`include "consts.vh"

module cjob_register #(parameter P_ADDR_WIDTH=`addr_width)
(
	input clk,
	input rst,
	input load,
	input out_en,
	input token data_in,
	output token data_out
);

token current_job;


always @(posedge clk) begin
	if(rst) begin
		data_out = 0;
		current_job = 0;
	end
	else begin
		if (load) current_job = data_in;
		if(out_en) data_out = current_job;
    end
end


endmodule