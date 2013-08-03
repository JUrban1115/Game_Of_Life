library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity wb_led is	-- display output slave ID := "10"
Port ( clk_i : in std_logic;
rst_i : in std_logic;
adr_i : in std_logic_vector(31 downto 0);
dat_i : in std_logic_vector(31 downto 0);
ack_o : out std_logic;
stb_i : in std_logic;
we_i : in std_logic;
digit : out  STD_LOGIC_VECTOR (3 downto 0);
segment : out  STD_LOGIC_VECTOR (7 downto 0));
end wb_led;

architecture Behavioral of wb_led is

-- input is ascii codes from reader
-- delete capability w/shift right

component ledCont is	-- control logic
    Port ( clk_i : in STD_LOGIC;
			  rst_i : in STD_LOGIC;
           stb_i : in  STD_LOGIC;
           we_i : in  STD_LOGIC;
			  dat_i : in STD_LOGIC_VECTOR (15 downto 0);
           ack_o : out  STD_LOGIC;
		-- can I use an array here?
           char0 : out  STD_LOGIC_VECTOR (7 downto 0);
           char1 : out  STD_LOGIC_VECTOR (7 downto 0);
           char2 : out  STD_LOGIC_VECTOR (7 downto 0);
           char3 : out  STD_LOGIC_VECTOR (7 downto 0);
           char4 : out  STD_LOGIC_VECTOR (7 downto 0);
           char5 : out  STD_LOGIC_VECTOR (7 downto 0);
           char6 : out  STD_LOGIC_VECTOR (7 downto 0);
           char7 : out  STD_LOGIC_VECTOR (7 downto 0));
end component ledCont;

component clkDivider is -- 1 ms clk
    Port ( clk : in  STD_LOGIC;
				reset : in STD_LOGIC;
           divClk : out  STD_LOGIC);
end component clkDivider;

component string2leds is
    Port ( char0, char1, char2, char3, char4, char5, 
				char6, char7 : in std_logic_vector(7 downto 0);
		segment : out std_logic_vector(7 downto 0);
		digit : out std_logic_vector(3 downto 0);
		enable : in std_logic;
		onemsec_clk : in std_logic;
		sys_rst : in std_logic );
end component string2leds;

signal milliclk: STD_LOGIC;
signal char0, char1, char2, char3, char4, char5, char6,
	char7: STD_LOGIC_VECTOR(7 downto 0);

begin
cont : ledCont port map (clk_i, rst_i, stb_i, we_i, 
						dat_i (15 downto 0), ack_o, char0, char1, char2, char3, 
						char4, char5, char6, char7);
clkd : clkDivider port map (clk_i, rst_i, milliclk);
disp : string2leds port map (char0, char1, char2, char3, char4, 
		char5, char6, char7, segment, digit, '1', milliclk, rst_i);

end Behavioral;

