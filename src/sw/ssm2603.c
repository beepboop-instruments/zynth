/****************************************************************************/
/**
* ssm2603.c
*
* This file contains the functions for configuring the ADI SSM2603 audio
* Codec over I2C.
*
*
* REVISION HISTORY:
*
* Ver   Who    Date     Changes
* ----- ------ -------- -----------------------------------------------------
* 0.00  tjh    08/19/22 Initial file
*
****************************************************************************/

#include "ssm2603.h"

/***************************************************************************
* Configure Codec
****************************************************************************/
int configCodec(XIic *Iic)
{
	int Status;
	codecSSM2603 myCodec;
	// set the I2C address to codec
	XIic_SetAddress(Iic, XII_ADDR_TO_SEND_TYPE, SSM2603_ADDR);

	/* 1. Enable all of the necessary power management bits of
	 *    Register R6 with the exception of the out bit (Bit D4). The
	 *    out bit should not be set to 1 until the final step of the
	 *    control register sequence.
	 */

	// Set power management reg for playback only using external clock
	Status = i2c_codec_write(Iic, CODEC_PWR_MGMT, PM_PB_ONLY_EXT);
	RETURN_ON_FAILURE(Status);

	/* 2. After the power management bits are set, program all other
	 *    necessary registers with the exception of the active bit
	 *    [Register R9, Bit D0] and the out bit of the power manage-
	 *    ment register.
	 */
	// enable dac at output mixer
	Status = i2c_codec_write(Iic, CODEC_AN_AUDIO_PATH, (M_DACSEL | M_MUTEMIC) );
	RETURN_ON_FAILURE(Status);

	// set clock condition for MCLK=12.288 MHz and 96 kHz sample rate
	Status = i2c_codec_write(Iic, CODEC_SAMPLE_RATE, (0x7 << 2) );
	RETURN_ON_FAILURE(Status);

	// unmute the DAC output
	Status = i2c_codec_write(Iic, CODEC_DIG_AUDIO_PATH, 0 );
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
	Status = i2c_codec_write(Iic, CODEC_ACTIVE, M_ACTIVE);
	RETURN_ON_FAILURE(Status);

	/* 4. Finally, to enable the DAC output path of the SSM2603, set
	 *    the out bit of Register R6 to 0.
	 */
	Status = i2c_codec_write(Iic, CODEC_PWR_MGMT, (PM_PB_ONLY_EXT & (~M_OUT)) );
	RETURN_ON_FAILURE(Status);

	get_codec_config(Iic, &myCodec);
#ifdef DEBUG
	print_codec_config(&myCodec);
#endif

	return XST_SUCCESS;
}


