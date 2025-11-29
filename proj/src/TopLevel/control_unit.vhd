-----------------------------------------------------------------------------
-- Generates all necessary control signals for JALR, AUIPC, and all Branches.
-----------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity control_unit is
    port(
        i_Opcode   : in  std_logic_vector(6 downto 0);
        
        -- Control Signals
        o_ALUSrc   : out std_logic;                    -- ALU Input B: 0=Reg, 1=Imm
        o_MemtoReg : out std_logic_vector(1 downto 0); -- 00=ALU, 01=Mem, 10=PC+4, 11=Imm
        o_RegWrite : out std_logic;
        o_MemRead  : out std_logic;
        o_MemWrite : out std_logic;
        o_Branch   : out std_logic;                    -- 1=Conditional Branch Instruction
        o_Jump     : out std_logic_vector(1 downto 0); -- 00=No, 01=JAL, 10=JALR <--- 2-bit Jump
        o_ALUOp    : out std_logic_vector(1 downto 0); -- 00=Add, 01=Sub, 10=Funct
        o_ImmType  : out std_logic_vector(2 downto 0); -- I/S/B/J/U type
        o_AUIPCSrc : out std_logic                     -- 0=rs1, 1=PC (For ALU Input A MUX) <--- New Control Signal
    );
end control_unit;

architecture behavior of control_unit is
begin
    process(i_Opcode)
    begin
        -- [Default Values]
        o_ALUSrc   <= '0';
        o_MemtoReg <= "00"; 
        o_RegWrite <= '0';
        o_MemRead  <= '0';
        o_MemWrite <= '0';
        o_Branch   <= '0';
        o_Jump     <= "00";
        o_ALUOp    <= "00";
        o_ImmType  <= "000"; 
        o_AUIPCSrc <= '0';

        case i_Opcode is
            -- [R-Type] (add, sub, sll, etc.)
            when "0110011" =>
                o_RegWrite <= '1';
                o_ALUOp    <= "10";

            -- [I-Type ALU] (addi, slti, etc.)
            when "0010011" =>
                o_ALUSrc   <= '1';
                o_RegWrite <= '1';
                o_ALUOp    <= "10";
                o_ImmType  <= "000";

            -- [Load] (lw, lb, lh...)
            when "0000011" =>
                o_ALUSrc   <= '1';
                o_MemtoReg <= "01";
                o_RegWrite <= '1';
                o_MemRead  <= '1';
                o_ALUOp    <= "00";
                o_ImmType  <= "000";

            -- [Store] (sw, sb, sh)
            when "0100011" =>
                o_ALUSrc   <= '1';
                o_MemWrite <= '1';
                o_ALUOp    <= "00";
                o_ImmType  <= "001";

            -- [Branch] (beq, bne...)
            when "1100011" =>
                o_ALUSrc   <= '0';
                o_Branch   <= '1';
                o_ALUOp    <= "01"; -- Sub for comparison
                o_ImmType  <= "010";

            -- [JAL]
            when "1101111" =>
                o_Jump     <= "01"; -- JAL Mode
                o_RegWrite <= '1';
                o_MemtoReg <= "10"; -- Store PC+4
                o_ImmType  <= "011";

            -- [JALR] (Requires rs1 + Imm path in Fetch)
            when "1100111" =>
                o_Jump     <= "10"; -- JALR Mode
                o_ALUSrc   <= '1';  -- ALU = rs1 + Imm
                o_RegWrite <= '1';
                o_MemtoReg <= "10"; -- Store PC+4
                o_ALUOp    <= "00"; -- Add
                o_ImmType  <= "000"; -- I-type

            -- [LUI]
            when "0110111" =>
                o_RegWrite <= '1';
                o_MemtoReg <= "11"; -- Load Imm
                o_ImmType  <= "100"; -- U-type

            -- [AUIPC] (Requires PC path to ALU Input A)
            when "0010111" =>
                o_AUIPCSrc <= '1';  -- ALU A = PC
                o_ALUSrc   <= '1';  -- ALU B = Imm
                o_RegWrite <= '1';
                o_MemtoReg <= "00"; -- ALU Result
                o_ALUOp    <= "00"; -- Add
                o_ImmType  <= "100"; -- U-type

            -- [WFI / HALT] (Optional, as required by some frameworks)
            when "0000000" => -- Assuming WFI is Opcode 0
                o_RegWrite <= '0';
                o_MemWrite <= '0';
                o_MemRead  <= '0';
                -- The Halt flag is handled in RISCV_Processor.vhd
                
            when others => null;
        end case;
    end process;
end behavior;