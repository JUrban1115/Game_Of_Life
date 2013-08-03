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

constant lastCol : integer := 3;	-- number of columns - 1 (8 pixels/col)
constant rowWidth : integer := ((lastCol + 1) * 8);

TYPE state_type IS ( reset, initClear, holdClear, incAddr,
							incRaw, initRead, holdRead, releaseRead,
							initWrite, holdWrite, incRW, waitGen, nextGen,
							clearCaches, loadLine, holdLine, releaseLine,
							checkRow, calcNeighbors, calcGen, prepNext,
							initNext, holdNext, waitNext, incNext, rotCache);
SIGNAL state : state_type := reset;
signal scanIn, asciiV : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
signal keyUp : STD_LOGIC := '0';

-- display variables:
signal dLine : integer := 0;	-- lines 0 thru 11 of character
signal dRow : integer := 0;	-- rows 0 thru 479 of display
signal dCol : integer := 0;	-- columns 0 thru (up to 80)
signal pixel : STD_LOGIC_VECTOR (7 downto 0);
signal addr : STD_LOGIC_VECTOR(17 downto 0) := (others => '0');
signal nextaddr : STD_LOGIC_VECTOR(17 downto 0) := "00" & x"0050";
signal readaddr : STD_LOGIC_VECTOR(17 downto 0) := "00" & x"9600";
signal adr_oTemp, adr_oI : std_logic_vector(31 downto 0);

signal dataReg : STD_LOGIC_VECTOR(31 downto 0);	-- record incoming data from SRAM
signal cache0G, cache1G, cache2G, nextG : STD_LOGIC_VECTOR((rowWidth + 1) downto 0);
	-- extra zero bits on either end
	-- Green species caches. 0 is previous row, 1 current row, 2 next row, next is next gen
type border is array (rowWidth downto 1) of STD_LOGIC_VECTOR(3 downto 0);	-- array of bordering cell count
signal neighbors : border;

constant genTime : integer := 25000000; -- 25000000 = 1/2 sec
signal genClk : STD_LOGIC; -- pulse each 1/2 sec triggers generation
signal cnt : integer := 0;	-- genClk counter

begin

adr_o <= adr_oI;

cyc_o <= '1' when (state = initClear or state = holdClear or
						 state = initRead or state = holdRead or
						 state = initWrite or state = holdWrite or
						 state = loadLine or state = holdLine or
						 state = initNext or state = holdNext) else '0';
stb_o <= '1' when (state = initClear or state = holdClear or
						 state = initRead or state = holdRead or
						 state = initWrite or state = holdWrite or
						 state = loadLine or state = holdLine or
						 state = initNext or state = holdNext) else '0';
we_o <=  '1' when (state = initClear or state = holdClear or
						 state = initWrite or state = holdWrite or
						 state = initNext or state = holdNext) else '0';

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
			addr <= "000000000001010000";	-- start at second line
			dRow <= 1;	-- update only rows 1 thru 478 (skip first and last)
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
			dat_o(29) <= dataReg(29) and dataReg(28) and dataReg(30);	-- retain white pixels
			dat_o(25) <= dataReg(25) and dataReg(24) and dataReg(26);
			dat_o(21) <= dataReg(21) and dataReg(20) and dataReg(22);
			dat_o(17) <= dataReg(17) and dataReg(16) and dataReg(18);
			dat_o(13) <= dataReg(13) and dataReg(12) and dataReg(28);
			dat_o(9) <= dataReg(9) and dataReg(8) and dataReg(10);
			dat_o(5) <= dataReg(5) and dataReg(4) and dataReg(6);
			dat_o(1) <= dataReg(1) and dataReg(0) and dataReg(2);			
--			dat_o(29) <= dataReg(29) and dataReg(28);	-- retain yellow pixels
--			dat_o(25) <= dataReg(25) and dataReg(24);
--			dat_o(21) <= dataReg(21) and dataReg(20);
--			dat_o(17) <= dataReg(17) and dataReg(16);
--			dat_o(13) <= dataReg(13) and dataReg(12);
--			dat_o(9) <= dataReg(9) and dataReg(8);
--			dat_o(5) <= dataReg(5) and dataReg(4);
--			dat_o(1) <= dataReg(1) and dataReg(0);			
--			dat_o(29) <= dataReg(29);	-- retain green pixels
--			dat_o(25) <= dataReg(25);
--			dat_o(21) <= dataReg(21);
--			dat_o(17) <= dataReg(17);
--			dat_o(13) <= dataReg(13);
--			dat_o(9) <= dataReg(9);
--			dat_o(5) <= dataReg(5);
--			dat_o(1) <= dataReg(1);			
			state <= initWrite;
		when initWrite =>
			adr_oI <= "00000000000000" & addr;	-- extend 18 bit address to 32 bit
			state <= holdWrite;
		when holdWrite =>
			if ack_i = '1' then
				state <= incRW;
			end if;
		when incRW =>
			if dCol = lastCol then	-- last column
				addr <= addr + (80 - lastCol);	-- increments to next address (80 - last column)
				dCol <= 0;
				dRow <= dRow + 1;
			else
				addr <= addr + 1;
				dCol <= dCol + 1;
			end if;
			readaddr <= readaddr + 1;
			if dCol = lastCol and dRow = 478 then	-- last row, column (rows 1 thru 478)
				dRow <= 0;
				state <= waitGen;
			else
				state <= initRead;
			end if;
