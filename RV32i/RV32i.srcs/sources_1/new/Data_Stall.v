`timescale 1ps / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/03/12 08:46:15
// Design Name: 
// Module Name: Data_Stall
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


module Data_Stall(
        /*
        Load-Use Hazard Detection

        Check when using instruction is decoded in ID stage

        ALU operand register numbers in ID stage are given by
                ◦ IF/ID.RegisterRs, IF/ID.RegisterRt
                
        Load-use hazard when
                ◦ ID/EX.MemRead and
                ((ID/EX.RegisterRd = IF/ID.RegisterRs) or
                (ID/EX.RegisterRd = IF/ID.RegisterRt))

        If detected, stall and insert bubble

        REFERENCE:
        "ELEC5140
        Advanced Computer Architecture
        Prof. Wei Zhang, ECE, HKUST
        GENERAL INTRODUCTION"
        */

        // Input:
        input ID_EXE_mem_w,
        input [4:0] ID_EXE_written_reg,

        input [4:0] IF_ID_read_reg1,
        input [4:0] IF_ID_read_reg2,

        // Output:
        output reg PC_dstall,
        output reg IF_ID_dstall,
        output reg ID_EXE_dstall       
    );
    always @ (*) begin
        PC_dstall = 0;
        IF_ID_dstall = 0;
        ID_EXE_dstall = 0;
        if (ID_EXE_mem_w
        && ((ID_EXE_written_reg == IF_ID_read_reg1)
        || (ID_EXE_written_reg == IF_ID_read_reg2))) begin
            PC_dstall = 1;
            IF_ID_dstall = 1;
            ID_EXE_dstall = 1;
        end
    end
endmodule
