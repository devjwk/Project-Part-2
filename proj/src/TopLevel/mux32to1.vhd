library IEEE;

use IEEE.std_logic_1164.all;

use IEEE.numeric_std.all;

entity mux32to1 is

    port (

        data_in : in  std_logic_vector(32*32-1 downto 0); -- 32 inputs × 32 bits

        sel     : in  std_logic_vector(4 downto 0);       -- 5-bit selector (0~31)

        y_out   : out std_logic_vector(31 downto 0)       -- selected 32-bit output

    );

end mux32to1;

architecture dataflow of mux32to1 is

begin

    process(data_in, sel)

    begin

        y_out <= data_in( (to_integer(unsigned(sel))+1)*32-1 downto to_integer(unsigned(sel))*32 );

    end process;

end dataflow;