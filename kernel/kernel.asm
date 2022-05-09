
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	0000a117          	auipc	sp,0xa
    80000004:	84010113          	addi	sp,sp,-1984 # 80009840 <stack0>
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
    8000004e:	ff660613          	addi	a2,a2,-10 # 80009040 <mscratch0>
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
    80000060:	eb478793          	addi	a5,a5,-332 # 80005f10 <timervec>
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
    80000094:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd77df>
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
    80000108:	73c50513          	addi	a0,a0,1852 # 80011840 <cons>
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
    8000012a:	6ce080e7          	jalr	1742(ra) # 800027f4 <either_copyin>
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
    8000014a:	6fa50513          	addi	a0,a0,1786 # 80011840 <cons>
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
    8000019a:	6aa50513          	addi	a0,a0,1706 # 80011840 <cons>
    8000019e:	00001097          	auipc	ra,0x1
    800001a2:	a72080e7          	jalr	-1422(ra) # 80000c10 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    800001a6:	00011497          	auipc	s1,0x11
    800001aa:	69a48493          	addi	s1,s1,1690 # 80011840 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001ae:	89a6                	mv	s3,s1
    800001b0:	00011917          	auipc	s2,0x11
    800001b4:	72890913          	addi	s2,s2,1832 # 800118d8 <cons+0x98>
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
    800001d2:	a42080e7          	jalr	-1470(ra) # 80001c10 <myproc>
    800001d6:	591c                	lw	a5,48(a0)
    800001d8:	e7b5                	bnez	a5,80000244 <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001da:	85ce                	mv	a1,s3
    800001dc:	854a                	mv	a0,s2
    800001de:	00002097          	auipc	ra,0x2
    800001e2:	35e080e7          	jalr	862(ra) # 8000253c <sleep>
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
    8000021e:	584080e7          	jalr	1412(ra) # 8000279e <either_copyout>
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
    80000232:	61250513          	addi	a0,a0,1554 # 80011840 <cons>
    80000236:	00001097          	auipc	ra,0x1
    8000023a:	a8e080e7          	jalr	-1394(ra) # 80000cc4 <release>

  return target - n;
    8000023e:	414b853b          	subw	a0,s7,s4
    80000242:	a811                	j	80000256 <consoleread+0xe8>
        release(&cons.lock);
    80000244:	00011517          	auipc	a0,0x11
    80000248:	5fc50513          	addi	a0,a0,1532 # 80011840 <cons>
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
    80000280:	64f72e23          	sw	a5,1628(a4) # 800118d8 <cons+0x98>
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
    800002da:	56a50513          	addi	a0,a0,1386 # 80011840 <cons>
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
    80000300:	54e080e7          	jalr	1358(ra) # 8000284a <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000304:	00011517          	auipc	a0,0x11
    80000308:	53c50513          	addi	a0,a0,1340 # 80011840 <cons>
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
    8000032c:	51870713          	addi	a4,a4,1304 # 80011840 <cons>
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
    80000356:	4ee78793          	addi	a5,a5,1262 # 80011840 <cons>
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
    80000384:	5587a783          	lw	a5,1368(a5) # 800118d8 <cons+0x98>
    80000388:	0807879b          	addiw	a5,a5,128
    8000038c:	f6f61ce3          	bne	a2,a5,80000304 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000390:	863e                	mv	a2,a5
    80000392:	a07d                	j	80000440 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000394:	00011717          	auipc	a4,0x11
    80000398:	4ac70713          	addi	a4,a4,1196 # 80011840 <cons>
    8000039c:	0a072783          	lw	a5,160(a4)
    800003a0:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a4:	00011497          	auipc	s1,0x11
    800003a8:	49c48493          	addi	s1,s1,1180 # 80011840 <cons>
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
    800003e4:	46070713          	addi	a4,a4,1120 # 80011840 <cons>
    800003e8:	0a072783          	lw	a5,160(a4)
    800003ec:	09c72703          	lw	a4,156(a4)
    800003f0:	f0f70ae3          	beq	a4,a5,80000304 <consoleintr+0x3c>
      cons.e--;
    800003f4:	37fd                	addiw	a5,a5,-1
    800003f6:	00011717          	auipc	a4,0x11
    800003fa:	4ef72523          	sw	a5,1258(a4) # 800118e0 <cons+0xa0>
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
    80000420:	42478793          	addi	a5,a5,1060 # 80011840 <cons>
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
    80000444:	48c7ae23          	sw	a2,1180(a5) # 800118dc <cons+0x9c>
        wakeup(&cons.r);
    80000448:	00011517          	auipc	a0,0x11
    8000044c:	49050513          	addi	a0,a0,1168 # 800118d8 <cons+0x98>
    80000450:	00002097          	auipc	ra,0x2
    80000454:	272080e7          	jalr	626(ra) # 800026c2 <wakeup>
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
    8000046e:	3d650513          	addi	a0,a0,982 # 80011840 <cons>
    80000472:	00000097          	auipc	ra,0x0
    80000476:	70e080e7          	jalr	1806(ra) # 80000b80 <initlock>

  uartinit();
    8000047a:	00000097          	auipc	ra,0x0
    8000047e:	330080e7          	jalr	816(ra) # 800007aa <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000482:	00021797          	auipc	a5,0x21
    80000486:	73e78793          	addi	a5,a5,1854 # 80021bc0 <devsw>
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
    80000558:	3a07a623          	sw	zero,940(a5) # 80011900 <pr+0x18>
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
    800005c8:	33cdad83          	lw	s11,828(s11) # 80011900 <pr+0x18>
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
    80000606:	2e650513          	addi	a0,a0,742 # 800118e8 <pr>
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
    8000076a:	18250513          	addi	a0,a0,386 # 800118e8 <pr>
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
    80000786:	16648493          	addi	s1,s1,358 # 800118e8 <pr>
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
    800007e6:	12650513          	addi	a0,a0,294 # 80011908 <uart_tx_lock>
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
    80000878:	094a0a13          	addi	s4,s4,148 # 80011908 <uart_tx_lock>
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
    800008ba:	e0c080e7          	jalr	-500(ra) # 800026c2 <wakeup>
    
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
    800008f6:	01650513          	addi	a0,a0,22 # 80011908 <uart_tx_lock>
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
    80000938:	fd4a0a13          	addi	s4,s4,-44 # 80011908 <uart_tx_lock>
    8000093c:	00008497          	auipc	s1,0x8
    80000940:	6c848493          	addi	s1,s1,1736 # 80009004 <uart_tx_r>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000944:	00008917          	auipc	s2,0x8
    80000948:	6c490913          	addi	s2,s2,1732 # 80009008 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    8000094c:	85d2                	mv	a1,s4
    8000094e:	8526                	mv	a0,s1
    80000950:	00002097          	auipc	ra,0x2
    80000954:	bec080e7          	jalr	-1044(ra) # 8000253c <sleep>
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
    80000978:	f9448493          	addi	s1,s1,-108 # 80011908 <uart_tx_lock>
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
    800009fa:	f1248493          	addi	s1,s1,-238 # 80011908 <uart_tx_lock>
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
    80000a38:	00026797          	auipc	a5,0x26
    80000a3c:	5e878793          	addi	a5,a5,1512 # 80027020 <end>
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
    80000a5c:	ee890913          	addi	s2,s2,-280 # 80011940 <kmem>
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
    80000af8:	e4c50513          	addi	a0,a0,-436 # 80011940 <kmem>
    80000afc:	00000097          	auipc	ra,0x0
    80000b00:	084080e7          	jalr	132(ra) # 80000b80 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b04:	45c5                	li	a1,17
    80000b06:	05ee                	slli	a1,a1,0x1b
    80000b08:	00026517          	auipc	a0,0x26
    80000b0c:	51850513          	addi	a0,a0,1304 # 80027020 <end>
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
    80000b2e:	e1648493          	addi	s1,s1,-490 # 80011940 <kmem>
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
    80000b46:	dfe50513          	addi	a0,a0,-514 # 80011940 <kmem>
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
    80000b72:	dd250513          	addi	a0,a0,-558 # 80011940 <kmem>
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
    80000bae:	04a080e7          	jalr	74(ra) # 80001bf4 <mycpu>
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
    80000be0:	018080e7          	jalr	24(ra) # 80001bf4 <mycpu>
    80000be4:	5d3c                	lw	a5,120(a0)
    80000be6:	cf89                	beqz	a5,80000c00 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000be8:	00001097          	auipc	ra,0x1
    80000bec:	00c080e7          	jalr	12(ra) # 80001bf4 <mycpu>
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
    80000c04:	ff4080e7          	jalr	-12(ra) # 80001bf4 <mycpu>
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
    80000c44:	fb4080e7          	jalr	-76(ra) # 80001bf4 <mycpu>
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
    80000c70:	f88080e7          	jalr	-120(ra) # 80001bf4 <mycpu>
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
    80000eca:	d1e080e7          	jalr	-738(ra) # 80001be4 <cpuid>
#endif    
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
    80000ee6:	d02080e7          	jalr	-766(ra) # 80001be4 <cpuid>
    80000eea:	85aa                	mv	a1,a0
    80000eec:	00007517          	auipc	a0,0x7
    80000ef0:	1cc50513          	addi	a0,a0,460 # 800080b8 <digits+0x78>
    80000ef4:	fffff097          	auipc	ra,0xfffff
    80000ef8:	69e080e7          	jalr	1694(ra) # 80000592 <printf>
    kvminithart();    // turn on paging
    80000efc:	00000097          	auipc	ra,0x0
    80000f00:	2a2080e7          	jalr	674(ra) # 8000119e <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f04:	00002097          	auipc	ra,0x2
    80000f08:	a86080e7          	jalr	-1402(ra) # 8000298a <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f0c:	00005097          	auipc	ra,0x5
    80000f10:	044080e7          	jalr	68(ra) # 80005f50 <plicinithart>
  }

  scheduler();        
    80000f14:	00001097          	auipc	ra,0x1
    80000f18:	320080e7          	jalr	800(ra) # 80002234 <scheduler>
    consoleinit();
    80000f1c:	fffff097          	auipc	ra,0xfffff
    80000f20:	53e080e7          	jalr	1342(ra) # 8000045a <consoleinit>
    statsinit();
    80000f24:	00005097          	auipc	ra,0x5
    80000f28:	7ee080e7          	jalr	2030(ra) # 80006712 <statsinit>
    printfinit();
    80000f2c:	00000097          	auipc	ra,0x0
    80000f30:	84c080e7          	jalr	-1972(ra) # 80000778 <printfinit>
    printf("\n");
    80000f34:	00007517          	auipc	a0,0x7
    80000f38:	19450513          	addi	a0,a0,404 # 800080c8 <digits+0x88>
    80000f3c:	fffff097          	auipc	ra,0xfffff
    80000f40:	656080e7          	jalr	1622(ra) # 80000592 <printf>
    printf("xv6 kernel is booting\n");
    80000f44:	00007517          	auipc	a0,0x7
    80000f48:	15c50513          	addi	a0,a0,348 # 800080a0 <digits+0x60>
    80000f4c:	fffff097          	auipc	ra,0xfffff
    80000f50:	646080e7          	jalr	1606(ra) # 80000592 <printf>
    printf("\n");
    80000f54:	00007517          	auipc	a0,0x7
    80000f58:	17450513          	addi	a0,a0,372 # 800080c8 <digits+0x88>
    80000f5c:	fffff097          	auipc	ra,0xfffff
    80000f60:	636080e7          	jalr	1590(ra) # 80000592 <printf>
    kinit();         // physical page allocator
    80000f64:	00000097          	auipc	ra,0x0
    80000f68:	b80080e7          	jalr	-1152(ra) # 80000ae4 <kinit>
    kvminit();       // create kernel page table
    80000f6c:	00000097          	auipc	ra,0x0
    80000f70:	4ae080e7          	jalr	1198(ra) # 8000141a <kvminit>
    kvminithart();   // turn on paging
    80000f74:	00000097          	auipc	ra,0x0
    80000f78:	22a080e7          	jalr	554(ra) # 8000119e <kvminithart>
    procinit();      // process table
    80000f7c:	00001097          	auipc	ra,0x1
    80000f80:	c00080e7          	jalr	-1024(ra) # 80001b7c <procinit>
    trapinit();      // trap vectors
    80000f84:	00002097          	auipc	ra,0x2
    80000f88:	9de080e7          	jalr	-1570(ra) # 80002962 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f8c:	00002097          	auipc	ra,0x2
    80000f90:	9fe080e7          	jalr	-1538(ra) # 8000298a <trapinithart>
    plicinit();      // set up interrupt controller
    80000f94:	00005097          	auipc	ra,0x5
    80000f98:	fa6080e7          	jalr	-90(ra) # 80005f3a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f9c:	00005097          	auipc	ra,0x5
    80000fa0:	fb4080e7          	jalr	-76(ra) # 80005f50 <plicinithart>
    binit();         // buffer cache
    80000fa4:	00002097          	auipc	ra,0x2
    80000fa8:	128080e7          	jalr	296(ra) # 800030cc <binit>
    iinit();         // inode cache
    80000fac:	00002097          	auipc	ra,0x2
    80000fb0:	7b8080e7          	jalr	1976(ra) # 80003764 <iinit>
    fileinit();      // file table
    80000fb4:	00003097          	auipc	ra,0x3
    80000fb8:	752080e7          	jalr	1874(ra) # 80004706 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fbc:	00005097          	auipc	ra,0x5
    80000fc0:	09c080e7          	jalr	156(ra) # 80006058 <virtio_disk_init>
    userinit();      // first user process
    80000fc4:	00001097          	auipc	ra,0x1
    80000fc8:	fc2080e7          	jalr	-62(ra) # 80001f86 <userinit>
    __sync_synchronize();
    80000fcc:	0ff0000f          	fence
    started = 1;
    80000fd0:	4785                	li	a5,1
    80000fd2:	00008717          	auipc	a4,0x8
    80000fd6:	02f72d23          	sw	a5,58(a4) # 8000900c <started>
    80000fda:	bf2d                	j	80000f14 <main+0x56>

0000000080000fdc <kpagetable_init_helper>:
extern char etext[]; // kernel.ld sets this to end of kernel code.

extern char trampoline[]; // trampoline.S

void kpagetable_init_helper(pagetable_t pgtbl_dst, pagetable_t pgtbl_src)
{
    80000fdc:	7139                	addi	sp,sp,-64
    80000fde:	fc06                	sd	ra,56(sp)
    80000fe0:	f822                	sd	s0,48(sp)
    80000fe2:	f426                	sd	s1,40(sp)
    80000fe4:	f04a                	sd	s2,32(sp)
    80000fe6:	ec4e                	sd	s3,24(sp)
    80000fe8:	e852                	sd	s4,16(sp)
    80000fea:	e456                	sd	s5,8(sp)
    80000fec:	e05a                	sd	s6,0(sp)
    80000fee:	0080                	addi	s0,sp,64
    80000ff0:	8b2a                	mv	s6,a0
    80000ff2:	8a2e                	mv	s4,a1
    80000ff4:	4481                	li	s1,0
  for (int i = 0; i < 512; i++)
  {
    pte_t pte_src = pgtbl_src[i];
    if ((pte_src & PTE_V) && (pte_src & (PTE_R | PTE_W | PTE_X)) == 0)
    80000ff6:	4a85                	li	s5,1
    80000ff8:	a099                	j	8000103e <kpagetable_init_helper+0x62>
    {
      pagetable_t next_level_pgtbl_dst = (pagetable_t)(kalloc());
    80000ffa:	00000097          	auipc	ra,0x0
    80000ffe:	b26080e7          	jalr	-1242(ra) # 80000b20 <kalloc>
    80001002:	89aa                	mv	s3,a0
      memset(next_level_pgtbl_dst, 0, PGSIZE);
    80001004:	6605                	lui	a2,0x1
    80001006:	4581                	li	a1,0
    80001008:	00000097          	auipc	ra,0x0
    8000100c:	d04080e7          	jalr	-764(ra) # 80000d0c <memset>
      if (next_level_pgtbl_dst == 0)
    80001010:	04098763          	beqz	s3,8000105e <kpagetable_init_helper+0x82>
      {
        panic("kpagetable_init_helper: kalloc failed");
      }
      pagetable_t next_level_pgtbl_src = (pagetable_t)PTE2PA(pte_src);
      pgtbl_dst[i] = PA2PTE(next_level_pgtbl_dst) | PTE_FLAGS(pte_src);
    80001014:	009b0733          	add	a4,s6,s1
    80001018:	00c9d793          	srli	a5,s3,0xc
    8000101c:	07aa                	slli	a5,a5,0xa
    8000101e:	3ff97693          	andi	a3,s2,1023
    80001022:	8fd5                	or	a5,a5,a3
    80001024:	e31c                	sd	a5,0(a4)
      pagetable_t next_level_pgtbl_src = (pagetable_t)PTE2PA(pte_src);
    80001026:	00a95593          	srli	a1,s2,0xa
      kpagetable_init_helper(next_level_pgtbl_dst, next_level_pgtbl_src);
    8000102a:	05b2                	slli	a1,a1,0xc
    8000102c:	854e                	mv	a0,s3
    8000102e:	00000097          	auipc	ra,0x0
    80001032:	fae080e7          	jalr	-82(ra) # 80000fdc <kpagetable_init_helper>
  for (int i = 0; i < 512; i++)
    80001036:	04a1                	addi	s1,s1,8
    80001038:	6785                	lui	a5,0x1
    8000103a:	02f48a63          	beq	s1,a5,8000106e <kpagetable_init_helper+0x92>
    pte_t pte_src = pgtbl_src[i];
    8000103e:	009a07b3          	add	a5,s4,s1
    80001042:	0007b903          	ld	s2,0(a5) # 1000 <_entry-0x7ffff000>
    if ((pte_src & PTE_V) && (pte_src & (PTE_R | PTE_W | PTE_X)) == 0)
    80001046:	00f97793          	andi	a5,s2,15
    8000104a:	fb5788e3          	beq	a5,s5,80000ffa <kpagetable_init_helper+0x1e>
    }
    else if (pte_src & PTE_V)
    8000104e:	00197793          	andi	a5,s2,1
    80001052:	d3f5                	beqz	a5,80001036 <kpagetable_init_helper+0x5a>
    {
      pgtbl_dst[i] = pte_src;
    80001054:	009b07b3          	add	a5,s6,s1
    80001058:	0127b023          	sd	s2,0(a5)
    8000105c:	bfe9                	j	80001036 <kpagetable_init_helper+0x5a>
        panic("kpagetable_init_helper: kalloc failed");
    8000105e:	00007517          	auipc	a0,0x7
    80001062:	07250513          	addi	a0,a0,114 # 800080d0 <digits+0x90>
    80001066:	fffff097          	auipc	ra,0xfffff
    8000106a:	4e2080e7          	jalr	1250(ra) # 80000548 <panic>
    }
  }
}
    8000106e:	70e2                	ld	ra,56(sp)
    80001070:	7442                	ld	s0,48(sp)
    80001072:	74a2                	ld	s1,40(sp)
    80001074:	7902                	ld	s2,32(sp)
    80001076:	69e2                	ld	s3,24(sp)
    80001078:	6a42                	ld	s4,16(sp)
    8000107a:	6aa2                	ld	s5,8(sp)
    8000107c:	6b02                	ld	s6,0(sp)
    8000107e:	6121                	addi	sp,sp,64
    80001080:	8082                	ret

0000000080001082 <kpagetable_init>:

// create kernel page table for every process
pagetable_t kpagetable_init()
{
    80001082:	1101                	addi	sp,sp,-32
    80001084:	ec06                	sd	ra,24(sp)
    80001086:	e822                	sd	s0,16(sp)
    80001088:	e426                	sd	s1,8(sp)
    8000108a:	e04a                	sd	s2,0(sp)
    8000108c:	1000                	addi	s0,sp,32
  // get 4096 bytes
  pagetable_t pagetable = (pagetable_t)kalloc();
    8000108e:	00000097          	auipc	ra,0x0
    80001092:	a92080e7          	jalr	-1390(ra) # 80000b20 <kalloc>
  if (pagetable == 0) {
    80001096:	c525                	beqz	a0,800010fe <kpagetable_init+0x7c>
    80001098:	84aa                	mv	s1,a0
    panic("kpagetable_init: kalloc failed");
  }
  memcpy(pagetable, kernel_pagetable, PGSIZE);
    8000109a:	6605                	lui	a2,0x1
    8000109c:	00008597          	auipc	a1,0x8
    800010a0:	f7c5b583          	ld	a1,-132(a1) # 80009018 <kernel_pagetable>
    800010a4:	00000097          	auipc	ra,0x0
    800010a8:	d2c080e7          	jalr	-724(ra) # 80000dd0 <memcpy>
  pagetable_t next_level_pgtbl_dst = (pagetable_t)(kalloc());
    800010ac:	00000097          	auipc	ra,0x0
    800010b0:	a74080e7          	jalr	-1420(ra) # 80000b20 <kalloc>
    800010b4:	892a                	mv	s2,a0
  if (next_level_pgtbl_dst == 0)
    800010b6:	cd21                	beqz	a0,8000110e <kpagetable_init+0x8c>
  {
    panic("kpagetable_init: kalloc failed");
  }
  memset(next_level_pgtbl_dst, 0, PGSIZE);
    800010b8:	6605                	lui	a2,0x1
    800010ba:	4581                	li	a1,0
    800010bc:	00000097          	auipc	ra,0x0
    800010c0:	c50080e7          	jalr	-944(ra) # 80000d0c <memset>
  pagetable[0] = PA2PTE(next_level_pgtbl_dst) | PTE_FLAGS(kernel_pagetable[0]); 
    800010c4:	00008697          	auipc	a3,0x8
    800010c8:	f5468693          	addi	a3,a3,-172 # 80009018 <kernel_pagetable>
    800010cc:	629c                	ld	a5,0(a3)
    800010ce:	639c                	ld	a5,0(a5)
    800010d0:	3ff7f793          	andi	a5,a5,1023
    800010d4:	00c95713          	srli	a4,s2,0xc
    800010d8:	072a                	slli	a4,a4,0xa
    800010da:	8fd9                	or	a5,a5,a4
    800010dc:	e09c                	sd	a5,0(s1)
  pagetable_t next_level_pgtbl_src = (pagetable_t)PTE2PA(kernel_pagetable[0]);
    800010de:	629c                	ld	a5,0(a3)
    800010e0:	638c                	ld	a1,0(a5)
    800010e2:	81a9                	srli	a1,a1,0xa
  kpagetable_init_helper(next_level_pgtbl_dst, next_level_pgtbl_src);
    800010e4:	05b2                	slli	a1,a1,0xc
    800010e6:	854a                	mv	a0,s2
    800010e8:	00000097          	auipc	ra,0x0
    800010ec:	ef4080e7          	jalr	-268(ra) # 80000fdc <kpagetable_init_helper>
  //   vmprint(next_level_pgtbl_src);
  // }
  // called_count += 1;
  // # endif
  return pagetable;
}
    800010f0:	8526                	mv	a0,s1
    800010f2:	60e2                	ld	ra,24(sp)
    800010f4:	6442                	ld	s0,16(sp)
    800010f6:	64a2                	ld	s1,8(sp)
    800010f8:	6902                	ld	s2,0(sp)
    800010fa:	6105                	addi	sp,sp,32
    800010fc:	8082                	ret
    panic("kpagetable_init: kalloc failed");
    800010fe:	00007517          	auipc	a0,0x7
    80001102:	ffa50513          	addi	a0,a0,-6 # 800080f8 <digits+0xb8>
    80001106:	fffff097          	auipc	ra,0xfffff
    8000110a:	442080e7          	jalr	1090(ra) # 80000548 <panic>
    panic("kpagetable_init: kalloc failed");
    8000110e:	00007517          	auipc	a0,0x7
    80001112:	fea50513          	addi	a0,a0,-22 # 800080f8 <digits+0xb8>
    80001116:	fffff097          	auipc	ra,0xfffff
    8000111a:	432080e7          	jalr	1074(ra) # 80000548 <panic>

000000008000111e <free_kpagetable_helper>:


void free_kpagetable_helper(pagetable_t pagetable)
{
    8000111e:	7179                	addi	sp,sp,-48
    80001120:	f406                	sd	ra,40(sp)
    80001122:	f022                	sd	s0,32(sp)
    80001124:	ec26                	sd	s1,24(sp)
    80001126:	e84a                	sd	s2,16(sp)
    80001128:	e44e                	sd	s3,8(sp)
    8000112a:	1800                	addi	s0,sp,48
    8000112c:	89aa                	mv	s3,a0
  for (int i = 0; i < 512; ++i) {
    8000112e:	84aa                	mv	s1,a0
    80001130:	6905                	lui	s2,0x1
    80001132:	992a                	add	s2,s2,a0
    80001134:	a021                	j	8000113c <free_kpagetable_helper+0x1e>
    80001136:	04a1                	addi	s1,s1,8
    80001138:	03248063          	beq	s1,s2,80001158 <free_kpagetable_helper+0x3a>
    pte_t pte = pagetable[i];
    8000113c:	6088                	ld	a0,0(s1)
    if (pte & PTE_V) {
    8000113e:	00157793          	andi	a5,a0,1
    80001142:	dbf5                	beqz	a5,80001136 <free_kpagetable_helper+0x18>
      if (pte & (PTE_R | PTE_W | PTE_X)) {
    80001144:	00e57793          	andi	a5,a0,14
    80001148:	f7fd                	bnez	a5,80001136 <free_kpagetable_helper+0x18>
        continue;
      }
      pagetable_t next_level_pgtbl = (pagetable_t)PTE2PA(pte);
    8000114a:	8129                	srli	a0,a0,0xa
      free_kpagetable_helper(next_level_pgtbl);
    8000114c:	0532                	slli	a0,a0,0xc
    8000114e:	00000097          	auipc	ra,0x0
    80001152:	fd0080e7          	jalr	-48(ra) # 8000111e <free_kpagetable_helper>
    80001156:	b7c5                	j	80001136 <free_kpagetable_helper+0x18>
    }
  }
  kfree((void *) pagetable);
    80001158:	854e                	mv	a0,s3
    8000115a:	00000097          	auipc	ra,0x0
    8000115e:	8ca080e7          	jalr	-1846(ra) # 80000a24 <kfree>
}
    80001162:	70a2                	ld	ra,40(sp)
    80001164:	7402                	ld	s0,32(sp)
    80001166:	64e2                	ld	s1,24(sp)
    80001168:	6942                	ld	s2,16(sp)
    8000116a:	69a2                	ld	s3,8(sp)
    8000116c:	6145                	addi	sp,sp,48
    8000116e:	8082                	ret

0000000080001170 <free_kpagetable>:

// free kernel page table for every process
void free_kpagetable(pagetable_t pagetable)
{
    80001170:	1101                	addi	sp,sp,-32
    80001172:	ec06                	sd	ra,24(sp)
    80001174:	e822                	sd	s0,16(sp)
    80001176:	e426                	sd	s1,8(sp)
    80001178:	1000                	addi	s0,sp,32
    8000117a:	84aa                	mv	s1,a0
  pagetable_t pgtbl = (pagetable_t) PTE2PA(pagetable[0]);
    8000117c:	6108                	ld	a0,0(a0)
    8000117e:	8129                	srli	a0,a0,0xa
  free_kpagetable_helper((pagetable_t) pgtbl);
    80001180:	0532                	slli	a0,a0,0xc
    80001182:	00000097          	auipc	ra,0x0
    80001186:	f9c080e7          	jalr	-100(ra) # 8000111e <free_kpagetable_helper>
  kfree(pagetable);
    8000118a:	8526                	mv	a0,s1
    8000118c:	00000097          	auipc	ra,0x0
    80001190:	898080e7          	jalr	-1896(ra) # 80000a24 <kfree>
}
    80001194:	60e2                	ld	ra,24(sp)
    80001196:	6442                	ld	s0,16(sp)
    80001198:	64a2                	ld	s1,8(sp)
    8000119a:	6105                	addi	sp,sp,32
    8000119c:	8082                	ret

000000008000119e <kvminithart>:
}

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void kvminithart()
{
    8000119e:	1141                	addi	sp,sp,-16
    800011a0:	e422                	sd	s0,8(sp)
    800011a2:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    800011a4:	00008797          	auipc	a5,0x8
    800011a8:	e747b783          	ld	a5,-396(a5) # 80009018 <kernel_pagetable>
    800011ac:	83b1                	srli	a5,a5,0xc
    800011ae:	577d                	li	a4,-1
    800011b0:	177e                	slli	a4,a4,0x3f
    800011b2:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    800011b4:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    800011b8:	12000073          	sfence.vma
  sfence_vma();
}
    800011bc:	6422                	ld	s0,8(sp)
    800011be:	0141                	addi	sp,sp,16
    800011c0:	8082                	ret

00000000800011c2 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    800011c2:	7139                	addi	sp,sp,-64
    800011c4:	fc06                	sd	ra,56(sp)
    800011c6:	f822                	sd	s0,48(sp)
    800011c8:	f426                	sd	s1,40(sp)
    800011ca:	f04a                	sd	s2,32(sp)
    800011cc:	ec4e                	sd	s3,24(sp)
    800011ce:	e852                	sd	s4,16(sp)
    800011d0:	e456                	sd	s5,8(sp)
    800011d2:	e05a                	sd	s6,0(sp)
    800011d4:	0080                	addi	s0,sp,64
    800011d6:	84aa                	mv	s1,a0
    800011d8:	89ae                	mv	s3,a1
    800011da:	8ab2                	mv	s5,a2
  if (va >= MAXVA)
    800011dc:	57fd                	li	a5,-1
    800011de:	83e9                	srli	a5,a5,0x1a
    800011e0:	4a79                	li	s4,30
    panic("walk");

  for (int level = 2; level > 0; level--)
    800011e2:	4b31                	li	s6,12
  if (va >= MAXVA)
    800011e4:	04b7f263          	bgeu	a5,a1,80001228 <walk+0x66>
    panic("walk");
    800011e8:	00007517          	auipc	a0,0x7
    800011ec:	f3050513          	addi	a0,a0,-208 # 80008118 <digits+0xd8>
    800011f0:	fffff097          	auipc	ra,0xfffff
    800011f4:	358080e7          	jalr	856(ra) # 80000548 <panic>
    {
      pagetable = (pagetable_t)PTE2PA(*pte);
    }
    else
    {
      if (!alloc || (pagetable = (pde_t *)kalloc()) == 0)
    800011f8:	060a8663          	beqz	s5,80001264 <walk+0xa2>
    800011fc:	00000097          	auipc	ra,0x0
    80001200:	924080e7          	jalr	-1756(ra) # 80000b20 <kalloc>
    80001204:	84aa                	mv	s1,a0
    80001206:	c529                	beqz	a0,80001250 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001208:	6605                	lui	a2,0x1
    8000120a:	4581                	li	a1,0
    8000120c:	00000097          	auipc	ra,0x0
    80001210:	b00080e7          	jalr	-1280(ra) # 80000d0c <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001214:	00c4d793          	srli	a5,s1,0xc
    80001218:	07aa                	slli	a5,a5,0xa
    8000121a:	0017e793          	ori	a5,a5,1
    8000121e:	00f93023          	sd	a5,0(s2) # 1000 <_entry-0x7ffff000>
  for (int level = 2; level > 0; level--)
    80001222:	3a5d                	addiw	s4,s4,-9
    80001224:	036a0063          	beq	s4,s6,80001244 <walk+0x82>
    pte_t *pte = &(pagetable[PX(level, va)]);
    80001228:	0149d933          	srl	s2,s3,s4
    8000122c:	1ff97913          	andi	s2,s2,511
    80001230:	090e                	slli	s2,s2,0x3
    80001232:	9926                	add	s2,s2,s1
    if (*pte & PTE_V)
    80001234:	00093483          	ld	s1,0(s2)
    80001238:	0014f793          	andi	a5,s1,1
    8000123c:	dfd5                	beqz	a5,800011f8 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000123e:	80a9                	srli	s1,s1,0xa
    80001240:	04b2                	slli	s1,s1,0xc
    80001242:	b7c5                	j	80001222 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001244:	00c9d513          	srli	a0,s3,0xc
    80001248:	1ff57513          	andi	a0,a0,511
    8000124c:	050e                	slli	a0,a0,0x3
    8000124e:	9526                	add	a0,a0,s1
}
    80001250:	70e2                	ld	ra,56(sp)
    80001252:	7442                	ld	s0,48(sp)
    80001254:	74a2                	ld	s1,40(sp)
    80001256:	7902                	ld	s2,32(sp)
    80001258:	69e2                	ld	s3,24(sp)
    8000125a:	6a42                	ld	s4,16(sp)
    8000125c:	6aa2                	ld	s5,8(sp)
    8000125e:	6b02                	ld	s6,0(sp)
    80001260:	6121                	addi	sp,sp,64
    80001262:	8082                	ret
        return 0;
    80001264:	4501                	li	a0,0
    80001266:	b7ed                	j	80001250 <walk+0x8e>

0000000080001268 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if (va >= MAXVA)
    80001268:	57fd                	li	a5,-1
    8000126a:	83e9                	srli	a5,a5,0x1a
    8000126c:	00b7f463          	bgeu	a5,a1,80001274 <walkaddr+0xc>
    return 0;
    80001270:	4501                	li	a0,0
    return 0;
  if ((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001272:	8082                	ret
{
    80001274:	1141                	addi	sp,sp,-16
    80001276:	e406                	sd	ra,8(sp)
    80001278:	e022                	sd	s0,0(sp)
    8000127a:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000127c:	4601                	li	a2,0
    8000127e:	00000097          	auipc	ra,0x0
    80001282:	f44080e7          	jalr	-188(ra) # 800011c2 <walk>
  if (pte == 0)
    80001286:	c105                	beqz	a0,800012a6 <walkaddr+0x3e>
  if ((*pte & PTE_V) == 0)
    80001288:	611c                	ld	a5,0(a0)
  if ((*pte & PTE_U) == 0)
    8000128a:	0117f693          	andi	a3,a5,17
    8000128e:	4745                	li	a4,17
    return 0;
    80001290:	4501                	li	a0,0
  if ((*pte & PTE_U) == 0)
    80001292:	00e68663          	beq	a3,a4,8000129e <walkaddr+0x36>
}
    80001296:	60a2                	ld	ra,8(sp)
    80001298:	6402                	ld	s0,0(sp)
    8000129a:	0141                	addi	sp,sp,16
    8000129c:	8082                	ret
  pa = PTE2PA(*pte);
    8000129e:	00a7d513          	srli	a0,a5,0xa
    800012a2:	0532                	slli	a0,a0,0xc
  return pa;
    800012a4:	bfcd                	j	80001296 <walkaddr+0x2e>
    return 0;
    800012a6:	4501                	li	a0,0
    800012a8:	b7fd                	j	80001296 <walkaddr+0x2e>

00000000800012aa <walkaddr_kpgtbl>:
walkaddr_kpgtbl(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if (va >= MAXVA)
    800012aa:	57fd                	li	a5,-1
    800012ac:	83e9                	srli	a5,a5,0x1a
    800012ae:	00b7f463          	bgeu	a5,a1,800012b6 <walkaddr_kpgtbl+0xc>
    return 0;
    800012b2:	4501                	li	a0,0
    return 0;
  if (*pte & PTE_U)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800012b4:	8082                	ret
{
    800012b6:	1141                	addi	sp,sp,-16
    800012b8:	e406                	sd	ra,8(sp)
    800012ba:	e022                	sd	s0,0(sp)
    800012bc:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800012be:	4601                	li	a2,0
    800012c0:	00000097          	auipc	ra,0x0
    800012c4:	f02080e7          	jalr	-254(ra) # 800011c2 <walk>
  if (pte == 0)
    800012c8:	c105                	beqz	a0,800012e8 <walkaddr_kpgtbl+0x3e>
  if ((*pte & PTE_V) == 0)
    800012ca:	611c                	ld	a5,0(a0)
    800012cc:	0017f513          	andi	a0,a5,1
    800012d0:	c901                	beqz	a0,800012e0 <walkaddr_kpgtbl+0x36>
  if (*pte & PTE_U)
    800012d2:	0107f713          	andi	a4,a5,16
    return 0;
    800012d6:	4501                	li	a0,0
  if (*pte & PTE_U)
    800012d8:	e701                	bnez	a4,800012e0 <walkaddr_kpgtbl+0x36>
  pa = PTE2PA(*pte);
    800012da:	00a7d513          	srli	a0,a5,0xa
    800012de:	0532                	slli	a0,a0,0xc
}
    800012e0:	60a2                	ld	ra,8(sp)
    800012e2:	6402                	ld	s0,0(sp)
    800012e4:	0141                	addi	sp,sp,16
    800012e6:	8082                	ret
    return 0;
    800012e8:	4501                	li	a0,0
    800012ea:	bfdd                	j	800012e0 <walkaddr_kpgtbl+0x36>

00000000800012ec <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    800012ec:	1101                	addi	sp,sp,-32
    800012ee:	ec06                	sd	ra,24(sp)
    800012f0:	e822                	sd	s0,16(sp)
    800012f2:	e426                	sd	s1,8(sp)
    800012f4:	e04a                	sd	s2,0(sp)
    800012f6:	1000                	addi	s0,sp,32
    800012f8:	84aa                	mv	s1,a0
  uint64 off = va % PGSIZE;
    800012fa:	1552                	slli	a0,a0,0x34
    800012fc:	03455913          	srli	s2,a0,0x34
  pte_t *pte;
  uint64 pa;
  pte = walk(myproc()->kernel_pagetable, va, 0);
    80001300:	00001097          	auipc	ra,0x1
    80001304:	910080e7          	jalr	-1776(ra) # 80001c10 <myproc>
    80001308:	4601                	li	a2,0
    8000130a:	85a6                	mv	a1,s1
    8000130c:	16853503          	ld	a0,360(a0)
    80001310:	00000097          	auipc	ra,0x0
    80001314:	eb2080e7          	jalr	-334(ra) # 800011c2 <walk>
  if (pte == 0)
    80001318:	cd11                	beqz	a0,80001334 <kvmpa+0x48>
    panic("kvmpa");
  if ((*pte & PTE_V) == 0)
    8000131a:	6108                	ld	a0,0(a0)
    8000131c:	00157793          	andi	a5,a0,1
    80001320:	c395                	beqz	a5,80001344 <kvmpa+0x58>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    80001322:	8129                	srli	a0,a0,0xa
    80001324:	0532                	slli	a0,a0,0xc
  return pa + off;
}
    80001326:	954a                	add	a0,a0,s2
    80001328:	60e2                	ld	ra,24(sp)
    8000132a:	6442                	ld	s0,16(sp)
    8000132c:	64a2                	ld	s1,8(sp)
    8000132e:	6902                	ld	s2,0(sp)
    80001330:	6105                	addi	sp,sp,32
    80001332:	8082                	ret
    panic("kvmpa");
    80001334:	00007517          	auipc	a0,0x7
    80001338:	dec50513          	addi	a0,a0,-532 # 80008120 <digits+0xe0>
    8000133c:	fffff097          	auipc	ra,0xfffff
    80001340:	20c080e7          	jalr	524(ra) # 80000548 <panic>
    panic("kvmpa");
    80001344:	00007517          	auipc	a0,0x7
    80001348:	ddc50513          	addi	a0,a0,-548 # 80008120 <digits+0xe0>
    8000134c:	fffff097          	auipc	ra,0xfffff
    80001350:	1fc080e7          	jalr	508(ra) # 80000548 <panic>

0000000080001354 <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001354:	715d                	addi	sp,sp,-80
    80001356:	e486                	sd	ra,72(sp)
    80001358:	e0a2                	sd	s0,64(sp)
    8000135a:	fc26                	sd	s1,56(sp)
    8000135c:	f84a                	sd	s2,48(sp)
    8000135e:	f44e                	sd	s3,40(sp)
    80001360:	f052                	sd	s4,32(sp)
    80001362:	ec56                	sd	s5,24(sp)
    80001364:	e85a                	sd	s6,16(sp)
    80001366:	e45e                	sd	s7,8(sp)
    80001368:	0880                	addi	s0,sp,80
    8000136a:	8aaa                	mv	s5,a0
    8000136c:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    8000136e:	777d                	lui	a4,0xfffff
    80001370:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    80001374:	167d                	addi	a2,a2,-1
    80001376:	00b609b3          	add	s3,a2,a1
    8000137a:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    8000137e:	893e                	mv	s2,a5
    80001380:	40f68a33          	sub	s4,a3,a5
    if (*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if (a == last)
      break;
    a += PGSIZE;
    80001384:	6b85                	lui	s7,0x1
    80001386:	012a04b3          	add	s1,s4,s2
    if ((pte = walk(pagetable, a, 1)) == 0)
    8000138a:	4605                	li	a2,1
    8000138c:	85ca                	mv	a1,s2
    8000138e:	8556                	mv	a0,s5
    80001390:	00000097          	auipc	ra,0x0
    80001394:	e32080e7          	jalr	-462(ra) # 800011c2 <walk>
    80001398:	c51d                	beqz	a0,800013c6 <mappages+0x72>
    if (*pte & PTE_V)
    8000139a:	611c                	ld	a5,0(a0)
    8000139c:	8b85                	andi	a5,a5,1
    8000139e:	ef81                	bnez	a5,800013b6 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800013a0:	80b1                	srli	s1,s1,0xc
    800013a2:	04aa                	slli	s1,s1,0xa
    800013a4:	0164e4b3          	or	s1,s1,s6
    800013a8:	0014e493          	ori	s1,s1,1
    800013ac:	e104                	sd	s1,0(a0)
    if (a == last)
    800013ae:	03390863          	beq	s2,s3,800013de <mappages+0x8a>
    a += PGSIZE;
    800013b2:	995e                	add	s2,s2,s7
    if ((pte = walk(pagetable, a, 1)) == 0)
    800013b4:	bfc9                	j	80001386 <mappages+0x32>
      panic("remap");
    800013b6:	00007517          	auipc	a0,0x7
    800013ba:	d7250513          	addi	a0,a0,-654 # 80008128 <digits+0xe8>
    800013be:	fffff097          	auipc	ra,0xfffff
    800013c2:	18a080e7          	jalr	394(ra) # 80000548 <panic>
      return -1;
    800013c6:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800013c8:	60a6                	ld	ra,72(sp)
    800013ca:	6406                	ld	s0,64(sp)
    800013cc:	74e2                	ld	s1,56(sp)
    800013ce:	7942                	ld	s2,48(sp)
    800013d0:	79a2                	ld	s3,40(sp)
    800013d2:	7a02                	ld	s4,32(sp)
    800013d4:	6ae2                	ld	s5,24(sp)
    800013d6:	6b42                	ld	s6,16(sp)
    800013d8:	6ba2                	ld	s7,8(sp)
    800013da:	6161                	addi	sp,sp,80
    800013dc:	8082                	ret
  return 0;
    800013de:	4501                	li	a0,0
    800013e0:	b7e5                	j	800013c8 <mappages+0x74>

00000000800013e2 <kvmmap>:
{
    800013e2:	1141                	addi	sp,sp,-16
    800013e4:	e406                	sd	ra,8(sp)
    800013e6:	e022                	sd	s0,0(sp)
    800013e8:	0800                	addi	s0,sp,16
    800013ea:	8736                	mv	a4,a3
  if (mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    800013ec:	86ae                	mv	a3,a1
    800013ee:	85aa                	mv	a1,a0
    800013f0:	00008517          	auipc	a0,0x8
    800013f4:	c2853503          	ld	a0,-984(a0) # 80009018 <kernel_pagetable>
    800013f8:	00000097          	auipc	ra,0x0
    800013fc:	f5c080e7          	jalr	-164(ra) # 80001354 <mappages>
    80001400:	e509                	bnez	a0,8000140a <kvmmap+0x28>
}
    80001402:	60a2                	ld	ra,8(sp)
    80001404:	6402                	ld	s0,0(sp)
    80001406:	0141                	addi	sp,sp,16
    80001408:	8082                	ret
    panic("kvmmap");
    8000140a:	00007517          	auipc	a0,0x7
    8000140e:	d2650513          	addi	a0,a0,-730 # 80008130 <digits+0xf0>
    80001412:	fffff097          	auipc	ra,0xfffff
    80001416:	136080e7          	jalr	310(ra) # 80000548 <panic>

000000008000141a <kvminit>:
{
    8000141a:	1101                	addi	sp,sp,-32
    8000141c:	ec06                	sd	ra,24(sp)
    8000141e:	e822                	sd	s0,16(sp)
    80001420:	e426                	sd	s1,8(sp)
    80001422:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t)kalloc();
    80001424:	fffff097          	auipc	ra,0xfffff
    80001428:	6fc080e7          	jalr	1788(ra) # 80000b20 <kalloc>
    8000142c:	00008797          	auipc	a5,0x8
    80001430:	bea7b623          	sd	a0,-1044(a5) # 80009018 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    80001434:	6605                	lui	a2,0x1
    80001436:	4581                	li	a1,0
    80001438:	00000097          	auipc	ra,0x0
    8000143c:	8d4080e7          	jalr	-1836(ra) # 80000d0c <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001440:	4699                	li	a3,6
    80001442:	6605                	lui	a2,0x1
    80001444:	100005b7          	lui	a1,0x10000
    80001448:	10000537          	lui	a0,0x10000
    8000144c:	00000097          	auipc	ra,0x0
    80001450:	f96080e7          	jalr	-106(ra) # 800013e2 <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001454:	4699                	li	a3,6
    80001456:	6605                	lui	a2,0x1
    80001458:	100015b7          	lui	a1,0x10001
    8000145c:	10001537          	lui	a0,0x10001
    80001460:	00000097          	auipc	ra,0x0
    80001464:	f82080e7          	jalr	-126(ra) # 800013e2 <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    80001468:	4699                	li	a3,6
    8000146a:	6641                	lui	a2,0x10
    8000146c:	020005b7          	lui	a1,0x2000
    80001470:	02000537          	lui	a0,0x2000
    80001474:	00000097          	auipc	ra,0x0
    80001478:	f6e080e7          	jalr	-146(ra) # 800013e2 <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    8000147c:	4699                	li	a3,6
    8000147e:	00400637          	lui	a2,0x400
    80001482:	0c0005b7          	lui	a1,0xc000
    80001486:	0c000537          	lui	a0,0xc000
    8000148a:	00000097          	auipc	ra,0x0
    8000148e:	f58080e7          	jalr	-168(ra) # 800013e2 <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext - KERNBASE, PTE_R | PTE_X);
    80001492:	00007497          	auipc	s1,0x7
    80001496:	b6e48493          	addi	s1,s1,-1170 # 80008000 <etext>
    8000149a:	46a9                	li	a3,10
    8000149c:	80007617          	auipc	a2,0x80007
    800014a0:	b6460613          	addi	a2,a2,-1180 # 8000 <_entry-0x7fff8000>
    800014a4:	4585                	li	a1,1
    800014a6:	05fe                	slli	a1,a1,0x1f
    800014a8:	852e                	mv	a0,a1
    800014aa:	00000097          	auipc	ra,0x0
    800014ae:	f38080e7          	jalr	-200(ra) # 800013e2 <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP - (uint64)etext, PTE_R | PTE_W);
    800014b2:	4699                	li	a3,6
    800014b4:	4645                	li	a2,17
    800014b6:	066e                	slli	a2,a2,0x1b
    800014b8:	8e05                	sub	a2,a2,s1
    800014ba:	85a6                	mv	a1,s1
    800014bc:	8526                	mv	a0,s1
    800014be:	00000097          	auipc	ra,0x0
    800014c2:	f24080e7          	jalr	-220(ra) # 800013e2 <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800014c6:	46a9                	li	a3,10
    800014c8:	6605                	lui	a2,0x1
    800014ca:	00006597          	auipc	a1,0x6
    800014ce:	b3658593          	addi	a1,a1,-1226 # 80007000 <_trampoline>
    800014d2:	04000537          	lui	a0,0x4000
    800014d6:	157d                	addi	a0,a0,-1
    800014d8:	0532                	slli	a0,a0,0xc
    800014da:	00000097          	auipc	ra,0x0
    800014de:	f08080e7          	jalr	-248(ra) # 800013e2 <kvmmap>
}
    800014e2:	60e2                	ld	ra,24(sp)
    800014e4:	6442                	ld	s0,16(sp)
    800014e6:	64a2                	ld	s1,8(sp)
    800014e8:	6105                	addi	sp,sp,32
    800014ea:	8082                	ret

00000000800014ec <uvmunmap>:

// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800014ec:	715d                	addi	sp,sp,-80
    800014ee:	e486                	sd	ra,72(sp)
    800014f0:	e0a2                	sd	s0,64(sp)
    800014f2:	fc26                	sd	s1,56(sp)
    800014f4:	f84a                	sd	s2,48(sp)
    800014f6:	f44e                	sd	s3,40(sp)
    800014f8:	f052                	sd	s4,32(sp)
    800014fa:	ec56                	sd	s5,24(sp)
    800014fc:	e85a                	sd	s6,16(sp)
    800014fe:	e45e                	sd	s7,8(sp)
    80001500:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if ((va % PGSIZE) != 0)
    80001502:	03459793          	slli	a5,a1,0x34
    80001506:	e795                	bnez	a5,80001532 <uvmunmap+0x46>
    80001508:	8a2a                	mv	s4,a0
    8000150a:	892e                	mv	s2,a1
    8000150c:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for (a = va; a < va + npages * PGSIZE; a += PGSIZE)
    8000150e:	0632                	slli	a2,a2,0xc
    80001510:	00b609b3          	add	s3,a2,a1
  {
    if ((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if ((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if (PTE_FLAGS(*pte) == PTE_V)
    80001514:	4b85                	li	s7,1
  for (a = va; a < va + npages * PGSIZE; a += PGSIZE)
    80001516:	6b05                	lui	s6,0x1
    80001518:	0735e863          	bltu	a1,s3,80001588 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void *)pa);
    }
    *pte = 0;
  }
}
    8000151c:	60a6                	ld	ra,72(sp)
    8000151e:	6406                	ld	s0,64(sp)
    80001520:	74e2                	ld	s1,56(sp)
    80001522:	7942                	ld	s2,48(sp)
    80001524:	79a2                	ld	s3,40(sp)
    80001526:	7a02                	ld	s4,32(sp)
    80001528:	6ae2                	ld	s5,24(sp)
    8000152a:	6b42                	ld	s6,16(sp)
    8000152c:	6ba2                	ld	s7,8(sp)
    8000152e:	6161                	addi	sp,sp,80
    80001530:	8082                	ret
    panic("uvmunmap: not aligned");
    80001532:	00007517          	auipc	a0,0x7
    80001536:	c0650513          	addi	a0,a0,-1018 # 80008138 <digits+0xf8>
    8000153a:	fffff097          	auipc	ra,0xfffff
    8000153e:	00e080e7          	jalr	14(ra) # 80000548 <panic>
      panic("uvmunmap: walk");
    80001542:	00007517          	auipc	a0,0x7
    80001546:	c0e50513          	addi	a0,a0,-1010 # 80008150 <digits+0x110>
    8000154a:	fffff097          	auipc	ra,0xfffff
    8000154e:	ffe080e7          	jalr	-2(ra) # 80000548 <panic>
      panic("uvmunmap: not mapped");
    80001552:	00007517          	auipc	a0,0x7
    80001556:	c0e50513          	addi	a0,a0,-1010 # 80008160 <digits+0x120>
    8000155a:	fffff097          	auipc	ra,0xfffff
    8000155e:	fee080e7          	jalr	-18(ra) # 80000548 <panic>
      panic("uvmunmap: not a leaf");
    80001562:	00007517          	auipc	a0,0x7
    80001566:	c1650513          	addi	a0,a0,-1002 # 80008178 <digits+0x138>
    8000156a:	fffff097          	auipc	ra,0xfffff
    8000156e:	fde080e7          	jalr	-34(ra) # 80000548 <panic>
      uint64 pa = PTE2PA(*pte);
    80001572:	8129                	srli	a0,a0,0xa
      kfree((void *)pa);
    80001574:	0532                	slli	a0,a0,0xc
    80001576:	fffff097          	auipc	ra,0xfffff
    8000157a:	4ae080e7          	jalr	1198(ra) # 80000a24 <kfree>
    *pte = 0;
    8000157e:	0004b023          	sd	zero,0(s1)
  for (a = va; a < va + npages * PGSIZE; a += PGSIZE)
    80001582:	995a                	add	s2,s2,s6
    80001584:	f9397ce3          	bgeu	s2,s3,8000151c <uvmunmap+0x30>
    if ((pte = walk(pagetable, a, 0)) == 0)
    80001588:	4601                	li	a2,0
    8000158a:	85ca                	mv	a1,s2
    8000158c:	8552                	mv	a0,s4
    8000158e:	00000097          	auipc	ra,0x0
    80001592:	c34080e7          	jalr	-972(ra) # 800011c2 <walk>
    80001596:	84aa                	mv	s1,a0
    80001598:	d54d                	beqz	a0,80001542 <uvmunmap+0x56>
    if ((*pte & PTE_V) == 0)
    8000159a:	6108                	ld	a0,0(a0)
    8000159c:	00157793          	andi	a5,a0,1
    800015a0:	dbcd                	beqz	a5,80001552 <uvmunmap+0x66>
    if (PTE_FLAGS(*pte) == PTE_V)
    800015a2:	3ff57793          	andi	a5,a0,1023
    800015a6:	fb778ee3          	beq	a5,s7,80001562 <uvmunmap+0x76>
    if (do_free)
    800015aa:	fc0a8ae3          	beqz	s5,8000157e <uvmunmap+0x92>
    800015ae:	b7d1                	j	80001572 <uvmunmap+0x86>

00000000800015b0 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800015b0:	1101                	addi	sp,sp,-32
    800015b2:	ec06                	sd	ra,24(sp)
    800015b4:	e822                	sd	s0,16(sp)
    800015b6:	e426                	sd	s1,8(sp)
    800015b8:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t)kalloc();
    800015ba:	fffff097          	auipc	ra,0xfffff
    800015be:	566080e7          	jalr	1382(ra) # 80000b20 <kalloc>
    800015c2:	84aa                	mv	s1,a0
  if (pagetable == 0)
    800015c4:	c519                	beqz	a0,800015d2 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800015c6:	6605                	lui	a2,0x1
    800015c8:	4581                	li	a1,0
    800015ca:	fffff097          	auipc	ra,0xfffff
    800015ce:	742080e7          	jalr	1858(ra) # 80000d0c <memset>
  return pagetable;
}
    800015d2:	8526                	mv	a0,s1
    800015d4:	60e2                	ld	ra,24(sp)
    800015d6:	6442                	ld	s0,16(sp)
    800015d8:	64a2                	ld	s1,8(sp)
    800015da:	6105                	addi	sp,sp,32
    800015dc:	8082                	ret

00000000800015de <uvminit>:

// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    800015de:	7179                	addi	sp,sp,-48
    800015e0:	f406                	sd	ra,40(sp)
    800015e2:	f022                	sd	s0,32(sp)
    800015e4:	ec26                	sd	s1,24(sp)
    800015e6:	e84a                	sd	s2,16(sp)
    800015e8:	e44e                	sd	s3,8(sp)
    800015ea:	e052                	sd	s4,0(sp)
    800015ec:	1800                	addi	s0,sp,48
  char *mem;

  if (sz >= PGSIZE)
    800015ee:	6785                	lui	a5,0x1
    800015f0:	04f67863          	bgeu	a2,a5,80001640 <uvminit+0x62>
    800015f4:	8a2a                	mv	s4,a0
    800015f6:	89ae                	mv	s3,a1
    800015f8:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    800015fa:	fffff097          	auipc	ra,0xfffff
    800015fe:	526080e7          	jalr	1318(ra) # 80000b20 <kalloc>
    80001602:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001604:	6605                	lui	a2,0x1
    80001606:	4581                	li	a1,0
    80001608:	fffff097          	auipc	ra,0xfffff
    8000160c:	704080e7          	jalr	1796(ra) # 80000d0c <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W | PTE_R | PTE_X | PTE_U);
    80001610:	4779                	li	a4,30
    80001612:	86ca                	mv	a3,s2
    80001614:	6605                	lui	a2,0x1
    80001616:	4581                	li	a1,0
    80001618:	8552                	mv	a0,s4
    8000161a:	00000097          	auipc	ra,0x0
    8000161e:	d3a080e7          	jalr	-710(ra) # 80001354 <mappages>
  memmove(mem, src, sz);
    80001622:	8626                	mv	a2,s1
    80001624:	85ce                	mv	a1,s3
    80001626:	854a                	mv	a0,s2
    80001628:	fffff097          	auipc	ra,0xfffff
    8000162c:	744080e7          	jalr	1860(ra) # 80000d6c <memmove>
}
    80001630:	70a2                	ld	ra,40(sp)
    80001632:	7402                	ld	s0,32(sp)
    80001634:	64e2                	ld	s1,24(sp)
    80001636:	6942                	ld	s2,16(sp)
    80001638:	69a2                	ld	s3,8(sp)
    8000163a:	6a02                	ld	s4,0(sp)
    8000163c:	6145                	addi	sp,sp,48
    8000163e:	8082                	ret
    panic("inituvm: more than a page");
    80001640:	00007517          	auipc	a0,0x7
    80001644:	b5050513          	addi	a0,a0,-1200 # 80008190 <digits+0x150>
    80001648:	fffff097          	auipc	ra,0xfffff
    8000164c:	f00080e7          	jalr	-256(ra) # 80000548 <panic>

0000000080001650 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001650:	1101                	addi	sp,sp,-32
    80001652:	ec06                	sd	ra,24(sp)
    80001654:	e822                	sd	s0,16(sp)
    80001656:	e426                	sd	s1,8(sp)
    80001658:	1000                	addi	s0,sp,32
  if (newsz >= oldsz)
    return oldsz;
    8000165a:	84ae                	mv	s1,a1
  if (newsz >= oldsz)
    8000165c:	00b67d63          	bgeu	a2,a1,80001676 <uvmdealloc+0x26>
    80001660:	84b2                	mv	s1,a2

  if (PGROUNDUP(newsz) < PGROUNDUP(oldsz))
    80001662:	6785                	lui	a5,0x1
    80001664:	17fd                	addi	a5,a5,-1
    80001666:	00f60733          	add	a4,a2,a5
    8000166a:	767d                	lui	a2,0xfffff
    8000166c:	8f71                	and	a4,a4,a2
    8000166e:	97ae                	add	a5,a5,a1
    80001670:	8ff1                	and	a5,a5,a2
    80001672:	00f76863          	bltu	a4,a5,80001682 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001676:	8526                	mv	a0,s1
    80001678:	60e2                	ld	ra,24(sp)
    8000167a:	6442                	ld	s0,16(sp)
    8000167c:	64a2                	ld	s1,8(sp)
    8000167e:	6105                	addi	sp,sp,32
    80001680:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001682:	8f99                	sub	a5,a5,a4
    80001684:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001686:	4685                	li	a3,1
    80001688:	0007861b          	sext.w	a2,a5
    8000168c:	85ba                	mv	a1,a4
    8000168e:	00000097          	auipc	ra,0x0
    80001692:	e5e080e7          	jalr	-418(ra) # 800014ec <uvmunmap>
    80001696:	b7c5                	j	80001676 <uvmdealloc+0x26>

0000000080001698 <uvmalloc>:
  if (newsz < oldsz)
    80001698:	0ab66163          	bltu	a2,a1,8000173a <uvmalloc+0xa2>
{
    8000169c:	7139                	addi	sp,sp,-64
    8000169e:	fc06                	sd	ra,56(sp)
    800016a0:	f822                	sd	s0,48(sp)
    800016a2:	f426                	sd	s1,40(sp)
    800016a4:	f04a                	sd	s2,32(sp)
    800016a6:	ec4e                	sd	s3,24(sp)
    800016a8:	e852                	sd	s4,16(sp)
    800016aa:	e456                	sd	s5,8(sp)
    800016ac:	0080                	addi	s0,sp,64
    800016ae:	8aaa                	mv	s5,a0
    800016b0:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800016b2:	6985                	lui	s3,0x1
    800016b4:	19fd                	addi	s3,s3,-1
    800016b6:	95ce                	add	a1,a1,s3
    800016b8:	79fd                	lui	s3,0xfffff
    800016ba:	0135f9b3          	and	s3,a1,s3
  for (a = oldsz; a < newsz; a += PGSIZE)
    800016be:	08c9f063          	bgeu	s3,a2,8000173e <uvmalloc+0xa6>
    800016c2:	894e                	mv	s2,s3
    mem = kalloc();
    800016c4:	fffff097          	auipc	ra,0xfffff
    800016c8:	45c080e7          	jalr	1116(ra) # 80000b20 <kalloc>
    800016cc:	84aa                	mv	s1,a0
    if (mem == 0)
    800016ce:	c51d                	beqz	a0,800016fc <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    800016d0:	6605                	lui	a2,0x1
    800016d2:	4581                	li	a1,0
    800016d4:	fffff097          	auipc	ra,0xfffff
    800016d8:	638080e7          	jalr	1592(ra) # 80000d0c <memset>
    if (mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W | PTE_X | PTE_R | PTE_U) != 0)
    800016dc:	4779                	li	a4,30
    800016de:	86a6                	mv	a3,s1
    800016e0:	6605                	lui	a2,0x1
    800016e2:	85ca                	mv	a1,s2
    800016e4:	8556                	mv	a0,s5
    800016e6:	00000097          	auipc	ra,0x0
    800016ea:	c6e080e7          	jalr	-914(ra) # 80001354 <mappages>
    800016ee:	e905                	bnez	a0,8000171e <uvmalloc+0x86>
  for (a = oldsz; a < newsz; a += PGSIZE)
    800016f0:	6785                	lui	a5,0x1
    800016f2:	993e                	add	s2,s2,a5
    800016f4:	fd4968e3          	bltu	s2,s4,800016c4 <uvmalloc+0x2c>
  return newsz;
    800016f8:	8552                	mv	a0,s4
    800016fa:	a809                	j	8000170c <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    800016fc:	864e                	mv	a2,s3
    800016fe:	85ca                	mv	a1,s2
    80001700:	8556                	mv	a0,s5
    80001702:	00000097          	auipc	ra,0x0
    80001706:	f4e080e7          	jalr	-178(ra) # 80001650 <uvmdealloc>
      return 0;
    8000170a:	4501                	li	a0,0
}
    8000170c:	70e2                	ld	ra,56(sp)
    8000170e:	7442                	ld	s0,48(sp)
    80001710:	74a2                	ld	s1,40(sp)
    80001712:	7902                	ld	s2,32(sp)
    80001714:	69e2                	ld	s3,24(sp)
    80001716:	6a42                	ld	s4,16(sp)
    80001718:	6aa2                	ld	s5,8(sp)
    8000171a:	6121                	addi	sp,sp,64
    8000171c:	8082                	ret
      kfree(mem);
    8000171e:	8526                	mv	a0,s1
    80001720:	fffff097          	auipc	ra,0xfffff
    80001724:	304080e7          	jalr	772(ra) # 80000a24 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001728:	864e                	mv	a2,s3
    8000172a:	85ca                	mv	a1,s2
    8000172c:	8556                	mv	a0,s5
    8000172e:	00000097          	auipc	ra,0x0
    80001732:	f22080e7          	jalr	-222(ra) # 80001650 <uvmdealloc>
      return 0;
    80001736:	4501                	li	a0,0
    80001738:	bfd1                	j	8000170c <uvmalloc+0x74>
    return oldsz;
    8000173a:	852e                	mv	a0,a1
}
    8000173c:	8082                	ret
  return newsz;
    8000173e:	8532                	mv	a0,a2
    80001740:	b7f1                	j	8000170c <uvmalloc+0x74>

0000000080001742 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void freewalk(pagetable_t pagetable)
{
    80001742:	7179                	addi	sp,sp,-48
    80001744:	f406                	sd	ra,40(sp)
    80001746:	f022                	sd	s0,32(sp)
    80001748:	ec26                	sd	s1,24(sp)
    8000174a:	e84a                	sd	s2,16(sp)
    8000174c:	e44e                	sd	s3,8(sp)
    8000174e:	e052                	sd	s4,0(sp)
    80001750:	1800                	addi	s0,sp,48
    80001752:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for (int i = 0; i < 512; i++)
    80001754:	84aa                	mv	s1,a0
    80001756:	6905                	lui	s2,0x1
    80001758:	992a                	add	s2,s2,a0
  {
    pte_t pte = pagetable[i];
    if ((pte & PTE_V) && (pte & (PTE_R | PTE_W | PTE_X)) == 0)
    8000175a:	4985                	li	s3,1
    8000175c:	a821                	j	80001774 <freewalk+0x32>
    {
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    8000175e:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80001760:	0532                	slli	a0,a0,0xc
    80001762:	00000097          	auipc	ra,0x0
    80001766:	fe0080e7          	jalr	-32(ra) # 80001742 <freewalk>
      pagetable[i] = 0;
    8000176a:	0004b023          	sd	zero,0(s1)
  for (int i = 0; i < 512; i++)
    8000176e:	04a1                	addi	s1,s1,8
    80001770:	03248163          	beq	s1,s2,80001792 <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001774:	6088                	ld	a0,0(s1)
    if ((pte & PTE_V) && (pte & (PTE_R | PTE_W | PTE_X)) == 0)
    80001776:	00f57793          	andi	a5,a0,15
    8000177a:	ff3782e3          	beq	a5,s3,8000175e <freewalk+0x1c>
    }
    else if (pte & PTE_V)
    8000177e:	8905                	andi	a0,a0,1
    80001780:	d57d                	beqz	a0,8000176e <freewalk+0x2c>
    {
      panic("freewalk: leaf");
    80001782:	00007517          	auipc	a0,0x7
    80001786:	a2e50513          	addi	a0,a0,-1490 # 800081b0 <digits+0x170>
    8000178a:	fffff097          	auipc	ra,0xfffff
    8000178e:	dbe080e7          	jalr	-578(ra) # 80000548 <panic>
    }
  }
  kfree((void *)pagetable);
    80001792:	8552                	mv	a0,s4
    80001794:	fffff097          	auipc	ra,0xfffff
    80001798:	290080e7          	jalr	656(ra) # 80000a24 <kfree>
}
    8000179c:	70a2                	ld	ra,40(sp)
    8000179e:	7402                	ld	s0,32(sp)
    800017a0:	64e2                	ld	s1,24(sp)
    800017a2:	6942                	ld	s2,16(sp)
    800017a4:	69a2                	ld	s3,8(sp)
    800017a6:	6a02                	ld	s4,0(sp)
    800017a8:	6145                	addi	sp,sp,48
    800017aa:	8082                	ret

00000000800017ac <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void uvmfree(pagetable_t pagetable, uint64 sz)
{
    800017ac:	1101                	addi	sp,sp,-32
    800017ae:	ec06                	sd	ra,24(sp)
    800017b0:	e822                	sd	s0,16(sp)
    800017b2:	e426                	sd	s1,8(sp)
    800017b4:	1000                	addi	s0,sp,32
    800017b6:	84aa                	mv	s1,a0
  if (sz > 0)
    800017b8:	e999                	bnez	a1,800017ce <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz) / PGSIZE, 1);
  freewalk(pagetable);
    800017ba:	8526                	mv	a0,s1
    800017bc:	00000097          	auipc	ra,0x0
    800017c0:	f86080e7          	jalr	-122(ra) # 80001742 <freewalk>
}
    800017c4:	60e2                	ld	ra,24(sp)
    800017c6:	6442                	ld	s0,16(sp)
    800017c8:	64a2                	ld	s1,8(sp)
    800017ca:	6105                	addi	sp,sp,32
    800017cc:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz) / PGSIZE, 1);
    800017ce:	6605                	lui	a2,0x1
    800017d0:	167d                	addi	a2,a2,-1
    800017d2:	962e                	add	a2,a2,a1
    800017d4:	4685                	li	a3,1
    800017d6:	8231                	srli	a2,a2,0xc
    800017d8:	4581                	li	a1,0
    800017da:	00000097          	auipc	ra,0x0
    800017de:	d12080e7          	jalr	-750(ra) # 800014ec <uvmunmap>
    800017e2:	bfe1                	j	800017ba <uvmfree+0xe>

00000000800017e4 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for (i = 0; i < sz; i += PGSIZE)
    800017e4:	c679                	beqz	a2,800018b2 <uvmcopy+0xce>
{
    800017e6:	715d                	addi	sp,sp,-80
    800017e8:	e486                	sd	ra,72(sp)
    800017ea:	e0a2                	sd	s0,64(sp)
    800017ec:	fc26                	sd	s1,56(sp)
    800017ee:	f84a                	sd	s2,48(sp)
    800017f0:	f44e                	sd	s3,40(sp)
    800017f2:	f052                	sd	s4,32(sp)
    800017f4:	ec56                	sd	s5,24(sp)
    800017f6:	e85a                	sd	s6,16(sp)
    800017f8:	e45e                	sd	s7,8(sp)
    800017fa:	0880                	addi	s0,sp,80
    800017fc:	8b2a                	mv	s6,a0
    800017fe:	8aae                	mv	s5,a1
    80001800:	8a32                	mv	s4,a2
  for (i = 0; i < sz; i += PGSIZE)
    80001802:	4981                	li	s3,0
  {
    if ((pte = walk(old, i, 0)) == 0)
    80001804:	4601                	li	a2,0
    80001806:	85ce                	mv	a1,s3
    80001808:	855a                	mv	a0,s6
    8000180a:	00000097          	auipc	ra,0x0
    8000180e:	9b8080e7          	jalr	-1608(ra) # 800011c2 <walk>
    80001812:	c531                	beqz	a0,8000185e <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if ((*pte & PTE_V) == 0)
    80001814:	6118                	ld	a4,0(a0)
    80001816:	00177793          	andi	a5,a4,1
    8000181a:	cbb1                	beqz	a5,8000186e <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000181c:	00a75593          	srli	a1,a4,0xa
    80001820:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001824:	3ff77493          	andi	s1,a4,1023
    if ((mem = kalloc()) == 0)
    80001828:	fffff097          	auipc	ra,0xfffff
    8000182c:	2f8080e7          	jalr	760(ra) # 80000b20 <kalloc>
    80001830:	892a                	mv	s2,a0
    80001832:	c939                	beqz	a0,80001888 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char *)pa, PGSIZE);
    80001834:	6605                	lui	a2,0x1
    80001836:	85de                	mv	a1,s7
    80001838:	fffff097          	auipc	ra,0xfffff
    8000183c:	534080e7          	jalr	1332(ra) # 80000d6c <memmove>
    if (mappages(new, i, PGSIZE, (uint64)mem, flags) != 0)
    80001840:	8726                	mv	a4,s1
    80001842:	86ca                	mv	a3,s2
    80001844:	6605                	lui	a2,0x1
    80001846:	85ce                	mv	a1,s3
    80001848:	8556                	mv	a0,s5
    8000184a:	00000097          	auipc	ra,0x0
    8000184e:	b0a080e7          	jalr	-1270(ra) # 80001354 <mappages>
    80001852:	e515                	bnez	a0,8000187e <uvmcopy+0x9a>
  for (i = 0; i < sz; i += PGSIZE)
    80001854:	6785                	lui	a5,0x1
    80001856:	99be                	add	s3,s3,a5
    80001858:	fb49e6e3          	bltu	s3,s4,80001804 <uvmcopy+0x20>
    8000185c:	a081                	j	8000189c <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    8000185e:	00007517          	auipc	a0,0x7
    80001862:	96250513          	addi	a0,a0,-1694 # 800081c0 <digits+0x180>
    80001866:	fffff097          	auipc	ra,0xfffff
    8000186a:	ce2080e7          	jalr	-798(ra) # 80000548 <panic>
      panic("uvmcopy: page not present");
    8000186e:	00007517          	auipc	a0,0x7
    80001872:	97250513          	addi	a0,a0,-1678 # 800081e0 <digits+0x1a0>
    80001876:	fffff097          	auipc	ra,0xfffff
    8000187a:	cd2080e7          	jalr	-814(ra) # 80000548 <panic>
    {
      kfree(mem);
    8000187e:	854a                	mv	a0,s2
    80001880:	fffff097          	auipc	ra,0xfffff
    80001884:	1a4080e7          	jalr	420(ra) # 80000a24 <kfree>
    }
  }
  return 0;

err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001888:	4685                	li	a3,1
    8000188a:	00c9d613          	srli	a2,s3,0xc
    8000188e:	4581                	li	a1,0
    80001890:	8556                	mv	a0,s5
    80001892:	00000097          	auipc	ra,0x0
    80001896:	c5a080e7          	jalr	-934(ra) # 800014ec <uvmunmap>
  return -1;
    8000189a:	557d                	li	a0,-1
}
    8000189c:	60a6                	ld	ra,72(sp)
    8000189e:	6406                	ld	s0,64(sp)
    800018a0:	74e2                	ld	s1,56(sp)
    800018a2:	7942                	ld	s2,48(sp)
    800018a4:	79a2                	ld	s3,40(sp)
    800018a6:	7a02                	ld	s4,32(sp)
    800018a8:	6ae2                	ld	s5,24(sp)
    800018aa:	6b42                	ld	s6,16(sp)
    800018ac:	6ba2                	ld	s7,8(sp)
    800018ae:	6161                	addi	sp,sp,80
    800018b0:	8082                	ret
  return 0;
    800018b2:	4501                	li	a0,0
}
    800018b4:	8082                	ret

00000000800018b6 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void uvmclear(pagetable_t pagetable, uint64 va)
{
    800018b6:	1141                	addi	sp,sp,-16
    800018b8:	e406                	sd	ra,8(sp)
    800018ba:	e022                	sd	s0,0(sp)
    800018bc:	0800                	addi	s0,sp,16
  pte_t *pte;

  pte = walk(pagetable, va, 0);
    800018be:	4601                	li	a2,0
    800018c0:	00000097          	auipc	ra,0x0
    800018c4:	902080e7          	jalr	-1790(ra) # 800011c2 <walk>
  if (pte == 0)
    800018c8:	c901                	beqz	a0,800018d8 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800018ca:	611c                	ld	a5,0(a0)
    800018cc:	9bbd                	andi	a5,a5,-17
    800018ce:	e11c                	sd	a5,0(a0)
}
    800018d0:	60a2                	ld	ra,8(sp)
    800018d2:	6402                	ld	s0,0(sp)
    800018d4:	0141                	addi	sp,sp,16
    800018d6:	8082                	ret
    panic("uvmclear");
    800018d8:	00007517          	auipc	a0,0x7
    800018dc:	92850513          	addi	a0,a0,-1752 # 80008200 <digits+0x1c0>
    800018e0:	fffff097          	auipc	ra,0xfffff
    800018e4:	c68080e7          	jalr	-920(ra) # 80000548 <panic>

00000000800018e8 <copyout>:
// Return 0 on success, -1 on error.
int copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while (len > 0)
    800018e8:	c6bd                	beqz	a3,80001956 <copyout+0x6e>
{
    800018ea:	715d                	addi	sp,sp,-80
    800018ec:	e486                	sd	ra,72(sp)
    800018ee:	e0a2                	sd	s0,64(sp)
    800018f0:	fc26                	sd	s1,56(sp)
    800018f2:	f84a                	sd	s2,48(sp)
    800018f4:	f44e                	sd	s3,40(sp)
    800018f6:	f052                	sd	s4,32(sp)
    800018f8:	ec56                	sd	s5,24(sp)
    800018fa:	e85a                	sd	s6,16(sp)
    800018fc:	e45e                	sd	s7,8(sp)
    800018fe:	e062                	sd	s8,0(sp)
    80001900:	0880                	addi	s0,sp,80
    80001902:	8b2a                	mv	s6,a0
    80001904:	8c2e                	mv	s8,a1
    80001906:	8a32                	mv	s4,a2
    80001908:	89b6                	mv	s3,a3
  {
    va0 = PGROUNDDOWN(dstva);
    8000190a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if (pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000190c:	6a85                	lui	s5,0x1
    8000190e:	a015                	j	80001932 <copyout+0x4a>
    if (n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001910:	9562                	add	a0,a0,s8
    80001912:	0004861b          	sext.w	a2,s1
    80001916:	85d2                	mv	a1,s4
    80001918:	41250533          	sub	a0,a0,s2
    8000191c:	fffff097          	auipc	ra,0xfffff
    80001920:	450080e7          	jalr	1104(ra) # 80000d6c <memmove>

    len -= n;
    80001924:	409989b3          	sub	s3,s3,s1
    src += n;
    80001928:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    8000192a:	01590c33          	add	s8,s2,s5
  while (len > 0)
    8000192e:	02098263          	beqz	s3,80001952 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001932:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001936:	85ca                	mv	a1,s2
    80001938:	855a                	mv	a0,s6
    8000193a:	00000097          	auipc	ra,0x0
    8000193e:	92e080e7          	jalr	-1746(ra) # 80001268 <walkaddr>
    if (pa0 == 0)
    80001942:	cd01                	beqz	a0,8000195a <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001944:	418904b3          	sub	s1,s2,s8
    80001948:	94d6                	add	s1,s1,s5
    if (n > len)
    8000194a:	fc99f3e3          	bgeu	s3,s1,80001910 <copyout+0x28>
    8000194e:	84ce                	mv	s1,s3
    80001950:	b7c1                	j	80001910 <copyout+0x28>
  }
  return 0;
    80001952:	4501                	li	a0,0
    80001954:	a021                	j	8000195c <copyout+0x74>
    80001956:	4501                	li	a0,0
}
    80001958:	8082                	ret
      return -1;
    8000195a:	557d                	li	a0,-1
}
    8000195c:	60a6                	ld	ra,72(sp)
    8000195e:	6406                	ld	s0,64(sp)
    80001960:	74e2                	ld	s1,56(sp)
    80001962:	7942                	ld	s2,48(sp)
    80001964:	79a2                	ld	s3,40(sp)
    80001966:	7a02                	ld	s4,32(sp)
    80001968:	6ae2                	ld	s5,24(sp)
    8000196a:	6b42                	ld	s6,16(sp)
    8000196c:	6ba2                	ld	s7,8(sp)
    8000196e:	6c02                	ld	s8,0(sp)
    80001970:	6161                	addi	sp,sp,80
    80001972:	8082                	ret

0000000080001974 <copyin>:

// Copy from user to kernel.
// Copy len bytes to dst from virtual address srcva in a given page table.
// Return 0 on success, -1 on error.
int copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
    80001974:	1141                	addi	sp,sp,-16
    80001976:	e406                	sd	ra,8(sp)
    80001978:	e022                	sd	s0,0(sp)
    8000197a:	0800                	addi	s0,sp,16
  //   len -= n;
  //   dst += n;
  //   srcva = va0 + PGSIZE;
  // }
  // return 0;
  return copyin_new(pagetable, dst, srcva, len);
    8000197c:	00005097          	auipc	ra,0x5
    80001980:	be4080e7          	jalr	-1052(ra) # 80006560 <copyin_new>
}
    80001984:	60a2                	ld	ra,8(sp)
    80001986:	6402                	ld	s0,0(sp)
    80001988:	0141                	addi	sp,sp,16
    8000198a:	8082                	ret

000000008000198c <copyinstr>:
// Copy a null-terminated string from user to kernel.
// Copy bytes to dst from virtual address srcva in a given page table,
// until a '\0', or max.
// Return 0 on success, -1 on error.
int copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
    8000198c:	1141                	addi	sp,sp,-16
    8000198e:	e406                	sd	ra,8(sp)
    80001990:	e022                	sd	s0,0(sp)
    80001992:	0800                	addi	s0,sp,16
  // {
  //   return -1;
  // }

  // Lab3
  return copyinstr_new(pagetable, dst, srcva, max);
    80001994:	00005097          	auipc	ra,0x5
    80001998:	c34080e7          	jalr	-972(ra) # 800065c8 <copyinstr_new>
}
    8000199c:	60a2                	ld	ra,8(sp)
    8000199e:	6402                	ld	s0,0(sp)
    800019a0:	0141                	addi	sp,sp,16
    800019a2:	8082                	ret

00000000800019a4 <kvmmapuser>:

// map user virtual address to kernel page table
void kvmmapuser(pagetable_t kpgtbl, pagetable_t upgtbl, uint64 start, uint64 end) {
    800019a4:	7139                	addi	sp,sp,-64
    800019a6:	fc06                	sd	ra,56(sp)
    800019a8:	f822                	sd	s0,48(sp)
    800019aa:	f426                	sd	s1,40(sp)
    800019ac:	f04a                	sd	s2,32(sp)
    800019ae:	ec4e                	sd	s3,24(sp)
    800019b0:	e852                	sd	s4,16(sp)
    800019b2:	e456                	sd	s5,8(sp)
    800019b4:	e05a                	sd	s6,0(sp)
    800019b6:	0080                	addi	s0,sp,64
  pte_t* user_pte;
  pte_t* kernel_pte;
  uint64 va;
  if (end >= PLIC) {
    800019b8:	0c0007b7          	lui	a5,0xc000
    800019bc:	06f6f563          	bgeu	a3,a5,80001a26 <kvmmapuser+0x82>
    800019c0:	8aaa                	mv	s5,a0
    800019c2:	8a2e                	mv	s4,a1
    800019c4:	8932                	mv	s2,a2
    panic("kvmmapuser: end address is too large");
  }
  if (start < end) {
    800019c6:	04d67663          	bgeu	a2,a3,80001a12 <kvmmapuser+0x6e>
    800019ca:	40c689b3          	sub	s3,a3,a2
    800019ce:	19fd                	addi	s3,s3,-1
    800019d0:	77fd                	lui	a5,0xfffff
    800019d2:	00f9f9b3          	and	s3,s3,a5
    800019d6:	6785                	lui	a5,0x1
    800019d8:	97b2                	add	a5,a5,a2
    800019da:	99be                	add	s3,s3,a5
    for (va = start; va < end; va += PGSIZE) {
    800019dc:	6b05                	lui	s6,0x1
      user_pte = walk(upgtbl, va, 0);
    800019de:	4601                	li	a2,0
    800019e0:	85ca                	mv	a1,s2
    800019e2:	8552                	mv	a0,s4
    800019e4:	fffff097          	auipc	ra,0xfffff
    800019e8:	7de080e7          	jalr	2014(ra) # 800011c2 <walk>
    800019ec:	84aa                	mv	s1,a0
      if (user_pte == 0 || (*user_pte & PTE_V) == 0) {
    800019ee:	c521                	beqz	a0,80001a36 <kvmmapuser+0x92>
    800019f0:	611c                	ld	a5,0(a0)
    800019f2:	8b85                	andi	a5,a5,1
    800019f4:	c3a9                	beqz	a5,80001a36 <kvmmapuser+0x92>
        panic("kvmmapuser: user page table walk failed");
      }
      kernel_pte = walk(kpgtbl, va, 1);
    800019f6:	4605                	li	a2,1
    800019f8:	85ca                	mv	a1,s2
    800019fa:	8556                	mv	a0,s5
    800019fc:	fffff097          	auipc	ra,0xfffff
    80001a00:	7c6080e7          	jalr	1990(ra) # 800011c2 <walk>
      if (kernel_pte == 0) {
    80001a04:	c129                	beqz	a0,80001a46 <kvmmapuser+0xa2>
        panic("kvmmapuser: kernel page table walk failed");
      }
      *kernel_pte = *user_pte;
      *kernel_pte &= ~(PTE_U | PTE_W | PTE_X);
    80001a06:	609c                	ld	a5,0(s1)
    80001a08:	9b8d                	andi	a5,a5,-29
    80001a0a:	e11c                	sd	a5,0(a0)
    for (va = start; va < end; va += PGSIZE) {
    80001a0c:	995a                	add	s2,s2,s6
    80001a0e:	fd2998e3          	bne	s3,s2,800019de <kvmmapuser+0x3a>
        panic("kvmmapuser: kernel page table walk failed");
      }
      *kernel_pte &= ~PTE_V;
    }
  }
}
    80001a12:	70e2                	ld	ra,56(sp)
    80001a14:	7442                	ld	s0,48(sp)
    80001a16:	74a2                	ld	s1,40(sp)
    80001a18:	7902                	ld	s2,32(sp)
    80001a1a:	69e2                	ld	s3,24(sp)
    80001a1c:	6a42                	ld	s4,16(sp)
    80001a1e:	6aa2                	ld	s5,8(sp)
    80001a20:	6b02                	ld	s6,0(sp)
    80001a22:	6121                	addi	sp,sp,64
    80001a24:	8082                	ret
    panic("kvmmapuser: end address is too large");
    80001a26:	00006517          	auipc	a0,0x6
    80001a2a:	7ea50513          	addi	a0,a0,2026 # 80008210 <digits+0x1d0>
    80001a2e:	fffff097          	auipc	ra,0xfffff
    80001a32:	b1a080e7          	jalr	-1254(ra) # 80000548 <panic>
        panic("kvmmapuser: user page table walk failed");
    80001a36:	00007517          	auipc	a0,0x7
    80001a3a:	80250513          	addi	a0,a0,-2046 # 80008238 <digits+0x1f8>
    80001a3e:	fffff097          	auipc	ra,0xfffff
    80001a42:	b0a080e7          	jalr	-1270(ra) # 80000548 <panic>
        panic("kvmmapuser: kernel page table walk failed");
    80001a46:	00007517          	auipc	a0,0x7
    80001a4a:	81a50513          	addi	a0,a0,-2022 # 80008260 <digits+0x220>
    80001a4e:	fffff097          	auipc	ra,0xfffff
    80001a52:	afa080e7          	jalr	-1286(ra) # 80000548 <panic>

0000000080001a56 <vmprint_helper>:

void vmprint_helper(pagetable_t pagetable, int level)
{
    80001a56:	711d                	addi	sp,sp,-96
    80001a58:	ec86                	sd	ra,88(sp)
    80001a5a:	e8a2                	sd	s0,80(sp)
    80001a5c:	e4a6                	sd	s1,72(sp)
    80001a5e:	e0ca                	sd	s2,64(sp)
    80001a60:	fc4e                	sd	s3,56(sp)
    80001a62:	f852                	sd	s4,48(sp)
    80001a64:	f456                	sd	s5,40(sp)
    80001a66:	f05a                	sd	s6,32(sp)
    80001a68:	ec5e                	sd	s7,24(sp)
    80001a6a:	e862                	sd	s8,16(sp)
    80001a6c:	e466                	sd	s9,8(sp)
    80001a6e:	e06a                	sd	s10,0(sp)
    80001a70:	1080                	addi	s0,sp,96
    80001a72:	8aae                	mv	s5,a1
  pte_t pte;
  pte_t child;
  int i;
  int j;
  for (i = 0; i < 512; ++i)
    80001a74:	8a2a                	mv	s4,a0
    80001a76:	4981                	li	s3,0
      for (j = -1; j < level; ++j)
      {
        printf("..");
      }
      child = PTE2PA(pte);
      printf("%d: pte %p pa %p\n", i, pte, child);
    80001a78:	00007c17          	auipc	s8,0x7
    80001a7c:	820c0c13          	addi	s8,s8,-2016 # 80008298 <digits+0x258>
      if ((pte & (PTE_R | PTE_W | PTE_X)) == 0)
      {
        vmprint_helper((pagetable_t)child, level + 1);
    80001a80:	00158d1b          	addiw	s10,a1,1
      for (j = -1; j < level; ++j)
    80001a84:	5cfd                	li	s9,-1
        printf("..");
    80001a86:	00007b17          	auipc	s6,0x7
    80001a8a:	80ab0b13          	addi	s6,s6,-2038 # 80008290 <digits+0x250>
  for (i = 0; i < 512; ++i)
    80001a8e:	20000b93          	li	s7,512
    80001a92:	a029                	j	80001a9c <vmprint_helper+0x46>
    80001a94:	2985                	addiw	s3,s3,1
    80001a96:	0a21                	addi	s4,s4,8
    80001a98:	05798863          	beq	s3,s7,80001ae8 <vmprint_helper+0x92>
    pte = pagetable[i];
    80001a9c:	000a3903          	ld	s2,0(s4) # fffffffffffff000 <end+0xffffffff7ffd7fe0>
    if (pte & PTE_V)
    80001aa0:	00197793          	andi	a5,s2,1
    80001aa4:	dbe5                	beqz	a5,80001a94 <vmprint_helper+0x3e>
      for (j = -1; j < level; ++j)
    80001aa6:	000acb63          	bltz	s5,80001abc <vmprint_helper+0x66>
    80001aaa:	84e6                	mv	s1,s9
        printf("..");
    80001aac:	855a                	mv	a0,s6
    80001aae:	fffff097          	auipc	ra,0xfffff
    80001ab2:	ae4080e7          	jalr	-1308(ra) # 80000592 <printf>
      for (j = -1; j < level; ++j)
    80001ab6:	2485                	addiw	s1,s1,1
    80001ab8:	fe9a9ae3          	bne	s5,s1,80001aac <vmprint_helper+0x56>
      child = PTE2PA(pte);
    80001abc:	00a95493          	srli	s1,s2,0xa
    80001ac0:	04b2                	slli	s1,s1,0xc
      printf("%d: pte %p pa %p\n", i, pte, child);
    80001ac2:	86a6                	mv	a3,s1
    80001ac4:	864a                	mv	a2,s2
    80001ac6:	85ce                	mv	a1,s3
    80001ac8:	8562                	mv	a0,s8
    80001aca:	fffff097          	auipc	ra,0xfffff
    80001ace:	ac8080e7          	jalr	-1336(ra) # 80000592 <printf>
      if ((pte & (PTE_R | PTE_W | PTE_X)) == 0)
    80001ad2:	00e97913          	andi	s2,s2,14
    80001ad6:	fa091fe3          	bnez	s2,80001a94 <vmprint_helper+0x3e>
        vmprint_helper((pagetable_t)child, level + 1);
    80001ada:	85ea                	mv	a1,s10
    80001adc:	8526                	mv	a0,s1
    80001ade:	00000097          	auipc	ra,0x0
    80001ae2:	f78080e7          	jalr	-136(ra) # 80001a56 <vmprint_helper>
    80001ae6:	b77d                	j	80001a94 <vmprint_helper+0x3e>
      }
    }
  }
}
    80001ae8:	60e6                	ld	ra,88(sp)
    80001aea:	6446                	ld	s0,80(sp)
    80001aec:	64a6                	ld	s1,72(sp)
    80001aee:	6906                	ld	s2,64(sp)
    80001af0:	79e2                	ld	s3,56(sp)
    80001af2:	7a42                	ld	s4,48(sp)
    80001af4:	7aa2                	ld	s5,40(sp)
    80001af6:	7b02                	ld	s6,32(sp)
    80001af8:	6be2                	ld	s7,24(sp)
    80001afa:	6c42                	ld	s8,16(sp)
    80001afc:	6ca2                	ld	s9,8(sp)
    80001afe:	6d02                	ld	s10,0(sp)
    80001b00:	6125                	addi	sp,sp,96
    80001b02:	8082                	ret

0000000080001b04 <vmprint>:

void vmprint(pagetable_t pagetable)
{
    80001b04:	1101                	addi	sp,sp,-32
    80001b06:	ec06                	sd	ra,24(sp)
    80001b08:	e822                	sd	s0,16(sp)
    80001b0a:	e426                	sd	s1,8(sp)
    80001b0c:	1000                	addi	s0,sp,32
    80001b0e:	84aa                	mv	s1,a0
  printf("page table %p\n", pagetable);
    80001b10:	85aa                	mv	a1,a0
    80001b12:	00006517          	auipc	a0,0x6
    80001b16:	79e50513          	addi	a0,a0,1950 # 800082b0 <digits+0x270>
    80001b1a:	fffff097          	auipc	ra,0xfffff
    80001b1e:	a78080e7          	jalr	-1416(ra) # 80000592 <printf>
  vmprint_helper(pagetable, 0);
    80001b22:	4581                	li	a1,0
    80001b24:	8526                	mv	a0,s1
    80001b26:	00000097          	auipc	ra,0x0
    80001b2a:	f30080e7          	jalr	-208(ra) # 80001a56 <vmprint_helper>
}
    80001b2e:	60e2                	ld	ra,24(sp)
    80001b30:	6442                	ld	s0,16(sp)
    80001b32:	64a2                	ld	s1,8(sp)
    80001b34:	6105                	addi	sp,sp,32
    80001b36:	8082                	ret

0000000080001b38 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80001b38:	1101                	addi	sp,sp,-32
    80001b3a:	ec06                	sd	ra,24(sp)
    80001b3c:	e822                	sd	s0,16(sp)
    80001b3e:	e426                	sd	s1,8(sp)
    80001b40:	1000                	addi	s0,sp,32
    80001b42:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001b44:	fffff097          	auipc	ra,0xfffff
    80001b48:	052080e7          	jalr	82(ra) # 80000b96 <holding>
    80001b4c:	c909                	beqz	a0,80001b5e <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    80001b4e:	749c                	ld	a5,40(s1)
    80001b50:	00978f63          	beq	a5,s1,80001b6e <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80001b54:	60e2                	ld	ra,24(sp)
    80001b56:	6442                	ld	s0,16(sp)
    80001b58:	64a2                	ld	s1,8(sp)
    80001b5a:	6105                	addi	sp,sp,32
    80001b5c:	8082                	ret
    panic("wakeup1");
    80001b5e:	00006517          	auipc	a0,0x6
    80001b62:	76250513          	addi	a0,a0,1890 # 800082c0 <digits+0x280>
    80001b66:	fffff097          	auipc	ra,0xfffff
    80001b6a:	9e2080e7          	jalr	-1566(ra) # 80000548 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    80001b6e:	4c98                	lw	a4,24(s1)
    80001b70:	4785                	li	a5,1
    80001b72:	fef711e3          	bne	a4,a5,80001b54 <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001b76:	4789                	li	a5,2
    80001b78:	cc9c                	sw	a5,24(s1)
}
    80001b7a:	bfe9                	j	80001b54 <wakeup1+0x1c>

0000000080001b7c <procinit>:
{
    80001b7c:	7179                	addi	sp,sp,-48
    80001b7e:	f406                	sd	ra,40(sp)
    80001b80:	f022                	sd	s0,32(sp)
    80001b82:	ec26                	sd	s1,24(sp)
    80001b84:	e84a                	sd	s2,16(sp)
    80001b86:	e44e                	sd	s3,8(sp)
    80001b88:	1800                	addi	s0,sp,48
  initlock(&pid_lock, "nextpid");
    80001b8a:	00006597          	auipc	a1,0x6
    80001b8e:	73e58593          	addi	a1,a1,1854 # 800082c8 <digits+0x288>
    80001b92:	00010517          	auipc	a0,0x10
    80001b96:	dce50513          	addi	a0,a0,-562 # 80011960 <pid_lock>
    80001b9a:	fffff097          	auipc	ra,0xfffff
    80001b9e:	fe6080e7          	jalr	-26(ra) # 80000b80 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ba2:	00010497          	auipc	s1,0x10
    80001ba6:	1d648493          	addi	s1,s1,470 # 80011d78 <proc>
      initlock(&p->lock, "proc");
    80001baa:	00006997          	auipc	s3,0x6
    80001bae:	72698993          	addi	s3,s3,1830 # 800082d0 <digits+0x290>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bb2:	00016917          	auipc	s2,0x16
    80001bb6:	dc690913          	addi	s2,s2,-570 # 80017978 <tickslock>
      initlock(&p->lock, "proc");
    80001bba:	85ce                	mv	a1,s3
    80001bbc:	8526                	mv	a0,s1
    80001bbe:	fffff097          	auipc	ra,0xfffff
    80001bc2:	fc2080e7          	jalr	-62(ra) # 80000b80 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bc6:	17048493          	addi	s1,s1,368
    80001bca:	ff2498e3          	bne	s1,s2,80001bba <procinit+0x3e>
  kvminithart();
    80001bce:	fffff097          	auipc	ra,0xfffff
    80001bd2:	5d0080e7          	jalr	1488(ra) # 8000119e <kvminithart>
}
    80001bd6:	70a2                	ld	ra,40(sp)
    80001bd8:	7402                	ld	s0,32(sp)
    80001bda:	64e2                	ld	s1,24(sp)
    80001bdc:	6942                	ld	s2,16(sp)
    80001bde:	69a2                	ld	s3,8(sp)
    80001be0:	6145                	addi	sp,sp,48
    80001be2:	8082                	ret

0000000080001be4 <cpuid>:
{
    80001be4:	1141                	addi	sp,sp,-16
    80001be6:	e422                	sd	s0,8(sp)
    80001be8:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001bea:	8512                	mv	a0,tp
}
    80001bec:	2501                	sext.w	a0,a0
    80001bee:	6422                	ld	s0,8(sp)
    80001bf0:	0141                	addi	sp,sp,16
    80001bf2:	8082                	ret

0000000080001bf4 <mycpu>:
mycpu(void) {
    80001bf4:	1141                	addi	sp,sp,-16
    80001bf6:	e422                	sd	s0,8(sp)
    80001bf8:	0800                	addi	s0,sp,16
    80001bfa:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001bfc:	2781                	sext.w	a5,a5
    80001bfe:	079e                	slli	a5,a5,0x7
}
    80001c00:	00010517          	auipc	a0,0x10
    80001c04:	d7850513          	addi	a0,a0,-648 # 80011978 <cpus>
    80001c08:	953e                	add	a0,a0,a5
    80001c0a:	6422                	ld	s0,8(sp)
    80001c0c:	0141                	addi	sp,sp,16
    80001c0e:	8082                	ret

0000000080001c10 <myproc>:
myproc(void) {
    80001c10:	1101                	addi	sp,sp,-32
    80001c12:	ec06                	sd	ra,24(sp)
    80001c14:	e822                	sd	s0,16(sp)
    80001c16:	e426                	sd	s1,8(sp)
    80001c18:	1000                	addi	s0,sp,32
  push_off();
    80001c1a:	fffff097          	auipc	ra,0xfffff
    80001c1e:	faa080e7          	jalr	-86(ra) # 80000bc4 <push_off>
    80001c22:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001c24:	2781                	sext.w	a5,a5
    80001c26:	079e                	slli	a5,a5,0x7
    80001c28:	00010717          	auipc	a4,0x10
    80001c2c:	d3870713          	addi	a4,a4,-712 # 80011960 <pid_lock>
    80001c30:	97ba                	add	a5,a5,a4
    80001c32:	6f84                	ld	s1,24(a5)
  pop_off();
    80001c34:	fffff097          	auipc	ra,0xfffff
    80001c38:	030080e7          	jalr	48(ra) # 80000c64 <pop_off>
}
    80001c3c:	8526                	mv	a0,s1
    80001c3e:	60e2                	ld	ra,24(sp)
    80001c40:	6442                	ld	s0,16(sp)
    80001c42:	64a2                	ld	s1,8(sp)
    80001c44:	6105                	addi	sp,sp,32
    80001c46:	8082                	ret

0000000080001c48 <forkret>:
{
    80001c48:	1141                	addi	sp,sp,-16
    80001c4a:	e406                	sd	ra,8(sp)
    80001c4c:	e022                	sd	s0,0(sp)
    80001c4e:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001c50:	00000097          	auipc	ra,0x0
    80001c54:	fc0080e7          	jalr	-64(ra) # 80001c10 <myproc>
    80001c58:	fffff097          	auipc	ra,0xfffff
    80001c5c:	06c080e7          	jalr	108(ra) # 80000cc4 <release>
  if (first) {
    80001c60:	00007797          	auipc	a5,0x7
    80001c64:	ce07a783          	lw	a5,-800(a5) # 80008940 <first.1704>
    80001c68:	eb89                	bnez	a5,80001c7a <forkret+0x32>
  usertrapret();
    80001c6a:	00001097          	auipc	ra,0x1
    80001c6e:	d38080e7          	jalr	-712(ra) # 800029a2 <usertrapret>
}
    80001c72:	60a2                	ld	ra,8(sp)
    80001c74:	6402                	ld	s0,0(sp)
    80001c76:	0141                	addi	sp,sp,16
    80001c78:	8082                	ret
    first = 0;
    80001c7a:	00007797          	auipc	a5,0x7
    80001c7e:	cc07a323          	sw	zero,-826(a5) # 80008940 <first.1704>
    fsinit(ROOTDEV);
    80001c82:	4505                	li	a0,1
    80001c84:	00002097          	auipc	ra,0x2
    80001c88:	a60080e7          	jalr	-1440(ra) # 800036e4 <fsinit>
    80001c8c:	bff9                	j	80001c6a <forkret+0x22>

0000000080001c8e <allocpid>:
allocpid() {
    80001c8e:	1101                	addi	sp,sp,-32
    80001c90:	ec06                	sd	ra,24(sp)
    80001c92:	e822                	sd	s0,16(sp)
    80001c94:	e426                	sd	s1,8(sp)
    80001c96:	e04a                	sd	s2,0(sp)
    80001c98:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001c9a:	00010917          	auipc	s2,0x10
    80001c9e:	cc690913          	addi	s2,s2,-826 # 80011960 <pid_lock>
    80001ca2:	854a                	mv	a0,s2
    80001ca4:	fffff097          	auipc	ra,0xfffff
    80001ca8:	f6c080e7          	jalr	-148(ra) # 80000c10 <acquire>
  pid = nextpid;
    80001cac:	00007797          	auipc	a5,0x7
    80001cb0:	c9878793          	addi	a5,a5,-872 # 80008944 <nextpid>
    80001cb4:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001cb6:	0014871b          	addiw	a4,s1,1
    80001cba:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001cbc:	854a                	mv	a0,s2
    80001cbe:	fffff097          	auipc	ra,0xfffff
    80001cc2:	006080e7          	jalr	6(ra) # 80000cc4 <release>
}
    80001cc6:	8526                	mv	a0,s1
    80001cc8:	60e2                	ld	ra,24(sp)
    80001cca:	6442                	ld	s0,16(sp)
    80001ccc:	64a2                	ld	s1,8(sp)
    80001cce:	6902                	ld	s2,0(sp)
    80001cd0:	6105                	addi	sp,sp,32
    80001cd2:	8082                	ret

0000000080001cd4 <proc_pagetable>:
{
    80001cd4:	1101                	addi	sp,sp,-32
    80001cd6:	ec06                	sd	ra,24(sp)
    80001cd8:	e822                	sd	s0,16(sp)
    80001cda:	e426                	sd	s1,8(sp)
    80001cdc:	e04a                	sd	s2,0(sp)
    80001cde:	1000                	addi	s0,sp,32
    80001ce0:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001ce2:	00000097          	auipc	ra,0x0
    80001ce6:	8ce080e7          	jalr	-1842(ra) # 800015b0 <uvmcreate>
    80001cea:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001cec:	c121                	beqz	a0,80001d2c <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001cee:	4729                	li	a4,10
    80001cf0:	00005697          	auipc	a3,0x5
    80001cf4:	31068693          	addi	a3,a3,784 # 80007000 <_trampoline>
    80001cf8:	6605                	lui	a2,0x1
    80001cfa:	040005b7          	lui	a1,0x4000
    80001cfe:	15fd                	addi	a1,a1,-1
    80001d00:	05b2                	slli	a1,a1,0xc
    80001d02:	fffff097          	auipc	ra,0xfffff
    80001d06:	652080e7          	jalr	1618(ra) # 80001354 <mappages>
    80001d0a:	02054863          	bltz	a0,80001d3a <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001d0e:	4719                	li	a4,6
    80001d10:	05893683          	ld	a3,88(s2)
    80001d14:	6605                	lui	a2,0x1
    80001d16:	020005b7          	lui	a1,0x2000
    80001d1a:	15fd                	addi	a1,a1,-1
    80001d1c:	05b6                	slli	a1,a1,0xd
    80001d1e:	8526                	mv	a0,s1
    80001d20:	fffff097          	auipc	ra,0xfffff
    80001d24:	634080e7          	jalr	1588(ra) # 80001354 <mappages>
    80001d28:	02054163          	bltz	a0,80001d4a <proc_pagetable+0x76>
}
    80001d2c:	8526                	mv	a0,s1
    80001d2e:	60e2                	ld	ra,24(sp)
    80001d30:	6442                	ld	s0,16(sp)
    80001d32:	64a2                	ld	s1,8(sp)
    80001d34:	6902                	ld	s2,0(sp)
    80001d36:	6105                	addi	sp,sp,32
    80001d38:	8082                	ret
    uvmfree(pagetable, 0);
    80001d3a:	4581                	li	a1,0
    80001d3c:	8526                	mv	a0,s1
    80001d3e:	00000097          	auipc	ra,0x0
    80001d42:	a6e080e7          	jalr	-1426(ra) # 800017ac <uvmfree>
    return 0;
    80001d46:	4481                	li	s1,0
    80001d48:	b7d5                	j	80001d2c <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d4a:	4681                	li	a3,0
    80001d4c:	4605                	li	a2,1
    80001d4e:	040005b7          	lui	a1,0x4000
    80001d52:	15fd                	addi	a1,a1,-1
    80001d54:	05b2                	slli	a1,a1,0xc
    80001d56:	8526                	mv	a0,s1
    80001d58:	fffff097          	auipc	ra,0xfffff
    80001d5c:	794080e7          	jalr	1940(ra) # 800014ec <uvmunmap>
    uvmfree(pagetable, 0);
    80001d60:	4581                	li	a1,0
    80001d62:	8526                	mv	a0,s1
    80001d64:	00000097          	auipc	ra,0x0
    80001d68:	a48080e7          	jalr	-1464(ra) # 800017ac <uvmfree>
    return 0;
    80001d6c:	4481                	li	s1,0
    80001d6e:	bf7d                	j	80001d2c <proc_pagetable+0x58>

0000000080001d70 <proc_freepagetable>:
{
    80001d70:	1101                	addi	sp,sp,-32
    80001d72:	ec06                	sd	ra,24(sp)
    80001d74:	e822                	sd	s0,16(sp)
    80001d76:	e426                	sd	s1,8(sp)
    80001d78:	e04a                	sd	s2,0(sp)
    80001d7a:	1000                	addi	s0,sp,32
    80001d7c:	84aa                	mv	s1,a0
    80001d7e:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d80:	4681                	li	a3,0
    80001d82:	4605                	li	a2,1
    80001d84:	040005b7          	lui	a1,0x4000
    80001d88:	15fd                	addi	a1,a1,-1
    80001d8a:	05b2                	slli	a1,a1,0xc
    80001d8c:	fffff097          	auipc	ra,0xfffff
    80001d90:	760080e7          	jalr	1888(ra) # 800014ec <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001d94:	4681                	li	a3,0
    80001d96:	4605                	li	a2,1
    80001d98:	020005b7          	lui	a1,0x2000
    80001d9c:	15fd                	addi	a1,a1,-1
    80001d9e:	05b6                	slli	a1,a1,0xd
    80001da0:	8526                	mv	a0,s1
    80001da2:	fffff097          	auipc	ra,0xfffff
    80001da6:	74a080e7          	jalr	1866(ra) # 800014ec <uvmunmap>
  uvmfree(pagetable, sz);
    80001daa:	85ca                	mv	a1,s2
    80001dac:	8526                	mv	a0,s1
    80001dae:	00000097          	auipc	ra,0x0
    80001db2:	9fe080e7          	jalr	-1538(ra) # 800017ac <uvmfree>
}
    80001db6:	60e2                	ld	ra,24(sp)
    80001db8:	6442                	ld	s0,16(sp)
    80001dba:	64a2                	ld	s1,8(sp)
    80001dbc:	6902                	ld	s2,0(sp)
    80001dbe:	6105                	addi	sp,sp,32
    80001dc0:	8082                	ret

0000000080001dc2 <freeproc>:
{
    80001dc2:	1101                	addi	sp,sp,-32
    80001dc4:	ec06                	sd	ra,24(sp)
    80001dc6:	e822                	sd	s0,16(sp)
    80001dc8:	e426                	sd	s1,8(sp)
    80001dca:	1000                	addi	s0,sp,32
    80001dcc:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001dce:	6d28                	ld	a0,88(a0)
    80001dd0:	c509                	beqz	a0,80001dda <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001dd2:	fffff097          	auipc	ra,0xfffff
    80001dd6:	c52080e7          	jalr	-942(ra) # 80000a24 <kfree>
  p->trapframe = 0;
    80001dda:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001dde:	68a8                	ld	a0,80(s1)
    80001de0:	c511                	beqz	a0,80001dec <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001de2:	64ac                	ld	a1,72(s1)
    80001de4:	00000097          	auipc	ra,0x0
    80001de8:	f8c080e7          	jalr	-116(ra) # 80001d70 <proc_freepagetable>
  uvmunmap(p->kernel_pagetable, p->kstack, 1, 1);
    80001dec:	4685                	li	a3,1
    80001dee:	4605                	li	a2,1
    80001df0:	60ac                	ld	a1,64(s1)
    80001df2:	1684b503          	ld	a0,360(s1)
    80001df6:	fffff097          	auipc	ra,0xfffff
    80001dfa:	6f6080e7          	jalr	1782(ra) # 800014ec <uvmunmap>
  p->kstack = 0;
    80001dfe:	0404b023          	sd	zero,64(s1)
  if (p->kernel_pagetable)
    80001e02:	1684b503          	ld	a0,360(s1)
    80001e06:	c509                	beqz	a0,80001e10 <freeproc+0x4e>
    free_kpagetable(p->kernel_pagetable);
    80001e08:	fffff097          	auipc	ra,0xfffff
    80001e0c:	368080e7          	jalr	872(ra) # 80001170 <free_kpagetable>
  p->pagetable = 0;
    80001e10:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001e14:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001e18:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001e1c:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001e20:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001e24:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001e28:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001e2c:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001e30:	0004ac23          	sw	zero,24(s1)
}
    80001e34:	60e2                	ld	ra,24(sp)
    80001e36:	6442                	ld	s0,16(sp)
    80001e38:	64a2                	ld	s1,8(sp)
    80001e3a:	6105                	addi	sp,sp,32
    80001e3c:	8082                	ret

0000000080001e3e <allocproc>:
{
    80001e3e:	7179                	addi	sp,sp,-48
    80001e40:	f406                	sd	ra,40(sp)
    80001e42:	f022                	sd	s0,32(sp)
    80001e44:	ec26                	sd	s1,24(sp)
    80001e46:	e84a                	sd	s2,16(sp)
    80001e48:	e44e                	sd	s3,8(sp)
    80001e4a:	1800                	addi	s0,sp,48
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e4c:	00010497          	auipc	s1,0x10
    80001e50:	f2c48493          	addi	s1,s1,-212 # 80011d78 <proc>
    80001e54:	00016917          	auipc	s2,0x16
    80001e58:	b2490913          	addi	s2,s2,-1244 # 80017978 <tickslock>
    acquire(&p->lock);
    80001e5c:	8526                	mv	a0,s1
    80001e5e:	fffff097          	auipc	ra,0xfffff
    80001e62:	db2080e7          	jalr	-590(ra) # 80000c10 <acquire>
    if(p->state == UNUSED) {
    80001e66:	4c9c                	lw	a5,24(s1)
    80001e68:	cf81                	beqz	a5,80001e80 <allocproc+0x42>
      release(&p->lock);
    80001e6a:	8526                	mv	a0,s1
    80001e6c:	fffff097          	auipc	ra,0xfffff
    80001e70:	e58080e7          	jalr	-424(ra) # 80000cc4 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e74:	17048493          	addi	s1,s1,368
    80001e78:	ff2492e3          	bne	s1,s2,80001e5c <allocproc+0x1e>
  return 0;
    80001e7c:	4481                	li	s1,0
    80001e7e:	a075                	j	80001f2a <allocproc+0xec>
  p->pid = allocpid();
    80001e80:	00000097          	auipc	ra,0x0
    80001e84:	e0e080e7          	jalr	-498(ra) # 80001c8e <allocpid>
    80001e88:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001e8a:	fffff097          	auipc	ra,0xfffff
    80001e8e:	c96080e7          	jalr	-874(ra) # 80000b20 <kalloc>
    80001e92:	892a                	mv	s2,a0
    80001e94:	eca8                	sd	a0,88(s1)
    80001e96:	c155                	beqz	a0,80001f3a <allocproc+0xfc>
  if ((p->kernel_pagetable = kpagetable_init()) == 0) {
    80001e98:	fffff097          	auipc	ra,0xfffff
    80001e9c:	1ea080e7          	jalr	490(ra) # 80001082 <kpagetable_init>
    80001ea0:	892a                	mv	s2,a0
    80001ea2:	16a4b423          	sd	a0,360(s1)
    80001ea6:	c14d                	beqz	a0,80001f48 <allocproc+0x10a>
  char *pa = kalloc();
    80001ea8:	fffff097          	auipc	ra,0xfffff
    80001eac:	c78080e7          	jalr	-904(ra) # 80000b20 <kalloc>
    80001eb0:	89aa                	mv	s3,a0
  if(pa == 0) {
    80001eb2:	c55d                	beqz	a0,80001f60 <allocproc+0x122>
  uint64 va = KSTACK(p - proc);
    80001eb4:	00010797          	auipc	a5,0x10
    80001eb8:	ec478793          	addi	a5,a5,-316 # 80011d78 <proc>
    80001ebc:	40f487b3          	sub	a5,s1,a5
    80001ec0:	8791                	srai	a5,a5,0x4
    80001ec2:	00006717          	auipc	a4,0x6
    80001ec6:	13e73703          	ld	a4,318(a4) # 80008000 <etext>
    80001eca:	02e787b3          	mul	a5,a5,a4
    80001ece:	0785                	addi	a5,a5,1
    80001ed0:	07b6                	slli	a5,a5,0xd
    80001ed2:	04000937          	lui	s2,0x4000
    80001ed6:	197d                	addi	s2,s2,-1
    80001ed8:	0932                	slli	s2,s2,0xc
    80001eda:	40f90933          	sub	s2,s2,a5
  mappages(p->kernel_pagetable, va, PGSIZE, (uint64) pa, PTE_R | PTE_W);
    80001ede:	4719                	li	a4,6
    80001ee0:	86aa                	mv	a3,a0
    80001ee2:	6605                	lui	a2,0x1
    80001ee4:	85ca                	mv	a1,s2
    80001ee6:	1684b503          	ld	a0,360(s1)
    80001eea:	fffff097          	auipc	ra,0xfffff
    80001eee:	46a080e7          	jalr	1130(ra) # 80001354 <mappages>
  p->kstack = va;
    80001ef2:	0524b023          	sd	s2,64(s1)
  p->pagetable = proc_pagetable(p);
    80001ef6:	8526                	mv	a0,s1
    80001ef8:	00000097          	auipc	ra,0x0
    80001efc:	ddc080e7          	jalr	-548(ra) # 80001cd4 <proc_pagetable>
    80001f00:	892a                	mv	s2,a0
    80001f02:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001f04:	c52d                	beqz	a0,80001f6e <allocproc+0x130>
  memset(&p->context, 0, sizeof(p->context));
    80001f06:	07000613          	li	a2,112
    80001f0a:	4581                	li	a1,0
    80001f0c:	06048513          	addi	a0,s1,96
    80001f10:	fffff097          	auipc	ra,0xfffff
    80001f14:	dfc080e7          	jalr	-516(ra) # 80000d0c <memset>
  p->context.ra = (uint64)forkret;
    80001f18:	00000797          	auipc	a5,0x0
    80001f1c:	d3078793          	addi	a5,a5,-720 # 80001c48 <forkret>
    80001f20:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001f22:	60bc                	ld	a5,64(s1)
    80001f24:	6705                	lui	a4,0x1
    80001f26:	97ba                	add	a5,a5,a4
    80001f28:	f4bc                	sd	a5,104(s1)
}
    80001f2a:	8526                	mv	a0,s1
    80001f2c:	70a2                	ld	ra,40(sp)
    80001f2e:	7402                	ld	s0,32(sp)
    80001f30:	64e2                	ld	s1,24(sp)
    80001f32:	6942                	ld	s2,16(sp)
    80001f34:	69a2                	ld	s3,8(sp)
    80001f36:	6145                	addi	sp,sp,48
    80001f38:	8082                	ret
    release(&p->lock);
    80001f3a:	8526                	mv	a0,s1
    80001f3c:	fffff097          	auipc	ra,0xfffff
    80001f40:	d88080e7          	jalr	-632(ra) # 80000cc4 <release>
    return 0;
    80001f44:	84ca                	mv	s1,s2
    80001f46:	b7d5                	j	80001f2a <allocproc+0xec>
    freeproc(p);
    80001f48:	8526                	mv	a0,s1
    80001f4a:	00000097          	auipc	ra,0x0
    80001f4e:	e78080e7          	jalr	-392(ra) # 80001dc2 <freeproc>
    release(&p->lock);
    80001f52:	8526                	mv	a0,s1
    80001f54:	fffff097          	auipc	ra,0xfffff
    80001f58:	d70080e7          	jalr	-656(ra) # 80000cc4 <release>
    return 0;
    80001f5c:	84ca                	mv	s1,s2
    80001f5e:	b7f1                	j	80001f2a <allocproc+0xec>
    release(&p->lock);
    80001f60:	8526                	mv	a0,s1
    80001f62:	fffff097          	auipc	ra,0xfffff
    80001f66:	d62080e7          	jalr	-670(ra) # 80000cc4 <release>
    return 0;
    80001f6a:	84ce                	mv	s1,s3
    80001f6c:	bf7d                	j	80001f2a <allocproc+0xec>
    freeproc(p);
    80001f6e:	8526                	mv	a0,s1
    80001f70:	00000097          	auipc	ra,0x0
    80001f74:	e52080e7          	jalr	-430(ra) # 80001dc2 <freeproc>
    release(&p->lock);
    80001f78:	8526                	mv	a0,s1
    80001f7a:	fffff097          	auipc	ra,0xfffff
    80001f7e:	d4a080e7          	jalr	-694(ra) # 80000cc4 <release>
    return 0;
    80001f82:	84ca                	mv	s1,s2
    80001f84:	b75d                	j	80001f2a <allocproc+0xec>

0000000080001f86 <userinit>:
{
    80001f86:	1101                	addi	sp,sp,-32
    80001f88:	ec06                	sd	ra,24(sp)
    80001f8a:	e822                	sd	s0,16(sp)
    80001f8c:	e426                	sd	s1,8(sp)
    80001f8e:	1000                	addi	s0,sp,32
  p = allocproc();
    80001f90:	00000097          	auipc	ra,0x0
    80001f94:	eae080e7          	jalr	-338(ra) # 80001e3e <allocproc>
    80001f98:	84aa                	mv	s1,a0
  initproc = p;
    80001f9a:	00007797          	auipc	a5,0x7
    80001f9e:	08a7b323          	sd	a0,134(a5) # 80009020 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001fa2:	03400613          	li	a2,52
    80001fa6:	00007597          	auipc	a1,0x7
    80001faa:	9aa58593          	addi	a1,a1,-1622 # 80008950 <initcode>
    80001fae:	6928                	ld	a0,80(a0)
    80001fb0:	fffff097          	auipc	ra,0xfffff
    80001fb4:	62e080e7          	jalr	1582(ra) # 800015de <uvminit>
  p->sz = PGSIZE;
    80001fb8:	6785                	lui	a5,0x1
    80001fba:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001fbc:	6cb8                	ld	a4,88(s1)
    80001fbe:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001fc2:	6cb8                	ld	a4,88(s1)
    80001fc4:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001fc6:	4641                	li	a2,16
    80001fc8:	00006597          	auipc	a1,0x6
    80001fcc:	31058593          	addi	a1,a1,784 # 800082d8 <digits+0x298>
    80001fd0:	15848513          	addi	a0,s1,344
    80001fd4:	fffff097          	auipc	ra,0xfffff
    80001fd8:	e8e080e7          	jalr	-370(ra) # 80000e62 <safestrcpy>
  p->cwd = namei("/");
    80001fdc:	00006517          	auipc	a0,0x6
    80001fe0:	30c50513          	addi	a0,a0,780 # 800082e8 <digits+0x2a8>
    80001fe4:	00002097          	auipc	ra,0x2
    80001fe8:	128080e7          	jalr	296(ra) # 8000410c <namei>
    80001fec:	14a4b823          	sd	a0,336(s1)
  kvmmapuser(p->kernel_pagetable, p->pagetable, 0, p->sz);
    80001ff0:	64b4                	ld	a3,72(s1)
    80001ff2:	4601                	li	a2,0
    80001ff4:	68ac                	ld	a1,80(s1)
    80001ff6:	1684b503          	ld	a0,360(s1)
    80001ffa:	00000097          	auipc	ra,0x0
    80001ffe:	9aa080e7          	jalr	-1622(ra) # 800019a4 <kvmmapuser>
  p->state = RUNNABLE;
    80002002:	4789                	li	a5,2
    80002004:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80002006:	8526                	mv	a0,s1
    80002008:	fffff097          	auipc	ra,0xfffff
    8000200c:	cbc080e7          	jalr	-836(ra) # 80000cc4 <release>
}
    80002010:	60e2                	ld	ra,24(sp)
    80002012:	6442                	ld	s0,16(sp)
    80002014:	64a2                	ld	s1,8(sp)
    80002016:	6105                	addi	sp,sp,32
    80002018:	8082                	ret

000000008000201a <growproc>:
{
    8000201a:	7179                	addi	sp,sp,-48
    8000201c:	f406                	sd	ra,40(sp)
    8000201e:	f022                	sd	s0,32(sp)
    80002020:	ec26                	sd	s1,24(sp)
    80002022:	e84a                	sd	s2,16(sp)
    80002024:	e44e                	sd	s3,8(sp)
    80002026:	1800                	addi	s0,sp,48
    80002028:	892a                	mv	s2,a0
  struct proc *p = myproc();
    8000202a:	00000097          	auipc	ra,0x0
    8000202e:	be6080e7          	jalr	-1050(ra) # 80001c10 <myproc>
    80002032:	84aa                	mv	s1,a0
  sz = p->sz;
    80002034:	04853983          	ld	s3,72(a0)
    80002038:	0009869b          	sext.w	a3,s3
  if(n > 0){
    8000203c:	03204963          	bgtz	s2,8000206e <growproc+0x54>
  } else if(n < 0){
    80002040:	04094863          	bltz	s2,80002090 <growproc+0x76>
  p->sz = sz;
    80002044:	1682                	slli	a3,a3,0x20
    80002046:	9281                	srli	a3,a3,0x20
    80002048:	e4b4                	sd	a3,72(s1)
  kvmmapuser(p->kernel_pagetable, p->pagetable, old_sz, p->sz);
    8000204a:	02099613          	slli	a2,s3,0x20
    8000204e:	9201                	srli	a2,a2,0x20
    80002050:	68ac                	ld	a1,80(s1)
    80002052:	1684b503          	ld	a0,360(s1)
    80002056:	00000097          	auipc	ra,0x0
    8000205a:	94e080e7          	jalr	-1714(ra) # 800019a4 <kvmmapuser>
  return 0;
    8000205e:	4501                	li	a0,0
}
    80002060:	70a2                	ld	ra,40(sp)
    80002062:	7402                	ld	s0,32(sp)
    80002064:	64e2                	ld	s1,24(sp)
    80002066:	6942                	ld	s2,16(sp)
    80002068:	69a2                	ld	s3,8(sp)
    8000206a:	6145                	addi	sp,sp,48
    8000206c:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    8000206e:	00d9063b          	addw	a2,s2,a3
    80002072:	1602                	slli	a2,a2,0x20
    80002074:	9201                	srli	a2,a2,0x20
    80002076:	02099593          	slli	a1,s3,0x20
    8000207a:	9181                	srli	a1,a1,0x20
    8000207c:	6928                	ld	a0,80(a0)
    8000207e:	fffff097          	auipc	ra,0xfffff
    80002082:	61a080e7          	jalr	1562(ra) # 80001698 <uvmalloc>
    80002086:	0005069b          	sext.w	a3,a0
    8000208a:	fecd                	bnez	a3,80002044 <growproc+0x2a>
      return -1;
    8000208c:	557d                	li	a0,-1
    8000208e:	bfc9                	j	80002060 <growproc+0x46>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80002090:	00d9063b          	addw	a2,s2,a3
    80002094:	1602                	slli	a2,a2,0x20
    80002096:	9201                	srli	a2,a2,0x20
    80002098:	02099593          	slli	a1,s3,0x20
    8000209c:	9181                	srli	a1,a1,0x20
    8000209e:	6928                	ld	a0,80(a0)
    800020a0:	fffff097          	auipc	ra,0xfffff
    800020a4:	5b0080e7          	jalr	1456(ra) # 80001650 <uvmdealloc>
    800020a8:	0005069b          	sext.w	a3,a0
    800020ac:	bf61                	j	80002044 <growproc+0x2a>

00000000800020ae <fork>:
{
    800020ae:	7179                	addi	sp,sp,-48
    800020b0:	f406                	sd	ra,40(sp)
    800020b2:	f022                	sd	s0,32(sp)
    800020b4:	ec26                	sd	s1,24(sp)
    800020b6:	e84a                	sd	s2,16(sp)
    800020b8:	e44e                	sd	s3,8(sp)
    800020ba:	e052                	sd	s4,0(sp)
    800020bc:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800020be:	00000097          	auipc	ra,0x0
    800020c2:	b52080e7          	jalr	-1198(ra) # 80001c10 <myproc>
    800020c6:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    800020c8:	00000097          	auipc	ra,0x0
    800020cc:	d76080e7          	jalr	-650(ra) # 80001e3e <allocproc>
    800020d0:	cd6d                	beqz	a0,800021ca <fork+0x11c>
    800020d2:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    800020d4:	04893603          	ld	a2,72(s2) # 4000048 <_entry-0x7bffffb8>
    800020d8:	692c                	ld	a1,80(a0)
    800020da:	05093503          	ld	a0,80(s2)
    800020de:	fffff097          	auipc	ra,0xfffff
    800020e2:	706080e7          	jalr	1798(ra) # 800017e4 <uvmcopy>
    800020e6:	04054863          	bltz	a0,80002136 <fork+0x88>
  np->sz = p->sz;
    800020ea:	04893783          	ld	a5,72(s2)
    800020ee:	04f9b423          	sd	a5,72(s3)
  np->parent = p;
    800020f2:	0329b023          	sd	s2,32(s3)
  *(np->trapframe) = *(p->trapframe);
    800020f6:	05893683          	ld	a3,88(s2)
    800020fa:	87b6                	mv	a5,a3
    800020fc:	0589b703          	ld	a4,88(s3)
    80002100:	12068693          	addi	a3,a3,288
    80002104:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80002108:	6788                	ld	a0,8(a5)
    8000210a:	6b8c                	ld	a1,16(a5)
    8000210c:	6f90                	ld	a2,24(a5)
    8000210e:	01073023          	sd	a6,0(a4)
    80002112:	e708                	sd	a0,8(a4)
    80002114:	eb0c                	sd	a1,16(a4)
    80002116:	ef10                	sd	a2,24(a4)
    80002118:	02078793          	addi	a5,a5,32
    8000211c:	02070713          	addi	a4,a4,32
    80002120:	fed792e3          	bne	a5,a3,80002104 <fork+0x56>
  np->trapframe->a0 = 0;
    80002124:	0589b783          	ld	a5,88(s3)
    80002128:	0607b823          	sd	zero,112(a5)
    8000212c:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80002130:	15000a13          	li	s4,336
    80002134:	a03d                	j	80002162 <fork+0xb4>
    freeproc(np);
    80002136:	854e                	mv	a0,s3
    80002138:	00000097          	auipc	ra,0x0
    8000213c:	c8a080e7          	jalr	-886(ra) # 80001dc2 <freeproc>
    release(&np->lock);
    80002140:	854e                	mv	a0,s3
    80002142:	fffff097          	auipc	ra,0xfffff
    80002146:	b82080e7          	jalr	-1150(ra) # 80000cc4 <release>
    return -1;
    8000214a:	54fd                	li	s1,-1
    8000214c:	a0b5                	j	800021b8 <fork+0x10a>
      np->ofile[i] = filedup(p->ofile[i]);
    8000214e:	00002097          	auipc	ra,0x2
    80002152:	64a080e7          	jalr	1610(ra) # 80004798 <filedup>
    80002156:	009987b3          	add	a5,s3,s1
    8000215a:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    8000215c:	04a1                	addi	s1,s1,8
    8000215e:	01448763          	beq	s1,s4,8000216c <fork+0xbe>
    if(p->ofile[i])
    80002162:	009907b3          	add	a5,s2,s1
    80002166:	6388                	ld	a0,0(a5)
    80002168:	f17d                	bnez	a0,8000214e <fork+0xa0>
    8000216a:	bfcd                	j	8000215c <fork+0xae>
  np->cwd = idup(p->cwd);
    8000216c:	15093503          	ld	a0,336(s2)
    80002170:	00001097          	auipc	ra,0x1
    80002174:	7ae080e7          	jalr	1966(ra) # 8000391e <idup>
    80002178:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    8000217c:	4641                	li	a2,16
    8000217e:	15890593          	addi	a1,s2,344
    80002182:	15898513          	addi	a0,s3,344
    80002186:	fffff097          	auipc	ra,0xfffff
    8000218a:	cdc080e7          	jalr	-804(ra) # 80000e62 <safestrcpy>
  pid = np->pid;
    8000218e:	0389a483          	lw	s1,56(s3)
  kvmmapuser(np->kernel_pagetable, np->pagetable, 0, np->sz);
    80002192:	0489b683          	ld	a3,72(s3)
    80002196:	4601                	li	a2,0
    80002198:	0509b583          	ld	a1,80(s3)
    8000219c:	1689b503          	ld	a0,360(s3)
    800021a0:	00000097          	auipc	ra,0x0
    800021a4:	804080e7          	jalr	-2044(ra) # 800019a4 <kvmmapuser>
  np->state = RUNNABLE;
    800021a8:	4789                	li	a5,2
    800021aa:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    800021ae:	854e                	mv	a0,s3
    800021b0:	fffff097          	auipc	ra,0xfffff
    800021b4:	b14080e7          	jalr	-1260(ra) # 80000cc4 <release>
}
    800021b8:	8526                	mv	a0,s1
    800021ba:	70a2                	ld	ra,40(sp)
    800021bc:	7402                	ld	s0,32(sp)
    800021be:	64e2                	ld	s1,24(sp)
    800021c0:	6942                	ld	s2,16(sp)
    800021c2:	69a2                	ld	s3,8(sp)
    800021c4:	6a02                	ld	s4,0(sp)
    800021c6:	6145                	addi	sp,sp,48
    800021c8:	8082                	ret
    return -1;
    800021ca:	54fd                	li	s1,-1
    800021cc:	b7f5                	j	800021b8 <fork+0x10a>

00000000800021ce <reparent>:
{
    800021ce:	7179                	addi	sp,sp,-48
    800021d0:	f406                	sd	ra,40(sp)
    800021d2:	f022                	sd	s0,32(sp)
    800021d4:	ec26                	sd	s1,24(sp)
    800021d6:	e84a                	sd	s2,16(sp)
    800021d8:	e44e                	sd	s3,8(sp)
    800021da:	e052                	sd	s4,0(sp)
    800021dc:	1800                	addi	s0,sp,48
    800021de:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800021e0:	00010497          	auipc	s1,0x10
    800021e4:	b9848493          	addi	s1,s1,-1128 # 80011d78 <proc>
      pp->parent = initproc;
    800021e8:	00007a17          	auipc	s4,0x7
    800021ec:	e38a0a13          	addi	s4,s4,-456 # 80009020 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800021f0:	00015997          	auipc	s3,0x15
    800021f4:	78898993          	addi	s3,s3,1928 # 80017978 <tickslock>
    800021f8:	a029                	j	80002202 <reparent+0x34>
    800021fa:	17048493          	addi	s1,s1,368
    800021fe:	03348363          	beq	s1,s3,80002224 <reparent+0x56>
    if(pp->parent == p){
    80002202:	709c                	ld	a5,32(s1)
    80002204:	ff279be3          	bne	a5,s2,800021fa <reparent+0x2c>
      acquire(&pp->lock);
    80002208:	8526                	mv	a0,s1
    8000220a:	fffff097          	auipc	ra,0xfffff
    8000220e:	a06080e7          	jalr	-1530(ra) # 80000c10 <acquire>
      pp->parent = initproc;
    80002212:	000a3783          	ld	a5,0(s4)
    80002216:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80002218:	8526                	mv	a0,s1
    8000221a:	fffff097          	auipc	ra,0xfffff
    8000221e:	aaa080e7          	jalr	-1366(ra) # 80000cc4 <release>
    80002222:	bfe1                	j	800021fa <reparent+0x2c>
}
    80002224:	70a2                	ld	ra,40(sp)
    80002226:	7402                	ld	s0,32(sp)
    80002228:	64e2                	ld	s1,24(sp)
    8000222a:	6942                	ld	s2,16(sp)
    8000222c:	69a2                	ld	s3,8(sp)
    8000222e:	6a02                	ld	s4,0(sp)
    80002230:	6145                	addi	sp,sp,48
    80002232:	8082                	ret

0000000080002234 <scheduler>:
{
    80002234:	715d                	addi	sp,sp,-80
    80002236:	e486                	sd	ra,72(sp)
    80002238:	e0a2                	sd	s0,64(sp)
    8000223a:	fc26                	sd	s1,56(sp)
    8000223c:	f84a                	sd	s2,48(sp)
    8000223e:	f44e                	sd	s3,40(sp)
    80002240:	f052                	sd	s4,32(sp)
    80002242:	ec56                	sd	s5,24(sp)
    80002244:	e85a                	sd	s6,16(sp)
    80002246:	e45e                	sd	s7,8(sp)
    80002248:	e062                	sd	s8,0(sp)
    8000224a:	0880                	addi	s0,sp,80
    8000224c:	8792                	mv	a5,tp
  int id = r_tp();
    8000224e:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002250:	00779b13          	slli	s6,a5,0x7
    80002254:	0000f717          	auipc	a4,0xf
    80002258:	70c70713          	addi	a4,a4,1804 # 80011960 <pid_lock>
    8000225c:	975a                	add	a4,a4,s6
    8000225e:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80002262:	0000f717          	auipc	a4,0xf
    80002266:	71e70713          	addi	a4,a4,1822 # 80011980 <cpus+0x8>
    8000226a:	9b3a                	add	s6,s6,a4
        c->proc = p;
    8000226c:	079e                	slli	a5,a5,0x7
    8000226e:	0000fa97          	auipc	s5,0xf
    80002272:	6f2a8a93          	addi	s5,s5,1778 # 80011960 <pid_lock>
    80002276:	9abe                	add	s5,s5,a5
        w_satp(MAKE_SATP(p->kernel_pagetable));
    80002278:	5a7d                	li	s4,-1
    8000227a:	1a7e                	slli	s4,s4,0x3f
        w_satp(MAKE_SATP(kernel_pagetable));
    8000227c:	00007b97          	auipc	s7,0x7
    80002280:	d9cb8b93          	addi	s7,s7,-612 # 80009018 <kernel_pagetable>
    80002284:	a8ad                	j	800022fe <scheduler+0xca>
        p->state = RUNNING;
    80002286:	478d                	li	a5,3
    80002288:	cc9c                	sw	a5,24(s1)
        c->proc = p;
    8000228a:	009abc23          	sd	s1,24(s5)
        w_satp(MAKE_SATP(p->kernel_pagetable));
    8000228e:	1684b783          	ld	a5,360(s1)
    80002292:	83b1                	srli	a5,a5,0xc
    80002294:	0147e7b3          	or	a5,a5,s4
  asm volatile("csrw satp, %0" : : "r" (x));
    80002298:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    8000229c:	12000073          	sfence.vma
        swtch(&c->context, &p->context);
    800022a0:	06048593          	addi	a1,s1,96
    800022a4:	855a                	mv	a0,s6
    800022a6:	00000097          	auipc	ra,0x0
    800022aa:	652080e7          	jalr	1618(ra) # 800028f8 <swtch>
        c->proc = 0;
    800022ae:	000abc23          	sd	zero,24(s5)
        w_satp(MAKE_SATP(kernel_pagetable));
    800022b2:	000bb783          	ld	a5,0(s7)
    800022b6:	83b1                	srli	a5,a5,0xc
    800022b8:	0147e7b3          	or	a5,a5,s4
  asm volatile("csrw satp, %0" : : "r" (x));
    800022bc:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    800022c0:	12000073          	sfence.vma
        found = 1;
    800022c4:	4c05                	li	s8,1
      release(&p->lock);
    800022c6:	8526                	mv	a0,s1
    800022c8:	fffff097          	auipc	ra,0xfffff
    800022cc:	9fc080e7          	jalr	-1540(ra) # 80000cc4 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    800022d0:	17048493          	addi	s1,s1,368
    800022d4:	01248b63          	beq	s1,s2,800022ea <scheduler+0xb6>
      acquire(&p->lock);
    800022d8:	8526                	mv	a0,s1
    800022da:	fffff097          	auipc	ra,0xfffff
    800022de:	936080e7          	jalr	-1738(ra) # 80000c10 <acquire>
      if(p->state == RUNNABLE) {
    800022e2:	4c9c                	lw	a5,24(s1)
    800022e4:	ff3791e3          	bne	a5,s3,800022c6 <scheduler+0x92>
    800022e8:	bf79                	j	80002286 <scheduler+0x52>
    if(found == 0) {
    800022ea:	000c1a63          	bnez	s8,800022fe <scheduler+0xca>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800022ee:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800022f2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800022f6:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    800022fa:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800022fe:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002302:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002306:	10079073          	csrw	sstatus,a5
    int found = 0;
    8000230a:	4c01                	li	s8,0
    for(p = proc; p < &proc[NPROC]; p++) {
    8000230c:	00010497          	auipc	s1,0x10
    80002310:	a6c48493          	addi	s1,s1,-1428 # 80011d78 <proc>
      if(p->state == RUNNABLE) {
    80002314:	4989                	li	s3,2
    for(p = proc; p < &proc[NPROC]; p++) {
    80002316:	00015917          	auipc	s2,0x15
    8000231a:	66290913          	addi	s2,s2,1634 # 80017978 <tickslock>
    8000231e:	bf6d                	j	800022d8 <scheduler+0xa4>

0000000080002320 <sched>:
{
    80002320:	7179                	addi	sp,sp,-48
    80002322:	f406                	sd	ra,40(sp)
    80002324:	f022                	sd	s0,32(sp)
    80002326:	ec26                	sd	s1,24(sp)
    80002328:	e84a                	sd	s2,16(sp)
    8000232a:	e44e                	sd	s3,8(sp)
    8000232c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000232e:	00000097          	auipc	ra,0x0
    80002332:	8e2080e7          	jalr	-1822(ra) # 80001c10 <myproc>
    80002336:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002338:	fffff097          	auipc	ra,0xfffff
    8000233c:	85e080e7          	jalr	-1954(ra) # 80000b96 <holding>
    80002340:	c93d                	beqz	a0,800023b6 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002342:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002344:	2781                	sext.w	a5,a5
    80002346:	079e                	slli	a5,a5,0x7
    80002348:	0000f717          	auipc	a4,0xf
    8000234c:	61870713          	addi	a4,a4,1560 # 80011960 <pid_lock>
    80002350:	97ba                	add	a5,a5,a4
    80002352:	0907a703          	lw	a4,144(a5)
    80002356:	4785                	li	a5,1
    80002358:	06f71763          	bne	a4,a5,800023c6 <sched+0xa6>
  if(p->state == RUNNING)
    8000235c:	4c98                	lw	a4,24(s1)
    8000235e:	478d                	li	a5,3
    80002360:	06f70b63          	beq	a4,a5,800023d6 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002364:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002368:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000236a:	efb5                	bnez	a5,800023e6 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000236c:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000236e:	0000f917          	auipc	s2,0xf
    80002372:	5f290913          	addi	s2,s2,1522 # 80011960 <pid_lock>
    80002376:	2781                	sext.w	a5,a5
    80002378:	079e                	slli	a5,a5,0x7
    8000237a:	97ca                	add	a5,a5,s2
    8000237c:	0947a983          	lw	s3,148(a5)
    80002380:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002382:	2781                	sext.w	a5,a5
    80002384:	079e                	slli	a5,a5,0x7
    80002386:	0000f597          	auipc	a1,0xf
    8000238a:	5fa58593          	addi	a1,a1,1530 # 80011980 <cpus+0x8>
    8000238e:	95be                	add	a1,a1,a5
    80002390:	06048513          	addi	a0,s1,96
    80002394:	00000097          	auipc	ra,0x0
    80002398:	564080e7          	jalr	1380(ra) # 800028f8 <swtch>
    8000239c:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000239e:	2781                	sext.w	a5,a5
    800023a0:	079e                	slli	a5,a5,0x7
    800023a2:	97ca                	add	a5,a5,s2
    800023a4:	0937aa23          	sw	s3,148(a5)
}
    800023a8:	70a2                	ld	ra,40(sp)
    800023aa:	7402                	ld	s0,32(sp)
    800023ac:	64e2                	ld	s1,24(sp)
    800023ae:	6942                	ld	s2,16(sp)
    800023b0:	69a2                	ld	s3,8(sp)
    800023b2:	6145                	addi	sp,sp,48
    800023b4:	8082                	ret
    panic("sched p->lock");
    800023b6:	00006517          	auipc	a0,0x6
    800023ba:	f3a50513          	addi	a0,a0,-198 # 800082f0 <digits+0x2b0>
    800023be:	ffffe097          	auipc	ra,0xffffe
    800023c2:	18a080e7          	jalr	394(ra) # 80000548 <panic>
    panic("sched locks");
    800023c6:	00006517          	auipc	a0,0x6
    800023ca:	f3a50513          	addi	a0,a0,-198 # 80008300 <digits+0x2c0>
    800023ce:	ffffe097          	auipc	ra,0xffffe
    800023d2:	17a080e7          	jalr	378(ra) # 80000548 <panic>
    panic("sched running");
    800023d6:	00006517          	auipc	a0,0x6
    800023da:	f3a50513          	addi	a0,a0,-198 # 80008310 <digits+0x2d0>
    800023de:	ffffe097          	auipc	ra,0xffffe
    800023e2:	16a080e7          	jalr	362(ra) # 80000548 <panic>
    panic("sched interruptible");
    800023e6:	00006517          	auipc	a0,0x6
    800023ea:	f3a50513          	addi	a0,a0,-198 # 80008320 <digits+0x2e0>
    800023ee:	ffffe097          	auipc	ra,0xffffe
    800023f2:	15a080e7          	jalr	346(ra) # 80000548 <panic>

00000000800023f6 <exit>:
{
    800023f6:	7179                	addi	sp,sp,-48
    800023f8:	f406                	sd	ra,40(sp)
    800023fa:	f022                	sd	s0,32(sp)
    800023fc:	ec26                	sd	s1,24(sp)
    800023fe:	e84a                	sd	s2,16(sp)
    80002400:	e44e                	sd	s3,8(sp)
    80002402:	e052                	sd	s4,0(sp)
    80002404:	1800                	addi	s0,sp,48
    80002406:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002408:	00000097          	auipc	ra,0x0
    8000240c:	808080e7          	jalr	-2040(ra) # 80001c10 <myproc>
    80002410:	89aa                	mv	s3,a0
  if(p == initproc)
    80002412:	00007797          	auipc	a5,0x7
    80002416:	c0e7b783          	ld	a5,-1010(a5) # 80009020 <initproc>
    8000241a:	0d050493          	addi	s1,a0,208
    8000241e:	15050913          	addi	s2,a0,336
    80002422:	02a79363          	bne	a5,a0,80002448 <exit+0x52>
    panic("init exiting");
    80002426:	00006517          	auipc	a0,0x6
    8000242a:	f1250513          	addi	a0,a0,-238 # 80008338 <digits+0x2f8>
    8000242e:	ffffe097          	auipc	ra,0xffffe
    80002432:	11a080e7          	jalr	282(ra) # 80000548 <panic>
      fileclose(f);
    80002436:	00002097          	auipc	ra,0x2
    8000243a:	3b4080e7          	jalr	948(ra) # 800047ea <fileclose>
      p->ofile[fd] = 0;
    8000243e:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002442:	04a1                	addi	s1,s1,8
    80002444:	01248563          	beq	s1,s2,8000244e <exit+0x58>
    if(p->ofile[fd]){
    80002448:	6088                	ld	a0,0(s1)
    8000244a:	f575                	bnez	a0,80002436 <exit+0x40>
    8000244c:	bfdd                	j	80002442 <exit+0x4c>
  begin_op();
    8000244e:	00002097          	auipc	ra,0x2
    80002452:	eca080e7          	jalr	-310(ra) # 80004318 <begin_op>
  iput(p->cwd);
    80002456:	1509b503          	ld	a0,336(s3)
    8000245a:	00001097          	auipc	ra,0x1
    8000245e:	6bc080e7          	jalr	1724(ra) # 80003b16 <iput>
  end_op();
    80002462:	00002097          	auipc	ra,0x2
    80002466:	f36080e7          	jalr	-202(ra) # 80004398 <end_op>
  p->cwd = 0;
    8000246a:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    8000246e:	00007497          	auipc	s1,0x7
    80002472:	bb248493          	addi	s1,s1,-1102 # 80009020 <initproc>
    80002476:	6088                	ld	a0,0(s1)
    80002478:	ffffe097          	auipc	ra,0xffffe
    8000247c:	798080e7          	jalr	1944(ra) # 80000c10 <acquire>
  wakeup1(initproc);
    80002480:	6088                	ld	a0,0(s1)
    80002482:	fffff097          	auipc	ra,0xfffff
    80002486:	6b6080e7          	jalr	1718(ra) # 80001b38 <wakeup1>
  release(&initproc->lock);
    8000248a:	6088                	ld	a0,0(s1)
    8000248c:	fffff097          	auipc	ra,0xfffff
    80002490:	838080e7          	jalr	-1992(ra) # 80000cc4 <release>
  acquire(&p->lock);
    80002494:	854e                	mv	a0,s3
    80002496:	ffffe097          	auipc	ra,0xffffe
    8000249a:	77a080e7          	jalr	1914(ra) # 80000c10 <acquire>
  struct proc *original_parent = p->parent;
    8000249e:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    800024a2:	854e                	mv	a0,s3
    800024a4:	fffff097          	auipc	ra,0xfffff
    800024a8:	820080e7          	jalr	-2016(ra) # 80000cc4 <release>
  acquire(&original_parent->lock);
    800024ac:	8526                	mv	a0,s1
    800024ae:	ffffe097          	auipc	ra,0xffffe
    800024b2:	762080e7          	jalr	1890(ra) # 80000c10 <acquire>
  acquire(&p->lock);
    800024b6:	854e                	mv	a0,s3
    800024b8:	ffffe097          	auipc	ra,0xffffe
    800024bc:	758080e7          	jalr	1880(ra) # 80000c10 <acquire>
  reparent(p);
    800024c0:	854e                	mv	a0,s3
    800024c2:	00000097          	auipc	ra,0x0
    800024c6:	d0c080e7          	jalr	-756(ra) # 800021ce <reparent>
  wakeup1(original_parent);
    800024ca:	8526                	mv	a0,s1
    800024cc:	fffff097          	auipc	ra,0xfffff
    800024d0:	66c080e7          	jalr	1644(ra) # 80001b38 <wakeup1>
  p->xstate = status;
    800024d4:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    800024d8:	4791                	li	a5,4
    800024da:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    800024de:	8526                	mv	a0,s1
    800024e0:	ffffe097          	auipc	ra,0xffffe
    800024e4:	7e4080e7          	jalr	2020(ra) # 80000cc4 <release>
  sched();
    800024e8:	00000097          	auipc	ra,0x0
    800024ec:	e38080e7          	jalr	-456(ra) # 80002320 <sched>
  panic("zombie exit");
    800024f0:	00006517          	auipc	a0,0x6
    800024f4:	e5850513          	addi	a0,a0,-424 # 80008348 <digits+0x308>
    800024f8:	ffffe097          	auipc	ra,0xffffe
    800024fc:	050080e7          	jalr	80(ra) # 80000548 <panic>

0000000080002500 <yield>:
{
    80002500:	1101                	addi	sp,sp,-32
    80002502:	ec06                	sd	ra,24(sp)
    80002504:	e822                	sd	s0,16(sp)
    80002506:	e426                	sd	s1,8(sp)
    80002508:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000250a:	fffff097          	auipc	ra,0xfffff
    8000250e:	706080e7          	jalr	1798(ra) # 80001c10 <myproc>
    80002512:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002514:	ffffe097          	auipc	ra,0xffffe
    80002518:	6fc080e7          	jalr	1788(ra) # 80000c10 <acquire>
  p->state = RUNNABLE;
    8000251c:	4789                	li	a5,2
    8000251e:	cc9c                	sw	a5,24(s1)
  sched();
    80002520:	00000097          	auipc	ra,0x0
    80002524:	e00080e7          	jalr	-512(ra) # 80002320 <sched>
  release(&p->lock);
    80002528:	8526                	mv	a0,s1
    8000252a:	ffffe097          	auipc	ra,0xffffe
    8000252e:	79a080e7          	jalr	1946(ra) # 80000cc4 <release>
}
    80002532:	60e2                	ld	ra,24(sp)
    80002534:	6442                	ld	s0,16(sp)
    80002536:	64a2                	ld	s1,8(sp)
    80002538:	6105                	addi	sp,sp,32
    8000253a:	8082                	ret

000000008000253c <sleep>:
{
    8000253c:	7179                	addi	sp,sp,-48
    8000253e:	f406                	sd	ra,40(sp)
    80002540:	f022                	sd	s0,32(sp)
    80002542:	ec26                	sd	s1,24(sp)
    80002544:	e84a                	sd	s2,16(sp)
    80002546:	e44e                	sd	s3,8(sp)
    80002548:	1800                	addi	s0,sp,48
    8000254a:	89aa                	mv	s3,a0
    8000254c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000254e:	fffff097          	auipc	ra,0xfffff
    80002552:	6c2080e7          	jalr	1730(ra) # 80001c10 <myproc>
    80002556:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    80002558:	05250663          	beq	a0,s2,800025a4 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    8000255c:	ffffe097          	auipc	ra,0xffffe
    80002560:	6b4080e7          	jalr	1716(ra) # 80000c10 <acquire>
    release(lk);
    80002564:	854a                	mv	a0,s2
    80002566:	ffffe097          	auipc	ra,0xffffe
    8000256a:	75e080e7          	jalr	1886(ra) # 80000cc4 <release>
  p->chan = chan;
    8000256e:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    80002572:	4785                	li	a5,1
    80002574:	cc9c                	sw	a5,24(s1)
  sched();
    80002576:	00000097          	auipc	ra,0x0
    8000257a:	daa080e7          	jalr	-598(ra) # 80002320 <sched>
  p->chan = 0;
    8000257e:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    80002582:	8526                	mv	a0,s1
    80002584:	ffffe097          	auipc	ra,0xffffe
    80002588:	740080e7          	jalr	1856(ra) # 80000cc4 <release>
    acquire(lk);
    8000258c:	854a                	mv	a0,s2
    8000258e:	ffffe097          	auipc	ra,0xffffe
    80002592:	682080e7          	jalr	1666(ra) # 80000c10 <acquire>
}
    80002596:	70a2                	ld	ra,40(sp)
    80002598:	7402                	ld	s0,32(sp)
    8000259a:	64e2                	ld	s1,24(sp)
    8000259c:	6942                	ld	s2,16(sp)
    8000259e:	69a2                	ld	s3,8(sp)
    800025a0:	6145                	addi	sp,sp,48
    800025a2:	8082                	ret
  p->chan = chan;
    800025a4:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    800025a8:	4785                	li	a5,1
    800025aa:	cd1c                	sw	a5,24(a0)
  sched();
    800025ac:	00000097          	auipc	ra,0x0
    800025b0:	d74080e7          	jalr	-652(ra) # 80002320 <sched>
  p->chan = 0;
    800025b4:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    800025b8:	bff9                	j	80002596 <sleep+0x5a>

00000000800025ba <wait>:
{
    800025ba:	715d                	addi	sp,sp,-80
    800025bc:	e486                	sd	ra,72(sp)
    800025be:	e0a2                	sd	s0,64(sp)
    800025c0:	fc26                	sd	s1,56(sp)
    800025c2:	f84a                	sd	s2,48(sp)
    800025c4:	f44e                	sd	s3,40(sp)
    800025c6:	f052                	sd	s4,32(sp)
    800025c8:	ec56                	sd	s5,24(sp)
    800025ca:	e85a                	sd	s6,16(sp)
    800025cc:	e45e                	sd	s7,8(sp)
    800025ce:	e062                	sd	s8,0(sp)
    800025d0:	0880                	addi	s0,sp,80
    800025d2:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800025d4:	fffff097          	auipc	ra,0xfffff
    800025d8:	63c080e7          	jalr	1596(ra) # 80001c10 <myproc>
    800025dc:	892a                	mv	s2,a0
  acquire(&p->lock);
    800025de:	8c2a                	mv	s8,a0
    800025e0:	ffffe097          	auipc	ra,0xffffe
    800025e4:	630080e7          	jalr	1584(ra) # 80000c10 <acquire>
    havekids = 0;
    800025e8:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800025ea:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    800025ec:	00015997          	auipc	s3,0x15
    800025f0:	38c98993          	addi	s3,s3,908 # 80017978 <tickslock>
        havekids = 1;
    800025f4:	4a85                	li	s5,1
    havekids = 0;
    800025f6:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800025f8:	0000f497          	auipc	s1,0xf
    800025fc:	78048493          	addi	s1,s1,1920 # 80011d78 <proc>
    80002600:	a08d                	j	80002662 <wait+0xa8>
          pid = np->pid;
    80002602:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002606:	000b0e63          	beqz	s6,80002622 <wait+0x68>
    8000260a:	4691                	li	a3,4
    8000260c:	03448613          	addi	a2,s1,52
    80002610:	85da                	mv	a1,s6
    80002612:	05093503          	ld	a0,80(s2)
    80002616:	fffff097          	auipc	ra,0xfffff
    8000261a:	2d2080e7          	jalr	722(ra) # 800018e8 <copyout>
    8000261e:	02054263          	bltz	a0,80002642 <wait+0x88>
          freeproc(np);
    80002622:	8526                	mv	a0,s1
    80002624:	fffff097          	auipc	ra,0xfffff
    80002628:	79e080e7          	jalr	1950(ra) # 80001dc2 <freeproc>
          release(&np->lock);
    8000262c:	8526                	mv	a0,s1
    8000262e:	ffffe097          	auipc	ra,0xffffe
    80002632:	696080e7          	jalr	1686(ra) # 80000cc4 <release>
          release(&p->lock);
    80002636:	854a                	mv	a0,s2
    80002638:	ffffe097          	auipc	ra,0xffffe
    8000263c:	68c080e7          	jalr	1676(ra) # 80000cc4 <release>
          return pid;
    80002640:	a8a9                	j	8000269a <wait+0xe0>
            release(&np->lock);
    80002642:	8526                	mv	a0,s1
    80002644:	ffffe097          	auipc	ra,0xffffe
    80002648:	680080e7          	jalr	1664(ra) # 80000cc4 <release>
            release(&p->lock);
    8000264c:	854a                	mv	a0,s2
    8000264e:	ffffe097          	auipc	ra,0xffffe
    80002652:	676080e7          	jalr	1654(ra) # 80000cc4 <release>
            return -1;
    80002656:	59fd                	li	s3,-1
    80002658:	a089                	j	8000269a <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    8000265a:	17048493          	addi	s1,s1,368
    8000265e:	03348463          	beq	s1,s3,80002686 <wait+0xcc>
      if(np->parent == p){
    80002662:	709c                	ld	a5,32(s1)
    80002664:	ff279be3          	bne	a5,s2,8000265a <wait+0xa0>
        acquire(&np->lock);
    80002668:	8526                	mv	a0,s1
    8000266a:	ffffe097          	auipc	ra,0xffffe
    8000266e:	5a6080e7          	jalr	1446(ra) # 80000c10 <acquire>
        if(np->state == ZOMBIE){
    80002672:	4c9c                	lw	a5,24(s1)
    80002674:	f94787e3          	beq	a5,s4,80002602 <wait+0x48>
        release(&np->lock);
    80002678:	8526                	mv	a0,s1
    8000267a:	ffffe097          	auipc	ra,0xffffe
    8000267e:	64a080e7          	jalr	1610(ra) # 80000cc4 <release>
        havekids = 1;
    80002682:	8756                	mv	a4,s5
    80002684:	bfd9                	j	8000265a <wait+0xa0>
    if(!havekids || p->killed){
    80002686:	c701                	beqz	a4,8000268e <wait+0xd4>
    80002688:	03092783          	lw	a5,48(s2)
    8000268c:	c785                	beqz	a5,800026b4 <wait+0xfa>
      release(&p->lock);
    8000268e:	854a                	mv	a0,s2
    80002690:	ffffe097          	auipc	ra,0xffffe
    80002694:	634080e7          	jalr	1588(ra) # 80000cc4 <release>
      return -1;
    80002698:	59fd                	li	s3,-1
}
    8000269a:	854e                	mv	a0,s3
    8000269c:	60a6                	ld	ra,72(sp)
    8000269e:	6406                	ld	s0,64(sp)
    800026a0:	74e2                	ld	s1,56(sp)
    800026a2:	7942                	ld	s2,48(sp)
    800026a4:	79a2                	ld	s3,40(sp)
    800026a6:	7a02                	ld	s4,32(sp)
    800026a8:	6ae2                	ld	s5,24(sp)
    800026aa:	6b42                	ld	s6,16(sp)
    800026ac:	6ba2                	ld	s7,8(sp)
    800026ae:	6c02                	ld	s8,0(sp)
    800026b0:	6161                	addi	sp,sp,80
    800026b2:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    800026b4:	85e2                	mv	a1,s8
    800026b6:	854a                	mv	a0,s2
    800026b8:	00000097          	auipc	ra,0x0
    800026bc:	e84080e7          	jalr	-380(ra) # 8000253c <sleep>
    havekids = 0;
    800026c0:	bf1d                	j	800025f6 <wait+0x3c>

00000000800026c2 <wakeup>:
{
    800026c2:	7139                	addi	sp,sp,-64
    800026c4:	fc06                	sd	ra,56(sp)
    800026c6:	f822                	sd	s0,48(sp)
    800026c8:	f426                	sd	s1,40(sp)
    800026ca:	f04a                	sd	s2,32(sp)
    800026cc:	ec4e                	sd	s3,24(sp)
    800026ce:	e852                	sd	s4,16(sp)
    800026d0:	e456                	sd	s5,8(sp)
    800026d2:	0080                	addi	s0,sp,64
    800026d4:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    800026d6:	0000f497          	auipc	s1,0xf
    800026da:	6a248493          	addi	s1,s1,1698 # 80011d78 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    800026de:	4985                	li	s3,1
      p->state = RUNNABLE;
    800026e0:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    800026e2:	00015917          	auipc	s2,0x15
    800026e6:	29690913          	addi	s2,s2,662 # 80017978 <tickslock>
    800026ea:	a821                	j	80002702 <wakeup+0x40>
      p->state = RUNNABLE;
    800026ec:	0154ac23          	sw	s5,24(s1)
    release(&p->lock);
    800026f0:	8526                	mv	a0,s1
    800026f2:	ffffe097          	auipc	ra,0xffffe
    800026f6:	5d2080e7          	jalr	1490(ra) # 80000cc4 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800026fa:	17048493          	addi	s1,s1,368
    800026fe:	01248e63          	beq	s1,s2,8000271a <wakeup+0x58>
    acquire(&p->lock);
    80002702:	8526                	mv	a0,s1
    80002704:	ffffe097          	auipc	ra,0xffffe
    80002708:	50c080e7          	jalr	1292(ra) # 80000c10 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    8000270c:	4c9c                	lw	a5,24(s1)
    8000270e:	ff3791e3          	bne	a5,s3,800026f0 <wakeup+0x2e>
    80002712:	749c                	ld	a5,40(s1)
    80002714:	fd479ee3          	bne	a5,s4,800026f0 <wakeup+0x2e>
    80002718:	bfd1                	j	800026ec <wakeup+0x2a>
}
    8000271a:	70e2                	ld	ra,56(sp)
    8000271c:	7442                	ld	s0,48(sp)
    8000271e:	74a2                	ld	s1,40(sp)
    80002720:	7902                	ld	s2,32(sp)
    80002722:	69e2                	ld	s3,24(sp)
    80002724:	6a42                	ld	s4,16(sp)
    80002726:	6aa2                	ld	s5,8(sp)
    80002728:	6121                	addi	sp,sp,64
    8000272a:	8082                	ret

000000008000272c <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000272c:	7179                	addi	sp,sp,-48
    8000272e:	f406                	sd	ra,40(sp)
    80002730:	f022                	sd	s0,32(sp)
    80002732:	ec26                	sd	s1,24(sp)
    80002734:	e84a                	sd	s2,16(sp)
    80002736:	e44e                	sd	s3,8(sp)
    80002738:	1800                	addi	s0,sp,48
    8000273a:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000273c:	0000f497          	auipc	s1,0xf
    80002740:	63c48493          	addi	s1,s1,1596 # 80011d78 <proc>
    80002744:	00015997          	auipc	s3,0x15
    80002748:	23498993          	addi	s3,s3,564 # 80017978 <tickslock>
    acquire(&p->lock);
    8000274c:	8526                	mv	a0,s1
    8000274e:	ffffe097          	auipc	ra,0xffffe
    80002752:	4c2080e7          	jalr	1218(ra) # 80000c10 <acquire>
    if(p->pid == pid){
    80002756:	5c9c                	lw	a5,56(s1)
    80002758:	01278d63          	beq	a5,s2,80002772 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000275c:	8526                	mv	a0,s1
    8000275e:	ffffe097          	auipc	ra,0xffffe
    80002762:	566080e7          	jalr	1382(ra) # 80000cc4 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002766:	17048493          	addi	s1,s1,368
    8000276a:	ff3491e3          	bne	s1,s3,8000274c <kill+0x20>
  }
  return -1;
    8000276e:	557d                	li	a0,-1
    80002770:	a829                	j	8000278a <kill+0x5e>
      p->killed = 1;
    80002772:	4785                	li	a5,1
    80002774:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    80002776:	4c98                	lw	a4,24(s1)
    80002778:	4785                	li	a5,1
    8000277a:	00f70f63          	beq	a4,a5,80002798 <kill+0x6c>
      release(&p->lock);
    8000277e:	8526                	mv	a0,s1
    80002780:	ffffe097          	auipc	ra,0xffffe
    80002784:	544080e7          	jalr	1348(ra) # 80000cc4 <release>
      return 0;
    80002788:	4501                	li	a0,0
}
    8000278a:	70a2                	ld	ra,40(sp)
    8000278c:	7402                	ld	s0,32(sp)
    8000278e:	64e2                	ld	s1,24(sp)
    80002790:	6942                	ld	s2,16(sp)
    80002792:	69a2                	ld	s3,8(sp)
    80002794:	6145                	addi	sp,sp,48
    80002796:	8082                	ret
        p->state = RUNNABLE;
    80002798:	4789                	li	a5,2
    8000279a:	cc9c                	sw	a5,24(s1)
    8000279c:	b7cd                	j	8000277e <kill+0x52>

000000008000279e <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000279e:	7179                	addi	sp,sp,-48
    800027a0:	f406                	sd	ra,40(sp)
    800027a2:	f022                	sd	s0,32(sp)
    800027a4:	ec26                	sd	s1,24(sp)
    800027a6:	e84a                	sd	s2,16(sp)
    800027a8:	e44e                	sd	s3,8(sp)
    800027aa:	e052                	sd	s4,0(sp)
    800027ac:	1800                	addi	s0,sp,48
    800027ae:	84aa                	mv	s1,a0
    800027b0:	892e                	mv	s2,a1
    800027b2:	89b2                	mv	s3,a2
    800027b4:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800027b6:	fffff097          	auipc	ra,0xfffff
    800027ba:	45a080e7          	jalr	1114(ra) # 80001c10 <myproc>
  if(user_dst){
    800027be:	c08d                	beqz	s1,800027e0 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800027c0:	86d2                	mv	a3,s4
    800027c2:	864e                	mv	a2,s3
    800027c4:	85ca                	mv	a1,s2
    800027c6:	6928                	ld	a0,80(a0)
    800027c8:	fffff097          	auipc	ra,0xfffff
    800027cc:	120080e7          	jalr	288(ra) # 800018e8 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800027d0:	70a2                	ld	ra,40(sp)
    800027d2:	7402                	ld	s0,32(sp)
    800027d4:	64e2                	ld	s1,24(sp)
    800027d6:	6942                	ld	s2,16(sp)
    800027d8:	69a2                	ld	s3,8(sp)
    800027da:	6a02                	ld	s4,0(sp)
    800027dc:	6145                	addi	sp,sp,48
    800027de:	8082                	ret
    memmove((char *)dst, src, len);
    800027e0:	000a061b          	sext.w	a2,s4
    800027e4:	85ce                	mv	a1,s3
    800027e6:	854a                	mv	a0,s2
    800027e8:	ffffe097          	auipc	ra,0xffffe
    800027ec:	584080e7          	jalr	1412(ra) # 80000d6c <memmove>
    return 0;
    800027f0:	8526                	mv	a0,s1
    800027f2:	bff9                	j	800027d0 <either_copyout+0x32>

00000000800027f4 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800027f4:	7179                	addi	sp,sp,-48
    800027f6:	f406                	sd	ra,40(sp)
    800027f8:	f022                	sd	s0,32(sp)
    800027fa:	ec26                	sd	s1,24(sp)
    800027fc:	e84a                	sd	s2,16(sp)
    800027fe:	e44e                	sd	s3,8(sp)
    80002800:	e052                	sd	s4,0(sp)
    80002802:	1800                	addi	s0,sp,48
    80002804:	892a                	mv	s2,a0
    80002806:	84ae                	mv	s1,a1
    80002808:	89b2                	mv	s3,a2
    8000280a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000280c:	fffff097          	auipc	ra,0xfffff
    80002810:	404080e7          	jalr	1028(ra) # 80001c10 <myproc>
  if(user_src){
    80002814:	c08d                	beqz	s1,80002836 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002816:	86d2                	mv	a3,s4
    80002818:	864e                	mv	a2,s3
    8000281a:	85ca                	mv	a1,s2
    8000281c:	6928                	ld	a0,80(a0)
    8000281e:	fffff097          	auipc	ra,0xfffff
    80002822:	156080e7          	jalr	342(ra) # 80001974 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002826:	70a2                	ld	ra,40(sp)
    80002828:	7402                	ld	s0,32(sp)
    8000282a:	64e2                	ld	s1,24(sp)
    8000282c:	6942                	ld	s2,16(sp)
    8000282e:	69a2                	ld	s3,8(sp)
    80002830:	6a02                	ld	s4,0(sp)
    80002832:	6145                	addi	sp,sp,48
    80002834:	8082                	ret
    memmove(dst, (char*)src, len);
    80002836:	000a061b          	sext.w	a2,s4
    8000283a:	85ce                	mv	a1,s3
    8000283c:	854a                	mv	a0,s2
    8000283e:	ffffe097          	auipc	ra,0xffffe
    80002842:	52e080e7          	jalr	1326(ra) # 80000d6c <memmove>
    return 0;
    80002846:	8526                	mv	a0,s1
    80002848:	bff9                	j	80002826 <either_copyin+0x32>

000000008000284a <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000284a:	715d                	addi	sp,sp,-80
    8000284c:	e486                	sd	ra,72(sp)
    8000284e:	e0a2                	sd	s0,64(sp)
    80002850:	fc26                	sd	s1,56(sp)
    80002852:	f84a                	sd	s2,48(sp)
    80002854:	f44e                	sd	s3,40(sp)
    80002856:	f052                	sd	s4,32(sp)
    80002858:	ec56                	sd	s5,24(sp)
    8000285a:	e85a                	sd	s6,16(sp)
    8000285c:	e45e                	sd	s7,8(sp)
    8000285e:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002860:	00006517          	auipc	a0,0x6
    80002864:	86850513          	addi	a0,a0,-1944 # 800080c8 <digits+0x88>
    80002868:	ffffe097          	auipc	ra,0xffffe
    8000286c:	d2a080e7          	jalr	-726(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002870:	0000f497          	auipc	s1,0xf
    80002874:	66048493          	addi	s1,s1,1632 # 80011ed0 <proc+0x158>
    80002878:	00015917          	auipc	s2,0x15
    8000287c:	25890913          	addi	s2,s2,600 # 80017ad0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002880:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    80002882:	00006997          	auipc	s3,0x6
    80002886:	ad698993          	addi	s3,s3,-1322 # 80008358 <digits+0x318>
    printf("%d %s %s", p->pid, state, p->name);
    8000288a:	00006a97          	auipc	s5,0x6
    8000288e:	ad6a8a93          	addi	s5,s5,-1322 # 80008360 <digits+0x320>
    printf("\n");
    80002892:	00006a17          	auipc	s4,0x6
    80002896:	836a0a13          	addi	s4,s4,-1994 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000289a:	00006b97          	auipc	s7,0x6
    8000289e:	afeb8b93          	addi	s7,s7,-1282 # 80008398 <states.1744>
    800028a2:	a00d                	j	800028c4 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800028a4:	ee06a583          	lw	a1,-288(a3)
    800028a8:	8556                	mv	a0,s5
    800028aa:	ffffe097          	auipc	ra,0xffffe
    800028ae:	ce8080e7          	jalr	-792(ra) # 80000592 <printf>
    printf("\n");
    800028b2:	8552                	mv	a0,s4
    800028b4:	ffffe097          	auipc	ra,0xffffe
    800028b8:	cde080e7          	jalr	-802(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800028bc:	17048493          	addi	s1,s1,368
    800028c0:	03248163          	beq	s1,s2,800028e2 <procdump+0x98>
    if(p->state == UNUSED)
    800028c4:	86a6                	mv	a3,s1
    800028c6:	ec04a783          	lw	a5,-320(s1)
    800028ca:	dbed                	beqz	a5,800028bc <procdump+0x72>
      state = "???";
    800028cc:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028ce:	fcfb6be3          	bltu	s6,a5,800028a4 <procdump+0x5a>
    800028d2:	1782                	slli	a5,a5,0x20
    800028d4:	9381                	srli	a5,a5,0x20
    800028d6:	078e                	slli	a5,a5,0x3
    800028d8:	97de                	add	a5,a5,s7
    800028da:	6390                	ld	a2,0(a5)
    800028dc:	f661                	bnez	a2,800028a4 <procdump+0x5a>
      state = "???";
    800028de:	864e                	mv	a2,s3
    800028e0:	b7d1                	j	800028a4 <procdump+0x5a>
  }
}
    800028e2:	60a6                	ld	ra,72(sp)
    800028e4:	6406                	ld	s0,64(sp)
    800028e6:	74e2                	ld	s1,56(sp)
    800028e8:	7942                	ld	s2,48(sp)
    800028ea:	79a2                	ld	s3,40(sp)
    800028ec:	7a02                	ld	s4,32(sp)
    800028ee:	6ae2                	ld	s5,24(sp)
    800028f0:	6b42                	ld	s6,16(sp)
    800028f2:	6ba2                	ld	s7,8(sp)
    800028f4:	6161                	addi	sp,sp,80
    800028f6:	8082                	ret

00000000800028f8 <swtch>:
    800028f8:	00153023          	sd	ra,0(a0)
    800028fc:	00253423          	sd	sp,8(a0)
    80002900:	e900                	sd	s0,16(a0)
    80002902:	ed04                	sd	s1,24(a0)
    80002904:	03253023          	sd	s2,32(a0)
    80002908:	03353423          	sd	s3,40(a0)
    8000290c:	03453823          	sd	s4,48(a0)
    80002910:	03553c23          	sd	s5,56(a0)
    80002914:	05653023          	sd	s6,64(a0)
    80002918:	05753423          	sd	s7,72(a0)
    8000291c:	05853823          	sd	s8,80(a0)
    80002920:	05953c23          	sd	s9,88(a0)
    80002924:	07a53023          	sd	s10,96(a0)
    80002928:	07b53423          	sd	s11,104(a0)
    8000292c:	0005b083          	ld	ra,0(a1)
    80002930:	0085b103          	ld	sp,8(a1)
    80002934:	6980                	ld	s0,16(a1)
    80002936:	6d84                	ld	s1,24(a1)
    80002938:	0205b903          	ld	s2,32(a1)
    8000293c:	0285b983          	ld	s3,40(a1)
    80002940:	0305ba03          	ld	s4,48(a1)
    80002944:	0385ba83          	ld	s5,56(a1)
    80002948:	0405bb03          	ld	s6,64(a1)
    8000294c:	0485bb83          	ld	s7,72(a1)
    80002950:	0505bc03          	ld	s8,80(a1)
    80002954:	0585bc83          	ld	s9,88(a1)
    80002958:	0605bd03          	ld	s10,96(a1)
    8000295c:	0685bd83          	ld	s11,104(a1)
    80002960:	8082                	ret

0000000080002962 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002962:	1141                	addi	sp,sp,-16
    80002964:	e406                	sd	ra,8(sp)
    80002966:	e022                	sd	s0,0(sp)
    80002968:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000296a:	00006597          	auipc	a1,0x6
    8000296e:	a5658593          	addi	a1,a1,-1450 # 800083c0 <states.1744+0x28>
    80002972:	00015517          	auipc	a0,0x15
    80002976:	00650513          	addi	a0,a0,6 # 80017978 <tickslock>
    8000297a:	ffffe097          	auipc	ra,0xffffe
    8000297e:	206080e7          	jalr	518(ra) # 80000b80 <initlock>
}
    80002982:	60a2                	ld	ra,8(sp)
    80002984:	6402                	ld	s0,0(sp)
    80002986:	0141                	addi	sp,sp,16
    80002988:	8082                	ret

000000008000298a <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000298a:	1141                	addi	sp,sp,-16
    8000298c:	e422                	sd	s0,8(sp)
    8000298e:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002990:	00003797          	auipc	a5,0x3
    80002994:	4f078793          	addi	a5,a5,1264 # 80005e80 <kernelvec>
    80002998:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000299c:	6422                	ld	s0,8(sp)
    8000299e:	0141                	addi	sp,sp,16
    800029a0:	8082                	ret

00000000800029a2 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800029a2:	1141                	addi	sp,sp,-16
    800029a4:	e406                	sd	ra,8(sp)
    800029a6:	e022                	sd	s0,0(sp)
    800029a8:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800029aa:	fffff097          	auipc	ra,0xfffff
    800029ae:	266080e7          	jalr	614(ra) # 80001c10 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029b2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800029b6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029b8:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800029bc:	00004617          	auipc	a2,0x4
    800029c0:	64460613          	addi	a2,a2,1604 # 80007000 <_trampoline>
    800029c4:	00004697          	auipc	a3,0x4
    800029c8:	63c68693          	addi	a3,a3,1596 # 80007000 <_trampoline>
    800029cc:	8e91                	sub	a3,a3,a2
    800029ce:	040007b7          	lui	a5,0x4000
    800029d2:	17fd                	addi	a5,a5,-1
    800029d4:	07b2                	slli	a5,a5,0xc
    800029d6:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029d8:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800029dc:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800029de:	180026f3          	csrr	a3,satp
    800029e2:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800029e4:	6d38                	ld	a4,88(a0)
    800029e6:	6134                	ld	a3,64(a0)
    800029e8:	6585                	lui	a1,0x1
    800029ea:	96ae                	add	a3,a3,a1
    800029ec:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800029ee:	6d38                	ld	a4,88(a0)
    800029f0:	00000697          	auipc	a3,0x0
    800029f4:	13868693          	addi	a3,a3,312 # 80002b28 <usertrap>
    800029f8:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800029fa:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800029fc:	8692                	mv	a3,tp
    800029fe:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a00:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002a04:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002a08:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a0c:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002a10:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a12:	6f18                	ld	a4,24(a4)
    80002a14:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002a18:	692c                	ld	a1,80(a0)
    80002a1a:	81b1                	srli	a1,a1,0xc
  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  // call userret() with TRAPFRAME and satp as arguments.
  // set 
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002a1c:	00004717          	auipc	a4,0x4
    80002a20:	67470713          	addi	a4,a4,1652 # 80007090 <userret>
    80002a24:	8f11                	sub	a4,a4,a2
    80002a26:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002a28:	577d                	li	a4,-1
    80002a2a:	177e                	slli	a4,a4,0x3f
    80002a2c:	8dd9                	or	a1,a1,a4
    80002a2e:	02000537          	lui	a0,0x2000
    80002a32:	157d                	addi	a0,a0,-1
    80002a34:	0536                	slli	a0,a0,0xd
    80002a36:	9782                	jalr	a5
}
    80002a38:	60a2                	ld	ra,8(sp)
    80002a3a:	6402                	ld	s0,0(sp)
    80002a3c:	0141                	addi	sp,sp,16
    80002a3e:	8082                	ret

0000000080002a40 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002a40:	1101                	addi	sp,sp,-32
    80002a42:	ec06                	sd	ra,24(sp)
    80002a44:	e822                	sd	s0,16(sp)
    80002a46:	e426                	sd	s1,8(sp)
    80002a48:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002a4a:	00015497          	auipc	s1,0x15
    80002a4e:	f2e48493          	addi	s1,s1,-210 # 80017978 <tickslock>
    80002a52:	8526                	mv	a0,s1
    80002a54:	ffffe097          	auipc	ra,0xffffe
    80002a58:	1bc080e7          	jalr	444(ra) # 80000c10 <acquire>
  ticks++;
    80002a5c:	00006517          	auipc	a0,0x6
    80002a60:	5cc50513          	addi	a0,a0,1484 # 80009028 <ticks>
    80002a64:	411c                	lw	a5,0(a0)
    80002a66:	2785                	addiw	a5,a5,1
    80002a68:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002a6a:	00000097          	auipc	ra,0x0
    80002a6e:	c58080e7          	jalr	-936(ra) # 800026c2 <wakeup>
  release(&tickslock);
    80002a72:	8526                	mv	a0,s1
    80002a74:	ffffe097          	auipc	ra,0xffffe
    80002a78:	250080e7          	jalr	592(ra) # 80000cc4 <release>
}
    80002a7c:	60e2                	ld	ra,24(sp)
    80002a7e:	6442                	ld	s0,16(sp)
    80002a80:	64a2                	ld	s1,8(sp)
    80002a82:	6105                	addi	sp,sp,32
    80002a84:	8082                	ret

0000000080002a86 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002a86:	1101                	addi	sp,sp,-32
    80002a88:	ec06                	sd	ra,24(sp)
    80002a8a:	e822                	sd	s0,16(sp)
    80002a8c:	e426                	sd	s1,8(sp)
    80002a8e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a90:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002a94:	00074d63          	bltz	a4,80002aae <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002a98:	57fd                	li	a5,-1
    80002a9a:	17fe                	slli	a5,a5,0x3f
    80002a9c:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002a9e:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002aa0:	06f70363          	beq	a4,a5,80002b06 <devintr+0x80>
  }
}
    80002aa4:	60e2                	ld	ra,24(sp)
    80002aa6:	6442                	ld	s0,16(sp)
    80002aa8:	64a2                	ld	s1,8(sp)
    80002aaa:	6105                	addi	sp,sp,32
    80002aac:	8082                	ret
     (scause & 0xff) == 9){
    80002aae:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002ab2:	46a5                	li	a3,9
    80002ab4:	fed792e3          	bne	a5,a3,80002a98 <devintr+0x12>
    int irq = plic_claim();
    80002ab8:	00003097          	auipc	ra,0x3
    80002abc:	4d0080e7          	jalr	1232(ra) # 80005f88 <plic_claim>
    80002ac0:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002ac2:	47a9                	li	a5,10
    80002ac4:	02f50763          	beq	a0,a5,80002af2 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002ac8:	4785                	li	a5,1
    80002aca:	02f50963          	beq	a0,a5,80002afc <devintr+0x76>
    return 1;
    80002ace:	4505                	li	a0,1
    } else if(irq){
    80002ad0:	d8f1                	beqz	s1,80002aa4 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002ad2:	85a6                	mv	a1,s1
    80002ad4:	00006517          	auipc	a0,0x6
    80002ad8:	8f450513          	addi	a0,a0,-1804 # 800083c8 <states.1744+0x30>
    80002adc:	ffffe097          	auipc	ra,0xffffe
    80002ae0:	ab6080e7          	jalr	-1354(ra) # 80000592 <printf>
      plic_complete(irq);
    80002ae4:	8526                	mv	a0,s1
    80002ae6:	00003097          	auipc	ra,0x3
    80002aea:	4c6080e7          	jalr	1222(ra) # 80005fac <plic_complete>
    return 1;
    80002aee:	4505                	li	a0,1
    80002af0:	bf55                	j	80002aa4 <devintr+0x1e>
      uartintr();
    80002af2:	ffffe097          	auipc	ra,0xffffe
    80002af6:	ee2080e7          	jalr	-286(ra) # 800009d4 <uartintr>
    80002afa:	b7ed                	j	80002ae4 <devintr+0x5e>
      virtio_disk_intr();
    80002afc:	00004097          	auipc	ra,0x4
    80002b00:	94a080e7          	jalr	-1718(ra) # 80006446 <virtio_disk_intr>
    80002b04:	b7c5                	j	80002ae4 <devintr+0x5e>
    if(cpuid() == 0){
    80002b06:	fffff097          	auipc	ra,0xfffff
    80002b0a:	0de080e7          	jalr	222(ra) # 80001be4 <cpuid>
    80002b0e:	c901                	beqz	a0,80002b1e <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002b10:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002b14:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002b16:	14479073          	csrw	sip,a5
    return 2;
    80002b1a:	4509                	li	a0,2
    80002b1c:	b761                	j	80002aa4 <devintr+0x1e>
      clockintr();
    80002b1e:	00000097          	auipc	ra,0x0
    80002b22:	f22080e7          	jalr	-222(ra) # 80002a40 <clockintr>
    80002b26:	b7ed                	j	80002b10 <devintr+0x8a>

0000000080002b28 <usertrap>:
{
    80002b28:	1101                	addi	sp,sp,-32
    80002b2a:	ec06                	sd	ra,24(sp)
    80002b2c:	e822                	sd	s0,16(sp)
    80002b2e:	e426                	sd	s1,8(sp)
    80002b30:	e04a                	sd	s2,0(sp)
    80002b32:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b34:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002b38:	1007f793          	andi	a5,a5,256
    80002b3c:	e3ad                	bnez	a5,80002b9e <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b3e:	00003797          	auipc	a5,0x3
    80002b42:	34278793          	addi	a5,a5,834 # 80005e80 <kernelvec>
    80002b46:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002b4a:	fffff097          	auipc	ra,0xfffff
    80002b4e:	0c6080e7          	jalr	198(ra) # 80001c10 <myproc>
    80002b52:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002b54:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b56:	14102773          	csrr	a4,sepc
    80002b5a:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b5c:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002b60:	47a1                	li	a5,8
    80002b62:	04f71c63          	bne	a4,a5,80002bba <usertrap+0x92>
    if(p->killed)
    80002b66:	591c                	lw	a5,48(a0)
    80002b68:	e3b9                	bnez	a5,80002bae <usertrap+0x86>
    p->trapframe->epc += 4;
    80002b6a:	6cb8                	ld	a4,88(s1)
    80002b6c:	6f1c                	ld	a5,24(a4)
    80002b6e:	0791                	addi	a5,a5,4
    80002b70:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b72:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b76:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b7a:	10079073          	csrw	sstatus,a5
    syscall();
    80002b7e:	00000097          	auipc	ra,0x0
    80002b82:	2e0080e7          	jalr	736(ra) # 80002e5e <syscall>
  if(p->killed)
    80002b86:	589c                	lw	a5,48(s1)
    80002b88:	ebc1                	bnez	a5,80002c18 <usertrap+0xf0>
  usertrapret();
    80002b8a:	00000097          	auipc	ra,0x0
    80002b8e:	e18080e7          	jalr	-488(ra) # 800029a2 <usertrapret>
}
    80002b92:	60e2                	ld	ra,24(sp)
    80002b94:	6442                	ld	s0,16(sp)
    80002b96:	64a2                	ld	s1,8(sp)
    80002b98:	6902                	ld	s2,0(sp)
    80002b9a:	6105                	addi	sp,sp,32
    80002b9c:	8082                	ret
    panic("usertrap: not from user mode");
    80002b9e:	00006517          	auipc	a0,0x6
    80002ba2:	84a50513          	addi	a0,a0,-1974 # 800083e8 <states.1744+0x50>
    80002ba6:	ffffe097          	auipc	ra,0xffffe
    80002baa:	9a2080e7          	jalr	-1630(ra) # 80000548 <panic>
      exit(-1);
    80002bae:	557d                	li	a0,-1
    80002bb0:	00000097          	auipc	ra,0x0
    80002bb4:	846080e7          	jalr	-1978(ra) # 800023f6 <exit>
    80002bb8:	bf4d                	j	80002b6a <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002bba:	00000097          	auipc	ra,0x0
    80002bbe:	ecc080e7          	jalr	-308(ra) # 80002a86 <devintr>
    80002bc2:	892a                	mv	s2,a0
    80002bc4:	c501                	beqz	a0,80002bcc <usertrap+0xa4>
  if(p->killed)
    80002bc6:	589c                	lw	a5,48(s1)
    80002bc8:	c3a1                	beqz	a5,80002c08 <usertrap+0xe0>
    80002bca:	a815                	j	80002bfe <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bcc:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002bd0:	5c90                	lw	a2,56(s1)
    80002bd2:	00006517          	auipc	a0,0x6
    80002bd6:	83650513          	addi	a0,a0,-1994 # 80008408 <states.1744+0x70>
    80002bda:	ffffe097          	auipc	ra,0xffffe
    80002bde:	9b8080e7          	jalr	-1608(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002be2:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002be6:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002bea:	00006517          	auipc	a0,0x6
    80002bee:	84e50513          	addi	a0,a0,-1970 # 80008438 <states.1744+0xa0>
    80002bf2:	ffffe097          	auipc	ra,0xffffe
    80002bf6:	9a0080e7          	jalr	-1632(ra) # 80000592 <printf>
    p->killed = 1;
    80002bfa:	4785                	li	a5,1
    80002bfc:	d89c                	sw	a5,48(s1)
    exit(-1);
    80002bfe:	557d                	li	a0,-1
    80002c00:	fffff097          	auipc	ra,0xfffff
    80002c04:	7f6080e7          	jalr	2038(ra) # 800023f6 <exit>
  if(which_dev == 2)
    80002c08:	4789                	li	a5,2
    80002c0a:	f8f910e3          	bne	s2,a5,80002b8a <usertrap+0x62>
    yield();
    80002c0e:	00000097          	auipc	ra,0x0
    80002c12:	8f2080e7          	jalr	-1806(ra) # 80002500 <yield>
    80002c16:	bf95                	j	80002b8a <usertrap+0x62>
  int which_dev = 0;
    80002c18:	4901                	li	s2,0
    80002c1a:	b7d5                	j	80002bfe <usertrap+0xd6>

0000000080002c1c <kerneltrap>:
{
    80002c1c:	7179                	addi	sp,sp,-48
    80002c1e:	f406                	sd	ra,40(sp)
    80002c20:	f022                	sd	s0,32(sp)
    80002c22:	ec26                	sd	s1,24(sp)
    80002c24:	e84a                	sd	s2,16(sp)
    80002c26:	e44e                	sd	s3,8(sp)
    80002c28:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c2a:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c2e:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c32:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002c36:	1004f793          	andi	a5,s1,256
    80002c3a:	cb85                	beqz	a5,80002c6a <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c3c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002c40:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002c42:	ef85                	bnez	a5,80002c7a <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002c44:	00000097          	auipc	ra,0x0
    80002c48:	e42080e7          	jalr	-446(ra) # 80002a86 <devintr>
    80002c4c:	cd1d                	beqz	a0,80002c8a <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c4e:	4789                	li	a5,2
    80002c50:	06f50a63          	beq	a0,a5,80002cc4 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c54:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c58:	10049073          	csrw	sstatus,s1
}
    80002c5c:	70a2                	ld	ra,40(sp)
    80002c5e:	7402                	ld	s0,32(sp)
    80002c60:	64e2                	ld	s1,24(sp)
    80002c62:	6942                	ld	s2,16(sp)
    80002c64:	69a2                	ld	s3,8(sp)
    80002c66:	6145                	addi	sp,sp,48
    80002c68:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002c6a:	00005517          	auipc	a0,0x5
    80002c6e:	7ee50513          	addi	a0,a0,2030 # 80008458 <states.1744+0xc0>
    80002c72:	ffffe097          	auipc	ra,0xffffe
    80002c76:	8d6080e7          	jalr	-1834(ra) # 80000548 <panic>
    panic("kerneltrap: interrupts enabled");
    80002c7a:	00006517          	auipc	a0,0x6
    80002c7e:	80650513          	addi	a0,a0,-2042 # 80008480 <states.1744+0xe8>
    80002c82:	ffffe097          	auipc	ra,0xffffe
    80002c86:	8c6080e7          	jalr	-1850(ra) # 80000548 <panic>
    printf("scause %p\n", scause);
    80002c8a:	85ce                	mv	a1,s3
    80002c8c:	00006517          	auipc	a0,0x6
    80002c90:	81450513          	addi	a0,a0,-2028 # 800084a0 <states.1744+0x108>
    80002c94:	ffffe097          	auipc	ra,0xffffe
    80002c98:	8fe080e7          	jalr	-1794(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c9c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ca0:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ca4:	00006517          	auipc	a0,0x6
    80002ca8:	80c50513          	addi	a0,a0,-2036 # 800084b0 <states.1744+0x118>
    80002cac:	ffffe097          	auipc	ra,0xffffe
    80002cb0:	8e6080e7          	jalr	-1818(ra) # 80000592 <printf>
    panic("kerneltrap");
    80002cb4:	00006517          	auipc	a0,0x6
    80002cb8:	81450513          	addi	a0,a0,-2028 # 800084c8 <states.1744+0x130>
    80002cbc:	ffffe097          	auipc	ra,0xffffe
    80002cc0:	88c080e7          	jalr	-1908(ra) # 80000548 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002cc4:	fffff097          	auipc	ra,0xfffff
    80002cc8:	f4c080e7          	jalr	-180(ra) # 80001c10 <myproc>
    80002ccc:	d541                	beqz	a0,80002c54 <kerneltrap+0x38>
    80002cce:	fffff097          	auipc	ra,0xfffff
    80002cd2:	f42080e7          	jalr	-190(ra) # 80001c10 <myproc>
    80002cd6:	4d18                	lw	a4,24(a0)
    80002cd8:	478d                	li	a5,3
    80002cda:	f6f71de3          	bne	a4,a5,80002c54 <kerneltrap+0x38>
    yield();
    80002cde:	00000097          	auipc	ra,0x0
    80002ce2:	822080e7          	jalr	-2014(ra) # 80002500 <yield>
    80002ce6:	b7bd                	j	80002c54 <kerneltrap+0x38>

0000000080002ce8 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002ce8:	1101                	addi	sp,sp,-32
    80002cea:	ec06                	sd	ra,24(sp)
    80002cec:	e822                	sd	s0,16(sp)
    80002cee:	e426                	sd	s1,8(sp)
    80002cf0:	1000                	addi	s0,sp,32
    80002cf2:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002cf4:	fffff097          	auipc	ra,0xfffff
    80002cf8:	f1c080e7          	jalr	-228(ra) # 80001c10 <myproc>
  switch (n) {
    80002cfc:	4795                	li	a5,5
    80002cfe:	0497e163          	bltu	a5,s1,80002d40 <argraw+0x58>
    80002d02:	048a                	slli	s1,s1,0x2
    80002d04:	00005717          	auipc	a4,0x5
    80002d08:	7fc70713          	addi	a4,a4,2044 # 80008500 <states.1744+0x168>
    80002d0c:	94ba                	add	s1,s1,a4
    80002d0e:	409c                	lw	a5,0(s1)
    80002d10:	97ba                	add	a5,a5,a4
    80002d12:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002d14:	6d3c                	ld	a5,88(a0)
    80002d16:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002d18:	60e2                	ld	ra,24(sp)
    80002d1a:	6442                	ld	s0,16(sp)
    80002d1c:	64a2                	ld	s1,8(sp)
    80002d1e:	6105                	addi	sp,sp,32
    80002d20:	8082                	ret
    return p->trapframe->a1;
    80002d22:	6d3c                	ld	a5,88(a0)
    80002d24:	7fa8                	ld	a0,120(a5)
    80002d26:	bfcd                	j	80002d18 <argraw+0x30>
    return p->trapframe->a2;
    80002d28:	6d3c                	ld	a5,88(a0)
    80002d2a:	63c8                	ld	a0,128(a5)
    80002d2c:	b7f5                	j	80002d18 <argraw+0x30>
    return p->trapframe->a3;
    80002d2e:	6d3c                	ld	a5,88(a0)
    80002d30:	67c8                	ld	a0,136(a5)
    80002d32:	b7dd                	j	80002d18 <argraw+0x30>
    return p->trapframe->a4;
    80002d34:	6d3c                	ld	a5,88(a0)
    80002d36:	6bc8                	ld	a0,144(a5)
    80002d38:	b7c5                	j	80002d18 <argraw+0x30>
    return p->trapframe->a5;
    80002d3a:	6d3c                	ld	a5,88(a0)
    80002d3c:	6fc8                	ld	a0,152(a5)
    80002d3e:	bfe9                	j	80002d18 <argraw+0x30>
  panic("argraw");
    80002d40:	00005517          	auipc	a0,0x5
    80002d44:	79850513          	addi	a0,a0,1944 # 800084d8 <states.1744+0x140>
    80002d48:	ffffe097          	auipc	ra,0xffffe
    80002d4c:	800080e7          	jalr	-2048(ra) # 80000548 <panic>

0000000080002d50 <fetchaddr>:
{
    80002d50:	1101                	addi	sp,sp,-32
    80002d52:	ec06                	sd	ra,24(sp)
    80002d54:	e822                	sd	s0,16(sp)
    80002d56:	e426                	sd	s1,8(sp)
    80002d58:	e04a                	sd	s2,0(sp)
    80002d5a:	1000                	addi	s0,sp,32
    80002d5c:	84aa                	mv	s1,a0
    80002d5e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002d60:	fffff097          	auipc	ra,0xfffff
    80002d64:	eb0080e7          	jalr	-336(ra) # 80001c10 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002d68:	653c                	ld	a5,72(a0)
    80002d6a:	02f4f863          	bgeu	s1,a5,80002d9a <fetchaddr+0x4a>
    80002d6e:	00848713          	addi	a4,s1,8
    80002d72:	02e7e663          	bltu	a5,a4,80002d9e <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002d76:	46a1                	li	a3,8
    80002d78:	8626                	mv	a2,s1
    80002d7a:	85ca                	mv	a1,s2
    80002d7c:	6928                	ld	a0,80(a0)
    80002d7e:	fffff097          	auipc	ra,0xfffff
    80002d82:	bf6080e7          	jalr	-1034(ra) # 80001974 <copyin>
    80002d86:	00a03533          	snez	a0,a0
    80002d8a:	40a00533          	neg	a0,a0
}
    80002d8e:	60e2                	ld	ra,24(sp)
    80002d90:	6442                	ld	s0,16(sp)
    80002d92:	64a2                	ld	s1,8(sp)
    80002d94:	6902                	ld	s2,0(sp)
    80002d96:	6105                	addi	sp,sp,32
    80002d98:	8082                	ret
    return -1;
    80002d9a:	557d                	li	a0,-1
    80002d9c:	bfcd                	j	80002d8e <fetchaddr+0x3e>
    80002d9e:	557d                	li	a0,-1
    80002da0:	b7fd                	j	80002d8e <fetchaddr+0x3e>

0000000080002da2 <fetchstr>:
{
    80002da2:	7179                	addi	sp,sp,-48
    80002da4:	f406                	sd	ra,40(sp)
    80002da6:	f022                	sd	s0,32(sp)
    80002da8:	ec26                	sd	s1,24(sp)
    80002daa:	e84a                	sd	s2,16(sp)
    80002dac:	e44e                	sd	s3,8(sp)
    80002dae:	1800                	addi	s0,sp,48
    80002db0:	892a                	mv	s2,a0
    80002db2:	84ae                	mv	s1,a1
    80002db4:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002db6:	fffff097          	auipc	ra,0xfffff
    80002dba:	e5a080e7          	jalr	-422(ra) # 80001c10 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002dbe:	86ce                	mv	a3,s3
    80002dc0:	864a                	mv	a2,s2
    80002dc2:	85a6                	mv	a1,s1
    80002dc4:	6928                	ld	a0,80(a0)
    80002dc6:	fffff097          	auipc	ra,0xfffff
    80002dca:	bc6080e7          	jalr	-1082(ra) # 8000198c <copyinstr>
  if(err < 0)
    80002dce:	00054763          	bltz	a0,80002ddc <fetchstr+0x3a>
  return strlen(buf);
    80002dd2:	8526                	mv	a0,s1
    80002dd4:	ffffe097          	auipc	ra,0xffffe
    80002dd8:	0c0080e7          	jalr	192(ra) # 80000e94 <strlen>
}
    80002ddc:	70a2                	ld	ra,40(sp)
    80002dde:	7402                	ld	s0,32(sp)
    80002de0:	64e2                	ld	s1,24(sp)
    80002de2:	6942                	ld	s2,16(sp)
    80002de4:	69a2                	ld	s3,8(sp)
    80002de6:	6145                	addi	sp,sp,48
    80002de8:	8082                	ret

0000000080002dea <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002dea:	1101                	addi	sp,sp,-32
    80002dec:	ec06                	sd	ra,24(sp)
    80002dee:	e822                	sd	s0,16(sp)
    80002df0:	e426                	sd	s1,8(sp)
    80002df2:	1000                	addi	s0,sp,32
    80002df4:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002df6:	00000097          	auipc	ra,0x0
    80002dfa:	ef2080e7          	jalr	-270(ra) # 80002ce8 <argraw>
    80002dfe:	c088                	sw	a0,0(s1)
  return 0;
}
    80002e00:	4501                	li	a0,0
    80002e02:	60e2                	ld	ra,24(sp)
    80002e04:	6442                	ld	s0,16(sp)
    80002e06:	64a2                	ld	s1,8(sp)
    80002e08:	6105                	addi	sp,sp,32
    80002e0a:	8082                	ret

0000000080002e0c <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002e0c:	1101                	addi	sp,sp,-32
    80002e0e:	ec06                	sd	ra,24(sp)
    80002e10:	e822                	sd	s0,16(sp)
    80002e12:	e426                	sd	s1,8(sp)
    80002e14:	1000                	addi	s0,sp,32
    80002e16:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e18:	00000097          	auipc	ra,0x0
    80002e1c:	ed0080e7          	jalr	-304(ra) # 80002ce8 <argraw>
    80002e20:	e088                	sd	a0,0(s1)
  return 0;
}
    80002e22:	4501                	li	a0,0
    80002e24:	60e2                	ld	ra,24(sp)
    80002e26:	6442                	ld	s0,16(sp)
    80002e28:	64a2                	ld	s1,8(sp)
    80002e2a:	6105                	addi	sp,sp,32
    80002e2c:	8082                	ret

0000000080002e2e <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002e2e:	1101                	addi	sp,sp,-32
    80002e30:	ec06                	sd	ra,24(sp)
    80002e32:	e822                	sd	s0,16(sp)
    80002e34:	e426                	sd	s1,8(sp)
    80002e36:	e04a                	sd	s2,0(sp)
    80002e38:	1000                	addi	s0,sp,32
    80002e3a:	84ae                	mv	s1,a1
    80002e3c:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002e3e:	00000097          	auipc	ra,0x0
    80002e42:	eaa080e7          	jalr	-342(ra) # 80002ce8 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
    // addr is the virtual address from user table on the string
  return fetchstr(addr, buf, max);
    80002e46:	864a                	mv	a2,s2
    80002e48:	85a6                	mv	a1,s1
    80002e4a:	00000097          	auipc	ra,0x0
    80002e4e:	f58080e7          	jalr	-168(ra) # 80002da2 <fetchstr>
}
    80002e52:	60e2                	ld	ra,24(sp)
    80002e54:	6442                	ld	s0,16(sp)
    80002e56:	64a2                	ld	s1,8(sp)
    80002e58:	6902                	ld	s2,0(sp)
    80002e5a:	6105                	addi	sp,sp,32
    80002e5c:	8082                	ret

0000000080002e5e <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002e5e:	1101                	addi	sp,sp,-32
    80002e60:	ec06                	sd	ra,24(sp)
    80002e62:	e822                	sd	s0,16(sp)
    80002e64:	e426                	sd	s1,8(sp)
    80002e66:	e04a                	sd	s2,0(sp)
    80002e68:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002e6a:	fffff097          	auipc	ra,0xfffff
    80002e6e:	da6080e7          	jalr	-602(ra) # 80001c10 <myproc>
    80002e72:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002e74:	05853903          	ld	s2,88(a0)
    80002e78:	0a893783          	ld	a5,168(s2)
    80002e7c:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002e80:	37fd                	addiw	a5,a5,-1
    80002e82:	4751                	li	a4,20
    80002e84:	00f76f63          	bltu	a4,a5,80002ea2 <syscall+0x44>
    80002e88:	00369713          	slli	a4,a3,0x3
    80002e8c:	00005797          	auipc	a5,0x5
    80002e90:	68c78793          	addi	a5,a5,1676 # 80008518 <syscalls>
    80002e94:	97ba                	add	a5,a5,a4
    80002e96:	639c                	ld	a5,0(a5)
    80002e98:	c789                	beqz	a5,80002ea2 <syscall+0x44>
    // store the return value to userspace
    p->trapframe->a0 = syscalls[num]();
    80002e9a:	9782                	jalr	a5
    80002e9c:	06a93823          	sd	a0,112(s2)
    80002ea0:	a839                	j	80002ebe <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002ea2:	15848613          	addi	a2,s1,344
    80002ea6:	5c8c                	lw	a1,56(s1)
    80002ea8:	00005517          	auipc	a0,0x5
    80002eac:	63850513          	addi	a0,a0,1592 # 800084e0 <states.1744+0x148>
    80002eb0:	ffffd097          	auipc	ra,0xffffd
    80002eb4:	6e2080e7          	jalr	1762(ra) # 80000592 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002eb8:	6cbc                	ld	a5,88(s1)
    80002eba:	577d                	li	a4,-1
    80002ebc:	fbb8                	sd	a4,112(a5)
  }
}
    80002ebe:	60e2                	ld	ra,24(sp)
    80002ec0:	6442                	ld	s0,16(sp)
    80002ec2:	64a2                	ld	s1,8(sp)
    80002ec4:	6902                	ld	s2,0(sp)
    80002ec6:	6105                	addi	sp,sp,32
    80002ec8:	8082                	ret

0000000080002eca <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002eca:	1101                	addi	sp,sp,-32
    80002ecc:	ec06                	sd	ra,24(sp)
    80002ece:	e822                	sd	s0,16(sp)
    80002ed0:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002ed2:	fec40593          	addi	a1,s0,-20
    80002ed6:	4501                	li	a0,0
    80002ed8:	00000097          	auipc	ra,0x0
    80002edc:	f12080e7          	jalr	-238(ra) # 80002dea <argint>
    return -1;
    80002ee0:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002ee2:	00054963          	bltz	a0,80002ef4 <sys_exit+0x2a>
  exit(n);
    80002ee6:	fec42503          	lw	a0,-20(s0)
    80002eea:	fffff097          	auipc	ra,0xfffff
    80002eee:	50c080e7          	jalr	1292(ra) # 800023f6 <exit>
  return 0;  // not reached
    80002ef2:	4781                	li	a5,0
}
    80002ef4:	853e                	mv	a0,a5
    80002ef6:	60e2                	ld	ra,24(sp)
    80002ef8:	6442                	ld	s0,16(sp)
    80002efa:	6105                	addi	sp,sp,32
    80002efc:	8082                	ret

0000000080002efe <sys_getpid>:

uint64
sys_getpid(void)
{
    80002efe:	1141                	addi	sp,sp,-16
    80002f00:	e406                	sd	ra,8(sp)
    80002f02:	e022                	sd	s0,0(sp)
    80002f04:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002f06:	fffff097          	auipc	ra,0xfffff
    80002f0a:	d0a080e7          	jalr	-758(ra) # 80001c10 <myproc>
}
    80002f0e:	5d08                	lw	a0,56(a0)
    80002f10:	60a2                	ld	ra,8(sp)
    80002f12:	6402                	ld	s0,0(sp)
    80002f14:	0141                	addi	sp,sp,16
    80002f16:	8082                	ret

0000000080002f18 <sys_fork>:

uint64
sys_fork(void)
{
    80002f18:	1141                	addi	sp,sp,-16
    80002f1a:	e406                	sd	ra,8(sp)
    80002f1c:	e022                	sd	s0,0(sp)
    80002f1e:	0800                	addi	s0,sp,16
  return fork();
    80002f20:	fffff097          	auipc	ra,0xfffff
    80002f24:	18e080e7          	jalr	398(ra) # 800020ae <fork>
}
    80002f28:	60a2                	ld	ra,8(sp)
    80002f2a:	6402                	ld	s0,0(sp)
    80002f2c:	0141                	addi	sp,sp,16
    80002f2e:	8082                	ret

0000000080002f30 <sys_wait>:

uint64
sys_wait(void)
{
    80002f30:	1101                	addi	sp,sp,-32
    80002f32:	ec06                	sd	ra,24(sp)
    80002f34:	e822                	sd	s0,16(sp)
    80002f36:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002f38:	fe840593          	addi	a1,s0,-24
    80002f3c:	4501                	li	a0,0
    80002f3e:	00000097          	auipc	ra,0x0
    80002f42:	ece080e7          	jalr	-306(ra) # 80002e0c <argaddr>
    80002f46:	87aa                	mv	a5,a0
    return -1;
    80002f48:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002f4a:	0007c863          	bltz	a5,80002f5a <sys_wait+0x2a>
  return wait(p);
    80002f4e:	fe843503          	ld	a0,-24(s0)
    80002f52:	fffff097          	auipc	ra,0xfffff
    80002f56:	668080e7          	jalr	1640(ra) # 800025ba <wait>
}
    80002f5a:	60e2                	ld	ra,24(sp)
    80002f5c:	6442                	ld	s0,16(sp)
    80002f5e:	6105                	addi	sp,sp,32
    80002f60:	8082                	ret

0000000080002f62 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002f62:	7179                	addi	sp,sp,-48
    80002f64:	f406                	sd	ra,40(sp)
    80002f66:	f022                	sd	s0,32(sp)
    80002f68:	ec26                	sd	s1,24(sp)
    80002f6a:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002f6c:	fdc40593          	addi	a1,s0,-36
    80002f70:	4501                	li	a0,0
    80002f72:	00000097          	auipc	ra,0x0
    80002f76:	e78080e7          	jalr	-392(ra) # 80002dea <argint>
    80002f7a:	87aa                	mv	a5,a0
    return -1;
    80002f7c:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002f7e:	0207c063          	bltz	a5,80002f9e <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002f82:	fffff097          	auipc	ra,0xfffff
    80002f86:	c8e080e7          	jalr	-882(ra) # 80001c10 <myproc>
    80002f8a:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002f8c:	fdc42503          	lw	a0,-36(s0)
    80002f90:	fffff097          	auipc	ra,0xfffff
    80002f94:	08a080e7          	jalr	138(ra) # 8000201a <growproc>
    80002f98:	00054863          	bltz	a0,80002fa8 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002f9c:	8526                	mv	a0,s1
}
    80002f9e:	70a2                	ld	ra,40(sp)
    80002fa0:	7402                	ld	s0,32(sp)
    80002fa2:	64e2                	ld	s1,24(sp)
    80002fa4:	6145                	addi	sp,sp,48
    80002fa6:	8082                	ret
    return -1;
    80002fa8:	557d                	li	a0,-1
    80002faa:	bfd5                	j	80002f9e <sys_sbrk+0x3c>

0000000080002fac <sys_sleep>:

uint64
sys_sleep(void)
{
    80002fac:	7139                	addi	sp,sp,-64
    80002fae:	fc06                	sd	ra,56(sp)
    80002fb0:	f822                	sd	s0,48(sp)
    80002fb2:	f426                	sd	s1,40(sp)
    80002fb4:	f04a                	sd	s2,32(sp)
    80002fb6:	ec4e                	sd	s3,24(sp)
    80002fb8:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002fba:	fcc40593          	addi	a1,s0,-52
    80002fbe:	4501                	li	a0,0
    80002fc0:	00000097          	auipc	ra,0x0
    80002fc4:	e2a080e7          	jalr	-470(ra) # 80002dea <argint>
    return -1;
    80002fc8:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002fca:	06054563          	bltz	a0,80003034 <sys_sleep+0x88>
  acquire(&tickslock);
    80002fce:	00015517          	auipc	a0,0x15
    80002fd2:	9aa50513          	addi	a0,a0,-1622 # 80017978 <tickslock>
    80002fd6:	ffffe097          	auipc	ra,0xffffe
    80002fda:	c3a080e7          	jalr	-966(ra) # 80000c10 <acquire>
  ticks0 = ticks;
    80002fde:	00006917          	auipc	s2,0x6
    80002fe2:	04a92903          	lw	s2,74(s2) # 80009028 <ticks>
  while(ticks - ticks0 < n){
    80002fe6:	fcc42783          	lw	a5,-52(s0)
    80002fea:	cf85                	beqz	a5,80003022 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002fec:	00015997          	auipc	s3,0x15
    80002ff0:	98c98993          	addi	s3,s3,-1652 # 80017978 <tickslock>
    80002ff4:	00006497          	auipc	s1,0x6
    80002ff8:	03448493          	addi	s1,s1,52 # 80009028 <ticks>
    if(myproc()->killed){
    80002ffc:	fffff097          	auipc	ra,0xfffff
    80003000:	c14080e7          	jalr	-1004(ra) # 80001c10 <myproc>
    80003004:	591c                	lw	a5,48(a0)
    80003006:	ef9d                	bnez	a5,80003044 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003008:	85ce                	mv	a1,s3
    8000300a:	8526                	mv	a0,s1
    8000300c:	fffff097          	auipc	ra,0xfffff
    80003010:	530080e7          	jalr	1328(ra) # 8000253c <sleep>
  while(ticks - ticks0 < n){
    80003014:	409c                	lw	a5,0(s1)
    80003016:	412787bb          	subw	a5,a5,s2
    8000301a:	fcc42703          	lw	a4,-52(s0)
    8000301e:	fce7efe3          	bltu	a5,a4,80002ffc <sys_sleep+0x50>
  }
  release(&tickslock);
    80003022:	00015517          	auipc	a0,0x15
    80003026:	95650513          	addi	a0,a0,-1706 # 80017978 <tickslock>
    8000302a:	ffffe097          	auipc	ra,0xffffe
    8000302e:	c9a080e7          	jalr	-870(ra) # 80000cc4 <release>
  return 0;
    80003032:	4781                	li	a5,0
}
    80003034:	853e                	mv	a0,a5
    80003036:	70e2                	ld	ra,56(sp)
    80003038:	7442                	ld	s0,48(sp)
    8000303a:	74a2                	ld	s1,40(sp)
    8000303c:	7902                	ld	s2,32(sp)
    8000303e:	69e2                	ld	s3,24(sp)
    80003040:	6121                	addi	sp,sp,64
    80003042:	8082                	ret
      release(&tickslock);
    80003044:	00015517          	auipc	a0,0x15
    80003048:	93450513          	addi	a0,a0,-1740 # 80017978 <tickslock>
    8000304c:	ffffe097          	auipc	ra,0xffffe
    80003050:	c78080e7          	jalr	-904(ra) # 80000cc4 <release>
      return -1;
    80003054:	57fd                	li	a5,-1
    80003056:	bff9                	j	80003034 <sys_sleep+0x88>

0000000080003058 <sys_kill>:

uint64
sys_kill(void)
{
    80003058:	1101                	addi	sp,sp,-32
    8000305a:	ec06                	sd	ra,24(sp)
    8000305c:	e822                	sd	s0,16(sp)
    8000305e:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003060:	fec40593          	addi	a1,s0,-20
    80003064:	4501                	li	a0,0
    80003066:	00000097          	auipc	ra,0x0
    8000306a:	d84080e7          	jalr	-636(ra) # 80002dea <argint>
    8000306e:	87aa                	mv	a5,a0
    return -1;
    80003070:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003072:	0007c863          	bltz	a5,80003082 <sys_kill+0x2a>
  return kill(pid);
    80003076:	fec42503          	lw	a0,-20(s0)
    8000307a:	fffff097          	auipc	ra,0xfffff
    8000307e:	6b2080e7          	jalr	1714(ra) # 8000272c <kill>
}
    80003082:	60e2                	ld	ra,24(sp)
    80003084:	6442                	ld	s0,16(sp)
    80003086:	6105                	addi	sp,sp,32
    80003088:	8082                	ret

000000008000308a <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000308a:	1101                	addi	sp,sp,-32
    8000308c:	ec06                	sd	ra,24(sp)
    8000308e:	e822                	sd	s0,16(sp)
    80003090:	e426                	sd	s1,8(sp)
    80003092:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003094:	00015517          	auipc	a0,0x15
    80003098:	8e450513          	addi	a0,a0,-1820 # 80017978 <tickslock>
    8000309c:	ffffe097          	auipc	ra,0xffffe
    800030a0:	b74080e7          	jalr	-1164(ra) # 80000c10 <acquire>
  xticks = ticks;
    800030a4:	00006497          	auipc	s1,0x6
    800030a8:	f844a483          	lw	s1,-124(s1) # 80009028 <ticks>
  release(&tickslock);
    800030ac:	00015517          	auipc	a0,0x15
    800030b0:	8cc50513          	addi	a0,a0,-1844 # 80017978 <tickslock>
    800030b4:	ffffe097          	auipc	ra,0xffffe
    800030b8:	c10080e7          	jalr	-1008(ra) # 80000cc4 <release>
  return xticks;
}
    800030bc:	02049513          	slli	a0,s1,0x20
    800030c0:	9101                	srli	a0,a0,0x20
    800030c2:	60e2                	ld	ra,24(sp)
    800030c4:	6442                	ld	s0,16(sp)
    800030c6:	64a2                	ld	s1,8(sp)
    800030c8:	6105                	addi	sp,sp,32
    800030ca:	8082                	ret

00000000800030cc <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800030cc:	7179                	addi	sp,sp,-48
    800030ce:	f406                	sd	ra,40(sp)
    800030d0:	f022                	sd	s0,32(sp)
    800030d2:	ec26                	sd	s1,24(sp)
    800030d4:	e84a                	sd	s2,16(sp)
    800030d6:	e44e                	sd	s3,8(sp)
    800030d8:	e052                	sd	s4,0(sp)
    800030da:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800030dc:	00005597          	auipc	a1,0x5
    800030e0:	4ec58593          	addi	a1,a1,1260 # 800085c8 <syscalls+0xb0>
    800030e4:	00015517          	auipc	a0,0x15
    800030e8:	8ac50513          	addi	a0,a0,-1876 # 80017990 <bcache>
    800030ec:	ffffe097          	auipc	ra,0xffffe
    800030f0:	a94080e7          	jalr	-1388(ra) # 80000b80 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800030f4:	0001d797          	auipc	a5,0x1d
    800030f8:	89c78793          	addi	a5,a5,-1892 # 8001f990 <bcache+0x8000>
    800030fc:	0001d717          	auipc	a4,0x1d
    80003100:	afc70713          	addi	a4,a4,-1284 # 8001fbf8 <bcache+0x8268>
    80003104:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003108:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000310c:	00015497          	auipc	s1,0x15
    80003110:	89c48493          	addi	s1,s1,-1892 # 800179a8 <bcache+0x18>
    b->next = bcache.head.next;
    80003114:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003116:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003118:	00005a17          	auipc	s4,0x5
    8000311c:	4b8a0a13          	addi	s4,s4,1208 # 800085d0 <syscalls+0xb8>
    b->next = bcache.head.next;
    80003120:	2b893783          	ld	a5,696(s2)
    80003124:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003126:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000312a:	85d2                	mv	a1,s4
    8000312c:	01048513          	addi	a0,s1,16
    80003130:	00001097          	auipc	ra,0x1
    80003134:	4ac080e7          	jalr	1196(ra) # 800045dc <initsleeplock>
    bcache.head.next->prev = b;
    80003138:	2b893783          	ld	a5,696(s2)
    8000313c:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000313e:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003142:	45848493          	addi	s1,s1,1112
    80003146:	fd349de3          	bne	s1,s3,80003120 <binit+0x54>
  }
}
    8000314a:	70a2                	ld	ra,40(sp)
    8000314c:	7402                	ld	s0,32(sp)
    8000314e:	64e2                	ld	s1,24(sp)
    80003150:	6942                	ld	s2,16(sp)
    80003152:	69a2                	ld	s3,8(sp)
    80003154:	6a02                	ld	s4,0(sp)
    80003156:	6145                	addi	sp,sp,48
    80003158:	8082                	ret

000000008000315a <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000315a:	7179                	addi	sp,sp,-48
    8000315c:	f406                	sd	ra,40(sp)
    8000315e:	f022                	sd	s0,32(sp)
    80003160:	ec26                	sd	s1,24(sp)
    80003162:	e84a                	sd	s2,16(sp)
    80003164:	e44e                	sd	s3,8(sp)
    80003166:	1800                	addi	s0,sp,48
    80003168:	89aa                	mv	s3,a0
    8000316a:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    8000316c:	00015517          	auipc	a0,0x15
    80003170:	82450513          	addi	a0,a0,-2012 # 80017990 <bcache>
    80003174:	ffffe097          	auipc	ra,0xffffe
    80003178:	a9c080e7          	jalr	-1380(ra) # 80000c10 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000317c:	0001d497          	auipc	s1,0x1d
    80003180:	acc4b483          	ld	s1,-1332(s1) # 8001fc48 <bcache+0x82b8>
    80003184:	0001d797          	auipc	a5,0x1d
    80003188:	a7478793          	addi	a5,a5,-1420 # 8001fbf8 <bcache+0x8268>
    8000318c:	02f48f63          	beq	s1,a5,800031ca <bread+0x70>
    80003190:	873e                	mv	a4,a5
    80003192:	a021                	j	8000319a <bread+0x40>
    80003194:	68a4                	ld	s1,80(s1)
    80003196:	02e48a63          	beq	s1,a4,800031ca <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000319a:	449c                	lw	a5,8(s1)
    8000319c:	ff379ce3          	bne	a5,s3,80003194 <bread+0x3a>
    800031a0:	44dc                	lw	a5,12(s1)
    800031a2:	ff2799e3          	bne	a5,s2,80003194 <bread+0x3a>
      b->refcnt++;
    800031a6:	40bc                	lw	a5,64(s1)
    800031a8:	2785                	addiw	a5,a5,1
    800031aa:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800031ac:	00014517          	auipc	a0,0x14
    800031b0:	7e450513          	addi	a0,a0,2020 # 80017990 <bcache>
    800031b4:	ffffe097          	auipc	ra,0xffffe
    800031b8:	b10080e7          	jalr	-1264(ra) # 80000cc4 <release>
      acquiresleep(&b->lock);
    800031bc:	01048513          	addi	a0,s1,16
    800031c0:	00001097          	auipc	ra,0x1
    800031c4:	456080e7          	jalr	1110(ra) # 80004616 <acquiresleep>
      return b;
    800031c8:	a8b9                	j	80003226 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800031ca:	0001d497          	auipc	s1,0x1d
    800031ce:	a764b483          	ld	s1,-1418(s1) # 8001fc40 <bcache+0x82b0>
    800031d2:	0001d797          	auipc	a5,0x1d
    800031d6:	a2678793          	addi	a5,a5,-1498 # 8001fbf8 <bcache+0x8268>
    800031da:	00f48863          	beq	s1,a5,800031ea <bread+0x90>
    800031de:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800031e0:	40bc                	lw	a5,64(s1)
    800031e2:	cf81                	beqz	a5,800031fa <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800031e4:	64a4                	ld	s1,72(s1)
    800031e6:	fee49de3          	bne	s1,a4,800031e0 <bread+0x86>
  panic("bget: no buffers");
    800031ea:	00005517          	auipc	a0,0x5
    800031ee:	3ee50513          	addi	a0,a0,1006 # 800085d8 <syscalls+0xc0>
    800031f2:	ffffd097          	auipc	ra,0xffffd
    800031f6:	356080e7          	jalr	854(ra) # 80000548 <panic>
      b->dev = dev;
    800031fa:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800031fe:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003202:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003206:	4785                	li	a5,1
    80003208:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000320a:	00014517          	auipc	a0,0x14
    8000320e:	78650513          	addi	a0,a0,1926 # 80017990 <bcache>
    80003212:	ffffe097          	auipc	ra,0xffffe
    80003216:	ab2080e7          	jalr	-1358(ra) # 80000cc4 <release>
      acquiresleep(&b->lock);
    8000321a:	01048513          	addi	a0,s1,16
    8000321e:	00001097          	auipc	ra,0x1
    80003222:	3f8080e7          	jalr	1016(ra) # 80004616 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003226:	409c                	lw	a5,0(s1)
    80003228:	cb89                	beqz	a5,8000323a <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000322a:	8526                	mv	a0,s1
    8000322c:	70a2                	ld	ra,40(sp)
    8000322e:	7402                	ld	s0,32(sp)
    80003230:	64e2                	ld	s1,24(sp)
    80003232:	6942                	ld	s2,16(sp)
    80003234:	69a2                	ld	s3,8(sp)
    80003236:	6145                	addi	sp,sp,48
    80003238:	8082                	ret
    virtio_disk_rw(b, 0);
    8000323a:	4581                	li	a1,0
    8000323c:	8526                	mv	a0,s1
    8000323e:	00003097          	auipc	ra,0x3
    80003242:	f5e080e7          	jalr	-162(ra) # 8000619c <virtio_disk_rw>
    b->valid = 1;
    80003246:	4785                	li	a5,1
    80003248:	c09c                	sw	a5,0(s1)
  return b;
    8000324a:	b7c5                	j	8000322a <bread+0xd0>

000000008000324c <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000324c:	1101                	addi	sp,sp,-32
    8000324e:	ec06                	sd	ra,24(sp)
    80003250:	e822                	sd	s0,16(sp)
    80003252:	e426                	sd	s1,8(sp)
    80003254:	1000                	addi	s0,sp,32
    80003256:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003258:	0541                	addi	a0,a0,16
    8000325a:	00001097          	auipc	ra,0x1
    8000325e:	456080e7          	jalr	1110(ra) # 800046b0 <holdingsleep>
    80003262:	cd01                	beqz	a0,8000327a <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003264:	4585                	li	a1,1
    80003266:	8526                	mv	a0,s1
    80003268:	00003097          	auipc	ra,0x3
    8000326c:	f34080e7          	jalr	-204(ra) # 8000619c <virtio_disk_rw>
}
    80003270:	60e2                	ld	ra,24(sp)
    80003272:	6442                	ld	s0,16(sp)
    80003274:	64a2                	ld	s1,8(sp)
    80003276:	6105                	addi	sp,sp,32
    80003278:	8082                	ret
    panic("bwrite");
    8000327a:	00005517          	auipc	a0,0x5
    8000327e:	37650513          	addi	a0,a0,886 # 800085f0 <syscalls+0xd8>
    80003282:	ffffd097          	auipc	ra,0xffffd
    80003286:	2c6080e7          	jalr	710(ra) # 80000548 <panic>

000000008000328a <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000328a:	1101                	addi	sp,sp,-32
    8000328c:	ec06                	sd	ra,24(sp)
    8000328e:	e822                	sd	s0,16(sp)
    80003290:	e426                	sd	s1,8(sp)
    80003292:	e04a                	sd	s2,0(sp)
    80003294:	1000                	addi	s0,sp,32
    80003296:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003298:	01050913          	addi	s2,a0,16
    8000329c:	854a                	mv	a0,s2
    8000329e:	00001097          	auipc	ra,0x1
    800032a2:	412080e7          	jalr	1042(ra) # 800046b0 <holdingsleep>
    800032a6:	c92d                	beqz	a0,80003318 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800032a8:	854a                	mv	a0,s2
    800032aa:	00001097          	auipc	ra,0x1
    800032ae:	3c2080e7          	jalr	962(ra) # 8000466c <releasesleep>

  acquire(&bcache.lock);
    800032b2:	00014517          	auipc	a0,0x14
    800032b6:	6de50513          	addi	a0,a0,1758 # 80017990 <bcache>
    800032ba:	ffffe097          	auipc	ra,0xffffe
    800032be:	956080e7          	jalr	-1706(ra) # 80000c10 <acquire>
  b->refcnt--;
    800032c2:	40bc                	lw	a5,64(s1)
    800032c4:	37fd                	addiw	a5,a5,-1
    800032c6:	0007871b          	sext.w	a4,a5
    800032ca:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800032cc:	eb05                	bnez	a4,800032fc <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800032ce:	68bc                	ld	a5,80(s1)
    800032d0:	64b8                	ld	a4,72(s1)
    800032d2:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800032d4:	64bc                	ld	a5,72(s1)
    800032d6:	68b8                	ld	a4,80(s1)
    800032d8:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800032da:	0001c797          	auipc	a5,0x1c
    800032de:	6b678793          	addi	a5,a5,1718 # 8001f990 <bcache+0x8000>
    800032e2:	2b87b703          	ld	a4,696(a5)
    800032e6:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800032e8:	0001d717          	auipc	a4,0x1d
    800032ec:	91070713          	addi	a4,a4,-1776 # 8001fbf8 <bcache+0x8268>
    800032f0:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800032f2:	2b87b703          	ld	a4,696(a5)
    800032f6:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800032f8:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800032fc:	00014517          	auipc	a0,0x14
    80003300:	69450513          	addi	a0,a0,1684 # 80017990 <bcache>
    80003304:	ffffe097          	auipc	ra,0xffffe
    80003308:	9c0080e7          	jalr	-1600(ra) # 80000cc4 <release>
}
    8000330c:	60e2                	ld	ra,24(sp)
    8000330e:	6442                	ld	s0,16(sp)
    80003310:	64a2                	ld	s1,8(sp)
    80003312:	6902                	ld	s2,0(sp)
    80003314:	6105                	addi	sp,sp,32
    80003316:	8082                	ret
    panic("brelse");
    80003318:	00005517          	auipc	a0,0x5
    8000331c:	2e050513          	addi	a0,a0,736 # 800085f8 <syscalls+0xe0>
    80003320:	ffffd097          	auipc	ra,0xffffd
    80003324:	228080e7          	jalr	552(ra) # 80000548 <panic>

0000000080003328 <bpin>:

void
bpin(struct buf *b) {
    80003328:	1101                	addi	sp,sp,-32
    8000332a:	ec06                	sd	ra,24(sp)
    8000332c:	e822                	sd	s0,16(sp)
    8000332e:	e426                	sd	s1,8(sp)
    80003330:	1000                	addi	s0,sp,32
    80003332:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003334:	00014517          	auipc	a0,0x14
    80003338:	65c50513          	addi	a0,a0,1628 # 80017990 <bcache>
    8000333c:	ffffe097          	auipc	ra,0xffffe
    80003340:	8d4080e7          	jalr	-1836(ra) # 80000c10 <acquire>
  b->refcnt++;
    80003344:	40bc                	lw	a5,64(s1)
    80003346:	2785                	addiw	a5,a5,1
    80003348:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000334a:	00014517          	auipc	a0,0x14
    8000334e:	64650513          	addi	a0,a0,1606 # 80017990 <bcache>
    80003352:	ffffe097          	auipc	ra,0xffffe
    80003356:	972080e7          	jalr	-1678(ra) # 80000cc4 <release>
}
    8000335a:	60e2                	ld	ra,24(sp)
    8000335c:	6442                	ld	s0,16(sp)
    8000335e:	64a2                	ld	s1,8(sp)
    80003360:	6105                	addi	sp,sp,32
    80003362:	8082                	ret

0000000080003364 <bunpin>:

void
bunpin(struct buf *b) {
    80003364:	1101                	addi	sp,sp,-32
    80003366:	ec06                	sd	ra,24(sp)
    80003368:	e822                	sd	s0,16(sp)
    8000336a:	e426                	sd	s1,8(sp)
    8000336c:	1000                	addi	s0,sp,32
    8000336e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003370:	00014517          	auipc	a0,0x14
    80003374:	62050513          	addi	a0,a0,1568 # 80017990 <bcache>
    80003378:	ffffe097          	auipc	ra,0xffffe
    8000337c:	898080e7          	jalr	-1896(ra) # 80000c10 <acquire>
  b->refcnt--;
    80003380:	40bc                	lw	a5,64(s1)
    80003382:	37fd                	addiw	a5,a5,-1
    80003384:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003386:	00014517          	auipc	a0,0x14
    8000338a:	60a50513          	addi	a0,a0,1546 # 80017990 <bcache>
    8000338e:	ffffe097          	auipc	ra,0xffffe
    80003392:	936080e7          	jalr	-1738(ra) # 80000cc4 <release>
}
    80003396:	60e2                	ld	ra,24(sp)
    80003398:	6442                	ld	s0,16(sp)
    8000339a:	64a2                	ld	s1,8(sp)
    8000339c:	6105                	addi	sp,sp,32
    8000339e:	8082                	ret

00000000800033a0 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800033a0:	1101                	addi	sp,sp,-32
    800033a2:	ec06                	sd	ra,24(sp)
    800033a4:	e822                	sd	s0,16(sp)
    800033a6:	e426                	sd	s1,8(sp)
    800033a8:	e04a                	sd	s2,0(sp)
    800033aa:	1000                	addi	s0,sp,32
    800033ac:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800033ae:	00d5d59b          	srliw	a1,a1,0xd
    800033b2:	0001d797          	auipc	a5,0x1d
    800033b6:	cba7a783          	lw	a5,-838(a5) # 8002006c <sb+0x1c>
    800033ba:	9dbd                	addw	a1,a1,a5
    800033bc:	00000097          	auipc	ra,0x0
    800033c0:	d9e080e7          	jalr	-610(ra) # 8000315a <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800033c4:	0074f713          	andi	a4,s1,7
    800033c8:	4785                	li	a5,1
    800033ca:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800033ce:	14ce                	slli	s1,s1,0x33
    800033d0:	90d9                	srli	s1,s1,0x36
    800033d2:	00950733          	add	a4,a0,s1
    800033d6:	05874703          	lbu	a4,88(a4)
    800033da:	00e7f6b3          	and	a3,a5,a4
    800033de:	c69d                	beqz	a3,8000340c <bfree+0x6c>
    800033e0:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800033e2:	94aa                	add	s1,s1,a0
    800033e4:	fff7c793          	not	a5,a5
    800033e8:	8ff9                	and	a5,a5,a4
    800033ea:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800033ee:	00001097          	auipc	ra,0x1
    800033f2:	100080e7          	jalr	256(ra) # 800044ee <log_write>
  brelse(bp);
    800033f6:	854a                	mv	a0,s2
    800033f8:	00000097          	auipc	ra,0x0
    800033fc:	e92080e7          	jalr	-366(ra) # 8000328a <brelse>
}
    80003400:	60e2                	ld	ra,24(sp)
    80003402:	6442                	ld	s0,16(sp)
    80003404:	64a2                	ld	s1,8(sp)
    80003406:	6902                	ld	s2,0(sp)
    80003408:	6105                	addi	sp,sp,32
    8000340a:	8082                	ret
    panic("freeing free block");
    8000340c:	00005517          	auipc	a0,0x5
    80003410:	1f450513          	addi	a0,a0,500 # 80008600 <syscalls+0xe8>
    80003414:	ffffd097          	auipc	ra,0xffffd
    80003418:	134080e7          	jalr	308(ra) # 80000548 <panic>

000000008000341c <balloc>:
{
    8000341c:	711d                	addi	sp,sp,-96
    8000341e:	ec86                	sd	ra,88(sp)
    80003420:	e8a2                	sd	s0,80(sp)
    80003422:	e4a6                	sd	s1,72(sp)
    80003424:	e0ca                	sd	s2,64(sp)
    80003426:	fc4e                	sd	s3,56(sp)
    80003428:	f852                	sd	s4,48(sp)
    8000342a:	f456                	sd	s5,40(sp)
    8000342c:	f05a                	sd	s6,32(sp)
    8000342e:	ec5e                	sd	s7,24(sp)
    80003430:	e862                	sd	s8,16(sp)
    80003432:	e466                	sd	s9,8(sp)
    80003434:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003436:	0001d797          	auipc	a5,0x1d
    8000343a:	c1e7a783          	lw	a5,-994(a5) # 80020054 <sb+0x4>
    8000343e:	cbd1                	beqz	a5,800034d2 <balloc+0xb6>
    80003440:	8baa                	mv	s7,a0
    80003442:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003444:	0001db17          	auipc	s6,0x1d
    80003448:	c0cb0b13          	addi	s6,s6,-1012 # 80020050 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000344c:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000344e:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003450:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003452:	6c89                	lui	s9,0x2
    80003454:	a831                	j	80003470 <balloc+0x54>
    brelse(bp);
    80003456:	854a                	mv	a0,s2
    80003458:	00000097          	auipc	ra,0x0
    8000345c:	e32080e7          	jalr	-462(ra) # 8000328a <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003460:	015c87bb          	addw	a5,s9,s5
    80003464:	00078a9b          	sext.w	s5,a5
    80003468:	004b2703          	lw	a4,4(s6)
    8000346c:	06eaf363          	bgeu	s5,a4,800034d2 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003470:	41fad79b          	sraiw	a5,s5,0x1f
    80003474:	0137d79b          	srliw	a5,a5,0x13
    80003478:	015787bb          	addw	a5,a5,s5
    8000347c:	40d7d79b          	sraiw	a5,a5,0xd
    80003480:	01cb2583          	lw	a1,28(s6)
    80003484:	9dbd                	addw	a1,a1,a5
    80003486:	855e                	mv	a0,s7
    80003488:	00000097          	auipc	ra,0x0
    8000348c:	cd2080e7          	jalr	-814(ra) # 8000315a <bread>
    80003490:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003492:	004b2503          	lw	a0,4(s6)
    80003496:	000a849b          	sext.w	s1,s5
    8000349a:	8662                	mv	a2,s8
    8000349c:	faa4fde3          	bgeu	s1,a0,80003456 <balloc+0x3a>
      m = 1 << (bi % 8);
    800034a0:	41f6579b          	sraiw	a5,a2,0x1f
    800034a4:	01d7d69b          	srliw	a3,a5,0x1d
    800034a8:	00c6873b          	addw	a4,a3,a2
    800034ac:	00777793          	andi	a5,a4,7
    800034b0:	9f95                	subw	a5,a5,a3
    800034b2:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800034b6:	4037571b          	sraiw	a4,a4,0x3
    800034ba:	00e906b3          	add	a3,s2,a4
    800034be:	0586c683          	lbu	a3,88(a3)
    800034c2:	00d7f5b3          	and	a1,a5,a3
    800034c6:	cd91                	beqz	a1,800034e2 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034c8:	2605                	addiw	a2,a2,1
    800034ca:	2485                	addiw	s1,s1,1
    800034cc:	fd4618e3          	bne	a2,s4,8000349c <balloc+0x80>
    800034d0:	b759                	j	80003456 <balloc+0x3a>
  panic("balloc: out of blocks");
    800034d2:	00005517          	auipc	a0,0x5
    800034d6:	14650513          	addi	a0,a0,326 # 80008618 <syscalls+0x100>
    800034da:	ffffd097          	auipc	ra,0xffffd
    800034de:	06e080e7          	jalr	110(ra) # 80000548 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800034e2:	974a                	add	a4,a4,s2
    800034e4:	8fd5                	or	a5,a5,a3
    800034e6:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800034ea:	854a                	mv	a0,s2
    800034ec:	00001097          	auipc	ra,0x1
    800034f0:	002080e7          	jalr	2(ra) # 800044ee <log_write>
        brelse(bp);
    800034f4:	854a                	mv	a0,s2
    800034f6:	00000097          	auipc	ra,0x0
    800034fa:	d94080e7          	jalr	-620(ra) # 8000328a <brelse>
  bp = bread(dev, bno);
    800034fe:	85a6                	mv	a1,s1
    80003500:	855e                	mv	a0,s7
    80003502:	00000097          	auipc	ra,0x0
    80003506:	c58080e7          	jalr	-936(ra) # 8000315a <bread>
    8000350a:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000350c:	40000613          	li	a2,1024
    80003510:	4581                	li	a1,0
    80003512:	05850513          	addi	a0,a0,88
    80003516:	ffffd097          	auipc	ra,0xffffd
    8000351a:	7f6080e7          	jalr	2038(ra) # 80000d0c <memset>
  log_write(bp);
    8000351e:	854a                	mv	a0,s2
    80003520:	00001097          	auipc	ra,0x1
    80003524:	fce080e7          	jalr	-50(ra) # 800044ee <log_write>
  brelse(bp);
    80003528:	854a                	mv	a0,s2
    8000352a:	00000097          	auipc	ra,0x0
    8000352e:	d60080e7          	jalr	-672(ra) # 8000328a <brelse>
}
    80003532:	8526                	mv	a0,s1
    80003534:	60e6                	ld	ra,88(sp)
    80003536:	6446                	ld	s0,80(sp)
    80003538:	64a6                	ld	s1,72(sp)
    8000353a:	6906                	ld	s2,64(sp)
    8000353c:	79e2                	ld	s3,56(sp)
    8000353e:	7a42                	ld	s4,48(sp)
    80003540:	7aa2                	ld	s5,40(sp)
    80003542:	7b02                	ld	s6,32(sp)
    80003544:	6be2                	ld	s7,24(sp)
    80003546:	6c42                	ld	s8,16(sp)
    80003548:	6ca2                	ld	s9,8(sp)
    8000354a:	6125                	addi	sp,sp,96
    8000354c:	8082                	ret

000000008000354e <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000354e:	7179                	addi	sp,sp,-48
    80003550:	f406                	sd	ra,40(sp)
    80003552:	f022                	sd	s0,32(sp)
    80003554:	ec26                	sd	s1,24(sp)
    80003556:	e84a                	sd	s2,16(sp)
    80003558:	e44e                	sd	s3,8(sp)
    8000355a:	e052                	sd	s4,0(sp)
    8000355c:	1800                	addi	s0,sp,48
    8000355e:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003560:	47ad                	li	a5,11
    80003562:	04b7fe63          	bgeu	a5,a1,800035be <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003566:	ff45849b          	addiw	s1,a1,-12
    8000356a:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000356e:	0ff00793          	li	a5,255
    80003572:	0ae7e363          	bltu	a5,a4,80003618 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003576:	08052583          	lw	a1,128(a0)
    8000357a:	c5ad                	beqz	a1,800035e4 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000357c:	00092503          	lw	a0,0(s2)
    80003580:	00000097          	auipc	ra,0x0
    80003584:	bda080e7          	jalr	-1062(ra) # 8000315a <bread>
    80003588:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000358a:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000358e:	02049593          	slli	a1,s1,0x20
    80003592:	9181                	srli	a1,a1,0x20
    80003594:	058a                	slli	a1,a1,0x2
    80003596:	00b784b3          	add	s1,a5,a1
    8000359a:	0004a983          	lw	s3,0(s1)
    8000359e:	04098d63          	beqz	s3,800035f8 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800035a2:	8552                	mv	a0,s4
    800035a4:	00000097          	auipc	ra,0x0
    800035a8:	ce6080e7          	jalr	-794(ra) # 8000328a <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800035ac:	854e                	mv	a0,s3
    800035ae:	70a2                	ld	ra,40(sp)
    800035b0:	7402                	ld	s0,32(sp)
    800035b2:	64e2                	ld	s1,24(sp)
    800035b4:	6942                	ld	s2,16(sp)
    800035b6:	69a2                	ld	s3,8(sp)
    800035b8:	6a02                	ld	s4,0(sp)
    800035ba:	6145                	addi	sp,sp,48
    800035bc:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800035be:	02059493          	slli	s1,a1,0x20
    800035c2:	9081                	srli	s1,s1,0x20
    800035c4:	048a                	slli	s1,s1,0x2
    800035c6:	94aa                	add	s1,s1,a0
    800035c8:	0504a983          	lw	s3,80(s1)
    800035cc:	fe0990e3          	bnez	s3,800035ac <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800035d0:	4108                	lw	a0,0(a0)
    800035d2:	00000097          	auipc	ra,0x0
    800035d6:	e4a080e7          	jalr	-438(ra) # 8000341c <balloc>
    800035da:	0005099b          	sext.w	s3,a0
    800035de:	0534a823          	sw	s3,80(s1)
    800035e2:	b7e9                	j	800035ac <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800035e4:	4108                	lw	a0,0(a0)
    800035e6:	00000097          	auipc	ra,0x0
    800035ea:	e36080e7          	jalr	-458(ra) # 8000341c <balloc>
    800035ee:	0005059b          	sext.w	a1,a0
    800035f2:	08b92023          	sw	a1,128(s2)
    800035f6:	b759                	j	8000357c <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800035f8:	00092503          	lw	a0,0(s2)
    800035fc:	00000097          	auipc	ra,0x0
    80003600:	e20080e7          	jalr	-480(ra) # 8000341c <balloc>
    80003604:	0005099b          	sext.w	s3,a0
    80003608:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000360c:	8552                	mv	a0,s4
    8000360e:	00001097          	auipc	ra,0x1
    80003612:	ee0080e7          	jalr	-288(ra) # 800044ee <log_write>
    80003616:	b771                	j	800035a2 <bmap+0x54>
  panic("bmap: out of range");
    80003618:	00005517          	auipc	a0,0x5
    8000361c:	01850513          	addi	a0,a0,24 # 80008630 <syscalls+0x118>
    80003620:	ffffd097          	auipc	ra,0xffffd
    80003624:	f28080e7          	jalr	-216(ra) # 80000548 <panic>

0000000080003628 <iget>:
{
    80003628:	7179                	addi	sp,sp,-48
    8000362a:	f406                	sd	ra,40(sp)
    8000362c:	f022                	sd	s0,32(sp)
    8000362e:	ec26                	sd	s1,24(sp)
    80003630:	e84a                	sd	s2,16(sp)
    80003632:	e44e                	sd	s3,8(sp)
    80003634:	e052                	sd	s4,0(sp)
    80003636:	1800                	addi	s0,sp,48
    80003638:	89aa                	mv	s3,a0
    8000363a:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    8000363c:	0001d517          	auipc	a0,0x1d
    80003640:	a3450513          	addi	a0,a0,-1484 # 80020070 <icache>
    80003644:	ffffd097          	auipc	ra,0xffffd
    80003648:	5cc080e7          	jalr	1484(ra) # 80000c10 <acquire>
  empty = 0;
    8000364c:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    8000364e:	0001d497          	auipc	s1,0x1d
    80003652:	a3a48493          	addi	s1,s1,-1478 # 80020088 <icache+0x18>
    80003656:	0001e697          	auipc	a3,0x1e
    8000365a:	4c268693          	addi	a3,a3,1218 # 80021b18 <log>
    8000365e:	a039                	j	8000366c <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003660:	02090b63          	beqz	s2,80003696 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003664:	08848493          	addi	s1,s1,136
    80003668:	02d48a63          	beq	s1,a3,8000369c <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000366c:	449c                	lw	a5,8(s1)
    8000366e:	fef059e3          	blez	a5,80003660 <iget+0x38>
    80003672:	4098                	lw	a4,0(s1)
    80003674:	ff3716e3          	bne	a4,s3,80003660 <iget+0x38>
    80003678:	40d8                	lw	a4,4(s1)
    8000367a:	ff4713e3          	bne	a4,s4,80003660 <iget+0x38>
      ip->ref++;
    8000367e:	2785                	addiw	a5,a5,1
    80003680:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    80003682:	0001d517          	auipc	a0,0x1d
    80003686:	9ee50513          	addi	a0,a0,-1554 # 80020070 <icache>
    8000368a:	ffffd097          	auipc	ra,0xffffd
    8000368e:	63a080e7          	jalr	1594(ra) # 80000cc4 <release>
      return ip;
    80003692:	8926                	mv	s2,s1
    80003694:	a03d                	j	800036c2 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003696:	f7f9                	bnez	a5,80003664 <iget+0x3c>
    80003698:	8926                	mv	s2,s1
    8000369a:	b7e9                	j	80003664 <iget+0x3c>
  if(empty == 0)
    8000369c:	02090c63          	beqz	s2,800036d4 <iget+0xac>
  ip->dev = dev;
    800036a0:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800036a4:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800036a8:	4785                	li	a5,1
    800036aa:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800036ae:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    800036b2:	0001d517          	auipc	a0,0x1d
    800036b6:	9be50513          	addi	a0,a0,-1602 # 80020070 <icache>
    800036ba:	ffffd097          	auipc	ra,0xffffd
    800036be:	60a080e7          	jalr	1546(ra) # 80000cc4 <release>
}
    800036c2:	854a                	mv	a0,s2
    800036c4:	70a2                	ld	ra,40(sp)
    800036c6:	7402                	ld	s0,32(sp)
    800036c8:	64e2                	ld	s1,24(sp)
    800036ca:	6942                	ld	s2,16(sp)
    800036cc:	69a2                	ld	s3,8(sp)
    800036ce:	6a02                	ld	s4,0(sp)
    800036d0:	6145                	addi	sp,sp,48
    800036d2:	8082                	ret
    panic("iget: no inodes");
    800036d4:	00005517          	auipc	a0,0x5
    800036d8:	f7450513          	addi	a0,a0,-140 # 80008648 <syscalls+0x130>
    800036dc:	ffffd097          	auipc	ra,0xffffd
    800036e0:	e6c080e7          	jalr	-404(ra) # 80000548 <panic>

00000000800036e4 <fsinit>:
fsinit(int dev) {
    800036e4:	7179                	addi	sp,sp,-48
    800036e6:	f406                	sd	ra,40(sp)
    800036e8:	f022                	sd	s0,32(sp)
    800036ea:	ec26                	sd	s1,24(sp)
    800036ec:	e84a                	sd	s2,16(sp)
    800036ee:	e44e                	sd	s3,8(sp)
    800036f0:	1800                	addi	s0,sp,48
    800036f2:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800036f4:	4585                	li	a1,1
    800036f6:	00000097          	auipc	ra,0x0
    800036fa:	a64080e7          	jalr	-1436(ra) # 8000315a <bread>
    800036fe:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003700:	0001d997          	auipc	s3,0x1d
    80003704:	95098993          	addi	s3,s3,-1712 # 80020050 <sb>
    80003708:	02000613          	li	a2,32
    8000370c:	05850593          	addi	a1,a0,88
    80003710:	854e                	mv	a0,s3
    80003712:	ffffd097          	auipc	ra,0xffffd
    80003716:	65a080e7          	jalr	1626(ra) # 80000d6c <memmove>
  brelse(bp);
    8000371a:	8526                	mv	a0,s1
    8000371c:	00000097          	auipc	ra,0x0
    80003720:	b6e080e7          	jalr	-1170(ra) # 8000328a <brelse>
  if(sb.magic != FSMAGIC)
    80003724:	0009a703          	lw	a4,0(s3)
    80003728:	102037b7          	lui	a5,0x10203
    8000372c:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003730:	02f71263          	bne	a4,a5,80003754 <fsinit+0x70>
  initlog(dev, &sb);
    80003734:	0001d597          	auipc	a1,0x1d
    80003738:	91c58593          	addi	a1,a1,-1764 # 80020050 <sb>
    8000373c:	854a                	mv	a0,s2
    8000373e:	00001097          	auipc	ra,0x1
    80003742:	b38080e7          	jalr	-1224(ra) # 80004276 <initlog>
}
    80003746:	70a2                	ld	ra,40(sp)
    80003748:	7402                	ld	s0,32(sp)
    8000374a:	64e2                	ld	s1,24(sp)
    8000374c:	6942                	ld	s2,16(sp)
    8000374e:	69a2                	ld	s3,8(sp)
    80003750:	6145                	addi	sp,sp,48
    80003752:	8082                	ret
    panic("invalid file system");
    80003754:	00005517          	auipc	a0,0x5
    80003758:	f0450513          	addi	a0,a0,-252 # 80008658 <syscalls+0x140>
    8000375c:	ffffd097          	auipc	ra,0xffffd
    80003760:	dec080e7          	jalr	-532(ra) # 80000548 <panic>

0000000080003764 <iinit>:
{
    80003764:	7179                	addi	sp,sp,-48
    80003766:	f406                	sd	ra,40(sp)
    80003768:	f022                	sd	s0,32(sp)
    8000376a:	ec26                	sd	s1,24(sp)
    8000376c:	e84a                	sd	s2,16(sp)
    8000376e:	e44e                	sd	s3,8(sp)
    80003770:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    80003772:	00005597          	auipc	a1,0x5
    80003776:	efe58593          	addi	a1,a1,-258 # 80008670 <syscalls+0x158>
    8000377a:	0001d517          	auipc	a0,0x1d
    8000377e:	8f650513          	addi	a0,a0,-1802 # 80020070 <icache>
    80003782:	ffffd097          	auipc	ra,0xffffd
    80003786:	3fe080e7          	jalr	1022(ra) # 80000b80 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000378a:	0001d497          	auipc	s1,0x1d
    8000378e:	90e48493          	addi	s1,s1,-1778 # 80020098 <icache+0x28>
    80003792:	0001e997          	auipc	s3,0x1e
    80003796:	39698993          	addi	s3,s3,918 # 80021b28 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    8000379a:	00005917          	auipc	s2,0x5
    8000379e:	ede90913          	addi	s2,s2,-290 # 80008678 <syscalls+0x160>
    800037a2:	85ca                	mv	a1,s2
    800037a4:	8526                	mv	a0,s1
    800037a6:	00001097          	auipc	ra,0x1
    800037aa:	e36080e7          	jalr	-458(ra) # 800045dc <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800037ae:	08848493          	addi	s1,s1,136
    800037b2:	ff3498e3          	bne	s1,s3,800037a2 <iinit+0x3e>
}
    800037b6:	70a2                	ld	ra,40(sp)
    800037b8:	7402                	ld	s0,32(sp)
    800037ba:	64e2                	ld	s1,24(sp)
    800037bc:	6942                	ld	s2,16(sp)
    800037be:	69a2                	ld	s3,8(sp)
    800037c0:	6145                	addi	sp,sp,48
    800037c2:	8082                	ret

00000000800037c4 <ialloc>:
{
    800037c4:	715d                	addi	sp,sp,-80
    800037c6:	e486                	sd	ra,72(sp)
    800037c8:	e0a2                	sd	s0,64(sp)
    800037ca:	fc26                	sd	s1,56(sp)
    800037cc:	f84a                	sd	s2,48(sp)
    800037ce:	f44e                	sd	s3,40(sp)
    800037d0:	f052                	sd	s4,32(sp)
    800037d2:	ec56                	sd	s5,24(sp)
    800037d4:	e85a                	sd	s6,16(sp)
    800037d6:	e45e                	sd	s7,8(sp)
    800037d8:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800037da:	0001d717          	auipc	a4,0x1d
    800037de:	88272703          	lw	a4,-1918(a4) # 8002005c <sb+0xc>
    800037e2:	4785                	li	a5,1
    800037e4:	04e7fa63          	bgeu	a5,a4,80003838 <ialloc+0x74>
    800037e8:	8aaa                	mv	s5,a0
    800037ea:	8bae                	mv	s7,a1
    800037ec:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800037ee:	0001da17          	auipc	s4,0x1d
    800037f2:	862a0a13          	addi	s4,s4,-1950 # 80020050 <sb>
    800037f6:	00048b1b          	sext.w	s6,s1
    800037fa:	0044d593          	srli	a1,s1,0x4
    800037fe:	018a2783          	lw	a5,24(s4)
    80003802:	9dbd                	addw	a1,a1,a5
    80003804:	8556                	mv	a0,s5
    80003806:	00000097          	auipc	ra,0x0
    8000380a:	954080e7          	jalr	-1708(ra) # 8000315a <bread>
    8000380e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003810:	05850993          	addi	s3,a0,88
    80003814:	00f4f793          	andi	a5,s1,15
    80003818:	079a                	slli	a5,a5,0x6
    8000381a:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000381c:	00099783          	lh	a5,0(s3)
    80003820:	c785                	beqz	a5,80003848 <ialloc+0x84>
    brelse(bp);
    80003822:	00000097          	auipc	ra,0x0
    80003826:	a68080e7          	jalr	-1432(ra) # 8000328a <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000382a:	0485                	addi	s1,s1,1
    8000382c:	00ca2703          	lw	a4,12(s4)
    80003830:	0004879b          	sext.w	a5,s1
    80003834:	fce7e1e3          	bltu	a5,a4,800037f6 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003838:	00005517          	auipc	a0,0x5
    8000383c:	e4850513          	addi	a0,a0,-440 # 80008680 <syscalls+0x168>
    80003840:	ffffd097          	auipc	ra,0xffffd
    80003844:	d08080e7          	jalr	-760(ra) # 80000548 <panic>
      memset(dip, 0, sizeof(*dip));
    80003848:	04000613          	li	a2,64
    8000384c:	4581                	li	a1,0
    8000384e:	854e                	mv	a0,s3
    80003850:	ffffd097          	auipc	ra,0xffffd
    80003854:	4bc080e7          	jalr	1212(ra) # 80000d0c <memset>
      dip->type = type;
    80003858:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000385c:	854a                	mv	a0,s2
    8000385e:	00001097          	auipc	ra,0x1
    80003862:	c90080e7          	jalr	-880(ra) # 800044ee <log_write>
      brelse(bp);
    80003866:	854a                	mv	a0,s2
    80003868:	00000097          	auipc	ra,0x0
    8000386c:	a22080e7          	jalr	-1502(ra) # 8000328a <brelse>
      return iget(dev, inum);
    80003870:	85da                	mv	a1,s6
    80003872:	8556                	mv	a0,s5
    80003874:	00000097          	auipc	ra,0x0
    80003878:	db4080e7          	jalr	-588(ra) # 80003628 <iget>
}
    8000387c:	60a6                	ld	ra,72(sp)
    8000387e:	6406                	ld	s0,64(sp)
    80003880:	74e2                	ld	s1,56(sp)
    80003882:	7942                	ld	s2,48(sp)
    80003884:	79a2                	ld	s3,40(sp)
    80003886:	7a02                	ld	s4,32(sp)
    80003888:	6ae2                	ld	s5,24(sp)
    8000388a:	6b42                	ld	s6,16(sp)
    8000388c:	6ba2                	ld	s7,8(sp)
    8000388e:	6161                	addi	sp,sp,80
    80003890:	8082                	ret

0000000080003892 <iupdate>:
{
    80003892:	1101                	addi	sp,sp,-32
    80003894:	ec06                	sd	ra,24(sp)
    80003896:	e822                	sd	s0,16(sp)
    80003898:	e426                	sd	s1,8(sp)
    8000389a:	e04a                	sd	s2,0(sp)
    8000389c:	1000                	addi	s0,sp,32
    8000389e:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800038a0:	415c                	lw	a5,4(a0)
    800038a2:	0047d79b          	srliw	a5,a5,0x4
    800038a6:	0001c597          	auipc	a1,0x1c
    800038aa:	7c25a583          	lw	a1,1986(a1) # 80020068 <sb+0x18>
    800038ae:	9dbd                	addw	a1,a1,a5
    800038b0:	4108                	lw	a0,0(a0)
    800038b2:	00000097          	auipc	ra,0x0
    800038b6:	8a8080e7          	jalr	-1880(ra) # 8000315a <bread>
    800038ba:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800038bc:	05850793          	addi	a5,a0,88
    800038c0:	40c8                	lw	a0,4(s1)
    800038c2:	893d                	andi	a0,a0,15
    800038c4:	051a                	slli	a0,a0,0x6
    800038c6:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800038c8:	04449703          	lh	a4,68(s1)
    800038cc:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800038d0:	04649703          	lh	a4,70(s1)
    800038d4:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800038d8:	04849703          	lh	a4,72(s1)
    800038dc:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800038e0:	04a49703          	lh	a4,74(s1)
    800038e4:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800038e8:	44f8                	lw	a4,76(s1)
    800038ea:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800038ec:	03400613          	li	a2,52
    800038f0:	05048593          	addi	a1,s1,80
    800038f4:	0531                	addi	a0,a0,12
    800038f6:	ffffd097          	auipc	ra,0xffffd
    800038fa:	476080e7          	jalr	1142(ra) # 80000d6c <memmove>
  log_write(bp);
    800038fe:	854a                	mv	a0,s2
    80003900:	00001097          	auipc	ra,0x1
    80003904:	bee080e7          	jalr	-1042(ra) # 800044ee <log_write>
  brelse(bp);
    80003908:	854a                	mv	a0,s2
    8000390a:	00000097          	auipc	ra,0x0
    8000390e:	980080e7          	jalr	-1664(ra) # 8000328a <brelse>
}
    80003912:	60e2                	ld	ra,24(sp)
    80003914:	6442                	ld	s0,16(sp)
    80003916:	64a2                	ld	s1,8(sp)
    80003918:	6902                	ld	s2,0(sp)
    8000391a:	6105                	addi	sp,sp,32
    8000391c:	8082                	ret

000000008000391e <idup>:
{
    8000391e:	1101                	addi	sp,sp,-32
    80003920:	ec06                	sd	ra,24(sp)
    80003922:	e822                	sd	s0,16(sp)
    80003924:	e426                	sd	s1,8(sp)
    80003926:	1000                	addi	s0,sp,32
    80003928:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    8000392a:	0001c517          	auipc	a0,0x1c
    8000392e:	74650513          	addi	a0,a0,1862 # 80020070 <icache>
    80003932:	ffffd097          	auipc	ra,0xffffd
    80003936:	2de080e7          	jalr	734(ra) # 80000c10 <acquire>
  ip->ref++;
    8000393a:	449c                	lw	a5,8(s1)
    8000393c:	2785                	addiw	a5,a5,1
    8000393e:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003940:	0001c517          	auipc	a0,0x1c
    80003944:	73050513          	addi	a0,a0,1840 # 80020070 <icache>
    80003948:	ffffd097          	auipc	ra,0xffffd
    8000394c:	37c080e7          	jalr	892(ra) # 80000cc4 <release>
}
    80003950:	8526                	mv	a0,s1
    80003952:	60e2                	ld	ra,24(sp)
    80003954:	6442                	ld	s0,16(sp)
    80003956:	64a2                	ld	s1,8(sp)
    80003958:	6105                	addi	sp,sp,32
    8000395a:	8082                	ret

000000008000395c <ilock>:
{
    8000395c:	1101                	addi	sp,sp,-32
    8000395e:	ec06                	sd	ra,24(sp)
    80003960:	e822                	sd	s0,16(sp)
    80003962:	e426                	sd	s1,8(sp)
    80003964:	e04a                	sd	s2,0(sp)
    80003966:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003968:	c115                	beqz	a0,8000398c <ilock+0x30>
    8000396a:	84aa                	mv	s1,a0
    8000396c:	451c                	lw	a5,8(a0)
    8000396e:	00f05f63          	blez	a5,8000398c <ilock+0x30>
  acquiresleep(&ip->lock);
    80003972:	0541                	addi	a0,a0,16
    80003974:	00001097          	auipc	ra,0x1
    80003978:	ca2080e7          	jalr	-862(ra) # 80004616 <acquiresleep>
  if(ip->valid == 0){
    8000397c:	40bc                	lw	a5,64(s1)
    8000397e:	cf99                	beqz	a5,8000399c <ilock+0x40>
}
    80003980:	60e2                	ld	ra,24(sp)
    80003982:	6442                	ld	s0,16(sp)
    80003984:	64a2                	ld	s1,8(sp)
    80003986:	6902                	ld	s2,0(sp)
    80003988:	6105                	addi	sp,sp,32
    8000398a:	8082                	ret
    panic("ilock");
    8000398c:	00005517          	auipc	a0,0x5
    80003990:	d0c50513          	addi	a0,a0,-756 # 80008698 <syscalls+0x180>
    80003994:	ffffd097          	auipc	ra,0xffffd
    80003998:	bb4080e7          	jalr	-1100(ra) # 80000548 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000399c:	40dc                	lw	a5,4(s1)
    8000399e:	0047d79b          	srliw	a5,a5,0x4
    800039a2:	0001c597          	auipc	a1,0x1c
    800039a6:	6c65a583          	lw	a1,1734(a1) # 80020068 <sb+0x18>
    800039aa:	9dbd                	addw	a1,a1,a5
    800039ac:	4088                	lw	a0,0(s1)
    800039ae:	fffff097          	auipc	ra,0xfffff
    800039b2:	7ac080e7          	jalr	1964(ra) # 8000315a <bread>
    800039b6:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800039b8:	05850593          	addi	a1,a0,88
    800039bc:	40dc                	lw	a5,4(s1)
    800039be:	8bbd                	andi	a5,a5,15
    800039c0:	079a                	slli	a5,a5,0x6
    800039c2:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800039c4:	00059783          	lh	a5,0(a1)
    800039c8:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800039cc:	00259783          	lh	a5,2(a1)
    800039d0:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800039d4:	00459783          	lh	a5,4(a1)
    800039d8:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800039dc:	00659783          	lh	a5,6(a1)
    800039e0:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800039e4:	459c                	lw	a5,8(a1)
    800039e6:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800039e8:	03400613          	li	a2,52
    800039ec:	05b1                	addi	a1,a1,12
    800039ee:	05048513          	addi	a0,s1,80
    800039f2:	ffffd097          	auipc	ra,0xffffd
    800039f6:	37a080e7          	jalr	890(ra) # 80000d6c <memmove>
    brelse(bp);
    800039fa:	854a                	mv	a0,s2
    800039fc:	00000097          	auipc	ra,0x0
    80003a00:	88e080e7          	jalr	-1906(ra) # 8000328a <brelse>
    ip->valid = 1;
    80003a04:	4785                	li	a5,1
    80003a06:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003a08:	04449783          	lh	a5,68(s1)
    80003a0c:	fbb5                	bnez	a5,80003980 <ilock+0x24>
      panic("ilock: no type");
    80003a0e:	00005517          	auipc	a0,0x5
    80003a12:	c9250513          	addi	a0,a0,-878 # 800086a0 <syscalls+0x188>
    80003a16:	ffffd097          	auipc	ra,0xffffd
    80003a1a:	b32080e7          	jalr	-1230(ra) # 80000548 <panic>

0000000080003a1e <iunlock>:
{
    80003a1e:	1101                	addi	sp,sp,-32
    80003a20:	ec06                	sd	ra,24(sp)
    80003a22:	e822                	sd	s0,16(sp)
    80003a24:	e426                	sd	s1,8(sp)
    80003a26:	e04a                	sd	s2,0(sp)
    80003a28:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003a2a:	c905                	beqz	a0,80003a5a <iunlock+0x3c>
    80003a2c:	84aa                	mv	s1,a0
    80003a2e:	01050913          	addi	s2,a0,16
    80003a32:	854a                	mv	a0,s2
    80003a34:	00001097          	auipc	ra,0x1
    80003a38:	c7c080e7          	jalr	-900(ra) # 800046b0 <holdingsleep>
    80003a3c:	cd19                	beqz	a0,80003a5a <iunlock+0x3c>
    80003a3e:	449c                	lw	a5,8(s1)
    80003a40:	00f05d63          	blez	a5,80003a5a <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003a44:	854a                	mv	a0,s2
    80003a46:	00001097          	auipc	ra,0x1
    80003a4a:	c26080e7          	jalr	-986(ra) # 8000466c <releasesleep>
}
    80003a4e:	60e2                	ld	ra,24(sp)
    80003a50:	6442                	ld	s0,16(sp)
    80003a52:	64a2                	ld	s1,8(sp)
    80003a54:	6902                	ld	s2,0(sp)
    80003a56:	6105                	addi	sp,sp,32
    80003a58:	8082                	ret
    panic("iunlock");
    80003a5a:	00005517          	auipc	a0,0x5
    80003a5e:	c5650513          	addi	a0,a0,-938 # 800086b0 <syscalls+0x198>
    80003a62:	ffffd097          	auipc	ra,0xffffd
    80003a66:	ae6080e7          	jalr	-1306(ra) # 80000548 <panic>

0000000080003a6a <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003a6a:	7179                	addi	sp,sp,-48
    80003a6c:	f406                	sd	ra,40(sp)
    80003a6e:	f022                	sd	s0,32(sp)
    80003a70:	ec26                	sd	s1,24(sp)
    80003a72:	e84a                	sd	s2,16(sp)
    80003a74:	e44e                	sd	s3,8(sp)
    80003a76:	e052                	sd	s4,0(sp)
    80003a78:	1800                	addi	s0,sp,48
    80003a7a:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003a7c:	05050493          	addi	s1,a0,80
    80003a80:	08050913          	addi	s2,a0,128
    80003a84:	a021                	j	80003a8c <itrunc+0x22>
    80003a86:	0491                	addi	s1,s1,4
    80003a88:	01248d63          	beq	s1,s2,80003aa2 <itrunc+0x38>
    if(ip->addrs[i]){
    80003a8c:	408c                	lw	a1,0(s1)
    80003a8e:	dde5                	beqz	a1,80003a86 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003a90:	0009a503          	lw	a0,0(s3)
    80003a94:	00000097          	auipc	ra,0x0
    80003a98:	90c080e7          	jalr	-1780(ra) # 800033a0 <bfree>
      ip->addrs[i] = 0;
    80003a9c:	0004a023          	sw	zero,0(s1)
    80003aa0:	b7dd                	j	80003a86 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003aa2:	0809a583          	lw	a1,128(s3)
    80003aa6:	e185                	bnez	a1,80003ac6 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003aa8:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003aac:	854e                	mv	a0,s3
    80003aae:	00000097          	auipc	ra,0x0
    80003ab2:	de4080e7          	jalr	-540(ra) # 80003892 <iupdate>
}
    80003ab6:	70a2                	ld	ra,40(sp)
    80003ab8:	7402                	ld	s0,32(sp)
    80003aba:	64e2                	ld	s1,24(sp)
    80003abc:	6942                	ld	s2,16(sp)
    80003abe:	69a2                	ld	s3,8(sp)
    80003ac0:	6a02                	ld	s4,0(sp)
    80003ac2:	6145                	addi	sp,sp,48
    80003ac4:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003ac6:	0009a503          	lw	a0,0(s3)
    80003aca:	fffff097          	auipc	ra,0xfffff
    80003ace:	690080e7          	jalr	1680(ra) # 8000315a <bread>
    80003ad2:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003ad4:	05850493          	addi	s1,a0,88
    80003ad8:	45850913          	addi	s2,a0,1112
    80003adc:	a811                	j	80003af0 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003ade:	0009a503          	lw	a0,0(s3)
    80003ae2:	00000097          	auipc	ra,0x0
    80003ae6:	8be080e7          	jalr	-1858(ra) # 800033a0 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003aea:	0491                	addi	s1,s1,4
    80003aec:	01248563          	beq	s1,s2,80003af6 <itrunc+0x8c>
      if(a[j])
    80003af0:	408c                	lw	a1,0(s1)
    80003af2:	dde5                	beqz	a1,80003aea <itrunc+0x80>
    80003af4:	b7ed                	j	80003ade <itrunc+0x74>
    brelse(bp);
    80003af6:	8552                	mv	a0,s4
    80003af8:	fffff097          	auipc	ra,0xfffff
    80003afc:	792080e7          	jalr	1938(ra) # 8000328a <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003b00:	0809a583          	lw	a1,128(s3)
    80003b04:	0009a503          	lw	a0,0(s3)
    80003b08:	00000097          	auipc	ra,0x0
    80003b0c:	898080e7          	jalr	-1896(ra) # 800033a0 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003b10:	0809a023          	sw	zero,128(s3)
    80003b14:	bf51                	j	80003aa8 <itrunc+0x3e>

0000000080003b16 <iput>:
{
    80003b16:	1101                	addi	sp,sp,-32
    80003b18:	ec06                	sd	ra,24(sp)
    80003b1a:	e822                	sd	s0,16(sp)
    80003b1c:	e426                	sd	s1,8(sp)
    80003b1e:	e04a                	sd	s2,0(sp)
    80003b20:	1000                	addi	s0,sp,32
    80003b22:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003b24:	0001c517          	auipc	a0,0x1c
    80003b28:	54c50513          	addi	a0,a0,1356 # 80020070 <icache>
    80003b2c:	ffffd097          	auipc	ra,0xffffd
    80003b30:	0e4080e7          	jalr	228(ra) # 80000c10 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b34:	4498                	lw	a4,8(s1)
    80003b36:	4785                	li	a5,1
    80003b38:	02f70363          	beq	a4,a5,80003b5e <iput+0x48>
  ip->ref--;
    80003b3c:	449c                	lw	a5,8(s1)
    80003b3e:	37fd                	addiw	a5,a5,-1
    80003b40:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003b42:	0001c517          	auipc	a0,0x1c
    80003b46:	52e50513          	addi	a0,a0,1326 # 80020070 <icache>
    80003b4a:	ffffd097          	auipc	ra,0xffffd
    80003b4e:	17a080e7          	jalr	378(ra) # 80000cc4 <release>
}
    80003b52:	60e2                	ld	ra,24(sp)
    80003b54:	6442                	ld	s0,16(sp)
    80003b56:	64a2                	ld	s1,8(sp)
    80003b58:	6902                	ld	s2,0(sp)
    80003b5a:	6105                	addi	sp,sp,32
    80003b5c:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b5e:	40bc                	lw	a5,64(s1)
    80003b60:	dff1                	beqz	a5,80003b3c <iput+0x26>
    80003b62:	04a49783          	lh	a5,74(s1)
    80003b66:	fbf9                	bnez	a5,80003b3c <iput+0x26>
    acquiresleep(&ip->lock);
    80003b68:	01048913          	addi	s2,s1,16
    80003b6c:	854a                	mv	a0,s2
    80003b6e:	00001097          	auipc	ra,0x1
    80003b72:	aa8080e7          	jalr	-1368(ra) # 80004616 <acquiresleep>
    release(&icache.lock);
    80003b76:	0001c517          	auipc	a0,0x1c
    80003b7a:	4fa50513          	addi	a0,a0,1274 # 80020070 <icache>
    80003b7e:	ffffd097          	auipc	ra,0xffffd
    80003b82:	146080e7          	jalr	326(ra) # 80000cc4 <release>
    itrunc(ip);
    80003b86:	8526                	mv	a0,s1
    80003b88:	00000097          	auipc	ra,0x0
    80003b8c:	ee2080e7          	jalr	-286(ra) # 80003a6a <itrunc>
    ip->type = 0;
    80003b90:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003b94:	8526                	mv	a0,s1
    80003b96:	00000097          	auipc	ra,0x0
    80003b9a:	cfc080e7          	jalr	-772(ra) # 80003892 <iupdate>
    ip->valid = 0;
    80003b9e:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003ba2:	854a                	mv	a0,s2
    80003ba4:	00001097          	auipc	ra,0x1
    80003ba8:	ac8080e7          	jalr	-1336(ra) # 8000466c <releasesleep>
    acquire(&icache.lock);
    80003bac:	0001c517          	auipc	a0,0x1c
    80003bb0:	4c450513          	addi	a0,a0,1220 # 80020070 <icache>
    80003bb4:	ffffd097          	auipc	ra,0xffffd
    80003bb8:	05c080e7          	jalr	92(ra) # 80000c10 <acquire>
    80003bbc:	b741                	j	80003b3c <iput+0x26>

0000000080003bbe <iunlockput>:
{
    80003bbe:	1101                	addi	sp,sp,-32
    80003bc0:	ec06                	sd	ra,24(sp)
    80003bc2:	e822                	sd	s0,16(sp)
    80003bc4:	e426                	sd	s1,8(sp)
    80003bc6:	1000                	addi	s0,sp,32
    80003bc8:	84aa                	mv	s1,a0
  iunlock(ip);
    80003bca:	00000097          	auipc	ra,0x0
    80003bce:	e54080e7          	jalr	-428(ra) # 80003a1e <iunlock>
  iput(ip);
    80003bd2:	8526                	mv	a0,s1
    80003bd4:	00000097          	auipc	ra,0x0
    80003bd8:	f42080e7          	jalr	-190(ra) # 80003b16 <iput>
}
    80003bdc:	60e2                	ld	ra,24(sp)
    80003bde:	6442                	ld	s0,16(sp)
    80003be0:	64a2                	ld	s1,8(sp)
    80003be2:	6105                	addi	sp,sp,32
    80003be4:	8082                	ret

0000000080003be6 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003be6:	1141                	addi	sp,sp,-16
    80003be8:	e422                	sd	s0,8(sp)
    80003bea:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003bec:	411c                	lw	a5,0(a0)
    80003bee:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003bf0:	415c                	lw	a5,4(a0)
    80003bf2:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003bf4:	04451783          	lh	a5,68(a0)
    80003bf8:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003bfc:	04a51783          	lh	a5,74(a0)
    80003c00:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003c04:	04c56783          	lwu	a5,76(a0)
    80003c08:	e99c                	sd	a5,16(a1)
}
    80003c0a:	6422                	ld	s0,8(sp)
    80003c0c:	0141                	addi	sp,sp,16
    80003c0e:	8082                	ret

0000000080003c10 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c10:	457c                	lw	a5,76(a0)
    80003c12:	0ed7e863          	bltu	a5,a3,80003d02 <readi+0xf2>
{
    80003c16:	7159                	addi	sp,sp,-112
    80003c18:	f486                	sd	ra,104(sp)
    80003c1a:	f0a2                	sd	s0,96(sp)
    80003c1c:	eca6                	sd	s1,88(sp)
    80003c1e:	e8ca                	sd	s2,80(sp)
    80003c20:	e4ce                	sd	s3,72(sp)
    80003c22:	e0d2                	sd	s4,64(sp)
    80003c24:	fc56                	sd	s5,56(sp)
    80003c26:	f85a                	sd	s6,48(sp)
    80003c28:	f45e                	sd	s7,40(sp)
    80003c2a:	f062                	sd	s8,32(sp)
    80003c2c:	ec66                	sd	s9,24(sp)
    80003c2e:	e86a                	sd	s10,16(sp)
    80003c30:	e46e                	sd	s11,8(sp)
    80003c32:	1880                	addi	s0,sp,112
    80003c34:	8baa                	mv	s7,a0
    80003c36:	8c2e                	mv	s8,a1
    80003c38:	8ab2                	mv	s5,a2
    80003c3a:	84b6                	mv	s1,a3
    80003c3c:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003c3e:	9f35                	addw	a4,a4,a3
    return 0;
    80003c40:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003c42:	08d76f63          	bltu	a4,a3,80003ce0 <readi+0xd0>
  if(off + n > ip->size)
    80003c46:	00e7f463          	bgeu	a5,a4,80003c4e <readi+0x3e>
    n = ip->size - off;
    80003c4a:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c4e:	0a0b0863          	beqz	s6,80003cfe <readi+0xee>
    80003c52:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c54:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003c58:	5cfd                	li	s9,-1
    80003c5a:	a82d                	j	80003c94 <readi+0x84>
    80003c5c:	020a1d93          	slli	s11,s4,0x20
    80003c60:	020ddd93          	srli	s11,s11,0x20
    80003c64:	05890613          	addi	a2,s2,88
    80003c68:	86ee                	mv	a3,s11
    80003c6a:	963a                	add	a2,a2,a4
    80003c6c:	85d6                	mv	a1,s5
    80003c6e:	8562                	mv	a0,s8
    80003c70:	fffff097          	auipc	ra,0xfffff
    80003c74:	b2e080e7          	jalr	-1234(ra) # 8000279e <either_copyout>
    80003c78:	05950d63          	beq	a0,s9,80003cd2 <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    80003c7c:	854a                	mv	a0,s2
    80003c7e:	fffff097          	auipc	ra,0xfffff
    80003c82:	60c080e7          	jalr	1548(ra) # 8000328a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c86:	013a09bb          	addw	s3,s4,s3
    80003c8a:	009a04bb          	addw	s1,s4,s1
    80003c8e:	9aee                	add	s5,s5,s11
    80003c90:	0569f663          	bgeu	s3,s6,80003cdc <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003c94:	000ba903          	lw	s2,0(s7)
    80003c98:	00a4d59b          	srliw	a1,s1,0xa
    80003c9c:	855e                	mv	a0,s7
    80003c9e:	00000097          	auipc	ra,0x0
    80003ca2:	8b0080e7          	jalr	-1872(ra) # 8000354e <bmap>
    80003ca6:	0005059b          	sext.w	a1,a0
    80003caa:	854a                	mv	a0,s2
    80003cac:	fffff097          	auipc	ra,0xfffff
    80003cb0:	4ae080e7          	jalr	1198(ra) # 8000315a <bread>
    80003cb4:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cb6:	3ff4f713          	andi	a4,s1,1023
    80003cba:	40ed07bb          	subw	a5,s10,a4
    80003cbe:	413b06bb          	subw	a3,s6,s3
    80003cc2:	8a3e                	mv	s4,a5
    80003cc4:	2781                	sext.w	a5,a5
    80003cc6:	0006861b          	sext.w	a2,a3
    80003cca:	f8f679e3          	bgeu	a2,a5,80003c5c <readi+0x4c>
    80003cce:	8a36                	mv	s4,a3
    80003cd0:	b771                	j	80003c5c <readi+0x4c>
      brelse(bp);
    80003cd2:	854a                	mv	a0,s2
    80003cd4:	fffff097          	auipc	ra,0xfffff
    80003cd8:	5b6080e7          	jalr	1462(ra) # 8000328a <brelse>
  }
  return tot;
    80003cdc:	0009851b          	sext.w	a0,s3
}
    80003ce0:	70a6                	ld	ra,104(sp)
    80003ce2:	7406                	ld	s0,96(sp)
    80003ce4:	64e6                	ld	s1,88(sp)
    80003ce6:	6946                	ld	s2,80(sp)
    80003ce8:	69a6                	ld	s3,72(sp)
    80003cea:	6a06                	ld	s4,64(sp)
    80003cec:	7ae2                	ld	s5,56(sp)
    80003cee:	7b42                	ld	s6,48(sp)
    80003cf0:	7ba2                	ld	s7,40(sp)
    80003cf2:	7c02                	ld	s8,32(sp)
    80003cf4:	6ce2                	ld	s9,24(sp)
    80003cf6:	6d42                	ld	s10,16(sp)
    80003cf8:	6da2                	ld	s11,8(sp)
    80003cfa:	6165                	addi	sp,sp,112
    80003cfc:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003cfe:	89da                	mv	s3,s6
    80003d00:	bff1                	j	80003cdc <readi+0xcc>
    return 0;
    80003d02:	4501                	li	a0,0
}
    80003d04:	8082                	ret

0000000080003d06 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d06:	457c                	lw	a5,76(a0)
    80003d08:	10d7e663          	bltu	a5,a3,80003e14 <writei+0x10e>
{
    80003d0c:	7159                	addi	sp,sp,-112
    80003d0e:	f486                	sd	ra,104(sp)
    80003d10:	f0a2                	sd	s0,96(sp)
    80003d12:	eca6                	sd	s1,88(sp)
    80003d14:	e8ca                	sd	s2,80(sp)
    80003d16:	e4ce                	sd	s3,72(sp)
    80003d18:	e0d2                	sd	s4,64(sp)
    80003d1a:	fc56                	sd	s5,56(sp)
    80003d1c:	f85a                	sd	s6,48(sp)
    80003d1e:	f45e                	sd	s7,40(sp)
    80003d20:	f062                	sd	s8,32(sp)
    80003d22:	ec66                	sd	s9,24(sp)
    80003d24:	e86a                	sd	s10,16(sp)
    80003d26:	e46e                	sd	s11,8(sp)
    80003d28:	1880                	addi	s0,sp,112
    80003d2a:	8baa                	mv	s7,a0
    80003d2c:	8c2e                	mv	s8,a1
    80003d2e:	8ab2                	mv	s5,a2
    80003d30:	8936                	mv	s2,a3
    80003d32:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003d34:	00e687bb          	addw	a5,a3,a4
    80003d38:	0ed7e063          	bltu	a5,a3,80003e18 <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003d3c:	00043737          	lui	a4,0x43
    80003d40:	0cf76e63          	bltu	a4,a5,80003e1c <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d44:	0a0b0763          	beqz	s6,80003df2 <writei+0xec>
    80003d48:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d4a:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003d4e:	5cfd                	li	s9,-1
    80003d50:	a091                	j	80003d94 <writei+0x8e>
    80003d52:	02099d93          	slli	s11,s3,0x20
    80003d56:	020ddd93          	srli	s11,s11,0x20
    80003d5a:	05848513          	addi	a0,s1,88
    80003d5e:	86ee                	mv	a3,s11
    80003d60:	8656                	mv	a2,s5
    80003d62:	85e2                	mv	a1,s8
    80003d64:	953a                	add	a0,a0,a4
    80003d66:	fffff097          	auipc	ra,0xfffff
    80003d6a:	a8e080e7          	jalr	-1394(ra) # 800027f4 <either_copyin>
    80003d6e:	07950263          	beq	a0,s9,80003dd2 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003d72:	8526                	mv	a0,s1
    80003d74:	00000097          	auipc	ra,0x0
    80003d78:	77a080e7          	jalr	1914(ra) # 800044ee <log_write>
    brelse(bp);
    80003d7c:	8526                	mv	a0,s1
    80003d7e:	fffff097          	auipc	ra,0xfffff
    80003d82:	50c080e7          	jalr	1292(ra) # 8000328a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d86:	01498a3b          	addw	s4,s3,s4
    80003d8a:	0129893b          	addw	s2,s3,s2
    80003d8e:	9aee                	add	s5,s5,s11
    80003d90:	056a7663          	bgeu	s4,s6,80003ddc <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003d94:	000ba483          	lw	s1,0(s7)
    80003d98:	00a9559b          	srliw	a1,s2,0xa
    80003d9c:	855e                	mv	a0,s7
    80003d9e:	fffff097          	auipc	ra,0xfffff
    80003da2:	7b0080e7          	jalr	1968(ra) # 8000354e <bmap>
    80003da6:	0005059b          	sext.w	a1,a0
    80003daa:	8526                	mv	a0,s1
    80003dac:	fffff097          	auipc	ra,0xfffff
    80003db0:	3ae080e7          	jalr	942(ra) # 8000315a <bread>
    80003db4:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003db6:	3ff97713          	andi	a4,s2,1023
    80003dba:	40ed07bb          	subw	a5,s10,a4
    80003dbe:	414b06bb          	subw	a3,s6,s4
    80003dc2:	89be                	mv	s3,a5
    80003dc4:	2781                	sext.w	a5,a5
    80003dc6:	0006861b          	sext.w	a2,a3
    80003dca:	f8f674e3          	bgeu	a2,a5,80003d52 <writei+0x4c>
    80003dce:	89b6                	mv	s3,a3
    80003dd0:	b749                	j	80003d52 <writei+0x4c>
      brelse(bp);
    80003dd2:	8526                	mv	a0,s1
    80003dd4:	fffff097          	auipc	ra,0xfffff
    80003dd8:	4b6080e7          	jalr	1206(ra) # 8000328a <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003ddc:	04cba783          	lw	a5,76(s7)
    80003de0:	0127f463          	bgeu	a5,s2,80003de8 <writei+0xe2>
      ip->size = off;
    80003de4:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003de8:	855e                	mv	a0,s7
    80003dea:	00000097          	auipc	ra,0x0
    80003dee:	aa8080e7          	jalr	-1368(ra) # 80003892 <iupdate>
  }

  return n;
    80003df2:	000b051b          	sext.w	a0,s6
}
    80003df6:	70a6                	ld	ra,104(sp)
    80003df8:	7406                	ld	s0,96(sp)
    80003dfa:	64e6                	ld	s1,88(sp)
    80003dfc:	6946                	ld	s2,80(sp)
    80003dfe:	69a6                	ld	s3,72(sp)
    80003e00:	6a06                	ld	s4,64(sp)
    80003e02:	7ae2                	ld	s5,56(sp)
    80003e04:	7b42                	ld	s6,48(sp)
    80003e06:	7ba2                	ld	s7,40(sp)
    80003e08:	7c02                	ld	s8,32(sp)
    80003e0a:	6ce2                	ld	s9,24(sp)
    80003e0c:	6d42                	ld	s10,16(sp)
    80003e0e:	6da2                	ld	s11,8(sp)
    80003e10:	6165                	addi	sp,sp,112
    80003e12:	8082                	ret
    return -1;
    80003e14:	557d                	li	a0,-1
}
    80003e16:	8082                	ret
    return -1;
    80003e18:	557d                	li	a0,-1
    80003e1a:	bff1                	j	80003df6 <writei+0xf0>
    return -1;
    80003e1c:	557d                	li	a0,-1
    80003e1e:	bfe1                	j	80003df6 <writei+0xf0>

0000000080003e20 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003e20:	1141                	addi	sp,sp,-16
    80003e22:	e406                	sd	ra,8(sp)
    80003e24:	e022                	sd	s0,0(sp)
    80003e26:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003e28:	4639                	li	a2,14
    80003e2a:	ffffd097          	auipc	ra,0xffffd
    80003e2e:	fbe080e7          	jalr	-66(ra) # 80000de8 <strncmp>
}
    80003e32:	60a2                	ld	ra,8(sp)
    80003e34:	6402                	ld	s0,0(sp)
    80003e36:	0141                	addi	sp,sp,16
    80003e38:	8082                	ret

0000000080003e3a <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003e3a:	7139                	addi	sp,sp,-64
    80003e3c:	fc06                	sd	ra,56(sp)
    80003e3e:	f822                	sd	s0,48(sp)
    80003e40:	f426                	sd	s1,40(sp)
    80003e42:	f04a                	sd	s2,32(sp)
    80003e44:	ec4e                	sd	s3,24(sp)
    80003e46:	e852                	sd	s4,16(sp)
    80003e48:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003e4a:	04451703          	lh	a4,68(a0)
    80003e4e:	4785                	li	a5,1
    80003e50:	00f71a63          	bne	a4,a5,80003e64 <dirlookup+0x2a>
    80003e54:	892a                	mv	s2,a0
    80003e56:	89ae                	mv	s3,a1
    80003e58:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e5a:	457c                	lw	a5,76(a0)
    80003e5c:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003e5e:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e60:	e79d                	bnez	a5,80003e8e <dirlookup+0x54>
    80003e62:	a8a5                	j	80003eda <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003e64:	00005517          	auipc	a0,0x5
    80003e68:	85450513          	addi	a0,a0,-1964 # 800086b8 <syscalls+0x1a0>
    80003e6c:	ffffc097          	auipc	ra,0xffffc
    80003e70:	6dc080e7          	jalr	1756(ra) # 80000548 <panic>
      panic("dirlookup read");
    80003e74:	00005517          	auipc	a0,0x5
    80003e78:	85c50513          	addi	a0,a0,-1956 # 800086d0 <syscalls+0x1b8>
    80003e7c:	ffffc097          	auipc	ra,0xffffc
    80003e80:	6cc080e7          	jalr	1740(ra) # 80000548 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e84:	24c1                	addiw	s1,s1,16
    80003e86:	04c92783          	lw	a5,76(s2)
    80003e8a:	04f4f763          	bgeu	s1,a5,80003ed8 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e8e:	4741                	li	a4,16
    80003e90:	86a6                	mv	a3,s1
    80003e92:	fc040613          	addi	a2,s0,-64
    80003e96:	4581                	li	a1,0
    80003e98:	854a                	mv	a0,s2
    80003e9a:	00000097          	auipc	ra,0x0
    80003e9e:	d76080e7          	jalr	-650(ra) # 80003c10 <readi>
    80003ea2:	47c1                	li	a5,16
    80003ea4:	fcf518e3          	bne	a0,a5,80003e74 <dirlookup+0x3a>
    if(de.inum == 0)
    80003ea8:	fc045783          	lhu	a5,-64(s0)
    80003eac:	dfe1                	beqz	a5,80003e84 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003eae:	fc240593          	addi	a1,s0,-62
    80003eb2:	854e                	mv	a0,s3
    80003eb4:	00000097          	auipc	ra,0x0
    80003eb8:	f6c080e7          	jalr	-148(ra) # 80003e20 <namecmp>
    80003ebc:	f561                	bnez	a0,80003e84 <dirlookup+0x4a>
      if(poff)
    80003ebe:	000a0463          	beqz	s4,80003ec6 <dirlookup+0x8c>
        *poff = off;
    80003ec2:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003ec6:	fc045583          	lhu	a1,-64(s0)
    80003eca:	00092503          	lw	a0,0(s2)
    80003ece:	fffff097          	auipc	ra,0xfffff
    80003ed2:	75a080e7          	jalr	1882(ra) # 80003628 <iget>
    80003ed6:	a011                	j	80003eda <dirlookup+0xa0>
  return 0;
    80003ed8:	4501                	li	a0,0
}
    80003eda:	70e2                	ld	ra,56(sp)
    80003edc:	7442                	ld	s0,48(sp)
    80003ede:	74a2                	ld	s1,40(sp)
    80003ee0:	7902                	ld	s2,32(sp)
    80003ee2:	69e2                	ld	s3,24(sp)
    80003ee4:	6a42                	ld	s4,16(sp)
    80003ee6:	6121                	addi	sp,sp,64
    80003ee8:	8082                	ret

0000000080003eea <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003eea:	711d                	addi	sp,sp,-96
    80003eec:	ec86                	sd	ra,88(sp)
    80003eee:	e8a2                	sd	s0,80(sp)
    80003ef0:	e4a6                	sd	s1,72(sp)
    80003ef2:	e0ca                	sd	s2,64(sp)
    80003ef4:	fc4e                	sd	s3,56(sp)
    80003ef6:	f852                	sd	s4,48(sp)
    80003ef8:	f456                	sd	s5,40(sp)
    80003efa:	f05a                	sd	s6,32(sp)
    80003efc:	ec5e                	sd	s7,24(sp)
    80003efe:	e862                	sd	s8,16(sp)
    80003f00:	e466                	sd	s9,8(sp)
    80003f02:	1080                	addi	s0,sp,96
    80003f04:	84aa                	mv	s1,a0
    80003f06:	8b2e                	mv	s6,a1
    80003f08:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003f0a:	00054703          	lbu	a4,0(a0)
    80003f0e:	02f00793          	li	a5,47
    80003f12:	02f70363          	beq	a4,a5,80003f38 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003f16:	ffffe097          	auipc	ra,0xffffe
    80003f1a:	cfa080e7          	jalr	-774(ra) # 80001c10 <myproc>
    80003f1e:	15053503          	ld	a0,336(a0)
    80003f22:	00000097          	auipc	ra,0x0
    80003f26:	9fc080e7          	jalr	-1540(ra) # 8000391e <idup>
    80003f2a:	89aa                	mv	s3,a0
  while(*path == '/')
    80003f2c:	02f00913          	li	s2,47
  len = path - s;
    80003f30:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003f32:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003f34:	4c05                	li	s8,1
    80003f36:	a865                	j	80003fee <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003f38:	4585                	li	a1,1
    80003f3a:	4505                	li	a0,1
    80003f3c:	fffff097          	auipc	ra,0xfffff
    80003f40:	6ec080e7          	jalr	1772(ra) # 80003628 <iget>
    80003f44:	89aa                	mv	s3,a0
    80003f46:	b7dd                	j	80003f2c <namex+0x42>
      iunlockput(ip);
    80003f48:	854e                	mv	a0,s3
    80003f4a:	00000097          	auipc	ra,0x0
    80003f4e:	c74080e7          	jalr	-908(ra) # 80003bbe <iunlockput>
      return 0;
    80003f52:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003f54:	854e                	mv	a0,s3
    80003f56:	60e6                	ld	ra,88(sp)
    80003f58:	6446                	ld	s0,80(sp)
    80003f5a:	64a6                	ld	s1,72(sp)
    80003f5c:	6906                	ld	s2,64(sp)
    80003f5e:	79e2                	ld	s3,56(sp)
    80003f60:	7a42                	ld	s4,48(sp)
    80003f62:	7aa2                	ld	s5,40(sp)
    80003f64:	7b02                	ld	s6,32(sp)
    80003f66:	6be2                	ld	s7,24(sp)
    80003f68:	6c42                	ld	s8,16(sp)
    80003f6a:	6ca2                	ld	s9,8(sp)
    80003f6c:	6125                	addi	sp,sp,96
    80003f6e:	8082                	ret
      iunlock(ip);
    80003f70:	854e                	mv	a0,s3
    80003f72:	00000097          	auipc	ra,0x0
    80003f76:	aac080e7          	jalr	-1364(ra) # 80003a1e <iunlock>
      return ip;
    80003f7a:	bfe9                	j	80003f54 <namex+0x6a>
      iunlockput(ip);
    80003f7c:	854e                	mv	a0,s3
    80003f7e:	00000097          	auipc	ra,0x0
    80003f82:	c40080e7          	jalr	-960(ra) # 80003bbe <iunlockput>
      return 0;
    80003f86:	89d2                	mv	s3,s4
    80003f88:	b7f1                	j	80003f54 <namex+0x6a>
  len = path - s;
    80003f8a:	40b48633          	sub	a2,s1,a1
    80003f8e:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003f92:	094cd463          	bge	s9,s4,8000401a <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003f96:	4639                	li	a2,14
    80003f98:	8556                	mv	a0,s5
    80003f9a:	ffffd097          	auipc	ra,0xffffd
    80003f9e:	dd2080e7          	jalr	-558(ra) # 80000d6c <memmove>
  while(*path == '/')
    80003fa2:	0004c783          	lbu	a5,0(s1)
    80003fa6:	01279763          	bne	a5,s2,80003fb4 <namex+0xca>
    path++;
    80003faa:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003fac:	0004c783          	lbu	a5,0(s1)
    80003fb0:	ff278de3          	beq	a5,s2,80003faa <namex+0xc0>
    ilock(ip);
    80003fb4:	854e                	mv	a0,s3
    80003fb6:	00000097          	auipc	ra,0x0
    80003fba:	9a6080e7          	jalr	-1626(ra) # 8000395c <ilock>
    if(ip->type != T_DIR){
    80003fbe:	04499783          	lh	a5,68(s3)
    80003fc2:	f98793e3          	bne	a5,s8,80003f48 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003fc6:	000b0563          	beqz	s6,80003fd0 <namex+0xe6>
    80003fca:	0004c783          	lbu	a5,0(s1)
    80003fce:	d3cd                	beqz	a5,80003f70 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003fd0:	865e                	mv	a2,s7
    80003fd2:	85d6                	mv	a1,s5
    80003fd4:	854e                	mv	a0,s3
    80003fd6:	00000097          	auipc	ra,0x0
    80003fda:	e64080e7          	jalr	-412(ra) # 80003e3a <dirlookup>
    80003fde:	8a2a                	mv	s4,a0
    80003fe0:	dd51                	beqz	a0,80003f7c <namex+0x92>
    iunlockput(ip);
    80003fe2:	854e                	mv	a0,s3
    80003fe4:	00000097          	auipc	ra,0x0
    80003fe8:	bda080e7          	jalr	-1062(ra) # 80003bbe <iunlockput>
    ip = next;
    80003fec:	89d2                	mv	s3,s4
  while(*path == '/')
    80003fee:	0004c783          	lbu	a5,0(s1)
    80003ff2:	05279763          	bne	a5,s2,80004040 <namex+0x156>
    path++;
    80003ff6:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003ff8:	0004c783          	lbu	a5,0(s1)
    80003ffc:	ff278de3          	beq	a5,s2,80003ff6 <namex+0x10c>
  if(*path == 0)
    80004000:	c79d                	beqz	a5,8000402e <namex+0x144>
    path++;
    80004002:	85a6                	mv	a1,s1
  len = path - s;
    80004004:	8a5e                	mv	s4,s7
    80004006:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004008:	01278963          	beq	a5,s2,8000401a <namex+0x130>
    8000400c:	dfbd                	beqz	a5,80003f8a <namex+0xa0>
    path++;
    8000400e:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004010:	0004c783          	lbu	a5,0(s1)
    80004014:	ff279ce3          	bne	a5,s2,8000400c <namex+0x122>
    80004018:	bf8d                	j	80003f8a <namex+0xa0>
    memmove(name, s, len);
    8000401a:	2601                	sext.w	a2,a2
    8000401c:	8556                	mv	a0,s5
    8000401e:	ffffd097          	auipc	ra,0xffffd
    80004022:	d4e080e7          	jalr	-690(ra) # 80000d6c <memmove>
    name[len] = 0;
    80004026:	9a56                	add	s4,s4,s5
    80004028:	000a0023          	sb	zero,0(s4)
    8000402c:	bf9d                	j	80003fa2 <namex+0xb8>
  if(nameiparent){
    8000402e:	f20b03e3          	beqz	s6,80003f54 <namex+0x6a>
    iput(ip);
    80004032:	854e                	mv	a0,s3
    80004034:	00000097          	auipc	ra,0x0
    80004038:	ae2080e7          	jalr	-1310(ra) # 80003b16 <iput>
    return 0;
    8000403c:	4981                	li	s3,0
    8000403e:	bf19                	j	80003f54 <namex+0x6a>
  if(*path == 0)
    80004040:	d7fd                	beqz	a5,8000402e <namex+0x144>
  while(*path != '/' && *path != 0)
    80004042:	0004c783          	lbu	a5,0(s1)
    80004046:	85a6                	mv	a1,s1
    80004048:	b7d1                	j	8000400c <namex+0x122>

000000008000404a <dirlink>:
{
    8000404a:	7139                	addi	sp,sp,-64
    8000404c:	fc06                	sd	ra,56(sp)
    8000404e:	f822                	sd	s0,48(sp)
    80004050:	f426                	sd	s1,40(sp)
    80004052:	f04a                	sd	s2,32(sp)
    80004054:	ec4e                	sd	s3,24(sp)
    80004056:	e852                	sd	s4,16(sp)
    80004058:	0080                	addi	s0,sp,64
    8000405a:	892a                	mv	s2,a0
    8000405c:	8a2e                	mv	s4,a1
    8000405e:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004060:	4601                	li	a2,0
    80004062:	00000097          	auipc	ra,0x0
    80004066:	dd8080e7          	jalr	-552(ra) # 80003e3a <dirlookup>
    8000406a:	e93d                	bnez	a0,800040e0 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000406c:	04c92483          	lw	s1,76(s2)
    80004070:	c49d                	beqz	s1,8000409e <dirlink+0x54>
    80004072:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004074:	4741                	li	a4,16
    80004076:	86a6                	mv	a3,s1
    80004078:	fc040613          	addi	a2,s0,-64
    8000407c:	4581                	li	a1,0
    8000407e:	854a                	mv	a0,s2
    80004080:	00000097          	auipc	ra,0x0
    80004084:	b90080e7          	jalr	-1136(ra) # 80003c10 <readi>
    80004088:	47c1                	li	a5,16
    8000408a:	06f51163          	bne	a0,a5,800040ec <dirlink+0xa2>
    if(de.inum == 0)
    8000408e:	fc045783          	lhu	a5,-64(s0)
    80004092:	c791                	beqz	a5,8000409e <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004094:	24c1                	addiw	s1,s1,16
    80004096:	04c92783          	lw	a5,76(s2)
    8000409a:	fcf4ede3          	bltu	s1,a5,80004074 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000409e:	4639                	li	a2,14
    800040a0:	85d2                	mv	a1,s4
    800040a2:	fc240513          	addi	a0,s0,-62
    800040a6:	ffffd097          	auipc	ra,0xffffd
    800040aa:	d7e080e7          	jalr	-642(ra) # 80000e24 <strncpy>
  de.inum = inum;
    800040ae:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040b2:	4741                	li	a4,16
    800040b4:	86a6                	mv	a3,s1
    800040b6:	fc040613          	addi	a2,s0,-64
    800040ba:	4581                	li	a1,0
    800040bc:	854a                	mv	a0,s2
    800040be:	00000097          	auipc	ra,0x0
    800040c2:	c48080e7          	jalr	-952(ra) # 80003d06 <writei>
    800040c6:	872a                	mv	a4,a0
    800040c8:	47c1                	li	a5,16
  return 0;
    800040ca:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040cc:	02f71863          	bne	a4,a5,800040fc <dirlink+0xb2>
}
    800040d0:	70e2                	ld	ra,56(sp)
    800040d2:	7442                	ld	s0,48(sp)
    800040d4:	74a2                	ld	s1,40(sp)
    800040d6:	7902                	ld	s2,32(sp)
    800040d8:	69e2                	ld	s3,24(sp)
    800040da:	6a42                	ld	s4,16(sp)
    800040dc:	6121                	addi	sp,sp,64
    800040de:	8082                	ret
    iput(ip);
    800040e0:	00000097          	auipc	ra,0x0
    800040e4:	a36080e7          	jalr	-1482(ra) # 80003b16 <iput>
    return -1;
    800040e8:	557d                	li	a0,-1
    800040ea:	b7dd                	j	800040d0 <dirlink+0x86>
      panic("dirlink read");
    800040ec:	00004517          	auipc	a0,0x4
    800040f0:	5f450513          	addi	a0,a0,1524 # 800086e0 <syscalls+0x1c8>
    800040f4:	ffffc097          	auipc	ra,0xffffc
    800040f8:	454080e7          	jalr	1108(ra) # 80000548 <panic>
    panic("dirlink");
    800040fc:	00004517          	auipc	a0,0x4
    80004100:	6fc50513          	addi	a0,a0,1788 # 800087f8 <syscalls+0x2e0>
    80004104:	ffffc097          	auipc	ra,0xffffc
    80004108:	444080e7          	jalr	1092(ra) # 80000548 <panic>

000000008000410c <namei>:

struct inode*
namei(char *path)
{
    8000410c:	1101                	addi	sp,sp,-32
    8000410e:	ec06                	sd	ra,24(sp)
    80004110:	e822                	sd	s0,16(sp)
    80004112:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004114:	fe040613          	addi	a2,s0,-32
    80004118:	4581                	li	a1,0
    8000411a:	00000097          	auipc	ra,0x0
    8000411e:	dd0080e7          	jalr	-560(ra) # 80003eea <namex>
}
    80004122:	60e2                	ld	ra,24(sp)
    80004124:	6442                	ld	s0,16(sp)
    80004126:	6105                	addi	sp,sp,32
    80004128:	8082                	ret

000000008000412a <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000412a:	1141                	addi	sp,sp,-16
    8000412c:	e406                	sd	ra,8(sp)
    8000412e:	e022                	sd	s0,0(sp)
    80004130:	0800                	addi	s0,sp,16
    80004132:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004134:	4585                	li	a1,1
    80004136:	00000097          	auipc	ra,0x0
    8000413a:	db4080e7          	jalr	-588(ra) # 80003eea <namex>
}
    8000413e:	60a2                	ld	ra,8(sp)
    80004140:	6402                	ld	s0,0(sp)
    80004142:	0141                	addi	sp,sp,16
    80004144:	8082                	ret

0000000080004146 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004146:	1101                	addi	sp,sp,-32
    80004148:	ec06                	sd	ra,24(sp)
    8000414a:	e822                	sd	s0,16(sp)
    8000414c:	e426                	sd	s1,8(sp)
    8000414e:	e04a                	sd	s2,0(sp)
    80004150:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004152:	0001e917          	auipc	s2,0x1e
    80004156:	9c690913          	addi	s2,s2,-1594 # 80021b18 <log>
    8000415a:	01892583          	lw	a1,24(s2)
    8000415e:	02892503          	lw	a0,40(s2)
    80004162:	fffff097          	auipc	ra,0xfffff
    80004166:	ff8080e7          	jalr	-8(ra) # 8000315a <bread>
    8000416a:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000416c:	02c92683          	lw	a3,44(s2)
    80004170:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004172:	02d05763          	blez	a3,800041a0 <write_head+0x5a>
    80004176:	0001e797          	auipc	a5,0x1e
    8000417a:	9d278793          	addi	a5,a5,-1582 # 80021b48 <log+0x30>
    8000417e:	05c50713          	addi	a4,a0,92
    80004182:	36fd                	addiw	a3,a3,-1
    80004184:	1682                	slli	a3,a3,0x20
    80004186:	9281                	srli	a3,a3,0x20
    80004188:	068a                	slli	a3,a3,0x2
    8000418a:	0001e617          	auipc	a2,0x1e
    8000418e:	9c260613          	addi	a2,a2,-1598 # 80021b4c <log+0x34>
    80004192:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004194:	4390                	lw	a2,0(a5)
    80004196:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004198:	0791                	addi	a5,a5,4
    8000419a:	0711                	addi	a4,a4,4
    8000419c:	fed79ce3          	bne	a5,a3,80004194 <write_head+0x4e>
  }
  bwrite(buf);
    800041a0:	8526                	mv	a0,s1
    800041a2:	fffff097          	auipc	ra,0xfffff
    800041a6:	0aa080e7          	jalr	170(ra) # 8000324c <bwrite>
  brelse(buf);
    800041aa:	8526                	mv	a0,s1
    800041ac:	fffff097          	auipc	ra,0xfffff
    800041b0:	0de080e7          	jalr	222(ra) # 8000328a <brelse>
}
    800041b4:	60e2                	ld	ra,24(sp)
    800041b6:	6442                	ld	s0,16(sp)
    800041b8:	64a2                	ld	s1,8(sp)
    800041ba:	6902                	ld	s2,0(sp)
    800041bc:	6105                	addi	sp,sp,32
    800041be:	8082                	ret

00000000800041c0 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800041c0:	0001e797          	auipc	a5,0x1e
    800041c4:	9847a783          	lw	a5,-1660(a5) # 80021b44 <log+0x2c>
    800041c8:	0af05663          	blez	a5,80004274 <install_trans+0xb4>
{
    800041cc:	7139                	addi	sp,sp,-64
    800041ce:	fc06                	sd	ra,56(sp)
    800041d0:	f822                	sd	s0,48(sp)
    800041d2:	f426                	sd	s1,40(sp)
    800041d4:	f04a                	sd	s2,32(sp)
    800041d6:	ec4e                	sd	s3,24(sp)
    800041d8:	e852                	sd	s4,16(sp)
    800041da:	e456                	sd	s5,8(sp)
    800041dc:	0080                	addi	s0,sp,64
    800041de:	0001ea97          	auipc	s5,0x1e
    800041e2:	96aa8a93          	addi	s5,s5,-1686 # 80021b48 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041e6:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800041e8:	0001e997          	auipc	s3,0x1e
    800041ec:	93098993          	addi	s3,s3,-1744 # 80021b18 <log>
    800041f0:	0189a583          	lw	a1,24(s3)
    800041f4:	014585bb          	addw	a1,a1,s4
    800041f8:	2585                	addiw	a1,a1,1
    800041fa:	0289a503          	lw	a0,40(s3)
    800041fe:	fffff097          	auipc	ra,0xfffff
    80004202:	f5c080e7          	jalr	-164(ra) # 8000315a <bread>
    80004206:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004208:	000aa583          	lw	a1,0(s5)
    8000420c:	0289a503          	lw	a0,40(s3)
    80004210:	fffff097          	auipc	ra,0xfffff
    80004214:	f4a080e7          	jalr	-182(ra) # 8000315a <bread>
    80004218:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000421a:	40000613          	li	a2,1024
    8000421e:	05890593          	addi	a1,s2,88
    80004222:	05850513          	addi	a0,a0,88
    80004226:	ffffd097          	auipc	ra,0xffffd
    8000422a:	b46080e7          	jalr	-1210(ra) # 80000d6c <memmove>
    bwrite(dbuf);  // write dst to disk
    8000422e:	8526                	mv	a0,s1
    80004230:	fffff097          	auipc	ra,0xfffff
    80004234:	01c080e7          	jalr	28(ra) # 8000324c <bwrite>
    bunpin(dbuf);
    80004238:	8526                	mv	a0,s1
    8000423a:	fffff097          	auipc	ra,0xfffff
    8000423e:	12a080e7          	jalr	298(ra) # 80003364 <bunpin>
    brelse(lbuf);
    80004242:	854a                	mv	a0,s2
    80004244:	fffff097          	auipc	ra,0xfffff
    80004248:	046080e7          	jalr	70(ra) # 8000328a <brelse>
    brelse(dbuf);
    8000424c:	8526                	mv	a0,s1
    8000424e:	fffff097          	auipc	ra,0xfffff
    80004252:	03c080e7          	jalr	60(ra) # 8000328a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004256:	2a05                	addiw	s4,s4,1
    80004258:	0a91                	addi	s5,s5,4
    8000425a:	02c9a783          	lw	a5,44(s3)
    8000425e:	f8fa49e3          	blt	s4,a5,800041f0 <install_trans+0x30>
}
    80004262:	70e2                	ld	ra,56(sp)
    80004264:	7442                	ld	s0,48(sp)
    80004266:	74a2                	ld	s1,40(sp)
    80004268:	7902                	ld	s2,32(sp)
    8000426a:	69e2                	ld	s3,24(sp)
    8000426c:	6a42                	ld	s4,16(sp)
    8000426e:	6aa2                	ld	s5,8(sp)
    80004270:	6121                	addi	sp,sp,64
    80004272:	8082                	ret
    80004274:	8082                	ret

0000000080004276 <initlog>:
{
    80004276:	7179                	addi	sp,sp,-48
    80004278:	f406                	sd	ra,40(sp)
    8000427a:	f022                	sd	s0,32(sp)
    8000427c:	ec26                	sd	s1,24(sp)
    8000427e:	e84a                	sd	s2,16(sp)
    80004280:	e44e                	sd	s3,8(sp)
    80004282:	1800                	addi	s0,sp,48
    80004284:	892a                	mv	s2,a0
    80004286:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004288:	0001e497          	auipc	s1,0x1e
    8000428c:	89048493          	addi	s1,s1,-1904 # 80021b18 <log>
    80004290:	00004597          	auipc	a1,0x4
    80004294:	46058593          	addi	a1,a1,1120 # 800086f0 <syscalls+0x1d8>
    80004298:	8526                	mv	a0,s1
    8000429a:	ffffd097          	auipc	ra,0xffffd
    8000429e:	8e6080e7          	jalr	-1818(ra) # 80000b80 <initlock>
  log.start = sb->logstart;
    800042a2:	0149a583          	lw	a1,20(s3)
    800042a6:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800042a8:	0109a783          	lw	a5,16(s3)
    800042ac:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800042ae:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800042b2:	854a                	mv	a0,s2
    800042b4:	fffff097          	auipc	ra,0xfffff
    800042b8:	ea6080e7          	jalr	-346(ra) # 8000315a <bread>
  log.lh.n = lh->n;
    800042bc:	4d3c                	lw	a5,88(a0)
    800042be:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800042c0:	02f05563          	blez	a5,800042ea <initlog+0x74>
    800042c4:	05c50713          	addi	a4,a0,92
    800042c8:	0001e697          	auipc	a3,0x1e
    800042cc:	88068693          	addi	a3,a3,-1920 # 80021b48 <log+0x30>
    800042d0:	37fd                	addiw	a5,a5,-1
    800042d2:	1782                	slli	a5,a5,0x20
    800042d4:	9381                	srli	a5,a5,0x20
    800042d6:	078a                	slli	a5,a5,0x2
    800042d8:	06050613          	addi	a2,a0,96
    800042dc:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800042de:	4310                	lw	a2,0(a4)
    800042e0:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800042e2:	0711                	addi	a4,a4,4
    800042e4:	0691                	addi	a3,a3,4
    800042e6:	fef71ce3          	bne	a4,a5,800042de <initlog+0x68>
  brelse(buf);
    800042ea:	fffff097          	auipc	ra,0xfffff
    800042ee:	fa0080e7          	jalr	-96(ra) # 8000328a <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    800042f2:	00000097          	auipc	ra,0x0
    800042f6:	ece080e7          	jalr	-306(ra) # 800041c0 <install_trans>
  log.lh.n = 0;
    800042fa:	0001e797          	auipc	a5,0x1e
    800042fe:	8407a523          	sw	zero,-1974(a5) # 80021b44 <log+0x2c>
  write_head(); // clear the log
    80004302:	00000097          	auipc	ra,0x0
    80004306:	e44080e7          	jalr	-444(ra) # 80004146 <write_head>
}
    8000430a:	70a2                	ld	ra,40(sp)
    8000430c:	7402                	ld	s0,32(sp)
    8000430e:	64e2                	ld	s1,24(sp)
    80004310:	6942                	ld	s2,16(sp)
    80004312:	69a2                	ld	s3,8(sp)
    80004314:	6145                	addi	sp,sp,48
    80004316:	8082                	ret

0000000080004318 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004318:	1101                	addi	sp,sp,-32
    8000431a:	ec06                	sd	ra,24(sp)
    8000431c:	e822                	sd	s0,16(sp)
    8000431e:	e426                	sd	s1,8(sp)
    80004320:	e04a                	sd	s2,0(sp)
    80004322:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004324:	0001d517          	auipc	a0,0x1d
    80004328:	7f450513          	addi	a0,a0,2036 # 80021b18 <log>
    8000432c:	ffffd097          	auipc	ra,0xffffd
    80004330:	8e4080e7          	jalr	-1820(ra) # 80000c10 <acquire>
  while(1){
    if(log.committing){
    80004334:	0001d497          	auipc	s1,0x1d
    80004338:	7e448493          	addi	s1,s1,2020 # 80021b18 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000433c:	4979                	li	s2,30
    8000433e:	a039                	j	8000434c <begin_op+0x34>
      sleep(&log, &log.lock);
    80004340:	85a6                	mv	a1,s1
    80004342:	8526                	mv	a0,s1
    80004344:	ffffe097          	auipc	ra,0xffffe
    80004348:	1f8080e7          	jalr	504(ra) # 8000253c <sleep>
    if(log.committing){
    8000434c:	50dc                	lw	a5,36(s1)
    8000434e:	fbed                	bnez	a5,80004340 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004350:	509c                	lw	a5,32(s1)
    80004352:	0017871b          	addiw	a4,a5,1
    80004356:	0007069b          	sext.w	a3,a4
    8000435a:	0027179b          	slliw	a5,a4,0x2
    8000435e:	9fb9                	addw	a5,a5,a4
    80004360:	0017979b          	slliw	a5,a5,0x1
    80004364:	54d8                	lw	a4,44(s1)
    80004366:	9fb9                	addw	a5,a5,a4
    80004368:	00f95963          	bge	s2,a5,8000437a <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000436c:	85a6                	mv	a1,s1
    8000436e:	8526                	mv	a0,s1
    80004370:	ffffe097          	auipc	ra,0xffffe
    80004374:	1cc080e7          	jalr	460(ra) # 8000253c <sleep>
    80004378:	bfd1                	j	8000434c <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000437a:	0001d517          	auipc	a0,0x1d
    8000437e:	79e50513          	addi	a0,a0,1950 # 80021b18 <log>
    80004382:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004384:	ffffd097          	auipc	ra,0xffffd
    80004388:	940080e7          	jalr	-1728(ra) # 80000cc4 <release>
      break;
    }
  }
}
    8000438c:	60e2                	ld	ra,24(sp)
    8000438e:	6442                	ld	s0,16(sp)
    80004390:	64a2                	ld	s1,8(sp)
    80004392:	6902                	ld	s2,0(sp)
    80004394:	6105                	addi	sp,sp,32
    80004396:	8082                	ret

0000000080004398 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004398:	7139                	addi	sp,sp,-64
    8000439a:	fc06                	sd	ra,56(sp)
    8000439c:	f822                	sd	s0,48(sp)
    8000439e:	f426                	sd	s1,40(sp)
    800043a0:	f04a                	sd	s2,32(sp)
    800043a2:	ec4e                	sd	s3,24(sp)
    800043a4:	e852                	sd	s4,16(sp)
    800043a6:	e456                	sd	s5,8(sp)
    800043a8:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800043aa:	0001d497          	auipc	s1,0x1d
    800043ae:	76e48493          	addi	s1,s1,1902 # 80021b18 <log>
    800043b2:	8526                	mv	a0,s1
    800043b4:	ffffd097          	auipc	ra,0xffffd
    800043b8:	85c080e7          	jalr	-1956(ra) # 80000c10 <acquire>
  log.outstanding -= 1;
    800043bc:	509c                	lw	a5,32(s1)
    800043be:	37fd                	addiw	a5,a5,-1
    800043c0:	0007891b          	sext.w	s2,a5
    800043c4:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800043c6:	50dc                	lw	a5,36(s1)
    800043c8:	efb9                	bnez	a5,80004426 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800043ca:	06091663          	bnez	s2,80004436 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800043ce:	0001d497          	auipc	s1,0x1d
    800043d2:	74a48493          	addi	s1,s1,1866 # 80021b18 <log>
    800043d6:	4785                	li	a5,1
    800043d8:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800043da:	8526                	mv	a0,s1
    800043dc:	ffffd097          	auipc	ra,0xffffd
    800043e0:	8e8080e7          	jalr	-1816(ra) # 80000cc4 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800043e4:	54dc                	lw	a5,44(s1)
    800043e6:	06f04763          	bgtz	a5,80004454 <end_op+0xbc>
    acquire(&log.lock);
    800043ea:	0001d497          	auipc	s1,0x1d
    800043ee:	72e48493          	addi	s1,s1,1838 # 80021b18 <log>
    800043f2:	8526                	mv	a0,s1
    800043f4:	ffffd097          	auipc	ra,0xffffd
    800043f8:	81c080e7          	jalr	-2020(ra) # 80000c10 <acquire>
    log.committing = 0;
    800043fc:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004400:	8526                	mv	a0,s1
    80004402:	ffffe097          	auipc	ra,0xffffe
    80004406:	2c0080e7          	jalr	704(ra) # 800026c2 <wakeup>
    release(&log.lock);
    8000440a:	8526                	mv	a0,s1
    8000440c:	ffffd097          	auipc	ra,0xffffd
    80004410:	8b8080e7          	jalr	-1864(ra) # 80000cc4 <release>
}
    80004414:	70e2                	ld	ra,56(sp)
    80004416:	7442                	ld	s0,48(sp)
    80004418:	74a2                	ld	s1,40(sp)
    8000441a:	7902                	ld	s2,32(sp)
    8000441c:	69e2                	ld	s3,24(sp)
    8000441e:	6a42                	ld	s4,16(sp)
    80004420:	6aa2                	ld	s5,8(sp)
    80004422:	6121                	addi	sp,sp,64
    80004424:	8082                	ret
    panic("log.committing");
    80004426:	00004517          	auipc	a0,0x4
    8000442a:	2d250513          	addi	a0,a0,722 # 800086f8 <syscalls+0x1e0>
    8000442e:	ffffc097          	auipc	ra,0xffffc
    80004432:	11a080e7          	jalr	282(ra) # 80000548 <panic>
    wakeup(&log);
    80004436:	0001d497          	auipc	s1,0x1d
    8000443a:	6e248493          	addi	s1,s1,1762 # 80021b18 <log>
    8000443e:	8526                	mv	a0,s1
    80004440:	ffffe097          	auipc	ra,0xffffe
    80004444:	282080e7          	jalr	642(ra) # 800026c2 <wakeup>
  release(&log.lock);
    80004448:	8526                	mv	a0,s1
    8000444a:	ffffd097          	auipc	ra,0xffffd
    8000444e:	87a080e7          	jalr	-1926(ra) # 80000cc4 <release>
  if(do_commit){
    80004452:	b7c9                	j	80004414 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004454:	0001da97          	auipc	s5,0x1d
    80004458:	6f4a8a93          	addi	s5,s5,1780 # 80021b48 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000445c:	0001da17          	auipc	s4,0x1d
    80004460:	6bca0a13          	addi	s4,s4,1724 # 80021b18 <log>
    80004464:	018a2583          	lw	a1,24(s4)
    80004468:	012585bb          	addw	a1,a1,s2
    8000446c:	2585                	addiw	a1,a1,1
    8000446e:	028a2503          	lw	a0,40(s4)
    80004472:	fffff097          	auipc	ra,0xfffff
    80004476:	ce8080e7          	jalr	-792(ra) # 8000315a <bread>
    8000447a:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000447c:	000aa583          	lw	a1,0(s5)
    80004480:	028a2503          	lw	a0,40(s4)
    80004484:	fffff097          	auipc	ra,0xfffff
    80004488:	cd6080e7          	jalr	-810(ra) # 8000315a <bread>
    8000448c:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000448e:	40000613          	li	a2,1024
    80004492:	05850593          	addi	a1,a0,88
    80004496:	05848513          	addi	a0,s1,88
    8000449a:	ffffd097          	auipc	ra,0xffffd
    8000449e:	8d2080e7          	jalr	-1838(ra) # 80000d6c <memmove>
    bwrite(to);  // write the log
    800044a2:	8526                	mv	a0,s1
    800044a4:	fffff097          	auipc	ra,0xfffff
    800044a8:	da8080e7          	jalr	-600(ra) # 8000324c <bwrite>
    brelse(from);
    800044ac:	854e                	mv	a0,s3
    800044ae:	fffff097          	auipc	ra,0xfffff
    800044b2:	ddc080e7          	jalr	-548(ra) # 8000328a <brelse>
    brelse(to);
    800044b6:	8526                	mv	a0,s1
    800044b8:	fffff097          	auipc	ra,0xfffff
    800044bc:	dd2080e7          	jalr	-558(ra) # 8000328a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044c0:	2905                	addiw	s2,s2,1
    800044c2:	0a91                	addi	s5,s5,4
    800044c4:	02ca2783          	lw	a5,44(s4)
    800044c8:	f8f94ee3          	blt	s2,a5,80004464 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800044cc:	00000097          	auipc	ra,0x0
    800044d0:	c7a080e7          	jalr	-902(ra) # 80004146 <write_head>
    install_trans(); // Now install writes to home locations
    800044d4:	00000097          	auipc	ra,0x0
    800044d8:	cec080e7          	jalr	-788(ra) # 800041c0 <install_trans>
    log.lh.n = 0;
    800044dc:	0001d797          	auipc	a5,0x1d
    800044e0:	6607a423          	sw	zero,1640(a5) # 80021b44 <log+0x2c>
    write_head();    // Erase the transaction from the log
    800044e4:	00000097          	auipc	ra,0x0
    800044e8:	c62080e7          	jalr	-926(ra) # 80004146 <write_head>
    800044ec:	bdfd                	j	800043ea <end_op+0x52>

00000000800044ee <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800044ee:	1101                	addi	sp,sp,-32
    800044f0:	ec06                	sd	ra,24(sp)
    800044f2:	e822                	sd	s0,16(sp)
    800044f4:	e426                	sd	s1,8(sp)
    800044f6:	e04a                	sd	s2,0(sp)
    800044f8:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800044fa:	0001d717          	auipc	a4,0x1d
    800044fe:	64a72703          	lw	a4,1610(a4) # 80021b44 <log+0x2c>
    80004502:	47f5                	li	a5,29
    80004504:	08e7c063          	blt	a5,a4,80004584 <log_write+0x96>
    80004508:	84aa                	mv	s1,a0
    8000450a:	0001d797          	auipc	a5,0x1d
    8000450e:	62a7a783          	lw	a5,1578(a5) # 80021b34 <log+0x1c>
    80004512:	37fd                	addiw	a5,a5,-1
    80004514:	06f75863          	bge	a4,a5,80004584 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004518:	0001d797          	auipc	a5,0x1d
    8000451c:	6207a783          	lw	a5,1568(a5) # 80021b38 <log+0x20>
    80004520:	06f05a63          	blez	a5,80004594 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    80004524:	0001d917          	auipc	s2,0x1d
    80004528:	5f490913          	addi	s2,s2,1524 # 80021b18 <log>
    8000452c:	854a                	mv	a0,s2
    8000452e:	ffffc097          	auipc	ra,0xffffc
    80004532:	6e2080e7          	jalr	1762(ra) # 80000c10 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    80004536:	02c92603          	lw	a2,44(s2)
    8000453a:	06c05563          	blez	a2,800045a4 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000453e:	44cc                	lw	a1,12(s1)
    80004540:	0001d717          	auipc	a4,0x1d
    80004544:	60870713          	addi	a4,a4,1544 # 80021b48 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004548:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000454a:	4314                	lw	a3,0(a4)
    8000454c:	04b68d63          	beq	a3,a1,800045a6 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    80004550:	2785                	addiw	a5,a5,1
    80004552:	0711                	addi	a4,a4,4
    80004554:	fec79be3          	bne	a5,a2,8000454a <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004558:	0621                	addi	a2,a2,8
    8000455a:	060a                	slli	a2,a2,0x2
    8000455c:	0001d797          	auipc	a5,0x1d
    80004560:	5bc78793          	addi	a5,a5,1468 # 80021b18 <log>
    80004564:	963e                	add	a2,a2,a5
    80004566:	44dc                	lw	a5,12(s1)
    80004568:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000456a:	8526                	mv	a0,s1
    8000456c:	fffff097          	auipc	ra,0xfffff
    80004570:	dbc080e7          	jalr	-580(ra) # 80003328 <bpin>
    log.lh.n++;
    80004574:	0001d717          	auipc	a4,0x1d
    80004578:	5a470713          	addi	a4,a4,1444 # 80021b18 <log>
    8000457c:	575c                	lw	a5,44(a4)
    8000457e:	2785                	addiw	a5,a5,1
    80004580:	d75c                	sw	a5,44(a4)
    80004582:	a83d                	j	800045c0 <log_write+0xd2>
    panic("too big a transaction");
    80004584:	00004517          	auipc	a0,0x4
    80004588:	18450513          	addi	a0,a0,388 # 80008708 <syscalls+0x1f0>
    8000458c:	ffffc097          	auipc	ra,0xffffc
    80004590:	fbc080e7          	jalr	-68(ra) # 80000548 <panic>
    panic("log_write outside of trans");
    80004594:	00004517          	auipc	a0,0x4
    80004598:	18c50513          	addi	a0,a0,396 # 80008720 <syscalls+0x208>
    8000459c:	ffffc097          	auipc	ra,0xffffc
    800045a0:	fac080e7          	jalr	-84(ra) # 80000548 <panic>
  for (i = 0; i < log.lh.n; i++) {
    800045a4:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    800045a6:	00878713          	addi	a4,a5,8
    800045aa:	00271693          	slli	a3,a4,0x2
    800045ae:	0001d717          	auipc	a4,0x1d
    800045b2:	56a70713          	addi	a4,a4,1386 # 80021b18 <log>
    800045b6:	9736                	add	a4,a4,a3
    800045b8:	44d4                	lw	a3,12(s1)
    800045ba:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800045bc:	faf607e3          	beq	a2,a5,8000456a <log_write+0x7c>
  }
  release(&log.lock);
    800045c0:	0001d517          	auipc	a0,0x1d
    800045c4:	55850513          	addi	a0,a0,1368 # 80021b18 <log>
    800045c8:	ffffc097          	auipc	ra,0xffffc
    800045cc:	6fc080e7          	jalr	1788(ra) # 80000cc4 <release>
}
    800045d0:	60e2                	ld	ra,24(sp)
    800045d2:	6442                	ld	s0,16(sp)
    800045d4:	64a2                	ld	s1,8(sp)
    800045d6:	6902                	ld	s2,0(sp)
    800045d8:	6105                	addi	sp,sp,32
    800045da:	8082                	ret

00000000800045dc <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800045dc:	1101                	addi	sp,sp,-32
    800045de:	ec06                	sd	ra,24(sp)
    800045e0:	e822                	sd	s0,16(sp)
    800045e2:	e426                	sd	s1,8(sp)
    800045e4:	e04a                	sd	s2,0(sp)
    800045e6:	1000                	addi	s0,sp,32
    800045e8:	84aa                	mv	s1,a0
    800045ea:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800045ec:	00004597          	auipc	a1,0x4
    800045f0:	15458593          	addi	a1,a1,340 # 80008740 <syscalls+0x228>
    800045f4:	0521                	addi	a0,a0,8
    800045f6:	ffffc097          	auipc	ra,0xffffc
    800045fa:	58a080e7          	jalr	1418(ra) # 80000b80 <initlock>
  lk->name = name;
    800045fe:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004602:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004606:	0204a423          	sw	zero,40(s1)
}
    8000460a:	60e2                	ld	ra,24(sp)
    8000460c:	6442                	ld	s0,16(sp)
    8000460e:	64a2                	ld	s1,8(sp)
    80004610:	6902                	ld	s2,0(sp)
    80004612:	6105                	addi	sp,sp,32
    80004614:	8082                	ret

0000000080004616 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004616:	1101                	addi	sp,sp,-32
    80004618:	ec06                	sd	ra,24(sp)
    8000461a:	e822                	sd	s0,16(sp)
    8000461c:	e426                	sd	s1,8(sp)
    8000461e:	e04a                	sd	s2,0(sp)
    80004620:	1000                	addi	s0,sp,32
    80004622:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004624:	00850913          	addi	s2,a0,8
    80004628:	854a                	mv	a0,s2
    8000462a:	ffffc097          	auipc	ra,0xffffc
    8000462e:	5e6080e7          	jalr	1510(ra) # 80000c10 <acquire>
  while (lk->locked) {
    80004632:	409c                	lw	a5,0(s1)
    80004634:	cb89                	beqz	a5,80004646 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004636:	85ca                	mv	a1,s2
    80004638:	8526                	mv	a0,s1
    8000463a:	ffffe097          	auipc	ra,0xffffe
    8000463e:	f02080e7          	jalr	-254(ra) # 8000253c <sleep>
  while (lk->locked) {
    80004642:	409c                	lw	a5,0(s1)
    80004644:	fbed                	bnez	a5,80004636 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004646:	4785                	li	a5,1
    80004648:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000464a:	ffffd097          	auipc	ra,0xffffd
    8000464e:	5c6080e7          	jalr	1478(ra) # 80001c10 <myproc>
    80004652:	5d1c                	lw	a5,56(a0)
    80004654:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004656:	854a                	mv	a0,s2
    80004658:	ffffc097          	auipc	ra,0xffffc
    8000465c:	66c080e7          	jalr	1644(ra) # 80000cc4 <release>
}
    80004660:	60e2                	ld	ra,24(sp)
    80004662:	6442                	ld	s0,16(sp)
    80004664:	64a2                	ld	s1,8(sp)
    80004666:	6902                	ld	s2,0(sp)
    80004668:	6105                	addi	sp,sp,32
    8000466a:	8082                	ret

000000008000466c <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000466c:	1101                	addi	sp,sp,-32
    8000466e:	ec06                	sd	ra,24(sp)
    80004670:	e822                	sd	s0,16(sp)
    80004672:	e426                	sd	s1,8(sp)
    80004674:	e04a                	sd	s2,0(sp)
    80004676:	1000                	addi	s0,sp,32
    80004678:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000467a:	00850913          	addi	s2,a0,8
    8000467e:	854a                	mv	a0,s2
    80004680:	ffffc097          	auipc	ra,0xffffc
    80004684:	590080e7          	jalr	1424(ra) # 80000c10 <acquire>
  lk->locked = 0;
    80004688:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000468c:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004690:	8526                	mv	a0,s1
    80004692:	ffffe097          	auipc	ra,0xffffe
    80004696:	030080e7          	jalr	48(ra) # 800026c2 <wakeup>
  release(&lk->lk);
    8000469a:	854a                	mv	a0,s2
    8000469c:	ffffc097          	auipc	ra,0xffffc
    800046a0:	628080e7          	jalr	1576(ra) # 80000cc4 <release>
}
    800046a4:	60e2                	ld	ra,24(sp)
    800046a6:	6442                	ld	s0,16(sp)
    800046a8:	64a2                	ld	s1,8(sp)
    800046aa:	6902                	ld	s2,0(sp)
    800046ac:	6105                	addi	sp,sp,32
    800046ae:	8082                	ret

00000000800046b0 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800046b0:	7179                	addi	sp,sp,-48
    800046b2:	f406                	sd	ra,40(sp)
    800046b4:	f022                	sd	s0,32(sp)
    800046b6:	ec26                	sd	s1,24(sp)
    800046b8:	e84a                	sd	s2,16(sp)
    800046ba:	e44e                	sd	s3,8(sp)
    800046bc:	1800                	addi	s0,sp,48
    800046be:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800046c0:	00850913          	addi	s2,a0,8
    800046c4:	854a                	mv	a0,s2
    800046c6:	ffffc097          	auipc	ra,0xffffc
    800046ca:	54a080e7          	jalr	1354(ra) # 80000c10 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800046ce:	409c                	lw	a5,0(s1)
    800046d0:	ef99                	bnez	a5,800046ee <holdingsleep+0x3e>
    800046d2:	4481                	li	s1,0
  release(&lk->lk);
    800046d4:	854a                	mv	a0,s2
    800046d6:	ffffc097          	auipc	ra,0xffffc
    800046da:	5ee080e7          	jalr	1518(ra) # 80000cc4 <release>
  return r;
}
    800046de:	8526                	mv	a0,s1
    800046e0:	70a2                	ld	ra,40(sp)
    800046e2:	7402                	ld	s0,32(sp)
    800046e4:	64e2                	ld	s1,24(sp)
    800046e6:	6942                	ld	s2,16(sp)
    800046e8:	69a2                	ld	s3,8(sp)
    800046ea:	6145                	addi	sp,sp,48
    800046ec:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800046ee:	0284a983          	lw	s3,40(s1)
    800046f2:	ffffd097          	auipc	ra,0xffffd
    800046f6:	51e080e7          	jalr	1310(ra) # 80001c10 <myproc>
    800046fa:	5d04                	lw	s1,56(a0)
    800046fc:	413484b3          	sub	s1,s1,s3
    80004700:	0014b493          	seqz	s1,s1
    80004704:	bfc1                	j	800046d4 <holdingsleep+0x24>

0000000080004706 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004706:	1141                	addi	sp,sp,-16
    80004708:	e406                	sd	ra,8(sp)
    8000470a:	e022                	sd	s0,0(sp)
    8000470c:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000470e:	00004597          	auipc	a1,0x4
    80004712:	04258593          	addi	a1,a1,66 # 80008750 <syscalls+0x238>
    80004716:	0001d517          	auipc	a0,0x1d
    8000471a:	54a50513          	addi	a0,a0,1354 # 80021c60 <ftable>
    8000471e:	ffffc097          	auipc	ra,0xffffc
    80004722:	462080e7          	jalr	1122(ra) # 80000b80 <initlock>
}
    80004726:	60a2                	ld	ra,8(sp)
    80004728:	6402                	ld	s0,0(sp)
    8000472a:	0141                	addi	sp,sp,16
    8000472c:	8082                	ret

000000008000472e <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000472e:	1101                	addi	sp,sp,-32
    80004730:	ec06                	sd	ra,24(sp)
    80004732:	e822                	sd	s0,16(sp)
    80004734:	e426                	sd	s1,8(sp)
    80004736:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004738:	0001d517          	auipc	a0,0x1d
    8000473c:	52850513          	addi	a0,a0,1320 # 80021c60 <ftable>
    80004740:	ffffc097          	auipc	ra,0xffffc
    80004744:	4d0080e7          	jalr	1232(ra) # 80000c10 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004748:	0001d497          	auipc	s1,0x1d
    8000474c:	53048493          	addi	s1,s1,1328 # 80021c78 <ftable+0x18>
    80004750:	0001e717          	auipc	a4,0x1e
    80004754:	4c870713          	addi	a4,a4,1224 # 80022c18 <ftable+0xfb8>
    if(f->ref == 0){
    80004758:	40dc                	lw	a5,4(s1)
    8000475a:	cf99                	beqz	a5,80004778 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000475c:	02848493          	addi	s1,s1,40
    80004760:	fee49ce3          	bne	s1,a4,80004758 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004764:	0001d517          	auipc	a0,0x1d
    80004768:	4fc50513          	addi	a0,a0,1276 # 80021c60 <ftable>
    8000476c:	ffffc097          	auipc	ra,0xffffc
    80004770:	558080e7          	jalr	1368(ra) # 80000cc4 <release>
  return 0;
    80004774:	4481                	li	s1,0
    80004776:	a819                	j	8000478c <filealloc+0x5e>
      f->ref = 1;
    80004778:	4785                	li	a5,1
    8000477a:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000477c:	0001d517          	auipc	a0,0x1d
    80004780:	4e450513          	addi	a0,a0,1252 # 80021c60 <ftable>
    80004784:	ffffc097          	auipc	ra,0xffffc
    80004788:	540080e7          	jalr	1344(ra) # 80000cc4 <release>
}
    8000478c:	8526                	mv	a0,s1
    8000478e:	60e2                	ld	ra,24(sp)
    80004790:	6442                	ld	s0,16(sp)
    80004792:	64a2                	ld	s1,8(sp)
    80004794:	6105                	addi	sp,sp,32
    80004796:	8082                	ret

0000000080004798 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004798:	1101                	addi	sp,sp,-32
    8000479a:	ec06                	sd	ra,24(sp)
    8000479c:	e822                	sd	s0,16(sp)
    8000479e:	e426                	sd	s1,8(sp)
    800047a0:	1000                	addi	s0,sp,32
    800047a2:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800047a4:	0001d517          	auipc	a0,0x1d
    800047a8:	4bc50513          	addi	a0,a0,1212 # 80021c60 <ftable>
    800047ac:	ffffc097          	auipc	ra,0xffffc
    800047b0:	464080e7          	jalr	1124(ra) # 80000c10 <acquire>
  if(f->ref < 1)
    800047b4:	40dc                	lw	a5,4(s1)
    800047b6:	02f05263          	blez	a5,800047da <filedup+0x42>
    panic("filedup");
  f->ref++;
    800047ba:	2785                	addiw	a5,a5,1
    800047bc:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800047be:	0001d517          	auipc	a0,0x1d
    800047c2:	4a250513          	addi	a0,a0,1186 # 80021c60 <ftable>
    800047c6:	ffffc097          	auipc	ra,0xffffc
    800047ca:	4fe080e7          	jalr	1278(ra) # 80000cc4 <release>
  return f;
}
    800047ce:	8526                	mv	a0,s1
    800047d0:	60e2                	ld	ra,24(sp)
    800047d2:	6442                	ld	s0,16(sp)
    800047d4:	64a2                	ld	s1,8(sp)
    800047d6:	6105                	addi	sp,sp,32
    800047d8:	8082                	ret
    panic("filedup");
    800047da:	00004517          	auipc	a0,0x4
    800047de:	f7e50513          	addi	a0,a0,-130 # 80008758 <syscalls+0x240>
    800047e2:	ffffc097          	auipc	ra,0xffffc
    800047e6:	d66080e7          	jalr	-666(ra) # 80000548 <panic>

00000000800047ea <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800047ea:	7139                	addi	sp,sp,-64
    800047ec:	fc06                	sd	ra,56(sp)
    800047ee:	f822                	sd	s0,48(sp)
    800047f0:	f426                	sd	s1,40(sp)
    800047f2:	f04a                	sd	s2,32(sp)
    800047f4:	ec4e                	sd	s3,24(sp)
    800047f6:	e852                	sd	s4,16(sp)
    800047f8:	e456                	sd	s5,8(sp)
    800047fa:	0080                	addi	s0,sp,64
    800047fc:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800047fe:	0001d517          	auipc	a0,0x1d
    80004802:	46250513          	addi	a0,a0,1122 # 80021c60 <ftable>
    80004806:	ffffc097          	auipc	ra,0xffffc
    8000480a:	40a080e7          	jalr	1034(ra) # 80000c10 <acquire>
  if(f->ref < 1)
    8000480e:	40dc                	lw	a5,4(s1)
    80004810:	06f05163          	blez	a5,80004872 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004814:	37fd                	addiw	a5,a5,-1
    80004816:	0007871b          	sext.w	a4,a5
    8000481a:	c0dc                	sw	a5,4(s1)
    8000481c:	06e04363          	bgtz	a4,80004882 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004820:	0004a903          	lw	s2,0(s1)
    80004824:	0094ca83          	lbu	s5,9(s1)
    80004828:	0104ba03          	ld	s4,16(s1)
    8000482c:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004830:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004834:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004838:	0001d517          	auipc	a0,0x1d
    8000483c:	42850513          	addi	a0,a0,1064 # 80021c60 <ftable>
    80004840:	ffffc097          	auipc	ra,0xffffc
    80004844:	484080e7          	jalr	1156(ra) # 80000cc4 <release>

  if(ff.type == FD_PIPE){
    80004848:	4785                	li	a5,1
    8000484a:	04f90d63          	beq	s2,a5,800048a4 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000484e:	3979                	addiw	s2,s2,-2
    80004850:	4785                	li	a5,1
    80004852:	0527e063          	bltu	a5,s2,80004892 <fileclose+0xa8>
    begin_op();
    80004856:	00000097          	auipc	ra,0x0
    8000485a:	ac2080e7          	jalr	-1342(ra) # 80004318 <begin_op>
    iput(ff.ip);
    8000485e:	854e                	mv	a0,s3
    80004860:	fffff097          	auipc	ra,0xfffff
    80004864:	2b6080e7          	jalr	694(ra) # 80003b16 <iput>
    end_op();
    80004868:	00000097          	auipc	ra,0x0
    8000486c:	b30080e7          	jalr	-1232(ra) # 80004398 <end_op>
    80004870:	a00d                	j	80004892 <fileclose+0xa8>
    panic("fileclose");
    80004872:	00004517          	auipc	a0,0x4
    80004876:	eee50513          	addi	a0,a0,-274 # 80008760 <syscalls+0x248>
    8000487a:	ffffc097          	auipc	ra,0xffffc
    8000487e:	cce080e7          	jalr	-818(ra) # 80000548 <panic>
    release(&ftable.lock);
    80004882:	0001d517          	auipc	a0,0x1d
    80004886:	3de50513          	addi	a0,a0,990 # 80021c60 <ftable>
    8000488a:	ffffc097          	auipc	ra,0xffffc
    8000488e:	43a080e7          	jalr	1082(ra) # 80000cc4 <release>
  }
}
    80004892:	70e2                	ld	ra,56(sp)
    80004894:	7442                	ld	s0,48(sp)
    80004896:	74a2                	ld	s1,40(sp)
    80004898:	7902                	ld	s2,32(sp)
    8000489a:	69e2                	ld	s3,24(sp)
    8000489c:	6a42                	ld	s4,16(sp)
    8000489e:	6aa2                	ld	s5,8(sp)
    800048a0:	6121                	addi	sp,sp,64
    800048a2:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800048a4:	85d6                	mv	a1,s5
    800048a6:	8552                	mv	a0,s4
    800048a8:	00000097          	auipc	ra,0x0
    800048ac:	372080e7          	jalr	882(ra) # 80004c1a <pipeclose>
    800048b0:	b7cd                	j	80004892 <fileclose+0xa8>

00000000800048b2 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800048b2:	715d                	addi	sp,sp,-80
    800048b4:	e486                	sd	ra,72(sp)
    800048b6:	e0a2                	sd	s0,64(sp)
    800048b8:	fc26                	sd	s1,56(sp)
    800048ba:	f84a                	sd	s2,48(sp)
    800048bc:	f44e                	sd	s3,40(sp)
    800048be:	0880                	addi	s0,sp,80
    800048c0:	84aa                	mv	s1,a0
    800048c2:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800048c4:	ffffd097          	auipc	ra,0xffffd
    800048c8:	34c080e7          	jalr	844(ra) # 80001c10 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800048cc:	409c                	lw	a5,0(s1)
    800048ce:	37f9                	addiw	a5,a5,-2
    800048d0:	4705                	li	a4,1
    800048d2:	04f76763          	bltu	a4,a5,80004920 <filestat+0x6e>
    800048d6:	892a                	mv	s2,a0
    ilock(f->ip);
    800048d8:	6c88                	ld	a0,24(s1)
    800048da:	fffff097          	auipc	ra,0xfffff
    800048de:	082080e7          	jalr	130(ra) # 8000395c <ilock>
    stati(f->ip, &st);
    800048e2:	fb840593          	addi	a1,s0,-72
    800048e6:	6c88                	ld	a0,24(s1)
    800048e8:	fffff097          	auipc	ra,0xfffff
    800048ec:	2fe080e7          	jalr	766(ra) # 80003be6 <stati>
    iunlock(f->ip);
    800048f0:	6c88                	ld	a0,24(s1)
    800048f2:	fffff097          	auipc	ra,0xfffff
    800048f6:	12c080e7          	jalr	300(ra) # 80003a1e <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800048fa:	46e1                	li	a3,24
    800048fc:	fb840613          	addi	a2,s0,-72
    80004900:	85ce                	mv	a1,s3
    80004902:	05093503          	ld	a0,80(s2)
    80004906:	ffffd097          	auipc	ra,0xffffd
    8000490a:	fe2080e7          	jalr	-30(ra) # 800018e8 <copyout>
    8000490e:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004912:	60a6                	ld	ra,72(sp)
    80004914:	6406                	ld	s0,64(sp)
    80004916:	74e2                	ld	s1,56(sp)
    80004918:	7942                	ld	s2,48(sp)
    8000491a:	79a2                	ld	s3,40(sp)
    8000491c:	6161                	addi	sp,sp,80
    8000491e:	8082                	ret
  return -1;
    80004920:	557d                	li	a0,-1
    80004922:	bfc5                	j	80004912 <filestat+0x60>

0000000080004924 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004924:	7179                	addi	sp,sp,-48
    80004926:	f406                	sd	ra,40(sp)
    80004928:	f022                	sd	s0,32(sp)
    8000492a:	ec26                	sd	s1,24(sp)
    8000492c:	e84a                	sd	s2,16(sp)
    8000492e:	e44e                	sd	s3,8(sp)
    80004930:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004932:	00854783          	lbu	a5,8(a0)
    80004936:	c3d5                	beqz	a5,800049da <fileread+0xb6>
    80004938:	84aa                	mv	s1,a0
    8000493a:	89ae                	mv	s3,a1
    8000493c:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000493e:	411c                	lw	a5,0(a0)
    80004940:	4705                	li	a4,1
    80004942:	04e78963          	beq	a5,a4,80004994 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004946:	470d                	li	a4,3
    80004948:	04e78d63          	beq	a5,a4,800049a2 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000494c:	4709                	li	a4,2
    8000494e:	06e79e63          	bne	a5,a4,800049ca <fileread+0xa6>
    ilock(f->ip);
    80004952:	6d08                	ld	a0,24(a0)
    80004954:	fffff097          	auipc	ra,0xfffff
    80004958:	008080e7          	jalr	8(ra) # 8000395c <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000495c:	874a                	mv	a4,s2
    8000495e:	5094                	lw	a3,32(s1)
    80004960:	864e                	mv	a2,s3
    80004962:	4585                	li	a1,1
    80004964:	6c88                	ld	a0,24(s1)
    80004966:	fffff097          	auipc	ra,0xfffff
    8000496a:	2aa080e7          	jalr	682(ra) # 80003c10 <readi>
    8000496e:	892a                	mv	s2,a0
    80004970:	00a05563          	blez	a0,8000497a <fileread+0x56>
      f->off += r;
    80004974:	509c                	lw	a5,32(s1)
    80004976:	9fa9                	addw	a5,a5,a0
    80004978:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000497a:	6c88                	ld	a0,24(s1)
    8000497c:	fffff097          	auipc	ra,0xfffff
    80004980:	0a2080e7          	jalr	162(ra) # 80003a1e <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004984:	854a                	mv	a0,s2
    80004986:	70a2                	ld	ra,40(sp)
    80004988:	7402                	ld	s0,32(sp)
    8000498a:	64e2                	ld	s1,24(sp)
    8000498c:	6942                	ld	s2,16(sp)
    8000498e:	69a2                	ld	s3,8(sp)
    80004990:	6145                	addi	sp,sp,48
    80004992:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004994:	6908                	ld	a0,16(a0)
    80004996:	00000097          	auipc	ra,0x0
    8000499a:	418080e7          	jalr	1048(ra) # 80004dae <piperead>
    8000499e:	892a                	mv	s2,a0
    800049a0:	b7d5                	j	80004984 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800049a2:	02451783          	lh	a5,36(a0)
    800049a6:	03079693          	slli	a3,a5,0x30
    800049aa:	92c1                	srli	a3,a3,0x30
    800049ac:	4725                	li	a4,9
    800049ae:	02d76863          	bltu	a4,a3,800049de <fileread+0xba>
    800049b2:	0792                	slli	a5,a5,0x4
    800049b4:	0001d717          	auipc	a4,0x1d
    800049b8:	20c70713          	addi	a4,a4,524 # 80021bc0 <devsw>
    800049bc:	97ba                	add	a5,a5,a4
    800049be:	639c                	ld	a5,0(a5)
    800049c0:	c38d                	beqz	a5,800049e2 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800049c2:	4505                	li	a0,1
    800049c4:	9782                	jalr	a5
    800049c6:	892a                	mv	s2,a0
    800049c8:	bf75                	j	80004984 <fileread+0x60>
    panic("fileread");
    800049ca:	00004517          	auipc	a0,0x4
    800049ce:	da650513          	addi	a0,a0,-602 # 80008770 <syscalls+0x258>
    800049d2:	ffffc097          	auipc	ra,0xffffc
    800049d6:	b76080e7          	jalr	-1162(ra) # 80000548 <panic>
    return -1;
    800049da:	597d                	li	s2,-1
    800049dc:	b765                	j	80004984 <fileread+0x60>
      return -1;
    800049de:	597d                	li	s2,-1
    800049e0:	b755                	j	80004984 <fileread+0x60>
    800049e2:	597d                	li	s2,-1
    800049e4:	b745                	j	80004984 <fileread+0x60>

00000000800049e6 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    800049e6:	00954783          	lbu	a5,9(a0)
    800049ea:	14078563          	beqz	a5,80004b34 <filewrite+0x14e>
{
    800049ee:	715d                	addi	sp,sp,-80
    800049f0:	e486                	sd	ra,72(sp)
    800049f2:	e0a2                	sd	s0,64(sp)
    800049f4:	fc26                	sd	s1,56(sp)
    800049f6:	f84a                	sd	s2,48(sp)
    800049f8:	f44e                	sd	s3,40(sp)
    800049fa:	f052                	sd	s4,32(sp)
    800049fc:	ec56                	sd	s5,24(sp)
    800049fe:	e85a                	sd	s6,16(sp)
    80004a00:	e45e                	sd	s7,8(sp)
    80004a02:	e062                	sd	s8,0(sp)
    80004a04:	0880                	addi	s0,sp,80
    80004a06:	892a                	mv	s2,a0
    80004a08:	8aae                	mv	s5,a1
    80004a0a:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004a0c:	411c                	lw	a5,0(a0)
    80004a0e:	4705                	li	a4,1
    80004a10:	02e78263          	beq	a5,a4,80004a34 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a14:	470d                	li	a4,3
    80004a16:	02e78563          	beq	a5,a4,80004a40 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a1a:	4709                	li	a4,2
    80004a1c:	10e79463          	bne	a5,a4,80004b24 <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004a20:	0ec05e63          	blez	a2,80004b1c <filewrite+0x136>
    int i = 0;
    80004a24:	4981                	li	s3,0
    80004a26:	6b05                	lui	s6,0x1
    80004a28:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004a2c:	6b85                	lui	s7,0x1
    80004a2e:	c00b8b9b          	addiw	s7,s7,-1024
    80004a32:	a851                	j	80004ac6 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004a34:	6908                	ld	a0,16(a0)
    80004a36:	00000097          	auipc	ra,0x0
    80004a3a:	254080e7          	jalr	596(ra) # 80004c8a <pipewrite>
    80004a3e:	a85d                	j	80004af4 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004a40:	02451783          	lh	a5,36(a0)
    80004a44:	03079693          	slli	a3,a5,0x30
    80004a48:	92c1                	srli	a3,a3,0x30
    80004a4a:	4725                	li	a4,9
    80004a4c:	0ed76663          	bltu	a4,a3,80004b38 <filewrite+0x152>
    80004a50:	0792                	slli	a5,a5,0x4
    80004a52:	0001d717          	auipc	a4,0x1d
    80004a56:	16e70713          	addi	a4,a4,366 # 80021bc0 <devsw>
    80004a5a:	97ba                	add	a5,a5,a4
    80004a5c:	679c                	ld	a5,8(a5)
    80004a5e:	cff9                	beqz	a5,80004b3c <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    80004a60:	4505                	li	a0,1
    80004a62:	9782                	jalr	a5
    80004a64:	a841                	j	80004af4 <filewrite+0x10e>
    80004a66:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004a6a:	00000097          	auipc	ra,0x0
    80004a6e:	8ae080e7          	jalr	-1874(ra) # 80004318 <begin_op>
      ilock(f->ip);
    80004a72:	01893503          	ld	a0,24(s2)
    80004a76:	fffff097          	auipc	ra,0xfffff
    80004a7a:	ee6080e7          	jalr	-282(ra) # 8000395c <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004a7e:	8762                	mv	a4,s8
    80004a80:	02092683          	lw	a3,32(s2)
    80004a84:	01598633          	add	a2,s3,s5
    80004a88:	4585                	li	a1,1
    80004a8a:	01893503          	ld	a0,24(s2)
    80004a8e:	fffff097          	auipc	ra,0xfffff
    80004a92:	278080e7          	jalr	632(ra) # 80003d06 <writei>
    80004a96:	84aa                	mv	s1,a0
    80004a98:	02a05f63          	blez	a0,80004ad6 <filewrite+0xf0>
        f->off += r;
    80004a9c:	02092783          	lw	a5,32(s2)
    80004aa0:	9fa9                	addw	a5,a5,a0
    80004aa2:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004aa6:	01893503          	ld	a0,24(s2)
    80004aaa:	fffff097          	auipc	ra,0xfffff
    80004aae:	f74080e7          	jalr	-140(ra) # 80003a1e <iunlock>
      end_op();
    80004ab2:	00000097          	auipc	ra,0x0
    80004ab6:	8e6080e7          	jalr	-1818(ra) # 80004398 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004aba:	049c1963          	bne	s8,s1,80004b0c <filewrite+0x126>
        panic("short filewrite");
      i += r;
    80004abe:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004ac2:	0349d663          	bge	s3,s4,80004aee <filewrite+0x108>
      int n1 = n - i;
    80004ac6:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004aca:	84be                	mv	s1,a5
    80004acc:	2781                	sext.w	a5,a5
    80004ace:	f8fb5ce3          	bge	s6,a5,80004a66 <filewrite+0x80>
    80004ad2:	84de                	mv	s1,s7
    80004ad4:	bf49                	j	80004a66 <filewrite+0x80>
      iunlock(f->ip);
    80004ad6:	01893503          	ld	a0,24(s2)
    80004ada:	fffff097          	auipc	ra,0xfffff
    80004ade:	f44080e7          	jalr	-188(ra) # 80003a1e <iunlock>
      end_op();
    80004ae2:	00000097          	auipc	ra,0x0
    80004ae6:	8b6080e7          	jalr	-1866(ra) # 80004398 <end_op>
      if(r < 0)
    80004aea:	fc04d8e3          	bgez	s1,80004aba <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80004aee:	8552                	mv	a0,s4
    80004af0:	033a1863          	bne	s4,s3,80004b20 <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004af4:	60a6                	ld	ra,72(sp)
    80004af6:	6406                	ld	s0,64(sp)
    80004af8:	74e2                	ld	s1,56(sp)
    80004afa:	7942                	ld	s2,48(sp)
    80004afc:	79a2                	ld	s3,40(sp)
    80004afe:	7a02                	ld	s4,32(sp)
    80004b00:	6ae2                	ld	s5,24(sp)
    80004b02:	6b42                	ld	s6,16(sp)
    80004b04:	6ba2                	ld	s7,8(sp)
    80004b06:	6c02                	ld	s8,0(sp)
    80004b08:	6161                	addi	sp,sp,80
    80004b0a:	8082                	ret
        panic("short filewrite");
    80004b0c:	00004517          	auipc	a0,0x4
    80004b10:	c7450513          	addi	a0,a0,-908 # 80008780 <syscalls+0x268>
    80004b14:	ffffc097          	auipc	ra,0xffffc
    80004b18:	a34080e7          	jalr	-1484(ra) # 80000548 <panic>
    int i = 0;
    80004b1c:	4981                	li	s3,0
    80004b1e:	bfc1                	j	80004aee <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004b20:	557d                	li	a0,-1
    80004b22:	bfc9                	j	80004af4 <filewrite+0x10e>
    panic("filewrite");
    80004b24:	00004517          	auipc	a0,0x4
    80004b28:	c6c50513          	addi	a0,a0,-916 # 80008790 <syscalls+0x278>
    80004b2c:	ffffc097          	auipc	ra,0xffffc
    80004b30:	a1c080e7          	jalr	-1508(ra) # 80000548 <panic>
    return -1;
    80004b34:	557d                	li	a0,-1
}
    80004b36:	8082                	ret
      return -1;
    80004b38:	557d                	li	a0,-1
    80004b3a:	bf6d                	j	80004af4 <filewrite+0x10e>
    80004b3c:	557d                	li	a0,-1
    80004b3e:	bf5d                	j	80004af4 <filewrite+0x10e>

0000000080004b40 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004b40:	7179                	addi	sp,sp,-48
    80004b42:	f406                	sd	ra,40(sp)
    80004b44:	f022                	sd	s0,32(sp)
    80004b46:	ec26                	sd	s1,24(sp)
    80004b48:	e84a                	sd	s2,16(sp)
    80004b4a:	e44e                	sd	s3,8(sp)
    80004b4c:	e052                	sd	s4,0(sp)
    80004b4e:	1800                	addi	s0,sp,48
    80004b50:	84aa                	mv	s1,a0
    80004b52:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004b54:	0005b023          	sd	zero,0(a1)
    80004b58:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004b5c:	00000097          	auipc	ra,0x0
    80004b60:	bd2080e7          	jalr	-1070(ra) # 8000472e <filealloc>
    80004b64:	e088                	sd	a0,0(s1)
    80004b66:	c551                	beqz	a0,80004bf2 <pipealloc+0xb2>
    80004b68:	00000097          	auipc	ra,0x0
    80004b6c:	bc6080e7          	jalr	-1082(ra) # 8000472e <filealloc>
    80004b70:	00aa3023          	sd	a0,0(s4)
    80004b74:	c92d                	beqz	a0,80004be6 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004b76:	ffffc097          	auipc	ra,0xffffc
    80004b7a:	faa080e7          	jalr	-86(ra) # 80000b20 <kalloc>
    80004b7e:	892a                	mv	s2,a0
    80004b80:	c125                	beqz	a0,80004be0 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004b82:	4985                	li	s3,1
    80004b84:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004b88:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004b8c:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004b90:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004b94:	00004597          	auipc	a1,0x4
    80004b98:	c0c58593          	addi	a1,a1,-1012 # 800087a0 <syscalls+0x288>
    80004b9c:	ffffc097          	auipc	ra,0xffffc
    80004ba0:	fe4080e7          	jalr	-28(ra) # 80000b80 <initlock>
  (*f0)->type = FD_PIPE;
    80004ba4:	609c                	ld	a5,0(s1)
    80004ba6:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004baa:	609c                	ld	a5,0(s1)
    80004bac:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004bb0:	609c                	ld	a5,0(s1)
    80004bb2:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004bb6:	609c                	ld	a5,0(s1)
    80004bb8:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004bbc:	000a3783          	ld	a5,0(s4)
    80004bc0:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004bc4:	000a3783          	ld	a5,0(s4)
    80004bc8:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004bcc:	000a3783          	ld	a5,0(s4)
    80004bd0:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004bd4:	000a3783          	ld	a5,0(s4)
    80004bd8:	0127b823          	sd	s2,16(a5)
  return 0;
    80004bdc:	4501                	li	a0,0
    80004bde:	a025                	j	80004c06 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004be0:	6088                	ld	a0,0(s1)
    80004be2:	e501                	bnez	a0,80004bea <pipealloc+0xaa>
    80004be4:	a039                	j	80004bf2 <pipealloc+0xb2>
    80004be6:	6088                	ld	a0,0(s1)
    80004be8:	c51d                	beqz	a0,80004c16 <pipealloc+0xd6>
    fileclose(*f0);
    80004bea:	00000097          	auipc	ra,0x0
    80004bee:	c00080e7          	jalr	-1024(ra) # 800047ea <fileclose>
  if(*f1)
    80004bf2:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004bf6:	557d                	li	a0,-1
  if(*f1)
    80004bf8:	c799                	beqz	a5,80004c06 <pipealloc+0xc6>
    fileclose(*f1);
    80004bfa:	853e                	mv	a0,a5
    80004bfc:	00000097          	auipc	ra,0x0
    80004c00:	bee080e7          	jalr	-1042(ra) # 800047ea <fileclose>
  return -1;
    80004c04:	557d                	li	a0,-1
}
    80004c06:	70a2                	ld	ra,40(sp)
    80004c08:	7402                	ld	s0,32(sp)
    80004c0a:	64e2                	ld	s1,24(sp)
    80004c0c:	6942                	ld	s2,16(sp)
    80004c0e:	69a2                	ld	s3,8(sp)
    80004c10:	6a02                	ld	s4,0(sp)
    80004c12:	6145                	addi	sp,sp,48
    80004c14:	8082                	ret
  return -1;
    80004c16:	557d                	li	a0,-1
    80004c18:	b7fd                	j	80004c06 <pipealloc+0xc6>

0000000080004c1a <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004c1a:	1101                	addi	sp,sp,-32
    80004c1c:	ec06                	sd	ra,24(sp)
    80004c1e:	e822                	sd	s0,16(sp)
    80004c20:	e426                	sd	s1,8(sp)
    80004c22:	e04a                	sd	s2,0(sp)
    80004c24:	1000                	addi	s0,sp,32
    80004c26:	84aa                	mv	s1,a0
    80004c28:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004c2a:	ffffc097          	auipc	ra,0xffffc
    80004c2e:	fe6080e7          	jalr	-26(ra) # 80000c10 <acquire>
  if(writable){
    80004c32:	02090d63          	beqz	s2,80004c6c <pipeclose+0x52>
    pi->writeopen = 0;
    80004c36:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004c3a:	21848513          	addi	a0,s1,536
    80004c3e:	ffffe097          	auipc	ra,0xffffe
    80004c42:	a84080e7          	jalr	-1404(ra) # 800026c2 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004c46:	2204b783          	ld	a5,544(s1)
    80004c4a:	eb95                	bnez	a5,80004c7e <pipeclose+0x64>
    release(&pi->lock);
    80004c4c:	8526                	mv	a0,s1
    80004c4e:	ffffc097          	auipc	ra,0xffffc
    80004c52:	076080e7          	jalr	118(ra) # 80000cc4 <release>
    kfree((char*)pi);
    80004c56:	8526                	mv	a0,s1
    80004c58:	ffffc097          	auipc	ra,0xffffc
    80004c5c:	dcc080e7          	jalr	-564(ra) # 80000a24 <kfree>
  } else
    release(&pi->lock);
}
    80004c60:	60e2                	ld	ra,24(sp)
    80004c62:	6442                	ld	s0,16(sp)
    80004c64:	64a2                	ld	s1,8(sp)
    80004c66:	6902                	ld	s2,0(sp)
    80004c68:	6105                	addi	sp,sp,32
    80004c6a:	8082                	ret
    pi->readopen = 0;
    80004c6c:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004c70:	21c48513          	addi	a0,s1,540
    80004c74:	ffffe097          	auipc	ra,0xffffe
    80004c78:	a4e080e7          	jalr	-1458(ra) # 800026c2 <wakeup>
    80004c7c:	b7e9                	j	80004c46 <pipeclose+0x2c>
    release(&pi->lock);
    80004c7e:	8526                	mv	a0,s1
    80004c80:	ffffc097          	auipc	ra,0xffffc
    80004c84:	044080e7          	jalr	68(ra) # 80000cc4 <release>
}
    80004c88:	bfe1                	j	80004c60 <pipeclose+0x46>

0000000080004c8a <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004c8a:	7119                	addi	sp,sp,-128
    80004c8c:	fc86                	sd	ra,120(sp)
    80004c8e:	f8a2                	sd	s0,112(sp)
    80004c90:	f4a6                	sd	s1,104(sp)
    80004c92:	f0ca                	sd	s2,96(sp)
    80004c94:	ecce                	sd	s3,88(sp)
    80004c96:	e8d2                	sd	s4,80(sp)
    80004c98:	e4d6                	sd	s5,72(sp)
    80004c9a:	e0da                	sd	s6,64(sp)
    80004c9c:	fc5e                	sd	s7,56(sp)
    80004c9e:	f862                	sd	s8,48(sp)
    80004ca0:	f466                	sd	s9,40(sp)
    80004ca2:	f06a                	sd	s10,32(sp)
    80004ca4:	ec6e                	sd	s11,24(sp)
    80004ca6:	0100                	addi	s0,sp,128
    80004ca8:	84aa                	mv	s1,a0
    80004caa:	8cae                	mv	s9,a1
    80004cac:	8b32                	mv	s6,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004cae:	ffffd097          	auipc	ra,0xffffd
    80004cb2:	f62080e7          	jalr	-158(ra) # 80001c10 <myproc>
    80004cb6:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004cb8:	8526                	mv	a0,s1
    80004cba:	ffffc097          	auipc	ra,0xffffc
    80004cbe:	f56080e7          	jalr	-170(ra) # 80000c10 <acquire>
  for(i = 0; i < n; i++){
    80004cc2:	0d605963          	blez	s6,80004d94 <pipewrite+0x10a>
    80004cc6:	89a6                	mv	s3,s1
    80004cc8:	3b7d                	addiw	s6,s6,-1
    80004cca:	1b02                	slli	s6,s6,0x20
    80004ccc:	020b5b13          	srli	s6,s6,0x20
    80004cd0:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004cd2:	21848a93          	addi	s5,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004cd6:	21c48a13          	addi	s4,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004cda:	5dfd                	li	s11,-1
    80004cdc:	000b8d1b          	sext.w	s10,s7
    80004ce0:	8c6a                	mv	s8,s10
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004ce2:	2184a783          	lw	a5,536(s1)
    80004ce6:	21c4a703          	lw	a4,540(s1)
    80004cea:	2007879b          	addiw	a5,a5,512
    80004cee:	02f71b63          	bne	a4,a5,80004d24 <pipewrite+0x9a>
      if(pi->readopen == 0 || pr->killed){
    80004cf2:	2204a783          	lw	a5,544(s1)
    80004cf6:	cbad                	beqz	a5,80004d68 <pipewrite+0xde>
    80004cf8:	03092783          	lw	a5,48(s2)
    80004cfc:	e7b5                	bnez	a5,80004d68 <pipewrite+0xde>
      wakeup(&pi->nread);
    80004cfe:	8556                	mv	a0,s5
    80004d00:	ffffe097          	auipc	ra,0xffffe
    80004d04:	9c2080e7          	jalr	-1598(ra) # 800026c2 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004d08:	85ce                	mv	a1,s3
    80004d0a:	8552                	mv	a0,s4
    80004d0c:	ffffe097          	auipc	ra,0xffffe
    80004d10:	830080e7          	jalr	-2000(ra) # 8000253c <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004d14:	2184a783          	lw	a5,536(s1)
    80004d18:	21c4a703          	lw	a4,540(s1)
    80004d1c:	2007879b          	addiw	a5,a5,512
    80004d20:	fcf709e3          	beq	a4,a5,80004cf2 <pipewrite+0x68>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d24:	4685                	li	a3,1
    80004d26:	019b8633          	add	a2,s7,s9
    80004d2a:	f8f40593          	addi	a1,s0,-113
    80004d2e:	05093503          	ld	a0,80(s2)
    80004d32:	ffffd097          	auipc	ra,0xffffd
    80004d36:	c42080e7          	jalr	-958(ra) # 80001974 <copyin>
    80004d3a:	05b50e63          	beq	a0,s11,80004d96 <pipewrite+0x10c>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004d3e:	21c4a783          	lw	a5,540(s1)
    80004d42:	0017871b          	addiw	a4,a5,1
    80004d46:	20e4ae23          	sw	a4,540(s1)
    80004d4a:	1ff7f793          	andi	a5,a5,511
    80004d4e:	97a6                	add	a5,a5,s1
    80004d50:	f8f44703          	lbu	a4,-113(s0)
    80004d54:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004d58:	001d0c1b          	addiw	s8,s10,1
    80004d5c:	001b8793          	addi	a5,s7,1 # 1001 <_entry-0x7fffefff>
    80004d60:	036b8b63          	beq	s7,s6,80004d96 <pipewrite+0x10c>
    80004d64:	8bbe                	mv	s7,a5
    80004d66:	bf9d                	j	80004cdc <pipewrite+0x52>
        release(&pi->lock);
    80004d68:	8526                	mv	a0,s1
    80004d6a:	ffffc097          	auipc	ra,0xffffc
    80004d6e:	f5a080e7          	jalr	-166(ra) # 80000cc4 <release>
        return -1;
    80004d72:	5c7d                	li	s8,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);
  return i;
}
    80004d74:	8562                	mv	a0,s8
    80004d76:	70e6                	ld	ra,120(sp)
    80004d78:	7446                	ld	s0,112(sp)
    80004d7a:	74a6                	ld	s1,104(sp)
    80004d7c:	7906                	ld	s2,96(sp)
    80004d7e:	69e6                	ld	s3,88(sp)
    80004d80:	6a46                	ld	s4,80(sp)
    80004d82:	6aa6                	ld	s5,72(sp)
    80004d84:	6b06                	ld	s6,64(sp)
    80004d86:	7be2                	ld	s7,56(sp)
    80004d88:	7c42                	ld	s8,48(sp)
    80004d8a:	7ca2                	ld	s9,40(sp)
    80004d8c:	7d02                	ld	s10,32(sp)
    80004d8e:	6de2                	ld	s11,24(sp)
    80004d90:	6109                	addi	sp,sp,128
    80004d92:	8082                	ret
  for(i = 0; i < n; i++){
    80004d94:	4c01                	li	s8,0
  wakeup(&pi->nread);
    80004d96:	21848513          	addi	a0,s1,536
    80004d9a:	ffffe097          	auipc	ra,0xffffe
    80004d9e:	928080e7          	jalr	-1752(ra) # 800026c2 <wakeup>
  release(&pi->lock);
    80004da2:	8526                	mv	a0,s1
    80004da4:	ffffc097          	auipc	ra,0xffffc
    80004da8:	f20080e7          	jalr	-224(ra) # 80000cc4 <release>
  return i;
    80004dac:	b7e1                	j	80004d74 <pipewrite+0xea>

0000000080004dae <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004dae:	715d                	addi	sp,sp,-80
    80004db0:	e486                	sd	ra,72(sp)
    80004db2:	e0a2                	sd	s0,64(sp)
    80004db4:	fc26                	sd	s1,56(sp)
    80004db6:	f84a                	sd	s2,48(sp)
    80004db8:	f44e                	sd	s3,40(sp)
    80004dba:	f052                	sd	s4,32(sp)
    80004dbc:	ec56                	sd	s5,24(sp)
    80004dbe:	e85a                	sd	s6,16(sp)
    80004dc0:	0880                	addi	s0,sp,80
    80004dc2:	84aa                	mv	s1,a0
    80004dc4:	892e                	mv	s2,a1
    80004dc6:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004dc8:	ffffd097          	auipc	ra,0xffffd
    80004dcc:	e48080e7          	jalr	-440(ra) # 80001c10 <myproc>
    80004dd0:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004dd2:	8b26                	mv	s6,s1
    80004dd4:	8526                	mv	a0,s1
    80004dd6:	ffffc097          	auipc	ra,0xffffc
    80004dda:	e3a080e7          	jalr	-454(ra) # 80000c10 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004dde:	2184a703          	lw	a4,536(s1)
    80004de2:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004de6:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004dea:	02f71463          	bne	a4,a5,80004e12 <piperead+0x64>
    80004dee:	2244a783          	lw	a5,548(s1)
    80004df2:	c385                	beqz	a5,80004e12 <piperead+0x64>
    if(pr->killed){
    80004df4:	030a2783          	lw	a5,48(s4)
    80004df8:	ebc1                	bnez	a5,80004e88 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004dfa:	85da                	mv	a1,s6
    80004dfc:	854e                	mv	a0,s3
    80004dfe:	ffffd097          	auipc	ra,0xffffd
    80004e02:	73e080e7          	jalr	1854(ra) # 8000253c <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e06:	2184a703          	lw	a4,536(s1)
    80004e0a:	21c4a783          	lw	a5,540(s1)
    80004e0e:	fef700e3          	beq	a4,a5,80004dee <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e12:	09505263          	blez	s5,80004e96 <piperead+0xe8>
    80004e16:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e18:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004e1a:	2184a783          	lw	a5,536(s1)
    80004e1e:	21c4a703          	lw	a4,540(s1)
    80004e22:	02f70d63          	beq	a4,a5,80004e5c <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004e26:	0017871b          	addiw	a4,a5,1
    80004e2a:	20e4ac23          	sw	a4,536(s1)
    80004e2e:	1ff7f793          	andi	a5,a5,511
    80004e32:	97a6                	add	a5,a5,s1
    80004e34:	0187c783          	lbu	a5,24(a5)
    80004e38:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e3c:	4685                	li	a3,1
    80004e3e:	fbf40613          	addi	a2,s0,-65
    80004e42:	85ca                	mv	a1,s2
    80004e44:	050a3503          	ld	a0,80(s4)
    80004e48:	ffffd097          	auipc	ra,0xffffd
    80004e4c:	aa0080e7          	jalr	-1376(ra) # 800018e8 <copyout>
    80004e50:	01650663          	beq	a0,s6,80004e5c <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e54:	2985                	addiw	s3,s3,1
    80004e56:	0905                	addi	s2,s2,1
    80004e58:	fd3a91e3          	bne	s5,s3,80004e1a <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004e5c:	21c48513          	addi	a0,s1,540
    80004e60:	ffffe097          	auipc	ra,0xffffe
    80004e64:	862080e7          	jalr	-1950(ra) # 800026c2 <wakeup>
  release(&pi->lock);
    80004e68:	8526                	mv	a0,s1
    80004e6a:	ffffc097          	auipc	ra,0xffffc
    80004e6e:	e5a080e7          	jalr	-422(ra) # 80000cc4 <release>
  return i;
}
    80004e72:	854e                	mv	a0,s3
    80004e74:	60a6                	ld	ra,72(sp)
    80004e76:	6406                	ld	s0,64(sp)
    80004e78:	74e2                	ld	s1,56(sp)
    80004e7a:	7942                	ld	s2,48(sp)
    80004e7c:	79a2                	ld	s3,40(sp)
    80004e7e:	7a02                	ld	s4,32(sp)
    80004e80:	6ae2                	ld	s5,24(sp)
    80004e82:	6b42                	ld	s6,16(sp)
    80004e84:	6161                	addi	sp,sp,80
    80004e86:	8082                	ret
      release(&pi->lock);
    80004e88:	8526                	mv	a0,s1
    80004e8a:	ffffc097          	auipc	ra,0xffffc
    80004e8e:	e3a080e7          	jalr	-454(ra) # 80000cc4 <release>
      return -1;
    80004e92:	59fd                	li	s3,-1
    80004e94:	bff9                	j	80004e72 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e96:	4981                	li	s3,0
    80004e98:	b7d1                	j	80004e5c <piperead+0xae>

0000000080004e9a <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004e9a:	df010113          	addi	sp,sp,-528
    80004e9e:	20113423          	sd	ra,520(sp)
    80004ea2:	20813023          	sd	s0,512(sp)
    80004ea6:	ffa6                	sd	s1,504(sp)
    80004ea8:	fbca                	sd	s2,496(sp)
    80004eaa:	f7ce                	sd	s3,488(sp)
    80004eac:	f3d2                	sd	s4,480(sp)
    80004eae:	efd6                	sd	s5,472(sp)
    80004eb0:	ebda                	sd	s6,464(sp)
    80004eb2:	e7de                	sd	s7,456(sp)
    80004eb4:	e3e2                	sd	s8,448(sp)
    80004eb6:	ff66                	sd	s9,440(sp)
    80004eb8:	fb6a                	sd	s10,432(sp)
    80004eba:	f76e                	sd	s11,424(sp)
    80004ebc:	0c00                	addi	s0,sp,528
    80004ebe:	84aa                	mv	s1,a0
    80004ec0:	dea43c23          	sd	a0,-520(s0)
    80004ec4:	e0b43023          	sd	a1,-512(s0)
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  // pagetable_t kernel_pagetable = 0, old_kernel_pagetable;
  struct proc *p = myproc();
    80004ec8:	ffffd097          	auipc	ra,0xffffd
    80004ecc:	d48080e7          	jalr	-696(ra) # 80001c10 <myproc>
    80004ed0:	892a                	mv	s2,a0
  // uint64 oldsz1 = p->sz;

  begin_op();
    80004ed2:	fffff097          	auipc	ra,0xfffff
    80004ed6:	446080e7          	jalr	1094(ra) # 80004318 <begin_op>

  // get inode by path
  if((ip = namei(path)) == 0){
    80004eda:	8526                	mv	a0,s1
    80004edc:	fffff097          	auipc	ra,0xfffff
    80004ee0:	230080e7          	jalr	560(ra) # 8000410c <namei>
    80004ee4:	c92d                	beqz	a0,80004f56 <exec+0xbc>
    80004ee6:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004ee8:	fffff097          	auipc	ra,0xfffff
    80004eec:	a74080e7          	jalr	-1420(ra) # 8000395c <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004ef0:	04000713          	li	a4,64
    80004ef4:	4681                	li	a3,0
    80004ef6:	e4840613          	addi	a2,s0,-440
    80004efa:	4581                	li	a1,0
    80004efc:	8526                	mv	a0,s1
    80004efe:	fffff097          	auipc	ra,0xfffff
    80004f02:	d12080e7          	jalr	-750(ra) # 80003c10 <readi>
    80004f06:	04000793          	li	a5,64
    80004f0a:	00f51a63          	bne	a0,a5,80004f1e <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004f0e:	e4842703          	lw	a4,-440(s0)
    80004f12:	464c47b7          	lui	a5,0x464c4
    80004f16:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004f1a:	04f70463          	beq	a4,a5,80004f62 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004f1e:	8526                	mv	a0,s1
    80004f20:	fffff097          	auipc	ra,0xfffff
    80004f24:	c9e080e7          	jalr	-866(ra) # 80003bbe <iunlockput>
    end_op();
    80004f28:	fffff097          	auipc	ra,0xfffff
    80004f2c:	470080e7          	jalr	1136(ra) # 80004398 <end_op>
  }
  return -1;
    80004f30:	557d                	li	a0,-1
}
    80004f32:	20813083          	ld	ra,520(sp)
    80004f36:	20013403          	ld	s0,512(sp)
    80004f3a:	74fe                	ld	s1,504(sp)
    80004f3c:	795e                	ld	s2,496(sp)
    80004f3e:	79be                	ld	s3,488(sp)
    80004f40:	7a1e                	ld	s4,480(sp)
    80004f42:	6afe                	ld	s5,472(sp)
    80004f44:	6b5e                	ld	s6,464(sp)
    80004f46:	6bbe                	ld	s7,456(sp)
    80004f48:	6c1e                	ld	s8,448(sp)
    80004f4a:	7cfa                	ld	s9,440(sp)
    80004f4c:	7d5a                	ld	s10,432(sp)
    80004f4e:	7dba                	ld	s11,424(sp)
    80004f50:	21010113          	addi	sp,sp,528
    80004f54:	8082                	ret
    end_op();
    80004f56:	fffff097          	auipc	ra,0xfffff
    80004f5a:	442080e7          	jalr	1090(ra) # 80004398 <end_op>
    return -1;
    80004f5e:	557d                	li	a0,-1
    80004f60:	bfc9                	j	80004f32 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004f62:	854a                	mv	a0,s2
    80004f64:	ffffd097          	auipc	ra,0xffffd
    80004f68:	d70080e7          	jalr	-656(ra) # 80001cd4 <proc_pagetable>
    80004f6c:	8baa                	mv	s7,a0
    80004f6e:	d945                	beqz	a0,80004f1e <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f70:	e6842983          	lw	s3,-408(s0)
    80004f74:	e8045783          	lhu	a5,-384(s0)
    80004f78:	c7ad                	beqz	a5,80004fe2 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004f7a:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f7c:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004f7e:	6c85                	lui	s9,0x1
    80004f80:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004f84:	def43823          	sd	a5,-528(s0)
    80004f88:	aca9                	j	800051e2 <exec+0x348>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004f8a:	00004517          	auipc	a0,0x4
    80004f8e:	81e50513          	addi	a0,a0,-2018 # 800087a8 <syscalls+0x290>
    80004f92:	ffffb097          	auipc	ra,0xffffb
    80004f96:	5b6080e7          	jalr	1462(ra) # 80000548 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004f9a:	8756                	mv	a4,s5
    80004f9c:	012d86bb          	addw	a3,s11,s2
    80004fa0:	4581                	li	a1,0
    80004fa2:	8526                	mv	a0,s1
    80004fa4:	fffff097          	auipc	ra,0xfffff
    80004fa8:	c6c080e7          	jalr	-916(ra) # 80003c10 <readi>
    80004fac:	2501                	sext.w	a0,a0
    80004fae:	1eaa9163          	bne	s5,a0,80005190 <exec+0x2f6>
  for(i = 0; i < sz; i += PGSIZE){
    80004fb2:	6785                	lui	a5,0x1
    80004fb4:	0127893b          	addw	s2,a5,s2
    80004fb8:	77fd                	lui	a5,0xfffff
    80004fba:	01478a3b          	addw	s4,a5,s4
    80004fbe:	21897963          	bgeu	s2,s8,800051d0 <exec+0x336>
    pa = walkaddr(pagetable, va + i);
    80004fc2:	02091593          	slli	a1,s2,0x20
    80004fc6:	9181                	srli	a1,a1,0x20
    80004fc8:	95ea                	add	a1,a1,s10
    80004fca:	855e                	mv	a0,s7
    80004fcc:	ffffc097          	auipc	ra,0xffffc
    80004fd0:	29c080e7          	jalr	668(ra) # 80001268 <walkaddr>
    80004fd4:	862a                	mv	a2,a0
    if(pa == 0)
    80004fd6:	d955                	beqz	a0,80004f8a <exec+0xf0>
      n = PGSIZE;
    80004fd8:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004fda:	fd9a70e3          	bgeu	s4,s9,80004f9a <exec+0x100>
      n = sz - i;
    80004fde:	8ad2                	mv	s5,s4
    80004fe0:	bf6d                	j	80004f9a <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004fe2:	4901                	li	s2,0
  iunlockput(ip);
    80004fe4:	8526                	mv	a0,s1
    80004fe6:	fffff097          	auipc	ra,0xfffff
    80004fea:	bd8080e7          	jalr	-1064(ra) # 80003bbe <iunlockput>
  end_op();
    80004fee:	fffff097          	auipc	ra,0xfffff
    80004ff2:	3aa080e7          	jalr	938(ra) # 80004398 <end_op>
  p = myproc();
    80004ff6:	ffffd097          	auipc	ra,0xffffd
    80004ffa:	c1a080e7          	jalr	-998(ra) # 80001c10 <myproc>
    80004ffe:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005000:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005004:	6785                	lui	a5,0x1
    80005006:	17fd                	addi	a5,a5,-1
    80005008:	993e                	add	s2,s2,a5
    8000500a:	757d                	lui	a0,0xfffff
    8000500c:	00a977b3          	and	a5,s2,a0
    80005010:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005014:	6609                	lui	a2,0x2
    80005016:	963e                	add	a2,a2,a5
    80005018:	85be                	mv	a1,a5
    8000501a:	855e                	mv	a0,s7
    8000501c:	ffffc097          	auipc	ra,0xffffc
    80005020:	67c080e7          	jalr	1660(ra) # 80001698 <uvmalloc>
    80005024:	8b2a                	mv	s6,a0
  ip = 0;
    80005026:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005028:	16050463          	beqz	a0,80005190 <exec+0x2f6>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000502c:	75f9                	lui	a1,0xffffe
    8000502e:	95aa                	add	a1,a1,a0
    80005030:	855e                	mv	a0,s7
    80005032:	ffffd097          	auipc	ra,0xffffd
    80005036:	884080e7          	jalr	-1916(ra) # 800018b6 <uvmclear>
  stackbase = sp - PGSIZE;
    8000503a:	7c7d                	lui	s8,0xfffff
    8000503c:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    8000503e:	e0043783          	ld	a5,-512(s0)
    80005042:	6388                	ld	a0,0(a5)
    80005044:	c535                	beqz	a0,800050b0 <exec+0x216>
    80005046:	e8840993          	addi	s3,s0,-376
    8000504a:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    8000504e:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005050:	ffffc097          	auipc	ra,0xffffc
    80005054:	e44080e7          	jalr	-444(ra) # 80000e94 <strlen>
    80005058:	2505                	addiw	a0,a0,1
    8000505a:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000505e:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005062:	15896b63          	bltu	s2,s8,800051b8 <exec+0x31e>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005066:	e0043d83          	ld	s11,-512(s0)
    8000506a:	000dba03          	ld	s4,0(s11)
    8000506e:	8552                	mv	a0,s4
    80005070:	ffffc097          	auipc	ra,0xffffc
    80005074:	e24080e7          	jalr	-476(ra) # 80000e94 <strlen>
    80005078:	0015069b          	addiw	a3,a0,1
    8000507c:	8652                	mv	a2,s4
    8000507e:	85ca                	mv	a1,s2
    80005080:	855e                	mv	a0,s7
    80005082:	ffffd097          	auipc	ra,0xffffd
    80005086:	866080e7          	jalr	-1946(ra) # 800018e8 <copyout>
    8000508a:	12054b63          	bltz	a0,800051c0 <exec+0x326>
    ustack[argc] = sp;
    8000508e:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005092:	0485                	addi	s1,s1,1
    80005094:	008d8793          	addi	a5,s11,8
    80005098:	e0f43023          	sd	a5,-512(s0)
    8000509c:	008db503          	ld	a0,8(s11)
    800050a0:	c911                	beqz	a0,800050b4 <exec+0x21a>
    if(argc >= MAXARG)
    800050a2:	09a1                	addi	s3,s3,8
    800050a4:	fb3c96e3          	bne	s9,s3,80005050 <exec+0x1b6>
  sz = sz1;
    800050a8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050ac:	4481                	li	s1,0
    800050ae:	a0cd                	j	80005190 <exec+0x2f6>
  sp = sz;
    800050b0:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    800050b2:	4481                	li	s1,0
  ustack[argc] = 0;
    800050b4:	00349793          	slli	a5,s1,0x3
    800050b8:	f9040713          	addi	a4,s0,-112
    800050bc:	97ba                	add	a5,a5,a4
    800050be:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    800050c2:	00148693          	addi	a3,s1,1
    800050c6:	068e                	slli	a3,a3,0x3
    800050c8:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800050cc:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800050d0:	01897663          	bgeu	s2,s8,800050dc <exec+0x242>
  sz = sz1;
    800050d4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050d8:	4481                	li	s1,0
    800050da:	a85d                	j	80005190 <exec+0x2f6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800050dc:	e8840613          	addi	a2,s0,-376
    800050e0:	85ca                	mv	a1,s2
    800050e2:	855e                	mv	a0,s7
    800050e4:	ffffd097          	auipc	ra,0xffffd
    800050e8:	804080e7          	jalr	-2044(ra) # 800018e8 <copyout>
    800050ec:	0c054e63          	bltz	a0,800051c8 <exec+0x32e>
  p->trapframe->a1 = sp;
    800050f0:	058ab783          	ld	a5,88(s5)
    800050f4:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800050f8:	df843783          	ld	a5,-520(s0)
    800050fc:	0007c703          	lbu	a4,0(a5)
    80005100:	cf11                	beqz	a4,8000511c <exec+0x282>
    80005102:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005104:	02f00693          	li	a3,47
    80005108:	a029                	j	80005112 <exec+0x278>
  for(last=s=path; *s; s++)
    8000510a:	0785                	addi	a5,a5,1
    8000510c:	fff7c703          	lbu	a4,-1(a5)
    80005110:	c711                	beqz	a4,8000511c <exec+0x282>
    if(*s == '/')
    80005112:	fed71ce3          	bne	a4,a3,8000510a <exec+0x270>
      last = s+1;
    80005116:	def43c23          	sd	a5,-520(s0)
    8000511a:	bfc5                	j	8000510a <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    8000511c:	4641                	li	a2,16
    8000511e:	df843583          	ld	a1,-520(s0)
    80005122:	158a8513          	addi	a0,s5,344
    80005126:	ffffc097          	auipc	ra,0xffffc
    8000512a:	d3c080e7          	jalr	-708(ra) # 80000e62 <safestrcpy>
  oldpagetable = p->pagetable;
    8000512e:	050ab983          	ld	s3,80(s5)
  p->pagetable = pagetable;
    80005132:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80005136:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000513a:	058ab783          	ld	a5,88(s5)
    8000513e:	e6043703          	ld	a4,-416(s0)
    80005142:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005144:	058ab783          	ld	a5,88(s5)
    80005148:	0327b823          	sd	s2,48(a5)
  kvmmapuser(p->kernel_pagetable, p->pagetable, 0, p->sz);
    8000514c:	048ab683          	ld	a3,72(s5)
    80005150:	4601                	li	a2,0
    80005152:	050ab583          	ld	a1,80(s5)
    80005156:	168ab503          	ld	a0,360(s5)
    8000515a:	ffffd097          	auipc	ra,0xffffd
    8000515e:	84a080e7          	jalr	-1974(ra) # 800019a4 <kvmmapuser>
  proc_freepagetable(oldpagetable, oldsz);
    80005162:	85ea                	mv	a1,s10
    80005164:	854e                	mv	a0,s3
    80005166:	ffffd097          	auipc	ra,0xffffd
    8000516a:	c0a080e7          	jalr	-1014(ra) # 80001d70 <proc_freepagetable>
  if(p->pid==1) {
    8000516e:	038aa703          	lw	a4,56(s5)
    80005172:	4785                	li	a5,1
    80005174:	00f70563          	beq	a4,a5,8000517e <exec+0x2e4>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005178:	0004851b          	sext.w	a0,s1
    8000517c:	bb5d                	j	80004f32 <exec+0x98>
    vmprint(p->pagetable);
    8000517e:	050ab503          	ld	a0,80(s5)
    80005182:	ffffd097          	auipc	ra,0xffffd
    80005186:	982080e7          	jalr	-1662(ra) # 80001b04 <vmprint>
    8000518a:	b7fd                	j	80005178 <exec+0x2de>
    8000518c:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005190:	e0843583          	ld	a1,-504(s0)
    80005194:	855e                	mv	a0,s7
    80005196:	ffffd097          	auipc	ra,0xffffd
    8000519a:	bda080e7          	jalr	-1062(ra) # 80001d70 <proc_freepagetable>
  if(ip){
    8000519e:	d80490e3          	bnez	s1,80004f1e <exec+0x84>
  return -1;
    800051a2:	557d                	li	a0,-1
    800051a4:	b379                	j	80004f32 <exec+0x98>
    800051a6:	e1243423          	sd	s2,-504(s0)
    800051aa:	b7dd                	j	80005190 <exec+0x2f6>
    800051ac:	e1243423          	sd	s2,-504(s0)
    800051b0:	b7c5                	j	80005190 <exec+0x2f6>
    800051b2:	e1243423          	sd	s2,-504(s0)
    800051b6:	bfe9                	j	80005190 <exec+0x2f6>
  sz = sz1;
    800051b8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800051bc:	4481                	li	s1,0
    800051be:	bfc9                	j	80005190 <exec+0x2f6>
  sz = sz1;
    800051c0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800051c4:	4481                	li	s1,0
    800051c6:	b7e9                	j	80005190 <exec+0x2f6>
  sz = sz1;
    800051c8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800051cc:	4481                	li	s1,0
    800051ce:	b7c9                	j	80005190 <exec+0x2f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800051d0:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800051d4:	2b05                	addiw	s6,s6,1
    800051d6:	0389899b          	addiw	s3,s3,56
    800051da:	e8045783          	lhu	a5,-384(s0)
    800051de:	e0fb53e3          	bge	s6,a5,80004fe4 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800051e2:	2981                	sext.w	s3,s3
    800051e4:	03800713          	li	a4,56
    800051e8:	86ce                	mv	a3,s3
    800051ea:	e1040613          	addi	a2,s0,-496
    800051ee:	4581                	li	a1,0
    800051f0:	8526                	mv	a0,s1
    800051f2:	fffff097          	auipc	ra,0xfffff
    800051f6:	a1e080e7          	jalr	-1506(ra) # 80003c10 <readi>
    800051fa:	03800793          	li	a5,56
    800051fe:	f8f517e3          	bne	a0,a5,8000518c <exec+0x2f2>
    if(ph.type != ELF_PROG_LOAD)
    80005202:	e1042783          	lw	a5,-496(s0)
    80005206:	4705                	li	a4,1
    80005208:	fce796e3          	bne	a5,a4,800051d4 <exec+0x33a>
    if(ph.memsz < ph.filesz)
    8000520c:	e3843603          	ld	a2,-456(s0)
    80005210:	e3043783          	ld	a5,-464(s0)
    80005214:	f8f669e3          	bltu	a2,a5,800051a6 <exec+0x30c>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005218:	e2043783          	ld	a5,-480(s0)
    8000521c:	963e                	add	a2,a2,a5
    8000521e:	f8f667e3          	bltu	a2,a5,800051ac <exec+0x312>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005222:	85ca                	mv	a1,s2
    80005224:	855e                	mv	a0,s7
    80005226:	ffffc097          	auipc	ra,0xffffc
    8000522a:	472080e7          	jalr	1138(ra) # 80001698 <uvmalloc>
    8000522e:	e0a43423          	sd	a0,-504(s0)
    80005232:	d141                	beqz	a0,800051b2 <exec+0x318>
    if(ph.vaddr % PGSIZE != 0)
    80005234:	e2043d03          	ld	s10,-480(s0)
    80005238:	df043783          	ld	a5,-528(s0)
    8000523c:	00fd77b3          	and	a5,s10,a5
    80005240:	fba1                	bnez	a5,80005190 <exec+0x2f6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005242:	e1842d83          	lw	s11,-488(s0)
    80005246:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000524a:	f80c03e3          	beqz	s8,800051d0 <exec+0x336>
    8000524e:	8a62                	mv	s4,s8
    80005250:	4901                	li	s2,0
    80005252:	bb85                	j	80004fc2 <exec+0x128>

0000000080005254 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005254:	7179                	addi	sp,sp,-48
    80005256:	f406                	sd	ra,40(sp)
    80005258:	f022                	sd	s0,32(sp)
    8000525a:	ec26                	sd	s1,24(sp)
    8000525c:	e84a                	sd	s2,16(sp)
    8000525e:	1800                	addi	s0,sp,48
    80005260:	892e                	mv	s2,a1
    80005262:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005264:	fdc40593          	addi	a1,s0,-36
    80005268:	ffffe097          	auipc	ra,0xffffe
    8000526c:	b82080e7          	jalr	-1150(ra) # 80002dea <argint>
    80005270:	04054063          	bltz	a0,800052b0 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005274:	fdc42703          	lw	a4,-36(s0)
    80005278:	47bd                	li	a5,15
    8000527a:	02e7ed63          	bltu	a5,a4,800052b4 <argfd+0x60>
    8000527e:	ffffd097          	auipc	ra,0xffffd
    80005282:	992080e7          	jalr	-1646(ra) # 80001c10 <myproc>
    80005286:	fdc42703          	lw	a4,-36(s0)
    8000528a:	01a70793          	addi	a5,a4,26
    8000528e:	078e                	slli	a5,a5,0x3
    80005290:	953e                	add	a0,a0,a5
    80005292:	611c                	ld	a5,0(a0)
    80005294:	c395                	beqz	a5,800052b8 <argfd+0x64>
    return -1;
  if(pfd)
    80005296:	00090463          	beqz	s2,8000529e <argfd+0x4a>
    *pfd = fd;
    8000529a:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000529e:	4501                	li	a0,0
  if(pf)
    800052a0:	c091                	beqz	s1,800052a4 <argfd+0x50>
    *pf = f;
    800052a2:	e09c                	sd	a5,0(s1)
}
    800052a4:	70a2                	ld	ra,40(sp)
    800052a6:	7402                	ld	s0,32(sp)
    800052a8:	64e2                	ld	s1,24(sp)
    800052aa:	6942                	ld	s2,16(sp)
    800052ac:	6145                	addi	sp,sp,48
    800052ae:	8082                	ret
    return -1;
    800052b0:	557d                	li	a0,-1
    800052b2:	bfcd                	j	800052a4 <argfd+0x50>
    return -1;
    800052b4:	557d                	li	a0,-1
    800052b6:	b7fd                	j	800052a4 <argfd+0x50>
    800052b8:	557d                	li	a0,-1
    800052ba:	b7ed                	j	800052a4 <argfd+0x50>

00000000800052bc <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800052bc:	1101                	addi	sp,sp,-32
    800052be:	ec06                	sd	ra,24(sp)
    800052c0:	e822                	sd	s0,16(sp)
    800052c2:	e426                	sd	s1,8(sp)
    800052c4:	1000                	addi	s0,sp,32
    800052c6:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800052c8:	ffffd097          	auipc	ra,0xffffd
    800052cc:	948080e7          	jalr	-1720(ra) # 80001c10 <myproc>
    800052d0:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800052d2:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd80b0>
    800052d6:	4501                	li	a0,0
    800052d8:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800052da:	6398                	ld	a4,0(a5)
    800052dc:	cb19                	beqz	a4,800052f2 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800052de:	2505                	addiw	a0,a0,1
    800052e0:	07a1                	addi	a5,a5,8
    800052e2:	fed51ce3          	bne	a0,a3,800052da <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800052e6:	557d                	li	a0,-1
}
    800052e8:	60e2                	ld	ra,24(sp)
    800052ea:	6442                	ld	s0,16(sp)
    800052ec:	64a2                	ld	s1,8(sp)
    800052ee:	6105                	addi	sp,sp,32
    800052f0:	8082                	ret
      p->ofile[fd] = f;
    800052f2:	01a50793          	addi	a5,a0,26
    800052f6:	078e                	slli	a5,a5,0x3
    800052f8:	963e                	add	a2,a2,a5
    800052fa:	e204                	sd	s1,0(a2)
      return fd;
    800052fc:	b7f5                	j	800052e8 <fdalloc+0x2c>

00000000800052fe <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800052fe:	715d                	addi	sp,sp,-80
    80005300:	e486                	sd	ra,72(sp)
    80005302:	e0a2                	sd	s0,64(sp)
    80005304:	fc26                	sd	s1,56(sp)
    80005306:	f84a                	sd	s2,48(sp)
    80005308:	f44e                	sd	s3,40(sp)
    8000530a:	f052                	sd	s4,32(sp)
    8000530c:	ec56                	sd	s5,24(sp)
    8000530e:	0880                	addi	s0,sp,80
    80005310:	89ae                	mv	s3,a1
    80005312:	8ab2                	mv	s5,a2
    80005314:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005316:	fb040593          	addi	a1,s0,-80
    8000531a:	fffff097          	auipc	ra,0xfffff
    8000531e:	e10080e7          	jalr	-496(ra) # 8000412a <nameiparent>
    80005322:	892a                	mv	s2,a0
    80005324:	12050f63          	beqz	a0,80005462 <create+0x164>
    return 0;

  ilock(dp);
    80005328:	ffffe097          	auipc	ra,0xffffe
    8000532c:	634080e7          	jalr	1588(ra) # 8000395c <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005330:	4601                	li	a2,0
    80005332:	fb040593          	addi	a1,s0,-80
    80005336:	854a                	mv	a0,s2
    80005338:	fffff097          	auipc	ra,0xfffff
    8000533c:	b02080e7          	jalr	-1278(ra) # 80003e3a <dirlookup>
    80005340:	84aa                	mv	s1,a0
    80005342:	c921                	beqz	a0,80005392 <create+0x94>
    iunlockput(dp);
    80005344:	854a                	mv	a0,s2
    80005346:	fffff097          	auipc	ra,0xfffff
    8000534a:	878080e7          	jalr	-1928(ra) # 80003bbe <iunlockput>
    ilock(ip);
    8000534e:	8526                	mv	a0,s1
    80005350:	ffffe097          	auipc	ra,0xffffe
    80005354:	60c080e7          	jalr	1548(ra) # 8000395c <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005358:	2981                	sext.w	s3,s3
    8000535a:	4789                	li	a5,2
    8000535c:	02f99463          	bne	s3,a5,80005384 <create+0x86>
    80005360:	0444d783          	lhu	a5,68(s1)
    80005364:	37f9                	addiw	a5,a5,-2
    80005366:	17c2                	slli	a5,a5,0x30
    80005368:	93c1                	srli	a5,a5,0x30
    8000536a:	4705                	li	a4,1
    8000536c:	00f76c63          	bltu	a4,a5,80005384 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005370:	8526                	mv	a0,s1
    80005372:	60a6                	ld	ra,72(sp)
    80005374:	6406                	ld	s0,64(sp)
    80005376:	74e2                	ld	s1,56(sp)
    80005378:	7942                	ld	s2,48(sp)
    8000537a:	79a2                	ld	s3,40(sp)
    8000537c:	7a02                	ld	s4,32(sp)
    8000537e:	6ae2                	ld	s5,24(sp)
    80005380:	6161                	addi	sp,sp,80
    80005382:	8082                	ret
    iunlockput(ip);
    80005384:	8526                	mv	a0,s1
    80005386:	fffff097          	auipc	ra,0xfffff
    8000538a:	838080e7          	jalr	-1992(ra) # 80003bbe <iunlockput>
    return 0;
    8000538e:	4481                	li	s1,0
    80005390:	b7c5                	j	80005370 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005392:	85ce                	mv	a1,s3
    80005394:	00092503          	lw	a0,0(s2)
    80005398:	ffffe097          	auipc	ra,0xffffe
    8000539c:	42c080e7          	jalr	1068(ra) # 800037c4 <ialloc>
    800053a0:	84aa                	mv	s1,a0
    800053a2:	c529                	beqz	a0,800053ec <create+0xee>
  ilock(ip);
    800053a4:	ffffe097          	auipc	ra,0xffffe
    800053a8:	5b8080e7          	jalr	1464(ra) # 8000395c <ilock>
  ip->major = major;
    800053ac:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800053b0:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800053b4:	4785                	li	a5,1
    800053b6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800053ba:	8526                	mv	a0,s1
    800053bc:	ffffe097          	auipc	ra,0xffffe
    800053c0:	4d6080e7          	jalr	1238(ra) # 80003892 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800053c4:	2981                	sext.w	s3,s3
    800053c6:	4785                	li	a5,1
    800053c8:	02f98a63          	beq	s3,a5,800053fc <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800053cc:	40d0                	lw	a2,4(s1)
    800053ce:	fb040593          	addi	a1,s0,-80
    800053d2:	854a                	mv	a0,s2
    800053d4:	fffff097          	auipc	ra,0xfffff
    800053d8:	c76080e7          	jalr	-906(ra) # 8000404a <dirlink>
    800053dc:	06054b63          	bltz	a0,80005452 <create+0x154>
  iunlockput(dp);
    800053e0:	854a                	mv	a0,s2
    800053e2:	ffffe097          	auipc	ra,0xffffe
    800053e6:	7dc080e7          	jalr	2012(ra) # 80003bbe <iunlockput>
  return ip;
    800053ea:	b759                	j	80005370 <create+0x72>
    panic("create: ialloc");
    800053ec:	00003517          	auipc	a0,0x3
    800053f0:	3dc50513          	addi	a0,a0,988 # 800087c8 <syscalls+0x2b0>
    800053f4:	ffffb097          	auipc	ra,0xffffb
    800053f8:	154080e7          	jalr	340(ra) # 80000548 <panic>
    dp->nlink++;  // for ".."
    800053fc:	04a95783          	lhu	a5,74(s2)
    80005400:	2785                	addiw	a5,a5,1
    80005402:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005406:	854a                	mv	a0,s2
    80005408:	ffffe097          	auipc	ra,0xffffe
    8000540c:	48a080e7          	jalr	1162(ra) # 80003892 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005410:	40d0                	lw	a2,4(s1)
    80005412:	00003597          	auipc	a1,0x3
    80005416:	3c658593          	addi	a1,a1,966 # 800087d8 <syscalls+0x2c0>
    8000541a:	8526                	mv	a0,s1
    8000541c:	fffff097          	auipc	ra,0xfffff
    80005420:	c2e080e7          	jalr	-978(ra) # 8000404a <dirlink>
    80005424:	00054f63          	bltz	a0,80005442 <create+0x144>
    80005428:	00492603          	lw	a2,4(s2)
    8000542c:	00003597          	auipc	a1,0x3
    80005430:	e6458593          	addi	a1,a1,-412 # 80008290 <digits+0x250>
    80005434:	8526                	mv	a0,s1
    80005436:	fffff097          	auipc	ra,0xfffff
    8000543a:	c14080e7          	jalr	-1004(ra) # 8000404a <dirlink>
    8000543e:	f80557e3          	bgez	a0,800053cc <create+0xce>
      panic("create dots");
    80005442:	00003517          	auipc	a0,0x3
    80005446:	39e50513          	addi	a0,a0,926 # 800087e0 <syscalls+0x2c8>
    8000544a:	ffffb097          	auipc	ra,0xffffb
    8000544e:	0fe080e7          	jalr	254(ra) # 80000548 <panic>
    panic("create: dirlink");
    80005452:	00003517          	auipc	a0,0x3
    80005456:	39e50513          	addi	a0,a0,926 # 800087f0 <syscalls+0x2d8>
    8000545a:	ffffb097          	auipc	ra,0xffffb
    8000545e:	0ee080e7          	jalr	238(ra) # 80000548 <panic>
    return 0;
    80005462:	84aa                	mv	s1,a0
    80005464:	b731                	j	80005370 <create+0x72>

0000000080005466 <sys_dup>:
{
    80005466:	7179                	addi	sp,sp,-48
    80005468:	f406                	sd	ra,40(sp)
    8000546a:	f022                	sd	s0,32(sp)
    8000546c:	ec26                	sd	s1,24(sp)
    8000546e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005470:	fd840613          	addi	a2,s0,-40
    80005474:	4581                	li	a1,0
    80005476:	4501                	li	a0,0
    80005478:	00000097          	auipc	ra,0x0
    8000547c:	ddc080e7          	jalr	-548(ra) # 80005254 <argfd>
    return -1;
    80005480:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005482:	02054363          	bltz	a0,800054a8 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005486:	fd843503          	ld	a0,-40(s0)
    8000548a:	00000097          	auipc	ra,0x0
    8000548e:	e32080e7          	jalr	-462(ra) # 800052bc <fdalloc>
    80005492:	84aa                	mv	s1,a0
    return -1;
    80005494:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005496:	00054963          	bltz	a0,800054a8 <sys_dup+0x42>
  filedup(f);
    8000549a:	fd843503          	ld	a0,-40(s0)
    8000549e:	fffff097          	auipc	ra,0xfffff
    800054a2:	2fa080e7          	jalr	762(ra) # 80004798 <filedup>
  return fd;
    800054a6:	87a6                	mv	a5,s1
}
    800054a8:	853e                	mv	a0,a5
    800054aa:	70a2                	ld	ra,40(sp)
    800054ac:	7402                	ld	s0,32(sp)
    800054ae:	64e2                	ld	s1,24(sp)
    800054b0:	6145                	addi	sp,sp,48
    800054b2:	8082                	ret

00000000800054b4 <sys_read>:
{
    800054b4:	7179                	addi	sp,sp,-48
    800054b6:	f406                	sd	ra,40(sp)
    800054b8:	f022                	sd	s0,32(sp)
    800054ba:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054bc:	fe840613          	addi	a2,s0,-24
    800054c0:	4581                	li	a1,0
    800054c2:	4501                	li	a0,0
    800054c4:	00000097          	auipc	ra,0x0
    800054c8:	d90080e7          	jalr	-624(ra) # 80005254 <argfd>
    return -1;
    800054cc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054ce:	04054163          	bltz	a0,80005510 <sys_read+0x5c>
    800054d2:	fe440593          	addi	a1,s0,-28
    800054d6:	4509                	li	a0,2
    800054d8:	ffffe097          	auipc	ra,0xffffe
    800054dc:	912080e7          	jalr	-1774(ra) # 80002dea <argint>
    return -1;
    800054e0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054e2:	02054763          	bltz	a0,80005510 <sys_read+0x5c>
    800054e6:	fd840593          	addi	a1,s0,-40
    800054ea:	4505                	li	a0,1
    800054ec:	ffffe097          	auipc	ra,0xffffe
    800054f0:	920080e7          	jalr	-1760(ra) # 80002e0c <argaddr>
    return -1;
    800054f4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054f6:	00054d63          	bltz	a0,80005510 <sys_read+0x5c>
  return fileread(f, p, n);
    800054fa:	fe442603          	lw	a2,-28(s0)
    800054fe:	fd843583          	ld	a1,-40(s0)
    80005502:	fe843503          	ld	a0,-24(s0)
    80005506:	fffff097          	auipc	ra,0xfffff
    8000550a:	41e080e7          	jalr	1054(ra) # 80004924 <fileread>
    8000550e:	87aa                	mv	a5,a0
}
    80005510:	853e                	mv	a0,a5
    80005512:	70a2                	ld	ra,40(sp)
    80005514:	7402                	ld	s0,32(sp)
    80005516:	6145                	addi	sp,sp,48
    80005518:	8082                	ret

000000008000551a <sys_write>:
{
    8000551a:	7179                	addi	sp,sp,-48
    8000551c:	f406                	sd	ra,40(sp)
    8000551e:	f022                	sd	s0,32(sp)
    80005520:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005522:	fe840613          	addi	a2,s0,-24
    80005526:	4581                	li	a1,0
    80005528:	4501                	li	a0,0
    8000552a:	00000097          	auipc	ra,0x0
    8000552e:	d2a080e7          	jalr	-726(ra) # 80005254 <argfd>
    return -1;
    80005532:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005534:	04054163          	bltz	a0,80005576 <sys_write+0x5c>
    80005538:	fe440593          	addi	a1,s0,-28
    8000553c:	4509                	li	a0,2
    8000553e:	ffffe097          	auipc	ra,0xffffe
    80005542:	8ac080e7          	jalr	-1876(ra) # 80002dea <argint>
    return -1;
    80005546:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005548:	02054763          	bltz	a0,80005576 <sys_write+0x5c>
    8000554c:	fd840593          	addi	a1,s0,-40
    80005550:	4505                	li	a0,1
    80005552:	ffffe097          	auipc	ra,0xffffe
    80005556:	8ba080e7          	jalr	-1862(ra) # 80002e0c <argaddr>
    return -1;
    8000555a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000555c:	00054d63          	bltz	a0,80005576 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005560:	fe442603          	lw	a2,-28(s0)
    80005564:	fd843583          	ld	a1,-40(s0)
    80005568:	fe843503          	ld	a0,-24(s0)
    8000556c:	fffff097          	auipc	ra,0xfffff
    80005570:	47a080e7          	jalr	1146(ra) # 800049e6 <filewrite>
    80005574:	87aa                	mv	a5,a0
}
    80005576:	853e                	mv	a0,a5
    80005578:	70a2                	ld	ra,40(sp)
    8000557a:	7402                	ld	s0,32(sp)
    8000557c:	6145                	addi	sp,sp,48
    8000557e:	8082                	ret

0000000080005580 <sys_close>:
{
    80005580:	1101                	addi	sp,sp,-32
    80005582:	ec06                	sd	ra,24(sp)
    80005584:	e822                	sd	s0,16(sp)
    80005586:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005588:	fe040613          	addi	a2,s0,-32
    8000558c:	fec40593          	addi	a1,s0,-20
    80005590:	4501                	li	a0,0
    80005592:	00000097          	auipc	ra,0x0
    80005596:	cc2080e7          	jalr	-830(ra) # 80005254 <argfd>
    return -1;
    8000559a:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000559c:	02054463          	bltz	a0,800055c4 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800055a0:	ffffc097          	auipc	ra,0xffffc
    800055a4:	670080e7          	jalr	1648(ra) # 80001c10 <myproc>
    800055a8:	fec42783          	lw	a5,-20(s0)
    800055ac:	07e9                	addi	a5,a5,26
    800055ae:	078e                	slli	a5,a5,0x3
    800055b0:	97aa                	add	a5,a5,a0
    800055b2:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800055b6:	fe043503          	ld	a0,-32(s0)
    800055ba:	fffff097          	auipc	ra,0xfffff
    800055be:	230080e7          	jalr	560(ra) # 800047ea <fileclose>
  return 0;
    800055c2:	4781                	li	a5,0
}
    800055c4:	853e                	mv	a0,a5
    800055c6:	60e2                	ld	ra,24(sp)
    800055c8:	6442                	ld	s0,16(sp)
    800055ca:	6105                	addi	sp,sp,32
    800055cc:	8082                	ret

00000000800055ce <sys_fstat>:
{
    800055ce:	1101                	addi	sp,sp,-32
    800055d0:	ec06                	sd	ra,24(sp)
    800055d2:	e822                	sd	s0,16(sp)
    800055d4:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800055d6:	fe840613          	addi	a2,s0,-24
    800055da:	4581                	li	a1,0
    800055dc:	4501                	li	a0,0
    800055de:	00000097          	auipc	ra,0x0
    800055e2:	c76080e7          	jalr	-906(ra) # 80005254 <argfd>
    return -1;
    800055e6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800055e8:	02054563          	bltz	a0,80005612 <sys_fstat+0x44>
    800055ec:	fe040593          	addi	a1,s0,-32
    800055f0:	4505                	li	a0,1
    800055f2:	ffffe097          	auipc	ra,0xffffe
    800055f6:	81a080e7          	jalr	-2022(ra) # 80002e0c <argaddr>
    return -1;
    800055fa:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800055fc:	00054b63          	bltz	a0,80005612 <sys_fstat+0x44>
  return filestat(f, st);
    80005600:	fe043583          	ld	a1,-32(s0)
    80005604:	fe843503          	ld	a0,-24(s0)
    80005608:	fffff097          	auipc	ra,0xfffff
    8000560c:	2aa080e7          	jalr	682(ra) # 800048b2 <filestat>
    80005610:	87aa                	mv	a5,a0
}
    80005612:	853e                	mv	a0,a5
    80005614:	60e2                	ld	ra,24(sp)
    80005616:	6442                	ld	s0,16(sp)
    80005618:	6105                	addi	sp,sp,32
    8000561a:	8082                	ret

000000008000561c <sys_link>:
{
    8000561c:	7169                	addi	sp,sp,-304
    8000561e:	f606                	sd	ra,296(sp)
    80005620:	f222                	sd	s0,288(sp)
    80005622:	ee26                	sd	s1,280(sp)
    80005624:	ea4a                	sd	s2,272(sp)
    80005626:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005628:	08000613          	li	a2,128
    8000562c:	ed040593          	addi	a1,s0,-304
    80005630:	4501                	li	a0,0
    80005632:	ffffd097          	auipc	ra,0xffffd
    80005636:	7fc080e7          	jalr	2044(ra) # 80002e2e <argstr>
    return -1;
    8000563a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000563c:	10054e63          	bltz	a0,80005758 <sys_link+0x13c>
    80005640:	08000613          	li	a2,128
    80005644:	f5040593          	addi	a1,s0,-176
    80005648:	4505                	li	a0,1
    8000564a:	ffffd097          	auipc	ra,0xffffd
    8000564e:	7e4080e7          	jalr	2020(ra) # 80002e2e <argstr>
    return -1;
    80005652:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005654:	10054263          	bltz	a0,80005758 <sys_link+0x13c>
  begin_op();
    80005658:	fffff097          	auipc	ra,0xfffff
    8000565c:	cc0080e7          	jalr	-832(ra) # 80004318 <begin_op>
  if((ip = namei(old)) == 0){
    80005660:	ed040513          	addi	a0,s0,-304
    80005664:	fffff097          	auipc	ra,0xfffff
    80005668:	aa8080e7          	jalr	-1368(ra) # 8000410c <namei>
    8000566c:	84aa                	mv	s1,a0
    8000566e:	c551                	beqz	a0,800056fa <sys_link+0xde>
  ilock(ip);
    80005670:	ffffe097          	auipc	ra,0xffffe
    80005674:	2ec080e7          	jalr	748(ra) # 8000395c <ilock>
  if(ip->type == T_DIR){
    80005678:	04449703          	lh	a4,68(s1)
    8000567c:	4785                	li	a5,1
    8000567e:	08f70463          	beq	a4,a5,80005706 <sys_link+0xea>
  ip->nlink++;
    80005682:	04a4d783          	lhu	a5,74(s1)
    80005686:	2785                	addiw	a5,a5,1
    80005688:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000568c:	8526                	mv	a0,s1
    8000568e:	ffffe097          	auipc	ra,0xffffe
    80005692:	204080e7          	jalr	516(ra) # 80003892 <iupdate>
  iunlock(ip);
    80005696:	8526                	mv	a0,s1
    80005698:	ffffe097          	auipc	ra,0xffffe
    8000569c:	386080e7          	jalr	902(ra) # 80003a1e <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800056a0:	fd040593          	addi	a1,s0,-48
    800056a4:	f5040513          	addi	a0,s0,-176
    800056a8:	fffff097          	auipc	ra,0xfffff
    800056ac:	a82080e7          	jalr	-1406(ra) # 8000412a <nameiparent>
    800056b0:	892a                	mv	s2,a0
    800056b2:	c935                	beqz	a0,80005726 <sys_link+0x10a>
  ilock(dp);
    800056b4:	ffffe097          	auipc	ra,0xffffe
    800056b8:	2a8080e7          	jalr	680(ra) # 8000395c <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800056bc:	00092703          	lw	a4,0(s2)
    800056c0:	409c                	lw	a5,0(s1)
    800056c2:	04f71d63          	bne	a4,a5,8000571c <sys_link+0x100>
    800056c6:	40d0                	lw	a2,4(s1)
    800056c8:	fd040593          	addi	a1,s0,-48
    800056cc:	854a                	mv	a0,s2
    800056ce:	fffff097          	auipc	ra,0xfffff
    800056d2:	97c080e7          	jalr	-1668(ra) # 8000404a <dirlink>
    800056d6:	04054363          	bltz	a0,8000571c <sys_link+0x100>
  iunlockput(dp);
    800056da:	854a                	mv	a0,s2
    800056dc:	ffffe097          	auipc	ra,0xffffe
    800056e0:	4e2080e7          	jalr	1250(ra) # 80003bbe <iunlockput>
  iput(ip);
    800056e4:	8526                	mv	a0,s1
    800056e6:	ffffe097          	auipc	ra,0xffffe
    800056ea:	430080e7          	jalr	1072(ra) # 80003b16 <iput>
  end_op();
    800056ee:	fffff097          	auipc	ra,0xfffff
    800056f2:	caa080e7          	jalr	-854(ra) # 80004398 <end_op>
  return 0;
    800056f6:	4781                	li	a5,0
    800056f8:	a085                	j	80005758 <sys_link+0x13c>
    end_op();
    800056fa:	fffff097          	auipc	ra,0xfffff
    800056fe:	c9e080e7          	jalr	-866(ra) # 80004398 <end_op>
    return -1;
    80005702:	57fd                	li	a5,-1
    80005704:	a891                	j	80005758 <sys_link+0x13c>
    iunlockput(ip);
    80005706:	8526                	mv	a0,s1
    80005708:	ffffe097          	auipc	ra,0xffffe
    8000570c:	4b6080e7          	jalr	1206(ra) # 80003bbe <iunlockput>
    end_op();
    80005710:	fffff097          	auipc	ra,0xfffff
    80005714:	c88080e7          	jalr	-888(ra) # 80004398 <end_op>
    return -1;
    80005718:	57fd                	li	a5,-1
    8000571a:	a83d                	j	80005758 <sys_link+0x13c>
    iunlockput(dp);
    8000571c:	854a                	mv	a0,s2
    8000571e:	ffffe097          	auipc	ra,0xffffe
    80005722:	4a0080e7          	jalr	1184(ra) # 80003bbe <iunlockput>
  ilock(ip);
    80005726:	8526                	mv	a0,s1
    80005728:	ffffe097          	auipc	ra,0xffffe
    8000572c:	234080e7          	jalr	564(ra) # 8000395c <ilock>
  ip->nlink--;
    80005730:	04a4d783          	lhu	a5,74(s1)
    80005734:	37fd                	addiw	a5,a5,-1
    80005736:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000573a:	8526                	mv	a0,s1
    8000573c:	ffffe097          	auipc	ra,0xffffe
    80005740:	156080e7          	jalr	342(ra) # 80003892 <iupdate>
  iunlockput(ip);
    80005744:	8526                	mv	a0,s1
    80005746:	ffffe097          	auipc	ra,0xffffe
    8000574a:	478080e7          	jalr	1144(ra) # 80003bbe <iunlockput>
  end_op();
    8000574e:	fffff097          	auipc	ra,0xfffff
    80005752:	c4a080e7          	jalr	-950(ra) # 80004398 <end_op>
  return -1;
    80005756:	57fd                	li	a5,-1
}
    80005758:	853e                	mv	a0,a5
    8000575a:	70b2                	ld	ra,296(sp)
    8000575c:	7412                	ld	s0,288(sp)
    8000575e:	64f2                	ld	s1,280(sp)
    80005760:	6952                	ld	s2,272(sp)
    80005762:	6155                	addi	sp,sp,304
    80005764:	8082                	ret

0000000080005766 <sys_unlink>:
{
    80005766:	7151                	addi	sp,sp,-240
    80005768:	f586                	sd	ra,232(sp)
    8000576a:	f1a2                	sd	s0,224(sp)
    8000576c:	eda6                	sd	s1,216(sp)
    8000576e:	e9ca                	sd	s2,208(sp)
    80005770:	e5ce                	sd	s3,200(sp)
    80005772:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005774:	08000613          	li	a2,128
    80005778:	f3040593          	addi	a1,s0,-208
    8000577c:	4501                	li	a0,0
    8000577e:	ffffd097          	auipc	ra,0xffffd
    80005782:	6b0080e7          	jalr	1712(ra) # 80002e2e <argstr>
    80005786:	18054163          	bltz	a0,80005908 <sys_unlink+0x1a2>
  begin_op();
    8000578a:	fffff097          	auipc	ra,0xfffff
    8000578e:	b8e080e7          	jalr	-1138(ra) # 80004318 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005792:	fb040593          	addi	a1,s0,-80
    80005796:	f3040513          	addi	a0,s0,-208
    8000579a:	fffff097          	auipc	ra,0xfffff
    8000579e:	990080e7          	jalr	-1648(ra) # 8000412a <nameiparent>
    800057a2:	84aa                	mv	s1,a0
    800057a4:	c979                	beqz	a0,8000587a <sys_unlink+0x114>
  ilock(dp);
    800057a6:	ffffe097          	auipc	ra,0xffffe
    800057aa:	1b6080e7          	jalr	438(ra) # 8000395c <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800057ae:	00003597          	auipc	a1,0x3
    800057b2:	02a58593          	addi	a1,a1,42 # 800087d8 <syscalls+0x2c0>
    800057b6:	fb040513          	addi	a0,s0,-80
    800057ba:	ffffe097          	auipc	ra,0xffffe
    800057be:	666080e7          	jalr	1638(ra) # 80003e20 <namecmp>
    800057c2:	14050a63          	beqz	a0,80005916 <sys_unlink+0x1b0>
    800057c6:	00003597          	auipc	a1,0x3
    800057ca:	aca58593          	addi	a1,a1,-1334 # 80008290 <digits+0x250>
    800057ce:	fb040513          	addi	a0,s0,-80
    800057d2:	ffffe097          	auipc	ra,0xffffe
    800057d6:	64e080e7          	jalr	1614(ra) # 80003e20 <namecmp>
    800057da:	12050e63          	beqz	a0,80005916 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800057de:	f2c40613          	addi	a2,s0,-212
    800057e2:	fb040593          	addi	a1,s0,-80
    800057e6:	8526                	mv	a0,s1
    800057e8:	ffffe097          	auipc	ra,0xffffe
    800057ec:	652080e7          	jalr	1618(ra) # 80003e3a <dirlookup>
    800057f0:	892a                	mv	s2,a0
    800057f2:	12050263          	beqz	a0,80005916 <sys_unlink+0x1b0>
  ilock(ip);
    800057f6:	ffffe097          	auipc	ra,0xffffe
    800057fa:	166080e7          	jalr	358(ra) # 8000395c <ilock>
  if(ip->nlink < 1)
    800057fe:	04a91783          	lh	a5,74(s2)
    80005802:	08f05263          	blez	a5,80005886 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005806:	04491703          	lh	a4,68(s2)
    8000580a:	4785                	li	a5,1
    8000580c:	08f70563          	beq	a4,a5,80005896 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005810:	4641                	li	a2,16
    80005812:	4581                	li	a1,0
    80005814:	fc040513          	addi	a0,s0,-64
    80005818:	ffffb097          	auipc	ra,0xffffb
    8000581c:	4f4080e7          	jalr	1268(ra) # 80000d0c <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005820:	4741                	li	a4,16
    80005822:	f2c42683          	lw	a3,-212(s0)
    80005826:	fc040613          	addi	a2,s0,-64
    8000582a:	4581                	li	a1,0
    8000582c:	8526                	mv	a0,s1
    8000582e:	ffffe097          	auipc	ra,0xffffe
    80005832:	4d8080e7          	jalr	1240(ra) # 80003d06 <writei>
    80005836:	47c1                	li	a5,16
    80005838:	0af51563          	bne	a0,a5,800058e2 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000583c:	04491703          	lh	a4,68(s2)
    80005840:	4785                	li	a5,1
    80005842:	0af70863          	beq	a4,a5,800058f2 <sys_unlink+0x18c>
  iunlockput(dp);
    80005846:	8526                	mv	a0,s1
    80005848:	ffffe097          	auipc	ra,0xffffe
    8000584c:	376080e7          	jalr	886(ra) # 80003bbe <iunlockput>
  ip->nlink--;
    80005850:	04a95783          	lhu	a5,74(s2)
    80005854:	37fd                	addiw	a5,a5,-1
    80005856:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000585a:	854a                	mv	a0,s2
    8000585c:	ffffe097          	auipc	ra,0xffffe
    80005860:	036080e7          	jalr	54(ra) # 80003892 <iupdate>
  iunlockput(ip);
    80005864:	854a                	mv	a0,s2
    80005866:	ffffe097          	auipc	ra,0xffffe
    8000586a:	358080e7          	jalr	856(ra) # 80003bbe <iunlockput>
  end_op();
    8000586e:	fffff097          	auipc	ra,0xfffff
    80005872:	b2a080e7          	jalr	-1238(ra) # 80004398 <end_op>
  return 0;
    80005876:	4501                	li	a0,0
    80005878:	a84d                	j	8000592a <sys_unlink+0x1c4>
    end_op();
    8000587a:	fffff097          	auipc	ra,0xfffff
    8000587e:	b1e080e7          	jalr	-1250(ra) # 80004398 <end_op>
    return -1;
    80005882:	557d                	li	a0,-1
    80005884:	a05d                	j	8000592a <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005886:	00003517          	auipc	a0,0x3
    8000588a:	f7a50513          	addi	a0,a0,-134 # 80008800 <syscalls+0x2e8>
    8000588e:	ffffb097          	auipc	ra,0xffffb
    80005892:	cba080e7          	jalr	-838(ra) # 80000548 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005896:	04c92703          	lw	a4,76(s2)
    8000589a:	02000793          	li	a5,32
    8000589e:	f6e7f9e3          	bgeu	a5,a4,80005810 <sys_unlink+0xaa>
    800058a2:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800058a6:	4741                	li	a4,16
    800058a8:	86ce                	mv	a3,s3
    800058aa:	f1840613          	addi	a2,s0,-232
    800058ae:	4581                	li	a1,0
    800058b0:	854a                	mv	a0,s2
    800058b2:	ffffe097          	auipc	ra,0xffffe
    800058b6:	35e080e7          	jalr	862(ra) # 80003c10 <readi>
    800058ba:	47c1                	li	a5,16
    800058bc:	00f51b63          	bne	a0,a5,800058d2 <sys_unlink+0x16c>
    if(de.inum != 0)
    800058c0:	f1845783          	lhu	a5,-232(s0)
    800058c4:	e7a1                	bnez	a5,8000590c <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800058c6:	29c1                	addiw	s3,s3,16
    800058c8:	04c92783          	lw	a5,76(s2)
    800058cc:	fcf9ede3          	bltu	s3,a5,800058a6 <sys_unlink+0x140>
    800058d0:	b781                	j	80005810 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800058d2:	00003517          	auipc	a0,0x3
    800058d6:	f4650513          	addi	a0,a0,-186 # 80008818 <syscalls+0x300>
    800058da:	ffffb097          	auipc	ra,0xffffb
    800058de:	c6e080e7          	jalr	-914(ra) # 80000548 <panic>
    panic("unlink: writei");
    800058e2:	00003517          	auipc	a0,0x3
    800058e6:	f4e50513          	addi	a0,a0,-178 # 80008830 <syscalls+0x318>
    800058ea:	ffffb097          	auipc	ra,0xffffb
    800058ee:	c5e080e7          	jalr	-930(ra) # 80000548 <panic>
    dp->nlink--;
    800058f2:	04a4d783          	lhu	a5,74(s1)
    800058f6:	37fd                	addiw	a5,a5,-1
    800058f8:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800058fc:	8526                	mv	a0,s1
    800058fe:	ffffe097          	auipc	ra,0xffffe
    80005902:	f94080e7          	jalr	-108(ra) # 80003892 <iupdate>
    80005906:	b781                	j	80005846 <sys_unlink+0xe0>
    return -1;
    80005908:	557d                	li	a0,-1
    8000590a:	a005                	j	8000592a <sys_unlink+0x1c4>
    iunlockput(ip);
    8000590c:	854a                	mv	a0,s2
    8000590e:	ffffe097          	auipc	ra,0xffffe
    80005912:	2b0080e7          	jalr	688(ra) # 80003bbe <iunlockput>
  iunlockput(dp);
    80005916:	8526                	mv	a0,s1
    80005918:	ffffe097          	auipc	ra,0xffffe
    8000591c:	2a6080e7          	jalr	678(ra) # 80003bbe <iunlockput>
  end_op();
    80005920:	fffff097          	auipc	ra,0xfffff
    80005924:	a78080e7          	jalr	-1416(ra) # 80004398 <end_op>
  return -1;
    80005928:	557d                	li	a0,-1
}
    8000592a:	70ae                	ld	ra,232(sp)
    8000592c:	740e                	ld	s0,224(sp)
    8000592e:	64ee                	ld	s1,216(sp)
    80005930:	694e                	ld	s2,208(sp)
    80005932:	69ae                	ld	s3,200(sp)
    80005934:	616d                	addi	sp,sp,240
    80005936:	8082                	ret

0000000080005938 <sys_open>:

uint64
sys_open(void)
{
    80005938:	7131                	addi	sp,sp,-192
    8000593a:	fd06                	sd	ra,184(sp)
    8000593c:	f922                	sd	s0,176(sp)
    8000593e:	f526                	sd	s1,168(sp)
    80005940:	f14a                	sd	s2,160(sp)
    80005942:	ed4e                	sd	s3,152(sp)
    80005944:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005946:	08000613          	li	a2,128
    8000594a:	f5040593          	addi	a1,s0,-176
    8000594e:	4501                	li	a0,0
    80005950:	ffffd097          	auipc	ra,0xffffd
    80005954:	4de080e7          	jalr	1246(ra) # 80002e2e <argstr>
    return -1;
    80005958:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000595a:	0c054163          	bltz	a0,80005a1c <sys_open+0xe4>
    8000595e:	f4c40593          	addi	a1,s0,-180
    80005962:	4505                	li	a0,1
    80005964:	ffffd097          	auipc	ra,0xffffd
    80005968:	486080e7          	jalr	1158(ra) # 80002dea <argint>
    8000596c:	0a054863          	bltz	a0,80005a1c <sys_open+0xe4>

  begin_op();
    80005970:	fffff097          	auipc	ra,0xfffff
    80005974:	9a8080e7          	jalr	-1624(ra) # 80004318 <begin_op>

  if(omode & O_CREATE){
    80005978:	f4c42783          	lw	a5,-180(s0)
    8000597c:	2007f793          	andi	a5,a5,512
    80005980:	cbdd                	beqz	a5,80005a36 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005982:	4681                	li	a3,0
    80005984:	4601                	li	a2,0
    80005986:	4589                	li	a1,2
    80005988:	f5040513          	addi	a0,s0,-176
    8000598c:	00000097          	auipc	ra,0x0
    80005990:	972080e7          	jalr	-1678(ra) # 800052fe <create>
    80005994:	892a                	mv	s2,a0
    if(ip == 0){
    80005996:	c959                	beqz	a0,80005a2c <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005998:	04491703          	lh	a4,68(s2)
    8000599c:	478d                	li	a5,3
    8000599e:	00f71763          	bne	a4,a5,800059ac <sys_open+0x74>
    800059a2:	04695703          	lhu	a4,70(s2)
    800059a6:	47a5                	li	a5,9
    800059a8:	0ce7ec63          	bltu	a5,a4,80005a80 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800059ac:	fffff097          	auipc	ra,0xfffff
    800059b0:	d82080e7          	jalr	-638(ra) # 8000472e <filealloc>
    800059b4:	89aa                	mv	s3,a0
    800059b6:	10050263          	beqz	a0,80005aba <sys_open+0x182>
    800059ba:	00000097          	auipc	ra,0x0
    800059be:	902080e7          	jalr	-1790(ra) # 800052bc <fdalloc>
    800059c2:	84aa                	mv	s1,a0
    800059c4:	0e054663          	bltz	a0,80005ab0 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800059c8:	04491703          	lh	a4,68(s2)
    800059cc:	478d                	li	a5,3
    800059ce:	0cf70463          	beq	a4,a5,80005a96 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800059d2:	4789                	li	a5,2
    800059d4:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800059d8:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800059dc:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800059e0:	f4c42783          	lw	a5,-180(s0)
    800059e4:	0017c713          	xori	a4,a5,1
    800059e8:	8b05                	andi	a4,a4,1
    800059ea:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800059ee:	0037f713          	andi	a4,a5,3
    800059f2:	00e03733          	snez	a4,a4
    800059f6:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800059fa:	4007f793          	andi	a5,a5,1024
    800059fe:	c791                	beqz	a5,80005a0a <sys_open+0xd2>
    80005a00:	04491703          	lh	a4,68(s2)
    80005a04:	4789                	li	a5,2
    80005a06:	08f70f63          	beq	a4,a5,80005aa4 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005a0a:	854a                	mv	a0,s2
    80005a0c:	ffffe097          	auipc	ra,0xffffe
    80005a10:	012080e7          	jalr	18(ra) # 80003a1e <iunlock>
  end_op();
    80005a14:	fffff097          	auipc	ra,0xfffff
    80005a18:	984080e7          	jalr	-1660(ra) # 80004398 <end_op>

  return fd;
}
    80005a1c:	8526                	mv	a0,s1
    80005a1e:	70ea                	ld	ra,184(sp)
    80005a20:	744a                	ld	s0,176(sp)
    80005a22:	74aa                	ld	s1,168(sp)
    80005a24:	790a                	ld	s2,160(sp)
    80005a26:	69ea                	ld	s3,152(sp)
    80005a28:	6129                	addi	sp,sp,192
    80005a2a:	8082                	ret
      end_op();
    80005a2c:	fffff097          	auipc	ra,0xfffff
    80005a30:	96c080e7          	jalr	-1684(ra) # 80004398 <end_op>
      return -1;
    80005a34:	b7e5                	j	80005a1c <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005a36:	f5040513          	addi	a0,s0,-176
    80005a3a:	ffffe097          	auipc	ra,0xffffe
    80005a3e:	6d2080e7          	jalr	1746(ra) # 8000410c <namei>
    80005a42:	892a                	mv	s2,a0
    80005a44:	c905                	beqz	a0,80005a74 <sys_open+0x13c>
    ilock(ip);
    80005a46:	ffffe097          	auipc	ra,0xffffe
    80005a4a:	f16080e7          	jalr	-234(ra) # 8000395c <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005a4e:	04491703          	lh	a4,68(s2)
    80005a52:	4785                	li	a5,1
    80005a54:	f4f712e3          	bne	a4,a5,80005998 <sys_open+0x60>
    80005a58:	f4c42783          	lw	a5,-180(s0)
    80005a5c:	dba1                	beqz	a5,800059ac <sys_open+0x74>
      iunlockput(ip);
    80005a5e:	854a                	mv	a0,s2
    80005a60:	ffffe097          	auipc	ra,0xffffe
    80005a64:	15e080e7          	jalr	350(ra) # 80003bbe <iunlockput>
      end_op();
    80005a68:	fffff097          	auipc	ra,0xfffff
    80005a6c:	930080e7          	jalr	-1744(ra) # 80004398 <end_op>
      return -1;
    80005a70:	54fd                	li	s1,-1
    80005a72:	b76d                	j	80005a1c <sys_open+0xe4>
      end_op();
    80005a74:	fffff097          	auipc	ra,0xfffff
    80005a78:	924080e7          	jalr	-1756(ra) # 80004398 <end_op>
      return -1;
    80005a7c:	54fd                	li	s1,-1
    80005a7e:	bf79                	j	80005a1c <sys_open+0xe4>
    iunlockput(ip);
    80005a80:	854a                	mv	a0,s2
    80005a82:	ffffe097          	auipc	ra,0xffffe
    80005a86:	13c080e7          	jalr	316(ra) # 80003bbe <iunlockput>
    end_op();
    80005a8a:	fffff097          	auipc	ra,0xfffff
    80005a8e:	90e080e7          	jalr	-1778(ra) # 80004398 <end_op>
    return -1;
    80005a92:	54fd                	li	s1,-1
    80005a94:	b761                	j	80005a1c <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005a96:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005a9a:	04691783          	lh	a5,70(s2)
    80005a9e:	02f99223          	sh	a5,36(s3)
    80005aa2:	bf2d                	j	800059dc <sys_open+0xa4>
    itrunc(ip);
    80005aa4:	854a                	mv	a0,s2
    80005aa6:	ffffe097          	auipc	ra,0xffffe
    80005aaa:	fc4080e7          	jalr	-60(ra) # 80003a6a <itrunc>
    80005aae:	bfb1                	j	80005a0a <sys_open+0xd2>
      fileclose(f);
    80005ab0:	854e                	mv	a0,s3
    80005ab2:	fffff097          	auipc	ra,0xfffff
    80005ab6:	d38080e7          	jalr	-712(ra) # 800047ea <fileclose>
    iunlockput(ip);
    80005aba:	854a                	mv	a0,s2
    80005abc:	ffffe097          	auipc	ra,0xffffe
    80005ac0:	102080e7          	jalr	258(ra) # 80003bbe <iunlockput>
    end_op();
    80005ac4:	fffff097          	auipc	ra,0xfffff
    80005ac8:	8d4080e7          	jalr	-1836(ra) # 80004398 <end_op>
    return -1;
    80005acc:	54fd                	li	s1,-1
    80005ace:	b7b9                	j	80005a1c <sys_open+0xe4>

0000000080005ad0 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005ad0:	7175                	addi	sp,sp,-144
    80005ad2:	e506                	sd	ra,136(sp)
    80005ad4:	e122                	sd	s0,128(sp)
    80005ad6:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005ad8:	fffff097          	auipc	ra,0xfffff
    80005adc:	840080e7          	jalr	-1984(ra) # 80004318 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005ae0:	08000613          	li	a2,128
    80005ae4:	f7040593          	addi	a1,s0,-144
    80005ae8:	4501                	li	a0,0
    80005aea:	ffffd097          	auipc	ra,0xffffd
    80005aee:	344080e7          	jalr	836(ra) # 80002e2e <argstr>
    80005af2:	02054963          	bltz	a0,80005b24 <sys_mkdir+0x54>
    80005af6:	4681                	li	a3,0
    80005af8:	4601                	li	a2,0
    80005afa:	4585                	li	a1,1
    80005afc:	f7040513          	addi	a0,s0,-144
    80005b00:	fffff097          	auipc	ra,0xfffff
    80005b04:	7fe080e7          	jalr	2046(ra) # 800052fe <create>
    80005b08:	cd11                	beqz	a0,80005b24 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b0a:	ffffe097          	auipc	ra,0xffffe
    80005b0e:	0b4080e7          	jalr	180(ra) # 80003bbe <iunlockput>
  end_op();
    80005b12:	fffff097          	auipc	ra,0xfffff
    80005b16:	886080e7          	jalr	-1914(ra) # 80004398 <end_op>
  return 0;
    80005b1a:	4501                	li	a0,0
}
    80005b1c:	60aa                	ld	ra,136(sp)
    80005b1e:	640a                	ld	s0,128(sp)
    80005b20:	6149                	addi	sp,sp,144
    80005b22:	8082                	ret
    end_op();
    80005b24:	fffff097          	auipc	ra,0xfffff
    80005b28:	874080e7          	jalr	-1932(ra) # 80004398 <end_op>
    return -1;
    80005b2c:	557d                	li	a0,-1
    80005b2e:	b7fd                	j	80005b1c <sys_mkdir+0x4c>

0000000080005b30 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005b30:	7135                	addi	sp,sp,-160
    80005b32:	ed06                	sd	ra,152(sp)
    80005b34:	e922                	sd	s0,144(sp)
    80005b36:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005b38:	ffffe097          	auipc	ra,0xffffe
    80005b3c:	7e0080e7          	jalr	2016(ra) # 80004318 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b40:	08000613          	li	a2,128
    80005b44:	f7040593          	addi	a1,s0,-144
    80005b48:	4501                	li	a0,0
    80005b4a:	ffffd097          	auipc	ra,0xffffd
    80005b4e:	2e4080e7          	jalr	740(ra) # 80002e2e <argstr>
    80005b52:	04054a63          	bltz	a0,80005ba6 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005b56:	f6c40593          	addi	a1,s0,-148
    80005b5a:	4505                	li	a0,1
    80005b5c:	ffffd097          	auipc	ra,0xffffd
    80005b60:	28e080e7          	jalr	654(ra) # 80002dea <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b64:	04054163          	bltz	a0,80005ba6 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005b68:	f6840593          	addi	a1,s0,-152
    80005b6c:	4509                	li	a0,2
    80005b6e:	ffffd097          	auipc	ra,0xffffd
    80005b72:	27c080e7          	jalr	636(ra) # 80002dea <argint>
     argint(1, &major) < 0 ||
    80005b76:	02054863          	bltz	a0,80005ba6 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005b7a:	f6841683          	lh	a3,-152(s0)
    80005b7e:	f6c41603          	lh	a2,-148(s0)
    80005b82:	458d                	li	a1,3
    80005b84:	f7040513          	addi	a0,s0,-144
    80005b88:	fffff097          	auipc	ra,0xfffff
    80005b8c:	776080e7          	jalr	1910(ra) # 800052fe <create>
     argint(2, &minor) < 0 ||
    80005b90:	c919                	beqz	a0,80005ba6 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b92:	ffffe097          	auipc	ra,0xffffe
    80005b96:	02c080e7          	jalr	44(ra) # 80003bbe <iunlockput>
  end_op();
    80005b9a:	ffffe097          	auipc	ra,0xffffe
    80005b9e:	7fe080e7          	jalr	2046(ra) # 80004398 <end_op>
  return 0;
    80005ba2:	4501                	li	a0,0
    80005ba4:	a031                	j	80005bb0 <sys_mknod+0x80>
    end_op();
    80005ba6:	ffffe097          	auipc	ra,0xffffe
    80005baa:	7f2080e7          	jalr	2034(ra) # 80004398 <end_op>
    return -1;
    80005bae:	557d                	li	a0,-1
}
    80005bb0:	60ea                	ld	ra,152(sp)
    80005bb2:	644a                	ld	s0,144(sp)
    80005bb4:	610d                	addi	sp,sp,160
    80005bb6:	8082                	ret

0000000080005bb8 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005bb8:	7135                	addi	sp,sp,-160
    80005bba:	ed06                	sd	ra,152(sp)
    80005bbc:	e922                	sd	s0,144(sp)
    80005bbe:	e526                	sd	s1,136(sp)
    80005bc0:	e14a                	sd	s2,128(sp)
    80005bc2:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005bc4:	ffffc097          	auipc	ra,0xffffc
    80005bc8:	04c080e7          	jalr	76(ra) # 80001c10 <myproc>
    80005bcc:	892a                	mv	s2,a0
  
  begin_op();
    80005bce:	ffffe097          	auipc	ra,0xffffe
    80005bd2:	74a080e7          	jalr	1866(ra) # 80004318 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005bd6:	08000613          	li	a2,128
    80005bda:	f6040593          	addi	a1,s0,-160
    80005bde:	4501                	li	a0,0
    80005be0:	ffffd097          	auipc	ra,0xffffd
    80005be4:	24e080e7          	jalr	590(ra) # 80002e2e <argstr>
    80005be8:	04054b63          	bltz	a0,80005c3e <sys_chdir+0x86>
    80005bec:	f6040513          	addi	a0,s0,-160
    80005bf0:	ffffe097          	auipc	ra,0xffffe
    80005bf4:	51c080e7          	jalr	1308(ra) # 8000410c <namei>
    80005bf8:	84aa                	mv	s1,a0
    80005bfa:	c131                	beqz	a0,80005c3e <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005bfc:	ffffe097          	auipc	ra,0xffffe
    80005c00:	d60080e7          	jalr	-672(ra) # 8000395c <ilock>
  if(ip->type != T_DIR){
    80005c04:	04449703          	lh	a4,68(s1)
    80005c08:	4785                	li	a5,1
    80005c0a:	04f71063          	bne	a4,a5,80005c4a <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005c0e:	8526                	mv	a0,s1
    80005c10:	ffffe097          	auipc	ra,0xffffe
    80005c14:	e0e080e7          	jalr	-498(ra) # 80003a1e <iunlock>
  iput(p->cwd);
    80005c18:	15093503          	ld	a0,336(s2)
    80005c1c:	ffffe097          	auipc	ra,0xffffe
    80005c20:	efa080e7          	jalr	-262(ra) # 80003b16 <iput>
  end_op();
    80005c24:	ffffe097          	auipc	ra,0xffffe
    80005c28:	774080e7          	jalr	1908(ra) # 80004398 <end_op>
  p->cwd = ip;
    80005c2c:	14993823          	sd	s1,336(s2)
  return 0;
    80005c30:	4501                	li	a0,0
}
    80005c32:	60ea                	ld	ra,152(sp)
    80005c34:	644a                	ld	s0,144(sp)
    80005c36:	64aa                	ld	s1,136(sp)
    80005c38:	690a                	ld	s2,128(sp)
    80005c3a:	610d                	addi	sp,sp,160
    80005c3c:	8082                	ret
    end_op();
    80005c3e:	ffffe097          	auipc	ra,0xffffe
    80005c42:	75a080e7          	jalr	1882(ra) # 80004398 <end_op>
    return -1;
    80005c46:	557d                	li	a0,-1
    80005c48:	b7ed                	j	80005c32 <sys_chdir+0x7a>
    iunlockput(ip);
    80005c4a:	8526                	mv	a0,s1
    80005c4c:	ffffe097          	auipc	ra,0xffffe
    80005c50:	f72080e7          	jalr	-142(ra) # 80003bbe <iunlockput>
    end_op();
    80005c54:	ffffe097          	auipc	ra,0xffffe
    80005c58:	744080e7          	jalr	1860(ra) # 80004398 <end_op>
    return -1;
    80005c5c:	557d                	li	a0,-1
    80005c5e:	bfd1                	j	80005c32 <sys_chdir+0x7a>

0000000080005c60 <sys_exec>:

uint64
sys_exec(void)
{
    80005c60:	7145                	addi	sp,sp,-464
    80005c62:	e786                	sd	ra,456(sp)
    80005c64:	e3a2                	sd	s0,448(sp)
    80005c66:	ff26                	sd	s1,440(sp)
    80005c68:	fb4a                	sd	s2,432(sp)
    80005c6a:	f74e                	sd	s3,424(sp)
    80005c6c:	f352                	sd	s4,416(sp)
    80005c6e:	ef56                	sd	s5,408(sp)
    80005c70:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005c72:	08000613          	li	a2,128
    80005c76:	f4040593          	addi	a1,s0,-192
    80005c7a:	4501                	li	a0,0
    80005c7c:	ffffd097          	auipc	ra,0xffffd
    80005c80:	1b2080e7          	jalr	434(ra) # 80002e2e <argstr>
    return -1;
    80005c84:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005c86:	0c054a63          	bltz	a0,80005d5a <sys_exec+0xfa>
    80005c8a:	e3840593          	addi	a1,s0,-456
    80005c8e:	4505                	li	a0,1
    80005c90:	ffffd097          	auipc	ra,0xffffd
    80005c94:	17c080e7          	jalr	380(ra) # 80002e0c <argaddr>
    80005c98:	0c054163          	bltz	a0,80005d5a <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005c9c:	10000613          	li	a2,256
    80005ca0:	4581                	li	a1,0
    80005ca2:	e4040513          	addi	a0,s0,-448
    80005ca6:	ffffb097          	auipc	ra,0xffffb
    80005caa:	066080e7          	jalr	102(ra) # 80000d0c <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005cae:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005cb2:	89a6                	mv	s3,s1
    80005cb4:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005cb6:	02000a13          	li	s4,32
    80005cba:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005cbe:	00391513          	slli	a0,s2,0x3
    80005cc2:	e3040593          	addi	a1,s0,-464
    80005cc6:	e3843783          	ld	a5,-456(s0)
    80005cca:	953e                	add	a0,a0,a5
    80005ccc:	ffffd097          	auipc	ra,0xffffd
    80005cd0:	084080e7          	jalr	132(ra) # 80002d50 <fetchaddr>
    80005cd4:	02054a63          	bltz	a0,80005d08 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005cd8:	e3043783          	ld	a5,-464(s0)
    80005cdc:	c3b9                	beqz	a5,80005d22 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005cde:	ffffb097          	auipc	ra,0xffffb
    80005ce2:	e42080e7          	jalr	-446(ra) # 80000b20 <kalloc>
    80005ce6:	85aa                	mv	a1,a0
    80005ce8:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005cec:	cd11                	beqz	a0,80005d08 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005cee:	6605                	lui	a2,0x1
    80005cf0:	e3043503          	ld	a0,-464(s0)
    80005cf4:	ffffd097          	auipc	ra,0xffffd
    80005cf8:	0ae080e7          	jalr	174(ra) # 80002da2 <fetchstr>
    80005cfc:	00054663          	bltz	a0,80005d08 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005d00:	0905                	addi	s2,s2,1
    80005d02:	09a1                	addi	s3,s3,8
    80005d04:	fb491be3          	bne	s2,s4,80005cba <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d08:	10048913          	addi	s2,s1,256
    80005d0c:	6088                	ld	a0,0(s1)
    80005d0e:	c529                	beqz	a0,80005d58 <sys_exec+0xf8>
    kfree(argv[i]);
    80005d10:	ffffb097          	auipc	ra,0xffffb
    80005d14:	d14080e7          	jalr	-748(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d18:	04a1                	addi	s1,s1,8
    80005d1a:	ff2499e3          	bne	s1,s2,80005d0c <sys_exec+0xac>
  return -1;
    80005d1e:	597d                	li	s2,-1
    80005d20:	a82d                	j	80005d5a <sys_exec+0xfa>
      argv[i] = 0;
    80005d22:	0a8e                	slli	s5,s5,0x3
    80005d24:	fc040793          	addi	a5,s0,-64
    80005d28:	9abe                	add	s5,s5,a5
    80005d2a:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005d2e:	e4040593          	addi	a1,s0,-448
    80005d32:	f4040513          	addi	a0,s0,-192
    80005d36:	fffff097          	auipc	ra,0xfffff
    80005d3a:	164080e7          	jalr	356(ra) # 80004e9a <exec>
    80005d3e:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d40:	10048993          	addi	s3,s1,256
    80005d44:	6088                	ld	a0,0(s1)
    80005d46:	c911                	beqz	a0,80005d5a <sys_exec+0xfa>
    kfree(argv[i]);
    80005d48:	ffffb097          	auipc	ra,0xffffb
    80005d4c:	cdc080e7          	jalr	-804(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d50:	04a1                	addi	s1,s1,8
    80005d52:	ff3499e3          	bne	s1,s3,80005d44 <sys_exec+0xe4>
    80005d56:	a011                	j	80005d5a <sys_exec+0xfa>
  return -1;
    80005d58:	597d                	li	s2,-1
}
    80005d5a:	854a                	mv	a0,s2
    80005d5c:	60be                	ld	ra,456(sp)
    80005d5e:	641e                	ld	s0,448(sp)
    80005d60:	74fa                	ld	s1,440(sp)
    80005d62:	795a                	ld	s2,432(sp)
    80005d64:	79ba                	ld	s3,424(sp)
    80005d66:	7a1a                	ld	s4,416(sp)
    80005d68:	6afa                	ld	s5,408(sp)
    80005d6a:	6179                	addi	sp,sp,464
    80005d6c:	8082                	ret

0000000080005d6e <sys_pipe>:

uint64
sys_pipe(void)
{
    80005d6e:	7139                	addi	sp,sp,-64
    80005d70:	fc06                	sd	ra,56(sp)
    80005d72:	f822                	sd	s0,48(sp)
    80005d74:	f426                	sd	s1,40(sp)
    80005d76:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005d78:	ffffc097          	auipc	ra,0xffffc
    80005d7c:	e98080e7          	jalr	-360(ra) # 80001c10 <myproc>
    80005d80:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005d82:	fd840593          	addi	a1,s0,-40
    80005d86:	4501                	li	a0,0
    80005d88:	ffffd097          	auipc	ra,0xffffd
    80005d8c:	084080e7          	jalr	132(ra) # 80002e0c <argaddr>
    return -1;
    80005d90:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005d92:	0e054063          	bltz	a0,80005e72 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005d96:	fc840593          	addi	a1,s0,-56
    80005d9a:	fd040513          	addi	a0,s0,-48
    80005d9e:	fffff097          	auipc	ra,0xfffff
    80005da2:	da2080e7          	jalr	-606(ra) # 80004b40 <pipealloc>
    return -1;
    80005da6:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005da8:	0c054563          	bltz	a0,80005e72 <sys_pipe+0x104>
  fd0 = -1;
    80005dac:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005db0:	fd043503          	ld	a0,-48(s0)
    80005db4:	fffff097          	auipc	ra,0xfffff
    80005db8:	508080e7          	jalr	1288(ra) # 800052bc <fdalloc>
    80005dbc:	fca42223          	sw	a0,-60(s0)
    80005dc0:	08054c63          	bltz	a0,80005e58 <sys_pipe+0xea>
    80005dc4:	fc843503          	ld	a0,-56(s0)
    80005dc8:	fffff097          	auipc	ra,0xfffff
    80005dcc:	4f4080e7          	jalr	1268(ra) # 800052bc <fdalloc>
    80005dd0:	fca42023          	sw	a0,-64(s0)
    80005dd4:	06054863          	bltz	a0,80005e44 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005dd8:	4691                	li	a3,4
    80005dda:	fc440613          	addi	a2,s0,-60
    80005dde:	fd843583          	ld	a1,-40(s0)
    80005de2:	68a8                	ld	a0,80(s1)
    80005de4:	ffffc097          	auipc	ra,0xffffc
    80005de8:	b04080e7          	jalr	-1276(ra) # 800018e8 <copyout>
    80005dec:	02054063          	bltz	a0,80005e0c <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005df0:	4691                	li	a3,4
    80005df2:	fc040613          	addi	a2,s0,-64
    80005df6:	fd843583          	ld	a1,-40(s0)
    80005dfa:	0591                	addi	a1,a1,4
    80005dfc:	68a8                	ld	a0,80(s1)
    80005dfe:	ffffc097          	auipc	ra,0xffffc
    80005e02:	aea080e7          	jalr	-1302(ra) # 800018e8 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005e06:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e08:	06055563          	bgez	a0,80005e72 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005e0c:	fc442783          	lw	a5,-60(s0)
    80005e10:	07e9                	addi	a5,a5,26
    80005e12:	078e                	slli	a5,a5,0x3
    80005e14:	97a6                	add	a5,a5,s1
    80005e16:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005e1a:	fc042503          	lw	a0,-64(s0)
    80005e1e:	0569                	addi	a0,a0,26
    80005e20:	050e                	slli	a0,a0,0x3
    80005e22:	9526                	add	a0,a0,s1
    80005e24:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005e28:	fd043503          	ld	a0,-48(s0)
    80005e2c:	fffff097          	auipc	ra,0xfffff
    80005e30:	9be080e7          	jalr	-1602(ra) # 800047ea <fileclose>
    fileclose(wf);
    80005e34:	fc843503          	ld	a0,-56(s0)
    80005e38:	fffff097          	auipc	ra,0xfffff
    80005e3c:	9b2080e7          	jalr	-1614(ra) # 800047ea <fileclose>
    return -1;
    80005e40:	57fd                	li	a5,-1
    80005e42:	a805                	j	80005e72 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005e44:	fc442783          	lw	a5,-60(s0)
    80005e48:	0007c863          	bltz	a5,80005e58 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005e4c:	01a78513          	addi	a0,a5,26
    80005e50:	050e                	slli	a0,a0,0x3
    80005e52:	9526                	add	a0,a0,s1
    80005e54:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005e58:	fd043503          	ld	a0,-48(s0)
    80005e5c:	fffff097          	auipc	ra,0xfffff
    80005e60:	98e080e7          	jalr	-1650(ra) # 800047ea <fileclose>
    fileclose(wf);
    80005e64:	fc843503          	ld	a0,-56(s0)
    80005e68:	fffff097          	auipc	ra,0xfffff
    80005e6c:	982080e7          	jalr	-1662(ra) # 800047ea <fileclose>
    return -1;
    80005e70:	57fd                	li	a5,-1
}
    80005e72:	853e                	mv	a0,a5
    80005e74:	70e2                	ld	ra,56(sp)
    80005e76:	7442                	ld	s0,48(sp)
    80005e78:	74a2                	ld	s1,40(sp)
    80005e7a:	6121                	addi	sp,sp,64
    80005e7c:	8082                	ret
	...

0000000080005e80 <kernelvec>:
    80005e80:	7111                	addi	sp,sp,-256
    80005e82:	e006                	sd	ra,0(sp)
    80005e84:	e40a                	sd	sp,8(sp)
    80005e86:	e80e                	sd	gp,16(sp)
    80005e88:	ec12                	sd	tp,24(sp)
    80005e8a:	f016                	sd	t0,32(sp)
    80005e8c:	f41a                	sd	t1,40(sp)
    80005e8e:	f81e                	sd	t2,48(sp)
    80005e90:	fc22                	sd	s0,56(sp)
    80005e92:	e0a6                	sd	s1,64(sp)
    80005e94:	e4aa                	sd	a0,72(sp)
    80005e96:	e8ae                	sd	a1,80(sp)
    80005e98:	ecb2                	sd	a2,88(sp)
    80005e9a:	f0b6                	sd	a3,96(sp)
    80005e9c:	f4ba                	sd	a4,104(sp)
    80005e9e:	f8be                	sd	a5,112(sp)
    80005ea0:	fcc2                	sd	a6,120(sp)
    80005ea2:	e146                	sd	a7,128(sp)
    80005ea4:	e54a                	sd	s2,136(sp)
    80005ea6:	e94e                	sd	s3,144(sp)
    80005ea8:	ed52                	sd	s4,152(sp)
    80005eaa:	f156                	sd	s5,160(sp)
    80005eac:	f55a                	sd	s6,168(sp)
    80005eae:	f95e                	sd	s7,176(sp)
    80005eb0:	fd62                	sd	s8,184(sp)
    80005eb2:	e1e6                	sd	s9,192(sp)
    80005eb4:	e5ea                	sd	s10,200(sp)
    80005eb6:	e9ee                	sd	s11,208(sp)
    80005eb8:	edf2                	sd	t3,216(sp)
    80005eba:	f1f6                	sd	t4,224(sp)
    80005ebc:	f5fa                	sd	t5,232(sp)
    80005ebe:	f9fe                	sd	t6,240(sp)
    80005ec0:	d5dfc0ef          	jal	ra,80002c1c <kerneltrap>
    80005ec4:	6082                	ld	ra,0(sp)
    80005ec6:	6122                	ld	sp,8(sp)
    80005ec8:	61c2                	ld	gp,16(sp)
    80005eca:	7282                	ld	t0,32(sp)
    80005ecc:	7322                	ld	t1,40(sp)
    80005ece:	73c2                	ld	t2,48(sp)
    80005ed0:	7462                	ld	s0,56(sp)
    80005ed2:	6486                	ld	s1,64(sp)
    80005ed4:	6526                	ld	a0,72(sp)
    80005ed6:	65c6                	ld	a1,80(sp)
    80005ed8:	6666                	ld	a2,88(sp)
    80005eda:	7686                	ld	a3,96(sp)
    80005edc:	7726                	ld	a4,104(sp)
    80005ede:	77c6                	ld	a5,112(sp)
    80005ee0:	7866                	ld	a6,120(sp)
    80005ee2:	688a                	ld	a7,128(sp)
    80005ee4:	692a                	ld	s2,136(sp)
    80005ee6:	69ca                	ld	s3,144(sp)
    80005ee8:	6a6a                	ld	s4,152(sp)
    80005eea:	7a8a                	ld	s5,160(sp)
    80005eec:	7b2a                	ld	s6,168(sp)
    80005eee:	7bca                	ld	s7,176(sp)
    80005ef0:	7c6a                	ld	s8,184(sp)
    80005ef2:	6c8e                	ld	s9,192(sp)
    80005ef4:	6d2e                	ld	s10,200(sp)
    80005ef6:	6dce                	ld	s11,208(sp)
    80005ef8:	6e6e                	ld	t3,216(sp)
    80005efa:	7e8e                	ld	t4,224(sp)
    80005efc:	7f2e                	ld	t5,232(sp)
    80005efe:	7fce                	ld	t6,240(sp)
    80005f00:	6111                	addi	sp,sp,256
    80005f02:	10200073          	sret
    80005f06:	00000013          	nop
    80005f0a:	00000013          	nop
    80005f0e:	0001                	nop

0000000080005f10 <timervec>:
    80005f10:	34051573          	csrrw	a0,mscratch,a0
    80005f14:	e10c                	sd	a1,0(a0)
    80005f16:	e510                	sd	a2,8(a0)
    80005f18:	e914                	sd	a3,16(a0)
    80005f1a:	710c                	ld	a1,32(a0)
    80005f1c:	7510                	ld	a2,40(a0)
    80005f1e:	6194                	ld	a3,0(a1)
    80005f20:	96b2                	add	a3,a3,a2
    80005f22:	e194                	sd	a3,0(a1)
    80005f24:	4589                	li	a1,2
    80005f26:	14459073          	csrw	sip,a1
    80005f2a:	6914                	ld	a3,16(a0)
    80005f2c:	6510                	ld	a2,8(a0)
    80005f2e:	610c                	ld	a1,0(a0)
    80005f30:	34051573          	csrrw	a0,mscratch,a0
    80005f34:	30200073          	mret
	...

0000000080005f3a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005f3a:	1141                	addi	sp,sp,-16
    80005f3c:	e422                	sd	s0,8(sp)
    80005f3e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005f40:	0c0007b7          	lui	a5,0xc000
    80005f44:	4705                	li	a4,1
    80005f46:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005f48:	c3d8                	sw	a4,4(a5)
}
    80005f4a:	6422                	ld	s0,8(sp)
    80005f4c:	0141                	addi	sp,sp,16
    80005f4e:	8082                	ret

0000000080005f50 <plicinithart>:

void
plicinithart(void)
{
    80005f50:	1141                	addi	sp,sp,-16
    80005f52:	e406                	sd	ra,8(sp)
    80005f54:	e022                	sd	s0,0(sp)
    80005f56:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f58:	ffffc097          	auipc	ra,0xffffc
    80005f5c:	c8c080e7          	jalr	-884(ra) # 80001be4 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005f60:	0085171b          	slliw	a4,a0,0x8
    80005f64:	0c0027b7          	lui	a5,0xc002
    80005f68:	97ba                	add	a5,a5,a4
    80005f6a:	40200713          	li	a4,1026
    80005f6e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005f72:	00d5151b          	slliw	a0,a0,0xd
    80005f76:	0c2017b7          	lui	a5,0xc201
    80005f7a:	953e                	add	a0,a0,a5
    80005f7c:	00052023          	sw	zero,0(a0)
}
    80005f80:	60a2                	ld	ra,8(sp)
    80005f82:	6402                	ld	s0,0(sp)
    80005f84:	0141                	addi	sp,sp,16
    80005f86:	8082                	ret

0000000080005f88 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005f88:	1141                	addi	sp,sp,-16
    80005f8a:	e406                	sd	ra,8(sp)
    80005f8c:	e022                	sd	s0,0(sp)
    80005f8e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f90:	ffffc097          	auipc	ra,0xffffc
    80005f94:	c54080e7          	jalr	-940(ra) # 80001be4 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005f98:	00d5179b          	slliw	a5,a0,0xd
    80005f9c:	0c201537          	lui	a0,0xc201
    80005fa0:	953e                	add	a0,a0,a5
  return irq;
}
    80005fa2:	4148                	lw	a0,4(a0)
    80005fa4:	60a2                	ld	ra,8(sp)
    80005fa6:	6402                	ld	s0,0(sp)
    80005fa8:	0141                	addi	sp,sp,16
    80005faa:	8082                	ret

0000000080005fac <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005fac:	1101                	addi	sp,sp,-32
    80005fae:	ec06                	sd	ra,24(sp)
    80005fb0:	e822                	sd	s0,16(sp)
    80005fb2:	e426                	sd	s1,8(sp)
    80005fb4:	1000                	addi	s0,sp,32
    80005fb6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005fb8:	ffffc097          	auipc	ra,0xffffc
    80005fbc:	c2c080e7          	jalr	-980(ra) # 80001be4 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005fc0:	00d5151b          	slliw	a0,a0,0xd
    80005fc4:	0c2017b7          	lui	a5,0xc201
    80005fc8:	97aa                	add	a5,a5,a0
    80005fca:	c3c4                	sw	s1,4(a5)
}
    80005fcc:	60e2                	ld	ra,24(sp)
    80005fce:	6442                	ld	s0,16(sp)
    80005fd0:	64a2                	ld	s1,8(sp)
    80005fd2:	6105                	addi	sp,sp,32
    80005fd4:	8082                	ret

0000000080005fd6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005fd6:	1141                	addi	sp,sp,-16
    80005fd8:	e406                	sd	ra,8(sp)
    80005fda:	e022                	sd	s0,0(sp)
    80005fdc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005fde:	479d                	li	a5,7
    80005fe0:	04a7cc63          	blt	a5,a0,80006038 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005fe4:	0001d797          	auipc	a5,0x1d
    80005fe8:	01c78793          	addi	a5,a5,28 # 80023000 <disk>
    80005fec:	00a78733          	add	a4,a5,a0
    80005ff0:	6789                	lui	a5,0x2
    80005ff2:	97ba                	add	a5,a5,a4
    80005ff4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005ff8:	eba1                	bnez	a5,80006048 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005ffa:	00451713          	slli	a4,a0,0x4
    80005ffe:	0001f797          	auipc	a5,0x1f
    80006002:	0027b783          	ld	a5,2(a5) # 80025000 <disk+0x2000>
    80006006:	97ba                	add	a5,a5,a4
    80006008:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    8000600c:	0001d797          	auipc	a5,0x1d
    80006010:	ff478793          	addi	a5,a5,-12 # 80023000 <disk>
    80006014:	97aa                	add	a5,a5,a0
    80006016:	6509                	lui	a0,0x2
    80006018:	953e                	add	a0,a0,a5
    8000601a:	4785                	li	a5,1
    8000601c:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80006020:	0001f517          	auipc	a0,0x1f
    80006024:	ff850513          	addi	a0,a0,-8 # 80025018 <disk+0x2018>
    80006028:	ffffc097          	auipc	ra,0xffffc
    8000602c:	69a080e7          	jalr	1690(ra) # 800026c2 <wakeup>
}
    80006030:	60a2                	ld	ra,8(sp)
    80006032:	6402                	ld	s0,0(sp)
    80006034:	0141                	addi	sp,sp,16
    80006036:	8082                	ret
    panic("virtio_disk_intr 1");
    80006038:	00003517          	auipc	a0,0x3
    8000603c:	80850513          	addi	a0,a0,-2040 # 80008840 <syscalls+0x328>
    80006040:	ffffa097          	auipc	ra,0xffffa
    80006044:	508080e7          	jalr	1288(ra) # 80000548 <panic>
    panic("virtio_disk_intr 2");
    80006048:	00003517          	auipc	a0,0x3
    8000604c:	81050513          	addi	a0,a0,-2032 # 80008858 <syscalls+0x340>
    80006050:	ffffa097          	auipc	ra,0xffffa
    80006054:	4f8080e7          	jalr	1272(ra) # 80000548 <panic>

0000000080006058 <virtio_disk_init>:
{
    80006058:	1101                	addi	sp,sp,-32
    8000605a:	ec06                	sd	ra,24(sp)
    8000605c:	e822                	sd	s0,16(sp)
    8000605e:	e426                	sd	s1,8(sp)
    80006060:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006062:	00003597          	auipc	a1,0x3
    80006066:	80e58593          	addi	a1,a1,-2034 # 80008870 <syscalls+0x358>
    8000606a:	0001f517          	auipc	a0,0x1f
    8000606e:	03e50513          	addi	a0,a0,62 # 800250a8 <disk+0x20a8>
    80006072:	ffffb097          	auipc	ra,0xffffb
    80006076:	b0e080e7          	jalr	-1266(ra) # 80000b80 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000607a:	100017b7          	lui	a5,0x10001
    8000607e:	4398                	lw	a4,0(a5)
    80006080:	2701                	sext.w	a4,a4
    80006082:	747277b7          	lui	a5,0x74727
    80006086:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000608a:	0ef71163          	bne	a4,a5,8000616c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000608e:	100017b7          	lui	a5,0x10001
    80006092:	43dc                	lw	a5,4(a5)
    80006094:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006096:	4705                	li	a4,1
    80006098:	0ce79a63          	bne	a5,a4,8000616c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000609c:	100017b7          	lui	a5,0x10001
    800060a0:	479c                	lw	a5,8(a5)
    800060a2:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800060a4:	4709                	li	a4,2
    800060a6:	0ce79363          	bne	a5,a4,8000616c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800060aa:	100017b7          	lui	a5,0x10001
    800060ae:	47d8                	lw	a4,12(a5)
    800060b0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800060b2:	554d47b7          	lui	a5,0x554d4
    800060b6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800060ba:	0af71963          	bne	a4,a5,8000616c <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    800060be:	100017b7          	lui	a5,0x10001
    800060c2:	4705                	li	a4,1
    800060c4:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060c6:	470d                	li	a4,3
    800060c8:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800060ca:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800060cc:	c7ffe737          	lui	a4,0xc7ffe
    800060d0:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd773f>
    800060d4:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800060d6:	2701                	sext.w	a4,a4
    800060d8:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060da:	472d                	li	a4,11
    800060dc:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060de:	473d                	li	a4,15
    800060e0:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    800060e2:	6705                	lui	a4,0x1
    800060e4:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800060e6:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800060ea:	5bdc                	lw	a5,52(a5)
    800060ec:	2781                	sext.w	a5,a5
  if(max == 0)
    800060ee:	c7d9                	beqz	a5,8000617c <virtio_disk_init+0x124>
  if(max < NUM)
    800060f0:	471d                	li	a4,7
    800060f2:	08f77d63          	bgeu	a4,a5,8000618c <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800060f6:	100014b7          	lui	s1,0x10001
    800060fa:	47a1                	li	a5,8
    800060fc:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    800060fe:	6609                	lui	a2,0x2
    80006100:	4581                	li	a1,0
    80006102:	0001d517          	auipc	a0,0x1d
    80006106:	efe50513          	addi	a0,a0,-258 # 80023000 <disk>
    8000610a:	ffffb097          	auipc	ra,0xffffb
    8000610e:	c02080e7          	jalr	-1022(ra) # 80000d0c <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80006112:	0001d717          	auipc	a4,0x1d
    80006116:	eee70713          	addi	a4,a4,-274 # 80023000 <disk>
    8000611a:	00c75793          	srli	a5,a4,0xc
    8000611e:	2781                	sext.w	a5,a5
    80006120:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80006122:	0001f797          	auipc	a5,0x1f
    80006126:	ede78793          	addi	a5,a5,-290 # 80025000 <disk+0x2000>
    8000612a:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    8000612c:	0001d717          	auipc	a4,0x1d
    80006130:	f5470713          	addi	a4,a4,-172 # 80023080 <disk+0x80>
    80006134:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80006136:	0001e717          	auipc	a4,0x1e
    8000613a:	eca70713          	addi	a4,a4,-310 # 80024000 <disk+0x1000>
    8000613e:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80006140:	4705                	li	a4,1
    80006142:	00e78c23          	sb	a4,24(a5)
    80006146:	00e78ca3          	sb	a4,25(a5)
    8000614a:	00e78d23          	sb	a4,26(a5)
    8000614e:	00e78da3          	sb	a4,27(a5)
    80006152:	00e78e23          	sb	a4,28(a5)
    80006156:	00e78ea3          	sb	a4,29(a5)
    8000615a:	00e78f23          	sb	a4,30(a5)
    8000615e:	00e78fa3          	sb	a4,31(a5)
}
    80006162:	60e2                	ld	ra,24(sp)
    80006164:	6442                	ld	s0,16(sp)
    80006166:	64a2                	ld	s1,8(sp)
    80006168:	6105                	addi	sp,sp,32
    8000616a:	8082                	ret
    panic("could not find virtio disk");
    8000616c:	00002517          	auipc	a0,0x2
    80006170:	71450513          	addi	a0,a0,1812 # 80008880 <syscalls+0x368>
    80006174:	ffffa097          	auipc	ra,0xffffa
    80006178:	3d4080e7          	jalr	980(ra) # 80000548 <panic>
    panic("virtio disk has no queue 0");
    8000617c:	00002517          	auipc	a0,0x2
    80006180:	72450513          	addi	a0,a0,1828 # 800088a0 <syscalls+0x388>
    80006184:	ffffa097          	auipc	ra,0xffffa
    80006188:	3c4080e7          	jalr	964(ra) # 80000548 <panic>
    panic("virtio disk max queue too short");
    8000618c:	00002517          	auipc	a0,0x2
    80006190:	73450513          	addi	a0,a0,1844 # 800088c0 <syscalls+0x3a8>
    80006194:	ffffa097          	auipc	ra,0xffffa
    80006198:	3b4080e7          	jalr	948(ra) # 80000548 <panic>

000000008000619c <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    8000619c:	7119                	addi	sp,sp,-128
    8000619e:	fc86                	sd	ra,120(sp)
    800061a0:	f8a2                	sd	s0,112(sp)
    800061a2:	f4a6                	sd	s1,104(sp)
    800061a4:	f0ca                	sd	s2,96(sp)
    800061a6:	ecce                	sd	s3,88(sp)
    800061a8:	e8d2                	sd	s4,80(sp)
    800061aa:	e4d6                	sd	s5,72(sp)
    800061ac:	e0da                	sd	s6,64(sp)
    800061ae:	fc5e                	sd	s7,56(sp)
    800061b0:	f862                	sd	s8,48(sp)
    800061b2:	f466                	sd	s9,40(sp)
    800061b4:	f06a                	sd	s10,32(sp)
    800061b6:	0100                	addi	s0,sp,128
    800061b8:	892a                	mv	s2,a0
    800061ba:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800061bc:	00c52c83          	lw	s9,12(a0)
    800061c0:	001c9c9b          	slliw	s9,s9,0x1
    800061c4:	1c82                	slli	s9,s9,0x20
    800061c6:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800061ca:	0001f517          	auipc	a0,0x1f
    800061ce:	ede50513          	addi	a0,a0,-290 # 800250a8 <disk+0x20a8>
    800061d2:	ffffb097          	auipc	ra,0xffffb
    800061d6:	a3e080e7          	jalr	-1474(ra) # 80000c10 <acquire>
  for(int i = 0; i < 3; i++){
    800061da:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800061dc:	4c21                	li	s8,8
      disk.free[i] = 0;
    800061de:	0001db97          	auipc	s7,0x1d
    800061e2:	e22b8b93          	addi	s7,s7,-478 # 80023000 <disk>
    800061e6:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    800061e8:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    800061ea:	8a4e                	mv	s4,s3
    800061ec:	a051                	j	80006270 <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    800061ee:	00fb86b3          	add	a3,s7,a5
    800061f2:	96da                	add	a3,a3,s6
    800061f4:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    800061f8:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800061fa:	0207c563          	bltz	a5,80006224 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800061fe:	2485                	addiw	s1,s1,1
    80006200:	0711                	addi	a4,a4,4
    80006202:	23548d63          	beq	s1,s5,8000643c <virtio_disk_rw+0x2a0>
    idx[i] = alloc_desc();
    80006206:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006208:	0001f697          	auipc	a3,0x1f
    8000620c:	e1068693          	addi	a3,a3,-496 # 80025018 <disk+0x2018>
    80006210:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80006212:	0006c583          	lbu	a1,0(a3)
    80006216:	fde1                	bnez	a1,800061ee <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006218:	2785                	addiw	a5,a5,1
    8000621a:	0685                	addi	a3,a3,1
    8000621c:	ff879be3          	bne	a5,s8,80006212 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006220:	57fd                	li	a5,-1
    80006222:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80006224:	02905a63          	blez	s1,80006258 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006228:	f9042503          	lw	a0,-112(s0)
    8000622c:	00000097          	auipc	ra,0x0
    80006230:	daa080e7          	jalr	-598(ra) # 80005fd6 <free_desc>
      for(int j = 0; j < i; j++)
    80006234:	4785                	li	a5,1
    80006236:	0297d163          	bge	a5,s1,80006258 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    8000623a:	f9442503          	lw	a0,-108(s0)
    8000623e:	00000097          	auipc	ra,0x0
    80006242:	d98080e7          	jalr	-616(ra) # 80005fd6 <free_desc>
      for(int j = 0; j < i; j++)
    80006246:	4789                	li	a5,2
    80006248:	0097d863          	bge	a5,s1,80006258 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    8000624c:	f9842503          	lw	a0,-104(s0)
    80006250:	00000097          	auipc	ra,0x0
    80006254:	d86080e7          	jalr	-634(ra) # 80005fd6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006258:	0001f597          	auipc	a1,0x1f
    8000625c:	e5058593          	addi	a1,a1,-432 # 800250a8 <disk+0x20a8>
    80006260:	0001f517          	auipc	a0,0x1f
    80006264:	db850513          	addi	a0,a0,-584 # 80025018 <disk+0x2018>
    80006268:	ffffc097          	auipc	ra,0xffffc
    8000626c:	2d4080e7          	jalr	724(ra) # 8000253c <sleep>
  for(int i = 0; i < 3; i++){
    80006270:	f9040713          	addi	a4,s0,-112
    80006274:	84ce                	mv	s1,s3
    80006276:	bf41                	j	80006206 <virtio_disk_rw+0x6a>
    uint32 reserved;
    uint64 sector;
  } buf0;

  if(write)
    buf0.type = VIRTIO_BLK_T_OUT; // write the disk
    80006278:	4785                	li	a5,1
    8000627a:	f8f42023          	sw	a5,-128(s0)
  else
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
  buf0.reserved = 0;
    8000627e:	f8042223          	sw	zero,-124(s0)
  buf0.sector = sector;
    80006282:	f9943423          	sd	s9,-120(s0)

  // buf0 is on a kernel stack, which is not direct mapped,
  // thus the call to kvmpa().
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    80006286:	f9042983          	lw	s3,-112(s0)
    8000628a:	00499493          	slli	s1,s3,0x4
    8000628e:	0001fa17          	auipc	s4,0x1f
    80006292:	d72a0a13          	addi	s4,s4,-654 # 80025000 <disk+0x2000>
    80006296:	000a3a83          	ld	s5,0(s4)
    8000629a:	9aa6                	add	s5,s5,s1
    8000629c:	f8040513          	addi	a0,s0,-128
    800062a0:	ffffb097          	auipc	ra,0xffffb
    800062a4:	04c080e7          	jalr	76(ra) # 800012ec <kvmpa>
    800062a8:	00aab023          	sd	a0,0(s5)
  disk.desc[idx[0]].len = sizeof(buf0);
    800062ac:	000a3783          	ld	a5,0(s4)
    800062b0:	97a6                	add	a5,a5,s1
    800062b2:	4741                	li	a4,16
    800062b4:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800062b6:	000a3783          	ld	a5,0(s4)
    800062ba:	97a6                	add	a5,a5,s1
    800062bc:	4705                	li	a4,1
    800062be:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    800062c2:	f9442703          	lw	a4,-108(s0)
    800062c6:	000a3783          	ld	a5,0(s4)
    800062ca:	97a6                	add	a5,a5,s1
    800062cc:	00e79723          	sh	a4,14(a5)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800062d0:	0712                	slli	a4,a4,0x4
    800062d2:	000a3783          	ld	a5,0(s4)
    800062d6:	97ba                	add	a5,a5,a4
    800062d8:	05890693          	addi	a3,s2,88
    800062dc:	e394                	sd	a3,0(a5)
  disk.desc[idx[1]].len = BSIZE;
    800062de:	000a3783          	ld	a5,0(s4)
    800062e2:	97ba                	add	a5,a5,a4
    800062e4:	40000693          	li	a3,1024
    800062e8:	c794                	sw	a3,8(a5)
  if(write)
    800062ea:	100d0a63          	beqz	s10,800063fe <virtio_disk_rw+0x262>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800062ee:	0001f797          	auipc	a5,0x1f
    800062f2:	d127b783          	ld	a5,-750(a5) # 80025000 <disk+0x2000>
    800062f6:	97ba                	add	a5,a5,a4
    800062f8:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800062fc:	0001d517          	auipc	a0,0x1d
    80006300:	d0450513          	addi	a0,a0,-764 # 80023000 <disk>
    80006304:	0001f797          	auipc	a5,0x1f
    80006308:	cfc78793          	addi	a5,a5,-772 # 80025000 <disk+0x2000>
    8000630c:	6394                	ld	a3,0(a5)
    8000630e:	96ba                	add	a3,a3,a4
    80006310:	00c6d603          	lhu	a2,12(a3)
    80006314:	00166613          	ori	a2,a2,1
    80006318:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000631c:	f9842683          	lw	a3,-104(s0)
    80006320:	6390                	ld	a2,0(a5)
    80006322:	9732                	add	a4,a4,a2
    80006324:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0;
    80006328:	20098613          	addi	a2,s3,512
    8000632c:	0612                	slli	a2,a2,0x4
    8000632e:	962a                	add	a2,a2,a0
    80006330:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006334:	00469713          	slli	a4,a3,0x4
    80006338:	6394                	ld	a3,0(a5)
    8000633a:	96ba                	add	a3,a3,a4
    8000633c:	6589                	lui	a1,0x2
    8000633e:	03058593          	addi	a1,a1,48 # 2030 <_entry-0x7fffdfd0>
    80006342:	94ae                	add	s1,s1,a1
    80006344:	94aa                	add	s1,s1,a0
    80006346:	e284                	sd	s1,0(a3)
  disk.desc[idx[2]].len = 1;
    80006348:	6394                	ld	a3,0(a5)
    8000634a:	96ba                	add	a3,a3,a4
    8000634c:	4585                	li	a1,1
    8000634e:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006350:	6394                	ld	a3,0(a5)
    80006352:	96ba                	add	a3,a3,a4
    80006354:	4509                	li	a0,2
    80006356:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    8000635a:	6394                	ld	a3,0(a5)
    8000635c:	9736                	add	a4,a4,a3
    8000635e:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006362:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    80006366:	03263423          	sd	s2,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    8000636a:	6794                	ld	a3,8(a5)
    8000636c:	0026d703          	lhu	a4,2(a3)
    80006370:	8b1d                	andi	a4,a4,7
    80006372:	2709                	addiw	a4,a4,2
    80006374:	0706                	slli	a4,a4,0x1
    80006376:	9736                	add	a4,a4,a3
    80006378:	01371023          	sh	s3,0(a4)
  __sync_synchronize();
    8000637c:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    80006380:	6798                	ld	a4,8(a5)
    80006382:	00275783          	lhu	a5,2(a4)
    80006386:	2785                	addiw	a5,a5,1
    80006388:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000638c:	100017b7          	lui	a5,0x10001
    80006390:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006394:	00492703          	lw	a4,4(s2)
    80006398:	4785                	li	a5,1
    8000639a:	02f71163          	bne	a4,a5,800063bc <virtio_disk_rw+0x220>
    sleep(b, &disk.vdisk_lock);
    8000639e:	0001f997          	auipc	s3,0x1f
    800063a2:	d0a98993          	addi	s3,s3,-758 # 800250a8 <disk+0x20a8>
  while(b->disk == 1) {
    800063a6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800063a8:	85ce                	mv	a1,s3
    800063aa:	854a                	mv	a0,s2
    800063ac:	ffffc097          	auipc	ra,0xffffc
    800063b0:	190080e7          	jalr	400(ra) # 8000253c <sleep>
  while(b->disk == 1) {
    800063b4:	00492783          	lw	a5,4(s2)
    800063b8:	fe9788e3          	beq	a5,s1,800063a8 <virtio_disk_rw+0x20c>
  }

  disk.info[idx[0]].b = 0;
    800063bc:	f9042483          	lw	s1,-112(s0)
    800063c0:	20048793          	addi	a5,s1,512 # 10001200 <_entry-0x6fffee00>
    800063c4:	00479713          	slli	a4,a5,0x4
    800063c8:	0001d797          	auipc	a5,0x1d
    800063cc:	c3878793          	addi	a5,a5,-968 # 80023000 <disk>
    800063d0:	97ba                	add	a5,a5,a4
    800063d2:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800063d6:	0001f917          	auipc	s2,0x1f
    800063da:	c2a90913          	addi	s2,s2,-982 # 80025000 <disk+0x2000>
    free_desc(i);
    800063de:	8526                	mv	a0,s1
    800063e0:	00000097          	auipc	ra,0x0
    800063e4:	bf6080e7          	jalr	-1034(ra) # 80005fd6 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800063e8:	0492                	slli	s1,s1,0x4
    800063ea:	00093783          	ld	a5,0(s2)
    800063ee:	94be                	add	s1,s1,a5
    800063f0:	00c4d783          	lhu	a5,12(s1)
    800063f4:	8b85                	andi	a5,a5,1
    800063f6:	cf89                	beqz	a5,80006410 <virtio_disk_rw+0x274>
      i = disk.desc[i].next;
    800063f8:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    800063fc:	b7cd                	j	800063de <virtio_disk_rw+0x242>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800063fe:	0001f797          	auipc	a5,0x1f
    80006402:	c027b783          	ld	a5,-1022(a5) # 80025000 <disk+0x2000>
    80006406:	97ba                	add	a5,a5,a4
    80006408:	4689                	li	a3,2
    8000640a:	00d79623          	sh	a3,12(a5)
    8000640e:	b5fd                	j	800062fc <virtio_disk_rw+0x160>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006410:	0001f517          	auipc	a0,0x1f
    80006414:	c9850513          	addi	a0,a0,-872 # 800250a8 <disk+0x20a8>
    80006418:	ffffb097          	auipc	ra,0xffffb
    8000641c:	8ac080e7          	jalr	-1876(ra) # 80000cc4 <release>
}
    80006420:	70e6                	ld	ra,120(sp)
    80006422:	7446                	ld	s0,112(sp)
    80006424:	74a6                	ld	s1,104(sp)
    80006426:	7906                	ld	s2,96(sp)
    80006428:	69e6                	ld	s3,88(sp)
    8000642a:	6a46                	ld	s4,80(sp)
    8000642c:	6aa6                	ld	s5,72(sp)
    8000642e:	6b06                	ld	s6,64(sp)
    80006430:	7be2                	ld	s7,56(sp)
    80006432:	7c42                	ld	s8,48(sp)
    80006434:	7ca2                	ld	s9,40(sp)
    80006436:	7d02                	ld	s10,32(sp)
    80006438:	6109                	addi	sp,sp,128
    8000643a:	8082                	ret
  if(write)
    8000643c:	e20d1ee3          	bnez	s10,80006278 <virtio_disk_rw+0xdc>
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
    80006440:	f8042023          	sw	zero,-128(s0)
    80006444:	bd2d                	j	8000627e <virtio_disk_rw+0xe2>

0000000080006446 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006446:	1101                	addi	sp,sp,-32
    80006448:	ec06                	sd	ra,24(sp)
    8000644a:	e822                	sd	s0,16(sp)
    8000644c:	e426                	sd	s1,8(sp)
    8000644e:	e04a                	sd	s2,0(sp)
    80006450:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006452:	0001f517          	auipc	a0,0x1f
    80006456:	c5650513          	addi	a0,a0,-938 # 800250a8 <disk+0x20a8>
    8000645a:	ffffa097          	auipc	ra,0xffffa
    8000645e:	7b6080e7          	jalr	1974(ra) # 80000c10 <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006462:	0001f717          	auipc	a4,0x1f
    80006466:	b9e70713          	addi	a4,a4,-1122 # 80025000 <disk+0x2000>
    8000646a:	02075783          	lhu	a5,32(a4)
    8000646e:	6b18                	ld	a4,16(a4)
    80006470:	00275683          	lhu	a3,2(a4)
    80006474:	8ebd                	xor	a3,a3,a5
    80006476:	8a9d                	andi	a3,a3,7
    80006478:	cab9                	beqz	a3,800064ce <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    8000647a:	0001d917          	auipc	s2,0x1d
    8000647e:	b8690913          	addi	s2,s2,-1146 # 80023000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006482:	0001f497          	auipc	s1,0x1f
    80006486:	b7e48493          	addi	s1,s1,-1154 # 80025000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    8000648a:	078e                	slli	a5,a5,0x3
    8000648c:	97ba                	add	a5,a5,a4
    8000648e:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    80006490:	20078713          	addi	a4,a5,512
    80006494:	0712                	slli	a4,a4,0x4
    80006496:	974a                	add	a4,a4,s2
    80006498:	03074703          	lbu	a4,48(a4)
    8000649c:	ef21                	bnez	a4,800064f4 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    8000649e:	20078793          	addi	a5,a5,512
    800064a2:	0792                	slli	a5,a5,0x4
    800064a4:	97ca                	add	a5,a5,s2
    800064a6:	7798                	ld	a4,40(a5)
    800064a8:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    800064ac:	7788                	ld	a0,40(a5)
    800064ae:	ffffc097          	auipc	ra,0xffffc
    800064b2:	214080e7          	jalr	532(ra) # 800026c2 <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    800064b6:	0204d783          	lhu	a5,32(s1)
    800064ba:	2785                	addiw	a5,a5,1
    800064bc:	8b9d                	andi	a5,a5,7
    800064be:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    800064c2:	6898                	ld	a4,16(s1)
    800064c4:	00275683          	lhu	a3,2(a4)
    800064c8:	8a9d                	andi	a3,a3,7
    800064ca:	fcf690e3          	bne	a3,a5,8000648a <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800064ce:	10001737          	lui	a4,0x10001
    800064d2:	533c                	lw	a5,96(a4)
    800064d4:	8b8d                	andi	a5,a5,3
    800064d6:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    800064d8:	0001f517          	auipc	a0,0x1f
    800064dc:	bd050513          	addi	a0,a0,-1072 # 800250a8 <disk+0x20a8>
    800064e0:	ffffa097          	auipc	ra,0xffffa
    800064e4:	7e4080e7          	jalr	2020(ra) # 80000cc4 <release>
}
    800064e8:	60e2                	ld	ra,24(sp)
    800064ea:	6442                	ld	s0,16(sp)
    800064ec:	64a2                	ld	s1,8(sp)
    800064ee:	6902                	ld	s2,0(sp)
    800064f0:	6105                	addi	sp,sp,32
    800064f2:	8082                	ret
      panic("virtio_disk_intr status");
    800064f4:	00002517          	auipc	a0,0x2
    800064f8:	3ec50513          	addi	a0,a0,1004 # 800088e0 <syscalls+0x3c8>
    800064fc:	ffffa097          	auipc	ra,0xffffa
    80006500:	04c080e7          	jalr	76(ra) # 80000548 <panic>

0000000080006504 <statscopyin>:
  int ncopyin;
  int ncopyinstr;
} stats;

int
statscopyin(char *buf, int sz) {
    80006504:	7179                	addi	sp,sp,-48
    80006506:	f406                	sd	ra,40(sp)
    80006508:	f022                	sd	s0,32(sp)
    8000650a:	ec26                	sd	s1,24(sp)
    8000650c:	e84a                	sd	s2,16(sp)
    8000650e:	e44e                	sd	s3,8(sp)
    80006510:	e052                	sd	s4,0(sp)
    80006512:	1800                	addi	s0,sp,48
    80006514:	892a                	mv	s2,a0
    80006516:	89ae                	mv	s3,a1
  int n;
  n = snprintf(buf, sz, "copyin: %d\n", stats.ncopyin);
    80006518:	00003a17          	auipc	s4,0x3
    8000651c:	b18a0a13          	addi	s4,s4,-1256 # 80009030 <stats>
    80006520:	000a2683          	lw	a3,0(s4)
    80006524:	00002617          	auipc	a2,0x2
    80006528:	3d460613          	addi	a2,a2,980 # 800088f8 <syscalls+0x3e0>
    8000652c:	00000097          	auipc	ra,0x0
    80006530:	2c2080e7          	jalr	706(ra) # 800067ee <snprintf>
    80006534:	84aa                	mv	s1,a0
  n += snprintf(buf+n, sz, "copyinstr: %d\n", stats.ncopyinstr);
    80006536:	004a2683          	lw	a3,4(s4)
    8000653a:	00002617          	auipc	a2,0x2
    8000653e:	3ce60613          	addi	a2,a2,974 # 80008908 <syscalls+0x3f0>
    80006542:	85ce                	mv	a1,s3
    80006544:	954a                	add	a0,a0,s2
    80006546:	00000097          	auipc	ra,0x0
    8000654a:	2a8080e7          	jalr	680(ra) # 800067ee <snprintf>
  return n;
}
    8000654e:	9d25                	addw	a0,a0,s1
    80006550:	70a2                	ld	ra,40(sp)
    80006552:	7402                	ld	s0,32(sp)
    80006554:	64e2                	ld	s1,24(sp)
    80006556:	6942                	ld	s2,16(sp)
    80006558:	69a2                	ld	s3,8(sp)
    8000655a:	6a02                	ld	s4,0(sp)
    8000655c:	6145                	addi	sp,sp,48
    8000655e:	8082                	ret

0000000080006560 <copyin_new>:
// Copy from user to kernel.
// Copy len bytes to dst from virtual address srcva in a given page table.
// Return 0 on success, -1 on error.
int
copyin_new(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
    80006560:	7179                	addi	sp,sp,-48
    80006562:	f406                	sd	ra,40(sp)
    80006564:	f022                	sd	s0,32(sp)
    80006566:	ec26                	sd	s1,24(sp)
    80006568:	e84a                	sd	s2,16(sp)
    8000656a:	e44e                	sd	s3,8(sp)
    8000656c:	1800                	addi	s0,sp,48
    8000656e:	89ae                	mv	s3,a1
    80006570:	84b2                	mv	s1,a2
    80006572:	8936                	mv	s2,a3
  struct proc *p = myproc();
    80006574:	ffffb097          	auipc	ra,0xffffb
    80006578:	69c080e7          	jalr	1692(ra) # 80001c10 <myproc>

  if (srcva >= p->sz || srcva+len >= p->sz || srcva+len < srcva)
    8000657c:	653c                	ld	a5,72(a0)
    8000657e:	02f4ff63          	bgeu	s1,a5,800065bc <copyin_new+0x5c>
    80006582:	01248733          	add	a4,s1,s2
    80006586:	02f77d63          	bgeu	a4,a5,800065c0 <copyin_new+0x60>
    8000658a:	02976d63          	bltu	a4,s1,800065c4 <copyin_new+0x64>
    return -1;
  memmove((void *) dst, (void *)srcva, len);
    8000658e:	0009061b          	sext.w	a2,s2
    80006592:	85a6                	mv	a1,s1
    80006594:	854e                	mv	a0,s3
    80006596:	ffffa097          	auipc	ra,0xffffa
    8000659a:	7d6080e7          	jalr	2006(ra) # 80000d6c <memmove>
  stats.ncopyin++;   // XXX lock
    8000659e:	00003717          	auipc	a4,0x3
    800065a2:	a9270713          	addi	a4,a4,-1390 # 80009030 <stats>
    800065a6:	431c                	lw	a5,0(a4)
    800065a8:	2785                	addiw	a5,a5,1
    800065aa:	c31c                	sw	a5,0(a4)
  return 0;
    800065ac:	4501                	li	a0,0
}
    800065ae:	70a2                	ld	ra,40(sp)
    800065b0:	7402                	ld	s0,32(sp)
    800065b2:	64e2                	ld	s1,24(sp)
    800065b4:	6942                	ld	s2,16(sp)
    800065b6:	69a2                	ld	s3,8(sp)
    800065b8:	6145                	addi	sp,sp,48
    800065ba:	8082                	ret
    return -1;
    800065bc:	557d                	li	a0,-1
    800065be:	bfc5                	j	800065ae <copyin_new+0x4e>
    800065c0:	557d                	li	a0,-1
    800065c2:	b7f5                	j	800065ae <copyin_new+0x4e>
    800065c4:	557d                	li	a0,-1
    800065c6:	b7e5                	j	800065ae <copyin_new+0x4e>

00000000800065c8 <copyinstr_new>:
// Copy bytes to dst from virtual address srcva in a given page table,
// until a '\0', or max.
// Return 0 on success, -1 on error.
int
copyinstr_new(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
    800065c8:	7179                	addi	sp,sp,-48
    800065ca:	f406                	sd	ra,40(sp)
    800065cc:	f022                	sd	s0,32(sp)
    800065ce:	ec26                	sd	s1,24(sp)
    800065d0:	e84a                	sd	s2,16(sp)
    800065d2:	e44e                	sd	s3,8(sp)
    800065d4:	1800                	addi	s0,sp,48
    800065d6:	89ae                	mv	s3,a1
    800065d8:	8932                	mv	s2,a2
    800065da:	84b6                	mv	s1,a3
  struct proc *p = myproc();
    800065dc:	ffffb097          	auipc	ra,0xffffb
    800065e0:	634080e7          	jalr	1588(ra) # 80001c10 <myproc>
  char *s = (char *) srcva;
  
  stats.ncopyinstr++;   // XXX lock
    800065e4:	00003717          	auipc	a4,0x3
    800065e8:	a4c70713          	addi	a4,a4,-1460 # 80009030 <stats>
    800065ec:	435c                	lw	a5,4(a4)
    800065ee:	2785                	addiw	a5,a5,1
    800065f0:	c35c                	sw	a5,4(a4)
  for(int i = 0; i < max && srcva + i < p->sz; i++){
    800065f2:	cc85                	beqz	s1,8000662a <copyinstr_new+0x62>
    800065f4:	00990833          	add	a6,s2,s1
    800065f8:	87ca                	mv	a5,s2
    800065fa:	6538                	ld	a4,72(a0)
    800065fc:	00e7ff63          	bgeu	a5,a4,8000661a <copyinstr_new+0x52>
    dst[i] = s[i];
    80006600:	0007c683          	lbu	a3,0(a5)
    80006604:	41278733          	sub	a4,a5,s2
    80006608:	974e                	add	a4,a4,s3
    8000660a:	00d70023          	sb	a3,0(a4)
    if(s[i] == '\0')
    8000660e:	c285                	beqz	a3,8000662e <copyinstr_new+0x66>
  for(int i = 0; i < max && srcva + i < p->sz; i++){
    80006610:	0785                	addi	a5,a5,1
    80006612:	ff0794e3          	bne	a5,a6,800065fa <copyinstr_new+0x32>
      return 0;
  }
  return -1;
    80006616:	557d                	li	a0,-1
    80006618:	a011                	j	8000661c <copyinstr_new+0x54>
    8000661a:	557d                	li	a0,-1
}
    8000661c:	70a2                	ld	ra,40(sp)
    8000661e:	7402                	ld	s0,32(sp)
    80006620:	64e2                	ld	s1,24(sp)
    80006622:	6942                	ld	s2,16(sp)
    80006624:	69a2                	ld	s3,8(sp)
    80006626:	6145                	addi	sp,sp,48
    80006628:	8082                	ret
  return -1;
    8000662a:	557d                	li	a0,-1
    8000662c:	bfc5                	j	8000661c <copyinstr_new+0x54>
      return 0;
    8000662e:	4501                	li	a0,0
    80006630:	b7f5                	j	8000661c <copyinstr_new+0x54>

0000000080006632 <statswrite>:
int statscopyin(char*, int);
int statslock(char*, int);
  
int
statswrite(int user_src, uint64 src, int n)
{
    80006632:	1141                	addi	sp,sp,-16
    80006634:	e422                	sd	s0,8(sp)
    80006636:	0800                	addi	s0,sp,16
  return -1;
}
    80006638:	557d                	li	a0,-1
    8000663a:	6422                	ld	s0,8(sp)
    8000663c:	0141                	addi	sp,sp,16
    8000663e:	8082                	ret

0000000080006640 <statsread>:

int
statsread(int user_dst, uint64 dst, int n)
{
    80006640:	7179                	addi	sp,sp,-48
    80006642:	f406                	sd	ra,40(sp)
    80006644:	f022                	sd	s0,32(sp)
    80006646:	ec26                	sd	s1,24(sp)
    80006648:	e84a                	sd	s2,16(sp)
    8000664a:	e44e                	sd	s3,8(sp)
    8000664c:	e052                	sd	s4,0(sp)
    8000664e:	1800                	addi	s0,sp,48
    80006650:	892a                	mv	s2,a0
    80006652:	89ae                	mv	s3,a1
    80006654:	84b2                	mv	s1,a2
  int m;

  acquire(&stats.lock);
    80006656:	00020517          	auipc	a0,0x20
    8000665a:	9aa50513          	addi	a0,a0,-1622 # 80026000 <stats>
    8000665e:	ffffa097          	auipc	ra,0xffffa
    80006662:	5b2080e7          	jalr	1458(ra) # 80000c10 <acquire>

  if(stats.sz == 0) {
    80006666:	00021797          	auipc	a5,0x21
    8000666a:	9b27a783          	lw	a5,-1614(a5) # 80027018 <stats+0x1018>
    8000666e:	cbb5                	beqz	a5,800066e2 <statsread+0xa2>
#endif
#ifdef LAB_LOCK
    stats.sz = statslock(stats.buf, BUFSZ);
#endif
  }
  m = stats.sz - stats.off;
    80006670:	00021797          	auipc	a5,0x21
    80006674:	99078793          	addi	a5,a5,-1648 # 80027000 <stats+0x1000>
    80006678:	4fd8                	lw	a4,28(a5)
    8000667a:	4f9c                	lw	a5,24(a5)
    8000667c:	9f99                	subw	a5,a5,a4
    8000667e:	0007869b          	sext.w	a3,a5

  if (m > 0) {
    80006682:	06d05e63          	blez	a3,800066fe <statsread+0xbe>
    if(m > n)
    80006686:	8a3e                	mv	s4,a5
    80006688:	00d4d363          	bge	s1,a3,8000668e <statsread+0x4e>
    8000668c:	8a26                	mv	s4,s1
    8000668e:	000a049b          	sext.w	s1,s4
      m  = n;
    if(either_copyout(user_dst, dst, stats.buf+stats.off, m) != -1) {
    80006692:	86a6                	mv	a3,s1
    80006694:	00020617          	auipc	a2,0x20
    80006698:	98460613          	addi	a2,a2,-1660 # 80026018 <stats+0x18>
    8000669c:	963a                	add	a2,a2,a4
    8000669e:	85ce                	mv	a1,s3
    800066a0:	854a                	mv	a0,s2
    800066a2:	ffffc097          	auipc	ra,0xffffc
    800066a6:	0fc080e7          	jalr	252(ra) # 8000279e <either_copyout>
    800066aa:	57fd                	li	a5,-1
    800066ac:	00f50a63          	beq	a0,a5,800066c0 <statsread+0x80>
      stats.off += m;
    800066b0:	00021717          	auipc	a4,0x21
    800066b4:	95070713          	addi	a4,a4,-1712 # 80027000 <stats+0x1000>
    800066b8:	4f5c                	lw	a5,28(a4)
    800066ba:	014787bb          	addw	a5,a5,s4
    800066be:	cf5c                	sw	a5,28(a4)
  } else {
    m = -1;
    stats.sz = 0;
    stats.off = 0;
  }
  release(&stats.lock);
    800066c0:	00020517          	auipc	a0,0x20
    800066c4:	94050513          	addi	a0,a0,-1728 # 80026000 <stats>
    800066c8:	ffffa097          	auipc	ra,0xffffa
    800066cc:	5fc080e7          	jalr	1532(ra) # 80000cc4 <release>
  return m;
}
    800066d0:	8526                	mv	a0,s1
    800066d2:	70a2                	ld	ra,40(sp)
    800066d4:	7402                	ld	s0,32(sp)
    800066d6:	64e2                	ld	s1,24(sp)
    800066d8:	6942                	ld	s2,16(sp)
    800066da:	69a2                	ld	s3,8(sp)
    800066dc:	6a02                	ld	s4,0(sp)
    800066de:	6145                	addi	sp,sp,48
    800066e0:	8082                	ret
    stats.sz = statscopyin(stats.buf, BUFSZ);
    800066e2:	6585                	lui	a1,0x1
    800066e4:	00020517          	auipc	a0,0x20
    800066e8:	93450513          	addi	a0,a0,-1740 # 80026018 <stats+0x18>
    800066ec:	00000097          	auipc	ra,0x0
    800066f0:	e18080e7          	jalr	-488(ra) # 80006504 <statscopyin>
    800066f4:	00021797          	auipc	a5,0x21
    800066f8:	92a7a223          	sw	a0,-1756(a5) # 80027018 <stats+0x1018>
    800066fc:	bf95                	j	80006670 <statsread+0x30>
    stats.sz = 0;
    800066fe:	00021797          	auipc	a5,0x21
    80006702:	90278793          	addi	a5,a5,-1790 # 80027000 <stats+0x1000>
    80006706:	0007ac23          	sw	zero,24(a5)
    stats.off = 0;
    8000670a:	0007ae23          	sw	zero,28(a5)
    m = -1;
    8000670e:	54fd                	li	s1,-1
    80006710:	bf45                	j	800066c0 <statsread+0x80>

0000000080006712 <statsinit>:

void
statsinit(void)
{
    80006712:	1141                	addi	sp,sp,-16
    80006714:	e406                	sd	ra,8(sp)
    80006716:	e022                	sd	s0,0(sp)
    80006718:	0800                	addi	s0,sp,16
  initlock(&stats.lock, "stats");
    8000671a:	00002597          	auipc	a1,0x2
    8000671e:	1fe58593          	addi	a1,a1,510 # 80008918 <syscalls+0x400>
    80006722:	00020517          	auipc	a0,0x20
    80006726:	8de50513          	addi	a0,a0,-1826 # 80026000 <stats>
    8000672a:	ffffa097          	auipc	ra,0xffffa
    8000672e:	456080e7          	jalr	1110(ra) # 80000b80 <initlock>

  devsw[STATS].read = statsread;
    80006732:	0001b797          	auipc	a5,0x1b
    80006736:	48e78793          	addi	a5,a5,1166 # 80021bc0 <devsw>
    8000673a:	00000717          	auipc	a4,0x0
    8000673e:	f0670713          	addi	a4,a4,-250 # 80006640 <statsread>
    80006742:	f398                	sd	a4,32(a5)
  devsw[STATS].write = statswrite;
    80006744:	00000717          	auipc	a4,0x0
    80006748:	eee70713          	addi	a4,a4,-274 # 80006632 <statswrite>
    8000674c:	f798                	sd	a4,40(a5)
}
    8000674e:	60a2                	ld	ra,8(sp)
    80006750:	6402                	ld	s0,0(sp)
    80006752:	0141                	addi	sp,sp,16
    80006754:	8082                	ret

0000000080006756 <sprintint>:
  return 1;
}

static int
sprintint(char *s, int xx, int base, int sign)
{
    80006756:	1101                	addi	sp,sp,-32
    80006758:	ec22                	sd	s0,24(sp)
    8000675a:	1000                	addi	s0,sp,32
    8000675c:	882a                	mv	a6,a0
  char buf[16];
  int i, n;
  uint x;

  if(sign && (sign = xx < 0))
    8000675e:	c299                	beqz	a3,80006764 <sprintint+0xe>
    80006760:	0805c163          	bltz	a1,800067e2 <sprintint+0x8c>
    x = -xx;
  else
    x = xx;
    80006764:	2581                	sext.w	a1,a1
    80006766:	4301                	li	t1,0

  i = 0;
    80006768:	fe040713          	addi	a4,s0,-32
    8000676c:	4501                	li	a0,0
  do {
    buf[i++] = digits[x % base];
    8000676e:	2601                	sext.w	a2,a2
    80006770:	00002697          	auipc	a3,0x2
    80006774:	1b068693          	addi	a3,a3,432 # 80008920 <digits>
    80006778:	88aa                	mv	a7,a0
    8000677a:	2505                	addiw	a0,a0,1
    8000677c:	02c5f7bb          	remuw	a5,a1,a2
    80006780:	1782                	slli	a5,a5,0x20
    80006782:	9381                	srli	a5,a5,0x20
    80006784:	97b6                	add	a5,a5,a3
    80006786:	0007c783          	lbu	a5,0(a5)
    8000678a:	00f70023          	sb	a5,0(a4)
  } while((x /= base) != 0);
    8000678e:	0005879b          	sext.w	a5,a1
    80006792:	02c5d5bb          	divuw	a1,a1,a2
    80006796:	0705                	addi	a4,a4,1
    80006798:	fec7f0e3          	bgeu	a5,a2,80006778 <sprintint+0x22>

  if(sign)
    8000679c:	00030b63          	beqz	t1,800067b2 <sprintint+0x5c>
    buf[i++] = '-';
    800067a0:	ff040793          	addi	a5,s0,-16
    800067a4:	97aa                	add	a5,a5,a0
    800067a6:	02d00713          	li	a4,45
    800067aa:	fee78823          	sb	a4,-16(a5)
    800067ae:	0028851b          	addiw	a0,a7,2

  n = 0;
  while(--i >= 0)
    800067b2:	02a05c63          	blez	a0,800067ea <sprintint+0x94>
    800067b6:	fe040793          	addi	a5,s0,-32
    800067ba:	00a78733          	add	a4,a5,a0
    800067be:	87c2                	mv	a5,a6
    800067c0:	0805                	addi	a6,a6,1
    800067c2:	fff5061b          	addiw	a2,a0,-1
    800067c6:	1602                	slli	a2,a2,0x20
    800067c8:	9201                	srli	a2,a2,0x20
    800067ca:	9642                	add	a2,a2,a6
  *s = c;
    800067cc:	fff74683          	lbu	a3,-1(a4)
    800067d0:	00d78023          	sb	a3,0(a5)
  while(--i >= 0)
    800067d4:	177d                	addi	a4,a4,-1
    800067d6:	0785                	addi	a5,a5,1
    800067d8:	fec79ae3          	bne	a5,a2,800067cc <sprintint+0x76>
    n += sputc(s+n, buf[i]);
  return n;
}
    800067dc:	6462                	ld	s0,24(sp)
    800067de:	6105                	addi	sp,sp,32
    800067e0:	8082                	ret
    x = -xx;
    800067e2:	40b005bb          	negw	a1,a1
  if(sign && (sign = xx < 0))
    800067e6:	4305                	li	t1,1
    x = -xx;
    800067e8:	b741                	j	80006768 <sprintint+0x12>
  while(--i >= 0)
    800067ea:	4501                	li	a0,0
    800067ec:	bfc5                	j	800067dc <sprintint+0x86>

00000000800067ee <snprintf>:

int
snprintf(char *buf, int sz, char *fmt, ...)
{
    800067ee:	7171                	addi	sp,sp,-176
    800067f0:	fc86                	sd	ra,120(sp)
    800067f2:	f8a2                	sd	s0,112(sp)
    800067f4:	f4a6                	sd	s1,104(sp)
    800067f6:	f0ca                	sd	s2,96(sp)
    800067f8:	ecce                	sd	s3,88(sp)
    800067fa:	e8d2                	sd	s4,80(sp)
    800067fc:	e4d6                	sd	s5,72(sp)
    800067fe:	e0da                	sd	s6,64(sp)
    80006800:	fc5e                	sd	s7,56(sp)
    80006802:	f862                	sd	s8,48(sp)
    80006804:	f466                	sd	s9,40(sp)
    80006806:	f06a                	sd	s10,32(sp)
    80006808:	ec6e                	sd	s11,24(sp)
    8000680a:	0100                	addi	s0,sp,128
    8000680c:	e414                	sd	a3,8(s0)
    8000680e:	e818                	sd	a4,16(s0)
    80006810:	ec1c                	sd	a5,24(s0)
    80006812:	03043023          	sd	a6,32(s0)
    80006816:	03143423          	sd	a7,40(s0)
  va_list ap;
  int i, c;
  int off = 0;
  char *s;

  if (fmt == 0)
    8000681a:	ca0d                	beqz	a2,8000684c <snprintf+0x5e>
    8000681c:	8baa                	mv	s7,a0
    8000681e:	89ae                	mv	s3,a1
    80006820:	8a32                	mv	s4,a2
    panic("null fmt");

  va_start(ap, fmt);
    80006822:	00840793          	addi	a5,s0,8
    80006826:	f8f43423          	sd	a5,-120(s0)
  int off = 0;
    8000682a:	4481                	li	s1,0
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    8000682c:	4901                	li	s2,0
    8000682e:	02b05763          	blez	a1,8000685c <snprintf+0x6e>
    if(c != '%'){
    80006832:	02500a93          	li	s5,37
      continue;
    }
    c = fmt[++i] & 0xff;
    if(c == 0)
      break;
    switch(c){
    80006836:	07300b13          	li	s6,115
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
      break;
    case 's':
      if((s = va_arg(ap, char*)) == 0)
        s = "(null)";
      for(; *s && off < sz; s++)
    8000683a:	02800d93          	li	s11,40
  *s = c;
    8000683e:	02500d13          	li	s10,37
    switch(c){
    80006842:	07800c93          	li	s9,120
    80006846:	06400c13          	li	s8,100
    8000684a:	a01d                	j	80006870 <snprintf+0x82>
    panic("null fmt");
    8000684c:	00001517          	auipc	a0,0x1
    80006850:	7dc50513          	addi	a0,a0,2012 # 80008028 <etext+0x28>
    80006854:	ffffa097          	auipc	ra,0xffffa
    80006858:	cf4080e7          	jalr	-780(ra) # 80000548 <panic>
  int off = 0;
    8000685c:	4481                	li	s1,0
    8000685e:	a86d                	j	80006918 <snprintf+0x12a>
  *s = c;
    80006860:	009b8733          	add	a4,s7,s1
    80006864:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    80006868:	2485                	addiw	s1,s1,1
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    8000686a:	2905                	addiw	s2,s2,1
    8000686c:	0b34d663          	bge	s1,s3,80006918 <snprintf+0x12a>
    80006870:	012a07b3          	add	a5,s4,s2
    80006874:	0007c783          	lbu	a5,0(a5)
    80006878:	0007871b          	sext.w	a4,a5
    8000687c:	cfd1                	beqz	a5,80006918 <snprintf+0x12a>
    if(c != '%'){
    8000687e:	ff5711e3          	bne	a4,s5,80006860 <snprintf+0x72>
    c = fmt[++i] & 0xff;
    80006882:	2905                	addiw	s2,s2,1
    80006884:	012a07b3          	add	a5,s4,s2
    80006888:	0007c783          	lbu	a5,0(a5)
    if(c == 0)
    8000688c:	c7d1                	beqz	a5,80006918 <snprintf+0x12a>
    switch(c){
    8000688e:	05678c63          	beq	a5,s6,800068e6 <snprintf+0xf8>
    80006892:	02fb6763          	bltu	s6,a5,800068c0 <snprintf+0xd2>
    80006896:	0b578763          	beq	a5,s5,80006944 <snprintf+0x156>
    8000689a:	0b879b63          	bne	a5,s8,80006950 <snprintf+0x162>
      off += sprintint(buf+off, va_arg(ap, int), 10, 1);
    8000689e:	f8843783          	ld	a5,-120(s0)
    800068a2:	00878713          	addi	a4,a5,8
    800068a6:	f8e43423          	sd	a4,-120(s0)
    800068aa:	4685                	li	a3,1
    800068ac:	4629                	li	a2,10
    800068ae:	438c                	lw	a1,0(a5)
    800068b0:	009b8533          	add	a0,s7,s1
    800068b4:	00000097          	auipc	ra,0x0
    800068b8:	ea2080e7          	jalr	-350(ra) # 80006756 <sprintint>
    800068bc:	9ca9                	addw	s1,s1,a0
      break;
    800068be:	b775                	j	8000686a <snprintf+0x7c>
    switch(c){
    800068c0:	09979863          	bne	a5,s9,80006950 <snprintf+0x162>
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
    800068c4:	f8843783          	ld	a5,-120(s0)
    800068c8:	00878713          	addi	a4,a5,8
    800068cc:	f8e43423          	sd	a4,-120(s0)
    800068d0:	4685                	li	a3,1
    800068d2:	4641                	li	a2,16
    800068d4:	438c                	lw	a1,0(a5)
    800068d6:	009b8533          	add	a0,s7,s1
    800068da:	00000097          	auipc	ra,0x0
    800068de:	e7c080e7          	jalr	-388(ra) # 80006756 <sprintint>
    800068e2:	9ca9                	addw	s1,s1,a0
      break;
    800068e4:	b759                	j	8000686a <snprintf+0x7c>
      if((s = va_arg(ap, char*)) == 0)
    800068e6:	f8843783          	ld	a5,-120(s0)
    800068ea:	00878713          	addi	a4,a5,8
    800068ee:	f8e43423          	sd	a4,-120(s0)
    800068f2:	639c                	ld	a5,0(a5)
    800068f4:	c3b1                	beqz	a5,80006938 <snprintf+0x14a>
      for(; *s && off < sz; s++)
    800068f6:	0007c703          	lbu	a4,0(a5)
    800068fa:	db25                	beqz	a4,8000686a <snprintf+0x7c>
    800068fc:	0134de63          	bge	s1,s3,80006918 <snprintf+0x12a>
    80006900:	009b86b3          	add	a3,s7,s1
  *s = c;
    80006904:	00e68023          	sb	a4,0(a3)
        off += sputc(buf+off, *s);
    80006908:	2485                	addiw	s1,s1,1
      for(; *s && off < sz; s++)
    8000690a:	0785                	addi	a5,a5,1
    8000690c:	0007c703          	lbu	a4,0(a5)
    80006910:	df29                	beqz	a4,8000686a <snprintf+0x7c>
    80006912:	0685                	addi	a3,a3,1
    80006914:	fe9998e3          	bne	s3,s1,80006904 <snprintf+0x116>
      off += sputc(buf+off, c);
      break;
    }
  }
  return off;
}
    80006918:	8526                	mv	a0,s1
    8000691a:	70e6                	ld	ra,120(sp)
    8000691c:	7446                	ld	s0,112(sp)
    8000691e:	74a6                	ld	s1,104(sp)
    80006920:	7906                	ld	s2,96(sp)
    80006922:	69e6                	ld	s3,88(sp)
    80006924:	6a46                	ld	s4,80(sp)
    80006926:	6aa6                	ld	s5,72(sp)
    80006928:	6b06                	ld	s6,64(sp)
    8000692a:	7be2                	ld	s7,56(sp)
    8000692c:	7c42                	ld	s8,48(sp)
    8000692e:	7ca2                	ld	s9,40(sp)
    80006930:	7d02                	ld	s10,32(sp)
    80006932:	6de2                	ld	s11,24(sp)
    80006934:	614d                	addi	sp,sp,176
    80006936:	8082                	ret
        s = "(null)";
    80006938:	00001797          	auipc	a5,0x1
    8000693c:	6e878793          	addi	a5,a5,1768 # 80008020 <etext+0x20>
      for(; *s && off < sz; s++)
    80006940:	876e                	mv	a4,s11
    80006942:	bf6d                	j	800068fc <snprintf+0x10e>
  *s = c;
    80006944:	009b87b3          	add	a5,s7,s1
    80006948:	01a78023          	sb	s10,0(a5)
      off += sputc(buf+off, '%');
    8000694c:	2485                	addiw	s1,s1,1
      break;
    8000694e:	bf31                	j	8000686a <snprintf+0x7c>
  *s = c;
    80006950:	009b8733          	add	a4,s7,s1
    80006954:	01a70023          	sb	s10,0(a4)
      off += sputc(buf+off, c);
    80006958:	0014871b          	addiw	a4,s1,1
  *s = c;
    8000695c:	975e                	add	a4,a4,s7
    8000695e:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    80006962:	2489                	addiw	s1,s1,2
      break;
    80006964:	b719                	j	8000686a <snprintf+0x7c>
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
