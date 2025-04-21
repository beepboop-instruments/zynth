----------------------------------------------------------------------------------
-- Company: beepboopinstruments
-- Engineer: tyler huddleston
-- 
-- Create Date: 08/14/2022 07:30:11 PM
-- Design Name: zynth
-- Module Name: top
-- Description: 
-- 
-- 
----------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library xil_defaultlib;
  use xil_defaultlib.synth_pkg.all;
  use xil_defaultlib.music_note_pkg.all;

entity top is
  generic (
    -- AXI parameters
    C_S_AXI_DATA_WIDTH  : integer  := 32;
    C_S_AXI_ADDR_WIDTH  : integer  := 31
  );
  port (
    -- ddr
    DDR_addr          : inout STD_LOGIC_VECTOR ( 14 downto 0 );
    DDR_ba            : inout STD_LOGIC_VECTOR ( 2 downto 0 );
    DDR_cas_n         : inout STD_LOGIC;
    DDR_ck_n          : inout STD_LOGIC;
    DDR_ck_p          : inout STD_LOGIC;
    DDR_cke           : inout STD_LOGIC;
    DDR_cs_n          : inout STD_LOGIC;
    DDR_dm            : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    DDR_dq            : inout STD_LOGIC_VECTOR ( 31 downto 0 );
    DDR_dqs_n         : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    DDR_dqs_p         : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    DDR_odt           : inout STD_LOGIC;
    DDR_ras_n         : inout STD_LOGIC;
    DDR_reset_n       : inout STD_LOGIC;
    DDR_we_n          : inout STD_LOGIC;
    FIXED_IO_ddr_vrn  : inout STD_LOGIC;
    FIXED_IO_ddr_vrp  : inout STD_LOGIC;
    FIXED_IO_mio      : inout STD_LOGIC_VECTOR ( 53 downto 0 );
    FIXED_IO_ps_clk   : inout STD_LOGIC;
    FIXED_IO_ps_porb  : inout STD_LOGIC;
    FIXED_IO_ps_srstb : inout STD_LOGIC;
    -- push buttons
    btn_tri_io        : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    -- leds
    led               : out   STD_LOGIC_VECTOR ( 3 downto 0 );
    -- audio codec pins
    ac_scl            : inout STD_LOGIC;
    ac_sda            : inout STD_LOGIC;
    ac_bclk           : out   STD_LOGIC;
    ac_mclk           : out   STD_LOGIC;
    ac_muten          : out   STD_LOGIC;
    ac_pbdat          : out   STD_LOGIC;
    ac_pblrc          : out   STD_LOGIC;
    ac_recdat         : in    STD_LOGIC;
    ac_reclrc         : out   STD_LOGIC
  );
end top;
  
