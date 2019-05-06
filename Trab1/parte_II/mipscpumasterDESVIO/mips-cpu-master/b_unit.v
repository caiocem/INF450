`ifndef _branch_unit
`define _branch_unit

module branch_unit(
    //input wire clk, //clock
    output wire WRt_fio, //manda a tabela atualizar a tag 
    output wire WRp_fio, //manda a tabela atualizar a predição
    input wire H, //h do fetch
    input wire P, //p do fetch
    input wire Hd, //h do decode
    input wire Pd, //p do decode
    input wire B, //se a instrução é um beq ou não
    input wire C, //comparador data1==data2(se o beq desvia ou não)
    output wire flush_s1_fio, //da flush na barreira s1 se precisar desfazer algo
    output wire [1:0] MUX_B_fio //mux que contra o fluxo do PC
);

reg flush_s1;
reg [1:0] MUX_B;
reg WRt;
reg WRp;

/* initial begin
    MUX_B <= 2'b00;
    flush_s1 <= 0;
    WRp = 0;
    WRt = 0;
end */
always @(*) 
begin
    
    if((B == 1'b0) && (H == 1'b0)) begin
        MUX_B <= 2'b0;
        WRp <= 1'b0;
        WRt <= 1'b0;
        flush_s1 <= 0;
    end else if ((H == 1'b1)&&(P == 1'b0)) begin
        MUX_B <= 2'b00;
        WRp <= 1'b0;
        WRt <= 1'b0;
        flush_s1 <= 0;
    end else if ((H == 1'b1)&&(P == 1'b1)) begin
        MUX_B <= 2'b01;
        WRp <= 1'b0;
        WRt <= 1'b0;
        flush_s1 <= 0;
    end else if ((H == 1'b0)&&(Hd == 1'b0)&&(C==1'b0)&&(B==1'b1)) begin
        MUX_B <= 2'b00;
        WRp <= 1'b1;
        WRt <= 1'b1;
        flush_s1 <= 0;
    end else if ((H == 1'b0)&&(Hd == 1'b0)&&(C==1'b1)&&(B==1'b1)) begin
        MUX_B <= 2'b11;
        WRp <= 1'b1;
        WRt <= 1'b1;
        flush_s1 <= 1;
    end  else if ((H == 1'b0)&&(Hd == 1'b1)&&(Pd == 1'd0)&&(C==1'b0)&&(B==1'b1)) begin
        MUX_B <= 2'b00;
        WRp <= 1'b0;
        WRt <= 1'b0;
        flush_s1 <= 0;
    end else if ((H == 1'b0)&&(Hd == 1'b1)&&(Pd == 1'd1)&&(C==1'b1)&&(B==1'b1)) begin
        MUX_B <= 2'b00;
        WRp <= 1'b0;
        WRt <= 1'b0;
        flush_s1 <= 0;
    end else if ((H == 1'b0)&&(Hd == 1'b1)&&(Pd == 1'd0)&&(C==1'b1)&&(B==1'b1)) begin
        MUX_B <= 2'b11;
        WRp <= 1'b1;
        WRt <= 1'b0;
        flush_s1 <= 1;
    end else if ((H == 1'b0)&&(Hd == 1'b1)&&(Pd == 1'd1)&&(C==1'b0)&&(B==1'b1)) begin
        MUX_B <= 2'b10;
        WRp <= 1'b1;
        WRt <= 1'b0;
        flush_s1 <= 1;
    end 
end
assign MUX_B_fio = MUX_B;
assign flush_s1_fio = flush_s1;
assign WRp_fio = WRp;
assign WRt_fio = WRt;
endmodule

`endif