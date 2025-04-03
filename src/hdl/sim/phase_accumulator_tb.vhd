----------------------------------------------------------------------------------
-- Company: beepboop
-- Engineer: Tyler Huddleston
-- 
-- Create Date: 03/08/2025
-- Design Name: Synthesizer Engine
-- Module Name: Phase Accumulator Testbench
-- Description: 
--   Simulation testbench for the Phase Accumulator in the Synthesizer Engine.
-- 
----------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library xil_defaultlib;
  use xil_defaultlib.synth_pkg.all;
  use xil_defaultlib.music_note_pkg.all;

entity phase_accumulator_tb is
  
end phase_accumulator_tb;

architecture tb of phase_accumulator_tb is
    
  -- DUT Component
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

  -- Clock process
  constant clk_period  : time := 40 ns;
  constant clk_period2 : time := 80 ns;

  -- note amps
  signal note_amps : t_note_amp;
  
    
begin
  -- Instantiate the DUT

  uut: phase_accumulator
    generic map (
      PHASE_WIDTH => WIDTH_PH_DATA
    )
    port map (
      clk             => clk,
      rst             => rst,
      phase_incs      => ph_inc_lut,
      note_amps       => note_amps,
      note_index_out  => open,
      phase_out       => open,
      note_amp_out    => open,
      cycle_start_out => open
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
  wait for clk_period2;
  rst     <= '0';
  wait;
end process stimulus;

end tb;
