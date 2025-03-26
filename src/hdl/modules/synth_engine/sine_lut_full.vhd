----------------------------------------------------------------------------------
-- Company: beepboop
-- Engineer: Tyler Huddleston
-- 
-- Create Date: 03/01/2025
-- Design Name: Synthesizer Engine
-- Module Name: Sine Wave Full Lookup Table
--
-- Description: 
--   The Sine Wave Full Lookup Table provides a sine wave value for a given phase
--   index. The full table is created from a quarter wave sine table stored
--   in memory.
-- 
----------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity sine_lut_full is
  generic (
    PHASE_WIDTH : natural := 12;
    SINE_WIDTH  : natural := 16
  );
  port (
    clk      : in  std_logic;
    phase    : in  std_logic_vector(PHASE_WIDTH-1 downto 0);
    sine_out : out signed(SINE_WIDTH-1 downto 0)
  );
end entity;

architecture rtl of sine_lut_full is
  
  component sine_quarter_wave_lut is
    PORT (
      a   : in  std_logic_vector(PHASE_WIDTH-3 downto 0);
      spo : OUT std_logic_vector(SINE_WIDTH-1 downto 0)
    );
  end component sine_quarter_wave_lut;

  signal addr    : std_logic_vector(PHASE_WIDTH-3 downto 0);
  signal sine    : std_logic_vector(SINE_WIDTH-1 downto 0);

begin

  -- index into table in reverse order from pi/2 to pi and from 3*pi/2 to 2*pi
  addr <=  phase(PHASE_WIDTH-3 downto 0) when phase(PHASE_WIDTH-2) = '0'
             else not(phase(PHASE_WIDTH-3 downto 0));
  
  -- sine wave is negative from pi to 2*pi
  sine_out <= signed(sine) when phase(PHASE_WIDTH-1) = '1' else 0 - signed(sine);
  
  u_sine_lut: sine_quarter_wave_lut 
    port map (
      a => addr,
      spo  => sine
    );
  
end architecture;
