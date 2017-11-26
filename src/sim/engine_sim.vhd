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
-- For loop cant change during run-time apparently, responcible for extra long code
-------------------------------------------------------------------------------
-- Revisions  :
-- Date				 Version	Author	Description
-- 2017-10-13	 1.0			CT			Created
-- 2017-10-14  1.1      CT      Removed "hardware", replaced with 'wait for's
-- 2017-11-13  1.2      CT      Added more accurate teeth and gap and anomoly after gap
-- 2017-11-22  1.3      CT      Added ability to change startting tooth
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

entity engine_sim is
	generic(
    TEETH       : integer := 60-2;  --Number of teeth in revolution
	  NORM_DUTY    : real := 0.425;    --Normal high/(low+high)
    GAP_FACTOR   : real := 5.25;     --Gap width/tooth before gap
	  POST_DUTY    : real := 0.58;      --Tooth after gap/(gap + tooth after)
	  START_TOOTH  : integer := 1
	);
	port (
		rpm         : in integer;     --Desired speed of output pulse train
		clk_125M    : in	std_logic;  --125Mhz master clock
		rst	        : in	std_logic;  --synchronous global reset
		pulse_train : out	std_logic  --simulated pulse train output
  );
end engine_sim;

architecture Behavioral of engine_sim is
	constant T : time := 1 us;
	
  begin
  
  --Generates pulse train
  PULSE_GEN : process
    variable normal_period_us : integer;   --Entire delay of tooth & gap in micro seconds
    variable normal_high_us : integer;    --Delay of solid tooth in micro seconds
    variable normal_low_us : integer;     --Delay of gap in microseconds
    variable post_delay_us : integer;      --Delay of anomolous tooth after gap
    
    begin
    
    --Sequence for starting not at tooth 1
     
    -- 58 teeth and gaps
    for i in START_TOOTH to TEETH loop  --Must subtract one because anomolous tooth was added after gap
      --Variable assignments
      normal_period_us := integer(ceil(1000000.0 / real(rpm))); 
      normal_high_us := integer(ceil(NORM_DUTY * real(normal_period_us)));
      normal_low_us := (normal_period_us - normal_high_us);
      post_delay_us := integer(ceil((POST_DUTY * real(normal_low_us)) / (1.0 - POST_DUTY)));
      
      --Normal teeth operation
      pulse_train <= '1';
      wait for normal_high_us * T;
      pulse_train <= '0';
      wait for normal_low_us * T;
    end loop;
      
    -- missing tooth
    wait for integer(ceil(real(normal_high_us) * GAP_FACTOR - real(normal_low_us))) * T;
    
    --Anomoly after missing tooth
    pulse_train <= '1';
    wait for post_delay_us * T;
    pulse_train <= '0';
    wait for normal_low_us * T;

    --Continue normal sequence
    while true loop
    
      -- 58 teeth and gaps
      for i in 1 to TEETH - 1 loop  --Must subtract one because anomolous tooth was added after gap
        --Variable assignments
        normal_period_us := integer(ceil(1000000.0 / real(rpm))); 
        normal_high_us := integer(ceil(NORM_DUTY * real(normal_period_us)));
        normal_low_us := (normal_period_us - normal_high_us);
        post_delay_us := integer(ceil((POST_DUTY * real(normal_low_us)) / (1.0 - POST_DUTY)));
        
        --Normal teeth operation
        pulse_train <= '1';
        wait for normal_high_us * T;
        pulse_train <= '0';
        wait for normal_low_us * T;
      end loop;
      
      -- missing tooth
      wait for integer(ceil(real(normal_high_us) * GAP_FACTOR - real(normal_low_us))) * T;
      
      --Anomoly after missing tooth
      pulse_train <= '1';
      wait for post_delay_us * T;
      pulse_train <= '0';
      wait for normal_low_us * T;
  
   end loop;
  end process;
	
end Behavioral;

