----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 24.03.2026 16:58:00
-- Design Name: 
-- Module Name: tb_mandelbrot_top - sim
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity tb_mandelbrot_top is

end tb_mandelbrot_top;

architecture sim of tb_mandelbrot_top is
    constant CLK_PERIOD : time := 10 ns;
    signal clk : std_logic := '0';
    signal reset : std_logic := '0';
    
    signal addr : std_logic_vector(18 downto 0);
    signal wr_en : std_logic := '0';
    signal di : std_logic_vector(3 downto 0);
begin
    uut : entity work.mandelbrot_top
        port map (
            clk_i => clk,
            enable => '1',
            valid => '0',
            uart_comm => (others => '0'),
            re_render => reset,
            addr => addr,
            wr_en => wr_en,
            di => di
        );
    
    clk <= not clk after CLK_PERIOD / 2;
    
    process
    begin
        reset <= '1';
        wait for CLK_PERIOD;
        reset <= '0';
        wait for CLK_PERIOD;
        
        
        
        wait;
    end process;

end sim;
