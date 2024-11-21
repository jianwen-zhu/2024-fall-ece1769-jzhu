-include $(LEVEL)/site.mk

###################################
# FIND ALL VERILOG FILES AND DEFINE
# ENV VERILOG FILES
###################################
RTL_FILES	= $(filter-out sim_%.v, $(shell find . -maxdepth 1 -name "*.v"))
ENV_FILES	= sim_top_level.v sim_dp_bram.v sim_fifo.v

###################################
# TEST BENCH AND LIB PATH
###################################
HARDWARE_LIB_DIR	= 	$(LEVEL)/lib
TEST_BENCH_DIR		= 	$(LEVEL)/tb
HARDWARE_LIB_FILES	= 	$(shell find $(HARDWARE_LIB_DIR) -maxdepth 1 -name "*.cpp")
TEST_BENCH_FILES 	=	$(shell find $(TEST_BENCH_DIR) -maxdepth 1 -name "*.cpp")

TEST_BENCH		=	$(addsuffix .o, $(basename $(TEST_BENCH_FILES)))
HARDWARE_LIB 		=	$(addsuffix .o, $(basename $(HARDWARE_LIB_FILES)))

INCLUDE_DIR		=	$(LEVEL)/inc	

###################################
# Default target
###################################
all :	verilate

###################################
# HLS PROJECT AND SOLUTION NAMES
###################################
HLS		=	$(VIVADO_HLS_PATH)/vivado_hls

