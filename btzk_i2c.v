`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:49:33 07/13/2018 
// Design Name: 
// Module Name:    btzk_i2c 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: i2c master module for openephys
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module btzk_i2c #(
	parameter INPUT_CLK = 100000000,
   parameter BUS_CLK  = 400000
	 )(
    input btzk_i2c_clk,
    input btzk_i2c_reset_n,
    input btzk_i2c_ena,
    input [6:0] btzk_i2c_addr,
    input btzk_i2c_rw,
    input [7:0] btzk_i2c_data_wr,
    output reg [7:0] btzk_i2c_data_rd,
    output reg btzk_i2c_ack_err,
    output reg btzk_i2c_busy,
    inout btzk_i2c_scl,
    inout btzk_i2c_sda
    );
		localparam
		ready = 100,
		start = 101,
		command = 102,
		slv_ack1 = 103,
		wr			= 104,
		rd			= 105,
		slv_ack2	= 106,
		mstr_ack = 107,
		stop		= 108;
	integer divider = (INPUT_CLK / BUS_CLK) / 4; // Number of system clocks in 1/4 of an scl clock
	reg [7:0] state = ready;
	
	reg stretch;
	reg [32:0] count;
	reg data_clk;
	reg scl_clk;
	reg scl_ena = 0;
	reg sda_int = 1;
	reg sda_ena_n;
	reg [7:0] addr_rw;
	reg [7:0] data_tx;
	reg [7:0] data_rx;
	reg bit_cnt = 7;
	reg data_clk_prev;

	


	
	// generate scl and data clk timings
	always@(posedge btzk_i2c_clk) begin
		if (btzk_i2c_reset_n == 0) begin
			stretch <= 1'b0;
			count <= 0;
		end else begin
			data_clk_prev <= data_clk;
			if (count == divider*4 - 1) begin
				count <= 0;
			end else if (stretch == 0) begin
				count <= count + 1;
			end
			
			if ((count >= 0) && (count < divider)) begin
				scl_clk <= 1'b0;
				data_clk <= 1'b0;
			end else if ((count >= divider) && (count < divider*2)) begin
				scl_clk <= 1'b0;
				data_clk <= 1'b1;
			end else if ((count >=divider*2) && (count < divider*3)) begin
				scl_clk <= 1;
				if (btzk_i2c_scl == 0) begin
					stretch <= 1;  // detect if slave is stretching clock
				end else begin
					stretch <= 1'b0;
				end
				data_clk <= 1'b1;
			end else begin
				scl_clk <= 1'b1;
				data_clk <= 1'b0;
			end
		end
		
		if ((data_clk == 1) && (data_clk_prev == 0)) begin
			$display("Starting state machine");
			case (state)
				ready: begin
					if (btzk_i2c_ena) begin
						btzk_i2c_busy <= 1'b1;
						addr_rw <= btzk_i2c_addr & btzk_i2c_rw;
						data_tx <= btzk_i2c_data_wr;
						state <= start;
					end else begin
						btzk_i2c_busy <= 1'b0;
						state <= ready;
					end
				end
				
				start: begin
					btzk_i2c_busy <= 1;
					sda_int <= addr_rw[bit_cnt];
					state <= command;
				end
				
				command: begin
					// ?
					if (bit_cnt == 0) begin
						sda_int <= 1'b1;
						bit_cnt <= 7;
						state <= slv_ack1;
					end else begin
						bit_cnt <= bit_cnt - 1;
						sda_int <= addr_rw[bit_cnt-1];
						state <= command;
					end
				end
	
				slv_ack1: begin
					if (addr_rw[0] == 0) begin
						sda_int <= data_tx[bit_cnt];
						state <= wr;
					end else begin
						sda_int <= 1'b1;
						state <= rd;
					end
				end
				
				wr: begin
					btzk_i2c_busy <= 1'b1;
					if (bit_cnt == 0) begin
						sda_int <= 1'b1;
						bit_cnt <= 7;
						state <= slv_ack2;
					end else begin
						bit_cnt <= bit_cnt - 1;
						sda_int <= data_tx[bit_cnt-1];
						state <= wr;
					end
				end
				
				rd: begin
					btzk_i2c_busy <= 1'b1;
					if (bit_cnt == 0) begin
						if (btzk_i2c_ena == 1 && addr_rw == btzk_i2c_addr & btzk_i2c_rw) begin
							sda_int <= 1'b0;
						end else begin
							sda_int <= 1'b1;
						end
						bit_cnt <= 7;
						btzk_i2c_data_rd <= data_rx;
						state <= mstr_ack;
					end else begin
						bit_cnt <=bit_cnt-1;
						state <= rd;
					end
				end
				
				slv_ack2: begin
					if (btzk_i2c_ena == 1) begin
						btzk_i2c_busy <= 1'b0;
						addr_rw <= btzk_i2c_addr & btzk_i2c_rw;
						data_tx <= btzk_i2c_data_wr;
						if(addr_rw == btzk_i2c_addr & btzk_i2c_rw) begin
							sda_int <= btzk_i2c_data_wr[bit_cnt];
							state <= wr;
						end else begin
							state <= start;
						end
					end else begin
						state <= stop;
					end
				end
				
				mstr_ack: begin
					if (btzk_i2c_ena == 1) begin
						btzk_i2c_busy <= 1'b0;
						addr_rw <= btzk_i2c_addr & btzk_i2c_rw;
						data_tx <= btzk_i2c_data_wr;
						if (addr_rw == btzk_i2c_addr & btzk_i2c_rw) begin
							sda_int <= 1'b1;
							state <= rd;
						end else begin
							state <= start;
						end
					end else begin
						state <= stop;
					end
				end
				
				stop: begin
					btzk_i2c_busy <= 1'b0;
					state <= ready;
				end
				
				endcase
			end else if ((data_clk == 0) && (data_clk_prev == 1)) begin
				case (state)
					start: begin
						if (scl_ena == 0) begin
							scl_ena <= 1'b1;
							btzk_i2c_ack_err <= 1'b0;
						end
					end
					
					slv_ack1: begin
						if (btzk_i2c_sda != 0 || btzk_i2c_ack_err == 1) begin
							btzk_i2c_ack_err <= 1'b1;
						end
					end
					
					rd: begin
						data_rx[bit_cnt] <= btzk_i2c_sda;
					end
					
					slv_ack2: begin
						if (btzk_i2c_sda != 0 || btzk_i2c_ack_err == 1) begin
							btzk_i2c_ack_err <= 1'b1;
						end
					end
					
					stop: begin
						scl_ena <= 1'b0;
					end
					endcase
				end
			end

	always @(*) begin
		if (state == start) begin
			sda_ena_n <= data_clk_prev;
		end else if (state == stop) begin
			sda_ena_n <= ~data_clk_prev;
		end else begin
			sda_ena_n <= sda_int;
		end
	end
	
	assign btzk_i2c_scl = (scl_ena == 1 && scl_clk == 0) ? 1'b0 : 1'bz;
	//assign btzk_i2c_scl = scl_clk;
	assign btzk_i2c_sda = (sda_ena_n == 0) ? 1'b0 : 1'bz;
	//assign btzk_i2c_sda = sda_ena_n;

endmodule
