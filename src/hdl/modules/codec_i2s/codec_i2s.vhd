----------------------------------------------------------------------------------
-- Company: beepboop
-- Engineer: tyler huddleston
-- 
-- Create Date: 08/20/2022
-- Design Name: Codec I2S
-- Module Name: Codec I2S
-- Description: 
--   Formats data to an I2S codec.
-- 
----------------------------------------------------------------------------------


library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity codec_i2s is
  generic (
    G_MCLK_BCLK_RATIO : natural := 2;                            -- mclk to bclk ratio
    G_DATA_WIDTH      : natural := 24;                           -- data width per channel
    G_WORDSIZE        : natural := 32  );                        -- word size per channel
  port (
    rst         : in  std_logic;                                 -- main logic reset
    clk         : in  std_logic;                                 -- main clock
    dac_data_l  : in  std_logic_vector(G_DATA_WIDTH-1 downto 0); -- left DAC data to codec
    dac_data_r  : in  std_logic_vector(G_DATA_WIDTH-1 downto 0); -- right DAC data to codec
    dac_latched : out std_logic;                                 -- DAC data to codec latched
    adc_data    : out std_logic_vector(G_DATA_WIDTH*2-1 downto 0); -- ADC data from codec
    adc_latched : out std_logic;                                 -- ADC data from codec latched
    mclk_in     : in  std_logic;                                 -- codec master clock from fabric
    mclk        : out std_logic;                                 -- codec master clock out
    bclk        : out std_logic;                                 -- codec serial bit clock
    pbdat       : out std_logic;                                 -- codec playback data left
    pblrc       : out std_logic;                                 -- codec playback data left/right select
    recdat      : in  std_logic;                                 -- codec record data
    reclrc      : out std_logic;                                 -- codec record data left/right select
    mute_n      : out std_logic    );                            -- codec mute enable
end codec_i2s;

architecture Behavioral of codec_i2s is

  component rst_sync is
  port (
    rst_async_in : in  std_logic;
    clk_sync_in  : in  std_logic;
    rst_sync_out : out std_logic
  );
  end component rst_sync;

  component clkdivider is
    generic (
      G_DIVIDEBY : natural := 2
    );
    port (
      clk    : in std_logic;
      rst    : in std_logic;
      clkout : out std_logic;
      rstout : out std_logic
    );
  end component clkdivider;
  
  signal bclk_int  : std_logic;
  signal lrc_int   : std_logic;
  signal lrc_int_q : std_logic;
  signal rst_mclk  : std_logic;
  signal rst_bclk  : std_logic;
  
  signal data_cnt    : natural range 0 to G_WORDSIZE-1;
  signal data_out    : std_logic_vector(G_WORDSIZE-1 downto 0);
  signal data_pad    : std_logic_vector(G_WORDSIZE-G_DATA_WIDTH-2 downto 0);
  signal data_sr     : std_logic_vector(G_WORDSIZE-1 downto 0);
  
  signal data_l_latched : std_logic_vector(G_DATA_WIDTH-1 downto 0);
  signal data_r_latched : std_logic_vector(G_DATA_WIDTH-1 downto 0);
  
  signal dout_latched_d, dout_latched_q : std_logic;
  
begin

--------------------- output assignments ---------------------

  mclk        <= mclk_in;
  bclk        <= bclk_int;
  pblrc       <= lrc_int;
  reclrc      <= lrc_int;
  pbdat       <= data_sr(G_WORDSIZE-1);
  mute_n      <= not rst;
  dac_latched <= dout_latched_q;
  adc_data    <= (others => '0');
  adc_latched <= '0';
  
--------------------- logic assignments ---------------------

  data_pad <= (others => '0');
  data_out <= '0' & data_l_latched & data_pad when lrc_int = '0' else '0' & data_r_latched & data_pad;
  dout_latched_d <= '1' when data_cnt = 0 else '0';
  
  data_l_latched <= dac_data_l when dout_latched_q = '1';
  data_r_latched <= dac_data_r when dout_latched_q = '1';
  
-------------------- synchonrous logic ----------------------

  s_dout_latched: process(clk, rst)
  begin
    if rst = '1' then
      dout_latched_q <= '0';
      lrc_int_q      <= '1';
    elsif rising_edge(clk) then
      lrc_int_q      <= lrc_int;
      dout_latched_q <= dout_latched_d and lrc_int and not(lrc_int_q);
    end if;
  end process s_dout_latched;

  s_i2s: process(clk, rst_bclk, bclk_int)
  begin
    if rst_bclk = '1' then
      data_cnt  <= G_WORDSIZE-1;
      lrc_int   <= '0';
      data_sr   <= (others => '0');
    elsif falling_edge(bclk_int) then
      if data_cnt < G_WORDSIZE-1 then
        data_cnt  <= data_cnt + 1;
        data_sr   <= data_sr(G_WORDSIZE-2 downto 0) & data_sr(G_WORDSIZE-1);
      else
        data_cnt  <= 0;
        lrc_int   <= not(lrc_int);
        data_sr   <= data_out;
      end if;
    end if;
  end process s_i2s;

------------------- component instantiation -------------------

  u_mclk_rst_sync: rst_sync
  port map (
    rst_async_in => rst,
    clk_sync_in  => mclk_in,
    rst_sync_out => rst_mclk
  );

  -- BCLK from MCLK
  u_bclk_div: clkdivider
  generic map (
    G_DIVIDEBY => G_MCLK_BCLK_RATIO
  )
  port map (
    clk      => mclk_in,
    rst      => rst_mclk,
    clkout   => bclk_int,
    rstout   => rst_bclk
  );
    
end Behavioral;
