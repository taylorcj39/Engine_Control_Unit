-------------------------------------------------------------------------------
-- Title      :  Engine Simulator Top
-- Project    :  ECU
-------------------------------------------------------------------------------
-- File       : engine_sim_top.vhd   
-- Author     : Chris Taylor
-- Company    : 
-- Created    : 2017-10-14
-- Last update: 2017-10-14
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: Top simulation file containing crank calculator and engine simulator
--              component.
-------------------------------------------------------------------------------
-- Notes:
-- For use in simulation only
-- Need to remove generics?
-------------------------------------------------------------------------------
-- Revisions  :
-- Date				Version	Author	Description
-- 2017-10-14	1.0			CT			Created, with only pulse counter inside 
-- 2017-10-14	1.0			CT			Added entire angle computer inside 
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

entity engine_sim_top is
	generic (WIDTH : integer := 8);
	port (
		rpm       : in integer;   --Desired speed of output pulse train
    clk_125M  : in std_logic; --125Mhz clock pulse
    rst       : in std_logic  --synchronous reset
    --angle     : out integer;  --Calculated output angle
  );
end engine_sim_top;

architecture rtl of engine_sim_top is

  --Component Declerations------------------------------------------------------
  --Engine Simulator (Creates pulse train based on rpm input)
  component engine_sim
    generic (
      TEETH       : integer := 60-2;  --Number of teeth in revolution
      NORM_DUTY    : real := 0.425;    --Normal high/(low+high)
      GAP_FACTOR   : real := 5.25;     --Gap width/tooth before gap
      POST_DUTY    : real := 0.58;      --Tooth after gap/(gap + tooth after)
      START_TOOTH  : integer := 3
    );
    port (
      rpm         : in integer;     --Desired speed of output pulse train
      clk_125M    : in  std_logic;  --125Mhz master clock
      rst          : in  std_logic;  --synchronous global reset
      pulse_train : out  std_logic  --simulated pulse train output
    );
  end component;
  
  --Crank Angle Computer Component
  component crank_angle_computer
    generic (
      TEETH       : integer := 60 - 2;
      WIDTH       : integer := 8;
      GAP_FACTOR    : unsigned(8 - 1 downto 0) := "01010100"  --5.25 in u[8 4] format
    );
    port (
      clk_125M    : in std_logic;           --125Mhz master clock
      rst         : in std_logic;           --global synchronous reset
      pulse_train   : in std_logic;            --pulse train input from crank angle sensor
      sync_achieved : out std_logic;           --sync is achieved signalpulse_train : in std_logic;            --pulse train input from crank angle sensor
      angle       : out unsigned(16 - 1 downto 0);  --calculated crank angle in u[16 6]
      rpm         : out unsigned(16 - 1 downto 0)   --calculated crank rpm in u[16 3]
    );
  end component;
  
  component servo_ctrl is
    generic (
      RPM_WIDTH   : integer := 16;
      ANGLE_WIDTH : integer := 16
    );
    port (
      clk_125M      : in std_logic;
      nrst          : in std_logic;  --global synchronous inverted reset (acts as enable)
      sync          : in std_logic;
      timing_input  : in signed(4 - 1 downto 0);
      angle         : in unsigned(RPM_WIDTH - 1 downto 0); 
      engine_rpm    : in unsigned(RPM_WIDTH - 1 downto 0);
      servo_pwm     : out std_logic
    );
  end component;
  
  --Internal Signals and Constants----------------------------------------------
  signal pulse_train  : std_logic := '0';
  signal angle        : unsigned(16 - 1 downto 0) := (others => '0'); --is this necessary?
  signal engine_rpm   : unsigned(16 - 1 downto 0) := (others => '0'); --is this necessary?
  signal sync         : std_logic := '0';
  signal servo_en     : std_logic := '0';
  signal servo_pwm    : std_logic := '0';
  
  begin  
  
  servo_en <= not rst;
  
  --Component Instantiation-----------------------------------------------------
  
  --Engine simulator
  ENG_SIM : engine_sim
  --using defaults for generics
  port map (
    clk_125M    => '1',--clk_125M,
    rpm         => rpm,
    rst         => rst,
    pulse_train => pulse_train
  );
  
  --Angle Computer
  ANGLE_CPU : crank_angle_computer
  generic map (
    TEETH      => 60-2,
    WIDTH      => 8
  )
  port map (
    clk_125M      => clk_125M,
    rst           => rst,
    pulse_train   => pulse_train,
    sync_achieved => sync,
    angle         => angle,
    rpm           => engine_rpm
  );
  
  --Servo controller
  SERVO : servo_ctrl
  generic map (  
      RPM_WIDTH   => 16,
      ANGLE_WIDTH => 16
    )             
  port map (         
    clk_125M      => clk_125M,
    nrst          => servo_en,
    sync          => sync,
    timing_input  => (others => '0'),
    angle         => angle,
    engine_rpm    => engine_rpm,
    servo_pwm     => servo_pwm
  );             
  
  
  
  
end rtl;