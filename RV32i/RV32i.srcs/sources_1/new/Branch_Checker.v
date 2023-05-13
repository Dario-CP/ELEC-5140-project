`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10.05.2023 22:09:27
// Design Name: 
// Module Name: Branch_Checker
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


module Branch_Checker(
    // Input:
    input zero_correct,
    input ID_EXE_zero_prediction,
    input [6:0] OPcode,

    // Output:
    output reg correct_prediction,
    output reg is_branch
    );

    always @(*) begin
        // If ID_EXE_ALU_Control is 7'b1100011, then the instruction is a branch and we need to check the prediction
        if (OPcode == 7'b1100011) begin
            is_branch = 1'b1;
            if (zero_correct == ID_EXE_zero_prediction) begin
                correct_prediction = 1'b1;
            end else begin
                correct_prediction = 1'b0;
            end
        end else begin
            is_branch = 1'b0;
            correct_prediction = 1'b1;
        end
    end

endmodule
