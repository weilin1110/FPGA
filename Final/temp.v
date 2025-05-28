// 排序邏輯（簡化版本，一拍完成）
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
