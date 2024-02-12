module tb_rx_block();

	wire CLK;
	wire RST_N;
	wire END_SIM='0;
	wire STROBE;
	wire [7:0] DATA = 8'b_01010011;
	wire TX;
	reg NEW_DATA='0;
	
	clk_gen CG(.END_SIM(END_SIM), .CLK(CLK), .RST_N(RST_N));
	
	tx_block DUT(.TX(TX), .DATA(DATA), .STROBE(STROBE), .NEW_DATA(NEW_DATA), .RST_N(RST_N), .CLK(CLK));


	integer tm=0;
	always @ (posedge CLK)
	begin
		tm=tm+1;
		if(tm==10 || tm==120)
			NEW_DATA='1;
		if(tm==20)
			NEW_DATA='0;
		
	end
endmodule
