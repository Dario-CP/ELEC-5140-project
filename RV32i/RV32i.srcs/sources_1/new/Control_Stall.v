`timescale 1ps / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/03/12 08:45:29
// Design Name: 
// Module Name: Control_Stall
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


module Control_Stall(
        // input [1:0] Branch,  // Old
        input correct_prediction,
        output reg IF_ID_cstall,
        output reg ID_EXE_cstall,
        output reg PC_cstall    // New
    );
    always @ (*) begin
        // Old:
        // Stall whenever we take a branch or jump
        // IF_ID_cstall = 1'b0;
        // if (Branch[1:0] != 2'b00) begin
        //     IF_ID_cstall = 1'b1;
        // end

        // New:
        // Stall whenever we have a branch instruction (regardless of whether we take the branch)
        // We have a branch instruction if OPcode is 7'b1100011
        IF_ID_cstall = 1'b0;
        ID_EXE_cstall = 1'b0;
        PC_cstall = 1'b0;
        if (correct_prediction == 1'b0) begin
            IF_ID_cstall = 1'b1;    // 1 to stall
            ID_EXE_cstall = 1'b1;   // 1 to stall
            PC_cstall = 1'b0;       // 0 to not stall (used in testing)
        end
    end
endmodule
