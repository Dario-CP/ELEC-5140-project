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
        input [1:0] Branch,
        input IF_ID_is_first_jalr,  // 1 if it was the first jalr out of the 2 in the bubble, 0 otherwise
        input correct_prediction,
        output reg IF_cstall,   ////////////////////////// ADD to main file
        output reg IF_ID_cstall,
        output reg ID_EXE_cstall,
        output reg PC_cstall,    // Unsused
        output reg is_first_jalr
    );
    // Stalls for flushing the pipeline when the branch prediction is wrong
    always @ (*) begin
        IF_ID_cstall = 1'b0;
        ID_EXE_cstall = 1'b0;
        PC_cstall = 1'b0;
        is_first_jalr = 1'b1;
        // Stall IF_ID and ID_EXE if the branch prediction was wrong
        if (correct_prediction == 1'b0) begin
            IF_ID_cstall = 1'b1;    // 1 to stall
            ID_EXE_cstall = 1'b1;   // 1 to stall
        end

    // Stall IF_ID if the branch was a JALR instruction
    // We will only stall one, the second time that the JALR instruction is detected,
        // Stall IF if the branch was a JALR instruction
        else if (Branch == 2'b11) begin
            if (IF_ID_is_first_jalr == 1'b1) begin
                IF_cstall = 1'b1;    // 1 to stall
                is_first_jalr = 1'b0;
            end else begin
                IF_cstall = 1'b0;    // 0 to not stall
                is_first_jalr = 1'b0;
            end
        end
    end
endmodule
