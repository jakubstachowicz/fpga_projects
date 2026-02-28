----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 28.02.2026 21:07:11
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity top is
    Port ( clk_i : in STD_LOGIC;
           rst_i : in STD_LOGIC;
           led_o : out STD_LOGIC_VECTOR (2 downto 0));
end top;

architecture Behavioral of top is
    signal vec3normal : unsigned (2 downto 0);
    signal vec3gray : STD_LOGIC_VECTOR (2 downto 0);
begin
    process(clk_i, rst_i)
    begin
        if rst_i = '1' then
            vec3normal <= "000";
        elsif rising_edge(clk_i) then
            vec3normal <= vec3normal + 1;
        end if;
    end process;
    
    vec3gray(2) <= vec3normal(2);
    vec3gray(1) <= vec3normal(2) xor vec3normal(1);
    vec3gray(0) <= vec3normal(1) xor vec3normal(0);
    
    led_o <= vec3gray;
end Behavioral;
