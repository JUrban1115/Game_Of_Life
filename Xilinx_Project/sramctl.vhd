--------------------------------------------------------------------------------
-- Company: UNIVERSITY OF CONNECTICUT
-- Engineer: John A. Chandy
--
-- Create Date:    16:28:25 11/02/06
-- Module Name:    sramctl - Behavioral
-- Additional Comments:
--   This module is a Wishbone module that provides an interface to external SRAM
--   on the Digilent Starter board
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity sramctl is
	generic  (num_read_waits : natural := 3; num_write_waits : natural := 1);
	Port ( clk_i : in std_logic;
          rst_i : in std_logic;
          adr_i : in std_logic_vector(31 downto 0);
          dat_i : in std_logic_vector(31 downto 0);
          dat_o : out std_logic_vector(31 downto 0);
          ack_o : out std_logic;
          stb_i : in std_logic;
          we_i  : in std_logic;
          sram_addr : out std_logic_vector(17 downto 0);
          sram_oe : out std_logic;
          sram_we : out std_logic;
          sram_io1 : inout std_logic_vector(15 downto 0);
          sram_ce1 : out std_logic;
          sram_ub1 : out std_logic;
          sram_lb1 : out std_logic;
          sram_io2 : inout std_logic_vector(15 downto 0);
          sram_ce2 : out std_logic;
          sram_ub2 : out std_logic;
          sram_lb2 : out std_logic
		);
end sramctl;

architecture Behavioral of sramctl is
	signal be, we : std_logic;
	signal ready : std_logic;
	signal waits : natural;
begin

	-- this process basically counts for num_write_waits or num_read_waits clock cycles depending
	-- on whether its a read or a write
	process(clk_i,rst_i)
	begin
		if (rst_i='1') then
			waits <= 0;
		elsif (clk_i'event and clk_i='1') then
			if ( (we_i='1' and waits<num_write_waits) or (we_i='0' and waits<num_read_waits) ) then
				waits <= waits + 1;
			elsif ( (we_i='1' and waits>=num_write_waits) or (we_i='0' and waits>=num_read_waits) ) then
				waits <= 0;
			end if;
		end if;
	end process;

	-- this process figures out whether to assert the ready/ack signal based on whether the
	-- waits count has reached num_write_waits or num_read_waits
	process(stb_i,we_i,waits)
	variable rready, wready : std_logic;
	begin
		if ( num_read_waits = 0 ) then
			rready := not we_i;
		elsif (stb_i='1' and we_i='0' and waits=num_read_waits) then
			rready := '1';
		else
			rready := '0';
		end if;
		if ( num_write_waits = 0 ) then
			wready := we_i;
		elsif (stb_i='1' and we_i='1' and waits=num_write_waits) then
			wready := '1';
		else
			wready := '0';
		end if;

		ready <= wready or rready;
	end process;

	sram_addr <= adr_i(17 downto 0);
	sram_io1 <= dat_i(15 downto 0) when we_i='1' else (others => 'Z');
	sram_io2 <= dat_i(31 downto 16) when we_i='1' else (others => 'Z');
	dat_o <= sram_io2 & sram_io1;
	sram_ce1 <= not stb_i;
	sram_ce2 <= not stb_i;
	we <= '0' when we_i='1' and stb_i='1' else '1';
	sram_we <= we;
--	sram_oe <= not we;
	sram_oe <= '0';
--	be <= not((not we and stb_i) or (we));
   be <= '0';
	sram_ub1 <= be;
	sram_ub2 <= be;
	sram_lb1 <= be;
	sram_lb2 <= be;
	ack_o <= ready;

end Behavioral;
