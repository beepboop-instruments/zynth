/****************************************************************************/
/**
* midi.c
*
* This file contains the functions for processing MIDI commands.
*
* REFERENCES:
* - https://www.midi.org/specifications-old/item/table-1-summary-of-midi-message
*
*
* REVISION HISTORY:
*
* Ver   Who    Date     Changes
* ----- ------ -------- -----------------------------------------------------
* 0.00  tjh    03/13/25 Initial file
*
****************************************************************************/

#include "xinterrupt_wrap.h"

#include "midi.h"
#include "pitch.h"
#include <xstatus.h>
#include <xuartps.h>

XUartPs MidiPs; /* The instance of the UART Driver */
u8 MidiBuffer[MIDI_BUFFER_SIZE];	/* MIDI receive buffer */
const char *midi_note_names[] = MIDI_NOTE_NAMES;
u32 FreqWords[128];

RingBuffer midi_rb = { .head = 0, .tail = 0 };
MidiParser midi_parser = {0};

/***************************************************************************
* Reset frequency word array back to defaults
****************************************************************************/

void initFreqWords(void) {
    for (u8 i = 0; i < 128; i ++) {
        FreqWords[i] = FreqWordDefaults[i];
    }
    return;
}

void writeFreqWords(void) {
  for (u8 i = 0; i < 128; i ++) {
    setPitch(i, FreqWords[i]);
  }
  return;    
}

/***************************************************************************
* MIDI ring buffer
****************************************************************************/

int rb_is_empty(RingBuffer *rb) {
    return rb->head == rb->tail;
}

int rb_is_full(RingBuffer *rb) {
    return ((rb->head + 1) % MIDI_BUFFER_SIZE) == rb->tail;
}

int rb_free_space(RingBuffer *rb) {
    if (rb->head >= rb->tail) {
        return MIDI_BUFFER_SIZE - (rb->head - rb->tail) - 1;
    } else {
        return (rb->tail - rb->head - 1);
    }
}

void rb_push(RingBuffer *rb, u8 byte) {
    if (!rb_is_full(rb)) {
        rb->data[rb->head] = byte;
        rb->head = (rb->head + 1) % MIDI_BUFFER_SIZE;
    } else if (rb_free_space(&midi_rb) < 4) {
    debug_print("Warning: MIDI buffer almost full.\r\n");
    } else {
        // optional: handle overflow (log or drop)
        debug_print("Critical Warning!: MIDI ring buffer overflow.\r\n");
    }
}

u8 rb_pop(RingBuffer *rb) {
  u8 byte = 0;
  if (!rb_is_empty(rb)) {
    byte = rb->data[rb->tail];
    rb->tail = (rb->tail + 1) % MIDI_BUFFER_SIZE;
  }
  return byte;
}

/***************************************************************************
* Configure the MIDI interface
****************************************************************************/

/***************************************************************************/
/**
* This function writes a number configures the UART interface to the MIDI standard.
*
* @param  BaseAddress contains the UART periphal's DMA address.
*
* @return XST_SUCCESS or XST_FAILURE
*
* @note   None.
*
****************************************************************************/
int configMidi(u32 BaseAddress)
{
	XUartPs_Config *Config;

#ifdef SDT
	(void)MidiPs;
#endif

    initFreqWords();

	/*
	 * Initialize the UART driver so that it's ready to use.
	 * Look up the configuration in the config table, then initialize it.
	 */
#ifndef SDT
	Config = XUartPs_LookupConfig(DeviceId);
#else
	Config = XUartPs_LookupConfig(BaseAddress);
#endif
	if (NULL == Config) {
		return XST_FAILURE;
	}

    // Initialize UART instance
    if (XUartPs_CfgInitialize(&MidiPs, Config, Config->BaseAddress) != XST_SUCCESS) {
        return XST_FAILURE;
    }

    // Reset FIFOs immediately after init
    XUartPs_SetOptions(&MidiPs, XUARTPS_OPTION_RESET_RX | XUARTPS_OPTION_RESET_TX);

    // Self test (optional, can remove in final system)
    if (XUartPs_SelfTest(&MidiPs) != XST_SUCCESS) {
        return XST_FAILURE;
    }

    // Set baud rate explicitly (optional but may help)
    XUartPs_SetBaudRate(&MidiPs, 31250);  // MIDI baud rate

    // Set FIFO trigger level early
    XUartPs_SetFifoThreshold(&MidiPs, 1);

    // Setup ISR handler
    XUartPs_SetHandler(&MidiPs, (XUartPs_Handler)Handler, &MidiPs);

    // Enable interrupts after setting handler
    u32 IntrMask = XUARTPS_IXR_RXFULL | XUARTPS_IXR_RXOVR |
                   XUARTPS_IXR_TOUT | XUARTPS_IXR_PARITY |
                   XUARTPS_IXR_FRAMING | XUARTPS_IXR_RXEMPTY;

    XUartPs_SetInterruptMask(&MidiPs, IntrMask);

    // Enable interrupt system (after interrupts are fully configured)
    XSetupInterruptSystem(&MidiPs, &XUartPs_InterruptHandler,
                          Config->IntrId, Config->IntrParent,
                          XINTERRUPT_DEFAULT_PRIORITY);

  return XST_SUCCESS;
}

