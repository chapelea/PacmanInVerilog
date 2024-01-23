/*
	A controller used to read/write map data.
	When readWrite = 0, it is at read mode, and data at (x, y) is being outputted to data_out.
	When readWrite = 1, it is at write mode, and the data inputted in data_in gets saved at (x, y)
	When reset_n = 1, it will reset the map to default values; else it will not.
	The input pins (x, y) represents the x and y coordinates
 */
module MapController(
	input [4:0] map_x,
	input [4:0] map_y,
	input [2:0] spriteIn,
	output [2:0] spriteOut,
	input readWrite,
	input clk);

	wire [8:0] extMap_x = {3'b000, map_x};

	wire [8:0] extMap_y = {3'b000, map_y};


	wire [8:0] clientAddr;
	assign clientAddr = (9'd21 * extMap_y) + extMap_x;

	Map map(
		.address(clientAddr),
		.clock(clk),
		.data(spriteIn),
		.wren(readWrite),
		.q(spriteOut)
		);

endmodule
