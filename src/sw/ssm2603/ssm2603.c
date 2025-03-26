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
#include <xil_types.h>
#include <xstatus.h>

codecSSM2603_t codecSSM2603;


/***************************************************************************
* Codec write
****************************************************************************/

int codec_write(AddressType reg, u16 data)
{
  u8 write_buf[2] = {
    (reg << 1) + ((data >> 8) & 1),
    data & 0xFF
  };

  if (i2c_write_reg(SSM2603_I2C_ADDR, &write_buf[0], 1, &write_buf[1], 1) != 2) {
      return XST_FAILURE;
  }

  return XST_SUCCESS;
}

/***************************************************************************
* Codec read
****************************************************************************/

int codec_read(AddressType reg, u16 *data)
{
  u8 read_buf[2] = {0,0};
  u8 read_reg = reg << 1;

  if (i2c_read_reg(SSM2603_I2C_ADDR, &read_reg, 1, read_buf, 2) != 2) {
    return XST_FAILURE;
  }

  *data = ((u16)read_buf[1] << 8) | read_buf[0];

return XST_SUCCESS;  
}

/***************************************************************************
* Configure Codec
****************************************************************************/
int configCodec()
{
 /* 1. Enable all of the necessary power management bits of
  *    Register R6 with the exception of the out bit (Bit D4). The
  *    out bit should not be set to 1 until the final step of the
  *    control register sequence.
  */
  if (codec_write(CODEC_PWR_MGMT, PM_PB_ONLY_EXT)) {
    return XST_FAILURE;
  }

 /* 2. After the power management bits are set, program all other
  *    necessary registers with the exception of the active bit
  *    [Register R9, Bit D0] and the out bit of the power manage-
  *    ment register.
  */
  // enable dac at output mixer
  if (codec_write(CODEC_AN_AUDIO_PATH, M_DACSEL | M_MUTEMIC)) {
    return XST_FAILURE;
  }

  // set clock condition for MCLK=12.288 MHz and 96 kHz sample rate
  if (codec_write(CODEC_SAMPLE_RATE, 0x7 << B_SR)) {
    return XST_FAILURE;
  }

  // unmute the DAC output
  if (codec_write(CODEC_DIG_AUDIO_PATH, 0)) {
    return XST_FAILURE;
  }

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
  if (codec_write(CODEC_ACTIVE, M_ACTIVE)) {
    return XST_FAILURE;
  }

 /* 4. Finally, to enable the DAC output path of the SSM2603, set
  *    the out bit of Register R6 to 0.
  */
  if (codec_write(CODEC_PWR_MGMT, PM_PB_ONLY_EXT & (~M_OUT))) {
    return XST_FAILURE;
  }

  if (get_codec_config()) {
      return XST_FAILURE;
  }
#ifdef DEBUG
  print_codec_config();
#endif

  return XST_SUCCESS;
}

