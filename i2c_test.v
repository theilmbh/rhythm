`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   17:00:37 07/14/2018
// Design Name:   btzk_i2c
// Module Name:   /home/brad/code/openephys/rhythm/i2c_test.v
// Project Name:  RHD2000InterfaceXEM6010
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: btzk_i2c
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module i2c_test;

	// Inputs
	reg btzk_i2c_clk;
	reg btzk_i2c_reset_n;
	reg btzk_i2c_ena;
	reg [6:0] btzk_i2c_addr;
	reg btzk_i2c_rw;
	reg [7:0] btzk_i2c_data_wr;

	// Outputs
	wire [7:0] btzk_i2c_data_rd;
	wire btzk_i2c_ack_err;
	wire btzk_i2c_busy;

	// Bidirs
	wire btzk_i2c_scl;
	wire btzk_i2c_sda;

	// Instantiate the Unit Under Test (UUT)
	btzk_i2c uut (
		.btzk_i2c_clk(btzk_i2c_clk), 
		.btzk_i2c_reset_n(btzk_i2c_reset_n), 
		.btzk_i2c_ena(btzk_i2c_ena), 
		.btzk_i2c_addr(btzk_i2c_addr), 
		.btzk_i2c_rw(btzk_i2c_rw), 
		.btzk_i2c_data_wr(btzk_i2c_data_wr), 
		.btzk_i2c_data_rd(btzk_i2c_data_rd), 
		.btzk_i2c_ack_err(btzk_i2c_ack_err), 
		.btzk_i2c_busy(btzk_i2c_busy), 
		.btzk_i2c_scl(btzk_i2c_scl), 
		.btzk_i2c_sda(btzk_i2c_sda)
	);

	initial begin
		// Initialize Inputs
		btzk_i2c_clk = 0;
		btzk_i2c_reset_n = 0;
		btzk_i2c_ena = 0;
		btzk_i2c_addr = 0;
		btzk_i2c_rw = 0;
		btzk_i2c_data_wr = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		btzk_i2c_addr <= 7'h55;
		btzk_i2c_data_wr <= 8'hAD;
		btzk_i2c_ena <= 1;
		btzk_i2c_reset_n <= 1;

	end
	
	always 
		#5 btzk_i2c_clk = ~btzk_i2c_clk;
      
endmodule

