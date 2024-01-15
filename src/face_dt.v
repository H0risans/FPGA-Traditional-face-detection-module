	module face_dt
	#(
		parameter COL = 1280,
		parameter ROW = 720
	)
	(
		input rst_n,
		
		input video_pclk,
		input video_valid,
		input [15:0]video_data,
		
		output out_pclk,
		output reg out_valid,
		output reg [15:0]out_data
	);
	
	wire [7:0]	Cb2;
	wire [7:0]	Cr2;
	wire o_v_sync;
	wire o_data_en;
	
	reg [7:0]face_data;
	reg face_valid;
	
	assign out_pclk = video_pclk;
	
	rgb_to_ycbcr u_rgb_to_ycbcr //delay 3 clk
	(
		.clk						(video_pclk		),
        .rst_n                      (rst_n          ),
		.rgb565   					(video_data		),
		.i_v_sync          			(				),
		.i_data_en         			(video_valid	),
		.i_h_sync          			(				),
	
		.o_h_sync          			(				),
		.o_y_8b   					(				),
		.o_cb_8b					(Cb2			),
		.o_cr_8b					(Cr2			),
		.o_v_sync          			(o_v_sync		),
		.o_data_en         			(o_data_en		)
	);
	
	always @(posedge video_pclk or negedge rst_n) begin
		if(!rst_n) begin
			face_data <= 'h0;
		end
		else if( (Cb2 > 77) && (Cb2 < 127) && (Cr2 > 133) && (Cr2 < 173) ) begin
			face_data <= 8'b1111_1111;
		end
		else begin
			face_data <= 'h0;
		end
	end
	
	always @(posedge video_pclk or negedge rst_n) begin
		if(!rst_n) begin
			face_valid <= 'd0;
		end
		else begin
			face_valid <= o_data_en;
		end
	end
	
	wire f_de;
	wire f_data;
	
	filter
	#(
		.COL(COL),
		.ROW(ROW)
	)u_filter
	(
		.rst_n			(rst_n		),

		.in_data_clk    (video_pclk	),
		.in_data_de     (face_valid	),
		.in_data   	(face_data	),

		.out_data_de    (f_de		),
		.out_data       (f_data		)
		
	);
	
	//坐标计算
	reg [15:0] col_cnt;
	reg [15:0] row_cnt;
	reg	switch_flag;
	
	always @(posedge video_pclk or negedge rst_n) begin
		if(rst_n == 1'b0)
			col_cnt             <=          16'd0;
		else if(col_cnt == COL-1 && f_de == 1'b1)
			col_cnt             <=          16'd0;
		else if(f_de == 1'b1)
			col_cnt             <=          col_cnt + 1'b1;
		else
			col_cnt             <=          col_cnt;
	end
	
	always @(posedge video_pclk or negedge rst_n) begin
		if(rst_n == 1'b0)
			row_cnt             <=          16'd0;
		else if(row_cnt == ROW-1 && col_cnt == COL-1 && f_de == 1'b1)
			row_cnt             <=          16'd0;
		else if(col_cnt == COL-1 && f_de == 1'b1) 
			row_cnt             <=          row_cnt + 1'b1;
		else
			row_cnt             <=          row_cnt;
	end
	
	always @(posedge video_pclk or negedge rst_n) begin
		if(rst_n == 1'b0)
			switch_flag <= 1'b0;
		else if(col_cnt == COL/2 - 1 && f_de == 1'b1)
			switch_flag <= 1'b1;
		else if(col_cnt == COL - 1 && f_de == 1'b1)
			switch_flag <= 1'b0;
		else
			switch_flag <= switch_flag;
	end
	
	//计算最大边框
	reg [15:0] 	l_up_reg	;	  
	reg [15:0] 	l_down_reg 	;
	reg [15:0] 	l_left_reg 	;
	reg [15:0] 	l_right_reg	;
	
	reg [15:0] 	r_up_reg	;	  
	reg [15:0] 	r_down_reg 	;
	reg [15:0] 	r_left_reg 	;
	reg [15:0] 	r_right_reg	;
	
	reg			flag_reg 	;
	
	always@(posedge video_pclk or negedge rst_n) begin
		if(!rst_n) begin
			l_up_reg	<= ROW		;
			l_down_reg  <= 16'd0	;
			l_left_reg  <= COL/2 - 1;
			l_right_reg <= 16'd0	;
			
			r_up_reg	<= ROW		;
			r_down_reg  <= 16'd0	;
			r_left_reg  <= COL		;
			r_right_reg <= COL/2	;
			
			flag_reg  <= 1'b0;
		end
		else if(row_cnt == ROW-1 && col_cnt == COL-1 && f_de == 1'b1)begin
			l_up_reg    <= ROW		;
			l_down_reg  <= 16'd0	;
			l_left_reg  <= COL/2 - 1;
			l_right_reg <= 16'd0	;
			
			r_up_reg	<= ROW		;
			r_down_reg  <= 16'd0	;
			r_left_reg  <= COL		;
			r_right_reg <= COL/2	;
			
			flag_reg  <= 1'b0;
		end
		else if(f_de & f_data & !switch_flag) begin
			flag_reg  <= 1'b1;
			
			if(col_cnt < l_left_reg) 
				l_left_reg <= col_cnt;		//左边界
			else
				l_left_reg <= l_left_reg;
				
			if(col_cnt > l_right_reg) 
				l_right_reg <= col_cnt;		//右边界
			else
				l_right_reg <= l_right_reg;
				
			if(row_cnt < l_up_reg) 
				l_up_reg <= row_cnt;		//上边界
			else
				l_up_reg <= l_up_reg;
				
			if(row_cnt > l_down_reg) 
				l_down_reg <= row_cnt;		//下边界
			else
				l_down_reg <= l_down_reg;	
		end
		else if(f_de & f_data & switch_flag) begin
			flag_reg  <= 1'b1;
			
			if(col_cnt < r_left_reg) 
				r_left_reg <= col_cnt;		//左边界
			else
				r_left_reg <= r_left_reg;
				
			if(col_cnt > r_right_reg) 
				r_right_reg <= col_cnt;		//右边界
			else
				r_right_reg <= r_right_reg;
				
			if(row_cnt < r_up_reg) 
				r_up_reg <= row_cnt;		//上边界
			else
				r_up_reg <= r_up_reg;
				
			if(row_cnt > r_down_reg) 
				r_down_reg <= row_cnt;		//下边界
			else
				r_down_reg <= r_down_reg;	
		end
	end
	
	reg [15:0] 	l_rectangular_up	;
	reg [15:0] 	l_rectangular_down 	;
	reg [15:0] 	l_rectangular_left 	;
	reg [15:0] 	l_rectangular_right	;
	
	reg [15:0] 	r_rectangular_up	;
	reg [15:0] 	r_rectangular_down 	;
	reg [15:0] 	r_rectangular_left 	;
	reg [15:0] 	r_rectangular_right	;	
	
	reg			rectangular_flag ;
	
	always@(posedge video_pclk or negedge rst_n) begin
		if(!rst_n) begin
			l_rectangular_up	<= 16'd0;
			l_rectangular_down  <= 16'd0;
			l_rectangular_left  <= 16'd0;
			l_rectangular_right <= 16'd0;
			
			r_rectangular_up	<= 16'd0;
			r_rectangular_down  <= 16'd0;
			r_rectangular_left  <= 16'd0;
			r_rectangular_right <= 16'd0;
			
			rectangular_flag  <= 1'b0;
		end
		else if((col_cnt == COL - 1) && (row_cnt == ROW - 1))begin
			l_rectangular_up	<= l_up_reg		;		
			l_rectangular_down  <= l_down_reg 	;
			l_rectangular_left  <= l_left_reg 	;		
			l_rectangular_right <= l_right_reg	;
			
			r_rectangular_up	<= r_up_reg		;
			r_rectangular_down  <= r_down_reg 	;
			r_rectangular_left  <= r_left_reg 	;
			r_rectangular_right <= r_right_reg	;

			rectangular_flag  <= flag_reg ;
		end
	end
	
	//*****************************************************
	//绘制矩形框
	
	//计算摄像头输入图像的像素坐标
	reg [15:0] x_cnt;
	reg [15:0] y_cnt;
	reg in_switch_flag;
	
	always @(posedge video_pclk or negedge rst_n) begin
		if(rst_n == 1'b0)
			in_switch_flag <= 1'b0;
		else if(x_cnt == COL/2 - 1 && video_valid == 1'b1)
			in_switch_flag <= 1'b1;
		else if(x_cnt == COL - 1 && video_valid == 1'b1)
			in_switch_flag <= 1'b0;
		else
			in_switch_flag <= in_switch_flag;
	end
	
	always @(posedge video_pclk or negedge rst_n) begin
		if(rst_n == 1'b0)
			x_cnt             <=          16'd0;
		else if(x_cnt == COL-1 && video_valid == 1'b1)
			x_cnt             <=          16'd0;
		else if(video_valid == 1'b1)
			x_cnt             <=          x_cnt + 1'b1;
		else
			x_cnt             <=          x_cnt;
	end
	
	always @(posedge video_pclk or negedge rst_n) begin
		if(rst_n == 1'b0)
			y_cnt             <=          16'd0;
		else if(y_cnt == ROW-1 && x_cnt == COL-1 && video_valid == 1'b1)
			y_cnt             <=          16'd0;
		else if(x_cnt == COL-1 && video_valid == 1'b1) 
			y_cnt             <=          y_cnt + 1'b1;
		else
			y_cnt             <=          y_cnt;
	end
	
	reg boarder_flag;	//标志着像素点位于方框上
	
	always@(posedge video_pclk or negedge rst_n) begin
		if(!rst_n) begin
			boarder_flag <= 1'd0;			
		end
		else begin	
			case(in_switch_flag)
				1'b0:
					begin
						if(rectangular_flag)begin
							if((x_cnt >  l_rectangular_left) && (x_cnt < l_rectangular_right)
									&& ((y_cnt == l_rectangular_up) ||(y_cnt == l_rectangular_down)) ) begin //绘制上下边界
								boarder_flag <= 1'd1;	
							end
							else if((y_cnt > l_rectangular_up) && (y_cnt < l_rectangular_down)
									&& ((x_cnt == l_rectangular_left) ||(x_cnt == l_rectangular_right)) ) begin //绘制左右边界
								boarder_flag <= 1'd1;
							end
							else begin
								boarder_flag <= 1'd0;
							end
						end
						else begin	
							boarder_flag <= 1'd0;
						end
					end
				1'b1:
					begin
							if(rectangular_flag)begin
							if((x_cnt >  r_rectangular_left) && (x_cnt < r_rectangular_right)
									&& ((y_cnt == r_rectangular_up) ||(y_cnt == r_rectangular_down)) ) begin //绘制上下边界
								boarder_flag <= 1'd1;	
							end
							else if((y_cnt > r_rectangular_up) && (y_cnt < r_rectangular_down)
									&& ((x_cnt == r_rectangular_left) ||(x_cnt == r_rectangular_right)) ) begin //绘制左右边界
								boarder_flag <= 1'd1;
							end
							else begin
								boarder_flag <= 1'd0;
							end
						end
						else begin	
							boarder_flag <= 1'd0;
						end
					end
			endcase
		end
	end
	
	always @ (posedge video_pclk or negedge rst_n ) begin
		if(!rst_n) begin
			out_valid  <= 1'd0;
			out_data 	 <= 16'd0;
		end
		else begin
			out_valid <= video_valid;
			out_data	<= boarder_flag ? 16'b11111_000000_00000 : video_data;
		end
	end
		
	endmodule