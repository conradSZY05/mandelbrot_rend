----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 19.03.2026 19:21:17
-- Design Name: 
-- Module Name: mandelbrot_iter - rtl
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


entity mandelbrot_iter is
    generic (
        MAX_ITERATION : integer := 255;
        ESCAPE_MAGNITUDE : integer := 1073741824 -- escape condition integer 4 in Q4.28 format
    );  
    port (
        clk_i : in std_logic;
        start : in std_logic;
        reset : in std_logic;
        c_re, c_im : in signed(31 downto 0); -- (c = c_re + i * c_im) from coord mapper both in Q4.28 format
       
        
        iter_count_o : out std_logic_vector(3 downto 0); -- mapped to pixel colour values (take bottom 4 bits of iter_count )(mod 16)
        done : out std_logic := '0'
    );
end mandelbrot_iter;

architecture rtl of mandelbrot_iter is
    signal iter_count : integer := 0;
    
    type iterator_state_t is (ST_IDLE, ST_ITER, ST_CALC, ST_CHECK, ST_DONE);
    signal state_r : iterator_state_t := ST_IDLE;
    
    -- implementing z(n + 1) = z(n)^2 + c
    signal z_re, z_im : signed(31 downto 0) := (others => '0'); -- Q8.56
    signal z_re_new, z_im_new : signed(31 downto 0); -- Q8.56
    
    signal z_re_im : signed(63 downto 0); -- Q8.56
    signal z_re_sq, z_im_sq : signed(63 downto 0); -- Q8.56 
    signal z_magnitude : signed(32 downto 0); -- z_re^2 + z_im^2 in Q4.28 
    

begin

    process (clk_i) 
    begin
        if rising_edge(clk_i) then
            if (reset = '1') then
                done <= '0';
                z_re <= (others => '0');
                z_im <= (others => '0');
                iter_count <= 0;
            end if;
            case state_r is
                when ST_IDLE =>
                    if (start = '1') then
                        done <= '0'; -- DONE NEEDS TO BE HERE TO CLEAR AND PREVENT DUPLICATES
                        -- reset before iterating
                        z_re <= (others => '0');
                        z_im <= (others => '0');
                        iter_count <= 0;
                        state_r <= ST_ITER;
                    end if;
                when ST_ITER =>
                    z_re_sq <= z_re * z_re;
                    z_im_sq <= z_im * z_im;
                    z_re_im <= z_re * z_im;
                    state_r <= ST_CALC;
                when ST_CALC =>
                    z_magnitude <= resize(z_re_sq(59 downto 28), 33) + resize(z_im_sq(59 downto 28), 33);
                    z_re_new <= z_re_sq(59 downto 28) - z_im_sq(59 downto 28) + c_re;
                    z_im_new <= shift_left(z_re_im(59 downto 28), 1) + c_im;
                    state_r <= ST_CHECK;
                when ST_CHECK =>
                    -- check escape condition
                    if (iter_count >= MAX_ITERATION) or (z_magnitude >= to_signed(ESCAPE_MAGNITUDE, 32)) then
                        state_r <= ST_DONE;
                    else 
                        iter_count <= iter_count + 1;
                        z_re <= z_re_new;
                        z_im <= z_im_new;
                        state_r <= ST_ITER;
                    end if;
                when ST_DONE =>
                    done <= '1';

                    iter_count_o <= std_logic_vector(to_unsigned(iter_count, 4)); -- take bottom 4 bits
                    state_r <= ST_IDLE;
                when others => 
                    state_r <= ST_IDLE;
             end case;
        end if;
    end process;

end rtl;
