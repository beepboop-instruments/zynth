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
  port (
    clk_tb        : out std_logic;
    rst_tb        : out std_logic;
    audio_out     : out std_logic_vector(WIDTH_WAVE_DATA+7 downto 0)
  );
end synth_engine_tb;

architecture tb of synth_engine_tb is

  constant AXI_DATA_WIDTH : integer := 32;
  constant AXI_ADDR_WIDTH : integer := 31;

  -- AXI signals
  signal clk      : std_logic := '0';
  signal rst      : std_logic := '1';
  signal rst_n    : std_logic := '0';

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
  constant clk_period  : time := 40 ns;
  constant clk_period2 : time := 80 ns;

  signal data_latched: std_logic := '0';
  constant strobe_cycles : integer := 260;
  signal counter : integer range 0 to strobe_cycles := 0;
  
  -- synth controls
  signal phase_incs   : t_ph_inc_lut;
  signal note_amps    : t_note_amp;
  signal wfrm_amps    : t_wfrm_amp;
  signal wfrm_phs     : t_wfrm_ph;
  signal pulse_width  : unsigned(WIDTH_PULSE_WIDTH-1 downto 0);
  signal adsr_attack  : unsigned(WIDTH_ADSR_CC-1 downto 0);
  signal adsr_decay   : unsigned(WIDTH_ADSR_CC-1 downto 0);
  signal adsr_sustain : unsigned(WIDTH_ADSR_CC-1 downto 0);
  signal adsr_release : unsigned(WIDTH_ADSR_CC-1 downto 0);
  signal out_amp      : unsigned(WIDTH_OUT_GAIN-1 downto 0);
  signal out_shift    : unsigned(WIDTH_OUT_SHIFT-1 downto 0);
  
  component synth_axi_ctrl is
    generic (
      -- AXI parameters
      C_S_AXI_DATA_WIDTH  : integer  := 32;
      C_S_AXI_ADDR_WIDTH  : integer  := 31
    );
    port (
      -- user clock domain
      clk                : in  std_logic;
      rst                : in  std_logic;
      -- synth controls out
      note_amps          : out t_note_amp;
      ph_inc_table       : out t_ph_inc_lut;
      wfrm_amps          : out t_wfrm_amp;
      wfrm_phs           : out t_wfrm_ph;
      out_amp            : out unsigned(WIDTH_OUT_GAIN-1 downto 0);
      out_shift          : out unsigned(WIDTH_OUT_SHIFT-1 downto 0);
      pulse_width        : out unsigned(WIDTH_PULSE_WIDTH-1 downto 0);
      adsr_attack_amt    : out unsigned(WIDTH_ADSR_CC-1 downto 0);
      adsr_decay_amt     : out unsigned(WIDTH_ADSR_CC-1 downto 0);
      adsr_sustain_amt   : out unsigned(WIDTH_ADSR_CC-1 downto 0);
      adsr_release_amt   : out unsigned(WIDTH_ADSR_CC-1 downto 0);
      -- compressor controls
      comp_attack_amt    : out integer;
      comp_release_amt   : out integer;
      comp_threshold     : out unsigned(WIDTH_WAVE_DATA-1 downto 0);
      comp_knee_width    : out unsigned(WIDTH_WAVE_DATA-1 downto 0);
      comp_knee_slope    : out unsigned(WIDTH_WAVE_GAIN-1 downto 0);

      -- AXI control interface
      s_axi_aclk     : in  std_logic;
      s_axi_aresetn  : in  std_logic;
      s_axi_awaddr   : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
      s_axi_awprot   : in  std_logic_vector(2 downto 0);
      s_axi_awvalid  : in  std_logic;
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
      s_axi_rready   : in  std_logic
    );
  end component synth_axi_ctrl;
    
  -- DUT Component (Assuming entity is named axi_slave)
  component synth_engine is
    generic (
      -- synth control parameters
      PHASE_WIDTH     : integer := WIDTH_PH_DATA;
      NOTE_GAIN_WIDTH : integer := WIDTH_NOTE_GAIN;
      SIN_LUT_PH      : natural := 12;
      ADSR_WIDTH      : natural := WIDTH_ADSR_CC;
      ACC_WIDTH       : natural := WIDTH_ADSR_COUNT;
      -- waveform parameters
      DATA_WIDTH      : natural := WIDTH_WAVE_DATA;
      OUT_DATA_WIDTH  : natural := WIDTH_WAVE_DATA+8
    );
    port (
      -- clock and reset
      clk           : in std_logic;
      rst           : in std_logic;
      -- state machine in
      data_latched  : in  std_logic;
      -- synth controls
      phase_incs    : in  t_ph_inc_lut;
      note_amps     : in  t_note_amp;
      wfrm_amps     : in  t_wfrm_amp;
      wfrm_phs      : in  t_wfrm_ph;
      pulse_width   : in  unsigned(WIDTH_PULSE_WIDTH-1 downto 0);
      attack_amt    : in  unsigned(ADSR_WIDTH-1 downto 0);
      decay_amt     : in  unsigned(ADSR_WIDTH-1 downto 0);
      sustain_amt   : in  unsigned(ADSR_WIDTH-1 downto 0);
      release_amt   : in  unsigned(ADSR_WIDTH-1 downto 0);
      out_amp       : in  unsigned(WIDTH_OUT_GAIN-1 downto 0);
      out_shift     : in  unsigned(WIDTH_OUT_SHIFT-1 downto 0);
      -- Digital audio output
      audio_out     : out std_logic_vector(OUT_DATA_WIDTH-1 downto 0)
    );
  end component synth_engine;
    
