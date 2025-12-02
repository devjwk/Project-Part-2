-------------------------------------------------------------------------
-- ID/EX Pipeline Register
-- Moves decoded control signals and operand data to the EX stage.
-- Flush clears only control signals (bubble), data is don’t-care.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

entity ID_EX_Reg is
    port(
        i_CLK      : in  std_logic;
        i_RST      : in  std_logic;
        i_Flush    : in  std_logic;   -- branch/jump flush

        -- Control Signals
        i_RegWrite : in  std_logic;
        i_MemtoReg : in  std_logic_vector(1 downto 0);
        i_MemRead  : in  std_logic;
        i_MemWrite : in  std_logic;
        i_ALUSrcA  : in  std_logic;
        i_ALUSrcB  : in  std_logic;
        i_ALUOp    : in  std_logic_vector(1 downto 0);
        i_Branch   : in  std_logic;
        i_Jump     : in  std_logic_vector(1 downto 0);
        i_Halt     : in  std_logic;   -- must reach WB before becoming final Halt!

        -- Data Signals
        i_PC        : in std_logic_vector(31 downto 0);
        i_ReadData1 : in std_logic_vector(31 downto 0);
        i_ReadData2 : in std_logic_vector(31 downto 0);
        i_Imm       : in std_logic_vector(31 downto 0);
        i_Funct3    : in std_logic_vector(2 downto 0);
        i_Funct7    : in std_logic_vector(6 downto 0);
        i_Rd        : in std_logic_vector(4 downto 0);
        i_Rs1       : in std_logic_vector(4 downto 0);
        i_Rs2       : in std_logic_vector(4 downto 0);

        -- Outputs
        o_RegWrite : out  std_logic;
        o_MemtoReg : out  std_logic_vector(1 downto 0);
        o_MemRead  : out  std_logic;
        o_MemWrite : out  std_logic;
        o_ALUSrcA  : out  std_logic;
        o_ALUSrcB  : out  std_logic;
        o_ALUOp    : out  std_logic_vector(1 downto 0);
        o_Branch   : out  std_logic;
        o_Jump     : out  std_logic_vector(1 downto 0);
        o_Halt     : out  std_logic;

        o_PC        : out std_logic_vector(31 downto 0);
        o_ReadData1 : out std_logic_vector(31 downto 0);
        o_ReadData2 : out std_logic_vector(31 downto 0);
        o_Imm       : out std_logic_vector(31 downto 0);
        o_Funct3    : out std_logic_vector(2 downto 0);
        o_Funct7    : out std_logic_vector(6 downto 0);
        o_Rd        : out std_logic_vector(4 downto 0);
        o_Rs1       : out std_logic_vector(4 downto 0);
        o_Rs2       : out std_logic_vector(4 downto 0)
    );
end ID_EX_Reg;

architecture behavior of ID_EX_Reg is
begin
    process(i_CLK, i_RST)
    begin
        if (i_RST = '1') then
            -- Reset → turn EX stage into NOP
            o_RegWrite <= '0';
            o_MemtoReg <= "00";
            o_MemRead  <= '0';
            o_MemWrite <= '0';
            o_ALUSrcA  <= '0';
            o_ALUSrcB  <= '0';
            o_ALUOp    <= "00";
            o_Branch   <= '0';
            o_Jump     <= "00";
            o_Halt     <= '0';

            o_PC        <= (others => '0');
            o_ReadData1 <= (others => '0');
            o_ReadData2 <= (others => '0');
            o_Imm       <= (others => '0');
            o_Funct3    <= (others => '0');
            o_Funct7    <= (others => '0');
            o_Rd        <= (others => '0');
            o_Rs1       <= (others => '0');
            o_Rs2       <= (others => '0');

        elsif rising_edge(i_CLK) then

            if (i_Flush = '1') then
                -------------------------------------------------------------
                -- Flush only control signals → bubble inserted
                -------------------------------------------------------------
                o_RegWrite <= '0';
                o_MemtoReg <= "00";
                o_MemRead  <= '0';
                o_MemWrite <= '0';
                o_ALUSrcA  <= '0';
                o_ALUSrcB  <= '0';
                o_ALUOp    <= "00";
                o_Branch   <= '0';
                o_Jump     <= "00";
                o_Halt     <= '0';  -- important: no early halt!

                -- Data is don't-care
            else
                -------------------------------------------------------------
                -- Normal operation
                -------------------------------------------------------------
                o_RegWrite <= i_RegWrite;
                o_MemtoReg <= i_MemtoReg;
                o_MemRead  <= i_MemRead;
                o_MemWrite <= i_MemWrite;
                o_ALUSrcA  <= i_ALUSrcA;
                o_ALUSrcB  <= i_ALUSrcB;
                o_ALUOp    <= i_ALUOp;
                o_Branch   <= i_Branch;
                o_Jump     <= i_Jump;
                o_Halt     <= i_Halt;

                o_PC        <= i_PC;
                o_ReadData1 <= i_ReadData1;
                o_ReadData2 <= i_ReadData2;
                o_Imm       <= i_Imm;
                o_Funct3    <= i_Funct3;
                o_Funct7    <= i_Funct7;
                o_Rd        <= i_Rd;
                o_Rs1       <= i_Rs1;
                o_Rs2       <= i_Rs2;
            end if;
        end if;
    end process;
end behavior;