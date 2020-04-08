 
 --**************************************************************
-- Author: Jacobo O. Salvador <jacosalvador@gmail.com>
-- Project:Desarrollo de un módulo experimental de foto conteo 
--para aplicaciones de sensado remoto activo atmosférico
--==============================================================
--File: : fsm_controller.vhd
--Design units:
--  entity : fsm_controller
--  function Finite state Machine to controller Multi-channel scaler logic
--  inputs:
--          clk:clock
--          inp:input pulse
--          clr:clear counter
--          enable: enable counter
--        
--  outputs: 
--          q: output std_logic_vector
----------------------------------------------------------------
--Library/package:
--  ieee.std_logic_1164
----------------------------------------------------------------
--Simulated at Vivado HLx Edition v2018.2 (64 bits)
----------------------------------------------------------------
--Synthesis and verification:
--  Synthesis Software: 
--  Options/script: xx
--  Target technology : xxxxxxxx
--  Testbench : xxxxxx_tb
----------------------------------------------------------------
--Revision history :
-- 2019/01/07 : created Version 1.0
--Comments : Original
--**************************************************************
 
library IEEE;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

entity counter is
	generic(N : natural := 16);
	port(
		inp 				:in std_logic;
		clr 				:in std_logic;
		enable				:in std_logic;
		clk 				:in std_logic;
		q   				:out std_logic_vector(N-1 downto 0)
    );
end counter;
architecture counter_arq of counter is
	--signal count: std_logic_vector(N-1 downto 0);
	signal count: unsigned(N-1 downto 0);
begin
	process(clk, clr)
	begin
	if clr = '1' then
	count <= (others => '0');
	elsif clk'event and clk = '1' then
		if enable='1' then
			if inp = '1'then
			count <= count + 1;
			end if;
		end if;
	end if;
	end process;
q <= std_logic_vector(count);
end counter_arq;
