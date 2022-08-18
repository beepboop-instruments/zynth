#ifndef MIDI_H_
#define MIDI_H_

#include "xuartps.h"
#include "utils.h"

/***************************************************************************
* Constant definitions
****************************************************************************/
// midi instance
#define MIDI_BASEADDR 		XPAR_XUARTPS_0_BASEADDR
#define MIDI_DEVICE_ID      XPAR_XUARTPS_0_DEVICE_ID
#define MIDI_BUFFER_SIZE    100

// midi channel voice messages
#define NOTE_OFF       0x80
#define NOTE_ON        0x90
#define POLY_PRESSURE  0xA0
#define CONTROL_CHANGE 0xB0
#define PROG_CHANGE    0xC0
#define CH_PRESSURE    0xD0
#define PITCH_BEND     0xE0

// midi system real-time messages
#define MIDI_SYS_CLK   0xF8

/***************************************************************************
* Function definitions
****************************************************************************/
int configMidi(XUartPs *MidiPs);
void readMidi(XUartPs *MidiPs, u8 *MidiBuffer, int numBytes);
int  rxMidiMsg(XUartPs *MidiPs, u8 *MidiBuffer);

#endif /* MIDI_H_ */
