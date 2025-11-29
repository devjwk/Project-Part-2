library IEEE;
use IEEE.std_logic_1164.all;

entity id_ex_reg is
    port(
        i_CLK       : in  std_logic;
        i_RST       : in  std_logic;

        -- Datapath input
        i_PC        : in  std_logic_vector(31 downto 0);
        i_ReadData1 : in  std_logic_vector(31 downto 0);
        i_ReadData2 : in  std_logic_vector(31 downto 0);
        i_Imm       : in  std_logic_vector(31 downto 0);
        i_Funct3    : in  std_logic_vector(2 downto 0);
        i_Funct7    : in  std_logic_vector(6 downto 0);
        i_Rd        : in  std_logic_vector(4 downto 0);

        -- Control input
        i_ALUSrcA   : in  std_logic;
        i_ALUSrcB   : in  std_logic;
        i_ALUOp     : in  std_logic_vector(1 downto 0);
        i_MemRead   : in  std_logic;
        i_MemWrite  : in  std_logic;
        i_MemtoReg  : in  std_logic_vector(1 downto 0);
        i_RegWrite  : in  std_logic;
        i_Branch    : in  std_logic;
        i_Jump      : in  std_logic_vector(1 downto 0);

        -- Datapath output
        o_PC        : out std_logic_vector(31 downto 0);
        o_ReadData1 : out std_logic_vector(31 downto 0);
        o_ReadData2 : out std_logic_vector(31 downto 0);
        o_Imm       : out std_logic_vector(31 downto 0);
        o_Funct3    : out std_logic_vector(2 downto 0);
        o_Funct7    : out std_logic_vector(6 downto 0);
        o_Rd        : out std_logic_vector(4 downto 0);

        -- Control output
        o_ALUSrcA   : out std_logic;
        o_ALUSrcB   : out std_logic;
        o_ALUOp     : out std_logic_vector(1 downto 0);
        o_MemRead   : out std_logic;
        o_MemWrite  : out std_logic;
        o_MemtoReg  : out std_logic_vector(1 downto 0);
        o_RegWrite  : out std_logic;
        o_Branch    : out std_logic;
        o_Jump      : out std_logic_vector(1 downto 0)
    );
end id_ex_reg;

architecture rtl of id_ex_reg is
    signal r_PC        : std_logic_vector(31 downto 0);
    signal r_ReadData1 : std_logic_vector(31 downto 0);
    signal r_ReadData2 : std_logic_vector(31 downto 0);
    signal r_Imm       : std_logic_vector(31 downto 0);
    signal r_Funct3    : std_logic_vector(2 downto 0);
    signal r_Funct7    : std_logic_vector(6 downto 0);
    signal r_Rd        : std_logic_vector(4 downto 0);

    signal r_ALUSrcA   : std_logic;
    signal r_ALUSrcB   : std_logic;
    signal r_ALUOp     : std_logic_vector(1 downto 0);
    signal r_MemRead   : std_logic;
    signal r_MemWrite  : std_logic;
    signal r_MemtoReg  : std_logic_vector(1 downto 0);
    signal r_RegWrite  : std_logic;
    signal r_Branch    : std_logic;
    signal r_Jump      : std_logic_vector(1 downto 0);
begin
    process(i_CLK)
    begin
        if rising_edge(i_CLK) then
            if i_RST = '1' then
                r_PC        <= (others => '0');
                r_ReadData1 <= (others => '0');
                r_ReadData2 <= (others => '0');
                r_Imm       <= (others => '0');
                r_Funct3    <= (others => '0');
                r_Funct7    <= (others => '0');
                r_Rd        <= (others => '0');

                r_ALUSrcA   <= '0';
                r_ALUSrcB   <= '0';
                r_ALUOp     <= (others => '0');
                r_MemRead   <= '0';
                r_MemWrite  <= '0';
                r_MemtoReg  <= (others => '0');
                r_RegWrite  <= '0';
                r_Branch    <= '0';
                r_Jump      <= (others => '0');
            else
                r_PC        <= i_PC;
                r_ReadData1 <= i_ReadData1;
                r_ReadData2 <= i_ReadData2;
                r_Imm       <= i_Imm;
                r_Funct3    <= i_Funct3;
                r_Funct7    <= i_Funct7;
                r_Rd        <= i_Rd;

                r_ALUSrcA   <= i_ALUSrcA;
                r_ALUSrcB   <= i_ALUSrcB;
                r_ALUOp     <= i_ALUOp;
                r_MemRead   <= i_MemRead;
                r_MemWrite  <= i_MemWrite;
                r_MemtoReg  <= i_MemtoReg;
                r_RegWrite  <= i_RegWrite;
                r_Branch    <= i_Branch;
                r_Jump      <= i_Jump;
            end if;
        end if;
    end process;

    o_PC        <= r_PC;
    o_ReadData1 <= r_ReadData1;
    o_ReadData2 <= r_ReadData2;
    o_Imm       <= r_Imm;
    o_Funct3    <= r_Funct3;
    o_Funct7    <= r_Funct7;
    o_Rd        <= r_Rd;

    o_ALUSrcA   <= r_ALUSrcA;
    o_ALUSrcB   <= r_ALUSrcB;
    o_ALUOp     <= r_ALUOp;
    o_MemRead   <= r_MemRead;
    o_MemWrite  <= r_MemWrite;
    o_MemtoReg  <= r_MemtoReg;
    o_RegWrite  <= r_RegWrite;
    o_Branch    <= r_Branch;
    o_Jump      <= r_Jump;
end rtl;
