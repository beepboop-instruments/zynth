----------------------------------------------------------------------------------
-- Company: beepboop
-- Engineer: Tyler Huddleston
-- 
-- Create Date: 03/08/2025
-- Design Name: Synthesizer Engine
-- Module Name: Synthesizer Engine Testbench
-- Description: 
--   Testbench for the Synthesizer Engine simulation.
-- 
----------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library xil_defaultlib;
  use xil_defaultlib.synth_pkg.all;
  use xil_defaultlib.music_note_pkg.all;

entity synth_engine_tb is
end synth_engine_tb;

architecture tb of synth_engine_tb is

  constant AXI_DATA_WIDTH : integer := 32;
  constant AXI_ADDR_WIDTH : integer := 31;

  -- AXI signals
  signal clk      : std_logic := '0';
  signal rst      : std_logic := '1';
  signal rst_n    : std_logic := '0';

  signal clk12p288 : std_logic;
  signal rst12p288 : std_logic := '1';

  signal awaddr   : std_logic_vector(AXI_ADDR_WIDTH-1 downto 0);
  signal awvalid  : std_logic;
  signal awready  : std_logic;

  signal wdata    : std_logic_vector(AXI_DATA_WIDTH-1 downto 0);
  signal wstrb    : std_logic_vector(3 downto 0);
  signal wvalid   : std_logic;
  signal wready   : std_logic;

  signal bresp    : std_logic_vector(1 downto 0);
  signal bvalid   : std_logic;
  signal bready   : std_logic;

  signal araddr   : std_logic_vector(AXI_ADDR_WIDTH-1 downto 0);
  signal arvalid  : std_logic;
  signal arready  : std_logic;

  signal rdata    : std_logic_vector(AXI_DATA_WIDTH-1 downto 0);
  signal rresp    : std_logic_vector(1 downto 0);
  signal rvalid   : std_logic;
  signal rready   : std_logic;

  -- Clock process
  constant clk_period  : time := 10 ns;
  constant clk_period2 : time := 20 ns;

  constant synth_clk_period : time := 82 ns;

  -- MCLK MMCM
  component clk_wiz_mclk is
    port (
      reset         : in  std_logic;
      clk_in1       : in  std_logic;
      locked        : out std_logic;
      clk_out1      : out std_logic
    );
  end component clk_wiz_mclk;

  component rst_sync is
    port (
      rst_async_in : in  std_logic;
      clk_sync_in  : in  std_logic;
      rst_sync_out : out std_logic
    );
  end component rst_sync;

  -- DUT Component (Assuming entity is named axi_slave)
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
      s_axi_awaddr   : in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
      s_axi_awprot   : in std_logic_vector(2 downto 0);
      s_axi_awvalid  : in std_logic;
      s_axi_awready  : out std_logic;
      s_axi_wdata    : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
      s_axi_wstrb    : in  std_logic_vector(3 downto 0);
      s_axi_wvalid   : in  std_logic;
      s_axi_wready   : out std_logic;
      s_axi_bresp    : out std_logic_vector(1 downto 0);
      s_axi_bvalid   : out std_logic;
      s_axi_bready   : in  std_logic;
      s_axi_araddr   : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
      s_axi_arprot   : in  std_logic_vector(2 downto 0);
      s_axi_arvalid  : in  std_logic;
      s_axi_arready  : out std_logic;
      s_axi_rdata    : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
      s_axi_rresp    : out std_logic_vector(1 downto 0);
      s_axi_rvalid   : out std_logic;
      s_axi_rready   : in  std_logic;

      -- Digital audio output
      audio_out     : out std_logic_vector(OUT_DATA_WIDTH-1 downto 0)
    );
  end component synth_engine;
    
