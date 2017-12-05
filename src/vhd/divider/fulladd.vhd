---------------------------------------------------------------------------
-- This VHDL file was developed by Daniel Llamocca (2013).  It may be
-- freely copied and/or distributed at no cost.  Any persons using this
-- file for any purpose do so at their own risk, and are responsible for
-- the results of such use.  Daniel Llamocca does not guarantee that
-- this file is complete, correct, or fit for any particular purpose.
-- NO WARRANTY OF ANY KIND IS EXPRESSED OR IMPLIED.  This notice must
-- accompany any copy of this file.
--------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity fulladd is
	port( cin, x, y : in std_logic;
         s, cout   : out std_logic);
end fulladd;

architecture structure of fulladd is

begin

	s <= x xor y xor cin;
	cout <= (x and y) or (x and cin) or (y and cin);
	
end structure;