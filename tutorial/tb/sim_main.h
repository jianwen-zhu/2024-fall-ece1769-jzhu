#ifndef _SIM_MAIN_H_
#define _SIM_MAIN_H_

#include <iostream>
#include <unistd.h>
#include <stdlib.h> 
#include <time.h>
#include <algorithm>
#include "hardware.h"


#define PORT_FIFO_IN_PUSH 	0x00
#define PORT_FIFO_IN_POP 	0x01
#define PORT_FIFO_OUT_PUSH 	0x02
#define PORT_FIFO_OUT_POP	0x03
#define PORT_MEMORY_READ	0x04
#define PORT_MEMORY_WRITE	0x05


#define VER_PARAM_INSTR_WIDTH 	2
#define VER_PARAM_ADDR_WIDTH  	16
#define VER_PARAM_Q_WIDTH     	3
#define VER_PARAM_IN_DATA_SIZE	100
#define VER_PARAM_OUT_DATA_SIZE	1

typedef enum result {UNKNOWN, PASS, FAIL} TestResult;
typedef enum status {UNDONE, DONE} JobStatus;

typedef struct StimuliData{
	int* 		iData;
	int* 		oData;
	int*		oDataGolden;
	int 		iDataSize;
	int 		oDataSize;
	int 		offset;
	int 		token;
	JobStatus 	status;
	TestResult	testResult;
	StimuliData(int t) {token = t;}
	bool operator()(const StimuliData& s) const {
        return (s.token == token);
  	}
} StimuliData;

struct arg_struct {
    Hardware *h;
    vector<StimuliData> *stData;    
};

void init(Hardware *h);
int createToken(int jid, int inst,int address);
int goldenModel(int *iData, int *oData);
void fillStimuliData(vector<StimuliData> *stData);
void printStimuli(vector<StimuliData> *stData);
void testResult(vector<StimuliData>::iterator it);
void* pushThread(void *arguments);
void* popThread(void *arguments);

#endif