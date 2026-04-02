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
        clk_i : in std_logic;
        di : in std_logic_vector(3 downto 0); -- do from framebuffer
        mode_change : in std_logic;
        do : out std_logic_vector(11 downto 0) -- rgb
    );
end colour_mapper;

architecture rtl of colour_mapper is
    type colour_mode_t is (DEF, BLACK, RED, ORANGE, GREEN, BLUE, PURPLE);
    signal colour_mode : colour_mode_t := DEF;
    
    type colour_map is array(0 to 15) of std_logic_vector(11 downto 0);
    
    constant def_map : colour_map := (
        x"F00", x"F20", x"F50", x"F80",
        x"FA0", x"FD0", x"CF0", x"8F0",
        x"4F0", x"0F4", x"0FA", x"8FF",
        x"CFF", x"FFF", x"444", x"000");
        
    constant black_map : colour_map := (
        x"111", x"222", x"333", x"444",
        x"555", x"666", x"777", x"888",
        x"999", x"AAA", x"BBB", x"CCC",
        x"DDD", x"EEE", x"FFF", x"000");
        
    constant red_map : colour_map := (
        x"200", x"400", x"600", x"800",
        x"A00", x"C00", x"E00", x"F00",
        x"F20", x"F40", x"F60", x"F80",
        x"FA0", x"FC8", x"FF8", x"000");
            
    constant orange_map : colour_map := (
        x"810", x"A20", x"C30", x"E40",
        x"F50", x"F60", x"F70", x"F80",
        x"F90", x"FA0", x"FC0", x"FD4",
        x"FE8", x"FF8", x"FFC", x"000");
        
    constant green_map : colour_map := (
        x"030", x"050", x"080", x"0A0",
        x"0C0", x"0F0", x"2F0", x"5F0",
        x"8F0", x"AF0", x"CF0", x"EF0",
        x"FF4", x"FF8", x"FFC", x"000");
        
    constant blue_map : colour_map := (
        x"008", x"00A", x"00C", x"00F",
        x"20F", x"40F", x"60F", x"80F",
        x"08F", x"0AF", x"0CF", x"0EF",
        x"4FF", x"8FF", x"CFF", x"000");
        
    constant purple_map : colour_map := (
        x"208", x"30A", x"40C", x"60F",
        x"80F", x"A0F", x"C0F", x"D2F",
        x"E4F", x"F6F", x"F8F", x"FAF",
        x"FCF", x"FEF", x"FFF", x"000");
        
    signal current_map : colour_map := def_map;
begin

    process (clk_i)
    begin
        if rising_edge(clk_i) then
            if (mode_change = '1') then
                case colour_mode is
                    when DEF =>
                        current_map <= black_map;
                        colour_mode <= BLACK;
                    when BLACK =>
                        current_map <= red_map;
                        colour_mode <= RED;
                    when RED =>
                        current_map <= orange_map;
                        colour_mode <= ORANGE;
                    when ORANGE =>
                        current_map <= green_map;
                        colour_mode <= GREEN;
                    when GREEN =>
                        current_map <= blue_map;
                        colour_mode <= BLUE;
                    when BLUE =>
                        current_map <= purple_map;
                        colour_mode <= PURPLE;
                    when PURPLE =>
                        current_map <= def_map;
                        colour_mode <= DEF;
                    when others =>
                        current_map <= def_map;
                        colour_mode <= DEF;
                end case;
            end if;
        end if;
    end process;    

    process (di)
    begin
        case di is
            when "0000" => do <= current_map(0);  
            when "0001" => do <= current_map(1); 
            when "0010" => do <= current_map(2);  
            when "0011" => do <= current_map(3);  
            when "0100" => do <= current_map(4); 
            when "0101" => do <= current_map(5);  
            when "0110" => do <= current_map(6);  
            when "0111" => do <= current_map(7);  
            when "1000" => do <= current_map(8);  
            when "1001" => do <= current_map(9);  
            when "1010" => do <= current_map(10);  
            when "1011" => do <= current_map(11);
            when "1100" => do <= current_map(12); 
            when "1101" => do <= current_map(13); 
            when "1110" => do <= current_map(14);
            when "1111" => do <= current_map(15);
            when others => do <= current_map(15);
        end case;
    end process;

end rtl;
