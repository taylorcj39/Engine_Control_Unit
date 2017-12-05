---------------------------------------------------------------------------
-- This VHDL file was developed by Daniel Llamocca (2014).  It may be
-- freely copied and/or distributed at no cost.  Any persons using this
-- file for any purpose do so at their own risk, and are responsible for
-- the results of such use.  Daniel Llamocca does not guarantee that
-- this file is complete, correct, or fit for any particular purpose.
-- NO WARRANTY OF ANY KIND IS EXPRESSED OR IMPLIED.  This notice must
-- accompany any copy of this file.
--------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity unit_proc is
	port( a, b, s, cin: in std_logic;
	      r, cout: out std_logic);
end unit_proc;

architecture structure of unit_proc is

	component fulladd
		port( cin, x, y : in std_logic;
				s, cout   : out std_logic);
	end component;
	
	signal not_b: std_logic;
	signal mux_1: std_logic;
	
begin

	not_b <= not(b);
	
	f1: fulladd port map (cin => cin , x => a, y => not_b, s => mux_1, cout => cout);

	with s select
		r <= mux_1 when '1',
		     a when others;

end structure;