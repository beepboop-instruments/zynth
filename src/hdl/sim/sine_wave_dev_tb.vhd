----------------------------------------------------------------------------------
-- Company: beepboop
-- Engineer: Tyler Huddleston
-- 
-- Create Date: 02/28/2025 01:13:39 PM
-- Design Name: 
-- Module Name: sine_wave_dev_tb
-- Description: 
--   Testbench for the waveform generator module.
-- 
----------------------------------------------------------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.ALL;
  use IEEE.NUMERIC_STD.ALL;

library xil_defaultlib;
  use xil_defaultlib.synth_pkg.all;
  use xil_defaultlib.music_note_pkg.all;

entity sine_wave_dev_tb is
--  Port ( );
end sine_wave_dev_tb;

architecture Behavioral of sine_wave_dev_tb is
  
  component phase_accumulator is
    generic (
      PHASE_WIDTH : integer := 8 -- 8-bit phase index
    );
    port (
      clk       : in  std_logic;
      rst       : in  std_logic;
      increment : in  unsigned(PHASE_WIDTH-1 downto 0); -- Phase increment
      phase     : out unsigned(PHASE_WIDTH-1 downto 0)  -- Phase output
    );
  end component;
  
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
  
  -- Audio codec
  component codec_i2s is
  generic (
    G_MCLK_BCLK_RATIO : natural := 2;
    G_DATA_WIDTH      : natural := 24;
    G_WORDSIZE        : natural := 32
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
  
  -- MCLK MMCM
    component clk_wiz_mclk is
      Port (
        reset         : in  std_logic;
        clk_in1       : in  std_logic;
        locked        : out std_logic;
        clk_out1     : out std_logic
      );
    end component clk_wiz_mclk;
  
  component waveform_generator is
    generic (
      DATA_WIDTH : natural := 16;
      SIN_LUT_PH : natural := 12
    );
    port (
      clk       : in  std_logic;
      phase     : in  unsigned(DATA_WIDTH-1 downto 0);
      -- pulse width modulation
      pulse_amp : in  unsigned(DATA_WIDTH-1 downto 0);
      pulse_ph  : in  unsigned(DATA_WIDTH-1 downto 0);
      duty      : in  unsigned(DATA_WIDTH-1 downto 0);
      pulse     : out signed(DATA_WIDTH-1 downto 0);
      -- ramp
      ramp_amp  : in  unsigned(DATA_WIDTH-1 downto 0);
      ramp_ph   : in  unsigned(DATA_WIDTH-1 downto 0);
      ramp      : out signed(DATA_WIDTH-1 downto 0);
      -- saw
      saw_amp   : in  unsigned(DATA_WIDTH-1 downto 0);
      saw_ph    : in  unsigned(DATA_WIDTH-1 downto 0);
      saw       : out signed(DATA_WIDTH-1 downto 0);
      -- triangle
      tri_amp   : in  unsigned(DATA_WIDTH-1 downto 0);
      tri_ph    : in  unsigned(DATA_WIDTH-1 downto 0);
      tri       : out signed(DATA_WIDTH-1 downto 0);
      -- sine
      sine_amp  : in  unsigned(DATA_WIDTH-1 downto 0);
      sine_ph   : in  unsigned(DATA_WIDTH-1 downto 0);
      sine      : out signed(DATA_WIDTH-1 downto 0);
      -- mixed output
      mix_out   : out signed(DATA_WIDTH-1 downto 0)
    );
  end component waveform_generator;
  
  signal clk100    : std_logic := '0'; -- 100 MHz
  signal clk1      : std_logic;        -- 1 MHz
  signal rst100    : std_logic := '1';
  signal rst1      : std_logic;
  
  signal mclk_12p88 : std_logic;
  
  signal phases : t_ph_inc_type;
  
  signal sine_data : std_logic_vector(23 downto 0);
  signal sine      : signed(15 downto 0);
  signal mixes  : t_wave_data;

begin

  -- Reset and clock
  clk100 <= not clk100 after 5 ns;
  rst100 <= '0' after 20 ns;
  
  -- Instantiate 128 phase accumulators
  gen_accumulators: for i in 0 to 127 generate
    phase_gen: phase_accumulator
      generic map (
        PHASE_WIDTH => 32
      )
      port map (
        clk       => clk1,
        rst       => rst1,
        increment => ph_inc_lut(i),
        phase     => phases(i)
      );
  
   u_waveform_gen: waveform_generator
    generic map (
      DATA_WIDTH => 16,
      SIN_LUT_PH => 12
    )
    port map (      
      clk      => clk1,
      phase    => phases(i)(31 downto 16),
      -- pulse width modulation
      pulse_amp => x"FFFF",
      pulse_ph  => x"6000",
      duty      => x"4000",
      pulse     => open,
      -- ramp
      ramp_amp => x"0000",
      ramp_ph  => x"0000",
      ramp     => open,
      -- saw
      saw_amp => x"7FFF",
      saw_ph   => x"0000",
      saw      => open,
      -- triangle
      tri_amp => x"0000",
      tri_ph   => x"6000",
      tri      => open,
      -- sine
      sine_amp => x"FFFF",
      sine_ph  => x"0000",
      sine     => open,
      -- mixed output
      mix_out  => mixes(i)
    );
  end generate;
  
  u_dds_clk_divider: clkdivider
  generic map (
    G_DIVIDEBY => 100
  )
  port map (
    clk    => clk100,
    rst    => rst100,
    clkout => clk1,
    rstout => rst1
  );
  
  -- MCLK MMCM
    u_mclk_mmcm: clk_wiz_mclk
      port map (
        reset         => rst100,
        clk_in1       => clk100,
        locked        => open,
        clk_out1     => mclk_12p88
      );
      
  sine <= mixes(69);
  sine_data <= std_logic_vector(sine) & x"00";
  
  -- Audio codec
    u_audio_codec: codec_i2s
    generic map (
      G_MCLK_BCLK_RATIO => 2,
      G_DATA_WIDTH      => 24,
      G_WORDSIZE        => 32
    )
      port map (
        -- input clock domain
        rst         => rst100,
        clk         => clk100,
        dac_data_l  => sine_data,
        dac_data_r  => sine_data,
        dac_latched => open,
        adc_data    => open,
        adc_latched => open,
        -- mclk domain
        mclk_in     => mclk_12p88,
        mclk        => open,
        bclk        => open,
        pbdat       => open,
        pblrc       => open,
        recdat      => '0',
        reclrc      => open,
        mute_n      => open
        );

end Behavioral;
