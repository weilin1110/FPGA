module tenthirty(
    input clk,
    input rst_n, //negedge reset
    input btn_m, //bottom middle
    input btn_r, //bottom right
    output reg [7:0] seg7_sel,
    output reg [7:0] seg7,   //segment right
    output reg [7:0] seg7_l, //segment left
    output reg [2:0] led // led[0] : player win, led[1] : dealer win, led[2] : done
);

//================================================================
//   PARAMETER
//================================================================

localparam IDLE = 3'd0;
localparam START = 3'd1;
localparam PLAYER = 3'd2;
localparam DEALER = 3'd3;
localparam COMPARE = 3'd4;
localparam DONE = 3'd5;

//================================================================
//   d_clk
//================================================================

//frequency division
reg [24:0] counter; 
wire dis_clk; //seg display clk, frequency faster than d_clk
wire d_clk  ; //division clk

//====== frequency division ======
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        counter <= 0;
    end
    else begin
        counter <= counter + 1;
    end
end
assign dis_clk = counter[16];
assign d_clk = counter[23];

//================================================================
//   REG/WIRE
//================================================================

//store segment display situation
reg [7:0] seg7_temp[0:7]; 
//display counter
reg [2:0] dis_cnt;
//LUT IO
reg  pip;
wire [3:0] number;
//FSM
reg [2:0] state;
reg [2:0] next_state;
// 玩家和莊家的牌值存儲
reg [3:0] player_cards [0:4];  // 玩家手牌(最多5張)
reg [3:0] dealer_cards [0:4];  // 莊家手牌(最多5張)
reg [2:0] player_cnt;          // 玩家手牌數
reg [2:0] dealer_cnt;          // 莊家手牌數
// 分數計算
reg [5:0] player_score;        // 玩家總分(2倍值)
reg [5:0] dealer_score;        // 莊家總分(2倍值)
// 半點的計數器
reg [2:0] player_half_cnt, dealer_half_cnt;
// 遊戲輪數計數
reg [1:0] round_cnt;
// 按鍵脈衝檢測
reg press_m_flag, press_r_flag;
wire btn_m_pulse;
wire btn_r_pulse;

//One Shot Pulse
always @(posedge d_clk or negedge rst_n) begin
    if (!rst_n) begin
        press_m_flag <= 0;
        press_r_flag <= 0;
    end else begin
        press_m_flag <= btn_m;
        press_r_flag <= btn_r;
    end
end
assign btn_m_pulse = {press_m_flag, btn_m} == 2'b10 ? 1 : 0;
assign btn_r_pulse = {press_r_flag, btn_r} == 2'b10 ? 1 : 0;

//================================================================
//   FSM
//================================================================

always @(*) begin
    case (state)
        IDLE: next_state = btn_m_pulse ? START : IDLE;
        
        START: begin
            // 初始化後進入玩家要牌狀態
            next_state = (player_cnt == 1 && dealer_cnt == 1) ? PLAYER : START;
        end
        
        PLAYER: begin
            if ((player_score > 10 || player_cnt == 5)) begin
                // 玩家爆牌或已要滿5張牌，轉莊家要牌
                next_state = DEALER;
            end else if (btn_r_pulse) begin
                // 玩家選擇不要牌，換莊家要牌
                next_state = DEALER;
            end else begin
                next_state = PLAYER;
            end
        end
        
        DEALER: begin
            if ( (dealer_score > 10 || dealer_cnt == 5))
            begin // 莊家爆牌或已要滿5張牌，進入比較狀態
                next_state = COMPARE;
            end else if (btn_r_pulse) begin
                // 玩家選擇不要牌，換莊家要牌
                next_state = COMPARE;
            end else begin
                next_state = DEALER;
            end
        end
        
        COMPARE: begin
            if (round_cnt == 3) begin
                // 已完成4輪，進完成狀態
                if(btn_r_pulse) begin
                    next_state = DONE;
                end
                else begin
                    next_state = COMPARE;
                end
            end else if (btn_r_pulse) begin
                // 準備下一輪
                next_state = IDLE;
            end else begin
                next_state = COMPARE;
            end
        end
        
        DONE: next_state = DONE;
    
    endcase
