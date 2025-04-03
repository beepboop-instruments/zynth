----------------------------------------------------------------------------------
-- Company: beepboop
-- Engineer: Tyler Huddleston
-- 
-- Create Date: 03/01/2025
-- Design Name: Synthesizer Engine
-- Module Name: Phase Accumulator
--
-- Description:
--   Increments a circular counter by a given phase increment.
--
-- Revision:
-- 04/01/2025 - modifications for pipelined datapath
-- 
----------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

  library xil_defaultlib;
    use xil_defaultlib.synth_pkg.all;

entity phase_accumulator is
  generic (
    PHASE_WIDTH     : integer := WIDTH_PH_DATA;
    NOTE_GAIN_WIDTH : integer := WIDTH_NOTE_GAIN
  );
  port (
    clk             : in  std_logic;
    rst             : in  std_logic;
    -- synth controls
    phase_incs      : in  t_ph_inc_lut;
    note_amps       : in  t_note_amp;
    -- pipeline out
    note_index_out  : out integer range I_LOWEST_NOTE to I_HIGHEST_NOTE;
    phase_out       : out unsigned(PHASE_WIDTH-1 downto 0);
    note_amp_out    : out unsigned(NOTE_GAIN_WIDTH-1 downto 0);
    cycle_start_out : out std_logic
  );
end entity;

architecture rtl of phase_accumulator is

  -- note index regs
  signal  note_index_d,
          note_index_q,
          note_index_q2 : integer range I_LOWEST_NOTE to I_HIGHEST_NOTE;
  
  -- phase index
  signal  phase_index_d,
          phase_index_q : integer range 116 to 127;

  -- phase
  signal  phase_d,
          phase_q,
          phase_inc_lookup,
          phase_inc_shifted,
          phase_reg_lookup   : unsigned(PHASE_WIDTH-1 downto 0);

  -- phase register table
  signal  phase_regs : t_ph_inc;

  -- note amplitude
  signal  note_amp_lookup_d,
          note_amp_lookup_q   : unsigned(NOTE_GAIN_WIDTH-1 downto 0);
  
  -- start of cycle
  signal cycle_start_d,
         cycle_start_q   : std_logic;

  -- shift amount
  signal  shift_amt : integer range 0 to 10;

begin

  -- output assignments
  note_index_out  <= note_index_q2;
  phase_out       <= phase_q;
  note_amp_out    <= note_amp_lookup_q;
  cycle_start_out <= cycle_start_q;

  -- index into registers
  phase_inc_lookup  <= phase_incs(phase_index_q);
  phase_reg_lookup  <= phase_regs(note_index_q);
  note_amp_lookup_d <= note_amps(note_index_q);

  -- shift phase increment lookup
  shift_amt <= 10 when note_index_q <   8 else
                9 when note_index_q <  20 else
                8 when note_index_q <  32 else
                7 when note_index_q <  44 else
                6 when note_index_q <  56 else
                5 when note_index_q <  68 else
                4 when note_index_q <  80 else
                3 when note_index_q <  92 else
                2 when note_index_q < 104 else
                1 when note_index_q < 116 else
                0;
  phase_inc_shifted <= shift_right(phase_inc_lookup, shift_amt);

  -- increment phase
  phase_d <= phase_reg_lookup + phase_inc_shifted;

  -- synchronous counters
  s_counter: process(note_index_q, phase_index_q)
  begin
    -- note index cyclical counter over note range
    if note_index_q < I_HIGHEST_NOTE then
      note_index_d <= note_index_q + 1;
      -- phase index cyclical counter from 116 to 127
      if phase_index_q < 127 then
        phase_index_d <= phase_index_q + 1;
      else
        phase_index_d <= 116;
      end if;
    else
      note_index_d  <= I_LOWEST_NOTE;
      phase_index_d <= 120;
    end if;
  end process s_counter;
  
  -- check for start of cycle
  s_start_of_cycle: process(phase_inc_shifted, phase_d)
  begin
    cycle_start_d <= '0';
    if (phase_d < phase_inc_shifted) then
      cycle_start_d <= '1';
    end if;
  end process s_start_of_cycle;

  -- synchronous registers
  s_regs: process(clk, rst)
  begin
    if (rst = '1') then
      note_index_q      <= I_LOWEST_NOTE;
      note_index_q2     <= I_LOWEST_NOTE;
      phase_index_q     <= 120;
      phase_q           <= (others => '0');
      phase_regs        <= (others => (others => '0'));
      note_amp_lookup_q <= (others => '0');
      cycle_start_q     <= '0';
    elsif rising_edge(clk) then
      note_index_q              <= note_index_d;
      note_index_q2             <= note_index_q;
      phase_index_q             <= phase_index_d;
      phase_q                   <= phase_d;
      phase_regs(note_index_q2) <= phase_q;
      note_amp_lookup_q         <= note_amp_lookup_d;
      cycle_start_q             <= cycle_start_d;
    end if;
  end process s_regs;

end architecture;
