
module DisplayController(
	input en, 
	output [4:0] map_x, 
	output [4:0] map_y, 
	input [2:0] spriteType, 
	
	input pacOrient,
	input [7:0] pacman_vga_x,
	input [7:0] pacman_vga_y,
	
	output reg vgaPlot, 
	output reg [7:0] vga_x,
	output reg [7:0] vga_y,
	output reg [2:0] vgaColor,
	
	input reset, 
	input clk,
	output reg isDispRunning);
	
	// A clock, used to determine which display controller to use.
	reg unsigned selDispCont;
	reg unsigned [14:0] curTime;
	
	// Determines what the character controller is currently displaying
	wire [2:0] charType;
	reg unsigned [7:0] x_out, y_out;
	
	initial
	begin
		selDispCont = 1'b0;
		curTime = 15'd0;
		x_out = 8'd0;
		y_out = 8'd0;
	end

	always @(posedge clk)
	begin
		if (reset == 1'b1) begin
			curTime = 15'd0;
			selDispCont = 1'b0;
			isDispRunning <= 1'b0;
		end
		
		else begin
			if (curTime < 15'd11025)
			begin
				isDispRunning <= 1'b1;
				curTime <= curTime + 15'd1;
				selDispCont <= 1'b0;
			end
			else if (curTime >= 15'd11025 && curTime <= 15'd11125)
			begin
				isDispRunning <= 1'b1;
				curTime <= curTime + 15'd1;
				selDispCont <= 1'b1;
			end
			else 
			begin
				isDispRunning <= 1'b0;
				curTime <= 15'd0;
				selDispCont <= 1'b0;    			
			end
		end		
	end
	
	// A mux used to control which character to select
	always @(*)
	begin
		case (charType)
			// Pacman
			3'd0: begin 
				x_out = pacman_vga_x;
				y_out = pacman_vga_y;
			end
		endcase
	end

	// The VGA output pins from the various controllers.
	wire [7:0] vga_x_cdc;
	wire [7:0] vga_y_cdc;
	wire [7:0] vga_x_mdc;
	wire [7:0] vga_y_mdc;
	wire [2:0] vgaColor_cdc;
	wire [2:0] vgaColor_mdc;
	wire vgaPlot_cdc;
	wire vgaPlot_mdc;

	CharacterDisplayController charDispContr(
		.en(en),
		.pacOrient(pacOrient),
		.charType(charType),
		.char_x(x_out),
		.char_y(y_out),
		.vgaPlot(vgaPlot_cdc),
		.vga_x(vga_x_cdc),
		.vga_y(vga_y_cdc),
		.vgaColor(vgaColor_cdc),
		.reset(reset),
		.clk(clk)
	);

	MapDisplayController mapDispContr(
		.en(en), 
		.map_x(map_x), 
		.map_y(map_y), 
		.spriteType(spriteType), 
		.vgaPlot(vgaPlot_mdc), 
		.vga_x(vga_x_mdc), 
		.vga_y(vga_y_mdc), 
		.vgaColor(vgaColor_mdc),
		.reset(reset), 
		.clk(clk), 
		.debugLEDs(debugLEDs)
	);
	
	// The mux, used to select which vga pins to use
	always @(*)
	begin		
		if (selDispCont == 1'b0)
		begin
			vga_x = vga_x_mdc;
			vga_y = vga_y_mdc;
			vgaColor = vgaColor_mdc;
			vgaPlot = vgaPlot_mdc;	
		end
		else 
		begin
			vga_x = vga_x_cdc;
			vga_y = vga_y_cdc;
			vgaColor = vgaColor_cdc;
			vgaPlot = vgaPlot_cdc;	
		end
	end

endmodule