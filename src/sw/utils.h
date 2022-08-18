
#define DEBUG

#ifdef DEBUG
#define DEBUG_PRINT(x) xil_printf x
#else
#define DEBUG_PRINT(x) do {} while (0)
#endif

#define RETURN_ON_FAILURE(x) if ((x) != XST_SUCCESS) return XST_FAILURE;
