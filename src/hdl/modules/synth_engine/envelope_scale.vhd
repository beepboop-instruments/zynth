----------------------------------------------------------------------------------
-- Company: beepboop
-- Engineer: Tyler Huddleston
-- 
-- Create Date: 04/03/2025
-- Design Name: Synthesizer Engine
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

  signal note_index_q,
         note_index_q2  : integer range I_LOWEST_NOTE to I_HIGHEST_NOTE;

  signal  note_amp_d    : unsigned(WIDTH_ADSR_COUNT-1 downto 0);
  signal  note_amp_q    : unsigned(WIDTH_NOTE_GAIN-1 downto 0);

  signal  note_amps_q   : t_note_amp;
  signal  note_amps_acc : t_note_acc;

  -- note register
  signal  note_d,
          note_q      : signed(DATA_WIDTH-1 downto 0);

  -- cycle start registered signal
  signal  cycle_start_q : std_logic;

  -- adsr signals
  signal  attack_step_d,
          attack_step_q,
          decay_step_d,
          decay_step_q,
          release_step_d,
          release_step_q     : unsigned(COUNT_WIDTH-1 downto 0);
  
  -- timing signals
  signal  one_ms_counter_d,
          one_ms_counter_q   : integer range 1 to 96;
  signal  one_ms_strobe_d,
          one_ms_strobe_q    : std_logic;

  -- states
  type    t_adsr_state  is (E_START, E_ATTACK, E_DECAY, E_SUSTAIN, E_RELEASE);
  type    t_adsr_states is array (I_LOWEST_NOTE to I_HIGHEST_NOTE) of t_adsr_state;
  signal  adsr_state_d  : t_adsr_state;
  signal  adsr_states_q : t_adsr_states;
  
  -- adsr count register file
  signal adsr_count_d  : unsigned(WIDTH_ADSR_COUNT-1 downto 0);
  signal adsr_counts_q : t_adsr_count;

