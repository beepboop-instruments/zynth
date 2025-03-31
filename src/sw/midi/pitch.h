#ifndef PITCH_H
#define PITCH_H

/***************************************************************************
* Include files
****************************************************************************/

#include "xil_types.h"
#include <math.h>

/***************************************************************************
* Constant definitions
****************************************************************************/

#define PITCH_BEND_RANGE 2.0  // ±2 semitones

// pre-computed frequency words for 128-note 25 MHz time-multiplexed synthesizer
static const u32 FreqWordDefaults[128] = { \
  0x0002be4b, \
  0x0002e80e, \
  0x0003144c, \
  0x0003432c, \
  0x000374d6, \
  0x0003a973, \
  0x0003e132, \
  0x00041c41, \
  0x00045ad3, \
  0x00049d1d, \
  0x0004e359, \
  0x00052dc2, \
  0x00057c97, \
  0x0005d01c, \
  0x00062899, \
  0x00068659, \
  0x0006e9ac, \
  0x000752e7, \
  0x0007c264, \
  0x00083882, \
  0x0008b5a6, \
  0x00093a3b, \
  0x0009c6b2, \
  0x000a5b84, \
  0x000af92e, \
  0x000ba039, \
  0x000c5133, \
  0x000d0cb3, \
  0x000dd359, \
  0x000ea5cf, \
  0x000f84c8, \
  0x00107104, \
  0x00116b4c, \
  0x00127476, \
  0x00138d65, \
  0x0014b708, \
  0x0015f25d, \
  0x00174073, \
  0x0018a267, \
  0x001a1966, \
  0x001ba6b2, \
  0x001d4b9e, \
  0x001f0991, \
  0x0020e209, \
  0x0022d699, \
  0x0024e8ed, \
  0x00271aca, \
  0x00296e10, \
  0x002be4bb, \
  0x002e80e7, \
  0x003144ce, \
  0x003432cd, \
  0x00374d65, \
  0x003a973d, \
  0x003e1323, \
  0x0041c413, \
  0x0045ad33, \
  0x0049d1db, \
  0x004e3594, \
  0x0052dc20, \
  0x0057c977, \
  0x005d01ce, \
  0x0062899c, \
  0x0068659a, \
  0x006e9aca, \
  0x00752e7a, \
  0x007c2647, \
  0x00838826, \
  0x008b5a66, \
  0x0093a3b6, \
  0x009c6b29, \
  0x00a5b840, \
  0x00af92ee, \
  0x00ba039d, \
  0x00c51339, \
  0x00d0cb35, \
  0x00dd3595, \
  0x00ea5cf4, \
  0x00f84c8e, \
  0x0107104d, \
  0x0116b4cd, \
  0x0127476c, \
  0x0138d653, \
  0x014b7081, \
  0x015f25dc, \
  0x0174073a, \
  0x018a2672, \
  0x01a1966a, \
  0x01ba6b2a, \
  0x01d4b9e8, \
  0x01f0991d, \
  0x020e209b, \
  0x022d699b, \
  0x024e8ed9, \
  0x0271aca6, \
  0x0296e102, \
  0x02be4bb8, \
  0x02e80e74, \
  0x03144ce4, \
  0x03432cd5, \
  0x0374d655, \
  0x03a973d0, \
  0x03e1323b, \
  0x041c4136, \
  0x045ad337, \
  0x049d1db2, \
  0x04e3594c, \
  0x052dc205, \
  0x057c9770, \
  0x05d01ce8, \
  0x062899c8, \
  0x068659ab, \
  0x06e9acaa, \
  0x0752e7a0, \
  0x07c26476, \
  0x0838826c, \
  0x08b5a66e, \
  0x093a3b65, \
  0x09c6b298, \
  0x0a5b840a, \
  0x0af92ee0, \
  0x0ba039d0, \
  0x0c513391, \
  0x0d0cb357, \
  0x0dd35954, \
  0x0ea5cf40, \
  0x0f84c8ec, \
  0x107104d9};

/***************************************************************************
* Helper macros
****************************************************************************/

#define get_pitch_bend_scale(pitch_bend) pow(2.0, (((pitch_bend - 8192)/ 8192.0 * PITCH_BEND_RANGE) / 12.0))

#endif /* PITCH_H */