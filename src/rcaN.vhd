library ieee; 
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use WORK.constants.all;

entity RCAN is 
	generic (NBIT : integer := numBit;
                 DRCAS : 	Time := 0 ns;
	         DRCAC : 	Time := 0 ns);
	Port (	A:	In	std_logic_vector(NBIT-1 downto 0);
		B:	In	std_logic_vector(NBIT-1 downto 0);
		Ci:	In	std_logic;
		S:	Out	std_logic_vector(NBIT-1 downto 0);
		Co:	Out	std_logic);
end RCAN; 

architecture STRUCTURAL of RCAN is

  signal STMP : std_logic_vector(NBIT-1 downto 0);
  signal CTMP : std_logic_vector(NBIT downto 0);

  component FA 
  generic (DFAS : 	Time := 0 ns;
           DFAC : 	Time := 0 ns);
  Port ( A:	In	std_logic;
	 B:	In	std_logic;
	 Ci:	In	std_logic;
	 S:	Out	std_logic;
	 Co:	Out	std_logic);
  end component; 

begin

  CTMP(0) <= Ci;
  S <= STMP;
  Co <= CTMP(NBIT);
  
  ADDER1: for i in 1 to NBIT generate
    FAI : FA 
	  generic map (DFAS => DRCAS, DFAC => DRCAC) 
	  Port Map (A(i-1), B(i-1), CTMP(i-1), STMP(i-1), CTMP(i)); 
  end generate;

end STRUCTURAL;


architecture BEHAVIORAL of RCAN is

signal sum : std_logic_vector(NBIT downto 0);      -- this will contain the sum of
                                                -- A + B on NBITS plus the carry
begin
  
  --the carry out is missing in this case, we need to add it
  sum <= ('0' & A) + ('0' & B) + Ci;
  Co <= sum(NBIT) after DRCAC;
  S <= sum(NBIT-1 downto 0) after DRCAS;
  
end BEHAVIORAL;

configuration CFG_RCAN_STRUCTURAL of RCAN is
  for STRUCTURAL 
    for ADDER1
      for all : FA
        use configuration WORK.CFG_FA_BEHAVIORAL;
      end for;
    end for;
  end for;
end CFG_RCAN_STRUCTURAL;

configuration CFG_RCAN_BEHAVIORAL of RCAN is
  for BEHAVIORAL 
  end for;
end CFG_RCAN_BEHAVIORAL;
