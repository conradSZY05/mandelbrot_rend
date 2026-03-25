----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 18.03.2026 19:38:23
-- Design Name: 
-- Module Name: VGA_controller - rtl
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

entity VGA_controller is
    generic (
        HOR_ACTIVE : integer := 640;
        HOR_FP : integer := 16; -- front porch
        HOR_SP : integer := 96; -- sync pulse
        HOR_BP : integer := 48; -- back porch
        
        VER_ACTIVE : integer := 480;
        VER_FP : integer := 10;
        VER_SP : integer := 2;
        VER_BP : integer := 33
    );
    port (
        pixel_clk : in std_logic; -- 25.125 MHz pixel clock from clocking wizard
        reset : in std_logic;

        x_pixel : out std_logic_vector(9 downto 0); -- 0 to 639 (active area)
        y_pixel : out std_logic_vector(9 downto 0); -- 0 to 479 (active area)
        h_sync, v_sync : out std_logic; -- active LOW
        display_active : out std_logic
    );
end VGA_controller;

architecture rtl of VGA_controller is
    constant HOR_TOTAL : integer := HOR_ACTIVE + HOR_FP + HOR_SP + HOR_BP;
    constant VER_TOTAL : integer := VER_ACTIVE + VER_FP + VER_SP + VER_BP;
    
    signal h_count : integer range 0 to (HOR_TOTAL - 1) := 0; -- active area is 0 to 640
    signal v_count : integer range 0 to (VER_TOTAL - 1) := 0; -- active area is 0 to 480
    
begin

    display_active <= '1' when (h_count < HOR_ACTIVE) and (v_count < VER_ACTIVE) else '0'; -- only display when within active area 640x480
    h_sync <= '0' when (h_count >= HOR_ACTIVE + HOR_FP) and (h_count < HOR_ACTIVE + HOR_FP + HOR_SP) else '1';
    v_sync <= '0' when (v_count >= VER_ACTIVE + VER_FP) and (v_count < VER_ACTIVE + VER_FP + VER_SP) else '1';
    
    x_pixel <= std_logic_vector(to_unsigned(h_count, 10)) when (h_count < HOR_ACTIVE) and (v_count < VER_ACTIVE) else (others => '0'); -- only need x and y pixels during active region
    y_pixel <= std_logic_vector(to_unsigned(v_count, 10)) when (v_count < VER_ACTIVE) and (h_count < HOR_ACTIVE) else (others => '0'); -- prevents issues with checking display_active first etc

    process (pixel_clk)
    begin
        if rising_edge(pixel_clk) then
            if(reset = '1') then
                h_count <= 0;
                v_count <= 0;
            else 
                if (h_count = HOR_TOTAL - 1) then
                    h_count <= 0;
                    if (v_count = VER_TOTAL - 1) then
                        v_count <= 0;
                    else 
                        v_count <= v_count + 1; -- counts complete horizontals
                    end if;
                else
                    h_count <= h_count + 1;
                end if; 
            end if;
        end if;
    end process;

end rtl;
