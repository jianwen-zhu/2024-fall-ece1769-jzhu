############################################################
## This file is generated automatically by Vivado HLS.
## Please DO NOT edit it.
## Copyright (C) 2014 Xilinx Inc. All rights reserved.
############################################################
if { $argc != 2 } {
	puts "The script.tcl requires two input arguments: Project name, and solution name".
	puts "Please provide them!"
} else {
open_project [lindex $argv 0]
set_top dot_product
add_files dot_product.h
add_files dot_product.c
add_files -tb dot_product_tb.c
open_solution [lindex $argv 1]
set_part {xc7a100tlcsg324-2l}
create_clock -period 10 -name default
source "directives.tcl"
csynth_design
}
