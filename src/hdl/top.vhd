----------------------------------------------------------------------------------
-- Company: beepboopinstruments
-- Engineer: tyler huddleston
-- 
-- Create Date: 08/14/2022 07:30:11 PM
-- Design Name: zynth
-- Module Name: top
-- Description: 
-- 
-- 
----------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library xil_defaultlib;
  use xil_defaultlib.synth_pkg.all;
  use xil_defaultlib.music_note_pkg.all;

entity top is
  generic (
    G_AUDIO_WORD_SIZE : natural := 24  );
  port (
    DDR_addr : inout STD_LOGIC_VECTOR ( 14 downto 0 );
    DDR_ba : inout STD_LOGIC_VECTOR ( 2 downto 0 );
    DDR_cas_n : inout STD_LOGIC;
    DDR_ck_n : inout STD_LOGIC;
    DDR_ck_p : inout STD_LOGIC;
    DDR_cke : inout STD_LOGIC;
    DDR_cs_n : inout STD_LOGIC;
    DDR_dm : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    DDR_dq : inout STD_LOGIC_VECTOR ( 31 downto 0 );
    DDR_dqs_n : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    DDR_dqs_p : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    DDR_odt : inout STD_LOGIC;
    DDR_ras_n : inout STD_LOGIC;
    DDR_reset_n : inout STD_LOGIC;
    DDR_we_n : inout STD_LOGIC;
    FIXED_IO_ddr_vrn : inout STD_LOGIC;
    FIXED_IO_ddr_vrp : inout STD_LOGIC;
    FIXED_IO_mio : inout STD_LOGIC_VECTOR ( 53 downto 0 );
    FIXED_IO_ps_clk : inout STD_LOGIC;
    FIXED_IO_ps_porb : inout STD_LOGIC;
    FIXED_IO_ps_srstb : inout STD_LOGIC;
    btn_tri_io : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    led : out STD_LOGIC_VECTOR ( 3 downto 0 );
    -- audio codec pins
    ac_scl    : inout STD_LOGIC;
    ac_sda    : inout STD_LOGIC;
    ac_bclk   : out   STD_LOGIC;
    ac_mclk   : out   STD_LOGIC;
    ac_muten  : out   STD_LOGIC;
    ac_pbdat  : out   STD_LOGIC;
    ac_pblrc  : out   STD_LOGIC;
    ac_recdat : in    STD_LOGIC;
    ac_reclrc : out   STD_LOGIC
  );
