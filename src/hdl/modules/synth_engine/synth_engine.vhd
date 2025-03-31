----------------------------------------------------------------------------------
-- Company: beepboop
-- Engineer: Tyler Huddleston
-- 
-- Create Date: 03/08/2025
-- Design Name: Synthesizer Engine
-- Module Name: Synthesizer Engine
-- Description: 
--   Provides an AXI-4 LITE interface to set controls to the synthesizer engine
--   and synthesized audio out.
-- 
----------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library xil_defaultlib;
  use xil_defaultlib.synth_pkg.all;
  use xil_defaultlib.music_note_pkg.all;

entity synth_engine is
  generic (
    -- AXI parameters
    C_S_AXI_DATA_WIDTH  : integer  := 32;
    C_S_AXI_ADDR_WIDTH  : integer  := 31;
    -- waveform parameters
    DATA_WIDTH     : natural := WIDTH_WAVE_DATA;
    OUT_DATA_WIDTH : natural := WIDTH_WAVE_DATA+8
  );
  port (
    -- clock and reset
    clk           : in std_logic;
    rst           : in std_logic;

    -- AXI control interface
    s_axi_awaddr  : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    s_axi_awprot  : in  std_logic_vector(2 downto 0);
    s_axi_awvalid : in  std_logic;
    s_axi_awready : out std_logic;
    s_axi_wdata   : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    s_axi_wstrb   : in  std_logic_vector(3 downto 0);
    s_axi_wvalid  : in  std_logic;
    s_axi_wready  : out std_logic;
    s_axi_bresp   : out std_logic_vector(1 downto 0);
    s_axi_bvalid  : out std_logic;
    s_axi_bready  : in  std_logic;
    s_axi_araddr  : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    s_axi_arprot  : in  std_logic_vector(2 downto 0);
    s_axi_arvalid : in  std_logic;
    s_axi_arready : out std_logic;
    s_axi_rdata   : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    s_axi_rresp   : out std_logic_vector(1 downto 0);
    s_axi_rvalid  : out std_logic;
    s_axi_rready  : in  std_logic;

    -- Digital audio output
    audio_out     : out std_logic_vector(OUT_DATA_WIDTH-1 downto 0)
  );
  end synth_engine;
  
