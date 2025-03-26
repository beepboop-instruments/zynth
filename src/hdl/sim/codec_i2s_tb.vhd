----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/23/2025 08:56:17 PM
-- Design Name: 
-- Module Name: codec_i2s_tb - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity codec_i2s_tb is
--  Port ( );
end codec_i2s_tb;

architecture Behavioral of codec_i2s_tb is

  -- MCLK MMCM
  component clk_wiz_mclk is
  Port (
    reset    : in  std_logic;
    clk_in1  : in  std_logic;
    locked   : out std_logic;
    clk_out1 : out std_logic
    );
  end component clk_wiz_mclk;

  component clk_wiz_25_to_100 is
    port (
      reset         : in  std_logic;
      clk_in1       : in  std_logic;
      locked        : out std_logic;
      clk_out1     : out std_logic
    );
  end component clk_wiz_25_to_100;

  -- Audio codec
  component codec_i2s is
  generic (
    G_MCLK_BCLK_RATIO : natural := 2;
    G_DATA_WIDTH      : natural := 24;
    G_WORDSIZE        : natural := 24
  );
  port (
    -- input logic clock domain
    rst         : in  std_logic;                                 -- main logic reset
    clk         : in  std_logic;                                 -- main clock
    dac_data_l  : in  std_logic_vector(G_DATA_WIDTH-1 downto 0); -- left DAC data to codec
    dac_data_r  : in  std_logic_vector(G_DATA_WIDTH-1 downto 0); -- right DAC data to codec
    dac_latched : out std_logic;                                 -- DAC data to codec latched
    adc_data    : out std_logic_vector(G_DATA_WIDTH*2-1 downto 0); -- ADC data from codec
    adc_latched : out std_logic;                                 -- ADC data from codec latched
    -- mclk domain
    mclk_in     : in std_logic;                                  -- codec master clock from fabric
    mclk        : out std_logic;                                 -- codec master clock out
    bclk        : out std_logic;                                 -- codec bit clock
    pbdat       : out std_logic;                                 -- codec playback data
    pblrc       : out std_logic;                                 -- codec playback data left/right select
    recdat      : in  std_logic;                                 -- codec record data
    reclrc      : out std_logic;                                 -- codec record data left/right select
    mute_n      : out std_logic    );                            -- codec mute enable
  end component codec_i2s;
  
  signal clk25    : std_logic := '0';
  signal rst25    : std_logic := '1';

  signal clk100   : std_logic;
  
  signal mclk_12p88 : std_logic;
  signal mclk       : std_logic;
  signal bclk       : std_logic;
  signal pblrc      : std_logic;
  signal pbdat      : std_logic;
  signal mute_n     : std_logic;
  signal clk25_locked : std_logic;
  signal rst_sync   : std_logic;

begin

  -- Reset and clock
  clk25 <= not clk25 after 20 ns;
  rst25 <= '0' after 50 ns;
  
  rst_sync <= rst25 or not(clk25_locked);
  
  
-- MCLK MMCM
u_mclk_mmcm: clk_wiz_mclk
  port map (
    reset         => rst25,
    clk_in1       => clk100,
    locked        => clk25_locked,
    clk_out1     => mclk_12p88
  );

  u_mclk_25_to_100: clk_wiz_25_to_100
    port map (
      reset         => rst25,
      clk_in1       => clk25,
      locked        => open,
      clk_out1     => clk100
    );

  -- Audio codec
  u_audio_codec: component codec_i2s
  generic map (
    G_MCLK_BCLK_RATIO => 2,
    G_DATA_WIDTH      => 24,
    G_WORDSIZE        => 32
  )
  port map (
    -- input clock domain
    rst         => rst_sync,
    clk         => clk25,
    dac_data_l  => (others => '1'),
    dac_data_r  => (others => '1'),
    dac_latched => open,
    adc_data    => open,
    adc_latched => open,
    -- mclk domain
    mclk_in     => mclk_12p88,
    mclk        => mclk,
    bclk        => bclk,
    pbdat       => pbdat,
    pblrc       => pblrc,
    recdat      => '1',
    reclrc      => open,
    mute_n      => mute_n
  );


end Behavioral;
