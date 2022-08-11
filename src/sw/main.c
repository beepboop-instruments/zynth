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
#include "xuartps.h"
#include "xil_printf.h"

#include "midi.h"

/***************************  Macro Definitions ****************************/

#define DEBUG

#ifdef DEBUG
#define DEBUG_PRINT(x) xil_printf x
#else
#define DEBUG_PRINT(x) do {} while (0)
#endif

/************************** Constant Definitions ***************************/

#define MIDI_BASEADDR 		XPAR_XUARTPS_0_BASEADDR
#define MIDI_DEVICE_ID      XPAR_XUARTPS_0_DEVICE_ID

#define MIDI_BUFFER_SIZE    100


/**************************** Type Definitions *****************************/

/***************** Macros (Inline Functions) Definitions *******************/

/************************** Function Prototypes ****************************/

static int  configMidi(XUartPs *MidiPs);
static int  rxMidiMsg(XUartPs *MidiPs);
       void readMidi(XUartPs *MidPs, u8 *buffer, int numBytes);

/************************** Variable Definitions ***************************/

XUartPs MidiPs;		                     /* The instance of the UART Driver */
static u8 MidiBuffer[MIDI_BUFFER_SIZE];  /* MIDI receive buffer */

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
		xil_printf("Failed to configure midi interface");
		return XST_FAILURE;
	}

	// Poll for midi messages received
	while (1) {
		// Wait until there is data then process received message
		while (!XUartPs_IsReceiveData(MIDI_BASEADDR));
		Status = rxMidiMsg(&MidiPs);
	}

}

/***************************************************************************
* Configure the MIDI interface
****************************************************************************/
static int configMidi(XUartPs *MidiPs)
{
	int Status;
	XUartPs_Config *Config;

	// Lookup configuration from config table
	Config = XUartPs_LookupConfig(MIDI_DEVICE_ID);
	if (NULL == Config) {
		return XST_FAILURE;
	}
	// Initialize uart driver
	Status = XUartPs_CfgInitialize(MidiPs, Config, Config->BaseAddress);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}
	// Check hardware build
	Status = XUartPs_SelfTest(MidiPs);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}
	// Set operate mode
	XUartPs_SetOperMode(MidiPs, XUARTPS_OPER_MODE_NORMAL);
	// Set baud rate to 31.25 kHz midi standard
	XUartPs_SetBaudRate(MidiPs, 31250);

	return XST_SUCCESS;
}

/***************************************************************************
* Process the recieved MIDI message
****************************************************************************/
static int  rxMidiMsg(XUartPs *MidiPs)
{
	// Read uart rx buffer
	XUartPs_Recv(MidiPs, MidiBuffer, 1);
	char command = (MidiBuffer[0] & 0xF0);
	char midiCh  = (MidiBuffer[0] & 0x0F);
	char key;
	char value;
	int pitchBend;
	switch (command)
	{
	case NOTE_OFF:
		readMidi(MidiPs, MidiBuffer, 2);
		key = MidiBuffer[0];
		value = MidiBuffer[1];
		DEBUG_PRINT(("MIDI %i note off: %03i %03i \n\r", midiCh, key, value));
		break;
	case NOTE_ON:
		readMidi(MidiPs, MidiBuffer, 2);
		key = MidiBuffer[0];
		value = MidiBuffer[1];
		DEBUG_PRINT(("MIDI %i note on:  %03i %03i \n\r", midiCh, key, value));
		break;
	case POLY_PRESSURE:
		readMidi(MidiPs, MidiBuffer, 2);
		key = MidiBuffer[0];
		value = MidiBuffer[1];
		DEBUG_PRINT(("MIDI %i polyphonic pressure: %03i %03i \n\r", midiCh, key, value));
		break;
	case CONTROL_CHANGE:
		readMidi(MidiPs, MidiBuffer, 2);
		key = MidiBuffer[0];
		value = MidiBuffer[1];
		DEBUG_PRINT(("MIDI %i control change: %03i %03i \n\r", midiCh, key, value));
		break;
	case PROG_CHANGE:
		readMidi(MidiPs, MidiBuffer, 1);
		key = MidiBuffer[0];
		DEBUG_PRINT(("MIDI %i program change: %03i \n\r", midiCh, key));
		break;
	case CH_PRESSURE:
		readMidi(MidiPs, MidiBuffer, 1);
		value = MidiBuffer[0];
		DEBUG_PRINT(("MIDI %i channel pressure: %03i \n\r", midiCh, value));
		break;
	case PITCH_BEND:
		readMidi(MidiPs, MidiBuffer, 2);
		pitchBend = (MidiBuffer[1]<<7) + MidiBuffer[0] - 0x2000;
		DEBUG_PRINT(("MIDI %i pitch bend: %04i \n\r", midiCh, pitchBend));
		break;
	}

	return XST_SUCCESS;
}

/***************************************************************************
* Poll MIDI buffer until specified number of bytes received
****************************************************************************/
void readMidi(XUartPs *MidiPs, u8 *buffer, int numBytes)
{
	int count = 0;
	int rxTotal = 0;
	while (rxTotal < numBytes)
	{
		count = XUartPs_Recv(MidiPs, buffer+rxTotal, numBytes-rxTotal);
		rxTotal += count;
	}
}
