----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09.03.2026 21:59:24
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
               rst_i : in STD_LOGIC;
               button_i : in STD_LOGIC_VECTOR (3 downto 0);
               led7_an_o : out STD_LOGIC_VECTOR (3 downto 0);
               led7_seg_o : out STD_LOGIC_VECTOR (7 downto 0));
    end component top;

    component bounce is
        Generic ( min_time : TIME := 100 us;
                max_time : TIME := 1 ms;
                max_cnt : INTEGER := 2;
                seed : INTEGER := 777);
        Port ( in_i : in STD_LOGIC;
            out_o : out STD_LOGIC);
    end component;

    signal clk_i : STD_LOGIC := '0';
    signal rst_i : STD_LOGIC := '1';
    
    signal physical_buttons : STD_LOGIC_VECTOR (3 downto 0) := "0000";
    signal bouncing_buttons : STD_LOGIC_VECTOR (3 downto 0);
    
    signal led7_an_o : STD_LOGIC_VECTOR (3 downto 0);
    signal led7_seg_o : STD_LOGIC_VECTOR (7 downto 0);

    constant CLK_PERIOD : time := 10 ns;
begin
    dut: top port map (
        clk_i => clk_i,
        rst_i => rst_i,
        button_i => bouncing_buttons,
        led7_an_o => led7_an_o,
        led7_seg_o => led7_seg_o
    );

    gen_bounce: for i in 0 to 3 generate
        b_inst: bounce 
        generic map ( 
            min_time => 2 us, -- czasy dostosowane do szybszego zegara hardwerowego
            max_time => 10 us,
            max_cnt => 4,
            seed => 100 + (i * 13)
        ) 
        port map (
            in_i  => physical_buttons(i),
            out_o => bouncing_buttons(i)
        );
    end generate;

    -- zegar
    clk_process : process
    begin
        clk_i <= '0';
        wait for CLK_PERIOD / 2;
        clk_i <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    stim: process
    begin
        rst_i <= '1';
        physical_buttons <= "0000";
        wait for 1 us;
        rst_i <= '0';
        wait for 20 us;
        
        report "Wejscie w tryb edycji";
        physical_buttons <= "1000";
        wait for 5500 us;  
        physical_buttons <= "0000";
        wait for 200 us;
        
        report "Zwiekszam wartosc (BTNU)";
        physical_buttons <= "0010"; wait for 200 us; physical_buttons <= "0000"; wait for 200 us;
        physical_buttons <= "0010"; wait for 200 us; physical_buttons <= "0000"; wait for 200 us;
        
        report "Zmniejszam wartosc (BTND - underflow test)";
        physical_buttons <= "0001"; wait for 200 us; physical_buttons <= "0000"; wait for 200 us;
        physical_buttons <= "0001"; wait for 200 us; physical_buttons <= "0000"; wait for 200 us;
        physical_buttons <= "0001"; wait for 200 us; physical_buttons <= "0000"; wait for 200 us;

        report "Przesuniecie kursora w lewo (Krotki klik BTNL)";
        physical_buttons <= "1000"; wait for 200 us; physical_buttons <= "0000"; wait for 200 us;
        
        report "Zwiekszam wartosc na cyfrze 1";
        physical_buttons <= "0010"; wait for 200 us; physical_buttons <= "0000"; wait for 200 us;
        
        report "Przesuniecie kursora w prawo (BTNR)";
        physical_buttons <= "0100"; wait for 200 us; physical_buttons <= "0000"; wait for 200 us;

        report "Wciskam BTNU i BTNR rownoczesnie";
        physical_buttons <= "0110"; 
        wait for 200 us;
        physical_buttons <= "0000";
        wait for 200 us;

        report "Wychodze z trybu edycji (Dlugi klik BTNL)";
        physical_buttons <= "1000";
        wait for 5500 us;
        physical_buttons <= "0000";
        
        report "Proba wcisniecia po wyjsciu";
        physical_buttons <= "0010"; wait for 200 us; physical_buttons <= "0000"; wait for 200 us;

        wait for 1000 us;
        report "====== ZAKONCZONO WSZYSTKIE TESTY ======";
        std.env.stop;
    end process;

end Behavioral;