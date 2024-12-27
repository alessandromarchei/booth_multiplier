library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;
use WORK.constants.all; 


--THIS IS THE TOP-LEVEL MODULE OF THE MULTIPLIER BASED ON THE BOOTH'S ALGORITHM
--IT IS A GENERIC NBIT MULTIPLIER, WHERE FOR NBIT IS INTENDED THE PARALLELISM
--OF THE 2 INPUTS A AND B, SO THE OUTPUT WILL BE REPRESENTED ON 2*NBITS.

--INTERNALLY, IT INSTANTIATES THE SUB MODULES :"MUX51_GENERIC", "P4_ADDER"
--"ENCODER",WHICH ARE CONNECTED TOGETHER IN ORDER TO ACCOMPLISH THE ALGORITHM.

--THE ADDER MODULE IS THE ONE WE HAVE DESIGNED ON THE PREVIOUS EXERCISE,
--CORRESPONDING TO THE PENTIUM 4 ADDER BASED ON THE CLA CARRY GENERATOR AND THE
--CARRY SELECT SUM GENERATOR.ITS PARALLELISM IS HOWEVER 2*NBIT SINCE WE NEED TO
--ADD ALL THE PARTIAL SUMS THAT WILL,AT THE END,REPRESENT RESULT ON DOUBLE THE
--INPUT PARALLELISM

--THE MAIN APPROACH TO IMPLEMENT THE MULTIPLIER IS TO FIRSTLY GENERATE
--(HARDWIRED) ALL THE POSSIBLE NBIT SHIFTS OF THE "A" OPERAND, IN ORDER TO INCREASE
--THE SPEED OF THE SYSTEM AND PERFORM THE MULTIPLICATION IN A MORE "PARALLEL"
--WAY, AND ONLY SUM THE PARTIAL PRODUCT ONLY EVERY 2 CYCLES (RATHER THAN IN
--THE CASE OF THE ARRAY MULTIPLIER).
--WE ACCOMPLISH THE SHIFTS BY CREATING ARRAYS OF STD_LOGIC_VECTORS WHERE EACH
--ELEMENT IS THE SHIFTED VERSION OF THE PREVIOUS ELEMENT (A_POS AND A_NEG ARE
--RESPECTIVELY THE VECTOR CONTAININGS THE MULTIPLES OF A).

--IN TOTAL WE WILL USE NBIT/2 - 1 ADDERS, SINCE THE ADDER COMPLEXITY OF THE ALGORITHM IS
--LINEAR : #ADDERS = (NBIT / 2 ) - 1. (IN CASE OF 32 BITS AT THE INPUTS : WE
--WILL HAVE 32/2) - 1 = 15 ADDERS.

--FINALLY, THE MAXIMUM LATENCY OF THE MULTIPLIER IS ABOUT (NBIT/2 - 1) TIMES THE LATENCY
--OF THE ADDER, SINCE IT IS POSSIBLE TO CONSIDER NEGLIGIBLE THE DELAYS OF THE
--MUXES WHEN COMPARED TO THE ADDERS.

entity BOOTHMUL is
        generic(NBIT : integer := numBit);
	Port (	A:	In	std_logic_vector(NBIT-1 downto 0);
                B:	In	std_logic_vector(NBIT-1 downto 0);
		Y:	Out	std_logic_vector(2*NBIT -1 downto 0));
end BOOTHMUL;

architecture BEHAVIORAL of BOOTHMUL is

--declaration of the ENCODER MODULE
component ENCODER is
	Port (	INPUT:	In	std_logic_vector(2 downto 0);
		OUTPUT: Out	std_logic_vector(2 downto 0));
end component;

component P4_ADDER is
  generic (NBIT: integer := 8*numBit;
           NBIT_PER_BLOCK: integer := numBit);
  port (
         A: in std_logic_vector(NBIT-1 downto 0);
         B: in std_logic_vector(NBIT-1 downto 0);
         Cin: in std_logic;
         S: out std_logic_vector(NBIT-1 downto 0);
         Cout: out std_logic);
  
end component;

--declaration of the MUX 5 TO 1 MODULE
component MUX51_GENERIC is
        Generic (NBIT: integer:= numBit;
		 DELAY_MUX: Time:= tp_mux);
	Port (	A:	In	std_logic_vector(NBIT-1 downto 0);
                B:	In	std_logic_vector(NBIT-1 downto 0);
                C:	In	std_logic_vector(NBIT-1 downto 0);
                D:	In	std_logic_vector(NBIT-1 downto 0);
                E:	In	std_logic_vector(NBIT-1 downto 0);
		SEL:	In	std_logic_vector(2 downto 0);
		Y:	Out	std_logic_vector(NBIT-1 downto 0));
