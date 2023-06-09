`timescale 1ps / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/05/01 14:34:39
// Design Name: 
// Module Name: Forward_Unit
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Forwarding unit to perform data forwarding
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module Forward_Unit(
    /*
    Check whether the Destination registers written by current instruction 
    match the Source registers read by next instructions:
        ID/EX.WriteRegister (Rd) = IF/ID.ReadRegister1 (Rs)
        ID/EX.WriteRegister (Rd) = IF/ID.ReadRegister2 (Rt)
        EX/MEM.WriteRegister = IF/ID.ReadRegister1 
        EX/MEM.WriteRegister = IF/ID.ReadRegister2
        MEM/WB.WriteRegister = IF/ID.ReadRegister1
        MEM/WB.WriteRegister = IF/ID.ReadRegister2

    EX hazard
      // Rd = Rs
      ◦ if (EX/MEM.RegWrite and (EX/MEM.RegisterRd != 0)
        and (EX/MEM.RegisterRd = ID/EX.RegisterRs))
            Forward EX/MEM.RegisterRd to ID/EX.RegisterRs

      // Rd = Rt
      ◦ if (EX/MEM.RegWrite and (EX/MEM.RegisterRd != 0)
        and (EX/MEM.RegisterRd = ID/EX.RegisterRt))
            Forward EX/MEM.RegisterRd to ID/EX.RegisterRt
    
    MEM hazard
      // Rd = Rs
      ◦ if (MEM/WB.RegWrite and (MEM/WB.RegisterRd != 0)
        and not (EX/MEM.RegWrite and (EX/MEM.RegisterRd != 0) and (EX/MEM.RegisterRd = ID/EX.RegisterRs))   // not EX hazard
        and (MEM/WB.RegisterRd = ID/EX.RegisterRs))
            Forward MEM/WB.RegisterRd to ID/EX.RegisterRs 

      // Rd = Rt
      ◦ if (MEM/WB.RegWrite and (MEM/WB.RegisterRd != 0)
        and not (EX/MEM.RegWrite and (EX/MEM.RegisterRd != 0) and (EX/MEM.RegisterRd = ID/EX.RegisterRt))   // not EX hazard
        and (MEM/WB.RegisterRd = ID/EX.RegisterRt))
            Forward MEM/WB.RegisterRd to ID/EX.RegisterRt
    
    Note: The "// not EX hazard" line is added to prevent the MEM hazard from
    forwarding an outdated value from the MEM/WB pipeline register when there
    is an EX hazard. This is because the EX stage is executed before the MEM,
    and a newer instruction may have written to the register in the EX stage.

    REFERENCE:
    "ELEC5140
    Advanced Computer Architecture
    Prof. Wei Zhang, ECE, HKUST
    GENERAL INTRODUCTION"

    */
        // Input:
        input [4:0] ID_EXE_read_reg1,       // ID/EXE.ReadRegister1
        input [4:0] ID_EXE_read_reg2,       // ID/EXE.ReadRegister2

        input EXE_MEM_RegWrite,             // EXE/MEM.RegWrite
        input [4:0] EXE_MEM_written_reg,    // EXE/MEM.WriteRegister

        input MEM_WB_RegWrite,              // MEM/WB.RegWrite
        input [4:0] MEM_WB_written_reg,     // MEM/WB.WriteRegister

        // Output:
        output reg [1:0] forwarding_A_sig,  // forwarding signal for ALU input A (forwarding_A_sig = EXE_forwarding_A | MEM_forwarding_A)
        output reg [1:0] forwarding_B_sig  // forwarding signal for ALU input B (forwarding_B_sig = EXE_forwarding_B | MEM_forwarding_B)
    );

    always @(*) begin
        // Initialize the forwarding signals
        forwarding_A_sig = 2'b00;
        forwarding_B_sig = 2'b00;

        // EX hazard
        // Rd = Rs
        if ((EXE_MEM_RegWrite && EXE_MEM_written_reg != 0) 
        && (EXE_MEM_written_reg == ID_EXE_read_reg1)) begin
            // Note: 1'b1 means a binary value of 1 (the 1 on the right of the b)
            // with a width of 1 bit (the 1 on the left of the b)
            forwarding_A_sig[1] = 1'b1;   // Signal 1 to forward
        end
        else begin
            forwarding_A_sig[1] = 1'b0;   // Signal 0 to not forward
        end

        // Rd = Rt
        if ((EXE_MEM_RegWrite && EXE_MEM_written_reg != 0) 
        && (EXE_MEM_written_reg == ID_EXE_read_reg2)) begin
            forwarding_B_sig[1] = 1'b1;   // Signal 1 to forward
        end
        else begin
            forwarding_B_sig[1] = 1'b0;   // Signal 0 to not forward
        end

        // MEM hazard (only if there is no EX hazard)
        // Rd = Rs
        if ((MEM_WB_RegWrite && MEM_WB_written_reg != 0) 
        && (!(EXE_MEM_written_reg != 0 && (EXE_MEM_written_reg == ID_EXE_read_reg1)))   // not EX hazard
        && (MEM_WB_written_reg == ID_EXE_read_reg1)) begin
            forwarding_A_sig[0] = 1'b1;   // Signal 1 to forward
        end
        else begin
            forwarding_A_sig[0] = 1'b0;   // Signal 0 to not forward
        end

        // Rd = Rt
        if ((MEM_WB_RegWrite && MEM_WB_written_reg != 0) 
        && (!(EXE_MEM_written_reg != 0 && (EXE_MEM_written_reg == ID_EXE_read_reg2)))   // not EX hazard
        && (MEM_WB_written_reg == ID_EXE_read_reg2)) begin
            forwarding_B_sig[0] = 1'b1;   // Signal 1 to forward
        end
        else begin
            forwarding_B_sig[0] = 1'b0;   // Signal 0 to not forward
        end

    end
endmodule    