/***************************************************************************
* Read configuration registers from codec
****************************************************************************/
int get_codec_config(XIic *Iic, codecSSM2603 *myCodec)
{
	int Status;
	u8  readbuffer[2];

	// read left ADC input volume
	Status = i2c_codec_read(Iic, CODEC_L_ADC_VOL, 2, readbuffer);
	RETURN_ON_FAILURE(Status);
	myCodec->lrinboth =  readbuffer[1];
	myCodec->linmute  = (readbuffer[0] & M_LINMUTE) >> B_LINMUTE;
	myCodec->linvol   = (readbuffer[0] & M_LINVOL)  >> B_LINVOL;

	// read right ADC input volume
	Status = i2c_codec_read(Iic, CODEC_R_ADC_VOL, 2, readbuffer);
	RETURN_ON_FAILURE(Status);
	myCodec->rlinboth =  readbuffer[1];
	myCodec->rinmute  = (readbuffer[0] & M_RINMUTE) >> B_RINMUTE;
	myCodec->rinvol   = (readbuffer[0] & M_RINVOL)  >> B_RINVOL;

	// read left DAC output volume
	Status = i2c_codec_read(Iic, CODEC_L_DAC_VOL, 2, readbuffer);
	RETURN_ON_FAILURE(Status);
	myCodec->lrhpboth =  readbuffer[1];
	myCodec->lhpvol   = (readbuffer[0] & M_LHPVOL)  >> B_LHPVOL;

	// read right DAC output volume
	Status = i2c_codec_read(Iic, CODEC_R_DAC_VOL, 2, readbuffer);
	RETURN_ON_FAILURE(Status);
	myCodec->rlhpboth =  readbuffer[1];
	myCodec->rhpvol   = (readbuffer[0] & M_RHPVOL)  >> B_RHPVOL;

	// read analog audio path
	Status = i2c_codec_read(Iic, CODEC_AN_AUDIO_PATH, 2, readbuffer);
	RETURN_ON_FAILURE(Status);
	myCodec->sidetone_attn = (readbuffer[0] & M_SIDETONE_ATT) >> B_SIDETONE_ATT;
	myCodec->sidetone_en   = (readbuffer[0] & M_SIDETONE_EN)  >> B_SIDETONE_EN;
	myCodec->dacsel        = (readbuffer[0] & M_DACSEL)       >> B_DACSEL;
	myCodec->bypass        = (readbuffer[0] & M_BYPASS)       >> B_BYPASS;
	myCodec->insel         = (readbuffer[0] & M_INSEL)        >> B_INSEL;
	myCodec->mutemic       = (readbuffer[0] & M_MUTEMIC)      >> B_MUTEMIC;
	myCodec->micboost      = (readbuffer[0] & M_MICBOOST)     >> B_MICBOOST;

	// read digital audio path
	Status = i2c_codec_read(Iic, CODEC_DIG_AUDIO_PATH, 2, readbuffer);
	RETURN_ON_FAILURE(Status);
	myCodec->hpor   = (readbuffer[0] & M_HPOR)   >> B_HPOR;
	myCodec->dacmu  = (readbuffer[0] & M_DACMU)  >> B_DACMU;
	myCodec->deemph = (readbuffer[0] & M_DEEMPH) >> B_DEEMPH;
	myCodec->adchpf = (readbuffer[0] & M_ADCHPF) >> B_ADCHPF;

	// power management
	Status = i2c_codec_read(Iic, CODEC_PWR_MGMT, 2, readbuffer);
	RETURN_ON_FAILURE(Status);
	myCodec->pwroff = (readbuffer[0] & M_PWROFF) >> B_PWROFF;
	myCodec->clkout = (readbuffer[0] & M_CLKOUT) >> B_CLKOUT;
	myCodec->osc    = (readbuffer[0] & M_OSC)    >> B_OSC;
	myCodec->out    = (readbuffer[0] & M_OUT)    >> B_OUT;
	myCodec->dac    = (readbuffer[0] & M_DAC)    >> B_DAC;
	myCodec->adc    = (readbuffer[0] & M_ADC)    >> B_ADC;
	myCodec->mic    = (readbuffer[0] & M_MIC)    >> B_MIC;
	myCodec->linein = (readbuffer[0] & M_LINEIN) >> B_LINEIN;

	// digital audio i/f
	Status = i2c_codec_read(Iic, CODEC_DIG_AUDIO_IF, 2, readbuffer);
	RETURN_ON_FAILURE(Status);
	myCodec->bclkinv = (readbuffer[0] & M_BCLKINV) >> B_BCLKINV;
	myCodec->ms      = (readbuffer[0] & M_MS)      >> B_MS;
	myCodec->lrswap  = (readbuffer[0] & M_LRSWAP)  >> B_LRSWAP;
	myCodec->lrp     = (readbuffer[0] & M_LRP)     >> B_LRP;
	myCodec->wl      = (readbuffer[0] & M_WL)      >> B_WL;
	myCodec->format  = (readbuffer[0] & M_FORMAT)  >> B_FORMAT;

	// sampling rate
	Status = i2c_codec_read(Iic, CODEC_SAMPLE_RATE, 2, readbuffer);
	RETURN_ON_FAILURE(Status);
	myCodec->clkodiv2 = (readbuffer[0] & M_CLKODIV2) >> B_CLKODIV2;
	myCodec->clkdiv2  = (readbuffer[0] & M_CLKDIV2)  >> B_CLKDIV2;
	myCodec->sr       = (readbuffer[0] & M_SR)       >> B_SR;
	myCodec->bosr     = (readbuffer[0] & M_BOSR)     >> B_BOSR;
	myCodec->usb      = (readbuffer[0] & M_USB)      >> B_USB;

	// active
	Status = i2c_codec_read(Iic, CODEC_ACTIVE, 2, readbuffer);
	RETURN_ON_FAILURE(Status);
	myCodec->active = readbuffer[0];

	// ALC control 1
	Status = i2c_codec_read(Iic, CODEC_ALC_CTRL1, 2, readbuffer);
	RETURN_ON_FAILURE(Status);
	myCodec->alcsel  = (readbuffer[1] << 1) + ((readbuffer[0] & M_ALCSEL)  >> B_ALCSEL);
	myCodec->maxgain = (readbuffer[0] & M_MAXGAIN) >> B_MAXGAIN;
	myCodec->alcl    = (readbuffer[0] & M_ALCL)    >> B_ALCL;

	// ALC control 2
	Status = i2c_codec_read(Iic, CODEC_ALC_CTRL2, 2, readbuffer);
	RETURN_ON_FAILURE(Status);
	myCodec->dcy = (readbuffer[0] & M_DCY) >> B_DCY;
	myCodec->atk = (readbuffer[0] & M_ATK) >> B_ATK;

	// noise gate
	Status = i2c_codec_read(Iic, CODEC_NOISE_GATE, 2, readbuffer);
	RETURN_ON_FAILURE(Status);
	myCodec->ngth = (readbuffer[0] & M_NGTH) >> B_NGTH;
	myCodec->ngg  = (readbuffer[0] & M_NGG)  >> B_NGG;
	myCodec->ngat = (readbuffer[0] & M_NGAT) >> B_NGAT;


	return XST_SUCCESS;
}


