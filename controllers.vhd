--**************************************************************
-- Author: Jacobo O. Salvador <jacosalvador@gmail.com>
-- Project:Desarrollo de un módulo experimental de foto conteo 
--para aplicaciones de sensado remoto activo atmosférico
--==============================================================
--File: : controllers.vhd
--Design units:
--  entity : controllers
--  function Blocks control: Logic, communication and memory
--  inputs:
--      clk:                    
--      trigger:                
--      clk_uart:               
--      Rx:                       
--      input_signal:           
--          
--   outputs:
--      led_enable:               
--      Tx:                     
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
-- Feb. 18 2020: writen header comments 
--**************************************************************
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity controllers is
  port(
--  inputs:
      clk_in:                 in std_logic;
      trigger:                in std_logic;
      Rx:                     in std_logic;   
      input_signal:           in std_logic;    
--  outputs:
--logic controller 
      led_enable:             out std_logic;
--uart   
      Tx:                     out std_logic;
--test
      trigger_probe: 	        out std_logic;
      signal_probe: 	        out std_logic
  );
  end controllers;

architecture controllers_arq of controllers is

--  component meta_harden is 
--    port(
--		clk_dst: 	in std_logic;	  -- Destination clock
--		signal_src: in std_logic;	-- Asynchronous signal to be synchronized
--		signal_dst: out std_logic	-- Synchronized signal
--	  );
 -- end component;

  --component SynchonizerParametric is 
  --  generic (
  --        SYNC_STAGES : integer := 2;
  --        PIPELINE_STAGES : integer := 1;
  --        INIT : std_logic := '0'
  --    );
  --  port   (
  --        pClk : in std_logic;
  --        piAsync : in std_logic;
  --        poSync : out std_logic
  --  );
