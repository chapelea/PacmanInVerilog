module MapDisplayController(
	input en, 
	output reg unsigned [4:0] map_x, 
	output reg unsigned [4:0] map_y, 
	input [2:0] spriteType, 
	output reg vgaPlot, 
	output unsigned [7:0] vga_x,
	output unsigned [7:0] vga_y,
	output reg [2:0] vgaColor,
	input reset, 
	input clk,
	output [7:0] debugLEDs);
	
	reg unsigned [2:0] curSprite_x;
	reg unsigned [2:0] curSprite_y;
	
	initial 
	begin
		map_x = 5'd0;
		map_y = 5'd0;
		curSprite_x = 3'd0;
		curSprite_y = 3'd0;
		vgaPlot = 1'b0;
		vgaColor = 3'd0;
	end 

	always @(posedge clk) 
	begin
		if (reset == 1'b1) 
		begin
			map_x <= 5'd0;
			map_y <= 5'd0;
			curSprite_x <= 3'd0;
			curSprite_y <= 3'd0;	
			vgaPlot <= 1'b1;
		end
		
		else
		begin
			// If we are currently drawing the sprite
			if (curSprite_y != 3'd4 || curSprite_x != 3'd4)
			begin			
				if(curSprite_x < 3'd4)
					curSprite_x <= curSprite_x + 3'd1;
					
				else //if (curSprite_x == 3'd4)
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
				
				// Reset the current sprite coordinates
				if (map_x == 5'd20)
				begin
					map_x <= 5'd0;											
					
					if (map_y == 5'd20)
					begin
						map_y <= 5'd0;
					end
					else
					begin
						map_y <= map_y + 5'd1;
					end
				end
				else 
				begin
					map_x <= map_x + 5'd1;					
				end	
			end		
		end
	end	

	// Determine the absolute pixel coordinates on the screen
	assign vga_x = ({3'b000, map_x} * 8'd5) + {5'd0, curSprite_x} + 8'd26;
	assign vga_y = ({3'b000, map_y} * 8'd5) + {5'd0, curSprite_y} + 8'd1;

	// Determining the sprite
	reg [4:0] row0;
	reg [4:0] row1;
	reg [4:0] row2;
	reg [4:0] row3;
	reg [4:0] row4;

	reg [2:0] spriteColor;

	always @(*)
	begin
		if (spriteType == 3'b000) // A black tile
		begin
			row0 = 5'b00000;
			row1 = 5'b00000;
			row2 = 5'b00000;
			row3 = 5'b00000;
			row4 = 5'b00000;

			spriteColor = 3'b000;
		end
		else if (spriteType == 3'b001) // A big orb
		begin
			row0 = 5'b00000;
			row1 = 5'b00100;
			row2 = 5'b01110;
			row3 = 5'b00100;
			row4 = 5'b00000;

			spriteColor = 3'b111;
		end
		else if (spriteType == 3'b010) // A small orb
		begin
			row0 = 5'b00000;
			row1 = 5'b00000;
			row2 = 5'b00100;
			row3 = 5'b00000;
			row4 = 5'b00000;
			spriteColor = 3'b111;
		end
		else if (spriteType == 3'b011) // A blue tile
		begin
			row0 = 5'b11111;
			row1 = 5'b11111;
			row2 = 5'b11111;
			row3 = 5'b11111;
			row4 = 5'b11111;

			spriteColor = 3'b001;
		end
		else if (spriteType == 3'b100) // A grey tile
		begin
			row0 = 5'b11111;
			row1 = 5'b11111;
			row2 = 5'b11111;
			row3 = 5'b11111;
			row4 = 5'b11111;

			spriteColor = 3'b010;
		end
		else
		begin
			row0 = 5'b11111;
			row1 = 5'b11111;
			row2 = 5'b11111;
			row3 = 5'b11111;
			row4 = 5'b11111;

			spriteColor = 3'b010;
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
		case (selColor)
			1'b1: vgaColor = spriteColor;
			1'b0: vgaColor = 3'b000;
		endcase
	end
endmodule
