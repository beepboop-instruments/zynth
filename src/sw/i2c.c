/****************************************************************************/
/**
* i2c.c
*
* This file contains the functions for basic I2C transactions using the
* AXI IIC module.
*
*
* REVISION HISTORY:
*
* Ver   Who    Date     Changes
* ----- ------ -------- -----------------------------------------------------
* 0.00  tjh    08/19/22 Initial file
*
****************************************************************************/

#include "i2c.h"

/***************************************************************************
* Variable definitions
****************************************************************************/

// I2C TX and RX flags
volatile u8 TransmitComplete;	/* Flag to check completion of Transmission */
volatile u8 ReceiveComplete;	/* Flag to check completion of Reception */

/***************************************************************************
* Function definitions
****************************************************************************/

// Handler function definitions
static void StatusHandler(XIic *InstancePtr, int Event);
static void SendHandler(XIic *InstancePtr);
static void ReceiveHandler(XIic *InstancePtr);

/***************************************************************************
* Configure the I2C interface
****************************************************************************/
int configI2C(XIic *Iic, INTC *Intc)
{
	int Status;
	XIic_Config *Config;

	// initialize the I2C driver
	Config = XIic_LookupConfig(I2C_DEVICE_ID);
	if(Config == NULL) {
		return XST_FAILURE;
	}
	Status = XIic_CfgInitialize(Iic, Config, Config->BaseAddress);
	RETURN_ON_FAILURE(Status);
	// setup the interrupt system
	Status = SetupInterruptSystem(Iic, Intc);
	RETURN_ON_FAILURE(Status);
	// set the interrupt handlers
	XIic_SetSendHandler(Iic, Iic, (XIic_Handler) SendHandler);
	XIic_SetRecvHandler(Iic, Iic, (XIic_Handler) ReceiveHandler);
	XIic_SetStatusHandler(Iic, Iic, (XIic_StatusHandler) StatusHandler);

	return XST_SUCCESS;
}


/***************************************************************************
* I2C error interrupt handlers
****************************************************************************/
static void StatusHandler(XIic *InstancePtr, int Event)
{
	switch (Event)
		{
			case XII_BUS_NOT_BUSY_EVENT:
				xil_printf("bus not busy event");
				break;

			case XII_ARB_LOST_EVENT:
				xil_printf("arb lost event");
				break;
			case XII_SLAVE_NO_ACK_EVENT:
				xil_printf("no ack event");
				break;
				break;
		}
}
static void SendHandler(XIic *InstancePtr)
{
	TransmitComplete = 0;
}
static void ReceiveHandler(XIic *InstancePtr)
{
	ReceiveComplete = 0;
}


/***************************************************************************
* Configure the I2C interrupt system
****************************************************************************/
int SetupInterruptSystem(XIic *Iic, INTC *Intc)
{
	int Status;

#ifdef XPAR_INTC_0_DEVICE_ID

	// intialize interrupt controller
	Status = XIntc_Initialize(*Intc, INTC_DEVICE_ID);
	RETURN_ON_FAILURE(Status);
	// connect device driver for interrupts
	Status = XIntc_Connect(*Intc, IIC_INTR_ID,  (XInterruptHandler) XIic_InterruptHandler, Iic);
	RETURN_ON_FAILURE(Status);
	// start interrupt controller
	Status = XIntc_Start(*Intc, XIN_REAL_MODE);
	RETURN_ON_FAILURE(Status);
	// enable interrupts on the I2C device
	XIntc_Enable(*Intc, IIC_INTR_ID);

#else
	// interrupt controller pointer
	XScuGic_Config *IntcConfig;
	// initialize interrupt controller
	IntcConfig = XScuGic_LookupConfig(INTC_DEVICE_ID);
	if (NULL == IntcConfig) {
		return XST_FAILURE;
	}
	Status = XScuGic_CfgInitialize(Intc, IntcConfig, IntcConfig->CpuBaseAddress);
	RETURN_ON_FAILURE(Status);
	XScuGic_SetPriorityTriggerType(Intc, IIC_INTR_ID, 0xA0, 0x3);
	// connect the interrupt handler
	Status = XScuGic_Connect(Intc, IIC_INTR_ID, (Xil_InterruptHandler)XIic_InterruptHandler, Iic);
	RETURN_ON_FAILURE(Status);
	// enable the I2C device interrupt
	XScuGic_Enable(Intc, IIC_INTR_ID);

#endif

	// initialize the exception table
	Xil_ExceptionInit();
	// register the interrupt with exception table
	Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT, (Xil_ExceptionHandler)INTC_HANDLER, Intc);
	// enable non-critical exceptions
	Xil_ExceptionEnable();

	return XST_SUCCESS;
}


