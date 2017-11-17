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
      TEETH      : integer := 60-2;  --Number of teeth in revolution
      NORM_DUTY  : real := 0.425;    --Normal high/(low+high)
      --GAP_DUTY   : real := 0.16;     --Tooth before gap/(gap + tooth before)
      GAP_FACTOR : real := 5.25;     --Gap width/tooth before gap
      POST_DUTY  : real := 0.58      --Tooth after gap/(gap + tooth after)
    );
    port (
      rpm         : in integer;     --Desired speed of output pulse train
      clk_125M    : in  std_logic;  --125Mhz master clock
      enable      : in  std_logic;  --sampling clock
      rst          : in  std_logic;  --clr
      pulse_train : out  std_logic  --simulated pulse train output
    );
  end component;
  
  --Crank Angle Computer Component
  component crank_angle_computer
    generic (
      TEETH       : integer := 60 - 2;
      WIDTH       : integer := 8;
      GAP_FACTOR  : integer := 4
    );
    port (
      clk_125M    : in std_logic;           --125Mhz master clock
      rst         : in std_logic;           --global synchronous reset
      pulse_train : in std_logic;            --pulse train input from crank angle sensor
      --tooth_count : out std_logic_vector(integer(ceil(log2(TEETH)))- 1 downto 0);
      angle       : out std_logic_vector(16 - 1 downto 0)
    );
  end component;
  
  --Internal Signals and Constants----------------------------------------------
  signal pulse_train  : std_logic := '0';
  signal sim_enable   : std_logic := '1'; --is this necessary?
  signal angle        : std_logic_vector(16 - 1 downto 0) := (others => '0'); --is this necessary?
  
  begin  
  --External Assignments--------------------------------------------------------
  
  --Component Instantiation-----------------------------------------------------
  --Engine simulator
  ENG_SIM : engine_sim
--  generic map (
--    TEETH => 60 - 2,
--    GAP_DUTY => 0.16,
--    DUTY => 0.425)
  port map (
    clk_125M    => '1',--clk_125M,
    rpm         => rpm,
    enable      => sim_enable,
    rst         => rst,
    pulse_train => pulse_train
  );
  
  --Angle Computer
  ANGLE_CPU : crank_angle_computer
  generic map (
    TEETH      => 60-2,
    WIDTH      => 8,
    GAP_FACTOR => 5
  )
  port map (
    clk_125M    => clk_125M,
    rst         => rst,
    pulse_train => pulse_train,
    angle       => angle
  );
  
end rtl;