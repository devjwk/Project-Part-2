-------------------------------------------------------------------------
-- Supports: SLL, SRL, SRA
-------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity barrel_shifter is
    port(
        i_data  : in  std_logic_vector(31 downto 0); -- input data
        i_amt   : in  std_logic_vector(4 downto 0);  -- shift amount (Shamt)
        i_dir   : in  std_logic;                     -- 0: Right(SRL/SRA), 1: Left(SLL)
        i_arith : in  std_logic;                     -- 1: Arithmetic(SRA), 0: Logical
        o_data  : out std_logic_vector(31 downto 0)  -- result
    );
end barrel_shifter;

architecture structural of barrel_shifter is

    -- internal signals
    signal s_in_reversed  : std_logic_vector(31 downto 0);
    signal s_mux_in       : std_logic_vector(31 downto 0);
    signal s_fill_bit     : std_logic;
    
    -- each steps MUX results
    signal s_stage1       : std_logic_vector(31 downto 0);
    signal s_stage2       : std_logic_vector(31 downto 0);
    signal s_stage4       : std_logic_vector(31 downto 0);
    signal s_stage8       : std_logic_vector(31 downto 0);
    signal s_stage16      : std_logic_vector(31 downto 0);
    
    signal s_out_reversed : std_logic_vector(31 downto 0);

begin

    --------------------------------------------------------------
    -- 1. Pre-processing: Reverse input for Left Shift support
    --------------------------------------------------------------
    -- If i_dir = 1 (Left), reverse input so that shifting is done as a Right Shift internally
    process(i_data, i_dir)
    begin
        if i_dir = '1' then
            for k in 0 to 31 loop
                s_in_reversed(k) <= i_data(31-k);
            end loop;
        else
            s_in_reversed <= i_data;
        end if;
    end process;

    s_mux_in <= s_in_reversed;


    --------------------------------------------------------------
    -- 2. Arithmetic Fill Bit decision
    --------------------------------------------------------------
    -- Only for SRA (Arithmetic), preserve MSB; otherwise fill with '0'
    -- Note: For Left Shift, even if arithmetic, always fill with '0'
    s_fill_bit <= s_mux_in(31) when (i_arith = '1' and i_dir = '0') else '0';


    --------------------------------------------------------------
    -- 3. Structural MUX Layers (Right Shifter Core)
    --------------------------------------------------------------
    
    -- Stage 1: Shift by 1 bit
    -- If i_amt(0)=1, shift right by 1; otherwise passthrough
    GEN_MUX_1: for i in 0 to 30 generate
        s_stage1(i) <= s_mux_in(i+1) when i_amt(0)='1' else s_mux_in(i);
    end generate;
    s_stage1(31) <= s_fill_bit when i_amt(0)='1' else s_mux_in(31);

    -- Stage 2: Shift by 2 bits
    GEN_MUX_2: for i in 0 to 29 generate
        s_stage2(i) <= s_stage1(i+2) when i_amt(1)='1' else s_stage1(i);
    end generate;
    GEN_FILL_2: for i in 30 to 31 generate
        s_stage2(i) <= s_fill_bit when i_amt(1)='1' else s_stage1(i);
    end generate;

    -- Stage 3: Shift by 4 bits
    GEN_MUX_4: for i in 0 to 27 generate
        s_stage4(i) <= s_stage2(i+4) when i_amt(2)='1' else s_stage2(i);
    end generate;
    GEN_FILL_4: for i in 28 to 31 generate
        s_stage4(i) <= s_fill_bit when i_amt(2)='1' else s_stage2(i);
    end generate;

    -- Stage 4: Shift by 8 bits
    GEN_MUX_8: for i in 0 to 23 generate
        s_stage8(i) <= s_stage4(i+8) when i_amt(3)='1' else s_stage4(i);
    end generate;
    GEN_FILL_8: for i in 24 to 31 generate
        s_stage8(i) <= s_fill_bit when i_amt(3)='1' else s_stage4(i);
    end generate;

    -- Stage 5: Shift by 16 bits
    GEN_MUX_16: for i in 0 to 15 generate
        s_stage16(i) <= s_stage8(i+16) when i_amt(4)='1' else s_stage8(i);
    end generate;
    GEN_FILL_16: for i in 16 to 31 generate
        s_stage16(i) <= s_fill_bit when i_amt(4)='1' else s_stage8(i);
    end generate;


    --------------------------------------------------------------
    -- 4. Post-processing: Reverse result back
    --------------------------------------------------------------
    -- If Left Shift, reverse again to restore original bit order
    process(s_stage16, i_dir)
    begin
        if i_dir = '1' then
            for k in 0 to 31 loop
                s_out_reversed(k) <= s_stage16(31-k);
            end loop;
        else
            s_out_reversed <= s_stage16;
        end if;
    end process;

    o_data <= s_out_reversed;

end structural;