/***************************************************************************
* Read configuration registers from codec
****************************************************************************/
int get_codec_config()
{
  u16 rd_data;

  // read left ADC input volume
  if (codec_read(CODEC_L_ADC_VOL, &rd_data)) {
    return XST_FAILURE;
  }
  codecSSM2603.lrinboth = GET_BIT(rd_data, B_LRINBOTH);
  codecSSM2603.linmute  = GET_BIT(rd_data, B_LINMUTE);
  codecSSM2603.linvol   = GET_BITS(rd_data, B_LINVOL, B_LINVOL+W_INVOL-1);

  // read right ADC input volume
  if (codec_read(CODEC_R_ADC_VOL, &rd_data)) {
      return XST_FAILURE;
  }
  codecSSM2603.rlinboth = GET_BIT(rd_data, B_RLINBOTH);
  codecSSM2603.rinmute  = GET_BIT(rd_data, B_RINMUTE);
  codecSSM2603.rinvol   = GET_BITS(rd_data, B_RINVOL, B_RINVOL+W_INVOL-1);

  // read left DAC output volume
  if (codec_read(CODEC_L_DAC_VOL, &rd_data)) {
      return XST_FAILURE;
  }
  codecSSM2603.lrhpboth = GET_BIT(rd_data, B_LRHPBOTH);
  codecSSM2603.lhpvol   = GET_BITS(rd_data, B_LHPVOL, B_LHPVOL+W_HPVOL-1);

  // read right DAC output volume
  if (codec_read(CODEC_R_DAC_VOL, &rd_data)) {
      return XST_FAILURE;
  }
  codecSSM2603.rlhpboth = GET_BIT(rd_data, B_RLHPBOTH);
  codecSSM2603.rhpvol   = GET_BITS(rd_data, B_RHPVOL, B_RHPVOL+W_HPVOL-1);

  // read analog audio path
  if (codec_read(CODEC_AN_AUDIO_PATH, &rd_data)) {
      return XST_FAILURE;
  }
  codecSSM2603.sidetone_attn = GET_BITS(rd_data, B_SIDETONE_ATT, B_SIDETONE_ATT+W_SIDETONE_ATT-1);
  codecSSM2603.sidetone_en   = GET_BIT(rd_data, B_SIDETONE_EN);
  codecSSM2603.dacsel        = GET_BIT(rd_data, B_DACSEL);
  codecSSM2603.bypass        = GET_BIT(rd_data, B_BYPASS);
  codecSSM2603.insel         = GET_BIT(rd_data, B_INSEL);
  codecSSM2603.mutemic       = GET_BIT(rd_data, B_MUTEMIC);
  codecSSM2603.micboost      = GET_BIT(rd_data, B_MICBOOST);

  // read digital audio path
  if (codec_read(CODEC_DIG_AUDIO_PATH, &rd_data)) {
      return XST_FAILURE;
  }
  codecSSM2603.hpor   = GET_BIT(rd_data, B_HPOR);
  codecSSM2603.dacmu  = GET_BIT(rd_data, B_DACMU);
  codecSSM2603.deemph = GET_BITS(rd_data, B_DEEMPH, B_DEEMPH+W_DEEMPH-1);
  codecSSM2603.adchpf = GET_BIT(rd_data, B_ADCHPF);

  // power management
  if (codec_read(CODEC_PWR_MGMT, &rd_data)) {
      return XST_FAILURE;
  }
  codecSSM2603.pwroff = GET_BIT(rd_data, B_PWROFF);
  codecSSM2603.clkout = GET_BIT(rd_data, B_CLKOUT);
  codecSSM2603.osc    = GET_BIT(rd_data, B_OSC);
  codecSSM2603.out    = GET_BIT(rd_data, B_OUT);
  codecSSM2603.dac    = GET_BIT(rd_data, B_DAC);
  codecSSM2603.adc    = GET_BIT(rd_data, B_ADC);
  codecSSM2603.mic    = GET_BIT(rd_data, B_MIC);
  codecSSM2603.linein = GET_BIT(rd_data, B_LINEIN);

  // digital audio i/f
  if (codec_read(CODEC_DIG_AUDIO_IF, &rd_data)) {
      return XST_FAILURE;
  }
  codecSSM2603.bclkinv = GET_BIT(rd_data, B_BCLKINV);
  codecSSM2603.ms      = GET_BIT(rd_data, B_MS);
  codecSSM2603.lrswap  = GET_BIT(rd_data, B_LRSWAP);
  codecSSM2603.lrp     = GET_BIT(rd_data, B_LRP);
  codecSSM2603.wl      = GET_BITS(rd_data, B_WL, B_WL+W_WL-1);
  codecSSM2603.format  = GET_BITS(rd_data, B_FORMAT, B_FORMAT+W_FORMAT-1);

  // sampling rate
  if (codec_read(CODEC_SAMPLE_RATE, &rd_data)) {
      return XST_FAILURE;
  }
  codecSSM2603.clkodiv2 = GET_BIT(rd_data, B_CLKODIV2);
  codecSSM2603.clkdiv2  = GET_BIT(rd_data, B_CLKDIV2);
  codecSSM2603.sr       = GET_BITS(rd_data, B_SR, B_SR+W_SR-1);
  codecSSM2603.bosr     = GET_BIT(rd_data, B_BOSR);
  codecSSM2603.usb      = GET_BIT(rd_data, B_USB);

  // active
  if (codec_read(CODEC_ACTIVE, &rd_data)) {
      return XST_FAILURE;
  }
  codecSSM2603.active = GET_BIT(rd_data, B_ACTIVE);

  // ALC control 1
  if (codec_read(CODEC_ALC_CTRL1, &rd_data)) {
      return XST_FAILURE;
  }
  codecSSM2603.alcsel  = GET_BITS(rd_data, B_ALCSEL, B_ALCSEL+W_ALSEL-1);
  codecSSM2603.maxgain = GET_BITS(rd_data, B_MAXGAIN, B_MAXGAIN+W_MAXGAIN-1);
  codecSSM2603.alcl    = GET_BITS(rd_data, B_ALCL, B_ALCL+W_ALCL-1);

  // ALC control 2
  if (codec_read(CODEC_ALC_CTRL2, &rd_data)) {
      return XST_FAILURE;
  }
  codecSSM2603.dcy = GET_BITS(rd_data, B_DCY, B_DCY+W_DCY-1);
  codecSSM2603.atk = GET_BITS(rd_data, B_ATK, B_ATK+W_ATK-1);

  // noise gate
  if (codec_read(CODEC_NOISE_GATE, &rd_data)) {
      return XST_FAILURE;
  }
  codecSSM2603.ngth = GET_BITS(rd_data, B_NGTH, B_NGTH+W_NGTH-1);
  codecSSM2603.ngg  = GET_BITS(rd_data, B_NGG, B_NGG+W_NGG-1);
  codecSSM2603.ngat = GET_BIT(rd_data, B_NGAT);

  return XST_SUCCESS;
}

