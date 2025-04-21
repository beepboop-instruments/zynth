----------------------------------------------------------------------------------
-- Company: beepboop
-- Engineer: Tyler Huddleston
-- 
-- Create Date: 04/13/2025
-- Design Name: Compressor
-- Module Name: Compressor
-- Description: 
--   Applies compression to a stream of audio samples.
-- 
----------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library xil_defaultlib;
  use xil_defaultlib.synth_pkg.all;

entity compressor is
  generic (
    SAMPLE_WIDTH : integer := WIDTH_WAVE_DATA;
    ENV_WIDTH    : integer := WIDTH_WAVE_DATA;
    GAIN_WIDTH   : integer := WIDTH_OUT_GAIN
  );
  port(
    -- clock + reset
    clk          : in  std_logic;
    rst          : in  std_logic;
    -- input controls
    attack_amt   : in  integer;
    release_amt  : in  integer;
    threshold    : in  unsigned(ENV_WIDTH-1  downto 0);
    knee_width   : in  unsigned(ENV_WIDTH -1 downto 0);
    knee_slope   : in  unsigned(GAIN_WIDTH-1 downto 0);
    -- audio samples
    sample_in    : in  std_logic_vector(SAMPLE_WIDTH-1 downto 0);
    sample_out   : out std_logic_vector(SAMPLE_WIDTH-1 downto 0)
  );
end entity compressor;

architecture rtl of compressor is
    
  component envelope_follower is
    generic (
      SAMPLE_WIDTH : integer := WIDTH_WAVE_DATA;
      ENV_WIDTH    : integer := WIDTH_OUT_GAIN
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
  end component;

  component gain_computer is
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
      envelope_in  : in  unsigned(ENV_WIDTH-1  downto 0);
      knee_width   : in  unsigned(ENV_WIDTH -1 downto 0);
      knee_slope   : in  unsigned(GAIN_WIDTH-1 downto 0);
      gain_out     : out unsigned(GAIN_WIDTH-1 downto 0)
    );
  end component gain_computer;

  component scaler_vector is
    generic (
      WIDTH_DATA : integer := 16;
      WIDTH_GAIN : integer := 7
    );
    port (
      input_word  : in  std_logic_vector(WIDTH_DATA-1 downto 0);
      gain_word   : in  unsigned(WIDTH_GAIN-1 downto 0);
      output_word : out std_logic_vector(WIDTH_DATA-1 downto 0)
    );
  end component scaler_vector;
  
  signal envelope     : unsigned(SAMPLE_WIDTH-1 downto 0);
  signal gain         : unsigned(GAIN_WIDTH-1 downto 0);
  signal sample_out_d,
         sample_out_q : std_logic_vector(SAMPLE_WIDTH-1 downto 0);

begin

  sample_out <= sample_out_q;

  u_env_follower: envelope_follower
    generic map (
      SAMPLE_WIDTH => SAMPLE_WIDTH,
      ENV_WIDTH    => ENV_WIDTH
    )
    port map (
      -- clock + reset
      clk          => clk,
      rst          => rst,
      -- input controls
      attack_amt   => attack_amt,
      release_amt  => release_amt,
      sample_in    => sample_in,
      envelope_out => envelope
    );
  
  u_gain_computer: gain_computer
    generic map (
      ENV_WIDTH    => SAMPLE_WIDTH,
      GAIN_WIDTH   => GAIN_WIDTH
    )
    port map (
      -- clock + reset
      clk          => clk,
      rst          => rst,
      -- input controls
      threshold    => threshold,
      envelope_in  => envelope,
      knee_width   => knee_width,
      knee_slope   => knee_slope,
      gain_out     => gain
    );

  u_scaler: scaler_vector
    generic map (
      WIDTH_DATA  => SAMPLE_WIDTH,
      WIDTH_GAIN  => GAIN_WIDTH
    )
    port map (
      input_word  => sample_in,
      gain_word   => gain,
      output_word => sample_out_d
    );

  s_regs: process(clk, rst)
  begin
    if (rst = '1') then
      sample_out_q <= (others => '0');
    elsif (rising_edge(clk)) then
      sample_out_q <= sample_out_d;
    end if;
  end process s_regs;

end architecture rtl;