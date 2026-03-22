----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 16.03.2026 19:59:28
-- Design Name: 
-- Module Name: tb_UART_RX - sim
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

entity tb_UART_RX is
    generic (
        CLK_DIV : integer := 54 -- (100 MHz / 115200 baud ) / 16 oversampling = 54.25
    );
end tb_UART_RX;

architecture sim of tb_UART_RX is
    constant CLK_PERIOD : time := 10 ns; -- 100 MHz clock

    signal clk_i : std_logic := '0';
    signal reset : std_logic := '0';
    signal data_i : std_logic := '1';
    signal data_o : std_logic_vector(7 downto 0);
    signal valid_o : std_logic;
begin
    uut : entity work.UART_RX(rtl)
        port map (
            clk_i => clk_i,
            reset => reset,
            data_i => data_i,
            data_o => data_o,
            valid_o => valid_o
        );
        
    clk_i <= not clk_i after CLK_PERIOD / 2;
    
    process
    begin
        reset <= '1'; wait for CLK_PERIOD * 5;
        reset <= '0'; wait for CLK_PERIOD * 5;
        
        -- start bit
        data_i <= '0';
        wait for CLK_PERIOD * 868;
        -- send 01010101
        data_i <= '1'; wait for CLK_PERIOD * 868;
        data_i <= '0'; wait for CLK_PERIOD * 868;
        data_i <= '1'; wait for CLK_PERIOD * 868;
        data_i <= '0'; wait for CLK_PERIOD * 868;
        data_i <= '1'; wait for CLK_PERIOD * 868;
        data_i <= '0'; wait for CLK_PERIOD * 868;
        data_i <= '1'; wait for CLK_PERIOD * 868;
        data_i <= '0'; wait for CLK_PERIOD * 868;
        -- stop bit
        data_i <= '1'; wait for CLK_PERIOD * 868;
        
        
        
                -- start bit
        data_i <= '0';
        wait for CLK_PERIOD * 868;
        -- send 01010101
        data_i <= '0'; wait for CLK_PERIOD * 868;
        data_i <= '0'; wait for CLK_PERIOD * 868;
        data_i <= '1'; wait for CLK_PERIOD * 868;
        data_i <= '1'; wait for CLK_PERIOD * 868;
        data_i <= '1'; wait for CLK_PERIOD * 868;
        data_i <= '0'; wait for CLK_PERIOD * 868;
        data_i <= '1'; wait for CLK_PERIOD * 868;
        data_i <= '1'; wait for CLK_PERIOD * 868;
        -- stop bit
        data_i <= '1'; wait for CLK_PERIOD * 868;
        
        wait for CLK_PERIOD * 868;
        
        wait;
    end process;

end sim;
