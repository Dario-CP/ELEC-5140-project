`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.05.2023 19:33:16
// Design Name: 
// Module Name: Gshare_Predictor
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


module Gshare_Predictor(
    /*
    Gshare 8/8 two-level branch predictor
    8 bits BHR
    256 entries PHT
    2 bits saturating up/down predictors per entry
    
    PHT indexed by PC[9:2] XOR BHR[7:0]
    */

    // Input:
    input clk,
    input rst,
    input [31:0] PC,
    input [6:0] OPcode,
    input [2:0] Fun1,
    input correct_prediction,   // 1 if last prediction was correct, 0 if not
    input is_branch,            // 1 if last instruction was a branch, 0 if not

    // Output:
    output reg [1:0] Branch,
    output reg zero_prediction,	// If zero_prediction==1, then the branch is taken (except for BNE)
    output reg is_bne
    );

    // BHR
    reg [7:0] BHR = 8'b00000000;
    // PHT
    reg [1:0] PHT [0:255];
    integer i;
    initial begin   // Initialize the 256 entries of PHT to 2'b10
        for (i = 0; i < 256; i = i + 1) begin
            PHT[i] = 2'b10;
        end
    end

    // Indexing
    reg [7:0] index = 8'b00000000;
    always @ (*) begin
        index = {PC[9:2]} ^ {BHR[7:0]}; // PC[9:2] XOR BHR[7:0]
    end

    // Update BHR (on rising edge of clk)
    always @ (posedge clk or posedge rst) begin
        if (rst == 1) begin
            BHR = 8'b00000000;     // Reset back to 0
        end
        else begin
            // If last instruction was a branch, shift BHR left by 1 and add correct prediction to LSB
            if (is_branch == 1) begin
                BHR = {BHR[6:0], correct_prediction};
            end
        end
    end

    // Make new prediction (on falling edge of clk)
    always @ (negedge clk) begin
        // Initialize Branch to 00
        Branch = 0;
        // Put MSB of PHT[index] into zero_prediction
        zero_prediction = PHT[index][1];

        is_bne = 0;

        // Calculate Branch (Previously done in Control Unit)
        case (OPcode)
            // Branch instructions
            7'b1100011: begin	// Branch
                case (Fun1)
                    3'b000: begin // BEQ
                        Branch = {1'b0, zero_prediction};
                    end 
                    3'b001: begin // BNE
                        Branch = {1'b0, zero_prediction};
                        // Indicate that this is a BNE instruction
                        // So that the zero_correct in the ALU is flipped
                        is_bne = 1;
                    end
                    3'b100: begin // BLT
                        Branch = {1'b0, zero_prediction};
                    end
                    3'b101: begin // BGE
                        Branch = {1'b0, zero_prediction};
                    end
                    3'b110: begin // BLTU
                        Branch = {1'b0, zero_prediction};
                    end
                    3'b111: begin // BGEU
                        Branch = {1'b0, zero_prediction};
                    end
                endcase
            end

            // Jump instructions
            7'b1101111: begin	// jal
				Branch = 2'b10;
			end
            7'b1100111: begin   // jalr
                Branch = 2'b11;
            end
        endcase
    end

    // Update PHT with the last prediction (on rising edge of clk)
    always @ (posedge clk or posedge rst) begin
        if (rst == 1) begin
            // Reset back to weakly taken all entries
            for (i = 0; i < 256; i = i + 1) begin
                PHT[i] = 2'b10;
            end
        end
        else begin
            // If last instruction was a branch, update PHT
            if (is_branch == 1) begin
                // If last prediction was correct, increment PHT (up to 11)
                if (correct_prediction == 1) begin
                    if (PHT[index] < 2) begin
                        PHT[index] = PHT[index] + 1;
                    end
                end
                // Else, decrement PHT (down to 00)
                else begin
                    if (PHT[index] > 0) begin
                        PHT[index] = PHT[index] - 1;
                    end
                end
            end
        end
    end

endmodule
