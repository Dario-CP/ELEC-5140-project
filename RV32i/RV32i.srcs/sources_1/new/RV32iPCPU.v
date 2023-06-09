`timescale 1ps / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/03/10 19:39:55
// Design Name: 
// Module Name: RV32iPCPU
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


module RV32iPCPU(
    input clk,
    input rst,
    input [31:0] data_in,   // MEM
    input [31:0] inst_in,   // IF, from PC_out
    
    output [31:0] ALU_out,  // From MEM, address out, for fetching data_in
    output [31:0] data_out, // From MEM, to be written into data memory
    output mem_w,           // From MEM, write valid, for store instructions
    output [31:0] PC_out    // From IF
    );
    wire V5;
    wire N0;
    wire [31:0] Imm_32;
    wire [31:0] add_branch_out;
    wire [31:0] add_jal_out;
    wire [31:0] add_jalr_out;
    wire [31:0] add_jalr_out_prov;

    wire [4:0] Wt_addr;
    wire [31:0] Wt_data;
    wire [31:0] rdata_A;
    wire [31:0] rdata_B;
    wire [31:0] PC_wb;
    wire [31:0] ALU_A;
    wire [31:0] ALU_B;
    assign V5 = 1'b1;
    assign N0 = 1'b0;
    
    
    wire zero_prediction;   // ID
    wire zero_correct;      // EXE
    wire correct_prediction;
    wire [31:0] unrecovered_PC;
    wire is_branch;
    wire is_bne;
    wire is_first_jalr;
    wire [1:0] Branch;      // IF
    wire [4:0] ALU_Control; // EXE
    wire ALUSrc_A;          // ID
    wire [1:0] ALUSrc_B;    // ID
    wire RegWrite;          // WB
    wire [1:0] DatatoReg;   // WB
    
    wire [1:0] B_H_W;       // WB // not used yet
    wire sign;              // WB // not used yet
//    wire RegDst; // WB
//    wire Jal; // WB
    
    // IF_ID
    wire [31:0] IF_ID_inst_in;
    wire [31:0] IF_ID_PC;
    wire [31:0] IF_ID_Imm_32;
    wire [31:0] IF_ID_Data_out;
    wire [31:0] IF_ID_add_branch_out;
    wire IF_ID_zero_prediction;
    wire IF_ID_is_bne;
    wire IF_ID_is_first_jalr;
    wire IF_ID_mem_w;
    wire IF_ID_mem_r;
    wire [4:0] IF_ID_written_reg;
    wire [4:0] IF_ID_read_reg1;
    wire [4:0] IF_ID_read_reg2;
    
    // ID_EXE
    wire [31:0] ID_EXE_inst_in;
    wire [31:0] ID_EXE_PC;
    wire [31:0] ID_EXE_Imm_32;
    wire [31:0] ID_EXE_ALU_A;
    wire [31:0] ID_EXE_ALU_B;
    wire ID_EXE_ALUSrc_A;
    wire [1:0] ID_EXE_ALUSrc_B;
    wire [31:0] ID_EXE_ALU_A_forward;
    wire [31:0] ID_EXE_ALU_B_forward;
    wire [31:0] ID_EXE_Data_out_forward;
    wire [4:0] ID_EXE_ALU_Control;
    wire [31:0] ID_EXE_Data_out;
    wire ID_EXE_mem_w;
    wire [1:0] ID_EXE_DatatoReg;
    wire ID_EXE_RegWrite;
    wire ID_EXE_zero_prediction;
    wire ID_EXE_is_bne;
    wire [31:0] ID_EXE_PC_after_flush;
    wire [4:0] ID_EXE_written_reg;
    wire [4:0] ID_EXE_read_reg1;
    wire [4:0] ID_EXE_read_reg2;
    
    wire [31:0] ID_EXE_ALU_out;

    // EXE_MEM
    wire [31:0] EXE_MEM_inst_in;
    wire [31:0] EXE_MEM_PC;
    wire [31:0] EXE_MEM_ALU_out;
    wire [31:0] EXE_MEM_Data_out;
    wire EXE_MEM_mem_w;
    wire [1:0] EXE_MEM_DatatoReg;
    wire EXE_MEM_RegWrite;
    wire [4:0] EXE_MEM_written_reg;
    wire [4:0] EXE_MEM_read_reg1;
    wire [4:0] EXE_MEM_read_reg2;
    
    // MEM_WB
    wire [31:0] MEM_WB_inst_in;
    wire [31:0] MEM_WB_PC;
    wire [31:0] MEM_WB_ALU_out;
    wire [31:0] MEM_WB_Data_in;
    wire [1:0] MEM_WB_DatatoReg;
    wire MEM_WB_RegWrite;
    wire [4:0] MEM_WB_written_reg;
   
    // Stall
    wire PC_dstall;
    wire PC_cstall;
    wire IF_cstall;
    wire IF_ID_cstall;
    wire IF_ID_dstall;
    wire ID_EXE_dstall;
    wire ID_EXE_cstall;

    // Forwarding
    wire [1:0] forwarding_A_sig;
    wire [1:0] forwarding_B_sig;


    Data_Stall _dstall_ (
        // Input:
        .ID_EXE_mem_r(ID_EXE_mem_r),

        .IF_ID_read_reg1(IF_ID_read_reg1),
        .IF_ID_read_reg2(IF_ID_read_reg2),
        
        .ID_EXE_written_reg(ID_EXE_written_reg),

        // Output:
        .PC_dstall(PC_dstall),
        .IF_ID_dstall(IF_ID_dstall),
        .ID_EXE_dstall(ID_EXE_dstall)
        );
        
    Control_Stall _cstall_ (
        // Input:
        .Branch(Branch[1:0]),
        .IF_ID_is_first_jalr(IF_ID_is_first_jalr),
        .correct_prediction(correct_prediction),
        // Output:
        .IF_cstall(IF_cstall),
        .IF_ID_cstall(IF_ID_cstall),
        .ID_EXE_cstall(ID_EXE_cstall),
        .PC_cstall(PC_cstall),
        .is_first_jalr(is_first_jalr)
        );

    assign ALU_out = EXE_MEM_ALU_out;
    assign data_out = EXE_MEM_Data_out;
    assign mem_w = EXE_MEM_mem_w;
    
    // IF:-------------------------------------------------------------------------------------------
    // Control Signals:
    //   1. Branch - MUX5 : ID
    // References:
    //   1. inst_in - MUX5 : ID
    //   2. rdata_A - MUX5 : ID
    //   3. Imm_32 - ADD_Branch : ID
    // Pass-on:
    //   1. inst_in (combinatorial)
    //   2. PC
    // Out:
    //   1. PC_out: for fetching inst_in

    SignExt _signed_ext_ (.inst_in(inst_in), .imm_32(Imm_32));   // Moved from ID stage to IF stage

    REG32 _pc_ (
        .CE(V5),
        .clk(clk),
        .D(PC_wb[31:0]),
        .rst(rst),
        .Q(PC_out[31:0]),
        .PC_dstall(PC_dstall),
        .PC_cstall(PC_cstall)
        );
    
    // Branch Predictor
    Gshare_Predictor _branch_predictor_ (
        // Input:
        .clk(clk),
        .rst(rst),
        .PC(PC_out),
        .OPcode(inst_in[6:0]),
        .Fun1(inst_in[14:12]),
        .correct_prediction(correct_prediction),
        .is_branch(is_branch),

        // Output:
        .Branch(Branch[1:0]),
        .zero_prediction(zero_prediction),
        .is_bne(is_bne)
        );

    add_32  ADD_Branch (
        .a(PC_out[31:0]),         // use the "PC" from IF stage
        .b(Imm_32[31:0]),           // From IF stage
        .c(add_branch_out[31:0])
        );
    add_32 ADD_JAL (
        .a(PC_out[31:0]),               // MIPS: PC+4, RISC-V: PC!!!
        .b({{11{inst_in[31]}}, inst_in[31], inst_in[19:12], inst_in[20], inst_in[30:21], 1'b0}),
        .c(add_jal_out[31:0])
        );
    add_32 ADD_JALR (
        .a(rdata_A[31:0]),  // We cannot get the most updated value of rdata_A from IF stage, so we need to stall for 1 cycle to get it at ID stage
        .b({{20{IF_ID_inst_in[31]}}, IF_ID_inst_in[31:20]}),    // From ID stage
        .c(add_jalr_out_prov[31:0])     // Provisional value
        );

    // If IF_cstall == 1, we fetch the same instruction again
    Mux2to1b32 MUX_JALR_SELECT (
        .I0(add_jalr_out_prov[31:0]),
        .I1(PC_out[31:0]),
        .s(IF_cstall),
        .o(add_jalr_out[31:0])
        );

    Mux4to1b32 MUX5 (
        .I0(PC_out[31:0] + 32'b0100),   // From IF stage (PC+4)             00
        .I1(add_branch_out[31:0]),      // From IF stage                    01
        .I2(add_jal_out[31:0]),         // From IF stage                    10
        .I3(add_jalr_out[31:0]),        // From ID stage                    11
        .s(Branch[1:0]),                // From IF stage
        .o(unrecovered_PC[31:0])
        );
    
    Mux2to1b32 Recover_PC (
        .I0(ID_EXE_PC_after_flush[31:0]),
        .I1(unrecovered_PC[31:0]),
        .s(correct_prediction),
        .o(PC_wb[31:0])
        );

    REG_IF_ID _if_id_ (
        .clk(clk), .rst(rst), .CE(V5),
        .IF_ID_dstall(IF_ID_dstall), .IF_ID_cstall(IF_ID_cstall),
        // Input
        .inst_in(inst_in),
        .PC(PC_out),
        .Imm_32(Imm_32),
        .add_branch_out(add_branch_out),
        .zero_prediction(zero_prediction),
        .is_bne(is_bne),
        .is_first_jalr(is_first_jalr),
        // Output
        .IF_ID_inst_in(IF_ID_inst_in),
        .IF_ID_PC(IF_ID_PC),
        .IF_ID_Imm_32(IF_ID_Imm_32),
        .IF_ID_add_branch_out(IF_ID_add_branch_out),
        .IF_ID_zero_prediction(IF_ID_zero_prediction),
        .IF_ID_is_bne(IF_ID_is_bne),
        .IF_ID_is_first_jalr(IF_ID_is_first_jalr)
        );

   // ID:-------------------------------------------------------------------------------------------
   // From IF:
   //   1. inst_in
   //   2. PC
   // Control Signals:
   //   1. RegWrite - Regs : WB
   //   2. ALUSrc_A / ALUSrc_B (stops here)
   // References:
   //   None
   // Pass-on:
   //   1. inst_in
       //   Control_signals {
       //   2. ALU_Control
       //   3. DatatoReg
       //   4. mem_w
       //   5. RegWrite
       //   }
   //   6. ALU_A
   //   7. ALU_B
   //   8. Data_out
   //   9. PC
   // Out:
   //   None
   
    Get_rw_regs _rw_regs_ (
        // Input:
        .inst_in(IF_ID_inst_in[31:0]),
        // Output:
        .written_reg(IF_ID_written_reg),    // Note that IF_ID_written_reg is just the destination register number obtained from decoding the instruction and is not in REG_IF_ID
        .read_reg1(IF_ID_read_reg1),        // Note that IF_ID_read_reg1 is just the operand1 register number obtained from decoding the instruction and is not in REG_IF_ID
        .read_reg2(IF_ID_read_reg2)         // Note that IF_ID_read_reg2 is just the operand2 register number obtained from decoding the instruction and is not in REG_IF_ID
        );

    Controler Ctrl_Unit (
        // Input:
        .OPcode(IF_ID_inst_in[6:0]),
        .Fun1(IF_ID_inst_in[14:12]),
        .Fun2(IF_ID_inst_in[31:25]),

        // Output:
        .ALUSrc_A(ALUSrc_A),
        .ALUSrc_B(ALUSrc_B[1:0]),
        .ALU_Control(ALU_Control[4:0]),
        .DatatoReg(DatatoReg[1:0]),
        .mem_w(IF_ID_mem_w),
        .mem_r(IF_ID_mem_r),            // 1 if the instruction reads from memory
        .RegWrite(RegWrite),
        .B_H_W(B_H_W),                  // not used yet
        .sign(sign)                     // not used yet
        );

    // Get the data from the register file
    Regs U2 (.clk(clk),
             .rst(rst),
             .L_S(MEM_WB_RegWrite),             // From Write-Back stage
             .R_addr_A(IF_ID_inst_in[19:15]),   // ID
             .R_addr_B(IF_ID_inst_in[24:20]),   // ID
             .Wt_addr(Wt_addr[4:0]),            // From Write-Back stage
             .Wt_data(Wt_data[31:0]),           // From Write-Back stage
             .rdata_A(rdata_A[31:0]),
             .rdata_B(rdata_B[31:0])
             );

    assign IF_ID_Data_out = rdata_B;    // for sw instruction, data from rs2 register written into memory, but we need to take into account data forwarding (_mux_forward_data_out_)

    REG_ID_EXE _id_exe_ (
        .clk(clk), .rst(rst), .CE(V5), .ID_EXE_dstall(ID_EXE_dstall), .ID_EXE_cstall(ID_EXE_cstall),
        // Input
        .inst_in(IF_ID_inst_in),
        .PC(IF_ID_PC),
        .Imm_32(IF_ID_Imm_32),
        //// To EXE stage, ALU Operands A & B
        .ALU_A(rdata_A[31:0]),
        .ALU_B(rdata_B[31:0]),
        //// To EXE stage, ALU operands source selection
        .ALUSrc_A(ALUSrc_A),
        .ALUSrc_B(ALUSrc_B),
        //// To EXE stage, ALU operation control signal
        .ALU_Control(ALU_Control),
        //// To MEM stage, for sw instruction, data from rs2 register written into memory
        .Data_out(IF_ID_Data_out),
        //// To MEM stage, for sw instruction, memor write enable signal
        .mem_w(IF_ID_mem_w),
        //// To ID stage, to detect load-use data hazard
        .mem_r(IF_ID_mem_r),
        //// To WB stage, for choosing different data written back to register file
        .DatatoReg(DatatoReg),
        //// To WB stage, register file write valid
        .RegWrite(RegWrite),
        //// For Data Hazard
        .written_reg(IF_ID_written_reg), .read_reg1(IF_ID_read_reg1), .read_reg2(IF_ID_read_reg2),
        .add_branch_out(IF_ID_add_branch_out),
        .zero_prediction(IF_ID_zero_prediction),
        .is_bne(IF_ID_is_bne),
        
        // Output
        .ID_EXE_inst_in(ID_EXE_inst_in),
        .ID_EXE_PC(ID_EXE_PC),
        .ID_EXE_Imm_32(ID_EXE_Imm_32),
        .ID_EXE_ALU_A(ID_EXE_ALU_A),    // Wire from REG_ID_EXE to the ALU Forwarding Multiplexer (A)
        .ID_EXE_ALU_B(ID_EXE_ALU_B),    // Wire from REG_ID_EXE to the ALU Forwarding Multiplexer (B)
        .ID_EXE_ALUSrc_A(ID_EXE_ALUSrc_A),
        .ID_EXE_ALUSrc_B(ID_EXE_ALUSrc_B),
        .ID_EXE_ALU_Control(ID_EXE_ALU_Control),
        .ID_EXE_Data_out(ID_EXE_Data_out),
        .ID_EXE_mem_w(ID_EXE_mem_w),
        .ID_EXE_mem_r(ID_EXE_mem_r),
        .ID_EXE_DatatoReg(ID_EXE_DatatoReg),
        .ID_EXE_RegWrite(ID_EXE_RegWrite),
        //// For Data Hazard
        .ID_EXE_written_reg(ID_EXE_written_reg), .ID_EXE_read_reg1(ID_EXE_read_reg1), .ID_EXE_read_reg2(ID_EXE_read_reg2),
        .ID_EXE_zero_prediction(ID_EXE_zero_prediction),
        .ID_EXE_PC_after_flush(ID_EXE_PC_after_flush),
        .ID_EXE_is_bne(ID_EXE_is_bne)
        );

    // EXE:-------------------------------------------------------------------------------------------
    // From ID:
    //   1. inst_in
        //   Control_signals {
        //   2. ALU_Control (stops here)
        //   3. mem_w
        //   4. DatatoReg
        //   5. RegWrite
        //   }
    //   6. ALU_A (stops here)
    //   7. ALU_B (stops here)
    //   8. Data_out
    //   9. PC
    // Control Signals:
    //   1. ALU_Control
    // References:
    //   None
    // Pass-on:
    //   1. inst_in
        //   Control_signals {
        //   2. DatatoReg (WB)
        //   3. mem_w (MEM)
        //   4. RegWrite (WB)
        //   }
    //   5. Data_out (used at MEM together with mem_w)
    //   6. ALU_out (Addr_out outside) (used at both MEM and WB)
    //   7. PC
    // Out:
    //   None

    // ALU Forwarding Multiplexer (A)
    Mux4to1b32 _mux_forward_alu_a_ (
        .I0(ID_EXE_ALU_A[31:0]),    // Wire from REG_ID_EXE
        .I1(Wt_data[31:0]),         // Output from MEM_WB Register
        .I2(EXE_MEM_ALU_out[31:0]), // Output from EXE_MEM Register
        .s(forwarding_A_sig[1:0]),  // Forwarding signal
        .o(ID_EXE_ALU_A_forward[31:0])   // Wire to ALU
        );
    
    // ALU Forwarding Multiplexer (B)
    Mux4to1b32 _mux_forward_alu_b_ (
        .I0(ID_EXE_ALU_B[31:0]),    // Wire from REG_ID_EXE
        .I1(Wt_data[31:0]),         // Output from MEM_WB Register
        .I2(EXE_MEM_ALU_out[31:0]), // Output from EXE_MEM Register
        .s(forwarding_B_sig[1:0]),  // Forwarding signal
        .o(ID_EXE_ALU_B_forward[31:0])   // Wire to ALU
        );
    
    // Data Out Forwarding Multiplexer
    Mux4to1b32 _mux_forward_data_out_ (
        .I0(ID_EXE_Data_out[31:0]),     // Wire from REG_ID_EXE
        .I1(Wt_data[31:0]),             // Output from MEM_WB Register
        .I2(EXE_MEM_ALU_out[31:0]),    // Output from EXE_MEM Register
        .s(forwarding_B_sig[1:0]),   // Forwarding signal
        .o(ID_EXE_Data_out_forward[31:0])   // Wire to EXE_MEM Register
        );
    
    Mux2to1b32 _alu_source_A_ (    // Moved from ID stage to EXE stage
        .I0(ID_EXE_ALU_A_forward[31:0]),
        .I1(ID_EXE_Imm_32[31:0]),   // not used 
        .s(ID_EXE_ALUSrc_A),
        .o(ALU_A[31:0])
        );

    Mux4to1b32 _alu_source_B_ (    // Moved from ID stage to EXE stage
        .I0(ID_EXE_ALU_B_forward[31:0]),
        .I1(ID_EXE_Imm_32[31:0]),
        .I2(),
        .I3(),
        .s(ID_EXE_ALUSrc_B[1:0]),
        .o(ALU_B[31:0]
        ));

    ALU _alualu_ (
        // Input:
        .A(ALU_A[31:0]),
        .B(ALU_B[31:0]),
        .ALU_operation(ID_EXE_ALU_Control[4:0]),
        .is_bne(ID_EXE_is_bne),
        // Output:
        .res(ID_EXE_ALU_out[31:0]),
        .overflow(),
        .zero_correct(zero_correct) // Now zero is calculated by ALU (connected to Branch Checker to determine if predicted correctly)
        );
    
    // Branch Checker
    Branch_Checker _branch_checker_ (
        // Input:
        .zero_correct(zero_correct),
        .ID_EXE_zero_prediction(ID_EXE_zero_prediction),
        .OPcode(ID_EXE_inst_in[6:0]),

        // Output:
        .correct_prediction(correct_prediction),
        .is_branch(is_branch)
        );

    REG_EXE_MEM _exe_mem_ (
        .clk(clk), .rst(rst), .CE(V5),
        // Input
        .inst_in(ID_EXE_inst_in),
        .PC(ID_EXE_PC),
        //// To MEM stage
        .ALU_out(ID_EXE_ALU_out),
        .Data_out(ID_EXE_Data_out_forward),
        .mem_w(ID_EXE_mem_w),
        //// To WB stage
        .DatatoReg(ID_EXE_DatatoReg),
        .RegWrite(ID_EXE_RegWrite),
        
        .written_reg(ID_EXE_written_reg), .read_reg1(ID_EXE_read_reg1), .read_reg2(ID_EXE_read_reg2),
        
        // Output
        .EXE_MEM_inst_in(EXE_MEM_inst_in),
        .EXE_MEM_PC(EXE_MEM_PC),
        .EXE_MEM_ALU_out(EXE_MEM_ALU_out),
        .EXE_MEM_Data_out(EXE_MEM_Data_out),
        .EXE_MEM_mem_w(EXE_MEM_mem_w),
        .EXE_MEM_DatatoReg(EXE_MEM_DatatoReg),
        .EXE_MEM_RegWrite(EXE_MEM_RegWrite),
        
        .EXE_MEM_written_reg(EXE_MEM_written_reg), .EXE_MEM_read_reg1(EXE_MEM_read_reg1), .EXE_MEM_read_reg2(EXE_MEM_read_reg2)
        );

    // MEM:-------------------------------------------------------------------------------------------
    // From EXE:
    //   1. inst_in
        //   Control_signals {
        //   2. DatatoReg (WB)
        //   3. mem_w (stops here)
        //   4. RegWrite (WB)
        //   }
    //   5. Data_out (stops here)
    //   6. ALU_out (Addr_out outside) (used at both MEM and WB)
    //   7. PC
    // Control Signals:
    //   1. mem_w
    // Pass-on:
    //   1. inst_in
        //   Control_signals {
        //   2. DatatoReg (WB)
        //   3. RegWrite (WB)
        //   }
    //   4. ALU_out (Addr_out outside) (used at both MEM and WB)
    //   5. PC
    //   6. Data_in
    // Out:
    //   Data_out & mem_w, ALU_out(as Addr_out)
    
    REG_MEM_WB _mem_wb_ (
        .clk(clk), .rst(rst), .CE(V5),
        // Input
        .inst_in(EXE_MEM_inst_in),
        .PC(EXE_MEM_PC),
        .ALU_out(EXE_MEM_ALU_out),
        .DatatoReg(EXE_MEM_DatatoReg),
        .RegWrite(EXE_MEM_RegWrite),
        .written_reg(EXE_MEM_written_reg),
        //// Comes from data memory
        .Data_in(data_in),
        
        // Output
        .MEM_WB_inst_in(MEM_WB_inst_in),
        .MEM_WB_PC(MEM_WB_PC),
        .MEM_WB_ALU_out(MEM_WB_ALU_out),
        .MEM_WB_DatatoReg(MEM_WB_DatatoReg),
        .MEM_WB_RegWrite(MEM_WB_RegWrite),
        .MEM_WB_Data_in(MEM_WB_Data_in),
        .MEM_WB_written_reg(MEM_WB_written_reg)
        );

    // WB:-------------------------------------------------------------------------------------------
    // From EXE:
    //   1. inst_in
       //   Control_signals {
       //   2. DatatoReg (WB)
       //   3. RegWrite (WB)
       //   }
    //   4. ALU_out (Addr_out outside) (used at both MEM and WB)
    // Local:
    wire [31:0] LoA_data;

    assign Wt_addr[4:0] = MEM_WB_inst_in[11:7]; // rd, except for branch and store instructions
    LUI_or_AUIPC _loa_ (
        .inst_in(MEM_WB_inst_in[31:0]),
        .PC(MEM_WB_PC),
        .data(LoA_data[31:0])
        );
    Mux4to1b32  MUX3 (
        .I0(MEM_WB_ALU_out[31:0]),          // Others
        .I1(MEM_WB_Data_in[31:0]),          // Load
        .I2(LoA_data[31:0]),                // LUI and AUIPC
        .I3(MEM_WB_PC[31:0] + 32'b0100),    // jal and jalr: PC + 4
        .s(MEM_WB_DatatoReg[1:0]),
        .o(Wt_data[31:0]));
    
    // Forward Unit
    Forward_Unit _forward_unit_ (
        // Input:
        .ID_EXE_read_reg1(ID_EXE_read_reg1),
        .ID_EXE_read_reg2(ID_EXE_read_reg2),

        .EXE_MEM_RegWrite(EXE_MEM_RegWrite),
        .EXE_MEM_written_reg(EXE_MEM_written_reg),

        .MEM_WB_RegWrite(MEM_WB_RegWrite),
        .MEM_WB_written_reg(MEM_WB_written_reg),

        // Output:
        .forwarding_A_sig(forwarding_A_sig),
        .forwarding_B_sig(forwarding_B_sig)
        );

endmodule
