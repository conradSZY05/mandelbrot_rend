----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 17.03.2026 13:22:33
-- Design Name: 
-- Module Name: UART - rtl
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

entity UART is
    port (
        clk : in std_logic;
        reset : in std_logic;
        rx : in std_logic;
        data_o : out std_logic_vector(7 downto 0)
    );
end UART;

architecture rtl of UART is
    signal valid_o : std_logic;
begin

    receiver : entity work.UART_RX
        port map (
            clk_i => clk,
            reset => reset,
            data_i => rx,
            data_o => data_o,
            valid_o => valid_o
        );

end rtl;
