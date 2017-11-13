-------------------------------------------------------------------------------
-- Title      :  Engine Simulator Testbench
-- Project    :  ECU
-------------------------------------------------------------------------------
-- File       : engine_sim_top_tb.vhd   
-- Author     : Chris Taylor
-- Company    : 
-- Created    : 2017-10-14
-- Last update: 2017-10-14
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: Testbench for simulating "engine simulator" simulation
-------------------------------------------------------------------------------
-- Notes:
-- 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date				  Version	 Author	 Description
-- 2017-10-14	  1.0			 CT			 Created
-- 2017-11-12   1.1      CT      Added functionality for angle counter
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

entity engine_sim_top_tb is
end engine_sim_top_tb;

architecture rtl of engine_sim_top_tb is
  --Component to be simulated
  component engine_sim_top
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
  
  --Signals
  signal rpm : integer := 5000;
  signal rst : std_logic := '1';
  signal clk_125M : std_logic := '0';
  
  constant CLK_125M_PERIOD : time := 8 ns;
  
  begin
  
  clk_125M <= not clk_125M after CLK_125M_PERIOD * 0.5;
  
  uut : engine_sim_top
  generic map(WIDTH => 8)
  port map(
    rpm       => rpm,   
    clk_125M  => clk_125M,
    rst       => rst
  );
  
  STIM : process
  begin
    wait for CLK_125M_PERIOD * 3;
    rst <= '0';
    wait for 13ms;
    rpm <= 1000;
    wait for 13ms;
  end process;
  
end rtl;