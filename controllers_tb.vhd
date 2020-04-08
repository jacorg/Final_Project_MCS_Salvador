-- EB Mar 2013
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.numeric_std.all;
use STD.TEXTIO.ALL;

entity controllers_tb is
end;

architecture controllers_tb_arq of controllers_tb is
	

component controllers is
	port(
		--  inputs:
		clk_in:                 in std_logic;
		trigger:                in std_logic;
		Rx:                     in std_logic;   
		input_signal:           in std_logic;    
-- outputs:
--logic controller 
		led_enable:             out std_logic;
--uart   
		Tx:                     out std_logic;
--test
		trigger_probe: 	        out std_logic;
		signal_probe: 	        out std_logic
	);
end component;

	signal clk_tb:                     std_logic;
	signal clk_tb2:                    std_logic;
	signal trigger_tb:                 std_logic;
	signal input_signal_tb:			   std_logic;
	signal Rx_tb:                      std_logic:='1';     
	--logic controller 
	signal led_enable_tb:              std_logic;
	--uart   
	signal Tx_tb:                      std_logic;
	--test
	signal trigger_probe_tb: 	       std_logic;
	signal signal_probe_tb: 	       std_logic;
	
		
	signal data_value: std_logic_vector(7 downto 0);



	constant clk_period : time := 8 ns;
	constant clk_period2 : time := 5 ns;

	constant uart_period : time := 8640 ns;

	file datos: text open read_mode is "datos.txt";
	--signal a_file: unsigned(0 downto 0);
	--signal b_file: unsigned(0 downto 0);


--Constants for UART communication
	--constant data_value  : std_logic_vector(7 downto 0) := x"69"; --intg
	constant data_value1  : std_logic_vector(7 downto 0) := x"50"; 
	constant data_value2  : std_logic_vector(7 downto 0) := x"20";
----------------------------------------------------------------------------
	constant res  : std_logic_vector(7 downto 0) := x"6A"; --res
	constant data_res  : std_logic_vector(7 downto 0) := x"30"; --res
----------------------------------------------------------------------------
	constant data_ena  : std_logic_vector(7 downto 0) := x"65"; --ena
----------------------------------------------------------------------------
	constant rst : std_logic_vector(7 downto 0) := x"72"; --rst
	constant ones : std_logic_vector(7 downto 0) := x"FF"; --ones
----------------------------------------------------------------------------	
begin 
	
DUTcontroller: controllers
		port map(
	 		clk_in=>clk_tb,
			trigger=>trigger_tb,
			Rx=>Rx_tb,   
			input_signal=>input_signal_tb,   
			--  outputs:
			--logic controller 
			led_enable=>led_enable_tb,
			--uart   
			Tx=>Tx_tb,
			--test
			trigger_probe => trigger_probe_tb,
			signal_probe => signal_probe_tb
		);

		
--trigger_tb<='1' after 1000 us,'0' after 1001 us,'1' after 3500 us,'0' after 3501 us,'1' after 7000 us,'0' after 7001 us;--,'1' after 303000 us,'0' after 303001 us,'1' after 404000 us,'0' after 404001 us,'1' after 605000 us,'0' after 605001 us;

input_signals: process
	variable l: line;
	variable ch: character:= ' ';
	variable aux: integer;
begin
	while not(endfile(datos)) loop 	-- si se quiere leer de stdin se pone "input"
	wait until rising_edge(clk_tb2);
	readline(datos, l); 			-- se lee una linea del archivo de valores de prueba
	read(l, aux); 					-- se extrae un entero de la linea
	if aux = 1 then					-- se carga el valor del Cout
		trigger_tb <= '1';
	else
		trigger_tb <= '0';
	end if;
	read(l, ch); 					-- se lee un caracter (es el espacio)
	read(l, aux); 					-- se lee otro entero de la linea
	if aux = 1 then					-- se carga el valor del Cout
		input_signal_tb <= '1';
	else
		input_signal_tb <= '0';
	end if;
	end loop;
	file_close(datos); 				-- cierra el archivo
	wait for clk_period; 			-- se pone el +1 para poder ver los datos
end process;


com_serial: process
type vec_command is array(0 to 5) of std_logic_vector(7 downto 0);
variable com: vec_command:=(x"69",x"03",x"00",x"6A",x"05",x"65");
begin
	for i in 0 to 5 loop
		data_value<=com(i);
		wait until rising_edge(clk_tb);
		Rx_tb <= '0'; -- start bit
		wait for uart_period;
		for j in 0 to (data_value'LENGTH-1) loop
			Rx_tb <= data_value(j); -- data bits
			wait for uart_period;
		end loop;
	Rx_tb <= '1'; -- stop bit
	wait for uart_period;
	end loop;
	wait for 800 ms;
end process;


clk_process : process
	begin
		clk_tb <= '0';
		wait for clk_period/2;
		clk_tb <= '1';
		wait for clk_period/2;
	end process;

clk_process2 : process
	begin
		clk_tb2 <= '0';
		wait for clk_period2/2;
		clk_tb2 <= '1';
		wait for clk_period2/2;
	end process;	



end;

