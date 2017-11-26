------------------------------------------------------------------------------
-- Title      : txt file Look-up-table
-- Project    : ECU
-------------------------------------------------------------------------------
-- File       : txt_lut.vhd
-- Author     : Chris Taylor
-- Company    : Oakland University
-- Last update: 2017-11-25
-- Platform   : 
-------------------------------------------------------------------------------
-- Description: lookup table for txt file
-------------------------------------------------------------------------------
-- Notes:
--  Architecture works on win7, 64, vivado 2016.2
--  Removed additional 'functions', made for 1 txt file function
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2017/25/12  1.1      Chris		 Created
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

library UNISIM;
use UNISIM.VComponents.all;

use std.textio.all;
use ieee.std_logic_textio.all;

-- Assumption: LUT_val has 256 positions of 8 bits.
entity txt_LUT is
	generic (
		NI					: INTEGER	:= 8;  --Input width
		NO					: INTEGER	:= 12; --Output width
		FILE_NAME		: STRING -- file where the numerical values are stored
	);
	port (
		LUT_in: in std_logic_vector (NI-1 downto 0);
		LUT_out: out std_logic_vector (NO-1 downto 0)
	);
end txt_LUT;

architecture rtl of txt_LUT is

	constant START_POINTER : INTEGER := 1;
	type chunk is array (2**NI -1 downto 0) of std_logic_vector (NO-1 downto 0);
	
	impure function ReadfromFile (FileName: in string; P: in integer) return chunk is
		FILE IN_FILE  : text open read_mode is FileName; -- VHDL 93 declaration
		variable BUFF : line;
		variable val  : chunk;
	
		begin
		
		if P /= 1 then 
			for j in 1 to P-1 loop
				readline (IN_FILE, BUFF); -- It positions the pointer to where we should start
			end loop;
		end if;
			
		for i in 0 to 2**NI - 1 loop
			readline (IN_FILE, BUFF);
			read (BUFF, val(i));
		end loop;

		return val;
	end function;	
	
	constant LUT_val: chunk:= ReadFromFile(FILE_NAME, START_POINTER); -- binary values

	begin
	
	LUT_out <= LUT_val(to_integer(unsigned(LUT_in)));

end rtl;