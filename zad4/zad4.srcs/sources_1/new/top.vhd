----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01.03.2026 01:06:10
-- Design Name: 
-- Module Name: top - Behavioral
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

entity top is
    Port ( clk_i : in STD_LOGIC;
           rst_i : in STD_LOGIC;
           RXD_i : in STD_LOGIC;
           led7_an_o : out STD_LOGIC_VECTOR (3 downto 0);
           led7_seg_o : out STD_LOGIC_VECTOR (7 downto 0));
end top;

architecture Behavioral of top is
    component byte_display is
        Port ( byte_i : in STD_LOGIC_VECTOR (7 downto 0);
               clk_i : in STD_LOGIC;
               latch_enable_i : in STD_LOGIC;
               rst_i : in STD_LOGIC;
               led7_an_o : out STD_LOGIC_VECTOR (3 downto 0);
               led7_seg_o : out STD_LOGIC_VECTOR (7 downto 0));
    end component byte_display;
    component uart_receiver is
    -- speed_div_factor = clk_speed / (2 * uart_speed)
    -- e.g. for 100 MHz clk and 9600 bps uart: 100 000 000 / (2 * 9600) = 5208
    Generic ( speed_div_factor : unsigned (15 downto 0) := to_unsigned(5208, 16) );
    Port ( clk_i : in STD_LOGIC;
           rst_i : in STD_LOGIC;  -- async reset (active high) invalidates data and forces receiver into waiting state
           rx_i : in STD_LOGIC;
           data_o : out STD_LOGIC_VECTOR (7 downto 0);
           data_valid_o : out STD_LOGIC;  -- high if data is valid, low if new data is being received or read_confirm is high
           read_confirm_i : in STD_LOGIC);
    end component uart_receiver;
    signal data : STD_LOGIC_VECTOR (7 downto 0);
    signal data_valid : STD_LOGIC;
    signal read_confirm : STD_LOGIC := '0';
begin    
    byte_display_instance: byte_display port map (
        byte_i => data,
        clk_i => clk_i,
        latch_enable_i => data_valid,
        rst_i => rst_i,
        led7_an_o  => led7_an_o,
        led7_seg_o => led7_seg_o);
    
    uart_receiver_instance: uart_receiver port map (
        clk_i => clk_i,
        rst_i => rst_i,
        rx_i => RXD_i,
        data_o => data,
        data_valid_o => data_valid,
        read_confirm_i => read_confirm);    
    
    process(clk_i, rst_i)
    begin
        if rst_i = '1' then
            read_confirm <= '0';
        elsif rising_edge(clk_i) then
            if data_valid = '1' then
                read_confirm <= '1';
            else 
                read_confirm <= '0';
            end if;
        end if;
    end process;

end Behavioral;
