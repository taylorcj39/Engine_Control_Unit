-------------------------------------------------------------------------------
-- Title      : ECU AXI Full
-- Project    : ECU
-------------------------------------------------------------------------------
-- File       : ecu_AXI_full.vhd   
-- Author     : Chris Taylor
-- Company    : 
-- Created    : 2017-12-02
-- Last update: 2017-12-02
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: Contains ecu and supporting arch for AXI full
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

Library UNISIM;
use UNISIM.vcomponents.all;

entity ecu_AXI_full is
	generic (
    C_S_AXI_DATA_WIDTH  : integer  := 32;  -- Width of S_AXI data bus
    C_S_AXI_ADDR_WIDTH  : integer  := 6    -- Width of S_AXI address bus
  );
  port (
    --AXI
    S_AXI_ACLK    : in std_logic;                                             -- Global Clock Signal
    S_AXI_ARESETN : in std_logic;                                              -- Global Reset Signal. This Signal is Active LOW
    S_AXI_WVALID  : in std_logic;                                             -- Write valid. This signal indicates that valid write data and strobes are available.
    S_AXI_WSTRB   : in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);   -- Write strobes. This signal indicates which byte lanes hold valid data. There is one write strobe bit for each eight bitsof the write data bus.       
    S_AXI_WREADY  : in std_logic;                                             -- Write ready. This signal indicates that the slave can accept the write data.        
    S_AXI_RREADY  : in std_logic;                                              -- Read ready. This signal indicates that the master can accept the read data and response information.        
    S_AXI_RVALID  : out std_logic;                                            -- Read valid. This signal indicates that the channel is signaling the required read data.
    S_AXI_RRESP   : out std_logic_vector(1 downto 0);                          -- Read response. This signal indicates the status of the read transfer.
    S_AXI_WDATA   : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);       -- Write Data
    S_AXI_RDATA   : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);       -- Read Data           
    axi_awv_awr_flag : in std_logic;                                           -- The axi_awv_awr_flag flag marks the presence of write address valid
    axi_arv_arr_flag : in std_logic;                                          --The axi_arv_arr_flag flag marks the presence of read address valid
    --Board Level IO for ECU
    clk_125M        : in std_logic;
    rst             : in std_logic;
    pulse_train     : in std_logic;
    servo_pwm       : out std_logic;
    p_ch0           : out std_logic;
    p_ch1           : out std_logic;
    p_ch2           : out std_logic;
    p_ch3           : out std_logic                                   
  );
end entity;

architecture rtl of ecu_AXI_full is
  
  signal max_rpm  : unsigned(16 - 1 downto 0);
  signal inst_rpm : unsigned(16 - 1 downto 0);
  signal engine_rpm : unsigned(16 - 1 downto 0);
  
  signal fifo_rst : std_logic;
  
  --ECU
  --signal clk_125M       : std_logic : ='0';
  --signal rst            : std_logic;
--  signal pulse_train    : std_logic : ='0';
  signal timing_input   : signed(4 - 1 downto 0) := (others => '0');
  signal p_duty         : unsigned(8 - 1 downto 0) := (others => '0');
  --signal p_invert     :
  signal p_pulse_count  : unsigned(16 - 1 downto 0) := (others => '0');
  signal p_pwm_ch       : unsigned(3 - 1 downto 0) := (others => '0');
  signal p_angle_start  : unsigned(16 - 1 downto 0) := (others => '0');
  signal p_angle_stop   : unsigned(16 - 1 downto 0) := (others => '0');
