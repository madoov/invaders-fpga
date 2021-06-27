/* ********************************************

	SPACE INVADERS CORE for FPGA toy
	by @madov Jun,2021


	趣味目的であり内容や動作は一切保証しません。

	
	
   ******************************************** */

/* 2021 06 11 new ver */
/* SX port -> LVDS serial */


`default_nettype none



module fpga_toy (

	//oscillator input
	input FPGA_CLK_50M,
	input FPGA_CLK2_50M,

	//8bit rgb out
	output [2:0]r,
	output [2:0]g,
	output [1:0]b,
	
	//video sync out
	output sync_out,sync_out2,

	//debug LED
	output [3:0] LED,

	//JAMMA control input
	input _1_UP, _1_DOWN, _1_RIGHT, _1_LEFT, _1_P1, _1_P2, 
	input _1_START,_1_COIN,
	
	//DIP switch input
	input DIP1,DIP2,DIP3,DIP4,DIP5,DIP6,DIP7,DIP8,
	
	//TACT switch input
	input 	SW1,SW2,

	//dsdac output
	output dsdac,
	


	/*
	SX output for invaders
	(for general purpose lowspeed port)

	sx_out 	-> data
	sx_sclk 	-> serialize clock
	sx_rclk	-> data out clock (for 74hcs595)

	*/
	
	output sx_out_lvds,
	output sx_sclk,
	output sx_rclk,

	/* SX4 is only for simple beep tune */
	output sx4_out,
	
	//external rom address,data,oe
	output [15:0]rom_a,
	input [7:0]rom_d,
	output rom_oe


);

wire [15:0]sx_out;

//flag for display flipping
reg inv_t;

always @(posedge SW1)
	inv_t <= ~inv_t;
	
wire inv = inv_t;

wire L = ~_1_LEFT;
wire R = ~_1_RIGHT;
wire FIRE = ~_1_P1;
wire COIN = ~_1_COIN;
wire S1 = ~_1_START;
wire S2 = ~_1_START;



assign sync_out = compblank;
//assign sync_out2 = compblank;


//All color is set to RED when bomb sound (sx[2])==1
assign r=sx[2] ? {3{video_out}} : {3{video_out & color[0]}};
assign g=sx[2] ? 3'b0 : {3{video_out & color[2]}};
assign b=sx[2] ? 2'b0 : {2{video_out & color[1]}};


/* clock generator (pll) */
wire clk_19968;
wire vclk;
wire clk_0487mhz;

pll0	pll0	(
	.inclk0 (FPGA_CLK_50M)	,
	.c0		(clk_19968),
	.c1		(f7_p14), 		//9.984MHz => 2 x vclk
	.c2		(vclk),//,		//4.992MHz
	.c3		(clk_0487mhz)	//0.487MHz  for extend sound NE555 simulatrion
	
);



wire [7:0] extend_sout;		//extend sound output (8bit PCM)
									//でも本当は1ビット
									
extend_sound s0 (
	.inclk_0487mhz  (clk_0487mhz),
	.vc3				 (vcount[3]),
	.out				 (extend_sout),
	.sx4				 (sx[4])
);

sigma_delta_dac dac0 (
	.DACout		(dsdac),
	.DACin		(extend_sout),
	.CLK			(FPGA_CLK_50M)

);




wire clk_9984 = f7_p14;


wire [15:0] ad;



/* ram/rom  unit */
wire [7:0]cpu_do;
wire [7:0]ram_din	 = cpu_do ;

wire [7:0]ram_dout_cpu;
wire [7:0]ram_dout_video;


/* ram_address */
/*
	video access side
	8H -> ram_cs
	{16H,32H,64H,128H,1V,2V,4V,8V,16V,32V,64V,128V} => ram_a

	cpu_access side
	ad0 -> ram_cs
	ad1..ad12 => ram_a
	
*/	

wire [12:0] addr_video_ninv = { vcount [7:0], hcount [7:3] };
wire [12:0] addr_video_inv =  { ~vcount[7:0] + 8'h20 , ~hcount[7:3] };

reg [12:0] addr_video;

always @(posedge vclk)
	addr_video = inv ? addr_video_inv : addr_video_ninv;

wire ram_wr = ~nWR & ad[13];

ram_all	ramall	(
//_a => cpu_side
	.address_a	( ad[12:0] ),
	.data_a	(ram_din),
	.q_a	(ram_dout_cpu),
	.wren_a	(ram_wr),
	.clock_a	(vclk),
	
//_b => video_side
	.address_b	( addr_video ),
	.data_b	(0),
	.q_b	(ram_dout_video),
	.wren_b	(0),
	.clock_b (~vclk)

);



wire [9:0] addr_color = { addr_video[12:8] , addr_video[4:0] };
wire  [2:0]color;// = 3'b111;



/* ********************** 

	For extrnal rom module 

	********************** */

reg bprom_setting;
initial bprom_setting = 1;

reg [7:0] extrom_d;

/*
	extrom address setting
	
	rom_a <- when bprom_setting, bprom_addr
				when normal       , cpu_address
	rom_oe is always "0"(enable)
	extrom_d (registered) = posedge clk_19968 synced rom_d
*/
	
assign rom_a = bprom_setting ? {6'b1111_10, bprom_addr[9:0] } : {3'b000, ad[12:0] };
assign rom_oe = 1'b0;
always @(posedge clk_19968) extrom_d = rom_d;
assign id = extrom_d;

/*

	bprom setting
	simply counting up!
	
	データは外部ROMの$F800から格納してある
	
	
*/

reg [9:0] bprom_addr;
always @(negedge vclk )
begin
	if (bprom_setting && hcount[2:0] == 3'b010 ) begin
			if ( bprom_addr == 10'b11_1111_1111 )
					bprom_setting = 0;
					else
					bprom_addr = bprom_addr + 1;
	end

end
	
bprom bpr0 (
	.address	( bprom_setting ? bprom_addr[9:0] : addr_color  ),  
	.data ( extrom_d ),
	.q	( color ),
	.wren	( bprom_setting ),
	.clock	( hcount[2] )
	
);



  
wire [7:0] id0,id1;


/* 4000-43ff check */
//not used?????? 2021/06/27
//assign id = ad[14] ? id1 : id0 ;


/* ******************************************************** 

	基板本体のロジックIC群　アルファベット順
	
	not,or,xorなど単純なロジックはwireで記述

	
	******************************************************** */
	
	
wire b3_p6 = ( h5_p14 & h5_p13 & ~d5_p9 & ~j3_p9);
wire b3_p8 = ~ ( cpusync & e6_p3 & ad[13] ); //20210414 added "~"
wire b4_p1 = ~ (b3_p6 | h5_p12);
wire b4_p4 = ~ ( b4_p10 | sd0 );
wire b4_p10 = ~ ( ad[13] | sd6 );
wire b4_p13 = ~ ( sd0 | sd6 );
wire b5_p6 = ~ ( c7_p11 & b5_p3 );
wire b5_p3 = ~ ( c7_p11 & l4_p4 );
wire c4_p6 =  c3_p10 ^ c3_p12;
wire c4_p11 = c3_p10 ^ h5_p12;
wire c6_p3 = ~ ( j7_p12 );
wire c6_p6 = ~ ( j7_p11 & c6_p3 );
wire c6_p8 = ~ ( ~d5_p9 & c6_p6 );
wire c7_p11 = h5_p13 & l4_p7;

 

wire f7_p14,f7_p13,f7_p12,f7_p11;
reg [3:0] f7_count;

wire f7_p14x;

always @(posedge clk_19968)
	f7_count = ( f7_count==4'h9) ? 4'h0 : f7_count + 1;

assign {f7_p11,f7_p12,f7_p13,f7_p14x } =  f7_count ;

// f7_p14は1/2 clock
//　これはpllで代用する。（しないとまともに動かない。）

//f7_p11は1/10clock
//duty比が違うため、これはこのまま使用する。
//タイミング制約をかける必要あるがいまのところ保留。(04/19)

wire c3_p2,c3_p5,c3_p12,c3_p10;
_174 c3 (
	.p3	(ram_dout_cpu[6]),
	.p4	(ram_dout_cpu[7]),
	.p13	(c3_p10),
	.p11	(1),
	.p6	(0),
	.p14	(0),
	

	.p2	(c3_p2),
	.p5	(c3_p5),
	.p7	(),
	.p12	(c3_p12),
	.p10	(c3_p10),
	.p15	(),
	
	.p1	(b3_p8),
	.p9	(c4_p11)


);

wire c5_p5,c5_p6;
wire c5_p9;

_74 c5 (

	.p2	(c3_p12),
	.p3	(f6_p6),
	.p5	(c5_p5),
	.p6	(c5_p6),

	.p4	(c5_p6),
	.p1	(b3_p8),


	.p10	(1),
	.p12	(inte),
	.p11	(c6_p8),
	.p9	(c5_p9),
	.p13	(~sd0)
	

);


wire f3_p2,f3_p5,f3_p7,f3_p10,f3_p12,f3_p15;
_174 f3 (
	.p3	(ram_dout_cpu[0]),
	.p4	(ram_dout_cpu[1]),
	.p6	(ram_dout_cpu[2]),
	.p11	(ram_dout_cpu[3]),
	.p13	(ram_dout_cpu[4]),
	.p14	(ram_dout_cpu[5]),

	.p2	(f3_p2),
	.p5	(f3_p5),
	.p7	(f3_p7),
	.p10	(f3_p10),
	.p12	(f3_p12),
	.p15	(f3_p15),
	
	.p1	(b3_p8),
	.p9	(c4_p11)
	
);

//shift 
wire video_out;
wire vo;


/*
_166 f4 (
	.p14	(ram_dout_v[0]),
	.p12	(ram_dout_v[1]),
	.p11	(ram_dout_v[2]),
	.p10	(ram_dout_v[3]),
	.p5	(ram_dout_v[4]),
	.p4	(ram_dout_v[5]),
	.p3	(ram_dout_v[6]),
	.p2	(ram_dout_v[7]),
	
	//clk
	.p6	(j3_p5),
	.p7	(j3_p5),
	
	.p9	(1),
	//shld
	.p15	(b4_p1),
	
	//out
	.p13	(vo)
	
);

*/





/* シフトレジスタ */
/* 本来は　74LS166　でやるべきだが、タイミングがあわないため自作で */
_shifter shft (
			.data	(ram_dout_video),
			.clk	(vclk),
			.nld	(b4_p1),
			.inv	(inv),
			.out	(vo)
		);
		

assign video_out = vo & ~vblank & ~hblank;

//wire compblank =  ~ ( (j3_p9 & ~j5_p13 & j5_p14) | (d5_p9 & j6_p12 & j6_p11 &  ~j7_p14 ) );

wire f6_p1,f6_p3,f6_p4,f6_p6,f6_p10;

_42 f6 (
	.p15	(f7_p14)	,
	.p14	(f7_p13)	,
	.p13	(f7_p12) ,
	.p12	(f7_p11)	,

	.p1	(f6_p1)	,
	.p3	(f6_p3)	,
	.p4	(f6_p4)	,
	.p6	(f6_p6)	,
	.p10	(f6_p10)	
);



wire e5_p5,e5_p6;
_74 e5 (
	.p2	(0),
	.p3	(0),
	.p4	(f6_p4),
	.p1	(f6_p10),
	.p5	(e5_p5),
	.p6	(e5_p6)
);



wire e6_p3 = ~ ( f6_p1 & e6_p6 ) ;
wire e6_p6 = ~ ( e6_p3 & f6_p3 ) ;


wire f5_p10,f5_p15,f5_p7,f5_p2;
_75365 f5 (
	.p11	(e6_p6),
	.p14	(e5_p6),
	.p12	(1),
	.p13	(1),
	.p4	(1),
	.p5	(1),
	.p6	(b5_p6),
	.p3	(b5_p3),
	
	.p10	(f5_p10),
	.p15	(f5_p15),
	.p7	(f5_p7),
	.p2	(f5_p2)
);


wire j3_p8,j3_p6;
	
wire l4_p4,l4_p7,ram_nrw;
_157 l4 (

	.p2	(h5_p11),
	.p3	(ad[0]),
	.p5	(~j3_p9),
	.p6	(c4_p6),
	.p11	(1),
	.p10	(nWR),
	
	.p4	(l4_p4),
	.p7	(l4_p7),
	.p9	(ram_nrw),

	.p15	(0),
	.p1	(h5_p12)
);



/* *************** L5,L6,L7 ***************
	ramアクセス用
	CPUからのアドレスバスとビデオ出力のアドレスバスの選択
	04/19現在の状況ではおそらく不要
*/

wire [15:0] ram_a;
	
_157 l5 (
	.p2	(j5_p14),
	.p3 	(ad[1]),
	.p5	(j5_p13),
	.p6	(ad[2]),
	.p11	(j5_p12),
	.p10	(ad[3]),
	.p14	(j5_p11),
	.p13	(ad[4]),
	
	.p15 (0),
	.p1	(h5_p12),
	
	.p4	(ram_a[0]),
	.p7	(ram_a[1]),
	.p9	(ram_a[2]),
	.p12	(ram_a[3]),
	
);

_157 l6 (
	.p2	(j6_p14),
	.p3 	(ad[5]),
	.p5	(j6_p13),
	.p6	(ad[6]),
	.p11	(j6_p12),
	.p10	(ad[7]),
	.p14	(j6_p11),
	.p13	(ad[8]),
	
	.p15 (0),
	.p1	(h5_p12),
	
	.p4	(ram_a[4]),
	.p7	(ram_a[5]),
	.p9	(ram_a[6]),
	.p12	(ram_a[7]),
	
);

_157 l7 (
	.p2	(j7_p14),
	.p3 	(ad[9]),
	.p5	(j7_p13),
	.p6	(ad[10]),
	.p11	(j7_p12),
	.p10	(ad[11]),
	.p14	(j7_p11),
	.p13	(ad[12]),
	
	.p15 (0),
	.p1	(h5_p12),
	
	.p4	(ram_a[8]),
	.p7	(ram_a[9]),
	.p9	(ram_a[10]),
	.p12	(ram_a[11]),
	
);

	
	
	
//temp, wire declarations





/* ********************************************
	CPUへのデータ引き渡し関連
	cpu_in に入力するデータは id mx ram_dout　から選択
	id:　romからの入力
	mx:　ポート入力とシフトレジスタ関連
	ram_dout: ramからの入力
	選択は　b4_p13 と b4_p4　で。

	B port

	wire b4_p13 = ~ ( sd0 | sd6 );

	wire b4_p10 = ~ ( ad[13] | sd6 );
	wire b4_p4  = ~ ( b4_p10 | sd0 );

	A port
	
	となっている。　
	D0  INTA  割り込み応答バスサイクルであることを示す。
	D1  WO*   書き込みを行うバスサイクルであることを示す。
	D2  STACK スタックポインタの指すメモリへのバスサイクルであることを示す。
	D3  HLTA  HALT命令を実行していることを示す。
	D4  OUT   I/Oポートへの出力サイクルであることを示す。
	D5  M1    CPUが命令の第1バイトを読み込むバスサイクルであることを示す。
	D6  INP   I/Oポートからの入力サイクルであることを示す。
	D7  MEMR  メモリからの読み込みを行うバスサイクルであることを示す。

						sd0 sd6 ad[13]    RESULT
	b4p13				0   0 				-> 1	 
					   0   1					->	0
						1   0					->	0
						1   1					->	0

						
	b4p4				ad[13] sd6 sd0
						0        0   0		-> 0
						0			0	 1		-> 0
						1        0   0		-> 1
						1			0   1		-> 0
						0			1   0		-> 1
						0			1	 1		-> 0
						1			1	 0		-> 1
						1			1	 1		-> 1

			
	 b4p13 &  b4p4 -> sd0==0,sd6==0であり、ad[13]==1 //ram
	 b4p13 & ~b4p4 -> sd0==0,sd6==0であり、ad[13]==0 //ram以外のメモリアクセス
	~b4p13 &  b4p4 -> sd0=0,sd6=1,ad[13]=0			 //port mixed bus
							sd0=1,sd6=1,ad[13]=1			 //これはない？？
	~b4p13 & ~b4p4 -> sd0=1,sd6=1,ad[13]=0			 //？？
	
							
	
						
   ******************************************** */
	
/* multiplex data bus */
// in A = b4_p4;
// in B = b4_p13;
wire [7:0]id;
wire [7:0]mx;


																			// B A
assign cpu_di = ( b4_p13 & b4_p4 ) ? ram_dout_cpu :		// 1 1
					 ( b4_p13 & ~b4_p4 ) ? 	id :					// 1 0
					 ( ~b4_p13 & b4_p4 ) ? 	mx :					// 0 1
						{ 3'b110, j7_p12, c6_p3, 3'b111 };

						
wire [7:0]mb14241_o;

/* ********************************************
	カスタムシフトレジスタ
	MB14241
	******************************************** */

	
//assign DIP4 = 1;
assign mx = mb14241_o;

mb14241_and_inp ic3x (
	.d0	(cpu_do[0]),
	.d1	(cpu_do[1]),
	.d2	(cpu_do[2]),
	.d3	(cpu_do[3]),
	.d4	(cpu_do[4]),
	.d5	(cpu_do[5]),
	.d6	(cpu_do[6]),
	.d7	(cpu_do[7]),

	.port4	(port[4]),
	.port2	(port[2]),

	.nreset	(nRESET),
	.mx		(mb14241_o),
	.mclk		(vclk),
	.a8		(ad[8]),
	.a9		(ad[9]),
	.a10		(ad[10]),
	
	.L			(L),
	.R			(R),
	.FIRE		(FIRE),
	.S1		(S1),
	.S2		(S2),
	.COIN		(COIN),
	.DIP3		(DIP3),
	.DIP4		(DIP4),//
	.DIP5		(DIP5),
	.DIP6		(DIP6),
	.DIP7		(DIP7),
	.port7	(0)	
	
	
	
	
);

wire sample =  ~nWR & sd4;
wire[7:0]port;


/* ********************************************
	入出力ポートセレクタ
	ad[10:8]と ~nWR & sd4(CPU側のIO入出ステータス) により選択


	******************************************** */
	

_42 ic13
(
	.p13	(ad[10]),
	.p14	(ad[9]),
	.p15	(ad[8]),
	.p12	(~sample),
	
	.p2	(port[1]),
	.p3	(port[2]),
	.p4	(port[3]),
	.p5	(port[4]),
	.p6	(port[5]),
	.p7	(port[6]),
	.p9	(port[7])

);



/* ********************************************
	sount port
	サウンド出力
	
	******************************************** */
reg [10:0]sx;
//一応クロックを入れてラッチ動作させる。適当でよいはず//
always @(posedge vclk)
begin
	
	if (port[3]==0)
			begin
			sx[5:0] = cpu_do[5:0];
			end
	if (port[5]==0)
			begin
			sx[10:6] = cpu_do[4:0];
			end
			
end
assign LED = sx[3:0];

assign sx_out[9:0] = { sx[10],sx[9],sx[8],sx[7],sx[6],1'b0/*sx[4]*/,sx[3],sx[2],sx[1],~sx[0] };


//LVDSでの出力用
//SCLKはVCLK,RCLKはVCLK/16

assign sx_out_lvds = sx_out[~hcount[3:0]];
assign sx_sclk = ~vclk;
assign sx_rclk = (hcount[3:0]==4'b0000);



/* ********************************************
	8080 cpu
	
	
	******************************************** */

//cpu input port//
wire [7:0]cpu_di;

//cpu output port
wire nRESET,ready,hold,int;
wire dbin,cpusync,inte,vait,hlda,nWR;

//power up reset、ウオッチドックタイマーは未実装

//20210627 bprom settingがおわったら一度リセットがかかるようにする
assign nRESET = ~ ( SW2 | bprom_setting );  //1;

assign ready = c5_p5;
assign int = c5_p9;
assign hold = 0;


T8080se r2 (
	.RESET_n		(nRESET),
	//20210414 changed f7_p14 -> f7_p11
	.CLK			(f7_p11),
	.CLKEN		(1),
	.READY		(ready),
	.HOLD			(hold),
	.INT			(int),
	.INTE			(inte),
	.DBIN			(dbin),
	.SYNC			(cpusync),
	.VAIT			(vait),
	.HLDA			(hlda),
	.WR_n			(nWR),
	.A				(ad),
	.DI			(cpu_di),
	.DO			(cpu_do),
);

wire sd0,sd1,sd3,sd4,sd6,sd7;


/* CPUのステータスラッチ */
/* 8080の場合はこんなかんじ

D0  INTA  割り込み応答バスサイクルであることを示す。
D1  WO*   書き込みを行うバスサイクルであることを示す。
D2  STACK スタックポインタの指すメモリへのバスサイクルであることを示す。
D3  HLTA  HALT命令を実行していることを示す。
D4  OUT   I/Oポートへの出力サイクルであることを示す。
D5  M1    CPUが命令の第1バイトを読み込むバスサイクルであることを示す。
D6  INP   I/Oポートからの入力サイクルであることを示す。
D7  MEMR  メモリからの読み込みを行うバスサイクルであることを示す。

 */


_174 h7
(
	.p3	(cpu_do[0]),
	.p4	(cpu_do[1]),
	.p6	(cpu_do[3]),
	.p11	(cpu_do[4]),
	.p13	(cpu_do[6]),
	.p14	(cpu_do[7]),
	//20210415 " &cpusync " 
	.p9	(e6_p3 & cpusync),

	.p2	(sd0),
	.p5	(sd1),
	.p7	(sd3),
	.p10	(sd4),
	.p12	(sd6),
	.p15	(sd7),
	
	.p1	(1)


);


/* ********************************************

	ビデオ同期信号生成
	
	******************************************** */
	

wire [7:0]hcount;
wire [7:0]vcount;

wire hsync;
wire vsync;
wire hblank,vblank;

inv_video video0
(
	.clk		(vclk),
	.hc		(hcount),
	.vc		(vcount),
	.hb		(hblank),
	.vb		(vblank),
	.hs		(hsync),
	.vs		(vsync)

);


wire compblank = ~( hsync | vsync );

/* sync counter signals */
wire h5_p14 = hcount[0];	//1H
wire h5_p13 = hcount[1]; 	//2H
wire h5_p12 = hcount[2];	//4H
wire h5_p11 = hcount[3]; 	//8H

wire j3_p9 = hblank;		//hblank

wire j5_p14 = hcount[4];	//16H
wire j5_p13	= hcount[5];	//32H
wire j5_p12	= hcount[6];	//64H
wire j5_p11	= hcount[7];	//128H

wire j6_p14	= vcount[0];	//1V	
wire j6_p13	= vcount[1];	//2V
wire j6_p12	= vcount[2];	//4V
wire j6_p11	= vcount[3];	//8V

wire j7_p14	= vcount[4];	//16V	
wire j7_p13	= vcount[5];	//32V
wire j7_p12	= vcount[6];	//64V
wire j7_p11	= vcount[7];	//128V

wire d5_p9 = vblank;

endmodule





/* ********************************************

	サブモジュール


	_75365  　ロジックIC
	_shifter シフトレジスタ（カスタム版）
	
	
	******************************************** */




module _75365 (
	input		p3,p4,p5,p6,p11,p12,p13,p14,
	output	p2,p7,p10,p15

);
	assign p2 = ~ ( p3 & p4 & p5 );
	assign p7 = ~ ( p6 & p4 & p5 );
	assign p10 = ~ ( p11 & p12 & p13 );
	assign p15 = ~ ( p14 & p12 & p13 );

endmodule



module _shifter 
(
	input wire [7:0] data,
	input	wire clk,
	input wire nld,
	input wire inv,
	output wire out
);

reg[7:0] r;
reg[2:0] counter;
reg o;

reg nld_latch;

always @(posedge clk)
begin
	if (nld == 0 && nld_latch == 1)
		begin
		counter = 0;
		r = data;
		end 
		o = r[ counter^{3{inv}}];
		nld_latch = nld;
		counter = counter + 1;

end	

assign  out = o;

endmodule


/* ********************************************

	ビデオ信号生成回路
	
	inputは clk　のみ。ビデオクロックとして 19.968kHz を入力
	これを分周してビデオ信号として生成する。
	
	
	
	
	******************************************** */


		
module inv_video (
	input wire clk,
	output wire [7:0] hc,
	output wire [7:0] vc,
	output wire hb,
	output wire vb,
	output wire hs,
	output wire vs	
	
);

// sync counter for module
reg [8:0]hcount;
reg [8:0]vcount;
//initial vcount = 8'h20;
//reg hcq;
//reg vcq;
//wire hblank;
//wire vblank;
//wire hblank;
//hcount
//0-----255 192----255
//0------ff-c0------ff
//0------ff-1c0-----1ff


always @(posedge clk)
	hcount <= ( hcount==9'h0ff) ?  9'h1c0 : hcount + 1;

	assign hs = ( hcount[8] & ~hcount[5] & hcount[4] );
	assign hb = hcount[8];
	assign hc =  hcount[7:0];


always @(posedge clk)
begin

//V count
//32----255 218-255
//20----ff da---ff
//
//32----255 474-511
//20----ff 1da--1ff

//hsync edge のときだけ動作
	if ( hcount==9'h1c0 )
						vcount <= (vcount == 9'h0ff ) ? 9'h1da :
									 (vcount == 9'h1ff ) ? 9'h020 :
									  vcount + 1;

end
									  
assign vc = vcount[7:0];
assign vb = vcount[8];
assign vs = (vcount[8] & vcount[2] & vcount[3] & ~vcount[4]);


endmodule

/* ********************************************

	カスタムチップ mb14241
	
	回路が共通されている部分もあるので、入出力ポートと一緒に実装
	
	
	******************************************** */




module mb14241_and_inp (
	input	wire a8,a9,a10,
	input wire d0,d1,d2,d3,d4,d5,d6,d7, //d0-d8
	input wire port4,port2,  //port 4, port 2
	input wire nreset,
	output wire [7:0]mx,//mx0-7
	input wire mclk, //synchronous clock..perhaps cpuclk?? or vclk??
	output wire sh1,sh2,sh3,
	
	input wire L,R,FIRE,S1,S2,COIN,
	input wire DIP3,DIP4,DIP5,DIP6,DIP7,
	input wire port7
/*	
2=B(a9)	14=A(a8) 

BA=11 S7,S6,S5,S4,S3,S2,S1,S0
BA=10 DIP7,R,L,Fire,DIP6,Tilt,DIP5,DIP3
BA=01 0,R,L,Fire,1,2S,1S,C
BA=00 Port7,R,L,Fire,1,1,1,DIP4
*/	
	
);

reg port2x,port4x;

//DIP3,5 = lives
//DIP4 = service
//DIP6,7 = BONUS
// 
assign mx = /* 3 */ (a9 & a8) ? mxx :
				/* 2 */ (a9 & ~a8) ? {DIP7,R,L,FIRE,DIP6,1'b0,DIP5,DIP3} :
				/* 1 */ (~a9 & a8) ? {1'b0,R,L,FIRE,1'b1,S1,S1,COIN} :	

				/* 0 */ {port7,   R,L,FIRE,3'b111, DIP4} ;
	//			/* 0 */ {port7,1'b1,L,FIRE,3'b000, 1'b0} ;　//only galaxy wars
				
wire [7:0] mxx;

always @(negedge mclk)
begin
	port2x <= ~port2;
	port4x <= ~port4;
end	

//wire sh3,sh2,sh1;

_175	ic13 (
	.p4	(d2),
	.p12	(d1),
	.p13	(d0),

	.p9	(port2x),
	
	.p2	(sh3),
	.p10	(sh2),
	.p15	(sh1),
	
	.p1	(1)
	
);

wire ds9,ds1,ds8;
_175	ic14	(
	.p5	(d1),
	.p13	(ds9),
	.p4	(d0),
	
	.p9	(port4x),
	
	.p1	(nreset),
	
	.p7	(ds9),
	.p15	(ds1),
	.p2	(ds8)
);

wire dsc,ds4,dsb,ds3,dsa,ds2;
_174	ic15	(
	.p3	(d4),
	.p4	(dsc),
	.p6	(d3),
	.p11	(dsb),
	.p13	(d2),
	.p14	(dsa),
	
	.p9	(port4x),
	.p1	(nreset),
	
	.p2	(dsc),
	.p5	(ds4),
	.p7	(dsb),
	.p10	(ds3),
	.p12	(dsa),
	.p15	(ds2)

	);

wire dsf,ds7,dse,ds6,dsd,ds5;
_174 ic16 (

	.p3	(d7),
	.p4	(dsf),
	.p6	(d6),
	.p11	(dse),
	.p13	(d5),
	.p14	(dsd),
	
	.p9	(port4x),
	.p1	(nreset),
	
	.p2	(dsf),
	.p5	(ds7),
	.p7	(dse),
	.p10	(ds6),
	.p12	(dsd),
	.p15	(ds5)
);

_151	ic12 (
	.p4	(ds8),
	.p3	(ds7),
	.p2	(ds6),
	.p1	(ds5),
	.p15	(ds4),
	.p14	(ds3),
	.p13	(ds2),
	.p12	(ds1),
	
	.p9	(sh3),
	.p10	(sh2),
	.p11	(sh1),
	
	.p5	(mxx[0]),
);

_151	ic11 (
	.p4	(ds9),
	.p3	(ds8),
	.p2	(ds7),
	.p1	(ds6),
	.p15	(ds5),
	.p14	(ds4),
	.p13	(ds3),
	.p12	(ds2),
	
	.p9	(sh3),
	.p10	(sh2),
	.p11	(sh1),
	
	.p5	(mxx[1]),
);

_151	ic10 (
	.p4	(dsa),
	.p3	(ds9),
	.p2	(ds8),
	.p1	(ds7),
	.p15	(ds6),
	.p14	(ds5),
	.p13	(ds4),
	.p12	(ds3),
	
	.p9	(sh3),
	.p10	(sh2),
	.p11	(sh1),
	
	.p5	(mxx[2]),
);

_151	ic9 (
	.p4	(dsb),
	.p3	(dsa),
	.p2	(ds9),
	.p1	(ds8),
	.p15	(ds7),
	.p14	(ds6),
	.p13	(ds5),
	.p12	(ds4),
	
	.p9	(sh3),
	.p10	(sh2),
	.p11	(sh1),
	
	.p5	(mxx[3]),
);


_151	ic41 (
	.p4	(dsc),
	.p3	(dsb),
	.p2	(dsa),
	.p1	(ds9),
	.p15	(ds8),
	.p14	(ds7),
	.p13	(ds6),
	.p12	(ds5),
	
	.p9	(sh3),
	.p10	(sh2),
	.p11	(sh1),
	
	.p5	(mxx[4]),
);

_151	ic42 (
	.p4	(dsd),
	.p3	(dsc),
	.p2	(dsb),
	.p1	(dsa),
	.p15	(ds9),
	.p14	(ds8),
	.p13	(ds7),
	.p12	(ds6),
	
	.p9	(sh3),
	.p10	(sh2),
	.p11	(sh1),
	
	.p5	(mxx[5]),
);
_151	ic43 (
	.p4	(dse),
	.p3	(dsd),
	.p2	(dsc),
	.p1	(dsb),
	.p15	(dsa),
	.p14	(ds9),
	.p13	(ds8),
	.p12	(ds7),
	
	.p9	(sh3),
	.p10	(sh2),
	.p11	(sh1),
	
	.p5	(mxx[6]),
);
_151	ic44 (
	.p4	(dsf),
	.p3	(dse),
	.p2	(dsd),
	.p1	(dsc),
	.p15	(dsb),
	.p14	(dsa),
	.p13	(ds9),
	.p12	(ds8),
	
	.p9	(sh3),
	.p10	(sh2),
	.p11	(sh1),
	
	.p5	(mxx[7]),
);

endmodule








/* ********************************************

	エクステンド音生成回路

	vc[3]をベースに、ne555とandをとる。
	ne555の周波数はLTSpiceによる実測値
	
	
	******************************************** */



module extend_sound
(
	input	inclk_0487mhz,
	input	vc3,
	output [7:0]out,
	input sx4
);

//making ne555 "almost"8Hz signal 
//phase
// 0.0000 ---  32.6257 msec  L 
//32.6258 --- 134.7060 msec  H
//
// 0...3265....13471 / 10usec
// 0...16325...67355 / 2usec
// 0...3e00....ffff  / 2.055usec almost 0.487MHz
reg [15:0]count;
reg r;

wire w;

always @(posedge inclk_0487mhz) 
								if (sx4)	count<=count+1;
								else count<=0;

assign w = ( count > 16'h3e00 ) & sx4;

assign out = {8{vc3 & w}};


endmodule


