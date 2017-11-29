-------------------------------------------------------------------------------
-- Title      : Sclk ticks to RPM Calculator
-- Project    : ECU
-------------------------------------------------------------------------------
-- File       : rpm_calculator.vhd   
-- Author     : Chris Taylor
-- Company    : 
-- Created    : 2017-11-25
-- Last update: 2017-11-25
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: Combinational txt based LUT to convert u[8 0] sclk_tick count to u[16 3] rpm
-------------------------------------------------------------------------------
-- Notes:
--  (2017-11-25) Resolution is poor (114.75rpm per sclk bit), math of conversion needs to be checked
-------------------------------------------------------------------------------
-- Revisions  :
-- Date			    Version	  Author    Description
-- 2017-11-25   1.0       CT        Created
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

entity rpm_calculator is
  generic (
    X_WIDTH   : integer := 8;
    RPM_WIDTH : integer := 16
  );
  port (
    clk_125M  : in std_logic;
    rst       : in std_logic;
    x         : in unsigned(X_WIDTH - 1 downto 0);  --Input X width in sampling clk ticks
    x_valid   : in std_logic;
    rpm       : out unsigned(RPM_WIDTH - 1 downto 0) --Output rpm in u[16 6] format
  );
end entity;

architecture rtl of rpm_calculator is
  --Internal Signals and constants
  signal x_q : unsigned(X_WIDTH - 1 downto 0):= (others => '0');  --registered correct x width
  
  --txt LUT Component Decleration
  component txt_lut is
    generic (
      NI          : INTEGER  := 8;  --Input width
      NO          : INTEGER  := 12; --Output width
      FILE_NAME   : STRING -- file where the numerical values are stored
    );
    port (
      LUT_in  : in std_logic_vector (NI-1 downto 0);
      LUT_out : out std_logic_vector (NO-1 downto 0)
    );
  end component;
  
  begin
  
  --X register
  X_REG : process(clk_125M)
  begin
    if rising_edge(clk_125M) then
      if rst = '1' then
        x_q <= (others => '0');
      elsif (x_valid = '1') then
        x_q <= x;
      end if;
    end if;
  end process;
  
  --txt LUT instantiation
  LUT : txt_lut
  generic map (
    NI => 8,
    NO => 16,
    FILE_NAME => "rpm_lut.txt"  
  )
  port map (
    LUT_in  => std_logic_vector(x_q),
    unsigned(LUT_out) => rpm
  );
 
  
end rtl;