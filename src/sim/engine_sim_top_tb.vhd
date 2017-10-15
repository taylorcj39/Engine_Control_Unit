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
-- Date				Version	Author	Description
-- 2017-10-14	1.0			CT			Created
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

entity engine_sim_top_tb is
end engine_sim_top_tb;

architecture Behavioral of engine_sim_top_tb is
  --Component to be simulated
  component engine_sim_top
    generic (WIDTH : integer := 8);
    port (
      rpm       : in integer;   --Desired speed of output pulse train
      clk_125M  : in std_logic; --125Mhz clock pulse
      rst       : in std_logic  --synchronous reset
      --angle     : out integer;  --Calculated output angle
    );
  end component;
  
  --Signals
  signal rpm : integer := 5000;
  signal rst : std_logic := '1';
  signal clk_125M : std_logic := '0';
  
  constant CLK_125M_PERIOD : time := 8ns;
  
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
  
end Behavioral;