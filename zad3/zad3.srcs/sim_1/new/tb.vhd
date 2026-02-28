----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 28.02.2026 22:01:04
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity tb is
--  Port ( );
end tb;

architecture Behavioral of tb is
    component top is
        Port ( clk_i : in STD_LOGIC;
               btn_i : in STD_LOGIC_VECTOR (3 downto 0);
               sw_i : in STD_LOGIC_VECTOR (7 downto 0);
               led7_an_o : out STD_LOGIC_VECTOR (3 downto 0);
               led7_seg_o : out STD_LOGIC_VECTOR (7 downto 0));
    end component top;
    signal clk_i : STD_LOGIC := '1';
    signal btn_i : STD_LOGIC_VECTOR (3 downto 0);
    signal sw_i : STD_LOGIC_VECTOR (7 downto 0);
    signal led7_an_o : STD_LOGIC_VECTOR (3 downto 0);
    signal led7_seg_o : STD_LOGIC_VECTOR (7 downto 0);
begin
    dut: top port map (
        clk_i => clk_i,
        btn_i => btn_i,
        sw_i => sw_i,
        led7_an_o => led7_an_o,
        led7_seg_o => led7_seg_o);

    clk_i <= not clk_i after 5 ns;

    stim: process
    begin
        btn_i <= "0000";
        sw_i(7 downto 4) <= "1100"; -- kropki
        
        -- wpisz "1" na wyświetlacz AN3
        wait for 100 us;
        sw_i(3 downto 0) <= "0001";
        wait for 1 ms;
        btn_i(3) <= '1';
        wait for 1 ms;
        btn_i(3) <= '0';
        
        -- zmiana przełączników w połowie czasu wyłączenia buttona
        wait for 1 ms;
        sw_i(3 downto 0) <= "1011"; -- będziemy wyświetlać "b"
        sw_i(7 downto 4) <= "1010"; -- zmiana kropek
        wait for 1 ms;

        -- wpis do AN2
        btn_i(2) <= '1';
        wait for 1 ms; 
        btn_i(2) <= '0';

        -- zmiana przełączników w połowie czasu wyłączenia buttona
        wait for 1 ms;
        sw_i(3 downto 0) <= "1001"; -- będziemy wyświetlać "9"
        sw_i(7 downto 4) <= "0101"; -- zmiana kropek
        wait for 1 ms;

        -- wpis do AN1
        btn_i(1) <= '1';
        wait for 1 ms; 
        btn_i(1) <= '0';

        -- zmiana przełączników w połowie czasu wyłączenia buttona
        wait for 1 ms;
        sw_i(3 downto 0) <= "1101"; -- będziemy wyświetlać "d"
        wait for 1 ms;

        -- wpis do AN0
        btn_i(0) <= '1';
        wait for 1 ms; 
        btn_i(0) <= '0';
        wait for 6 ms;
        
        wait;
    end process;

end Behavioral;