/**************************************************************************/
/**
*
* This function is the handler which performs processing to handle data events
* from the device.  It is called from an interrupt context. so the amount of
* processing should be minimal.
*
* This handler provides an example of how to handle data for the device and
* is application specific.
*
* @param	CallBackRef contains a callback reference from the driver,
*		in this case it is the instance pointer for the XUartPs driver.
* @param	Event contains the specific kind of event that has occurred.
* @param	EventData contains the number of bytes sent or received for sent
*		and receive events.
*
* @return	None.
*
* @note		None.
*
***************************************************************************/
void Handler(void *CallBackRef, u32 Event, unsigned int EventData)
{
    (void)CallBackRef; // not used

	/* All of the data has been sent */
	if (Event == XUARTPS_EVENT_SENT_DATA) {
	}

	/* All of the data has been received */
	if (Event == XUARTPS_EVENT_RECV_DATA) {
      while (XUartPs_IsReceiveData(MIDI_BASEADDR)) {
        u8 byte;
        XUartPs_Recv(&MidiPs, &byte, 1);
        if (byte != SYS_CMD+SYS_CLK) {
          rb_push(&midi_rb, byte);
        }
      }
	}

	/*
	 * Data was received, but not the expected number of bytes, a
	 * timeout just indicates the data stopped for 8 character times
	 */
	if (Event == XUARTPS_EVENT_RECV_TOUT) {
      debug_print("XUARTPS_EVENT_RECV_TOUT!!\r\n");
      debug_print("EventData=%d\r\n", EventData);
	}

	/*
	 * Data was received with an error, keep the data but determine
	 * what kind of errors occurred
	 */
	if (Event == XUARTPS_EVENT_RECV_ERROR) {
      debug_print("XUARTPS_EVENT_RECV_ERROR!!\r\n");
      debug_print("EventData=%d\r\n", EventData);
      // clear PS UART buffer
      while (XUartPs_IsReceiveData(MIDI_BASEADDR)) {
        XUartPs_RecvByte(MIDI_BASEADDR);
      }
	}

	/*
	 * Data was received with an parity or frame or break error, keep the data
	 * but determine what kind of errors occurred. Specific to Zynq Ultrascale+
	 * MP.
	 */
	if (Event == XUARTPS_EVENT_PARE_FRAME_BRKE) {
      debug_print("XUARTPS_EVENT_PARE_FRAME_BRKE!!\r\n");
      debug_print("EventData=%d\r\n", EventData);
	}

	/*
	 * Data was received with an overrun error, keep the data but determine
	 * what kind of errors occurred. Specific to Zynq Ultrascale+ MP.
	 */
	if (Event == XUARTPS_EVENT_RECV_ORERR) {
      debug_print("XUARTPS_EVENT_RECV_ORERR!!\r\n");
      debug_print("EventData=%d\r\n", EventData);
	}
}

/***************************************************************************/
/**
* This parses a received MIDI message.
*
* @return XST_SUCCESS or XST_FAILURE
*
* @note   None.
*
****************************************************************************/
int rxMidiMsg(void) {
  while (!rb_is_empty(&midi_rb)) {
    u8 byte = rb_pop(&midi_rb);

    // Real-time system messages (0xF8–0xFF) can appear any time
    if (byte >= 0xF8) {
      // Optionally: handle or ignore
      continue;
    }

    // Status byte
    if (byte & 0x80) {
      midi_parser.status = byte;
      midi_parser.msg[0] = byte;
      midi_parser.count = 1;

      // Determine expected message length
      switch (byte & 0xF0) {
        case NOTE_OFF:
        case NOTE_ON:
        case POLY_PRESSURE:
        case CONTROL_CHANGE:
        case PITCH_BEND:
          midi_parser.expected = 3;
          break;
        case PROG_CHANGE:
        case CH_PRESSURE:
          midi_parser.expected = 2;
          break;
        case SYS_CMD:
          // Let the system handler figure it out
          midi_parser.expected = 2;
          break;
        default:
          midi_parser.expected = 1;
          break;
        }
    } else {
      // Data byte, running status
      if (midi_parser.count == 0 && midi_parser.status == 0) {
        // No running status available
        continue;
      }

      if (midi_parser.count == 0) {
        midi_parser.msg[0] = midi_parser.status;
        midi_parser.count = 1;
      }

      midi_parser.msg[midi_parser.count++] = byte;

      // Full message received
      if (midi_parser.count >= midi_parser.expected) {
        dispatchMidiMessage(midi_parser.msg, midi_parser.count);
        midi_parser.count = 0;
      }
    }
  }

  return XST_SUCCESS;
}

