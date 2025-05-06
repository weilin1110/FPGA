// 十點半遊戲主模組 tenthirty.v
// 功能：控制整個遊戲流程（發牌、比牌、顯示、LED），與 LUT 模組搭配運作
module tenthirty(
    input clk,
    input rst_n, // 非同步負緣 reset
    input btn_m, // 中鍵，代表 "抽牌" 或 "開始"
    input btn_r, // 右鍵，代表 "不抽牌" 或 "進下一階段"
    output reg [7:0] seg7_sel,
    output reg [7:0] seg7,   // segment 顯示器右邊資料（前四顆）
    output reg [7:0] seg7_l, // segment 顯示器左邊資料（後四顆）
    output reg [2:0] led     // led[0] : 玩家贏, led[1] : 莊家贏, led[2] : 遊戲結束
);

//================================================================
//   PARAMETER - 狀態定義
//================================================================
parameter IDLE = 3'd0;
parameter BEGINNING = 3'd1; // 起始牌階段（玩家與莊家各一張）
parameter HIT_PLAYER = 3'd2; // 玩家抽牌階段
parameter HIT_DEALER = 3'd3; // 莊家抽牌階段
parameter COMPARE = 3'd4; // 比牌階段
parameter DONE = 3'd5;    // 遊戲結束（4 回合）

//================================================================
//   d_clk 分頻器設定
//================================================================
reg [24:0] counter; 
wire dis_clk; // 顯示用時脈（較快）
wire d_clk; // 控制邏輯用時脈（較慢）

// 分頻器邏輯
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        counter <= 0;
    end else begin
        counter <= counter + 1;
    end
end

assign dis_clk = counter[0]; //16
assign d_clk = counter[1]; //23

//================================================================
//   REG / WIRE 區域
//================================================================
reg [7:0] seg7_temp[0:7]; // 暫存各顆七段顯示器顯示的值
reg [2:0] dis_cnt;        // 控制哪一顆七段顯示器亮
reg pip;                  // 發牌觸發信號
wire [3:0] number;        // 從 LUT 抽出的一張牌值（1~13）

reg [2:0]current_state, next_state;
reg [2:0]round; //遊戲次數

//玩家
reg [3:0]cards_of_player[0:4];  //1到5張牌
reg [3:0]total_point_of_player[0:1]; //[0小數點:1整數]
reg [2:0]player_cards_cnt;  //手牌數
//莊家
reg [3:0]cards_of_dealer[0:4];
reg [3:0]total_point_of_dealer[0:1];
reg [2:0]dealer_cards_cnt;  

//=============================
// ONE SHOT PULSE
//=============================
reg btn_m_press_flag;
reg btn_r_press_flag;
wire btn_m_pluse;
wire btn_r_pluse;

always @(posedge d_clk or negedge rst_n) begin
    if(!rst_n) begin
        btn_m_press_flag <= 0;
        btn_r_press_flag <= 0;
    end
    else begin
        btn_m_press_flag <= btn_m;
        btn_r_press_flag <= btn_r;
    end
end
assign btn_m_pluse = {btn_m, btn_m_press_flag} == 2'b10 ? 1 : 0;
assign btn_r_pluse = {btn_r, btn_r_press_flag} == 2'b10 ? 1 : 0;

//================================================================
//   FSM 狀態控制
//================================================================

always @(posedge d_clk or negedge rst_n) begin
    if(!rst_n)
        current_state <= IDLE;
    else
        current_state <= next_state;
end

