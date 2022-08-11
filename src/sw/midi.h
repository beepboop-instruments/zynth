#ifndef MIDI_H_
#define MIDI_H_

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

#endif /* MIDI_H_ */
