#include "midi.h"


/***************************************************************************
* Configure the MIDI interface
****************************************************************************/
int configMidi(XUartPs *MidiPs)
{
	int Status;
	XUartPs_Config *Config;

	// Lookup configuration from config table
	Config = XUartPs_LookupConfig(MIDI_DEVICE_ID);
	if (NULL == Config) { return XST_FAILURE; }
	// Initialize uart driver
	Status = XUartPs_CfgInitialize(MidiPs, Config, Config->BaseAddress);
	RETURN_ON_FAILURE(Status);
	// Check hardware build
	Status = XUartPs_SelfTest(MidiPs);
	RETURN_ON_FAILURE(Status);
	// Set operate mode
	XUartPs_SetOperMode(MidiPs, XUARTPS_OPER_MODE_NORMAL);
	// Set baud rate to 31.25 kHz midi standard
	XUartPs_SetBaudRate(MidiPs, 31250);

	return XST_SUCCESS;
}


/***************************************************************************
* Poll MIDI buffer until specified number of bytes received
****************************************************************************/
void readMidi(XUartPs *MidiPs, u8 *MidiBuffer, int numBytes)
{
	int count = 0;
	int rxTotal = 0;
	while (rxTotal < numBytes)
	{
		count = XUartPs_Recv(MidiPs, MidiBuffer+rxTotal, numBytes-rxTotal);
		rxTotal += count;
	}
}


/***************************************************************************
* Process the received MIDI message
****************************************************************************/
int  rxMidiMsg(XUartPs *MidiPs, u8 *MidiBuffer)
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
