
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00006297          	auipc	t0,0x6
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0206000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00006297          	auipc	t0,0x6
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0206008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02052b7          	lui	t0,0xc0205
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
ffffffffc020003c:	c0205137          	lui	sp,0xc0205

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 1. 使用临时寄存器 t1 计算栈顶的精确地址
    lui t1, %hi(bootstacktop)
ffffffffc0200040:	c0205337          	lui	t1,0xc0205
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
ffffffffc020004e:	07c28293          	addi	t0,t0,124 # ffffffffc020007c <kern_init>
    jr t0
ffffffffc0200052:	8282                	jr	t0

ffffffffc0200054 <test_illegal>:
#include <dtb.h>

int kern_init(void) __attribute__((noreturn));
void grade_backtrace(void);

void test_illegal(void) {
ffffffffc0200054:	1141                	addi	sp,sp,-16
    cprintf("\n Testing  illegal instruction1 \n");
ffffffffc0200056:	00002517          	auipc	a0,0x2
ffffffffc020005a:	eea50513          	addi	a0,a0,-278 # ffffffffc0201f40 <etext+0x6>
void test_illegal(void) {
ffffffffc020005e:	e406                	sd	ra,8(sp)
    cprintf("\n Testing  illegal instruction1 \n");
ffffffffc0200060:	0b2000ef          	jal	ra,ffffffffc0200112 <cprintf>
ffffffffc0200064:	ffff                	0xffff
ffffffffc0200066:	ffff                	0xffff
    asm volatile (".word 0xffffffff");     // 非法 32 位编码，低两位 == 0x3

    cprintf("\n Testing  illegal instruction2 \n");
ffffffffc0200068:	00002517          	auipc	a0,0x2
ffffffffc020006c:	f0050513          	addi	a0,a0,-256 # ffffffffc0201f68 <etext+0x2e>
ffffffffc0200070:	0a2000ef          	jal	ra,ffffffffc0200112 <cprintf>
ffffffffc0200074:	0000                	unimp
    asm volatile (".short 0x0000");        // 非法 16 位半字，低两位 != 0x3
}
ffffffffc0200076:	60a2                	ld	ra,8(sp)
ffffffffc0200078:	0141                	addi	sp,sp,16
ffffffffc020007a:	8082                	ret

ffffffffc020007c <kern_init>:
}

int kern_init(void) {
    extern char edata[], end[];
    // 先清零 BSS，再读取并保存 DTB 的内存信息，避免被清零覆盖（为了解释变化 正式上传时我觉得应该删去这句话）
    memset(edata, 0, end - edata);
ffffffffc020007c:	00006517          	auipc	a0,0x6
ffffffffc0200080:	fac50513          	addi	a0,a0,-84 # ffffffffc0206028 <free_area>
ffffffffc0200084:	00006617          	auipc	a2,0x6
ffffffffc0200088:	41c60613          	addi	a2,a2,1052 # ffffffffc02064a0 <end>
int kern_init(void) {
ffffffffc020008c:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc020008e:	8e09                	sub	a2,a2,a0
ffffffffc0200090:	4581                	li	a1,0
int kern_init(void) {
ffffffffc0200092:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc0200094:	695010ef          	jal	ra,ffffffffc0201f28 <memset>
    dtb_init();
ffffffffc0200098:	420000ef          	jal	ra,ffffffffc02004b8 <dtb_init>
    cons_init();  // init the console
ffffffffc020009c:	40e000ef          	jal	ra,ffffffffc02004aa <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc02000a0:	00002517          	auipc	a0,0x2
ffffffffc02000a4:	f0850513          	addi	a0,a0,-248 # ffffffffc0201fa8 <etext+0x6e>
ffffffffc02000a8:	0a2000ef          	jal	ra,ffffffffc020014a <cputs>

    print_kerninfo();
ffffffffc02000ac:	0ee000ef          	jal	ra,ffffffffc020019a <print_kerninfo>

    // grade_backtrace();
    idt_init();  // init interrupt descriptor table
ffffffffc02000b0:	7c4000ef          	jal	ra,ffffffffc0200874 <idt_init>

    pmm_init();  // init physical memory management
ffffffffc02000b4:	6f8010ef          	jal	ra,ffffffffc02017ac <pmm_init>

    idt_init();  // init interrupt descriptor table
ffffffffc02000b8:	7bc000ef          	jal	ra,ffffffffc0200874 <idt_init>

    // 异常测试
    test_illegal();
ffffffffc02000bc:	f99ff0ef          	jal	ra,ffffffffc0200054 <test_illegal>
    cprintf("\n Testing  breakpoint \n");
ffffffffc02000c0:	00002517          	auipc	a0,0x2
ffffffffc02000c4:	ed050513          	addi	a0,a0,-304 # ffffffffc0201f90 <etext+0x56>
ffffffffc02000c8:	04a000ef          	jal	ra,ffffffffc0200112 <cprintf>
    asm volatile ("ebreak");               // 标准断点      
ffffffffc02000cc:	9002                	ebreak
    test_breakpoint();
    
    // 中断测试
    clock_init();   // init clock interrupt，就在这触发的时钟中断
ffffffffc02000ce:	39a000ef          	jal	ra,ffffffffc0200468 <clock_init>

    intr_enable();  // enable irq interrupt
ffffffffc02000d2:	796000ef          	jal	ra,ffffffffc0200868 <intr_enable>

    /* do nothing */
    while (1)
ffffffffc02000d6:	a001                	j	ffffffffc02000d6 <kern_init+0x5a>

ffffffffc02000d8 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc02000d8:	1141                	addi	sp,sp,-16
ffffffffc02000da:	e022                	sd	s0,0(sp)
ffffffffc02000dc:	e406                	sd	ra,8(sp)
ffffffffc02000de:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc02000e0:	3cc000ef          	jal	ra,ffffffffc02004ac <cons_putc>
    (*cnt) ++;
ffffffffc02000e4:	401c                	lw	a5,0(s0)
}
ffffffffc02000e6:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc02000e8:	2785                	addiw	a5,a5,1
ffffffffc02000ea:	c01c                	sw	a5,0(s0)
}
ffffffffc02000ec:	6402                	ld	s0,0(sp)
ffffffffc02000ee:	0141                	addi	sp,sp,16
ffffffffc02000f0:	8082                	ret

ffffffffc02000f2 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000f2:	1101                	addi	sp,sp,-32
ffffffffc02000f4:	862a                	mv	a2,a0
ffffffffc02000f6:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000f8:	00000517          	auipc	a0,0x0
ffffffffc02000fc:	fe050513          	addi	a0,a0,-32 # ffffffffc02000d8 <cputch>
ffffffffc0200100:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200102:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc0200104:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200106:	0f3010ef          	jal	ra,ffffffffc02019f8 <vprintfmt>
    return cnt;
}
ffffffffc020010a:	60e2                	ld	ra,24(sp)
ffffffffc020010c:	4532                	lw	a0,12(sp)
ffffffffc020010e:	6105                	addi	sp,sp,32
ffffffffc0200110:	8082                	ret

ffffffffc0200112 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc0200112:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc0200114:	02810313          	addi	t1,sp,40 # ffffffffc0205028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc0200118:	8e2a                	mv	t3,a0
ffffffffc020011a:	f42e                	sd	a1,40(sp)
ffffffffc020011c:	f832                	sd	a2,48(sp)
ffffffffc020011e:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200120:	00000517          	auipc	a0,0x0
ffffffffc0200124:	fb850513          	addi	a0,a0,-72 # ffffffffc02000d8 <cputch>
ffffffffc0200128:	004c                	addi	a1,sp,4
ffffffffc020012a:	869a                	mv	a3,t1
ffffffffc020012c:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc020012e:	ec06                	sd	ra,24(sp)
ffffffffc0200130:	e0ba                	sd	a4,64(sp)
ffffffffc0200132:	e4be                	sd	a5,72(sp)
ffffffffc0200134:	e8c2                	sd	a6,80(sp)
ffffffffc0200136:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc0200138:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc020013a:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020013c:	0bd010ef          	jal	ra,ffffffffc02019f8 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc0200140:	60e2                	ld	ra,24(sp)
ffffffffc0200142:	4512                	lw	a0,4(sp)
ffffffffc0200144:	6125                	addi	sp,sp,96
ffffffffc0200146:	8082                	ret

ffffffffc0200148 <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc0200148:	a695                	j	ffffffffc02004ac <cons_putc>

ffffffffc020014a <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc020014a:	1101                	addi	sp,sp,-32
ffffffffc020014c:	e822                	sd	s0,16(sp)
ffffffffc020014e:	ec06                	sd	ra,24(sp)
ffffffffc0200150:	e426                	sd	s1,8(sp)
ffffffffc0200152:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc0200154:	00054503          	lbu	a0,0(a0)
ffffffffc0200158:	c51d                	beqz	a0,ffffffffc0200186 <cputs+0x3c>
ffffffffc020015a:	0405                	addi	s0,s0,1
ffffffffc020015c:	4485                	li	s1,1
ffffffffc020015e:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc0200160:	34c000ef          	jal	ra,ffffffffc02004ac <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc0200164:	00044503          	lbu	a0,0(s0)
ffffffffc0200168:	008487bb          	addw	a5,s1,s0
ffffffffc020016c:	0405                	addi	s0,s0,1
ffffffffc020016e:	f96d                	bnez	a0,ffffffffc0200160 <cputs+0x16>
    (*cnt) ++;
ffffffffc0200170:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc0200174:	4529                	li	a0,10
ffffffffc0200176:	336000ef          	jal	ra,ffffffffc02004ac <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc020017a:	60e2                	ld	ra,24(sp)
ffffffffc020017c:	8522                	mv	a0,s0
ffffffffc020017e:	6442                	ld	s0,16(sp)
ffffffffc0200180:	64a2                	ld	s1,8(sp)
ffffffffc0200182:	6105                	addi	sp,sp,32
ffffffffc0200184:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc0200186:	4405                	li	s0,1
ffffffffc0200188:	b7f5                	j	ffffffffc0200174 <cputs+0x2a>

ffffffffc020018a <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc020018a:	1141                	addi	sp,sp,-16
ffffffffc020018c:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc020018e:	326000ef          	jal	ra,ffffffffc02004b4 <cons_getc>
ffffffffc0200192:	dd75                	beqz	a0,ffffffffc020018e <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200194:	60a2                	ld	ra,8(sp)
ffffffffc0200196:	0141                	addi	sp,sp,16
ffffffffc0200198:	8082                	ret

ffffffffc020019a <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020019a:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc020019c:	00002517          	auipc	a0,0x2
ffffffffc02001a0:	e2c50513          	addi	a0,a0,-468 # ffffffffc0201fc8 <etext+0x8e>
void print_kerninfo(void) {
ffffffffc02001a4:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc02001a6:	f6dff0ef          	jal	ra,ffffffffc0200112 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", kern_init);
ffffffffc02001aa:	00000597          	auipc	a1,0x0
ffffffffc02001ae:	ed258593          	addi	a1,a1,-302 # ffffffffc020007c <kern_init>
ffffffffc02001b2:	00002517          	auipc	a0,0x2
ffffffffc02001b6:	e3650513          	addi	a0,a0,-458 # ffffffffc0201fe8 <etext+0xae>
ffffffffc02001ba:	f59ff0ef          	jal	ra,ffffffffc0200112 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc02001be:	00002597          	auipc	a1,0x2
ffffffffc02001c2:	d7c58593          	addi	a1,a1,-644 # ffffffffc0201f3a <etext>
ffffffffc02001c6:	00002517          	auipc	a0,0x2
ffffffffc02001ca:	e4250513          	addi	a0,a0,-446 # ffffffffc0202008 <etext+0xce>
ffffffffc02001ce:	f45ff0ef          	jal	ra,ffffffffc0200112 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc02001d2:	00006597          	auipc	a1,0x6
ffffffffc02001d6:	e5658593          	addi	a1,a1,-426 # ffffffffc0206028 <free_area>
ffffffffc02001da:	00002517          	auipc	a0,0x2
ffffffffc02001de:	e4e50513          	addi	a0,a0,-434 # ffffffffc0202028 <etext+0xee>
ffffffffc02001e2:	f31ff0ef          	jal	ra,ffffffffc0200112 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc02001e6:	00006597          	auipc	a1,0x6
ffffffffc02001ea:	2ba58593          	addi	a1,a1,698 # ffffffffc02064a0 <end>
ffffffffc02001ee:	00002517          	auipc	a0,0x2
ffffffffc02001f2:	e5a50513          	addi	a0,a0,-422 # ffffffffc0202048 <etext+0x10e>
ffffffffc02001f6:	f1dff0ef          	jal	ra,ffffffffc0200112 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc02001fa:	00006597          	auipc	a1,0x6
ffffffffc02001fe:	6a558593          	addi	a1,a1,1701 # ffffffffc020689f <end+0x3ff>
ffffffffc0200202:	00000797          	auipc	a5,0x0
ffffffffc0200206:	e7a78793          	addi	a5,a5,-390 # ffffffffc020007c <kern_init>
ffffffffc020020a:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc020020e:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc0200212:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200214:	3ff5f593          	andi	a1,a1,1023
ffffffffc0200218:	95be                	add	a1,a1,a5
ffffffffc020021a:	85a9                	srai	a1,a1,0xa
ffffffffc020021c:	00002517          	auipc	a0,0x2
ffffffffc0200220:	e4c50513          	addi	a0,a0,-436 # ffffffffc0202068 <etext+0x12e>
}
ffffffffc0200224:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200226:	b5f5                	j	ffffffffc0200112 <cprintf>

ffffffffc0200228 <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc0200228:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc020022a:	00002617          	auipc	a2,0x2
ffffffffc020022e:	e6e60613          	addi	a2,a2,-402 # ffffffffc0202098 <etext+0x15e>
ffffffffc0200232:	04d00593          	li	a1,77
ffffffffc0200236:	00002517          	auipc	a0,0x2
ffffffffc020023a:	e7a50513          	addi	a0,a0,-390 # ffffffffc02020b0 <etext+0x176>
void print_stackframe(void) {
ffffffffc020023e:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc0200240:	1cc000ef          	jal	ra,ffffffffc020040c <__panic>

ffffffffc0200244 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200244:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200246:	00002617          	auipc	a2,0x2
ffffffffc020024a:	e8260613          	addi	a2,a2,-382 # ffffffffc02020c8 <etext+0x18e>
ffffffffc020024e:	00002597          	auipc	a1,0x2
ffffffffc0200252:	e9a58593          	addi	a1,a1,-358 # ffffffffc02020e8 <etext+0x1ae>
ffffffffc0200256:	00002517          	auipc	a0,0x2
ffffffffc020025a:	e9a50513          	addi	a0,a0,-358 # ffffffffc02020f0 <etext+0x1b6>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc020025e:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200260:	eb3ff0ef          	jal	ra,ffffffffc0200112 <cprintf>
ffffffffc0200264:	00002617          	auipc	a2,0x2
ffffffffc0200268:	e9c60613          	addi	a2,a2,-356 # ffffffffc0202100 <etext+0x1c6>
ffffffffc020026c:	00002597          	auipc	a1,0x2
ffffffffc0200270:	ebc58593          	addi	a1,a1,-324 # ffffffffc0202128 <etext+0x1ee>
ffffffffc0200274:	00002517          	auipc	a0,0x2
ffffffffc0200278:	e7c50513          	addi	a0,a0,-388 # ffffffffc02020f0 <etext+0x1b6>
ffffffffc020027c:	e97ff0ef          	jal	ra,ffffffffc0200112 <cprintf>
ffffffffc0200280:	00002617          	auipc	a2,0x2
ffffffffc0200284:	eb860613          	addi	a2,a2,-328 # ffffffffc0202138 <etext+0x1fe>
ffffffffc0200288:	00002597          	auipc	a1,0x2
ffffffffc020028c:	ed058593          	addi	a1,a1,-304 # ffffffffc0202158 <etext+0x21e>
ffffffffc0200290:	00002517          	auipc	a0,0x2
ffffffffc0200294:	e6050513          	addi	a0,a0,-416 # ffffffffc02020f0 <etext+0x1b6>
ffffffffc0200298:	e7bff0ef          	jal	ra,ffffffffc0200112 <cprintf>
    }
    return 0;
}
ffffffffc020029c:	60a2                	ld	ra,8(sp)
ffffffffc020029e:	4501                	li	a0,0
ffffffffc02002a0:	0141                	addi	sp,sp,16
ffffffffc02002a2:	8082                	ret

ffffffffc02002a4 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002a4:	1141                	addi	sp,sp,-16
ffffffffc02002a6:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc02002a8:	ef3ff0ef          	jal	ra,ffffffffc020019a <print_kerninfo>
    return 0;
}
ffffffffc02002ac:	60a2                	ld	ra,8(sp)
ffffffffc02002ae:	4501                	li	a0,0
ffffffffc02002b0:	0141                	addi	sp,sp,16
ffffffffc02002b2:	8082                	ret

ffffffffc02002b4 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002b4:	1141                	addi	sp,sp,-16
ffffffffc02002b6:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc02002b8:	f71ff0ef          	jal	ra,ffffffffc0200228 <print_stackframe>
    return 0;
}
ffffffffc02002bc:	60a2                	ld	ra,8(sp)
ffffffffc02002be:	4501                	li	a0,0
ffffffffc02002c0:	0141                	addi	sp,sp,16
ffffffffc02002c2:	8082                	ret

