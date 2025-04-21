----------------------------------------------------------------------------------
-- Company: beepboop
-- Engineer: Tyler Huddleston
-- 
-- Create Date: 04/13/2025
-- Design Name: Zynq Synthesizer
-- Module Name: Audio Path Testbench
-- Description: 
--   Testbench for the audio path.
-- 
----------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library xil_defaultlib;
  use xil_defaultlib.synth_pkg.all;

entity audio_path_tb is
end entity audio_path_tb;

architecture tb of audio_path_tb is

  component synth_engine_tb is
    port (
      clk_tb        : out std_logic;
      rst_tb        : out std_logic;
      audio_out     : out std_logic_vector(WIDTH_WAVE_DATA+7 downto 0)
    );
  end component synth_engine_tb;

  component compressor is
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
  end component compressor;

  -- clock + reset
  signal clk, rst    : std_logic;

  signal synth_audio : std_logic_vector(WIDTH_WAVE_DATA+7 downto 0);

begin

  u_stim_synth_engine_tb: synth_engine_tb
    port map (
      clk_tb     => clk,
      rst_tb     => rst,
      audio_out  => synth_audio
    );

  -- instantiate DUT
  u_compressor: compressor
      generic map (
        SAMPLE_WIDTH => WIDTH_WAVE_DATA+8,
        ENV_WIDTH    => WIDTH_WAVE_DATA+8,
        GAIN_WIDTH   => WIDTH_WAVE_GAIN
      )
      port map (
        -- clock + reset
        clk          => clk,
        rst          => rst,
        -- input controls
        attack_amt   => 4,
        release_amt  => 10,
        threshold    => x"071B00", -- ~72% of full scale
        knee_width   => x"2DC600",  -- Smooth transition over this envelope range
        knee_slope   => "1010000",  -- ~0.5
        -- audio samples
        sample_in    => synth_audio,
        sample_out   => open
      );
    
end architecture;
