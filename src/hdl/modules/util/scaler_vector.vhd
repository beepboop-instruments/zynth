----------------------------------------------------------------------------------
-- Company: beepboop
-- Engineer: Tyler Huddleston
-- 
-- Create Date: 03/22/2025
-- Design Name: Synthesizer Engine
-- Module Name: Scaler
--
-- Description:
--   Scales an input word according to the gain.
-- 
----------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity scaler_vector is
  generic (
    WIDTH_DATA : integer := 16;  -- Width of input and output samples
    WIDTH_GAIN : integer := 7
  );
  port (
    input_word  : in  std_logic_vector(WIDTH_DATA-1 downto 0);
    gain_word   : in  unsigned(WIDTH_GAIN-1 downto 0);
    output_word : out std_logic_vector(WIDTH_DATA-1 downto 0)
  );
end scaler_vector;

architecture behavioral of scaler_vector is
begin
  process(input_word, gain_word)
    variable in_signed      : signed(WIDTH_DATA-1 downto 0);
    variable scaled_sum     : signed(WIDTH_DATA downto 0) := (others => '0');
    variable shifted_input  : signed(WIDTH_DATA-1 downto 0);
  begin
    in_signed := signed(input_word);
    scaled_sum := (others => '0');

    for i in 0 to WIDTH_GAIN-1 loop
      if gain_word(WIDTH_GAIN-1-i) = '1' then
        shifted_input := shift_right(in_signed, i);
        scaled_sum := scaled_sum + resize(shifted_input, WIDTH_DATA + 1);
      end if;
    end loop;

    output_word <= std_logic_vector(scaled_sum(WIDTH_DATA downto 1));
  end process;

end behavioral;
