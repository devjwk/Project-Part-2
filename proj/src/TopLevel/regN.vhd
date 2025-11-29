-- regN.vhd : N-bit register built from dffg flip-flops

library IEEE;

use IEEE.std_logic_1164.all;

entity regN is

  generic ( N : integer := 32 );

  port (

    i_CLK : in  std_logic;

    i_RST : in  std_logic;                -- async, active-high

    i_WE  : in  std_logic;                -- write enable

    i_D   : in  std_logic_vector(N-1 downto 0);

    o_Q   : out std_logic_vector(N-1 downto 0)

  );

end entity;

architecture structural of regN is

  component dffg

    port(

      i_CLK : in  std_logic;

      i_RST : in  std_logic;

      i_WE  : in  std_logic;

      i_D   : in  std_logic;

      o_Q   : out std_logic

    );

  end component;

  signal s_q : std_logic_vector(N-1 downto 0);

begin

  o_Q <= s_q;

  gen_bits : for i in 0 to N-1 generate

    u_ff : dffg

      port map(

        i_CLK => i_CLK,

        i_RST => i_RST,

        i_WE  => i_WE,

        i_D   => i_D(i),

        o_Q   => s_q(i)

      );

  end generate;

end architecture;