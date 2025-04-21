----------------------------------------------------------------------------------
-- Company: beepboop
-- Engineer: Tyler Huddleston
-- 
-- Create Date: 03/08/2025
-- Design Name: Synthesizer Engine
-- Module Name: Synthesizer Engine
-- Description: 
--   Generates 128-note polyphonic waveforms and mixes them into one 
--   digital waveform.
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
    clk           : in  std_logic;
    rst           : in  std_logic;
    -- state machine in
    data_latched  : in  std_logic;
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
  end synth_engine;
  
architecture struct_synth_engine of synth_engine is

  component phase_accumulator is
    generic (
      PHASE_WIDTH     : integer := WIDTH_PH_DATA;
      NOTE_GAIN_WIDTH : integer := WIDTH_NOTE_GAIN
    );
    port (
      clk             : in  std_logic;
      rst             : in  std_logic;
      -- state machine in
      data_latched    : in  std_logic;
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
      DATA_WIDTH      : natural := WIDTH_WAVE_DATA;
      ADSR_WIDTH      : natural := WIDTH_ADSR_CC;
      ACC_WIDTH       : natural := WIDTH_ADSR_COUNT
    );
    port (
      clk             : in  std_logic;
      rst             : in  std_logic;
      -- synth controls
      attack_amt      : in  unsigned(ADSR_WIDTH-1 downto 0);
      decay_amt       : in  unsigned(ADSR_WIDTH-1 downto 0);
      sustain_amt     : in  unsigned(ADSR_WIDTH-1 downto 0);
      release_amt     : in  unsigned(ADSR_WIDTH-1 downto 0);
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
      OUT_DATA_WIDTH  : natural := OUT_DATA_WIDTH
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

begin
  
  u_stage_0_phase_gen: phase_accumulator
    generic map (
      PHASE_WIDTH     => WIDTH_PH_DATA,
      NOTE_GAIN_WIDTH => WIDTH_NOTE_GAIN
    )
    port map (
      clk             => clk,
      rst             => rst,
      -- state machine in
      data_latched    => data_latched,
      -- synth controls
      phase_incs      => phase_incs,
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
      DATA_WIDTH      => WIDTH_WAVE_DATA,
      ADSR_WIDTH      => WIDTH_ADSR_CC,
      ACC_WIDTH       => WIDTH_ADSR_COUNT
    )
    port map (
      clk             => clk,
      rst             => rst,
      -- synth controls
      attack_amt      => attack_amt,
      decay_amt       => decay_amt,
      sustain_amt     => sustain_amt,
      release_amt     => release_amt,
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
      OUT_DATA_WIDTH  => OUT_DATA_WIDTH
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