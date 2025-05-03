`timescale 1ns/1ps
`define CYCLE 10

module tb_tenthirty ();

    reg  clk = 0;
    reg  rst_n;
    reg  sw;
    reg  btn_m; //bottom middle
    reg  btn_r; //bottom right
    wire [7:0] seg7_sel;
    wire [7:0] seg7;   
    wire [7:0] seg7_l; 
    wire [2:0] led;

    // clk
    always begin
        #(`CYCLE/2) clk = ~clk;
    end

    //================================================================
    //   d_clk
    //================================================================
    // frequency division
    reg [24:0] counter; 
    wire d_clk = counter[4]; // �нT�O�P tenthirty.v �@�P

    //====== frequency division ======
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
        end else begin
            counter <= counter + 1;
        end
    end

    // integer
    integer gap;

    initial begin
        btn_m = 0;
        btn_r = 0;
        rst_n = 1;
        gap = 4;
        repeat(gap) @(negedge clk);
        rst_n = 0;
        repeat(gap) @(negedge clk);
        rst_n = 1;
        repeat(4) @(negedge d_clk);
        btn_m = 1;
        repeat(gap) @(negedge d_clk);
        btn_m = 0;
        repeat(gap) @(negedge d_clk);
        btn_r = 1;
        repeat(gap) @(negedge d_clk);
        btn_r = 0;
        repeat(gap) @(negedge d_clk);
        btn_m = 1;
        repeat(gap) @(negedge d_clk);
        btn_m = 0;
        repeat(gap) @(negedge d_clk);
        btn_r = 1;
        repeat(gap) @(negedge d_clk);
        btn_r = 0;
        repeat(gap) @(negedge d_clk);
        btn_r = 1;
        repeat(gap) @(negedge d_clk);
        btn_r = 0;
        repeat(gap) @(negedge d_clk);
        btn_m = 1;
        $finish;
    end

    tenthirty inst_tenthirty (
        .clk      (clk),
        .rst_n    (rst_n),
        .btn_m    (btn_m),
        .btn_r    (btn_r),
        .seg7_sel (seg7_sel),
        .seg7     (seg7),
        .seg7_l   (seg7_l),
        .led      (led)
    );



endmodule
