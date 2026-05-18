library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity top is
	Port (
		clk_i : in STD_LOGIC;
		btn_i : in STD_LOGIC_VECTOR (3 downto 0);
		sw_i : in STD_LOGIC_VECTOR (7 downto 0);
		red_o : out STD_LOGIC_VECTOR (3 downto 0);
		green_o : out STD_LOGIC_VECTOR (3 downto 0);
		blue_o : out STD_LOGIC_VECTOR (3 downto 0);
		hsync_o : out STD_LOGIC;
		vsync_o : out STD_LOGIC
	);
end top;

architecture Behavioral of top is
	COMPONENT video_mem
		PORT (
			clka : IN STD_LOGIC;
			wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
			addra : IN STD_LOGIC_VECTOR(18 DOWNTO 0);
			dina : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
			clkb : IN STD_LOGIC;
			addrb : IN STD_LOGIC_VECTOR(18 DOWNTO 0);
			doutb : OUT STD_LOGIC_VECTOR(0 DOWNTO 0)
		);
	END COMPONENT;

	COMPONENT painter
		Port (
			clk_i : in STD_LOGIC;
			btn_i : in STD_LOGIC_VECTOR(3 downto 0);
			sw_i : in STD_LOGIC_VECTOR(7 downto 0);
			addr_o : out STD_LOGIC_VECTOR(18 downto 0);
			data_o : out STD_LOGIC_VECTOR(0 downto 0);
			we_o : out STD_LOGIC_VECTOR(0 downto 0)
		);
	END COMPONENT;

	COMPONENT vga_generator
		Port (
			clk_i : in STD_LOGIC;
			data_i : in STD_LOGIC_VECTOR(0 downto 0);
			addr_o : out STD_LOGIC_VECTOR(18 downto 0);
			red_o : out STD_LOGIC_VECTOR(3 downto 0);
			green_o : out STD_LOGIC_VECTOR(3 downto 0);
			blue_o : out STD_LOGIC_VECTOR(3 downto 0);
			hsync_o : out STD_LOGIC;
			vsync_o : out STD_LOGIC
		);
	END COMPONENT;


	signal ram_wr_addr : STD_LOGIC_VECTOR(18 downto 0);
	signal ram_wr_data : STD_LOGIC_VECTOR(0 downto 0);
	signal ram_wr_en : STD_LOGIC_VECTOR(0 downto 0);

	signal ram_rd_addr : STD_LOGIC_VECTOR(18 downto 0);
	signal ram_rd_data : STD_LOGIC_VECTOR(0 downto 0);

begin
	painter_instance: painter
		port map (
			clk_i => clk_i,
			btn_i => btn_i,
			sw_i => sw_i,
			addr_o => ram_wr_addr,
			data_o => ram_wr_data,
			we_o => ram_wr_en
		);


	video_mem_instance : video_mem
		PORT MAP (
			clka => clk_i,
			wea => ram_wr_en,
			addra => ram_wr_addr,
			dina => ram_wr_data,
			clkb => clk_i,
			addrb => ram_rd_addr,
			doutb => ram_rd_data
		);


	vga_gen_instance: vga_generator
		port map (
			clk_i => clk_i,
			data_i => ram_rd_data,
			addr_o => ram_rd_addr,
			red_o => red_o,
			green_o => green_o,
			blue_o => blue_o,
			hsync_o => hsync_o,
			vsync_o => vsync_o
		);

end Behavioral;
