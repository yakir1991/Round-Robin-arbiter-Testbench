// arbiter_driver.sv
class arbiter_driver #(parameter HOSTS = 4);
    // Virtual interface handle with array access
    virtual arbiter_if #(HOSTS) vif;
    
    // Mailbox from generator
    mailbox #(arbiter_transaction) gen2drv_mbox;
    
    // Driver configuration
    int host_id;  // Which host this driver represents

    rand int unsigned delay;

    // Delay constraints
    constraint delay_c {
        delay inside {[1:10]}; // Random delay between 1-10 cycles
    }

    // Constructor
    function new(virtual arbiter_if #(HOSTS) vif, mailbox #(arbiter_transaction) gen2drv_mbox, int host_id);
        this.vif = vif;
        this.gen2drv_mbox = gen2drv_mbox;
        this.host_id = host_id;
        $display("Time: %0t [Driver-%0d] Created new driver", $time, host_id); // Display creation message
    endfunction

    // Random delay task
    task add_random_delay();
        if (!this.randomize()) begin
            $error("Time: %0t [Driver-%0d] Failed to randomize delay", $time, host_id); // Display error message if randomization fails
            return;
        end
        repeat(delay) @(posedge vif.clk); // Wait for a random number of clock cycles
    endtask

    // Main driver task
    task run();
        $display("Time: %0t [Driver-%0d] Starting driver", $time, host_id); // Display start message
        
        // Initialize interface signals for this host
        vif.addr[host_id] = 0;
        vif.rd[host_id]   = 0;
        vif.wr[host_id]   = 0;
        vif.be[host_id]   = 0;
        vif.dwr[host_id]  = 0;
        vif.cpu[host_id]  = 0;

        // Wait for reset
        wait(vif.reset_n);
        @(posedge vif.clk);

        forever begin
            arbiter_transaction trans;

            add_random_delay(); // Add random delay
            
            gen2drv_mbox.get(trans); // Get transaction from mailbox
            
            $display("Time: %0t [Driver-%0d] Driving transaction:", $time, host_id); // Display transaction message
            trans.print_master($sformatf("Driver-Host%0d", host_id), host_id); // Print transaction details
            
            drive_transaction(trans); // Drive the transaction
        end
    endtask

    // Drive single transaction
    task drive_transaction(arbiter_transaction trans);
        @(posedge vif.clk);
        
        // Drive signals for this host
        vif.addr[host_id] <= trans.addr;
        vif.rd[host_id]   <= trans.rd;
        vif.wr[host_id]   <= trans.wr;
        vif.be[host_id]   <= trans.be;
        vif.dwr[host_id]  <= trans.data;
        vif.cpu[host_id]  <= trans.cpu;

        // Wait for acknowledge
        wait_for_ack(trans);

        // Clear signals
        vif.addr[host_id] <= 0;
        vif.rd[host_id]   <= 0;
        vif.wr[host_id]   <= 0;
        vif.be[host_id]   <= 0;
        vif.dwr[host_id]  <= 0;
    endtask

    // Wait for acknowledge
    task wait_for_ack(arbiter_transaction trans);
        int timeout_count = 0;
        const int TIMEOUT_LIMIT = 65535;
        bit got_response = 0;

        while(!got_response) begin
            @(posedge vif.clk);
            if(vif.ack[host_id] != 2'b00) begin
                trans.ack = vif.ack[host_id];
                if(trans.rd) begin
                    trans.rd_data = vif.drd[host_id];
                end
                got_response = 1;
            end
            
            timeout_count++;
            if(timeout_count >= TIMEOUT_LIMIT) begin
                $error("Time: %0t [Driver-%0d] Timeout waiting for acknowledge", 
                    $time, host_id); // Display timeout error message
                got_response = 1;
            end
        end
    endtask
endclass