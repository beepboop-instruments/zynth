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


/************************** Instance Definitions ***************************/
/*
 * The following constants map to the XPAR parameters created in the
 * xparameters.h file. They are defined here such that a user can easily
 * change all the needed parameters in one place.
 */
#ifndef SDT
#define UART_DEVICE_ID              XPAR_XUARTPS_0_DEVICE_ID
#else
#define	XUARTPS_BASEADDRESS	XPAR_XUARTPS_0_BASEADDR
#endif


/***************************************************************************
* Main function
****************************************************************************/
int main(void)
{
	int Status;

    Status = checkSynthCtrl();

    setWaveAmp(SINE_WAVE, 0x1F);
    setOutAmp(0x3F);
    setOutShift(0xA);
	
	// Configure audio codec
    if (configCodec()) { 
        xil_printf("Config codec error occurred!\r\n");
    }

	// Configure MIDI UART peripheral
	if (configMidi(XUARTPS_BASEADDRESS)) {
		xil_printf("Failed to configure midi interface\r\n");
		return XST_FAILURE;
	}

    // Poll for midi messages received
	while (1) {
		// Wait until there is data then process received message
		while (!XUartPs_IsReceiveData(XUARTPS_BASEADDRESS));
		rxMidiMsg();
	}

    return Status;

}
