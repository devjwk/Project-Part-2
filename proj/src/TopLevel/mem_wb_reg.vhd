library IEEE;
use IEEE.std_logic_1164.all;

entity mem_wb_reg is
    port(
        i_CLK      : in std_logic;
        i_RST      : in std_logic;

        -- From MEM
        i_ReadData : in std_logic_vector(31 downto 0);
        i_ALURes   : in std_logic_vector(31 downto 0);
        i_PCPlus4  : in std_logic_vector(31 downto 0);
        i_Imm      : in std_logic_vector(31 downto 0);
        i_Rd       : in std_logic_vector(4 downto 0);

        -- Control
        i_MemtoReg : in std_logic_vector(1 downto 0);
        i_RegWrite : in std_logic;

        -- To WB
        o_ReadData : out std_logic_vector(31 downto 0);
        o_ALURes   : out std_logic_vector(31 downto 0);
        o_PCPlus4  : out std_logic_vector(31 downto 0);
        o_Imm      : out std_logic_vector(31 downto 0);
        o_Rd       : out std_logic_vector(4 downto 0);

        o_MemtoReg : out std_logic_vector(1 downto 0);
        o_RegWrite : out std_logic
    );
end mem_wb_reg;
architecture rtl of mem_wb_reg is
    signal r_ReadData : std_logic_vector(31 downto 0);
    signal r_ALURes   : std_logic_vector(31 downto 0);
    signal r_PCPlus4  : std_logic_vector(31 downto 0);
    signal r_Imm      : std_logic_vector(31 downto 0);
    signal r_Rd       : std_logic_vector(4 downto 0);

    signal r_MemtoReg : std_logic_vector(1 downto 0);
    signal r_RegWrite : std_logic;
begin
    process(i_CLK)
    begin
        if rising_edge(i_CLK) then
            if i_RST = '1' then
                r_ReadData <= (others => '0');
                r_ALURes   <= (others => '0');
                r_PCPlus4  <= (others => '0');
                r_Imm      <= (others => '0');
                r_Rd       <= (others => '0');
                r_MemtoReg <= (others => '0');
                r_RegWrite <= '0';
            else
                r_ReadData <= i_ReadData;
                r_ALURes   <= i_ALURes;
                r_PCPlus4  <= i_PCPlus4;
                r_Imm      <= i_Imm;
                r_Rd       <= i_Rd;
                r_MemtoReg <= i_MemtoReg;
                r_RegWrite <= i_RegWrite;
            end if;
        end if;
    end process;

    o_ReadData <= r_ReadData;
    o_ALURes   <= r_ALURes;
    o_PCPlus4  <= r_PCPlus4;
    o_Imm      <= r_Imm;
    o_Rd       <= r_Rd;
    o_MemtoReg <= r_MemtoReg;
    o_RegWrite <= r_RegWrite;
end rtl;
