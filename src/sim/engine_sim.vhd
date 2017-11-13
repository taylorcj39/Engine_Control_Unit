-------------------------------------------------------------------------------
-- Title      :  Engine Simulator
-- Project    :  ECU
-------------------------------------------------------------------------------
-- File       : engine_sim.vhd   
-- Author     : Chris Taylor
-- Company    : 
-- Created    : 2017-10-13
-- Last update: 2017-10-13
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: Simulation only component for mimicking crank angle sensor pulsetrain output
-------------------------------------------------------------------------------
-- Notes:
-- Working 10/16, needs global reset when 'rpm' changes to interrupt 'wait for's
-------------------------------------------------------------------------------
-- Revisions  :
-- Date				Version	Author	Description
-- 2017-10-13	1.0			CT			Created
-- 2017-10-14 1.1     CT      Removed "hardware", replaced with 'wait for's
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

entity engine_sim is
	generic(TEETH : integer := 60-2; GAP_FACTOR : integer := 4; DUTY : real := 0.5);
	port (
		rpm         : in integer;     --Desired speed of output pulse train
		clk_125M    : in	std_logic;  --125Mhz master clock
		enable      : in	std_logic;  --sampling clock
		rst	        : in	std_logic;  --clr
		pulse_train : out	std_logic  --simulated pulse train output
  );
end engine_sim;

architecture Behavioral of engine_sim is
	constant T : time := 1 us;
	
  begin
  
  --Generates pulse train
  PULSE_GEN: process
    variable tooth_period_us : integer;   --Entire delay of tooth & gap in micro seconds
    variable delay_high_us : integer;     --Delay of solid tooth in micro seconds
    variable delay_low_us : integer;      --Delay of gap in microseconds
    
    begin
   
    -- 58 teeth and gaps
    for i in 1 to TEETH loop
      --Variable assignments
      tooth_period_us := integer(ceil(1000000.0 / real(rpm))); 
      delay_high_us := integer(ceil(DUTY * real(tooth_period_us)));
      delay_low_us := (tooth_period_us - delay_high_us);
      
      pulse_train <= '1';
      wait for delay_high_us * T;
      pulse_train <= '0';
      wait for delay_low_us * T;
    end loop;
    -- missing tooth
    wait for delay_high_us * T * GAP_FACTOR;
		--wait;
  end process;
	
end Behavioral;

