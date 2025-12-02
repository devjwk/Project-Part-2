-------------------------------------------------------------------------
-- EX/MEM Pipeline Register
-- Holds ALU results, memory control, and writeback information.
-- Flush is NOT used here (hazards only require ID/EX flush).
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

entity EX_MEM_Reg is
    port(
        i_CLK      : in  std_logic;
        i_RST      : in  std_logic;

        -- Control signals
        i_RegWrite : in std_logic;
        i_MemtoReg : in std_logic_vector(1 downto 0);
        i_MemRead  : in std_logic;
        i_MemWrite : in std_logic;
        i_Halt     : in std_logic;

        -- Data
        i_PCPlus4   : in std_logic_vector(31 downto 0);
        i_ALUResult : in std_logic_vector(31 downto 0);
        i_WriteData : in std_logic_vector(31 downto 0);  -- RS2 value
        i_Rd        : in std_logic_vector(4 downto 0);
        i_Imm       : in std_logic_vector(31 downto 0);

        -- Outputs
        o_RegWrite : out std_logic;
        o_MemtoReg : out std_logic_vector(1 downto 0);
        o_MemRead  : out std_logic;
        o_MemWrite : out std_logic;
        o_Halt     : out std_logic;

        o_PCPlus4   : out std_logic_vector(31 downto 0);
        o_ALUResult : out std_logic_vector(31 downto 0);
        o_WriteData : out std_logic_vector(31 downto 0);
        o_Rd        : out std_logic_vector(4 downto 0);
        o_Imm       : out std_logic_vector(31 downto 0)
    );
end EX_MEM_Reg;

architecture behavior of EX_MEM_Reg is
begin
    process(i_CLK, i_RST)
    begin
        if (i_RST = '1') then
            -- Control reset
            o_RegWrite <= '0';
            o_MemtoReg <= "00";
            o_MemRead  <= '0';
            o_MemWrite <= '0';
            o_Halt     <= '0';

            -- Data reset
            o_PCPlus4   <= (others => '0');
            o_ALUResult <= (others => '0');
            o_WriteData <= (others => '0');
            o_Rd        <= (others => '0');
            o_Imm       <= (others => '0');

        elsif rising_edge(i_CLK) then
            -- Normal pipeline register transfer
            o_RegWrite <= i_RegWrite;
            o_MemtoReg <= i_MemtoReg;
            o_MemRead  <= i_MemRead;
            o_MemWrite <= i_MemWrite;
            o_Halt     <= i_Halt;

            o_PCPlus4   <= i_PCPlus4;
            o_ALUResult <= i_ALUResult;
            o_WriteData <= i_WriteData;
            o_Rd        <= i_Rd;
            o_Imm       <= i_Imm;
        end if;
    end process;
end behavior;