/***************************************************************************
* Print codec settings over serial debug
****************************************************************************/
void print_codec_config(codecSSM2603 *myCodec)
{
	// print a header
	DEBUG_PRINT(("-------------------------\n\r"));
	DEBUG_PRINT(("-------------------------\n\r"));
	DEBUG_PRINT(("Audio Codec Configuration\n\r"));
	DEBUG_PRINT(("-------------------------\n\r"));

	// Active
	DEBUG_PRINT(("Active: "));
	if (myCodec->active == 1)   { DEBUG_PRINT(("yes\n\r")); }
	else                        { DEBUG_PRINT(("no\n\r"));  }

	// Power management
	DEBUG_PRINT(("Power - whole chip: "));
	if (myCodec->pwroff == 1)   { DEBUG_PRINT(("off\n\r"));}
	else                        { DEBUG_PRINT(("on\n\r")); }
	DEBUG_PRINT(("Power - clock out: "));
	if (myCodec->clkout == 1)   { DEBUG_PRINT(("off\n\r"));}
	else                        { DEBUG_PRINT(("on\n\r")); }
	DEBUG_PRINT(("Power - crystal: "));
	if (myCodec->osc == 1)      { DEBUG_PRINT(("off\n\r"));}
	else                        { DEBUG_PRINT(("on\n\r")); }
	DEBUG_PRINT(("Power - output: "));
	if (myCodec->out == 1)      { DEBUG_PRINT(("off\n\r"));}
	else                        { DEBUG_PRINT(("on\n\r")); }
	DEBUG_PRINT(("Power - DAC: "));
	if (myCodec->dac == 1)      { DEBUG_PRINT(("off\n\r"));}
	else                        { DEBUG_PRINT(("on\n\r")); }
	DEBUG_PRINT(("Power - ADC: "));
	if (myCodec->adc == 1)      { DEBUG_PRINT(("off\n\r"));}
	else                        { DEBUG_PRINT(("on\n\r")); }
	DEBUG_PRINT(("Power - mic input: "));
	if (myCodec->mic == 1)      { DEBUG_PRINT(("off\n\r"));}
	else                        { DEBUG_PRINT(("on\n\r")); }
	DEBUG_PRINT(("Power - line input: "));
	if (myCodec->linein == 1)   { DEBUG_PRINT(("off\n\r"));}
	else                        { DEBUG_PRINT(("on\n\r")); }

	// Digital Audio I/F
	DEBUG_PRINT(("Format: "));
	switch(myCodec->format) {
	case(0): DEBUG_PRINT(("right justified\n\r")); break;
	case(1): DEBUG_PRINT(("left justified\n\r")); break;
	case(2): DEBUG_PRINT(("I2S mode\n\r")); break;
	case(3): DEBUG_PRINT(("DSP mode\n\r")); break;
	default: break; }
	DEBUG_PRINT(("Data word length: "));
	switch(myCodec->wl) {
	case(0): DEBUG_PRINT(("16 bits\n\r")); break;
	case(1): DEBUG_PRINT(("20 bits\n\r")); break;
	case(2): DEBUG_PRINT(("24 bits\n\r")); break;
	case(3): DEBUG_PRINT(("32 bits\n\r")); break;
	default: break; }
	DEBUG_PRINT(("Master mode: "));
	if (myCodec->ms == 1)       { DEBUG_PRINT(("enabled\n\r"));                   }
	else                        { DEBUG_PRINT(("disabled (secondary mode)\n\r")); }
	DEBUG_PRINT(("BCLK inversion: "));
	if (myCodec->bclkinv == 1)  { DEBUG_PRINT(("inverted\n\r"));     }
	else                        { DEBUG_PRINT(("not inverted\n\r")); }
	DEBUG_PRINT(("Left and right output swap: "));
	if (myCodec->lrswap == 1)   { DEBUG_PRINT(("enabled\n\r"));  }
	else                        { DEBUG_PRINT(("disabled\n\r")); }
	DEBUG_PRINT(("Polarity control: "));
	if (myCodec->lrp == 1)      { DEBUG_PRINT(("invert PBLRC & RECLRC polarity, or DSP submodule 2\n\r")); }
	else                        { DEBUG_PRINT(("normal PBLRC & RECLRC, or DSP submodule 1\n\r"));

	// Analog audio path
	DEBUG_PRINT(("Mic mixed to output: "));
	if (myCodec->sidetone_en == 1) { DEBUG_PRINT(("enabled\n\r"));  }
	else                           { DEBUG_PRINT(("disabled\n\r")); }
	DEBUG_PRINT(("Mic attenuation: -%i dB\n\r", (6 + 3*myCodec->sidetone_attn) ));
	DEBUG_PRINT(("DAC mixed to output: "));
	if (myCodec->dacsel == 1)      { DEBUG_PRINT(("enabled\n\r"));  }
	else                           { DEBUG_PRINT(("disabled\n\r")); }
	DEBUG_PRINT(("Line in mixed to output: "));
	if (myCodec->bypass == 1)      { DEBUG_PRINT(("enabled\n\r"));  }
	else                           { DEBUG_PRINT(("disabled\n\r")); }
	DEBUG_PRINT(("Input select: "));
	if (myCodec->insel == 1)       { DEBUG_PRINT(("microphone\n\r")); }
	else                           { DEBUG_PRINT(("line in\n\r"));    }
	DEBUG_PRINT(("Mic mute: "));
	if (myCodec->mutemic == 1)     { DEBUG_PRINT(("enabled\n\r"));  }
	else                           { DEBUG_PRINT(("disabled\n\r")); }
	DEBUG_PRINT(("Mic boost: "));
	if (myCodec->micboost == 1)    { DEBUG_PRINT(("20 dB\n\r"));}
	else                           { DEBUG_PRINT(("0 dB\n\r")); }

	// Digital audio path
	DEBUG_PRINT(("Store DC offset: "));
	if (myCodec->hpor == 1)     { DEBUG_PRINT(("enabled\n\r"));  }
	else                        { DEBUG_PRINT(("disabled\n\r")); }
	DEBUG_PRINT(("DAC mute: "));
	if (myCodec->dacmu == 1)    { DEBUG_PRINT(("enabled\n\r"));  }
	else                        { DEBUG_PRINT(("disabled\n\r")); }
	DEBUG_PRINT(("De-emphasis control: "));
	switch(myCodec->deemph) {
	case(0): DEBUG_PRINT(("none\n\r")); break;
	case(1): DEBUG_PRINT(("32 kHz sampling rate\n\r")); break;
	case(2): DEBUG_PRINT(("44.1 kHz sampling rate\n\r")); break;
	case(3): DEBUG_PRINT(("48 kHz sampling rate\n\r")); break;
	default: break; }
	DEBUG_PRINT(("ADC HPF: "));
	if (myCodec->adchpf == 1)   { DEBUG_PRINT(("disabled\n\r"));}
	else                        { DEBUG_PRINT(("enabled\n\r")); }        }

	// ADC volume
	DEBUG_PRINT(("ADC left to right: "));
	if (myCodec->lrinboth == 1) { DEBUG_PRINT(("enabled\n\r"));  }
	else                        { DEBUG_PRINT(("disabled\n\r")); }
	DEBUG_PRINT(("ADC right to left: "));
	if (myCodec->rlinboth == 1) { DEBUG_PRINT(("enabled\n\r"));  }
	else                        { DEBUG_PRINT(("disabled\n\r")); }
	DEBUG_PRINT(("ADC Left in mute: "));
	if (myCodec->linmute == 1) { DEBUG_PRINT(("enabled\n\r"));   }
	else                       { DEBUG_PRINT(("disabled\n\r"));  }
	DEBUG_PRINT(("ADC right in mute: "));
	if (myCodec->rinmute == 1) { DEBUG_PRINT(("enabled\n\r"));   }
	else                       { DEBUG_PRINT(("disabled\n\r"));  }
	DEBUG_PRINT(("ADC left in volume: %i%%\n\r",  (myCodec->linvol*100/63) ));
	DEBUG_PRINT(("ADC right in volume: %i%%\n\r", (myCodec->rinvol*100/63) ));

	// DAC volume
	DEBUG_PRINT(("DAC HP left to right: "));
	if (myCodec->lrhpboth == 1) { DEBUG_PRINT(("enabled\n\r"));  }
	else                        { DEBUG_PRINT(("disabled\n\r")); }
	DEBUG_PRINT(("DAC HP right to left: "));
	if (myCodec->rlhpboth == 1) { DEBUG_PRINT(("enabled\n\r"));  }
	else                        { DEBUG_PRINT(("disabled\n\r")); }
	DEBUG_PRINT(("DAC left out volume: %i%%\n\r", (myCodec->lhpvol*100/127) ));
	DEBUG_PRINT(("DAC right out volume: %i%%\n\r", (myCodec->rhpvol*100/127) ));

	// Sampling rate
	DEBUG_PRINT(("CLKOUT select: "));
	if (myCodec->clkodiv2 == 1) { DEBUG_PRINT(("core clock divided by 2\n\r")); }
	else                        { DEBUG_PRINT(("core clock\n\r"));              }
	DEBUG_PRINT(("Core clock select: "));
	if (myCodec->clkdiv2 == 1)  { DEBUG_PRINT(("MCLK divided by 2\n\r")); }
	else                        { DEBUG_PRINT(("MCLK\n\r"));              }
	DEBUG_PRINT(("Sample rate setting: 0x%x\n\r", myCodec->sr));
	DEBUG_PRINT(("USB mode select: "));
	if (myCodec->usb == 1)      { DEBUG_PRINT(("enabled\n\r"));  }
	else                        { DEBUG_PRINT(("disabled\n\r")); }
	DEBUG_PRINT(("Base oversampling rate: "));
	if (myCodec->bosr == 1 && myCodec->usb == 1)  { DEBUG_PRINT(("272 fs\n\r"));  }
	if (myCodec->bosr == 0 && myCodec->usb == 1)  { DEBUG_PRINT(("250 fs\n\r"));  }
	if (myCodec->bosr == 1 && myCodec->usb == 0)  { DEBUG_PRINT(("256 fs\n\r"));  }
	if (myCodec->bosr == 0 && myCodec->usb == 0)  { DEBUG_PRINT(("384 fs\n\r"));  }

	// ALC control
	DEBUG_PRINT(("ALC select: "));
	switch(myCodec->alcsel) {
	case(0): DEBUG_PRINT(("disabled\n\r")); break;
	case(1): DEBUG_PRINT(("enabled (right only)\n\r")); break;
	case(2): DEBUG_PRINT(("enabled (left only)")); break;
	case(3): DEBUG_PRINT(("enabled (both)\n\r")); break;
	default: break; }
	DEBUG_PRINT(("ALC max gain: %i dB\n\r", (6*(double)(myCodec->maxgain)-12) ));
	DEBUG_PRINT(("ALC target level: %d dBFS\n\r", (1.5*(double)(myCodec->maxgain)-28.5) ));
	DEBUG_PRINT(("ALC decay: %i ms\n\r", (2^myCodec->dcy*24) ));
	DEBUG_PRINT(("ALC attack: %i ms\n\r", (2^myCodec->atk*6) ));

	// Noise gate
	DEBUG_PRINT(("Noise gate: "));
	if (myCodec->ngat == 1) { DEBUG_PRINT(("enabled\n\r"));  }
	else                    { DEBUG_PRINT(("disabled\n\r")); }
	DEBUG_PRINT(("Noise gate type: "));
	switch(myCodec->ngg) {
	case(0):
	case(2): DEBUG_PRINT(("hold PGA gain constant\n\r")); break;
	case(1): DEBUG_PRINT(("mute output")); break;
	case(3): DEBUG_PRINT(("reserved\n\r")); break;
	default: break; }
	DEBUG_PRINT(("Noise gate threshold: %d dbFS\n\r", (1.5*(double)(myCodec)->ngth-76.5) ));


	DEBUG_PRINT(("-------------------------\n\r"));
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


/***************************************************************************
* I2C Codec Read
****************************************************************************/
int i2c_codec_read(XIic *Iic, u8 reg, u16 numBytes, u8 *readbuffer)
{
	int Status;

	Status = i2c_writeread(Iic, (reg<<1), numBytes, readbuffer);
	RETURN_ON_FAILURE(Status);

	return XST_SUCCESS;
}
