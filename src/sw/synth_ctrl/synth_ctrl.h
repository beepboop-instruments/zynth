#ifndef SYNTH_CTRL_H
#define SYNTH_CTRL_H

/***************************************************************************
* Include files
****************************************************************************/

#include "xparameters.h"
#include "xgpio_l.h"
#include <xil_types.h>
#include <xstatus.h>

#define SYNTH_CTRL_BASEADDR XPAR_M03_AXI_0_BASEADDR

/***************************************************************************
* Type definitions
****************************************************************************/

typedef uint8_t wave_type;

/***************************************************************************
* Constant definitions
****************************************************************************/

#define SAMPLE_RATE 96000
#define MAX_AMPLITUDE 65535

// waveform types
#define PULSE_WAVE 1
#define RAMP_WAVE  2
#define SAW_WAVE   3
#define TRI_WAVE   4
#define SINE_WAVE  5

// ADSR types
#define ATTACK  0
#define DECAY   1
#define SUSTAIN 2
#define RELEASE 3

// address offsets
#define OFFSET_PULSE_WIDTH_REG 0x200
#define OFFSET_PULSE_REG       0x204
#define OFFSET_RAMP_REG        0x208
#define OFFSET_SAW_REG         0x20C
#define OFFSET_TRI_REG         0x210
#define OFFSET_SINE_REG        0x214
#define OFFSET_GAIN_SHIFT_REG  0x220
#define OFFSET_GAIN_SCALE_REG  0x224
#define OFFSET_ATTACK_STEP     0x280
#define OFFSET_DECAY_STEP      0x2A0
#define OFFSET_SUSTAIN_LEVEL   0x2C0
#define OFFSET_RELEASE_STEP    0x2E0
#define OFFSET_REV_REG         0x3E0
#define OFFSET_DATE_REG        0x3E4
#define OFFSET_WRAPBACK_REG    0x3FC
#define OFFSET_PITCH_REG       0x400

typedef struct {
  u16 attack_lut[7];
  u16 decay_lut[7];
  u16 release_lut[7];
  u16 attack_length;
  u16 decay_length;
  u16 sustain_amt;
  u16 release_length;
} adsr_t;

extern adsr_t adsr_settings;

/***************************************************************************
* Helper macros
****************************************************************************/

#define synthRead(addr)             XGpio_ReadReg(SYNTH_CTRL_BASEADDR, addr)
#define synthWrite(addr, data)      XGpio_WriteReg(SYNTH_CTRL_BASEADDR, addr, data)

#define playNote(note, amp)         synthWrite(note*4, amp)
#define stopNote(note)              synthWrite(note*4, 0)
#define setPitch(note, pitch)       synthWrite(OFFSET_PITCH_REG + note*4, pitch)
#define setPulseWidth(width)        synthWrite(OFFSET_PULSE_WIDTH_REG, width)
#define setWaveAmp(wave_form, amp)  synthWrite(0x200 + 4*wave_form, amp)
#define setWavePh(wave_form, phase) synthWrite(0x200 + 4*wave_form, phase)
#define setAttackLength(length)     synthWrite(OFFSET_ATTACK_LENGTH, length)
#define setDecayLength(length)      synthWrite(OFFSET_DECAY_LENGTH, length)
#define setReleaseLength(length)    synthWrite(OFFSET_RELEASE_LENGTH, length)
#define setOutAmp(amp)              synthWrite(OFFSET_GAIN_SCALE_REG, amp)
#define setOutShift(shift_amt)      synthWrite(OFFSET_GAIN_SHIFT_REG, shift_amt)
#define setWrapback(data)           synthWrite(OFFSET_WRAPBACK_REG, data)

#define readRev()                   synthRead(OFFSET_REV_REG)
#define readDateCode()              synthRead(OFFSET_DATE_REG)
#define readWrapback()              synthRead(OFFSET_WRAPBACK_REG)

/***************************************************************************
* Function definitions
****************************************************************************/

int initSynth(void);
int checkSynthCtrl(void);
int readSynthCtrl(void);
void generate_step_table(uint16_t duration_ms, uint16_t amplitude_start, uint16_t amplitude_end, uint16_t table[7]);
int initADSR(void);
int setADSR(void);

#endif /* SYNTH_CTRL_H */
