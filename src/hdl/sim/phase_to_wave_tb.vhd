----------------------------------------------------------------------------------
-- Company: beepboop
-- Engineer: Tyler Huddleston
-- 
-- Create Date: 03/08/2025
-- Design Name: Synthesizer Engine
-- Module Name: Phase to Waveform Testbench
-- Description: 
--   Simulation testbench for the Phase to Waveform in the Synthesizer Engine.
-- 
----------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library xil_defaultlib;
  use xil_defaultlib.synth_pkg.all;
  use xil_defaultlib.music_note_pkg.all;

entity phase_to_wave_tb is
  
end phase_to_wave_tb;

architecture tb of phase_to_wave_tb is
    
  -- DUT Component
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
      wave_mix_amp    : in  unsigned(WIDTH_NOTE_GAIN-1 downto 0);
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

  component phase_accumulator is
    generic (
      PHASE_WIDTH : integer := WIDTH_PH_DATA;
      NOTE_GAIN_WIDTH : integer := WIDTH_NOTE_GAIN
    );
    port (
      clk             : in  std_logic;
      rst             : in  std_logic;
      phase_incs      : in  t_ph_inc_lut;
      note_amps       : in  t_note_amp;
      note_index_out  : out integer range I_LOWEST_NOTE to I_HIGHEST_NOTE;
      phase_out       : out unsigned(PHASE_WIDTH-1 downto 0);
      note_amp_out    : out unsigned(NOTE_GAIN_WIDTH-1 downto 0);
      cycle_start_out : out std_logic
    );
  end component;

  signal clk : std_logic := '0';
  signal rst : std_logic := '1';

  signal phase_q   : unsigned(WIDTH_PH_DATA-1 downto 0);

  signal note_index_q : integer range I_LOWEST_NOTE to I_HIGHEST_NOTE;

  signal note_amp_q : unsigned(WIDTH_NOTE_GAIN-1 downto 0);

  signal cycle_start_q : std_logic;

  signal wfrm_amps : t_wfrm_amp;
  signal wfrm_phs  : t_wfrm_ph;

  -- Clock process
  constant clk_period  : time := 40 ns;
  constant clk_period2 : time := 80 ns;

  -- note amps
  signal note_amps : t_note_amp;
  
    
begin
  -- Instantiate the DUT
  uut: phase_to_wave
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
      pulse_width     => x"4000",
      wave_mix_amp    => "1111111",
      -- pipeline in
      note_index_in   => note_index_q,
      phase_in        => phase_q,
      note_amp_in     => note_amp_q,
      cycle_start_in  => cycle_start_q,
      -- pipeline out
      note_index_out  => open,
      note_out        => open,
      note_amp_out    => open,
      cycle_start_out => open
    );

  u_phase_accumulator: phase_accumulator
    generic map (
      PHASE_WIDTH => WIDTH_PH_DATA
    )
    port map (
      clk             => clk,
      rst             => rst,
      phase_incs      => ph_inc_lut,
      note_amps       => note_amps,
      note_index_out  => note_index_q,
      phase_out       => phase_q,
      note_amp_out    => note_amp_q,
      cycle_start_out => cycle_start_q
    );
  
  -- Clock Process
  clk_process : process
  begin
      while true loop
          clk <= '0';
          wait for clk_period / 2;
          clk <= '1';
          wait for clk_period / 2;
      end loop;
  end process;

-- Stimulus Process
stimulus : process
begin
  note_amps    <= (others => (others => '0'));
  note_amps(0) <= "1111111";
  wfrm_amps    <= (others => (others => '1'));
  wfrm_phs     <= (others => (others => '1'));
  wait for clk_period2;
  rst     <= '0';
  wait;
end process stimulus;

end tb;
