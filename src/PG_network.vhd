library IEEE;
use IEEE.std_logic_1164.all;
use WORK.constants.all;

--THIS MODULE HAS BEEN DESIGNED IN ORDER TO DESIGN THE CLA-SPARSE TREE CARRY
--GENERATOR (ONE OF THE SUB-BLOCKS OF THE P4 ADDER).

--THE PG_NETWORK IS THE FIRST LAYER OF THE SPARSE TREE. IT RECIEVES A AND B AS
--INPUTS AND SYNTHESIZES GENERATE AND PROPAGATE TERMS (p and g) ACCORDING TO
--THE FOLLOWING FORMULAS

-- p = a xor b
-- g = a and b

entity PG_network is
  generic (NBIT : integer := numBit);
  port(
    A: in std_logic_vector(NBIT-1 downto 0);
    B: in std_logic_vector(NBIT-1 downto 0);
    Pout: out std_logic_vector(NBIT-1 downto 0);
    Gout: out std_logic_vector(NBIT-1 downto 0));
end PG_network;

architecture BEHAVIORAL of PG_network is

begin

  Pout <= (A xor B); --Pout_i = p_i = A(i) xor B(i) --> propagate
  Gout <= (A and B); --Gout_i = g_i = A(i) and B(i) --> generate

end BEHAVIORAL;
