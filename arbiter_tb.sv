// arbiter_tb.sv
// Testbench for the arbiter module
// Author: Yakir Aqua

module arbiter_tb;
    // Clock and reset
    logic clk; // Clock signal
    logic reset_n; // Active-low reset signal
    
    // Parameters
    parameter HOSTS = 4; // Number of hosts
    
    // Interface instance
    arbiter_if #(HOSTS) intf(clk, reset_n); // Interface instance for communication with DUT
    
    // Environment instance
    arbiter_env #(HOSTS) env; // Environment instance for the testbench
    
    // DUT instance
    arbiter dut (
        // Master Host (Host 0)
        .mcpu(intf.cpu[0]), // CPU signal for master host
        .maddr(intf.addr[0]), // Address for master host
        .mrd(intf.rd[0]), // Read signal for master host
        .mwr(intf.wr[0]), // Write signal for master host
        .mbe(intf.be[0]), // Byte enable for master host
        .mdwr(intf.dwr[0]), // Data write for master host
        .mdrd(intf.drd[0]), // Data read for master host
        .mack(intf.ack[0]), // Acknowledge signal for master host
        
        // Slave Host (Host 1)
        .scpu(intf.cpu[1]), // CPU signal for slave host
        .saddr(intf.addr[1]), // Address for slave host
        .srd(intf.rd[1]), // Read signal for slave host
        .swr(intf.wr[1]), // Write signal for slave host
        .sbe(intf.be[1]), // Byte enable for slave host
        .sdwr(intf.dwr[1]), // Data write for slave host
        .sdrd(intf.drd[1]), // Data read for slave host
        .sack(intf.ack[1]), // Acknowledge signal for slave host
        
        // Test Host (Host 2)
        .tcpu(intf.cpu[2]), // CPU signal for test host
        .taddr(intf.addr[2]), // Address for test host
        .trd(intf.rd[2]), // Read signal for test host
        .twr(intf.wr[2]), // Write signal for test host
        .tbe(intf.be[2]), // Byte enable for test host
        .tdwr(intf.dwr[2]), // Data write for test host
        .tdrd(intf.drd[2]), // Data read for test host
        .tack(intf.ack[2]), // Acknowledge signal for test host
        
        // Extra Host (Host 3)
        .ecpu(intf.cpu[3]), // CPU signal for extra host
        .eaddr(intf.addr[3]), // Address for extra host
        .erd(intf.rd[3]), // Read signal for extra host
        .ewr(intf.wr[3]), // Write signal for extra host
        .ebe(intf.be[3]), // Byte enable for extra host
        .edwr(intf.dwr[3]), // Data write for extra host
        .edrd(intf.drd[3]), // Data read for extra host
        .eack(intf.ack[3]), // Acknowledge signal for extra host
        
        // Slave interface
        .add_bus(intf.add_bus),
        .byte_en(intf.byte_en),
        .wr_bus(intf.wr_bus),
        .rd_bus(intf.rd_bus),
        .data_bus_wr(intf.data_bus_wr),
        .data_bus_rd(intf.data_bus_rd),
        .ack_bus(intf.ack_bus),
        .cpu_bus(intf.cpu_bus),
        
        // Clock and reset
        .clk(clk),
        .reset_n(reset_n)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test flow
    initial begin
        // Initialize
        reset_n = 0;
        
        // Create environment
        env = new(intf);
        
        // Apply reset
        repeat(5) @(posedge clk);
        reset_n = 1;
        
        // Run test
        env.run();
        env.report();
        $finish;
    end

    // Timeout watchdog
    initial begin
        #100000;  // Adjust timeout value as needed
        $display("Testbench timeout!");
        env.report();
        $finish;
    end

    // Dump waves
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars();
    end

    // Bind assertions to DUT
    bind arbiter arbiter_assertions #(
        .HOSTS(4)  // השתמש בערך קבוע במקום במשתנה HOSTS
    ) assertions_inst (
        .clk(clk),
        .reset_n(reset_n),
        .addr('{maddr, saddr, taddr, eaddr}),
        .rd('{mrd, srd, trd, erd}),
        .wr('{mwr, swr, twr, ewr}),
        .be('{mbe, sbe, tbe, ebe}),
        .dwr('{mdwr, sdwr, tdwr, edwr}),
        .drd('{mdrd, sdrd, tdrd, edrd}),
        .ack('{mack, sack, tack, eack}),
        .cpu('{mcpu, scpu, tcpu, ecpu}),
        .add_bus(add_bus),
        .byte_en(byte_en),
        .wr_bus(wr_bus),
        .rd_bus(rd_bus),
        .data_bus_wr(data_bus_wr),
        .data_bus_rd(data_bus_rd),
        .ack_bus(ack_bus),
        .cpu_bus(cpu_bus)
    );
endmodule