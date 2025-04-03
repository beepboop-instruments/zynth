----------------------------------------------------------------------------------
-- Company: beepboop
-- Engineer: Tyler Huddlesotn
-- 
-- Create Date: 04/02/2025
-- Design Name: Synthesizer Enginer
-- Module Name: Phase to Waveform Converter
-- Description: 
--   Given a phase index, produces ramp, saw, triangle, square, and sine waveforms.
--   Each waveform can be phase shifted and optionally mixed together into a single
--   output.
-- 
----------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library xil_defaultlib;
  use xil_defaultlib.synth_pkg.all;

entity phase_to_wave is
  generic (
    PHASE_WIDTH     : integer := WIDTH_PH_DATA;
    NOTE_GAIN_WIDTH : integer := WIDTH_NOTE_GAIN;
    DATA_WIDTH      : natural := WIDTH_WAVE_DATA;
    SIN_LUT_PH      : natural := 12
  );
  port (
    clk             : in  std_logic;
    rst             : in  std_logic;
    -- synth controls
    wfrm_amps       : in  t_wfrm_amp;
    wfrm_phs        : in  t_wfrm_ph;
    pulse_width     : in  unsigned(WIDTH_PULSE_WIDTH-1 downto 0);
    -- pipeline in
    note_index_in   : in  integer range I_LOWEST_NOTE to I_HIGHEST_NOTE;
    phase_in        : in  unsigned(PHASE_WIDTH-1 downto 0);
    note_amp_in     : in  unsigned(NOTE_GAIN_WIDTH-1 downto 0);
    cycle_start_in  : in  std_logic;
    -- pipeline out
    note_index_out  : out integer range I_LOWEST_NOTE to I_HIGHEST_NOTE;
    note_out        : out signed(DATA_WIDTH-1 downto 0);
    note_amp_out    : out unsigned(NOTE_GAIN_WIDTH-1 downto 0);
    cycle_start_out : out std_logic
  );
end entity;

architecture rtl of phase_to_wave is

  component sine_lut_full is
    generic (
      PHASE_WIDTH : natural := 12;
      SINE_WIDTH  : natural := 16
    );
    port (
      clk      : in  std_logic;
      phase    : in  std_logic_vector(PHASE_WIDTH-1 downto 0);
      sine_out : out signed(SINE_WIDTH-1 downto 0)
    );
  end component sine_lut_full;

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

  -- maximum output amplitude
  constant OUT_MAX  : signed(DATA_WIDTH-1 downto 0) := to_signed(2**(DATA_WIDTH-1) - 1, DATA_WIDTH);
  -- minimum output amplitude
  constant OUT_MIN  : signed(DATA_WIDTH-1 downto 0) := to_signed(2**(DATA_WIDTH-1), DATA_WIDTH);
  -- half of the maximum amplitude
  constant HALF_MAX : signed(DATA_WIDTH-1 downto 0) := OUT_MAX/2;

  -- sine phase shift to lookup table
  signal phase_sin_lut : std_logic_vector(DATA_WIDTH-1 downto DATA_WIDTH-SIN_LUT_PH);

  -- phase accumulators with offsets
  signal tri_ph_offset   : unsigned(DATA_WIDTH-1 downto 0);

  -- phase
  signal phase : unsigned(DATA_WIDTH-1 downto 0);

  -- phase shifts
  signal  pulse_ph,
          ramp_ph,
          saw_ph,
          tri_ph,
          sine_ph   : unsigned(DATA_WIDTH-1 downto 0);

  -- waveform amplitude
  signal  pulse_amp,
          ramp_amp,
          saw_amp,
          tri_amp,
          sine_amp  : unsigned(WIDTH_WAVE_GAIN-1 downto 0);

  -- waveform signals
  signal  pulse_d, pulse_scale_d, pulse_q,
          ramp_d,  ramp_scale_d,  ramp_q,
          saw_d,   saw_scale_d,   saw_q,
          tri_d,   tri_scale_d,   tri_q,
          sine_d,  sine_scale_d,  sine_q,
          sine_lookup_d                    : signed(DATA_WIDTH-1 downto 0);
  
  -- intermediate logic signals
  signal  tri_pre : unsigned(DATA_WIDTH-1 downto 0);

  -- mix signals
  signal  mix_d,
          mix_q        : signed(DATA_WIDTH-1 downto 0);

  -- note index pipeline
  signal note_index_q, note_index_q2   : integer range I_LOWEST_NOTE to I_HIGHEST_NOTE;

  -- cycle start pipeline
  signal cycle_start_q, cycle_start_q2 : std_logic;

  -- note amp pipeline
  signal note_amp_q, note_amp_q2       : unsigned(NOTE_GAIN_WIDTH-1 downto 0);

