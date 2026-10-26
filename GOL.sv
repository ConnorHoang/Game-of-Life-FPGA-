// Conway's Game of Life on 8x8 LED Matrix for three seperate colors
`include "controller.sv"
`include "ws2812b.sv"

module top (
    input  logic clk,
    input  logic SW,
    input  logic BOOT,
    output logic _48b
);

    logic [63:0] red_seed [0:0];
    logic [63:0] green_seed [0:0];
    logic [63:0] blue_seed [0:0];

    logic [63:0] red_legacy;
    logic [63:0] green_legacy;
    logic [63:0] blue_legacy;

    logic [63:0] red_next;
    logic [63:0] green_next;
    logic [63:0] blue_next;

    initial begin
        $readmemh("seed_r.txt", red_seed);
        $readmemh("seed_g.txt", green_seed);
        $readmemh("seed_b.txt", blue_seed);
    end

    logic data_transfered = 1'b0;

    // Controller and WS2812B
    logic [5:0]  pixel;
    logic [4:0]  frame;
    logic        load_sreg;
    logic        transmit_pixel;
    logic        shift;
    logic        ws2812b_out;
    logic [23:0] shift_reg = 24'd0;

    assign _48b = ws2812b_out;

    controller u_controller (
        .clk(clk),
        .load_sreg(load_sreg),
        .transmit_pixel(transmit_pixel),
        .pixel(pixel),
        .frame(frame)
    );

    ws2812b u_ws2812b (
        .clk(clk),
        .serial_in(shift_reg[23]),
        .transmit(transmit_pixel),
        .ws2812b_out(ws2812b_out),
        .shift(shift)
    );

    function automatic logic [3:0] find_neighbors(input logic [63:0] b, input logic [5:0] idx);
        logic [2:0] row, col;
        logic [2:0] row_up, row_dn, col_lf, col_rt;
        begin
            row = idx[5:3];
            col = idx[2:0];

            row_up = row - 3'd1;
            row_dn = row + 3'd1;
            col_lf = col - 3'd1;
            col_rt = col + 3'd1;

            // Top left to bottom right, excluding center
            find_neighbors = b[{row_up, col_lf}] + b[{row_up, col}] + b[{row_up, col_rt}] + b[{row, col_lf}] 
                              + b[{row, col_rt}] + b[{row_dn, col_lf}] + b[{row_dn, col}] + b[{row_dn, col_rt}];
        end
    endfunction

    // GOL rules
    function automatic logic calc_next_cell(input logic alive, input logic [3:0] living_neighbors);
            if (alive)
                calc_next_cell = (living_neighbors == 4'd2 || living_neighbors == 4'd3);
            else
                calc_next_cell = (living_neighbors == 4'd3);
    endfunction

    // Sweep through all nodes
    always_comb begin
        for (int i = 0; i < 64; i = i + 1) begin
            red_next[i]   = calc_next_cell(red_legacy[i],   find_neighbors(red_legacy,   i[5:0]));
            green_next[i] = calc_next_cell(green_legacy[i], find_neighbors(green_legacy, i[5:0]));
            blue_next[i]  = calc_next_cell(blue_legacy[i],  find_neighbors(blue_legacy,  i[5:0]));
        end
    end

    logic [4:0] last_frame = 5'd0;
    logic [3:0] delay_count = 4'd0;

    always_ff @(posedge clk) begin
        // Move data to proper place and format
        if (!data_transfered) begin
            red_legacy   <= red_seed[0]; 
            green_legacy <= green_seed[0];
            blue_legacy  <= blue_seed[0];
            data_transfered <= 1'b1;
            last_frame <= frame;
        end
        
        last_frame <= frame;
         // Keeps fom running in parralel with above code
        if (frame != last_frame) begin
            // Slow down board updates so code can run and display is good speed for humans
            if (delay_count == 4'b100) begin
                delay_count <= 4'b000;
                red_legacy   <= red_next;
                green_legacy <= green_next;
                blue_legacy  <= blue_next;
            end 
            else begin
                delay_count <= delay_count + 4'b001;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (load_sreg) begin
            shift_reg <= {
                green_legacy[pixel] * 8'h20,
                red_legacy[pixel] * 8'h20,
                blue_legacy[pixel] * 8'h20
            };
        end
        else if (shift) begin
            shift_reg <= {shift_reg[22:0], 1'b0};
        end
    end
endmodule