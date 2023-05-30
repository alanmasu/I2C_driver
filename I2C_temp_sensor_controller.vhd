----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/27/2023 01:41:10 PM
-- Design Name: 
-- Module Name: I2C_temp_sensor_controller - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity I2C_temp_sensor_controller is
    PORT(
        CLK : IN    STD_LOGIC;                          --system clock
        SW1 : IN    STD_LOGIC;                          --asynchronous active-low reset
        pw_off : in std_logic;                          --PowerOff for Display
        JA3 : INOUT STD_LOGIC;                          --I2C serial clock
        JA4 : INOUT STD_LOGIC;                          --I2C serial data
        LED : OUT   STD_LOGIC_VECTOR(7 DOWNTO 0);       --temperature value obtained
        oled_sdin : out std_logic;                      -- OLED SPI data out
        oled_sclk : out std_logic;                      -- OLED SPI clock
        oled_dc : out   std_logic;                      -- OLED data/command signal
        oled_res : out  std_logic;                      -- OLED reset signal
        oled_vbat : out std_logic;                      -- OLED Vbat enable
        oled_vdd : out  std_logic                       -- OLED Vdd enable

    );   
end I2C_temp_sensor_controller;

architecture Behavioral of I2C_temp_sensor_controller is
    TYPE machine IS(start, set_resolution, pause, read_data, output_result); --needed states
    signal state       : machine;                       --state machine
    signal i2c_ena     : STD_LOGIC;                     --i2c enable signal
    signal i2c_addr    : STD_LOGIC_VECTOR(6 DOWNTO 0);  --i2c address signal
    signal i2c_rw      : STD_LOGIC;                     --i2c read/write command signal
    signal i2c_data_wr : STD_LOGIC_VECTOR(7 DOWNTO 0);  --i2c write data
    signal i2c_data_rd : STD_LOGIC_VECTOR(7 DOWNTO 0);  --i2c read data
    signal i2c_busy    : STD_LOGIC;                     --i2c busy signal
    signal i2c_error   : STD_LOGIC;                     --i2c Error signal
    signal busy_prev   : STD_LOGIC;                     --previous value of i2c busy signal
    signal temp_data   : STD_LOGIC_VECTOR(15 DOWNTO 0); --temperature data buffer
    signal temp_corr   : SIGNED(15 downto 0);           --temp in °C
    signal display_data: std_logic_vector(31 downto 0); --Data to print on LCD
    signal time_wait_100ms : integer := 10_000_000;
    signal time_wait_10us : integer := 769_000;
    signal busy_cnt : INTEGER ;
    signal counter: INTEGER ;

    constant i2c_addr_sens_temp : STD_LOGIC_VECTOR(6 DOWNTO 0):="1001011";  --i2c address signal
    
