library IEEE;
use IEEE.std_logic_1164.all; --  libreria IEEE con definizione tipi standard logic
use WORK.constants.all; -- libreria WORK user-defined

entity MUX21_GENERIC is
        Generic (NBIT: integer:= numBit;
		 DELAY_MUX: Time:= tp_mux);
	Port (	A:	In	std_logic_vector(NBIT-1 downto 0) ;
		B:	In	std_logic_vector(NBIT-1 downto 0);
		SEL:	In	std_logic;
		Y:	Out	std_logic_vector(NBIT-1 downto 0));
end MUX21_GENERIC;


architecture BEHAVIORAL of MUX21_GENERIC is

begin
	pmux: process(A,B,SEL)
	begin
                 if SEL = '0' then
			Y <= A after DELAY_MUX;        --REGARDLESS IF 'A' IS A BIT OR A
                                                       --VECTOR, THE PROCESS IS STILL CORRECT
                                                       --SINCE BOTH OPERANDS 'A','B' ARE
                                                       --COHERENT WITH THE SIZE OF Y
		else
			Y <= B after DELAY_MUX;
		end if;
            
	end process;

end BEHAVIORAL;


architecture STRUCTURAL of MUX21_GENERIC is

	signal Y1: std_logic_vector(NBIT-1 downto 0);           --vector for
                                                                --the first signal
	signal Y2: std_logic_vector(NBIT-1 downto 0);           --vector for
                                                                --the second signal
	signal SA: std_logic;                                   
                                                                --the negated signal

	component ND2
	port (	A:	In	std_logic;
		B:	In	std_logic;
		Y:	Out	std_logic);
	end component;
	
	component IV
	port (	A:	In	std_logic;
		Y:	Out	std_logic);
	end component;

begin

         UIV: IV                                  --INVERSION OF THE SELECTOR, DO
         port map (SEL, SA);                      --NOT CHANGE THE SIZE, BECAUSE
                                                  --IT IS ALWAYS 1 BIT WIDE
        
        FOR1: for i in 0 to NBIT-1 generate           --NAND BETWEEN 'A' AND !SELECTOR
          for all: ND2 use configuration WORK.CFG_ND2_ARCH2;
        begin
        U1: ND2 port map (A(i), SA, Y1(i));
        end generate;

        FOR2: for i in 0 to NBIT-1 generate           --NAND BETWEEN 'B' AND SELECTOR
           for all: ND2 use configuration WORK.CFG_ND2_ARCH2;
        begin
        U2: ND2 port map (B(i), SEL, Y2(i));
        end generate;

	FOR3: for i in 0 to NBIT-1 generate
           for all: ND2 use configuration WORK.CFG_ND2_ARCH2;
        begin
        U3: ND2 port map (Y1(i),Y2(i),Y(i));       --NAND BETWEEN SELECTED OUTPUTS
        end generate;


end STRUCTURAL;


configuration CFG_MUX21_GEN_BEHAVIORAL of MUX21_GENERIC is
	for BEHAVIORAL
	end for;
end CFG_MUX21_GEN_BEHAVIORAL;



configuration CFG_MUX21_GEN_STRUCTURAL of MUX21_GENERIC is
	for STRUCTURAL
		for all : IV
			use configuration WORK.CFG_IV_BEHAVIORAL;
		end for;
	end for;
end CFG_MUX21_GEN_STRUCTURAL;
