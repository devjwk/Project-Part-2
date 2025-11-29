library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity load_extender is
    port(
        i_DMemOut : in  std_logic_vector(31 downto 0);
        i_Funct3  : in  std_logic_vector(2 downto 0);
        i_AddrLSB : in  std_logic_vector(1 downto 0);
        o_ReadData: out std_logic_vector(31 downto 0)
    );
end load_extender;

architecture behavioral of load_extender is
begin
    process(i_DMemOut, i_Funct3, i_AddrLSB)
        variable v_byte : std_logic_vector(7 downto 0);
        variable v_half : std_logic_vector(15 downto 0);
        variable v_word : std_logic_vector(31 downto 0);
    begin

        v_word := (others => '0');

        case i_Funct3 is

            -- LB
            when "000" =>
                case i_AddrLSB is
                    when "00" => v_byte := i_DMemOut(7 downto 0);
                    when "01" => v_byte := i_DMemOut(15 downto 8);
                    when "10" => v_byte := i_DMemOut(23 downto 16);
                    when others => v_byte := i_DMemOut(31 downto 24);
                end case;

                v_word := std_logic_vector(resize(signed(v_byte), 32));
            
            -- LH
            when "001" =>
                if i_AddrLSB(1) = '0' then
                    v_half := i_DMemOut(15 downto 0);
                else
                    v_half := i_DMemOut(31 downto 16);
                end if;

                v_word := std_logic_vector(resize(signed(v_half), 32));

            -- LW
            when "010" =>
                v_word := i_DMemOut;

            -- LBU
            when "100" =>
                case i_AddrLSB is
                    when "00" => v_byte := i_DMemOut(7 downto 0);
                    when "01" => v_byte := i_DMemOut(15 downto 8);
                    when "10" => v_byte := i_DMemOut(23 downto 16);
                    when others => v_byte := i_DMemOut(31 downto 24);
                end case;

                v_word := std_logic_vector(resize(unsigned(v_byte), 32));

            -- LHU
            when "101" =>
                if i_AddrLSB(1) = '0' then
                    v_half := i_DMemOut(15 downto 0);
                else
                    v_half := i_DMemOut(31 downto 16);
                end if;

                v_word := std_logic_vector(resize(unsigned(v_half), 32));

            when others =>
                v_word := (others => '0');

        end case;

        o_ReadData <= v_word;

    end process;
end behavioral;