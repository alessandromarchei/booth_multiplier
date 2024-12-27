library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use WORK.constants.all;

entity tb_multiplier is
end tb_multiplier;


architecture TEST of tb_multiplier is

component BOOTHMUL is
        generic(NBIT : integer := numBit);
	Port (	A:	In	std_logic_vector(NBIT-1 downto 0);
                B:	In	std_logic_vector(NBIT-1 downto 0);
		Y:	Out	std_logic_vector(2*NBIT -1 downto 0));
end component;


  constant numBit : integer := 16;    -- :=8  --:=16    

  --  input	 
  signal A_mp_i : std_logic_vector(numBit-1 downto 0) := (others => '0');
  signal B_mp_i : std_logic_vector(numBit-1 downto 0) := (others => '0');
  -- output
  signal Y_mp_i : std_logic_vector(2*numBit-1 downto 0);

begin
  
mul : BOOTHMUL generic MAP(numBit)port map(A_mp_i,B_mp_i,Y_mp_i);

-- PROCESS FOR TESTING TEST - COMLETE CYCLE ---------
  test: process
  begin

    -- cycle for operand A
    NumROW : for i in 10 to 2**(NumBit-1)-1 loop

        -- cycle for operand B
    	NumCOL : for i in 2 to 2**(NumBit-1)-1 loop
	    wait for 10 ns;
	    B_mp_i <= B_mp_i + '1';
	end loop NumCOL ;
        
	A_mp_i <= A_mp_i + '1'; 	
    end loop NumROW ;
    wait;          
  end process test;


end TEST;

configuration BOOTHMUL_TEST of tb_multiplier is
  for TEST
  end for;
end BOOTHMUL_TEST;
