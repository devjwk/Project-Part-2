------------------------------------------------------------------------
-- ID/EX Pipeline Register
-- ID 단계에서 생성된 모든 데이터/컨트롤 신호들을 EX 단계로 전달
--
-- single-cycle processor의 논리 흐름을 그대로 반영:
--   • ID 단계 = instruction decode + register read + immediate gen + control gen
--   • EX 단계에서 필요한 모든 값들을 pipeline register에 저장해 전달해야 함
--
-- Part 1 (software-scheduled pipeline):
--   • Stall / Flush 없음 → 매 사이클마다 그대로 레지스터에 저장
------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity id_ex_reg is
    generic(N : integer := 32);
    port(
        i_CLK       : in  std_logic;
        i_RST       : in  std_logic;

        --------------------------------------------------------------------
        -- Datapath Inputs from ID Stage
        --------------------------------------------------------------------
        i_PC        : in  std_logic_vector(N-1 downto 0);    -- ID 단계에서 전달해야 할 PC
        i_ReadData1 : in  std_logic_vector(N-1 downto 0);    -- Register rs1 값
        i_ReadData2 : in  std_logic_vector(N-1 downto 0);    -- Register rs2 값
        i_Imm       : in  std_logic_vector(N-1 downto 0);    -- Immediate generator output
        i_Rs1       : in  std_logic_vector(4 downto 0);      -- rs1 index (forwarding 대비)
        i_Rs2       : in  std_logic_vector(4 downto 0);      -- rs2 index (forwarding 대비)
        i_Rd        : in  std_logic_vector(4 downto 0);      -- 목적 레지스터 번호

        --------------------------------------------------------------------
        -- Control Inputs from ID Stage
        --------------------------------------------------------------------
        i_ALUSrcA   : in  std_logic;
        i_ALUSrcB   : in  std_logic;
        i_ALUOp     : in  std_logic_vector(2 downto 0);      -- 너희 single-cycle 기준
        i_Branch    : in  std_logic;
        i_Jump      : in  std_logic_vector(1 downto 0);
        i_MemRead   : in  std_logic;
        i_MemWrite  : in  std_logic;
        i_MemToReg  : in  std_logic_vector(1 downto 0);
        i_RegWrite  : in  std_logic;
        i_Halt      : in  std_logic;

        --------------------------------------------------------------------
        -- Outputs to EX Stage
        --------------------------------------------------------------------
        o_PC        : out std_logic_vector(N-1 downto 0);
        o_ReadData1 : out std_logic_vector(N-1 downto 0);
        o_ReadData2 : out std_logic_vector(N-1 downto 0);
        o_Imm       : out std_logic_vector(N-1 downto 0);
        o_Rs1       : out std_logic_vector(4 downto 0);
        o_Rs2       : out std_logic_vector(4 downto 0);
        o_Rd        : out std_logic_vector(4 downto 0);

        o_ALUSrcA   : out std_logic;
        o_ALUSrcB   : out std_logic;
        o_ALUOp     : out std_logic_vector(2 downto 0);
        o_Branch    : out std_logic;
        o_Jump      : out std_logic_vector(1 downto 0);
        o_MemRead   : out std_logic;
        o_MemWrite  : out std_logic;
        o_MemToReg  : out std_logic_vector(1 downto 0);
        o_RegWrite  : out std_logic;
        o_Halt      : out std_logic
    );
end id_ex_reg;

