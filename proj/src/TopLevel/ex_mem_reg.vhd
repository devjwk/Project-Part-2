-------------------------------------------------------------------------
-- EX/MEM Pipeline Register
-- Captures ALU results and memory write data for the Memory Stage.
-------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;

entity EX_MEM_Reg is
    port(
        i_CLK       : in std_logic;
        i_RST       : in std_logic;

        -- [Control Signals]
        -- WB Stage Signals (Pass-through to WB)
        i_RegWrite  : in std_logic;
        i_MemtoReg  : in std_logic_vector(1 downto 0);
        i_Halt      : in std_logic;

        -- MEM Stage Signals (Used in next stage)
        i_MemWrite  : in std_logic;
        i_MemRead   : in std_logic;

        -- [Data Signals]
        i_PCPlus4   : in std_logic_vector(31 downto 0); -- For JAL/JALR
        i_ALUResult : in std_logic_vector(31 downto 0); -- Calculated Address or Result
        i_WriteData : in std_logic_vector(31 downto 0); -- Data to store (sw)
        i_Rd        : in std_logic_vector(4 downto 0);  -- Dest Register Address
        i_Imm       : in std_logic_vector(31 downto 0); -- Pass-through (optional, for LUI)

        -- [Outputs] Mapped 1:1 to Inputs
        o_RegWrite  : out std_logic;
        o_MemtoReg  : out std_logic_vector(1 downto 0);
        o_Halt      : out std_logic;

        o_MemWrite  : out std_logic;
        o_MemRead   : out std_logic;

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
            -- Reset: Clear Control Signals
            o_RegWrite <= '0';
            o_MemtoReg <= "00";
            o_Halt     <= '0';
            o_MemWrite <= '0';
            o_MemRead  <= '0';
            
            -- Reset Data Signals
            o_PCPlus4   <= (others => '0');
            o_ALUResult <= (others => '0');
            o_WriteData <= (others => '0');
            o_Rd        <= (others => '0');
            o_Imm       <= (others => '0');
            
        elsif (rising_edge(i_CLK)) then
            -- Normal Operation: Pass all signals
            o_RegWrite <= i_RegWrite;
            o_MemtoReg <= i_MemtoReg;
            o_Halt     <= i_Halt;
            
            o_MemWrite <= i_MemWrite;
            o_MemRead  <= i_MemRead;

            o_PCPlus4   <= i_PCPlus4;
            o_ALUResult <= i_ALUResult;
            o_WriteData <= i_WriteData;
            o_Rd        <= i_Rd;
            o_Imm       <= i_Imm;
        end if;
    end process;
end behavior;