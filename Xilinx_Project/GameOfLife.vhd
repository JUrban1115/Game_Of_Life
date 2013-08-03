library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity GameOfLife is
	generic (
	noAddr : STD_LOGIC_VECTOR(31 downto 0) := "00000000000000000000000000000000";
	addFill : STD_LOGIC_VECTOR(29 downto 0) := "000000000000000000000000000000");
				-- placeholders for unconnected masters and data bits
    Port ( sys_clk : in  STD_LOGIC;
           sys_rst : in  STD_LOGIC;
           digit : out  STD_LOGIC_VECTOR (3 downto 0);
           segment : out  STD_LOGIC_VECTOR (7 downto 0);
			  leds_o : out STD_LOGIC_VECTOR (7 downto 0);
			  btn2 : in STD_LOGIC;
			  btn0 : in STD_LOGIC;
			  swts_i : in STD_LOGIC_VECTOR(7 downto 0);
			  sram_io1, sram_io2 : inout STD_LOGIC_VECTOR(15 downto 0);
					-- data bus 1 (lower 16) and 2 (upper 16)
			  sram_addr : out STD_LOGIC_VECTOR(17 downto 0); -- shared addr
					-- controls are active low:
			  sram_we, sram_oe : out STD_LOGIC; -- shared write and read enables
			  sram_ce1, sram_ce2 : out STD_LOGIC; -- bank enables
			  sram_ub1, sram_ub2 : out STD_LOGIC; -- upper byte enables
			  sram_lb1, sram_lb2 : out STD_LOGIC; -- lower byte enables
			  ps2_data : in STD_LOGIC;
			  ps2_clk : in STD_LOGIC;
			  vga_red, vga_green, vga_blue : out STD_LOGIC;
			  vga_hsync : out STD_LOGIC;
			  vga_vsync : out STD_LOGIC);
end GameOfLife;  

architecture Behavioral of GameOfLife is

component wb_intercon is
generic (num_addr_bits : positive := 32; num_data_bits : positive := 32);
port (
ACK_I_M: out std_logic_vector(3 downto 0);
ACK_O_S: in std_logic_vector(3 downto 0);
ADR_O_M0: in std_logic_vector( num_addr_bits-1 downto 0 );
ADR_O_M1: in std_logic_vector( num_addr_bits-1 downto 0 );
ADR_O_M2: in std_logic_vector( num_addr_bits-1 downto 0 );
ADR_O_M3: in std_logic_vector( num_addr_bits-1 downto 0 );
ADR_I_S: out std_logic_vector( num_addr_bits-1 downto 0 );
CYC_O_M: in std_logic_vector(3 downto 0);
DAT_O_M0: in std_logic_vector( num_data_bits-1 downto 0 );
DAT_O_M1: in std_logic_vector( num_data_bits-1 downto 0 );
DAT_O_M2: in std_logic_vector( num_data_bits-1 downto 0 );
DAT_O_M3: in std_logic_vector( num_data_bits-1 downto 0 );
DWR: out std_logic_vector( num_data_bits-1 downto 0 );
DAT_O_S0: in std_logic_vector( num_data_bits-1 downto 0 );
DAT_O_S1: in std_logic_vector( num_data_bits-1 downto 0 );
DAT_O_S2: in std_logic_vector( num_data_bits-1 downto 0 );
DAT_O_S3: in std_logic_vector( num_data_bits-1 downto 0 );
DRD: out std_logic_vector( num_data_bits-1 downto 0 );
IRQ_O_S:		in std_logic_vector(3 downto 0) := "0000";
IRQ_I_M:		out std_logic;
IRQV_I_M:	out std_logic_vector(1 downto 0);
STB_I_S: out std_logic_vector(3 downto 0);
STB_O_M: in std_logic_vector(3 downto 0);
WE_O_M: in std_logic_vector(3 downto 0);
WE: out std_logic;
CLK: in std_logic;
RST: in std_logic
);
end component wb_intercon;

component wb_game is
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
we_o : out std_logic;
swts_i : in STD_LOGIC_VECTOR(7 downto 0);
btn2 : in STD_LOGIC;
btn0 : in STD_LOGIC);
end component wb_game;

component wb_sram is
Port ( clk_i : in std_logic;
rst_i : in std_logic;
adr_i : in std_logic_vector(31 downto 0);
dat_i : in std_logic_vector(31 downto 0);
dat_o : out std_logic_vector(31 downto 0);
ack_o : out std_logic;
stb_i : in std_logic;
we_i : in std_logic;
sram_io1, sram_io2 : inout STD_LOGIC_VECTOR(15 downto 0);
		-- data bus 1 (lower 16) and 2 (upper 16)
sram_addr : out STD_LOGIC_VECTOR(17 downto 0); -- shared addr
-- controls are active low:
sram_we, sram_oe : out STD_LOGIC; -- shared write and read enables
sram_ce1, sram_ce2 : out STD_LOGIC; -- bank enables
sram_ub1, sram_ub2 : out STD_LOGIC; -- upper byte enables
sram_lb1, sram_lb2 : out STD_LOGIC); -- lower byte enables
end component wb_sram;

