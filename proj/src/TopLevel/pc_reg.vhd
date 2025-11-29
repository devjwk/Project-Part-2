-------------------------------------------------------------------------
-- Stores the current instruction address
-------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity pc_reg is
    generic(N : integer := 32);
    port(
        i_CLK    : in std_logic;                      -- Clock
        i_RST    : in std_logic;                      -- Reset (High Active)
        i_WE     : in std_logic;                      -- Write Enable (always 1)
        i_NextPC : in std_logic_vector(N-1 downto 0); -- From Fetch Logic
        o_PC     : out std_logic_vector(N-1 downto 0) -- To IMem & Fetch Logic
    );
end pc_reg;

architecture behavior of pc_reg is
    -- Internal signal to store the current PC value (initial value = 0)
    signal s_PC : std_logic_vector(N-1 downto 0) := (others => '0');
begin

    process(i_CLK, i_RST)
    begin
        -- 1. When reset is asserted, initialize PC to 0
        --    (Depending on the lab setup, may need to change to 0x00400000, etc.)
        if (i_RST = '1') then
            s_PC <= "00000000010000000000000000000000"; 
            
        -- 2. On rising clock edge, update PC
        elsif rising_edge(i_CLK) then
            if (i_WE = '1') then
                s_PC <= i_NextPC;
            end if;
        end if;
    end process;

    -- Output connection
    o_PC <= s_PC;

end behavior;
