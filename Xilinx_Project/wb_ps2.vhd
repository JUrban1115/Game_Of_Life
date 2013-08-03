library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity wb_ps2 is
Port ( clk_i : in std_logic;
rst_i : in std_logic;
adr_i : in std_logic_vector(31 downto 0);
dat_i : in std_logic_vector(31 downto 0);
dat_o : out std_logic_vector(31 downto 0) := (others => '0');
irq_o : out std_logic := '0';
ack_o : out std_logic := '0';
stb_i : in std_logic;
we_i : in std_logic;
-- PS/2 inputs
ps2clk : in STD_LOGIC;
ps2data : in STD_LOGIC);
end wb_ps2;

architecture Behavioral of wb_ps2 is

component ps2conv is
	port (clk_i : in STD_LOGIC;
	rst_i : in STD_LOGIC;
	scanIn : in STD_LOGIC_VECTOR (7 downto 0);
	startConv : in STD_LOGIC;
	convDone : out STD_LOGIC;
	asciiO : out STD_LOGIC_VECTOR (7 downto 0));
end component ps2conv;

-- serial to parallel scancode shift register signals
signal scanQ : STD_LOGIC_VECTOR (10 downto 0) := (others => '1'); -- scan shift reg
signal clearScan : STD_LOGIC := '0'; -- reset scan code input
signal scanReady : STD_LOGIC := '0'; -- scan code output ready

begin

-- serial to parallel scancode shift register
process(clearScan, ps2clk) is
begin
if clearScan = '1' then
	scanReady <= '0';
	scanQ <= (others => '1'); -- reset to all 1's
					-- allows detect of '0' start bit completely shifted
elsif ps2clk'event and ps2clk = '0' then -- neg edge trigger
	if scanQ(1) = '0' then -- start bit will shift completely, scan code completes
									-- could check parity here if desired
		scanReady <= '1';
	end if;
	scanQ <= ps2data & scanQ(10 downto 1); -- shift right
end if;
end process;

-- main process
process(rst_i, clk_i) is
begin
if rst_i = '1' then
	clearscan <= '1';
elsif clk_i'event and clk_i = '1' then
	clearScan <= '0'; -- this is overridden later if needed
	if scanReady = '1' then
		irq_o <= '1'; -- send interrupt for new scanCode
		dat_o(7 downto 0) <= scanQ(8 downto 1); -- latch scanCode for output
		if stb_i = '1' and we_i = '0' then -- read event
			irq_o <= '0'; -- end interrupt upon master request
			ack_o <= '1'; -- send acknowledge - time to read data
			clearScan <= '1'; -- this scan cycle finished, strobe clearScan
		else
			ack_o <= '0';
		end if;
	end if;
end if;
end process;

end Behavioral;