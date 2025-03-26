----------------------------------------------------------------------------------
-- Company: beepboop
-- Engineer: Tyler Huddlesotn
-- 
-- Create Date: 03/01/2025
-- Design Name: Synthesizer Enginer
-- Module Name: Waveform Generator
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

entity waveform_generator is
  generic (
    DATA_WIDTH : natural := 16;
    SIN_LUT_PH : natural := 12
  );
  port (
    clk       : in  std_logic;
    phase     : in  unsigned(DATA_WIDTH-1 downto 0);
    -- note indexes
    index_in  : in  integer range I_LOWEST_NOTE to I_HIGHEST_NOTE;
    index_out : out integer range I_LOWEST_NOTE to I_HIGHEST_NOTE;
    -- pulse width modulation
    pulse_amp : in  unsigned(WIDTH_WAVE_GAIN-1 downto 0);
    pulse_ph  : in  unsigned(DATA_WIDTH-1 downto 0);
    duty      : in  unsigned(WIDTH_PULSE_WIDTH-1 downto 0);
    pulse     : out signed(DATA_WIDTH-1 downto 0);
    -- ramp
    ramp_amp  : in  unsigned(WIDTH_WAVE_GAIN-1 downto 0);
    ramp_ph   : in  unsigned(DATA_WIDTH-1 downto 0);
    ramp      : out signed(DATA_WIDTH-1 downto 0);
    -- saw
    saw_amp   : in  unsigned(WIDTH_WAVE_GAIN-1 downto 0);
    saw_ph    : in  unsigned(DATA_WIDTH-1 downto 0);
    saw       : out signed(DATA_WIDTH-1 downto 0);
    -- triangle
    tri_amp   : in  unsigned(WIDTH_WAVE_GAIN-1 downto 0);
    tri_ph    : in  unsigned(DATA_WIDTH-1 downto 0);
    tri       : out signed(DATA_WIDTH-1 downto 0);
    -- sine
    sine_amp  : in  unsigned(WIDTH_WAVE_GAIN-1 downto 0);
    sine_ph   : in  unsigned(DATA_WIDTH-1 downto 0);
    sine      : out signed(DATA_WIDTH-1 downto 0);
    -- mixed output
    mix_amp   : in  unsigned(WIDTH_NOTE_GAIN-1 downto 0);
    mix_out   : out signed(DATA_WIDTH-1 downto 0)
  );
end waveform_generator;

