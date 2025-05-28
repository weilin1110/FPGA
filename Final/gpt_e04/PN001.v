// 2023 FPGA
// FIANL : Polish Notation(PN)
module PN(
    input clk,
    input rst_n,
    input [1:0] mode,
    input operator,
    input [2:0] in,
    input in_valid,
    output reg out_valid,
    output reg signed [31:0] out
);

//================================================================
//   PARAMETER/INTEGER
//================================================================
parameter IDLE = 3'd0, RECEIVE = 3'd1, CALC = 3'd2, SORT = 3'd3, OUTPUT = 3'd4;

//================================================================
//   REG/WIRE
//================================================================
reg [2:0] current_state, next_state;
reg [2:0] in_data [0:11];
reg op_flag [0:11];
reg [3:0] data_cnt;
reg [2:0] out_cnt;
reg signed [31:0] result [3:0];
reg [1:0] result_cnt;
reg [1:0] mode_reg;
reg signed [31:0] sorted_result [0:3];
reg calc_done, sort_done;
reg signed [31:0] stack [0:11];
reg signed [31:0] op1, op2;
reg [3:0] sp;
reg input_done;

integer i;

//================================================================
//   FSM state  transfer
//================================================================
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) current_state <= IDLE;
    else       current_state <= next_state;
end