architecture structure of top is

  component ps is
    port (
      DDR_cas_n         : inout STD_LOGIC;
      DDR_cke           : inout STD_LOGIC;
      DDR_ck_n          : inout STD_LOGIC;
      DDR_ck_p          : inout STD_LOGIC;
      DDR_cs_n          : inout STD_LOGIC;
      DDR_reset_n       : inout STD_LOGIC;
      DDR_odt           : inout STD_LOGIC;
      DDR_ras_n         : inout STD_LOGIC;
      DDR_we_n          : inout STD_LOGIC;
      DDR_ba            : inout STD_LOGIC_VECTOR ( 2 downto 0 );
      DDR_addr          : inout STD_LOGIC_VECTOR ( 14 downto 0 );
      DDR_dm            : inout STD_LOGIC_VECTOR ( 3 downto 0 );
      DDR_dq            : inout STD_LOGIC_VECTOR ( 31 downto 0 );
      DDR_dqs_n         : inout STD_LOGIC_VECTOR ( 3 downto 0 );
      DDR_dqs_p         : inout STD_LOGIC_VECTOR ( 3 downto 0 );
      FIXED_IO_mio      : inout STD_LOGIC_VECTOR ( 53 downto 0 );
      FIXED_IO_ddr_vrn  : inout STD_LOGIC;
      FIXED_IO_ddr_vrp  : inout STD_LOGIC;
      FIXED_IO_ps_srstb : inout STD_LOGIC;
      FIXED_IO_ps_clk   : inout STD_LOGIC;
      FIXED_IO_ps_porb  : inout STD_LOGIC;
      leds_4bits_tri_o  : out   STD_LOGIC_VECTOR ( 3 downto 0 );
      btn_tri_i         : in    STD_LOGIC_VECTOR ( 3 downto 0 );
      iic_scl_i         : in    STD_LOGIC;
      iic_scl_o         : out   STD_LOGIC;
      iic_scl_t         : out   STD_LOGIC;
      iic_sda_i         : in    STD_LOGIC;
      iic_sda_o         : out   STD_LOGIC;
      iic_sda_t         : out   STD_LOGIC;
      M03_AXI_awaddr    : out   STD_LOGIC_VECTOR ( 30 downto 0 );
      M03_AXI_awprot    : out   STD_LOGIC_VECTOR ( 2 downto 0 );
      M03_AXI_awvalid   : out   STD_LOGIC;
      M03_AXI_awready   : in    STD_LOGIC;
      M03_AXI_wdata     : out   STD_LOGIC_VECTOR ( 31 downto 0 );
      M03_AXI_wstrb     : out   STD_LOGIC_VECTOR ( 3 downto 0 );
      M03_AXI_wvalid    : out   STD_LOGIC;
      M03_AXI_wready    : in    STD_LOGIC;
      M03_AXI_bresp     : in    STD_LOGIC_VECTOR ( 1 downto 0 );
      M03_AXI_bvalid    : in    STD_LOGIC;
      M03_AXI_bready    : out   STD_LOGIC;
      M03_AXI_araddr    : out   STD_LOGIC_VECTOR ( 30 downto 0 );
      M03_AXI_arprot    : out   STD_LOGIC_VECTOR ( 2 downto 0 );
      M03_AXI_arvalid   : out   STD_LOGIC;
      M03_AXI_arready   : in    STD_LOGIC;
      M03_AXI_rdata     : in    STD_LOGIC_VECTOR ( 31 downto 0 );
      M03_AXI_rresp     : in    STD_LOGIC_VECTOR ( 1 downto 0 );
      M03_AXI_rvalid    : in    STD_LOGIC;
      M03_AXI_rready    : out   STD_LOGIC;
      FCLK_CLK0         : out   STD_LOGIC;
      FCLK_CLK1         : out   std_logic;
      FCLK_RESET0_N     : out   STD_LOGIC;
      FCLK_RESET1_N     : out   std_logic
    );
  end component ps;

  component IOBUF is
    port (
      I  : in    STD_LOGIC;
      O  : out   STD_LOGIC;
      T  : in    STD_LOGIC;
      IO : inout STD_LOGIC
    );
  end component IOBUF;
  
  -- MCLK MMCM
  component clk_wiz_mclk is
    port (
      reset     : in  std_logic;
      clk_in1   : in  std_logic;
      locked    : out std_logic;
      clk_out1  : out std_logic
    );
  end component clk_wiz_mclk;
  
  component synth_engine is
    generic (
      -- synth control parameters
      PHASE_WIDTH     : integer := WIDTH_PH_DATA;
      NOTE_GAIN_WIDTH : integer := WIDTH_NOTE_GAIN;
      SIN_LUT_PH      : natural := 12;
      ADSR_WIDTH      : natural := WIDTH_ADSR_CC;
      ACC_WIDTH       : natural := WIDTH_ADSR_COUNT;
      -- waveform parameters
      DATA_WIDTH      : natural := WIDTH_WAVE_DATA;
      OUT_DATA_WIDTH  : natural := WIDTH_WAVE_DATA+8
    );
    port (
      -- clock and reset
      clk           : in std_logic;
      rst           : in std_logic;
      -- state machine in
      data_latched  : in std_logic;
      -- synth controls
      phase_incs    : in  t_ph_inc_lut;
      note_amps     : in  t_note_amp;
      wfrm_amps     : in  t_wfrm_amp;
      wfrm_phs      : in  t_wfrm_ph;
      pulse_width   : in  unsigned(WIDTH_PULSE_WIDTH-1 downto 0);
      attack_amt    : in  unsigned(ADSR_WIDTH-1 downto 0);
      decay_amt     : in  unsigned(ADSR_WIDTH-1 downto 0);
      sustain_amt   : in  unsigned(ADSR_WIDTH-1 downto 0);
      release_amt   : in  unsigned(ADSR_WIDTH-1 downto 0);
      out_amp       : in  unsigned(WIDTH_OUT_GAIN-1 downto 0);
      out_shift     : in  unsigned(WIDTH_OUT_SHIFT-1 downto 0);
      -- Digital audio output
      audio_out     : out std_logic_vector(OUT_DATA_WIDTH-1 downto 0)
    );
  end component synth_engine;

  component compressor is
    generic (
      SAMPLE_WIDTH : integer := WIDTH_WAVE_DATA;
      ENV_WIDTH    : integer := WIDTH_WAVE_DATA;
      GAIN_WIDTH   : integer := WIDTH_OUT_GAIN
    );
    port(
      -- clock + reset
      clk          : in  std_logic;
      rst          : in  std_logic;
      -- input controls
      attack_amt   : in  integer;
      release_amt  : in  integer;
      threshold    : in  unsigned(WIDTH_WAVE_DATA+7 downto 0);
      knee_width   : in  unsigned(WIDTH_WAVE_DATA+7 downto 0);
      knee_slope   : in  unsigned(WIDTH_WAVE_GAIN-1 downto 0);
      -- audio samples
      sample_in    : in  std_logic_vector(SAMPLE_WIDTH-1 downto 0);
      sample_out   : out std_logic_vector(SAMPLE_WIDTH-1 downto 0)
    );
  end component compressor;

  component synth_axi_ctrl is
    generic (
      -- AXI parameters
      C_S_AXI_DATA_WIDTH  : integer  := 32;
      C_S_AXI_ADDR_WIDTH  : integer  := 31
    );
    port (
      -- user clock domain
      clk                : in  std_logic;
      rst                : in  std_logic;
      -- synth controls out
      note_amps          : out t_note_amp;
      ph_inc_table       : out t_ph_inc_lut;
      wfrm_amps          : out t_wfrm_amp;
      wfrm_phs           : out t_wfrm_ph;
      out_amp            : out unsigned(WIDTH_OUT_GAIN-1 downto 0);
      out_shift          : out unsigned(WIDTH_OUT_SHIFT-1 downto 0);
      pulse_width        : out unsigned(WIDTH_PULSE_WIDTH-1 downto 0);
      adsr_attack_amt    : out unsigned(WIDTH_ADSR_CC-1 downto 0);
      adsr_decay_amt     : out unsigned(WIDTH_ADSR_CC-1 downto 0);
      adsr_sustain_amt   : out unsigned(WIDTH_ADSR_CC-1 downto 0);
      adsr_release_amt   : out unsigned(WIDTH_ADSR_CC-1 downto 0);
      -- compressor controls
      comp_attack_amt    : out integer;
      comp_release_amt   : out integer;
      comp_threshold     : out unsigned(WIDTH_WAVE_DATA+7 downto 0);
      comp_knee_width    : out unsigned(WIDTH_WAVE_DATA+7 downto 0);
      comp_knee_slope    : out unsigned(WIDTH_WAVE_GAIN-1 downto 0);
      -- AXI control interface
      s_axi_awaddr   : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
      s_axi_awprot   : in  std_logic_vector(2 downto 0);
      s_axi_awvalid  : in  std_logic;
      s_axi_awready  : out std_logic;
      s_axi_wdata    : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
      s_axi_wstrb    : in  std_logic_vector(3 downto 0);
      s_axi_wvalid   : in  std_logic;
      s_axi_wready   : out std_logic;
      s_axi_bresp    : out std_logic_vector(1 downto 0);
      s_axi_bvalid   : out std_logic;
      s_axi_bready   : in  std_logic;
      s_axi_araddr   : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
      s_axi_arprot   : in  std_logic_vector(2 downto 0);
      s_axi_arvalid  : in  std_logic;
      s_axi_arready  : out std_logic;
      s_axi_rdata    : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
      s_axi_rresp    : out std_logic_vector(1 downto 0);
      s_axi_rvalid   : out std_logic;
      s_axi_rready   : in  std_logic
    );
  end component synth_axi_ctrl;
    
  -- Audio codec
  component codec_i2s is
    generic (
      G_MCLK_BCLK_RATIO : natural := 2;
      G_DATA_WIDTH      : natural := 24;
      G_WORDSIZE        : natural := 32
    );
    port (
      -- input logic clock domain
      rst         : in  std_logic;                                 -- main logic reset
      clk         : in  std_logic;                                 -- main clock
      dac_data_l  : in  std_logic_vector(G_DATA_WIDTH-1 downto 0); -- left DAC data to codec
      dac_data_r  : in  std_logic_vector(G_DATA_WIDTH-1 downto 0); -- right DAC data to codec
      dac_latched : out std_logic;                                 -- DAC data to codec latched
      adc_data    : out std_logic_vector(G_DATA_WIDTH*2-1 downto 0); -- ADC data from codec
      adc_latched : out std_logic;                                 -- ADC data from codec latched
      -- mclk domain
      mclk_in     : in std_logic;                                  -- codec master clock from fabric
      mclk        : out std_logic;                                 -- codec master clock out
      bclk        : out std_logic;                                 -- codec bit clock
      pbdat       : out std_logic;                                 -- codec playback data
      pblrc       : out std_logic;                                 -- codec playback data left/right select
      recdat      : in  std_logic;                                 -- codec record data
      reclrc      : out std_logic;                                 -- codec record data left/right select
      mute_n      : out std_logic                                  -- codec mute enable
    );
  end component codec_i2s;
  
  -- Clocks and resets
  signal clk25   : std_logic;
  signal rst25   : std_logic;
  signal rst25_n : std_logic;

  signal clk100   : std_logic;
  signal rst100   : std_logic;
  signal rst100_n : std_logic;
  
  signal clk12p288   : std_logic;

  -- synth controls
  signal phase_incs   : t_ph_inc_lut;
  signal note_amps    : t_note_amp;
  signal wfrm_amps    : t_wfrm_amp;
  signal wfrm_phs     : t_wfrm_ph;
  signal pulse_width  : unsigned(WIDTH_PULSE_WIDTH-1 downto 0);
  signal adsr_attack  : unsigned(WIDTH_ADSR_CC-1 downto 0);
  signal adsr_decay   : unsigned(WIDTH_ADSR_CC-1 downto 0);
  signal adsr_sustain : unsigned(WIDTH_ADSR_CC-1 downto 0);
  signal adsr_release : unsigned(WIDTH_ADSR_CC-1 downto 0);
  signal out_amp      : unsigned(WIDTH_OUT_GAIN-1 downto 0);
  signal out_shift    : unsigned(WIDTH_OUT_SHIFT-1 downto 0);

  -- codec
  signal dac_latched : std_logic;

  -- compressor controls  
  signal comp_attack      : integer;
  signal comp_release     : integer;
  signal comp_threshold   : unsigned(WIDTH_OUT_DATA-1 downto 0);
  signal comp_knee_width  : unsigned(WIDTH_OUT_DATA-1 downto 0);
  signal comp_knee_slope  : unsigned(WIDTH_WAVE_GAIN-1 downto 0);
  
  -- audio data
  signal audio_data  : std_logic_vector(WIDTH_WAVE_DATA+7 downto 0);
  signal audio_data_compressed  : std_logic_vector(WIDTH_WAVE_DATA+7 downto 0);
  
  -- I2C
  signal btn_tri_i_0 : STD_LOGIC_VECTOR ( 0 to 0 );
  signal btn_tri_i_1 : STD_LOGIC_VECTOR ( 1 to 1 );
  signal btn_tri_i_2 : STD_LOGIC_VECTOR ( 2 to 2 );
  signal btn_tri_i_3 : STD_LOGIC_VECTOR ( 3 to 3 );
  signal iic_scl_i   : STD_LOGIC;
  signal iic_scl_o   : STD_LOGIC;
  signal iic_scl_t   : STD_LOGIC;
  signal iic_sda_i   : STD_LOGIC;
  signal iic_sda_o   : STD_LOGIC;
  signal iic_sda_t   : STD_LOGIC;

  -- AXI
  signal awaddr   : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
  signal awprot   : std_logic_vector(2 downto 0);
  signal awvalid  : std_logic;
  signal awready  : std_logic;
  signal wdata    : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal wstrb    : std_logic_vector(3 downto 0);
  signal wvalid   : std_logic;
  signal wready   : std_logic;
  signal bresp    : std_logic_vector(1 downto 0);
  signal bvalid   : std_logic;
  signal bready   : std_logic;
  signal araddr   : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
  signal arprot   : std_logic_vector(2 downto 0);
  signal arvalid  : std_logic;
  signal arready  : std_logic;
  signal rdata    : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal rresp    : std_logic_vector(1 downto 0);
  signal rvalid   : std_logic;
  signal rready   : std_logic;
    
