---------------------------------------------------------------------------
-- This VHDL file was developed by Daniel Llamocca (2013).  It may be
-- freely copied and/or distributed at no cost.  Any persons using this
-- file for any purpose do so at their own risk, and are responsible for
-- the results of such use.  Daniel Llamocca does not guarantee that
-- this file is complete, correct, or fit for any particular purpose.
-- NO WARRANTY OF ANY KIND IS EXPRESSED OR IMPLIED.  This notice must
-- accompany any copy of this file.
--------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- N-bit Parallel access Shift register:
-- DIR = "LEFT" --> Shift to the left: from LSB to MSB
-- DIR = "RIGHT" --> Shift to the right: from MSB to LSB
-- s_l = 0 --> Shift operation (MSB to LSB)
-- s_l = 1 -> Parallel load
entity my_pashiftreg is
   generic (N: INTEGER:= 4;
	         DIR: STRING:= "LEFT");
	port ( clock, resetn: in std_logic;
	       din, E, s_l: in std_logic; -- din: shiftin input
			 D: in std_logic_vector (N-1 downto 0);
	       Q: out std_logic_vector (N-1 downto 0);
          shiftout: out std_logic);
end my_pashiftreg;

architecture Behavioral of my_pashiftreg is

	signal Qt: std_logic_vector (N-1 downto 0);
	
begin

a0: assert (DIR = "LEFT" or DIR = "RIGHT")
    report "DIR can only be LEFT or RIGHT"
	 severity error;
	
	process (resetn, clock, E, s_l, din, Qt)
	begin
--		if resetn = '0' then
--			Qt <= (others => '0');
--		elsif (clock'event and clock = '1') then
    if rising_edge(clock) then
      if resetn = '0' then
        Qt <= (others => '0');  
			elsif E = '1' then	
				if s_l = '1' then
					Qt <= D;					
				else
					if DIR = "LEFT" then
						Qt(0) <= din;
						for i in 1 to N-1 loop
							Qt(i) <= Qt(i-1);
						end loop;
					elsif DIR = "RIGHT" then
						Qt(N-1) <= din;
						for i in 0 to N-2 loop
							Qt(i) <= Qt(i+1);
						end loop;
					end if;
				end if;
			end if;
		end if;
		
	end process;

	Q <= Qt;
	
	gl: if DIR = "LEFT" generate
			 shiftout <= Qt(N-1);
		 end generate;
	gr: if DIR = "RIGHT" generate
			 shiftout <= Qt(0);
		 end generate;
		
end Behavioral;

