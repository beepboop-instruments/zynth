#ifndef I2C_H
#define I2C_H

#include "xil_types.h"
#include "xiic.h"

/************************** Constant Definitions *****************************/

/*
 * The following constants map to the XPAR parameters created in the
 * xparameters.h file. They are defined here such that a user can easily
 * change all the needed parameters in one place.
 */

#define IIC_BASE_ADDRESS	XPAR_AXI_IIC_0_BASEADDR


/**************************** Type Definitions *******************************/

/*
 * The AddressType for ML300/ML310/ML510 boards should be u16 as the address
 * pointer in the on board EEPROM is 2 bytes.
 * The AddressType for ML403/ML501/ML505/ML507/ML605/SP601/SP605 boards should
 * be u8 as the address pointer in the on board EEPROM is 1 bytes.
 */
typedef u8 AddressType;

/************************** Function Prototypes ******************************/

unsigned i2c_write_reg(AddressType i2c_addr, u8 *reg, u8 regsize, u8 *buf, u16 byte_cnt);

unsigned i2c_read_reg(AddressType i2c_addr, u8 *reg, u8 regsize, u8 *BufferPtr, u16 ByteCount);

#endif /* I2C_H */