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
#define MAX_NOTE 127

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
#define OFFSET_PULSE_WIDTH_REG   0x200
#define OFFSET_PULSE_REG         0x204
#define OFFSET_RAMP_REG          0x208
#define OFFSET_SAW_REG           0x20C
#define OFFSET_TRI_REG           0x210
#define OFFSET_SINE_REG          0x214
#define OFFSET_GAIN_SHIFT_REG    0x220
#define OFFSET_GAIN_SCALE_REG    0x224
#define OFFSET_ADSR_ATTACK_AMT   0x280
#define OFFSET_ADSR_DECAY_AMT    0x284
#define OFFSET_ADSR_SUSTAIN_AMT  0x288
#define OFFSET_ADSR_RELEASE_AMT  0x28C
#define OFFSET_COMP_ATTACK_AMT   0x290
#define OFFSET_COMP_RELEASE_AMT  0x294
#define OFFSET_COMP_THRESHOLD    0x298
#define OFFSET_COMP_KNEE_WIDTH   0x29C
#define OFFSET_COMP_KNEE_SLOPE   0x2A0
#define OFFSET_REV_REG           0x3E0
#define OFFSET_DATE_REG          0x3E4
#define OFFSET_WRAPBACK_REG      0x3FC
#define OFFSET_PITCH_REG         0x400

// midi controller CC mapping
#define CC_SINE_AMT     31
#define CC_TRI_AMT      32
#define CC_SAW_AMT      33
#define CC_RAMP_AMT     34
#define CC_PWM_AMT      35
#define CC_PWM_WIDTH    36
#define CC_ATTACK_AMT   21
#define CC_DECAY_AMT    22
#define CC_SUSTAIN_AMT  23
#define CC_RELEASE_AMT  24
#define CC_COMP_ATTACK  41
#define CC_COMP_RELEASE 42
#define CC_COMP_THRESH  43
#define CC_COMP_KNEE_W  44
#define CC_COMP_KNEE_S  45

/***************************************************************************
* Helper macros
****************************************************************************/

#define synthRead(addr)             XGpio_ReadReg(SYNTH_CTRL_BASEADDR, addr)
#define synthWrite(addr, data)      XGpio_WriteReg(SYNTH_CTRL_BASEADDR, addr, data)

#define playNote(note, amp)         safeSynthWrite(note*4, amp)
#define stopNote(note)              safeSynthWrite(note*4, 0)
#define setPitch(note, pitch)       safeSynthWrite(OFFSET_PITCH_REG + note*4, pitch)
#define setPulseWidth(width)        safeSynthWrite(OFFSET_PULSE_WIDTH_REG, width)
#define setWaveAmp(wave_form, amp)  safeSynthWrite(0x200 + 4*wave_form, amp)
#define setWavePh(wave_form, phase) safeSynthWrite(0x200 + 4*wave_form, phase)
#define setADSRAttack(amt)          safeSynthWrite(OFFSET_ADSR_ATTACK_AMT, amt)
#define setADSRDecay(amt)           safeSynthWrite(OFFSET_ADSR_DECAY_AMT, amt)
#define setADSRSustain(amt)         safeSynthWrite(OFFSET_ADSR_SUSTAIN_AMT, amt)
#define setADSRRelease(amt)         safeSynthWrite(OFFSET_ADSR_RELEASE_AMT, amt)
#define setCompAttack(amt)          safeSynthWrite(OFFSET_COMP_ATTACK_AMT, amt)
#define setCompRelease(amt)         safeSynthWrite(OFFSET_COMP_RELEASE_AMT, amt)
#define setCompThreshold(amt)       safeSynthWrite(OFFSET_COMP_THRESHOLD, amt)
#define setCompKneeWidth(amt)       safeSynthWrite(OFFSET_COMP_KNEE_WIDTH, amt)
#define setCompKneeSlope(amt)       safeSynthWrite(OFFSET_COMP_KNEE_SLOPE, amt)
#define setOutAmp(amp)              safeSynthWrite(OFFSET_GAIN_SCALE_REG, amp)
#define setOutShift(shift_amt)      safeSynthWrite(OFFSET_GAIN_SHIFT_REG, shift_amt)
#define setWrapback(data)           safeSynthWrite(OFFSET_WRAPBACK_REG, data)

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
int initComp(void);
void safePlayNote(u8 note, u8 amp);
void safeStopNote(u8 note);
void safeSynthWrite(u32 addr, u32 data);
u32 calcADSRamt(u8 midi_cc);
#define MAX_NOTE 127


#endif /* SYNTH_CTRL_H */
