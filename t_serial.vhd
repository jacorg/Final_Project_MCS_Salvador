--**************************************************************
-- Author: Jacobo O. Salvador <jacosalvador@gmail.com>
-- Project:Desarrollo de un módulo experimental de foto conteo 
--para aplicaciones de sensado remoto activo atmosférico
--==============================================================
--File: : t_serial.vhd
--Design units:
--  entity : t_serial
--  function Finite state Machine using a UART based in the Pong Chu Book
--  input entradas
--  output salidas
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
-- 07/2019 : created - Version 1.0 
--Comments : Original
--**************************************************************
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity t_serial is
generic(
  n_read_mem:       natural:=4;
  data_bus:         natural:=32;
  width_data_bytes: natural:=4;
	depth_mem:        natural:=511
);
port(
  sys_clk: in std_logic;                             -- 300 MHz system clock
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
end t_serial;

architecture Behavioral of t_serial is

component basic_uart is
generic (
  DIVISOR: natural                               --system clock working at 300 MHz
);
port (
  clk: in std_logic;                              -- system clock
  reset: in std_logic;
  
  -- Client interface
  rx_data: out std_logic_vector(7 downto 0);      -- received byte
  rx_enable: out std_logic;                       -- validates received byte (1 system clock spike)
  tx_data: in std_logic_vector(7 downto 0);       -- byte to send
  tx_enable: in std_logic;                        -- validates byte to send if tx_ready is '1'
  tx_ready: out std_logic;                        -- if '1', we can send a new byte, otherwise we won't take it
  
  -- Physical interface
  rx: in std_logic;
  tx: out std_logic
);
end component;

type fsm_state_t is (idle, received, enable_sys, reset_sys, resol_sys, intg_sys_lsb, intg_sys_msb, addressing, rcv_mem, tx_to_uart, end_emitting, end_tx);
type state_t is
record
  fsm_state: fsm_state_t; -- FSM state
  tx_data: std_logic_vector(7 downto 0);
  cmd: std_logic_vector(7 downto 0);
  tx_enable: std_logic;
  
  ena:          std_logic;
  rst:          std_logic;
  resol:        std_logic_vector(7 downto 0);
  intg:         std_logic_vector(15 downto 0);
  end_emitting: std_logic;
-- internal variables 
  addr_i: integer range 0 to depth_mem;
  data_i: integer range 0 to width_data_bytes;
end record;

signal reset: std_logic;
signal uart_rx_data: std_logic_vector(7 downto 0);
signal uart_rx_enable: std_logic;
signal uart_tx_data: std_logic_vector(7 downto 0);
signal uart_tx_enable: std_logic;
signal uart_tx_ready: std_logic;


signal state,state_next: state_t;

begin

  basic_uart_inst: basic_uart
  generic map (DIVISOR => 109) -- 115200 baudios @ 300 MHz:209
  port map (			--115200 baudios @ 200 MHz:109
    clk => sys_clk, 
    reset => reset,
    rx_data => uart_rx_data, 
    rx_enable => uart_rx_enable,
    tx_data => uart_tx_data, 
    tx_enable => uart_tx_enable, 
    tx_ready => uart_tx_ready,
    rx => uart_rx,
    tx => uart_tx
  );

  reset_control: process (sys_reset) is
    begin
      if sys_reset = '1' then
        reset <= '1';
      else
        reset <= '0';
      end if;
    end process;


  fsm_clk: process (sys_clk,reset) is
  begin
    if reset = '1' then
      state.fsm_state <= idle;                    --initial state is "idle"
      state.tx_enable <= '0';                     --enable control logic block
      state.ena <= '0';
      state.rst <= '0';                           --rst output signal activated by cmd to reset system by UART
      state.resol <= x"04";                       --resolution number by default
      state.intg<=x"00FF";                        --integration by default 
      state.end_emitting<='0';                    --indicate tx finished

    else
      if rising_edge(sys_clk) then
        state <= state_next;
      end if;
    end if;
  end process;

  fsm_next: process (state,uart_rx_enable,uart_rx_data,uart_tx_ready,tx_block_mem,q_b,state_next) is

  begin
    state_next <= state;   

    case state.fsm_state is                      --switch case

    when idle =>
      state_next.end_emitting<='0';             -- output ready_block is '0'
      state_next.rst<='0';
    ----------------------------------
      if state.resol<x"04" then                 --simple validation to avoid resol=0 
        state_next.resol<=x"04";
      end if;
    ---------------------------------

      if tx_block_mem ='1' then                  -- init tx memory using UART to PC
        state_next.fsm_state <= addressing;
        state_next.addr_i<=0;
        state_next.data_i<=0;           
      elsif uart_rx_enable = '1' then
        state_next.cmd <= uart_rx_data;
        state_next.tx_enable <= '0';      
        state_next.fsm_state <= received;
      else
        state_next.fsm_state <= idle; 
      end if;
      
      
    when received =>
      if state_next.cmd=X"65" then               --e x65 enable 
        state_next.fsm_state <= enable_sys;
        
      elsif state_next.cmd=X"72" then            --r x72 reset fsm 
        state_next.fsm_state <= reset_sys;

      elsif state_next.cmd=X"6A" then            --j x6A bin-size resolution 1-byte 0-255
        state_next.fsm_state <= resol_sys;

      elsif state_next.cmd=X"69" then            --i x69 integration value given by 2-two bytes
        state_next.fsm_state <= intg_sys_lsb;
      else 
        state_next.fsm_state <= idle;            -- idle state if any cmd is sent by uart
      end if;

      
    when enable_sys=>
        state_next.ena<='1';
        state_next.fsm_state <= idle;
    --    state_next.led_ena<='1';

    when reset_sys=>
        state_next.rst<='1';
        state_next.ena<='0';
        --state_next.led_ena<='0';
        state_next.fsm_state <= idle;

--System resolution given by a byte        
    when resol_sys=>
      if uart_rx_enable = '1' then
        state_next.resol <= uart_rx_data;--  valor de resol que llega x uart
        state_next.tx_enable <= '0';       
        state_next.fsm_state <= idle;
      end if;

--System intg given by 2-two bytes        
    when intg_sys_lsb=>
      if uart_rx_enable = '1' then
        state_next.intg(7 downto 0) <= uart_rx_data;
        state_next.fsm_state <= intg_sys_msb;
      end if;

    when intg_sys_msb=>
      if uart_rx_enable = '1' then
        state_next.intg(15 downto 8) <= uart_rx_data;
        state_next.fsm_state <= idle;
      end if;

    when addressing=>                                     --addressing: get data from dual port RAM
      --addr_b<=state.addr_i; 
      state_next.tx_enable <= '0';                        --aca hay que poner una demora de 3 ciclos para leer
      state_next.fsm_state <= rcv_mem;                    --o colocar un estado de lectura
      
    when rcv_mem=>                                        --rcv_mem: read data from dual port RAM
                                                          --q_b 31 downto 0 compose by 4 bytes
      if state.data_i=0 then
        state_next.tx_data<=q_b(7 downto 0);              --byte 0
        if uart_tx_ready = '1' then
          state_next.fsm_state <=tx_to_uart;
          state_next.tx_enable <= '1';
          state_next.data_i<=state.data_i+1;
        else
          state_next.fsm_state <=rcv_mem;
        end if;


      elsif state.data_i=1 then
        state_next.tx_data<=q_b(15 downto 8);             --byte 1
        if uart_tx_ready = '1' then
          state_next.fsm_state <=tx_to_uart;
          state_next.tx_enable <= '1';
          state_next.data_i<=state.data_i+1;
        else
          state_next.fsm_state <=rcv_mem;
        end if;

      elsif state.data_i=2 then
        state_next.tx_data<=q_b(23 downto 16);            --byte 2
        if uart_tx_ready = '1' then
          state_next.fsm_state <=tx_to_uart;
          state_next.tx_enable <= '1';
          state_next.data_i<=state.data_i+1;
        else
          state_next.fsm_state <=rcv_mem;
        end if;

      elsif state.data_i=3 then
        state_next.tx_data<=q_b(31 downto 24);            --byte 3
        if uart_tx_ready = '1' then
          state_next.fsm_state <=tx_to_uart;
          state_next.tx_enable <= '1';
          state_next.data_i<=state.data_i+1;
        else
          state_next.fsm_state <=rcv_mem;
        end if;
      else
        state_next.fsm_state <=idle;
      end if;     

    when tx_to_uart=>
      if uart_tx_ready = '0' then                          --send tx data
        state_next.tx_enable <= '0';
        state_next.fsm_state <=end_emitting;
      end if;

    when end_emitting=>                                    --end_emitting: when uart_tx_ready='0' then tx_enable='0'
        --state_next.tx_enable <= '0'; 
        if uart_tx_ready = '1' then                        
          if state.data_i<width_data_bytes then
            state_next.fsm_state <= rcv_mem;
          elsif state.addr_i<depth_mem then                       
              state_next.addr_i<=state.addr_i+1;
              --addr_b<=addr_i;  --addressing: get data from dual port RAM
              state_next.data_i<=0;
              state_next.fsm_state <= addressing;
          else
              state_next.fsm_state <= end_tx;
          end if;
        else
        state_next.fsm_state <= end_emitting;
        end if; 
  
      when end_tx=>
      if uart_tx_ready = '1' then
        state_next.end_emitting<='1';
        state_next.fsm_state <= idle;
      end if;

      when others=>
      state_next.fsm_state <= idle;
      state_next.addr_i<=0;
      state_next.data_i<=0;

    end case;
  end process;

  
  fsm_output: process (state) is
  begin
    uart_tx_enable <= state.tx_enable;
    uart_tx_data <= state.tx_data;

    ena<=state.ena;
    rst<=state.rst;
    resol<=state.resol;
    intg<=state.intg;
    ready_block_mem<=state.end_emitting;
    addr_b<=state.addr_i; 

  end process;
  
end Behavioral;