begin

  -- output assignments
  note_index_out <= note_index_q;
  note_out       <= note_q;

  -- adsr state machine
  s_adsr_state_machine: process(adsr_states_q, adsr_counts_q,
                                note_amp_q,    note_index_q,    note_amps_q,
                                cycle_start_q, one_ms_strobe_q,
                                attack_length, decay_length,    release_length)
  begin

    adsr_state_d  <= adsr_states_q(note_index_q);
    adsr_count_d  <= adsr_counts_q(note_index_q);
    note_amp_d    <= note_amps_acc(note_index_q);

    case adsr_states_q(note_index_q) is

      when E_START =>
        adsr_count_d <= (others => '0');
        note_amp_d   <= (others => '0');
        -- go to attack state when a note is played
        if (note_amp_q /= to_unsigned(0, WIDTH_NOTE_GAIN)) then
          if (cycle_start_q = '1') then
            adsr_state_d <= E_ATTACK;
          end if;
        end if;

      when E_ATTACK =>
        if (note_amp_q = to_unsigned(0, WIDTH_NOTE_GAIN)) then
          -- if key is released, go to release state
          adsr_state_d <= E_RELEASE;
          adsr_count_d <= (others => '0');
        elsif (note_amp_q /= note_amps_q(note_index_q)) then
          -- reset attack counter if the note amplitude changed
          adsr_count_d <= (others => '0');
          note_amp_d   <= (others => '0');
        elsif (adsr_counts_q(note_index_q) < attack_length) then
          -- increase amplitude one ms at a time until the attack stage is complete
          if (one_ms_strobe_q = '1') then
            adsr_count_d <= adsr_counts_q(note_index_q) + 1;
          end if;
          note_amp_d   <= note_amps_acc(note_index_q) + attack_step_q;
        else
          -- continue to decay state
          adsr_state_d <= E_DECAY;
          adsr_count_d <= (others => '0');
        end if;

      when E_DECAY =>
        if (note_amp_q = to_unsigned(0, WIDTH_NOTE_GAIN)) then
          -- if key is released, go to release state
          adsr_state_d <= E_RELEASE;
          adsr_count_d <= (others => '0');
        elsif (note_amp_q /= note_amps_q(note_index_q)) then
          -- reset attack counter if the note amplitude changed
          adsr_state_d <= E_ATTACK;
          adsr_count_d <= (others => '0');
          note_amp_d   <= (others => '0');
        elsif (adsr_counts_q(note_index_q) < decay_length) then
          -- decrease note amplitude until the end of the decay state
          if (one_ms_strobe_q = '1') then
            adsr_count_d <= adsr_counts_q(note_index_q) + 1;
          end if;
          note_amp_d   <= note_amps_acc(note_index_q) - decay_step_q;
        else
          -- continue to sustain state
          adsr_state_d <= E_SUSTAIN;
          adsr_count_d <= (others => '0');
        end if;

      when E_SUSTAIN =>
        if (note_amp_q = to_unsigned(0, WIDTH_NOTE_GAIN)) then
          -- if key is released, go to release state
          adsr_state_d <= E_RELEASE;
          adsr_count_d <= (others => '0');
        elsif (note_amp_q /= note_amps_q(note_index_q)) then
          -- reset attack counter if the note amplitude changed
          adsr_state_d <= E_ATTACK;
          adsr_count_d <= (others => '0');
          note_amp_d   <= (others => '0');
        end if;

      when E_RELEASE =>
        if (note_amp_q /= note_amps_q(note_index_q) and
            note_amp_q /= to_unsigned(0, WIDTH_NOTE_GAIN)) then
          -- go to attack state if note is played again
          adsr_state_d <= E_ATTACK;
          adsr_count_d <= (others => '0');
          note_amp_d   <= (others => '0');
        elsif (adsr_counts_q(note_index_q) < release_length) then
          -- decrease note amplitude until the end of the release state
          if (one_ms_strobe_q = '1') then
            adsr_count_d <= adsr_counts_q(note_index_q) + 1;
          end if;
          note_amp_d   <= note_amps_acc(note_index_q) - release_step_q;
        else
          adsr_state_d <= E_START;
          adsr_count_d <= (others => '0');
          note_amp_d   <= (others => '0');
        end if;

      when others =>
        adsr_state_d <= E_START;
        
    end case;

  end process s_adsr_state_machine;

  -- calculate step sizes using bitwise-weighted sum approximation
  s_step_sizes: process(note_amps_q, note_index_in)
    variable attack_step_acc  : unsigned(COUNT_WIDTH-1 downto 0) := (others => '0');
    variable decay_step_acc   : unsigned(COUNT_WIDTH-1 downto 0) := (others => '0');
    variable release_step_acc : unsigned(COUNT_WIDTH-1 downto 0) := (others => '0');
  begin
    attack_step_acc  := (others => '0');
    decay_step_acc   := (others => '0');
    release_step_acc := (others => '0');
    for i in 0 to 6 loop
      if note_amps_q(note_index_in)(i) = '1' then
        attack_step_acc  := attack_step_acc  + attack_steps(i);
        decay_step_acc   := decay_step_acc   + decay_steps(i);
        release_step_acc := release_step_acc + release_steps(i);
      end if;
    end loop;
    attack_step_d  <= attack_step_acc;
    decay_step_d   <= decay_step_acc;
    release_step_d <= release_step_acc;
  end process s_step_sizes;

  s_one_ms_counter: process(one_ms_counter_q, note_index_q)
  begin
    -- count to 1 ms based on 96 kHz sample rate, where a 96 kHz
    -- period starts every 128 notes
    if (note_index_q = I_LOWEST_NOTE) then
      if (one_ms_counter_q = 96) then
        one_ms_counter_d <= 1;
        one_ms_strobe_d  <= '1';
      else
        one_ms_counter_d <= one_ms_counter_q + 1;
        one_ms_strobe_d <= '0';
      end if;
    end if;
  end process s_one_ms_counter;

  s_regs: process(rst, clk)
  begin
    if (rst = '1') then
      adsr_states_q                <= (others => E_START);
      note_q                       <= (others => '0');
      note_index_q                 <= I_LOWEST_NOTE;
      note_index_q2                <= I_LOWEST_NOTE;
      one_ms_counter_q             <= 1;
      one_ms_strobe_q              <= '0';
      adsr_counts_q                <= (others => (others => '0'));
      note_amp_q                   <= (others => '0');
      note_amps_acc                <= (others => (others => '0'));
      cycle_start_q                <= '0';
      attack_step_q                <= (others => '0');
      decay_step_q                 <= (others => '0');
      release_step_q               <= (others => '0');
    elsif (rising_edge(clk)) then
      adsr_states_q(note_index_q)  <= adsr_state_d;
      note_q                       <= note_d;
      note_index_q                 <= note_index_in;
      note_index_q2                <= note_index_q;
      one_ms_counter_q             <= one_ms_counter_d;
      one_ms_strobe_q              <= one_ms_strobe_d;
      adsr_counts_q(note_index_q)  <= adsr_count_d;
      note_amp_q                   <= note_amp_in;
      note_amps_acc(note_index_q)  <= note_amp_d;
      cycle_start_q                <= cycle_start_in;
      attack_step_q                <= attack_step_d;
      decay_step_q                 <= decay_step_d;
      release_step_q               <= release_step_d;
    end if;
  end process s_regs;

  s_regs_note_amps: process(clk, rst, adsr_states_q, note_index_q)
  begin
    if (rst = '1') then
      note_amps_q <= (others => (others => '0'));
    elsif (rising_edge(clk)) then
      note_amps_q <= note_amps_q;

      case (adsr_states_q(note_index_q)) is

        when E_START | E_ATTACK | E_DECAY =>
          note_amps_q(note_index_q) <= note_amp_q;

        when others =>
          null;

      end case;
    end if;

  end process s_regs_note_amps;

  u_out_gain_scaler: scaler
  generic map (
    WIDTH_DATA => DATA_WIDTH,
    WIDTH_GAIN => WIDTH_ADSR_COUNT
  )
  port map (
    input_word  => note_in,
    gain_word   => note_amps_acc(note_index_in),
    output_word => note_d
  );

end architecture rtl;