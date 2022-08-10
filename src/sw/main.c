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

#include "xparameters.h"
#include "xstatus.h"
#include "xil_types.h"
#include "xil_assert.h"
#include "xuartps_hw.h"
#include "xuartps.h"
#include "xil_printf.h"

/************************** Constant Definitions ***************************/

#define MIDI_BASEADDR 		XPAR_XUARTPS_0_BASEADDR
#define MIDI_DEVICE_ID      XPAR_XUARTPS_0_DEVICE_ID


/**************************** Type Definitions *****************************/

/***************** Macros (Inline Functions) Definitions *******************/

/************************** Function Prototypes ****************************/

int UartPsEchoExample(u32 UartBaseAddress0, u16 DeviceId);

/************************** Variable Definitions ***************************/

XUartPs Uart_Ps;		/* The instance of the UART Driver */

/***************************************************************************/
/**
*
* Main function
*
****************************************************************************/
int main(void)
{
	u8 RecvChar;
	int Status;
	XUartPs_Config *Config;

	/*
	 * Initialize the UART driver so that it's ready to use
	 * Look up the configuration in the config table and then initialize it.
	 */
	Config = XUartPs_LookupConfig(MIDI_DEVICE_ID);
	if (NULL == Config) {
		return XST_FAILURE;
	}

	Status = XUartPs_CfgInitialize(&Uart_Ps, Config, Config->BaseAddress);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	XUartPs_SetBaudRate(&Uart_Ps, 31250);

	while (1) {
		 // Wait until there is data
		while (!XUartPs_IsReceiveData(MIDI_BASEADDR));
		// Read uart rx buffer
		RecvChar = XUartPs_ReadReg(MIDI_BASEADDR, XUARTPS_FIFO_OFFSET);
		// Echo midi message to console
		xil_printf("0x%x\n\r",RecvChar);
	}

}