begin

  -- assign outputs
  clk_tb <= clk;
  rst_tb <= rst;

  rst_n <= not(rst);

  -- Strobe Generator
  strobe_process : process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        counter <= 0;
        data_latched <= '0';
      else
        if counter = strobe_cycles - 1 then
          data_latched <= '1';
          counter <= 0;
        else
          data_latched <= '0';
          counter <= counter + 1;
        end if;
      end if;
    end if;
  end process;
  
  u_synth_axi_ctrl: synth_axi_ctrl
    generic map (
      -- Width of S_AXI data bus
      C_S_AXI_DATA_WIDTH => 32,
      -- Width of S_AXI address bus
      C_S_AXI_ADDR_WIDTH => 31
    )
    port map (
      -- user clock domain
      clk              => clk,
      rst              => rst,
      -- synth controls out
      note_amps        => note_amps,
      ph_inc_table     => phase_incs,
      wfrm_amps        => wfrm_amps,
      wfrm_phs         => wfrm_phs,
      out_amp          => out_amp,
      out_shift        => out_shift,
      pulse_width      => pulse_width,
      adsr_attack_amt  => adsr_attack,
      adsr_decay_amt   => adsr_decay,
      adsr_sustain_amt => adsr_sustain,
      adsr_release_amt => adsr_release,
      -- compressor controls
      comp_attack_amt  => open,
      comp_release_amt => open,
      comp_threshold   => open,
      comp_knee_width  => open,
      comp_knee_slope  => open,
      -- AXI control interface
      s_axi_aclk       => clk,
      s_axi_aresetn    => rst_n,
      s_axi_awaddr     => awaddr,
      s_axi_awprot     => "000",
      s_axi_awvalid    => awvalid,
      s_axi_awready    => awready,
      s_axi_wdata      => wdata,
      s_axi_wstrb      => wstrb,
      s_axi_wvalid     => wvalid,
      s_axi_wready     => wready,
      s_axi_bresp      => bresp,
      s_axi_bvalid     => bvalid,
      s_axi_bready     => bready,
      s_axi_araddr     => araddr,
      s_axi_arprot     => "000",
      s_axi_arvalid    => arvalid,
      s_axi_arready    => arready,
      s_axi_rdata      => rdata,
      s_axi_rresp      => rresp,
      s_axi_rvalid     => rvalid,
      s_axi_rready     => rready
    );

  -- Instantiate the DUT
  u_synth_engine: synth_engine
    generic map (
      -- synth control parameters
      PHASE_WIDTH     => WIDTH_PH_DATA,
      NOTE_GAIN_WIDTH => WIDTH_NOTE_GAIN,
      SIN_LUT_PH      => 12,
      ADSR_WIDTH      => WIDTH_ADSR_CC,
      ACC_WIDTH       => WIDTH_ADSR_COUNT,
      -- waveform parameters
      DATA_WIDTH      => WIDTH_WAVE_DATA,
      OUT_DATA_WIDTH  => WIDTH_WAVE_DATA+8
    )
    port map (
      -- AXI control interface
      clk           => clk,
      rst           => rst,
      -- state machine in
      data_latched  => data_latched,
      -- synth controls in
      note_amps     => note_amps,
      phase_incs    => phase_incs,
      wfrm_amps     => wfrm_amps,
      wfrm_phs      => wfrm_phs,
      out_amp       => out_amp,
      out_shift     => out_shift,
      pulse_width   => pulse_width,
      attack_amt    => adsr_attack,
      decay_amt     => adsr_decay,
      sustain_amt   => adsr_sustain,
      release_amt   => adsr_release,
      -- Digital audio output
      audio_out     => audio_out
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
      data : in std_logic_vector(AXI_DATA_WIDTH-1 downto 0)
    ) is begin
      awaddr  <= address;
      awvalid <= '1';
      wdata   <= data;
      wstrb   <= "1111";
      wvalid  <= '1';
      bready  <= '1';

      wait until rising_edge(clk);
      awvalid <= '0';
      wvalid  <= '0';

      wait until rising_edge(clk);
      if bvalid = '0' then
          wait until bvalid = '1';
      end if;
      
      bready  <= '0';
      
    end procedure;
    
    procedure axi_read(
      address : in std_logic_vector(AXI_ADDR_WIDTH-1 downto 0)
    ) is begin
      araddr  <= address;
      arvalid <= '1';
      rready  <= '1';
      
      wait until rising_edge(clk);
      arvalid <= '0';
      
      wait until rising_edge(clk);
      rready  <= '0';
    
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
    axi_write("000" & x"0000280", x"00002000");
    -- Write to decay regs
    axi_write("000" & x"0000284", x"00002000");
    -- Write to sustain regs
    axi_write("000" & x"0000288", x"00080000");
    -- Write to release regs
    axi_write("000" & x"000028C", x"00002000");

    wait for 6e6 ns;
    wait until rising_edge(clk);
    -- Write to note 127 reg
    axi_write("000" & x"00001FC", x"00000000");
    -- End Simulation
    wait for clk_period2;
    report "Testbench completed." severity note;
  wait;
end process;

end tb;
