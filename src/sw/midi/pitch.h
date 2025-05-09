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
  0x000594d3, \
  0x0005e9c9, \
  0x000643cd, \
  0x0006a32b, \
  0x00070834, \
  0x00077340, \
  0x0007e4a9, \
  0x00085cd1, \
  0x0008dc1e, \
  0x000962fc, \
  0x0009f1e0, \
  0x000a8942, \
  0x000b29a6, \
  0x000bd392, \
  0x000c879a, \
  0x000d4656, \
  0x000e1069, \
  0x000ee680, \
  0x000fc953, \
  0x0010b9a2, \
  0x0011b83c, \
  0x0012c5f9, \
  0x0013e3c0, \
  0x00151285, \
  0x0016534c, \
  0x0017a725, \
  0x00190f34, \
  0x001a8cac, \
  0x001c20d2, \
  0x001dcd01, \
  0x001f92a6, \
  0x00217345, \
  0x00237078, \
  0x00258bf2, \
  0x0027c780, \
  0x002a250b, \
  0x002ca698, \
  0x002f4e4b, \
  0x00321e68, \
  0x00351958, \
  0x003841a5, \
  0x003b9a03, \
  0x003f254d, \
  0x0042e68a, \
  0x0046e0f0, \
  0x004b17e4, \
  0x004f8f01, \
  0x00544a17, \
  0x00594d30, \
  0x005e9c96, \
  0x00643cd1, \
  0x006a32b0, \
  0x0070834b, \
  0x00773407, \
  0x007e4a9b, \
  0x0085cd15, \
  0x008dc1e0, \
  0x00962fc9, \
  0x009f1e02, \
  0x00a8942e, \
  0x00b29a61, \
  0x00bd392c, \
  0x00c879a3, \
  0x00d46561, \
  0x00e10697, \
  0x00ee680e, \
  0x00fc9536, \
  0x010b9a2a, \
  0x011b83c1, \
  0x012c5f92, \
  0x013e3c05, \
  0x0151285c, \
  0x016534c3, \
  0x017a7259, \
  0x0190f346, \
  0x01a8cac3, \
  0x01c20d2e, \
  0x01dcd01d, \
  0x01f92a6c, \
  0x02173455, \
  0x02370783, \
  0x0258bf25, \
  0x027c780b, \
  0x02a250b9, \
  0x02ca6986, \
  0x02f4e4b3, \
  0x0321e68d, \
  0x03519586, \
  0x03841a5d, \
  0x03b9a03a, \
  0x03f254d9, \
  0x042e68ab, \
  0x046e0f06, \
  0x04b17e4b, \
  0x04f8f016, \
  0x0544a173, \
  0x0594d30d, \
  0x05e9c967, \
  0x0643cd1a, \
  0x06a32b0c, \
  0x070834ba, \
  0x07734074, \
  0x07e4a9b2, \
  0x085cd157, \
  0x08dc1e0d, \
  0x0962fc96, \
  0x09f1e02d, \
  0x0a8942e6, \
  0x0b29a61a, \
  0x0bd392cf, \
  0x0c879a35, \
  0x0d465619, \
  0x0e106974, \
  0x0ee680e9, \
  0x0fc95364, \
  0x10b9a2ae, \
  0x11b83c1a, \
  0x12c5f92c, \
  0x13e3c05a, \
  0x151285cd, \
  0x16534c34, \
  0x17a7259f, \
  0x190f346a, \
  0x1a8cac33, \
  0x1c20d2e8, \
  0x1dcd01d2, \
  0x1f92a6c8, \
  0x2173455d};

/***************************************************************************
* Helper macros
****************************************************************************/

// pitch-bend linear approximation
#define get_pitch_bend_scale(pitch_bend) (1.0 + ((pitch_bend - 8192) / 8192.0 * PITCH_BEND_RANGE) / 12.0)

// pitch-bend exponential equation
//#define get_pitch_bend_scale(pitch_bend) pow(2.0, (((pitch_bend - 8192)/ 8192.0 * PITCH_BEND_RANGE) / 12.0))

#endif /* PITCH_H */