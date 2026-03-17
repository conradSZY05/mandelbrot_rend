----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 16.03.2026 18:47:43
-- Design Name: 
-- Module Name: UART_RX - rtl
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

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity UART_RX is
    generic (
        CLK_DIV : integer := 54 -- (100 MHz / 115200 baud ) / 16 oversampling = 54.25
    );
    port (
        clk_i : in std_logic;
        reset : in std_logic;
        data_i : in std_logic;
        data_o : out std_logic_vector(7 downto 0);
        valid_o : out std_logic
    );
end UART_RX;

architecture rtl of UART_RX is
    signal clk_enable16x : std_logic := '0';

    type state_t is (ST_IDLE, ST_START, ST_DATA, ST_STOP);
    signal state_r : state_t := ST_IDLE;
    
    signal buf_data_i : std_logic_vector(7 downto 0) := (others => '0');
    
    signal start_detected : std_logic := '0';
    signal start_reset : std_logic := '0';
    
    signal bit_pos_counter : integer range 0 to 15 := 0;
    signal shift_count : integer range 0 to 8 := 0;
begin
    -- 16x oversampling
    process (clk_i)
        variable clk_cycles : integer := (CLK_DIV - 1); -- 868 clk divider oversampled 16x
    begin
        if rising_edge(clk_i) then
            if (reset = '1') then
                clk_enable16x <= '0';
                clk_cycles := (CLK_DIV - 1);
            else
                if (clk_cycles = 0) then
                    clk_enable16x <= '1';
                    clk_cycles := (CLK_DIV - 1);
                else 
                    clk_enable16x <= '0';
                    clk_cycles := clk_cycles - 1;
                end if;
            end if;
        end if;
    end process;
    
    -- increment counter for current sample
    process (clk_i)
    begin
        if rising_edge(clk_i) then
            if (reset = '1') then
                bit_pos_counter <= 0;
            else 
                if (clk_enable16x = '1') then
                    if (bit_pos_counter = 15) then
                        bit_pos_counter <= 0;
                    else
                        bit_pos_counter <= bit_pos_counter + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;
    
    -- detect start
    process (clk_i)
    begin
        if rising_edge(clk_i) then
            if (reset = '1') or (start_reset = '1') then
                start_detected <= '0';
            elsif (data_i = '0') and (start_detected = '0') and (state_r = ST_IDLE) then
                start_detected <= '1';
            end if;
        end if;
    end process;
    
    -- fsm
    process (clk_i)
    begin
        if rising_edge(clk_i) then
            if (reset = '1') then
                state_r <= ST_IDLE;
                start_reset <= '1';
                valid_o <= '0';
            else
                valid_o <= '0';
                start_reset <= '0';
                if (clk_enable16x = '1') then
                    case state_r is
                        when ST_IDLE =>
                            if (start_detected = '1') then
                                start_reset <= '1'; -- clear start_detected 
                                state_r <= ST_START;
                            end if;
                        when ST_START =>
                            if (bit_pos_counter = 6) then -- transition one tick early, prevents immediate sampling of data on transition to ST_DATA
                                shift_count <= 0;
                                state_r <= ST_DATA;
                            end if;
                        when ST_DATA =>
                            if (bit_pos_counter = 7) then 
                                -- lsb first, then shift right until 8 count
                                buf_data_i <= data_i & buf_data_i(7 downto 1);
                                shift_count <= shift_count + 1;
                                if (shift_count = 8) then
                                    state_r <= ST_STOP;
                                end if;
                            end if;
                        when ST_STOP =>
                            -- check for stop bit
                            if (bit_pos_counter = 7) then
                                shift_count <= 0;
                                if (data_i = '1') then
                                    data_o <= buf_data_i; -- final shift
                                    valid_o <= '1';
                                    buf_data_i <= (others => '0');
                                end if;
                                state_r <= ST_IDLE;
                                start_reset <= '1';
                            end if;
                        when others =>
                            state_r <= ST_IDLE;
                    end case;
                end if;
            end if; 
        end if;
    end process;
end rtl;
