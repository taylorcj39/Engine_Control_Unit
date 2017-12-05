-------------------------------------------------------------------------------
-- Title      : Engine Control Unit Top
-- Project    : ECU
-------------------------------------------------------------------------------
-- File       : ecu_top.vhd   
-- Author     : Chris Taylor
-- Company    : 
-- Created    : 2017-12-02
-- Last update: 2017-12-02
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: Board-level top file
-------------------------------------------------------------------------------
-- Notes:
-- 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date			    Version	  Author    Description
-- 2017-12-03  1.0       CT        Created
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

entity ecu_top is
  port (
    clk : in std_logic;
    btn : in std_logic_vector(0 downto 0);
    j0  : in std_logic_vector(0 downto 0);  --j0(0) = sensor to board (pulse train)
    j2  : out std_logic_vector(0 downto 0)  --j2(0) = board to servo (servo_pwm)
  );                                      
end ecu_top;

architecture rtl of ecu_top is
  --signal 
  signal pulse_train  : std_logic := '0';
  signal rst          : std_logic := '0';
  signal servo_pwm    : std_logic := '0';
  
  --ECU Component
  component ecu is
  port (
    clk_125M        : in std_logic;
    rst             : in std_logic;
    pulse_train     : in std_logic;
    timing_input    : in signed(4 - 1 downto 0);
    --Peripheral Configuration signals
    p_duty          : in unsigned(8 - 1 downto 0);
    --p_invert        : in std_logic;
    p_pulse_count   : in unsigned(16 - 1 downto 0);
    p_pwm_ch        : in unsigned(3 - 1 downto 0);
    p_angle_start   : in unsigned(16 - 1 downto 0);
    p_angle_stop    : in unsigned(16 - 1 downto 0);
    --Outputs
    engine_rpm      : out unsigned(16 - 1 downto 0);
    servo_pwm       : out std_logic;
    p_ch0           : out std_logic;
    p_ch1           : out std_logic;
    p_ch2           : out std_logic;
    p_ch3           : out std_logic
  );  
  end component;
  
  begin
  
  --FFs added to meet timing----------------------------------------------------
--  IO_FF : process(clk, j0(0))
--  begin
--    if btn(0)='1' then
--        j2(0) <= '0';
--        pulse_train <= '0';
--    elsif rising_edge(clk) then
--      --if rst = '1' then
--      --etc
--      pulse_train <= j0(0);
--      j2(0) <= servo_pwm;
--      rst <= btn(0);
--    end if;
--  end process;
  
  --Instantantiation of ECU
  ECU_COMPONENT : ecu
  port map (
    clk_125M      => clk,
    rst           => btn(0),
    pulse_train   => j0(0),
    timing_input  => "0000",
    --Peripheral  => 
    p_duty        => (others => '0'),
    --p_invert    => (others => '0'),
    p_pulse_count => (others => '0'),
    p_pwm_ch      => (others => '0'),
    p_angle_start => (others => '0'),
    p_angle_stop  => (others => '0'),
    --Outputs
    engine_rpm    => open,
    servo_pwm     => j2(0),
    p_ch0         => open,
    p_ch1         => open,
    p_ch2         => open,
    p_ch3         => open
  );
  
end rtl;