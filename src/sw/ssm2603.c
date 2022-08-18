
#include "ssm2603.h"


/***************************************************************************
* Configure Codec
****************************************************************************/
int configCodec(XIic *Iic)
{
	int Status;
	// set the I2C address to codec
	XIic_SetAddress(Iic, XII_ADDR_TO_SEND_TYPE, SSM2603_ADDR);

	/* 1. Enable all of the necessary power management bits of
	 *    Register R6 with the exception of the out bit (Bit D4). The
	 *    out bit should not be set to 1 until the final step of the
	 *    control register sequence.
	 */

	// Set power management reg for playback only using external clock
	u16 pwr_mgmt = ~(B_PWROFF | B_OUT | B_DAC) & 0xFF;
	Status = i2c_codec_write(Iic, CODEC_PWR_MGMT, pwr_mgmt);
	RETURN_ON_FAILURE(Status);

	/* 2. After the power management bits are set, program all other
	 *    necessary registers with the exception of the active bit
	 *    [Register R9, Bit D0] and the out bit of the power manage-
	 *    ment register.
	 */
	// enable dac at output mixer
	u16 an_audio = B_DACSEL | B_MUTEMIC;
	Status = i2c_codec_write(Iic, CODEC_AN_AUDIO_PATH, an_audio);
	RETURN_ON_FAILURE(Status);

	// set clock condition for MCLK=12.288 MHz and 96 kHz sample rate
	u16 sample_rate = 0x7 << 2;
	Status = i2c_codec_write(Iic, CODEC_SAMPLE_RATE, sample_rate);
	RETURN_ON_FAILURE(Status);

	/* 3. As described in the Digital Core Clock section of the
	 *    Theory of Operation, insert enough delay time to charge
	 *    the VMID decoupling capacitor before setting the active
	 *    bit [Register R9, Bit D0].
	 *
	 *    Delay time t = C x 25,000 / 3.5
	 *    where C is the capcitance at the VMID pin
	 *
	 *    t = 10.1 uF x 25,000 / 3.5 = 73 ms
	 */
	usleep(73000);
	Status = i2c_codec_write(Iic, CODEC_ACTIVE, B_ACTIVE);
	RETURN_ON_FAILURE(Status);

	/* 4. Finally, to enable the DAC output path of the SSM2603, set
	 *    the out bit of Register R6 to 0.
	 */
	pwr_mgmt = pwr_mgmt & 0xFE;
	Status = i2c_codec_write(Iic, CODEC_PWR_MGMT, pwr_mgmt);
	RETURN_ON_FAILURE(Status);

	return XST_SUCCESS;
}

/***************************************************************************
* I2C Codec Write
****************************************************************************/
int i2c_codec_write(XIic *Iic, u8 reg, u16 data)
{
	int Status;
	u8 writedata[2] = { (u8)((reg<<1)+(data>>8)), (u8)(data & 0xFF) };
	Status = i2c_write(Iic, writedata, 2);
	RETURN_ON_FAILURE(Status);

	return XST_SUCCESS;
}
