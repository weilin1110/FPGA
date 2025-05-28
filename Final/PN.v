// 2023 FPGA
// FIANL : Polish Notation(PN)
//
// -----------------------------------------------------------------------------
// ©Communication IC & Signal Processing Lab 716
// -----------------------------------------------------------------------------
// Author : HSUAN-YU LIN
// File   : PN.v
// Create : 2023-02-27 13:19:54
// Revise : 2023-02-27 13:19:54
// Editor : sublime text4, tab size (4)
// -----------------------------------------------------------------------------
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
//--FSM state difine--
parameter IDLE = 3'd0, RECEIVE = 3'd1, CALC = 3'd2, SORT = 3'd3, OUTPUT = 3'd4;

//================================================================
//   REG/WIRE
//================================================================
reg [2:0] current_state, next_state;        //狀態存取
reg [2:0] in_data [0:11];                   //輸入的資料(最多12個)
reg op_flag [0:11];                         //對應的 operator 判斷
reg [3:0] data_cnt;                         //資料計數
reg [2:0] out_cnt;                          //輸出計數
reg signed [31:0] result [3:0];             //運算結果(最多4個)
reg [1:0] result_cnt;                       //結果數量紀錄
reg [1:0] mode_reg;                         //鎖存 mode   
reg signed [31:0] sorted_result [0:3];      //排列的結果
reg calc_done, sort_done;                   //計算、排列是否完成
reg signed [31:0] stack [0:11];             //堆疊暫存
reg signed [31:0] op1, op2;                 //堆疊計算的temp
reg [3:0] sp;                               //stack pointer 堆疊指標

//================================================================
//   Design
//================================================================
// FSM state  transfer
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) current_state <= IDLE;
    else       current_state <= next_state;
end

// FSM logic
always @(*) begin
    case(current_state)
        IDLE: begin
            if(in_valid && mode <= 2'd3)
                next_state <= RECEIVE;
            else
                next_state <= IDLE;
        end
        RECEIVE: next_state = (in_valid) ? RECEIVE : CALC;
        CALC: begin
            case(mode_reg)
                2'd0, 2'd1: next_state = (calc_done) ? SORT : CALC;
                2'd2, 2'd3: next_state = (calc_done) ? OUTPUT : CALC;
                default:    next_state = IDLE;
            endcase
        end
        SORT: next_state = (sort_done) ? OUTPUT : SORT;
        OUTPUT: next_state = (out_cnt == result_cnt) ? IDLE : OUTPUT;
        default: next_state = IDLE;
    endcase
end

// mode 鎖存與資料接收
integer i;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for(i = 0; i < 12; i = i + 1) in_data[i] <= 0;
        data_cnt <= 0;
        mode_reg <= 0;
    end
    else if (current_state == IDLE && in_valid) begin
        mode_reg <= mode;
        in_data[0] <= in;
        op_flag[0] <= operator;
        data_cnt <= 1;
    end
    else if (current_state == RECEIVE && in_valid) begin
        in_data[data_cnt] <= in;
        op_flag[data_cnt] <= operator;
        data_cnt <= data_cnt + 1;
    end
    else if (current_state == CALC) begin
        data_cnt <= 0;
    end
end

// 運算邏輯
integer idx;
integer sum;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 4; i = i + 1) result[i] <= 0;
        for(i = 0; i < 4; i = i + 1) sorted_result[i] <= 0;
        for(i = 0; i < 12; i = i + 1) op_flag[i] <= 0;
        result_cnt <= 0;
        calc_done <= 0;
        sum <= 0;
        op1 <= 0;
        op2 <= 0;
    end
    else if(current_state == CALC) begin
        //結果運算
        case(mode_reg)
            // mode == 0 or 1, 資料3個一組進行計算
            2'd0: begin     //prefix 降冪
                result_cnt <= data_cnt / 3;
                for(i = 0; i < result_cnt; i = i + 1) begin
                    idx = i * 3;
                    if(op_flag[idx] == 1 && op_flag[idx+1] == 0 && op_flag[idx+2] == 0)begin
                        case(in_data[idx])
                            3'd0: result[i] <= in_data[idx+1] + in_data[idx+2];
                            3'd1: result[i] <= in_data[idx+1] - in_data[idx+2];
                            3'd2: result[i] <= in_data[idx+1] * in_data[idx+2];
                            3'd3: begin
                                sum = in_data[idx+1] + in_data[idx+2];
                                result[i] <= (sum >= 0) ? sum : - sum;
                            end
                            default: result[i] <= 0;
                        endcase
                    end
                      else result[i] <= 0;
                end
            end
            2'd1: begin     //postfix 升冪
            result_cnt <= data_cnt / 3;
                for(i = 0; i < result_cnt; i = i + 1) begin
                    idx = i * 3;
                    if(op_flag[idx] == 0 && op_flag[idx+1] == 0 && op_flag[idx+2] == 1) begin
                        case(in_data[idx+2])
                            3'd0: result[i] <= in_data[idx] + in_data[idx+1];
                            3'd1: result[i] <= in_data[idx] - in_data[idx+1];
                            3'd2: result[i] <= in_data[idx] * in_data[idx+1];
                            3'd3: begin
                                sum = in_data[idx] + in_data[idx+1];
                                result[i] <= (sum >= 0) ? sum : - sum;
                            end
                            default: result[i] <= 0;
                        endcase
                    end
                    else result[i] <= 0;
                end
            end
            // mode = 2 or 3, 利用stack堆疊來計算
            2'd2: begin     //prefix (右往左分析)
                sp = 0;
                for(i = data_cnt - 1; i >= 0; i = i - 1) begin
                    if(op_flag[i] == 0) begin
                        stack[sp] = in_data[i];
                        sp = sp + 1;
                    end
                    else if(op_flag[i] == 1 && sp >= 2)begin
                        sp = sp - 1;
                        op1 = stack[sp];
                        sp = sp - 1;
                        op2 = stack[sp];
                        case(in_data[i])
                            3'd0: stack[sp] = op1 + op2;
                            3'd1: stack[sp] = op1 - op2;
                            3'd2: stack[sp] = op1 * op2;
                            3'd3: begin
                                sum = op1 + op2;
                                stack[sp] = (sum >= 0) ? sum : -sum;
                            end
                            default: stack[sp] = 0;
                        endcase
                        sp = sp + 1;
                    end
                end
                result[0] <= stack[0];
                result_cnt <= 1;
            end
            2'd3: begin     //postfix (左往右分析)
                sp = 0;
                for(i = 0; i < data_cnt; i = i + 1) begin
                    if(op_flag[i] == 0) begin
                        stack[sp] = in_data[i];
                        sp = sp + 1;
                    end
                    else if(op_flag[i] == 1 && sp >= 2)begin
                        sp = sp - 1;
                        op2 = stack[sp];
                        sp = sp - 1;
                        op1 = stack[sp];
                        case(in_data[i])
                            3'd0: stack[sp] = op1 + op2;
                            3'd1: stack[sp] = op1 - op2;
                            3'd2: stack[sp] = op1 * op2;
                            3'd3: begin
                                sum = op1 + op2;
                                stack[sp] = (sum >= 0) ? sum : -sum;
                            end
                            default: stack[sp] = 0;
                        endcase
                        sp = sp + 1;
                    end
                end
                result[0] <= stack[0];
                result_cnt <= 1;
            end
        endcase
        end
    end
    else begin
        calc_done <= 0;
    end
