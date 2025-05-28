// 排序邏輯（簡化版本，一拍完成）
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < 4; i = i + 1) sorted_result[i] <= 0;
        sort_done <= 0;
    end
    else if (current_state == SORT) begin
        reg signed [31:0] a[0:3];
        for (i = 0; i < result_cnt; i = i + 1)
            a[i] = result[i];

        // 比較並排序（最多4個元素，展開所有可能）
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
            reg signed [31:0] b0, b1, b2;
            // Bubble sort 展開版（3元素）
            if ((mode_reg == 2'd0 && a[0] < a[1]) || (mode_reg == 2'd1 && a[0] > a[1])) begin
                b0 = a[1]; b1 = a[0];
            end else begin
                b0 = a[0]; b1 = a[1];
            end
            if ((mode_reg == 2'd0 && b1 < a[2]) || (mode_reg == 2'd1 && b1 > a[2])) begin
                b2 = b1; b1 = a[2];
            end else begin
                b2 = a[2];
            end
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
            reg signed [31:0] t[0:3];
            t[0] = a[0]; t[1] = a[1]; t[2] = a[2]; t[3] = a[3];

            // 展開的 bubble sort for 4 items（3輪）
            integer round, j;
            for (round = 0; round < 3; round = round + 1) begin
                for (j = 0; j < 3 - round; j = j + 1) begin
                    if ((mode_reg == 2'd0 && t[j] < t[j+1]) || (mode_reg == 2'd1 && t[j] > t[j+1])) begin
                        reg signed [31:0] temp;
                        temp = t[j];
                        t[j] = t[j+1];
                        t[j+1] = temp;
                    end
                end
            end

            sorted_result[0] <= t[0];
            sorted_result[1] <= t[1];
            sorted_result[2] <= t[2];
            sorted_result[3] <= t[3];
        end

        sort_done <= 1;
    end
    else begin
        sort_done <= 0;
    end
end
