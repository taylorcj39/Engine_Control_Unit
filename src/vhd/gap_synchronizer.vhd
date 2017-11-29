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
-- Tooth count innacuracy before sync does not matter. Tooth count is only used after sync
-------------------------------------------------------------------------------
-- Revisions  :
-- Date			    Version	  Author    Description
-- 2017-10-17   1.0       CT        Created
-- 2017-11-13   1.1       CT        Moving tooth counter inside here, making gap factor real number
-- 2017-11-20   1.2       CT        Made generic GAP_FACTOR of u[8 4] FX
-- 2017-11-22   1.21      CT        Fixed bugs with tooth counter and gap verification
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

entity gap_synchronizer is
  generic (
    TEETH         : integer := 60-2;  --teeth on wheel 
    WIDTH         : integer := 8;      --width of x,y
    EXTRA_WIDTH   : integer := 16;
    GAP_FACTOR    : unsigned(8 - 1 downto 0) := "01010100"  --5.25 in u[8 4] format
  );
  port (
    clk_125M        : in std_logic;
    rst             : in std_logic;
    x               : in unsigned(WIDTH - 1 downto 0);
    y               : in unsigned(EXTRA_WIDTH - 1 downto 0);
    x_valid         : in std_logic;
    y_valid         : in std_logic;
    tooth_count     : in unsigned(integer(ceil(log2(real(TEETH))))- 1 downto 0);
    tooth_count_rst : out std_logic;
    sync            : out std_logic;
    gap_present     : out std_logic
  );
end gap_synchronizer;

architecture rtl of gap_synchronizer is
  --FSM Type and Signal
  type STATE_TYPE is (start, calc_g, reset_sync, pre_sync, sync_state, post_sync, verify);
  signal state : STATE_TYPE := start;
  
  --Constants
  constant TOOTH_CNT_WIDTH  : integer := integer(ceil(log2(real(TEETH))));
  constant TOOTH_CNT_MAX    : unsigned(TOOTH_CNT_WIDTH - 1 downto 0) := to_unsigned(TEETH, TOOTH_CNT_WIDTH);
 
  --Internal Signals------------------------------------------------------------
  --gap
  signal g        : unsigned(EXTRA_WIDTH - 1 downto 0) := (others => '0'); 
  signal g_minus  : unsigned(EXTRA_WIDTH - 1 downto 0) := (others => '0'); --Lower bounds of tolerance for gap width
  signal g_plus   : unsigned(EXTRA_WIDTH - 1 downto 0) := (others => '0'); --Upper bound of tolerance for gap width 
  --x & y registers
  signal x_q      : unsigned(WIDTH - 1 downto 0)  := (others => '0');  --Internal registered value of x
  signal y_q      : unsigned(EXTRA_WIDTH - 1 downto 0) := (others => '0');  --Internal registered value of y

  begin
  
  --Registers-------------------------------------------------------------------
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
    
  Y_REG : process(clk_125M)
  begin
    if rising_edge(clk_125M) then
      if rst = '1' then
        y_q <= (others => '0');
      elsif (y_valid = '1') then
        y_q <= y;
      end if;
    end if;
  end process;
  
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
            --state <= reset_sync;
            state <= pre_sync;
          when reset_sync =>     --State which sets tooth count back to 1
            state <= pre_sync;
          when pre_sync =>        --Gap has not been accurately identified yet
            --if tooth_count < TEETH then  --Ensures were not stuck here forever
            if (g_minus <= y_q and y_q <= g_plus) then
              state <= sync_state;
            end if;
          when sync_state =>
            state <= post_sync;
          when post_sync =>       --Gap has been accurately identified
            if tooth_count = TOOTH_CNT_MAX then
              state <= verify;
            end if;
          when verify =>          --Check to ensure we are still synced (Currently resets tooth counter (tooth = 0 when in gap)
            if (g_minus <= y_q and y_q <= g_plus) then --Compare y value to gap calculated value
              state <= post_sync;
            elsif x_valid = '1' then  --New tooth has come in and gap never matched, start over
              state <= reset_sync;
            end if;
         end case;
       end if;
     end if;
  end process;
  
  --FSM Combinational Assignment Process
  SL : process(state)
  begin
    --default outputs;
    --tooth_count_inc <= '0';
    tooth_count_rst <= '0';
    sync <= '0';
    gap_present <= '0';
    case state is
      when reset_sync =>        --reset tooth counter, try to resync
        tooth_count_rst <= '1';   
      when sync_state =>        --System is in sync
        sync <= '1';
        tooth_count_rst <= '1';
      when post_sync =>
        sync <= '1';
      when verify =>             --Gap should be present, check
        tooth_count_rst <= '1';
        sync <= '1';
        gap_present <= '1';
      when others =>
        null;
    end case;
  end process;
  
  --Combinational Calculations for gap
  g <= (x_q * GAP_FACTOR)/16; 
  g_plus <= g + 5; -- (+/-)5  = (+/-)2.08% @ 1000rpm, (+/-)10.41% @ 5000rpm 
  g_minus <= g - 5;
  --Dynamic gap tolerance would be nice (multiplication, not +/-)
    
end rtl;