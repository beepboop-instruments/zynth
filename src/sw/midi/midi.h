#ifndef MIDI_H_
#define MIDI_H_

/***************************************************************************
* Include files
****************************************************************************/

#include "xuartps.h"
#include "../utils/utils.h"

#include "../synth_ctrl/synth_ctrl.h"

/***************************************************************************
* Constant definitions
****************************************************************************/
#define ON  1
#define OFF 0

// midi instance
#define MIDI_BASEADDR 		XPAR_XUARTPS_0_BASEADDR
#define MIDI_DEVICE_ID    XPAR_XUARTPS_0_DEVICE_ID
#define MIDI_BUFFER_SIZE  128

// midi channel voice messages
#define NOTE_OFF       0x80
#define NOTE_ON        0x90
#define POLY_PRESSURE  0xA0
#define CONTROL_CHANGE 0xB0
#define PROG_CHANGE    0xC0
#define CH_PRESSURE    0xD0
#define PITCH_BEND     0xE0

// channel mode messages
#define ALL_SOUND_OFF  0x78
#define RESET_ALL      0x79
#define LOCAL_CONTROL  0x7A
#define ALL_NOTES_OFF  0x7B
#define OMNI_MODE_OFF  0x7C
#define OMNI_MODE_ON   0x7D
#define MONO_MODE_ON   0x7E
#define POLY_MODE_ON   0x7F

// system common messages
#define SYS_CMD        0xF0
#define SYS_EXCL_START 0x00
#define SYS_EXCL_END   0xF7
#define SYS_QTR_FRAME  0x01
#define SYS_POS_PTR    0x02
#define SYS_SONG_SEL   0x03
#define SYS_TUNE       0x06
// system real-time messages
#define SYS_CLK        0x08
#define SYS_START      0x0A
#define SYS_CONTINUE   0x0B
#define SYS_STOP       0x0C
#define SYS_SENSING    0x0E
#define SYS_RESET      0x0F

#define MIDI_NOTE_NAMES { \
  "C0  ", "Db0 ", "D0  ", "Eb0 ", "E0  ", "F0  ", "Gb0 ", "G0  ", "Ab0 ", "A0  ", "Bb0 ", "B0  ",  \
  "C1  ", "Db1 ", "D1  ", "Eb1 ", "E1  ", "F1  ", "Gb1 ", "G1  ", "Ab1 ", "A1  ", "Bb1 ", "B1  ",  \
  "C2  ", "Db2 ", "D2  ", "Eb2 ", "E2  ", "F2  ", "Gb2 ", "G2  ", "Ab2 ", "A2  ", "Bb2 ", "B2  ",  \
  "C3  ", "Db3 ", "D3  ", "Eb3 ", "E3  ", "F3  ", "Gb3 ", "G3  ", "Ab3 ", "A3  ", "Bb3 ", "B3  ",  \
  "C4  ", "Db4 ", "D4  ", "Eb4 ", "E4  ", "F4  ", "Gb4 ", "G4  ", "Ab4 ", "A4  ", "Bb4 ", "B4  ",  \
  "C5  ", "Db5 ", "D5  ", "Eb5 ", "E5  ", "F5  ", "Gb5 ", "G5  ", "Ab5 ", "A5  ", "Bb5 ", "B5  ",  \
  "C6  ", "Db6 ", "D6  ", "Eb6 ", "E6  ", "F6  ", "Gb6 ", "G6  ", "Ab6 ", "A6  ", "Bb6 ", "B6  ",  \
  "C7  ", "Db7 ", "D7  ", "Eb7 ", "E7  ", "F7  ", "Gb7 ", "G7  ", "Ab7 ", "A7  ", "Bb7 ", "B7  ",  \
  "C8  ", "Db8 ", "D8  ", "Eb8 ", "E8  ", "F8  ", "Gb8 ", "G8  ", "Ab8 ", "A8  ", "Bb8 ", "B8  ",  \
  "C9  ", "Db9 ", "D9  ", "Eb9 ", "E9  ", "F9  ", "Gb9 ", "G9  ", "Ab9 ", "A9  ", "Bb9 ", "B9  ",  \
  "C10 ", "Db10", "D10 ", "Eb10", "E10 ", "F10 ", "Gb10", "G10 "};

/***************************************************************************
* Function helper macros
****************************************************************************/

#define note_on(ch) MidiNoteOnOff(ch, ON)
#define note_off(ch) MidiNoteOnOff(ch, OFF)

/***************************************************************************
* Global variable definitions
****************************************************************************/

extern XUartPs MidiPs;
extern u8 MidiBuffer[MIDI_BUFFER_SIZE];

/***************************************************************************
* Function definitions
****************************************************************************/
int configMidi(u32 BaseAddress);
void readMidi(int numBytes);
int rxMidiMsg(void);
int MidiNoteOnOff(u8 Ch, u8 OnOff);
int MidiPolyPressure(u8 Ch);
int MidiControlChange(u8 Ch);
int MidiProgChange(u8 Ch);
int MidiChannelPressure(u8 Ch);
int MidiPitchBend(u8 Ch);
int MidiMsgSystemCommon(u8 Cmd);

#endif /* MIDI_H_ */
