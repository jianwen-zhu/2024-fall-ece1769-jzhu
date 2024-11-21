#include <iostream>
#include <unistd.h>
#include <cstdarg>
#include <fstream>
#include "hardware.h"

void *Hardware::process(void){
	top->ap_rst = 1;
	top->ap_clk = 0;
	pthread_setcanceltype(PTHREAD_CANCEL_ASYNCHRONOUS,NULL);
	while(true) {
		top->ap_rst = (cycle<2);
		tfp->dump(cycle);
		top->ap_clk = !top->ap_clk;
		top->eval();
		cycle++;
	}
			
}

Hardware::Hardware(int argc, char **argv, char **env){

	if(argc<2)
	{
		printf("invalid argurment!!\nYou must determine the vcd file name as second input.\n");
		exit(1);
	}

	char *file_name = argv[1];
	Verilated::commandArgs(argc,argv);
	top = new Vtop_level("top");
	Verilated::debug(0);
	Verilated::traceEverOn(true);
	tfp = new VerilatedVcdC;
  	top->trace (tfp, 99);
	tfp->open(file_name);
	cycle=0;
	return;
}

Hardware::~Hardware(){
}



int Hardware::begin(void){

	return pthread_create(&t,NULL,&Hardware::processHelper,this);
}

int Hardware::end(void){
	top->final();
	pthread_cancel(t);
	usleep(1000);
	tfp->close();
	return 0;
}

void Hardware::fifoPush(int portNumber,int data){
	functionCall(portNumber, 1, data);
}
IData Hardware::fifoPop(int portNumber){
	return functionCall(portNumber,0);
}
IData Hardware::memRead(int portNumber,int address){
	return functionCall(portNumber,1,address);
}
void Hardware::memWrite(int portNumber,int address, int data){
	functionCall(portNumber, 2, address, data);
}

IData Hardware::functionCall(int FuncPortNum, int numArgs, ...){

	va_list arguments;
	
	va_start(arguments,numArgs);

	IData *args= (IData*) malloc(numArgs*sizeof(int));
	for(int i=0;i<numArgs;i++)
		args[i]= va_arg(arguments,IData);
	
	IData outputData;

	void* p=funcPtrsVect[FuncPortNum].ptr;
	const VerilatedScope* scope = funcPtrsVect[FuncPortNum].scope;

	void *dep = funcPtrsVect[FuncPortNum].depSigPtr;
	
	if(dep!=NULL){
		CData *depSignal =  (CData*) dep;
		while(!(*depSignal));
	}

	switch(numArgs){
		case 0:
		{
			func_ptr_0in pFunc=(func_ptr_0in)p;
   			(*pFunc)((design_syms*)scope->symsp(), outputData);
   		}
			break;
		case 1:
		{
			func_ptr_1in pFunc=(func_ptr_1in)p;
   			(*pFunc)((design_syms*)scope->symsp(),args[0], outputData);
   		}
			break;
		case 2:
		{
			func_ptr_2in pFunc=(func_ptr_2in)p;
   			(*pFunc)((design_syms*)scope->symsp(),args[0],args[1], outputData);
   		}
			break;
		case 3:
		{
			func_ptr_3in pFunc=(func_ptr_3in)p;
   			(*pFunc)((design_syms*)scope->symsp(),args[0], args[1], args[2], outputData);
   		}
			break;
		case 4:
		{
			func_ptr_4in pFunc=(func_ptr_4in)p;
   			(*pFunc)((design_syms*)scope->symsp(), args[0], args[1], args[2], args[3], outputData);
   		}
			break;
		default:
			break;
	}

	this->wait(1);
	return outputData;
}

void Hardware::wait(int cycles){
	int start = this->cycle;
	while(this->cycle-start < cycles);
	return;
}


int Hardware::portBind(int portNumber, const char* scopeString, const char* name, PortType type){
		int funcNum=Verilated::exportFuncNum(name);
		const VerilatedScope *scope=Verilated::scopeFind(scopeString);		
		
		if (scope == NULL)
			return ERR_PORT_BIND_SCOPE_NOT_FOUND;

		void* p=(void*) (VerilatedScope::exportFind(scope,funcNum));
		
		if (p == NULL) 
			return ERR_PORT_BIND_NAME_NOT_FOUND;

		void* depSig=NULL;
		if(type == FIFO_PUSH){
			depSig = (void*) scope->varFind("buf_full")->datap();
			if (depSig == NULL)
				return ERR_PORT_BIND_DEP_SIG_NOT_FOUND;
		}
		else if (type == FIFO_POP){
			depSig = (void*) scope->varFind("buf_empty")->datap();
			if (depSig == NULL)
				return ERR_PORT_BIND_DEP_SIG_NOT_FOUND;
		}
		else if (type != MEM_READ && type != MEM_WRITE)
			return ERR_PORT_BIND_UNSUPPORTED_PORT_TYPE;

		FuncSig temp={p,scope,depSig};
		funcPtrsVect[portNumber] = temp;
	return 0;
}

void Hardware::printError(int errNumber){
	printf("Error Number: %d\nError String: ",-errNumber);
	
	switch(errNumber){
		case ERR_PORT_BIND_SCOPE_NOT_FOUND:
			printf("Binding port not found\n");
			break;
		case ERR_PORT_BIND_NAME_NOT_FOUND:
			printf("Binding name not found\n");
			break;
		case ERR_PORT_BIND_UNSUPPORTED_PORT_TYPE:
			printf("Unsupported signal type. Supported Types: FIFO_PUSH, FIFO_POP, MEM_READ, MEM_WRITE\n");
			break;
		case ERR_PORT_BIND_DEP_SIG_NOT_FOUND:
			printf("Dependency signal not found\n");
			break;
		default:
			printf("Unkown error\n");
			break;
	}
}

void Hardware::dumpInternals(){
	Verilated::internalsDump();
}