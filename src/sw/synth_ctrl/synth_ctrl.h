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
* Play a note and ensure AXI bounds are not exceeded
****************************************************************************/

void safePlayNote(u8 note, u8 amp) {
    if (note <= MAX_NOTE) {
        playNote(note, amp);
    } else {
        debug_print("Invalid note %d\r\n", note);
    }
}

/***************************************************************************
* Stop a note and ensure AXI bounds are not exceeded
****************************************************************************/

void safeStopNote(u8 note) {
    if (note <= MAX_NOTE) {
        stopNote(note);
    } else {
        debug_print("Invalid note %d\r\n", note);
    }
}

/***************************************************************************
* Perform AXI write and ensure bounds are not exceeded
****************************************************************************/

void safeSynthWrite(u32 addr, u32 data) {
    if (addr <= 511*4) {
        synthWrite(addr, data);
    } else {
        debug_print("AXI write skipped — invalid addr: %d\r\n", addr);
    }
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

u32 calcADSRamt(u8 midi_cc) {
  float scaler = 1.0;
  if (midi_cc < 32) {
      scaler = 1.0;
  } else if (midi_cc < 64) {
      scaler = 0.5;
  } else if (midi_cc < 96) {
      scaler = 0.25;
  } else {
      scaler = 0.1;
  }
  return (u32)(scaler * (128 - midi_cc)); // round to nearest
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