----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 22.03.2026 15:22:22
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
    signal enable : std_logic := '0';
    signal valid : std_logic := '0';
    signal uart_comm : std_logic_vector(7 downto 0);
    signal re_render : std_logic; -- reset on power on, uart command
    signal addr : std_logic_vector(18 downto 0);
    signal wr_en : std_logic;
    signal di : std_logic_vector(3 downto 0);
begin
    clk <= not clk after CLK_PERIOD / 2;
    
    uut : entity work.mandelbrot_top 
        port map (
            clk_i => clk,
            enable => enable,
            valid => valid,
            uart_comm => uart_comm,
            re_render => re_render,
            addr => addr,
            wr_en => wr_en,
            di => di
        );

    process
    begin
        wait for CLK_PERIOD * 7;
        
        re_render <= '1';
        wait for CLK_PERIOD;
        re_render <= '0';
        wait for CLK_PERIOD;
        
        enable <= '1';
        
        wait;
    end process;

end sim;
