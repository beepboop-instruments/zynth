#ifndef SSM2603_H_
#define SSM2603_H_

/***************************************************************************
* Include files
****************************************************************************/

#include "i2c.h"
#include "sleep.h"

/***************************************************************************
* Constant definitions
****************************************************************************/
// 7-bit I2C address
#define SSM2603_ADDR 0x1A
// Register map
#define CODEC_R0  0x00
#define CODEC_R1  0x01
#define CODEC_R2  0x02
#define CODEC_R3  0x03
#define CODEC_R4  0x04
#define CODEC_R5  0x05
#define CODEC_R6  0x06
#define CODEC_R7  0x07
#define CODEC_R8  0x08
#define CODEC_R9  0x09
#define CODEC_R15 0x0F
#define CODEC_R16 0x10
#define CODEC_R17 0x11
#define CODEC_R18 0x12
#define CODEC_L_ADC_VOL      CODEC_R0
#define CODEC_R_ADC_VOL      CODEC_R1
#define CODEC_L_DAC_VOL      CODEC_R2
#define CODEC_R_DAC_VOL      CODEC_R3
#define CODEC_AN_AUDIO_PATH  CODEC_R4
#define CODEC_DIG_AUDIO_PATH CODEC_R5
#define CODEC_PWR_MGMT       CODEC_R6
#define CODEC_DIG_AUDIO_IF   CODEC_R7
#define CODEC_SAMPLE_RATE    CODEC_R8
#define CODEC_ACTIVE         CODEC_R9
#define CODEC_SW_RESET       CODEC_R15
#define CODEC_ALC_CTRL1      CODEC_R16
#define CODEC_ALC_CTRL2      CODEC_R17
#define CODEC_NOISE_GATE     CODEC_R18
// bit positions within registers
#define B_LRINBOTH     8
#define B_LINMUTE      7
#define B_LINVOL       0
#define B_RLINBOTH     8
#define B_RINMUTE      7
#define B_RINVOL       0
#define B_LRHPBOTH     8
#define B_LHPVOL       0
#define B_RLHPBOTH     8
#define B_RHPVOL       0
#define B_SIDETONE_ATT 6
#define B_SIDETONE_EN  5
#define B_DACSEL       4
#define B_BYPASS       3
#define B_INSEL        2
#define B_MUTEMIC      1
#define B_MICBOOST     0
#define B_HPOR         4
#define B_DACMU        3
#define B_DEEMPH       1
#define B_ADCHPF       0
#define B_PWROFF       7
#define B_CLKOUT       6
#define B_OSC          5
#define B_OUT          4
#define B_DAC          3
#define B_ADC          2
#define B_MIC          1
#define B_LINEIN       0
#define B_BCLKINV      7
#define B_MS           6
#define B_LRSWAP       5
#define B_LRP          4
#define B_WL           2
#define B_FORMAT       0
#define B_CLKODIV2     7
#define B_CLKDIV2      6
#define B_SR           2
#define B_BOSR         1
#define B_USB          0
#define B_ACTIVE       0
#define B_RESET        0
#define B_ALCSEL       7
#define B_MAXGAIN      4
#define B_ALCL         0
#define B_DCY          4
#define B_ATK          0
#define B_NGTH         3
#define B_NGG          1
#define B_NGAT         0
// bit masks within registers
#define M_LRINBOTH     0b100000000
#define M_LINMUTE      0b010000000
#define M_LINVOL       0b000111111
#define M_RLINBOTH     0b100000000
#define M_RINMUTE      0b010000000
#define M_RINVOL       0b000111111
#define M_LRHPBOTH     0b100000000
#define M_LHPVOL       0b001111111
#define M_RLHPBOTH     0b100000000
#define M_RHPVOL       0b001111111
#define M_SIDETONE_ATT 0b011000000
#define M_SIDETONE_EN  0b000100000
#define M_DACSEL       0b000010000
#define M_BYPASS       0b000001000
#define M_INSEL        0b000000100
#define M_MUTEMIC      0b000000010
#define M_MICBOOST     0b000000001
#define M_HPOR         0b000010000
#define M_DACMU        0b000001000
#define M_DEEMPH       0b000000110
#define M_ADCHPF       0b000000001
#define M_PWROFF       0b010000000
#define M_CLKOUT       0b001000000
#define M_OSC          0b000100000
#define M_OUT          0b000010000
#define M_DAC          0b000001000
#define M_ADC          0b000000100
#define M_MIC          0b000000010
#define M_LINEIN       0b000000001
#define M_BCLKINV      0b010000000
#define M_MS           0b001000000
#define M_LRSWAP       0b000100000
#define M_LRP          0b000010000
#define M_WL           0b000001100
#define M_FORMAT       0b000000011
#define M_CLKODIV2     0b010000000
#define M_CLKDIV2      0b001000000
#define M_SR           0b000111100
#define M_BOSR         0b000000010
#define M_USB          0b000000001
#define M_ACTIVE       0b000000001
#define M_RESET        0b111111111
#define M_ALCSEL       0b110000000
#define M_MAXGAIN      0b001110000
#define M_ALCL         0b000001111
#define M_DCY          0b011110000
#define M_ATK          0b000001111
#define M_NGTH         0b011111000
#define M_NGG          0b000000110
#define M_NGAT         0b000000001
// Power management settings
#define PM_REC_AND_PB     ( ~(M_PWROFF | M_CLKOUT | M_OSC | M_DAC | M_ADC | M_MIC | M_LINEIN) & 0xFF )
#define PM_PB_ONLY_OSC    ( ~(M_PWROFF | M_CLKOUT | M_OSC | M_DAC) & 0xFF )
#define PM_PB_ONLY_EXT    ( ~(M_PWROFF | M_DAC) & 0xFF )
#define PM_REC_LINEIN_OSC ( ~(M_PWROFF | M_CLKOUT | M_OSC | M_ADC | M_LINEIN) & 0xFF )
#define PM_REC_LINEIN_EXT ( ~(M_PWROFF | M_CLKOUT | M_ADC | M_LINEIN) & 0xFF )
#define PM_REC_MICIN_OSC  ( ~(M_PWROFF | M_CLKOUT | M_OSC | M_ADC | B_MIC) & 0xFF )
#define PM_REC_MICIN_EXT  ( ~(M_PWROFF | M_CLKOUT | M_ADC | M_MIC) & 0xFF )
#define PM_MIC_TO_LINEOUT ( ~(M_PWROFF | M_CLKOUT | M_MIC) & 0xFF )
#define PM_ANALOG_BYPASS  ( ~(M_PWROFF | M_CLKOUT | M_LINEIN) & 0xFF )
#define PM_POWER_DOWN     0xFF

