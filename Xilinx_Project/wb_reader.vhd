library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity wb_reader is
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
end wb_reader;

architecture Behavioral of wb_reader is

constant sramID : STD_LOGIC_VECTOR(1 downto 0) := "00";
constant startAddr : STD_LOGIC_VECTOR(31 downto 0) := x"00009600";
	-- first address after VGA addresses
constant genTime : integer := 25000000; -- 25000000 = 1/2 sec

signal genClk : STD_LOGIC; -- pulse each 1/2 sec triggers generation
signal cnt : integer := 0;	-- genClk counter

type grid42x82 is array (0 to 41, 0 to 81) of std_logic;
signal initgrid : grid42x82;
signal grid : grid42x82;
signal nxtGrid : grid42x82;
type bord42x82 is array (1 to 40, 1 to 80) of std_logic_vector(3 downto 0);
signal bord : bord42x82;
signal aB,bB,cB,dB,eB,fB,gB,hB,numB : integer := 0;
signal col : integer := 1;	-- column for cell calc

TYPE state_type IS ( reset );
SIGNAL state : state_type := reset;		-- starts in reset mode

TYPE calc_state_type IS ( restart, calcBord, incColB, calcCell, incColC, rotate, output );
SIGNAL calcState : calc_state_type := restart;		-- starts in reset mode

signal initDone : STD_LOGIC := '0';	-- signals completion of initialization
signal outPulse : STD_LOGIC := '0';	-- pulse to trigger sram output

--component borderCnt is
--	Port (	a : in integer;
--				b : in integer;
--				c : in integer;
--				d : in integer;
--				e : in integer;
--				f : in integer;
--				g : in integer;
--				h : in integer;
--				num : out integer);
--end component borderCnt;

begin
--
--brdcnt : borderCnt port map(aB,bB,cB,dB,eB,fB,gB,hB,numB);

-- half second clock to trigger generation. Pulse trigger
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

---- no nested for loops supported in Xilinx ISE
---- bordering cells calc
--process(grid) is
--begin
--	for i in 1 to 40 loop	-- active rows
--		for j in 1 to 80 loop	-- active columns @@@@@@@@@ does nested loop work?
--			bord(i,j) <= "0000" + grid(i-1,j-1) + grid(i-1,j) + grid(i-1,j+1) + grid(i,j-1) + grid(i,j+1) + grid(i+1,j-1) + grid(i+1,j) + grid(i+1,j+1);
--		end loop;
--	end loop;
--end process;

-- @@@@@@@@@@@@@@@@@@@@@@@ need to input starting values into this process @@@@@@@@@@@@@@@@@@@@@@@@@@@
outPulse <= '1' when calcState = output else '0';	-- pulse to trigger sram output process
-- w/out nested for loop. Rows in parallel, columns sequential
-- bordering cells calc
process(clk_i) is
begin
	if rst_i = '1' then
		col <= 1;
		calcState <= restart;
	elsif clk_i'event and clk_i = '1' then
		case calcState is
			when restart =>
				if initDone = '1' then
					calcState <= calcBord;
				end if;
-- calculate border count for each cell
			when calcBord =>
				for i in 1 to 40 loop	-- active rows
					bord(i,col) <= "0000" + grid(i-1,col-1) + grid(i-1,col) + grid(i-1,col+1) + grid(i,col-1) + grid(i,col+1) + grid(i+1,col-1) + grid(i+1,col) + grid(i+1,col+1);
				end loop;
				calcState <= incColB;
			when incColB =>
				if col = 40 then
					col <= 1;
					calcState <= calcCell;
				else
					col <= col + 1;
					calcState <= calcBord;
				end if;
-- calculate nextGen for each cell
			when calcCell =>
				-- calculate live die or born for each cell
				for i in 1 to 40 loop	-- active rows
					if nxtGrid(i,col) = 1 then	-- cell is alive
						if (bord(i,col) = 2) or (bord(i,col) = 3) then	-- cell survives
							nxtGrid(i,col) <= 1;
						else	-- cell dies
							nxtGrid(i,col) <= 0;
						end if;
					else	-- cell is dead
						if bord(i,col) = 3 then	-- cell is born
							nxtGrid(i,col) <= 1;
						else
							nxtGrid(i,col) <= 0;
						end if;
					end if;
				end loop;
				calcState <= incColB;
			when incColC =>
				if col = 40 then
					col <= 1;
					calcState <= rotate;
				else
					col <= col + 1;
					calcState <= calcCell;
				end if;
-- wait for human scale clock, update grid and recalculate
			when rotate =>
				if genClk = '1' then
					grid <= nxtGrid;	-- update cells to new values
					calcState <= output;
				end if;
			when output =>
				calcState <= calcBord;
		end case;
	end if;
end process;

---- calc subsequent generations (parallel)
--process(genClk) is
--begin
--	if genClk'event and genClk = '1' then
--		for i in (1 to 40) loop	-- active rows
--			for j in (1 to 80) loop	-- active columns @@@@@@@@@ does nested loop work?
--				if grid(i,j) = '1' then	-- alive
--					if bord(i,j) = 2 or bord(i,j) = 3 then
--						grid(i,j) <= '1';	-- stays alive
--					else
--						grid(i,j) <= '0';	-- dies
--					end if;
--				else	-- dead
--					if bord(i,j) = 3 then
--						grid(i,j) <= '1';	-- 3 bordering cells -> born
--					else
--						grid(i,j) <= '0'; -- not born
--					end if;
--				end if;
--			end loop;
--		end loop;
--	end if;
--end process;

-- wishbone interface process controlled by main process
	-- upon reset, read from sram into grid
		-- activate initDone upon completion
	-- upon outPulse trigger, write to sram
	-- use:
		--		constant sramID : STD_LOGIC_VECTOR(1 downto 0) := "00";
		--		constant startAddr : STD_LOGIC_VECTOR(31 downto 0) := x"00009600";
		--		signal initgrid : grid42x82;

end Behavioral;