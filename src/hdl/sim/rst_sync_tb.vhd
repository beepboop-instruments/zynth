----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/23/2025 03:11:56 PM
-- Design Name: 
-- Module Name: rst_sync_tb - Behavioral
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

entity rst_sync_tb is
--  Port ( );
end rst_sync_tb;

architecture Behavioral of rst_sync_tb is

  component rst_sync is
    port (
      rst_async_in : in  std_logic;
      clk_sync_in  : in  std_logic;
      rst_sync_out : out std_logic
    );
  end component rst_sync;

  signal clock    : std_logic := '0';
  signal reset    : std_logic := '1';
  signal rst_out  : std_logic;

begin

  -- Reset and clock
  clock <= not clock after 10 ns;
  reset <= not reset after 137 ns;

  -- Instantiate the design under test
  dut: rst_sync
    port map (
      rst_async_in => reset,
      clk_sync_in  => clock,
      rst_sync_out => rst_out
    );

end Behavioral;
