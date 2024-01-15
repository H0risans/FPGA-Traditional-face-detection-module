module filter
#(
	parameter COL = 1280,
	parameter ROW = 720
)
(
	input rst_n,
	
	input in_data_clk,
	input in_data_de,
	input [7:0]in_data,
	
	output out_data_de,
	output out_data
	
);

wire m_de;
wire [7:0]m_data;


middle_filter
#(
	.U_COL(COL),
	.U_ROW(ROW)
)u_middle_filter
(
	.clk		(in_data_clk),
	.rst_n      (rst_n),

	.in_de      (in_data_de),
	.in_data    (in_data),

	.out_de     (m_de),
	.out_data   (m_data)
	
);

wire e_de;
wire e_data;

erode
#(
	.U_COL(COL),
	.U_ROW(ROW)
)u_erode
(
	.clk			(in_data_clk),
	.rst_n          (rst_n		),

	.in_de          (m_de		),
	.in_data   (m_data		),

	.out_de         (e_de		),
	.out_data       (e_data		)

);

assign out_data_de = e_de;
assign out_data	   = e_data;

endmodule