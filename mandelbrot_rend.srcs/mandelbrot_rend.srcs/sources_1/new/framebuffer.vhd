----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 18.03.2026 19:54:06
-- Design Name: 
-- Module Name: framebuffer - rtl
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

entity framebuffer is
    generic (
        ADDRESSES : integer := 307200 -- 640x480 number of pixels
    );
    port (
        clk_write : in std_logic; -- 100 MHz
        wr_en_a : in std_logic; -- write enable
        addr_a : in std_logic_vector(18 downto 0); -- addresses for 307200 locations
        di_a : in std_logic_vector(3 downto 0); -- write data in 4 bits per pixel
        
        clk_read : in std_logic; -- 25.125 MHz
        addr_b : in std_logic_vector(18 downto 0);
        do_b : out std_logic_vector(3 downto 0) -- read data out
    );
end framebuffer;

-- 640 x 480 = 307200 pixels total
-- 307200 x 4 bits = 1228800 bits needed
-- write on 100 MHz, read on 25.125 MHz
architecture rtl of framebuffer is
    type ramtype is array(0 to ADDRESSES - 1) of std_logic_vector(3 downto 0);
    signal mem_ram : ramtype;
begin

    -- write only a port at 100 MHz
    process (clk_write)
    begin
        if rising_edge(clk_write) then
            if (wr_en_a = '1') then
                mem_ram(to_integer(unsigned(addr_a))) <= di_a;
            end if;
        end if;
    end process;
    
    -- read only b port at 25.125 MHz
    process (clk_read)
    begin
        if rising_edge(clk_read) then
            do_b <= mem_ram(to_integer(unsigned(addr_b)));
        end if;
    end process;

end rtl;
