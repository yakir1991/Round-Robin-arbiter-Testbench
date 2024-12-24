// arbiter_generator.sv
class arbiter_generator #(parameter HOSTS = 4);
    // Array of mailboxes to drivers
    mailbox #(arbiter_transaction) gen2drv_mbox[HOSTS];
    
    // Generator configuration
    int num_transactions;
    bit [HOSTS-1:0] cpu_values; // One CPU bit per host

    // Constructor
    function new(mailbox #(arbiter_transaction) gen2drv_mbox[HOSTS], 
                int num_transactions,
                bit [HOSTS-1:0] cpu_values);
        this.gen2drv_mbox = gen2drv_mbox; // Initialize mailboxes
        this.num_transactions = num_transactions; // Initialize number of transactions
        this.cpu_values = cpu_values; // Initialize CPU values
        $display("Time: %0t [Generator] Created for %0d hosts", $time, HOSTS); // Display creation message
    endfunction

    // Main generation task - now generates for all hosts
    task run();
        fork
            for(int i = 0; i < HOSTS; i++) begin
                automatic int host_id = i;
                generate_for_host(host_id); // Generate transactions for each host
            end
        join_none
    endtask

    // Generate transactions for a specific host
    task generate_for_host(int host_id);
        $display("Time: %0t [Generator-%0d] Starting transaction generation", $time, host_id); // Display start message

        repeat(num_transactions) begin
            arbiter_transaction trans;
            trans = new(cpu_values[host_id], host_id);  // Pass both CPU value and host_id
            // Generate transaction details here (e.g., address, read/write, data, etc.)

            gen2drv_mbox[host_id].put(trans); // Send transaction to the corresponding driver
        end
    endtask
endclass