$(TOP_MODULE).v : 
	$(HLS) script.tcl vivado_hls sol
	cp vivado_hls/sol/syn/verilog/* .
	rm -rf vivado_hls*

csyn: $(TOP_MODULE).v

###################################
# Verilator rules
###################################
VIEW_OPTIONS		= --save=wave.gtkw
VV			= $(VERILATOR_PATH)/bin/verilator
VFLAGS			= --trace -Wno-WIDTH
CFLAGS			= -j
CPP_FLAGS		= -I$(INCLUDE_DIR)  -Iobj_dir/ -I$(HARDWARE_LIB_DIR) -I$(TEST_BENCH_DIR)
CPP_FLAGS		+= -I$(VERILATOR_PATH)/include -I$(VERILATOR_PATH)/include/vltstd

VERILATOR_OBJS_FILES 	= Vtop_level__ALL.a  verilated.o verilated_dpi.o verilated_vcd_c.o 
VERILATOR_OBJS 		= $(addprefix obj_dir/, $(VERILATOR_OBJS_FILES))
VERILATOR_MAKEFILE	= obj_dir/Vtop_level.mk

verilate: $(TOP_MODULE).verilated

$(TOP_MODULE).verilated:  $(VERILATOR_OBJS) $(TEST_BENCH) $(HARDWARE_LIB)
	g++ -o $(TOP_MODULE).verilated $(TEST_BENCH) $(HARDWARE_LIB) $(VERILATOR_OBJS) -lpthread

$(VERILATOR_OBJS): $(TOP_MODULE).v $(ENV_FILES)
	$(VV) $(VFLAGS)  -I$(INCLUDE_DIR) --cc sim_top_level.v 
	cd obj_dir && \
	make $(CFLAGS)  -f Vtop_level.mk CXXFLAGS=-pthread $(VERILATOR_OBJS_FILES)


%.o: %.cpp
	g++  -c $(CPP_FLAGS) $< -o $@

###################################
# Simulation rules
###################################

sim: $(TOP_MODULE).vcd

$(TOP_MODULE).vcd: $(TOP_MODULE).verilated
	./$(TOP_MODULE).verilated $(PORT_DEF_FILE) $(TOP_MODULE).vcd

###################################
# Waveform viewing
###################################

view: $(TOP_MODULE).vcd
	$(GTKWAVE_PATH)/gtkwave $(VIEW_OPTIONS) $(TOP_MODULE).vcd

###################################
# Yosys rules
###################################
YY			= $(YOSYS_PATH)/yosys
YOSYS_GLOBRST		?=
YOSYS_COARSE		?=
YOSYS_SPLITNETS		?=

synth.ys: $(TOP_MODULE).v
	for file in $(RTL_FILES); do                     		\
		echo "read_verilog -I../inc -sv $$file" >> $@ 		;\
	done
	if test -n "$(TOP_MODULE)"; then                          	\
		echo "hierarchy -check -top $(TOP_MODULE)" >> $@ 	;\
	else                                                		\
		echo "hierarchy -check" >> $@ 				;\
	fi
	if test -z "$(YOSYS_GLOBRST)"; then                 		\
		echo "add -global_input globrst 1" >> $@ 		;\
		echo "proc -global_arst globrst" >> $@   		;\
	else                                                		\
		echo "proc" >> $@                        		;\
	fi
	echo "flatten; opt; memory; opt; fsm; opt" >> $@
	if test -n "$(YOSYS_COARSE)"; then                    		\
		echo "techmap; opt; abc -dff; clean" >> $@ 		;\
	fi
	if test -z "$(YOSYS_SPLITNETS)"; then				\
		echo "splitnets; clean"  >> $@             		;\
	fi
	if test -z "$(YOSYS_COARSE)"; then 				\
		echo "write_verilog -noexpr -noattr synth.v"  >> $@ 	;\
	else 								\
		echo "select -assert-none t:\$[!_]">> $@    		;\
		echo "write_verilog -noattr synth.v" >> $@ 		;\
	fi
	echo "stat" >> $@

synth.v: synth.ys $(RTL_FILES)
	$(YY) -v2 -l synth.log synth.ys

synth.stat : synth.v
	$(YY) -l synth.stat -p "read_verilog synth.v" -p stat

syn:    synth.v
stat:   synth.stat

###################################
# $(ENV_FILES) generation rules
###################################

sim_top_level.v:
	@echo "\`include \"consts.vh\"" >> $@
	@echo "module top_level #(parameter P_DATA_WIDTH=\`data_width, parameter P_ADDR_WIDTH=\`addr_width, parameter P_COUNT=\`in_data_size) (" >> $@
	@echo "input ap_clk," >> $@
	@echo "input ap_rst," >> $@
	@echo "// INPUT FIFO SIGNALS" >> $@
	@echo "input token fin_buf_in," >> $@
	@echo "input fin_wr_en," >> $@
	@echo "output fin_stat," >> $@
	@echo "output fin_buf_full/* verilator public */," >> $@
	@echo "output [\`q_width:0] fin_counter," >> $@
	@echo "// OUTPUT FIFO SIGNALS" >> $@
	@echo "input fout_rd_en," >> $@
	@echo "output fout_buf_empty /* verilator public */," >> $@
	@echo "output fout_stat," >> $@
	@echo "output [\`q_width:0] fout_counter," >> $@
	@echo "output token fout_buf_out" >> $@
	@echo ");" >> $@
	@echo "" >> $@
	@echo "wire [P_ADDR_WIDTH-1:0] 	memory_Addr_A;" >> $@
	@echo "wire 						memory_EN_A;" >> $@
	@echo "wire 						memory_WEN_A;" >> $@
	@echo "wire [P_DATA_WIDTH-1:0] 	memory_Din_A;" >> $@
	@echo "wire [P_DATA_WIDTH-1:0] 	memory_Dout_A;" >> $@
	@echo "wire 						memory_Clk_A;" >> $@
	@echo "wire 						memory_Rst_A;" >> $@
	@echo "wire [P_ADDR_WIDTH-1:0]		memory_Addr_B;" >> $@
	@echo "wire 						memory_EN_B;" >> $@
	@echo "wire 						memory_WEN_B;" >> $@
	@echo "wire [P_DATA_WIDTH-1:0] 	memory_Din_B;" >> $@
	@echo "wire [P_DATA_WIDTH-1:0] 	memory_Dout_B;" >> $@
	@echo "wire 						memory_Clk_B;" >> $@
	@echo "wire 						memory_Rst_B;" >> $@
	@echo "" >> $@
	@echo "wire fin_rd_en;" >> $@
	@echo "token fin_buf_out;" >> $@
	@echo "wire fin_buf_empty;" >> $@
	@echo "" >> $@
	@echo "token fout_buf_in;" >> $@
	@echo "wire fout_wr_en;" >> $@
	@echo "wire fout_buf_full;" >> $@
	@echo "" >> $@
	@echo "assign memory_Clk_A = ap_clk;" >> $@
	@echo "assign memory_Clk_B = ap_clk;" >> $@
	@echo "assign memory_Rst_A = ap_rst;" >> $@
	@echo "assign memory_Rst_B = ap_rst;" >> $@
	@echo "" >> $@
	@echo "fifo #(\`instr_width,P_ADDR_WIDTH,\`q_width,\`q_size) fifo_in(" >> $@
	@echo ".clk(ap_clk)," >> $@
	@echo ".rst(ap_rst)," >> $@
	@echo ".buf_in(fin_buf_in), " >> $@
	@echo ".wr_en(fin_wr_en), " >> $@
	@echo ".rd_en(fin_rd_en), " >> $@
	@echo ".buf_out(fin_buf_out)," >> $@
	@echo ".buf_empty(fin_buf_empty), " >> $@
	@echo ".buf_full(fin_buf_full), " >> $@
	@echo ".stat(fin_stat), " >> $@
	@echo ".fifo_counter(fin_counter)" >> $@
	@echo ");" >> $@
	@echo "" >> $@
	@echo "fifo #(\`instr_width,P_ADDR_WIDTH,\`q_width,\`q_size) fifo_out(" >> $@
	@echo ".clk(ap_clk)," >> $@
	@echo ".rst(ap_rst)," >> $@
	@echo ".buf_in(fout_buf_in), " >> $@
	@echo ".wr_en(fout_wr_en), " >> $@
	@echo ".rd_en(fout_rd_en)," >> $@
	@echo ".buf_out(fout_buf_out)," >> $@
	@echo ".buf_empty(fout_buf_empty), " >> $@
	@echo ".buf_full(fout_buf_full), " >> $@
	@echo ".stat(fout_stat), " >> $@
	@echo ".fifo_counter(fout_counter)" >> $@
	@echo ");" >> $@
	@echo "" >> $@
	@echo "dp_bram #(P_DATA_WIDTH, P_ADDR_WIDTH, P_COUNT) memory(" >> $@
	@echo "" >> $@
	@echo ".memory_Addr_A(memory_Addr_A)," >> $@
	@echo ".memory_EN_A(memory_EN_A)," >> $@
	@echo ".memory_WEN_A(memory_WEN_A)," >> $@
	@echo ".memory_Din_A(memory_Din_A)," >> $@
	@echo ".memory_Dout_A(memory_Dout_A)," >> $@
	@echo ".memory_Clk_A(memory_Clk_A)," >> $@
	@echo ".memory_Rst_A(memory_Rst_A)," >> $@
	@echo ".memory_Addr_B(memory_Addr_B)," >> $@
	@echo ".memory_EN_B(memory_EN_B)," >> $@
	@echo ".memory_WEN_B(memory_WEN_B)," >> $@
	@echo ".memory_Din_B(memory_Din_B)," >> $@
	@echo ".memory_Dout_B(memory_Dout_B)," >> $@
	@echo ".memory_Clk_B(memory_Clk_B)," >> $@
	@echo ".memory_Rst_B(memory_Rst_B)" >> $@
	@echo ");" >> $@
	@echo "" >> $@
	@echo "$(TOP_MODULE) DUT(" >> $@
	@echo ".ap_clk(ap_clk)," >> $@
	@echo ".ap_rst(ap_rst)," >> $@
	@echo "// MEMORY SIGNALS" >> $@
	@echo ".memory_Addr_A(memory_Addr_A)," >> $@
	@echo ".memory_EN_A(memory_EN_A)," >> $@
	@echo ".memory_WEN_A(memory_WEN_A)," >> $@
	@echo ".memory_Din_A(memory_Din_A)," >> $@
	@echo ".memory_Dout_A(memory_Dout_A)," >> $@
	@echo ".memory_Clk_A(memory_Clk_A)," >> $@
	@echo ".memory_Rst_A(memory_Rst_A)," >> $@
	@echo ".memory_Addr_B(memory_Addr_B)," >> $@
	@echo ".memory_EN_B(memory_EN_B)," >> $@
	@echo ".memory_WEN_B(memory_WEN_B)," >> $@
	@echo ".memory_Din_B(memory_Din_B)," >> $@
	@echo ".memory_Dout_B(memory_Dout_B)," >> $@
	@echo ".memory_Clk_B(memory_Clk_B)," >> $@
	@echo ".memory_Rst_B(memory_Rst_B)," >> $@
	@echo "// INPUT FIFO SIGNALS" >> $@
	@echo ".fifo_in_empty_n(fin_buf_empty)," >> $@
	@echo ".fifo_in_dout(fin_buf_out)," >> $@
	@echo ".fifo_in_read(fin_rd_en)," >> $@
	@echo "// OUTPUT FIFO SIGNALS" >> $@
	@echo ".fifo_out_full_n(fout_buf_full)," >> $@
	@echo ".fifo_out_write(fout_wr_en)," >> $@
	@echo ".fifo_out_din(fout_buf_in)" >> $@
	@echo ");" >> $@
	@echo "" >> $@
	@echo "endmodule" >> $@

