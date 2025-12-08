------------------------------------------------------------------------
-- EX/MEM Pipeline Register
-- EX 단계에서 생성된 Datapath/Control 신호들을 MEM 단계로 전달
--
-- single-cycle processor의 논리 흐름을 그대로 반영:
--   • EX 단계에서 ALU 연산 수행
--   • Store instruction의 write data 준비
--   • Destination register 번호 유지
--   • Control signal들은 MEM/WB까지 carry되어야 함
--
-- Part 1 (software-scheduled pipeline):
--   • Hazard / Stall / Flush 없음 → 매 사이클마다 값이 갱신됨
------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity ex_mem_reg is
    generic(N : integer := 32);
    port(
        i_CLK        : in  std_logic;
        i_RST        : in  std_logic;

        --------------------------------------------------------------------
        -- Datapath Inputs from EX Stage
        --------------------------------------------------------------------
        i_ALUResult  : in  std_logic_vector(N-1 downto 0); -- ALU 계산 결과
        i_WriteData  : in  std_logic_vector(N-1 downto 0); -- Store 시 메모리에 쓸 값
        i_PC         : in  std_logic_vector(N-1 downto 0); -- PC+4 또는 Branch/Jump 계산용
        i_Rd         : in  std_logic_vector(4 downto 0);   -- 목적 레지스터 번호

        --------------------------------------------------------------------
        -- Control Inputs from EX Stage
        --------------------------------------------------------------------
        i_RegWrite   : in  std_logic;                     -- Register write enable
        i_MemRead    : in  std_logic;                     -- Load flag
        i_MemWrite   : in  std_logic;                     -- Store flag
        i_MemToReg   : in  std_logic_vector(1 downto 0);  -- WB stage 선택
        i_Halt       : in  std_logic;                     -- Halt carry

        --------------------------------------------------------------------
        -- Outputs to MEM Stage
        --------------------------------------------------------------------
        o_ALUResult  : out std_logic_vector(N-1 downto 0);
        o_WriteData  : out std_logic_vector(N-1 downto 0);
        o_PC         : out std_logic_vector(N-1 downto 0);
        o_Rd         : out std_logic_vector(4 downto 0);

        o_RegWrite   : out std_logic;
        o_MemRead    : out std_logic;
        o_MemWrite   : out std_logic;
        o_MemToReg   : out std_logic_vector(1 downto 0);
        o_Halt       : out std_logic
    );
end ex_mem_reg;

architecture behavior of ex_mem_reg is

    -- 내부 레지스터들
    signal s_ALUResult_reg : std_logic_vector(N-1 downto 0) := (others => '0');
    signal s_WriteData_reg : std_logic_vector(N-1 downto 0) := (others => '0');
    signal s_PC_reg        : std_logic_vector(N-1 downto 0) := (others => '0');
    signal s_Rd_reg        : std_logic_vector(4 downto 0)   := (others => '0');

    signal s_RegWrite_reg  : std_logic := '0';
    signal s_MemRead_reg   : std_logic := '0';
    signal s_MemWrite_reg  : std_logic := '0';
    signal s_MemToReg_reg  : std_logic_vector(1 downto 0) := (others => '0');
    signal s_Halt_reg      : std_logic := '0';

begin

    process(i_CLK, i_RST)
    begin
        -- 🔹 Reset 처리
        if (i_RST = '1') then
            s_ALUResult_reg <= (others => '0');
            s_WriteData_reg <= (others => '0');
            s_PC_reg        <= (others => '0');
            s_Rd_reg        <= (others => '0');

            s_RegWrite_reg  <= '0';
            s_MemRead_reg   <= '0';
            s_MemWrite_reg  <= '0';
            s_MemToReg_reg  <= (others => '0');
            s_Halt_reg      <= '0';

        -- 🔹 Part 1: stall/flush 없음 → rising edge마다 값 업데이트
        elsif rising_edge(i_CLK) then
            s_ALUResult_reg <= i_ALUResult;
            s_WriteData_reg <= i_WriteData;
            s_PC_reg        <= i_PC;
            s_Rd_reg        <= i_Rd;

            s_RegWrite_reg  <= i_RegWrite;
            s_MemRead_reg   <= i_MemRead;
            s_MemWrite_reg  <= i_MemWrite;
            s_MemToReg_reg  <= i_MemToReg;
            s_Halt_reg      <= i_Halt;
        end if;
    end process;

    -- MEM 단계로 출력
    o_ALUResult <= s_ALUResult_reg;
    o_WriteData <= s_WriteData_reg;
    o_PC        <= s_PC_reg;
    o_Rd        <= s_Rd_reg;

    o_RegWrite  <= s_RegWrite_reg;
    o_MemRead   <= s_MemRead_reg;
    o_MemWrite  <= s_MemWrite_reg;
    o_MemToReg  <= s_MemToReg_reg;
    o_Halt      <= s_Halt_reg;

end behavior;