----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 18.03.2026 19:54:47
-- Design Name: 
-- Module Name: colour_mapper - rtl
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
--use IEEE.NUMERIC_STD.ALL;

entity colour_mapper is
    port ( 
        di : in std_logic_vector(3 downto 0); -- do from framebuffer
        do : out std_logic_vector(11 downto 0) -- rgb
    );
end colour_mapper;

architecture rtl of colour_mapper is
begin

    process (di)
    begin
        case di is
            when "0000" => do <= x"F00";  -- red 
            when "0001" => do <= x"F20";  -- 
            when "0010" => do <= x"F50";  -- orange
            when "0011" => do <= x"F80";  -- 
            when "0100" => do <= x"FA0";  -- 
            when "0101" => do <= x"FD0";  -- yellow
            when "0110" => do <= x"CF0";  -- 
            when "0111" => do <= x"8F0";  -- green
            when "1000" => do <= x"4F0";  -- 
            when "1001" => do <= x"0F4";  -- 
            when "1010" => do <= x"0FA";  -- teal
            when "1011" => do <= x"8FF";  -- light cyan
            when "1100" => do <= x"CFF";  -- 
            when "1101" => do <= x"FFF";  -- white
            when "1110" => do <= x"444";  -- dark grey
            when "1111" => do <= x"000";  -- black (inside set)
            when others => do <= x"000";
        end case;
    end process;

end rtl;
