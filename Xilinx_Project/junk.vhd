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
			dat_o(29) <= dataReg(29) and dataReg(28) and dataReg(30);	
						-- retain white pixels
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
				addr <= addr + (80 - lastCol);	-- increments to next address
				dCol <= 0;
				dRow <= dRow + 1;
			else
				addr <= addr + 1;
				dCol <= dCol + 1;
			end if;
			readaddr <= readaddr + 1;
			if dCol = lastCol and dRow = lastRow then	-- last row, column
				dRow <= 0;
				state <= waitGen;
			else
				state <= initRead;
			end if;
