/*
	A module used to display the characters.

	When en = 1, pacOrient is specified, reset was turned from 1 to 0,
	clk is set to the 50mhz clock; vgaColor, vgaPlot, vga_x, vga_y goes to VGA adapter;
	char_x, char_y, and charType goes to the CharacterRegisters,

	It will iterate through all the characters, drawing each character one step at a time
	(one pixel is drawn per clock cycle)
 */
module CharacterDisplayController(
	input en,
	input pacOrient,
	output reg [2:0] charType,
	input unsigned [7:0] char_x,
	input unsigned [7:0] char_y,
	output reg vgaPlot,
	output [7:0] vga_x,
	output [7:0] vga_y,
	output reg [2:0] vgaColor,
	input reset,
	input clk);

	// Drawing the pixels of each character and of each of their bitmaps
	reg unsigned [2:0] curSprite_x;
	reg unsigned [2:0] curSprite_y;

	// IS REQUIRED! There is a bug in Quartus where all registers must be
	// initialized to a value regardless of clock cycle.
	initial
	begin
		charType = 3'd0;
		curSprite_x = 3'd0;
		curSprite_y = 3'd0;
	end

	always @(posedge clk)
	begin
		if (reset == 1'b1)
		begin
			charType <= 3'd0;
			curSprite_x <= 3'd0;
			curSprite_y <= 3'd0;
		end
		else //if (en == 1'b1)
		begin
			// If we are currently drawing the sprite
			if (curSprite_y != 3'd4 || curSprite_x != 3'd4)
			begin
				if(curSprite_x < 3'd4)
				begin
					curSprite_x <= curSprite_x + 3'd1;
				end

				else // if (curSprite_x == 3'd4)
				begin
					curSprite_x <= 3'd0;
					curSprite_y <= curSprite_y + 3'd1;
				end
			end

			// If we have finished drawing the sprite
			else
			begin
				curSprite_x <= 3'd0;
				curSprite_y <= 3'd0;

				if (charType == 3'd4)
				begin
					charType <= 3'd0;
				end
				else
				begin
					charType <= charType + 3'd1;
				end
			end
		end
	end

	// Determine the absolute pixel coordinates on the screen
	assign vga_x = char_x + {5'd00000, curSprite_x} + 8'd26;
	assign vga_y = char_y + {5'd00000, curSprite_y} + 8'd1;

	// Determining the bitmap of the characters
	reg [4:0] row0;
	reg [4:0] row1;
	reg [4:0] row2;
	reg [4:0] row3;
	reg [4:0] row4;

	reg [2:0] spriteColor;

	always @(*)
	begin
		if (charType == 3'b000) // Pacman
		begin
			if (pacOrient == 1'b0) // Facing left
			begin
				row0 = 5'b01110;//CHANGED LAST FROM 0 TO 1
				row1 = 5'b00111;
				row2 = 5'b00011;
				row3 = 5'b00111;
				row4 = 5'b01110;
			end
			else // Facing right
			begin
				row0 = 5'b01110;
				row1 = 5'b11100;
				row2 = 5'b11000;
				row3 = 5'b11100;
				row4 = 5'b01110;
			end

			spriteColor = 3'b110;
		end
	end

	reg [6:0] selRow;
	always @(*)
	begin
		case (curSprite_y)
			4'd0: selRow = row0;
			4'd1: selRow = row1;
			4'd2: selRow = row2;
			4'd3: selRow = row3;
			4'd4: selRow = row4;

			default: selRow = row0;
		endcase
	end

	reg selColor;
	always @(*)
	begin
		case (curSprite_x)
			4'd0: selColor = selRow[0];
			4'd1: selColor = selRow[1];
			4'd2: selColor = selRow[2];
			4'd3: selColor = selRow[3];
			4'd4: selColor = selRow[4];

			default: selColor = selRow[0];
		endcase
	end

	always @(*)
	begin
		vgaColor = spriteColor;

		if (selColor == 1'b1 && reset == 1'b0)
		begin
			vgaPlot = 1'b1;
		end
		else
		begin
			vgaPlot = 1'b0;
		end
	end

endmodule
