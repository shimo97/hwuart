module frame_gen(
input CLK,RST_N,
output TX, END_SIM
);

reg TX_i;
reg END_SIM_i;

assign END_SIM = END_SIM_i;
assign TX = TX_i;

localparam data = 24'b_11_00101101_01_11001010_0111; //data to send 
integer bit=0; //current bit
integer sample=0; //current sample instant

always @ (posedge CLK or negedge RST_N)
	begin
		if(RST_N == 0) begin
			TX_i<=data[0];
			END_SIM_i<=0'b0;
		end
		else begin
			TX_i<=data[bit];
			sample=sample+1;
			if(sample==8) begin
				sample=0;
				bit=bit+1;
				if(bit==24) begin
					END_SIM_i<=1'b1;
				end
			end
		end	
	end

endmodule

module tb_rx_block();

	wire CLK;
	wire RST_N;
	wire END_SIM;
	wire STROBE;
	wire DATA[7:0];
	wire RX;
	
	clk_gen CG(.END_SIM(END_SIM), .CLK(CLK), .RST_N(RST_N));
	
	frame_gen FG(.CLK(CLK),.RST_N(RST_N),.TX(RX),.END_SIM(END_SIM));
	
	rx_block DUT(.RX(RX), .DATA(DATA), .STROBE(STROBE), .RST_N(RST_N), .CLK(CLK));
	
	
	
endmodule
