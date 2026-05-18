library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity painter is
    Port (
        clk_i   : in  STD_LOGIC;                         
        btn_i   : in  STD_LOGIC_VECTOR(3 downto 0);      
        sw_i    : in  STD_LOGIC_VECTOR(7 downto 0);      
        addr_o  : out STD_LOGIC_VECTOR(18 downto 0);     
        data_o  : out STD_LOGIC_VECTOR(0 downto 0);      
        we_o    : out STD_LOGIC_VECTOR(0 downto 0)       
    );
end painter;

architecture Behavioral of painter is

    COMPONENT singen
      PORT (
        aclk : IN STD_LOGIC;
        aresetn : IN STD_LOGIC;
        aclken : IN STD_LOGIC;
        s_axis_config_tvalid : IN STD_LOGIC;
        s_axis_config_tdata : IN STD_LOGIC_VECTOR(15 DOWNTO 0); 
        s_axis_config_tlast : IN STD_LOGIC;
        m_axis_data_tvalid : OUT STD_LOGIC;
        m_axis_data_tdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)   
      );
    END COMPONENT;

    signal dds_aresetn : std_logic := '1';
    signal dds_aclken  : std_logic := '1';
    signal cfg_tvalid  : std_logic := '0';
    signal cfg_tdata   : std_logic_vector(15 downto 0) := (others => '0');
    signal cfg_tlast   : std_logic := '0';
    signal dds_tvalid  : std_logic;
    signal dds_tdata   : std_logic_vector(31 downto 0);

    signal reg_f1 : std_logic_vector(7 downto 0) := x"01"; 
    signal reg_f2 : std_logic_vector(7 downto 0) := x"07"; 
    signal reg_A  : integer := 48;  
    signal reg_B  : integer := 48;  

    signal btn_prev : std_logic_vector(3 downto 0) := (others => '0');

    type state_type is (BOOT_CLEAR, DRAWING, BTN_CLEAR, RESET_DDS_LOW, RESET_DDS_HIGH, CONFIG_CH1, CONFIG_CH2);
    signal state : state_type := BOOT_CLEAR;
    signal clear_addr : integer range 0 to 307199 := 0;

    signal dds_chan_idx : std_logic := '0'; 
    signal sin1, cos1   : integer := 0;
    signal sin2, cos2   : integer := 0;
    
    signal x_val, y_val : integer := 0;
    signal x_screen, y_screen : integer := 0;
    
    signal math_trigger : std_logic := '0';
    signal write_req    : std_logic := '0';

begin

    u_singen : singen
      PORT MAP (
        aclk                 => clk_i,
        aresetn              => dds_aresetn,
        aclken               => dds_aclken,
        s_axis_config_tvalid => cfg_tvalid,
        s_axis_config_tdata  => cfg_tdata,
        s_axis_config_tlast  => cfg_tlast,
        m_axis_data_tvalid   => dds_tvalid,
        m_axis_data_tdata    => dds_tdata
      );

    process(clk_i)
    begin
        if rising_edge(clk_i) then
            btn_prev <= btn_i;

            if btn_i(3) = '1' and btn_prev(3) = '0' then
                reg_f1 <= sw_i; 
            end if;

            if btn_i(2) = '1' and btn_prev(2) = '0' then
                reg_f2 <= sw_i; 
            end if;

            if btn_i(1) = '1' and btn_prev(1) = '0' then
                reg_A <= to_integer(unsigned(sw_i(7 downto 4))) * 16;
                reg_B <= to_integer(unsigned(sw_i(3 downto 0))) * 4;
            end if;
        end if;
    end process;

    process(clk_i)
    begin
        if rising_edge(clk_i) then
            math_trigger <= '0';
            write_req <= '0';

            if dds_aclken = '0' then
                dds_chan_idx <= '0';

            elsif dds_tvalid = '1' then
                if dds_chan_idx = '0' then
                    sin1 <= to_integer(signed(dds_tdata(26 downto 16)));
                    cos1 <= to_integer(signed(dds_tdata(10 downto 0)));
                    dds_chan_idx <= '1';
                else
                    sin2 <= to_integer(signed(dds_tdata(26 downto 16)));
                    cos2 <= to_integer(signed(dds_tdata(10 downto 0)));
                    dds_chan_idx <= '0';
                    math_trigger <= '1'; 
                end if;
            end if;

            if math_trigger = '1' then
                x_val <= (reg_A * cos1) / 1024 - (reg_B * cos2) / 1024;
                y_val <= (reg_A * sin1) / 1024 - (reg_B * sin2) / 1024;
                
                x_screen <= 320 + x_val; 
                y_screen <= 240 - y_val; 
                
                if (x_screen >= 0) and (x_screen < 640) and (y_screen >= 0) and (y_screen < 480) then
                    write_req <= '1';
                end if;
            end if;
            
        end if;
    end process;

    process(clk_i)
    begin
        if rising_edge(clk_i) then
            cfg_tvalid <= '0';
            cfg_tlast  <= '0';
            we_o       <= "0";

            case state is
                
                when BOOT_CLEAR =>
                    dds_aclken <= '0'; 
                    we_o <= "1";
                    data_o <= "0";
                    addr_o <= std_logic_vector(to_unsigned(clear_addr, 19));
                    
                    if clear_addr = 307199 then
                        state <= DRAWING; 
                        clear_addr <= 0;
                        dds_aclken <= '1';
                    else
                        clear_addr <= clear_addr + 1;
                    end if;

                when DRAWING =>
                    dds_aclken <= '1';
                    
                    if write_req = '1' then
                        data_o <= "1";
                        we_o <= "1";
                        addr_o <= std_logic_vector(to_unsigned(x_screen + (640 * y_screen), 19));
                    end if;

                    if btn_i(0) = '1' and btn_prev(0) = '0' then
                        state <= BTN_CLEAR;
                        clear_addr <= 0;
                        dds_aclken <= '0';

                    end if;

                when BTN_CLEAR =>
                    dds_aclken <= '0';
                    we_o <= "1";
                    data_o <= "0";
                    addr_o <= std_logic_vector(to_unsigned(clear_addr, 19));
                    
                    if clear_addr = 307199 then
                        state <= RESET_DDS_LOW;
                        clear_addr <= 0;
                    else
                        clear_addr <= clear_addr + 1;
                    end if;

                when RESET_DDS_LOW =>
                    dds_aclken <= '1'; 
                    dds_aresetn <= '0';
                    state <= RESET_DDS_HIGH;

                when RESET_DDS_HIGH =>
                    dds_aresetn <= '1';
                    state <= CONFIG_CH1;

                when CONFIG_CH1 =>
                    cfg_tvalid <= '1';
                    cfg_tlast  <= '0';
                    cfg_tdata  <= x"00" & reg_f1; 
                    state <= CONFIG_CH2;

                when CONFIG_CH2 =>
                    cfg_tvalid <= '1';
                    cfg_tlast  <= '1';
                    cfg_tdata  <= x"00" & reg_f2; 
                    state <= DRAWING;

            end case;
        end if;
    end process;

end Behavioral;
