----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/23/2023 10:27:58 AM
-- Design Name: 
-- Module Name: I2C_driver - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
----------------------------------------------------------------------------------
-- [FULLY TESTED]

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

entity I2C_driver is
    Port ( clk : in STD_LOGIC;
           res : in STD_LOGIC;
           en : in STD_LOGIC;
           rw_n : in STD_LOGIC;
           d_in : in STD_LOGIC_VECTOR (7 downto 0);
           addr_in : in STD_LOGIC_VECTOR (6 downto 0);
           d_out : out STD_LOGIC_VECTOR (7 downto 0);
           busy, error : out STD_LOGIC;
           sda : inout STD_LOGIC;
           scl : inout STD_LOGIC
    );
end I2C_driver;

architecture Behavioral of I2C_driver is
    component clk_wiz
        port(  
            clk_out1 : out std_logic;
            clk_in1  : in  std_logic
         );
    end component;

    type stato_t is (idle, start, send_address, read_ack, readed_nack, writing, reading, write_ack, stop);
    signal i2c_state : stato_t := idle;
    signal sda_int, scl_int : std_logic;
    signal data, addr : std_logic_vector(7 downto 0) := (others => '0');
    signal ack, nack : std_logic;
    
    signal scl_count : unsigned (7 downto 0) := (others => '0');
    signal to_start, to_stop : std_logic := '0';
    signal data_count : unsigned (2 downto 0) := (others => '0');
    constant total_cycle : unsigned (7 downto 0) := to_unsigned(249, 8);    --250 cicli * 10 ns - 1 ciclo * 10 ns
    constant half_cycle : unsigned (7 downto 0) := to_unsigned(124, 8);     --125 cicli * 10 ns - 1 ciclo * 10 ns
    constant quarter_cycle : unsigned (7 downto 0) := to_unsigned(61, 8);   --62  cicli * 10 ns - 1 ciclo * 10 ns
    

begin

    msf : process( clk, res) begin
        if res = '0' then
            i2c_state <= idle;
            sda_int <= '1';
            scl_int <= '1';
            d_out <= (others => '0');
            scl_count <= (others => '0');
            data_count <= (others => '0');
            addr <= (others => '0');
            ack <= '0';
            nack <= '0';
            busy <= '0';
            error <= '0';
            to_start <= '0';
            to_stop  <= '0';
        elsif rising_edge(clk) then
            --Defaults
            error <= '0';
            busy <= '1';
            scl_count <= scl_count + 1;
            ack <= ack;
            nack <= nack;
            to_start <= to_start;
            to_stop  <= to_stop;

            --SCL gen
            if scl_count < half_cycle then
                scl_int <= '0';
            elsif scl_count >= half_cycle and scl_count <= total_cycle then
                scl_int <= '1';
            end if;
            if scl_count = total_cycle then
                scl_count <= (others => '0');
            end if ;

            case( i2c_state ) is
                when idle =>
                    scl_int <= '1';
                    sda_int <= '1';
                    busy <= '0';
                    nack <= '0';
                    ack <= '0';
                    scl_count <= scl_count;
                    if en = '1' then
                        sda_int <= '0';
                        data <= d_in;
                        addr(7 downto 1) <= addr_in;
                        addr(0) <= rw_n;
                        i2c_state <= start;
                        scl_count <= (others => '0');
                    end if;
                when start =>
                    to_start <= '0';
                    if scl_count < quarter_cycle then
                        sda_int <= '0';
                        scl_int <= '1';
                    elsif scl_count >= quarter_cycle and scl_count < half_cycle then
                        sda_int <= '0';
                        scl_int <= '0';
                    elsif scl_count >= half_cycle then
                        sda_int <= '0';
                        scl_int <= '0';
                        i2c_state <= send_address;
                        scl_count <= quarter_cycle + 1;
                        data_count <= (others => '1');
                    end if ;
                when send_address =>
                    --SDA gen
                    sda_int <= sda_int;
                    if scl_count < half_cycle then
                        if scl_count = quarter_cycle then
                            data_count <= data_count - 1;
                        elsif scl_count > quarter_cycle then
                            sda_int <= addr(to_integer(data_count));
                        end if ;
                    elsif scl_count >= half_cycle then
                        if scl_count = total_cycle and data_count = 0 then
                            sda_int <= '1';
                            i2c_state <= read_ack;
                        end if ;
                    end if ;
                when read_ack => 
                    if scl_count = half_cycle + quarter_cycle then
                        if sda = '0' then
                            ack <= '1';
                        elsif sda = '1' then
                            nack <= '1';
                        end if ;
                    elsif scl_count = total_cycle then
                        scl_count <= (others => '0');
                        if ack = '1' then
                            if to_stop = '1' then
                                i2c_state <= stop;
                            elsif rw_n = '1' then
                                i2c_state <= reading;
                            elsif rw_n = '0'  then
                                i2c_state <= writing;
                            end if ;
                        elsif nack = '1' then
                            i2c_state <= readed_nack;
                        end if ;
                    end if ;
                when readed_nack => 
                    scl_int <= '1';
                    sda_int <= '1';
                    busy <= '0';
                    error <= '1';
                    scl_count <= scl_count;
                    nack <= '0';
                    ack <= '0';
                    if en = '1' then
                        data <= d_in;
                        addr(7 downto 1) <= addr_in;
                        addr(0) <= rw_n;
                        i2c_state <= start;
                        scl_count <= (others => '0');
                    end if;
                when reading =>
                    ack <= '0';
                    nack <= '0';
                    if scl_count = quarter_cycle then
                        data_count <= data_count - 1;
                    elsif scl_count = half_cycle + quarter_cycle then
                        d_out(to_integer(data_count)) <= sda;
                    elsif scl_count = total_cycle and data_count = 0 then
                        i2c_state <= write_ack;
                        -- if en = '1' then
                        --     data <= d_in;
                        --     addr(7 downto 1) <= addr_in;
                        --     addr(0) <= rw_n;
                        --     scl_count <= (others => '0');
                        --     to_start <= '1';
                        -- else 
                        --     to_stop <= '1';
                        -- end if ;
                    end if ;
                when writing =>
                    ack <= '0';
                    nack <= '0';
                    if scl_count = quarter_cycle then
                        data_count <= data_count - 1;
                    elsif scl_count > quarter_cycle and scl_count < half_cycle then
                        sda_int <= data(to_integer(data_count));
                    elsif scl_count = total_cycle and data_count = 0 then
                        to_stop <= '1';
                        i2c_state <= read_ack;
                    end if ;
                when write_ack => 
                    if scl_count > half_cycle and scl_count < total_cycle then
                        sda_int <= '0';
                    elsif scl_count = total_cycle then
                        i2c_state <= idle;
                        -- if to_start = '1' and to_stop = '0' then
                        --     i2c_status <= start;
                        -- elsif to_start = '0' and to_stop = '1' then
                        --     i2c_stop <= stop;
                        -- end if ;
                    end if ;
                when stop => 
                    to_stop <= '0';
                    if scl_count > quarter_cycle and scl_count < half_cycle + quarter_cycle then
                        sda_int <= '0';
                    elsif scl_count >= half_cycle + quarter_cycle and scl_count < total_cycle then
                        sda_int <= '1';
                    elsif scl_count = total_cycle then
                        i2c_state <= idle;
                    end if ;
                when others => 
                    i2c_state <= idle;
            end case ;
        end if ;
    end process ; -- msf
    --Equazioni
    sda <= 'Z' when sda_int = '1' else '0';
    scl <= 'Z' when scl_int = '1' else '0';

end Behavioral;