--end component;
  component test is
      generic(
        N_trigger: 		natural := 400000;
        N_signal:  		natural :=4;
        N_aux:			natural :=30
      );
      port(
        clk_i: 			    in  std_logic;
        trigger_test: 	out std_logic;
        signal_test: 	  out std_logic
      );        
  end component;


  component risingEdge is
	    port (
	        clk     		  	: in  std_logic;
  	      inputPulse			: in  std_logic;
  	      outputPulse			: out std_logic
	    );
  end component;


  component fsm_controller is
    generic(
    intg_max:         natural:=(2**16)-1;     --0 to 65535
    depth_mem:        natural:=511;           --0 to 512
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
  end component;
  
component clk_wiz_0 is
  port
   (-- Clock in ports
    -- Clock out ports
    clk_out1          : out    std_logic;
    clk_in1           : in     std_logic
   );
  end component;

component t_serial is
  generic(
    n_read_mem:       natural:=4;
    data_bus:         natural:=32;
    width_data_bytes: natural:=4;
	  depth_mem:        natural:=511
  );
  port(
    sys_clk: in std_logic;                             -- 100 MHz system clock
    sys_reset: in std_logic;

  --led: out std_logic;
    uart_rx: in std_logic;
    uart_tx: out std_logic;
  
    ena: out std_logic;
    rst: out std_logic;
    resol:out std_logic_vector(7 downto 0);
    intg: out std_logic_vector(15 downto 0);

    addr_b: out natural range 0 to depth_mem;
    q_b: in std_logic_vector(data_bus-1 downto 0);

    tx_block_mem: in std_logic;
    ready_block_mem: out std_logic
  );
end component;

component fsm_memory is
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
end component;

component or_gate is
  port (
      in_1    : in  std_logic;
      in_2    : in  std_logic;
      or_o  : out std_logic
    );
end component;

component true_dpram_sclk is
  generic ( 
      data_bus    : natural:=32;
      depth_mem   : natural:=511
    );
    port(	
    data_a	: in std_logic_vector(data_bus-1 downto 0);
--		data_b	: in std_logic_vector(data_bus-1 downto 0);
    addr_a	: in natural range 0 to depth_mem;
    addr_b	: in natural range 0 to depth_mem;
    we_a	: in std_logic := '1';
--		we_b	: in std_logic := '1';
    clk	: in std_logic;
    q_a	: out std_logic_vector(data_bus-1 downto 0);
    q_b	: out std_logic_vector(data_bus-1 downto 0)
  );
end component;

component acc_mem is
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
end component;

component power_on_reset is
  generic(
    max_cons_delay:          natural:=150;
    cons_delay_pulse:        natural:=20        
  );
  port(
    clk:                    in std_logic;   
    power_on_reset:         out std_logic
  );
end component;

component counter is
  generic(N : natural := 16);
	port(
		inp 				:in std_logic;
		clr 				:in std_logic;
		enable			:in std_logic;
		clk 				:in std_logic;
		q   				:out std_logic_vector(N-1 downto 0)
  );
end component;

component demux4 is
  generic( 
		N_data    : natural:=2
	);
  port(
  	F     	    :in  std_logic;
  	A           :out std_logic;
		B           :out std_logic;
		C           :out std_logic;
		D           :out std_logic;
	  sel         :in std_logic_vector(N_data-1 downto 0)
	);
end component;

-----------------------------------------------------------------
--meta_harden
signal trigger_s:                       std_logic;
--signal input_signal_s:                  std_logic;
----------------------------------------------------------------
--rising edge
signal input_signal_edge_s:             std_logic;
----------------------------------------------------------------
--signals logic controller
signal ena_from_uart_s:                 std_logic;
signal reset_fsm_logic_controller_s:    std_logic;
signal demux_s:                         std_logic_vector(1 downto 0);

--signal between logic controller and counters
signal ena_cnt_s:                       std_logic;
signal clr_all_s:                       std_logic;
signal clr_a_and_b_s:                   std_logic;
signal clr_c_and_d_s:                   std_logic;

--signal between demux and counters
signal in_cnt_0:                        std_logic;
signal in_cnt_1:                        std_logic;
signal in_cnt_2:                        std_logic;
signal in_cnt_3:                        std_logic;

--signal between or gates and counters
signal clr_cnts_a_and_b_s:              std_logic;
signal clr_cnts_c_and_d_s:              std_logic;

--signal between counters and accumulator
signal data_cnt_a_and_b_s:              std_logic_vector(31 downto 0);
signal data_cnt_c_and_d_s:              std_logic_vector(31 downto 0);

--signals between logic controller and UART
signal resolution_s:                    std_logic_vector(7 downto 0);
signal integration_s:                   std_logic_vector(15 downto 0);
signal tx_mem_s:                        std_logic;
signal tx_ready_s:                      std_logic;

--signals between logic controller and fsm_mem
signal init_s:                          std_logic;
signal reg_a_s:                         std_logic;
signal reg_b_s:                         std_logic;
-----------------------------------------------------------------
--signals UART
signal addr_b_s:                        natural range 0 to 511;
signal reset_fsm_logic_memory_s:        std_logic;
-----------------------------------------------------------------
--signals fsm memory controller
signal reset_fsm_memory_s:              std_logic;
signal wr_a_s:                          std_logic;
-----------------------------------------------------------------
--signals power_on_reset
signal por_s:                           std_logic;
-----------------------------------------------------------------
--accumulation unit with bank selection
signal fst_intg_s:                       std_logic;
signal sel_bank_s:                       std_logic;
signal data_acc_to_mem_s:                std_logic_vector(31 downto 0);
-----------------------------------------------------------------
--dual port RAM
signal addr_a_s:                          natural range 0 to 511;
signal data_from_mem_a_s:                 std_logic_vector(31 downto 0);
signal data_from_mem_b_s:                 std_logic_vector(31 downto 0);
-----------------------------------------------------------------
--clk mmcm
signal clk:                               std_logic;


begin

inst_clk_mmcm : clk_wiz_0
  port map ( 
 -- Clock out ports  
  clk_out1 => clk,
  -- Clock in ports
  clk_in1 => clk_in
  );

--inst_meta_herden_trigger: meta_harden
--            port map(
--            clk_dst=>clk,
--            signal_src=>trigger,
--            signal_dst=>trigger_s        --connected to trigger controller
--            );

inst_test:  test
            port map(
                clk_i=> clk,
                trigger_test => trigger_probe,
                signal_test => signal_probe
            );



inst_rising_edge_trigger:  risingEdge
              port map(
                  clk => clk,
                  inputPulse =>trigger,
                  outputPulse	=>trigger_s
              );

inst_controller: fsm_controller
            port map(
              --inputs:
              clk=>clk, 
              trigger=>trigger_s,         --connected to trigger controller
              enable=>ena_from_uart_s,
              reset=>reset_fsm_logic_controller_s, 
              tx_ready=>tx_ready_s,
              integ_s=>integration_s,
              resol_s=>resolution_s,
--            outputs: 
              fst_int=>fst_intg_s,                  --connected to acc_mem
              init=>init_s,
              ena_cnt=>ena_cnt_s,
              clr_all=>clr_all_s,
              tx_mem=>tx_mem_s, 
              reg_a=>reg_a_s, 
              reg_b=>reg_b_s,
              led_ena=>led_enable, 
              demux=>demux_s
            );
            
inst_or_gate_controller_a: or_gate
            port map(
              in_1=>por_s,
              in_2=>reset_fsm_logic_memory_s,
              or_o=>reset_fsm_logic_controller_s          --signal output or gate
            );
  
inst_uart: t_serial
            port map( 
              sys_clk=>clk,                               -- 200 MHz system clock
              sys_reset=>por_s,
              uart_rx=>Rx,
              uart_tx=>Tx,
  
              ena=>ena_from_uart_s,
              rst=>reset_fsm_logic_memory_s,             --output
              resol=>resolution_s,
              intg=>integration_s,
              addr_b=>addr_b_s,                          --connected dual port B RAM
              q_b=>data_from_mem_b_s,
              tx_block_mem=>tx_mem_s,
              ready_block_mem=>tx_ready_s
            );   
            
inst_or_gate_controller_b: or_gate
            port map(
              in_1=>por_s,
              in_2=>reset_fsm_logic_memory_s,
              or_o=>reset_fsm_memory_s    --signal output or gate
            );


inst_fsm_mem: fsm_memory
            port map(            
              --inputs:
              clk=>clk,
              reset=>reset_fsm_memory_s, 
              reg_a=>reg_a_s, 
              reg_b=>reg_b_s, 
              init=>init_s,     
          --  outputs: 
              addr_a=>addr_a_s,                --connected dual port RAM
              wr_a=>wr_a_s,
              clr_cnt_a=>clr_a_and_b_s,
              clr_cnt_b=>clr_c_and_d_s,
              sel=>sel_bank_s                   --connected to acc_mem
            );

inst_true_dpram_sclk: true_dpram_sclk
            port map(
              data_a=>data_acc_to_mem_s,
        --		data_b=>,
              addr_a=>addr_a_s,-----------------------------
              addr_b=>addr_b_s,                 --connected t_serial
              we_a=>wr_a_s,--------------------------------------
          --		we_b=>wr_mem,
              clk=>clk,
              q_a=>data_from_mem_a_s,
              q_b=>data_from_mem_b_s
            );
-----------------------------------------accumulator---------------------------------------------
inst_acc_mem: acc_mem
            port map(
              clk=>clk,
              data_from_mem=>data_from_mem_a_s,
              bank_cnt_a_and_b=>data_cnt_a_and_b_s,
              bank_cnt_c_and_d=>data_cnt_c_and_d_s,
              fst_cnt=>fst_intg_s,       
              sel_bank=>sel_bank_s,
              --  outputs: 
              data_to_mem=>data_acc_to_mem_s
            );  

---------------------------------------meta_harden_signal_in--------------------------------------
--inst_meta_herden_signal_in: meta_harden
--            port map(
--            clk_dst=>clk,
--            signal_src=>input_signal,
--            signal_dst=>input_signal_s        --connected to signal in
--            );

--inst_SynchonizerParametric_signal_in: SynchonizerParametric
--              port map(
--                  pClk => clk,
--                  piAsync => input_signal,
--                  poSync => input_signal_s
--              );

inst_rising_edge_input:  risingEdge
              port map(
                  clk => clk,
                  inputPulse =>input_signal,
                  outputPulse	=>input_signal_edge_s
              );
             
-------------------------------------------demultiplexor------------------------------------------- 
inst_demux: demux4
            port map(
            	F=>input_signal_edge_s,    --in  signal
  	          A=>in_cnt_0,               --out  counter 0
		          B=>in_cnt_1,               --out  counter 1
		          C=>in_cnt_2,               --out  counter 2
		          D=>in_cnt_3,               --out  counter 3
		          sel=>demux_s               --in  selection
            );

-------------------------------------------counter block-------------------------------------------
inst_counter_0: counter
          port map(
            inp=>in_cnt_0,				
		        clr=>clr_cnts_a_and_b_s,
		        enable=>ena_cnt_s,
		        clk=>clk,
		        q=>data_cnt_a_and_b_s(15 downto 0)
          );

inst_or_gate_cnt_a_and_b: or_gate
          port map(
            in_1=>clr_all_s,
            in_2=>clr_a_and_b_s,
            or_o=>clr_cnts_a_and_b_s
          );    

inst_counter_1: counter
          port map(
            inp=>in_cnt_1,				
		        clr=>clr_cnts_a_and_b_s,
		        enable=>ena_cnt_s,
		        clk=>clk,
		        q=>data_cnt_a_and_b_s(31 downto 16)
          );

inst_counter_2: counter
          port map(
            inp=>in_cnt_2,				
		        clr=>clr_cnts_c_and_d_s,
		        enable=>ena_cnt_s,
		        clk=>clk,
		        q=>data_cnt_c_and_d_s(15 downto 0)
          );

inst_or_gate_cnt_c_and_d: or_gate
          port map(
            in_1=>clr_all_s,
            in_2=>clr_c_and_d_s,
            or_o=>clr_cnts_c_and_d_s
          ); 

inst_counter_3: counter
          port map(
            inp=>in_cnt_3,				
		        clr=>clr_cnts_c_and_d_s,
		        enable=>ena_cnt_s,
		        clk=>clk,
		        q=>data_cnt_c_and_d_s(31 downto 16)
          );

inst_power_on_reset: power_on_reset
          port map(
             clk=>clk,                   
             power_on_reset=>por_s
          );

end controllers_arq;



