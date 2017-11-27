LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

use std.textio.all;
use ieee.std_logic_textio.all;

entity teknik_ctrl_tb is
end teknik_ctrl_tb;

architecture Behavioral of teknik_ctrl_tb is
	component pwm_fsm
    Port ( clock : in STD_LOGIC;
           reset : in STD_LOGIC;
           enab: in std_logic;
           duty : in STD_LOGIC_VECTOR (7 downto 0);
           pulse : in STD_LOGIC_VECTOR (15 downto 0);
           pwm_ch : in std_logic_vector(2 downto 0);
           angle_start: in std_logic_vector(15 downto 0);
           angle_stop: in std_logic_vector(15 downto 0);
           current_angle: in std_logic_vector(15 downto 0);
           pwm_out_ch1 : out STD_LOGIC;
           pwm_out_ch2 : out STD_LOGIC;
           pwm_out_ch3 : out STD_LOGIC;
           pwm_out_ch4 : out STD_LOGIC);
end component;

	-- Input Signals
	signal clock : 	STD_LOGIC := '0';
	signal reset : 		STD_LOGIC := '1';
	signal enab : 		STD_LOGIC := '0';
	
	signal pwm_ch : std_logic_vector(2 downto 0) := "000";
	signal duty :	STD_LOGIC_VECTOR(7 downto 0) := X"00";
	signal pulse :	STD_LOGIC_VECTOR(15 downto 0) := X"0000";
    signal angle_start :	STD_LOGIC_VECTOR(15 downto 0) := X"0000";
    signal angle_stop :	STD_LOGIC_VECTOR(15 downto 0) := X"0000";
    signal current_angle :	STD_LOGIC_VECTOR(15 downto 0) := X"0000";
	-- Output Signals
	signal pwm_out_ch1 :	STD_LOGIC := '0';
	signal pwm_out_ch2 :	STD_LOGIC := '0';
	signal pwm_out_ch3 :	STD_LOGIC := '0';
	signal pwm_out_ch4 :	STD_LOGIC := '0';

	constant CLK_125M_PERIOD : time := 8ns;

	begin

	clock <= not clock after CLK_125M_PERIOD * 0.5;

	uut : pwm_fsm
	port map(
		clock => clock,
		reset => reset,
		duty => duty,
		pulse => pulse,
		enab => enab,
		pwm_ch => pwm_ch,
		angle_start=>angle_start,
		angle_stop=>angle_stop,
		current_angle => current_angle,
		pwm_out_ch1 => pwm_out_ch1,
		pwm_out_ch2 => pwm_out_ch2,
		pwm_out_ch3 => pwm_out_ch3,
		pwm_out_ch4 => pwm_out_ch4
	);

	STIM : process
	begin
		wait for CLK_125M_PERIOD * 3;

		reset <= '0';
		wait for 10us;

	
		
		
		
        duty <= X"32"; -- 50% Duty Cycle
        pulse<= x"00FA"; -- 250 counts
        pwm_ch<="001";
        angle_start <= x"0000";
        angle_stop <= x"8000";
        wait for 10 us;

        
                
                
    --    duty <= X"32"; -- 50% Duty Cycle
    --    pulse<= x"00FA"; -- 250 counts
        pwm_ch<="010";
      
    --    wait for 10us;

        duty <= X"4B"; -- 75% Duty Cycle
        pulse <= x"00FA"; -- 250 counts
        angle_start <= x"0000";
        angle_stop <= x"4000";
        wait for 10us;

   --     duty <= X"32"; -- 50% Duty Cycle
   --     pulse <= x"04E2"; -- 1250 counts
   --     wait for 10us;

    --    duty <= X"4B"; -- 75% Duty Cycle
   --     pulse <= x"04E2"; -- 1250 counts
        wait for 10 us;


                
   --     duty <= X"32"; -- 50% Duty Cycle
   --     pulse<= x"00FA"; -- 250 counts
        pwm_ch<="011";
        duty <= X"4B"; -- 75% Duty Cycle
        pulse <= x"04E2"; -- 1250 counts
        angle_start <= x"0000";
        angle_stop <= x"FFFF";
        wait for 10 us;


     
      
                
    --    duty <= X"32"; -- 50% Duty Cycle
   --     pulse<= x"00FA"; -- 250 counts
        pwm_ch<="100";
      
        wait for 10 us;

        angle_start <= x"0000";
        angle_stop <= x"3423";
        
        duty <= X"32"; -- 50% Duty Cycle
        pulse <= x"04E2"; -- 1250 counts
        wait for 10us;

        pwm_ch<="000";
 	    --wait for 10 us;
		wait;
		
	end process;
	val : process
        begin
        wait for CLK_125M_PERIOD * 3;
	lo: for j in 0 to 2**16 - 1 loop
                             current_angle<= current_angle + "0000000000000001";                      
                             wait for CLK_125M_PERIOD;    
                        end loop;
         wait;
         end process;
    
end Behavioral;