----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/26/2025 07:58:49 PM
-- Design Name: 
-- Module Name: audio_dds_tb - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

library work;
use work.music_note_pkg.all;

entity audio_dds_tb is
--  Port ( );
end audio_dds_tb;

architecture Behavioral of audio_dds_tb is

  component dds_audio is
    port (
      aclk                            : in  std_logic;
      s_axis_config_tvalid            : in  std_logic;
      s_axis_config_tdata             : in  std_logic_vector(63 downto 0);
      m_axis_data_tvalid              : OUT std_logic;
      m_axis_data_tdata               : OUT std_logic_vector(15 downto 0);
      m_axis_phase_tvalid             : OUT std_logic;
      m_axis_phase_tdata              : OUT std_logic_vector(31 downto 0)
    );
  end component dds_audio;

  component clkdivider is
    generic (
      G_DIVIDEBY : natural := 2
    );
    port (
      clk : in std_logic;
      reset : in std_logic;
      pulseout : out std_logic
    );
  end component clkdivider;
  
  component rst_sync is
    port (
      rst_async_in : in  std_logic;
      clk_sync_in  : in  std_logic;
      rst_sync_out : out std_logic
    );
  end component rst_sync;
  
  component clk_wiz_mclk is
    port (
      reset         : in  std_logic;
      clk_in1       : in  std_logic;
      locked        : out std_logic;
      mclk_codec    : out std_logic;
      clk_audio_dds : out std_logic
    );
    end component clk_wiz_mclk;
    
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

  signal clk100    : std_logic := '0';
  signal clk_12p8  : std_logic;
  signal clk_12p288 : std_logic;
  signal clk_0p16   : std_logic;
  
  signal rst100    : std_logic := '1';
  signal rst_12p8 : std_logic;
  
  signal dds_data  : std_logic_vector(15 downto 0);
  signal dds_ramp  : std_logic_vector(15 downto 0);
  signal dds_sqr   : std_logic_vector(15 downto 0);
  signal dds_saw   : std_logic_vector(15 downto 0);
  signal dds_tri   : std_logic_vector(15 downto 0);
  signal dds_tri_pre   : std_logic_vector(15 downto 0);
  signal dds_phase : std_logic_vector(31 downto 0);
  signal dac_data  : std_logic_vector(23 downto 0);

begin

  -- Reset and clock
  clk100 <= not clk100 after 5 ns;
  rst100 <= '0' after 20 ns;
  
  dds_ramp <= dds_phase(31 downto 16);
  dds_sqr  <= x"7FFF" when signed(dds_data) > 0 else x"8000";
  dds_saw  <= dds_ramp xor x"FFFF";
  dds_tri_pre  <= dds_ramp when dds_ramp > x"7FFF" else dds_saw;
  dds_tri  <= std_logic_vector((signed(dds_tri_pre) + x"3FFF") sll 1);
  
  dac_data <= dds_data & x"00";
  
  -- Audio codec
  u_audio_codec: component codec_i2s
  generic map (
    G_MCLK_BCLK_RATIO => 2,
    G_DATA_WIDTH      => 24,
    G_WORDSIZE        => 32
  )
  port map (
    -- input clock domain
    rst         => rst100,
    clk         => clk100,
    dac_data_l  => dac_data,
    dac_data_r  => dac_data,
    dac_latched => open,
    adc_data    => open,
    adc_latched => open,
    -- mclk domain
    mclk_in     => clk_12p288,
    mclk        => open,
    bclk        => open,
    pbdat       => open,
    pblrc       => open,
    recdat      => '1',
    reclrc      => open,
    mute_n      => open
  );
  
  u_dds: dds_audio
  port map (
    aclk                            => clk_0p16,
    s_axis_config_tvalid            => '0', --'1',
    s_axis_config_tdata             => x"000000000b439581",
    m_axis_data_tvalid              => open,
    m_axis_data_tdata               => dds_data,
    m_axis_phase_tvalid             => open,
    m_axis_phase_tdata              => dds_phase
  );
  
  u_mclk_mmcm: clk_wiz_mclk
  port map (
    reset         => rst100,
    clk_in1       => clk100,
    locked        => open,
    mclk_codec    => clk_12p288,
    clk_audio_dds => clk_12p8
  );
  
  u_dds_clk_divider: clkdivider
  generic map (
    G_DIVIDEBY => 80
  )
  port map (
    clk      => clk_12p8,
    reset    => rst_12p8,
    pulseout => clk_0p16
  );
  
  u_rst_12p8_sync: rst_sync
  port map (
    rst_async_in => rst100,
    clk_sync_in  => clk_12p8,
    rst_sync_out => rst_12p8
  );

end Behavioral;
