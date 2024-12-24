module arbiter_assertions #(parameter HOSTS = 4) (
    input logic clk,
    input logic reset_n,
    
    // Host Interface Array
    input logic [31:0] addr     [HOSTS], // Address array for each host
    input logic        rd       [HOSTS], // Read signal array for each host
    input logic        wr       [HOSTS], // Write signal array for each host
    input logic [3:0]  be       [HOSTS], // Byte enable array for each host
    input logic [31:0] dwr      [HOSTS], // Data write array for each host
    input logic [31:0] drd      [HOSTS], // Data read array for each host
    input logic [1:0]  ack      [HOSTS], // Acknowledge signal array for each host
    input logic        cpu      [HOSTS], // CPU signal array for each host
    
    // Slave Interface
    input logic [31:0] add_bus,     // Address bus for slave interface
    input logic [3:0]  byte_en,     // Byte enable for slave interface
    input logic        wr_bus,      // Write bus for slave interface
    input logic        rd_bus,      // Read bus for slave interface
    input logic [31:0] data_bus_wr, // Data write bus for slave interface
    input logic [31:0] data_bus_rd, // Data read bus for slave interface
    input logic        ack_bus,     // Acknowledge bus for slave interface
    input logic        cpu_bus      // CPU bus for slave interface
);

    // Properties
    
    // 1. Only one read or write can be active at a time
    property exclusive_rd_wr;
        @(posedge clk) disable iff (!reset_n)
        $onehot0({rd_bus, wr_bus}); // Ensure only one of rd_bus or wr_bus is active
    endproperty

    // 2. After reset, first active host should be host 1
    property first_host_after_reset;
        @(posedge clk)
        $rose(reset_n) |=> (rd[1] || wr[1])[->1]; // Ensure host 1 is the first active host after reset
    endproperty

    // 3. Verify byte enable is never zero during active transaction
    property valid_byte_enable;
        @(posedge clk) disable iff (!reset_n)
        (rd_bus || wr_bus) |-> (byte_en != 4'b0000);
    endproperty

    // 4. Verify response timing - ack must come within 16 cycles
    property ack_timing;
        @(posedge clk) disable iff (!reset_n)
        (rd_bus || wr_bus) |-> ##[1:16] ack_bus;
    endproperty


    // Assertions
    assert property (exclusive_rd_wr)
        else $error("Violation: Both read and write active simultaneously");

    assert property (first_host_after_reset)
        else $error("Violation: First host after reset was not host 1");

    assert property (valid_byte_enable)
        else $error("Violation: Invalid byte enable value during transaction");

    assert property (ack_timing)
        else $error("Violation: ACK response timing exceeded limit");


    // Coverage
    covergroup arbiter_cov @(posedge clk);
        rd_wr_cp: coverpoint {rd_bus, wr_bus} {
            bins read = {2'b10};
            bins write = {2'b01};
            bins idle = {2'b00};
            illegal_bins both = {2'b11};
        }
    endgroup

    arbiter_cov cg = new();

endmodule