component sramctl is
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
end component sramctl;

component vga640x480 is
	Port ( clk_i : in std_logic;
          rst_i : in std_logic;
		    adr_o : out std_logic_vector(31 downto 0);
          dat_i : in std_logic_vector(31 downto 0);
          dat_o : out std_logic_vector(31 downto 0);
          ack_i : in std_logic;
          cyc_o : out std_logic;
          stb_o : out std_logic;
          we_o  : out std_logic;
    		 red : out std_logic;
          green : out std_logic;
          blue : out std_logic;
          hsync : out std_logic;
          vsync : out std_logic
			);
end component vga640x480;

signal weA, irqM : STD_LOGIC;
signal irqV : STD_LOGIC_VECTOR (1 downto 0);
signal ackM, ackS, cycT, stbM, stbS, weM, irqS :
			STD_LOGIC_VECTOR (3 downto 0) := "0000";
	-- ackM, ackS : acknowledge to master and slaves
	-- cycM : masters cyc
	-- stbM, stbS : start data masters and slaves
	-- weM : write enable from masters, to slaves
signal gameAdd, vgaAdd, slvAdd, gameData, vgaData,
			dInBus, sramData, dOutBus,
			dRdBus : STD_LOGIC_VECTOR (31 downto 0) := (others => '0'); 
	-- Add's : address from masters, to slaves
	-- Data's : data from units
	-- InBus's : data from intercon to units
	-- dWrBus : data from intercon to slaves
	-- dRdBus : data from slaves to intercon
begin

segment <= (others => '1');
leds_o <= (others => '0');
digit <= (others => '0');

wbint : wb_intercon port map (
	ACK_I_M => ackM,
	ACK_O_S => ackS,
	ADR_O_M0 => vgaAdd,
	ADR_O_M1 => gameAdd,
	ADR_O_M2 => noAddr,
	ADR_O_M3 => noAddr,
	ADR_I_S => slvAdd,
	CYC_O_M => cycT,
	DAT_O_M0 => vgaData,
	DAT_O_M1 => gameData,
	DAT_O_M2 => noAddr,
	DAT_O_M3 => noAddr,
	DWR => dOutBus,
	DAT_O_S0 => sramData,
	DAT_O_S1 => noAddr ,
	DAT_O_S2 => noAddr,
	DAT_O_S3 => noAddr,
	DRD => dInBus,
	IRQ_O_S => irqS,
	IRQ_I_M => irqM,
	IRQV_I_M => irqV,
	STB_I_S => stbS,
	STB_O_M => stbM,
	WE_O_M => weM,
	WE => weA,
	CLK => sys_clk,
	RST => sys_rst);
wbgm : wb_game port map (clk_i => sys_clk, rst_i => sys_rst, -- master 1
	adr_o => gameAdd, dat_i => dInBus, dat_o => gameData, irq_i => irqM,
	irqv_i => irqV, ack_i => ackM(1), cyc_o => cycT(1), stb_o => stbM(1), 
	we_o => weM(1), swts_i => swts_i, btn2 => btn2, btn0 => btn0);
wsrm : sramctl port map (clk_i => sys_clk, rst_i => sys_rst,  -- slave 0
	adr_i => slvAdd, dat_i => dOutBus, dat_o => sramData, ack_o => ackS(0), 
	stb_i => stbS(0),we_i => weA, sram_io1 => sram_io1, 
	sram_io2 => sram_io2, sram_addr => sram_addr, 
	sram_we => sram_we, sram_oe => sram_oe, 
	sram_ce1 => sram_ce1, sram_ce2 => sram_ce2, 
	sram_ub1 => sram_ub1, sram_ub2 => sram_ub2, 
	sram_lb1 => sram_lb1, sram_lb2 => sram_lb2);
wbvga : vga640x480 port map (clk_i => sys_clk, rst_i => sys_rst, -- master 0
	adr_o => vgaAdd, dat_i => dInBus, dat_o => vgaData,
	ack_i => ackM(0), cyc_o => cycT(0), stb_o => stbM(0), 
	we_o => weM(0), red => vga_red, green => vga_green, blue => vga_blue, 
	hsync => vga_hsync, vsync => vga_vsync );
end Behavioral;
 
 