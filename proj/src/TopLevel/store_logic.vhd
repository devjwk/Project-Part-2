-------------------------------------------------------------------------
-- Store Logic (sb, sh, sw)
-- Generates Byte Enables (WE bits) for memory component.
-------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity store_logic is
    port(
        i_MemWrite : in  std_logic;                    -- Master MemWrite signal (from Control)
        i_Funct3   : in  std_logic_vector(2 downto 0);  -- Store Type (sb, sh, sw)
        i_AddrLSB  : in  std_logic_vector(1 downto 0);  -- Byte offset (Addr[1:0])
        o_ByteWE   : out std_logic_vector(3 downto 0)   -- Byte Enable (Memory WE pin)
    );
end entity;

architecture behavior of store_logic is
begin
    
    process(i_MemWrite, i_Funct3, i_AddrLSB)
    begin
        o_ByteWE <= (others => '0');

        if i_MemWrite = '1' then
            case i_Funct3 is
                when "000" => -- SB (Store Byte)
                    case i_AddrLSB is
                        when "00" => o_ByteWE <= "0001";
                        when "01" => o_ByteWE <= "0010";
                        when "10" => o_ByteWE <= "0100";
                        when others => o_ByteWE <= "1000";
                    end case;
                when "001" => -- SH (Store Half-word)
                    if i_AddrLSB(1) = '0' then
                        o_ByteWE <= "0011"; -- Lower Half (0, 1)
                    else
                        o_ByteWE <= "1100"; -- Upper Half (2, 3)
                    end if;
                when "010" => -- SW (Store Word)
                    o_ByteWE <= "1111"; -- All bytes
                when others =>
                    o_ByteWE <= (others => '0');
            end case;
        end if;
    end process;
    
end architecture;