----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10.03.2026 20:20:46
-- Design Name: 
-- Module Name: uart_receiver - Behavioral
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

entity uart_receiver is
    -- speed_div_factor = clk_speed / (2 * uart_speed)
    -- e.g. for 100 MHz clk and 9600 bps uart: 100 000 000 / (2 * 9600) = 5208
    Generic ( speed_div_factor : unsigned (15 downto 0) := to_unsigned(5208, 16) );
    Port ( clk_i : in STD_LOGIC;
           rst_i : in STD_LOGIC;  -- async reset (active high) invalidates data and forces receiver into waiting state
           rx_i : in STD_LOGIC;
           data_o : out STD_LOGIC_VECTOR (7 downto 0);
           data_valid_o : out STD_LOGIC;  -- high if data is valid, low if new data is being received or read_confirm is high
           read_confirm_i : in STD_LOGIC);
end uart_receiver;

architecture Behavioral of uart_receiver is
    signal rx_vec3 : STD_LOGIC_VECTOR (2 downto 0) := "111";
    signal uart_clk_vec2 : STD_LOGIC_VECTOR (1 downto 0) := "11";
    signal uart_clk_div_cntr : unsigned (15 downto 0) := to_unsigned(0, 16);
    signal uart_clk_pulse_cntr : unsigned (3 downto 0) := to_unsigned(0, 4);
    signal byte_recvd_shf_reg : STD_LOGIC_VECTOR (9 downto 0);
    signal receive_state : STD_LOGIC := '0';
    signal data_valid : STD_LOGIC := '0';
begin
    data_o <= byte_recvd_shf_reg(8 downto 1);
    data_valid_o <= data_valid;

    process(clk_i, rst_i)
    begin
        if rst_i = '1' then
            rx_vec3 <= "111";
            uart_clk_vec2 <= "11";
            uart_clk_div_cntr <= to_unsigned(0, 16);
            uart_clk_pulse_cntr <= to_unsigned(0, 4);
            receive_state <= '0';
            data_valid <= '0';
        elsif rising_edge(clk_i) then
            rx_vec3 <= rx_vec3(1 downto 0) & rx_i;
            
            if receive_state = '0' then
                -- "low if [...] or read_confirm is high"
                if read_confirm_i = '1' then
                    data_valid <= '0';
                end if;
            
                -- transmission begin
                -- two zeros required to filter-out noise
                if rx_vec3(2 downto 1) = "10" then
                    receive_state <= '1';
                    uart_clk_div_cntr <= to_unsigned(0, 16);
                    uart_clk_pulse_cntr <= to_unsigned(0, 4);
                    uart_clk_vec2 <= "00";
                end if;
            elsif receive_state = '1' then
                -- uart_clk_vec2 handling
                if uart_clk_div_cntr = speed_div_factor - 1 then
                    uart_clk_vec2 <= uart_clk_vec2(0) & not uart_clk_vec2(0);
                    uart_clk_div_cntr <= to_unsigned(0, 16);
                else
                    uart_clk_vec2 <= uart_clk_vec2(0) & uart_clk_vec2(0);
                    uart_clk_div_cntr <= uart_clk_div_cntr + 1;
                end if;
                
                -- data readout on the rising edge of uart_clk_vec2
                if uart_clk_vec2 = "01" then
                    byte_recvd_shf_reg <= rx_vec3(2) & byte_recvd_shf_reg(9 downto 1);
                    if uart_clk_pulse_cntr = 0 then
                        if rx_vec3(2) = '1' then
                            -- start bit invalid, aborting receiving
                            receive_state <= '0';
                            data_valid <= '0';
                        else
                            -- everything ok, can invalidate data and start counting
                            data_valid <= '0'; -- "low if new data is being received [...]"
                            uart_clk_pulse_cntr <= uart_clk_pulse_cntr + 1;
                        end if;                        
                    elsif uart_clk_pulse_cntr = 9 then
                        receive_state <= '0';
                        if rx_vec3(2) = '0' then
                            -- stop bit invalid
                            data_valid <= '0';
                        else
                            -- even though read_confirm_i might be high,
                            -- new output data overrides this signal and forces data_valid high
                            data_valid <= '1';
                        end if;
                    else
                        -- "low if new data is being received [...]"
                        data_valid <= '0';
                        uart_clk_pulse_cntr <= uart_clk_pulse_cntr + 1;
                    end if;
                elsif read_confirm_i = '1' then
                    -- "low if [...] or read_confirm is high"
                    data_valid <= '0';                
                end if;
            end if;
        end if;
    end process;

end Behavioral;
