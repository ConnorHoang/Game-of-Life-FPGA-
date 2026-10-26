`timescale 1ns/1ps

module gol_tb();
    logic clk;
    logic SW;
    logic BOOT;
    logic _48b;

    // Instantiate your top module
    top u_top (
        .clk(clk),
        .SW(SW),
        .BOOT(BOOT),
        ._48b(_48b)
    );

    // Generate a 12 MHz clock (~83.33 ns period)
    always #41.66 clk = ~clk;

    initial begin
        // Tell Icarus Verilog to dump the simulation waveforms
        $dumpfile("gol.vcd");
        $dumpvars(0, gol_tb);

        // Initialize inputs
        clk = 0;
        SW = 1;
        BOOT = 1;

        // Run the simulation long enough to see board updates
        #500000; 
        
        $display("Simulation complete.");
        $finish;
    end
endmodule