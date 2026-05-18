library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity vga_generator is
	Port (
		clk_i : in STD_LOGIC;
		data_i : in STD_LOGIC_VECTOR (0 downto 0);
		addr_o : out STD_LOGIC_VECTOR (18 downto 0);
		red_o : out STD_LOGIC_VECTOR (3 downto 0);
		green_o : out STD_LOGIC_VECTOR (3 downto 0);
		blue_o : out STD_LOGIC_VECTOR (3 downto 0);
		hsync_o : out STD_LOGIC;
		vsync_o : out STD_LOGIC
	);
end vga_generator;

architecture Behavioral of vga_generator is
	signal div_ctr : integer range 0 to 3 := 0;
	signal h_ctr : integer range 0 to 799 := 0;
	signal v_ctr : integer range 0 to 524 := 0;

	signal out_pxl : STD_LOGIC := '0';

begin
    -- aktualizacja licznikow
	process(clk_i)
	begin
		if rising_edge(clk_i) then
			if div_ctr = 3 then
				div_ctr <= 0;

				if h_ctr = 799 then
					h_ctr <= 0;
					if v_ctr = 524 then
						v_ctr <= 0;
					else
						v_ctr <= v_ctr + 1;
					end if;
				else
					h_ctr <= h_ctr + 1;
				end if;
			else
				div_ctr <= div_ctr + 1;
			end if;
		end if;
	end process;

    -- generowanie sygnalow synchronizacji pion i horyz
	process(clk_i)
	begin
		if rising_edge(clk_i) then
			if (h_ctr >= 640 + 16) and (h_ctr < 640 + 16 + 96) then
				hsync_o <= '0';
			else
				hsync_o <= '1';
			end if;

			if (v_ctr >= 480 + 10) and (v_ctr < 480 + 10 + 2) then
				vsync_o <= '0';
			else
				vsync_o <= '1';
			end if;
		end if;
	end process;

    -- rysowanie piksela lub blanking period
	process(clk_i)
	begin
		if rising_edge(clk_i) then
			if (h_ctr >= 640) or (v_ctr >= 480) then
				out_pxl <= '0';
			else
				if div_ctr = 0 then
					addr_o <= std_logic_vector(to_unsigned(h_ctr + 640 * v_ctr, 19));
				elsif div_ctr = 2 then
					out_pxl <= data_i(0);
				end if;
			end if;
		end if;
	end process;

	red_o <= (others => out_pxl);
	green_o <= (others => out_pxl);
	blue_o <= (others => out_pxl);

end Behavioral;
