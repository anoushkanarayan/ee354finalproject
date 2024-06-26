`timescale 1ns / 1ps

module block_controller(
	input clk, //this clock must be a slow enough clock to view the changing positions of the objects
	input bright,
	input rst,
	input up, input down, input left, input right, input state,
	input [9:0] hCount, vCount,
	output reg [11:0] rgb,
	output reg [11:0] background,
	//output reg [15:0] score,
	output reg paddle_on,
	output reg [9:0] xpos, ypos
   );
	wire block_fill;
	
	//these two values dictate the center of the block, incrementing and decrementing them leads the block to move in certain directions
	reg [9:0] xpos, ypos; // position of center of the block. We will also have a block type thing
	
	parameter RED   = 12'b1111_0000_0000;
	
	/*when outputting the rgb value in an always block like this, make sure to include the if(~bright) statement, as this ensures the monitor 
	will output some data to every pixel and not just the images you are trying to display*/
	always@ (*) begin
    	if(~bright ) begin	//force black if not inside the display area
			rgb = 12'b0000_0000_0000;
			paddle_on = 0;
		end
		else if (block_fill) begin
			rgb = RED; 
			paddle_on = 1;
		end else begin	
			rgb=background;
			paddle_on = 0;
		end
	end
		//the +-5 for the positions give the dimension of the block (i.e. it will be 10x10 pixels)
	assign block_fill=vCount>=(ypos-5) && vCount<=(ypos+5) && hCount>=(xpos-25) && hCount<=(xpos+25); // dimensions of the block, we will want to make it smaller. 
	// we would want the block to be +-3??
	
	always@(posedge clk, posedge rst) 
	begin
		if(rst || (state == 0))
		begin 
			//rough values for center of screen
			xpos<=450;
			ypos<=500;
			// score = 15'd0;
		end
		else if (clk) begin
		
		/* Note that the top left of the screen does NOT correlate to vCount=0 and hCount=0. The display_controller.v file has the 
			synchronizing pulses for both the horizontal sync and the vertical sync begin at vcount=0 and hcount=0. Recall that after 
			the length of the pulse, there is also a short period called the back porch before the display area begins. So effectively, 
			the top left corner corresponds to (hcount,vcount)~(144,35). Which means with a 640x480 resolution, the bottom right corner 
			corresponds to ~(783,515).  
		*/
			if(right) begin
				xpos<=xpos+2; //change the amount you increment to make the speed faster 
				if(xpos==800) //these are rough values to attempt looping around, you can fine-tune them to make it more accurate- refer to the block comment above
					begin
					xpos<=xpos;
					// score = score + 16'd1;
					end
			end
			else if(left) begin
				xpos<=xpos-2;
				if(xpos==150)
					begin
					xpos<=xpos;
					// score = score + 16'd1; // if we hit the boundary should increment the counter, we'll see how this works?
					end 
			end
			// else if(up) begin
			// 	ypos<=ypos-2;
			// 	if(ypos==34)
			// 		ypos<=514;
			// end
			// else if(down) begin
			// 	ypos<=ypos+2;
			// 	if(ypos==514)
			// 		ypos<=34;
			// end
		end
	end
	
	//the background color reflects the most recent button press
	always@(posedge clk, posedge rst) begin
		if(rst || (state == 0))
			background <= 12'b1111_1111_1111;
		else 
			if(right)
				background <= 12'b1100_1111_1100;
			else if(left)
				background <= 12'b0000_1111_1111;
			// else if(down)
			// 	background <= 12'b0000_1111_0000;
			// else if(up)
			// 	background <= 12'b0000_0000_1111;
	end

	
	
endmodule
