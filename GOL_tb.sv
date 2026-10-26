`timescale 1ns/1ps

module gol_tb();
    logic clk;
    logic SW;
    logic BOOT;
    logic _48b;

    // Instantiate top module
    top u_top (
        .clk(clk),
        .SW(SW),
        .BOOT(BOOT),
        ._48b(_48b)
    );

    // Generate a 12 MHz clock
    always #41.66 clk = ~clk;

    initial begin
        $dumpfile("gol.vcd");
        // $dumpvars(0, gol_tb);
        $dumpvars(0, _48b, u_top.frame, u_top.delay_count, u_top.red_legacy, u_top.green_legacy, u_top.blue_legacy, 
            u_top.red_next,   u_top.green_next,   u_top.blue_next);

        // Initialize inputs
        clk = 0;
        SW = 1;
        BOOT = 1;

        #350000000; 
        
        $display("Simulation complete.");
        $finish;
    end
endmodule