architecture struct_synth_engine of synth_engine is

  component synth_axi_ctrl is
    generic (
      -- AXI parameters
      C_S_AXI_DATA_WIDTH  : integer  := 32;
      C_S_AXI_ADDR_WIDTH  : integer  := 31
    );
    port (
      -- synth controls out
      note_amps    : out t_note_amp;
      ph_inc_table : out t_ph_inc_lut;
      wfrm_amps    : out t_wfrm_amp;
      wfrm_phs     : out t_wfrm_ph;
      out_amp      : out unsigned(WIDTH_OUT_GAIN-1 downto 0);
      out_shift    : out unsigned(WIDTH_OUT_SHIFT-1 downto 0);
      pulse_width  : out unsigned(WIDTH_PULSE_WIDTH-1 downto 0);

      -- AXI control interface
      s_axi_aclk     : in  std_logic;
      s_axi_aresetn  : in  std_logic;
      s_axi_awaddr   : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
      s_axi_awprot   : in  std_logic_vector(2 downto 0);
      s_axi_awvalid  : in  std_logic;
      s_axi_awready  : out std_logic;
      s_axi_wdata    : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
      s_axi_wstrb    : in  std_logic_vector(3 downto 0);
      s_axi_wvalid   : in  std_logic;
      s_axi_wready   : out std_logic;
      s_axi_bresp    : out std_logic_vector(1 downto 0);
      s_axi_bvalid   : out std_logic;
      s_axi_bready   : in  std_logic;
      s_axi_araddr   : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
      s_axi_arprot   : in  std_logic_vector(2 downto 0);
      s_axi_arvalid  : in  std_logic;
      s_axi_arready  : out std_logic;
      s_axi_rdata    : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
      s_axi_rresp    : out std_logic_vector(1 downto 0);
      s_axi_rvalid   : out std_logic;
      s_axi_rready   : in  std_logic
    );
  end component synth_axi_ctrl;

  component waveform_generator is
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
  end component waveform_generator;

  component phase_accumulator is
    generic (
      PHASE_WIDTH : integer := 8 -- 8-bit phase index
    );
    port (
      clk         : in  std_logic;
      rst         : in  std_logic;
      phase_in    : in  unsigned(PHASE_WIDTH-1 downto 0); -- Phase input
      increment   : in  unsigned(PHASE_WIDTH-1 downto 0); -- Phase increment
      phase       : out unsigned(PHASE_WIDTH-1 downto 0)  -- Phase output
    );
  end component;

  component amp_gate is
    port (
      clk            : in std_logic;
      rst            : in std_logic;
      note_amp       : in  unsigned(WIDTH_NOTE_GAIN-1 downto 0);
      phase          : in  unsigned(WIDTH_PH_DATA-1 downto 0);
      note_amp_gated : out unsigned(WIDTH_NOTE_GAIN-1 downto 0)
    );
  end component;
  
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

  signal rst_n      : std_logic;
  signal clk1       : std_logic;
  signal rst1       : std_logic;

  signal wfrm_mixes_q : t_wave_data;
  signal wfrm_mix_d   : signed(DATA_WIDTH-1 downto 0);

  signal phase_d   : unsigned(WIDTH_PH_DATA-1 downto 0);
  signal phases_q  : t_ph_inc;

  signal note_amp_gated_d : unsigned(WIDTH_NOTE_GAIN-1 downto 0);
  signal note_amps_gated  : t_note_amp;

  signal ph_inc_table     : t_ph_inc_lut;
  signal note_amps        : t_note_amp;
  signal wfrm_amps        : t_wfrm_amp;
  signal wfrm_phs         : t_wfrm_ph;
  
  signal out_amp   : unsigned(WIDTH_OUT_GAIN-1 downto 0);
  signal out_shift : unsigned(WIDTH_OUT_SHIFT-1 downto 0);

  signal pulse_width : unsigned(WIDTH_PULSE_WIDTH-1 downto 0);

  signal notes_sum  : signed(OUT_DATA_WIDTH-1 downto 0);
  signal audio_out_mult : signed(OUT_DATA_WIDTH-1 downto 0);

  signal note_index, note_index_q, note_index_q0, note_index_q1 : integer range I_LOWEST_NOTE to I_HIGHEST_NOTE;

