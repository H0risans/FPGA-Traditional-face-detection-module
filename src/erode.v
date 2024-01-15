module erode
#(
	parameter U_COL = 1280,
	parameter U_ROW = 720
)
(
	input clk,
	input rst_n,
	
	input in_de,
	input [7:0]in_data,
	
	output out_de,
	output out_data

);

wire [7:0] erode_matrix_11 ;
wire [7:0] erode_matrix_12 ;
wire [7:0] erode_matrix_13 ;
wire [7:0] erode_matrix_21 ;
wire [7:0] erode_matrix_22 ;
wire [7:0] erode_matrix_23 ;
wire [7:0] erode_matrix_31 ;
wire [7:0] erode_matrix_32 ;
wire [7:0] erode_matrix_33 ;

reg erode_1;
reg erode_2;
reg erode_3;
reg erode;

matrix_3x3 //delay 1 clk
#(
    .COL                    (U_COL),
    .ROW                    (U_ROW)
)
matrix_3x3_erode
(
    .clk                    (clk     	 	),
    .rst_n                  (rst_n    		),
    .valid_in               (in_de  		),
    .din                    (in_data		),
    .matrix_11              (erode_matrix_11),
    .matrix_12              (erode_matrix_12),
    .matrix_13              (erode_matrix_13),
    .matrix_21              (erode_matrix_21),
    .matrix_22              (erode_matrix_22),
    .matrix_23              (erode_matrix_23),
    .matrix_31              (erode_matrix_31),
    .matrix_32              (erode_matrix_32),
    .matrix_33              (erode_matrix_33)
);

always @ (posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        erode_1 <= 'd0;
        erode_2 <= 'd0;
        erode_3 <= 'd0;
    end
    else begin
        erode_1 <= erode_matrix_11 && erode_matrix_12 && erode_matrix_13;
        erode_2 <= erode_matrix_21 && erode_matrix_22 && erode_matrix_23;
        erode_3 <= erode_matrix_31 && erode_matrix_32 && erode_matrix_33;
    end
end

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        erode <= 'd0;
    end
    else begin
        erode <= erode_1 && erode_2 && erode_3;
    end
end

assign out_data = erode ? 16'hffff : 16'h0000;

reg [2:0] diff_de_r;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        diff_de_r    <= 3'b0;
    end
    else begin  
        diff_de_r    <= {diff_de_r[1:0],    in_de};
    end
end

assign out_de    = diff_de_r[2];

endmodule