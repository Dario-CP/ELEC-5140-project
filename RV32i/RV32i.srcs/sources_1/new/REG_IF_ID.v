`timescale 1ps / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/03/10 21:05:36
// Design Name: 
// Module Name: REG_IF_ID
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


module REG_IF_ID(
        input clk,
        input rst, 
        input CE,
        input IF_ID_dstall,
        input IF_ID_cstall,
        
        input [31:0] inst_in,
        input [31:0] PC,
        input [31:0] Imm_32,
        input [31:0] add_branch_out,
        input zero_prediction,
        input is_bne,
        
        output reg [31:0] IF_ID_inst_in,
        output reg [31:0] IF_ID_PC = 0,
        output reg [31:0] IF_ID_Imm_32,
        output reg [31:0] IF_ID_add_branch_out,
        output reg IF_ID_zero_prediction,
        output reg IF_ID_is_bne

    );
    always @ (posedge clk or posedge rst) begin
        if (rst == 1) begin
            IF_ID_inst_in <= 32'h00000013;
            IF_ID_PC <= 32'h00000000;
        end
        // A bubble here is a nop, or rather, "addi x0, x0, 0"
        if (IF_ID_dstall == 0) begin
            if (rst == 1 || IF_ID_cstall == 1'b1) begin
                IF_ID_inst_in <= 32'h00000013;
                IF_ID_PC <= 32'h00000000;
                IF_ID_Imm_32 <= 32'h00000000;
                IF_ID_add_branch_out <= 32'h00000000;
                IF_ID_zero_prediction <= 1'b0;
                IF_ID_is_bne <= 1'b0;
            end
            else if (CE) begin
                IF_ID_inst_in <= inst_in;
                IF_ID_PC <= PC;
                IF_ID_Imm_32 <= Imm_32;
                IF_ID_add_branch_out <= add_branch_out;
                IF_ID_zero_prediction <= zero_prediction;
                IF_ID_is_bne <= is_bne;
            end
        end
        // else: if stall, then nothing changes here
    end
endmodule
