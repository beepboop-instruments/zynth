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
#include "xil_printf.h"
// Zynth
#include "utils.h"
#include "midi.h"
#include "i2c.h"
#include "ssm2603.h"


/************************** Instance Definitions ***************************/
// MIDI
static XUartPs MidiPs;					/* The instance of the UART Driver */
static u8 MidiBuffer[MIDI_BUFFER_SIZE];	/* MIDI receive buffer */
// I2C
static XIic Iic;		            	/* The instance of the IIC device */
// Interrupt controller
static INTC Intc; 	                	/* The instance of the Interrupt Controller Driver */


/***************************************************************************
* Main function
****************************************************************************/
int main(void)
{
	int Status;

	// Configure MIDI UART peripheral
	Status = configMidi(&MidiPs);
	if (Status != XST_SUCCESS)
	{
		xil_printf("Failed to configure midi interface\r\n");
		return XST_FAILURE;
	}
	// Configure the I2C peripheral
	Status = configI2C(&Iic, &Intc);
	if (Status != XST_SUCCESS)
	{
		xil_printf("Failed to configure I2C interface\r\n");
		return XST_FAILURE;
	}
	// Configure the SSM2603 Audio Codec
	Status = configCodec(&Iic);
	if (Status != XST_SUCCESS)
	{
		xil_printf("Failed to configure the audio codec\r\n");
	}

	// Poll for midi messages received
	while (1) {
		// Wait until there is data then process received message
		while (!XUartPs_IsReceiveData(MIDI_BASEADDR));
		Status = rxMidiMsg(&MidiPs, MidiBuffer);
	}

}
