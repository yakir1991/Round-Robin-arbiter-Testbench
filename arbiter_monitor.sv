// arbiter_monitor.sv
class arbiter_monitor #(parameter HOSTS = 4);
    // Virtual interface handle
    virtual arbiter_if #(HOSTS) vif;
    
    // Mailbox to scoreboard for each host
    mailbox #(arbiter_transaction) mon2scb_mbox[HOSTS];
    
    // Transaction counters per host
    int num_transactions[HOSTS];
    
    // Semaphores to prevent multiple sampling
    semaphore host_sema[HOSTS];
    
    // Current active host
    int current_host;
    
    // Constructor
    function new(virtual arbiter_if #(HOSTS) vif, 
                mailbox #(arbiter_transaction) mon2scb_mbox[HOSTS]);
        this.vif = vif;
        this.mon2scb_mbox = mon2scb_mbox;
        foreach(num_transactions[i]) begin
            num_transactions[i] = 0;
            host_sema[i] = new(1);
        end
        $display("Time: %0t [Monitor] Created new monitor for %0d hosts", $time, HOSTS);
    endfunction

    // Main monitor task
    task run();
        $display("Time: %0t [Monitor] Starting monitor", $time);
        
        // Wait for reset
        wait(vif.reset_n);
        @(posedge vif.clk);
        current_host = 1; // Set priority to Host 1 after reset
        $display("Time: %0t [Monitor] Reset completed. Starting from Host 1.", $time);

        forever begin
            for (int i = 0; i < HOSTS; i++) begin
                // Check only current active host after reset
                if (i == current_host && (vif.rd[i] || vif.wr[i])) begin
                    monitor_host(i);
                    current_host = get_next_host(i);
                end
            end
            @(posedge vif.clk); // Wait for next clock cycle
        end
    endtask

    // Determine next host in round-robin
    function int get_next_host(int current);
        return (current + 1) % HOSTS;
    endfunction

    // Monitor single host
    task monitor_host(int host_id);
        if (host_sema[host_id].try_get()) begin
            begin
                arbiter_transaction trans;
                
                $display("\nTime: %0t [Monitor-Host%0d] Detected new transaction %0d (%s)", 
                        $time, host_id, num_transactions[host_id] + 1, 
                        vif.rd[host_id] ? "READ" : "WRITE");
                
                trans = new();
                collect_transaction(trans, host_id); // Collect transaction data from the host
                
                // Increment counter only after successful collection
                num_transactions[host_id]++;
                mon2scb_mbox[host_id].put(trans); // Send the transaction to the scoreboard
                host_sema[host_id].put();  // Ensure semaphore release
            end
        end
    endtask

    // Collect transaction from specific host
    task collect_transaction(arbiter_transaction trans, int host_id);
        trans.addr = vif.addr[host_id]; // Collect address
        trans.rd   = vif.rd[host_id];   // Collect read signal
        trans.wr   = vif.wr[host_id];   // Collect write signal
        trans.be   = vif.be[host_id];   // Collect byte enable
        trans.cpu  = vif.cpu[host_id];  // Collect CPU signal
        
        if (trans.wr) begin
            trans.data = vif.dwr[host_id]; // Collect data to write if write signal is active
        end
        
        trans.print_master($sformatf("Monitor-Host%0d", host_id), host_id); // Print master transaction details

        @(posedge vif.clk);
        
        // Collect slave signals
        trans.add_bus = vif.add_bus; // Collect address bus
        trans.byte_en = vif.byte_en;
        trans.wr_bus = vif.wr_bus;
        trans.rd_bus = vif.rd_bus;
        trans.data_bus_wr = vif.data_bus_wr;
        trans.data_bus_rd = vif.data_bus_rd;
        trans.cpu_bus = vif.cpu_bus;
        
        trans.print_slave($sformatf("Monitor-Host%0d", host_id), host_id);

        wait_for_response(trans, host_id);
    endtask

    // Wait for response for specific host
    task wait_for_response(arbiter_transaction trans, int host_id);
        int timeout_count = 0;
        const int TIMEOUT_LIMIT = 65535;
        bit got_response = 0;

        while (!got_response) begin
            @(posedge vif.clk);
            if (vif.ack[host_id] != 2'b00) begin
                trans.ack = vif.ack[host_id];
                if (trans.rd) begin
                    trans.rd_data = vif.drd[host_id];
                    trans.data_bus_rd = vif.data_bus_rd;
                end
                got_response = 1;
            end
            
            timeout_count++;
            if (timeout_count >= TIMEOUT_LIMIT) begin
                $error("Time: %0t [Monitor-Host%0d] Timeout waiting for response", 
                       $time, host_id);
                got_response = 1;
            end
        end
    endtask
endclass
