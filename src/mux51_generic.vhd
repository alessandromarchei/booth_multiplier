library IEEE;
use IEEE.std_logic_1164.all; --  libreria IEEE con definizione tipi standard logic
use WORK.constants.all; -- libreria WORK user-defined


--THIS MODULE HAS BEEN DESIGNED AD HOC TO EASILY IMPLEMENT THE MULTIPLIER BASED
--ON THE BOOTH'S ALGORITHM.
--IT BEHAVES AS A NORMAL MUX GENERIC ON N BITS, where it is possible to choose
--among 5 inputs. For each step in the Booth's algorithm, we will choose among
--the following options, depending on the encoder outputs
--      0
--      2^N * A
--      - 2^N * A
--      2^(N + 1) * A
--      -2^(N + 1) * A

entity MUX51_GENERIC is
        Generic (NBIT: integer:= numBit;
		 DELAY_MUX: Time:= tp_mux);
	Port (	A:	In	std_logic_vector(NBIT-1 downto 0);
                B:	In	std_logic_vector(NBIT-1 downto 0);
                C:	In	std_logic_vector(NBIT-1 downto 0);
                D:	In	std_logic_vector(NBIT-1 downto 0);
                E:	In	std_logic_vector(NBIT-1 downto 0);
		SEL:	In	std_logic_vector(2 downto 0);
		Y:	Out	std_logic_vector(NBIT-1 downto 0));
end MUX51_GENERIC;


architecture BEHAVIORAL of MUX51_GENERIC is

begin
	p_mux: process(A,B,C,D,E,SEL)
	begin
          case SEL is
            when "000" => Y <= A after DELAY_MUX;
            when "001" => Y <= B after DELAY_MUX;
            when "010" => Y <= C after DELAY_MUX;
            when "011" => Y <= D after DELAY_MUX;
            when "100" => Y <= E after DELAY_MUX;              

 --only up to 5 inputs can be chosen since this design is ad hoc in order to
 --implement the booth's multiplier. In case the selector is higher than 4, we
 --chose to saturate it and use the first input as "default"
            when others => Y <= A;
          end case;
	end process;

end BEHAVIORAL;





configuration CFG_MUX51_GEN_BEHAVIORAL of MUX51_GENERIC is
	for BEHAVIORAL
	end for;
end CFG_MUX51_GEN_BEHAVIORAL;
