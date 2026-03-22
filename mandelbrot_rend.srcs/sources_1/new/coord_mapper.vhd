----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 19.03.2026 19:21:32
-- Design Name: 
-- Module Name: coord_mapper - rtl
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


-- mandelbrot set is between -2.5 and 1.0 for Re, and -1.2 to 1.2 for Im
entity coord_mapper is
    generic (
        -- Q4.28 format 
        X_MIN_LIMIT : integer := -671088640; -- -2.5
        X_MAX_LIMIT : integer := 268435456; --  1.0
        Y_MIN_LIMIT : integer := -322122547; -- -1.2
        Y_MAX_LIMIT : integer := 322122547; --  1.2
        
        X_STEP_LIMIT : integer := 1468006; -- 3.5 / 640
        Y_STEP_LIMIT : integer := 1342177 -- 2 / 480
    );
    port (
        clk_i : in std_logic; -- 100 NHz
        valid : in std_logic; -- from uart
        uart_comm : in std_logic_vector(7 downto 0);
        
        px, py : in std_logic_vector(9 downto 0); -- pixel coordinates 640 x 480
        re, im : out signed(31 downto 0)
    );
end coord_mapper;

architecture rtl of coord_mapper is
    -- 32 word size, 4 integer bits 28 fractional
    signal x_min : signed(31 downto 0) := to_signed(X_MIN_LIMIT, 32); -- -2.5 * 2^28 
    signal x_max : signed(31 downto 0) := to_signed(X_MAX_LIMIT, 32);
    signal y_min : signed(31 downto 0) := to_signed(Y_MIN_LIMIT, 32);
    signal y_max : signed(31 downto 0) := to_signed(Y_MAX_LIMIT, 32);
    
    signal x_range : signed(31 downto 0);
    signal y_range : signed(31 downto 0);
    signal x_step : signed(31 downto 0) := to_signed(X_STEP_LIMIT, 32);
    signal y_step : signed(31 downto 0) := to_signed(Y_STEP_LIMIT, 32);
    signal px_mult : signed(42 downto 0); -- Q11.0 * Q4.28 = Q14.28 (43 bit total, want 31 downto 0)
    signal py_mult : signed(42 downto 0);
    
    -- panning
    signal pan_amount_x : signed(31 downto 0);
    signal pan_amount_y : signed(31 downto 0);
    
    -- zooming
    signal sum_x : signed(31 downto 0);
    signal centre_x : signed(31 downto 0);
    signal new_range_x : signed(31 downto 0);
    signal sum_y : signed(31 downto 0);
    signal centre_y : signed(31 downto 0);
    signal new_range_y : signed(31 downto 0);
    
    -- lock to limits
    
begin
    x_range <= x_max - x_min;
    y_range <= y_max - y_min;
    
    -- pan_amount should be 1/16 of the range, so 16 pans is one full screen 
    pan_amount_x <= shift_right(x_range, 4);
    pan_amount_y <= shift_right(y_range, 4);
    
    px_mult <= ('0' & to_signed(to_integer(unsigned(px)), 10)) * x_step;
    py_mult <= ('0' & to_signed(to_integer(unsigned(py)), 10)) * y_step;
    
    re <= x_min + px_mult(31 downto 0);
    im <= y_min + py_mult(31 downto 0);
    
    sum_x <= x_max + x_min;
    centre_x <= shift_right(sum_x, 1);
    new_range_x <= shift_right(x_range, 1);
    sum_y <= y_max + y_min;
    centre_y <= shift_right(sum_y, 1);
    new_range_y <= shift_right(y_range, 1);
    
    
    -- process uart commands
    process (clk_i)
    begin
        if rising_edge(clk_i) then
            if (valid = '1') then
                case uart_comm is
                    -- pan up 'U'
                    when "01010101" => y_min <= y_min - pan_amount_y;
                                       y_max <= y_max - pan_amount_y;
                    -- pan down 'D'
                    when "01000100" => y_min <= y_min + pan_amount_y;
                                       y_max <= y_max + pan_amount_y;
                    -- pan left 'L'
                    when "01001100" => x_min <= x_min - pan_amount_x;
                                       x_max <= x_max - pan_amount_x;
                    -- pan right 'R'
                    when "01010010" => x_min <= x_min + pan_amount_x;
                                       x_max <= x_max + pan_amount_x;
                    -- zoom in 'i'
                    when "01101001" => x_min <= centre_x - shift_right(new_range_x, 1); -- offset
                                       x_max <= centre_x + shift_right(new_range_x, 1);
                                       x_step <= shift_right(x_step, 1); -- half step
                                       y_min <= centre_y - shift_right(new_range_y, 1);
                                       y_max <= centre_y + shift_right(new_range_y, 1);
                                       y_step <= shift_right(y_step, 1);
                    -- zoom out 'o'
                    when "01101111"	=> x_min <= centre_x - x_range; -- offset
                                       x_max <= centre_x + x_range;
                                       x_step <= shift_left(x_step, 1); -- double step
                                       y_min <= centre_y - y_range;
                                       y_max <= centre_y + y_range;
                                       y_step <= shift_left(y_step, 1);
                    when others => null;
                end case;
            end if;
        end if;
    end process;
    
end rtl;
