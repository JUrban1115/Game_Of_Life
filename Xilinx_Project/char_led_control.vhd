--------------------------------------------------------------------------------
-- Company: UNIVERSITY OF CONNECTICUT
-- Engineer: John A. Chandy
--
-- Create Date:    04/22/05
-- Module Name:    char_led_control - Behavioral
-- Additional Comments:
--   This module controls the segment lines on the bank 7-segment LED displays
--   on the Digilent Spartan-3 Starter Board.  Each digit is displayed for
--   approximately 1 millisecond.  It is assumed that the clk that is passed in
--   to this module has a period of 1 ms.
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

--  Uncomment the following lines to use the declarations that are
--  provided for instantiating Xilinx primitive components.
--library UNISIM;
--use UNISIM.VComponents.all;

entity char_led_control is
    Port ( clk : in std_logic;
    		 reset : in std_logic;
		 enable : in std_logic;
           segment0 : in std_logic_vector(7 downto 0);
           segment1 : in std_logic_vector(7 downto 0);
           segment2 : in std_logic_vector(7 downto 0);
           segment3 : in std_logic_vector(7 downto 0);
           segment : out std_logic_vector(7 downto 0);
           digit : out std_logic_vector(3 downto 0));
end char_led_control;

architecture Behavioral of char_led_control is
	signal count : std_logic_vector(1 downto 0);
begin

        -- the clk should be a one millisecond clock generated by a higher
        -- level module. This process basically increments a 2 bit counter so
        -- that we can cycle through the 4 digits
 	process(clk,reset)
	begin
		if (reset = '1') then
			count <= "00";
		elsif (clk'event and clk = '1') then
			count <= count + 1;


		end if;
	end process;

        -- this process sets the digit and segment signals depending on what
        -- digit is being addressed - the count signal from the above process
  	process(count,enable,segment0,segment1,segment2,segment3)
	begin
		if ( enable = '1' ) then
			if ( count = "00" ) then
				digit <= "1110";
				segment <= segment0;
			elsif ( count = "01" ) then
				digit <= std_logic_vector'("1101");
				segment <= segment1;
			elsif ( count = "10" ) then
				digit <= std_logic_vector'("1011");
				segment <= segment2;
			else
				digit <= std_logic_vector'("0111");
				segment <= segment3;
			end if;
		else
			digit <= "1111";
		end if;
	end process;

end Behavioral;
