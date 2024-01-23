/*
	A rate dividor which slows down the clock signal by an interval, i.e,
	the rate dividor ticks (i.e, flips from 1 to 0, 0 to 1, etc.) 
	when the clock signal ellapsed for a certain interval amount.

	When reset_n = 1, it resets the rate dividor.
	The reducedClk is the slowed down clock signal.
	When en = 1 and reset_n = 0, it will output a slower clock signal.
 */
module RateDivider(
	input [27:0] interval,
	input reset,
	input en,
	input clk,
	output reg reducedClk);

	reg [27:0] curTime;

	always @(posedge clk)
	begin
		if (reset == 1'b1)
		begin
			curTime <= interval;
			reducedClk <= 1'b0;
		end
		else if (en == 1'b1)
		begin
			if (curTime == 27'd1) // Prevent going to negative #s
			begin
				curTime <= interval;
				reducedClk <= ~reducedClk;
			end
			else
			begin
				curTime <= curTime - 1'b1;
			end
		end
	end
endmodule