library IEEE;
use ieee.std_logic_1164.all;
entity demux4 is
		generic 
		( 
		N_data    : natural:=2
		);
		port(
  		F     	: in  std_logic;
  		A       : out std_logic;
		B       : out std_logic;
		C       : out std_logic;
		D       : out std_logic;
		sel     : in std_logic_vector(N_data-1 downto 0)
		);
end demux4;


architecture demux4_arq of demux4 is
  -- declarative part: empty
begin
	process (F,sel) is
	begin
		if (sel="00") then
			A <= F;
			B <= '0';
			C <= '0';
			D <= '0';

 		elsif (sel="01") then
 			A <= '0';
			B <= F;
			C <= '0';
			D <= '0';

		elsif (sel="10") then
			A <= '0';
			B <= '0';
			C <= F;
			D <= '0';
		elsif (sel="11") then
			A <= '0';
			B <= '0';
			C <= '0';
			D <= F;
		else
			A <= '0';
			B <= '0';
			C <= '0';
			D <= '0';
		end if;
	end process;
end;


