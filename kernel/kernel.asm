
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	0000a117          	auipc	sp,0xa
    80000004:	83010113          	addi	sp,sp,-2000 # 80009830 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	070000ef          	jal	ra,80000086 <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    80000026:	0037969b          	slliw	a3,a5,0x3
    8000002a:	02004737          	lui	a4,0x2004
    8000002e:	96ba                	add	a3,a3,a4
    80000030:	0200c737          	lui	a4,0x200c
    80000034:	ff873603          	ld	a2,-8(a4) # 200bff8 <_entry-0x7dff4008>
    80000038:	000f4737          	lui	a4,0xf4
    8000003c:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    80000040:	963a                	add	a2,a2,a4
    80000042:	e290                	sd	a2,0(a3)

  // prepare information in scratch[] for timervec.
  // scratch[0..3] : space for timervec to save registers.
  // scratch[4] : address of CLINT MTIMECMP register.
  // scratch[5] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &mscratch0[32 * id];
    80000044:	0057979b          	slliw	a5,a5,0x5
    80000048:	078e                	slli	a5,a5,0x3
    8000004a:	00009617          	auipc	a2,0x9
    8000004e:	fe660613          	addi	a2,a2,-26 # 80009030 <mscratch0>
    80000052:	97b2                	add	a5,a5,a2
  scratch[4] = CLINT_MTIMECMP(id);
    80000054:	f394                	sd	a3,32(a5)
  scratch[5] = interval;
    80000056:	f798                	sd	a4,40(a5)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000058:	34079073          	csrw	mscratch,a5
  asm volatile("csrw mtvec, %0" : : "r" (x));
    8000005c:	00006797          	auipc	a5,0x6
    80000060:	c8478793          	addi	a5,a5,-892 # 80005ce0 <timervec>
    80000064:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000068:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    8000006c:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000070:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    80000074:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000078:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    8000007c:	30479073          	csrw	mie,a5
}
    80000080:	6422                	ld	s0,8(sp)
    80000082:	0141                	addi	sp,sp,16
    80000084:	8082                	ret

0000000080000086 <start>:
{
    80000086:	1141                	addi	sp,sp,-16
    80000088:	e406                	sd	ra,8(sp)
    8000008a:	e022                	sd	s0,0(sp)
    8000008c:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000008e:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000092:	7779                	lui	a4,0xffffe
    80000094:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    80000098:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    8000009a:	6705                	lui	a4,0x1
    8000009c:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a2:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000a6:	00001797          	auipc	a5,0x1
    800000aa:	e1878793          	addi	a5,a5,-488 # 80000ebe <main>
    800000ae:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b2:	4781                	li	a5,0
    800000b4:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000b8:	67c1                	lui	a5,0x10
    800000ba:	17fd                	addi	a5,a5,-1
    800000bc:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c0:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000c4:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000c8:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000cc:	10479073          	csrw	sie,a5
  timerinit();
    800000d0:	00000097          	auipc	ra,0x0
    800000d4:	f4c080e7          	jalr	-180(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000d8:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000dc:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000de:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e0:	30200073          	mret
}
    800000e4:	60a2                	ld	ra,8(sp)
    800000e6:	6402                	ld	s0,0(sp)
    800000e8:	0141                	addi	sp,sp,16
    800000ea:	8082                	ret

00000000800000ec <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000ec:	715d                	addi	sp,sp,-80
    800000ee:	e486                	sd	ra,72(sp)
    800000f0:	e0a2                	sd	s0,64(sp)
    800000f2:	fc26                	sd	s1,56(sp)
    800000f4:	f84a                	sd	s2,48(sp)
    800000f6:	f44e                	sd	s3,40(sp)
    800000f8:	f052                	sd	s4,32(sp)
    800000fa:	ec56                	sd	s5,24(sp)
    800000fc:	0880                	addi	s0,sp,80
    800000fe:	8a2a                	mv	s4,a0
    80000100:	84ae                	mv	s1,a1
    80000102:	89b2                	mv	s3,a2
  int i;

  acquire(&cons.lock);
    80000104:	00011517          	auipc	a0,0x11
    80000108:	72c50513          	addi	a0,a0,1836 # 80011830 <cons>
    8000010c:	00001097          	auipc	ra,0x1
    80000110:	b04080e7          	jalr	-1276(ra) # 80000c10 <acquire>
  for(i = 0; i < n; i++){
    80000114:	05305b63          	blez	s3,8000016a <consolewrite+0x7e>
    80000118:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011a:	5afd                	li	s5,-1
    8000011c:	4685                	li	a3,1
    8000011e:	8626                	mv	a2,s1
    80000120:	85d2                	mv	a1,s4
    80000122:	fbf40513          	addi	a0,s0,-65
    80000126:	00002097          	auipc	ra,0x2
    8000012a:	460080e7          	jalr	1120(ra) # 80002586 <either_copyin>
    8000012e:	01550c63          	beq	a0,s5,80000146 <consolewrite+0x5a>
      break;
    uartputc(c);
    80000132:	fbf44503          	lbu	a0,-65(s0)
    80000136:	00000097          	auipc	ra,0x0
    8000013a:	7aa080e7          	jalr	1962(ra) # 800008e0 <uartputc>
  for(i = 0; i < n; i++){
    8000013e:	2905                	addiw	s2,s2,1
    80000140:	0485                	addi	s1,s1,1
    80000142:	fd299de3          	bne	s3,s2,8000011c <consolewrite+0x30>
  }
  release(&cons.lock);
    80000146:	00011517          	auipc	a0,0x11
    8000014a:	6ea50513          	addi	a0,a0,1770 # 80011830 <cons>
    8000014e:	00001097          	auipc	ra,0x1
    80000152:	b76080e7          	jalr	-1162(ra) # 80000cc4 <release>

  return i;
}
    80000156:	854a                	mv	a0,s2
    80000158:	60a6                	ld	ra,72(sp)
    8000015a:	6406                	ld	s0,64(sp)
    8000015c:	74e2                	ld	s1,56(sp)
    8000015e:	7942                	ld	s2,48(sp)
    80000160:	79a2                	ld	s3,40(sp)
    80000162:	7a02                	ld	s4,32(sp)
    80000164:	6ae2                	ld	s5,24(sp)
    80000166:	6161                	addi	sp,sp,80
    80000168:	8082                	ret
  for(i = 0; i < n; i++){
    8000016a:	4901                	li	s2,0
    8000016c:	bfe9                	j	80000146 <consolewrite+0x5a>

000000008000016e <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    8000016e:	7119                	addi	sp,sp,-128
    80000170:	fc86                	sd	ra,120(sp)
    80000172:	f8a2                	sd	s0,112(sp)
    80000174:	f4a6                	sd	s1,104(sp)
    80000176:	f0ca                	sd	s2,96(sp)
    80000178:	ecce                	sd	s3,88(sp)
    8000017a:	e8d2                	sd	s4,80(sp)
    8000017c:	e4d6                	sd	s5,72(sp)
    8000017e:	e0da                	sd	s6,64(sp)
    80000180:	fc5e                	sd	s7,56(sp)
    80000182:	f862                	sd	s8,48(sp)
    80000184:	f466                	sd	s9,40(sp)
    80000186:	f06a                	sd	s10,32(sp)
    80000188:	ec6e                	sd	s11,24(sp)
    8000018a:	0100                	addi	s0,sp,128
    8000018c:	8b2a                	mv	s6,a0
    8000018e:	8aae                	mv	s5,a1
    80000190:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000192:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    80000196:	00011517          	auipc	a0,0x11
    8000019a:	69a50513          	addi	a0,a0,1690 # 80011830 <cons>
    8000019e:	00001097          	auipc	ra,0x1
    800001a2:	a72080e7          	jalr	-1422(ra) # 80000c10 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    800001a6:	00011497          	auipc	s1,0x11
    800001aa:	68a48493          	addi	s1,s1,1674 # 80011830 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001ae:	89a6                	mv	s3,s1
    800001b0:	00011917          	auipc	s2,0x11
    800001b4:	71890913          	addi	s2,s2,1816 # 800118c8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001b8:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ba:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001bc:	4da9                	li	s11,10
  while(n > 0){
    800001be:	07405863          	blez	s4,8000022e <consoleread+0xc0>
    while(cons.r == cons.w){
    800001c2:	0984a783          	lw	a5,152(s1)
    800001c6:	09c4a703          	lw	a4,156(s1)
    800001ca:	02f71463          	bne	a4,a5,800001f2 <consoleread+0x84>
      if(myproc()->killed){
    800001ce:	00002097          	auipc	ra,0x2
    800001d2:	8f0080e7          	jalr	-1808(ra) # 80001abe <myproc>
    800001d6:	591c                	lw	a5,48(a0)
    800001d8:	e7b5                	bnez	a5,80000244 <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001da:	85ce                	mv	a1,s3
    800001dc:	854a                	mv	a0,s2
    800001de:	00002097          	auipc	ra,0x2
    800001e2:	0f0080e7          	jalr	240(ra) # 800022ce <sleep>
    while(cons.r == cons.w){
    800001e6:	0984a783          	lw	a5,152(s1)
    800001ea:	09c4a703          	lw	a4,156(s1)
    800001ee:	fef700e3          	beq	a4,a5,800001ce <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001f2:	0017871b          	addiw	a4,a5,1
    800001f6:	08e4ac23          	sw	a4,152(s1)
    800001fa:	07f7f713          	andi	a4,a5,127
    800001fe:	9726                	add	a4,a4,s1
    80000200:	01874703          	lbu	a4,24(a4)
    80000204:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    80000208:	079c0663          	beq	s8,s9,80000274 <consoleread+0x106>
    cbuf = c;
    8000020c:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000210:	4685                	li	a3,1
    80000212:	f8f40613          	addi	a2,s0,-113
    80000216:	85d6                	mv	a1,s5
    80000218:	855a                	mv	a0,s6
    8000021a:	00002097          	auipc	ra,0x2
    8000021e:	316080e7          	jalr	790(ra) # 80002530 <either_copyout>
    80000222:	01a50663          	beq	a0,s10,8000022e <consoleread+0xc0>
    dst++;
    80000226:	0a85                	addi	s5,s5,1
    --n;
    80000228:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    8000022a:	f9bc1ae3          	bne	s8,s11,800001be <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022e:	00011517          	auipc	a0,0x11
    80000232:	60250513          	addi	a0,a0,1538 # 80011830 <cons>
    80000236:	00001097          	auipc	ra,0x1
    8000023a:	a8e080e7          	jalr	-1394(ra) # 80000cc4 <release>

  return target - n;
    8000023e:	414b853b          	subw	a0,s7,s4
    80000242:	a811                	j	80000256 <consoleread+0xe8>
        release(&cons.lock);
    80000244:	00011517          	auipc	a0,0x11
    80000248:	5ec50513          	addi	a0,a0,1516 # 80011830 <cons>
    8000024c:	00001097          	auipc	ra,0x1
    80000250:	a78080e7          	jalr	-1416(ra) # 80000cc4 <release>
        return -1;
    80000254:	557d                	li	a0,-1
}
    80000256:	70e6                	ld	ra,120(sp)
    80000258:	7446                	ld	s0,112(sp)
    8000025a:	74a6                	ld	s1,104(sp)
    8000025c:	7906                	ld	s2,96(sp)
    8000025e:	69e6                	ld	s3,88(sp)
    80000260:	6a46                	ld	s4,80(sp)
    80000262:	6aa6                	ld	s5,72(sp)
    80000264:	6b06                	ld	s6,64(sp)
    80000266:	7be2                	ld	s7,56(sp)
    80000268:	7c42                	ld	s8,48(sp)
    8000026a:	7ca2                	ld	s9,40(sp)
    8000026c:	7d02                	ld	s10,32(sp)
    8000026e:	6de2                	ld	s11,24(sp)
    80000270:	6109                	addi	sp,sp,128
    80000272:	8082                	ret
      if(n < target){
    80000274:	000a071b          	sext.w	a4,s4
    80000278:	fb777be3          	bgeu	a4,s7,8000022e <consoleread+0xc0>
        cons.r--;
    8000027c:	00011717          	auipc	a4,0x11
    80000280:	64f72623          	sw	a5,1612(a4) # 800118c8 <cons+0x98>
    80000284:	b76d                	j	8000022e <consoleread+0xc0>

0000000080000286 <consputc>:
{
    80000286:	1141                	addi	sp,sp,-16
    80000288:	e406                	sd	ra,8(sp)
    8000028a:	e022                	sd	s0,0(sp)
    8000028c:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000028e:	10000793          	li	a5,256
    80000292:	00f50a63          	beq	a0,a5,800002a6 <consputc+0x20>
    uartputc_sync(c);
    80000296:	00000097          	auipc	ra,0x0
    8000029a:	564080e7          	jalr	1380(ra) # 800007fa <uartputc_sync>
}
    8000029e:	60a2                	ld	ra,8(sp)
    800002a0:	6402                	ld	s0,0(sp)
    800002a2:	0141                	addi	sp,sp,16
    800002a4:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a6:	4521                	li	a0,8
    800002a8:	00000097          	auipc	ra,0x0
    800002ac:	552080e7          	jalr	1362(ra) # 800007fa <uartputc_sync>
    800002b0:	02000513          	li	a0,32
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	546080e7          	jalr	1350(ra) # 800007fa <uartputc_sync>
    800002bc:	4521                	li	a0,8
    800002be:	00000097          	auipc	ra,0x0
    800002c2:	53c080e7          	jalr	1340(ra) # 800007fa <uartputc_sync>
    800002c6:	bfe1                	j	8000029e <consputc+0x18>

00000000800002c8 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c8:	1101                	addi	sp,sp,-32
    800002ca:	ec06                	sd	ra,24(sp)
    800002cc:	e822                	sd	s0,16(sp)
    800002ce:	e426                	sd	s1,8(sp)
    800002d0:	e04a                	sd	s2,0(sp)
    800002d2:	1000                	addi	s0,sp,32
    800002d4:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002d6:	00011517          	auipc	a0,0x11
    800002da:	55a50513          	addi	a0,a0,1370 # 80011830 <cons>
    800002de:	00001097          	auipc	ra,0x1
    800002e2:	932080e7          	jalr	-1742(ra) # 80000c10 <acquire>

  switch(c){
    800002e6:	47d5                	li	a5,21
    800002e8:	0af48663          	beq	s1,a5,80000394 <consoleintr+0xcc>
    800002ec:	0297ca63          	blt	a5,s1,80000320 <consoleintr+0x58>
    800002f0:	47a1                	li	a5,8
    800002f2:	0ef48763          	beq	s1,a5,800003e0 <consoleintr+0x118>
    800002f6:	47c1                	li	a5,16
    800002f8:	10f49a63          	bne	s1,a5,8000040c <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002fc:	00002097          	auipc	ra,0x2
    80000300:	2e0080e7          	jalr	736(ra) # 800025dc <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000304:	00011517          	auipc	a0,0x11
    80000308:	52c50513          	addi	a0,a0,1324 # 80011830 <cons>
    8000030c:	00001097          	auipc	ra,0x1
    80000310:	9b8080e7          	jalr	-1608(ra) # 80000cc4 <release>
}
    80000314:	60e2                	ld	ra,24(sp)
    80000316:	6442                	ld	s0,16(sp)
    80000318:	64a2                	ld	s1,8(sp)
    8000031a:	6902                	ld	s2,0(sp)
    8000031c:	6105                	addi	sp,sp,32
    8000031e:	8082                	ret
  switch(c){
    80000320:	07f00793          	li	a5,127
    80000324:	0af48e63          	beq	s1,a5,800003e0 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000328:	00011717          	auipc	a4,0x11
    8000032c:	50870713          	addi	a4,a4,1288 # 80011830 <cons>
    80000330:	0a072783          	lw	a5,160(a4)
    80000334:	09872703          	lw	a4,152(a4)
    80000338:	9f99                	subw	a5,a5,a4
    8000033a:	07f00713          	li	a4,127
    8000033e:	fcf763e3          	bltu	a4,a5,80000304 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000342:	47b5                	li	a5,13
    80000344:	0cf48763          	beq	s1,a5,80000412 <consoleintr+0x14a>
      consputc(c);
    80000348:	8526                	mv	a0,s1
    8000034a:	00000097          	auipc	ra,0x0
    8000034e:	f3c080e7          	jalr	-196(ra) # 80000286 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000352:	00011797          	auipc	a5,0x11
    80000356:	4de78793          	addi	a5,a5,1246 # 80011830 <cons>
    8000035a:	0a07a703          	lw	a4,160(a5)
    8000035e:	0017069b          	addiw	a3,a4,1
    80000362:	0006861b          	sext.w	a2,a3
    80000366:	0ad7a023          	sw	a3,160(a5)
    8000036a:	07f77713          	andi	a4,a4,127
    8000036e:	97ba                	add	a5,a5,a4
    80000370:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000374:	47a9                	li	a5,10
    80000376:	0cf48563          	beq	s1,a5,80000440 <consoleintr+0x178>
    8000037a:	4791                	li	a5,4
    8000037c:	0cf48263          	beq	s1,a5,80000440 <consoleintr+0x178>
    80000380:	00011797          	auipc	a5,0x11
    80000384:	5487a783          	lw	a5,1352(a5) # 800118c8 <cons+0x98>
    80000388:	0807879b          	addiw	a5,a5,128
    8000038c:	f6f61ce3          	bne	a2,a5,80000304 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000390:	863e                	mv	a2,a5
    80000392:	a07d                	j	80000440 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000394:	00011717          	auipc	a4,0x11
    80000398:	49c70713          	addi	a4,a4,1180 # 80011830 <cons>
    8000039c:	0a072783          	lw	a5,160(a4)
    800003a0:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a4:	00011497          	auipc	s1,0x11
    800003a8:	48c48493          	addi	s1,s1,1164 # 80011830 <cons>
    while(cons.e != cons.w &&
    800003ac:	4929                	li	s2,10
    800003ae:	f4f70be3          	beq	a4,a5,80000304 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003b2:	37fd                	addiw	a5,a5,-1
    800003b4:	07f7f713          	andi	a4,a5,127
    800003b8:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003ba:	01874703          	lbu	a4,24(a4)
    800003be:	f52703e3          	beq	a4,s2,80000304 <consoleintr+0x3c>
      cons.e--;
    800003c2:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003c6:	10000513          	li	a0,256
    800003ca:	00000097          	auipc	ra,0x0
    800003ce:	ebc080e7          	jalr	-324(ra) # 80000286 <consputc>
    while(cons.e != cons.w &&
    800003d2:	0a04a783          	lw	a5,160(s1)
    800003d6:	09c4a703          	lw	a4,156(s1)
    800003da:	fcf71ce3          	bne	a4,a5,800003b2 <consoleintr+0xea>
    800003de:	b71d                	j	80000304 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003e0:	00011717          	auipc	a4,0x11
    800003e4:	45070713          	addi	a4,a4,1104 # 80011830 <cons>
    800003e8:	0a072783          	lw	a5,160(a4)
    800003ec:	09c72703          	lw	a4,156(a4)
    800003f0:	f0f70ae3          	beq	a4,a5,80000304 <consoleintr+0x3c>
      cons.e--;
    800003f4:	37fd                	addiw	a5,a5,-1
    800003f6:	00011717          	auipc	a4,0x11
    800003fa:	4cf72d23          	sw	a5,1242(a4) # 800118d0 <cons+0xa0>
      consputc(BACKSPACE);
    800003fe:	10000513          	li	a0,256
    80000402:	00000097          	auipc	ra,0x0
    80000406:	e84080e7          	jalr	-380(ra) # 80000286 <consputc>
    8000040a:	bded                	j	80000304 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000040c:	ee048ce3          	beqz	s1,80000304 <consoleintr+0x3c>
    80000410:	bf21                	j	80000328 <consoleintr+0x60>
      consputc(c);
    80000412:	4529                	li	a0,10
    80000414:	00000097          	auipc	ra,0x0
    80000418:	e72080e7          	jalr	-398(ra) # 80000286 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000041c:	00011797          	auipc	a5,0x11
    80000420:	41478793          	addi	a5,a5,1044 # 80011830 <cons>
    80000424:	0a07a703          	lw	a4,160(a5)
    80000428:	0017069b          	addiw	a3,a4,1
    8000042c:	0006861b          	sext.w	a2,a3
    80000430:	0ad7a023          	sw	a3,160(a5)
    80000434:	07f77713          	andi	a4,a4,127
    80000438:	97ba                	add	a5,a5,a4
    8000043a:	4729                	li	a4,10
    8000043c:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000440:	00011797          	auipc	a5,0x11
    80000444:	48c7a623          	sw	a2,1164(a5) # 800118cc <cons+0x9c>
        wakeup(&cons.r);
    80000448:	00011517          	auipc	a0,0x11
    8000044c:	48050513          	addi	a0,a0,1152 # 800118c8 <cons+0x98>
    80000450:	00002097          	auipc	ra,0x2
    80000454:	004080e7          	jalr	4(ra) # 80002454 <wakeup>
    80000458:	b575                	j	80000304 <consoleintr+0x3c>

000000008000045a <consoleinit>:

void
consoleinit(void)
{
    8000045a:	1141                	addi	sp,sp,-16
    8000045c:	e406                	sd	ra,8(sp)
    8000045e:	e022                	sd	s0,0(sp)
    80000460:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000462:	00008597          	auipc	a1,0x8
    80000466:	bae58593          	addi	a1,a1,-1106 # 80008010 <etext+0x10>
    8000046a:	00011517          	auipc	a0,0x11
    8000046e:	3c650513          	addi	a0,a0,966 # 80011830 <cons>
    80000472:	00000097          	auipc	ra,0x0
    80000476:	70e080e7          	jalr	1806(ra) # 80000b80 <initlock>

  uartinit();
    8000047a:	00000097          	auipc	ra,0x0
    8000047e:	330080e7          	jalr	816(ra) # 800007aa <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000482:	00021797          	auipc	a5,0x21
    80000486:	52e78793          	addi	a5,a5,1326 # 800219b0 <devsw>
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	ce470713          	addi	a4,a4,-796 # 8000016e <consoleread>
    80000492:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000494:	00000717          	auipc	a4,0x0
    80000498:	c5870713          	addi	a4,a4,-936 # 800000ec <consolewrite>
    8000049c:	ef98                	sd	a4,24(a5)
}
    8000049e:	60a2                	ld	ra,8(sp)
    800004a0:	6402                	ld	s0,0(sp)
    800004a2:	0141                	addi	sp,sp,16
    800004a4:	8082                	ret

00000000800004a6 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004a6:	7179                	addi	sp,sp,-48
    800004a8:	f406                	sd	ra,40(sp)
    800004aa:	f022                	sd	s0,32(sp)
    800004ac:	ec26                	sd	s1,24(sp)
    800004ae:	e84a                	sd	s2,16(sp)
    800004b0:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004b2:	c219                	beqz	a2,800004b8 <printint+0x12>
    800004b4:	08054663          	bltz	a0,80000540 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004b8:	2501                	sext.w	a0,a0
    800004ba:	4881                	li	a7,0
    800004bc:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004c0:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004c2:	2581                	sext.w	a1,a1
    800004c4:	00008617          	auipc	a2,0x8
    800004c8:	b7c60613          	addi	a2,a2,-1156 # 80008040 <digits>
    800004cc:	883a                	mv	a6,a4
    800004ce:	2705                	addiw	a4,a4,1
    800004d0:	02b577bb          	remuw	a5,a0,a1
    800004d4:	1782                	slli	a5,a5,0x20
    800004d6:	9381                	srli	a5,a5,0x20
    800004d8:	97b2                	add	a5,a5,a2
    800004da:	0007c783          	lbu	a5,0(a5)
    800004de:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004e2:	0005079b          	sext.w	a5,a0
    800004e6:	02b5553b          	divuw	a0,a0,a1
    800004ea:	0685                	addi	a3,a3,1
    800004ec:	feb7f0e3          	bgeu	a5,a1,800004cc <printint+0x26>

  if(sign)
    800004f0:	00088b63          	beqz	a7,80000506 <printint+0x60>
    buf[i++] = '-';
    800004f4:	fe040793          	addi	a5,s0,-32
    800004f8:	973e                	add	a4,a4,a5
    800004fa:	02d00793          	li	a5,45
    800004fe:	fef70823          	sb	a5,-16(a4)
    80000502:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    80000506:	02e05763          	blez	a4,80000534 <printint+0x8e>
    8000050a:	fd040793          	addi	a5,s0,-48
    8000050e:	00e784b3          	add	s1,a5,a4
    80000512:	fff78913          	addi	s2,a5,-1
    80000516:	993a                	add	s2,s2,a4
    80000518:	377d                	addiw	a4,a4,-1
    8000051a:	1702                	slli	a4,a4,0x20
    8000051c:	9301                	srli	a4,a4,0x20
    8000051e:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000522:	fff4c503          	lbu	a0,-1(s1)
    80000526:	00000097          	auipc	ra,0x0
    8000052a:	d60080e7          	jalr	-672(ra) # 80000286 <consputc>
  while(--i >= 0)
    8000052e:	14fd                	addi	s1,s1,-1
    80000530:	ff2499e3          	bne	s1,s2,80000522 <printint+0x7c>
}
    80000534:	70a2                	ld	ra,40(sp)
    80000536:	7402                	ld	s0,32(sp)
    80000538:	64e2                	ld	s1,24(sp)
    8000053a:	6942                	ld	s2,16(sp)
    8000053c:	6145                	addi	sp,sp,48
    8000053e:	8082                	ret
    x = -xx;
    80000540:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000544:	4885                	li	a7,1
    x = -xx;
    80000546:	bf9d                	j	800004bc <printint+0x16>

0000000080000548 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000548:	1101                	addi	sp,sp,-32
    8000054a:	ec06                	sd	ra,24(sp)
    8000054c:	e822                	sd	s0,16(sp)
    8000054e:	e426                	sd	s1,8(sp)
    80000550:	1000                	addi	s0,sp,32
    80000552:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000554:	00011797          	auipc	a5,0x11
    80000558:	3807ae23          	sw	zero,924(a5) # 800118f0 <pr+0x18>
  printf("panic: ");
    8000055c:	00008517          	auipc	a0,0x8
    80000560:	abc50513          	addi	a0,a0,-1348 # 80008018 <etext+0x18>
    80000564:	00000097          	auipc	ra,0x0
    80000568:	02e080e7          	jalr	46(ra) # 80000592 <printf>
  printf(s);
    8000056c:	8526                	mv	a0,s1
    8000056e:	00000097          	auipc	ra,0x0
    80000572:	024080e7          	jalr	36(ra) # 80000592 <printf>
  printf("\n");
    80000576:	00008517          	auipc	a0,0x8
    8000057a:	b5250513          	addi	a0,a0,-1198 # 800080c8 <digits+0x88>
    8000057e:	00000097          	auipc	ra,0x0
    80000582:	014080e7          	jalr	20(ra) # 80000592 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000586:	4785                	li	a5,1
    80000588:	00009717          	auipc	a4,0x9
    8000058c:	a6f72c23          	sw	a5,-1416(a4) # 80009000 <panicked>
  for(;;)
    80000590:	a001                	j	80000590 <panic+0x48>

0000000080000592 <printf>:
{
    80000592:	7131                	addi	sp,sp,-192
    80000594:	fc86                	sd	ra,120(sp)
    80000596:	f8a2                	sd	s0,112(sp)
    80000598:	f4a6                	sd	s1,104(sp)
    8000059a:	f0ca                	sd	s2,96(sp)
    8000059c:	ecce                	sd	s3,88(sp)
    8000059e:	e8d2                	sd	s4,80(sp)
    800005a0:	e4d6                	sd	s5,72(sp)
    800005a2:	e0da                	sd	s6,64(sp)
    800005a4:	fc5e                	sd	s7,56(sp)
    800005a6:	f862                	sd	s8,48(sp)
    800005a8:	f466                	sd	s9,40(sp)
    800005aa:	f06a                	sd	s10,32(sp)
    800005ac:	ec6e                	sd	s11,24(sp)
    800005ae:	0100                	addi	s0,sp,128
    800005b0:	8a2a                	mv	s4,a0
    800005b2:	e40c                	sd	a1,8(s0)
    800005b4:	e810                	sd	a2,16(s0)
    800005b6:	ec14                	sd	a3,24(s0)
    800005b8:	f018                	sd	a4,32(s0)
    800005ba:	f41c                	sd	a5,40(s0)
    800005bc:	03043823          	sd	a6,48(s0)
    800005c0:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005c4:	00011d97          	auipc	s11,0x11
    800005c8:	32cdad83          	lw	s11,812(s11) # 800118f0 <pr+0x18>
  if(locking)
    800005cc:	020d9b63          	bnez	s11,80000602 <printf+0x70>
  if (fmt == 0)
    800005d0:	040a0263          	beqz	s4,80000614 <printf+0x82>
  va_start(ap, fmt);
    800005d4:	00840793          	addi	a5,s0,8
    800005d8:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005dc:	000a4503          	lbu	a0,0(s4)
    800005e0:	16050263          	beqz	a0,80000744 <printf+0x1b2>
    800005e4:	4481                	li	s1,0
    if(c != '%'){
    800005e6:	02500a93          	li	s5,37
    switch(c){
    800005ea:	07000b13          	li	s6,112
  consputc('x');
    800005ee:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005f0:	00008b97          	auipc	s7,0x8
    800005f4:	a50b8b93          	addi	s7,s7,-1456 # 80008040 <digits>
    switch(c){
    800005f8:	07300c93          	li	s9,115
    800005fc:	06400c13          	li	s8,100
    80000600:	a82d                	j	8000063a <printf+0xa8>
    acquire(&pr.lock);
    80000602:	00011517          	auipc	a0,0x11
    80000606:	2d650513          	addi	a0,a0,726 # 800118d8 <pr>
    8000060a:	00000097          	auipc	ra,0x0
    8000060e:	606080e7          	jalr	1542(ra) # 80000c10 <acquire>
    80000612:	bf7d                	j	800005d0 <printf+0x3e>
    panic("null fmt");
    80000614:	00008517          	auipc	a0,0x8
    80000618:	a1450513          	addi	a0,a0,-1516 # 80008028 <etext+0x28>
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	f2c080e7          	jalr	-212(ra) # 80000548 <panic>
      consputc(c);
    80000624:	00000097          	auipc	ra,0x0
    80000628:	c62080e7          	jalr	-926(ra) # 80000286 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000062c:	2485                	addiw	s1,s1,1
    8000062e:	009a07b3          	add	a5,s4,s1
    80000632:	0007c503          	lbu	a0,0(a5)
    80000636:	10050763          	beqz	a0,80000744 <printf+0x1b2>
    if(c != '%'){
    8000063a:	ff5515e3          	bne	a0,s5,80000624 <printf+0x92>
    c = fmt[++i] & 0xff;
    8000063e:	2485                	addiw	s1,s1,1
    80000640:	009a07b3          	add	a5,s4,s1
    80000644:	0007c783          	lbu	a5,0(a5)
    80000648:	0007891b          	sext.w	s2,a5
    if(c == 0)
    8000064c:	cfe5                	beqz	a5,80000744 <printf+0x1b2>
    switch(c){
    8000064e:	05678a63          	beq	a5,s6,800006a2 <printf+0x110>
    80000652:	02fb7663          	bgeu	s6,a5,8000067e <printf+0xec>
    80000656:	09978963          	beq	a5,s9,800006e8 <printf+0x156>
    8000065a:	07800713          	li	a4,120
    8000065e:	0ce79863          	bne	a5,a4,8000072e <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000662:	f8843783          	ld	a5,-120(s0)
    80000666:	00878713          	addi	a4,a5,8
    8000066a:	f8e43423          	sd	a4,-120(s0)
    8000066e:	4605                	li	a2,1
    80000670:	85ea                	mv	a1,s10
    80000672:	4388                	lw	a0,0(a5)
    80000674:	00000097          	auipc	ra,0x0
    80000678:	e32080e7          	jalr	-462(ra) # 800004a6 <printint>
      break;
    8000067c:	bf45                	j	8000062c <printf+0x9a>
    switch(c){
    8000067e:	0b578263          	beq	a5,s5,80000722 <printf+0x190>
    80000682:	0b879663          	bne	a5,s8,8000072e <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    80000686:	f8843783          	ld	a5,-120(s0)
    8000068a:	00878713          	addi	a4,a5,8
    8000068e:	f8e43423          	sd	a4,-120(s0)
    80000692:	4605                	li	a2,1
    80000694:	45a9                	li	a1,10
    80000696:	4388                	lw	a0,0(a5)
    80000698:	00000097          	auipc	ra,0x0
    8000069c:	e0e080e7          	jalr	-498(ra) # 800004a6 <printint>
      break;
    800006a0:	b771                	j	8000062c <printf+0x9a>
      printptr(va_arg(ap, uint64));
    800006a2:	f8843783          	ld	a5,-120(s0)
    800006a6:	00878713          	addi	a4,a5,8
    800006aa:	f8e43423          	sd	a4,-120(s0)
    800006ae:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006b2:	03000513          	li	a0,48
    800006b6:	00000097          	auipc	ra,0x0
    800006ba:	bd0080e7          	jalr	-1072(ra) # 80000286 <consputc>
  consputc('x');
    800006be:	07800513          	li	a0,120
    800006c2:	00000097          	auipc	ra,0x0
    800006c6:	bc4080e7          	jalr	-1084(ra) # 80000286 <consputc>
    800006ca:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006cc:	03c9d793          	srli	a5,s3,0x3c
    800006d0:	97de                	add	a5,a5,s7
    800006d2:	0007c503          	lbu	a0,0(a5)
    800006d6:	00000097          	auipc	ra,0x0
    800006da:	bb0080e7          	jalr	-1104(ra) # 80000286 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006de:	0992                	slli	s3,s3,0x4
    800006e0:	397d                	addiw	s2,s2,-1
    800006e2:	fe0915e3          	bnez	s2,800006cc <printf+0x13a>
    800006e6:	b799                	j	8000062c <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006e8:	f8843783          	ld	a5,-120(s0)
    800006ec:	00878713          	addi	a4,a5,8
    800006f0:	f8e43423          	sd	a4,-120(s0)
    800006f4:	0007b903          	ld	s2,0(a5)
    800006f8:	00090e63          	beqz	s2,80000714 <printf+0x182>
      for(; *s; s++)
    800006fc:	00094503          	lbu	a0,0(s2)
    80000700:	d515                	beqz	a0,8000062c <printf+0x9a>
        consputc(*s);
    80000702:	00000097          	auipc	ra,0x0
    80000706:	b84080e7          	jalr	-1148(ra) # 80000286 <consputc>
      for(; *s; s++)
    8000070a:	0905                	addi	s2,s2,1
    8000070c:	00094503          	lbu	a0,0(s2)
    80000710:	f96d                	bnez	a0,80000702 <printf+0x170>
    80000712:	bf29                	j	8000062c <printf+0x9a>
        s = "(null)";
    80000714:	00008917          	auipc	s2,0x8
    80000718:	90c90913          	addi	s2,s2,-1780 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000071c:	02800513          	li	a0,40
    80000720:	b7cd                	j	80000702 <printf+0x170>
      consputc('%');
    80000722:	8556                	mv	a0,s5
    80000724:	00000097          	auipc	ra,0x0
    80000728:	b62080e7          	jalr	-1182(ra) # 80000286 <consputc>
      break;
    8000072c:	b701                	j	8000062c <printf+0x9a>
      consputc('%');
    8000072e:	8556                	mv	a0,s5
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b56080e7          	jalr	-1194(ra) # 80000286 <consputc>
      consputc(c);
    80000738:	854a                	mv	a0,s2
    8000073a:	00000097          	auipc	ra,0x0
    8000073e:	b4c080e7          	jalr	-1204(ra) # 80000286 <consputc>
      break;
    80000742:	b5ed                	j	8000062c <printf+0x9a>
  if(locking)
    80000744:	020d9163          	bnez	s11,80000766 <printf+0x1d4>
}
    80000748:	70e6                	ld	ra,120(sp)
    8000074a:	7446                	ld	s0,112(sp)
    8000074c:	74a6                	ld	s1,104(sp)
    8000074e:	7906                	ld	s2,96(sp)
    80000750:	69e6                	ld	s3,88(sp)
    80000752:	6a46                	ld	s4,80(sp)
    80000754:	6aa6                	ld	s5,72(sp)
    80000756:	6b06                	ld	s6,64(sp)
    80000758:	7be2                	ld	s7,56(sp)
    8000075a:	7c42                	ld	s8,48(sp)
    8000075c:	7ca2                	ld	s9,40(sp)
    8000075e:	7d02                	ld	s10,32(sp)
    80000760:	6de2                	ld	s11,24(sp)
    80000762:	6129                	addi	sp,sp,192
    80000764:	8082                	ret
    release(&pr.lock);
    80000766:	00011517          	auipc	a0,0x11
    8000076a:	17250513          	addi	a0,a0,370 # 800118d8 <pr>
    8000076e:	00000097          	auipc	ra,0x0
    80000772:	556080e7          	jalr	1366(ra) # 80000cc4 <release>
}
    80000776:	bfc9                	j	80000748 <printf+0x1b6>

0000000080000778 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000778:	1101                	addi	sp,sp,-32
    8000077a:	ec06                	sd	ra,24(sp)
    8000077c:	e822                	sd	s0,16(sp)
    8000077e:	e426                	sd	s1,8(sp)
    80000780:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000782:	00011497          	auipc	s1,0x11
    80000786:	15648493          	addi	s1,s1,342 # 800118d8 <pr>
    8000078a:	00008597          	auipc	a1,0x8
    8000078e:	8ae58593          	addi	a1,a1,-1874 # 80008038 <etext+0x38>
    80000792:	8526                	mv	a0,s1
    80000794:	00000097          	auipc	ra,0x0
    80000798:	3ec080e7          	jalr	1004(ra) # 80000b80 <initlock>
  pr.locking = 1;
    8000079c:	4785                	li	a5,1
    8000079e:	cc9c                	sw	a5,24(s1)
}
    800007a0:	60e2                	ld	ra,24(sp)
    800007a2:	6442                	ld	s0,16(sp)
    800007a4:	64a2                	ld	s1,8(sp)
    800007a6:	6105                	addi	sp,sp,32
    800007a8:	8082                	ret

00000000800007aa <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007aa:	1141                	addi	sp,sp,-16
    800007ac:	e406                	sd	ra,8(sp)
    800007ae:	e022                	sd	s0,0(sp)
    800007b0:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007b2:	100007b7          	lui	a5,0x10000
    800007b6:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ba:	f8000713          	li	a4,-128
    800007be:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007c2:	470d                	li	a4,3
    800007c4:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007c8:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007cc:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007d0:	469d                	li	a3,7
    800007d2:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007d6:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007da:	00008597          	auipc	a1,0x8
    800007de:	87e58593          	addi	a1,a1,-1922 # 80008058 <digits+0x18>
    800007e2:	00011517          	auipc	a0,0x11
    800007e6:	11650513          	addi	a0,a0,278 # 800118f8 <uart_tx_lock>
    800007ea:	00000097          	auipc	ra,0x0
    800007ee:	396080e7          	jalr	918(ra) # 80000b80 <initlock>
}
    800007f2:	60a2                	ld	ra,8(sp)
    800007f4:	6402                	ld	s0,0(sp)
    800007f6:	0141                	addi	sp,sp,16
    800007f8:	8082                	ret

00000000800007fa <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007fa:	1101                	addi	sp,sp,-32
    800007fc:	ec06                	sd	ra,24(sp)
    800007fe:	e822                	sd	s0,16(sp)
    80000800:	e426                	sd	s1,8(sp)
    80000802:	1000                	addi	s0,sp,32
    80000804:	84aa                	mv	s1,a0
  push_off();
    80000806:	00000097          	auipc	ra,0x0
    8000080a:	3be080e7          	jalr	958(ra) # 80000bc4 <push_off>

  if(panicked){
    8000080e:	00008797          	auipc	a5,0x8
    80000812:	7f27a783          	lw	a5,2034(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000816:	10000737          	lui	a4,0x10000
  if(panicked){
    8000081a:	c391                	beqz	a5,8000081e <uartputc_sync+0x24>
    for(;;)
    8000081c:	a001                	j	8000081c <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000081e:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000822:	0ff7f793          	andi	a5,a5,255
    80000826:	0207f793          	andi	a5,a5,32
    8000082a:	dbf5                	beqz	a5,8000081e <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000082c:	0ff4f793          	andi	a5,s1,255
    80000830:	10000737          	lui	a4,0x10000
    80000834:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000838:	00000097          	auipc	ra,0x0
    8000083c:	42c080e7          	jalr	1068(ra) # 80000c64 <pop_off>
}
    80000840:	60e2                	ld	ra,24(sp)
    80000842:	6442                	ld	s0,16(sp)
    80000844:	64a2                	ld	s1,8(sp)
    80000846:	6105                	addi	sp,sp,32
    80000848:	8082                	ret

000000008000084a <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    8000084a:	00008797          	auipc	a5,0x8
    8000084e:	7ba7a783          	lw	a5,1978(a5) # 80009004 <uart_tx_r>
    80000852:	00008717          	auipc	a4,0x8
    80000856:	7b672703          	lw	a4,1974(a4) # 80009008 <uart_tx_w>
    8000085a:	08f70263          	beq	a4,a5,800008de <uartstart+0x94>
{
    8000085e:	7139                	addi	sp,sp,-64
    80000860:	fc06                	sd	ra,56(sp)
    80000862:	f822                	sd	s0,48(sp)
    80000864:	f426                	sd	s1,40(sp)
    80000866:	f04a                	sd	s2,32(sp)
    80000868:	ec4e                	sd	s3,24(sp)
    8000086a:	e852                	sd	s4,16(sp)
    8000086c:	e456                	sd	s5,8(sp)
    8000086e:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000870:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r];
    80000874:	00011a17          	auipc	s4,0x11
    80000878:	084a0a13          	addi	s4,s4,132 # 800118f8 <uart_tx_lock>
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    8000087c:	00008497          	auipc	s1,0x8
    80000880:	78848493          	addi	s1,s1,1928 # 80009004 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000884:	00008997          	auipc	s3,0x8
    80000888:	78498993          	addi	s3,s3,1924 # 80009008 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000088c:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000890:	0ff77713          	andi	a4,a4,255
    80000894:	02077713          	andi	a4,a4,32
    80000898:	cb15                	beqz	a4,800008cc <uartstart+0x82>
    int c = uart_tx_buf[uart_tx_r];
    8000089a:	00fa0733          	add	a4,s4,a5
    8000089e:	01874a83          	lbu	s5,24(a4)
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    800008a2:	2785                	addiw	a5,a5,1
    800008a4:	41f7d71b          	sraiw	a4,a5,0x1f
    800008a8:	01b7571b          	srliw	a4,a4,0x1b
    800008ac:	9fb9                	addw	a5,a5,a4
    800008ae:	8bfd                	andi	a5,a5,31
    800008b0:	9f99                	subw	a5,a5,a4
    800008b2:	c09c                	sw	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008b4:	8526                	mv	a0,s1
    800008b6:	00002097          	auipc	ra,0x2
    800008ba:	b9e080e7          	jalr	-1122(ra) # 80002454 <wakeup>
    
    WriteReg(THR, c);
    800008be:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008c2:	409c                	lw	a5,0(s1)
    800008c4:	0009a703          	lw	a4,0(s3)
    800008c8:	fcf712e3          	bne	a4,a5,8000088c <uartstart+0x42>
  }
}
    800008cc:	70e2                	ld	ra,56(sp)
    800008ce:	7442                	ld	s0,48(sp)
    800008d0:	74a2                	ld	s1,40(sp)
    800008d2:	7902                	ld	s2,32(sp)
    800008d4:	69e2                	ld	s3,24(sp)
    800008d6:	6a42                	ld	s4,16(sp)
    800008d8:	6aa2                	ld	s5,8(sp)
    800008da:	6121                	addi	sp,sp,64
    800008dc:	8082                	ret
    800008de:	8082                	ret

00000000800008e0 <uartputc>:
{
    800008e0:	7179                	addi	sp,sp,-48
    800008e2:	f406                	sd	ra,40(sp)
    800008e4:	f022                	sd	s0,32(sp)
    800008e6:	ec26                	sd	s1,24(sp)
    800008e8:	e84a                	sd	s2,16(sp)
    800008ea:	e44e                	sd	s3,8(sp)
    800008ec:	e052                	sd	s4,0(sp)
    800008ee:	1800                	addi	s0,sp,48
    800008f0:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008f2:	00011517          	auipc	a0,0x11
    800008f6:	00650513          	addi	a0,a0,6 # 800118f8 <uart_tx_lock>
    800008fa:	00000097          	auipc	ra,0x0
    800008fe:	316080e7          	jalr	790(ra) # 80000c10 <acquire>
  if(panicked){
    80000902:	00008797          	auipc	a5,0x8
    80000906:	6fe7a783          	lw	a5,1790(a5) # 80009000 <panicked>
    8000090a:	c391                	beqz	a5,8000090e <uartputc+0x2e>
    for(;;)
    8000090c:	a001                	j	8000090c <uartputc+0x2c>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    8000090e:	00008717          	auipc	a4,0x8
    80000912:	6fa72703          	lw	a4,1786(a4) # 80009008 <uart_tx_w>
    80000916:	0017079b          	addiw	a5,a4,1
    8000091a:	41f7d69b          	sraiw	a3,a5,0x1f
    8000091e:	01b6d69b          	srliw	a3,a3,0x1b
    80000922:	9fb5                	addw	a5,a5,a3
    80000924:	8bfd                	andi	a5,a5,31
    80000926:	9f95                	subw	a5,a5,a3
    80000928:	00008697          	auipc	a3,0x8
    8000092c:	6dc6a683          	lw	a3,1756(a3) # 80009004 <uart_tx_r>
    80000930:	04f69263          	bne	a3,a5,80000974 <uartputc+0x94>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000934:	00011a17          	auipc	s4,0x11
    80000938:	fc4a0a13          	addi	s4,s4,-60 # 800118f8 <uart_tx_lock>
    8000093c:	00008497          	auipc	s1,0x8
    80000940:	6c848493          	addi	s1,s1,1736 # 80009004 <uart_tx_r>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000944:	00008917          	auipc	s2,0x8
    80000948:	6c490913          	addi	s2,s2,1732 # 80009008 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    8000094c:	85d2                	mv	a1,s4
    8000094e:	8526                	mv	a0,s1
    80000950:	00002097          	auipc	ra,0x2
    80000954:	97e080e7          	jalr	-1666(ra) # 800022ce <sleep>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000958:	00092703          	lw	a4,0(s2)
    8000095c:	0017079b          	addiw	a5,a4,1
    80000960:	41f7d69b          	sraiw	a3,a5,0x1f
    80000964:	01b6d69b          	srliw	a3,a3,0x1b
    80000968:	9fb5                	addw	a5,a5,a3
    8000096a:	8bfd                	andi	a5,a5,31
    8000096c:	9f95                	subw	a5,a5,a3
    8000096e:	4094                	lw	a3,0(s1)
    80000970:	fcf68ee3          	beq	a3,a5,8000094c <uartputc+0x6c>
      uart_tx_buf[uart_tx_w] = c;
    80000974:	00011497          	auipc	s1,0x11
    80000978:	f8448493          	addi	s1,s1,-124 # 800118f8 <uart_tx_lock>
    8000097c:	9726                	add	a4,a4,s1
    8000097e:	01370c23          	sb	s3,24(a4)
      uart_tx_w = (uart_tx_w + 1) % UART_TX_BUF_SIZE;
    80000982:	00008717          	auipc	a4,0x8
    80000986:	68f72323          	sw	a5,1670(a4) # 80009008 <uart_tx_w>
      uartstart();
    8000098a:	00000097          	auipc	ra,0x0
    8000098e:	ec0080e7          	jalr	-320(ra) # 8000084a <uartstart>
      release(&uart_tx_lock);
    80000992:	8526                	mv	a0,s1
    80000994:	00000097          	auipc	ra,0x0
    80000998:	330080e7          	jalr	816(ra) # 80000cc4 <release>
}
    8000099c:	70a2                	ld	ra,40(sp)
    8000099e:	7402                	ld	s0,32(sp)
    800009a0:	64e2                	ld	s1,24(sp)
    800009a2:	6942                	ld	s2,16(sp)
    800009a4:	69a2                	ld	s3,8(sp)
    800009a6:	6a02                	ld	s4,0(sp)
    800009a8:	6145                	addi	sp,sp,48
    800009aa:	8082                	ret

00000000800009ac <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    800009ac:	1141                	addi	sp,sp,-16
    800009ae:	e422                	sd	s0,8(sp)
    800009b0:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    800009b2:	100007b7          	lui	a5,0x10000
    800009b6:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800009ba:	8b85                	andi	a5,a5,1
    800009bc:	cb91                	beqz	a5,800009d0 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    800009be:	100007b7          	lui	a5,0x10000
    800009c2:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009c6:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009ca:	6422                	ld	s0,8(sp)
    800009cc:	0141                	addi	sp,sp,16
    800009ce:	8082                	ret
    return -1;
    800009d0:	557d                	li	a0,-1
    800009d2:	bfe5                	j	800009ca <uartgetc+0x1e>

00000000800009d4 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009d4:	1101                	addi	sp,sp,-32
    800009d6:	ec06                	sd	ra,24(sp)
    800009d8:	e822                	sd	s0,16(sp)
    800009da:	e426                	sd	s1,8(sp)
    800009dc:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009de:	54fd                	li	s1,-1
    int c = uartgetc();
    800009e0:	00000097          	auipc	ra,0x0
    800009e4:	fcc080e7          	jalr	-52(ra) # 800009ac <uartgetc>
    if(c == -1)
    800009e8:	00950763          	beq	a0,s1,800009f6 <uartintr+0x22>
      break;
    consoleintr(c);
    800009ec:	00000097          	auipc	ra,0x0
    800009f0:	8dc080e7          	jalr	-1828(ra) # 800002c8 <consoleintr>
  while(1){
    800009f4:	b7f5                	j	800009e0 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009f6:	00011497          	auipc	s1,0x11
    800009fa:	f0248493          	addi	s1,s1,-254 # 800118f8 <uart_tx_lock>
    800009fe:	8526                	mv	a0,s1
    80000a00:	00000097          	auipc	ra,0x0
    80000a04:	210080e7          	jalr	528(ra) # 80000c10 <acquire>
  uartstart();
    80000a08:	00000097          	auipc	ra,0x0
    80000a0c:	e42080e7          	jalr	-446(ra) # 8000084a <uartstart>
  release(&uart_tx_lock);
    80000a10:	8526                	mv	a0,s1
    80000a12:	00000097          	auipc	ra,0x0
    80000a16:	2b2080e7          	jalr	690(ra) # 80000cc4 <release>
}
    80000a1a:	60e2                	ld	ra,24(sp)
    80000a1c:	6442                	ld	s0,16(sp)
    80000a1e:	64a2                	ld	s1,8(sp)
    80000a20:	6105                	addi	sp,sp,32
    80000a22:	8082                	ret

0000000080000a24 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a24:	1101                	addi	sp,sp,-32
    80000a26:	ec06                	sd	ra,24(sp)
    80000a28:	e822                	sd	s0,16(sp)
    80000a2a:	e426                	sd	s1,8(sp)
    80000a2c:	e04a                	sd	s2,0(sp)
    80000a2e:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a30:	03451793          	slli	a5,a0,0x34
    80000a34:	ebb9                	bnez	a5,80000a8a <kfree+0x66>
    80000a36:	84aa                	mv	s1,a0
    80000a38:	00025797          	auipc	a5,0x25
    80000a3c:	5c878793          	addi	a5,a5,1480 # 80026000 <end>
    80000a40:	04f56563          	bltu	a0,a5,80000a8a <kfree+0x66>
    80000a44:	47c5                	li	a5,17
    80000a46:	07ee                	slli	a5,a5,0x1b
    80000a48:	04f57163          	bgeu	a0,a5,80000a8a <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a4c:	6605                	lui	a2,0x1
    80000a4e:	4585                	li	a1,1
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	2bc080e7          	jalr	700(ra) # 80000d0c <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a58:	00011917          	auipc	s2,0x11
    80000a5c:	ed890913          	addi	s2,s2,-296 # 80011930 <kmem>
    80000a60:	854a                	mv	a0,s2
    80000a62:	00000097          	auipc	ra,0x0
    80000a66:	1ae080e7          	jalr	430(ra) # 80000c10 <acquire>
  r->next = kmem.freelist;
    80000a6a:	01893783          	ld	a5,24(s2)
    80000a6e:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a70:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a74:	854a                	mv	a0,s2
    80000a76:	00000097          	auipc	ra,0x0
    80000a7a:	24e080e7          	jalr	590(ra) # 80000cc4 <release>
}
    80000a7e:	60e2                	ld	ra,24(sp)
    80000a80:	6442                	ld	s0,16(sp)
    80000a82:	64a2                	ld	s1,8(sp)
    80000a84:	6902                	ld	s2,0(sp)
    80000a86:	6105                	addi	sp,sp,32
    80000a88:	8082                	ret
    panic("kfree");
    80000a8a:	00007517          	auipc	a0,0x7
    80000a8e:	5d650513          	addi	a0,a0,1494 # 80008060 <digits+0x20>
    80000a92:	00000097          	auipc	ra,0x0
    80000a96:	ab6080e7          	jalr	-1354(ra) # 80000548 <panic>

0000000080000a9a <freerange>:
{
    80000a9a:	7179                	addi	sp,sp,-48
    80000a9c:	f406                	sd	ra,40(sp)
    80000a9e:	f022                	sd	s0,32(sp)
    80000aa0:	ec26                	sd	s1,24(sp)
    80000aa2:	e84a                	sd	s2,16(sp)
    80000aa4:	e44e                	sd	s3,8(sp)
    80000aa6:	e052                	sd	s4,0(sp)
    80000aa8:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000aaa:	6785                	lui	a5,0x1
    80000aac:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000ab0:	94aa                	add	s1,s1,a0
    80000ab2:	757d                	lui	a0,0xfffff
    80000ab4:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ab6:	94be                	add	s1,s1,a5
    80000ab8:	0095ee63          	bltu	a1,s1,80000ad4 <freerange+0x3a>
    80000abc:	892e                	mv	s2,a1
    kfree(p);
    80000abe:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ac0:	6985                	lui	s3,0x1
    kfree(p);
    80000ac2:	01448533          	add	a0,s1,s4
    80000ac6:	00000097          	auipc	ra,0x0
    80000aca:	f5e080e7          	jalr	-162(ra) # 80000a24 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ace:	94ce                	add	s1,s1,s3
    80000ad0:	fe9979e3          	bgeu	s2,s1,80000ac2 <freerange+0x28>
}
    80000ad4:	70a2                	ld	ra,40(sp)
    80000ad6:	7402                	ld	s0,32(sp)
    80000ad8:	64e2                	ld	s1,24(sp)
    80000ada:	6942                	ld	s2,16(sp)
    80000adc:	69a2                	ld	s3,8(sp)
    80000ade:	6a02                	ld	s4,0(sp)
    80000ae0:	6145                	addi	sp,sp,48
    80000ae2:	8082                	ret

0000000080000ae4 <kinit>:
{
    80000ae4:	1141                	addi	sp,sp,-16
    80000ae6:	e406                	sd	ra,8(sp)
    80000ae8:	e022                	sd	s0,0(sp)
    80000aea:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000aec:	00007597          	auipc	a1,0x7
    80000af0:	57c58593          	addi	a1,a1,1404 # 80008068 <digits+0x28>
    80000af4:	00011517          	auipc	a0,0x11
    80000af8:	e3c50513          	addi	a0,a0,-452 # 80011930 <kmem>
    80000afc:	00000097          	auipc	ra,0x0
    80000b00:	084080e7          	jalr	132(ra) # 80000b80 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b04:	45c5                	li	a1,17
    80000b06:	05ee                	slli	a1,a1,0x1b
    80000b08:	00025517          	auipc	a0,0x25
    80000b0c:	4f850513          	addi	a0,a0,1272 # 80026000 <end>
    80000b10:	00000097          	auipc	ra,0x0
    80000b14:	f8a080e7          	jalr	-118(ra) # 80000a9a <freerange>
}
    80000b18:	60a2                	ld	ra,8(sp)
    80000b1a:	6402                	ld	s0,0(sp)
    80000b1c:	0141                	addi	sp,sp,16
    80000b1e:	8082                	ret

0000000080000b20 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b20:	1101                	addi	sp,sp,-32
    80000b22:	ec06                	sd	ra,24(sp)
    80000b24:	e822                	sd	s0,16(sp)
    80000b26:	e426                	sd	s1,8(sp)
    80000b28:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b2a:	00011497          	auipc	s1,0x11
    80000b2e:	e0648493          	addi	s1,s1,-506 # 80011930 <kmem>
    80000b32:	8526                	mv	a0,s1
    80000b34:	00000097          	auipc	ra,0x0
    80000b38:	0dc080e7          	jalr	220(ra) # 80000c10 <acquire>
  r = kmem.freelist;
    80000b3c:	6c84                	ld	s1,24(s1)
  if(r)
    80000b3e:	c885                	beqz	s1,80000b6e <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b40:	609c                	ld	a5,0(s1)
    80000b42:	00011517          	auipc	a0,0x11
    80000b46:	dee50513          	addi	a0,a0,-530 # 80011930 <kmem>
    80000b4a:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b4c:	00000097          	auipc	ra,0x0
    80000b50:	178080e7          	jalr	376(ra) # 80000cc4 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b54:	6605                	lui	a2,0x1
    80000b56:	4595                	li	a1,5
    80000b58:	8526                	mv	a0,s1
    80000b5a:	00000097          	auipc	ra,0x0
    80000b5e:	1b2080e7          	jalr	434(ra) # 80000d0c <memset>
  return (void*)r;
}
    80000b62:	8526                	mv	a0,s1
    80000b64:	60e2                	ld	ra,24(sp)
    80000b66:	6442                	ld	s0,16(sp)
    80000b68:	64a2                	ld	s1,8(sp)
    80000b6a:	6105                	addi	sp,sp,32
    80000b6c:	8082                	ret
  release(&kmem.lock);
    80000b6e:	00011517          	auipc	a0,0x11
    80000b72:	dc250513          	addi	a0,a0,-574 # 80011930 <kmem>
    80000b76:	00000097          	auipc	ra,0x0
    80000b7a:	14e080e7          	jalr	334(ra) # 80000cc4 <release>
  if(r)
    80000b7e:	b7d5                	j	80000b62 <kalloc+0x42>

0000000080000b80 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b80:	1141                	addi	sp,sp,-16
    80000b82:	e422                	sd	s0,8(sp)
    80000b84:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b86:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b88:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b8c:	00053823          	sd	zero,16(a0)
}
    80000b90:	6422                	ld	s0,8(sp)
    80000b92:	0141                	addi	sp,sp,16
    80000b94:	8082                	ret

0000000080000b96 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b96:	411c                	lw	a5,0(a0)
    80000b98:	e399                	bnez	a5,80000b9e <holding+0x8>
    80000b9a:	4501                	li	a0,0
  return r;
}
    80000b9c:	8082                	ret
{
    80000b9e:	1101                	addi	sp,sp,-32
    80000ba0:	ec06                	sd	ra,24(sp)
    80000ba2:	e822                	sd	s0,16(sp)
    80000ba4:	e426                	sd	s1,8(sp)
    80000ba6:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000ba8:	6904                	ld	s1,16(a0)
    80000baa:	00001097          	auipc	ra,0x1
    80000bae:	ef8080e7          	jalr	-264(ra) # 80001aa2 <mycpu>
    80000bb2:	40a48533          	sub	a0,s1,a0
    80000bb6:	00153513          	seqz	a0,a0
}
    80000bba:	60e2                	ld	ra,24(sp)
    80000bbc:	6442                	ld	s0,16(sp)
    80000bbe:	64a2                	ld	s1,8(sp)
    80000bc0:	6105                	addi	sp,sp,32
    80000bc2:	8082                	ret

0000000080000bc4 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000bc4:	1101                	addi	sp,sp,-32
    80000bc6:	ec06                	sd	ra,24(sp)
    80000bc8:	e822                	sd	s0,16(sp)
    80000bca:	e426                	sd	s1,8(sp)
    80000bcc:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000bce:	100024f3          	csrr	s1,sstatus
    80000bd2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000bd6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bd8:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bdc:	00001097          	auipc	ra,0x1
    80000be0:	ec6080e7          	jalr	-314(ra) # 80001aa2 <mycpu>
    80000be4:	5d3c                	lw	a5,120(a0)
    80000be6:	cf89                	beqz	a5,80000c00 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000be8:	00001097          	auipc	ra,0x1
    80000bec:	eba080e7          	jalr	-326(ra) # 80001aa2 <mycpu>
    80000bf0:	5d3c                	lw	a5,120(a0)
    80000bf2:	2785                	addiw	a5,a5,1
    80000bf4:	dd3c                	sw	a5,120(a0)
}
    80000bf6:	60e2                	ld	ra,24(sp)
    80000bf8:	6442                	ld	s0,16(sp)
    80000bfa:	64a2                	ld	s1,8(sp)
    80000bfc:	6105                	addi	sp,sp,32
    80000bfe:	8082                	ret
    mycpu()->intena = old;
    80000c00:	00001097          	auipc	ra,0x1
    80000c04:	ea2080e7          	jalr	-350(ra) # 80001aa2 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c08:	8085                	srli	s1,s1,0x1
    80000c0a:	8885                	andi	s1,s1,1
    80000c0c:	dd64                	sw	s1,124(a0)
    80000c0e:	bfe9                	j	80000be8 <push_off+0x24>

0000000080000c10 <acquire>:
{
    80000c10:	1101                	addi	sp,sp,-32
    80000c12:	ec06                	sd	ra,24(sp)
    80000c14:	e822                	sd	s0,16(sp)
    80000c16:	e426                	sd	s1,8(sp)
    80000c18:	1000                	addi	s0,sp,32
    80000c1a:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c1c:	00000097          	auipc	ra,0x0
    80000c20:	fa8080e7          	jalr	-88(ra) # 80000bc4 <push_off>
  if(holding(lk))
    80000c24:	8526                	mv	a0,s1
    80000c26:	00000097          	auipc	ra,0x0
    80000c2a:	f70080e7          	jalr	-144(ra) # 80000b96 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c2e:	4705                	li	a4,1
  if(holding(lk))
    80000c30:	e115                	bnez	a0,80000c54 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c32:	87ba                	mv	a5,a4
    80000c34:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c38:	2781                	sext.w	a5,a5
    80000c3a:	ffe5                	bnez	a5,80000c32 <acquire+0x22>
  __sync_synchronize();
    80000c3c:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	e62080e7          	jalr	-414(ra) # 80001aa2 <mycpu>
    80000c48:	e888                	sd	a0,16(s1)
}
    80000c4a:	60e2                	ld	ra,24(sp)
    80000c4c:	6442                	ld	s0,16(sp)
    80000c4e:	64a2                	ld	s1,8(sp)
    80000c50:	6105                	addi	sp,sp,32
    80000c52:	8082                	ret
    panic("acquire");
    80000c54:	00007517          	auipc	a0,0x7
    80000c58:	41c50513          	addi	a0,a0,1052 # 80008070 <digits+0x30>
    80000c5c:	00000097          	auipc	ra,0x0
    80000c60:	8ec080e7          	jalr	-1812(ra) # 80000548 <panic>

0000000080000c64 <pop_off>:

void
pop_off(void)
{
    80000c64:	1141                	addi	sp,sp,-16
    80000c66:	e406                	sd	ra,8(sp)
    80000c68:	e022                	sd	s0,0(sp)
    80000c6a:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c6c:	00001097          	auipc	ra,0x1
    80000c70:	e36080e7          	jalr	-458(ra) # 80001aa2 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c74:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c78:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c7a:	e78d                	bnez	a5,80000ca4 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c7c:	5d3c                	lw	a5,120(a0)
    80000c7e:	02f05b63          	blez	a5,80000cb4 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c82:	37fd                	addiw	a5,a5,-1
    80000c84:	0007871b          	sext.w	a4,a5
    80000c88:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c8a:	eb09                	bnez	a4,80000c9c <pop_off+0x38>
    80000c8c:	5d7c                	lw	a5,124(a0)
    80000c8e:	c799                	beqz	a5,80000c9c <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c90:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c94:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c98:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c9c:	60a2                	ld	ra,8(sp)
    80000c9e:	6402                	ld	s0,0(sp)
    80000ca0:	0141                	addi	sp,sp,16
    80000ca2:	8082                	ret
    panic("pop_off - interruptible");
    80000ca4:	00007517          	auipc	a0,0x7
    80000ca8:	3d450513          	addi	a0,a0,980 # 80008078 <digits+0x38>
    80000cac:	00000097          	auipc	ra,0x0
    80000cb0:	89c080e7          	jalr	-1892(ra) # 80000548 <panic>
    panic("pop_off");
    80000cb4:	00007517          	auipc	a0,0x7
    80000cb8:	3dc50513          	addi	a0,a0,988 # 80008090 <digits+0x50>
    80000cbc:	00000097          	auipc	ra,0x0
    80000cc0:	88c080e7          	jalr	-1908(ra) # 80000548 <panic>

0000000080000cc4 <release>:
{
    80000cc4:	1101                	addi	sp,sp,-32
    80000cc6:	ec06                	sd	ra,24(sp)
    80000cc8:	e822                	sd	s0,16(sp)
    80000cca:	e426                	sd	s1,8(sp)
    80000ccc:	1000                	addi	s0,sp,32
    80000cce:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000cd0:	00000097          	auipc	ra,0x0
    80000cd4:	ec6080e7          	jalr	-314(ra) # 80000b96 <holding>
    80000cd8:	c115                	beqz	a0,80000cfc <release+0x38>
  lk->cpu = 0;
    80000cda:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cde:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ce2:	0f50000f          	fence	iorw,ow
    80000ce6:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cea:	00000097          	auipc	ra,0x0
    80000cee:	f7a080e7          	jalr	-134(ra) # 80000c64 <pop_off>
}
    80000cf2:	60e2                	ld	ra,24(sp)
    80000cf4:	6442                	ld	s0,16(sp)
    80000cf6:	64a2                	ld	s1,8(sp)
    80000cf8:	6105                	addi	sp,sp,32
    80000cfa:	8082                	ret
    panic("release");
    80000cfc:	00007517          	auipc	a0,0x7
    80000d00:	39c50513          	addi	a0,a0,924 # 80008098 <digits+0x58>
    80000d04:	00000097          	auipc	ra,0x0
    80000d08:	844080e7          	jalr	-1980(ra) # 80000548 <panic>

0000000080000d0c <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d0c:	1141                	addi	sp,sp,-16
    80000d0e:	e422                	sd	s0,8(sp)
    80000d10:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d12:	ce09                	beqz	a2,80000d2c <memset+0x20>
    80000d14:	87aa                	mv	a5,a0
    80000d16:	fff6071b          	addiw	a4,a2,-1
    80000d1a:	1702                	slli	a4,a4,0x20
    80000d1c:	9301                	srli	a4,a4,0x20
    80000d1e:	0705                	addi	a4,a4,1
    80000d20:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000d22:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d26:	0785                	addi	a5,a5,1
    80000d28:	fee79de3          	bne	a5,a4,80000d22 <memset+0x16>
  }
  return dst;
}
    80000d2c:	6422                	ld	s0,8(sp)
    80000d2e:	0141                	addi	sp,sp,16
    80000d30:	8082                	ret

0000000080000d32 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d32:	1141                	addi	sp,sp,-16
    80000d34:	e422                	sd	s0,8(sp)
    80000d36:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d38:	ca05                	beqz	a2,80000d68 <memcmp+0x36>
    80000d3a:	fff6069b          	addiw	a3,a2,-1
    80000d3e:	1682                	slli	a3,a3,0x20
    80000d40:	9281                	srli	a3,a3,0x20
    80000d42:	0685                	addi	a3,a3,1
    80000d44:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d46:	00054783          	lbu	a5,0(a0)
    80000d4a:	0005c703          	lbu	a4,0(a1)
    80000d4e:	00e79863          	bne	a5,a4,80000d5e <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d52:	0505                	addi	a0,a0,1
    80000d54:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d56:	fed518e3          	bne	a0,a3,80000d46 <memcmp+0x14>
  }

  return 0;
    80000d5a:	4501                	li	a0,0
    80000d5c:	a019                	j	80000d62 <memcmp+0x30>
      return *s1 - *s2;
    80000d5e:	40e7853b          	subw	a0,a5,a4
}
    80000d62:	6422                	ld	s0,8(sp)
    80000d64:	0141                	addi	sp,sp,16
    80000d66:	8082                	ret
  return 0;
    80000d68:	4501                	li	a0,0
    80000d6a:	bfe5                	j	80000d62 <memcmp+0x30>

0000000080000d6c <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d6c:	1141                	addi	sp,sp,-16
    80000d6e:	e422                	sd	s0,8(sp)
    80000d70:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d72:	00a5f963          	bgeu	a1,a0,80000d84 <memmove+0x18>
    80000d76:	02061713          	slli	a4,a2,0x20
    80000d7a:	9301                	srli	a4,a4,0x20
    80000d7c:	00e587b3          	add	a5,a1,a4
    80000d80:	02f56563          	bltu	a0,a5,80000daa <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d84:	fff6069b          	addiw	a3,a2,-1
    80000d88:	ce11                	beqz	a2,80000da4 <memmove+0x38>
    80000d8a:	1682                	slli	a3,a3,0x20
    80000d8c:	9281                	srli	a3,a3,0x20
    80000d8e:	0685                	addi	a3,a3,1
    80000d90:	96ae                	add	a3,a3,a1
    80000d92:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000d94:	0585                	addi	a1,a1,1
    80000d96:	0785                	addi	a5,a5,1
    80000d98:	fff5c703          	lbu	a4,-1(a1)
    80000d9c:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000da0:	fed59ae3          	bne	a1,a3,80000d94 <memmove+0x28>

  return dst;
}
    80000da4:	6422                	ld	s0,8(sp)
    80000da6:	0141                	addi	sp,sp,16
    80000da8:	8082                	ret
    d += n;
    80000daa:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000dac:	fff6069b          	addiw	a3,a2,-1
    80000db0:	da75                	beqz	a2,80000da4 <memmove+0x38>
    80000db2:	02069613          	slli	a2,a3,0x20
    80000db6:	9201                	srli	a2,a2,0x20
    80000db8:	fff64613          	not	a2,a2
    80000dbc:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000dbe:	17fd                	addi	a5,a5,-1
    80000dc0:	177d                	addi	a4,a4,-1
    80000dc2:	0007c683          	lbu	a3,0(a5)
    80000dc6:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000dca:	fec79ae3          	bne	a5,a2,80000dbe <memmove+0x52>
    80000dce:	bfd9                	j	80000da4 <memmove+0x38>

0000000080000dd0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000dd0:	1141                	addi	sp,sp,-16
    80000dd2:	e406                	sd	ra,8(sp)
    80000dd4:	e022                	sd	s0,0(sp)
    80000dd6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000dd8:	00000097          	auipc	ra,0x0
    80000ddc:	f94080e7          	jalr	-108(ra) # 80000d6c <memmove>
}
    80000de0:	60a2                	ld	ra,8(sp)
    80000de2:	6402                	ld	s0,0(sp)
    80000de4:	0141                	addi	sp,sp,16
    80000de6:	8082                	ret

0000000080000de8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000de8:	1141                	addi	sp,sp,-16
    80000dea:	e422                	sd	s0,8(sp)
    80000dec:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dee:	ce11                	beqz	a2,80000e0a <strncmp+0x22>
    80000df0:	00054783          	lbu	a5,0(a0)
    80000df4:	cf89                	beqz	a5,80000e0e <strncmp+0x26>
    80000df6:	0005c703          	lbu	a4,0(a1)
    80000dfa:	00f71a63          	bne	a4,a5,80000e0e <strncmp+0x26>
    n--, p++, q++;
    80000dfe:	367d                	addiw	a2,a2,-1
    80000e00:	0505                	addi	a0,a0,1
    80000e02:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e04:	f675                	bnez	a2,80000df0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e06:	4501                	li	a0,0
    80000e08:	a809                	j	80000e1a <strncmp+0x32>
    80000e0a:	4501                	li	a0,0
    80000e0c:	a039                	j	80000e1a <strncmp+0x32>
  if(n == 0)
    80000e0e:	ca09                	beqz	a2,80000e20 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e10:	00054503          	lbu	a0,0(a0)
    80000e14:	0005c783          	lbu	a5,0(a1)
    80000e18:	9d1d                	subw	a0,a0,a5
}
    80000e1a:	6422                	ld	s0,8(sp)
    80000e1c:	0141                	addi	sp,sp,16
    80000e1e:	8082                	ret
    return 0;
    80000e20:	4501                	li	a0,0
    80000e22:	bfe5                	j	80000e1a <strncmp+0x32>

0000000080000e24 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e24:	1141                	addi	sp,sp,-16
    80000e26:	e422                	sd	s0,8(sp)
    80000e28:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e2a:	872a                	mv	a4,a0
    80000e2c:	8832                	mv	a6,a2
    80000e2e:	367d                	addiw	a2,a2,-1
    80000e30:	01005963          	blez	a6,80000e42 <strncpy+0x1e>
    80000e34:	0705                	addi	a4,a4,1
    80000e36:	0005c783          	lbu	a5,0(a1)
    80000e3a:	fef70fa3          	sb	a5,-1(a4)
    80000e3e:	0585                	addi	a1,a1,1
    80000e40:	f7f5                	bnez	a5,80000e2c <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e42:	00c05d63          	blez	a2,80000e5c <strncpy+0x38>
    80000e46:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e48:	0685                	addi	a3,a3,1
    80000e4a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e4e:	fff6c793          	not	a5,a3
    80000e52:	9fb9                	addw	a5,a5,a4
    80000e54:	010787bb          	addw	a5,a5,a6
    80000e58:	fef048e3          	bgtz	a5,80000e48 <strncpy+0x24>
  return os;
}
    80000e5c:	6422                	ld	s0,8(sp)
    80000e5e:	0141                	addi	sp,sp,16
    80000e60:	8082                	ret

0000000080000e62 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e62:	1141                	addi	sp,sp,-16
    80000e64:	e422                	sd	s0,8(sp)
    80000e66:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e68:	02c05363          	blez	a2,80000e8e <safestrcpy+0x2c>
    80000e6c:	fff6069b          	addiw	a3,a2,-1
    80000e70:	1682                	slli	a3,a3,0x20
    80000e72:	9281                	srli	a3,a3,0x20
    80000e74:	96ae                	add	a3,a3,a1
    80000e76:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e78:	00d58963          	beq	a1,a3,80000e8a <safestrcpy+0x28>
    80000e7c:	0585                	addi	a1,a1,1
    80000e7e:	0785                	addi	a5,a5,1
    80000e80:	fff5c703          	lbu	a4,-1(a1)
    80000e84:	fee78fa3          	sb	a4,-1(a5)
    80000e88:	fb65                	bnez	a4,80000e78 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e8a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e8e:	6422                	ld	s0,8(sp)
    80000e90:	0141                	addi	sp,sp,16
    80000e92:	8082                	ret

0000000080000e94 <strlen>:

int
strlen(const char *s)
{
    80000e94:	1141                	addi	sp,sp,-16
    80000e96:	e422                	sd	s0,8(sp)
    80000e98:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e9a:	00054783          	lbu	a5,0(a0)
    80000e9e:	cf91                	beqz	a5,80000eba <strlen+0x26>
    80000ea0:	0505                	addi	a0,a0,1
    80000ea2:	87aa                	mv	a5,a0
    80000ea4:	4685                	li	a3,1
    80000ea6:	9e89                	subw	a3,a3,a0
    80000ea8:	00f6853b          	addw	a0,a3,a5
    80000eac:	0785                	addi	a5,a5,1
    80000eae:	fff7c703          	lbu	a4,-1(a5)
    80000eb2:	fb7d                	bnez	a4,80000ea8 <strlen+0x14>
    ;
  return n;
}
    80000eb4:	6422                	ld	s0,8(sp)
    80000eb6:	0141                	addi	sp,sp,16
    80000eb8:	8082                	ret
  for(n = 0; s[n]; n++)
    80000eba:	4501                	li	a0,0
    80000ebc:	bfe5                	j	80000eb4 <strlen+0x20>

0000000080000ebe <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000ebe:	1141                	addi	sp,sp,-16
    80000ec0:	e406                	sd	ra,8(sp)
    80000ec2:	e022                	sd	s0,0(sp)
    80000ec4:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000ec6:	00001097          	auipc	ra,0x1
    80000eca:	bcc080e7          	jalr	-1076(ra) # 80001a92 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ece:	00008717          	auipc	a4,0x8
    80000ed2:	13e70713          	addi	a4,a4,318 # 8000900c <started>
  if(cpuid() == 0){
    80000ed6:	c139                	beqz	a0,80000f1c <main+0x5e>
    while(started == 0)
    80000ed8:	431c                	lw	a5,0(a4)
    80000eda:	2781                	sext.w	a5,a5
    80000edc:	dff5                	beqz	a5,80000ed8 <main+0x1a>
      ;
    __sync_synchronize();
    80000ede:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000ee2:	00001097          	auipc	ra,0x1
    80000ee6:	bb0080e7          	jalr	-1104(ra) # 80001a92 <cpuid>
    80000eea:	85aa                	mv	a1,a0
    80000eec:	00007517          	auipc	a0,0x7
    80000ef0:	1cc50513          	addi	a0,a0,460 # 800080b8 <digits+0x78>
    80000ef4:	fffff097          	auipc	ra,0xfffff
    80000ef8:	69e080e7          	jalr	1694(ra) # 80000592 <printf>
    kvminithart();    // turn on paging
    80000efc:	00000097          	auipc	ra,0x0
    80000f00:	0d8080e7          	jalr	216(ra) # 80000fd4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f04:	00002097          	auipc	ra,0x2
    80000f08:	818080e7          	jalr	-2024(ra) # 8000271c <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f0c:	00005097          	auipc	ra,0x5
    80000f10:	e14080e7          	jalr	-492(ra) # 80005d20 <plicinithart>
  }

  scheduler();        
    80000f14:	00001097          	auipc	ra,0x1
    80000f18:	0da080e7          	jalr	218(ra) # 80001fee <scheduler>
    consoleinit();
    80000f1c:	fffff097          	auipc	ra,0xfffff
    80000f20:	53e080e7          	jalr	1342(ra) # 8000045a <consoleinit>
    printfinit();
    80000f24:	00000097          	auipc	ra,0x0
    80000f28:	854080e7          	jalr	-1964(ra) # 80000778 <printfinit>
    printf("\n");
    80000f2c:	00007517          	auipc	a0,0x7
    80000f30:	19c50513          	addi	a0,a0,412 # 800080c8 <digits+0x88>
    80000f34:	fffff097          	auipc	ra,0xfffff
    80000f38:	65e080e7          	jalr	1630(ra) # 80000592 <printf>
    printf("xv6 kernel is booting\n");
    80000f3c:	00007517          	auipc	a0,0x7
    80000f40:	16450513          	addi	a0,a0,356 # 800080a0 <digits+0x60>
    80000f44:	fffff097          	auipc	ra,0xfffff
    80000f48:	64e080e7          	jalr	1614(ra) # 80000592 <printf>
    printf("\n");
    80000f4c:	00007517          	auipc	a0,0x7
    80000f50:	17c50513          	addi	a0,a0,380 # 800080c8 <digits+0x88>
    80000f54:	fffff097          	auipc	ra,0xfffff
    80000f58:	63e080e7          	jalr	1598(ra) # 80000592 <printf>
    kinit();         // physical page allocator
    80000f5c:	00000097          	auipc	ra,0x0
    80000f60:	b88080e7          	jalr	-1144(ra) # 80000ae4 <kinit>
    kvminit();       // create kernel page table
    80000f64:	00000097          	auipc	ra,0x0
    80000f68:	2a0080e7          	jalr	672(ra) # 80001204 <kvminit>
    kvminithart();   // turn on paging
    80000f6c:	00000097          	auipc	ra,0x0
    80000f70:	068080e7          	jalr	104(ra) # 80000fd4 <kvminithart>
    procinit();      // process table
    80000f74:	00001097          	auipc	ra,0x1
    80000f78:	a4e080e7          	jalr	-1458(ra) # 800019c2 <procinit>
    trapinit();      // trap vectors
    80000f7c:	00001097          	auipc	ra,0x1
    80000f80:	778080e7          	jalr	1912(ra) # 800026f4 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f84:	00001097          	auipc	ra,0x1
    80000f88:	798080e7          	jalr	1944(ra) # 8000271c <trapinithart>
    plicinit();      // set up interrupt controller
    80000f8c:	00005097          	auipc	ra,0x5
    80000f90:	d7e080e7          	jalr	-642(ra) # 80005d0a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f94:	00005097          	auipc	ra,0x5
    80000f98:	d8c080e7          	jalr	-628(ra) # 80005d20 <plicinithart>
    binit();         // buffer cache
    80000f9c:	00002097          	auipc	ra,0x2
    80000fa0:	f22080e7          	jalr	-222(ra) # 80002ebe <binit>
    iinit();         // inode cache
    80000fa4:	00002097          	auipc	ra,0x2
    80000fa8:	5b2080e7          	jalr	1458(ra) # 80003556 <iinit>
    fileinit();      // file table
    80000fac:	00003097          	auipc	ra,0x3
    80000fb0:	550080e7          	jalr	1360(ra) # 800044fc <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fb4:	00005097          	auipc	ra,0x5
    80000fb8:	e74080e7          	jalr	-396(ra) # 80005e28 <virtio_disk_init>
    userinit();      // first user process
    80000fbc:	00001097          	auipc	ra,0x1
    80000fc0:	dcc080e7          	jalr	-564(ra) # 80001d88 <userinit>
    __sync_synchronize();
    80000fc4:	0ff0000f          	fence
    started = 1;
    80000fc8:	4785                	li	a5,1
    80000fca:	00008717          	auipc	a4,0x8
    80000fce:	04f72123          	sw	a5,66(a4) # 8000900c <started>
    80000fd2:	b789                	j	80000f14 <main+0x56>

0000000080000fd4 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fd4:	1141                	addi	sp,sp,-16
    80000fd6:	e422                	sd	s0,8(sp)
    80000fd8:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fda:	00008797          	auipc	a5,0x8
    80000fde:	0367b783          	ld	a5,54(a5) # 80009010 <kernel_pagetable>
    80000fe2:	83b1                	srli	a5,a5,0xc
    80000fe4:	577d                	li	a4,-1
    80000fe6:	177e                	slli	a4,a4,0x3f
    80000fe8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fea:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fee:	12000073          	sfence.vma
  sfence_vma();
}
    80000ff2:	6422                	ld	s0,8(sp)
    80000ff4:	0141                	addi	sp,sp,16
    80000ff6:	8082                	ret

0000000080000ff8 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000ff8:	7139                	addi	sp,sp,-64
    80000ffa:	fc06                	sd	ra,56(sp)
    80000ffc:	f822                	sd	s0,48(sp)
    80000ffe:	f426                	sd	s1,40(sp)
    80001000:	f04a                	sd	s2,32(sp)
    80001002:	ec4e                	sd	s3,24(sp)
    80001004:	e852                	sd	s4,16(sp)
    80001006:	e456                	sd	s5,8(sp)
    80001008:	e05a                	sd	s6,0(sp)
    8000100a:	0080                	addi	s0,sp,64
    8000100c:	84aa                	mv	s1,a0
    8000100e:	89ae                	mv	s3,a1
    80001010:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001012:	57fd                	li	a5,-1
    80001014:	83e9                	srli	a5,a5,0x1a
    80001016:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001018:	4b31                	li	s6,12
  if(va >= MAXVA)
    8000101a:	04b7f263          	bgeu	a5,a1,8000105e <walk+0x66>
    panic("walk");
    8000101e:	00007517          	auipc	a0,0x7
    80001022:	0b250513          	addi	a0,a0,178 # 800080d0 <digits+0x90>
    80001026:	fffff097          	auipc	ra,0xfffff
    8000102a:	522080e7          	jalr	1314(ra) # 80000548 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    8000102e:	060a8663          	beqz	s5,8000109a <walk+0xa2>
    80001032:	00000097          	auipc	ra,0x0
    80001036:	aee080e7          	jalr	-1298(ra) # 80000b20 <kalloc>
    8000103a:	84aa                	mv	s1,a0
    8000103c:	c529                	beqz	a0,80001086 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000103e:	6605                	lui	a2,0x1
    80001040:	4581                	li	a1,0
    80001042:	00000097          	auipc	ra,0x0
    80001046:	cca080e7          	jalr	-822(ra) # 80000d0c <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000104a:	00c4d793          	srli	a5,s1,0xc
    8000104e:	07aa                	slli	a5,a5,0xa
    80001050:	0017e793          	ori	a5,a5,1
    80001054:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001058:	3a5d                	addiw	s4,s4,-9
    8000105a:	036a0063          	beq	s4,s6,8000107a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000105e:	0149d933          	srl	s2,s3,s4
    80001062:	1ff97913          	andi	s2,s2,511
    80001066:	090e                	slli	s2,s2,0x3
    80001068:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000106a:	00093483          	ld	s1,0(s2)
    8000106e:	0014f793          	andi	a5,s1,1
    80001072:	dfd5                	beqz	a5,8000102e <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001074:	80a9                	srli	s1,s1,0xa
    80001076:	04b2                	slli	s1,s1,0xc
    80001078:	b7c5                	j	80001058 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000107a:	00c9d513          	srli	a0,s3,0xc
    8000107e:	1ff57513          	andi	a0,a0,511
    80001082:	050e                	slli	a0,a0,0x3
    80001084:	9526                	add	a0,a0,s1
}
    80001086:	70e2                	ld	ra,56(sp)
    80001088:	7442                	ld	s0,48(sp)
    8000108a:	74a2                	ld	s1,40(sp)
    8000108c:	7902                	ld	s2,32(sp)
    8000108e:	69e2                	ld	s3,24(sp)
    80001090:	6a42                	ld	s4,16(sp)
    80001092:	6aa2                	ld	s5,8(sp)
    80001094:	6b02                	ld	s6,0(sp)
    80001096:	6121                	addi	sp,sp,64
    80001098:	8082                	ret
        return 0;
    8000109a:	4501                	li	a0,0
    8000109c:	b7ed                	j	80001086 <walk+0x8e>

000000008000109e <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000109e:	57fd                	li	a5,-1
    800010a0:	83e9                	srli	a5,a5,0x1a
    800010a2:	00b7f463          	bgeu	a5,a1,800010aa <walkaddr+0xc>
    return 0;
    800010a6:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800010a8:	8082                	ret
{
    800010aa:	1141                	addi	sp,sp,-16
    800010ac:	e406                	sd	ra,8(sp)
    800010ae:	e022                	sd	s0,0(sp)
    800010b0:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010b2:	4601                	li	a2,0
    800010b4:	00000097          	auipc	ra,0x0
    800010b8:	f44080e7          	jalr	-188(ra) # 80000ff8 <walk>
  if(pte == 0)
    800010bc:	c105                	beqz	a0,800010dc <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800010be:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010c0:	0117f693          	andi	a3,a5,17
    800010c4:	4745                	li	a4,17
    return 0;
    800010c6:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010c8:	00e68663          	beq	a3,a4,800010d4 <walkaddr+0x36>
}
    800010cc:	60a2                	ld	ra,8(sp)
    800010ce:	6402                	ld	s0,0(sp)
    800010d0:	0141                	addi	sp,sp,16
    800010d2:	8082                	ret
  pa = PTE2PA(*pte);
    800010d4:	00a7d513          	srli	a0,a5,0xa
    800010d8:	0532                	slli	a0,a0,0xc
  return pa;
    800010da:	bfcd                	j	800010cc <walkaddr+0x2e>
    return 0;
    800010dc:	4501                	li	a0,0
    800010de:	b7fd                	j	800010cc <walkaddr+0x2e>

00000000800010e0 <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    800010e0:	1101                	addi	sp,sp,-32
    800010e2:	ec06                	sd	ra,24(sp)
    800010e4:	e822                	sd	s0,16(sp)
    800010e6:	e426                	sd	s1,8(sp)
    800010e8:	1000                	addi	s0,sp,32
    800010ea:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    800010ec:	1552                	slli	a0,a0,0x34
    800010ee:	03455493          	srli	s1,a0,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(kernel_pagetable, va, 0);
    800010f2:	4601                	li	a2,0
    800010f4:	00008517          	auipc	a0,0x8
    800010f8:	f1c53503          	ld	a0,-228(a0) # 80009010 <kernel_pagetable>
    800010fc:	00000097          	auipc	ra,0x0
    80001100:	efc080e7          	jalr	-260(ra) # 80000ff8 <walk>
  if(pte == 0)
    80001104:	cd09                	beqz	a0,8000111e <kvmpa+0x3e>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    80001106:	6108                	ld	a0,0(a0)
    80001108:	00157793          	andi	a5,a0,1
    8000110c:	c38d                	beqz	a5,8000112e <kvmpa+0x4e>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    8000110e:	8129                	srli	a0,a0,0xa
    80001110:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    80001112:	9526                	add	a0,a0,s1
    80001114:	60e2                	ld	ra,24(sp)
    80001116:	6442                	ld	s0,16(sp)
    80001118:	64a2                	ld	s1,8(sp)
    8000111a:	6105                	addi	sp,sp,32
    8000111c:	8082                	ret
    panic("kvmpa");
    8000111e:	00007517          	auipc	a0,0x7
    80001122:	fba50513          	addi	a0,a0,-70 # 800080d8 <digits+0x98>
    80001126:	fffff097          	auipc	ra,0xfffff
    8000112a:	422080e7          	jalr	1058(ra) # 80000548 <panic>
    panic("kvmpa");
    8000112e:	00007517          	auipc	a0,0x7
    80001132:	faa50513          	addi	a0,a0,-86 # 800080d8 <digits+0x98>
    80001136:	fffff097          	auipc	ra,0xfffff
    8000113a:	412080e7          	jalr	1042(ra) # 80000548 <panic>

000000008000113e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000113e:	715d                	addi	sp,sp,-80
    80001140:	e486                	sd	ra,72(sp)
    80001142:	e0a2                	sd	s0,64(sp)
    80001144:	fc26                	sd	s1,56(sp)
    80001146:	f84a                	sd	s2,48(sp)
    80001148:	f44e                	sd	s3,40(sp)
    8000114a:	f052                	sd	s4,32(sp)
    8000114c:	ec56                	sd	s5,24(sp)
    8000114e:	e85a                	sd	s6,16(sp)
    80001150:	e45e                	sd	s7,8(sp)
    80001152:	0880                	addi	s0,sp,80
    80001154:	8aaa                	mv	s5,a0
    80001156:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    80001158:	777d                	lui	a4,0xfffff
    8000115a:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    8000115e:	167d                	addi	a2,a2,-1
    80001160:	00b609b3          	add	s3,a2,a1
    80001164:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001168:	893e                	mv	s2,a5
    8000116a:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    8000116e:	6b85                	lui	s7,0x1
    80001170:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001174:	4605                	li	a2,1
    80001176:	85ca                	mv	a1,s2
    80001178:	8556                	mv	a0,s5
    8000117a:	00000097          	auipc	ra,0x0
    8000117e:	e7e080e7          	jalr	-386(ra) # 80000ff8 <walk>
    80001182:	c51d                	beqz	a0,800011b0 <mappages+0x72>
    if(*pte & PTE_V)
    80001184:	611c                	ld	a5,0(a0)
    80001186:	8b85                	andi	a5,a5,1
    80001188:	ef81                	bnez	a5,800011a0 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000118a:	80b1                	srli	s1,s1,0xc
    8000118c:	04aa                	slli	s1,s1,0xa
    8000118e:	0164e4b3          	or	s1,s1,s6
    80001192:	0014e493          	ori	s1,s1,1
    80001196:	e104                	sd	s1,0(a0)
    if(a == last)
    80001198:	03390863          	beq	s2,s3,800011c8 <mappages+0x8a>
    a += PGSIZE;
    8000119c:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    8000119e:	bfc9                	j	80001170 <mappages+0x32>
      panic("remap");
    800011a0:	00007517          	auipc	a0,0x7
    800011a4:	f4050513          	addi	a0,a0,-192 # 800080e0 <digits+0xa0>
    800011a8:	fffff097          	auipc	ra,0xfffff
    800011ac:	3a0080e7          	jalr	928(ra) # 80000548 <panic>
      return -1;
    800011b0:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800011b2:	60a6                	ld	ra,72(sp)
    800011b4:	6406                	ld	s0,64(sp)
    800011b6:	74e2                	ld	s1,56(sp)
    800011b8:	7942                	ld	s2,48(sp)
    800011ba:	79a2                	ld	s3,40(sp)
    800011bc:	7a02                	ld	s4,32(sp)
    800011be:	6ae2                	ld	s5,24(sp)
    800011c0:	6b42                	ld	s6,16(sp)
    800011c2:	6ba2                	ld	s7,8(sp)
    800011c4:	6161                	addi	sp,sp,80
    800011c6:	8082                	ret
  return 0;
    800011c8:	4501                	li	a0,0
    800011ca:	b7e5                	j	800011b2 <mappages+0x74>

00000000800011cc <kvmmap>:
{
    800011cc:	1141                	addi	sp,sp,-16
    800011ce:	e406                	sd	ra,8(sp)
    800011d0:	e022                	sd	s0,0(sp)
    800011d2:	0800                	addi	s0,sp,16
    800011d4:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    800011d6:	86ae                	mv	a3,a1
    800011d8:	85aa                	mv	a1,a0
    800011da:	00008517          	auipc	a0,0x8
    800011de:	e3653503          	ld	a0,-458(a0) # 80009010 <kernel_pagetable>
    800011e2:	00000097          	auipc	ra,0x0
    800011e6:	f5c080e7          	jalr	-164(ra) # 8000113e <mappages>
    800011ea:	e509                	bnez	a0,800011f4 <kvmmap+0x28>
}
    800011ec:	60a2                	ld	ra,8(sp)
    800011ee:	6402                	ld	s0,0(sp)
    800011f0:	0141                	addi	sp,sp,16
    800011f2:	8082                	ret
    panic("kvmmap");
    800011f4:	00007517          	auipc	a0,0x7
    800011f8:	ef450513          	addi	a0,a0,-268 # 800080e8 <digits+0xa8>
    800011fc:	fffff097          	auipc	ra,0xfffff
    80001200:	34c080e7          	jalr	844(ra) # 80000548 <panic>

0000000080001204 <kvminit>:
{
    80001204:	1101                	addi	sp,sp,-32
    80001206:	ec06                	sd	ra,24(sp)
    80001208:	e822                	sd	s0,16(sp)
    8000120a:	e426                	sd	s1,8(sp)
    8000120c:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    8000120e:	00000097          	auipc	ra,0x0
    80001212:	912080e7          	jalr	-1774(ra) # 80000b20 <kalloc>
    80001216:	00008797          	auipc	a5,0x8
    8000121a:	dea7bd23          	sd	a0,-518(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    8000121e:	6605                	lui	a2,0x1
    80001220:	4581                	li	a1,0
    80001222:	00000097          	auipc	ra,0x0
    80001226:	aea080e7          	jalr	-1302(ra) # 80000d0c <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000122a:	4699                	li	a3,6
    8000122c:	6605                	lui	a2,0x1
    8000122e:	100005b7          	lui	a1,0x10000
    80001232:	10000537          	lui	a0,0x10000
    80001236:	00000097          	auipc	ra,0x0
    8000123a:	f96080e7          	jalr	-106(ra) # 800011cc <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000123e:	4699                	li	a3,6
    80001240:	6605                	lui	a2,0x1
    80001242:	100015b7          	lui	a1,0x10001
    80001246:	10001537          	lui	a0,0x10001
    8000124a:	00000097          	auipc	ra,0x0
    8000124e:	f82080e7          	jalr	-126(ra) # 800011cc <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    80001252:	4699                	li	a3,6
    80001254:	6641                	lui	a2,0x10
    80001256:	020005b7          	lui	a1,0x2000
    8000125a:	02000537          	lui	a0,0x2000
    8000125e:	00000097          	auipc	ra,0x0
    80001262:	f6e080e7          	jalr	-146(ra) # 800011cc <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001266:	4699                	li	a3,6
    80001268:	00400637          	lui	a2,0x400
    8000126c:	0c0005b7          	lui	a1,0xc000
    80001270:	0c000537          	lui	a0,0xc000
    80001274:	00000097          	auipc	ra,0x0
    80001278:	f58080e7          	jalr	-168(ra) # 800011cc <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    8000127c:	00007497          	auipc	s1,0x7
    80001280:	d8448493          	addi	s1,s1,-636 # 80008000 <etext>
    80001284:	46a9                	li	a3,10
    80001286:	80007617          	auipc	a2,0x80007
    8000128a:	d7a60613          	addi	a2,a2,-646 # 8000 <_entry-0x7fff8000>
    8000128e:	4585                	li	a1,1
    80001290:	05fe                	slli	a1,a1,0x1f
    80001292:	852e                	mv	a0,a1
    80001294:	00000097          	auipc	ra,0x0
    80001298:	f38080e7          	jalr	-200(ra) # 800011cc <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    8000129c:	4699                	li	a3,6
    8000129e:	4645                	li	a2,17
    800012a0:	066e                	slli	a2,a2,0x1b
    800012a2:	8e05                	sub	a2,a2,s1
    800012a4:	85a6                	mv	a1,s1
    800012a6:	8526                	mv	a0,s1
    800012a8:	00000097          	auipc	ra,0x0
    800012ac:	f24080e7          	jalr	-220(ra) # 800011cc <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800012b0:	46a9                	li	a3,10
    800012b2:	6605                	lui	a2,0x1
    800012b4:	00006597          	auipc	a1,0x6
    800012b8:	d4c58593          	addi	a1,a1,-692 # 80007000 <_trampoline>
    800012bc:	04000537          	lui	a0,0x4000
    800012c0:	157d                	addi	a0,a0,-1
    800012c2:	0532                	slli	a0,a0,0xc
    800012c4:	00000097          	auipc	ra,0x0
    800012c8:	f08080e7          	jalr	-248(ra) # 800011cc <kvmmap>
}
    800012cc:	60e2                	ld	ra,24(sp)
    800012ce:	6442                	ld	s0,16(sp)
    800012d0:	64a2                	ld	s1,8(sp)
    800012d2:	6105                	addi	sp,sp,32
    800012d4:	8082                	ret

00000000800012d6 <uvmlazytouch>:

// touch a lazy-allocated page so it's mapped to an actual physical page.
void uvmlazytouch(uint64 va) {
    800012d6:	7179                	addi	sp,sp,-48
    800012d8:	f406                	sd	ra,40(sp)
    800012da:	f022                	sd	s0,32(sp)
    800012dc:	ec26                	sd	s1,24(sp)
    800012de:	e84a                	sd	s2,16(sp)
    800012e0:	e44e                	sd	s3,8(sp)
    800012e2:	1800                	addi	s0,sp,48
    800012e4:	89aa                	mv	s3,a0
  struct proc *p = myproc();
    800012e6:	00000097          	auipc	ra,0x0
    800012ea:	7d8080e7          	jalr	2008(ra) # 80001abe <myproc>
    800012ee:	892a                	mv	s2,a0
  char *mem = kalloc();
    800012f0:	00000097          	auipc	ra,0x0
    800012f4:	830080e7          	jalr	-2000(ra) # 80000b20 <kalloc>
  if(mem == 0) {
    800012f8:	cd05                	beqz	a0,80001330 <uvmlazytouch+0x5a>
    800012fa:	84aa                	mv	s1,a0
    // failed to allocate physical memory
    printf("lazy alloc: out of memory\n");
    p->killed = 1;
  } else {
    memset(mem, 0, PGSIZE);
    800012fc:	6605                	lui	a2,0x1
    800012fe:	4581                	li	a1,0
    80001300:	00000097          	auipc	ra,0x0
    80001304:	a0c080e7          	jalr	-1524(ra) # 80000d0c <memset>
    if(mappages(p->pagetable, PGROUNDDOWN(va), PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001308:	4779                	li	a4,30
    8000130a:	86a6                	mv	a3,s1
    8000130c:	6605                	lui	a2,0x1
    8000130e:	75fd                	lui	a1,0xfffff
    80001310:	00b9f5b3          	and	a1,s3,a1
    80001314:	05093503          	ld	a0,80(s2)
    80001318:	00000097          	auipc	ra,0x0
    8000131c:	e26080e7          	jalr	-474(ra) # 8000113e <mappages>
    80001320:	e505                	bnez	a0,80001348 <uvmlazytouch+0x72>
      kfree(mem);
      p->killed = 1;
    }
  }
  // printf("lazy alloc: %p, p->sz: %p\n", PGROUNDDOWN(va), p->sz);
}
    80001322:	70a2                	ld	ra,40(sp)
    80001324:	7402                	ld	s0,32(sp)
    80001326:	64e2                	ld	s1,24(sp)
    80001328:	6942                	ld	s2,16(sp)
    8000132a:	69a2                	ld	s3,8(sp)
    8000132c:	6145                	addi	sp,sp,48
    8000132e:	8082                	ret
    printf("lazy alloc: out of memory\n");
    80001330:	00007517          	auipc	a0,0x7
    80001334:	dc050513          	addi	a0,a0,-576 # 800080f0 <digits+0xb0>
    80001338:	fffff097          	auipc	ra,0xfffff
    8000133c:	25a080e7          	jalr	602(ra) # 80000592 <printf>
    p->killed = 1;
    80001340:	4785                	li	a5,1
    80001342:	02f92823          	sw	a5,48(s2)
    80001346:	bff1                	j	80001322 <uvmlazytouch+0x4c>
      printf("lazy alloc: failed to map page\n");
    80001348:	00007517          	auipc	a0,0x7
    8000134c:	dc850513          	addi	a0,a0,-568 # 80008110 <digits+0xd0>
    80001350:	fffff097          	auipc	ra,0xfffff
    80001354:	242080e7          	jalr	578(ra) # 80000592 <printf>
      kfree(mem);
    80001358:	8526                	mv	a0,s1
    8000135a:	fffff097          	auipc	ra,0xfffff
    8000135e:	6ca080e7          	jalr	1738(ra) # 80000a24 <kfree>
      p->killed = 1;
    80001362:	4785                	li	a5,1
    80001364:	02f92823          	sw	a5,48(s2)
}
    80001368:	bf6d                	j	80001322 <uvmlazytouch+0x4c>

000000008000136a <uvmshouldtouch>:
// whether a page is previously lazy-allocated and needed to be touched before use.
int uvmshouldtouch(uint64 va) {
    8000136a:	1101                	addi	sp,sp,-32
    8000136c:	ec06                	sd	ra,24(sp)
    8000136e:	e822                	sd	s0,16(sp)
    80001370:	e426                	sd	s1,8(sp)
    80001372:	1000                	addi	s0,sp,32
    80001374:	84aa                	mv	s1,a0
  pte_t *pte;
  struct proc *p = myproc();
    80001376:	00000097          	auipc	ra,0x0
    8000137a:	748080e7          	jalr	1864(ra) # 80001abe <myproc>
  
  return va < p->sz // within size of memory for the process
    && PGROUNDDOWN(va) != r_sp() // not accessing stack guard page (it shouldn't be mapped)
    && (((pte = walk(p->pagetable, va, 0))==0) || ((*pte & PTE_V)==0)); // page table entry does not exist
    8000137e:	6538                	ld	a4,72(a0)
    80001380:	02e4f863          	bgeu	s1,a4,800013b0 <uvmshouldtouch+0x46>
    80001384:	87aa                	mv	a5,a0
  asm volatile("mv %0, sp" : "=r" (x) );
    80001386:	868a                	mv	a3,sp
    && PGROUNDDOWN(va) != r_sp() // not accessing stack guard page (it shouldn't be mapped)
    80001388:	777d                	lui	a4,0xfffff
    8000138a:	8f65                	and	a4,a4,s1
    && (((pte = walk(p->pagetable, va, 0))==0) || ((*pte & PTE_V)==0)); // page table entry does not exist
    8000138c:	4501                	li	a0,0
    && PGROUNDDOWN(va) != r_sp() // not accessing stack guard page (it shouldn't be mapped)
    8000138e:	02d70263          	beq	a4,a3,800013b2 <uvmshouldtouch+0x48>
    && (((pte = walk(p->pagetable, va, 0))==0) || ((*pte & PTE_V)==0)); // page table entry does not exist
    80001392:	4601                	li	a2,0
    80001394:	85a6                	mv	a1,s1
    80001396:	6ba8                	ld	a0,80(a5)
    80001398:	00000097          	auipc	ra,0x0
    8000139c:	c60080e7          	jalr	-928(ra) # 80000ff8 <walk>
    800013a0:	87aa                	mv	a5,a0
    800013a2:	4505                	li	a0,1
    800013a4:	c799                	beqz	a5,800013b2 <uvmshouldtouch+0x48>
    800013a6:	6388                	ld	a0,0(a5)
    800013a8:	00154513          	xori	a0,a0,1
    800013ac:	8905                	andi	a0,a0,1
    800013ae:	a011                	j	800013b2 <uvmshouldtouch+0x48>
    800013b0:	4501                	li	a0,0
}
    800013b2:	60e2                	ld	ra,24(sp)
    800013b4:	6442                	ld	s0,16(sp)
    800013b6:	64a2                	ld	s1,8(sp)
    800013b8:	6105                	addi	sp,sp,32
    800013ba:	8082                	ret

00000000800013bc <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800013bc:	715d                	addi	sp,sp,-80
    800013be:	e486                	sd	ra,72(sp)
    800013c0:	e0a2                	sd	s0,64(sp)
    800013c2:	fc26                	sd	s1,56(sp)
    800013c4:	f84a                	sd	s2,48(sp)
    800013c6:	f44e                	sd	s3,40(sp)
    800013c8:	f052                	sd	s4,32(sp)
    800013ca:	ec56                	sd	s5,24(sp)
    800013cc:	e85a                	sd	s6,16(sp)
    800013ce:	e45e                	sd	s7,8(sp)
    800013d0:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800013d2:	03459793          	slli	a5,a1,0x34
    800013d6:	e795                	bnez	a5,80001402 <uvmunmap+0x46>
    800013d8:	8a2a                	mv	s4,a0
    800013da:	892e                	mv	s2,a1
    800013dc:	8b36                	mv	s6,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013de:	0632                	slli	a2,a2,0xc
    800013e0:	00b609b3          	add	s3,a2,a1
      //panic("uvmunmap: walk");
      continue;
    if((*pte & PTE_V) == 0)
      //panic("uvmunmap: not mapped");
      continue;
    if(PTE_FLAGS(*pte) == PTE_V)
    800013e4:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013e6:	6a85                	lui	s5,0x1
    800013e8:	0535e963          	bltu	a1,s3,8000143a <uvmunmap+0x7e>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800013ec:	60a6                	ld	ra,72(sp)
    800013ee:	6406                	ld	s0,64(sp)
    800013f0:	74e2                	ld	s1,56(sp)
    800013f2:	7942                	ld	s2,48(sp)
    800013f4:	79a2                	ld	s3,40(sp)
    800013f6:	7a02                	ld	s4,32(sp)
    800013f8:	6ae2                	ld	s5,24(sp)
    800013fa:	6b42                	ld	s6,16(sp)
    800013fc:	6ba2                	ld	s7,8(sp)
    800013fe:	6161                	addi	sp,sp,80
    80001400:	8082                	ret
    panic("uvmunmap: not aligned");
    80001402:	00007517          	auipc	a0,0x7
    80001406:	d2e50513          	addi	a0,a0,-722 # 80008130 <digits+0xf0>
    8000140a:	fffff097          	auipc	ra,0xfffff
    8000140e:	13e080e7          	jalr	318(ra) # 80000548 <panic>
      panic("uvmunmap: not a leaf");
    80001412:	00007517          	auipc	a0,0x7
    80001416:	d3650513          	addi	a0,a0,-714 # 80008148 <digits+0x108>
    8000141a:	fffff097          	auipc	ra,0xfffff
    8000141e:	12e080e7          	jalr	302(ra) # 80000548 <panic>
      uint64 pa = PTE2PA(*pte);
    80001422:	83a9                	srli	a5,a5,0xa
      kfree((void*)pa);
    80001424:	00c79513          	slli	a0,a5,0xc
    80001428:	fffff097          	auipc	ra,0xfffff
    8000142c:	5fc080e7          	jalr	1532(ra) # 80000a24 <kfree>
    *pte = 0;
    80001430:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001434:	9956                	add	s2,s2,s5
    80001436:	fb397be3          	bgeu	s2,s3,800013ec <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000143a:	4601                	li	a2,0
    8000143c:	85ca                	mv	a1,s2
    8000143e:	8552                	mv	a0,s4
    80001440:	00000097          	auipc	ra,0x0
    80001444:	bb8080e7          	jalr	-1096(ra) # 80000ff8 <walk>
    80001448:	84aa                	mv	s1,a0
    8000144a:	d56d                	beqz	a0,80001434 <uvmunmap+0x78>
    if((*pte & PTE_V) == 0)
    8000144c:	611c                	ld	a5,0(a0)
    8000144e:	0017f713          	andi	a4,a5,1
    80001452:	d36d                	beqz	a4,80001434 <uvmunmap+0x78>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001454:	3ff7f713          	andi	a4,a5,1023
    80001458:	fb770de3          	beq	a4,s7,80001412 <uvmunmap+0x56>
    if(do_free){
    8000145c:	fc0b0ae3          	beqz	s6,80001430 <uvmunmap+0x74>
    80001460:	b7c9                	j	80001422 <uvmunmap+0x66>

0000000080001462 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001462:	1101                	addi	sp,sp,-32
    80001464:	ec06                	sd	ra,24(sp)
    80001466:	e822                	sd	s0,16(sp)
    80001468:	e426                	sd	s1,8(sp)
    8000146a:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000146c:	fffff097          	auipc	ra,0xfffff
    80001470:	6b4080e7          	jalr	1716(ra) # 80000b20 <kalloc>
    80001474:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001476:	c519                	beqz	a0,80001484 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001478:	6605                	lui	a2,0x1
    8000147a:	4581                	li	a1,0
    8000147c:	00000097          	auipc	ra,0x0
    80001480:	890080e7          	jalr	-1904(ra) # 80000d0c <memset>
  return pagetable;
}
    80001484:	8526                	mv	a0,s1
    80001486:	60e2                	ld	ra,24(sp)
    80001488:	6442                	ld	s0,16(sp)
    8000148a:	64a2                	ld	s1,8(sp)
    8000148c:	6105                	addi	sp,sp,32
    8000148e:	8082                	ret

0000000080001490 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001490:	7179                	addi	sp,sp,-48
    80001492:	f406                	sd	ra,40(sp)
    80001494:	f022                	sd	s0,32(sp)
    80001496:	ec26                	sd	s1,24(sp)
    80001498:	e84a                	sd	s2,16(sp)
    8000149a:	e44e                	sd	s3,8(sp)
    8000149c:	e052                	sd	s4,0(sp)
    8000149e:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800014a0:	6785                	lui	a5,0x1
    800014a2:	04f67863          	bgeu	a2,a5,800014f2 <uvminit+0x62>
    800014a6:	8a2a                	mv	s4,a0
    800014a8:	89ae                	mv	s3,a1
    800014aa:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    800014ac:	fffff097          	auipc	ra,0xfffff
    800014b0:	674080e7          	jalr	1652(ra) # 80000b20 <kalloc>
    800014b4:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800014b6:	6605                	lui	a2,0x1
    800014b8:	4581                	li	a1,0
    800014ba:	00000097          	auipc	ra,0x0
    800014be:	852080e7          	jalr	-1966(ra) # 80000d0c <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800014c2:	4779                	li	a4,30
    800014c4:	86ca                	mv	a3,s2
    800014c6:	6605                	lui	a2,0x1
    800014c8:	4581                	li	a1,0
    800014ca:	8552                	mv	a0,s4
    800014cc:	00000097          	auipc	ra,0x0
    800014d0:	c72080e7          	jalr	-910(ra) # 8000113e <mappages>
  memmove(mem, src, sz);
    800014d4:	8626                	mv	a2,s1
    800014d6:	85ce                	mv	a1,s3
    800014d8:	854a                	mv	a0,s2
    800014da:	00000097          	auipc	ra,0x0
    800014de:	892080e7          	jalr	-1902(ra) # 80000d6c <memmove>
}
    800014e2:	70a2                	ld	ra,40(sp)
    800014e4:	7402                	ld	s0,32(sp)
    800014e6:	64e2                	ld	s1,24(sp)
    800014e8:	6942                	ld	s2,16(sp)
    800014ea:	69a2                	ld	s3,8(sp)
    800014ec:	6a02                	ld	s4,0(sp)
    800014ee:	6145                	addi	sp,sp,48
    800014f0:	8082                	ret
    panic("inituvm: more than a page");
    800014f2:	00007517          	auipc	a0,0x7
    800014f6:	c6e50513          	addi	a0,a0,-914 # 80008160 <digits+0x120>
    800014fa:	fffff097          	auipc	ra,0xfffff
    800014fe:	04e080e7          	jalr	78(ra) # 80000548 <panic>

0000000080001502 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001502:	1101                	addi	sp,sp,-32
    80001504:	ec06                	sd	ra,24(sp)
    80001506:	e822                	sd	s0,16(sp)
    80001508:	e426                	sd	s1,8(sp)
    8000150a:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000150c:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    8000150e:	00b67d63          	bgeu	a2,a1,80001528 <uvmdealloc+0x26>
    80001512:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001514:	6785                	lui	a5,0x1
    80001516:	17fd                	addi	a5,a5,-1
    80001518:	00f60733          	add	a4,a2,a5
    8000151c:	767d                	lui	a2,0xfffff
    8000151e:	8f71                	and	a4,a4,a2
    80001520:	97ae                	add	a5,a5,a1
    80001522:	8ff1                	and	a5,a5,a2
    80001524:	00f76863          	bltu	a4,a5,80001534 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001528:	8526                	mv	a0,s1
    8000152a:	60e2                	ld	ra,24(sp)
    8000152c:	6442                	ld	s0,16(sp)
    8000152e:	64a2                	ld	s1,8(sp)
    80001530:	6105                	addi	sp,sp,32
    80001532:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001534:	8f99                	sub	a5,a5,a4
    80001536:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001538:	4685                	li	a3,1
    8000153a:	0007861b          	sext.w	a2,a5
    8000153e:	85ba                	mv	a1,a4
    80001540:	00000097          	auipc	ra,0x0
    80001544:	e7c080e7          	jalr	-388(ra) # 800013bc <uvmunmap>
    80001548:	b7c5                	j	80001528 <uvmdealloc+0x26>

000000008000154a <uvmalloc>:
  if(newsz < oldsz)
    8000154a:	0ab66163          	bltu	a2,a1,800015ec <uvmalloc+0xa2>
{
    8000154e:	7139                	addi	sp,sp,-64
    80001550:	fc06                	sd	ra,56(sp)
    80001552:	f822                	sd	s0,48(sp)
    80001554:	f426                	sd	s1,40(sp)
    80001556:	f04a                	sd	s2,32(sp)
    80001558:	ec4e                	sd	s3,24(sp)
    8000155a:	e852                	sd	s4,16(sp)
    8000155c:	e456                	sd	s5,8(sp)
    8000155e:	0080                	addi	s0,sp,64
    80001560:	8aaa                	mv	s5,a0
    80001562:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001564:	6985                	lui	s3,0x1
    80001566:	19fd                	addi	s3,s3,-1
    80001568:	95ce                	add	a1,a1,s3
    8000156a:	79fd                	lui	s3,0xfffff
    8000156c:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001570:	08c9f063          	bgeu	s3,a2,800015f0 <uvmalloc+0xa6>
    80001574:	894e                	mv	s2,s3
    mem = kalloc();
    80001576:	fffff097          	auipc	ra,0xfffff
    8000157a:	5aa080e7          	jalr	1450(ra) # 80000b20 <kalloc>
    8000157e:	84aa                	mv	s1,a0
    if(mem == 0){
    80001580:	c51d                	beqz	a0,800015ae <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001582:	6605                	lui	a2,0x1
    80001584:	4581                	li	a1,0
    80001586:	fffff097          	auipc	ra,0xfffff
    8000158a:	786080e7          	jalr	1926(ra) # 80000d0c <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000158e:	4779                	li	a4,30
    80001590:	86a6                	mv	a3,s1
    80001592:	6605                	lui	a2,0x1
    80001594:	85ca                	mv	a1,s2
    80001596:	8556                	mv	a0,s5
    80001598:	00000097          	auipc	ra,0x0
    8000159c:	ba6080e7          	jalr	-1114(ra) # 8000113e <mappages>
    800015a0:	e905                	bnez	a0,800015d0 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800015a2:	6785                	lui	a5,0x1
    800015a4:	993e                	add	s2,s2,a5
    800015a6:	fd4968e3          	bltu	s2,s4,80001576 <uvmalloc+0x2c>
  return newsz;
    800015aa:	8552                	mv	a0,s4
    800015ac:	a809                	j	800015be <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    800015ae:	864e                	mv	a2,s3
    800015b0:	85ca                	mv	a1,s2
    800015b2:	8556                	mv	a0,s5
    800015b4:	00000097          	auipc	ra,0x0
    800015b8:	f4e080e7          	jalr	-178(ra) # 80001502 <uvmdealloc>
      return 0;
    800015bc:	4501                	li	a0,0
}
    800015be:	70e2                	ld	ra,56(sp)
    800015c0:	7442                	ld	s0,48(sp)
    800015c2:	74a2                	ld	s1,40(sp)
    800015c4:	7902                	ld	s2,32(sp)
    800015c6:	69e2                	ld	s3,24(sp)
    800015c8:	6a42                	ld	s4,16(sp)
    800015ca:	6aa2                	ld	s5,8(sp)
    800015cc:	6121                	addi	sp,sp,64
    800015ce:	8082                	ret
      kfree(mem);
    800015d0:	8526                	mv	a0,s1
    800015d2:	fffff097          	auipc	ra,0xfffff
    800015d6:	452080e7          	jalr	1106(ra) # 80000a24 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800015da:	864e                	mv	a2,s3
    800015dc:	85ca                	mv	a1,s2
    800015de:	8556                	mv	a0,s5
    800015e0:	00000097          	auipc	ra,0x0
    800015e4:	f22080e7          	jalr	-222(ra) # 80001502 <uvmdealloc>
      return 0;
    800015e8:	4501                	li	a0,0
    800015ea:	bfd1                	j	800015be <uvmalloc+0x74>
    return oldsz;
    800015ec:	852e                	mv	a0,a1
}
    800015ee:	8082                	ret
  return newsz;
    800015f0:	8532                	mv	a0,a2
    800015f2:	b7f1                	j	800015be <uvmalloc+0x74>

00000000800015f4 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800015f4:	7179                	addi	sp,sp,-48
    800015f6:	f406                	sd	ra,40(sp)
    800015f8:	f022                	sd	s0,32(sp)
    800015fa:	ec26                	sd	s1,24(sp)
    800015fc:	e84a                	sd	s2,16(sp)
    800015fe:	e44e                	sd	s3,8(sp)
    80001600:	e052                	sd	s4,0(sp)
    80001602:	1800                	addi	s0,sp,48
    80001604:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001606:	84aa                	mv	s1,a0
    80001608:	6905                	lui	s2,0x1
    8000160a:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000160c:	4985                	li	s3,1
    8000160e:	a821                	j	80001626 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001610:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80001612:	0532                	slli	a0,a0,0xc
    80001614:	00000097          	auipc	ra,0x0
    80001618:	fe0080e7          	jalr	-32(ra) # 800015f4 <freewalk>
      pagetable[i] = 0;
    8000161c:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001620:	04a1                	addi	s1,s1,8
    80001622:	03248163          	beq	s1,s2,80001644 <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001626:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001628:	00f57793          	andi	a5,a0,15
    8000162c:	ff3782e3          	beq	a5,s3,80001610 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001630:	8905                	andi	a0,a0,1
    80001632:	d57d                	beqz	a0,80001620 <freewalk+0x2c>
      panic("freewalk: leaf");
    80001634:	00007517          	auipc	a0,0x7
    80001638:	b4c50513          	addi	a0,a0,-1204 # 80008180 <digits+0x140>
    8000163c:	fffff097          	auipc	ra,0xfffff
    80001640:	f0c080e7          	jalr	-244(ra) # 80000548 <panic>
    }
  }
  kfree((void*)pagetable);
    80001644:	8552                	mv	a0,s4
    80001646:	fffff097          	auipc	ra,0xfffff
    8000164a:	3de080e7          	jalr	990(ra) # 80000a24 <kfree>
}
    8000164e:	70a2                	ld	ra,40(sp)
    80001650:	7402                	ld	s0,32(sp)
    80001652:	64e2                	ld	s1,24(sp)
    80001654:	6942                	ld	s2,16(sp)
    80001656:	69a2                	ld	s3,8(sp)
    80001658:	6a02                	ld	s4,0(sp)
    8000165a:	6145                	addi	sp,sp,48
    8000165c:	8082                	ret

000000008000165e <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000165e:	1101                	addi	sp,sp,-32
    80001660:	ec06                	sd	ra,24(sp)
    80001662:	e822                	sd	s0,16(sp)
    80001664:	e426                	sd	s1,8(sp)
    80001666:	1000                	addi	s0,sp,32
    80001668:	84aa                	mv	s1,a0
  if(sz > 0)
    8000166a:	e999                	bnez	a1,80001680 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000166c:	8526                	mv	a0,s1
    8000166e:	00000097          	auipc	ra,0x0
    80001672:	f86080e7          	jalr	-122(ra) # 800015f4 <freewalk>
}
    80001676:	60e2                	ld	ra,24(sp)
    80001678:	6442                	ld	s0,16(sp)
    8000167a:	64a2                	ld	s1,8(sp)
    8000167c:	6105                	addi	sp,sp,32
    8000167e:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001680:	6605                	lui	a2,0x1
    80001682:	167d                	addi	a2,a2,-1
    80001684:	962e                	add	a2,a2,a1
    80001686:	4685                	li	a3,1
    80001688:	8231                	srli	a2,a2,0xc
    8000168a:	4581                	li	a1,0
    8000168c:	00000097          	auipc	ra,0x0
    80001690:	d30080e7          	jalr	-720(ra) # 800013bc <uvmunmap>
    80001694:	bfe1                	j	8000166c <uvmfree+0xe>

0000000080001696 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001696:	ca4d                	beqz	a2,80001748 <uvmcopy+0xb2>
{
    80001698:	715d                	addi	sp,sp,-80
    8000169a:	e486                	sd	ra,72(sp)
    8000169c:	e0a2                	sd	s0,64(sp)
    8000169e:	fc26                	sd	s1,56(sp)
    800016a0:	f84a                	sd	s2,48(sp)
    800016a2:	f44e                	sd	s3,40(sp)
    800016a4:	f052                	sd	s4,32(sp)
    800016a6:	ec56                	sd	s5,24(sp)
    800016a8:	e85a                	sd	s6,16(sp)
    800016aa:	e45e                	sd	s7,8(sp)
    800016ac:	0880                	addi	s0,sp,80
    800016ae:	8aaa                	mv	s5,a0
    800016b0:	8b2e                	mv	s6,a1
    800016b2:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800016b4:	4481                	li	s1,0
    800016b6:	a029                	j	800016c0 <uvmcopy+0x2a>
    800016b8:	6785                	lui	a5,0x1
    800016ba:	94be                	add	s1,s1,a5
    800016bc:	0744fa63          	bgeu	s1,s4,80001730 <uvmcopy+0x9a>
    if((pte = walk(old, i, 0)) == 0)
    800016c0:	4601                	li	a2,0
    800016c2:	85a6                	mv	a1,s1
    800016c4:	8556                	mv	a0,s5
    800016c6:	00000097          	auipc	ra,0x0
    800016ca:	932080e7          	jalr	-1742(ra) # 80000ff8 <walk>
    800016ce:	d56d                	beqz	a0,800016b8 <uvmcopy+0x22>
      //panic("uvmcopy: pte should exist");
      continue;
    if((*pte & PTE_V) == 0)
    800016d0:	6118                	ld	a4,0(a0)
    800016d2:	00177793          	andi	a5,a4,1
    800016d6:	d3ed                	beqz	a5,800016b8 <uvmcopy+0x22>
      //panic("uvmcopy: page not present");
      continue;;
    pa = PTE2PA(*pte);
    800016d8:	00a75593          	srli	a1,a4,0xa
    800016dc:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800016e0:	3ff77913          	andi	s2,a4,1023
    if((mem = kalloc()) == 0)
    800016e4:	fffff097          	auipc	ra,0xfffff
    800016e8:	43c080e7          	jalr	1084(ra) # 80000b20 <kalloc>
    800016ec:	89aa                	mv	s3,a0
    800016ee:	c515                	beqz	a0,8000171a <uvmcopy+0x84>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800016f0:	6605                	lui	a2,0x1
    800016f2:	85de                	mv	a1,s7
    800016f4:	fffff097          	auipc	ra,0xfffff
    800016f8:	678080e7          	jalr	1656(ra) # 80000d6c <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800016fc:	874a                	mv	a4,s2
    800016fe:	86ce                	mv	a3,s3
    80001700:	6605                	lui	a2,0x1
    80001702:	85a6                	mv	a1,s1
    80001704:	855a                	mv	a0,s6
    80001706:	00000097          	auipc	ra,0x0
    8000170a:	a38080e7          	jalr	-1480(ra) # 8000113e <mappages>
    8000170e:	d54d                	beqz	a0,800016b8 <uvmcopy+0x22>
      kfree(mem);
    80001710:	854e                	mv	a0,s3
    80001712:	fffff097          	auipc	ra,0xfffff
    80001716:	312080e7          	jalr	786(ra) # 80000a24 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000171a:	4685                	li	a3,1
    8000171c:	00c4d613          	srli	a2,s1,0xc
    80001720:	4581                	li	a1,0
    80001722:	855a                	mv	a0,s6
    80001724:	00000097          	auipc	ra,0x0
    80001728:	c98080e7          	jalr	-872(ra) # 800013bc <uvmunmap>
  return -1;
    8000172c:	557d                	li	a0,-1
    8000172e:	a011                	j	80001732 <uvmcopy+0x9c>
  return 0;
    80001730:	4501                	li	a0,0
}
    80001732:	60a6                	ld	ra,72(sp)
    80001734:	6406                	ld	s0,64(sp)
    80001736:	74e2                	ld	s1,56(sp)
    80001738:	7942                	ld	s2,48(sp)
    8000173a:	79a2                	ld	s3,40(sp)
    8000173c:	7a02                	ld	s4,32(sp)
    8000173e:	6ae2                	ld	s5,24(sp)
    80001740:	6b42                	ld	s6,16(sp)
    80001742:	6ba2                	ld	s7,8(sp)
    80001744:	6161                	addi	sp,sp,80
    80001746:	8082                	ret
  return 0;
    80001748:	4501                	li	a0,0
}
    8000174a:	8082                	ret

000000008000174c <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000174c:	1141                	addi	sp,sp,-16
    8000174e:	e406                	sd	ra,8(sp)
    80001750:	e022                	sd	s0,0(sp)
    80001752:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001754:	4601                	li	a2,0
    80001756:	00000097          	auipc	ra,0x0
    8000175a:	8a2080e7          	jalr	-1886(ra) # 80000ff8 <walk>
  if(pte == 0)
    8000175e:	c901                	beqz	a0,8000176e <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001760:	611c                	ld	a5,0(a0)
    80001762:	9bbd                	andi	a5,a5,-17
    80001764:	e11c                	sd	a5,0(a0)
}
    80001766:	60a2                	ld	ra,8(sp)
    80001768:	6402                	ld	s0,0(sp)
    8000176a:	0141                	addi	sp,sp,16
    8000176c:	8082                	ret
    panic("uvmclear");
    8000176e:	00007517          	auipc	a0,0x7
    80001772:	a2250513          	addi	a0,a0,-1502 # 80008190 <digits+0x150>
    80001776:	fffff097          	auipc	ra,0xfffff
    8000177a:	dd2080e7          	jalr	-558(ra) # 80000548 <panic>

000000008000177e <copyout>:
// Copy from kernel to user.
// Copy len bytes from src to virtual address dstva in a given page table.
// Return 0 on success, -1 on error.
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
    8000177e:	715d                	addi	sp,sp,-80
    80001780:	e486                	sd	ra,72(sp)
    80001782:	e0a2                	sd	s0,64(sp)
    80001784:	fc26                	sd	s1,56(sp)
    80001786:	f84a                	sd	s2,48(sp)
    80001788:	f44e                	sd	s3,40(sp)
    8000178a:	f052                	sd	s4,32(sp)
    8000178c:	ec56                	sd	s5,24(sp)
    8000178e:	e85a                	sd	s6,16(sp)
    80001790:	e45e                	sd	s7,8(sp)
    80001792:	e062                	sd	s8,0(sp)
    80001794:	0880                	addi	s0,sp,80
    80001796:	8b2a                	mv	s6,a0
    80001798:	8c2e                	mv	s8,a1
    8000179a:	8a32                	mv	s4,a2
    8000179c:	89b6                	mv	s3,a3
  uint64 n, va0, pa0;

  if(uvmshouldtouch(dstva))
    8000179e:	852e                	mv	a0,a1
    800017a0:	00000097          	auipc	ra,0x0
    800017a4:	bca080e7          	jalr	-1078(ra) # 8000136a <uvmshouldtouch>
    800017a8:	e511                	bnez	a0,800017b4 <copyout+0x36>
    uvmlazytouch(dstva);
  while(len > 0){
    800017aa:	04098e63          	beqz	s3,80001806 <copyout+0x88>
    va0 = PGROUNDDOWN(dstva);
    800017ae:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800017b0:	6a85                	lui	s5,0x1
    800017b2:	a805                	j	800017e2 <copyout+0x64>
    uvmlazytouch(dstva);
    800017b4:	8562                	mv	a0,s8
    800017b6:	00000097          	auipc	ra,0x0
    800017ba:	b20080e7          	jalr	-1248(ra) # 800012d6 <uvmlazytouch>
    800017be:	b7f5                	j	800017aa <copyout+0x2c>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800017c0:	9562                	add	a0,a0,s8
    800017c2:	0004861b          	sext.w	a2,s1
    800017c6:	85d2                	mv	a1,s4
    800017c8:	41250533          	sub	a0,a0,s2
    800017cc:	fffff097          	auipc	ra,0xfffff
    800017d0:	5a0080e7          	jalr	1440(ra) # 80000d6c <memmove>

    len -= n;
    800017d4:	409989b3          	sub	s3,s3,s1
    src += n;
    800017d8:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800017da:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800017de:	02098263          	beqz	s3,80001802 <copyout+0x84>
    va0 = PGROUNDDOWN(dstva);
    800017e2:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800017e6:	85ca                	mv	a1,s2
    800017e8:	855a                	mv	a0,s6
    800017ea:	00000097          	auipc	ra,0x0
    800017ee:	8b4080e7          	jalr	-1868(ra) # 8000109e <walkaddr>
    if(pa0 == 0)
    800017f2:	cd01                	beqz	a0,8000180a <copyout+0x8c>
    n = PGSIZE - (dstva - va0);
    800017f4:	418904b3          	sub	s1,s2,s8
    800017f8:	94d6                	add	s1,s1,s5
    if(n > len)
    800017fa:	fc99f3e3          	bgeu	s3,s1,800017c0 <copyout+0x42>
    800017fe:	84ce                	mv	s1,s3
    80001800:	b7c1                	j	800017c0 <copyout+0x42>
  }
  return 0;
    80001802:	4501                	li	a0,0
    80001804:	a021                	j	8000180c <copyout+0x8e>
    80001806:	4501                	li	a0,0
    80001808:	a011                	j	8000180c <copyout+0x8e>
      return -1;
    8000180a:	557d                	li	a0,-1
}
    8000180c:	60a6                	ld	ra,72(sp)
    8000180e:	6406                	ld	s0,64(sp)
    80001810:	74e2                	ld	s1,56(sp)
    80001812:	7942                	ld	s2,48(sp)
    80001814:	79a2                	ld	s3,40(sp)
    80001816:	7a02                	ld	s4,32(sp)
    80001818:	6ae2                	ld	s5,24(sp)
    8000181a:	6b42                	ld	s6,16(sp)
    8000181c:	6ba2                	ld	s7,8(sp)
    8000181e:	6c02                	ld	s8,0(sp)
    80001820:	6161                	addi	sp,sp,80
    80001822:	8082                	ret

0000000080001824 <copyin>:
// Copy from user to kernel.
// Copy len bytes to dst from virtual address srcva in a given page table.
// Return 0 on success, -1 on error.
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
    80001824:	715d                	addi	sp,sp,-80
    80001826:	e486                	sd	ra,72(sp)
    80001828:	e0a2                	sd	s0,64(sp)
    8000182a:	fc26                	sd	s1,56(sp)
    8000182c:	f84a                	sd	s2,48(sp)
    8000182e:	f44e                	sd	s3,40(sp)
    80001830:	f052                	sd	s4,32(sp)
    80001832:	ec56                	sd	s5,24(sp)
    80001834:	e85a                	sd	s6,16(sp)
    80001836:	e45e                	sd	s7,8(sp)
    80001838:	e062                	sd	s8,0(sp)
    8000183a:	0880                	addi	s0,sp,80
    8000183c:	8b2a                	mv	s6,a0
    8000183e:	8a2e                	mv	s4,a1
    80001840:	8c32                	mv	s8,a2
    80001842:	89b6                	mv	s3,a3
  uint64 n, va0, pa0;

  if(uvmshouldtouch(srcva))
    80001844:	8532                	mv	a0,a2
    80001846:	00000097          	auipc	ra,0x0
    8000184a:	b24080e7          	jalr	-1244(ra) # 8000136a <uvmshouldtouch>
    8000184e:	e511                	bnez	a0,8000185a <copyin+0x36>
    uvmlazytouch(srcva);
  while(len > 0){
    80001850:	04098e63          	beqz	s3,800018ac <copyin+0x88>
    va0 = PGROUNDDOWN(srcva);
    80001854:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001856:	6a85                	lui	s5,0x1
    80001858:	a805                	j	80001888 <copyin+0x64>
    uvmlazytouch(srcva);
    8000185a:	8562                	mv	a0,s8
    8000185c:	00000097          	auipc	ra,0x0
    80001860:	a7a080e7          	jalr	-1414(ra) # 800012d6 <uvmlazytouch>
    80001864:	b7f5                	j	80001850 <copyin+0x2c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001866:	9562                	add	a0,a0,s8
    80001868:	0004861b          	sext.w	a2,s1
    8000186c:	412505b3          	sub	a1,a0,s2
    80001870:	8552                	mv	a0,s4
    80001872:	fffff097          	auipc	ra,0xfffff
    80001876:	4fa080e7          	jalr	1274(ra) # 80000d6c <memmove>

    len -= n;
    8000187a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000187e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001880:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001884:	02098263          	beqz	s3,800018a8 <copyin+0x84>
    va0 = PGROUNDDOWN(srcva);
    80001888:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000188c:	85ca                	mv	a1,s2
    8000188e:	855a                	mv	a0,s6
    80001890:	00000097          	auipc	ra,0x0
    80001894:	80e080e7          	jalr	-2034(ra) # 8000109e <walkaddr>
    if(pa0 == 0)
    80001898:	cd01                	beqz	a0,800018b0 <copyin+0x8c>
    n = PGSIZE - (srcva - va0);
    8000189a:	418904b3          	sub	s1,s2,s8
    8000189e:	94d6                	add	s1,s1,s5
    if(n > len)
    800018a0:	fc99f3e3          	bgeu	s3,s1,80001866 <copyin+0x42>
    800018a4:	84ce                	mv	s1,s3
    800018a6:	b7c1                	j	80001866 <copyin+0x42>
  }
  return 0;
    800018a8:	4501                	li	a0,0
    800018aa:	a021                	j	800018b2 <copyin+0x8e>
    800018ac:	4501                	li	a0,0
    800018ae:	a011                	j	800018b2 <copyin+0x8e>
      return -1;
    800018b0:	557d                	li	a0,-1
}
    800018b2:	60a6                	ld	ra,72(sp)
    800018b4:	6406                	ld	s0,64(sp)
    800018b6:	74e2                	ld	s1,56(sp)
    800018b8:	7942                	ld	s2,48(sp)
    800018ba:	79a2                	ld	s3,40(sp)
    800018bc:	7a02                	ld	s4,32(sp)
    800018be:	6ae2                	ld	s5,24(sp)
    800018c0:	6b42                	ld	s6,16(sp)
    800018c2:	6ba2                	ld	s7,8(sp)
    800018c4:	6c02                	ld	s8,0(sp)
    800018c6:	6161                	addi	sp,sp,80
    800018c8:	8082                	ret

00000000800018ca <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800018ca:	c6c5                	beqz	a3,80001972 <copyinstr+0xa8>
{
    800018cc:	715d                	addi	sp,sp,-80
    800018ce:	e486                	sd	ra,72(sp)
    800018d0:	e0a2                	sd	s0,64(sp)
    800018d2:	fc26                	sd	s1,56(sp)
    800018d4:	f84a                	sd	s2,48(sp)
    800018d6:	f44e                	sd	s3,40(sp)
    800018d8:	f052                	sd	s4,32(sp)
    800018da:	ec56                	sd	s5,24(sp)
    800018dc:	e85a                	sd	s6,16(sp)
    800018de:	e45e                	sd	s7,8(sp)
    800018e0:	0880                	addi	s0,sp,80
    800018e2:	8a2a                	mv	s4,a0
    800018e4:	8b2e                	mv	s6,a1
    800018e6:	8bb2                	mv	s7,a2
    800018e8:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800018ea:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800018ec:	6985                	lui	s3,0x1
    800018ee:	a035                	j	8000191a <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800018f0:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800018f4:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800018f6:	0017b793          	seqz	a5,a5
    800018fa:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800018fe:	60a6                	ld	ra,72(sp)
    80001900:	6406                	ld	s0,64(sp)
    80001902:	74e2                	ld	s1,56(sp)
    80001904:	7942                	ld	s2,48(sp)
    80001906:	79a2                	ld	s3,40(sp)
    80001908:	7a02                	ld	s4,32(sp)
    8000190a:	6ae2                	ld	s5,24(sp)
    8000190c:	6b42                	ld	s6,16(sp)
    8000190e:	6ba2                	ld	s7,8(sp)
    80001910:	6161                	addi	sp,sp,80
    80001912:	8082                	ret
    srcva = va0 + PGSIZE;
    80001914:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001918:	c8a9                	beqz	s1,8000196a <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    8000191a:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    8000191e:	85ca                	mv	a1,s2
    80001920:	8552                	mv	a0,s4
    80001922:	fffff097          	auipc	ra,0xfffff
    80001926:	77c080e7          	jalr	1916(ra) # 8000109e <walkaddr>
    if(pa0 == 0)
    8000192a:	c131                	beqz	a0,8000196e <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    8000192c:	41790833          	sub	a6,s2,s7
    80001930:	984e                	add	a6,a6,s3
    if(n > max)
    80001932:	0104f363          	bgeu	s1,a6,80001938 <copyinstr+0x6e>
    80001936:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001938:	955e                	add	a0,a0,s7
    8000193a:	41250533          	sub	a0,a0,s2
    while(n > 0){
    8000193e:	fc080be3          	beqz	a6,80001914 <copyinstr+0x4a>
    80001942:	985a                	add	a6,a6,s6
    80001944:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001946:	41650633          	sub	a2,a0,s6
    8000194a:	14fd                	addi	s1,s1,-1
    8000194c:	9b26                	add	s6,s6,s1
    8000194e:	00f60733          	add	a4,a2,a5
    80001952:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd9000>
    80001956:	df49                	beqz	a4,800018f0 <copyinstr+0x26>
        *dst = *p;
    80001958:	00e78023          	sb	a4,0(a5)
      --max;
    8000195c:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001960:	0785                	addi	a5,a5,1
    while(n > 0){
    80001962:	ff0796e3          	bne	a5,a6,8000194e <copyinstr+0x84>
      dst++;
    80001966:	8b42                	mv	s6,a6
    80001968:	b775                	j	80001914 <copyinstr+0x4a>
    8000196a:	4781                	li	a5,0
    8000196c:	b769                	j	800018f6 <copyinstr+0x2c>
      return -1;
    8000196e:	557d                	li	a0,-1
    80001970:	b779                	j	800018fe <copyinstr+0x34>
  int got_null = 0;
    80001972:	4781                	li	a5,0
  if(got_null){
    80001974:	0017b793          	seqz	a5,a5
    80001978:	40f00533          	neg	a0,a5
}
    8000197c:	8082                	ret

000000008000197e <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    8000197e:	1101                	addi	sp,sp,-32
    80001980:	ec06                	sd	ra,24(sp)
    80001982:	e822                	sd	s0,16(sp)
    80001984:	e426                	sd	s1,8(sp)
    80001986:	1000                	addi	s0,sp,32
    80001988:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000198a:	fffff097          	auipc	ra,0xfffff
    8000198e:	20c080e7          	jalr	524(ra) # 80000b96 <holding>
    80001992:	c909                	beqz	a0,800019a4 <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    80001994:	749c                	ld	a5,40(s1)
    80001996:	00978f63          	beq	a5,s1,800019b4 <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    8000199a:	60e2                	ld	ra,24(sp)
    8000199c:	6442                	ld	s0,16(sp)
    8000199e:	64a2                	ld	s1,8(sp)
    800019a0:	6105                	addi	sp,sp,32
    800019a2:	8082                	ret
    panic("wakeup1");
    800019a4:	00006517          	auipc	a0,0x6
    800019a8:	7fc50513          	addi	a0,a0,2044 # 800081a0 <digits+0x160>
    800019ac:	fffff097          	auipc	ra,0xfffff
    800019b0:	b9c080e7          	jalr	-1124(ra) # 80000548 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    800019b4:	4c98                	lw	a4,24(s1)
    800019b6:	4785                	li	a5,1
    800019b8:	fef711e3          	bne	a4,a5,8000199a <wakeup1+0x1c>
    p->state = RUNNABLE;
    800019bc:	4789                	li	a5,2
    800019be:	cc9c                	sw	a5,24(s1)
}
    800019c0:	bfe9                	j	8000199a <wakeup1+0x1c>

00000000800019c2 <procinit>:
{
    800019c2:	715d                	addi	sp,sp,-80
    800019c4:	e486                	sd	ra,72(sp)
    800019c6:	e0a2                	sd	s0,64(sp)
    800019c8:	fc26                	sd	s1,56(sp)
    800019ca:	f84a                	sd	s2,48(sp)
    800019cc:	f44e                	sd	s3,40(sp)
    800019ce:	f052                	sd	s4,32(sp)
    800019d0:	ec56                	sd	s5,24(sp)
    800019d2:	e85a                	sd	s6,16(sp)
    800019d4:	e45e                	sd	s7,8(sp)
    800019d6:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    800019d8:	00006597          	auipc	a1,0x6
    800019dc:	7d058593          	addi	a1,a1,2000 # 800081a8 <digits+0x168>
    800019e0:	00010517          	auipc	a0,0x10
    800019e4:	f7050513          	addi	a0,a0,-144 # 80011950 <pid_lock>
    800019e8:	fffff097          	auipc	ra,0xfffff
    800019ec:	198080e7          	jalr	408(ra) # 80000b80 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    800019f0:	00010917          	auipc	s2,0x10
    800019f4:	37890913          	addi	s2,s2,888 # 80011d68 <proc>
      initlock(&p->lock, "proc");
    800019f8:	00006b97          	auipc	s7,0x6
    800019fc:	7b8b8b93          	addi	s7,s7,1976 # 800081b0 <digits+0x170>
      uint64 va = KSTACK((int) (p - proc));
    80001a00:	8b4a                	mv	s6,s2
    80001a02:	00006a97          	auipc	s5,0x6
    80001a06:	5fea8a93          	addi	s5,s5,1534 # 80008000 <etext>
    80001a0a:	040009b7          	lui	s3,0x4000
    80001a0e:	19fd                	addi	s3,s3,-1
    80001a10:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a12:	00016a17          	auipc	s4,0x16
    80001a16:	d56a0a13          	addi	s4,s4,-682 # 80017768 <tickslock>
      initlock(&p->lock, "proc");
    80001a1a:	85de                	mv	a1,s7
    80001a1c:	854a                	mv	a0,s2
    80001a1e:	fffff097          	auipc	ra,0xfffff
    80001a22:	162080e7          	jalr	354(ra) # 80000b80 <initlock>
      char *pa = kalloc();
    80001a26:	fffff097          	auipc	ra,0xfffff
    80001a2a:	0fa080e7          	jalr	250(ra) # 80000b20 <kalloc>
    80001a2e:	85aa                	mv	a1,a0
      if(pa == 0)
    80001a30:	c929                	beqz	a0,80001a82 <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    80001a32:	416904b3          	sub	s1,s2,s6
    80001a36:	848d                	srai	s1,s1,0x3
    80001a38:	000ab783          	ld	a5,0(s5)
    80001a3c:	02f484b3          	mul	s1,s1,a5
    80001a40:	2485                	addiw	s1,s1,1
    80001a42:	00d4949b          	slliw	s1,s1,0xd
    80001a46:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001a4a:	4699                	li	a3,6
    80001a4c:	6605                	lui	a2,0x1
    80001a4e:	8526                	mv	a0,s1
    80001a50:	fffff097          	auipc	ra,0xfffff
    80001a54:	77c080e7          	jalr	1916(ra) # 800011cc <kvmmap>
      p->kstack = va;
    80001a58:	04993023          	sd	s1,64(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a5c:	16890913          	addi	s2,s2,360
    80001a60:	fb491de3          	bne	s2,s4,80001a1a <procinit+0x58>
  kvminithart();
    80001a64:	fffff097          	auipc	ra,0xfffff
    80001a68:	570080e7          	jalr	1392(ra) # 80000fd4 <kvminithart>
}
    80001a6c:	60a6                	ld	ra,72(sp)
    80001a6e:	6406                	ld	s0,64(sp)
    80001a70:	74e2                	ld	s1,56(sp)
    80001a72:	7942                	ld	s2,48(sp)
    80001a74:	79a2                	ld	s3,40(sp)
    80001a76:	7a02                	ld	s4,32(sp)
    80001a78:	6ae2                	ld	s5,24(sp)
    80001a7a:	6b42                	ld	s6,16(sp)
    80001a7c:	6ba2                	ld	s7,8(sp)
    80001a7e:	6161                	addi	sp,sp,80
    80001a80:	8082                	ret
        panic("kalloc");
    80001a82:	00006517          	auipc	a0,0x6
    80001a86:	73650513          	addi	a0,a0,1846 # 800081b8 <digits+0x178>
    80001a8a:	fffff097          	auipc	ra,0xfffff
    80001a8e:	abe080e7          	jalr	-1346(ra) # 80000548 <panic>

0000000080001a92 <cpuid>:
{
    80001a92:	1141                	addi	sp,sp,-16
    80001a94:	e422                	sd	s0,8(sp)
    80001a96:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a98:	8512                	mv	a0,tp
}
    80001a9a:	2501                	sext.w	a0,a0
    80001a9c:	6422                	ld	s0,8(sp)
    80001a9e:	0141                	addi	sp,sp,16
    80001aa0:	8082                	ret

0000000080001aa2 <mycpu>:
mycpu(void) {
    80001aa2:	1141                	addi	sp,sp,-16
    80001aa4:	e422                	sd	s0,8(sp)
    80001aa6:	0800                	addi	s0,sp,16
    80001aa8:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001aaa:	2781                	sext.w	a5,a5
    80001aac:	079e                	slli	a5,a5,0x7
}
    80001aae:	00010517          	auipc	a0,0x10
    80001ab2:	eba50513          	addi	a0,a0,-326 # 80011968 <cpus>
    80001ab6:	953e                	add	a0,a0,a5
    80001ab8:	6422                	ld	s0,8(sp)
    80001aba:	0141                	addi	sp,sp,16
    80001abc:	8082                	ret

0000000080001abe <myproc>:
myproc(void) {
    80001abe:	1101                	addi	sp,sp,-32
    80001ac0:	ec06                	sd	ra,24(sp)
    80001ac2:	e822                	sd	s0,16(sp)
    80001ac4:	e426                	sd	s1,8(sp)
    80001ac6:	1000                	addi	s0,sp,32
  push_off();
    80001ac8:	fffff097          	auipc	ra,0xfffff
    80001acc:	0fc080e7          	jalr	252(ra) # 80000bc4 <push_off>
    80001ad0:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001ad2:	2781                	sext.w	a5,a5
    80001ad4:	079e                	slli	a5,a5,0x7
    80001ad6:	00010717          	auipc	a4,0x10
    80001ada:	e7a70713          	addi	a4,a4,-390 # 80011950 <pid_lock>
    80001ade:	97ba                	add	a5,a5,a4
    80001ae0:	6f84                	ld	s1,24(a5)
  pop_off();
    80001ae2:	fffff097          	auipc	ra,0xfffff
    80001ae6:	182080e7          	jalr	386(ra) # 80000c64 <pop_off>
}
    80001aea:	8526                	mv	a0,s1
    80001aec:	60e2                	ld	ra,24(sp)
    80001aee:	6442                	ld	s0,16(sp)
    80001af0:	64a2                	ld	s1,8(sp)
    80001af2:	6105                	addi	sp,sp,32
    80001af4:	8082                	ret

0000000080001af6 <forkret>:
{
    80001af6:	1141                	addi	sp,sp,-16
    80001af8:	e406                	sd	ra,8(sp)
    80001afa:	e022                	sd	s0,0(sp)
    80001afc:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001afe:	00000097          	auipc	ra,0x0
    80001b02:	fc0080e7          	jalr	-64(ra) # 80001abe <myproc>
    80001b06:	fffff097          	auipc	ra,0xfffff
    80001b0a:	1be080e7          	jalr	446(ra) # 80000cc4 <release>
  if (first) {
    80001b0e:	00007797          	auipc	a5,0x7
    80001b12:	ce27a783          	lw	a5,-798(a5) # 800087f0 <first.1662>
    80001b16:	eb89                	bnez	a5,80001b28 <forkret+0x32>
  usertrapret();
    80001b18:	00001097          	auipc	ra,0x1
    80001b1c:	c1c080e7          	jalr	-996(ra) # 80002734 <usertrapret>
}
    80001b20:	60a2                	ld	ra,8(sp)
    80001b22:	6402                	ld	s0,0(sp)
    80001b24:	0141                	addi	sp,sp,16
    80001b26:	8082                	ret
    first = 0;
    80001b28:	00007797          	auipc	a5,0x7
    80001b2c:	cc07a423          	sw	zero,-824(a5) # 800087f0 <first.1662>
    fsinit(ROOTDEV);
    80001b30:	4505                	li	a0,1
    80001b32:	00002097          	auipc	ra,0x2
    80001b36:	9a4080e7          	jalr	-1628(ra) # 800034d6 <fsinit>
    80001b3a:	bff9                	j	80001b18 <forkret+0x22>

0000000080001b3c <allocpid>:
allocpid() {
    80001b3c:	1101                	addi	sp,sp,-32
    80001b3e:	ec06                	sd	ra,24(sp)
    80001b40:	e822                	sd	s0,16(sp)
    80001b42:	e426                	sd	s1,8(sp)
    80001b44:	e04a                	sd	s2,0(sp)
    80001b46:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001b48:	00010917          	auipc	s2,0x10
    80001b4c:	e0890913          	addi	s2,s2,-504 # 80011950 <pid_lock>
    80001b50:	854a                	mv	a0,s2
    80001b52:	fffff097          	auipc	ra,0xfffff
    80001b56:	0be080e7          	jalr	190(ra) # 80000c10 <acquire>
  pid = nextpid;
    80001b5a:	00007797          	auipc	a5,0x7
    80001b5e:	c9a78793          	addi	a5,a5,-870 # 800087f4 <nextpid>
    80001b62:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001b64:	0014871b          	addiw	a4,s1,1
    80001b68:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001b6a:	854a                	mv	a0,s2
    80001b6c:	fffff097          	auipc	ra,0xfffff
    80001b70:	158080e7          	jalr	344(ra) # 80000cc4 <release>
}
    80001b74:	8526                	mv	a0,s1
    80001b76:	60e2                	ld	ra,24(sp)
    80001b78:	6442                	ld	s0,16(sp)
    80001b7a:	64a2                	ld	s1,8(sp)
    80001b7c:	6902                	ld	s2,0(sp)
    80001b7e:	6105                	addi	sp,sp,32
    80001b80:	8082                	ret

0000000080001b82 <proc_pagetable>:
{
    80001b82:	1101                	addi	sp,sp,-32
    80001b84:	ec06                	sd	ra,24(sp)
    80001b86:	e822                	sd	s0,16(sp)
    80001b88:	e426                	sd	s1,8(sp)
    80001b8a:	e04a                	sd	s2,0(sp)
    80001b8c:	1000                	addi	s0,sp,32
    80001b8e:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001b90:	00000097          	auipc	ra,0x0
    80001b94:	8d2080e7          	jalr	-1838(ra) # 80001462 <uvmcreate>
    80001b98:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001b9a:	c121                	beqz	a0,80001bda <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b9c:	4729                	li	a4,10
    80001b9e:	00005697          	auipc	a3,0x5
    80001ba2:	46268693          	addi	a3,a3,1122 # 80007000 <_trampoline>
    80001ba6:	6605                	lui	a2,0x1
    80001ba8:	040005b7          	lui	a1,0x4000
    80001bac:	15fd                	addi	a1,a1,-1
    80001bae:	05b2                	slli	a1,a1,0xc
    80001bb0:	fffff097          	auipc	ra,0xfffff
    80001bb4:	58e080e7          	jalr	1422(ra) # 8000113e <mappages>
    80001bb8:	02054863          	bltz	a0,80001be8 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001bbc:	4719                	li	a4,6
    80001bbe:	05893683          	ld	a3,88(s2)
    80001bc2:	6605                	lui	a2,0x1
    80001bc4:	020005b7          	lui	a1,0x2000
    80001bc8:	15fd                	addi	a1,a1,-1
    80001bca:	05b6                	slli	a1,a1,0xd
    80001bcc:	8526                	mv	a0,s1
    80001bce:	fffff097          	auipc	ra,0xfffff
    80001bd2:	570080e7          	jalr	1392(ra) # 8000113e <mappages>
    80001bd6:	02054163          	bltz	a0,80001bf8 <proc_pagetable+0x76>
}
    80001bda:	8526                	mv	a0,s1
    80001bdc:	60e2                	ld	ra,24(sp)
    80001bde:	6442                	ld	s0,16(sp)
    80001be0:	64a2                	ld	s1,8(sp)
    80001be2:	6902                	ld	s2,0(sp)
    80001be4:	6105                	addi	sp,sp,32
    80001be6:	8082                	ret
    uvmfree(pagetable, 0);
    80001be8:	4581                	li	a1,0
    80001bea:	8526                	mv	a0,s1
    80001bec:	00000097          	auipc	ra,0x0
    80001bf0:	a72080e7          	jalr	-1422(ra) # 8000165e <uvmfree>
    return 0;
    80001bf4:	4481                	li	s1,0
    80001bf6:	b7d5                	j	80001bda <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001bf8:	4681                	li	a3,0
    80001bfa:	4605                	li	a2,1
    80001bfc:	040005b7          	lui	a1,0x4000
    80001c00:	15fd                	addi	a1,a1,-1
    80001c02:	05b2                	slli	a1,a1,0xc
    80001c04:	8526                	mv	a0,s1
    80001c06:	fffff097          	auipc	ra,0xfffff
    80001c0a:	7b6080e7          	jalr	1974(ra) # 800013bc <uvmunmap>
    uvmfree(pagetable, 0);
    80001c0e:	4581                	li	a1,0
    80001c10:	8526                	mv	a0,s1
    80001c12:	00000097          	auipc	ra,0x0
    80001c16:	a4c080e7          	jalr	-1460(ra) # 8000165e <uvmfree>
    return 0;
    80001c1a:	4481                	li	s1,0
    80001c1c:	bf7d                	j	80001bda <proc_pagetable+0x58>

0000000080001c1e <proc_freepagetable>:
{
    80001c1e:	1101                	addi	sp,sp,-32
    80001c20:	ec06                	sd	ra,24(sp)
    80001c22:	e822                	sd	s0,16(sp)
    80001c24:	e426                	sd	s1,8(sp)
    80001c26:	e04a                	sd	s2,0(sp)
    80001c28:	1000                	addi	s0,sp,32
    80001c2a:	84aa                	mv	s1,a0
    80001c2c:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c2e:	4681                	li	a3,0
    80001c30:	4605                	li	a2,1
    80001c32:	040005b7          	lui	a1,0x4000
    80001c36:	15fd                	addi	a1,a1,-1
    80001c38:	05b2                	slli	a1,a1,0xc
    80001c3a:	fffff097          	auipc	ra,0xfffff
    80001c3e:	782080e7          	jalr	1922(ra) # 800013bc <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c42:	4681                	li	a3,0
    80001c44:	4605                	li	a2,1
    80001c46:	020005b7          	lui	a1,0x2000
    80001c4a:	15fd                	addi	a1,a1,-1
    80001c4c:	05b6                	slli	a1,a1,0xd
    80001c4e:	8526                	mv	a0,s1
    80001c50:	fffff097          	auipc	ra,0xfffff
    80001c54:	76c080e7          	jalr	1900(ra) # 800013bc <uvmunmap>
  uvmfree(pagetable, sz);
    80001c58:	85ca                	mv	a1,s2
    80001c5a:	8526                	mv	a0,s1
    80001c5c:	00000097          	auipc	ra,0x0
    80001c60:	a02080e7          	jalr	-1534(ra) # 8000165e <uvmfree>
}
    80001c64:	60e2                	ld	ra,24(sp)
    80001c66:	6442                	ld	s0,16(sp)
    80001c68:	64a2                	ld	s1,8(sp)
    80001c6a:	6902                	ld	s2,0(sp)
    80001c6c:	6105                	addi	sp,sp,32
    80001c6e:	8082                	ret

0000000080001c70 <freeproc>:
{
    80001c70:	1101                	addi	sp,sp,-32
    80001c72:	ec06                	sd	ra,24(sp)
    80001c74:	e822                	sd	s0,16(sp)
    80001c76:	e426                	sd	s1,8(sp)
    80001c78:	1000                	addi	s0,sp,32
    80001c7a:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001c7c:	6d28                	ld	a0,88(a0)
    80001c7e:	c509                	beqz	a0,80001c88 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001c80:	fffff097          	auipc	ra,0xfffff
    80001c84:	da4080e7          	jalr	-604(ra) # 80000a24 <kfree>
  p->trapframe = 0;
    80001c88:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001c8c:	68a8                	ld	a0,80(s1)
    80001c8e:	c511                	beqz	a0,80001c9a <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001c90:	64ac                	ld	a1,72(s1)
    80001c92:	00000097          	auipc	ra,0x0
    80001c96:	f8c080e7          	jalr	-116(ra) # 80001c1e <proc_freepagetable>
  p->pagetable = 0;
    80001c9a:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001c9e:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001ca2:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001ca6:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001caa:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001cae:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001cb2:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001cb6:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001cba:	0004ac23          	sw	zero,24(s1)
}
    80001cbe:	60e2                	ld	ra,24(sp)
    80001cc0:	6442                	ld	s0,16(sp)
    80001cc2:	64a2                	ld	s1,8(sp)
    80001cc4:	6105                	addi	sp,sp,32
    80001cc6:	8082                	ret

0000000080001cc8 <allocproc>:
{
    80001cc8:	1101                	addi	sp,sp,-32
    80001cca:	ec06                	sd	ra,24(sp)
    80001ccc:	e822                	sd	s0,16(sp)
    80001cce:	e426                	sd	s1,8(sp)
    80001cd0:	e04a                	sd	s2,0(sp)
    80001cd2:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cd4:	00010497          	auipc	s1,0x10
    80001cd8:	09448493          	addi	s1,s1,148 # 80011d68 <proc>
    80001cdc:	00016917          	auipc	s2,0x16
    80001ce0:	a8c90913          	addi	s2,s2,-1396 # 80017768 <tickslock>
    acquire(&p->lock);
    80001ce4:	8526                	mv	a0,s1
    80001ce6:	fffff097          	auipc	ra,0xfffff
    80001cea:	f2a080e7          	jalr	-214(ra) # 80000c10 <acquire>
    if(p->state == UNUSED) {
    80001cee:	4c9c                	lw	a5,24(s1)
    80001cf0:	cf81                	beqz	a5,80001d08 <allocproc+0x40>
      release(&p->lock);
    80001cf2:	8526                	mv	a0,s1
    80001cf4:	fffff097          	auipc	ra,0xfffff
    80001cf8:	fd0080e7          	jalr	-48(ra) # 80000cc4 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cfc:	16848493          	addi	s1,s1,360
    80001d00:	ff2492e3          	bne	s1,s2,80001ce4 <allocproc+0x1c>
  return 0;
    80001d04:	4481                	li	s1,0
    80001d06:	a0b9                	j	80001d54 <allocproc+0x8c>
  p->pid = allocpid();
    80001d08:	00000097          	auipc	ra,0x0
    80001d0c:	e34080e7          	jalr	-460(ra) # 80001b3c <allocpid>
    80001d10:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001d12:	fffff097          	auipc	ra,0xfffff
    80001d16:	e0e080e7          	jalr	-498(ra) # 80000b20 <kalloc>
    80001d1a:	892a                	mv	s2,a0
    80001d1c:	eca8                	sd	a0,88(s1)
    80001d1e:	c131                	beqz	a0,80001d62 <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    80001d20:	8526                	mv	a0,s1
    80001d22:	00000097          	auipc	ra,0x0
    80001d26:	e60080e7          	jalr	-416(ra) # 80001b82 <proc_pagetable>
    80001d2a:	892a                	mv	s2,a0
    80001d2c:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001d2e:	c129                	beqz	a0,80001d70 <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    80001d30:	07000613          	li	a2,112
    80001d34:	4581                	li	a1,0
    80001d36:	06048513          	addi	a0,s1,96
    80001d3a:	fffff097          	auipc	ra,0xfffff
    80001d3e:	fd2080e7          	jalr	-46(ra) # 80000d0c <memset>
  p->context.ra = (uint64)forkret;
    80001d42:	00000797          	auipc	a5,0x0
    80001d46:	db478793          	addi	a5,a5,-588 # 80001af6 <forkret>
    80001d4a:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001d4c:	60bc                	ld	a5,64(s1)
    80001d4e:	6705                	lui	a4,0x1
    80001d50:	97ba                	add	a5,a5,a4
    80001d52:	f4bc                	sd	a5,104(s1)
}
    80001d54:	8526                	mv	a0,s1
    80001d56:	60e2                	ld	ra,24(sp)
    80001d58:	6442                	ld	s0,16(sp)
    80001d5a:	64a2                	ld	s1,8(sp)
    80001d5c:	6902                	ld	s2,0(sp)
    80001d5e:	6105                	addi	sp,sp,32
    80001d60:	8082                	ret
    release(&p->lock);
    80001d62:	8526                	mv	a0,s1
    80001d64:	fffff097          	auipc	ra,0xfffff
    80001d68:	f60080e7          	jalr	-160(ra) # 80000cc4 <release>
    return 0;
    80001d6c:	84ca                	mv	s1,s2
    80001d6e:	b7dd                	j	80001d54 <allocproc+0x8c>
    freeproc(p);
    80001d70:	8526                	mv	a0,s1
    80001d72:	00000097          	auipc	ra,0x0
    80001d76:	efe080e7          	jalr	-258(ra) # 80001c70 <freeproc>
    release(&p->lock);
    80001d7a:	8526                	mv	a0,s1
    80001d7c:	fffff097          	auipc	ra,0xfffff
    80001d80:	f48080e7          	jalr	-184(ra) # 80000cc4 <release>
    return 0;
    80001d84:	84ca                	mv	s1,s2
    80001d86:	b7f9                	j	80001d54 <allocproc+0x8c>

0000000080001d88 <userinit>:
{
    80001d88:	1101                	addi	sp,sp,-32
    80001d8a:	ec06                	sd	ra,24(sp)
    80001d8c:	e822                	sd	s0,16(sp)
    80001d8e:	e426                	sd	s1,8(sp)
    80001d90:	1000                	addi	s0,sp,32
  p = allocproc();
    80001d92:	00000097          	auipc	ra,0x0
    80001d96:	f36080e7          	jalr	-202(ra) # 80001cc8 <allocproc>
    80001d9a:	84aa                	mv	s1,a0
  initproc = p;
    80001d9c:	00007797          	auipc	a5,0x7
    80001da0:	26a7be23          	sd	a0,636(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001da4:	03400613          	li	a2,52
    80001da8:	00007597          	auipc	a1,0x7
    80001dac:	a5858593          	addi	a1,a1,-1448 # 80008800 <initcode>
    80001db0:	6928                	ld	a0,80(a0)
    80001db2:	fffff097          	auipc	ra,0xfffff
    80001db6:	6de080e7          	jalr	1758(ra) # 80001490 <uvminit>
  p->sz = PGSIZE;
    80001dba:	6785                	lui	a5,0x1
    80001dbc:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001dbe:	6cb8                	ld	a4,88(s1)
    80001dc0:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001dc4:	6cb8                	ld	a4,88(s1)
    80001dc6:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001dc8:	4641                	li	a2,16
    80001dca:	00006597          	auipc	a1,0x6
    80001dce:	3f658593          	addi	a1,a1,1014 # 800081c0 <digits+0x180>
    80001dd2:	15848513          	addi	a0,s1,344
    80001dd6:	fffff097          	auipc	ra,0xfffff
    80001dda:	08c080e7          	jalr	140(ra) # 80000e62 <safestrcpy>
  p->cwd = namei("/");
    80001dde:	00006517          	auipc	a0,0x6
    80001de2:	3f250513          	addi	a0,a0,1010 # 800081d0 <digits+0x190>
    80001de6:	00002097          	auipc	ra,0x2
    80001dea:	11c080e7          	jalr	284(ra) # 80003f02 <namei>
    80001dee:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001df2:	4789                	li	a5,2
    80001df4:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001df6:	8526                	mv	a0,s1
    80001df8:	fffff097          	auipc	ra,0xfffff
    80001dfc:	ecc080e7          	jalr	-308(ra) # 80000cc4 <release>
}
    80001e00:	60e2                	ld	ra,24(sp)
    80001e02:	6442                	ld	s0,16(sp)
    80001e04:	64a2                	ld	s1,8(sp)
    80001e06:	6105                	addi	sp,sp,32
    80001e08:	8082                	ret

0000000080001e0a <growproc>:
{
    80001e0a:	1101                	addi	sp,sp,-32
    80001e0c:	ec06                	sd	ra,24(sp)
    80001e0e:	e822                	sd	s0,16(sp)
    80001e10:	e426                	sd	s1,8(sp)
    80001e12:	e04a                	sd	s2,0(sp)
    80001e14:	1000                	addi	s0,sp,32
    80001e16:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001e18:	00000097          	auipc	ra,0x0
    80001e1c:	ca6080e7          	jalr	-858(ra) # 80001abe <myproc>
    80001e20:	892a                	mv	s2,a0
  sz = p->sz;
    80001e22:	652c                	ld	a1,72(a0)
    80001e24:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001e28:	00904f63          	bgtz	s1,80001e46 <growproc+0x3c>
  } else if(n < 0){
    80001e2c:	0204cc63          	bltz	s1,80001e64 <growproc+0x5a>
  p->sz = sz;
    80001e30:	1602                	slli	a2,a2,0x20
    80001e32:	9201                	srli	a2,a2,0x20
    80001e34:	04c93423          	sd	a2,72(s2)
  return 0;
    80001e38:	4501                	li	a0,0
}
    80001e3a:	60e2                	ld	ra,24(sp)
    80001e3c:	6442                	ld	s0,16(sp)
    80001e3e:	64a2                	ld	s1,8(sp)
    80001e40:	6902                	ld	s2,0(sp)
    80001e42:	6105                	addi	sp,sp,32
    80001e44:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001e46:	9e25                	addw	a2,a2,s1
    80001e48:	1602                	slli	a2,a2,0x20
    80001e4a:	9201                	srli	a2,a2,0x20
    80001e4c:	1582                	slli	a1,a1,0x20
    80001e4e:	9181                	srli	a1,a1,0x20
    80001e50:	6928                	ld	a0,80(a0)
    80001e52:	fffff097          	auipc	ra,0xfffff
    80001e56:	6f8080e7          	jalr	1784(ra) # 8000154a <uvmalloc>
    80001e5a:	0005061b          	sext.w	a2,a0
    80001e5e:	fa69                	bnez	a2,80001e30 <growproc+0x26>
      return -1;
    80001e60:	557d                	li	a0,-1
    80001e62:	bfe1                	j	80001e3a <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001e64:	9e25                	addw	a2,a2,s1
    80001e66:	1602                	slli	a2,a2,0x20
    80001e68:	9201                	srli	a2,a2,0x20
    80001e6a:	1582                	slli	a1,a1,0x20
    80001e6c:	9181                	srli	a1,a1,0x20
    80001e6e:	6928                	ld	a0,80(a0)
    80001e70:	fffff097          	auipc	ra,0xfffff
    80001e74:	692080e7          	jalr	1682(ra) # 80001502 <uvmdealloc>
    80001e78:	0005061b          	sext.w	a2,a0
    80001e7c:	bf55                	j	80001e30 <growproc+0x26>

0000000080001e7e <fork>:
{
    80001e7e:	7179                	addi	sp,sp,-48
    80001e80:	f406                	sd	ra,40(sp)
    80001e82:	f022                	sd	s0,32(sp)
    80001e84:	ec26                	sd	s1,24(sp)
    80001e86:	e84a                	sd	s2,16(sp)
    80001e88:	e44e                	sd	s3,8(sp)
    80001e8a:	e052                	sd	s4,0(sp)
    80001e8c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001e8e:	00000097          	auipc	ra,0x0
    80001e92:	c30080e7          	jalr	-976(ra) # 80001abe <myproc>
    80001e96:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001e98:	00000097          	auipc	ra,0x0
    80001e9c:	e30080e7          	jalr	-464(ra) # 80001cc8 <allocproc>
    80001ea0:	c175                	beqz	a0,80001f84 <fork+0x106>
    80001ea2:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001ea4:	04893603          	ld	a2,72(s2)
    80001ea8:	692c                	ld	a1,80(a0)
    80001eaa:	05093503          	ld	a0,80(s2)
    80001eae:	fffff097          	auipc	ra,0xfffff
    80001eb2:	7e8080e7          	jalr	2024(ra) # 80001696 <uvmcopy>
    80001eb6:	04054863          	bltz	a0,80001f06 <fork+0x88>
  np->sz = p->sz;
    80001eba:	04893783          	ld	a5,72(s2)
    80001ebe:	04f9b423          	sd	a5,72(s3) # 4000048 <_entry-0x7bffffb8>
  np->parent = p;
    80001ec2:	0329b023          	sd	s2,32(s3)
  *(np->trapframe) = *(p->trapframe);
    80001ec6:	05893683          	ld	a3,88(s2)
    80001eca:	87b6                	mv	a5,a3
    80001ecc:	0589b703          	ld	a4,88(s3)
    80001ed0:	12068693          	addi	a3,a3,288
    80001ed4:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001ed8:	6788                	ld	a0,8(a5)
    80001eda:	6b8c                	ld	a1,16(a5)
    80001edc:	6f90                	ld	a2,24(a5)
    80001ede:	01073023          	sd	a6,0(a4)
    80001ee2:	e708                	sd	a0,8(a4)
    80001ee4:	eb0c                	sd	a1,16(a4)
    80001ee6:	ef10                	sd	a2,24(a4)
    80001ee8:	02078793          	addi	a5,a5,32
    80001eec:	02070713          	addi	a4,a4,32
    80001ef0:	fed792e3          	bne	a5,a3,80001ed4 <fork+0x56>
  np->trapframe->a0 = 0;
    80001ef4:	0589b783          	ld	a5,88(s3)
    80001ef8:	0607b823          	sd	zero,112(a5)
    80001efc:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001f00:	15000a13          	li	s4,336
    80001f04:	a03d                	j	80001f32 <fork+0xb4>
    freeproc(np);
    80001f06:	854e                	mv	a0,s3
    80001f08:	00000097          	auipc	ra,0x0
    80001f0c:	d68080e7          	jalr	-664(ra) # 80001c70 <freeproc>
    release(&np->lock);
    80001f10:	854e                	mv	a0,s3
    80001f12:	fffff097          	auipc	ra,0xfffff
    80001f16:	db2080e7          	jalr	-590(ra) # 80000cc4 <release>
    return -1;
    80001f1a:	54fd                	li	s1,-1
    80001f1c:	a899                	j	80001f72 <fork+0xf4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001f1e:	00002097          	auipc	ra,0x2
    80001f22:	670080e7          	jalr	1648(ra) # 8000458e <filedup>
    80001f26:	009987b3          	add	a5,s3,s1
    80001f2a:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001f2c:	04a1                	addi	s1,s1,8
    80001f2e:	01448763          	beq	s1,s4,80001f3c <fork+0xbe>
    if(p->ofile[i])
    80001f32:	009907b3          	add	a5,s2,s1
    80001f36:	6388                	ld	a0,0(a5)
    80001f38:	f17d                	bnez	a0,80001f1e <fork+0xa0>
    80001f3a:	bfcd                	j	80001f2c <fork+0xae>
  np->cwd = idup(p->cwd);
    80001f3c:	15093503          	ld	a0,336(s2)
    80001f40:	00001097          	auipc	ra,0x1
    80001f44:	7d0080e7          	jalr	2000(ra) # 80003710 <idup>
    80001f48:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001f4c:	4641                	li	a2,16
    80001f4e:	15890593          	addi	a1,s2,344
    80001f52:	15898513          	addi	a0,s3,344
    80001f56:	fffff097          	auipc	ra,0xfffff
    80001f5a:	f0c080e7          	jalr	-244(ra) # 80000e62 <safestrcpy>
  pid = np->pid;
    80001f5e:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    80001f62:	4789                	li	a5,2
    80001f64:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001f68:	854e                	mv	a0,s3
    80001f6a:	fffff097          	auipc	ra,0xfffff
    80001f6e:	d5a080e7          	jalr	-678(ra) # 80000cc4 <release>
}
    80001f72:	8526                	mv	a0,s1
    80001f74:	70a2                	ld	ra,40(sp)
    80001f76:	7402                	ld	s0,32(sp)
    80001f78:	64e2                	ld	s1,24(sp)
    80001f7a:	6942                	ld	s2,16(sp)
    80001f7c:	69a2                	ld	s3,8(sp)
    80001f7e:	6a02                	ld	s4,0(sp)
    80001f80:	6145                	addi	sp,sp,48
    80001f82:	8082                	ret
    return -1;
    80001f84:	54fd                	li	s1,-1
    80001f86:	b7f5                	j	80001f72 <fork+0xf4>

0000000080001f88 <reparent>:
{
    80001f88:	7179                	addi	sp,sp,-48
    80001f8a:	f406                	sd	ra,40(sp)
    80001f8c:	f022                	sd	s0,32(sp)
    80001f8e:	ec26                	sd	s1,24(sp)
    80001f90:	e84a                	sd	s2,16(sp)
    80001f92:	e44e                	sd	s3,8(sp)
    80001f94:	e052                	sd	s4,0(sp)
    80001f96:	1800                	addi	s0,sp,48
    80001f98:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001f9a:	00010497          	auipc	s1,0x10
    80001f9e:	dce48493          	addi	s1,s1,-562 # 80011d68 <proc>
      pp->parent = initproc;
    80001fa2:	00007a17          	auipc	s4,0x7
    80001fa6:	076a0a13          	addi	s4,s4,118 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001faa:	00015997          	auipc	s3,0x15
    80001fae:	7be98993          	addi	s3,s3,1982 # 80017768 <tickslock>
    80001fb2:	a029                	j	80001fbc <reparent+0x34>
    80001fb4:	16848493          	addi	s1,s1,360
    80001fb8:	03348363          	beq	s1,s3,80001fde <reparent+0x56>
    if(pp->parent == p){
    80001fbc:	709c                	ld	a5,32(s1)
    80001fbe:	ff279be3          	bne	a5,s2,80001fb4 <reparent+0x2c>
      acquire(&pp->lock);
    80001fc2:	8526                	mv	a0,s1
    80001fc4:	fffff097          	auipc	ra,0xfffff
    80001fc8:	c4c080e7          	jalr	-948(ra) # 80000c10 <acquire>
      pp->parent = initproc;
    80001fcc:	000a3783          	ld	a5,0(s4)
    80001fd0:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80001fd2:	8526                	mv	a0,s1
    80001fd4:	fffff097          	auipc	ra,0xfffff
    80001fd8:	cf0080e7          	jalr	-784(ra) # 80000cc4 <release>
    80001fdc:	bfe1                	j	80001fb4 <reparent+0x2c>
}
    80001fde:	70a2                	ld	ra,40(sp)
    80001fe0:	7402                	ld	s0,32(sp)
    80001fe2:	64e2                	ld	s1,24(sp)
    80001fe4:	6942                	ld	s2,16(sp)
    80001fe6:	69a2                	ld	s3,8(sp)
    80001fe8:	6a02                	ld	s4,0(sp)
    80001fea:	6145                	addi	sp,sp,48
    80001fec:	8082                	ret

0000000080001fee <scheduler>:
{
    80001fee:	711d                	addi	sp,sp,-96
    80001ff0:	ec86                	sd	ra,88(sp)
    80001ff2:	e8a2                	sd	s0,80(sp)
    80001ff4:	e4a6                	sd	s1,72(sp)
    80001ff6:	e0ca                	sd	s2,64(sp)
    80001ff8:	fc4e                	sd	s3,56(sp)
    80001ffa:	f852                	sd	s4,48(sp)
    80001ffc:	f456                	sd	s5,40(sp)
    80001ffe:	f05a                	sd	s6,32(sp)
    80002000:	ec5e                	sd	s7,24(sp)
    80002002:	e862                	sd	s8,16(sp)
    80002004:	e466                	sd	s9,8(sp)
    80002006:	1080                	addi	s0,sp,96
    80002008:	8792                	mv	a5,tp
  int id = r_tp();
    8000200a:	2781                	sext.w	a5,a5
  c->proc = 0;
    8000200c:	00779c13          	slli	s8,a5,0x7
    80002010:	00010717          	auipc	a4,0x10
    80002014:	94070713          	addi	a4,a4,-1728 # 80011950 <pid_lock>
    80002018:	9762                	add	a4,a4,s8
    8000201a:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    8000201e:	00010717          	auipc	a4,0x10
    80002022:	95270713          	addi	a4,a4,-1710 # 80011970 <cpus+0x8>
    80002026:	9c3a                	add	s8,s8,a4
      if(p->state == RUNNABLE) {
    80002028:	4a89                	li	s5,2
        c->proc = p;
    8000202a:	079e                	slli	a5,a5,0x7
    8000202c:	00010b17          	auipc	s6,0x10
    80002030:	924b0b13          	addi	s6,s6,-1756 # 80011950 <pid_lock>
    80002034:	9b3e                	add	s6,s6,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80002036:	00015a17          	auipc	s4,0x15
    8000203a:	732a0a13          	addi	s4,s4,1842 # 80017768 <tickslock>
    int nproc = 0;
    8000203e:	4c81                	li	s9,0
    80002040:	a8a1                	j	80002098 <scheduler+0xaa>
        p->state = RUNNING;
    80002042:	0174ac23          	sw	s7,24(s1)
        c->proc = p;
    80002046:	009b3c23          	sd	s1,24(s6)
        swtch(&c->context, &p->context);
    8000204a:	06048593          	addi	a1,s1,96
    8000204e:	8562                	mv	a0,s8
    80002050:	00000097          	auipc	ra,0x0
    80002054:	63a080e7          	jalr	1594(ra) # 8000268a <swtch>
        c->proc = 0;
    80002058:	000b3c23          	sd	zero,24(s6)
      release(&p->lock);
    8000205c:	8526                	mv	a0,s1
    8000205e:	fffff097          	auipc	ra,0xfffff
    80002062:	c66080e7          	jalr	-922(ra) # 80000cc4 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002066:	16848493          	addi	s1,s1,360
    8000206a:	01448d63          	beq	s1,s4,80002084 <scheduler+0x96>
      acquire(&p->lock);
    8000206e:	8526                	mv	a0,s1
    80002070:	fffff097          	auipc	ra,0xfffff
    80002074:	ba0080e7          	jalr	-1120(ra) # 80000c10 <acquire>
      if(p->state != UNUSED) {
    80002078:	4c9c                	lw	a5,24(s1)
    8000207a:	d3ed                	beqz	a5,8000205c <scheduler+0x6e>
        nproc++;
    8000207c:	2985                	addiw	s3,s3,1
      if(p->state == RUNNABLE) {
    8000207e:	fd579fe3          	bne	a5,s5,8000205c <scheduler+0x6e>
    80002082:	b7c1                	j	80002042 <scheduler+0x54>
    if(nproc <= 2) {   // only init and sh exist
    80002084:	013aca63          	blt	s5,s3,80002098 <scheduler+0xaa>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002088:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000208c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002090:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    80002094:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002098:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000209c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800020a0:	10079073          	csrw	sstatus,a5
    int nproc = 0;
    800020a4:	89e6                	mv	s3,s9
    for(p = proc; p < &proc[NPROC]; p++) {
    800020a6:	00010497          	auipc	s1,0x10
    800020aa:	cc248493          	addi	s1,s1,-830 # 80011d68 <proc>
        p->state = RUNNING;
    800020ae:	4b8d                	li	s7,3
    800020b0:	bf7d                	j	8000206e <scheduler+0x80>

00000000800020b2 <sched>:
{
    800020b2:	7179                	addi	sp,sp,-48
    800020b4:	f406                	sd	ra,40(sp)
    800020b6:	f022                	sd	s0,32(sp)
    800020b8:	ec26                	sd	s1,24(sp)
    800020ba:	e84a                	sd	s2,16(sp)
    800020bc:	e44e                	sd	s3,8(sp)
    800020be:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800020c0:	00000097          	auipc	ra,0x0
    800020c4:	9fe080e7          	jalr	-1538(ra) # 80001abe <myproc>
    800020c8:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800020ca:	fffff097          	auipc	ra,0xfffff
    800020ce:	acc080e7          	jalr	-1332(ra) # 80000b96 <holding>
    800020d2:	c93d                	beqz	a0,80002148 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020d4:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800020d6:	2781                	sext.w	a5,a5
    800020d8:	079e                	slli	a5,a5,0x7
    800020da:	00010717          	auipc	a4,0x10
    800020de:	87670713          	addi	a4,a4,-1930 # 80011950 <pid_lock>
    800020e2:	97ba                	add	a5,a5,a4
    800020e4:	0907a703          	lw	a4,144(a5)
    800020e8:	4785                	li	a5,1
    800020ea:	06f71763          	bne	a4,a5,80002158 <sched+0xa6>
  if(p->state == RUNNING)
    800020ee:	4c98                	lw	a4,24(s1)
    800020f0:	478d                	li	a5,3
    800020f2:	06f70b63          	beq	a4,a5,80002168 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020f6:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800020fa:	8b89                	andi	a5,a5,2
  if(intr_get())
    800020fc:	efb5                	bnez	a5,80002178 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020fe:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002100:	00010917          	auipc	s2,0x10
    80002104:	85090913          	addi	s2,s2,-1968 # 80011950 <pid_lock>
    80002108:	2781                	sext.w	a5,a5
    8000210a:	079e                	slli	a5,a5,0x7
    8000210c:	97ca                	add	a5,a5,s2
    8000210e:	0947a983          	lw	s3,148(a5)
    80002112:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002114:	2781                	sext.w	a5,a5
    80002116:	079e                	slli	a5,a5,0x7
    80002118:	00010597          	auipc	a1,0x10
    8000211c:	85858593          	addi	a1,a1,-1960 # 80011970 <cpus+0x8>
    80002120:	95be                	add	a1,a1,a5
    80002122:	06048513          	addi	a0,s1,96
    80002126:	00000097          	auipc	ra,0x0
    8000212a:	564080e7          	jalr	1380(ra) # 8000268a <swtch>
    8000212e:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002130:	2781                	sext.w	a5,a5
    80002132:	079e                	slli	a5,a5,0x7
    80002134:	97ca                	add	a5,a5,s2
    80002136:	0937aa23          	sw	s3,148(a5)
}
    8000213a:	70a2                	ld	ra,40(sp)
    8000213c:	7402                	ld	s0,32(sp)
    8000213e:	64e2                	ld	s1,24(sp)
    80002140:	6942                	ld	s2,16(sp)
    80002142:	69a2                	ld	s3,8(sp)
    80002144:	6145                	addi	sp,sp,48
    80002146:	8082                	ret
    panic("sched p->lock");
    80002148:	00006517          	auipc	a0,0x6
    8000214c:	09050513          	addi	a0,a0,144 # 800081d8 <digits+0x198>
    80002150:	ffffe097          	auipc	ra,0xffffe
    80002154:	3f8080e7          	jalr	1016(ra) # 80000548 <panic>
    panic("sched locks");
    80002158:	00006517          	auipc	a0,0x6
    8000215c:	09050513          	addi	a0,a0,144 # 800081e8 <digits+0x1a8>
    80002160:	ffffe097          	auipc	ra,0xffffe
    80002164:	3e8080e7          	jalr	1000(ra) # 80000548 <panic>
    panic("sched running");
    80002168:	00006517          	auipc	a0,0x6
    8000216c:	09050513          	addi	a0,a0,144 # 800081f8 <digits+0x1b8>
    80002170:	ffffe097          	auipc	ra,0xffffe
    80002174:	3d8080e7          	jalr	984(ra) # 80000548 <panic>
    panic("sched interruptible");
    80002178:	00006517          	auipc	a0,0x6
    8000217c:	09050513          	addi	a0,a0,144 # 80008208 <digits+0x1c8>
    80002180:	ffffe097          	auipc	ra,0xffffe
    80002184:	3c8080e7          	jalr	968(ra) # 80000548 <panic>

0000000080002188 <exit>:
{
    80002188:	7179                	addi	sp,sp,-48
    8000218a:	f406                	sd	ra,40(sp)
    8000218c:	f022                	sd	s0,32(sp)
    8000218e:	ec26                	sd	s1,24(sp)
    80002190:	e84a                	sd	s2,16(sp)
    80002192:	e44e                	sd	s3,8(sp)
    80002194:	e052                	sd	s4,0(sp)
    80002196:	1800                	addi	s0,sp,48
    80002198:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000219a:	00000097          	auipc	ra,0x0
    8000219e:	924080e7          	jalr	-1756(ra) # 80001abe <myproc>
    800021a2:	89aa                	mv	s3,a0
  if(p == initproc)
    800021a4:	00007797          	auipc	a5,0x7
    800021a8:	e747b783          	ld	a5,-396(a5) # 80009018 <initproc>
    800021ac:	0d050493          	addi	s1,a0,208
    800021b0:	15050913          	addi	s2,a0,336
    800021b4:	02a79363          	bne	a5,a0,800021da <exit+0x52>
    panic("init exiting");
    800021b8:	00006517          	auipc	a0,0x6
    800021bc:	06850513          	addi	a0,a0,104 # 80008220 <digits+0x1e0>
    800021c0:	ffffe097          	auipc	ra,0xffffe
    800021c4:	388080e7          	jalr	904(ra) # 80000548 <panic>
      fileclose(f);
    800021c8:	00002097          	auipc	ra,0x2
    800021cc:	418080e7          	jalr	1048(ra) # 800045e0 <fileclose>
      p->ofile[fd] = 0;
    800021d0:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800021d4:	04a1                	addi	s1,s1,8
    800021d6:	01248563          	beq	s1,s2,800021e0 <exit+0x58>
    if(p->ofile[fd]){
    800021da:	6088                	ld	a0,0(s1)
    800021dc:	f575                	bnez	a0,800021c8 <exit+0x40>
    800021de:	bfdd                	j	800021d4 <exit+0x4c>
  begin_op();
    800021e0:	00002097          	auipc	ra,0x2
    800021e4:	f2e080e7          	jalr	-210(ra) # 8000410e <begin_op>
  iput(p->cwd);
    800021e8:	1509b503          	ld	a0,336(s3)
    800021ec:	00001097          	auipc	ra,0x1
    800021f0:	71c080e7          	jalr	1820(ra) # 80003908 <iput>
  end_op();
    800021f4:	00002097          	auipc	ra,0x2
    800021f8:	f9a080e7          	jalr	-102(ra) # 8000418e <end_op>
  p->cwd = 0;
    800021fc:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    80002200:	00007497          	auipc	s1,0x7
    80002204:	e1848493          	addi	s1,s1,-488 # 80009018 <initproc>
    80002208:	6088                	ld	a0,0(s1)
    8000220a:	fffff097          	auipc	ra,0xfffff
    8000220e:	a06080e7          	jalr	-1530(ra) # 80000c10 <acquire>
  wakeup1(initproc);
    80002212:	6088                	ld	a0,0(s1)
    80002214:	fffff097          	auipc	ra,0xfffff
    80002218:	76a080e7          	jalr	1898(ra) # 8000197e <wakeup1>
  release(&initproc->lock);
    8000221c:	6088                	ld	a0,0(s1)
    8000221e:	fffff097          	auipc	ra,0xfffff
    80002222:	aa6080e7          	jalr	-1370(ra) # 80000cc4 <release>
  acquire(&p->lock);
    80002226:	854e                	mv	a0,s3
    80002228:	fffff097          	auipc	ra,0xfffff
    8000222c:	9e8080e7          	jalr	-1560(ra) # 80000c10 <acquire>
  struct proc *original_parent = p->parent;
    80002230:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    80002234:	854e                	mv	a0,s3
    80002236:	fffff097          	auipc	ra,0xfffff
    8000223a:	a8e080e7          	jalr	-1394(ra) # 80000cc4 <release>
  acquire(&original_parent->lock);
    8000223e:	8526                	mv	a0,s1
    80002240:	fffff097          	auipc	ra,0xfffff
    80002244:	9d0080e7          	jalr	-1584(ra) # 80000c10 <acquire>
  acquire(&p->lock);
    80002248:	854e                	mv	a0,s3
    8000224a:	fffff097          	auipc	ra,0xfffff
    8000224e:	9c6080e7          	jalr	-1594(ra) # 80000c10 <acquire>
  reparent(p);
    80002252:	854e                	mv	a0,s3
    80002254:	00000097          	auipc	ra,0x0
    80002258:	d34080e7          	jalr	-716(ra) # 80001f88 <reparent>
  wakeup1(original_parent);
    8000225c:	8526                	mv	a0,s1
    8000225e:	fffff097          	auipc	ra,0xfffff
    80002262:	720080e7          	jalr	1824(ra) # 8000197e <wakeup1>
  p->xstate = status;
    80002266:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    8000226a:	4791                	li	a5,4
    8000226c:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    80002270:	8526                	mv	a0,s1
    80002272:	fffff097          	auipc	ra,0xfffff
    80002276:	a52080e7          	jalr	-1454(ra) # 80000cc4 <release>
  sched();
    8000227a:	00000097          	auipc	ra,0x0
    8000227e:	e38080e7          	jalr	-456(ra) # 800020b2 <sched>
  panic("zombie exit");
    80002282:	00006517          	auipc	a0,0x6
    80002286:	fae50513          	addi	a0,a0,-82 # 80008230 <digits+0x1f0>
    8000228a:	ffffe097          	auipc	ra,0xffffe
    8000228e:	2be080e7          	jalr	702(ra) # 80000548 <panic>

0000000080002292 <yield>:
{
    80002292:	1101                	addi	sp,sp,-32
    80002294:	ec06                	sd	ra,24(sp)
    80002296:	e822                	sd	s0,16(sp)
    80002298:	e426                	sd	s1,8(sp)
    8000229a:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000229c:	00000097          	auipc	ra,0x0
    800022a0:	822080e7          	jalr	-2014(ra) # 80001abe <myproc>
    800022a4:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800022a6:	fffff097          	auipc	ra,0xfffff
    800022aa:	96a080e7          	jalr	-1686(ra) # 80000c10 <acquire>
  p->state = RUNNABLE;
    800022ae:	4789                	li	a5,2
    800022b0:	cc9c                	sw	a5,24(s1)
  sched();
    800022b2:	00000097          	auipc	ra,0x0
    800022b6:	e00080e7          	jalr	-512(ra) # 800020b2 <sched>
  release(&p->lock);
    800022ba:	8526                	mv	a0,s1
    800022bc:	fffff097          	auipc	ra,0xfffff
    800022c0:	a08080e7          	jalr	-1528(ra) # 80000cc4 <release>
}
    800022c4:	60e2                	ld	ra,24(sp)
    800022c6:	6442                	ld	s0,16(sp)
    800022c8:	64a2                	ld	s1,8(sp)
    800022ca:	6105                	addi	sp,sp,32
    800022cc:	8082                	ret

00000000800022ce <sleep>:
{
    800022ce:	7179                	addi	sp,sp,-48
    800022d0:	f406                	sd	ra,40(sp)
    800022d2:	f022                	sd	s0,32(sp)
    800022d4:	ec26                	sd	s1,24(sp)
    800022d6:	e84a                	sd	s2,16(sp)
    800022d8:	e44e                	sd	s3,8(sp)
    800022da:	1800                	addi	s0,sp,48
    800022dc:	89aa                	mv	s3,a0
    800022de:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800022e0:	fffff097          	auipc	ra,0xfffff
    800022e4:	7de080e7          	jalr	2014(ra) # 80001abe <myproc>
    800022e8:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    800022ea:	05250663          	beq	a0,s2,80002336 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    800022ee:	fffff097          	auipc	ra,0xfffff
    800022f2:	922080e7          	jalr	-1758(ra) # 80000c10 <acquire>
    release(lk);
    800022f6:	854a                	mv	a0,s2
    800022f8:	fffff097          	auipc	ra,0xfffff
    800022fc:	9cc080e7          	jalr	-1588(ra) # 80000cc4 <release>
  p->chan = chan;
    80002300:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    80002304:	4785                	li	a5,1
    80002306:	cc9c                	sw	a5,24(s1)
  sched();
    80002308:	00000097          	auipc	ra,0x0
    8000230c:	daa080e7          	jalr	-598(ra) # 800020b2 <sched>
  p->chan = 0;
    80002310:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    80002314:	8526                	mv	a0,s1
    80002316:	fffff097          	auipc	ra,0xfffff
    8000231a:	9ae080e7          	jalr	-1618(ra) # 80000cc4 <release>
    acquire(lk);
    8000231e:	854a                	mv	a0,s2
    80002320:	fffff097          	auipc	ra,0xfffff
    80002324:	8f0080e7          	jalr	-1808(ra) # 80000c10 <acquire>
}
    80002328:	70a2                	ld	ra,40(sp)
    8000232a:	7402                	ld	s0,32(sp)
    8000232c:	64e2                	ld	s1,24(sp)
    8000232e:	6942                	ld	s2,16(sp)
    80002330:	69a2                	ld	s3,8(sp)
    80002332:	6145                	addi	sp,sp,48
    80002334:	8082                	ret
  p->chan = chan;
    80002336:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    8000233a:	4785                	li	a5,1
    8000233c:	cd1c                	sw	a5,24(a0)
  sched();
    8000233e:	00000097          	auipc	ra,0x0
    80002342:	d74080e7          	jalr	-652(ra) # 800020b2 <sched>
  p->chan = 0;
    80002346:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    8000234a:	bff9                	j	80002328 <sleep+0x5a>

000000008000234c <wait>:
{
    8000234c:	715d                	addi	sp,sp,-80
    8000234e:	e486                	sd	ra,72(sp)
    80002350:	e0a2                	sd	s0,64(sp)
    80002352:	fc26                	sd	s1,56(sp)
    80002354:	f84a                	sd	s2,48(sp)
    80002356:	f44e                	sd	s3,40(sp)
    80002358:	f052                	sd	s4,32(sp)
    8000235a:	ec56                	sd	s5,24(sp)
    8000235c:	e85a                	sd	s6,16(sp)
    8000235e:	e45e                	sd	s7,8(sp)
    80002360:	e062                	sd	s8,0(sp)
    80002362:	0880                	addi	s0,sp,80
    80002364:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002366:	fffff097          	auipc	ra,0xfffff
    8000236a:	758080e7          	jalr	1880(ra) # 80001abe <myproc>
    8000236e:	892a                	mv	s2,a0
  acquire(&p->lock);
    80002370:	8c2a                	mv	s8,a0
    80002372:	fffff097          	auipc	ra,0xfffff
    80002376:	89e080e7          	jalr	-1890(ra) # 80000c10 <acquire>
    havekids = 0;
    8000237a:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    8000237c:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    8000237e:	00015997          	auipc	s3,0x15
    80002382:	3ea98993          	addi	s3,s3,1002 # 80017768 <tickslock>
        havekids = 1;
    80002386:	4a85                	li	s5,1
    havekids = 0;
    80002388:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    8000238a:	00010497          	auipc	s1,0x10
    8000238e:	9de48493          	addi	s1,s1,-1570 # 80011d68 <proc>
    80002392:	a08d                	j	800023f4 <wait+0xa8>
          pid = np->pid;
    80002394:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002398:	000b0e63          	beqz	s6,800023b4 <wait+0x68>
    8000239c:	4691                	li	a3,4
    8000239e:	03448613          	addi	a2,s1,52
    800023a2:	85da                	mv	a1,s6
    800023a4:	05093503          	ld	a0,80(s2)
    800023a8:	fffff097          	auipc	ra,0xfffff
    800023ac:	3d6080e7          	jalr	982(ra) # 8000177e <copyout>
    800023b0:	02054263          	bltz	a0,800023d4 <wait+0x88>
          freeproc(np);
    800023b4:	8526                	mv	a0,s1
    800023b6:	00000097          	auipc	ra,0x0
    800023ba:	8ba080e7          	jalr	-1862(ra) # 80001c70 <freeproc>
          release(&np->lock);
    800023be:	8526                	mv	a0,s1
    800023c0:	fffff097          	auipc	ra,0xfffff
    800023c4:	904080e7          	jalr	-1788(ra) # 80000cc4 <release>
          release(&p->lock);
    800023c8:	854a                	mv	a0,s2
    800023ca:	fffff097          	auipc	ra,0xfffff
    800023ce:	8fa080e7          	jalr	-1798(ra) # 80000cc4 <release>
          return pid;
    800023d2:	a8a9                	j	8000242c <wait+0xe0>
            release(&np->lock);
    800023d4:	8526                	mv	a0,s1
    800023d6:	fffff097          	auipc	ra,0xfffff
    800023da:	8ee080e7          	jalr	-1810(ra) # 80000cc4 <release>
            release(&p->lock);
    800023de:	854a                	mv	a0,s2
    800023e0:	fffff097          	auipc	ra,0xfffff
    800023e4:	8e4080e7          	jalr	-1820(ra) # 80000cc4 <release>
            return -1;
    800023e8:	59fd                	li	s3,-1
    800023ea:	a089                	j	8000242c <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    800023ec:	16848493          	addi	s1,s1,360
    800023f0:	03348463          	beq	s1,s3,80002418 <wait+0xcc>
      if(np->parent == p){
    800023f4:	709c                	ld	a5,32(s1)
    800023f6:	ff279be3          	bne	a5,s2,800023ec <wait+0xa0>
        acquire(&np->lock);
    800023fa:	8526                	mv	a0,s1
    800023fc:	fffff097          	auipc	ra,0xfffff
    80002400:	814080e7          	jalr	-2028(ra) # 80000c10 <acquire>
        if(np->state == ZOMBIE){
    80002404:	4c9c                	lw	a5,24(s1)
    80002406:	f94787e3          	beq	a5,s4,80002394 <wait+0x48>
        release(&np->lock);
    8000240a:	8526                	mv	a0,s1
    8000240c:	fffff097          	auipc	ra,0xfffff
    80002410:	8b8080e7          	jalr	-1864(ra) # 80000cc4 <release>
        havekids = 1;
    80002414:	8756                	mv	a4,s5
    80002416:	bfd9                	j	800023ec <wait+0xa0>
    if(!havekids || p->killed){
    80002418:	c701                	beqz	a4,80002420 <wait+0xd4>
    8000241a:	03092783          	lw	a5,48(s2)
    8000241e:	c785                	beqz	a5,80002446 <wait+0xfa>
      release(&p->lock);
    80002420:	854a                	mv	a0,s2
    80002422:	fffff097          	auipc	ra,0xfffff
    80002426:	8a2080e7          	jalr	-1886(ra) # 80000cc4 <release>
      return -1;
    8000242a:	59fd                	li	s3,-1
}
    8000242c:	854e                	mv	a0,s3
    8000242e:	60a6                	ld	ra,72(sp)
    80002430:	6406                	ld	s0,64(sp)
    80002432:	74e2                	ld	s1,56(sp)
    80002434:	7942                	ld	s2,48(sp)
    80002436:	79a2                	ld	s3,40(sp)
    80002438:	7a02                	ld	s4,32(sp)
    8000243a:	6ae2                	ld	s5,24(sp)
    8000243c:	6b42                	ld	s6,16(sp)
    8000243e:	6ba2                	ld	s7,8(sp)
    80002440:	6c02                	ld	s8,0(sp)
    80002442:	6161                	addi	sp,sp,80
    80002444:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    80002446:	85e2                	mv	a1,s8
    80002448:	854a                	mv	a0,s2
    8000244a:	00000097          	auipc	ra,0x0
    8000244e:	e84080e7          	jalr	-380(ra) # 800022ce <sleep>
    havekids = 0;
    80002452:	bf1d                	j	80002388 <wait+0x3c>

0000000080002454 <wakeup>:
{
    80002454:	7139                	addi	sp,sp,-64
    80002456:	fc06                	sd	ra,56(sp)
    80002458:	f822                	sd	s0,48(sp)
    8000245a:	f426                	sd	s1,40(sp)
    8000245c:	f04a                	sd	s2,32(sp)
    8000245e:	ec4e                	sd	s3,24(sp)
    80002460:	e852                	sd	s4,16(sp)
    80002462:	e456                	sd	s5,8(sp)
    80002464:	0080                	addi	s0,sp,64
    80002466:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    80002468:	00010497          	auipc	s1,0x10
    8000246c:	90048493          	addi	s1,s1,-1792 # 80011d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    80002470:	4985                	li	s3,1
      p->state = RUNNABLE;
    80002472:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    80002474:	00015917          	auipc	s2,0x15
    80002478:	2f490913          	addi	s2,s2,756 # 80017768 <tickslock>
    8000247c:	a821                	j	80002494 <wakeup+0x40>
      p->state = RUNNABLE;
    8000247e:	0154ac23          	sw	s5,24(s1)
    release(&p->lock);
    80002482:	8526                	mv	a0,s1
    80002484:	fffff097          	auipc	ra,0xfffff
    80002488:	840080e7          	jalr	-1984(ra) # 80000cc4 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000248c:	16848493          	addi	s1,s1,360
    80002490:	01248e63          	beq	s1,s2,800024ac <wakeup+0x58>
    acquire(&p->lock);
    80002494:	8526                	mv	a0,s1
    80002496:	ffffe097          	auipc	ra,0xffffe
    8000249a:	77a080e7          	jalr	1914(ra) # 80000c10 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    8000249e:	4c9c                	lw	a5,24(s1)
    800024a0:	ff3791e3          	bne	a5,s3,80002482 <wakeup+0x2e>
    800024a4:	749c                	ld	a5,40(s1)
    800024a6:	fd479ee3          	bne	a5,s4,80002482 <wakeup+0x2e>
    800024aa:	bfd1                	j	8000247e <wakeup+0x2a>
}
    800024ac:	70e2                	ld	ra,56(sp)
    800024ae:	7442                	ld	s0,48(sp)
    800024b0:	74a2                	ld	s1,40(sp)
    800024b2:	7902                	ld	s2,32(sp)
    800024b4:	69e2                	ld	s3,24(sp)
    800024b6:	6a42                	ld	s4,16(sp)
    800024b8:	6aa2                	ld	s5,8(sp)
    800024ba:	6121                	addi	sp,sp,64
    800024bc:	8082                	ret

00000000800024be <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800024be:	7179                	addi	sp,sp,-48
    800024c0:	f406                	sd	ra,40(sp)
    800024c2:	f022                	sd	s0,32(sp)
    800024c4:	ec26                	sd	s1,24(sp)
    800024c6:	e84a                	sd	s2,16(sp)
    800024c8:	e44e                	sd	s3,8(sp)
    800024ca:	1800                	addi	s0,sp,48
    800024cc:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800024ce:	00010497          	auipc	s1,0x10
    800024d2:	89a48493          	addi	s1,s1,-1894 # 80011d68 <proc>
    800024d6:	00015997          	auipc	s3,0x15
    800024da:	29298993          	addi	s3,s3,658 # 80017768 <tickslock>
    acquire(&p->lock);
    800024de:	8526                	mv	a0,s1
    800024e0:	ffffe097          	auipc	ra,0xffffe
    800024e4:	730080e7          	jalr	1840(ra) # 80000c10 <acquire>
    if(p->pid == pid){
    800024e8:	5c9c                	lw	a5,56(s1)
    800024ea:	01278d63          	beq	a5,s2,80002504 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800024ee:	8526                	mv	a0,s1
    800024f0:	ffffe097          	auipc	ra,0xffffe
    800024f4:	7d4080e7          	jalr	2004(ra) # 80000cc4 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800024f8:	16848493          	addi	s1,s1,360
    800024fc:	ff3491e3          	bne	s1,s3,800024de <kill+0x20>
  }
  return -1;
    80002500:	557d                	li	a0,-1
    80002502:	a829                	j	8000251c <kill+0x5e>
      p->killed = 1;
    80002504:	4785                	li	a5,1
    80002506:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    80002508:	4c98                	lw	a4,24(s1)
    8000250a:	4785                	li	a5,1
    8000250c:	00f70f63          	beq	a4,a5,8000252a <kill+0x6c>
      release(&p->lock);
    80002510:	8526                	mv	a0,s1
    80002512:	ffffe097          	auipc	ra,0xffffe
    80002516:	7b2080e7          	jalr	1970(ra) # 80000cc4 <release>
      return 0;
    8000251a:	4501                	li	a0,0
}
    8000251c:	70a2                	ld	ra,40(sp)
    8000251e:	7402                	ld	s0,32(sp)
    80002520:	64e2                	ld	s1,24(sp)
    80002522:	6942                	ld	s2,16(sp)
    80002524:	69a2                	ld	s3,8(sp)
    80002526:	6145                	addi	sp,sp,48
    80002528:	8082                	ret
        p->state = RUNNABLE;
    8000252a:	4789                	li	a5,2
    8000252c:	cc9c                	sw	a5,24(s1)
    8000252e:	b7cd                	j	80002510 <kill+0x52>

0000000080002530 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002530:	7179                	addi	sp,sp,-48
    80002532:	f406                	sd	ra,40(sp)
    80002534:	f022                	sd	s0,32(sp)
    80002536:	ec26                	sd	s1,24(sp)
    80002538:	e84a                	sd	s2,16(sp)
    8000253a:	e44e                	sd	s3,8(sp)
    8000253c:	e052                	sd	s4,0(sp)
    8000253e:	1800                	addi	s0,sp,48
    80002540:	84aa                	mv	s1,a0
    80002542:	892e                	mv	s2,a1
    80002544:	89b2                	mv	s3,a2
    80002546:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002548:	fffff097          	auipc	ra,0xfffff
    8000254c:	576080e7          	jalr	1398(ra) # 80001abe <myproc>
  if(user_dst){
    80002550:	c08d                	beqz	s1,80002572 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002552:	86d2                	mv	a3,s4
    80002554:	864e                	mv	a2,s3
    80002556:	85ca                	mv	a1,s2
    80002558:	6928                	ld	a0,80(a0)
    8000255a:	fffff097          	auipc	ra,0xfffff
    8000255e:	224080e7          	jalr	548(ra) # 8000177e <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002562:	70a2                	ld	ra,40(sp)
    80002564:	7402                	ld	s0,32(sp)
    80002566:	64e2                	ld	s1,24(sp)
    80002568:	6942                	ld	s2,16(sp)
    8000256a:	69a2                	ld	s3,8(sp)
    8000256c:	6a02                	ld	s4,0(sp)
    8000256e:	6145                	addi	sp,sp,48
    80002570:	8082                	ret
    memmove((char *)dst, src, len);
    80002572:	000a061b          	sext.w	a2,s4
    80002576:	85ce                	mv	a1,s3
    80002578:	854a                	mv	a0,s2
    8000257a:	ffffe097          	auipc	ra,0xffffe
    8000257e:	7f2080e7          	jalr	2034(ra) # 80000d6c <memmove>
    return 0;
    80002582:	8526                	mv	a0,s1
    80002584:	bff9                	j	80002562 <either_copyout+0x32>

0000000080002586 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002586:	7179                	addi	sp,sp,-48
    80002588:	f406                	sd	ra,40(sp)
    8000258a:	f022                	sd	s0,32(sp)
    8000258c:	ec26                	sd	s1,24(sp)
    8000258e:	e84a                	sd	s2,16(sp)
    80002590:	e44e                	sd	s3,8(sp)
    80002592:	e052                	sd	s4,0(sp)
    80002594:	1800                	addi	s0,sp,48
    80002596:	892a                	mv	s2,a0
    80002598:	84ae                	mv	s1,a1
    8000259a:	89b2                	mv	s3,a2
    8000259c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000259e:	fffff097          	auipc	ra,0xfffff
    800025a2:	520080e7          	jalr	1312(ra) # 80001abe <myproc>
  if(user_src){
    800025a6:	c08d                	beqz	s1,800025c8 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800025a8:	86d2                	mv	a3,s4
    800025aa:	864e                	mv	a2,s3
    800025ac:	85ca                	mv	a1,s2
    800025ae:	6928                	ld	a0,80(a0)
    800025b0:	fffff097          	auipc	ra,0xfffff
    800025b4:	274080e7          	jalr	628(ra) # 80001824 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800025b8:	70a2                	ld	ra,40(sp)
    800025ba:	7402                	ld	s0,32(sp)
    800025bc:	64e2                	ld	s1,24(sp)
    800025be:	6942                	ld	s2,16(sp)
    800025c0:	69a2                	ld	s3,8(sp)
    800025c2:	6a02                	ld	s4,0(sp)
    800025c4:	6145                	addi	sp,sp,48
    800025c6:	8082                	ret
    memmove(dst, (char*)src, len);
    800025c8:	000a061b          	sext.w	a2,s4
    800025cc:	85ce                	mv	a1,s3
    800025ce:	854a                	mv	a0,s2
    800025d0:	ffffe097          	auipc	ra,0xffffe
    800025d4:	79c080e7          	jalr	1948(ra) # 80000d6c <memmove>
    return 0;
    800025d8:	8526                	mv	a0,s1
    800025da:	bff9                	j	800025b8 <either_copyin+0x32>

00000000800025dc <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800025dc:	715d                	addi	sp,sp,-80
    800025de:	e486                	sd	ra,72(sp)
    800025e0:	e0a2                	sd	s0,64(sp)
    800025e2:	fc26                	sd	s1,56(sp)
    800025e4:	f84a                	sd	s2,48(sp)
    800025e6:	f44e                	sd	s3,40(sp)
    800025e8:	f052                	sd	s4,32(sp)
    800025ea:	ec56                	sd	s5,24(sp)
    800025ec:	e85a                	sd	s6,16(sp)
    800025ee:	e45e                	sd	s7,8(sp)
    800025f0:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800025f2:	00006517          	auipc	a0,0x6
    800025f6:	ad650513          	addi	a0,a0,-1322 # 800080c8 <digits+0x88>
    800025fa:	ffffe097          	auipc	ra,0xffffe
    800025fe:	f98080e7          	jalr	-104(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002602:	00010497          	auipc	s1,0x10
    80002606:	8be48493          	addi	s1,s1,-1858 # 80011ec0 <proc+0x158>
    8000260a:	00015917          	auipc	s2,0x15
    8000260e:	2b690913          	addi	s2,s2,694 # 800178c0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002612:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    80002614:	00006997          	auipc	s3,0x6
    80002618:	c2c98993          	addi	s3,s3,-980 # 80008240 <digits+0x200>
    printf("%d %s %s", p->pid, state, p->name);
    8000261c:	00006a97          	auipc	s5,0x6
    80002620:	c2ca8a93          	addi	s5,s5,-980 # 80008248 <digits+0x208>
    printf("\n");
    80002624:	00006a17          	auipc	s4,0x6
    80002628:	aa4a0a13          	addi	s4,s4,-1372 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000262c:	00006b97          	auipc	s7,0x6
    80002630:	c54b8b93          	addi	s7,s7,-940 # 80008280 <states.1702>
    80002634:	a00d                	j	80002656 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002636:	ee06a583          	lw	a1,-288(a3)
    8000263a:	8556                	mv	a0,s5
    8000263c:	ffffe097          	auipc	ra,0xffffe
    80002640:	f56080e7          	jalr	-170(ra) # 80000592 <printf>
    printf("\n");
    80002644:	8552                	mv	a0,s4
    80002646:	ffffe097          	auipc	ra,0xffffe
    8000264a:	f4c080e7          	jalr	-180(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000264e:	16848493          	addi	s1,s1,360
    80002652:	03248163          	beq	s1,s2,80002674 <procdump+0x98>
    if(p->state == UNUSED)
    80002656:	86a6                	mv	a3,s1
    80002658:	ec04a783          	lw	a5,-320(s1)
    8000265c:	dbed                	beqz	a5,8000264e <procdump+0x72>
      state = "???";
    8000265e:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002660:	fcfb6be3          	bltu	s6,a5,80002636 <procdump+0x5a>
    80002664:	1782                	slli	a5,a5,0x20
    80002666:	9381                	srli	a5,a5,0x20
    80002668:	078e                	slli	a5,a5,0x3
    8000266a:	97de                	add	a5,a5,s7
    8000266c:	6390                	ld	a2,0(a5)
    8000266e:	f661                	bnez	a2,80002636 <procdump+0x5a>
      state = "???";
    80002670:	864e                	mv	a2,s3
    80002672:	b7d1                	j	80002636 <procdump+0x5a>
  }
}
    80002674:	60a6                	ld	ra,72(sp)
    80002676:	6406                	ld	s0,64(sp)
    80002678:	74e2                	ld	s1,56(sp)
    8000267a:	7942                	ld	s2,48(sp)
    8000267c:	79a2                	ld	s3,40(sp)
    8000267e:	7a02                	ld	s4,32(sp)
    80002680:	6ae2                	ld	s5,24(sp)
    80002682:	6b42                	ld	s6,16(sp)
    80002684:	6ba2                	ld	s7,8(sp)
    80002686:	6161                	addi	sp,sp,80
    80002688:	8082                	ret

000000008000268a <swtch>:
    8000268a:	00153023          	sd	ra,0(a0)
    8000268e:	00253423          	sd	sp,8(a0)
    80002692:	e900                	sd	s0,16(a0)
    80002694:	ed04                	sd	s1,24(a0)
    80002696:	03253023          	sd	s2,32(a0)
    8000269a:	03353423          	sd	s3,40(a0)
    8000269e:	03453823          	sd	s4,48(a0)
    800026a2:	03553c23          	sd	s5,56(a0)
    800026a6:	05653023          	sd	s6,64(a0)
    800026aa:	05753423          	sd	s7,72(a0)
    800026ae:	05853823          	sd	s8,80(a0)
    800026b2:	05953c23          	sd	s9,88(a0)
    800026b6:	07a53023          	sd	s10,96(a0)
    800026ba:	07b53423          	sd	s11,104(a0)
    800026be:	0005b083          	ld	ra,0(a1)
    800026c2:	0085b103          	ld	sp,8(a1)
    800026c6:	6980                	ld	s0,16(a1)
    800026c8:	6d84                	ld	s1,24(a1)
    800026ca:	0205b903          	ld	s2,32(a1)
    800026ce:	0285b983          	ld	s3,40(a1)
    800026d2:	0305ba03          	ld	s4,48(a1)
    800026d6:	0385ba83          	ld	s5,56(a1)
    800026da:	0405bb03          	ld	s6,64(a1)
    800026de:	0485bb83          	ld	s7,72(a1)
    800026e2:	0505bc03          	ld	s8,80(a1)
    800026e6:	0585bc83          	ld	s9,88(a1)
    800026ea:	0605bd03          	ld	s10,96(a1)
    800026ee:	0685bd83          	ld	s11,104(a1)
    800026f2:	8082                	ret

00000000800026f4 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800026f4:	1141                	addi	sp,sp,-16
    800026f6:	e406                	sd	ra,8(sp)
    800026f8:	e022                	sd	s0,0(sp)
    800026fa:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800026fc:	00006597          	auipc	a1,0x6
    80002700:	bac58593          	addi	a1,a1,-1108 # 800082a8 <states.1702+0x28>
    80002704:	00015517          	auipc	a0,0x15
    80002708:	06450513          	addi	a0,a0,100 # 80017768 <tickslock>
    8000270c:	ffffe097          	auipc	ra,0xffffe
    80002710:	474080e7          	jalr	1140(ra) # 80000b80 <initlock>
}
    80002714:	60a2                	ld	ra,8(sp)
    80002716:	6402                	ld	s0,0(sp)
    80002718:	0141                	addi	sp,sp,16
    8000271a:	8082                	ret

000000008000271c <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000271c:	1141                	addi	sp,sp,-16
    8000271e:	e422                	sd	s0,8(sp)
    80002720:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002722:	00003797          	auipc	a5,0x3
    80002726:	52e78793          	addi	a5,a5,1326 # 80005c50 <kernelvec>
    8000272a:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000272e:	6422                	ld	s0,8(sp)
    80002730:	0141                	addi	sp,sp,16
    80002732:	8082                	ret

0000000080002734 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002734:	1141                	addi	sp,sp,-16
    80002736:	e406                	sd	ra,8(sp)
    80002738:	e022                	sd	s0,0(sp)
    8000273a:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000273c:	fffff097          	auipc	ra,0xfffff
    80002740:	382080e7          	jalr	898(ra) # 80001abe <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002744:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002748:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000274a:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000274e:	00005617          	auipc	a2,0x5
    80002752:	8b260613          	addi	a2,a2,-1870 # 80007000 <_trampoline>
    80002756:	00005697          	auipc	a3,0x5
    8000275a:	8aa68693          	addi	a3,a3,-1878 # 80007000 <_trampoline>
    8000275e:	8e91                	sub	a3,a3,a2
    80002760:	040007b7          	lui	a5,0x4000
    80002764:	17fd                	addi	a5,a5,-1
    80002766:	07b2                	slli	a5,a5,0xc
    80002768:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000276a:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000276e:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002770:	180026f3          	csrr	a3,satp
    80002774:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002776:	6d38                	ld	a4,88(a0)
    80002778:	6134                	ld	a3,64(a0)
    8000277a:	6585                	lui	a1,0x1
    8000277c:	96ae                	add	a3,a3,a1
    8000277e:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002780:	6d38                	ld	a4,88(a0)
    80002782:	00000697          	auipc	a3,0x0
    80002786:	13868693          	addi	a3,a3,312 # 800028ba <usertrap>
    8000278a:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000278c:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000278e:	8692                	mv	a3,tp
    80002790:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002792:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002796:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000279a:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000279e:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800027a2:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800027a4:	6f18                	ld	a4,24(a4)
    800027a6:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800027aa:	692c                	ld	a1,80(a0)
    800027ac:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800027ae:	00005717          	auipc	a4,0x5
    800027b2:	8e270713          	addi	a4,a4,-1822 # 80007090 <userret>
    800027b6:	8f11                	sub	a4,a4,a2
    800027b8:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800027ba:	577d                	li	a4,-1
    800027bc:	177e                	slli	a4,a4,0x3f
    800027be:	8dd9                	or	a1,a1,a4
    800027c0:	02000537          	lui	a0,0x2000
    800027c4:	157d                	addi	a0,a0,-1
    800027c6:	0536                	slli	a0,a0,0xd
    800027c8:	9782                	jalr	a5
}
    800027ca:	60a2                	ld	ra,8(sp)
    800027cc:	6402                	ld	s0,0(sp)
    800027ce:	0141                	addi	sp,sp,16
    800027d0:	8082                	ret

00000000800027d2 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800027d2:	1101                	addi	sp,sp,-32
    800027d4:	ec06                	sd	ra,24(sp)
    800027d6:	e822                	sd	s0,16(sp)
    800027d8:	e426                	sd	s1,8(sp)
    800027da:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800027dc:	00015497          	auipc	s1,0x15
    800027e0:	f8c48493          	addi	s1,s1,-116 # 80017768 <tickslock>
    800027e4:	8526                	mv	a0,s1
    800027e6:	ffffe097          	auipc	ra,0xffffe
    800027ea:	42a080e7          	jalr	1066(ra) # 80000c10 <acquire>
  ticks++;
    800027ee:	00007517          	auipc	a0,0x7
    800027f2:	83250513          	addi	a0,a0,-1998 # 80009020 <ticks>
    800027f6:	411c                	lw	a5,0(a0)
    800027f8:	2785                	addiw	a5,a5,1
    800027fa:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800027fc:	00000097          	auipc	ra,0x0
    80002800:	c58080e7          	jalr	-936(ra) # 80002454 <wakeup>
  release(&tickslock);
    80002804:	8526                	mv	a0,s1
    80002806:	ffffe097          	auipc	ra,0xffffe
    8000280a:	4be080e7          	jalr	1214(ra) # 80000cc4 <release>
}
    8000280e:	60e2                	ld	ra,24(sp)
    80002810:	6442                	ld	s0,16(sp)
    80002812:	64a2                	ld	s1,8(sp)
    80002814:	6105                	addi	sp,sp,32
    80002816:	8082                	ret

0000000080002818 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002818:	1101                	addi	sp,sp,-32
    8000281a:	ec06                	sd	ra,24(sp)
    8000281c:	e822                	sd	s0,16(sp)
    8000281e:	e426                	sd	s1,8(sp)
    80002820:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002822:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002826:	00074d63          	bltz	a4,80002840 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    8000282a:	57fd                	li	a5,-1
    8000282c:	17fe                	slli	a5,a5,0x3f
    8000282e:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002830:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002832:	06f70363          	beq	a4,a5,80002898 <devintr+0x80>
  }
}
    80002836:	60e2                	ld	ra,24(sp)
    80002838:	6442                	ld	s0,16(sp)
    8000283a:	64a2                	ld	s1,8(sp)
    8000283c:	6105                	addi	sp,sp,32
    8000283e:	8082                	ret
     (scause & 0xff) == 9){
    80002840:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002844:	46a5                	li	a3,9
    80002846:	fed792e3          	bne	a5,a3,8000282a <devintr+0x12>
    int irq = plic_claim();
    8000284a:	00003097          	auipc	ra,0x3
    8000284e:	50e080e7          	jalr	1294(ra) # 80005d58 <plic_claim>
    80002852:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002854:	47a9                	li	a5,10
    80002856:	02f50763          	beq	a0,a5,80002884 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000285a:	4785                	li	a5,1
    8000285c:	02f50963          	beq	a0,a5,8000288e <devintr+0x76>
    return 1;
    80002860:	4505                	li	a0,1
    } else if(irq){
    80002862:	d8f1                	beqz	s1,80002836 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002864:	85a6                	mv	a1,s1
    80002866:	00006517          	auipc	a0,0x6
    8000286a:	a4a50513          	addi	a0,a0,-1462 # 800082b0 <states.1702+0x30>
    8000286e:	ffffe097          	auipc	ra,0xffffe
    80002872:	d24080e7          	jalr	-732(ra) # 80000592 <printf>
      plic_complete(irq);
    80002876:	8526                	mv	a0,s1
    80002878:	00003097          	auipc	ra,0x3
    8000287c:	504080e7          	jalr	1284(ra) # 80005d7c <plic_complete>
    return 1;
    80002880:	4505                	li	a0,1
    80002882:	bf55                	j	80002836 <devintr+0x1e>
      uartintr();
    80002884:	ffffe097          	auipc	ra,0xffffe
    80002888:	150080e7          	jalr	336(ra) # 800009d4 <uartintr>
    8000288c:	b7ed                	j	80002876 <devintr+0x5e>
      virtio_disk_intr();
    8000288e:	00004097          	auipc	ra,0x4
    80002892:	988080e7          	jalr	-1656(ra) # 80006216 <virtio_disk_intr>
    80002896:	b7c5                	j	80002876 <devintr+0x5e>
    if(cpuid() == 0){
    80002898:	fffff097          	auipc	ra,0xfffff
    8000289c:	1fa080e7          	jalr	506(ra) # 80001a92 <cpuid>
    800028a0:	c901                	beqz	a0,800028b0 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800028a2:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800028a6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800028a8:	14479073          	csrw	sip,a5
    return 2;
    800028ac:	4509                	li	a0,2
    800028ae:	b761                	j	80002836 <devintr+0x1e>
      clockintr();
    800028b0:	00000097          	auipc	ra,0x0
    800028b4:	f22080e7          	jalr	-222(ra) # 800027d2 <clockintr>
    800028b8:	b7ed                	j	800028a2 <devintr+0x8a>

00000000800028ba <usertrap>:
{
    800028ba:	7179                	addi	sp,sp,-48
    800028bc:	f406                	sd	ra,40(sp)
    800028be:	f022                	sd	s0,32(sp)
    800028c0:	ec26                	sd	s1,24(sp)
    800028c2:	e84a                	sd	s2,16(sp)
    800028c4:	e44e                	sd	s3,8(sp)
    800028c6:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028c8:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800028cc:	1007f793          	andi	a5,a5,256
    800028d0:	e3b5                	bnez	a5,80002934 <usertrap+0x7a>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028d2:	00003797          	auipc	a5,0x3
    800028d6:	37e78793          	addi	a5,a5,894 # 80005c50 <kernelvec>
    800028da:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800028de:	fffff097          	auipc	ra,0xfffff
    800028e2:	1e0080e7          	jalr	480(ra) # 80001abe <myproc>
    800028e6:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800028e8:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028ea:	14102773          	csrr	a4,sepc
    800028ee:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028f0:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800028f4:	47a1                	li	a5,8
    800028f6:	04f71d63          	bne	a4,a5,80002950 <usertrap+0x96>
    if(p->killed)
    800028fa:	591c                	lw	a5,48(a0)
    800028fc:	e7a1                	bnez	a5,80002944 <usertrap+0x8a>
    p->trapframe->epc += 4;
    800028fe:	6cb8                	ld	a4,88(s1)
    80002900:	6f1c                	ld	a5,24(a4)
    80002902:	0791                	addi	a5,a5,4
    80002904:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002906:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000290a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000290e:	10079073          	csrw	sstatus,a5
    syscall();
    80002912:	00000097          	auipc	ra,0x0
    80002916:	312080e7          	jalr	786(ra) # 80002c24 <syscall>
  if(p->killed)
    8000291a:	589c                	lw	a5,48(s1)
    8000291c:	e3e9                	bnez	a5,800029de <usertrap+0x124>
  usertrapret();
    8000291e:	00000097          	auipc	ra,0x0
    80002922:	e16080e7          	jalr	-490(ra) # 80002734 <usertrapret>
}
    80002926:	70a2                	ld	ra,40(sp)
    80002928:	7402                	ld	s0,32(sp)
    8000292a:	64e2                	ld	s1,24(sp)
    8000292c:	6942                	ld	s2,16(sp)
    8000292e:	69a2                	ld	s3,8(sp)
    80002930:	6145                	addi	sp,sp,48
    80002932:	8082                	ret
    panic("usertrap: not from user mode");
    80002934:	00006517          	auipc	a0,0x6
    80002938:	99c50513          	addi	a0,a0,-1636 # 800082d0 <states.1702+0x50>
    8000293c:	ffffe097          	auipc	ra,0xffffe
    80002940:	c0c080e7          	jalr	-1012(ra) # 80000548 <panic>
      exit(-1);
    80002944:	557d                	li	a0,-1
    80002946:	00000097          	auipc	ra,0x0
    8000294a:	842080e7          	jalr	-1982(ra) # 80002188 <exit>
    8000294e:	bf45                	j	800028fe <usertrap+0x44>
  } else if((which_dev = devintr()) != 0){
    80002950:	00000097          	auipc	ra,0x0
    80002954:	ec8080e7          	jalr	-312(ra) # 80002818 <devintr>
    80002958:	892a                	mv	s2,a0
    8000295a:	ed3d                	bnez	a0,800029d8 <usertrap+0x11e>
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000295c:	143029f3          	csrr	s3,stval
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002960:	14202773          	csrr	a4,scause
    if((r_scause() == 13 || r_scause() == 15) && uvmshouldtouch(va)){ // 缺页异常，并且发生异常的地址进行过懒分配
    80002964:	47b5                	li	a5,13
    80002966:	04f70d63          	beq	a4,a5,800029c0 <usertrap+0x106>
    8000296a:	14202773          	csrr	a4,scause
    8000296e:	47bd                	li	a5,15
    80002970:	04f70863          	beq	a4,a5,800029c0 <usertrap+0x106>
    80002974:	142025f3          	csrr	a1,scause
      printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002978:	5c90                	lw	a2,56(s1)
    8000297a:	00006517          	auipc	a0,0x6
    8000297e:	97650513          	addi	a0,a0,-1674 # 800082f0 <states.1702+0x70>
    80002982:	ffffe097          	auipc	ra,0xffffe
    80002986:	c10080e7          	jalr	-1008(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000298a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000298e:	14302673          	csrr	a2,stval
      printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002992:	00006517          	auipc	a0,0x6
    80002996:	98e50513          	addi	a0,a0,-1650 # 80008320 <states.1702+0xa0>
    8000299a:	ffffe097          	auipc	ra,0xffffe
    8000299e:	bf8080e7          	jalr	-1032(ra) # 80000592 <printf>
      p->killed = 1;
    800029a2:	4785                	li	a5,1
    800029a4:	d89c                	sw	a5,48(s1)
    exit(-1);
    800029a6:	557d                	li	a0,-1
    800029a8:	fffff097          	auipc	ra,0xfffff
    800029ac:	7e0080e7          	jalr	2016(ra) # 80002188 <exit>
  if(which_dev == 2)
    800029b0:	4789                	li	a5,2
    800029b2:	f6f916e3          	bne	s2,a5,8000291e <usertrap+0x64>
    yield();
    800029b6:	00000097          	auipc	ra,0x0
    800029ba:	8dc080e7          	jalr	-1828(ra) # 80002292 <yield>
    800029be:	b785                	j	8000291e <usertrap+0x64>
    if((r_scause() == 13 || r_scause() == 15) && uvmshouldtouch(va)){ // 缺页异常，并且发生异常的地址进行过懒分配
    800029c0:	854e                	mv	a0,s3
    800029c2:	fffff097          	auipc	ra,0xfffff
    800029c6:	9a8080e7          	jalr	-1624(ra) # 8000136a <uvmshouldtouch>
    800029ca:	d54d                	beqz	a0,80002974 <usertrap+0xba>
      uvmlazytouch(va); // 分配物理内存，并在页表创建映射
    800029cc:	854e                	mv	a0,s3
    800029ce:	fffff097          	auipc	ra,0xfffff
    800029d2:	908080e7          	jalr	-1784(ra) # 800012d6 <uvmlazytouch>
    800029d6:	b791                	j	8000291a <usertrap+0x60>
  if(p->killed)
    800029d8:	589c                	lw	a5,48(s1)
    800029da:	dbf9                	beqz	a5,800029b0 <usertrap+0xf6>
    800029dc:	b7e9                	j	800029a6 <usertrap+0xec>
    800029de:	4901                	li	s2,0
    800029e0:	b7d9                	j	800029a6 <usertrap+0xec>

00000000800029e2 <kerneltrap>:
{
    800029e2:	7179                	addi	sp,sp,-48
    800029e4:	f406                	sd	ra,40(sp)
    800029e6:	f022                	sd	s0,32(sp)
    800029e8:	ec26                	sd	s1,24(sp)
    800029ea:	e84a                	sd	s2,16(sp)
    800029ec:	e44e                	sd	s3,8(sp)
    800029ee:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029f0:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029f4:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029f8:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800029fc:	1004f793          	andi	a5,s1,256
    80002a00:	cb85                	beqz	a5,80002a30 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a02:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002a06:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002a08:	ef85                	bnez	a5,80002a40 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002a0a:	00000097          	auipc	ra,0x0
    80002a0e:	e0e080e7          	jalr	-498(ra) # 80002818 <devintr>
    80002a12:	cd1d                	beqz	a0,80002a50 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a14:	4789                	li	a5,2
    80002a16:	06f50a63          	beq	a0,a5,80002a8a <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a1a:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a1e:	10049073          	csrw	sstatus,s1
}
    80002a22:	70a2                	ld	ra,40(sp)
    80002a24:	7402                	ld	s0,32(sp)
    80002a26:	64e2                	ld	s1,24(sp)
    80002a28:	6942                	ld	s2,16(sp)
    80002a2a:	69a2                	ld	s3,8(sp)
    80002a2c:	6145                	addi	sp,sp,48
    80002a2e:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002a30:	00006517          	auipc	a0,0x6
    80002a34:	91050513          	addi	a0,a0,-1776 # 80008340 <states.1702+0xc0>
    80002a38:	ffffe097          	auipc	ra,0xffffe
    80002a3c:	b10080e7          	jalr	-1264(ra) # 80000548 <panic>
    panic("kerneltrap: interrupts enabled");
    80002a40:	00006517          	auipc	a0,0x6
    80002a44:	92850513          	addi	a0,a0,-1752 # 80008368 <states.1702+0xe8>
    80002a48:	ffffe097          	auipc	ra,0xffffe
    80002a4c:	b00080e7          	jalr	-1280(ra) # 80000548 <panic>
    printf("scause %p\n", scause);
    80002a50:	85ce                	mv	a1,s3
    80002a52:	00006517          	auipc	a0,0x6
    80002a56:	93650513          	addi	a0,a0,-1738 # 80008388 <states.1702+0x108>
    80002a5a:	ffffe097          	auipc	ra,0xffffe
    80002a5e:	b38080e7          	jalr	-1224(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a62:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a66:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a6a:	00006517          	auipc	a0,0x6
    80002a6e:	92e50513          	addi	a0,a0,-1746 # 80008398 <states.1702+0x118>
    80002a72:	ffffe097          	auipc	ra,0xffffe
    80002a76:	b20080e7          	jalr	-1248(ra) # 80000592 <printf>
    panic("kerneltrap");
    80002a7a:	00006517          	auipc	a0,0x6
    80002a7e:	93650513          	addi	a0,a0,-1738 # 800083b0 <states.1702+0x130>
    80002a82:	ffffe097          	auipc	ra,0xffffe
    80002a86:	ac6080e7          	jalr	-1338(ra) # 80000548 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a8a:	fffff097          	auipc	ra,0xfffff
    80002a8e:	034080e7          	jalr	52(ra) # 80001abe <myproc>
    80002a92:	d541                	beqz	a0,80002a1a <kerneltrap+0x38>
    80002a94:	fffff097          	auipc	ra,0xfffff
    80002a98:	02a080e7          	jalr	42(ra) # 80001abe <myproc>
    80002a9c:	4d18                	lw	a4,24(a0)
    80002a9e:	478d                	li	a5,3
    80002aa0:	f6f71de3          	bne	a4,a5,80002a1a <kerneltrap+0x38>
    yield();
    80002aa4:	fffff097          	auipc	ra,0xfffff
    80002aa8:	7ee080e7          	jalr	2030(ra) # 80002292 <yield>
    80002aac:	b7bd                	j	80002a1a <kerneltrap+0x38>

0000000080002aae <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002aae:	1101                	addi	sp,sp,-32
    80002ab0:	ec06                	sd	ra,24(sp)
    80002ab2:	e822                	sd	s0,16(sp)
    80002ab4:	e426                	sd	s1,8(sp)
    80002ab6:	1000                	addi	s0,sp,32
    80002ab8:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002aba:	fffff097          	auipc	ra,0xfffff
    80002abe:	004080e7          	jalr	4(ra) # 80001abe <myproc>
  switch (n) {
    80002ac2:	4795                	li	a5,5
    80002ac4:	0497e163          	bltu	a5,s1,80002b06 <argraw+0x58>
    80002ac8:	048a                	slli	s1,s1,0x2
    80002aca:	00006717          	auipc	a4,0x6
    80002ace:	91e70713          	addi	a4,a4,-1762 # 800083e8 <states.1702+0x168>
    80002ad2:	94ba                	add	s1,s1,a4
    80002ad4:	409c                	lw	a5,0(s1)
    80002ad6:	97ba                	add	a5,a5,a4
    80002ad8:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002ada:	6d3c                	ld	a5,88(a0)
    80002adc:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002ade:	60e2                	ld	ra,24(sp)
    80002ae0:	6442                	ld	s0,16(sp)
    80002ae2:	64a2                	ld	s1,8(sp)
    80002ae4:	6105                	addi	sp,sp,32
    80002ae6:	8082                	ret
    return p->trapframe->a1;
    80002ae8:	6d3c                	ld	a5,88(a0)
    80002aea:	7fa8                	ld	a0,120(a5)
    80002aec:	bfcd                	j	80002ade <argraw+0x30>
    return p->trapframe->a2;
    80002aee:	6d3c                	ld	a5,88(a0)
    80002af0:	63c8                	ld	a0,128(a5)
    80002af2:	b7f5                	j	80002ade <argraw+0x30>
    return p->trapframe->a3;
    80002af4:	6d3c                	ld	a5,88(a0)
    80002af6:	67c8                	ld	a0,136(a5)
    80002af8:	b7dd                	j	80002ade <argraw+0x30>
    return p->trapframe->a4;
    80002afa:	6d3c                	ld	a5,88(a0)
    80002afc:	6bc8                	ld	a0,144(a5)
    80002afe:	b7c5                	j	80002ade <argraw+0x30>
    return p->trapframe->a5;
    80002b00:	6d3c                	ld	a5,88(a0)
    80002b02:	6fc8                	ld	a0,152(a5)
    80002b04:	bfe9                	j	80002ade <argraw+0x30>
  panic("argraw");
    80002b06:	00006517          	auipc	a0,0x6
    80002b0a:	8ba50513          	addi	a0,a0,-1862 # 800083c0 <states.1702+0x140>
    80002b0e:	ffffe097          	auipc	ra,0xffffe
    80002b12:	a3a080e7          	jalr	-1478(ra) # 80000548 <panic>

0000000080002b16 <fetchaddr>:
{
    80002b16:	1101                	addi	sp,sp,-32
    80002b18:	ec06                	sd	ra,24(sp)
    80002b1a:	e822                	sd	s0,16(sp)
    80002b1c:	e426                	sd	s1,8(sp)
    80002b1e:	e04a                	sd	s2,0(sp)
    80002b20:	1000                	addi	s0,sp,32
    80002b22:	84aa                	mv	s1,a0
    80002b24:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002b26:	fffff097          	auipc	ra,0xfffff
    80002b2a:	f98080e7          	jalr	-104(ra) # 80001abe <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002b2e:	653c                	ld	a5,72(a0)
    80002b30:	02f4f863          	bgeu	s1,a5,80002b60 <fetchaddr+0x4a>
    80002b34:	00848713          	addi	a4,s1,8
    80002b38:	02e7e663          	bltu	a5,a4,80002b64 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002b3c:	46a1                	li	a3,8
    80002b3e:	8626                	mv	a2,s1
    80002b40:	85ca                	mv	a1,s2
    80002b42:	6928                	ld	a0,80(a0)
    80002b44:	fffff097          	auipc	ra,0xfffff
    80002b48:	ce0080e7          	jalr	-800(ra) # 80001824 <copyin>
    80002b4c:	00a03533          	snez	a0,a0
    80002b50:	40a00533          	neg	a0,a0
}
    80002b54:	60e2                	ld	ra,24(sp)
    80002b56:	6442                	ld	s0,16(sp)
    80002b58:	64a2                	ld	s1,8(sp)
    80002b5a:	6902                	ld	s2,0(sp)
    80002b5c:	6105                	addi	sp,sp,32
    80002b5e:	8082                	ret
    return -1;
    80002b60:	557d                	li	a0,-1
    80002b62:	bfcd                	j	80002b54 <fetchaddr+0x3e>
    80002b64:	557d                	li	a0,-1
    80002b66:	b7fd                	j	80002b54 <fetchaddr+0x3e>

0000000080002b68 <fetchstr>:
{
    80002b68:	7179                	addi	sp,sp,-48
    80002b6a:	f406                	sd	ra,40(sp)
    80002b6c:	f022                	sd	s0,32(sp)
    80002b6e:	ec26                	sd	s1,24(sp)
    80002b70:	e84a                	sd	s2,16(sp)
    80002b72:	e44e                	sd	s3,8(sp)
    80002b74:	1800                	addi	s0,sp,48
    80002b76:	892a                	mv	s2,a0
    80002b78:	84ae                	mv	s1,a1
    80002b7a:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b7c:	fffff097          	auipc	ra,0xfffff
    80002b80:	f42080e7          	jalr	-190(ra) # 80001abe <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002b84:	86ce                	mv	a3,s3
    80002b86:	864a                	mv	a2,s2
    80002b88:	85a6                	mv	a1,s1
    80002b8a:	6928                	ld	a0,80(a0)
    80002b8c:	fffff097          	auipc	ra,0xfffff
    80002b90:	d3e080e7          	jalr	-706(ra) # 800018ca <copyinstr>
  if(err < 0)
    80002b94:	00054763          	bltz	a0,80002ba2 <fetchstr+0x3a>
  return strlen(buf);
    80002b98:	8526                	mv	a0,s1
    80002b9a:	ffffe097          	auipc	ra,0xffffe
    80002b9e:	2fa080e7          	jalr	762(ra) # 80000e94 <strlen>
}
    80002ba2:	70a2                	ld	ra,40(sp)
    80002ba4:	7402                	ld	s0,32(sp)
    80002ba6:	64e2                	ld	s1,24(sp)
    80002ba8:	6942                	ld	s2,16(sp)
    80002baa:	69a2                	ld	s3,8(sp)
    80002bac:	6145                	addi	sp,sp,48
    80002bae:	8082                	ret

0000000080002bb0 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002bb0:	1101                	addi	sp,sp,-32
    80002bb2:	ec06                	sd	ra,24(sp)
    80002bb4:	e822                	sd	s0,16(sp)
    80002bb6:	e426                	sd	s1,8(sp)
    80002bb8:	1000                	addi	s0,sp,32
    80002bba:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002bbc:	00000097          	auipc	ra,0x0
    80002bc0:	ef2080e7          	jalr	-270(ra) # 80002aae <argraw>
    80002bc4:	c088                	sw	a0,0(s1)
  return 0;
}
    80002bc6:	4501                	li	a0,0
    80002bc8:	60e2                	ld	ra,24(sp)
    80002bca:	6442                	ld	s0,16(sp)
    80002bcc:	64a2                	ld	s1,8(sp)
    80002bce:	6105                	addi	sp,sp,32
    80002bd0:	8082                	ret

0000000080002bd2 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002bd2:	1101                	addi	sp,sp,-32
    80002bd4:	ec06                	sd	ra,24(sp)
    80002bd6:	e822                	sd	s0,16(sp)
    80002bd8:	e426                	sd	s1,8(sp)
    80002bda:	1000                	addi	s0,sp,32
    80002bdc:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002bde:	00000097          	auipc	ra,0x0
    80002be2:	ed0080e7          	jalr	-304(ra) # 80002aae <argraw>
    80002be6:	e088                	sd	a0,0(s1)
  return 0;
}
    80002be8:	4501                	li	a0,0
    80002bea:	60e2                	ld	ra,24(sp)
    80002bec:	6442                	ld	s0,16(sp)
    80002bee:	64a2                	ld	s1,8(sp)
    80002bf0:	6105                	addi	sp,sp,32
    80002bf2:	8082                	ret

0000000080002bf4 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002bf4:	1101                	addi	sp,sp,-32
    80002bf6:	ec06                	sd	ra,24(sp)
    80002bf8:	e822                	sd	s0,16(sp)
    80002bfa:	e426                	sd	s1,8(sp)
    80002bfc:	e04a                	sd	s2,0(sp)
    80002bfe:	1000                	addi	s0,sp,32
    80002c00:	84ae                	mv	s1,a1
    80002c02:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002c04:	00000097          	auipc	ra,0x0
    80002c08:	eaa080e7          	jalr	-342(ra) # 80002aae <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002c0c:	864a                	mv	a2,s2
    80002c0e:	85a6                	mv	a1,s1
    80002c10:	00000097          	auipc	ra,0x0
    80002c14:	f58080e7          	jalr	-168(ra) # 80002b68 <fetchstr>
}
    80002c18:	60e2                	ld	ra,24(sp)
    80002c1a:	6442                	ld	s0,16(sp)
    80002c1c:	64a2                	ld	s1,8(sp)
    80002c1e:	6902                	ld	s2,0(sp)
    80002c20:	6105                	addi	sp,sp,32
    80002c22:	8082                	ret

0000000080002c24 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002c24:	1101                	addi	sp,sp,-32
    80002c26:	ec06                	sd	ra,24(sp)
    80002c28:	e822                	sd	s0,16(sp)
    80002c2a:	e426                	sd	s1,8(sp)
    80002c2c:	e04a                	sd	s2,0(sp)
    80002c2e:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002c30:	fffff097          	auipc	ra,0xfffff
    80002c34:	e8e080e7          	jalr	-370(ra) # 80001abe <myproc>
    80002c38:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002c3a:	05853903          	ld	s2,88(a0)
    80002c3e:	0a893783          	ld	a5,168(s2)
    80002c42:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c46:	37fd                	addiw	a5,a5,-1
    80002c48:	4751                	li	a4,20
    80002c4a:	00f76f63          	bltu	a4,a5,80002c68 <syscall+0x44>
    80002c4e:	00369713          	slli	a4,a3,0x3
    80002c52:	00005797          	auipc	a5,0x5
    80002c56:	7ae78793          	addi	a5,a5,1966 # 80008400 <syscalls>
    80002c5a:	97ba                	add	a5,a5,a4
    80002c5c:	639c                	ld	a5,0(a5)
    80002c5e:	c789                	beqz	a5,80002c68 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002c60:	9782                	jalr	a5
    80002c62:	06a93823          	sd	a0,112(s2)
    80002c66:	a839                	j	80002c84 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c68:	15848613          	addi	a2,s1,344
    80002c6c:	5c8c                	lw	a1,56(s1)
    80002c6e:	00005517          	auipc	a0,0x5
    80002c72:	75a50513          	addi	a0,a0,1882 # 800083c8 <states.1702+0x148>
    80002c76:	ffffe097          	auipc	ra,0xffffe
    80002c7a:	91c080e7          	jalr	-1764(ra) # 80000592 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c7e:	6cbc                	ld	a5,88(s1)
    80002c80:	577d                	li	a4,-1
    80002c82:	fbb8                	sd	a4,112(a5)
  }
}
    80002c84:	60e2                	ld	ra,24(sp)
    80002c86:	6442                	ld	s0,16(sp)
    80002c88:	64a2                	ld	s1,8(sp)
    80002c8a:	6902                	ld	s2,0(sp)
    80002c8c:	6105                	addi	sp,sp,32
    80002c8e:	8082                	ret

0000000080002c90 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002c90:	1101                	addi	sp,sp,-32
    80002c92:	ec06                	sd	ra,24(sp)
    80002c94:	e822                	sd	s0,16(sp)
    80002c96:	1000                	addi	s0,sp,32
  int n; 
  if(argint(0, &n) < 0)
    80002c98:	fec40593          	addi	a1,s0,-20
    80002c9c:	4501                	li	a0,0
    80002c9e:	00000097          	auipc	ra,0x0
    80002ca2:	f12080e7          	jalr	-238(ra) # 80002bb0 <argint>
    return -1;
    80002ca6:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002ca8:	00054963          	bltz	a0,80002cba <sys_exit+0x2a>
  exit(n);
    80002cac:	fec42503          	lw	a0,-20(s0)
    80002cb0:	fffff097          	auipc	ra,0xfffff
    80002cb4:	4d8080e7          	jalr	1240(ra) # 80002188 <exit>
  return 0;  // not reached
    80002cb8:	4781                	li	a5,0
}
    80002cba:	853e                	mv	a0,a5
    80002cbc:	60e2                	ld	ra,24(sp)
    80002cbe:	6442                	ld	s0,16(sp)
    80002cc0:	6105                	addi	sp,sp,32
    80002cc2:	8082                	ret

0000000080002cc4 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002cc4:	1141                	addi	sp,sp,-16
    80002cc6:	e406                	sd	ra,8(sp)
    80002cc8:	e022                	sd	s0,0(sp)
    80002cca:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002ccc:	fffff097          	auipc	ra,0xfffff
    80002cd0:	df2080e7          	jalr	-526(ra) # 80001abe <myproc>
}
    80002cd4:	5d08                	lw	a0,56(a0)
    80002cd6:	60a2                	ld	ra,8(sp)
    80002cd8:	6402                	ld	s0,0(sp)
    80002cda:	0141                	addi	sp,sp,16
    80002cdc:	8082                	ret

0000000080002cde <sys_fork>:

uint64
sys_fork(void)
{
    80002cde:	1141                	addi	sp,sp,-16
    80002ce0:	e406                	sd	ra,8(sp)
    80002ce2:	e022                	sd	s0,0(sp)
    80002ce4:	0800                	addi	s0,sp,16
  return fork();
    80002ce6:	fffff097          	auipc	ra,0xfffff
    80002cea:	198080e7          	jalr	408(ra) # 80001e7e <fork>
}
    80002cee:	60a2                	ld	ra,8(sp)
    80002cf0:	6402                	ld	s0,0(sp)
    80002cf2:	0141                	addi	sp,sp,16
    80002cf4:	8082                	ret

0000000080002cf6 <sys_wait>:

uint64
sys_wait(void)
{
    80002cf6:	1101                	addi	sp,sp,-32
    80002cf8:	ec06                	sd	ra,24(sp)
    80002cfa:	e822                	sd	s0,16(sp)
    80002cfc:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002cfe:	fe840593          	addi	a1,s0,-24
    80002d02:	4501                	li	a0,0
    80002d04:	00000097          	auipc	ra,0x0
    80002d08:	ece080e7          	jalr	-306(ra) # 80002bd2 <argaddr>
    80002d0c:	87aa                	mv	a5,a0
    return -1;
    80002d0e:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002d10:	0007c863          	bltz	a5,80002d20 <sys_wait+0x2a>
  return wait(p);
    80002d14:	fe843503          	ld	a0,-24(s0)
    80002d18:	fffff097          	auipc	ra,0xfffff
    80002d1c:	634080e7          	jalr	1588(ra) # 8000234c <wait>
}
    80002d20:	60e2                	ld	ra,24(sp)
    80002d22:	6442                	ld	s0,16(sp)
    80002d24:	6105                	addi	sp,sp,32
    80002d26:	8082                	ret

0000000080002d28 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002d28:	7179                	addi	sp,sp,-48
    80002d2a:	f406                	sd	ra,40(sp)
    80002d2c:	f022                	sd	s0,32(sp)
    80002d2e:	ec26                	sd	s1,24(sp)
    80002d30:	e84a                	sd	s2,16(sp)
    80002d32:	1800                	addi	s0,sp,48
  int addr;
  int n;

  struct proc *p = myproc();
    80002d34:	fffff097          	auipc	ra,0xfffff
    80002d38:	d8a080e7          	jalr	-630(ra) # 80001abe <myproc>
    80002d3c:	84aa                	mv	s1,a0
  if(argint(0, &n) < 0)
    80002d3e:	fdc40593          	addi	a1,s0,-36
    80002d42:	4501                	li	a0,0
    80002d44:	00000097          	auipc	ra,0x0
    80002d48:	e6c080e7          	jalr	-404(ra) # 80002bb0 <argint>
    80002d4c:	87aa                	mv	a5,a0
    return -1;
    80002d4e:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002d50:	0207c863          	bltz	a5,80002d80 <sys_sbrk+0x58>
  //addr = myproc()->sz;
  //if(growproc(n) < 0)
  //  return -1;
  if(argint(0, &n) < 0)
    80002d54:	fdc40593          	addi	a1,s0,-36
    80002d58:	4501                	li	a0,0
    80002d5a:	00000097          	auipc	ra,0x0
    80002d5e:	e56080e7          	jalr	-426(ra) # 80002bb0 <argint>
    80002d62:	02054c63          	bltz	a0,80002d9a <sys_sbrk+0x72>
    return -1;
  addr = p->sz;
    80002d66:	64ac                	ld	a1,72(s1)
    80002d68:	0005891b          	sext.w	s2,a1
  if(n < 0) {
    80002d6c:	fdc42603          	lw	a2,-36(s0)
    80002d70:	00064e63          	bltz	a2,80002d8c <sys_sbrk+0x64>
    uvmdealloc(p->pagetable, p->sz, p->sz+n); // 如果是缩小空间，则马上释放
  }
  p->sz += n; // 懒分配
    80002d74:	fdc42703          	lw	a4,-36(s0)
    80002d78:	64bc                	ld	a5,72(s1)
    80002d7a:	97ba                	add	a5,a5,a4
    80002d7c:	e4bc                	sd	a5,72(s1)
  return addr;
    80002d7e:	854a                	mv	a0,s2
}
    80002d80:	70a2                	ld	ra,40(sp)
    80002d82:	7402                	ld	s0,32(sp)
    80002d84:	64e2                	ld	s1,24(sp)
    80002d86:	6942                	ld	s2,16(sp)
    80002d88:	6145                	addi	sp,sp,48
    80002d8a:	8082                	ret
    uvmdealloc(p->pagetable, p->sz, p->sz+n); // 如果是缩小空间，则马上释放
    80002d8c:	962e                	add	a2,a2,a1
    80002d8e:	68a8                	ld	a0,80(s1)
    80002d90:	ffffe097          	auipc	ra,0xffffe
    80002d94:	772080e7          	jalr	1906(ra) # 80001502 <uvmdealloc>
    80002d98:	bff1                	j	80002d74 <sys_sbrk+0x4c>
    return -1;
    80002d9a:	557d                	li	a0,-1
    80002d9c:	b7d5                	j	80002d80 <sys_sbrk+0x58>

0000000080002d9e <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d9e:	7139                	addi	sp,sp,-64
    80002da0:	fc06                	sd	ra,56(sp)
    80002da2:	f822                	sd	s0,48(sp)
    80002da4:	f426                	sd	s1,40(sp)
    80002da6:	f04a                	sd	s2,32(sp)
    80002da8:	ec4e                	sd	s3,24(sp)
    80002daa:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002dac:	fcc40593          	addi	a1,s0,-52
    80002db0:	4501                	li	a0,0
    80002db2:	00000097          	auipc	ra,0x0
    80002db6:	dfe080e7          	jalr	-514(ra) # 80002bb0 <argint>
    return -1;
    80002dba:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002dbc:	06054563          	bltz	a0,80002e26 <sys_sleep+0x88>
  acquire(&tickslock);
    80002dc0:	00015517          	auipc	a0,0x15
    80002dc4:	9a850513          	addi	a0,a0,-1624 # 80017768 <tickslock>
    80002dc8:	ffffe097          	auipc	ra,0xffffe
    80002dcc:	e48080e7          	jalr	-440(ra) # 80000c10 <acquire>
  ticks0 = ticks;
    80002dd0:	00006917          	auipc	s2,0x6
    80002dd4:	25092903          	lw	s2,592(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002dd8:	fcc42783          	lw	a5,-52(s0)
    80002ddc:	cf85                	beqz	a5,80002e14 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002dde:	00015997          	auipc	s3,0x15
    80002de2:	98a98993          	addi	s3,s3,-1654 # 80017768 <tickslock>
    80002de6:	00006497          	auipc	s1,0x6
    80002dea:	23a48493          	addi	s1,s1,570 # 80009020 <ticks>
    if(myproc()->killed){
    80002dee:	fffff097          	auipc	ra,0xfffff
    80002df2:	cd0080e7          	jalr	-816(ra) # 80001abe <myproc>
    80002df6:	591c                	lw	a5,48(a0)
    80002df8:	ef9d                	bnez	a5,80002e36 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002dfa:	85ce                	mv	a1,s3
    80002dfc:	8526                	mv	a0,s1
    80002dfe:	fffff097          	auipc	ra,0xfffff
    80002e02:	4d0080e7          	jalr	1232(ra) # 800022ce <sleep>
  while(ticks - ticks0 < n){
    80002e06:	409c                	lw	a5,0(s1)
    80002e08:	412787bb          	subw	a5,a5,s2
    80002e0c:	fcc42703          	lw	a4,-52(s0)
    80002e10:	fce7efe3          	bltu	a5,a4,80002dee <sys_sleep+0x50>
  }
  release(&tickslock);
    80002e14:	00015517          	auipc	a0,0x15
    80002e18:	95450513          	addi	a0,a0,-1708 # 80017768 <tickslock>
    80002e1c:	ffffe097          	auipc	ra,0xffffe
    80002e20:	ea8080e7          	jalr	-344(ra) # 80000cc4 <release>
  return 0;
    80002e24:	4781                	li	a5,0
}
    80002e26:	853e                	mv	a0,a5
    80002e28:	70e2                	ld	ra,56(sp)
    80002e2a:	7442                	ld	s0,48(sp)
    80002e2c:	74a2                	ld	s1,40(sp)
    80002e2e:	7902                	ld	s2,32(sp)
    80002e30:	69e2                	ld	s3,24(sp)
    80002e32:	6121                	addi	sp,sp,64
    80002e34:	8082                	ret
      release(&tickslock);
    80002e36:	00015517          	auipc	a0,0x15
    80002e3a:	93250513          	addi	a0,a0,-1742 # 80017768 <tickslock>
    80002e3e:	ffffe097          	auipc	ra,0xffffe
    80002e42:	e86080e7          	jalr	-378(ra) # 80000cc4 <release>
      return -1;
    80002e46:	57fd                	li	a5,-1
    80002e48:	bff9                	j	80002e26 <sys_sleep+0x88>

0000000080002e4a <sys_kill>:

uint64
sys_kill(void)
{
    80002e4a:	1101                	addi	sp,sp,-32
    80002e4c:	ec06                	sd	ra,24(sp)
    80002e4e:	e822                	sd	s0,16(sp)
    80002e50:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002e52:	fec40593          	addi	a1,s0,-20
    80002e56:	4501                	li	a0,0
    80002e58:	00000097          	auipc	ra,0x0
    80002e5c:	d58080e7          	jalr	-680(ra) # 80002bb0 <argint>
    80002e60:	87aa                	mv	a5,a0
    return -1;
    80002e62:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002e64:	0007c863          	bltz	a5,80002e74 <sys_kill+0x2a>
  return kill(pid);
    80002e68:	fec42503          	lw	a0,-20(s0)
    80002e6c:	fffff097          	auipc	ra,0xfffff
    80002e70:	652080e7          	jalr	1618(ra) # 800024be <kill>
}
    80002e74:	60e2                	ld	ra,24(sp)
    80002e76:	6442                	ld	s0,16(sp)
    80002e78:	6105                	addi	sp,sp,32
    80002e7a:	8082                	ret

0000000080002e7c <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e7c:	1101                	addi	sp,sp,-32
    80002e7e:	ec06                	sd	ra,24(sp)
    80002e80:	e822                	sd	s0,16(sp)
    80002e82:	e426                	sd	s1,8(sp)
    80002e84:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e86:	00015517          	auipc	a0,0x15
    80002e8a:	8e250513          	addi	a0,a0,-1822 # 80017768 <tickslock>
    80002e8e:	ffffe097          	auipc	ra,0xffffe
    80002e92:	d82080e7          	jalr	-638(ra) # 80000c10 <acquire>
  xticks = ticks;
    80002e96:	00006497          	auipc	s1,0x6
    80002e9a:	18a4a483          	lw	s1,394(s1) # 80009020 <ticks>
  release(&tickslock);
    80002e9e:	00015517          	auipc	a0,0x15
    80002ea2:	8ca50513          	addi	a0,a0,-1846 # 80017768 <tickslock>
    80002ea6:	ffffe097          	auipc	ra,0xffffe
    80002eaa:	e1e080e7          	jalr	-482(ra) # 80000cc4 <release>
  return xticks;
}
    80002eae:	02049513          	slli	a0,s1,0x20
    80002eb2:	9101                	srli	a0,a0,0x20
    80002eb4:	60e2                	ld	ra,24(sp)
    80002eb6:	6442                	ld	s0,16(sp)
    80002eb8:	64a2                	ld	s1,8(sp)
    80002eba:	6105                	addi	sp,sp,32
    80002ebc:	8082                	ret

0000000080002ebe <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002ebe:	7179                	addi	sp,sp,-48
    80002ec0:	f406                	sd	ra,40(sp)
    80002ec2:	f022                	sd	s0,32(sp)
    80002ec4:	ec26                	sd	s1,24(sp)
    80002ec6:	e84a                	sd	s2,16(sp)
    80002ec8:	e44e                	sd	s3,8(sp)
    80002eca:	e052                	sd	s4,0(sp)
    80002ecc:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002ece:	00005597          	auipc	a1,0x5
    80002ed2:	5e258593          	addi	a1,a1,1506 # 800084b0 <syscalls+0xb0>
    80002ed6:	00015517          	auipc	a0,0x15
    80002eda:	8aa50513          	addi	a0,a0,-1878 # 80017780 <bcache>
    80002ede:	ffffe097          	auipc	ra,0xffffe
    80002ee2:	ca2080e7          	jalr	-862(ra) # 80000b80 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002ee6:	0001d797          	auipc	a5,0x1d
    80002eea:	89a78793          	addi	a5,a5,-1894 # 8001f780 <bcache+0x8000>
    80002eee:	0001d717          	auipc	a4,0x1d
    80002ef2:	afa70713          	addi	a4,a4,-1286 # 8001f9e8 <bcache+0x8268>
    80002ef6:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002efa:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002efe:	00015497          	auipc	s1,0x15
    80002f02:	89a48493          	addi	s1,s1,-1894 # 80017798 <bcache+0x18>
    b->next = bcache.head.next;
    80002f06:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f08:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f0a:	00005a17          	auipc	s4,0x5
    80002f0e:	5aea0a13          	addi	s4,s4,1454 # 800084b8 <syscalls+0xb8>
    b->next = bcache.head.next;
    80002f12:	2b893783          	ld	a5,696(s2)
    80002f16:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f18:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f1c:	85d2                	mv	a1,s4
    80002f1e:	01048513          	addi	a0,s1,16
    80002f22:	00001097          	auipc	ra,0x1
    80002f26:	4b0080e7          	jalr	1200(ra) # 800043d2 <initsleeplock>
    bcache.head.next->prev = b;
    80002f2a:	2b893783          	ld	a5,696(s2)
    80002f2e:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f30:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f34:	45848493          	addi	s1,s1,1112
    80002f38:	fd349de3          	bne	s1,s3,80002f12 <binit+0x54>
  }
}
    80002f3c:	70a2                	ld	ra,40(sp)
    80002f3e:	7402                	ld	s0,32(sp)
    80002f40:	64e2                	ld	s1,24(sp)
    80002f42:	6942                	ld	s2,16(sp)
    80002f44:	69a2                	ld	s3,8(sp)
    80002f46:	6a02                	ld	s4,0(sp)
    80002f48:	6145                	addi	sp,sp,48
    80002f4a:	8082                	ret

0000000080002f4c <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f4c:	7179                	addi	sp,sp,-48
    80002f4e:	f406                	sd	ra,40(sp)
    80002f50:	f022                	sd	s0,32(sp)
    80002f52:	ec26                	sd	s1,24(sp)
    80002f54:	e84a                	sd	s2,16(sp)
    80002f56:	e44e                	sd	s3,8(sp)
    80002f58:	1800                	addi	s0,sp,48
    80002f5a:	89aa                	mv	s3,a0
    80002f5c:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002f5e:	00015517          	auipc	a0,0x15
    80002f62:	82250513          	addi	a0,a0,-2014 # 80017780 <bcache>
    80002f66:	ffffe097          	auipc	ra,0xffffe
    80002f6a:	caa080e7          	jalr	-854(ra) # 80000c10 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002f6e:	0001d497          	auipc	s1,0x1d
    80002f72:	aca4b483          	ld	s1,-1334(s1) # 8001fa38 <bcache+0x82b8>
    80002f76:	0001d797          	auipc	a5,0x1d
    80002f7a:	a7278793          	addi	a5,a5,-1422 # 8001f9e8 <bcache+0x8268>
    80002f7e:	02f48f63          	beq	s1,a5,80002fbc <bread+0x70>
    80002f82:	873e                	mv	a4,a5
    80002f84:	a021                	j	80002f8c <bread+0x40>
    80002f86:	68a4                	ld	s1,80(s1)
    80002f88:	02e48a63          	beq	s1,a4,80002fbc <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002f8c:	449c                	lw	a5,8(s1)
    80002f8e:	ff379ce3          	bne	a5,s3,80002f86 <bread+0x3a>
    80002f92:	44dc                	lw	a5,12(s1)
    80002f94:	ff2799e3          	bne	a5,s2,80002f86 <bread+0x3a>
      b->refcnt++;
    80002f98:	40bc                	lw	a5,64(s1)
    80002f9a:	2785                	addiw	a5,a5,1
    80002f9c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f9e:	00014517          	auipc	a0,0x14
    80002fa2:	7e250513          	addi	a0,a0,2018 # 80017780 <bcache>
    80002fa6:	ffffe097          	auipc	ra,0xffffe
    80002faa:	d1e080e7          	jalr	-738(ra) # 80000cc4 <release>
      acquiresleep(&b->lock);
    80002fae:	01048513          	addi	a0,s1,16
    80002fb2:	00001097          	auipc	ra,0x1
    80002fb6:	45a080e7          	jalr	1114(ra) # 8000440c <acquiresleep>
      return b;
    80002fba:	a8b9                	j	80003018 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fbc:	0001d497          	auipc	s1,0x1d
    80002fc0:	a744b483          	ld	s1,-1420(s1) # 8001fa30 <bcache+0x82b0>
    80002fc4:	0001d797          	auipc	a5,0x1d
    80002fc8:	a2478793          	addi	a5,a5,-1500 # 8001f9e8 <bcache+0x8268>
    80002fcc:	00f48863          	beq	s1,a5,80002fdc <bread+0x90>
    80002fd0:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002fd2:	40bc                	lw	a5,64(s1)
    80002fd4:	cf81                	beqz	a5,80002fec <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fd6:	64a4                	ld	s1,72(s1)
    80002fd8:	fee49de3          	bne	s1,a4,80002fd2 <bread+0x86>
  panic("bget: no buffers");
    80002fdc:	00005517          	auipc	a0,0x5
    80002fe0:	4e450513          	addi	a0,a0,1252 # 800084c0 <syscalls+0xc0>
    80002fe4:	ffffd097          	auipc	ra,0xffffd
    80002fe8:	564080e7          	jalr	1380(ra) # 80000548 <panic>
      b->dev = dev;
    80002fec:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80002ff0:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80002ff4:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002ff8:	4785                	li	a5,1
    80002ffa:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002ffc:	00014517          	auipc	a0,0x14
    80003000:	78450513          	addi	a0,a0,1924 # 80017780 <bcache>
    80003004:	ffffe097          	auipc	ra,0xffffe
    80003008:	cc0080e7          	jalr	-832(ra) # 80000cc4 <release>
      acquiresleep(&b->lock);
    8000300c:	01048513          	addi	a0,s1,16
    80003010:	00001097          	auipc	ra,0x1
    80003014:	3fc080e7          	jalr	1020(ra) # 8000440c <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003018:	409c                	lw	a5,0(s1)
    8000301a:	cb89                	beqz	a5,8000302c <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000301c:	8526                	mv	a0,s1
    8000301e:	70a2                	ld	ra,40(sp)
    80003020:	7402                	ld	s0,32(sp)
    80003022:	64e2                	ld	s1,24(sp)
    80003024:	6942                	ld	s2,16(sp)
    80003026:	69a2                	ld	s3,8(sp)
    80003028:	6145                	addi	sp,sp,48
    8000302a:	8082                	ret
    virtio_disk_rw(b, 0);
    8000302c:	4581                	li	a1,0
    8000302e:	8526                	mv	a0,s1
    80003030:	00003097          	auipc	ra,0x3
    80003034:	f3c080e7          	jalr	-196(ra) # 80005f6c <virtio_disk_rw>
    b->valid = 1;
    80003038:	4785                	li	a5,1
    8000303a:	c09c                	sw	a5,0(s1)
  return b;
    8000303c:	b7c5                	j	8000301c <bread+0xd0>

000000008000303e <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000303e:	1101                	addi	sp,sp,-32
    80003040:	ec06                	sd	ra,24(sp)
    80003042:	e822                	sd	s0,16(sp)
    80003044:	e426                	sd	s1,8(sp)
    80003046:	1000                	addi	s0,sp,32
    80003048:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000304a:	0541                	addi	a0,a0,16
    8000304c:	00001097          	auipc	ra,0x1
    80003050:	45a080e7          	jalr	1114(ra) # 800044a6 <holdingsleep>
    80003054:	cd01                	beqz	a0,8000306c <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003056:	4585                	li	a1,1
    80003058:	8526                	mv	a0,s1
    8000305a:	00003097          	auipc	ra,0x3
    8000305e:	f12080e7          	jalr	-238(ra) # 80005f6c <virtio_disk_rw>
}
    80003062:	60e2                	ld	ra,24(sp)
    80003064:	6442                	ld	s0,16(sp)
    80003066:	64a2                	ld	s1,8(sp)
    80003068:	6105                	addi	sp,sp,32
    8000306a:	8082                	ret
    panic("bwrite");
    8000306c:	00005517          	auipc	a0,0x5
    80003070:	46c50513          	addi	a0,a0,1132 # 800084d8 <syscalls+0xd8>
    80003074:	ffffd097          	auipc	ra,0xffffd
    80003078:	4d4080e7          	jalr	1236(ra) # 80000548 <panic>

000000008000307c <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000307c:	1101                	addi	sp,sp,-32
    8000307e:	ec06                	sd	ra,24(sp)
    80003080:	e822                	sd	s0,16(sp)
    80003082:	e426                	sd	s1,8(sp)
    80003084:	e04a                	sd	s2,0(sp)
    80003086:	1000                	addi	s0,sp,32
    80003088:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000308a:	01050913          	addi	s2,a0,16
    8000308e:	854a                	mv	a0,s2
    80003090:	00001097          	auipc	ra,0x1
    80003094:	416080e7          	jalr	1046(ra) # 800044a6 <holdingsleep>
    80003098:	c92d                	beqz	a0,8000310a <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000309a:	854a                	mv	a0,s2
    8000309c:	00001097          	auipc	ra,0x1
    800030a0:	3c6080e7          	jalr	966(ra) # 80004462 <releasesleep>

  acquire(&bcache.lock);
    800030a4:	00014517          	auipc	a0,0x14
    800030a8:	6dc50513          	addi	a0,a0,1756 # 80017780 <bcache>
    800030ac:	ffffe097          	auipc	ra,0xffffe
    800030b0:	b64080e7          	jalr	-1180(ra) # 80000c10 <acquire>
  b->refcnt--;
    800030b4:	40bc                	lw	a5,64(s1)
    800030b6:	37fd                	addiw	a5,a5,-1
    800030b8:	0007871b          	sext.w	a4,a5
    800030bc:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800030be:	eb05                	bnez	a4,800030ee <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800030c0:	68bc                	ld	a5,80(s1)
    800030c2:	64b8                	ld	a4,72(s1)
    800030c4:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800030c6:	64bc                	ld	a5,72(s1)
    800030c8:	68b8                	ld	a4,80(s1)
    800030ca:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800030cc:	0001c797          	auipc	a5,0x1c
    800030d0:	6b478793          	addi	a5,a5,1716 # 8001f780 <bcache+0x8000>
    800030d4:	2b87b703          	ld	a4,696(a5)
    800030d8:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800030da:	0001d717          	auipc	a4,0x1d
    800030de:	90e70713          	addi	a4,a4,-1778 # 8001f9e8 <bcache+0x8268>
    800030e2:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800030e4:	2b87b703          	ld	a4,696(a5)
    800030e8:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800030ea:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800030ee:	00014517          	auipc	a0,0x14
    800030f2:	69250513          	addi	a0,a0,1682 # 80017780 <bcache>
    800030f6:	ffffe097          	auipc	ra,0xffffe
    800030fa:	bce080e7          	jalr	-1074(ra) # 80000cc4 <release>
}
    800030fe:	60e2                	ld	ra,24(sp)
    80003100:	6442                	ld	s0,16(sp)
    80003102:	64a2                	ld	s1,8(sp)
    80003104:	6902                	ld	s2,0(sp)
    80003106:	6105                	addi	sp,sp,32
    80003108:	8082                	ret
    panic("brelse");
    8000310a:	00005517          	auipc	a0,0x5
    8000310e:	3d650513          	addi	a0,a0,982 # 800084e0 <syscalls+0xe0>
    80003112:	ffffd097          	auipc	ra,0xffffd
    80003116:	436080e7          	jalr	1078(ra) # 80000548 <panic>

000000008000311a <bpin>:

void
bpin(struct buf *b) {
    8000311a:	1101                	addi	sp,sp,-32
    8000311c:	ec06                	sd	ra,24(sp)
    8000311e:	e822                	sd	s0,16(sp)
    80003120:	e426                	sd	s1,8(sp)
    80003122:	1000                	addi	s0,sp,32
    80003124:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003126:	00014517          	auipc	a0,0x14
    8000312a:	65a50513          	addi	a0,a0,1626 # 80017780 <bcache>
    8000312e:	ffffe097          	auipc	ra,0xffffe
    80003132:	ae2080e7          	jalr	-1310(ra) # 80000c10 <acquire>
  b->refcnt++;
    80003136:	40bc                	lw	a5,64(s1)
    80003138:	2785                	addiw	a5,a5,1
    8000313a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000313c:	00014517          	auipc	a0,0x14
    80003140:	64450513          	addi	a0,a0,1604 # 80017780 <bcache>
    80003144:	ffffe097          	auipc	ra,0xffffe
    80003148:	b80080e7          	jalr	-1152(ra) # 80000cc4 <release>
}
    8000314c:	60e2                	ld	ra,24(sp)
    8000314e:	6442                	ld	s0,16(sp)
    80003150:	64a2                	ld	s1,8(sp)
    80003152:	6105                	addi	sp,sp,32
    80003154:	8082                	ret

0000000080003156 <bunpin>:

void
bunpin(struct buf *b) {
    80003156:	1101                	addi	sp,sp,-32
    80003158:	ec06                	sd	ra,24(sp)
    8000315a:	e822                	sd	s0,16(sp)
    8000315c:	e426                	sd	s1,8(sp)
    8000315e:	1000                	addi	s0,sp,32
    80003160:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003162:	00014517          	auipc	a0,0x14
    80003166:	61e50513          	addi	a0,a0,1566 # 80017780 <bcache>
    8000316a:	ffffe097          	auipc	ra,0xffffe
    8000316e:	aa6080e7          	jalr	-1370(ra) # 80000c10 <acquire>
  b->refcnt--;
    80003172:	40bc                	lw	a5,64(s1)
    80003174:	37fd                	addiw	a5,a5,-1
    80003176:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003178:	00014517          	auipc	a0,0x14
    8000317c:	60850513          	addi	a0,a0,1544 # 80017780 <bcache>
    80003180:	ffffe097          	auipc	ra,0xffffe
    80003184:	b44080e7          	jalr	-1212(ra) # 80000cc4 <release>
}
    80003188:	60e2                	ld	ra,24(sp)
    8000318a:	6442                	ld	s0,16(sp)
    8000318c:	64a2                	ld	s1,8(sp)
    8000318e:	6105                	addi	sp,sp,32
    80003190:	8082                	ret

0000000080003192 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003192:	1101                	addi	sp,sp,-32
    80003194:	ec06                	sd	ra,24(sp)
    80003196:	e822                	sd	s0,16(sp)
    80003198:	e426                	sd	s1,8(sp)
    8000319a:	e04a                	sd	s2,0(sp)
    8000319c:	1000                	addi	s0,sp,32
    8000319e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800031a0:	00d5d59b          	srliw	a1,a1,0xd
    800031a4:	0001d797          	auipc	a5,0x1d
    800031a8:	cb87a783          	lw	a5,-840(a5) # 8001fe5c <sb+0x1c>
    800031ac:	9dbd                	addw	a1,a1,a5
    800031ae:	00000097          	auipc	ra,0x0
    800031b2:	d9e080e7          	jalr	-610(ra) # 80002f4c <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800031b6:	0074f713          	andi	a4,s1,7
    800031ba:	4785                	li	a5,1
    800031bc:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800031c0:	14ce                	slli	s1,s1,0x33
    800031c2:	90d9                	srli	s1,s1,0x36
    800031c4:	00950733          	add	a4,a0,s1
    800031c8:	05874703          	lbu	a4,88(a4)
    800031cc:	00e7f6b3          	and	a3,a5,a4
    800031d0:	c69d                	beqz	a3,800031fe <bfree+0x6c>
    800031d2:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800031d4:	94aa                	add	s1,s1,a0
    800031d6:	fff7c793          	not	a5,a5
    800031da:	8ff9                	and	a5,a5,a4
    800031dc:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800031e0:	00001097          	auipc	ra,0x1
    800031e4:	104080e7          	jalr	260(ra) # 800042e4 <log_write>
  brelse(bp);
    800031e8:	854a                	mv	a0,s2
    800031ea:	00000097          	auipc	ra,0x0
    800031ee:	e92080e7          	jalr	-366(ra) # 8000307c <brelse>
}
    800031f2:	60e2                	ld	ra,24(sp)
    800031f4:	6442                	ld	s0,16(sp)
    800031f6:	64a2                	ld	s1,8(sp)
    800031f8:	6902                	ld	s2,0(sp)
    800031fa:	6105                	addi	sp,sp,32
    800031fc:	8082                	ret
    panic("freeing free block");
    800031fe:	00005517          	auipc	a0,0x5
    80003202:	2ea50513          	addi	a0,a0,746 # 800084e8 <syscalls+0xe8>
    80003206:	ffffd097          	auipc	ra,0xffffd
    8000320a:	342080e7          	jalr	834(ra) # 80000548 <panic>

000000008000320e <balloc>:
{
    8000320e:	711d                	addi	sp,sp,-96
    80003210:	ec86                	sd	ra,88(sp)
    80003212:	e8a2                	sd	s0,80(sp)
    80003214:	e4a6                	sd	s1,72(sp)
    80003216:	e0ca                	sd	s2,64(sp)
    80003218:	fc4e                	sd	s3,56(sp)
    8000321a:	f852                	sd	s4,48(sp)
    8000321c:	f456                	sd	s5,40(sp)
    8000321e:	f05a                	sd	s6,32(sp)
    80003220:	ec5e                	sd	s7,24(sp)
    80003222:	e862                	sd	s8,16(sp)
    80003224:	e466                	sd	s9,8(sp)
    80003226:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003228:	0001d797          	auipc	a5,0x1d
    8000322c:	c1c7a783          	lw	a5,-996(a5) # 8001fe44 <sb+0x4>
    80003230:	cbd1                	beqz	a5,800032c4 <balloc+0xb6>
    80003232:	8baa                	mv	s7,a0
    80003234:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003236:	0001db17          	auipc	s6,0x1d
    8000323a:	c0ab0b13          	addi	s6,s6,-1014 # 8001fe40 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000323e:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003240:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003242:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003244:	6c89                	lui	s9,0x2
    80003246:	a831                	j	80003262 <balloc+0x54>
    brelse(bp);
    80003248:	854a                	mv	a0,s2
    8000324a:	00000097          	auipc	ra,0x0
    8000324e:	e32080e7          	jalr	-462(ra) # 8000307c <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003252:	015c87bb          	addw	a5,s9,s5
    80003256:	00078a9b          	sext.w	s5,a5
    8000325a:	004b2703          	lw	a4,4(s6)
    8000325e:	06eaf363          	bgeu	s5,a4,800032c4 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003262:	41fad79b          	sraiw	a5,s5,0x1f
    80003266:	0137d79b          	srliw	a5,a5,0x13
    8000326a:	015787bb          	addw	a5,a5,s5
    8000326e:	40d7d79b          	sraiw	a5,a5,0xd
    80003272:	01cb2583          	lw	a1,28(s6)
    80003276:	9dbd                	addw	a1,a1,a5
    80003278:	855e                	mv	a0,s7
    8000327a:	00000097          	auipc	ra,0x0
    8000327e:	cd2080e7          	jalr	-814(ra) # 80002f4c <bread>
    80003282:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003284:	004b2503          	lw	a0,4(s6)
    80003288:	000a849b          	sext.w	s1,s5
    8000328c:	8662                	mv	a2,s8
    8000328e:	faa4fde3          	bgeu	s1,a0,80003248 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003292:	41f6579b          	sraiw	a5,a2,0x1f
    80003296:	01d7d69b          	srliw	a3,a5,0x1d
    8000329a:	00c6873b          	addw	a4,a3,a2
    8000329e:	00777793          	andi	a5,a4,7
    800032a2:	9f95                	subw	a5,a5,a3
    800032a4:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800032a8:	4037571b          	sraiw	a4,a4,0x3
    800032ac:	00e906b3          	add	a3,s2,a4
    800032b0:	0586c683          	lbu	a3,88(a3)
    800032b4:	00d7f5b3          	and	a1,a5,a3
    800032b8:	cd91                	beqz	a1,800032d4 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032ba:	2605                	addiw	a2,a2,1
    800032bc:	2485                	addiw	s1,s1,1
    800032be:	fd4618e3          	bne	a2,s4,8000328e <balloc+0x80>
    800032c2:	b759                	j	80003248 <balloc+0x3a>
  panic("balloc: out of blocks");
    800032c4:	00005517          	auipc	a0,0x5
    800032c8:	23c50513          	addi	a0,a0,572 # 80008500 <syscalls+0x100>
    800032cc:	ffffd097          	auipc	ra,0xffffd
    800032d0:	27c080e7          	jalr	636(ra) # 80000548 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800032d4:	974a                	add	a4,a4,s2
    800032d6:	8fd5                	or	a5,a5,a3
    800032d8:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800032dc:	854a                	mv	a0,s2
    800032de:	00001097          	auipc	ra,0x1
    800032e2:	006080e7          	jalr	6(ra) # 800042e4 <log_write>
        brelse(bp);
    800032e6:	854a                	mv	a0,s2
    800032e8:	00000097          	auipc	ra,0x0
    800032ec:	d94080e7          	jalr	-620(ra) # 8000307c <brelse>
  bp = bread(dev, bno);
    800032f0:	85a6                	mv	a1,s1
    800032f2:	855e                	mv	a0,s7
    800032f4:	00000097          	auipc	ra,0x0
    800032f8:	c58080e7          	jalr	-936(ra) # 80002f4c <bread>
    800032fc:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800032fe:	40000613          	li	a2,1024
    80003302:	4581                	li	a1,0
    80003304:	05850513          	addi	a0,a0,88
    80003308:	ffffe097          	auipc	ra,0xffffe
    8000330c:	a04080e7          	jalr	-1532(ra) # 80000d0c <memset>
  log_write(bp);
    80003310:	854a                	mv	a0,s2
    80003312:	00001097          	auipc	ra,0x1
    80003316:	fd2080e7          	jalr	-46(ra) # 800042e4 <log_write>
  brelse(bp);
    8000331a:	854a                	mv	a0,s2
    8000331c:	00000097          	auipc	ra,0x0
    80003320:	d60080e7          	jalr	-672(ra) # 8000307c <brelse>
}
    80003324:	8526                	mv	a0,s1
    80003326:	60e6                	ld	ra,88(sp)
    80003328:	6446                	ld	s0,80(sp)
    8000332a:	64a6                	ld	s1,72(sp)
    8000332c:	6906                	ld	s2,64(sp)
    8000332e:	79e2                	ld	s3,56(sp)
    80003330:	7a42                	ld	s4,48(sp)
    80003332:	7aa2                	ld	s5,40(sp)
    80003334:	7b02                	ld	s6,32(sp)
    80003336:	6be2                	ld	s7,24(sp)
    80003338:	6c42                	ld	s8,16(sp)
    8000333a:	6ca2                	ld	s9,8(sp)
    8000333c:	6125                	addi	sp,sp,96
    8000333e:	8082                	ret

0000000080003340 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003340:	7179                	addi	sp,sp,-48
    80003342:	f406                	sd	ra,40(sp)
    80003344:	f022                	sd	s0,32(sp)
    80003346:	ec26                	sd	s1,24(sp)
    80003348:	e84a                	sd	s2,16(sp)
    8000334a:	e44e                	sd	s3,8(sp)
    8000334c:	e052                	sd	s4,0(sp)
    8000334e:	1800                	addi	s0,sp,48
    80003350:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003352:	47ad                	li	a5,11
    80003354:	04b7fe63          	bgeu	a5,a1,800033b0 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003358:	ff45849b          	addiw	s1,a1,-12
    8000335c:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003360:	0ff00793          	li	a5,255
    80003364:	0ae7e363          	bltu	a5,a4,8000340a <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003368:	08052583          	lw	a1,128(a0)
    8000336c:	c5ad                	beqz	a1,800033d6 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000336e:	00092503          	lw	a0,0(s2)
    80003372:	00000097          	auipc	ra,0x0
    80003376:	bda080e7          	jalr	-1062(ra) # 80002f4c <bread>
    8000337a:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000337c:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003380:	02049593          	slli	a1,s1,0x20
    80003384:	9181                	srli	a1,a1,0x20
    80003386:	058a                	slli	a1,a1,0x2
    80003388:	00b784b3          	add	s1,a5,a1
    8000338c:	0004a983          	lw	s3,0(s1)
    80003390:	04098d63          	beqz	s3,800033ea <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003394:	8552                	mv	a0,s4
    80003396:	00000097          	auipc	ra,0x0
    8000339a:	ce6080e7          	jalr	-794(ra) # 8000307c <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000339e:	854e                	mv	a0,s3
    800033a0:	70a2                	ld	ra,40(sp)
    800033a2:	7402                	ld	s0,32(sp)
    800033a4:	64e2                	ld	s1,24(sp)
    800033a6:	6942                	ld	s2,16(sp)
    800033a8:	69a2                	ld	s3,8(sp)
    800033aa:	6a02                	ld	s4,0(sp)
    800033ac:	6145                	addi	sp,sp,48
    800033ae:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800033b0:	02059493          	slli	s1,a1,0x20
    800033b4:	9081                	srli	s1,s1,0x20
    800033b6:	048a                	slli	s1,s1,0x2
    800033b8:	94aa                	add	s1,s1,a0
    800033ba:	0504a983          	lw	s3,80(s1)
    800033be:	fe0990e3          	bnez	s3,8000339e <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800033c2:	4108                	lw	a0,0(a0)
    800033c4:	00000097          	auipc	ra,0x0
    800033c8:	e4a080e7          	jalr	-438(ra) # 8000320e <balloc>
    800033cc:	0005099b          	sext.w	s3,a0
    800033d0:	0534a823          	sw	s3,80(s1)
    800033d4:	b7e9                	j	8000339e <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800033d6:	4108                	lw	a0,0(a0)
    800033d8:	00000097          	auipc	ra,0x0
    800033dc:	e36080e7          	jalr	-458(ra) # 8000320e <balloc>
    800033e0:	0005059b          	sext.w	a1,a0
    800033e4:	08b92023          	sw	a1,128(s2)
    800033e8:	b759                	j	8000336e <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800033ea:	00092503          	lw	a0,0(s2)
    800033ee:	00000097          	auipc	ra,0x0
    800033f2:	e20080e7          	jalr	-480(ra) # 8000320e <balloc>
    800033f6:	0005099b          	sext.w	s3,a0
    800033fa:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800033fe:	8552                	mv	a0,s4
    80003400:	00001097          	auipc	ra,0x1
    80003404:	ee4080e7          	jalr	-284(ra) # 800042e4 <log_write>
    80003408:	b771                	j	80003394 <bmap+0x54>
  panic("bmap: out of range");
    8000340a:	00005517          	auipc	a0,0x5
    8000340e:	10e50513          	addi	a0,a0,270 # 80008518 <syscalls+0x118>
    80003412:	ffffd097          	auipc	ra,0xffffd
    80003416:	136080e7          	jalr	310(ra) # 80000548 <panic>

000000008000341a <iget>:
{
    8000341a:	7179                	addi	sp,sp,-48
    8000341c:	f406                	sd	ra,40(sp)
    8000341e:	f022                	sd	s0,32(sp)
    80003420:	ec26                	sd	s1,24(sp)
    80003422:	e84a                	sd	s2,16(sp)
    80003424:	e44e                	sd	s3,8(sp)
    80003426:	e052                	sd	s4,0(sp)
    80003428:	1800                	addi	s0,sp,48
    8000342a:	89aa                	mv	s3,a0
    8000342c:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    8000342e:	0001d517          	auipc	a0,0x1d
    80003432:	a3250513          	addi	a0,a0,-1486 # 8001fe60 <icache>
    80003436:	ffffd097          	auipc	ra,0xffffd
    8000343a:	7da080e7          	jalr	2010(ra) # 80000c10 <acquire>
  empty = 0;
    8000343e:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003440:	0001d497          	auipc	s1,0x1d
    80003444:	a3848493          	addi	s1,s1,-1480 # 8001fe78 <icache+0x18>
    80003448:	0001e697          	auipc	a3,0x1e
    8000344c:	4c068693          	addi	a3,a3,1216 # 80021908 <log>
    80003450:	a039                	j	8000345e <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003452:	02090b63          	beqz	s2,80003488 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003456:	08848493          	addi	s1,s1,136
    8000345a:	02d48a63          	beq	s1,a3,8000348e <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000345e:	449c                	lw	a5,8(s1)
    80003460:	fef059e3          	blez	a5,80003452 <iget+0x38>
    80003464:	4098                	lw	a4,0(s1)
    80003466:	ff3716e3          	bne	a4,s3,80003452 <iget+0x38>
    8000346a:	40d8                	lw	a4,4(s1)
    8000346c:	ff4713e3          	bne	a4,s4,80003452 <iget+0x38>
      ip->ref++;
    80003470:	2785                	addiw	a5,a5,1
    80003472:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    80003474:	0001d517          	auipc	a0,0x1d
    80003478:	9ec50513          	addi	a0,a0,-1556 # 8001fe60 <icache>
    8000347c:	ffffe097          	auipc	ra,0xffffe
    80003480:	848080e7          	jalr	-1976(ra) # 80000cc4 <release>
      return ip;
    80003484:	8926                	mv	s2,s1
    80003486:	a03d                	j	800034b4 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003488:	f7f9                	bnez	a5,80003456 <iget+0x3c>
    8000348a:	8926                	mv	s2,s1
    8000348c:	b7e9                	j	80003456 <iget+0x3c>
  if(empty == 0)
    8000348e:	02090c63          	beqz	s2,800034c6 <iget+0xac>
  ip->dev = dev;
    80003492:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003496:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000349a:	4785                	li	a5,1
    8000349c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800034a0:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    800034a4:	0001d517          	auipc	a0,0x1d
    800034a8:	9bc50513          	addi	a0,a0,-1604 # 8001fe60 <icache>
    800034ac:	ffffe097          	auipc	ra,0xffffe
    800034b0:	818080e7          	jalr	-2024(ra) # 80000cc4 <release>
}
    800034b4:	854a                	mv	a0,s2
    800034b6:	70a2                	ld	ra,40(sp)
    800034b8:	7402                	ld	s0,32(sp)
    800034ba:	64e2                	ld	s1,24(sp)
    800034bc:	6942                	ld	s2,16(sp)
    800034be:	69a2                	ld	s3,8(sp)
    800034c0:	6a02                	ld	s4,0(sp)
    800034c2:	6145                	addi	sp,sp,48
    800034c4:	8082                	ret
    panic("iget: no inodes");
    800034c6:	00005517          	auipc	a0,0x5
    800034ca:	06a50513          	addi	a0,a0,106 # 80008530 <syscalls+0x130>
    800034ce:	ffffd097          	auipc	ra,0xffffd
    800034d2:	07a080e7          	jalr	122(ra) # 80000548 <panic>

00000000800034d6 <fsinit>:
fsinit(int dev) {
    800034d6:	7179                	addi	sp,sp,-48
    800034d8:	f406                	sd	ra,40(sp)
    800034da:	f022                	sd	s0,32(sp)
    800034dc:	ec26                	sd	s1,24(sp)
    800034de:	e84a                	sd	s2,16(sp)
    800034e0:	e44e                	sd	s3,8(sp)
    800034e2:	1800                	addi	s0,sp,48
    800034e4:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800034e6:	4585                	li	a1,1
    800034e8:	00000097          	auipc	ra,0x0
    800034ec:	a64080e7          	jalr	-1436(ra) # 80002f4c <bread>
    800034f0:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800034f2:	0001d997          	auipc	s3,0x1d
    800034f6:	94e98993          	addi	s3,s3,-1714 # 8001fe40 <sb>
    800034fa:	02000613          	li	a2,32
    800034fe:	05850593          	addi	a1,a0,88
    80003502:	854e                	mv	a0,s3
    80003504:	ffffe097          	auipc	ra,0xffffe
    80003508:	868080e7          	jalr	-1944(ra) # 80000d6c <memmove>
  brelse(bp);
    8000350c:	8526                	mv	a0,s1
    8000350e:	00000097          	auipc	ra,0x0
    80003512:	b6e080e7          	jalr	-1170(ra) # 8000307c <brelse>
  if(sb.magic != FSMAGIC)
    80003516:	0009a703          	lw	a4,0(s3)
    8000351a:	102037b7          	lui	a5,0x10203
    8000351e:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003522:	02f71263          	bne	a4,a5,80003546 <fsinit+0x70>
  initlog(dev, &sb);
    80003526:	0001d597          	auipc	a1,0x1d
    8000352a:	91a58593          	addi	a1,a1,-1766 # 8001fe40 <sb>
    8000352e:	854a                	mv	a0,s2
    80003530:	00001097          	auipc	ra,0x1
    80003534:	b3c080e7          	jalr	-1220(ra) # 8000406c <initlog>
}
    80003538:	70a2                	ld	ra,40(sp)
    8000353a:	7402                	ld	s0,32(sp)
    8000353c:	64e2                	ld	s1,24(sp)
    8000353e:	6942                	ld	s2,16(sp)
    80003540:	69a2                	ld	s3,8(sp)
    80003542:	6145                	addi	sp,sp,48
    80003544:	8082                	ret
    panic("invalid file system");
    80003546:	00005517          	auipc	a0,0x5
    8000354a:	ffa50513          	addi	a0,a0,-6 # 80008540 <syscalls+0x140>
    8000354e:	ffffd097          	auipc	ra,0xffffd
    80003552:	ffa080e7          	jalr	-6(ra) # 80000548 <panic>

0000000080003556 <iinit>:
{
    80003556:	7179                	addi	sp,sp,-48
    80003558:	f406                	sd	ra,40(sp)
    8000355a:	f022                	sd	s0,32(sp)
    8000355c:	ec26                	sd	s1,24(sp)
    8000355e:	e84a                	sd	s2,16(sp)
    80003560:	e44e                	sd	s3,8(sp)
    80003562:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    80003564:	00005597          	auipc	a1,0x5
    80003568:	ff458593          	addi	a1,a1,-12 # 80008558 <syscalls+0x158>
    8000356c:	0001d517          	auipc	a0,0x1d
    80003570:	8f450513          	addi	a0,a0,-1804 # 8001fe60 <icache>
    80003574:	ffffd097          	auipc	ra,0xffffd
    80003578:	60c080e7          	jalr	1548(ra) # 80000b80 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000357c:	0001d497          	auipc	s1,0x1d
    80003580:	90c48493          	addi	s1,s1,-1780 # 8001fe88 <icache+0x28>
    80003584:	0001e997          	auipc	s3,0x1e
    80003588:	39498993          	addi	s3,s3,916 # 80021918 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    8000358c:	00005917          	auipc	s2,0x5
    80003590:	fd490913          	addi	s2,s2,-44 # 80008560 <syscalls+0x160>
    80003594:	85ca                	mv	a1,s2
    80003596:	8526                	mv	a0,s1
    80003598:	00001097          	auipc	ra,0x1
    8000359c:	e3a080e7          	jalr	-454(ra) # 800043d2 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800035a0:	08848493          	addi	s1,s1,136
    800035a4:	ff3498e3          	bne	s1,s3,80003594 <iinit+0x3e>
}
    800035a8:	70a2                	ld	ra,40(sp)
    800035aa:	7402                	ld	s0,32(sp)
    800035ac:	64e2                	ld	s1,24(sp)
    800035ae:	6942                	ld	s2,16(sp)
    800035b0:	69a2                	ld	s3,8(sp)
    800035b2:	6145                	addi	sp,sp,48
    800035b4:	8082                	ret

00000000800035b6 <ialloc>:
{
    800035b6:	715d                	addi	sp,sp,-80
    800035b8:	e486                	sd	ra,72(sp)
    800035ba:	e0a2                	sd	s0,64(sp)
    800035bc:	fc26                	sd	s1,56(sp)
    800035be:	f84a                	sd	s2,48(sp)
    800035c0:	f44e                	sd	s3,40(sp)
    800035c2:	f052                	sd	s4,32(sp)
    800035c4:	ec56                	sd	s5,24(sp)
    800035c6:	e85a                	sd	s6,16(sp)
    800035c8:	e45e                	sd	s7,8(sp)
    800035ca:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800035cc:	0001d717          	auipc	a4,0x1d
    800035d0:	88072703          	lw	a4,-1920(a4) # 8001fe4c <sb+0xc>
    800035d4:	4785                	li	a5,1
    800035d6:	04e7fa63          	bgeu	a5,a4,8000362a <ialloc+0x74>
    800035da:	8aaa                	mv	s5,a0
    800035dc:	8bae                	mv	s7,a1
    800035de:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800035e0:	0001da17          	auipc	s4,0x1d
    800035e4:	860a0a13          	addi	s4,s4,-1952 # 8001fe40 <sb>
    800035e8:	00048b1b          	sext.w	s6,s1
    800035ec:	0044d593          	srli	a1,s1,0x4
    800035f0:	018a2783          	lw	a5,24(s4)
    800035f4:	9dbd                	addw	a1,a1,a5
    800035f6:	8556                	mv	a0,s5
    800035f8:	00000097          	auipc	ra,0x0
    800035fc:	954080e7          	jalr	-1708(ra) # 80002f4c <bread>
    80003600:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003602:	05850993          	addi	s3,a0,88
    80003606:	00f4f793          	andi	a5,s1,15
    8000360a:	079a                	slli	a5,a5,0x6
    8000360c:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000360e:	00099783          	lh	a5,0(s3)
    80003612:	c785                	beqz	a5,8000363a <ialloc+0x84>
    brelse(bp);
    80003614:	00000097          	auipc	ra,0x0
    80003618:	a68080e7          	jalr	-1432(ra) # 8000307c <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000361c:	0485                	addi	s1,s1,1
    8000361e:	00ca2703          	lw	a4,12(s4)
    80003622:	0004879b          	sext.w	a5,s1
    80003626:	fce7e1e3          	bltu	a5,a4,800035e8 <ialloc+0x32>
  panic("ialloc: no inodes");
    8000362a:	00005517          	auipc	a0,0x5
    8000362e:	f3e50513          	addi	a0,a0,-194 # 80008568 <syscalls+0x168>
    80003632:	ffffd097          	auipc	ra,0xffffd
    80003636:	f16080e7          	jalr	-234(ra) # 80000548 <panic>
      memset(dip, 0, sizeof(*dip));
    8000363a:	04000613          	li	a2,64
    8000363e:	4581                	li	a1,0
    80003640:	854e                	mv	a0,s3
    80003642:	ffffd097          	auipc	ra,0xffffd
    80003646:	6ca080e7          	jalr	1738(ra) # 80000d0c <memset>
      dip->type = type;
    8000364a:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000364e:	854a                	mv	a0,s2
    80003650:	00001097          	auipc	ra,0x1
    80003654:	c94080e7          	jalr	-876(ra) # 800042e4 <log_write>
      brelse(bp);
    80003658:	854a                	mv	a0,s2
    8000365a:	00000097          	auipc	ra,0x0
    8000365e:	a22080e7          	jalr	-1502(ra) # 8000307c <brelse>
      return iget(dev, inum);
    80003662:	85da                	mv	a1,s6
    80003664:	8556                	mv	a0,s5
    80003666:	00000097          	auipc	ra,0x0
    8000366a:	db4080e7          	jalr	-588(ra) # 8000341a <iget>
}
    8000366e:	60a6                	ld	ra,72(sp)
    80003670:	6406                	ld	s0,64(sp)
    80003672:	74e2                	ld	s1,56(sp)
    80003674:	7942                	ld	s2,48(sp)
    80003676:	79a2                	ld	s3,40(sp)
    80003678:	7a02                	ld	s4,32(sp)
    8000367a:	6ae2                	ld	s5,24(sp)
    8000367c:	6b42                	ld	s6,16(sp)
    8000367e:	6ba2                	ld	s7,8(sp)
    80003680:	6161                	addi	sp,sp,80
    80003682:	8082                	ret

0000000080003684 <iupdate>:
{
    80003684:	1101                	addi	sp,sp,-32
    80003686:	ec06                	sd	ra,24(sp)
    80003688:	e822                	sd	s0,16(sp)
    8000368a:	e426                	sd	s1,8(sp)
    8000368c:	e04a                	sd	s2,0(sp)
    8000368e:	1000                	addi	s0,sp,32
    80003690:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003692:	415c                	lw	a5,4(a0)
    80003694:	0047d79b          	srliw	a5,a5,0x4
    80003698:	0001c597          	auipc	a1,0x1c
    8000369c:	7c05a583          	lw	a1,1984(a1) # 8001fe58 <sb+0x18>
    800036a0:	9dbd                	addw	a1,a1,a5
    800036a2:	4108                	lw	a0,0(a0)
    800036a4:	00000097          	auipc	ra,0x0
    800036a8:	8a8080e7          	jalr	-1880(ra) # 80002f4c <bread>
    800036ac:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800036ae:	05850793          	addi	a5,a0,88
    800036b2:	40c8                	lw	a0,4(s1)
    800036b4:	893d                	andi	a0,a0,15
    800036b6:	051a                	slli	a0,a0,0x6
    800036b8:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800036ba:	04449703          	lh	a4,68(s1)
    800036be:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800036c2:	04649703          	lh	a4,70(s1)
    800036c6:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800036ca:	04849703          	lh	a4,72(s1)
    800036ce:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800036d2:	04a49703          	lh	a4,74(s1)
    800036d6:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800036da:	44f8                	lw	a4,76(s1)
    800036dc:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800036de:	03400613          	li	a2,52
    800036e2:	05048593          	addi	a1,s1,80
    800036e6:	0531                	addi	a0,a0,12
    800036e8:	ffffd097          	auipc	ra,0xffffd
    800036ec:	684080e7          	jalr	1668(ra) # 80000d6c <memmove>
  log_write(bp);
    800036f0:	854a                	mv	a0,s2
    800036f2:	00001097          	auipc	ra,0x1
    800036f6:	bf2080e7          	jalr	-1038(ra) # 800042e4 <log_write>
  brelse(bp);
    800036fa:	854a                	mv	a0,s2
    800036fc:	00000097          	auipc	ra,0x0
    80003700:	980080e7          	jalr	-1664(ra) # 8000307c <brelse>
}
    80003704:	60e2                	ld	ra,24(sp)
    80003706:	6442                	ld	s0,16(sp)
    80003708:	64a2                	ld	s1,8(sp)
    8000370a:	6902                	ld	s2,0(sp)
    8000370c:	6105                	addi	sp,sp,32
    8000370e:	8082                	ret

0000000080003710 <idup>:
{
    80003710:	1101                	addi	sp,sp,-32
    80003712:	ec06                	sd	ra,24(sp)
    80003714:	e822                	sd	s0,16(sp)
    80003716:	e426                	sd	s1,8(sp)
    80003718:	1000                	addi	s0,sp,32
    8000371a:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    8000371c:	0001c517          	auipc	a0,0x1c
    80003720:	74450513          	addi	a0,a0,1860 # 8001fe60 <icache>
    80003724:	ffffd097          	auipc	ra,0xffffd
    80003728:	4ec080e7          	jalr	1260(ra) # 80000c10 <acquire>
  ip->ref++;
    8000372c:	449c                	lw	a5,8(s1)
    8000372e:	2785                	addiw	a5,a5,1
    80003730:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003732:	0001c517          	auipc	a0,0x1c
    80003736:	72e50513          	addi	a0,a0,1838 # 8001fe60 <icache>
    8000373a:	ffffd097          	auipc	ra,0xffffd
    8000373e:	58a080e7          	jalr	1418(ra) # 80000cc4 <release>
}
    80003742:	8526                	mv	a0,s1
    80003744:	60e2                	ld	ra,24(sp)
    80003746:	6442                	ld	s0,16(sp)
    80003748:	64a2                	ld	s1,8(sp)
    8000374a:	6105                	addi	sp,sp,32
    8000374c:	8082                	ret

000000008000374e <ilock>:
{
    8000374e:	1101                	addi	sp,sp,-32
    80003750:	ec06                	sd	ra,24(sp)
    80003752:	e822                	sd	s0,16(sp)
    80003754:	e426                	sd	s1,8(sp)
    80003756:	e04a                	sd	s2,0(sp)
    80003758:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000375a:	c115                	beqz	a0,8000377e <ilock+0x30>
    8000375c:	84aa                	mv	s1,a0
    8000375e:	451c                	lw	a5,8(a0)
    80003760:	00f05f63          	blez	a5,8000377e <ilock+0x30>
  acquiresleep(&ip->lock);
    80003764:	0541                	addi	a0,a0,16
    80003766:	00001097          	auipc	ra,0x1
    8000376a:	ca6080e7          	jalr	-858(ra) # 8000440c <acquiresleep>
  if(ip->valid == 0){
    8000376e:	40bc                	lw	a5,64(s1)
    80003770:	cf99                	beqz	a5,8000378e <ilock+0x40>
}
    80003772:	60e2                	ld	ra,24(sp)
    80003774:	6442                	ld	s0,16(sp)
    80003776:	64a2                	ld	s1,8(sp)
    80003778:	6902                	ld	s2,0(sp)
    8000377a:	6105                	addi	sp,sp,32
    8000377c:	8082                	ret
    panic("ilock");
    8000377e:	00005517          	auipc	a0,0x5
    80003782:	e0250513          	addi	a0,a0,-510 # 80008580 <syscalls+0x180>
    80003786:	ffffd097          	auipc	ra,0xffffd
    8000378a:	dc2080e7          	jalr	-574(ra) # 80000548 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000378e:	40dc                	lw	a5,4(s1)
    80003790:	0047d79b          	srliw	a5,a5,0x4
    80003794:	0001c597          	auipc	a1,0x1c
    80003798:	6c45a583          	lw	a1,1732(a1) # 8001fe58 <sb+0x18>
    8000379c:	9dbd                	addw	a1,a1,a5
    8000379e:	4088                	lw	a0,0(s1)
    800037a0:	fffff097          	auipc	ra,0xfffff
    800037a4:	7ac080e7          	jalr	1964(ra) # 80002f4c <bread>
    800037a8:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037aa:	05850593          	addi	a1,a0,88
    800037ae:	40dc                	lw	a5,4(s1)
    800037b0:	8bbd                	andi	a5,a5,15
    800037b2:	079a                	slli	a5,a5,0x6
    800037b4:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800037b6:	00059783          	lh	a5,0(a1)
    800037ba:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800037be:	00259783          	lh	a5,2(a1)
    800037c2:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800037c6:	00459783          	lh	a5,4(a1)
    800037ca:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800037ce:	00659783          	lh	a5,6(a1)
    800037d2:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800037d6:	459c                	lw	a5,8(a1)
    800037d8:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800037da:	03400613          	li	a2,52
    800037de:	05b1                	addi	a1,a1,12
    800037e0:	05048513          	addi	a0,s1,80
    800037e4:	ffffd097          	auipc	ra,0xffffd
    800037e8:	588080e7          	jalr	1416(ra) # 80000d6c <memmove>
    brelse(bp);
    800037ec:	854a                	mv	a0,s2
    800037ee:	00000097          	auipc	ra,0x0
    800037f2:	88e080e7          	jalr	-1906(ra) # 8000307c <brelse>
    ip->valid = 1;
    800037f6:	4785                	li	a5,1
    800037f8:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800037fa:	04449783          	lh	a5,68(s1)
    800037fe:	fbb5                	bnez	a5,80003772 <ilock+0x24>
      panic("ilock: no type");
    80003800:	00005517          	auipc	a0,0x5
    80003804:	d8850513          	addi	a0,a0,-632 # 80008588 <syscalls+0x188>
    80003808:	ffffd097          	auipc	ra,0xffffd
    8000380c:	d40080e7          	jalr	-704(ra) # 80000548 <panic>

0000000080003810 <iunlock>:
{
    80003810:	1101                	addi	sp,sp,-32
    80003812:	ec06                	sd	ra,24(sp)
    80003814:	e822                	sd	s0,16(sp)
    80003816:	e426                	sd	s1,8(sp)
    80003818:	e04a                	sd	s2,0(sp)
    8000381a:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000381c:	c905                	beqz	a0,8000384c <iunlock+0x3c>
    8000381e:	84aa                	mv	s1,a0
    80003820:	01050913          	addi	s2,a0,16
    80003824:	854a                	mv	a0,s2
    80003826:	00001097          	auipc	ra,0x1
    8000382a:	c80080e7          	jalr	-896(ra) # 800044a6 <holdingsleep>
    8000382e:	cd19                	beqz	a0,8000384c <iunlock+0x3c>
    80003830:	449c                	lw	a5,8(s1)
    80003832:	00f05d63          	blez	a5,8000384c <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003836:	854a                	mv	a0,s2
    80003838:	00001097          	auipc	ra,0x1
    8000383c:	c2a080e7          	jalr	-982(ra) # 80004462 <releasesleep>
}
    80003840:	60e2                	ld	ra,24(sp)
    80003842:	6442                	ld	s0,16(sp)
    80003844:	64a2                	ld	s1,8(sp)
    80003846:	6902                	ld	s2,0(sp)
    80003848:	6105                	addi	sp,sp,32
    8000384a:	8082                	ret
    panic("iunlock");
    8000384c:	00005517          	auipc	a0,0x5
    80003850:	d4c50513          	addi	a0,a0,-692 # 80008598 <syscalls+0x198>
    80003854:	ffffd097          	auipc	ra,0xffffd
    80003858:	cf4080e7          	jalr	-780(ra) # 80000548 <panic>

000000008000385c <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000385c:	7179                	addi	sp,sp,-48
    8000385e:	f406                	sd	ra,40(sp)
    80003860:	f022                	sd	s0,32(sp)
    80003862:	ec26                	sd	s1,24(sp)
    80003864:	e84a                	sd	s2,16(sp)
    80003866:	e44e                	sd	s3,8(sp)
    80003868:	e052                	sd	s4,0(sp)
    8000386a:	1800                	addi	s0,sp,48
    8000386c:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000386e:	05050493          	addi	s1,a0,80
    80003872:	08050913          	addi	s2,a0,128
    80003876:	a021                	j	8000387e <itrunc+0x22>
    80003878:	0491                	addi	s1,s1,4
    8000387a:	01248d63          	beq	s1,s2,80003894 <itrunc+0x38>
    if(ip->addrs[i]){
    8000387e:	408c                	lw	a1,0(s1)
    80003880:	dde5                	beqz	a1,80003878 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003882:	0009a503          	lw	a0,0(s3)
    80003886:	00000097          	auipc	ra,0x0
    8000388a:	90c080e7          	jalr	-1780(ra) # 80003192 <bfree>
      ip->addrs[i] = 0;
    8000388e:	0004a023          	sw	zero,0(s1)
    80003892:	b7dd                	j	80003878 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003894:	0809a583          	lw	a1,128(s3)
    80003898:	e185                	bnez	a1,800038b8 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000389a:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000389e:	854e                	mv	a0,s3
    800038a0:	00000097          	auipc	ra,0x0
    800038a4:	de4080e7          	jalr	-540(ra) # 80003684 <iupdate>
}
    800038a8:	70a2                	ld	ra,40(sp)
    800038aa:	7402                	ld	s0,32(sp)
    800038ac:	64e2                	ld	s1,24(sp)
    800038ae:	6942                	ld	s2,16(sp)
    800038b0:	69a2                	ld	s3,8(sp)
    800038b2:	6a02                	ld	s4,0(sp)
    800038b4:	6145                	addi	sp,sp,48
    800038b6:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800038b8:	0009a503          	lw	a0,0(s3)
    800038bc:	fffff097          	auipc	ra,0xfffff
    800038c0:	690080e7          	jalr	1680(ra) # 80002f4c <bread>
    800038c4:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800038c6:	05850493          	addi	s1,a0,88
    800038ca:	45850913          	addi	s2,a0,1112
    800038ce:	a811                	j	800038e2 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    800038d0:	0009a503          	lw	a0,0(s3)
    800038d4:	00000097          	auipc	ra,0x0
    800038d8:	8be080e7          	jalr	-1858(ra) # 80003192 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    800038dc:	0491                	addi	s1,s1,4
    800038de:	01248563          	beq	s1,s2,800038e8 <itrunc+0x8c>
      if(a[j])
    800038e2:	408c                	lw	a1,0(s1)
    800038e4:	dde5                	beqz	a1,800038dc <itrunc+0x80>
    800038e6:	b7ed                	j	800038d0 <itrunc+0x74>
    brelse(bp);
    800038e8:	8552                	mv	a0,s4
    800038ea:	fffff097          	auipc	ra,0xfffff
    800038ee:	792080e7          	jalr	1938(ra) # 8000307c <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800038f2:	0809a583          	lw	a1,128(s3)
    800038f6:	0009a503          	lw	a0,0(s3)
    800038fa:	00000097          	auipc	ra,0x0
    800038fe:	898080e7          	jalr	-1896(ra) # 80003192 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003902:	0809a023          	sw	zero,128(s3)
    80003906:	bf51                	j	8000389a <itrunc+0x3e>

0000000080003908 <iput>:
{
    80003908:	1101                	addi	sp,sp,-32
    8000390a:	ec06                	sd	ra,24(sp)
    8000390c:	e822                	sd	s0,16(sp)
    8000390e:	e426                	sd	s1,8(sp)
    80003910:	e04a                	sd	s2,0(sp)
    80003912:	1000                	addi	s0,sp,32
    80003914:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003916:	0001c517          	auipc	a0,0x1c
    8000391a:	54a50513          	addi	a0,a0,1354 # 8001fe60 <icache>
    8000391e:	ffffd097          	auipc	ra,0xffffd
    80003922:	2f2080e7          	jalr	754(ra) # 80000c10 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003926:	4498                	lw	a4,8(s1)
    80003928:	4785                	li	a5,1
    8000392a:	02f70363          	beq	a4,a5,80003950 <iput+0x48>
  ip->ref--;
    8000392e:	449c                	lw	a5,8(s1)
    80003930:	37fd                	addiw	a5,a5,-1
    80003932:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003934:	0001c517          	auipc	a0,0x1c
    80003938:	52c50513          	addi	a0,a0,1324 # 8001fe60 <icache>
    8000393c:	ffffd097          	auipc	ra,0xffffd
    80003940:	388080e7          	jalr	904(ra) # 80000cc4 <release>
}
    80003944:	60e2                	ld	ra,24(sp)
    80003946:	6442                	ld	s0,16(sp)
    80003948:	64a2                	ld	s1,8(sp)
    8000394a:	6902                	ld	s2,0(sp)
    8000394c:	6105                	addi	sp,sp,32
    8000394e:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003950:	40bc                	lw	a5,64(s1)
    80003952:	dff1                	beqz	a5,8000392e <iput+0x26>
    80003954:	04a49783          	lh	a5,74(s1)
    80003958:	fbf9                	bnez	a5,8000392e <iput+0x26>
    acquiresleep(&ip->lock);
    8000395a:	01048913          	addi	s2,s1,16
    8000395e:	854a                	mv	a0,s2
    80003960:	00001097          	auipc	ra,0x1
    80003964:	aac080e7          	jalr	-1364(ra) # 8000440c <acquiresleep>
    release(&icache.lock);
    80003968:	0001c517          	auipc	a0,0x1c
    8000396c:	4f850513          	addi	a0,a0,1272 # 8001fe60 <icache>
    80003970:	ffffd097          	auipc	ra,0xffffd
    80003974:	354080e7          	jalr	852(ra) # 80000cc4 <release>
    itrunc(ip);
    80003978:	8526                	mv	a0,s1
    8000397a:	00000097          	auipc	ra,0x0
    8000397e:	ee2080e7          	jalr	-286(ra) # 8000385c <itrunc>
    ip->type = 0;
    80003982:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003986:	8526                	mv	a0,s1
    80003988:	00000097          	auipc	ra,0x0
    8000398c:	cfc080e7          	jalr	-772(ra) # 80003684 <iupdate>
    ip->valid = 0;
    80003990:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003994:	854a                	mv	a0,s2
    80003996:	00001097          	auipc	ra,0x1
    8000399a:	acc080e7          	jalr	-1332(ra) # 80004462 <releasesleep>
    acquire(&icache.lock);
    8000399e:	0001c517          	auipc	a0,0x1c
    800039a2:	4c250513          	addi	a0,a0,1218 # 8001fe60 <icache>
    800039a6:	ffffd097          	auipc	ra,0xffffd
    800039aa:	26a080e7          	jalr	618(ra) # 80000c10 <acquire>
    800039ae:	b741                	j	8000392e <iput+0x26>

00000000800039b0 <iunlockput>:
{
    800039b0:	1101                	addi	sp,sp,-32
    800039b2:	ec06                	sd	ra,24(sp)
    800039b4:	e822                	sd	s0,16(sp)
    800039b6:	e426                	sd	s1,8(sp)
    800039b8:	1000                	addi	s0,sp,32
    800039ba:	84aa                	mv	s1,a0
  iunlock(ip);
    800039bc:	00000097          	auipc	ra,0x0
    800039c0:	e54080e7          	jalr	-428(ra) # 80003810 <iunlock>
  iput(ip);
    800039c4:	8526                	mv	a0,s1
    800039c6:	00000097          	auipc	ra,0x0
    800039ca:	f42080e7          	jalr	-190(ra) # 80003908 <iput>
}
    800039ce:	60e2                	ld	ra,24(sp)
    800039d0:	6442                	ld	s0,16(sp)
    800039d2:	64a2                	ld	s1,8(sp)
    800039d4:	6105                	addi	sp,sp,32
    800039d6:	8082                	ret

00000000800039d8 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800039d8:	1141                	addi	sp,sp,-16
    800039da:	e422                	sd	s0,8(sp)
    800039dc:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800039de:	411c                	lw	a5,0(a0)
    800039e0:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800039e2:	415c                	lw	a5,4(a0)
    800039e4:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800039e6:	04451783          	lh	a5,68(a0)
    800039ea:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800039ee:	04a51783          	lh	a5,74(a0)
    800039f2:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800039f6:	04c56783          	lwu	a5,76(a0)
    800039fa:	e99c                	sd	a5,16(a1)
}
    800039fc:	6422                	ld	s0,8(sp)
    800039fe:	0141                	addi	sp,sp,16
    80003a00:	8082                	ret

0000000080003a02 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a02:	457c                	lw	a5,76(a0)
    80003a04:	0ed7e963          	bltu	a5,a3,80003af6 <readi+0xf4>
{
    80003a08:	7159                	addi	sp,sp,-112
    80003a0a:	f486                	sd	ra,104(sp)
    80003a0c:	f0a2                	sd	s0,96(sp)
    80003a0e:	eca6                	sd	s1,88(sp)
    80003a10:	e8ca                	sd	s2,80(sp)
    80003a12:	e4ce                	sd	s3,72(sp)
    80003a14:	e0d2                	sd	s4,64(sp)
    80003a16:	fc56                	sd	s5,56(sp)
    80003a18:	f85a                	sd	s6,48(sp)
    80003a1a:	f45e                	sd	s7,40(sp)
    80003a1c:	f062                	sd	s8,32(sp)
    80003a1e:	ec66                	sd	s9,24(sp)
    80003a20:	e86a                	sd	s10,16(sp)
    80003a22:	e46e                	sd	s11,8(sp)
    80003a24:	1880                	addi	s0,sp,112
    80003a26:	8baa                	mv	s7,a0
    80003a28:	8c2e                	mv	s8,a1
    80003a2a:	8ab2                	mv	s5,a2
    80003a2c:	84b6                	mv	s1,a3
    80003a2e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a30:	9f35                	addw	a4,a4,a3
    return 0;
    80003a32:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a34:	0ad76063          	bltu	a4,a3,80003ad4 <readi+0xd2>
  if(off + n > ip->size)
    80003a38:	00e7f463          	bgeu	a5,a4,80003a40 <readi+0x3e>
    n = ip->size - off;
    80003a3c:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a40:	0a0b0963          	beqz	s6,80003af2 <readi+0xf0>
    80003a44:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a46:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003a4a:	5cfd                	li	s9,-1
    80003a4c:	a82d                	j	80003a86 <readi+0x84>
    80003a4e:	020a1d93          	slli	s11,s4,0x20
    80003a52:	020ddd93          	srli	s11,s11,0x20
    80003a56:	05890613          	addi	a2,s2,88
    80003a5a:	86ee                	mv	a3,s11
    80003a5c:	963a                	add	a2,a2,a4
    80003a5e:	85d6                	mv	a1,s5
    80003a60:	8562                	mv	a0,s8
    80003a62:	fffff097          	auipc	ra,0xfffff
    80003a66:	ace080e7          	jalr	-1330(ra) # 80002530 <either_copyout>
    80003a6a:	05950d63          	beq	a0,s9,80003ac4 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003a6e:	854a                	mv	a0,s2
    80003a70:	fffff097          	auipc	ra,0xfffff
    80003a74:	60c080e7          	jalr	1548(ra) # 8000307c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a78:	013a09bb          	addw	s3,s4,s3
    80003a7c:	009a04bb          	addw	s1,s4,s1
    80003a80:	9aee                	add	s5,s5,s11
    80003a82:	0569f763          	bgeu	s3,s6,80003ad0 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003a86:	000ba903          	lw	s2,0(s7)
    80003a8a:	00a4d59b          	srliw	a1,s1,0xa
    80003a8e:	855e                	mv	a0,s7
    80003a90:	00000097          	auipc	ra,0x0
    80003a94:	8b0080e7          	jalr	-1872(ra) # 80003340 <bmap>
    80003a98:	0005059b          	sext.w	a1,a0
    80003a9c:	854a                	mv	a0,s2
    80003a9e:	fffff097          	auipc	ra,0xfffff
    80003aa2:	4ae080e7          	jalr	1198(ra) # 80002f4c <bread>
    80003aa6:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003aa8:	3ff4f713          	andi	a4,s1,1023
    80003aac:	40ed07bb          	subw	a5,s10,a4
    80003ab0:	413b06bb          	subw	a3,s6,s3
    80003ab4:	8a3e                	mv	s4,a5
    80003ab6:	2781                	sext.w	a5,a5
    80003ab8:	0006861b          	sext.w	a2,a3
    80003abc:	f8f679e3          	bgeu	a2,a5,80003a4e <readi+0x4c>
    80003ac0:	8a36                	mv	s4,a3
    80003ac2:	b771                	j	80003a4e <readi+0x4c>
      brelse(bp);
    80003ac4:	854a                	mv	a0,s2
    80003ac6:	fffff097          	auipc	ra,0xfffff
    80003aca:	5b6080e7          	jalr	1462(ra) # 8000307c <brelse>
      tot = -1;
    80003ace:	59fd                	li	s3,-1
  }
  return tot;
    80003ad0:	0009851b          	sext.w	a0,s3
}
    80003ad4:	70a6                	ld	ra,104(sp)
    80003ad6:	7406                	ld	s0,96(sp)
    80003ad8:	64e6                	ld	s1,88(sp)
    80003ada:	6946                	ld	s2,80(sp)
    80003adc:	69a6                	ld	s3,72(sp)
    80003ade:	6a06                	ld	s4,64(sp)
    80003ae0:	7ae2                	ld	s5,56(sp)
    80003ae2:	7b42                	ld	s6,48(sp)
    80003ae4:	7ba2                	ld	s7,40(sp)
    80003ae6:	7c02                	ld	s8,32(sp)
    80003ae8:	6ce2                	ld	s9,24(sp)
    80003aea:	6d42                	ld	s10,16(sp)
    80003aec:	6da2                	ld	s11,8(sp)
    80003aee:	6165                	addi	sp,sp,112
    80003af0:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003af2:	89da                	mv	s3,s6
    80003af4:	bff1                	j	80003ad0 <readi+0xce>
    return 0;
    80003af6:	4501                	li	a0,0
}
    80003af8:	8082                	ret

0000000080003afa <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003afa:	457c                	lw	a5,76(a0)
    80003afc:	10d7e763          	bltu	a5,a3,80003c0a <writei+0x110>
{
    80003b00:	7159                	addi	sp,sp,-112
    80003b02:	f486                	sd	ra,104(sp)
    80003b04:	f0a2                	sd	s0,96(sp)
    80003b06:	eca6                	sd	s1,88(sp)
    80003b08:	e8ca                	sd	s2,80(sp)
    80003b0a:	e4ce                	sd	s3,72(sp)
    80003b0c:	e0d2                	sd	s4,64(sp)
    80003b0e:	fc56                	sd	s5,56(sp)
    80003b10:	f85a                	sd	s6,48(sp)
    80003b12:	f45e                	sd	s7,40(sp)
    80003b14:	f062                	sd	s8,32(sp)
    80003b16:	ec66                	sd	s9,24(sp)
    80003b18:	e86a                	sd	s10,16(sp)
    80003b1a:	e46e                	sd	s11,8(sp)
    80003b1c:	1880                	addi	s0,sp,112
    80003b1e:	8baa                	mv	s7,a0
    80003b20:	8c2e                	mv	s8,a1
    80003b22:	8ab2                	mv	s5,a2
    80003b24:	8936                	mv	s2,a3
    80003b26:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b28:	00e687bb          	addw	a5,a3,a4
    80003b2c:	0ed7e163          	bltu	a5,a3,80003c0e <writei+0x114>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b30:	00043737          	lui	a4,0x43
    80003b34:	0cf76f63          	bltu	a4,a5,80003c12 <writei+0x118>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b38:	0a0b0863          	beqz	s6,80003be8 <writei+0xee>
    80003b3c:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b3e:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003b42:	5cfd                	li	s9,-1
    80003b44:	a091                	j	80003b88 <writei+0x8e>
    80003b46:	02099d93          	slli	s11,s3,0x20
    80003b4a:	020ddd93          	srli	s11,s11,0x20
    80003b4e:	05848513          	addi	a0,s1,88
    80003b52:	86ee                	mv	a3,s11
    80003b54:	8656                	mv	a2,s5
    80003b56:	85e2                	mv	a1,s8
    80003b58:	953a                	add	a0,a0,a4
    80003b5a:	fffff097          	auipc	ra,0xfffff
    80003b5e:	a2c080e7          	jalr	-1492(ra) # 80002586 <either_copyin>
    80003b62:	07950263          	beq	a0,s9,80003bc6 <writei+0xcc>
      brelse(bp);
      n = -1;
      break;
    }
    log_write(bp);
    80003b66:	8526                	mv	a0,s1
    80003b68:	00000097          	auipc	ra,0x0
    80003b6c:	77c080e7          	jalr	1916(ra) # 800042e4 <log_write>
    brelse(bp);
    80003b70:	8526                	mv	a0,s1
    80003b72:	fffff097          	auipc	ra,0xfffff
    80003b76:	50a080e7          	jalr	1290(ra) # 8000307c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b7a:	01498a3b          	addw	s4,s3,s4
    80003b7e:	0129893b          	addw	s2,s3,s2
    80003b82:	9aee                	add	s5,s5,s11
    80003b84:	056a7763          	bgeu	s4,s6,80003bd2 <writei+0xd8>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b88:	000ba483          	lw	s1,0(s7)
    80003b8c:	00a9559b          	srliw	a1,s2,0xa
    80003b90:	855e                	mv	a0,s7
    80003b92:	fffff097          	auipc	ra,0xfffff
    80003b96:	7ae080e7          	jalr	1966(ra) # 80003340 <bmap>
    80003b9a:	0005059b          	sext.w	a1,a0
    80003b9e:	8526                	mv	a0,s1
    80003ba0:	fffff097          	auipc	ra,0xfffff
    80003ba4:	3ac080e7          	jalr	940(ra) # 80002f4c <bread>
    80003ba8:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003baa:	3ff97713          	andi	a4,s2,1023
    80003bae:	40ed07bb          	subw	a5,s10,a4
    80003bb2:	414b06bb          	subw	a3,s6,s4
    80003bb6:	89be                	mv	s3,a5
    80003bb8:	2781                	sext.w	a5,a5
    80003bba:	0006861b          	sext.w	a2,a3
    80003bbe:	f8f674e3          	bgeu	a2,a5,80003b46 <writei+0x4c>
    80003bc2:	89b6                	mv	s3,a3
    80003bc4:	b749                	j	80003b46 <writei+0x4c>
      brelse(bp);
    80003bc6:	8526                	mv	a0,s1
    80003bc8:	fffff097          	auipc	ra,0xfffff
    80003bcc:	4b4080e7          	jalr	1204(ra) # 8000307c <brelse>
      n = -1;
    80003bd0:	5b7d                	li	s6,-1
  }

  if(n > 0){
    if(off > ip->size)
    80003bd2:	04cba783          	lw	a5,76(s7)
    80003bd6:	0127f463          	bgeu	a5,s2,80003bde <writei+0xe4>
      ip->size = off;
    80003bda:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003bde:	855e                	mv	a0,s7
    80003be0:	00000097          	auipc	ra,0x0
    80003be4:	aa4080e7          	jalr	-1372(ra) # 80003684 <iupdate>
  }

  return n;
    80003be8:	000b051b          	sext.w	a0,s6
}
    80003bec:	70a6                	ld	ra,104(sp)
    80003bee:	7406                	ld	s0,96(sp)
    80003bf0:	64e6                	ld	s1,88(sp)
    80003bf2:	6946                	ld	s2,80(sp)
    80003bf4:	69a6                	ld	s3,72(sp)
    80003bf6:	6a06                	ld	s4,64(sp)
    80003bf8:	7ae2                	ld	s5,56(sp)
    80003bfa:	7b42                	ld	s6,48(sp)
    80003bfc:	7ba2                	ld	s7,40(sp)
    80003bfe:	7c02                	ld	s8,32(sp)
    80003c00:	6ce2                	ld	s9,24(sp)
    80003c02:	6d42                	ld	s10,16(sp)
    80003c04:	6da2                	ld	s11,8(sp)
    80003c06:	6165                	addi	sp,sp,112
    80003c08:	8082                	ret
    return -1;
    80003c0a:	557d                	li	a0,-1
}
    80003c0c:	8082                	ret
    return -1;
    80003c0e:	557d                	li	a0,-1
    80003c10:	bff1                	j	80003bec <writei+0xf2>
    return -1;
    80003c12:	557d                	li	a0,-1
    80003c14:	bfe1                	j	80003bec <writei+0xf2>

0000000080003c16 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c16:	1141                	addi	sp,sp,-16
    80003c18:	e406                	sd	ra,8(sp)
    80003c1a:	e022                	sd	s0,0(sp)
    80003c1c:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c1e:	4639                	li	a2,14
    80003c20:	ffffd097          	auipc	ra,0xffffd
    80003c24:	1c8080e7          	jalr	456(ra) # 80000de8 <strncmp>
}
    80003c28:	60a2                	ld	ra,8(sp)
    80003c2a:	6402                	ld	s0,0(sp)
    80003c2c:	0141                	addi	sp,sp,16
    80003c2e:	8082                	ret

0000000080003c30 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c30:	7139                	addi	sp,sp,-64
    80003c32:	fc06                	sd	ra,56(sp)
    80003c34:	f822                	sd	s0,48(sp)
    80003c36:	f426                	sd	s1,40(sp)
    80003c38:	f04a                	sd	s2,32(sp)
    80003c3a:	ec4e                	sd	s3,24(sp)
    80003c3c:	e852                	sd	s4,16(sp)
    80003c3e:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003c40:	04451703          	lh	a4,68(a0)
    80003c44:	4785                	li	a5,1
    80003c46:	00f71a63          	bne	a4,a5,80003c5a <dirlookup+0x2a>
    80003c4a:	892a                	mv	s2,a0
    80003c4c:	89ae                	mv	s3,a1
    80003c4e:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c50:	457c                	lw	a5,76(a0)
    80003c52:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003c54:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c56:	e79d                	bnez	a5,80003c84 <dirlookup+0x54>
    80003c58:	a8a5                	j	80003cd0 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003c5a:	00005517          	auipc	a0,0x5
    80003c5e:	94650513          	addi	a0,a0,-1722 # 800085a0 <syscalls+0x1a0>
    80003c62:	ffffd097          	auipc	ra,0xffffd
    80003c66:	8e6080e7          	jalr	-1818(ra) # 80000548 <panic>
      panic("dirlookup read");
    80003c6a:	00005517          	auipc	a0,0x5
    80003c6e:	94e50513          	addi	a0,a0,-1714 # 800085b8 <syscalls+0x1b8>
    80003c72:	ffffd097          	auipc	ra,0xffffd
    80003c76:	8d6080e7          	jalr	-1834(ra) # 80000548 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c7a:	24c1                	addiw	s1,s1,16
    80003c7c:	04c92783          	lw	a5,76(s2)
    80003c80:	04f4f763          	bgeu	s1,a5,80003cce <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003c84:	4741                	li	a4,16
    80003c86:	86a6                	mv	a3,s1
    80003c88:	fc040613          	addi	a2,s0,-64
    80003c8c:	4581                	li	a1,0
    80003c8e:	854a                	mv	a0,s2
    80003c90:	00000097          	auipc	ra,0x0
    80003c94:	d72080e7          	jalr	-654(ra) # 80003a02 <readi>
    80003c98:	47c1                	li	a5,16
    80003c9a:	fcf518e3          	bne	a0,a5,80003c6a <dirlookup+0x3a>
    if(de.inum == 0)
    80003c9e:	fc045783          	lhu	a5,-64(s0)
    80003ca2:	dfe1                	beqz	a5,80003c7a <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003ca4:	fc240593          	addi	a1,s0,-62
    80003ca8:	854e                	mv	a0,s3
    80003caa:	00000097          	auipc	ra,0x0
    80003cae:	f6c080e7          	jalr	-148(ra) # 80003c16 <namecmp>
    80003cb2:	f561                	bnez	a0,80003c7a <dirlookup+0x4a>
      if(poff)
    80003cb4:	000a0463          	beqz	s4,80003cbc <dirlookup+0x8c>
        *poff = off;
    80003cb8:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003cbc:	fc045583          	lhu	a1,-64(s0)
    80003cc0:	00092503          	lw	a0,0(s2)
    80003cc4:	fffff097          	auipc	ra,0xfffff
    80003cc8:	756080e7          	jalr	1878(ra) # 8000341a <iget>
    80003ccc:	a011                	j	80003cd0 <dirlookup+0xa0>
  return 0;
    80003cce:	4501                	li	a0,0
}
    80003cd0:	70e2                	ld	ra,56(sp)
    80003cd2:	7442                	ld	s0,48(sp)
    80003cd4:	74a2                	ld	s1,40(sp)
    80003cd6:	7902                	ld	s2,32(sp)
    80003cd8:	69e2                	ld	s3,24(sp)
    80003cda:	6a42                	ld	s4,16(sp)
    80003cdc:	6121                	addi	sp,sp,64
    80003cde:	8082                	ret

0000000080003ce0 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003ce0:	711d                	addi	sp,sp,-96
    80003ce2:	ec86                	sd	ra,88(sp)
    80003ce4:	e8a2                	sd	s0,80(sp)
    80003ce6:	e4a6                	sd	s1,72(sp)
    80003ce8:	e0ca                	sd	s2,64(sp)
    80003cea:	fc4e                	sd	s3,56(sp)
    80003cec:	f852                	sd	s4,48(sp)
    80003cee:	f456                	sd	s5,40(sp)
    80003cf0:	f05a                	sd	s6,32(sp)
    80003cf2:	ec5e                	sd	s7,24(sp)
    80003cf4:	e862                	sd	s8,16(sp)
    80003cf6:	e466                	sd	s9,8(sp)
    80003cf8:	1080                	addi	s0,sp,96
    80003cfa:	84aa                	mv	s1,a0
    80003cfc:	8b2e                	mv	s6,a1
    80003cfe:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d00:	00054703          	lbu	a4,0(a0)
    80003d04:	02f00793          	li	a5,47
    80003d08:	02f70363          	beq	a4,a5,80003d2e <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d0c:	ffffe097          	auipc	ra,0xffffe
    80003d10:	db2080e7          	jalr	-590(ra) # 80001abe <myproc>
    80003d14:	15053503          	ld	a0,336(a0)
    80003d18:	00000097          	auipc	ra,0x0
    80003d1c:	9f8080e7          	jalr	-1544(ra) # 80003710 <idup>
    80003d20:	89aa                	mv	s3,a0
  while(*path == '/')
    80003d22:	02f00913          	li	s2,47
  len = path - s;
    80003d26:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003d28:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d2a:	4c05                	li	s8,1
    80003d2c:	a865                	j	80003de4 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003d2e:	4585                	li	a1,1
    80003d30:	4505                	li	a0,1
    80003d32:	fffff097          	auipc	ra,0xfffff
    80003d36:	6e8080e7          	jalr	1768(ra) # 8000341a <iget>
    80003d3a:	89aa                	mv	s3,a0
    80003d3c:	b7dd                	j	80003d22 <namex+0x42>
      iunlockput(ip);
    80003d3e:	854e                	mv	a0,s3
    80003d40:	00000097          	auipc	ra,0x0
    80003d44:	c70080e7          	jalr	-912(ra) # 800039b0 <iunlockput>
      return 0;
    80003d48:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003d4a:	854e                	mv	a0,s3
    80003d4c:	60e6                	ld	ra,88(sp)
    80003d4e:	6446                	ld	s0,80(sp)
    80003d50:	64a6                	ld	s1,72(sp)
    80003d52:	6906                	ld	s2,64(sp)
    80003d54:	79e2                	ld	s3,56(sp)
    80003d56:	7a42                	ld	s4,48(sp)
    80003d58:	7aa2                	ld	s5,40(sp)
    80003d5a:	7b02                	ld	s6,32(sp)
    80003d5c:	6be2                	ld	s7,24(sp)
    80003d5e:	6c42                	ld	s8,16(sp)
    80003d60:	6ca2                	ld	s9,8(sp)
    80003d62:	6125                	addi	sp,sp,96
    80003d64:	8082                	ret
      iunlock(ip);
    80003d66:	854e                	mv	a0,s3
    80003d68:	00000097          	auipc	ra,0x0
    80003d6c:	aa8080e7          	jalr	-1368(ra) # 80003810 <iunlock>
      return ip;
    80003d70:	bfe9                	j	80003d4a <namex+0x6a>
      iunlockput(ip);
    80003d72:	854e                	mv	a0,s3
    80003d74:	00000097          	auipc	ra,0x0
    80003d78:	c3c080e7          	jalr	-964(ra) # 800039b0 <iunlockput>
      return 0;
    80003d7c:	89d2                	mv	s3,s4
    80003d7e:	b7f1                	j	80003d4a <namex+0x6a>
  len = path - s;
    80003d80:	40b48633          	sub	a2,s1,a1
    80003d84:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003d88:	094cd463          	bge	s9,s4,80003e10 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003d8c:	4639                	li	a2,14
    80003d8e:	8556                	mv	a0,s5
    80003d90:	ffffd097          	auipc	ra,0xffffd
    80003d94:	fdc080e7          	jalr	-36(ra) # 80000d6c <memmove>
  while(*path == '/')
    80003d98:	0004c783          	lbu	a5,0(s1)
    80003d9c:	01279763          	bne	a5,s2,80003daa <namex+0xca>
    path++;
    80003da0:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003da2:	0004c783          	lbu	a5,0(s1)
    80003da6:	ff278de3          	beq	a5,s2,80003da0 <namex+0xc0>
    ilock(ip);
    80003daa:	854e                	mv	a0,s3
    80003dac:	00000097          	auipc	ra,0x0
    80003db0:	9a2080e7          	jalr	-1630(ra) # 8000374e <ilock>
    if(ip->type != T_DIR){
    80003db4:	04499783          	lh	a5,68(s3)
    80003db8:	f98793e3          	bne	a5,s8,80003d3e <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003dbc:	000b0563          	beqz	s6,80003dc6 <namex+0xe6>
    80003dc0:	0004c783          	lbu	a5,0(s1)
    80003dc4:	d3cd                	beqz	a5,80003d66 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003dc6:	865e                	mv	a2,s7
    80003dc8:	85d6                	mv	a1,s5
    80003dca:	854e                	mv	a0,s3
    80003dcc:	00000097          	auipc	ra,0x0
    80003dd0:	e64080e7          	jalr	-412(ra) # 80003c30 <dirlookup>
    80003dd4:	8a2a                	mv	s4,a0
    80003dd6:	dd51                	beqz	a0,80003d72 <namex+0x92>
    iunlockput(ip);
    80003dd8:	854e                	mv	a0,s3
    80003dda:	00000097          	auipc	ra,0x0
    80003dde:	bd6080e7          	jalr	-1066(ra) # 800039b0 <iunlockput>
    ip = next;
    80003de2:	89d2                	mv	s3,s4
  while(*path == '/')
    80003de4:	0004c783          	lbu	a5,0(s1)
    80003de8:	05279763          	bne	a5,s2,80003e36 <namex+0x156>
    path++;
    80003dec:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003dee:	0004c783          	lbu	a5,0(s1)
    80003df2:	ff278de3          	beq	a5,s2,80003dec <namex+0x10c>
  if(*path == 0)
    80003df6:	c79d                	beqz	a5,80003e24 <namex+0x144>
    path++;
    80003df8:	85a6                	mv	a1,s1
  len = path - s;
    80003dfa:	8a5e                	mv	s4,s7
    80003dfc:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003dfe:	01278963          	beq	a5,s2,80003e10 <namex+0x130>
    80003e02:	dfbd                	beqz	a5,80003d80 <namex+0xa0>
    path++;
    80003e04:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003e06:	0004c783          	lbu	a5,0(s1)
    80003e0a:	ff279ce3          	bne	a5,s2,80003e02 <namex+0x122>
    80003e0e:	bf8d                	j	80003d80 <namex+0xa0>
    memmove(name, s, len);
    80003e10:	2601                	sext.w	a2,a2
    80003e12:	8556                	mv	a0,s5
    80003e14:	ffffd097          	auipc	ra,0xffffd
    80003e18:	f58080e7          	jalr	-168(ra) # 80000d6c <memmove>
    name[len] = 0;
    80003e1c:	9a56                	add	s4,s4,s5
    80003e1e:	000a0023          	sb	zero,0(s4)
    80003e22:	bf9d                	j	80003d98 <namex+0xb8>
  if(nameiparent){
    80003e24:	f20b03e3          	beqz	s6,80003d4a <namex+0x6a>
    iput(ip);
    80003e28:	854e                	mv	a0,s3
    80003e2a:	00000097          	auipc	ra,0x0
    80003e2e:	ade080e7          	jalr	-1314(ra) # 80003908 <iput>
    return 0;
    80003e32:	4981                	li	s3,0
    80003e34:	bf19                	j	80003d4a <namex+0x6a>
  if(*path == 0)
    80003e36:	d7fd                	beqz	a5,80003e24 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003e38:	0004c783          	lbu	a5,0(s1)
    80003e3c:	85a6                	mv	a1,s1
    80003e3e:	b7d1                	j	80003e02 <namex+0x122>

0000000080003e40 <dirlink>:
{
    80003e40:	7139                	addi	sp,sp,-64
    80003e42:	fc06                	sd	ra,56(sp)
    80003e44:	f822                	sd	s0,48(sp)
    80003e46:	f426                	sd	s1,40(sp)
    80003e48:	f04a                	sd	s2,32(sp)
    80003e4a:	ec4e                	sd	s3,24(sp)
    80003e4c:	e852                	sd	s4,16(sp)
    80003e4e:	0080                	addi	s0,sp,64
    80003e50:	892a                	mv	s2,a0
    80003e52:	8a2e                	mv	s4,a1
    80003e54:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003e56:	4601                	li	a2,0
    80003e58:	00000097          	auipc	ra,0x0
    80003e5c:	dd8080e7          	jalr	-552(ra) # 80003c30 <dirlookup>
    80003e60:	e93d                	bnez	a0,80003ed6 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e62:	04c92483          	lw	s1,76(s2)
    80003e66:	c49d                	beqz	s1,80003e94 <dirlink+0x54>
    80003e68:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e6a:	4741                	li	a4,16
    80003e6c:	86a6                	mv	a3,s1
    80003e6e:	fc040613          	addi	a2,s0,-64
    80003e72:	4581                	li	a1,0
    80003e74:	854a                	mv	a0,s2
    80003e76:	00000097          	auipc	ra,0x0
    80003e7a:	b8c080e7          	jalr	-1140(ra) # 80003a02 <readi>
    80003e7e:	47c1                	li	a5,16
    80003e80:	06f51163          	bne	a0,a5,80003ee2 <dirlink+0xa2>
    if(de.inum == 0)
    80003e84:	fc045783          	lhu	a5,-64(s0)
    80003e88:	c791                	beqz	a5,80003e94 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e8a:	24c1                	addiw	s1,s1,16
    80003e8c:	04c92783          	lw	a5,76(s2)
    80003e90:	fcf4ede3          	bltu	s1,a5,80003e6a <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003e94:	4639                	li	a2,14
    80003e96:	85d2                	mv	a1,s4
    80003e98:	fc240513          	addi	a0,s0,-62
    80003e9c:	ffffd097          	auipc	ra,0xffffd
    80003ea0:	f88080e7          	jalr	-120(ra) # 80000e24 <strncpy>
  de.inum = inum;
    80003ea4:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ea8:	4741                	li	a4,16
    80003eaa:	86a6                	mv	a3,s1
    80003eac:	fc040613          	addi	a2,s0,-64
    80003eb0:	4581                	li	a1,0
    80003eb2:	854a                	mv	a0,s2
    80003eb4:	00000097          	auipc	ra,0x0
    80003eb8:	c46080e7          	jalr	-954(ra) # 80003afa <writei>
    80003ebc:	872a                	mv	a4,a0
    80003ebe:	47c1                	li	a5,16
  return 0;
    80003ec0:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ec2:	02f71863          	bne	a4,a5,80003ef2 <dirlink+0xb2>
}
    80003ec6:	70e2                	ld	ra,56(sp)
    80003ec8:	7442                	ld	s0,48(sp)
    80003eca:	74a2                	ld	s1,40(sp)
    80003ecc:	7902                	ld	s2,32(sp)
    80003ece:	69e2                	ld	s3,24(sp)
    80003ed0:	6a42                	ld	s4,16(sp)
    80003ed2:	6121                	addi	sp,sp,64
    80003ed4:	8082                	ret
    iput(ip);
    80003ed6:	00000097          	auipc	ra,0x0
    80003eda:	a32080e7          	jalr	-1486(ra) # 80003908 <iput>
    return -1;
    80003ede:	557d                	li	a0,-1
    80003ee0:	b7dd                	j	80003ec6 <dirlink+0x86>
      panic("dirlink read");
    80003ee2:	00004517          	auipc	a0,0x4
    80003ee6:	6e650513          	addi	a0,a0,1766 # 800085c8 <syscalls+0x1c8>
    80003eea:	ffffc097          	auipc	ra,0xffffc
    80003eee:	65e080e7          	jalr	1630(ra) # 80000548 <panic>
    panic("dirlink");
    80003ef2:	00004517          	auipc	a0,0x4
    80003ef6:	7f650513          	addi	a0,a0,2038 # 800086e8 <syscalls+0x2e8>
    80003efa:	ffffc097          	auipc	ra,0xffffc
    80003efe:	64e080e7          	jalr	1614(ra) # 80000548 <panic>

0000000080003f02 <namei>:

struct inode*
namei(char *path)
{
    80003f02:	1101                	addi	sp,sp,-32
    80003f04:	ec06                	sd	ra,24(sp)
    80003f06:	e822                	sd	s0,16(sp)
    80003f08:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f0a:	fe040613          	addi	a2,s0,-32
    80003f0e:	4581                	li	a1,0
    80003f10:	00000097          	auipc	ra,0x0
    80003f14:	dd0080e7          	jalr	-560(ra) # 80003ce0 <namex>
}
    80003f18:	60e2                	ld	ra,24(sp)
    80003f1a:	6442                	ld	s0,16(sp)
    80003f1c:	6105                	addi	sp,sp,32
    80003f1e:	8082                	ret

0000000080003f20 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f20:	1141                	addi	sp,sp,-16
    80003f22:	e406                	sd	ra,8(sp)
    80003f24:	e022                	sd	s0,0(sp)
    80003f26:	0800                	addi	s0,sp,16
    80003f28:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f2a:	4585                	li	a1,1
    80003f2c:	00000097          	auipc	ra,0x0
    80003f30:	db4080e7          	jalr	-588(ra) # 80003ce0 <namex>
}
    80003f34:	60a2                	ld	ra,8(sp)
    80003f36:	6402                	ld	s0,0(sp)
    80003f38:	0141                	addi	sp,sp,16
    80003f3a:	8082                	ret

0000000080003f3c <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f3c:	1101                	addi	sp,sp,-32
    80003f3e:	ec06                	sd	ra,24(sp)
    80003f40:	e822                	sd	s0,16(sp)
    80003f42:	e426                	sd	s1,8(sp)
    80003f44:	e04a                	sd	s2,0(sp)
    80003f46:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003f48:	0001e917          	auipc	s2,0x1e
    80003f4c:	9c090913          	addi	s2,s2,-1600 # 80021908 <log>
    80003f50:	01892583          	lw	a1,24(s2)
    80003f54:	02892503          	lw	a0,40(s2)
    80003f58:	fffff097          	auipc	ra,0xfffff
    80003f5c:	ff4080e7          	jalr	-12(ra) # 80002f4c <bread>
    80003f60:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003f62:	02c92683          	lw	a3,44(s2)
    80003f66:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003f68:	02d05763          	blez	a3,80003f96 <write_head+0x5a>
    80003f6c:	0001e797          	auipc	a5,0x1e
    80003f70:	9cc78793          	addi	a5,a5,-1588 # 80021938 <log+0x30>
    80003f74:	05c50713          	addi	a4,a0,92
    80003f78:	36fd                	addiw	a3,a3,-1
    80003f7a:	1682                	slli	a3,a3,0x20
    80003f7c:	9281                	srli	a3,a3,0x20
    80003f7e:	068a                	slli	a3,a3,0x2
    80003f80:	0001e617          	auipc	a2,0x1e
    80003f84:	9bc60613          	addi	a2,a2,-1604 # 8002193c <log+0x34>
    80003f88:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003f8a:	4390                	lw	a2,0(a5)
    80003f8c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003f8e:	0791                	addi	a5,a5,4
    80003f90:	0711                	addi	a4,a4,4
    80003f92:	fed79ce3          	bne	a5,a3,80003f8a <write_head+0x4e>
  }
  bwrite(buf);
    80003f96:	8526                	mv	a0,s1
    80003f98:	fffff097          	auipc	ra,0xfffff
    80003f9c:	0a6080e7          	jalr	166(ra) # 8000303e <bwrite>
  brelse(buf);
    80003fa0:	8526                	mv	a0,s1
    80003fa2:	fffff097          	auipc	ra,0xfffff
    80003fa6:	0da080e7          	jalr	218(ra) # 8000307c <brelse>
}
    80003faa:	60e2                	ld	ra,24(sp)
    80003fac:	6442                	ld	s0,16(sp)
    80003fae:	64a2                	ld	s1,8(sp)
    80003fb0:	6902                	ld	s2,0(sp)
    80003fb2:	6105                	addi	sp,sp,32
    80003fb4:	8082                	ret

0000000080003fb6 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fb6:	0001e797          	auipc	a5,0x1e
    80003fba:	97e7a783          	lw	a5,-1666(a5) # 80021934 <log+0x2c>
    80003fbe:	0af05663          	blez	a5,8000406a <install_trans+0xb4>
{
    80003fc2:	7139                	addi	sp,sp,-64
    80003fc4:	fc06                	sd	ra,56(sp)
    80003fc6:	f822                	sd	s0,48(sp)
    80003fc8:	f426                	sd	s1,40(sp)
    80003fca:	f04a                	sd	s2,32(sp)
    80003fcc:	ec4e                	sd	s3,24(sp)
    80003fce:	e852                	sd	s4,16(sp)
    80003fd0:	e456                	sd	s5,8(sp)
    80003fd2:	0080                	addi	s0,sp,64
    80003fd4:	0001ea97          	auipc	s5,0x1e
    80003fd8:	964a8a93          	addi	s5,s5,-1692 # 80021938 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fdc:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003fde:	0001e997          	auipc	s3,0x1e
    80003fe2:	92a98993          	addi	s3,s3,-1750 # 80021908 <log>
    80003fe6:	0189a583          	lw	a1,24(s3)
    80003fea:	014585bb          	addw	a1,a1,s4
    80003fee:	2585                	addiw	a1,a1,1
    80003ff0:	0289a503          	lw	a0,40(s3)
    80003ff4:	fffff097          	auipc	ra,0xfffff
    80003ff8:	f58080e7          	jalr	-168(ra) # 80002f4c <bread>
    80003ffc:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003ffe:	000aa583          	lw	a1,0(s5)
    80004002:	0289a503          	lw	a0,40(s3)
    80004006:	fffff097          	auipc	ra,0xfffff
    8000400a:	f46080e7          	jalr	-186(ra) # 80002f4c <bread>
    8000400e:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004010:	40000613          	li	a2,1024
    80004014:	05890593          	addi	a1,s2,88
    80004018:	05850513          	addi	a0,a0,88
    8000401c:	ffffd097          	auipc	ra,0xffffd
    80004020:	d50080e7          	jalr	-688(ra) # 80000d6c <memmove>
    bwrite(dbuf);  // write dst to disk
    80004024:	8526                	mv	a0,s1
    80004026:	fffff097          	auipc	ra,0xfffff
    8000402a:	018080e7          	jalr	24(ra) # 8000303e <bwrite>
    bunpin(dbuf);
    8000402e:	8526                	mv	a0,s1
    80004030:	fffff097          	auipc	ra,0xfffff
    80004034:	126080e7          	jalr	294(ra) # 80003156 <bunpin>
    brelse(lbuf);
    80004038:	854a                	mv	a0,s2
    8000403a:	fffff097          	auipc	ra,0xfffff
    8000403e:	042080e7          	jalr	66(ra) # 8000307c <brelse>
    brelse(dbuf);
    80004042:	8526                	mv	a0,s1
    80004044:	fffff097          	auipc	ra,0xfffff
    80004048:	038080e7          	jalr	56(ra) # 8000307c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000404c:	2a05                	addiw	s4,s4,1
    8000404e:	0a91                	addi	s5,s5,4
    80004050:	02c9a783          	lw	a5,44(s3)
    80004054:	f8fa49e3          	blt	s4,a5,80003fe6 <install_trans+0x30>
}
    80004058:	70e2                	ld	ra,56(sp)
    8000405a:	7442                	ld	s0,48(sp)
    8000405c:	74a2                	ld	s1,40(sp)
    8000405e:	7902                	ld	s2,32(sp)
    80004060:	69e2                	ld	s3,24(sp)
    80004062:	6a42                	ld	s4,16(sp)
    80004064:	6aa2                	ld	s5,8(sp)
    80004066:	6121                	addi	sp,sp,64
    80004068:	8082                	ret
    8000406a:	8082                	ret

000000008000406c <initlog>:
{
    8000406c:	7179                	addi	sp,sp,-48
    8000406e:	f406                	sd	ra,40(sp)
    80004070:	f022                	sd	s0,32(sp)
    80004072:	ec26                	sd	s1,24(sp)
    80004074:	e84a                	sd	s2,16(sp)
    80004076:	e44e                	sd	s3,8(sp)
    80004078:	1800                	addi	s0,sp,48
    8000407a:	892a                	mv	s2,a0
    8000407c:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000407e:	0001e497          	auipc	s1,0x1e
    80004082:	88a48493          	addi	s1,s1,-1910 # 80021908 <log>
    80004086:	00004597          	auipc	a1,0x4
    8000408a:	55258593          	addi	a1,a1,1362 # 800085d8 <syscalls+0x1d8>
    8000408e:	8526                	mv	a0,s1
    80004090:	ffffd097          	auipc	ra,0xffffd
    80004094:	af0080e7          	jalr	-1296(ra) # 80000b80 <initlock>
  log.start = sb->logstart;
    80004098:	0149a583          	lw	a1,20(s3)
    8000409c:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000409e:	0109a783          	lw	a5,16(s3)
    800040a2:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800040a4:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800040a8:	854a                	mv	a0,s2
    800040aa:	fffff097          	auipc	ra,0xfffff
    800040ae:	ea2080e7          	jalr	-350(ra) # 80002f4c <bread>
  log.lh.n = lh->n;
    800040b2:	4d3c                	lw	a5,88(a0)
    800040b4:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800040b6:	02f05563          	blez	a5,800040e0 <initlog+0x74>
    800040ba:	05c50713          	addi	a4,a0,92
    800040be:	0001e697          	auipc	a3,0x1e
    800040c2:	87a68693          	addi	a3,a3,-1926 # 80021938 <log+0x30>
    800040c6:	37fd                	addiw	a5,a5,-1
    800040c8:	1782                	slli	a5,a5,0x20
    800040ca:	9381                	srli	a5,a5,0x20
    800040cc:	078a                	slli	a5,a5,0x2
    800040ce:	06050613          	addi	a2,a0,96
    800040d2:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800040d4:	4310                	lw	a2,0(a4)
    800040d6:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800040d8:	0711                	addi	a4,a4,4
    800040da:	0691                	addi	a3,a3,4
    800040dc:	fef71ce3          	bne	a4,a5,800040d4 <initlog+0x68>
  brelse(buf);
    800040e0:	fffff097          	auipc	ra,0xfffff
    800040e4:	f9c080e7          	jalr	-100(ra) # 8000307c <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    800040e8:	00000097          	auipc	ra,0x0
    800040ec:	ece080e7          	jalr	-306(ra) # 80003fb6 <install_trans>
  log.lh.n = 0;
    800040f0:	0001e797          	auipc	a5,0x1e
    800040f4:	8407a223          	sw	zero,-1980(a5) # 80021934 <log+0x2c>
  write_head(); // clear the log
    800040f8:	00000097          	auipc	ra,0x0
    800040fc:	e44080e7          	jalr	-444(ra) # 80003f3c <write_head>
}
    80004100:	70a2                	ld	ra,40(sp)
    80004102:	7402                	ld	s0,32(sp)
    80004104:	64e2                	ld	s1,24(sp)
    80004106:	6942                	ld	s2,16(sp)
    80004108:	69a2                	ld	s3,8(sp)
    8000410a:	6145                	addi	sp,sp,48
    8000410c:	8082                	ret

000000008000410e <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000410e:	1101                	addi	sp,sp,-32
    80004110:	ec06                	sd	ra,24(sp)
    80004112:	e822                	sd	s0,16(sp)
    80004114:	e426                	sd	s1,8(sp)
    80004116:	e04a                	sd	s2,0(sp)
    80004118:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000411a:	0001d517          	auipc	a0,0x1d
    8000411e:	7ee50513          	addi	a0,a0,2030 # 80021908 <log>
    80004122:	ffffd097          	auipc	ra,0xffffd
    80004126:	aee080e7          	jalr	-1298(ra) # 80000c10 <acquire>
  while(1){
    if(log.committing){
    8000412a:	0001d497          	auipc	s1,0x1d
    8000412e:	7de48493          	addi	s1,s1,2014 # 80021908 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004132:	4979                	li	s2,30
    80004134:	a039                	j	80004142 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004136:	85a6                	mv	a1,s1
    80004138:	8526                	mv	a0,s1
    8000413a:	ffffe097          	auipc	ra,0xffffe
    8000413e:	194080e7          	jalr	404(ra) # 800022ce <sleep>
    if(log.committing){
    80004142:	50dc                	lw	a5,36(s1)
    80004144:	fbed                	bnez	a5,80004136 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004146:	509c                	lw	a5,32(s1)
    80004148:	0017871b          	addiw	a4,a5,1
    8000414c:	0007069b          	sext.w	a3,a4
    80004150:	0027179b          	slliw	a5,a4,0x2
    80004154:	9fb9                	addw	a5,a5,a4
    80004156:	0017979b          	slliw	a5,a5,0x1
    8000415a:	54d8                	lw	a4,44(s1)
    8000415c:	9fb9                	addw	a5,a5,a4
    8000415e:	00f95963          	bge	s2,a5,80004170 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004162:	85a6                	mv	a1,s1
    80004164:	8526                	mv	a0,s1
    80004166:	ffffe097          	auipc	ra,0xffffe
    8000416a:	168080e7          	jalr	360(ra) # 800022ce <sleep>
    8000416e:	bfd1                	j	80004142 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004170:	0001d517          	auipc	a0,0x1d
    80004174:	79850513          	addi	a0,a0,1944 # 80021908 <log>
    80004178:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000417a:	ffffd097          	auipc	ra,0xffffd
    8000417e:	b4a080e7          	jalr	-1206(ra) # 80000cc4 <release>
      break;
    }
  }
}
    80004182:	60e2                	ld	ra,24(sp)
    80004184:	6442                	ld	s0,16(sp)
    80004186:	64a2                	ld	s1,8(sp)
    80004188:	6902                	ld	s2,0(sp)
    8000418a:	6105                	addi	sp,sp,32
    8000418c:	8082                	ret

000000008000418e <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000418e:	7139                	addi	sp,sp,-64
    80004190:	fc06                	sd	ra,56(sp)
    80004192:	f822                	sd	s0,48(sp)
    80004194:	f426                	sd	s1,40(sp)
    80004196:	f04a                	sd	s2,32(sp)
    80004198:	ec4e                	sd	s3,24(sp)
    8000419a:	e852                	sd	s4,16(sp)
    8000419c:	e456                	sd	s5,8(sp)
    8000419e:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800041a0:	0001d497          	auipc	s1,0x1d
    800041a4:	76848493          	addi	s1,s1,1896 # 80021908 <log>
    800041a8:	8526                	mv	a0,s1
    800041aa:	ffffd097          	auipc	ra,0xffffd
    800041ae:	a66080e7          	jalr	-1434(ra) # 80000c10 <acquire>
  log.outstanding -= 1;
    800041b2:	509c                	lw	a5,32(s1)
    800041b4:	37fd                	addiw	a5,a5,-1
    800041b6:	0007891b          	sext.w	s2,a5
    800041ba:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800041bc:	50dc                	lw	a5,36(s1)
    800041be:	efb9                	bnez	a5,8000421c <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800041c0:	06091663          	bnez	s2,8000422c <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800041c4:	0001d497          	auipc	s1,0x1d
    800041c8:	74448493          	addi	s1,s1,1860 # 80021908 <log>
    800041cc:	4785                	li	a5,1
    800041ce:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800041d0:	8526                	mv	a0,s1
    800041d2:	ffffd097          	auipc	ra,0xffffd
    800041d6:	af2080e7          	jalr	-1294(ra) # 80000cc4 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800041da:	54dc                	lw	a5,44(s1)
    800041dc:	06f04763          	bgtz	a5,8000424a <end_op+0xbc>
    acquire(&log.lock);
    800041e0:	0001d497          	auipc	s1,0x1d
    800041e4:	72848493          	addi	s1,s1,1832 # 80021908 <log>
    800041e8:	8526                	mv	a0,s1
    800041ea:	ffffd097          	auipc	ra,0xffffd
    800041ee:	a26080e7          	jalr	-1498(ra) # 80000c10 <acquire>
    log.committing = 0;
    800041f2:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800041f6:	8526                	mv	a0,s1
    800041f8:	ffffe097          	auipc	ra,0xffffe
    800041fc:	25c080e7          	jalr	604(ra) # 80002454 <wakeup>
    release(&log.lock);
    80004200:	8526                	mv	a0,s1
    80004202:	ffffd097          	auipc	ra,0xffffd
    80004206:	ac2080e7          	jalr	-1342(ra) # 80000cc4 <release>
}
    8000420a:	70e2                	ld	ra,56(sp)
    8000420c:	7442                	ld	s0,48(sp)
    8000420e:	74a2                	ld	s1,40(sp)
    80004210:	7902                	ld	s2,32(sp)
    80004212:	69e2                	ld	s3,24(sp)
    80004214:	6a42                	ld	s4,16(sp)
    80004216:	6aa2                	ld	s5,8(sp)
    80004218:	6121                	addi	sp,sp,64
    8000421a:	8082                	ret
    panic("log.committing");
    8000421c:	00004517          	auipc	a0,0x4
    80004220:	3c450513          	addi	a0,a0,964 # 800085e0 <syscalls+0x1e0>
    80004224:	ffffc097          	auipc	ra,0xffffc
    80004228:	324080e7          	jalr	804(ra) # 80000548 <panic>
    wakeup(&log);
    8000422c:	0001d497          	auipc	s1,0x1d
    80004230:	6dc48493          	addi	s1,s1,1756 # 80021908 <log>
    80004234:	8526                	mv	a0,s1
    80004236:	ffffe097          	auipc	ra,0xffffe
    8000423a:	21e080e7          	jalr	542(ra) # 80002454 <wakeup>
  release(&log.lock);
    8000423e:	8526                	mv	a0,s1
    80004240:	ffffd097          	auipc	ra,0xffffd
    80004244:	a84080e7          	jalr	-1404(ra) # 80000cc4 <release>
  if(do_commit){
    80004248:	b7c9                	j	8000420a <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000424a:	0001da97          	auipc	s5,0x1d
    8000424e:	6eea8a93          	addi	s5,s5,1774 # 80021938 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004252:	0001da17          	auipc	s4,0x1d
    80004256:	6b6a0a13          	addi	s4,s4,1718 # 80021908 <log>
    8000425a:	018a2583          	lw	a1,24(s4)
    8000425e:	012585bb          	addw	a1,a1,s2
    80004262:	2585                	addiw	a1,a1,1
    80004264:	028a2503          	lw	a0,40(s4)
    80004268:	fffff097          	auipc	ra,0xfffff
    8000426c:	ce4080e7          	jalr	-796(ra) # 80002f4c <bread>
    80004270:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004272:	000aa583          	lw	a1,0(s5)
    80004276:	028a2503          	lw	a0,40(s4)
    8000427a:	fffff097          	auipc	ra,0xfffff
    8000427e:	cd2080e7          	jalr	-814(ra) # 80002f4c <bread>
    80004282:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004284:	40000613          	li	a2,1024
    80004288:	05850593          	addi	a1,a0,88
    8000428c:	05848513          	addi	a0,s1,88
    80004290:	ffffd097          	auipc	ra,0xffffd
    80004294:	adc080e7          	jalr	-1316(ra) # 80000d6c <memmove>
    bwrite(to);  // write the log
    80004298:	8526                	mv	a0,s1
    8000429a:	fffff097          	auipc	ra,0xfffff
    8000429e:	da4080e7          	jalr	-604(ra) # 8000303e <bwrite>
    brelse(from);
    800042a2:	854e                	mv	a0,s3
    800042a4:	fffff097          	auipc	ra,0xfffff
    800042a8:	dd8080e7          	jalr	-552(ra) # 8000307c <brelse>
    brelse(to);
    800042ac:	8526                	mv	a0,s1
    800042ae:	fffff097          	auipc	ra,0xfffff
    800042b2:	dce080e7          	jalr	-562(ra) # 8000307c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042b6:	2905                	addiw	s2,s2,1
    800042b8:	0a91                	addi	s5,s5,4
    800042ba:	02ca2783          	lw	a5,44(s4)
    800042be:	f8f94ee3          	blt	s2,a5,8000425a <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800042c2:	00000097          	auipc	ra,0x0
    800042c6:	c7a080e7          	jalr	-902(ra) # 80003f3c <write_head>
    install_trans(); // Now install writes to home locations
    800042ca:	00000097          	auipc	ra,0x0
    800042ce:	cec080e7          	jalr	-788(ra) # 80003fb6 <install_trans>
    log.lh.n = 0;
    800042d2:	0001d797          	auipc	a5,0x1d
    800042d6:	6607a123          	sw	zero,1634(a5) # 80021934 <log+0x2c>
    write_head();    // Erase the transaction from the log
    800042da:	00000097          	auipc	ra,0x0
    800042de:	c62080e7          	jalr	-926(ra) # 80003f3c <write_head>
    800042e2:	bdfd                	j	800041e0 <end_op+0x52>

00000000800042e4 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800042e4:	1101                	addi	sp,sp,-32
    800042e6:	ec06                	sd	ra,24(sp)
    800042e8:	e822                	sd	s0,16(sp)
    800042ea:	e426                	sd	s1,8(sp)
    800042ec:	e04a                	sd	s2,0(sp)
    800042ee:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800042f0:	0001d717          	auipc	a4,0x1d
    800042f4:	64472703          	lw	a4,1604(a4) # 80021934 <log+0x2c>
    800042f8:	47f5                	li	a5,29
    800042fa:	08e7c063          	blt	a5,a4,8000437a <log_write+0x96>
    800042fe:	84aa                	mv	s1,a0
    80004300:	0001d797          	auipc	a5,0x1d
    80004304:	6247a783          	lw	a5,1572(a5) # 80021924 <log+0x1c>
    80004308:	37fd                	addiw	a5,a5,-1
    8000430a:	06f75863          	bge	a4,a5,8000437a <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000430e:	0001d797          	auipc	a5,0x1d
    80004312:	61a7a783          	lw	a5,1562(a5) # 80021928 <log+0x20>
    80004316:	06f05a63          	blez	a5,8000438a <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    8000431a:	0001d917          	auipc	s2,0x1d
    8000431e:	5ee90913          	addi	s2,s2,1518 # 80021908 <log>
    80004322:	854a                	mv	a0,s2
    80004324:	ffffd097          	auipc	ra,0xffffd
    80004328:	8ec080e7          	jalr	-1812(ra) # 80000c10 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    8000432c:	02c92603          	lw	a2,44(s2)
    80004330:	06c05563          	blez	a2,8000439a <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004334:	44cc                	lw	a1,12(s1)
    80004336:	0001d717          	auipc	a4,0x1d
    8000433a:	60270713          	addi	a4,a4,1538 # 80021938 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000433e:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004340:	4314                	lw	a3,0(a4)
    80004342:	04b68d63          	beq	a3,a1,8000439c <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    80004346:	2785                	addiw	a5,a5,1
    80004348:	0711                	addi	a4,a4,4
    8000434a:	fec79be3          	bne	a5,a2,80004340 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000434e:	0621                	addi	a2,a2,8
    80004350:	060a                	slli	a2,a2,0x2
    80004352:	0001d797          	auipc	a5,0x1d
    80004356:	5b678793          	addi	a5,a5,1462 # 80021908 <log>
    8000435a:	963e                	add	a2,a2,a5
    8000435c:	44dc                	lw	a5,12(s1)
    8000435e:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004360:	8526                	mv	a0,s1
    80004362:	fffff097          	auipc	ra,0xfffff
    80004366:	db8080e7          	jalr	-584(ra) # 8000311a <bpin>
    log.lh.n++;
    8000436a:	0001d717          	auipc	a4,0x1d
    8000436e:	59e70713          	addi	a4,a4,1438 # 80021908 <log>
    80004372:	575c                	lw	a5,44(a4)
    80004374:	2785                	addiw	a5,a5,1
    80004376:	d75c                	sw	a5,44(a4)
    80004378:	a83d                	j	800043b6 <log_write+0xd2>
    panic("too big a transaction");
    8000437a:	00004517          	auipc	a0,0x4
    8000437e:	27650513          	addi	a0,a0,630 # 800085f0 <syscalls+0x1f0>
    80004382:	ffffc097          	auipc	ra,0xffffc
    80004386:	1c6080e7          	jalr	454(ra) # 80000548 <panic>
    panic("log_write outside of trans");
    8000438a:	00004517          	auipc	a0,0x4
    8000438e:	27e50513          	addi	a0,a0,638 # 80008608 <syscalls+0x208>
    80004392:	ffffc097          	auipc	ra,0xffffc
    80004396:	1b6080e7          	jalr	438(ra) # 80000548 <panic>
  for (i = 0; i < log.lh.n; i++) {
    8000439a:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    8000439c:	00878713          	addi	a4,a5,8
    800043a0:	00271693          	slli	a3,a4,0x2
    800043a4:	0001d717          	auipc	a4,0x1d
    800043a8:	56470713          	addi	a4,a4,1380 # 80021908 <log>
    800043ac:	9736                	add	a4,a4,a3
    800043ae:	44d4                	lw	a3,12(s1)
    800043b0:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800043b2:	faf607e3          	beq	a2,a5,80004360 <log_write+0x7c>
  }
  release(&log.lock);
    800043b6:	0001d517          	auipc	a0,0x1d
    800043ba:	55250513          	addi	a0,a0,1362 # 80021908 <log>
    800043be:	ffffd097          	auipc	ra,0xffffd
    800043c2:	906080e7          	jalr	-1786(ra) # 80000cc4 <release>
}
    800043c6:	60e2                	ld	ra,24(sp)
    800043c8:	6442                	ld	s0,16(sp)
    800043ca:	64a2                	ld	s1,8(sp)
    800043cc:	6902                	ld	s2,0(sp)
    800043ce:	6105                	addi	sp,sp,32
    800043d0:	8082                	ret

00000000800043d2 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800043d2:	1101                	addi	sp,sp,-32
    800043d4:	ec06                	sd	ra,24(sp)
    800043d6:	e822                	sd	s0,16(sp)
    800043d8:	e426                	sd	s1,8(sp)
    800043da:	e04a                	sd	s2,0(sp)
    800043dc:	1000                	addi	s0,sp,32
    800043de:	84aa                	mv	s1,a0
    800043e0:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800043e2:	00004597          	auipc	a1,0x4
    800043e6:	24658593          	addi	a1,a1,582 # 80008628 <syscalls+0x228>
    800043ea:	0521                	addi	a0,a0,8
    800043ec:	ffffc097          	auipc	ra,0xffffc
    800043f0:	794080e7          	jalr	1940(ra) # 80000b80 <initlock>
  lk->name = name;
    800043f4:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800043f8:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800043fc:	0204a423          	sw	zero,40(s1)
}
    80004400:	60e2                	ld	ra,24(sp)
    80004402:	6442                	ld	s0,16(sp)
    80004404:	64a2                	ld	s1,8(sp)
    80004406:	6902                	ld	s2,0(sp)
    80004408:	6105                	addi	sp,sp,32
    8000440a:	8082                	ret

000000008000440c <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000440c:	1101                	addi	sp,sp,-32
    8000440e:	ec06                	sd	ra,24(sp)
    80004410:	e822                	sd	s0,16(sp)
    80004412:	e426                	sd	s1,8(sp)
    80004414:	e04a                	sd	s2,0(sp)
    80004416:	1000                	addi	s0,sp,32
    80004418:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000441a:	00850913          	addi	s2,a0,8
    8000441e:	854a                	mv	a0,s2
    80004420:	ffffc097          	auipc	ra,0xffffc
    80004424:	7f0080e7          	jalr	2032(ra) # 80000c10 <acquire>
  while (lk->locked) {
    80004428:	409c                	lw	a5,0(s1)
    8000442a:	cb89                	beqz	a5,8000443c <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000442c:	85ca                	mv	a1,s2
    8000442e:	8526                	mv	a0,s1
    80004430:	ffffe097          	auipc	ra,0xffffe
    80004434:	e9e080e7          	jalr	-354(ra) # 800022ce <sleep>
  while (lk->locked) {
    80004438:	409c                	lw	a5,0(s1)
    8000443a:	fbed                	bnez	a5,8000442c <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000443c:	4785                	li	a5,1
    8000443e:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004440:	ffffd097          	auipc	ra,0xffffd
    80004444:	67e080e7          	jalr	1662(ra) # 80001abe <myproc>
    80004448:	5d1c                	lw	a5,56(a0)
    8000444a:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000444c:	854a                	mv	a0,s2
    8000444e:	ffffd097          	auipc	ra,0xffffd
    80004452:	876080e7          	jalr	-1930(ra) # 80000cc4 <release>
}
    80004456:	60e2                	ld	ra,24(sp)
    80004458:	6442                	ld	s0,16(sp)
    8000445a:	64a2                	ld	s1,8(sp)
    8000445c:	6902                	ld	s2,0(sp)
    8000445e:	6105                	addi	sp,sp,32
    80004460:	8082                	ret

0000000080004462 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004462:	1101                	addi	sp,sp,-32
    80004464:	ec06                	sd	ra,24(sp)
    80004466:	e822                	sd	s0,16(sp)
    80004468:	e426                	sd	s1,8(sp)
    8000446a:	e04a                	sd	s2,0(sp)
    8000446c:	1000                	addi	s0,sp,32
    8000446e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004470:	00850913          	addi	s2,a0,8
    80004474:	854a                	mv	a0,s2
    80004476:	ffffc097          	auipc	ra,0xffffc
    8000447a:	79a080e7          	jalr	1946(ra) # 80000c10 <acquire>
  lk->locked = 0;
    8000447e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004482:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004486:	8526                	mv	a0,s1
    80004488:	ffffe097          	auipc	ra,0xffffe
    8000448c:	fcc080e7          	jalr	-52(ra) # 80002454 <wakeup>
  release(&lk->lk);
    80004490:	854a                	mv	a0,s2
    80004492:	ffffd097          	auipc	ra,0xffffd
    80004496:	832080e7          	jalr	-1998(ra) # 80000cc4 <release>
}
    8000449a:	60e2                	ld	ra,24(sp)
    8000449c:	6442                	ld	s0,16(sp)
    8000449e:	64a2                	ld	s1,8(sp)
    800044a0:	6902                	ld	s2,0(sp)
    800044a2:	6105                	addi	sp,sp,32
    800044a4:	8082                	ret

00000000800044a6 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800044a6:	7179                	addi	sp,sp,-48
    800044a8:	f406                	sd	ra,40(sp)
    800044aa:	f022                	sd	s0,32(sp)
    800044ac:	ec26                	sd	s1,24(sp)
    800044ae:	e84a                	sd	s2,16(sp)
    800044b0:	e44e                	sd	s3,8(sp)
    800044b2:	1800                	addi	s0,sp,48
    800044b4:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800044b6:	00850913          	addi	s2,a0,8
    800044ba:	854a                	mv	a0,s2
    800044bc:	ffffc097          	auipc	ra,0xffffc
    800044c0:	754080e7          	jalr	1876(ra) # 80000c10 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800044c4:	409c                	lw	a5,0(s1)
    800044c6:	ef99                	bnez	a5,800044e4 <holdingsleep+0x3e>
    800044c8:	4481                	li	s1,0
  release(&lk->lk);
    800044ca:	854a                	mv	a0,s2
    800044cc:	ffffc097          	auipc	ra,0xffffc
    800044d0:	7f8080e7          	jalr	2040(ra) # 80000cc4 <release>
  return r;
}
    800044d4:	8526                	mv	a0,s1
    800044d6:	70a2                	ld	ra,40(sp)
    800044d8:	7402                	ld	s0,32(sp)
    800044da:	64e2                	ld	s1,24(sp)
    800044dc:	6942                	ld	s2,16(sp)
    800044de:	69a2                	ld	s3,8(sp)
    800044e0:	6145                	addi	sp,sp,48
    800044e2:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800044e4:	0284a983          	lw	s3,40(s1)
    800044e8:	ffffd097          	auipc	ra,0xffffd
    800044ec:	5d6080e7          	jalr	1494(ra) # 80001abe <myproc>
    800044f0:	5d04                	lw	s1,56(a0)
    800044f2:	413484b3          	sub	s1,s1,s3
    800044f6:	0014b493          	seqz	s1,s1
    800044fa:	bfc1                	j	800044ca <holdingsleep+0x24>

00000000800044fc <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800044fc:	1141                	addi	sp,sp,-16
    800044fe:	e406                	sd	ra,8(sp)
    80004500:	e022                	sd	s0,0(sp)
    80004502:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004504:	00004597          	auipc	a1,0x4
    80004508:	13458593          	addi	a1,a1,308 # 80008638 <syscalls+0x238>
    8000450c:	0001d517          	auipc	a0,0x1d
    80004510:	54450513          	addi	a0,a0,1348 # 80021a50 <ftable>
    80004514:	ffffc097          	auipc	ra,0xffffc
    80004518:	66c080e7          	jalr	1644(ra) # 80000b80 <initlock>
}
    8000451c:	60a2                	ld	ra,8(sp)
    8000451e:	6402                	ld	s0,0(sp)
    80004520:	0141                	addi	sp,sp,16
    80004522:	8082                	ret

0000000080004524 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004524:	1101                	addi	sp,sp,-32
    80004526:	ec06                	sd	ra,24(sp)
    80004528:	e822                	sd	s0,16(sp)
    8000452a:	e426                	sd	s1,8(sp)
    8000452c:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000452e:	0001d517          	auipc	a0,0x1d
    80004532:	52250513          	addi	a0,a0,1314 # 80021a50 <ftable>
    80004536:	ffffc097          	auipc	ra,0xffffc
    8000453a:	6da080e7          	jalr	1754(ra) # 80000c10 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000453e:	0001d497          	auipc	s1,0x1d
    80004542:	52a48493          	addi	s1,s1,1322 # 80021a68 <ftable+0x18>
    80004546:	0001e717          	auipc	a4,0x1e
    8000454a:	4c270713          	addi	a4,a4,1218 # 80022a08 <ftable+0xfb8>
    if(f->ref == 0){
    8000454e:	40dc                	lw	a5,4(s1)
    80004550:	cf99                	beqz	a5,8000456e <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004552:	02848493          	addi	s1,s1,40
    80004556:	fee49ce3          	bne	s1,a4,8000454e <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000455a:	0001d517          	auipc	a0,0x1d
    8000455e:	4f650513          	addi	a0,a0,1270 # 80021a50 <ftable>
    80004562:	ffffc097          	auipc	ra,0xffffc
    80004566:	762080e7          	jalr	1890(ra) # 80000cc4 <release>
  return 0;
    8000456a:	4481                	li	s1,0
    8000456c:	a819                	j	80004582 <filealloc+0x5e>
      f->ref = 1;
    8000456e:	4785                	li	a5,1
    80004570:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004572:	0001d517          	auipc	a0,0x1d
    80004576:	4de50513          	addi	a0,a0,1246 # 80021a50 <ftable>
    8000457a:	ffffc097          	auipc	ra,0xffffc
    8000457e:	74a080e7          	jalr	1866(ra) # 80000cc4 <release>
}
    80004582:	8526                	mv	a0,s1
    80004584:	60e2                	ld	ra,24(sp)
    80004586:	6442                	ld	s0,16(sp)
    80004588:	64a2                	ld	s1,8(sp)
    8000458a:	6105                	addi	sp,sp,32
    8000458c:	8082                	ret

000000008000458e <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000458e:	1101                	addi	sp,sp,-32
    80004590:	ec06                	sd	ra,24(sp)
    80004592:	e822                	sd	s0,16(sp)
    80004594:	e426                	sd	s1,8(sp)
    80004596:	1000                	addi	s0,sp,32
    80004598:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000459a:	0001d517          	auipc	a0,0x1d
    8000459e:	4b650513          	addi	a0,a0,1206 # 80021a50 <ftable>
    800045a2:	ffffc097          	auipc	ra,0xffffc
    800045a6:	66e080e7          	jalr	1646(ra) # 80000c10 <acquire>
  if(f->ref < 1)
    800045aa:	40dc                	lw	a5,4(s1)
    800045ac:	02f05263          	blez	a5,800045d0 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800045b0:	2785                	addiw	a5,a5,1
    800045b2:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800045b4:	0001d517          	auipc	a0,0x1d
    800045b8:	49c50513          	addi	a0,a0,1180 # 80021a50 <ftable>
    800045bc:	ffffc097          	auipc	ra,0xffffc
    800045c0:	708080e7          	jalr	1800(ra) # 80000cc4 <release>
  return f;
}
    800045c4:	8526                	mv	a0,s1
    800045c6:	60e2                	ld	ra,24(sp)
    800045c8:	6442                	ld	s0,16(sp)
    800045ca:	64a2                	ld	s1,8(sp)
    800045cc:	6105                	addi	sp,sp,32
    800045ce:	8082                	ret
    panic("filedup");
    800045d0:	00004517          	auipc	a0,0x4
    800045d4:	07050513          	addi	a0,a0,112 # 80008640 <syscalls+0x240>
    800045d8:	ffffc097          	auipc	ra,0xffffc
    800045dc:	f70080e7          	jalr	-144(ra) # 80000548 <panic>

00000000800045e0 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800045e0:	7139                	addi	sp,sp,-64
    800045e2:	fc06                	sd	ra,56(sp)
    800045e4:	f822                	sd	s0,48(sp)
    800045e6:	f426                	sd	s1,40(sp)
    800045e8:	f04a                	sd	s2,32(sp)
    800045ea:	ec4e                	sd	s3,24(sp)
    800045ec:	e852                	sd	s4,16(sp)
    800045ee:	e456                	sd	s5,8(sp)
    800045f0:	0080                	addi	s0,sp,64
    800045f2:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800045f4:	0001d517          	auipc	a0,0x1d
    800045f8:	45c50513          	addi	a0,a0,1116 # 80021a50 <ftable>
    800045fc:	ffffc097          	auipc	ra,0xffffc
    80004600:	614080e7          	jalr	1556(ra) # 80000c10 <acquire>
  if(f->ref < 1)
    80004604:	40dc                	lw	a5,4(s1)
    80004606:	06f05163          	blez	a5,80004668 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000460a:	37fd                	addiw	a5,a5,-1
    8000460c:	0007871b          	sext.w	a4,a5
    80004610:	c0dc                	sw	a5,4(s1)
    80004612:	06e04363          	bgtz	a4,80004678 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004616:	0004a903          	lw	s2,0(s1)
    8000461a:	0094ca83          	lbu	s5,9(s1)
    8000461e:	0104ba03          	ld	s4,16(s1)
    80004622:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004626:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000462a:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000462e:	0001d517          	auipc	a0,0x1d
    80004632:	42250513          	addi	a0,a0,1058 # 80021a50 <ftable>
    80004636:	ffffc097          	auipc	ra,0xffffc
    8000463a:	68e080e7          	jalr	1678(ra) # 80000cc4 <release>

  if(ff.type == FD_PIPE){
    8000463e:	4785                	li	a5,1
    80004640:	04f90d63          	beq	s2,a5,8000469a <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004644:	3979                	addiw	s2,s2,-2
    80004646:	4785                	li	a5,1
    80004648:	0527e063          	bltu	a5,s2,80004688 <fileclose+0xa8>
    begin_op();
    8000464c:	00000097          	auipc	ra,0x0
    80004650:	ac2080e7          	jalr	-1342(ra) # 8000410e <begin_op>
    iput(ff.ip);
    80004654:	854e                	mv	a0,s3
    80004656:	fffff097          	auipc	ra,0xfffff
    8000465a:	2b2080e7          	jalr	690(ra) # 80003908 <iput>
    end_op();
    8000465e:	00000097          	auipc	ra,0x0
    80004662:	b30080e7          	jalr	-1232(ra) # 8000418e <end_op>
    80004666:	a00d                	j	80004688 <fileclose+0xa8>
    panic("fileclose");
    80004668:	00004517          	auipc	a0,0x4
    8000466c:	fe050513          	addi	a0,a0,-32 # 80008648 <syscalls+0x248>
    80004670:	ffffc097          	auipc	ra,0xffffc
    80004674:	ed8080e7          	jalr	-296(ra) # 80000548 <panic>
    release(&ftable.lock);
    80004678:	0001d517          	auipc	a0,0x1d
    8000467c:	3d850513          	addi	a0,a0,984 # 80021a50 <ftable>
    80004680:	ffffc097          	auipc	ra,0xffffc
    80004684:	644080e7          	jalr	1604(ra) # 80000cc4 <release>
  }
}
    80004688:	70e2                	ld	ra,56(sp)
    8000468a:	7442                	ld	s0,48(sp)
    8000468c:	74a2                	ld	s1,40(sp)
    8000468e:	7902                	ld	s2,32(sp)
    80004690:	69e2                	ld	s3,24(sp)
    80004692:	6a42                	ld	s4,16(sp)
    80004694:	6aa2                	ld	s5,8(sp)
    80004696:	6121                	addi	sp,sp,64
    80004698:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000469a:	85d6                	mv	a1,s5
    8000469c:	8552                	mv	a0,s4
    8000469e:	00000097          	auipc	ra,0x0
    800046a2:	372080e7          	jalr	882(ra) # 80004a10 <pipeclose>
    800046a6:	b7cd                	j	80004688 <fileclose+0xa8>

00000000800046a8 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800046a8:	715d                	addi	sp,sp,-80
    800046aa:	e486                	sd	ra,72(sp)
    800046ac:	e0a2                	sd	s0,64(sp)
    800046ae:	fc26                	sd	s1,56(sp)
    800046b0:	f84a                	sd	s2,48(sp)
    800046b2:	f44e                	sd	s3,40(sp)
    800046b4:	0880                	addi	s0,sp,80
    800046b6:	84aa                	mv	s1,a0
    800046b8:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800046ba:	ffffd097          	auipc	ra,0xffffd
    800046be:	404080e7          	jalr	1028(ra) # 80001abe <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800046c2:	409c                	lw	a5,0(s1)
    800046c4:	37f9                	addiw	a5,a5,-2
    800046c6:	4705                	li	a4,1
    800046c8:	04f76763          	bltu	a4,a5,80004716 <filestat+0x6e>
    800046cc:	892a                	mv	s2,a0
    ilock(f->ip);
    800046ce:	6c88                	ld	a0,24(s1)
    800046d0:	fffff097          	auipc	ra,0xfffff
    800046d4:	07e080e7          	jalr	126(ra) # 8000374e <ilock>
    stati(f->ip, &st);
    800046d8:	fb840593          	addi	a1,s0,-72
    800046dc:	6c88                	ld	a0,24(s1)
    800046de:	fffff097          	auipc	ra,0xfffff
    800046e2:	2fa080e7          	jalr	762(ra) # 800039d8 <stati>
    iunlock(f->ip);
    800046e6:	6c88                	ld	a0,24(s1)
    800046e8:	fffff097          	auipc	ra,0xfffff
    800046ec:	128080e7          	jalr	296(ra) # 80003810 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800046f0:	46e1                	li	a3,24
    800046f2:	fb840613          	addi	a2,s0,-72
    800046f6:	85ce                	mv	a1,s3
    800046f8:	05093503          	ld	a0,80(s2)
    800046fc:	ffffd097          	auipc	ra,0xffffd
    80004700:	082080e7          	jalr	130(ra) # 8000177e <copyout>
    80004704:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004708:	60a6                	ld	ra,72(sp)
    8000470a:	6406                	ld	s0,64(sp)
    8000470c:	74e2                	ld	s1,56(sp)
    8000470e:	7942                	ld	s2,48(sp)
    80004710:	79a2                	ld	s3,40(sp)
    80004712:	6161                	addi	sp,sp,80
    80004714:	8082                	ret
  return -1;
    80004716:	557d                	li	a0,-1
    80004718:	bfc5                	j	80004708 <filestat+0x60>

000000008000471a <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000471a:	7179                	addi	sp,sp,-48
    8000471c:	f406                	sd	ra,40(sp)
    8000471e:	f022                	sd	s0,32(sp)
    80004720:	ec26                	sd	s1,24(sp)
    80004722:	e84a                	sd	s2,16(sp)
    80004724:	e44e                	sd	s3,8(sp)
    80004726:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004728:	00854783          	lbu	a5,8(a0)
    8000472c:	c3d5                	beqz	a5,800047d0 <fileread+0xb6>
    8000472e:	84aa                	mv	s1,a0
    80004730:	89ae                	mv	s3,a1
    80004732:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004734:	411c                	lw	a5,0(a0)
    80004736:	4705                	li	a4,1
    80004738:	04e78963          	beq	a5,a4,8000478a <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000473c:	470d                	li	a4,3
    8000473e:	04e78d63          	beq	a5,a4,80004798 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004742:	4709                	li	a4,2
    80004744:	06e79e63          	bne	a5,a4,800047c0 <fileread+0xa6>
    ilock(f->ip);
    80004748:	6d08                	ld	a0,24(a0)
    8000474a:	fffff097          	auipc	ra,0xfffff
    8000474e:	004080e7          	jalr	4(ra) # 8000374e <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004752:	874a                	mv	a4,s2
    80004754:	5094                	lw	a3,32(s1)
    80004756:	864e                	mv	a2,s3
    80004758:	4585                	li	a1,1
    8000475a:	6c88                	ld	a0,24(s1)
    8000475c:	fffff097          	auipc	ra,0xfffff
    80004760:	2a6080e7          	jalr	678(ra) # 80003a02 <readi>
    80004764:	892a                	mv	s2,a0
    80004766:	00a05563          	blez	a0,80004770 <fileread+0x56>
      f->off += r;
    8000476a:	509c                	lw	a5,32(s1)
    8000476c:	9fa9                	addw	a5,a5,a0
    8000476e:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004770:	6c88                	ld	a0,24(s1)
    80004772:	fffff097          	auipc	ra,0xfffff
    80004776:	09e080e7          	jalr	158(ra) # 80003810 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000477a:	854a                	mv	a0,s2
    8000477c:	70a2                	ld	ra,40(sp)
    8000477e:	7402                	ld	s0,32(sp)
    80004780:	64e2                	ld	s1,24(sp)
    80004782:	6942                	ld	s2,16(sp)
    80004784:	69a2                	ld	s3,8(sp)
    80004786:	6145                	addi	sp,sp,48
    80004788:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000478a:	6908                	ld	a0,16(a0)
    8000478c:	00000097          	auipc	ra,0x0
    80004790:	418080e7          	jalr	1048(ra) # 80004ba4 <piperead>
    80004794:	892a                	mv	s2,a0
    80004796:	b7d5                	j	8000477a <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004798:	02451783          	lh	a5,36(a0)
    8000479c:	03079693          	slli	a3,a5,0x30
    800047a0:	92c1                	srli	a3,a3,0x30
    800047a2:	4725                	li	a4,9
    800047a4:	02d76863          	bltu	a4,a3,800047d4 <fileread+0xba>
    800047a8:	0792                	slli	a5,a5,0x4
    800047aa:	0001d717          	auipc	a4,0x1d
    800047ae:	20670713          	addi	a4,a4,518 # 800219b0 <devsw>
    800047b2:	97ba                	add	a5,a5,a4
    800047b4:	639c                	ld	a5,0(a5)
    800047b6:	c38d                	beqz	a5,800047d8 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800047b8:	4505                	li	a0,1
    800047ba:	9782                	jalr	a5
    800047bc:	892a                	mv	s2,a0
    800047be:	bf75                	j	8000477a <fileread+0x60>
    panic("fileread");
    800047c0:	00004517          	auipc	a0,0x4
    800047c4:	e9850513          	addi	a0,a0,-360 # 80008658 <syscalls+0x258>
    800047c8:	ffffc097          	auipc	ra,0xffffc
    800047cc:	d80080e7          	jalr	-640(ra) # 80000548 <panic>
    return -1;
    800047d0:	597d                	li	s2,-1
    800047d2:	b765                	j	8000477a <fileread+0x60>
      return -1;
    800047d4:	597d                	li	s2,-1
    800047d6:	b755                	j	8000477a <fileread+0x60>
    800047d8:	597d                	li	s2,-1
    800047da:	b745                	j	8000477a <fileread+0x60>

00000000800047dc <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    800047dc:	00954783          	lbu	a5,9(a0)
    800047e0:	14078563          	beqz	a5,8000492a <filewrite+0x14e>
{
    800047e4:	715d                	addi	sp,sp,-80
    800047e6:	e486                	sd	ra,72(sp)
    800047e8:	e0a2                	sd	s0,64(sp)
    800047ea:	fc26                	sd	s1,56(sp)
    800047ec:	f84a                	sd	s2,48(sp)
    800047ee:	f44e                	sd	s3,40(sp)
    800047f0:	f052                	sd	s4,32(sp)
    800047f2:	ec56                	sd	s5,24(sp)
    800047f4:	e85a                	sd	s6,16(sp)
    800047f6:	e45e                	sd	s7,8(sp)
    800047f8:	e062                	sd	s8,0(sp)
    800047fa:	0880                	addi	s0,sp,80
    800047fc:	892a                	mv	s2,a0
    800047fe:	8aae                	mv	s5,a1
    80004800:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004802:	411c                	lw	a5,0(a0)
    80004804:	4705                	li	a4,1
    80004806:	02e78263          	beq	a5,a4,8000482a <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000480a:	470d                	li	a4,3
    8000480c:	02e78563          	beq	a5,a4,80004836 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004810:	4709                	li	a4,2
    80004812:	10e79463          	bne	a5,a4,8000491a <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004816:	0ec05e63          	blez	a2,80004912 <filewrite+0x136>
    int i = 0;
    8000481a:	4981                	li	s3,0
    8000481c:	6b05                	lui	s6,0x1
    8000481e:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004822:	6b85                	lui	s7,0x1
    80004824:	c00b8b9b          	addiw	s7,s7,-1024
    80004828:	a851                	j	800048bc <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    8000482a:	6908                	ld	a0,16(a0)
    8000482c:	00000097          	auipc	ra,0x0
    80004830:	254080e7          	jalr	596(ra) # 80004a80 <pipewrite>
    80004834:	a85d                	j	800048ea <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004836:	02451783          	lh	a5,36(a0)
    8000483a:	03079693          	slli	a3,a5,0x30
    8000483e:	92c1                	srli	a3,a3,0x30
    80004840:	4725                	li	a4,9
    80004842:	0ed76663          	bltu	a4,a3,8000492e <filewrite+0x152>
    80004846:	0792                	slli	a5,a5,0x4
    80004848:	0001d717          	auipc	a4,0x1d
    8000484c:	16870713          	addi	a4,a4,360 # 800219b0 <devsw>
    80004850:	97ba                	add	a5,a5,a4
    80004852:	679c                	ld	a5,8(a5)
    80004854:	cff9                	beqz	a5,80004932 <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    80004856:	4505                	li	a0,1
    80004858:	9782                	jalr	a5
    8000485a:	a841                	j	800048ea <filewrite+0x10e>
    8000485c:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004860:	00000097          	auipc	ra,0x0
    80004864:	8ae080e7          	jalr	-1874(ra) # 8000410e <begin_op>
      ilock(f->ip);
    80004868:	01893503          	ld	a0,24(s2)
    8000486c:	fffff097          	auipc	ra,0xfffff
    80004870:	ee2080e7          	jalr	-286(ra) # 8000374e <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004874:	8762                	mv	a4,s8
    80004876:	02092683          	lw	a3,32(s2)
    8000487a:	01598633          	add	a2,s3,s5
    8000487e:	4585                	li	a1,1
    80004880:	01893503          	ld	a0,24(s2)
    80004884:	fffff097          	auipc	ra,0xfffff
    80004888:	276080e7          	jalr	630(ra) # 80003afa <writei>
    8000488c:	84aa                	mv	s1,a0
    8000488e:	02a05f63          	blez	a0,800048cc <filewrite+0xf0>
        f->off += r;
    80004892:	02092783          	lw	a5,32(s2)
    80004896:	9fa9                	addw	a5,a5,a0
    80004898:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000489c:	01893503          	ld	a0,24(s2)
    800048a0:	fffff097          	auipc	ra,0xfffff
    800048a4:	f70080e7          	jalr	-144(ra) # 80003810 <iunlock>
      end_op();
    800048a8:	00000097          	auipc	ra,0x0
    800048ac:	8e6080e7          	jalr	-1818(ra) # 8000418e <end_op>

      if(r < 0)
        break;
      if(r != n1)
    800048b0:	049c1963          	bne	s8,s1,80004902 <filewrite+0x126>
        panic("short filewrite");
      i += r;
    800048b4:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800048b8:	0349d663          	bge	s3,s4,800048e4 <filewrite+0x108>
      int n1 = n - i;
    800048bc:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800048c0:	84be                	mv	s1,a5
    800048c2:	2781                	sext.w	a5,a5
    800048c4:	f8fb5ce3          	bge	s6,a5,8000485c <filewrite+0x80>
    800048c8:	84de                	mv	s1,s7
    800048ca:	bf49                	j	8000485c <filewrite+0x80>
      iunlock(f->ip);
    800048cc:	01893503          	ld	a0,24(s2)
    800048d0:	fffff097          	auipc	ra,0xfffff
    800048d4:	f40080e7          	jalr	-192(ra) # 80003810 <iunlock>
      end_op();
    800048d8:	00000097          	auipc	ra,0x0
    800048dc:	8b6080e7          	jalr	-1866(ra) # 8000418e <end_op>
      if(r < 0)
    800048e0:	fc04d8e3          	bgez	s1,800048b0 <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    800048e4:	8552                	mv	a0,s4
    800048e6:	033a1863          	bne	s4,s3,80004916 <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800048ea:	60a6                	ld	ra,72(sp)
    800048ec:	6406                	ld	s0,64(sp)
    800048ee:	74e2                	ld	s1,56(sp)
    800048f0:	7942                	ld	s2,48(sp)
    800048f2:	79a2                	ld	s3,40(sp)
    800048f4:	7a02                	ld	s4,32(sp)
    800048f6:	6ae2                	ld	s5,24(sp)
    800048f8:	6b42                	ld	s6,16(sp)
    800048fa:	6ba2                	ld	s7,8(sp)
    800048fc:	6c02                	ld	s8,0(sp)
    800048fe:	6161                	addi	sp,sp,80
    80004900:	8082                	ret
        panic("short filewrite");
    80004902:	00004517          	auipc	a0,0x4
    80004906:	d6650513          	addi	a0,a0,-666 # 80008668 <syscalls+0x268>
    8000490a:	ffffc097          	auipc	ra,0xffffc
    8000490e:	c3e080e7          	jalr	-962(ra) # 80000548 <panic>
    int i = 0;
    80004912:	4981                	li	s3,0
    80004914:	bfc1                	j	800048e4 <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004916:	557d                	li	a0,-1
    80004918:	bfc9                	j	800048ea <filewrite+0x10e>
    panic("filewrite");
    8000491a:	00004517          	auipc	a0,0x4
    8000491e:	d5e50513          	addi	a0,a0,-674 # 80008678 <syscalls+0x278>
    80004922:	ffffc097          	auipc	ra,0xffffc
    80004926:	c26080e7          	jalr	-986(ra) # 80000548 <panic>
    return -1;
    8000492a:	557d                	li	a0,-1
}
    8000492c:	8082                	ret
      return -1;
    8000492e:	557d                	li	a0,-1
    80004930:	bf6d                	j	800048ea <filewrite+0x10e>
    80004932:	557d                	li	a0,-1
    80004934:	bf5d                	j	800048ea <filewrite+0x10e>

0000000080004936 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004936:	7179                	addi	sp,sp,-48
    80004938:	f406                	sd	ra,40(sp)
    8000493a:	f022                	sd	s0,32(sp)
    8000493c:	ec26                	sd	s1,24(sp)
    8000493e:	e84a                	sd	s2,16(sp)
    80004940:	e44e                	sd	s3,8(sp)
    80004942:	e052                	sd	s4,0(sp)
    80004944:	1800                	addi	s0,sp,48
    80004946:	84aa                	mv	s1,a0
    80004948:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000494a:	0005b023          	sd	zero,0(a1)
    8000494e:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004952:	00000097          	auipc	ra,0x0
    80004956:	bd2080e7          	jalr	-1070(ra) # 80004524 <filealloc>
    8000495a:	e088                	sd	a0,0(s1)
    8000495c:	c551                	beqz	a0,800049e8 <pipealloc+0xb2>
    8000495e:	00000097          	auipc	ra,0x0
    80004962:	bc6080e7          	jalr	-1082(ra) # 80004524 <filealloc>
    80004966:	00aa3023          	sd	a0,0(s4)
    8000496a:	c92d                	beqz	a0,800049dc <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    8000496c:	ffffc097          	auipc	ra,0xffffc
    80004970:	1b4080e7          	jalr	436(ra) # 80000b20 <kalloc>
    80004974:	892a                	mv	s2,a0
    80004976:	c125                	beqz	a0,800049d6 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004978:	4985                	li	s3,1
    8000497a:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    8000497e:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004982:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004986:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    8000498a:	00004597          	auipc	a1,0x4
    8000498e:	cfe58593          	addi	a1,a1,-770 # 80008688 <syscalls+0x288>
    80004992:	ffffc097          	auipc	ra,0xffffc
    80004996:	1ee080e7          	jalr	494(ra) # 80000b80 <initlock>
  (*f0)->type = FD_PIPE;
    8000499a:	609c                	ld	a5,0(s1)
    8000499c:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800049a0:	609c                	ld	a5,0(s1)
    800049a2:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800049a6:	609c                	ld	a5,0(s1)
    800049a8:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800049ac:	609c                	ld	a5,0(s1)
    800049ae:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800049b2:	000a3783          	ld	a5,0(s4)
    800049b6:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800049ba:	000a3783          	ld	a5,0(s4)
    800049be:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800049c2:	000a3783          	ld	a5,0(s4)
    800049c6:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800049ca:	000a3783          	ld	a5,0(s4)
    800049ce:	0127b823          	sd	s2,16(a5)
  return 0;
    800049d2:	4501                	li	a0,0
    800049d4:	a025                	j	800049fc <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800049d6:	6088                	ld	a0,0(s1)
    800049d8:	e501                	bnez	a0,800049e0 <pipealloc+0xaa>
    800049da:	a039                	j	800049e8 <pipealloc+0xb2>
    800049dc:	6088                	ld	a0,0(s1)
    800049de:	c51d                	beqz	a0,80004a0c <pipealloc+0xd6>
    fileclose(*f0);
    800049e0:	00000097          	auipc	ra,0x0
    800049e4:	c00080e7          	jalr	-1024(ra) # 800045e0 <fileclose>
  if(*f1)
    800049e8:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800049ec:	557d                	li	a0,-1
  if(*f1)
    800049ee:	c799                	beqz	a5,800049fc <pipealloc+0xc6>
    fileclose(*f1);
    800049f0:	853e                	mv	a0,a5
    800049f2:	00000097          	auipc	ra,0x0
    800049f6:	bee080e7          	jalr	-1042(ra) # 800045e0 <fileclose>
  return -1;
    800049fa:	557d                	li	a0,-1
}
    800049fc:	70a2                	ld	ra,40(sp)
    800049fe:	7402                	ld	s0,32(sp)
    80004a00:	64e2                	ld	s1,24(sp)
    80004a02:	6942                	ld	s2,16(sp)
    80004a04:	69a2                	ld	s3,8(sp)
    80004a06:	6a02                	ld	s4,0(sp)
    80004a08:	6145                	addi	sp,sp,48
    80004a0a:	8082                	ret
  return -1;
    80004a0c:	557d                	li	a0,-1
    80004a0e:	b7fd                	j	800049fc <pipealloc+0xc6>

0000000080004a10 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a10:	1101                	addi	sp,sp,-32
    80004a12:	ec06                	sd	ra,24(sp)
    80004a14:	e822                	sd	s0,16(sp)
    80004a16:	e426                	sd	s1,8(sp)
    80004a18:	e04a                	sd	s2,0(sp)
    80004a1a:	1000                	addi	s0,sp,32
    80004a1c:	84aa                	mv	s1,a0
    80004a1e:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a20:	ffffc097          	auipc	ra,0xffffc
    80004a24:	1f0080e7          	jalr	496(ra) # 80000c10 <acquire>
  if(writable){
    80004a28:	02090d63          	beqz	s2,80004a62 <pipeclose+0x52>
    pi->writeopen = 0;
    80004a2c:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a30:	21848513          	addi	a0,s1,536
    80004a34:	ffffe097          	auipc	ra,0xffffe
    80004a38:	a20080e7          	jalr	-1504(ra) # 80002454 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a3c:	2204b783          	ld	a5,544(s1)
    80004a40:	eb95                	bnez	a5,80004a74 <pipeclose+0x64>
    release(&pi->lock);
    80004a42:	8526                	mv	a0,s1
    80004a44:	ffffc097          	auipc	ra,0xffffc
    80004a48:	280080e7          	jalr	640(ra) # 80000cc4 <release>
    kfree((char*)pi);
    80004a4c:	8526                	mv	a0,s1
    80004a4e:	ffffc097          	auipc	ra,0xffffc
    80004a52:	fd6080e7          	jalr	-42(ra) # 80000a24 <kfree>
  } else
    release(&pi->lock);
}
    80004a56:	60e2                	ld	ra,24(sp)
    80004a58:	6442                	ld	s0,16(sp)
    80004a5a:	64a2                	ld	s1,8(sp)
    80004a5c:	6902                	ld	s2,0(sp)
    80004a5e:	6105                	addi	sp,sp,32
    80004a60:	8082                	ret
    pi->readopen = 0;
    80004a62:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004a66:	21c48513          	addi	a0,s1,540
    80004a6a:	ffffe097          	auipc	ra,0xffffe
    80004a6e:	9ea080e7          	jalr	-1558(ra) # 80002454 <wakeup>
    80004a72:	b7e9                	j	80004a3c <pipeclose+0x2c>
    release(&pi->lock);
    80004a74:	8526                	mv	a0,s1
    80004a76:	ffffc097          	auipc	ra,0xffffc
    80004a7a:	24e080e7          	jalr	590(ra) # 80000cc4 <release>
}
    80004a7e:	bfe1                	j	80004a56 <pipeclose+0x46>

0000000080004a80 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004a80:	7119                	addi	sp,sp,-128
    80004a82:	fc86                	sd	ra,120(sp)
    80004a84:	f8a2                	sd	s0,112(sp)
    80004a86:	f4a6                	sd	s1,104(sp)
    80004a88:	f0ca                	sd	s2,96(sp)
    80004a8a:	ecce                	sd	s3,88(sp)
    80004a8c:	e8d2                	sd	s4,80(sp)
    80004a8e:	e4d6                	sd	s5,72(sp)
    80004a90:	e0da                	sd	s6,64(sp)
    80004a92:	fc5e                	sd	s7,56(sp)
    80004a94:	f862                	sd	s8,48(sp)
    80004a96:	f466                	sd	s9,40(sp)
    80004a98:	f06a                	sd	s10,32(sp)
    80004a9a:	ec6e                	sd	s11,24(sp)
    80004a9c:	0100                	addi	s0,sp,128
    80004a9e:	84aa                	mv	s1,a0
    80004aa0:	8cae                	mv	s9,a1
    80004aa2:	8b32                	mv	s6,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004aa4:	ffffd097          	auipc	ra,0xffffd
    80004aa8:	01a080e7          	jalr	26(ra) # 80001abe <myproc>
    80004aac:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004aae:	8526                	mv	a0,s1
    80004ab0:	ffffc097          	auipc	ra,0xffffc
    80004ab4:	160080e7          	jalr	352(ra) # 80000c10 <acquire>
  for(i = 0; i < n; i++){
    80004ab8:	0d605963          	blez	s6,80004b8a <pipewrite+0x10a>
    80004abc:	89a6                	mv	s3,s1
    80004abe:	3b7d                	addiw	s6,s6,-1
    80004ac0:	1b02                	slli	s6,s6,0x20
    80004ac2:	020b5b13          	srli	s6,s6,0x20
    80004ac6:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004ac8:	21848a93          	addi	s5,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004acc:	21c48a13          	addi	s4,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ad0:	5dfd                	li	s11,-1
    80004ad2:	000b8d1b          	sext.w	s10,s7
    80004ad6:	8c6a                	mv	s8,s10
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004ad8:	2184a783          	lw	a5,536(s1)
    80004adc:	21c4a703          	lw	a4,540(s1)
    80004ae0:	2007879b          	addiw	a5,a5,512
    80004ae4:	02f71b63          	bne	a4,a5,80004b1a <pipewrite+0x9a>
      if(pi->readopen == 0 || pr->killed){
    80004ae8:	2204a783          	lw	a5,544(s1)
    80004aec:	cbad                	beqz	a5,80004b5e <pipewrite+0xde>
    80004aee:	03092783          	lw	a5,48(s2)
    80004af2:	e7b5                	bnez	a5,80004b5e <pipewrite+0xde>
      wakeup(&pi->nread);
    80004af4:	8556                	mv	a0,s5
    80004af6:	ffffe097          	auipc	ra,0xffffe
    80004afa:	95e080e7          	jalr	-1698(ra) # 80002454 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004afe:	85ce                	mv	a1,s3
    80004b00:	8552                	mv	a0,s4
    80004b02:	ffffd097          	auipc	ra,0xffffd
    80004b06:	7cc080e7          	jalr	1996(ra) # 800022ce <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004b0a:	2184a783          	lw	a5,536(s1)
    80004b0e:	21c4a703          	lw	a4,540(s1)
    80004b12:	2007879b          	addiw	a5,a5,512
    80004b16:	fcf709e3          	beq	a4,a5,80004ae8 <pipewrite+0x68>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b1a:	4685                	li	a3,1
    80004b1c:	019b8633          	add	a2,s7,s9
    80004b20:	f8f40593          	addi	a1,s0,-113
    80004b24:	05093503          	ld	a0,80(s2)
    80004b28:	ffffd097          	auipc	ra,0xffffd
    80004b2c:	cfc080e7          	jalr	-772(ra) # 80001824 <copyin>
    80004b30:	05b50e63          	beq	a0,s11,80004b8c <pipewrite+0x10c>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b34:	21c4a783          	lw	a5,540(s1)
    80004b38:	0017871b          	addiw	a4,a5,1
    80004b3c:	20e4ae23          	sw	a4,540(s1)
    80004b40:	1ff7f793          	andi	a5,a5,511
    80004b44:	97a6                	add	a5,a5,s1
    80004b46:	f8f44703          	lbu	a4,-113(s0)
    80004b4a:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004b4e:	001d0c1b          	addiw	s8,s10,1
    80004b52:	001b8793          	addi	a5,s7,1 # 1001 <_entry-0x7fffefff>
    80004b56:	036b8b63          	beq	s7,s6,80004b8c <pipewrite+0x10c>
    80004b5a:	8bbe                	mv	s7,a5
    80004b5c:	bf9d                	j	80004ad2 <pipewrite+0x52>
        release(&pi->lock);
    80004b5e:	8526                	mv	a0,s1
    80004b60:	ffffc097          	auipc	ra,0xffffc
    80004b64:	164080e7          	jalr	356(ra) # 80000cc4 <release>
        return -1;
    80004b68:	5c7d                	li	s8,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);
  return i;
}
    80004b6a:	8562                	mv	a0,s8
    80004b6c:	70e6                	ld	ra,120(sp)
    80004b6e:	7446                	ld	s0,112(sp)
    80004b70:	74a6                	ld	s1,104(sp)
    80004b72:	7906                	ld	s2,96(sp)
    80004b74:	69e6                	ld	s3,88(sp)
    80004b76:	6a46                	ld	s4,80(sp)
    80004b78:	6aa6                	ld	s5,72(sp)
    80004b7a:	6b06                	ld	s6,64(sp)
    80004b7c:	7be2                	ld	s7,56(sp)
    80004b7e:	7c42                	ld	s8,48(sp)
    80004b80:	7ca2                	ld	s9,40(sp)
    80004b82:	7d02                	ld	s10,32(sp)
    80004b84:	6de2                	ld	s11,24(sp)
    80004b86:	6109                	addi	sp,sp,128
    80004b88:	8082                	ret
  for(i = 0; i < n; i++){
    80004b8a:	4c01                	li	s8,0
  wakeup(&pi->nread);
    80004b8c:	21848513          	addi	a0,s1,536
    80004b90:	ffffe097          	auipc	ra,0xffffe
    80004b94:	8c4080e7          	jalr	-1852(ra) # 80002454 <wakeup>
  release(&pi->lock);
    80004b98:	8526                	mv	a0,s1
    80004b9a:	ffffc097          	auipc	ra,0xffffc
    80004b9e:	12a080e7          	jalr	298(ra) # 80000cc4 <release>
  return i;
    80004ba2:	b7e1                	j	80004b6a <pipewrite+0xea>

0000000080004ba4 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004ba4:	715d                	addi	sp,sp,-80
    80004ba6:	e486                	sd	ra,72(sp)
    80004ba8:	e0a2                	sd	s0,64(sp)
    80004baa:	fc26                	sd	s1,56(sp)
    80004bac:	f84a                	sd	s2,48(sp)
    80004bae:	f44e                	sd	s3,40(sp)
    80004bb0:	f052                	sd	s4,32(sp)
    80004bb2:	ec56                	sd	s5,24(sp)
    80004bb4:	e85a                	sd	s6,16(sp)
    80004bb6:	0880                	addi	s0,sp,80
    80004bb8:	84aa                	mv	s1,a0
    80004bba:	892e                	mv	s2,a1
    80004bbc:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004bbe:	ffffd097          	auipc	ra,0xffffd
    80004bc2:	f00080e7          	jalr	-256(ra) # 80001abe <myproc>
    80004bc6:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004bc8:	8b26                	mv	s6,s1
    80004bca:	8526                	mv	a0,s1
    80004bcc:	ffffc097          	auipc	ra,0xffffc
    80004bd0:	044080e7          	jalr	68(ra) # 80000c10 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bd4:	2184a703          	lw	a4,536(s1)
    80004bd8:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004bdc:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004be0:	02f71463          	bne	a4,a5,80004c08 <piperead+0x64>
    80004be4:	2244a783          	lw	a5,548(s1)
    80004be8:	c385                	beqz	a5,80004c08 <piperead+0x64>
    if(pr->killed){
    80004bea:	030a2783          	lw	a5,48(s4)
    80004bee:	ebc1                	bnez	a5,80004c7e <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004bf0:	85da                	mv	a1,s6
    80004bf2:	854e                	mv	a0,s3
    80004bf4:	ffffd097          	auipc	ra,0xffffd
    80004bf8:	6da080e7          	jalr	1754(ra) # 800022ce <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bfc:	2184a703          	lw	a4,536(s1)
    80004c00:	21c4a783          	lw	a5,540(s1)
    80004c04:	fef700e3          	beq	a4,a5,80004be4 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c08:	09505263          	blez	s5,80004c8c <piperead+0xe8>
    80004c0c:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c0e:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004c10:	2184a783          	lw	a5,536(s1)
    80004c14:	21c4a703          	lw	a4,540(s1)
    80004c18:	02f70d63          	beq	a4,a5,80004c52 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c1c:	0017871b          	addiw	a4,a5,1
    80004c20:	20e4ac23          	sw	a4,536(s1)
    80004c24:	1ff7f793          	andi	a5,a5,511
    80004c28:	97a6                	add	a5,a5,s1
    80004c2a:	0187c783          	lbu	a5,24(a5)
    80004c2e:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c32:	4685                	li	a3,1
    80004c34:	fbf40613          	addi	a2,s0,-65
    80004c38:	85ca                	mv	a1,s2
    80004c3a:	050a3503          	ld	a0,80(s4)
    80004c3e:	ffffd097          	auipc	ra,0xffffd
    80004c42:	b40080e7          	jalr	-1216(ra) # 8000177e <copyout>
    80004c46:	01650663          	beq	a0,s6,80004c52 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c4a:	2985                	addiw	s3,s3,1
    80004c4c:	0905                	addi	s2,s2,1
    80004c4e:	fd3a91e3          	bne	s5,s3,80004c10 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c52:	21c48513          	addi	a0,s1,540
    80004c56:	ffffd097          	auipc	ra,0xffffd
    80004c5a:	7fe080e7          	jalr	2046(ra) # 80002454 <wakeup>
  release(&pi->lock);
    80004c5e:	8526                	mv	a0,s1
    80004c60:	ffffc097          	auipc	ra,0xffffc
    80004c64:	064080e7          	jalr	100(ra) # 80000cc4 <release>
  return i;
}
    80004c68:	854e                	mv	a0,s3
    80004c6a:	60a6                	ld	ra,72(sp)
    80004c6c:	6406                	ld	s0,64(sp)
    80004c6e:	74e2                	ld	s1,56(sp)
    80004c70:	7942                	ld	s2,48(sp)
    80004c72:	79a2                	ld	s3,40(sp)
    80004c74:	7a02                	ld	s4,32(sp)
    80004c76:	6ae2                	ld	s5,24(sp)
    80004c78:	6b42                	ld	s6,16(sp)
    80004c7a:	6161                	addi	sp,sp,80
    80004c7c:	8082                	ret
      release(&pi->lock);
    80004c7e:	8526                	mv	a0,s1
    80004c80:	ffffc097          	auipc	ra,0xffffc
    80004c84:	044080e7          	jalr	68(ra) # 80000cc4 <release>
      return -1;
    80004c88:	59fd                	li	s3,-1
    80004c8a:	bff9                	j	80004c68 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c8c:	4981                	li	s3,0
    80004c8e:	b7d1                	j	80004c52 <piperead+0xae>

0000000080004c90 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004c90:	df010113          	addi	sp,sp,-528
    80004c94:	20113423          	sd	ra,520(sp)
    80004c98:	20813023          	sd	s0,512(sp)
    80004c9c:	ffa6                	sd	s1,504(sp)
    80004c9e:	fbca                	sd	s2,496(sp)
    80004ca0:	f7ce                	sd	s3,488(sp)
    80004ca2:	f3d2                	sd	s4,480(sp)
    80004ca4:	efd6                	sd	s5,472(sp)
    80004ca6:	ebda                	sd	s6,464(sp)
    80004ca8:	e7de                	sd	s7,456(sp)
    80004caa:	e3e2                	sd	s8,448(sp)
    80004cac:	ff66                	sd	s9,440(sp)
    80004cae:	fb6a                	sd	s10,432(sp)
    80004cb0:	f76e                	sd	s11,424(sp)
    80004cb2:	0c00                	addi	s0,sp,528
    80004cb4:	84aa                	mv	s1,a0
    80004cb6:	dea43c23          	sd	a0,-520(s0)
    80004cba:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004cbe:	ffffd097          	auipc	ra,0xffffd
    80004cc2:	e00080e7          	jalr	-512(ra) # 80001abe <myproc>
    80004cc6:	892a                	mv	s2,a0

  begin_op();
    80004cc8:	fffff097          	auipc	ra,0xfffff
    80004ccc:	446080e7          	jalr	1094(ra) # 8000410e <begin_op>

  if((ip = namei(path)) == 0){
    80004cd0:	8526                	mv	a0,s1
    80004cd2:	fffff097          	auipc	ra,0xfffff
    80004cd6:	230080e7          	jalr	560(ra) # 80003f02 <namei>
    80004cda:	c92d                	beqz	a0,80004d4c <exec+0xbc>
    80004cdc:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004cde:	fffff097          	auipc	ra,0xfffff
    80004ce2:	a70080e7          	jalr	-1424(ra) # 8000374e <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004ce6:	04000713          	li	a4,64
    80004cea:	4681                	li	a3,0
    80004cec:	e4840613          	addi	a2,s0,-440
    80004cf0:	4581                	li	a1,0
    80004cf2:	8526                	mv	a0,s1
    80004cf4:	fffff097          	auipc	ra,0xfffff
    80004cf8:	d0e080e7          	jalr	-754(ra) # 80003a02 <readi>
    80004cfc:	04000793          	li	a5,64
    80004d00:	00f51a63          	bne	a0,a5,80004d14 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004d04:	e4842703          	lw	a4,-440(s0)
    80004d08:	464c47b7          	lui	a5,0x464c4
    80004d0c:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d10:	04f70463          	beq	a4,a5,80004d58 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d14:	8526                	mv	a0,s1
    80004d16:	fffff097          	auipc	ra,0xfffff
    80004d1a:	c9a080e7          	jalr	-870(ra) # 800039b0 <iunlockput>
    end_op();
    80004d1e:	fffff097          	auipc	ra,0xfffff
    80004d22:	470080e7          	jalr	1136(ra) # 8000418e <end_op>
  }
  return -1;
    80004d26:	557d                	li	a0,-1
}
    80004d28:	20813083          	ld	ra,520(sp)
    80004d2c:	20013403          	ld	s0,512(sp)
    80004d30:	74fe                	ld	s1,504(sp)
    80004d32:	795e                	ld	s2,496(sp)
    80004d34:	79be                	ld	s3,488(sp)
    80004d36:	7a1e                	ld	s4,480(sp)
    80004d38:	6afe                	ld	s5,472(sp)
    80004d3a:	6b5e                	ld	s6,464(sp)
    80004d3c:	6bbe                	ld	s7,456(sp)
    80004d3e:	6c1e                	ld	s8,448(sp)
    80004d40:	7cfa                	ld	s9,440(sp)
    80004d42:	7d5a                	ld	s10,432(sp)
    80004d44:	7dba                	ld	s11,424(sp)
    80004d46:	21010113          	addi	sp,sp,528
    80004d4a:	8082                	ret
    end_op();
    80004d4c:	fffff097          	auipc	ra,0xfffff
    80004d50:	442080e7          	jalr	1090(ra) # 8000418e <end_op>
    return -1;
    80004d54:	557d                	li	a0,-1
    80004d56:	bfc9                	j	80004d28 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d58:	854a                	mv	a0,s2
    80004d5a:	ffffd097          	auipc	ra,0xffffd
    80004d5e:	e28080e7          	jalr	-472(ra) # 80001b82 <proc_pagetable>
    80004d62:	8baa                	mv	s7,a0
    80004d64:	d945                	beqz	a0,80004d14 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d66:	e6842983          	lw	s3,-408(s0)
    80004d6a:	e8045783          	lhu	a5,-384(s0)
    80004d6e:	c7ad                	beqz	a5,80004dd8 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004d70:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d72:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004d74:	6c85                	lui	s9,0x1
    80004d76:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004d7a:	def43823          	sd	a5,-528(s0)
    80004d7e:	a42d                	j	80004fa8 <exec+0x318>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004d80:	00004517          	auipc	a0,0x4
    80004d84:	91050513          	addi	a0,a0,-1776 # 80008690 <syscalls+0x290>
    80004d88:	ffffb097          	auipc	ra,0xffffb
    80004d8c:	7c0080e7          	jalr	1984(ra) # 80000548 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004d90:	8756                	mv	a4,s5
    80004d92:	012d86bb          	addw	a3,s11,s2
    80004d96:	4581                	li	a1,0
    80004d98:	8526                	mv	a0,s1
    80004d9a:	fffff097          	auipc	ra,0xfffff
    80004d9e:	c68080e7          	jalr	-920(ra) # 80003a02 <readi>
    80004da2:	2501                	sext.w	a0,a0
    80004da4:	1aaa9963          	bne	s5,a0,80004f56 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004da8:	6785                	lui	a5,0x1
    80004daa:	0127893b          	addw	s2,a5,s2
    80004dae:	77fd                	lui	a5,0xfffff
    80004db0:	01478a3b          	addw	s4,a5,s4
    80004db4:	1f897163          	bgeu	s2,s8,80004f96 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004db8:	02091593          	slli	a1,s2,0x20
    80004dbc:	9181                	srli	a1,a1,0x20
    80004dbe:	95ea                	add	a1,a1,s10
    80004dc0:	855e                	mv	a0,s7
    80004dc2:	ffffc097          	auipc	ra,0xffffc
    80004dc6:	2dc080e7          	jalr	732(ra) # 8000109e <walkaddr>
    80004dca:	862a                	mv	a2,a0
    if(pa == 0)
    80004dcc:	d955                	beqz	a0,80004d80 <exec+0xf0>
      n = PGSIZE;
    80004dce:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004dd0:	fd9a70e3          	bgeu	s4,s9,80004d90 <exec+0x100>
      n = sz - i;
    80004dd4:	8ad2                	mv	s5,s4
    80004dd6:	bf6d                	j	80004d90 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004dd8:	4901                	li	s2,0
  iunlockput(ip);
    80004dda:	8526                	mv	a0,s1
    80004ddc:	fffff097          	auipc	ra,0xfffff
    80004de0:	bd4080e7          	jalr	-1068(ra) # 800039b0 <iunlockput>
  end_op();
    80004de4:	fffff097          	auipc	ra,0xfffff
    80004de8:	3aa080e7          	jalr	938(ra) # 8000418e <end_op>
  p = myproc();
    80004dec:	ffffd097          	auipc	ra,0xffffd
    80004df0:	cd2080e7          	jalr	-814(ra) # 80001abe <myproc>
    80004df4:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004df6:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004dfa:	6785                	lui	a5,0x1
    80004dfc:	17fd                	addi	a5,a5,-1
    80004dfe:	993e                	add	s2,s2,a5
    80004e00:	757d                	lui	a0,0xfffff
    80004e02:	00a977b3          	and	a5,s2,a0
    80004e06:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e0a:	6609                	lui	a2,0x2
    80004e0c:	963e                	add	a2,a2,a5
    80004e0e:	85be                	mv	a1,a5
    80004e10:	855e                	mv	a0,s7
    80004e12:	ffffc097          	auipc	ra,0xffffc
    80004e16:	738080e7          	jalr	1848(ra) # 8000154a <uvmalloc>
    80004e1a:	8b2a                	mv	s6,a0
  ip = 0;
    80004e1c:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e1e:	12050c63          	beqz	a0,80004f56 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e22:	75f9                	lui	a1,0xffffe
    80004e24:	95aa                	add	a1,a1,a0
    80004e26:	855e                	mv	a0,s7
    80004e28:	ffffd097          	auipc	ra,0xffffd
    80004e2c:	924080e7          	jalr	-1756(ra) # 8000174c <uvmclear>
  stackbase = sp - PGSIZE;
    80004e30:	7c7d                	lui	s8,0xfffff
    80004e32:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004e34:	e0043783          	ld	a5,-512(s0)
    80004e38:	6388                	ld	a0,0(a5)
    80004e3a:	c535                	beqz	a0,80004ea6 <exec+0x216>
    80004e3c:	e8840993          	addi	s3,s0,-376
    80004e40:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004e44:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004e46:	ffffc097          	auipc	ra,0xffffc
    80004e4a:	04e080e7          	jalr	78(ra) # 80000e94 <strlen>
    80004e4e:	2505                	addiw	a0,a0,1
    80004e50:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e54:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004e58:	13896363          	bltu	s2,s8,80004f7e <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e5c:	e0043d83          	ld	s11,-512(s0)
    80004e60:	000dba03          	ld	s4,0(s11)
    80004e64:	8552                	mv	a0,s4
    80004e66:	ffffc097          	auipc	ra,0xffffc
    80004e6a:	02e080e7          	jalr	46(ra) # 80000e94 <strlen>
    80004e6e:	0015069b          	addiw	a3,a0,1
    80004e72:	8652                	mv	a2,s4
    80004e74:	85ca                	mv	a1,s2
    80004e76:	855e                	mv	a0,s7
    80004e78:	ffffd097          	auipc	ra,0xffffd
    80004e7c:	906080e7          	jalr	-1786(ra) # 8000177e <copyout>
    80004e80:	10054363          	bltz	a0,80004f86 <exec+0x2f6>
    ustack[argc] = sp;
    80004e84:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004e88:	0485                	addi	s1,s1,1
    80004e8a:	008d8793          	addi	a5,s11,8
    80004e8e:	e0f43023          	sd	a5,-512(s0)
    80004e92:	008db503          	ld	a0,8(s11)
    80004e96:	c911                	beqz	a0,80004eaa <exec+0x21a>
    if(argc >= MAXARG)
    80004e98:	09a1                	addi	s3,s3,8
    80004e9a:	fb3c96e3          	bne	s9,s3,80004e46 <exec+0x1b6>
  sz = sz1;
    80004e9e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ea2:	4481                	li	s1,0
    80004ea4:	a84d                	j	80004f56 <exec+0x2c6>
  sp = sz;
    80004ea6:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004ea8:	4481                	li	s1,0
  ustack[argc] = 0;
    80004eaa:	00349793          	slli	a5,s1,0x3
    80004eae:	f9040713          	addi	a4,s0,-112
    80004eb2:	97ba                	add	a5,a5,a4
    80004eb4:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    80004eb8:	00148693          	addi	a3,s1,1
    80004ebc:	068e                	slli	a3,a3,0x3
    80004ebe:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004ec2:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004ec6:	01897663          	bgeu	s2,s8,80004ed2 <exec+0x242>
  sz = sz1;
    80004eca:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ece:	4481                	li	s1,0
    80004ed0:	a059                	j	80004f56 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004ed2:	e8840613          	addi	a2,s0,-376
    80004ed6:	85ca                	mv	a1,s2
    80004ed8:	855e                	mv	a0,s7
    80004eda:	ffffd097          	auipc	ra,0xffffd
    80004ede:	8a4080e7          	jalr	-1884(ra) # 8000177e <copyout>
    80004ee2:	0a054663          	bltz	a0,80004f8e <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004ee6:	058ab783          	ld	a5,88(s5)
    80004eea:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004eee:	df843783          	ld	a5,-520(s0)
    80004ef2:	0007c703          	lbu	a4,0(a5)
    80004ef6:	cf11                	beqz	a4,80004f12 <exec+0x282>
    80004ef8:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004efa:	02f00693          	li	a3,47
    80004efe:	a029                	j	80004f08 <exec+0x278>
  for(last=s=path; *s; s++)
    80004f00:	0785                	addi	a5,a5,1
    80004f02:	fff7c703          	lbu	a4,-1(a5)
    80004f06:	c711                	beqz	a4,80004f12 <exec+0x282>
    if(*s == '/')
    80004f08:	fed71ce3          	bne	a4,a3,80004f00 <exec+0x270>
      last = s+1;
    80004f0c:	def43c23          	sd	a5,-520(s0)
    80004f10:	bfc5                	j	80004f00 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f12:	4641                	li	a2,16
    80004f14:	df843583          	ld	a1,-520(s0)
    80004f18:	158a8513          	addi	a0,s5,344
    80004f1c:	ffffc097          	auipc	ra,0xffffc
    80004f20:	f46080e7          	jalr	-186(ra) # 80000e62 <safestrcpy>
  oldpagetable = p->pagetable;
    80004f24:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004f28:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004f2c:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f30:	058ab783          	ld	a5,88(s5)
    80004f34:	e6043703          	ld	a4,-416(s0)
    80004f38:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f3a:	058ab783          	ld	a5,88(s5)
    80004f3e:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f42:	85ea                	mv	a1,s10
    80004f44:	ffffd097          	auipc	ra,0xffffd
    80004f48:	cda080e7          	jalr	-806(ra) # 80001c1e <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f4c:	0004851b          	sext.w	a0,s1
    80004f50:	bbe1                	j	80004d28 <exec+0x98>
    80004f52:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004f56:	e0843583          	ld	a1,-504(s0)
    80004f5a:	855e                	mv	a0,s7
    80004f5c:	ffffd097          	auipc	ra,0xffffd
    80004f60:	cc2080e7          	jalr	-830(ra) # 80001c1e <proc_freepagetable>
  if(ip){
    80004f64:	da0498e3          	bnez	s1,80004d14 <exec+0x84>
  return -1;
    80004f68:	557d                	li	a0,-1
    80004f6a:	bb7d                	j	80004d28 <exec+0x98>
    80004f6c:	e1243423          	sd	s2,-504(s0)
    80004f70:	b7dd                	j	80004f56 <exec+0x2c6>
    80004f72:	e1243423          	sd	s2,-504(s0)
    80004f76:	b7c5                	j	80004f56 <exec+0x2c6>
    80004f78:	e1243423          	sd	s2,-504(s0)
    80004f7c:	bfe9                	j	80004f56 <exec+0x2c6>
  sz = sz1;
    80004f7e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f82:	4481                	li	s1,0
    80004f84:	bfc9                	j	80004f56 <exec+0x2c6>
  sz = sz1;
    80004f86:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f8a:	4481                	li	s1,0
    80004f8c:	b7e9                	j	80004f56 <exec+0x2c6>
  sz = sz1;
    80004f8e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f92:	4481                	li	s1,0
    80004f94:	b7c9                	j	80004f56 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f96:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f9a:	2b05                	addiw	s6,s6,1
    80004f9c:	0389899b          	addiw	s3,s3,56
    80004fa0:	e8045783          	lhu	a5,-384(s0)
    80004fa4:	e2fb5be3          	bge	s6,a5,80004dda <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004fa8:	2981                	sext.w	s3,s3
    80004faa:	03800713          	li	a4,56
    80004fae:	86ce                	mv	a3,s3
    80004fb0:	e1040613          	addi	a2,s0,-496
    80004fb4:	4581                	li	a1,0
    80004fb6:	8526                	mv	a0,s1
    80004fb8:	fffff097          	auipc	ra,0xfffff
    80004fbc:	a4a080e7          	jalr	-1462(ra) # 80003a02 <readi>
    80004fc0:	03800793          	li	a5,56
    80004fc4:	f8f517e3          	bne	a0,a5,80004f52 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80004fc8:	e1042783          	lw	a5,-496(s0)
    80004fcc:	4705                	li	a4,1
    80004fce:	fce796e3          	bne	a5,a4,80004f9a <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80004fd2:	e3843603          	ld	a2,-456(s0)
    80004fd6:	e3043783          	ld	a5,-464(s0)
    80004fda:	f8f669e3          	bltu	a2,a5,80004f6c <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004fde:	e2043783          	ld	a5,-480(s0)
    80004fe2:	963e                	add	a2,a2,a5
    80004fe4:	f8f667e3          	bltu	a2,a5,80004f72 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004fe8:	85ca                	mv	a1,s2
    80004fea:	855e                	mv	a0,s7
    80004fec:	ffffc097          	auipc	ra,0xffffc
    80004ff0:	55e080e7          	jalr	1374(ra) # 8000154a <uvmalloc>
    80004ff4:	e0a43423          	sd	a0,-504(s0)
    80004ff8:	d141                	beqz	a0,80004f78 <exec+0x2e8>
    if(ph.vaddr % PGSIZE != 0)
    80004ffa:	e2043d03          	ld	s10,-480(s0)
    80004ffe:	df043783          	ld	a5,-528(s0)
    80005002:	00fd77b3          	and	a5,s10,a5
    80005006:	fba1                	bnez	a5,80004f56 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005008:	e1842d83          	lw	s11,-488(s0)
    8000500c:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005010:	f80c03e3          	beqz	s8,80004f96 <exec+0x306>
    80005014:	8a62                	mv	s4,s8
    80005016:	4901                	li	s2,0
    80005018:	b345                	j	80004db8 <exec+0x128>

000000008000501a <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000501a:	7179                	addi	sp,sp,-48
    8000501c:	f406                	sd	ra,40(sp)
    8000501e:	f022                	sd	s0,32(sp)
    80005020:	ec26                	sd	s1,24(sp)
    80005022:	e84a                	sd	s2,16(sp)
    80005024:	1800                	addi	s0,sp,48
    80005026:	892e                	mv	s2,a1
    80005028:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000502a:	fdc40593          	addi	a1,s0,-36
    8000502e:	ffffe097          	auipc	ra,0xffffe
    80005032:	b82080e7          	jalr	-1150(ra) # 80002bb0 <argint>
    80005036:	04054063          	bltz	a0,80005076 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000503a:	fdc42703          	lw	a4,-36(s0)
    8000503e:	47bd                	li	a5,15
    80005040:	02e7ed63          	bltu	a5,a4,8000507a <argfd+0x60>
    80005044:	ffffd097          	auipc	ra,0xffffd
    80005048:	a7a080e7          	jalr	-1414(ra) # 80001abe <myproc>
    8000504c:	fdc42703          	lw	a4,-36(s0)
    80005050:	01a70793          	addi	a5,a4,26
    80005054:	078e                	slli	a5,a5,0x3
    80005056:	953e                	add	a0,a0,a5
    80005058:	611c                	ld	a5,0(a0)
    8000505a:	c395                	beqz	a5,8000507e <argfd+0x64>
    return -1;
  if(pfd)
    8000505c:	00090463          	beqz	s2,80005064 <argfd+0x4a>
    *pfd = fd;
    80005060:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005064:	4501                	li	a0,0
  if(pf)
    80005066:	c091                	beqz	s1,8000506a <argfd+0x50>
    *pf = f;
    80005068:	e09c                	sd	a5,0(s1)
}
    8000506a:	70a2                	ld	ra,40(sp)
    8000506c:	7402                	ld	s0,32(sp)
    8000506e:	64e2                	ld	s1,24(sp)
    80005070:	6942                	ld	s2,16(sp)
    80005072:	6145                	addi	sp,sp,48
    80005074:	8082                	ret
    return -1;
    80005076:	557d                	li	a0,-1
    80005078:	bfcd                	j	8000506a <argfd+0x50>
    return -1;
    8000507a:	557d                	li	a0,-1
    8000507c:	b7fd                	j	8000506a <argfd+0x50>
    8000507e:	557d                	li	a0,-1
    80005080:	b7ed                	j	8000506a <argfd+0x50>

0000000080005082 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005082:	1101                	addi	sp,sp,-32
    80005084:	ec06                	sd	ra,24(sp)
    80005086:	e822                	sd	s0,16(sp)
    80005088:	e426                	sd	s1,8(sp)
    8000508a:	1000                	addi	s0,sp,32
    8000508c:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000508e:	ffffd097          	auipc	ra,0xffffd
    80005092:	a30080e7          	jalr	-1488(ra) # 80001abe <myproc>
    80005096:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005098:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    8000509c:	4501                	li	a0,0
    8000509e:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800050a0:	6398                	ld	a4,0(a5)
    800050a2:	cb19                	beqz	a4,800050b8 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800050a4:	2505                	addiw	a0,a0,1
    800050a6:	07a1                	addi	a5,a5,8
    800050a8:	fed51ce3          	bne	a0,a3,800050a0 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800050ac:	557d                	li	a0,-1
}
    800050ae:	60e2                	ld	ra,24(sp)
    800050b0:	6442                	ld	s0,16(sp)
    800050b2:	64a2                	ld	s1,8(sp)
    800050b4:	6105                	addi	sp,sp,32
    800050b6:	8082                	ret
      p->ofile[fd] = f;
    800050b8:	01a50793          	addi	a5,a0,26
    800050bc:	078e                	slli	a5,a5,0x3
    800050be:	963e                	add	a2,a2,a5
    800050c0:	e204                	sd	s1,0(a2)
      return fd;
    800050c2:	b7f5                	j	800050ae <fdalloc+0x2c>

00000000800050c4 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800050c4:	715d                	addi	sp,sp,-80
    800050c6:	e486                	sd	ra,72(sp)
    800050c8:	e0a2                	sd	s0,64(sp)
    800050ca:	fc26                	sd	s1,56(sp)
    800050cc:	f84a                	sd	s2,48(sp)
    800050ce:	f44e                	sd	s3,40(sp)
    800050d0:	f052                	sd	s4,32(sp)
    800050d2:	ec56                	sd	s5,24(sp)
    800050d4:	0880                	addi	s0,sp,80
    800050d6:	89ae                	mv	s3,a1
    800050d8:	8ab2                	mv	s5,a2
    800050da:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800050dc:	fb040593          	addi	a1,s0,-80
    800050e0:	fffff097          	auipc	ra,0xfffff
    800050e4:	e40080e7          	jalr	-448(ra) # 80003f20 <nameiparent>
    800050e8:	892a                	mv	s2,a0
    800050ea:	12050f63          	beqz	a0,80005228 <create+0x164>
    return 0;

  ilock(dp);
    800050ee:	ffffe097          	auipc	ra,0xffffe
    800050f2:	660080e7          	jalr	1632(ra) # 8000374e <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800050f6:	4601                	li	a2,0
    800050f8:	fb040593          	addi	a1,s0,-80
    800050fc:	854a                	mv	a0,s2
    800050fe:	fffff097          	auipc	ra,0xfffff
    80005102:	b32080e7          	jalr	-1230(ra) # 80003c30 <dirlookup>
    80005106:	84aa                	mv	s1,a0
    80005108:	c921                	beqz	a0,80005158 <create+0x94>
    iunlockput(dp);
    8000510a:	854a                	mv	a0,s2
    8000510c:	fffff097          	auipc	ra,0xfffff
    80005110:	8a4080e7          	jalr	-1884(ra) # 800039b0 <iunlockput>
    ilock(ip);
    80005114:	8526                	mv	a0,s1
    80005116:	ffffe097          	auipc	ra,0xffffe
    8000511a:	638080e7          	jalr	1592(ra) # 8000374e <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000511e:	2981                	sext.w	s3,s3
    80005120:	4789                	li	a5,2
    80005122:	02f99463          	bne	s3,a5,8000514a <create+0x86>
    80005126:	0444d783          	lhu	a5,68(s1)
    8000512a:	37f9                	addiw	a5,a5,-2
    8000512c:	17c2                	slli	a5,a5,0x30
    8000512e:	93c1                	srli	a5,a5,0x30
    80005130:	4705                	li	a4,1
    80005132:	00f76c63          	bltu	a4,a5,8000514a <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005136:	8526                	mv	a0,s1
    80005138:	60a6                	ld	ra,72(sp)
    8000513a:	6406                	ld	s0,64(sp)
    8000513c:	74e2                	ld	s1,56(sp)
    8000513e:	7942                	ld	s2,48(sp)
    80005140:	79a2                	ld	s3,40(sp)
    80005142:	7a02                	ld	s4,32(sp)
    80005144:	6ae2                	ld	s5,24(sp)
    80005146:	6161                	addi	sp,sp,80
    80005148:	8082                	ret
    iunlockput(ip);
    8000514a:	8526                	mv	a0,s1
    8000514c:	fffff097          	auipc	ra,0xfffff
    80005150:	864080e7          	jalr	-1948(ra) # 800039b0 <iunlockput>
    return 0;
    80005154:	4481                	li	s1,0
    80005156:	b7c5                	j	80005136 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005158:	85ce                	mv	a1,s3
    8000515a:	00092503          	lw	a0,0(s2)
    8000515e:	ffffe097          	auipc	ra,0xffffe
    80005162:	458080e7          	jalr	1112(ra) # 800035b6 <ialloc>
    80005166:	84aa                	mv	s1,a0
    80005168:	c529                	beqz	a0,800051b2 <create+0xee>
  ilock(ip);
    8000516a:	ffffe097          	auipc	ra,0xffffe
    8000516e:	5e4080e7          	jalr	1508(ra) # 8000374e <ilock>
  ip->major = major;
    80005172:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005176:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000517a:	4785                	li	a5,1
    8000517c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005180:	8526                	mv	a0,s1
    80005182:	ffffe097          	auipc	ra,0xffffe
    80005186:	502080e7          	jalr	1282(ra) # 80003684 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000518a:	2981                	sext.w	s3,s3
    8000518c:	4785                	li	a5,1
    8000518e:	02f98a63          	beq	s3,a5,800051c2 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005192:	40d0                	lw	a2,4(s1)
    80005194:	fb040593          	addi	a1,s0,-80
    80005198:	854a                	mv	a0,s2
    8000519a:	fffff097          	auipc	ra,0xfffff
    8000519e:	ca6080e7          	jalr	-858(ra) # 80003e40 <dirlink>
    800051a2:	06054b63          	bltz	a0,80005218 <create+0x154>
  iunlockput(dp);
    800051a6:	854a                	mv	a0,s2
    800051a8:	fffff097          	auipc	ra,0xfffff
    800051ac:	808080e7          	jalr	-2040(ra) # 800039b0 <iunlockput>
  return ip;
    800051b0:	b759                	j	80005136 <create+0x72>
    panic("create: ialloc");
    800051b2:	00003517          	auipc	a0,0x3
    800051b6:	4fe50513          	addi	a0,a0,1278 # 800086b0 <syscalls+0x2b0>
    800051ba:	ffffb097          	auipc	ra,0xffffb
    800051be:	38e080e7          	jalr	910(ra) # 80000548 <panic>
    dp->nlink++;  // for ".."
    800051c2:	04a95783          	lhu	a5,74(s2)
    800051c6:	2785                	addiw	a5,a5,1
    800051c8:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800051cc:	854a                	mv	a0,s2
    800051ce:	ffffe097          	auipc	ra,0xffffe
    800051d2:	4b6080e7          	jalr	1206(ra) # 80003684 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800051d6:	40d0                	lw	a2,4(s1)
    800051d8:	00003597          	auipc	a1,0x3
    800051dc:	4e858593          	addi	a1,a1,1256 # 800086c0 <syscalls+0x2c0>
    800051e0:	8526                	mv	a0,s1
    800051e2:	fffff097          	auipc	ra,0xfffff
    800051e6:	c5e080e7          	jalr	-930(ra) # 80003e40 <dirlink>
    800051ea:	00054f63          	bltz	a0,80005208 <create+0x144>
    800051ee:	00492603          	lw	a2,4(s2)
    800051f2:	00003597          	auipc	a1,0x3
    800051f6:	4d658593          	addi	a1,a1,1238 # 800086c8 <syscalls+0x2c8>
    800051fa:	8526                	mv	a0,s1
    800051fc:	fffff097          	auipc	ra,0xfffff
    80005200:	c44080e7          	jalr	-956(ra) # 80003e40 <dirlink>
    80005204:	f80557e3          	bgez	a0,80005192 <create+0xce>
      panic("create dots");
    80005208:	00003517          	auipc	a0,0x3
    8000520c:	4c850513          	addi	a0,a0,1224 # 800086d0 <syscalls+0x2d0>
    80005210:	ffffb097          	auipc	ra,0xffffb
    80005214:	338080e7          	jalr	824(ra) # 80000548 <panic>
    panic("create: dirlink");
    80005218:	00003517          	auipc	a0,0x3
    8000521c:	4c850513          	addi	a0,a0,1224 # 800086e0 <syscalls+0x2e0>
    80005220:	ffffb097          	auipc	ra,0xffffb
    80005224:	328080e7          	jalr	808(ra) # 80000548 <panic>
    return 0;
    80005228:	84aa                	mv	s1,a0
    8000522a:	b731                	j	80005136 <create+0x72>

000000008000522c <sys_dup>:
{
    8000522c:	7179                	addi	sp,sp,-48
    8000522e:	f406                	sd	ra,40(sp)
    80005230:	f022                	sd	s0,32(sp)
    80005232:	ec26                	sd	s1,24(sp)
    80005234:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005236:	fd840613          	addi	a2,s0,-40
    8000523a:	4581                	li	a1,0
    8000523c:	4501                	li	a0,0
    8000523e:	00000097          	auipc	ra,0x0
    80005242:	ddc080e7          	jalr	-548(ra) # 8000501a <argfd>
    return -1;
    80005246:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005248:	02054363          	bltz	a0,8000526e <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000524c:	fd843503          	ld	a0,-40(s0)
    80005250:	00000097          	auipc	ra,0x0
    80005254:	e32080e7          	jalr	-462(ra) # 80005082 <fdalloc>
    80005258:	84aa                	mv	s1,a0
    return -1;
    8000525a:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000525c:	00054963          	bltz	a0,8000526e <sys_dup+0x42>
  filedup(f);
    80005260:	fd843503          	ld	a0,-40(s0)
    80005264:	fffff097          	auipc	ra,0xfffff
    80005268:	32a080e7          	jalr	810(ra) # 8000458e <filedup>
  return fd;
    8000526c:	87a6                	mv	a5,s1
}
    8000526e:	853e                	mv	a0,a5
    80005270:	70a2                	ld	ra,40(sp)
    80005272:	7402                	ld	s0,32(sp)
    80005274:	64e2                	ld	s1,24(sp)
    80005276:	6145                	addi	sp,sp,48
    80005278:	8082                	ret

000000008000527a <sys_read>:
{
    8000527a:	7179                	addi	sp,sp,-48
    8000527c:	f406                	sd	ra,40(sp)
    8000527e:	f022                	sd	s0,32(sp)
    80005280:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005282:	fe840613          	addi	a2,s0,-24
    80005286:	4581                	li	a1,0
    80005288:	4501                	li	a0,0
    8000528a:	00000097          	auipc	ra,0x0
    8000528e:	d90080e7          	jalr	-624(ra) # 8000501a <argfd>
    return -1;
    80005292:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005294:	04054163          	bltz	a0,800052d6 <sys_read+0x5c>
    80005298:	fe440593          	addi	a1,s0,-28
    8000529c:	4509                	li	a0,2
    8000529e:	ffffe097          	auipc	ra,0xffffe
    800052a2:	912080e7          	jalr	-1774(ra) # 80002bb0 <argint>
    return -1;
    800052a6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052a8:	02054763          	bltz	a0,800052d6 <sys_read+0x5c>
    800052ac:	fd840593          	addi	a1,s0,-40
    800052b0:	4505                	li	a0,1
    800052b2:	ffffe097          	auipc	ra,0xffffe
    800052b6:	920080e7          	jalr	-1760(ra) # 80002bd2 <argaddr>
    return -1;
    800052ba:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052bc:	00054d63          	bltz	a0,800052d6 <sys_read+0x5c>
  return fileread(f, p, n);
    800052c0:	fe442603          	lw	a2,-28(s0)
    800052c4:	fd843583          	ld	a1,-40(s0)
    800052c8:	fe843503          	ld	a0,-24(s0)
    800052cc:	fffff097          	auipc	ra,0xfffff
    800052d0:	44e080e7          	jalr	1102(ra) # 8000471a <fileread>
    800052d4:	87aa                	mv	a5,a0
}
    800052d6:	853e                	mv	a0,a5
    800052d8:	70a2                	ld	ra,40(sp)
    800052da:	7402                	ld	s0,32(sp)
    800052dc:	6145                	addi	sp,sp,48
    800052de:	8082                	ret

00000000800052e0 <sys_write>:
{
    800052e0:	7179                	addi	sp,sp,-48
    800052e2:	f406                	sd	ra,40(sp)
    800052e4:	f022                	sd	s0,32(sp)
    800052e6:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052e8:	fe840613          	addi	a2,s0,-24
    800052ec:	4581                	li	a1,0
    800052ee:	4501                	li	a0,0
    800052f0:	00000097          	auipc	ra,0x0
    800052f4:	d2a080e7          	jalr	-726(ra) # 8000501a <argfd>
    return -1;
    800052f8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052fa:	04054163          	bltz	a0,8000533c <sys_write+0x5c>
    800052fe:	fe440593          	addi	a1,s0,-28
    80005302:	4509                	li	a0,2
    80005304:	ffffe097          	auipc	ra,0xffffe
    80005308:	8ac080e7          	jalr	-1876(ra) # 80002bb0 <argint>
    return -1;
    8000530c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000530e:	02054763          	bltz	a0,8000533c <sys_write+0x5c>
    80005312:	fd840593          	addi	a1,s0,-40
    80005316:	4505                	li	a0,1
    80005318:	ffffe097          	auipc	ra,0xffffe
    8000531c:	8ba080e7          	jalr	-1862(ra) # 80002bd2 <argaddr>
    return -1;
    80005320:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005322:	00054d63          	bltz	a0,8000533c <sys_write+0x5c>
  return filewrite(f, p, n);
    80005326:	fe442603          	lw	a2,-28(s0)
    8000532a:	fd843583          	ld	a1,-40(s0)
    8000532e:	fe843503          	ld	a0,-24(s0)
    80005332:	fffff097          	auipc	ra,0xfffff
    80005336:	4aa080e7          	jalr	1194(ra) # 800047dc <filewrite>
    8000533a:	87aa                	mv	a5,a0
}
    8000533c:	853e                	mv	a0,a5
    8000533e:	70a2                	ld	ra,40(sp)
    80005340:	7402                	ld	s0,32(sp)
    80005342:	6145                	addi	sp,sp,48
    80005344:	8082                	ret

0000000080005346 <sys_close>:
{
    80005346:	1101                	addi	sp,sp,-32
    80005348:	ec06                	sd	ra,24(sp)
    8000534a:	e822                	sd	s0,16(sp)
    8000534c:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000534e:	fe040613          	addi	a2,s0,-32
    80005352:	fec40593          	addi	a1,s0,-20
    80005356:	4501                	li	a0,0
    80005358:	00000097          	auipc	ra,0x0
    8000535c:	cc2080e7          	jalr	-830(ra) # 8000501a <argfd>
    return -1;
    80005360:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005362:	02054463          	bltz	a0,8000538a <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005366:	ffffc097          	auipc	ra,0xffffc
    8000536a:	758080e7          	jalr	1880(ra) # 80001abe <myproc>
    8000536e:	fec42783          	lw	a5,-20(s0)
    80005372:	07e9                	addi	a5,a5,26
    80005374:	078e                	slli	a5,a5,0x3
    80005376:	97aa                	add	a5,a5,a0
    80005378:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000537c:	fe043503          	ld	a0,-32(s0)
    80005380:	fffff097          	auipc	ra,0xfffff
    80005384:	260080e7          	jalr	608(ra) # 800045e0 <fileclose>
  return 0;
    80005388:	4781                	li	a5,0
}
    8000538a:	853e                	mv	a0,a5
    8000538c:	60e2                	ld	ra,24(sp)
    8000538e:	6442                	ld	s0,16(sp)
    80005390:	6105                	addi	sp,sp,32
    80005392:	8082                	ret

0000000080005394 <sys_fstat>:
{
    80005394:	1101                	addi	sp,sp,-32
    80005396:	ec06                	sd	ra,24(sp)
    80005398:	e822                	sd	s0,16(sp)
    8000539a:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000539c:	fe840613          	addi	a2,s0,-24
    800053a0:	4581                	li	a1,0
    800053a2:	4501                	li	a0,0
    800053a4:	00000097          	auipc	ra,0x0
    800053a8:	c76080e7          	jalr	-906(ra) # 8000501a <argfd>
    return -1;
    800053ac:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053ae:	02054563          	bltz	a0,800053d8 <sys_fstat+0x44>
    800053b2:	fe040593          	addi	a1,s0,-32
    800053b6:	4505                	li	a0,1
    800053b8:	ffffe097          	auipc	ra,0xffffe
    800053bc:	81a080e7          	jalr	-2022(ra) # 80002bd2 <argaddr>
    return -1;
    800053c0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053c2:	00054b63          	bltz	a0,800053d8 <sys_fstat+0x44>
  return filestat(f, st);
    800053c6:	fe043583          	ld	a1,-32(s0)
    800053ca:	fe843503          	ld	a0,-24(s0)
    800053ce:	fffff097          	auipc	ra,0xfffff
    800053d2:	2da080e7          	jalr	730(ra) # 800046a8 <filestat>
    800053d6:	87aa                	mv	a5,a0
}
    800053d8:	853e                	mv	a0,a5
    800053da:	60e2                	ld	ra,24(sp)
    800053dc:	6442                	ld	s0,16(sp)
    800053de:	6105                	addi	sp,sp,32
    800053e0:	8082                	ret

00000000800053e2 <sys_link>:
{
    800053e2:	7169                	addi	sp,sp,-304
    800053e4:	f606                	sd	ra,296(sp)
    800053e6:	f222                	sd	s0,288(sp)
    800053e8:	ee26                	sd	s1,280(sp)
    800053ea:	ea4a                	sd	s2,272(sp)
    800053ec:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053ee:	08000613          	li	a2,128
    800053f2:	ed040593          	addi	a1,s0,-304
    800053f6:	4501                	li	a0,0
    800053f8:	ffffd097          	auipc	ra,0xffffd
    800053fc:	7fc080e7          	jalr	2044(ra) # 80002bf4 <argstr>
    return -1;
    80005400:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005402:	10054e63          	bltz	a0,8000551e <sys_link+0x13c>
    80005406:	08000613          	li	a2,128
    8000540a:	f5040593          	addi	a1,s0,-176
    8000540e:	4505                	li	a0,1
    80005410:	ffffd097          	auipc	ra,0xffffd
    80005414:	7e4080e7          	jalr	2020(ra) # 80002bf4 <argstr>
    return -1;
    80005418:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000541a:	10054263          	bltz	a0,8000551e <sys_link+0x13c>
  begin_op();
    8000541e:	fffff097          	auipc	ra,0xfffff
    80005422:	cf0080e7          	jalr	-784(ra) # 8000410e <begin_op>
  if((ip = namei(old)) == 0){
    80005426:	ed040513          	addi	a0,s0,-304
    8000542a:	fffff097          	auipc	ra,0xfffff
    8000542e:	ad8080e7          	jalr	-1320(ra) # 80003f02 <namei>
    80005432:	84aa                	mv	s1,a0
    80005434:	c551                	beqz	a0,800054c0 <sys_link+0xde>
  ilock(ip);
    80005436:	ffffe097          	auipc	ra,0xffffe
    8000543a:	318080e7          	jalr	792(ra) # 8000374e <ilock>
  if(ip->type == T_DIR){
    8000543e:	04449703          	lh	a4,68(s1)
    80005442:	4785                	li	a5,1
    80005444:	08f70463          	beq	a4,a5,800054cc <sys_link+0xea>
  ip->nlink++;
    80005448:	04a4d783          	lhu	a5,74(s1)
    8000544c:	2785                	addiw	a5,a5,1
    8000544e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005452:	8526                	mv	a0,s1
    80005454:	ffffe097          	auipc	ra,0xffffe
    80005458:	230080e7          	jalr	560(ra) # 80003684 <iupdate>
  iunlock(ip);
    8000545c:	8526                	mv	a0,s1
    8000545e:	ffffe097          	auipc	ra,0xffffe
    80005462:	3b2080e7          	jalr	946(ra) # 80003810 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005466:	fd040593          	addi	a1,s0,-48
    8000546a:	f5040513          	addi	a0,s0,-176
    8000546e:	fffff097          	auipc	ra,0xfffff
    80005472:	ab2080e7          	jalr	-1358(ra) # 80003f20 <nameiparent>
    80005476:	892a                	mv	s2,a0
    80005478:	c935                	beqz	a0,800054ec <sys_link+0x10a>
  ilock(dp);
    8000547a:	ffffe097          	auipc	ra,0xffffe
    8000547e:	2d4080e7          	jalr	724(ra) # 8000374e <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005482:	00092703          	lw	a4,0(s2)
    80005486:	409c                	lw	a5,0(s1)
    80005488:	04f71d63          	bne	a4,a5,800054e2 <sys_link+0x100>
    8000548c:	40d0                	lw	a2,4(s1)
    8000548e:	fd040593          	addi	a1,s0,-48
    80005492:	854a                	mv	a0,s2
    80005494:	fffff097          	auipc	ra,0xfffff
    80005498:	9ac080e7          	jalr	-1620(ra) # 80003e40 <dirlink>
    8000549c:	04054363          	bltz	a0,800054e2 <sys_link+0x100>
  iunlockput(dp);
    800054a0:	854a                	mv	a0,s2
    800054a2:	ffffe097          	auipc	ra,0xffffe
    800054a6:	50e080e7          	jalr	1294(ra) # 800039b0 <iunlockput>
  iput(ip);
    800054aa:	8526                	mv	a0,s1
    800054ac:	ffffe097          	auipc	ra,0xffffe
    800054b0:	45c080e7          	jalr	1116(ra) # 80003908 <iput>
  end_op();
    800054b4:	fffff097          	auipc	ra,0xfffff
    800054b8:	cda080e7          	jalr	-806(ra) # 8000418e <end_op>
  return 0;
    800054bc:	4781                	li	a5,0
    800054be:	a085                	j	8000551e <sys_link+0x13c>
    end_op();
    800054c0:	fffff097          	auipc	ra,0xfffff
    800054c4:	cce080e7          	jalr	-818(ra) # 8000418e <end_op>
    return -1;
    800054c8:	57fd                	li	a5,-1
    800054ca:	a891                	j	8000551e <sys_link+0x13c>
    iunlockput(ip);
    800054cc:	8526                	mv	a0,s1
    800054ce:	ffffe097          	auipc	ra,0xffffe
    800054d2:	4e2080e7          	jalr	1250(ra) # 800039b0 <iunlockput>
    end_op();
    800054d6:	fffff097          	auipc	ra,0xfffff
    800054da:	cb8080e7          	jalr	-840(ra) # 8000418e <end_op>
    return -1;
    800054de:	57fd                	li	a5,-1
    800054e0:	a83d                	j	8000551e <sys_link+0x13c>
    iunlockput(dp);
    800054e2:	854a                	mv	a0,s2
    800054e4:	ffffe097          	auipc	ra,0xffffe
    800054e8:	4cc080e7          	jalr	1228(ra) # 800039b0 <iunlockput>
  ilock(ip);
    800054ec:	8526                	mv	a0,s1
    800054ee:	ffffe097          	auipc	ra,0xffffe
    800054f2:	260080e7          	jalr	608(ra) # 8000374e <ilock>
  ip->nlink--;
    800054f6:	04a4d783          	lhu	a5,74(s1)
    800054fa:	37fd                	addiw	a5,a5,-1
    800054fc:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005500:	8526                	mv	a0,s1
    80005502:	ffffe097          	auipc	ra,0xffffe
    80005506:	182080e7          	jalr	386(ra) # 80003684 <iupdate>
  iunlockput(ip);
    8000550a:	8526                	mv	a0,s1
    8000550c:	ffffe097          	auipc	ra,0xffffe
    80005510:	4a4080e7          	jalr	1188(ra) # 800039b0 <iunlockput>
  end_op();
    80005514:	fffff097          	auipc	ra,0xfffff
    80005518:	c7a080e7          	jalr	-902(ra) # 8000418e <end_op>
  return -1;
    8000551c:	57fd                	li	a5,-1
}
    8000551e:	853e                	mv	a0,a5
    80005520:	70b2                	ld	ra,296(sp)
    80005522:	7412                	ld	s0,288(sp)
    80005524:	64f2                	ld	s1,280(sp)
    80005526:	6952                	ld	s2,272(sp)
    80005528:	6155                	addi	sp,sp,304
    8000552a:	8082                	ret

000000008000552c <sys_unlink>:
{
    8000552c:	7151                	addi	sp,sp,-240
    8000552e:	f586                	sd	ra,232(sp)
    80005530:	f1a2                	sd	s0,224(sp)
    80005532:	eda6                	sd	s1,216(sp)
    80005534:	e9ca                	sd	s2,208(sp)
    80005536:	e5ce                	sd	s3,200(sp)
    80005538:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000553a:	08000613          	li	a2,128
    8000553e:	f3040593          	addi	a1,s0,-208
    80005542:	4501                	li	a0,0
    80005544:	ffffd097          	auipc	ra,0xffffd
    80005548:	6b0080e7          	jalr	1712(ra) # 80002bf4 <argstr>
    8000554c:	18054163          	bltz	a0,800056ce <sys_unlink+0x1a2>
  begin_op();
    80005550:	fffff097          	auipc	ra,0xfffff
    80005554:	bbe080e7          	jalr	-1090(ra) # 8000410e <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005558:	fb040593          	addi	a1,s0,-80
    8000555c:	f3040513          	addi	a0,s0,-208
    80005560:	fffff097          	auipc	ra,0xfffff
    80005564:	9c0080e7          	jalr	-1600(ra) # 80003f20 <nameiparent>
    80005568:	84aa                	mv	s1,a0
    8000556a:	c979                	beqz	a0,80005640 <sys_unlink+0x114>
  ilock(dp);
    8000556c:	ffffe097          	auipc	ra,0xffffe
    80005570:	1e2080e7          	jalr	482(ra) # 8000374e <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005574:	00003597          	auipc	a1,0x3
    80005578:	14c58593          	addi	a1,a1,332 # 800086c0 <syscalls+0x2c0>
    8000557c:	fb040513          	addi	a0,s0,-80
    80005580:	ffffe097          	auipc	ra,0xffffe
    80005584:	696080e7          	jalr	1686(ra) # 80003c16 <namecmp>
    80005588:	14050a63          	beqz	a0,800056dc <sys_unlink+0x1b0>
    8000558c:	00003597          	auipc	a1,0x3
    80005590:	13c58593          	addi	a1,a1,316 # 800086c8 <syscalls+0x2c8>
    80005594:	fb040513          	addi	a0,s0,-80
    80005598:	ffffe097          	auipc	ra,0xffffe
    8000559c:	67e080e7          	jalr	1662(ra) # 80003c16 <namecmp>
    800055a0:	12050e63          	beqz	a0,800056dc <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800055a4:	f2c40613          	addi	a2,s0,-212
    800055a8:	fb040593          	addi	a1,s0,-80
    800055ac:	8526                	mv	a0,s1
    800055ae:	ffffe097          	auipc	ra,0xffffe
    800055b2:	682080e7          	jalr	1666(ra) # 80003c30 <dirlookup>
    800055b6:	892a                	mv	s2,a0
    800055b8:	12050263          	beqz	a0,800056dc <sys_unlink+0x1b0>
  ilock(ip);
    800055bc:	ffffe097          	auipc	ra,0xffffe
    800055c0:	192080e7          	jalr	402(ra) # 8000374e <ilock>
  if(ip->nlink < 1)
    800055c4:	04a91783          	lh	a5,74(s2)
    800055c8:	08f05263          	blez	a5,8000564c <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800055cc:	04491703          	lh	a4,68(s2)
    800055d0:	4785                	li	a5,1
    800055d2:	08f70563          	beq	a4,a5,8000565c <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800055d6:	4641                	li	a2,16
    800055d8:	4581                	li	a1,0
    800055da:	fc040513          	addi	a0,s0,-64
    800055de:	ffffb097          	auipc	ra,0xffffb
    800055e2:	72e080e7          	jalr	1838(ra) # 80000d0c <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800055e6:	4741                	li	a4,16
    800055e8:	f2c42683          	lw	a3,-212(s0)
    800055ec:	fc040613          	addi	a2,s0,-64
    800055f0:	4581                	li	a1,0
    800055f2:	8526                	mv	a0,s1
    800055f4:	ffffe097          	auipc	ra,0xffffe
    800055f8:	506080e7          	jalr	1286(ra) # 80003afa <writei>
    800055fc:	47c1                	li	a5,16
    800055fe:	0af51563          	bne	a0,a5,800056a8 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005602:	04491703          	lh	a4,68(s2)
    80005606:	4785                	li	a5,1
    80005608:	0af70863          	beq	a4,a5,800056b8 <sys_unlink+0x18c>
  iunlockput(dp);
    8000560c:	8526                	mv	a0,s1
    8000560e:	ffffe097          	auipc	ra,0xffffe
    80005612:	3a2080e7          	jalr	930(ra) # 800039b0 <iunlockput>
  ip->nlink--;
    80005616:	04a95783          	lhu	a5,74(s2)
    8000561a:	37fd                	addiw	a5,a5,-1
    8000561c:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005620:	854a                	mv	a0,s2
    80005622:	ffffe097          	auipc	ra,0xffffe
    80005626:	062080e7          	jalr	98(ra) # 80003684 <iupdate>
  iunlockput(ip);
    8000562a:	854a                	mv	a0,s2
    8000562c:	ffffe097          	auipc	ra,0xffffe
    80005630:	384080e7          	jalr	900(ra) # 800039b0 <iunlockput>
  end_op();
    80005634:	fffff097          	auipc	ra,0xfffff
    80005638:	b5a080e7          	jalr	-1190(ra) # 8000418e <end_op>
  return 0;
    8000563c:	4501                	li	a0,0
    8000563e:	a84d                	j	800056f0 <sys_unlink+0x1c4>
    end_op();
    80005640:	fffff097          	auipc	ra,0xfffff
    80005644:	b4e080e7          	jalr	-1202(ra) # 8000418e <end_op>
    return -1;
    80005648:	557d                	li	a0,-1
    8000564a:	a05d                	j	800056f0 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000564c:	00003517          	auipc	a0,0x3
    80005650:	0a450513          	addi	a0,a0,164 # 800086f0 <syscalls+0x2f0>
    80005654:	ffffb097          	auipc	ra,0xffffb
    80005658:	ef4080e7          	jalr	-268(ra) # 80000548 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000565c:	04c92703          	lw	a4,76(s2)
    80005660:	02000793          	li	a5,32
    80005664:	f6e7f9e3          	bgeu	a5,a4,800055d6 <sys_unlink+0xaa>
    80005668:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000566c:	4741                	li	a4,16
    8000566e:	86ce                	mv	a3,s3
    80005670:	f1840613          	addi	a2,s0,-232
    80005674:	4581                	li	a1,0
    80005676:	854a                	mv	a0,s2
    80005678:	ffffe097          	auipc	ra,0xffffe
    8000567c:	38a080e7          	jalr	906(ra) # 80003a02 <readi>
    80005680:	47c1                	li	a5,16
    80005682:	00f51b63          	bne	a0,a5,80005698 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005686:	f1845783          	lhu	a5,-232(s0)
    8000568a:	e7a1                	bnez	a5,800056d2 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000568c:	29c1                	addiw	s3,s3,16
    8000568e:	04c92783          	lw	a5,76(s2)
    80005692:	fcf9ede3          	bltu	s3,a5,8000566c <sys_unlink+0x140>
    80005696:	b781                	j	800055d6 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005698:	00003517          	auipc	a0,0x3
    8000569c:	07050513          	addi	a0,a0,112 # 80008708 <syscalls+0x308>
    800056a0:	ffffb097          	auipc	ra,0xffffb
    800056a4:	ea8080e7          	jalr	-344(ra) # 80000548 <panic>
    panic("unlink: writei");
    800056a8:	00003517          	auipc	a0,0x3
    800056ac:	07850513          	addi	a0,a0,120 # 80008720 <syscalls+0x320>
    800056b0:	ffffb097          	auipc	ra,0xffffb
    800056b4:	e98080e7          	jalr	-360(ra) # 80000548 <panic>
    dp->nlink--;
    800056b8:	04a4d783          	lhu	a5,74(s1)
    800056bc:	37fd                	addiw	a5,a5,-1
    800056be:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800056c2:	8526                	mv	a0,s1
    800056c4:	ffffe097          	auipc	ra,0xffffe
    800056c8:	fc0080e7          	jalr	-64(ra) # 80003684 <iupdate>
    800056cc:	b781                	j	8000560c <sys_unlink+0xe0>
    return -1;
    800056ce:	557d                	li	a0,-1
    800056d0:	a005                	j	800056f0 <sys_unlink+0x1c4>
    iunlockput(ip);
    800056d2:	854a                	mv	a0,s2
    800056d4:	ffffe097          	auipc	ra,0xffffe
    800056d8:	2dc080e7          	jalr	732(ra) # 800039b0 <iunlockput>
  iunlockput(dp);
    800056dc:	8526                	mv	a0,s1
    800056de:	ffffe097          	auipc	ra,0xffffe
    800056e2:	2d2080e7          	jalr	722(ra) # 800039b0 <iunlockput>
  end_op();
    800056e6:	fffff097          	auipc	ra,0xfffff
    800056ea:	aa8080e7          	jalr	-1368(ra) # 8000418e <end_op>
  return -1;
    800056ee:	557d                	li	a0,-1
}
    800056f0:	70ae                	ld	ra,232(sp)
    800056f2:	740e                	ld	s0,224(sp)
    800056f4:	64ee                	ld	s1,216(sp)
    800056f6:	694e                	ld	s2,208(sp)
    800056f8:	69ae                	ld	s3,200(sp)
    800056fa:	616d                	addi	sp,sp,240
    800056fc:	8082                	ret

00000000800056fe <sys_open>:

uint64
sys_open(void)
{
    800056fe:	7131                	addi	sp,sp,-192
    80005700:	fd06                	sd	ra,184(sp)
    80005702:	f922                	sd	s0,176(sp)
    80005704:	f526                	sd	s1,168(sp)
    80005706:	f14a                	sd	s2,160(sp)
    80005708:	ed4e                	sd	s3,152(sp)
    8000570a:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000570c:	08000613          	li	a2,128
    80005710:	f5040593          	addi	a1,s0,-176
    80005714:	4501                	li	a0,0
    80005716:	ffffd097          	auipc	ra,0xffffd
    8000571a:	4de080e7          	jalr	1246(ra) # 80002bf4 <argstr>
    return -1;
    8000571e:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005720:	0c054163          	bltz	a0,800057e2 <sys_open+0xe4>
    80005724:	f4c40593          	addi	a1,s0,-180
    80005728:	4505                	li	a0,1
    8000572a:	ffffd097          	auipc	ra,0xffffd
    8000572e:	486080e7          	jalr	1158(ra) # 80002bb0 <argint>
    80005732:	0a054863          	bltz	a0,800057e2 <sys_open+0xe4>

  begin_op();
    80005736:	fffff097          	auipc	ra,0xfffff
    8000573a:	9d8080e7          	jalr	-1576(ra) # 8000410e <begin_op>

  if(omode & O_CREATE){
    8000573e:	f4c42783          	lw	a5,-180(s0)
    80005742:	2007f793          	andi	a5,a5,512
    80005746:	cbdd                	beqz	a5,800057fc <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005748:	4681                	li	a3,0
    8000574a:	4601                	li	a2,0
    8000574c:	4589                	li	a1,2
    8000574e:	f5040513          	addi	a0,s0,-176
    80005752:	00000097          	auipc	ra,0x0
    80005756:	972080e7          	jalr	-1678(ra) # 800050c4 <create>
    8000575a:	892a                	mv	s2,a0
    if(ip == 0){
    8000575c:	c959                	beqz	a0,800057f2 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000575e:	04491703          	lh	a4,68(s2)
    80005762:	478d                	li	a5,3
    80005764:	00f71763          	bne	a4,a5,80005772 <sys_open+0x74>
    80005768:	04695703          	lhu	a4,70(s2)
    8000576c:	47a5                	li	a5,9
    8000576e:	0ce7ec63          	bltu	a5,a4,80005846 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005772:	fffff097          	auipc	ra,0xfffff
    80005776:	db2080e7          	jalr	-590(ra) # 80004524 <filealloc>
    8000577a:	89aa                	mv	s3,a0
    8000577c:	10050263          	beqz	a0,80005880 <sys_open+0x182>
    80005780:	00000097          	auipc	ra,0x0
    80005784:	902080e7          	jalr	-1790(ra) # 80005082 <fdalloc>
    80005788:	84aa                	mv	s1,a0
    8000578a:	0e054663          	bltz	a0,80005876 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000578e:	04491703          	lh	a4,68(s2)
    80005792:	478d                	li	a5,3
    80005794:	0cf70463          	beq	a4,a5,8000585c <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005798:	4789                	li	a5,2
    8000579a:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    8000579e:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800057a2:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800057a6:	f4c42783          	lw	a5,-180(s0)
    800057aa:	0017c713          	xori	a4,a5,1
    800057ae:	8b05                	andi	a4,a4,1
    800057b0:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800057b4:	0037f713          	andi	a4,a5,3
    800057b8:	00e03733          	snez	a4,a4
    800057bc:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800057c0:	4007f793          	andi	a5,a5,1024
    800057c4:	c791                	beqz	a5,800057d0 <sys_open+0xd2>
    800057c6:	04491703          	lh	a4,68(s2)
    800057ca:	4789                	li	a5,2
    800057cc:	08f70f63          	beq	a4,a5,8000586a <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800057d0:	854a                	mv	a0,s2
    800057d2:	ffffe097          	auipc	ra,0xffffe
    800057d6:	03e080e7          	jalr	62(ra) # 80003810 <iunlock>
  end_op();
    800057da:	fffff097          	auipc	ra,0xfffff
    800057de:	9b4080e7          	jalr	-1612(ra) # 8000418e <end_op>

  return fd;
}
    800057e2:	8526                	mv	a0,s1
    800057e4:	70ea                	ld	ra,184(sp)
    800057e6:	744a                	ld	s0,176(sp)
    800057e8:	74aa                	ld	s1,168(sp)
    800057ea:	790a                	ld	s2,160(sp)
    800057ec:	69ea                	ld	s3,152(sp)
    800057ee:	6129                	addi	sp,sp,192
    800057f0:	8082                	ret
      end_op();
    800057f2:	fffff097          	auipc	ra,0xfffff
    800057f6:	99c080e7          	jalr	-1636(ra) # 8000418e <end_op>
      return -1;
    800057fa:	b7e5                	j	800057e2 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800057fc:	f5040513          	addi	a0,s0,-176
    80005800:	ffffe097          	auipc	ra,0xffffe
    80005804:	702080e7          	jalr	1794(ra) # 80003f02 <namei>
    80005808:	892a                	mv	s2,a0
    8000580a:	c905                	beqz	a0,8000583a <sys_open+0x13c>
    ilock(ip);
    8000580c:	ffffe097          	auipc	ra,0xffffe
    80005810:	f42080e7          	jalr	-190(ra) # 8000374e <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005814:	04491703          	lh	a4,68(s2)
    80005818:	4785                	li	a5,1
    8000581a:	f4f712e3          	bne	a4,a5,8000575e <sys_open+0x60>
    8000581e:	f4c42783          	lw	a5,-180(s0)
    80005822:	dba1                	beqz	a5,80005772 <sys_open+0x74>
      iunlockput(ip);
    80005824:	854a                	mv	a0,s2
    80005826:	ffffe097          	auipc	ra,0xffffe
    8000582a:	18a080e7          	jalr	394(ra) # 800039b0 <iunlockput>
      end_op();
    8000582e:	fffff097          	auipc	ra,0xfffff
    80005832:	960080e7          	jalr	-1696(ra) # 8000418e <end_op>
      return -1;
    80005836:	54fd                	li	s1,-1
    80005838:	b76d                	j	800057e2 <sys_open+0xe4>
      end_op();
    8000583a:	fffff097          	auipc	ra,0xfffff
    8000583e:	954080e7          	jalr	-1708(ra) # 8000418e <end_op>
      return -1;
    80005842:	54fd                	li	s1,-1
    80005844:	bf79                	j	800057e2 <sys_open+0xe4>
    iunlockput(ip);
    80005846:	854a                	mv	a0,s2
    80005848:	ffffe097          	auipc	ra,0xffffe
    8000584c:	168080e7          	jalr	360(ra) # 800039b0 <iunlockput>
    end_op();
    80005850:	fffff097          	auipc	ra,0xfffff
    80005854:	93e080e7          	jalr	-1730(ra) # 8000418e <end_op>
    return -1;
    80005858:	54fd                	li	s1,-1
    8000585a:	b761                	j	800057e2 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000585c:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005860:	04691783          	lh	a5,70(s2)
    80005864:	02f99223          	sh	a5,36(s3)
    80005868:	bf2d                	j	800057a2 <sys_open+0xa4>
    itrunc(ip);
    8000586a:	854a                	mv	a0,s2
    8000586c:	ffffe097          	auipc	ra,0xffffe
    80005870:	ff0080e7          	jalr	-16(ra) # 8000385c <itrunc>
    80005874:	bfb1                	j	800057d0 <sys_open+0xd2>
      fileclose(f);
    80005876:	854e                	mv	a0,s3
    80005878:	fffff097          	auipc	ra,0xfffff
    8000587c:	d68080e7          	jalr	-664(ra) # 800045e0 <fileclose>
    iunlockput(ip);
    80005880:	854a                	mv	a0,s2
    80005882:	ffffe097          	auipc	ra,0xffffe
    80005886:	12e080e7          	jalr	302(ra) # 800039b0 <iunlockput>
    end_op();
    8000588a:	fffff097          	auipc	ra,0xfffff
    8000588e:	904080e7          	jalr	-1788(ra) # 8000418e <end_op>
    return -1;
    80005892:	54fd                	li	s1,-1
    80005894:	b7b9                	j	800057e2 <sys_open+0xe4>

0000000080005896 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005896:	7175                	addi	sp,sp,-144
    80005898:	e506                	sd	ra,136(sp)
    8000589a:	e122                	sd	s0,128(sp)
    8000589c:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000589e:	fffff097          	auipc	ra,0xfffff
    800058a2:	870080e7          	jalr	-1936(ra) # 8000410e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800058a6:	08000613          	li	a2,128
    800058aa:	f7040593          	addi	a1,s0,-144
    800058ae:	4501                	li	a0,0
    800058b0:	ffffd097          	auipc	ra,0xffffd
    800058b4:	344080e7          	jalr	836(ra) # 80002bf4 <argstr>
    800058b8:	02054963          	bltz	a0,800058ea <sys_mkdir+0x54>
    800058bc:	4681                	li	a3,0
    800058be:	4601                	li	a2,0
    800058c0:	4585                	li	a1,1
    800058c2:	f7040513          	addi	a0,s0,-144
    800058c6:	fffff097          	auipc	ra,0xfffff
    800058ca:	7fe080e7          	jalr	2046(ra) # 800050c4 <create>
    800058ce:	cd11                	beqz	a0,800058ea <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058d0:	ffffe097          	auipc	ra,0xffffe
    800058d4:	0e0080e7          	jalr	224(ra) # 800039b0 <iunlockput>
  end_op();
    800058d8:	fffff097          	auipc	ra,0xfffff
    800058dc:	8b6080e7          	jalr	-1866(ra) # 8000418e <end_op>
  return 0;
    800058e0:	4501                	li	a0,0
}
    800058e2:	60aa                	ld	ra,136(sp)
    800058e4:	640a                	ld	s0,128(sp)
    800058e6:	6149                	addi	sp,sp,144
    800058e8:	8082                	ret
    end_op();
    800058ea:	fffff097          	auipc	ra,0xfffff
    800058ee:	8a4080e7          	jalr	-1884(ra) # 8000418e <end_op>
    return -1;
    800058f2:	557d                	li	a0,-1
    800058f4:	b7fd                	j	800058e2 <sys_mkdir+0x4c>

00000000800058f6 <sys_mknod>:

uint64
sys_mknod(void)
{
    800058f6:	7135                	addi	sp,sp,-160
    800058f8:	ed06                	sd	ra,152(sp)
    800058fa:	e922                	sd	s0,144(sp)
    800058fc:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800058fe:	fffff097          	auipc	ra,0xfffff
    80005902:	810080e7          	jalr	-2032(ra) # 8000410e <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005906:	08000613          	li	a2,128
    8000590a:	f7040593          	addi	a1,s0,-144
    8000590e:	4501                	li	a0,0
    80005910:	ffffd097          	auipc	ra,0xffffd
    80005914:	2e4080e7          	jalr	740(ra) # 80002bf4 <argstr>
    80005918:	04054a63          	bltz	a0,8000596c <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    8000591c:	f6c40593          	addi	a1,s0,-148
    80005920:	4505                	li	a0,1
    80005922:	ffffd097          	auipc	ra,0xffffd
    80005926:	28e080e7          	jalr	654(ra) # 80002bb0 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000592a:	04054163          	bltz	a0,8000596c <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    8000592e:	f6840593          	addi	a1,s0,-152
    80005932:	4509                	li	a0,2
    80005934:	ffffd097          	auipc	ra,0xffffd
    80005938:	27c080e7          	jalr	636(ra) # 80002bb0 <argint>
     argint(1, &major) < 0 ||
    8000593c:	02054863          	bltz	a0,8000596c <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005940:	f6841683          	lh	a3,-152(s0)
    80005944:	f6c41603          	lh	a2,-148(s0)
    80005948:	458d                	li	a1,3
    8000594a:	f7040513          	addi	a0,s0,-144
    8000594e:	fffff097          	auipc	ra,0xfffff
    80005952:	776080e7          	jalr	1910(ra) # 800050c4 <create>
     argint(2, &minor) < 0 ||
    80005956:	c919                	beqz	a0,8000596c <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005958:	ffffe097          	auipc	ra,0xffffe
    8000595c:	058080e7          	jalr	88(ra) # 800039b0 <iunlockput>
  end_op();
    80005960:	fffff097          	auipc	ra,0xfffff
    80005964:	82e080e7          	jalr	-2002(ra) # 8000418e <end_op>
  return 0;
    80005968:	4501                	li	a0,0
    8000596a:	a031                	j	80005976 <sys_mknod+0x80>
    end_op();
    8000596c:	fffff097          	auipc	ra,0xfffff
    80005970:	822080e7          	jalr	-2014(ra) # 8000418e <end_op>
    return -1;
    80005974:	557d                	li	a0,-1
}
    80005976:	60ea                	ld	ra,152(sp)
    80005978:	644a                	ld	s0,144(sp)
    8000597a:	610d                	addi	sp,sp,160
    8000597c:	8082                	ret

000000008000597e <sys_chdir>:

uint64
sys_chdir(void)
{
    8000597e:	7135                	addi	sp,sp,-160
    80005980:	ed06                	sd	ra,152(sp)
    80005982:	e922                	sd	s0,144(sp)
    80005984:	e526                	sd	s1,136(sp)
    80005986:	e14a                	sd	s2,128(sp)
    80005988:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    8000598a:	ffffc097          	auipc	ra,0xffffc
    8000598e:	134080e7          	jalr	308(ra) # 80001abe <myproc>
    80005992:	892a                	mv	s2,a0
  
  begin_op();
    80005994:	ffffe097          	auipc	ra,0xffffe
    80005998:	77a080e7          	jalr	1914(ra) # 8000410e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    8000599c:	08000613          	li	a2,128
    800059a0:	f6040593          	addi	a1,s0,-160
    800059a4:	4501                	li	a0,0
    800059a6:	ffffd097          	auipc	ra,0xffffd
    800059aa:	24e080e7          	jalr	590(ra) # 80002bf4 <argstr>
    800059ae:	04054b63          	bltz	a0,80005a04 <sys_chdir+0x86>
    800059b2:	f6040513          	addi	a0,s0,-160
    800059b6:	ffffe097          	auipc	ra,0xffffe
    800059ba:	54c080e7          	jalr	1356(ra) # 80003f02 <namei>
    800059be:	84aa                	mv	s1,a0
    800059c0:	c131                	beqz	a0,80005a04 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800059c2:	ffffe097          	auipc	ra,0xffffe
    800059c6:	d8c080e7          	jalr	-628(ra) # 8000374e <ilock>
  if(ip->type != T_DIR){
    800059ca:	04449703          	lh	a4,68(s1)
    800059ce:	4785                	li	a5,1
    800059d0:	04f71063          	bne	a4,a5,80005a10 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800059d4:	8526                	mv	a0,s1
    800059d6:	ffffe097          	auipc	ra,0xffffe
    800059da:	e3a080e7          	jalr	-454(ra) # 80003810 <iunlock>
  iput(p->cwd);
    800059de:	15093503          	ld	a0,336(s2)
    800059e2:	ffffe097          	auipc	ra,0xffffe
    800059e6:	f26080e7          	jalr	-218(ra) # 80003908 <iput>
  end_op();
    800059ea:	ffffe097          	auipc	ra,0xffffe
    800059ee:	7a4080e7          	jalr	1956(ra) # 8000418e <end_op>
  p->cwd = ip;
    800059f2:	14993823          	sd	s1,336(s2)
  return 0;
    800059f6:	4501                	li	a0,0
}
    800059f8:	60ea                	ld	ra,152(sp)
    800059fa:	644a                	ld	s0,144(sp)
    800059fc:	64aa                	ld	s1,136(sp)
    800059fe:	690a                	ld	s2,128(sp)
    80005a00:	610d                	addi	sp,sp,160
    80005a02:	8082                	ret
    end_op();
    80005a04:	ffffe097          	auipc	ra,0xffffe
    80005a08:	78a080e7          	jalr	1930(ra) # 8000418e <end_op>
    return -1;
    80005a0c:	557d                	li	a0,-1
    80005a0e:	b7ed                	j	800059f8 <sys_chdir+0x7a>
    iunlockput(ip);
    80005a10:	8526                	mv	a0,s1
    80005a12:	ffffe097          	auipc	ra,0xffffe
    80005a16:	f9e080e7          	jalr	-98(ra) # 800039b0 <iunlockput>
    end_op();
    80005a1a:	ffffe097          	auipc	ra,0xffffe
    80005a1e:	774080e7          	jalr	1908(ra) # 8000418e <end_op>
    return -1;
    80005a22:	557d                	li	a0,-1
    80005a24:	bfd1                	j	800059f8 <sys_chdir+0x7a>

0000000080005a26 <sys_exec>:

uint64
sys_exec(void)
{
    80005a26:	7145                	addi	sp,sp,-464
    80005a28:	e786                	sd	ra,456(sp)
    80005a2a:	e3a2                	sd	s0,448(sp)
    80005a2c:	ff26                	sd	s1,440(sp)
    80005a2e:	fb4a                	sd	s2,432(sp)
    80005a30:	f74e                	sd	s3,424(sp)
    80005a32:	f352                	sd	s4,416(sp)
    80005a34:	ef56                	sd	s5,408(sp)
    80005a36:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a38:	08000613          	li	a2,128
    80005a3c:	f4040593          	addi	a1,s0,-192
    80005a40:	4501                	li	a0,0
    80005a42:	ffffd097          	auipc	ra,0xffffd
    80005a46:	1b2080e7          	jalr	434(ra) # 80002bf4 <argstr>
    return -1;
    80005a4a:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a4c:	0c054a63          	bltz	a0,80005b20 <sys_exec+0xfa>
    80005a50:	e3840593          	addi	a1,s0,-456
    80005a54:	4505                	li	a0,1
    80005a56:	ffffd097          	auipc	ra,0xffffd
    80005a5a:	17c080e7          	jalr	380(ra) # 80002bd2 <argaddr>
    80005a5e:	0c054163          	bltz	a0,80005b20 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005a62:	10000613          	li	a2,256
    80005a66:	4581                	li	a1,0
    80005a68:	e4040513          	addi	a0,s0,-448
    80005a6c:	ffffb097          	auipc	ra,0xffffb
    80005a70:	2a0080e7          	jalr	672(ra) # 80000d0c <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005a74:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005a78:	89a6                	mv	s3,s1
    80005a7a:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005a7c:	02000a13          	li	s4,32
    80005a80:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005a84:	00391513          	slli	a0,s2,0x3
    80005a88:	e3040593          	addi	a1,s0,-464
    80005a8c:	e3843783          	ld	a5,-456(s0)
    80005a90:	953e                	add	a0,a0,a5
    80005a92:	ffffd097          	auipc	ra,0xffffd
    80005a96:	084080e7          	jalr	132(ra) # 80002b16 <fetchaddr>
    80005a9a:	02054a63          	bltz	a0,80005ace <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005a9e:	e3043783          	ld	a5,-464(s0)
    80005aa2:	c3b9                	beqz	a5,80005ae8 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005aa4:	ffffb097          	auipc	ra,0xffffb
    80005aa8:	07c080e7          	jalr	124(ra) # 80000b20 <kalloc>
    80005aac:	85aa                	mv	a1,a0
    80005aae:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005ab2:	cd11                	beqz	a0,80005ace <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005ab4:	6605                	lui	a2,0x1
    80005ab6:	e3043503          	ld	a0,-464(s0)
    80005aba:	ffffd097          	auipc	ra,0xffffd
    80005abe:	0ae080e7          	jalr	174(ra) # 80002b68 <fetchstr>
    80005ac2:	00054663          	bltz	a0,80005ace <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005ac6:	0905                	addi	s2,s2,1
    80005ac8:	09a1                	addi	s3,s3,8
    80005aca:	fb491be3          	bne	s2,s4,80005a80 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ace:	10048913          	addi	s2,s1,256
    80005ad2:	6088                	ld	a0,0(s1)
    80005ad4:	c529                	beqz	a0,80005b1e <sys_exec+0xf8>
    kfree(argv[i]);
    80005ad6:	ffffb097          	auipc	ra,0xffffb
    80005ada:	f4e080e7          	jalr	-178(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ade:	04a1                	addi	s1,s1,8
    80005ae0:	ff2499e3          	bne	s1,s2,80005ad2 <sys_exec+0xac>
  return -1;
    80005ae4:	597d                	li	s2,-1
    80005ae6:	a82d                	j	80005b20 <sys_exec+0xfa>
      argv[i] = 0;
    80005ae8:	0a8e                	slli	s5,s5,0x3
    80005aea:	fc040793          	addi	a5,s0,-64
    80005aee:	9abe                	add	s5,s5,a5
    80005af0:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005af4:	e4040593          	addi	a1,s0,-448
    80005af8:	f4040513          	addi	a0,s0,-192
    80005afc:	fffff097          	auipc	ra,0xfffff
    80005b00:	194080e7          	jalr	404(ra) # 80004c90 <exec>
    80005b04:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b06:	10048993          	addi	s3,s1,256
    80005b0a:	6088                	ld	a0,0(s1)
    80005b0c:	c911                	beqz	a0,80005b20 <sys_exec+0xfa>
    kfree(argv[i]);
    80005b0e:	ffffb097          	auipc	ra,0xffffb
    80005b12:	f16080e7          	jalr	-234(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b16:	04a1                	addi	s1,s1,8
    80005b18:	ff3499e3          	bne	s1,s3,80005b0a <sys_exec+0xe4>
    80005b1c:	a011                	j	80005b20 <sys_exec+0xfa>
  return -1;
    80005b1e:	597d                	li	s2,-1
}
    80005b20:	854a                	mv	a0,s2
    80005b22:	60be                	ld	ra,456(sp)
    80005b24:	641e                	ld	s0,448(sp)
    80005b26:	74fa                	ld	s1,440(sp)
    80005b28:	795a                	ld	s2,432(sp)
    80005b2a:	79ba                	ld	s3,424(sp)
    80005b2c:	7a1a                	ld	s4,416(sp)
    80005b2e:	6afa                	ld	s5,408(sp)
    80005b30:	6179                	addi	sp,sp,464
    80005b32:	8082                	ret

0000000080005b34 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b34:	7139                	addi	sp,sp,-64
    80005b36:	fc06                	sd	ra,56(sp)
    80005b38:	f822                	sd	s0,48(sp)
    80005b3a:	f426                	sd	s1,40(sp)
    80005b3c:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b3e:	ffffc097          	auipc	ra,0xffffc
    80005b42:	f80080e7          	jalr	-128(ra) # 80001abe <myproc>
    80005b46:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005b48:	fd840593          	addi	a1,s0,-40
    80005b4c:	4501                	li	a0,0
    80005b4e:	ffffd097          	auipc	ra,0xffffd
    80005b52:	084080e7          	jalr	132(ra) # 80002bd2 <argaddr>
    return -1;
    80005b56:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005b58:	0e054063          	bltz	a0,80005c38 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005b5c:	fc840593          	addi	a1,s0,-56
    80005b60:	fd040513          	addi	a0,s0,-48
    80005b64:	fffff097          	auipc	ra,0xfffff
    80005b68:	dd2080e7          	jalr	-558(ra) # 80004936 <pipealloc>
    return -1;
    80005b6c:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005b6e:	0c054563          	bltz	a0,80005c38 <sys_pipe+0x104>
  fd0 = -1;
    80005b72:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005b76:	fd043503          	ld	a0,-48(s0)
    80005b7a:	fffff097          	auipc	ra,0xfffff
    80005b7e:	508080e7          	jalr	1288(ra) # 80005082 <fdalloc>
    80005b82:	fca42223          	sw	a0,-60(s0)
    80005b86:	08054c63          	bltz	a0,80005c1e <sys_pipe+0xea>
    80005b8a:	fc843503          	ld	a0,-56(s0)
    80005b8e:	fffff097          	auipc	ra,0xfffff
    80005b92:	4f4080e7          	jalr	1268(ra) # 80005082 <fdalloc>
    80005b96:	fca42023          	sw	a0,-64(s0)
    80005b9a:	06054863          	bltz	a0,80005c0a <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b9e:	4691                	li	a3,4
    80005ba0:	fc440613          	addi	a2,s0,-60
    80005ba4:	fd843583          	ld	a1,-40(s0)
    80005ba8:	68a8                	ld	a0,80(s1)
    80005baa:	ffffc097          	auipc	ra,0xffffc
    80005bae:	bd4080e7          	jalr	-1068(ra) # 8000177e <copyout>
    80005bb2:	02054063          	bltz	a0,80005bd2 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005bb6:	4691                	li	a3,4
    80005bb8:	fc040613          	addi	a2,s0,-64
    80005bbc:	fd843583          	ld	a1,-40(s0)
    80005bc0:	0591                	addi	a1,a1,4
    80005bc2:	68a8                	ld	a0,80(s1)
    80005bc4:	ffffc097          	auipc	ra,0xffffc
    80005bc8:	bba080e7          	jalr	-1094(ra) # 8000177e <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005bcc:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bce:	06055563          	bgez	a0,80005c38 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005bd2:	fc442783          	lw	a5,-60(s0)
    80005bd6:	07e9                	addi	a5,a5,26
    80005bd8:	078e                	slli	a5,a5,0x3
    80005bda:	97a6                	add	a5,a5,s1
    80005bdc:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005be0:	fc042503          	lw	a0,-64(s0)
    80005be4:	0569                	addi	a0,a0,26
    80005be6:	050e                	slli	a0,a0,0x3
    80005be8:	9526                	add	a0,a0,s1
    80005bea:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005bee:	fd043503          	ld	a0,-48(s0)
    80005bf2:	fffff097          	auipc	ra,0xfffff
    80005bf6:	9ee080e7          	jalr	-1554(ra) # 800045e0 <fileclose>
    fileclose(wf);
    80005bfa:	fc843503          	ld	a0,-56(s0)
    80005bfe:	fffff097          	auipc	ra,0xfffff
    80005c02:	9e2080e7          	jalr	-1566(ra) # 800045e0 <fileclose>
    return -1;
    80005c06:	57fd                	li	a5,-1
    80005c08:	a805                	j	80005c38 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005c0a:	fc442783          	lw	a5,-60(s0)
    80005c0e:	0007c863          	bltz	a5,80005c1e <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005c12:	01a78513          	addi	a0,a5,26
    80005c16:	050e                	slli	a0,a0,0x3
    80005c18:	9526                	add	a0,a0,s1
    80005c1a:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c1e:	fd043503          	ld	a0,-48(s0)
    80005c22:	fffff097          	auipc	ra,0xfffff
    80005c26:	9be080e7          	jalr	-1602(ra) # 800045e0 <fileclose>
    fileclose(wf);
    80005c2a:	fc843503          	ld	a0,-56(s0)
    80005c2e:	fffff097          	auipc	ra,0xfffff
    80005c32:	9b2080e7          	jalr	-1614(ra) # 800045e0 <fileclose>
    return -1;
    80005c36:	57fd                	li	a5,-1
}
    80005c38:	853e                	mv	a0,a5
    80005c3a:	70e2                	ld	ra,56(sp)
    80005c3c:	7442                	ld	s0,48(sp)
    80005c3e:	74a2                	ld	s1,40(sp)
    80005c40:	6121                	addi	sp,sp,64
    80005c42:	8082                	ret
	...

0000000080005c50 <kernelvec>:
    80005c50:	7111                	addi	sp,sp,-256
    80005c52:	e006                	sd	ra,0(sp)
    80005c54:	e40a                	sd	sp,8(sp)
    80005c56:	e80e                	sd	gp,16(sp)
    80005c58:	ec12                	sd	tp,24(sp)
    80005c5a:	f016                	sd	t0,32(sp)
    80005c5c:	f41a                	sd	t1,40(sp)
    80005c5e:	f81e                	sd	t2,48(sp)
    80005c60:	fc22                	sd	s0,56(sp)
    80005c62:	e0a6                	sd	s1,64(sp)
    80005c64:	e4aa                	sd	a0,72(sp)
    80005c66:	e8ae                	sd	a1,80(sp)
    80005c68:	ecb2                	sd	a2,88(sp)
    80005c6a:	f0b6                	sd	a3,96(sp)
    80005c6c:	f4ba                	sd	a4,104(sp)
    80005c6e:	f8be                	sd	a5,112(sp)
    80005c70:	fcc2                	sd	a6,120(sp)
    80005c72:	e146                	sd	a7,128(sp)
    80005c74:	e54a                	sd	s2,136(sp)
    80005c76:	e94e                	sd	s3,144(sp)
    80005c78:	ed52                	sd	s4,152(sp)
    80005c7a:	f156                	sd	s5,160(sp)
    80005c7c:	f55a                	sd	s6,168(sp)
    80005c7e:	f95e                	sd	s7,176(sp)
    80005c80:	fd62                	sd	s8,184(sp)
    80005c82:	e1e6                	sd	s9,192(sp)
    80005c84:	e5ea                	sd	s10,200(sp)
    80005c86:	e9ee                	sd	s11,208(sp)
    80005c88:	edf2                	sd	t3,216(sp)
    80005c8a:	f1f6                	sd	t4,224(sp)
    80005c8c:	f5fa                	sd	t5,232(sp)
    80005c8e:	f9fe                	sd	t6,240(sp)
    80005c90:	d53fc0ef          	jal	ra,800029e2 <kerneltrap>
    80005c94:	6082                	ld	ra,0(sp)
    80005c96:	6122                	ld	sp,8(sp)
    80005c98:	61c2                	ld	gp,16(sp)
    80005c9a:	7282                	ld	t0,32(sp)
    80005c9c:	7322                	ld	t1,40(sp)
    80005c9e:	73c2                	ld	t2,48(sp)
    80005ca0:	7462                	ld	s0,56(sp)
    80005ca2:	6486                	ld	s1,64(sp)
    80005ca4:	6526                	ld	a0,72(sp)
    80005ca6:	65c6                	ld	a1,80(sp)
    80005ca8:	6666                	ld	a2,88(sp)
    80005caa:	7686                	ld	a3,96(sp)
    80005cac:	7726                	ld	a4,104(sp)
    80005cae:	77c6                	ld	a5,112(sp)
    80005cb0:	7866                	ld	a6,120(sp)
    80005cb2:	688a                	ld	a7,128(sp)
    80005cb4:	692a                	ld	s2,136(sp)
    80005cb6:	69ca                	ld	s3,144(sp)
    80005cb8:	6a6a                	ld	s4,152(sp)
    80005cba:	7a8a                	ld	s5,160(sp)
    80005cbc:	7b2a                	ld	s6,168(sp)
    80005cbe:	7bca                	ld	s7,176(sp)
    80005cc0:	7c6a                	ld	s8,184(sp)
    80005cc2:	6c8e                	ld	s9,192(sp)
    80005cc4:	6d2e                	ld	s10,200(sp)
    80005cc6:	6dce                	ld	s11,208(sp)
    80005cc8:	6e6e                	ld	t3,216(sp)
    80005cca:	7e8e                	ld	t4,224(sp)
    80005ccc:	7f2e                	ld	t5,232(sp)
    80005cce:	7fce                	ld	t6,240(sp)
    80005cd0:	6111                	addi	sp,sp,256
    80005cd2:	10200073          	sret
    80005cd6:	00000013          	nop
    80005cda:	00000013          	nop
    80005cde:	0001                	nop

0000000080005ce0 <timervec>:
    80005ce0:	34051573          	csrrw	a0,mscratch,a0
    80005ce4:	e10c                	sd	a1,0(a0)
    80005ce6:	e510                	sd	a2,8(a0)
    80005ce8:	e914                	sd	a3,16(a0)
    80005cea:	710c                	ld	a1,32(a0)
    80005cec:	7510                	ld	a2,40(a0)
    80005cee:	6194                	ld	a3,0(a1)
    80005cf0:	96b2                	add	a3,a3,a2
    80005cf2:	e194                	sd	a3,0(a1)
    80005cf4:	4589                	li	a1,2
    80005cf6:	14459073          	csrw	sip,a1
    80005cfa:	6914                	ld	a3,16(a0)
    80005cfc:	6510                	ld	a2,8(a0)
    80005cfe:	610c                	ld	a1,0(a0)
    80005d00:	34051573          	csrrw	a0,mscratch,a0
    80005d04:	30200073          	mret
	...

0000000080005d0a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005d0a:	1141                	addi	sp,sp,-16
    80005d0c:	e422                	sd	s0,8(sp)
    80005d0e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005d10:	0c0007b7          	lui	a5,0xc000
    80005d14:	4705                	li	a4,1
    80005d16:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005d18:	c3d8                	sw	a4,4(a5)
}
    80005d1a:	6422                	ld	s0,8(sp)
    80005d1c:	0141                	addi	sp,sp,16
    80005d1e:	8082                	ret

0000000080005d20 <plicinithart>:

void
plicinithart(void)
{
    80005d20:	1141                	addi	sp,sp,-16
    80005d22:	e406                	sd	ra,8(sp)
    80005d24:	e022                	sd	s0,0(sp)
    80005d26:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d28:	ffffc097          	auipc	ra,0xffffc
    80005d2c:	d6a080e7          	jalr	-662(ra) # 80001a92 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005d30:	0085171b          	slliw	a4,a0,0x8
    80005d34:	0c0027b7          	lui	a5,0xc002
    80005d38:	97ba                	add	a5,a5,a4
    80005d3a:	40200713          	li	a4,1026
    80005d3e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005d42:	00d5151b          	slliw	a0,a0,0xd
    80005d46:	0c2017b7          	lui	a5,0xc201
    80005d4a:	953e                	add	a0,a0,a5
    80005d4c:	00052023          	sw	zero,0(a0)
}
    80005d50:	60a2                	ld	ra,8(sp)
    80005d52:	6402                	ld	s0,0(sp)
    80005d54:	0141                	addi	sp,sp,16
    80005d56:	8082                	ret

0000000080005d58 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005d58:	1141                	addi	sp,sp,-16
    80005d5a:	e406                	sd	ra,8(sp)
    80005d5c:	e022                	sd	s0,0(sp)
    80005d5e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d60:	ffffc097          	auipc	ra,0xffffc
    80005d64:	d32080e7          	jalr	-718(ra) # 80001a92 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005d68:	00d5179b          	slliw	a5,a0,0xd
    80005d6c:	0c201537          	lui	a0,0xc201
    80005d70:	953e                	add	a0,a0,a5
  return irq;
}
    80005d72:	4148                	lw	a0,4(a0)
    80005d74:	60a2                	ld	ra,8(sp)
    80005d76:	6402                	ld	s0,0(sp)
    80005d78:	0141                	addi	sp,sp,16
    80005d7a:	8082                	ret

0000000080005d7c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005d7c:	1101                	addi	sp,sp,-32
    80005d7e:	ec06                	sd	ra,24(sp)
    80005d80:	e822                	sd	s0,16(sp)
    80005d82:	e426                	sd	s1,8(sp)
    80005d84:	1000                	addi	s0,sp,32
    80005d86:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005d88:	ffffc097          	auipc	ra,0xffffc
    80005d8c:	d0a080e7          	jalr	-758(ra) # 80001a92 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005d90:	00d5151b          	slliw	a0,a0,0xd
    80005d94:	0c2017b7          	lui	a5,0xc201
    80005d98:	97aa                	add	a5,a5,a0
    80005d9a:	c3c4                	sw	s1,4(a5)
}
    80005d9c:	60e2                	ld	ra,24(sp)
    80005d9e:	6442                	ld	s0,16(sp)
    80005da0:	64a2                	ld	s1,8(sp)
    80005da2:	6105                	addi	sp,sp,32
    80005da4:	8082                	ret

0000000080005da6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005da6:	1141                	addi	sp,sp,-16
    80005da8:	e406                	sd	ra,8(sp)
    80005daa:	e022                	sd	s0,0(sp)
    80005dac:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005dae:	479d                	li	a5,7
    80005db0:	04a7cc63          	blt	a5,a0,80005e08 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005db4:	0001d797          	auipc	a5,0x1d
    80005db8:	24c78793          	addi	a5,a5,588 # 80023000 <disk>
    80005dbc:	00a78733          	add	a4,a5,a0
    80005dc0:	6789                	lui	a5,0x2
    80005dc2:	97ba                	add	a5,a5,a4
    80005dc4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005dc8:	eba1                	bnez	a5,80005e18 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005dca:	00451713          	slli	a4,a0,0x4
    80005dce:	0001f797          	auipc	a5,0x1f
    80005dd2:	2327b783          	ld	a5,562(a5) # 80025000 <disk+0x2000>
    80005dd6:	97ba                	add	a5,a5,a4
    80005dd8:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005ddc:	0001d797          	auipc	a5,0x1d
    80005de0:	22478793          	addi	a5,a5,548 # 80023000 <disk>
    80005de4:	97aa                	add	a5,a5,a0
    80005de6:	6509                	lui	a0,0x2
    80005de8:	953e                	add	a0,a0,a5
    80005dea:	4785                	li	a5,1
    80005dec:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005df0:	0001f517          	auipc	a0,0x1f
    80005df4:	22850513          	addi	a0,a0,552 # 80025018 <disk+0x2018>
    80005df8:	ffffc097          	auipc	ra,0xffffc
    80005dfc:	65c080e7          	jalr	1628(ra) # 80002454 <wakeup>
}
    80005e00:	60a2                	ld	ra,8(sp)
    80005e02:	6402                	ld	s0,0(sp)
    80005e04:	0141                	addi	sp,sp,16
    80005e06:	8082                	ret
    panic("virtio_disk_intr 1");
    80005e08:	00003517          	auipc	a0,0x3
    80005e0c:	92850513          	addi	a0,a0,-1752 # 80008730 <syscalls+0x330>
    80005e10:	ffffa097          	auipc	ra,0xffffa
    80005e14:	738080e7          	jalr	1848(ra) # 80000548 <panic>
    panic("virtio_disk_intr 2");
    80005e18:	00003517          	auipc	a0,0x3
    80005e1c:	93050513          	addi	a0,a0,-1744 # 80008748 <syscalls+0x348>
    80005e20:	ffffa097          	auipc	ra,0xffffa
    80005e24:	728080e7          	jalr	1832(ra) # 80000548 <panic>

0000000080005e28 <virtio_disk_init>:
{
    80005e28:	1101                	addi	sp,sp,-32
    80005e2a:	ec06                	sd	ra,24(sp)
    80005e2c:	e822                	sd	s0,16(sp)
    80005e2e:	e426                	sd	s1,8(sp)
    80005e30:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005e32:	00003597          	auipc	a1,0x3
    80005e36:	92e58593          	addi	a1,a1,-1746 # 80008760 <syscalls+0x360>
    80005e3a:	0001f517          	auipc	a0,0x1f
    80005e3e:	26e50513          	addi	a0,a0,622 # 800250a8 <disk+0x20a8>
    80005e42:	ffffb097          	auipc	ra,0xffffb
    80005e46:	d3e080e7          	jalr	-706(ra) # 80000b80 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e4a:	100017b7          	lui	a5,0x10001
    80005e4e:	4398                	lw	a4,0(a5)
    80005e50:	2701                	sext.w	a4,a4
    80005e52:	747277b7          	lui	a5,0x74727
    80005e56:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005e5a:	0ef71163          	bne	a4,a5,80005f3c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e5e:	100017b7          	lui	a5,0x10001
    80005e62:	43dc                	lw	a5,4(a5)
    80005e64:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e66:	4705                	li	a4,1
    80005e68:	0ce79a63          	bne	a5,a4,80005f3c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e6c:	100017b7          	lui	a5,0x10001
    80005e70:	479c                	lw	a5,8(a5)
    80005e72:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e74:	4709                	li	a4,2
    80005e76:	0ce79363          	bne	a5,a4,80005f3c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005e7a:	100017b7          	lui	a5,0x10001
    80005e7e:	47d8                	lw	a4,12(a5)
    80005e80:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e82:	554d47b7          	lui	a5,0x554d4
    80005e86:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005e8a:	0af71963          	bne	a4,a5,80005f3c <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e8e:	100017b7          	lui	a5,0x10001
    80005e92:	4705                	li	a4,1
    80005e94:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e96:	470d                	li	a4,3
    80005e98:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005e9a:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005e9c:	c7ffe737          	lui	a4,0xc7ffe
    80005ea0:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005ea4:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005ea6:	2701                	sext.w	a4,a4
    80005ea8:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005eaa:	472d                	li	a4,11
    80005eac:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005eae:	473d                	li	a4,15
    80005eb0:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005eb2:	6705                	lui	a4,0x1
    80005eb4:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005eb6:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005eba:	5bdc                	lw	a5,52(a5)
    80005ebc:	2781                	sext.w	a5,a5
  if(max == 0)
    80005ebe:	c7d9                	beqz	a5,80005f4c <virtio_disk_init+0x124>
  if(max < NUM)
    80005ec0:	471d                	li	a4,7
    80005ec2:	08f77d63          	bgeu	a4,a5,80005f5c <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005ec6:	100014b7          	lui	s1,0x10001
    80005eca:	47a1                	li	a5,8
    80005ecc:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005ece:	6609                	lui	a2,0x2
    80005ed0:	4581                	li	a1,0
    80005ed2:	0001d517          	auipc	a0,0x1d
    80005ed6:	12e50513          	addi	a0,a0,302 # 80023000 <disk>
    80005eda:	ffffb097          	auipc	ra,0xffffb
    80005ede:	e32080e7          	jalr	-462(ra) # 80000d0c <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005ee2:	0001d717          	auipc	a4,0x1d
    80005ee6:	11e70713          	addi	a4,a4,286 # 80023000 <disk>
    80005eea:	00c75793          	srli	a5,a4,0xc
    80005eee:	2781                	sext.w	a5,a5
    80005ef0:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80005ef2:	0001f797          	auipc	a5,0x1f
    80005ef6:	10e78793          	addi	a5,a5,270 # 80025000 <disk+0x2000>
    80005efa:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    80005efc:	0001d717          	auipc	a4,0x1d
    80005f00:	18470713          	addi	a4,a4,388 # 80023080 <disk+0x80>
    80005f04:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80005f06:	0001e717          	auipc	a4,0x1e
    80005f0a:	0fa70713          	addi	a4,a4,250 # 80024000 <disk+0x1000>
    80005f0e:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005f10:	4705                	li	a4,1
    80005f12:	00e78c23          	sb	a4,24(a5)
    80005f16:	00e78ca3          	sb	a4,25(a5)
    80005f1a:	00e78d23          	sb	a4,26(a5)
    80005f1e:	00e78da3          	sb	a4,27(a5)
    80005f22:	00e78e23          	sb	a4,28(a5)
    80005f26:	00e78ea3          	sb	a4,29(a5)
    80005f2a:	00e78f23          	sb	a4,30(a5)
    80005f2e:	00e78fa3          	sb	a4,31(a5)
}
    80005f32:	60e2                	ld	ra,24(sp)
    80005f34:	6442                	ld	s0,16(sp)
    80005f36:	64a2                	ld	s1,8(sp)
    80005f38:	6105                	addi	sp,sp,32
    80005f3a:	8082                	ret
    panic("could not find virtio disk");
    80005f3c:	00003517          	auipc	a0,0x3
    80005f40:	83450513          	addi	a0,a0,-1996 # 80008770 <syscalls+0x370>
    80005f44:	ffffa097          	auipc	ra,0xffffa
    80005f48:	604080e7          	jalr	1540(ra) # 80000548 <panic>
    panic("virtio disk has no queue 0");
    80005f4c:	00003517          	auipc	a0,0x3
    80005f50:	84450513          	addi	a0,a0,-1980 # 80008790 <syscalls+0x390>
    80005f54:	ffffa097          	auipc	ra,0xffffa
    80005f58:	5f4080e7          	jalr	1524(ra) # 80000548 <panic>
    panic("virtio disk max queue too short");
    80005f5c:	00003517          	auipc	a0,0x3
    80005f60:	85450513          	addi	a0,a0,-1964 # 800087b0 <syscalls+0x3b0>
    80005f64:	ffffa097          	auipc	ra,0xffffa
    80005f68:	5e4080e7          	jalr	1508(ra) # 80000548 <panic>

0000000080005f6c <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005f6c:	7119                	addi	sp,sp,-128
    80005f6e:	fc86                	sd	ra,120(sp)
    80005f70:	f8a2                	sd	s0,112(sp)
    80005f72:	f4a6                	sd	s1,104(sp)
    80005f74:	f0ca                	sd	s2,96(sp)
    80005f76:	ecce                	sd	s3,88(sp)
    80005f78:	e8d2                	sd	s4,80(sp)
    80005f7a:	e4d6                	sd	s5,72(sp)
    80005f7c:	e0da                	sd	s6,64(sp)
    80005f7e:	fc5e                	sd	s7,56(sp)
    80005f80:	f862                	sd	s8,48(sp)
    80005f82:	f466                	sd	s9,40(sp)
    80005f84:	f06a                	sd	s10,32(sp)
    80005f86:	0100                	addi	s0,sp,128
    80005f88:	892a                	mv	s2,a0
    80005f8a:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005f8c:	00c52c83          	lw	s9,12(a0)
    80005f90:	001c9c9b          	slliw	s9,s9,0x1
    80005f94:	1c82                	slli	s9,s9,0x20
    80005f96:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005f9a:	0001f517          	auipc	a0,0x1f
    80005f9e:	10e50513          	addi	a0,a0,270 # 800250a8 <disk+0x20a8>
    80005fa2:	ffffb097          	auipc	ra,0xffffb
    80005fa6:	c6e080e7          	jalr	-914(ra) # 80000c10 <acquire>
  for(int i = 0; i < 3; i++){
    80005faa:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005fac:	4c21                	li	s8,8
      disk.free[i] = 0;
    80005fae:	0001db97          	auipc	s7,0x1d
    80005fb2:	052b8b93          	addi	s7,s7,82 # 80023000 <disk>
    80005fb6:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80005fb8:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80005fba:	8a4e                	mv	s4,s3
    80005fbc:	a051                	j	80006040 <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80005fbe:	00fb86b3          	add	a3,s7,a5
    80005fc2:	96da                	add	a3,a3,s6
    80005fc4:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80005fc8:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80005fca:	0207c563          	bltz	a5,80005ff4 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005fce:	2485                	addiw	s1,s1,1
    80005fd0:	0711                	addi	a4,a4,4
    80005fd2:	23548d63          	beq	s1,s5,8000620c <virtio_disk_rw+0x2a0>
    idx[i] = alloc_desc();
    80005fd6:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80005fd8:	0001f697          	auipc	a3,0x1f
    80005fdc:	04068693          	addi	a3,a3,64 # 80025018 <disk+0x2018>
    80005fe0:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80005fe2:	0006c583          	lbu	a1,0(a3)
    80005fe6:	fde1                	bnez	a1,80005fbe <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005fe8:	2785                	addiw	a5,a5,1
    80005fea:	0685                	addi	a3,a3,1
    80005fec:	ff879be3          	bne	a5,s8,80005fe2 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005ff0:	57fd                	li	a5,-1
    80005ff2:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80005ff4:	02905a63          	blez	s1,80006028 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005ff8:	f9042503          	lw	a0,-112(s0)
    80005ffc:	00000097          	auipc	ra,0x0
    80006000:	daa080e7          	jalr	-598(ra) # 80005da6 <free_desc>
      for(int j = 0; j < i; j++)
    80006004:	4785                	li	a5,1
    80006006:	0297d163          	bge	a5,s1,80006028 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    8000600a:	f9442503          	lw	a0,-108(s0)
    8000600e:	00000097          	auipc	ra,0x0
    80006012:	d98080e7          	jalr	-616(ra) # 80005da6 <free_desc>
      for(int j = 0; j < i; j++)
    80006016:	4789                	li	a5,2
    80006018:	0097d863          	bge	a5,s1,80006028 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    8000601c:	f9842503          	lw	a0,-104(s0)
    80006020:	00000097          	auipc	ra,0x0
    80006024:	d86080e7          	jalr	-634(ra) # 80005da6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006028:	0001f597          	auipc	a1,0x1f
    8000602c:	08058593          	addi	a1,a1,128 # 800250a8 <disk+0x20a8>
    80006030:	0001f517          	auipc	a0,0x1f
    80006034:	fe850513          	addi	a0,a0,-24 # 80025018 <disk+0x2018>
    80006038:	ffffc097          	auipc	ra,0xffffc
    8000603c:	296080e7          	jalr	662(ra) # 800022ce <sleep>
  for(int i = 0; i < 3; i++){
    80006040:	f9040713          	addi	a4,s0,-112
    80006044:	84ce                	mv	s1,s3
    80006046:	bf41                	j	80005fd6 <virtio_disk_rw+0x6a>
    uint32 reserved;
    uint64 sector;
  } buf0;

  if(write)
    buf0.type = VIRTIO_BLK_T_OUT; // write the disk
    80006048:	4785                	li	a5,1
    8000604a:	f8f42023          	sw	a5,-128(s0)
  else
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
  buf0.reserved = 0;
    8000604e:	f8042223          	sw	zero,-124(s0)
  buf0.sector = sector;
    80006052:	f9943423          	sd	s9,-120(s0)

  // buf0 is on a kernel stack, which is not direct mapped,
  // thus the call to kvmpa().
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    80006056:	f9042983          	lw	s3,-112(s0)
    8000605a:	00499493          	slli	s1,s3,0x4
    8000605e:	0001fa17          	auipc	s4,0x1f
    80006062:	fa2a0a13          	addi	s4,s4,-94 # 80025000 <disk+0x2000>
    80006066:	000a3a83          	ld	s5,0(s4)
    8000606a:	9aa6                	add	s5,s5,s1
    8000606c:	f8040513          	addi	a0,s0,-128
    80006070:	ffffb097          	auipc	ra,0xffffb
    80006074:	070080e7          	jalr	112(ra) # 800010e0 <kvmpa>
    80006078:	00aab023          	sd	a0,0(s5)
  disk.desc[idx[0]].len = sizeof(buf0);
    8000607c:	000a3783          	ld	a5,0(s4)
    80006080:	97a6                	add	a5,a5,s1
    80006082:	4741                	li	a4,16
    80006084:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006086:	000a3783          	ld	a5,0(s4)
    8000608a:	97a6                	add	a5,a5,s1
    8000608c:	4705                	li	a4,1
    8000608e:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    80006092:	f9442703          	lw	a4,-108(s0)
    80006096:	000a3783          	ld	a5,0(s4)
    8000609a:	97a6                	add	a5,a5,s1
    8000609c:	00e79723          	sh	a4,14(a5)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800060a0:	0712                	slli	a4,a4,0x4
    800060a2:	000a3783          	ld	a5,0(s4)
    800060a6:	97ba                	add	a5,a5,a4
    800060a8:	05890693          	addi	a3,s2,88
    800060ac:	e394                	sd	a3,0(a5)
  disk.desc[idx[1]].len = BSIZE;
    800060ae:	000a3783          	ld	a5,0(s4)
    800060b2:	97ba                	add	a5,a5,a4
    800060b4:	40000693          	li	a3,1024
    800060b8:	c794                	sw	a3,8(a5)
  if(write)
    800060ba:	100d0a63          	beqz	s10,800061ce <virtio_disk_rw+0x262>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800060be:	0001f797          	auipc	a5,0x1f
    800060c2:	f427b783          	ld	a5,-190(a5) # 80025000 <disk+0x2000>
    800060c6:	97ba                	add	a5,a5,a4
    800060c8:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800060cc:	0001d517          	auipc	a0,0x1d
    800060d0:	f3450513          	addi	a0,a0,-204 # 80023000 <disk>
    800060d4:	0001f797          	auipc	a5,0x1f
    800060d8:	f2c78793          	addi	a5,a5,-212 # 80025000 <disk+0x2000>
    800060dc:	6394                	ld	a3,0(a5)
    800060de:	96ba                	add	a3,a3,a4
    800060e0:	00c6d603          	lhu	a2,12(a3)
    800060e4:	00166613          	ori	a2,a2,1
    800060e8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800060ec:	f9842683          	lw	a3,-104(s0)
    800060f0:	6390                	ld	a2,0(a5)
    800060f2:	9732                	add	a4,a4,a2
    800060f4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0;
    800060f8:	20098613          	addi	a2,s3,512
    800060fc:	0612                	slli	a2,a2,0x4
    800060fe:	962a                	add	a2,a2,a0
    80006100:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006104:	00469713          	slli	a4,a3,0x4
    80006108:	6394                	ld	a3,0(a5)
    8000610a:	96ba                	add	a3,a3,a4
    8000610c:	6589                	lui	a1,0x2
    8000610e:	03058593          	addi	a1,a1,48 # 2030 <_entry-0x7fffdfd0>
    80006112:	94ae                	add	s1,s1,a1
    80006114:	94aa                	add	s1,s1,a0
    80006116:	e284                	sd	s1,0(a3)
  disk.desc[idx[2]].len = 1;
    80006118:	6394                	ld	a3,0(a5)
    8000611a:	96ba                	add	a3,a3,a4
    8000611c:	4585                	li	a1,1
    8000611e:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006120:	6394                	ld	a3,0(a5)
    80006122:	96ba                	add	a3,a3,a4
    80006124:	4509                	li	a0,2
    80006126:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    8000612a:	6394                	ld	a3,0(a5)
    8000612c:	9736                	add	a4,a4,a3
    8000612e:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006132:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    80006136:	03263423          	sd	s2,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    8000613a:	6794                	ld	a3,8(a5)
    8000613c:	0026d703          	lhu	a4,2(a3)
    80006140:	8b1d                	andi	a4,a4,7
    80006142:	2709                	addiw	a4,a4,2
    80006144:	0706                	slli	a4,a4,0x1
    80006146:	9736                	add	a4,a4,a3
    80006148:	01371023          	sh	s3,0(a4)
  __sync_synchronize();
    8000614c:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    80006150:	6798                	ld	a4,8(a5)
    80006152:	00275783          	lhu	a5,2(a4)
    80006156:	2785                	addiw	a5,a5,1
    80006158:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000615c:	100017b7          	lui	a5,0x10001
    80006160:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006164:	00492703          	lw	a4,4(s2)
    80006168:	4785                	li	a5,1
    8000616a:	02f71163          	bne	a4,a5,8000618c <virtio_disk_rw+0x220>
    sleep(b, &disk.vdisk_lock);
    8000616e:	0001f997          	auipc	s3,0x1f
    80006172:	f3a98993          	addi	s3,s3,-198 # 800250a8 <disk+0x20a8>
  while(b->disk == 1) {
    80006176:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006178:	85ce                	mv	a1,s3
    8000617a:	854a                	mv	a0,s2
    8000617c:	ffffc097          	auipc	ra,0xffffc
    80006180:	152080e7          	jalr	338(ra) # 800022ce <sleep>
  while(b->disk == 1) {
    80006184:	00492783          	lw	a5,4(s2)
    80006188:	fe9788e3          	beq	a5,s1,80006178 <virtio_disk_rw+0x20c>
  }

  disk.info[idx[0]].b = 0;
    8000618c:	f9042483          	lw	s1,-112(s0)
    80006190:	20048793          	addi	a5,s1,512 # 10001200 <_entry-0x6fffee00>
    80006194:	00479713          	slli	a4,a5,0x4
    80006198:	0001d797          	auipc	a5,0x1d
    8000619c:	e6878793          	addi	a5,a5,-408 # 80023000 <disk>
    800061a0:	97ba                	add	a5,a5,a4
    800061a2:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800061a6:	0001f917          	auipc	s2,0x1f
    800061aa:	e5a90913          	addi	s2,s2,-422 # 80025000 <disk+0x2000>
    free_desc(i);
    800061ae:	8526                	mv	a0,s1
    800061b0:	00000097          	auipc	ra,0x0
    800061b4:	bf6080e7          	jalr	-1034(ra) # 80005da6 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800061b8:	0492                	slli	s1,s1,0x4
    800061ba:	00093783          	ld	a5,0(s2)
    800061be:	94be                	add	s1,s1,a5
    800061c0:	00c4d783          	lhu	a5,12(s1)
    800061c4:	8b85                	andi	a5,a5,1
    800061c6:	cf89                	beqz	a5,800061e0 <virtio_disk_rw+0x274>
      i = disk.desc[i].next;
    800061c8:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    800061cc:	b7cd                	j	800061ae <virtio_disk_rw+0x242>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800061ce:	0001f797          	auipc	a5,0x1f
    800061d2:	e327b783          	ld	a5,-462(a5) # 80025000 <disk+0x2000>
    800061d6:	97ba                	add	a5,a5,a4
    800061d8:	4689                	li	a3,2
    800061da:	00d79623          	sh	a3,12(a5)
    800061de:	b5fd                	j	800060cc <virtio_disk_rw+0x160>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800061e0:	0001f517          	auipc	a0,0x1f
    800061e4:	ec850513          	addi	a0,a0,-312 # 800250a8 <disk+0x20a8>
    800061e8:	ffffb097          	auipc	ra,0xffffb
    800061ec:	adc080e7          	jalr	-1316(ra) # 80000cc4 <release>
}
    800061f0:	70e6                	ld	ra,120(sp)
    800061f2:	7446                	ld	s0,112(sp)
    800061f4:	74a6                	ld	s1,104(sp)
    800061f6:	7906                	ld	s2,96(sp)
    800061f8:	69e6                	ld	s3,88(sp)
    800061fa:	6a46                	ld	s4,80(sp)
    800061fc:	6aa6                	ld	s5,72(sp)
    800061fe:	6b06                	ld	s6,64(sp)
    80006200:	7be2                	ld	s7,56(sp)
    80006202:	7c42                	ld	s8,48(sp)
    80006204:	7ca2                	ld	s9,40(sp)
    80006206:	7d02                	ld	s10,32(sp)
    80006208:	6109                	addi	sp,sp,128
    8000620a:	8082                	ret
  if(write)
    8000620c:	e20d1ee3          	bnez	s10,80006048 <virtio_disk_rw+0xdc>
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
    80006210:	f8042023          	sw	zero,-128(s0)
    80006214:	bd2d                	j	8000604e <virtio_disk_rw+0xe2>

0000000080006216 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006216:	1101                	addi	sp,sp,-32
    80006218:	ec06                	sd	ra,24(sp)
    8000621a:	e822                	sd	s0,16(sp)
    8000621c:	e426                	sd	s1,8(sp)
    8000621e:	e04a                	sd	s2,0(sp)
    80006220:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006222:	0001f517          	auipc	a0,0x1f
    80006226:	e8650513          	addi	a0,a0,-378 # 800250a8 <disk+0x20a8>
    8000622a:	ffffb097          	auipc	ra,0xffffb
    8000622e:	9e6080e7          	jalr	-1562(ra) # 80000c10 <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006232:	0001f717          	auipc	a4,0x1f
    80006236:	dce70713          	addi	a4,a4,-562 # 80025000 <disk+0x2000>
    8000623a:	02075783          	lhu	a5,32(a4)
    8000623e:	6b18                	ld	a4,16(a4)
    80006240:	00275683          	lhu	a3,2(a4)
    80006244:	8ebd                	xor	a3,a3,a5
    80006246:	8a9d                	andi	a3,a3,7
    80006248:	cab9                	beqz	a3,8000629e <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    8000624a:	0001d917          	auipc	s2,0x1d
    8000624e:	db690913          	addi	s2,s2,-586 # 80023000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006252:	0001f497          	auipc	s1,0x1f
    80006256:	dae48493          	addi	s1,s1,-594 # 80025000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    8000625a:	078e                	slli	a5,a5,0x3
    8000625c:	97ba                	add	a5,a5,a4
    8000625e:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    80006260:	20078713          	addi	a4,a5,512
    80006264:	0712                	slli	a4,a4,0x4
    80006266:	974a                	add	a4,a4,s2
    80006268:	03074703          	lbu	a4,48(a4)
    8000626c:	ef21                	bnez	a4,800062c4 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    8000626e:	20078793          	addi	a5,a5,512
    80006272:	0792                	slli	a5,a5,0x4
    80006274:	97ca                	add	a5,a5,s2
    80006276:	7798                	ld	a4,40(a5)
    80006278:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    8000627c:	7788                	ld	a0,40(a5)
    8000627e:	ffffc097          	auipc	ra,0xffffc
    80006282:	1d6080e7          	jalr	470(ra) # 80002454 <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006286:	0204d783          	lhu	a5,32(s1)
    8000628a:	2785                	addiw	a5,a5,1
    8000628c:	8b9d                	andi	a5,a5,7
    8000628e:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006292:	6898                	ld	a4,16(s1)
    80006294:	00275683          	lhu	a3,2(a4)
    80006298:	8a9d                	andi	a3,a3,7
    8000629a:	fcf690e3          	bne	a3,a5,8000625a <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000629e:	10001737          	lui	a4,0x10001
    800062a2:	533c                	lw	a5,96(a4)
    800062a4:	8b8d                	andi	a5,a5,3
    800062a6:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    800062a8:	0001f517          	auipc	a0,0x1f
    800062ac:	e0050513          	addi	a0,a0,-512 # 800250a8 <disk+0x20a8>
    800062b0:	ffffb097          	auipc	ra,0xffffb
    800062b4:	a14080e7          	jalr	-1516(ra) # 80000cc4 <release>
}
    800062b8:	60e2                	ld	ra,24(sp)
    800062ba:	6442                	ld	s0,16(sp)
    800062bc:	64a2                	ld	s1,8(sp)
    800062be:	6902                	ld	s2,0(sp)
    800062c0:	6105                	addi	sp,sp,32
    800062c2:	8082                	ret
      panic("virtio_disk_intr status");
    800062c4:	00002517          	auipc	a0,0x2
    800062c8:	50c50513          	addi	a0,a0,1292 # 800087d0 <syscalls+0x3d0>
    800062cc:	ffffa097          	auipc	ra,0xffffa
    800062d0:	27c080e7          	jalr	636(ra) # 80000548 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
