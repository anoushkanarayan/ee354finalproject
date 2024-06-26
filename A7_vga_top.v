`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    12:18:00 12/14/2017 
// Design Name: 
// Module Name:    vga_top 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
// Date: 04/04/2020
// Author: Yue (Julien) Niu
// Description: Port from NEXYS3 to NEXYS4
//////////////////////////////////////////////////////////////////////////////////
module vga_top(
	input ClkPort,
	input BtnC,
	input BtnU,
	input BtnR,
	input BtnL,
	input BtnD,
	//VGA signal
	output hSync, vSync,
	output [3:0] vgaR, vgaG, vgaB,
	
	//SSG signal 
	output An0, An1, An2, An3, An4, An5, An6, An7,
	output Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp,
	
	//output MemOE, MemWR, RamCS,
	output  QuadSpiFlashCS
	);
	wire Reset;
	assign Reset=BtnC;
	wire bright;
	wire block_on; // changed block_on and color_blocks
	wire ball_on;
	wire paddle_on;
	wire [1:0] lives;
	wire [9:0] paddle_xpos, paddle_ypos;
	wire [11:0] color_blocks;
	wire [11:0] ball_pixel;
	wire[9:0] hc, vc;
	wire[15:0] score;
	wire [6:0] ssdOut; // change here. added this
	wire up,down,left,right;
	wire [7:0] anode;
	wire [11:0] rgb;
	wire rst;
	wire [55:0] visible;
	wire [55:0] visible_out;
	wire state;
	
	// reg [3:0]	SSD;
	// wire [3:0]	SSD3, SSD2, SSD1, SSD0;
	// reg [7:0]  	SSD_CATHODES;
	// wire [1:0] 	ssdscan_clk;
	
	reg [27:0]	DIV_CLK;
	always @ (posedge ClkPort, posedge Reset)  
	begin : CLOCK_DIVIDER
      if (Reset)
			DIV_CLK <= 0;
	  else
			DIV_CLK <= DIV_CLK + 1'b1;
	end
	wire move_clk;
	assign move_clk=DIV_CLK[19]; //slower clock to drive the movement of objects on the vga screen
	wire [11:0] background;
	display_controller dc(.clk(ClkPort), .hSync(hSync), .vSync(vSync), .bright(bright), .hCount(hc), .vCount(vc));
	block_controller sc(.clk(move_clk), .bright(bright), .rst(BtnC), .up(BtnU), .down(BtnD),.left(BtnL),.right(BtnR),.state(state),.hCount(hc), .vCount(vc), .rgb(rgb), .background(background), .paddle_on(paddle_on), .xpos(paddle_xpos), .ypos(paddle_ypos));
	counter cnt(.clk(ClkPort), .displayNumber(score), .displayScore(lives), .anode(anode), .ssdOut(ssdOut)); // added this
	breakout_blocks bb(.clk(ClkPort), .rst(BtnC), .hCount(hc), .vCount(vc), .visible_out(visible_out), .state(state), .block_on(block_on), .color(color_blocks), .visible(visible)); // for breakout_blocks
	// ball_mechanics bm(.clk(ClkPort), .hCount(hc), .vCount(vc), .ball_pixel(ball_pixel), .ball_on(ball_on));
	ball_movement ballm(.clk(ClkPort), .rst(BtnC), .hCount(hc), .vCount(vc), .paddle_on(paddle_on), .paddle_xpos(paddle_xpos), .paddle_ypos(paddle_ypos), .visible(visible), .ball_pixel(ball_pixel), .ball_on(ball_on), .lives(lives), .visible_out(visible_out), .score(score), .state(state));

	//assign rgb = block_on ? color_blocks : background;
	
	/*if(block_on)
        assign vgaR = color_blocks[11 : 8];
        assign vgaG = color_blocks[7  : 4];
        assign vgaB = color_blocks[3  : 0];
	else*/
        // assign vgaR = block_on ? color_blocks[11:8] : rgb[11 : 8];
        // assign vgaG = block_on ? color_blocks[7:4] : rgb[7  : 4];
        // assign vgaB = block_on ? color_blocks[3:0] : rgb[3  : 0];
	// disable mamory ports
	//assign {MemOE, MemWR, RamCS, QuadSpiFlashCS} = 4'b1111;

	assign vgaR = ball_on ? ball_pixel[11:8] :
              (block_on ? color_blocks[11:8] : rgb[11:8]);

	assign vgaG = ball_on ? ball_pixel[7:4] :
				(block_on ? color_blocks[7:4] : rgb[7:4]);

	assign vgaB = ball_on ? ball_pixel[3:0] :
				(block_on ? color_blocks[3:0] : rgb[3:0]);



	assign QuadSpiFlashCS = 1'b1;
	
	//------------
// SSD (Seven Segment Display)
	// reg [3:0]	SSD;
	// wire [3:0]	SSD3, SSD2, SSD1, SSD0;
	
	//SSDs display 
	//to show how we can interface our "game" module with the SSD's, we output the 12-bit rgb background value to the SSD's
	// assign SSD3 = 4'b0000;
	// assign SSD2 = background[11:8];
	// assign SSD1 = background[7:4];
	// assign SSD0 = background[3:0];
	// commented the above out in new changes
	assign {Ca, Cb, Cc, Cd, Ce, Cf, Cg} = ssdOut[6 : 0]; // added these two lines assigning ssdOut and the anodes
	assign {An7, An6, An5, An4, An3, An2, An1, An0} = {4'b1111, anode};


	// need a scan clk for the seven segment display 
	
	// 100 MHz / 2^18 = 381.5 cycles/sec ==> frequency of DIV_CLK[17]
	// 100 MHz / 2^19 = 190.7 cycles/sec ==> frequency of DIV_CLK[18]
	// 100 MHz / 2^20 =  95.4 cycles/sec ==> frequency of DIV_CLK[19]
	
	// 381.5 cycles/sec (2.62 ms per digit) [which means all 4 digits are lit once every 10.5 ms (reciprocal of 95.4 cycles/sec)] works well.
	
	//                  --|  |--|  |--|  |--|  |--|  |--|  |--|  |--|  |   
    //                    |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  | 
	//  DIV_CLK[17]       |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|
	//
	//               -----|     |-----|     |-----|     |-----|     |
    //                    |  0  |  1  |  0  |  1  |     |     |     |     
	//  DIV_CLK[18]       |_____|     |_____|     |_____|     |_____|
	//
	//         -----------|           |-----------|           |
    //                    |  0     0  |  1     1  |           |           
	//  DIV_CLK[19]       |___________|           |___________|
	//

	// assign ssdscan_clk = DIV_CLK[19:18];
	// assign An0	= !(~(ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 00
	// assign An1	= !(~(ssdscan_clk[1]) &&  (ssdscan_clk[0]));  // when ssdscan_clk = 01
	// assign An2	=  !((ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 10
	// assign An3	=  !((ssdscan_clk[1]) &&  (ssdscan_clk[0]));  // when ssdscan_clk = 11
	// // Turn off another 4 anodes
	// assign {An7, An6, An5, An4} = 4'b1111;
	
	// always @ (ssdscan_clk, SSD0, SSD1, SSD2, SSD3)
	// begin : SSD_SCAN_OUT
	// 	case (ssdscan_clk) 
	// 			  2'b00: SSD = SSD0;
	// 			  2'b01: SSD = SSD1;
	// 			  2'b10: SSD = SSD2;
	// 			  2'b11: SSD = SSD3;
	// 	endcase 
	// end

	// // Following is Hex-to-SSD conversion
	// always @ (SSD) 
	// begin : HEX_TO_SSD
	// 	case (SSD) // in this solution file the dot points are made to glow by making Dp = 0
	// 	    //                                                                abcdefg,Dp
	// 		4'b0000: SSD_CATHODES = 8'b00000010; // 0
	// 		4'b0001: SSD_CATHODES = 8'b10011110; // 1
	// 		4'b0010: SSD_CATHODES = 8'b00100100; // 2
	// 		4'b0011: SSD_CATHODES = 8'b00001100; // 3
	// 		4'b0100: SSD_CATHODES = 8'b10011000; // 4
	// 		4'b0101: SSD_CATHODES = 8'b01001000; // 5
	// 		4'b0110: SSD_CATHODES = 8'b01000000; // 6
	// 		4'b0111: SSD_CATHODES = 8'b00011110; // 7
	// 		4'b1000: SSD_CATHODES = 8'b00000000; // 8
	// 		4'b1001: SSD_CATHODES = 8'b00001000; // 9
	// 		4'b1010: SSD_CATHODES = 8'b00010000; // A
	// 		4'b1011: SSD_CATHODES = 8'b11000000; // B
	// 		4'b1100: SSD_CATHODES = 8'b01100010; // C
	// 		4'b1101: SSD_CATHODES = 8'b10000100; // D
	// 		4'b1110: SSD_CATHODES = 8'b01100000; // E
	// 		4'b1111: SSD_CATHODES = 8'b01110000; // F    
	// 		default: SSD_CATHODES = 8'bXXXXXXXX; // default is not needed as we covered all cases
	// 	endcase
	// end	
	
	// // reg [7:0]  SSD_CATHODES;
	// assign {Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp} = {SSD_CATHODES};

endmodule
