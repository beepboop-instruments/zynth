#ifndef I2C_H_
#define I2C_H_

#include "utils.h"
#include "xiic.h"
#include "xil_exception.h"

#ifdef XPAR_INTC_0_DEVICE_ID
 #include "xintc.h"
#else
 #include "xscugic.h"
#endif

extern volatile u8 TransmitComplete;	/* Flag to check completion of Transmission */
extern volatile u8 ReceiveComplete;		/* Flag to check completion of Reception */

/***************************************************************************
* Constant definitions
****************************************************************************/
// i2c instance
#define I2C_DEVICE_ID		XPAR_IIC_0_DEVICE_ID

// Interrupt controller instance
#ifdef XPAR_INTC_0_DEVICE_ID
 #define INTC_DEVICE_ID	XPAR_INTC_0_DEVICE_ID
 #define IIC_INTR_ID	XPAR_INTC_0_IIC_0_VEC_ID
 #define INTC			XIntc
 #define INTC_HANDLER	XIntc_InterruptHandler
#else
 #define INTC_DEVICE_ID		XPAR_SCUGIC_SINGLE_DEVICE_ID
 #define IIC_INTR_ID		XPAR_FABRIC_IIC_0_VEC_ID
 #define INTC			 	XScuGic
 #define INTC_HANDLER		XScuGic_InterruptHandler
#endif


/***************************************************************************
* Function definitions
****************************************************************************/
int configI2C(XIic *Iic, INTC *Intc);
int SetupInterruptSystem(XIic *Iic, INTC *Intc);
int i2c_writeread(XIic *Iic, u8 addr, u16 numBytes, u8 *readbuffer);
int i2c_write(XIic *Iic, u8 *writebuffer, int numBytes);

#endif /* I2C_H_ */
