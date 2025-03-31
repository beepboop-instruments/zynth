#ifndef UTILS_H_
#define UTILS_H_

#include <stdio.h>

/***************************************************************************
* Constant definitions
****************************************************************************/

#define DEBUG

/***************************************************************************
* Macro functions
****************************************************************************/

#ifdef DEBUG
  #define debug_print(fmt, ...) xil_printf(fmt, ##__VA_ARGS__)
#else
  #define debug_print(fmt, ...)  // Expands to nothing
#endif

#define RETURN_ON_FAILURE(x) if ((x) != XST_SUCCESS) return XST_FAILURE;

#define GET_BIT(data, pos) (((data) >> (pos)) & 1)
#define GET_BITS(data, start, end) (((data) >> (start)) & ((1U << ((end) - (start) + 1)) - 1))

#define SCALE 10000  // Define scale for 4 decimal places
#define FLOAT_TO_INT_FRAC(value, int_part, frac_part, scale) \
    do { \
        int_part = (int)(value); \
        frac_part = (int)((value - int_part) * scale); \
        if (frac_part < 0) frac_part = -frac_part; /* Handle negative numbers */ \
    } while (0)

#define ARRAY_COPY(dest, src, size) memcpy((dest), (src), (size) * sizeof(*(src)))

#endif /* UTILS_H_ */
