
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00007297          	auipc	t0,0x7
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0207000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00007297          	auipc	t0,0x7
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0207008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02062b7          	lui	t0,0xc0206
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc020001c:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200020:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc0200022:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200026:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc020002a:	fff0031b          	addiw	t1,zero,-1
ffffffffc020002e:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200030:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200034:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200038:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc020003c:	c0206137          	lui	sp,0xc0206

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 1. 使用临时寄存器 t1 计算栈顶的精确地址
    lui t1, %hi(bootstacktop)
ffffffffc0200040:	c0206337          	lui	t1,0xc0206
    addi t1, t1, %lo(bootstacktop)
ffffffffc0200044:	00030313          	mv	t1,t1
    # 2. 将精确地址一次性地、安全地传给 sp
    mv sp, t1
ffffffffc0200048:	811a                	mv	sp,t1
    # 现在栈指针已经完美设置，可以安全地调用任何C函数了
    # 然后跳转到 kern_init (不再返回)
    lui t0, %hi(kern_init)
ffffffffc020004a:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc020004e:	0a228293          	addi	t0,t0,162 # ffffffffc02000a2 <kern_init>
    jr t0
ffffffffc0200052:	8282                	jr	t0

ffffffffc0200054 <test_illegal>:
#include <dtb.h>

int kern_init(void) __attribute__((noreturn));
void grade_backtrace(void);

void test_illegal(void) {
ffffffffc0200054:	1141                	addi	sp,sp,-16
    cprintf("\n Testing  illegal instruction_32 \n");
ffffffffc0200056:	00002517          	auipc	a0,0x2
ffffffffc020005a:	fca50513          	addi	a0,a0,-54 # ffffffffc0202020 <etext>
void test_illegal(void) {
ffffffffc020005e:	e406                	sd	ra,8(sp)
    cprintf("\n Testing  illegal instruction_32 \n");
ffffffffc0200060:	0ce000ef          	jal	ra,ffffffffc020012e <cprintf>
ffffffffc0200064:	ffff                	0xffff
ffffffffc0200066:	ffff                	0xffff
    asm volatile (".word 0xffffffff");     // 非法 32 位编码，低两位 == 0x3

    cprintf("\n Testing  illegal instruction_16 \n");
ffffffffc0200068:	00002517          	auipc	a0,0x2
ffffffffc020006c:	fe050513          	addi	a0,a0,-32 # ffffffffc0202048 <etext+0x28>
ffffffffc0200070:	0be000ef          	jal	ra,ffffffffc020012e <cprintf>
ffffffffc0200074:	0000                	unimp
    asm volatile (".short 0x0000");        // 非法 16 位半字，低两位 != 0x3
}
ffffffffc0200076:	60a2                	ld	ra,8(sp)
ffffffffc0200078:	0141                	addi	sp,sp,16
ffffffffc020007a:	8082                	ret

ffffffffc020007c <test_breakpoint>:

void test_breakpoint(void) {
ffffffffc020007c:	1141                	addi	sp,sp,-16
    cprintf("\n Testing  breakpoint_32 \n");
ffffffffc020007e:	00002517          	auipc	a0,0x2
ffffffffc0200082:	ff250513          	addi	a0,a0,-14 # ffffffffc0202070 <etext+0x50>
void test_breakpoint(void) {
ffffffffc0200086:	e406                	sd	ra,8(sp)
    cprintf("\n Testing  breakpoint_32 \n");
ffffffffc0200088:	0a6000ef          	jal	ra,ffffffffc020012e <cprintf>
    asm volatile ("ebreak");               // 标准断点      
ffffffffc020008c:	9002                	ebreak

    cprintf("\n Testing  breakpoint_16 \n");
ffffffffc020008e:	00002517          	auipc	a0,0x2
ffffffffc0200092:	00250513          	addi	a0,a0,2 # ffffffffc0202090 <etext+0x70>
ffffffffc0200096:	098000ef          	jal	ra,ffffffffc020012e <cprintf>
ffffffffc020009a:	9002                	ebreak
    asm volatile (".short 0x9002");        // 压缩断点 c.ebreak
}
ffffffffc020009c:	60a2                	ld	ra,8(sp)
ffffffffc020009e:	0141                	addi	sp,sp,16
ffffffffc02000a0:	8082                	ret

ffffffffc02000a2 <kern_init>:

int kern_init(void) {
    extern char edata[], end[];
    // 先清零 BSS，再读取并保存 DTB 的内存信息，避免被清零覆盖（为了解释变化 正式上传时我觉得应该删去这句话）
    memset(edata, 0, end - edata);
ffffffffc02000a2:	00007517          	auipc	a0,0x7
ffffffffc02000a6:	f8650513          	addi	a0,a0,-122 # ffffffffc0207028 <free_area>
ffffffffc02000aa:	00007617          	auipc	a2,0x7
ffffffffc02000ae:	3f660613          	addi	a2,a2,1014 # ffffffffc02074a0 <end>
int kern_init(void) {
ffffffffc02000b2:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc02000b4:	8e09                	sub	a2,a2,a0
ffffffffc02000b6:	4581                	li	a1,0
int kern_init(void) {
ffffffffc02000b8:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc02000ba:	755010ef          	jal	ra,ffffffffc020200e <memset>
    dtb_init();
ffffffffc02000be:	416000ef          	jal	ra,ffffffffc02004d4 <dtb_init>
    cons_init();  // init the console
ffffffffc02000c2:	404000ef          	jal	ra,ffffffffc02004c6 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc02000c6:	00002517          	auipc	a0,0x2
ffffffffc02000ca:	fea50513          	addi	a0,a0,-22 # ffffffffc02020b0 <etext+0x90>
ffffffffc02000ce:	098000ef          	jal	ra,ffffffffc0200166 <cputs>

    print_kerninfo();
ffffffffc02000d2:	0e4000ef          	jal	ra,ffffffffc02001b6 <print_kerninfo>

    // grade_backtrace();
    idt_init();  // init interrupt descriptor table
ffffffffc02000d6:	7ba000ef          	jal	ra,ffffffffc0200890 <idt_init>

    pmm_init();  // init physical memory management
ffffffffc02000da:	7b8010ef          	jal	ra,ffffffffc0201892 <pmm_init>

    idt_init();  // init interrupt descriptor table
ffffffffc02000de:	7b2000ef          	jal	ra,ffffffffc0200890 <idt_init>

    // 异常测试
    test_illegal();
ffffffffc02000e2:	f73ff0ef          	jal	ra,ffffffffc0200054 <test_illegal>
    test_breakpoint();
ffffffffc02000e6:	f97ff0ef          	jal	ra,ffffffffc020007c <test_breakpoint>
    
    // 中断测试
    clock_init();   // init clock interrupt，就在这触发的时钟中断
ffffffffc02000ea:	39a000ef          	jal	ra,ffffffffc0200484 <clock_init>

    intr_enable();  // enable irq interrupt
ffffffffc02000ee:	796000ef          	jal	ra,ffffffffc0200884 <intr_enable>

    /* do nothing */
    while (1)
ffffffffc02000f2:	a001                	j	ffffffffc02000f2 <kern_init+0x50>

ffffffffc02000f4 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc02000f4:	1141                	addi	sp,sp,-16
ffffffffc02000f6:	e022                	sd	s0,0(sp)
ffffffffc02000f8:	e406                	sd	ra,8(sp)
ffffffffc02000fa:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc02000fc:	3cc000ef          	jal	ra,ffffffffc02004c8 <cons_putc>
    (*cnt) ++;
ffffffffc0200100:	401c                	lw	a5,0(s0)
}
ffffffffc0200102:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc0200104:	2785                	addiw	a5,a5,1
ffffffffc0200106:	c01c                	sw	a5,0(s0)
}
ffffffffc0200108:	6402                	ld	s0,0(sp)
ffffffffc020010a:	0141                	addi	sp,sp,16
ffffffffc020010c:	8082                	ret

ffffffffc020010e <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc020010e:	1101                	addi	sp,sp,-32
ffffffffc0200110:	862a                	mv	a2,a0
ffffffffc0200112:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200114:	00000517          	auipc	a0,0x0
ffffffffc0200118:	fe050513          	addi	a0,a0,-32 # ffffffffc02000f4 <cputch>
ffffffffc020011c:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc020011e:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc0200120:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200122:	1bd010ef          	jal	ra,ffffffffc0201ade <vprintfmt>
    return cnt;
}
ffffffffc0200126:	60e2                	ld	ra,24(sp)
ffffffffc0200128:	4532                	lw	a0,12(sp)
ffffffffc020012a:	6105                	addi	sp,sp,32
ffffffffc020012c:	8082                	ret

ffffffffc020012e <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc020012e:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc0200130:	02810313          	addi	t1,sp,40 # ffffffffc0206028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc0200134:	8e2a                	mv	t3,a0
ffffffffc0200136:	f42e                	sd	a1,40(sp)
ffffffffc0200138:	f832                	sd	a2,48(sp)
ffffffffc020013a:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020013c:	00000517          	auipc	a0,0x0
ffffffffc0200140:	fb850513          	addi	a0,a0,-72 # ffffffffc02000f4 <cputch>
ffffffffc0200144:	004c                	addi	a1,sp,4
ffffffffc0200146:	869a                	mv	a3,t1
ffffffffc0200148:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc020014a:	ec06                	sd	ra,24(sp)
ffffffffc020014c:	e0ba                	sd	a4,64(sp)
ffffffffc020014e:	e4be                	sd	a5,72(sp)
ffffffffc0200150:	e8c2                	sd	a6,80(sp)
ffffffffc0200152:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc0200154:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc0200156:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200158:	187010ef          	jal	ra,ffffffffc0201ade <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc020015c:	60e2                	ld	ra,24(sp)
ffffffffc020015e:	4512                	lw	a0,4(sp)
ffffffffc0200160:	6125                	addi	sp,sp,96
ffffffffc0200162:	8082                	ret

ffffffffc0200164 <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc0200164:	a695                	j	ffffffffc02004c8 <cons_putc>

ffffffffc0200166 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc0200166:	1101                	addi	sp,sp,-32
ffffffffc0200168:	e822                	sd	s0,16(sp)
ffffffffc020016a:	ec06                	sd	ra,24(sp)
ffffffffc020016c:	e426                	sd	s1,8(sp)
ffffffffc020016e:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc0200170:	00054503          	lbu	a0,0(a0)
ffffffffc0200174:	c51d                	beqz	a0,ffffffffc02001a2 <cputs+0x3c>
ffffffffc0200176:	0405                	addi	s0,s0,1
ffffffffc0200178:	4485                	li	s1,1
ffffffffc020017a:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc020017c:	34c000ef          	jal	ra,ffffffffc02004c8 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc0200180:	00044503          	lbu	a0,0(s0)
ffffffffc0200184:	008487bb          	addw	a5,s1,s0
ffffffffc0200188:	0405                	addi	s0,s0,1
ffffffffc020018a:	f96d                	bnez	a0,ffffffffc020017c <cputs+0x16>
    (*cnt) ++;
ffffffffc020018c:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc0200190:	4529                	li	a0,10
ffffffffc0200192:	336000ef          	jal	ra,ffffffffc02004c8 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc0200196:	60e2                	ld	ra,24(sp)
ffffffffc0200198:	8522                	mv	a0,s0
ffffffffc020019a:	6442                	ld	s0,16(sp)
ffffffffc020019c:	64a2                	ld	s1,8(sp)
ffffffffc020019e:	6105                	addi	sp,sp,32
ffffffffc02001a0:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc02001a2:	4405                	li	s0,1
ffffffffc02001a4:	b7f5                	j	ffffffffc0200190 <cputs+0x2a>

ffffffffc02001a6 <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc02001a6:	1141                	addi	sp,sp,-16
ffffffffc02001a8:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc02001aa:	326000ef          	jal	ra,ffffffffc02004d0 <cons_getc>
ffffffffc02001ae:	dd75                	beqz	a0,ffffffffc02001aa <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc02001b0:	60a2                	ld	ra,8(sp)
ffffffffc02001b2:	0141                	addi	sp,sp,16
ffffffffc02001b4:	8082                	ret

ffffffffc02001b6 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc02001b6:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc02001b8:	00002517          	auipc	a0,0x2
ffffffffc02001bc:	f1850513          	addi	a0,a0,-232 # ffffffffc02020d0 <etext+0xb0>
void print_kerninfo(void) {
ffffffffc02001c0:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc02001c2:	f6dff0ef          	jal	ra,ffffffffc020012e <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", kern_init);
ffffffffc02001c6:	00000597          	auipc	a1,0x0
ffffffffc02001ca:	edc58593          	addi	a1,a1,-292 # ffffffffc02000a2 <kern_init>
ffffffffc02001ce:	00002517          	auipc	a0,0x2
ffffffffc02001d2:	f2250513          	addi	a0,a0,-222 # ffffffffc02020f0 <etext+0xd0>
ffffffffc02001d6:	f59ff0ef          	jal	ra,ffffffffc020012e <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc02001da:	00002597          	auipc	a1,0x2
ffffffffc02001de:	e4658593          	addi	a1,a1,-442 # ffffffffc0202020 <etext>
ffffffffc02001e2:	00002517          	auipc	a0,0x2
ffffffffc02001e6:	f2e50513          	addi	a0,a0,-210 # ffffffffc0202110 <etext+0xf0>
ffffffffc02001ea:	f45ff0ef          	jal	ra,ffffffffc020012e <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc02001ee:	00007597          	auipc	a1,0x7
ffffffffc02001f2:	e3a58593          	addi	a1,a1,-454 # ffffffffc0207028 <free_area>
ffffffffc02001f6:	00002517          	auipc	a0,0x2
ffffffffc02001fa:	f3a50513          	addi	a0,a0,-198 # ffffffffc0202130 <etext+0x110>
ffffffffc02001fe:	f31ff0ef          	jal	ra,ffffffffc020012e <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200202:	00007597          	auipc	a1,0x7
ffffffffc0200206:	29e58593          	addi	a1,a1,670 # ffffffffc02074a0 <end>
ffffffffc020020a:	00002517          	auipc	a0,0x2
ffffffffc020020e:	f4650513          	addi	a0,a0,-186 # ffffffffc0202150 <etext+0x130>
ffffffffc0200212:	f1dff0ef          	jal	ra,ffffffffc020012e <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc0200216:	00007597          	auipc	a1,0x7
ffffffffc020021a:	68958593          	addi	a1,a1,1673 # ffffffffc020789f <end+0x3ff>
ffffffffc020021e:	00000797          	auipc	a5,0x0
ffffffffc0200222:	e8478793          	addi	a5,a5,-380 # ffffffffc02000a2 <kern_init>
ffffffffc0200226:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc020022a:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc020022e:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200230:	3ff5f593          	andi	a1,a1,1023
ffffffffc0200234:	95be                	add	a1,a1,a5
ffffffffc0200236:	85a9                	srai	a1,a1,0xa
ffffffffc0200238:	00002517          	auipc	a0,0x2
ffffffffc020023c:	f3850513          	addi	a0,a0,-200 # ffffffffc0202170 <etext+0x150>
}
ffffffffc0200240:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200242:	b5f5                	j	ffffffffc020012e <cprintf>

ffffffffc0200244 <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc0200244:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc0200246:	00002617          	auipc	a2,0x2
ffffffffc020024a:	f5a60613          	addi	a2,a2,-166 # ffffffffc02021a0 <etext+0x180>
ffffffffc020024e:	04d00593          	li	a1,77
ffffffffc0200252:	00002517          	auipc	a0,0x2
ffffffffc0200256:	f6650513          	addi	a0,a0,-154 # ffffffffc02021b8 <etext+0x198>
void print_stackframe(void) {
ffffffffc020025a:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc020025c:	1cc000ef          	jal	ra,ffffffffc0200428 <__panic>

ffffffffc0200260 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200260:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200262:	00002617          	auipc	a2,0x2
ffffffffc0200266:	f6e60613          	addi	a2,a2,-146 # ffffffffc02021d0 <etext+0x1b0>
ffffffffc020026a:	00002597          	auipc	a1,0x2
ffffffffc020026e:	f8658593          	addi	a1,a1,-122 # ffffffffc02021f0 <etext+0x1d0>
ffffffffc0200272:	00002517          	auipc	a0,0x2
ffffffffc0200276:	f8650513          	addi	a0,a0,-122 # ffffffffc02021f8 <etext+0x1d8>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc020027a:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc020027c:	eb3ff0ef          	jal	ra,ffffffffc020012e <cprintf>
ffffffffc0200280:	00002617          	auipc	a2,0x2
ffffffffc0200284:	f8860613          	addi	a2,a2,-120 # ffffffffc0202208 <etext+0x1e8>
ffffffffc0200288:	00002597          	auipc	a1,0x2
ffffffffc020028c:	fa858593          	addi	a1,a1,-88 # ffffffffc0202230 <etext+0x210>
ffffffffc0200290:	00002517          	auipc	a0,0x2
ffffffffc0200294:	f6850513          	addi	a0,a0,-152 # ffffffffc02021f8 <etext+0x1d8>
ffffffffc0200298:	e97ff0ef          	jal	ra,ffffffffc020012e <cprintf>
ffffffffc020029c:	00002617          	auipc	a2,0x2
ffffffffc02002a0:	fa460613          	addi	a2,a2,-92 # ffffffffc0202240 <etext+0x220>
ffffffffc02002a4:	00002597          	auipc	a1,0x2
ffffffffc02002a8:	fbc58593          	addi	a1,a1,-68 # ffffffffc0202260 <etext+0x240>
ffffffffc02002ac:	00002517          	auipc	a0,0x2
ffffffffc02002b0:	f4c50513          	addi	a0,a0,-180 # ffffffffc02021f8 <etext+0x1d8>
ffffffffc02002b4:	e7bff0ef          	jal	ra,ffffffffc020012e <cprintf>
    }
    return 0;
}
ffffffffc02002b8:	60a2                	ld	ra,8(sp)
ffffffffc02002ba:	4501                	li	a0,0
ffffffffc02002bc:	0141                	addi	sp,sp,16
ffffffffc02002be:	8082                	ret

ffffffffc02002c0 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002c0:	1141                	addi	sp,sp,-16
ffffffffc02002c2:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc02002c4:	ef3ff0ef          	jal	ra,ffffffffc02001b6 <print_kerninfo>
    return 0;
}
ffffffffc02002c8:	60a2                	ld	ra,8(sp)
ffffffffc02002ca:	4501                	li	a0,0
ffffffffc02002cc:	0141                	addi	sp,sp,16
ffffffffc02002ce:	8082                	ret

ffffffffc02002d0 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002d0:	1141                	addi	sp,sp,-16
ffffffffc02002d2:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc02002d4:	f71ff0ef          	jal	ra,ffffffffc0200244 <print_stackframe>
    return 0;
}
ffffffffc02002d8:	60a2                	ld	ra,8(sp)
ffffffffc02002da:	4501                	li	a0,0
ffffffffc02002dc:	0141                	addi	sp,sp,16
ffffffffc02002de:	8082                	ret

