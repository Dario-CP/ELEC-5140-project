`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.05.2023 19:33:16
// Design Name: 
// Module Name: gshare_predictor
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


module gshare_predictor(
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
    input [1:0] branch,
    input [1:0] correct_prediction, // 1 if last prediction was correct, 0 if not

    // Output:
    output reg [1:0] prediction
    );

    // BHR
    reg [7:0] BHR = 8'b00000000;
    // PHT
    reg [1:0] PHT [255:0] = {256{2'b10}};   // Initialize to weakly taken

    // Indexing
    always @ (PC or BHR) begin  // When either PC or BHR changes
        reg [7:0] index = PC[9:2] ^ BHR[7:0];   // PC[9:2] XOR BHR[7:0]
    end

    // Update BHR
    always @ (posedge clk or posedge rst) begin
        if (rst == 1) begin
            BHR <= 8'b00000000;     // Reset back to 0
        end
        else begin
            // Shift BHR left by 1 and add branch result to LSB
            BHR <= {BHR[6:0], branch};
        end
    end

    // Make new prediction
    always @ (negedge clk or posedge rst) begin
        if (rst == 1) begin
            prediction <= 2'b10;    // Reset back to weakly taken
        end
        else begin
            prediction <= PHT[index];
        end
    end

    // Update PHT with the last prediction
    always @ (posedge clk or posedge rst) begin
        if (rst == 1) begin
            // Reset back to weakly taken all entries
            PHT <= {256{2'b10}};
        end
        else begin
            // If last prediction was correct, increment PHT (up to 11)
            if (correct_prediction == 1) begin
                if (PHT[index] < 2) begin
                    PHT[index] <= PHT[index] + 1;
                end
            end
            // Else, decrement PHT (down to 00)
            else begin
                if (PHT[index] > 0) begin
                    PHT[index] <= PHT[index] - 1;
                end
            end
        end
    end

endmodule
