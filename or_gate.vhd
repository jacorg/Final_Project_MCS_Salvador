library ieee;
use ieee.std_logic_1164.all;
 
entity or_gate is
  port (
    in_1    : in  std_logic;
    in_2    : in  std_logic;
    or_o  : out std_logic
    );
end or_gate;
 
architecture or_gate_arq of or_gate is
  signal or_gate : std_logic;
begin
  or_gate   <= in_1 or in_2;
  or_o <= or_gate;
end or_gate_arq;

