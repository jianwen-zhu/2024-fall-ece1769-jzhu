#ifndef HARDWARE_H
#define HARDWARE_H

#include <string>
#include <pthread.h>
#include <vector>

#include "verilated_vcd_c.h"
#include "verilated_syms.h"
#include "verilated.h"
#include "Vtop_level__Syms.h"

#define MAX_NUM_PORTS 100

#define ERR_PORT_BIND_SCOPE_NOT_FOUND			-400
#define ERR_PORT_BIND_NAME_NOT_FOUND			-401
#define ERR_PORT_BIND_UNSUPPORTED_PORT_TYPE		-402
#define ERR_PORT_BIND_DEP_SIG_NOT_FOUND			-403

typedef enum type {FIFO_PUSH, FIFO_POP, MEM_READ, MEM_WRITE} PortType;

typedef Vtop_level__Syms design_syms;

typedef struct FuncSig{
	void* ptr;
    const VerilatedScope* scope;
    void* depSigPtr;
} FuncSig;

typedef void (*func_ptr_0in) (design_syms* __restrict vlSymsp, IData& push__Vfuncrtn);
typedef void (*func_ptr_1in) (design_syms* __restrict vlSymsp, IData, IData& push__Vfuncrtn);
typedef void (*func_ptr_2in) (design_syms* __restrict vlSymsp, IData, IData, IData& push__Vfuncrtn);
typedef void (*func_ptr_3in) (design_syms* __restrict vlSymsp, IData, IData, IData, IData& push__Vfuncrtn);
typedef void (*func_ptr_4in) (design_syms* __restrict vlSymsp, IData, IData, IData, IData, IData& push__Vfuncrtn);


using namespace std;

class Hardware{
	private:
		int cycle;
		pthread_t t;
		Vtop_level *top;
		VerilatedVcdC *tfp;
   		FuncSig funcPtrsVect[MAX_NUM_PORTS];

   		IData functionCall(int FuncPortNum, int numArgs, ...);
		void *process(void);
		static void *processHelper(void *context)
    	{
       	 	return ((Hardware *)context)->process();
   		}
	public:
		Hardware(int argc, char **argv, char **env);
		~Hardware(void);
		int  portBind(int portNumber, const char* scope, const char* name, PortType type);
		int  begin(void);
		int  end(void);
		void wait(int cycle);
		
		void  fifoPush(int portNumber,int data);
		IData fifoPop(int portNumber);
		IData memRead(int portNumber,int address);
		void  memWrite(int portNumber,int address, int data);
		void  printError(int errNumber);
		void dumpInternals(void);


};
#endif
