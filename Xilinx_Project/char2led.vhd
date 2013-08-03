--------------------------------------------------------------------------------
-- Company: UNIVERSITY OF CONNECTICUT
-- Engineer: John A. Chandy
--
-- Create Date:    15:42:43 08/15/05
-- Design Name:    
-- Module Name:    char2led - Behavioral
-- Project Name:   
-- Target Device:  
-- Tool versions:  
-- Description:
--
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity char2led is
    Port ( ascii : in std_logic_vector(7 downto 0);
			  segment : out std_logic_vector(7 downto 1)
			);
end char2led;

architecture Behavioral of char2led is
begin
	with ascii select
		segment(7 downto 1) <= 
				 std_logic_vector'("1111111") when X"20", -- -
				 std_logic_vector'("1011101") when X"22", -- "
				 std_logic_vector'("1011111") when X"27", -- '
				 std_logic_vector'("1111110") when X"2D", -- -
				 std_logic_vector'("1111111") when X"2E", -- -
				 std_logic_vector'("0000001") when X"30", -- 0
				 std_logic_vector'("1001111") when X"31", -- 1
				 std_logic_vector'("0010010") when X"32", -- 2
				 std_logic_vector'("0000110") when X"33",	-- 3
				 std_logic_vector'("1001100") when X"34",	-- 4
				 std_logic_vector'("0100100") when X"35",	-- 5
				 std_logic_vector'("0100000") when X"36",	-- 6
				 std_logic_vector'("0001111") when X"37", -- 7
				 std_logic_vector'("0000000") when X"38", -- 8
				 std_logic_vector'("0000100") when X"39",	-- 9
				 std_logic_vector'("0001000") when X"41",	-- A
				 std_logic_vector'("1100000") when X"42",	-- B (b)
				 std_logic_vector'("0110001") when X"43",	-- C
				 std_logic_vector'("1000010") when X"44",	-- D (d)
				 std_logic_vector'("0110000") when X"45",	-- E
				 std_logic_vector'("0111000") when X"46",	-- F
				 std_logic_vector'("0100001") when X"47", -- G
				 std_logic_vector'("1001000") when X"48", -- H
				 std_logic_vector'("1001111") when X"49", -- I (1)
				 std_logic_vector'("0000011") when X"4A", -- J
				 std_logic_vector'("1001000") when X"4B", -- K (H)
				 std_logic_vector'("1110001") when X"4C", -- L
				 std_logic_vector'("0001001") when X"4D", -- M
				 std_logic_vector'("1101010") when X"4E", -- N (n)
				 std_logic_vector'("0000001") when X"4F", -- 0 (0)
				 std_logic_vector'("0011000") when X"50", -- P
				 std_logic_vector'("0001100") when X"51", -- Q (q)
				 std_logic_vector'("1111010") when X"52",	-- R (r)
				 std_logic_vector'("0100100") when X"53",	-- S (5)
				 std_logic_vector'("0001111") when X"54",	-- T
				 std_logic_vector'("1000001") when X"55",	-- U
				 std_logic_vector'("1000001") when X"56",	-- V (U)
				 std_logic_vector'("1000001") when X"57",	-- W (U)
				 std_logic_vector'("1001000") when X"58", -- X (H)
				 std_logic_vector'("1000100") when X"59",	-- Y (y)
				 std_logic_vector'("0010010") when X"5A", -- Z (2)
				 std_logic_vector'("1110111") when X"5F", -- _
				 std_logic_vector'("1111101") when X"60", -- `
				 std_logic_vector'("0001000") when X"61",	-- a (A)
				 std_logic_vector'("1100000") when X"62",	-- b
				 std_logic_vector'("1110010") when X"63",	-- c
				 std_logic_vector'("1000010") when X"64",	-- d
				 std_logic_vector'("0110000") when X"65",	-- e (E)
				 std_logic_vector'("0111000") when X"66",	-- f (F)
				 std_logic_vector'("0000100") when X"67", -- g
				 std_logic_vector'("1101000") when X"68", -- h
				 std_logic_vector'("1101111") when X"69", -- i
				 std_logic_vector'("1000011") when X"6A", -- j
				 std_logic_vector'("1001000") when X"6B", -- k (H)
				 std_logic_vector'("1110001") when X"6C", -- l (L)
				 std_logic_vector'("0001001") when X"6D", -- m (M)
				 std_logic_vector'("1101010") when X"6E", -- n
				 std_logic_vector'("1100010") when X"6F", -- o
				 std_logic_vector'("0011000") when X"70", -- p (P)
				 std_logic_vector'("0001100") when X"71", -- q
				 std_logic_vector'("1111010") when X"72",	-- r
				 std_logic_vector'("0100100") when X"73",	-- s (5)
				 std_logic_vector'("0001111") when X"74",	-- t (T)
				 std_logic_vector'("1100011") when X"75",	-- u
				 std_logic_vector'("1100011") when X"76",	-- V (u)
				 std_logic_vector'("1100011") when X"77",	-- W (u)
				 std_logic_vector'("1001000") when X"78", -- x (H)
				 std_logic_vector'("1000100") when X"79",	-- y
				 std_logic_vector'("0010010") when X"7A", -- z (2)
				 std_logic_vector'("1111001") when X"7C", -- |
				 std_logic_vector'("1110111") when others;

--	segment(0) <= '0' when ascii = X"2E" else '1';

end Behavioral;
