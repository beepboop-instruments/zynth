#ifndef UTILS_H_
#define UTILS_H_

#include <stdio.h>

/***************************************************************************
* Constant definitions
****************************************************************************/

#define DEBUG

#define STR_HEADER " __                              __\r\n" \
                   "|  | ___   ____    ____   ____  |  | ___    ___     ___   ____ \r\n" \
                   "|  |/   \\ /     \\ /     \\|     \\|  |/   \\ /     \\ /     \\|     \\ \r\n" \
                   "|      ^ |    ^_/|    ^_/|    ^ |      ^ |    ^  |    ^  |    ^ | \r\n" \
                   "|__|____/ \\_____\\ \\_____\\|  | _/|__|____/ \\ ___ / \\ ___ /|  | _/ \r\n" \
                   "/////////////////////////|__|////////////////////////////|__| \r\n" \
                   "Polyphonic Synthesizer v.0.0 \r\n" \
                   "//////////////////////////////////////////////////////////////\r\n\r\n"

#define STR_BAR "//////////////////////////////////////////////////////////////\r\n"

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
