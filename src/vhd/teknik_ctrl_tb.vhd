library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

entity teknik_ctrl_tb is
end teknik_ctrl_tb;

architecture Behavioral of teknik_ctrl_tb is
	component teknik_ctrl
		port (
			clk_125M :	in STD_LOGIC;
			rst :		in STD_LOGIC;
			duty_cycle:	in STD_LOGIC_VECTOR (7 downto 0);
			pulse_cnt : 	in STD_LOGIC_VECTOR (15 downto 0);
			pulse_out :	out STD_LOGIC
		);
	end component;

	-- Input Signals
	signal clk_125M : 	STD_LOGIC := '0';
	signal rst : 		STD_LOGIC := '1';
	signal duty_cycle :	STD_LOGIC_VECTOR(7 downto 0) := X"00";
	signal pulse_cnt :	STD_LOGIC_VECTOR(15 downto 0) := X"0000";

	-- Output Signals
	signal pulse_out :	STD_LOGIC := '0';

	constant CLK_125M_PERIOD : time := 8ns;

	begin

	clk_125M <= not clk_125M after CLK_125M_PERIOD * 0.5;

	uut : teknik_ctrl
	port map(
		clk_125M => clk_125M,
		rst => rst,
		duty_cycle => duty_cycle,
		pulse_cnt => pulse_cnt,
		pulse_out => pulse_out
	);

	STIM : process
	begin
		wait for CLK_125M_PERIOD * 3;

		rst <= '0';
		wait for 10us;

		duty_cycle <= X"32"; -- 50% Duty Cycle
		pulse_cnt <= x"00FA"; -- 250 counts
		wait for 10us;

		duty_cycle <= X"4B"; -- 75% Duty Cycle
		pulse_cnt <= x"00FA"; -- 250 counts
		wait for 10us;

		duty_cycle <= X"32"; -- 50% Duty Cycle
		pulse_cnt <= x"04E2"; -- 1250 counts
		wait for 10us;

		duty_cycle <= X"4B"; -- 75% Duty Cycle
		pulse_cnt <= x"04E2"; -- 1250 counts
		wait for 10us;
	end process;

end Behavioral;