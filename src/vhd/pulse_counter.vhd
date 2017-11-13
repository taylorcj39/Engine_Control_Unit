-------------------------------------------------------------------------------
-- Title      : Pulse Counter
-- Project    : ECU
-------------------------------------------------------------------------------
-- File       : pulse_counter.vhd   
-- Author     : Chris Taylor
-- Company    : 
-- Created    : 2017-10-14
-- Last update: 2017-10-14
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: Counts sampling clk pulses (488.28kHz) of time high or low from
--  pulse train of crank angle sensor or simulator
-------------------------------------------------------------------------------
-- Notes:
-- Add aditional generic for sclk frequency selection, add constant for 8bits of clk
-- Currenlty has 2*288kHz inside, need to reformat so only counts once per sclk period
-------------------------------------------------------------------------------
-- Revisions  :
-- Date				 Version	Author    Description
-- 2017-10-14  1.0      CT        Created
-- 2017-10-18  1.1      CT        Doubled width of y to hold length of gap 
-- 2017-11-12  1.1      CT        Changed output x, y from U to SLV 
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

entity pulse_counter is
	generic(WIDTH : integer := 8);
	port (
		clk_125M    : in	std_logic;                      --125Mhz master clock
		rst	        : in	std_logic;                      --global synchronous reset
		pulse_train : in	std_logic;                      --pulse train from sensor
		x           : out std_logic_vector(WIDTH - 1 downto 0);   --high pulse width in samples
		y           : out std_logic_vector((WIDTH * 2) - 1 downto 0);   --low pulse width in samples
		x_valid	    : out std_logic;                      --high pulse width ready to be read
		y_valid	    : out std_logic                       --low pulse width ready to be read
	);
end pulse_counter;