begin
  
  -- reset polarity inversion
  rst100      <= not(rst100_n);
  rst25       <= not(rst25_n);
  
  ps_i: component ps
    port map (
      DDR_addr(14 downto 0)        => DDR_addr(14 downto 0),
      DDR_ba(2 downto 0)           => DDR_ba(2 downto 0),
      DDR_cas_n                    => DDR_cas_n,
      DDR_ck_n                     => DDR_ck_n,
      DDR_ck_p                     => DDR_ck_p,
      DDR_cke                      => DDR_cke,
      DDR_cs_n                     => DDR_cs_n,
      DDR_dm(3 downto 0)           => DDR_dm(3 downto 0),
      DDR_dq(31 downto 0)          => DDR_dq(31 downto 0),
      DDR_dqs_n(3 downto 0)        => DDR_dqs_n(3 downto 0),
      DDR_dqs_p(3 downto 0)        => DDR_dqs_p(3 downto 0),
      DDR_odt                      => DDR_odt,
      DDR_ras_n                    => DDR_ras_n,
      DDR_reset_n                  => DDR_reset_n,
      DDR_we_n                     => DDR_we_n,
      FCLK_CLK0                    => clk25,
      FCLK_CLK1                    => clk100,
      FCLK_RESET0_N                => rst25_n,
      FCLK_RESET1_N                => rst100_n,
      FIXED_IO_ddr_vrn             => FIXED_IO_ddr_vrn,
      FIXED_IO_ddr_vrp             => FIXED_IO_ddr_vrp,
      FIXED_IO_mio(53 downto 0)    => FIXED_IO_mio(53 downto 0),
      FIXED_IO_ps_clk              => FIXED_IO_ps_clk,
      FIXED_IO_ps_porb             => FIXED_IO_ps_porb,
      FIXED_IO_ps_srstb            => FIXED_IO_ps_srstb,
      btn_tri_i(3)                 => btn_tri_i_3(3),
      btn_tri_i(2)                 => btn_tri_i_2(2),
      btn_tri_i(1)                 => btn_tri_i_1(1),
      btn_tri_i(0)                 => btn_tri_i_0(0),
      iic_scl_i                    => iic_scl_i,
      iic_scl_o                    => iic_scl_o,
      iic_scl_t                    => iic_scl_t,
      iic_sda_i                    => iic_sda_i,
      iic_sda_o                    => iic_sda_o,
      iic_sda_t                    => iic_sda_t,
      leds_4bits_tri_o(3 downto 0) => led(3 downto 0),
      M03_AXI_awaddr               => awaddr,
      M03_AXI_awprot               => awprot,
      M03_AXI_awvalid              => awvalid,
      M03_AXI_awready              => awready,
      M03_AXI_wdata                => wdata,
      M03_AXI_wstrb                => wstrb,
      M03_AXI_wvalid               => wvalid,
      M03_AXI_wready               => wready,
      M03_AXI_bresp                => bresp,
      M03_AXI_bvalid               => bvalid,
      M03_AXI_bready               => bready,
      M03_AXI_araddr               => araddr,
      M03_AXI_arprot               => arprot,
      M03_AXI_arvalid              => arvalid,
      M03_AXI_arready              => arready,
      M03_AXI_rdata                => rdata,
      M03_AXI_rresp                => rresp,
      M03_AXI_rvalid               => rvalid,
      M03_AXI_rready               => rready
    );
  
    u_synth_axi_ctrl: synth_axi_ctrl
    generic map (
      -- Width of S_AXI data bus
      C_S_AXI_DATA_WIDTH => C_S_AXI_DATA_WIDTH,
      -- Width of S_AXI address bus
      C_S_AXI_ADDR_WIDTH => C_S_AXI_ADDR_WIDTH
    )
    port map (
      -- user clock domain
      clk              => clk25,
      rst              => rst25,
      -- synth controls out
      note_amps        => note_amps,
      ph_inc_table     => phase_incs,
      wfrm_amps        => wfrm_amps,
      wfrm_phs         => wfrm_phs,
      out_amp          => out_amp,
      out_shift        => out_shift,
      pulse_width      => pulse_width,
      adsr_attack_amt  => adsr_attack,
      adsr_decay_amt   => adsr_decay,
      adsr_sustain_amt => adsr_sustain,
      adsr_release_amt => adsr_release,
      -- compressor controls
      comp_attack_amt  => comp_attack,
      comp_release_amt => comp_release,
      comp_threshold   => comp_threshold,
      comp_knee_width  => comp_knee_width,
      comp_knee_slope  => comp_knee_slope,
      -- AXI control interface
      s_axi_awaddr     => awaddr,
      s_axi_awprot     => awprot,
      s_axi_awvalid    => awvalid,
      s_axi_awready    => awready,
      s_axi_wdata      => wdata,
      s_axi_wstrb      => wstrb,
      s_axi_wvalid     => wvalid,
      s_axi_wready     => wready,
      s_axi_bresp      => bresp,
      s_axi_bvalid     => bvalid,
      s_axi_bready     => bready,
      s_axi_araddr     => araddr,
      s_axi_arprot     => arprot,
      s_axi_arvalid    => arvalid,
      s_axi_arready    => arready,
      s_axi_rdata      => rdata,
      s_axi_rresp      => rresp,
      s_axi_rvalid     => rvalid,
      s_axi_rready     => rready
    );

  iic_scl_iobuf: component IOBUF
    port map (
      I  => iic_scl_o,
      IO => ac_scl,
      O  => iic_scl_i,
      T  => iic_scl_t
    );

  iic_sda_iobuf: component IOBUF
    port map (
      I  => iic_sda_o,
      IO => ac_sda,
      O  => iic_sda_i,
      T  => iic_sda_t
    );
    
  -- synth engine
  u_synth_engine: synth_engine
    generic map (
      -- synth control parameters
      PHASE_WIDTH     => WIDTH_PH_DATA,
      NOTE_GAIN_WIDTH => WIDTH_NOTE_GAIN,
      SIN_LUT_PH      => 12,
      ADSR_WIDTH      => WIDTH_ADSR_CC,
      ACC_WIDTH       => WIDTH_ADSR_COUNT,
      -- waveform parameters
      DATA_WIDTH      => WIDTH_WAVE_DATA,
      OUT_DATA_WIDTH  => WIDTH_OUT_DATA
    )
    port map (
      -- AXI control interface
      clk           => clk25,
      rst           => rst25,
      -- state machine in
      data_latched  => dac_latched,
      -- synth controls in
      note_amps     => note_amps,
      phase_incs    => phase_incs,
      wfrm_amps     => wfrm_amps,
      wfrm_phs      => wfrm_phs,
      out_amp       => out_amp,
      out_shift     => out_shift,
      pulse_width   => pulse_width,
      attack_amt    => adsr_attack,
      decay_amt     => adsr_decay,
      sustain_amt   => adsr_sustain,
      release_amt   => adsr_release,
      -- Digital audio output
      audio_out     => audio_data
    );
    
    -- compressor
    u_compressor: compressor
    generic map (
      SAMPLE_WIDTH => WIDTH_OUT_DATA,
      ENV_WIDTH    => WIDTH_OUT_DATA,
      GAIN_WIDTH   => WIDTH_NOTE_GAIN
    )
    port map (
      -- clock + reset
      clk          => clk25,
      rst          => rst25,
      -- input controls
      attack_amt   => comp_attack,
      release_amt  => comp_release,
      threshold    => comp_threshold,
      knee_width   => comp_knee_width,
      knee_slope   => comp_knee_slope,
      -- audio samples
      sample_in    => audio_data,
      sample_out   => audio_data_compressed
    );
    
  -- Audio codec
  u_audio_codec: codec_i2s
    generic map (
      G_MCLK_BCLK_RATIO => 2,
      G_DATA_WIDTH      => WIDTH_OUT_DATA,
      G_WORDSIZE        => 32
    )
    port map (
      -- input clock domain
      clk         => clk25,
      rst         => rst25,
      dac_data_l  => audio_data_compressed,
      dac_data_r  => audio_data_compressed,
      dac_latched => dac_latched,
      adc_data    => open,
      adc_latched => open,
      -- mclk domain
      mclk_in     => clk12p288,
      mclk        => ac_mclk,
      bclk        => ac_bclk,
      pbdat       => ac_pbdat,
      pblrc       => ac_pblrc,
      recdat      => ac_recdat,
      reclrc      => ac_reclrc,
      mute_n      => ac_muten
    );
        
  -- MCLK MMCM
  u_mclk_mmcm: clk_wiz_mclk
    port map (
      reset        => rst100,
      clk_in1      => clk100,
      locked       => open,
      clk_out1     => clk12p288
    );

end STRUCTURE;
