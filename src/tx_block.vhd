library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tx_block is
port(
	TX : out std_logic; --output
	DATA : in unsigned(7 downto 0); --input data
	STROBE : out std_logic; --strobe input (asserted for one clock when new data has been loaded)
	NEW_DATA : in std_logic; --to be set high to signal that new data is available to be sent
	
	RST_N : in std_logic; --asynchronous reset
	CLK : in std_logic --clock
);
end entity tx_block;

architecture rtl of tx_block is
-- REGISTERS AND COUNTERS
signal DATA_REG : unsigned(9 downto 0); --data shift register
signal SMP_CNT : unsigned(2 downto 0); --sample counter
signal DATA_CNT : unsigned(3 downto 0); --data counter

-- STATUS SIGNALS
signal S_VAL : std_logic; -- sample counter terminal count (asserted one clock before the last value)
signal D_VAL : std_logic; -- data counter terminal count
-- CONTROL SIGNALS
signal SHIFT_OUT : std_logic; --data shift register shift command
signal LOAD_TX : std_logic; --data shift register load command
signal S_RSTN : std_logic; -- sample counter synch reset (active low)
signal D_RSTN : std_logic; -- data counter synch reset (active low)
signal D_EN : std_logic; --data counter enable
-- STATE MACHINE SIGNALS
type stateType is(IDLE,LOAD_DATA,BUSY,SHIFT_DATA); --possible machine states
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
D_VAL<=	'1' when DATA_CNT = to_unsigned(9,DATA_CNT'length) else '0'; --combinatory part (terminal counter)

------------------------------------------------------

-- REGISTERS INFERENCE -------------------------------
DR: process(CLK,RST_N) --data register
begin
if RST_N='0' then
	DATA_REG<=(others=>'1');
elsif CLK='1' and CLK'event then
	if LOAD_TX='1' then
		DATA_REG(0)<='0';
		DATA_REG(9)<='1';
		DATA_REG(8 downto 1)<=DATA(7 downto 0);
	elsif SHIFT_OUT='1' then
		DATA_REG(8 downto 0)<=DATA_REG(9 downto 1);
		DATA_REG(9)<='1';
	end if;
end if;
end process;

------------------------------------------------------


-- OTHER ASSIGNMENTS ---------------------------------
TX<=DATA_REG(0);
------------------------------------------------------

-- CONTROL UNIT STATE MACHINE ------------------------
NS: process(STATE,NEW_DATA,D_VAL,S_VAL) --next state computation process
begin
	case STATE is
		when IDLE =>
			if NEW_DATA='1' then
				STATE_NEXT<=LOAD_DATA;
			end if;
		when LOAD_DATA =>
			STATE_NEXT<=BUSY;
		when BUSY =>
			if S_VAL='1' then
				if D_VAL='0' then
					STATE_NEXT<=SHIFT_DATA;
				elsif NEW_DATA='1' then
					STATE_NEXT<=LOAD_DATA;
				else
					STATE_NEXT<=IDLE;
				end if;
			end if;
		when SHIFT_DATA =>
			STATE_NEXT<=BUSY;
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
			LOAD_TX<='0';
			SHIFT_OUT<='0';
			STROBE<='0';
		when LOAD_DATA =>
			S_RSTN<='1';
			D_RSTN<='0';
			D_EN<='0';
			LOAD_TX<='1';
			SHIFT_OUT<='0';
			STROBE<='1';
		when BUSY =>
			S_RSTN<='1';
			D_RSTN<='1';
			D_EN<='0';
			LOAD_TX<='0';
			SHIFT_OUT<='0';
			STROBE<='0';
		when SHIFT_DATA =>
			S_RSTN<='1';
			D_RSTN<='1';
			D_EN<='1';
			LOAD_TX<='0';
			SHIFT_OUT<='1';
			STROBE<='0';
		when others =>
			S_RSTN<='0';
			D_RSTN<='0';
			D_EN<='0';
			LOAD_TX<='0';
			SHIFT_OUT<='0';
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
