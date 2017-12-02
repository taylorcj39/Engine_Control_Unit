-------------------------------------------------------------------------------
-- Title      : Wrapper Contiaining interface for 4 I/O perephirals
-- Project    : ECU
-------------------------------------------------------------------------------
-- File       : peripheral_interface.vhd   
-- Author     : Robert McInerney
-- Company    : 
-- Created    : 2017-11-26
-- Last update: 2017-12-02
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: Sets up up to 4 I/Os for perephirals
-------------------------------------------------------------------------------
-- Notes:
--  (12-02-17) Updated some types from SLV to unsigned
--              Maybe use invert?
-------------------------------------------------------------------------------
-- Revisions  :
-- Date			    Version	  Author    Description
-- 2017-11-26   1.0       RM        Created
-- 2017-11-28   1.1       CT        Formatted, changed name from (pwm_fsm.vhd to perephiral_interface.vhd)
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

entity peripheral_interface is
    Port ( 
			clk_125M 			: in STD_LOGIC;
      rst 					: in STD_LOGIC;
      --enab: in std_logic;
      duty 					: in unsigned(8 - 1 downto 0);
      --invert        : in std_logic;
      pulse 				: in unsigned(16 - 1 downto 0);
      pwm_ch 				: in unsigned(3 - 1 downto 0);
      angle_start		: in unsigned(16 - 1 downto 0);
      angle_stop		: in unsigned(16 - 1 downto 0);
      current_angle	: in unsigned(16 - 1 downto 0);
      pwm_out_ch0 	: out STD_LOGIC;
			pwm_out_ch1 	: out STD_LOGIC;
      pwm_out_ch2 	: out STD_LOGIC;
      pwm_out_ch3 	: out STD_LOGIC
		);
end peripheral_interface;

architecture rtl of peripheral_interface is

component pwm_ctrl
	port (
		clk_125M 		:	in STD_LOGIC;
		rst 				:	in STD_LOGIC;
		duty_cycle	:	in unsigned(7 downto 0);  --unsigned duty cycle 0-100
		pulse_cnt 	: in unsigned (15 downto 0);	--# of mclk ticks in 1 period
		enable			: in std_logic;
		sclr				: in std_logic;				
		pulse_out 	:	out STD_LOGIC	--Output PWM signal
	);
end component;


type state is(S1);
signal y: state;

signal pwm_ch1_en: std_logic;
signal pwm_ch2_en: std_logic;
signal pwm_ch3_en: std_logic;
signal pwm_ch0_en: std_logic;

signal sclr1 : std_logic;
signal sclr2 : std_logic;
signal sclr3 : std_logic;
signal sclr0 : std_logic;

signal duty_ch1   : unsigned(7 downto 0);
signal duty_ch2   : unsigned(7 downto 0);
signal duty_ch3   : unsigned(7 downto 0);
signal duty_ch0   : unsigned(7 downto 0);
signal pulse_ch1  : unsigned(15 downto 0);
signal pulse_ch2  : unsigned(15 downto 0);
signal pulse_ch3  : unsigned(15 downto 0);
signal pulse_ch0  : unsigned(15 downto 0);

signal angle_start_1: unsigned(16 - 1 downto 0);
signal angle_stop_1: unsigned(16 - 1 downto 0);
signal angle_start_2: unsigned(16 - 1 downto 0);
signal angle_stop_2: unsigned(16 - 1 downto 0);
signal angle_start_3: unsigned(16 - 1 downto 0);
signal angle_stop_3: unsigned(16 - 1 downto 0);
signal angle_start_0: unsigned(16 - 1 downto 0);
signal angle_stop_0: unsigned(16 - 1 downto 0);

begin


