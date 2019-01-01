`timescale 1ns / 1ps
//----------------
// log:
// have to detect errors by 'aux' number.
// aux number: 8 bits length.
// --~~ -~ -> --~-~-~-~-~ : 1 clock 
// aux: 8bits. -> 0..255
//-------------------

/*
input signal:

output signal:
result-~-~-- === -~-~-~ === (count, ok, valid)


aux : same data * (segment_num_max)

function (prev_aux, aux):
	if nextcount(prev_aux) === aux :
		ok ++;
	elif 
	ry


	next && nowcount;;
	
	function next_aux;
		input [7:0] prev_aux; 
		input [7:0] samecount;
		input [7:0] maxaux;
		
		begin

		end
	
	endfunction

// calculate how many packets lost.
	function skip_count;
		input prev_aux;
		input samecount;
		input maxaux;

		begin

		end

*/
module detect_errors #(parameter whereis_aux = 0, segment_number_max = 50)(
	input wire clk,
	input wire rst,
	(* mark_debug = "true" *) input wire rx_en,
	(* mark_debug = "true" *) input wire [7:0] rx_data,
	(* mark_debug = "true" *) output reg [31:0] count,
	(* mark_debug = "true" *) output reg [31:0] ok,
	(* mark_debug = "true" *) output reg [31:0] ng,
	(* mark_debug = "true" *) output reg [31:0] lostnum,
	(* mark_debug = "true" *) output reg valid,
	(* mark_debug = "true" *) output reg [2:0] state
);

localparam maxcount = 500000;
localparam maxaux = 8'b11111111;

reg [15:0] count_edge;
reg [7:0] aux = maxaux;
reg [7:0] aux_prev;
reg [7:0] samecount;

wire aux_on = (whereis_aux == count_edge && rx_en);// && valid;
wire aux_on_1 = (whereis_aux + 1'b1 == count_edge);// && valid;
//wire [7:0] next_aux = (aux_prev == maxaux) ? 0 : (aux_prev + 1'b1);
//wire aux_ok = (aux == next_aux);
wire [7:0] next_samecount = (samecount == segment_number_max - 1)?
							0: samecount + 1;

//-~-~-~-^ function ----------------
function [7:0] next_aux_func;
	input [7:0] aux_prev;
	input [7:0] samecount;
	input [15:0] segment_number_max;

	begin
		if (samecount == segment_number_max - 1) begin
			next_aux_func = aux_prev + 1'b1;
		end
		else begin
			next_aux_func = aux_prev;
		end
	end
endfunction
//-~-~-~-~-~
function [31:0] calculate_losts;
	input [7:0] aux_prev;
	input [7:0] samecount;
	input [7:0] aux;
	input [15:0] segment_number_max;

	begin
		if (aux > aux_prev) begin
			calculate_losts = (segment_number_max - samecount - 1) + (aux - aux_prev - 1)*segment_number_max;
		end
		else begin
			calculate_losts = (segment_number_max - samecount - 1) + (segment_number_max - aux_prev + aux) * segment_number_max;
		end
	end
endfunction
// -------function----------

localparam state_init = 0;
localparam state_started = 1;
localparam state_running = 2;
localparam state_run = 3;
localparam state_inner = 4;
localparam state_finished = 7;

always @(posedge clk) begin
	if (rst) begin
		count_edge <= 16'b0;
		count <= 0;
		ok <= 0;
		valid <= 1'b0;
		aux <= 0;
		aux_prev <= 0;
		ng <= 0;
		lostnum <= 0;
		samecount <= 0;
		state = state_init;
	end
	else begin //!rst
	//------- counting edge.------
		if (rx_en) begin
			count_edge <= count_edge + 1'b1;
			if (aux_on) begin
				aux <= rx_data;
				aux_prev <= aux;
			end 
		end
		else begin
			count_edge <= 0;
		end
	//~~-~-~-~-~-~-~-~-~-~-~-~-~--
		case (state)
			state_init: begin
				if (aux_on_1) begin
					samecount <= 0;
					state = state_run;
				end
			end

			state_run: begin
				if (aux_on_1) begin
					count <= count + 1'b1;
					if (next_aux_func(aux_prev, samecount, segment_number_max) == aux) begin
						ok <= ok + 1'b1;
						samecount <= next_samecount;
					end
					else begin // not ok
						ng <= ng + 1'b1;
						samecount <= 0;
						lostnum <= lostnum + calculate_losts(aux_prev, samecount, aux, segment_number_max);
					end
				end

				if (count == maxcount) state = state_finished;
			end // end of state_run

			state_finished: begin
			end
		endcase
	end
/*
	else begin
		if (rx_en) begin
			count_edge <= count_edge + 1'b1;
		end else begin
			count_edge <= 0;

		end

	case (state)
		state_init: begin
			state = state_started;
		end

		state_started: begin// necessary??
			if (rx_en) begin
				valid <= 1'b1;
				if (aux_on) begin
					if (rx_data === 8'h00) begin
						aux <= rx_data;
						aux_prev <= aux;
						count <= count + 1'b1;
						ok <= ok + 1'b1;
						state <= state_running;
					end
				end
			end else begin
				valid <= 0;
			end
		end

		state_running: begin
			if (rx_en) begin
				valid <= 1'b1;
				if (aux_on) begin // 1 clock enable.
					aux <= rx_data;
					aux_prev <= aux;
				end
				else if (aux_on_1) begin
					count = count + 1'b1;
					if (aux_ok) begin
						ok = ok + 1'b1;
					end
				end
			end // END of " if (rx_en) "
			else begin // if !rx_en
				valid <= 0;
				if (count == maxcount) begin
					state <= state_finished;
				end
			end
		end // end of this state.

		state_finished: begin
			state = state_finished;
		end
	endcase
	end // end of !rst
*/
end // end of always block
endmodule