/****************************************************************************/
/**
* synth_ctrl.c
*
* This file contains the functions for controlling the synthesizer.
*
*
* REVISION HISTORY:
*
* Ver   Who    Date     Changes
* ----- ------ -------- -----------------------------------------------------
* 0.00  tjh    03/24/25 Initial file
*
****************************************************************************/

#include <stdint.h>
#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include "synth_ctrl.h"
#include "../utils/utils.h"

adsr_t adsr_settings;

/***************************************************************************
* Initialize synthesizer controller
****************************************************************************/

int initSynth(void) {

  setWaveAmp(SINE_WAVE, 0x1F);
  setOutAmp(0x3F);
  setOutShift(0x8);
  setPulseWidth(0x8000);

  return initADSR();
}

/***************************************************************************
* Initialize adsr settings
****************************************************************************/

int initADSR(void) {
  adsr_settings.attack_length  = 100;
  adsr_settings.decay_length   = 100;
  adsr_settings.sustain_amt    = 0x7FFF;
  adsr_settings.release_length = 500;

  return setADSR();
}

/***************************************************************************
* Generate ADSR step tables
****************************************************************************/

void generate_step_table(uint16_t duration_ms, uint16_t amplitude_start, uint16_t amplitude_end, uint16_t table[7]) {
  uint32_t samples = duration_ms * SAMPLE_RATE / 1000;
  if (samples == 0) samples = 1;  // avoid div-by-zero

  int32_t delta = (int32_t)amplitude_end - (int32_t)amplitude_start;
  double base_step = (double)abs(delta) / samples;

  for (int i = 0; i < 7; ++i) {
    uint8_t weight = 1 << i; // 1, 2, 4, 8, ..., 64
    table[i] = (uint16_t)floor((weight / 127.0) * base_step);
  }
}

int setADSR(void) {
  generate_step_table(adsr_settings.attack_length, 0, MAX_AMPLITUDE, adsr_settings.attack_lut);
  generate_step_table(adsr_settings.decay_length, MAX_AMPLITUDE, adsr_settings.sustain_amt, adsr_settings.decay_lut);
  generate_step_table(adsr_settings.release_length, adsr_settings.sustain_amt, 0, adsr_settings.release_lut);

  for (u8 i = 0; i < 7; i++) {
    synthWrite(OFFSET_ATTACK_STEP+i*4, adsr_settings.attack_lut[i]);
    synthWrite(OFFSET_DECAY_STEP+i*4, adsr_settings.decay_lut[i]);
    synthWrite(OFFSET_RELEASE_STEP+i*4, adsr_settings.release_lut[i]);
  }

  setAttackLength(adsr_settings.attack_length);
  setDecayLength(adsr_settings.decay_length);
  setReleaseLength(adsr_settings.release_length);

  return XST_SUCCESS;
}

/***************************************************************************
* Check synthesizer controller
****************************************************************************/

int checkSynthCtrl(void) {

  u32 data;

  debug_print("-----------------------------------------------------\r\n");
  debug_print("Synthesizer Controller Test\r\n");
  debug_print("-----------------------------------------------------\r\n");

  // read revision register
  data = readRev();
  u16 rev_major = data >> 16;
  u16 rev_minor = data & 0xFFFF;
  debug_print("Revision: %X.%X ", rev_major, rev_minor);

  // read date code register
  data = readDateCode();
  u16 year = data & 0xFFFF;
  u8 month = data >> 16;
  u8 day = data >> 24;
  debug_print("Date: %02X-%02X-%04X\r\n", day, month, year);

  // verify wrapback register
  u32 testdata = 0xABCD1234;
  debug_print("Synth controller wrapback test\r\n");
  data = readWrapback();
  debug_print("- Wrapback reg read:  0x%08X\r\n", data);
  setWrapback(testdata);
  debug_print("- Wrapback reg write: 0x%08X\r\n", testdata);
  data = readWrapback();
  debug_print("- Wrapback reg read:  0x%08X\r\n", data);

  if (data == testdata) {
    debug_print("PASS\r\n");
  } else {
    debug_print("FAIL\r\n");
    return XST_FAILURE;
  }

  return XST_SUCCESS;
}

/***************************************************************************
* Read synthesizer controller memory map
****************************************************************************/

int readSynthCtrl(void) {

  u32 data;

  for (int i = 0; i < 256; i ++) {

    data = synthRead(i*4);
    debug_print("%d: 0x%08X\r\n", i, data);
    
  }

  return XST_SUCCESS;
}