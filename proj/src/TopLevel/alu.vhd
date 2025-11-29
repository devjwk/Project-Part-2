-------------------------------------------------------------------------
-- Integrates: Adder/Subtractor, Barrel Shifter, Logic Unit
-- NEW: Outputs Sign Bit (o_Sign) and Carry Out (o_Cout) for Branch Logic.
-------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity alu is
    port(
        i_A        : in std_logic_vector(31 downto 0);
        i_B        : in std_logic_vector(31 downto 0);
        i_ALUCtrl  : in std_logic_vector(3 downto 0); 

        o_Result   : out std_logic_vector(31 downto 0);
        o_Zero     : out std_logic;
        o_Sign     : out std_logic; -- Sign Bit (MSB of result)
        o_Cout     : out std_logic  -- Carry Out for Unsigned comparison (bltu/bgeu)
    );
end alu;

architecture structural of alu is

    -- [1] Adder/Subtractor Component (o_Cout must be connected here)
    component adder_subtractor is
        generic(N : integer := 32);
        port(
            i_A        : in  std_logic_vector(N-1 downto 0);
            i_B        : in  std_logic_vector(N-1 downto 0);
            i_nAdd_Sub : in  std_logic; 
            o_Sum      : out std_logic_vector(N-1 downto 0);
            o_Cout     : out std_logic -- Connected to ALU's o_Cout
        );
    end component;

    -- [2] Barrel Shifter Component (no change needed here)
    component barrel_shifter is
        port(
            i_data  : in  std_logic_vector(31 downto 0);
            i_amt   : in  std_logic_vector(4 downto 0);
            i_dir   : in  std_logic; 
            i_arith : in  std_logic; 
            o_data  : out std_logic_vector(31 downto 0)
        );
    end component;

    -- Internal Signals
    signal s_Sum        : std_logic_vector(31 downto 0); 
    signal s_ShiftRes   : std_logic_vector(31 downto 0); 
    signal s_LogicRes   : std_logic_vector(31 downto 0); 
    signal s_FinalRes   : std_logic_vector(31 downto 0); 
    
    -- Control Signals for Sub-components
    signal s_nAdd_Sub   : std_logic;
    signal s_ShiftDir   : std_logic;
    signal s_ShiftArith : std_logic;
    signal s_AdderCout  : std_logic; -- Internal signal for Cout

    signal s_SLT_Result : std_logic_vector(31 downto 0);

begin

    -----------------------------------------------------------------
    -- 1. Control Signal Decoding
    -----------------------------------------------------------------
    s_nAdd_Sub <= '1' when (i_ALUCtrl = "0110" or i_ALUCtrl = "0111") else '0';
    s_ShiftDir <= '1' when (i_ALUCtrl = "1001") else '0'; 
    s_ShiftArith <= '1' when (i_ALUCtrl = "1010") else '0'; 


    -----------------------------------------------------------------
    -- 2. Instantiate Adder/Subtractor
    -----------------------------------------------------------------
    U_ADDER : adder_subtractor
    generic map(N => 32)
    port map(
        i_A        => i_A,
        i_B        => i_B,
        i_nAdd_Sub => s_nAdd_Sub,
        o_Sum      => s_Sum,
        o_Cout     => s_AdderCout -- Connect to internal signal
    );


    -----------------------------------------------------------------
    -- 3. Instantiate Barrel Shifter
    -----------------------------------------------------------------
    U_SHIFTER : barrel_shifter
    port map(
        i_data  => i_A,
        i_amt   => i_B(4 downto 0), 
        i_dir   => s_ShiftDir,
        i_arith => s_ShiftArith,
        o_data  => s_ShiftRes
    );


    -----------------------------------------------------------------
    -- 4. Logic Unit (AND, OR, XOR)
    -----------------------------------------------------------------
    process(i_A, i_B, i_ALUCtrl)
    begin
        case i_ALUCtrl is
            when "0000" => s_LogicRes <= i_A and i_B;
            when "0001" => s_LogicRes <= i_A or i_B;
            when "0100" => s_LogicRes <= i_A xor i_B;
            when others => s_LogicRes <= (others => '0');
        end case;
    end process;


    -----------------------------------------------------------------
    -- 5. Final MUX & SLT Logic
    -----------------------------------------------------------------
    process(i_ALUCtrl, s_Sum, s_ShiftRes, s_LogicRes, s_SLT_Result)
    begin
        -- SLT Logic
        if s_Sum(31) = '1' then 
            s_SLT_Result <= x"00000001";
        else
            s_SLT_Result <= x"00000000";
        end if;
        
        -- Final Selection MUX
        case i_ALUCtrl is
            when "0010" | "0110" => s_FinalRes <= s_Sum;
            when "0111" => s_FinalRes <= s_SLT_Result; 
            when "1000" | "1001" | "1010" => s_FinalRes <= s_ShiftRes;
            when "0000" | "0001" | "0100" => s_FinalRes <= s_LogicRes;
            when others => s_FinalRes <= (others => '0');
        end case;
    end process;


    -----------------------------------------------------------------
    -- 6. Output Assignments
    -----------------------------------------------------------------
    o_Result <= s_FinalRes;

    -- Zero Flag Generation
    o_Zero <= '1' when (unsigned(s_FinalRes) = 0) else '0';
    
    -- Sign Flag Generation (MSB of the final result)
    o_Sign <= s_FinalRes(31); 
    
    -- Carry Out Generation
    o_Cout <= s_AdderCout; -- NEW: Expose Carry Out for unsigned branch logic

end structural;