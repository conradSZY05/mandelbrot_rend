----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 16.03.2026 14:24:44
-- Design Name: 
-- Module Name: tb_UART_TX - sim
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity tb_UART_TX is
    generic (
        CLK_DIV : integer := 868; -- 100 MHz / 115200 baud = 868 clock cycles per bit
        CLK_PERIOD : time := 10 ns -- 1 / 100 MHz = 10 ns, so enable_clk every 8680 ns
    );
end tb_UART_TX;

architecture sim of tb_UART_TX is
    signal clk_i : std_logic := '0';
    signal reset : std_logic;
    signal tx_start : std_logic;
    signal data_i : std_logic_vector(7 downto 0);
    signal data_o :  std_logic;
begin
    uut : entity work.UART_TX(rtl)
        port map (
            clk_i => clk_i,
            reset => reset,
            tx_start => tx_start,
            data_i => data_i,
            data_o => data_o
        );

    clk_i <= not clk_i after CLK_PERIOD / 2;
    
    process
    begin
        reset <= '1';
        wait for CLK_PERIOD;
        reset <= '0';
        wait for CLK_PERIOD;
        
        data_i <= "11111111";
        tx_start <= '1';
        
        wait;
    end process;
end sim;
