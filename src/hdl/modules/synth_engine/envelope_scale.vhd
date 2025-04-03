----------------------------------------------------------------------------------
-- Company: beepboop
-- Engineer: Tyler Huddlesotn
-- 
-- Create Date: 04/03/2025
-- Design Name: Synthesizer Enginer
-- Module Name: Envelope Scale
-- Description: 
--   Applies an amplitude envelope to each played note.
-- 
----------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library xil_defaultlib;
  use xil_defaultlib.synth_pkg.all;

entity envelope_scale is
  generic (
    NOTE_GAIN_WIDTH : integer := WIDTH_NOTE_GAIN;
    DATA_WIDTH      : natural := WIDTH_WAVE_DATA
  );
  port (
    clk             : in  std_logic;
    rst             : in  std_logic;
    -- synth controls
    -- adsr_settings
    -- pipeline in
    note_index_in   : in  integer range I_LOWEST_NOTE to I_HIGHEST_NOTE;
    note_amp_in     : in  unsigned(NOTE_GAIN_WIDTH-1 downto 0);
    note_in         : in  signed(DATA_WIDTH-1 downto 0);
    cycle_start_in  : in  std_logic;
    -- pipeline out
    note_index_out  : out integer range I_LOWEST_NOTE to I_HIGHEST_NOTE;
    note_out        : out signed(DATA_WIDTH-1 downto 0)
  );
end entity;

architecture rtl of envelope_scale is

  component scaler is
    generic (
      WIDTH_DATA : integer := 16;  -- Width of input and output samples
      WIDTH_GAIN : integer := 7
    );
    port (
      input_word  : in  signed(WIDTH_DATA-1 downto 0);
      gain_word   : in  unsigned(WIDTH_GAIN-1 downto 0);
      output_word : out signed(WIDTH_DATA-1 downto 0)
    );
  end component scaler;

  signal note_amps  : t_note_amp;

  signal note_index_q : integer range I_LOWEST_NOTE to I_HIGHEST_NOTE;

  signal note_amp_q : unsigned(NOTE_GAIN_WIDTH-1 downto 0);

  signal note_d, note_q : signed(DATA_WIDTH-1 downto 0);

begin

  note_index_out <= note_index_q;
  note_out       <= note_q;

  s_regs: process(rst, clk)
  begin
    if (rst = '1') then
      note_q       <= (others => '0');
      note_index_q <= I_LOWEST_NOTE;
      note_amps    <= (others => (others => '0'));
    elsif (rising_edge(clk)) then
      note_q       <= note_d;
      note_index_q <= note_index_in;
      if (cycle_start_in = '1') then
        note_amps(note_index_in) <= note_amp_in;
      end if;
    end if;
  end process s_regs;

  u_out_gain_scaler: scaler
  generic map (
    WIDTH_DATA => DATA_WIDTH,
    WIDTH_GAIN => WIDTH_NOTE_GAIN
  )
  port map (
    input_word  => note_in,
    gain_word   => note_amps(note_index_in),
    output_word => note_d
  );

end architecture rtl;