always @(*) begin
    case(current_state)
        IDLE: begin
            if(btn_m_pluse)
                next_state <= BEGINNING;
            else
                next_state <= IDLE;
        end

        BEGINNING: begin
            if(player_cards_cnt == 1 && dealer_cards_cnt == 1)
                next_state <= HIT_PLAYER;
            else
                next_state <= BEGINNING;
        end

        HIT_PLAYER: begin
            if(btn_r_pluse || total_point_of_player[1] > 10 || player_cards_cnt == 5)
                next_state <= HIT_DEALER;
            else
                next_state <= HIT_PLAYER;
        end

        HIT_DEALER: begin
            if(btn_r_pluse || total_point_of_dealer[1] > 10 || dealer_cards_cnt == 5)
                next_state <= COMPARE;
            else
                next_state <= HIT_DEALER;
        end

        COMPARE: begin
            if(round < 4) begin
                if(btn_r_pluse)
                    next_state <= IDLE;
                else
                    next_state <= COMPARE;
            end
            else begin
                if(btn_r_pluse)
                    next_state <= DONE;
                else
                    next_state <= COMPARE;
            end
        end

        DONE: next_state <= DONE;
    endcase
end


//抽牌
//pip
always @(posedge d_clk or negedge rst_n) begin
    if(!rst_n)
        pip <= 0;
    else begin
        case(current_state)
            BEGINNING:
                if(player_cards_cnt == 0) pip <= 1;
                else pip <= 0;
            
            HIT_PLAYER:
                if(btn_m_pluse) pip <= 1;
                else pip <= 0;

            HIT_DEALER:
                if(btn_m_pluse) pip <= 1;
                else pip <= 0;
        endcase
    end
end

reg pip_delay_1_clk;
always @(posedge d_clk or negedge rst_n) begin
    if (!rst_n)
        pip_delay_1_clk <= 1'b0;
    else
        pip_delay_1_clk <= pip;
end

always @(posedge d_clk or negedge rst_n) begin
    if(!rst_n) begin
        cards_of_player[0] <= 0;
        cards_of_player[1] <= 0;
        cards_of_player[2] <= 0;
        cards_of_player[3] <= 0;
        cards_of_player[4] <= 0; 
        total_point_of_player[1] <= 0;
        total_point_of_player[0] <= 0;
        player_cards_cnt <= 0;

        cards_of_dealer[0] <= 0;
        cards_of_dealer[1] <= 0;
        cards_of_dealer[2] <= 0;
        cards_of_dealer[3] <= 0;
        cards_of_dealer[4] <= 0;
        total_point_of_dealer[1] <= 0;
        total_point_of_dealer[0] <= 0;
        dealer_cards_cnt <= 0;

        round <= 1;
    end
    else begin
        case(current_state)
            BEGINNING: begin
                if(player_cards_cnt == 0 && pip_delay_1_clk) begin
                    cards_of_player[0] <= number;
                    player_cards_cnt <= 1;
                    if(number > 10)
                        total_point_of_player[0] <= 1;
                    else
                        total_point_of_player[1] <= number;
                end
                else if(dealer_cards_cnt == 0 && pip_delay_1_clk) begin
                    cards_of_dealer[0] <= number;
                    dealer_cards_cnt <= 1;
                    if(number > 10)
                        total_point_of_dealer[0] <= 1;
                    else
                        total_point_of_dealer[1] <= number;
                end
            end

            HIT_PLAYER: begin
                if(pip_delay_1_clk && player_cards_cnt < 5) begin
                    cards_of_player[player_cards_cnt] <= number;

                    if(number > 10) begin
                        if(total_point_of_player[0] == 1) begin
                            total_point_of_player[0] <= 0;
                            total_point_of_player[1] <= total_point_of_player[1] + 1;
                        end
                        else begin
                            total_point_of_player[0] <= 1;
                            total_point_of_player[1] <= total_point_of_player[1];
                        end
                    end
                    else begin
                        total_point_of_player[1] <= total_point_of_player[1] + number;
                    end

                    player_cards_cnt <= player_cards_cnt + 1;
                end
            end

            HIT_DEALER: begin
                if(pip_delay_1_clk && dealer_cards_cnt < 5) begin
                    cards_of_dealer[dealer_cards_cnt] <= number;

                    if(number > 10) begin
                        if(total_point_of_dealer[0] == 1) begin
                            total_point_of_dealer[0] <= 0;
                            total_point_of_dealer[1] <= total_point_of_dealer[1] + 1;
                        end
                        else begin
                            total_point_of_dealer[0] <= 1;
                            total_point_of_dealer[1] <= total_point_of_dealer[1];
                        end
                    end
                    else begin
                        total_point_of_dealer[1] <= total_point_of_dealer[1] + number;
                    end

                    dealer_cards_cnt <= dealer_cards_cnt + 1;
                end
            end

            COMPARE: begin
                if(btn_r_pluse) begin
                    player_cards_cnt <= 0;
                    total_point_of_player[0] <= 0;
                    total_point_of_player[1] <= 0;
                    cards_of_player[0] <= 0;
                    cards_of_player[1] <= 0;
                    cards_of_player[2] <= 0;
                    cards_of_player[3] <= 0;
                    cards_of_player[4] <= 0;

                    dealer_cards_cnt <= 0;
                    total_point_of_dealer[0] <= 0;
                    total_point_of_dealer[1] <= 0;
                    cards_of_dealer[0] <= 0;
                    cards_of_dealer[1] <= 0;
                    cards_of_dealer[2] <= 0;
                    cards_of_dealer[3] <= 0;
                    cards_of_dealer[4] <= 0;

                    round <= round + 1;
                end
            end
        endcase
    end