ffffffffc02002e0 <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc02002e0:	7115                	addi	sp,sp,-224
ffffffffc02002e2:	ed5e                	sd	s7,152(sp)
ffffffffc02002e4:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc02002e6:	00002517          	auipc	a0,0x2
ffffffffc02002ea:	f8a50513          	addi	a0,a0,-118 # ffffffffc0202270 <etext+0x250>
kmonitor(struct trapframe *tf) {
ffffffffc02002ee:	ed86                	sd	ra,216(sp)
ffffffffc02002f0:	e9a2                	sd	s0,208(sp)
ffffffffc02002f2:	e5a6                	sd	s1,200(sp)
ffffffffc02002f4:	e1ca                	sd	s2,192(sp)
ffffffffc02002f6:	fd4e                	sd	s3,184(sp)
ffffffffc02002f8:	f952                	sd	s4,176(sp)
ffffffffc02002fa:	f556                	sd	s5,168(sp)
ffffffffc02002fc:	f15a                	sd	s6,160(sp)
ffffffffc02002fe:	e962                	sd	s8,144(sp)
ffffffffc0200300:	e566                	sd	s9,136(sp)
ffffffffc0200302:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200304:	e2bff0ef          	jal	ra,ffffffffc020012e <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc0200308:	00002517          	auipc	a0,0x2
ffffffffc020030c:	f9050513          	addi	a0,a0,-112 # ffffffffc0202298 <etext+0x278>
ffffffffc0200310:	e1fff0ef          	jal	ra,ffffffffc020012e <cprintf>
    if (tf != NULL) {
ffffffffc0200314:	000b8563          	beqz	s7,ffffffffc020031e <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc0200318:	855e                	mv	a0,s7
ffffffffc020031a:	756000ef          	jal	ra,ffffffffc0200a70 <print_trapframe>
ffffffffc020031e:	00002c17          	auipc	s8,0x2
ffffffffc0200322:	feac0c13          	addi	s8,s8,-22 # ffffffffc0202308 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200326:	00002917          	auipc	s2,0x2
ffffffffc020032a:	f9a90913          	addi	s2,s2,-102 # ffffffffc02022c0 <etext+0x2a0>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020032e:	00002497          	auipc	s1,0x2
ffffffffc0200332:	f9a48493          	addi	s1,s1,-102 # ffffffffc02022c8 <etext+0x2a8>
        if (argc == MAXARGS - 1) {
ffffffffc0200336:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200338:	00002b17          	auipc	s6,0x2
ffffffffc020033c:	f98b0b13          	addi	s6,s6,-104 # ffffffffc02022d0 <etext+0x2b0>
        argv[argc ++] = buf;
ffffffffc0200340:	00002a17          	auipc	s4,0x2
ffffffffc0200344:	eb0a0a13          	addi	s4,s4,-336 # ffffffffc02021f0 <etext+0x1d0>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200348:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc020034a:	854a                	mv	a0,s2
ffffffffc020034c:	315010ef          	jal	ra,ffffffffc0201e60 <readline>
ffffffffc0200350:	842a                	mv	s0,a0
ffffffffc0200352:	dd65                	beqz	a0,ffffffffc020034a <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200354:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc0200358:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020035a:	e1bd                	bnez	a1,ffffffffc02003c0 <kmonitor+0xe0>
    if (argc == 0) {
ffffffffc020035c:	fe0c87e3          	beqz	s9,ffffffffc020034a <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200360:	6582                	ld	a1,0(sp)
ffffffffc0200362:	00002d17          	auipc	s10,0x2
ffffffffc0200366:	fa6d0d13          	addi	s10,s10,-90 # ffffffffc0202308 <commands>
        argv[argc ++] = buf;
ffffffffc020036a:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020036c:	4401                	li	s0,0
ffffffffc020036e:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200370:	445010ef          	jal	ra,ffffffffc0201fb4 <strcmp>
ffffffffc0200374:	c919                	beqz	a0,ffffffffc020038a <kmonitor+0xaa>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200376:	2405                	addiw	s0,s0,1
ffffffffc0200378:	0b540063          	beq	s0,s5,ffffffffc0200418 <kmonitor+0x138>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020037c:	000d3503          	ld	a0,0(s10)
ffffffffc0200380:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200382:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200384:	431010ef          	jal	ra,ffffffffc0201fb4 <strcmp>
ffffffffc0200388:	f57d                	bnez	a0,ffffffffc0200376 <kmonitor+0x96>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc020038a:	00141793          	slli	a5,s0,0x1
ffffffffc020038e:	97a2                	add	a5,a5,s0
ffffffffc0200390:	078e                	slli	a5,a5,0x3
ffffffffc0200392:	97e2                	add	a5,a5,s8
ffffffffc0200394:	6b9c                	ld	a5,16(a5)
ffffffffc0200396:	865e                	mv	a2,s7
ffffffffc0200398:	002c                	addi	a1,sp,8
ffffffffc020039a:	fffc851b          	addiw	a0,s9,-1
ffffffffc020039e:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc02003a0:	fa0555e3          	bgez	a0,ffffffffc020034a <kmonitor+0x6a>
}
ffffffffc02003a4:	60ee                	ld	ra,216(sp)
ffffffffc02003a6:	644e                	ld	s0,208(sp)
ffffffffc02003a8:	64ae                	ld	s1,200(sp)
ffffffffc02003aa:	690e                	ld	s2,192(sp)
ffffffffc02003ac:	79ea                	ld	s3,184(sp)
ffffffffc02003ae:	7a4a                	ld	s4,176(sp)
ffffffffc02003b0:	7aaa                	ld	s5,168(sp)
ffffffffc02003b2:	7b0a                	ld	s6,160(sp)
ffffffffc02003b4:	6bea                	ld	s7,152(sp)
ffffffffc02003b6:	6c4a                	ld	s8,144(sp)
ffffffffc02003b8:	6caa                	ld	s9,136(sp)
ffffffffc02003ba:	6d0a                	ld	s10,128(sp)
ffffffffc02003bc:	612d                	addi	sp,sp,224
ffffffffc02003be:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003c0:	8526                	mv	a0,s1
ffffffffc02003c2:	437010ef          	jal	ra,ffffffffc0201ff8 <strchr>
ffffffffc02003c6:	c901                	beqz	a0,ffffffffc02003d6 <kmonitor+0xf6>
ffffffffc02003c8:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc02003cc:	00040023          	sb	zero,0(s0)
ffffffffc02003d0:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003d2:	d5c9                	beqz	a1,ffffffffc020035c <kmonitor+0x7c>
ffffffffc02003d4:	b7f5                	j	ffffffffc02003c0 <kmonitor+0xe0>
        if (*buf == '\0') {
ffffffffc02003d6:	00044783          	lbu	a5,0(s0)
ffffffffc02003da:	d3c9                	beqz	a5,ffffffffc020035c <kmonitor+0x7c>
        if (argc == MAXARGS - 1) {
ffffffffc02003dc:	033c8963          	beq	s9,s3,ffffffffc020040e <kmonitor+0x12e>
        argv[argc ++] = buf;
ffffffffc02003e0:	003c9793          	slli	a5,s9,0x3
ffffffffc02003e4:	0118                	addi	a4,sp,128
ffffffffc02003e6:	97ba                	add	a5,a5,a4
ffffffffc02003e8:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003ec:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc02003f0:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003f2:	e591                	bnez	a1,ffffffffc02003fe <kmonitor+0x11e>
ffffffffc02003f4:	b7b5                	j	ffffffffc0200360 <kmonitor+0x80>
ffffffffc02003f6:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc02003fa:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003fc:	d1a5                	beqz	a1,ffffffffc020035c <kmonitor+0x7c>
ffffffffc02003fe:	8526                	mv	a0,s1
ffffffffc0200400:	3f9010ef          	jal	ra,ffffffffc0201ff8 <strchr>
ffffffffc0200404:	d96d                	beqz	a0,ffffffffc02003f6 <kmonitor+0x116>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200406:	00044583          	lbu	a1,0(s0)
ffffffffc020040a:	d9a9                	beqz	a1,ffffffffc020035c <kmonitor+0x7c>
ffffffffc020040c:	bf55                	j	ffffffffc02003c0 <kmonitor+0xe0>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020040e:	45c1                	li	a1,16
ffffffffc0200410:	855a                	mv	a0,s6
ffffffffc0200412:	d1dff0ef          	jal	ra,ffffffffc020012e <cprintf>
ffffffffc0200416:	b7e9                	j	ffffffffc02003e0 <kmonitor+0x100>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc0200418:	6582                	ld	a1,0(sp)
ffffffffc020041a:	00002517          	auipc	a0,0x2
ffffffffc020041e:	ed650513          	addi	a0,a0,-298 # ffffffffc02022f0 <etext+0x2d0>
ffffffffc0200422:	d0dff0ef          	jal	ra,ffffffffc020012e <cprintf>
    return 0;
ffffffffc0200426:	b715                	j	ffffffffc020034a <kmonitor+0x6a>

ffffffffc0200428 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc0200428:	00007317          	auipc	t1,0x7
ffffffffc020042c:	01830313          	addi	t1,t1,24 # ffffffffc0207440 <is_panic>
ffffffffc0200430:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc0200434:	715d                	addi	sp,sp,-80
ffffffffc0200436:	ec06                	sd	ra,24(sp)
ffffffffc0200438:	e822                	sd	s0,16(sp)
ffffffffc020043a:	f436                	sd	a3,40(sp)
ffffffffc020043c:	f83a                	sd	a4,48(sp)
ffffffffc020043e:	fc3e                	sd	a5,56(sp)
ffffffffc0200440:	e0c2                	sd	a6,64(sp)
ffffffffc0200442:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc0200444:	020e1a63          	bnez	t3,ffffffffc0200478 <__panic+0x50>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc0200448:	4785                	li	a5,1
ffffffffc020044a:	00f32023          	sw	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc020044e:	8432                	mv	s0,a2
ffffffffc0200450:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200452:	862e                	mv	a2,a1
ffffffffc0200454:	85aa                	mv	a1,a0
ffffffffc0200456:	00002517          	auipc	a0,0x2
ffffffffc020045a:	efa50513          	addi	a0,a0,-262 # ffffffffc0202350 <commands+0x48>
    va_start(ap, fmt);
ffffffffc020045e:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200460:	ccfff0ef          	jal	ra,ffffffffc020012e <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200464:	65a2                	ld	a1,8(sp)
ffffffffc0200466:	8522                	mv	a0,s0
ffffffffc0200468:	ca7ff0ef          	jal	ra,ffffffffc020010e <vcprintf>
    cprintf("\n");
ffffffffc020046c:	00002517          	auipc	a0,0x2
ffffffffc0200470:	d2c50513          	addi	a0,a0,-724 # ffffffffc0202198 <etext+0x178>
ffffffffc0200474:	cbbff0ef          	jal	ra,ffffffffc020012e <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc0200478:	412000ef          	jal	ra,ffffffffc020088a <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc020047c:	4501                	li	a0,0
ffffffffc020047e:	e63ff0ef          	jal	ra,ffffffffc02002e0 <kmonitor>
    while (1) {
ffffffffc0200482:	bfed                	j	ffffffffc020047c <__panic+0x54>

ffffffffc0200484 <clock_init>:

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
ffffffffc0200484:	1141                	addi	sp,sp,-16
ffffffffc0200486:	e406                	sd	ra,8(sp)
    /*
    "分级使能"机制：既要在 sie 中使能特定中断源，又要在 sstatus 中开启全局中断。
        1. sie : 细粒度控制，决定"哪些类型的中断可以被接收"
        2. sstatus.SIE : 粗粒度控制，决定"是否接收任何中断"
    */
    set_csr(sie, MIP_STIP);  // SSTATUS_SIE
ffffffffc0200488:	02000793          	li	a5,32
ffffffffc020048c:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200490:	c0102573          	rdtime	a0
    cprintf("++ setup timer interrupts\n");
}

// clock_set_next_event() ，它会读取当前时间 rdtime ，再通过 sbi_set_timer(get_cycles() + timebase) 请求固件设置“下一次触发时间点”。可以理解为“设了个闹钟”。
// 注意，时钟中断就是在这触发的！！！！！！！！！！！！
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200494:	67e1                	lui	a5,0x18
ffffffffc0200496:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc020049a:	953e                	add	a0,a0,a5
ffffffffc020049c:	293010ef          	jal	ra,ffffffffc0201f2e <sbi_set_timer>
}
ffffffffc02004a0:	60a2                	ld	ra,8(sp)
    ticks = 0;
ffffffffc02004a2:	00007797          	auipc	a5,0x7
ffffffffc02004a6:	fa07b323          	sd	zero,-90(a5) # ffffffffc0207448 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc02004aa:	00002517          	auipc	a0,0x2
ffffffffc02004ae:	ec650513          	addi	a0,a0,-314 # ffffffffc0202370 <commands+0x68>
}
ffffffffc02004b2:	0141                	addi	sp,sp,16
    cprintf("++ setup timer interrupts\n");
ffffffffc02004b4:	b9ad                	j	ffffffffc020012e <cprintf>

ffffffffc02004b6 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc02004b6:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc02004ba:	67e1                	lui	a5,0x18
ffffffffc02004bc:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc02004c0:	953e                	add	a0,a0,a5
ffffffffc02004c2:	26d0106f          	j	ffffffffc0201f2e <sbi_set_timer>

ffffffffc02004c6 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc02004c6:	8082                	ret

ffffffffc02004c8 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc02004c8:	0ff57513          	zext.b	a0,a0
ffffffffc02004cc:	2490106f          	j	ffffffffc0201f14 <sbi_console_putchar>

ffffffffc02004d0 <cons_getc>:
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    c = sbi_console_getchar();
ffffffffc02004d0:	2790106f          	j	ffffffffc0201f48 <sbi_console_getchar>

ffffffffc02004d4 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc02004d4:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc02004d6:	00002517          	auipc	a0,0x2
ffffffffc02004da:	eba50513          	addi	a0,a0,-326 # ffffffffc0202390 <commands+0x88>
void dtb_init(void) {
ffffffffc02004de:	fc86                	sd	ra,120(sp)
ffffffffc02004e0:	f8a2                	sd	s0,112(sp)
ffffffffc02004e2:	e8d2                	sd	s4,80(sp)
ffffffffc02004e4:	f4a6                	sd	s1,104(sp)
ffffffffc02004e6:	f0ca                	sd	s2,96(sp)
ffffffffc02004e8:	ecce                	sd	s3,88(sp)
ffffffffc02004ea:	e4d6                	sd	s5,72(sp)
ffffffffc02004ec:	e0da                	sd	s6,64(sp)
ffffffffc02004ee:	fc5e                	sd	s7,56(sp)
ffffffffc02004f0:	f862                	sd	s8,48(sp)
ffffffffc02004f2:	f466                	sd	s9,40(sp)
ffffffffc02004f4:	f06a                	sd	s10,32(sp)
ffffffffc02004f6:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc02004f8:	c37ff0ef          	jal	ra,ffffffffc020012e <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc02004fc:	00007597          	auipc	a1,0x7
ffffffffc0200500:	b045b583          	ld	a1,-1276(a1) # ffffffffc0207000 <boot_hartid>
ffffffffc0200504:	00002517          	auipc	a0,0x2
ffffffffc0200508:	e9c50513          	addi	a0,a0,-356 # ffffffffc02023a0 <commands+0x98>
ffffffffc020050c:	c23ff0ef          	jal	ra,ffffffffc020012e <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc0200510:	00007417          	auipc	s0,0x7
ffffffffc0200514:	af840413          	addi	s0,s0,-1288 # ffffffffc0207008 <boot_dtb>
ffffffffc0200518:	600c                	ld	a1,0(s0)
ffffffffc020051a:	00002517          	auipc	a0,0x2
ffffffffc020051e:	e9650513          	addi	a0,a0,-362 # ffffffffc02023b0 <commands+0xa8>
ffffffffc0200522:	c0dff0ef          	jal	ra,ffffffffc020012e <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200526:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc020052a:	00002517          	auipc	a0,0x2
ffffffffc020052e:	e9e50513          	addi	a0,a0,-354 # ffffffffc02023c8 <commands+0xc0>
    if (boot_dtb == 0) {
ffffffffc0200532:	120a0463          	beqz	s4,ffffffffc020065a <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200536:	57f5                	li	a5,-3
ffffffffc0200538:	07fa                	slli	a5,a5,0x1e
ffffffffc020053a:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc020053e:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200540:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200544:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200546:	0087d59b          	srliw	a1,a5,0x8
ffffffffc020054a:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020054e:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200552:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200556:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020055a:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020055c:	8ec9                	or	a3,a3,a0
ffffffffc020055e:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200562:	1b7d                	addi	s6,s6,-1
ffffffffc0200564:	0167f7b3          	and	a5,a5,s6
ffffffffc0200568:	8dd5                	or	a1,a1,a3
ffffffffc020056a:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc020056c:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200570:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc0200572:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed8a4d>
ffffffffc0200576:	10f59163          	bne	a1,a5,ffffffffc0200678 <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc020057a:	471c                	lw	a5,8(a4)
ffffffffc020057c:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc020057e:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200580:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200584:	0086d51b          	srliw	a0,a3,0x8
ffffffffc0200588:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020058c:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200590:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200594:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200598:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020059c:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005a0:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005a4:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005a8:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005aa:	01146433          	or	s0,s0,a7
ffffffffc02005ae:	0086969b          	slliw	a3,a3,0x8
ffffffffc02005b2:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005b6:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005b8:	0087979b          	slliw	a5,a5,0x8
ffffffffc02005bc:	8c49                	or	s0,s0,a0
ffffffffc02005be:	0166f6b3          	and	a3,a3,s6
ffffffffc02005c2:	00ca6a33          	or	s4,s4,a2
ffffffffc02005c6:	0167f7b3          	and	a5,a5,s6
ffffffffc02005ca:	8c55                	or	s0,s0,a3
ffffffffc02005cc:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02005d0:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02005d2:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02005d4:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02005d6:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02005da:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02005dc:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005de:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc02005e2:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02005e4:	00002917          	auipc	s2,0x2
ffffffffc02005e8:	e3490913          	addi	s2,s2,-460 # ffffffffc0202418 <commands+0x110>
ffffffffc02005ec:	49bd                	li	s3,15
        switch (token) {
ffffffffc02005ee:	4d91                	li	s11,4
ffffffffc02005f0:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02005f2:	00002497          	auipc	s1,0x2
ffffffffc02005f6:	e1e48493          	addi	s1,s1,-482 # ffffffffc0202410 <commands+0x108>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc02005fa:	000a2703          	lw	a4,0(s4)
ffffffffc02005fe:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200602:	0087569b          	srliw	a3,a4,0x8
ffffffffc0200606:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020060a:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020060e:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200612:	0107571b          	srliw	a4,a4,0x10
ffffffffc0200616:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200618:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020061c:	0087171b          	slliw	a4,a4,0x8
ffffffffc0200620:	8fd5                	or	a5,a5,a3
ffffffffc0200622:	00eb7733          	and	a4,s6,a4
ffffffffc0200626:	8fd9                	or	a5,a5,a4
ffffffffc0200628:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc020062a:	09778c63          	beq	a5,s7,ffffffffc02006c2 <dtb_init+0x1ee>
ffffffffc020062e:	00fbea63          	bltu	s7,a5,ffffffffc0200642 <dtb_init+0x16e>
ffffffffc0200632:	07a78663          	beq	a5,s10,ffffffffc020069e <dtb_init+0x1ca>
ffffffffc0200636:	4709                	li	a4,2
ffffffffc0200638:	00e79763          	bne	a5,a4,ffffffffc0200646 <dtb_init+0x172>
ffffffffc020063c:	4c81                	li	s9,0
ffffffffc020063e:	8a56                	mv	s4,s5
ffffffffc0200640:	bf6d                	j	ffffffffc02005fa <dtb_init+0x126>
ffffffffc0200642:	ffb78ee3          	beq	a5,s11,ffffffffc020063e <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc0200646:	00002517          	auipc	a0,0x2
ffffffffc020064a:	e4a50513          	addi	a0,a0,-438 # ffffffffc0202490 <commands+0x188>
ffffffffc020064e:	ae1ff0ef          	jal	ra,ffffffffc020012e <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc0200652:	00002517          	auipc	a0,0x2
ffffffffc0200656:	e7650513          	addi	a0,a0,-394 # ffffffffc02024c8 <commands+0x1c0>
}
ffffffffc020065a:	7446                	ld	s0,112(sp)
ffffffffc020065c:	70e6                	ld	ra,120(sp)
ffffffffc020065e:	74a6                	ld	s1,104(sp)
ffffffffc0200660:	7906                	ld	s2,96(sp)
ffffffffc0200662:	69e6                	ld	s3,88(sp)
ffffffffc0200664:	6a46                	ld	s4,80(sp)
ffffffffc0200666:	6aa6                	ld	s5,72(sp)
ffffffffc0200668:	6b06                	ld	s6,64(sp)
ffffffffc020066a:	7be2                	ld	s7,56(sp)
ffffffffc020066c:	7c42                	ld	s8,48(sp)
ffffffffc020066e:	7ca2                	ld	s9,40(sp)
ffffffffc0200670:	7d02                	ld	s10,32(sp)
ffffffffc0200672:	6de2                	ld	s11,24(sp)
ffffffffc0200674:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc0200676:	bc65                	j	ffffffffc020012e <cprintf>
}
ffffffffc0200678:	7446                	ld	s0,112(sp)
ffffffffc020067a:	70e6                	ld	ra,120(sp)
ffffffffc020067c:	74a6                	ld	s1,104(sp)
ffffffffc020067e:	7906                	ld	s2,96(sp)
ffffffffc0200680:	69e6                	ld	s3,88(sp)
ffffffffc0200682:	6a46                	ld	s4,80(sp)
ffffffffc0200684:	6aa6                	ld	s5,72(sp)
ffffffffc0200686:	6b06                	ld	s6,64(sp)
ffffffffc0200688:	7be2                	ld	s7,56(sp)
ffffffffc020068a:	7c42                	ld	s8,48(sp)
ffffffffc020068c:	7ca2                	ld	s9,40(sp)
ffffffffc020068e:	7d02                	ld	s10,32(sp)
ffffffffc0200690:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200692:	00002517          	auipc	a0,0x2
ffffffffc0200696:	d5650513          	addi	a0,a0,-682 # ffffffffc02023e8 <commands+0xe0>
}
ffffffffc020069a:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc020069c:	bc49                	j	ffffffffc020012e <cprintf>
                int name_len = strlen(name);
ffffffffc020069e:	8556                	mv	a0,s5
ffffffffc02006a0:	0df010ef          	jal	ra,ffffffffc0201f7e <strlen>
ffffffffc02006a4:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02006a6:	4619                	li	a2,6
ffffffffc02006a8:	85a6                	mv	a1,s1
ffffffffc02006aa:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc02006ac:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02006ae:	125010ef          	jal	ra,ffffffffc0201fd2 <strncmp>
ffffffffc02006b2:	e111                	bnez	a0,ffffffffc02006b6 <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc02006b4:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02006b6:	0a91                	addi	s5,s5,4
ffffffffc02006b8:	9ad2                	add	s5,s5,s4
ffffffffc02006ba:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc02006be:	8a56                	mv	s4,s5
ffffffffc02006c0:	bf2d                	j	ffffffffc02005fa <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc02006c2:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02006c6:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ca:	0087d71b          	srliw	a4,a5,0x8
ffffffffc02006ce:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006d2:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006d6:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006da:	0107d79b          	srliw	a5,a5,0x10
ffffffffc02006de:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006e2:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006e6:	0087979b          	slliw	a5,a5,0x8
ffffffffc02006ea:	00eaeab3          	or	s5,s5,a4
ffffffffc02006ee:	00fb77b3          	and	a5,s6,a5
ffffffffc02006f2:	00faeab3          	or	s5,s5,a5
ffffffffc02006f6:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02006f8:	000c9c63          	bnez	s9,ffffffffc0200710 <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc02006fc:	1a82                	slli	s5,s5,0x20
ffffffffc02006fe:	00368793          	addi	a5,a3,3
ffffffffc0200702:	020ada93          	srli	s5,s5,0x20
ffffffffc0200706:	9abe                	add	s5,s5,a5
ffffffffc0200708:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc020070c:	8a56                	mv	s4,s5
ffffffffc020070e:	b5f5                	j	ffffffffc02005fa <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200710:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200714:	85ca                	mv	a1,s2
ffffffffc0200716:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200718:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020071c:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200720:	0187971b          	slliw	a4,a5,0x18
ffffffffc0200724:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200728:	0107d79b          	srliw	a5,a5,0x10
ffffffffc020072c:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020072e:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200732:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200736:	8d59                	or	a0,a0,a4
ffffffffc0200738:	00fb77b3          	and	a5,s6,a5
ffffffffc020073c:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc020073e:	1502                	slli	a0,a0,0x20
ffffffffc0200740:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200742:	9522                	add	a0,a0,s0
ffffffffc0200744:	071010ef          	jal	ra,ffffffffc0201fb4 <strcmp>
ffffffffc0200748:	66a2                	ld	a3,8(sp)
ffffffffc020074a:	f94d                	bnez	a0,ffffffffc02006fc <dtb_init+0x228>
ffffffffc020074c:	fb59f8e3          	bgeu	s3,s5,ffffffffc02006fc <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc0200750:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc0200754:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200758:	00002517          	auipc	a0,0x2
ffffffffc020075c:	cc850513          	addi	a0,a0,-824 # ffffffffc0202420 <commands+0x118>
           fdt32_to_cpu(x >> 32);
ffffffffc0200760:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200764:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc0200768:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020076c:	0187de1b          	srliw	t3,a5,0x18
ffffffffc0200770:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200774:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200778:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020077c:	0187d693          	srli	a3,a5,0x18
ffffffffc0200780:	01861f1b          	slliw	t5,a2,0x18
ffffffffc0200784:	0087579b          	srliw	a5,a4,0x8
ffffffffc0200788:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020078c:	0106561b          	srliw	a2,a2,0x10
ffffffffc0200790:	010f6f33          	or	t5,t5,a6
ffffffffc0200794:	0187529b          	srliw	t0,a4,0x18
ffffffffc0200798:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020079c:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007a0:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007a4:	0186f6b3          	and	a3,a3,s8
ffffffffc02007a8:	01859e1b          	slliw	t3,a1,0x18
ffffffffc02007ac:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007b0:	0107581b          	srliw	a6,a4,0x10
ffffffffc02007b4:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007b8:	8361                	srli	a4,a4,0x18
ffffffffc02007ba:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007be:	0105d59b          	srliw	a1,a1,0x10
ffffffffc02007c2:	01e6e6b3          	or	a3,a3,t5
ffffffffc02007c6:	00cb7633          	and	a2,s6,a2
ffffffffc02007ca:	0088181b          	slliw	a6,a6,0x8
ffffffffc02007ce:	0085959b          	slliw	a1,a1,0x8
ffffffffc02007d2:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007d6:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007da:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007de:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007e2:	0088989b          	slliw	a7,a7,0x8
ffffffffc02007e6:	011b78b3          	and	a7,s6,a7
ffffffffc02007ea:	005eeeb3          	or	t4,t4,t0
ffffffffc02007ee:	00c6e733          	or	a4,a3,a2
ffffffffc02007f2:	006c6c33          	or	s8,s8,t1
ffffffffc02007f6:	010b76b3          	and	a3,s6,a6
ffffffffc02007fa:	00bb7b33          	and	s6,s6,a1
ffffffffc02007fe:	01d7e7b3          	or	a5,a5,t4
ffffffffc0200802:	016c6b33          	or	s6,s8,s6
ffffffffc0200806:	01146433          	or	s0,s0,a7
ffffffffc020080a:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc020080c:	1702                	slli	a4,a4,0x20
ffffffffc020080e:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200810:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200812:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200814:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200816:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020081a:	0167eb33          	or	s6,a5,s6
ffffffffc020081e:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200820:	90fff0ef          	jal	ra,ffffffffc020012e <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc0200824:	85a2                	mv	a1,s0
ffffffffc0200826:	00002517          	auipc	a0,0x2
ffffffffc020082a:	c1a50513          	addi	a0,a0,-998 # ffffffffc0202440 <commands+0x138>
ffffffffc020082e:	901ff0ef          	jal	ra,ffffffffc020012e <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc0200832:	014b5613          	srli	a2,s6,0x14
ffffffffc0200836:	85da                	mv	a1,s6
ffffffffc0200838:	00002517          	auipc	a0,0x2
ffffffffc020083c:	c2050513          	addi	a0,a0,-992 # ffffffffc0202458 <commands+0x150>
ffffffffc0200840:	8efff0ef          	jal	ra,ffffffffc020012e <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200844:	008b05b3          	add	a1,s6,s0
ffffffffc0200848:	15fd                	addi	a1,a1,-1
ffffffffc020084a:	00002517          	auipc	a0,0x2
ffffffffc020084e:	c2e50513          	addi	a0,a0,-978 # ffffffffc0202478 <commands+0x170>
ffffffffc0200852:	8ddff0ef          	jal	ra,ffffffffc020012e <cprintf>
    cprintf("DTB init completed\n");
ffffffffc0200856:	00002517          	auipc	a0,0x2
ffffffffc020085a:	c7250513          	addi	a0,a0,-910 # ffffffffc02024c8 <commands+0x1c0>
        memory_base = mem_base;
ffffffffc020085e:	00007797          	auipc	a5,0x7
ffffffffc0200862:	be87b923          	sd	s0,-1038(a5) # ffffffffc0207450 <memory_base>
        memory_size = mem_size;
ffffffffc0200866:	00007797          	auipc	a5,0x7
ffffffffc020086a:	bf67b923          	sd	s6,-1038(a5) # ffffffffc0207458 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc020086e:	b3f5                	j	ffffffffc020065a <dtb_init+0x186>

ffffffffc0200870 <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc0200870:	00007517          	auipc	a0,0x7
ffffffffc0200874:	be053503          	ld	a0,-1056(a0) # ffffffffc0207450 <memory_base>
ffffffffc0200878:	8082                	ret

ffffffffc020087a <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc020087a:	00007517          	auipc	a0,0x7
ffffffffc020087e:	bde53503          	ld	a0,-1058(a0) # ffffffffc0207458 <memory_size>
ffffffffc0200882:	8082                	ret

ffffffffc0200884 <intr_enable>:
- 即使在 sie 中使能了特定中断源，如果 SSTATUS_SIE 为 0，所有中断都会被屏蔽
- 当中断发生时，硬件会自动清除 SIE 位并保存到 SPIE 位，防止中断嵌套； sret 返回时会从 SPIE 恢复 SIE
*/
// 中断使能状态位置位
// SSTATUS_SPP本来就是0，无需置位
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200884:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0200888:	8082                	ret

ffffffffc020088a <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc020088a:	100177f3          	csrrci	a5,sstatus,2
ffffffffc020088e:	8082                	ret

ffffffffc0200890 <idt_init>:
     */

    extern void __alltraps(void);
    /* Set sup0 scratch register to 0, indicating to exception vector
       that we are presently executing in the kernel */
    write_csr(sscratch, 0);  // 中断后S态接管
ffffffffc0200890:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);  // 中断后全部跳转至__alltraps
ffffffffc0200894:	00000797          	auipc	a5,0x0
ffffffffc0200898:	3b878793          	addi	a5,a5,952 # ffffffffc0200c4c <__alltraps>
ffffffffc020089c:	10579073          	csrw	stvec,a5
}
ffffffffc02008a0:	8082                	ret

ffffffffc02008a2 <print_regs>:
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02008a2:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
ffffffffc02008a4:	1141                	addi	sp,sp,-16
ffffffffc02008a6:	e022                	sd	s0,0(sp)
ffffffffc02008a8:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02008aa:	00002517          	auipc	a0,0x2
ffffffffc02008ae:	c3650513          	addi	a0,a0,-970 # ffffffffc02024e0 <commands+0x1d8>
void print_regs(struct pushregs *gpr) {
ffffffffc02008b2:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02008b4:	87bff0ef          	jal	ra,ffffffffc020012e <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc02008b8:	640c                	ld	a1,8(s0)
ffffffffc02008ba:	00002517          	auipc	a0,0x2
ffffffffc02008be:	c3e50513          	addi	a0,a0,-962 # ffffffffc02024f8 <commands+0x1f0>
ffffffffc02008c2:	86dff0ef          	jal	ra,ffffffffc020012e <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02008c6:	680c                	ld	a1,16(s0)
ffffffffc02008c8:	00002517          	auipc	a0,0x2
ffffffffc02008cc:	c4850513          	addi	a0,a0,-952 # ffffffffc0202510 <commands+0x208>
ffffffffc02008d0:	85fff0ef          	jal	ra,ffffffffc020012e <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc02008d4:	6c0c                	ld	a1,24(s0)
ffffffffc02008d6:	00002517          	auipc	a0,0x2
ffffffffc02008da:	c5250513          	addi	a0,a0,-942 # ffffffffc0202528 <commands+0x220>
ffffffffc02008de:	851ff0ef          	jal	ra,ffffffffc020012e <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02008e2:	700c                	ld	a1,32(s0)
ffffffffc02008e4:	00002517          	auipc	a0,0x2
ffffffffc02008e8:	c5c50513          	addi	a0,a0,-932 # ffffffffc0202540 <commands+0x238>
ffffffffc02008ec:	843ff0ef          	jal	ra,ffffffffc020012e <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02008f0:	740c                	ld	a1,40(s0)
ffffffffc02008f2:	00002517          	auipc	a0,0x2
ffffffffc02008f6:	c6650513          	addi	a0,a0,-922 # ffffffffc0202558 <commands+0x250>
ffffffffc02008fa:	835ff0ef          	jal	ra,ffffffffc020012e <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02008fe:	780c                	ld	a1,48(s0)
ffffffffc0200900:	00002517          	auipc	a0,0x2
ffffffffc0200904:	c7050513          	addi	a0,a0,-912 # ffffffffc0202570 <commands+0x268>
ffffffffc0200908:	827ff0ef          	jal	ra,ffffffffc020012e <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc020090c:	7c0c                	ld	a1,56(s0)
ffffffffc020090e:	00002517          	auipc	a0,0x2
ffffffffc0200912:	c7a50513          	addi	a0,a0,-902 # ffffffffc0202588 <commands+0x280>
ffffffffc0200916:	819ff0ef          	jal	ra,ffffffffc020012e <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc020091a:	602c                	ld	a1,64(s0)
ffffffffc020091c:	00002517          	auipc	a0,0x2
ffffffffc0200920:	c8450513          	addi	a0,a0,-892 # ffffffffc02025a0 <commands+0x298>
ffffffffc0200924:	80bff0ef          	jal	ra,ffffffffc020012e <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200928:	642c                	ld	a1,72(s0)
ffffffffc020092a:	00002517          	auipc	a0,0x2
ffffffffc020092e:	c8e50513          	addi	a0,a0,-882 # ffffffffc02025b8 <commands+0x2b0>
ffffffffc0200932:	ffcff0ef          	jal	ra,ffffffffc020012e <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200936:	682c                	ld	a1,80(s0)
ffffffffc0200938:	00002517          	auipc	a0,0x2
ffffffffc020093c:	c9850513          	addi	a0,a0,-872 # ffffffffc02025d0 <commands+0x2c8>
ffffffffc0200940:	feeff0ef          	jal	ra,ffffffffc020012e <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200944:	6c2c                	ld	a1,88(s0)
ffffffffc0200946:	00002517          	auipc	a0,0x2
ffffffffc020094a:	ca250513          	addi	a0,a0,-862 # ffffffffc02025e8 <commands+0x2e0>
ffffffffc020094e:	fe0ff0ef          	jal	ra,ffffffffc020012e <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200952:	702c                	ld	a1,96(s0)
ffffffffc0200954:	00002517          	auipc	a0,0x2
ffffffffc0200958:	cac50513          	addi	a0,a0,-852 # ffffffffc0202600 <commands+0x2f8>
ffffffffc020095c:	fd2ff0ef          	jal	ra,ffffffffc020012e <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200960:	742c                	ld	a1,104(s0)
ffffffffc0200962:	00002517          	auipc	a0,0x2
ffffffffc0200966:	cb650513          	addi	a0,a0,-842 # ffffffffc0202618 <commands+0x310>
ffffffffc020096a:	fc4ff0ef          	jal	ra,ffffffffc020012e <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc020096e:	782c                	ld	a1,112(s0)
ffffffffc0200970:	00002517          	auipc	a0,0x2
ffffffffc0200974:	cc050513          	addi	a0,a0,-832 # ffffffffc0202630 <commands+0x328>
ffffffffc0200978:	fb6ff0ef          	jal	ra,ffffffffc020012e <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc020097c:	7c2c                	ld	a1,120(s0)
ffffffffc020097e:	00002517          	auipc	a0,0x2
ffffffffc0200982:	cca50513          	addi	a0,a0,-822 # ffffffffc0202648 <commands+0x340>
ffffffffc0200986:	fa8ff0ef          	jal	ra,ffffffffc020012e <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc020098a:	604c                	ld	a1,128(s0)
ffffffffc020098c:	00002517          	auipc	a0,0x2
ffffffffc0200990:	cd450513          	addi	a0,a0,-812 # ffffffffc0202660 <commands+0x358>
ffffffffc0200994:	f9aff0ef          	jal	ra,ffffffffc020012e <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200998:	644c                	ld	a1,136(s0)
ffffffffc020099a:	00002517          	auipc	a0,0x2
ffffffffc020099e:	cde50513          	addi	a0,a0,-802 # ffffffffc0202678 <commands+0x370>
ffffffffc02009a2:	f8cff0ef          	jal	ra,ffffffffc020012e <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc02009a6:	684c                	ld	a1,144(s0)
ffffffffc02009a8:	00002517          	auipc	a0,0x2
ffffffffc02009ac:	ce850513          	addi	a0,a0,-792 # ffffffffc0202690 <commands+0x388>
ffffffffc02009b0:	f7eff0ef          	jal	ra,ffffffffc020012e <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc02009b4:	6c4c                	ld	a1,152(s0)
ffffffffc02009b6:	00002517          	auipc	a0,0x2
ffffffffc02009ba:	cf250513          	addi	a0,a0,-782 # ffffffffc02026a8 <commands+0x3a0>
ffffffffc02009be:	f70ff0ef          	jal	ra,ffffffffc020012e <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc02009c2:	704c                	ld	a1,160(s0)
ffffffffc02009c4:	00002517          	auipc	a0,0x2
ffffffffc02009c8:	cfc50513          	addi	a0,a0,-772 # ffffffffc02026c0 <commands+0x3b8>
ffffffffc02009cc:	f62ff0ef          	jal	ra,ffffffffc020012e <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc02009d0:	744c                	ld	a1,168(s0)
ffffffffc02009d2:	00002517          	auipc	a0,0x2
ffffffffc02009d6:	d0650513          	addi	a0,a0,-762 # ffffffffc02026d8 <commands+0x3d0>
ffffffffc02009da:	f54ff0ef          	jal	ra,ffffffffc020012e <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02009de:	784c                	ld	a1,176(s0)
ffffffffc02009e0:	00002517          	auipc	a0,0x2
ffffffffc02009e4:	d1050513          	addi	a0,a0,-752 # ffffffffc02026f0 <commands+0x3e8>
ffffffffc02009e8:	f46ff0ef          	jal	ra,ffffffffc020012e <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02009ec:	7c4c                	ld	a1,184(s0)
ffffffffc02009ee:	00002517          	auipc	a0,0x2
ffffffffc02009f2:	d1a50513          	addi	a0,a0,-742 # ffffffffc0202708 <commands+0x400>
ffffffffc02009f6:	f38ff0ef          	jal	ra,ffffffffc020012e <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02009fa:	606c                	ld	a1,192(s0)
ffffffffc02009fc:	00002517          	auipc	a0,0x2
ffffffffc0200a00:	d2450513          	addi	a0,a0,-732 # ffffffffc0202720 <commands+0x418>
ffffffffc0200a04:	f2aff0ef          	jal	ra,ffffffffc020012e <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc0200a08:	646c                	ld	a1,200(s0)
ffffffffc0200a0a:	00002517          	auipc	a0,0x2
ffffffffc0200a0e:	d2e50513          	addi	a0,a0,-722 # ffffffffc0202738 <commands+0x430>
ffffffffc0200a12:	f1cff0ef          	jal	ra,ffffffffc020012e <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200a16:	686c                	ld	a1,208(s0)
ffffffffc0200a18:	00002517          	auipc	a0,0x2
ffffffffc0200a1c:	d3850513          	addi	a0,a0,-712 # ffffffffc0202750 <commands+0x448>
ffffffffc0200a20:	f0eff0ef          	jal	ra,ffffffffc020012e <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200a24:	6c6c                	ld	a1,216(s0)
ffffffffc0200a26:	00002517          	auipc	a0,0x2
ffffffffc0200a2a:	d4250513          	addi	a0,a0,-702 # ffffffffc0202768 <commands+0x460>
ffffffffc0200a2e:	f00ff0ef          	jal	ra,ffffffffc020012e <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200a32:	706c                	ld	a1,224(s0)
ffffffffc0200a34:	00002517          	auipc	a0,0x2
ffffffffc0200a38:	d4c50513          	addi	a0,a0,-692 # ffffffffc0202780 <commands+0x478>
ffffffffc0200a3c:	ef2ff0ef          	jal	ra,ffffffffc020012e <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200a40:	746c                	ld	a1,232(s0)
ffffffffc0200a42:	00002517          	auipc	a0,0x2
ffffffffc0200a46:	d5650513          	addi	a0,a0,-682 # ffffffffc0202798 <commands+0x490>
ffffffffc0200a4a:	ee4ff0ef          	jal	ra,ffffffffc020012e <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200a4e:	786c                	ld	a1,240(s0)
ffffffffc0200a50:	00002517          	auipc	a0,0x2
ffffffffc0200a54:	d6050513          	addi	a0,a0,-672 # ffffffffc02027b0 <commands+0x4a8>
ffffffffc0200a58:	ed6ff0ef          	jal	ra,ffffffffc020012e <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a5c:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200a5e:	6402                	ld	s0,0(sp)
ffffffffc0200a60:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a62:	00002517          	auipc	a0,0x2
ffffffffc0200a66:	d6650513          	addi	a0,a0,-666 # ffffffffc02027c8 <commands+0x4c0>
}
ffffffffc0200a6a:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a6c:	ec2ff06f          	j	ffffffffc020012e <cprintf>

ffffffffc0200a70 <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
ffffffffc0200a70:	1141                	addi	sp,sp,-16
ffffffffc0200a72:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a74:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
ffffffffc0200a76:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a78:	00002517          	auipc	a0,0x2
ffffffffc0200a7c:	d6850513          	addi	a0,a0,-664 # ffffffffc02027e0 <commands+0x4d8>
void print_trapframe(struct trapframe *tf) {
ffffffffc0200a80:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a82:	eacff0ef          	jal	ra,ffffffffc020012e <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200a86:	8522                	mv	a0,s0
ffffffffc0200a88:	e1bff0ef          	jal	ra,ffffffffc02008a2 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200a8c:	10043583          	ld	a1,256(s0)
ffffffffc0200a90:	00002517          	auipc	a0,0x2
ffffffffc0200a94:	d6850513          	addi	a0,a0,-664 # ffffffffc02027f8 <commands+0x4f0>
ffffffffc0200a98:	e96ff0ef          	jal	ra,ffffffffc020012e <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200a9c:	10843583          	ld	a1,264(s0)
ffffffffc0200aa0:	00002517          	auipc	a0,0x2
ffffffffc0200aa4:	d7050513          	addi	a0,a0,-656 # ffffffffc0202810 <commands+0x508>
ffffffffc0200aa8:	e86ff0ef          	jal	ra,ffffffffc020012e <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200aac:	11043583          	ld	a1,272(s0)
ffffffffc0200ab0:	00002517          	auipc	a0,0x2
ffffffffc0200ab4:	d7850513          	addi	a0,a0,-648 # ffffffffc0202828 <commands+0x520>
ffffffffc0200ab8:	e76ff0ef          	jal	ra,ffffffffc020012e <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200abc:	11843583          	ld	a1,280(s0)
}
ffffffffc0200ac0:	6402                	ld	s0,0(sp)
ffffffffc0200ac2:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200ac4:	00002517          	auipc	a0,0x2
ffffffffc0200ac8:	d7c50513          	addi	a0,a0,-644 # ffffffffc0202840 <commands+0x538>
}
ffffffffc0200acc:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200ace:	e60ff06f          	j	ffffffffc020012e <cprintf>

