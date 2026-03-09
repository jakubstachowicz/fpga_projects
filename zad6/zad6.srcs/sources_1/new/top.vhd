----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09.03.2026 17:28:19
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
           button_i : in STD_LOGIC_VECTOR (3 downto 0);
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
    component kcpsm6 is
      generic(                 hwbuild : std_logic_vector(7 downto 0) := X"00";
                      interrupt_vector : std_logic_vector(11 downto 0) := X"3FF";
               scratch_pad_memory_size : integer := 64);
      port (                   address : out std_logic_vector(11 downto 0);
                           instruction : in std_logic_vector(17 downto 0);
                           bram_enable : out std_logic;
                               in_port : in std_logic_vector(7 downto 0);
                              out_port : out std_logic_vector(7 downto 0);
                               port_id : out std_logic_vector(7 downto 0);
                          write_strobe : out std_logic;
                        k_write_strobe : out std_logic;
                           read_strobe : out std_logic;
                             interrupt : in std_logic;
                         interrupt_ack : out std_logic;
                                 sleep : in std_logic;
                                 reset : in std_logic;
                                   clk : in std_logic);
    end component kcpsm6;
    component program is
      generic(             C_FAMILY : string := "S6"; 
                  C_RAM_SIZE_KWORDS : integer := 1;
               C_JTAG_LOADER_ENABLE : integer := 0);
      Port (      address : in std_logic_vector(11 downto 0);
              instruction : out std_logic_vector(17 downto 0);
                   enable : in std_logic;
                      rdl : out std_logic;                    
                      clk : in std_logic);
    end component program;
    signal address : std_logic_vector (11 downto 0);
    signal instruction : std_logic_vector (17 downto 0);
    signal bram_enable : std_logic;
    signal in_port : std_logic_vector (7 downto 0);
    signal out_port : std_logic_vector (7 downto 0);
    signal port_id : std_logic_vector (7 downto 0);
    signal write_strobe : std_logic;
    signal interrupt : std_logic := '0';
    signal interrupt_ack : std_logic;
    signal digit : STD_LOGIC_VECTOR (31 downto 0);
    signal counter : unsigned (31 downto 0) := to_unsigned(0, 32);
begin
    display_instance: display
    generic map ( clk_divide_factor => to_unsigned(25000, 32) )
    port map (
        clk_i => clk_i,
        rst_i => rst_i,
        digit_i => digit,
        led7_an_o  => led7_an_o,
        led7_seg_o => led7_seg_o);

    picoblaze_instance: kcpsm6
    port map (
        address => address,
        instruction => instruction,
        bram_enable => bram_enable,
        in_port => in_port,
        out_port => out_port, -- slowo wyjsciowe
        port_id => port_id, -- id portu z ktorego pochodzi slowo wyjsciowe
        write_strobe => write_strobe, -- "siema, odczytaj dane z out_port i port_id bo sa juz spoko"
        k_write_strobe => open, -- nieuzywane
        read_strobe => open, -- nieuzywane
        interrupt => interrupt, -- przerwanie do obslugi zegara bede uzywal
        interrupt_ack => interrupt_ack, -- acknowledgement przerwania (przerwania do obslugi zegara)
        sleep => '0', -- nieuzywane
        reset => rst_i,
        clk => clk_i);
        
    program_rom: program
    port map (
        address => address,
        instruction => instruction,
        enable => bram_enable,
        rdl => open, -- nieuzywane
        clk => clk_i);
        
    in_port <= "0000" & button_i;

    process(clk_i, rst_i)
    begin
        if rst_i = '1' then
            counter <= to_unsigned(0, 32);
            interrupt <= '0';
        elsif rising_edge(clk_i) then
            if write_strobe = '1' then
                if port_id = "00000000" then digit(7 downto 0) <= out_port;
                elsif port_id = "00000001" then digit(15 downto 8) <= out_port;
                elsif port_id = "00000010" then digit(23 downto 16) <= out_port;
                else digit(31 downto 24) <= out_port; end if;
            end if;
            
            -- sprzetowy timer 1-milisekundowy
            if counter = 99998 then
                interrupt <= '1';
                counter <= counter + 1;
            elsif counter = 99999 then
                interrupt <= '1';
                counter <= to_unsigned(0, 32);
            else 
                counter <= counter + 1;
                if interrupt_ack = '1' then
                    interrupt <= '0';
                end if;
            end if;
        end if;
    end process;

end Behavioral;
