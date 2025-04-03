----------------------------------------------------------------------------------
-- Company: beepboop
-- Engineer: Tyler Huddlesotn
-- 
-- Create Date: 04/03/2025
-- Design Name: Synthesizer Enginer
-- Module Name: Polyphony Mixer
-- Description: 
--   Mixes all played notes together
-- 
----------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library xil_defaultlib;
  use xil_defaultlib.synth_pkg.all;

entity poly_mix is
  generic (
    OUT_GAIN_WIDTH  : integer := WIDTH_OUT_GAIN;
    OUT_SHIFT_WIDTH : integer := WIDTH_OUT_SHIFT;
    DATA_WIDTH      : natural := WIDTH_WAVE_DATA;
    OUT_DATA_WIDTH : natural := WIDTH_WAVE_DATA+8
  );
  port (
    clk             : in  std_logic;
    rst             : in  std_logic;
    -- synth controls
    out_amp         : in  unsigned(OUT_GAIN_WIDTH-1 downto 0);
    out_shift       : in  unsigned(OUT_SHIFT_WIDTH-1 downto 0);
    -- pipeline in
    note_index_in   : in  integer range I_LOWEST_NOTE to I_HIGHEST_NOTE;
    note_in         : in  signed(DATA_WIDTH-1 downto 0);
    -- pipeline out
    audio_out       : out std_logic_vector(OUT_DATA_WIDTH-1 downto 0)
  );
end entity;

architecture rtl of poly_mix is

  component synth_note_mixer is
    generic (
      I_LOW       : integer := 0;  -- lowest index in array
      I_HIGH      : integer := 3;  -- highest index in array
      IN_WIDTH    : integer := 16; -- width of input data
      OUT_WIDTH   : integer := 24  -- width of output data
    );
    port (
      in_array : in  t_wave_data;
      out_sum  : out signed(OUT_WIDTH-1 downto 0)
    );
  end component;

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

  -- register file to store all note waveforms
  signal note_regs  : t_wave_data;

  -- audio output registers
  signal audio_out_d,
         audio_out_q   : std_logic_vector(OUT_DATA_WIDTH-1 downto 0);

  -- intermediate processing signals
  signal notes_sum       : signed(OUT_DATA_WIDTH-1 downto 0);
  signal audio_out_scale : signed(OUT_DATA_WIDTH-1 downto 0);

begin
  -- output assignments
  audio_out   <= audio_out_q;

  -- logic assignments
  audio_out_d <= std_logic_vector(shift_left(audio_out_scale, to_integer(out_shift)));

  -- mix all notes together for polyphonic
  u_sum_mixes: synth_note_mixer
    generic map (
      I_LOW       => I_LOWEST_NOTE,
      I_HIGH      => I_HIGHEST_NOTE,
      IN_WIDTH    => DATA_WIDTH,
      OUT_WIDTH   => OUT_DATA_WIDTH
    )
    port map (
      in_array => note_regs,
      out_sum  => notes_sum
    );

  -- scale the polyphonic mix
  u_out_scaler: scaler
    generic map (
      WIDTH_DATA => OUT_DATA_WIDTH,
      WIDTH_GAIN => WIDTH_OUT_GAIN
    )
    port map (
      input_word  => notes_sum,
      gain_word   => out_amp,
      output_word => audio_out_scale
    );

  -- synchronous registers
  s_regs: process(rst, clk)
  begin
    if (rst = '1') then
      note_regs    <= (others => (others => '0'));
      audio_out_q  <= (others => '0');
    elsif (rising_edge(clk)) then
      note_regs(note_index_in) <= note_in;
      audio_out_q  <= audio_out_d;
    end if;
  end process s_regs;

end architecture rtl;