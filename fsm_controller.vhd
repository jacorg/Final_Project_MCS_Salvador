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
--          clk:
--          trigger:
--          rst_from_uart:
--          power_on_rst:
--          enable:
--          tx_ready:
--          integ_s:
--          resol_s:

--  outputs: 
--          fst_int:
--          init:
--          ena_cnt
--          clr_all:
--          tx_mem: 
--          reg_a:
--          reg_b:
--          led_ena:
--          demux:
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

entity fsm_controller is
  generic(
    intg_max:         natural:=(2**16)-1;     --0 to 65535
    depth_mem:        natural:=511;           --0 to 511
    resol_max:        natural:=255            --0 to 255
  );
  port(
--  inputs:
    clk:            in std_logic; 
    trigger:        in std_logic; 
    enable:         in std_logic; 
    reset:          in std_logic; 
    tx_ready:       in std_logic; 
    integ_s:        in std_logic_vector(15 downto 0);
    resol_s:        in std_logic_vector(7 downto 0);

--  outputs: 
    fst_int:        out std_logic; 
    init:           out std_logic;
    ena_cnt:        out std_logic;
    clr_all:        out std_logic;
    tx_mem:         out std_logic; 
    reg_a:          out std_logic; 
    reg_b:          out std_logic; 
    led_ena:        out std_logic; 
    demux:          out std_logic_vector(1 downto 0)
  );
  end fsm_controller;

