#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <ap_cint.h>
#include "dot_product.h"


void dot_product(int *fifo_in, int memory[MEMORY_SIZE], int *fifo_out)
{

	#pragma HLS INTERFACE bram port=memory
	#pragma HLS RESOURCE  variable=memory core=RAM_T2P_BRAM
	#pragma HLS INTERFACE ap_ctrl_none port=return
	#pragma HLS INTERFACE ap_fifo depth=8 port=fifo_out
	#pragma HLS INTERFACE ap_fifo depth=8 port=fifo_in

	int c_job = *fifo_in;

	unsigned offset = c_job & 0xFFFF;

	int result=0;
	int i;
	printf("address is : %X\n",offset);

	for (i = 0; i < ARRAY_SIZE; i++)
		#pragma HLS PIPELINE
		result += memory[offset+i]*memory[offset+i+ARRAY_SIZE];

	memory[2*ARRAY_SIZE+offset] = result;
	*fifo_out = c_job;
}
