------------------------------------------------------------------------
-- IF/ID Pipeline Register
-- IF 단계에서 나온 PC와 Instruction을 ID 단계로 전달하는 레지스터
-- 👉 Part 1에서는 Hazard / Stall / Flush 없음
-- 👉 따라서 클럭 상승엣지마다 단순히 값만 저장하면 됨
------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity if_id_reg is
    generic(N : integer := 32);
    port(
        i_CLK     : in  std_logic;
        i_RST     : in  std_logic;

        -- IF 단계에서 들어오는 값들
        -- i_PC   : 현재 instruction의 PC 값
        -- i_Inst : Instruction Memory에서 읽은 명령어
        i_PC      : in  std_logic_vector(N-1 downto 0);
        i_Inst    : in  std_logic_vector(N-1 downto 0);

        -- ID 단계로 전달할 값들
        o_PC      : out std_logic_vector(N-1 downto 0);
        o_Inst    : out std_logic_vector(N-1 downto 0)
    );
end if_id_reg;

architecture behavior of if_id_reg is

    -- 내부 레지스터 (PC와 Inst를 저장함)
    -- Reset 시 0으로 초기화 → pipeline bubble (NOP 효과)
    signal s_PC_reg   : std_logic_vector(N-1 downto 0) := (others => '0');
    signal s_Inst_reg : std_logic_vector(N-1 downto 0) := (others => '0');

begin

    process(i_CLK, i_RST)
    begin
        -- 🔹 Reset 처리
        -- Reset = 1이면 pipeline을 깨끗하게 지워야 하므로
        -- PC=0, Inst=0으로 초기화 (Inst=0은 실질적으로 NOP)
        if (i_RST = '1') then
            s_PC_reg   <= (others => '0');
            s_Inst_reg <= (others => '0');

        -- 🔹 클럭 상승엣지에서 새로운 IF-stage 결과를 저장
        -- Part 1에서는 Stall/Flush가 없으므로 매 사이클 값이 갱신됨
        elsif rising_edge(i_CLK) then
            s_PC_reg   <= i_PC;     -- PC를 ID 단계로 전달하기 위해 저장
            s_Inst_reg <= i_Inst;   -- Instruction을 ID 단계로 전달하기 위해 저장
        end if;
    end process;

    -- 🔹 저장된 값을 ID 단계로 출력
    o_PC   <= s_PC_reg;
    o_Inst <= s_Inst_reg;

end behavior;