architecture fsm_controller_arq of fsm_controller is

  type fsm_state_t is (idle,run,cnt0,cnt1,cnt2,cnt3,fsm_delay,inc_integ,send_data,wait_tx_ready);
  type state_t is
  record                                                     --Record  
    fsm_state: fsm_state_t;                                 -- FSM state
    demux: std_logic_vector(1 downto 0);
    fst_int: std_logic; 
    ena_cnt: std_logic;
    clr_all: std_logic;
    tx_mem: std_logic; 
    reg_a: std_logic; 
    reg_b: std_logic; 
    led_ena: std_logic;
    clk_div_enable: std_logic;
    init: std_logic;
  --internal variables
    mem_i: integer range 0 to depth_mem;                    --memory index position
    intg_i: integer range 0 to intg_max;                    --integration index take into account the integration range
    
  end record;

  signal state,state_next: state_t;  
  signal clk_div_sig:std_logic;

  begin
  --------------------------------reset and state-------------------------------
  fsm_clk: process (clk,reset) is
    begin
      if reset = '1' then
        state.fsm_state <= idle;                                 --initial state is "idle"
      else
        if rising_edge(clk) then
          state <= state_next;
        end if;
      end if;
    end process;

  ----------------------------------clk divider---------------------------------      
    fsm_clk_div: process (clk,state,resol_s) is
      variable resol_i: integer range 0 to resol_max:=0;           --resol_i give the resolution of the bin size. This variable is used in the counter code
      --variable resol_j:integer range 0 to resol_max:=to_integer(unsigned(resol_s));
      variable clk_div_aux: std_logic;
      
      begin
        if state.clk_div_enable = '1' then
          if rising_edge(clk) then                                --bin size = resol_s/clk
          resol_i:=resol_i+1;
            if resol_i=to_integer(unsigned(resol_s)) then         --conversion  unsigned and to_integer. Resol is pass through com. controller.
              resol_i:=0;
              --clk_div_sig<='1';
              clk_div_aux:='1';
            else
              --clk_div_sig<='0';
              clk_div_aux:='0'; 
            end if;
          end if;
        end if;
        clk_div_sig<=clk_div_aux;
      end process;

    ---------------------------------fsm next-----------------------------------
    fsm_next: process (state,clk_div_sig,enable, trigger,tx_ready,integ_s) is  
 
    begin
      state_next <= state;   
      case state.fsm_state is

        when idle =>
          state_next.demux <= "00";
          state_next.reg_a<= '0';
          state_next.reg_b<= '0';
          state_next.led_ena<= '0';
          state_next.fst_int<='0';
          state_next.tx_mem<='0';
          state_next.clk_div_enable<='0';                         --internal state variable
          state_next.clr_all<='1';                                --clear all counters
          state_next.ena_cnt<='0';                                --enable counters
          state_next.init<='0';                                   --init unit accumulation and memory manage
          
          state_next.mem_i<=0;
          state_next.intg_i<=0;
          
          if enable='1' then
            state_next.fsm_state <= run;
          else
            state_next.fsm_state <= idle;
          end if;
        -----------------------------------------------------------------
        when run =>
         state_next.led_ena<= '1';
         state_next.reg_a<= '0';
         state_next.reg_b<= '0';
         state_next.clr_all<='0';                                  --clear all counters
         state_next.ena_cnt<='0';                                  --disable ena counter if not enable otherwise ena_cnt=1
         --state_next.init<='1';                                     --init unit accumulation and memory manage   OLD
         state_next.init<='0'; --NEW


        if enable='1' then
          if trigger='1' and state.intg_i=0 then 
            state_next.fsm_state <= cnt0;
            state_next.fst_int<='1';
            state_next.clk_div_enable<='1';
            state_next.ena_cnt<='1';                              --enable counters
            state_next.init<='1';                                 --generate init signal to fsm_memory
          elsif trigger='1' and state.intg_i>0 then
            state_next.fsm_state <= cnt0;
            state_next.fst_int<='0';
            state_next.clk_div_enable<='1';
            state_next.ena_cnt<='1';                              --enable counters
            state_next.init<='1';                                 --generate init signal to fsm_memory
          else
            state_next.fsm_state <= run;
          end if;
        else
          state_next.fsm_state <= idle;
        end if;
        -----------------------------------------------------------------
        --cnt0 cnt1: enable counter 0 and 1 called bank A
        when cnt0 =>
          state_next.demux <= "00"; 
          state_next.clr_all<='0';
          state_next.reg_b<= '0';
          state_next.init<='0'; 

          if clk_div_sig='1' then                                   --bin size = resol_s/clk
            state_next.fsm_state <= cnt1;                         
          else  
            state_next.fsm_state <= cnt0;                           --next state 
          end if; 
        -----------------------------------------------------------------    
        --counter 1 enable signal reg_a=1 to fsm memory address and accum data
        when cnt1 =>
          state_next.demux <= "01"; 
          state_next.clr_all<='0';

          if clk_div_sig='1' then  
            state_next.fsm_state <= cnt2;  
            state_next.reg_a<= '1';                                 --reg_a signal to fsm memory
            state_next.mem_i<=state.mem_i+1;                        --memory increase x1 position
          else  
            state_next.fsm_state <= cnt1;                           --next state 
          end if;  
        -----------------------------------------------------------------
        --cnt2 cnt3: enable counter 2 and 3 called bank B
        when cnt2 =>
          state_next.demux <= "10"; 
          state_next.clr_all<='0';
          state_next.reg_a<= '0';

          if clk_div_sig='1' then  
            state_next.fsm_state <= cnt3;                            --bin size = resol_s/clk
          else  
            state_next.fsm_state <= cnt2;                            --next state 
          end if;  
        -----------------------------------------------------------------
        when cnt3 =>
          state_next.demux <= "11";                                  --comparo si llegue al final de la memoria y ejecuto latch
          state_next.clr_all<='0';                                
         
          if clk_div_sig='1' then  
            if state.mem_i=depth_mem then
              state_next.mem_i<=0;               
              state_next.intg_i<=state.intg_i+1;                                   --incremental value intg_i
              state_next.fsm_state <= fsm_delay;
              state_next.reg_b<= '1';   
            else
              state_next.mem_i<=state.mem_i+1; 
              state_next.fsm_state <= cnt0;
              state_next.reg_b<= '1'; 
            end if;
            --if mem_i<depth_mem then                                  --check memory is full
            --    mem_i:=mem_i+1;                                      --memry increase x1 position
            --    state_next.fsm_state <= cnt0;                        --next state 
            --    state_next.reg_b<= '1';                              --reg_b signal 
            --    if mem_i=depth_mem then
            --      mem_i:=0;               
            --      intg_i:=intg_i+1;                                   --incremental value intg_i
            --      state_next.fsm_state <= inc_integ;                  -- next state
            --    end if;
            --  end if;                                         
          else  
            state_next.fsm_state <= cnt3;                            --same state 
          end if; 
        
        when fsm_delay =>                                            --generate delay for last address 511
          state_next.reg_b<= '0'; 
          if clk_div_sig='1' then      
            state_next.fsm_state <= inc_integ;   
           else
            state_next.fsm_state <= fsm_delay; 
          end if;   

        when inc_integ =>
        state_next.clk_div_enable<='0';                              --disable clk divider system in 0          
        state_next.reg_b<= '0';               
        if state.intg_i<to_integer(unsigned(integ_s)) then                 --eval integration if it's lower go RUN state waiting for a new trigger signal
          state_next.fsm_state <= run;      
        else
          state_next.fsm_state <= send_data;                         --eval integration if it's reached then send data from memory by UART to PC
        end if;
        
        --generate signal to t_serial to address memory and then move data throught UART
        when send_data =>                                             
          state_next.tx_mem<='1';
          state_next.ena_cnt<='0';                                    --disable counters
          state_next.clr_all<='1';                                    --clear all counters
          state_next.intg_i<=0;
          state_next.fsm_state <= wait_tx_ready;

        -- wait signal to start a new cycle          
        when wait_tx_ready =>
        state_next.tx_mem<='0';
        if tx_ready='1' then
          state_next.fsm_state <= run;
          state_next.tx_mem<='0';
        else
          state_next.fsm_state <= wait_tx_ready;
        end if;
      end case; 

    end process;

    ------------------------------fsm output------------------------------
    fsm_output: process (state) is
    begin
      demux<=state.demux;  
      reg_a<=state.reg_a;
      reg_b<=state.reg_b;
      fst_int<=state.fst_int;   
      tx_mem<=state.tx_mem;
      led_ena<=state.led_ena;
      clr_all<=state.clr_all;
      ena_cnt<=state.ena_cnt;
      init<=state.init;
    end process;
        
end fsm_controller_arq;