architecture behavior of id_ex_reg is

    -- 내부 레지스터 (ID 단계 → EX 단계 전달용)
    signal s_PC_reg        : std_logic_vector(N-1 downto 0) := (others => '0');
    signal s_ReadData1_reg : std_logic_vector(N-1 downto 0) := (others => '0');
    signal s_ReadData2_reg : std_logic_vector(N-1 downto 0) := (others => '0');
    signal s_Imm_reg       : std_logic_vector(N-1 downto 0) := (others => '0');
    signal s_Rs1_reg       : std_logic_vector(4 downto 0) := (others => '0');
    signal s_Rs2_reg       : std_logic_vector(4 downto 0) := (others => '0');
    signal s_Rd_reg        : std_logic_vector(4 downto 0) := (others => '0');

    signal s_ALUSrcA_reg   : std_logic := '0';
    signal s_ALUSrcB_reg   : std_logic := '0';
    signal s_ALUOp_reg     : std_logic_vector(2 downto 0) := (others => '0');
    signal s_Branch_reg    : std_logic := '0';
    signal s_Jump_reg      : std_logic_vector(1 downto 0) := (others => '0');
    signal s_MemRead_reg   : std_logic := '0';
    signal s_MemWrite_reg  : std_logic := '0';
    signal s_MemToReg_reg  : std_logic_vector(1 downto 0) := (others => '0');
    signal s_RegWrite_reg  : std_logic := '0';
    signal s_Halt_reg      : std_logic := '0';

begin

    process(i_CLK, i_RST)
    begin
        -- 🔹 Reset 처리: 모든 레지스터 값을 0으로 초기화
        -- ID 단계가 비면 EX 단계도 bubble이 되어야 함
        if (i_RST = '1') then
            s_PC_reg        <= (others => '0');
            s_ReadData1_reg <= (others => '0');
            s_ReadData2_reg <= (others => '0');
            s_Imm_reg       <= (others => '0');
            s_Rs1_reg       <= (others => '0');
            s_Rs2_reg       <= (others => '0');
            s_Rd_reg        <= (others => '0');

            s_ALUSrcA_reg   <= '0';
            s_ALUSrcB_reg   <= '0';
            s_ALUOp_reg     <= (others => '0');
            s_Branch_reg    <= '0';
            s_Jump_reg      <= (others => '0');
            s_MemRead_reg   <= '0';
            s_MemWrite_reg  <= '0';
            s_MemToReg_reg  <= (others => '0');
            s_RegWrite_reg  <= '0';
            s_Halt_reg      <= '0';

        -- 🔹 Part 1에서는 hazard / stall / flush 없음
        --     → rising edge마다 ID 단계 신호를 그대로 저장
        elsif rising_edge(i_CLK) then
            s_PC_reg        <= i_PC;
            s_ReadData1_reg <= i_ReadData1;
            s_ReadData2_reg <= i_ReadData2;
            s_Imm_reg       <= i_Imm;
            s_Rs1_reg       <= i_Rs1;
            s_Rs2_reg       <= i_Rs2;
            s_Rd_reg        <= i_Rd;

            s_ALUSrcA_reg   <= i_ALUSrcA;
            s_ALUSrcB_reg   <= i_ALUSrcB;
            s_ALUOp_reg     <= i_ALUOp;
            s_Branch_reg    <= i_Branch;
            s_Jump_reg      <= i_Jump;
            s_MemRead_reg   <= i_MemRead;
            s_MemWrite_reg  <= i_MemWrite;
            s_MemToReg_reg  <= i_MemToReg;
            s_RegWrite_reg  <= i_RegWrite;
            s_Halt_reg      <= i_Halt;
        end if;
    end process;

    -- EX 단계로 출력
    o_PC        <= s_PC_reg;
    o_ReadData1 <= s_ReadData1_reg;
    o_ReadData2 <= s_ReadData2_reg;
    o_Imm       <= s_Imm_reg;
    o_Rs1       <= s_Rs1_reg;
    o_Rs2       <= s_Rs2_reg;
    o_Rd        <= s_Rd_reg;

    o_ALUSrcA   <= s_ALUSrcA_reg;
    o_ALUSrcB   <= s_ALUSrcB_reg;
    o_ALUOp     <= s_ALUOp_reg;
    o_Branch    <= s_Branch_reg;
    o_Jump      <= s_Jump_reg;
    o_MemRead   <= s_MemRead_reg;
    o_MemWrite  <= s_MemWrite_reg;
    o_MemToReg  <= s_MemToReg_reg;
    o_RegWrite  <= s_RegWrite_reg;
    o_Halt      <= s_Halt_reg;

end behavior;