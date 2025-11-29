library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity reg_file is
    port (
        i_CLK    : in  std_logic;
        i_RST    : in  std_logic;
        i_WE     : in  std_logic;
        i_WADDR  : in  std_logic_vector(4 downto 0);
        i_WDATA  : in  std_logic_vector(31 downto 0);
        i_RADDR1 : in  std_logic_vector(4 downto 0);
        i_RADDR2 : in  std_logic_vector(4 downto 0);
        o_RDATA1 : out std_logic_vector(31 downto 0);
        o_RDATA2 : out std_logic_vector(31 downto 0)
    );
end entity;

architecture structural of reg_file is
    -- Component declarations
    component dec5to32 is
        port (
            a : in  std_logic_vector(4 downto 0);
            y : out std_logic_vector(31 downto 0)
        );
    end component;

    component regN is
        generic ( N : integer := 32 );
        port (
            i_CLK : in  std_logic;
            i_RST : in  std_logic;
            i_WE  : in  std_logic;
            i_D   : in  std_logic_vector(N-1 downto 0);
            o_Q   : out std_logic_vector(N-1 downto 0)
        );
    end component;

    component mux32to1 is
        port (
            data_in : in  std_logic_vector(32*32-1 downto 0);
            sel     : in  std_logic_vector(4 downto 0);
            y_out   : out std_logic_vector(31 downto 0)
        );
    end component;

    -- 내부 신호
    signal s_dec_out : std_logic_vector(31 downto 0);  -- decorder output (one-hot)
    signal s_regs    : std_logic_vector(32*32-1 downto 0); 
    signal s_we      : std_logic_vector(31 downto 0);  

begin
    -- decorder: write address -> one-hot
    u_dec: dec5to32
        port map (
            a => i_WADDR,
            y => s_dec_out
        );

    
    gen_we: for i in 0 to 31 generate
        s_we(i) <= i_WE and s_dec_out(i) when i /= 0 else '0';
    end generate;

   
    gen_regs: for i in 0 to 31 generate
        u_reg: regN
            generic map ( N => 32 )
            port map (
                i_CLK => i_CLK,
                i_RST => i_RST,
                i_WE  => s_we(i),
                i_D   => i_WDATA,
                o_Q   => s_regs((i+1)*32-1 downto i*32)
            );
    end generate;

   
    u_mux1: mux32to1
        port map (
            data_in => s_regs,
            sel     => i_RADDR1,
            y_out   => o_RDATA1
        );

   
    u_mux2: mux32to1
        port map (
            data_in => s_regs,
            sel     => i_RADDR2,
            y_out   => o_RDATA2
        );

end architecture;