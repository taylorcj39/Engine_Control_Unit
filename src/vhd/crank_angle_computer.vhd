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
--  (2017-11-20): Tooth counter has bugs, needs to be moved to within gap_synchronizer
-------------------------------------------------------------------------------
-- Revisions  :
-- Date			    Version	  Author    Description
-- 2017-10-17   1.0       CT        Created
-- 2017-11-12   1.0       CT        Added angle counter (early revision) and synchronizer

-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

entity crank_angle_computer is 
  generic (
    TEETH       : integer := 60 - 2;
    WIDTH       : integer := 8;
    GAP_FACTOR    : unsigned(8 - 1 downto 0) := "01010100"  --5.25 in u[8 4] format
  );
  port (
    clk_125M    : in std_logic;           --125Mhz master clock
    rst         : in std_logic;           --global synchronous reset
    pulse_train : in std_logic;            --pulse train input from crank angle sensor
    angle       : out unsigned(16 - 1 downto 0);  --calculated crank angle in u[16 6]
    rpm         : out unsigned(16 - 1 downto 0)   --calculated crank rpm in u[16 3]
  );
end crank_angle_computer;

architecture rtl of crank_angle_computer is
  --Constants-------------------------------------------------------------------
  constant TOOTH_COUNT_WIDTH  : integer := integer(ceil(log2(real(TEETH)))); --Width of tooth counter
  constant TOOTH_COUNT_MAX    : unsigned(TOOTH_COUNT_WIDTH - 1 downto 0) := to_unsigned(TEETH, TOOTH_COUNT_WIDTH); --Max value toth counter can reach
  constant DOUBLE_WIDTH       : integer := WIDTH * 2; --Double width required for y to handle gap
  
  --Internal Signals------------------------------------------------------------
  --Tooth Counter
  signal tooth_count_inc    : std_logic := '0';
  signal tooth_count_rst    : std_logic := '0';
  signal tooth_count_toggle : std_logic := '0';
  signal tooth_count        : unsigned(TOOTH_COUNT_WIDTH - 1 downto 0) := (0 => '1', others=> '0');
  
  --Pulse Counter
  signal x        : unsigned(WIDTH - 1 downto 0) := (others => '0');
  signal y        : unsigned(DOUBLE_WIDTH - 1 downto 0) := (others => '0');
  signal x_valid  : std_logic := '0';                  
  signal y_valid  : std_logic := '0';                   
  
  signal gap_present  : std_logic := '0';
  signal sync         : std_logic := '0';
  
  --Component Declerations------------------------------------------------------
  --Gap Synchronizer determines where missing tooth is
  component gap_synchronizer
    generic (
      TEETH       : integer := 60-2;  --teeth on wheel 
      WIDTH       : integer := 8;      --width of x,y
      GAP_FACTOR    : unsigned(8 - 1 downto 0) := "01010100"  --5.25 in u[8 4] format
    );
    port (
      clk_125M        : in  std_logic;
      rst             : in  std_logic;
      x               : in unsigned(WIDTH - 1 downto 0);
      y               : in unsigned((WIDTH * 2) - 1 downto 0);
      x_valid         : in std_logic;
      y_valid         : in std_logic;
      tooth_count     : in unsigned(integer(ceil(log2(real(TEETH))))- 1 downto 0);
      tooth_count_rst : out std_logic;
      sync            : out std_logic;
      gap_present     : out std_logic
    );
  end component;
  
  --Angle Counter computes current angle of crank shaft
  component angle_counter
    generic(
      TEETH   : integer := 60 - 2;
      X_DEG   : unsigned := "0000000010100010"; --2.5451 in u[16 6] format
      Y_DEG   : unsigned := "0000000011011101"; --3.4549 in u[16 6] format
      GAP_DEG : unsigned := "0000001111011101"  --15.4549 in u[16 6] format
    );
    port (
      clk_125M    : in std_logic;          --125Mhz master clock
      rst         : in std_logic;          --global synchronous reset
      x           : in unsigned(WIDTH - 1 downto 0);
      y           : in unsigned(WIDTH*2 - 1 downto 0);
      x_valid     : in std_logic;
      y_valid     : in std_logic;
      sync        : in std_logic;
      gap_present : in std_logic;          --signal from gsynchronizer
      --tooth_count : in std_logic_vector(integer(ceil(log2(real(TEETH))))- 1 downto 0);
      angle       : out unsigned(16 - 1 downto 0) --[16 6] unsigned fixed point 
    );
  end component;
  
  --Pulse counter determines width of previous tooth/gap
  component pulse_counter
    generic(WIDTH : integer := 8);
    port (
      clk_125M    : in  std_logic;                      --125Mhz master clock
      rst         : in  std_logic;                     --global synchronous reset
      pulse_train : in  std_logic;                      --pulse train from sensor
      x           : out unsigned(WIDTH - 1 downto 0);   --high pulse width in samples
      y           : out unsigned((WIDTH * 2) - 1 downto 0);   --low pulse width in samples
      x_valid     : out std_logic;                     --high pulse width ready to be read
      y_valid     : out std_logic                      --low pulse width ready to be read
    );
  end component;
  
  --RPM calculator component, computes rpm based on tooth width
  component rpm_calculator
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
  end component;
  
  begin

  --Falling Edge Tooth Counter (Starts at 0, has to be manually reset to 1)--------------------------------------------------------------- 
  TOOTH_CNT : process(clk_125M)
  begin
  if rising_edge(clk_125M) then             --Makes process synchronous
      if (rst = '1'or tooth_count_rst = '1') then                     --Always check clr
        --tooth_count <= (0 => '1',others => '0');  --reset to 1
        tooth_count <= (others => '0'); --reset to 0
      elsif (pulse_train = '1' and tooth_count_toggle = '0') then
        --tooth_count <= tooth_count + 1;
        tooth_count_toggle <= '1';
      elsif (pulse_train = '0' and tooth_count_toggle = '1') then
        tooth_count <= tooth_count + 1;
        tooth_count_toggle <= '0';   
      end if;
    end if;      
  end process;
  
  --Component Instantiations----------------------------------------------------
  
  --Pulse Counter
  PULSE_CNT : pulse_counter
  generic map (
    WIDTH => WIDTH
  )
  port map (
    clk_125M    => clk_125M,
    rst         => rst,
    pulse_train => pulse_train,
    x           => x,
    y           => y,
    x_valid     => x_valid,
    y_valid     => y_valid
  );
  
  --Gap Synchronizer
  SYNCHRONIZER : gap_synchronizer
  generic map (
    TEETH       => TEETH, 
    WIDTH       => WIDTH,
    GAP_FACTOR  => GAP_FACTOR
  )
  port map(
    clk_125M        => clk_125M,
    rst             => rst,
    x               => x,
    y               => y,
    x_valid         => x_valid,
    y_valid         => y_valid,
    tooth_count_rst => tooth_count_rst,
    tooth_count     => tooth_count,
    sync            => sync,
    gap_present     => gap_present
  );
  
  --Angle Counter
  ANGLE_CNT : angle_counter
  generic map(
    TEETH   => 60 - 2,
    X_DEG   => "0000000010100010", --2.5451 in u[16 6] format 
    Y_DEG   => "0000000011011101", --3.4549 in u[16 6] format 
    GAP_DEG => "0000001111011101"  --15.4549 in u[16 6] format
  )
  port map (
    clk_125M    => clk_125M,
    rst         => rst,
    x           => x,
    y           => y,
    x_valid     => x_valid,
    y_valid     => y_valid,
    sync        => sync,
    gap_present => gap_present,
    --tooth_count => --tooth_count,
    angle       => angle
  );
  
  --RPM Calculator
  RPM_CALC : rpm_calculator
  generic map(
    X_WIDTH   => WIDTH,
    RPM_WIDTH => DOUBLE_WIDTH
  )
  port map(
    clk_125M  => clk_125M,
    rst       => rst,
    x         => x,
    x_valid   => x_valid,
    rpm       => rpm
  );
                             
end rtl;