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

entity I2C_driver is
    Port ( clk : in STD_LOGIC;
           res : in STD_LOGIC;
           en : in STD_LOGIC;
           rw_n : in STD_LOGIC;
           d_in : in STD_LOGIC_VECTOR (7 downto 0);
           add_in : in STD_LOGIC_VECTOR (6 downto 0);
           busy : out STD_LOGIC_VECTOR (0 downto 0);
           d_out : out STD_LOGIC_VECTOR (7 downto 0);
           sda : out STD_LOGIC;
           scl : out STD_LOGIC);
end I2C_driver;

architecture Behavioral of I2C_driver is
    component clk_wiz
        port(  
            clk_out1 : out std_logic;
            clk_in1  : in  std_logic
         );
    end component;

    type stato_t is (idle, start, writing);
    type clk_type is (start, stop, clock, no_clok);
    signal i2c_state : stato_t := idle;
    signal scl_state :  clk_type := no_clok;
    signal sda_int, scl_int, clk_200m, clk_1_6m: std_logic;
    
    signal scl_count : unsigned (9 downto 0);
    constant total_cycle : unsigned (7 downto 0) := to_unsigned(250, 8);
    constant half_cycle : unsigned (7 downto 0) := to_unsigned(125, 8);
    constant quarter_cycle : unsigned (7 downto 0) := to_unsigned(62, 8);

begin
    your_instance_name : clk_wiz
    port map (  
        clk_out1 => clk_200m,
        clk_in1 => clk
    );

    clk_1_6MHz_gen : process( clk_200m )
        if rising_edge(clk_200m) then
            
        end if ;
    begin
        
    end process ; -- clk_1_6MHz_gen

    i2c_scl_gen : process( ckl, res )
    begin
        if res = '0' then
            scl_count <= (others => '0');
            scl_state <= no_clock;
        elsif rising_edge(clk) then
            --Contatore per SCL
            if scl_state = start or scl_state = stop or scl_state = clock then
                scl_count <= scl_count + 1;
            end if ;

            --Stato 
            case( scl_state ) is
                when no_clock =>
                    scl_int <= '1';
                    scl_count <= (others => '0');
                when start =>
                    if scl_counter = quarter_cycle - 1 then
                        scl_in <= '0';
                        scl_count <= (others => '0');
                        scl_state <= clock;
                    end if ;
                when clock => 
                    if scl_counter < semi_cycle then
                        scl_in <= '0';
                    elsif scl_counter < total_cycle then
                        scl_in <= '1';
                    end if ;
                when stop =>
                    
                    
            end case ;
        end if ;        
    end process ; -- i2c_scl_gen
                   
    --Equazioni
    sda <= 'Z' when sda_int = '1' else '0';
    scl <= 'Z' when scl_int = '1' else '0';
end Behavioral;
