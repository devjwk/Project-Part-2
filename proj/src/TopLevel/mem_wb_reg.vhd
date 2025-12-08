------------------------------------------------------------------------
-- MEM/WB Pipeline Register
-- MEM 단계에서 생성된 값들을 WB 단계로 전달하는 레지스터
--
-- single-cycle processor의 논리 흐름을 그대로 반영:
--   • Load 결과(load_extender) 또는 ALU 결과를 WB에서 선택해야 함
--   • JAL/JALR의 PC+4도 WB에서 register file에 기록될 수 있음
--   • AUIPC 등 일부 명령은 Immediate를 WB까지 carry해야 함
--
-- Part 1 (software-scheduled pipeline):
--   • Hazard / Stall / Flush 없음 → 매 사이클마다 저장
------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity mem_wb_reg is
    generic(N : integer := 32);
    port(
        i_CLK       : in  std_logic;
        i_RST       : in  std_logic;

        --------------------------------------------------------------------
        -- Datapath Inputs from MEM Stage
        --------------------------------------------------------------------
        i_ALUResult : in  std_logic_vector(N-1 downto 0);  -- ALU 결과
        i_MemData   : in  std_logic_vector(N-1 downto 0);  -- 메모리에서 읽어온 load 데이터
        i_PC4       : in  std_logic_vector(N-1 downto 0);  -- PC + 4 (JAL/JALR)
        i_Imm       : in  std_logic_vector(N-1 downto 0);  -- Immediate (AUIPC 등 WB 필요 시)
        i_Rd        : in  std_logic_vector(4 downto 0);    -- 목적 레지스터 번호

        --------------------------------------------------------------------
        -- Control Inputs from MEM Stage
        --------------------------------------------------------------------
        i_RegWrite  : in  std_logic;                       -- Register file write enable
        i_MemToReg  : in  std_logic_vector(1 downto 0);    -- WB 단계 선택 코드
        i_Halt      : in  std_logic;                       -- Halt carry (WB에서 assert)

        --------------------------------------------------------------------
        -- Outputs to WB Stage
        --------------------------------------------------------------------
        o_ALUResult : out std_logic_vector(N-1 downto 0);
        o_MemData   : out std_logic_vector(N-1 downto 0);
        o_PC4       : out std_logic_vector(N-1 downto 0);
        o_Imm       : out std_logic_vector(N-1 downto 0);
        o_Rd        : out std_logic_vector(4 downto 0);

        o_RegWrite  : out std_logic;
        o_MemToReg  : out std_logic_vector(1 downto 0);
        o_Halt      : out std_logic
    );
end mem_wb_reg;

architecture behavior of mem_wb_reg is

    ------------------------------------------------------------------------
    -- 내부 레지스터: MEM 단계의 결과를 WB 단계까지 carry하는 저장소
    ------------------------------------------------------------------------
    signal s_ALUResult_reg : std_logic_vector(N-1 downto 0) := (others => '0');
    signal s_MemData_reg   : std_logic_vector(N-1 downto 0) := (others => '0');
    signal s_PC4_reg       : std_logic_vector(N-1 downto 0) := (others => '0');
    signal s_Imm_reg       : std_logic_vector(N-1 downto 0) := (others => '0');
    signal s_Rd_reg        : std_logic_vector(4 downto 0)   := (others => '0');

    signal s_RegWrite_reg  : std_logic := '0';
    signal s_MemToReg_reg  : std_logic_vector(1 downto 0) := (others => '0');
    signal s_Halt_reg      : std_logic := '0';

begin

    process(i_CLK, i_RST)
    begin
        -- 🔹 Reset 처리 → pipeline bubble 생성
        if (i_RST = '1') then
            s_ALUResult_reg <= (others => '0');
            s_MemData_reg   <= (others => '0');
            s_PC4_reg       <= (others => '0');
            s_Imm_reg       <= (others => '0');
            s_Rd_reg        <= (others => '0');

            s_RegWrite_reg  <= '0';
            s_MemToReg_reg  <= (others => '0');
            s_Halt_reg      <= '0';

        -- 🔹 Part 1: stall/flush 없음 → 모든 값 매 클럭 갱신
        elsif rising_edge(i_CLK) then
            s_ALUResult_reg <= i_ALUResult;
            s_MemData_reg   <= i_MemData;
            s_PC4_reg       <= i_PC4;
            s_Imm_reg       <= i_Imm;
            s_Rd_reg        <= i_Rd;

            s_RegWrite_reg  <= i_RegWrite;
            s_MemToReg_reg  <= i_MemToReg;
            s_Halt_reg      <= i_Halt;
        end if;
    end process;

    ------------------------------------------------------------------------
    -- WB 단계로 출력
    ------------------------------------------------------------------------
    o_ALUResult <= s_ALUResult_reg;
    o_MemData   <= s_MemData_reg;
    o_PC4       <= s_PC4_reg;
    o_Imm       <= s_Imm_reg;
    o_Rd        <= s_Rd_reg;

    o_RegWrite  <= s_RegWrite_reg;
    o_MemToReg  <= s_MemToReg_reg;
    o_Halt      <= s_Halt_reg;

end behavior;