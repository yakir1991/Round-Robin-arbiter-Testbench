// arbiter_responder.sv
class slave_responder;
    // Virtual interface handle
    virtual arbiter_if vif; // Virtual interface to communicate with the DUT
    
    // Transaction counter
    int num_transactions; // Counter for the number of transactions handled
    
    // Constructor
    function new(virtual arbiter_if vif);
        this.vif = vif; // Initialize the virtual interface
        this.num_transactions = 0; // Initialize the transaction counter
        $display("Time: %0t [Responder] Created new responder", $time); // Display creation message
    endfunction

    // Main responder task
    task run();
        $display("Time: %0t [Responder] Starting responder", $time); // Display start message
        
        // Initialize response signals
        vif.ack_bus = 0; // Initialize acknowledge bus to 0
        vif.data_bus_rd = 0; // Initialize data read bus to 0
        $display("Time: %0t [Responder] Initialized response signals to 0", $time); // Display initialization message

        // Wait for reset
        $display("Time: %0t [Responder] Waiting for reset", $time); // Display waiting for reset message
        wait(vif.reset_n); 
        $display("Time: %0t [Responder] Reset completed", $time); // Display reset completion message

        forever begin
            @(posedge vif.clk);
            if(vif.rd_bus || vif.wr_bus) begin
                num_transactions++; // Increment transaction counter
                $display("\nTime: %0t [Responder] Detected new transaction %0d (%s)", 
                        $time, num_transactions, vif.rd_bus ? "READ" : "WRITE"); // Display transaction detection message
                
                respond_to_transaction(); // Call the response generation task
            end
        end
    endtask

    // Response generation task
    task respond_to_transaction();
        $display("Time: %0t [Responder] Generating response for transaction %0d", 
                 $time, num_transactions); // Display response generation message
        
        // Set acknowledge
        vif.ack_bus = 1'b1; // Set acknowledge bus to 1
        $display("Time: %0t [Responder] Setting ack_bus = 1", $time); // Display acknowledge setting message
        
        // For read operations, provide read data
        if(vif.rd_bus) begin
            vif.data_bus_rd = $urandom(); // Generate random read data
            $display("Time: %0t [Responder] Generated read data = 0x%h", 
                     $time, vif.data_bus_rd); // Display generated read data
        end
        
        @(posedge vif.clk);
        
        // Clear response
        $display("Time: %0t [Responder] Clearing response signals", $time); // Display clearing response message
        vif.ack_bus = 1'b0; // Clear acknowledge bus
        vif.data_bus_rd = 0; // Clear data read bus
        
        $display("Time: %0t [Responder] Completed transaction %0d", 
                 $time, num_transactions); // Display transaction completion message
    endtask

    // Print statistics
    function void report();
        $display("\n=== Responder Statistics ===");
        $display("Total Transactions Handled: %0d", num_transactions); // Display total transactions handled
        $display("=========================\n");
    endfunction
endclass