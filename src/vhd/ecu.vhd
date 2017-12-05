-------------------------------------------------------------------------------
-- Title      : Engine Control Unit
-- Project    : ECU
-------------------------------------------------------------------------------
-- File       : ecu.vhd   
-- Author     : Chris Taylor
-- Company    : 
-- Created    : 2017-12-02
-- Last update: 2017-12-02
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: Contains crank angle calculator, servo controller, and peripheral interface
-------------------------------------------------------------------------------
-- Notes:
-- 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date			    Version	  Author    Description
-- 2017-11-26   1.0       CT        Created
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

entity ecu is
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
end ecu;

architecture rtl of ecu is
  
  --Crank angle computer decleration
  component crank_angle_computer
    generic (
      TEETH       : integer := 60 - 2;
      WIDTH       : integer := 8;
      GAP_FACTOR  : unsigned(8 - 1 downto 0) := "01010100"  --5.25 in u[8 4] format
    );
    port (
      clk_125M      : in std_logic;           --125Mhz master clock
      rst           : in std_logic;           --global synchronous reset
      pulse_train   : in std_logic;            --pulse train input from crank angle sensor
      sync_achieved : out std_logic;           --sync is achieved signal
      angle         : out unsigned(16 - 1 downto 0);  --calculated crank angle in u[16 6]
      rpm           : out unsigned(16 - 1 downto 0)   --calculated crank rpm in u[16 3]
    );
  end component;
  
  --Peripheral Interface decleration
  component peripheral_interface
    port ( 
        clk_125M      : in STD_LOGIC;
        rst           : in STD_LOGIC;
        --enab: in std_logic;
        duty          : in unsigned(8 - 1 downto 0);
        pulse         : in unsigned(16 - 1 downto 0);
        pwm_ch        : in unsigned(3 - 1 downto 0);
        angle_start   : in unsigned(16 - 1 downto 0);
        angle_stop    : in unsigned(16 - 1 downto 0);
        current_angle : in unsigned(16 - 1 downto 0);
        pwm_out_ch0   : out STD_LOGIC;
        pwm_out_ch1   : out STD_LOGIC;
        pwm_out_ch2   : out STD_LOGIC;
        pwm_out_ch3   : out STD_LOGIC
      );
  end component;
  
  --Servo Controller
  component servo_ctrl
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

  
  --Internal Signals
  signal engine_angle : unsigned(16 - 1 downto 0) := (others => '0'); --is this necessary?
  signal rpm          : unsigned(16 - 1 downto 0) := (others => '0'); --is this necessary?
  signal sync         : std_logic := '0';
  signal servo_en     : std_logic := '0';
  
  begin  
  
  servo_en <= not rst;
  engine_rpm <= rpm;
   
  --Component Instantiations-----------------------------------------------------
  
  --Angle Computer
  CPU : crank_angle_computer
  generic map (
    TEETH      => 60-2,
    WIDTH      => 8
  )
  port map (
    clk_125M      => clk_125M,
    rst           => rst,
    pulse_train   => pulse_train,
    sync_achieved => sync,
    angle         => engine_angle,
    rpm           => rpm
  );
  
  --peripheral interface
  PERIPHERALS : peripheral_interface
  port map (       
    clk_125M      => clk_125M,   
    rst           => rst,
    duty          => p_duty,       
    pulse         => p_pulse_count,
    pwm_ch        => p_pwm_ch,     
    angle_start   => p_angle_start,
    angle_stop    => p_angle_stop, 
    current_angle => engine_angle,
    pwm_out_ch0   => p_ch0,
    pwm_out_ch1   => p_ch1,
    pwm_out_ch2   => p_ch2,
    pwm_out_ch3   => p_ch3
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
    timing_input  => timing_input,
    angle         => engine_angle,
    engine_rpm    => rpm,
    servo_pwm     => servo_pwm
  );     
end rtl;