library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity clkDivider is -- 1 ms clk
    Port ( clk : in  STD_LOGIC;
				reset : in STD_LOGIC;
           divClk : out  STD_LOGIC);
end clkDivider;

architecture Behavioral of clkDivider is

constant CLKratio: integer := 50000; -- ratio of system clock to divided clock
signal Q: integer := 0;
signal newClk: STD_LOGIC := '0';

begin

divClk <= newClk;

process(clk, reset)
begin
	if reset = '1' then
		Q <= 0;
		newClk <= '0';
	elsif clk'event and clk = '1' then  -- always counts system clock
		Q <= Q + 1;
	
		if Q = CLKratio then 					-- overrides count if reached CLKratio
			Q <= 0;
			if newClk = '0' then					-- switches divided clock output
				newClk <= '1';
			else
				newClk <= '0';
			end if;
		end if;
	end if;
		
end process;

end Behavioral;