sim_dp_bram.v:
	@echo "module dp_bram #(parameter P_DATA_WIDTH=32, parameter P_ADDR_WIDTH=8, parameter P_COUNT=100)" >> $@
	@echo "(" >> $@
	@echo "// PORT A SIGNALS" >> $@
	@echo "input [P_ADDR_WIDTH-1:0] 		memory_Addr_A," >> $@
	@echo "input 							memory_EN_A," >> $@
	@echo "input 							memory_WEN_A," >> $@
	@echo "input [P_DATA_WIDTH-1:0] 		memory_Din_A," >> $@
	@echo "output reg [P_DATA_WIDTH-1:0] 	memory_Dout_A," >> $@
	@echo "input 							memory_Clk_A/* verilator lint_off MULTIDRIVEN */," >> $@
	@echo "input 							memory_Rst_A," >> $@
	@echo "// PORT B SIGNALS" >> $@
	@echo "input [P_ADDR_WIDTH-1:0]		memory_Addr_B," >> $@
	@echo "input 							memory_EN_B," >> $@
	@echo "input 							memory_WEN_B," >> $@
	@echo "input [P_DATA_WIDTH-1:0] 		memory_Din_B," >> $@
	@echo "output reg [P_DATA_WIDTH-1:0] 	memory_Dout_B," >> $@
	@echo "input 							memory_Clk_B," >> $@
	@echo "input 							memory_Rst_B" >> $@
	@echo ");" >> $@
	@echo "// Declare the RAM variable" >> $@
	@echo "int ram[(2**P_ADDR_WIDTH)-1:0];" >> $@
	@echo "" >> $@
	@echo "export \"DPI-C\" task writemem;" >> $@
	@echo "export \"DPI-C\" task readmem;" >> $@
	@echo "" >> $@
	@echo "\`ifdef verilator" >> $@
	@echo "function int readmem;" >> $@
	@echo "input int addr;" >> $@
	@echo "readmem = ram[addr>>2];" >> $@
	@echo "endfunction // if" >> $@
	@echo "" >> $@
	@echo "task writemem;" >> $@
	@echo "input int addr; " >> $@
	@echo "input int data;" >> $@
	@echo "ram[addr>>2] = data;" >> $@
	@echo "endtask" >> $@
	@echo "\`endif" >> $@
	@echo "" >> $@
	@echo "wire [P_ADDR_WIDTH-1:0] memory_Addr_A_COR;" >> $@
	@echo "wire [P_ADDR_WIDTH-1:0] memory_Addr_B_COR;" >> $@
	@echo "" >> $@
	@echo "assign memory_Addr_A_COR = memory_Addr_A[P_ADDR_WIDTH-1:0]>>2;" >> $@
	@echo "assign memory_Addr_B_COR = memory_Addr_B[P_ADDR_WIDTH-1:0]>>2;" >> $@
	@echo "" >> $@
	@echo "// Port A" >> $@
	@echo "always @ (posedge memory_Clk_A)" >> $@
	@echo "begin" >> $@
	@echo "if(memory_EN_A)" >> $@
	@echo "if (memory_WEN_A) " >> $@
	@echo "ram[memory_Addr_A_COR] <= memory_Din_A;" >> $@
	@echo "else " >> $@
	@echo "memory_Dout_A <= ram[memory_Addr_A_COR];" >> $@
	@echo "end" >> $@
	@echo "// Port B" >> $@
	@echo "always @ (posedge memory_Clk_B)" >> $@
	@echo "begin" >> $@
	@echo "if(memory_EN_B)" >> $@
	@echo "if (memory_WEN_B) " >> $@
	@echo "ram[memory_Addr_B_COR] <= memory_Din_B;" >> $@
	@echo "else " >> $@
	@echo "memory_Dout_B <= ram[memory_Addr_B_COR];" >> $@
	@echo "end" >> $@
	@echo "endmodule" >> $@

