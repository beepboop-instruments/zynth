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
  constant NOTE_WORD_C_0   : unsigned := x"000594d3";
  constant NOTE_WORD_Db_0  : unsigned := x"0005e9c9";
  constant NOTE_WORD_D_0   : unsigned := x"000643cd";
  constant NOTE_WORD_Eb_0  : unsigned := x"0006a32b";
  constant NOTE_WORD_E_0   : unsigned := x"00070834";
  constant NOTE_WORD_F_0   : unsigned := x"00077340";
  constant NOTE_WORD_Gb_0  : unsigned := x"0007e4a9";
  constant NOTE_WORD_G_0   : unsigned := x"00085cd1";
  constant NOTE_WORD_Ab_0  : unsigned := x"0008dc1e";
  constant NOTE_WORD_A_0   : unsigned := x"000962fc";
  constant NOTE_WORD_Bb_0  : unsigned := x"0009f1e0";
  constant NOTE_WORD_B_0   : unsigned := x"000a8942";
  constant NOTE_WORD_C_1   : unsigned := x"000b29a6";
  constant NOTE_WORD_Db_1  : unsigned := x"000bd392";
  constant NOTE_WORD_D_1   : unsigned := x"000c879a";
  constant NOTE_WORD_Eb_1  : unsigned := x"000d4656";
  constant NOTE_WORD_E_1   : unsigned := x"000e1069";
  constant NOTE_WORD_F_1   : unsigned := x"000ee680";
  constant NOTE_WORD_Gb_1  : unsigned := x"000fc953";
  constant NOTE_WORD_G_1   : unsigned := x"0010b9a2";
  constant NOTE_WORD_Ab_1  : unsigned := x"0011b83c";
  constant NOTE_WORD_A_1   : unsigned := x"0012c5f9";
  constant NOTE_WORD_Bb_1  : unsigned := x"0013e3c0";
  constant NOTE_WORD_B_1   : unsigned := x"00151285";
  constant NOTE_WORD_C_2   : unsigned := x"0016534c";
  constant NOTE_WORD_Db_2  : unsigned := x"0017a725";
  constant NOTE_WORD_D_2   : unsigned := x"00190f34";
  constant NOTE_WORD_Eb_2  : unsigned := x"001a8cac";
  constant NOTE_WORD_E_2   : unsigned := x"001c20d2";
  constant NOTE_WORD_F_2   : unsigned := x"001dcd01";
  constant NOTE_WORD_Gb_2  : unsigned := x"001f92a6";
  constant NOTE_WORD_G_2   : unsigned := x"00217345";
  constant NOTE_WORD_Ab_2  : unsigned := x"00237078";
  constant NOTE_WORD_A_2   : unsigned := x"00258bf2";
  constant NOTE_WORD_Bb_2  : unsigned := x"0027c780";
  constant NOTE_WORD_B_2   : unsigned := x"002a250b";
  constant NOTE_WORD_C_3   : unsigned := x"002ca698";
  constant NOTE_WORD_Db_3  : unsigned := x"002f4e4b";
  constant NOTE_WORD_D_3   : unsigned := x"00321e68";
  constant NOTE_WORD_Eb_3  : unsigned := x"00351958";
  constant NOTE_WORD_E_3   : unsigned := x"003841a5";
  constant NOTE_WORD_F_3   : unsigned := x"003b9a03";
  constant NOTE_WORD_Gb_3  : unsigned := x"003f254d";
  constant NOTE_WORD_G_3   : unsigned := x"0042e68a";
  constant NOTE_WORD_Ab_3  : unsigned := x"0046e0f0";
  constant NOTE_WORD_A_3   : unsigned := x"004b17e4";
  constant NOTE_WORD_Bb_3  : unsigned := x"004f8f01";
  constant NOTE_WORD_B_3   : unsigned := x"00544a17";
  constant NOTE_WORD_C_4   : unsigned := x"00594d30";
  constant NOTE_WORD_Db_4  : unsigned := x"005e9c96";
  constant NOTE_WORD_D_4   : unsigned := x"00643cd1";
  constant NOTE_WORD_Eb_4  : unsigned := x"006a32b0";
  constant NOTE_WORD_E_4   : unsigned := x"0070834b";
  constant NOTE_WORD_F_4   : unsigned := x"00773407";
  constant NOTE_WORD_Gb_4  : unsigned := x"007e4a9b";
  constant NOTE_WORD_G_4   : unsigned := x"0085cd15";
  constant NOTE_WORD_Ab_4  : unsigned := x"008dc1e0";
  constant NOTE_WORD_A_4   : unsigned := x"00962fc9";
  constant NOTE_WORD_Bb_4  : unsigned := x"009f1e02";
  constant NOTE_WORD_B_4   : unsigned := x"00a8942e";
  constant NOTE_WORD_C_5   : unsigned := x"00b29a61";
  constant NOTE_WORD_Db_5  : unsigned := x"00bd392c";
  constant NOTE_WORD_D_5   : unsigned := x"00c879a3";
  constant NOTE_WORD_Eb_5  : unsigned := x"00d46561";
  constant NOTE_WORD_E_5   : unsigned := x"00e10697";
  constant NOTE_WORD_F_5   : unsigned := x"00ee680e";
  constant NOTE_WORD_Gb_5  : unsigned := x"00fc9536";
  constant NOTE_WORD_G_5   : unsigned := x"010b9a2a";
  constant NOTE_WORD_Ab_5  : unsigned := x"011b83c1";
  constant NOTE_WORD_A_5   : unsigned := x"012c5f92";
  constant NOTE_WORD_Bb_5  : unsigned := x"013e3c05";
  constant NOTE_WORD_B_5   : unsigned := x"0151285c";
  constant NOTE_WORD_C_6   : unsigned := x"016534c3";
  constant NOTE_WORD_Db_6  : unsigned := x"017a7259";
  constant NOTE_WORD_D_6   : unsigned := x"0190f346";
  constant NOTE_WORD_Eb_6  : unsigned := x"01a8cac3";
  constant NOTE_WORD_E_6   : unsigned := x"01c20d2e";
  constant NOTE_WORD_F_6   : unsigned := x"01dcd01d";
  constant NOTE_WORD_Gb_6  : unsigned := x"01f92a6c";
  constant NOTE_WORD_G_6   : unsigned := x"02173455";
  constant NOTE_WORD_Ab_6  : unsigned := x"02370783";
  constant NOTE_WORD_A_6   : unsigned := x"0258bf25";
  constant NOTE_WORD_Bb_6  : unsigned := x"027c780b";
  constant NOTE_WORD_B_6   : unsigned := x"02a250b9";
  constant NOTE_WORD_C_7   : unsigned := x"02ca6986";
  constant NOTE_WORD_Db_7  : unsigned := x"02f4e4b3";
  constant NOTE_WORD_D_7   : unsigned := x"0321e68d";
  constant NOTE_WORD_Eb_7  : unsigned := x"03519586";
  constant NOTE_WORD_E_7   : unsigned := x"03841a5d";
  constant NOTE_WORD_F_7   : unsigned := x"03b9a03a";
  constant NOTE_WORD_Gb_7  : unsigned := x"03f254d9";
  constant NOTE_WORD_G_7   : unsigned := x"042e68ab";
  constant NOTE_WORD_Ab_7  : unsigned := x"046e0f06";
  constant NOTE_WORD_A_7   : unsigned := x"04b17e4b";
  constant NOTE_WORD_Bb_7  : unsigned := x"04f8f016";
  constant NOTE_WORD_B_7   : unsigned := x"0544a173";
  constant NOTE_WORD_C_8   : unsigned := x"0594d30d";
  constant NOTE_WORD_Db_8  : unsigned := x"05e9c967";
  constant NOTE_WORD_D_8   : unsigned := x"0643cd1a";
  constant NOTE_WORD_Eb_8  : unsigned := x"06a32b0c";
  constant NOTE_WORD_E_8   : unsigned := x"070834ba";
  constant NOTE_WORD_F_8   : unsigned := x"07734074";
  constant NOTE_WORD_Gb_8  : unsigned := x"07e4a9b2";
  constant NOTE_WORD_G_8   : unsigned := x"085cd157";
  constant NOTE_WORD_Ab_8  : unsigned := x"08dc1e0d";
  constant NOTE_WORD_A_8   : unsigned := x"0962fc96";
  constant NOTE_WORD_Bb_8  : unsigned := x"09f1e02d";
  constant NOTE_WORD_B_8   : unsigned := x"0a8942e6";
  constant NOTE_WORD_C_9   : unsigned := x"0b29a61a";
  constant NOTE_WORD_Db_9  : unsigned := x"0bd392cf";
  constant NOTE_WORD_D_9   : unsigned := x"0c879a35";
  constant NOTE_WORD_Eb_9  : unsigned := x"0d465619";
  constant NOTE_WORD_E_9   : unsigned := x"0e106974";
  constant NOTE_WORD_F_9   : unsigned := x"0ee680e9";
  constant NOTE_WORD_Gb_9  : unsigned := x"0fc95364";
  constant NOTE_WORD_G_9   : unsigned := x"10b9a2ae";
  constant NOTE_WORD_Ab_9  : unsigned := x"11b83c1a";
  constant NOTE_WORD_A_9   : unsigned := x"12c5f92c";
  constant NOTE_WORD_Bb_9  : unsigned := x"13e3c05a";
  constant NOTE_WORD_B_9   : unsigned := x"151285cd";
  constant NOTE_WORD_C_10  : unsigned := x"16534c34";
  constant NOTE_WORD_Db_10 : unsigned := x"17a7259f";
  constant NOTE_WORD_D_10  : unsigned := x"190f346a";
  constant NOTE_WORD_Eb_10 : unsigned := x"1a8cac33";
  constant NOTE_WORD_E_10  : unsigned := x"1c20d2e8";
  constant NOTE_WORD_F_10  : unsigned := x"1dcd01d2";
  constant NOTE_WORD_Gb_10 : unsigned := x"1f92a6c8";
  constant NOTE_WORD_G_10  : unsigned := x"2173455d";

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

