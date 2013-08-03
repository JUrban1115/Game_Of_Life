library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- input is ascii codes from reader
-- delete capability w/shift right

entity ledCont is	-- control logic
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
end ledCont;

architecture Behavioral of ledCont is

type charReg is array (0 to 7) of STD_LOGIC_VECTOR (7 downto 0);
signal CReg: charReg := (others => x"20");

TYPE state_type IS ( idle, inputC, holdInput );
SIGNAL state : state_type := idle;		-- starts in idle mode


begin

char0 <= CReg(0);
char1 <= CReg(1);
char2 <= CReg(2);
char3 <= CReg(3);
char4 <= CReg(4);
char5 <= CReg(5);
char6 <= CReg(6);
char7 <= CReg(7);

-- needs delete capability here - check for delete ascii x"08"

process(rst_i, clk_i) is
begin
if rst_i = '1' then
	CReg <= (others => x"20");	-- values -> spaces upon reset
elsif clk_i'event and clk_i = '1' then
	case state is
		when idle =>
			ack_o <= '0';	-- clear acknowledge
			if stb_i = '1' and we_i = '1' then	-- write event on Disp slave unit
				state <= inputC;
			end if;
		when inputC =>
			if dat_i(7 downto 0) = x"08" then	-- ascii delete
				CReg(0 to 6) <= CReg(1 to 7);
				CReg(7) <= x"20";	-- fill in left with spaces
			else
				CReg(0) <= dat_i(7 downto 0); -- latch led input values
				CReg(1 to 7) <= CReg(0 to 6); -- new value -> shift left
						-- CReg(0) is newest char
			end if;
			ack_o <= '1';
			state <= holdInput;
		when holdInput =>
			if stb_i = '0' then
				state <= idle;
			end if;
	end case;
end if;
end process;

end Behavioral;