end component;

--signals declaration of the hardwired series of shifts
--NOTE : each vector is 2*NBIT bits long since we are shifting NBIT TIMES


type signalVector is array(NBIT-1 downto 0) of std_logic_vector(2*NBIT - 1 downto 0);
type addervec is array((NBIT/2)-1 downto 0) of std_logic_vector(2*NBIT - 1 downto 0);

signal zeros : std_logic_vector(2*NBIT - 1 downto 0) := (others => '0');
signal A_pos : signalVector; --array of std_logic_vectors to store POSITIVE SHIFTS
signal A_neg : signalVector; --array of std_logic_vectors to store NEGATIVE SHIFTS
signal addends : addervec;   --array to store the OUTPUTS OF THE MUXES
signal output_adder : addervec; --array to store the OUTPUTS OF THE ADDERS
signal B_buff : std_logic_vector(NBIT downto 0);--VECTOR CONTAINING B &
                                                --'0',NECESSARY FOR THE FIRST ENCODER

signal selector : std_logic_vector((NBIT/2)*3 -1 downto 0);--SELECTORS OF THE
                                                           --MUXES, THERE ARE 3
                                                           --BITS EVERY 2 OF
                                                           --THE B FACTOR

signal cout_vec: std_logic_vector((NBIT/2) - 1 downto 0);--VECTOR CONTAINING
                                                         --THE USELESS CARRY
                                                         --OUT OF EACH ADDER

begin

B_buff <= B & '0';
A_pos(0) <= (2*NBIT - 1 downto A'length => '0') & A;


--HARDWIRED SHIFTS

--shifting A left by 1 position each time, creating 0,A,2A,4A,8A .. up until (2^(NBIT-1))*A
shiftpos : for i in 1 to NBIT-1 generate
  A_pos(i) <= to_stdlogicvector(to_bitvector(A_pos(i-1)) sll 1);
end generate;

--shifting A left by 1 position each time, creating 0,-A,-2A,-4A,-8A .. up
--until -(2^(NBIT-1))*A
shiftneg : for i in 0 to NBIT-1 generate
  A_neg(i) <= std_logic_vector(-signed(A_pos(i)));
end generate;


--INSTANTIATION OF THE ELEMENTS AND ADDING UP
           
--SELECTORS OF THE MUXES
 
selectors : for i in 1 to NBIT/2 generate
  begin
    enc : encoder port map(B_buff((2*i) downto (2*(i-1))), selector((3*i)-1 downto (3*(i-1))));
  end generate;


--ADDENDS OF THE ADDERS
  --first instance of the multiplexers at the top, and the output is at addends(0)
mux0 : mux51_generic generic map(2*NBIT) port map(zeros,A_pos(0),A_neg(0),A_pos(1),A_neg(1),selector(2 downto 0),addends(0));

  --instance of the first output of the sum, which will then be iterated
add0 : P4_ADDER generic map(2*NBIT,4) port map(addends(0),addends(1),'0',output_adder(0),cout_vec(0));

mult : for i in 1 to (NBIT/2)-1 generate
  begin
    mux_i : mux51_generic generic map(2*NBIT) port map(zeros,A_pos(2*i),A_neg(2*i),A_pos((2*i)+1),A_neg((2*i)+1),selector(3*(i+1)-1 downto 3*i),addends(i));
  end generate;

add : for i in 1 to (NBIT/2)-2 generate
  begin
    add_i : P4_ADDER generic map(2*NBIT,4) port map(output_adder(i-1),addends(i+1),'0',output_adder(i),cout_vec(i));
  end generate;

  
--IN ORDER TO AVOID THE CREATION OF ANOTHER TYPE, WE USED THE OUTPUT_ADDER
--ARRAY TO STORE THE OUTPUTS OF THE ADDERS, BUT THERE IS 1 UNUSED VECTOR (THE
--LAST ONE) SINCE THE ADDERS ARE 1 LESS THAN THE MUXES, SO WE NEED TO EXTRACT
--THE 2ND LAST ELEMENT TO PRODUCE THE OUTPUT RESULT (THE FINAL PRODUCT)
  
Y <= output_adder((NBIT/2)-2);  


end BEHAVIORAL;
