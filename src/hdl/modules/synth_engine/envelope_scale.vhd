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
    ADSR_WIDTH      : natural := WIDTH_ADSR_CC;
    ACC_WIDTH       : natural := WIDTH_ADSR_COUNT
  );
  port (
    clk             : in  std_logic;
    rst             : in  std_logic;
    -- synth controls
    attack_amt      : in  unsigned(ADSR_WIDTH-1 downto 0);
    decay_amt       : in  unsigned(ADSR_WIDTH-1 downto 0);
    sustain_amt     : in  unsigned(ADSR_WIDTH-1 downto 0);
    release_amt     : in  unsigned(ADSR_WIDTH-1 downto 0);
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
  
  component scaler_unsigned is
    generic (
      WIDTH_DATA : integer := 16;  -- Width of input and output samples
      WIDTH_GAIN : integer := 7
    );
    port (
      input_word  : in  unsigned(WIDTH_DATA-1 downto 0);
      gain_word   : in  unsigned(WIDTH_GAIN-1 downto 0);
      output_word : out unsigned(WIDTH_DATA-1 downto 0)
    );
  end component scaler_unsigned;

  -- note indexing registers
  signal note_index_q  : integer range I_LOWEST_NOTE to I_HIGHEST_NOTE;

  -- note amplitude storage
  signal  note_amp_d,
          note_amps_20_d,
          note_amps_20_q  : unsigned(ACC_WIDTH-1 downto 0);
  signal  note_amp_q      : unsigned(WIDTH_NOTE_GAIN-1 downto 0);

  signal  note_amps_q   : t_note_amp;
  signal  note_amps_acc : t_note_acc;
  
  -- note register
  signal  note_d,
          note_q      : signed(DATA_WIDTH-1 downto 0);

  -- cycle start registered signal
  signal  cycle_start_q : std_logic;

  -- adsr signals
  signal  step_amt,
          step_d,
          step_q,
          sustain_level_d,
          sustain_level_q    : unsigned(ACC_WIDTH-1 downto 0);

  -- states
  type    t_adsr_state  is (E_START, E_ATTACK, E_DECAY, E_SUSTAIN, E_RELEASE);
  type    t_adsr_states is array (I_LOWEST_NOTE to I_HIGHEST_NOTE) of t_adsr_state;
  signal  adsr_state_d  : t_adsr_state;
  signal  adsr_states_q : t_adsr_states;

begin

  -- output assignments
  note_index_out <= note_index_q;
  note_out       <= note_q;

  note_amps_20_q  <= note_amps_q(note_index_q) & '0' & x"000";

  -- adsr state machine
  s_adsr_state_machine: process(
    adsr_states_q,
    note_amps_20_q,
    note_index_q,
    note_amps_acc,
    note_amps_q,
    cycle_start_q,
    sustain_level_q
)
  begin

    -- default logic
    adsr_state_d  <= adsr_states_q(note_index_q);
    note_amp_d    <= note_amps_acc(note_index_q);

    case adsr_states_q(note_index_q) is

      when E_START =>
        note_amp_d   <= (others => '0');
        -- go to attack state when a note is played
        if (note_amp_q /= to_unsigned(0, WIDTH_NOTE_GAIN)) then
          adsr_state_d <= E_ATTACK;
        end if;

      when E_ATTACK =>
        if (note_amp_q = to_unsigned(0, WIDTH_NOTE_GAIN)) then
          -- if key is released, go to release state
          adsr_state_d <= E_RELEASE;
        elsif (note_amp_q /= note_amps_q(note_index_q)) then
          -- reset attack amplitude if changed in this state
          note_amp_d   <= (others => '0');
        elsif (note_amps_acc(note_index_q) < note_amps_20_q) then
          -- increment note amplitude until played velocity reached
          if (note_amps_20_q - note_amps_acc(note_index_q) >= step_q) then
            note_amp_d <= note_amps_acc(note_index_q) + step_q;
          else
            -- continue to decay state
            note_amp_d <= note_amps_acc(note_index_q);
            adsr_state_d <= E_DECAY;
          end if;
        else
          -- continue to decay state
          adsr_state_d <= E_DECAY;
        end if;

      when E_DECAY =>
        if (note_amp_q = to_unsigned(0, WIDTH_NOTE_GAIN)) then
          -- if key is released, go to release state
          adsr_state_d <= E_RELEASE;
        elsif (note_amp_q /= note_amps_q(note_index_q)) then
          -- reset attack amplitude if changed in this state
          adsr_state_d <= E_ATTACK;
          note_amp_d   <= (others => '0');
        elsif (note_amps_acc(note_index_q) > sustain_level_q) then
          -- decrease note amplitude until sustain level reached
          if (note_amps_acc(note_index_q) - sustain_level_q >= step_q) then
            note_amp_d   <= note_amps_acc(note_index_q) - step_q;
          else
            -- continue to sustain state
            note_amp_d <= sustain_level_q;
            adsr_state_d <= E_SUSTAIN;
          end if;
        else
          -- continue to sustain state
          adsr_state_d <= E_SUSTAIN;
        end if;

      when E_SUSTAIN =>
        if (note_amp_q = to_unsigned(0, WIDTH_NOTE_GAIN)) then
          -- if key is released, go to release state
          adsr_state_d <= E_RELEASE;
        elsif (note_amp_q /= note_amps_q(note_index_q)) then
          -- reset note amplitude and play again
          adsr_state_d <= E_ATTACK;
          note_amp_d   <= (others => '0');
        end if;

      when E_RELEASE =>
        if (note_amp_q /= note_amps_q(note_index_q) and
            note_amp_q /= to_unsigned(0, WIDTH_NOTE_GAIN)) then
          -- go to attack state if note is played again
          adsr_state_d <= E_ATTACK;
          note_amp_d   <= (others => '0');
        elsif (note_amps_acc(note_index_q) > to_unsigned(0, WIDTH_NOTE_GAIN)) then
          -- decrease note amplitude until off
          if (note_amps_acc(note_index_q) <= step_q) then
            note_amp_d <= (others => '0');
            adsr_state_d <= E_START;
          else
            if (step_q > 0) then
              note_amp_d <= note_amps_acc(note_index_q) - step_q;
            else
              note_amp_d   <= note_amps_acc(note_index_q) - 1;
            end if;
          end if;
        else
          adsr_state_d <= E_START;
        end if;

      when others =>
        adsr_state_d <= E_START;
        
    end case;

  end process s_adsr_state_machine;

  -- synchronous registers
  s_regs: process(rst, clk, cycle_start_q)
  begin
    if (rst = '1') then
      adsr_states_q                <= (others => E_START);
      note_q                       <= (others => '0');
      note_amp_q                   <= (others => '0');
      note_index_q                 <= I_LOWEST_NOTE;
      note_amps_acc                <= (others => (others => '0'));
      cycle_start_q                <= '0';
      sustain_level_q              <= (others => '0');
      step_q                       <= (others => '0');
    elsif (rising_edge(clk)) then
      if (cycle_start_q = '1') then
        adsr_states_q(note_index_q)  <= adsr_state_d;
      else
        adsr_states_q(note_index_q)  <= adsr_states_q(note_index_q);
      end if;
      note_q                       <= note_d;
      note_amp_q                   <= note_amp_in;
      note_index_q                 <= note_index_in;
      note_amps_acc(note_index_q)  <= note_amp_d;
      cycle_start_q                <= cycle_start_in;
      sustain_level_q              <= sustain_level_d;
      step_q                       <= step_d;
    end if;
  end process s_regs;

  -- store input note amplitude according to current state.
  s_regs_note_amps: process(clk, rst, adsr_states_q, note_index_q, note_amp_q, cycle_start_in)
  begin
    if (rst = '1') then
      note_amps_q <= (others => (others => '0'));
    elsif (rising_edge(clk)) then

      note_amps_q <= note_amps_q;

      case (adsr_states_q(note_index_q)) is

        when E_START =>
          note_amps_q(note_index_q) <= note_amp_q;

        when E_ATTACK | E_DECAY | E_SUSTAIN =>
          if note_amp_q /= to_unsigned(0, NOTE_GAIN_WIDTH) then
            note_amps_q(note_index_q) <= note_amp_q;
          end if;

        when others =>
          null;

      end case;
    end if;

  end process s_regs_note_amps;

  note_amps_20_d <= note_amps_q(note_index_in) & '0' & x"000";

  step_amt <= attack_amt  when adsr_states_q(note_index_in) = E_ATTACK  else
              decay_amt   when adsr_states_q(note_index_in) = E_DECAY   else
              release_amt when adsr_states_q(note_index_in) = E_RELEASE else
              (others => '0');

  -- scale the step size
  u_step_scaler: scaler_unsigned
  generic map (
    WIDTH_DATA => ACC_WIDTH,
    WIDTH_GAIN => WIDTH_NOTE_GAIN
  )
  port map (
    input_word  => step_amt,
    gain_word   => note_amps_q(note_index_in),
    output_word => step_d
  );

  -- scale the sustain amount
  u_sustain_scaler: scaler_unsigned
  generic map (
    WIDTH_DATA => ACC_WIDTH,
    WIDTH_GAIN => ADSR_WIDTH
  )
  port map (
    input_word  => note_amps_20_d,
    gain_word   => sustain_amt,
    output_word => sustain_level_d
  );

  -- scale the note based on current amplitude
  u_out_gain_scaler: scaler
  generic map (
    WIDTH_DATA => DATA_WIDTH,
    WIDTH_GAIN => ACC_WIDTH
  )
  port map (
    input_word  => note_in,
    gain_word   => note_amps_acc(note_index_in),
    output_word => note_d
  );

end architecture rtl;