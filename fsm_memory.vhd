--**************************************************************
-- Author: Jacobo O. Salvador <jacosalvador@gmail.com>
-- Project:Desarrollo de un módulo experimental de foto conteo 
--para aplicaciones de sensado remoto activo atmosférico
--==============================================================
--File: : fsm_memory.vhd
--Design units:
--  entity : fsm_memory
--  function Finite state Machine to controller data memory access
--  inputs:
--          clk:
--          reset:
--          reg_a:
--          reg_b:
--          init:


--  outputs: 
--          addr_a:
--          wr_a:
--          clr_cnt_a:
--          clr_cnt_b: 
--          sel:

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

entity fsm_memory is
  generic(
    depth_mem:        natural:=511          --0 to 511
  );
  port(
--  inputs:
    clk:            in std_logic; 
    reset:          in std_logic; 
    reg_a:          in std_logic; 
    reg_b:          in std_logic; 
    init:           in std_logic; 
    
--  outputs: 
    addr_a:         out natural range 0 to depth_mem; 
    wr_a:           out std_logic;
    clr_cnt_a:      out std_logic;
    clr_cnt_b:      out std_logic; 
    sel:            out std_logic
  );
  end fsm_memory;

architecture fsm_memory_arq of fsm_memory is

  type fsm_state_t is (initial,run,select_reg_a,select_reg_b,add1,add2,wr,clr);
  type state_t is
  record                                            --Record  
    fsm_state: fsm_state_t; -- FSM state 
    addr_a:         natural range 0 to depth_mem; 
    wr_a:           std_logic;
    clr_cnt_a:      std_logic;
    clr_cnt_b:      std_logic; 
    sel:            std_logic;
  --internal variable
    mem_i: natural range 0 to depth_mem;                            --memory index position
  end record;

  signal state,state_next: state_t;  

  begin
  --------------------------------reset and state-------------------------------
  fsm_clk: process (clk,reset,init) is
    begin
      if reset = '1' or init= '1' then
        state.fsm_state <= initial;                                 --initial state is "idle"
      else
        if rising_edge(clk) then
          state <= state_next;
        end if;
      end if;
    end process;

    ---------------------------------fsm next-----------------------------------
    fsm_next: process (state,reg_a,reg_b,init) is  
     
    begin
      state_next <= state;   
      case state.fsm_state is

        when initial =>
          state_next.mem_i<=0;
          state_next.addr_a <= state.mem_i;
          state_next.sel <= '0';
          state_next.wr_a <= '0';
          state_next.clr_cnt_a <= '0';
          state_next.clr_cnt_b <= '0';         
          state_next.fsm_state <= run;
        
        -----------------------------------------------------------------
        when run =>
          state_next.wr_a <= '0';
          state_next.clr_cnt_a<='0';
          state_next.clr_cnt_b<='0';

          if reg_a='1' then
            state_next.fsm_state <= select_reg_a;
            state_next.addr_a <= state.mem_i;     
          elsif reg_b='1' then 
            state_next.fsm_state <= select_reg_b;
            state_next.addr_a <= state.mem_i; 
          else
            state_next.fsm_state <= run;
          end if;

        -----------------------------------------------------------------
        when select_reg_a =>
          state_next.sel <= '0'; 
          state_next.fsm_state <= add1;
          
        -----------------------------------------------------------------    
        when select_reg_b =>
          state_next.sel <= '1';    
          state_next.fsm_state <= add1; 

        -----------------------------------------------------------------
        when add1 =>
          state_next.fsm_state <= add2; 

        -----------------------------------------------------------------    
        when add2=>
          state_next.fsm_state <= wr;

        -----------------------------------------------------------------
        when wr =>
          state_next.wr_a <= '1';
          state_next.fsm_state <= clr;
        
        -----------------------------------------------------------------    
        when clr =>
        state_next.wr_a <= '0';
                      
        if state.mem_i<depth_mem then                               --check memory is full                                   
        state_next.fsm_state <= run;                            --next state 
        state_next.mem_i<=state.mem_i+1; 
          if state.sel='0' then
            state_next.clr_cnt_a<='1';   
          else
            state_next.clr_cnt_b<='1';  
          end if;
        
      else             
      state_next.fsm_state <= initial;
        if state.sel='0' then
          state_next.clr_cnt_a<='1';   
         else
          state_next.clr_cnt_b<='1';  
        end if; 
      end if;
      end case; 

    end process;

    ------------------------------fsm output------------------------------
    fsm_output: process (state) is
    begin
      addr_a<=state.addr_a;
      wr_a<=state.wr_a;
      clr_cnt_a<=state.clr_cnt_a;
      clr_cnt_b<=state.clr_cnt_b; 
      sel<=state.sel;
      
    end process;
        
end fsm_memory_arq;



