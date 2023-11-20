module Parking_Controller(
    input flr, power, clk,

    inout PS2_DAT,
    input PS2_CLK,
    
    //input [7:0] key1_code, // to remove
    //input key1_on, // 

    // output reg [6:0] first_rem_BCD, second_rem_BCD, tot_rem_BCD_left, tot_rem_BCD_right,
    output reg red_power_led, red_wrong_led, green_led,
    output wire buffer_full, esc_pressed, key_pressed,
    output wire LCD_RW, LCD_EN, LCD_RS,
    output wire [7:0] LCD_DATA,
    output wire [7:0] BCD0, BCD1, BCD2, BCD3, BCD4, BCD5, BCD6
    
);

reg reset;
reg [5:0] state; 
wire [27:0] ID;
reg [3:0] LCD_State;

reg [5:0] t;
wire ctrla_pressed, ctrl_pressed, a_pressed;
wire [3:0] key;
reg [1:0] flg_inp;


parameter OFF = 0;
parameter INITIAL = 1;
parameter NORMAL_FSM = 2;
parameter ADMIN_FSM = 3;
parameter EXIT_FSM = 4;
parameter INPUTTING = 5;

initial begin
    state = 0;
    reset = 0;
    t = 1;
    LCD_State = 15;
    flg_inp = 0;
end

ps2_Main keyb(
    .CLK    (clk),
    .reset   (reset),
    .PS2_CLK    (PS2_CLK),   //
    .PS2_DAT    (PS2_DAT),  //
    .key_pressed    (key_pressed),
    .buffer_full    (buffer_full),
    .ID   (ID),
    .key (key),
    .esc_pressed (esc_pressed),
    .ctrla_pressed (ctrla_pressed),
    .ctrl_pressed (ctrl_pressed),
    .a_pressed (a_pressed)
);

MAIN_LCD lcd_inst(
    .iCLK (clk), 
    .LCD_State (LCD_State),
    .ID (ID),
    .LCD_DATA (LCD_DATA),
    .LCD_RW (LCD_RW),
    .LCD_EN (LCD_EN),
    .LCD_RS (LCD_RS)
);

BDC_7SEG bcd_inst(
    .code (ID),
    .CLK (clk),
    .BCD0 (BCD0), 
    .BCD1 (BCD1), 
    .BCD2 (BCD2), 
    .BCD3 (BCD3), 
    .BCD4 (BCD4), 
    .BCD5 (BCD5), 
    .BCD6 (BCD6)
);

reg [32:0] counter = 0;