always @(*) begin
    case(current_state)
        IDLE:    next_state = (in_valid && mode <= 2'd3) ? RECEIVE : IDLE;
        RECEIVE: next_state = (in_valid) ? RECEIVE : CALC;
        CALC:    next_state = (calc_done) ? ((mode_reg <= 1) ? SORT : OUTPUT) : CALC;
        SORT:    next_state = (sort_done) ? OUTPUT : SORT;
        OUTPUT:  next_state = (out_cnt == result_cnt) ? IDLE : OUTPUT;
        default: next_state = IDLE;
    endcase
end

//================================================================
//   Input + Mode Register
//================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_cnt <= 0;
        mode_reg <= 0;
        input_done <= 0;
        for(i = 0; i < 12; i = i + 1) in_data[i] <= 0;
    end
    else if (current_state == IDLE && in_valid) begin
        mode_reg <= mode;
        in_data[0] <= in;
        op_flag[0] <= operator;
        data_cnt <= 1;
        input_done <= 0;
    end
    else if (current_state == RECEIVE && in_valid) begin
        in_data[data_cnt] <= in;
        op_flag[data_cnt] <= operator;
        data_cnt <= data_cnt + 1;
    end
    else if (current_state == RECEIVE && !in_valid) begin
        input_done <= 1;
    end
    else if (current_state == IDLE) begin
        input_done <= 0;
    end
end

//================================================================
//   Calculation
//================================================================
integer idx;
integer sum;
reg calc_start;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        calc_start <= 0;
        calc_done <= 0;
        result_cnt <= 0;
        for(i = 0; i < 4; i = i + 1) result[i] <= 0;
        for(i = 0; i < 12; i = i + 1) op_flag[i] <= 0;
    end
    else if(current_state == CALC) begin
        if (!calc_start) begin
            calc_start <= 1;
            case(mode_reg)
                2'd0: begin
                    result_cnt <= data_cnt / 3;
                    for(i = 0; i < data_cnt / 3; i = i + 1) begin
                        idx = i * 3;
                        if(op_flag[idx] == 1 && op_flag[idx+1] == 0 && op_flag[idx+2] == 0) begin
                            case(in_data[idx])
                                3'd0: result[i] <= in_data[idx+1] + in_data[idx+2];
                                3'd1: result[i] <= in_data[idx+1] - in_data[idx+2];
                                3'd2: result[i] <= in_data[idx+1] * in_data[idx+2];
                                3'd3: begin
                                    sum = in_data[idx+1] + in_data[idx+2];
                                    result[i] <= (sum >= 0) ? sum : -sum;
                                end
                                default: result[i] <= 0;
                            endcase
                        end else result[i] <= 0;
                    end
                end
                2'd1: begin
                    result_cnt <= data_cnt / 3;
                    for(i = 0; i < data_cnt / 3; i = i + 1) begin
                        idx = i * 3;
                        if(op_flag[idx] == 0 && op_flag[idx+1] == 0 && op_flag[idx+2] == 1) begin
                            case(in_data[idx+2])
                                3'd0: result[i] <= in_data[idx] + in_data[idx+1];
                                3'd1: result[i] <= in_data[idx] - in_data[idx+1];
                                3'd2: result[i] <= in_data[idx] * in_data[idx+1];
                                3'd3: begin
                                    sum = in_data[idx] + in_data[idx+1];
                                    result[i] <= (sum >= 0) ? sum : -sum;
                                end
                                default: result[i] <= 0;
                            endcase
                        end else result[i] <= 0;
                    end
                end
                2'd2: begin
                    sp = 0;
                    for(i = data_cnt - 1; i >= 0; i = i - 1) begin
                        if(op_flag[i] == 0) stack[sp++] = in_data[i];
                        else if(sp >= 2) begin
                            op1 = stack[--sp];
                            op2 = stack[--sp];
                            case(in_data[i])
                                3'd0: stack[sp++] = op1 + op2;
                                3'd1: stack[sp++] = op1 - op2;
                                3'd2: stack[sp++] = op1 * op2;
                                3'd3: begin
                                    sum = op1 + op2;
                                    stack[sp++] = (sum >= 0) ? sum : -sum;
                                end
                                default: stack[sp++] = 0;
                            endcase
                        end
                    end
                    result[0] <= stack[0];
                    result_cnt <= 1;
                end
                2'd3: begin
                    sp = 0;
                    for(i = 0; i < data_cnt; i = i + 1) begin
                        if(op_flag[i] == 0) stack[sp++] = in_data[i];
                        else if(sp >= 2) begin
                            op2 = stack[--sp];
                            op1 = stack[--sp];
                            case(in_data[i])
                                3'd0: stack[sp++] = op1 + op2;
                                3'd1: stack[sp++] = op1 - op2;
                                3'd2: stack[sp++] = op1 * op2;
                                3'd3: begin
                                    sum = op1 + op2;
                                    stack[sp++] = (sum >= 0) ? sum : -sum;
                                end
                                default: stack[sp++] = 0;
                            endcase
                        end
                    end
                    result[0] <= stack[0];
                    result_cnt <= 1;
                end
            endcase
        end else calc_done <= 1;
    end
    else begin
        calc_start <= 0;
        calc_done <= 0;
    end
end

//================================================================
//   Sort
//================================================================
reg signed [31:0] t[0:3];
reg signed [31:0] a[0:3];
reg signed [31:0] b0, b1, b2;
integer round, j;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sort_done <= 0;
    end
    else if (current_state == SORT) begin
        for (i = 0; i < result_cnt; i = i + 1)
            a[i] = result[i];
        if (result_cnt == 1) sorted_result[0] <= a[0];
        else if (result_cnt == 2) begin
            if ((mode_reg == 0 && a[0] >= a[1]) || (mode_reg == 1 && a[0] <= a[1])) begin
                sorted_result[0] <= a[0]; sorted_result[1] <= a[1];
            end else begin
                sorted_result[0] <= a[1]; sorted_result[1] <= a[0];
            end
        end
        else if (result_cnt == 3) begin
            if ((mode_reg == 0 && a[0] < a[1]) || (mode_reg == 1 && a[0] > a[1])) begin
                b0 = a[1]; b1 = a[0];
            end else begin
                b0 = a[0]; b1 = a[1];
            end
            if ((mode_reg == 0 && b1 < a[2]) || (mode_reg == 1 && b1 > a[2])) begin
                b2 = b1; b1 = a[2];
            end else begin
                b2 = a[2];
            end
            if ((mode_reg == 0 && b0 < b1) || (mode_reg == 1 && b0 > b1)) begin
                sorted_result[0] <= b1; sorted_result[1] <= b0;
            end else begin
                sorted_result[0] <= b0; sorted_result[1] <= b1;
            end
            sorted_result[2] <= b2;
        end
        else if (result_cnt == 4) begin
            t[0] = a[0]; t[1] = a[1]; t[2] = a[2]; t[3] = a[3];
            for (round = 0; round < 3; round = round + 1)
                for (j = 0; j < 3 - round; j = j + 1)
                    if ((mode_reg == 0 && t[j] < t[j+1]) || (mode_reg == 1 && t[j] > t[j+1])) begin
                        t[j] ^= t[j+1]; t[j+1] ^= t[j]; t[j] ^= t[j+1];
                    end
            for (i = 0; i < 4; i = i + 1)
                sorted_result[i] <= t[i];
        end
        sort_done <= 1;
    end
    else sort_done <= 0;
end

//================================================================
//   Output
//================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out <= 0;
        out_valid <= 0;
        out_cnt <= 0;
    end
    else if (current_state == OUTPUT) begin
        if (input_done) begin
            out_valid <= 1;
            out <= (mode_reg == 2 || mode_reg == 3) ? result[0] : sorted_result[out_cnt];
            out_cnt <= out_cnt + 1;
        end else begin
            out_valid <= 0;
        end
    end
    else begin
        out <= 0;
        out_valid <= 0;
        out_cnt <= 0;
    end
end

endmodule
