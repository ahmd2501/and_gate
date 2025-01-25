module and_gate (
    input  logic a,  // Input A
    input  logic b,  // Input B
    output logic y   // Output Y
);
    assign y = a & b;  // AND operation
endmodule
interface and_gate_if;
    logic a;  // Input A
    logic b;  // Input B
    logic y;  // Output Y
endinterface
