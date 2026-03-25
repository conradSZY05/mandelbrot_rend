----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 23.03.2026 19:02:58
-- Design Name: 
-- Module Name: mandelbrot_top_pipelined - rtl
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


entity mandelbrot_top_pipelined is
    generic (
        MAX_PX : integer := 639;
        MAX_PY : integer := 479;
        MAX_ITERATION : integer := 16
    );
    port (
        clk_i : in std_logic;
        enable : in std_logic;
        valid : in std_logic;
        uart_comm : in std_logic_vector(7 downto 0);
        re_render : in std_logic; -- reset on power on, uart command
        
        -- writing to framebuffer
        addr : out std_logic_vector(18 downto 0);
        wr_en : out std_logic;
        di : out std_logic_vector(3 downto 0)
    );
end mandelbrot_top_pipelined;

architecture rtl of mandelbrot_top_pipelined is
    signal px, py : std_logic_vector(9 downto 0) := (others => '0');
    signal re, im : signed(31 downto 0) := (others => '0');
    signal iter_count : std_logic_vector(3 downto 0);
    signal done : std_logic := '0';
    
    signal ce : std_logic;
    signal latency_count : integer := 0;
    
    type px_delay_t is array(0 to MAX_ITERATION) of std_logic_vector(9 downto 0);
    signal px_delay : px_delay_t;
    signal py_delay : px_delay_t;
begin

    mapper : entity work.coord_mapper 
        port map (
            clk_i => clk_i,
            valid => valid,
            uart_comm => uart_comm,
            px => px,
            py => py,
            re => re,
            im => im
        );
        
    pipeline : entity work.mandelbrot_pipelined
        port map (
            clk_i => clk_i,
            c_re_in => re,
            c_im_in => im,
            ce_o => ce,
            iter_count_o => iter_count
        );

    process (clk_i)
    begin
        if rising_edge(clk_i) then
            wr_en <= '0';
            -- always increment px and py even when filling pipeline
            if (px = std_logic_vector(to_unsigned(MAX_PX, 10))) then
                px <= (others => '0');
                if (py = std_logic_vector(to_unsigned(MAX_PY, 10))) then
                    py <= (others => '0');
                else
                    py <= std_logic_vector(unsigned(py) + 1);
                end if;
            else
                px <= std_logic_vector(unsigned(px) + 1);
            end if;
            -- delay px and py by MAX_ITERATION
            px_delay(0) <= px;
            py_delay(0) <= py;
            for i in 1 to MAX_ITERATION loop
                px_delay(i) <= px_delay(i-1);
                py_delay(i) <= py_delay(i-1);
            end loop;
            
            
            if (re_render = '1') then
                px <= (others => '0');
                py <= (others => '0');
                latency_count <= 0;
                wr_en <= '0';
            elsif (latency_count >= MAX_ITERATION - 1) then -- let pipeline fill
                wr_en <= '1';
                di <= iter_count;
               
                addr <= std_logic_vector(shift_left(resize(unsigned(py_delay(MAX_ITERATION)), 19), 9) 
                        + shift_left(resize(unsigned(py_delay(MAX_ITERATION)), 19), 7) 
                        + resize(unsigned(px_delay(MAX_ITERATION)), 19));
            else 
                latency_count <= latency_count + 1;
            end if;
        end if;
    end process;    

end rtl;