end

//================================================================
//   LED 控制邏輯
//================================================================

always @(posedge d_clk or negedge rst_n) begin
    if (!rst_n)
        led <= 3'b000;
    else begin
        case (current_state)
            COMPARE: begin
                if (total_point_of_player[1] >= 11)
                    led <= 3'b010; // 玩家爆牌 → 莊家贏
                else if (total_point_of_dealer[1] >= 11)
                    led <= 3'b001; // 莊家爆牌 → 玩家贏
                else if (total_point_of_player[1] == total_point_of_dealer[1]) begin
                    if(total_point_of_player[0] == total_point_of_dealer[0])
                        led <= 3'b010;
                    else if(total_point_of_player[0] > total_point_of_dealer[0])
                        led <= 3'b001;
                    else if(total_point_of_player[0] < total_point_of_dealer[0])
                        led <= 3'b010; 
                end
                else if(total_point_of_player[1] < total_point_of_dealer[1])
                    led <= 3'b010;
            end
            DONE: begin
                led <= 3'b100; // 四回合結束顯示
            end
            default: begin
                led <= 3'b000;
            end
        endcase
    end
end

//================================================================
//Seven-Segment Display
//================================================================

//seg7_temp顯示
always @(posedge d_clk or negedge rst_n) begin
    if (!rst_n) begin
        seg7_temp[0] <= 8'b0000_0001;
        seg7_temp[1] <= 8'b0000_0001;
        seg7_temp[2] <= 8'b0000_0001;
        seg7_temp[3] <= 8'b0000_0001;
        seg7_temp[4] <= 8'b0000_0001;
        seg7_temp[5] <= 8'b0000_0001;
        seg7_temp[6] <= 8'b0000_0001;
        seg7_temp[7] <= 8'b0000_0001;
    end
    else begin
        case (current_state)
            HIT_PLAYER: begin
                seg7_temp[0] <= (player_cards_cnt > 0)? seg_display(cards_of_player[0]) : 8'b0000_0001;
                seg7_temp[1] <= (player_cards_cnt > 1)? seg_display(cards_of_player[1]) : 8'b0000_0001;
                seg7_temp[2] <= (player_cards_cnt > 2)? seg_display(cards_of_player[2]) : 8'b0000_0001;
                seg7_temp[3] <= (player_cards_cnt > 3)? seg_display(cards_of_player[3]) : 8'b0000_0001;
                seg7_temp[4] <= (player_cards_cnt > 4)? seg_display(cards_of_player[4]) : 8'b0000_0001;
                seg7_temp[5] <= (total_point_of_player[0] == 1) ? 8'b1000_0000 : 8'b0000_0001;
                seg7_temp[6] <= seg_display(total_point_of_player[1] % 10);
                seg7_temp[7] <= seg_display(total_point_of_player[1] / 10);
            end

            HIT_DEALER: begin
                seg7_temp[0] <= (dealer_cards_cnt > 0)? seg_display(cards_of_dealer[0]) : 8'b0000_0001;
                seg7_temp[1] <= (dealer_cards_cnt > 1)? seg_display(cards_of_dealer[1]) : 8'b0000_0001;
                seg7_temp[2] <= (dealer_cards_cnt > 2)? seg_display(cards_of_dealer[2]) : 8'b0000_0001;
                seg7_temp[3] <= (dealer_cards_cnt > 3)? seg_display(cards_of_dealer[3]) : 8'b0000_0001;
                seg7_temp[4] <= (dealer_cards_cnt > 4)? seg_display(cards_of_dealer[4]) : 8'b0000_0001;
                seg7_temp[5] <= (total_point_of_dealer[0] == 1)? 8'b1000_0000 : 8'b0000_0001;
                seg7_temp[6] <= seg_display(total_point_of_dealer[1] % 10);
                seg7_temp[7] <= seg_display(total_point_of_dealer[1] / 10);
            end

            COMPARE: begin
                seg7_temp[0] <= (total_point_of_player[0] == 1)? 8'b1000_0000 : 8'b0000_0001;
                seg7_temp[1] <= seg_display(total_point_of_player[1] % 10);
                seg7_temp[2] <= seg_display(total_point_of_player[1] / 10);
                seg7_temp[3] <= 8'b0000_0001;
                seg7_temp[4] <= 8'b0000_0001;
                seg7_temp[5] <= (total_point_of_dealer[0] == 1)? 8'b1000_0000 : 8'b0000_0001;
                seg7_temp[6] <= seg_display(total_point_of_dealer[1] % 10);
                seg7_temp[7] <= seg_display(total_point_of_dealer[1] / 10);
            end

            default: begin
                seg7_temp[0] <= 8'b0000_0001;
                seg7_temp[1] <= 8'b0000_0001;
                seg7_temp[2] <= 8'b0000_0001;
                seg7_temp[3] <= 8'b0000_0001;
                seg7_temp[4] <= 8'b0000_0001;
                seg7_temp[5] <= 8'b0000_0001;
                seg7_temp[6] <= 8'b0000_0001;
                seg7_temp[7] <= 8'b0000_0001;
            end
        endcase
    end
