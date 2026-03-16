----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 16.03.2026 13:32:40
-- Design Name: 
-- Module Name: UART_TX - rtl
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity UART_TX is
    generic (
        CLK_DIV : integer := 868-- 100 MHz / 115200 baud = 868 clock cycles per bit
    );
    
    port (
        clk_i : in std_logic;
        reset : in std_logic;
        tx_start : in std_logic;
        data_i : in std_logic_vector(7 downto 0);
        data_o : out std_logic
    );
end UART_TX;

architecture rtl of UART_TX is
    signal clk_enable : std_logic := '0';
    
    signal data_ind : integer := 0; -- index of data out being sent
    signal data_ind_reset : std_logic := '0';
    signal buf_data_i : std_logic_vector(7 downto 0) := (others => '0');
    
    signal start_detected : std_logic := '0'; -- once you start processing data, dont receive any more
    signal start_reset : std_logic := '0'; -- reset from fsm
    
    type state_t is (ST_IDLE, ST_START, ST_DATA, ST_STOP);
    signal state_r : state_t := ST_IDLE;
begin

    -- set clk_enable high every 868 clock cycles
    process (clk_i)
        variable clk_cycles : integer range 0 to (CLK_DIV - 1) := (CLK_DIV - 1);
    begin
        if rising_edge(clk_i) then
            if (reset = '1') then
                clk_enable <= '0';
                clk_cycles := CLK_DIV - 1;
            else 
                if (clk_cycles = 0) then
                    clk_enable <= '1';
                    clk_cycles := CLK_DIV - 1;
                else 
                    clk_enable <= '0';
                    clk_cycles := clk_cycles - 1;
                end if;
            end if;
        end if;
    end process;
    
    -- detect starting edge
    process (clk_i)
    begin
        if rising_edge(clk_i) then
            if (reset = '1') or (start_reset = '1') then
                start_detected <= '0';
            elsif (tx_start = '1') and (start_detected = '0') then 
                start_detected <= '1';
                buf_data_i <= data_i;
            end if;        
        end if;
    end process;
    
    -- increment data index
    process (clk_i)
    begin
        if rising_edge(clk_i) then
            if (reset = '1') or (data_ind_reset = '1') then
                data_ind <= 0;
            elsif (clk_enable = '1') then 
                data_ind <= data_ind + 1;
            end if;
        end if;
    end process;
    

    process (clk_i)
    begin
        if rising_edge(clk_i) then
            if (reset = '1') then
                state_r <= ST_IDLE;
                start_reset <= '1'; --hold resets
                data_ind_reset <= '1';
                data_o <= '1'; --set out high
            else
                data_ind_reset <= '0';
                start_reset <= '0';
                if (clk_enable = '1') then
                    case state_r is
                        when ST_IDLE =>
                            data_o <= '1';
                            if (start_detected = '1') then 
                                state_r <= ST_START;
                            end if;
                        when ST_START =>
                            data_ind_reset <= '1'; -- start incrementing
                            data_o <= '0'; --start bit
                            state_r <= ST_DATA;
                        when ST_DATA =>
                            data_o <= buf_data_i(data_ind); -- send one bit every 868 clock cycles
                            if (data_ind = 7) then -- only sending one byte
                                data_ind_reset <= '1';
                                state_r <= ST_STOP;
                            end if;
                        when ST_STOP =>
                            data_o <= '1'; -- stop bit
                            start_reset <= '1';
                            state_r <= ST_IDLE;
                        when others =>
                            state_r <= ST_IDLE;
                    end case;   
                end if;
            end if;     
        end if;
    end process;

end rtl;