begin

    --instantiate the i2c master
    I2C_driver_0:  entity work.i2c_driver
    PORT MAP(
        clk => CLK, 
        res => SW1, 
        en => i2c_ena, 
        addr_in => i2c_addr,
        rw_n => i2c_rw, 
        d_in => i2c_data_wr, 
        busy => i2c_busy,
        error => i2c_error,
        d_out => i2c_data_rd, 
        sda => JA4,
        scl => JA3
    );

    -- Instantiate the driver
    DRIVER : entity work.oled_driver port map(
        clock => clk,
        reset => sw1,
        poweroff => pw_off,
        display_in => display_data,
        oled_sdin => oled_sdin,
        oled_sclk => oled_sclk,
        oled_dc => oled_dc,
        oled_res => oled_res,
        oled_vbat => oled_vbat,
        oled_vdd => oled_vdd
    );
    
    PROCESS(CLK, SW1) BEGIN
        IF(SW1 = '0') THEN                                      --reset activated
            counter <= 0;                                       --clear wait counter
            i2c_ena <= '0';                                     --clear i2c enable
            busy_cnt <= 0;                                      --clear busy counter
            LED <= (OTHERS => '0');                             --clear temperature result output
            state <= start;                                     --return to start state
        ELSIF(rising_edge (CLK)) THEN                           --rising edge of system clock
            CASE state IS                                       --state machine
            --give temp sensor 100ms to power up before communicating
                WHEN start =>
                    IF(counter < time_wait_100ms) THEN          --100ms not yet reached
                        counter <= counter + 1;                 --increment counter
                    ELSE                                        --100ms reached
                        counter <= 0;                           --clear counter
                        state <= set_resolution;                --advance to setting the resolution
                    END IF;
            
                --set the resolution of the temperature data to 16 bits
                WHEN set_resolution =>            
                    busy_prev <= i2c_busy;                       --capture the value of the previous i2c busy signal
                    IF(busy_prev = '0' AND i2c_busy = '1') THEN  --i2c busy just went high
                        busy_cnt <= busy_cnt + 1;                --counts the times busy has gone from low to high during transaction
                    END IF;
                    if busy_cnt =0 then                          --busy_cnt keeps track of which command we are on
                        i2c_ena <= '1';                          --initiate the transaction
                        i2c_addr <= i2c_addr_sens_temp;          --set the address of the temp sensor
                        i2c_rw <= '0';                           --command 1 is a write
                        i2c_data_wr <= "00000011";               --send the address (x03) of the Configuration Register
                    elsif busy_cnt =1 then                       --busy_cnt keeps track of which command we are on
                        i2c_data_wr <= "10000000";               --write the new configuration value to the Configuration Register
                    elsif busy_cnt =2 then                       --busy_cnt keeps track of which command we are on
                        i2c_ena <= '0';                          --deassert enable to stop transaction after command 2
                        IF(i2c_busy = '0') THEN                  --transaction complete
                            busy_cnt <= 0;                       --reset busy_cnt for next transaction
                            state <= pause;                      --advance to setting the Register Pointer for data reads
                        END IF;
                    end if;
                --pause 1s between transactions
                WHEN pause =>
                    IF(counter < time_wait_10us) THEN             --1.3us not yet reached
                        counter <= counter + 1;                   --increment counter
                    ELSE                                          --1.3us reached
                        counter <= 0;                             --clear counter
                        state <= read_data;                       --reading temperature data
                    END IF;
            
                --read ambient temperature data
                WHEN read_data =>
                    busy_prev <= i2c_busy;                        --capture the value of the previous i2c busy signal
                    IF(busy_prev = '0' AND i2c_busy = '1') THEN   --i2c busy just went high
                        busy_cnt <= busy_cnt + 1;                 --counts the times busy has gone from low to high during transaction
                    END IF;
                    if busy_cnt = 0 then                          --busy_cnt keeps track of which command we are on
                        i2c_ena <= '1';                           --initiate the transaction
                        i2c_addr <= i2c_addr_sens_temp;           --set the address of the temp sensor
                        i2c_rw <= '0';                            --command 1 is a write
                        i2c_data_wr <= "00000000";                --send the address (x00) of the Temperature Value MSB Register
                    elsif busy_cnt =1 then
                        i2c_rw <= '1';                            --command 2 is a read
                    elsif busy_cnt =2 then
                        IF(i2c_busy = '0') THEN                   --indicates data read in command 2 is ready
                        temp_data(15 DOWNTO 8) <= i2c_data_rd;    --retrieve MSB data from command 2
                        END IF;
                    elsif busy_cnt =3 then
                        i2c_ena <= '0';                           --deassert enable to stop transaction after command 3
                        IF(i2c_busy = '0') THEN                   --indicates data read in command 3 is ready
                            temp_data(7 DOWNTO 0) <= i2c_data_rd; --retrieve LSB data from command 3
                            busy_cnt <= 0;                        --reset busy_cnt for next transaction
                            state <= output_result;               --advance to output the result
                        END IF;
                    end if;
                --output the temperature data
                WHEN output_result =>
                    display_data(31 downto 16) <= (others => '0');
                    display_data(15 downto 0 ) <= temp_data;      --std_logic_vector(temp_corr);
                    LED <= temp_data(15 DOWNTO 8);                --write temperature data to output
                    state <= pause;                               --pause 1.3us before next transaction
                --default to start state
                WHEN OTHERS =>
                    state <= start;
                
            END CASE;
        END IF;
    END PROCESS;   
    temp_corr <= to_signed(120, 16) - signed(temp_data); 
    
end Behavioral;
