----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 18.03.2026 20:07:36
-- Design Name: 
-- Module Name: top - rtl
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

entity top is
    port (
        clk_i_100 : in std_logic; -- 100 MHz clock from Basys 3 
        reset : in std_logic;
        mode_change : in std_logic;
        -- UART
        rx : in std_logic;
        data_o_uart : out std_logic_vector(7 downto 0);
        -- VGA
        vga_r, vga_g, vga_b : out std_logic_vector(3 downto 0);
        h_sync, v_sync : out std_logic
    );
end top;


architecture rtl of top is
    -- clocking wizard
    signal clk_o_25 : std_logic; -- 25.125 MHz pixel clock to controller
    signal locked : std_logic;
    -- VGA
    signal x_pixel : std_logic_vector(9 downto 0);
    signal y_pixel : std_logic_vector(9 downto 0);
    signal display_active : std_logic;
    signal display_active_r : std_logic;
    signal vga_reset : std_logic;
    -- framebuffer
    signal wr_en_a : std_logic;
    signal addr_a : std_logic_vector(18 downto 0);
    signal addr_b : std_logic_vector(18 downto 0);
    signal di_a : std_logic_vector(3 downto 0);
    signal do_b : std_logic_vector(3 downto 0);
    -- colour mapper
    signal rgb : std_logic_vector(11 downto 0);
    signal mode_change_o : std_logic := '0';
    signal re_render_sig : std_logic := '0';
    
    -- uart
    signal valid_o : std_logic;
    signal data_o : std_logic_vector(7 downto 0);
    
    component clk_wiz_0
        port (
          clk_out1          : out    std_logic;
          reset             : in     std_logic;
          locked            : out    std_logic;
          clk_in1           : in     std_logic
         );
    end component;
    
begin
    
    pixel_clk_wizard : clk_wiz_0
        port map ( 
            clk_out1 => clk_o_25,           
            reset => reset,
            locked => locked,
            clk_in1 => clk_i_100
        );
        
    vga_reset <= not locked;
    vga_controller : entity work.VGA_controller 
        port map (
            pixel_clk => clk_o_25,
            reset => vga_reset,
            x_pixel => x_pixel,
            y_pixel => y_pixel,
            h_sync => h_sync,
            v_sync => v_sync,
            display_active => display_active
        );
    data_o_uart <= data_o;
    uart_receiver : entity work.UART_RX
        port map (
            clk_i => clk_i_100,
            reset => reset,
            data_i => rx,
            data_o => data_o,
            valid_o => valid_o
        );
        
    framebuffer : entity work.framebuffer
        port map (
            clk_write => clk_i_100,
            wr_en_a => wr_en_a,
            addr_a => addr_a,
            di_a => di_a,
            clk_read => clk_o_25,
            addr_b => addr_b,
            do_b => do_b
        );
        
    colour_mapper : entity work.colour_mapper 
        port map (
            clk_i => clk_i_100,
            di => do_b,
            mode_change => mode_change_o,
            do => rgb
        );
        
    -- iterative version
    re_render_sig <= reset or mode_change_o;
    mandelbrot : entity work.mandelbrot_top
        port map (
            clk_i => clk_i_100,
            enable => '1',
            valid => valid_o,
            uart_comm => data_o,
            re_render => re_render_sig,
            addr => addr_a,
            wr_en => wr_en_a,
            di => di_a
        );
     
     -- pipelined version (doesnt work)
     --mandelbrot : entity work.mandelbrot_top_pipelined
        --port map (
            --clk_i => clk_i_100,
            --enable => '1',
            --valid => valid_o,
            --uart_comm => data_o,
            --re_render => reset,
            --addr => addr_a,
            --wr_en => wr_en_a,
            --di => di_a
        --);
        
    -- mode_change 
    process (clk_i_100) 
        variable last : std_logic := '0';
    begin
        if rising_edge(clk_i_100) then
            mode_change_o <= '0';
            if (mode_change = '1') and (last = '0') then
                mode_change_o <= '1';
            end if;
            last := mode_change;
        end if;
    end process;    
        
    -- frame buffer read is one cycle delayed frame buffer write, so account for delay and use display_active_r here
    process (clk_o_25)
    begin
        if rising_edge(clk_o_25) then
            display_active_r <= display_active;
        end if;
    end process;
    
    -- addr_b = y_pixel * 640 + x_pixel
    addr_b <= std_logic_vector(to_unsigned(to_integer(unsigned(y_pixel)) * 640 + to_integer(unsigned(x_pixel)), 19));
        
    -- test values    
    --vga_r <= x_pixel(9 downto 6) when display_active = '1' else "0000";
    --vga_g <= y_pixel(9 downto 6) when display_active = '1' else "0000";
    --vga_b <= (others => '1')     when display_active = '1' else "0000";
    
    
    vga_r <= rgb(11 downto 8) when (display_active_r = '1') else (others => '0');
    vga_g <= rgb(7 downto 4) when (display_active_r = '1') else (others => '0');
    vga_b <= rgb(3 downto 0) when (display_active_r = '1') else (others => '0');
    
    
end rtl;
