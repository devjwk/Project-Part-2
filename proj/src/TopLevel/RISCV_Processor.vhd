-------------------------------------------------------------------------
-- Henry Duwe
-- Department of Electrical and Computer Engineering
-- Iowa State University
-------------------------------------------------------------------------
-- RISCV_Processor.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file contains a skeleton of a RISCV_Processor
-- implementation.
-- 01/29/2019 by H3::Design created.
-- 04/10/2025 by AP::Coverted to RISC-V.
-- Integrated & Fixed by Assistant
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.RISCV_types.all;

entity RISCV_Processor is
    generic(N : integer := DATA_WIDTH);
    port(
        iCLK      : in std_logic;
        iRST      : in std_logic;
        iInstLd   : in std_logic;
        iInstAddr : in std_logic_vector(N-1 downto 0);
        iInstExt  : in std_logic_vector(N-1 downto 0);
        oALUOut   : out std_logic_vector(N-1 downto 0)
    );
end RISCV_Processor;

architecture structure of RISCV_Processor is

    -- [1] Required data memory signals (Skeleton Compliance)
    signal s_DMemWr   : std_logic; 
    signal s_DMemAddr : std_logic_vector(N-1 downto 0); 
    signal s_DMemData : std_logic_vector(N-1 downto 0); 
    signal s_DMemOut  : std_logic_vector(N-1 downto 0); 
    
    -- [2] Required register file signals (Skeleton Compliance)
    signal s_RegWr     : std_logic; 
    signal s_RegWrAddr : std_logic_vector(4 downto 0); 
    signal s_RegWrData : std_logic_vector(N-1 downto 0); 

    -- [3] Required instruction memory signals
    signal s_IMemAddr     : std_logic_vector(N-1 downto 0); 
    signal s_NextInstAddr : std_logic_vector(N-1 downto 0); 
    signal s_Inst         : std_logic_vector(N-1 downto 0); 

    -- [4] Required halt & overflow signals
    signal s_Halt : std_logic; 
    signal s_Ovfl : std_logic; 

    -- [5] Internal Control & Data Signals (User Logic)
    signal s_CurrentPC : std_logic_vector(31 downto 0);
    
    signal s_Funct3    : std_logic_vector(2 downto 0);
    signal s_Funct7    : std_logic_vector(6 downto 0);
    
    signal s_MemRead   : std_logic;
    -- s_MemWrite is mapped to s_DMemWr
    signal s_Branch    : std_logic;
    signal s_Jump      : std_logic_vector(1 downto 0);
    
    signal s_ALUSrcA   : std_logic;
    signal s_ALUSrcB   : std_logic;
    signal s_MemtoReg  : std_logic_vector(1 downto 0);
    signal s_ALUOp     : std_logic_vector(1 downto 0);
    signal s_ImmType   : std_logic_vector(2 downto 0);
    
    signal s_ReadData1 : std_logic_vector(31 downto 0);
    -- s_ReadData2 is mapped to s_DMemData
    
    signal s_Imm       : std_logic_vector(31 downto 0);
    signal s_ALUCtrl   : std_logic_vector(3 downto 0);
    
    signal s_ALUInputA : std_logic_vector(31 downto 0);
    signal s_ALUInputB : std_logic_vector(31 downto 0);
    signal s_ALUResult : std_logic_vector(31 downto 0); -- Internal ALU Result
    
    signal s_Zero      : std_logic;
    signal s_Sign      : std_logic;
    signal s_Cout      : std_logic;

    signal s_ReadData2 : std_logic_vector(31 downto 0); 
    signal s_LoadData : std_logic_vector(31 downto 0);
    signal s_ByteOffset : std_logic_vector(1 downto 0);


    -- ======================================================================
    -- Component Declarations
    -- ======================================================================

    -- 1. Memory (Provided by Skeleton)
    component mem is
        generic(
            ADDR_WIDTH : integer;
            DATA_WIDTH : integer
        );
        port(
            clk  : in std_logic;
            addr : in std_logic_vector((ADDR_WIDTH-1) downto 0); -- Fixed size mapping
            data : in std_logic_vector((DATA_WIDTH-1) downto 0);
            we   : in std_logic := '1';
            q    : out std_logic_vector((DATA_WIDTH -1) downto 0)
        );
    end component;

    -- 2. Control Unit
    component control_unit is
        port(
            i_Opcode   : in  std_logic_vector(6 downto 0);
            o_ALUSrc   : out std_logic;
            o_MemtoReg : out std_logic_vector(1 downto 0);
            o_RegWrite : out std_logic;
            o_MemRead  : out std_logic;
            o_MemWrite : out std_logic;
            o_Branch   : out std_logic;
            o_Jump     : out std_logic_vector(1 downto 0);
            o_ALUOp    : out std_logic_vector(1 downto 0);
            o_ImmType  : out std_logic_vector(2 downto 0);
            o_AUIPCSrc : out std_logic
        );
    end component;

    -- 3. Register File
    -- NOTE: Ensure your regfile.vhd entity name is 'regfile'
    component reg_file is
        port(
            i_CLK    : in  std_logic;
            i_RST    : in  std_logic;
            i_WE     : in  std_logic;
            i_WADDR  : in  std_logic_vector(4 downto 0);
            i_WDATA  : in  std_logic_vector(31 downto 0);
            i_RADDR1 : in  std_logic_vector(4 downto 0);
            i_RADDR2 : in  std_logic_vector(4 downto 0);
            o_RDATA1 : out std_logic_vector(31 downto 0);
            o_RDATA2 : out std_logic_vector(31 downto 0)
        );
    end component;

    -- 4. ALU
    component alu is
        port(
            i_A        : in  std_logic_vector(31 downto 0);
            i_B        : in  std_logic_vector(31 downto 0);
            i_ALUCtrl  : in  std_logic_vector(3 downto 0); 
            o_Result   : out std_logic_vector(31 downto 0);
            o_Zero     : out std_logic;
            o_Sign     : out std_logic; 
            o_Cout     : out std_logic  
        );
    end component;

    -- 5. ALU Control
    component alu_control is
        port(
            i_ALUOp   : in  std_logic_vector(1 downto 0);
            i_Funct3  : in  std_logic_vector(2 downto 0);
            i_Funct7  : in  std_logic_vector(6 downto 0);
            o_ALUCtrl : out std_logic_vector(3 downto 0)
        );
    end component;

    -- 6. Fetch Logic
    component fetch_logic is
        generic(N : integer := 32);
        port(
            i_PC        : in std_logic_vector(N-1 downto 0); 
            i_Imm       : in std_logic_vector(N-1 downto 0); 
            i_RS1       : in std_logic_vector(N-1 downto 0); 
            i_Branch    : in std_logic;                      
            i_Jump      : in std_logic_vector(1 downto 0);   
            i_Funct3    : in std_logic_vector(2 downto 0);   
            i_ALUZero   : in std_logic;                      
            i_ALUSign   : in std_logic;                      
            i_ALUCout   : in std_logic;                      
            o_NextPC    : out std_logic_vector(N-1 downto 0) 
        );
    end component;

    -- 7. Immediate Generator
    component imm_gen is
        port(
            i_Inst    : in  std_logic_vector(31 downto 0);
            i_ImmType : in  std_logic_vector(2 downto 0);
            o_Imm     : out std_logic_vector(31 downto 0)
        );
    end component;

    -- 8. PC Register
    component pc_reg is
        port(
            i_CLK    : in  std_logic;
            i_RST    : in  std_logic;
            i_WE     : in  std_logic;
            i_NextPC : in  std_logic_vector(31 downto 0);
            o_PC     : out std_logic_vector(31 downto 0)
        );
    end component;
    component load_extender is
    port(
        i_DMemOut : in  std_logic_vector(31 downto 0);
        i_Funct3  : in  std_logic_vector(2 downto 0);
        i_AddrLSB : in  std_logic_vector(1 downto 0);
        o_ReadData: out std_logic_vector(31 downto 0)
    );
    end component;

