// arbiter_if.sv
interface arbiter_if #(parameter HOSTS = 4) (input logic clk, reset_n);
    // Host Interface Array
    logic [31:0] addr     [HOSTS]; // Address array for each host
    logic        rd       [HOSTS]; // Read signal array for each host
    logic        wr       [HOSTS]; // Write signal array for each host
    logic [3:0]  be       [HOSTS]; // Byte enable array for each host
    logic [31:0] dwr      [HOSTS]; // Data write array for each host
    logic [31:0] drd      [HOSTS]; // Data read array for each host
    logic [1:0]  ack      [HOSTS]; // Acknowledge signal array for each host
    logic        cpu      [HOSTS]; // CPU signal array for each host
    
    // Slave Interface
    logic [31:0] add_bus;     // Address bus for slave interface
    logic [3:0]  byte_en;     // Byte enable for slave interface
    logic        wr_bus;      // Write bus for slave interface
    logic        rd_bus;      // Read bus for slave interface
    logic [31:0] data_bus_wr; // Data write bus for slave interface
    logic [31:0] data_bus_rd; // Data read bus for slave interface
    logic        ack_bus;     // Acknowledge bus for slave interface
    logic        cpu_bus;     // CPU bus for slave interface
endinterface