library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity imm_gen is
    port(
        i_Inst    : in std_logic_vector(31 downto 0); -- full instruction
        i_ImmType : in std_logic_vector(2 downto 0);  -- from Control Unit
        o_Imm     : out std_logic_vector(31 downto 0) -- extended 32bits numbers
    );
end imm_gen;

architecture behavior of imm_gen is
begin
    process(i_Inst, i_ImmType)
    begin
        case i_ImmType is
            -- I-Type (addi, lw, jalr)
            when "000" => 
                o_Imm <= std_logic_vector(resize(signed(i_Inst(31 downto 20)), 32));
            
            -- S-Type (sw)
            when "001" => 
                o_Imm <= std_logic_vector(resize(signed(i_Inst(31 downto 25) & i_Inst(11 downto 7)), 32));
            
            -- B-Type (beq)
            when "010" => 
                o_Imm <= std_logic_vector(resize(signed(i_Inst(31) & i_Inst(7) & i_Inst(30 downto 25) & i_Inst(11 downto 8) & '0'), 32));
            
            -- J-Type (jal)
            when "011" => 
                o_Imm <= std_logic_vector(resize(signed(i_Inst(31) & i_Inst(19 downto 12) & i_Inst(20) & i_Inst(30 downto 21) & '0'), 32));
            
            -- U-Type (lui)
            when "100" => 
                o_Imm <= i_Inst(31 downto 12) & x"000";
                
            when others =>
                o_Imm <= (others => '0');
        end case;
    end process;
end behavior;