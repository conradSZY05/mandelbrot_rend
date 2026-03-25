----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 22.03.2026 13:50:56
-- Design Name: 
-- Module Name: tb_mandelbrot_iter - sim
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
use IEEE.NUMERIC_STD.ALL;


entity tb_mandelbrot_iter is
end tb_mandelbrot_iter;

architecture sim of tb_mandelbrot_iter is
    constant CLK_PERIOD : time := 10 ns;
    -- in
    signal clk_i : std_logic := '0';
    signal start : std_logic;
    signal c_re, c_im : signed(31 downto 0);
    -- out
    signal iter_count_o : std_logic_vector(3 downto 0);
    signal done : std_logic;
begin
    uut : entity work.mandelbrot_iter
        port map (
            clk_i => clk_i,
            start => start,
            c_re => c_re,
            c_im => c_im,
            iter_count_o => iter_count_o,
            done => done
        );

    clk_i <= not clk_i after CLK_PERIOD / 2;

    process
    begin
        wait for CLK_PERIOD * 5;
       
        -- c = (0, 0) should reach MAX_ITERATION(never escapes)
        --c_re <= (others => '0');
        --c_im <= (others => '0');
        
        -- c = (2.0, 2.0) should escape on iteration 1
        --c_re <= to_signed(536870912, 32);
        --c_im <= to_signed(536870912, 32);
        
        -- c = (-0.5, 0.5) should escape slowly
        c_re <= to_signed(134217728, 32);
        c_im <= to_signed(-134217728, 32);
        
        start <= '1';
        wait for CLK_PERIOD;
        start <= '0';

    end process;
    
end sim;
