library IEEE;
use IEEE.std_logic_1164.all;

entity if_id_reg is
    port(
        i_CLK : in std_logic;
        i_RST : in std_logic;

        -- From IF
        i_PC   : in std_logic_vector(31 downto 0);
        i_Inst : in std_logic_vector(31 downto 0);

        -- To ID
        o_PC   : out std_logic_vector(31 downto 0);
        o_Inst : out std_logic_vector(31 downto 0)
    );
end if_id_reg;

architecture rtl of if_id_reg is
    signal r_PC   : std_logic_vector(31 downto 0);
    signal r_Inst : std_logic_vector(31 downto 0);
begin
    process(i_CLK)
    begin
        if rising_edge(i_CLK) then
            if i_RST = '1' then
                r_PC   <= (others => '0');
                r_Inst <= (others => '0');
            else
                r_PC   <= i_PC;
                r_Inst <= i_Inst;
            end if;
        end if;
    end process;

    o_PC   <= r_PC;
    o_Inst <= r_Inst;
end rtl;
