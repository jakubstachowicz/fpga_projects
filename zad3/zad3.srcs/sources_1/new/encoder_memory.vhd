----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 28.02.2026 21:37:33
-- Design Name: 
-- Module Name: encoder_memory - Behavioral
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

entity encoder_memory is
    Port ( clk_i : in STD_LOGIC;
           btn_i : in STD_LOGIC_VECTOR (3 downto 0);
           sw_i : in STD_LOGIC_VECTOR (7 downto 0);
           digit_o : out STD_LOGIC_VECTOR (31 downto 0));
end encoder_memory;

architecture Behavioral of encoder_memory is
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
    signal digit_internal : STD_LOGIC_VECTOR (31 downto 0) := (others => '1');
begin
    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if btn_i(3) = '1' then
                digit_internal(31 downto 25) <= hex_to_seg_encode(sw_i(3 downto 0));
            end if;
            if btn_i(2) = '1' then
                digit_internal(23 downto 17) <= hex_to_seg_encode(sw_i(3 downto 0));
            end if;
            if btn_i(1) = '1' then
                digit_internal(15 downto 9) <= hex_to_seg_encode(sw_i(3 downto 0));
            end if;
            if btn_i(0) = '1' then
                digit_internal(7 downto 1) <= hex_to_seg_encode(sw_i(3 downto 0));
            end if;
        end if;
    end process;
    
    digit_internal(24) <= not sw_i(7);
    digit_internal(16) <= not sw_i(6);
    digit_internal(8) <= not sw_i(5);
    digit_internal(0) <= not sw_i(4);
    
    digit_o <= digit_internal;

end Behavioral;
