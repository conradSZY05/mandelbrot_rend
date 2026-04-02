----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 23.03.2026 18:23:10
-- Design Name: 
-- Module Name: mandelbrot_pipelined - rtl
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


entity mandelbrot_pipelined is
    generic (
        MAX_ITERATION : integer := 16
    );
    port (
        clk_i : in std_logic;
        c_re_in, c_im_in : in signed(31 downto 0);
        
        ce_o : out std_logic; -- check escaped
        iter_count_o : out std_logic_vector(3 downto 0) -- mapped to pixel colour values (take bottom 4 bits of iter_count )(mod 16)
    );  
end mandelbrot_pipelined;

architecture rtl of mandelbrot_pipelined is
    type pipe_re_t is array(0 to MAX_ITERATION) of signed(31 downto 0);
    signal pipe_z_re : pipe_re_t;
    signal pipe_c_re : pipe_re_t;
    
    type pipe_im_t is array(0 to MAX_ITERATION) of signed(31 downto 0);
    signal pipe_z_im : pipe_im_t;
    signal pipe_c_im : pipe_im_t;
    
    type ce_t is array(0 to MAX_ITERATION) of std_logic;
    signal pipe_ce : ce_t;
    
    type iter_count_t is array(0 to MAX_ITERATION) of unsigned(7 downto 0);
    signal pipe_iter_count : iter_count_t;
begin

    -- initial values
    pipe_z_re(0) <= (others => '0');
    pipe_z_im(0) <= (others => '0');
    pipe_c_re(0) <= c_re_in;
    pipe_c_im(0) <= c_im_in;
    pipe_ce(0) <= '0';
    pipe_iter_count(0) <= (others => '0');
    
    gen : for i in 0 to MAX_ITERATION - 1 generate
        stage : entity work.mandelbrot_stage
            port map (
                clk_i => clk_i,
                z_re_in => pipe_z_re(i),
                z_im_in => pipe_z_im(i),
                c_re_in => pipe_c_re(i),
                c_im_in => pipe_c_im(i),
                ce_in => pipe_ce(i),
                iter_count_in => pipe_iter_count(i),
                z_re_out => pipe_z_re(i+1),
                z_im_out => pipe_z_im(i+1),
                c_re_out => pipe_c_re(i+1),
                c_im_out => pipe_c_im(i+1),
                ce_out => pipe_ce(i+1),
                iter_count_out => pipe_iter_count(i+1)
            );
    end generate;
    
    iter_count_o <= std_logic_vector(pipe_iter_count(MAX_ITERATION)(3 downto 0));
    ce_o <= pipe_ce(MAX_ITERATION);


end rtl;
