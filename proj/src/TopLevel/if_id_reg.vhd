-------------------------------------------------------------------------
-- IF/ID Pipeline Register
-- Holds PC and Instruction for the Decode Stage
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

entity IF_ID_Reg is
    port(
        i_CLK   : in  std_logic;
        i_RST   : in  std_logic;
        i_Flush : in  std_logic; -- Flush when branch taken

        i_PC    : in  std_logic_vector(31 downto 0);
        i_Inst  : in  std_logic_vector(31 downto 0);

        o_PC    : out std_logic_vector(31 downto 0);
        o_Inst  : out std_logic_vector(31 downto 0)
    );
end IF_ID_Reg;

architecture behavior of IF_ID_Reg is
begin
    process(i_CLK, i_RST)
    begin
        if (i_RST = '1') then
            -- Reset: clear everything to 0
            o_PC   <= (others => '0');
            o_Inst <= (others => '0');

        elsif rising_edge(i_CLK) then
            if (i_Flush = '1') then
                -- Flush: convert this stage into a bubble
                o_PC   <= (others => '0');
                o_Inst <= (others => '0');
            else
                -- Normal pipeline propagation
                o_PC   <= i_PC;
                o_Inst <= i_Inst;
            end if;
        end if;
    end process;

end behavior;