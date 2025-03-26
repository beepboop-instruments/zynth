----------------------------------------------------------------------------------
-- Company: beepboop
-- Engineer: Tyler Huddleston
-- 
-- Create Date: 03/25/2025
-- Design Name: Synthesizer Engine
-- Module Name: Amplitude Change Gate
--
-- Description: 
--   This module will only allow an amplitude to change at the start of a new
--   new cycle to prevent abrupt jumps when playing smoother wave forms like
--   sine and triangle waves.
-- 
----------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

  library xil_defaultlib;
    use xil_defaultlib.synth_pkg.all;

entity amp_gate is
  port (
    clk            : in std_logic;
    rst            : in std_logic;
    note_amp       : in  unsigned(WIDTH_NOTE_GAIN-1 downto 0);
    phase          : in  unsigned(WIDTH_PH_DATA-1 downto 0);
    note_amp_gated : out unsigned(WIDTH_NOTE_GAIN-1 downto 0)
  );
end entity;

architecture rtl of amp_gate is
  
  signal phase_q  : unsigned(WIDTH_PH_DATA-1 downto 0);

begin

  s_amp_gate: process(clk, rst)
    begin
      if (rst = '1') then
        phase_q <= (others => '0');
      elsif (rising_edge(clk)) then
        phase_q <= phase;
        -- detect phase counter rollover
        if (phase_q > phase) then 
          note_amp_gated <= note_amp;
        end if;
      end if;
  end process;
  
end architecture;