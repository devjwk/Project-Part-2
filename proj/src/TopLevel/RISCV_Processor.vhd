-------------------------------------------------------------------------
-- Henry Duwe
-- Department of Electrical and Computer Engineering
-- Iowa State University
-------------------------------------------------------------------------
-- RISCV_Processor.vhd
-------------------------------------------------------------------------
-- Single-Cycle 기반 설계를 5-stage Software-Scheduled Pipeline으로 확장한 버전
-- IF / ID / EX / MEM / WB 파이프라인, NO forwarding / NO stalls (소프트웨어 NOP 스케줄링 가정)
-- Test framework 요구 사항 만족:
--   - s_Halt 는 HALT(wfi) 인스트럭션이 WB 단계에 도달했을 때만 '1' 이 됨
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

    ---------------------------------------------------------------------
    -- [1] Skeleton에서 요구하는 기본 신호 (그대로 유지)
    ---------------------------------------------------------------------
    signal s_DMemWr   : std_logic;
    signal s_DMemAddr : std_logic_vector(N-1 downto 0);
    signal s_DMemData : std_logic_vector(N-1 downto 0);
    signal s_DMemOut  : std_logic_vector(N-1 downto 0);

    signal s_RegWr     : std_logic;
    signal s_RegWrAddr : std_logic_vector(4 downto 0);
    signal s_RegWrData : std_logic_vector(N-1 downto 0);

    signal s_IMemAddr     : std_logic_vector(N-1 downto 0);
    signal s_NextInstAddr : std_logic_vector(N-1 downto 0);
    signal s_Inst         : std_logic_vector(N-1 downto 0);

    signal s_Halt : std_logic;
    signal s_Ovfl : std_logic;

    ---------------------------------------------------------------------
    -- [2] 싱글 사이클에서 쓰던 내부 신호 (이름 유지)
    ---------------------------------------------------------------------
    signal s_CurrentPC : std_logic_vector(31 downto 0);

    signal s_Funct3   : std_logic_vector(2 downto 0);
    signal s_Funct7   : std_logic_vector(6 downto 0);

    signal s_MemRead  : std_logic;
    -- s_DMemWr is MemWrite
    signal s_Branch   : std_logic;
    signal s_Jump     : std_logic_vector(1 downto 0);

    signal s_ALUSrcA  : std_logic;
    signal s_ALUSrcB  : std_logic;
    signal s_MemtoReg : std_logic_vector(1 downto 0);
    signal s_ALUOp    : std_logic_vector(1 downto 0);
    signal s_ImmType  : std_logic_vector(2 downto 0);

    signal s_ReadData1 : std_logic_vector(31 downto 0);
    signal s_ReadData2 : std_logic_vector(31 downto 0);

    signal s_Imm       : std_logic_vector(31 downto 0);
    signal s_ALUCtrl   : std_logic_vector(3 downto 0);

    signal s_ALUInputA : std_logic_vector(31 downto 0);
    signal s_ALUInputB : std_logic_vector(31 downto 0);
    signal s_ALUResult : std_logic_vector(31 downto 0);

    signal s_Zero      : std_logic;
    signal s_Sign      : std_logic;
    signal s_Cout      : std_logic;

    signal s_LoadData  : std_logic_vector(31 downto 0);
    signal s_ByteOffset: std_logic_vector(1 downto 0);

    ---------------------------------------------------------------------
    -- [3] 파이프라인용 추가 신호
    ---------------------------------------------------------------------

    -- IF/ID
    signal s_IFID_PC    : std_logic_vector(31 downto 0);
    signal s_IFID_Inst  : std_logic_vector(31 downto 0);
    signal s_IF_Flush   : std_logic := '0';  -- Part 1: 하드웨어 flush 없음 (소프트웨어 NOP 스케줄링 가정)
    signal s_ID_Flush   : std_logic := '0';

    -- ID stage 디코드 결과
    signal s_ID_RegWrite : std_logic;
    signal s_ID_MemRead  : std_logic;
    signal s_ID_MemWrite : std_logic;
    signal s_ID_MemtoReg : std_logic_vector(1 downto 0);
    signal s_ID_ALUSrcA  : std_logic;
    signal s_ID_ALUSrcB  : std_logic;
    signal s_ID_ALUOp    : std_logic_vector(1 downto 0);
    signal s_ID_Branch   : std_logic;
    signal s_ID_Jump     : std_logic_vector(1 downto 0);
    signal s_ID_ImmType  : std_logic_vector(2 downto 0);
    signal s_ID_Halt     : std_logic;  -- HALT(wfi) 디코드용

    -- ID/EX
    signal s_EX_RegWrite : std_logic;
    signal s_EX_MemRead  : std_logic;
    signal s_EX_MemWrite : std_logic;
    signal s_EX_MemtoReg : std_logic_vector(1 downto 0);
    signal s_EX_ALUSrcA  : std_logic;
    signal s_EX_ALUSrcB  : std_logic;
    signal s_EX_ALUOp    : std_logic_vector(1 downto 0);
    signal s_EX_Branch   : std_logic;
    signal s_EX_Jump     : std_logic_vector(1 downto 0);

    signal s_EX_PC        : std_logic_vector(31 downto 0);
    signal s_EX_ReadData1 : std_logic_vector(31 downto 0);
    signal s_EX_ReadData2 : std_logic_vector(31 downto 0);
    signal s_EX_Imm       : std_logic_vector(31 downto 0);
    signal s_EX_Funct3    : std_logic_vector(2 downto 0);
    signal s_EX_Funct7    : std_logic_vector(6 downto 0);
    signal s_EX_Rs1       : std_logic_vector(4 downto 0);
    signal s_EX_Rs2       : std_logic_vector(4 downto 0);
    signal s_EX_Rd        : std_logic_vector(4 downto 0);
    signal s_EX_Halt      : std_logic;

    -- EX/MEM
    signal s_MEM_RegWrite : std_logic;
    signal s_MEM_MemRead  : std_logic;
    signal s_MEM_MemWrite : std_logic;
    signal s_MEM_MemtoReg : std_logic_vector(1 downto 0);
    signal s_MEM_PCPlus4  : std_logic_vector(31 downto 0);
    signal s_MEM_ALUResult: std_logic_vector(31 downto 0);
    signal s_MEM_WriteData: std_logic_vector(31 downto 0);
    signal s_MEM_Imm      : std_logic_vector(31 downto 0);
    signal s_MEM_Rd       : std_logic_vector(4 downto 0);
    signal s_MEM_Funct3   : std_logic_vector(2 downto 0);
    signal s_MEM_Halt     : std_logic;

    -- MEM/WB
    signal s_WB_RegWrite  : std_logic;
    signal s_WB_MemtoReg  : std_logic_vector(1 downto 0);
    signal s_WB_ReadData  : std_logic_vector(31 downto 0);
    signal s_WB_ALUResult : std_logic_vector(31 downto 0);
    signal s_WB_PCPlus4   : std_logic_vector(31 downto 0);
    signal s_WB_Imm       : std_logic_vector(31 downto 0);
    signal s_WB_Rd        : std_logic_vector(4 downto 0);
    signal s_WB_Halt      : std_logic;

    -- 실제 WB에서 레지스터 파일에 쓰여지는 값
    signal s_WB_WriteData : std_logic_vector(31 downto 0);

    ---------------------------------------------------------------------
    -- [4] 컴포넌트 선언
    ---------------------------------------------------------------------

    -- Memory
    component mem is
        generic(
            ADDR_WIDTH : integer;
            DATA_WIDTH : integer
        );
        port(
            clk  : in std_logic;
            addr : in std_logic_vector((ADDR_WIDTH-1) downto 0);
            data : in std_logic_vector((DATA_WIDTH-1) downto 0);
            we   : in std_logic := '1';
            q    : out std_logic_vector((DATA_WIDTH-1) downto 0)
        );
    end component;

    -- Control Unit
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

    -- Register File
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

    -- ALU
    component alu is
        port(
            i_A       : in  std_logic_vector(31 downto 0);
            i_B       : in  std_logic_vector(31 downto 0);
            i_ALUCtrl : in  std_logic_vector(3 downto 0);
            o_Result  : out std_logic_vector(31 downto 0);
            o_Zero    : out std_logic;
            o_Sign    : out std_logic;
            o_Cout    : out std_logic
        );
    end component;

    -- ALU Control
    component alu_control is
        port(
            i_ALUOp   : in  std_logic_vector(1 downto 0);
            i_Funct3  : in  std_logic_vector(2 downto 0);
            i_Funct7  : in  std_logic_vector(6 downto 0);
            o_ALUCtrl : out std_logic_vector(3 downto 0)
        );
    end component;

    -- Fetch Logic (Next PC 계산기)
    component fetch_logic is
        generic(N : integer := 32);
        port(
            i_PC      : in std_logic_vector(N-1 downto 0);
            i_Imm     : in std_logic_vector(N-1 downto 0);
            i_RS1     : in std_logic_vector(N-1 downto 0);
            i_Branch  : in std_logic;
            i_Jump    : in std_logic_vector(1 downto 0);
            i_Funct3  : in std_logic_vector(2 downto 0);
            i_ALUZero : in std_logic;
            i_ALUSign : in std_logic;
            i_ALUCout : in std_logic;
            o_NextPC  : out std_logic_vector(N-1 downto 0)
        );
    end component;

    -- Immediate Generator
    component imm_gen is
        port(
            i_Inst    : in  std_logic_vector(31 downto 0);
            i_ImmType : in  std_logic_vector(2 downto 0);
            o_Imm     : out std_logic_vector(31 downto 0)
        );
    end component;

    -- PC Register
    component pc_reg is
        port(
            i_CLK    : in  std_logic;
            i_RST    : in  std_logic;
            i_WE     : in  std_logic;
            i_NextPC : in  std_logic_vector(31 downto 0);
            o_PC     : out std_logic_vector(31 downto 0)
        );
    end component;

    -- Load Extender
    component load_extender is
        port(
            i_DMemOut : in  std_logic_vector(31 downto 0);
            i_Funct3  : in  std_logic_vector(2 downto 0);
            i_AddrLSB : in  std_logic_vector(1 downto 0);
            o_ReadData: out std_logic_vector(31 downto 0)
        );
    end component;

    -- IF/ID Pipeline Register
    component IF_ID_Reg is
        port(
            i_CLK   : in  std_logic;
            i_RST   : in  std_logic;
            i_Flush : in  std_logic;
            i_PC    : in  std_logic_vector(31 downto 0);
            i_Inst  : in  std_logic_vector(31 downto 0);
            o_PC    : out std_logic_vector(31 downto 0);
            o_Inst  : out std_logic_vector(31 downto 0)
        );
    end component;

    -- ID/EX Pipeline Register
    component ID_EX_Reg is
        port(
            i_CLK       : in std_logic;
            i_RST       : in std_logic;
            i_Flush     : in std_logic;

            i_RegWrite  : in std_logic;
            i_MemtoReg  : in std_logic_vector(1 downto 0);
            i_Halt      : in std_logic;

            i_MemWrite  : in std_logic;
            i_MemRead   : in std_logic;

            i_ALUSrcA   : in std_logic;
            i_ALUSrcB   : in std_logic;
            i_ALUOp     : in std_logic_vector(1 downto 0);
            i_Branch    : in std_logic;
            i_Jump      : in std_logic_vector(1 downto 0);

            i_PC        : in std_logic_vector(31 downto 0);
            i_ReadData1 : in std_logic_vector(31 downto 0);
            i_ReadData2 : in std_logic_vector(31 downto 0);
            i_Imm       : in std_logic_vector(31 downto 0);

            i_Funct3    : in std_logic_vector(2 downto 0);
            i_Funct7    : in std_logic_vector(6 downto 0);
            i_Rd        : in std_logic_vector(4 downto 0);
            i_Rs1       : in std_logic_vector(4 downto 0);
            i_Rs2       : in std_logic_vector(4 downto 0);

            o_RegWrite  : out std_logic;
            o_MemtoReg  : out std_logic_vector(1 downto 0);
            o_Halt      : out std_logic;

            o_MemWrite  : out std_logic;
            o_MemRead   : out std_logic;

            o_ALUSrcA   : out std_logic;
            o_ALUSrcB   : out std_logic;
            o_ALUOp     : out std_logic_vector(1 downto 0);
            o_Branch    : out std_logic;
            o_Jump      : out std_logic_vector(1 downto 0);

            o_PC        : out std_logic_vector(31 downto 0);
            o_ReadData1 : out std_logic_vector(31 downto 0);
            o_ReadData2 : out std_logic_vector(31 downto 0);
            o_Imm       : out std_logic_vector(31 downto 0);

            o_Funct3    : out std_logic_vector(2 downto 0);
            o_Funct7    : out std_logic_vector(6 downto 0);
            o_Rd        : out std_logic_vector(4 downto 0);
            o_Rs1       : out std_logic_vector(4 downto 0);
            o_Rs2       : out std_logic_vector(4 downto 0)
        );
    end component;

    -- EX/MEM Pipeline Register
    component EX_MEM_Reg is
        port(
            i_CLK      : in std_logic;
            i_RST      : in std_logic;

            i_RegWrite : in std_logic;
            i_MemtoReg : in std_logic_vector(1 downto 0);
            i_Halt     : in std_logic;
            i_MemWrite : in std_logic;
            i_MemRead  : in std_logic;

            i_PCPlus4  : in std_logic_vector(31 downto 0);
            i_ALUResult: in std_logic_vector(31 downto 0);
            i_WriteData: in std_logic_vector(31 downto 0);
            i_Imm      : in std_logic_vector(31 downto 0);
            i_Rd       : in std_logic_vector(4 downto 0);
            i_Funct3   : in std_logic_vector(2 downto 0);

            o_RegWrite : out std_logic;
            o_MemtoReg : out std_logic_vector(1 downto 0);
            o_Halt     : out std_logic;
            o_MemWrite : out std_logic;
            o_MemRead  : out std_logic;

            o_PCPlus4  : out std_logic_vector(31 downto 0);
            o_ALUResult: out std_logic_vector(31 downto 0);
            o_WriteData: out std_logic_vector(31 downto 0);
            o_Imm      : out std_logic_vector(31 downto 0);
            o_Rd       : out std_logic_vector(4 downto 0);
            o_Funct3   : out std_logic_vector(2 downto 0)
        );
    end component;

    -- MEM/WB Pipeline Register
    component MEM_WB_Reg is
        port(
            i_CLK      : in std_logic;
            i_RST      : in std_logic;

            i_RegWrite : in std_logic;
            i_MemtoReg : in std_logic_vector(1 downto 0);
            i_Halt     : in std_logic;

            i_ReadData : in std_logic_vector(31 downto 0);
            i_ALUResult: in std_logic_vector(31 downto 0);
            i_PCPlus4  : in std_logic_vector(31 downto 0);
            i_Imm      : in std_logic_vector(31 downto 0);
            i_Rd       : in std_logic_vector(4 downto 0);

            o_RegWrite : out std_logic;
            o_MemtoReg : out std_logic_vector(1 downto 0);
            o_Halt     : out std_logic;

            o_ReadData : out std_logic_vector(31 downto 0);
            o_ALUResult: out std_logic_vector(31 downto 0);
            o_PCPlus4  : out std_logic_vector(31 downto 0);
            o_Imm      : out std_logic_vector(31 downto 0);
            o_Rd       : out std_logic_vector(4 downto 0)
        );
    end component;

