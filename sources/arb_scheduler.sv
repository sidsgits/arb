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
logic [2:0] next_channel;

integer i;
integer k;


////Round robin helper

function automatic [2:0] rr_select;
    input [4:0] v;
    input [2:0] start;
    begin
        rr_select = start;
        for(k=1;k<=5;k=k+1) begin
            if(v[(start+k)%5]) begin
                rr_select = (start+k)%5;
                k = 6;
            end
        end
    end
endfunction


////Next state logic (PARTIAL)

always_comb begin

    next_channel = current_channel;

    if(out_ready) begin

        // Find highest priority valid channel
        logic [2:0] best_channel;
        best_channel = 5;  // invalid default

        for(i=0;i<5;i=i+1) begin
            if(valid[i] && best_channel == 5)
                best_channel = i;
        end


        if(!valid[current_channel]) begin
            next_channel = rr_select(valid, current_channel);
        end
        else begin
            next_channel = current_channel;
        end

    end

end



////State register

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        current_channel <= 0;
    else if(out_ready)
        current_channel <= next_channel;
end



////Output logic (PARTIAL)

always_comb begin

    out_channel = current_channel;

    if(valid[current_channel]) begin
        out_valid = 1;
        out_data  = data_in[current_channel];
    end
    else begin
        // TODO:
        // Select next valid channel using rr_select
        out_channel = rr_select(valid, current_channel);
        out_valid   = valid[out_channel];
        out_data    = data_in[out_channel];
    end

end

endmodule