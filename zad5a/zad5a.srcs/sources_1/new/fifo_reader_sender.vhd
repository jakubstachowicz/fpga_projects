----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 21.03.2026 20:09:05
-- Design Name: 
-- Module Name: fifo_reader_sender - Behavioral
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

entity fifo_reader_sender is
    -- speed_div_factor = clk_speed / (2 * uart_speed)
    -- e.g. for 100 MHz clk and 9600 bps uart: 100 000 000 / (2 * 9600) = 5208
    Generic ( speed_div_factor : unsigned (15 downto 0) := to_unsigned(5208, 16) );
    Port ( -- clock and uart interface
           clk_i : in STD_LOGIC;
           TXD_o : out STD_LOGIC;
           -- fifo interface
           fifo_rd_en : out STD_LOGIC;
           fifo_dout : in STD_LOGIC_VECTOR(7 DOWNTO 0);
           fifo_full : in STD_LOGIC;
           fifo_empty : in STD_LOGIC;
           -- additional force unload logic
           force_fifo_unload_i : in STD_LOGIC;
           force_fifo_unload_ack_o : out STD_LOGIC);
end fifo_reader_sender;

architecture Behavioral of fifo_reader_sender is
    component uart_transmitter is
        -- speed_div_factor = clk_speed / (2 * uart_speed)
        -- e.g. for 100 MHz clk and 9600 bps uart: 100 000 000 / (2 * 9600) = 5208
        Generic ( speed_div_factor : unsigned (15 downto 0) := to_unsigned(5208, 16) );
        Port ( clk_i : in STD_LOGIC;
            rst_i : in STD_LOGIC;  -- async reset (active high) forces to stop transmitting
            tx_o : out STD_LOGIC;
            data_i : in STD_LOGIC_VECTOR (7 downto 0);
            lock_and_send_i : in STD_LOGIC;  -- if high and the transmitter is idle, locks the input data to the internal register and starts sending
            send_confirm_o : out STD_LOGIC);  -- high for one clock cycle if the data was locked and is being sent
    end component uart_transmitter;

    COMPONENT char_mem
        PORT (
            clka : IN STD_LOGIC;
            addra : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
            douta : OUT STD_LOGIC_VECTOR(7 DOWNTO 0) 
        );
    END COMPONENT;

    type state_t is (
        IDLE, --> UNLOADING
        UNLOADING, --> UNLOADING_FLIP_RD_EN, SENDING_LINE
        UNLOADING_FLIP_RD_EN, --> UNLOADING_FLIP_RD_EN (comeback)
        SENDING_LINE, --> SENDING_CHAR, IDLE
        SENDING_CHAR, --> SENDING_PIXEL, SENDING_UART_LINEFEED_WAIT
        SENDING_UART_LINEFEED_WAIT, --> SENDING_LINE (2-deep comeback)
        SENDING_PIXEL, --> SENDING_PIXEL_FETCH, SENDING_CHAR (comeback)
        SENDING_PIXEL_FETCH, --> SENDING_FETCHED_PIXEL
        SENDING_FETCHED_PIXEL, --> SENDING_UART_WAIT
        SENDING_UART_WAIT --> SENDING_PIXEL (3-deep comeback)
    );
    signal state : state_t := IDLE;

    signal uart_data : STD_LOGIC_VECTOR (7 downto 0);
    signal lock_and_send : STD_LOGIC := '0';
    signal send_confirm : STD_LOGIC;
    signal fifo_read_enable : STD_LOGIC := '0';
    signal unload_ack : STD_LOGIC := '0';
    
    -- unloaded data signals
    type ram_type is array (0 to 127) of STD_LOGIC_VECTOR (7 downto 0);
    signal ram : ram_type;
    signal size : integer;
    signal data_to_send : STD_LOGIC_VECTOR (7 downto 0);
    signal char_ctr : integer;
    constant line_size : integer := 16;
    signal line_ctr : integer;
    constant pixel_size : integer := 8;
    signal pixel_ctr : integer;
    
    -- rom interface
    signal rom_addra : STD_LOGIC_VECTOR(11 DOWNTO 0);
    signal rom_douta : STD_LOGIC_VECTOR(7 DOWNTO 0);

begin
    uart_transmitter_instance : uart_transmitter
    generic map (
        speed_div_factor => speed_div_factor
    )
    port map (
        clk_i => clk_i,
        rst_i => '0',
        tx_o => TXD_o,
        data_i => uart_data,
        lock_and_send_i => lock_and_send,
        send_confirm_o => send_confirm
    );
    
    char_mem_rom : char_mem
      PORT MAP (
        clka => clk_i,
        addra => rom_addra,
        douta => rom_douta
      );

    fifo_rd_en <= fifo_read_enable;
    force_fifo_unload_ack_o <= unload_ack;

    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if state = IDLE then
                if force_fifo_unload_i = '1' then
                    state <= UNLOADING;
                    size <= 0;
                end if;
            elsif state = UNLOADING then
                if fifo_empty = '0' then
                    ram(size) <= fifo_dout;
                    size <= size + 1;
                    fifo_read_enable <= '1';
                    state <= UNLOADING_FLIP_RD_EN;
                else
                    unload_ack <= '1';
                    state <= SENDING_LINE;
                    line_ctr <= 0;
                end if;
            elsif state = UNLOADING_FLIP_RD_EN then
                fifo_read_enable <= '0';
                state <= UNLOADING;
            elsif state = SENDING_LINE then
                unload_ack <= '0';
                if line_ctr < line_size then
                    line_ctr <= line_ctr + 1;
                    char_ctr <= 0;
                    state <= SENDING_CHAR;
                else
                    state <= IDLE;
                end if;
            elsif state = SENDING_CHAR then
                if char_ctr < size then
                    if ram(char_ctr) = "00001101" then
                        char_ctr <= char_ctr + 1;
                    else
                        char_ctr <= char_ctr + 1;
                        pixel_ctr <= 0;
                        state <= SENDING_PIXEL;
                    end if;
                else
                    uart_data <= "00001010";
                    lock_and_send <= '1';
                    state <= SENDING_UART_LINEFEED_WAIT;
                end if;                
            elsif state = SENDING_UART_LINEFEED_WAIT then
                if send_confirm = '1' then 
                    lock_and_send <= '0';
                    state <= SENDING_LINE;
                end if;
            elsif state = SENDING_PIXEL then
                if pixel_ctr < pixel_size then
                    pixel_ctr <= pixel_ctr + 1;
                    rom_addra <= ram(char_ctr - 1) & std_logic_vector(to_unsigned(line_ctr - 1, 4));
                    state <= SENDING_PIXEL_FETCH;
                else
                    state <= SENDING_CHAR;
                end if;      
            elsif state = SENDING_PIXEL_FETCH then
                state <= SENDING_FETCHED_PIXEL;
            elsif state = SENDING_FETCHED_PIXEL then
                if rom_douta(pixel_ctr - 1) = '0' then
                    uart_data <= "00100000";
                else 
                    if unsigned(ram(char_ctr - 1)) < 32 or unsigned(ram(char_ctr - 1)) > 127 then
                        uart_data <= "00101010";
                    else 
                        uart_data <= ram(char_ctr - 1);
                    end if;
                end if;
                lock_and_send <= '1';
                state <= SENDING_UART_WAIT;
            elsif state = SENDING_UART_WAIT then
                if send_confirm = '1' then 
                    lock_and_send <= '0';
                    state <= SENDING_PIXEL;
                end if;
            end if;
        end if;
    end process;

end Behavioral;
