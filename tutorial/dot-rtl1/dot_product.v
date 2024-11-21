`include "consts.vh"

module dot_product (
	input ap_clk,
	input ap_rst,
	// MEMORY SIGNALS
	output [`addr_width-1:0]  	memory_Addr_A,
	output 						memory_EN_A,
	output 						memory_WEN_A,
	output [`data_width-1:0]	memory_Din_A,
	input  [`data_width-1:0] 	memory_Dout_A,
	output 						memory_Clk_A,
	output 						memory_Rst_A,
	output [`addr_width-1:0]  	memory_Addr_B,
	output 						memory_EN_B,
	output 						memory_WEN_B,
	output [`data_width-1:0]	memory_Din_B,
	input  [`data_width-1:0] 	memory_Dout_B,
	input 						memory_Clk_B,
	input 						memory_Rst_B,
	// INPUT FIFO SIGNALS
	input 						fifo_in_empty_n,
	input  token			 	fifo_in_dout,
	output 						fifo_in_read,
	// OUTPUT FIFO SIGNALS
	input 						fifo_out_full_n,
	output 						fifo_out_write,
	output token				fifo_out_din
);

	wire 						internal_rst;
	wire 						cjob_load_en;
	wire 						cjob_out_en;
	wire [`addr_width-1:0] 		job_offset;

datapath #(`data_width) dp(
	.input_a(memory_Dout_A), 
	.input_b(memory_Dout_B), 
	.clk(ap_clk), 
	.rst(internal_rst), 
	.out(memory_Din_A)
);

controller #(`addr_width, `in_data_size) ctrl(
	.clk(ap_clk),
	.rst(ap_rst),
	.out_rst(internal_rst),
	.ce_0(memory_EN_A),
	.ce_1(memory_EN_B),
	.we_0(memory_WEN_A),
	.we_1(memory_WEN_B),
	.cjob_offset(job_offset),
	.address_0(memory_Addr_A),
	.address_1(memory_Addr_B),
	// INPUT FIFO SIGNALS
	.fin_buf_empty(fifo_in_empty_n),
	.fin_rd_en(fifo_in_read),
	// OUTPUT FIFO SIGNALS
	.fout_buf_full(fifo_out_full_n),
	.fout_wr_en(fifo_out_write),
	// CURRENT JOB REGISTER SIGNALS
	.cjob_load_en(cjob_load_en),
	.cjob_out_en(cjob_out_en)
);

cjob_register cjob_reg(
	.clk(ap_clk),
	.rst(ap_rst),
	.load(cjob_load_en),
	.out_en(cjob_out_en),
	.data_in(fifo_in_dout),
	.data_out(fifo_out_din)
);

assign job_offset = fin_buf_out.addr;

endmodule
