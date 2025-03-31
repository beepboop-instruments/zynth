----------------------------------------------------------------------------------
-- Company: beepboop
-- Engineer: Tyler Huddleston
-- 
-- Create Date: 03/01/2025
-- Design Name: Synthesizer Engine
-- Module Name: Phase Accumulator
--
-- Description:
--   Increments a circular counter by a given phase increment.
-- 
----------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity phase_accumulator is
  generic (
    PHASE_WIDTH : integer := 8 -- 8-bit phase index
  );
  port (
    clk       : in  std_logic;
    rst       : in  std_logic;
    phase_in  : in  unsigned(PHASE_WIDTH-1 downto 0); -- Phase input
    increment : in  unsigned(PHASE_WIDTH-1 downto 0); -- Phase increment
    phase     : out unsigned(PHASE_WIDTH-1 downto 0)  -- Phase output
  );
end entity;

architecture rtl of phase_accumulator is
  signal phase_reg : unsigned(PHASE_WIDTH-1 downto 0) := (others => '0');
begin
  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        phase_reg <= (others => '0');
      else
        phase_reg <= phase_in + increment;
      end if;
    end if;
  end process;

  phase <= phase_reg;

end architecture;
