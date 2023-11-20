module Parking_Controller(
    input flr, power, clk,

    // inout PS2_DAT,
    // input PS2_CLK,
    
    input [7:0] key1_code, // to remove
    input key1_on, // 

    output reg [6:0] first_rem_BCD, second_rem_BCD, tot_rem_BCD_left, tot_rem_BCD_right,
    output reg red_power_led, red_wrong_led, green_led
);

reg reset, chosen_flr_full, alternative_flr_full, id_special, special_flr_chosen;
reg [5:0] state, state_N; 
wire [27:0] ID;
wire buffer_full, esc_pressed, ctrla_pressed;

reg [5:0] t;
wire key_pressed;
wire [3:0] key;
reg [1:0] flg_inp = 0;
wire id_valid;

reg [2:0] floor_zero, floor_one;

parameter OFF = 0;
parameter INITIAL = 1;
parameter NORMAL_FSM = 2;
parameter ADMIN_FSM = 3;
parameter EXIT_FSM = 4;
parameter INPUTTING = 5;

parameter CHECK_STATE_N = 0;
parameter CHECK_FLR_N = 1;
parameter INCORRECT_N = 2;
parameter GRANTED_ALT_FLR_N = 3;
parameter GRANTED_CHOSN_FLR_N = 4;
parameter NO_SPACE_N = 5;


assign id_valid = 1;

initial begin
    state = 0;
    reset = 0;
    t = 0;
    state_N = 0;
    floor_zero = 5;
    floor_one = 5;
    chosen_flr_full = 0; 
    alternative_flr_full = 0; 
    id_special = 0; 
    special_flr_chosen = 0;
end

ps2_Main keyb(
    .CLK    (clk),
    .reset   (reset),
    .PS2_CLK    (32'd0),   //
    .PS2_DAT    (32'd0),  //
    .key1_code  (key1_code),
    .key1_on    (key1_on),
    .key_pressed    (key_pressed),
    .buffer_full    (buffer_full),
    .ID   (ID),
    .key (key),
    .esc_pressed (esc_pressed),
    .ctrla_pressed (ctrla_pressed)
);

reg [32:0] counter = 0;

always @ (posedge clk) begin
    counter <= counter + 1;
    if (counter == 32'd10) begin
        counter <= 0;
        t <= t + 1;
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
            end else begin


state <= NORMAL_FSM;
if (flr == 0) begin
    if (floor_zero <= 2) begin
        chosen_flr_full <= 1;
        if (floor_one < 1) begin
            alternative_flr_full <= 1;
        end else alternative_flr_full <= 0;
    end else chosen_flr_full <= 0;
end else if (flr == 1) begin
    if (floor_one < 1) begin
        chosen_flr_full <= 1;
        if (floor_one <= 2) begin
            alternative_flr_full <= 1;
        end else alternative_flr_full <= 0;
    end else chosen_flr_full <= 0;
end

special_flr_chosen <= (flr == 0) ? 1 : 0;

case(state_N)
    CHECK_STATE_N: begin
        if (id_valid) begin
            state_N <= CHECK_FLR_N;
            if (id_special && !special_flr_chosen) begin
                state_N <= GRANTED_ALT_FLR_N;
                t <= 1;
                if (flr == 0) floor_one <= floor_one - 1;
                else floor_zero <= floor_zero - 1;
            end else if (id_special && special_flr_chosen) begin
                state_N <= GRANTED_CHOSN_FLR_N;
                t <= 1;
                if (flr == 0) floor_zero <= floor_zero - 1;
                else floor_one <= floor_one - 1;
            end
        end else begin
            state_N <= INCORRECT_N;
            t <= 1;
        end
    end
    CHECK_FLR_N: begin
        if (!chosen_flr_full) begin
            state_N <= GRANTED_CHOSN_FLR_N;
            t <= 1;
            if (flr == 0) floor_zero <= floor_zero - 1;
            else floor_one <= floor_one - 1;
        end else begin
            if (!alternative_flr_full) begin
                state_N <= GRANTED_ALT_FLR_N;
                t <= 1;
                if (flr == 0) floor_one <= floor_one - 1;
                else floor_zero <= floor_zero - 1;
            end else begin
                state_N <= NO_SPACE_N;
                t <= 1;
            end
        end
    end
    INCORRECT_N: begin
        if (t < 5) state_N <= INCORRECT_N;
        else begin
            state_N <= CHECK_STATE_N;
            state <= INITIAL;
            t <= 1;
        end
    end
    GRANTED_CHOSN_FLR_N: begin
        if (t < 3) state_N <= GRANTED_CHOSN_FLR_N;
        else begin
            state_N <= CHECK_STATE_N;
            state <= INITIAL;
            t <= 1;
        end
    end
    GRANTED_ALT_FLR_N: begin
        if (t < 3) state_N <= GRANTED_ALT_FLR_N;
        else begin
            state_N <= CHECK_STATE_N;
            state <= INITIAL;
            t <= 1;
        end
    end
    NO_SPACE_N: begin
        if (t < 3) state_N <= NO_SPACE_N;
        else begin
            state_N <= CHECK_STATE_N;
            state <= INITIAL;
            t <= 1;
        end
    end
endcase

            end
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
        end 
        INITIAL: begin
            red_power_led = 1;
            red_wrong_led = 0;
            green_led = 0;
        end 
        INPUTTING: begin
            red_wrong_led = 0;
            green_led = 1;
        end
        NORMAL_FSM: begin
            red_power_led = 1;
            red_wrong_led = 1;
            green_led = 1;
        end
        EXIT_FSM: begin
            red_power_led = 0;
            red_wrong_led = 1;
            green_led = 1;
        end
        ADMIN_FSM: begin
            red_power_led = 1;
            red_wrong_led = 1;
            green_led = 0;
        end
    endcase
end

endmodule