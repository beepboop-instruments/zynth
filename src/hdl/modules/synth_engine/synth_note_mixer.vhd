----------------------------------------------------------------------------------
-- Company: beepboop
-- Engineer: Tyler Huddleston
-- 
-- Create Date: 03/21/2025
-- Design Name: Synthesizer Engine
-- Module Name: Synthesizer Mixer
-- Description: 
--   Mixes multiple vectors within an array by summing them to a single vector.
-- 
----------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library xil_defaultlib;
  use xil_defaultlib.synth_pkg.all;

entity synth_note_mixer is
  generic (
    I_LOW       : integer := 0;  -- lowest index in array
    I_HIGH      : integer := 3;  -- highest index in array
    IN_WIDTH    : integer := 16; -- width of input data
    OUT_WIDTH   : integer := 24  -- width of output data
  );
  port (
    in_array : in  t_wave_data;
    out_sum  : out signed(OUT_WIDTH-1 downto 0)
  );
end entity;

architecture behavioral of synth_note_mixer is
begin

  process(in_array)
    variable sum_accumulator : signed(OUT_WIDTH-1 downto 0);
  begin
    -- initialize sum to 0
    sum_accumulator := (others => '0');

    -- sum all vectors in an array
    for i in I_LOW to I_HIGH loop
      sum_accumulator := sum_accumulator + in_array(i);
    end loop;

    -- output assignment
    out_sum <= sum_accumulator;

  end process;
end architecture;
