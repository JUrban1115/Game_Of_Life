library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity borderCnt is
	Port (	a : in integer;
				b : in integer;
				c : in integer;
				d : in integer;
				e : in integer;
				f : in integer;
				g : in integer;
				h : in integer;
				num : out integer);
end borderCnt;

architecture Behavioral of borderCnt is

begin
	num <= ((a + b) + (c + d)) + ((e + f) + (g + h));
end Behavioral;

