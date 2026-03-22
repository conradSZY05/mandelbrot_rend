----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 19.03.2026 19:21:04
-- Design Name: 
-- Module Name: mandelbrot_top - rtl
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

entity mandelbrot_top is
    generic (
        MAX_PX : integer := 639;
        MAX_PY : integer := 479
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
end mandelbrot_top;

architecture rtl of mandelbrot_top is
    type top_state_t is (ST_IDLE, ST_START, ST_WAIT, ST_WRITE, ST_NEXT);
    signal state_r : top_state_t := ST_IDLE;

    signal px, py : std_logic_vector(9 downto 0) := (others => '0');
    signal re, im : signed(31 downto 0) := (others => '0');
    signal start : std_logic := '0';
    signal iter_count : std_logic_vector(3 downto 0);
    signal done : std_logic := '0';
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
        
    iterator : entity work.mandelbrot_iter
        port map (
            clk_i => clk_i,
            start => start,
            c_re => re,
            c_im => im,
            iter_count_o => iter_count,
            done => done
        );

    process (clk_i)
    begin
        if rising_edge(clk_i) then
            wr_en <= '0';
            if (enable = '1') then 
                if (re_render = '1') or (valid = '1') then
                    state_r <= ST_START;
                    px <= (others => '0');
                    py <= (others => '0');
                    start <= '0';
                    wr_en <= '0';
                else
                    case state_r is
                        when ST_IDLE =>
                            px <= (others => '0');
                            py <= (others => '0');
                            state_r <= ST_START;
                        when ST_START =>
                            start <= '1';
                            state_r <= ST_WAIT;
                        when ST_WAIT => 
                            start <= '0';
                            if (done = '1') then
                                addr <= std_logic_vector(shift_left(resize(unsigned(py), 19), 9) + shift_left(resize(unsigned(py), 19), 7) + resize(unsigned(px), 19));
                                state_r <= ST_WRITE;
                            end if;
                        when ST_WRITE =>
                            -- calculate address(addr = py * 640 + px
                            wr_en <= '1';
                            di <= iter_count;
                            state_r <= ST_NEXT;
                        when ST_NEXT =>
                            wr_en <= '0';
                            if (px = std_logic_vector(to_unsigned(MAX_PX, 10))) then
                                px <= (others => '0');
                                if (py = std_logic_vector(to_unsigned(MAX_PY, 10))) then
                                    py <= (others => '0');
                                    state_r <= ST_IDLE;
                                else
                                    py <= std_logic_vector(unsigned(py) + 1);
                                    state_r <= ST_START;
                                end if;
                            else
                                px <= std_logic_vector(unsigned(px) + 1);
                                state_r <= ST_START;
                            end if;
                        when others =>
                            state_r <= ST_IDLE;
                    end case;
                end if;
            end if;
        end if;
    end process;
    
end rtl;
