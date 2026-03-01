----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01.03.2026 23:00:04
-- Design Name: 
-- Module Name: tb - Behavioral
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

entity tb is
end tb;

architecture Behavioral of tb is
    component top is
        Port ( 
            clk_i : in STD_LOGIC;
            rst_i : in STD_LOGIC;
            RXD_i : in STD_LOGIC;
            led7_an_o : out STD_LOGIC_VECTOR (3 downto 0);
            led7_seg_o : out STD_LOGIC_VECTOR (7 downto 0)
        );
    end component;
    signal clk_i : STD_LOGIC := '0';
    signal rst_i : STD_LOGIC := '1';
    signal RXD_i : STD_LOGIC := '1';
    signal led7_an_o : STD_LOGIC_VECTOR (3 downto 0);
    signal led7_seg_o : STD_LOGIC_VECTOR (7 downto 0);

    procedure send_byte (
        constant data_vec8 : in STD_LOGIC_VECTOR (7 downto 0);
        constant wait_time : in time;
        signal tx : out std_logic
    ) is
    begin
        tx <= '0';
        wait for wait_time;

        for i in 0 to 7 loop
            tx <= data_vec8(i);
            wait for wait_time;
        end loop;

        tx <= '1';
        wait for wait_time;
    end procedure;
begin
    dut: top port map (
        clk_i => clk_i,
        rst_i => rst_i,
        RXD_i => RXD_i,
        led7_an_o => led7_an_o,
        led7_seg_o => led7_seg_o);

    clk_i <= not clk_i after 5 ns;

    stim: process
    begin
        RXD_i <= '1';
        rst_i <= '1';
        wait for 100 us;
        rst_i <= '0';
        wait for 100 us;

        send_byte("01010011", 104167 ns, RXD_i); -- 10^9 ns / 9600
        wait for 123 us;
        send_byte("01010011", 108507 ns, RXD_i); -- 10^9 ns / (9600 * 0,96 = 9216)
        wait for 321 us;
        send_byte("01010011", 100160 ns, RXD_i); -- 10^9 ns / (9600 * 1,04 = 9984)
        wait for 500 us;
        wait;
    end process;

end Behavioral;

