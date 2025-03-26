----------------------------------------------------------------------------------
-- Company: beepboop
-- Engineer: Tyler Huddleston
-- 
-- Create Date: 02/23/2025
-- Design Name: Utilities
-- Module Name: CLock Divider
-- Description: 
--   Divides an output clock to a lower frequency.
-- 
----------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

entity clkdivider is
  generic (
    G_DIVIDEBY : natural := 2
  );
  port (
    clk      : in  std_logic;
    rst      : in  std_logic;
    clkout   : out std_logic;
    rstout   : out std_logic
  );
end clkdivider;

architecture Behavioral of clkdivider is

  component rst_sync is
    port (
      rst_async_in : in  std_logic;
      clk_sync_in  : in  std_logic;
      rst_sync_out : out std_logic
    );
  end component rst_sync;

signal cnt : natural range 0 to G_DIVIDEBY;
signal clk_out_buf : std_logic;

begin

  clkout <= clk_out_buf;

  process(clk, rst)
  begin
    if rst = '1' then
      cnt <= G_DIVIDEBY/2-1;
      clk_out_buf <= '0';
    elsif rising_edge(clk) then
      if cnt = (G_DIVIDEBY/2) - 1 then
        cnt <= 0;
        clk_out_buf <= not clk_out_buf;
      else
        cnt <= cnt + 1;
      end if;
    end if;
  end process;
  
  u_rst_sync: rst_sync
  port map (
    rst_async_in => rst,
    clk_sync_in  => clk_out_buf,
    rst_sync_out => rstout
  );

end Behavioral;
