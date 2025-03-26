----------------------------------------------------------------------------------
-- Company: beepboop
-- Engineer: Tyler Huddleston
-- 
-- Create Date: 02/23/2025
-- Design Name: Utilities
-- Module Name: Reset Synchronizer
-- Description: 
--   Synchronizes a reset to a clock.
-- 
----------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

entity rst_sync is
  port (
    rst_async_in : in  std_logic;
    clk_sync_in  : in  std_logic;
    rst_sync_out : out std_logic
  );
end rst_sync;

architecture Behavioral of rst_sync is

  -- Register
  signal rst_out_q : std_logic := '1';

begin

  -- Asynchronously applied and synchronously released reset
  s_rst: process(rst_async_in, rst_out_q, clk_sync_in)
  begin
    if rst_async_in = '1' then
      rst_out_q    <= '1';
      rst_sync_out <= '1';
    else
      if rising_edge(clk_sync_in) then
        rst_out_q    <= '0';
        rst_sync_out <= rst_out_q;
      end if;
    end if;
  end process s_rst;

end Behavioral;
