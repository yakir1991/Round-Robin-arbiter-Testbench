// arbiter_transaction.sv
class arbiter_transaction;
    // Host ID
    int host_id;  // Added to track which host owns this transaction

    // Master signals
    rand bit [31:0] addr;    
    rand bit        rd;      
    rand bit        wr;      
    rand bit [3:0]  be;      
    rand bit [31:0] data;    
    bit            cpu;      
    
    // Master response fields
    bit [31:0] rd_data;      
    bit [1:0]  ack;          

    // Slave interface signals
    bit [31:0] add_bus;      // Address bus to slave
    bit [3:0]  byte_en;      // Byte enable to slave
    bit        wr_bus;       // Write signal to slave
    bit        rd_bus;       // Read signal to slave
    bit [31:0] data_bus_wr;  // Write data to slave
    bit [31:0] data_bus_rd;  // Read data from slave
    bit        ack_bus;      // Acknowledge from slave
    bit        cpu_bus;      // CPU indicator to slave
    
    // Constraints
    constraint c_ops {
        rd != wr;  // Only one operation active at a time
        rd == 1 -> wr == 0;
        wr == 1 -> rd == 0;
    }

    constraint c_be {
        be != 4'b0000;  // At least one bit must be set
    }

    // New constraint to ensure round-robin behavior
    constraint c_addr_unique {
        // Make sure addresses are unique per host to help debug
        addr[31:28] == host_id[3:0];  
    }

    // Constructor
    function new(bit cpu_value = 0, int host_id = 0);
        this.cpu = cpu_value; // Initialize CPU value
        this.host_id = host_id; // Initialize host ID
    endfunction

    // Print function for master signals
    function void print_master(string tag = "", int host_id = 0);
        $display("\nTime: %0t [%s] Transaction Master Signals (Host %0d):", $time, tag, host_id);
        $display("\tAddress: 0x%0h", addr);
        $display("\tOperation: %s", rd ? "READ" : (wr ? "WRITE" : "NONE"));
        $display("\tByte Enable: 0x%0h", be);
        if(wr) $display("\tWrite Data: 0x%0h", data);
        $display("\tCPU: %0b", cpu);
    endfunction

    function void print_slave(string tag = "", int host_id = 0);
        $display("\nTime: %0t [%s] Transaction Slave Signals (Host %0d):", $time, tag, host_id);
        $display("\tSlave Address Bus: 0x%0h", add_bus);
        $display("\tSlave Byte Enable: 0x%0h", byte_en);
        $display("\tSlave Write Bus: %b", wr_bus);
        $display("\tSlave Read Bus: %b", rd_bus);
        $display("\tSlave Write Data: 0x%0h", data_bus_wr);
        $display("\tSlave Read Data: 0x%0h", data_bus_rd);
        $display("\tSlave ACK: %b", ack_bus);
        $display("\tSlave CPU: %b", cpu_bus);
    endfunction
endclass