architecture Behavioral of pulse_counter is
  --State machine types and signal
  type STATE_TYPE is (start, count, tooth, gap, tooth_plus, gap_plus, tooth_valid, gap_valid, tooth_rst, gap_rst);
  signal state : STATE_TYPE := start;

  --Internal Signals
  signal x_count        : unsigned(WIDTH - 1 downto 0) := (others => '0');
  signal x_count_rst    : std_logic := '0';
  signal x_count_inc    : std_logic := '0';
  signal x_count_toggle : std_logic := '0';
  
  signal y_count        : unsigned((WIDTH * 2) - 1 downto 0)  := (others => '0');
  signal y_count_rst    : std_logic := '0';
  signal y_count_inc    : std_logic := '0';
  signal y_count_toggle : std_logic := '0';
  
  signal sclk           : std_logic := '0';         --488kHz sampling clk
  signal clk_q          : unsigned(9 - 1 downto 0) := (others => '0'); --Accumulator for clk_125M pulses
  
  --Register signals for pulse and sclk
  signal pulse_q      : std_logic := '0'; --registered pulse value
  signal sclk_q       : std_logic := '0'; --registered sclk value
  signal pulse_e      : std_logic := '0'; --enable for pulse register
  signal sclk_e       : std_logic := '0'; --enable for sclk register
    
  begin
  
  --Sampling clk generator
  SCLKGEN : process(clk_125M)
  begin
  if rising_edge(clk_125M) then
    if rst = '1' then
      clk_q <= (others => '0');
    else
      clk_q <= clk_q + 1;
    end if;    
  end if;   
  end process;
  sclk <= clk_q(9 - 1); --Slowed sclk down by half, currently counting on high and low
  
  --Coutners--------------------------------------------------------------------
  --Counter for 'high' pulses
  XCNT: process(clk_125M)
  begin
  if rising_edge(clk_125M) then             --Makes process synchronous
      if (rst = '1' or x_count_rst = '1') then                     --Always check clr
        x_count <= (others => '0');
      elsif (x_count_inc = '1' and x_count_toggle = '0') then
        x_count <= x_count + 1;
        x_count_toggle <= '1';
      elsif (x_count_inc = '0' and x_count_toggle = '1') then
        x_count_toggle <= '0';   
      end if;
    end if;      
  end process;
  x <= std_logic_vector(x_count); --Assign component output to internal count

  --Counter for 'low' pulses
  YCNT: process(clk_125M)
  begin
  if rising_edge(clk_125M) then             --Makes process synchronous
      if (rst = '1'or y_count_rst = '1') then                     --Always check clr
        y_count <= (others => '0');
        --toggle <= '0'; ??
      elsif (y_count_inc = '1' and y_count_toggle = '0') then
        y_count <= y_count + 1;
        y_count_toggle <= '1';
      elsif (y_count_inc = '0' and y_count_toggle = '1') then
        y_count_toggle <= '0';   
      end if;
    end if;      
  end process;
  y <= std_logic_vector(y_count); --Assign component output to internal count
	------------------------------------------------------------------------------
	
	--Registers-------------------------------------------------------------------
	--Pulse Register, I think this can be eliminated 10/16
	PREG : process(clk_125M)
	begin
	 if rising_edge(clk_125M) then
	   if rst = '1' then
	     pulse_q <= '0';
	   elsif (pulse_e = '1') then
	     pulse_q <= pulse_train;
	   end if;
	 end if;
	end process;
	
	--Sclk Register
  SCLKREG : process(clk_125M)
  begin
   if rising_edge(clk_125M) then
     if rst = '1' then
       sclk_q <= '0';
     elsif (sclk_e = '1') then
       sclk_q <= sclk;
     end if;
   end if;
  end process;
	------------------------------------------------------------------------------
	
	--FSM Transitional Process
	ST : process(clk_125M)
	begin
    if rising_edge(clk_125M) then
      if rst = '1' then
       state <= start;
      else
        case state is
          when start =>
            state <= count;
          when count =>
            if pulse_train = '1' then
              state <= tooth;
            else
              state <= gap;
          end if;
          --Tooth sequence
          when tooth =>
            if (sclk = sclk_q) then
            --if sclk = '0' then ??
              if pulse_train = '1' then
                state <= tooth;
              else
                state <= tooth_valid;
              end if;
            else
            --elsif (sclk /= sclk_q and sclk = '0') then ??
              state <= tooth_plus;
            end if;
          when tooth_plus =>
            if pulse_train = '1' then
              state <= tooth;
            else
              state <= tooth_valid;
            end if;
          when tooth_valid =>
            state <= tooth_rst;
          when tooth_rst =>
            state <= count;
          --Gap sequence  
          when gap =>
            if (sclk = sclk_q) then
              if pulse_train = '0' then
                state <= gap;
              else
                state <= gap_valid;
              end if;
            else
              state <= gap_plus;
            end if;
          when gap_plus =>
            if pulse_train = '0' then
              state <= gap;
            else
              state <= gap_valid;
            end if;
          when gap_valid =>
            state <= gap_rst;
          when gap_rst =>
            state <= count;
        end case;
      end if;
    end if;
	end process;

	--FSM Combinational Assignments
  SL : process(state)
    begin
    --Default outputs
    sclk_e <= '0'; 
    pulse_e <= '0'; 
    x_count_rst <= '0'; y_count_rst <= '0';
    x_count_inc <= '0'; y_count_inc <= '0';
    x_valid <= '0'; y_valid <= '0'; 
    case state is
      when start =>
        x_count_rst <= '1';
        y_count_rst <= '1';
        x_valid <= '0';
        y_valid <= '0';
      when count =>
        sclk_e <= '1';
        pulse_e <= '1';
      when tooth_plus =>
        sclk_e <= '1';
        x_count_inc <= '1';
      when tooth_valid =>
        x_valid <= '1';
      when tooth_rst =>
        x_count_rst <= '1';  
      when gap_plus =>
        sclk_e <= '1';
        y_count_inc <= '1';
      when gap_valid =>
        y_valid <= '1';
      when gap_rst =>
        y_count_rst <= '1';
      when others =>
        null;
    end case;
  end process;
	
end Behavioral;

