--**************************************************************
-- Author: Jacobo O. Salvador <jacosalvador@gmail.com>
-- Project:Desarrollo de un módulo experimental de foto conteo 
--para aplicaciones de sensado remoto activo atmosférico
--==============================================================
--File: : power_on_reset.vhd
--Design units:
--  entity : accumulator memory
--  function accumulator data from counter and register in memory
--  inputs:
--          clk:                  clock frequency
--          data_from_mem:        data bus from memory to be accumulated
--          bank_cnt_a_and_b:     represents first two counters
---         bank_cnt_c_and_d:     represents second two counters
--          fst_cnt:              signal represents first counting non accumulated
--          sel_bank:             select which bank is accumulated
--  outputs: 
--          data_to_mem:          operation result after adding and ccumulation
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
-- 04/202  : Modified- add overflow condition. add results saturate at 0xFFFF-FFFF
--**************************************************************
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity acc_mem is
  port(
--  inputs:
    clk:                    in std_logic;
    data_from_mem:          in std_logic_vector(31 downto 0);
    bank_cnt_a_and_b:       in std_logic_vector(31 downto 0);
    bank_cnt_c_and_d:       in std_logic_vector(31 downto 0);
    fst_cnt:                in std_logic;        
    sel_bank:               in std_logic;
--  outputs: 
    data_to_mem:            out std_logic_vector(31 downto 0)
  );
  end acc_mem;

architecture acc_mem_arq of acc_mem is

signal result_a : std_logic_vector(16 downto 0);
signal result_b : std_logic_vector(16 downto 0); 
signal sum_aux  : std_logic_vector(31 downto 0); 

begin
--https://stackoverflow.com/questions/40247478/full-adder-3-bit-std-logic-vector  
acc_mem_procedure: process (clk,sum_aux) is  

  --variable sum_aux: unsigned(31 downto 0);    
    
  begin   
    if rising_edge(clk) then
        if fst_cnt='1' and sel_bank='0'then
            sum_aux<=bank_cnt_a_and_b;
        elsif fst_cnt='1' and sel_bank='1'then
            sum_aux<=bank_cnt_c_and_d;
        elsif fst_cnt='0' and sel_bank='0'then           
            result_a<=std_logic_vector(unsigned('0' & data_from_mem(15 downto 0))+unsigned('0' & bank_cnt_a_and_b(15 downto 0)));
            result_b<=std_logic_vector(unsigned('0' & data_from_mem(31 downto 16))+unsigned('0' & bank_cnt_a_and_b(31 downto 16)));
            
            if result_a(16)='0' then
              sum_aux(15 downto 0)<=result_a(15 downto 0);
            else
              sum_aux(15 downto 0)<=x"FFFF";
            end if;

            if result_b(16)='0' then
              sum_aux(31 downto 16)<=result_b(15 downto 0);
            else
              sum_aux(31 downto 16)<=x"FFFF";
            end if; 


        else   -- condition fst_cnt='0' and sel_bank='1'then   
            --sum_aux:=unsigned(data_from_mem)+unsigned(bank_cnt_c_and_d);

            result_a<=std_logic_vector(unsigned('0' & data_from_mem(15 downto 0))+unsigned('0' & bank_cnt_c_and_d(15 downto 0)));
            result_b<=std_logic_vector(unsigned('0' & data_from_mem(31 downto 16))+unsigned('0' & bank_cnt_c_and_d(31 downto 16)));
            
            if result_a(16)='0' then
              sum_aux(15 downto 0)<=result_a(15 downto 0);
            else
              sum_aux(15 downto 0)<=x"FFFF";
            end if;

            if result_b(16)='0' then
              sum_aux(31 downto 16)<=result_b(15 downto 0);
            else
              sum_aux(31 downto 16)<=x"FFFF";
            end  if;

        end if;
    end if;
  
    --data_to_mem <= std_logic_vector(sum_aux);
    data_to_mem <= sum_aux;
end process;

end acc_mem_arq;



