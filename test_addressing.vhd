----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/25/2023 04:00:36 PM
-- Design Name: 
-- Module Name: test_addressing - Behavioral
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

entity test_addressing is
--  Port ( );
end test_addressing;

architecture Behavioral of test_addressing is
    signal clk, res, en, busy, error, rw_n, sda, scl : std_logic := '0';
    signal addr : std_logic_vector(6 downto 0) := (others => '0');
    signal data, data_rd : std_logic_vector(7 downto 0) := (others => '0');
begin
    dut : entity work.I2C_driver
    port map(
        clk => clk, 
        res => res,
        en => en,
        rw_n => rw_n,
        d_in => data,
        addr_in => addr,
        d_out => data_rd,
        busy => busy,
        error => error,
        sda => sda,
        scl => scl
    );
    clk_gen : process    begin
        clk <= '1'; wait for 5 ns;
        clk <= '0'; wait for 5 ns;
    end process ; -- clk_gen

    res_gen : process begin
        res <= '0';
        wait for 10 ns;
        res <= '1';
        wait;
    end process ; -- res

    test_process : process begin
        sda <= 'Z';
        wait for 9 ns;
        
        --Transizione in scrittura con ACK
        en <= '1';
        data <= "00000001";
        addr <= "1001111";
        rw_n <= '0';
        while busy = '0' loop
            wait for 1 ns;
        end loop ; -- attendo_busy
        en <= '0';
        wait for 21 us;
        en <= '0';
        sda <= '0'; -- ACK for address
        wait for 2130 ns;
        sda <= 'Z';
        wait for 21 us;
        sda <= '0'; -- ACK for data
        wait for 2100 ns;
        sda <= 'Z';

        -- --Transizione in lettura con ACK
        -- en <= '1';
        -- data <= "00000001";
        -- addr <= "1001111";
        -- rw_n <= '1';
        -- while busy = '0' loop
        --     wait for 1 ns;
        -- end loop ; -- attendo_busy
        -- en <= '0';
        -- wait for 21 us;
        -- en <= '0';
        -- sda <= '0'; -- ACK
        -- wait for 2300 ns;
        -- sda <= 'Z';
        -- wait for 2 us;

        -- --Transizione in lettura con NACK
        -- en <= '1';
        -- data <= "00000001";
        -- addr <= "1001111";
        -- rw_n <= '1';
        -- while busy = '0' loop
        --     wait for 1 ns;
        -- end loop ;
        -- en <= '0';

        -- wait for 21 us;
        -- sda <= '1'; -- NACK
        -- wait for 2300 ns;
        -- sda <= 'Z';
        -- wait for 2 us;
            
            
        -- --Transizione in scrittura con NACK
        -- en <= '1';
        -- data <= "00000001";
        -- addr <= "1001111";
        -- rw_n <= '0';
        -- while busy = '0' loop
        --     wait for 1 ns;
        -- end loop ;
        -- en <= '0';

        -- wait for 21 us;
        -- sda <= '1'; -- NACK
        -- wait for 2300 ns;
        -- sda <= 'Z';
        -- wait for 2 us;

        wait;
    end process ; -- test_process

    --scl <= '1' when scl = 'Z' else '0';
end Behavioral;
