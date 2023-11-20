module MAIN_LCD(
    iCLK, LCD_State, ID,
    LCD_DATA,LCD_RW,LCD_EN,LCD_RS
);

input			iCLK;
input   [3:0]   LCD_State;
input   [27:0]  ID;
output	[7:0]	LCD_DATA;
output			LCD_RW,LCD_EN,LCD_RS;
wire clk;

reg [127:0] line1, line2;
reg [55:0] ID_string;


always @ (posedge iCLK) begin
    ID_string[55:48] <= {4'h3, ID[27:24]};
    ID_string[47:40] <= {4'h3, ID[23:20]};
    ID_string[39:32] <= {4'h3, ID[19:16]};
    ID_string[31:24] <= {4'h3, ID[15:12]};
    ID_string[23:16] <= {4'h3, ID[11:8]};
    ID_string[15:8]  <= {4'h3, ID[7:4]};
    ID_string[7:0]   <= {4'h3, ID[3:0]};

    case(LCD_State)
        4'd0: begin
				line1 <= "   Enter Your   "; 
				line2 <= "   ID to Park   ";
			end
        4'd1: begin
				line1 <= " ACCESS GRANTED ";
				line2 <= "   ID: " + ID_string + "  ";
			end
			
        4'd2: begin 
				line1 <= " ACCESS DENIED  ";
				line2 <= "   Try Again    ";
			end
        4'd3: begin 
				line1 <= "   Enter Your   "; 
				line2 <= "   ID to Exit   ";
			end
        4'd4: begin 
				line1 <= "Administrator   "; 
				line2 <= "Mode            ";
			end
        4'd15: begin 
				line1 <= "    Parking     "; 
				line2 <= "       OFF      ";
			end
        default: begin
				line1 <= "        X       ";
				line2 <= "                ";
			end
    endcase
end

LCD_CDivider inst1 (
    .clock_in (iCLK),
    .reset (0),
    .clock_out (clk)
);

LCD inst2(
    .iCLK (iCLK),
    .iRST_N (clk),
    .line1 (line1),
    .line2 (line2),
    .LCD_DATA (LCD_DATA),
    .LCD_RW (LCD_RW),
    .LCD_EN (LCD_EN),
    .LCD_RS (LCD_RS)
);

endmodule