/***************************************************************************/
/**
* This function processes the received MIDI message.
*
* @return XST_SUCCESS or XST_FAILURE
*
* @note   None.
*
****************************************************************************/
void dispatchMidiMessage(u8 *msg, u8 len) {
  u8 cmd = msg[0] & 0xF0;
  u8 ch = (msg[0] & 0x0F) + 1;

  switch (cmd) {
    case NOTE_ON:
      if (len >= 3) {
        debug_print("NOTE ON: ch %d, key %d, vel %d\r\n", ch, msg[1], msg[2]);
        safePlayNote(msg[1], msg[2]);
      }
      break;

    case NOTE_OFF:
      if (len >= 3) {
        debug_print("NOTE OFF: ch %d, key %d, vel %d\r\n", ch, msg[1], msg[2]);
        safeStopNote(msg[1]);
      }
      break;

	case POLY_PRESSURE:
      if (len >= 2) {
        MidiPolyPressure(ch, msg[1], msg[2]);
      }
	  break;

    case CONTROL_CHANGE:
      if (len >= 3) {
        MidiControlChange(ch, msg[1], msg[2]);
      }
      break;
      
    case PROG_CHANGE:
      if (len >= 1) {
        MidiProgChange(ch, msg[1]);
      }
      break;
      
	case CH_PRESSURE:
      if (len >= 2) {
        MidiChannelPressure(ch, msg[1]);
      }
	  break;
      
    case PITCH_BEND:
      if (len >= 3) {
        MidiPitchBend(ch, msg[1], msg[2]);
      }
      break;

      // Handle other message types...
      default:
        debug_print("Unknown MIDI: %02X [%d bytes]\r\n", msg[0], len);
        break;
    }
}

/***************************************************************************/
/**
* This function processes the MIDI Poly Pressure message.
*
* @param  Ch the MIDI channel specified in the message
* 
* @return XST_SUCCESS or XST_FAILURE
*
* @note   This message is most often sent by pressing down on the key after 
*         it “bottoms out”. (kkkkkkk) is the key (note) number. (vvvvvvv) is 
*         the pressure value.
*
****************************************************************************/
int MidiPolyPressure(u8 Ch, u8 key, u8 value) {

  debug_print("midi %i polyphonic pressure: %s %03i \n\r", Ch, midi_note_names[key], value);

  return XST_SUCCESS;
}