begin

  rst_n <= not(rst);

  -- MCLK MMCM
  u_mclk_mmcm: clk_wiz_mclk
  port map (
    reset         => rst,
    clk_in1       => clk,
    locked        => open,
    clk_out1      => clk12p288
  );

  u_rst12p288_sync: rst_sync
  port map (
    rst_async_in => rst,
    clk_sync_in  => clk12p288,
    rst_sync_out => rst12p288
  );

  -- Instantiate the DUT
  uut: synth_engine
    generic map (
      C_S_AXI_DATA_WIDTH  => AXI_DATA_WIDTH,
      C_S_AXI_ADDR_WIDTH  => AXI_ADDR_WIDTH,
      DATA_WIDTH     => WIDTH_WAVE_DATA,
      OUT_DATA_WIDTH => WIDTH_WAVE_DATA+8
    )
    port map (
      -- AXI control interface
      clk           => clk12p288,
      rst           => rst12p288,
      s_axi_aclk    => clk,
      s_axi_aresetn => rst_n,
      s_axi_awaddr  => awaddr,
      s_axi_awprot  => "000",
      s_axi_awvalid  => awvalid,
      s_axi_awready  => awready,
      s_axi_wdata    => wdata,
      s_axi_wstrb    => wstrb,
      s_axi_wvalid  => wvalid,
      s_axi_wready  => wready,
      s_axi_bresp    => bresp,
      s_axi_bvalid  => bvalid,
      s_axi_bready  => bready,
      s_axi_araddr  => araddr,
      s_axi_arprot  => "000",
      s_axi_arvalid  => arvalid,
      s_axi_arready  => arready,
      s_axi_rdata    => rdata,
      s_axi_rresp    => rresp,
      s_axi_rvalid  => rvalid,
      s_axi_rready  => rready,

      -- Digital audio output
      audio_out     => open
    );
  
  -- Clock Process
  clk_process : process
  begin
      while true loop
          clk <= '0';
          wait for clk_period / 2;
          clk <= '1';
          wait for clk_period / 2;
      end loop;
  end process;
  
  -- Stimulus Process
  stimulus : process
  
    procedure axi_write(
      address : in std_logic_vector(AXI_ADDR_WIDTH-1 downto 0);
      data    : in std_logic_vector(AXI_DATA_WIDTH-1 downto 0)
    ) is
    begin
      awaddr  <= address;
      awvalid <= '1';
      wdata   <= data;
      wstrb   <= (others => '1');
      wvalid  <= '1';
      bready  <= '1';
    
      -- Wait until both address and data handshakes complete
      while (awready /= '1' or wready /= '1') loop
        wait until rising_edge(clk);
      end loop;
    
      -- Deassert write signals after handshake
      awvalid <= '0';
      wvalid  <= '0';
    
      -- Wait for write response
      wait until rising_edge(clk);
      while bvalid /= '1' loop
        wait until rising_edge(clk);
      end loop;
    
      -- Accept response
      bready <= '0';
    end procedure;
    
    procedure axi_read(
      address : in std_logic_vector(AXI_ADDR_WIDTH-1 downto 0)
    ) is
    begin
      araddr  <= address;
      arvalid <= '1';
      rready  <= '1';
    
      -- Wait for read address handshake
      while arready /= '1' loop
        wait until rising_edge(clk);
      end loop;
    
      -- Deassert address after accepted
      arvalid <= '0';
    
      -- Wait for read data valid
      while rvalid /= '1' loop
        wait until rising_edge(clk);
      end loop;
    
      -- Deassert ready after one cycle (assuming single-beat read)
      wait until rising_edge(clk);
      rready <= '0';
    end procedure;
    
    
  begin
    -- Reset
    rst      <= '1';
    awaddr  <= "000" & x"0000000";
    awvalid <= '0';
    wdata   <= x"00000000";
    wstrb   <= "0000";
    wvalid  <= '0';
    bready  <= '0';
    araddr  <= "000" & x"0000000";
    arvalid <= '0';
    rready  <= '0';
    wait for clk_period2;
    rst     <= '0';
    wait for clk_period2;

    wait for clk_period * 1024;
    
    -- Write to register 0
    axi_write("000" & x"0000000", x"00000018");
    -- Read from register 0
    axi_read("000" & x"0000000");
    -- Write to note 69 (A4) reg
    axi_write("000" & x"0000114", x"0000007F");
    -- Write to note 127 reg
    axi_write("000" & x"00001FC", x"0000007F");
    -- Write to output amplitude register
    axi_write("000" & x"0000220", x"00000008");
    axi_write("000" & x"0000224", x"0000003F");
    -- Write to pulse reg
    axi_write("000" & x"0000200", x"00004000");
    axi_write("000" & x"0000204", x"00000000");
    -- Write to ramp reg
    axi_write("000" & x"0000208", x"00000000");
    -- Write to saw reg
    axi_write("000" & x"000020C", x"00000000");
    -- Write to tri reg
    axi_write("000" & x"0000210", x"00000000");
    -- Write to sin reg
    axi_write("000" & x"0000214", x"0000007F");
    -- Write to wrapback reg
    axi_write("000" & x"00003FC", x"ABCD1234");
    -- Read from wrapback reg
    axi_read("000" & x"00003FC");
    -- Read from rev reg
    axi_read("000" & x"00003E0");
    -- Read from date reg
    axi_read("000" & x"00003E4");
    -- Read from phase increment table note 117
    axi_read("000" & x"00005D4");
    -- Read from phase increment table note 119
    axi_read("000" & x"00005DC");
    -- Write to attack regs
    axi_write("000" & x"0000280", x"00000080");
    axi_write("000" & x"0000284", x"00000060");
    -- Write to decay regs
    axi_write("000" & x"00002A0", x"00000100");
    -- Write to sustain regs
    axi_write("000" & x"00002C0", x"00008000");
    -- Write to release regs
    axi_write("000" & x"00002E0", x"00000200");

    wait for 6e6 ns;
    -- Write to note 127 reg
    axi_write("000" & x"00001FC", x"00000000");

    -- End Simulation
    wait for clk_period2;
    report "Testbench completed." severity note;
  wait;
end process;

end tb;