ffffffffc02002c4 <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc02002c4:	7115                	addi	sp,sp,-224
ffffffffc02002c6:	ed5e                	sd	s7,152(sp)
ffffffffc02002c8:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc02002ca:	00002517          	auipc	a0,0x2
ffffffffc02002ce:	e9e50513          	addi	a0,a0,-354 # ffffffffc0202168 <etext+0x22e>
kmonitor(struct trapframe *tf) {
ffffffffc02002d2:	ed86                	sd	ra,216(sp)
ffffffffc02002d4:	e9a2                	sd	s0,208(sp)
ffffffffc02002d6:	e5a6                	sd	s1,200(sp)
ffffffffc02002d8:	e1ca                	sd	s2,192(sp)
ffffffffc02002da:	fd4e                	sd	s3,184(sp)
ffffffffc02002dc:	f952                	sd	s4,176(sp)
ffffffffc02002de:	f556                	sd	s5,168(sp)
ffffffffc02002e0:	f15a                	sd	s6,160(sp)
ffffffffc02002e2:	e962                	sd	s8,144(sp)
ffffffffc02002e4:	e566                	sd	s9,136(sp)
ffffffffc02002e6:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc02002e8:	e2bff0ef          	jal	ra,ffffffffc0200112 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc02002ec:	00002517          	auipc	a0,0x2
ffffffffc02002f0:	ea450513          	addi	a0,a0,-348 # ffffffffc0202190 <etext+0x256>
ffffffffc02002f4:	e1fff0ef          	jal	ra,ffffffffc0200112 <cprintf>
    if (tf != NULL) {
ffffffffc02002f8:	000b8563          	beqz	s7,ffffffffc0200302 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc02002fc:	855e                	mv	a0,s7
ffffffffc02002fe:	756000ef          	jal	ra,ffffffffc0200a54 <print_trapframe>
ffffffffc0200302:	00002c17          	auipc	s8,0x2
ffffffffc0200306:	efec0c13          	addi	s8,s8,-258 # ffffffffc0202200 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc020030a:	00002917          	auipc	s2,0x2
ffffffffc020030e:	eae90913          	addi	s2,s2,-338 # ffffffffc02021b8 <etext+0x27e>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200312:	00002497          	auipc	s1,0x2
ffffffffc0200316:	eae48493          	addi	s1,s1,-338 # ffffffffc02021c0 <etext+0x286>
        if (argc == MAXARGS - 1) {
ffffffffc020031a:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020031c:	00002b17          	auipc	s6,0x2
ffffffffc0200320:	eacb0b13          	addi	s6,s6,-340 # ffffffffc02021c8 <etext+0x28e>
        argv[argc ++] = buf;
ffffffffc0200324:	00002a17          	auipc	s4,0x2
ffffffffc0200328:	dc4a0a13          	addi	s4,s4,-572 # ffffffffc02020e8 <etext+0x1ae>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020032c:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc020032e:	854a                	mv	a0,s2
ffffffffc0200330:	24b010ef          	jal	ra,ffffffffc0201d7a <readline>
ffffffffc0200334:	842a                	mv	s0,a0
ffffffffc0200336:	dd65                	beqz	a0,ffffffffc020032e <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200338:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc020033c:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020033e:	e1bd                	bnez	a1,ffffffffc02003a4 <kmonitor+0xe0>
    if (argc == 0) {
ffffffffc0200340:	fe0c87e3          	beqz	s9,ffffffffc020032e <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200344:	6582                	ld	a1,0(sp)
ffffffffc0200346:	00002d17          	auipc	s10,0x2
ffffffffc020034a:	ebad0d13          	addi	s10,s10,-326 # ffffffffc0202200 <commands>
        argv[argc ++] = buf;
ffffffffc020034e:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200350:	4401                	li	s0,0
ffffffffc0200352:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200354:	37b010ef          	jal	ra,ffffffffc0201ece <strcmp>
ffffffffc0200358:	c919                	beqz	a0,ffffffffc020036e <kmonitor+0xaa>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020035a:	2405                	addiw	s0,s0,1
ffffffffc020035c:	0b540063          	beq	s0,s5,ffffffffc02003fc <kmonitor+0x138>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200360:	000d3503          	ld	a0,0(s10)
ffffffffc0200364:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200366:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200368:	367010ef          	jal	ra,ffffffffc0201ece <strcmp>
ffffffffc020036c:	f57d                	bnez	a0,ffffffffc020035a <kmonitor+0x96>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc020036e:	00141793          	slli	a5,s0,0x1
ffffffffc0200372:	97a2                	add	a5,a5,s0
ffffffffc0200374:	078e                	slli	a5,a5,0x3
ffffffffc0200376:	97e2                	add	a5,a5,s8
ffffffffc0200378:	6b9c                	ld	a5,16(a5)
ffffffffc020037a:	865e                	mv	a2,s7
ffffffffc020037c:	002c                	addi	a1,sp,8
ffffffffc020037e:	fffc851b          	addiw	a0,s9,-1
ffffffffc0200382:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc0200384:	fa0555e3          	bgez	a0,ffffffffc020032e <kmonitor+0x6a>
}
ffffffffc0200388:	60ee                	ld	ra,216(sp)
ffffffffc020038a:	644e                	ld	s0,208(sp)
ffffffffc020038c:	64ae                	ld	s1,200(sp)
ffffffffc020038e:	690e                	ld	s2,192(sp)
ffffffffc0200390:	79ea                	ld	s3,184(sp)
ffffffffc0200392:	7a4a                	ld	s4,176(sp)
ffffffffc0200394:	7aaa                	ld	s5,168(sp)
ffffffffc0200396:	7b0a                	ld	s6,160(sp)
ffffffffc0200398:	6bea                	ld	s7,152(sp)
ffffffffc020039a:	6c4a                	ld	s8,144(sp)
ffffffffc020039c:	6caa                	ld	s9,136(sp)
ffffffffc020039e:	6d0a                	ld	s10,128(sp)
ffffffffc02003a0:	612d                	addi	sp,sp,224
ffffffffc02003a2:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003a4:	8526                	mv	a0,s1
ffffffffc02003a6:	36d010ef          	jal	ra,ffffffffc0201f12 <strchr>
ffffffffc02003aa:	c901                	beqz	a0,ffffffffc02003ba <kmonitor+0xf6>
ffffffffc02003ac:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc02003b0:	00040023          	sb	zero,0(s0)
ffffffffc02003b4:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003b6:	d5c9                	beqz	a1,ffffffffc0200340 <kmonitor+0x7c>
ffffffffc02003b8:	b7f5                	j	ffffffffc02003a4 <kmonitor+0xe0>
        if (*buf == '\0') {
ffffffffc02003ba:	00044783          	lbu	a5,0(s0)
ffffffffc02003be:	d3c9                	beqz	a5,ffffffffc0200340 <kmonitor+0x7c>
        if (argc == MAXARGS - 1) {
ffffffffc02003c0:	033c8963          	beq	s9,s3,ffffffffc02003f2 <kmonitor+0x12e>
        argv[argc ++] = buf;
ffffffffc02003c4:	003c9793          	slli	a5,s9,0x3
ffffffffc02003c8:	0118                	addi	a4,sp,128
ffffffffc02003ca:	97ba                	add	a5,a5,a4
ffffffffc02003cc:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003d0:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc02003d4:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003d6:	e591                	bnez	a1,ffffffffc02003e2 <kmonitor+0x11e>
ffffffffc02003d8:	b7b5                	j	ffffffffc0200344 <kmonitor+0x80>
ffffffffc02003da:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc02003de:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003e0:	d1a5                	beqz	a1,ffffffffc0200340 <kmonitor+0x7c>
ffffffffc02003e2:	8526                	mv	a0,s1
ffffffffc02003e4:	32f010ef          	jal	ra,ffffffffc0201f12 <strchr>
ffffffffc02003e8:	d96d                	beqz	a0,ffffffffc02003da <kmonitor+0x116>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003ea:	00044583          	lbu	a1,0(s0)
ffffffffc02003ee:	d9a9                	beqz	a1,ffffffffc0200340 <kmonitor+0x7c>
ffffffffc02003f0:	bf55                	j	ffffffffc02003a4 <kmonitor+0xe0>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02003f2:	45c1                	li	a1,16
ffffffffc02003f4:	855a                	mv	a0,s6
ffffffffc02003f6:	d1dff0ef          	jal	ra,ffffffffc0200112 <cprintf>
ffffffffc02003fa:	b7e9                	j	ffffffffc02003c4 <kmonitor+0x100>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc02003fc:	6582                	ld	a1,0(sp)
ffffffffc02003fe:	00002517          	auipc	a0,0x2
ffffffffc0200402:	dea50513          	addi	a0,a0,-534 # ffffffffc02021e8 <etext+0x2ae>
ffffffffc0200406:	d0dff0ef          	jal	ra,ffffffffc0200112 <cprintf>
    return 0;
ffffffffc020040a:	b715                	j	ffffffffc020032e <kmonitor+0x6a>

ffffffffc020040c <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc020040c:	00006317          	auipc	t1,0x6
ffffffffc0200410:	03430313          	addi	t1,t1,52 # ffffffffc0206440 <is_panic>
ffffffffc0200414:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc0200418:	715d                	addi	sp,sp,-80
ffffffffc020041a:	ec06                	sd	ra,24(sp)
ffffffffc020041c:	e822                	sd	s0,16(sp)
ffffffffc020041e:	f436                	sd	a3,40(sp)
ffffffffc0200420:	f83a                	sd	a4,48(sp)
ffffffffc0200422:	fc3e                	sd	a5,56(sp)
ffffffffc0200424:	e0c2                	sd	a6,64(sp)
ffffffffc0200426:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc0200428:	020e1a63          	bnez	t3,ffffffffc020045c <__panic+0x50>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc020042c:	4785                	li	a5,1
ffffffffc020042e:	00f32023          	sw	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc0200432:	8432                	mv	s0,a2
ffffffffc0200434:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200436:	862e                	mv	a2,a1
ffffffffc0200438:	85aa                	mv	a1,a0
ffffffffc020043a:	00002517          	auipc	a0,0x2
ffffffffc020043e:	e0e50513          	addi	a0,a0,-498 # ffffffffc0202248 <commands+0x48>
    va_start(ap, fmt);
ffffffffc0200442:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200444:	ccfff0ef          	jal	ra,ffffffffc0200112 <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200448:	65a2                	ld	a1,8(sp)
ffffffffc020044a:	8522                	mv	a0,s0
ffffffffc020044c:	ca7ff0ef          	jal	ra,ffffffffc02000f2 <vcprintf>
    cprintf("\n");
ffffffffc0200450:	00002517          	auipc	a0,0x2
ffffffffc0200454:	b1050513          	addi	a0,a0,-1264 # ffffffffc0201f60 <etext+0x26>
ffffffffc0200458:	cbbff0ef          	jal	ra,ffffffffc0200112 <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc020045c:	412000ef          	jal	ra,ffffffffc020086e <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc0200460:	4501                	li	a0,0
ffffffffc0200462:	e63ff0ef          	jal	ra,ffffffffc02002c4 <kmonitor>
    while (1) {
ffffffffc0200466:	bfed                	j	ffffffffc0200460 <__panic+0x54>

ffffffffc0200468 <clock_init>:

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
ffffffffc0200468:	1141                	addi	sp,sp,-16
ffffffffc020046a:	e406                	sd	ra,8(sp)
    /*
    "分级使能"机制：既要在 sie 中使能特定中断源，又要在 sstatus 中开启全局中断。
        1. sie : 细粒度控制，决定"哪些类型的中断可以被接收"
        2. sstatus.SIE : 粗粒度控制，决定"是否接收任何中断"
    */
    set_csr(sie, MIP_STIP);  // SSTATUS_SIE
ffffffffc020046c:	02000793          	li	a5,32
ffffffffc0200470:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200474:	c0102573          	rdtime	a0
    cprintf("++ setup timer interrupts\n");
}

// clock_set_next_event() ，它会读取当前时间 rdtime ，再通过 sbi_set_timer(get_cycles() + timebase) 请求固件设置“下一次触发时间点”。可以理解为“设了个闹钟”。
// 注意，时钟中断就是在这触发的！！！！！！！！！！！！
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200478:	67e1                	lui	a5,0x18
ffffffffc020047a:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc020047e:	953e                	add	a0,a0,a5
ffffffffc0200480:	1c9010ef          	jal	ra,ffffffffc0201e48 <sbi_set_timer>
}
ffffffffc0200484:	60a2                	ld	ra,8(sp)
    ticks = 0;
ffffffffc0200486:	00006797          	auipc	a5,0x6
ffffffffc020048a:	fc07b123          	sd	zero,-62(a5) # ffffffffc0206448 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc020048e:	00002517          	auipc	a0,0x2
ffffffffc0200492:	dda50513          	addi	a0,a0,-550 # ffffffffc0202268 <commands+0x68>
}
ffffffffc0200496:	0141                	addi	sp,sp,16
    cprintf("++ setup timer interrupts\n");
ffffffffc0200498:	b9ad                	j	ffffffffc0200112 <cprintf>

ffffffffc020049a <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020049a:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020049e:	67e1                	lui	a5,0x18
ffffffffc02004a0:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc02004a4:	953e                	add	a0,a0,a5
ffffffffc02004a6:	1a30106f          	j	ffffffffc0201e48 <sbi_set_timer>

ffffffffc02004aa <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc02004aa:	8082                	ret

ffffffffc02004ac <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc02004ac:	0ff57513          	zext.b	a0,a0
ffffffffc02004b0:	17f0106f          	j	ffffffffc0201e2e <sbi_console_putchar>

ffffffffc02004b4 <cons_getc>:
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    c = sbi_console_getchar();
ffffffffc02004b4:	1af0106f          	j	ffffffffc0201e62 <sbi_console_getchar>

ffffffffc02004b8 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc02004b8:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc02004ba:	00002517          	auipc	a0,0x2
ffffffffc02004be:	dce50513          	addi	a0,a0,-562 # ffffffffc0202288 <commands+0x88>
void dtb_init(void) {
ffffffffc02004c2:	fc86                	sd	ra,120(sp)
ffffffffc02004c4:	f8a2                	sd	s0,112(sp)
ffffffffc02004c6:	e8d2                	sd	s4,80(sp)
ffffffffc02004c8:	f4a6                	sd	s1,104(sp)
ffffffffc02004ca:	f0ca                	sd	s2,96(sp)
ffffffffc02004cc:	ecce                	sd	s3,88(sp)
ffffffffc02004ce:	e4d6                	sd	s5,72(sp)
ffffffffc02004d0:	e0da                	sd	s6,64(sp)
ffffffffc02004d2:	fc5e                	sd	s7,56(sp)
ffffffffc02004d4:	f862                	sd	s8,48(sp)
ffffffffc02004d6:	f466                	sd	s9,40(sp)
ffffffffc02004d8:	f06a                	sd	s10,32(sp)
ffffffffc02004da:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc02004dc:	c37ff0ef          	jal	ra,ffffffffc0200112 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc02004e0:	00006597          	auipc	a1,0x6
ffffffffc02004e4:	b205b583          	ld	a1,-1248(a1) # ffffffffc0206000 <boot_hartid>
ffffffffc02004e8:	00002517          	auipc	a0,0x2
ffffffffc02004ec:	db050513          	addi	a0,a0,-592 # ffffffffc0202298 <commands+0x98>
ffffffffc02004f0:	c23ff0ef          	jal	ra,ffffffffc0200112 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc02004f4:	00006417          	auipc	s0,0x6
ffffffffc02004f8:	b1440413          	addi	s0,s0,-1260 # ffffffffc0206008 <boot_dtb>
ffffffffc02004fc:	600c                	ld	a1,0(s0)
ffffffffc02004fe:	00002517          	auipc	a0,0x2
ffffffffc0200502:	daa50513          	addi	a0,a0,-598 # ffffffffc02022a8 <commands+0xa8>
ffffffffc0200506:	c0dff0ef          	jal	ra,ffffffffc0200112 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc020050a:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc020050e:	00002517          	auipc	a0,0x2
ffffffffc0200512:	db250513          	addi	a0,a0,-590 # ffffffffc02022c0 <commands+0xc0>
    if (boot_dtb == 0) {
ffffffffc0200516:	120a0463          	beqz	s4,ffffffffc020063e <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc020051a:	57f5                	li	a5,-3
ffffffffc020051c:	07fa                	slli	a5,a5,0x1e
ffffffffc020051e:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc0200522:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200524:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200528:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020052a:	0087d59b          	srliw	a1,a5,0x8
ffffffffc020052e:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200532:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200536:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020053a:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020053e:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200540:	8ec9                	or	a3,a3,a0
ffffffffc0200542:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200546:	1b7d                	addi	s6,s6,-1
ffffffffc0200548:	0167f7b3          	and	a5,a5,s6
ffffffffc020054c:	8dd5                	or	a1,a1,a3
ffffffffc020054e:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc0200550:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200554:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc0200556:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed9a4d>
ffffffffc020055a:	10f59163          	bne	a1,a5,ffffffffc020065c <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc020055e:	471c                	lw	a5,8(a4)
ffffffffc0200560:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc0200562:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200564:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200568:	0086d51b          	srliw	a0,a3,0x8
ffffffffc020056c:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200570:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200574:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200578:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020057c:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200580:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200584:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200588:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020058c:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020058e:	01146433          	or	s0,s0,a7
ffffffffc0200592:	0086969b          	slliw	a3,a3,0x8
ffffffffc0200596:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020059a:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020059c:	0087979b          	slliw	a5,a5,0x8
ffffffffc02005a0:	8c49                	or	s0,s0,a0
ffffffffc02005a2:	0166f6b3          	and	a3,a3,s6
ffffffffc02005a6:	00ca6a33          	or	s4,s4,a2
ffffffffc02005aa:	0167f7b3          	and	a5,a5,s6
ffffffffc02005ae:	8c55                	or	s0,s0,a3
ffffffffc02005b0:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02005b4:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02005b6:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02005b8:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02005ba:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02005be:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02005c0:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005c2:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc02005c6:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02005c8:	00002917          	auipc	s2,0x2
ffffffffc02005cc:	d4890913          	addi	s2,s2,-696 # ffffffffc0202310 <commands+0x110>
ffffffffc02005d0:	49bd                	li	s3,15
        switch (token) {
ffffffffc02005d2:	4d91                	li	s11,4
ffffffffc02005d4:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02005d6:	00002497          	auipc	s1,0x2
ffffffffc02005da:	d3248493          	addi	s1,s1,-718 # ffffffffc0202308 <commands+0x108>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc02005de:	000a2703          	lw	a4,0(s4)
ffffffffc02005e2:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005e6:	0087569b          	srliw	a3,a4,0x8
ffffffffc02005ea:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005ee:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005f2:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005f6:	0107571b          	srliw	a4,a4,0x10
ffffffffc02005fa:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005fc:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200600:	0087171b          	slliw	a4,a4,0x8
ffffffffc0200604:	8fd5                	or	a5,a5,a3
ffffffffc0200606:	00eb7733          	and	a4,s6,a4
ffffffffc020060a:	8fd9                	or	a5,a5,a4
ffffffffc020060c:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc020060e:	09778c63          	beq	a5,s7,ffffffffc02006a6 <dtb_init+0x1ee>
ffffffffc0200612:	00fbea63          	bltu	s7,a5,ffffffffc0200626 <dtb_init+0x16e>
ffffffffc0200616:	07a78663          	beq	a5,s10,ffffffffc0200682 <dtb_init+0x1ca>
ffffffffc020061a:	4709                	li	a4,2
ffffffffc020061c:	00e79763          	bne	a5,a4,ffffffffc020062a <dtb_init+0x172>
ffffffffc0200620:	4c81                	li	s9,0
ffffffffc0200622:	8a56                	mv	s4,s5
ffffffffc0200624:	bf6d                	j	ffffffffc02005de <dtb_init+0x126>
ffffffffc0200626:	ffb78ee3          	beq	a5,s11,ffffffffc0200622 <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc020062a:	00002517          	auipc	a0,0x2
ffffffffc020062e:	d5e50513          	addi	a0,a0,-674 # ffffffffc0202388 <commands+0x188>
ffffffffc0200632:	ae1ff0ef          	jal	ra,ffffffffc0200112 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc0200636:	00002517          	auipc	a0,0x2
ffffffffc020063a:	d8a50513          	addi	a0,a0,-630 # ffffffffc02023c0 <commands+0x1c0>
}
ffffffffc020063e:	7446                	ld	s0,112(sp)
ffffffffc0200640:	70e6                	ld	ra,120(sp)
ffffffffc0200642:	74a6                	ld	s1,104(sp)
ffffffffc0200644:	7906                	ld	s2,96(sp)
ffffffffc0200646:	69e6                	ld	s3,88(sp)
ffffffffc0200648:	6a46                	ld	s4,80(sp)
ffffffffc020064a:	6aa6                	ld	s5,72(sp)
ffffffffc020064c:	6b06                	ld	s6,64(sp)
ffffffffc020064e:	7be2                	ld	s7,56(sp)
ffffffffc0200650:	7c42                	ld	s8,48(sp)
ffffffffc0200652:	7ca2                	ld	s9,40(sp)
ffffffffc0200654:	7d02                	ld	s10,32(sp)
ffffffffc0200656:	6de2                	ld	s11,24(sp)
ffffffffc0200658:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc020065a:	bc65                	j	ffffffffc0200112 <cprintf>
}
ffffffffc020065c:	7446                	ld	s0,112(sp)
ffffffffc020065e:	70e6                	ld	ra,120(sp)
ffffffffc0200660:	74a6                	ld	s1,104(sp)
ffffffffc0200662:	7906                	ld	s2,96(sp)
ffffffffc0200664:	69e6                	ld	s3,88(sp)
ffffffffc0200666:	6a46                	ld	s4,80(sp)
ffffffffc0200668:	6aa6                	ld	s5,72(sp)
ffffffffc020066a:	6b06                	ld	s6,64(sp)
ffffffffc020066c:	7be2                	ld	s7,56(sp)
ffffffffc020066e:	7c42                	ld	s8,48(sp)
ffffffffc0200670:	7ca2                	ld	s9,40(sp)
ffffffffc0200672:	7d02                	ld	s10,32(sp)
ffffffffc0200674:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200676:	00002517          	auipc	a0,0x2
ffffffffc020067a:	c6a50513          	addi	a0,a0,-918 # ffffffffc02022e0 <commands+0xe0>
}
ffffffffc020067e:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200680:	bc49                	j	ffffffffc0200112 <cprintf>
                int name_len = strlen(name);
ffffffffc0200682:	8556                	mv	a0,s5
ffffffffc0200684:	015010ef          	jal	ra,ffffffffc0201e98 <strlen>
ffffffffc0200688:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020068a:	4619                	li	a2,6
ffffffffc020068c:	85a6                	mv	a1,s1
ffffffffc020068e:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc0200690:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200692:	05b010ef          	jal	ra,ffffffffc0201eec <strncmp>
ffffffffc0200696:	e111                	bnez	a0,ffffffffc020069a <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc0200698:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc020069a:	0a91                	addi	s5,s5,4
ffffffffc020069c:	9ad2                	add	s5,s5,s4
ffffffffc020069e:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc02006a2:	8a56                	mv	s4,s5
ffffffffc02006a4:	bf2d                	j	ffffffffc02005de <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc02006a6:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02006aa:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ae:	0087d71b          	srliw	a4,a5,0x8
ffffffffc02006b2:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006b6:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ba:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006be:	0107d79b          	srliw	a5,a5,0x10
ffffffffc02006c2:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006c6:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006ca:	0087979b          	slliw	a5,a5,0x8
ffffffffc02006ce:	00eaeab3          	or	s5,s5,a4
ffffffffc02006d2:	00fb77b3          	and	a5,s6,a5
ffffffffc02006d6:	00faeab3          	or	s5,s5,a5
ffffffffc02006da:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02006dc:	000c9c63          	bnez	s9,ffffffffc02006f4 <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc02006e0:	1a82                	slli	s5,s5,0x20
ffffffffc02006e2:	00368793          	addi	a5,a3,3
ffffffffc02006e6:	020ada93          	srli	s5,s5,0x20
ffffffffc02006ea:	9abe                	add	s5,s5,a5
ffffffffc02006ec:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc02006f0:	8a56                	mv	s4,s5
ffffffffc02006f2:	b5f5                	j	ffffffffc02005de <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02006f4:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02006f8:	85ca                	mv	a1,s2
ffffffffc02006fa:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006fc:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200700:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200704:	0187971b          	slliw	a4,a5,0x18
ffffffffc0200708:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020070c:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200710:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200712:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200716:	0087979b          	slliw	a5,a5,0x8
ffffffffc020071a:	8d59                	or	a0,a0,a4
ffffffffc020071c:	00fb77b3          	and	a5,s6,a5
ffffffffc0200720:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc0200722:	1502                	slli	a0,a0,0x20
ffffffffc0200724:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200726:	9522                	add	a0,a0,s0
ffffffffc0200728:	7a6010ef          	jal	ra,ffffffffc0201ece <strcmp>
ffffffffc020072c:	66a2                	ld	a3,8(sp)
ffffffffc020072e:	f94d                	bnez	a0,ffffffffc02006e0 <dtb_init+0x228>
ffffffffc0200730:	fb59f8e3          	bgeu	s3,s5,ffffffffc02006e0 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc0200734:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc0200738:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc020073c:	00002517          	auipc	a0,0x2
ffffffffc0200740:	bdc50513          	addi	a0,a0,-1060 # ffffffffc0202318 <commands+0x118>
           fdt32_to_cpu(x >> 32);
ffffffffc0200744:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200748:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc020074c:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200750:	0187de1b          	srliw	t3,a5,0x18
ffffffffc0200754:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200758:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020075c:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200760:	0187d693          	srli	a3,a5,0x18
ffffffffc0200764:	01861f1b          	slliw	t5,a2,0x18
ffffffffc0200768:	0087579b          	srliw	a5,a4,0x8
ffffffffc020076c:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200770:	0106561b          	srliw	a2,a2,0x10
ffffffffc0200774:	010f6f33          	or	t5,t5,a6
ffffffffc0200778:	0187529b          	srliw	t0,a4,0x18
ffffffffc020077c:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200780:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200784:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200788:	0186f6b3          	and	a3,a3,s8
ffffffffc020078c:	01859e1b          	slliw	t3,a1,0x18
ffffffffc0200790:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200794:	0107581b          	srliw	a6,a4,0x10
ffffffffc0200798:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020079c:	8361                	srli	a4,a4,0x18
ffffffffc020079e:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007a2:	0105d59b          	srliw	a1,a1,0x10
ffffffffc02007a6:	01e6e6b3          	or	a3,a3,t5
ffffffffc02007aa:	00cb7633          	and	a2,s6,a2
ffffffffc02007ae:	0088181b          	slliw	a6,a6,0x8
ffffffffc02007b2:	0085959b          	slliw	a1,a1,0x8
ffffffffc02007b6:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007ba:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007be:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007c2:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007c6:	0088989b          	slliw	a7,a7,0x8
ffffffffc02007ca:	011b78b3          	and	a7,s6,a7
ffffffffc02007ce:	005eeeb3          	or	t4,t4,t0
ffffffffc02007d2:	00c6e733          	or	a4,a3,a2
ffffffffc02007d6:	006c6c33          	or	s8,s8,t1
ffffffffc02007da:	010b76b3          	and	a3,s6,a6
ffffffffc02007de:	00bb7b33          	and	s6,s6,a1
ffffffffc02007e2:	01d7e7b3          	or	a5,a5,t4
ffffffffc02007e6:	016c6b33          	or	s6,s8,s6
ffffffffc02007ea:	01146433          	or	s0,s0,a7
ffffffffc02007ee:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc02007f0:	1702                	slli	a4,a4,0x20
ffffffffc02007f2:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02007f4:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc02007f6:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02007f8:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc02007fa:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02007fe:	0167eb33          	or	s6,a5,s6
ffffffffc0200802:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200804:	90fff0ef          	jal	ra,ffffffffc0200112 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc0200808:	85a2                	mv	a1,s0
ffffffffc020080a:	00002517          	auipc	a0,0x2
ffffffffc020080e:	b2e50513          	addi	a0,a0,-1234 # ffffffffc0202338 <commands+0x138>
ffffffffc0200812:	901ff0ef          	jal	ra,ffffffffc0200112 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc0200816:	014b5613          	srli	a2,s6,0x14
ffffffffc020081a:	85da                	mv	a1,s6
ffffffffc020081c:	00002517          	auipc	a0,0x2
ffffffffc0200820:	b3450513          	addi	a0,a0,-1228 # ffffffffc0202350 <commands+0x150>
ffffffffc0200824:	8efff0ef          	jal	ra,ffffffffc0200112 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200828:	008b05b3          	add	a1,s6,s0
ffffffffc020082c:	15fd                	addi	a1,a1,-1
ffffffffc020082e:	00002517          	auipc	a0,0x2
ffffffffc0200832:	b4250513          	addi	a0,a0,-1214 # ffffffffc0202370 <commands+0x170>
ffffffffc0200836:	8ddff0ef          	jal	ra,ffffffffc0200112 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc020083a:	00002517          	auipc	a0,0x2
ffffffffc020083e:	b8650513          	addi	a0,a0,-1146 # ffffffffc02023c0 <commands+0x1c0>
        memory_base = mem_base;
ffffffffc0200842:	00006797          	auipc	a5,0x6
ffffffffc0200846:	c087b723          	sd	s0,-1010(a5) # ffffffffc0206450 <memory_base>
        memory_size = mem_size;
ffffffffc020084a:	00006797          	auipc	a5,0x6
ffffffffc020084e:	c167b723          	sd	s6,-1010(a5) # ffffffffc0206458 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc0200852:	b3f5                	j	ffffffffc020063e <dtb_init+0x186>

ffffffffc0200854 <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc0200854:	00006517          	auipc	a0,0x6
ffffffffc0200858:	bfc53503          	ld	a0,-1028(a0) # ffffffffc0206450 <memory_base>
ffffffffc020085c:	8082                	ret

ffffffffc020085e <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc020085e:	00006517          	auipc	a0,0x6
ffffffffc0200862:	bfa53503          	ld	a0,-1030(a0) # ffffffffc0206458 <memory_size>
ffffffffc0200866:	8082                	ret

ffffffffc0200868 <intr_enable>:
- 即使在 sie 中使能了特定中断源，如果 SSTATUS_SIE 为 0，所有中断都会被屏蔽
- 当中断发生时，硬件会自动清除 SIE 位并保存到 SPIE 位，防止中断嵌套； sret 返回时会从 SPIE 恢复 SIE
*/
// 中断使能状态位置位
// SSTATUS_SPP本来就是0，无需置位
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200868:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc020086c:	8082                	ret

ffffffffc020086e <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc020086e:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0200872:	8082                	ret

ffffffffc0200874 <idt_init>:
     */

    extern void __alltraps(void);
    /* Set sup0 scratch register to 0, indicating to exception vector
       that we are presently executing in the kernel */
    write_csr(sscratch, 0);  // 中断后S态接管
ffffffffc0200874:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);  // 中断后全部跳转至__alltraps
ffffffffc0200878:	00000797          	auipc	a5,0x0
ffffffffc020087c:	3b878793          	addi	a5,a5,952 # ffffffffc0200c30 <__alltraps>
ffffffffc0200880:	10579073          	csrw	stvec,a5
}
ffffffffc0200884:	8082                	ret

ffffffffc0200886 <print_regs>:
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200886:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
ffffffffc0200888:	1141                	addi	sp,sp,-16
ffffffffc020088a:	e022                	sd	s0,0(sp)
ffffffffc020088c:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020088e:	00002517          	auipc	a0,0x2
ffffffffc0200892:	b4a50513          	addi	a0,a0,-1206 # ffffffffc02023d8 <commands+0x1d8>
void print_regs(struct pushregs *gpr) {
ffffffffc0200896:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200898:	87bff0ef          	jal	ra,ffffffffc0200112 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc020089c:	640c                	ld	a1,8(s0)
ffffffffc020089e:	00002517          	auipc	a0,0x2
ffffffffc02008a2:	b5250513          	addi	a0,a0,-1198 # ffffffffc02023f0 <commands+0x1f0>
ffffffffc02008a6:	86dff0ef          	jal	ra,ffffffffc0200112 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02008aa:	680c                	ld	a1,16(s0)
ffffffffc02008ac:	00002517          	auipc	a0,0x2
ffffffffc02008b0:	b5c50513          	addi	a0,a0,-1188 # ffffffffc0202408 <commands+0x208>
ffffffffc02008b4:	85fff0ef          	jal	ra,ffffffffc0200112 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc02008b8:	6c0c                	ld	a1,24(s0)
ffffffffc02008ba:	00002517          	auipc	a0,0x2
ffffffffc02008be:	b6650513          	addi	a0,a0,-1178 # ffffffffc0202420 <commands+0x220>
ffffffffc02008c2:	851ff0ef          	jal	ra,ffffffffc0200112 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02008c6:	700c                	ld	a1,32(s0)
ffffffffc02008c8:	00002517          	auipc	a0,0x2
ffffffffc02008cc:	b7050513          	addi	a0,a0,-1168 # ffffffffc0202438 <commands+0x238>
ffffffffc02008d0:	843ff0ef          	jal	ra,ffffffffc0200112 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02008d4:	740c                	ld	a1,40(s0)
ffffffffc02008d6:	00002517          	auipc	a0,0x2
ffffffffc02008da:	b7a50513          	addi	a0,a0,-1158 # ffffffffc0202450 <commands+0x250>
ffffffffc02008de:	835ff0ef          	jal	ra,ffffffffc0200112 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02008e2:	780c                	ld	a1,48(s0)
ffffffffc02008e4:	00002517          	auipc	a0,0x2
ffffffffc02008e8:	b8450513          	addi	a0,a0,-1148 # ffffffffc0202468 <commands+0x268>
ffffffffc02008ec:	827ff0ef          	jal	ra,ffffffffc0200112 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02008f0:	7c0c                	ld	a1,56(s0)
ffffffffc02008f2:	00002517          	auipc	a0,0x2
ffffffffc02008f6:	b8e50513          	addi	a0,a0,-1138 # ffffffffc0202480 <commands+0x280>
ffffffffc02008fa:	819ff0ef          	jal	ra,ffffffffc0200112 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02008fe:	602c                	ld	a1,64(s0)
ffffffffc0200900:	00002517          	auipc	a0,0x2
ffffffffc0200904:	b9850513          	addi	a0,a0,-1128 # ffffffffc0202498 <commands+0x298>
ffffffffc0200908:	80bff0ef          	jal	ra,ffffffffc0200112 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc020090c:	642c                	ld	a1,72(s0)
ffffffffc020090e:	00002517          	auipc	a0,0x2
ffffffffc0200912:	ba250513          	addi	a0,a0,-1118 # ffffffffc02024b0 <commands+0x2b0>
ffffffffc0200916:	ffcff0ef          	jal	ra,ffffffffc0200112 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc020091a:	682c                	ld	a1,80(s0)
ffffffffc020091c:	00002517          	auipc	a0,0x2
ffffffffc0200920:	bac50513          	addi	a0,a0,-1108 # ffffffffc02024c8 <commands+0x2c8>
ffffffffc0200924:	feeff0ef          	jal	ra,ffffffffc0200112 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200928:	6c2c                	ld	a1,88(s0)
ffffffffc020092a:	00002517          	auipc	a0,0x2
ffffffffc020092e:	bb650513          	addi	a0,a0,-1098 # ffffffffc02024e0 <commands+0x2e0>
ffffffffc0200932:	fe0ff0ef          	jal	ra,ffffffffc0200112 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200936:	702c                	ld	a1,96(s0)
ffffffffc0200938:	00002517          	auipc	a0,0x2
ffffffffc020093c:	bc050513          	addi	a0,a0,-1088 # ffffffffc02024f8 <commands+0x2f8>
ffffffffc0200940:	fd2ff0ef          	jal	ra,ffffffffc0200112 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200944:	742c                	ld	a1,104(s0)
ffffffffc0200946:	00002517          	auipc	a0,0x2
ffffffffc020094a:	bca50513          	addi	a0,a0,-1078 # ffffffffc0202510 <commands+0x310>
ffffffffc020094e:	fc4ff0ef          	jal	ra,ffffffffc0200112 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200952:	782c                	ld	a1,112(s0)
ffffffffc0200954:	00002517          	auipc	a0,0x2
ffffffffc0200958:	bd450513          	addi	a0,a0,-1068 # ffffffffc0202528 <commands+0x328>
ffffffffc020095c:	fb6ff0ef          	jal	ra,ffffffffc0200112 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200960:	7c2c                	ld	a1,120(s0)
ffffffffc0200962:	00002517          	auipc	a0,0x2
ffffffffc0200966:	bde50513          	addi	a0,a0,-1058 # ffffffffc0202540 <commands+0x340>
ffffffffc020096a:	fa8ff0ef          	jal	ra,ffffffffc0200112 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc020096e:	604c                	ld	a1,128(s0)
ffffffffc0200970:	00002517          	auipc	a0,0x2
ffffffffc0200974:	be850513          	addi	a0,a0,-1048 # ffffffffc0202558 <commands+0x358>
ffffffffc0200978:	f9aff0ef          	jal	ra,ffffffffc0200112 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc020097c:	644c                	ld	a1,136(s0)
ffffffffc020097e:	00002517          	auipc	a0,0x2
ffffffffc0200982:	bf250513          	addi	a0,a0,-1038 # ffffffffc0202570 <commands+0x370>
ffffffffc0200986:	f8cff0ef          	jal	ra,ffffffffc0200112 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc020098a:	684c                	ld	a1,144(s0)
ffffffffc020098c:	00002517          	auipc	a0,0x2
ffffffffc0200990:	bfc50513          	addi	a0,a0,-1028 # ffffffffc0202588 <commands+0x388>
ffffffffc0200994:	f7eff0ef          	jal	ra,ffffffffc0200112 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200998:	6c4c                	ld	a1,152(s0)
ffffffffc020099a:	00002517          	auipc	a0,0x2
ffffffffc020099e:	c0650513          	addi	a0,a0,-1018 # ffffffffc02025a0 <commands+0x3a0>
ffffffffc02009a2:	f70ff0ef          	jal	ra,ffffffffc0200112 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc02009a6:	704c                	ld	a1,160(s0)
ffffffffc02009a8:	00002517          	auipc	a0,0x2
ffffffffc02009ac:	c1050513          	addi	a0,a0,-1008 # ffffffffc02025b8 <commands+0x3b8>
ffffffffc02009b0:	f62ff0ef          	jal	ra,ffffffffc0200112 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc02009b4:	744c                	ld	a1,168(s0)
ffffffffc02009b6:	00002517          	auipc	a0,0x2
ffffffffc02009ba:	c1a50513          	addi	a0,a0,-998 # ffffffffc02025d0 <commands+0x3d0>
ffffffffc02009be:	f54ff0ef          	jal	ra,ffffffffc0200112 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02009c2:	784c                	ld	a1,176(s0)
ffffffffc02009c4:	00002517          	auipc	a0,0x2
ffffffffc02009c8:	c2450513          	addi	a0,a0,-988 # ffffffffc02025e8 <commands+0x3e8>
ffffffffc02009cc:	f46ff0ef          	jal	ra,ffffffffc0200112 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02009d0:	7c4c                	ld	a1,184(s0)
ffffffffc02009d2:	00002517          	auipc	a0,0x2
ffffffffc02009d6:	c2e50513          	addi	a0,a0,-978 # ffffffffc0202600 <commands+0x400>
ffffffffc02009da:	f38ff0ef          	jal	ra,ffffffffc0200112 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02009de:	606c                	ld	a1,192(s0)
ffffffffc02009e0:	00002517          	auipc	a0,0x2
ffffffffc02009e4:	c3850513          	addi	a0,a0,-968 # ffffffffc0202618 <commands+0x418>
ffffffffc02009e8:	f2aff0ef          	jal	ra,ffffffffc0200112 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02009ec:	646c                	ld	a1,200(s0)
ffffffffc02009ee:	00002517          	auipc	a0,0x2
ffffffffc02009f2:	c4250513          	addi	a0,a0,-958 # ffffffffc0202630 <commands+0x430>
ffffffffc02009f6:	f1cff0ef          	jal	ra,ffffffffc0200112 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02009fa:	686c                	ld	a1,208(s0)
ffffffffc02009fc:	00002517          	auipc	a0,0x2
ffffffffc0200a00:	c4c50513          	addi	a0,a0,-948 # ffffffffc0202648 <commands+0x448>
ffffffffc0200a04:	f0eff0ef          	jal	ra,ffffffffc0200112 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200a08:	6c6c                	ld	a1,216(s0)
ffffffffc0200a0a:	00002517          	auipc	a0,0x2
ffffffffc0200a0e:	c5650513          	addi	a0,a0,-938 # ffffffffc0202660 <commands+0x460>
ffffffffc0200a12:	f00ff0ef          	jal	ra,ffffffffc0200112 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200a16:	706c                	ld	a1,224(s0)
ffffffffc0200a18:	00002517          	auipc	a0,0x2
ffffffffc0200a1c:	c6050513          	addi	a0,a0,-928 # ffffffffc0202678 <commands+0x478>
ffffffffc0200a20:	ef2ff0ef          	jal	ra,ffffffffc0200112 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200a24:	746c                	ld	a1,232(s0)
ffffffffc0200a26:	00002517          	auipc	a0,0x2
ffffffffc0200a2a:	c6a50513          	addi	a0,a0,-918 # ffffffffc0202690 <commands+0x490>
ffffffffc0200a2e:	ee4ff0ef          	jal	ra,ffffffffc0200112 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200a32:	786c                	ld	a1,240(s0)
ffffffffc0200a34:	00002517          	auipc	a0,0x2
ffffffffc0200a38:	c7450513          	addi	a0,a0,-908 # ffffffffc02026a8 <commands+0x4a8>
ffffffffc0200a3c:	ed6ff0ef          	jal	ra,ffffffffc0200112 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a40:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200a42:	6402                	ld	s0,0(sp)
ffffffffc0200a44:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a46:	00002517          	auipc	a0,0x2
ffffffffc0200a4a:	c7a50513          	addi	a0,a0,-902 # ffffffffc02026c0 <commands+0x4c0>
}
ffffffffc0200a4e:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a50:	ec2ff06f          	j	ffffffffc0200112 <cprintf>

ffffffffc0200a54 <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
ffffffffc0200a54:	1141                	addi	sp,sp,-16
ffffffffc0200a56:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a58:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
ffffffffc0200a5a:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a5c:	00002517          	auipc	a0,0x2
ffffffffc0200a60:	c7c50513          	addi	a0,a0,-900 # ffffffffc02026d8 <commands+0x4d8>
void print_trapframe(struct trapframe *tf) {
ffffffffc0200a64:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a66:	eacff0ef          	jal	ra,ffffffffc0200112 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200a6a:	8522                	mv	a0,s0
ffffffffc0200a6c:	e1bff0ef          	jal	ra,ffffffffc0200886 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200a70:	10043583          	ld	a1,256(s0)
ffffffffc0200a74:	00002517          	auipc	a0,0x2
ffffffffc0200a78:	c7c50513          	addi	a0,a0,-900 # ffffffffc02026f0 <commands+0x4f0>
ffffffffc0200a7c:	e96ff0ef          	jal	ra,ffffffffc0200112 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200a80:	10843583          	ld	a1,264(s0)
ffffffffc0200a84:	00002517          	auipc	a0,0x2
ffffffffc0200a88:	c8450513          	addi	a0,a0,-892 # ffffffffc0202708 <commands+0x508>
ffffffffc0200a8c:	e86ff0ef          	jal	ra,ffffffffc0200112 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200a90:	11043583          	ld	a1,272(s0)
ffffffffc0200a94:	00002517          	auipc	a0,0x2
ffffffffc0200a98:	c8c50513          	addi	a0,a0,-884 # ffffffffc0202720 <commands+0x520>
ffffffffc0200a9c:	e76ff0ef          	jal	ra,ffffffffc0200112 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200aa0:	11843583          	ld	a1,280(s0)
}
ffffffffc0200aa4:	6402                	ld	s0,0(sp)
ffffffffc0200aa6:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200aa8:	00002517          	auipc	a0,0x2
ffffffffc0200aac:	c9050513          	addi	a0,a0,-880 # ffffffffc0202738 <commands+0x538>
}
ffffffffc0200ab0:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200ab2:	e60ff06f          	j	ffffffffc0200112 <cprintf>