end

///排序邏輯
reg signed [31:0] t[0:3];  // 用於4項排序時
reg signed [31:0] a[0:3];  // 複製 result
reg signed [31:0] b0, b1, b2;  // 3項排序時的中間變數
integer round, j;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < 4; i = i + 1) sorted_result[i] <= 0;
        sort_done <= 0;
    end
    else if (current_state == SORT) begin
        for (i = 0; i < result_cnt; i = i + 1)
            a[i] = result[i];

        if (result_cnt == 1) begin
            sorted_result[0] <= a[0];
        end
        else if (result_cnt == 2) begin
            if ((mode_reg == 2'd0 && a[0] >= a[1]) || (mode_reg == 2'd1 && a[0] <= a[1])) begin
                sorted_result[0] <= a[0];
                sorted_result[1] <= a[1];
            end else begin
                sorted_result[0] <= a[1];
                sorted_result[1] <= a[0];
            end
        end
        else if (result_cnt == 3) begin
            // 第一階段：前兩個排序
            if ((mode_reg == 2'd0 && a[0] < a[1]) || (mode_reg == 2'd1 && a[0] > a[1])) begin
                b0 = a[1]; b1 = a[0];
            end else begin
                b0 = a[0]; b1 = a[1];
            end
            // 第二階段：第三個加入
            if ((mode_reg == 2'd0 && b1 < a[2]) || (mode_reg == 2'd1 && b1 > a[2])) begin
                b2 = b1; b1 = a[2];
            end else begin
                b2 = a[2];
            end
            // 第三階段：確認 b0 和 b1 順序
            if ((mode_reg == 2'd0 && b0 < b1) || (mode_reg == 2'd1 && b0 > b1)) begin
                sorted_result[0] <= b1;
                sorted_result[1] <= b0;
            end else begin
                sorted_result[0] <= b0;
                sorted_result[1] <= b1;
            end
            sorted_result[2] <= b2;
        end
        else if (result_cnt == 4) begin
            t[0] = a[0]; t[1] = a[1]; t[2] = a[2]; t[3] = a[3];
            for (round = 0; round < 3; round = round + 1) begin
                for (j = 0; j < 3 - round; j = j + 1) begin
                    if ((mode_reg == 2'd0 && t[j] < t[j+1]) || (mode_reg == 2'd1 && t[j] > t[j+1])) begin
                        t[j]   = t[j] ^ t[j+1];
                        t[j+1] = t[j] ^ t[j+1];
                        t[j]   = t[j] ^ t[j+1];
                    end
                end
            end
            for (i = 0; i < 4; i = i + 1)
                sorted_result[i] <= t[i];
        end

        sort_done <= 1;
    end
    else begin
        sort_done <= 0;
    end
end

// 輸出控制
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out <= 0;
        out_valid <= 0;
        out_cnt <= 0;
    end
    else if(current_state == OUTPUT) begin
        out_valid <= 1;
        out <= (mode_reg == 2 || mode_reg == 3) ? result[0] : sorted_result[out_cnt];
        out_cnt <= out_cnt + 1;
    end
    else begin
        out <= 0;
        out_valid <= 0;
        out_cnt <= 0;
    end
end

endmodule