end

function [7:0] seg_display;
    input [3:0] number;
    begin
        case (number)
            0: seg_display = 8'b0011_1111;
            1: seg_display = 8'b0000_0110;
            2: seg_display = 8'b0101_1011;
            3: seg_display = 8'b0100_1111;
            4: seg_display = 8'b0100_1111;
            5: seg_display = 8'b0110_1101;
            6: seg_display = 8'b0111_1101;
            7: seg_display = 8'b0000_0111;
            8: seg_display = 8'b0111_1111;
            9: seg_display = 8'b0110_1111;
            10: seg_display = 8'b0011_1111;
            11: seg_display = 8'b1000_0000;
            12: seg_display = 8'b1000_0000;
            13: seg_display = 8'b1000_0000; 
            default: seg_display = 8'b0000_0001; 
        endcase
    end
endfunction


//================================================================
//   SEGMENT 顯示邏輯（不要修改以下區段）
//================================================================

always@(posedge dis_clk or negedge rst_n) begin
    if(!rst_n)
        dis_cnt <= 0;
    else
        dis_cnt <= (dis_cnt >= 7) ? 0 : (dis_cnt + 1);
end

always @(posedge dis_clk or negedge rst_n) begin 
    if(!rst_n)
        seg7 <= 8'b0000_0001;
    else if(!dis_cnt[2])
        seg7 <= seg7_temp[dis_cnt];
end

always @(posedge dis_clk or negedge rst_n) begin 
    if(!rst_n)
        seg7_l <= 8'b0000_0001;
    else if(dis_cnt[2])
        seg7_l <= seg7_temp[dis_cnt];
end

always@(posedge dis_clk or negedge rst_n) begin
    if(!rst_n)
        seg7_sel <= 8'b11111111;
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
//   LUT 發牌模組實例化
//================================================================
lut inst_LUT (.clk(d_clk), .rst_n(rst_n), .pip(pip), .number(number));

endmodule
