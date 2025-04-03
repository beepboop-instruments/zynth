----------------------------------------------------------------------------------
-- Company: beepboop
-- Engineer: Tyler Huddleston
-- 
-- Create Date: 03/08/2025
-- Design Name: Synthesizer Engine
-- Module Name: Synthesizer Engine
-- Description: 
--   Provides an AXI-4 LITE interface to set controls to the synthesizer engine
--   and synthesized audio out.
-- 
----------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library xil_defaultlib;
  use xil_defaultlib.synth_pkg.all;
  use xil_defaultlib.music_note_pkg.all;

entity synth_engine is
  generic (
    -- AXI parameters
    C_S_AXI_DATA_WIDTH  : integer  := 32;
    C_S_AXI_ADDR_WIDTH  : integer  := 31;
    -- waveform parameters
    DATA_WIDTH     : natural := WIDTH_WAVE_DATA;
    OUT_DATA_WIDTH : natural := WIDTH_WAVE_DATA+8
  );
  port (
    -- clock and reset
    clk           : in std_logic;
    rst           : in std_logic;

    -- AXI control interface
    s_axi_awaddr  : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    s_axi_awprot  : in  std_logic_vector(2 downto 0);
    s_axi_awvalid : in  std_logic;
    s_axi_awready : out std_logic;
    s_axi_wdata   : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    s_axi_wstrb   : in  std_logic_vector(3 downto 0);
    s_axi_wvalid  : in  std_logic;
    s_axi_wready  : out std_logic;
    s_axi_bresp   : out std_logic_vector(1 downto 0);
    s_axi_bvalid  : out std_logic;
    s_axi_bready  : in  std_logic;
    s_axi_araddr  : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    s_axi_arprot  : in  std_logic_vector(2 downto 0);
    s_axi_arvalid : in  std_logic;
    s_axi_arready : out std_logic;
    s_axi_rdata   : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    s_axi_rresp   : out std_logic_vector(1 downto 0);
    s_axi_rvalid  : out std_logic;
    s_axi_rready  : in  std_logic;

    -- Digital audio output
    audio_out     : out std_logic_vector(OUT_DATA_WIDTH-1 downto 0)
  );
  end synth_engine;
  