-- wait for timer done flag
		when waitGen =>
			if genClk = '1' then
				state <= nextGen;
			else
				state <= waitGen;
			end if;
-- Calculate Future Generations
		when nextGen =>
			state <= clearCaches;
-- initialize caches to zero
		when clearCaches =>
			cache0G <= (others => '0');
			cache1G <= (others => '0');
			cache2G <= (others => '0');
			addr <= (others => '0');	-- start over
			nextaddr <= "00" & x"0050"; -- start over
			dCol <= 0;
			dRow <= 0;
			state <= loadLine;
-- load lines one at a time
		when loadLine =>	-- load next line (8 pix)
			adr_oI <= "00000000000000" & addr;	-- extend 18 bit address to 32 bit
			state <= holdLine;
		when holdLine =>
			for i in 7 downto 0 loop
				cache2G(i + (8 * (lastCol - dCol))) <= dat_i((i * 4) + 1);
--				i.e. cache2G(29) <= dat_i(29);	-- retain green pixels
			end loop;
			if ack_i = '1' then
				state <= releaseLine;
			end if;
		when releaseLine =>
			if dCol = lastCol then	-- last column
				addr <= addr + (80 - lastCol);	-- increments to next address (80 - last column)
				dCol <= 0;
				dRow <= dRow + 1;
				state <= checkRow;		-- row is complete, do calculation
			else
				addr <= addr + 1;
				dCol <= dCol + 1;
				state <= loadLine;	-- continue to load row
			end if;
-- perform calc based on previous, current, next lines
		when checkRow =>
			if dRow = 1 then	-- only row 0 has been loaded, need another row
				state <= rotCache;
			else
				state <= calcNeighbors;
			end if;
		when calcNeighbors =>	-- calculate next generation
			for i in rowWidth downto 1 loop	-- skip either end (extra zero bits) of caches
--				neighbors(i) <= ((a + b) + (c + d)) + ((f + g) + (h + i));	-- count neighboring cells
				neighbors(i) <= "0000" + ("000" + ("00" + cache0G(i-1) + cache0G(i)) + ("00" + cache0G(i+1) + cache1G(i-1))) + 
										("000" + ("00" + cache1G(i+1) + cache2G(i-1)) + ("00" + cache2G(i) + cache2G(i+1)));
			end loop;
			state <= calcGen;
		when calcGen =>	-- determine next generation
			for i in rowWidth downto 1 loop
				if neighbors(i) = "0011" or ((neighbors(i) = "0010") and (cache1G(i) = '1')) then
					nextG(i) <= '1';	-- cell is alive
				else
					nextG(i) <= '0';	-- cell is dead
				end if;
			end loop;
			state <= prepNext;
-- write each line to memory
		when prepNext =>
			nextaddr <= "00" & x"0050";	-- second line
			dRow <= 1;
			dCol <= 0;
			state <= initNext;
		when initNext =>
			dat_o <= (others => '0');
			for i in 7 downto 0 loop	-- output 8 pixels
				dat_o((i*4) + 1) <= nextG(i + (8 * (lastCol - dCol)));
			end loop;
			adr_oI <= "00000000000000" & nextaddr;	-- extend 18 bit address to 32 bit
			state <= holdNext;
		when holdNext =>
			if ack_i = '1' then
--				state <= incNext;
--			end if;
				state <= waitNext;
			end if;
		when waitNext =>
			if genClk = '1' then
				state <= incNext;
			else
				state <= waitNext;
			end if;
		when incNext =>
			if dCol = lastCol then	-- last column
				nextaddr <= nextaddr + (80 - lastCol);	-- increments to next address (80 - last column)
				dCol <= 0;
				dRow <= dRow + 1;
			else
				nextaddr <= nextaddr + 1;
				dCol <= dCol + 1;
			end if;
-- check if last line complete
			if dCol = lastCol and dRow = 478 then	-- last row, column (rows 1 thru 478)
				dRow <= 0;
				state <= waitGen;
			else
				state <= rotCache;
			end if;
-- rotate caches
		when rotCache =>	-- rotate caches
			cache0G <= cache1G;
			cache1G <= cache2G;
			cache2G <= (others => '0');	-- clear last cache;
			state <= loadLine;
	end case;
end if;
end process;

process(clk_i, rst_i)
begin
	if rst_i = '1' then
		cnt <= 0;
	elsif(clk_i'event and clk_i='1') then
		if cnt = genTime then
			cnt <= 0;
			genClk <= '1';
		else
			cnt <= cnt + 1;
			genClk <= '0';
		end if;
	end if;
end process;

end Behavioral;