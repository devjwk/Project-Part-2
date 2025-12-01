-------------------------------------------------------------------------
-- MEM/WB Pipeline Register
-- Stores final data (from Memory or ALU) for the Writeback Stage.
-------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;

entity MEM_WB_Reg is
    port(
        i_CLK       : in std_logic;
        i_RST       : in std_logic;

        -- [Control Signals]
        -- WB Stage Signals (Used in this final stage)
        i_RegWrite  : in std_logic;                    -- To Register File WE
        i_MemtoReg  : in std_logic_vector(1 downto 0); -- To WB Mux Select
        i_Halt      : in std_logic;                    -- Final Halt Signal

        -- [Data Signals]
        i_ReadData  : in std_logic_vector(31 downto 0); -- Data read from Memory
        i_ALUResult : in std_logic_vector(31 downto 0); -- Bypass from ALU
        i_PCPlus4   : in std_logic_vector(31 downto 0); -- For JAL/JALR
        i_Imm       : in std_logic_vector(31 downto 0); -- For LUI
        i_Rd        : in std_logic_vector(4 downto 0);  -- Dest Register Address

        -- [Outputs] Mapped 1:1 to Inputs
        o_RegWrite  : out std_logic;
        o_MemtoReg  : out std_logic_vector(1 downto 0);
        o_Halt      : out std_logic;

        o_ReadData  : out std_logic_vector(31 downto 0);
        o_ALUResult : out std_logic_vector(31 downto 0);
        o_PCPlus4   : out std_logic_vector(31 downto 0);
        o_Imm       : out std_logic_vector(31 downto 0);
        o_Rd        : out std_logic_vector(4 downto 0)
    );
end MEM_WB_Reg;

architecture behavior of MEM_WB_Reg is
begin
    process(i_CLK, i_RST)
    begin
        if (i_RST = '1') then
            -- Reset: Clear Control Signals
            o_RegWrite <= '0';
            o_Halt     <= '0';
            -- o_MemtoReg doesn't strictly need reset if RegWrite is 0, but safer to clear
            o_MemtoReg <= "00";
            
            -- Reset Data Signals
            o_ReadData  <= (others => '0');
            o_ALUResult <= (others => '0');
            o_PCPlus4   <= (others => '0');
            o_Imm       <= (others => '0');
            o_Rd        <= (others => '0');
            
        elsif (rising_edge(i_CLK)) then
            -- Normal Operation: Pass all signals
            o_RegWrite <= i_RegWrite;
            o_MemtoReg <= i_MemtoReg;
            o_Halt     <= i_Halt;

            o_ReadData  <= i_ReadData;
            o_ALUResult <= i_ALUResult;
            o_PCPlus4   <= i_PCPlus4;
            o_Imm       <= i_Imm;
            o_Rd        <= i_Rd;
        end if;
    end process;
end behavior;