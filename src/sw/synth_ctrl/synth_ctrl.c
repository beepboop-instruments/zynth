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
  setAttack(calcADSRamt(0));
  setDecay(calcADSRamt(0));
  setSustain(0xFFFFF);
  setRelease(calcADSRamt(0));

  return XST_SUCCESS;
}

/***************************************************************************
* Calculate adsr exponential settings
****************************************************************************/

// Map midi_cc (0-127) to a value in range [2, 0xFFFFF] approximately
u32 calcADSRamt(u8 midi_cc) {
  // Avoid division by zero
  if (midi_cc > 127) midi_cc = 127;

  // Use exponential mapping: output = A * exp(-k * midi_cc)
  // Coefficients chosen to approximate the desired values
  double A = 0xFFFFF;
  double k = log((double)A / 8.0) / 127.0;

  double result = A * exp(-k * midi_cc);
  return (u32)(result + 0.5); // round to nearest
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