end top;
  
  architecture STRUCTURE of top is
    component ps is
      port (
        DDR_cas_n : inout STD_LOGIC;
        DDR_cke : inout STD_LOGIC;
        DDR_ck_n : inout STD_LOGIC;
        DDR_ck_p : inout STD_LOGIC;
        DDR_cs_n : inout STD_LOGIC;
        DDR_reset_n : inout STD_LOGIC;
        DDR_odt : inout STD_LOGIC;
        DDR_ras_n : inout STD_LOGIC;
        DDR_we_n : inout STD_LOGIC;
        DDR_ba : inout STD_LOGIC_VECTOR ( 2 downto 0 );
        DDR_addr : inout STD_LOGIC_VECTOR ( 14 downto 0 );
        DDR_dm : inout STD_LOGIC_VECTOR ( 3 downto 0 );
        DDR_dq : inout STD_LOGIC_VECTOR ( 31 downto 0 );
        DDR_dqs_n : inout STD_LOGIC_VECTOR ( 3 downto 0 );
        DDR_dqs_p : inout STD_LOGIC_VECTOR ( 3 downto 0 );
        FIXED_IO_mio : inout STD_LOGIC_VECTOR ( 53 downto 0 );
        FIXED_IO_ddr_vrn : inout STD_LOGIC;
        FIXED_IO_ddr_vrp : inout STD_LOGIC;
        FIXED_IO_ps_srstb : inout STD_LOGIC;
        FIXED_IO_ps_clk : inout STD_LOGIC;
        FIXED_IO_ps_porb : inout STD_LOGIC;
        leds_4bits_tri_o : out STD_LOGIC_VECTOR ( 3 downto 0 );
        btn_tri_i : in STD_LOGIC_VECTOR ( 3 downto 0 );
        iic_scl_i : in STD_LOGIC;
        iic_scl_o : out STD_LOGIC;
        iic_scl_t : out STD_LOGIC;
        iic_sda_i : in STD_LOGIC;
        iic_sda_o : out STD_LOGIC;
        iic_sda_t : out STD_LOGIC;
        M03_AXI_0_awaddr : out STD_LOGIC_VECTOR ( 30 downto 0 );
        M03_AXI_0_awprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
        M03_AXI_0_awvalid : out STD_LOGIC;
        M03_AXI_0_awready : in STD_LOGIC;
        M03_AXI_0_wdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
        M03_AXI_0_wstrb : out STD_LOGIC_VECTOR ( 3 downto 0 );
        M03_AXI_0_wvalid : out STD_LOGIC;
        M03_AXI_0_wready : in STD_LOGIC;
        M03_AXI_0_bresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
        M03_AXI_0_bvalid : in STD_LOGIC;
        M03_AXI_0_bready : out STD_LOGIC;
        M03_AXI_0_araddr : out STD_LOGIC_VECTOR ( 30 downto 0 );
        M03_AXI_0_arprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
        M03_AXI_0_arvalid : out STD_LOGIC;
        M03_AXI_0_arready : in STD_LOGIC;
        M03_AXI_0_rdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
        M03_AXI_0_rresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
        M03_AXI_0_rvalid : in STD_LOGIC;
        M03_AXI_0_rready : out STD_LOGIC;
        FCLK_CLK0 : out STD_LOGIC;
        FCLK_RESET0_N : out STD_LOGIC;
        fab_clk        : in std_logic
      );
      end component ps;

    component IOBUF is
      port (
        I : in STD_LOGIC;
        O : out STD_LOGIC;
        T : in STD_LOGIC;
        IO : inout STD_LOGIC
      );
    end component IOBUF;
    
    -- MCLK MMCM
    component clk_wiz_mclk is
      port (
        reset         : in  std_logic;
        clk_in1       : in  std_logic;
        locked        : out std_logic;
        clk_out1     : out std_logic
      );
    end component clk_wiz_mclk;

    component synth_engine is
      generic (
        -- AXI parameters
        C_S_AXI_DATA_WIDTH  : integer  := 32;
        C_S_AXI_ADDR_WIDTH  : integer  := 31;
        -- waveform parameters
        DATA_WIDTH     : natural := WIDTH_WAVE_DATA;
        OUT_DATA_WIDTH : natural := WIDTH_WAVE_DATA+8
      );
      port (
        -- clock and reset
        clk           : in std_logic;
        rst           : in std_logic;
  
        -- AXI control interface
        s_axi_aclk    : in  std_logic;
        s_axi_aresetn : in  std_logic;
        s_axi_awaddr  : in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
        s_axi_awprot  : in std_logic_vector(2 downto 0);
        s_axi_awvalid : in std_logic;
        s_axi_awready : out std_logic;
        s_axi_wdata   : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        s_axi_wstrb   : in  std_logic_vector(3 downto 0);
        s_axi_wvalid  : in  std_logic;
        s_axi_wready  : out std_logic;
        s_axi_bresp   : out std_logic_vector(1 downto 0);
        s_axi_bvalid  : out std_logic;
        s_axi_bready  : in  std_logic;
        s_axi_araddr  : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
        s_axi_arprot  : in  std_logic_vector(2 downto 0);
        s_axi_arvalid : in  std_logic;
        s_axi_arready : out std_logic;
        s_axi_rdata   : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        s_axi_rresp   : out std_logic_vector(1 downto 0);
        s_axi_rvalid  : out std_logic;
        s_axi_rready  : in  std_logic;
  
        -- Digital audio output
        audio_out     : out std_logic_vector(OUT_DATA_WIDTH-1 downto 0)
      );
    end component synth_engine;
      
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
        mute_n      : out std_logic                                  -- codec mute enable
      );
    end component codec_i2s;

    component rst_sync is
      port (
        rst_async_in : in  std_logic;
        clk_sync_in  : in  std_logic;
        rst_sync_out : out std_logic
      );
    end component rst_sync;
    
    -- Clocks and resets
    signal clk100  : std_logic;
    signal rst100   : std_logic;
    signal rst100_n : std_logic;
    
    signal clk12p288   : std_logic;
    signal rst12p288   : std_logic;
    signal rst12p288_n : std_logic;
    
    signal audio_data : std_logic_vector(23 downto 0);
    
    signal btn_tri_i_0 : STD_LOGIC_VECTOR ( 0 to 0 );
    signal btn_tri_i_1 : STD_LOGIC_VECTOR ( 1 to 1 );
    signal btn_tri_i_2 : STD_LOGIC_VECTOR ( 2 to 2 );
    signal btn_tri_i_3 : STD_LOGIC_VECTOR ( 3 to 3 );
    signal iic_scl_i : STD_LOGIC;
    signal iic_scl_o : STD_LOGIC;
    signal iic_scl_t : STD_LOGIC;
    signal iic_sda_i : STD_LOGIC;
    signal iic_sda_o : STD_LOGIC;
    signal iic_sda_t : STD_LOGIC;

    -- AXI bus
    signal awaddr   : std_logic_vector(30 downto 0);
    signal awvalid  : std_logic;
    signal awready  : std_logic;
    signal awprot   : std_logic_vector(2 downto 0);
  
    signal wdata    : std_logic_vector(31 downto 0);
    signal wstrb    : std_logic_vector(3 downto 0);
    signal wvalid   : std_logic;
    signal wready   : std_logic;
  
    signal bresp    : std_logic_vector(1 downto 0);
    signal bvalid   : std_logic;
    signal bready   : std_logic;
  
    signal araddr   : std_logic_vector(30 downto 0);
    signal arvalid  : std_logic;
    signal arready  : std_logic;
    signal arprot   : std_logic_vector(2 downto 0);
  
    signal rdata    : std_logic_vector(31 downto 0);
    signal rresp    : std_logic_vector(1 downto 0);
    signal rvalid   : std_logic;
    signal rready   : std_logic;
      
  begin
  
  rst100      <= not(rst100_n);
  rst12p288_n <= not(rst12p288);
  
  ps_i: component ps
    port map (
      DDR_addr(14 downto 0) => DDR_addr(14 downto 0),
      DDR_ba(2 downto 0) => DDR_ba(2 downto 0),
      DDR_cas_n => DDR_cas_n,
      DDR_ck_n => DDR_ck_n,
      DDR_ck_p => DDR_ck_p,
      DDR_cke => DDR_cke,
      DDR_cs_n => DDR_cs_n,
      DDR_dm(3 downto 0) => DDR_dm(3 downto 0),
      DDR_dq(31 downto 0) => DDR_dq(31 downto 0),
      DDR_dqs_n(3 downto 0) => DDR_dqs_n(3 downto 0),
      DDR_dqs_p(3 downto 0) => DDR_dqs_p(3 downto 0),
      DDR_odt => DDR_odt,
      DDR_ras_n => DDR_ras_n,
      DDR_reset_n => DDR_reset_n,
      DDR_we_n => DDR_we_n,
      FCLK_CLK0 => clk100,
      FCLK_RESET0_N => rst100_n,
      FIXED_IO_ddr_vrn => FIXED_IO_ddr_vrn,
      FIXED_IO_ddr_vrp => FIXED_IO_ddr_vrp,
      FIXED_IO_mio(53 downto 0) => FIXED_IO_mio(53 downto 0),
      FIXED_IO_ps_clk => FIXED_IO_ps_clk,
      FIXED_IO_ps_porb => FIXED_IO_ps_porb,
      FIXED_IO_ps_srstb => FIXED_IO_ps_srstb,
      btn_tri_i(3) => btn_tri_i_3(3),
      btn_tri_i(2) => btn_tri_i_2(2),
      btn_tri_i(1) => btn_tri_i_1(1),
      btn_tri_i(0) => btn_tri_i_0(0),
      iic_scl_i => iic_scl_i,
      iic_scl_o => iic_scl_o,
      iic_scl_t => iic_scl_t,
      iic_sda_i => iic_sda_i,
      iic_sda_o => iic_sda_o,
      iic_sda_t => iic_sda_t,
      leds_4bits_tri_o(3 downto 0) => led(3 downto 0),
      M03_AXI_0_awaddr  => awaddr,
      M03_AXI_0_awprot  => awprot,
      M03_AXI_0_awvalid => awvalid,
      M03_AXI_0_awready => awready,
      M03_AXI_0_wdata   => wdata,
      M03_AXI_0_wstrb   => wstrb,
      M03_AXI_0_wvalid  => wvalid,
      M03_AXI_0_wready  => wready,
      M03_AXI_0_bresp   => bresp,
      M03_AXI_0_bvalid  => bvalid,
      M03_AXI_0_bready  => bready,
      M03_AXI_0_araddr  => araddr,
      M03_AXI_0_arprot  => arprot,
      M03_AXI_0_arvalid => arvalid,
      M03_AXI_0_arready => arready,
      M03_AXI_0_rdata   => rdata,
      M03_AXI_0_rresp   => rresp,
      M03_AXI_0_rvalid  => rvalid,
      M03_AXI_0_rready  => rready,
      fab_clk           => clk12p288
    );

  iic_scl_iobuf: component IOBUF
    port map (
      I => iic_scl_o,
      IO => ac_scl,
      O => iic_scl_i,
      T => iic_scl_t
    );

  iic_sda_iobuf: component IOBUF
    port map (
      I => iic_sda_o,
      IO => ac_sda,
      O => iic_sda_i,
      T => iic_sda_t
    );
      
  -- synth engine
  u_synth_engine: synth_engine
    generic map (
      -- AXI parameters
      C_S_AXI_DATA_WIDTH => 32,
      C_S_AXI_ADDR_WIDTH => 31,
      -- waveform parameters
      DATA_WIDTH     => WIDTH_WAVE_DATA,
      OUT_DATA_WIDTH => WIDTH_WAVE_DATA+8
    )
    port map (
      -- AXI control interface
      clk           => clk12p288,
      rst           => rst12p288,
      s_axi_aclk    => clk12p288,
      s_axi_aresetn => rst12p288_n,
      s_axi_awaddr  => awaddr,
      s_axi_awprot  => awprot,
      s_axi_awvalid => awvalid,
      s_axi_awready => awready,
      s_axi_wdata   => wdata,
      s_axi_wstrb   => wstrb,
      s_axi_wvalid  => wvalid,
      s_axi_wready  => wready,
      s_axi_bresp   => bresp,
      s_axi_bvalid  => bvalid,
      s_axi_bready  => bready,
      s_axi_araddr  => araddr,
      s_axi_arprot  => awprot,
      s_axi_arvalid => arvalid,
      s_axi_arready => arready,
      s_axi_rdata   => rdata,
      s_axi_rresp   => rresp,
      s_axi_rvalid  => rvalid,
      s_axi_rready  => rready,

      -- Digital audio output
      audio_out     => audio_data
    );
    
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
      dac_data_l  => audio_data,
      dac_data_r  => audio_data,
      dac_latched => open,
      adc_data    => open,
      adc_latched => open,
      -- mclk domain
      mclk_in     => clk12p288,
      mclk        => ac_mclk,
      bclk        => ac_bclk,
      pbdat       => ac_pbdat,
      pblrc       => ac_pblrc,
      recdat      => ac_recdat,
      reclrc      => ac_reclrc,
      mute_n      => ac_muten
    );
        
  -- MCLK MMCM
  u_mclk_mmcm: clk_wiz_mclk
    port map (
      reset         => rst100,
      clk_in1       => clk100,
      locked        => open,
      clk_out1     => clk12p288
    );
    
    u_rst12p288_sync: rst_sync
    port map (
      rst_async_in => rst100,
      clk_sync_in  => clk12p288,
      rst_sync_out => rst12p288
    );

end STRUCTURE;
