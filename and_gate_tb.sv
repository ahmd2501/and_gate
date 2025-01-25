// class transaction;
//     rand bit a;
//     rand bit b;
//     bit y;

//     function void display(input string tag);
//         $display("[%0s] : a = %0b, b=%0b, y=%0b",tag,a,b,y);
//     endfunction


//     function transaction copy();
//         copy=new();
//         copy.a=this.a;
//         copy.b=this.b;
//         copy.y=this.y;
//     endfunction

// endclass

// class generator;
//     transaction tr;
//     mailbox #(transaction)mbx;
//     event done;
//     int count=0;
//     event drvnext;

//     function new(mailbox #(transaction)mbx);
//         this.mbx=mbx;
//         tr=new();
//     endfunction
//     task run();
//         repeat (count)begin
//             assert(tr.randomize) else $error("[GEN]: Randomization Failed");
//             mbx.put(tr.copy);
//             tr.display("[GEN]");
//             @(drvnext)
//         end
//         ->done;
//     endtask

// endclass

// class driver;
//     virtual and_gate_if vif;
//     transaction tr;
//     mailbox #(transaction) mbx;
//     event drvnext;
//     function new(mailbox #(transaction)mbx);
//         this.mbx=mbx;
//     endfunction
//     task run();
//         forever  begin
//             mbx.get(tr);
//             vif.a<=tr.a;
//             vif.b<=tr.b;
//             #10;
//             tr.y=vif.y;
//             tr.display("DRV");
//             ->drvnext;
//         end
//     endtask

// endclass

// class monitor;
//     transaction tr;
//     mailbox #(bit) mbx;
//     virtual and_gate_if vif;
//     function new(mailbox #(bit) mbx);
//         this.mbx=mbx;
//     endfunction
//     task run();
//         forever begin
//             @(posedge vif.a or posedge vif.b);
//             #1;
//             mbx.put(vif.y);
//             $display("[MON] : y%0b",vif.y)
//         end
//     endtask

// endclass

// class scoreboard;
//     mailbox #(bit) mbx;
//     bit expected_y;
//     bit actual_y;
//     function new(mailbox #(bit) mbx);
//         this.mbx=mbx;
//     endfunction
//     task run();
//         forever begin
//             mbx.get(actual_y);
//             expected_y=vif.a & vif.b;
//             if(actual_y === expected_y)
//                 $display("[SCO] : MATCH : Expected = %0b, Actual = %0b",expected_y,actual_y);
//             else $error("[SCO] : MISMATCH : Expected = %0b, Actual = %0b", expected_y,actual_y);
//         end
//     endtask
// endclass

// class environment;
//     generator gen;
//     driver drv;
//     monitor mon;
//     scoreboard sco;

//     mailbox #(transaction)mbx;
//     mailbox #(bit) mbx_mon;
//     virtual and_gate_if vif;
//     function new(virtual and_gate_if vif);
//         mbx=new();
//         mbx_mon=new(mbx);
//         gen=new(mbx);
//         drv=new(mbx);
//         mon=new(mbx_mon);
//         sco=new(mbx_mon);

//         this.vif=vif;
//         drv.vif=this.vif;
//         mon.vif=this.vif;
//     endfunction

//     task rub();
//         gen.count=10;
//         fork
//             gen.run();
//             drv.run();
//             mon.run();
//             sco.run();
//         join_any
//     endtask
// endclass

//  module tb;
//     and_gate_if vif();
//     and_gate dut(vif.a,vif.b,vif.y);
//     environment env;
//     initial begin
//         env=new(vif);
//         env.run();
//         #100;
//         $finish;
//     end
//     initial begin 
//         $dumpfile("dump.vcd");
//         $dumpvars;
//     end
//  endmodule

class transaction;
    rand bit a;  // Input A
    rand bit b;  // Input B
    bit y;       // Output Y

    // Display function for debugging
    function void display(input string tag);
        $display("[%0s] : a = %0b, b = %0b, y = %0b", tag, a, b, y);
    endfunction

    // Transaction copy function
    function transaction copy();
        copy = new();
        copy.a = this.a;
        copy.b = this.b;
        copy.y = this.y;
    endfunction
