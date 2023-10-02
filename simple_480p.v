module simple_480p(
	input clk,
	output o_hsync,
	output o_vsync,
	output [3:0] o_red,
	output [3:0] o_blue,
	output [3:0] o_green
);

	reg [9:0] counter_x = 0;
	reg [9:0] counter_y = 0;
	reg [3:0] r_red = 0;
	reg [3:0] r_blue = 0;
	reg [3:0] r_green = 0;
	
	reg reset = 0;
	
	
	//CLOCK DIVIDER////////////////////////////////////////////////////////
	wire clk25MHz;
	clkdivider fiftytotwentyfive(
	.areset(reset),
	.inclk0(clk),
	.c0(clk25MHz),
	.locked()
	);
	
	//H and V sync
	reg hsync,vsync,de;
	always@* begin
        hsync = ~(counter_x >= 655 && counter_x < 751);  // invert: negative polarity
        vsync = ~(counter_y >= 489 && counter_y < 491);  // invert: negative polarity
        de = (counter_x <= 639 && counter_y <= 479);
   end
	
	assign o_hsync = hsync;
	assign o_vsync = vsync;
	
	//Horizontal and Vertical counter
	always @(posedge clk25MHz) begin
        if (counter_x == 799) begin  // last pixel on line?
            counter_x <= 0;
            counter_y <= (counter_y == 524) ? 0 : counter_y + 1;  // last line on screen?
        end else begin
            counter_x <= counter_x + 1;
        end
        if (reset) begin
            counter_x <= 0;
            counter_y <= 0;
        end
    end
	 
	//Color output assignments
	assign o_red = display_r;
	assign o_blue = display_g;
	assign o_green = display_b;
	
	/////////////////////////////Square Code//////////////////////////////////////////////////////////
	
	localparam H_RES = 640;  // horizontal screen resolution
	localparam V_RES = 480;  // vertical screen resolution
	
	reg frame;  // high for one clock tick at the start of vertical blanking
	always @*
	begin
		frame = (counter_y == V_RES && counter_x == 0);
	end
	
	
	
	// frame (buffer) counter lets us to slow down the action
	localparam FRAME_NUM = 1;  // slow-mo: animate every N frames, default value 1 means no slow down
	reg [$clog2(FRAME_NUM):0] cnt_frame;  // frame counter, $clog2 gives ceiling of log_2
	always @(posedge clk25MHz) begin
		if (frame) 									// if at end of vsync and start of hsync
			begin
				cnt_frame <= (cnt_frame == FRAME_NUM-1) ? 0 : cnt_frame + 1;	//if condition set cnt_frame to 0 otherwise increment by 1
			end
	end
	
	//Square Parameters
	localparam Q_SIZE = 100;   // size in pixels
	reg [9:0] qx, qy;  			// position (origin at top left)
	reg qdx, qdy;           	// direction: qdx=0 right, qdy=0 down
	reg [9:0] qs = 2;  			// speed in pixels/frame
	
	// update square position once per frame
	always @(posedge clk25MHz) 
	begin
		if (frame && cnt_frame == 0) begin		//beginning of frame and frame counter (updates every start of frame and frame counter)
        // horizontal position
		  
        if (qdx == 0) begin  									// moving right because at edge of left side
            if (qx + Q_SIZE + qs >= H_RES-1) begin  	// If hitting right side of screen
                qx <= H_RES - Q_SIZE - 1;  				// move right as far as we can
                qdx <= 1;  									// start moving left next frame
            end else qx <= qx + qs;  						// else continue moving right
        end else begin  										// else if moving left
            if (qx < qs) begin  								// if hitting left side of screen
                qx <= 0;  										// move left as far as we can
                qdx <= 0;  									// move right next frame
            end else qx <= qx - qs;  						// else continue moving left
        end

        // vertical position
        if (qdy == 0) begin  									// moving down because at top of screen
            if (qy + Q_SIZE + qs >= V_RES-1) begin  	// if hitting bottom screen
                qy <= V_RES - Q_SIZE - 1;  				// move down as far as we can
                qdy <= 1;  									// move up next frame
            end else qy <= qy + qs;  						// else continue moving down
        end else begin  										// else if moving up
            if (qy < qs) begin  								// if hitting top of screen
                qy <= 0;  										// move up as far as we can
                qdy <= 0;  									// move down next frame
            end else qy <= qy - qs;  						// else continue moving up
        end
    end
		
	end
	
	
	
	//Pattern Generation
	 reg square;
    always @* begin
        square = (counter_x >= qx) && (counter_x < qx + Q_SIZE) && (counter_y >= qy) && (counter_y < qy + Q_SIZE);
    end
	 
	 reg [3:0] paint_r, paint_g, paint_b;
	 always @* begin
		paint_r = (square) ? 4'h0 : 4'hF;
		paint_g = (square) ? 4'h0 : 4'hF;
		paint_b = (square) ? 4'h0 : 4'hF;
	 end
	 
	 reg [3:0] display_r, display_g, display_b;
    always @* begin
        display_r = (de) ? paint_r : 4'h0;
        display_g = (de) ? paint_g : 4'h0;
        display_b = (de) ? paint_b : 4'h0;
    end
		
	
	
		
endmodule
	