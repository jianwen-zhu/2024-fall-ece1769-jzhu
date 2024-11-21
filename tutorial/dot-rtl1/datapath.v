module datapath #(parameter P_WIDTH=32)(

	input [P_WIDTH-1:0] input_a,
	input [P_WIDTH-1:0] input_b,
	input clk,
	input rst,
	output [P_WIDTH-1:0] out
	);


wire [P_WIDTH-1:0] mult_result;
wire [P_WIDTH-1:0] adder_out;
reg [P_WIDTH-1:0] adder_out_reg;

assign mult_result = input_a * input_b;
assign adder_out  = adder_out_reg + mult_result;
assign out = adder_out_reg;

always @(posedge clk)
 if (rst ==1) 
	adder_out_reg <= adder_out;
 else
	adder_out_reg <= 0;



endmodule