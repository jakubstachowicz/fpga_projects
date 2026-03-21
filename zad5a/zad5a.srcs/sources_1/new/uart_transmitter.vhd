----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 21.03.2026 19:04:44
-- Design Name: 
-- Module Name: uart_transmitter - Behavioral
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
 
entity uart_transmitter is
    -- speed_div_factor = clk_speed / (2 * uart_speed)
    -- e.g. for 100 MHz clk and 9600 bps uart: 100 000 000 / (2 * 9600) = 5208
    Generic ( speed_div_factor : unsigned (15 downto 0) := to_unsigned(5208, 16) );
    Port ( clk_i : in STD_LOGIC;
           rst_i : in STD_LOGIC;  -- async reset (active high) forces to stop transmitting
           tx_o : out STD_LOGIC;
           data_i : in STD_LOGIC_VECTOR (7 downto 0);
           lock_and_send_i : in STD_LOGIC;  -- if high and the transmitter is idle, locks the input data to the internal register and starts sending
           send_confirm_o : out STD_LOGIC);  -- high for one clock cycle if the data was locked and is being sent
end uart_transmitter;
 
architecture Behavioral of uart_transmitter is
    signal uart_clk_vec2 : STD_LOGIC_VECTOR (1 downto 0) := "11";
    signal uart_clk_div_cntr : unsigned (15 downto 0) := to_unsigned(0, 16);
    signal uart_clk_pulse_cntr : unsigned (3 downto 0) := to_unsigned(0, 4);
    signal tx_data_shf_reg : STD_LOGIC_VECTOR (9 downto 0);
    signal send_state : STD_LOGIC := '0';
    signal tx : STD_LOGIC := '1';
    signal send_confirm : STD_LOGIC := '0';
begin
    tx_o <= tx;
    send_confirm_o <= send_confirm;
 
    process(clk_i, rst_i)
    begin
        if rst_i = '1' then
            uart_clk_vec2 <= "00";
            uart_clk_div_cntr <= to_unsigned(0, 16);
            uart_clk_pulse_cntr <= to_unsigned(0, 4);
            send_state <= '0';
            tx <= '1';
            send_confirm <= '0';
        elsif rising_edge(clk_i) then
            if send_state = '0' then            
                -- transmission can begin
                if lock_and_send_i = '1' then
                    send_state <= '1';
                    tx_data_shf_reg <= '1' & data_i & '0';
                    uart_clk_div_cntr <= to_unsigned(0, 16);
                    uart_clk_pulse_cntr <= to_unsigned(0, 4);
                    uart_clk_vec2 <= "01";
                    send_confirm <= '1';
                end if;
            elsif send_state = '1' then
                -- turning off the confirm signal
                if send_confirm = '1' then
                    send_confirm <= '0';
                end if;
            
                -- uart_clk_vec2 handling
                if uart_clk_div_cntr = speed_div_factor - 1 then
                    uart_clk_vec2 <= uart_clk_vec2(0) & not uart_clk_vec2(0);
                    uart_clk_div_cntr <= to_unsigned(0, 16);
                else
                    uart_clk_vec2 <= uart_clk_vec2(0) & uart_clk_vec2(0);
                    uart_clk_div_cntr <= uart_clk_div_cntr + 1;
                end if;
                
                -- data send on the rising edge of uart_clk_vec2
                if uart_clk_vec2 = "01" then
                    if uart_clk_pulse_cntr = 10 then
                        tx <= '1';
                        send_state <= '0';
                    else
                        tx <= tx_data_shf_reg(0);
                        tx_data_shf_reg <= tx_data_shf_reg(0) & tx_data_shf_reg(9 downto 1);
                        uart_clk_pulse_cntr <= uart_clk_pulse_cntr + 1;
                    end if;            
                end if;
            end if;
        end if;
    end process;
 
 
end Behavioral;
