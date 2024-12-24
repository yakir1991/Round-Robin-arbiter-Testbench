class arbiter_scoreboard #(parameter HOSTS = 4);
    // Mailboxes
    mailbox #(arbiter_transaction) mon2scb_mbox[HOSTS];
    
    // Essential Statistics
    int num_transactions[HOSTS];
    int num_errors[HOSTS];
    
    // Round Robin Tracking
    int expected_host;
    int last_active_host;
    
    // Coverage variables
    int cov_host_id;
    bit cov_rd, cov_wr;
    bit [31:0] cov_addr;
    bit [3:0] cov_be;
    bit [1:0] cov_ack;
    bit cov_timeout;

    // Main coverage group
    covergroup arbiter_cg;
        // Host operations
        host_cp: coverpoint cov_host_id {
            bins hosts[] = {[0:HOSTS-1]};
        }
        
        // Operation type
        op_cp: coverpoint {cov_rd, cov_wr} {
            bins read = {2'b10};
            bins write = {2'b01};
            illegal_bins invalid = {2'b00, 2'b11};
        }
        
        // Address ranges
        addr_cp: coverpoint cov_addr {
            bins ranges[4] = {[0:32'hFFFFFFFF]};
        }
        
        // Byte enables
        be_cp: coverpoint cov_be {
            bins single_byte[] = {4'b0001, 4'b0010, 4'b0100, 4'b1000};
            bins word = {4'b1111};
            bins other_combinations = default;
        }
        
        // Response checking
        ack_cp: coverpoint cov_ack {
            bins normal = {2'b01}; // Normal acknowledgment
            bins timeout = {2'b10}; // Timeout acknowledgment
            bins error = {2'b11}; // Error acknowledgment
        }
        
        // Key crosses
        host_op_cross: cross host_cp, op_cp; // Cross coverage between host and operation type
        addr_be_cross: cross addr_cp, be_cp; // Cross coverage between address and byte enable
    endgroup

    // Constructor
    function new(mailbox #(arbiter_transaction) mon2scb_mbox[HOSTS]);
        this.mon2scb_mbox = mon2scb_mbox; // Initialize mailboxes
        this.expected_host = 1; // Initialize expected host to 1
        this.last_active_host = -1; // Initialize last active host to -1
        
        foreach(num_transactions[i]) begin
            num_transactions[i] = 0; // Initialize transaction counters
            num_errors[i] = 0; // Initialize error counters
        end
        
        arbiter_cg = new(); // Initialize coverage group
    endfunction

    // Main run task
    task run();
        fork
            for (int i = 0; i < HOSTS; i++) begin
                automatic int host_id = i;
                fork
                    process_transactions(host_id); // Process transactions for each host
                join_none
            end
        join_none
    endtask

    // Process transactions for a host
    task process_transactions(int host_id);
        forever begin
            arbiter_transaction trans;
            mon2scb_mbox[host_id].get(trans);
            
            // Update stats
            num_transactions[host_id]++;
            
            // Verify round robin order
            if (host_id != expected_host) begin
                $error("Time: %0t Host order violation. Expected: %0d, Got: %0d", 
                       $time, expected_host, host_id);
                num_errors[host_id]++;
            end
            expected_host = (host_id + 1) % HOSTS;
            
            // Basic transaction checks
            if (!check_transaction(trans, host_id)) begin
                num_errors[host_id]++;
            end
            
            // Sample coverage
            sample_coverage(trans, host_id);
        end
    endtask

    // Transaction checking
    function bit check_transaction(arbiter_transaction trans, int host_id);
        bit status = 1;
        
        // Check read/write exclusivity
        if (trans.rd && trans.wr) begin
            $error("Time: %0t Host %0d: Simultaneous read and write", $time, host_id);
            status = 0;
        end
        
        // Check byte enable validity
        if (trans.be == 4'b0000) begin
            $error("Time: %0t Host %0d: Invalid byte enable value", $time, host_id);
            status = 0;
        end
        
        // Check address validity
        if (trans.addr === 'x || trans.addr === 'z) begin
            $error("Time: %0t Host %0d: Invalid address value", $time, host_id);
            status = 0;
        end
        
        return status;
    endfunction

    // Coverage sampling
    function void sample_coverage(arbiter_transaction trans, int host_id);
        cov_host_id = host_id;
        cov_rd = trans.rd;
        cov_wr = trans.wr;
        cov_addr = trans.addr;
        cov_be = trans.be;
        cov_ack = trans.ack;
        cov_timeout = trans.ack[1];
        arbiter_cg.sample();
    endfunction

    // Report results
    function void report();
        int total_errors = 0;
        
        $display("\n=== Arbiter Scoreboard Report ===");
        
        for (int i = 0; i < HOSTS; i++) begin
            total_errors += num_errors[i];
            $display("\nHost %0d:", i);
            $display("  Transactions: %0d", num_transactions[i]);
            $display("  Errors: %0d", num_errors[i]);
        end
        
        $display("\nCoverage:");
        $display("  Overall: %.2f%%", arbiter_cg.get_coverage());
        $display("  Host-Operation Cross: %.2f%%", arbiter_cg.host_op_cross.get_coverage());
        $display("  Address-BE Cross: %.2f%%", arbiter_cg.addr_be_cross.get_coverage());
        
        $display("\nTest %s", total_errors == 0 ? "PASSED" : "FAILED");
        if (total_errors > 0) $display("Total Errors: %0d", total_errors);
        
        $display("===============================\n");
    endfunction

endclass