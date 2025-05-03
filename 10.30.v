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
parameter IDLE = 0;
parameter BEGINNING = 1; // 起始牌階段（玩家與莊家各一張）
parameter HIT_PLAYER = 2; // 玩家抽牌階段
parameter HIT_DEALER = 3; // 莊家抽牌階段
parameter COMPARE = 4; // 比牌階段
parameter DONE = 5;    // 遊戲結束（4 回合）

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

assign d_clk = counter[0]; //23
assign dis_clk = counter[1]; //16

//================================================================
//   REG / WIRE 區域
//================================================================
reg [7:0] seg7_temp[0:7]; // 暫存各顆七段顯示器顯示的值
reg [2:0] dis_cnt;        // 控制哪一顆七段顯示器亮
reg pip;                  // 發牌觸發信號
wire [3:0] number;        // 從 LUT 抽出的一張牌值（1~13）

//=============================
// ONE SHOT PULSE
//=============================
reg btn_m_press_flag;
reg btn_r_press_flag;
wire btn_m_pluse;
wire btn_r_pluse;

//btn_m
always @(posedge d_clk or negedge rst_n) begin
    if(!rst_n)
        btn_m_press_flag <= 0;
    else
        btn_m_press_flag <= btn_m_pos;
end
assign btn_m_pluse = {btn_m, btn_m_press_flag} == 2'b10 ? 1 : 0;

//btn_r
always @(posedge d_clk or negedge rst_n) begin
    if(!rst_n)
        btn_r_press_flag <= 0;
    else
        btn_r_press_flag <= btn_r_pos;
end
assign btn_r_pluse = {btn_r, btn_r_press_flag} == 2'b10 ? 1 : 0;

//================================================================
//   FSM 狀態控制
//================================================================
reg [2:0]current_state, next_state;
reg [2:0]round; //遊戲次數

reg [3:0]cards_of_player[0:4];  //1到5張牌
reg [3:0]total_point_of_player[0:1]; //[0小數點:1整數]
reg [3:0]cards_of_dealer[0:4];
reg [3:0]total_point_of_dealer[0:1];


integer i, k, cnt;
// 狀態寄存器（主狀態）
always @(posedge d_clk or negedge rst_n) begin
    if (!rst_n) begin
        current_state <= IDLE;
        next_state <= IDLE;
        round <= 3'b000;
        k <= 0;
        for(i = 0; i < 5; i = i + 1) begin
            cards_of_player[i] = 0;
            total_point_of_player[i] = 0;
            cards_of_dealer[i] = 0;
            total_point_of_dealer[i] = 0;
        end
    end
    else
        current_state <= next_state;
end

// 狀態轉移邏輯
always @(posedge d_clk) begin
    case (current_state)
        IDLE: begin
            if (btn_m_pluse) begin
                next_state <= BEGINNING;
                round <= round + 1;
                k <= 0;
                cnt <= 0;
                for(i = 0; i < 5; i = i + 1) begin
                    cards_of_player[i] <= 0;
                    total_point_of_player[i] <= 0;
                    cards_of_dealer[i] <= 0;
                    total_point_of_dealer[i] <= 0;
                end
            end
            else
                next_state <= IDLE;
        end
        BEGINNING: begin
            if(cnt == 2) begin
                next_state <= HIT_PLAYER;
                k <= 1;
            end
            else begin
                next_state <= BEGINNING;
                cnt <= cnt + 1;
            end
        end
        HIT_PLAYER: begin
            if (btn_r_pluse || (cards_of_player[4] != 0) || (total_point_of_player[1] >= 11) || ((total_point_of_player[1] || 10) && (total_point_of_player[0] == 1))) begin
                next_state <= HIT_DEALER;
                k <= 1;
            end
            else
                next_state <= HIT_PLAYER;
        end
        HIT_DEALER: begin
            if (btn_r_pluse || (cards_of_dealer[4] != 0) || (total_point_of_dealer[1] >= 11) || ((total_point_of_dealer[1] == 10) && (total_point_of_dealer[0] == 1))) begin
                next_state <= COMPARE;
            end
            else
                next_state <= HIT_DEALER;
        end
        COMPARE: begin
            if (btn_r_pluse && round < 4)
                next_state <= IDLE;
            else if (btn_r_pluse)
                next_state <= DONE;
            else
                next_state <= COMPARE;
        end
        DONE: next_state = DONE;
        default: next_state <= IDLE;
    endcase
end

