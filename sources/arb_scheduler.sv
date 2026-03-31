`timescale 1ns/1ps

module arb_scheduler(

    input  logic        clk,
    input  logic        rst_n,

    input  logic [4:0]  valid,
    input  logic [7:0]  data_in [4:0],

    output logic        out_valid,
    output logic [7:0]  out_data,
    output logic [2:0]  out_channel,

    input  logic        out_ready
);

logic [2:0] current_channel;

// Simple state update
always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        current_channel <= 0;
    else if(out_ready) begin
        // Basic priority selection ONLY (no RR, no preemption logic)
        if(valid[0]) current_channel <= 0;
        else if(valid[1]) current_channel <= 1;
        else if(valid[2]) current_channel <= 2;
        else if(valid[3]) current_channel <= 3;
        else if(valid[4]) current_channel <= 4;
    end
end

// Output logic
assign out_channel = current_channel;
assign out_valid   = valid[current_channel];
assign out_data    = data_in[current_channel];

endmodule