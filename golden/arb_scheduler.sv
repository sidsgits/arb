`timescale 1ns/1ps

module arb_scheduler(

    input clk,
    input rst_n,

    input  [4:0] valid,
    input  [7:0] data_in [0:4],

    output reg        out_valid,
    output reg [7:0]  out_data,
    output reg [2:0]  out_channel,

    input out_ready
);

reg [2:0] current_channel;
reg [2:0] next_channel;

integer i;
integer k;


/////////Round robin helper

function [2:0] rr_select;
    input [4:0] v;
    input [2:0] start;
    begin
        rr_select = start;

        for(k=1;k<=5;k=k+1)
        begin
            if(v[(start+k)%5])
            begin
                rr_select = (start+k)%5;
                k = 6;
            end
        end
    end
endfunction



///////////////Next state logic

always @(*) begin

    next_channel = current_channel;

    if(!out_ready) begin
        next_channel = current_channel;
    end
    else begin

        /////find highest priority valid channel FIRST
        reg [2:0] best_channel;
        best_channel = 5;  // invalid default

        for(i=0;i<5;i=i+1) begin
            if(valid[i] && (best_channel == 5))
                best_channel = i;
        end

        ///////if higher priority exists
        if(best_channel < current_channel) begin

            if((current_channel - best_channel) >= 2)
                next_channel = best_channel;     // immediate

            else
                next_channel = current_channel;  // deferred

        end

        //////if current invalid then round robin
        else if(!valid[current_channel]) begin
            next_channel = rr_select(valid,current_channel);
        end

    end

end


//////State register
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        current_channel <= 0;
    else if(out_ready)
        current_channel <= next_channel;
end


///////Output logic
always @(*) begin

    //using next_channel when ready
    if(out_ready)
        out_channel = next_channel;
    else
        out_channel = current_channel;

    if(valid[out_channel]) begin
        out_valid = 1;
        out_data  = data_in[out_channel];
    end
    else begin
        out_channel = rr_select(valid,out_channel);
        out_valid   = valid[out_channel];
        out_data    = data_in[out_channel];
    end

end

endmodule