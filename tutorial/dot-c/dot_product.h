#ifndef __DOT_PRODUCT_H__
#define __DOT_PRODUCT_H__
#define ARRAY_SIZE 100
#define MEMORY_ADDR_WIDTH 16
#define MEMORY_SIZE 1<<MEMORY_ADDR_WIDTH
void dot_product(int *fifo_in, int memory[MEMORY_SIZE], int *fifo_out);

#endif
