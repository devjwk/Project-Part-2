-------------------------------------------------------------------------
-- IF/ID Pipeline Register
-- Stores Instruction and PC from the Fetch Stage for the Decode Stage.
-- Optimized for Part 1: No hardware stall logic included.
-------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;

entity IF_ID_Reg is
    port(
        i_CLK       : in std_logic;
        i_RST       : in std_logic;
        
        -- Control Signals
        i_Flush     : in std_logic; -- 1: Clear to NOP (Used when Branch/Jump is taken)

        -- Data Inputs (From Fetch Stage)
        i_PC        : in std_logic_vector(31 downto 0); -- Current PC
        i_Inst      : in std_logic_vector(31 downto 0); -- Fetched Instruction

        -- Data Outputs (To Decode Stage)
        o_PC        : out std_logic_vector(31 downto 0);
        o_Inst      : out std_logic_vector(31 downto 0)
    );
end IF_ID_Reg;

architecture behavior of IF_ID_Reg is
begin
    process(i_CLK, i_RST)
    begin
        -- Asynchronous Reset
        if (i_RST = '1') then
            o_PC   <= (others => '0');
            o_Inst <= (others => '0'); -- Initialize to NOP (0x00000000)

        elsif (rising_edge(i_CLK)) then
            
            if (i_Flush = '1') then
                -- Flush: Clear instruction to NOP 
                -- This happens when a Branch/Jump decision is made in EX stage,
                -- making the currently fetched instruction invalid.
                o_PC   <= (others => '0');
                o_Inst <= (others => '0'); 
                
            else
                -- Normal Operation: Update values every cycle
                -- (No stalling logic needed for software-scheduled pipeline)
                o_PC   <= i_PC;
                o_Inst <= i_Inst;
            end if;
            
        end if;
    end process;

end behavior;