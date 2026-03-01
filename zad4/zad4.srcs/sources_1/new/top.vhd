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
    signal uart_clk_div_factor : unsigned (15 downto 0) := to_unsigned(5208, 16); -- constant
    signal byte_recvd_shf_reg : STD_LOGIC_VECTOR (9 downto 0);
    signal receive_state : STD_LOGIC := '0';
    signal latch_enable : STD_LOGIC := '0';
    signal uart_clock : STD_LOGIC := '1';
    signal uart_clk_div_cntr : unsigned (15 downto 0) := to_unsigned(0, 16);
    signal uart_clk_pulse_cntr : unsigned (3 downto 0) := to_unsigned(0, 4);
    signal rxd_vec2 : STD_LOGIC_VECTOR (1 downto 0) := "11";
begin    
    byte_display_instance: byte_display port map (
        byte_i => byte_recvd_shf_reg(8 downto 1),
        clk_i => clk_i,
        latch_enable_i => latch_enable,
        rst_i => rst_i,
        led7_an_o  => led7_an_o,
        led7_seg_o => led7_seg_o);
        
    process(clk_i, rst_i)
    begin
        if rst_i = '1' then
            receive_state <= '0';
            latch_enable <= '0';
            uart_clock <= '1';
            uart_clk_div_cntr <= to_unsigned(0, 16);
            uart_clk_pulse_cntr <= to_unsigned(0, 4);
            rxd_vec2 <= "11";
        elsif rising_edge(clk_i) then
            rxd_vec2 <= rxd_vec2(0) & RXD_i;
            if receive_state = '0' then
                latch_enable <= '0';
                if rxd_vec2(1) = '1' and rxd_vec2(0) = '0' then
                    receive_state <= '1';
                    uart_clk_div_cntr <= to_unsigned(0, 16);
                    uart_clock <= '0';
                end if;
            elsif receive_state = '1' then
                uart_clk_div_cntr <= uart_clk_div_cntr + 1;
                if uart_clk_div_cntr - 1 = uart_clk_div_factor then
                    uart_clk_div_cntr <= to_unsigned(0, 16);
                    uart_clock <= not uart_clock;
                    if uart_clock = '0' then
                        byte_recvd_shf_reg <= rxd_vec2(0) & byte_recvd_shf_reg(9 downto 1);
                        uart_clk_pulse_cntr <= uart_clk_pulse_cntr + 1;
                        if uart_clk_pulse_cntr = 9 then
                            receive_state <= '0';
                            latch_enable <= '1';
                            uart_clk_pulse_cntr <= to_unsigned(0, 4);
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;

end Behavioral;
