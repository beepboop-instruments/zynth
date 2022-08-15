----------------------------------------------------------------------------------
-- Company: beepboopinstruments
-- Engineer: tyler huddleston
-- 
-- Create Date: 08/14/2022 07:30:11 PM
-- Design Name: zynth
-- Module Name: top - Behavioral
-- Project Name: zynth
-- Target Devices: zynq (zybo z7020)
-- Tool Versions: vivado 2022.1
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

entity top is
  Port ( 
    -- ddr pins
    DDR_addr          : inout STD_LOGIC_VECTOR ( 14 downto 0 );
    DDR_ba            : inout STD_LOGIC_VECTOR ( 2 downto 0 );
    DDR_cas_n         : inout STD_LOGIC;
    DDR_ck_n          : inout STD_LOGIC;
    DDR_ck_p          : inout STD_LOGIC;
    DDR_cke           : inout STD_LOGIC;
    DDR_cs_n          : inout STD_LOGIC;
    DDR_dm            : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    DDR_dq            : inout STD_LOGIC_VECTOR ( 31 downto 0 );
    DDR_dqs_n         : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    DDR_dqs_p         : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    DDR_odt           : inout STD_LOGIC;
    DDR_ras_n         : inout STD_LOGIC;
    DDR_reset_n       : inout STD_LOGIC;
    DDR_we_n          : inout STD_LOGIC;
    FIXED_IO_ddr_vrn  : inout STD_LOGIC;
    FIXED_IO_ddr_vrp  : inout STD_LOGIC;
    FIXED_IO_mio      : inout STD_LOGIC_VECTOR ( 53 downto 0 );
    FIXED_IO_ps_clk   : inout STD_LOGIC;
    FIXED_IO_ps_porb  : inout STD_LOGIC;
    FIXED_IO_ps_srstb : inout STD_LOGIC;
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

architecture Behavioral of top is
  -- PS block design
  component ps_zynth is
    port (
      DDR_cas_n         : inout STD_LOGIC;
      DDR_cke           : inout STD_LOGIC;
      DDR_ck_n          : inout STD_LOGIC;
      DDR_ck_p          : inout STD_LOGIC;
      DDR_cs_n          : inout STD_LOGIC;
      DDR_reset_n       : inout STD_LOGIC;
      DDR_odt           : inout STD_LOGIC;
      DDR_ras_n         : inout STD_LOGIC;
      DDR_we_n          : inout STD_LOGIC;
      DDR_ba            : inout STD_LOGIC_VECTOR ( 2 downto 0 );
      DDR_addr          : inout STD_LOGIC_VECTOR ( 14 downto 0 );
      DDR_dm            : inout STD_LOGIC_VECTOR ( 3 downto 0 );
      DDR_dq            : inout STD_LOGIC_VECTOR ( 31 downto 0 );
      DDR_dqs_n         : inout STD_LOGIC_VECTOR ( 3 downto 0 );
      DDR_dqs_p         : inout STD_LOGIC_VECTOR ( 3 downto 0 );
      FIXED_IO_mio      : inout STD_LOGIC_VECTOR ( 53 downto 0 );
      FIXED_IO_ddr_vrn  : inout STD_LOGIC;
      FIXED_IO_ddr_vrp  : inout STD_LOGIC;
      FIXED_IO_ps_srstb : inout STD_LOGIC;
      FIXED_IO_ps_clk   : inout STD_LOGIC;
      FIXED_IO_ps_porb  : inout STD_LOGIC;
      iic_rtl_scl_i     : in    STD_LOGIC;
      iic_rtl_scl_o     : out   STD_LOGIC;
      iic_rtl_scl_t     : out   STD_LOGIC;
      iic_rtl_sda_i     : in    STD_LOGIC;
      iic_rtl_sda_o     : out   STD_LOGIC;
      iic_rtl_sda_t     : out   STD_LOGIC
      );
    end component ps_zynth;
      
    -- 3-state buffer
    component IOBUF is
      port (
        I  : in STD_LOGIC;
        O  : out STD_LOGIC;
        T  : in STD_LOGIC;
        IO : inout STD_LOGIC
        );
      end component IOBUF;
      
    -- Audio Codec I2C control signals from block design to buffers
    signal iic_rtl_scl_i : STD_LOGIC;
    signal iic_rtl_scl_o : STD_LOGIC;
    signal iic_rtl_scl_t : STD_LOGIC;
    signal iic_rtl_sda_i : STD_LOGIC;
    signal iic_rtl_sda_o : STD_LOGIC;
    signal iic_rtl_sda_t : STD_LOGIC;

--------------------------------------------------------------
begin

--------------------- output assignments ---------------------

ac_bclk    <= '0';
ac_mclk    <= '0';
ac_muten   <= '0';
ac_pbdat   <= '0';
ac_pblrc   <= '0';
ac_reclrc  <= '0';



----------------------- process logic ------------------------


------------------- component instantiation -------------------

  -- block design
  ps_zynth_i: component ps_zynth
    port map (
      DDR_addr(14 downto 0)     => DDR_addr(14 downto 0),
      DDR_ba(2 downto 0)        => DDR_ba(2 downto 0),
      DDR_cas_n                 => DDR_cas_n,
      DDR_ck_n                  => DDR_ck_n,
      DDR_ck_p                  => DDR_ck_p,
      DDR_cke                   => DDR_cke,
      DDR_cs_n                  => DDR_cs_n,
      DDR_dm(3 downto 0)        => DDR_dm(3 downto 0),
      DDR_dq(31 downto 0)       => DDR_dq(31 downto 0),
      DDR_dqs_n(3 downto 0)     => DDR_dqs_n(3 downto 0),
      DDR_dqs_p(3 downto 0)     => DDR_dqs_p(3 downto 0),
      DDR_odt                   => DDR_odt,
      DDR_ras_n                 => DDR_ras_n,
      DDR_reset_n               => DDR_reset_n,
      DDR_we_n                  => DDR_we_n,
      FIXED_IO_ddr_vrn          => FIXED_IO_ddr_vrn,
      FIXED_IO_ddr_vrp          => FIXED_IO_ddr_vrp,
      FIXED_IO_mio(53 downto 0) => FIXED_IO_mio(53 downto 0),
      FIXED_IO_ps_clk           => FIXED_IO_ps_clk,
      FIXED_IO_ps_porb          => FIXED_IO_ps_porb,
      FIXED_IO_ps_srstb         => FIXED_IO_ps_srstb,
      iic_rtl_scl_i             => iic_rtl_scl_i,
      iic_rtl_scl_o             => iic_rtl_scl_o,
      iic_rtl_scl_t             => iic_rtl_scl_t,
      iic_rtl_sda_i             => iic_rtl_sda_i,
      iic_rtl_sda_o             => iic_rtl_sda_o,
      iic_rtl_sda_t             => iic_rtl_sda_t
      );

  -- audio codec scl buffer
  iic_rtl_scl_iobuf: component IOBUF
    port map (
      I  => iic_rtl_scl_o,
      IO => ac_scl,
      O  => iic_rtl_scl_i,
      T  => iic_rtl_scl_t  );
      
  -- audio codec sda buffer
  iic_rtl_sda_iobuf: component IOBUF
    port map (
      I => iic_rtl_sda_o,
      IO => ac_sda,
      O => iic_rtl_sda_i,
      T => iic_rtl_sda_t
      );
 

end Behavioral;
