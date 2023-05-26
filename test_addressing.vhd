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
    signal clk, res, en, busy, rw_n, sda, scl : std_logic := '0';
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
        wait for 9 ns;
        en <= '1';
        data <= "00000001";
        addr <= "0000001";
        rw_n <= '1';
        wait for 10 ns;
        wait for 100 ns;

    end process ; -- test_process
end Behavioral;
