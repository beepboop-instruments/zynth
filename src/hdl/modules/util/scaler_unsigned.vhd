----------------------------------------------------------------------------------
-- Company: beepboop
-- Engineer: Tyler Huddleston
-- 
-- Create Date: 04/09/2025
-- Design Name: Synthesizer Engine
-- Module Name: Scaler Unsigned
--
-- Description:
--   Scales an unsigned input word according to the gain.
-- 
----------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity scaler_unsigned is
  generic (
    WIDTH_DATA : integer := 16;  -- Width of input and output samples
    WIDTH_GAIN : integer := 7
  );
  port (
    input_word  : in  unsigned(WIDTH_DATA-1 downto 0);
    gain_word   : in  unsigned(WIDTH_GAIN-1 downto 0);
    output_word : out unsigned(WIDTH_DATA-1 downto 0)
  );
end scaler_unsigned;

architecture behavioral of scaler_unsigned is
begin
  process(input_word, gain_word)
    variable scaled_sum    : unsigned(WIDTH_DATA downto 0) := (others => '0');
    variable shifted_input : unsigned(WIDTH_DATA-1 downto 0);
  begin
    scaled_sum := (others => '0'); -- Reset sum each clock cycle
    
    -- Binary decomposition: sum shifted versions of input_word
    for i in 0 to WIDTH_GAIN-1 loop
      if gain_word(WIDTH_GAIN-1-i) = '1' then
        shifted_input := shift_right(input_word, i); -- Right shift for scaling
        scaled_sum    := scaled_sum + shifted_input; -- Accumulate shifted values
      end if;
    end loop;

    -- Assign scaled output (saturating if needed)
    output_word <= scaled_sum(WIDTH_DATA downto 1);

    end process;

end behavioral;
