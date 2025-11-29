library IEEE;
use IEEE.std_logic_1164.all;

entity ex_mem_reg is
    port(
        i_CLK      : in  std_logic;
        i_RST      : in  std_logic;

        -- Datapath
        i_PC        : in std_logic_vector(31 downto 0);
        i_ALURes    : in std_logic_vector(31 downto 0);
        i_WriteData : in std_logic_vector(31 downto 0);
        i_Rd        : in std_logic_vector(4 downto 0);
        i_Zero      : in std_logic;
        i_Sign      : in std_logic;
        i_Cout      : in std_logic;

        -- Control
        i_MemRead   : in std_logic;
        i_MemWrite  : in std_logic;
        i_MemtoReg  : in std_logic_vector(1 downto 0);
        i_RegWrite  : in std_logic;
        i_Branch    : in std_logic;
        i_Jump      : in std_logic_vector(1 downto 0);

        -- Outputs
        o_PC        : out std_logic_vector(31 downto 0);
        o_ALURes    : out std_logic_vector(31 downto 0);
        o_WriteData : out std_logic_vector(31 downto 0);
        o_Rd        : out std_logic_vector(4 downto 0);
        o_Zero      : out std_logic;
        o_Sign      : out std_logic;
        o_Cout      : out std_logic;

        o_MemRead   : out std_logic;
        o_MemWrite  : out std_logic;
        o_MemtoReg  : out std_logic_vector(1 downto 0);
        o_RegWrite  : out std_logic;
        o_Branch    : out std_logic;
        o_Jump      : out std_logic_vector(1 downto 0)
    );
end ex_mem_reg;

architecture rtl of ex_mem_reg is
    signal r_PC        : std_logic_vector(31 downto 0);
    signal r_ALURes    : std_logic_vector(31 downto 0);
    signal r_WriteData : std_logic_vector(31 downto 0);
    signal r_Rd        : std_logic_vector(4 downto 0);
    signal r_Zero      : std_logic;
    signal r_Sign      : std_logic;
    signal r_Cout      : std_logic;

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
                -- Datapath reset
                r_PC        <= (others => '0');
                r_ALURes    <= (others => '0');
                r_WriteData <= (others => '0');
                r_Rd        <= (others => '0');
                r_Zero      <= '0';
                r_Sign      <= '0';
                r_Cout      <= '0';

                -- Control reset
                r_MemRead   <= '0';
                r_MemWrite  <= '0';
                r_MemtoReg  <= (others => '0');
                r_RegWrite  <= '0';
                r_Branch    <= '0';
                r_Jump      <= (others => '0');
            else
                -- Datapath
                r_PC        <= i_PC;
                r_ALURes    <= i_ALURes;
                r_WriteData <= i_WriteData;
                r_Rd        <= i_Rd;
                r_Zero      <= i_Zero;
                r_Sign      <= i_Sign;
                r_Cout      <= i_Cout;

                -- Control
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
    o_ALURes    <= r_ALURes;
    o_WriteData <= r_WriteData;
    o_Rd        <= r_Rd;
    o_Zero      <= r_Zero;
    o_Sign      <= r_Sign;
    o_Cout      <= r_Cout;

    o_MemRead   <= r_MemRead;
    o_MemWrite  <= r_MemWrite;
    o_MemtoReg  <= r_MemtoReg;
    o_RegWrite  <= r_RegWrite;
    o_Branch    <= r_Branch;
    o_Jump      <= r_Jump;
end rtl;
