`timescale 1ps / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/03/10 19:39:55
// Design Name: 
// Module Name: ALU
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ALU(
	input [31:0] A,
	input [31:0] B,
	input [4:0] ALU_operation,
	input is_bne,
	output reg signed [31:0] res,
	output reg overflow,
	output wire zero_correct	// If zero_correct==1 and it is a branch instruction, then the branch should have been taken
    );
	reg flip_zero;	// If flip_zero==1, we need to flip the zero signal before outputing
	wire res_temp;
	assign res_temp = res;
	parameter one = 32'h00000001, zero_0 = 32'h00000000;
	wire signed [31:0] A_temp, B_temp;
	assign A_temp = A;
	assign B_temp = B;
	// always @ (A or B or ALU_operation) begin
    always @ (*) begin
		flip_zero = 0;
		case (ALU_operation)
			5'b00000: begin	// and
				res = A & B;
				overflow = 0;
			end
			5'b00001: begin	// or
				res = A | B;
				overflow = 0;
			end
			5'b00010: begin	// add
				res = A_temp + B_temp;
				if ((A[31] == 1 && B[31] == 1 && res[31] == 0) || (A[31] == 0 && B[31] == 0 && res[31] == 1))
					overflow = 1;
				else overflow = 0;
			end
			5'b00011: begin	// sub (and BEQ and BNE)
				res = A_temp - B_temp;
				if ((A[31] == 1 && B[31] == 0 && res[31] == 0) || (A[31] == 0 && B[31] == 1 && res[31] == 1))
					overflow = 1;
				else overflow = 0;
				// If it is a BNE, flip the zero signal
				if (is_bne == 1'b1)
					flip_zero = 1;
			end
            5'b00100: begin // XOR
                res = A ^ B;
                overflow = 0;
            end
			5'b00101: begin	// SLT (and BLT)
				res = (A_temp < B_temp) ? one : zero_0;
				flip_zero = 1;	// For BLT
				overflow = 0;				
			end
            5'b00110: begin // SLTU (and BLTU)
                res = (A < B) ? one : zero_0;
				flip_zero = 1;	// For BLTU
                overflow = 0;
            end
            5'b00111: begin // SLL
                res = (A << B);
                overflow = 0;
            end
            5'b01000: begin // SRL
                res = (A >> B);
                overflow = 0;
            end
            5'b01001: begin // SRA
                res = (A_temp >> B);
                overflow = 0;
			end
			5'b01010: begin // BGE
                res = (A_temp >= B_temp) ? zero_0 : one;
                overflow = 0;
			end
            5'b01011: begin // BGEU
                res = (A >= B) ? zero_0 : one;
                overflow = 0;
            end
			default: res = 32'hx;
		endcase
	end
	assign zero_correct = (res == 0) ? ~flip_zero : flip_zero;

endmodule
