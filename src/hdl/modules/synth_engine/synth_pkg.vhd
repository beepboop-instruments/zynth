----------------------------------------------------------------------------------
-- Company: beepboop
-- Engineer: Tyler Huddleston
-- 
-- Create Date: 03/22/2025
-- Design Name: Synthesizer Engine
-- Module Name: Synthesizer Package
-- Description: 
--   Contains constant and type definitions for the the synthesizer engine.
-- 
----------------------------------------------------------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.ALL;
  use IEEE.NUMERIC_STD.ALL;

package synth_pkg is
  constant SYNTH_ENG_REV  : std_logic_vector := x"00000001";
  constant SYNTH_ENG_DATE : std_logic_vector := x"03302025";

  -- memmory-mapped address definitions
  constant OFFSET_PULSE_WIDTH_REG : std_logic_vector := "0000000";
  constant OFFSET_PULSE_REG       : std_logic_vector := "0000001";
  constant OFFSET_RAMP_REG        : std_logic_vector := "0000010";
  constant OFFSET_SAW_REG         : std_logic_vector := "0000011";
  constant OFFSET_TRI_REG         : std_logic_vector := "0000100";
  constant OFFSET_SINE_REG        : std_logic_vector := "0000101";
  constant OFFSET_GAIN_SHIFT_REG  : std_logic_vector := "0001000";
  constant OFFSET_GAIN_SCALE_REG  : std_logic_vector := "0001001";
  constant OFFSET_REV_REG         : std_logic_vector := "1111000";
  constant OFFSET_DATE_REG        : std_logic_vector := "1111001";
  constant OFFSET_WRAPBACK_REG    : std_logic_vector := "1111111";

  -- vector size definitions
  constant WIDTH_WAVE_DATA   : natural := 16;
  constant WIDTH_PH_DATA     : natural := 32;
  constant WIDTH_NOTE_GAIN   : natural := 7;
  constant WIDTH_WAVE_GAIN   : natural := 7;
  constant WIDTH_OUT_GAIN    : natural := 7;
  constant WIDTH_OUT_SHIFT   : natural := 5;
  constant WIDTH_PULSE_WIDTH : natural := 16;

  constant NUM_WFRMS       : natural := 5;
  constant NUM_NOTES       : natural := 128;
  constant I_LOWEST_NOTE   : natural := 0;
  constant I_HIGHEST_NOTE  : natural := I_LOWEST_NOTE + NUM_NOTES - 1;

  -- waveform indexes
  constant I_PULSE : natural := 0;
  constant I_RAMP  : natural := 1;
  constant I_SAW   : natural := 2;
  constant I_TRI   : natural := 3;
  constant I_SINE  : natural := 4;

  -- array data types
  type t_ph_inc_lut  is array (0 to 127) of unsigned(WIDTH_PH_DATA-1 downto 0);
  type t_ph_inc      is array (I_LOWEST_NOTE to I_HIGHEST_NOTE) of unsigned(WIDTH_PH_DATA-1 downto 0);
  type t_wave_data   is array (I_LOWEST_NOTE to I_HIGHEST_NOTE) of signed(WIDTH_WAVE_DATA-1 downto 0);
  type t_note_amp    is array (0 to 127) of unsigned(WIDTH_NOTE_GAIN-1 downto 0);
  type t_wfrm_amp    is array (0 to NUM_WFRMS-1) of unsigned(WIDTH_WAVE_GAIN-1 downto 0);
  type t_wfrm_ph     is array (0 to NUM_WFRMS-1) of unsigned(WIDTH_WAVE_DATA-1 downto 0);

end synth_pkg;

package body synth_pkg is
    -- No implementation needed for a package with only constants
end synth_pkg;
