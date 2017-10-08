-------------------------------------------------------------------------------
-- Title      :  
-- Project    : 
-------------------------------------------------------------------------------
-- File       : template.vhd   
-- Author     : Chris Taylor
-- Company    : 
-- Created    : yyyy-mm-dd
-- Last update: yyyy-mm-dd
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description:
-------------------------------------------------------------------------------
-- Notes:
-- 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date				Version	Author	Description
-- yyyy-mm-dd	1.0			CT			Created
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

entity pulse_counter is
	generic(WIDTH : integer := 8);
	port (
		clk_125M    : in	std_logic;                               --125Mhz master clock
		sclk        : in	std_logic;                               --sampling clock
		clr	        : in	std_logic;                               --clr
		pulse_train : in	std_logic;                               --pulse train from sensor
		x           : out std_logic_vector(WIDTH - 1 downto 0);   --high pulse width in samples
		y           : out std_logic_vector(WIDTH - 1 downto 0);   --low pulse width in samples
		x_valid	    : out std_logic;                              --high pulse width ready to be read
		y_valid	    : out std_logic                               --low pulse width ready to be read
	);
end pulse_counter;

architecture Behavioral of pulse_counter is
  --Internal Signals
  signal x_count  : unsigned(WIDTH - 1 downto 0);
  signal x_lock   : std_logic;
  signal y_count  : unsigned(WIDTH - 1 downto 0);
  signal y_lock   : std_logic;
  
  begin
  
  XCNT: process(clk_125M, sclk, pulse_train, clr)
  begin
    if rising_edge(clk_125M) then
      if (clr = '1') then
        x_count <= (others => '0');
      elsif (x_lock = '0') then
        if (sclk = '1' and pulse_train = '1') then
          x_count <= x_count + 1;
          x_lock <= '1'
        end if;
      end if;   
    end if;
    
  end process;
  
  YCNT: process(clk_125M, sclk, pulse_train, clr)
  begin
    
  end process;
	
end Behavioral;

