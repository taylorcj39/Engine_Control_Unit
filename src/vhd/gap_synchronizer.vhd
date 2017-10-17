-------------------------------------------------------------------------------
-- Title      : Gap Synchronizer
-- Project    : ECU
-------------------------------------------------------------------------------
-- File       : gap_synchronizer.vhd   
-- Author     : Chris Taylor
-- Company    : 
-- Created    : 2017-10-17
-- Last update: 2017-10-17
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: Counts teeth and calculates lenght of 'gap' to determine which tooth is
--    present in terms of entire cycle (tooth 1 = tooth following gap)
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

entity gap_synchronizer is
  generic (
    TEETH       : integer := 60-2;  --teeth on wheel 
    WIDTH       : integer := 8;      --width of x,y
    GAP_FACTOR  : integer := 4
  );
  port (
    clk_125M    : in  std_logic;
    rst         : in  std_logic;
    x           : in std_logic_vector(WIDTH - 1 downto 0);
    y           : in std_logic_vector(WIDTH - 1 downto 0);
    x_valid     : in std_logic;
    y_valid     : in std_logic;
    --pulse_train : in std_logic;
    tooth_count : in std_logic_vector(integer(ceil(log2(TEETH)))- 1 downto 0);
    gap_sync    : out std_logic;
    gap_present : out std_logic
  );
end gap_synchronizer;

architecture Behavioral of gap_synchronizer is
  --FSM Type and Signal
  type STATE_TYPE is (start, calc_g, pre_sync, sync, post_sync, verify);
  signal state : STATE_TYPE := start;
  
  --Constants
  constant GAP_FACTOR_ADD_WIDTH : integer := integer(ceil(log2(GAP_FACTOR))); --Multiplication by GAP_FACTOR adds additional bits to g
  constant TOOTH_CNT_WIDTH           : integer := integer(ceil(log2(TEETH)));
  constant TOOTH_CNT_MAX             : unsigned(TOOTH_CNT_WIDTH - 1 downto 0) := to_unsigned(TEETH, TOOTH_CNT_WIDTH);
  --constant TEETH_WIDTH : integer := integer(ceil(log2(TEETH))); --Width to hold teeth in tooth counter
  
  --Internal Signals------------------------------------------------------------
  --gap
  signal g        : unsigned(WIDTH + GAP_FACTOR_ADD_WIDTH - 1 downto 0); 
  signal g_minus  : unsigned(WIDTH + GAP_FACTOR_ADD_WIDTH - 1 downto 0); --Lower bounds of tolerance for gap width
  signal g_plus   : unsigned(WIDTH + GAP_FACTOR_ADD_WIDTH - 1 downto 0); --Upper bound of tolerance for gap width 
  --x & y registers
  signal x_q      : unsigned(WIDTH - 1 downto 0);  --Internal registered value of x
  signal y_q      : unsigned(WIDTH + GAP_FACTOR_ADD_WIDTH - 1 downto 0);  --Internal registered value of y
  --signal x_e      : std_logic;  --x register load signal
  --signal y_e      : std_logic;  --y register load signal
  --tooth counter
  signal tooth_count_inc    : std_logic;
  signal tooth_count_rst    : std_logic;
  signal tooth_count_toggle : std_logic;
  signal tooth_count_q        : unsigned(TOOTH_CNT_WIDTH - 1 downto 0);
  
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
  
  --Toggled tooth Counter--------------------------------------------------------------- 
  TOOTH_CNT: process(clk_125M)
  begin
  if rising_edge(clk_125M) then             --Makes process synchronous
      if (rst = '1'or tooth_count_rst = '1') then                     --Always check clr
        tooth_count_q <= (others => '0'); --1?
      elsif (pulse_train = '1' and tooth_count_toggle = '0') then
        tooth_count_q <= tooth_count_q + 1;
        tooth_count_toggle <= '1';
      elsif (pulse_train = '0' and tooth_count_toggle = '1') then
        tooth_count_toggle <= '0';   
      end if;
    end if;      
  end process;
  tooth_count <= std_logic_vector(tooth_count_q); --Assign component output to internal count
   
  --FSM-------------------------------------------------------------------------
  --State transition process (Moore machine)
  ST : process(clk_125M)
  begin
    if rising_edge(clk_125M) then
      if rst = '1' then
        state <= start;
      else
        case state is
          when start =>           --Reset has started system over
            if x_valid = '1' then
              state <= calc_g;
            end if;
          when calc_g =>          --Buffer state to calculate g based on x
            state <= pre_sync;
          when pre_sync =>        --Gap has not been accurately identified yet
            --if tooth_count < TEETH then  --Ensures were not stuck here forever
            if (g_minus <= y_q or y_q <= g_plus) then
              state <= sync;
            end if;
          when sync =>
            state <= post_sync;
          when post_sync =>       --Gap has been accurately identified
            if unsigned(tooth_count_q) = TOOTH_CNT_MAX then
              state <= verify;
            end if;
          when verify =>          --Check to ensure we are still synced
            if (g_minus <= y_q or y_q <= g_plus) then
              state <= post_sync;
            else
              state <= pre_sync;
            end if;
         end case;
       end if;
     end if;
  end process;
  
  --FSM Combinational Assignment Process
  SL : process(state)
  begin
    --default outputs;
    tooth_count_inc <= '0';
    tooth_count_rst <= '0';
    case state is
      when pre_sync =>
        
    end case;
  end process;
  
  --Combinational Calculations for gap
  g <= x_q * to_unsigned(GAP_FACTOR, GAP_FACTOR_ADD_WIDTH);
  --g_plus <= g * to_unsigned(1.05, GAP_FACTOR_ADD_WIDTH); --Dynamic tolerance would be preferred
  --g_minus <= g * to_unsigned(0.95, GAP_FACTOR_ADD_WIDTH); 
  g_plus <= g + 5; -- (+/-)5  = (+/-)2.08% @ 1000rpm, (+/-)10.41% @ 5000rpm 
  g_minus <= g - 5;
  
end Behavioral;