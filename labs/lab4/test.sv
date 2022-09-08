program automatic test(router_io.TB rtr_io);
  //Lab 4 - Task 8, Step 2
  //
  //Include the Packet.sv file
  //ToDo

  int run_for_n_packets;      // number of packets to test
  bit[3:0] sa;                        // source address
  bit[3:0] da;                        // destination address
  logic[7:0] payload[$];              // expected packet data array
  logic[7:0] pkt2cmp_payload[$];      // actual packet data array
  //Lab 4 - Task 8, Step 2
  //
  //Declare and construct two Packets pkt2send and pkt2cmp
  //ToDo


  initial begin
    
    run_for_n_packets = 2000;
      reset();
    repeat(run_for_n_packets) begin

      gen();
      
      fork
        send();
        recv();
      join

      check();
    
    end
    repeat(10) @(rtr_io.cb);
    
  end
  
  task reset();
    rtr_io.reset_n = 1'b0;
    rtr_io.cb.frame_n <= '1;
    rtr_io.cb.valid_n <= '1;
	repeat(2) @rtr_io.cb;
    rtr_io.cb.reset_n <= 1'b1;
    repeat(15) @(rtr_io.cb);
  endtask: reset

  task gen();
  
    //Lab 4 - Task 9, Step 1
    //
    //Delete all existing code in gen()
    //ToDo
    sa = $urandom;
    da = $urandom;
    payload.delete(); //clear previous data
    repeat($urandom_range(4,2))
    payload.push_back($urandom);
    //Lab 4 - Task 9, Step 2
    //
    //Declare a static int pkts_generated (initialize to 0)
    //ToDo

    //Lab 4 - Task 9, Step 3
    //
    //Give a unique name string to pkt2send using pkts_generated
    //ToDo

    //Lab 4 - Task 9, Step 4
    //
    //Randomize the pkt2send object
    //ToDo

    //Lab 4 - Task 9, Step 5
    //
    //Update sa and da to the sa and da of pkt2send
    //Update payload to payload of pkt2send
    //ToDo

  endtask: gen

  task send();
  
    send_addrs();
    send_pad();
    send_payload();

  endtask: send

  task send_addrs();
  
    rtr_io.cb.frame_n[sa] <= 1'b0; //start of packet
    for(int i=0; i<4; i++) begin
      rtr_io.cb.din[sa] <= da[i]; //i'th bit of da
      @(rtr_io.cb);
    end

  endtask: send_addrs

  task send_pad();
  
    rtr_io.cb.frame_n[sa] <= 1'b0;
    rtr_io.cb.din[sa] <= 1'b1;
    rtr_io.cb.valid_n[sa] <= 1'b1;
    repeat(5) @(rtr_io.cb);

  endtask: send_pad

  task send_payload();
  
    foreach(payload[index])
      for(int i=0; i<8; i++) begin
        rtr_io.cb.din[sa] <= payload[index][i];
        rtr_io.cb.valid_n[sa] <= 1'b0; //driving a valid bit
        rtr_io.cb.frame_n[sa] <= ((i == 7) && (index == (payload.size() - 1)));
        @(rtr_io.cb);
      end
    rtr_io.cb.valid_n[sa] <= 1'b1;
  endtask: send_payload

  task recv();

    //Lab 4 - Task 10, Step 1
    //
    //Add static int pkt_cnt before the call to get_payload()
    //ToDo

    get_payload();
    //Lab 4 - Task 10, Step 2
    //
    //Assign pkt2cmp.da with global da
    //ToDo

    //Lab 4 - Task 10, Step 3
    //
    //Assign pkt2cmp.payload with pkt2cmp_payload
    //ToDo

    //Lab 4 - Task 10, Step 4
    //
    //Set a unique name for pkt2cmp. Use pkt_cnt
    //ToDo
  
  endtask: recv

  task get_payload();

    pkt2cmp_payload.delete();

    fork
      begin: wd_timer_fork
      fork: frameo_wd_timer
        //Do not use @(negedge rtr_io.cb.frameo_n[da]);
		//This may cause timing issues because of how the LRM defines it.
		begin
		  wait(rtr_io.cb.frameo_n[da] != 0);
		  @(rtr_io.cb iff(rtr_io.cb.frameo_n[da] == 0 ));
		end
        begin                              //this is another thread
          repeat(1000) @(rtr_io.cb);
          $display("\n%m\n[ERROR]%t Frame signal timed out!\n", $realtime);
          $finish;
        end
      join_any: frameo_wd_timer
      disable fork;
      end: wd_timer_fork
    join

    forever begin
      logic[7:0] datum;
      for(int i=0; i<8; i=i)  begin //i=i prevents VCS warning messages
        if(!rtr_io.cb.valido_n[da])
          datum[i++] = rtr_io.cb.dout[da];
        if(rtr_io.cb.frameo_n[da])
          if(i==8) begin //byte alligned
            pkt2cmp_payload.push_back(datum);
            return;      //done with payload
          end

          else begin
            $display("\n%m\n[ERROR]%t Packet payload not byte aligned!\n", $realtime);
            $finish;
          end
        @(rtr_io.cb);
      end
      pkt2cmp_payload.push_back(datum);
    end
  endtask: get_payload

  //Lab 4 - Task 12, Step 1
  //
  //Delete the compare routine
  //ToDo Caution!! Do only after Step 11

  function bit compare(ref string message);

    //Lab 3 - Task 4, Step 2
    //
    //In compare() compare data payload[$] with pkt2cmp_payload[$]
    //If sizes do not match
    //   set string argument with description of error
    //   terminate subroutine by returning a 0
    //If data matches (you can directly compare arrays using ==)
    //   set string argument with description of success
    //   terminate subroutine successfully by returning a 1
    //If data does not match
    //   set string argument with description of error
    //   terminate subroutine by returning a 0
    //ToDo

    if(payload.size() != pkt2cmp_payload.size()) begin
      message = "Payload size Mismatch:\n";
      message = { message, $sformatf("payload.size() = %0d, pkt2cmp_payload.size() = %0d\n", payload.size(), pkt2cmp_payload.size()) };
      return (0);
    end
    if(payload == pkt2cmp_payload) ;
    else begin
      message = "Payload Content Mismatch:\n";
      message = { message, $sformatf("Packet Sent:   %p\nPkt Received:   %p", payload, pkt2cmp_payload) };
      return (0);
    end
    message = "Successfully Compared";
    return(1);
  endfunction: compare

  function void check();

    string message;
    static int pkts_checked = 0;

    //Lab 4 - Task 11, Step 1
    //
    //Replace the compare call with call to compare of pkt2send
    //ToDo
    if (!compare(message)) begin
      $display("\n%m\n[ERROR]%t Packet #%0d %s\n", $realtime, pkts_checked, message);
      //Lab 4 - Task 11, Step 2
      //
      //make use of the Packet's display method when error is detected
      //ToDo

      $finish;
    end
    $display("[NOTE]%t Packet #%0d %s", $realtime, pkts_checked++, message);
  endfunction: check

endprogram: test
