-------------------------------------------------------------------------
-- MEM/WB Pipeline Register
-- Holds memory read data, ALU result, PC+4, Imm, and control signals
-- for the final Writeback stage.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

entity MEM_WB_Reg is
    port(
        i_CLK      : in std_logic;
        i_RST      : in std_logic;

        -- Control
        i_RegWrite : in std_logic;
        i_MemtoReg : in std_logic_vector(1 downto 0);
        i_Halt     : in std_logic;

        -- Data
        i_ReadData : in std_logic_vector(31 downto 0); -- From DMem
        i_ALUResult: in std_logic_vector(31 downto 0);
        i_PCPlus4  : in std_logic_vector(31 downto 0);
        i_Imm      : in std_logic_vector(31 downto 0);
        i_Rd       : in std_logic_vector(4 downto 0);

        -- Outputs
        o_RegWrite : out std_logic;
        o_MemtoReg : out std_logic_vector(1 downto 0);
        o_Halt     : out std_logic;

        o_ReadData : out std_logic_vector(31 downto 0);
        o_ALUResult: out std_logic_vector(31 downto 0);
        o_PCPlus4  : out std_logic_vector(31 downto 0);
        o_Imm      : out std_logic_vector(31 downto 0);
        o_Rd       : out std_logic_vector(4 downto 0)
    );
end MEM_WB_Reg;

architecture behavior of MEM_WB_Reg is
begin
    process(i_CLK, i_RST)
    begin
        if (i_RST = '1') then
            -- Control reset
            o_RegWrite <= '0';
            o_MemtoReg <= "00";
            o_Halt     <= '0';

            -- Data reset
            o_ReadData <= (others => '0');
            o_ALUResult<= (others => '0');
            o_PCPlus4  <= (others => '0');
            o_Imm      <= (others => '0');
            o_Rd       <= (others => '0');

        elsif rising_edge(i_CLK) then
            -- Pipeline propagation
            o_RegWrite <= i_RegWrite;
            o_MemtoReg <= i_MemtoReg;
            o_Halt     <= i_Halt;

            o_ReadData <= i_ReadData;
            o_ALUResult<= i_ALUResult;
            o_PCPlus4  <= i_PCPlus4;
            o_Imm      <= i_Imm;
            o_Rd       <= i_Rd;
        end if;
    end process;
end behavior;