begin

    ---------------------------------------------------------------------
    -- [IF Stage] Instruction Memory + PC
    ---------------------------------------------------------------------

    -- Inst memory address 선택: normal 실행 vs 로딩
    with iInstLd select
        s_IMemAddr <= s_CurrentPC when '0',
                      iInstAddr   when others;

    IMem : mem
        generic map(
            ADDR_WIDTH => ADDR_WIDTH,
            DATA_WIDTH => N
        )
        port map(
            clk  => iCLK,
            addr => s_IMemAddr(ADDR_WIDTH+1 downto 2),
            data => iInstExt,
            we   => iInstLd,
            q    => s_Inst
        );

    -- PC Register
    U_PC : pc_reg
        port map(
            i_CLK    => iCLK,
            i_RST    => iRST,
            i_WE     => '1',
            i_NextPC => s_NextInstAddr,
            o_PC     => s_CurrentPC
        );

    -- IF/ID 파이프라인 레지스터
    U_IFID : IF_ID_Reg
        port map(
            i_CLK   => iCLK,
            i_RST   => iRST,
            i_Flush => s_IF_Flush,  -- Part 1에서는 항상 '0'으로 둬도 됨
            i_PC    => s_CurrentPC,
            i_Inst  => s_Inst,
            o_PC    => s_IFID_PC,
            o_Inst  => s_IFID_Inst
        );

    ---------------------------------------------------------------------
    -- [ID Stage] Control, Register File, ImmGen
    ---------------------------------------------------------------------

    -- Funct3/Funct7는 ID 단계에서 추출
    s_Funct3 <= s_IFID_Inst(14 downto 12);
    s_Funct7 <= s_IFID_Inst(31 downto 25);

    -- Control Unit (ID stage)
    U_CONTROL : control_unit
        port map(
            i_Opcode   => s_IFID_Inst(6 downto 0),
            o_ALUSrc   => s_ID_ALUSrcB,
            o_MemtoReg => s_ID_MemtoReg,
            o_RegWrite => s_ID_RegWrite,
            o_MemRead  => s_ID_MemRead,
            o_MemWrite => s_ID_MemWrite,
            o_Branch   => s_ID_Branch,
            o_Jump     => s_ID_Jump,
            o_ALUOp    => s_ID_ALUOp,
            o_ImmType  => s_ID_ImmType,
            o_AUIPCSrc => s_ID_ALUSrcA
        );

    -- HALT (wfi, opcode "0000000") 디코드 – ID 단계에서 잡아서 파이프라인으로 보냄
    process(s_IFID_Inst, iRST)
    begin
        if (iRST = '1') then
            s_ID_Halt <= '0';
        elsif (s_IFID_Inst(6 downto 0) = "0000000") then
            s_ID_Halt <= '1';
        else
            s_ID_Halt <= '0';
        end if;
    end process;

    -- Register File
    U_REGFILE : reg_file
        port map(
            i_CLK    => iCLK,
            i_RST    => iRST,
            i_WE     => s_WB_RegWrite,  -- WB 단계에서 쓰기
            i_WADDR  => s_WB_Rd,
            i_WDATA  => s_WB_WriteData,
            i_RADDR1 => s_IFID_Inst(19 downto 15),
            i_RADDR2 => s_IFID_Inst(24 downto 20),
            o_RDATA1 => s_ReadData1,
            o_RDATA2 => s_ReadData2
        );

    -- Immediate Generator
    U_IMM_GEN : imm_gen
        port map(
            i_Inst    => s_IFID_Inst,
            i_ImmType => s_ID_ImmType,
            o_Imm     => s_Imm
        );

    -- ID/EX Pipeline Register
    U_IDEX : ID_EX_Reg
        port map(
            i_CLK       => iCLK,
            i_RST       => iRST,
            i_Flush     => s_ID_Flush,  -- Part 1에서는 항상 '0' 가능

            i_RegWrite  => s_ID_RegWrite,
            i_MemtoReg  => s_ID_MemtoReg,
            i_Halt      => s_ID_Halt,

            i_MemWrite  => s_ID_MemWrite,
            i_MemRead   => s_ID_MemRead,

            i_ALUSrcA   => s_ID_ALUSrcA,
            i_ALUSrcB   => s_ID_ALUSrcB,
            i_ALUOp     => s_ID_ALUOp,
            i_Branch    => s_ID_Branch,
            i_Jump      => s_ID_Jump,

            i_PC        => s_IFID_PC,
            i_ReadData1 => s_ReadData1,
            i_ReadData2 => s_ReadData2,
            i_Imm       => s_Imm,

            i_Funct3    => s_Funct3,
            i_Funct7    => s_Funct7,
            i_Rd        => s_IFID_Inst(11 downto 7),
            i_Rs1       => s_IFID_Inst(19 downto 15),
            i_Rs2       => s_IFID_Inst(24 downto 20),

            o_RegWrite  => s_EX_RegWrite,
            o_MemtoReg  => s_EX_MemtoReg,
            o_Halt      => s_EX_Halt,

            o_MemWrite  => s_EX_MemWrite,
            o_MemRead   => s_EX_MemRead,

            o_ALUSrcA   => s_EX_ALUSrcA,
            o_ALUSrcB   => s_EX_ALUSrcB,
            o_ALUOp     => s_EX_ALUOp,
            o_Branch    => s_EX_Branch,
            o_Jump      => s_EX_Jump,

            o_PC        => s_EX_PC,
            o_ReadData1 => s_EX_ReadData1,
            o_ReadData2 => s_EX_ReadData2,
            o_Imm       => s_EX_Imm,

            o_Funct3    => s_EX_Funct3,
            o_Funct7    => s_EX_Funct7,
            o_Rd        => s_EX_Rd,
            o_Rs1       => s_EX_Rs1,
            o_Rs2       => s_EX_Rs2
        );

    ---------------------------------------------------------------------
    -- [EX Stage] ALU, ALU Control, Branch를 위한 정보 생성
    ---------------------------------------------------------------------

    -- ALU 입력 선택
    s_ALUInputA <= s_EX_PC when s_EX_ALUSrcA = '1' else s_EX_ReadData1;
    s_ALUInputB <= s_EX_Imm when s_EX_ALUSrcB = '1' else s_EX_ReadData2;

    U_ALUCTRL : alu_control
        port map(
            i_ALUOp   => s_EX_ALUOp,
            i_Funct3  => s_EX_Funct3,
            i_Funct7  => s_EX_Funct7,
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

    -- Next PC 계산: EX 단계 정보 사용 (소프트웨어가 NOP로 hazard 처리)
    U_FETCH : fetch_logic
        generic map(N => 32)
        port map(
            i_PC      => s_EX_PC,
            i_Imm     => s_EX_Imm,
            i_RS1     => s_EX_ReadData1,
            i_Branch  => s_EX_Branch,
            i_Jump    => s_EX_Jump,
            i_Funct3  => s_EX_Funct3,
            i_ALUZero => s_Zero,
            i_ALUSign => s_Sign,
            i_ALUCout => s_Cout,
            o_NextPC  => s_NextInstAddr
        );

    -- EX/MEM Pipeline Register
    U_EXMEM : EX_MEM_Reg
        port map(
            i_CLK      => iCLK,
            i_RST      => iRST,

            i_RegWrite => s_EX_RegWrite,
            i_MemtoReg => s_EX_MemtoReg,
            i_Halt     => s_EX_Halt,
            i_MemWrite => s_EX_MemWrite,
            i_MemRead  => s_EX_MemRead,

            i_PCPlus4  => std_logic_vector(unsigned(s_EX_PC) + 4),
            i_ALUResult=> s_ALUResult,
            i_WriteData=> s_EX_ReadData2,
            i_Imm      => s_EX_Imm,
            i_Rd       => s_EX_Rd,
            i_Funct3   => s_EX_Funct3,

            o_RegWrite => s_MEM_RegWrite,
            o_MemtoReg => s_MEM_MemtoReg,
            o_Halt     => s_MEM_Halt,
            o_MemWrite => s_MEM_MemWrite,
            o_MemRead  => s_MEM_MemRead,

            o_PCPlus4  => s_MEM_PCPlus4,
            o_ALUResult=> s_MEM_ALUResult,
            o_WriteData=> s_MEM_WriteData,
            o_Imm      => s_MEM_Imm,
            o_Rd       => s_MEM_Rd,
            o_Funct3   => s_MEM_Funct3
        );

    ---------------------------------------------------------------------
    -- [MEM Stage] Data Memory + Load Extender
    ---------------------------------------------------------------------

    -- Skeleton용 DMem 인터페이스에 파이프라인 신호 매핑
    s_DMemAddr <= s_MEM_ALUResult;
    s_DMemData <= s_MEM_WriteData;
    s_DMemWr   <= s_MEM_MemWrite;

    DMem : mem
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

    -- Load Extender (lb/lh/lbu/lhu/lw)
    s_ByteOffset <= s_MEM_ALUResult(1 downto 0);

    U_LOADEXT : load_extender
        port map(
            i_DMemOut  => s_DMemOut,
            i_Funct3   => s_MEM_Funct3,
            i_AddrLSB  => s_ByteOffset,
            o_ReadData => s_LoadData
        );

    -- MEM/WB Pipeline Register
    U_MEMWB : MEM_WB_Reg
        port map(
            i_CLK      => iCLK,
            i_RST      => iRST,

            i_RegWrite => s_MEM_RegWrite,
            i_MemtoReg => s_MEM_MemtoReg,
            i_Halt     => s_MEM_Halt,

            i_ReadData => s_LoadData,
            i_ALUResult=> s_MEM_ALUResult,
            i_PCPlus4  => s_MEM_PCPlus4,
            i_Imm      => s_MEM_Imm,
            i_Rd       => s_MEM_Rd,

            o_RegWrite => s_WB_RegWrite,
            o_MemtoReg => s_WB_MemtoReg,
            o_Halt     => s_WB_Halt,

            o_ReadData => s_WB_ReadData,
            o_ALUResult=> s_WB_ALUResult,
            o_PCPlus4  => s_WB_PCPlus4,
            o_Imm      => s_WB_Imm,
            o_Rd       => s_WB_Rd
        );

    ---------------------------------------------------------------------
    -- [WB Stage] Writeback MUX + Skeleton 신호 매핑
    ---------------------------------------------------------------------

    -- Writeback MUX: 무엇을 레지스터 파일에 쓸 것인가?
    with s_WB_MemtoReg select
        s_WB_WriteData <= s_WB_ALUResult                      when "00", -- ALU 결과
                          s_WB_ReadData                       when "01", -- 메모리 로드
                          s_WB_PCPlus4                        when "10", -- PC+4 (JAL/JALR)
                          s_WB_Imm                            when "11", -- LUI 등
                          (others => '0')                     when others;

    -- Skeleton에서 요구하는 레지스터 파일 제어 신호에 WB 신호를 매핑
    s_RegWr     <= s_WB_RegWrite;
    s_RegWrAddr <= s_WB_Rd;
    s_RegWrData <= s_WB_WriteData;

    -- 최종 Halt: HALT 인스트럭션이 WB 단계에 도달했을 때만 '1'
    s_Halt <= s_WB_Halt;

    -- Overflow는 현재 ALU에서 구현 안 했으므로 0으로 고정
    s_Ovfl <= '0';

    -- Testbench용 ALU 출력 (Skeleton에서 DMemAddr를 기대하던 것 그대로 유지)
    oALUOut <= s_DMemAddr;

end structure;