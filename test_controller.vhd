----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/27/2023 11:42:39 PM
-- Design Name: 
-- Module Name: test_controller - Behavioral
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

entity test_controller is
--  Port ( );
end test_controller;

architecture Behavioral of test_controller is
    signal clk : STD_LOGIC := '0';                          --system clock
    signal SW1 : STD_LOGIC := '0';                          --asynchronous active-low reset
    signal pw_off : std_logic := '0';                       --PowerOff for Display
    signal JA3 : STD_LOGIC := '0';                          --I2C serial clock
    signal JA4 : STD_LOGIC := '0';                          --I2C serial data
    signal LED : STD_LOGIC_VECTOR(7 DOWNTO 0) := (others => '0');       --temperature value obtained
begin
    dut : entity work.I2C_temp_sensor_controller
    port map(
        CLK => clk,
        sw1 => sw1,
        pw_off => pw_off,
        JA3 => JA3,
        ja4 => ja4,
        led => led
    );

    clk_gen : process begin
        clk <= '1'; wait for 5 ns;
        clk <= '0'; wait for 5 ns;
    end process ; -- clk_gen

    test_pro : process
    begin
        sw1 <= '0';
        wait for 100 ns;
        sw1 <= '1';
        wait;

    end process ; -- test_pro
end Behavioral;
