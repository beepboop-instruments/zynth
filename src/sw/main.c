/****************************************************************************/
/**
* main.c
*
* This file contains the main function and loop.
*
*
* REVISION HISTORY:
*
* Ver   Who    Date     Changes
* ----- ------ -------- -----------------------------------------------------
* 0.00  tjh    08/09/22 Initial file
*
****************************************************************************/

/***************************** Include Files *******************************/
// Xilinx
#include "xparameters.h"
#include "xstatus.h"
#include "xil_types.h"
#include "xil_assert.h"
#include "xuartps.h"
#include "xiic.h"
#include "xil_io.h"
#include "xil_printf.h"
// Zynth
#include "utils/utils.h"
#include "midi/midi.h"
#include "i2c/i2c.h"
#include "ssm2603/ssm2603.h"
#include "synth_ctrl/synth_ctrl.h"

/***************************************************************************
* Main function
****************************************************************************/

int main(void) {


	// Initialize synthesizer
	if (initSynth() || checkSynthCtrl()) {
		xil_printf("Synthesizer initialization error occurred!\r\n");
	}

	// Configure audio codec
	if (configCodec()) { 
		xil_printf("Config codec error occurred!\r\n");
	}

	// Configure MIDI UART peripheral
	if (configMidi(MIDI_BASEADDR)) {
		xil_printf("Failed to configure midi interface\r\n");
		return XST_FAILURE;
	}

    u32 count = 0;
	// Poll for midi messages received
	while (1) {
        if (count++ > 10000000) {
            xil_printf("ALIVE\r\n");
            count = 0;
        }
		// Wait until there is data then process received message
		if (!rb_is_empty(&midi_rb)) {
			rxMidiMsg();
		}
	}

}
