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
parameter IDLE = 2'd0, RECEIVE = 2'd1, CALC = 2'd2, SORT = 2'd3, OUTPUT = 2'd4;

//================================================================
//   REG/WIRE
//================================================================
reg [2:0] current_state, next_state;        //狀態存取
reg [2:0] in_data [0:11];                   //輸入的資料(最多12個)
reg op_flag [0:11];                         //對應的 operator 判斷
reg [3:0] data_cnt;                         //資料計數
reg [1:0] out_cnt;                          //輸出計數
reg signed [31:0] result [3:0];             //運算結果(最多4個)
reg [1:0] result_cnt;                       //結果數量紀錄
reg [1:0] mode_reg;                         //鎖存 mode   
reg signed [31:0] sorted_result [0:3]       //排列的結果
reg calc_done, sort_done;                   //計算、排列是否完成

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
                default:    next_state = IDLE
            endcase
        end
        SORT: next_state = (sort_done) ? OUTPUT : SORT;
        OUTPUT: next_state = (out_cnt == result_cnt) ? IDLE : OUTPUT;
        default: next_state = IDLE;
    endcase
end

// mode 鎖存與資料接收
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for(i = 0; i < 12; i = i + 1) in_data[i] <= 0;
        data_cnt <= 0;
        mode_reg <= 0;
    end
    else if (state == IDLE && in_valid) begin
        mode_reg <= mode;
        in_data[0] <= in;
        op_flag[0] <= operator;
        data_cnt <= 1;
    end
    else if (state == RECEIVE && in_valid) begin
        in_data[data_cnt] <= in;
        op_flag[data_cnt] <= operator;
        data_cnt <= data_cnt + 1;
    end
    else if (state == CALC) begin
        data_cnt <= 0;
    end
end

// 運算邏輯
integer i;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 4; i = i + 1) result[i] <= 0;
        for(i = 0; i < 4; i = i + 1) sorted_result[i] <= 0;
        for(i = 0; i < 12; i = i + 1) op_flag[i] <= 0;
        result_cnt <= 0;
        calc_done < 0;
    end
    else if(current_state == CALC) begin
        //結果運算
        result_cnt <= data_cnt / 3;
        for(i = 0; i < result_cnt; i = i + 1)begin
            integer idx;
            idx = i * 3;
            case(mode_reg)
                2'd0, 2'd2: begin   //prefix
                    if(op_flag[idx] == 1 && op_flag[idx+1] == 0 && op_flag[idx+2] == 0)begin
                        case(in_data[idx])
                            3'd0: result[i] <= in_data[idx+1] + in_data[idx+2];
                            3'd1: result[i] <= in_data[idx+1] - in_data[idx+2];
                            3'd2: result[i] <= in_data[idx+1] * in_data[idx+2];
                            3'd3: begin
                                integer sum = in_data[idx+1] + in_data[idx+2];
                                result[i] <= (sum >= 0) ? sum : - sum;
                            end
                            default: result[i] <= 0;
                        endcase
                    end
                    else result[i] <= 0;
                end
                2'd1, 2'd3: begin   //postfix
                    if(op_flag[idx] == 0 && op_flag[idx+1] == 0 && op_flag[idx+2] == 1) begin
                        case(in_data[idx+2])
                            3'd0: result[i] <= in_data[idx] + in_data[idx+1];
                            3'd1: result[i] <= in_data[idx] - in_data[idx+1];
                            3'd2: result[i] <= in_data[idx] * in_data[idx+1];
                            3'd3: begin
                                integer sum = in_data[idx] + in_data[idx+1];
                                result[i] <= (sum >= 0) ? sum : - sum;
                            end
                            default: result[i] <= 0;
                        endcase
                    end
                    else result[i] <= 0;
                end
            endcase
        end
        calc_done <= 1;
    end
    else calc_done <= 0;
end

// 排序邏輯（Bubble Sort）
integer j;
reg [31:0] temp;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 4; i = i + 1) sorted_result[i] <= 0;
        sort_done <= 0;
    end
    else if(current_state == SORT) begin
        // 將 result[] 複製到 sorted_result[]
        for(i = 0; i < result_cnt; i = i + 1) sorted_result[i] <= result[i];

        //排序
        for(i = 0; i < result_cnt - 1; i = i + 1) begin
            for(j = 0; j < result_cnt - 1 - i; j = j + 1) begin
                if((mode_reg == 2'd0 && sorted_result[j] < sorted_result[j+1]) ||       //降冪
                    (mode_reg == 2'd1 && sorted_result[j] > sorted_result[j+1])) begin  //升冪
                    temp = sorted_result[j];
                    sorted_result[j] = sorted_result[j+1];
                    sorted_result[j+1] = temp;
                end
            end
        end
        sort_done <= 1;
    end
    else sort_done <= 0;
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
