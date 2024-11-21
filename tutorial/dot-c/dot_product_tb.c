#include <stdio.h>
#include <stdlib.h>
#include  <stdint.h>
#include "dot_product.h"
#define ARRAY_SIZE 10

int main(int argc, char ** argv){
	int fifo_ins[5] = {0x10000,0x20000,0x30000,0x40000,0x50000};
	int fifo_outs[5];
	int memory[MEMORY_SIZE];
	int i;
	for(i=0;i<200;i++)
		memory[i]=i;
	 dot_product(fifo_ins, memory, fifo_outs);
	printf("fifo_out0:0x%x\n",fifo_outs[0]);
	printf("fifo_out1:0x%x\n",fifo_outs[1]);
	printf("fifo_out2:0x%x\n",fifo_outs[2]);
	printf("fifo_out3:0x%x\n",fifo_outs[3]);
	printf("fifo_out4:0x%x\n",fifo_outs[4]);
}
