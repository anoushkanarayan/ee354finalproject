`timescale 1ns / 1ps

module breakout_blocks(
    input clk,
    input rst, 
    input [9:0] hCount, // Horizontal pixel count from the display_controller
    input [9:0] vCount, // Vertical pixel count from the display_controller
    input [55:0] visible_out,
    input state,
    output reg block_on, // Output to indicate whether we're on a block pixel
    output reg [11:0] color, // Output color based on block state
    output reg [55:0] visible
    );

    // Parameters for block size and positioning
    parameter block_width = 40;
    parameter block_height = 20;
    parameter num_blocks_x = 14;
    parameter num_blocks_y = 4; // Adjusted to fill top third of the screen
    parameter block_spacing = 5; // Spacing between blocks
    parameter start_x = 152; // X position to start drawing blocks
    parameter start_y = 150; // Y position to start drawing blocks

    // Colors for the blocks
    parameter BLACK = 12'b0000_0000_0000;
    parameter WHITE = 12'b1111_1111_1111;
    parameter RED   = 12'b1111_0000_0000;
    parameter GREEN = 12'b0000_1111_0000;

    // Calculate the end positions dynamically based on start and number of blocks
    integer current_row;
    integer block_idx_x, block_idx_y, idx;
    integer end_x = start_x + num_blocks_x * (block_width + block_spacing) - block_spacing;
    integer end_y = start_y + num_blocks_y * (block_height + block_spacing) - block_spacing;

    initial begin
        visible = 56'b11111111111111111111111111111111111111111111111111111111; // All blocks are visible initially
    end

    // Generate signal for block visibility and assign color
    always @(posedge clk) begin
        if(rst || (state == 0))
		begin 
			//rough values for center of screen
            visible = 56'b11111111111111111111111111111111111111111111111111111111;
            // lives = 9;
            // right = 2;
			// xpos<=450;
			// ypos<=514;
            // down = 1;
			// score = 15'd0;
		end
        if (clk) begin
        block_on <= 0;
        color <= BLACK;
        visible <= visible_out;

        if ((hCount >= start_x && hCount < end_x) && (vCount >= start_y && vCount < end_y)) begin
            // Calculate the current row and column
            current_row = (vCount - start_y) / (block_height + block_spacing);
            //integer current_col = (hCount - start_x) / (block_width + block_spacing);

            block_idx_x = (hCount - start_x) / (block_width + block_spacing);
            block_idx_y = (vCount - start_y) / (block_height + block_spacing);
            idx = block_idx_y * num_blocks_x + block_idx_x;

            // Check if the current pixel is within a block (excluding spacing)
            if (((hCount - start_x) % (block_width + block_spacing)) < block_width &&
                ((vCount - start_y) % (block_height + block_spacing)) < block_height && visible[idx] /*&& visible_out[idx]*/) begin
                block_on <= 1;
                // Assign color alternately for each row
                if (current_row % 2 == 0) color <= RED;
                else color = GREEN;
                end
        end
    end
    end

endmodule