library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity wb_game is
Port ( clk_i : in std_logic;
rst_i : in std_logic;
adr_o : out std_logic_vector(31 downto 0);
dat_i : in std_logic_vector(31 downto 0);
dat_o : out std_logic_vector(31 downto 0);
irq_i : in STD_LOGIC;
irqv_i : in STD_LOGIC_VECTOR(1 downto 0);
ack_i : in std_logic;
cyc_o : out std_logic;
stb_o : out std_logic;
we_o : out std_logic);
end wb_game;

architecture Behavioral of wb_game is

constant sramID : STD_LOGIC_VECTOR(1 downto 0) := "00";
constant ps2ID : STD_LOGIC_VECTOR(1 downto 0) := "01";
constant dispID : STD_LOGIC_VECTOR(1 downto 0) := "10";
constant led8ID : STD_LOGIC_VECTOR(1 downto 0) := "11";

constant rowWidth : integer := 64;
constant gridpix : integer := rowWidth * 480;

TYPE state_type IS ( reset, initClear, holdClear, incAddr,
							incRaw, initRead, holdRead, releaseRead,
							initWrite, holdWrite, incRW,
							idle);
SIGNAL state : state_type := reset;
signal scanIn, asciiV : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
signal keyUp : STD_LOGIC := '0';

-- display variables:
signal dLine : integer := 0;	-- lines 0 thru 11 of character
signal pixel : STD_LOGIC_VECTOR (7 downto 0);
signal addr : STD_LOGIC_VECTOR(17 downto 0) := (others => '0');
signal readaddr : STD_LOGIC_VECTOR(17 downto 0) := "00" & x"9600";
signal adr_oTemp, adr_oI : std_logic_vector(31 downto 0);

signal dataReg : STD_LOGIC_VECTOR(31 downto 0);	-- record incoming data from SRAM

begin

adr_o <= adr_oI;

cyc_o <= '1' when (state = initClear or state = holdClear or
						 state = initRead or state = holdRead or
						 state = initWrite or state = holdWrite) else '0';
stb_o <= '1' when (state = initClear or state = holdClear or
						 state = initRead or state = holdRead or
						 state = initWrite or state = holdWrite) else '0';
we_o <=  '1' when (state = initClear or state = holdClear or
						 state = initWrite or state = holdWrite) else '0';

process(rst_i, clk_i) is -- input / output moore state machine
begin
if rst_i = '1' then	-- initialize all values
	state <= reset;
elsif clk_i'event and clk_i = '1' then -- rst_i = '0'
	case state is
-- Initialize display to black
		when reset =>
			keyUp <= '0';
			dLine <= 0;
			adr_oI <= (others => '0');	-- extend 16 bit address to 32 bit
			dat_o <= (others => '0');
			addr <= "000000000000000000";	-- start over
			offset <= offset + 1;
			state <= initClear;
		when initClear =>
			adr_oI <= "00000000000000" & addr;	-- extend 18 bit address to 32 bit
			state <= holdClear;
		when holdClear =>
			if ack_i = '1' then
				state <= incAddr;
			end if;
		when incAddr =>
			addr <= addr + 1;	-- increments to next address
			if addr = "00" & x"95FF" then	-- last row, column, line
				state <= incRaw;
			else
				state <= initClear;
			end if;
-- Initialization complete
		when incRaw =>	-- read/write new raw data (readaddr is not cleared on reset)
			addr <= "000000000000000000";	-- start over
			state <= initRead;
-- Load memory random bits to grid
		when initRead =>
			adr_oI <= "00000000000000" & readaddr;	-- extend 18 bit address to 32 bit
			state <= holdRead;
		when holdRead =>
			dataReg <= dat_i; -- latch data value
			if ack_i = '1' then
				state <= releaseRead;
			end if;
		when releaseRead =>
			dat_o <= (others => '0');
			dat_o(29) <= dataReg(29);	-- retain green pixels
			dat_o(25) <= dataReg(25);
			dat_o(21) <= dataReg(21);
			dat_o(17) <= dataReg(17);
			dat_o(13) <= dataReg(13);
			dat_o(9) <= dataReg(9);
			dat_o(5) <= dataReg(5);
			dat_o(1) <= dataReg(1);			
			state <= initWrite;
		when initWrite =>
			adr_oI <= "00000000000000" & addr;	-- extend 18 bit address to 32 bit
			state <= holdWrite;
		when holdWrite =>
			if ack_i = '1' then
				state <= incRW;
			end if;
		when incRW =>
			addr <= addr + 1;	-- increments to next address
			readaddr <= readaddr + 1;
			if addr = "00" & x"95FF" then	-- last row, column, line
				state <= idle;
			else
				state <= initRead;
			end if;
		when idle =>
			state <= idle;
	end case;
end if;
end process;

end Behavioral;

