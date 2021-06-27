/* ******************************************************************


	74 logic for verilog-hdl
	
	
	
	
	2020-2021 @madov
	
	
	
	--2021/04/09 ver100

	
********************************************************************* */

`default_nettype none


//7400 nand gate
module _00 ( 
	input p1,p2,p4,p5,p9,p10,p12,p13,
	output p3,p6,p8,p11
	
);

	assign p3 = ~(p1 & p2);
	assign p6 = ~(p4 & p5);
	assign p8 = ~(p9 & p10);
	assign p11 = ~(p12 & p13);
	
endmodule

//7402 nor gate
module _02 (
	input p2,p3,p5,p6,p8,p9,p11,p12,
	output p1,p4,p10,p13
	
);

	assign p1 = ~ (p2 | p3);
	assign p4 = ~ (p5 | p6);
	assign p10 = ~ (p8 | p9);
	assign p13 = ~ (p11 | p12);
	
endmodule

//7404 not gate
module _04 (
	input p1,p3,p5,p9,p11,p13,
	output p2,p4,p6,p8,p10,p12
);
	assign p2 = ~p1;
	assign p4 = ~p3;
	assign p6 = ~p5;
	assign p8 = ~p9;
	assign p10 = ~p11;
	assign p12 = ~p13;
	
endmodule

//7408 and gate
module _08 (
	input p1,p2,p4,p5,p9,p10,p12,p13,
	output p3,p6,p8,p11
	
	
);
	assign p3 = p1 & p2;
	assign p6 = p4 & p5;
	assign p8 = p9 & p10;
	assign p11 = p12 & p13;
	

endmodule

	
//7410 triple nand
module _10 (
	input p1,p2,p13,p3,p4,p5,p9,p10,p11,
	output p12,p6,p8
);
	assign p12 = ~ ( p1 & p2 & p13);
	assign p6 = ~ (p3 & p4 & p5);
	assign p8 = ~ (p9 & p10 & p11);

endmodule

//7420 4input nand
module _20 (
	input p1,p2,p4,p5,p9,p10,p12,p13,
	output p6,p8
);
	assign p6 = ~ (p1 & p2 & p4 & p5);
	assign p8 = ~ (p9 & p10 & p12 & p13);

endmodule

//7425 4input nor with strobe
module _25 (
	input p1,p2,p3,p4,p5,p9,p10,p11,p12,p13,
	output p6,p8
);
	assign p6 = ~ (p3 & ( p1 | p2 | p4 | p5 ));
	
	assign p8 = ~ (p11 & ( p9 | p10 | p12 | p13 ));

endmodule


//7442 
//bcd to decimal decoder

module _42 (
	input p15,p14,p13,p12,
	output p1,p2,p3,p4,p5,p6,p7,p9,p10,p11
);

	wire ia = p15;
	wire ib = p14;
	wire ic = p13;
	wire id = p12;

	assign p1 = ~ (~ia & ~ib & ~ic & ~id);
	assign p2 = ~ ( ia & ~ib & ~ic & ~id);
	assign p3 = ~ (~ia &  ib & ~ic & ~id);
	assign p4 = ~ ( ia &  ib & ~ic & ~id);
	assign p5 = ~ (~ia & ~ib &  ic & ~id);
	assign p6 = ~ ( ia & ~ib &  ic & ~id);
	assign p7 = ~ (~ia &  ib &  ic & ~id);
	assign p9 = ~ ( ia &  ib &  ic & ~id);
	assign p10= ~ (~ia & ~ib & ~ic &  id);
	assign p11= ~ ( ia & ~ib & ~ic &  id);

endmodule

//7474 D-ffx2
module  _74 (
//p4,p10 pre/

	input p1,p2,p3,p4,p10,p11,p12,p13,
	output p5,p6,p8,p9
);

 reg q1,q2;
 
 always @(posedge p3 or negedge p1 or negedge p4)	
			begin
			if ( p1==0 ) q1 <= 0; else 
			if ( p4==0 ) q1 <= 1; else
			 q1 <= p2; 
			end
			
 always @(posedge p11 or negedge p13 or negedge p10) 
			begin
			if ( p13==0 )  q2 <= 0; else
		   if ( p10==0 ) 	q2 <= 1; else
			 q2 <= p12;
			end
			
			
 assign p5 = q1;
 assign p6 = ~q1;
 assign p9 = q2;
 assign p8 = ~q2;
 
 

endmodule

	
//7485
module _85 (
	input p1,p2,p3,p4,p9,p10,p11,p12,p13,p14,p15,
	output p5,p6,p7
);

wire [3:0] a = { p15, p13, p12, p10 };
wire [3:0] b = { p1, p14, p11, p9 };

// l: a<b
// h: a>b
// e: a==b
 
wire l,h,e;

assign l = ( a < b );
assign h = ( a > b );
assign e = ( a == b );
	
//p5 : o a>b
//p6 : o a=b
//p7 : o a<b

//p2 : i a<b
//p3 : i a=b
//p4 : i a>b


assign p5 = e ? ( (  ( ( p4 & ~p2)  | (~p4 & ~p2 ) ) & ~p3 )  ? 1 : 0 )   : h ;
assign p6 = e ? ( p3 ? 1 : 0 ) : 0 ;
assign p7 = e ? ( (  ( ( ~p4 & p2)  | (~p4 & ~p2 ) ) & ~p3 )  ? 1 : 0 )   : l ;



	
endmodule

module _85a (
	input p1,p2,p3,p4,p9,p10,p11,p12,p13,p14,p15,
	output p5,p6,p7
);

endmodule

	

	
//7486 quad xor
module _86 (
	input  p1,p2,p4,p5,p9,p10,p12,p13,
	output p3,p6,p8,p11

);

assign p3 = p1 ^ p2;
assign p6 = p4 ^ p5;
assign p8 = p9 ^ p10;
assign p11 = p12 ^ p13;

endmodule

//74107 jk-ff 
//NEGEDGE!!
module _107 (
	input	 p1,p4,p8,p9,p10,p11,p12,p13,
	output p2,p3,p5,p6
);
reg q1,q2;

always @(negedge p12)
//p1 = J
//p4 = K
	q1 <= ( p1 & ~p4 ) ? 1 :
			( ~p1 & p4 ) ? 0 :
			( ~p1 & ~p4 ) ? q1 :
			~q1;


always @(negedge p9)
//p8 = J
//p11 = K

	q2 <= ( p8 & ~p11 ) ? 1 :
			( ~p8 & p11 ) ? 0 :
			( ~p8 & ~p11 ) ? q2 :
			~q2;


assign p3 = ( p13 ) ? q1 : 0 ;
assign p2 = ~p3;

assign p5 = ( p10 ) ? q2 : 0 ;
assign p6 = ~p5;



endmodule

//other imprementation
module jkff_gate(q,qbar,clk,j,k);

input j,k,clk;
output q,qbar;

wire nand1_out; // output from nand1
wire nand2_out; // output from nand2

nand(nand1_out, j,clk,qbar);
nand(nand2_out, k,clk,q);
nand(q,qbar,nand1_out);
nand(qbar,q,nand2_out);

endmodule


//74138
//3input 7 decoder
//p1-p3 input A,B,C
//p7 = y7, p15-p9 = y0-y6

module _138 (
	input p1,p2,p3,p4,p5,p6,
	output p7,p9,p10,p11,p12,p13,p14,p15
);

wire g;
wire a,b,c;
assign a=p1,b=p2,c=p3;
assign g = ~p4 & ~p5 & p6;
                                     //CBA
assign p15 = g ?  a |  b |  c  : 1 ; //000 
assign p14 = g ? ~a |  b |  c  : 1 ; //001
assign p13 = g ?  a | ~b |  c  : 1 ; //010
assign p12 = g ? ~a | ~b |  c  : 1 ; //011
assign p11 = g ?  a |  b | ~c  : 1 ; //100
assign p10 = g ? ~a |  b | ~c  : 1 ; //101
assign p9 =  g ?  a | ~b | ~c  : 1 ; //110
assign p7 =  g ? ~a | ~b | ~c  : 1 ; //111

endmodule

//74151
module _151 (
	//         d3 d2 d1 d0 d7  d6  d5  d4
	input wire p1,p2,p3,p4,p12,p13,p14,p15,
	//    nstrobe
	input wire p7,
	//				c   b   a
	input wire p9,p10,p11,
	
	//		      Y  W/
	output wire p5,p6
);

	wire [7:0]dat = { p12,p13,p14,p15,p1,p2,p3,p4 };
	wire [2:0]sel = { p9,p10,p11 };

	assign p5 = dat[sel];
	assign p6 = ~p6;

endmodule
	
	
	
	

//74153
//dual 4line to 1line 

module _153 (
//      1 g/ b c3 c2 c1 c0 2g/   a  2c3 2c2 2c1 2c0 
	input p1,p2,p3,p4,p5,p6,p15,p14,p13,p12,p11,p10,
	      //1y 2y
	output p7,p9
// ba - select
// LL - y=c0
// LH - y=c1
// HL - y=c2
// HH - y=c3
// g/==H -> Y=L
	
);

assign p7 = p1 ? 0 : (
				(~p2 & ~p14 ) ? p6 :
				(~p2 &  p14 ) ? p5 :
				( p2 & ~p14 ) ? p4 : p3 );
				
assign p9 = p15 ? 0 : (
				(~p2 & ~p14 ) ? p10 :
				(~p2 &  p14 ) ? p11 :
				( p2 & ~p14 ) ? p12 : p13 );

endmodule



//74157
//quad 2 input multiplexer
module _157 (
	//     S i0a i1a i0b i1b i1d  i0d  i1c i0c E/
	input p1,p2, p3, p5, p6, p10, p11, p13,p14,p15,
	//     Za Zb Zd Zc
	output p4,p7,p9,p12
);
// S==L Z=i0x 
// S==H Z=i1x
// E/==1 Z=L

assign p4  = p15 ? 1'b0 : (p1 ? p3 : p2 );
assign p7  = p15 ? 1'b0 : (p1 ? p6 : p5 );
assign p9  = p15 ? 1'b0 : (p1 ? p10 : p11 );
assign p12 = p15 ? 1'b0 : (p1 ? p13 : p14 );


endmodule

//74160
//synchronous presettable bin count w/ clear
//(decimal)
module _160 (
	//  nclr cl da db dc dd ep lo~ et
	input p1,p2,p3,p4,p5,p6,p7,p9,p10,
	//     qd  qc  qb  qa  rco
	output p11,p12,p13,p14,p15
);

reg [3:0]q;

always @(posedge p2 or negedge p1)
begin

	//clr mode
	if ( p1==0 )  q = 4'b0;
	else
	//load==0 -> load
	//load==1 -> p7 & p10 ->count else hold
			q = p9 ? (   (p7 & p10) ? ( (q==4'b1001) ?  0 : q+1 )  : q ) : {p6,p5,p4,p3};
			
			
			
	
		
end
	
assign {p11,p12,p13,p14} = q;
assign p15 = &q;


endmodule






//74161
//synchronous presettable bin count w/ clear
module _161 (
	//  nclr cl da db dc dd ep lo~ et
	input p1,p2,p3,p4,p5,p6,p7,p9,p10,
	//     qd  qc  qb  qa  rco
	output p11,p12,p13,p14,p15
);

reg [3:0]q;

always @(posedge p2 or negedge p1)
begin

	//clr mode
	if ( p1 == 1'b0 )  q <= 4'b0;
	else
	//load==0 -> load
	//load==1 -> p7 & p10 ->count else hold
		q <= p9 ? (   (p7 & p10) ? q + 4'h1 : q ) : {p6,p5,p4,p3};
		
		
end
	
assign {p11,p12,p13,p14} = q;

//20210411 add "&p10"
assign p15 = &q & p10;


endmodule


//74166
//8bit parallel-load shift-registers
module _166	(
	input p1,p2,p3,p4,p5,p6,p7,p9,p10,p11,p12,p14,p15,
	output p13
	
);
wire shld;
assign shld=p15;
wire clk;
assign clk = p6 | p7;

wire qa,qb,qc,qd,qe,qf,qg,qh;


	//A
	_ff ff0 (
		.d	(  (p1 & shld ) | ( ~shld & p2 ) ),
		.c	(	clk	)	,
		.r	(	p9		)	,
		.q	( qa	)	
		);
		
	//B
	_ff ff1 (
		.d	(  (qa & shld ) | ( ~shld & p3 ) ),
		.c	(	clk	)	,
		.r	(	p9		)	,
		.q	( qb	)
		);

	//C
	_ff ff2 (
		.d	(  (qb & shld ) | ( ~shld & p4 ) ),
		.c	(	clk	)	,
		.r	(	p9		)	,
		.q	( qc	)
		);
		
	//D
	_ff ff3 (
		.d	(  (qc & shld ) | ( ~shld & p5 ) ),
		.c	(	clk	)	,
		.r	(	p9		)	,
		.q	( qd	)
		
		);
		
	//E
	_ff ff4 (
		.d	(  (qd & shld ) | ( ~shld & p10 ) ),
		.c	(	clk	)	,
		.r	(	p9		)	,
		.q	( qe	)
		);
		
	//F
	_ff ff5(
		.d	(  (qe & shld ) | ( ~shld & p11 ) ),
		.c	(	clk	)	,
		.r	(	p9		)	,
		.q	( qf	)
		);

	//G
	_ff ff6(
		.d	(  (qf & shld ) | ( ~shld & p12 ) ),
		.c	(	clk	)	,
		.r	(	p9		)	,
		.q	( qg	)
		);
		
	//H
	_ff ff7(
		.d	(  (qg & shld ) | ( ~shld & p14 ) ),
		.c	(	clk	)	,
		.r	(	p9		)	,
		.q	( qh	)
		);

assign p13 = qh;


endmodule


module _ff (
	input d,c,r,
	output q
	);
reg x;

always @(posedge c or negedge r )
		if (r==0) x<=0; else x <= d;
	
assign q=x;

endmodule

//74174
//hex-d flip flop
module _174 (
	//    c/ 1d 2d 3d cl 4d  5d  6d
	input p1,p3,p4,p6,p9,p11,p13,p14,
	//     1q 2q 3q 4q  5q  6q
	output p2,p5,p7,p10,p12,p15
);
reg q1,q2,q3,q4,q5,q6;

always @(posedge p9 or negedge p1)
begin
	if (p1==0) {q1,q2,q3,q4,q5,q6} <= 6'b000000;
	else begin
		q1 <= p3;
		q2 <= p4;
		q3 <= p6;
		q4 <= p11;
		q5 <= p13;
		q6 <= p14;
		end


end

assign {p2,p5,p7,p10,p12,p15} = {q1,q2,q3,q4,q5,q6};
		
endmodule
		
module _175 (
	//    c/ 1d 2d 3d  4d  cl 
	input p1,p4,p5,p12,p13,p9,
	//     1q    2q    3q      4q  
	output p2,p3,p7,p6,p10,p11,p15,p14
);
reg q1,q2,q3,q4;

always @(posedge p9 or negedge p1)
begin
	if (p1==0) {q1,q2,q3,q4} <= 4'b0000;
	else begin
		q1 <= p4;
		q2 <= p5;
		q3 <= p12;
		q4 <= p13;
		end


end

assign  {p2, p3,p7, p6,p10, p11, p15,p14}
		= {q1,~q1,q2,~q2, q3, ~q3, q4, ~q4};


endmodule


//74245
//bus transceiver
module _245 (
	input p1,p19,
	inout p2,p3,p4,p5,p6,p7,p8,p9,
	inout p11,p12,p13,p14,p15,p16,p17,p18
);

//wire [7:0] aport = {p2,p3,p4,p5,p6,p7,p8,p9};
//wire [7:0] bport = {p18,p17,p16,p15,p14,p13,p12,p11};
assign  { p2, p3, p4, p5, p6, p7, p8, p9} = p19 ? 8'bZ : p1 ? 8'bZ : {p18,p17,p16,p15,p14,p13,p12,p11};
assign  {p18,p17,p16,p15,p14,p13,p12,p11} = p19 ? 8'bZ : p1 ? {p2,p3,p4,p5,p6,p7,p8,p9} : 8'bZ ;

endmodule




//74257
//quad 2 input multiplexer with 3-state
module _257 (
	//     S i0a i1a i0b i1b i1d  i0d  i1c i0c OC/
	input p1,p2, p3, p5, p6, p10, p11, p13,p14,p15,
	//     Za Zb Zd Zc
	output p4,p7,p9,p12
);
// S==L Z=i0x 
// S==H Z=i1x
// E/==1 Z=L

assign p4  = p15 ? 1'bZ : (p1 ? p3 : p2 );
assign p7  = p15 ? 1'bZ : (p1 ? p6 : p5 );
assign p9  = p15 ? 1'bZ : (p1 ? p10 : p11 );
assign p12 = p15 ? 1'bZ : (p1 ? p13 : p14 );


endmodule



//74273
//octal posedge d-ff
module _273 (
	//    c/ 1d 2d 3d 4d cl  5d  6d  7d  8d
	input p1,p3,p4,p7,p8,p11,p13,p14,p17,p18,
	//     1q 2q 3q 4q  5q  6q  7q  8q
	output p2,p5,p6,p9,p12,p15,p16,p19
);
reg q1,q2,q3,q4,q5,q6,q7,q8;

always @(posedge p11 or negedge p1)
begin
	if (p1==0)
		{q1,q2,q3,q4,q5,q6,q7,q8} <= 8'b00000000;
	else begin
		q1 <= p3;
		q2 <= p4;
		q3 <= p7;
		q4 <= p8;
		q5 <= p13;
		q6 <= p14;
		q7 <= p17;
		q8 <= p18;
		end
end

assign {p2,p5,p6,p9,p12,p15,p16,p19} = {q1,q2,q3,q4,q5,q6,q7,q8};

		
endmodule



//74283
//adder
module _283 (
	//    b2 a2 a1 b1 C0  b4  a4  a3  b3
	input p2,p3,p5,p6,p7,p11,p12,p14,p15,
	//     s2 s1 C4  s4  s3
	output p1,p4,p9,p10,p13
);

wire c1,c2,c3;

/*assign p4 = p7 ^ ( ~( p5 & p6 ) & ( p5 | p6 )  );
assign c1 = ( ( p5 ^ p6 ) & p7 ) | ( p5 & p6 );

assign p1 = c1 ^ ( ~( p3 & p2 ) & ( p3 | p2 ) );
assign c2 = ( ( p3 ^ p2 ) & c1 ) | ( p5 & p6 );

assign p13= c2 ^ ( ~(p14 & p15) & (p14 | p15) );
assign c3 = ( (p14 ^ p15) & c2 ) | (p14 & p15);

assign p10= c3 ^ ( ~(p12 & p11) & (p12 | p11) );
assign p9 = ( (p12 ^ p11) & c3 ) | (p12 & p11);
*/

assign p4 = p7 ^ ( p5 ^ p6 );
assign c1 = (p5 & p6 ) | (p7 & (p5 ^ p6 ) );

assign p1 = c1 ^ ( p3 ^ p2 );
assign c2 = (p3 & p2 ) | (c1 & (p3 ^ p2 ) );

assign p13 = c2 ^ ( p14 ^ p15 );
assign c3 = (p14 & p15 ) | (c2 & (p14 ^ p15 ) );


assign p10 = c3 ^ ( p12 ^ p11 );
assign p9 = (p12 & p11 ) | (c3 & (p12 ^ p11 ) );

endmodule

/*
c0 p5 p6   s  c
0  0  0 -> 0  0
0  0  1 -> 1  0
0  1  0 -> 1  0
0  1  1 -> 0  1
1  0  0 -> 1  0
1  0  1 -> 0  1
1  1  0 -> 0  1
1  1  1 -> 1  1
*/




//74365
//hex tristate buffer
module _365 (
	//    g1/a1 a2 a3  a4  a5  a6 g2/
	input p1,p2,p4,p6,p10,p12,p14,p15,
	//     y1 y2 y3 y4  y5  y6
	output p3,p5,p7,p9,p11,p13
);

wire g;
assign g = ~p1 & ~p15;
assign p3 = g ? p2 : 1'bZ;
assign p5 = g ? p4 : 1'bZ;
assign p7 = g ? p6 : 1'bZ;
assign p9 = g ? p10: 1'bZ;
assign p11= g ? p12: 1'bZ;
assign p13= g ? p14: 1'bZ;

endmodule


