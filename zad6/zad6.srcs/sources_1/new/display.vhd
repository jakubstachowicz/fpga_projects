----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 28.02.2026 21:37:33
-- Design Name: 
-- Module Name: display - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity display is
    Generic ( clk_divide_factor : unsigned (31 downto 0) );
    Port ( clk_i : in STD_LOGIC;
           rst_i : in STD_LOGIC;
           digit_i : in STD_LOGIC_VECTOR (31 downto 0);
           led7_an_o : out STD_LOGIC_VECTOR (3 downto 0);
           led7_seg_o : out STD_LOGIC_VECTOR (7 downto 0));
end display;

architecture Behavioral of display is
    signal clk_divide_counter : unsigned (31 downto 0) := to_unsigned(0, 32);
    signal an_select : STD_LOGIC_VECTOR (3 downto 0) := "1110";
    signal seg_select : STD_LOGIC_VECTOR (7 downto 0) := "11111111";
begin
    process(clk_i, rst_i)
    begin
        if rst_i = '1' then
            clk_divide_counter <= to_unsigned(0, 32);
            an_select <= "1110"; 
        elsif rising_edge(clk_i) then
            clk_divide_counter <= clk_divide_counter + 1;
            if clk_divide_counter = clk_divide_factor - 1 then 
                clk_divide_counter <= to_unsigned(0, 32);
                an_select <= an_select(2 downto 0) & an_select(3);
                
                -- an_select jest w tym momencie "o jeden do tyłu"
                if an_select = "0111" then
                    seg_select <= digit_i(7 downto 0);
                elsif an_select = "1110" then
                    seg_select <= digit_i(15 downto 8);
                elsif an_select = "1101" then
                    seg_select <= digit_i(23 downto 16);
                else
                    seg_select <= digit_i(31 downto 24);
                end if;
            end if;
        end if;
    end process;

    led7_an_o  <= "0000" when rst_i = '1' else an_select;
    led7_seg_o <= "00000000" when rst_i = '1' else seg_select;
end Behavioral;