ffffffffc0200ad2 <interrupt_handler>:

void interrupt_handler(struct trapframe *tf) {
    // interrupt_handler() 则用“清除最高位”的技巧取出具体中断号。
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc0200ad2:	11853783          	ld	a5,280(a0)
ffffffffc0200ad6:	472d                	li	a4,11
ffffffffc0200ad8:	0786                	slli	a5,a5,0x1
ffffffffc0200ada:	8385                	srli	a5,a5,0x1
ffffffffc0200adc:	08f76363          	bltu	a4,a5,ffffffffc0200b62 <interrupt_handler+0x90>
ffffffffc0200ae0:	00002717          	auipc	a4,0x2
ffffffffc0200ae4:	e4070713          	addi	a4,a4,-448 # ffffffffc0202920 <commands+0x618>
ffffffffc0200ae8:	078a                	slli	a5,a5,0x2
ffffffffc0200aea:	97ba                	add	a5,a5,a4
ffffffffc0200aec:	439c                	lw	a5,0(a5)
ffffffffc0200aee:	97ba                	add	a5,a5,a4
ffffffffc0200af0:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc0200af2:	00002517          	auipc	a0,0x2
ffffffffc0200af6:	dc650513          	addi	a0,a0,-570 # ffffffffc02028b8 <commands+0x5b0>
ffffffffc0200afa:	e34ff06f          	j	ffffffffc020012e <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc0200afe:	00002517          	auipc	a0,0x2
ffffffffc0200b02:	d9a50513          	addi	a0,a0,-614 # ffffffffc0202898 <commands+0x590>
ffffffffc0200b06:	e28ff06f          	j	ffffffffc020012e <cprintf>
            cprintf("User software interrupt\n");
ffffffffc0200b0a:	00002517          	auipc	a0,0x2
ffffffffc0200b0e:	d4e50513          	addi	a0,a0,-690 # ffffffffc0202858 <commands+0x550>
ffffffffc0200b12:	e1cff06f          	j	ffffffffc020012e <cprintf>
            break;
        case IRQ_U_TIMER:
            cprintf("User Timer interrupt\n");
ffffffffc0200b16:	00002517          	auipc	a0,0x2
ffffffffc0200b1a:	dc250513          	addi	a0,a0,-574 # ffffffffc02028d8 <commands+0x5d0>
ffffffffc0200b1e:	e10ff06f          	j	ffffffffc020012e <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc0200b22:	1141                	addi	sp,sp,-16
ffffffffc0200b24:	e406                	sd	ra,8(sp)
            /*(1)设置下次时钟中断- clock_set_next_event()
             *(2)计数器（ticks）加一
             *(3)当计数器加到100的时候，我们会输出一个`100ticks`表示我们触发了100次时钟中断，同时打印次数（num）加一
            * (4)判断打印次数，当打印次数为10时，调用<sbi.h>中的关机函数关机
            */
            clock_set_next_event();
ffffffffc0200b26:	991ff0ef          	jal	ra,ffffffffc02004b6 <clock_set_next_event>
            ticks++;
ffffffffc0200b2a:	00007797          	auipc	a5,0x7
ffffffffc0200b2e:	91e78793          	addi	a5,a5,-1762 # ffffffffc0207448 <ticks>
ffffffffc0200b32:	6398                	ld	a4,0(a5)
ffffffffc0200b34:	0705                	addi	a4,a4,1
ffffffffc0200b36:	e398                	sd	a4,0(a5)
            if (ticks % TICK_NUM == 0) {
ffffffffc0200b38:	639c                	ld	a5,0(a5)
ffffffffc0200b3a:	06400713          	li	a4,100
ffffffffc0200b3e:	02e7f7b3          	remu	a5,a5,a4
ffffffffc0200b42:	c38d                	beqz	a5,ffffffffc0200b64 <interrupt_handler+0x92>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200b44:	60a2                	ld	ra,8(sp)
ffffffffc0200b46:	0141                	addi	sp,sp,16
ffffffffc0200b48:	8082                	ret
            cprintf("Supervisor external interrupt\n");
ffffffffc0200b4a:	00002517          	auipc	a0,0x2
ffffffffc0200b4e:	db650513          	addi	a0,a0,-586 # ffffffffc0202900 <commands+0x5f8>
ffffffffc0200b52:	ddcff06f          	j	ffffffffc020012e <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc0200b56:	00002517          	auipc	a0,0x2
ffffffffc0200b5a:	d2250513          	addi	a0,a0,-734 # ffffffffc0202878 <commands+0x570>
ffffffffc0200b5e:	dd0ff06f          	j	ffffffffc020012e <cprintf>
            print_trapframe(tf);
ffffffffc0200b62:	b739                	j	ffffffffc0200a70 <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200b64:	06400593          	li	a1,100
ffffffffc0200b68:	00002517          	auipc	a0,0x2
ffffffffc0200b6c:	d8850513          	addi	a0,a0,-632 # ffffffffc02028f0 <commands+0x5e8>
ffffffffc0200b70:	dbeff0ef          	jal	ra,ffffffffc020012e <cprintf>
                num++;
ffffffffc0200b74:	00007717          	auipc	a4,0x7
ffffffffc0200b78:	8ec70713          	addi	a4,a4,-1812 # ffffffffc0207460 <num.0>
ffffffffc0200b7c:	431c                	lw	a5,0(a4)
                if (num == 10) {
ffffffffc0200b7e:	46a9                	li	a3,10
                num++;
ffffffffc0200b80:	0017861b          	addiw	a2,a5,1
ffffffffc0200b84:	c310                	sw	a2,0(a4)
                if (num == 10) {
ffffffffc0200b86:	fad61fe3          	bne	a2,a3,ffffffffc0200b44 <interrupt_handler+0x72>
}
ffffffffc0200b8a:	60a2                	ld	ra,8(sp)
ffffffffc0200b8c:	0141                	addi	sp,sp,16
                    sbi_shutdown();
ffffffffc0200b8e:	3d60106f          	j	ffffffffc0201f64 <sbi_shutdown>

ffffffffc0200b92 <exception_handler>:

void exception_handler(struct trapframe *tf) {
ffffffffc0200b92:	1101                	addi	sp,sp,-32
ffffffffc0200b94:	e822                	sd	s0,16(sp)
    switch (tf->cause) {
ffffffffc0200b96:	11853403          	ld	s0,280(a0)
void exception_handler(struct trapframe *tf) {
ffffffffc0200b9a:	e426                	sd	s1,8(sp)
ffffffffc0200b9c:	e04a                	sd	s2,0(sp)
ffffffffc0200b9e:	ec06                	sd	ra,24(sp)
    switch (tf->cause) {
ffffffffc0200ba0:	490d                	li	s2,3
void exception_handler(struct trapframe *tf) {
ffffffffc0200ba2:	84aa                	mv	s1,a0
    switch (tf->cause) {
ffffffffc0200ba4:	05240f63          	beq	s0,s2,ffffffffc0200c02 <exception_handler+0x70>
ffffffffc0200ba8:	04896363          	bltu	s2,s0,ffffffffc0200bee <exception_handler+0x5c>
ffffffffc0200bac:	4789                	li	a5,2
ffffffffc0200bae:	02f41a63          	bne	s0,a5,ffffffffc0200be2 <exception_handler+0x50>
             /* LAB3 CHALLENGE3   2312326 范鼎辉 2311136 崔颖欣 2312585 解子萱  :  */
            /*(1)输出指令异常类型（ Illegal instruction）
             *(2)输出异常指令地址
             *(3)更新 tf->epc寄存器
            */
            cprintf("Exception type:Illegal instruction\n");
ffffffffc0200bb2:	00002517          	auipc	a0,0x2
ffffffffc0200bb6:	d9e50513          	addi	a0,a0,-610 # ffffffffc0202950 <commands+0x648>
ffffffffc0200bba:	d74ff0ef          	jal	ra,ffffffffc020012e <cprintf>
            cprintf("Illegal instruction caught at 0x%08x\n", tf->epc);
ffffffffc0200bbe:	1084b583          	ld	a1,264(s1)
ffffffffc0200bc2:	00002517          	auipc	a0,0x2
ffffffffc0200bc6:	db650513          	addi	a0,a0,-586 # ffffffffc0202978 <commands+0x670>
ffffffffc0200bca:	d64ff0ef          	jal	ra,ffffffffc020012e <cprintf>
            {
                // 从异常指令地址 tf->epc 所指的内存中，读取16位值，并存入变量。
                uint16_t insn16 = *(uint16_t *)(tf->epc);
ffffffffc0200bce:	1084b783          	ld	a5,264(s1)
                if ((insn16 & 0x3) != 0x3) {
ffffffffc0200bd2:	0007d703          	lhu	a4,0(a5)
ffffffffc0200bd6:	8b0d                	andi	a4,a4,3
ffffffffc0200bd8:	05270a63          	beq	a4,s2,ffffffffc0200c2c <exception_handler+0x9a>
            cprintf("ebreak caught at 0x%08x\n", tf->epc);
            {
                // 从异常指令地址 tf->epc 所指的内存中，读取16位值，并存入变量。
                uint16_t insn16 = *(uint16_t *)(tf->epc);
                if ((insn16 & 0x3) != 0x3) {
                    tf->epc += 2;  // 压缩指令长度16位
ffffffffc0200bdc:	0789                	addi	a5,a5,2
ffffffffc0200bde:	10f4b423          	sd	a5,264(s1)
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200be2:	60e2                	ld	ra,24(sp)
ffffffffc0200be4:	6442                	ld	s0,16(sp)
ffffffffc0200be6:	64a2                	ld	s1,8(sp)
ffffffffc0200be8:	6902                	ld	s2,0(sp)
ffffffffc0200bea:	6105                	addi	sp,sp,32
ffffffffc0200bec:	8082                	ret
    switch (tf->cause) {
ffffffffc0200bee:	1471                	addi	s0,s0,-4
ffffffffc0200bf0:	479d                	li	a5,7
ffffffffc0200bf2:	fe87f8e3          	bgeu	a5,s0,ffffffffc0200be2 <exception_handler+0x50>
}
ffffffffc0200bf6:	6442                	ld	s0,16(sp)
ffffffffc0200bf8:	60e2                	ld	ra,24(sp)
ffffffffc0200bfa:	64a2                	ld	s1,8(sp)
ffffffffc0200bfc:	6902                	ld	s2,0(sp)
ffffffffc0200bfe:	6105                	addi	sp,sp,32
            print_trapframe(tf);
ffffffffc0200c00:	bd85                	j	ffffffffc0200a70 <print_trapframe>
            cprintf("Exception type:breakpoint\n");
ffffffffc0200c02:	00002517          	auipc	a0,0x2
ffffffffc0200c06:	d9e50513          	addi	a0,a0,-610 # ffffffffc02029a0 <commands+0x698>
ffffffffc0200c0a:	d24ff0ef          	jal	ra,ffffffffc020012e <cprintf>
            cprintf("ebreak caught at 0x%08x\n", tf->epc);
ffffffffc0200c0e:	1084b583          	ld	a1,264(s1)
ffffffffc0200c12:	00002517          	auipc	a0,0x2
ffffffffc0200c16:	dae50513          	addi	a0,a0,-594 # ffffffffc02029c0 <commands+0x6b8>
ffffffffc0200c1a:	d14ff0ef          	jal	ra,ffffffffc020012e <cprintf>
                uint16_t insn16 = *(uint16_t *)(tf->epc);
ffffffffc0200c1e:	1084b783          	ld	a5,264(s1)
                if ((insn16 & 0x3) != 0x3) {
ffffffffc0200c22:	0007d703          	lhu	a4,0(a5)
ffffffffc0200c26:	8b0d                	andi	a4,a4,3
ffffffffc0200c28:	fa871ae3          	bne	a4,s0,ffffffffc0200bdc <exception_handler+0x4a>
}
ffffffffc0200c2c:	60e2                	ld	ra,24(sp)
ffffffffc0200c2e:	6442                	ld	s0,16(sp)
                    tf->epc += 4;  // 标准指令长度32位
ffffffffc0200c30:	0791                	addi	a5,a5,4
ffffffffc0200c32:	10f4b423          	sd	a5,264(s1)
}
ffffffffc0200c36:	6902                	ld	s2,0(sp)
ffffffffc0200c38:	64a2                	ld	s1,8(sp)
ffffffffc0200c3a:	6105                	addi	sp,sp,32
ffffffffc0200c3c:	8082                	ret

ffffffffc0200c3e <trap>:

static inline void trap_dispatch(struct trapframe *tf) {
    // 把 tf->cause 当作有符号数，检查最高位（硬件设为 1 表示“中断”）来区分中断与异常
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200c3e:	11853783          	ld	a5,280(a0)
ffffffffc0200c42:	0007c363          	bltz	a5,ffffffffc0200c48 <trap+0xa>
        // interrupts
        interrupt_handler(tf);  // 中断
    } else {
        // exceptions
        exception_handler(tf);  // 异常
ffffffffc0200c46:	b7b1                	j	ffffffffc0200b92 <exception_handler>
        interrupt_handler(tf);  // 中断
ffffffffc0200c48:	b569                	j	ffffffffc0200ad2 <interrupt_handler>
	...

ffffffffc0200c4c <__alltraps>:
    .endm

    .globl __alltraps
    .align(2)
__alltraps:
    SAVE_ALL
ffffffffc0200c4c:	14011073          	csrw	sscratch,sp
ffffffffc0200c50:	712d                	addi	sp,sp,-288
ffffffffc0200c52:	e002                	sd	zero,0(sp)
ffffffffc0200c54:	e406                	sd	ra,8(sp)
ffffffffc0200c56:	ec0e                	sd	gp,24(sp)
ffffffffc0200c58:	f012                	sd	tp,32(sp)
ffffffffc0200c5a:	f416                	sd	t0,40(sp)
ffffffffc0200c5c:	f81a                	sd	t1,48(sp)
ffffffffc0200c5e:	fc1e                	sd	t2,56(sp)
ffffffffc0200c60:	e0a2                	sd	s0,64(sp)
ffffffffc0200c62:	e4a6                	sd	s1,72(sp)
ffffffffc0200c64:	e8aa                	sd	a0,80(sp)
ffffffffc0200c66:	ecae                	sd	a1,88(sp)
ffffffffc0200c68:	f0b2                	sd	a2,96(sp)
ffffffffc0200c6a:	f4b6                	sd	a3,104(sp)
ffffffffc0200c6c:	f8ba                	sd	a4,112(sp)
ffffffffc0200c6e:	fcbe                	sd	a5,120(sp)
ffffffffc0200c70:	e142                	sd	a6,128(sp)
ffffffffc0200c72:	e546                	sd	a7,136(sp)
ffffffffc0200c74:	e94a                	sd	s2,144(sp)
ffffffffc0200c76:	ed4e                	sd	s3,152(sp)
ffffffffc0200c78:	f152                	sd	s4,160(sp)
ffffffffc0200c7a:	f556                	sd	s5,168(sp)
ffffffffc0200c7c:	f95a                	sd	s6,176(sp)
ffffffffc0200c7e:	fd5e                	sd	s7,184(sp)
ffffffffc0200c80:	e1e2                	sd	s8,192(sp)
ffffffffc0200c82:	e5e6                	sd	s9,200(sp)
ffffffffc0200c84:	e9ea                	sd	s10,208(sp)
ffffffffc0200c86:	edee                	sd	s11,216(sp)
ffffffffc0200c88:	f1f2                	sd	t3,224(sp)
ffffffffc0200c8a:	f5f6                	sd	t4,232(sp)
ffffffffc0200c8c:	f9fa                	sd	t5,240(sp)
ffffffffc0200c8e:	fdfe                	sd	t6,248(sp)
ffffffffc0200c90:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200c94:	100024f3          	csrr	s1,sstatus
ffffffffc0200c98:	14102973          	csrr	s2,sepc
ffffffffc0200c9c:	143029f3          	csrr	s3,stval
ffffffffc0200ca0:	14202a73          	csrr	s4,scause
ffffffffc0200ca4:	e822                	sd	s0,16(sp)
ffffffffc0200ca6:	e226                	sd	s1,256(sp)
ffffffffc0200ca8:	e64a                	sd	s2,264(sp)
ffffffffc0200caa:	ea4e                	sd	s3,272(sp)
ffffffffc0200cac:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200cae:	850a                	mv	a0,sp
    jal trap
ffffffffc0200cb0:	f8fff0ef          	jal	ra,ffffffffc0200c3e <trap>

ffffffffc0200cb4 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200cb4:	6492                	ld	s1,256(sp)
ffffffffc0200cb6:	6932                	ld	s2,264(sp)
ffffffffc0200cb8:	10049073          	csrw	sstatus,s1
ffffffffc0200cbc:	14191073          	csrw	sepc,s2
ffffffffc0200cc0:	60a2                	ld	ra,8(sp)
ffffffffc0200cc2:	61e2                	ld	gp,24(sp)
ffffffffc0200cc4:	7202                	ld	tp,32(sp)
ffffffffc0200cc6:	72a2                	ld	t0,40(sp)
ffffffffc0200cc8:	7342                	ld	t1,48(sp)
ffffffffc0200cca:	73e2                	ld	t2,56(sp)
ffffffffc0200ccc:	6406                	ld	s0,64(sp)
ffffffffc0200cce:	64a6                	ld	s1,72(sp)
ffffffffc0200cd0:	6546                	ld	a0,80(sp)
ffffffffc0200cd2:	65e6                	ld	a1,88(sp)
ffffffffc0200cd4:	7606                	ld	a2,96(sp)
ffffffffc0200cd6:	76a6                	ld	a3,104(sp)
ffffffffc0200cd8:	7746                	ld	a4,112(sp)
ffffffffc0200cda:	77e6                	ld	a5,120(sp)
ffffffffc0200cdc:	680a                	ld	a6,128(sp)
ffffffffc0200cde:	68aa                	ld	a7,136(sp)
ffffffffc0200ce0:	694a                	ld	s2,144(sp)
ffffffffc0200ce2:	69ea                	ld	s3,152(sp)
ffffffffc0200ce4:	7a0a                	ld	s4,160(sp)
ffffffffc0200ce6:	7aaa                	ld	s5,168(sp)
ffffffffc0200ce8:	7b4a                	ld	s6,176(sp)
ffffffffc0200cea:	7bea                	ld	s7,184(sp)
ffffffffc0200cec:	6c0e                	ld	s8,192(sp)
ffffffffc0200cee:	6cae                	ld	s9,200(sp)
ffffffffc0200cf0:	6d4e                	ld	s10,208(sp)
ffffffffc0200cf2:	6dee                	ld	s11,216(sp)
ffffffffc0200cf4:	7e0e                	ld	t3,224(sp)
ffffffffc0200cf6:	7eae                	ld	t4,232(sp)
ffffffffc0200cf8:	7f4e                	ld	t5,240(sp)
ffffffffc0200cfa:	7fee                	ld	t6,248(sp)
ffffffffc0200cfc:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200cfe:	10200073          	sret

ffffffffc0200d02 <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200d02:	00006797          	auipc	a5,0x6
ffffffffc0200d06:	32678793          	addi	a5,a5,806 # ffffffffc0207028 <free_area>
ffffffffc0200d0a:	e79c                	sd	a5,8(a5)
ffffffffc0200d0c:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200d0e:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200d12:	8082                	ret

ffffffffc0200d14 <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200d14:	00006517          	auipc	a0,0x6
ffffffffc0200d18:	32456503          	lwu	a0,804(a0) # ffffffffc0207038 <free_area+0x10>
ffffffffc0200d1c:	8082                	ret

ffffffffc0200d1e <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc0200d1e:	715d                	addi	sp,sp,-80
ffffffffc0200d20:	e0a2                	sd	s0,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200d22:	00006417          	auipc	s0,0x6
ffffffffc0200d26:	30640413          	addi	s0,s0,774 # ffffffffc0207028 <free_area>
ffffffffc0200d2a:	641c                	ld	a5,8(s0)
ffffffffc0200d2c:	e486                	sd	ra,72(sp)
ffffffffc0200d2e:	fc26                	sd	s1,56(sp)
ffffffffc0200d30:	f84a                	sd	s2,48(sp)
ffffffffc0200d32:	f44e                	sd	s3,40(sp)
ffffffffc0200d34:	f052                	sd	s4,32(sp)
ffffffffc0200d36:	ec56                	sd	s5,24(sp)
ffffffffc0200d38:	e85a                	sd	s6,16(sp)
ffffffffc0200d3a:	e45e                	sd	s7,8(sp)
ffffffffc0200d3c:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200d3e:	2c878763          	beq	a5,s0,ffffffffc020100c <default_check+0x2ee>
    int count = 0, total = 0;
ffffffffc0200d42:	4481                	li	s1,0
ffffffffc0200d44:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200d46:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200d4a:	8b09                	andi	a4,a4,2
ffffffffc0200d4c:	2c070463          	beqz	a4,ffffffffc0201014 <default_check+0x2f6>
        count ++, total += p->property;
ffffffffc0200d50:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200d54:	679c                	ld	a5,8(a5)
ffffffffc0200d56:	2905                	addiw	s2,s2,1
ffffffffc0200d58:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200d5a:	fe8796e3          	bne	a5,s0,ffffffffc0200d46 <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0200d5e:	89a6                	mv	s3,s1
ffffffffc0200d60:	2f9000ef          	jal	ra,ffffffffc0201858 <nr_free_pages>
ffffffffc0200d64:	71351863          	bne	a0,s3,ffffffffc0201474 <default_check+0x756>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200d68:	4505                	li	a0,1
ffffffffc0200d6a:	271000ef          	jal	ra,ffffffffc02017da <alloc_pages>
ffffffffc0200d6e:	8a2a                	mv	s4,a0
ffffffffc0200d70:	44050263          	beqz	a0,ffffffffc02011b4 <default_check+0x496>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200d74:	4505                	li	a0,1
ffffffffc0200d76:	265000ef          	jal	ra,ffffffffc02017da <alloc_pages>
ffffffffc0200d7a:	89aa                	mv	s3,a0
ffffffffc0200d7c:	70050c63          	beqz	a0,ffffffffc0201494 <default_check+0x776>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200d80:	4505                	li	a0,1
ffffffffc0200d82:	259000ef          	jal	ra,ffffffffc02017da <alloc_pages>
ffffffffc0200d86:	8aaa                	mv	s5,a0
ffffffffc0200d88:	4a050663          	beqz	a0,ffffffffc0201234 <default_check+0x516>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200d8c:	2b3a0463          	beq	s4,s3,ffffffffc0201034 <default_check+0x316>
ffffffffc0200d90:	2aaa0263          	beq	s4,a0,ffffffffc0201034 <default_check+0x316>
ffffffffc0200d94:	2aa98063          	beq	s3,a0,ffffffffc0201034 <default_check+0x316>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200d98:	000a2783          	lw	a5,0(s4)
ffffffffc0200d9c:	2a079c63          	bnez	a5,ffffffffc0201054 <default_check+0x336>
ffffffffc0200da0:	0009a783          	lw	a5,0(s3)
ffffffffc0200da4:	2a079863          	bnez	a5,ffffffffc0201054 <default_check+0x336>
ffffffffc0200da8:	411c                	lw	a5,0(a0)
ffffffffc0200daa:	2a079563          	bnez	a5,ffffffffc0201054 <default_check+0x336>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200dae:	00006797          	auipc	a5,0x6
ffffffffc0200db2:	6c27b783          	ld	a5,1730(a5) # ffffffffc0207470 <pages>
ffffffffc0200db6:	40fa0733          	sub	a4,s4,a5
ffffffffc0200dba:	870d                	srai	a4,a4,0x3
ffffffffc0200dbc:	00002597          	auipc	a1,0x2
ffffffffc0200dc0:	3ac5b583          	ld	a1,940(a1) # ffffffffc0203168 <error_string+0x38>
ffffffffc0200dc4:	02b70733          	mul	a4,a4,a1
ffffffffc0200dc8:	00002617          	auipc	a2,0x2
ffffffffc0200dcc:	3a863603          	ld	a2,936(a2) # ffffffffc0203170 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200dd0:	00006697          	auipc	a3,0x6
ffffffffc0200dd4:	6986b683          	ld	a3,1688(a3) # ffffffffc0207468 <npage>
ffffffffc0200dd8:	06b2                	slli	a3,a3,0xc
ffffffffc0200dda:	9732                	add	a4,a4,a2

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc0200ddc:	0732                	slli	a4,a4,0xc
ffffffffc0200dde:	28d77b63          	bgeu	a4,a3,ffffffffc0201074 <default_check+0x356>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200de2:	40f98733          	sub	a4,s3,a5
ffffffffc0200de6:	870d                	srai	a4,a4,0x3
ffffffffc0200de8:	02b70733          	mul	a4,a4,a1
ffffffffc0200dec:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200dee:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200df0:	4cd77263          	bgeu	a4,a3,ffffffffc02012b4 <default_check+0x596>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200df4:	40f507b3          	sub	a5,a0,a5
ffffffffc0200df8:	878d                	srai	a5,a5,0x3
ffffffffc0200dfa:	02b787b3          	mul	a5,a5,a1
ffffffffc0200dfe:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200e00:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200e02:	30d7f963          	bgeu	a5,a3,ffffffffc0201114 <default_check+0x3f6>
    assert(alloc_page() == NULL);
ffffffffc0200e06:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200e08:	00043c03          	ld	s8,0(s0)
ffffffffc0200e0c:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0200e10:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0200e14:	e400                	sd	s0,8(s0)
ffffffffc0200e16:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0200e18:	00006797          	auipc	a5,0x6
ffffffffc0200e1c:	2207a023          	sw	zero,544(a5) # ffffffffc0207038 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200e20:	1bb000ef          	jal	ra,ffffffffc02017da <alloc_pages>
ffffffffc0200e24:	2c051863          	bnez	a0,ffffffffc02010f4 <default_check+0x3d6>
    free_page(p0);
ffffffffc0200e28:	4585                	li	a1,1
ffffffffc0200e2a:	8552                	mv	a0,s4
ffffffffc0200e2c:	1ed000ef          	jal	ra,ffffffffc0201818 <free_pages>
    free_page(p1);
ffffffffc0200e30:	4585                	li	a1,1
ffffffffc0200e32:	854e                	mv	a0,s3
ffffffffc0200e34:	1e5000ef          	jal	ra,ffffffffc0201818 <free_pages>
    free_page(p2);
ffffffffc0200e38:	4585                	li	a1,1
ffffffffc0200e3a:	8556                	mv	a0,s5
ffffffffc0200e3c:	1dd000ef          	jal	ra,ffffffffc0201818 <free_pages>
    assert(nr_free == 3);
ffffffffc0200e40:	4818                	lw	a4,16(s0)
ffffffffc0200e42:	478d                	li	a5,3
ffffffffc0200e44:	28f71863          	bne	a4,a5,ffffffffc02010d4 <default_check+0x3b6>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200e48:	4505                	li	a0,1
ffffffffc0200e4a:	191000ef          	jal	ra,ffffffffc02017da <alloc_pages>
ffffffffc0200e4e:	89aa                	mv	s3,a0
ffffffffc0200e50:	26050263          	beqz	a0,ffffffffc02010b4 <default_check+0x396>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200e54:	4505                	li	a0,1
ffffffffc0200e56:	185000ef          	jal	ra,ffffffffc02017da <alloc_pages>
ffffffffc0200e5a:	8aaa                	mv	s5,a0
ffffffffc0200e5c:	3a050c63          	beqz	a0,ffffffffc0201214 <default_check+0x4f6>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200e60:	4505                	li	a0,1
ffffffffc0200e62:	179000ef          	jal	ra,ffffffffc02017da <alloc_pages>
ffffffffc0200e66:	8a2a                	mv	s4,a0
ffffffffc0200e68:	38050663          	beqz	a0,ffffffffc02011f4 <default_check+0x4d6>
    assert(alloc_page() == NULL);
ffffffffc0200e6c:	4505                	li	a0,1
ffffffffc0200e6e:	16d000ef          	jal	ra,ffffffffc02017da <alloc_pages>
ffffffffc0200e72:	36051163          	bnez	a0,ffffffffc02011d4 <default_check+0x4b6>
    free_page(p0);
ffffffffc0200e76:	4585                	li	a1,1
ffffffffc0200e78:	854e                	mv	a0,s3
ffffffffc0200e7a:	19f000ef          	jal	ra,ffffffffc0201818 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200e7e:	641c                	ld	a5,8(s0)
ffffffffc0200e80:	20878a63          	beq	a5,s0,ffffffffc0201094 <default_check+0x376>
    assert((p = alloc_page()) == p0);
ffffffffc0200e84:	4505                	li	a0,1
ffffffffc0200e86:	155000ef          	jal	ra,ffffffffc02017da <alloc_pages>
ffffffffc0200e8a:	30a99563          	bne	s3,a0,ffffffffc0201194 <default_check+0x476>
    assert(alloc_page() == NULL);
ffffffffc0200e8e:	4505                	li	a0,1
ffffffffc0200e90:	14b000ef          	jal	ra,ffffffffc02017da <alloc_pages>
ffffffffc0200e94:	2e051063          	bnez	a0,ffffffffc0201174 <default_check+0x456>
    assert(nr_free == 0);
ffffffffc0200e98:	481c                	lw	a5,16(s0)
ffffffffc0200e9a:	2a079d63          	bnez	a5,ffffffffc0201154 <default_check+0x436>
    free_page(p);
ffffffffc0200e9e:	854e                	mv	a0,s3
ffffffffc0200ea0:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200ea2:	01843023          	sd	s8,0(s0)
ffffffffc0200ea6:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0200eaa:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0200eae:	16b000ef          	jal	ra,ffffffffc0201818 <free_pages>
    free_page(p1);
ffffffffc0200eb2:	4585                	li	a1,1
ffffffffc0200eb4:	8556                	mv	a0,s5
ffffffffc0200eb6:	163000ef          	jal	ra,ffffffffc0201818 <free_pages>
    free_page(p2);
ffffffffc0200eba:	4585                	li	a1,1
ffffffffc0200ebc:	8552                	mv	a0,s4
ffffffffc0200ebe:	15b000ef          	jal	ra,ffffffffc0201818 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200ec2:	4515                	li	a0,5
ffffffffc0200ec4:	117000ef          	jal	ra,ffffffffc02017da <alloc_pages>
ffffffffc0200ec8:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200eca:	26050563          	beqz	a0,ffffffffc0201134 <default_check+0x416>
ffffffffc0200ece:	651c                	ld	a5,8(a0)
ffffffffc0200ed0:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0200ed2:	8b85                	andi	a5,a5,1
ffffffffc0200ed4:	54079063          	bnez	a5,ffffffffc0201414 <default_check+0x6f6>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200ed8:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200eda:	00043b03          	ld	s6,0(s0)
ffffffffc0200ede:	00843a83          	ld	s5,8(s0)
ffffffffc0200ee2:	e000                	sd	s0,0(s0)
ffffffffc0200ee4:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0200ee6:	0f5000ef          	jal	ra,ffffffffc02017da <alloc_pages>
ffffffffc0200eea:	50051563          	bnez	a0,ffffffffc02013f4 <default_check+0x6d6>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0200eee:	05098a13          	addi	s4,s3,80
ffffffffc0200ef2:	8552                	mv	a0,s4
ffffffffc0200ef4:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0200ef6:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc0200efa:	00006797          	auipc	a5,0x6
ffffffffc0200efe:	1207af23          	sw	zero,318(a5) # ffffffffc0207038 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc0200f02:	117000ef          	jal	ra,ffffffffc0201818 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200f06:	4511                	li	a0,4
ffffffffc0200f08:	0d3000ef          	jal	ra,ffffffffc02017da <alloc_pages>
ffffffffc0200f0c:	4c051463          	bnez	a0,ffffffffc02013d4 <default_check+0x6b6>
ffffffffc0200f10:	0589b783          	ld	a5,88(s3)
ffffffffc0200f14:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0200f16:	8b85                	andi	a5,a5,1
ffffffffc0200f18:	48078e63          	beqz	a5,ffffffffc02013b4 <default_check+0x696>
ffffffffc0200f1c:	0609a703          	lw	a4,96(s3)
ffffffffc0200f20:	478d                	li	a5,3
ffffffffc0200f22:	48f71963          	bne	a4,a5,ffffffffc02013b4 <default_check+0x696>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0200f26:	450d                	li	a0,3
ffffffffc0200f28:	0b3000ef          	jal	ra,ffffffffc02017da <alloc_pages>
ffffffffc0200f2c:	8c2a                	mv	s8,a0
ffffffffc0200f2e:	46050363          	beqz	a0,ffffffffc0201394 <default_check+0x676>
    assert(alloc_page() == NULL);
ffffffffc0200f32:	4505                	li	a0,1
ffffffffc0200f34:	0a7000ef          	jal	ra,ffffffffc02017da <alloc_pages>
ffffffffc0200f38:	42051e63          	bnez	a0,ffffffffc0201374 <default_check+0x656>
    assert(p0 + 2 == p1);
ffffffffc0200f3c:	418a1c63          	bne	s4,s8,ffffffffc0201354 <default_check+0x636>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0200f40:	4585                	li	a1,1
ffffffffc0200f42:	854e                	mv	a0,s3
ffffffffc0200f44:	0d5000ef          	jal	ra,ffffffffc0201818 <free_pages>
    free_pages(p1, 3);
ffffffffc0200f48:	458d                	li	a1,3
ffffffffc0200f4a:	8552                	mv	a0,s4
ffffffffc0200f4c:	0cd000ef          	jal	ra,ffffffffc0201818 <free_pages>
ffffffffc0200f50:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc0200f54:	02898c13          	addi	s8,s3,40
ffffffffc0200f58:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0200f5a:	8b85                	andi	a5,a5,1
ffffffffc0200f5c:	3c078c63          	beqz	a5,ffffffffc0201334 <default_check+0x616>
ffffffffc0200f60:	0109a703          	lw	a4,16(s3)
ffffffffc0200f64:	4785                	li	a5,1
ffffffffc0200f66:	3cf71763          	bne	a4,a5,ffffffffc0201334 <default_check+0x616>
ffffffffc0200f6a:	008a3783          	ld	a5,8(s4)
ffffffffc0200f6e:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0200f70:	8b85                	andi	a5,a5,1
ffffffffc0200f72:	3a078163          	beqz	a5,ffffffffc0201314 <default_check+0x5f6>
ffffffffc0200f76:	010a2703          	lw	a4,16(s4)
ffffffffc0200f7a:	478d                	li	a5,3
ffffffffc0200f7c:	38f71c63          	bne	a4,a5,ffffffffc0201314 <default_check+0x5f6>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0200f80:	4505                	li	a0,1
ffffffffc0200f82:	059000ef          	jal	ra,ffffffffc02017da <alloc_pages>
ffffffffc0200f86:	36a99763          	bne	s3,a0,ffffffffc02012f4 <default_check+0x5d6>
    free_page(p0);
ffffffffc0200f8a:	4585                	li	a1,1
ffffffffc0200f8c:	08d000ef          	jal	ra,ffffffffc0201818 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0200f90:	4509                	li	a0,2
ffffffffc0200f92:	049000ef          	jal	ra,ffffffffc02017da <alloc_pages>
ffffffffc0200f96:	32aa1f63          	bne	s4,a0,ffffffffc02012d4 <default_check+0x5b6>

    free_pages(p0, 2);
ffffffffc0200f9a:	4589                	li	a1,2
ffffffffc0200f9c:	07d000ef          	jal	ra,ffffffffc0201818 <free_pages>
    free_page(p2);
ffffffffc0200fa0:	4585                	li	a1,1
ffffffffc0200fa2:	8562                	mv	a0,s8
ffffffffc0200fa4:	075000ef          	jal	ra,ffffffffc0201818 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200fa8:	4515                	li	a0,5
ffffffffc0200faa:	031000ef          	jal	ra,ffffffffc02017da <alloc_pages>
ffffffffc0200fae:	89aa                	mv	s3,a0
ffffffffc0200fb0:	48050263          	beqz	a0,ffffffffc0201434 <default_check+0x716>
    assert(alloc_page() == NULL);
ffffffffc0200fb4:	4505                	li	a0,1
ffffffffc0200fb6:	025000ef          	jal	ra,ffffffffc02017da <alloc_pages>
ffffffffc0200fba:	2c051d63          	bnez	a0,ffffffffc0201294 <default_check+0x576>

    assert(nr_free == 0);
ffffffffc0200fbe:	481c                	lw	a5,16(s0)
ffffffffc0200fc0:	2a079a63          	bnez	a5,ffffffffc0201274 <default_check+0x556>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0200fc4:	4595                	li	a1,5
ffffffffc0200fc6:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0200fc8:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc0200fcc:	01643023          	sd	s6,0(s0)
ffffffffc0200fd0:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc0200fd4:	045000ef          	jal	ra,ffffffffc0201818 <free_pages>
    return listelm->next;
ffffffffc0200fd8:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200fda:	00878963          	beq	a5,s0,ffffffffc0200fec <default_check+0x2ce>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0200fde:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200fe2:	679c                	ld	a5,8(a5)
ffffffffc0200fe4:	397d                	addiw	s2,s2,-1
ffffffffc0200fe6:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200fe8:	fe879be3          	bne	a5,s0,ffffffffc0200fde <default_check+0x2c0>
    }
    assert(count == 0);
ffffffffc0200fec:	26091463          	bnez	s2,ffffffffc0201254 <default_check+0x536>
    assert(total == 0);
ffffffffc0200ff0:	46049263          	bnez	s1,ffffffffc0201454 <default_check+0x736>
}
ffffffffc0200ff4:	60a6                	ld	ra,72(sp)
ffffffffc0200ff6:	6406                	ld	s0,64(sp)
ffffffffc0200ff8:	74e2                	ld	s1,56(sp)
ffffffffc0200ffa:	7942                	ld	s2,48(sp)
ffffffffc0200ffc:	79a2                	ld	s3,40(sp)
ffffffffc0200ffe:	7a02                	ld	s4,32(sp)
ffffffffc0201000:	6ae2                	ld	s5,24(sp)
ffffffffc0201002:	6b42                	ld	s6,16(sp)
ffffffffc0201004:	6ba2                	ld	s7,8(sp)
ffffffffc0201006:	6c02                	ld	s8,0(sp)
ffffffffc0201008:	6161                	addi	sp,sp,80
ffffffffc020100a:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc020100c:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc020100e:	4481                	li	s1,0
ffffffffc0201010:	4901                	li	s2,0
ffffffffc0201012:	b3b9                	j	ffffffffc0200d60 <default_check+0x42>
        assert(PageProperty(p));
ffffffffc0201014:	00002697          	auipc	a3,0x2
ffffffffc0201018:	9cc68693          	addi	a3,a3,-1588 # ffffffffc02029e0 <commands+0x6d8>
ffffffffc020101c:	00002617          	auipc	a2,0x2
ffffffffc0201020:	9d460613          	addi	a2,a2,-1580 # ffffffffc02029f0 <commands+0x6e8>
ffffffffc0201024:	0f000593          	li	a1,240
ffffffffc0201028:	00002517          	auipc	a0,0x2
ffffffffc020102c:	9e050513          	addi	a0,a0,-1568 # ffffffffc0202a08 <commands+0x700>
ffffffffc0201030:	bf8ff0ef          	jal	ra,ffffffffc0200428 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0201034:	00002697          	auipc	a3,0x2
ffffffffc0201038:	a6c68693          	addi	a3,a3,-1428 # ffffffffc0202aa0 <commands+0x798>
ffffffffc020103c:	00002617          	auipc	a2,0x2
ffffffffc0201040:	9b460613          	addi	a2,a2,-1612 # ffffffffc02029f0 <commands+0x6e8>
ffffffffc0201044:	0bd00593          	li	a1,189
ffffffffc0201048:	00002517          	auipc	a0,0x2
ffffffffc020104c:	9c050513          	addi	a0,a0,-1600 # ffffffffc0202a08 <commands+0x700>
ffffffffc0201050:	bd8ff0ef          	jal	ra,ffffffffc0200428 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0201054:	00002697          	auipc	a3,0x2
ffffffffc0201058:	a7468693          	addi	a3,a3,-1420 # ffffffffc0202ac8 <commands+0x7c0>
ffffffffc020105c:	00002617          	auipc	a2,0x2
ffffffffc0201060:	99460613          	addi	a2,a2,-1644 # ffffffffc02029f0 <commands+0x6e8>
ffffffffc0201064:	0be00593          	li	a1,190
ffffffffc0201068:	00002517          	auipc	a0,0x2
ffffffffc020106c:	9a050513          	addi	a0,a0,-1632 # ffffffffc0202a08 <commands+0x700>
ffffffffc0201070:	bb8ff0ef          	jal	ra,ffffffffc0200428 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0201074:	00002697          	auipc	a3,0x2
ffffffffc0201078:	a9468693          	addi	a3,a3,-1388 # ffffffffc0202b08 <commands+0x800>
ffffffffc020107c:	00002617          	auipc	a2,0x2
ffffffffc0201080:	97460613          	addi	a2,a2,-1676 # ffffffffc02029f0 <commands+0x6e8>
ffffffffc0201084:	0c000593          	li	a1,192
ffffffffc0201088:	00002517          	auipc	a0,0x2
ffffffffc020108c:	98050513          	addi	a0,a0,-1664 # ffffffffc0202a08 <commands+0x700>
ffffffffc0201090:	b98ff0ef          	jal	ra,ffffffffc0200428 <__panic>
    assert(!list_empty(&free_list));
ffffffffc0201094:	00002697          	auipc	a3,0x2
ffffffffc0201098:	afc68693          	addi	a3,a3,-1284 # ffffffffc0202b90 <commands+0x888>
ffffffffc020109c:	00002617          	auipc	a2,0x2
ffffffffc02010a0:	95460613          	addi	a2,a2,-1708 # ffffffffc02029f0 <commands+0x6e8>
ffffffffc02010a4:	0d900593          	li	a1,217
ffffffffc02010a8:	00002517          	auipc	a0,0x2
ffffffffc02010ac:	96050513          	addi	a0,a0,-1696 # ffffffffc0202a08 <commands+0x700>
ffffffffc02010b0:	b78ff0ef          	jal	ra,ffffffffc0200428 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02010b4:	00002697          	auipc	a3,0x2
ffffffffc02010b8:	98c68693          	addi	a3,a3,-1652 # ffffffffc0202a40 <commands+0x738>
ffffffffc02010bc:	00002617          	auipc	a2,0x2
ffffffffc02010c0:	93460613          	addi	a2,a2,-1740 # ffffffffc02029f0 <commands+0x6e8>
ffffffffc02010c4:	0d200593          	li	a1,210
ffffffffc02010c8:	00002517          	auipc	a0,0x2
ffffffffc02010cc:	94050513          	addi	a0,a0,-1728 # ffffffffc0202a08 <commands+0x700>
ffffffffc02010d0:	b58ff0ef          	jal	ra,ffffffffc0200428 <__panic>
    assert(nr_free == 3);
ffffffffc02010d4:	00002697          	auipc	a3,0x2
ffffffffc02010d8:	aac68693          	addi	a3,a3,-1364 # ffffffffc0202b80 <commands+0x878>
ffffffffc02010dc:	00002617          	auipc	a2,0x2
ffffffffc02010e0:	91460613          	addi	a2,a2,-1772 # ffffffffc02029f0 <commands+0x6e8>
ffffffffc02010e4:	0d000593          	li	a1,208
ffffffffc02010e8:	00002517          	auipc	a0,0x2
ffffffffc02010ec:	92050513          	addi	a0,a0,-1760 # ffffffffc0202a08 <commands+0x700>
ffffffffc02010f0:	b38ff0ef          	jal	ra,ffffffffc0200428 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02010f4:	00002697          	auipc	a3,0x2
ffffffffc02010f8:	a7468693          	addi	a3,a3,-1420 # ffffffffc0202b68 <commands+0x860>
ffffffffc02010fc:	00002617          	auipc	a2,0x2
ffffffffc0201100:	8f460613          	addi	a2,a2,-1804 # ffffffffc02029f0 <commands+0x6e8>
ffffffffc0201104:	0cb00593          	li	a1,203
ffffffffc0201108:	00002517          	auipc	a0,0x2
ffffffffc020110c:	90050513          	addi	a0,a0,-1792 # ffffffffc0202a08 <commands+0x700>
ffffffffc0201110:	b18ff0ef          	jal	ra,ffffffffc0200428 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0201114:	00002697          	auipc	a3,0x2
ffffffffc0201118:	a3468693          	addi	a3,a3,-1484 # ffffffffc0202b48 <commands+0x840>
ffffffffc020111c:	00002617          	auipc	a2,0x2
ffffffffc0201120:	8d460613          	addi	a2,a2,-1836 # ffffffffc02029f0 <commands+0x6e8>
ffffffffc0201124:	0c200593          	li	a1,194
ffffffffc0201128:	00002517          	auipc	a0,0x2
ffffffffc020112c:	8e050513          	addi	a0,a0,-1824 # ffffffffc0202a08 <commands+0x700>
ffffffffc0201130:	af8ff0ef          	jal	ra,ffffffffc0200428 <__panic>
    assert(p0 != NULL);
ffffffffc0201134:	00002697          	auipc	a3,0x2
ffffffffc0201138:	aa468693          	addi	a3,a3,-1372 # ffffffffc0202bd8 <commands+0x8d0>
ffffffffc020113c:	00002617          	auipc	a2,0x2
ffffffffc0201140:	8b460613          	addi	a2,a2,-1868 # ffffffffc02029f0 <commands+0x6e8>
ffffffffc0201144:	0f800593          	li	a1,248
ffffffffc0201148:	00002517          	auipc	a0,0x2
ffffffffc020114c:	8c050513          	addi	a0,a0,-1856 # ffffffffc0202a08 <commands+0x700>
ffffffffc0201150:	ad8ff0ef          	jal	ra,ffffffffc0200428 <__panic>
    assert(nr_free == 0);
ffffffffc0201154:	00002697          	auipc	a3,0x2
ffffffffc0201158:	a7468693          	addi	a3,a3,-1420 # ffffffffc0202bc8 <commands+0x8c0>
ffffffffc020115c:	00002617          	auipc	a2,0x2
ffffffffc0201160:	89460613          	addi	a2,a2,-1900 # ffffffffc02029f0 <commands+0x6e8>
ffffffffc0201164:	0df00593          	li	a1,223
ffffffffc0201168:	00002517          	auipc	a0,0x2
ffffffffc020116c:	8a050513          	addi	a0,a0,-1888 # ffffffffc0202a08 <commands+0x700>
ffffffffc0201170:	ab8ff0ef          	jal	ra,ffffffffc0200428 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201174:	00002697          	auipc	a3,0x2
ffffffffc0201178:	9f468693          	addi	a3,a3,-1548 # ffffffffc0202b68 <commands+0x860>
ffffffffc020117c:	00002617          	auipc	a2,0x2
ffffffffc0201180:	87460613          	addi	a2,a2,-1932 # ffffffffc02029f0 <commands+0x6e8>
ffffffffc0201184:	0dd00593          	li	a1,221
ffffffffc0201188:	00002517          	auipc	a0,0x2
ffffffffc020118c:	88050513          	addi	a0,a0,-1920 # ffffffffc0202a08 <commands+0x700>
ffffffffc0201190:	a98ff0ef          	jal	ra,ffffffffc0200428 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0201194:	00002697          	auipc	a3,0x2
ffffffffc0201198:	a1468693          	addi	a3,a3,-1516 # ffffffffc0202ba8 <commands+0x8a0>
ffffffffc020119c:	00002617          	auipc	a2,0x2
ffffffffc02011a0:	85460613          	addi	a2,a2,-1964 # ffffffffc02029f0 <commands+0x6e8>
ffffffffc02011a4:	0dc00593          	li	a1,220
ffffffffc02011a8:	00002517          	auipc	a0,0x2
ffffffffc02011ac:	86050513          	addi	a0,a0,-1952 # ffffffffc0202a08 <commands+0x700>
ffffffffc02011b0:	a78ff0ef          	jal	ra,ffffffffc0200428 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02011b4:	00002697          	auipc	a3,0x2
ffffffffc02011b8:	88c68693          	addi	a3,a3,-1908 # ffffffffc0202a40 <commands+0x738>
ffffffffc02011bc:	00002617          	auipc	a2,0x2
ffffffffc02011c0:	83460613          	addi	a2,a2,-1996 # ffffffffc02029f0 <commands+0x6e8>
ffffffffc02011c4:	0b900593          	li	a1,185
ffffffffc02011c8:	00002517          	auipc	a0,0x2
ffffffffc02011cc:	84050513          	addi	a0,a0,-1984 # ffffffffc0202a08 <commands+0x700>
ffffffffc02011d0:	a58ff0ef          	jal	ra,ffffffffc0200428 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02011d4:	00002697          	auipc	a3,0x2
ffffffffc02011d8:	99468693          	addi	a3,a3,-1644 # ffffffffc0202b68 <commands+0x860>
ffffffffc02011dc:	00002617          	auipc	a2,0x2
ffffffffc02011e0:	81460613          	addi	a2,a2,-2028 # ffffffffc02029f0 <commands+0x6e8>
ffffffffc02011e4:	0d600593          	li	a1,214
ffffffffc02011e8:	00002517          	auipc	a0,0x2
ffffffffc02011ec:	82050513          	addi	a0,a0,-2016 # ffffffffc0202a08 <commands+0x700>
ffffffffc02011f0:	a38ff0ef          	jal	ra,ffffffffc0200428 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02011f4:	00002697          	auipc	a3,0x2
ffffffffc02011f8:	88c68693          	addi	a3,a3,-1908 # ffffffffc0202a80 <commands+0x778>
ffffffffc02011fc:	00001617          	auipc	a2,0x1
ffffffffc0201200:	7f460613          	addi	a2,a2,2036 # ffffffffc02029f0 <commands+0x6e8>
ffffffffc0201204:	0d400593          	li	a1,212
ffffffffc0201208:	00002517          	auipc	a0,0x2
ffffffffc020120c:	80050513          	addi	a0,a0,-2048 # ffffffffc0202a08 <commands+0x700>
ffffffffc0201210:	a18ff0ef          	jal	ra,ffffffffc0200428 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201214:	00002697          	auipc	a3,0x2
ffffffffc0201218:	84c68693          	addi	a3,a3,-1972 # ffffffffc0202a60 <commands+0x758>
ffffffffc020121c:	00001617          	auipc	a2,0x1
ffffffffc0201220:	7d460613          	addi	a2,a2,2004 # ffffffffc02029f0 <commands+0x6e8>
ffffffffc0201224:	0d300593          	li	a1,211
ffffffffc0201228:	00001517          	auipc	a0,0x1
ffffffffc020122c:	7e050513          	addi	a0,a0,2016 # ffffffffc0202a08 <commands+0x700>
ffffffffc0201230:	9f8ff0ef          	jal	ra,ffffffffc0200428 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201234:	00002697          	auipc	a3,0x2
ffffffffc0201238:	84c68693          	addi	a3,a3,-1972 # ffffffffc0202a80 <commands+0x778>
ffffffffc020123c:	00001617          	auipc	a2,0x1
ffffffffc0201240:	7b460613          	addi	a2,a2,1972 # ffffffffc02029f0 <commands+0x6e8>
ffffffffc0201244:	0bb00593          	li	a1,187
ffffffffc0201248:	00001517          	auipc	a0,0x1
ffffffffc020124c:	7c050513          	addi	a0,a0,1984 # ffffffffc0202a08 <commands+0x700>
ffffffffc0201250:	9d8ff0ef          	jal	ra,ffffffffc0200428 <__panic>
    assert(count == 0);
ffffffffc0201254:	00002697          	auipc	a3,0x2
ffffffffc0201258:	ad468693          	addi	a3,a3,-1324 # ffffffffc0202d28 <commands+0xa20>
ffffffffc020125c:	00001617          	auipc	a2,0x1
ffffffffc0201260:	79460613          	addi	a2,a2,1940 # ffffffffc02029f0 <commands+0x6e8>
ffffffffc0201264:	12500593          	li	a1,293
ffffffffc0201268:	00001517          	auipc	a0,0x1
ffffffffc020126c:	7a050513          	addi	a0,a0,1952 # ffffffffc0202a08 <commands+0x700>
ffffffffc0201270:	9b8ff0ef          	jal	ra,ffffffffc0200428 <__panic>
    assert(nr_free == 0);
ffffffffc0201274:	00002697          	auipc	a3,0x2
ffffffffc0201278:	95468693          	addi	a3,a3,-1708 # ffffffffc0202bc8 <commands+0x8c0>
ffffffffc020127c:	00001617          	auipc	a2,0x1
ffffffffc0201280:	77460613          	addi	a2,a2,1908 # ffffffffc02029f0 <commands+0x6e8>
ffffffffc0201284:	11a00593          	li	a1,282
ffffffffc0201288:	00001517          	auipc	a0,0x1
ffffffffc020128c:	78050513          	addi	a0,a0,1920 # ffffffffc0202a08 <commands+0x700>
ffffffffc0201290:	998ff0ef          	jal	ra,ffffffffc0200428 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201294:	00002697          	auipc	a3,0x2
ffffffffc0201298:	8d468693          	addi	a3,a3,-1836 # ffffffffc0202b68 <commands+0x860>
ffffffffc020129c:	00001617          	auipc	a2,0x1
ffffffffc02012a0:	75460613          	addi	a2,a2,1876 # ffffffffc02029f0 <commands+0x6e8>
ffffffffc02012a4:	11800593          	li	a1,280
ffffffffc02012a8:	00001517          	auipc	a0,0x1
ffffffffc02012ac:	76050513          	addi	a0,a0,1888 # ffffffffc0202a08 <commands+0x700>
ffffffffc02012b0:	978ff0ef          	jal	ra,ffffffffc0200428 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02012b4:	00002697          	auipc	a3,0x2
ffffffffc02012b8:	87468693          	addi	a3,a3,-1932 # ffffffffc0202b28 <commands+0x820>
ffffffffc02012bc:	00001617          	auipc	a2,0x1
ffffffffc02012c0:	73460613          	addi	a2,a2,1844 # ffffffffc02029f0 <commands+0x6e8>
ffffffffc02012c4:	0c100593          	li	a1,193
ffffffffc02012c8:	00001517          	auipc	a0,0x1
ffffffffc02012cc:	74050513          	addi	a0,a0,1856 # ffffffffc0202a08 <commands+0x700>
ffffffffc02012d0:	958ff0ef          	jal	ra,ffffffffc0200428 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc02012d4:	00002697          	auipc	a3,0x2
ffffffffc02012d8:	a1468693          	addi	a3,a3,-1516 # ffffffffc0202ce8 <commands+0x9e0>
ffffffffc02012dc:	00001617          	auipc	a2,0x1
ffffffffc02012e0:	71460613          	addi	a2,a2,1812 # ffffffffc02029f0 <commands+0x6e8>
ffffffffc02012e4:	11200593          	li	a1,274
ffffffffc02012e8:	00001517          	auipc	a0,0x1
ffffffffc02012ec:	72050513          	addi	a0,a0,1824 # ffffffffc0202a08 <commands+0x700>
ffffffffc02012f0:	938ff0ef          	jal	ra,ffffffffc0200428 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc02012f4:	00002697          	auipc	a3,0x2
ffffffffc02012f8:	9d468693          	addi	a3,a3,-1580 # ffffffffc0202cc8 <commands+0x9c0>
ffffffffc02012fc:	00001617          	auipc	a2,0x1
ffffffffc0201300:	6f460613          	addi	a2,a2,1780 # ffffffffc02029f0 <commands+0x6e8>
ffffffffc0201304:	11000593          	li	a1,272
ffffffffc0201308:	00001517          	auipc	a0,0x1
ffffffffc020130c:	70050513          	addi	a0,a0,1792 # ffffffffc0202a08 <commands+0x700>
ffffffffc0201310:	918ff0ef          	jal	ra,ffffffffc0200428 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0201314:	00002697          	auipc	a3,0x2
ffffffffc0201318:	98c68693          	addi	a3,a3,-1652 # ffffffffc0202ca0 <commands+0x998>
ffffffffc020131c:	00001617          	auipc	a2,0x1
ffffffffc0201320:	6d460613          	addi	a2,a2,1748 # ffffffffc02029f0 <commands+0x6e8>
ffffffffc0201324:	10e00593          	li	a1,270
ffffffffc0201328:	00001517          	auipc	a0,0x1
ffffffffc020132c:	6e050513          	addi	a0,a0,1760 # ffffffffc0202a08 <commands+0x700>
ffffffffc0201330:	8f8ff0ef          	jal	ra,ffffffffc0200428 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0201334:	00002697          	auipc	a3,0x2
ffffffffc0201338:	94468693          	addi	a3,a3,-1724 # ffffffffc0202c78 <commands+0x970>
ffffffffc020133c:	00001617          	auipc	a2,0x1
ffffffffc0201340:	6b460613          	addi	a2,a2,1716 # ffffffffc02029f0 <commands+0x6e8>
ffffffffc0201344:	10d00593          	li	a1,269
ffffffffc0201348:	00001517          	auipc	a0,0x1
ffffffffc020134c:	6c050513          	addi	a0,a0,1728 # ffffffffc0202a08 <commands+0x700>
ffffffffc0201350:	8d8ff0ef          	jal	ra,ffffffffc0200428 <__panic>
    assert(p0 + 2 == p1);
ffffffffc0201354:	00002697          	auipc	a3,0x2
ffffffffc0201358:	91468693          	addi	a3,a3,-1772 # ffffffffc0202c68 <commands+0x960>
ffffffffc020135c:	00001617          	auipc	a2,0x1
ffffffffc0201360:	69460613          	addi	a2,a2,1684 # ffffffffc02029f0 <commands+0x6e8>
ffffffffc0201364:	10800593          	li	a1,264
ffffffffc0201368:	00001517          	auipc	a0,0x1
ffffffffc020136c:	6a050513          	addi	a0,a0,1696 # ffffffffc0202a08 <commands+0x700>
ffffffffc0201370:	8b8ff0ef          	jal	ra,ffffffffc0200428 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201374:	00001697          	auipc	a3,0x1
ffffffffc0201378:	7f468693          	addi	a3,a3,2036 # ffffffffc0202b68 <commands+0x860>
ffffffffc020137c:	00001617          	auipc	a2,0x1
ffffffffc0201380:	67460613          	addi	a2,a2,1652 # ffffffffc02029f0 <commands+0x6e8>
ffffffffc0201384:	10700593          	li	a1,263
ffffffffc0201388:	00001517          	auipc	a0,0x1
ffffffffc020138c:	68050513          	addi	a0,a0,1664 # ffffffffc0202a08 <commands+0x700>
ffffffffc0201390:	898ff0ef          	jal	ra,ffffffffc0200428 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0201394:	00002697          	auipc	a3,0x2
ffffffffc0201398:	8b468693          	addi	a3,a3,-1868 # ffffffffc0202c48 <commands+0x940>
ffffffffc020139c:	00001617          	auipc	a2,0x1
ffffffffc02013a0:	65460613          	addi	a2,a2,1620 # ffffffffc02029f0 <commands+0x6e8>
ffffffffc02013a4:	10600593          	li	a1,262
ffffffffc02013a8:	00001517          	auipc	a0,0x1
ffffffffc02013ac:	66050513          	addi	a0,a0,1632 # ffffffffc0202a08 <commands+0x700>
ffffffffc02013b0:	878ff0ef          	jal	ra,ffffffffc0200428 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc02013b4:	00002697          	auipc	a3,0x2
ffffffffc02013b8:	86468693          	addi	a3,a3,-1948 # ffffffffc0202c18 <commands+0x910>
ffffffffc02013bc:	00001617          	auipc	a2,0x1
ffffffffc02013c0:	63460613          	addi	a2,a2,1588 # ffffffffc02029f0 <commands+0x6e8>
ffffffffc02013c4:	10500593          	li	a1,261
ffffffffc02013c8:	00001517          	auipc	a0,0x1
ffffffffc02013cc:	64050513          	addi	a0,a0,1600 # ffffffffc0202a08 <commands+0x700>
ffffffffc02013d0:	858ff0ef          	jal	ra,ffffffffc0200428 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc02013d4:	00002697          	auipc	a3,0x2
ffffffffc02013d8:	82c68693          	addi	a3,a3,-2004 # ffffffffc0202c00 <commands+0x8f8>
ffffffffc02013dc:	00001617          	auipc	a2,0x1
ffffffffc02013e0:	61460613          	addi	a2,a2,1556 # ffffffffc02029f0 <commands+0x6e8>
ffffffffc02013e4:	10400593          	li	a1,260
ffffffffc02013e8:	00001517          	auipc	a0,0x1
ffffffffc02013ec:	62050513          	addi	a0,a0,1568 # ffffffffc0202a08 <commands+0x700>
ffffffffc02013f0:	838ff0ef          	jal	ra,ffffffffc0200428 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02013f4:	00001697          	auipc	a3,0x1
ffffffffc02013f8:	77468693          	addi	a3,a3,1908 # ffffffffc0202b68 <commands+0x860>
ffffffffc02013fc:	00001617          	auipc	a2,0x1
ffffffffc0201400:	5f460613          	addi	a2,a2,1524 # ffffffffc02029f0 <commands+0x6e8>
ffffffffc0201404:	0fe00593          	li	a1,254
ffffffffc0201408:	00001517          	auipc	a0,0x1
ffffffffc020140c:	60050513          	addi	a0,a0,1536 # ffffffffc0202a08 <commands+0x700>
ffffffffc0201410:	818ff0ef          	jal	ra,ffffffffc0200428 <__panic>
    assert(!PageProperty(p0));
ffffffffc0201414:	00001697          	auipc	a3,0x1
ffffffffc0201418:	7d468693          	addi	a3,a3,2004 # ffffffffc0202be8 <commands+0x8e0>
ffffffffc020141c:	00001617          	auipc	a2,0x1
ffffffffc0201420:	5d460613          	addi	a2,a2,1492 # ffffffffc02029f0 <commands+0x6e8>
ffffffffc0201424:	0f900593          	li	a1,249
ffffffffc0201428:	00001517          	auipc	a0,0x1
ffffffffc020142c:	5e050513          	addi	a0,a0,1504 # ffffffffc0202a08 <commands+0x700>
ffffffffc0201430:	ff9fe0ef          	jal	ra,ffffffffc0200428 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201434:	00002697          	auipc	a3,0x2
ffffffffc0201438:	8d468693          	addi	a3,a3,-1836 # ffffffffc0202d08 <commands+0xa00>
ffffffffc020143c:	00001617          	auipc	a2,0x1
ffffffffc0201440:	5b460613          	addi	a2,a2,1460 # ffffffffc02029f0 <commands+0x6e8>
ffffffffc0201444:	11700593          	li	a1,279
ffffffffc0201448:	00001517          	auipc	a0,0x1
ffffffffc020144c:	5c050513          	addi	a0,a0,1472 # ffffffffc0202a08 <commands+0x700>
ffffffffc0201450:	fd9fe0ef          	jal	ra,ffffffffc0200428 <__panic>
    assert(total == 0);
ffffffffc0201454:	00002697          	auipc	a3,0x2
ffffffffc0201458:	8e468693          	addi	a3,a3,-1820 # ffffffffc0202d38 <commands+0xa30>
ffffffffc020145c:	00001617          	auipc	a2,0x1
ffffffffc0201460:	59460613          	addi	a2,a2,1428 # ffffffffc02029f0 <commands+0x6e8>
ffffffffc0201464:	12600593          	li	a1,294
ffffffffc0201468:	00001517          	auipc	a0,0x1
ffffffffc020146c:	5a050513          	addi	a0,a0,1440 # ffffffffc0202a08 <commands+0x700>
ffffffffc0201470:	fb9fe0ef          	jal	ra,ffffffffc0200428 <__panic>
    assert(total == nr_free_pages());
ffffffffc0201474:	00001697          	auipc	a3,0x1
ffffffffc0201478:	5ac68693          	addi	a3,a3,1452 # ffffffffc0202a20 <commands+0x718>
ffffffffc020147c:	00001617          	auipc	a2,0x1
ffffffffc0201480:	57460613          	addi	a2,a2,1396 # ffffffffc02029f0 <commands+0x6e8>
ffffffffc0201484:	0f300593          	li	a1,243
ffffffffc0201488:	00001517          	auipc	a0,0x1
ffffffffc020148c:	58050513          	addi	a0,a0,1408 # ffffffffc0202a08 <commands+0x700>
ffffffffc0201490:	f99fe0ef          	jal	ra,ffffffffc0200428 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201494:	00001697          	auipc	a3,0x1
ffffffffc0201498:	5cc68693          	addi	a3,a3,1484 # ffffffffc0202a60 <commands+0x758>
ffffffffc020149c:	00001617          	auipc	a2,0x1
ffffffffc02014a0:	55460613          	addi	a2,a2,1364 # ffffffffc02029f0 <commands+0x6e8>
ffffffffc02014a4:	0ba00593          	li	a1,186
ffffffffc02014a8:	00001517          	auipc	a0,0x1
ffffffffc02014ac:	56050513          	addi	a0,a0,1376 # ffffffffc0202a08 <commands+0x700>
ffffffffc02014b0:	f79fe0ef          	jal	ra,ffffffffc0200428 <__panic>

ffffffffc02014b4 <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc02014b4:	1141                	addi	sp,sp,-16
ffffffffc02014b6:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02014b8:	14058a63          	beqz	a1,ffffffffc020160c <default_free_pages+0x158>
    for (; p != base + n; p ++) {
ffffffffc02014bc:	00259693          	slli	a3,a1,0x2
ffffffffc02014c0:	96ae                	add	a3,a3,a1
ffffffffc02014c2:	068e                	slli	a3,a3,0x3
ffffffffc02014c4:	96aa                	add	a3,a3,a0
ffffffffc02014c6:	87aa                	mv	a5,a0
ffffffffc02014c8:	02d50263          	beq	a0,a3,ffffffffc02014ec <default_free_pages+0x38>
ffffffffc02014cc:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02014ce:	8b05                	andi	a4,a4,1
ffffffffc02014d0:	10071e63          	bnez	a4,ffffffffc02015ec <default_free_pages+0x138>
ffffffffc02014d4:	6798                	ld	a4,8(a5)
ffffffffc02014d6:	8b09                	andi	a4,a4,2
ffffffffc02014d8:	10071a63          	bnez	a4,ffffffffc02015ec <default_free_pages+0x138>
        p->flags = 0;
ffffffffc02014dc:	0007b423          	sd	zero,8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc02014e0:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc02014e4:	02878793          	addi	a5,a5,40
ffffffffc02014e8:	fed792e3          	bne	a5,a3,ffffffffc02014cc <default_free_pages+0x18>
    base->property = n;
ffffffffc02014ec:	2581                	sext.w	a1,a1
ffffffffc02014ee:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc02014f0:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02014f4:	4789                	li	a5,2
ffffffffc02014f6:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc02014fa:	00006697          	auipc	a3,0x6
ffffffffc02014fe:	b2e68693          	addi	a3,a3,-1234 # ffffffffc0207028 <free_area>
ffffffffc0201502:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201504:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0201506:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc020150a:	9db9                	addw	a1,a1,a4
ffffffffc020150c:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc020150e:	0ad78863          	beq	a5,a3,ffffffffc02015be <default_free_pages+0x10a>
            struct Page* page = le2page(le, page_link);
ffffffffc0201512:	fe878713          	addi	a4,a5,-24
ffffffffc0201516:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc020151a:	4581                	li	a1,0
            if (base < page) {
ffffffffc020151c:	00e56a63          	bltu	a0,a4,ffffffffc0201530 <default_free_pages+0x7c>
    return listelm->next;
ffffffffc0201520:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0201522:	06d70263          	beq	a4,a3,ffffffffc0201586 <default_free_pages+0xd2>
    for (; p != base + n; p ++) {
ffffffffc0201526:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0201528:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc020152c:	fee57ae3          	bgeu	a0,a4,ffffffffc0201520 <default_free_pages+0x6c>
ffffffffc0201530:	c199                	beqz	a1,ffffffffc0201536 <default_free_pages+0x82>
ffffffffc0201532:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201536:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc0201538:	e390                	sd	a2,0(a5)
ffffffffc020153a:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc020153c:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020153e:	ed18                	sd	a4,24(a0)
    if (le != &free_list) {
ffffffffc0201540:	02d70063          	beq	a4,a3,ffffffffc0201560 <default_free_pages+0xac>
        if (p + p->property == base) {
ffffffffc0201544:	ff872803          	lw	a6,-8(a4)
        p = le2page(le, page_link);
ffffffffc0201548:	fe870593          	addi	a1,a4,-24
        if (p + p->property == base) {
ffffffffc020154c:	02081613          	slli	a2,a6,0x20
ffffffffc0201550:	9201                	srli	a2,a2,0x20
ffffffffc0201552:	00261793          	slli	a5,a2,0x2
ffffffffc0201556:	97b2                	add	a5,a5,a2
ffffffffc0201558:	078e                	slli	a5,a5,0x3
ffffffffc020155a:	97ae                	add	a5,a5,a1
ffffffffc020155c:	02f50f63          	beq	a0,a5,ffffffffc020159a <default_free_pages+0xe6>
    return listelm->next;
ffffffffc0201560:	7118                	ld	a4,32(a0)
    if (le != &free_list) {
ffffffffc0201562:	00d70f63          	beq	a4,a3,ffffffffc0201580 <default_free_pages+0xcc>
        if (base + base->property == p) {
ffffffffc0201566:	490c                	lw	a1,16(a0)
        p = le2page(le, page_link);
ffffffffc0201568:	fe870693          	addi	a3,a4,-24
        if (base + base->property == p) {
ffffffffc020156c:	02059613          	slli	a2,a1,0x20
ffffffffc0201570:	9201                	srli	a2,a2,0x20
ffffffffc0201572:	00261793          	slli	a5,a2,0x2
ffffffffc0201576:	97b2                	add	a5,a5,a2
ffffffffc0201578:	078e                	slli	a5,a5,0x3
ffffffffc020157a:	97aa                	add	a5,a5,a0
ffffffffc020157c:	04f68863          	beq	a3,a5,ffffffffc02015cc <default_free_pages+0x118>
}
ffffffffc0201580:	60a2                	ld	ra,8(sp)
ffffffffc0201582:	0141                	addi	sp,sp,16
ffffffffc0201584:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201586:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201588:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc020158a:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc020158c:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc020158e:	02d70563          	beq	a4,a3,ffffffffc02015b8 <default_free_pages+0x104>
    prev->next = next->prev = elm;
ffffffffc0201592:	8832                	mv	a6,a2
ffffffffc0201594:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc0201596:	87ba                	mv	a5,a4
ffffffffc0201598:	bf41                	j	ffffffffc0201528 <default_free_pages+0x74>
            p->property += base->property;
ffffffffc020159a:	491c                	lw	a5,16(a0)
ffffffffc020159c:	0107883b          	addw	a6,a5,a6
ffffffffc02015a0:	ff072c23          	sw	a6,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02015a4:	57f5                	li	a5,-3
ffffffffc02015a6:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc02015aa:	6d10                	ld	a2,24(a0)
ffffffffc02015ac:	711c                	ld	a5,32(a0)
            base = p;
ffffffffc02015ae:	852e                	mv	a0,a1
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc02015b0:	e61c                	sd	a5,8(a2)
    return listelm->next;
ffffffffc02015b2:	6718                	ld	a4,8(a4)
    next->prev = prev;
ffffffffc02015b4:	e390                	sd	a2,0(a5)
ffffffffc02015b6:	b775                	j	ffffffffc0201562 <default_free_pages+0xae>
ffffffffc02015b8:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list) {
ffffffffc02015ba:	873e                	mv	a4,a5
ffffffffc02015bc:	b761                	j	ffffffffc0201544 <default_free_pages+0x90>
}
ffffffffc02015be:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02015c0:	e390                	sd	a2,0(a5)
ffffffffc02015c2:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02015c4:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02015c6:	ed1c                	sd	a5,24(a0)
ffffffffc02015c8:	0141                	addi	sp,sp,16
ffffffffc02015ca:	8082                	ret
            base->property += p->property;
ffffffffc02015cc:	ff872783          	lw	a5,-8(a4)
ffffffffc02015d0:	ff070693          	addi	a3,a4,-16
ffffffffc02015d4:	9dbd                	addw	a1,a1,a5
ffffffffc02015d6:	c90c                	sw	a1,16(a0)
ffffffffc02015d8:	57f5                	li	a5,-3
ffffffffc02015da:	60f6b02f          	amoand.d	zero,a5,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc02015de:	6314                	ld	a3,0(a4)
ffffffffc02015e0:	671c                	ld	a5,8(a4)
}
ffffffffc02015e2:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc02015e4:	e69c                	sd	a5,8(a3)
    next->prev = prev;
ffffffffc02015e6:	e394                	sd	a3,0(a5)
ffffffffc02015e8:	0141                	addi	sp,sp,16
ffffffffc02015ea:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02015ec:	00001697          	auipc	a3,0x1
ffffffffc02015f0:	76468693          	addi	a3,a3,1892 # ffffffffc0202d50 <commands+0xa48>
ffffffffc02015f4:	00001617          	auipc	a2,0x1
ffffffffc02015f8:	3fc60613          	addi	a2,a2,1020 # ffffffffc02029f0 <commands+0x6e8>
ffffffffc02015fc:	08300593          	li	a1,131
ffffffffc0201600:	00001517          	auipc	a0,0x1
ffffffffc0201604:	40850513          	addi	a0,a0,1032 # ffffffffc0202a08 <commands+0x700>
ffffffffc0201608:	e21fe0ef          	jal	ra,ffffffffc0200428 <__panic>
    assert(n > 0);
ffffffffc020160c:	00001697          	auipc	a3,0x1
ffffffffc0201610:	73c68693          	addi	a3,a3,1852 # ffffffffc0202d48 <commands+0xa40>
ffffffffc0201614:	00001617          	auipc	a2,0x1
ffffffffc0201618:	3dc60613          	addi	a2,a2,988 # ffffffffc02029f0 <commands+0x6e8>
ffffffffc020161c:	08000593          	li	a1,128
ffffffffc0201620:	00001517          	auipc	a0,0x1
ffffffffc0201624:	3e850513          	addi	a0,a0,1000 # ffffffffc0202a08 <commands+0x700>
ffffffffc0201628:	e01fe0ef          	jal	ra,ffffffffc0200428 <__panic>

ffffffffc020162c <default_alloc_pages>:
    assert(n > 0);
ffffffffc020162c:	c959                	beqz	a0,ffffffffc02016c2 <default_alloc_pages+0x96>
    if (n > nr_free) {
ffffffffc020162e:	00006597          	auipc	a1,0x6
ffffffffc0201632:	9fa58593          	addi	a1,a1,-1542 # ffffffffc0207028 <free_area>
ffffffffc0201636:	0105a803          	lw	a6,16(a1)
ffffffffc020163a:	862a                	mv	a2,a0
ffffffffc020163c:	02081793          	slli	a5,a6,0x20
ffffffffc0201640:	9381                	srli	a5,a5,0x20
ffffffffc0201642:	00a7ee63          	bltu	a5,a0,ffffffffc020165e <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc0201646:	87ae                	mv	a5,a1
ffffffffc0201648:	a801                	j	ffffffffc0201658 <default_alloc_pages+0x2c>
        if (p->property >= n) {
ffffffffc020164a:	ff87a703          	lw	a4,-8(a5)
ffffffffc020164e:	02071693          	slli	a3,a4,0x20
ffffffffc0201652:	9281                	srli	a3,a3,0x20
ffffffffc0201654:	00c6f763          	bgeu	a3,a2,ffffffffc0201662 <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc0201658:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc020165a:	feb798e3          	bne	a5,a1,ffffffffc020164a <default_alloc_pages+0x1e>
        return NULL;
ffffffffc020165e:	4501                	li	a0,0
}
ffffffffc0201660:	8082                	ret
    return listelm->prev;
ffffffffc0201662:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201666:	0087b303          	ld	t1,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc020166a:	fe878513          	addi	a0,a5,-24
            p->property = page->property - n;
ffffffffc020166e:	00060e1b          	sext.w	t3,a2
    prev->next = next;
ffffffffc0201672:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc0201676:	01133023          	sd	a7,0(t1)
        if (page->property > n) {
ffffffffc020167a:	02d67b63          	bgeu	a2,a3,ffffffffc02016b0 <default_alloc_pages+0x84>
            struct Page *p = page + n;
ffffffffc020167e:	00261693          	slli	a3,a2,0x2
ffffffffc0201682:	96b2                	add	a3,a3,a2
ffffffffc0201684:	068e                	slli	a3,a3,0x3
ffffffffc0201686:	96aa                	add	a3,a3,a0
            p->property = page->property - n;
ffffffffc0201688:	41c7073b          	subw	a4,a4,t3
ffffffffc020168c:	ca98                	sw	a4,16(a3)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020168e:	00868613          	addi	a2,a3,8
ffffffffc0201692:	4709                	li	a4,2
ffffffffc0201694:	40e6302f          	amoor.d	zero,a4,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc0201698:	0088b703          	ld	a4,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc020169c:	01868613          	addi	a2,a3,24
        nr_free -= n;
ffffffffc02016a0:	0105a803          	lw	a6,16(a1)
    prev->next = next->prev = elm;
ffffffffc02016a4:	e310                	sd	a2,0(a4)
ffffffffc02016a6:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc02016aa:	f298                	sd	a4,32(a3)
    elm->prev = prev;
ffffffffc02016ac:	0116bc23          	sd	a7,24(a3)
ffffffffc02016b0:	41c8083b          	subw	a6,a6,t3
ffffffffc02016b4:	0105a823          	sw	a6,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02016b8:	5775                	li	a4,-3
ffffffffc02016ba:	17c1                	addi	a5,a5,-16
ffffffffc02016bc:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc02016c0:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc02016c2:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc02016c4:	00001697          	auipc	a3,0x1
ffffffffc02016c8:	68468693          	addi	a3,a3,1668 # ffffffffc0202d48 <commands+0xa40>
ffffffffc02016cc:	00001617          	auipc	a2,0x1
ffffffffc02016d0:	32460613          	addi	a2,a2,804 # ffffffffc02029f0 <commands+0x6e8>
ffffffffc02016d4:	06200593          	li	a1,98
ffffffffc02016d8:	00001517          	auipc	a0,0x1
ffffffffc02016dc:	33050513          	addi	a0,a0,816 # ffffffffc0202a08 <commands+0x700>
default_alloc_pages(size_t n) {
ffffffffc02016e0:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02016e2:	d47fe0ef          	jal	ra,ffffffffc0200428 <__panic>

ffffffffc02016e6 <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc02016e6:	1141                	addi	sp,sp,-16
ffffffffc02016e8:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02016ea:	c9e1                	beqz	a1,ffffffffc02017ba <default_init_memmap+0xd4>
    for (; p != base + n; p ++) {
ffffffffc02016ec:	00259693          	slli	a3,a1,0x2
ffffffffc02016f0:	96ae                	add	a3,a3,a1
ffffffffc02016f2:	068e                	slli	a3,a3,0x3
ffffffffc02016f4:	96aa                	add	a3,a3,a0
ffffffffc02016f6:	87aa                	mv	a5,a0
ffffffffc02016f8:	00d50f63          	beq	a0,a3,ffffffffc0201716 <default_init_memmap+0x30>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02016fc:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc02016fe:	8b05                	andi	a4,a4,1
ffffffffc0201700:	cf49                	beqz	a4,ffffffffc020179a <default_init_memmap+0xb4>
        p->flags = p->property = 0;
ffffffffc0201702:	0007a823          	sw	zero,16(a5)
ffffffffc0201706:	0007b423          	sd	zero,8(a5)
ffffffffc020170a:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc020170e:	02878793          	addi	a5,a5,40
ffffffffc0201712:	fed795e3          	bne	a5,a3,ffffffffc02016fc <default_init_memmap+0x16>
    base->property = n;
ffffffffc0201716:	2581                	sext.w	a1,a1
ffffffffc0201718:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020171a:	4789                	li	a5,2
ffffffffc020171c:	00850713          	addi	a4,a0,8
ffffffffc0201720:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0201724:	00006697          	auipc	a3,0x6
ffffffffc0201728:	90468693          	addi	a3,a3,-1788 # ffffffffc0207028 <free_area>
ffffffffc020172c:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc020172e:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0201730:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc0201734:	9db9                	addw	a1,a1,a4
ffffffffc0201736:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0201738:	04d78a63          	beq	a5,a3,ffffffffc020178c <default_init_memmap+0xa6>
            struct Page* page = le2page(le, page_link);
ffffffffc020173c:	fe878713          	addi	a4,a5,-24
ffffffffc0201740:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0201744:	4581                	li	a1,0
            if (base < page) {
ffffffffc0201746:	00e56a63          	bltu	a0,a4,ffffffffc020175a <default_init_memmap+0x74>
    return listelm->next;
ffffffffc020174a:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc020174c:	02d70263          	beq	a4,a3,ffffffffc0201770 <default_init_memmap+0x8a>
    for (; p != base + n; p ++) {
ffffffffc0201750:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0201752:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0201756:	fee57ae3          	bgeu	a0,a4,ffffffffc020174a <default_init_memmap+0x64>
ffffffffc020175a:	c199                	beqz	a1,ffffffffc0201760 <default_init_memmap+0x7a>
ffffffffc020175c:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201760:	6398                	ld	a4,0(a5)
}
ffffffffc0201762:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201764:	e390                	sd	a2,0(a5)
ffffffffc0201766:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201768:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020176a:	ed18                	sd	a4,24(a0)
ffffffffc020176c:	0141                	addi	sp,sp,16
ffffffffc020176e:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201770:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201772:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201774:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201776:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201778:	00d70663          	beq	a4,a3,ffffffffc0201784 <default_init_memmap+0x9e>
    prev->next = next->prev = elm;
ffffffffc020177c:	8832                	mv	a6,a2
ffffffffc020177e:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc0201780:	87ba                	mv	a5,a4
ffffffffc0201782:	bfc1                	j	ffffffffc0201752 <default_init_memmap+0x6c>
}
ffffffffc0201784:	60a2                	ld	ra,8(sp)
ffffffffc0201786:	e290                	sd	a2,0(a3)
ffffffffc0201788:	0141                	addi	sp,sp,16
ffffffffc020178a:	8082                	ret
ffffffffc020178c:	60a2                	ld	ra,8(sp)
ffffffffc020178e:	e390                	sd	a2,0(a5)
ffffffffc0201790:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201792:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201794:	ed1c                	sd	a5,24(a0)
ffffffffc0201796:	0141                	addi	sp,sp,16
ffffffffc0201798:	8082                	ret
        assert(PageReserved(p));
ffffffffc020179a:	00001697          	auipc	a3,0x1
ffffffffc020179e:	5de68693          	addi	a3,a3,1502 # ffffffffc0202d78 <commands+0xa70>
ffffffffc02017a2:	00001617          	auipc	a2,0x1
ffffffffc02017a6:	24e60613          	addi	a2,a2,590 # ffffffffc02029f0 <commands+0x6e8>
ffffffffc02017aa:	04900593          	li	a1,73
ffffffffc02017ae:	00001517          	auipc	a0,0x1
ffffffffc02017b2:	25a50513          	addi	a0,a0,602 # ffffffffc0202a08 <commands+0x700>
ffffffffc02017b6:	c73fe0ef          	jal	ra,ffffffffc0200428 <__panic>
    assert(n > 0);
ffffffffc02017ba:	00001697          	auipc	a3,0x1
ffffffffc02017be:	58e68693          	addi	a3,a3,1422 # ffffffffc0202d48 <commands+0xa40>
ffffffffc02017c2:	00001617          	auipc	a2,0x1
ffffffffc02017c6:	22e60613          	addi	a2,a2,558 # ffffffffc02029f0 <commands+0x6e8>
ffffffffc02017ca:	04600593          	li	a1,70
ffffffffc02017ce:	00001517          	auipc	a0,0x1
ffffffffc02017d2:	23a50513          	addi	a0,a0,570 # ffffffffc0202a08 <commands+0x700>
ffffffffc02017d6:	c53fe0ef          	jal	ra,ffffffffc0200428 <__panic>

ffffffffc02017da <alloc_pages>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02017da:	100027f3          	csrr	a5,sstatus
ffffffffc02017de:	8b89                	andi	a5,a5,2
ffffffffc02017e0:	e799                	bnez	a5,ffffffffc02017ee <alloc_pages+0x14>
struct Page *alloc_pages(size_t n) {
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc02017e2:	00006797          	auipc	a5,0x6
ffffffffc02017e6:	c967b783          	ld	a5,-874(a5) # ffffffffc0207478 <pmm_manager>
ffffffffc02017ea:	6f9c                	ld	a5,24(a5)
ffffffffc02017ec:	8782                	jr	a5
struct Page *alloc_pages(size_t n) {
ffffffffc02017ee:	1141                	addi	sp,sp,-16
ffffffffc02017f0:	e406                	sd	ra,8(sp)
ffffffffc02017f2:	e022                	sd	s0,0(sp)
ffffffffc02017f4:	842a                	mv	s0,a0
        intr_disable();
ffffffffc02017f6:	894ff0ef          	jal	ra,ffffffffc020088a <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02017fa:	00006797          	auipc	a5,0x6
ffffffffc02017fe:	c7e7b783          	ld	a5,-898(a5) # ffffffffc0207478 <pmm_manager>
ffffffffc0201802:	6f9c                	ld	a5,24(a5)
ffffffffc0201804:	8522                	mv	a0,s0
ffffffffc0201806:	9782                	jalr	a5
ffffffffc0201808:	842a                	mv	s0,a0
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
ffffffffc020180a:	87aff0ef          	jal	ra,ffffffffc0200884 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc020180e:	60a2                	ld	ra,8(sp)
ffffffffc0201810:	8522                	mv	a0,s0
ffffffffc0201812:	6402                	ld	s0,0(sp)
ffffffffc0201814:	0141                	addi	sp,sp,16
ffffffffc0201816:	8082                	ret

ffffffffc0201818 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201818:	100027f3          	csrr	a5,sstatus
ffffffffc020181c:	8b89                	andi	a5,a5,2
ffffffffc020181e:	e799                	bnez	a5,ffffffffc020182c <free_pages+0x14>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201820:	00006797          	auipc	a5,0x6
ffffffffc0201824:	c587b783          	ld	a5,-936(a5) # ffffffffc0207478 <pmm_manager>
ffffffffc0201828:	739c                	ld	a5,32(a5)
ffffffffc020182a:	8782                	jr	a5
void free_pages(struct Page *base, size_t n) {
ffffffffc020182c:	1101                	addi	sp,sp,-32
ffffffffc020182e:	ec06                	sd	ra,24(sp)
ffffffffc0201830:	e822                	sd	s0,16(sp)
ffffffffc0201832:	e426                	sd	s1,8(sp)
ffffffffc0201834:	842a                	mv	s0,a0
ffffffffc0201836:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0201838:	852ff0ef          	jal	ra,ffffffffc020088a <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020183c:	00006797          	auipc	a5,0x6
ffffffffc0201840:	c3c7b783          	ld	a5,-964(a5) # ffffffffc0207478 <pmm_manager>
ffffffffc0201844:	739c                	ld	a5,32(a5)
ffffffffc0201846:	85a6                	mv	a1,s1
ffffffffc0201848:	8522                	mv	a0,s0
ffffffffc020184a:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc020184c:	6442                	ld	s0,16(sp)
ffffffffc020184e:	60e2                	ld	ra,24(sp)
ffffffffc0201850:	64a2                	ld	s1,8(sp)
ffffffffc0201852:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201854:	830ff06f          	j	ffffffffc0200884 <intr_enable>

ffffffffc0201858 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201858:	100027f3          	csrr	a5,sstatus
ffffffffc020185c:	8b89                	andi	a5,a5,2
ffffffffc020185e:	e799                	bnez	a5,ffffffffc020186c <nr_free_pages+0x14>
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201860:	00006797          	auipc	a5,0x6
ffffffffc0201864:	c187b783          	ld	a5,-1000(a5) # ffffffffc0207478 <pmm_manager>
ffffffffc0201868:	779c                	ld	a5,40(a5)
ffffffffc020186a:	8782                	jr	a5
size_t nr_free_pages(void) {
ffffffffc020186c:	1141                	addi	sp,sp,-16
ffffffffc020186e:	e406                	sd	ra,8(sp)
ffffffffc0201870:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0201872:	818ff0ef          	jal	ra,ffffffffc020088a <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201876:	00006797          	auipc	a5,0x6
ffffffffc020187a:	c027b783          	ld	a5,-1022(a5) # ffffffffc0207478 <pmm_manager>
ffffffffc020187e:	779c                	ld	a5,40(a5)
ffffffffc0201880:	9782                	jalr	a5
ffffffffc0201882:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201884:	800ff0ef          	jal	ra,ffffffffc0200884 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201888:	60a2                	ld	ra,8(sp)
ffffffffc020188a:	8522                	mv	a0,s0
ffffffffc020188c:	6402                	ld	s0,0(sp)
ffffffffc020188e:	0141                	addi	sp,sp,16
ffffffffc0201890:	8082                	ret

ffffffffc0201892 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc0201892:	00001797          	auipc	a5,0x1
ffffffffc0201896:	50e78793          	addi	a5,a5,1294 # ffffffffc0202da0 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020189a:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc020189c:	7179                	addi	sp,sp,-48
ffffffffc020189e:	f022                	sd	s0,32(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02018a0:	00001517          	auipc	a0,0x1
ffffffffc02018a4:	53850513          	addi	a0,a0,1336 # ffffffffc0202dd8 <default_pmm_manager+0x38>
    pmm_manager = &default_pmm_manager;
ffffffffc02018a8:	00006417          	auipc	s0,0x6
ffffffffc02018ac:	bd040413          	addi	s0,s0,-1072 # ffffffffc0207478 <pmm_manager>
void pmm_init(void) {
ffffffffc02018b0:	f406                	sd	ra,40(sp)
ffffffffc02018b2:	ec26                	sd	s1,24(sp)
ffffffffc02018b4:	e44e                	sd	s3,8(sp)
ffffffffc02018b6:	e84a                	sd	s2,16(sp)
ffffffffc02018b8:	e052                	sd	s4,0(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc02018ba:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02018bc:	873fe0ef          	jal	ra,ffffffffc020012e <cprintf>
    pmm_manager->init();
ffffffffc02018c0:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02018c2:	00006497          	auipc	s1,0x6
ffffffffc02018c6:	bce48493          	addi	s1,s1,-1074 # ffffffffc0207490 <va_pa_offset>
    pmm_manager->init();
ffffffffc02018ca:	679c                	ld	a5,8(a5)
ffffffffc02018cc:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02018ce:	57f5                	li	a5,-3
ffffffffc02018d0:	07fa                	slli	a5,a5,0x1e
ffffffffc02018d2:	e09c                	sd	a5,0(s1)
    uint64_t mem_begin = get_memory_base();
ffffffffc02018d4:	f9dfe0ef          	jal	ra,ffffffffc0200870 <get_memory_base>
ffffffffc02018d8:	89aa                	mv	s3,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc02018da:	fa1fe0ef          	jal	ra,ffffffffc020087a <get_memory_size>
    if (mem_size == 0) {
ffffffffc02018de:	16050163          	beqz	a0,ffffffffc0201a40 <pmm_init+0x1ae>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc02018e2:	892a                	mv	s2,a0
    cprintf("physcial memory map:\n");
ffffffffc02018e4:	00001517          	auipc	a0,0x1
ffffffffc02018e8:	53c50513          	addi	a0,a0,1340 # ffffffffc0202e20 <default_pmm_manager+0x80>
ffffffffc02018ec:	843fe0ef          	jal	ra,ffffffffc020012e <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc02018f0:	01298a33          	add	s4,s3,s2
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc02018f4:	864e                	mv	a2,s3
ffffffffc02018f6:	fffa0693          	addi	a3,s4,-1
ffffffffc02018fa:	85ca                	mv	a1,s2
ffffffffc02018fc:	00001517          	auipc	a0,0x1
ffffffffc0201900:	53c50513          	addi	a0,a0,1340 # ffffffffc0202e38 <default_pmm_manager+0x98>
ffffffffc0201904:	82bfe0ef          	jal	ra,ffffffffc020012e <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0201908:	c80007b7          	lui	a5,0xc8000
ffffffffc020190c:	8652                	mv	a2,s4
ffffffffc020190e:	0d47e863          	bltu	a5,s4,ffffffffc02019de <pmm_init+0x14c>
ffffffffc0201912:	00007797          	auipc	a5,0x7
ffffffffc0201916:	b8d78793          	addi	a5,a5,-1139 # ffffffffc020849f <end+0xfff>
ffffffffc020191a:	757d                	lui	a0,0xfffff
ffffffffc020191c:	8d7d                	and	a0,a0,a5
ffffffffc020191e:	8231                	srli	a2,a2,0xc
ffffffffc0201920:	00006597          	auipc	a1,0x6
ffffffffc0201924:	b4858593          	addi	a1,a1,-1208 # ffffffffc0207468 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201928:	00006817          	auipc	a6,0x6
ffffffffc020192c:	b4880813          	addi	a6,a6,-1208 # ffffffffc0207470 <pages>
    npage = maxpa / PGSIZE;
ffffffffc0201930:	e190                	sd	a2,0(a1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201932:	00a83023          	sd	a0,0(a6)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201936:	000807b7          	lui	a5,0x80
ffffffffc020193a:	02f60663          	beq	a2,a5,ffffffffc0201966 <pmm_init+0xd4>
ffffffffc020193e:	4701                	li	a4,0
ffffffffc0201940:	4781                	li	a5,0
ffffffffc0201942:	4305                	li	t1,1
ffffffffc0201944:	fff808b7          	lui	a7,0xfff80
        SetPageReserved(pages + i);
ffffffffc0201948:	953a                	add	a0,a0,a4
ffffffffc020194a:	00850693          	addi	a3,a0,8 # fffffffffffff008 <end+0x3fdf7b68>
ffffffffc020194e:	4066b02f          	amoor.d	zero,t1,(a3)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201952:	6190                	ld	a2,0(a1)
ffffffffc0201954:	0785                	addi	a5,a5,1
        SetPageReserved(pages + i);
ffffffffc0201956:	00083503          	ld	a0,0(a6)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc020195a:	011606b3          	add	a3,a2,a7
ffffffffc020195e:	02870713          	addi	a4,a4,40
ffffffffc0201962:	fed7e3e3          	bltu	a5,a3,ffffffffc0201948 <pmm_init+0xb6>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201966:	00261693          	slli	a3,a2,0x2
ffffffffc020196a:	96b2                	add	a3,a3,a2
ffffffffc020196c:	fec007b7          	lui	a5,0xfec00
ffffffffc0201970:	97aa                	add	a5,a5,a0
ffffffffc0201972:	068e                	slli	a3,a3,0x3
ffffffffc0201974:	96be                	add	a3,a3,a5
ffffffffc0201976:	c02007b7          	lui	a5,0xc0200
ffffffffc020197a:	0af6e763          	bltu	a3,a5,ffffffffc0201a28 <pmm_init+0x196>
ffffffffc020197e:	6098                	ld	a4,0(s1)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc0201980:	77fd                	lui	a5,0xfffff
ffffffffc0201982:	00fa75b3          	and	a1,s4,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201986:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc0201988:	04b6ee63          	bltu	a3,a1,ffffffffc02019e4 <pmm_init+0x152>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc020198c:	601c                	ld	a5,0(s0)
ffffffffc020198e:	7b9c                	ld	a5,48(a5)
ffffffffc0201990:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0201992:	00001517          	auipc	a0,0x1
ffffffffc0201996:	52e50513          	addi	a0,a0,1326 # ffffffffc0202ec0 <default_pmm_manager+0x120>
ffffffffc020199a:	f94fe0ef          	jal	ra,ffffffffc020012e <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc020199e:	00004597          	auipc	a1,0x4
ffffffffc02019a2:	66258593          	addi	a1,a1,1634 # ffffffffc0206000 <boot_page_table_sv39>
ffffffffc02019a6:	00006797          	auipc	a5,0x6
ffffffffc02019aa:	aeb7b123          	sd	a1,-1310(a5) # ffffffffc0207488 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc02019ae:	c02007b7          	lui	a5,0xc0200
ffffffffc02019b2:	0af5e363          	bltu	a1,a5,ffffffffc0201a58 <pmm_init+0x1c6>
ffffffffc02019b6:	6090                	ld	a2,0(s1)
}
ffffffffc02019b8:	7402                	ld	s0,32(sp)
ffffffffc02019ba:	70a2                	ld	ra,40(sp)
ffffffffc02019bc:	64e2                	ld	s1,24(sp)
ffffffffc02019be:	6942                	ld	s2,16(sp)
ffffffffc02019c0:	69a2                	ld	s3,8(sp)
ffffffffc02019c2:	6a02                	ld	s4,0(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc02019c4:	40c58633          	sub	a2,a1,a2
ffffffffc02019c8:	00006797          	auipc	a5,0x6
ffffffffc02019cc:	aac7bc23          	sd	a2,-1352(a5) # ffffffffc0207480 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02019d0:	00001517          	auipc	a0,0x1
ffffffffc02019d4:	51050513          	addi	a0,a0,1296 # ffffffffc0202ee0 <default_pmm_manager+0x140>
}
ffffffffc02019d8:	6145                	addi	sp,sp,48
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02019da:	f54fe06f          	j	ffffffffc020012e <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc02019de:	c8000637          	lui	a2,0xc8000
ffffffffc02019e2:	bf05                	j	ffffffffc0201912 <pmm_init+0x80>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc02019e4:	6705                	lui	a4,0x1
ffffffffc02019e6:	177d                	addi	a4,a4,-1
ffffffffc02019e8:	96ba                	add	a3,a3,a4
ffffffffc02019ea:	8efd                	and	a3,a3,a5
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc02019ec:	00c6d793          	srli	a5,a3,0xc
ffffffffc02019f0:	02c7f063          	bgeu	a5,a2,ffffffffc0201a10 <pmm_init+0x17e>
    pmm_manager->init_memmap(base, n);
ffffffffc02019f4:	6010                	ld	a2,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc02019f6:	fff80737          	lui	a4,0xfff80
ffffffffc02019fa:	973e                	add	a4,a4,a5
ffffffffc02019fc:	00271793          	slli	a5,a4,0x2
ffffffffc0201a00:	97ba                	add	a5,a5,a4
ffffffffc0201a02:	6a18                	ld	a4,16(a2)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0201a04:	8d95                	sub	a1,a1,a3
ffffffffc0201a06:	078e                	slli	a5,a5,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc0201a08:	81b1                	srli	a1,a1,0xc
ffffffffc0201a0a:	953e                	add	a0,a0,a5
ffffffffc0201a0c:	9702                	jalr	a4
}
ffffffffc0201a0e:	bfbd                	j	ffffffffc020198c <pmm_init+0xfa>
        panic("pa2page called with invalid pa");
ffffffffc0201a10:	00001617          	auipc	a2,0x1
ffffffffc0201a14:	48060613          	addi	a2,a2,1152 # ffffffffc0202e90 <default_pmm_manager+0xf0>
ffffffffc0201a18:	06b00593          	li	a1,107
ffffffffc0201a1c:	00001517          	auipc	a0,0x1
ffffffffc0201a20:	49450513          	addi	a0,a0,1172 # ffffffffc0202eb0 <default_pmm_manager+0x110>
ffffffffc0201a24:	a05fe0ef          	jal	ra,ffffffffc0200428 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201a28:	00001617          	auipc	a2,0x1
ffffffffc0201a2c:	44060613          	addi	a2,a2,1088 # ffffffffc0202e68 <default_pmm_manager+0xc8>
ffffffffc0201a30:	07100593          	li	a1,113
ffffffffc0201a34:	00001517          	auipc	a0,0x1
ffffffffc0201a38:	3dc50513          	addi	a0,a0,988 # ffffffffc0202e10 <default_pmm_manager+0x70>
ffffffffc0201a3c:	9edfe0ef          	jal	ra,ffffffffc0200428 <__panic>
        panic("DTB memory info not available");
ffffffffc0201a40:	00001617          	auipc	a2,0x1
ffffffffc0201a44:	3b060613          	addi	a2,a2,944 # ffffffffc0202df0 <default_pmm_manager+0x50>
ffffffffc0201a48:	05a00593          	li	a1,90
ffffffffc0201a4c:	00001517          	auipc	a0,0x1
ffffffffc0201a50:	3c450513          	addi	a0,a0,964 # ffffffffc0202e10 <default_pmm_manager+0x70>
ffffffffc0201a54:	9d5fe0ef          	jal	ra,ffffffffc0200428 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201a58:	86ae                	mv	a3,a1
ffffffffc0201a5a:	00001617          	auipc	a2,0x1
ffffffffc0201a5e:	40e60613          	addi	a2,a2,1038 # ffffffffc0202e68 <default_pmm_manager+0xc8>
ffffffffc0201a62:	08c00593          	li	a1,140
ffffffffc0201a66:	00001517          	auipc	a0,0x1
ffffffffc0201a6a:	3aa50513          	addi	a0,a0,938 # ffffffffc0202e10 <default_pmm_manager+0x70>
ffffffffc0201a6e:	9bbfe0ef          	jal	ra,ffffffffc0200428 <__panic>

ffffffffc0201a72 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0201a72:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201a76:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0201a78:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201a7c:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0201a7e:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201a82:	f022                	sd	s0,32(sp)
ffffffffc0201a84:	ec26                	sd	s1,24(sp)
ffffffffc0201a86:	e84a                	sd	s2,16(sp)
ffffffffc0201a88:	f406                	sd	ra,40(sp)
ffffffffc0201a8a:	e44e                	sd	s3,8(sp)
ffffffffc0201a8c:	84aa                	mv	s1,a0
ffffffffc0201a8e:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0201a90:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0201a94:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0201a96:	03067e63          	bgeu	a2,a6,ffffffffc0201ad2 <printnum+0x60>
ffffffffc0201a9a:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0201a9c:	00805763          	blez	s0,ffffffffc0201aaa <printnum+0x38>
ffffffffc0201aa0:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0201aa2:	85ca                	mv	a1,s2
ffffffffc0201aa4:	854e                	mv	a0,s3
ffffffffc0201aa6:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0201aa8:	fc65                	bnez	s0,ffffffffc0201aa0 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201aaa:	1a02                	slli	s4,s4,0x20
ffffffffc0201aac:	00001797          	auipc	a5,0x1
ffffffffc0201ab0:	47478793          	addi	a5,a5,1140 # ffffffffc0202f20 <default_pmm_manager+0x180>
ffffffffc0201ab4:	020a5a13          	srli	s4,s4,0x20
ffffffffc0201ab8:	9a3e                	add	s4,s4,a5
}
ffffffffc0201aba:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201abc:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0201ac0:	70a2                	ld	ra,40(sp)
ffffffffc0201ac2:	69a2                	ld	s3,8(sp)
ffffffffc0201ac4:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201ac6:	85ca                	mv	a1,s2
ffffffffc0201ac8:	87a6                	mv	a5,s1
}
ffffffffc0201aca:	6942                	ld	s2,16(sp)
ffffffffc0201acc:	64e2                	ld	s1,24(sp)
ffffffffc0201ace:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201ad0:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0201ad2:	03065633          	divu	a2,a2,a6
ffffffffc0201ad6:	8722                	mv	a4,s0
ffffffffc0201ad8:	f9bff0ef          	jal	ra,ffffffffc0201a72 <printnum>
ffffffffc0201adc:	b7f9                	j	ffffffffc0201aaa <printnum+0x38>

ffffffffc0201ade <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0201ade:	7119                	addi	sp,sp,-128
ffffffffc0201ae0:	f4a6                	sd	s1,104(sp)
ffffffffc0201ae2:	f0ca                	sd	s2,96(sp)
ffffffffc0201ae4:	ecce                	sd	s3,88(sp)
ffffffffc0201ae6:	e8d2                	sd	s4,80(sp)
ffffffffc0201ae8:	e4d6                	sd	s5,72(sp)
ffffffffc0201aea:	e0da                	sd	s6,64(sp)
ffffffffc0201aec:	fc5e                	sd	s7,56(sp)
ffffffffc0201aee:	f06a                	sd	s10,32(sp)
ffffffffc0201af0:	fc86                	sd	ra,120(sp)
ffffffffc0201af2:	f8a2                	sd	s0,112(sp)
ffffffffc0201af4:	f862                	sd	s8,48(sp)
ffffffffc0201af6:	f466                	sd	s9,40(sp)
ffffffffc0201af8:	ec6e                	sd	s11,24(sp)
ffffffffc0201afa:	892a                	mv	s2,a0
ffffffffc0201afc:	84ae                	mv	s1,a1
ffffffffc0201afe:	8d32                	mv	s10,a2
ffffffffc0201b00:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201b02:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0201b06:	5b7d                	li	s6,-1
ffffffffc0201b08:	00001a97          	auipc	s5,0x1
ffffffffc0201b0c:	44ca8a93          	addi	s5,s5,1100 # ffffffffc0202f54 <default_pmm_manager+0x1b4>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201b10:	00001b97          	auipc	s7,0x1
ffffffffc0201b14:	620b8b93          	addi	s7,s7,1568 # ffffffffc0203130 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201b18:	000d4503          	lbu	a0,0(s10)
ffffffffc0201b1c:	001d0413          	addi	s0,s10,1
ffffffffc0201b20:	01350a63          	beq	a0,s3,ffffffffc0201b34 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0201b24:	c121                	beqz	a0,ffffffffc0201b64 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0201b26:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201b28:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0201b2a:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201b2c:	fff44503          	lbu	a0,-1(s0)
ffffffffc0201b30:	ff351ae3          	bne	a0,s3,ffffffffc0201b24 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b34:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0201b38:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0201b3c:	4c81                	li	s9,0
ffffffffc0201b3e:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0201b40:	5c7d                	li	s8,-1
ffffffffc0201b42:	5dfd                	li	s11,-1
ffffffffc0201b44:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0201b48:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b4a:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201b4e:	0ff5f593          	zext.b	a1,a1
ffffffffc0201b52:	00140d13          	addi	s10,s0,1
ffffffffc0201b56:	04b56263          	bltu	a0,a1,ffffffffc0201b9a <vprintfmt+0xbc>
ffffffffc0201b5a:	058a                	slli	a1,a1,0x2
ffffffffc0201b5c:	95d6                	add	a1,a1,s5
ffffffffc0201b5e:	4194                	lw	a3,0(a1)
ffffffffc0201b60:	96d6                	add	a3,a3,s5
ffffffffc0201b62:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0201b64:	70e6                	ld	ra,120(sp)
ffffffffc0201b66:	7446                	ld	s0,112(sp)
ffffffffc0201b68:	74a6                	ld	s1,104(sp)
ffffffffc0201b6a:	7906                	ld	s2,96(sp)
ffffffffc0201b6c:	69e6                	ld	s3,88(sp)
ffffffffc0201b6e:	6a46                	ld	s4,80(sp)
ffffffffc0201b70:	6aa6                	ld	s5,72(sp)
ffffffffc0201b72:	6b06                	ld	s6,64(sp)
ffffffffc0201b74:	7be2                	ld	s7,56(sp)
ffffffffc0201b76:	7c42                	ld	s8,48(sp)
ffffffffc0201b78:	7ca2                	ld	s9,40(sp)
ffffffffc0201b7a:	7d02                	ld	s10,32(sp)
ffffffffc0201b7c:	6de2                	ld	s11,24(sp)
ffffffffc0201b7e:	6109                	addi	sp,sp,128
ffffffffc0201b80:	8082                	ret
            padc = '0';
ffffffffc0201b82:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0201b84:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b88:	846a                	mv	s0,s10
ffffffffc0201b8a:	00140d13          	addi	s10,s0,1
ffffffffc0201b8e:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201b92:	0ff5f593          	zext.b	a1,a1
ffffffffc0201b96:	fcb572e3          	bgeu	a0,a1,ffffffffc0201b5a <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0201b9a:	85a6                	mv	a1,s1
ffffffffc0201b9c:	02500513          	li	a0,37
ffffffffc0201ba0:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201ba2:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201ba6:	8d22                	mv	s10,s0
ffffffffc0201ba8:	f73788e3          	beq	a5,s3,ffffffffc0201b18 <vprintfmt+0x3a>
ffffffffc0201bac:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0201bb0:	1d7d                	addi	s10,s10,-1
ffffffffc0201bb2:	ff379de3          	bne	a5,s3,ffffffffc0201bac <vprintfmt+0xce>
ffffffffc0201bb6:	b78d                	j	ffffffffc0201b18 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0201bb8:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0201bbc:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201bc0:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0201bc2:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0201bc6:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201bca:	02d86463          	bltu	a6,a3,ffffffffc0201bf2 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0201bce:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0201bd2:	002c169b          	slliw	a3,s8,0x2
ffffffffc0201bd6:	0186873b          	addw	a4,a3,s8
ffffffffc0201bda:	0017171b          	slliw	a4,a4,0x1
ffffffffc0201bde:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0201be0:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0201be4:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0201be6:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0201bea:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201bee:	fed870e3          	bgeu	a6,a3,ffffffffc0201bce <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0201bf2:	f40ddce3          	bgez	s11,ffffffffc0201b4a <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0201bf6:	8de2                	mv	s11,s8
ffffffffc0201bf8:	5c7d                	li	s8,-1
ffffffffc0201bfa:	bf81                	j	ffffffffc0201b4a <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0201bfc:	fffdc693          	not	a3,s11
ffffffffc0201c00:	96fd                	srai	a3,a3,0x3f
ffffffffc0201c02:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201c06:	00144603          	lbu	a2,1(s0)
ffffffffc0201c0a:	2d81                	sext.w	s11,s11
ffffffffc0201c0c:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201c0e:	bf35                	j	ffffffffc0201b4a <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0201c10:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201c14:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0201c18:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201c1a:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0201c1c:	bfd9                	j	ffffffffc0201bf2 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0201c1e:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201c20:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201c24:	01174463          	blt	a4,a7,ffffffffc0201c2c <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0201c28:	1a088e63          	beqz	a7,ffffffffc0201de4 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0201c2c:	000a3603          	ld	a2,0(s4)
ffffffffc0201c30:	46c1                	li	a3,16
ffffffffc0201c32:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201c34:	2781                	sext.w	a5,a5
ffffffffc0201c36:	876e                	mv	a4,s11
ffffffffc0201c38:	85a6                	mv	a1,s1
ffffffffc0201c3a:	854a                	mv	a0,s2
ffffffffc0201c3c:	e37ff0ef          	jal	ra,ffffffffc0201a72 <printnum>
            break;
ffffffffc0201c40:	bde1                	j	ffffffffc0201b18 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0201c42:	000a2503          	lw	a0,0(s4)
ffffffffc0201c46:	85a6                	mv	a1,s1
ffffffffc0201c48:	0a21                	addi	s4,s4,8
ffffffffc0201c4a:	9902                	jalr	s2
            break;
ffffffffc0201c4c:	b5f1                	j	ffffffffc0201b18 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201c4e:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201c50:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201c54:	01174463          	blt	a4,a7,ffffffffc0201c5c <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0201c58:	18088163          	beqz	a7,ffffffffc0201dda <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0201c5c:	000a3603          	ld	a2,0(s4)
ffffffffc0201c60:	46a9                	li	a3,10
ffffffffc0201c62:	8a2e                	mv	s4,a1
ffffffffc0201c64:	bfc1                	j	ffffffffc0201c34 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201c66:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0201c6a:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201c6c:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201c6e:	bdf1                	j	ffffffffc0201b4a <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0201c70:	85a6                	mv	a1,s1
ffffffffc0201c72:	02500513          	li	a0,37
ffffffffc0201c76:	9902                	jalr	s2
            break;
ffffffffc0201c78:	b545                	j	ffffffffc0201b18 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201c7a:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0201c7e:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201c80:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201c82:	b5e1                	j	ffffffffc0201b4a <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0201c84:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201c86:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201c8a:	01174463          	blt	a4,a7,ffffffffc0201c92 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0201c8e:	14088163          	beqz	a7,ffffffffc0201dd0 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0201c92:	000a3603          	ld	a2,0(s4)
ffffffffc0201c96:	46a1                	li	a3,8
ffffffffc0201c98:	8a2e                	mv	s4,a1
ffffffffc0201c9a:	bf69                	j	ffffffffc0201c34 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0201c9c:	03000513          	li	a0,48
ffffffffc0201ca0:	85a6                	mv	a1,s1
ffffffffc0201ca2:	e03e                	sd	a5,0(sp)
ffffffffc0201ca4:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0201ca6:	85a6                	mv	a1,s1
ffffffffc0201ca8:	07800513          	li	a0,120
ffffffffc0201cac:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201cae:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0201cb0:	6782                	ld	a5,0(sp)
ffffffffc0201cb2:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201cb4:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0201cb8:	bfb5                	j	ffffffffc0201c34 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201cba:	000a3403          	ld	s0,0(s4)
ffffffffc0201cbe:	008a0713          	addi	a4,s4,8
ffffffffc0201cc2:	e03a                	sd	a4,0(sp)
ffffffffc0201cc4:	14040263          	beqz	s0,ffffffffc0201e08 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0201cc8:	0fb05763          	blez	s11,ffffffffc0201db6 <vprintfmt+0x2d8>
ffffffffc0201ccc:	02d00693          	li	a3,45
ffffffffc0201cd0:	0cd79163          	bne	a5,a3,ffffffffc0201d92 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201cd4:	00044783          	lbu	a5,0(s0)
ffffffffc0201cd8:	0007851b          	sext.w	a0,a5
ffffffffc0201cdc:	cf85                	beqz	a5,ffffffffc0201d14 <vprintfmt+0x236>
ffffffffc0201cde:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201ce2:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201ce6:	000c4563          	bltz	s8,ffffffffc0201cf0 <vprintfmt+0x212>
ffffffffc0201cea:	3c7d                	addiw	s8,s8,-1
ffffffffc0201cec:	036c0263          	beq	s8,s6,ffffffffc0201d10 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0201cf0:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201cf2:	0e0c8e63          	beqz	s9,ffffffffc0201dee <vprintfmt+0x310>
ffffffffc0201cf6:	3781                	addiw	a5,a5,-32
ffffffffc0201cf8:	0ef47b63          	bgeu	s0,a5,ffffffffc0201dee <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0201cfc:	03f00513          	li	a0,63
ffffffffc0201d00:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201d02:	000a4783          	lbu	a5,0(s4)
ffffffffc0201d06:	3dfd                	addiw	s11,s11,-1
ffffffffc0201d08:	0a05                	addi	s4,s4,1
ffffffffc0201d0a:	0007851b          	sext.w	a0,a5
ffffffffc0201d0e:	ffe1                	bnez	a5,ffffffffc0201ce6 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0201d10:	01b05963          	blez	s11,ffffffffc0201d22 <vprintfmt+0x244>
ffffffffc0201d14:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0201d16:	85a6                	mv	a1,s1
ffffffffc0201d18:	02000513          	li	a0,32
ffffffffc0201d1c:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201d1e:	fe0d9be3          	bnez	s11,ffffffffc0201d14 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201d22:	6a02                	ld	s4,0(sp)
ffffffffc0201d24:	bbd5                	j	ffffffffc0201b18 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201d26:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201d28:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0201d2c:	01174463          	blt	a4,a7,ffffffffc0201d34 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0201d30:	08088d63          	beqz	a7,ffffffffc0201dca <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0201d34:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0201d38:	0a044d63          	bltz	s0,ffffffffc0201df2 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0201d3c:	8622                	mv	a2,s0
ffffffffc0201d3e:	8a66                	mv	s4,s9
ffffffffc0201d40:	46a9                	li	a3,10
ffffffffc0201d42:	bdcd                	j	ffffffffc0201c34 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0201d44:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201d48:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0201d4a:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0201d4c:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0201d50:	8fb5                	xor	a5,a5,a3
ffffffffc0201d52:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201d56:	02d74163          	blt	a4,a3,ffffffffc0201d78 <vprintfmt+0x29a>
ffffffffc0201d5a:	00369793          	slli	a5,a3,0x3
ffffffffc0201d5e:	97de                	add	a5,a5,s7
ffffffffc0201d60:	639c                	ld	a5,0(a5)
ffffffffc0201d62:	cb99                	beqz	a5,ffffffffc0201d78 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201d64:	86be                	mv	a3,a5
ffffffffc0201d66:	00001617          	auipc	a2,0x1
ffffffffc0201d6a:	1ea60613          	addi	a2,a2,490 # ffffffffc0202f50 <default_pmm_manager+0x1b0>
ffffffffc0201d6e:	85a6                	mv	a1,s1
ffffffffc0201d70:	854a                	mv	a0,s2
ffffffffc0201d72:	0ce000ef          	jal	ra,ffffffffc0201e40 <printfmt>
ffffffffc0201d76:	b34d                	j	ffffffffc0201b18 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201d78:	00001617          	auipc	a2,0x1
ffffffffc0201d7c:	1c860613          	addi	a2,a2,456 # ffffffffc0202f40 <default_pmm_manager+0x1a0>
ffffffffc0201d80:	85a6                	mv	a1,s1
ffffffffc0201d82:	854a                	mv	a0,s2
ffffffffc0201d84:	0bc000ef          	jal	ra,ffffffffc0201e40 <printfmt>
ffffffffc0201d88:	bb41                	j	ffffffffc0201b18 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0201d8a:	00001417          	auipc	s0,0x1
ffffffffc0201d8e:	1ae40413          	addi	s0,s0,430 # ffffffffc0202f38 <default_pmm_manager+0x198>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201d92:	85e2                	mv	a1,s8
ffffffffc0201d94:	8522                	mv	a0,s0
ffffffffc0201d96:	e43e                	sd	a5,8(sp)
ffffffffc0201d98:	200000ef          	jal	ra,ffffffffc0201f98 <strnlen>
ffffffffc0201d9c:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0201da0:	01b05b63          	blez	s11,ffffffffc0201db6 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0201da4:	67a2                	ld	a5,8(sp)
ffffffffc0201da6:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201daa:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0201dac:	85a6                	mv	a1,s1
ffffffffc0201dae:	8552                	mv	a0,s4
ffffffffc0201db0:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201db2:	fe0d9ce3          	bnez	s11,ffffffffc0201daa <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201db6:	00044783          	lbu	a5,0(s0)
ffffffffc0201dba:	00140a13          	addi	s4,s0,1
ffffffffc0201dbe:	0007851b          	sext.w	a0,a5
ffffffffc0201dc2:	d3a5                	beqz	a5,ffffffffc0201d22 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201dc4:	05e00413          	li	s0,94
ffffffffc0201dc8:	bf39                	j	ffffffffc0201ce6 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0201dca:	000a2403          	lw	s0,0(s4)
ffffffffc0201dce:	b7ad                	j	ffffffffc0201d38 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0201dd0:	000a6603          	lwu	a2,0(s4)
ffffffffc0201dd4:	46a1                	li	a3,8
ffffffffc0201dd6:	8a2e                	mv	s4,a1
ffffffffc0201dd8:	bdb1                	j	ffffffffc0201c34 <vprintfmt+0x156>
ffffffffc0201dda:	000a6603          	lwu	a2,0(s4)
ffffffffc0201dde:	46a9                	li	a3,10
ffffffffc0201de0:	8a2e                	mv	s4,a1
ffffffffc0201de2:	bd89                	j	ffffffffc0201c34 <vprintfmt+0x156>
ffffffffc0201de4:	000a6603          	lwu	a2,0(s4)
ffffffffc0201de8:	46c1                	li	a3,16
ffffffffc0201dea:	8a2e                	mv	s4,a1
ffffffffc0201dec:	b5a1                	j	ffffffffc0201c34 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0201dee:	9902                	jalr	s2
ffffffffc0201df0:	bf09                	j	ffffffffc0201d02 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0201df2:	85a6                	mv	a1,s1
ffffffffc0201df4:	02d00513          	li	a0,45
ffffffffc0201df8:	e03e                	sd	a5,0(sp)
ffffffffc0201dfa:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0201dfc:	6782                	ld	a5,0(sp)
ffffffffc0201dfe:	8a66                	mv	s4,s9
ffffffffc0201e00:	40800633          	neg	a2,s0
ffffffffc0201e04:	46a9                	li	a3,10
ffffffffc0201e06:	b53d                	j	ffffffffc0201c34 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0201e08:	03b05163          	blez	s11,ffffffffc0201e2a <vprintfmt+0x34c>
ffffffffc0201e0c:	02d00693          	li	a3,45
ffffffffc0201e10:	f6d79de3          	bne	a5,a3,ffffffffc0201d8a <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0201e14:	00001417          	auipc	s0,0x1
ffffffffc0201e18:	12440413          	addi	s0,s0,292 # ffffffffc0202f38 <default_pmm_manager+0x198>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201e1c:	02800793          	li	a5,40
ffffffffc0201e20:	02800513          	li	a0,40
ffffffffc0201e24:	00140a13          	addi	s4,s0,1
ffffffffc0201e28:	bd6d                	j	ffffffffc0201ce2 <vprintfmt+0x204>
ffffffffc0201e2a:	00001a17          	auipc	s4,0x1
ffffffffc0201e2e:	10fa0a13          	addi	s4,s4,271 # ffffffffc0202f39 <default_pmm_manager+0x199>
ffffffffc0201e32:	02800513          	li	a0,40
ffffffffc0201e36:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201e3a:	05e00413          	li	s0,94
ffffffffc0201e3e:	b565                	j	ffffffffc0201ce6 <vprintfmt+0x208>

ffffffffc0201e40 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201e40:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201e42:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201e46:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201e48:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201e4a:	ec06                	sd	ra,24(sp)
ffffffffc0201e4c:	f83a                	sd	a4,48(sp)
ffffffffc0201e4e:	fc3e                	sd	a5,56(sp)
ffffffffc0201e50:	e0c2                	sd	a6,64(sp)
ffffffffc0201e52:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201e54:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201e56:	c89ff0ef          	jal	ra,ffffffffc0201ade <vprintfmt>
}
ffffffffc0201e5a:	60e2                	ld	ra,24(sp)
ffffffffc0201e5c:	6161                	addi	sp,sp,80
ffffffffc0201e5e:	8082                	ret

ffffffffc0201e60 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0201e60:	715d                	addi	sp,sp,-80
ffffffffc0201e62:	e486                	sd	ra,72(sp)
ffffffffc0201e64:	e0a6                	sd	s1,64(sp)
ffffffffc0201e66:	fc4a                	sd	s2,56(sp)
ffffffffc0201e68:	f84e                	sd	s3,48(sp)
ffffffffc0201e6a:	f452                	sd	s4,40(sp)
ffffffffc0201e6c:	f056                	sd	s5,32(sp)
ffffffffc0201e6e:	ec5a                	sd	s6,24(sp)
ffffffffc0201e70:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc0201e72:	c901                	beqz	a0,ffffffffc0201e82 <readline+0x22>
ffffffffc0201e74:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc0201e76:	00001517          	auipc	a0,0x1
ffffffffc0201e7a:	0da50513          	addi	a0,a0,218 # ffffffffc0202f50 <default_pmm_manager+0x1b0>
ffffffffc0201e7e:	ab0fe0ef          	jal	ra,ffffffffc020012e <cprintf>
readline(const char *prompt) {
ffffffffc0201e82:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201e84:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc0201e86:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc0201e88:	4aa9                	li	s5,10
ffffffffc0201e8a:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc0201e8c:	00005b97          	auipc	s7,0x5
ffffffffc0201e90:	1b4b8b93          	addi	s7,s7,436 # ffffffffc0207040 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201e94:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc0201e98:	b0efe0ef          	jal	ra,ffffffffc02001a6 <getchar>
        if (c < 0) {
ffffffffc0201e9c:	00054a63          	bltz	a0,ffffffffc0201eb0 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201ea0:	00a95a63          	bge	s2,a0,ffffffffc0201eb4 <readline+0x54>
ffffffffc0201ea4:	029a5263          	bge	s4,s1,ffffffffc0201ec8 <readline+0x68>
        c = getchar();
ffffffffc0201ea8:	afefe0ef          	jal	ra,ffffffffc02001a6 <getchar>
        if (c < 0) {
ffffffffc0201eac:	fe055ae3          	bgez	a0,ffffffffc0201ea0 <readline+0x40>
            return NULL;
ffffffffc0201eb0:	4501                	li	a0,0
ffffffffc0201eb2:	a091                	j	ffffffffc0201ef6 <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc0201eb4:	03351463          	bne	a0,s3,ffffffffc0201edc <readline+0x7c>
ffffffffc0201eb8:	e8a9                	bnez	s1,ffffffffc0201f0a <readline+0xaa>
        c = getchar();
ffffffffc0201eba:	aecfe0ef          	jal	ra,ffffffffc02001a6 <getchar>
        if (c < 0) {
ffffffffc0201ebe:	fe0549e3          	bltz	a0,ffffffffc0201eb0 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201ec2:	fea959e3          	bge	s2,a0,ffffffffc0201eb4 <readline+0x54>
ffffffffc0201ec6:	4481                	li	s1,0
            cputchar(c);
ffffffffc0201ec8:	e42a                	sd	a0,8(sp)
ffffffffc0201eca:	a9afe0ef          	jal	ra,ffffffffc0200164 <cputchar>
            buf[i ++] = c;
ffffffffc0201ece:	6522                	ld	a0,8(sp)
ffffffffc0201ed0:	009b87b3          	add	a5,s7,s1
ffffffffc0201ed4:	2485                	addiw	s1,s1,1
ffffffffc0201ed6:	00a78023          	sb	a0,0(a5)
ffffffffc0201eda:	bf7d                	j	ffffffffc0201e98 <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc0201edc:	01550463          	beq	a0,s5,ffffffffc0201ee4 <readline+0x84>
ffffffffc0201ee0:	fb651ce3          	bne	a0,s6,ffffffffc0201e98 <readline+0x38>
            cputchar(c);
ffffffffc0201ee4:	a80fe0ef          	jal	ra,ffffffffc0200164 <cputchar>
            buf[i] = '\0';
ffffffffc0201ee8:	00005517          	auipc	a0,0x5
ffffffffc0201eec:	15850513          	addi	a0,a0,344 # ffffffffc0207040 <buf>
ffffffffc0201ef0:	94aa                	add	s1,s1,a0
ffffffffc0201ef2:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc0201ef6:	60a6                	ld	ra,72(sp)
ffffffffc0201ef8:	6486                	ld	s1,64(sp)
ffffffffc0201efa:	7962                	ld	s2,56(sp)
ffffffffc0201efc:	79c2                	ld	s3,48(sp)
ffffffffc0201efe:	7a22                	ld	s4,40(sp)
ffffffffc0201f00:	7a82                	ld	s5,32(sp)
ffffffffc0201f02:	6b62                	ld	s6,24(sp)
ffffffffc0201f04:	6bc2                	ld	s7,16(sp)
ffffffffc0201f06:	6161                	addi	sp,sp,80
ffffffffc0201f08:	8082                	ret
            cputchar(c);
ffffffffc0201f0a:	4521                	li	a0,8
ffffffffc0201f0c:	a58fe0ef          	jal	ra,ffffffffc0200164 <cputchar>
            i --;
ffffffffc0201f10:	34fd                	addiw	s1,s1,-1
ffffffffc0201f12:	b759                	j	ffffffffc0201e98 <readline+0x38>

ffffffffc0201f14 <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc0201f14:	4781                	li	a5,0
ffffffffc0201f16:	00005717          	auipc	a4,0x5
ffffffffc0201f1a:	10273703          	ld	a4,258(a4) # ffffffffc0207018 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201f1e:	88ba                	mv	a7,a4
ffffffffc0201f20:	852a                	mv	a0,a0
ffffffffc0201f22:	85be                	mv	a1,a5
ffffffffc0201f24:	863e                	mv	a2,a5
ffffffffc0201f26:	00000073          	ecall
ffffffffc0201f2a:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0201f2c:	8082                	ret

ffffffffc0201f2e <sbi_set_timer>:
    __asm__ volatile (
ffffffffc0201f2e:	4781                	li	a5,0
ffffffffc0201f30:	00005717          	auipc	a4,0x5
ffffffffc0201f34:	56873703          	ld	a4,1384(a4) # ffffffffc0207498 <SBI_SET_TIMER>
ffffffffc0201f38:	88ba                	mv	a7,a4
ffffffffc0201f3a:	852a                	mv	a0,a0
ffffffffc0201f3c:	85be                	mv	a1,a5
ffffffffc0201f3e:	863e                	mv	a2,a5
ffffffffc0201f40:	00000073          	ecall
ffffffffc0201f44:	87aa                	mv	a5,a0

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
}
ffffffffc0201f46:	8082                	ret

ffffffffc0201f48 <sbi_console_getchar>:
    __asm__ volatile (
ffffffffc0201f48:	4501                	li	a0,0
ffffffffc0201f4a:	00005797          	auipc	a5,0x5
ffffffffc0201f4e:	0c67b783          	ld	a5,198(a5) # ffffffffc0207010 <SBI_CONSOLE_GETCHAR>
ffffffffc0201f52:	88be                	mv	a7,a5
ffffffffc0201f54:	852a                	mv	a0,a0
ffffffffc0201f56:	85aa                	mv	a1,a0
ffffffffc0201f58:	862a                	mv	a2,a0
ffffffffc0201f5a:	00000073          	ecall
ffffffffc0201f5e:	852a                	mv	a0,a0

int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
}
ffffffffc0201f60:	2501                	sext.w	a0,a0
ffffffffc0201f62:	8082                	ret

ffffffffc0201f64 <sbi_shutdown>:
    __asm__ volatile (
ffffffffc0201f64:	4781                	li	a5,0
ffffffffc0201f66:	00005717          	auipc	a4,0x5
ffffffffc0201f6a:	0ba73703          	ld	a4,186(a4) # ffffffffc0207020 <SBI_SHUTDOWN>
ffffffffc0201f6e:	88ba                	mv	a7,a4
ffffffffc0201f70:	853e                	mv	a0,a5
ffffffffc0201f72:	85be                	mv	a1,a5
ffffffffc0201f74:	863e                	mv	a2,a5
ffffffffc0201f76:	00000073          	ecall
ffffffffc0201f7a:	87aa                	mv	a5,a0

void sbi_shutdown(void)
{
	sbi_call(SBI_SHUTDOWN, 0, 0, 0);
ffffffffc0201f7c:	8082                	ret

ffffffffc0201f7e <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0201f7e:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0201f82:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0201f84:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0201f86:	cb81                	beqz	a5,ffffffffc0201f96 <strlen+0x18>
        cnt ++;
ffffffffc0201f88:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0201f8a:	00a707b3          	add	a5,a4,a0
ffffffffc0201f8e:	0007c783          	lbu	a5,0(a5)
ffffffffc0201f92:	fbfd                	bnez	a5,ffffffffc0201f88 <strlen+0xa>
ffffffffc0201f94:	8082                	ret
    }
    return cnt;
}
ffffffffc0201f96:	8082                	ret

ffffffffc0201f98 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0201f98:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201f9a:	e589                	bnez	a1,ffffffffc0201fa4 <strnlen+0xc>
ffffffffc0201f9c:	a811                	j	ffffffffc0201fb0 <strnlen+0x18>
        cnt ++;
ffffffffc0201f9e:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201fa0:	00f58863          	beq	a1,a5,ffffffffc0201fb0 <strnlen+0x18>
ffffffffc0201fa4:	00f50733          	add	a4,a0,a5
ffffffffc0201fa8:	00074703          	lbu	a4,0(a4)
ffffffffc0201fac:	fb6d                	bnez	a4,ffffffffc0201f9e <strnlen+0x6>
ffffffffc0201fae:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0201fb0:	852e                	mv	a0,a1
ffffffffc0201fb2:	8082                	ret

ffffffffc0201fb4 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201fb4:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201fb8:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201fbc:	cb89                	beqz	a5,ffffffffc0201fce <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0201fbe:	0505                	addi	a0,a0,1
ffffffffc0201fc0:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201fc2:	fee789e3          	beq	a5,a4,ffffffffc0201fb4 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201fc6:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201fca:	9d19                	subw	a0,a0,a4
ffffffffc0201fcc:	8082                	ret
ffffffffc0201fce:	4501                	li	a0,0
ffffffffc0201fd0:	bfed                	j	ffffffffc0201fca <strcmp+0x16>

ffffffffc0201fd2 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201fd2:	c20d                	beqz	a2,ffffffffc0201ff4 <strncmp+0x22>
ffffffffc0201fd4:	962e                	add	a2,a2,a1
ffffffffc0201fd6:	a031                	j	ffffffffc0201fe2 <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0201fd8:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201fda:	00e79a63          	bne	a5,a4,ffffffffc0201fee <strncmp+0x1c>
ffffffffc0201fde:	00b60b63          	beq	a2,a1,ffffffffc0201ff4 <strncmp+0x22>
ffffffffc0201fe2:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0201fe6:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201fe8:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0201fec:	f7f5                	bnez	a5,ffffffffc0201fd8 <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201fee:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0201ff2:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201ff4:	4501                	li	a0,0
ffffffffc0201ff6:	8082                	ret

ffffffffc0201ff8 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0201ff8:	00054783          	lbu	a5,0(a0)
ffffffffc0201ffc:	c799                	beqz	a5,ffffffffc020200a <strchr+0x12>
        if (*s == c) {
ffffffffc0201ffe:	00f58763          	beq	a1,a5,ffffffffc020200c <strchr+0x14>
    while (*s != '\0') {
ffffffffc0202002:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0202006:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0202008:	fbfd                	bnez	a5,ffffffffc0201ffe <strchr+0x6>
    }
    return NULL;
ffffffffc020200a:	4501                	li	a0,0
}
ffffffffc020200c:	8082                	ret

ffffffffc020200e <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc020200e:	ca01                	beqz	a2,ffffffffc020201e <memset+0x10>
ffffffffc0202010:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0202012:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0202014:	0785                	addi	a5,a5,1
ffffffffc0202016:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc020201a:	fec79de3          	bne	a5,a2,ffffffffc0202014 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc020201e:	8082                	ret
