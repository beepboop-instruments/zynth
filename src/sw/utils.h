#ifndef UTILS_H_
#define UTILS_H_


/***************************************************************************
* Constant definitions
****************************************************************************/

#define DEBUG

/***************************************************************************
* Macro functions
****************************************************************************/

#ifdef DEBUG
#define DEBUG_PRINT(x) xil_printf x
#else
#define DEBUG_PRINT(x) do {} while (0)
#endif

#define RETURN_ON_FAILURE(x) if ((x) != XST_SUCCESS) return XST_FAILURE;

#endif /* UTILS_H_ */
