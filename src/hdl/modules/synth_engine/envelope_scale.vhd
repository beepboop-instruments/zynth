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
    DATA_WIDTH      : natural := WIDTH_WAVE_DATA;
    COUNT_WIDTH     : natural := WIDTH_ADSR_COUNT
  );
  port (
    clk             : in  std_logic;
    rst             : in  std_logic;
    -- synth controls
    attack_length   : in  unsigned(COUNT_WIDTH-1 downto 0);
    decay_length    : in  unsigned(COUNT_WIDTH-1 downto 0);
    sustain_amt     : in  unsigned(COUNT_WIDTH-1 downto 0);
    release_length  : in  unsigned(COUNT_WIDTH-1 downto 0);
    attack_steps    : in  t_adsr;
    decay_steps     : in  t_adsr;
    release_steps   : in  t_adsr;
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

  signal note_amps    : t_note_amp;

  signal note_index_q : integer range I_LOWEST_NOTE to I_HIGHEST_NOTE;

  signal note_amp_q   : unsigned(NOTE_GAIN_WIDTH-1 downto 0);

  -- note register
  signal  note_d,
          note_q      : signed(DATA_WIDTH-1 downto 0);

  -- adsr signals
  signal  attack_step,
          decay_step,
          release_step   : unsigned(COUNT_WIDTH-1 downto 0);
  
  -- timing signals
  signal  one_ms_counter_d,
          one_ms_counter_q   : integer range 1 to 96;

  -- states
  type   t_adsr_states is (IDLE, ATTACK, DECAY, SUSTAIN, RELEASE);
  signal  adsr_state_d,
          adsr_state_q : t_adsr_states;

begin

  -- output assignments
  note_index_out <= note_index_q;
  note_out       <= note_q;

  -- calculate step sizes using bitwise-weighted sum approximation
  s_step_sizes: process(clk)
    variable attack_step_acc  : unsigned(COUNT_WIDTH-1 downto 0) := (others => '0');
    variable decay_step_acc   : unsigned(COUNT_WIDTH-1 downto 0) := (others => '0');
    variable release_step_acc : unsigned(COUNT_WIDTH-1 downto 0) := (others => '0');
  begin
    if rising_edge(clk) then
      attack_step_acc  := (others => '0');
      decay_step_acc   := (others => '0');
      release_step_acc := (others => '0');
      for i in 0 to 6 loop
        if note_amp_in(i) = '1' then
          attack_step_acc  := attack_step_acc + attack_steps(i);
          decay_step_acc   := decay_step_acc + decay_steps(i);
          release_step_acc := release_step_acc + release_steps(i);
        end if;
      end loop;
      attack_step  <= attack_step_acc;
      decay_step   <= decay_step_acc;
      release_step <= release_step_acc;
    end if;
  end process s_step_sizes;

  s_one_ms_counter: process(one_ms_counter_q, note_index_q)
  begin
    -- count to 1 ms based on 96 kHz sample rate, where a 96 kHz
    -- period starts every 128 notes
    if (note_index_q = I_LOWEST_NOTE) then
      if (one_ms_counter_q = 96) then
        one_ms_counter_d <= 1;
      else
        one_ms_counter_d <= one_ms_counter_q + 1;
      end if;
    end if;
  end process s_one_ms_counter;

  s_regs: process(rst, clk)
  begin
    if (rst = '1') then
      note_q           <= (others => '0');
      note_index_q     <= I_LOWEST_NOTE;
      note_amps        <= (others => (others => '0'));
      one_ms_counter_q <= 1;
    elsif (rising_edge(clk)) then
      note_q       <= note_d;
      note_index_q <= note_index_in;
      if (cycle_start_in = '1') then
        note_amps(note_index_in) <= note_amp_in;
      end if;
      one_ms_counter_q   <= one_ms_counter_d;
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