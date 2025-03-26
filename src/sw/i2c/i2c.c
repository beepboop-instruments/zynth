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
* 0.00  tjh    03/07/25 Initial file
*
****************************************************************************/

#include "i2c.h"
#include <xiic_l.h>

/***************************************************************************
* Function definitions
****************************************************************************/

/*****************************************************************************/
/**
* This function writes a number of bytes to a given register over I2C from a
* specified buffer.
*
* @param  i2c_addr contains the 7-bit I2C address to write to.
* @param  reg contains the register address to write to.
* @param  buf contains the address of the data buffer to send.
* @param  byte_cnt contains the number of bytes in the buffer to be send.
*
* @return The number of bytes sent. A value less than the specified input
*         value indicates an error.
*
* @note   None.
*
****************************************************************************/
unsigned i2c_write_reg(AddressType i2c_addr, u8 *reg, u8 regsize, u8 *buf, u16 byte_cnt)
{
  volatile unsigned sent_cnt;
  volatile unsigned sent_byte_cnt;
  u32 cntl_reg;
  u8 write_buf[regsize + byte_cnt];

  /*
   * Add the register address to the beginning of the write buffer.
   * Then place the data in the write buffer.
   */
  for(u8 i = 0; i < regsize; i++) {
    write_buf[i] = (u8)(reg[i] >> 8*i);
  }

  for (u16 i = 0; i < byte_cnt; i++) {
    write_buf[regsize + i] = buf[i];
  }

  /*
   * Send the register address until ack received.
   */
  do {
    sent_cnt = XIic_Send(IIC_BASE_ADDRESS, i2c_addr,
            (u8 *)&reg, regsize,XIIC_STOP);

    if (sent_cnt != regsize) {
      /* Send is aborted so reset Tx FIFO */
      cntl_reg = XIic_ReadReg(IIC_BASE_ADDRESS, XIIC_CR_REG_OFFSET);
      XIic_WriteReg(IIC_BASE_ADDRESS, XIIC_CR_REG_OFFSET, cntl_reg | XIIC_CR_TX_FIFO_RESET_MASK);
      XIic_WriteReg(IIC_BASE_ADDRESS, XIIC_CR_REG_OFFSET,  XIIC_CR_ENABLE_DEVICE_MASK);
    }

  } while (sent_cnt != regsize);

  /*
   * Send the page buffer.
   */
  sent_byte_cnt = XIic_Send(IIC_BASE_ADDRESS, i2c_addr,
          write_buf, sizeof(write_buf), XIIC_STOP);

  do {
    sent_cnt = XIic_Send(IIC_BASE_ADDRESS, i2c_addr,
            (u8 *)&reg, regsize,XIIC_STOP);

    if (sent_cnt != regsize) {
      /* Send is aborted so reset Tx FIFO */
      cntl_reg = XIic_ReadReg(IIC_BASE_ADDRESS, XIIC_CR_REG_OFFSET);
      XIic_WriteReg(IIC_BASE_ADDRESS, XIIC_CR_REG_OFFSET, cntl_reg | XIIC_CR_TX_FIFO_RESET_MASK);
      XIic_WriteReg(IIC_BASE_ADDRESS, XIIC_CR_REG_OFFSET,  XIIC_CR_ENABLE_DEVICE_MASK);
    }

  } while (sent_cnt != regsize);

  /*
   * Return the number of bytes written to the EEPROM
   */
  return sent_byte_cnt;
}

/*****************************************************************************/
/**
* This function reads a number of bytes from a given register over I2C into a
* specified buffer.
*
* @param  i2c_addr contains the 7-bit I2C address to read from.
* @param  reg contains the register address to read from.
* @param  buf contains the address of the data buffer to be filled.
* @param  byte_cnt contains the number of bytes in the buffer to be read.
*
* @return The number of bytes read. A value less than the specified input
*         value indicates an error.
*
* @note   None.
*
****************************************************************************/
unsigned i2c_read_reg(AddressType i2c_addr, u8 *reg, u8 regsize, u8 *buf, u16  byte_cnt)
{
  volatile unsigned ReceivedByteCount;
  u16 StatusReg;
  u32 cntl_reg;

  u8 reg_send[regsize];

  for (u8 i = 0; i < regsize; i ++) {
      reg_send[i] = reg[i];
  }
    
  /*
   * Set the address register to the specified address by writing
   * the address to the device, this must be tried until it succeeds
   * because a previous write to the device could be pending and it
   * will not ack until that write is complete.
   */
  do {
    StatusReg = XIic_ReadReg(IIC_BASE_ADDRESS, XIIC_SR_REG_OFFSET);

    if (!(StatusReg & XIIC_SR_BUS_BUSY_MASK)) {
      ReceivedByteCount = XIic_Send(
                  IIC_BASE_ADDRESS,
                  i2c_addr,
                  (u8 *)&reg_send,
                  sizeof(reg_send),
                  XIIC_REPEATED_START);

      if (ReceivedByteCount != sizeof(reg_send)) {

        /* Send is aborted so reset Tx FIFO */
        cntl_reg = XIic_ReadReg(IIC_BASE_ADDRESS, XIIC_CR_REG_OFFSET);
        XIic_WriteReg(IIC_BASE_ADDRESS, XIIC_CR_REG_OFFSET, cntl_reg | XIIC_CR_TX_FIFO_RESET_MASK);
        XIic_WriteReg(IIC_BASE_ADDRESS, XIIC_CR_REG_OFFSET, XIIC_CR_ENABLE_DEVICE_MASK);
      }
    }

  } while (ReceivedByteCount != sizeof(reg_send));

  buf[0] = 0;

  /*
   * Read the number of bytes at the specified address from the EEPROM.
   */
  ReceivedByteCount = XIic_Recv(IIC_BASE_ADDRESS, i2c_addr,
              buf, byte_cnt, XIIC_STOP);

  /*
   * Return the number of bytes read from the EEPROM.
   */
  return ReceivedByteCount;
}
