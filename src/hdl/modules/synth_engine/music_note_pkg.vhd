----------------------------------------------------------------------------------
-- Company: beepboop
-- Engineer: Tyler Huddleston
-- 
-- Create Date: 02/28/2025
-- Design Name: Synthesizer Engine
-- Module Name: Music Note Package
-- Description: 
--   Contains constant and type definitions for music notes.
-- 
----------------------------------------------------------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.ALL;
  use IEEE.NUMERIC_STD.ALL;

library xil_defaultlib;
  use xil_defaultlib.synth_pkg.all;

package music_note_pkg is

  -- note frequency word definitions
  constant NOTE_WORD_C_0   : unsigned := x"0002be4b";
  constant NOTE_WORD_Db_0  : unsigned := x"0002e80e";
  constant NOTE_WORD_D_0   : unsigned := x"0003144c";
  constant NOTE_WORD_Eb_0  : unsigned := x"0003432c";
  constant NOTE_WORD_E_0   : unsigned := x"000374d6";
  constant NOTE_WORD_F_0   : unsigned := x"0003a973";
  constant NOTE_WORD_Gb_0  : unsigned := x"0003e132";
  constant NOTE_WORD_G_0   : unsigned := x"00041c41";
  constant NOTE_WORD_Ab_0  : unsigned := x"00045ad3";
  constant NOTE_WORD_A_0   : unsigned := x"00049d1d";
  constant NOTE_WORD_Bb_0  : unsigned := x"0004e359";
  constant NOTE_WORD_B_0   : unsigned := x"00052dc2";
  constant NOTE_WORD_C_1   : unsigned := x"00057c97";
  constant NOTE_WORD_Db_1  : unsigned := x"0005d01c";
  constant NOTE_WORD_D_1   : unsigned := x"00062899";
  constant NOTE_WORD_Eb_1  : unsigned := x"00068659";
  constant NOTE_WORD_E_1   : unsigned := x"0006e9ac";
  constant NOTE_WORD_F_1   : unsigned := x"000752e7";
  constant NOTE_WORD_Gb_1  : unsigned := x"0007c264";
  constant NOTE_WORD_G_1   : unsigned := x"00083882";
  constant NOTE_WORD_Ab_1  : unsigned := x"0008b5a6";
  constant NOTE_WORD_A_1   : unsigned := x"00093a3b";
  constant NOTE_WORD_Bb_1  : unsigned := x"0009c6b2";
  constant NOTE_WORD_B_1   : unsigned := x"000a5b84";
  constant NOTE_WORD_C_2   : unsigned := x"000af92e";
  constant NOTE_WORD_Db_2  : unsigned := x"000ba039";
  constant NOTE_WORD_D_2   : unsigned := x"000c5133";
  constant NOTE_WORD_Eb_2  : unsigned := x"000d0cb3";
  constant NOTE_WORD_E_2   : unsigned := x"000dd359";
  constant NOTE_WORD_F_2   : unsigned := x"000ea5cf";
  constant NOTE_WORD_Gb_2  : unsigned := x"000f84c8";
  constant NOTE_WORD_G_2   : unsigned := x"00107104";
  constant NOTE_WORD_Ab_2  : unsigned := x"00116b4c";
  constant NOTE_WORD_A_2   : unsigned := x"00127476";
  constant NOTE_WORD_Bb_2  : unsigned := x"00138d65";
  constant NOTE_WORD_B_2   : unsigned := x"0014b708";
  constant NOTE_WORD_C_3   : unsigned := x"0015f25d";
  constant NOTE_WORD_Db_3  : unsigned := x"00174073";
  constant NOTE_WORD_D_3   : unsigned := x"0018a267";
  constant NOTE_WORD_Eb_3  : unsigned := x"001a1966";
  constant NOTE_WORD_E_3   : unsigned := x"001ba6b2";
  constant NOTE_WORD_F_3   : unsigned := x"001d4b9e";
  constant NOTE_WORD_Gb_3  : unsigned := x"001f0991";
  constant NOTE_WORD_G_3   : unsigned := x"0020e209";
  constant NOTE_WORD_Ab_3  : unsigned := x"0022d699";
  constant NOTE_WORD_A_3   : unsigned := x"0024e8ed";
  constant NOTE_WORD_Bb_3  : unsigned := x"00271aca";
  constant NOTE_WORD_B_3   : unsigned := x"00296e10";
  constant NOTE_WORD_C_4   : unsigned := x"002be4bb";
  constant NOTE_WORD_Db_4  : unsigned := x"002e80e7";
  constant NOTE_WORD_D_4   : unsigned := x"003144ce";
  constant NOTE_WORD_Eb_4  : unsigned := x"003432cd";
  constant NOTE_WORD_E_4   : unsigned := x"00374d65";
  constant NOTE_WORD_F_4   : unsigned := x"003a973d";
  constant NOTE_WORD_Gb_4  : unsigned := x"003e1323";
  constant NOTE_WORD_G_4   : unsigned := x"0041c413";
  constant NOTE_WORD_Ab_4  : unsigned := x"0045ad33";
  constant NOTE_WORD_A_4   : unsigned := x"0049d1db";
  constant NOTE_WORD_Bb_4  : unsigned := x"004e3594";
  constant NOTE_WORD_B_4   : unsigned := x"0052dc20";
  constant NOTE_WORD_C_5   : unsigned := x"0057c977";
  constant NOTE_WORD_Db_5  : unsigned := x"005d01ce";
  constant NOTE_WORD_D_5   : unsigned := x"0062899c";
  constant NOTE_WORD_Eb_5  : unsigned := x"0068659a";
  constant NOTE_WORD_E_5   : unsigned := x"006e9aca";
  constant NOTE_WORD_F_5   : unsigned := x"00752e7a";
  constant NOTE_WORD_Gb_5  : unsigned := x"007c2647";
  constant NOTE_WORD_G_5   : unsigned := x"00838826";
  constant NOTE_WORD_Ab_5  : unsigned := x"008b5a66";
  constant NOTE_WORD_A_5   : unsigned := x"0093a3b6";
  constant NOTE_WORD_Bb_5  : unsigned := x"009c6b29";
  constant NOTE_WORD_B_5   : unsigned := x"00a5b840";
  constant NOTE_WORD_C_6   : unsigned := x"00af92ee";
  constant NOTE_WORD_Db_6  : unsigned := x"00ba039d";
  constant NOTE_WORD_D_6   : unsigned := x"00c51339";
  constant NOTE_WORD_Eb_6  : unsigned := x"00d0cb35";
  constant NOTE_WORD_E_6   : unsigned := x"00dd3595";
  constant NOTE_WORD_F_6   : unsigned := x"00ea5cf4";
  constant NOTE_WORD_Gb_6  : unsigned := x"00f84c8e";
  constant NOTE_WORD_G_6   : unsigned := x"0107104d";
  constant NOTE_WORD_Ab_6  : unsigned := x"0116b4cd";
  constant NOTE_WORD_A_6   : unsigned := x"0127476c";
  constant NOTE_WORD_Bb_6  : unsigned := x"0138d653";
  constant NOTE_WORD_B_6   : unsigned := x"014b7081";
  constant NOTE_WORD_C_7   : unsigned := x"015f25dc";
  constant NOTE_WORD_Db_7  : unsigned := x"0174073a";
  constant NOTE_WORD_D_7   : unsigned := x"018a2672";
  constant NOTE_WORD_Eb_7  : unsigned := x"01a1966a";
  constant NOTE_WORD_E_7   : unsigned := x"01ba6b2a";
  constant NOTE_WORD_F_7   : unsigned := x"01d4b9e8";
  constant NOTE_WORD_Gb_7  : unsigned := x"01f0991d";
  constant NOTE_WORD_G_7   : unsigned := x"020e209b";
  constant NOTE_WORD_Ab_7  : unsigned := x"022d699b";
  constant NOTE_WORD_A_7   : unsigned := x"024e8ed9";
  constant NOTE_WORD_Bb_7  : unsigned := x"0271aca6";
  constant NOTE_WORD_B_7   : unsigned := x"0296e102";
  constant NOTE_WORD_C_8   : unsigned := x"02be4bb8";
  constant NOTE_WORD_Db_8  : unsigned := x"02e80e74";
  constant NOTE_WORD_D_8   : unsigned := x"03144ce4";
  constant NOTE_WORD_Eb_8  : unsigned := x"03432cd5";
  constant NOTE_WORD_E_8   : unsigned := x"0374d655";
  constant NOTE_WORD_F_8   : unsigned := x"03a973d0";
  constant NOTE_WORD_Gb_8  : unsigned := x"03e1323b";
  constant NOTE_WORD_G_8   : unsigned := x"041c4136";
  constant NOTE_WORD_Ab_8  : unsigned := x"045ad337";
  constant NOTE_WORD_A_8   : unsigned := x"049d1db2";
  constant NOTE_WORD_Bb_8  : unsigned := x"04e3594c";
  constant NOTE_WORD_B_8   : unsigned := x"052dc205";
  constant NOTE_WORD_C_9   : unsigned := x"057c9770";
  constant NOTE_WORD_Db_9  : unsigned := x"05d01ce8";
  constant NOTE_WORD_D_9   : unsigned := x"062899c8";
  constant NOTE_WORD_Eb_9  : unsigned := x"068659ab";
  constant NOTE_WORD_E_9   : unsigned := x"06e9acaa";
  constant NOTE_WORD_F_9   : unsigned := x"0752e7a0";
  constant NOTE_WORD_Gb_9  : unsigned := x"07c26476";
  constant NOTE_WORD_G_9   : unsigned := x"0838826c";
  constant NOTE_WORD_Ab_9  : unsigned := x"08b5a66e";
  constant NOTE_WORD_A_9   : unsigned := x"093a3b65";
  constant NOTE_WORD_Bb_9  : unsigned := x"09c6b298";
  constant NOTE_WORD_B_9   : unsigned := x"0a5b840a";
  constant NOTE_WORD_C_10  : unsigned := x"0af92ee0";
  constant NOTE_WORD_Db_10 : unsigned := x"0ba039d0";
  constant NOTE_WORD_D_10  : unsigned := x"0c513391";
  constant NOTE_WORD_Eb_10 : unsigned := x"0d0cb357";
  constant NOTE_WORD_E_10  : unsigned := x"0dd35954";
  constant NOTE_WORD_F_10  : unsigned := x"0ea5cf40";
  constant NOTE_WORD_Gb_10 : unsigned := x"0f84c8ec";
  constant NOTE_WORD_G_10  : unsigned := x"107104d9";

  -- phase increment lookup table array
  constant ph_inc_lut : t_ph_inc_lut := (
    -- since frequency doubles every 12 notes, we can just keep the 12 largest
    -- and left shift them as needed to conserve resources
    -- NOTE_WORD_C_0,
    -- NOTE_WORD_Db_0,
    -- NOTE_WORD_D_0,
    -- NOTE_WORD_Eb_0,
    -- NOTE_WORD_E_0,
    -- NOTE_WORD_F_0,
    -- NOTE_WORD_Gb_0,
    -- NOTE_WORD_G_0,
    -- NOTE_WORD_Ab_0,
    -- NOTE_WORD_A_0,
    -- NOTE_WORD_Bb_0,
    -- NOTE_WORD_B_0,
    -- NOTE_WORD_C_1,
    -- NOTE_WORD_Db_1,
    -- NOTE_WORD_D_1,
    -- NOTE_WORD_Eb_1,
    -- NOTE_WORD_E_1,
    -- NOTE_WORD_F_1,
    -- NOTE_WORD_Gb_1,
    -- NOTE_WORD_G_1,
    -- NOTE_WORD_Ab_1,
    -- NOTE_WORD_A_1,
    -- NOTE_WORD_Bb_1,
    -- NOTE_WORD_B_1,
    -- NOTE_WORD_C_2,
    -- NOTE_WORD_Db_2,
    -- NOTE_WORD_D_2,
    -- NOTE_WORD_Eb_2,
    -- NOTE_WORD_E_2,
    -- NOTE_WORD_F_2,
    -- NOTE_WORD_Gb_2,
    -- NOTE_WORD_G_2,
    -- NOTE_WORD_Ab_2,
    -- NOTE_WORD_A_2,
    -- NOTE_WORD_Bb_2,
    -- NOTE_WORD_B_2,
    -- NOTE_WORD_C_3,
    -- NOTE_WORD_Db_3,
    -- NOTE_WORD_D_3,
    -- NOTE_WORD_Eb_3,
    -- NOTE_WORD_E_3,
    -- NOTE_WORD_F_3,
    -- NOTE_WORD_Gb_3,
    -- NOTE_WORD_G_3,
    -- NOTE_WORD_Ab_3,
    -- NOTE_WORD_A_3,
    -- NOTE_WORD_Bb_3,
    -- NOTE_WORD_B_3,
    -- NOTE_WORD_C_4,
    -- NOTE_WORD_Db_4,
    -- NOTE_WORD_D_4,
    -- NOTE_WORD_Eb_4,
    -- NOTE_WORD_E_4,
    -- NOTE_WORD_F_4,
    -- NOTE_WORD_Gb_4,
    -- NOTE_WORD_G_4,
    -- NOTE_WORD_Ab_4,
    -- NOTE_WORD_A_4,
    -- NOTE_WORD_Bb_4,
    -- NOTE_WORD_B_4,
    -- NOTE_WORD_C_5,
    -- NOTE_WORD_Db_5,
    -- NOTE_WORD_D_5,
    -- NOTE_WORD_Eb_5,
    -- NOTE_WORD_E_5,
    -- NOTE_WORD_F_5,
    -- NOTE_WORD_Gb_5,
    -- NOTE_WORD_G_5,
    -- NOTE_WORD_Ab_5,
    -- NOTE_WORD_A_5,
    -- NOTE_WORD_Bb_5,
    -- NOTE_WORD_B_5,
    -- NOTE_WORD_C_6,
    -- NOTE_WORD_Db_6,
    -- NOTE_WORD_D_6,
    -- NOTE_WORD_Eb_6,
    -- NOTE_WORD_E_6,
    -- NOTE_WORD_F_6,
    -- NOTE_WORD_Gb_6,
    -- NOTE_WORD_G_6,
    -- NOTE_WORD_Ab_6,
    -- NOTE_WORD_A_6,
    -- NOTE_WORD_Bb_6,
    -- NOTE_WORD_B_6,
    -- NOTE_WORD_C_7,
    -- NOTE_WORD_Db_7,
    -- NOTE_WORD_D_7,
    -- NOTE_WORD_Eb_7,
    -- NOTE_WORD_E_7,
    -- NOTE_WORD_F_7,
    -- NOTE_WORD_Gb_7,
    -- NOTE_WORD_G_7,
    -- NOTE_WORD_Ab_7,
    -- NOTE_WORD_A_7,
    -- NOTE_WORD_Bb_7,
    -- NOTE_WORD_B_7,
    -- NOTE_WORD_C_8,
    -- NOTE_WORD_Db_8,
    -- NOTE_WORD_D_8,
    -- NOTE_WORD_Eb_8,
    -- NOTE_WORD_E_8,
    -- NOTE_WORD_F_8,
    -- NOTE_WORD_Gb_8,
    -- NOTE_WORD_G_8,
    -- NOTE_WORD_Ab_8,
    -- NOTE_WORD_A_8,
    -- NOTE_WORD_Bb_8,
    -- NOTE_WORD_B_8,
    -- NOTE_WORD_C_9,
    -- NOTE_WORD_Db_9,
    -- NOTE_WORD_D_9,
    -- NOTE_WORD_Eb_9,
    -- NOTE_WORD_E_9,
    -- NOTE_WORD_F_9,
    -- NOTE_WORD_Gb_9,
    -- NOTE_WORD_G_9,
    NOTE_WORD_Ab_9,
    NOTE_WORD_A_9,
    NOTE_WORD_Bb_9,
    NOTE_WORD_B_9,
    NOTE_WORD_C_10,
    NOTE_WORD_Db_10,
    NOTE_WORD_D_10,
    NOTE_WORD_Eb_10,
    NOTE_WORD_E_10,
    NOTE_WORD_F_10,
    NOTE_WORD_Gb_10,
    NOTE_WORD_G_10
  );
end music_note_pkg;

package body music_note_pkg is
    -- No implementation needed for a package with only constants
end music_note_pkg;