architecture struct_synth_engine of synth_engine is

  component synth_axi_ctrl is
    generic (
      -- AXI parameters
      C_S_AXI_DATA_WIDTH  : integer  := 32;
      C_S_AXI_ADDR_WIDTH  : integer  := 31
    );
    port (
      -- synth controls out
      note_amps    : out t_note_amp;
      ph_inc_table : out t_ph_inc_lut;
      wfrm_amps    : out t_wfrm_amp;
      wfrm_phs     : out t_wfrm_ph;
      out_amp      : out unsigned(WIDTH_OUT_GAIN-1 downto 0);
      out_shift    : out unsigned(WIDTH_OUT_SHIFT-1 downto 0);
      pulse_width  : out unsigned(WIDTH_PULSE_WIDTH-1 downto 0);

      -- AXI control interface
      s_axi_aclk     : in  std_logic;
      s_axi_aresetn  : in  std_logic;
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

  component phase_accumulator is
    generic (
      PHASE_WIDTH     : integer := WIDTH_PH_DATA;
      NOTE_GAIN_WIDTH : integer := WIDTH_NOTE_GAIN
    );
    port (
      clk             : in  std_logic;
      rst             : in  std_logic;
      -- synth controls
      phase_incs      : in  t_ph_inc_lut;
      note_amps       : in  t_note_amp;
      -- pipeline out
      note_index_out  : out integer range I_LOWEST_NOTE to I_HIGHEST_NOTE;
      phase_out       : out unsigned(PHASE_WIDTH-1 downto 0);
      note_amp_out    : out unsigned(NOTE_GAIN_WIDTH-1 downto 0);
      cycle_start_out : out std_logic
    );
  end component;

  component phase_to_wave is
    generic (
      PHASE_WIDTH     : integer := WIDTH_PH_DATA;
      NOTE_GAIN_WIDTH : integer := WIDTH_NOTE_GAIN;
      DATA_WIDTH      : natural := WIDTH_WAVE_DATA;
      SIN_LUT_PH      : natural := 12
    );
    port (
      clk             : in  std_logic;
      rst             : in  std_logic;
      -- synth controls
      wfrm_amps       : in  t_wfrm_amp;
      wfrm_phs        : in  t_wfrm_ph;
      pulse_width     : in  unsigned(WIDTH_PULSE_WIDTH-1 downto 0);
      -- pipeline in
      note_index_in   : in  integer range I_LOWEST_NOTE to I_HIGHEST_NOTE;
      phase_in        : in  unsigned(PHASE_WIDTH-1 downto 0);
      note_amp_in     : in  unsigned(NOTE_GAIN_WIDTH-1 downto 0);
      cycle_start_in  : in  std_logic;
      -- pipeline out
      note_index_out  : out integer range I_LOWEST_NOTE to I_HIGHEST_NOTE;
      note_out        : out signed(DATA_WIDTH-1 downto 0);
      note_amp_out    : out unsigned(NOTE_GAIN_WIDTH-1 downto 0);
      cycle_start_out : out std_logic
    );
  end component;

  component envelope_scale is
    generic (
      NOTE_GAIN_WIDTH : integer := WIDTH_NOTE_GAIN;
      DATA_WIDTH      : natural := WIDTH_WAVE_DATA
    );
    port (
      clk             : in  std_logic;
      rst             : in  std_logic;
      -- synth controls
      -- adsr_settings
      -- pipeline in
      note_index_in   : in  integer range I_LOWEST_NOTE to I_HIGHEST_NOTE;
      note_amp_in     : in  unsigned(NOTE_GAIN_WIDTH-1 downto 0);
      note_in         : in  signed(DATA_WIDTH-1 downto 0);
      cycle_start_in  : in  std_logic;
      -- pipeline out
      note_index_out  : out integer range I_LOWEST_NOTE to I_HIGHEST_NOTE;
      note_out        : out signed(DATA_WIDTH-1 downto 0)
    );
  end component;

  component poly_mix is
    generic (
      OUT_GAIN_WIDTH  : integer := WIDTH_OUT_GAIN;
      OUT_SHIFT_WIDTH : integer := WIDTH_OUT_SHIFT;
      DATA_WIDTH      : natural := WIDTH_WAVE_DATA;
      OUT_DATA_WIDTH  : natural := WIDTH_WAVE_DATA+8
    );
    port (
      clk             : in  std_logic;
      rst             : in  std_logic;
      -- synth controls
      out_amp         : in  unsigned(WIDTH_OUT_GAIN-1 downto 0);
      out_shift       : in  unsigned(WIDTH_OUT_SHIFT-1 downto 0);
      -- pipeline in
      note_index_in   : in  integer range I_LOWEST_NOTE to I_HIGHEST_NOTE;
      note_in         : in  signed(DATA_WIDTH-1 downto 0);
      -- pipeline out
      audio_out       : out std_logic_vector(OUT_DATA_WIDTH-1 downto 0)
    );
  end component;

  signal rst_n : std_logic;

  -- phase pipeline signals
  signal phase_q   : unsigned(WIDTH_PH_DATA-1 downto 0);

  -- note index pipeline signals
  signal note_index_q,
         note_index_q2,
         note_index_q3 : integer range I_LOWEST_NOTE to I_HIGHEST_NOTE;

  -- note pipeline signals
  signal note_q2,
         note_q3   : signed(DATA_WIDTH-1 downto 0);

  -- note amplitude pipeline signals
  signal note_amp_q,
         note_amp_q2 : unsigned(WIDTH_NOTE_GAIN-1 downto 0);

  -- start of cycle pipeline signals
  signal cycle_start_q,
         cycle_start_q2 : std_logic;

  -- synth controller signals
  signal ph_inc_table  : t_ph_inc_lut;
  signal note_amps     : t_note_amp;
  signal wfrm_amps     : t_wfrm_amp;
  signal wfrm_phs      : t_wfrm_ph;
  signal out_amp       : unsigned(WIDTH_OUT_GAIN-1 downto 0);
  signal out_shift     : unsigned(WIDTH_OUT_SHIFT-1 downto 0);
  signal pulse_width   : unsigned(WIDTH_PULSE_WIDTH-1 downto 0);

begin

  rst_n     <= not(rst);

  u_synth_axi_ctrl: synth_axi_ctrl
    generic map (
      -- Width of S_AXI data bus
      C_S_AXI_DATA_WIDTH => C_S_AXI_DATA_WIDTH,
      -- Width of S_AXI address bus
      C_S_AXI_ADDR_WIDTH => C_S_AXI_ADDR_WIDTH
    )
    port map (
      -- synth controls out
      note_amps    => note_amps,
      ph_inc_table => ph_inc_table,
      wfrm_amps    => wfrm_amps,
      wfrm_phs     => wfrm_phs,
      out_amp      => out_amp,
      out_shift    => out_shift,
      pulse_width  => pulse_width,

      -- AXI control interface
      s_axi_aclk    => clk,
      s_axi_aresetn => rst_n,
      s_axi_awaddr  => s_axi_awaddr,
      s_axi_awprot  => s_axi_awprot,
      s_axi_awvalid => s_axi_awvalid,
      s_axi_awready => s_axi_awready,
      s_axi_wdata   => s_axi_wdata,
      s_axi_wstrb   => s_axi_wstrb,
      s_axi_wvalid  => s_axi_wvalid,
      s_axi_wready  => s_axi_wready,
      s_axi_bresp   => s_axi_bresp,
      s_axi_bvalid  => s_axi_bvalid,
      s_axi_bready  => s_axi_bready,
      s_axi_araddr  => s_axi_araddr,
      s_axi_arprot  => s_axi_arprot,
      s_axi_arvalid => s_axi_arvalid,
      s_axi_arready => s_axi_arready,
      s_axi_rdata   => s_axi_rdata,
      s_axi_rresp   => s_axi_rresp,
      s_axi_rvalid  => s_axi_rvalid,
      s_axi_rready  => s_axi_rready
    );
  
  u_stage_0_phase_gen: phase_accumulator
    generic map (
      PHASE_WIDTH     => WIDTH_PH_DATA,
      NOTE_GAIN_WIDTH => WIDTH_NOTE_GAIN
    )
    port map (
      clk             => clk,
      rst             => rst,
      -- synth controls
      phase_incs      => ph_inc_table,
      note_amps       => note_amps,
      -- pipeline out
      note_index_out  => note_index_q,
      phase_out       => phase_q,
      note_amp_out    => note_amp_q,
      cycle_start_out => cycle_start_q
    );
  
  u_stage_1_phase_to_wave: phase_to_wave
    generic map (
      PHASE_WIDTH     => WIDTH_PH_DATA,
      NOTE_GAIN_WIDTH => WIDTH_NOTE_GAIN,
      DATA_WIDTH      => WIDTH_WAVE_DATA,
      SIN_LUT_PH      => 12
    )
    port map (
      clk             => clk,
      rst             => rst,
      -- synth controls
      wfrm_amps       => wfrm_amps,
      wfrm_phs        => wfrm_phs,
      pulse_width     => pulse_width,
      -- pipeline in
      note_index_in   => note_index_q,
      phase_in        => phase_q,
      note_amp_in     => note_amp_q,
      cycle_start_in  => cycle_start_q,
      -- pipeline out
      note_index_out  => note_index_q2,
      note_out        => note_q2,
      note_amp_out    => note_amp_q2,
      cycle_start_out => cycle_start_q2
    );

  u_stage_2_envelope_scale: envelope_scale
    generic map(
      NOTE_GAIN_WIDTH => WIDTH_NOTE_GAIN,
      DATA_WIDTH      => WIDTH_WAVE_DATA
    )
    port map (
      clk             => clk,
      rst             => rst,
      -- synth controls
      -- adsr_settings
      -- pipeline in
      note_index_in   => note_index_q2,
      note_amp_in     => note_amp_q2,
      note_in         => note_q2,
      cycle_start_in  => cycle_start_q2,
      -- pipeline out
      note_index_out  => note_index_q3,
      note_out        => note_q3
    );
  
  u_stage_3_poly_mix: poly_mix
    generic map (
      OUT_GAIN_WIDTH  => WIDTH_OUT_GAIN,
      OUT_SHIFT_WIDTH => WIDTH_OUT_SHIFT,
      DATA_WIDTH      => WIDTH_WAVE_DATA,
      OUT_DATA_WIDTH  => WIDTH_WAVE_DATA+8
    )
    port map (
      clk             => clk,
      rst             => rst,
      -- synth controls
      out_amp         => out_amp,
      out_shift       => out_shift,
      -- pipeline in
      note_index_in   => note_index_q3,
      note_in         => note_q3,
      -- pipeline out
      audio_out       => audio_out
    );

end struct_synth_engine;