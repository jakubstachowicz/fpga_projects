----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 28.02.2026 21:37:33
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
           btn_i : in STD_LOGIC_VECTOR (3 downto 0);
           sw_i : in STD_LOGIC_VECTOR (7 downto 0);
           led7_an_o : out STD_LOGIC_VECTOR (3 downto 0);
           led7_seg_o : out STD_LOGIC_VECTOR (7 downto 0));
end top;

architecture Behavioral of top is
    component display is
        Generic ( clk_divide_factor : unsigned (31 downto 0) );
        Port ( clk_i : in STD_LOGIC;
               rst_i : in STD_LOGIC;
               digit_i : in STD_LOGIC_VECTOR (31 downto 0);
               led7_an_o : out STD_LOGIC_VECTOR (3 downto 0);
               led7_seg_o : out STD_LOGIC_VECTOR (7 downto 0));
    end component display;
    component encoder_memory is
        Port ( clk_i : in STD_LOGIC;
               btn_i : in STD_LOGIC_VECTOR (3 downto 0);
               sw_i : in STD_LOGIC_VECTOR (7 downto 0);
               digit_o : out STD_LOGIC_VECTOR (31 downto 0));
    end component encoder_memory;
    signal digit : STD_LOGIC_VECTOR (31 downto 0);
begin
    encoder_memory_instance: encoder_memory port map (
        clk_i => clk_i,
        btn_i => btn_i,
        sw_i => sw_i,
        digit_o => digit);

    display_instance: display
    generic map ( clk_divide_factor => to_unsigned(100000, 32) )
    port map (
        clk_i => clk_i,
        rst_i => '0',
        digit_i => digit,
        led7_an_o  => led7_an_o,
        led7_seg_o => led7_seg_o);
        
end Behavioral;
