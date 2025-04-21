----------------------------------------------------------------------------------
-- Company: beepboop
-- Engineer: Tyler Huddleston
-- 
-- Create Date: 04/13/2025
-- Design Name: Compressor
-- Module Name: Envelope Follower
-- Description: 
--   Generates an envelope for a digital waveform.
-- 
----------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library xil_defaultlib;
  use xil_defaultlib.synth_pkg.all;

entity envelope_follower is
  generic (
    SAMPLE_WIDTH   : integer := WIDTH_WAVE_DATA;
    ENV_WIDTH      : integer := WIDTH_WAVE_DATA
  );
  port (
    -- clock + reset
    clk          : in  std_logic;
    rst          : in  std_logic;
    -- input controls
    attack_amt   : in  integer;
    release_amt  : in  integer;
    sample_in    : in  std_logic_vector(SAMPLE_WIDTH-1 downto 0);
    envelope_out : out unsigned(ENV_WIDTH-1 downto 0)
  );
end entity envelope_follower;

architecture rtl of envelope_follower is

  signal sample_abs_d,
         sample_abs_q,
         env_d,
         env_q         : unsigned(SAMPLE_WIDTH-1 downto 0);

begin

  -- output assignments
  envelope_out <= env_q(SAMPLE_WIDTH-1 downto SAMPLE_WIDTH - ENV_WIDTH);

  s_envelope_follower: process(sample_abs_q, sample_in, env_q, attack_amt, release_amt)
    variable diff : unsigned(SAMPLE_WIDTH-1 downto 0);
  begin
      -- use absolute value of input
      if (sample_in(SAMPLE_WIDTH-1) = '1') then
        sample_abs_d <= unsigned(not(sample_in)) + 1;
      else
        sample_abs_d <= unsigned(sample_in);
      end if;

      if (sample_abs_q > env_q) then
        -- apply attack
        diff   := sample_abs_q - env_q;
        env_d  <= env_q + (diff srl attack_amt);
      else
        -- apply release
        diff   := env_q - sample_abs_q;
        env_d  <= env_q - (diff srl release_amt);
      end if;
      
  end process s_envelope_follower;

  -- synchronous logic registers
  s_regs: process(clk, rst)
  begin
    if (rst = '1') then
      sample_abs_q <= (others => '0');
      env_q        <= (others => '0');
    elsif (rising_edge(clk)) then
      sample_abs_q <= sample_abs_d;
      env_q        <= env_d;
    end if;
  end process s_regs;

end architecture rtl;
