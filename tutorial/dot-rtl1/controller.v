module controller #(parameter P_ADDR_WIDTH=8, parameter P_COUNT=100)(
	input clk,
	input rst,
	output reg out_rst,
	output reg ce_0,
	output reg ce_1,
	output reg we_0,
	output reg we_1,

	input  [P_ADDR_WIDTH-1:0] cjob_offset,
	output [P_ADDR_WIDTH-1:0] address_0,
	output [P_ADDR_WIDTH-1:0] address_1,
	// INPUT FIFO SIGNALS
	input fin_buf_empty,
	output fin_rd_en,
	// OUTPUT FIFO SIGNALS
	input fout_buf_full,
	output fout_wr_en,
	// CURRENT JOB REGISTER SIGNALS
	output cjob_load_en,
	output cjob_out_en
);

parameter IDLE= 7'b0000001,JOB_LOAD= 7'b0000010,  PREP=7'b0000100, PROCESSING = 7'b0001000, WRITE_BACK=7'b0010000, WAIT_Q=7'b0100000, WRITE_Q=7'b1000000;
reg [6:0] curr_state;
reg [6:0] next_state;
reg [P_ADDR_WIDTH-1:0] counter;
reg [P_ADDR_WIDTH-1:0] offset;

always @(curr_state,fin_buf_empty,counter,fout_buf_full)
begin
	next_state=5'b00000;
	case (curr_state)	
		IDLE:
			if(!fin_buf_empty)
				next_state=IDLE;
			else
				next_state=JOB_LOAD;
		JOB_LOAD:
			next_state=PREP;
		PREP:
			next_state=PROCESSING;
		PROCESSING:
			if(counter<P_COUNT-1+offset)			
				next_state = PROCESSING;
			else
				next_state = WRITE_BACK;
		WRITE_BACK:
			next_state=WAIT_Q;
		WAIT_Q:
			if(!fout_buf_full)
				next_state=WAIT_Q;
			else
				next_state=WRITE_Q;
		WRITE_Q:
			next_state=IDLE;
		default:
			next_state=IDLE;
	endcase
end

always @(posedge clk)       
begin
	if(rst==1)
		curr_state <= IDLE;
	else
		curr_state <= next_state;
end

always @(posedge clk)       
begin
	case(curr_state)
		IDLE:	begin
			out_rst<=0;
			ce_0<=0;
			ce_1<=0;
			we_0<=0;
			we_1<=0;
			counter <= 0;
			fin_rd_en<=0;
			fout_wr_en<=0;
			cjob_load_en<=0;
			cjob_out_en<=0;
			offset<=0;
			end
		JOB_LOAD:
			begin
			fin_rd_en<=1;
			end
		PREP:
			begin
			fin_rd_en<=0;
			ce_0<=1;
			ce_1<=1;
			we_0<=0;
			we_1<=0;
			cjob_load_en<=1;
			counter<=cjob_offset;
			offset<=cjob_offset;
			end
		PROCESSING:
			begin
			cjob_load_en<=0;
			out_rst<=1;
			counter<= counter+1;
			end
		WRITE_BACK:
			begin
			ce_1<=0;
			we_0<=1;
			counter<=counter+P_COUNT;
			end
		WAIT_Q:
			begin
			ce_0<=0;
			counter<=0;
			end
		WRITE_Q:
			begin
			fout_wr_en<=1;
			cjob_out_en<=1;
			end
		default:
			begin
			end
	endcase
end

assign address_0 = counter<<2;
assign address_1 = (counter+P_COUNT)<<2;


endmodule
