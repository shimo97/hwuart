library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rx_block is
port(
	RX : in std_logic; --input
	DATA : out unsigned(7 downto 0); --output data
	STROBE : out std_logic; --strobe output (asserted one clock before the data is valid)
	
	RST_N : in std_logic; --asynchronous reset
	CLK : in std_logic --clock
);
end entity rx_block;

architecture rtl of rx_block is
-- REGISTERS AND COUNTERS
signal SMP_REG : unsigned(7 downto 0); --sampling shift register
signal DATA_REG : unsigned(7 downto 0); --data shift register
signal SMP_CNT : unsigned(2 downto 0); --sample counter
signal DATA_CNT : unsigned(2 downto 0); --data counter

-- STATUS SIGNALS
signal START : unsigned(2 downto 0); --signal corresponding to the LSBs of sampling shift register
signal BIT_VAL : std_logic; --majority voter output
signal S_VAL : std_logic; -- sample counter terminal count (asserted one clock before the last value)
signal D_VAL : std_logic; -- data counter terminal count
-- CONTROL SIGNALS
signal SHIFT_IN : std_logic; --data shift register shift command
signal S_RSTN : std_logic; -- sample counter synch reset (active low)
signal D_RSTN : std_logic; -- data counter synch reset (active low)
signal D_EN : std_logic; --data counter enable
-- STATE MACHINE SIGNALS
type stateType is(IDLE,WAIT_DATA,RX_DATA,WAIT_STOP,OUT_DATA); --possible machine states
signal STATE : stateType; --state machine current state
signal STATE_NEXT : stateType; --state machine next state

 
begin

-- COUNTERS INFERENCE --------------------------------
SC: process(CLK,RST_N) --sample counter
begin
if RST_N='0' then
	SMP_CNT<=(others=>'0');
elsif CLK='1' and CLK'event then
	if S_RSTN='0' then
		SMP_CNT<=(others=>'0');
	else
		SMP_CNT<=SMP_CNT+1;
	end if;
end if;
end process;
S_VAL<=	'1' when SMP_CNT = to_unsigned(6,SMP_CNT'length) else '0'; --combinatory part (terminal counter)

DC: process(CLK,RST_N) --data counter
begin
if RST_N='0' then
	DATA_CNT<=(others=>'0');
elsif CLK='1' and CLK'event then
	if D_RSTN='0' then
		DATA_CNT<=(others=>'0');
	elsif D_EN='1' then
		DATA_CNT<=DATA_CNT+1;
	end if;
end if;
end process;
D_VAL<=	'1' when DATA_CNT = to_unsigned(7,DATA_CNT'length) else '0'; --combinatory part (terminal counter)

------------------------------------------------------

-- REGISTERS INFERENCE -------------------------------
SR: process(CLK,RST_N) --sample register
begin
if RST_N='0' then
	SMP_REG<=(others=>'0');
elsif CLK='1' and CLK'event then
	SMP_REG(6 downto 0)<=SMP_REG(7 downto 1);
	SMP_REG(7)<=RX;
end if;
end process;

DR: process(CLK,RST_N) --data register
begin
if RST_N='0' then
	DATA_REG<=(others=>'0');
elsif CLK='1' and CLK'event then
	if SHIFT_IN='1' then
		DATA_REG(6 downto 0)<=DATA_REG(7 downto 1);
		DATA_REG(7)<=BIT_VAL;
	end if;
end if;
end process;

------------------------------------------------------

-- MAJORITY VOTER ------------------------------------
MV: process(SMP_REG)
variable numOne : integer; --to count the number of ones
begin
	numOne:=to_integer(SMP_REG(7 downto 7));
	numOne:=numOne+to_integer(SMP_REG(6 downto 6));
	numOne:=numOne+to_integer(SMP_REG(5 downto 5));
	
	if numOne>=2 then
		BIT_VAL<='1';
	else
		BIT_VAL<='0';
	end if;
end process;

------------------------------------------------------

-- OTHER ASSIGNMENTS ---------------------------------
START<=SMP_REG(2 downto 0); --assigning LSBs to START signal
DATA<=DATA_REG; -- assigning data register content to output signal
------------------------------------------------------

-- CONTROL UNIT STATE MACHINE ------------------------
NS: process(STATE,START,BIT_VAL,S_VAL,D_VAL) --next state computation process
begin
	case STATE is
		when IDLE =>
			if START="011" and BIT_VAL='0' then
				STATE_NEXT<=WAIT_DATA;
			end if;
		when WAIT_DATA =>
			if S_VAL='1' then
				STATE_NEXT<=RX_DATA;
			end if;
		when RX_DATA =>
			if D_VAL='1' then
				STATE_NEXT<=WAIT_STOP;
			else
				STATE_NEXT<=WAIT_DATA;
			end if;
		when WAIT_STOP =>
			if S_VAL='1' then
				STATE_NEXT<=OUT_DATA;
			end if;
		when OUT_DATA =>
			STATE_NEXT<=IDLE;
		when others =>
			STATE_NEXT<=IDLE;
	end case;
end process;

OP: process(STATE) --output computation process
begin
	case STATE is
		when IDLE =>
			S_RSTN<='0';
			D_RSTN<='0';
			D_EN<='0';
			SHIFT_IN<='0';
			STROBE<='0';
		when WAIT_DATA =>
			S_RSTN<='1';
			D_RSTN<='1';
			D_EN<='0';
			SHIFT_IN<='0';
			STROBE<='0';
		when RX_DATA =>
			S_RSTN<='1';
			D_RSTN<='1';
			D_EN<='1';
			SHIFT_IN<='1';
			STROBE<='0';
		when WAIT_STOP =>
			S_RSTN<='1';
			D_RSTN<='1';
			D_EN<='0';
			SHIFT_IN<='0';
			STROBE<='0';
		when OUT_DATA =>
			S_RSTN<='0';
			D_RSTN<='1';
			D_EN<='0';
			SHIFT_IN<='0';
			STROBE<='1';
		when others =>
			S_RSTN<='0';
			D_RSTN<='0';
			D_EN<='0';
			SHIFT_IN<='0';
			STROBE<='0';
	end case;
end process;

SM: process(CLK,RST_N) --state machine process
begin
	if RST_N='0' then --state reset
		STATE<=IDLE;
	elsif CLK='1' and CLK'event then --state update
		STATE<=STATE_NEXT;
	end if;
end process;

------------------------------------------------------
end architecture rtl;