architecture behavioral of waveform_generator is

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
  
  -- Look up table for adjusting gain based on number of waveforms enabled to mixer
  type gain_lut_type is array (0 to 5) of unsigned(DATA_WIDTH-1 downto 0);
  signal gain_lut: gain_lut_type := (
    0  => to_unsigned(0, DATA_WIDTH),                                     -- 0
    1  => to_unsigned(2**(DATA_WIDTH)-1, DATA_WIDTH),                   -- 1
    2  => to_unsigned(2**(DATA_WIDTH-1), DATA_WIDTH),                     -- 1/2
    3  => to_unsigned(2**(DATA_WIDTH-2) + 2**(DATA_WIDTH-4), DATA_WIDTH), -- 1/3
    4  => to_unsigned(2**(DATA_WIDTH-3), DATA_WIDTH),                     -- 1/4
    5  => to_unsigned(2**(DATA_WIDTH-4) + 2**(DATA_WIDTH-5), DATA_WIDTH), -- 1/5
    others => to_unsigned(1, DATA_WIDTH)  -- Smallest value to prevent zero
  );

  -- maximum output amplitude
  constant OUT_MAX  : signed(DATA_WIDTH-1 downto 0) := to_signed(2**(DATA_WIDTH-1) - 1, DATA_WIDTH);
  -- minimum output amplitude
  constant OUT_MIN  : signed(DATA_WIDTH-1 downto 0) := to_signed(2**(DATA_WIDTH-1), DATA_WIDTH);
  -- half of the maximum amplitude
  constant HALF_MAX : signed(DATA_WIDTH-1 downto 0) := OUT_MAX/2;
  
  -- preliminary logic signals
  signal tri_pre   : unsigned(DATA_WIDTH-1 downto 0);
  signal tri_out   : signed(DATA_WIDTH-1  downto 0);
  signal ramp_out  : signed(DATA_WIDTH-1 downto 0);
  signal saw_out   : signed(DATA_WIDTH-1 downto 0);
  signal pulse_out : signed(DATA_WIDTH-1 downto 0);
  signal sin_out   : signed(DATA_WIDTH-1 downto 0);
  
  -- signals to mixer
  signal ramp_mix,  ramp_mix_q  : signed(DATA_WIDTH-1 downto 0);
  signal saw_mix,   saw_mix_q   : signed(DATA_WIDTH-1 downto 0);
  signal tri_mix,   tri_mix_q   : signed(DATA_WIDTH-1 downto 0);
  signal pulse_mix, pulse_mix_q : signed(DATA_WIDTH-1 downto 0);
  signal sin_mix,   sin_mix_q   : signed(DATA_WIDTH-1 downto 0);
  
  signal phase_q :  unsigned(DATA_WIDTH-1 downto 0);

  signal mix_pre_sum,   mix_pre_sum_q    : signed(DATA_WIDTH-1 downto 0);
  signal mix_pre_scale, mix_pre_scale_q  : signed(DATA_WIDTH-1 downto 0);
  signal mix_out_int                     : signed(DATA_WIDTH-1 downto 0);

  signal mix_amp_q, mix_amp_q2, mix_amp_q3, mix_amp_q4 : unsigned(WIDTH_NOTE_GAIN-1 downto 0);
  
  signal idx_q, idx_q2, idx_q3, idx_q4 : integer range I_LOWEST_NOTE to I_HIGHEST_NOTE;
  
  -- enables to mixer
  signal pulse_en  : std_logic;
  signal ramp_en   : std_logic;
  signal saw_en    : std_logic;
  signal tri_en    : std_logic;
  signal sine_en   : std_logic;
  signal ramp_en2  : unsigned(1 downto 0);
  signal saw_en2   : unsigned(1 downto 0);
  signal tri_en2   : unsigned(1 downto 0);
  signal pulse_en2 : unsigned(1 downto 0);
  signal sine_en2  : unsigned(1 downto 0);
  
  -- count of how many signals enabled
  signal shift_amt : integer range 0 to 5;
  
  -- sine phase shift to lookup table
  signal phase_sin_lut : std_logic_vector(DATA_WIDTH-1 downto DATA_WIDTH-SIN_LUT_PH);
  
  -- phase accumulators with offsets
  signal tri_ph_offset   : unsigned(DATA_WIDTH-1 downto 0);
  signal pulse_ph_offset : unsigned(DATA_WIDTH-1 downto 0);