PWM_Channel : process(clk_125M, rst) begin
		
    
     if rising_edge(clk_125M) then 
        if rst = '1' then
            y <= s1;
        else 
        case y is 
        
        when S1 =>
                if(pwm_ch = "001") then
                     duty_ch1 <= duty;
                     pulse_ch1 <= pulse;
                     angle_start_1 <= angle_start;
                     angle_stop_1 <= angle_stop;
                end if;
                
                if(pwm_ch = "010") then
                    duty_ch2 <= duty;
                    pulse_ch2 <= pulse;
                    angle_start_2 <= angle_start;
                    angle_stop_2 <= angle_stop;
                 end if;
                 if(pwm_ch = "011") then
                    duty_ch3 <= duty;
                    pulse_ch3 <= pulse;
                    angle_start_3 <= angle_start;
                    angle_stop_3 <= angle_stop;
                 end if;
                 if(pwm_ch = "100") then
                      duty_ch0 <= duty;
                      pulse_ch0 <= pulse;
                      angle_start_0 <= angle_start;
                      angle_stop_0 <= angle_stop;
                 end if;    
     end case;
     end if;
     end if;
     end process;     
     
     
     Outputs: process(clk_125M, y, pwm_ch, angle_start_1, angle_start_2, angle_start_3,angle_start_0, angle_stop_1, angle_stop_2,angle_stop_3,angle_stop_0,current_angle)
     begin
     
         pwm_ch1_en <= '0'; pwm_ch2_en <= '0'; pwm_ch3_en <= '0'; pwm_ch0_en <= '0';
         sclr1 <= '0'; sclr2 <= '0'; sclr3 <= '0'; sclr0 <= '0'; 
         
         case y is
             when S1 =>
           --      if(pwm_ch = "001") then
             --            pwm_ch1_en <= '1';
            --     end if;  
            --     if(pwm_ch = "010") then
            --             pwm_ch2_en <= '1';
            --    end if;
            --     if(pwm_ch = "011") then
             --            pwm_ch3_en <= '1';
             --            
             --    end if;
             --    if(pwm_ch = "100") then
             --            pwm_ch0_en <= '1';
                         
           --      end if;
             
             if(angle_start_1 < current_angle)then
                   pwm_ch1_en <= '1';
             else
                   sclr1<= '1';
             end if;
               
             if(angle_stop_1 > current_angle) then
                    pwm_ch1_en<= '1';
             else 
                  sclr1<= '1';
              end if;
             
            
           if(angle_start_2 < current_angle)then
                 pwm_ch2_en <= '1';
           else
                 sclr2<= '1';
           end if;
             
           if(angle_stop_2 > current_angle) then
                  pwm_ch2_en<= '1';
           else 
                sclr2<= '1';
            end if;  
                            
         if(angle_start_3 < current_angle)then
               pwm_ch3_en <= '1';
         else
               sclr3<= '1';
         end if;
           
         if(angle_stop_3 > current_angle) then
                pwm_ch3_en<= '1';
         else 
              sclr3<= '1';
          end if;                   
                            
       if(angle_start_0 < current_angle)then
               pwm_ch0_en <= '1';
         else
               sclr0<= '1';
         end if;
           
         if(angle_stop_0 > current_angle) then
                pwm_ch0_en<= '1';
         else 
              sclr0<= '1';
          end if;                   
                       
         
         
                            
                 
          end case;
          end process;                    
   
    
ch1_pwm : pwm_ctrl port map(clk_125M=>clk_125M,rst=>rst, duty_cycle=>duty_ch1, pulse_cnt=>pulse_ch1 , enable => pwm_ch1_en ,pulse_out=>pwm_out_ch1, sclr=>sclr1);     
ch2_pwm : pwm_ctrl port map(clk_125M=>clk_125M,rst=>rst, duty_cycle=>duty_ch2, pulse_cnt=>pulse_ch2 , enable => pwm_ch2_en, pulse_out=>pwm_out_ch2, sclr=>sclr2);
ch3_pwm : pwm_ctrl port map(clk_125M=>clk_125M,rst=>rst, duty_cycle=>duty_ch3, pulse_cnt=>pulse_ch3 ,enable => pwm_ch3_en, pulse_out=>pwm_out_ch3 , sclr=>sclr3);
ch0_pwm : pwm_ctrl port map(clk_125M=>clk_125M,rst=>rst, duty_cycle=>duty_ch0, pulse_cnt=>pulse_ch0 , enable => pwm_ch0_en, pulse_out=>pwm_out_ch0, sclr=>sclr0);       
     
end rtl;