sim_fifo.v:
	@echo "\`include \"consts.vh\"" >> $@
	@echo "" >> $@
	@echo "module fifo #(parameter INSTR_WIDTH=\`instr_width,parameter ADDR_WIDTH=\`addr_width,parameter Q_WIDTH=\`q_width,parameter Q_SIZE=\`q_size)" >> $@
	@echo "(" >> $@
	@echo "input                   clk," >> $@
	@echo "input                   rst," >> $@
	@echo "input   int             buf_in," >> $@
	@echo "input                   wr_en," >> $@
	@echo "input                   rd_en," >> $@
	@echo "output  int             buf_out," >> $@
	@echo "output  reg             buf_empty/* verilator public */," >> $@
	@echo "output  reg             buf_full/* verilator public */," >> $@
	@echo "output  reg             stat," >> $@
	@echo "output  reg [Q_WIDTH:0] fifo_counter " >> $@
	@echo ");" >> $@
	@echo "" >> $@
	@echo "reg   [Q_WIDTH-1:0]  rd_ptr;" >> $@
	@echo "reg   [Q_WIDTH-1:0]  wr_ptr; " >> $@
	@echo "int   buf_mem[Q_SIZE-1:0];" >> $@
	@echo "" >> $@
	@echo "export \"DPI-C\" function push;" >> $@
	@echo "export \"DPI-C\" function pop;" >> $@
	@echo "" >> $@
	@echo "\`ifdef verilator" >> $@
	@echo "function int pop;" >> $@
	@echo "if(buf_empty) begin" >> $@
	@echo "pop = buf_mem[rd_ptr];" >> $@
	@echo "rd_ptr = rd_ptr + 1;" >> $@
	@echo "fifo_counter = fifo_counter - 1;" >> $@
	@echo "end" >> $@
	@echo "endfunction " >> $@
	@echo "" >> $@
	@echo "function int push;" >> $@
	@echo "input int data;" >> $@
	@echo "if(buf_full) begin" >> $@
	@echo "//$display("pushing function");" >> $@
	@echo "buf_mem[ wr_ptr ] = data;" >> $@
	@echo "wr_ptr = wr_ptr + 1;" >> $@
	@echo "fifo_counter = fifo_counter + 1;" >> $@
	@echo "push = 1'b1;" >> $@
	@echo "end" >> $@
	@echo "else " >> $@
	@echo "push=1'b0;" >> $@
	@echo "endfunction" >> $@
	@echo "\`endif" >> $@
	@echo "" >> $@
	@echo "" >> $@
	@echo "always @(fifo_counter)" >> $@
	@echo "begin" >> $@
	@echo "buf_empty = (fifo_counter!=0);" >> $@
	@echo "buf_full = (fifo_counter!= Q_SIZE);" >> $@
	@echo "end" >> $@
	@echo "" >> $@
	@echo "" >> $@
	@echo "always @(posedge clk) begin" >> $@
	@echo "if( rst ) begin" >> $@
	@echo "fifo_counter =0;" >> $@
	@echo "stat = 0;" >> $@
	@echo "buf_full = 0;" >> $@
	@echo "buf_empty = 0;" >> $@
	@echo "wr_ptr= 0;" >> $@
	@echo "rd_ptr=0;" >> $@
	@echo "buf_out = 0;" >> $@
	@echo "end" >> $@
	@echo "else begin" >> $@
	@echo "if(buf_full && wr_en) stat = push(buf_in);" >> $@
	@echo "if(buf_empty && rd_en) buf_out = pop();" >> $@
	@echo "end" >> $@
	@echo "end" >> $@
	@echo "endmodule" >> $@


###################################
# clearning rules
###################################
clean:
	@rm -rf ./obj_dir ./vivado_hls V$(TOP_MODULE)
	@rm -f *.vcd *.log *.o *.d *.verilated $(CSYN_FILES) $(ENV_FILES)
	@rm -f *.ys synth.v *.stat