end
always @(posedge d_clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
    end else begin
        state <= next_state;
    end
end

//================================================================
//   DESIGN
//================================================================

//seg7_temp
always @(posedge d_clk or negedge rst_n) begin
    if (!rst_n) begin
        seg7_temp[0] <= 8'b0000_0001;
        seg7_temp[1] <= 8'b0000_0001;
        seg7_temp[2] <= 8'b0000_0001;
        seg7_temp[3] <= 8'b0000_0001;
        seg7_temp[4] <= 8'b0000_0001;
        seg7_temp[5] <= 8'b0000_0001;
        seg7_temp[6] <= 8'b0011_1111;
        seg7_temp[7] <= 8'b0011_1111;
    end else begin
        case (state)
            PLAYER: begin
                // 右邊顯示玩家的手牌
                seg7_temp[0] <= (player_cnt > 0) ? seg_decoder(player_cards[0]) : 8'b0000_0001;
                seg7_temp[1] <= (player_cnt > 1) ? seg_decoder(player_cards[1]) : 8'b0000_0001;
                seg7_temp[2] <= (player_cnt > 2) ? seg_decoder(player_cards[2]) : 8'b0000_0001;
                seg7_temp[3] <= (player_cnt > 3) ? seg_decoder(player_cards[3]) : 8'b0000_0001;
                seg7_temp[4] <= (player_cnt > 4) ? seg_decoder(player_cards[4]) : 8'b0000_0001;
                // 左邊顯示玩家總分
                seg7_temp[7] <= seg_decoder(player_score / 10); // 十位
                seg7_temp[6] <= seg_decoder(player_score % 10); // 個位
                seg7_temp[5] <= (player_half_cnt == 1) ? 8'b1000_0000 : 8'b0000_0001;
                //有半點時顯示半點 否則顯示上方一槓
            end

            DEALER: begin
                // 右邊顯示莊家的手牌
                seg7_temp[0] <= (dealer_cnt > 0) ? seg_decoder(dealer_cards[0]) : 8'b0000_0001;
                seg7_temp[1] <= (dealer_cnt > 1) ? seg_decoder(dealer_cards[1]) : 8'b0000_0001;
                seg7_temp[2] <= (dealer_cnt > 2) ? seg_decoder(dealer_cards[2]) : 8'b0000_0001;
                seg7_temp[3] <= (dealer_cnt > 3) ? seg_decoder(dealer_cards[3]) : 8'b0000_0001;
                seg7_temp[4] <= (dealer_cnt > 4) ? seg_decoder(dealer_cards[4]) : 8'b0000_0001;
                // 左邊顯示莊家總分
                seg7_temp[7] <= seg_decoder(dealer_score / 10);
                seg7_temp[6] <= seg_decoder(dealer_score % 10);
                seg7_temp[5] <= (dealer_half_cnt == 1) ? 8'b1000_0000 : 8'b0000_0001;
                //有半點時顯示半點 否則顯示上方一槓
            end

            COMPARE: begin
                // COMPARE狀態：左邊3個顯示莊家分數，右邊3個顯示玩家分數
                seg7_temp[7] <= seg_decoder(dealer_score / 10);
                seg7_temp[6] <= seg_decoder(dealer_score % 10);
                seg7_temp[5] <= (dealer_half_cnt == 1) ? 8'b1000_0000 : 8'b0000_0001;
                seg7_temp[4] <= 8'b0000_0001;
                seg7_temp[3] <= 8'b0000_0001;
                seg7_temp[2] <= seg_decoder(player_score / 10);
                seg7_temp[1] <= seg_decoder(player_score % 10);
                seg7_temp[0] <= (player_half_cnt == 1) ? 8'b1000_0000 : 8'b0000_0001;
            end

            default: begin
                // 其他狀態清空
                seg7_temp[0] <= 8'b0000_0001;
                seg7_temp[1] <= 8'b0000_0001;
                seg7_temp[2] <= 8'b0000_0001;
                seg7_temp[3] <= 8'b0000_0001;
                seg7_temp[4] <= 8'b0000_0001;
                seg7_temp[5] <= 8'b0000_0001;
                seg7_temp[6] <= 8'b0011_1111;
                seg7_temp[7] <= 8'b0011_1111;
            end
        endcase
    end
end

function [7:0] seg_decoder;
    input [3:0] num;
    begin
        case (num)
            4'd0: seg_decoder = 8'b0011_1111;
            4'd1: seg_decoder = 8'b0000_0110;
            4'd2: seg_decoder = 8'b0101_1011;
            4'd3: seg_decoder = 8'b0100_1111;
            4'd4: seg_decoder = 8'b0100_1111;
            4'd5: seg_decoder = 8'b0110_1101;
            4'd6: seg_decoder = 8'b0111_1101;
            4'd7: seg_decoder = 8'b0000_0111;
            4'd8: seg_decoder = 8'b0111_1111;
            4'd9: seg_decoder = 8'b0110_1111;
            4'd10: seg_decoder = 8'b0011_1111; // 10 顯示 0
            4'd11: seg_decoder = 8'b1000_0000; // J 顯示 .
            4'd12: seg_decoder = 8'b1000_0000; // Q 顯示 .
            4'd13: seg_decoder = 8'b1000_0000; // K 顯示 .
            default: seg_decoder = 8'b0000_0000; //全滅
        endcase
    end
endfunction

//拉高pip要牌
always @(posedge d_clk or negedge rst_n) begin
    if (!rst_n) begin
        pip <= 0;
    end
    else begin
        pip <= (state == START && player_cnt == 0) || 
               (state == PLAYER && btn_m_pulse) ||
               (state == DEALER && btn_m_pulse);
    end
end

reg pip_dly; //pip訊號當下只拿牌 等到pip_dly訊號再加總
always @(posedge d_clk or negedge rst_n) begin
    if (!rst_n)
        pip_dly <= 1'b0;
    else
        pip_dly <= pip;
end

//拿牌 + 更新分數
reg [5:0] temp_score;
reg [2:0] temp_half;
always @(posedge d_clk or negedge rst_n) begin
    if (!rst_n) begin
        player_cnt <= 0;
        dealer_cnt <= 0;
        player_score <= 0;
        dealer_score <= 0;
        
        round_cnt <= 0;
    end else begin
        case (state)
            START: begin //玩家莊家先各拿一張
                if (pip_dly) begin
                    if (player_cnt == 0) begin
                        // 玩家第一張牌
                        player_cards[0] <= number;
                        player_cnt <= 1;
                        if (number > 10) begin //JQK算半點
                            player_half_cnt <= 1;    
                        end else begin
                            player_score <= number; //分數
                        end
                    
                    end else if (dealer_cnt == 0) begin
                        // 莊家第一張牌
                        dealer_cards[0] <= number;
                        dealer_cnt <= 1;
                        if (number > 10) begin
                            dealer_half_cnt <= 1;
                        end else begin
                            dealer_score <= number;
                        end
                    end
                end
            end

            PLAYER: begin
                if (pip_dly && player_cnt < 5) begin
                    
                    player_cnt <= player_cnt + 1;
                    player_cards[player_cnt] <= number;

                    temp_score = player_score;
                    temp_half  = player_half_cnt;

                    if (number > 10) begin
                        temp_half = temp_half + 1;

                        if (temp_half >= 2) begin
                            temp_half  = temp_half - 2;
                            temp_score = temp_score + 1;
                        end
                    end else begin
                        temp_score = temp_score + number;
                    end

                    player_score     <= temp_score;
                    player_half_cnt  <= temp_half;
                end
            end

            DEALER: begin
                if (pip_dly && dealer_cnt < 5) begin
                    
                    dealer_cnt <= dealer_cnt + 1;
                    dealer_cards[dealer_cnt] <= number;

                    temp_score = dealer_score;
                    temp_half  = dealer_half_cnt;

                    if (number > 10) begin
                        temp_half = temp_half + 1;

                        if (temp_half >= 2) begin
                            temp_half  = temp_half - 2;
                            temp_score = temp_score + 1;
                        end
                    end else begin
                        temp_score = temp_score + number;
                    end

                    dealer_score     <= temp_score;
                    dealer_half_cnt  <= temp_half;
                end
            end


            COMPARE: begin
                if (btn_r_pulse) begin
                    // 一局結束，準備下一局
                    player_cnt <= 0;
                    dealer_cnt <= 0;
                    player_score <= 0;
                    dealer_score <= 0;
                    player_half_cnt <= 0;
                    dealer_half_cnt <= 0;
                    round_cnt <= round_cnt + 1;
                end
            end

            default: ;
        endcase
    end
end

//================================================================
//   LED
//================================================================

// LED控制
always @(posedge d_clk or negedge rst_n) begin
    if (!rst_n) begin
        led <= 3'b000;
    end else begin
        case (state)
            COMPARE: begin
                if (player_score > 10 || 
                   ((dealer_score <= 10 && dealer_score >= player_score)) && (dealer_half_cnt >= player_half_cnt)) begin
                    led <= 3'b010; // 莊家贏
                end else begin
                    led <= 3'b001; // 玩家贏
                end
            end
            
            DONE: begin
                led <= 3'b100; // 遊戲完成
            end
            
            default: begin
                led <= 3'b000; // 其他狀態LED關閉
            end
        endcase
    end
end

//#################### Don't revise the code below ############################## 

//================================================================
//   SEGMENT
//================================================================

//display counter 
always@(posedge dis_clk or negedge rst_n) begin
    if(!rst_n) begin
        dis_cnt <= 0;
    end
    else begin
        dis_cnt <= (dis_cnt >= 7) ? 0 : (dis_cnt + 1);
    end
end

always @(posedge dis_clk or negedge rst_n) begin 
    if(!rst_n) begin
        seg7 <= 8'b0000_0001;
    end 
    else begin
        if(!dis_cnt[2]) begin
            seg7 <= seg7_temp[dis_cnt];
        end
    end
end

always @(posedge dis_clk or negedge rst_n) begin 
    if(!rst_n) begin
        seg7_l <= 8'b0000_0001;
    end 
    else begin
        if(dis_cnt[2]) begin
            seg7_l <= seg7_temp[dis_cnt];
        end
    end
end

always@(posedge dis_clk or negedge rst_n) begin
    if(!rst_n) begin
        seg7_sel <= 8'b11111111;
    end
    else begin
        case(dis_cnt)
            0 : seg7_sel <= 8'b00000001;
            1 : seg7_sel <= 8'b00000010;
            2 : seg7_sel <= 8'b00000100;
            3 : seg7_sel <= 8'b00001000;
            4 : seg7_sel <= 8'b00010000;
            5 : seg7_sel <= 8'b00100000;
            6 : seg7_sel <= 8'b01000000;
            7 : seg7_sel <= 8'b10000000;
            default : seg7_sel <= 8'b11111111;
        endcase
    end
end

//================================================================
//   LUT
//================================================================
 
lut inst_LUT (.clk(d_clk), .rst_n(rst_n), .pip(pip), .number(number));

endmodule 