begin

  -- output assignments
  note_index_out  <= note_index_q2;
  note_out        <= mix_q;
  note_amp_out    <= note_amp_q2;
  cycle_start_out <= cycle_start_q2;

  -- phase shift assignments
  pulse_ph <= wfrm_phs(I_PULSE);
  ramp_ph  <= wfrm_phs(I_RAMP);
  saw_ph   <= wfrm_phs(I_SAW);
  tri_ph   <= wfrm_phs(I_TRI);
  sine_ph  <= wfrm_phs(I_SINE);

  phase  <= phase_in(PHASE_WIDTH-1 downto PHASE_WIDTH - DATA_WIDTH);

  -- waveform amplitude assignments
  pulse_amp <= wfrm_amps(I_PULSE);
  ramp_amp  <= wfrm_amps(I_RAMP);
  saw_amp   <= wfrm_amps(I_SAW);
  tri_amp   <= wfrm_amps(I_TRI);
  sine_amp  <= wfrm_amps(I_SINE);

  -- mix all waveforms
  mix_d <= pulse_q + ramp_q + saw_q + tri_q + sine_q;

  -- pwm phase to waveform logic
  pulse_d <= to_signed(0, DATA_WIDTH) when (pulse_amp = 0) else
             OUT_MAX when (phase + pulse_ph) < pulse_width else OUT_MIN;

  -- ramp phase to waveform logic
  ramp_d  <= to_signed(0, DATA_WIDTH) when (ramp_amp = 0) else
             signed(phase + 2**(DATA_WIDTH-1) + ramp_ph);

  -- saw phase to waveform logic
  saw_d   <= to_signed(0, DATA_WIDTH) when (saw_amp = 0) else
             signed(2**(DATA_WIDTH) - phase + saw_ph);

  -- triangle phase to waveform logic
  tri_ph_offset <= to_unsigned(0, DATA_WIDTH) when (tri_amp = 0) else
                   phase + tri_ph;
  tri_pre       <= tri_ph_offset sll 1 when tri_ph_offset(DATA_WIDTH-2) = '0' else not(tri_ph_offset sll 1);
  tri_d         <= signed(tri_pre) when tri_ph_offset(DATA_WIDTH-1) = '1' else 0 - signed(tri_pre);
  
  -- phase offset to sine lookup table
  phase_sin_lut <= std_logic_vector(
                      phase(DATA_WIDTH-1 downto DATA_WIDTH-SIN_LUT_PH)
                    + sine_ph(DATA_WIDTH-1 downto DATA_WIDTH-SIN_LUT_PH)
                    + 2**(SIN_LUT_PH-1));

  sine_d  <= to_signed(0, DATA_WIDTH) when (sine_amp = 0) else sine_lookup_d;

  -- sine phase to waveform lookup table
  u_sine_lut: sine_lut_full
  generic map (
    PHASE_WIDTH => SIN_LUT_PH,
    SINE_WIDTH  => DATA_WIDTH
    )
  port map(
    clk      => clk,
    phase    => phase_sin_lut,
    sine_out => sine_lookup_d
  );

  -- assignments to mixer
  u_pulse_scaler: scaler
  generic map (
    WIDTH_DATA => DATA_WIDTH,
    WIDTH_GAIN => WIDTH_WAVE_GAIN
  )
  port map (
    input_word  => pulse_d,
    gain_word   => pulse_amp,
    output_word => pulse_scale_d
  );
  
  u_ramp_scaler: scaler
  generic map (
    WIDTH_DATA => DATA_WIDTH,
    WIDTH_GAIN => WIDTH_WAVE_GAIN
  )
  port map (
    input_word  => ramp_d,
    gain_word   => ramp_amp,
    output_word => ramp_scale_d
  );
  
  u_saw_scaler: scaler
  generic map (
    WIDTH_DATA => DATA_WIDTH,
    WIDTH_GAIN => WIDTH_WAVE_GAIN
  )
  port map (
    input_word  => saw_d,
    gain_word   => saw_amp,
    output_word => saw_scale_d
  );
  
  u_tri_scaler: scaler
  generic map (
    WIDTH_DATA => DATA_WIDTH,
    WIDTH_GAIN => WIDTH_WAVE_GAIN
  )
  port map (
    input_word  => tri_d,
    gain_word   => tri_amp,
    output_word => tri_scale_d
  );
  
  u_sin_scaler: scaler
  generic map (
    WIDTH_DATA => DATA_WIDTH,
    WIDTH_GAIN => WIDTH_WAVE_GAIN
  )
  port map (
    input_word  => sine_d,
    gain_word   => sine_amp,
    output_word => sine_scale_d
  );

  -- synchronous registers
  s_regs: process(rst, clk)
  begin
    if (rst = '1') then
      pulse_q        <= (others => '0');
      ramp_q         <= (others => '0');
      saw_q          <= (others => '0');
      tri_q          <= (others => '0');
      sine_q         <= (others => '0');
      mix_q          <= (others => '0');
      note_index_q   <= 0;
      note_index_q2  <= 0;
      cycle_start_q  <= '0';
      cycle_start_q2 <= '0';
      note_amp_q     <= (others => '0');
      note_amp_q2    <= (others => '0');
    elsif (rising_edge(clk)) then
      pulse_q        <= pulse_scale_d;
      ramp_q         <= ramp_scale_d;
      saw_q          <= saw_scale_d;
      tri_q          <= tri_scale_d;
      sine_q         <= sine_scale_d;
      mix_q          <= mix_d;
      note_index_q   <= note_index_in;
      note_index_q2  <= note_index_q;
      cycle_start_q  <= cycle_start_in;
      cycle_start_q2 <= cycle_start_q;
      note_amp_q     <= note_amp_in;
      note_amp_q2    <= note_amp_q;
    end if;
  end process s_regs;

end architecture;