begin

    -- ======================================================================
    -- Instruction Memory Interface
    -- ======================================================================
    with iInstLd select
        s_IMemAddr <= s_CurrentPC when '0',
                      iInstAddr      when others;

    IMem: mem
        generic map(
            ADDR_WIDTH => ADDR_WIDTH,
            DATA_WIDTH => N
        )
        port map(
            clk  => iCLK,
            -- [CRITICAL FIX] Using ADDR_WIDTH-1 downto 0 (e.g. 9 downto 0 for 10 bits)
            addr => s_IMemAddr(ADDR_WIDTH+1 downto 2), 
            data => iInstExt,
            we   => iInstLd,
            q    => s_Inst
        );

    -- ======================================================================
    -- Data Memory Interface
    -- ======================================================================
    DMem: mem
        generic map(
            ADDR_WIDTH => ADDR_WIDTH,
            DATA_WIDTH => N
        )
        port map(
            clk  => iCLK,
            addr => s_DMemAddr(ADDR_WIDTH+1 downto 2),
            data => s_DMemData,
            we   => s_DMemWr,
            q    => s_DMemOut
        );

    -- Connect Skeleton Signals used for Output
    oALUOut <= s_DMemAddr; 

    -- ======================================================================
    -- Control Unit
    -- ======================================================================
    s_Funct3 <= s_Inst(14 downto 12);
    s_Funct7 <= s_Inst(31 downto 25);

    U_CONTROL : control_unit
        port map(
            i_Opcode   => s_Inst(6 downto 0),
            o_ALUSrc   => s_ALUSrcB,
            o_MemtoReg => s_MemtoReg,
            o_RegWrite => s_RegWr,       -- Connect to s_RegWr
            o_MemRead  => s_MemRead,
            o_MemWrite => s_DMemWr,      -- Connect to s_DMemWr (Important!)
            o_Branch   => s_Branch,
            o_Jump     => s_Jump,
            o_ALUOp    => s_ALUOp,
            o_ImmType  => s_ImmType,
            o_AUIPCSrc => s_ALUSrcA
        );

    -- ======================================================================
    -- PC & Fetch Logic
    -- ======================================================================
    U_PC : pc_reg
        port map(
            i_CLK    => iCLK,
            i_RST    => iRST,
            i_WE     => '1',
            i_NextPC => s_NextInstAddr,
            o_PC     => s_CurrentPC
        );

    U_FETCH : fetch_logic
        port map(
            i_PC      => s_CurrentPC,
            i_Imm     => s_Imm,
            i_RS1     => s_ReadData1,
            i_Branch  => s_Branch,
            i_Jump    => s_Jump,
            i_Funct3  => s_Funct3,
            i_ALUZero => s_Zero,
            i_ALUSign => s_Sign,
            i_ALUCout => s_Cout,
            o_NextPC  => s_NextInstAddr
        );

    -- ======================================================================
    -- Register File
    -- ======================================================================
    s_RegWrAddr <= s_Inst(11 downto 7);
    

    U_REGFILE : reg_file
        port map(
            i_CLK    => iCLK,
            i_RST    => iRST,
            i_WE     => s_RegWr,
            i_WADDR  => s_RegWrAddr,
            i_WDATA  => s_RegWrData,
            i_RADDR1 => s_Inst(19 downto 15),
            i_RADDR2 => s_Inst(24 downto 20),
            o_RDATA1 => s_ReadData1,
            o_RDATA2 => s_ReadData2 -- Internal signal (also goes to s_DMemData)
        );
        
    s_DMemData <= s_ReadData2; -- Hook up to DMem Input

    -- ======================================================================
    -- Immediate Generator
    -- ======================================================================
    U_IMM_GEN : imm_gen
        port map(
            i_Inst    => s_Inst,
            i_ImmType => s_ImmType,
            o_Imm     => s_Imm
        );

    -- ======================================================================
    -- ALU Section
    -- ======================================================================
    -- MUX A
    s_ALUInputA <= s_CurrentPC when s_ALUSrcA = '1' else s_ReadData1;
    
    -- MUX B
    s_ALUInputB <= s_Imm       when s_ALUSrcB = '1' else s_ReadData2;

    U_ALUCTRL : alu_control
        port map(
            i_ALUOp   => s_ALUOp,
            i_Funct3  => s_Funct3,
            i_Funct7  => s_Funct7,
            o_ALUCtrl => s_ALUCtrl
        );

    U_ALU : alu
        port map(
            i_A       => s_ALUInputA,
            i_B       => s_ALUInputB,
            i_ALUCtrl => s_ALUCtrl,
            o_Result  => s_ALUResult,
            o_Zero    => s_Zero,
            o_Sign    => s_Sign,
            o_Cout    => s_Cout
        );

    s_DMemAddr <= s_ALUResult; -- Hook up to DMem Address
    U_LOADEXT : load_extender
    port map(
        i_DMemOut  => s_DMemOut,       -- 32bit word from memory
        i_Funct3   => s_Funct3,        -- funct3 for load exteder (lb lh lw lbu lhu)
        i_AddrLSB  => s_ByteOffset,    -- address lower 2bit
        o_ReadData => s_LoadData       -- Sign/Zero sign extended
    );
    s_ByteOffset <= s_ALUResult(1 downto 0);
    -- ======================================================================
    -- Writeback MUX
    -- ======================================================================
    with s_MemtoReg select
        s_RegWrData <= s_DMemAddr                                     when "00", -- ALU
                       s_LoadData                                  when "01", -- Memory
                       std_logic_vector(unsigned(s_CurrentPC) + 4)    when "10", -- PC+4
                       s_Imm                                          when "11", -- Imm (LUI)
                       (others => '0')                                when others;

    -- ======================================================================
    -- Required Signals for Testbench
    -- ======================================================================
    
    -- 1. Overflow Signal (Placeholder as current ALU doesn't explicitly output overflow)
    s_Ovfl <= '0'; 

    -- 2. Halt Logic (FIXED: Prevents premature exit during reset)
    process(s_Inst, iRST)
    begin
        if (iRST = '1') then
            s_Halt <= '0';
        elsif (s_Inst(6 downto 0)) = "0000000" then
            s_Halt <= '1';
        else
            s_Halt <= '0';
        end if;
    end process;

end structure;