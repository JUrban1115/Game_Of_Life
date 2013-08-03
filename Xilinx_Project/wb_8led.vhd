library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity wb_8led is
Port ( clk_i : in std_logic;
rst_i : in std_logic;
adr_i : in std_logic_vector(31 downto 0);
dat_i : in std_logic_vector(31 downto 0);
dat_o : out std_logic_vector(31 downto 0);
ack_o : out std_logic;
stb_i : in std_logic;
we_i : in std_logic;
-- 8LED Output
leds_o : out STD_LOGIC_VECTOR(7 downto 0) := (others => '0'));
end wb_8led;

architecture Behavioral of wb_8led is

begin
process(rst_i, clk_i) is
begin
if rst_i = '1' then
	leds_o <= (others => '0');	-- LEDs off upon reset
elsif clk_i'event and clk_i = '1' then
	if stb_i = '1' and we_i = '1' then
					-- write event on 8LED slave unit
		leds_o <= dat_i(7 downto 0); -- latch led input values
		ack_o <= '1';
	else
		ack_o <= '0';
	end if;
end if;
end process;

end Behavioral;

-- accept data input of last character pressed
-- hold value and display on LEDs
-- activate LEDs