begin

  rst_n     <= not(rst);

  audio_out <= std_logic_vector(shift_left(audio_out_mult, to_integer(out_shift)));

  u_out_scaler: scaler
    generic map (
      WIDTH_DATA => OUT_DATA_WIDTH,
      WIDTH_GAIN => WIDTH_OUT_GAIN
    )
    port map (
      input_word  => notes_sum,
      gain_word   => out_amp,
      output_word => audio_out_mult
    );

  u_synth_axi_ctrl: synth_axi_ctrl
    generic map (
      -- Width of S_AXI data bus
      C_S_AXI_DATA_WIDTH => C_S_AXI_DATA_WIDTH,
      -- Width of S_AXI address bus
      C_S_AXI_ADDR_WIDTH => C_S_AXI_ADDR_WIDTH
    )
    port map (
      -- synth controls out
      note_amps    => note_amps,
      ph_inc_table => ph_inc_table,
      wfrm_amps    => wfrm_amps,
      wfrm_phs     => wfrm_phs,
      out_amp      => out_amp,
      out_shift    => out_shift,
      pulse_width  => pulse_width,

      -- AXI control interface
      s_axi_aclk    => clk,
      s_axi_aresetn => rst_n,
      s_axi_awaddr  => s_axi_awaddr,
      s_axi_awprot  => s_axi_awprot,
      s_axi_awvalid => s_axi_awvalid,
      s_axi_awready => s_axi_awready,
      s_axi_wdata   => s_axi_wdata,
      s_axi_wstrb   => s_axi_wstrb,
      s_axi_wvalid  => s_axi_wvalid,
      s_axi_wready  => s_axi_wready,
      s_axi_bresp   => s_axi_bresp,
      s_axi_bvalid  => s_axi_bvalid,
      s_axi_bready  => s_axi_bready,
      s_axi_araddr  => s_axi_araddr,
      s_axi_arprot  => s_axi_arprot,
      s_axi_arvalid => s_axi_arvalid,
      s_axi_arready => s_axi_arready,
      s_axi_rdata   => s_axi_rdata,
      s_axi_rresp   => s_axi_rresp,
      s_axi_rvalid  => s_axi_rvalid,
      s_axi_rready  => s_axi_rready
    );
  
  s_counter_index: process(clk, rst)
    begin
      if(rst = '1') then
        -- reset registes
        wfrm_mixes_q    <= (others => (others => '0'));
        note_index      <= I_LOWEST_NOTE;
        note_index_q0   <= I_LOWEST_NOTE;
        note_index_q1   <= I_LOWEST_NOTE;
        phases_q        <= (others => (others => '0'));
        note_amps_gated <= (others => (others => '0'));
      elsif (rising_edge(clk)) then
        -- clock registers
        note_index_q0 <= note_index;
        note_index_q1 <= note_index_q0;
        wfrm_mixes_q(note_index_q) <= wfrm_mix_d;
        phases_q(note_index_q1) <= phase_d;

        -- change amplitude at the start of a cycle
        if (phases_q(note_index_q0) < ph_inc_table(note_index_q0)) then
          note_amps_gated(note_index_q0) <= note_amps(note_index_q0);
        end if;

        -- cycle through each note
        if note_index < I_HIGHEST_NOTE then
          note_index <= note_index + 1;
        else
          note_index <= I_LOWEST_NOTE;
        end if;

      end if;
    end process;
  
  u_phase_gen: phase_accumulator
  generic map (
    PHASE_WIDTH => WIDTH_PH_DATA
  )
  port map (
    clk         => clk,
    rst         => rst,
    phase_in    => phases_q(note_index_q0),
    increment   => ph_inc_table(note_index_q0),
    phase       => phase_d
  );
  
  u_waveform_gen: waveform_generator
    generic map (
      DATA_WIDTH => DATA_WIDTH,
      SIN_LUT_PH => 12
    )
    port map (      
      clk      => clk,
      phase    => phases_q(note_index_q0)(31 downto 16),
      -- note indexes
      index_in  => note_index_q0,
      index_out => note_index_q,
      -- pulse width modulation
      pulse_amp => wfrm_amps(I_PULSE),
      pulse_ph  => wfrm_phs(I_PULSE),
      duty      => pulse_width,
      pulse     => open,
      -- ramp
      ramp_amp => wfrm_amps(I_RAMP),
      ramp_ph  => wfrm_phs(I_RAMP),
      ramp     => open,
      -- saw
      saw_amp  => wfrm_amps(I_SAW),
      saw_ph   => wfrm_phs(I_SAW),
      saw      => open,
      -- triangle
      tri_amp  => wfrm_amps(I_TRI),
      tri_ph   => wfrm_phs(I_TRI),
      tri      => open,
      -- sine
      sine_amp => wfrm_amps(I_SINE),
      sine_ph  => wfrm_phs(I_SINE),
      sine     => open,
      -- waveform mixed output
      mix_amp  => note_amps_gated(note_index_q0),
      mix_out  => wfrm_mix_d
    );

  -- mix all notes together for polyphonic
  u_sum_mixes: synth_note_mixer
    generic map (
      I_LOW       => I_LOWEST_NOTE,
      I_HIGH      => I_HIGHEST_NOTE,
      IN_WIDTH    => DATA_WIDTH,
      OUT_WIDTH   => OUT_DATA_WIDTH
    )
    port map (
      in_array => wfrm_mixes_q,
      out_sum  => notes_sum
    );

end struct_synth_engine;