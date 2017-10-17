-------------------------------------------------------------------------------
-- Title      : Crank Angle Computer
-- Project    : ECU
-------------------------------------------------------------------------------
-- File       : crank_angle_computer.vhd   
-- Author     : Chris Taylor
-- Company    : 
-- Created    : 2017-10-17
-- Last update: 2017-10-17
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: Top level component which calculates current angle of crank shaft
--    based on pulse-train input from crank angle sensor
-------------------------------------------------------------------------------
-- Notes:
-- 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date			    Version	  Author    Description
-- 2017-10-17   1.0       CT        Created
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

entity crank_angle_computer is 
  generic(
    TEETH       : integer := 60 - 2;
    WIDTH       : integer := 8;
    GAP_FACTOR  : integer := 4
  );
  port (
    clk_125M    : in std_logic;           --125Mhz master clock
    rst         : in std_logic;           --global synchronous reset
    pulse_train : in std_logic            --pulse train input from crank angle sensor
    --angle       : out std_logic_vector;
  );
end crank_angle_computer;

architecture Behavioral of crank_angle_computer is

begin

end Behavioral;