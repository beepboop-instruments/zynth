library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library xil_defaultlib;
use xil_defaultlib.synth_pkg.all;

entity synth_ctrl_tb is
end synth_ctrl_tb;

architecture tb of synth_ctrl_tb is

    -- AXI signals
    signal clk      : std_logic := '0';
    signal reset_n  : std_logic := '0';
    
    signal awaddr   : std_logic_vector(9 downto 0);
    signal awvalid  : std_logic;
    signal awready  : std_logic;
    
    signal wdata    : std_logic_vector(31 downto 0);
    signal wstrb    : std_logic_vector(3 downto 0);
    signal wvalid   : std_logic;
    signal wready   : std_logic;
    
    signal bresp    : std_logic_vector(1 downto 0);
    signal bvalid   : std_logic;
    signal bready   : std_logic;
    
    signal araddr   : std_logic_vector(9 downto 0);
    signal arvalid  : std_logic;
    signal arready  : std_logic;
    
    signal rdata    : std_logic_vector(31 downto 0);
    signal rresp    : std_logic_vector(1 downto 0);
    signal rvalid   : std_logic;
    signal rready   : std_logic;

    -- Clock process
    constant clk_period : time := 10 ns;
    
    -- DUT Component (Assuming entity is named axi_slave)
    component synth_ctrl is
        port (
            -- Users to add ports here
            note_amps : out t_note_amp;
            wfrm_amps : out t_wfrm_amp;
            wfrm_phs  : out t_wfrm_ph;
    
            -- User ports ends
            -- Do not modify the ports beyond this line
    
    
            -- Ports of Axi Slave Bus Interface S00_AXI
            s00_axi_aclk  : in std_logic;
            s00_axi_aresetn  : in std_logic;
            s00_axi_awaddr  : in std_logic_vector(9 downto 0);
            s00_axi_awprot  : in std_logic_vector(2 downto 0);
            s00_axi_awvalid  : in std_logic;
            s00_axi_awready  : out std_logic;
            s00_axi_wdata  : in std_logic_vector(31 downto 0);
            s00_axi_wstrb  : in std_logic_vector(3 downto 0);
            s00_axi_wvalid  : in std_logic;
            s00_axi_wready  : out std_logic;
            s00_axi_bresp  : out std_logic_vector(1 downto 0);
            s00_axi_bvalid  : out std_logic;
            s00_axi_bready  : in std_logic;
            s00_axi_araddr  : in std_logic_vector(9 downto 0);
            s00_axi_arprot  : in std_logic_vector(2 downto 0);
            s00_axi_arvalid  : in std_logic;
            s00_axi_arready  : out std_logic;
            s00_axi_rdata  : out std_logic_vector(31 downto 0);
            s00_axi_rresp  : out std_logic_vector(1 downto 0);
            s00_axi_rvalid  : out std_logic;
            s00_axi_rready  : in std_logic
        );
    end component synth_ctrl;
    
begin
    -- Instantiate the DUT

    uut: synth_ctrl
        port map (
            -- Users to add ports here
            note_amps => open,
            wfrm_amps => open,
            wfrm_phs  => open,
    
            -- User ports ends
            -- Do not modify the ports beyond this line
    
    
            -- Ports of Axi Slave Bus Interface S00_AXI
            s00_axi_aclk  => clk,
            s00_axi_aresetn  => reset_n,
            s00_axi_awaddr  => awaddr,
            s00_axi_awprot  => "000",
            s00_axi_awvalid  => awvalid,
            s00_axi_awready  => awready,
            s00_axi_wdata  => wdata,
            s00_axi_wstrb  => wstrb,
            s00_axi_wvalid  => wvalid,
            s00_axi_wready  => wready,
            s00_axi_bresp  => bresp,
            s00_axi_bvalid  => bvalid,
            s00_axi_bready  => bready,
            s00_axi_araddr  => araddr,
            s00_axi_arprot  => "000",
            s00_axi_arvalid  => arvalid,
            s00_axi_arready  => arready,
            s00_axi_rdata  => rdata,
            s00_axi_rresp  => rresp,
            s00_axi_rvalid  => rvalid,
            s00_axi_rready  => rready
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
        address : in std_logic_vector(9 downto 0);
        data : in std_logic_vector(31 downto 0)
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
        address : in std_logic_vector(9 downto 0)
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
        reset_n <= '0';
        awaddr  <= "0000000000";
        awvalid <= '0';
        wdata   <= x"00000000";
        wstrb   <= "0000";
        wvalid  <= '0';
        bready  <= '0';
        araddr  <= "0000000000";
        arvalid <= '0';
        rready  <= '0';
        wait for 20 ns;
        reset_n <= '1';
        wait for 20 ns;
        
        -- Write to register 0
        axi_write("0000000000", x"00000018");
        -- Read from register 0
        axi_read("0000000000");
        -- Write to note 127 reg
        axi_write("0111111100", x"000000A5");
        -- Write to pulse reg
        axi_write("1000000000", x"ABCDFEDC");
        -- Write to ramp reg
        axi_write("1000000100", x"4321FEFE");
        -- Write to saw reg
        axi_write("1000001000", x"CAFE1234");
        -- Write to tri reg
        axi_write("1000001100", x"BA5EBA11");
        -- Write to sin reg
        axi_write("1000010000", x"87654321");
        
        -- End Simulation
        wait for 100 ns;
        report "Testbench completed." severity note;
        wait;
    end process;

end tb;