/***************************************************************************
* I2C read register function
****************************************************************************/
int i2c_writeread(XIic *Iic, u8 addr, u16 numBytes, u8 *readbuffer)
{
	int Status;
	// place register address in write buffer
	u8 writedata[1] = {addr};
	// initialize i2c flags and error counter
	TransmitComplete = 1;
	ReceiveComplete = 1;
	Iic->Stats.TxErrors = 0;

	// enable repeated start for an I2C write read
	Iic->Options = XII_REPEATED_START_OPTION;
	// start the I2C device
	Status = XIic_Start(Iic);
	RETURN_ON_FAILURE(Status);
	// send the write data
	Status = XIic_MasterSend(Iic, writedata, 1);
	RETURN_ON_FAILURE(Status);

	// wait until the transmission is complete
	while (TransmitComplete)
	{
		// check for TX errors and retry if any occurred
		if (Iic->Stats.TxErrors != 0)
		{
			Status = XIic_Start(Iic);
			RETURN_ON_FAILURE(Status);
			if (!XIic_IsIicBusy(Iic))
			{
				Status = XIic_MasterSend(Iic, writedata, 1);
				if (Status == XST_SUCCESS)
				{
					Iic->Stats.TxErrors = 0;
				}
			}
		}
	}

	// turn off repeated start, so stop bit occurs at the end of read
	Iic->Options = 0;
	// get read data
	Status = XIic_MasterRecv(Iic, readbuffer, numBytes);
	RETURN_ON_FAILURE(Status);

	// wait until the data is received
	while ((ReceiveComplete) || (XIic_IsIicBusy(Iic) == TRUE)) { }

	// stop the I2C device
	Status = XIic_Stop(Iic);
	RETURN_ON_FAILURE(Status);

	return XST_SUCCESS;
}


/***************************************************************************
* I2C read register function
****************************************************************************/
int i2c_write(XIic *Iic, u8 *writebuffer, int numBytes)
{
	int Status;
	// initialize i2c flags and error counter
	TransmitComplete = 1;
	Iic->Stats.TxErrors = 0;

	// turn off repeated start, so stop bit occurs at the end of write
	Iic->Options = 0;

	// start the I2C device
	Status = XIic_Start(Iic);
	RETURN_ON_FAILURE(Status);
	// send the write data
	Status = XIic_MasterSend(Iic, writebuffer, numBytes);
	RETURN_ON_FAILURE(Status);

	// wait until the transmission is complete
	while (TransmitComplete || (XIic_IsIicBusy(Iic) == TRUE))
	{
		// check for TX errors and retry if any occurred
		if (Iic->Stats.TxErrors != 0)
		{
			Status = XIic_Start(Iic);
			RETURN_ON_FAILURE(Status);
			if (!XIic_IsIicBusy(Iic))
			{
				Status = XIic_MasterSend(Iic, writebuffer, numBytes);
				if (Status == XST_SUCCESS)
				{
					Iic->Stats.TxErrors = 0;
				}
			}
		}
	}

	// stop the I2C device
	Status = XIic_Stop(Iic);
	RETURN_ON_FAILURE(Status);

	return XST_SUCCESS;
}
