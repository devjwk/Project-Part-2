-------------------------------------------------------------------------
-- Performs Addition (A+B) or Subtraction (A-B) based on control signal
-------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity adder_subtractor is
    generic(N : integer := 32);
    port(
        i_A        : in  std_logic_vector(N-1 downto 0);
        i_B        : in  std_logic_vector(N-1 downto 0);
        i_nAdd_Sub : in  std_logic; -- 0: Add, 1: Sub
        o_Sum      : out std_logic_vector(N-1 downto 0);
        o_Cout     : out std_logic
    );
end adder_subtractor;

architecture behavior of adder_subtractor is
    -- internal signals (for operation)
    signal s_A      : unsigned(N downto 0); -- for carry arithmetic, expand 1 bit
    signal s_B_mod  : unsigned(N downto 0); -- B -> XOR -> B
    signal s_Result : unsigned(N downto 0);
    
begin
    
    -- 1. Convert input A to Unsigned and extend width to N+1 bits (prevents overflow)
    s_A <= resize(unsigned(i_A), N+1);

    -- 2. Subtraction logic preparation (forming two’s complement)
    -- When i_nAdd_Sub = '1', invert B (NOT B) for subtraction; when '0', use B unchanged
    process(i_B, i_nAdd_Sub)
    begin
        if (i_nAdd_Sub = '1') then
            s_B_mod <= resize(unsigned(not i_B), N+1);
        else
            s_B_mod <= resize(unsigned(i_B), N+1);
        end if;
    end process;

    -- 3. Perform addition: A + (B or NOT B) + Cin
    -- When subtracting, i_nAdd_Sub = '1', so Cin = 1 (to complete two's complement addition)
    s_Result <= s_A + s_B_mod + ("0" & i_nAdd_Sub);

    -- 4. Output the results
    o_Sum  <= std_logic_vector(s_Result(N-1 downto 0)); -- Lower 32 bits of the result
    o_Cout <= std_logic(s_Result(N));                   -- Most significant bit (Carry Out)

end behavior;