begin

  -- output assignments
  ramp      <= ramp_out;
  saw       <= saw_out;
  tri       <= tri_out;
  pulse     <= pulse_out;
  sine      <= sin_out;
  mix_out   <= mix_out_int;
  index_out <= idx_q4;

  process(clk)
    begin
      if (rising_edge(clk)) then
        phase_q <= phase;

        pulse_mix_q <= pulse_mix;
        ramp_mix_q  <= ramp_mix;
        saw_mix_q   <= saw_mix;
        tri_mix_q   <= tri_mix;
        sin_mix_q   <= sin_mix;

        mix_pre_sum_q   <= mix_pre_sum;
        mix_pre_scale_q <= mix_pre_scale;

        mix_amp_q  <= mix_amp;
        mix_amp_q2 <= mix_amp_q;
        mix_amp_q3 <= mix_amp_q2;
        mix_amp_q4 <= mix_amp_q3;

        idx_q    <= index_in;
        idx_q2   <= idx_q;
        idx_q3   <= idx_q2;
        idx_q4   <= idx_q3;
      end if;
  end process;
  
  -- rescale mixer output based on number of waveforms enabled
  u_out_sum_scalar: scaler
    generic map (
      WIDTH_DATA => DATA_WIDTH,
      WIDTH_GAIN => DATA_WIDTH
    )
    port map (
      input_word  => mix_pre_sum_q,
      gain_word   => gain_lut(shift_amt),
      output_word => mix_pre_scale
    );
  
  u_out_gain_scaler: scaler
    generic map (
      WIDTH_DATA => DATA_WIDTH,
      WIDTH_GAIN => WIDTH_NOTE_GAIN
    )
    port map (
      input_word  => mix_pre_scale_q,
      gain_word   => mix_amp_q4,
      output_word => mix_out_int
    );

  -- preliminary logic
  ramp_out  <= signed(phase_q + 2**(DATA_WIDTH-1) + ramp_ph);
  saw_out   <= signed(2**(DATA_WIDTH) - phase_q + saw_ph);
  tri_ph_offset <= phase_q + tri_ph;
  tri_pre   <= tri_ph_offset sll 1 when tri_ph_offset(DATA_WIDTH-2) = '0' else not(tri_ph_offset sll 1);
  tri_out   <= signed(tri_pre) when tri_ph_offset(DATA_WIDTH-1) = '1' else 0 - signed(tri_pre);
  pulse_ph_offset <= phase_q + pulse_ph;
  pulse_out <= OUT_MAX when pulse_ph_offset < duty else OUT_MIN;
  
  -- determine if waveforms are enabled
  pulse_en <= '1' when pulse_amp > 0 else '0';
  ramp_en  <= '1' when ramp_amp  > 0 else '0';
  saw_en   <= '1' when saw_amp   > 0 else '0';
  tri_en   <= '1' when tri_amp   > 0 else '0';
  sine_en  <= '1' when sine_amp  > 0 else '0';
  
  -- assignments to mixer
  u_pulse_scaler: scaler
    generic map (
      WIDTH_DATA => DATA_WIDTH,
      WIDTH_GAIN => WIDTH_WAVE_GAIN
    )
    port map (
      input_word  => pulse_out,
      gain_word   => pulse_amp,
      output_word => pulse_mix
    );
  
  u_ramp_scaler: scaler
    generic map (
      WIDTH_DATA => DATA_WIDTH,
      WIDTH_GAIN => WIDTH_WAVE_GAIN
    )
    port map (
      input_word  => ramp_out,
      gain_word   => ramp_amp,
      output_word => ramp_mix
    );
  
  u_saw_scaler: scaler
    generic map (
      WIDTH_DATA => DATA_WIDTH,
      WIDTH_GAIN => WIDTH_WAVE_GAIN
    )
    port map (
      input_word  => saw_out,
      gain_word   => saw_amp,
      output_word => saw_mix
    );
  
  u_tri_scaler: scaler
    generic map (
      WIDTH_DATA => DATA_WIDTH,
      WIDTH_GAIN => WIDTH_WAVE_GAIN
    )
    port map (
      input_word  => tri_out,
      gain_word   => tri_amp,
      output_word => tri_mix
    );
  
  u_sin_scaler: scaler
    generic map (
      WIDTH_DATA => DATA_WIDTH,
      WIDTH_GAIN => WIDTH_WAVE_GAIN
    )
    port map (
      input_word  => sin_out,
      gain_word   => sine_amp,
      output_word => sin_mix
    );
  
  -- mix all waveforms
  mix_pre_sum <=   ramp_mix_q
                 + saw_mix_q
                 + tri_mix_q
                 + pulse_mix_q
                 + sin_mix_q;
  
  -- use at least two bits for addition without sign issues
  ramp_en2  <= '0' & ramp_en;
  saw_en2   <= '0' & saw_en;
  tri_en2   <= '0' & tri_en;
  pulse_en2 <= '0' & pulse_en;
  sine_en2  <= '0' & sine_en;
  
  -- count number of waveforms enabled
  shift_amt <=   to_integer(ramp_en2)
               + to_integer(saw_en2)
               + to_integer(tri_en2)
               + to_integer(pulse_en2)
               + to_integer(sine_en2);
  
  -- phase offset to sine lookup table
  phase_sin_lut <= std_logic_vector(
                      phase_q(DATA_WIDTH-1 downto DATA_WIDTH-SIN_LUT_PH)
                    + sine_ph(DATA_WIDTH-1 downto DATA_WIDTH-SIN_LUT_PH)
                    + 2**(SIN_LUT_PH-1));

  -- determine sine waveform from lookup table
  u_sine_lut: sine_lut_full
  generic map (
    PHASE_WIDTH => SIN_LUT_PH,
    SINE_WIDTH  => DATA_WIDTH
    )
  port map(
    clk      => clk,
    phase    => phase_sin_lut,
    sine_out => sin_out
  );

end behavioral;
