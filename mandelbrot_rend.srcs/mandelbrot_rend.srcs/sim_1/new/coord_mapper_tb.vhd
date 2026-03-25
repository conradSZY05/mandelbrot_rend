----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 20.03.2026 16:12:39
-- Design Name: 
-- Module Name: coord_mapper_tb - sim
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

entity coord_mapper_tb is
end coord_mapper_tb;

architecture sim of coord_mapper_tb is
    constant CLK_PERIOD : time := 10 ns;
    signal clk_i : std_logic := '0';
    signal valid : std_logic := '1';
    signal uart_comm : std_logic_vector(7 downto 0);
    signal px, py : std_logic_vector(9 downto 0);
    signal re, im : signed(31 downto 0);
begin
    uut : entity work.coord_mapper
        port map (
            clk_i => clk_i,
            valid => valid,
            uart_comm => uart_comm,
            px => px,
            py => py,
            re => re,
            im => im
        );
        
    clk_i <= not clk_i after CLK_PERIOD / 2;

    process 
    begin
        px <= (others => '0');
        py <= (others => '0');
        wait for CLK_PERIOD * 2;
        -- re = -2.5 and im = -1.2
        
        px <= std_logic_vector(to_unsigned(639, 10));
        py <= std_logic_vector(to_unsigned(479, 10));
        wait for CLK_PERIOD * 2;
        -- re = 1.0 and im = 1.2
        
        -- pan right
        uart_comm <= "01010010";
        wait for CLK_PERIOD * 2;
        -- x_min and x_max should incremenet by pan_amount
        
        -- zoom in
        uart_comm <= "01101001";
        wait for CLK_PERIOD * 2;
        -- range half, step half, centre same
        
        -- zoom out
        uart_comm <= "01101111";
        wait for CLK_PERIOD * 2;
        -- range double, step double, centre same
              
              
        wait;
    end process;
    
end sim;
