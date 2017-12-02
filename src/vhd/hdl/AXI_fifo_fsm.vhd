-------------------------------------------------------------------------------
-- Title      : AXI ACLK FSM 
-- Project    : Lab4
-------------------------------------------------------------------------------
-- File       : AXI_aclk_fsm.vhd   
-- Author     : Chris Taylor
-- Company    : Oakland University
-- Created    : 2017-11-01
-- Last update: 2017-11-01
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: FSM for AXI Full interface which handles the FIFOs and others
-------------------------------------------------------------------------------
-- Notes:
-- 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date				Version		Author	Description
-- 2017-11-01	1.0				CT			Created
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

entity AXI_fifo_fsm is
	port (
		S_AXI_ACLK		    : in	std_logic;
		S_AXI_ARESETN	    : in	std_logic;
		S_AXI_RREADY	    : in	std_logic;
		axi_arv_arr_flag	: in	std_logic;
		mem_wren			    : in	std_logic;
		mem_rden			    : in	std_logic;
		i_full				    : in	std_logic;
		o_empty				    : in	std_logic;
		S_AXI_RVALID	    : out	std_logic;
		S_AXI_RRESP	      : out	std_logic_vector(2 - 1 downto 0);
		o_rden				    : out std_logic;
		i_wren				    : out std_logic;
		fifo_rst			    : out	std_logic
	);
end AXI_fifo_fsm;

architecture rtl of AXI_fifo_fsm is
	--FSM Types and Signal---------------------------------------------------------
	type STATE_TYPE is (state1, state2);
	signal state : STATE_TYPE := state1;
	
	--Constants & Signals------------------------------------------------------------------
	constant COUNT_MAX 		: natural := 16;
	constant COUNT_WIDTH	: natural := integer(ceil(log2(real(COUNT_MAX))));
	
	signal count				: unsigned(COUNT_WIDTH - 1 downto 0) := (others => '0');
	--signal count_q		: 	unsigned(COUNT_WIDTH - 1 downto 0) := (others => '0');
	signal count_done		: std_logic := '0';
	signal count_toggle : std_logic := '0';
	signal count_inc		: std_logic := '0';
	signal count_rst		: std_logic	:= '0';
	
	signal fifo_fsm_rstq :	std_logic := '0';
	signal fifo_fsm_rst  :	std_logic := '0';
	
	signal axi_rresp   : std_logic_vector(2 - 1 downto 0) := (others => '0');
	signal axi_rvalid  : std_logic := '0';
	
	begin
	
	--Toggled synchronous counter
	COUNTER : process(S_AXI_ACLK)
	begin
		if rising_edge(S_AXI_ACLK) then
			if S_AXI_ARESETN = '0' or count_rst = '1' then
				count <= (others => '0');
				count_toggle <= '0';
			else
				if (count_inc = '1' and count_toggle = '0') then
					count <= count + 1;
					count_toggle <= '1';
				elsif (count_inc = '0' and count_toggle = '1') then
					count_toggle <= '0';
				end if;
			end if;
		end if;
	end process;
	
	count_done <= '1' when count = to_unsigned(COUNT_MAX - 1, COUNT_WIDTH - 1) else '0';
	
	--Flip-flop for fifo_fsm_rst
	FIFO_FSM_RST_FF : process(S_AXI_ACLK)
	begin
		if rising_edge(S_AXI_ACLK) then
			if S_AXI_ARESETN = '0' then
	       fifo_fsm_rstq <= '0';
			else
				fifo_fsm_rstq <= fifo_fsm_rst;
			end if;
		end if;
	end process;
	
	fifo_rst <= not S_AXI_ARESETN or fifo_fsm_rstq;
	
	--FSM Transition Process
	TRANSITION : process(S_AXI_ACLK)
	begin
		if rising_edge(S_AXI_ACLK) then
			if S_AXI_ARESETN = '0' then
				state <= state1;
			else
				case state is
					when state1 =>
							if count_done = '1' then -- C = 15
								if o_empty = '1' then 
									state <= state2;
								end if;
							end if;				
					when state2 =>
						state <= state2;
				end case;
			end if;
		end if;
	end process;
	
	--FSM Assignments
	ASSIGNMENTS : process(state, mem_wren, mem_rden, i_full, o_empty, count_done, axi_rvalid)
	begin
		-- Initialization of signals:
		i_wren <= '0'; o_rden <= '0'; count_rst <= '0'; count_inc <= '0'; fifo_fsm_rst <= '0';
		case state is
			when state1 =>
			     if count_done = '1' then -- C = 15?
			         if o_empty = '1' then
			             count_rst <= '1';
									 --EC <= '1'; -- C<=0
			         end if;
			     else
			         fifo_fsm_rst <= '1';
			         count_inc <= '1'; -- C <= C+1
			     end if;
			when state2 =>
				if (mem_wren = '1') then
					if i_full = '0' then
						i_wren <= '1';
					end if;
				else
					if mem_rden = '1' then
						if o_empty = '0' and axi_rvalid = '1' then 
							o_rden <= '1'; 
						end if;
					end if;
				end if;
		end case;
	end process;

S_AXI_RVALID <= axi_rvalid;
S_AXI_RRESP    <= axi_rresp;

  AXI_ARVALID: process(S_AXI_ACLK)
  begin
    if rising_edge(S_AXI_ACLK) then
      if S_AXI_ARESETN = '0' then
        axi_rvalid <= '0';
        axi_rresp  <= "00";
      else
        if (axi_arv_arr_flag = '1' and axi_rvalid = '0' and o_empty='0') then -- The axi_arv_arr_flag flag marks the presence of read address valid, i.e., we are ready to read
          axi_rvalid <= '1';
          axi_rresp  <= "00"; -- 'OKAY' response
        elsif (axi_rvalid = '1' and S_AXI_RREADY = '1') then
          axi_rvalid <= '0';
        end  if;      
      end if;
    end if;
  end process;
	
end rtl;