endclass

class generator;
    transaction tr;
    mailbox #(transaction) mbx;
    event done;
    int count = 0;  // Number of transactions to generate
    event drvnext;  // Signal to driver

    // Constructor
    function new(mailbox #(transaction) mbx);
        this.mbx = mbx;
        tr = new();
    endfunction

    // Task to generate transactions
    task run();
        repeat (count) begin
            assert(tr.randomize) else $error("[GEN] : Randomization Failed");
            mbx.put(tr.copy);
            tr.display("GEN");
            @(drvnext);  // Wait for driver to finish
        end
        -> done;  // Signal that generation is complete
    endtask
endclass

class driver;
    virtual and_gate_if vif;  // Virtual interface for AND gate
    transaction tr;
    mailbox #(transaction) mbx;
    event drvnext;

    // Constructor
    function new(mailbox #(transaction) mbx);
        this.mbx = mbx;
    endfunction

    // Task to drive transactions
    task run();
        forever begin
            mbx.get(tr);  // Get transaction from generator
            vif.a <= tr.a;
            vif.b <= tr.b;
            #10;  // Wait for output to stabilize
            tr.y = vif.y;  // Capture output
            tr.display("DRV");
            ->drvnext;  // Signal generator to proceed
        end
    endtask
endclass

class monitor;
    transaction tr;
    mailbox #(bit) mbx;  // Mailbox to send output to scoreboard
    virtual and_gate_if vif;

    // Constructor
    function new(mailbox #(bit) mbx);
        this.mbx = mbx;
    endfunction

    // Task to monitor the output
    task run();
        forever begin
            @(posedge vif.a or posedge vif.b);  // Trigger on input change
            #1;  // Small delay to allow output to stabilize
            mbx.put(vif.y);  // Send output to scoreboard
            $display("[MON] : y = %0b", vif.y);
        end
    endtask
endclass

class scoreboard;
    mailbox #(bit) mbx;  // Mailbox to receive output from monitor
    bit expected_y;      // Expected output
    bit actual_y;        // Actual output

    // Constructor
    function new(mailbox #(bit) mbx);
        this.mbx = mbx;
    endfunction

    // Task to compare expected and actual outputs
    task run();
        forever begin
            mbx.get(actual_y);  // Get output from monitor
            expected_y = vif.a & vif.b;  // Calculate expected output
            if (actual_y === expected_y)
                $display("[SCO] : MATCH : Expected = %0b, Actual = %0b", expected_y, actual_y);
            else
                $error("[SCO] : MISMATCH : Expected = %0b, Actual = %0b", expected_y, actual_y);
        end
    endtask
endclass

class environment;
    generator gen;
    driver drv;
    monitor mon;
    scoreboard sco;

    mailbox #(transaction) mbx;  // Generator -> Driver
    mailbox #(bit) mbx_mon;      // Monitor -> Scoreboard

    virtual and_gate_if vif;

    // Constructor
    function new(virtual and_gate_if vif);
        mbx = new();
        mbx_mon = new();
        gen = new(mbx);
        drv = new(mbx);
        mon = new(mbx_mon);
        sco = new(mbx_mon);

        this.vif = vif;
        drv.vif = this.vif;
        mon.vif = this.vif;
    endfunction

    // Task to run the test
    task run();
        gen.count = 10;  // Number of transactions to generate
        fork
            gen.run();
            drv.run();
            mon.run();
            sco.run();
        join_any
    endtask
endclass

module tb;
    and_gate_if vif();  // Interface for AND gate
    and_gate dut(vif.a, vif.b, vif.y);  // DUT instantiation

    environment env;

    initial begin
        env = new(vif);
        env.run();
        #100;  // Allow time for simulation
        $finish;
    end

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars;
    end
endmodule

