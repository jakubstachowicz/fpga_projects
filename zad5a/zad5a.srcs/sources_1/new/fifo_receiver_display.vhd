----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 21.03.2026 19:24:38
-- Design Name: 
-- Module Name: fifo_receiver_display - Behavioral
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

entity fifo_receiver_display is
    -- speed_div_factor = clk_speed / (2 * uart_speed)
    -- e.g. for 100 MHz clk and 9600 bps uart: 100 000 000 / (2 * 9600) = 5208
    Generic ( speed_div_factor : unsigned (15 downto 0) := to_unsigned(5208, 16) );
    Port ( -- clock and uart interface
           clk_i : in STD_LOGIC;
           RXD_i : in STD_LOGIC;
           -- fifo output interface
           rd_en : IN STD_LOGIC;
           dout : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
           full : OUT STD_LOGIC;
           empty : OUT STD_LOGIC;
           -- additional force unload logic
           force_fifo_unload_o : out STD_LOGIC;
           force_fifo_unload_ack_i : in STD_LOGIC;
           -- segment display & overflow led
           ld0 : out STD_LOGIC;
           led7_an_o : out STD_LOGIC_VECTOR (3 downto 0);
           led7_seg_o : out STD_LOGIC_VECTOR (7 downto 0));
end fifo_receiver_display;

architecture Behavioral of fifo_receiver_display is
    COMPONENT fifo_mem
      PORT (
        clk : IN STD_LOGIC;
        din : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        wr_en : IN STD_LOGIC;
        rd_en : IN STD_LOGIC;
        dout : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        full : OUT STD_LOGIC;
        empty : OUT STD_LOGIC 
      );
    END COMPONENT;
    
    component byte_display is
        Port ( byte_i : in STD_LOGIC_VECTOR (7 downto 0);
               clk_i : in STD_LOGIC;
               latch_enable_i : in STD_LOGIC;
               rst_i : in STD_LOGIC;
               led7_an_o : out STD_LOGIC_VECTOR (3 downto 0);
               led7_seg_o : out STD_LOGIC_VECTOR (7 downto 0));
    end component byte_display;
    
    component uart_receiver is
        -- speed_div_factor = clk_speed / (2 * uart_speed)
        -- e.g. for 100 MHz clk and 9600 bps uart: 100 000 000 / (2 * 9600) = 5208
        Generic ( speed_div_factor : unsigned (15 downto 0) := to_unsigned(5208, 16) );
        Port ( clk_i : in STD_LOGIC;
               rst_i : in STD_LOGIC;  -- async reset (active high) invalidates data and forces receiver into waiting state
               rx_i : in STD_LOGIC;
               data_o : out STD_LOGIC_VECTOR (7 downto 0);
               data_valid_o : out STD_LOGIC;  -- high if data is valid, low if new data is being received or read_confirm is high
               read_confirm_i : in STD_LOGIC);
    end component uart_receiver;
    
    signal uart_data : STD_LOGIC_VECTOR (7 downto 0);
    signal data_valid_write_enable : STD_LOGIC;
    signal read_confirm : STD_LOGIC := '0';
    signal actual_wr_en : STD_LOGIC;
    signal fifo_full : STD_LOGIC;
    signal fifo_empty : STD_LOGIC;
    signal overflow : STD_LOGIC := '0';
    signal force_fifo_unload : STD_LOGIC := '0';
    signal buffer_counter : unsigned (7 downto 0) := to_unsigned(0, 8);
    signal should_force_unload : STD_LOGIC := '0';
    
begin 
    byte_display_instance : byte_display
    port map (
        byte_i => uart_data,
        clk_i => clk_i,
        latch_enable_i => data_valid_write_enable,
        rst_i => '0',
        led7_an_o  => led7_an_o,
        led7_seg_o => led7_seg_o
    );

    uart_receiver_instance : uart_receiver
    generic map (
        speed_div_factor => speed_div_factor
    )
    port map (
        clk_i => clk_i,
        rst_i => '0',
        rx_i => RXD_i,
        data_o => uart_data,
        data_valid_o => data_valid_write_enable,
        read_confirm_i => read_confirm
    );

    fifo_instance : fifo_mem
    port map (
        clk => clk_i,
        din => uart_data,
        wr_en => actual_wr_en,
        rd_en => rd_en,
        dout => dout,
        full => fifo_full,
        empty => fifo_empty
    );
    
    actual_wr_en <= (not read_confirm) and data_valid_write_enable;
    full <= fifo_full;
    empty <= fifo_empty;
    ld0 <= overflow;
    force_fifo_unload_o <= force_fifo_unload;

    process(clk_i)
    begin
        if rising_edge(clk_i) then
            -- read confirm (for uart) and overflow (for led) handling
            -- alongside buffer counter increment/set-zero handling
            if data_valid_write_enable = '1' and read_confirm = '0' then
                if fifo_full = '1' then
                    read_confirm <= '0';
                    overflow <= '1';
                else
                    if buffer_counter >= 17 or uart_data = "00001101" then
                        should_force_unload <= '1';
                        buffer_counter <= to_unsigned(0, 8);
                        read_confirm <= '1';
                        overflow <= '0';
                    else 
                        buffer_counter <= buffer_counter + 1;
                        read_confirm <= '1';
                        overflow <= '0';
                    end if;
                end if;
            else
                read_confirm <= '0';
                overflow <= '0';
            end if;
            
            -- force fifo unload handling, >=18 <=> >17 or enter (13)
            if should_force_unload = '1' then
                should_force_unload <= '0';
                force_fifo_unload <= '1';
            else 
                if force_fifo_unload_ack_i = '1' then
                    force_fifo_unload <= '0';
                end if;
            end if;
        end if;
    end process;
end Behavioral;