--  signal servo_pwm      : 
--  signal p_ch0          :
--  signal p_ch1          :
--  signal p_ch2          :
--  signal p_ch3          :
  
  signal mem_wren : std_logic := '0';
  signal mem_rden : std_logic := '0';
  
  --Output (read) side
  signal ofifo_do       : std_logic_vector(32 - 1 downto 0) := (others => '0');
  signal ofifo_di       : std_logic_vector(32 - 1 downto 0) := (others => '0');
  signal ofifo_di_q     : std_logic_vector(32 - 1 downto 0) := (others => '0');
  signal ofifo_empty    : std_logic := '0';
  signal ofifo_full     : std_logic := '0';
  signal ofifo_rden     : std_logic := '0';
  signal ofifo_wren     : std_logic := '0';
  signal ofifo_wrcount  : std_logic_vector(12 - 1 downto 0)  := (others => '0');

  --Input (write) side
  signal ififo_do       : std_logic_vector(32 - 1 downto 0) := (others => '0');
  signal ififo_di       : std_logic_vector(32 - 1 downto 0) := (others => '0');
  signal ififo_di_q     : std_logic_vector(32 - 1 downto 0) := (others => '0');
  signal ififo_empty    : std_logic := '0';
  signal ififo_full     : std_logic := '0';
  signal ififo_rden     : std_logic := '0';
  signal ififo_wren     : std_logic := '0';
  signal ififo_wrcount  : std_logic_vector(12 - 1 downto 0)  := (others => '0');

  --ECU Component Decleration
  component ecu
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
      servo_pwm       : out std_logic;
      p_ch0           : out std_logic;
      p_ch1           : out std_logic;
      p_ch2           : out std_logic;
      p_ch3           : out std_logic
    );
  end component;
  
  --Fifo rst FSM
  component AXI_fifo_fsm is
    port (
      S_AXI_ACLK        : in  std_logic;
      S_AXI_ARESETN      : in  std_logic;
      S_AXI_RREADY      : in  std_logic;
      axi_arv_arr_flag  : in  std_logic;
      mem_wren          : in  std_logic;
      mem_rden          : in  std_logic;
      i_full            : in  std_logic;
      o_empty            : in  std_logic;
      S_AXI_RVALID      : out  std_logic;
      S_AXI_RRESP        : out  std_logic_vector(2 - 1 downto 0);
      o_rden            : out std_logic;
      i_wren            : out std_logic;
      fifo_rst          : out  std_logic
    );
  end component;
  
  begin
   
  ofifo_di <= std_logic_vector(inst_rpm) & std_logic_vector(max_rpm); --register both rpms as 32b word
  
  --Process for continually updating ofifo
  OFIFO_REFRESH : process(clk_125M)
  begin
    if rising_edge(clk_125M) then
      ofifo_di_q <= ofifo_di; --register input data for comparison
      if rst = '1' then
        ofifo_wren <= '0';
        ofifo_rden <= '0';
      elsif ofifo_empty = '1' then  --fifo is empty, put data on it
        ofifo_wren <= '1';
      elsif ofifo_di_q /= ofifo_di then --data at input has changed, push onto fifo
        ofifo_rden <= '1';  --pop old data off, new data will be written next clock cycle
      end if;
    end if;
  end process;
  
  --Instanaeous rpm register
  INST_LATCH : process(clk_125M)
  begin
    if rising_edge(clk_125M) then
      if rst = '1' then
        inst_rpm <= (others => '0');
      else
        inst_rpm <= engine_rpm;
      end if;
    end if;  
  end process;
  
  --Max rpm register
  MAX_REG : process(clk_125M)
  begin
    if rising_edge(clk_125M) then
      if rst = '1' then
        max_rpm <= (others => '0');
      elsif max_rpm < engine_rpm then
        max_rpm <= engine_rpm;
      end if;
    end if;
  end process;
  
  --Component Inastantiations
  
  --ECU
  ECU_COMPONENT : ecu
  port map (         
    clk_125M      => clk_125M,
    rst           => rst,
    pulse_train   => pulse_train,
    timing_input  => timing_input, --later through AXI
    --Peripheral   
    p_duty        => p_duty,
    --p_invert     
    p_pulse_count => p_pulse_count,
    p_pwm_ch      => p_pwm_ch,
    p_angle_start => p_angle_start,
    p_angle_stop  => p_angle_stop,
    --Outputs      
    servo_pwm     => servo_pwm, --GPIO outputs
    p_ch0         => p_ch0,     --GPIO outputs
    p_ch1         => p_ch1,     --GPIO outputs
    p_ch2         => p_ch2,     --GPIO outputs
    p_ch3         => p_ch3      --GPIO outputs
  );             
  
  --Input (write) side dual clock FIFO (copied from cordic exactly (12-2))
  IFIFO : FIFO18E1
  generic map (
    ALMOST_EMPTY_OFFSET     => X"0080",              -- Sets the almost empty threshold
    ALMOST_FULL_OFFSET       => X"0080",               -- Sets almost full threshold
    DATA_WIDTH               => 36,                   -- Sets data width to 4-36
    DO_REG                   => 1,                    -- Enable output register (1-0) Must be 1 if EN_SYN = FALSE
    EN_SYN                   => FALSE,                -- Specifies FIFO as dual-clock (FALSE) or Synchronous (TRUE)
    FIFO_MODE               => "FIFO18_36",             -- Sets mode to FIFO18 or FIFO18_36
    FIRST_WORD_FALL_THROUGH => TRUE,                  -- Sets the FIFO FWFT to FALSE, TRUE
    INIT                     => X"000000000",-- Initial values on output port
    SIM_DEVICE               => "7SERIES",            -- Must be set to "7SERIES" for simulation behavior
    SRVAL                   => X"000000000" -- Set/Reset value for output port
  )
  port map (
    -- Read Data: 32-bit (each) output: Read output data
    DO           => ififo_do,           -- 32-bit output: Data output
    --DOP         => DOP,         -- 4-bit output: Parity data output
    -- Status: 1-bit (each) output: Flags and other FIFO status outputs
    --ALMOSTEMPTY => ALMOSTEMPTY, -- 1-bit output: Almost empty flag
    --ALMOSTFULL   => ALMOSTFULL,  -- 1-bit output: Almost full flag
    EMPTY       => ififo_empty,       -- 1-bit output: Empty flag
    FULL        => ififo_full,        -- 1-bit output: Full flag
    --RDCOUNT     => RDCOUNT,     -- 12-bit output: Read count
    --RDERR       => RDERR,       -- 1-bit output: Read error
    WRCOUNT     => ififo_wrcount,     -- 12-bit output: Write count
    --WRERR       => WRERR,       -- 1-bit output: Write error
    -- Read Control Signals: 1-bit (each) input: Read clock, enable and reset input signals
    RDCLK       => clk_125M,       -- 1-bit input: Read clock
    RDEN        => ififo_rden,        -- 1-bit input: Read enable
    REGCE       => '1',       -- 1-bit input: Clock enable
    RST         => fifo_rst,         -- 1-bit input: Asynchronous Reset
    RSTREG      => '0',      -- 1-bit input: Output register set/reset
    -- Write Control Signals: 1-bit (each) input: Write clock and enable input signals
    WRCLK       => S_AXI_ACLK,       -- 1-bit input: Write clock
    WREN        => ififo_wren,        -- 1-bit input: Write enable
    -- Write Data: 32-bit (each) input: Write input data
    DI          => ififo_di,          -- 32-bit input: Data input
    DIP         => "0000"          -- 4-bit input: Parity input
  );
  
  -- Output FIFO IP for Instantaneous RPM
  OFIFO : FIFO18E1
    generic map (
      ALMOST_EMPTY_OFFSET     => X"0080",              -- Sets the almost empty threshold
      ALMOST_FULL_OFFSET      => X"0080",               -- Sets almost full threshold
      DATA_WIDTH              => 36,                   -- Sets data width to 36-4
      DO_REG                  => 1,                    -- Enable output register (1-0) Must be 1 if EN_SYN = FALSE
      EN_SYN                  => FALSE,                -- Specifies FIFO as dual-clock (FALSE) or Synchronous (TRUE)
      FIFO_MODE               => "FIFO18_36",             -- Sets mode to FIFO18 or FIFO18_36
      FIRST_WORD_FALL_THROUGH => TRUE,                  -- Sets the FIFO FWFT to FALSE, TRUE
      INIT                    => X"000000000",-- Initial values on output port
      SIM_DEVICE              => "7SERIES",            -- Must be set to "7SERIES" for simulation behavior
      SRVAL                   => X"000000000" -- Set/Reset value for output port
    )
    port map (
      -- Read Data: 32-bit (each) output: Read output data
      DO           => ofifo_do,           -- 32-bit output: Data output
      --DOP         => DOP,         -- 4-bit output: Parity data output
      -- Status: 1-bit (each) output: Flags and other FIFO status outputs
      --ALMOSTEMPTY => ALMOSTEMPTY, -- 1-bit output: Almost empty flag
      --ALMOSTFULL   => ALMOSTFULL,  -- 1-bit output: Almost full flag
      EMPTY       => ofifo_empty,       -- 1-bit output: Empty flag
      FULL        => ofifo_full,        -- 1-bit output: Full flag
      --RDCOUNT     => RDCOUNT,     -- 12-bit output: Read count
      --RDERR       => RDERR,       -- 1-bit output: Read error
      WRCOUNT     => ofifo_wrcount,     -- 12-bit output: Write count
      --WRERR       => WRERR,       -- 1-bit output: Write error
      -- Read Control Signals: 1-bit (each) input: Read clock, enable and reset input signals
      RDCLK       => S_AXI_ACLK,       -- 1-bit input: Read clock
      RDEN        => ofifo_rden,        -- 1-bit input: Read enable
      REGCE       => '1',       -- 1-bit input: Clock enable
      RST         => fifo_rst,         -- 1-bit input: Asynchronous Reset
      RSTREG      => '0',      -- 1-bit input: Output register set/reset
      -- Write Control Signals: 1-bit (each) input: Write clock and enable input signals
      WRCLK       => clk_125M,       -- 1-bit input: Write clock
      WREN        => ofifo_wren,        -- 1-bit input: Write enable
      -- Write Data: 32-bit (each) input: Write input data
      DI           => ofifo_di,          -- 32-bit input: Data input
      DIP         => "0000"          -- 4-bit input: Parity input
    );
  
  	--AXI FIFO FSM
    FIFO_FSM : AXI_fifo_fsm
    port map(
      S_AXI_ACLK      => S_AXI_ACLK,
      S_AXI_ARESETN   => S_AXI_ARESETN,
      S_AXI_RREADY    => S_AXI_RREADY,
      axi_arv_arr_flag  => axi_arv_arr_flag,
      --fifo_fsm_rst
      mem_wren        => mem_wren, 
      mem_rden        => mem_rden, 
      i_full          => ififo_full,  
      o_empty         => ofifo_empty,  
      S_AXI_RVALID    => S_AXI_RVALID,
      S_AXI_RRESP     => S_AXI_RRESP,
      o_rden          => ofifo_rden,  
      i_wren          => ififo_wren,  
      fifo_rst        => fifo_rst 
    );
end rtl;
