`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.11.2025 22:53:25
// Design Name: 
// Module Name: fpu_alu
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module fpu_alu(
    input [31:0] a,b,
    input reset,clk,
    input [7:0] opcode,
    output [31:0] y,
    output [6:0] flag
);
wire [31:0] a_out,b_out;
wire [7:0] opcode_out;
wire [31:0] y_in;
wire [6:0] flag_in;

ip_reg a1(.a_in(a),.b_in(b),.opcode_in(opcode),.reset(reset),.clk(clk),.a_out(a_out),.b_out(b_out), .opcode_out(opcode_out));
fpu_alu_top a2(.a(a_out),.b(b_out),.reset(reset),.opcode(opcode_out),.y(y_in),.flag(flag_in));
op_reg a3(.y_in(y_in),.flag_in(flag_in),.reset(reset),.clk(clk),.y_out(y),.flag_out(flag));

endmodule

module fpu_alu_top(
    input [31:0] a,b,
    input reset,
    input [7:0] opcode,
    output [31:0] y,
    output [6:0] flag
    );

wire [6:0] flag_addr;
reg [6:0] dummy_flag;
wire [31:0] y_addr;
reg [31:0] dummy_y;
wire y_comp,y_uneq,y_great;
    
fp_adder_754 a0(.reset(reset),.a(a),.b(b),.opcode(opcode),.y(y_addr),.NaN_flag(flag_addr[6]),
                .inf_flag(flag_addr[5]),.zero_flag(flag_addr[4]),.subnormal_flag(flag_addr[3]),
                .sticky_flag(flag_addr[2]),.overflow_flag(flag_addr[1]),.underflow_flag(flag_addr[0]));   
fp_comparator_754 a1(.reset(reset),.a(a),.b(b),.opcode(opcode),.y(y_comp),.NaN_flag(flag_addr[6]));
fp_unequal_754 a2(.reset(reset),.a(a),.b(b),.opcode(opcode),.y(y_uneq),.NaN_flag(flag_addr[6]));
fp_greater_754 a3(.reset(reset),.a(a),.b(b),.opcode(opcode),.y(y_great),.NaN_flag(flag_addr[6]));

always@*
    begin
        case(opcode)
            8'b1111_1111 : begin
                                dummy_y = y_addr;
                                dummy_flag = flag_addr;
                           end
            8'b1111_1101 : begin
                                dummy_y = {31'b0,y_comp};
                                dummy_flag = {flag_addr[6],5'b0};
                           end
            8'b1111_1100 : begin
                                dummy_y = {31'b0,y_uneq};
                                dummy_flag = {flag_addr[6],5'b0};
                           end
            8'b1111_1011 : begin
                                dummy_y = {31'b0,y_great};
                                dummy_flag = {flag_addr[6],5'b0};
                           end
            default:       begin
                                dummy_y = 32'b0;
                                dummy_flag = 7'b0;
                           end
        endcase
    end
assign y = dummy_y;
assign flag = dummy_flag;
endmodule


module ip_reg(
    input [31:0] a_in,b_in,
    input [7:0] opcode_in,
    input reset,clk,
    output [31:0] a_out,b_out,
    output [7:0] opcode_out
);

reg [31:0] a_out_dummy, b_out_dummy;
reg [7:0] opcode_out_dummy;
always@(posedge clk, posedge reset)
    if(reset) begin
        a_out_dummy <= 32'b0;
        b_out_dummy <= 32'b0;
        opcode_out_dummy <= 32'b0;
    end
    else begin
        a_out_dummy <= a_in;
        b_out_dummy <= b_in;
        opcode_out_dummy <= opcode_in;
    end
    
assign a_out = a_out_dummy;
assign b_out = b_out_dummy;
assign opcode_out = opcode_out_dummy;
endmodule



module op_reg(
    input [31:0] y_in,
    input [7:0] flag_in,
    input reset,clk,
    output [31:0] y_out,
    output [7:0] flag_out
);

reg [31:0] y_out_dummy;
reg [7:0] flag_out_dummy;
always@(posedge clk, posedge reset)
    if(reset) begin
        y_out_dummy <= 32'b0;
        flag_out_dummy <= 32'b0;
    end
    else begin
        y_out_dummy <= y_in;
        flag_out_dummy <= flag_in;
    end
    
assign flag_out = flag_out_dummy;
assign y_out = y_out_dummy;
endmodule



module fp_adder_754(
    input reset,
    input [31:0] a,
    input [31:0] b,
    input [7:0] opcode,
    output [31:0] y,
    output NaN_flag,
    output inf_flag,
    output zero_flag,
    output subnormal_flag,
    output sticky_flag,
    output overflow_flag,
    output underflow_flag
    );
    
reg sign_a,sign_b,sign_y;
reg [7:0] exp_a,exp_b,exp_y;
reg [63:0] buff_a,buff_b,buff_y,max,min;
reg [31:0] dummy_y;
reg NaN_f;
reg inf_f;
reg zero_f;
reg same_num_op_sign;
reg reset_op;
always@*
    begin
        sign_a = a[31];
        sign_b = b[31];
        buff_a = 64'b0;
        buff_b = 64'b0;
        buff_y = 64'b0;
        buff_a[32] = 1'b1;
        buff_a[31:9] = a[22:0];
        buff_b[32] = 1'b1;
        buff_b[31:9] = b[22:0];
        exp_a = a[30:23];
        exp_b = b[30:23];
        if(opcode == 8'b1111_1111) reset_op = 1'b0;
        else reset_op = 1'b1;
        if(reset || reset_op) 
            begin
                dummy_y = 32'b0;
                NaN_f = 1'b0;
                inf_f = 1'b0;
                zero_f = 1'b0;
            end
        else begin
        //Zero
        if(a == 32'b0 && b == 32'b0)
            begin
                zero_f = 1'b1;
                dummy_y = 32'b0; //Don't remove dummy y value. When both numbers are zero it should hold some value.   
            end
        else if(b == 32'b0)
            begin
                zero_f = 1'b0;
                dummy_y = 32'b0;
            end 
        else if(a == 32'b0)
            begin
                zero_f = 1'b0;
                dummy_y = 32'b0;
            end 
        else
            begin
                zero_f = 1'b0;
                dummy_y = 32'b0;
            end
        ////////////////////////////
        /**/
        //NaN Condition
        if((exp_a == {8{1'b1}} &&((a[22:0] & {23{1'b1}}) != 23'b0)) || (exp_b == {8{1'b1}} && ((b[22:0] & {23{1'b1}}) != 23'b0)))
            begin
                NaN_f = 1'b1;
                dummy_y = {32{1'b1}};
            end
        else
            begin
                NaN_f = 1'b0;
                dummy_y = 32'b0;
            end
        //Infinity
        if(a == 32'h7f800000 || b == 32'h7f800000)
            begin
                inf_f = 1'b1;
                dummy_y = 32'h7f800000;
            end
        else if(a == 32'hff800000 || b == 32'hff800000)
            begin
                inf_f = 1'b1;
                dummy_y = 32'hff800000;
            end
        else if((a == 32'h7f800000 && b == 32'hff800000)||((a == 32'hff800000 && b == 32'h7f800000)))
            begin
                inf_f = 1'b1;
                dummy_y = {32{1'b1}};
            end
        else
            begin
                inf_f = 1'b0;
                dummy_y = 32'b0;
            end
        //Same numbers
        if((a[22:0] == b[22:0])&&(~zero_f))
            begin
                if(sign_a == sign_b) 
                    begin
                        same_num_op_sign = 1'b0;
                        dummy_y = 32'b0;
                    end
                else
                    begin
                        same_num_op_sign = 1'b1;
                        dummy_y = 32'b0;
                    end
            end
         else
            begin
                same_num_op_sign = 1'b0;
                dummy_y = 32'b0;
            end

        if(~(NaN_f || inf_f || zero_f || same_num_op_sign))
            begin        
                if(exp_a > exp_b)
                    begin
                        exp_y = exp_a;
                        buff_b = buff_b >> (exp_a - exp_b);
                        buff_a = buff_a;
                    end
                else 
                    begin
                        exp_y = exp_b;
                        buff_a = buff_a >> (exp_b - exp_a);
                        buff_b = buff_b;
                    end
                if(buff_a > buff_b)
                    begin
                        max = buff_a;
                        min = buff_b;
                        sign_y = sign_a;
                    end 
                else
                    begin
                        max = buff_b;
                        min = buff_a;
                        sign_y = sign_b;
                    end
                if(sign_a == sign_b) buff_y = max + min;
                else buff_y = max - min;
                if(buff_y[33:32] == 2'b11 || buff_y[33:32] == 2'b10)
                    begin
                        buff_y = buff_y >> 1;
                        exp_y = exp_y + 1'b1;
                    end
                else if(buff_y[33:32] == 2'b00)
                    begin
                        buff_y = buff_y << 1;
                        exp_y = exp_y - 1'b1;
                    end
                else
                    begin
                        buff_y = buff_y;
                        exp_y = exp_y;
                    end
                dummy_y[31] = sign_y;
                dummy_y[30:23] = exp_y;
                dummy_y[22:0] = buff_y[31:9]; 
            end
        else
            begin
                exp_y = 8'b0;
                max = 64'b0;
                min = 64'b0;
                sign_y = 1'b0;
                buff_y = 64'b0;
            end 
        end             
    end
assign y = dummy_y;
assign NaN_flag = NaN_f;
assign inf_flag = inf_f;
assign zero_flag = (zero_f || (y == 32'b0));
assign sticky_flag = (dummy_y[7:0] != 8'b00)?1'b1:1'b0;
assign subnormal_flag = (y[30:23] == 8'b0 && y[22:0] != 32'b0);
assign overflow_flag = ((y[30:23] < a[30:23] || y[30:23] < b[30:23])&&(a[31] == b[31]))?1'b1:1'b0;
assign underflow_flag = (y[30:23] == 8'b0)&&(((a[30:23] == 8'b0) && (a[22:0] != 23'b0)) || ((b[30:23] == 8'b0) && (b[22:0] != 23'b0)))?1'b1:1'b0;
endmodule



module fp_comparator_754(
    input reset,
    input [31:0] a,
    input [31:0] b,
    input [7:0] opcode,
    output y,
    output NaN_flag
    );
    

reg dummy_y;
reg NaN_f;
reg reset_op;
always@*
    begin
        
        if(opcode == 8'b1111_1101) reset_op = 1'b0;
        else reset_op = 1'b1;
        if(reset || reset_op) 
            begin
                dummy_y = 32'b0;
                NaN_f = 1'b0;
            end
        else begin

        //NaN Condition
        if((a[30:23] == {8{1'b1}} &&((a[22:0] & {23{1'b1}}) != 23'b0)) || (b[30:23] == {8{1'b1}} && ((b[22:0] & {23{1'b1}}) != 23'b0)))
            begin
                NaN_f = 1'b1;
            end
        else
            begin
                NaN_f = 1'b0;
            end
        end
        if((a == b) && (~NaN_f)) dummy_y = 1'b1;
        else dummy_y = 1'b0;      
    end
assign y = dummy_y;
assign NaN_flag = NaN_f;

endmodule



module fp_unequal_754(
    input reset,
    input [31:0] a,
    input [31:0] b,
    input [7:0] opcode,
    output y,
    output NaN_flag
    );
    

reg dummy_y;
reg NaN_f;
reg reset_op;
always@*
    begin
        
        if(opcode == 8'b1111_1100) reset_op = 1'b0;
        else reset_op = 1'b1;
        if(reset || reset_op) 
            begin
                dummy_y = 32'b0;
                NaN_f = 1'b0;
            end
        else begin

        //NaN Condition
        if((a[30:23] == {8{1'b1}} &&((a[22:0] & {23{1'b1}}) != 23'b0)) || (b[30:23] == {8{1'b1}} && ((b[22:0] & {23{1'b1}}) != 23'b0)))
            begin
                NaN_f = 1'b1;
            end
        else
            begin
                NaN_f = 1'b0;
            end
        end
        if((a != b) || (NaN_f)) dummy_y = 1'b1;
        else dummy_y = 1'b0;      
    end
assign y = dummy_y;
assign NaN_flag = NaN_f;

endmodule

module fp_greater_754(
    input reset,
    input [31:0] a,
    input [31:0] b,
    input [7:0] opcode,
    output y,
    output NaN_flag
    );
    

reg dummy_y1,dummy_y2,dummy_y3;
reg NaN_f;
reg reset_op;
reg sign_a,sign_b;
reg [7:0] exp_a,exp_b;
reg [63:0] buff_a,buff_b;
always@*
    begin
        sign_a = a[31];
        sign_b = b[31];
        buff_a = 64'b0;
        buff_b = 64'b0;
        buff_a[32] = 1'b1;
        buff_a[31:9] = a[22:0];
        buff_b[32] = 1'b1;
        buff_b[31:9] = b[22:0];
        exp_a = a[30:23];
        exp_b = b[30:23];
        if(opcode == 8'b1111_1011) reset_op = 1'b0;
        else reset_op = 1'b1;
        if(reset || reset_op) 
            begin
                dummy_y1 = 1'b0;
                dummy_y2 = 1'b0;
                dummy_y3 = 1'b0;
                NaN_f = 1'b0;
            end
        else begin

        //NaN Condition
        if((a[30:23] == {8{1'b1}} &&((a[22:0] & {23{1'b1}}) != 23'b0)) || (b[30:23] == {8{1'b1}} && ((b[22:0] & {23{1'b1}}) != 23'b0)))
            begin
                NaN_f = 1'b1;
            end
        else
            begin
                NaN_f = 1'b0;
            end
        end
        if(~(NaN_f))
            begin        
                if(exp_a > exp_b)
                    begin
                        dummy_y2 = 1'b1;
                        buff_b = buff_b >> (exp_a - exp_b);
                        buff_a = buff_a;
                    end
                else 
                    begin
                        dummy_y2 = 1'b0;
                        buff_a = buff_a >> (exp_b - exp_a);
                        buff_b = buff_b;
                    end
            end
        else
            begin
                dummy_y2 = 1'b0;
            end 
        if(buff_a > buff_b) dummy_y3 = 1'b1;
        else dummy_y3 = 1'b0;
        if(sign_b < sign_a) dummy_y1 = 1'b0;
        else if(sign_b == sign_a) dummy_y1 = 1'b0;
        else dummy_y1 = 1'b1;
    end
            
assign y = dummy_y1||dummy_y2||dummy_y3;
assign NaN_flag = NaN_f;

endmodule


