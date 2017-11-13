-------------------------------------------------------------------------------
-- Title      : Angle Counter
-- Project    : ECU
-------------------------------------------------------------------------------
-- File       : angle_counter.vhd   
-- Author     : Chris Taylor
-- Company    : 
-- Created    : 2017-10-17
-- Last update: 2017-10-17
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: Counts and calculates angle based on current tooth in cycle
-------------------------------------------------------------------------------
-- Notes:
-- 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date			    Version	  Author    Description
-- 2017-11-12   1.0       CT        Created
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

entity angle_counter is 
  generic(
    TEETH       : integer := 60 - 2;
    X_DEG   : unsigned := "0000000010100001"; --2.53 in u[16 6] format
    Y_DEG   : unsigned := "0000000010100001"; --YYY in u[16 6] format
    GAP_DEG : unsigned := "0000000010100001"  --GGG in u[16 6] format
  );
  port (
    clk_125M    : in std_logic;          --125Mhz master clock
    rst         : in std_logic;          --global synchronous reset
    x           : in std_logic_vector(8 - 1 downto 0);
    y           : in std_logic_vector(16 - 1 downto 0);
    x_valid     : in std_logic;
    y_valid     : in std_logic;
    sync        : in std_logic;
    gap_present : in std_logic;          --signal from gsynchronizer
    --tooth_count : in std_logic_vector(integer(ceil(log2(real(TEETH))))- 1 downto 0);          --
    angle       : out std_logic_vector(16 - 1 downto 0) --[16 6] unsigned fixed point 
  );
end angle_counter;

architecture Behavioral of angle_counter is
  --Constants-------------------------------------------------------------------
  --constant LRES_ANGLE : unsigned(16 - 1 downto 0) := to_unsigned(16 - 1 downto 0)
  constant ANGLE_MAX : unsigned(16 - 1 downto 0) := "1011010000000000"; --720 in u[16 6]
  
  --State type and signals------------------------------------------------------
  type STATE_TYPE is (start, normal, gap);
  signal state : STATE_TYPE := start;
  
  --Internal Signals----------------------------------------------------------------
  signal aclk_q : unsigned(3 - 1 downto 0);
  signal aclk   : std_logic;
  signal sclk_q : unsigned(9 - 1 downto 0);
  signal sclk   : std_logic;
  
  signal x_q    : unsigned(8 - 1 downto 0); 
  signal y_q    : unsigned(16 - 1 downto 0);
  
  signal angle_q : unsigned(16 - 1 downto 0);
   
  begin
  
  --Registers-------------------------------------------------------------------
  X_REG : process(clk_125M)
  begin
    if rising_edge(clk_125M) then
      if rst = '1' then
        x_q <= (others => '0');
      elsif (x_valid = '1') then
        x_q <= unsigned(x);
      end if;
    end if;
  end process;
    
  Y_REG : process(clk_125M)
  begin
    if rising_edge(clk_125M) then
      if rst = '1' then
        y_q <= (others => '0');
      elsif (y_valid = '1') then
        y_q <= unsigned(y);
      end if;
    end if;
  end process;
 
  --Sampling clk generator
  SCLKGEN : process(clk_125M)
  begin
  if rising_edge(clk_125M) then
    if rst = '1' then
      sclk_q <= (others => '0');
    else
      sclk_q <= sclk_q + 1;
    end if;    
  end if;   
  end process;
  sclk <= sclk_q(9 - 1); --Slowed sclk down by half, currently counting on high and low
 
    
 --31.3MHz clk generator
 ACLK_GEN : process(clk_125M)
 begin
 if rising_edge(clk_125M) then
   if rst = '1' then
     aclk_q <= (others => '0');
   else
     aclk_q <= aclk_q + 1;
   end if;    
 end if;   
 end process;
 aclk <= aclk_q(3 - 1);
 
 --FSM (Mealy machine)--------------------------------------------------------------------------
  --State Transition Process
  TRANSITION : process(clk_125M)
  begin
  if rising_edge(clk_125M) then
    if rst = '1' or sync  = '0' then
      state <= start;
    else
      case state is
        when start =>
          if sync = '1' then
            state <= normal;
          end if;
        when normal =>
          if gap_present = '1' then
            state <= gap;
          end if;  
        when gap => 
          if gap_present = '0' then
            state <= normal;
          end if;  
      end case;  
    end if;
  end if;
  end process;
  
  ASSIGNMENT : process(state, x_valid, y_valid, gap_present, angle_q)
  begin
    --Default outputs
    angle_q <= (others => '0');
    case state is
      when start =>
        null;
      when normal =>
        if x_valid = '1' then
          angle_q <= angle_q + X_DEG;
        elsif y_valid = '1' then
          angle_q <= angle_q + Y_DEG;
        end if;
      when gap =>
        if gap_present = '0' then --May not work, might need additional state
          angle_q <= angle_q + GAP_DEG;
        end if;    
    end case;
  end process;
  
-- --Low Resolution Angle Incrementer
-- LRES_ANGLE_INC : process(clk_125M)
-- begin
-- if rising_edge(clk_125M) then
--  if rst = '1' then
--    angle_q <= (others => '0');
--  elsif x_valid = '1' then
--    if angle_q < ANGLE_MAX then
--      angle_q <= angle_q + TOOTH_DEG;
--    else
--      angle_q <= (others => '0');
--    end if;
--  elsif y_valid and 
--  end if;
-- end if;
-- end process;
 
 angle <= std_logic_vector(angle_q);
end Behavioral;