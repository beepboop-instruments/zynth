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

#include "midi.h"
#include <xstatus.h>

XUartPs MidiPs; /* The instance of the UART Driver */
u8 MidiBuffer[MIDI_BUFFER_SIZE];	/* MIDI receive buffer */
const char *midi_note_names[] = MIDI_NOTE_NAMES;

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

    if (XUartPs_CfgInitialize(&MidiPs, Config, Config->BaseAddress)) {
		return XST_FAILURE;
	}

	// Check hardware build
    if (XUartPs_SelfTest(&MidiPs)) {
        return XST_FAILURE;
    }
	// Set operate mode
	XUartPs_SetOperMode(&MidiPs, XUARTPS_OPER_MODE_NORMAL);
	// Set baud rate to 31.25 kHz midi standard
	XUartPs_SetBaudRate(&MidiPs, 31250);

	return XST_SUCCESS;
}

/***************************************************************************/
/**
* This function writes a polls the UART recieve buffer until the specified
* number of bytes is received.
*
* @param  numBytes contains the number of bytes that should be received.
*
* @return XST_SUCCESS or XST_FAILURE
*
* @note   None.
*
****************************************************************************/
void readMidi(int numBytes)
{
	int count = 0;
	int rxTotal = 0;
    
    // TODO: add timeout if number of bytes expected aren't received in time
	while (rxTotal < numBytes)
	{
		count = XUartPs_Recv(&MidiPs, MidiBuffer+rxTotal, numBytes-rxTotal);
		rxTotal += count;
	}
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
int  rxMidiMsg()
{
	// Read uart rx buffer
	XUartPs_Recv(&MidiPs, MidiBuffer, 1);
	u8 cmd = (MidiBuffer[0] & 0xF0);
	u8 ch  = (MidiBuffer[0] & 0x0F);

    int Status;

	switch (cmd)
	{
	case NOTE_OFF:
        Status = note_off(ch);
		break;
	case NOTE_ON:
        Status = note_on(ch);
		break;
	case POLY_PRESSURE:
        Status = MidiPolyPressure(ch);
		break;
	case CONTROL_CHANGE:
        Status = MidiControlChange(ch);
		break;
	case PROG_CHANGE:
        Status = MidiProgChange(ch);    
		break;
	case CH_PRESSURE:
        Status = MidiChannelPressure(ch);
		break;
	case PITCH_BEND:
        Status = MidiPitchBend(ch);
		break;
    case SYS_CMD:
        Status = MidiMsgSystemCommon(ch);
        break;
    default:
        debug_print("MIDI message: 0x%02X\n\r", MidiBuffer[0]);
        Status = XST_SUCCESS;
        break;
	}

	return Status;
}

/***************************************************************************/
/**
* This function processes the MIDI Note On and MIDI Note Off messages.
*
* @param  Ch the MIDI channel specified in the message
* @param  OnOff whether the note is on (=1) or off (=0)
* 
* @return XST_SUCCESS or XST_FAILURE
*
* @note   Note Off event:
*         This message is sent when a note is released (ended). (kkkkkkk) is
*         the key (note) number. (vvvvvvv) is the velocity.
*
*         Note On event:
*         This message is sent when a note is depressed (start). (kkkkkkk) is
*         the key (note) number. (vvvvvvv) is the velocity.
*
****************************************************************************/
int MidiNoteOnOff(u8 Ch, u8 OnOff) {

    char *s_onoff = OnOff ? "ON " : "OFF";
    
    // read the note and velocity
    readMidi(2);
    u8 key = MidiBuffer[0];
    u8 vel = MidiBuffer[1];

    // set the note on or off
    if (OnOff) {
        playNote(key, vel);
    } else {
        stopNote(key);
    }

    debug_print("MIDI %i Note %s: %s %03i \r\n", Ch, s_onoff, midi_note_names[key], vel);

    return XST_SUCCESS;
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
int MidiPolyPressure(u8 Ch) {

    // read the note and pressure
    readMidi(2);
    u8 key = MidiBuffer[0];
    u8 value = MidiBuffer[1];

    debug_print("MIDI %i polyphonic pressure: %s %03i \n\r", Ch, midi_note_names[key], value);

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
int MidiControlChange(u8 Ch) {

    char *change;

    // read note and value
    readMidi(2);
    u8 control = MidiBuffer[0];
    u8 value = MidiBuffer[1];

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

        case 41:
        /* Set sine wave amplitude
         */
          setWaveAmp(SINE_WAVE, value >> 2);
          return XST_SUCCESS;

        case 42:
        /* Set triangle wave amplitude
         */
          setWaveAmp(TRI_WAVE, value >> 2);
          return XST_SUCCESS;

        case 43:
        /* Set saw wave amplitude
         */
          setWaveAmp(SAW_WAVE, value >> 2);
          return XST_SUCCESS;

        case 44:
        /* Set ramp wave amplitude
         */
          setWaveAmp(RAMP_WAVE, value >> 2);
          return XST_SUCCESS;

        case 45:
        /* Set pulse wave amplitude
         */
          setWaveAmp(PULSE_WAVE, value >> 2);
          return XST_SUCCESS;

        case 46:
        /* Set pulse wave width
         */
          setPulseWidth(value << 9);
          return XST_SUCCESS;

        default:
            debug_print("MIDI %i controller %i: %i.\r\n", Ch, control, value);

            return XST_SUCCESS;    
    }

    debug_print("MIDI %i %s: %i.\r\n", Ch, change, value);
    
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
int MidiProgChange(u8 Ch) {

    // read value    
    readMidi(1);
    u8 value = MidiBuffer[0];

    debug_print("MIDI %i program change: 0x%02X \n\r", Ch, value);

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
int MidiChannelPressure(u8 Ch) {
    
    // read value    
    readMidi(1);
    u8 value = MidiBuffer[0];

    debug_print("MIDI %i channel pressure: %03i \n\r", Ch, value);

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
int MidiPitchBend(u8 Ch) {
    
    // read pitch offset
    readMidi(2);
    int pitchBend = (MidiBuffer[1]<<7) + MidiBuffer[0] - 0x2000;

    debug_print("MIDI %i pitch bend: %04i \n\r", Ch, pitchBend);

    return XST_SUCCESS;
}

/***************************************************************************/
/**
* This function processes the MIDI System Common messages.
*
* @param  Ch the MIDI channel specified in the message
* 
* @return XST_SUCCESS or XST_FAILURE
*
* @note   None.
*
****************************************************************************/
int MidiMsgSystemCommon(u8 Cmd) {

    switch(Cmd) {        
        case SYS_EXCL_START:
        /* System Exclusive. This message type allows manufacturers to create
         * their own messages (such as bulk dumps, patch parameters, and other
         * non-spec data) and provides a mechanism for creating additional
         * MIDI Specification messages. The Manufacturer’s ID code (assigned
         * by MMA or AMEI) is either 1 byte (0iiiiiii) or 3 bytes
         * (0iiiiiii 0iiiiiii 0iiiiiii). Two of the 1 Byte IDs are reserved
         * for extensions called Universal Exclusive Messages, which are not
         * manufacturer-specific. If a device recognizes the ID code as its own
         * (or as a supported Universal message) it will listen to the rest of
         * the message (0ddddddd). Otherwise, the message will be ignored.
         * (Note: Only Real-Time messages may be interleaved with a System
         * Exclusive.)
         */
            debug_print("MIDI System Exclusive:");
            while (MidiBuffer[0] != SYS_EXCL_END) {
                readMidi(1);
                debug_print(" %02X", MidiBuffer[0]);
            }          
            debug_print("\n\r");
            break;
        
        case SYS_QTR_FRAME:
        /* MIDI Time Code Quarter Frame. Value = 0nnndddd.
         * nnn = Message Type. dddd = Values.
         */
            readMidi(1);
            u8 type = MidiBuffer[0]>>4;
            u8 values = MidiBuffer[0] & 0x0F;
            debug_print("MIDI Time Code Quarter Frame - type: %i, values: %i.\r\n", type, values);
            break;
        
        case SYS_POS_PTR:
        /* Song Position Pointer. This is an internal 14 bit register that
         * holds the number of MIDI beats (1 beat= six MIDI clocks) since
         * the start of the song. l is the LSB (0lllllll), m the MSB (0mmmmmmm).
         */
            readMidi(2);
            int position = (MidiBuffer[1]<<7) + MidiBuffer[0];
            debug_print("MIDI Song Position Pointer: %i.\r\n", position);            
            break;
        
        case SYS_SONG_SEL:
        /* Song Select. The Song Select specifies which sequence or song is to be played.
         */
            readMidi(1);
            u8 song = MidiBuffer[0];
            debug_print("MIDI Song Select: %i.\r\n", song);
            break;
        
        case SYS_TUNE:
        /* Tune Request. Upon receiving a Tune Request, all analog synthesizers
         * should tune their oscillators.
         */
            debug_print("MIDI Tune Request.\r\n");
            break;

        case SYS_CLK:
        /* Timing Clock. Sent 24 times per quarter note when synchronization is required.
         */
            break;
        
        case SYS_START:
        /* Timing Clock. Sent 24 times per quarter note when synchronization is required.
         */
            debug_print("MIDI Start Sequence.\r\n");
            break;

        case SYS_CONTINUE:
        /* Continue. Continue at the point the sequence was Stopped.
         */
            debug_print("MIDI Continue Sequence.\r\n");
            break;

        case SYS_STOP:
        /* Stop. Stop the current sequence.
         */
            debug_print("MIDI Stop Sequence.\r\n");
            break;
        
        case SYS_SENSING:
        /* Active Sensing. This message is intended to be sent repeatedly
         * to tell the receiver that a connection is alive. Use of this
         * message is optional. When initially received, the receiver will
         * expect to receive another Active Sensing message each 300ms (max),
         * and if it does not then it will assume that the connection has been
         * terminated. At termination, the receiver will turn off all voices
         * and return to normal (non- active sensing) operation. 
         */
            debug_print("MIDI Active Sensing.\r\n");
            break;
        
        case SYS_RESET:
        /* Reset. Reset all receivers in the system to power-up status. This
         * should be used sparingly, preferably under manual control. In
         * particular, it should not be sent on power-up.
         */
            debug_print("MIDI System Reset.\r\n");
            break; 

        default:
            debug_print("MIDI system message: 0x%02X\n\r", MidiBuffer[0]);
    }        

    return XST_SUCCESS;
}