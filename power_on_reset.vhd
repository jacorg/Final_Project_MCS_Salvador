--**************************************************************
-- Author: Jacobo O. Salvador <jacosalvador@gmail.com>
-- Project:Desarrollo de un módulo experimental de foto conteo 
--para aplicaciones de sensado remoto activo atmosférico
--==============================================================
--File: : power_on_reset.vhd
--Design units:
--  entity : fsm_memory
--  function Finite state Machine to controller data memory access
--  inputs:
--          clk:
--  outputs: 
--          power_on_reset:
--
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
-- 01/2020 : created - Version 1.0 
--Comments : Original
--**************************************************************
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity power_on_reset is
  generic(
    max_cons_delay:          natural:=150;
    cons_delay_pulse:        natural:=20        
  );
  port(
--  inputs:
    clk:                    in std_logic;   
--  outputs: 
    power_on_reset:         out std_logic
  );
  end  power_on_reset;

architecture power_on_reset_arq of power_on_reset is
begin

  por_procedure: process (clk) is  
 
    variable delay_pulse: natural range 0 to max_cons_delay:=0;              --memory index position
              
    begin
      delay_pulse:=delay_pulse+1;
      if rising_edge(clk) then
        if delay_pulse<cons_delay_pulse then
          power_on_reset<='1';
        else
          delay_pulse:=100;
          power_on_reset<='0';
        end if;
      end if;  
    end process;  
end power_on_reset_arq;



