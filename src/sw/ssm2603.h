#ifndef SSM2603_H_
#define SSM2603_H_

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
#define B_LRINBOTH     0b100000000
#define B_LINMUTE      0b010000000
#define B_LINVOL       0b000111111
#define B_RLINBOTH     0b100000000
#define B_RINMUTE      0b010000000
#define B_RINVOL       0b000111111
#define B_LRHPBOTH     0b100000000
#define B_LHPVOL       0b001111111
#define B_RLHPBOTH     0b100000000
#define B_RHPVOL       0b001111111
#define B_SIDETONE_ATT 0b011000000
#define B_SIDETONE_EN  0b000100000
#define B_DACSEL       0b000010000
#define B_BYPASS       0b000001000
#define B_INSEL        0b000000100
#define B_MUTEMIC      0b000000010
#define B_MICBOOST     0b000000001
#define B_HPOR         0b000010000
#define B_DACMU        0b000001000
#define B_DEEMPH       0b000000110
#define B_ADCHPF       0b000000001
#define B_PWROFF       0b010000000
#define B_CLKOUT       0b001000000
#define B_OSC          0b000100000
#define B_OUT          0b000010000
#define B_DAC          0b000001000
#define B_ADC          0b000000100
#define B_MIC          0b000000010
#define B_LINEIN       0b000000001
#define B_BCLKINV      0b010000000
#define B_MS           0b001000000
#define B_LRSWAP       0b000100000
#define B_LRP          0b000010000
#define B_WL           0b000001100
#define B_FORMAT       0b000000011
#define B_CLKODIV2     0b010000000
#define B_CLKDIV2      0b001000000
#define B_SR           0b000111100
#define B_BOSR         0b000000010
#define B_USB          0b000000001
#define B_ACTIVE       0b000000001
#define B_RESET        0b111111111
#define B_ALCSEL       0b110000000
#define B_MAXGAIN      0b001110000
#define B_ALCL         0b000001111
#define B_DCY          0b011110000
#define B_ATK          0b000001111
#define B_NGTH         0b011111000
#define B_NGG          0b000000110
#define B_NGAT         0b000000001


/***************************************************************************
* Function definitions
****************************************************************************/
int configCodec(XIic *Iic);
int i2c_codec_write(XIic *Iic, u8 reg, u16 data);

#endif /* SSM2603_H_ */
