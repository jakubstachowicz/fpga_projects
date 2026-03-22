----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 21.03.2026 18:30:06
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity top is
    Port ( clk_i : in STD_LOGIC;
           RXD_i : in STD_LOGIC;
           TXD_o : out STD_LOGIC;
           ld0 : out STD_LOGIC;
           led7_an_o : out STD_LOGIC_VECTOR (3 downto 0);
           led7_seg_o : out STD_LOGIC_VECTOR (7 downto 0));
end top;

architecture Behavioral of top is
    component fifo_receiver_display is
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
    end component fifo_receiver_display;
    
    component fifo_reader_sender is
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
    end component fifo_reader_sender;
    
    signal fifo_rd_en : STD_LOGIC;
    signal fifo_dout : STD_LOGIC_VECTOR(7 DOWNTO 0);
    signal fifo_full : STD_LOGIC;
    signal fifo_empty : STD_LOGIC;
    signal force_fifo_unload : STD_LOGIC;
    signal force_fifo_unload_ack : STD_LOGIC;

begin
    fifo_receiver_display_instance : fifo_receiver_display
    port map (
        clk_i => clk_i,
        RXD_i => RXD_i,
        rd_en => fifo_rd_en,
        dout => fifo_dout,
        full => fifo_full,
        empty => fifo_empty,
        force_fifo_unload_o => force_fifo_unload,
        force_fifo_unload_ack_i => force_fifo_unload_ack,
        ld0 => ld0,
        led7_an_o => led7_an_o,
        led7_seg_o => led7_seg_o
    );
    
    fifo_reader_sender_instance : fifo_reader_sender
    port map (
        clk_i => clk_i,
        TXD_o => TXD_o,
        fifo_rd_en => fifo_rd_en,
        fifo_dout => fifo_dout,
        fifo_full => fifo_full,
        fifo_empty => fifo_empty,
        force_fifo_unload_i => force_fifo_unload,
        force_fifo_unload_ack_o => force_fifo_unload_ack
    );

end Behavioral;
