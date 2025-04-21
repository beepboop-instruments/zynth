----------------------------------------------------------------------------------
-- Company: beepboop
-- Engineer: Tyler Huddleston
-- 
-- Create Date: 04/13/2025
-- Design Name: Compressor
-- Module Name: Gain Computer
-- Description: 
--   Calculates the compression gain to apply to a given sample.
-- 
----------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library xil_defaultlib;
  use xil_defaultlib.synth_pkg.all;

entity gain_computer is
  generic (
    ENV_WIDTH      : integer := WIDTH_WAVE_DATA;
    GAIN_WIDTH     : integer := WIDTH_OUT_GAIN
  );
  port (
    -- clock + reset
    clk          : in  std_logic;
    rst          : in  std_logic;
    -- input controls
    threshold    : in  unsigned(ENV_WIDTH-1  downto 0);
    knee_width   : in  unsigned(ENV_WIDTH-1  downto 0);
    knee_slope   : in  unsigned(GAIN_WIDTH-1 downto 0);
    -- envelope input
    envelope_in  : in  unsigned(ENV_WIDTH-1  downto 0);
    -- gain output
    gain_out     : out unsigned(GAIN_WIDTH-1 downto 0)
  );
end entity gain_computer;

architecture rtl of gain_computer is

  component scaler_unsigned is
    generic (
      WIDTH_DATA : integer := 16;  -- Width of input and output samples
      WIDTH_GAIN : integer := 7
    );
    port (
      input_word  : in  unsigned(WIDTH_DATA-1 downto 0);
      gain_word   : in  unsigned(WIDTH_GAIN-1 downto 0);
      output_word : out unsigned(WIDTH_DATA-1 downto 0)
    );
  end component scaler_unsigned;

  signal delta,
         knee_start       : unsigned(ENV_WIDTH-1 downto 0);

  signal gain_d,
         gain_q,
         reduction,
         full_scale       : unsigned(GAIN_WIDTH-1 downto 0);
  
  signal gain_mult_result : unsigned(ENV_WIDTH + GAIN_WIDTH - 1 downto 0);

  -- about 12.5% (6 dB) headroom
  constant MIN_GAIN : unsigned(GAIN_WIDTH-1 downto 0) := to_unsigned(1, GAIN_WIDTH);
  constant MAX_GAIN : unsigned(GAIN_WIDTH-1 downto 0) := to_unsigned((2**GAIN_WIDTH - 2**(GAIN_WIDTH - 3)), GAIN_WIDTH);

begin

  -- output assignments
  gain_out <= gain_q;

  -- logic assignments
  knee_start       <= threshold - knee_width when threshold >= knee_width else
                      (others => '0');
  delta            <= envelope_in - knee_start;
  full_scale       <= (others => '1');
  gain_mult_result <= delta * knee_slope;
  reduction        <= gain_mult_result(ENV_WIDTH + GAIN_WIDTH - 1 downto ENV_WIDTH);

  -- Compression only active in knee range
  process(envelope_in, knee_start, threshold, clk, gain_q, full_scale, reduction)
  begin
    gain_d <= gain_q;
    if envelope_in < knee_start then
      gain_d <= full_scale;  -- No compression
    else
      gain_d <= full_scale - reduction;
    end if;
  end process;

  -- synchronous logic registers
  s_regs: process(clk, rst)
  begin
    if (rst = '1') then
      gain_q <= (others => '1');
    elsif (rising_edge(clk)) then
      gain_q <= gain_d;
    end if;
  end process s_regs;

end architecture rtl;
