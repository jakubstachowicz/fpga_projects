----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01.03.2026 01:06:10
-- Design Name: 
-- Module Name: byte_display - Behavioral
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

entity byte_display is
    Port ( byte_i : in STD_LOGIC_VECTOR (7 downto 0);
           clk_i : in STD_LOGIC;
           latch_i : in STD_LOGIC;
           rst_i : in STD_LOGIC;
           led7_an_o : out STD_LOGIC_VECTOR (3 downto 0);
           led7_seg_o : out STD_LOGIC_VECTOR (7 downto 0));
end byte_display;

architecture Behavioral of byte_display is
    function hex_to_seg_encode(hex : STD_LOGIC_VECTOR (3 downto 0)) return STD_LOGIC_VECTOR is
        variable seg : STD_LOGIC_VECTOR (6 downto 0);
    begin
        case hex is
            when "0000" => seg := "0000001"; -- 0
            when "0001" => seg := "1001111"; -- 1
            when "0010" => seg := "0010010"; -- 2
            when "0011" => seg := "0000110"; -- 3
            when "0100" => seg := "1001100"; -- 4
            when "0101" => seg := "0100100"; -- 5
            when "0110" => seg := "0100000"; -- 6
            when "0111" => seg := "0001111"; -- 7
            when "1000" => seg := "0000000"; -- 8
            when "1001" => seg := "0000100"; -- 9
            when "1010" => seg := "0001000"; -- A
            when "1011" => seg := "1100000"; -- b
            when "1100" => seg := "0110001"; -- C
            when "1101" => seg := "1000010"; -- d
            when "1110" => seg := "0110000"; -- E
            when "1111" => seg := "0111000"; -- F
            when others => seg := "1111111";
        end case;
        return seg;
    end hex_to_seg_encode;
    component display is
        Generic ( clk_divide_factor : unsigned (31 downto 0) );
        Port ( clk_i : in STD_LOGIC;
               rst_i : in STD_LOGIC;
               digit_i : in STD_LOGIC_VECTOR (31 downto 0);
               led7_an_o : out STD_LOGIC_VECTOR (3 downto 0);
               led7_seg_o : out STD_LOGIC_VECTOR (7 downto 0));
    end component display;
    signal digit : STD_LOGIC_VECTOR (31 downto 0) := (others => '1');
begin
    display_instance: display
    generic map ( clk_divide_factor => to_unsigned(25000, 32) )
    port map (
        clk_i => clk_i,
        rst_i => rst_i,
        digit_i => digit,
        led7_an_o  => led7_an_o,
        led7_seg_o => led7_seg_o);
    
    process(latch_i, rst_i)
    begin
        if rst_i = '1' then
            digit <= (others => '1');
        elsif rising_edge(latch_i) then
            digit(15 downto 9) <= hex_to_seg_encode(byte_i(7 downto 4));
            digit(7 downto 1) <= hex_to_seg_encode(byte_i(3 downto 0));
        end if;
    end process;

end Behavioral;
