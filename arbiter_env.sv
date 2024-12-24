// arbiter_env.sv
class arbiter_env #(parameter HOSTS = 4);
   // Components
   arbiter_generator  #(HOSTS) generator; // Generator component
   arbiter_driver     #(HOSTS) drivers[HOSTS]; // Array of driver components
   arbiter_monitor    #(HOSTS) monitor; // Monitor component
   arbiter_scoreboard #(HOSTS) scoreboard; // Scoreboard component
   slave_responder    responder; // Responder component
   
   // Mailboxes
   mailbox #(arbiter_transaction) gen2drv_mbox[HOSTS]; // Mailboxes from generator to drivers
   mailbox #(arbiter_transaction) mon2scb_mbox[HOSTS]; // Mailboxes from monitor to scoreboard
   
   // Virtual interface
   virtual arbiter_if #(HOSTS) vif; // Virtual interface for communication with DUT
   
   // Configuration
   bit [HOSTS-1:0] cpu_values = 4'b1111; // Default CPU settings
   int num_transactions = 100; // Number of transactions to generate
   
   // Constructor
   function new(virtual arbiter_if #(HOSTS) vif);
       this.vif = vif;
       
       // Create mailboxes for each host
       for(int i = 0; i < HOSTS; i++) begin
           gen2drv_mbox[i] = new();
           mon2scb_mbox[i] = new();
       end
       
       // Create components
       generator   = new(gen2drv_mbox, num_transactions, cpu_values); // Create generator
       for(int i = 0; i < HOSTS; i++) begin
           drivers[i] = new(vif, gen2drv_mbox[i], i); // Create drivers
       end
       monitor    = new(vif, mon2scb_mbox); // Create monitor
       scoreboard = new(mon2scb_mbox); // Create scoreboard
       responder  = new(vif); // Create responder
       
       $display("Time: %0t [Environment] Created environment", $time); // Display creation message
   endfunction
   
    // Run task 
    task run();
        $display("Time: %0t [Environment] Starting environment", $time); // Display start message
        
        fork
            // Start generator for all hosts
            generator.run();
            
            // Start all drivers
            fork
                begin
                    // Start each driver in its own thread
                    for(int i = 0; i < HOSTS; i++) begin
                        automatic int host_id = i;
                        fork
                            begin
                                // Start specific driver
                                $display("Time: %0t [Environment] Starting driver %0d", $time, host_id);
                                drivers[host_id].run();
                            end
                        join_none
                    end
                end
            join_none
            
            // Start monitor, scoreboard and responder
            monitor.run();
            scoreboard.run();
            responder.run();
        join_none
        
        // Wait for all transactions to complete
        wait_for_completion();
    endtask

   // Wait for all transactions to complete
   task wait_for_completion();
       int transactions_per_host[HOSTS]; // Array to store the number of transactions per host
       bit all_done; // Flag to indicate if all transactions are done
       
       forever begin
           all_done = 1; // Assume all transactions are done
           for(int i = 0; i < HOSTS; i++) begin
               transactions_per_host[i] = scoreboard.num_transactions[i]; // Get the number of transactions for each host
               if(transactions_per_host[i] < num_transactions) begin
                   all_done = 0; // If any host has not completed all transactions, set flag to 0
               end
           end
           
           if(all_done) break; // If all transactions are done, exit the loop
           
           @(posedge vif.clk); // Wait for the next clock cycle
       end
   endtask
   
   // Report results
   function void report();
       $display("\n=== Environment Report ===");
       scoreboard.report(); // Report scoreboard results
       responder.report(); // Report responder results
       $display("=========================\n");
   endfunction
endclass