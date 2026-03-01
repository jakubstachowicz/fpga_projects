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
               latch_i : in STD_LOGIC;
               rst_i : in STD_LOGIC;
               led7_an_o : out STD_LOGIC_VECTOR (3 downto 0);
               led7_seg_o : out STD_LOGIC_VECTOR (7 downto 0));
    end component byte_display;
    signal uart_clk_div_factor : unsigned (15 downto 0) := to_unsigned(5208, 16); -- constant
    signal byte_recvd_shf_reg : STD_LOGIC_VECTOR (9 downto 0);
    signal receive_state : STD_LOGIC := '0';
    signal latch_byte : STD_LOGIC := '0';
    signal uart_clock : STD_LOGIC := '1';
    signal uart_clk_div_cntr : unsigned (15 downto 0) := to_unsigned(0, 16);
    signal uart_clk_pulse_cntr : unsigned (3 downto 0) := to_unsigned(0, 4);
begin    
    byte_display_instance: byte_display port map (
        byte_i => byte_recvd_shf_reg(8 downto 1),
        clk_i => clk_i,
        latch_i => latch_byte,
        rst_i => rst_i,
        led7_an_o  => led7_an_o,
        led7_seg_o => led7_seg_o);
        
    process(clk_i, RXD_i, rst_i)
    begin
        if rst_i = '1' then
            receive_state <= '0';
            latch_byte <= '0';
            uart_clock <= '1';
            uart_clk_div_cntr <= to_unsigned(0, 16);
            uart_clk_pulse_cntr <= to_unsigned(0, 4);
        elsif receive_state = '0' then
            if falling_edge(RXD_i) then
                receive_state <= '1';
                latch_byte <= '0';
                uart_clock <= not uart_clock;
            end if;
        elsif rising_edge(clk_i) then
            uart_clk_div_cntr <= uart_clk_div_cntr + 1;
            if uart_clk_div_cntr - 1 = uart_clk_div_factor then
                uart_clk_div_cntr <= to_unsigned(0, 16);
                uart_clock <= not uart_clock;
                if uart_clock = '0' then
                    byte_recvd_shf_reg <= RXD_i & byte_recvd_shf_reg(9 downto 1);
                    uart_clk_pulse_cntr <= uart_clk_pulse_cntr + 1;
                    if uart_clk_pulse_cntr = 9 then
                        receive_state <= '0';
                        latch_byte <= '1';
                        uart_clk_pulse_cntr <= to_unsigned(0, 4);
                    end if;
                end if;
            end if;
        end if;
    end process;

end Behavioral;
