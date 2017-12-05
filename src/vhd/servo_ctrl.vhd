-------------------------------------------------------------------------------
-- Title      : Servo/BLDC Controller
-- Project    : ECU
-------------------------------------------------------------------------------
-- File       : servo_ctrl.vhd   
-- Author     : Chris Taylor
-- Company    : 
-- Created    : 2017-11-25
-- Last update: 2017-11-29
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: Controls servo/BLDC based off engine angle and rpm
-------------------------------------------------------------------------------
-- Notes:
--  2017-11-29: START_ANGLE is 0, Glitch occurs after funky tooth, error in PWM block
-------------------------------------------------------------------------------
-- Revisions  :
-- Date			    Version	  Author    Description
-- 2017-11-25   1.0       CT        Created
-- 2017-11-28   1.1       CT        Added architecture (No working timing variance)
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

entity servo_ctrl is
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
end entity;

architecture rtl of servo_ctrl is
  --Internal Constants and Signals----------------------------------------------
  constant START_ANGLE : unsigned(16 - 1 downto 0) := (others => '0');  --Angle at which the motor starts spinning
  constant NUM : unsigned(32 - 1 downto 0) := shift_left(to_unsigned(1250000,32),3);
  constant FIFTY : unsigned(8 - 1 downto 0) := to_unsigned(50,8);
  constant X_DEG   : unsigned := "0000000010100010"; --2.5451 in u[16 6] format
  
  signal desired_rpm : unsigned(16 - 1 downto 0) := (others => '0');
  signal intermediate : unsigned(32 - 1 downto 0) := (others => '0');
  signal pulse_count : unsigned(16 - 1 downto 0) := (others => '0');
  signal intermediate_q : signed(32 - 1 downto 0) := (others => '0');
  signal engine_rpm_q : signed(32 - 1 downto 0) := (others => '0');
  signal div_v  : std_logic := '0';
  
  signal drive_pwm : std_logic := '0';
  signal start_angle_v : std_logic := '0';
  signal start_angle_e : std_logic := '0';
  signal servo_en : std_logic := '0';
  signal rst : std_logic := '0';
  
  --Component Decleration
  component pwm_ctrl
    port (
      clk_125M    : in STD_LOGIC;
      rst         : in STD_LOGIC;
      duty_cycle  : in unsigned(7 downto 0);
      pulse_cnt   : in unsigned (15 downto 0);  --# of mclk ticks in 1 period
      enable      : in std_logic;
      sclr        : in std_logic;        
      pulse_out   : out STD_LOGIC  --Output PWM signal
    );
  end component;
  
  component div_restoring is
    generic (
      N : integer := 16
    );
    port(
        clk  : in  std_logic;
        rst  : in  std_logic;
        go   : in  std_logic;
        x    : in  signed(N - 1 downto 0);
        d    : in  signed(N - 1 downto 0);
        q    : out signed(N - 1 downto 0);
        done : out std_logic
    );
  end component;
  
  begin
  
  rst <= not nrst;
  
  --Calculate pulse_count
  desired_rpm <= shift_right(engine_rpm,2) when timing_input = "0000" else (engine_rpm / 4);  --Only works for nominal operation currently
--  intermediate <= (NUM / desired_rpm) when desired_rpm /= X"00000000" else (others => '0'); --safeguard for div/0
  --pulse_count <= shift_right(intermediate(16 - 1 downto 0),2);  --unsure why shift 2 rather than shift 3
  --pulse_count <= X"0FE2";
--  
  START_ANGLE_REG : process(clk_125M)
  begin
    if rising_edge(clk_125M) then
      if sync = '0' or nrst = '0' then
        servo_en <= '0';
      elsif start_angle_v <= '1' and nrst = '1' and sync = '1' then
        servo_en <= '1';
      end if;
    end if;
  end process;
  start_angle_v <= '1' when angle <= START_ANGLE + X_DEG and angle >= START_ANGLE - X_DEG else '0'; 
  
  RPM_DIV_REG : process(clk_125M)
  begin
    if rising_edge(clk_125M) then
      if rst = '1' then
        pulse_count <= (others => '0');   
      elsif div_v = '1' then
        pulse_count <= shift_right(intermediate(16 - 1 downto 0),2);
      end if;
    end if;
  end process;
   
  --Component instantiation
  PWM : pwm_ctrl
  port map(
    clk_125M   => clk_125M,
    rst        => rst,
    duty_cycle => FIFTY,
    pulse_cnt  => pulse_count,
    enable     => servo_en,
    sclr       => '0',
    pulse_out  => drive_pwm
  );
  
  --Divider
  DIV : div_restoring
  generic map (
    N => 32
  )
  port map (
    clk  => clk_125M,
    rst  => rst,
    go   => '1',
    x    => signed(std_logic_vector(NUM)),
    d    => engine_rpm_q,
    q    => intermediate_q, --no div/0 protection
    done => div_v
  );
  
  engine_rpm_q <= signed(std_logic_vector(X"0000" & engine_rpm));
  intermediate <= unsigned(std_logic_vector(intermediate_q));
  servo_pwm <= drive_pwm when servo_en  = '1' else '0'; --Current motor has no "servoing capabilities, so "open pos" = off
end rtl;