always @ (posedge clk) begin
    counter <= counter + 1;
    if (counter == 32'd49999999) begin
        t <= t + 1;
        counter <= 0;
    end
    reset <= 1;
    case(state)
        OFF: begin
            if (power) begin
                state <= INITIAL;
            end else state <= OFF;
        end
        INITIAL: begin
            t <= 1;
            flg_inp = 0;
            reset <= 0;
            if (!power) begin
                state <= OFF;
            end else if (key_pressed) begin
                if (esc_pressed) begin
                    state <= EXIT_FSM;
                end else if (ctrla_pressed) begin
                    state <= ADMIN_FSM;
                end else begin
                    state <= INPUTTING;
                end
            end
        end
        INPUTTING: begin
            reset <= 0;
            if (!power) begin
                state <= OFF;
            end else begin
                if (!buffer_full) begin
                    if (t < 5 && !key_pressed) begin
                        state <= INPUTTING;
                    end else if (key_pressed) begin
                        state <= INPUTTING;
                        t <= 1;
                    end else if (t >= 5) begin
                        state <= INITIAL;
                        t <= 1;
                        reset <= 1;
                    end
                end else begin
                    case(flg_inp)
                        0: begin
                            state <= NORMAL_FSM;
                        end
                        1: begin
                            state <= ADMIN_FSM;
                        end
                        2: begin
                            state <= EXIT_FSM;
                        end
                        default: begin
                        end
                    endcase
					t <= 1;
                end
            end
        end 
        NORMAL_FSM: begin
            reset <= 1;
            if (!power) begin
                state <= OFF;
            end else state <= NORMAL_FSM;
        end
        ADMIN_FSM: begin
            if (!power) begin
                state <= OFF;
            end else state <= ADMIN_FSM;
        end
        EXIT_FSM: begin 
            reset <= 0;
            if (!power) begin
                state <= OFF;
            end else state <= EXIT_FSM;
        end
        default: begin
            if (power) begin
                state <= INITIAL;
            end else state <= OFF;
        end
    endcase
    
end

always @ (state) begin
    case(state)
        OFF: begin
            red_power_led = 0;
            red_wrong_led = 1;
            green_led = 0;
            LCD_State = 4'd15;
        end 
        INITIAL: begin
            red_power_led = 1;
            red_wrong_led = 0;
            green_led = 0;
            LCD_State = 4'd0;
        end 
        INPUTTING: begin
            red_wrong_led = 0;
            green_led = 1;
            LCD_State = 4'd0;
        end
        NORMAL_FSM: begin
            red_power_led = 1;
            red_wrong_led = 1;
            green_led = 1;
            LCD_State = 4'd1;
        end
        EXIT_FSM: begin
            red_power_led = 0;
            red_wrong_led = 1;
            green_led = 1;
            LCD_State = 4'd3;
        end
        ADMIN_FSM: begin
            red_power_led = 1;
            red_wrong_led = 1;
            green_led = 0;
            LCD_State = 4'd4;
        end
    endcase
end

endmodule

// set_location_assignment PIN_AC17 -to first_rem_BCD[6]
// set_location_assignment PIN_AA15 -to first_rem_BCD[5]
// set_location_assignment PIN_AB15 -to first_rem_BCD[4]
// set_location_assignment PIN_AB17 -to first_rem_BCD[3]
// set_location_assignment PIN_AA16 -to first_rem_BCD[2]
// set_location_assignment PIN_AB16 -to first_rem_BCD[1]
// set_location_assignment PIN_AA17 -to first_rem_BCD[0]

// set_location_assignment PIN_AE18 -to second_rem_BCD[6]
// set_location_assignment PIN_AF19 -to second_rem_BCD[5]
// set_location_assignment PIN_AE19 -to second_rem_BCD[4]
// set_location_assignment PIN_AH21 -to second_rem_BCD[3]
// set_location_assignment PIN_AG21 -to second_rem_BCD[2]
// set_location_assignment PIN_AA19 -to second_rem_BCD[1]
// set_location_assignment PIN_AB19 -to second_rem_BCD[0]

// set_location_assignment PIN_U24 -to tot_rem_BCD_left[6]
// set_location_assignment PIN_U23 -to tot_rem_BCD_left[5]
// set_location_assignment PIN_W25 -to tot_rem_BCD_left[4]
// set_location_assignment PIN_W22 -to tot_rem_BCD_left[3]
// set_location_assignment PIN_W21 -to tot_rem_BCD_left[2]
// set_location_assignment PIN_Y22 -to tot_rem_BCD_left[1]
// set_location_assignment PIN_M24 -to tot_rem_BCD_left[0]

// set_location_assignment PIN_H22 -to tot_rem_BCD_right[6]
// set_location_assignment PIN_J22 -to tot_rem_BCD_right[5]
// set_location_assignment PIN_L25 -to tot_rem_BCD_right[4]
// set_location_assignment PIN_L26 -to tot_rem_BCD_right[3]
// set_location_assignment PIN_E17 -to tot_rem_BCD_right[2]
// set_location_assignment PIN_F22 -to tot_rem_BCD_right[1]
// set_location_assignment PIN_G18 -to tot_rem_BCD_right[0]

// set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to first_rem_BCD[6]
// set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to first_rem_BCD[5]
// set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to first_rem_BCD[4]
// set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to first_rem_BCD[3]
// set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to first_rem_BCD[2]
// set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to first_rem_BCD[1]
// set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to first_rem_BCD[0]

// set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to second_rem_BCD[6]
// set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to second_rem_BCD[5]
// set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to second_rem_BCD[4]
// set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to second_rem_BCD[3]
// set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to second_rem_BCD[2]
// set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to second_rem_BCD[1]
// set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to second_rem_BCD[0]

// set_instance_assignment -name IO_STANDARD "2.5 V" -to tot_rem_BCD_left[6]
// set_instance_assignment -name IO_STANDARD "2.5 V" -to tot_rem_BCD_left[5]
// set_instance_assignment -name IO_STANDARD "2.5 V" -to tot_rem_BCD_left[4]
// set_instance_assignment -name IO_STANDARD "2.5 V" -to tot_rem_BCD_left[3]
// set_instance_assignment -name IO_STANDARD "2.5 V" -to tot_rem_BCD_left[2]
// set_instance_assignment -name IO_STANDARD "2.5 V" -to tot_rem_BCD_left[1]
// set_instance_assignment -name IO_STANDARD "2.5 V" -to tot_rem_BCD_left[0]

// set_instance_assignment -name IO_STANDARD "2.5 V" -to tot_rem_BCD_right[6]
// set_instance_assignment -name IO_STANDARD "2.5 V" -to tot_rem_BCD_right[5]
// set_instance_assignment -name IO_STANDARD "2.5 V" -to tot_rem_BCD_right[4]
// set_instance_assignment -name IO_STANDARD "2.5 V" -to tot_rem_BCD_right[3]
// set_instance_assignment -name IO_STANDARD "2.5 V" -to tot_rem_BCD_right[2]
// set_instance_assignment -name IO_STANDARD "2.5 V" -to tot_rem_BCD_right[1]
// set_instance_assignment -name IO_STANDARD "2.5 V" -to tot_rem_BCD_right[0]