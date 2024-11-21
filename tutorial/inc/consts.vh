`ifndef	_consts_vh_
`define	_consts_vh_

`define instr_width 	2
`define addr_width  	16
`define q_width     	3
`define q_size      	1<<`q_width
`define data_width		32
`define in_data_size	100
`define out_data_size	1

typedef struct packed {
  reg [`q_width-1:0]      jid;
  reg [`instr_width-1:0]  instr; 
  reg [`addr_width-1:0]   addr; 
} token;

`endif