library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.math_real.all;
use WORK.constants.all;

--THE CLA-SPARSE TREE CARRY GENERATOR IS ONE OF THE SUB-BLOCKS OF THE PENTIUM 4
--ADDER

--IT RECIEVES A, B (NBIT) AND A CARRY IN AS INPUTS AND IT GENERATES A CARRY OUT
--EVERY NBIT_PER_BLOCK. OUTPUTS OF THE CARRY GENERATOR WILL FEED THE SUM
--GENERATOR (THE 2nd SUB-BLOCK OF THE P4 ADDER).

--THE CARRY GENERATOR IS MADE UP OF A PG NETWORK, SOME G BLOCKS THAT GENERATE THE
--FINAL CARRIES AND SOME PG BLOCKS, WHICH ARE NEEDED TO PRODUCE INTERMEDIATE RESULTS.
--IN THE FOLLOWING, ALL THESE BLOCKS ARE CONNECTED TOGETHER IN SUCH A WAY TO IMPLEMENT
--THE ALGORITHM THE SPARSE TREE IS BASED ON.


entity CARRY_GENERATOR is
  generic (NBIT : integer := numBit;
           NBIT_PER_BLOCK : integer := numBit); --NBIT/NBIT_PER_BLOCK = NBLOCKS
  port (
      A: in std_logic_vector (NBIT-1 downto 0); 
      B: in std_logic_vector (NBIT-1 downto 0);
      Cin: in std_logic; --Cin = c0
      Co: out std_logic_vector (NBIT/NBIT_PER_BLOCK downto 0)); 
end CARRY_GENERATOR;


architecture STRUCTURAL of CARRY_GENERATOR is

  --The sprse tree is made up of log2(NBIT) layers (or rows)
  --The algorithm is split into two parts:
  --  1) the first one will be implemented from row(0) to row(ENDPART1)
  --     --> ENDPART1 is equal to log2(NBIT_PER_BLOCK)+1 ;
  --  2) the second part will be implemented from row(ENDPART1 + 1) to the end ( row(ENDPART2) )
  
  constant ENDPART1: integer := integer(log2(real(NBIT_PER_BLOCK))) +1 ; 
  constant ENDPART2: integer := integer(log2(real(NBIT))) ; 
                                                            
  --General propagate (Pi:j) and general generate (Gi:j) signals
  type SignalVector is array (NBIT downto 0) of std_logic_vector(NBIT downto 0); 

  signal P,G : SignalVector;

  --Useful signals for the PG_network port map
  signal p_signal, g_signal: std_logic_vector (NBIT-1 downto 0);

  --Component declaration
  component PG_NETWORK
     generic (NBIT : integer := numBit);
     port(
          A: in std_logic_vector(NBIT-1 downto 0);
          B: in std_logic_vector(NBIT-1 downto 0);
          Pout: out std_logic_vector(NBIT-1 downto 0);  --Pout_i = p_i --> propagate
          Gout: out std_logic_vector(NBIT-1 downto 0)); --Gout_i = g_i --> generate 
  end component;

  component G_BLOCK
     port (
         A: in std_logic_vector(1 downto 0);           --A(1)=Pi:k      A(0)=Gi:k
         B: in std_logic;                              --B=Gk-1:j
         Gout: out std_logic);                         --Gout=Gi:j
  end component;

  component PG_BLOCK
     port (
        A: in std_logic_vector(1 downto 0);           --A(1)=Pi:k       A(0)=Gi:k
        B: in std_logic_vector(1 downto 0);           --B(1)=Pk-1:j     B(0)=Gk-1;j
        PGout: out std_logic_vector (1 downto 0));    --PGout(1)=Pi:j   PGout(0)=Gi:j
  end component;
  
