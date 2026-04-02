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
        MAX_PY : integer := 479;
        NUM_CORES : integer := 5 -- this has to be a factor of the number of iterations, see ST_NEXT 
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
    type top_state_t is (ST_IDLE, ST_START, ST_WAIT, ST_WRITE, ST_WRITE_WAIT, ST_NEXT);
    signal state_r : top_state_t := ST_IDLE;
    
    type z_array_t is array(0 to NUM_CORES - 1) of signed(31 downto 0);
    signal core_re : z_array_t;
    signal core_im : z_array_t;
    
    type iter_count_t is array(0 to NUM_CORES - 1) of std_logic_vector(3 downto 0);
    signal core_iter_count : iter_count_t;
    
    type start_t is array(0 to NUM_CORES - 1) of std_logic;
    signal core_start : start_t;
    
    type reset_t is array(0 to NUM_CORES - 1) of std_logic;
    signal core_reset : reset_t;
    
    type done_t is array(0 to NUM_CORES - 1) of std_logic;
    signal core_done : done_t;
    
    type core_p_t is array(0 to NUM_CORES - 1) of std_logic_vector(9 downto 0);
    signal core_px : core_p_t;
    signal core_py : core_p_t;
    
    --signal px, py : std_logic_vector(9 downto 0) := (others => '0');
    --signal re, im : signed(31 downto 0) := (others => '0');
    --signal start : std_logic := '0';
    --signal iter_count : std_logic_vector(3 downto 0);
    --signal done : std_logic := '0';
    signal all_cores_done : std_logic := '0';
    
    signal core_write : integer range 0 to NUM_CORES - 1 := 0;
    
    function calculate_addr (
        px, py : in std_logic_vector(9 downto 0))
        return std_logic_vector is
        variable addr_temp : std_logic_vector(18 downto 0);
    begin
        addr_temp := std_logic_vector(shift_left(resize(unsigned(py), 19), 9) + shift_left(resize(unsigned(py), 19), 7) + resize(unsigned(px), 19));
        return std_logic_vector(addr_temp);
    end;
    
begin
        
    gen : for i in 0 to NUM_CORES - 1 generate
        iter_core : entity work.mandelbrot_iter
            port map (
                clk_i => clk_i,
                start => core_start(i),
                reset => core_reset(i),
                c_re => core_re(i),
                c_im => core_im(i),
                iter_count_o => core_iter_count(i),
                done => core_done(i)
            );
            
        mapper_core : entity work.coord_mapper 
        port map (
            clk_i => clk_i,
            valid => valid,
            uart_comm => uart_comm,
            px => core_px(i),
            py => core_py(i),
            re => core_re(i),
            im => core_im(i)
        );
    end generate;

    process (core_done)
        variable done_temp : std_logic;
    begin
        done_temp := '1';
        for i in 0 to NUM_CORES - 1 loop 
            done_temp := done_temp and core_done(i);
        end loop;
        all_cores_done <= done_temp;
    end process;

    process (clk_i)
    begin
        if rising_edge(clk_i) then
            wr_en <= '0';
            for i in 0 to NUM_CORES - 1 loop
                core_reset(i) <= '0';
            end loop;
            if (enable = '1') then 
                if (re_render = '1') or (valid = '1') then
                    state_r <= ST_START;
                    for i in 0 to NUM_CORES - 1 loop
                        core_px(i) <= std_logic_vector(to_unsigned(i, 10));
                        core_py(i) <= (others => '0');
                    end loop;
                    for i in 0 to NUM_CORES - 1 loop
                        core_start(i) <= '0';
                    end loop;
                    wr_en <= '0';
                else
                    case state_r is
                        when ST_IDLE =>
                            for i in 0 to NUM_CORES - 1 loop
                                core_px(i) <= std_logic_vector(to_unsigned(i, 10));
                                core_py(i) <= (others => '0');
                            end loop;
                            state_r <= ST_START;
                        when ST_START =>
                            -- pulse start for all cores
                            for i in 0 to NUM_CORES - 1 loop
                                core_start(i) <= '1';
                            end loop;
                            for i in 0 to NUM_CORES - 1 loop
                                core_reset(i) <= '0';
                            end loop;
                            state_r <= ST_WAIT;
                        when ST_WAIT => 
                            for i in 0 to NUM_CORES - 1 loop
                                core_start(i) <= '0';
                            end loop;
                            -- check if done (all cores done)
                            if (all_cores_done = '1') then
                                addr <= calculate_addr(core_px(core_write), core_py(core_write));
                                state_r <= ST_WRITE_WAIT; -- pre calculate first value, wait before writing to let address catch up since a cycle behind
                            end if;
                        when ST_WRITE =>
                            -- calculate address(addr = py * 640 + px
                            wr_en <= '1';
                            di <= core_iter_count(core_write); -- write to active core
                            addr <= calculate_addr(core_px(core_write), core_py(core_write));
                            -- write to cores sequentially when done but NUM_CORES delay :(
                            if (core_write = NUM_CORES - 1) then
                                core_write <= 0;
                                state_r <= ST_NEXT;
                            else
                                core_write <= core_write + 1;
                                state_r <= ST_WRITE_WAIT; -- give addr a chance to catch up because its a cycle behind
                            end if;
                        when ST_WRITE_WAIT =>
                                state_r <= ST_WRITE;
                        when ST_NEXT =>
                            for i in 0 to NUM_CORES - 1 loop
                                core_reset(i) <= '1';
                            end loop;
                            wr_en <= '0';
                            -- since the number of iterations is divisible by the number of cores, just check the last core
                            if (core_px(NUM_CORES - 1) = std_logic_vector(to_unsigned(MAX_PX, 10))) then
                                for i in 0 to NUM_CORES - 1 loop
                                    core_px(i) <= std_logic_vector(to_unsigned(i, 10));
                                end loop;
                                if (core_py(NUM_CORES - 1) = std_logic_vector(to_unsigned(MAX_PY, 10))) then
                                    for i in 0 to NUM_CORES - 1 loop
                                        core_py(i) <= (others => '0');
                                    end loop;
                                    state_r <= ST_IDLE;
                                else
                                    for i in 0 to NUM_CORES - 1 loop
                                        core_py(i) <= std_logic_vector(unsigned(core_py(i)) + 1);
                                    end loop;
                                    state_r <= ST_START;
                                end if;
                            else
                                for i in 0 to NUM_CORES - 1 loop
                                    core_px(i) <= std_logic_vector(unsigned(core_px(i)) + NUM_CORES);
                                end loop;
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