//抽牌
always @(posedge d_clk or negedge rst_n) begin
    if(!rst_n) begin
        pip <= 0;
    end
    else begin
    case(current_state)
        BEGINNING: begin
            if(cnt == 0) begin
                pip <= 1;
            end
            else if(cnt == 2) begin
                pip <= 0;
            end;

            if(cards_of_player[0] == 0 && number != 0) begin
                cards_of_player[0] <= number;
                if(number < 11)
                    total_point_of_player[1] = number;
                else if(number > 10)
                    total_point_of_player[0] = 1;
            end
            else if(cards_of_dealer[0] == 0 && number != 0) begin
                cards_of_dealer[0] <= number;
                if(number < 11)
                    total_point_of_dealer[1] = number;
                else if(number > 10)
                    total_point_of_dealer[0] = 1;
            end
        end
        HIT_PLAYER: begin
            if(btn_m_pluse) begin
                pip <= btn_m_pluse;
            end
            else
                pip <= 0;

            if(number != 0)begin
                cards_of_player[k] <= number;
                if(number < 11)
                    total_point_of_player[1] = number;
                else if(number > 10)
                    total_point_of_player[0] = total_point_of_player[0] + 1;

                if(total_point_of_player[0] == 2)begin
                    total_point_of_player[1] = total_point_of_player[1] + 1;
                    total_point_of_player[0] = 0;
                end
                k <= k + 1;
            end
        end
        HIT_DEALER: begin
            if(btn_m_pluse) begin
                pip <= btn_m_pluse;
            end
            else
                pip <= 0;

            if(number != 0)begin
                cards_of_dealer[k] <= number;
                if(number < 11)
                    total_point_of_dealer[1] = number;
                else if(number > 10)
                    total_point_of_dealer[0] = total_point_of_dealer[0] + 1;

                if(total_point_of_dealer[0] == 2)begin
                    total_point_of_dealer[1] = total_point_of_dealer[1] + 1;
                    total_point_of_dealer[0] = 0;
                end
                k <= k + 1;
            end
        end
        default: ;
    endcase
    end
end

//================================================================
//   LED 控制邏輯
//================================================================
// 假設外部已定義 player_total_int / half、dealer_total_int / half
always @(posedge d_clk or negedge rst_n) begin
    if (!rst_n) begin
        led <= 3'b000;
    end else begin
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
reg [7:0]seg7_number[0:7];

//seg7_temp顯示
always@ (posedge d_clk or negedge rst_n) begin
    if(!rst_n) begin
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
    case(current_state)
        HIT_PLAYER: begin
            for(i = 0; i < 4; i = i + 1) begin
                seg7_number[i] <= cards_of_player[i];
            end
            seg7_number[5] <= (total_point_of_player[0] == 0)? 0 : 11;
            seg7_number[6] <= total_point_of_player[1] % 10;
            seg7_number[7] <= total_point_of_player[1] / 10;
        end
        HIT_DEALER: begin
            for(i = 0; i < 4; i = i + 1) begin
                seg7_number[i] <= cards_of_dealer[i];
            end
            seg7_number[5] <= (total_point_of_dealer[0] == 0)? 0: 11;
            seg7_number[6] <= total_point_of_dealer[1] % 10;
            seg7_number[7] <= total_point_of_dealer[1] / 10;
        end
        COMPARE: begin
            seg7_number[0] <= (total_point_of_player[0] == 0)? 0 : 11;
            seg7_number[1] <= total_point_of_player[1] % 10;
            seg7_number[2] <= total_point_of_player[1] / 10;
            seg7_number[3] <= 0;
            seg7_number[4] <= 0;
            seg7_number[5] <= (total_point_of_dealer[0] == 0)? 0: 11;
            seg7_number[6] <= total_point_of_dealer[1] % 10;
            seg7_number[7] <= total_point_of_dealer[1] / 10;
        end
        default: begin
            // 其他狀態清空
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
        case(seg7_number[dis_cnt])
			0:seg7_temp[dis_cnt] <= 8'b0011_1111;
            1:seg7_temp[dis_cnt] <= 8'b0000_0110;
            2:seg7_temp[dis_cnt] <= 8'b0101_1011;
            3:seg7_temp[dis_cnt] <= 8'b0100_1111;
            4:seg7_temp[dis_cnt] <= 8'b0110_0110;
            5:seg7_temp[dis_cnt] <= 8'b0110_1101;
            6:seg7_temp[dis_cnt] <= 8'b0111_1101;
            7:seg7_temp[dis_cnt] <= 8'b0000_0111;
            8:seg7_temp[dis_cnt] <= 8'b0111_1111;
            9:seg7_temp[dis_cnt] <= 8'b0110_1111;
            10:seg7_temp[dis_cnt] <= 8'b0011_1111;
            11:seg7_temp[dis_cnt] <= 8'b1000_0000;
            12:seg7_temp[dis_cnt] <= 8'b1000_0000;
            13:seg7_temp[dis_cnt] <= 8'b1000_0000;
            14:seg7_temp[dis_cnt] <= 8'b0000_0001;
            default:seg7_temp[dis_cnt] <= 8'b0000_0001;
		endcase
    end
end


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
