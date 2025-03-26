----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/23/2025 08:03:45 PM
-- Design Name: 
-- Module Name: clkdivider_tb - Behavioral
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

entity clkdivider_tb is
--  Port ( );
end clkdivider_tb;

architecture Behavioral of clkdivider_tb is

  component clkdivider is
    generic (G_DIVIDEBY : natural := 2);
    port ( clk : in std_logic;
           reset : in std_logic;
           pulseout : out std_logic);
  end component clkdivider;

  signal clock    : std_logic := '0';
  signal reset    : std_logic := '1';
  signal clk_div2, clk_div3, clk_div4 : std_logic;
  
begin

  -- Reset and clock
  clock <= not clock after 10 ns;
  reset <= '0' after 20 ns;

  -- Instantiate the design under test
  u_div_by_2: clkdivider
    generic map (
      G_DIVIDEBY => 2
    )
    port map (
      clk      => clock,
      reset    => reset,
      pulseout => clk_div2
    );
    
    u_div_by_3: clkdivider
    generic map (
      G_DIVIDEBY => 3
    )
    port map (
      clk      => clock,
      reset    => reset,
      pulseout => clk_div3
    );
    
    u_div_by_4: clkdivider
    generic map (
      G_DIVIDEBY => 4
    )
    port map (
      clk      => clock,
      reset    => reset,
      pulseout => clk_div4
    );

end Behavioral;
