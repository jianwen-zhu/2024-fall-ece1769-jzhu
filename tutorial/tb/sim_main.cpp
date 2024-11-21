#include "sim_main.h"

int main(int argc, char **argv, char **env){
	
	srand (time(NULL));

	pthread_t pushT,popT;

	vector<StimuliData> *stData  = new vector<StimuliData>;
	Hardware *h=new Hardware(argc,argv,env);

	fillStimuliData(stData);
	printStimuli(stData);

	struct arg_struct args;
    args.h = h;
    args.stData = stData;

	init(h);
	
	h->begin();
	usleep(2000);

	pthread_create(&pushT, NULL, &pushThread, (void *)&args);
	pthread_create(&popT, NULL, &popThread, (void *)&args);

	pthread_join(pushT,NULL);
	pthread_join(popT,NULL);

	h->end();
	delete h;
	return 0;
}

void init(Hardware *h){
	int err;
	err = h->portBind(PORT_FIFO_IN_PUSH, "top.v.fifo_in", "push", FIFO_PUSH); 
	if (err!= 0) h->printError(err);
	err = h->portBind(PORT_FIFO_IN_POP, "top.v.fifo_in", "pop", FIFO_POP);
	if (err!= 0) h->printError(err);
	err = h->portBind(PORT_FIFO_OUT_PUSH, "top.v.fifo_out", "push", FIFO_PUSH);
	if (err!= 0) h->printError(err);
	err = h->portBind(PORT_FIFO_OUT_POP, "top.v.fifo_out", "pop", FIFO_POP);
	if (err!= 0) h->printError(err);
	err = h->portBind(PORT_MEMORY_READ, "top.v.memory", "readmem", MEM_READ);
	if (err!= 0) h->printError(err);
	err = h->portBind(PORT_MEMORY_WRITE, "top.v.memory", "writemem", MEM_WRITE);
	if (err!= 0) h->printError(err);
	return;
}


int createToken(int jid, int inst,int address){
	int ret=0;
	ret =  (jid&( (1<<VER_PARAM_Q_WIDTH) -1 )  ) << (VER_PARAM_ADDR_WIDTH+VER_PARAM_INSTR_WIDTH)   ;
	ret +=  (  inst&( (1<<VER_PARAM_INSTR_WIDTH)-1)  ) << VER_PARAM_ADDR_WIDTH;
	ret +=	address&((1<<VER_PARAM_ADDR_WIDTH)-1);
	return ret;
}

int goldenModel(int *iData, int *oData){
	oData[0]=0;
	for(int i=0;i<VER_PARAM_IN_DATA_SIZE;i++)
		oData[0] += iData[i]*iData[VER_PARAM_IN_DATA_SIZE+i];
	return 0;
}

void fillStimuliData(vector<StimuliData> *stData){

	for (int i=0;i<20;i++){
		StimuliData temp(0);
		temp.iData = (int*) malloc((2*VER_PARAM_IN_DATA_SIZE)*sizeof(int));
		for(int j=0;j<2*VER_PARAM_IN_DATA_SIZE;j++)
			temp.iData[j]=rand();
		temp.oData 			= (int*) malloc(VER_PARAM_OUT_DATA_SIZE*sizeof(int));
		temp.oDataGolden 	= (int*) malloc(VER_PARAM_OUT_DATA_SIZE*sizeof(int));
		temp.iDataSize		= (2*VER_PARAM_IN_DATA_SIZE);
		temp.oDataSize		= VER_PARAM_OUT_DATA_SIZE;
		temp.offset 		= i*(temp.iDataSize+temp.oDataSize);
		temp.token 			= createToken(i,0,temp.offset);
		temp.status 		= UNDONE;
		temp.testResult		= UNKNOWN;
		stData->push_back(temp);
	}
}

void printStimuli(vector<StimuliData> *stData){

	printf ("Stimuli Table:\n");
	printf ("************************************************************************************\n");
	printf ("************************************************************************************\n");
	printf ("TOKEN\t\t&IDATA\t\t&ODATA\t\tOFFSET\t\tSTATUS\tTEST_RESULT\n");
	printf ("************************************************************************************\n");
	printf ("************************************************************************************\n");
	for(vector<StimuliData>::iterator it=stData->begin(); it != stData->end(); ++it){
		printf("0x%08x\t%p\t%p\t0x%x\t\t",it->token, it->iData, it->oData, it->offset);
		if(it->status == DONE)
			printf("\x1b[32m""%s\t""\x1b[0m","DONE");
		else
			printf("\x1b[31m""%s\t""\x1b[0m","UNDONE");
		if(it->testResult == PASS)
			printf("\x1b[32m""%s\n""\x1b[0m","PASS");
		else if (it->testResult == FAIL)
			printf("\x1b[31m""%s\n""\x1b[0m","FAIL");
		else
			printf("\x1b[33m""%s\n""\x1b[0m","UNKNOWN");
		printf ("------------------------------------------------------------------------------------\n");
	}
	printf ("------------------------------------------------------------------------------------\n");

}

void testResult(vector<StimuliData>::iterator it){
	goldenModel(it->iData, it->oDataGolden);
	it->testResult = (!memcmp(it->oData,it->oDataGolden,it->oDataSize)) ? PASS : FAIL;
}

void* pushThread(void *arguments){
	
	struct arg_struct *args = (struct arg_struct *)arguments;
	Hardware *h = args->h;
	vector<StimuliData> *stData = args->stData;

	for(vector<StimuliData>::iterator it=stData->begin(); it != stData->end(); ++it){
		for(int i=0;i<it->iDataSize;i++)
			h->memWrite(PORT_MEMORY_WRITE,(i+(it->offset))*sizeof(int),it->iData[i]);
		printf("Push Job # 0x%x\n", it->token);
		h->fifoPush(PORT_FIFO_IN_PUSH,it->token); 
	}
	return 0;
}

void* popThread(void *arguments){
	
	struct arg_struct *args = (struct arg_struct *)arguments;
	Hardware *h = args->h;
	vector<StimuliData> *stData = args->stData;

	for(int i=0;i<stData->size();i++){
		int token = (int) h->fifoPop(PORT_FIFO_OUT_POP);
		StimuliData t(token);
		printf("Pop Job # 0x%x\n",token);
		vector<StimuliData>::iterator it = find_if(stData->begin(),stData->end(),StimuliData(token));
		for(int i=0;i<it->oDataSize;i++){
			it->oData[i] = h->memRead(PORT_MEMORY_READ,(it->offset+(2*VER_PARAM_IN_DATA_SIZE)+i)*sizeof(int));
		}
		it->status = DONE;
		testResult(it);
		printStimuli(stData);
	}
	return 0;
}