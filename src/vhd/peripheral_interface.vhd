-------------------------------------------------------------------------------
-- Title      : Wrapper Contiaining interface for 4 I/O perephirals
-- Project    : ECU
-------------------------------------------------------------------------------
-- File       : peripheral_interface.vhd   
-- Author     : Robert McInerney
-- Company    : 
-- Created    : 2017-11-26
-- Last update: 2017-11-28
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: Sets up up to 4 I/Os for perephirals
-------------------------------------------------------------------------------
-- Notes:
--  
-------------------------------------------------------------------------------
-- Revisions  :
-- Date			    Version	  Author    Description
-- 2017-11-26   1.0       RM        Created
-- 2017-11-28   1.1       CT        Formatted, changed name from (pwm_fsm.vhd to perephiral_interface.vhd)
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity pwm_fsm is
    Port ( clk_125M : in STD_LOGIC;
           rst : in STD_LOGIC;
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
end pwm_fsm;

architecture Behavioral of pwm_fsm is

component pwm_ctrl
	port (
		clk_125M 		:	in STD_LOGIC;
		rst 				:	in STD_LOGIC;
		duty_cycle	:	in STD_LOGIC_VECTOR (7 downto 0);
		pulse_cnt 	: in STD_LOGIC_VECTOR (15 downto 0);	--# of mclk ticks in 1 period
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
signal pwm_ch4_en: std_logic;

signal sclr1: std_logic;
signal sclr2: std_logic;
signal sclr3: std_logic;
signal sclr4: std_logic;

signal duty_ch1: std_logic_vector(7 downto 0);
signal duty_ch2: std_logic_vector(7 downto 0);
signal duty_ch3: std_logic_vector(7 downto 0);
signal duty_ch4: std_logic_vector(7 downto 0);
signal pulse_ch1: std_logic_vector(15 downto 0);
signal pulse_ch2: std_logic_vector(15 downto 0);
signal pulse_ch3: std_logic_vector(15 downto 0);
signal pulse_ch4: std_logic_vector(15 downto 0);

signal angle_start_1: std_logic_vector(15 downto 0);
signal angle_stop_1: std_logic_vector(15 downto 0);
signal angle_start_2: std_logic_vector(15 downto 0);
signal angle_stop_2: std_logic_vector(15 downto 0);
signal angle_start_3: std_logic_vector(15 downto 0);
signal angle_stop_3: std_logic_vector(15 downto 0);
signal angle_start_4: std_logic_vector(15 downto 0);
signal angle_stop_4: std_logic_vector(15 downto 0);

begin


PWM_Channel : process(clk_125M, rst) begin
		
     if rst = '1' then y <= s1;
     elsif(clk_125M'event and clk_125M = '1') then 
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
                      duty_ch4 <= duty;
                      pulse_ch4 <= pulse;
                      angle_start_4 <= angle_start;
                      angle_stop_4 <= angle_stop;
                 end if;
                 
     end case;
     end if;
     end process;     
     
     
     Outputs: process(clk_125M, y, pwm_ch)
     begin
     
         pwm_ch1_en <= '0'; pwm_ch2_en <= '0'; pwm_ch3_en <= '0'; pwm_ch4_en <= '0';
         sclr1 <= '0'; sclr2 <= '0'; sclr3 <= '0'; sclr4 <= '0'; 
         
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
             --            pwm_ch4_en <= '1';
                         
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
                            
       if(angle_start_4 < current_angle)then
               pwm_ch4_en <= '1';
         else
               sclr4<= '1';
         end if;
           
         if(angle_stop_4 > current_angle) then
                pwm_ch4_en<= '1';
         else 
              sclr4<= '1';
          end if;                   
                       
         
         
                            
                 
          end case;
          end process;                    
   
    
ch1_pwm: teknik_ctrl port map(clk_125M=>clk_125M,rst=>rst, duty_cycle=>duty_ch1, pulse_cnt=>pulse_ch1 , enab => pwm_ch1_en ,pulse_out=>pwm_out_ch1, sclr=>sclr1);     
ch2_pwm: teknik_ctrl port map(clk_125M=>clk_125M,rst=>rst, duty_cycle=>duty_ch2, pulse_cnt=>pulse_ch2 , enab => pwm_ch2_en, pulse_out=>pwm_out_ch2, sclr=>sclr2);
ch3_pwm: teknik_ctrl port map(clk_125M=>clk_125M,rst=>rst, duty_cycle=>duty_ch3, pulse_cnt=>pulse_ch3 ,enab => pwm_ch3_en, pulse_out=>pwm_out_ch3 , sclr=>sclr3);
ch4_pwm: teknik_ctrl port map(clk_125M=>clk_125M,rst=>rst, duty_cycle=>duty_ch4, pulse_cnt=>pulse_ch4 , enab => pwm_ch4_en, pulse_out=>pwm_out_ch4, sclr=>sclr4);       
     
end rtl;