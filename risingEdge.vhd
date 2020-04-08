library ieee;
use ieee.std_logic_1164.all;

entity risingEdge is
	port 
	(
	clk     			: in  std_logic;
  	inputPulse			: in  std_logic;
  	outputPulse			: out std_logic
	);
end risingEdge;

architecture risingEdge_arq of risingEdge is
	signal inputAux0	: std_logic:='0'; --no dejar estados inciertos
	signal inputAux1	: std_logic:='0'; --no dejar estados inciertos

begin

p_rising_edge_detector : process(clk)

begin
	if(rising_edge(clk)) then
		inputAux0<=inputPulse;
		inputAux1<= inputAux0;
  	end if;
end process p_rising_edge_detector;

outputPulse<= not inputAux1 and inputAux0;

end risingEdge_arq;
