----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 23.03.2026 17:52:31
-- Design Name: 
-- Module Name: mandelbrot_stage - rtl
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


entity mandelbrot_stage is
    generic (
        ESCAPE_MAGNITUDE : integer := 1073741824 -- escape condition integer 4 in Q4.28 format
    );
    port (
        clk_i : in std_logic;
        
        -- from last stage
        z_re_in, z_im_in : in signed(31 downto 0);
        c_re_in, c_im_in : in signed(31 downto 0); -- (c = c_re + i * c_im) from coord mapper both in Q4.28 format        
        ce_in : in std_logic; -- escape check
        iter_count_in : in unsigned(7 downto 0); -- mapped to pixel colour values (take bottom 4 bits of iter_count )(mod 16)

        -- to next stage
        z_re_out, z_im_out : out signed(31 downto 0);
        c_re_out, c_im_out : out signed(31 downto 0);
        ce_out : out std_logic;
        iter_count_out : out unsigned(7 downto 0)
    );
end mandelbrot_stage;

architecture rtl of mandelbrot_stage is
begin

    process (clk_i)
        -- implementing z(n + 1) = z(n)^2 + c
        variable z_re_new, z_im_new : signed(31 downto 0); -- Q8.56
        
        variable z_re_im : signed(63 downto 0); -- Q8.56
        variable z_re_sq, z_im_sq : signed(63 downto 0); -- Q8.56 
        variable z_magnitude : signed(32 downto 0); -- z_re^2 + z_im^2 in Q4.28 
        
        attribute use_dsp : string;
        attribute use_dsp of z_re_sq : variable is "yes";
        attribute use_dsp of z_im_sq : variable is "yes";
        attribute use_dsp of z_re_im : variable is "yes";
    begin
        
        if rising_edge(clk_i) then
            -- c doesnt change, just gets passed along stages
            c_re_out <= c_re_in;
            c_im_out <= c_im_in;
            
            if (ce_in = '0') then
                z_re_sq := z_re_in * z_re_in;
                z_im_sq := z_im_in * z_im_in;
                z_re_im := z_re_in * z_im_in;
                z_magnitude := resize(z_re_sq(59 downto 28), 33) + resize(z_im_sq(59 downto 28), 33);
                z_re_new := z_re_sq(59 downto 28) - z_im_sq(59 downto 28) + c_re_in;
                z_im_new := shift_left(z_re_im(59 downto 28), 1) + c_im_in;
                
                if (z_magnitude >= to_signed(ESCAPE_MAGNITUDE, 33)) then -- escape
                    ce_out <= '1';
                else
                    ce_out <= ce_in; -- '0'
                end if;
                
                z_re_out <= z_re_new;
                z_im_out <= z_im_new;
                
                iter_count_out <= iter_count_in + 1;
            else
                ce_out <= ce_in; -- keep it tied to '1' if already there
                iter_count_out <= iter_count_in;
                z_re_out <= z_re_in;
                z_im_out <= z_im_in;
            end if;
        end if;
    end process;


end rtl;
