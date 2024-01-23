module PacMan(
		sw,
		key,
		LEDR,
		clk,
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,					//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[7:0]
		VGA_G,	 						//	VGA Green[7:0]
		VGA_B);
	
	input [3:0] key;
	input [9:0] sw;
	output [9:0] LEDR;
	input clk;

	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;			//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[7:0]	VGA_R;   				//	VGA Red[7:0]
	output	[7:0]	VGA_G;	 				//	VGA Green[7:0]
	output	[7:0]	VGA_B;   				//	VGA Blue[7:0]

	wire reset;
	assign reset = sw[9];

	wire en;
	assign en = sw[8];

	wire [2:0] color;
	wire [7:0] x;
	wire [7:0] y;
	wire plot;

	// Import VGA

		vga_adapter VGA(
			.resetn(~reset),
			.clock(clk),
			.color(color),
			.x(x),
			.y(y[6:0]),
			.plot(plot),
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
			
	defparam VGA.RESOLUTION = "160x120";
	defparam VGA.MONOCHROME = "FALSE";
	defparam VGA.BITS_PER_COLOR_CHANNEL = 1;
	
	// Note: Background did not work in demo
	defparam VGA.BACKGROUND_IMAGE = "Background.mif"; // Custom background 

	wire slowClk;
	
	RateDivider div(
		.interval(27'd300),
		.reset(reset),
		.en(1'b1),
		.clk(clk),
		.reducedClk(slowClk)
		);
			
	MainModule main_module(
		.moveUp(~key[1]),
		.moveDown(~key[2]),
		.moveLeft(~key[3]),
		.moveRight(~key[0]),
		.clk(clk),
		.slowClk(slowClk),
		.reset(reset),
		.vgaColor(color),
		.vga_x(x),
		.vga_y(y),
		.vgaPlot(plot),
		.debugLEDs(LEDR));

endmodule

module MainModule(
	input moveUp,
	input moveDown,
	input moveLeft,
	input moveRight,
	input clk,
	input slowClk,
	input reset,
	output [2:0] vgaColor,
	output [7:0] vga_x,
	output [7:0] vga_y,
	output vgaPlot,
	output [9:0] debugLEDs);

		
	localparam
				TRY_EAT 				= 6'd0,
				EAT_WAIT 			= 6'd1,
				EAT 					= 6'd2,
				GET_TARGET			= 6'd3,
				GET_MAP				= 6'd4,
				WAIT					= 6'd5,
				SET_POS				= 6'd6,

				START_DISP			= 6'd23,
				VIEW_DISP			= 6'd24,
				STOP_DISP			= 6'd25,
				
				END_GAME				= 6'd26;
	
	// The coordinates of character (it is 9 bit so that it can do signed operations)
	reg [8:0] pacman_vga_x; 
	reg [8:0] pacman_vga_y; 
	
	// The pins that go to the map
	reg [4:0] map_x;
	reg [4:0] map_y;
	reg [2:0] spriteIn;
	wire [2:0] spriteOut;
	reg mapRW; //0 for read, 1 for write
	
	// The directions of character
	reg [1:0] pacman_dx; 
	reg [1:0] pacman_dy; 

	// The target x and y coordinates for a character (it is 9 bit so that it can do signed operations)
	reg [8:0] target_x;
	reg [8:0] target_y;
	
	reg [4:0] charMap_x;
	reg [4:0] charMap_y;
	
	reg isHit;
	
	reg resetDisp;
	reg startDisp = 1'b0;
	reg finishedDisp = 1'b0;
	reg [27:0] counter = 28'd0;
	wire isDispRunning;
	wire [4:0] dispMap_x, dispMap_y;

	// The current state in FSM
	reg [5:0] curState;
	
	assign debugLEDs[5:0] = curState;
	
	initial begin
		map_x = 1'b0;
		map_y = 1'b0;
		spriteIn = 3'b000;

		pacman_vga_x = 9'd10;
		pacman_vga_y = 9'd5;

		curState = GET_TARGET;
		target_x = 9'd0;
		target_y = 9'd0;
		isHit = 1'b0;

		resetDisp = 1'b1;
	end

	always @(posedge slowClk, posedge reset) 
	begin
		if (reset == 1'b1) begin
			spriteIn <= 3'b000;

			pacman_vga_x <= 9'd10;
			pacman_vga_y <= 9'd5;

			pacman_dx <= 2'd0;
			pacman_dy <= 2'd0;

			curState <= GET_TARGET;
			target_x <= 9'd0;
			target_y <= 9'd0;
			isHit <= 1'b0;
		end
		
		else begin
			case (curState)
				TRY_EAT:
				begin
					charMap_x <= pacman_vga_x / 9'd5;
					charMap_y <= pacman_vga_y / 9'd5;
					mapRW <= 1'b0;
					curState <= EAT_WAIT;
				end
					
				EAT_WAIT: curState <= EAT;
				
				EAT:
				begin
					case (spriteOut)
					3'b001: // Blue or gray tile
					begin
						spriteIn <= 3'b000;
						mapRW <= 1'b1;
					end
					
					3'b010: // Blue or gray tile
					begin	
						spriteIn <= 3'b000;
						mapRW <= 1'b1;					
					end	
					
					endcase
					curState <= GET_TARGET; 
				end
					
				GET_TARGET:
				begin
					curState <= GET_MAP;
					if(moveUp)
						pacman_dy <= 2'b10;
					else if(moveDown)
						pacman_dy <= 2'b01;
					else if(moveLeft)
						pacman_dx <= 2'b10;
					else if(moveRight)
						pacman_dx <= 2'b01;
					else
					begin
						pacman_dx <= 2'b00;
						pacman_dy <= 2'b00;
					end
						
					case (pacman_dx)
						2'b01: target_x <= pacman_vga_x + 9'd1;	
						2'b10: target_x <= pacman_vga_x - 9'd1;	
						default: target_x <= pacman_vga_x;	
					endcase
					
					case (pacman_dy)
						2'b01: target_y <= pacman_vga_y + 9'd1;
						2'b10: target_y <= pacman_vga_y - 9'd1;
						default: target_y <= pacman_vga_y;
					endcase	
				end
				
				GET_MAP:
				begin
					case(pacman_dx)
						2'b01: charMap_x <= (target_x + 9'd4) / 9'd5;
						default: charMap_x <= target_x / 9'd5;
					endcase
					case(pacman_dy)
						2'b01: charMap_y <= (target_y + 9'd4)/ 9'd5;
						default: charMap_y <= target_y / 9'd5;
					endcase
					
					mapRW <= 1'b0;
					curState <= WAIT;				
				end
				
				WAIT:
				begin
					curState <= SET_POS;
				end

				SET_POS:
				begin
					curState <= START_DISP;
					case (spriteOut)
						3'b011: // Blue tile
						begin
							pacman_vga_x <= pacman_vga_x;
							pacman_vga_y <= pacman_vga_y;
							pacman_dx <= 2'd0;
							pacman_dy <= 2'd0;
						end
						
						3'b100: // Grey tile
						begin
							pacman_vga_x <= pacman_vga_x;
							pacman_vga_y <= pacman_vga_y;
							pacman_dx <= 2'd0;
							pacman_dy <= 2'd0;
						end
						
						default: // A black tile
						begin
							pacman_vga_x <= target_x;
							pacman_vga_y <= target_y;
						end
					endcase
				end

				START_DISP:
				begin
					resetDisp <= 1'b0;
					startDisp <= 1'b1;
					counter <= 28'd0;
					curState <= VIEW_DISP;
				end
				
				VIEW_DISP:
				begin
					resetDisp <= 1'b0;
					
					if (startDisp == 1'b1) begin
						counter <= counter + 28'd1;
						startDisp <= 1'b0;
						curState <= VIEW_DISP;
					end
					else if (startDisp == 1'b0 && counter <= 28'd11300) begin
						counter <= counter + 28'd1;
						curState <= VIEW_DISP;
					end
					else if (startDisp == 1'b0 && counter > 28'd11300)begin
						counter <= 28'd0;
						curState <= STOP_DISP;
					end
				end
				
				STOP_DISP:
				begin
					resetDisp <= 1'b1;
					counter <= 28'd0;
					
					if (isHit == 1'b1) begin
						curState <= END_GAME;
					end
					else begin
						curState <= TRY_EAT;
					end
				end
				
				END_GAME:
				begin
					resetDisp <= 1'b1;
					counter <= 28'd0;
				end
			endcase			
		end
	end
	
	always @(*)
	begin
		if (curState == VIEW_DISP) begin
			map_x = dispMap_x;
			map_y = dispMap_y;
		end
		else begin
			map_x = charMap_x;
			map_y = charMap_y;
		end
	end
		
	// The map, containing map data
	MapController map(
		.map_x(map_x),
		.map_y(map_y),
		.spriteIn(spriteIn),
		.spriteOut(spriteOut),
		.readWrite(mapRW),
		.clk(clk));

	DisplayController dispController(
		.en(1'b1),
		.map_x(dispMap_x),
		.map_y(dispMap_y),
		.spriteType(spriteOut),
		
		.pacOrient(moveLeft),		
		.pacman_vga_x(pacman_vga_x[7:0]),
		.pacman_vga_y(pacman_vga_y[7:0]),
		
		.vgaPlot(vgaPlot),
		.vga_x(vga_x),
		.vga_y(vga_y),
		.vgaColor(vgaColor),
		.reset(resetDisp || reset),
		.clk(clk),
		.isDispRunning(isDispRunning));

endmodule