ffffffffc0200ab6 <interrupt_handler>:

void interrupt_handler(struct trapframe *tf) {
    // interrupt_handler() 则用“清除最高位”的技巧取出具体中断号。
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc0200ab6:	11853783          	ld	a5,280(a0)
ffffffffc0200aba:	472d                	li	a4,11
ffffffffc0200abc:	0786                	slli	a5,a5,0x1
ffffffffc0200abe:	8385                	srli	a5,a5,0x1
ffffffffc0200ac0:	08f76363          	bltu	a4,a5,ffffffffc0200b46 <interrupt_handler+0x90>
ffffffffc0200ac4:	00002717          	auipc	a4,0x2
ffffffffc0200ac8:	d5470713          	addi	a4,a4,-684 # ffffffffc0202818 <commands+0x618>
ffffffffc0200acc:	078a                	slli	a5,a5,0x2
ffffffffc0200ace:	97ba                	add	a5,a5,a4
ffffffffc0200ad0:	439c                	lw	a5,0(a5)
ffffffffc0200ad2:	97ba                	add	a5,a5,a4
ffffffffc0200ad4:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc0200ad6:	00002517          	auipc	a0,0x2
ffffffffc0200ada:	cda50513          	addi	a0,a0,-806 # ffffffffc02027b0 <commands+0x5b0>
ffffffffc0200ade:	e34ff06f          	j	ffffffffc0200112 <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc0200ae2:	00002517          	auipc	a0,0x2
ffffffffc0200ae6:	cae50513          	addi	a0,a0,-850 # ffffffffc0202790 <commands+0x590>
ffffffffc0200aea:	e28ff06f          	j	ffffffffc0200112 <cprintf>
            cprintf("User software interrupt\n");
ffffffffc0200aee:	00002517          	auipc	a0,0x2
ffffffffc0200af2:	c6250513          	addi	a0,a0,-926 # ffffffffc0202750 <commands+0x550>
ffffffffc0200af6:	e1cff06f          	j	ffffffffc0200112 <cprintf>
            break;
        case IRQ_U_TIMER:
            cprintf("User Timer interrupt\n");
ffffffffc0200afa:	00002517          	auipc	a0,0x2
ffffffffc0200afe:	cd650513          	addi	a0,a0,-810 # ffffffffc02027d0 <commands+0x5d0>
ffffffffc0200b02:	e10ff06f          	j	ffffffffc0200112 <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc0200b06:	1141                	addi	sp,sp,-16
ffffffffc0200b08:	e406                	sd	ra,8(sp)
            /*(1)设置下次时钟中断- clock_set_next_event()
             *(2)计数器（ticks）加一
             *(3)当计数器加到100的时候，我们会输出一个`100ticks`表示我们触发了100次时钟中断，同时打印次数（num）加一
            * (4)判断打印次数，当打印次数为10时，调用<sbi.h>中的关机函数关机
            */
            clock_set_next_event();
ffffffffc0200b0a:	991ff0ef          	jal	ra,ffffffffc020049a <clock_set_next_event>
            ticks++;
ffffffffc0200b0e:	00006797          	auipc	a5,0x6
ffffffffc0200b12:	93a78793          	addi	a5,a5,-1734 # ffffffffc0206448 <ticks>
ffffffffc0200b16:	6398                	ld	a4,0(a5)
ffffffffc0200b18:	0705                	addi	a4,a4,1
ffffffffc0200b1a:	e398                	sd	a4,0(a5)
            if (ticks % TICK_NUM == 0) {
ffffffffc0200b1c:	639c                	ld	a5,0(a5)
ffffffffc0200b1e:	06400713          	li	a4,100
ffffffffc0200b22:	02e7f7b3          	remu	a5,a5,a4
ffffffffc0200b26:	c38d                	beqz	a5,ffffffffc0200b48 <interrupt_handler+0x92>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200b28:	60a2                	ld	ra,8(sp)
ffffffffc0200b2a:	0141                	addi	sp,sp,16
ffffffffc0200b2c:	8082                	ret
            cprintf("Supervisor external interrupt\n");
ffffffffc0200b2e:	00002517          	auipc	a0,0x2
ffffffffc0200b32:	cca50513          	addi	a0,a0,-822 # ffffffffc02027f8 <commands+0x5f8>
ffffffffc0200b36:	ddcff06f          	j	ffffffffc0200112 <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc0200b3a:	00002517          	auipc	a0,0x2
ffffffffc0200b3e:	c3650513          	addi	a0,a0,-970 # ffffffffc0202770 <commands+0x570>
ffffffffc0200b42:	dd0ff06f          	j	ffffffffc0200112 <cprintf>
            print_trapframe(tf);
ffffffffc0200b46:	b739                	j	ffffffffc0200a54 <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200b48:	06400593          	li	a1,100
ffffffffc0200b4c:	00002517          	auipc	a0,0x2
ffffffffc0200b50:	c9c50513          	addi	a0,a0,-868 # ffffffffc02027e8 <commands+0x5e8>
ffffffffc0200b54:	dbeff0ef          	jal	ra,ffffffffc0200112 <cprintf>
                num++;
ffffffffc0200b58:	00006717          	auipc	a4,0x6
ffffffffc0200b5c:	90870713          	addi	a4,a4,-1784 # ffffffffc0206460 <num.0>
ffffffffc0200b60:	431c                	lw	a5,0(a4)
                if (num == 10) {
ffffffffc0200b62:	46a9                	li	a3,10
                num++;
ffffffffc0200b64:	0017861b          	addiw	a2,a5,1
ffffffffc0200b68:	c310                	sw	a2,0(a4)
                if (num == 10) {
ffffffffc0200b6a:	fad61fe3          	bne	a2,a3,ffffffffc0200b28 <interrupt_handler+0x72>
}
ffffffffc0200b6e:	60a2                	ld	ra,8(sp)
ffffffffc0200b70:	0141                	addi	sp,sp,16
                    sbi_shutdown();
ffffffffc0200b72:	30c0106f          	j	ffffffffc0201e7e <sbi_shutdown>

ffffffffc0200b76 <exception_handler>:

void exception_handler(struct trapframe *tf) {
ffffffffc0200b76:	1101                	addi	sp,sp,-32
ffffffffc0200b78:	e822                	sd	s0,16(sp)
    switch (tf->cause) {
ffffffffc0200b7a:	11853403          	ld	s0,280(a0)
void exception_handler(struct trapframe *tf) {
ffffffffc0200b7e:	e426                	sd	s1,8(sp)
ffffffffc0200b80:	e04a                	sd	s2,0(sp)
ffffffffc0200b82:	ec06                	sd	ra,24(sp)
    switch (tf->cause) {
ffffffffc0200b84:	490d                	li	s2,3
void exception_handler(struct trapframe *tf) {
ffffffffc0200b86:	84aa                	mv	s1,a0
    switch (tf->cause) {
ffffffffc0200b88:	05240f63          	beq	s0,s2,ffffffffc0200be6 <exception_handler+0x70>
ffffffffc0200b8c:	04896363          	bltu	s2,s0,ffffffffc0200bd2 <exception_handler+0x5c>
ffffffffc0200b90:	4789                	li	a5,2
ffffffffc0200b92:	02f41a63          	bne	s0,a5,ffffffffc0200bc6 <exception_handler+0x50>
             /* LAB3 CHALLENGE3   2312326 范鼎辉 2311136 崔颖欣 2312585 解子萱  :  */
            /*(1)输出指令异常类型（ Illegal instruction）
             *(2)输出异常指令地址
             *(3)更新 tf->epc寄存器
            */
            cprintf("Exception type:Illegal instruction\n");
ffffffffc0200b96:	00002517          	auipc	a0,0x2
ffffffffc0200b9a:	cb250513          	addi	a0,a0,-846 # ffffffffc0202848 <commands+0x648>
ffffffffc0200b9e:	d74ff0ef          	jal	ra,ffffffffc0200112 <cprintf>
            cprintf("Illegal instruction caught at 0x%08x\n", tf->epc);
ffffffffc0200ba2:	1084b583          	ld	a1,264(s1)
ffffffffc0200ba6:	00002517          	auipc	a0,0x2
ffffffffc0200baa:	cca50513          	addi	a0,a0,-822 # ffffffffc0202870 <commands+0x670>
ffffffffc0200bae:	d64ff0ef          	jal	ra,ffffffffc0200112 <cprintf>
            {
                // 从异常指令地址 tf->epc 所指的内存中，读取16位值，并存入变量。
                uint16_t insn16 = *(uint16_t *)(tf->epc);
ffffffffc0200bb2:	1084b783          	ld	a5,264(s1)
                if ((insn16 & 0x3) != 0x3) {
ffffffffc0200bb6:	0007d703          	lhu	a4,0(a5)
ffffffffc0200bba:	8b0d                	andi	a4,a4,3
ffffffffc0200bbc:	05270a63          	beq	a4,s2,ffffffffc0200c10 <exception_handler+0x9a>
            cprintf("ebreak caught at 0x%08x\n", tf->epc);
            {
                // 从异常指令地址 tf->epc 所指的内存中，读取16位值，并存入变量。
                uint16_t insn16 = *(uint16_t *)(tf->epc);
                if ((insn16 & 0x3) != 0x3) {
                    tf->epc += 2;  // 压缩指令长度16位
ffffffffc0200bc0:	0789                	addi	a5,a5,2
ffffffffc0200bc2:	10f4b423          	sd	a5,264(s1)
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200bc6:	60e2                	ld	ra,24(sp)
ffffffffc0200bc8:	6442                	ld	s0,16(sp)
ffffffffc0200bca:	64a2                	ld	s1,8(sp)
ffffffffc0200bcc:	6902                	ld	s2,0(sp)
ffffffffc0200bce:	6105                	addi	sp,sp,32
ffffffffc0200bd0:	8082                	ret
    switch (tf->cause) {
ffffffffc0200bd2:	1471                	addi	s0,s0,-4
ffffffffc0200bd4:	479d                	li	a5,7
ffffffffc0200bd6:	fe87f8e3          	bgeu	a5,s0,ffffffffc0200bc6 <exception_handler+0x50>
}
ffffffffc0200bda:	6442                	ld	s0,16(sp)
ffffffffc0200bdc:	60e2                	ld	ra,24(sp)
ffffffffc0200bde:	64a2                	ld	s1,8(sp)
ffffffffc0200be0:	6902                	ld	s2,0(sp)
ffffffffc0200be2:	6105                	addi	sp,sp,32
            print_trapframe(tf);
ffffffffc0200be4:	bd85                	j	ffffffffc0200a54 <print_trapframe>
            cprintf("Exception type:breakpoint\n");
ffffffffc0200be6:	00002517          	auipc	a0,0x2
ffffffffc0200bea:	cb250513          	addi	a0,a0,-846 # ffffffffc0202898 <commands+0x698>
ffffffffc0200bee:	d24ff0ef          	jal	ra,ffffffffc0200112 <cprintf>
            cprintf("ebreak caught at 0x%08x\n", tf->epc);
ffffffffc0200bf2:	1084b583          	ld	a1,264(s1)
ffffffffc0200bf6:	00002517          	auipc	a0,0x2
ffffffffc0200bfa:	cc250513          	addi	a0,a0,-830 # ffffffffc02028b8 <commands+0x6b8>
ffffffffc0200bfe:	d14ff0ef          	jal	ra,ffffffffc0200112 <cprintf>
                uint16_t insn16 = *(uint16_t *)(tf->epc);
ffffffffc0200c02:	1084b783          	ld	a5,264(s1)
                if ((insn16 & 0x3) != 0x3) {
ffffffffc0200c06:	0007d703          	lhu	a4,0(a5)
ffffffffc0200c0a:	8b0d                	andi	a4,a4,3
ffffffffc0200c0c:	fa871ae3          	bne	a4,s0,ffffffffc0200bc0 <exception_handler+0x4a>
}
ffffffffc0200c10:	60e2                	ld	ra,24(sp)
ffffffffc0200c12:	6442                	ld	s0,16(sp)
                    tf->epc += 4;  // 标准指令长度32位
ffffffffc0200c14:	0791                	addi	a5,a5,4
ffffffffc0200c16:	10f4b423          	sd	a5,264(s1)
}
ffffffffc0200c1a:	6902                	ld	s2,0(sp)
ffffffffc0200c1c:	64a2                	ld	s1,8(sp)
ffffffffc0200c1e:	6105                	addi	sp,sp,32
ffffffffc0200c20:	8082                	ret

ffffffffc0200c22 <trap>:

static inline void trap_dispatch(struct trapframe *tf) {
    // 把 tf->cause 当作有符号数，检查最高位（硬件设为 1 表示“中断”）来区分中断与异常
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200c22:	11853783          	ld	a5,280(a0)
ffffffffc0200c26:	0007c363          	bltz	a5,ffffffffc0200c2c <trap+0xa>
        // interrupts
        interrupt_handler(tf);  // 中断
    } else {
        // exceptions
        exception_handler(tf);  // 异常
ffffffffc0200c2a:	b7b1                	j	ffffffffc0200b76 <exception_handler>
        interrupt_handler(tf);  // 中断
ffffffffc0200c2c:	b569                	j	ffffffffc0200ab6 <interrupt_handler>
	...

ffffffffc0200c30 <__alltraps>:
    .endm

    .globl __alltraps
    .align(2)
__alltraps:
    SAVE_ALL
ffffffffc0200c30:	14011073          	csrw	sscratch,sp
ffffffffc0200c34:	712d                	addi	sp,sp,-288
ffffffffc0200c36:	e002                	sd	zero,0(sp)
ffffffffc0200c38:	e406                	sd	ra,8(sp)
ffffffffc0200c3a:	ec0e                	sd	gp,24(sp)
ffffffffc0200c3c:	f012                	sd	tp,32(sp)
ffffffffc0200c3e:	f416                	sd	t0,40(sp)
ffffffffc0200c40:	f81a                	sd	t1,48(sp)
ffffffffc0200c42:	fc1e                	sd	t2,56(sp)
ffffffffc0200c44:	e0a2                	sd	s0,64(sp)
ffffffffc0200c46:	e4a6                	sd	s1,72(sp)
ffffffffc0200c48:	e8aa                	sd	a0,80(sp)
ffffffffc0200c4a:	ecae                	sd	a1,88(sp)
ffffffffc0200c4c:	f0b2                	sd	a2,96(sp)
ffffffffc0200c4e:	f4b6                	sd	a3,104(sp)
ffffffffc0200c50:	f8ba                	sd	a4,112(sp)
ffffffffc0200c52:	fcbe                	sd	a5,120(sp)
ffffffffc0200c54:	e142                	sd	a6,128(sp)
ffffffffc0200c56:	e546                	sd	a7,136(sp)
ffffffffc0200c58:	e94a                	sd	s2,144(sp)
ffffffffc0200c5a:	ed4e                	sd	s3,152(sp)
ffffffffc0200c5c:	f152                	sd	s4,160(sp)
ffffffffc0200c5e:	f556                	sd	s5,168(sp)
ffffffffc0200c60:	f95a                	sd	s6,176(sp)
ffffffffc0200c62:	fd5e                	sd	s7,184(sp)
ffffffffc0200c64:	e1e2                	sd	s8,192(sp)
ffffffffc0200c66:	e5e6                	sd	s9,200(sp)
ffffffffc0200c68:	e9ea                	sd	s10,208(sp)
ffffffffc0200c6a:	edee                	sd	s11,216(sp)
ffffffffc0200c6c:	f1f2                	sd	t3,224(sp)
ffffffffc0200c6e:	f5f6                	sd	t4,232(sp)
ffffffffc0200c70:	f9fa                	sd	t5,240(sp)
ffffffffc0200c72:	fdfe                	sd	t6,248(sp)
ffffffffc0200c74:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200c78:	100024f3          	csrr	s1,sstatus
ffffffffc0200c7c:	14102973          	csrr	s2,sepc
ffffffffc0200c80:	143029f3          	csrr	s3,stval
ffffffffc0200c84:	14202a73          	csrr	s4,scause
ffffffffc0200c88:	e822                	sd	s0,16(sp)
ffffffffc0200c8a:	e226                	sd	s1,256(sp)
ffffffffc0200c8c:	e64a                	sd	s2,264(sp)
ffffffffc0200c8e:	ea4e                	sd	s3,272(sp)
ffffffffc0200c90:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200c92:	850a                	mv	a0,sp
    jal trap
ffffffffc0200c94:	f8fff0ef          	jal	ra,ffffffffc0200c22 <trap>

ffffffffc0200c98 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200c98:	6492                	ld	s1,256(sp)
ffffffffc0200c9a:	6932                	ld	s2,264(sp)
ffffffffc0200c9c:	10049073          	csrw	sstatus,s1
ffffffffc0200ca0:	14191073          	csrw	sepc,s2
ffffffffc0200ca4:	60a2                	ld	ra,8(sp)
ffffffffc0200ca6:	61e2                	ld	gp,24(sp)
ffffffffc0200ca8:	7202                	ld	tp,32(sp)
ffffffffc0200caa:	72a2                	ld	t0,40(sp)
ffffffffc0200cac:	7342                	ld	t1,48(sp)
ffffffffc0200cae:	73e2                	ld	t2,56(sp)
ffffffffc0200cb0:	6406                	ld	s0,64(sp)
ffffffffc0200cb2:	64a6                	ld	s1,72(sp)
ffffffffc0200cb4:	6546                	ld	a0,80(sp)
ffffffffc0200cb6:	65e6                	ld	a1,88(sp)
ffffffffc0200cb8:	7606                	ld	a2,96(sp)
ffffffffc0200cba:	76a6                	ld	a3,104(sp)
ffffffffc0200cbc:	7746                	ld	a4,112(sp)
ffffffffc0200cbe:	77e6                	ld	a5,120(sp)
ffffffffc0200cc0:	680a                	ld	a6,128(sp)
ffffffffc0200cc2:	68aa                	ld	a7,136(sp)
ffffffffc0200cc4:	694a                	ld	s2,144(sp)
ffffffffc0200cc6:	69ea                	ld	s3,152(sp)
ffffffffc0200cc8:	7a0a                	ld	s4,160(sp)
ffffffffc0200cca:	7aaa                	ld	s5,168(sp)
ffffffffc0200ccc:	7b4a                	ld	s6,176(sp)
ffffffffc0200cce:	7bea                	ld	s7,184(sp)
ffffffffc0200cd0:	6c0e                	ld	s8,192(sp)
ffffffffc0200cd2:	6cae                	ld	s9,200(sp)
ffffffffc0200cd4:	6d4e                	ld	s10,208(sp)
ffffffffc0200cd6:	6dee                	ld	s11,216(sp)
ffffffffc0200cd8:	7e0e                	ld	t3,224(sp)
ffffffffc0200cda:	7eae                	ld	t4,232(sp)
ffffffffc0200cdc:	7f4e                	ld	t5,240(sp)
ffffffffc0200cde:	7fee                	ld	t6,248(sp)
ffffffffc0200ce0:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200ce2:	10200073          	sret

ffffffffc0200ce6 <best_fit_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200ce6:	00005797          	auipc	a5,0x5
ffffffffc0200cea:	34278793          	addi	a5,a5,834 # ffffffffc0206028 <free_area>
ffffffffc0200cee:	e79c                	sd	a5,8(a5)
ffffffffc0200cf0:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
best_fit_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200cf2:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200cf6:	8082                	ret

ffffffffc0200cf8 <best_fit_nr_free_pages>:
}

static size_t
best_fit_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200cf8:	00005517          	auipc	a0,0x5
ffffffffc0200cfc:	34056503          	lwu	a0,832(a0) # ffffffffc0206038 <free_area+0x10>
ffffffffc0200d00:	8082                	ret

ffffffffc0200d02 <best_fit_alloc_pages>:
    assert(n > 0);
ffffffffc0200d02:	c155                	beqz	a0,ffffffffc0200da6 <best_fit_alloc_pages+0xa4>
    if (n > nr_free) {
ffffffffc0200d04:	00005617          	auipc	a2,0x5
ffffffffc0200d08:	32460613          	addi	a2,a2,804 # ffffffffc0206028 <free_area>
ffffffffc0200d0c:	01062803          	lw	a6,16(a2)
ffffffffc0200d10:	86aa                	mv	a3,a0
ffffffffc0200d12:	02081793          	slli	a5,a6,0x20
ffffffffc0200d16:	9381                	srli	a5,a5,0x20
ffffffffc0200d18:	08a7e563          	bltu	a5,a0,ffffffffc0200da2 <best_fit_alloc_pages+0xa0>
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200d1c:	661c                	ld	a5,8(a2)
    size_t min_size = nr_free + 1;
ffffffffc0200d1e:	0018059b          	addiw	a1,a6,1
ffffffffc0200d22:	1582                	slli	a1,a1,0x20
ffffffffc0200d24:	9181                	srli	a1,a1,0x20
    struct Page *page = NULL;
ffffffffc0200d26:	4501                	li	a0,0
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200d28:	06c78c63          	beq	a5,a2,ffffffffc0200da0 <best_fit_alloc_pages+0x9e>
        if (p->property >= n) {
ffffffffc0200d2c:	ff87e703          	lwu	a4,-8(a5)
ffffffffc0200d30:	00d76863          	bltu	a4,a3,ffffffffc0200d40 <best_fit_alloc_pages+0x3e>
            if (p->property - n < min_size){
ffffffffc0200d34:	8f15                	sub	a4,a4,a3
ffffffffc0200d36:	00b77563          	bgeu	a4,a1,ffffffffc0200d40 <best_fit_alloc_pages+0x3e>
        struct Page *p = le2page(le, page_link);
ffffffffc0200d3a:	fe878513          	addi	a0,a5,-24
ffffffffc0200d3e:	85ba                	mv	a1,a4
ffffffffc0200d40:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200d42:	fec795e3          	bne	a5,a2,ffffffffc0200d2c <best_fit_alloc_pages+0x2a>
    if (page != NULL) {
ffffffffc0200d46:	cd29                	beqz	a0,ffffffffc0200da0 <best_fit_alloc_pages+0x9e>
    __list_del(listelm->prev, listelm->next);
ffffffffc0200d48:	711c                	ld	a5,32(a0)
 * list_prev - get the previous entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_prev(list_entry_t *listelm) {
    return listelm->prev;
ffffffffc0200d4a:	6d18                	ld	a4,24(a0)
        if (page->property > n) {
ffffffffc0200d4c:	490c                	lw	a1,16(a0)
            p->property = page->property - n;
ffffffffc0200d4e:	0006889b          	sext.w	a7,a3
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0200d52:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0200d54:	e398                	sd	a4,0(a5)
        if (page->property > n) {
ffffffffc0200d56:	02059793          	slli	a5,a1,0x20
ffffffffc0200d5a:	9381                	srli	a5,a5,0x20
ffffffffc0200d5c:	02f6f863          	bgeu	a3,a5,ffffffffc0200d8c <best_fit_alloc_pages+0x8a>
            struct Page *p = page + n;
ffffffffc0200d60:	00269793          	slli	a5,a3,0x2
ffffffffc0200d64:	97b6                	add	a5,a5,a3
ffffffffc0200d66:	078e                	slli	a5,a5,0x3
ffffffffc0200d68:	97aa                	add	a5,a5,a0
            p->property = page->property - n;
ffffffffc0200d6a:	411585bb          	subw	a1,a1,a7
ffffffffc0200d6e:	cb8c                	sw	a1,16(a5)
 *
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void set_bit(int nr, volatile void *addr) {
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0200d70:	4689                	li	a3,2
ffffffffc0200d72:	00878593          	addi	a1,a5,8
ffffffffc0200d76:	40d5b02f          	amoor.d	zero,a3,(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200d7a:	6714                	ld	a3,8(a4)
            list_add(prev, &(p->page_link));
ffffffffc0200d7c:	01878593          	addi	a1,a5,24
        nr_free -= n;
ffffffffc0200d80:	01062803          	lw	a6,16(a2)
    prev->next = next->prev = elm;
ffffffffc0200d84:	e28c                	sd	a1,0(a3)
ffffffffc0200d86:	e70c                	sd	a1,8(a4)
    elm->next = next;
ffffffffc0200d88:	f394                	sd	a3,32(a5)
    elm->prev = prev;
ffffffffc0200d8a:	ef98                	sd	a4,24(a5)
ffffffffc0200d8c:	4118083b          	subw	a6,a6,a7
ffffffffc0200d90:	01062823          	sw	a6,16(a2)
 * clear_bit - Atomically clears a bit in memory
 * @nr:     the bit to clear
 * @addr:   the address to start counting from
 * */
static inline void clear_bit(int nr, volatile void *addr) {
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0200d94:	57f5                	li	a5,-3
ffffffffc0200d96:	00850713          	addi	a4,a0,8
ffffffffc0200d9a:	60f7302f          	amoand.d	zero,a5,(a4)
}
ffffffffc0200d9e:	8082                	ret
}
ffffffffc0200da0:	8082                	ret
        return NULL;
ffffffffc0200da2:	4501                	li	a0,0
ffffffffc0200da4:	8082                	ret
best_fit_alloc_pages(size_t n) {
ffffffffc0200da6:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0200da8:	00002697          	auipc	a3,0x2
ffffffffc0200dac:	b3068693          	addi	a3,a3,-1232 # ffffffffc02028d8 <commands+0x6d8>
ffffffffc0200db0:	00002617          	auipc	a2,0x2
ffffffffc0200db4:	b3060613          	addi	a2,a2,-1232 # ffffffffc02028e0 <commands+0x6e0>
ffffffffc0200db8:	06b00593          	li	a1,107
ffffffffc0200dbc:	00002517          	auipc	a0,0x2
ffffffffc0200dc0:	b3c50513          	addi	a0,a0,-1220 # ffffffffc02028f8 <commands+0x6f8>
best_fit_alloc_pages(size_t n) {
ffffffffc0200dc4:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200dc6:	e46ff0ef          	jal	ra,ffffffffc020040c <__panic>

ffffffffc0200dca <best_fit_check>:
}

// LAB2: below code is used to check the best fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
best_fit_check(void) {
ffffffffc0200dca:	715d                	addi	sp,sp,-80
ffffffffc0200dcc:	e0a2                	sd	s0,64(sp)
    return listelm->next;
ffffffffc0200dce:	00005417          	auipc	s0,0x5
ffffffffc0200dd2:	25a40413          	addi	s0,s0,602 # ffffffffc0206028 <free_area>
ffffffffc0200dd6:	641c                	ld	a5,8(s0)
ffffffffc0200dd8:	e486                	sd	ra,72(sp)
ffffffffc0200dda:	fc26                	sd	s1,56(sp)
ffffffffc0200ddc:	f84a                	sd	s2,48(sp)
ffffffffc0200dde:	f44e                	sd	s3,40(sp)
ffffffffc0200de0:	f052                	sd	s4,32(sp)
ffffffffc0200de2:	ec56                	sd	s5,24(sp)
ffffffffc0200de4:	e85a                	sd	s6,16(sp)
ffffffffc0200de6:	e45e                	sd	s7,8(sp)
ffffffffc0200de8:	e062                	sd	s8,0(sp)
    int score = 0 ,sumscore = 6;
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200dea:	26878b63          	beq	a5,s0,ffffffffc0201060 <best_fit_check+0x296>
    int count = 0, total = 0;
ffffffffc0200dee:	4481                	li	s1,0
ffffffffc0200df0:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200df2:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200df6:	8b09                	andi	a4,a4,2
ffffffffc0200df8:	26070863          	beqz	a4,ffffffffc0201068 <best_fit_check+0x29e>
        count ++, total += p->property;
ffffffffc0200dfc:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200e00:	679c                	ld	a5,8(a5)
ffffffffc0200e02:	2905                	addiw	s2,s2,1
ffffffffc0200e04:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200e06:	fe8796e3          	bne	a5,s0,ffffffffc0200df2 <best_fit_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0200e0a:	89a6                	mv	s3,s1
ffffffffc0200e0c:	167000ef          	jal	ra,ffffffffc0201772 <nr_free_pages>
ffffffffc0200e10:	33351c63          	bne	a0,s3,ffffffffc0201148 <best_fit_check+0x37e>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200e14:	4505                	li	a0,1
ffffffffc0200e16:	0df000ef          	jal	ra,ffffffffc02016f4 <alloc_pages>
ffffffffc0200e1a:	8a2a                	mv	s4,a0
ffffffffc0200e1c:	36050663          	beqz	a0,ffffffffc0201188 <best_fit_check+0x3be>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200e20:	4505                	li	a0,1
ffffffffc0200e22:	0d3000ef          	jal	ra,ffffffffc02016f4 <alloc_pages>
ffffffffc0200e26:	89aa                	mv	s3,a0
ffffffffc0200e28:	34050063          	beqz	a0,ffffffffc0201168 <best_fit_check+0x39e>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200e2c:	4505                	li	a0,1
ffffffffc0200e2e:	0c7000ef          	jal	ra,ffffffffc02016f4 <alloc_pages>
ffffffffc0200e32:	8aaa                	mv	s5,a0
ffffffffc0200e34:	2c050a63          	beqz	a0,ffffffffc0201108 <best_fit_check+0x33e>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200e38:	253a0863          	beq	s4,s3,ffffffffc0201088 <best_fit_check+0x2be>
ffffffffc0200e3c:	24aa0663          	beq	s4,a0,ffffffffc0201088 <best_fit_check+0x2be>
ffffffffc0200e40:	24a98463          	beq	s3,a0,ffffffffc0201088 <best_fit_check+0x2be>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200e44:	000a2783          	lw	a5,0(s4)
ffffffffc0200e48:	26079063          	bnez	a5,ffffffffc02010a8 <best_fit_check+0x2de>
ffffffffc0200e4c:	0009a783          	lw	a5,0(s3)
ffffffffc0200e50:	24079c63          	bnez	a5,ffffffffc02010a8 <best_fit_check+0x2de>
ffffffffc0200e54:	411c                	lw	a5,0(a0)
ffffffffc0200e56:	24079963          	bnez	a5,ffffffffc02010a8 <best_fit_check+0x2de>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200e5a:	00005797          	auipc	a5,0x5
ffffffffc0200e5e:	6167b783          	ld	a5,1558(a5) # ffffffffc0206470 <pages>
ffffffffc0200e62:	40fa0733          	sub	a4,s4,a5
ffffffffc0200e66:	870d                	srai	a4,a4,0x3
ffffffffc0200e68:	00002597          	auipc	a1,0x2
ffffffffc0200e6c:	1805b583          	ld	a1,384(a1) # ffffffffc0202fe8 <error_string+0x38>
ffffffffc0200e70:	02b70733          	mul	a4,a4,a1
ffffffffc0200e74:	00002617          	auipc	a2,0x2
ffffffffc0200e78:	17c63603          	ld	a2,380(a2) # ffffffffc0202ff0 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200e7c:	00005697          	auipc	a3,0x5
ffffffffc0200e80:	5ec6b683          	ld	a3,1516(a3) # ffffffffc0206468 <npage>
ffffffffc0200e84:	06b2                	slli	a3,a3,0xc
ffffffffc0200e86:	9732                	add	a4,a4,a2

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc0200e88:	0732                	slli	a4,a4,0xc
ffffffffc0200e8a:	22d77f63          	bgeu	a4,a3,ffffffffc02010c8 <best_fit_check+0x2fe>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200e8e:	40f98733          	sub	a4,s3,a5
ffffffffc0200e92:	870d                	srai	a4,a4,0x3
ffffffffc0200e94:	02b70733          	mul	a4,a4,a1
ffffffffc0200e98:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200e9a:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200e9c:	3ed77663          	bgeu	a4,a3,ffffffffc0201288 <best_fit_check+0x4be>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200ea0:	40f507b3          	sub	a5,a0,a5
ffffffffc0200ea4:	878d                	srai	a5,a5,0x3
ffffffffc0200ea6:	02b787b3          	mul	a5,a5,a1
ffffffffc0200eaa:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200eac:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200eae:	3ad7fd63          	bgeu	a5,a3,ffffffffc0201268 <best_fit_check+0x49e>
    assert(alloc_page() == NULL);
ffffffffc0200eb2:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200eb4:	00043c03          	ld	s8,0(s0)
ffffffffc0200eb8:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0200ebc:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0200ec0:	e400                	sd	s0,8(s0)
ffffffffc0200ec2:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0200ec4:	00005797          	auipc	a5,0x5
ffffffffc0200ec8:	1607aa23          	sw	zero,372(a5) # ffffffffc0206038 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200ecc:	029000ef          	jal	ra,ffffffffc02016f4 <alloc_pages>
ffffffffc0200ed0:	36051c63          	bnez	a0,ffffffffc0201248 <best_fit_check+0x47e>
    free_page(p0);
ffffffffc0200ed4:	4585                	li	a1,1
ffffffffc0200ed6:	8552                	mv	a0,s4
ffffffffc0200ed8:	05b000ef          	jal	ra,ffffffffc0201732 <free_pages>
    free_page(p1);
ffffffffc0200edc:	4585                	li	a1,1
ffffffffc0200ede:	854e                	mv	a0,s3
ffffffffc0200ee0:	053000ef          	jal	ra,ffffffffc0201732 <free_pages>
    free_page(p2);
ffffffffc0200ee4:	4585                	li	a1,1
ffffffffc0200ee6:	8556                	mv	a0,s5
ffffffffc0200ee8:	04b000ef          	jal	ra,ffffffffc0201732 <free_pages>
    assert(nr_free == 3);
ffffffffc0200eec:	4818                	lw	a4,16(s0)
ffffffffc0200eee:	478d                	li	a5,3
ffffffffc0200ef0:	32f71c63          	bne	a4,a5,ffffffffc0201228 <best_fit_check+0x45e>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200ef4:	4505                	li	a0,1
ffffffffc0200ef6:	7fe000ef          	jal	ra,ffffffffc02016f4 <alloc_pages>
ffffffffc0200efa:	89aa                	mv	s3,a0
ffffffffc0200efc:	30050663          	beqz	a0,ffffffffc0201208 <best_fit_check+0x43e>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200f00:	4505                	li	a0,1
ffffffffc0200f02:	7f2000ef          	jal	ra,ffffffffc02016f4 <alloc_pages>
ffffffffc0200f06:	8aaa                	mv	s5,a0
ffffffffc0200f08:	2e050063          	beqz	a0,ffffffffc02011e8 <best_fit_check+0x41e>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200f0c:	4505                	li	a0,1
ffffffffc0200f0e:	7e6000ef          	jal	ra,ffffffffc02016f4 <alloc_pages>
ffffffffc0200f12:	8a2a                	mv	s4,a0
ffffffffc0200f14:	2a050a63          	beqz	a0,ffffffffc02011c8 <best_fit_check+0x3fe>
    assert(alloc_page() == NULL);
ffffffffc0200f18:	4505                	li	a0,1
ffffffffc0200f1a:	7da000ef          	jal	ra,ffffffffc02016f4 <alloc_pages>
ffffffffc0200f1e:	28051563          	bnez	a0,ffffffffc02011a8 <best_fit_check+0x3de>
    free_page(p0);
ffffffffc0200f22:	4585                	li	a1,1
ffffffffc0200f24:	854e                	mv	a0,s3
ffffffffc0200f26:	00d000ef          	jal	ra,ffffffffc0201732 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200f2a:	641c                	ld	a5,8(s0)
ffffffffc0200f2c:	1a878e63          	beq	a5,s0,ffffffffc02010e8 <best_fit_check+0x31e>
    assert((p = alloc_page()) == p0);
ffffffffc0200f30:	4505                	li	a0,1
ffffffffc0200f32:	7c2000ef          	jal	ra,ffffffffc02016f4 <alloc_pages>
ffffffffc0200f36:	52a99963          	bne	s3,a0,ffffffffc0201468 <best_fit_check+0x69e>
    assert(alloc_page() == NULL);
ffffffffc0200f3a:	4505                	li	a0,1
ffffffffc0200f3c:	7b8000ef          	jal	ra,ffffffffc02016f4 <alloc_pages>
ffffffffc0200f40:	50051463          	bnez	a0,ffffffffc0201448 <best_fit_check+0x67e>
    assert(nr_free == 0);
ffffffffc0200f44:	481c                	lw	a5,16(s0)
ffffffffc0200f46:	4e079163          	bnez	a5,ffffffffc0201428 <best_fit_check+0x65e>
    free_page(p);
ffffffffc0200f4a:	854e                	mv	a0,s3
ffffffffc0200f4c:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200f4e:	01843023          	sd	s8,0(s0)
ffffffffc0200f52:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0200f56:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0200f5a:	7d8000ef          	jal	ra,ffffffffc0201732 <free_pages>
    free_page(p1);
ffffffffc0200f5e:	4585                	li	a1,1
ffffffffc0200f60:	8556                	mv	a0,s5
ffffffffc0200f62:	7d0000ef          	jal	ra,ffffffffc0201732 <free_pages>
    free_page(p2);
ffffffffc0200f66:	4585                	li	a1,1
ffffffffc0200f68:	8552                	mv	a0,s4
ffffffffc0200f6a:	7c8000ef          	jal	ra,ffffffffc0201732 <free_pages>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200f6e:	4515                	li	a0,5
ffffffffc0200f70:	784000ef          	jal	ra,ffffffffc02016f4 <alloc_pages>
ffffffffc0200f74:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200f76:	48050963          	beqz	a0,ffffffffc0201408 <best_fit_check+0x63e>
ffffffffc0200f7a:	651c                	ld	a5,8(a0)
ffffffffc0200f7c:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0200f7e:	8b85                	andi	a5,a5,1
ffffffffc0200f80:	46079463          	bnez	a5,ffffffffc02013e8 <best_fit_check+0x61e>
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200f84:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200f86:	00043a83          	ld	s5,0(s0)
ffffffffc0200f8a:	00843a03          	ld	s4,8(s0)
ffffffffc0200f8e:	e000                	sd	s0,0(s0)
ffffffffc0200f90:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0200f92:	762000ef          	jal	ra,ffffffffc02016f4 <alloc_pages>
ffffffffc0200f96:	42051963          	bnez	a0,ffffffffc02013c8 <best_fit_check+0x5fe>
    #endif
    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    // * - - * -
    free_pages(p0 + 1, 2);
ffffffffc0200f9a:	4589                	li	a1,2
ffffffffc0200f9c:	02898513          	addi	a0,s3,40
    unsigned int nr_free_store = nr_free;
ffffffffc0200fa0:	01042b03          	lw	s6,16(s0)
    free_pages(p0 + 4, 1);
ffffffffc0200fa4:	0a098c13          	addi	s8,s3,160
    nr_free = 0;
ffffffffc0200fa8:	00005797          	auipc	a5,0x5
ffffffffc0200fac:	0807a823          	sw	zero,144(a5) # ffffffffc0206038 <free_area+0x10>
    free_pages(p0 + 1, 2);
ffffffffc0200fb0:	782000ef          	jal	ra,ffffffffc0201732 <free_pages>
    free_pages(p0 + 4, 1);
ffffffffc0200fb4:	8562                	mv	a0,s8
ffffffffc0200fb6:	4585                	li	a1,1
ffffffffc0200fb8:	77a000ef          	jal	ra,ffffffffc0201732 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200fbc:	4511                	li	a0,4
ffffffffc0200fbe:	736000ef          	jal	ra,ffffffffc02016f4 <alloc_pages>
ffffffffc0200fc2:	3e051363          	bnez	a0,ffffffffc02013a8 <best_fit_check+0x5de>
ffffffffc0200fc6:	0309b783          	ld	a5,48(s3)
ffffffffc0200fca:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0200fcc:	8b85                	andi	a5,a5,1
ffffffffc0200fce:	3a078d63          	beqz	a5,ffffffffc0201388 <best_fit_check+0x5be>
ffffffffc0200fd2:	0389a703          	lw	a4,56(s3)
ffffffffc0200fd6:	4789                	li	a5,2
ffffffffc0200fd8:	3af71863          	bne	a4,a5,ffffffffc0201388 <best_fit_check+0x5be>
    // * - - * *
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0200fdc:	4505                	li	a0,1
ffffffffc0200fde:	716000ef          	jal	ra,ffffffffc02016f4 <alloc_pages>
ffffffffc0200fe2:	8baa                	mv	s7,a0
ffffffffc0200fe4:	38050263          	beqz	a0,ffffffffc0201368 <best_fit_check+0x59e>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc0200fe8:	4509                	li	a0,2
ffffffffc0200fea:	70a000ef          	jal	ra,ffffffffc02016f4 <alloc_pages>
ffffffffc0200fee:	34050d63          	beqz	a0,ffffffffc0201348 <best_fit_check+0x57e>
    assert(p0 + 4 == p1);
ffffffffc0200ff2:	337c1b63          	bne	s8,s7,ffffffffc0201328 <best_fit_check+0x55e>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    p2 = p0 + 1;
    free_pages(p0, 5);
ffffffffc0200ff6:	854e                	mv	a0,s3
ffffffffc0200ff8:	4595                	li	a1,5
ffffffffc0200ffa:	738000ef          	jal	ra,ffffffffc0201732 <free_pages>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200ffe:	4515                	li	a0,5
ffffffffc0201000:	6f4000ef          	jal	ra,ffffffffc02016f4 <alloc_pages>
ffffffffc0201004:	89aa                	mv	s3,a0
ffffffffc0201006:	30050163          	beqz	a0,ffffffffc0201308 <best_fit_check+0x53e>
    assert(alloc_page() == NULL);
ffffffffc020100a:	4505                	li	a0,1
ffffffffc020100c:	6e8000ef          	jal	ra,ffffffffc02016f4 <alloc_pages>
ffffffffc0201010:	2c051c63          	bnez	a0,ffffffffc02012e8 <best_fit_check+0x51e>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    assert(nr_free == 0);
ffffffffc0201014:	481c                	lw	a5,16(s0)
ffffffffc0201016:	2a079963          	bnez	a5,ffffffffc02012c8 <best_fit_check+0x4fe>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc020101a:	4595                	li	a1,5
ffffffffc020101c:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc020101e:	01642823          	sw	s6,16(s0)
    free_list = free_list_store;
ffffffffc0201022:	01543023          	sd	s5,0(s0)
ffffffffc0201026:	01443423          	sd	s4,8(s0)
    free_pages(p0, 5);
ffffffffc020102a:	708000ef          	jal	ra,ffffffffc0201732 <free_pages>
    return listelm->next;
ffffffffc020102e:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201030:	00878963          	beq	a5,s0,ffffffffc0201042 <best_fit_check+0x278>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0201034:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201038:	679c                	ld	a5,8(a5)
ffffffffc020103a:	397d                	addiw	s2,s2,-1
ffffffffc020103c:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc020103e:	fe879be3          	bne	a5,s0,ffffffffc0201034 <best_fit_check+0x26a>
    }
    assert(count == 0);
ffffffffc0201042:	26091363          	bnez	s2,ffffffffc02012a8 <best_fit_check+0x4de>
    assert(total == 0);
ffffffffc0201046:	e0ed                	bnez	s1,ffffffffc0201128 <best_fit_check+0x35e>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
}
ffffffffc0201048:	60a6                	ld	ra,72(sp)
ffffffffc020104a:	6406                	ld	s0,64(sp)
ffffffffc020104c:	74e2                	ld	s1,56(sp)
ffffffffc020104e:	7942                	ld	s2,48(sp)
ffffffffc0201050:	79a2                	ld	s3,40(sp)
ffffffffc0201052:	7a02                	ld	s4,32(sp)
ffffffffc0201054:	6ae2                	ld	s5,24(sp)
ffffffffc0201056:	6b42                	ld	s6,16(sp)
ffffffffc0201058:	6ba2                	ld	s7,8(sp)
ffffffffc020105a:	6c02                	ld	s8,0(sp)
ffffffffc020105c:	6161                	addi	sp,sp,80
ffffffffc020105e:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201060:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0201062:	4481                	li	s1,0
ffffffffc0201064:	4901                	li	s2,0
ffffffffc0201066:	b35d                	j	ffffffffc0200e0c <best_fit_check+0x42>
        assert(PageProperty(p));
ffffffffc0201068:	00002697          	auipc	a3,0x2
ffffffffc020106c:	8a868693          	addi	a3,a3,-1880 # ffffffffc0202910 <commands+0x710>
ffffffffc0201070:	00002617          	auipc	a2,0x2
ffffffffc0201074:	87060613          	addi	a2,a2,-1936 # ffffffffc02028e0 <commands+0x6e0>
ffffffffc0201078:	11300593          	li	a1,275
ffffffffc020107c:	00002517          	auipc	a0,0x2
ffffffffc0201080:	87c50513          	addi	a0,a0,-1924 # ffffffffc02028f8 <commands+0x6f8>
ffffffffc0201084:	b88ff0ef          	jal	ra,ffffffffc020040c <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0201088:	00002697          	auipc	a3,0x2
ffffffffc020108c:	91868693          	addi	a3,a3,-1768 # ffffffffc02029a0 <commands+0x7a0>
ffffffffc0201090:	00002617          	auipc	a2,0x2
ffffffffc0201094:	85060613          	addi	a2,a2,-1968 # ffffffffc02028e0 <commands+0x6e0>
ffffffffc0201098:	0df00593          	li	a1,223
ffffffffc020109c:	00002517          	auipc	a0,0x2
ffffffffc02010a0:	85c50513          	addi	a0,a0,-1956 # ffffffffc02028f8 <commands+0x6f8>
ffffffffc02010a4:	b68ff0ef          	jal	ra,ffffffffc020040c <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc02010a8:	00002697          	auipc	a3,0x2
ffffffffc02010ac:	92068693          	addi	a3,a3,-1760 # ffffffffc02029c8 <commands+0x7c8>
ffffffffc02010b0:	00002617          	auipc	a2,0x2
ffffffffc02010b4:	83060613          	addi	a2,a2,-2000 # ffffffffc02028e0 <commands+0x6e0>
ffffffffc02010b8:	0e000593          	li	a1,224
ffffffffc02010bc:	00002517          	auipc	a0,0x2
ffffffffc02010c0:	83c50513          	addi	a0,a0,-1988 # ffffffffc02028f8 <commands+0x6f8>
ffffffffc02010c4:	b48ff0ef          	jal	ra,ffffffffc020040c <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02010c8:	00002697          	auipc	a3,0x2
ffffffffc02010cc:	94068693          	addi	a3,a3,-1728 # ffffffffc0202a08 <commands+0x808>
ffffffffc02010d0:	00002617          	auipc	a2,0x2
ffffffffc02010d4:	81060613          	addi	a2,a2,-2032 # ffffffffc02028e0 <commands+0x6e0>
ffffffffc02010d8:	0e200593          	li	a1,226
ffffffffc02010dc:	00002517          	auipc	a0,0x2
ffffffffc02010e0:	81c50513          	addi	a0,a0,-2020 # ffffffffc02028f8 <commands+0x6f8>
ffffffffc02010e4:	b28ff0ef          	jal	ra,ffffffffc020040c <__panic>
    assert(!list_empty(&free_list));
ffffffffc02010e8:	00002697          	auipc	a3,0x2
ffffffffc02010ec:	9a868693          	addi	a3,a3,-1624 # ffffffffc0202a90 <commands+0x890>
ffffffffc02010f0:	00001617          	auipc	a2,0x1
ffffffffc02010f4:	7f060613          	addi	a2,a2,2032 # ffffffffc02028e0 <commands+0x6e0>
ffffffffc02010f8:	0fb00593          	li	a1,251
ffffffffc02010fc:	00001517          	auipc	a0,0x1
ffffffffc0201100:	7fc50513          	addi	a0,a0,2044 # ffffffffc02028f8 <commands+0x6f8>
ffffffffc0201104:	b08ff0ef          	jal	ra,ffffffffc020040c <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201108:	00002697          	auipc	a3,0x2
ffffffffc020110c:	87868693          	addi	a3,a3,-1928 # ffffffffc0202980 <commands+0x780>
ffffffffc0201110:	00001617          	auipc	a2,0x1
ffffffffc0201114:	7d060613          	addi	a2,a2,2000 # ffffffffc02028e0 <commands+0x6e0>
ffffffffc0201118:	0dd00593          	li	a1,221
ffffffffc020111c:	00001517          	auipc	a0,0x1
ffffffffc0201120:	7dc50513          	addi	a0,a0,2012 # ffffffffc02028f8 <commands+0x6f8>
ffffffffc0201124:	ae8ff0ef          	jal	ra,ffffffffc020040c <__panic>
    assert(total == 0);
ffffffffc0201128:	00002697          	auipc	a3,0x2
ffffffffc020112c:	a9868693          	addi	a3,a3,-1384 # ffffffffc0202bc0 <commands+0x9c0>
ffffffffc0201130:	00001617          	auipc	a2,0x1
ffffffffc0201134:	7b060613          	addi	a2,a2,1968 # ffffffffc02028e0 <commands+0x6e0>
ffffffffc0201138:	15500593          	li	a1,341
ffffffffc020113c:	00001517          	auipc	a0,0x1
ffffffffc0201140:	7bc50513          	addi	a0,a0,1980 # ffffffffc02028f8 <commands+0x6f8>
ffffffffc0201144:	ac8ff0ef          	jal	ra,ffffffffc020040c <__panic>
    assert(total == nr_free_pages());
ffffffffc0201148:	00001697          	auipc	a3,0x1
ffffffffc020114c:	7d868693          	addi	a3,a3,2008 # ffffffffc0202920 <commands+0x720>
ffffffffc0201150:	00001617          	auipc	a2,0x1
ffffffffc0201154:	79060613          	addi	a2,a2,1936 # ffffffffc02028e0 <commands+0x6e0>
ffffffffc0201158:	11600593          	li	a1,278
ffffffffc020115c:	00001517          	auipc	a0,0x1
ffffffffc0201160:	79c50513          	addi	a0,a0,1948 # ffffffffc02028f8 <commands+0x6f8>
ffffffffc0201164:	aa8ff0ef          	jal	ra,ffffffffc020040c <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201168:	00001697          	auipc	a3,0x1
ffffffffc020116c:	7f868693          	addi	a3,a3,2040 # ffffffffc0202960 <commands+0x760>
ffffffffc0201170:	00001617          	auipc	a2,0x1
ffffffffc0201174:	77060613          	addi	a2,a2,1904 # ffffffffc02028e0 <commands+0x6e0>
ffffffffc0201178:	0dc00593          	li	a1,220
ffffffffc020117c:	00001517          	auipc	a0,0x1
ffffffffc0201180:	77c50513          	addi	a0,a0,1916 # ffffffffc02028f8 <commands+0x6f8>
ffffffffc0201184:	a88ff0ef          	jal	ra,ffffffffc020040c <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201188:	00001697          	auipc	a3,0x1
ffffffffc020118c:	7b868693          	addi	a3,a3,1976 # ffffffffc0202940 <commands+0x740>
ffffffffc0201190:	00001617          	auipc	a2,0x1
ffffffffc0201194:	75060613          	addi	a2,a2,1872 # ffffffffc02028e0 <commands+0x6e0>
ffffffffc0201198:	0db00593          	li	a1,219
ffffffffc020119c:	00001517          	auipc	a0,0x1
ffffffffc02011a0:	75c50513          	addi	a0,a0,1884 # ffffffffc02028f8 <commands+0x6f8>
ffffffffc02011a4:	a68ff0ef          	jal	ra,ffffffffc020040c <__panic>
    assert(alloc_page() == NULL);
ffffffffc02011a8:	00002697          	auipc	a3,0x2
ffffffffc02011ac:	8c068693          	addi	a3,a3,-1856 # ffffffffc0202a68 <commands+0x868>
ffffffffc02011b0:	00001617          	auipc	a2,0x1
ffffffffc02011b4:	73060613          	addi	a2,a2,1840 # ffffffffc02028e0 <commands+0x6e0>
ffffffffc02011b8:	0f800593          	li	a1,248
ffffffffc02011bc:	00001517          	auipc	a0,0x1
ffffffffc02011c0:	73c50513          	addi	a0,a0,1852 # ffffffffc02028f8 <commands+0x6f8>
ffffffffc02011c4:	a48ff0ef          	jal	ra,ffffffffc020040c <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02011c8:	00001697          	auipc	a3,0x1
ffffffffc02011cc:	7b868693          	addi	a3,a3,1976 # ffffffffc0202980 <commands+0x780>
ffffffffc02011d0:	00001617          	auipc	a2,0x1
ffffffffc02011d4:	71060613          	addi	a2,a2,1808 # ffffffffc02028e0 <commands+0x6e0>
ffffffffc02011d8:	0f600593          	li	a1,246
ffffffffc02011dc:	00001517          	auipc	a0,0x1
ffffffffc02011e0:	71c50513          	addi	a0,a0,1820 # ffffffffc02028f8 <commands+0x6f8>
ffffffffc02011e4:	a28ff0ef          	jal	ra,ffffffffc020040c <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02011e8:	00001697          	auipc	a3,0x1
ffffffffc02011ec:	77868693          	addi	a3,a3,1912 # ffffffffc0202960 <commands+0x760>
ffffffffc02011f0:	00001617          	auipc	a2,0x1
ffffffffc02011f4:	6f060613          	addi	a2,a2,1776 # ffffffffc02028e0 <commands+0x6e0>
ffffffffc02011f8:	0f500593          	li	a1,245
ffffffffc02011fc:	00001517          	auipc	a0,0x1
ffffffffc0201200:	6fc50513          	addi	a0,a0,1788 # ffffffffc02028f8 <commands+0x6f8>
ffffffffc0201204:	a08ff0ef          	jal	ra,ffffffffc020040c <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201208:	00001697          	auipc	a3,0x1
ffffffffc020120c:	73868693          	addi	a3,a3,1848 # ffffffffc0202940 <commands+0x740>
ffffffffc0201210:	00001617          	auipc	a2,0x1
ffffffffc0201214:	6d060613          	addi	a2,a2,1744 # ffffffffc02028e0 <commands+0x6e0>
ffffffffc0201218:	0f400593          	li	a1,244
ffffffffc020121c:	00001517          	auipc	a0,0x1
ffffffffc0201220:	6dc50513          	addi	a0,a0,1756 # ffffffffc02028f8 <commands+0x6f8>
ffffffffc0201224:	9e8ff0ef          	jal	ra,ffffffffc020040c <__panic>
    assert(nr_free == 3);
ffffffffc0201228:	00002697          	auipc	a3,0x2
ffffffffc020122c:	85868693          	addi	a3,a3,-1960 # ffffffffc0202a80 <commands+0x880>
ffffffffc0201230:	00001617          	auipc	a2,0x1
ffffffffc0201234:	6b060613          	addi	a2,a2,1712 # ffffffffc02028e0 <commands+0x6e0>
ffffffffc0201238:	0f200593          	li	a1,242
ffffffffc020123c:	00001517          	auipc	a0,0x1
ffffffffc0201240:	6bc50513          	addi	a0,a0,1724 # ffffffffc02028f8 <commands+0x6f8>
ffffffffc0201244:	9c8ff0ef          	jal	ra,ffffffffc020040c <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201248:	00002697          	auipc	a3,0x2
ffffffffc020124c:	82068693          	addi	a3,a3,-2016 # ffffffffc0202a68 <commands+0x868>
ffffffffc0201250:	00001617          	auipc	a2,0x1
ffffffffc0201254:	69060613          	addi	a2,a2,1680 # ffffffffc02028e0 <commands+0x6e0>
ffffffffc0201258:	0ed00593          	li	a1,237
ffffffffc020125c:	00001517          	auipc	a0,0x1
ffffffffc0201260:	69c50513          	addi	a0,a0,1692 # ffffffffc02028f8 <commands+0x6f8>
ffffffffc0201264:	9a8ff0ef          	jal	ra,ffffffffc020040c <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0201268:	00001697          	auipc	a3,0x1
ffffffffc020126c:	7e068693          	addi	a3,a3,2016 # ffffffffc0202a48 <commands+0x848>
ffffffffc0201270:	00001617          	auipc	a2,0x1
ffffffffc0201274:	67060613          	addi	a2,a2,1648 # ffffffffc02028e0 <commands+0x6e0>
ffffffffc0201278:	0e400593          	li	a1,228
ffffffffc020127c:	00001517          	auipc	a0,0x1
ffffffffc0201280:	67c50513          	addi	a0,a0,1660 # ffffffffc02028f8 <commands+0x6f8>
ffffffffc0201284:	988ff0ef          	jal	ra,ffffffffc020040c <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201288:	00001697          	auipc	a3,0x1
ffffffffc020128c:	7a068693          	addi	a3,a3,1952 # ffffffffc0202a28 <commands+0x828>
ffffffffc0201290:	00001617          	auipc	a2,0x1
ffffffffc0201294:	65060613          	addi	a2,a2,1616 # ffffffffc02028e0 <commands+0x6e0>
ffffffffc0201298:	0e300593          	li	a1,227
ffffffffc020129c:	00001517          	auipc	a0,0x1
ffffffffc02012a0:	65c50513          	addi	a0,a0,1628 # ffffffffc02028f8 <commands+0x6f8>
ffffffffc02012a4:	968ff0ef          	jal	ra,ffffffffc020040c <__panic>
    assert(count == 0);
ffffffffc02012a8:	00002697          	auipc	a3,0x2
ffffffffc02012ac:	90868693          	addi	a3,a3,-1784 # ffffffffc0202bb0 <commands+0x9b0>
ffffffffc02012b0:	00001617          	auipc	a2,0x1
ffffffffc02012b4:	63060613          	addi	a2,a2,1584 # ffffffffc02028e0 <commands+0x6e0>
ffffffffc02012b8:	15400593          	li	a1,340
ffffffffc02012bc:	00001517          	auipc	a0,0x1
ffffffffc02012c0:	63c50513          	addi	a0,a0,1596 # ffffffffc02028f8 <commands+0x6f8>
ffffffffc02012c4:	948ff0ef          	jal	ra,ffffffffc020040c <__panic>
    assert(nr_free == 0);
ffffffffc02012c8:	00002697          	auipc	a3,0x2
ffffffffc02012cc:	80068693          	addi	a3,a3,-2048 # ffffffffc0202ac8 <commands+0x8c8>
ffffffffc02012d0:	00001617          	auipc	a2,0x1
ffffffffc02012d4:	61060613          	addi	a2,a2,1552 # ffffffffc02028e0 <commands+0x6e0>
ffffffffc02012d8:	14900593          	li	a1,329
ffffffffc02012dc:	00001517          	auipc	a0,0x1
ffffffffc02012e0:	61c50513          	addi	a0,a0,1564 # ffffffffc02028f8 <commands+0x6f8>
ffffffffc02012e4:	928ff0ef          	jal	ra,ffffffffc020040c <__panic>
    assert(alloc_page() == NULL);
ffffffffc02012e8:	00001697          	auipc	a3,0x1
ffffffffc02012ec:	78068693          	addi	a3,a3,1920 # ffffffffc0202a68 <commands+0x868>
ffffffffc02012f0:	00001617          	auipc	a2,0x1
ffffffffc02012f4:	5f060613          	addi	a2,a2,1520 # ffffffffc02028e0 <commands+0x6e0>
ffffffffc02012f8:	14300593          	li	a1,323
ffffffffc02012fc:	00001517          	auipc	a0,0x1
ffffffffc0201300:	5fc50513          	addi	a0,a0,1532 # ffffffffc02028f8 <commands+0x6f8>
ffffffffc0201304:	908ff0ef          	jal	ra,ffffffffc020040c <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201308:	00002697          	auipc	a3,0x2
ffffffffc020130c:	88868693          	addi	a3,a3,-1912 # ffffffffc0202b90 <commands+0x990>
ffffffffc0201310:	00001617          	auipc	a2,0x1
ffffffffc0201314:	5d060613          	addi	a2,a2,1488 # ffffffffc02028e0 <commands+0x6e0>
ffffffffc0201318:	14200593          	li	a1,322
ffffffffc020131c:	00001517          	auipc	a0,0x1
ffffffffc0201320:	5dc50513          	addi	a0,a0,1500 # ffffffffc02028f8 <commands+0x6f8>
ffffffffc0201324:	8e8ff0ef          	jal	ra,ffffffffc020040c <__panic>
    assert(p0 + 4 == p1);
ffffffffc0201328:	00002697          	auipc	a3,0x2
ffffffffc020132c:	85868693          	addi	a3,a3,-1960 # ffffffffc0202b80 <commands+0x980>
ffffffffc0201330:	00001617          	auipc	a2,0x1
ffffffffc0201334:	5b060613          	addi	a2,a2,1456 # ffffffffc02028e0 <commands+0x6e0>
ffffffffc0201338:	13a00593          	li	a1,314
ffffffffc020133c:	00001517          	auipc	a0,0x1
ffffffffc0201340:	5bc50513          	addi	a0,a0,1468 # ffffffffc02028f8 <commands+0x6f8>
ffffffffc0201344:	8c8ff0ef          	jal	ra,ffffffffc020040c <__panic>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc0201348:	00002697          	auipc	a3,0x2
ffffffffc020134c:	82068693          	addi	a3,a3,-2016 # ffffffffc0202b68 <commands+0x968>
ffffffffc0201350:	00001617          	auipc	a2,0x1
ffffffffc0201354:	59060613          	addi	a2,a2,1424 # ffffffffc02028e0 <commands+0x6e0>
ffffffffc0201358:	13900593          	li	a1,313
ffffffffc020135c:	00001517          	auipc	a0,0x1
ffffffffc0201360:	59c50513          	addi	a0,a0,1436 # ffffffffc02028f8 <commands+0x6f8>
ffffffffc0201364:	8a8ff0ef          	jal	ra,ffffffffc020040c <__panic>
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0201368:	00001697          	auipc	a3,0x1
ffffffffc020136c:	7e068693          	addi	a3,a3,2016 # ffffffffc0202b48 <commands+0x948>
ffffffffc0201370:	00001617          	auipc	a2,0x1
ffffffffc0201374:	57060613          	addi	a2,a2,1392 # ffffffffc02028e0 <commands+0x6e0>
ffffffffc0201378:	13800593          	li	a1,312
ffffffffc020137c:	00001517          	auipc	a0,0x1
ffffffffc0201380:	57c50513          	addi	a0,a0,1404 # ffffffffc02028f8 <commands+0x6f8>
ffffffffc0201384:	888ff0ef          	jal	ra,ffffffffc020040c <__panic>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0201388:	00001697          	auipc	a3,0x1
ffffffffc020138c:	79068693          	addi	a3,a3,1936 # ffffffffc0202b18 <commands+0x918>
ffffffffc0201390:	00001617          	auipc	a2,0x1
ffffffffc0201394:	55060613          	addi	a2,a2,1360 # ffffffffc02028e0 <commands+0x6e0>
ffffffffc0201398:	13600593          	li	a1,310
ffffffffc020139c:	00001517          	auipc	a0,0x1
ffffffffc02013a0:	55c50513          	addi	a0,a0,1372 # ffffffffc02028f8 <commands+0x6f8>
ffffffffc02013a4:	868ff0ef          	jal	ra,ffffffffc020040c <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc02013a8:	00001697          	auipc	a3,0x1
ffffffffc02013ac:	75868693          	addi	a3,a3,1880 # ffffffffc0202b00 <commands+0x900>
ffffffffc02013b0:	00001617          	auipc	a2,0x1
ffffffffc02013b4:	53060613          	addi	a2,a2,1328 # ffffffffc02028e0 <commands+0x6e0>
ffffffffc02013b8:	13500593          	li	a1,309
ffffffffc02013bc:	00001517          	auipc	a0,0x1
ffffffffc02013c0:	53c50513          	addi	a0,a0,1340 # ffffffffc02028f8 <commands+0x6f8>
ffffffffc02013c4:	848ff0ef          	jal	ra,ffffffffc020040c <__panic>
    assert(alloc_page() == NULL);
ffffffffc02013c8:	00001697          	auipc	a3,0x1
ffffffffc02013cc:	6a068693          	addi	a3,a3,1696 # ffffffffc0202a68 <commands+0x868>
ffffffffc02013d0:	00001617          	auipc	a2,0x1
ffffffffc02013d4:	51060613          	addi	a2,a2,1296 # ffffffffc02028e0 <commands+0x6e0>
ffffffffc02013d8:	12900593          	li	a1,297
ffffffffc02013dc:	00001517          	auipc	a0,0x1
ffffffffc02013e0:	51c50513          	addi	a0,a0,1308 # ffffffffc02028f8 <commands+0x6f8>
ffffffffc02013e4:	828ff0ef          	jal	ra,ffffffffc020040c <__panic>
    assert(!PageProperty(p0));
ffffffffc02013e8:	00001697          	auipc	a3,0x1
ffffffffc02013ec:	70068693          	addi	a3,a3,1792 # ffffffffc0202ae8 <commands+0x8e8>
ffffffffc02013f0:	00001617          	auipc	a2,0x1
ffffffffc02013f4:	4f060613          	addi	a2,a2,1264 # ffffffffc02028e0 <commands+0x6e0>
ffffffffc02013f8:	12000593          	li	a1,288
ffffffffc02013fc:	00001517          	auipc	a0,0x1
ffffffffc0201400:	4fc50513          	addi	a0,a0,1276 # ffffffffc02028f8 <commands+0x6f8>
ffffffffc0201404:	808ff0ef          	jal	ra,ffffffffc020040c <__panic>
    assert(p0 != NULL);
ffffffffc0201408:	00001697          	auipc	a3,0x1
ffffffffc020140c:	6d068693          	addi	a3,a3,1744 # ffffffffc0202ad8 <commands+0x8d8>
ffffffffc0201410:	00001617          	auipc	a2,0x1
ffffffffc0201414:	4d060613          	addi	a2,a2,1232 # ffffffffc02028e0 <commands+0x6e0>
ffffffffc0201418:	11f00593          	li	a1,287
ffffffffc020141c:	00001517          	auipc	a0,0x1
ffffffffc0201420:	4dc50513          	addi	a0,a0,1244 # ffffffffc02028f8 <commands+0x6f8>
ffffffffc0201424:	fe9fe0ef          	jal	ra,ffffffffc020040c <__panic>
    assert(nr_free == 0);
ffffffffc0201428:	00001697          	auipc	a3,0x1
ffffffffc020142c:	6a068693          	addi	a3,a3,1696 # ffffffffc0202ac8 <commands+0x8c8>
ffffffffc0201430:	00001617          	auipc	a2,0x1
ffffffffc0201434:	4b060613          	addi	a2,a2,1200 # ffffffffc02028e0 <commands+0x6e0>
ffffffffc0201438:	10100593          	li	a1,257
ffffffffc020143c:	00001517          	auipc	a0,0x1
ffffffffc0201440:	4bc50513          	addi	a0,a0,1212 # ffffffffc02028f8 <commands+0x6f8>
ffffffffc0201444:	fc9fe0ef          	jal	ra,ffffffffc020040c <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201448:	00001697          	auipc	a3,0x1
ffffffffc020144c:	62068693          	addi	a3,a3,1568 # ffffffffc0202a68 <commands+0x868>
ffffffffc0201450:	00001617          	auipc	a2,0x1
ffffffffc0201454:	49060613          	addi	a2,a2,1168 # ffffffffc02028e0 <commands+0x6e0>
ffffffffc0201458:	0ff00593          	li	a1,255
ffffffffc020145c:	00001517          	auipc	a0,0x1
ffffffffc0201460:	49c50513          	addi	a0,a0,1180 # ffffffffc02028f8 <commands+0x6f8>
ffffffffc0201464:	fa9fe0ef          	jal	ra,ffffffffc020040c <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0201468:	00001697          	auipc	a3,0x1
ffffffffc020146c:	64068693          	addi	a3,a3,1600 # ffffffffc0202aa8 <commands+0x8a8>
ffffffffc0201470:	00001617          	auipc	a2,0x1
ffffffffc0201474:	47060613          	addi	a2,a2,1136 # ffffffffc02028e0 <commands+0x6e0>
ffffffffc0201478:	0fe00593          	li	a1,254
ffffffffc020147c:	00001517          	auipc	a0,0x1
ffffffffc0201480:	47c50513          	addi	a0,a0,1148 # ffffffffc02028f8 <commands+0x6f8>
ffffffffc0201484:	f89fe0ef          	jal	ra,ffffffffc020040c <__panic>

ffffffffc0201488 <best_fit_free_pages>:
best_fit_free_pages(struct Page *base, size_t n) {
ffffffffc0201488:	1141                	addi	sp,sp,-16
ffffffffc020148a:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020148c:	14058a63          	beqz	a1,ffffffffc02015e0 <best_fit_free_pages+0x158>
    for (; p != base + n; p ++) {
ffffffffc0201490:	00259693          	slli	a3,a1,0x2
ffffffffc0201494:	96ae                	add	a3,a3,a1
ffffffffc0201496:	068e                	slli	a3,a3,0x3
ffffffffc0201498:	96aa                	add	a3,a3,a0
ffffffffc020149a:	87aa                	mv	a5,a0
ffffffffc020149c:	02d50263          	beq	a0,a3,ffffffffc02014c0 <best_fit_free_pages+0x38>
ffffffffc02014a0:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02014a2:	8b05                	andi	a4,a4,1
ffffffffc02014a4:	10071e63          	bnez	a4,ffffffffc02015c0 <best_fit_free_pages+0x138>
ffffffffc02014a8:	6798                	ld	a4,8(a5)
ffffffffc02014aa:	8b09                	andi	a4,a4,2
ffffffffc02014ac:	10071a63          	bnez	a4,ffffffffc02015c0 <best_fit_free_pages+0x138>
        p->flags = 0;
ffffffffc02014b0:	0007b423          	sd	zero,8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc02014b4:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc02014b8:	02878793          	addi	a5,a5,40
ffffffffc02014bc:	fed792e3          	bne	a5,a3,ffffffffc02014a0 <best_fit_free_pages+0x18>
    base->property = n;
ffffffffc02014c0:	2581                	sext.w	a1,a1
ffffffffc02014c2:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc02014c4:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02014c8:	4789                	li	a5,2
ffffffffc02014ca:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc02014ce:	00005697          	auipc	a3,0x5
ffffffffc02014d2:	b5a68693          	addi	a3,a3,-1190 # ffffffffc0206028 <free_area>
ffffffffc02014d6:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02014d8:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc02014da:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc02014de:	9db9                	addw	a1,a1,a4
ffffffffc02014e0:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc02014e2:	0ad78863          	beq	a5,a3,ffffffffc0201592 <best_fit_free_pages+0x10a>
            struct Page* page = le2page(le, page_link);
ffffffffc02014e6:	fe878713          	addi	a4,a5,-24
ffffffffc02014ea:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc02014ee:	4581                	li	a1,0
            if (base < page) {
ffffffffc02014f0:	00e56a63          	bltu	a0,a4,ffffffffc0201504 <best_fit_free_pages+0x7c>
    return listelm->next;
ffffffffc02014f4:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc02014f6:	06d70263          	beq	a4,a3,ffffffffc020155a <best_fit_free_pages+0xd2>
    for (; p != base + n; p ++) {
ffffffffc02014fa:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc02014fc:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0201500:	fee57ae3          	bgeu	a0,a4,ffffffffc02014f4 <best_fit_free_pages+0x6c>
ffffffffc0201504:	c199                	beqz	a1,ffffffffc020150a <best_fit_free_pages+0x82>
ffffffffc0201506:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc020150a:	6398                	ld	a4,0(a5)
    prev->next = next->prev = elm;
ffffffffc020150c:	e390                	sd	a2,0(a5)
ffffffffc020150e:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201510:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201512:	ed18                	sd	a4,24(a0)
    if (le != &free_list) {
ffffffffc0201514:	02d70063          	beq	a4,a3,ffffffffc0201534 <best_fit_free_pages+0xac>
        if (p + p->property == base) {
ffffffffc0201518:	ff872803          	lw	a6,-8(a4)
        p = le2page(le, page_link);
ffffffffc020151c:	fe870593          	addi	a1,a4,-24
        if (p + p->property == base) {
ffffffffc0201520:	02081613          	slli	a2,a6,0x20
ffffffffc0201524:	9201                	srli	a2,a2,0x20
ffffffffc0201526:	00261793          	slli	a5,a2,0x2
ffffffffc020152a:	97b2                	add	a5,a5,a2
ffffffffc020152c:	078e                	slli	a5,a5,0x3
ffffffffc020152e:	97ae                	add	a5,a5,a1
ffffffffc0201530:	02f50f63          	beq	a0,a5,ffffffffc020156e <best_fit_free_pages+0xe6>
    return listelm->next;
ffffffffc0201534:	7118                	ld	a4,32(a0)
    if (le != &free_list) {
ffffffffc0201536:	00d70f63          	beq	a4,a3,ffffffffc0201554 <best_fit_free_pages+0xcc>
        if (base + base->property == p) {
ffffffffc020153a:	490c                	lw	a1,16(a0)
        p = le2page(le, page_link);
ffffffffc020153c:	fe870693          	addi	a3,a4,-24
        if (base + base->property == p) {
ffffffffc0201540:	02059613          	slli	a2,a1,0x20
ffffffffc0201544:	9201                	srli	a2,a2,0x20
ffffffffc0201546:	00261793          	slli	a5,a2,0x2
ffffffffc020154a:	97b2                	add	a5,a5,a2
ffffffffc020154c:	078e                	slli	a5,a5,0x3
ffffffffc020154e:	97aa                	add	a5,a5,a0
ffffffffc0201550:	04f68863          	beq	a3,a5,ffffffffc02015a0 <best_fit_free_pages+0x118>
}
ffffffffc0201554:	60a2                	ld	ra,8(sp)
ffffffffc0201556:	0141                	addi	sp,sp,16
ffffffffc0201558:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc020155a:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc020155c:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc020155e:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201560:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201562:	02d70563          	beq	a4,a3,ffffffffc020158c <best_fit_free_pages+0x104>
    prev->next = next->prev = elm;
ffffffffc0201566:	8832                	mv	a6,a2
ffffffffc0201568:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc020156a:	87ba                	mv	a5,a4
ffffffffc020156c:	bf41                	j	ffffffffc02014fc <best_fit_free_pages+0x74>
            p->property += base->property;
ffffffffc020156e:	491c                	lw	a5,16(a0)
ffffffffc0201570:	0107883b          	addw	a6,a5,a6
ffffffffc0201574:	ff072c23          	sw	a6,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201578:	57f5                	li	a5,-3
ffffffffc020157a:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc020157e:	6d10                	ld	a2,24(a0)
ffffffffc0201580:	711c                	ld	a5,32(a0)
            base = p;
ffffffffc0201582:	852e                	mv	a0,a1
    prev->next = next;
ffffffffc0201584:	e61c                	sd	a5,8(a2)
    return listelm->next;
ffffffffc0201586:	6718                	ld	a4,8(a4)
    next->prev = prev;
ffffffffc0201588:	e390                	sd	a2,0(a5)
ffffffffc020158a:	b775                	j	ffffffffc0201536 <best_fit_free_pages+0xae>
ffffffffc020158c:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list) {
ffffffffc020158e:	873e                	mv	a4,a5
ffffffffc0201590:	b761                	j	ffffffffc0201518 <best_fit_free_pages+0x90>
}
ffffffffc0201592:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201594:	e390                	sd	a2,0(a5)
ffffffffc0201596:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201598:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020159a:	ed1c                	sd	a5,24(a0)
ffffffffc020159c:	0141                	addi	sp,sp,16
ffffffffc020159e:	8082                	ret
            base->property += p->property;
ffffffffc02015a0:	ff872783          	lw	a5,-8(a4)
ffffffffc02015a4:	ff070693          	addi	a3,a4,-16
ffffffffc02015a8:	9dbd                	addw	a1,a1,a5
ffffffffc02015aa:	c90c                	sw	a1,16(a0)
ffffffffc02015ac:	57f5                	li	a5,-3
ffffffffc02015ae:	60f6b02f          	amoand.d	zero,a5,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc02015b2:	6314                	ld	a3,0(a4)
ffffffffc02015b4:	671c                	ld	a5,8(a4)
}
ffffffffc02015b6:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc02015b8:	e69c                	sd	a5,8(a3)
    next->prev = prev;
ffffffffc02015ba:	e394                	sd	a3,0(a5)
ffffffffc02015bc:	0141                	addi	sp,sp,16
ffffffffc02015be:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02015c0:	00001697          	auipc	a3,0x1
ffffffffc02015c4:	61068693          	addi	a3,a3,1552 # ffffffffc0202bd0 <commands+0x9d0>
ffffffffc02015c8:	00001617          	auipc	a2,0x1
ffffffffc02015cc:	31860613          	addi	a2,a2,792 # ffffffffc02028e0 <commands+0x6e0>
ffffffffc02015d0:	09800593          	li	a1,152
ffffffffc02015d4:	00001517          	auipc	a0,0x1
ffffffffc02015d8:	32450513          	addi	a0,a0,804 # ffffffffc02028f8 <commands+0x6f8>
ffffffffc02015dc:	e31fe0ef          	jal	ra,ffffffffc020040c <__panic>
    assert(n > 0);
ffffffffc02015e0:	00001697          	auipc	a3,0x1
ffffffffc02015e4:	2f868693          	addi	a3,a3,760 # ffffffffc02028d8 <commands+0x6d8>
ffffffffc02015e8:	00001617          	auipc	a2,0x1
ffffffffc02015ec:	2f860613          	addi	a2,a2,760 # ffffffffc02028e0 <commands+0x6e0>
ffffffffc02015f0:	09500593          	li	a1,149
ffffffffc02015f4:	00001517          	auipc	a0,0x1
ffffffffc02015f8:	30450513          	addi	a0,a0,772 # ffffffffc02028f8 <commands+0x6f8>
ffffffffc02015fc:	e11fe0ef          	jal	ra,ffffffffc020040c <__panic>

ffffffffc0201600 <best_fit_init_memmap>:
best_fit_init_memmap(struct Page *base, size_t n) {
ffffffffc0201600:	1141                	addi	sp,sp,-16
ffffffffc0201602:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201604:	c9e1                	beqz	a1,ffffffffc02016d4 <best_fit_init_memmap+0xd4>
    for (; p != base + n; p ++) {
ffffffffc0201606:	00259693          	slli	a3,a1,0x2
ffffffffc020160a:	96ae                	add	a3,a3,a1
ffffffffc020160c:	068e                	slli	a3,a3,0x3
ffffffffc020160e:	96aa                	add	a3,a3,a0
ffffffffc0201610:	87aa                	mv	a5,a0
ffffffffc0201612:	00d50f63          	beq	a0,a3,ffffffffc0201630 <best_fit_init_memmap+0x30>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0201616:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc0201618:	8b05                	andi	a4,a4,1
ffffffffc020161a:	cf49                	beqz	a4,ffffffffc02016b4 <best_fit_init_memmap+0xb4>
        p->flags = p->property = 0;
ffffffffc020161c:	0007a823          	sw	zero,16(a5)
ffffffffc0201620:	0007b423          	sd	zero,8(a5)
ffffffffc0201624:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0201628:	02878793          	addi	a5,a5,40
ffffffffc020162c:	fed795e3          	bne	a5,a3,ffffffffc0201616 <best_fit_init_memmap+0x16>
    base->property = n;
ffffffffc0201630:	2581                	sext.w	a1,a1
ffffffffc0201632:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201634:	4789                	li	a5,2
ffffffffc0201636:	00850713          	addi	a4,a0,8
ffffffffc020163a:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc020163e:	00005697          	auipc	a3,0x5
ffffffffc0201642:	9ea68693          	addi	a3,a3,-1558 # ffffffffc0206028 <free_area>
ffffffffc0201646:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201648:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc020164a:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc020164e:	9db9                	addw	a1,a1,a4
ffffffffc0201650:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0201652:	04d78a63          	beq	a5,a3,ffffffffc02016a6 <best_fit_init_memmap+0xa6>
            struct Page* page = le2page(le, page_link);
ffffffffc0201656:	fe878713          	addi	a4,a5,-24
ffffffffc020165a:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc020165e:	4581                	li	a1,0
            if (base < page) {
ffffffffc0201660:	00e56a63          	bltu	a0,a4,ffffffffc0201674 <best_fit_init_memmap+0x74>
    return listelm->next;
ffffffffc0201664:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0201666:	02d70263          	beq	a4,a3,ffffffffc020168a <best_fit_init_memmap+0x8a>
    for (; p != base + n; p ++) {
ffffffffc020166a:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc020166c:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0201670:	fee57ae3          	bgeu	a0,a4,ffffffffc0201664 <best_fit_init_memmap+0x64>
ffffffffc0201674:	c199                	beqz	a1,ffffffffc020167a <best_fit_init_memmap+0x7a>
ffffffffc0201676:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc020167a:	6398                	ld	a4,0(a5)
}
ffffffffc020167c:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc020167e:	e390                	sd	a2,0(a5)
ffffffffc0201680:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201682:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201684:	ed18                	sd	a4,24(a0)
ffffffffc0201686:	0141                	addi	sp,sp,16
ffffffffc0201688:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc020168a:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc020168c:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc020168e:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201690:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201692:	00d70663          	beq	a4,a3,ffffffffc020169e <best_fit_init_memmap+0x9e>
    prev->next = next->prev = elm;
ffffffffc0201696:	8832                	mv	a6,a2
ffffffffc0201698:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc020169a:	87ba                	mv	a5,a4
ffffffffc020169c:	bfc1                	j	ffffffffc020166c <best_fit_init_memmap+0x6c>
}
ffffffffc020169e:	60a2                	ld	ra,8(sp)
ffffffffc02016a0:	e290                	sd	a2,0(a3)
ffffffffc02016a2:	0141                	addi	sp,sp,16
ffffffffc02016a4:	8082                	ret
ffffffffc02016a6:	60a2                	ld	ra,8(sp)
ffffffffc02016a8:	e390                	sd	a2,0(a5)
ffffffffc02016aa:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02016ac:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02016ae:	ed1c                	sd	a5,24(a0)
ffffffffc02016b0:	0141                	addi	sp,sp,16
ffffffffc02016b2:	8082                	ret
        assert(PageReserved(p));
ffffffffc02016b4:	00001697          	auipc	a3,0x1
ffffffffc02016b8:	54468693          	addi	a3,a3,1348 # ffffffffc0202bf8 <commands+0x9f8>
ffffffffc02016bc:	00001617          	auipc	a2,0x1
ffffffffc02016c0:	22460613          	addi	a2,a2,548 # ffffffffc02028e0 <commands+0x6e0>
ffffffffc02016c4:	04a00593          	li	a1,74
ffffffffc02016c8:	00001517          	auipc	a0,0x1
ffffffffc02016cc:	23050513          	addi	a0,a0,560 # ffffffffc02028f8 <commands+0x6f8>
ffffffffc02016d0:	d3dfe0ef          	jal	ra,ffffffffc020040c <__panic>
    assert(n > 0);
ffffffffc02016d4:	00001697          	auipc	a3,0x1
ffffffffc02016d8:	20468693          	addi	a3,a3,516 # ffffffffc02028d8 <commands+0x6d8>
ffffffffc02016dc:	00001617          	auipc	a2,0x1
ffffffffc02016e0:	20460613          	addi	a2,a2,516 # ffffffffc02028e0 <commands+0x6e0>
ffffffffc02016e4:	04700593          	li	a1,71
ffffffffc02016e8:	00001517          	auipc	a0,0x1
ffffffffc02016ec:	21050513          	addi	a0,a0,528 # ffffffffc02028f8 <commands+0x6f8>
ffffffffc02016f0:	d1dfe0ef          	jal	ra,ffffffffc020040c <__panic>

ffffffffc02016f4 <alloc_pages>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02016f4:	100027f3          	csrr	a5,sstatus
ffffffffc02016f8:	8b89                	andi	a5,a5,2
ffffffffc02016fa:	e799                	bnez	a5,ffffffffc0201708 <alloc_pages+0x14>
struct Page *alloc_pages(size_t n) {
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc02016fc:	00005797          	auipc	a5,0x5
ffffffffc0201700:	d7c7b783          	ld	a5,-644(a5) # ffffffffc0206478 <pmm_manager>
ffffffffc0201704:	6f9c                	ld	a5,24(a5)
ffffffffc0201706:	8782                	jr	a5
struct Page *alloc_pages(size_t n) {
ffffffffc0201708:	1141                	addi	sp,sp,-16
ffffffffc020170a:	e406                	sd	ra,8(sp)
ffffffffc020170c:	e022                	sd	s0,0(sp)
ffffffffc020170e:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0201710:	95eff0ef          	jal	ra,ffffffffc020086e <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201714:	00005797          	auipc	a5,0x5
ffffffffc0201718:	d647b783          	ld	a5,-668(a5) # ffffffffc0206478 <pmm_manager>
ffffffffc020171c:	6f9c                	ld	a5,24(a5)
ffffffffc020171e:	8522                	mv	a0,s0
ffffffffc0201720:	9782                	jalr	a5
ffffffffc0201722:	842a                	mv	s0,a0
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
ffffffffc0201724:	944ff0ef          	jal	ra,ffffffffc0200868 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0201728:	60a2                	ld	ra,8(sp)
ffffffffc020172a:	8522                	mv	a0,s0
ffffffffc020172c:	6402                	ld	s0,0(sp)
ffffffffc020172e:	0141                	addi	sp,sp,16
ffffffffc0201730:	8082                	ret

ffffffffc0201732 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201732:	100027f3          	csrr	a5,sstatus
ffffffffc0201736:	8b89                	andi	a5,a5,2
ffffffffc0201738:	e799                	bnez	a5,ffffffffc0201746 <free_pages+0x14>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc020173a:	00005797          	auipc	a5,0x5
ffffffffc020173e:	d3e7b783          	ld	a5,-706(a5) # ffffffffc0206478 <pmm_manager>
ffffffffc0201742:	739c                	ld	a5,32(a5)
ffffffffc0201744:	8782                	jr	a5
void free_pages(struct Page *base, size_t n) {
ffffffffc0201746:	1101                	addi	sp,sp,-32
ffffffffc0201748:	ec06                	sd	ra,24(sp)
ffffffffc020174a:	e822                	sd	s0,16(sp)
ffffffffc020174c:	e426                	sd	s1,8(sp)
ffffffffc020174e:	842a                	mv	s0,a0
ffffffffc0201750:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0201752:	91cff0ef          	jal	ra,ffffffffc020086e <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201756:	00005797          	auipc	a5,0x5
ffffffffc020175a:	d227b783          	ld	a5,-734(a5) # ffffffffc0206478 <pmm_manager>
ffffffffc020175e:	739c                	ld	a5,32(a5)
ffffffffc0201760:	85a6                	mv	a1,s1
ffffffffc0201762:	8522                	mv	a0,s0
ffffffffc0201764:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201766:	6442                	ld	s0,16(sp)
ffffffffc0201768:	60e2                	ld	ra,24(sp)
ffffffffc020176a:	64a2                	ld	s1,8(sp)
ffffffffc020176c:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc020176e:	8faff06f          	j	ffffffffc0200868 <intr_enable>

ffffffffc0201772 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201772:	100027f3          	csrr	a5,sstatus
ffffffffc0201776:	8b89                	andi	a5,a5,2
ffffffffc0201778:	e799                	bnez	a5,ffffffffc0201786 <nr_free_pages+0x14>
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc020177a:	00005797          	auipc	a5,0x5
ffffffffc020177e:	cfe7b783          	ld	a5,-770(a5) # ffffffffc0206478 <pmm_manager>
ffffffffc0201782:	779c                	ld	a5,40(a5)
ffffffffc0201784:	8782                	jr	a5
size_t nr_free_pages(void) {
ffffffffc0201786:	1141                	addi	sp,sp,-16
ffffffffc0201788:	e406                	sd	ra,8(sp)
ffffffffc020178a:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc020178c:	8e2ff0ef          	jal	ra,ffffffffc020086e <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201790:	00005797          	auipc	a5,0x5
ffffffffc0201794:	ce87b783          	ld	a5,-792(a5) # ffffffffc0206478 <pmm_manager>
ffffffffc0201798:	779c                	ld	a5,40(a5)
ffffffffc020179a:	9782                	jalr	a5
ffffffffc020179c:	842a                	mv	s0,a0
        intr_enable();
ffffffffc020179e:	8caff0ef          	jal	ra,ffffffffc0200868 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc02017a2:	60a2                	ld	ra,8(sp)
ffffffffc02017a4:	8522                	mv	a0,s0
ffffffffc02017a6:	6402                	ld	s0,0(sp)
ffffffffc02017a8:	0141                	addi	sp,sp,16
ffffffffc02017aa:	8082                	ret

ffffffffc02017ac <pmm_init>:
    pmm_manager = &best_fit_pmm_manager;
ffffffffc02017ac:	00001797          	auipc	a5,0x1
ffffffffc02017b0:	47478793          	addi	a5,a5,1140 # ffffffffc0202c20 <best_fit_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02017b4:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc02017b6:	7179                	addi	sp,sp,-48
ffffffffc02017b8:	f022                	sd	s0,32(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02017ba:	00001517          	auipc	a0,0x1
ffffffffc02017be:	49e50513          	addi	a0,a0,1182 # ffffffffc0202c58 <best_fit_pmm_manager+0x38>
    pmm_manager = &best_fit_pmm_manager;
ffffffffc02017c2:	00005417          	auipc	s0,0x5
ffffffffc02017c6:	cb640413          	addi	s0,s0,-842 # ffffffffc0206478 <pmm_manager>
void pmm_init(void) {
ffffffffc02017ca:	f406                	sd	ra,40(sp)
ffffffffc02017cc:	ec26                	sd	s1,24(sp)
ffffffffc02017ce:	e44e                	sd	s3,8(sp)
ffffffffc02017d0:	e84a                	sd	s2,16(sp)
ffffffffc02017d2:	e052                	sd	s4,0(sp)
    pmm_manager = &best_fit_pmm_manager;
ffffffffc02017d4:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02017d6:	93dfe0ef          	jal	ra,ffffffffc0200112 <cprintf>
    pmm_manager->init();
ffffffffc02017da:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02017dc:	00005497          	auipc	s1,0x5
ffffffffc02017e0:	cb448493          	addi	s1,s1,-844 # ffffffffc0206490 <va_pa_offset>
    pmm_manager->init();
ffffffffc02017e4:	679c                	ld	a5,8(a5)
ffffffffc02017e6:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02017e8:	57f5                	li	a5,-3
ffffffffc02017ea:	07fa                	slli	a5,a5,0x1e
ffffffffc02017ec:	e09c                	sd	a5,0(s1)
    uint64_t mem_begin = get_memory_base();
ffffffffc02017ee:	866ff0ef          	jal	ra,ffffffffc0200854 <get_memory_base>
ffffffffc02017f2:	89aa                	mv	s3,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc02017f4:	86aff0ef          	jal	ra,ffffffffc020085e <get_memory_size>
    if (mem_size == 0) {
ffffffffc02017f8:	16050163          	beqz	a0,ffffffffc020195a <pmm_init+0x1ae>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc02017fc:	892a                	mv	s2,a0
    cprintf("physcial memory map:\n");
ffffffffc02017fe:	00001517          	auipc	a0,0x1
ffffffffc0201802:	4a250513          	addi	a0,a0,1186 # ffffffffc0202ca0 <best_fit_pmm_manager+0x80>
ffffffffc0201806:	90dfe0ef          	jal	ra,ffffffffc0200112 <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc020180a:	01298a33          	add	s4,s3,s2
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc020180e:	864e                	mv	a2,s3
ffffffffc0201810:	fffa0693          	addi	a3,s4,-1
ffffffffc0201814:	85ca                	mv	a1,s2
ffffffffc0201816:	00001517          	auipc	a0,0x1
ffffffffc020181a:	4a250513          	addi	a0,a0,1186 # ffffffffc0202cb8 <best_fit_pmm_manager+0x98>
ffffffffc020181e:	8f5fe0ef          	jal	ra,ffffffffc0200112 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0201822:	c80007b7          	lui	a5,0xc8000
ffffffffc0201826:	8652                	mv	a2,s4
ffffffffc0201828:	0d47e863          	bltu	a5,s4,ffffffffc02018f8 <pmm_init+0x14c>
ffffffffc020182c:	00006797          	auipc	a5,0x6
ffffffffc0201830:	c7378793          	addi	a5,a5,-909 # ffffffffc020749f <end+0xfff>
ffffffffc0201834:	757d                	lui	a0,0xfffff
ffffffffc0201836:	8d7d                	and	a0,a0,a5
ffffffffc0201838:	8231                	srli	a2,a2,0xc
ffffffffc020183a:	00005597          	auipc	a1,0x5
ffffffffc020183e:	c2e58593          	addi	a1,a1,-978 # ffffffffc0206468 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201842:	00005817          	auipc	a6,0x5
ffffffffc0201846:	c2e80813          	addi	a6,a6,-978 # ffffffffc0206470 <pages>
    npage = maxpa / PGSIZE;
ffffffffc020184a:	e190                	sd	a2,0(a1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020184c:	00a83023          	sd	a0,0(a6)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201850:	000807b7          	lui	a5,0x80
ffffffffc0201854:	02f60663          	beq	a2,a5,ffffffffc0201880 <pmm_init+0xd4>
ffffffffc0201858:	4701                	li	a4,0
ffffffffc020185a:	4781                	li	a5,0
ffffffffc020185c:	4305                	li	t1,1
ffffffffc020185e:	fff808b7          	lui	a7,0xfff80
        SetPageReserved(pages + i);
ffffffffc0201862:	953a                	add	a0,a0,a4
ffffffffc0201864:	00850693          	addi	a3,a0,8 # fffffffffffff008 <end+0x3fdf8b68>
ffffffffc0201868:	4066b02f          	amoor.d	zero,t1,(a3)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc020186c:	6190                	ld	a2,0(a1)
ffffffffc020186e:	0785                	addi	a5,a5,1
        SetPageReserved(pages + i);
ffffffffc0201870:	00083503          	ld	a0,0(a6)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201874:	011606b3          	add	a3,a2,a7
ffffffffc0201878:	02870713          	addi	a4,a4,40
ffffffffc020187c:	fed7e3e3          	bltu	a5,a3,ffffffffc0201862 <pmm_init+0xb6>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201880:	00261693          	slli	a3,a2,0x2
ffffffffc0201884:	96b2                	add	a3,a3,a2
ffffffffc0201886:	fec007b7          	lui	a5,0xfec00
ffffffffc020188a:	97aa                	add	a5,a5,a0
ffffffffc020188c:	068e                	slli	a3,a3,0x3
ffffffffc020188e:	96be                	add	a3,a3,a5
ffffffffc0201890:	c02007b7          	lui	a5,0xc0200
ffffffffc0201894:	0af6e763          	bltu	a3,a5,ffffffffc0201942 <pmm_init+0x196>
ffffffffc0201898:	6098                	ld	a4,0(s1)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc020189a:	77fd                	lui	a5,0xfffff
ffffffffc020189c:	00fa75b3          	and	a1,s4,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02018a0:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc02018a2:	04b6ee63          	bltu	a3,a1,ffffffffc02018fe <pmm_init+0x152>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc02018a6:	601c                	ld	a5,0(s0)
ffffffffc02018a8:	7b9c                	ld	a5,48(a5)
ffffffffc02018aa:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc02018ac:	00001517          	auipc	a0,0x1
ffffffffc02018b0:	49450513          	addi	a0,a0,1172 # ffffffffc0202d40 <best_fit_pmm_manager+0x120>
ffffffffc02018b4:	85ffe0ef          	jal	ra,ffffffffc0200112 <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc02018b8:	00003597          	auipc	a1,0x3
ffffffffc02018bc:	74858593          	addi	a1,a1,1864 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc02018c0:	00005797          	auipc	a5,0x5
ffffffffc02018c4:	bcb7b423          	sd	a1,-1080(a5) # ffffffffc0206488 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc02018c8:	c02007b7          	lui	a5,0xc0200
ffffffffc02018cc:	0af5e363          	bltu	a1,a5,ffffffffc0201972 <pmm_init+0x1c6>
ffffffffc02018d0:	6090                	ld	a2,0(s1)
}
ffffffffc02018d2:	7402                	ld	s0,32(sp)
ffffffffc02018d4:	70a2                	ld	ra,40(sp)
ffffffffc02018d6:	64e2                	ld	s1,24(sp)
ffffffffc02018d8:	6942                	ld	s2,16(sp)
ffffffffc02018da:	69a2                	ld	s3,8(sp)
ffffffffc02018dc:	6a02                	ld	s4,0(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc02018de:	40c58633          	sub	a2,a1,a2
ffffffffc02018e2:	00005797          	auipc	a5,0x5
ffffffffc02018e6:	b8c7bf23          	sd	a2,-1122(a5) # ffffffffc0206480 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02018ea:	00001517          	auipc	a0,0x1
ffffffffc02018ee:	47650513          	addi	a0,a0,1142 # ffffffffc0202d60 <best_fit_pmm_manager+0x140>
}
ffffffffc02018f2:	6145                	addi	sp,sp,48
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02018f4:	81ffe06f          	j	ffffffffc0200112 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc02018f8:	c8000637          	lui	a2,0xc8000
ffffffffc02018fc:	bf05                	j	ffffffffc020182c <pmm_init+0x80>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc02018fe:	6705                	lui	a4,0x1
ffffffffc0201900:	177d                	addi	a4,a4,-1
ffffffffc0201902:	96ba                	add	a3,a3,a4
ffffffffc0201904:	8efd                	and	a3,a3,a5
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0201906:	00c6d793          	srli	a5,a3,0xc
ffffffffc020190a:	02c7f063          	bgeu	a5,a2,ffffffffc020192a <pmm_init+0x17e>
    pmm_manager->init_memmap(base, n);
ffffffffc020190e:	6010                	ld	a2,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc0201910:	fff80737          	lui	a4,0xfff80
ffffffffc0201914:	973e                	add	a4,a4,a5
ffffffffc0201916:	00271793          	slli	a5,a4,0x2
ffffffffc020191a:	97ba                	add	a5,a5,a4
ffffffffc020191c:	6a18                	ld	a4,16(a2)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc020191e:	8d95                	sub	a1,a1,a3
ffffffffc0201920:	078e                	slli	a5,a5,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc0201922:	81b1                	srli	a1,a1,0xc
ffffffffc0201924:	953e                	add	a0,a0,a5
ffffffffc0201926:	9702                	jalr	a4
}
ffffffffc0201928:	bfbd                	j	ffffffffc02018a6 <pmm_init+0xfa>
        panic("pa2page called with invalid pa");
ffffffffc020192a:	00001617          	auipc	a2,0x1
ffffffffc020192e:	3e660613          	addi	a2,a2,998 # ffffffffc0202d10 <best_fit_pmm_manager+0xf0>
ffffffffc0201932:	06b00593          	li	a1,107
ffffffffc0201936:	00001517          	auipc	a0,0x1
ffffffffc020193a:	3fa50513          	addi	a0,a0,1018 # ffffffffc0202d30 <best_fit_pmm_manager+0x110>
ffffffffc020193e:	acffe0ef          	jal	ra,ffffffffc020040c <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201942:	00001617          	auipc	a2,0x1
ffffffffc0201946:	3a660613          	addi	a2,a2,934 # ffffffffc0202ce8 <best_fit_pmm_manager+0xc8>
ffffffffc020194a:	07100593          	li	a1,113
ffffffffc020194e:	00001517          	auipc	a0,0x1
ffffffffc0201952:	34250513          	addi	a0,a0,834 # ffffffffc0202c90 <best_fit_pmm_manager+0x70>
ffffffffc0201956:	ab7fe0ef          	jal	ra,ffffffffc020040c <__panic>
        panic("DTB memory info not available");
ffffffffc020195a:	00001617          	auipc	a2,0x1
ffffffffc020195e:	31660613          	addi	a2,a2,790 # ffffffffc0202c70 <best_fit_pmm_manager+0x50>
ffffffffc0201962:	05a00593          	li	a1,90
ffffffffc0201966:	00001517          	auipc	a0,0x1
ffffffffc020196a:	32a50513          	addi	a0,a0,810 # ffffffffc0202c90 <best_fit_pmm_manager+0x70>
ffffffffc020196e:	a9ffe0ef          	jal	ra,ffffffffc020040c <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201972:	86ae                	mv	a3,a1
ffffffffc0201974:	00001617          	auipc	a2,0x1
ffffffffc0201978:	37460613          	addi	a2,a2,884 # ffffffffc0202ce8 <best_fit_pmm_manager+0xc8>
ffffffffc020197c:	08c00593          	li	a1,140
ffffffffc0201980:	00001517          	auipc	a0,0x1
ffffffffc0201984:	31050513          	addi	a0,a0,784 # ffffffffc0202c90 <best_fit_pmm_manager+0x70>
ffffffffc0201988:	a85fe0ef          	jal	ra,ffffffffc020040c <__panic>

ffffffffc020198c <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc020198c:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201990:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0201992:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201996:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0201998:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020199c:	f022                	sd	s0,32(sp)
ffffffffc020199e:	ec26                	sd	s1,24(sp)
ffffffffc02019a0:	e84a                	sd	s2,16(sp)
ffffffffc02019a2:	f406                	sd	ra,40(sp)
ffffffffc02019a4:	e44e                	sd	s3,8(sp)
ffffffffc02019a6:	84aa                	mv	s1,a0
ffffffffc02019a8:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc02019aa:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc02019ae:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc02019b0:	03067e63          	bgeu	a2,a6,ffffffffc02019ec <printnum+0x60>
ffffffffc02019b4:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc02019b6:	00805763          	blez	s0,ffffffffc02019c4 <printnum+0x38>
ffffffffc02019ba:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc02019bc:	85ca                	mv	a1,s2
ffffffffc02019be:	854e                	mv	a0,s3
ffffffffc02019c0:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc02019c2:	fc65                	bnez	s0,ffffffffc02019ba <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02019c4:	1a02                	slli	s4,s4,0x20
ffffffffc02019c6:	00001797          	auipc	a5,0x1
ffffffffc02019ca:	3da78793          	addi	a5,a5,986 # ffffffffc0202da0 <best_fit_pmm_manager+0x180>
ffffffffc02019ce:	020a5a13          	srli	s4,s4,0x20
ffffffffc02019d2:	9a3e                	add	s4,s4,a5
}
ffffffffc02019d4:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02019d6:	000a4503          	lbu	a0,0(s4)
}
ffffffffc02019da:	70a2                	ld	ra,40(sp)
ffffffffc02019dc:	69a2                	ld	s3,8(sp)
ffffffffc02019de:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02019e0:	85ca                	mv	a1,s2
ffffffffc02019e2:	87a6                	mv	a5,s1
}
ffffffffc02019e4:	6942                	ld	s2,16(sp)
ffffffffc02019e6:	64e2                	ld	s1,24(sp)
ffffffffc02019e8:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02019ea:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc02019ec:	03065633          	divu	a2,a2,a6
ffffffffc02019f0:	8722                	mv	a4,s0
ffffffffc02019f2:	f9bff0ef          	jal	ra,ffffffffc020198c <printnum>
ffffffffc02019f6:	b7f9                	j	ffffffffc02019c4 <printnum+0x38>

ffffffffc02019f8 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc02019f8:	7119                	addi	sp,sp,-128
ffffffffc02019fa:	f4a6                	sd	s1,104(sp)
ffffffffc02019fc:	f0ca                	sd	s2,96(sp)
ffffffffc02019fe:	ecce                	sd	s3,88(sp)
ffffffffc0201a00:	e8d2                	sd	s4,80(sp)
ffffffffc0201a02:	e4d6                	sd	s5,72(sp)
ffffffffc0201a04:	e0da                	sd	s6,64(sp)
ffffffffc0201a06:	fc5e                	sd	s7,56(sp)
ffffffffc0201a08:	f06a                	sd	s10,32(sp)
ffffffffc0201a0a:	fc86                	sd	ra,120(sp)
ffffffffc0201a0c:	f8a2                	sd	s0,112(sp)
ffffffffc0201a0e:	f862                	sd	s8,48(sp)
ffffffffc0201a10:	f466                	sd	s9,40(sp)
ffffffffc0201a12:	ec6e                	sd	s11,24(sp)
ffffffffc0201a14:	892a                	mv	s2,a0
ffffffffc0201a16:	84ae                	mv	s1,a1
ffffffffc0201a18:	8d32                	mv	s10,a2
ffffffffc0201a1a:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201a1c:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0201a20:	5b7d                	li	s6,-1
ffffffffc0201a22:	00001a97          	auipc	s5,0x1
ffffffffc0201a26:	3b2a8a93          	addi	s5,s5,946 # ffffffffc0202dd4 <best_fit_pmm_manager+0x1b4>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201a2a:	00001b97          	auipc	s7,0x1
ffffffffc0201a2e:	586b8b93          	addi	s7,s7,1414 # ffffffffc0202fb0 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201a32:	000d4503          	lbu	a0,0(s10)
ffffffffc0201a36:	001d0413          	addi	s0,s10,1
ffffffffc0201a3a:	01350a63          	beq	a0,s3,ffffffffc0201a4e <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0201a3e:	c121                	beqz	a0,ffffffffc0201a7e <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0201a40:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201a42:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0201a44:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201a46:	fff44503          	lbu	a0,-1(s0)
ffffffffc0201a4a:	ff351ae3          	bne	a0,s3,ffffffffc0201a3e <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201a4e:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0201a52:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0201a56:	4c81                	li	s9,0
ffffffffc0201a58:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0201a5a:	5c7d                	li	s8,-1
ffffffffc0201a5c:	5dfd                	li	s11,-1
ffffffffc0201a5e:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0201a62:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201a64:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201a68:	0ff5f593          	zext.b	a1,a1
ffffffffc0201a6c:	00140d13          	addi	s10,s0,1
ffffffffc0201a70:	04b56263          	bltu	a0,a1,ffffffffc0201ab4 <vprintfmt+0xbc>
ffffffffc0201a74:	058a                	slli	a1,a1,0x2
ffffffffc0201a76:	95d6                	add	a1,a1,s5
ffffffffc0201a78:	4194                	lw	a3,0(a1)
ffffffffc0201a7a:	96d6                	add	a3,a3,s5
ffffffffc0201a7c:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0201a7e:	70e6                	ld	ra,120(sp)
ffffffffc0201a80:	7446                	ld	s0,112(sp)
ffffffffc0201a82:	74a6                	ld	s1,104(sp)
ffffffffc0201a84:	7906                	ld	s2,96(sp)
ffffffffc0201a86:	69e6                	ld	s3,88(sp)
ffffffffc0201a88:	6a46                	ld	s4,80(sp)
ffffffffc0201a8a:	6aa6                	ld	s5,72(sp)
ffffffffc0201a8c:	6b06                	ld	s6,64(sp)
ffffffffc0201a8e:	7be2                	ld	s7,56(sp)
ffffffffc0201a90:	7c42                	ld	s8,48(sp)
ffffffffc0201a92:	7ca2                	ld	s9,40(sp)
ffffffffc0201a94:	7d02                	ld	s10,32(sp)
ffffffffc0201a96:	6de2                	ld	s11,24(sp)
ffffffffc0201a98:	6109                	addi	sp,sp,128
ffffffffc0201a9a:	8082                	ret
            padc = '0';
ffffffffc0201a9c:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0201a9e:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201aa2:	846a                	mv	s0,s10
ffffffffc0201aa4:	00140d13          	addi	s10,s0,1
ffffffffc0201aa8:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201aac:	0ff5f593          	zext.b	a1,a1
ffffffffc0201ab0:	fcb572e3          	bgeu	a0,a1,ffffffffc0201a74 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0201ab4:	85a6                	mv	a1,s1
ffffffffc0201ab6:	02500513          	li	a0,37
ffffffffc0201aba:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201abc:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201ac0:	8d22                	mv	s10,s0
ffffffffc0201ac2:	f73788e3          	beq	a5,s3,ffffffffc0201a32 <vprintfmt+0x3a>
ffffffffc0201ac6:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0201aca:	1d7d                	addi	s10,s10,-1
ffffffffc0201acc:	ff379de3          	bne	a5,s3,ffffffffc0201ac6 <vprintfmt+0xce>
ffffffffc0201ad0:	b78d                	j	ffffffffc0201a32 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0201ad2:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0201ad6:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201ada:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0201adc:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0201ae0:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201ae4:	02d86463          	bltu	a6,a3,ffffffffc0201b0c <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0201ae8:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0201aec:	002c169b          	slliw	a3,s8,0x2
ffffffffc0201af0:	0186873b          	addw	a4,a3,s8
ffffffffc0201af4:	0017171b          	slliw	a4,a4,0x1
ffffffffc0201af8:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0201afa:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0201afe:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0201b00:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0201b04:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201b08:	fed870e3          	bgeu	a6,a3,ffffffffc0201ae8 <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0201b0c:	f40ddce3          	bgez	s11,ffffffffc0201a64 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0201b10:	8de2                	mv	s11,s8
ffffffffc0201b12:	5c7d                	li	s8,-1
ffffffffc0201b14:	bf81                	j	ffffffffc0201a64 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0201b16:	fffdc693          	not	a3,s11
ffffffffc0201b1a:	96fd                	srai	a3,a3,0x3f
ffffffffc0201b1c:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b20:	00144603          	lbu	a2,1(s0)
ffffffffc0201b24:	2d81                	sext.w	s11,s11
ffffffffc0201b26:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201b28:	bf35                	j	ffffffffc0201a64 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0201b2a:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b2e:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0201b32:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b34:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0201b36:	bfd9                	j	ffffffffc0201b0c <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0201b38:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201b3a:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201b3e:	01174463          	blt	a4,a7,ffffffffc0201b46 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0201b42:	1a088e63          	beqz	a7,ffffffffc0201cfe <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0201b46:	000a3603          	ld	a2,0(s4)
ffffffffc0201b4a:	46c1                	li	a3,16
ffffffffc0201b4c:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201b4e:	2781                	sext.w	a5,a5
ffffffffc0201b50:	876e                	mv	a4,s11
ffffffffc0201b52:	85a6                	mv	a1,s1
ffffffffc0201b54:	854a                	mv	a0,s2
ffffffffc0201b56:	e37ff0ef          	jal	ra,ffffffffc020198c <printnum>
            break;
ffffffffc0201b5a:	bde1                	j	ffffffffc0201a32 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0201b5c:	000a2503          	lw	a0,0(s4)
ffffffffc0201b60:	85a6                	mv	a1,s1
ffffffffc0201b62:	0a21                	addi	s4,s4,8
ffffffffc0201b64:	9902                	jalr	s2
            break;
ffffffffc0201b66:	b5f1                	j	ffffffffc0201a32 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201b68:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201b6a:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201b6e:	01174463          	blt	a4,a7,ffffffffc0201b76 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0201b72:	18088163          	beqz	a7,ffffffffc0201cf4 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0201b76:	000a3603          	ld	a2,0(s4)
ffffffffc0201b7a:	46a9                	li	a3,10
ffffffffc0201b7c:	8a2e                	mv	s4,a1
ffffffffc0201b7e:	bfc1                	j	ffffffffc0201b4e <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b80:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0201b84:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b86:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201b88:	bdf1                	j	ffffffffc0201a64 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0201b8a:	85a6                	mv	a1,s1
ffffffffc0201b8c:	02500513          	li	a0,37
ffffffffc0201b90:	9902                	jalr	s2
            break;
ffffffffc0201b92:	b545                	j	ffffffffc0201a32 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b94:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0201b98:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b9a:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201b9c:	b5e1                	j	ffffffffc0201a64 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0201b9e:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201ba0:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201ba4:	01174463          	blt	a4,a7,ffffffffc0201bac <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0201ba8:	14088163          	beqz	a7,ffffffffc0201cea <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0201bac:	000a3603          	ld	a2,0(s4)
ffffffffc0201bb0:	46a1                	li	a3,8
ffffffffc0201bb2:	8a2e                	mv	s4,a1
ffffffffc0201bb4:	bf69                	j	ffffffffc0201b4e <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0201bb6:	03000513          	li	a0,48
ffffffffc0201bba:	85a6                	mv	a1,s1
ffffffffc0201bbc:	e03e                	sd	a5,0(sp)
ffffffffc0201bbe:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0201bc0:	85a6                	mv	a1,s1
ffffffffc0201bc2:	07800513          	li	a0,120
ffffffffc0201bc6:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201bc8:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0201bca:	6782                	ld	a5,0(sp)
ffffffffc0201bcc:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201bce:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0201bd2:	bfb5                	j	ffffffffc0201b4e <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201bd4:	000a3403          	ld	s0,0(s4)
ffffffffc0201bd8:	008a0713          	addi	a4,s4,8
ffffffffc0201bdc:	e03a                	sd	a4,0(sp)
ffffffffc0201bde:	14040263          	beqz	s0,ffffffffc0201d22 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0201be2:	0fb05763          	blez	s11,ffffffffc0201cd0 <vprintfmt+0x2d8>
ffffffffc0201be6:	02d00693          	li	a3,45
ffffffffc0201bea:	0cd79163          	bne	a5,a3,ffffffffc0201cac <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201bee:	00044783          	lbu	a5,0(s0)
ffffffffc0201bf2:	0007851b          	sext.w	a0,a5
ffffffffc0201bf6:	cf85                	beqz	a5,ffffffffc0201c2e <vprintfmt+0x236>
ffffffffc0201bf8:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201bfc:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201c00:	000c4563          	bltz	s8,ffffffffc0201c0a <vprintfmt+0x212>
ffffffffc0201c04:	3c7d                	addiw	s8,s8,-1
ffffffffc0201c06:	036c0263          	beq	s8,s6,ffffffffc0201c2a <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0201c0a:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201c0c:	0e0c8e63          	beqz	s9,ffffffffc0201d08 <vprintfmt+0x310>
ffffffffc0201c10:	3781                	addiw	a5,a5,-32
ffffffffc0201c12:	0ef47b63          	bgeu	s0,a5,ffffffffc0201d08 <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0201c16:	03f00513          	li	a0,63
ffffffffc0201c1a:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201c1c:	000a4783          	lbu	a5,0(s4)
ffffffffc0201c20:	3dfd                	addiw	s11,s11,-1
ffffffffc0201c22:	0a05                	addi	s4,s4,1
ffffffffc0201c24:	0007851b          	sext.w	a0,a5
ffffffffc0201c28:	ffe1                	bnez	a5,ffffffffc0201c00 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0201c2a:	01b05963          	blez	s11,ffffffffc0201c3c <vprintfmt+0x244>
ffffffffc0201c2e:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0201c30:	85a6                	mv	a1,s1
ffffffffc0201c32:	02000513          	li	a0,32
ffffffffc0201c36:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201c38:	fe0d9be3          	bnez	s11,ffffffffc0201c2e <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201c3c:	6a02                	ld	s4,0(sp)
ffffffffc0201c3e:	bbd5                	j	ffffffffc0201a32 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201c40:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201c42:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0201c46:	01174463          	blt	a4,a7,ffffffffc0201c4e <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0201c4a:	08088d63          	beqz	a7,ffffffffc0201ce4 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0201c4e:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0201c52:	0a044d63          	bltz	s0,ffffffffc0201d0c <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0201c56:	8622                	mv	a2,s0
ffffffffc0201c58:	8a66                	mv	s4,s9
ffffffffc0201c5a:	46a9                	li	a3,10
ffffffffc0201c5c:	bdcd                	j	ffffffffc0201b4e <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0201c5e:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201c62:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0201c64:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0201c66:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0201c6a:	8fb5                	xor	a5,a5,a3
ffffffffc0201c6c:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201c70:	02d74163          	blt	a4,a3,ffffffffc0201c92 <vprintfmt+0x29a>
ffffffffc0201c74:	00369793          	slli	a5,a3,0x3
ffffffffc0201c78:	97de                	add	a5,a5,s7
ffffffffc0201c7a:	639c                	ld	a5,0(a5)
ffffffffc0201c7c:	cb99                	beqz	a5,ffffffffc0201c92 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201c7e:	86be                	mv	a3,a5
ffffffffc0201c80:	00001617          	auipc	a2,0x1
ffffffffc0201c84:	15060613          	addi	a2,a2,336 # ffffffffc0202dd0 <best_fit_pmm_manager+0x1b0>
ffffffffc0201c88:	85a6                	mv	a1,s1
ffffffffc0201c8a:	854a                	mv	a0,s2
ffffffffc0201c8c:	0ce000ef          	jal	ra,ffffffffc0201d5a <printfmt>
ffffffffc0201c90:	b34d                	j	ffffffffc0201a32 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201c92:	00001617          	auipc	a2,0x1
ffffffffc0201c96:	12e60613          	addi	a2,a2,302 # ffffffffc0202dc0 <best_fit_pmm_manager+0x1a0>
ffffffffc0201c9a:	85a6                	mv	a1,s1
ffffffffc0201c9c:	854a                	mv	a0,s2
ffffffffc0201c9e:	0bc000ef          	jal	ra,ffffffffc0201d5a <printfmt>
ffffffffc0201ca2:	bb41                	j	ffffffffc0201a32 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0201ca4:	00001417          	auipc	s0,0x1
ffffffffc0201ca8:	11440413          	addi	s0,s0,276 # ffffffffc0202db8 <best_fit_pmm_manager+0x198>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201cac:	85e2                	mv	a1,s8
ffffffffc0201cae:	8522                	mv	a0,s0
ffffffffc0201cb0:	e43e                	sd	a5,8(sp)
ffffffffc0201cb2:	200000ef          	jal	ra,ffffffffc0201eb2 <strnlen>
ffffffffc0201cb6:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0201cba:	01b05b63          	blez	s11,ffffffffc0201cd0 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0201cbe:	67a2                	ld	a5,8(sp)
ffffffffc0201cc0:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201cc4:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0201cc6:	85a6                	mv	a1,s1
ffffffffc0201cc8:	8552                	mv	a0,s4
ffffffffc0201cca:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201ccc:	fe0d9ce3          	bnez	s11,ffffffffc0201cc4 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201cd0:	00044783          	lbu	a5,0(s0)
ffffffffc0201cd4:	00140a13          	addi	s4,s0,1
ffffffffc0201cd8:	0007851b          	sext.w	a0,a5
ffffffffc0201cdc:	d3a5                	beqz	a5,ffffffffc0201c3c <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201cde:	05e00413          	li	s0,94
ffffffffc0201ce2:	bf39                	j	ffffffffc0201c00 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0201ce4:	000a2403          	lw	s0,0(s4)
ffffffffc0201ce8:	b7ad                	j	ffffffffc0201c52 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0201cea:	000a6603          	lwu	a2,0(s4)
ffffffffc0201cee:	46a1                	li	a3,8
ffffffffc0201cf0:	8a2e                	mv	s4,a1
ffffffffc0201cf2:	bdb1                	j	ffffffffc0201b4e <vprintfmt+0x156>
ffffffffc0201cf4:	000a6603          	lwu	a2,0(s4)
ffffffffc0201cf8:	46a9                	li	a3,10
ffffffffc0201cfa:	8a2e                	mv	s4,a1
ffffffffc0201cfc:	bd89                	j	ffffffffc0201b4e <vprintfmt+0x156>
ffffffffc0201cfe:	000a6603          	lwu	a2,0(s4)
ffffffffc0201d02:	46c1                	li	a3,16
ffffffffc0201d04:	8a2e                	mv	s4,a1
ffffffffc0201d06:	b5a1                	j	ffffffffc0201b4e <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0201d08:	9902                	jalr	s2
ffffffffc0201d0a:	bf09                	j	ffffffffc0201c1c <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0201d0c:	85a6                	mv	a1,s1
ffffffffc0201d0e:	02d00513          	li	a0,45
ffffffffc0201d12:	e03e                	sd	a5,0(sp)
ffffffffc0201d14:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0201d16:	6782                	ld	a5,0(sp)
ffffffffc0201d18:	8a66                	mv	s4,s9
ffffffffc0201d1a:	40800633          	neg	a2,s0
ffffffffc0201d1e:	46a9                	li	a3,10
ffffffffc0201d20:	b53d                	j	ffffffffc0201b4e <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0201d22:	03b05163          	blez	s11,ffffffffc0201d44 <vprintfmt+0x34c>
ffffffffc0201d26:	02d00693          	li	a3,45
ffffffffc0201d2a:	f6d79de3          	bne	a5,a3,ffffffffc0201ca4 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0201d2e:	00001417          	auipc	s0,0x1
ffffffffc0201d32:	08a40413          	addi	s0,s0,138 # ffffffffc0202db8 <best_fit_pmm_manager+0x198>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201d36:	02800793          	li	a5,40
ffffffffc0201d3a:	02800513          	li	a0,40
ffffffffc0201d3e:	00140a13          	addi	s4,s0,1
ffffffffc0201d42:	bd6d                	j	ffffffffc0201bfc <vprintfmt+0x204>
ffffffffc0201d44:	00001a17          	auipc	s4,0x1
ffffffffc0201d48:	075a0a13          	addi	s4,s4,117 # ffffffffc0202db9 <best_fit_pmm_manager+0x199>
ffffffffc0201d4c:	02800513          	li	a0,40
ffffffffc0201d50:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201d54:	05e00413          	li	s0,94
ffffffffc0201d58:	b565                	j	ffffffffc0201c00 <vprintfmt+0x208>

ffffffffc0201d5a <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201d5a:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201d5c:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201d60:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201d62:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201d64:	ec06                	sd	ra,24(sp)
ffffffffc0201d66:	f83a                	sd	a4,48(sp)
ffffffffc0201d68:	fc3e                	sd	a5,56(sp)
ffffffffc0201d6a:	e0c2                	sd	a6,64(sp)
ffffffffc0201d6c:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201d6e:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201d70:	c89ff0ef          	jal	ra,ffffffffc02019f8 <vprintfmt>
}
ffffffffc0201d74:	60e2                	ld	ra,24(sp)
ffffffffc0201d76:	6161                	addi	sp,sp,80
ffffffffc0201d78:	8082                	ret

ffffffffc0201d7a <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0201d7a:	715d                	addi	sp,sp,-80
ffffffffc0201d7c:	e486                	sd	ra,72(sp)
ffffffffc0201d7e:	e0a6                	sd	s1,64(sp)
ffffffffc0201d80:	fc4a                	sd	s2,56(sp)
ffffffffc0201d82:	f84e                	sd	s3,48(sp)
ffffffffc0201d84:	f452                	sd	s4,40(sp)
ffffffffc0201d86:	f056                	sd	s5,32(sp)
ffffffffc0201d88:	ec5a                	sd	s6,24(sp)
ffffffffc0201d8a:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc0201d8c:	c901                	beqz	a0,ffffffffc0201d9c <readline+0x22>
ffffffffc0201d8e:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc0201d90:	00001517          	auipc	a0,0x1
ffffffffc0201d94:	04050513          	addi	a0,a0,64 # ffffffffc0202dd0 <best_fit_pmm_manager+0x1b0>
ffffffffc0201d98:	b7afe0ef          	jal	ra,ffffffffc0200112 <cprintf>
readline(const char *prompt) {
ffffffffc0201d9c:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201d9e:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc0201da0:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc0201da2:	4aa9                	li	s5,10
ffffffffc0201da4:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc0201da6:	00004b97          	auipc	s7,0x4
ffffffffc0201daa:	29ab8b93          	addi	s7,s7,666 # ffffffffc0206040 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201dae:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc0201db2:	bd8fe0ef          	jal	ra,ffffffffc020018a <getchar>
        if (c < 0) {
ffffffffc0201db6:	00054a63          	bltz	a0,ffffffffc0201dca <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201dba:	00a95a63          	bge	s2,a0,ffffffffc0201dce <readline+0x54>
ffffffffc0201dbe:	029a5263          	bge	s4,s1,ffffffffc0201de2 <readline+0x68>
        c = getchar();
ffffffffc0201dc2:	bc8fe0ef          	jal	ra,ffffffffc020018a <getchar>
        if (c < 0) {
ffffffffc0201dc6:	fe055ae3          	bgez	a0,ffffffffc0201dba <readline+0x40>
            return NULL;
ffffffffc0201dca:	4501                	li	a0,0
ffffffffc0201dcc:	a091                	j	ffffffffc0201e10 <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc0201dce:	03351463          	bne	a0,s3,ffffffffc0201df6 <readline+0x7c>
ffffffffc0201dd2:	e8a9                	bnez	s1,ffffffffc0201e24 <readline+0xaa>
        c = getchar();
ffffffffc0201dd4:	bb6fe0ef          	jal	ra,ffffffffc020018a <getchar>
        if (c < 0) {
ffffffffc0201dd8:	fe0549e3          	bltz	a0,ffffffffc0201dca <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201ddc:	fea959e3          	bge	s2,a0,ffffffffc0201dce <readline+0x54>
ffffffffc0201de0:	4481                	li	s1,0
            cputchar(c);
ffffffffc0201de2:	e42a                	sd	a0,8(sp)
ffffffffc0201de4:	b64fe0ef          	jal	ra,ffffffffc0200148 <cputchar>
            buf[i ++] = c;
ffffffffc0201de8:	6522                	ld	a0,8(sp)
ffffffffc0201dea:	009b87b3          	add	a5,s7,s1
ffffffffc0201dee:	2485                	addiw	s1,s1,1
ffffffffc0201df0:	00a78023          	sb	a0,0(a5)
ffffffffc0201df4:	bf7d                	j	ffffffffc0201db2 <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc0201df6:	01550463          	beq	a0,s5,ffffffffc0201dfe <readline+0x84>
ffffffffc0201dfa:	fb651ce3          	bne	a0,s6,ffffffffc0201db2 <readline+0x38>
            cputchar(c);
ffffffffc0201dfe:	b4afe0ef          	jal	ra,ffffffffc0200148 <cputchar>
            buf[i] = '\0';
ffffffffc0201e02:	00004517          	auipc	a0,0x4
ffffffffc0201e06:	23e50513          	addi	a0,a0,574 # ffffffffc0206040 <buf>
ffffffffc0201e0a:	94aa                	add	s1,s1,a0
ffffffffc0201e0c:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc0201e10:	60a6                	ld	ra,72(sp)
ffffffffc0201e12:	6486                	ld	s1,64(sp)
ffffffffc0201e14:	7962                	ld	s2,56(sp)
ffffffffc0201e16:	79c2                	ld	s3,48(sp)
ffffffffc0201e18:	7a22                	ld	s4,40(sp)
ffffffffc0201e1a:	7a82                	ld	s5,32(sp)
ffffffffc0201e1c:	6b62                	ld	s6,24(sp)
ffffffffc0201e1e:	6bc2                	ld	s7,16(sp)
ffffffffc0201e20:	6161                	addi	sp,sp,80
ffffffffc0201e22:	8082                	ret
            cputchar(c);
ffffffffc0201e24:	4521                	li	a0,8
ffffffffc0201e26:	b22fe0ef          	jal	ra,ffffffffc0200148 <cputchar>
            i --;
ffffffffc0201e2a:	34fd                	addiw	s1,s1,-1
ffffffffc0201e2c:	b759                	j	ffffffffc0201db2 <readline+0x38>

ffffffffc0201e2e <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc0201e2e:	4781                	li	a5,0
ffffffffc0201e30:	00004717          	auipc	a4,0x4
ffffffffc0201e34:	1e873703          	ld	a4,488(a4) # ffffffffc0206018 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201e38:	88ba                	mv	a7,a4
ffffffffc0201e3a:	852a                	mv	a0,a0
ffffffffc0201e3c:	85be                	mv	a1,a5
ffffffffc0201e3e:	863e                	mv	a2,a5
ffffffffc0201e40:	00000073          	ecall
ffffffffc0201e44:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0201e46:	8082                	ret

ffffffffc0201e48 <sbi_set_timer>:
    __asm__ volatile (
ffffffffc0201e48:	4781                	li	a5,0
ffffffffc0201e4a:	00004717          	auipc	a4,0x4
ffffffffc0201e4e:	64e73703          	ld	a4,1614(a4) # ffffffffc0206498 <SBI_SET_TIMER>
ffffffffc0201e52:	88ba                	mv	a7,a4
ffffffffc0201e54:	852a                	mv	a0,a0
ffffffffc0201e56:	85be                	mv	a1,a5
ffffffffc0201e58:	863e                	mv	a2,a5
ffffffffc0201e5a:	00000073          	ecall
ffffffffc0201e5e:	87aa                	mv	a5,a0

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
}
ffffffffc0201e60:	8082                	ret

ffffffffc0201e62 <sbi_console_getchar>:
    __asm__ volatile (
ffffffffc0201e62:	4501                	li	a0,0
ffffffffc0201e64:	00004797          	auipc	a5,0x4
ffffffffc0201e68:	1ac7b783          	ld	a5,428(a5) # ffffffffc0206010 <SBI_CONSOLE_GETCHAR>
ffffffffc0201e6c:	88be                	mv	a7,a5
ffffffffc0201e6e:	852a                	mv	a0,a0
ffffffffc0201e70:	85aa                	mv	a1,a0
ffffffffc0201e72:	862a                	mv	a2,a0
ffffffffc0201e74:	00000073          	ecall
ffffffffc0201e78:	852a                	mv	a0,a0

int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
}
ffffffffc0201e7a:	2501                	sext.w	a0,a0
ffffffffc0201e7c:	8082                	ret

ffffffffc0201e7e <sbi_shutdown>:
    __asm__ volatile (
ffffffffc0201e7e:	4781                	li	a5,0
ffffffffc0201e80:	00004717          	auipc	a4,0x4
ffffffffc0201e84:	1a073703          	ld	a4,416(a4) # ffffffffc0206020 <SBI_SHUTDOWN>
ffffffffc0201e88:	88ba                	mv	a7,a4
ffffffffc0201e8a:	853e                	mv	a0,a5
ffffffffc0201e8c:	85be                	mv	a1,a5
ffffffffc0201e8e:	863e                	mv	a2,a5
ffffffffc0201e90:	00000073          	ecall
ffffffffc0201e94:	87aa                	mv	a5,a0

void sbi_shutdown(void)
{
	sbi_call(SBI_SHUTDOWN, 0, 0, 0);
ffffffffc0201e96:	8082                	ret

ffffffffc0201e98 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0201e98:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0201e9c:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0201e9e:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0201ea0:	cb81                	beqz	a5,ffffffffc0201eb0 <strlen+0x18>
        cnt ++;
ffffffffc0201ea2:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0201ea4:	00a707b3          	add	a5,a4,a0
ffffffffc0201ea8:	0007c783          	lbu	a5,0(a5)
ffffffffc0201eac:	fbfd                	bnez	a5,ffffffffc0201ea2 <strlen+0xa>
ffffffffc0201eae:	8082                	ret
    }
    return cnt;
}
ffffffffc0201eb0:	8082                	ret

ffffffffc0201eb2 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0201eb2:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201eb4:	e589                	bnez	a1,ffffffffc0201ebe <strnlen+0xc>
ffffffffc0201eb6:	a811                	j	ffffffffc0201eca <strnlen+0x18>
        cnt ++;
ffffffffc0201eb8:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201eba:	00f58863          	beq	a1,a5,ffffffffc0201eca <strnlen+0x18>
ffffffffc0201ebe:	00f50733          	add	a4,a0,a5
ffffffffc0201ec2:	00074703          	lbu	a4,0(a4)
ffffffffc0201ec6:	fb6d                	bnez	a4,ffffffffc0201eb8 <strnlen+0x6>
ffffffffc0201ec8:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0201eca:	852e                	mv	a0,a1
ffffffffc0201ecc:	8082                	ret

ffffffffc0201ece <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201ece:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201ed2:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201ed6:	cb89                	beqz	a5,ffffffffc0201ee8 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0201ed8:	0505                	addi	a0,a0,1
ffffffffc0201eda:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201edc:	fee789e3          	beq	a5,a4,ffffffffc0201ece <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201ee0:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201ee4:	9d19                	subw	a0,a0,a4
ffffffffc0201ee6:	8082                	ret
ffffffffc0201ee8:	4501                	li	a0,0
ffffffffc0201eea:	bfed                	j	ffffffffc0201ee4 <strcmp+0x16>

ffffffffc0201eec <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201eec:	c20d                	beqz	a2,ffffffffc0201f0e <strncmp+0x22>
ffffffffc0201eee:	962e                	add	a2,a2,a1
ffffffffc0201ef0:	a031                	j	ffffffffc0201efc <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0201ef2:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201ef4:	00e79a63          	bne	a5,a4,ffffffffc0201f08 <strncmp+0x1c>
ffffffffc0201ef8:	00b60b63          	beq	a2,a1,ffffffffc0201f0e <strncmp+0x22>
ffffffffc0201efc:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0201f00:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201f02:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0201f06:	f7f5                	bnez	a5,ffffffffc0201ef2 <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201f08:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0201f0c:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201f0e:	4501                	li	a0,0
ffffffffc0201f10:	8082                	ret

ffffffffc0201f12 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0201f12:	00054783          	lbu	a5,0(a0)
ffffffffc0201f16:	c799                	beqz	a5,ffffffffc0201f24 <strchr+0x12>
        if (*s == c) {
ffffffffc0201f18:	00f58763          	beq	a1,a5,ffffffffc0201f26 <strchr+0x14>
    while (*s != '\0') {
ffffffffc0201f1c:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0201f20:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0201f22:	fbfd                	bnez	a5,ffffffffc0201f18 <strchr+0x6>
    }
    return NULL;
ffffffffc0201f24:	4501                	li	a0,0
}
ffffffffc0201f26:	8082                	ret

ffffffffc0201f28 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201f28:	ca01                	beqz	a2,ffffffffc0201f38 <memset+0x10>
ffffffffc0201f2a:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201f2c:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201f2e:	0785                	addi	a5,a5,1
ffffffffc0201f30:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201f34:	fec79de3          	bne	a5,a2,ffffffffc0201f2e <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201f38:	8082                	ret
