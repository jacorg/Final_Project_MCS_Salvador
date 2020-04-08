library IEEE;
use IEEE.std_logic_1164.all;

entity test is
	generic(
		N_trigger: 		natural := 400000;
		N_signal:  		natural :=4;
		N_aux:			natural :=30
	);
	port(
		clk_i: 			in  std_logic;
		trigger_test: 	out std_logic;
		signal_test: 	out std_logic
	);
end;

architecture test_arq of test is

signal trigger_test_s: std_logic;
signal signal_test_s:  std_logic;

begin

inst_trigger:	process(clk_i)
	variable count: integer range 0 to N_trigger+N_aux := 0;
	variable count_aux: integer range 0 to N_aux := 0;
begin
	if rising_edge(clk_i) then
		count := count + 1;
		if count >= N_trigger then
			count_aux:=count_aux+1;
			trigger_test_s <= '1';
			if count_aux=N_aux-1 then
				count:=0;
				count_aux:=0;
			end if;

		else
			trigger_test_s <= '0';
		end if;
	end if;
end process;	


--inst_trigger:	process(clk_i)
--	variable count_t: integer range 0 to N_trigger:= 0;
--
--	begin
--		if rising_edge(clk_i) then
--			count_t := count_t + 1;
--
--			if count_t = N_trigger then
--				count_t:=0;
--				trigger_test_s <= '1';	
--			else
--				trigger_test_s <= '0';
--			end if;
--		end if;
--	end process;

	
	
inst_signal:	process(clk_i)
	variable count: integer range 0 to N_signal := 0;
	begin
		if rising_edge(clk_i) then
			count := count + 1;
			if count = N_signal then
				count := 0;
				signal_test_s <= '1';
			else
				signal_test_s <= '0';
			end if;
		end if;
	end process;
			


	trigger_test <= trigger_test_s;
    signal_test <= signal_test_s;
end;