/***************************************************************************
* Structure definitions
****************************************************************************/
struct codecSSM2603 {
	// ADC input volume
	u8 lrinboth      = 0;
	u8 rlinboth      = 0;
	u8 linmute       = 0;
	u8 rinmute       = 0;
	u8 linvol        = 0;
	u8 rinvol        = 0;
	// DAC output volume
	u8 lrhpboth      = 0;
	u8 rlhpboth      = 0;
	u8 lhpvol        = 0;
	u8 rhpvol        = 0;
	// Analog audio path
	u8 sidetone_attn = 0;
	u8 sidetone_en   = 0;
	u8 dacsel        = 0;
	u8 bypass        = 0;
	u8 insel         = 0;
	u8 mutemic       = 0;
	u8 micboost      = 0;
	// Digital audio path
	u8 hpor          = 0;
	u8 dacmu         = 0;
	u8 deemph        = 0;
	u8 adchpf        = 0;
	// Power management
	u8 pwroff        = 0;
	u8 clkout        = 0;
	u8 osc           = 0;
	u8 out           = 0;
	u8 dac           = 0;
	u8 adc           = 0;
	u8 mic           = 0;
	u8 linein        = 0;
	// Digital audio I/F
	u8 bclkinv       = 0;
	u8 ms            = 0;
	u8 lrswap        = 0;
	u8 lrp           = 0;
	u8 wl            = 0;
	u8 format        = 0;
	// Sampling rate
	u8 clkodiv2      = 0;
	u8 clkdiv2       = 0;
	u8 sr            = 0;
	u8 bosr          = 0;
	u8 usb           = 0;
	// Active
	u8 active        = 0;
	// ALC control 1
	u8 alcsel        = 0;
	u8 maxgain       = 0;
	u8 alcl          = 0;
	// ALC control 2
	u8 dcy           = 0;
	u8 atk           = 0;
	// Noise gate
	u8 ngth          = 0;
	u8 ngg           = 0;
	u8 ngat          = 0;
};

/***************************************************************************
* Function definitions
****************************************************************************/
int  configCodec(XIic *Iic);
int  get_codec_config(XIic *Iic, codecSSM2603 *myCodec);
void print_codec_config(codecSSM2603 *myCodec);
int  i2c_codec_write(XIic *Iic, u8 reg, u16 data);
int  i2c_codec_read(XIic *Iic, u8 reg, u16 numBytes, u8 *readbuffer);

#endif /* SSM2603_H_ */