/***************************************************************************
* Print codec settings over serial debug
****************************************************************************/
void print_codec_config()
{
  float temp = 0;
  int int_part, frac_part;

  // print a header
  debug_print("-----------------------------------------------------\r\n");
  debug_print("Audio Codec Configuration\r\n");
  debug_print("-----------------------------------------------------\r\n");

  // Active
  debug_print("Active: %s\r\n", codecSSM2603.active == 1 ? "yes" : "no");

  // Power management
  debug_print("Power - whole chip: %s\r\n", codecSSM2603.pwroff == 1 ? "off" : "on");
  debug_print("Power - clock out: %s\r\n", codecSSM2603.clkout == 1 ? "off" : "on");
  debug_print("Power - crystal: %s\r\n", codecSSM2603.osc == 1 ? "off" : "on");
  debug_print("Power - output: %s\r\n", codecSSM2603.out == 1 ? "off" : "on");
  debug_print("Power - DAC: %s\r\n", codecSSM2603.dac == 1 ? "off" : "on");
  debug_print("Power - ADC: %s\r\n", codecSSM2603.adc == 1 ? "off" : "on");
  debug_print("Power - mic input: %s\r\n", codecSSM2603.mic == 1 ? "off" : "on");
  debug_print("Power - line input: %s\r\n", codecSSM2603.linein == 1 ? "off" : "on");

  // Digital Audio I/F
  debug_print("Format: ");
  switch(codecSSM2603.format) {
    case(0): debug_print("right justified\r\n"); break;
    case(1): debug_print("left justified\r\n"); break;
    case(2): debug_print("I2S mode\r\n"); break;
    case(3): debug_print("DSP mode\r\n"); break;
    default: break;
  }
  debug_print("Data word length: ");
  switch(codecSSM2603.wl) {
    case(0): debug_print("16 bits\r\n"); break;
    case(1): debug_print("20 bits\r\n"); break;
    case(2): debug_print("24 bits\r\n"); break;
    case(3): debug_print("32 bits\r\n"); break;
    default: break;
  }
  debug_print("Master mode: %s\r\n", codecSSM2603.ms == 1 ? "enabled" : "disabled (secondary mode)");
  debug_print("BCLK inversion: %s\r\n", codecSSM2603.bclkinv == 1 ? "inverted" : "not inverted");
  debug_print("Left and right output swap: %s\r\n", codecSSM2603.lrswap == 1 ? "enabled" : "disabled");
  debug_print("Polarity control: %s\r\n", codecSSM2603.lrp == 1
    ? "invert PBLRC & RECLRC polarity, or DSP submodule 2"
    : "normal PBLRC & RECLRC, or DSP submodule 1");

  // Analog audio path
  debug_print("Mic mixed to output: %s\r\n", codecSSM2603.sidetone_en == 1 ? "enabled" : "disabled");
  debug_print("Mic attenuation: -%d dB\r\n", (6 + 3*codecSSM2603.sidetone_attn) );
  debug_print("DAC mixed to output: %s\r\n", codecSSM2603.dacsel == 1 ? "enabled" : "disabled");
  debug_print("Line in mixed to output: %s\r\n", codecSSM2603.bypass == 1 ? "enabled" : "disabled");
  debug_print("Input select: %s\r\n", codecSSM2603.insel == 1 ? "microphone" : "line in");
  debug_print("Mic mute: %s\r\n", codecSSM2603.mutemic == 1 ? "enabled" : "disabled");
  debug_print("Mic boost: %s\r\n", codecSSM2603.micboost == 1 ? "20 dB" : "0 dB");

  // Digital audio path
  debug_print("Store DC offset: %s\r\n", codecSSM2603.hpor == 1 ? "enabled" : "disabled");
  debug_print("DAC mute: %s\r\n", codecSSM2603.dacmu == 1 ? "enabled" : "disabled");
  debug_print("De-emphasis control: ");
  switch(codecSSM2603.deemph) {
    case(0): debug_print("none\r\n"); break;
    case(1): debug_print("32 kHz sampling rate\r\n"); break;
    case(2): debug_print("44.1 kHz sampling rate\r\n"); break;
    case(3): debug_print("48 kHz sampling rate\r\n"); break;
    default: break;
  }
  debug_print("ADC HPF: %s\r\n", codecSSM2603.adchpf == 1 ? "disabled" : "enabled");

  // ADC volume
  debug_print("ADC left to right: %s\r\n", codecSSM2603.lrinboth == 1 ? "enabled" : "disabled");
  debug_print("ADC right to left: %s\r\n", codecSSM2603.rlinboth == 1 ? "enabled" : "disabled");
  debug_print("ADC Left in mute: %s\r\n", codecSSM2603.linmute == 1 ? "enabled" : "disabled");
  debug_print("ADC right in mute: %s\r\n", codecSSM2603.rinmute == 1 ? "enabled" : "disabled");
  debug_print("ADC left in volume: %d%%\r\n",  (codecSSM2603.linvol*100/63) );
  debug_print("ADC right in volume: %d%%\r\n", (codecSSM2603.rinvol*100/63) );

  // DAC volume
  debug_print("DAC HP left to right: %s\r\n", codecSSM2603.lrhpboth == 1 ? "enabled" : "disabled");
  debug_print("DAC HP right to left: %s\r\n", codecSSM2603.rlhpboth == 1 ? "enabled" : "disabled");
  debug_print("DAC left out volume: %d%%\r\n", (codecSSM2603.lhpvol*100/127) );
  debug_print("DAC right out volume: %d%%\r\n", (codecSSM2603.rhpvol*100/127) );

  // Sampling rate
  debug_print("CLKOUT select: %s\r\n", codecSSM2603.clkodiv2 == 1
    ? "core clock divided by 2"
    : "core clock");
  debug_print("Core clock select: %s\r\n", codecSSM2603.clkdiv2 == 1
    ? "MCLK divided by 2"
    : "MCLK");
  debug_print("Sample rate setting: 0x%X\r\n", codecSSM2603.sr);
  debug_print("USB mode select: %s\r\n", codecSSM2603.usb == 1 ? "enabled" : "disabled");
  debug_print("Base oversampling rate: ");
  if (codecSSM2603.bosr == 1 && codecSSM2603.usb == 1)  { debug_print("272 fs\r\n");  }
  if (codecSSM2603.bosr == 0 && codecSSM2603.usb == 1)  { debug_print("250 fs\r\n");  }
  if (codecSSM2603.bosr == 1 && codecSSM2603.usb == 0)  { debug_print("256 fs\r\n");  }
  if (codecSSM2603.bosr == 0 && codecSSM2603.usb == 0)  { debug_print("384 fs\r\n");  }

  // ALC control
  debug_print("ALC select: ");
  switch(codecSSM2603.alcsel) {
    case(0): debug_print("disabled\r\n"); break;
    case(1): debug_print("enabled (right only)\r\n"); break;
    case(2): debug_print("enabled (left only)\r\n"); break;
    case(3): debug_print("enabled (both)\r\n"); break;
    default: break;
  }
  temp = codecSSM2603.maxgain;
  FLOAT_TO_INT_FRAC((6*temp-12), int_part, frac_part, 1);
  debug_print("ALC max gain: %d.%01d dB\r\n", int_part, frac_part);
  temp = codecSSM2603.alcl;
  FLOAT_TO_INT_FRAC((1.5*temp-28.5), int_part, frac_part, 1);
  debug_print("ALC target level: %d.%01d dBFS\r\n", int_part, frac_part);
  debug_print("ALC decay: %d ms\r\n", (24 << codecSSM2603.dcy) );
  debug_print("ALC attack: %d ms\r\n", (6 << codecSSM2603.atk) );

  // Noise gate
  debug_print("Noise gate: %s\r\n", codecSSM2603.ngat == 1 ? "enabled" : "disabled");
  debug_print("Noise gate type: ");
  switch(codecSSM2603.ngg) {
    case(0):
    case(2): debug_print("hold PGA gain constant\r\n"); break;
    case(1): debug_print("mute output"); break;
    case(3): debug_print("reserved\r\n"); break;
    default: break;
  }
  temp = codecSSM2603.ngth;
  FLOAT_TO_INT_FRAC((1.5*temp-76.5), int_part, frac_part, 1);
  debug_print("Noise gate threshold: %d.%01d dBFS\r\n", int_part, frac_part);

  debug_print("-----------------------------------------------------\r\n");
}
