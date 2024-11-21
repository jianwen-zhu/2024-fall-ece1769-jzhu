#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include "dot_prod.h"

int dot_product(int v[], int u[], int n){
	int result=0;
	int i;
	for (i = 0; i < n; i++)
		result += v[i]*u[i];
	return result;
}
