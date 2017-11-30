-------------------------------------------------------------------------------
-- Title      : PWM Controller
-- Project    : ECU
-------------------------------------------------------------------------------
-- File       : pwm_ctrl.vhd   
-- Author     : Constantin Lacraru
-- Company    : 
-- Created    : 2017-11-20
-- Last update: 2017-11-28
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: PWM controller which takes mclk 
-------------------------------------------------------------------------------
-- Notes:
--
-------------------------------------------------------------------------------
-- Revisions  :
-- Date			    Version	  Author    Description
-- 2017-11-20   1.0       CL        Created
-- 2017-11-26   1.1       RM        Added enable and sclr
-- 2017-11-28   1.2       CT        Updated name and formatting
-------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

entity pwm_ctrl is
	port (
		clk_125M 		:	in STD_LOGIC;
		rst 				:	in STD_LOGIC;
		duty_cycle	:	in unsigned(7 downto 0);  --unsigned duty cycle 0-100
		pulse_cnt 	: in unsigned (15 downto 0);	--# of mclk ticks in 1 period
		enable			: in std_logic;
		sclr				: in std_logic;				
		pulse_out 	:	out STD_LOGIC	--Output PWM signal
	);
end pwm_ctrl;

architecture rtl of pwm_ctrl is 
	-- State machine used to switch from high to low based on tick counts
	type STATE_TYPE is (start, p_low, p_high, to_high, to_low);
	signal state :		STATE_TYPE := start;

  --constants

	-- Signals
	signal dutyhigh :	unsigned(15 downto 0) := X"0000";
	signal dutylow :	unsigned(15 downto 0) := X"0000";
	signal calchigh :	unsigned(23 downto 0) := X"000000";
	signal interhigh :  unsigned(23 downto 0) := X"000000";
	signal count :	    unsigned(15 downto 0) := X"0001";
	signal temporal :	STD_LOGIC := '0';
	signal t_flag : STD_LOGIC := '0';

begin
	-- Generates a tick count based on the Duty cycle
	COUNT_GEN : process(clk_125M) begin
		if rising_edge(clk_125M) then
			if rst = '1' then
				dutyhigh <= X"0000";
				dutylow <= X"0000";
			else
			   if sclr = '1' then
			       dutyhigh <= X"0000";
			       dutylow<= X"0000";
			   end if;
			   
				calchigh <= pulse_cnt * duty_cycle;
				interhigh <= SHIFT_RIGHT(calchigh,7) + SHIFT_RIGHT(calchigh, 9) + SHIFT_RIGHT(calchigh, 12);	--?
				dutyhigh <= interhigh(15 downto 0);
				--dutylow <= pulse_cnt - dutyhigh;
				dutylow <= pulse_cnt - interhigh(15 downto 0);
			end if;
		end if;
	end process;
	
	-- Counter itself
	COUNTER : process(clk_125M) begin
	   if rising_edge(clk_125M) then
	       if t_flag = '1' and pulse_cnt /= X"0000" then
	           count <= count + X"0001";
	       else
	           count <= X"0001";
	       end if;
	   end if;
	end process;
	
	-- FSM forCreating the actual pulse based on the counts of high and low
	PULSE_FSM : process(clk_125M) begin
		if rising_edge(clk_125M) then
			if rst = '1' then
				state <= start;
			else
				if sclr = '1' then
						state<= start;
				end if;
				case state is
					when start =>
					    if(enable = '1') then
						  state <= p_low;
						else
						  state<= start;
						end if;
					when p_low =>
						if count = (dutylow - 1) then
							state <= to_high;
						end if;
				    when to_high =>
				        state <= p_high;
					when p_high =>
						if count = (dutyhigh - 1) then
							state <= to_low;
						end if;
					when to_low =>
					   state <= p_low;
				end case;
			end if;
		end if;
	end process;

    -- State machine parameters
	PULSE_GEN : process(state) begin
		-- Default outputs
		t_flag <= '0';
		case state is
			when start =>
				t_flag <= '0';
			when p_low =>
				t_flag <= '1';
			when to_high =>
			  t_flag <= '0';
			when p_high =>
				t_flag <= '1';
			when to_low =>
        t_flag <= '0';
			when others =>
				null;
		end case;
	end process;

pulse_out <= '1' when state = p_high or state = to_low else '0';

end rtl;