/***************************************************************************/
/**
* This function processes the MIDI Control Change (CC) message.
*
* @param  Ch the MIDI channel specified in the message
* 
* @return XST_SUCCESS or XST_FAILURE
*
* @note   This message is sent when a controller value changes. Controllers
*         include devices such as pedals and levers.
*
****************************************************************************/
int MidiControlChange(u8 Ch, u8 control, u8 value) {

  char *change = 0;

  switch (control) {
    case ALL_SOUND_OFF:
     /* All Sound Off. When All Sound Off is received all oscillators
      * will turn off, and their volume envelopes are set to zero as 
      * soon as possible. c = 120, v = 0: All Sound Off
      */
      change = "ALL SOUND OFF";
      break;

    case RESET_ALL:
      /* Reset All Controllers. When Reset All Controllers is received, 
      * all controller values are reset to their default values. (See 
      * specific Recommended Practices for defaults). c = 121, v = x: 
      * Value must only be zero unless otherwise allowed in a specific
      * Recommended Practice.
      */
      change = "RESET ALL CONTROLLERS";
      break;
        
    case LOCAL_CONTROL:
      /* Local Control. When Local Control is Off, all devices on a given
       * channel will respond only to data received over MIDI. Played data,
       * etc. will be ignored. Local Control On restores the functions of
       * the normal controllers.
       * c = 122, v = 0: Local Control Off
       * c = 122, v = 127: Local Control On
       */
      change = "LOCAL CONTROL";
      break;

    case ALL_NOTES_OFF:
      /* All Notes Off. When an All Notes Off is received, all oscillators will turn off.
       * c = 123, v = 0: All Notes Off (See text for description of actual mode commands.)
       */
      change = "ALL NOTES OFF";
      break;

    case OMNI_MODE_OFF:
      /* c = 124, v = 0: Omni Mode Off
       */
      change = "OMNI MODE OFF";
      break;
        
    case OMNI_MODE_ON:
     /* c = 125, v = 0: Omni Mode On
      */
      change = "OMNI MODE ON";
      break;
        
    case MONO_MODE_ON:
     /* c = 126, v = M: Mono Mode On (Poly Off) where M is the number of channels
      * (Omni Off) or 0 (Omni On)
      */
      change = "MONO MODE ON";
      break;
        
    case POLY_MODE_ON:   
     /* c = 127, v = 0: Poly Mode On (Mono Off) (Note: These four messages also cause 
      * All Notes Off)
      */
      change = "POLY MODE ON";
      break;

     /* Controller numbers 120-127 are reserved as “Channel Mode Messages” (below).
      * (ccccccc) is the controller number (0-119). (vvvvvvv) is the controller
      * value (0-127).
      */

    case CC_SINE_AMT:
     /* Set sine wave amplitude
      */
      setWaveAmp(SINE_WAVE, value >> 2);
      change = "SINE AMT";
      break;

    case CC_TRI_AMT:
     /* Set triangle wave amplitude
      */
      setWaveAmp(TRI_WAVE, value >> 2);
      change = "TRI AMT";
      break;

    case CC_SAW_AMT:
     /* Set saw wave amplitude
      */
      setWaveAmp(SAW_WAVE, value >> 2);
      change = "SAW AMT";
      break;

    case CC_RAMP_AMT:
     /* Set ramp wave amplitude
      */
      setWaveAmp(RAMP_WAVE, value >> 2);
      change = "RAMP AMT";
      break;

    case CC_PWM_AMT:
     /* Set pulse wave amplitude
      */
      setWaveAmp(PULSE_WAVE, value >> 2);
      change = "PULSE AMT";
      break;

    case CC_PWM_WIDTH:
     /* Set pulse wave width
      */
      setPulseWidth(value << 9);
      change = "PULSE WIDTH";
      break;

    case CC_ATTACK_AMT:
     /* Set attack length
      */
      setAttack(calcADSRamt(value));
      change = "ATTACK AMT";
      break;

    case CC_DECAY_AMT:
      /* Set decay length
      */
      setDecay(calcADSRamt(value));
      change = "DECAY AMT";
      break;

    case CC_SUSTAIN_AMT:
      /* Set sustain amount
      */
      setSustain(value << 13);
      change = "SUSTAIN AMT";
      break;

    case CC_RELEASE_AMT:
      /* Set release length
      */
      setRelease(calcADSRamt(value));
      change = "RELEASE AMT";
      break;

    default:
      debug_print("midi %i controller %i: %i.\r\n", Ch, control, value);
      break;
  }

  debug_print("midi %i %s: %i.\r\n", Ch, change, value);
  
  return XST_SUCCESS;
}

/***************************************************************************/
/**
* This function processes the MIDI Program Change message.
*
* @param  Ch the MIDI channel specified in the message
* 
* @return XST_SUCCESS or XST_FAILURE
*
* @note   Program Change. This message sent when the patch number changes.
*         (ppppppp) is the new program number.
*
****************************************************************************/
int MidiProgChange(u8 Ch, u8 value) {

  debug_print("midi %i program change: 0x%02X \n\r", Ch, value);

  return XST_SUCCESS;
}

/***************************************************************************/
/**
* This function processes the MIDI Channel Pressure message.
*
* @param  Ch the MIDI channel specified in the message
* 
* @return XST_SUCCESS or XST_FAILURE
*
* @note    	Channel Pressure (After-touch). This message is most often sent
*           by pressing down on the key after it “bottoms out”. This message
*           is different from polyphonic after-touch. Use this message to send
*           the single greatest pressure value (of all the current depressed
*           keys). (vvvvvvv) is the pressure value.
*
****************************************************************************/
int MidiChannelPressure(u8 Ch, u8 value) {

  debug_print("midi %i channel pressure: %03i \n\r", Ch, value);

  return XST_SUCCESS;
}

/***************************************************************************/
/**
* This function processes the MIDI Pitch Bend message.
*
* @param  Ch the MIDI channel specified in the message
* 
* @return XST_SUCCESS or XST_FAILURE
*
* @note   Pitch Bend Change. This message is sent to indicate a change in the
*         pitch bender (wheel or lever, typically). The pitch bender is
*         measured by a fourteen bit value. Center (no pitch change) is 2000H.
*         Sensitivity is a function of the receiver, but may be set using RPN
*         0. (lllllll) are the least significant 7 bits. (mmmmmmm) are the
*         most significant 7 bits.
*
****************************************************************************/
int MidiPitchBend(u8 Ch, int lsb, int msb) {
    
  int pitchBend = ((msb << 7) + lsb);
  double scale = get_pitch_bend_scale(pitchBend);

  for (u8 i = 116; i < 128; i ++) {
    FreqWords[i] = (u32)((double)(FreqWordDefaults[i]) * scale);
  }

  writeFreqWords();

  xil_printf("midi %i pitch bend: %i\n\r", Ch, pitchBend-8192);

  return XST_SUCCESS;
}