begin

  --By definition P0:0 = p0 = 0
  P(0)(0) <= '0';

  --First block of the PG_NETWORK:
  --since  we have to take into account also Cin, we compute the output of the block separately
  G(1)(0) <= ((A(0) xor B(0)) and Cin) or (A(0) and B(0)); --G1:0 = G1:1 + P1:1 * G0:0 = g1 + p1 * Cin
  g_signal(0) <= G(1)(0); 
  
  --Assignment of generated carries
  G(0)(0) <= Cin; --Cin = c0 = g0 = G0:0 = Co(0)
  Co(0) <= G(0)(0);
  
  carrygen: for i in 1 to NBIT/NBIT_PER_BLOCK generate
               Co(i) <= G(i*NBIT_PER_BLOCK)(0);
  end generate carrygen;
  

  --1st PART OF THE ALGORITHM:
  
  part1 : for i in 0 to ENDPART1 generate

           --Layer 0 is the PG network
    
           row0 : if i = 0 generate

             --j starts from 1, since the case j=0 for the PG_NETWORK has been
             --computed just before 
             columns0 : for j in 1 to NBIT-1 generate
                  P(j+1)(j+1) <= p_signal(j);
                  G(j+1)(j+1) <= g_signal(j);
              end generate columns0;
                
              pgnetwork: PG_NETWORK
                 generic map(NBIT)
                 port map (A=>A, B=>B, Pout=>p_signal, Gout=>g_signal);
              
           end generate row0;
           

           --Other rows of the first part are made up of PG_BLOCKs and G_BLOCKs
           
           rows1 : if i > 0 generate
             
           --In the first part of the algorithm, the total number of blocks in each layer is equal to NBIT divided
           --by 2^i, where i is the index of the layer
           --e.g. layer1 --> #blocks = NBIT/2
           --     layer2 --> #blocks = NBIT/4
             
           --In each layer the rightmost block is a G_BLOCK, while all the
           --other blocks are PG_BLOCKs

           --G_BLOCK:
           --        Each input of a G_BLOCK has two indexes:
           --        leftmost inputs are Gi:k and Pi:k --> let's call
           --                   i --> a
           --                   k --> b
           --        rightmost input is Gk-1:j --> let's call
           --                   k-1 --> c
           --                   j   --> d
           --        a, b, c, d are related as follows:
           --        1) In a G_BLOCK d is always equal to 0
           --        2) The distance between a and b is related to the index of
           --           the layer (i=layer index). In particular, dist = (a-b) = 2^(i-1) - 1
           --        3) Since d = 0, the distance between c and d is equal to
           --           dist+1. Then, c = d + (dist+1) = 2^(i-1)
           --        4) b = c+1 = 2^(i-1) + 1
           --        5) a = b + dist = 2 * 2^(i-1) = 2^i

           --PG_BLOCK:
           --       Using the previous notation, we can describe the indexes of
           --       a PG_BLOCK as follows:
           --       1) In a PG_BLOCK a is related to the index of both the layer(i=layer index) and
           --          the block (j=block index). In particular, a = j * 2^i
           --       2) b = a - dist = j * 2^i - 2^(i-1) + 1
           --       3) c = b-1 = j * 2^i - 2^(i-1)
           --       4) d = c - dist = j * 2^i - 2 * 2^(i-1) + 1 = (j-1) * 2^i +1
             
               columns1 : for j in 1 to NBIT/(2**i) generate

                  firstblock1 : if j = 1 generate
                     gblock1 : G_BLOCK
                        port map(A(0)=>G(2**i)(2**(i-1)+1), A(1)=>P(2**i)(2**(i-1)+1), B=>G(2**(i-1))(0), Gout=>G(2**i)(0));
                  end generate firstblock1;

                  otherblocks1 : if j > 1 generate
                     pgblock1 : PG_BLOCK
                         port map (A(0)=>G(j* 2**i)(j* 2**i-2**(i-1)+1), A(1)=>P(j* 2**i)(j* 2**i-2**(i-1)+1), B(0)=>G(j* 2**i-2**(i-1))((j-1)* 2**i+1), B(1)=>P(j* 2**i-2**(i-1))((j-1)* 2**i+1), PGout(0)=>G(j* 2**i)((j-1)* 2**i+1) , PGout(1)=>P(j* 2**i)((j-1)* 2**i+1) );
                  end generate otherblocks1;

              end generate columns1;
                 
          end generate rows1;
           
  end generate part1;
 

  --2nd PART OF THE ALGORITHM:
  
  part2 : for i in  ENDPART1+1 to ENDPART2 generate
    
       --In the second part of the algorithm, let's call "j" the index of blocks in the PG_network,
       --hence j takes values from 1 to NBIT
    
       index: for j in 1 to NBIT generate
         
	     --In the i-th layer, we generate all the carries c_k, with k
             --greater than 2^(i-1) and less than or equal to 2^i
             --                   2^(i-1) < k ≤ 2^i
             --
             --Recall that we have to generate a new carry every NBIT_PER_BLOCK, namely k
             --is a multiple of NBIT_PER_BLOCK (k = j*NBIT_PER_BLOCK)
             --e.g layer4 (i=4) and NBIT_PER_BLOCK = 4 --> we generate c_12 and c_16
             --    layer5 (i=5) and NBIT_PER_BLOCK = 4 --> we generate c_20, c_24,
             --                                                        c_28, c_32
             --
             --Therefore, every time index j fulfills all these requirements a G_BLOCK
             --must be generated.
             --Using the previous notation, we can describe the indexes of inputs
             --and output of a G_BLOCK as follows:
             --  1) d = 0
             --  2) c = d + (dist+1) = 2^(i-1)
             --  3) b = c + 1 = 1 + 2^(i-1)
             --  4) a = j*NBIT_PER_BLOCK
             
      	     is_gblock: if ( (j*NBIT_PER_BLOCK <= 2**i) and (j*NBIT_PER_BLOCK > 2**(i-1)) ) generate
	           gblock2: G_BLOCK
                       port map (A(0)=>G(j*NBIT_PER_BLOCK)(1+2**(i-1)), A(1)=>P(j*NBIT_PER_BLOCK)(1+2**(i-1)), B=>G(2**(i-1))(0), Gout=>G(j*NBIT_PER_BLOCK)(0));
	     end generate is_gblock;

             --Let's call n an index that assumes values from 2 to
             --NBIT/(2^i). In order to generate a PG_BLOCK in this part of the
             --algorithm, some conditions related to both n and j have to
             --be met.
             
             --Exploiting again the 1st part of the algorithm, we should
             --generate a PG_BLOCK for each value of n, with the following indexes: 
             -- a = n * 2^i
             -- b = a - dist = n * 2^i - 2^(i-1) + 1
             -- c = b-1 = n * 2^i - 2^(i-1)
             -- d = c - dist = n * 2^i - 2 * 2^(i-1) + 1 = (n-1) * 2^i +1

             --Moreover, in the 2nd part of the algorithm we have to generate
             --also some "extra" PG_BLOCKs. In particular, we need a PG_BLOCK for
             --every j that is greater than (a - NBIT_PER_BLOCK*2^(i-ENDPART1))
             --and less than or equal to a (with a = n*2^i, as written above).
             --These "extra" PG_BLOCKs have the same b, c, d expected by the 1st
             --part of the algorithm, and a equal to the value of j that fulfills
             --the requirements so that the PG_BLOCK has to be generated.

             n_pgblock:  for n in 2 to NBIT/(2**i) generate       
                   is_pgblock: if ((j > (n*2**i)-(NBIT_PER_BLOCK * 2**(i-ENDPART1))) and (j <= n*2**i ) and (j mod NBIT_PER_BLOCK = 0) ) generate
                       pgblock2: PG_BLOCK
                           port map (A(0)=>G(j)(n*2**i-2**(i-1)+1), A(1)=>P(j)(n*2**i-2**(i-1)+1), B(0)=>G(n*2**i-2**(i-1))((n-1)*2**i+1), B(1)=>P(n*2**i-2**(i-1))((n-1)*2**i+1), PGout(0)=>G(j)((n-1)*2**i+1), PGout(1)=>P(j)((n-1)*2**i+1));
                   end generate is_pgblock;
             end generate n_pgblock;
            
      end generate index;

  end generate part2; 
  
end STRUCTURAL;
