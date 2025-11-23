
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00009297          	auipc	t0,0x9
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0209000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00009297          	auipc	t0,0x9
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0209008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)
    
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02082b7          	lui	t0,0xc0208
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
ffffffffc020003c:	c0208137          	lui	sp,0xc0208

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	04a28293          	addi	t0,t0,74 # ffffffffc020004a <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <kern_init>:
void grade_backtrace(void);

int kern_init(void)
{
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc020004a:	00009517          	auipc	a0,0x9
ffffffffc020004e:	fe650513          	addi	a0,a0,-26 # ffffffffc0209030 <buf>
ffffffffc0200052:	0000d617          	auipc	a2,0xd
ffffffffc0200056:	49a60613          	addi	a2,a2,1178 # ffffffffc020d4ec <end>
{
ffffffffc020005a:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc020005c:	8e09                	sub	a2,a2,a0
ffffffffc020005e:	4581                	li	a1,0
{
ffffffffc0200060:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc0200062:	627030ef          	jal	ra,ffffffffc0203e88 <memset>
    dtb_init();
ffffffffc0200066:	514000ef          	jal	ra,ffffffffc020057a <dtb_init>
    cons_init(); // init the console
ffffffffc020006a:	49e000ef          	jal	ra,ffffffffc0200508 <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc020006e:	00004597          	auipc	a1,0x4
ffffffffc0200072:	e6a58593          	addi	a1,a1,-406 # ffffffffc0203ed8 <etext+0x2>
ffffffffc0200076:	00004517          	auipc	a0,0x4
ffffffffc020007a:	e8250513          	addi	a0,a0,-382 # ffffffffc0203ef8 <etext+0x22>
ffffffffc020007e:	116000ef          	jal	ra,ffffffffc0200194 <cprintf>

    print_kerninfo();
ffffffffc0200082:	15a000ef          	jal	ra,ffffffffc02001dc <print_kerninfo>

    // grade_backtrace();

    pmm_init(); // init physical memory management
ffffffffc0200086:	0d0020ef          	jal	ra,ffffffffc0202156 <pmm_init>

    pic_init(); // init interrupt controller
ffffffffc020008a:	0ad000ef          	jal	ra,ffffffffc0200936 <pic_init>
    idt_init(); // init interrupt descriptor table
ffffffffc020008e:	0ab000ef          	jal	ra,ffffffffc0200938 <idt_init>

    vmm_init();  // init virtual memory management 完成第一个页表的创建
ffffffffc0200092:	639020ef          	jal	ra,ffffffffc0202eca <vmm_init>
                 // 具体实现见 /kern/mm/vmm.c
    proc_init(); // init process table 创建进程
ffffffffc0200096:	58a030ef          	jal	ra,ffffffffc0203620 <proc_init>
                 // 具体实现见 /kern/process/proc.c

    clock_init();  // init clock interrupt
ffffffffc020009a:	41c000ef          	jal	ra,ffffffffc02004b6 <clock_init>
    intr_enable(); // enable irq interrupt
ffffffffc020009e:	08d000ef          	jal	ra,ffffffffc020092a <intr_enable>

    cpu_idle(); // run idle process
ffffffffc02000a2:	7f4030ef          	jal	ra,ffffffffc0203896 <cpu_idle>

ffffffffc02000a6 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc02000a6:	715d                	addi	sp,sp,-80
ffffffffc02000a8:	e486                	sd	ra,72(sp)
ffffffffc02000aa:	e0a6                	sd	s1,64(sp)
ffffffffc02000ac:	fc4a                	sd	s2,56(sp)
ffffffffc02000ae:	f84e                	sd	s3,48(sp)
ffffffffc02000b0:	f452                	sd	s4,40(sp)
ffffffffc02000b2:	f056                	sd	s5,32(sp)
ffffffffc02000b4:	ec5a                	sd	s6,24(sp)
ffffffffc02000b6:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc02000b8:	c901                	beqz	a0,ffffffffc02000c8 <readline+0x22>
ffffffffc02000ba:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc02000bc:	00004517          	auipc	a0,0x4
ffffffffc02000c0:	e4450513          	addi	a0,a0,-444 # ffffffffc0203f00 <etext+0x2a>
ffffffffc02000c4:	0d0000ef          	jal	ra,ffffffffc0200194 <cprintf>
readline(const char *prompt) {
ffffffffc02000c8:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000ca:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc02000cc:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc02000ce:	4aa9                	li	s5,10
ffffffffc02000d0:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc02000d2:	00009b97          	auipc	s7,0x9
ffffffffc02000d6:	f5eb8b93          	addi	s7,s7,-162 # ffffffffc0209030 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000da:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc02000de:	0ee000ef          	jal	ra,ffffffffc02001cc <getchar>
        if (c < 0) {
ffffffffc02000e2:	00054a63          	bltz	a0,ffffffffc02000f6 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000e6:	00a95a63          	bge	s2,a0,ffffffffc02000fa <readline+0x54>
ffffffffc02000ea:	029a5263          	bge	s4,s1,ffffffffc020010e <readline+0x68>
        c = getchar();
ffffffffc02000ee:	0de000ef          	jal	ra,ffffffffc02001cc <getchar>
        if (c < 0) {
ffffffffc02000f2:	fe055ae3          	bgez	a0,ffffffffc02000e6 <readline+0x40>
            return NULL;
ffffffffc02000f6:	4501                	li	a0,0
ffffffffc02000f8:	a091                	j	ffffffffc020013c <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc02000fa:	03351463          	bne	a0,s3,ffffffffc0200122 <readline+0x7c>
ffffffffc02000fe:	e8a9                	bnez	s1,ffffffffc0200150 <readline+0xaa>
        c = getchar();
ffffffffc0200100:	0cc000ef          	jal	ra,ffffffffc02001cc <getchar>
        if (c < 0) {
ffffffffc0200104:	fe0549e3          	bltz	a0,ffffffffc02000f6 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0200108:	fea959e3          	bge	s2,a0,ffffffffc02000fa <readline+0x54>
ffffffffc020010c:	4481                	li	s1,0
            cputchar(c);
ffffffffc020010e:	e42a                	sd	a0,8(sp)
ffffffffc0200110:	0ba000ef          	jal	ra,ffffffffc02001ca <cputchar>
            buf[i ++] = c;
ffffffffc0200114:	6522                	ld	a0,8(sp)
ffffffffc0200116:	009b87b3          	add	a5,s7,s1
ffffffffc020011a:	2485                	addiw	s1,s1,1
ffffffffc020011c:	00a78023          	sb	a0,0(a5)
ffffffffc0200120:	bf7d                	j	ffffffffc02000de <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc0200122:	01550463          	beq	a0,s5,ffffffffc020012a <readline+0x84>
ffffffffc0200126:	fb651ce3          	bne	a0,s6,ffffffffc02000de <readline+0x38>
            cputchar(c);
ffffffffc020012a:	0a0000ef          	jal	ra,ffffffffc02001ca <cputchar>
            buf[i] = '\0';
ffffffffc020012e:	00009517          	auipc	a0,0x9
ffffffffc0200132:	f0250513          	addi	a0,a0,-254 # ffffffffc0209030 <buf>
ffffffffc0200136:	94aa                	add	s1,s1,a0
ffffffffc0200138:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc020013c:	60a6                	ld	ra,72(sp)
ffffffffc020013e:	6486                	ld	s1,64(sp)
ffffffffc0200140:	7962                	ld	s2,56(sp)
ffffffffc0200142:	79c2                	ld	s3,48(sp)
ffffffffc0200144:	7a22                	ld	s4,40(sp)
ffffffffc0200146:	7a82                	ld	s5,32(sp)
ffffffffc0200148:	6b62                	ld	s6,24(sp)
ffffffffc020014a:	6bc2                	ld	s7,16(sp)
ffffffffc020014c:	6161                	addi	sp,sp,80
ffffffffc020014e:	8082                	ret
            cputchar(c);
ffffffffc0200150:	4521                	li	a0,8
ffffffffc0200152:	078000ef          	jal	ra,ffffffffc02001ca <cputchar>
            i --;
ffffffffc0200156:	34fd                	addiw	s1,s1,-1
ffffffffc0200158:	b759                	j	ffffffffc02000de <readline+0x38>

ffffffffc020015a <cputch>:
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt)
{
ffffffffc020015a:	1141                	addi	sp,sp,-16
ffffffffc020015c:	e022                	sd	s0,0(sp)
ffffffffc020015e:	e406                	sd	ra,8(sp)
ffffffffc0200160:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc0200162:	3a8000ef          	jal	ra,ffffffffc020050a <cons_putc>
    (*cnt)++;
ffffffffc0200166:	401c                	lw	a5,0(s0)
}
ffffffffc0200168:	60a2                	ld	ra,8(sp)
    (*cnt)++;
ffffffffc020016a:	2785                	addiw	a5,a5,1
ffffffffc020016c:	c01c                	sw	a5,0(s0)
}
ffffffffc020016e:	6402                	ld	s0,0(sp)
ffffffffc0200170:	0141                	addi	sp,sp,16
ffffffffc0200172:	8082                	ret

ffffffffc0200174 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int vcprintf(const char *fmt, va_list ap)
{
ffffffffc0200174:	1101                	addi	sp,sp,-32
ffffffffc0200176:	862a                	mv	a2,a0
ffffffffc0200178:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc020017a:	00000517          	auipc	a0,0x0
ffffffffc020017e:	fe050513          	addi	a0,a0,-32 # ffffffffc020015a <cputch>
ffffffffc0200182:	006c                	addi	a1,sp,12
{
ffffffffc0200184:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc0200186:	c602                	sw	zero,12(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc0200188:	0dd030ef          	jal	ra,ffffffffc0203a64 <vprintfmt>
    return cnt;
}
ffffffffc020018c:	60e2                	ld	ra,24(sp)
ffffffffc020018e:	4532                	lw	a0,12(sp)
ffffffffc0200190:	6105                	addi	sp,sp,32
ffffffffc0200192:	8082                	ret

ffffffffc0200194 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int cprintf(const char *fmt, ...)
{
ffffffffc0200194:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc0200196:	02810313          	addi	t1,sp,40 # ffffffffc0208028 <boot_page_table_sv39+0x28>
{
ffffffffc020019a:	8e2a                	mv	t3,a0
ffffffffc020019c:	f42e                	sd	a1,40(sp)
ffffffffc020019e:	f832                	sd	a2,48(sp)
ffffffffc02001a0:	fc36                	sd	a3,56(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001a2:	00000517          	auipc	a0,0x0
ffffffffc02001a6:	fb850513          	addi	a0,a0,-72 # ffffffffc020015a <cputch>
ffffffffc02001aa:	004c                	addi	a1,sp,4
ffffffffc02001ac:	869a                	mv	a3,t1
ffffffffc02001ae:	8672                	mv	a2,t3
{
ffffffffc02001b0:	ec06                	sd	ra,24(sp)
ffffffffc02001b2:	e0ba                	sd	a4,64(sp)
ffffffffc02001b4:	e4be                	sd	a5,72(sp)
ffffffffc02001b6:	e8c2                	sd	a6,80(sp)
ffffffffc02001b8:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02001ba:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02001bc:	c202                	sw	zero,4(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001be:	0a7030ef          	jal	ra,ffffffffc0203a64 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02001c2:	60e2                	ld	ra,24(sp)
ffffffffc02001c4:	4512                	lw	a0,4(sp)
ffffffffc02001c6:	6125                	addi	sp,sp,96
ffffffffc02001c8:	8082                	ret

ffffffffc02001ca <cputchar>:

/* cputchar - writes a single character to stdout */
void cputchar(int c)
{
    cons_putc(c);
ffffffffc02001ca:	a681                	j	ffffffffc020050a <cons_putc>

ffffffffc02001cc <getchar>:
}

/* getchar - reads a single non-zero character from stdin */
int getchar(void)
{
ffffffffc02001cc:	1141                	addi	sp,sp,-16
ffffffffc02001ce:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc02001d0:	36e000ef          	jal	ra,ffffffffc020053e <cons_getc>
ffffffffc02001d4:	dd75                	beqz	a0,ffffffffc02001d0 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc02001d6:	60a2                	ld	ra,8(sp)
ffffffffc02001d8:	0141                	addi	sp,sp,16
ffffffffc02001da:	8082                	ret

ffffffffc02001dc <print_kerninfo>:
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void)
{
ffffffffc02001dc:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc02001de:	00004517          	auipc	a0,0x4
ffffffffc02001e2:	d2a50513          	addi	a0,a0,-726 # ffffffffc0203f08 <etext+0x32>
{
ffffffffc02001e6:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc02001e8:	fadff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc02001ec:	00000597          	auipc	a1,0x0
ffffffffc02001f0:	e5e58593          	addi	a1,a1,-418 # ffffffffc020004a <kern_init>
ffffffffc02001f4:	00004517          	auipc	a0,0x4
ffffffffc02001f8:	d3450513          	addi	a0,a0,-716 # ffffffffc0203f28 <etext+0x52>
ffffffffc02001fc:	f99ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc0200200:	00004597          	auipc	a1,0x4
ffffffffc0200204:	cd658593          	addi	a1,a1,-810 # ffffffffc0203ed6 <etext>
ffffffffc0200208:	00004517          	auipc	a0,0x4
ffffffffc020020c:	d4050513          	addi	a0,a0,-704 # ffffffffc0203f48 <etext+0x72>
ffffffffc0200210:	f85ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc0200214:	00009597          	auipc	a1,0x9
ffffffffc0200218:	e1c58593          	addi	a1,a1,-484 # ffffffffc0209030 <buf>
ffffffffc020021c:	00004517          	auipc	a0,0x4
ffffffffc0200220:	d4c50513          	addi	a0,a0,-692 # ffffffffc0203f68 <etext+0x92>
ffffffffc0200224:	f71ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200228:	0000d597          	auipc	a1,0xd
ffffffffc020022c:	2c458593          	addi	a1,a1,708 # ffffffffc020d4ec <end>
ffffffffc0200230:	00004517          	auipc	a0,0x4
ffffffffc0200234:	d5850513          	addi	a0,a0,-680 # ffffffffc0203f88 <etext+0xb2>
ffffffffc0200238:	f5dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc020023c:	0000d597          	auipc	a1,0xd
ffffffffc0200240:	6af58593          	addi	a1,a1,1711 # ffffffffc020d8eb <end+0x3ff>
ffffffffc0200244:	00000797          	auipc	a5,0x0
ffffffffc0200248:	e0678793          	addi	a5,a5,-506 # ffffffffc020004a <kern_init>
ffffffffc020024c:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200250:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc0200254:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200256:	3ff5f593          	andi	a1,a1,1023
ffffffffc020025a:	95be                	add	a1,a1,a5
ffffffffc020025c:	85a9                	srai	a1,a1,0xa
ffffffffc020025e:	00004517          	auipc	a0,0x4
ffffffffc0200262:	d4a50513          	addi	a0,a0,-694 # ffffffffc0203fa8 <etext+0xd2>
}
ffffffffc0200266:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200268:	b735                	j	ffffffffc0200194 <cprintf>

ffffffffc020026a <print_stackframe>:
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void)
{
ffffffffc020026a:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc020026c:	00004617          	auipc	a2,0x4
ffffffffc0200270:	d6c60613          	addi	a2,a2,-660 # ffffffffc0203fd8 <etext+0x102>
ffffffffc0200274:	04900593          	li	a1,73
ffffffffc0200278:	00004517          	auipc	a0,0x4
ffffffffc020027c:	d7850513          	addi	a0,a0,-648 # ffffffffc0203ff0 <etext+0x11a>
{
ffffffffc0200280:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc0200282:	1d8000ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0200286 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200286:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200288:	00004617          	auipc	a2,0x4
ffffffffc020028c:	d8060613          	addi	a2,a2,-640 # ffffffffc0204008 <etext+0x132>
ffffffffc0200290:	00004597          	auipc	a1,0x4
ffffffffc0200294:	d9858593          	addi	a1,a1,-616 # ffffffffc0204028 <etext+0x152>
ffffffffc0200298:	00004517          	auipc	a0,0x4
ffffffffc020029c:	d9850513          	addi	a0,a0,-616 # ffffffffc0204030 <etext+0x15a>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002a0:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002a2:	ef3ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc02002a6:	00004617          	auipc	a2,0x4
ffffffffc02002aa:	d9a60613          	addi	a2,a2,-614 # ffffffffc0204040 <etext+0x16a>
ffffffffc02002ae:	00004597          	auipc	a1,0x4
ffffffffc02002b2:	dba58593          	addi	a1,a1,-582 # ffffffffc0204068 <etext+0x192>
ffffffffc02002b6:	00004517          	auipc	a0,0x4
ffffffffc02002ba:	d7a50513          	addi	a0,a0,-646 # ffffffffc0204030 <etext+0x15a>
ffffffffc02002be:	ed7ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc02002c2:	00004617          	auipc	a2,0x4
ffffffffc02002c6:	db660613          	addi	a2,a2,-586 # ffffffffc0204078 <etext+0x1a2>
ffffffffc02002ca:	00004597          	auipc	a1,0x4
ffffffffc02002ce:	dce58593          	addi	a1,a1,-562 # ffffffffc0204098 <etext+0x1c2>
ffffffffc02002d2:	00004517          	auipc	a0,0x4
ffffffffc02002d6:	d5e50513          	addi	a0,a0,-674 # ffffffffc0204030 <etext+0x15a>
ffffffffc02002da:	ebbff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    }
    return 0;
}
ffffffffc02002de:	60a2                	ld	ra,8(sp)
ffffffffc02002e0:	4501                	li	a0,0
ffffffffc02002e2:	0141                	addi	sp,sp,16
ffffffffc02002e4:	8082                	ret

ffffffffc02002e6 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002e6:	1141                	addi	sp,sp,-16
ffffffffc02002e8:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc02002ea:	ef3ff0ef          	jal	ra,ffffffffc02001dc <print_kerninfo>
    return 0;
}
ffffffffc02002ee:	60a2                	ld	ra,8(sp)
ffffffffc02002f0:	4501                	li	a0,0
ffffffffc02002f2:	0141                	addi	sp,sp,16
ffffffffc02002f4:	8082                	ret

ffffffffc02002f6 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002f6:	1141                	addi	sp,sp,-16
ffffffffc02002f8:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc02002fa:	f71ff0ef          	jal	ra,ffffffffc020026a <print_stackframe>
    return 0;
}
ffffffffc02002fe:	60a2                	ld	ra,8(sp)
ffffffffc0200300:	4501                	li	a0,0
ffffffffc0200302:	0141                	addi	sp,sp,16
ffffffffc0200304:	8082                	ret

ffffffffc0200306 <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc0200306:	7115                	addi	sp,sp,-224
ffffffffc0200308:	ed5e                	sd	s7,152(sp)
ffffffffc020030a:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020030c:	00004517          	auipc	a0,0x4
ffffffffc0200310:	d9c50513          	addi	a0,a0,-612 # ffffffffc02040a8 <etext+0x1d2>
kmonitor(struct trapframe *tf) {
ffffffffc0200314:	ed86                	sd	ra,216(sp)
ffffffffc0200316:	e9a2                	sd	s0,208(sp)
ffffffffc0200318:	e5a6                	sd	s1,200(sp)
ffffffffc020031a:	e1ca                	sd	s2,192(sp)
ffffffffc020031c:	fd4e                	sd	s3,184(sp)
ffffffffc020031e:	f952                	sd	s4,176(sp)
ffffffffc0200320:	f556                	sd	s5,168(sp)
ffffffffc0200322:	f15a                	sd	s6,160(sp)
ffffffffc0200324:	e962                	sd	s8,144(sp)
ffffffffc0200326:	e566                	sd	s9,136(sp)
ffffffffc0200328:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020032a:	e6bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc020032e:	00004517          	auipc	a0,0x4
ffffffffc0200332:	da250513          	addi	a0,a0,-606 # ffffffffc02040d0 <etext+0x1fa>
ffffffffc0200336:	e5fff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    if (tf != NULL) {
ffffffffc020033a:	000b8563          	beqz	s7,ffffffffc0200344 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc020033e:	855e                	mv	a0,s7
ffffffffc0200340:	7e0000ef          	jal	ra,ffffffffc0200b20 <print_trapframe>
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc0200344:	4501                	li	a0,0
ffffffffc0200346:	4581                	li	a1,0
ffffffffc0200348:	4601                	li	a2,0
ffffffffc020034a:	48a1                	li	a7,8
ffffffffc020034c:	00000073          	ecall
ffffffffc0200350:	00004c17          	auipc	s8,0x4
ffffffffc0200354:	df0c0c13          	addi	s8,s8,-528 # ffffffffc0204140 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200358:	00004917          	auipc	s2,0x4
ffffffffc020035c:	da090913          	addi	s2,s2,-608 # ffffffffc02040f8 <etext+0x222>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200360:	00004497          	auipc	s1,0x4
ffffffffc0200364:	da048493          	addi	s1,s1,-608 # ffffffffc0204100 <etext+0x22a>
        if (argc == MAXARGS - 1) {
ffffffffc0200368:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020036a:	00004b17          	auipc	s6,0x4
ffffffffc020036e:	d9eb0b13          	addi	s6,s6,-610 # ffffffffc0204108 <etext+0x232>
        argv[argc ++] = buf;
ffffffffc0200372:	00004a17          	auipc	s4,0x4
ffffffffc0200376:	cb6a0a13          	addi	s4,s4,-842 # ffffffffc0204028 <etext+0x152>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020037a:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc020037c:	854a                	mv	a0,s2
ffffffffc020037e:	d29ff0ef          	jal	ra,ffffffffc02000a6 <readline>
ffffffffc0200382:	842a                	mv	s0,a0
ffffffffc0200384:	dd65                	beqz	a0,ffffffffc020037c <kmonitor+0x76>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200386:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc020038a:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020038c:	e1bd                	bnez	a1,ffffffffc02003f2 <kmonitor+0xec>
    if (argc == 0) {
ffffffffc020038e:	fe0c87e3          	beqz	s9,ffffffffc020037c <kmonitor+0x76>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200392:	6582                	ld	a1,0(sp)
ffffffffc0200394:	00004d17          	auipc	s10,0x4
ffffffffc0200398:	dacd0d13          	addi	s10,s10,-596 # ffffffffc0204140 <commands>
        argv[argc ++] = buf;
ffffffffc020039c:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020039e:	4401                	li	s0,0
ffffffffc02003a0:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003a2:	28d030ef          	jal	ra,ffffffffc0203e2e <strcmp>
ffffffffc02003a6:	c919                	beqz	a0,ffffffffc02003bc <kmonitor+0xb6>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003a8:	2405                	addiw	s0,s0,1
ffffffffc02003aa:	0b540063          	beq	s0,s5,ffffffffc020044a <kmonitor+0x144>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003ae:	000d3503          	ld	a0,0(s10)
ffffffffc02003b2:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003b4:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003b6:	279030ef          	jal	ra,ffffffffc0203e2e <strcmp>
ffffffffc02003ba:	f57d                	bnez	a0,ffffffffc02003a8 <kmonitor+0xa2>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc02003bc:	00141793          	slli	a5,s0,0x1
ffffffffc02003c0:	97a2                	add	a5,a5,s0
ffffffffc02003c2:	078e                	slli	a5,a5,0x3
ffffffffc02003c4:	97e2                	add	a5,a5,s8
ffffffffc02003c6:	6b9c                	ld	a5,16(a5)
ffffffffc02003c8:	865e                	mv	a2,s7
ffffffffc02003ca:	002c                	addi	a1,sp,8
ffffffffc02003cc:	fffc851b          	addiw	a0,s9,-1
ffffffffc02003d0:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc02003d2:	fa0555e3          	bgez	a0,ffffffffc020037c <kmonitor+0x76>
}
ffffffffc02003d6:	60ee                	ld	ra,216(sp)
ffffffffc02003d8:	644e                	ld	s0,208(sp)
ffffffffc02003da:	64ae                	ld	s1,200(sp)
ffffffffc02003dc:	690e                	ld	s2,192(sp)
ffffffffc02003de:	79ea                	ld	s3,184(sp)
ffffffffc02003e0:	7a4a                	ld	s4,176(sp)
ffffffffc02003e2:	7aaa                	ld	s5,168(sp)
ffffffffc02003e4:	7b0a                	ld	s6,160(sp)
ffffffffc02003e6:	6bea                	ld	s7,152(sp)
ffffffffc02003e8:	6c4a                	ld	s8,144(sp)
ffffffffc02003ea:	6caa                	ld	s9,136(sp)
ffffffffc02003ec:	6d0a                	ld	s10,128(sp)
ffffffffc02003ee:	612d                	addi	sp,sp,224
ffffffffc02003f0:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003f2:	8526                	mv	a0,s1
ffffffffc02003f4:	27f030ef          	jal	ra,ffffffffc0203e72 <strchr>
ffffffffc02003f8:	c901                	beqz	a0,ffffffffc0200408 <kmonitor+0x102>
ffffffffc02003fa:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc02003fe:	00040023          	sb	zero,0(s0)
ffffffffc0200402:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200404:	d5c9                	beqz	a1,ffffffffc020038e <kmonitor+0x88>
ffffffffc0200406:	b7f5                	j	ffffffffc02003f2 <kmonitor+0xec>
        if (*buf == '\0') {
ffffffffc0200408:	00044783          	lbu	a5,0(s0)
ffffffffc020040c:	d3c9                	beqz	a5,ffffffffc020038e <kmonitor+0x88>
        if (argc == MAXARGS - 1) {
ffffffffc020040e:	033c8963          	beq	s9,s3,ffffffffc0200440 <kmonitor+0x13a>
        argv[argc ++] = buf;
ffffffffc0200412:	003c9793          	slli	a5,s9,0x3
ffffffffc0200416:	0118                	addi	a4,sp,128
ffffffffc0200418:	97ba                	add	a5,a5,a4
ffffffffc020041a:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020041e:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc0200422:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200424:	e591                	bnez	a1,ffffffffc0200430 <kmonitor+0x12a>
ffffffffc0200426:	b7b5                	j	ffffffffc0200392 <kmonitor+0x8c>
ffffffffc0200428:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc020042c:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020042e:	d1a5                	beqz	a1,ffffffffc020038e <kmonitor+0x88>
ffffffffc0200430:	8526                	mv	a0,s1
ffffffffc0200432:	241030ef          	jal	ra,ffffffffc0203e72 <strchr>
ffffffffc0200436:	d96d                	beqz	a0,ffffffffc0200428 <kmonitor+0x122>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200438:	00044583          	lbu	a1,0(s0)
ffffffffc020043c:	d9a9                	beqz	a1,ffffffffc020038e <kmonitor+0x88>
ffffffffc020043e:	bf55                	j	ffffffffc02003f2 <kmonitor+0xec>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200440:	45c1                	li	a1,16
ffffffffc0200442:	855a                	mv	a0,s6
ffffffffc0200444:	d51ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0200448:	b7e9                	j	ffffffffc0200412 <kmonitor+0x10c>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc020044a:	6582                	ld	a1,0(sp)
ffffffffc020044c:	00004517          	auipc	a0,0x4
ffffffffc0200450:	cdc50513          	addi	a0,a0,-804 # ffffffffc0204128 <etext+0x252>
ffffffffc0200454:	d41ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return 0;
ffffffffc0200458:	b715                	j	ffffffffc020037c <kmonitor+0x76>

ffffffffc020045a <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc020045a:	0000d317          	auipc	t1,0xd
ffffffffc020045e:	00e30313          	addi	t1,t1,14 # ffffffffc020d468 <is_panic>
ffffffffc0200462:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc0200466:	715d                	addi	sp,sp,-80
ffffffffc0200468:	ec06                	sd	ra,24(sp)
ffffffffc020046a:	e822                	sd	s0,16(sp)
ffffffffc020046c:	f436                	sd	a3,40(sp)
ffffffffc020046e:	f83a                	sd	a4,48(sp)
ffffffffc0200470:	fc3e                	sd	a5,56(sp)
ffffffffc0200472:	e0c2                	sd	a6,64(sp)
ffffffffc0200474:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc0200476:	020e1a63          	bnez	t3,ffffffffc02004aa <__panic+0x50>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc020047a:	4785                	li	a5,1
ffffffffc020047c:	00f32023          	sw	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc0200480:	8432                	mv	s0,a2
ffffffffc0200482:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200484:	862e                	mv	a2,a1
ffffffffc0200486:	85aa                	mv	a1,a0
ffffffffc0200488:	00004517          	auipc	a0,0x4
ffffffffc020048c:	d0050513          	addi	a0,a0,-768 # ffffffffc0204188 <commands+0x48>
    va_start(ap, fmt);
ffffffffc0200490:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200492:	d03ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200496:	65a2                	ld	a1,8(sp)
ffffffffc0200498:	8522                	mv	a0,s0
ffffffffc020049a:	cdbff0ef          	jal	ra,ffffffffc0200174 <vcprintf>
    cprintf("\n");
ffffffffc020049e:	00005517          	auipc	a0,0x5
ffffffffc02004a2:	d9a50513          	addi	a0,a0,-614 # ffffffffc0205238 <default_pmm_manager+0x530>
ffffffffc02004a6:	cefff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc02004aa:	486000ef          	jal	ra,ffffffffc0200930 <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc02004ae:	4501                	li	a0,0
ffffffffc02004b0:	e57ff0ef          	jal	ra,ffffffffc0200306 <kmonitor>
    while (1) {
ffffffffc02004b4:	bfed                	j	ffffffffc02004ae <__panic+0x54>

ffffffffc02004b6 <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc02004b6:	67e1                	lui	a5,0x18
ffffffffc02004b8:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc02004bc:	0000d717          	auipc	a4,0xd
ffffffffc02004c0:	faf73e23          	sd	a5,-68(a4) # ffffffffc020d478 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc02004c4:	c0102573          	rdtime	a0
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc02004c8:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc02004ca:	953e                	add	a0,a0,a5
ffffffffc02004cc:	4601                	li	a2,0
ffffffffc02004ce:	4881                	li	a7,0
ffffffffc02004d0:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc02004d4:	02000793          	li	a5,32
ffffffffc02004d8:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc02004dc:	00004517          	auipc	a0,0x4
ffffffffc02004e0:	ccc50513          	addi	a0,a0,-820 # ffffffffc02041a8 <commands+0x68>
    ticks = 0;
ffffffffc02004e4:	0000d797          	auipc	a5,0xd
ffffffffc02004e8:	f807b623          	sd	zero,-116(a5) # ffffffffc020d470 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc02004ec:	b165                	j	ffffffffc0200194 <cprintf>

ffffffffc02004ee <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc02004ee:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc02004f2:	0000d797          	auipc	a5,0xd
ffffffffc02004f6:	f867b783          	ld	a5,-122(a5) # ffffffffc020d478 <timebase>
ffffffffc02004fa:	953e                	add	a0,a0,a5
ffffffffc02004fc:	4581                	li	a1,0
ffffffffc02004fe:	4601                	li	a2,0
ffffffffc0200500:	4881                	li	a7,0
ffffffffc0200502:	00000073          	ecall
ffffffffc0200506:	8082                	ret

ffffffffc0200508 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200508:	8082                	ret

ffffffffc020050a <cons_putc>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020050a:	100027f3          	csrr	a5,sstatus
ffffffffc020050e:	8b89                	andi	a5,a5,2
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc0200510:	0ff57513          	zext.b	a0,a0
ffffffffc0200514:	e799                	bnez	a5,ffffffffc0200522 <cons_putc+0x18>
ffffffffc0200516:	4581                	li	a1,0
ffffffffc0200518:	4601                	li	a2,0
ffffffffc020051a:	4885                	li	a7,1
ffffffffc020051c:	00000073          	ecall
    }
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
ffffffffc0200520:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc0200522:	1101                	addi	sp,sp,-32
ffffffffc0200524:	ec06                	sd	ra,24(sp)
ffffffffc0200526:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0200528:	408000ef          	jal	ra,ffffffffc0200930 <intr_disable>
ffffffffc020052c:	6522                	ld	a0,8(sp)
ffffffffc020052e:	4581                	li	a1,0
ffffffffc0200530:	4601                	li	a2,0
ffffffffc0200532:	4885                	li	a7,1
ffffffffc0200534:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc0200538:	60e2                	ld	ra,24(sp)
ffffffffc020053a:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc020053c:	a6fd                	j	ffffffffc020092a <intr_enable>

ffffffffc020053e <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020053e:	100027f3          	csrr	a5,sstatus
ffffffffc0200542:	8b89                	andi	a5,a5,2
ffffffffc0200544:	eb89                	bnez	a5,ffffffffc0200556 <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc0200546:	4501                	li	a0,0
ffffffffc0200548:	4581                	li	a1,0
ffffffffc020054a:	4601                	li	a2,0
ffffffffc020054c:	4889                	li	a7,2
ffffffffc020054e:	00000073          	ecall
ffffffffc0200552:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc0200554:	8082                	ret
int cons_getc(void) {
ffffffffc0200556:	1101                	addi	sp,sp,-32
ffffffffc0200558:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc020055a:	3d6000ef          	jal	ra,ffffffffc0200930 <intr_disable>
ffffffffc020055e:	4501                	li	a0,0
ffffffffc0200560:	4581                	li	a1,0
ffffffffc0200562:	4601                	li	a2,0
ffffffffc0200564:	4889                	li	a7,2
ffffffffc0200566:	00000073          	ecall
ffffffffc020056a:	2501                	sext.w	a0,a0
ffffffffc020056c:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc020056e:	3bc000ef          	jal	ra,ffffffffc020092a <intr_enable>
}
ffffffffc0200572:	60e2                	ld	ra,24(sp)
ffffffffc0200574:	6522                	ld	a0,8(sp)
ffffffffc0200576:	6105                	addi	sp,sp,32
ffffffffc0200578:	8082                	ret

ffffffffc020057a <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc020057a:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc020057c:	00004517          	auipc	a0,0x4
ffffffffc0200580:	c4c50513          	addi	a0,a0,-948 # ffffffffc02041c8 <commands+0x88>
void dtb_init(void) {
ffffffffc0200584:	fc86                	sd	ra,120(sp)
ffffffffc0200586:	f8a2                	sd	s0,112(sp)
ffffffffc0200588:	e8d2                	sd	s4,80(sp)
ffffffffc020058a:	f4a6                	sd	s1,104(sp)
ffffffffc020058c:	f0ca                	sd	s2,96(sp)
ffffffffc020058e:	ecce                	sd	s3,88(sp)
ffffffffc0200590:	e4d6                	sd	s5,72(sp)
ffffffffc0200592:	e0da                	sd	s6,64(sp)
ffffffffc0200594:	fc5e                	sd	s7,56(sp)
ffffffffc0200596:	f862                	sd	s8,48(sp)
ffffffffc0200598:	f466                	sd	s9,40(sp)
ffffffffc020059a:	f06a                	sd	s10,32(sp)
ffffffffc020059c:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc020059e:	bf7ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc02005a2:	00009597          	auipc	a1,0x9
ffffffffc02005a6:	a5e5b583          	ld	a1,-1442(a1) # ffffffffc0209000 <boot_hartid>
ffffffffc02005aa:	00004517          	auipc	a0,0x4
ffffffffc02005ae:	c2e50513          	addi	a0,a0,-978 # ffffffffc02041d8 <commands+0x98>
ffffffffc02005b2:	be3ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc02005b6:	00009417          	auipc	s0,0x9
ffffffffc02005ba:	a5240413          	addi	s0,s0,-1454 # ffffffffc0209008 <boot_dtb>
ffffffffc02005be:	600c                	ld	a1,0(s0)
ffffffffc02005c0:	00004517          	auipc	a0,0x4
ffffffffc02005c4:	c2850513          	addi	a0,a0,-984 # ffffffffc02041e8 <commands+0xa8>
ffffffffc02005c8:	bcdff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc02005cc:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc02005d0:	00004517          	auipc	a0,0x4
ffffffffc02005d4:	c3050513          	addi	a0,a0,-976 # ffffffffc0204200 <commands+0xc0>
    if (boot_dtb == 0) {
ffffffffc02005d8:	120a0463          	beqz	s4,ffffffffc0200700 <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc02005dc:	57f5                	li	a5,-3
ffffffffc02005de:	07fa                	slli	a5,a5,0x1e
ffffffffc02005e0:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc02005e4:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005e6:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005ea:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005ec:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02005f0:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005f4:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005f8:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005fc:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200600:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200602:	8ec9                	or	a3,a3,a0
ffffffffc0200604:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200608:	1b7d                	addi	s6,s6,-1
ffffffffc020060a:	0167f7b3          	and	a5,a5,s6
ffffffffc020060e:	8dd5                	or	a1,a1,a3
ffffffffc0200610:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc0200612:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200616:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc0200618:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed2a01>
ffffffffc020061c:	10f59163          	bne	a1,a5,ffffffffc020071e <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc0200620:	471c                	lw	a5,8(a4)
ffffffffc0200622:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc0200624:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200626:	0087d59b          	srliw	a1,a5,0x8
ffffffffc020062a:	0086d51b          	srliw	a0,a3,0x8
ffffffffc020062e:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200632:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200636:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020063a:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020063e:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200642:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200646:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020064a:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020064e:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200650:	01146433          	or	s0,s0,a7
ffffffffc0200654:	0086969b          	slliw	a3,a3,0x8
ffffffffc0200658:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020065c:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020065e:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200662:	8c49                	or	s0,s0,a0
ffffffffc0200664:	0166f6b3          	and	a3,a3,s6
ffffffffc0200668:	00ca6a33          	or	s4,s4,a2
ffffffffc020066c:	0167f7b3          	and	a5,a5,s6
ffffffffc0200670:	8c55                	or	s0,s0,a3
ffffffffc0200672:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200676:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200678:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020067a:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020067c:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200680:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200682:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200684:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc0200688:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020068a:	00004917          	auipc	s2,0x4
ffffffffc020068e:	bc690913          	addi	s2,s2,-1082 # ffffffffc0204250 <commands+0x110>
ffffffffc0200692:	49bd                	li	s3,15
        switch (token) {
ffffffffc0200694:	4d91                	li	s11,4
ffffffffc0200696:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200698:	00004497          	auipc	s1,0x4
ffffffffc020069c:	bb048493          	addi	s1,s1,-1104 # ffffffffc0204248 <commands+0x108>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc02006a0:	000a2703          	lw	a4,0(s4)
ffffffffc02006a4:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006a8:	0087569b          	srliw	a3,a4,0x8
ffffffffc02006ac:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006b0:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006b4:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006b8:	0107571b          	srliw	a4,a4,0x10
ffffffffc02006bc:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006be:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006c2:	0087171b          	slliw	a4,a4,0x8
ffffffffc02006c6:	8fd5                	or	a5,a5,a3
ffffffffc02006c8:	00eb7733          	and	a4,s6,a4
ffffffffc02006cc:	8fd9                	or	a5,a5,a4
ffffffffc02006ce:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc02006d0:	09778c63          	beq	a5,s7,ffffffffc0200768 <dtb_init+0x1ee>
ffffffffc02006d4:	00fbea63          	bltu	s7,a5,ffffffffc02006e8 <dtb_init+0x16e>
ffffffffc02006d8:	07a78663          	beq	a5,s10,ffffffffc0200744 <dtb_init+0x1ca>
ffffffffc02006dc:	4709                	li	a4,2
ffffffffc02006de:	00e79763          	bne	a5,a4,ffffffffc02006ec <dtb_init+0x172>
ffffffffc02006e2:	4c81                	li	s9,0
ffffffffc02006e4:	8a56                	mv	s4,s5
ffffffffc02006e6:	bf6d                	j	ffffffffc02006a0 <dtb_init+0x126>
ffffffffc02006e8:	ffb78ee3          	beq	a5,s11,ffffffffc02006e4 <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc02006ec:	00004517          	auipc	a0,0x4
ffffffffc02006f0:	bdc50513          	addi	a0,a0,-1060 # ffffffffc02042c8 <commands+0x188>
ffffffffc02006f4:	aa1ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc02006f8:	00004517          	auipc	a0,0x4
ffffffffc02006fc:	c0850513          	addi	a0,a0,-1016 # ffffffffc0204300 <commands+0x1c0>
}
ffffffffc0200700:	7446                	ld	s0,112(sp)
ffffffffc0200702:	70e6                	ld	ra,120(sp)
ffffffffc0200704:	74a6                	ld	s1,104(sp)
ffffffffc0200706:	7906                	ld	s2,96(sp)
ffffffffc0200708:	69e6                	ld	s3,88(sp)
ffffffffc020070a:	6a46                	ld	s4,80(sp)
ffffffffc020070c:	6aa6                	ld	s5,72(sp)
ffffffffc020070e:	6b06                	ld	s6,64(sp)
ffffffffc0200710:	7be2                	ld	s7,56(sp)
ffffffffc0200712:	7c42                	ld	s8,48(sp)
ffffffffc0200714:	7ca2                	ld	s9,40(sp)
ffffffffc0200716:	7d02                	ld	s10,32(sp)
ffffffffc0200718:	6de2                	ld	s11,24(sp)
ffffffffc020071a:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc020071c:	bca5                	j	ffffffffc0200194 <cprintf>
}
ffffffffc020071e:	7446                	ld	s0,112(sp)
ffffffffc0200720:	70e6                	ld	ra,120(sp)
ffffffffc0200722:	74a6                	ld	s1,104(sp)
ffffffffc0200724:	7906                	ld	s2,96(sp)
ffffffffc0200726:	69e6                	ld	s3,88(sp)
ffffffffc0200728:	6a46                	ld	s4,80(sp)
ffffffffc020072a:	6aa6                	ld	s5,72(sp)
ffffffffc020072c:	6b06                	ld	s6,64(sp)
ffffffffc020072e:	7be2                	ld	s7,56(sp)
ffffffffc0200730:	7c42                	ld	s8,48(sp)
ffffffffc0200732:	7ca2                	ld	s9,40(sp)
ffffffffc0200734:	7d02                	ld	s10,32(sp)
ffffffffc0200736:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200738:	00004517          	auipc	a0,0x4
ffffffffc020073c:	ae850513          	addi	a0,a0,-1304 # ffffffffc0204220 <commands+0xe0>
}
ffffffffc0200740:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200742:	bc89                	j	ffffffffc0200194 <cprintf>
                int name_len = strlen(name);
ffffffffc0200744:	8556                	mv	a0,s5
ffffffffc0200746:	6a0030ef          	jal	ra,ffffffffc0203de6 <strlen>
ffffffffc020074a:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020074c:	4619                	li	a2,6
ffffffffc020074e:	85a6                	mv	a1,s1
ffffffffc0200750:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc0200752:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200754:	6f8030ef          	jal	ra,ffffffffc0203e4c <strncmp>
ffffffffc0200758:	e111                	bnez	a0,ffffffffc020075c <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc020075a:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc020075c:	0a91                	addi	s5,s5,4
ffffffffc020075e:	9ad2                	add	s5,s5,s4
ffffffffc0200760:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200764:	8a56                	mv	s4,s5
ffffffffc0200766:	bf2d                	j	ffffffffc02006a0 <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200768:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc020076c:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200770:	0087d71b          	srliw	a4,a5,0x8
ffffffffc0200774:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200778:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020077c:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200780:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200784:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200788:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020078c:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200790:	00eaeab3          	or	s5,s5,a4
ffffffffc0200794:	00fb77b3          	and	a5,s6,a5
ffffffffc0200798:	00faeab3          	or	s5,s5,a5
ffffffffc020079c:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020079e:	000c9c63          	bnez	s9,ffffffffc02007b6 <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc02007a2:	1a82                	slli	s5,s5,0x20
ffffffffc02007a4:	00368793          	addi	a5,a3,3
ffffffffc02007a8:	020ada93          	srli	s5,s5,0x20
ffffffffc02007ac:	9abe                	add	s5,s5,a5
ffffffffc02007ae:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc02007b2:	8a56                	mv	s4,s5
ffffffffc02007b4:	b5f5                	j	ffffffffc02006a0 <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02007b6:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02007ba:	85ca                	mv	a1,s2
ffffffffc02007bc:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007be:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007c2:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007c6:	0187971b          	slliw	a4,a5,0x18
ffffffffc02007ca:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007ce:	0107d79b          	srliw	a5,a5,0x10
ffffffffc02007d2:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007d4:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007d8:	0087979b          	slliw	a5,a5,0x8
ffffffffc02007dc:	8d59                	or	a0,a0,a4
ffffffffc02007de:	00fb77b3          	and	a5,s6,a5
ffffffffc02007e2:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc02007e4:	1502                	slli	a0,a0,0x20
ffffffffc02007e6:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02007e8:	9522                	add	a0,a0,s0
ffffffffc02007ea:	644030ef          	jal	ra,ffffffffc0203e2e <strcmp>
ffffffffc02007ee:	66a2                	ld	a3,8(sp)
ffffffffc02007f0:	f94d                	bnez	a0,ffffffffc02007a2 <dtb_init+0x228>
ffffffffc02007f2:	fb59f8e3          	bgeu	s3,s5,ffffffffc02007a2 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc02007f6:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc02007fa:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc02007fe:	00004517          	auipc	a0,0x4
ffffffffc0200802:	a5a50513          	addi	a0,a0,-1446 # ffffffffc0204258 <commands+0x118>
           fdt32_to_cpu(x >> 32);
ffffffffc0200806:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020080a:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc020080e:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200812:	0187de1b          	srliw	t3,a5,0x18
ffffffffc0200816:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020081a:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020081e:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200822:	0187d693          	srli	a3,a5,0x18
ffffffffc0200826:	01861f1b          	slliw	t5,a2,0x18
ffffffffc020082a:	0087579b          	srliw	a5,a4,0x8
ffffffffc020082e:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200832:	0106561b          	srliw	a2,a2,0x10
ffffffffc0200836:	010f6f33          	or	t5,t5,a6
ffffffffc020083a:	0187529b          	srliw	t0,a4,0x18
ffffffffc020083e:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200842:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200846:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020084a:	0186f6b3          	and	a3,a3,s8
ffffffffc020084e:	01859e1b          	slliw	t3,a1,0x18
ffffffffc0200852:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200856:	0107581b          	srliw	a6,a4,0x10
ffffffffc020085a:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020085e:	8361                	srli	a4,a4,0x18
ffffffffc0200860:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200864:	0105d59b          	srliw	a1,a1,0x10
ffffffffc0200868:	01e6e6b3          	or	a3,a3,t5
ffffffffc020086c:	00cb7633          	and	a2,s6,a2
ffffffffc0200870:	0088181b          	slliw	a6,a6,0x8
ffffffffc0200874:	0085959b          	slliw	a1,a1,0x8
ffffffffc0200878:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020087c:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200880:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200884:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200888:	0088989b          	slliw	a7,a7,0x8
ffffffffc020088c:	011b78b3          	and	a7,s6,a7
ffffffffc0200890:	005eeeb3          	or	t4,t4,t0
ffffffffc0200894:	00c6e733          	or	a4,a3,a2
ffffffffc0200898:	006c6c33          	or	s8,s8,t1
ffffffffc020089c:	010b76b3          	and	a3,s6,a6
ffffffffc02008a0:	00bb7b33          	and	s6,s6,a1
ffffffffc02008a4:	01d7e7b3          	or	a5,a5,t4
ffffffffc02008a8:	016c6b33          	or	s6,s8,s6
ffffffffc02008ac:	01146433          	or	s0,s0,a7
ffffffffc02008b0:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc02008b2:	1702                	slli	a4,a4,0x20
ffffffffc02008b4:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02008b6:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc02008b8:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02008ba:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc02008bc:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02008c0:	0167eb33          	or	s6,a5,s6
ffffffffc02008c4:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc02008c6:	8cfff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc02008ca:	85a2                	mv	a1,s0
ffffffffc02008cc:	00004517          	auipc	a0,0x4
ffffffffc02008d0:	9ac50513          	addi	a0,a0,-1620 # ffffffffc0204278 <commands+0x138>
ffffffffc02008d4:	8c1ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc02008d8:	014b5613          	srli	a2,s6,0x14
ffffffffc02008dc:	85da                	mv	a1,s6
ffffffffc02008de:	00004517          	auipc	a0,0x4
ffffffffc02008e2:	9b250513          	addi	a0,a0,-1614 # ffffffffc0204290 <commands+0x150>
ffffffffc02008e6:	8afff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc02008ea:	008b05b3          	add	a1,s6,s0
ffffffffc02008ee:	15fd                	addi	a1,a1,-1
ffffffffc02008f0:	00004517          	auipc	a0,0x4
ffffffffc02008f4:	9c050513          	addi	a0,a0,-1600 # ffffffffc02042b0 <commands+0x170>
ffffffffc02008f8:	89dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc02008fc:	00004517          	auipc	a0,0x4
ffffffffc0200900:	a0450513          	addi	a0,a0,-1532 # ffffffffc0204300 <commands+0x1c0>
        memory_base = mem_base;
ffffffffc0200904:	0000d797          	auipc	a5,0xd
ffffffffc0200908:	b687be23          	sd	s0,-1156(a5) # ffffffffc020d480 <memory_base>
        memory_size = mem_size;
ffffffffc020090c:	0000d797          	auipc	a5,0xd
ffffffffc0200910:	b767be23          	sd	s6,-1156(a5) # ffffffffc020d488 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc0200914:	b3f5                	j	ffffffffc0200700 <dtb_init+0x186>

ffffffffc0200916 <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc0200916:	0000d517          	auipc	a0,0xd
ffffffffc020091a:	b6a53503          	ld	a0,-1174(a0) # ffffffffc020d480 <memory_base>
ffffffffc020091e:	8082                	ret

ffffffffc0200920 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc0200920:	0000d517          	auipc	a0,0xd
ffffffffc0200924:	b6853503          	ld	a0,-1176(a0) # ffffffffc020d488 <memory_size>
ffffffffc0200928:	8082                	ret

ffffffffc020092a <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc020092a:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc020092e:	8082                	ret

ffffffffc0200930 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200930:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0200934:	8082                	ret

ffffffffc0200936 <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc0200936:	8082                	ret

ffffffffc0200938 <idt_init>:
void idt_init(void)
{
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc0200938:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc020093c:	00000797          	auipc	a5,0x0
ffffffffc0200940:	3e078793          	addi	a5,a5,992 # ffffffffc0200d1c <__alltraps>
ffffffffc0200944:	10579073          	csrw	stvec,a5
    /* Allow kernel to access user memory */
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc0200948:	000407b7          	lui	a5,0x40
ffffffffc020094c:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc0200950:	8082                	ret

ffffffffc0200952 <print_regs>:
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr)
{
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200952:	610c                	ld	a1,0(a0)
{
ffffffffc0200954:	1141                	addi	sp,sp,-16
ffffffffc0200956:	e022                	sd	s0,0(sp)
ffffffffc0200958:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020095a:	00004517          	auipc	a0,0x4
ffffffffc020095e:	9be50513          	addi	a0,a0,-1602 # ffffffffc0204318 <commands+0x1d8>
{
ffffffffc0200962:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200964:	831ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200968:	640c                	ld	a1,8(s0)
ffffffffc020096a:	00004517          	auipc	a0,0x4
ffffffffc020096e:	9c650513          	addi	a0,a0,-1594 # ffffffffc0204330 <commands+0x1f0>
ffffffffc0200972:	823ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc0200976:	680c                	ld	a1,16(s0)
ffffffffc0200978:	00004517          	auipc	a0,0x4
ffffffffc020097c:	9d050513          	addi	a0,a0,-1584 # ffffffffc0204348 <commands+0x208>
ffffffffc0200980:	815ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200984:	6c0c                	ld	a1,24(s0)
ffffffffc0200986:	00004517          	auipc	a0,0x4
ffffffffc020098a:	9da50513          	addi	a0,a0,-1574 # ffffffffc0204360 <commands+0x220>
ffffffffc020098e:	807ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200992:	700c                	ld	a1,32(s0)
ffffffffc0200994:	00004517          	auipc	a0,0x4
ffffffffc0200998:	9e450513          	addi	a0,a0,-1564 # ffffffffc0204378 <commands+0x238>
ffffffffc020099c:	ff8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02009a0:	740c                	ld	a1,40(s0)
ffffffffc02009a2:	00004517          	auipc	a0,0x4
ffffffffc02009a6:	9ee50513          	addi	a0,a0,-1554 # ffffffffc0204390 <commands+0x250>
ffffffffc02009aa:	feaff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02009ae:	780c                	ld	a1,48(s0)
ffffffffc02009b0:	00004517          	auipc	a0,0x4
ffffffffc02009b4:	9f850513          	addi	a0,a0,-1544 # ffffffffc02043a8 <commands+0x268>
ffffffffc02009b8:	fdcff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02009bc:	7c0c                	ld	a1,56(s0)
ffffffffc02009be:	00004517          	auipc	a0,0x4
ffffffffc02009c2:	a0250513          	addi	a0,a0,-1534 # ffffffffc02043c0 <commands+0x280>
ffffffffc02009c6:	fceff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02009ca:	602c                	ld	a1,64(s0)
ffffffffc02009cc:	00004517          	auipc	a0,0x4
ffffffffc02009d0:	a0c50513          	addi	a0,a0,-1524 # ffffffffc02043d8 <commands+0x298>
ffffffffc02009d4:	fc0ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02009d8:	642c                	ld	a1,72(s0)
ffffffffc02009da:	00004517          	auipc	a0,0x4
ffffffffc02009de:	a1650513          	addi	a0,a0,-1514 # ffffffffc02043f0 <commands+0x2b0>
ffffffffc02009e2:	fb2ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc02009e6:	682c                	ld	a1,80(s0)
ffffffffc02009e8:	00004517          	auipc	a0,0x4
ffffffffc02009ec:	a2050513          	addi	a0,a0,-1504 # ffffffffc0204408 <commands+0x2c8>
ffffffffc02009f0:	fa4ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc02009f4:	6c2c                	ld	a1,88(s0)
ffffffffc02009f6:	00004517          	auipc	a0,0x4
ffffffffc02009fa:	a2a50513          	addi	a0,a0,-1494 # ffffffffc0204420 <commands+0x2e0>
ffffffffc02009fe:	f96ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200a02:	702c                	ld	a1,96(s0)
ffffffffc0200a04:	00004517          	auipc	a0,0x4
ffffffffc0200a08:	a3450513          	addi	a0,a0,-1484 # ffffffffc0204438 <commands+0x2f8>
ffffffffc0200a0c:	f88ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200a10:	742c                	ld	a1,104(s0)
ffffffffc0200a12:	00004517          	auipc	a0,0x4
ffffffffc0200a16:	a3e50513          	addi	a0,a0,-1474 # ffffffffc0204450 <commands+0x310>
ffffffffc0200a1a:	f7aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200a1e:	782c                	ld	a1,112(s0)
ffffffffc0200a20:	00004517          	auipc	a0,0x4
ffffffffc0200a24:	a4850513          	addi	a0,a0,-1464 # ffffffffc0204468 <commands+0x328>
ffffffffc0200a28:	f6cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200a2c:	7c2c                	ld	a1,120(s0)
ffffffffc0200a2e:	00004517          	auipc	a0,0x4
ffffffffc0200a32:	a5250513          	addi	a0,a0,-1454 # ffffffffc0204480 <commands+0x340>
ffffffffc0200a36:	f5eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200a3a:	604c                	ld	a1,128(s0)
ffffffffc0200a3c:	00004517          	auipc	a0,0x4
ffffffffc0200a40:	a5c50513          	addi	a0,a0,-1444 # ffffffffc0204498 <commands+0x358>
ffffffffc0200a44:	f50ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200a48:	644c                	ld	a1,136(s0)
ffffffffc0200a4a:	00004517          	auipc	a0,0x4
ffffffffc0200a4e:	a6650513          	addi	a0,a0,-1434 # ffffffffc02044b0 <commands+0x370>
ffffffffc0200a52:	f42ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200a56:	684c                	ld	a1,144(s0)
ffffffffc0200a58:	00004517          	auipc	a0,0x4
ffffffffc0200a5c:	a7050513          	addi	a0,a0,-1424 # ffffffffc02044c8 <commands+0x388>
ffffffffc0200a60:	f34ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200a64:	6c4c                	ld	a1,152(s0)
ffffffffc0200a66:	00004517          	auipc	a0,0x4
ffffffffc0200a6a:	a7a50513          	addi	a0,a0,-1414 # ffffffffc02044e0 <commands+0x3a0>
ffffffffc0200a6e:	f26ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200a72:	704c                	ld	a1,160(s0)
ffffffffc0200a74:	00004517          	auipc	a0,0x4
ffffffffc0200a78:	a8450513          	addi	a0,a0,-1404 # ffffffffc02044f8 <commands+0x3b8>
ffffffffc0200a7c:	f18ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200a80:	744c                	ld	a1,168(s0)
ffffffffc0200a82:	00004517          	auipc	a0,0x4
ffffffffc0200a86:	a8e50513          	addi	a0,a0,-1394 # ffffffffc0204510 <commands+0x3d0>
ffffffffc0200a8a:	f0aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200a8e:	784c                	ld	a1,176(s0)
ffffffffc0200a90:	00004517          	auipc	a0,0x4
ffffffffc0200a94:	a9850513          	addi	a0,a0,-1384 # ffffffffc0204528 <commands+0x3e8>
ffffffffc0200a98:	efcff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200a9c:	7c4c                	ld	a1,184(s0)
ffffffffc0200a9e:	00004517          	auipc	a0,0x4
ffffffffc0200aa2:	aa250513          	addi	a0,a0,-1374 # ffffffffc0204540 <commands+0x400>
ffffffffc0200aa6:	eeeff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc0200aaa:	606c                	ld	a1,192(s0)
ffffffffc0200aac:	00004517          	auipc	a0,0x4
ffffffffc0200ab0:	aac50513          	addi	a0,a0,-1364 # ffffffffc0204558 <commands+0x418>
ffffffffc0200ab4:	ee0ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc0200ab8:	646c                	ld	a1,200(s0)
ffffffffc0200aba:	00004517          	auipc	a0,0x4
ffffffffc0200abe:	ab650513          	addi	a0,a0,-1354 # ffffffffc0204570 <commands+0x430>
ffffffffc0200ac2:	ed2ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200ac6:	686c                	ld	a1,208(s0)
ffffffffc0200ac8:	00004517          	auipc	a0,0x4
ffffffffc0200acc:	ac050513          	addi	a0,a0,-1344 # ffffffffc0204588 <commands+0x448>
ffffffffc0200ad0:	ec4ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200ad4:	6c6c                	ld	a1,216(s0)
ffffffffc0200ad6:	00004517          	auipc	a0,0x4
ffffffffc0200ada:	aca50513          	addi	a0,a0,-1334 # ffffffffc02045a0 <commands+0x460>
ffffffffc0200ade:	eb6ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200ae2:	706c                	ld	a1,224(s0)
ffffffffc0200ae4:	00004517          	auipc	a0,0x4
ffffffffc0200ae8:	ad450513          	addi	a0,a0,-1324 # ffffffffc02045b8 <commands+0x478>
ffffffffc0200aec:	ea8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200af0:	746c                	ld	a1,232(s0)
ffffffffc0200af2:	00004517          	auipc	a0,0x4
ffffffffc0200af6:	ade50513          	addi	a0,a0,-1314 # ffffffffc02045d0 <commands+0x490>
ffffffffc0200afa:	e9aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200afe:	786c                	ld	a1,240(s0)
ffffffffc0200b00:	00004517          	auipc	a0,0x4
ffffffffc0200b04:	ae850513          	addi	a0,a0,-1304 # ffffffffc02045e8 <commands+0x4a8>
ffffffffc0200b08:	e8cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b0c:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200b0e:	6402                	ld	s0,0(sp)
ffffffffc0200b10:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b12:	00004517          	auipc	a0,0x4
ffffffffc0200b16:	aee50513          	addi	a0,a0,-1298 # ffffffffc0204600 <commands+0x4c0>
}
ffffffffc0200b1a:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b1c:	e78ff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200b20 <print_trapframe>:
{
ffffffffc0200b20:	1141                	addi	sp,sp,-16
ffffffffc0200b22:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200b24:	85aa                	mv	a1,a0
{
ffffffffc0200b26:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200b28:	00004517          	auipc	a0,0x4
ffffffffc0200b2c:	af050513          	addi	a0,a0,-1296 # ffffffffc0204618 <commands+0x4d8>
{
ffffffffc0200b30:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200b32:	e62ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200b36:	8522                	mv	a0,s0
ffffffffc0200b38:	e1bff0ef          	jal	ra,ffffffffc0200952 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200b3c:	10043583          	ld	a1,256(s0)
ffffffffc0200b40:	00004517          	auipc	a0,0x4
ffffffffc0200b44:	af050513          	addi	a0,a0,-1296 # ffffffffc0204630 <commands+0x4f0>
ffffffffc0200b48:	e4cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200b4c:	10843583          	ld	a1,264(s0)
ffffffffc0200b50:	00004517          	auipc	a0,0x4
ffffffffc0200b54:	af850513          	addi	a0,a0,-1288 # ffffffffc0204648 <commands+0x508>
ffffffffc0200b58:	e3cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200b5c:	11043583          	ld	a1,272(s0)
ffffffffc0200b60:	00004517          	auipc	a0,0x4
ffffffffc0200b64:	b0050513          	addi	a0,a0,-1280 # ffffffffc0204660 <commands+0x520>
ffffffffc0200b68:	e2cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b6c:	11843583          	ld	a1,280(s0)
}
ffffffffc0200b70:	6402                	ld	s0,0(sp)
ffffffffc0200b72:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b74:	00004517          	auipc	a0,0x4
ffffffffc0200b78:	b0450513          	addi	a0,a0,-1276 # ffffffffc0204678 <commands+0x538>
}
ffffffffc0200b7c:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b7e:	e16ff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200b82 <interrupt_handler>:

extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf)
{
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc0200b82:	11853783          	ld	a5,280(a0)
ffffffffc0200b86:	472d                	li	a4,11
ffffffffc0200b88:	0786                	slli	a5,a5,0x1
ffffffffc0200b8a:	8385                	srli	a5,a5,0x1
ffffffffc0200b8c:	06f76d63          	bltu	a4,a5,ffffffffc0200c06 <interrupt_handler+0x84>
ffffffffc0200b90:	00004717          	auipc	a4,0x4
ffffffffc0200b94:	bb070713          	addi	a4,a4,-1104 # ffffffffc0204740 <commands+0x600>
ffffffffc0200b98:	078a                	slli	a5,a5,0x2
ffffffffc0200b9a:	97ba                	add	a5,a5,a4
ffffffffc0200b9c:	439c                	lw	a5,0(a5)
ffffffffc0200b9e:	97ba                	add	a5,a5,a4
ffffffffc0200ba0:	8782                	jr	a5
        break;
    case IRQ_H_SOFT:
        cprintf("Hypervisor software interrupt\n");
        break;
    case IRQ_M_SOFT:
        cprintf("Machine software interrupt\n");
ffffffffc0200ba2:	00004517          	auipc	a0,0x4
ffffffffc0200ba6:	b4e50513          	addi	a0,a0,-1202 # ffffffffc02046f0 <commands+0x5b0>
ffffffffc0200baa:	deaff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc0200bae:	00004517          	auipc	a0,0x4
ffffffffc0200bb2:	b2250513          	addi	a0,a0,-1246 # ffffffffc02046d0 <commands+0x590>
ffffffffc0200bb6:	ddeff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc0200bba:	00004517          	auipc	a0,0x4
ffffffffc0200bbe:	ad650513          	addi	a0,a0,-1322 # ffffffffc0204690 <commands+0x550>
ffffffffc0200bc2:	dd2ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc0200bc6:	00004517          	auipc	a0,0x4
ffffffffc0200bca:	aea50513          	addi	a0,a0,-1302 # ffffffffc02046b0 <commands+0x570>
ffffffffc0200bce:	dc6ff06f          	j	ffffffffc0200194 <cprintf>
{
ffffffffc0200bd2:	1141                	addi	sp,sp,-16
ffffffffc0200bd4:	e406                	sd	ra,8(sp)
        /*(1)设置下次时钟中断- clock_set_next_event()
            *(2)计数器（ticks）加一
            *(3)当计数器加到100的时候，我们会输出一个`100ticks`表示我们触发了100次时钟中断，同时打印次数（num）加一
        * (4)判断打印次数，当打印次数为10时，调用<sbi.h>中的关机函数关机
        */
        clock_set_next_event();
ffffffffc0200bd6:	919ff0ef          	jal	ra,ffffffffc02004ee <clock_set_next_event>
        ticks++;
ffffffffc0200bda:	0000d797          	auipc	a5,0xd
ffffffffc0200bde:	89678793          	addi	a5,a5,-1898 # ffffffffc020d470 <ticks>
ffffffffc0200be2:	6398                	ld	a4,0(a5)
ffffffffc0200be4:	0705                	addi	a4,a4,1
ffffffffc0200be6:	e398                	sd	a4,0(a5)
        if (ticks % TICK_NUM == 0) {
ffffffffc0200be8:	639c                	ld	a5,0(a5)
ffffffffc0200bea:	06400713          	li	a4,100
ffffffffc0200bee:	02e7f7b3          	remu	a5,a5,a4
ffffffffc0200bf2:	cb99                	beqz	a5,ffffffffc0200c08 <interrupt_handler+0x86>
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200bf4:	60a2                	ld	ra,8(sp)
ffffffffc0200bf6:	0141                	addi	sp,sp,16
ffffffffc0200bf8:	8082                	ret
        cprintf("Supervisor external interrupt\n");
ffffffffc0200bfa:	00004517          	auipc	a0,0x4
ffffffffc0200bfe:	b2650513          	addi	a0,a0,-1242 # ffffffffc0204720 <commands+0x5e0>
ffffffffc0200c02:	d92ff06f          	j	ffffffffc0200194 <cprintf>
        print_trapframe(tf);
ffffffffc0200c06:	bf29                	j	ffffffffc0200b20 <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200c08:	06400593          	li	a1,100
ffffffffc0200c0c:	00004517          	auipc	a0,0x4
ffffffffc0200c10:	b0450513          	addi	a0,a0,-1276 # ffffffffc0204710 <commands+0x5d0>
ffffffffc0200c14:	d80ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
            num++;
ffffffffc0200c18:	0000d717          	auipc	a4,0xd
ffffffffc0200c1c:	87870713          	addi	a4,a4,-1928 # ffffffffc020d490 <num.0>
ffffffffc0200c20:	431c                	lw	a5,0(a4)
            if (num == 10) {
ffffffffc0200c22:	46a9                	li	a3,10
            num++;
ffffffffc0200c24:	0017861b          	addiw	a2,a5,1
ffffffffc0200c28:	c310                	sw	a2,0(a4)
            if (num == 10) {
ffffffffc0200c2a:	fcd615e3          	bne	a2,a3,ffffffffc0200bf4 <interrupt_handler+0x72>
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc0200c2e:	4501                	li	a0,0
ffffffffc0200c30:	4581                	li	a1,0
ffffffffc0200c32:	4601                	li	a2,0
ffffffffc0200c34:	48a1                	li	a7,8
ffffffffc0200c36:	00000073          	ecall
}
ffffffffc0200c3a:	bf6d                	j	ffffffffc0200bf4 <interrupt_handler+0x72>

ffffffffc0200c3c <exception_handler>:

void exception_handler(struct trapframe *tf)
{
    int ret;
    switch (tf->cause)
ffffffffc0200c3c:	11853783          	ld	a5,280(a0)
ffffffffc0200c40:	473d                	li	a4,15
ffffffffc0200c42:	0cf76563          	bltu	a4,a5,ffffffffc0200d0c <exception_handler+0xd0>
ffffffffc0200c46:	00004717          	auipc	a4,0x4
ffffffffc0200c4a:	cc270713          	addi	a4,a4,-830 # ffffffffc0204908 <commands+0x7c8>
ffffffffc0200c4e:	078a                	slli	a5,a5,0x2
ffffffffc0200c50:	97ba                	add	a5,a5,a4
ffffffffc0200c52:	439c                	lw	a5,0(a5)
ffffffffc0200c54:	97ba                	add	a5,a5,a4
ffffffffc0200c56:	8782                	jr	a5
        break;
    case CAUSE_LOAD_PAGE_FAULT:
        cprintf("Load page fault\n");
        break;
    case CAUSE_STORE_PAGE_FAULT:
        cprintf("Store/AMO page fault\n");
ffffffffc0200c58:	00004517          	auipc	a0,0x4
ffffffffc0200c5c:	c9850513          	addi	a0,a0,-872 # ffffffffc02048f0 <commands+0x7b0>
ffffffffc0200c60:	d34ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Instruction address misaligned\n");
ffffffffc0200c64:	00004517          	auipc	a0,0x4
ffffffffc0200c68:	b0c50513          	addi	a0,a0,-1268 # ffffffffc0204770 <commands+0x630>
ffffffffc0200c6c:	d28ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Instruction access fault\n");
ffffffffc0200c70:	00004517          	auipc	a0,0x4
ffffffffc0200c74:	b2050513          	addi	a0,a0,-1248 # ffffffffc0204790 <commands+0x650>
ffffffffc0200c78:	d1cff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Illegal instruction\n");
ffffffffc0200c7c:	00004517          	auipc	a0,0x4
ffffffffc0200c80:	b3450513          	addi	a0,a0,-1228 # ffffffffc02047b0 <commands+0x670>
ffffffffc0200c84:	d10ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Breakpoint\n");
ffffffffc0200c88:	00004517          	auipc	a0,0x4
ffffffffc0200c8c:	b4050513          	addi	a0,a0,-1216 # ffffffffc02047c8 <commands+0x688>
ffffffffc0200c90:	d04ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Load address misaligned\n");
ffffffffc0200c94:	00004517          	auipc	a0,0x4
ffffffffc0200c98:	b4450513          	addi	a0,a0,-1212 # ffffffffc02047d8 <commands+0x698>
ffffffffc0200c9c:	cf8ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Load access fault\n");
ffffffffc0200ca0:	00004517          	auipc	a0,0x4
ffffffffc0200ca4:	b5850513          	addi	a0,a0,-1192 # ffffffffc02047f8 <commands+0x6b8>
ffffffffc0200ca8:	cecff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("AMO address misaligned\n");
ffffffffc0200cac:	00004517          	auipc	a0,0x4
ffffffffc0200cb0:	b6450513          	addi	a0,a0,-1180 # ffffffffc0204810 <commands+0x6d0>
ffffffffc0200cb4:	ce0ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Store/AMO access fault\n");
ffffffffc0200cb8:	00004517          	auipc	a0,0x4
ffffffffc0200cbc:	b7050513          	addi	a0,a0,-1168 # ffffffffc0204828 <commands+0x6e8>
ffffffffc0200cc0:	cd4ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Environment call from U-mode\n");
ffffffffc0200cc4:	00004517          	auipc	a0,0x4
ffffffffc0200cc8:	b7c50513          	addi	a0,a0,-1156 # ffffffffc0204840 <commands+0x700>
ffffffffc0200ccc:	cc8ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Environment call from S-mode\n");
ffffffffc0200cd0:	00004517          	auipc	a0,0x4
ffffffffc0200cd4:	b9050513          	addi	a0,a0,-1136 # ffffffffc0204860 <commands+0x720>
ffffffffc0200cd8:	cbcff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Environment call from H-mode\n");
ffffffffc0200cdc:	00004517          	auipc	a0,0x4
ffffffffc0200ce0:	ba450513          	addi	a0,a0,-1116 # ffffffffc0204880 <commands+0x740>
ffffffffc0200ce4:	cb0ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Environment call from M-mode\n");
ffffffffc0200ce8:	00004517          	auipc	a0,0x4
ffffffffc0200cec:	bb850513          	addi	a0,a0,-1096 # ffffffffc02048a0 <commands+0x760>
ffffffffc0200cf0:	ca4ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Instruction page fault\n");
ffffffffc0200cf4:	00004517          	auipc	a0,0x4
ffffffffc0200cf8:	bcc50513          	addi	a0,a0,-1076 # ffffffffc02048c0 <commands+0x780>
ffffffffc0200cfc:	c98ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Load page fault\n");
ffffffffc0200d00:	00004517          	auipc	a0,0x4
ffffffffc0200d04:	bd850513          	addi	a0,a0,-1064 # ffffffffc02048d8 <commands+0x798>
ffffffffc0200d08:	c8cff06f          	j	ffffffffc0200194 <cprintf>
        break;
    default:
        print_trapframe(tf);
ffffffffc0200d0c:	bd11                	j	ffffffffc0200b20 <print_trapframe>

ffffffffc0200d0e <trap>:
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf)
{
    // dispatch based on what type of trap occurred
    if ((intptr_t)tf->cause < 0)
ffffffffc0200d0e:	11853783          	ld	a5,280(a0)
ffffffffc0200d12:	0007c363          	bltz	a5,ffffffffc0200d18 <trap+0xa>
        interrupt_handler(tf);
    }
    else
    {
        // exceptions
        exception_handler(tf);
ffffffffc0200d16:	b71d                	j	ffffffffc0200c3c <exception_handler>
        interrupt_handler(tf);
ffffffffc0200d18:	b5ad                	j	ffffffffc0200b82 <interrupt_handler>
	...

ffffffffc0200d1c <__alltraps>:
    LOAD  x2,2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200d1c:	14011073          	csrw	sscratch,sp
ffffffffc0200d20:	712d                	addi	sp,sp,-288
ffffffffc0200d22:	e406                	sd	ra,8(sp)
ffffffffc0200d24:	ec0e                	sd	gp,24(sp)
ffffffffc0200d26:	f012                	sd	tp,32(sp)
ffffffffc0200d28:	f416                	sd	t0,40(sp)
ffffffffc0200d2a:	f81a                	sd	t1,48(sp)
ffffffffc0200d2c:	fc1e                	sd	t2,56(sp)
ffffffffc0200d2e:	e0a2                	sd	s0,64(sp)
ffffffffc0200d30:	e4a6                	sd	s1,72(sp)
ffffffffc0200d32:	e8aa                	sd	a0,80(sp)
ffffffffc0200d34:	ecae                	sd	a1,88(sp)
ffffffffc0200d36:	f0b2                	sd	a2,96(sp)
ffffffffc0200d38:	f4b6                	sd	a3,104(sp)
ffffffffc0200d3a:	f8ba                	sd	a4,112(sp)
ffffffffc0200d3c:	fcbe                	sd	a5,120(sp)
ffffffffc0200d3e:	e142                	sd	a6,128(sp)
ffffffffc0200d40:	e546                	sd	a7,136(sp)
ffffffffc0200d42:	e94a                	sd	s2,144(sp)
ffffffffc0200d44:	ed4e                	sd	s3,152(sp)
ffffffffc0200d46:	f152                	sd	s4,160(sp)
ffffffffc0200d48:	f556                	sd	s5,168(sp)
ffffffffc0200d4a:	f95a                	sd	s6,176(sp)
ffffffffc0200d4c:	fd5e                	sd	s7,184(sp)
ffffffffc0200d4e:	e1e2                	sd	s8,192(sp)
ffffffffc0200d50:	e5e6                	sd	s9,200(sp)
ffffffffc0200d52:	e9ea                	sd	s10,208(sp)
ffffffffc0200d54:	edee                	sd	s11,216(sp)
ffffffffc0200d56:	f1f2                	sd	t3,224(sp)
ffffffffc0200d58:	f5f6                	sd	t4,232(sp)
ffffffffc0200d5a:	f9fa                	sd	t5,240(sp)
ffffffffc0200d5c:	fdfe                	sd	t6,248(sp)
ffffffffc0200d5e:	14002473          	csrr	s0,sscratch
ffffffffc0200d62:	100024f3          	csrr	s1,sstatus
ffffffffc0200d66:	14102973          	csrr	s2,sepc
ffffffffc0200d6a:	143029f3          	csrr	s3,stval
ffffffffc0200d6e:	14202a73          	csrr	s4,scause
ffffffffc0200d72:	e822                	sd	s0,16(sp)
ffffffffc0200d74:	e226                	sd	s1,256(sp)
ffffffffc0200d76:	e64a                	sd	s2,264(sp)
ffffffffc0200d78:	ea4e                	sd	s3,272(sp)
ffffffffc0200d7a:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200d7c:	850a                	mv	a0,sp
    jal trap
ffffffffc0200d7e:	f91ff0ef          	jal	ra,ffffffffc0200d0e <trap>

ffffffffc0200d82 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200d82:	6492                	ld	s1,256(sp)
ffffffffc0200d84:	6932                	ld	s2,264(sp)
ffffffffc0200d86:	10049073          	csrw	sstatus,s1
ffffffffc0200d8a:	14191073          	csrw	sepc,s2
ffffffffc0200d8e:	60a2                	ld	ra,8(sp)
ffffffffc0200d90:	61e2                	ld	gp,24(sp)
ffffffffc0200d92:	7202                	ld	tp,32(sp)
ffffffffc0200d94:	72a2                	ld	t0,40(sp)
ffffffffc0200d96:	7342                	ld	t1,48(sp)
ffffffffc0200d98:	73e2                	ld	t2,56(sp)
ffffffffc0200d9a:	6406                	ld	s0,64(sp)
ffffffffc0200d9c:	64a6                	ld	s1,72(sp)
ffffffffc0200d9e:	6546                	ld	a0,80(sp)
ffffffffc0200da0:	65e6                	ld	a1,88(sp)
ffffffffc0200da2:	7606                	ld	a2,96(sp)
ffffffffc0200da4:	76a6                	ld	a3,104(sp)
ffffffffc0200da6:	7746                	ld	a4,112(sp)
ffffffffc0200da8:	77e6                	ld	a5,120(sp)
ffffffffc0200daa:	680a                	ld	a6,128(sp)
ffffffffc0200dac:	68aa                	ld	a7,136(sp)
ffffffffc0200dae:	694a                	ld	s2,144(sp)
ffffffffc0200db0:	69ea                	ld	s3,152(sp)
ffffffffc0200db2:	7a0a                	ld	s4,160(sp)
ffffffffc0200db4:	7aaa                	ld	s5,168(sp)
ffffffffc0200db6:	7b4a                	ld	s6,176(sp)
ffffffffc0200db8:	7bea                	ld	s7,184(sp)
ffffffffc0200dba:	6c0e                	ld	s8,192(sp)
ffffffffc0200dbc:	6cae                	ld	s9,200(sp)
ffffffffc0200dbe:	6d4e                	ld	s10,208(sp)
ffffffffc0200dc0:	6dee                	ld	s11,216(sp)
ffffffffc0200dc2:	7e0e                	ld	t3,224(sp)
ffffffffc0200dc4:	7eae                	ld	t4,232(sp)
ffffffffc0200dc6:	7f4e                	ld	t5,240(sp)
ffffffffc0200dc8:	7fee                	ld	t6,248(sp)
ffffffffc0200dca:	6142                	ld	sp,16(sp)
    # go back from supervisor call
    sret
ffffffffc0200dcc:	10200073          	sret

ffffffffc0200dd0 <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200dd0:	812a                	mv	sp,a0
    j __trapret
ffffffffc0200dd2:	bf45                	j	ffffffffc0200d82 <__trapret>
	...

ffffffffc0200dd6 <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200dd6:	00008797          	auipc	a5,0x8
ffffffffc0200dda:	65a78793          	addi	a5,a5,1626 # ffffffffc0209430 <free_area>
ffffffffc0200dde:	e79c                	sd	a5,8(a5)
ffffffffc0200de0:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200de2:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200de6:	8082                	ret

ffffffffc0200de8 <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200de8:	00008517          	auipc	a0,0x8
ffffffffc0200dec:	65856503          	lwu	a0,1624(a0) # ffffffffc0209440 <free_area+0x10>
ffffffffc0200df0:	8082                	ret

ffffffffc0200df2 <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc0200df2:	715d                	addi	sp,sp,-80
ffffffffc0200df4:	e0a2                	sd	s0,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200df6:	00008417          	auipc	s0,0x8
ffffffffc0200dfa:	63a40413          	addi	s0,s0,1594 # ffffffffc0209430 <free_area>
ffffffffc0200dfe:	641c                	ld	a5,8(s0)
ffffffffc0200e00:	e486                	sd	ra,72(sp)
ffffffffc0200e02:	fc26                	sd	s1,56(sp)
ffffffffc0200e04:	f84a                	sd	s2,48(sp)
ffffffffc0200e06:	f44e                	sd	s3,40(sp)
ffffffffc0200e08:	f052                	sd	s4,32(sp)
ffffffffc0200e0a:	ec56                	sd	s5,24(sp)
ffffffffc0200e0c:	e85a                	sd	s6,16(sp)
ffffffffc0200e0e:	e45e                	sd	s7,8(sp)
ffffffffc0200e10:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200e12:	2a878d63          	beq	a5,s0,ffffffffc02010cc <default_check+0x2da>
    int count = 0, total = 0;
ffffffffc0200e16:	4481                	li	s1,0
ffffffffc0200e18:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200e1a:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200e1e:	8b09                	andi	a4,a4,2
ffffffffc0200e20:	2a070a63          	beqz	a4,ffffffffc02010d4 <default_check+0x2e2>
        count ++, total += p->property;
ffffffffc0200e24:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200e28:	679c                	ld	a5,8(a5)
ffffffffc0200e2a:	2905                	addiw	s2,s2,1
ffffffffc0200e2c:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200e2e:	fe8796e3          	bne	a5,s0,ffffffffc0200e1a <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0200e32:	89a6                	mv	s3,s1
ffffffffc0200e34:	6db000ef          	jal	ra,ffffffffc0201d0e <nr_free_pages>
ffffffffc0200e38:	6f351e63          	bne	a0,s3,ffffffffc0201534 <default_check+0x742>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200e3c:	4505                	li	a0,1
ffffffffc0200e3e:	653000ef          	jal	ra,ffffffffc0201c90 <alloc_pages>
ffffffffc0200e42:	8aaa                	mv	s5,a0
ffffffffc0200e44:	42050863          	beqz	a0,ffffffffc0201274 <default_check+0x482>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200e48:	4505                	li	a0,1
ffffffffc0200e4a:	647000ef          	jal	ra,ffffffffc0201c90 <alloc_pages>
ffffffffc0200e4e:	89aa                	mv	s3,a0
ffffffffc0200e50:	70050263          	beqz	a0,ffffffffc0201554 <default_check+0x762>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200e54:	4505                	li	a0,1
ffffffffc0200e56:	63b000ef          	jal	ra,ffffffffc0201c90 <alloc_pages>
ffffffffc0200e5a:	8a2a                	mv	s4,a0
ffffffffc0200e5c:	48050c63          	beqz	a0,ffffffffc02012f4 <default_check+0x502>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200e60:	293a8a63          	beq	s5,s3,ffffffffc02010f4 <default_check+0x302>
ffffffffc0200e64:	28aa8863          	beq	s5,a0,ffffffffc02010f4 <default_check+0x302>
ffffffffc0200e68:	28a98663          	beq	s3,a0,ffffffffc02010f4 <default_check+0x302>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200e6c:	000aa783          	lw	a5,0(s5)
ffffffffc0200e70:	2a079263          	bnez	a5,ffffffffc0201114 <default_check+0x322>
ffffffffc0200e74:	0009a783          	lw	a5,0(s3)
ffffffffc0200e78:	28079e63          	bnez	a5,ffffffffc0201114 <default_check+0x322>
ffffffffc0200e7c:	411c                	lw	a5,0(a0)
ffffffffc0200e7e:	28079b63          	bnez	a5,ffffffffc0201114 <default_check+0x322>
extern uint_t va_pa_offset;

static inline ppn_t
page2ppn(struct Page *page)
{
    return page - pages + nbase;
ffffffffc0200e82:	0000c797          	auipc	a5,0xc
ffffffffc0200e86:	6367b783          	ld	a5,1590(a5) # ffffffffc020d4b8 <pages>
ffffffffc0200e8a:	40fa8733          	sub	a4,s5,a5
ffffffffc0200e8e:	00005617          	auipc	a2,0x5
ffffffffc0200e92:	bd263603          	ld	a2,-1070(a2) # ffffffffc0205a60 <nbase>
ffffffffc0200e96:	8719                	srai	a4,a4,0x6
ffffffffc0200e98:	9732                	add	a4,a4,a2
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200e9a:	0000c697          	auipc	a3,0xc
ffffffffc0200e9e:	6166b683          	ld	a3,1558(a3) # ffffffffc020d4b0 <npage>
ffffffffc0200ea2:	06b2                	slli	a3,a3,0xc
}

static inline uintptr_t
page2pa(struct Page *page)
{
    return page2ppn(page) << PGSHIFT;
ffffffffc0200ea4:	0732                	slli	a4,a4,0xc
ffffffffc0200ea6:	28d77763          	bgeu	a4,a3,ffffffffc0201134 <default_check+0x342>
    return page - pages + nbase;
ffffffffc0200eaa:	40f98733          	sub	a4,s3,a5
ffffffffc0200eae:	8719                	srai	a4,a4,0x6
ffffffffc0200eb0:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200eb2:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200eb4:	4cd77063          	bgeu	a4,a3,ffffffffc0201374 <default_check+0x582>
    return page - pages + nbase;
ffffffffc0200eb8:	40f507b3          	sub	a5,a0,a5
ffffffffc0200ebc:	8799                	srai	a5,a5,0x6
ffffffffc0200ebe:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200ec0:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200ec2:	30d7f963          	bgeu	a5,a3,ffffffffc02011d4 <default_check+0x3e2>
    assert(alloc_page() == NULL);
ffffffffc0200ec6:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200ec8:	00043c03          	ld	s8,0(s0)
ffffffffc0200ecc:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0200ed0:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0200ed4:	e400                	sd	s0,8(s0)
ffffffffc0200ed6:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0200ed8:	00008797          	auipc	a5,0x8
ffffffffc0200edc:	5607a423          	sw	zero,1384(a5) # ffffffffc0209440 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200ee0:	5b1000ef          	jal	ra,ffffffffc0201c90 <alloc_pages>
ffffffffc0200ee4:	2c051863          	bnez	a0,ffffffffc02011b4 <default_check+0x3c2>
    free_page(p0);
ffffffffc0200ee8:	4585                	li	a1,1
ffffffffc0200eea:	8556                	mv	a0,s5
ffffffffc0200eec:	5e3000ef          	jal	ra,ffffffffc0201cce <free_pages>
    free_page(p1);
ffffffffc0200ef0:	4585                	li	a1,1
ffffffffc0200ef2:	854e                	mv	a0,s3
ffffffffc0200ef4:	5db000ef          	jal	ra,ffffffffc0201cce <free_pages>
    free_page(p2);
ffffffffc0200ef8:	4585                	li	a1,1
ffffffffc0200efa:	8552                	mv	a0,s4
ffffffffc0200efc:	5d3000ef          	jal	ra,ffffffffc0201cce <free_pages>
    assert(nr_free == 3);
ffffffffc0200f00:	4818                	lw	a4,16(s0)
ffffffffc0200f02:	478d                	li	a5,3
ffffffffc0200f04:	28f71863          	bne	a4,a5,ffffffffc0201194 <default_check+0x3a2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200f08:	4505                	li	a0,1
ffffffffc0200f0a:	587000ef          	jal	ra,ffffffffc0201c90 <alloc_pages>
ffffffffc0200f0e:	89aa                	mv	s3,a0
ffffffffc0200f10:	26050263          	beqz	a0,ffffffffc0201174 <default_check+0x382>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200f14:	4505                	li	a0,1
ffffffffc0200f16:	57b000ef          	jal	ra,ffffffffc0201c90 <alloc_pages>
ffffffffc0200f1a:	8aaa                	mv	s5,a0
ffffffffc0200f1c:	3a050c63          	beqz	a0,ffffffffc02012d4 <default_check+0x4e2>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200f20:	4505                	li	a0,1
ffffffffc0200f22:	56f000ef          	jal	ra,ffffffffc0201c90 <alloc_pages>
ffffffffc0200f26:	8a2a                	mv	s4,a0
ffffffffc0200f28:	38050663          	beqz	a0,ffffffffc02012b4 <default_check+0x4c2>
    assert(alloc_page() == NULL);
ffffffffc0200f2c:	4505                	li	a0,1
ffffffffc0200f2e:	563000ef          	jal	ra,ffffffffc0201c90 <alloc_pages>
ffffffffc0200f32:	36051163          	bnez	a0,ffffffffc0201294 <default_check+0x4a2>
    free_page(p0);
ffffffffc0200f36:	4585                	li	a1,1
ffffffffc0200f38:	854e                	mv	a0,s3
ffffffffc0200f3a:	595000ef          	jal	ra,ffffffffc0201cce <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200f3e:	641c                	ld	a5,8(s0)
ffffffffc0200f40:	20878a63          	beq	a5,s0,ffffffffc0201154 <default_check+0x362>
    assert((p = alloc_page()) == p0);
ffffffffc0200f44:	4505                	li	a0,1
ffffffffc0200f46:	54b000ef          	jal	ra,ffffffffc0201c90 <alloc_pages>
ffffffffc0200f4a:	30a99563          	bne	s3,a0,ffffffffc0201254 <default_check+0x462>
    assert(alloc_page() == NULL);
ffffffffc0200f4e:	4505                	li	a0,1
ffffffffc0200f50:	541000ef          	jal	ra,ffffffffc0201c90 <alloc_pages>
ffffffffc0200f54:	2e051063          	bnez	a0,ffffffffc0201234 <default_check+0x442>
    assert(nr_free == 0);
ffffffffc0200f58:	481c                	lw	a5,16(s0)
ffffffffc0200f5a:	2a079d63          	bnez	a5,ffffffffc0201214 <default_check+0x422>
    free_page(p);
ffffffffc0200f5e:	854e                	mv	a0,s3
ffffffffc0200f60:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200f62:	01843023          	sd	s8,0(s0)
ffffffffc0200f66:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0200f6a:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0200f6e:	561000ef          	jal	ra,ffffffffc0201cce <free_pages>
    free_page(p1);
ffffffffc0200f72:	4585                	li	a1,1
ffffffffc0200f74:	8556                	mv	a0,s5
ffffffffc0200f76:	559000ef          	jal	ra,ffffffffc0201cce <free_pages>
    free_page(p2);
ffffffffc0200f7a:	4585                	li	a1,1
ffffffffc0200f7c:	8552                	mv	a0,s4
ffffffffc0200f7e:	551000ef          	jal	ra,ffffffffc0201cce <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200f82:	4515                	li	a0,5
ffffffffc0200f84:	50d000ef          	jal	ra,ffffffffc0201c90 <alloc_pages>
ffffffffc0200f88:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200f8a:	26050563          	beqz	a0,ffffffffc02011f4 <default_check+0x402>
ffffffffc0200f8e:	651c                	ld	a5,8(a0)
ffffffffc0200f90:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0200f92:	8b85                	andi	a5,a5,1
ffffffffc0200f94:	54079063          	bnez	a5,ffffffffc02014d4 <default_check+0x6e2>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200f98:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200f9a:	00043b03          	ld	s6,0(s0)
ffffffffc0200f9e:	00843a83          	ld	s5,8(s0)
ffffffffc0200fa2:	e000                	sd	s0,0(s0)
ffffffffc0200fa4:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0200fa6:	4eb000ef          	jal	ra,ffffffffc0201c90 <alloc_pages>
ffffffffc0200faa:	50051563          	bnez	a0,ffffffffc02014b4 <default_check+0x6c2>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0200fae:	08098a13          	addi	s4,s3,128
ffffffffc0200fb2:	8552                	mv	a0,s4
ffffffffc0200fb4:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0200fb6:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc0200fba:	00008797          	auipc	a5,0x8
ffffffffc0200fbe:	4807a323          	sw	zero,1158(a5) # ffffffffc0209440 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc0200fc2:	50d000ef          	jal	ra,ffffffffc0201cce <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200fc6:	4511                	li	a0,4
ffffffffc0200fc8:	4c9000ef          	jal	ra,ffffffffc0201c90 <alloc_pages>
ffffffffc0200fcc:	4c051463          	bnez	a0,ffffffffc0201494 <default_check+0x6a2>
ffffffffc0200fd0:	0889b783          	ld	a5,136(s3)
ffffffffc0200fd4:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0200fd6:	8b85                	andi	a5,a5,1
ffffffffc0200fd8:	48078e63          	beqz	a5,ffffffffc0201474 <default_check+0x682>
ffffffffc0200fdc:	0909a703          	lw	a4,144(s3)
ffffffffc0200fe0:	478d                	li	a5,3
ffffffffc0200fe2:	48f71963          	bne	a4,a5,ffffffffc0201474 <default_check+0x682>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0200fe6:	450d                	li	a0,3
ffffffffc0200fe8:	4a9000ef          	jal	ra,ffffffffc0201c90 <alloc_pages>
ffffffffc0200fec:	8c2a                	mv	s8,a0
ffffffffc0200fee:	46050363          	beqz	a0,ffffffffc0201454 <default_check+0x662>
    assert(alloc_page() == NULL);
ffffffffc0200ff2:	4505                	li	a0,1
ffffffffc0200ff4:	49d000ef          	jal	ra,ffffffffc0201c90 <alloc_pages>
ffffffffc0200ff8:	42051e63          	bnez	a0,ffffffffc0201434 <default_check+0x642>
    assert(p0 + 2 == p1);
ffffffffc0200ffc:	418a1c63          	bne	s4,s8,ffffffffc0201414 <default_check+0x622>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0201000:	4585                	li	a1,1
ffffffffc0201002:	854e                	mv	a0,s3
ffffffffc0201004:	4cb000ef          	jal	ra,ffffffffc0201cce <free_pages>
    free_pages(p1, 3);
ffffffffc0201008:	458d                	li	a1,3
ffffffffc020100a:	8552                	mv	a0,s4
ffffffffc020100c:	4c3000ef          	jal	ra,ffffffffc0201cce <free_pages>
ffffffffc0201010:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc0201014:	04098c13          	addi	s8,s3,64
ffffffffc0201018:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc020101a:	8b85                	andi	a5,a5,1
ffffffffc020101c:	3c078c63          	beqz	a5,ffffffffc02013f4 <default_check+0x602>
ffffffffc0201020:	0109a703          	lw	a4,16(s3)
ffffffffc0201024:	4785                	li	a5,1
ffffffffc0201026:	3cf71763          	bne	a4,a5,ffffffffc02013f4 <default_check+0x602>
ffffffffc020102a:	008a3783          	ld	a5,8(s4)
ffffffffc020102e:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0201030:	8b85                	andi	a5,a5,1
ffffffffc0201032:	3a078163          	beqz	a5,ffffffffc02013d4 <default_check+0x5e2>
ffffffffc0201036:	010a2703          	lw	a4,16(s4)
ffffffffc020103a:	478d                	li	a5,3
ffffffffc020103c:	38f71c63          	bne	a4,a5,ffffffffc02013d4 <default_check+0x5e2>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201040:	4505                	li	a0,1
ffffffffc0201042:	44f000ef          	jal	ra,ffffffffc0201c90 <alloc_pages>
ffffffffc0201046:	36a99763          	bne	s3,a0,ffffffffc02013b4 <default_check+0x5c2>
    free_page(p0);
ffffffffc020104a:	4585                	li	a1,1
ffffffffc020104c:	483000ef          	jal	ra,ffffffffc0201cce <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201050:	4509                	li	a0,2
ffffffffc0201052:	43f000ef          	jal	ra,ffffffffc0201c90 <alloc_pages>
ffffffffc0201056:	32aa1f63          	bne	s4,a0,ffffffffc0201394 <default_check+0x5a2>

    free_pages(p0, 2);
ffffffffc020105a:	4589                	li	a1,2
ffffffffc020105c:	473000ef          	jal	ra,ffffffffc0201cce <free_pages>
    free_page(p2);
ffffffffc0201060:	4585                	li	a1,1
ffffffffc0201062:	8562                	mv	a0,s8
ffffffffc0201064:	46b000ef          	jal	ra,ffffffffc0201cce <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201068:	4515                	li	a0,5
ffffffffc020106a:	427000ef          	jal	ra,ffffffffc0201c90 <alloc_pages>
ffffffffc020106e:	89aa                	mv	s3,a0
ffffffffc0201070:	48050263          	beqz	a0,ffffffffc02014f4 <default_check+0x702>
    assert(alloc_page() == NULL);
ffffffffc0201074:	4505                	li	a0,1
ffffffffc0201076:	41b000ef          	jal	ra,ffffffffc0201c90 <alloc_pages>
ffffffffc020107a:	2c051d63          	bnez	a0,ffffffffc0201354 <default_check+0x562>

    assert(nr_free == 0);
ffffffffc020107e:	481c                	lw	a5,16(s0)
ffffffffc0201080:	2a079a63          	bnez	a5,ffffffffc0201334 <default_check+0x542>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0201084:	4595                	li	a1,5
ffffffffc0201086:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0201088:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc020108c:	01643023          	sd	s6,0(s0)
ffffffffc0201090:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc0201094:	43b000ef          	jal	ra,ffffffffc0201cce <free_pages>
    return listelm->next;
ffffffffc0201098:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc020109a:	00878963          	beq	a5,s0,ffffffffc02010ac <default_check+0x2ba>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc020109e:	ff87a703          	lw	a4,-8(a5)
ffffffffc02010a2:	679c                	ld	a5,8(a5)
ffffffffc02010a4:	397d                	addiw	s2,s2,-1
ffffffffc02010a6:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc02010a8:	fe879be3          	bne	a5,s0,ffffffffc020109e <default_check+0x2ac>
    }
    assert(count == 0);
ffffffffc02010ac:	26091463          	bnez	s2,ffffffffc0201314 <default_check+0x522>
    assert(total == 0);
ffffffffc02010b0:	46049263          	bnez	s1,ffffffffc0201514 <default_check+0x722>
}
ffffffffc02010b4:	60a6                	ld	ra,72(sp)
ffffffffc02010b6:	6406                	ld	s0,64(sp)
ffffffffc02010b8:	74e2                	ld	s1,56(sp)
ffffffffc02010ba:	7942                	ld	s2,48(sp)
ffffffffc02010bc:	79a2                	ld	s3,40(sp)
ffffffffc02010be:	7a02                	ld	s4,32(sp)
ffffffffc02010c0:	6ae2                	ld	s5,24(sp)
ffffffffc02010c2:	6b42                	ld	s6,16(sp)
ffffffffc02010c4:	6ba2                	ld	s7,8(sp)
ffffffffc02010c6:	6c02                	ld	s8,0(sp)
ffffffffc02010c8:	6161                	addi	sp,sp,80
ffffffffc02010ca:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc02010cc:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc02010ce:	4481                	li	s1,0
ffffffffc02010d0:	4901                	li	s2,0
ffffffffc02010d2:	b38d                	j	ffffffffc0200e34 <default_check+0x42>
        assert(PageProperty(p));
ffffffffc02010d4:	00004697          	auipc	a3,0x4
ffffffffc02010d8:	87468693          	addi	a3,a3,-1932 # ffffffffc0204948 <commands+0x808>
ffffffffc02010dc:	00004617          	auipc	a2,0x4
ffffffffc02010e0:	87c60613          	addi	a2,a2,-1924 # ffffffffc0204958 <commands+0x818>
ffffffffc02010e4:	0f000593          	li	a1,240
ffffffffc02010e8:	00004517          	auipc	a0,0x4
ffffffffc02010ec:	88850513          	addi	a0,a0,-1912 # ffffffffc0204970 <commands+0x830>
ffffffffc02010f0:	b6aff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02010f4:	00004697          	auipc	a3,0x4
ffffffffc02010f8:	91468693          	addi	a3,a3,-1772 # ffffffffc0204a08 <commands+0x8c8>
ffffffffc02010fc:	00004617          	auipc	a2,0x4
ffffffffc0201100:	85c60613          	addi	a2,a2,-1956 # ffffffffc0204958 <commands+0x818>
ffffffffc0201104:	0bd00593          	li	a1,189
ffffffffc0201108:	00004517          	auipc	a0,0x4
ffffffffc020110c:	86850513          	addi	a0,a0,-1944 # ffffffffc0204970 <commands+0x830>
ffffffffc0201110:	b4aff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0201114:	00004697          	auipc	a3,0x4
ffffffffc0201118:	91c68693          	addi	a3,a3,-1764 # ffffffffc0204a30 <commands+0x8f0>
ffffffffc020111c:	00004617          	auipc	a2,0x4
ffffffffc0201120:	83c60613          	addi	a2,a2,-1988 # ffffffffc0204958 <commands+0x818>
ffffffffc0201124:	0be00593          	li	a1,190
ffffffffc0201128:	00004517          	auipc	a0,0x4
ffffffffc020112c:	84850513          	addi	a0,a0,-1976 # ffffffffc0204970 <commands+0x830>
ffffffffc0201130:	b2aff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0201134:	00004697          	auipc	a3,0x4
ffffffffc0201138:	93c68693          	addi	a3,a3,-1732 # ffffffffc0204a70 <commands+0x930>
ffffffffc020113c:	00004617          	auipc	a2,0x4
ffffffffc0201140:	81c60613          	addi	a2,a2,-2020 # ffffffffc0204958 <commands+0x818>
ffffffffc0201144:	0c000593          	li	a1,192
ffffffffc0201148:	00004517          	auipc	a0,0x4
ffffffffc020114c:	82850513          	addi	a0,a0,-2008 # ffffffffc0204970 <commands+0x830>
ffffffffc0201150:	b0aff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(!list_empty(&free_list));
ffffffffc0201154:	00004697          	auipc	a3,0x4
ffffffffc0201158:	9a468693          	addi	a3,a3,-1628 # ffffffffc0204af8 <commands+0x9b8>
ffffffffc020115c:	00003617          	auipc	a2,0x3
ffffffffc0201160:	7fc60613          	addi	a2,a2,2044 # ffffffffc0204958 <commands+0x818>
ffffffffc0201164:	0d900593          	li	a1,217
ffffffffc0201168:	00004517          	auipc	a0,0x4
ffffffffc020116c:	80850513          	addi	a0,a0,-2040 # ffffffffc0204970 <commands+0x830>
ffffffffc0201170:	aeaff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201174:	00004697          	auipc	a3,0x4
ffffffffc0201178:	83468693          	addi	a3,a3,-1996 # ffffffffc02049a8 <commands+0x868>
ffffffffc020117c:	00003617          	auipc	a2,0x3
ffffffffc0201180:	7dc60613          	addi	a2,a2,2012 # ffffffffc0204958 <commands+0x818>
ffffffffc0201184:	0d200593          	li	a1,210
ffffffffc0201188:	00003517          	auipc	a0,0x3
ffffffffc020118c:	7e850513          	addi	a0,a0,2024 # ffffffffc0204970 <commands+0x830>
ffffffffc0201190:	acaff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(nr_free == 3);
ffffffffc0201194:	00004697          	auipc	a3,0x4
ffffffffc0201198:	95468693          	addi	a3,a3,-1708 # ffffffffc0204ae8 <commands+0x9a8>
ffffffffc020119c:	00003617          	auipc	a2,0x3
ffffffffc02011a0:	7bc60613          	addi	a2,a2,1980 # ffffffffc0204958 <commands+0x818>
ffffffffc02011a4:	0d000593          	li	a1,208
ffffffffc02011a8:	00003517          	auipc	a0,0x3
ffffffffc02011ac:	7c850513          	addi	a0,a0,1992 # ffffffffc0204970 <commands+0x830>
ffffffffc02011b0:	aaaff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(alloc_page() == NULL);
ffffffffc02011b4:	00004697          	auipc	a3,0x4
ffffffffc02011b8:	91c68693          	addi	a3,a3,-1764 # ffffffffc0204ad0 <commands+0x990>
ffffffffc02011bc:	00003617          	auipc	a2,0x3
ffffffffc02011c0:	79c60613          	addi	a2,a2,1948 # ffffffffc0204958 <commands+0x818>
ffffffffc02011c4:	0cb00593          	li	a1,203
ffffffffc02011c8:	00003517          	auipc	a0,0x3
ffffffffc02011cc:	7a850513          	addi	a0,a0,1960 # ffffffffc0204970 <commands+0x830>
ffffffffc02011d0:	a8aff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02011d4:	00004697          	auipc	a3,0x4
ffffffffc02011d8:	8dc68693          	addi	a3,a3,-1828 # ffffffffc0204ab0 <commands+0x970>
ffffffffc02011dc:	00003617          	auipc	a2,0x3
ffffffffc02011e0:	77c60613          	addi	a2,a2,1916 # ffffffffc0204958 <commands+0x818>
ffffffffc02011e4:	0c200593          	li	a1,194
ffffffffc02011e8:	00003517          	auipc	a0,0x3
ffffffffc02011ec:	78850513          	addi	a0,a0,1928 # ffffffffc0204970 <commands+0x830>
ffffffffc02011f0:	a6aff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(p0 != NULL);
ffffffffc02011f4:	00004697          	auipc	a3,0x4
ffffffffc02011f8:	94c68693          	addi	a3,a3,-1716 # ffffffffc0204b40 <commands+0xa00>
ffffffffc02011fc:	00003617          	auipc	a2,0x3
ffffffffc0201200:	75c60613          	addi	a2,a2,1884 # ffffffffc0204958 <commands+0x818>
ffffffffc0201204:	0f800593          	li	a1,248
ffffffffc0201208:	00003517          	auipc	a0,0x3
ffffffffc020120c:	76850513          	addi	a0,a0,1896 # ffffffffc0204970 <commands+0x830>
ffffffffc0201210:	a4aff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(nr_free == 0);
ffffffffc0201214:	00004697          	auipc	a3,0x4
ffffffffc0201218:	91c68693          	addi	a3,a3,-1764 # ffffffffc0204b30 <commands+0x9f0>
ffffffffc020121c:	00003617          	auipc	a2,0x3
ffffffffc0201220:	73c60613          	addi	a2,a2,1852 # ffffffffc0204958 <commands+0x818>
ffffffffc0201224:	0df00593          	li	a1,223
ffffffffc0201228:	00003517          	auipc	a0,0x3
ffffffffc020122c:	74850513          	addi	a0,a0,1864 # ffffffffc0204970 <commands+0x830>
ffffffffc0201230:	a2aff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201234:	00004697          	auipc	a3,0x4
ffffffffc0201238:	89c68693          	addi	a3,a3,-1892 # ffffffffc0204ad0 <commands+0x990>
ffffffffc020123c:	00003617          	auipc	a2,0x3
ffffffffc0201240:	71c60613          	addi	a2,a2,1820 # ffffffffc0204958 <commands+0x818>
ffffffffc0201244:	0dd00593          	li	a1,221
ffffffffc0201248:	00003517          	auipc	a0,0x3
ffffffffc020124c:	72850513          	addi	a0,a0,1832 # ffffffffc0204970 <commands+0x830>
ffffffffc0201250:	a0aff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0201254:	00004697          	auipc	a3,0x4
ffffffffc0201258:	8bc68693          	addi	a3,a3,-1860 # ffffffffc0204b10 <commands+0x9d0>
ffffffffc020125c:	00003617          	auipc	a2,0x3
ffffffffc0201260:	6fc60613          	addi	a2,a2,1788 # ffffffffc0204958 <commands+0x818>
ffffffffc0201264:	0dc00593          	li	a1,220
ffffffffc0201268:	00003517          	auipc	a0,0x3
ffffffffc020126c:	70850513          	addi	a0,a0,1800 # ffffffffc0204970 <commands+0x830>
ffffffffc0201270:	9eaff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201274:	00003697          	auipc	a3,0x3
ffffffffc0201278:	73468693          	addi	a3,a3,1844 # ffffffffc02049a8 <commands+0x868>
ffffffffc020127c:	00003617          	auipc	a2,0x3
ffffffffc0201280:	6dc60613          	addi	a2,a2,1756 # ffffffffc0204958 <commands+0x818>
ffffffffc0201284:	0b900593          	li	a1,185
ffffffffc0201288:	00003517          	auipc	a0,0x3
ffffffffc020128c:	6e850513          	addi	a0,a0,1768 # ffffffffc0204970 <commands+0x830>
ffffffffc0201290:	9caff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201294:	00004697          	auipc	a3,0x4
ffffffffc0201298:	83c68693          	addi	a3,a3,-1988 # ffffffffc0204ad0 <commands+0x990>
ffffffffc020129c:	00003617          	auipc	a2,0x3
ffffffffc02012a0:	6bc60613          	addi	a2,a2,1724 # ffffffffc0204958 <commands+0x818>
ffffffffc02012a4:	0d600593          	li	a1,214
ffffffffc02012a8:	00003517          	auipc	a0,0x3
ffffffffc02012ac:	6c850513          	addi	a0,a0,1736 # ffffffffc0204970 <commands+0x830>
ffffffffc02012b0:	9aaff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02012b4:	00003697          	auipc	a3,0x3
ffffffffc02012b8:	73468693          	addi	a3,a3,1844 # ffffffffc02049e8 <commands+0x8a8>
ffffffffc02012bc:	00003617          	auipc	a2,0x3
ffffffffc02012c0:	69c60613          	addi	a2,a2,1692 # ffffffffc0204958 <commands+0x818>
ffffffffc02012c4:	0d400593          	li	a1,212
ffffffffc02012c8:	00003517          	auipc	a0,0x3
ffffffffc02012cc:	6a850513          	addi	a0,a0,1704 # ffffffffc0204970 <commands+0x830>
ffffffffc02012d0:	98aff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02012d4:	00003697          	auipc	a3,0x3
ffffffffc02012d8:	6f468693          	addi	a3,a3,1780 # ffffffffc02049c8 <commands+0x888>
ffffffffc02012dc:	00003617          	auipc	a2,0x3
ffffffffc02012e0:	67c60613          	addi	a2,a2,1660 # ffffffffc0204958 <commands+0x818>
ffffffffc02012e4:	0d300593          	li	a1,211
ffffffffc02012e8:	00003517          	auipc	a0,0x3
ffffffffc02012ec:	68850513          	addi	a0,a0,1672 # ffffffffc0204970 <commands+0x830>
ffffffffc02012f0:	96aff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02012f4:	00003697          	auipc	a3,0x3
ffffffffc02012f8:	6f468693          	addi	a3,a3,1780 # ffffffffc02049e8 <commands+0x8a8>
ffffffffc02012fc:	00003617          	auipc	a2,0x3
ffffffffc0201300:	65c60613          	addi	a2,a2,1628 # ffffffffc0204958 <commands+0x818>
ffffffffc0201304:	0bb00593          	li	a1,187
ffffffffc0201308:	00003517          	auipc	a0,0x3
ffffffffc020130c:	66850513          	addi	a0,a0,1640 # ffffffffc0204970 <commands+0x830>
ffffffffc0201310:	94aff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(count == 0);
ffffffffc0201314:	00004697          	auipc	a3,0x4
ffffffffc0201318:	97c68693          	addi	a3,a3,-1668 # ffffffffc0204c90 <commands+0xb50>
ffffffffc020131c:	00003617          	auipc	a2,0x3
ffffffffc0201320:	63c60613          	addi	a2,a2,1596 # ffffffffc0204958 <commands+0x818>
ffffffffc0201324:	12500593          	li	a1,293
ffffffffc0201328:	00003517          	auipc	a0,0x3
ffffffffc020132c:	64850513          	addi	a0,a0,1608 # ffffffffc0204970 <commands+0x830>
ffffffffc0201330:	92aff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(nr_free == 0);
ffffffffc0201334:	00003697          	auipc	a3,0x3
ffffffffc0201338:	7fc68693          	addi	a3,a3,2044 # ffffffffc0204b30 <commands+0x9f0>
ffffffffc020133c:	00003617          	auipc	a2,0x3
ffffffffc0201340:	61c60613          	addi	a2,a2,1564 # ffffffffc0204958 <commands+0x818>
ffffffffc0201344:	11a00593          	li	a1,282
ffffffffc0201348:	00003517          	auipc	a0,0x3
ffffffffc020134c:	62850513          	addi	a0,a0,1576 # ffffffffc0204970 <commands+0x830>
ffffffffc0201350:	90aff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201354:	00003697          	auipc	a3,0x3
ffffffffc0201358:	77c68693          	addi	a3,a3,1916 # ffffffffc0204ad0 <commands+0x990>
ffffffffc020135c:	00003617          	auipc	a2,0x3
ffffffffc0201360:	5fc60613          	addi	a2,a2,1532 # ffffffffc0204958 <commands+0x818>
ffffffffc0201364:	11800593          	li	a1,280
ffffffffc0201368:	00003517          	auipc	a0,0x3
ffffffffc020136c:	60850513          	addi	a0,a0,1544 # ffffffffc0204970 <commands+0x830>
ffffffffc0201370:	8eaff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201374:	00003697          	auipc	a3,0x3
ffffffffc0201378:	71c68693          	addi	a3,a3,1820 # ffffffffc0204a90 <commands+0x950>
ffffffffc020137c:	00003617          	auipc	a2,0x3
ffffffffc0201380:	5dc60613          	addi	a2,a2,1500 # ffffffffc0204958 <commands+0x818>
ffffffffc0201384:	0c100593          	li	a1,193
ffffffffc0201388:	00003517          	auipc	a0,0x3
ffffffffc020138c:	5e850513          	addi	a0,a0,1512 # ffffffffc0204970 <commands+0x830>
ffffffffc0201390:	8caff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201394:	00004697          	auipc	a3,0x4
ffffffffc0201398:	8bc68693          	addi	a3,a3,-1860 # ffffffffc0204c50 <commands+0xb10>
ffffffffc020139c:	00003617          	auipc	a2,0x3
ffffffffc02013a0:	5bc60613          	addi	a2,a2,1468 # ffffffffc0204958 <commands+0x818>
ffffffffc02013a4:	11200593          	li	a1,274
ffffffffc02013a8:	00003517          	auipc	a0,0x3
ffffffffc02013ac:	5c850513          	addi	a0,a0,1480 # ffffffffc0204970 <commands+0x830>
ffffffffc02013b0:	8aaff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc02013b4:	00004697          	auipc	a3,0x4
ffffffffc02013b8:	87c68693          	addi	a3,a3,-1924 # ffffffffc0204c30 <commands+0xaf0>
ffffffffc02013bc:	00003617          	auipc	a2,0x3
ffffffffc02013c0:	59c60613          	addi	a2,a2,1436 # ffffffffc0204958 <commands+0x818>
ffffffffc02013c4:	11000593          	li	a1,272
ffffffffc02013c8:	00003517          	auipc	a0,0x3
ffffffffc02013cc:	5a850513          	addi	a0,a0,1448 # ffffffffc0204970 <commands+0x830>
ffffffffc02013d0:	88aff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02013d4:	00004697          	auipc	a3,0x4
ffffffffc02013d8:	83468693          	addi	a3,a3,-1996 # ffffffffc0204c08 <commands+0xac8>
ffffffffc02013dc:	00003617          	auipc	a2,0x3
ffffffffc02013e0:	57c60613          	addi	a2,a2,1404 # ffffffffc0204958 <commands+0x818>
ffffffffc02013e4:	10e00593          	li	a1,270
ffffffffc02013e8:	00003517          	auipc	a0,0x3
ffffffffc02013ec:	58850513          	addi	a0,a0,1416 # ffffffffc0204970 <commands+0x830>
ffffffffc02013f0:	86aff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02013f4:	00003697          	auipc	a3,0x3
ffffffffc02013f8:	7ec68693          	addi	a3,a3,2028 # ffffffffc0204be0 <commands+0xaa0>
ffffffffc02013fc:	00003617          	auipc	a2,0x3
ffffffffc0201400:	55c60613          	addi	a2,a2,1372 # ffffffffc0204958 <commands+0x818>
ffffffffc0201404:	10d00593          	li	a1,269
ffffffffc0201408:	00003517          	auipc	a0,0x3
ffffffffc020140c:	56850513          	addi	a0,a0,1384 # ffffffffc0204970 <commands+0x830>
ffffffffc0201410:	84aff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(p0 + 2 == p1);
ffffffffc0201414:	00003697          	auipc	a3,0x3
ffffffffc0201418:	7bc68693          	addi	a3,a3,1980 # ffffffffc0204bd0 <commands+0xa90>
ffffffffc020141c:	00003617          	auipc	a2,0x3
ffffffffc0201420:	53c60613          	addi	a2,a2,1340 # ffffffffc0204958 <commands+0x818>
ffffffffc0201424:	10800593          	li	a1,264
ffffffffc0201428:	00003517          	auipc	a0,0x3
ffffffffc020142c:	54850513          	addi	a0,a0,1352 # ffffffffc0204970 <commands+0x830>
ffffffffc0201430:	82aff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201434:	00003697          	auipc	a3,0x3
ffffffffc0201438:	69c68693          	addi	a3,a3,1692 # ffffffffc0204ad0 <commands+0x990>
ffffffffc020143c:	00003617          	auipc	a2,0x3
ffffffffc0201440:	51c60613          	addi	a2,a2,1308 # ffffffffc0204958 <commands+0x818>
ffffffffc0201444:	10700593          	li	a1,263
ffffffffc0201448:	00003517          	auipc	a0,0x3
ffffffffc020144c:	52850513          	addi	a0,a0,1320 # ffffffffc0204970 <commands+0x830>
ffffffffc0201450:	80aff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0201454:	00003697          	auipc	a3,0x3
ffffffffc0201458:	75c68693          	addi	a3,a3,1884 # ffffffffc0204bb0 <commands+0xa70>
ffffffffc020145c:	00003617          	auipc	a2,0x3
ffffffffc0201460:	4fc60613          	addi	a2,a2,1276 # ffffffffc0204958 <commands+0x818>
ffffffffc0201464:	10600593          	li	a1,262
ffffffffc0201468:	00003517          	auipc	a0,0x3
ffffffffc020146c:	50850513          	addi	a0,a0,1288 # ffffffffc0204970 <commands+0x830>
ffffffffc0201470:	febfe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201474:	00003697          	auipc	a3,0x3
ffffffffc0201478:	70c68693          	addi	a3,a3,1804 # ffffffffc0204b80 <commands+0xa40>
ffffffffc020147c:	00003617          	auipc	a2,0x3
ffffffffc0201480:	4dc60613          	addi	a2,a2,1244 # ffffffffc0204958 <commands+0x818>
ffffffffc0201484:	10500593          	li	a1,261
ffffffffc0201488:	00003517          	auipc	a0,0x3
ffffffffc020148c:	4e850513          	addi	a0,a0,1256 # ffffffffc0204970 <commands+0x830>
ffffffffc0201490:	fcbfe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0201494:	00003697          	auipc	a3,0x3
ffffffffc0201498:	6d468693          	addi	a3,a3,1748 # ffffffffc0204b68 <commands+0xa28>
ffffffffc020149c:	00003617          	auipc	a2,0x3
ffffffffc02014a0:	4bc60613          	addi	a2,a2,1212 # ffffffffc0204958 <commands+0x818>
ffffffffc02014a4:	10400593          	li	a1,260
ffffffffc02014a8:	00003517          	auipc	a0,0x3
ffffffffc02014ac:	4c850513          	addi	a0,a0,1224 # ffffffffc0204970 <commands+0x830>
ffffffffc02014b0:	fabfe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(alloc_page() == NULL);
ffffffffc02014b4:	00003697          	auipc	a3,0x3
ffffffffc02014b8:	61c68693          	addi	a3,a3,1564 # ffffffffc0204ad0 <commands+0x990>
ffffffffc02014bc:	00003617          	auipc	a2,0x3
ffffffffc02014c0:	49c60613          	addi	a2,a2,1180 # ffffffffc0204958 <commands+0x818>
ffffffffc02014c4:	0fe00593          	li	a1,254
ffffffffc02014c8:	00003517          	auipc	a0,0x3
ffffffffc02014cc:	4a850513          	addi	a0,a0,1192 # ffffffffc0204970 <commands+0x830>
ffffffffc02014d0:	f8bfe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(!PageProperty(p0));
ffffffffc02014d4:	00003697          	auipc	a3,0x3
ffffffffc02014d8:	67c68693          	addi	a3,a3,1660 # ffffffffc0204b50 <commands+0xa10>
ffffffffc02014dc:	00003617          	auipc	a2,0x3
ffffffffc02014e0:	47c60613          	addi	a2,a2,1148 # ffffffffc0204958 <commands+0x818>
ffffffffc02014e4:	0f900593          	li	a1,249
ffffffffc02014e8:	00003517          	auipc	a0,0x3
ffffffffc02014ec:	48850513          	addi	a0,a0,1160 # ffffffffc0204970 <commands+0x830>
ffffffffc02014f0:	f6bfe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02014f4:	00003697          	auipc	a3,0x3
ffffffffc02014f8:	77c68693          	addi	a3,a3,1916 # ffffffffc0204c70 <commands+0xb30>
ffffffffc02014fc:	00003617          	auipc	a2,0x3
ffffffffc0201500:	45c60613          	addi	a2,a2,1116 # ffffffffc0204958 <commands+0x818>
ffffffffc0201504:	11700593          	li	a1,279
ffffffffc0201508:	00003517          	auipc	a0,0x3
ffffffffc020150c:	46850513          	addi	a0,a0,1128 # ffffffffc0204970 <commands+0x830>
ffffffffc0201510:	f4bfe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(total == 0);
ffffffffc0201514:	00003697          	auipc	a3,0x3
ffffffffc0201518:	78c68693          	addi	a3,a3,1932 # ffffffffc0204ca0 <commands+0xb60>
ffffffffc020151c:	00003617          	auipc	a2,0x3
ffffffffc0201520:	43c60613          	addi	a2,a2,1084 # ffffffffc0204958 <commands+0x818>
ffffffffc0201524:	12600593          	li	a1,294
ffffffffc0201528:	00003517          	auipc	a0,0x3
ffffffffc020152c:	44850513          	addi	a0,a0,1096 # ffffffffc0204970 <commands+0x830>
ffffffffc0201530:	f2bfe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(total == nr_free_pages());
ffffffffc0201534:	00003697          	auipc	a3,0x3
ffffffffc0201538:	45468693          	addi	a3,a3,1108 # ffffffffc0204988 <commands+0x848>
ffffffffc020153c:	00003617          	auipc	a2,0x3
ffffffffc0201540:	41c60613          	addi	a2,a2,1052 # ffffffffc0204958 <commands+0x818>
ffffffffc0201544:	0f300593          	li	a1,243
ffffffffc0201548:	00003517          	auipc	a0,0x3
ffffffffc020154c:	42850513          	addi	a0,a0,1064 # ffffffffc0204970 <commands+0x830>
ffffffffc0201550:	f0bfe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201554:	00003697          	auipc	a3,0x3
ffffffffc0201558:	47468693          	addi	a3,a3,1140 # ffffffffc02049c8 <commands+0x888>
ffffffffc020155c:	00003617          	auipc	a2,0x3
ffffffffc0201560:	3fc60613          	addi	a2,a2,1020 # ffffffffc0204958 <commands+0x818>
ffffffffc0201564:	0ba00593          	li	a1,186
ffffffffc0201568:	00003517          	auipc	a0,0x3
ffffffffc020156c:	40850513          	addi	a0,a0,1032 # ffffffffc0204970 <commands+0x830>
ffffffffc0201570:	eebfe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0201574 <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc0201574:	1141                	addi	sp,sp,-16
ffffffffc0201576:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201578:	14058463          	beqz	a1,ffffffffc02016c0 <default_free_pages+0x14c>
    for (; p != base + n; p ++) {
ffffffffc020157c:	00659693          	slli	a3,a1,0x6
ffffffffc0201580:	96aa                	add	a3,a3,a0
ffffffffc0201582:	87aa                	mv	a5,a0
ffffffffc0201584:	02d50263          	beq	a0,a3,ffffffffc02015a8 <default_free_pages+0x34>
ffffffffc0201588:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020158a:	8b05                	andi	a4,a4,1
ffffffffc020158c:	10071a63          	bnez	a4,ffffffffc02016a0 <default_free_pages+0x12c>
ffffffffc0201590:	6798                	ld	a4,8(a5)
ffffffffc0201592:	8b09                	andi	a4,a4,2
ffffffffc0201594:	10071663          	bnez	a4,ffffffffc02016a0 <default_free_pages+0x12c>
        p->flags = 0;
ffffffffc0201598:	0007b423          	sd	zero,8(a5)
}

static inline void
set_page_ref(struct Page *page, int val)
{
    page->ref = val;
ffffffffc020159c:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc02015a0:	04078793          	addi	a5,a5,64
ffffffffc02015a4:	fed792e3          	bne	a5,a3,ffffffffc0201588 <default_free_pages+0x14>
    base->property = n;
ffffffffc02015a8:	2581                	sext.w	a1,a1
ffffffffc02015aa:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc02015ac:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02015b0:	4789                	li	a5,2
ffffffffc02015b2:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc02015b6:	00008697          	auipc	a3,0x8
ffffffffc02015ba:	e7a68693          	addi	a3,a3,-390 # ffffffffc0209430 <free_area>
ffffffffc02015be:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02015c0:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc02015c2:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc02015c6:	9db9                	addw	a1,a1,a4
ffffffffc02015c8:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc02015ca:	0ad78463          	beq	a5,a3,ffffffffc0201672 <default_free_pages+0xfe>
            struct Page* page = le2page(le, page_link);
ffffffffc02015ce:	fe878713          	addi	a4,a5,-24
ffffffffc02015d2:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc02015d6:	4581                	li	a1,0
            if (base < page) {
ffffffffc02015d8:	00e56a63          	bltu	a0,a4,ffffffffc02015ec <default_free_pages+0x78>
    return listelm->next;
ffffffffc02015dc:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc02015de:	04d70c63          	beq	a4,a3,ffffffffc0201636 <default_free_pages+0xc2>
    for (; p != base + n; p ++) {
ffffffffc02015e2:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc02015e4:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc02015e8:	fee57ae3          	bgeu	a0,a4,ffffffffc02015dc <default_free_pages+0x68>
ffffffffc02015ec:	c199                	beqz	a1,ffffffffc02015f2 <default_free_pages+0x7e>
ffffffffc02015ee:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02015f2:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc02015f4:	e390                	sd	a2,0(a5)
ffffffffc02015f6:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02015f8:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02015fa:	ed18                	sd	a4,24(a0)
    if (le != &free_list) {
ffffffffc02015fc:	00d70d63          	beq	a4,a3,ffffffffc0201616 <default_free_pages+0xa2>
        if (p + p->property == base) {
ffffffffc0201600:	ff872583          	lw	a1,-8(a4)
        p = le2page(le, page_link);
ffffffffc0201604:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base) {
ffffffffc0201608:	02059813          	slli	a6,a1,0x20
ffffffffc020160c:	01a85793          	srli	a5,a6,0x1a
ffffffffc0201610:	97b2                	add	a5,a5,a2
ffffffffc0201612:	02f50c63          	beq	a0,a5,ffffffffc020164a <default_free_pages+0xd6>
    return listelm->next;
ffffffffc0201616:	711c                	ld	a5,32(a0)
    if (le != &free_list) {
ffffffffc0201618:	00d78c63          	beq	a5,a3,ffffffffc0201630 <default_free_pages+0xbc>
        if (base + base->property == p) {
ffffffffc020161c:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc020161e:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p) {
ffffffffc0201622:	02061593          	slli	a1,a2,0x20
ffffffffc0201626:	01a5d713          	srli	a4,a1,0x1a
ffffffffc020162a:	972a                	add	a4,a4,a0
ffffffffc020162c:	04e68a63          	beq	a3,a4,ffffffffc0201680 <default_free_pages+0x10c>
}
ffffffffc0201630:	60a2                	ld	ra,8(sp)
ffffffffc0201632:	0141                	addi	sp,sp,16
ffffffffc0201634:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201636:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201638:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc020163a:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc020163c:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc020163e:	02d70763          	beq	a4,a3,ffffffffc020166c <default_free_pages+0xf8>
    prev->next = next->prev = elm;
ffffffffc0201642:	8832                	mv	a6,a2
ffffffffc0201644:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc0201646:	87ba                	mv	a5,a4
ffffffffc0201648:	bf71                	j	ffffffffc02015e4 <default_free_pages+0x70>
            p->property += base->property;
ffffffffc020164a:	491c                	lw	a5,16(a0)
ffffffffc020164c:	9dbd                	addw	a1,a1,a5
ffffffffc020164e:	feb72c23          	sw	a1,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201652:	57f5                	li	a5,-3
ffffffffc0201654:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201658:	01853803          	ld	a6,24(a0)
ffffffffc020165c:	710c                	ld	a1,32(a0)
            base = p;
ffffffffc020165e:	8532                	mv	a0,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0201660:	00b83423          	sd	a1,8(a6)
    return listelm->next;
ffffffffc0201664:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc0201666:	0105b023          	sd	a6,0(a1)
ffffffffc020166a:	b77d                	j	ffffffffc0201618 <default_free_pages+0xa4>
ffffffffc020166c:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list) {
ffffffffc020166e:	873e                	mv	a4,a5
ffffffffc0201670:	bf41                	j	ffffffffc0201600 <default_free_pages+0x8c>
}
ffffffffc0201672:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201674:	e390                	sd	a2,0(a5)
ffffffffc0201676:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201678:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020167a:	ed1c                	sd	a5,24(a0)
ffffffffc020167c:	0141                	addi	sp,sp,16
ffffffffc020167e:	8082                	ret
            base->property += p->property;
ffffffffc0201680:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201684:	ff078693          	addi	a3,a5,-16
ffffffffc0201688:	9e39                	addw	a2,a2,a4
ffffffffc020168a:	c910                	sw	a2,16(a0)
ffffffffc020168c:	5775                	li	a4,-3
ffffffffc020168e:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201692:	6398                	ld	a4,0(a5)
ffffffffc0201694:	679c                	ld	a5,8(a5)
}
ffffffffc0201696:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0201698:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc020169a:	e398                	sd	a4,0(a5)
ffffffffc020169c:	0141                	addi	sp,sp,16
ffffffffc020169e:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02016a0:	00003697          	auipc	a3,0x3
ffffffffc02016a4:	61868693          	addi	a3,a3,1560 # ffffffffc0204cb8 <commands+0xb78>
ffffffffc02016a8:	00003617          	auipc	a2,0x3
ffffffffc02016ac:	2b060613          	addi	a2,a2,688 # ffffffffc0204958 <commands+0x818>
ffffffffc02016b0:	08300593          	li	a1,131
ffffffffc02016b4:	00003517          	auipc	a0,0x3
ffffffffc02016b8:	2bc50513          	addi	a0,a0,700 # ffffffffc0204970 <commands+0x830>
ffffffffc02016bc:	d9ffe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(n > 0);
ffffffffc02016c0:	00003697          	auipc	a3,0x3
ffffffffc02016c4:	5f068693          	addi	a3,a3,1520 # ffffffffc0204cb0 <commands+0xb70>
ffffffffc02016c8:	00003617          	auipc	a2,0x3
ffffffffc02016cc:	29060613          	addi	a2,a2,656 # ffffffffc0204958 <commands+0x818>
ffffffffc02016d0:	08000593          	li	a1,128
ffffffffc02016d4:	00003517          	auipc	a0,0x3
ffffffffc02016d8:	29c50513          	addi	a0,a0,668 # ffffffffc0204970 <commands+0x830>
ffffffffc02016dc:	d7ffe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc02016e0 <default_alloc_pages>:
    assert(n > 0);
ffffffffc02016e0:	c941                	beqz	a0,ffffffffc0201770 <default_alloc_pages+0x90>
    if (n > nr_free) {
ffffffffc02016e2:	00008597          	auipc	a1,0x8
ffffffffc02016e6:	d4e58593          	addi	a1,a1,-690 # ffffffffc0209430 <free_area>
ffffffffc02016ea:	0105a803          	lw	a6,16(a1)
ffffffffc02016ee:	872a                	mv	a4,a0
ffffffffc02016f0:	02081793          	slli	a5,a6,0x20
ffffffffc02016f4:	9381                	srli	a5,a5,0x20
ffffffffc02016f6:	00a7ee63          	bltu	a5,a0,ffffffffc0201712 <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc02016fa:	87ae                	mv	a5,a1
ffffffffc02016fc:	a801                	j	ffffffffc020170c <default_alloc_pages+0x2c>
        if (p->property >= n) {
ffffffffc02016fe:	ff87a683          	lw	a3,-8(a5)
ffffffffc0201702:	02069613          	slli	a2,a3,0x20
ffffffffc0201706:	9201                	srli	a2,a2,0x20
ffffffffc0201708:	00e67763          	bgeu	a2,a4,ffffffffc0201716 <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc020170c:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc020170e:	feb798e3          	bne	a5,a1,ffffffffc02016fe <default_alloc_pages+0x1e>
        return NULL;
ffffffffc0201712:	4501                	li	a0,0
}
ffffffffc0201714:	8082                	ret
    return listelm->prev;
ffffffffc0201716:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc020171a:	0087b303          	ld	t1,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc020171e:	fe878513          	addi	a0,a5,-24
            p->property = page->property - n;
ffffffffc0201722:	00070e1b          	sext.w	t3,a4
    prev->next = next;
ffffffffc0201726:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc020172a:	01133023          	sd	a7,0(t1)
        if (page->property > n) {
ffffffffc020172e:	02c77863          	bgeu	a4,a2,ffffffffc020175e <default_alloc_pages+0x7e>
            struct Page *p = page + n;
ffffffffc0201732:	071a                	slli	a4,a4,0x6
ffffffffc0201734:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc0201736:	41c686bb          	subw	a3,a3,t3
ffffffffc020173a:	cb14                	sw	a3,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020173c:	00870613          	addi	a2,a4,8
ffffffffc0201740:	4689                	li	a3,2
ffffffffc0201742:	40d6302f          	amoor.d	zero,a3,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc0201746:	0088b683          	ld	a3,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc020174a:	01870613          	addi	a2,a4,24
        nr_free -= n;
ffffffffc020174e:	0105a803          	lw	a6,16(a1)
    prev->next = next->prev = elm;
ffffffffc0201752:	e290                	sd	a2,0(a3)
ffffffffc0201754:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc0201758:	f314                	sd	a3,32(a4)
    elm->prev = prev;
ffffffffc020175a:	01173c23          	sd	a7,24(a4)
ffffffffc020175e:	41c8083b          	subw	a6,a6,t3
ffffffffc0201762:	0105a823          	sw	a6,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201766:	5775                	li	a4,-3
ffffffffc0201768:	17c1                	addi	a5,a5,-16
ffffffffc020176a:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc020176e:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc0201770:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0201772:	00003697          	auipc	a3,0x3
ffffffffc0201776:	53e68693          	addi	a3,a3,1342 # ffffffffc0204cb0 <commands+0xb70>
ffffffffc020177a:	00003617          	auipc	a2,0x3
ffffffffc020177e:	1de60613          	addi	a2,a2,478 # ffffffffc0204958 <commands+0x818>
ffffffffc0201782:	06200593          	li	a1,98
ffffffffc0201786:	00003517          	auipc	a0,0x3
ffffffffc020178a:	1ea50513          	addi	a0,a0,490 # ffffffffc0204970 <commands+0x830>
default_alloc_pages(size_t n) {
ffffffffc020178e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201790:	ccbfe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0201794 <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc0201794:	1141                	addi	sp,sp,-16
ffffffffc0201796:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201798:	c5f1                	beqz	a1,ffffffffc0201864 <default_init_memmap+0xd0>
    for (; p != base + n; p ++) {
ffffffffc020179a:	00659693          	slli	a3,a1,0x6
ffffffffc020179e:	96aa                	add	a3,a3,a0
ffffffffc02017a0:	87aa                	mv	a5,a0
ffffffffc02017a2:	00d50f63          	beq	a0,a3,ffffffffc02017c0 <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02017a6:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc02017a8:	8b05                	andi	a4,a4,1
ffffffffc02017aa:	cf49                	beqz	a4,ffffffffc0201844 <default_init_memmap+0xb0>
        p->flags = p->property = 0;
ffffffffc02017ac:	0007a823          	sw	zero,16(a5)
ffffffffc02017b0:	0007b423          	sd	zero,8(a5)
ffffffffc02017b4:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc02017b8:	04078793          	addi	a5,a5,64
ffffffffc02017bc:	fed795e3          	bne	a5,a3,ffffffffc02017a6 <default_init_memmap+0x12>
    base->property = n;
ffffffffc02017c0:	2581                	sext.w	a1,a1
ffffffffc02017c2:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02017c4:	4789                	li	a5,2
ffffffffc02017c6:	00850713          	addi	a4,a0,8
ffffffffc02017ca:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc02017ce:	00008697          	auipc	a3,0x8
ffffffffc02017d2:	c6268693          	addi	a3,a3,-926 # ffffffffc0209430 <free_area>
ffffffffc02017d6:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02017d8:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc02017da:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc02017de:	9db9                	addw	a1,a1,a4
ffffffffc02017e0:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc02017e2:	04d78a63          	beq	a5,a3,ffffffffc0201836 <default_init_memmap+0xa2>
            struct Page* page = le2page(le, page_link);
ffffffffc02017e6:	fe878713          	addi	a4,a5,-24
ffffffffc02017ea:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc02017ee:	4581                	li	a1,0
            if (base < page) {
ffffffffc02017f0:	00e56a63          	bltu	a0,a4,ffffffffc0201804 <default_init_memmap+0x70>
    return listelm->next;
ffffffffc02017f4:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc02017f6:	02d70263          	beq	a4,a3,ffffffffc020181a <default_init_memmap+0x86>
    for (; p != base + n; p ++) {
ffffffffc02017fa:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc02017fc:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0201800:	fee57ae3          	bgeu	a0,a4,ffffffffc02017f4 <default_init_memmap+0x60>
ffffffffc0201804:	c199                	beqz	a1,ffffffffc020180a <default_init_memmap+0x76>
ffffffffc0201806:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc020180a:	6398                	ld	a4,0(a5)
}
ffffffffc020180c:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc020180e:	e390                	sd	a2,0(a5)
ffffffffc0201810:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201812:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201814:	ed18                	sd	a4,24(a0)
ffffffffc0201816:	0141                	addi	sp,sp,16
ffffffffc0201818:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc020181a:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc020181c:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc020181e:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201820:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201822:	00d70663          	beq	a4,a3,ffffffffc020182e <default_init_memmap+0x9a>
    prev->next = next->prev = elm;
ffffffffc0201826:	8832                	mv	a6,a2
ffffffffc0201828:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc020182a:	87ba                	mv	a5,a4
ffffffffc020182c:	bfc1                	j	ffffffffc02017fc <default_init_memmap+0x68>
}
ffffffffc020182e:	60a2                	ld	ra,8(sp)
ffffffffc0201830:	e290                	sd	a2,0(a3)
ffffffffc0201832:	0141                	addi	sp,sp,16
ffffffffc0201834:	8082                	ret
ffffffffc0201836:	60a2                	ld	ra,8(sp)
ffffffffc0201838:	e390                	sd	a2,0(a5)
ffffffffc020183a:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc020183c:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020183e:	ed1c                	sd	a5,24(a0)
ffffffffc0201840:	0141                	addi	sp,sp,16
ffffffffc0201842:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201844:	00003697          	auipc	a3,0x3
ffffffffc0201848:	49c68693          	addi	a3,a3,1180 # ffffffffc0204ce0 <commands+0xba0>
ffffffffc020184c:	00003617          	auipc	a2,0x3
ffffffffc0201850:	10c60613          	addi	a2,a2,268 # ffffffffc0204958 <commands+0x818>
ffffffffc0201854:	04900593          	li	a1,73
ffffffffc0201858:	00003517          	auipc	a0,0x3
ffffffffc020185c:	11850513          	addi	a0,a0,280 # ffffffffc0204970 <commands+0x830>
ffffffffc0201860:	bfbfe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(n > 0);
ffffffffc0201864:	00003697          	auipc	a3,0x3
ffffffffc0201868:	44c68693          	addi	a3,a3,1100 # ffffffffc0204cb0 <commands+0xb70>
ffffffffc020186c:	00003617          	auipc	a2,0x3
ffffffffc0201870:	0ec60613          	addi	a2,a2,236 # ffffffffc0204958 <commands+0x818>
ffffffffc0201874:	04600593          	li	a1,70
ffffffffc0201878:	00003517          	auipc	a0,0x3
ffffffffc020187c:	0f850513          	addi	a0,a0,248 # ffffffffc0204970 <commands+0x830>
ffffffffc0201880:	bdbfe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0201884 <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc0201884:	c94d                	beqz	a0,ffffffffc0201936 <slob_free+0xb2>
{
ffffffffc0201886:	1141                	addi	sp,sp,-16
ffffffffc0201888:	e022                	sd	s0,0(sp)
ffffffffc020188a:	e406                	sd	ra,8(sp)
ffffffffc020188c:	842a                	mv	s0,a0
		return;

	if (size)
ffffffffc020188e:	e9c1                	bnez	a1,ffffffffc020191e <slob_free+0x9a>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201890:	100027f3          	csrr	a5,sstatus
ffffffffc0201894:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201896:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201898:	ebd9                	bnez	a5,ffffffffc020192e <slob_free+0xaa>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc020189a:	00007617          	auipc	a2,0x7
ffffffffc020189e:	78660613          	addi	a2,a2,1926 # ffffffffc0209020 <slobfree>
ffffffffc02018a2:	621c                	ld	a5,0(a2)
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02018a4:	873e                	mv	a4,a5
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc02018a6:	679c                	ld	a5,8(a5)
ffffffffc02018a8:	02877a63          	bgeu	a4,s0,ffffffffc02018dc <slob_free+0x58>
ffffffffc02018ac:	00f46463          	bltu	s0,a5,ffffffffc02018b4 <slob_free+0x30>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02018b0:	fef76ae3          	bltu	a4,a5,ffffffffc02018a4 <slob_free+0x20>
			break;

	if (b + b->units == cur->next)
ffffffffc02018b4:	400c                	lw	a1,0(s0)
ffffffffc02018b6:	00459693          	slli	a3,a1,0x4
ffffffffc02018ba:	96a2                	add	a3,a3,s0
ffffffffc02018bc:	02d78a63          	beq	a5,a3,ffffffffc02018f0 <slob_free+0x6c>
		b->next = cur->next->next;
	}
	else
		b->next = cur->next;

	if (cur + cur->units == b)
ffffffffc02018c0:	4314                	lw	a3,0(a4)
		b->next = cur->next;
ffffffffc02018c2:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc02018c4:	00469793          	slli	a5,a3,0x4
ffffffffc02018c8:	97ba                	add	a5,a5,a4
ffffffffc02018ca:	02f40e63          	beq	s0,a5,ffffffffc0201906 <slob_free+0x82>
	{
		cur->units += b->units;
		cur->next = b->next;
	}
	else
		cur->next = b;
ffffffffc02018ce:	e700                	sd	s0,8(a4)

	slobfree = cur;
ffffffffc02018d0:	e218                	sd	a4,0(a2)
    if (flag) {
ffffffffc02018d2:	e129                	bnez	a0,ffffffffc0201914 <slob_free+0x90>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc02018d4:	60a2                	ld	ra,8(sp)
ffffffffc02018d6:	6402                	ld	s0,0(sp)
ffffffffc02018d8:	0141                	addi	sp,sp,16
ffffffffc02018da:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02018dc:	fcf764e3          	bltu	a4,a5,ffffffffc02018a4 <slob_free+0x20>
ffffffffc02018e0:	fcf472e3          	bgeu	s0,a5,ffffffffc02018a4 <slob_free+0x20>
	if (b + b->units == cur->next)
ffffffffc02018e4:	400c                	lw	a1,0(s0)
ffffffffc02018e6:	00459693          	slli	a3,a1,0x4
ffffffffc02018ea:	96a2                	add	a3,a3,s0
ffffffffc02018ec:	fcd79ae3          	bne	a5,a3,ffffffffc02018c0 <slob_free+0x3c>
		b->units += cur->next->units;
ffffffffc02018f0:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc02018f2:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc02018f4:	9db5                	addw	a1,a1,a3
ffffffffc02018f6:	c00c                	sw	a1,0(s0)
	if (cur + cur->units == b)
ffffffffc02018f8:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc02018fa:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc02018fc:	00469793          	slli	a5,a3,0x4
ffffffffc0201900:	97ba                	add	a5,a5,a4
ffffffffc0201902:	fcf416e3          	bne	s0,a5,ffffffffc02018ce <slob_free+0x4a>
		cur->units += b->units;
ffffffffc0201906:	401c                	lw	a5,0(s0)
		cur->next = b->next;
ffffffffc0201908:	640c                	ld	a1,8(s0)
	slobfree = cur;
ffffffffc020190a:	e218                	sd	a4,0(a2)
		cur->units += b->units;
ffffffffc020190c:	9ebd                	addw	a3,a3,a5
ffffffffc020190e:	c314                	sw	a3,0(a4)
		cur->next = b->next;
ffffffffc0201910:	e70c                	sd	a1,8(a4)
ffffffffc0201912:	d169                	beqz	a0,ffffffffc02018d4 <slob_free+0x50>
}
ffffffffc0201914:	6402                	ld	s0,0(sp)
ffffffffc0201916:	60a2                	ld	ra,8(sp)
ffffffffc0201918:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc020191a:	810ff06f          	j	ffffffffc020092a <intr_enable>
		b->units = SLOB_UNITS(size);
ffffffffc020191e:	25bd                	addiw	a1,a1,15
ffffffffc0201920:	8191                	srli	a1,a1,0x4
ffffffffc0201922:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201924:	100027f3          	csrr	a5,sstatus
ffffffffc0201928:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020192a:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020192c:	d7bd                	beqz	a5,ffffffffc020189a <slob_free+0x16>
        intr_disable();
ffffffffc020192e:	802ff0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        return 1;
ffffffffc0201932:	4505                	li	a0,1
ffffffffc0201934:	b79d                	j	ffffffffc020189a <slob_free+0x16>
ffffffffc0201936:	8082                	ret

ffffffffc0201938 <__slob_get_free_pages.constprop.0>:
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201938:	4785                	li	a5,1
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc020193a:	1141                	addi	sp,sp,-16
	struct Page *page = alloc_pages(1 << order);
ffffffffc020193c:	00a7953b          	sllw	a0,a5,a0
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201940:	e406                	sd	ra,8(sp)
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201942:	34e000ef          	jal	ra,ffffffffc0201c90 <alloc_pages>
	if (!page)
ffffffffc0201946:	c91d                	beqz	a0,ffffffffc020197c <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc0201948:	0000c697          	auipc	a3,0xc
ffffffffc020194c:	b706b683          	ld	a3,-1168(a3) # ffffffffc020d4b8 <pages>
ffffffffc0201950:	8d15                	sub	a0,a0,a3
ffffffffc0201952:	8519                	srai	a0,a0,0x6
ffffffffc0201954:	00004697          	auipc	a3,0x4
ffffffffc0201958:	10c6b683          	ld	a3,268(a3) # ffffffffc0205a60 <nbase>
ffffffffc020195c:	9536                	add	a0,a0,a3
    return KADDR(page2pa(page));
ffffffffc020195e:	00c51793          	slli	a5,a0,0xc
ffffffffc0201962:	83b1                	srli	a5,a5,0xc
ffffffffc0201964:	0000c717          	auipc	a4,0xc
ffffffffc0201968:	b4c73703          	ld	a4,-1204(a4) # ffffffffc020d4b0 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc020196c:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc020196e:	00e7fa63          	bgeu	a5,a4,ffffffffc0201982 <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc0201972:	0000c697          	auipc	a3,0xc
ffffffffc0201976:	b566b683          	ld	a3,-1194(a3) # ffffffffc020d4c8 <va_pa_offset>
ffffffffc020197a:	9536                	add	a0,a0,a3
}
ffffffffc020197c:	60a2                	ld	ra,8(sp)
ffffffffc020197e:	0141                	addi	sp,sp,16
ffffffffc0201980:	8082                	ret
ffffffffc0201982:	86aa                	mv	a3,a0
ffffffffc0201984:	00003617          	auipc	a2,0x3
ffffffffc0201988:	3bc60613          	addi	a2,a2,956 # ffffffffc0204d40 <default_pmm_manager+0x38>
ffffffffc020198c:	07100593          	li	a1,113
ffffffffc0201990:	00003517          	auipc	a0,0x3
ffffffffc0201994:	3d850513          	addi	a0,a0,984 # ffffffffc0204d68 <default_pmm_manager+0x60>
ffffffffc0201998:	ac3fe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc020199c <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc020199c:	1101                	addi	sp,sp,-32
ffffffffc020199e:	ec06                	sd	ra,24(sp)
ffffffffc02019a0:	e822                	sd	s0,16(sp)
ffffffffc02019a2:	e426                	sd	s1,8(sp)
ffffffffc02019a4:	e04a                	sd	s2,0(sp)
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc02019a6:	01050713          	addi	a4,a0,16
ffffffffc02019aa:	6785                	lui	a5,0x1
ffffffffc02019ac:	0cf77363          	bgeu	a4,a5,ffffffffc0201a72 <slob_alloc.constprop.0+0xd6>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc02019b0:	00f50493          	addi	s1,a0,15
ffffffffc02019b4:	8091                	srli	s1,s1,0x4
ffffffffc02019b6:	2481                	sext.w	s1,s1
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02019b8:	10002673          	csrr	a2,sstatus
ffffffffc02019bc:	8a09                	andi	a2,a2,2
ffffffffc02019be:	e25d                	bnez	a2,ffffffffc0201a64 <slob_alloc.constprop.0+0xc8>
	prev = slobfree;
ffffffffc02019c0:	00007917          	auipc	s2,0x7
ffffffffc02019c4:	66090913          	addi	s2,s2,1632 # ffffffffc0209020 <slobfree>
ffffffffc02019c8:	00093683          	ld	a3,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc02019cc:	669c                	ld	a5,8(a3)
		if (cur->units >= units + delta)
ffffffffc02019ce:	4398                	lw	a4,0(a5)
ffffffffc02019d0:	08975e63          	bge	a4,s1,ffffffffc0201a6c <slob_alloc.constprop.0+0xd0>
		if (cur == slobfree)
ffffffffc02019d4:	00d78b63          	beq	a5,a3,ffffffffc02019ea <slob_alloc.constprop.0+0x4e>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc02019d8:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc02019da:	4018                	lw	a4,0(s0)
ffffffffc02019dc:	02975a63          	bge	a4,s1,ffffffffc0201a10 <slob_alloc.constprop.0+0x74>
		if (cur == slobfree)
ffffffffc02019e0:	00093683          	ld	a3,0(s2)
ffffffffc02019e4:	87a2                	mv	a5,s0
ffffffffc02019e6:	fed799e3          	bne	a5,a3,ffffffffc02019d8 <slob_alloc.constprop.0+0x3c>
    if (flag) {
ffffffffc02019ea:	ee31                	bnez	a2,ffffffffc0201a46 <slob_alloc.constprop.0+0xaa>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc02019ec:	4501                	li	a0,0
ffffffffc02019ee:	f4bff0ef          	jal	ra,ffffffffc0201938 <__slob_get_free_pages.constprop.0>
ffffffffc02019f2:	842a                	mv	s0,a0
			if (!cur)
ffffffffc02019f4:	cd05                	beqz	a0,ffffffffc0201a2c <slob_alloc.constprop.0+0x90>
			slob_free(cur, PAGE_SIZE);
ffffffffc02019f6:	6585                	lui	a1,0x1
ffffffffc02019f8:	e8dff0ef          	jal	ra,ffffffffc0201884 <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02019fc:	10002673          	csrr	a2,sstatus
ffffffffc0201a00:	8a09                	andi	a2,a2,2
ffffffffc0201a02:	ee05                	bnez	a2,ffffffffc0201a3a <slob_alloc.constprop.0+0x9e>
			cur = slobfree;
ffffffffc0201a04:	00093783          	ld	a5,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201a08:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0201a0a:	4018                	lw	a4,0(s0)
ffffffffc0201a0c:	fc974ae3          	blt	a4,s1,ffffffffc02019e0 <slob_alloc.constprop.0+0x44>
			if (cur->units == units)	/* exact fit? */
ffffffffc0201a10:	04e48763          	beq	s1,a4,ffffffffc0201a5e <slob_alloc.constprop.0+0xc2>
				prev->next = cur + units;
ffffffffc0201a14:	00449693          	slli	a3,s1,0x4
ffffffffc0201a18:	96a2                	add	a3,a3,s0
ffffffffc0201a1a:	e794                	sd	a3,8(a5)
				prev->next->next = cur->next;
ffffffffc0201a1c:	640c                	ld	a1,8(s0)
				prev->next->units = cur->units - units;
ffffffffc0201a1e:	9f05                	subw	a4,a4,s1
ffffffffc0201a20:	c298                	sw	a4,0(a3)
				prev->next->next = cur->next;
ffffffffc0201a22:	e68c                	sd	a1,8(a3)
				cur->units = units;
ffffffffc0201a24:	c004                	sw	s1,0(s0)
			slobfree = prev;
ffffffffc0201a26:	00f93023          	sd	a5,0(s2)
    if (flag) {
ffffffffc0201a2a:	e20d                	bnez	a2,ffffffffc0201a4c <slob_alloc.constprop.0+0xb0>
}
ffffffffc0201a2c:	60e2                	ld	ra,24(sp)
ffffffffc0201a2e:	8522                	mv	a0,s0
ffffffffc0201a30:	6442                	ld	s0,16(sp)
ffffffffc0201a32:	64a2                	ld	s1,8(sp)
ffffffffc0201a34:	6902                	ld	s2,0(sp)
ffffffffc0201a36:	6105                	addi	sp,sp,32
ffffffffc0201a38:	8082                	ret
        intr_disable();
ffffffffc0201a3a:	ef7fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
			cur = slobfree;
ffffffffc0201a3e:	00093783          	ld	a5,0(s2)
        return 1;
ffffffffc0201a42:	4605                	li	a2,1
ffffffffc0201a44:	b7d1                	j	ffffffffc0201a08 <slob_alloc.constprop.0+0x6c>
        intr_enable();
ffffffffc0201a46:	ee5fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0201a4a:	b74d                	j	ffffffffc02019ec <slob_alloc.constprop.0+0x50>
ffffffffc0201a4c:	edffe0ef          	jal	ra,ffffffffc020092a <intr_enable>
}
ffffffffc0201a50:	60e2                	ld	ra,24(sp)
ffffffffc0201a52:	8522                	mv	a0,s0
ffffffffc0201a54:	6442                	ld	s0,16(sp)
ffffffffc0201a56:	64a2                	ld	s1,8(sp)
ffffffffc0201a58:	6902                	ld	s2,0(sp)
ffffffffc0201a5a:	6105                	addi	sp,sp,32
ffffffffc0201a5c:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc0201a5e:	6418                	ld	a4,8(s0)
ffffffffc0201a60:	e798                	sd	a4,8(a5)
ffffffffc0201a62:	b7d1                	j	ffffffffc0201a26 <slob_alloc.constprop.0+0x8a>
        intr_disable();
ffffffffc0201a64:	ecdfe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        return 1;
ffffffffc0201a68:	4605                	li	a2,1
ffffffffc0201a6a:	bf99                	j	ffffffffc02019c0 <slob_alloc.constprop.0+0x24>
		if (cur->units >= units + delta)
ffffffffc0201a6c:	843e                	mv	s0,a5
ffffffffc0201a6e:	87b6                	mv	a5,a3
ffffffffc0201a70:	b745                	j	ffffffffc0201a10 <slob_alloc.constprop.0+0x74>
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201a72:	00003697          	auipc	a3,0x3
ffffffffc0201a76:	30668693          	addi	a3,a3,774 # ffffffffc0204d78 <default_pmm_manager+0x70>
ffffffffc0201a7a:	00003617          	auipc	a2,0x3
ffffffffc0201a7e:	ede60613          	addi	a2,a2,-290 # ffffffffc0204958 <commands+0x818>
ffffffffc0201a82:	06300593          	li	a1,99
ffffffffc0201a86:	00003517          	auipc	a0,0x3
ffffffffc0201a8a:	31250513          	addi	a0,a0,786 # ffffffffc0204d98 <default_pmm_manager+0x90>
ffffffffc0201a8e:	9cdfe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0201a92 <kmalloc_init>:
	cprintf("use SLOB allocator\n");
}

inline void
kmalloc_init(void)
{
ffffffffc0201a92:	1141                	addi	sp,sp,-16
	cprintf("use SLOB allocator\n");
ffffffffc0201a94:	00003517          	auipc	a0,0x3
ffffffffc0201a98:	31c50513          	addi	a0,a0,796 # ffffffffc0204db0 <default_pmm_manager+0xa8>
{
ffffffffc0201a9c:	e406                	sd	ra,8(sp)
	cprintf("use SLOB allocator\n");
ffffffffc0201a9e:	ef6fe0ef          	jal	ra,ffffffffc0200194 <cprintf>
	slob_init();
	cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201aa2:	60a2                	ld	ra,8(sp)
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201aa4:	00003517          	auipc	a0,0x3
ffffffffc0201aa8:	32450513          	addi	a0,a0,804 # ffffffffc0204dc8 <default_pmm_manager+0xc0>
}
ffffffffc0201aac:	0141                	addi	sp,sp,16
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201aae:	ee6fe06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0201ab2 <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201ab2:	1101                	addi	sp,sp,-32
ffffffffc0201ab4:	e04a                	sd	s2,0(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201ab6:	6905                	lui	s2,0x1
{
ffffffffc0201ab8:	e822                	sd	s0,16(sp)
ffffffffc0201aba:	ec06                	sd	ra,24(sp)
ffffffffc0201abc:	e426                	sd	s1,8(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201abe:	fef90793          	addi	a5,s2,-17 # fef <kern_entry-0xffffffffc01ff011>
{
ffffffffc0201ac2:	842a                	mv	s0,a0
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201ac4:	04a7f963          	bgeu	a5,a0,ffffffffc0201b16 <kmalloc+0x64>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0201ac8:	4561                	li	a0,24
ffffffffc0201aca:	ed3ff0ef          	jal	ra,ffffffffc020199c <slob_alloc.constprop.0>
ffffffffc0201ace:	84aa                	mv	s1,a0
	if (!bb)
ffffffffc0201ad0:	c929                	beqz	a0,ffffffffc0201b22 <kmalloc+0x70>
	bb->order = find_order(size);
ffffffffc0201ad2:	0004079b          	sext.w	a5,s0
	int order = 0;
ffffffffc0201ad6:	4501                	li	a0,0
	for (; size > 4096; size >>= 1)
ffffffffc0201ad8:	00f95763          	bge	s2,a5,ffffffffc0201ae6 <kmalloc+0x34>
ffffffffc0201adc:	6705                	lui	a4,0x1
ffffffffc0201ade:	8785                	srai	a5,a5,0x1
		order++;
ffffffffc0201ae0:	2505                	addiw	a0,a0,1
	for (; size > 4096; size >>= 1)
ffffffffc0201ae2:	fef74ee3          	blt	a4,a5,ffffffffc0201ade <kmalloc+0x2c>
	bb->order = find_order(size);
ffffffffc0201ae6:	c088                	sw	a0,0(s1)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0201ae8:	e51ff0ef          	jal	ra,ffffffffc0201938 <__slob_get_free_pages.constprop.0>
ffffffffc0201aec:	e488                	sd	a0,8(s1)
ffffffffc0201aee:	842a                	mv	s0,a0
	if (bb->pages)
ffffffffc0201af0:	c525                	beqz	a0,ffffffffc0201b58 <kmalloc+0xa6>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201af2:	100027f3          	csrr	a5,sstatus
ffffffffc0201af6:	8b89                	andi	a5,a5,2
ffffffffc0201af8:	ef8d                	bnez	a5,ffffffffc0201b32 <kmalloc+0x80>
		bb->next = bigblocks;
ffffffffc0201afa:	0000c797          	auipc	a5,0xc
ffffffffc0201afe:	99e78793          	addi	a5,a5,-1634 # ffffffffc020d498 <bigblocks>
ffffffffc0201b02:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201b04:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201b06:	e898                	sd	a4,16(s1)
	return __kmalloc(size, 0);
}
ffffffffc0201b08:	60e2                	ld	ra,24(sp)
ffffffffc0201b0a:	8522                	mv	a0,s0
ffffffffc0201b0c:	6442                	ld	s0,16(sp)
ffffffffc0201b0e:	64a2                	ld	s1,8(sp)
ffffffffc0201b10:	6902                	ld	s2,0(sp)
ffffffffc0201b12:	6105                	addi	sp,sp,32
ffffffffc0201b14:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201b16:	0541                	addi	a0,a0,16
ffffffffc0201b18:	e85ff0ef          	jal	ra,ffffffffc020199c <slob_alloc.constprop.0>
		return m ? (void *)(m + 1) : 0;
ffffffffc0201b1c:	01050413          	addi	s0,a0,16
ffffffffc0201b20:	f565                	bnez	a0,ffffffffc0201b08 <kmalloc+0x56>
ffffffffc0201b22:	4401                	li	s0,0
}
ffffffffc0201b24:	60e2                	ld	ra,24(sp)
ffffffffc0201b26:	8522                	mv	a0,s0
ffffffffc0201b28:	6442                	ld	s0,16(sp)
ffffffffc0201b2a:	64a2                	ld	s1,8(sp)
ffffffffc0201b2c:	6902                	ld	s2,0(sp)
ffffffffc0201b2e:	6105                	addi	sp,sp,32
ffffffffc0201b30:	8082                	ret
        intr_disable();
ffffffffc0201b32:	dfffe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
		bb->next = bigblocks;
ffffffffc0201b36:	0000c797          	auipc	a5,0xc
ffffffffc0201b3a:	96278793          	addi	a5,a5,-1694 # ffffffffc020d498 <bigblocks>
ffffffffc0201b3e:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201b40:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201b42:	e898                	sd	a4,16(s1)
        intr_enable();
ffffffffc0201b44:	de7fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
		return bb->pages;
ffffffffc0201b48:	6480                	ld	s0,8(s1)
}
ffffffffc0201b4a:	60e2                	ld	ra,24(sp)
ffffffffc0201b4c:	64a2                	ld	s1,8(sp)
ffffffffc0201b4e:	8522                	mv	a0,s0
ffffffffc0201b50:	6442                	ld	s0,16(sp)
ffffffffc0201b52:	6902                	ld	s2,0(sp)
ffffffffc0201b54:	6105                	addi	sp,sp,32
ffffffffc0201b56:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201b58:	45e1                	li	a1,24
ffffffffc0201b5a:	8526                	mv	a0,s1
ffffffffc0201b5c:	d29ff0ef          	jal	ra,ffffffffc0201884 <slob_free>
	return __kmalloc(size, 0);
ffffffffc0201b60:	b765                	j	ffffffffc0201b08 <kmalloc+0x56>

ffffffffc0201b62 <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0201b62:	c169                	beqz	a0,ffffffffc0201c24 <kfree+0xc2>
{
ffffffffc0201b64:	1101                	addi	sp,sp,-32
ffffffffc0201b66:	e822                	sd	s0,16(sp)
ffffffffc0201b68:	ec06                	sd	ra,24(sp)
ffffffffc0201b6a:	e426                	sd	s1,8(sp)
		return;

	if (!((unsigned long)block & (PAGE_SIZE - 1)))
ffffffffc0201b6c:	03451793          	slli	a5,a0,0x34
ffffffffc0201b70:	842a                	mv	s0,a0
ffffffffc0201b72:	e3d9                	bnez	a5,ffffffffc0201bf8 <kfree+0x96>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201b74:	100027f3          	csrr	a5,sstatus
ffffffffc0201b78:	8b89                	andi	a5,a5,2
ffffffffc0201b7a:	e7d9                	bnez	a5,ffffffffc0201c08 <kfree+0xa6>
	{
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201b7c:	0000c797          	auipc	a5,0xc
ffffffffc0201b80:	91c7b783          	ld	a5,-1764(a5) # ffffffffc020d498 <bigblocks>
    return 0;
ffffffffc0201b84:	4601                	li	a2,0
ffffffffc0201b86:	cbad                	beqz	a5,ffffffffc0201bf8 <kfree+0x96>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc0201b88:	0000c697          	auipc	a3,0xc
ffffffffc0201b8c:	91068693          	addi	a3,a3,-1776 # ffffffffc020d498 <bigblocks>
ffffffffc0201b90:	a021                	j	ffffffffc0201b98 <kfree+0x36>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201b92:	01048693          	addi	a3,s1,16
ffffffffc0201b96:	c3a5                	beqz	a5,ffffffffc0201bf6 <kfree+0x94>
		{
			if (bb->pages == block)
ffffffffc0201b98:	6798                	ld	a4,8(a5)
ffffffffc0201b9a:	84be                	mv	s1,a5
			{
				*last = bb->next;
ffffffffc0201b9c:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block)
ffffffffc0201b9e:	fe871ae3          	bne	a4,s0,ffffffffc0201b92 <kfree+0x30>
				*last = bb->next;
ffffffffc0201ba2:	e29c                	sd	a5,0(a3)
    if (flag) {
ffffffffc0201ba4:	ee2d                	bnez	a2,ffffffffc0201c1e <kfree+0xbc>
    return pa2page(PADDR(kva));
ffffffffc0201ba6:	c02007b7          	lui	a5,0xc0200
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
ffffffffc0201baa:	4098                	lw	a4,0(s1)
ffffffffc0201bac:	08f46963          	bltu	s0,a5,ffffffffc0201c3e <kfree+0xdc>
ffffffffc0201bb0:	0000c697          	auipc	a3,0xc
ffffffffc0201bb4:	9186b683          	ld	a3,-1768(a3) # ffffffffc020d4c8 <va_pa_offset>
ffffffffc0201bb8:	8c15                	sub	s0,s0,a3
    if (PPN(pa) >= npage)
ffffffffc0201bba:	8031                	srli	s0,s0,0xc
ffffffffc0201bbc:	0000c797          	auipc	a5,0xc
ffffffffc0201bc0:	8f47b783          	ld	a5,-1804(a5) # ffffffffc020d4b0 <npage>
ffffffffc0201bc4:	06f47163          	bgeu	s0,a5,ffffffffc0201c26 <kfree+0xc4>
    return &pages[PPN(pa) - nbase];
ffffffffc0201bc8:	00004517          	auipc	a0,0x4
ffffffffc0201bcc:	e9853503          	ld	a0,-360(a0) # ffffffffc0205a60 <nbase>
ffffffffc0201bd0:	8c09                	sub	s0,s0,a0
ffffffffc0201bd2:	041a                	slli	s0,s0,0x6
	free_pages(kva2page(kva), 1 << order);
ffffffffc0201bd4:	0000c517          	auipc	a0,0xc
ffffffffc0201bd8:	8e453503          	ld	a0,-1820(a0) # ffffffffc020d4b8 <pages>
ffffffffc0201bdc:	4585                	li	a1,1
ffffffffc0201bde:	9522                	add	a0,a0,s0
ffffffffc0201be0:	00e595bb          	sllw	a1,a1,a4
ffffffffc0201be4:	0ea000ef          	jal	ra,ffffffffc0201cce <free_pages>
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0201be8:	6442                	ld	s0,16(sp)
ffffffffc0201bea:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201bec:	8526                	mv	a0,s1
}
ffffffffc0201bee:	64a2                	ld	s1,8(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201bf0:	45e1                	li	a1,24
}
ffffffffc0201bf2:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201bf4:	b941                	j	ffffffffc0201884 <slob_free>
ffffffffc0201bf6:	e20d                	bnez	a2,ffffffffc0201c18 <kfree+0xb6>
ffffffffc0201bf8:	ff040513          	addi	a0,s0,-16
}
ffffffffc0201bfc:	6442                	ld	s0,16(sp)
ffffffffc0201bfe:	60e2                	ld	ra,24(sp)
ffffffffc0201c00:	64a2                	ld	s1,8(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201c02:	4581                	li	a1,0
}
ffffffffc0201c04:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201c06:	b9bd                	j	ffffffffc0201884 <slob_free>
        intr_disable();
ffffffffc0201c08:	d29fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201c0c:	0000c797          	auipc	a5,0xc
ffffffffc0201c10:	88c7b783          	ld	a5,-1908(a5) # ffffffffc020d498 <bigblocks>
        return 1;
ffffffffc0201c14:	4605                	li	a2,1
ffffffffc0201c16:	fbad                	bnez	a5,ffffffffc0201b88 <kfree+0x26>
        intr_enable();
ffffffffc0201c18:	d13fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0201c1c:	bff1                	j	ffffffffc0201bf8 <kfree+0x96>
ffffffffc0201c1e:	d0dfe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0201c22:	b751                	j	ffffffffc0201ba6 <kfree+0x44>
ffffffffc0201c24:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0201c26:	00003617          	auipc	a2,0x3
ffffffffc0201c2a:	1ea60613          	addi	a2,a2,490 # ffffffffc0204e10 <default_pmm_manager+0x108>
ffffffffc0201c2e:	06900593          	li	a1,105
ffffffffc0201c32:	00003517          	auipc	a0,0x3
ffffffffc0201c36:	13650513          	addi	a0,a0,310 # ffffffffc0204d68 <default_pmm_manager+0x60>
ffffffffc0201c3a:	821fe0ef          	jal	ra,ffffffffc020045a <__panic>
    return pa2page(PADDR(kva));
ffffffffc0201c3e:	86a2                	mv	a3,s0
ffffffffc0201c40:	00003617          	auipc	a2,0x3
ffffffffc0201c44:	1a860613          	addi	a2,a2,424 # ffffffffc0204de8 <default_pmm_manager+0xe0>
ffffffffc0201c48:	07700593          	li	a1,119
ffffffffc0201c4c:	00003517          	auipc	a0,0x3
ffffffffc0201c50:	11c50513          	addi	a0,a0,284 # ffffffffc0204d68 <default_pmm_manager+0x60>
ffffffffc0201c54:	807fe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0201c58 <pa2page.part.0>:
pa2page(uintptr_t pa)
ffffffffc0201c58:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201c5a:	00003617          	auipc	a2,0x3
ffffffffc0201c5e:	1b660613          	addi	a2,a2,438 # ffffffffc0204e10 <default_pmm_manager+0x108>
ffffffffc0201c62:	06900593          	li	a1,105
ffffffffc0201c66:	00003517          	auipc	a0,0x3
ffffffffc0201c6a:	10250513          	addi	a0,a0,258 # ffffffffc0204d68 <default_pmm_manager+0x60>
pa2page(uintptr_t pa)
ffffffffc0201c6e:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0201c70:	feafe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0201c74 <pte2page.part.0>:
pte2page(pte_t pte)
ffffffffc0201c74:	1141                	addi	sp,sp,-16
        panic("pte2page called with invalid pte");
ffffffffc0201c76:	00003617          	auipc	a2,0x3
ffffffffc0201c7a:	1ba60613          	addi	a2,a2,442 # ffffffffc0204e30 <default_pmm_manager+0x128>
ffffffffc0201c7e:	07f00593          	li	a1,127
ffffffffc0201c82:	00003517          	auipc	a0,0x3
ffffffffc0201c86:	0e650513          	addi	a0,a0,230 # ffffffffc0204d68 <default_pmm_manager+0x60>
pte2page(pte_t pte)
ffffffffc0201c8a:	e406                	sd	ra,8(sp)
        panic("pte2page called with invalid pte");
ffffffffc0201c8c:	fcefe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0201c90 <alloc_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201c90:	100027f3          	csrr	a5,sstatus
ffffffffc0201c94:	8b89                	andi	a5,a5,2
ffffffffc0201c96:	e799                	bnez	a5,ffffffffc0201ca4 <alloc_pages+0x14>
{
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0201c98:	0000c797          	auipc	a5,0xc
ffffffffc0201c9c:	8287b783          	ld	a5,-2008(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201ca0:	6f9c                	ld	a5,24(a5)
ffffffffc0201ca2:	8782                	jr	a5
{
ffffffffc0201ca4:	1141                	addi	sp,sp,-16
ffffffffc0201ca6:	e406                	sd	ra,8(sp)
ffffffffc0201ca8:	e022                	sd	s0,0(sp)
ffffffffc0201caa:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0201cac:	c85fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201cb0:	0000c797          	auipc	a5,0xc
ffffffffc0201cb4:	8107b783          	ld	a5,-2032(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201cb8:	6f9c                	ld	a5,24(a5)
ffffffffc0201cba:	8522                	mv	a0,s0
ffffffffc0201cbc:	9782                	jalr	a5
ffffffffc0201cbe:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201cc0:	c6bfe0ef          	jal	ra,ffffffffc020092a <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0201cc4:	60a2                	ld	ra,8(sp)
ffffffffc0201cc6:	8522                	mv	a0,s0
ffffffffc0201cc8:	6402                	ld	s0,0(sp)
ffffffffc0201cca:	0141                	addi	sp,sp,16
ffffffffc0201ccc:	8082                	ret

ffffffffc0201cce <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201cce:	100027f3          	csrr	a5,sstatus
ffffffffc0201cd2:	8b89                	andi	a5,a5,2
ffffffffc0201cd4:	e799                	bnez	a5,ffffffffc0201ce2 <free_pages+0x14>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201cd6:	0000b797          	auipc	a5,0xb
ffffffffc0201cda:	7ea7b783          	ld	a5,2026(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201cde:	739c                	ld	a5,32(a5)
ffffffffc0201ce0:	8782                	jr	a5
{
ffffffffc0201ce2:	1101                	addi	sp,sp,-32
ffffffffc0201ce4:	ec06                	sd	ra,24(sp)
ffffffffc0201ce6:	e822                	sd	s0,16(sp)
ffffffffc0201ce8:	e426                	sd	s1,8(sp)
ffffffffc0201cea:	842a                	mv	s0,a0
ffffffffc0201cec:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0201cee:	c43fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201cf2:	0000b797          	auipc	a5,0xb
ffffffffc0201cf6:	7ce7b783          	ld	a5,1998(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201cfa:	739c                	ld	a5,32(a5)
ffffffffc0201cfc:	85a6                	mv	a1,s1
ffffffffc0201cfe:	8522                	mv	a0,s0
ffffffffc0201d00:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201d02:	6442                	ld	s0,16(sp)
ffffffffc0201d04:	60e2                	ld	ra,24(sp)
ffffffffc0201d06:	64a2                	ld	s1,8(sp)
ffffffffc0201d08:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201d0a:	c21fe06f          	j	ffffffffc020092a <intr_enable>

ffffffffc0201d0e <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201d0e:	100027f3          	csrr	a5,sstatus
ffffffffc0201d12:	8b89                	andi	a5,a5,2
ffffffffc0201d14:	e799                	bnez	a5,ffffffffc0201d22 <nr_free_pages+0x14>
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201d16:	0000b797          	auipc	a5,0xb
ffffffffc0201d1a:	7aa7b783          	ld	a5,1962(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201d1e:	779c                	ld	a5,40(a5)
ffffffffc0201d20:	8782                	jr	a5
{
ffffffffc0201d22:	1141                	addi	sp,sp,-16
ffffffffc0201d24:	e406                	sd	ra,8(sp)
ffffffffc0201d26:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0201d28:	c09fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201d2c:	0000b797          	auipc	a5,0xb
ffffffffc0201d30:	7947b783          	ld	a5,1940(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201d34:	779c                	ld	a5,40(a5)
ffffffffc0201d36:	9782                	jalr	a5
ffffffffc0201d38:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201d3a:	bf1fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201d3e:	60a2                	ld	ra,8(sp)
ffffffffc0201d40:	8522                	mv	a0,s0
ffffffffc0201d42:	6402                	ld	s0,0(sp)
ffffffffc0201d44:	0141                	addi	sp,sp,16
ffffffffc0201d46:	8082                	ret

ffffffffc0201d48 <get_pte>:
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) //在页目录 pgdir 中查找虚拟地址 la 对应的 PTE 最终页表项，如果 create=true 并且缺页，则自动分配表页
{
    pde_t *pdep1 = &pgdir[PDX1(la)]; //从虚拟地址 la 中取出一级页目录索引
ffffffffc0201d48:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0201d4c:	1ff7f793          	andi	a5,a5,511
{
ffffffffc0201d50:	7139                	addi	sp,sp,-64
    pde_t *pdep1 = &pgdir[PDX1(la)]; //从虚拟地址 la 中取出一级页目录索引
ffffffffc0201d52:	078e                	slli	a5,a5,0x3
{
ffffffffc0201d54:	f426                	sd	s1,40(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)]; //从虚拟地址 la 中取出一级页目录索引
ffffffffc0201d56:	00f504b3          	add	s1,a0,a5
    if (!(*pdep1 & PTE_V)) //PTE_V有效标志位
ffffffffc0201d5a:	6094                	ld	a3,0(s1)
{
ffffffffc0201d5c:	f04a                	sd	s2,32(sp)
ffffffffc0201d5e:	ec4e                	sd	s3,24(sp)
ffffffffc0201d60:	e852                	sd	s4,16(sp)
ffffffffc0201d62:	fc06                	sd	ra,56(sp)
ffffffffc0201d64:	f822                	sd	s0,48(sp)
ffffffffc0201d66:	e456                	sd	s5,8(sp)
ffffffffc0201d68:	e05a                	sd	s6,0(sp)
    if (!(*pdep1 & PTE_V)) //PTE_V有效标志位
ffffffffc0201d6a:	0016f793          	andi	a5,a3,1
{
ffffffffc0201d6e:	892e                	mv	s2,a1
ffffffffc0201d70:	8a32                	mv	s4,a2
ffffffffc0201d72:	0000b997          	auipc	s3,0xb
ffffffffc0201d76:	73e98993          	addi	s3,s3,1854 # ffffffffc020d4b0 <npage>
    if (!(*pdep1 & PTE_V)) //PTE_V有效标志位
ffffffffc0201d7a:	efbd                	bnez	a5,ffffffffc0201df8 <get_pte+0xb0>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201d7c:	14060c63          	beqz	a2,ffffffffc0201ed4 <get_pte+0x18c>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201d80:	100027f3          	csrr	a5,sstatus
ffffffffc0201d84:	8b89                	andi	a5,a5,2
ffffffffc0201d86:	14079963          	bnez	a5,ffffffffc0201ed8 <get_pte+0x190>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201d8a:	0000b797          	auipc	a5,0xb
ffffffffc0201d8e:	7367b783          	ld	a5,1846(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201d92:	6f9c                	ld	a5,24(a5)
ffffffffc0201d94:	4505                	li	a0,1
ffffffffc0201d96:	9782                	jalr	a5
ffffffffc0201d98:	842a                	mv	s0,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201d9a:	12040d63          	beqz	s0,ffffffffc0201ed4 <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc0201d9e:	0000bb17          	auipc	s6,0xb
ffffffffc0201da2:	71ab0b13          	addi	s6,s6,1818 # ffffffffc020d4b8 <pages>
ffffffffc0201da6:	000b3503          	ld	a0,0(s6)
ffffffffc0201daa:	00080ab7          	lui	s5,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1); //页表页属于内核管理，引用计数设为 1。
        uintptr_t pa = page2pa(page); //把 page 转换成物理地址
        memset(KADDR(pa), 0, PGSIZE); //把物理地址 pa 转为“内核虚拟地址”，并把新页表清空
ffffffffc0201dae:	0000b997          	auipc	s3,0xb
ffffffffc0201db2:	70298993          	addi	s3,s3,1794 # ffffffffc020d4b0 <npage>
ffffffffc0201db6:	40a40533          	sub	a0,s0,a0
ffffffffc0201dba:	8519                	srai	a0,a0,0x6
ffffffffc0201dbc:	9556                	add	a0,a0,s5
ffffffffc0201dbe:	0009b703          	ld	a4,0(s3)
ffffffffc0201dc2:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0201dc6:	4685                	li	a3,1
ffffffffc0201dc8:	c014                	sw	a3,0(s0)
ffffffffc0201dca:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201dcc:	0532                	slli	a0,a0,0xc
ffffffffc0201dce:	16e7f763          	bgeu	a5,a4,ffffffffc0201f3c <get_pte+0x1f4>
ffffffffc0201dd2:	0000b797          	auipc	a5,0xb
ffffffffc0201dd6:	6f67b783          	ld	a5,1782(a5) # ffffffffc020d4c8 <va_pa_offset>
ffffffffc0201dda:	6605                	lui	a2,0x1
ffffffffc0201ddc:	4581                	li	a1,0
ffffffffc0201dde:	953e                	add	a0,a0,a5
ffffffffc0201de0:	0a8020ef          	jal	ra,ffffffffc0203e88 <memset>
    return page - pages + nbase;
ffffffffc0201de4:	000b3683          	ld	a3,0(s6)
ffffffffc0201de8:	40d406b3          	sub	a3,s0,a3
ffffffffc0201dec:	8699                	srai	a3,a3,0x6
ffffffffc0201dee:	96d6                	add	a3,a3,s5
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type)
{
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201df0:	06aa                	slli	a3,a3,0xa
ffffffffc0201df2:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V); //把新页表写入一级目录项
ffffffffc0201df6:	e094                	sd	a3,0(s1)
    }
    pde_t *pdep0 = &((pte_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)]; //从一级目录项里取出“二级页表的物理地址”，将物理地址 pa 转换成内核虚拟地址，将其转换为 pte_t 数组后再取出二级页目录项索引
ffffffffc0201df8:	77fd                	lui	a5,0xfffff
ffffffffc0201dfa:	068a                	slli	a3,a3,0x2
ffffffffc0201dfc:	0009b703          	ld	a4,0(s3)
ffffffffc0201e00:	8efd                	and	a3,a3,a5
ffffffffc0201e02:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201e06:	10e7ff63          	bgeu	a5,a4,ffffffffc0201f24 <get_pte+0x1dc>
ffffffffc0201e0a:	0000ba97          	auipc	s5,0xb
ffffffffc0201e0e:	6bea8a93          	addi	s5,s5,1726 # ffffffffc020d4c8 <va_pa_offset>
ffffffffc0201e12:	000ab403          	ld	s0,0(s5)
ffffffffc0201e16:	01595793          	srli	a5,s2,0x15
ffffffffc0201e1a:	1ff7f793          	andi	a5,a5,511
ffffffffc0201e1e:	96a2                	add	a3,a3,s0
ffffffffc0201e20:	00379413          	slli	s0,a5,0x3
ffffffffc0201e24:	9436                	add	s0,s0,a3
    if (!(*pdep0 & PTE_V))
ffffffffc0201e26:	6014                	ld	a3,0(s0)
ffffffffc0201e28:	0016f793          	andi	a5,a3,1
ffffffffc0201e2c:	ebad                	bnez	a5,ffffffffc0201e9e <get_pte+0x156>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201e2e:	0a0a0363          	beqz	s4,ffffffffc0201ed4 <get_pte+0x18c>
ffffffffc0201e32:	100027f3          	csrr	a5,sstatus
ffffffffc0201e36:	8b89                	andi	a5,a5,2
ffffffffc0201e38:	efcd                	bnez	a5,ffffffffc0201ef2 <get_pte+0x1aa>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201e3a:	0000b797          	auipc	a5,0xb
ffffffffc0201e3e:	6867b783          	ld	a5,1670(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201e42:	6f9c                	ld	a5,24(a5)
ffffffffc0201e44:	4505                	li	a0,1
ffffffffc0201e46:	9782                	jalr	a5
ffffffffc0201e48:	84aa                	mv	s1,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201e4a:	c4c9                	beqz	s1,ffffffffc0201ed4 <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc0201e4c:	0000bb17          	auipc	s6,0xb
ffffffffc0201e50:	66cb0b13          	addi	s6,s6,1644 # ffffffffc020d4b8 <pages>
ffffffffc0201e54:	000b3503          	ld	a0,0(s6)
ffffffffc0201e58:	00080a37          	lui	s4,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201e5c:	0009b703          	ld	a4,0(s3)
ffffffffc0201e60:	40a48533          	sub	a0,s1,a0
ffffffffc0201e64:	8519                	srai	a0,a0,0x6
ffffffffc0201e66:	9552                	add	a0,a0,s4
ffffffffc0201e68:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0201e6c:	4685                	li	a3,1
ffffffffc0201e6e:	c094                	sw	a3,0(s1)
ffffffffc0201e70:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201e72:	0532                	slli	a0,a0,0xc
ffffffffc0201e74:	0ee7f163          	bgeu	a5,a4,ffffffffc0201f56 <get_pte+0x20e>
ffffffffc0201e78:	000ab783          	ld	a5,0(s5)
ffffffffc0201e7c:	6605                	lui	a2,0x1
ffffffffc0201e7e:	4581                	li	a1,0
ffffffffc0201e80:	953e                	add	a0,a0,a5
ffffffffc0201e82:	006020ef          	jal	ra,ffffffffc0203e88 <memset>
    return page - pages + nbase;
ffffffffc0201e86:	000b3683          	ld	a3,0(s6)
ffffffffc0201e8a:	40d486b3          	sub	a3,s1,a3
ffffffffc0201e8e:	8699                	srai	a3,a3,0x6
ffffffffc0201e90:	96d2                	add	a3,a3,s4
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201e92:	06aa                	slli	a3,a3,0xa
ffffffffc0201e94:	0116e693          	ori	a3,a3,17
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201e98:	e014                	sd	a3,0(s0)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)]; //根据虚拟地址 la 的页内偏移（PTX(la)）找到该地址的最终 PTE
ffffffffc0201e9a:	0009b703          	ld	a4,0(s3)
ffffffffc0201e9e:	068a                	slli	a3,a3,0x2
ffffffffc0201ea0:	757d                	lui	a0,0xfffff
ffffffffc0201ea2:	8ee9                	and	a3,a3,a0
ffffffffc0201ea4:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201ea8:	06e7f263          	bgeu	a5,a4,ffffffffc0201f0c <get_pte+0x1c4>
ffffffffc0201eac:	000ab503          	ld	a0,0(s5)
ffffffffc0201eb0:	00c95913          	srli	s2,s2,0xc
ffffffffc0201eb4:	1ff97913          	andi	s2,s2,511
ffffffffc0201eb8:	96aa                	add	a3,a3,a0
ffffffffc0201eba:	00391513          	slli	a0,s2,0x3
ffffffffc0201ebe:	9536                	add	a0,a0,a3
}
ffffffffc0201ec0:	70e2                	ld	ra,56(sp)
ffffffffc0201ec2:	7442                	ld	s0,48(sp)
ffffffffc0201ec4:	74a2                	ld	s1,40(sp)
ffffffffc0201ec6:	7902                	ld	s2,32(sp)
ffffffffc0201ec8:	69e2                	ld	s3,24(sp)
ffffffffc0201eca:	6a42                	ld	s4,16(sp)
ffffffffc0201ecc:	6aa2                	ld	s5,8(sp)
ffffffffc0201ece:	6b02                	ld	s6,0(sp)
ffffffffc0201ed0:	6121                	addi	sp,sp,64
ffffffffc0201ed2:	8082                	ret
            return NULL;
ffffffffc0201ed4:	4501                	li	a0,0
ffffffffc0201ed6:	b7ed                	j	ffffffffc0201ec0 <get_pte+0x178>
        intr_disable();
ffffffffc0201ed8:	a59fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201edc:	0000b797          	auipc	a5,0xb
ffffffffc0201ee0:	5e47b783          	ld	a5,1508(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201ee4:	6f9c                	ld	a5,24(a5)
ffffffffc0201ee6:	4505                	li	a0,1
ffffffffc0201ee8:	9782                	jalr	a5
ffffffffc0201eea:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201eec:	a3ffe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0201ef0:	b56d                	j	ffffffffc0201d9a <get_pte+0x52>
        intr_disable();
ffffffffc0201ef2:	a3ffe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
ffffffffc0201ef6:	0000b797          	auipc	a5,0xb
ffffffffc0201efa:	5ca7b783          	ld	a5,1482(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201efe:	6f9c                	ld	a5,24(a5)
ffffffffc0201f00:	4505                	li	a0,1
ffffffffc0201f02:	9782                	jalr	a5
ffffffffc0201f04:	84aa                	mv	s1,a0
        intr_enable();
ffffffffc0201f06:	a25fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0201f0a:	b781                	j	ffffffffc0201e4a <get_pte+0x102>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)]; //根据虚拟地址 la 的页内偏移（PTX(la)）找到该地址的最终 PTE
ffffffffc0201f0c:	00003617          	auipc	a2,0x3
ffffffffc0201f10:	e3460613          	addi	a2,a2,-460 # ffffffffc0204d40 <default_pmm_manager+0x38>
ffffffffc0201f14:	0fb00593          	li	a1,251
ffffffffc0201f18:	00003517          	auipc	a0,0x3
ffffffffc0201f1c:	f4050513          	addi	a0,a0,-192 # ffffffffc0204e58 <default_pmm_manager+0x150>
ffffffffc0201f20:	d3afe0ef          	jal	ra,ffffffffc020045a <__panic>
    pde_t *pdep0 = &((pte_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)]; //从一级目录项里取出“二级页表的物理地址”，将物理地址 pa 转换成内核虚拟地址，将其转换为 pte_t 数组后再取出二级页目录项索引
ffffffffc0201f24:	00003617          	auipc	a2,0x3
ffffffffc0201f28:	e1c60613          	addi	a2,a2,-484 # ffffffffc0204d40 <default_pmm_manager+0x38>
ffffffffc0201f2c:	0ee00593          	li	a1,238
ffffffffc0201f30:	00003517          	auipc	a0,0x3
ffffffffc0201f34:	f2850513          	addi	a0,a0,-216 # ffffffffc0204e58 <default_pmm_manager+0x150>
ffffffffc0201f38:	d22fe0ef          	jal	ra,ffffffffc020045a <__panic>
        memset(KADDR(pa), 0, PGSIZE); //把物理地址 pa 转为“内核虚拟地址”，并把新页表清空
ffffffffc0201f3c:	86aa                	mv	a3,a0
ffffffffc0201f3e:	00003617          	auipc	a2,0x3
ffffffffc0201f42:	e0260613          	addi	a2,a2,-510 # ffffffffc0204d40 <default_pmm_manager+0x38>
ffffffffc0201f46:	0eb00593          	li	a1,235
ffffffffc0201f4a:	00003517          	auipc	a0,0x3
ffffffffc0201f4e:	f0e50513          	addi	a0,a0,-242 # ffffffffc0204e58 <default_pmm_manager+0x150>
ffffffffc0201f52:	d08fe0ef          	jal	ra,ffffffffc020045a <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201f56:	86aa                	mv	a3,a0
ffffffffc0201f58:	00003617          	auipc	a2,0x3
ffffffffc0201f5c:	de860613          	addi	a2,a2,-536 # ffffffffc0204d40 <default_pmm_manager+0x38>
ffffffffc0201f60:	0f800593          	li	a1,248
ffffffffc0201f64:	00003517          	auipc	a0,0x3
ffffffffc0201f68:	ef450513          	addi	a0,a0,-268 # ffffffffc0204e58 <default_pmm_manager+0x150>
ffffffffc0201f6c:	ceefe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0201f70 <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store)
{
ffffffffc0201f70:	1141                	addi	sp,sp,-16
ffffffffc0201f72:	e022                	sd	s0,0(sp)
ffffffffc0201f74:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201f76:	4601                	li	a2,0
{
ffffffffc0201f78:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201f7a:	dcfff0ef          	jal	ra,ffffffffc0201d48 <get_pte>
    if (ptep_store != NULL)
ffffffffc0201f7e:	c011                	beqz	s0,ffffffffc0201f82 <get_page+0x12>
    {
        *ptep_store = ptep;
ffffffffc0201f80:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0201f82:	c511                	beqz	a0,ffffffffc0201f8e <get_page+0x1e>
ffffffffc0201f84:	611c                	ld	a5,0(a0)
    {
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc0201f86:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0201f88:	0017f713          	andi	a4,a5,1
ffffffffc0201f8c:	e709                	bnez	a4,ffffffffc0201f96 <get_page+0x26>
}
ffffffffc0201f8e:	60a2                	ld	ra,8(sp)
ffffffffc0201f90:	6402                	ld	s0,0(sp)
ffffffffc0201f92:	0141                	addi	sp,sp,16
ffffffffc0201f94:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0201f96:	078a                	slli	a5,a5,0x2
ffffffffc0201f98:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0201f9a:	0000b717          	auipc	a4,0xb
ffffffffc0201f9e:	51673703          	ld	a4,1302(a4) # ffffffffc020d4b0 <npage>
ffffffffc0201fa2:	00e7ff63          	bgeu	a5,a4,ffffffffc0201fc0 <get_page+0x50>
ffffffffc0201fa6:	60a2                	ld	ra,8(sp)
ffffffffc0201fa8:	6402                	ld	s0,0(sp)
    return &pages[PPN(pa) - nbase];
ffffffffc0201faa:	fff80537          	lui	a0,0xfff80
ffffffffc0201fae:	97aa                	add	a5,a5,a0
ffffffffc0201fb0:	079a                	slli	a5,a5,0x6
ffffffffc0201fb2:	0000b517          	auipc	a0,0xb
ffffffffc0201fb6:	50653503          	ld	a0,1286(a0) # ffffffffc020d4b8 <pages>
ffffffffc0201fba:	953e                	add	a0,a0,a5
ffffffffc0201fbc:	0141                	addi	sp,sp,16
ffffffffc0201fbe:	8082                	ret
ffffffffc0201fc0:	c99ff0ef          	jal	ra,ffffffffc0201c58 <pa2page.part.0>

ffffffffc0201fc4 <page_remove>:
}

// page_remove - free an Page which is related linear address la and has an
// validated pte
void page_remove(pde_t *pgdir, uintptr_t la)
{
ffffffffc0201fc4:	7179                	addi	sp,sp,-48
    pte_t *ptep = get_pte(pgdir, la, 0);//找到页表项所在位置
ffffffffc0201fc6:	4601                	li	a2,0
{
ffffffffc0201fc8:	ec26                	sd	s1,24(sp)
ffffffffc0201fca:	f406                	sd	ra,40(sp)
ffffffffc0201fcc:	f022                	sd	s0,32(sp)
ffffffffc0201fce:	84ae                	mv	s1,a1
    pte_t *ptep = get_pte(pgdir, la, 0);//找到页表项所在位置
ffffffffc0201fd0:	d79ff0ef          	jal	ra,ffffffffc0201d48 <get_pte>
    if (ptep != NULL)
ffffffffc0201fd4:	c511                	beqz	a0,ffffffffc0201fe0 <page_remove+0x1c>
    if (*ptep & PTE_V)  // 如果该 PTE 有效
ffffffffc0201fd6:	611c                	ld	a5,0(a0)
ffffffffc0201fd8:	842a                	mv	s0,a0
ffffffffc0201fda:	0017f713          	andi	a4,a5,1
ffffffffc0201fde:	e711                	bnez	a4,ffffffffc0201fea <page_remove+0x26>
    {
        page_remove_pte(pgdir, la, ptep);// 删除页表项 ptep 对应的物理页映射
    }
}
ffffffffc0201fe0:	70a2                	ld	ra,40(sp)
ffffffffc0201fe2:	7402                	ld	s0,32(sp)
ffffffffc0201fe4:	64e2                	ld	s1,24(sp)
ffffffffc0201fe6:	6145                	addi	sp,sp,48
ffffffffc0201fe8:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0201fea:	078a                	slli	a5,a5,0x2
ffffffffc0201fec:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0201fee:	0000b717          	auipc	a4,0xb
ffffffffc0201ff2:	4c273703          	ld	a4,1218(a4) # ffffffffc020d4b0 <npage>
ffffffffc0201ff6:	06e7f363          	bgeu	a5,a4,ffffffffc020205c <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc0201ffa:	fff80537          	lui	a0,0xfff80
ffffffffc0201ffe:	97aa                	add	a5,a5,a0
ffffffffc0202000:	079a                	slli	a5,a5,0x6
ffffffffc0202002:	0000b517          	auipc	a0,0xb
ffffffffc0202006:	4b653503          	ld	a0,1206(a0) # ffffffffc020d4b8 <pages>
ffffffffc020200a:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc020200c:	411c                	lw	a5,0(a0)
ffffffffc020200e:	fff7871b          	addiw	a4,a5,-1
ffffffffc0202012:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc0202014:	cb11                	beqz	a4,ffffffffc0202028 <page_remove+0x64>
        *ptep = 0;                 //(5) clear second page table entry
ffffffffc0202016:	00043023          	sd	zero,0(s0)
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la)
{
    // flush_tlb();
    // The flush_tlb flush the entire TLB, is there any better way?
    asm volatile("sfence.vma %0" : : "r"(la)); //只刷新这个虚拟地址对应的 TLB 项
ffffffffc020201a:	12048073          	sfence.vma	s1
}
ffffffffc020201e:	70a2                	ld	ra,40(sp)
ffffffffc0202020:	7402                	ld	s0,32(sp)
ffffffffc0202022:	64e2                	ld	s1,24(sp)
ffffffffc0202024:	6145                	addi	sp,sp,48
ffffffffc0202026:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0202028:	100027f3          	csrr	a5,sstatus
ffffffffc020202c:	8b89                	andi	a5,a5,2
ffffffffc020202e:	eb89                	bnez	a5,ffffffffc0202040 <page_remove+0x7c>
        pmm_manager->free_pages(base, n);
ffffffffc0202030:	0000b797          	auipc	a5,0xb
ffffffffc0202034:	4907b783          	ld	a5,1168(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0202038:	739c                	ld	a5,32(a5)
ffffffffc020203a:	4585                	li	a1,1
ffffffffc020203c:	9782                	jalr	a5
    if (flag) {
ffffffffc020203e:	bfe1                	j	ffffffffc0202016 <page_remove+0x52>
        intr_disable();
ffffffffc0202040:	e42a                	sd	a0,8(sp)
ffffffffc0202042:	8effe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
ffffffffc0202046:	0000b797          	auipc	a5,0xb
ffffffffc020204a:	47a7b783          	ld	a5,1146(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc020204e:	739c                	ld	a5,32(a5)
ffffffffc0202050:	6522                	ld	a0,8(sp)
ffffffffc0202052:	4585                	li	a1,1
ffffffffc0202054:	9782                	jalr	a5
        intr_enable();
ffffffffc0202056:	8d5fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc020205a:	bf75                	j	ffffffffc0202016 <page_remove+0x52>
ffffffffc020205c:	bfdff0ef          	jal	ra,ffffffffc0201c58 <pa2page.part.0>

ffffffffc0202060 <page_insert>:
{
ffffffffc0202060:	7139                	addi	sp,sp,-64
ffffffffc0202062:	e852                	sd	s4,16(sp)
ffffffffc0202064:	8a32                	mv	s4,a2
ffffffffc0202066:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);//找到页表项所在位置
ffffffffc0202068:	4605                	li	a2,1
{
ffffffffc020206a:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);//找到页表项所在位置
ffffffffc020206c:	85d2                	mv	a1,s4
{
ffffffffc020206e:	f426                	sd	s1,40(sp)
ffffffffc0202070:	fc06                	sd	ra,56(sp)
ffffffffc0202072:	f04a                	sd	s2,32(sp)
ffffffffc0202074:	ec4e                	sd	s3,24(sp)
ffffffffc0202076:	e456                	sd	s5,8(sp)
ffffffffc0202078:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);//找到页表项所在位置
ffffffffc020207a:	ccfff0ef          	jal	ra,ffffffffc0201d48 <get_pte>
    if (ptep == NULL)
ffffffffc020207e:	c961                	beqz	a0,ffffffffc020214e <page_insert+0xee>
    page->ref += 1;
ffffffffc0202080:	4014                	lw	a3,0(s0)
    if (*ptep & PTE_V) //如果该 PTE 已存在映射
ffffffffc0202082:	611c                	ld	a5,0(a0)
ffffffffc0202084:	89aa                	mv	s3,a0
ffffffffc0202086:	0016871b          	addiw	a4,a3,1
ffffffffc020208a:	c018                	sw	a4,0(s0)
ffffffffc020208c:	0017f713          	andi	a4,a5,1
ffffffffc0202090:	ef05                	bnez	a4,ffffffffc02020c8 <page_insert+0x68>
    return page - pages + nbase;
ffffffffc0202092:	0000b717          	auipc	a4,0xb
ffffffffc0202096:	42673703          	ld	a4,1062(a4) # ffffffffc020d4b8 <pages>
ffffffffc020209a:	8c19                	sub	s0,s0,a4
ffffffffc020209c:	000807b7          	lui	a5,0x80
ffffffffc02020a0:	8419                	srai	s0,s0,0x6
ffffffffc02020a2:	943e                	add	s0,s0,a5
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc02020a4:	042a                	slli	s0,s0,0xa
ffffffffc02020a6:	8cc1                	or	s1,s1,s0
ffffffffc02020a8:	0014e493          	ori	s1,s1,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm); // 写入新 PTE
ffffffffc02020ac:	0099b023          	sd	s1,0(s3)
    asm volatile("sfence.vma %0" : : "r"(la)); //只刷新这个虚拟地址对应的 TLB 项
ffffffffc02020b0:	120a0073          	sfence.vma	s4
    return 0;
ffffffffc02020b4:	4501                	li	a0,0
}
ffffffffc02020b6:	70e2                	ld	ra,56(sp)
ffffffffc02020b8:	7442                	ld	s0,48(sp)
ffffffffc02020ba:	74a2                	ld	s1,40(sp)
ffffffffc02020bc:	7902                	ld	s2,32(sp)
ffffffffc02020be:	69e2                	ld	s3,24(sp)
ffffffffc02020c0:	6a42                	ld	s4,16(sp)
ffffffffc02020c2:	6aa2                	ld	s5,8(sp)
ffffffffc02020c4:	6121                	addi	sp,sp,64
ffffffffc02020c6:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc02020c8:	078a                	slli	a5,a5,0x2
ffffffffc02020ca:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02020cc:	0000b717          	auipc	a4,0xb
ffffffffc02020d0:	3e473703          	ld	a4,996(a4) # ffffffffc020d4b0 <npage>
ffffffffc02020d4:	06e7ff63          	bgeu	a5,a4,ffffffffc0202152 <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc02020d8:	0000ba97          	auipc	s5,0xb
ffffffffc02020dc:	3e0a8a93          	addi	s5,s5,992 # ffffffffc020d4b8 <pages>
ffffffffc02020e0:	000ab703          	ld	a4,0(s5)
ffffffffc02020e4:	fff80937          	lui	s2,0xfff80
ffffffffc02020e8:	993e                	add	s2,s2,a5
ffffffffc02020ea:	091a                	slli	s2,s2,0x6
ffffffffc02020ec:	993a                	add	s2,s2,a4
        if (p == page)
ffffffffc02020ee:	01240c63          	beq	s0,s2,ffffffffc0202106 <page_insert+0xa6>
    page->ref -= 1;
ffffffffc02020f2:	00092783          	lw	a5,0(s2) # fffffffffff80000 <end+0x3fd72b14>
ffffffffc02020f6:	fff7869b          	addiw	a3,a5,-1
ffffffffc02020fa:	00d92023          	sw	a3,0(s2)
        if (page_ref(page) ==
ffffffffc02020fe:	c691                	beqz	a3,ffffffffc020210a <page_insert+0xaa>
    asm volatile("sfence.vma %0" : : "r"(la)); //只刷新这个虚拟地址对应的 TLB 项
ffffffffc0202100:	120a0073          	sfence.vma	s4
}
ffffffffc0202104:	bf59                	j	ffffffffc020209a <page_insert+0x3a>
ffffffffc0202106:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc0202108:	bf49                	j	ffffffffc020209a <page_insert+0x3a>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020210a:	100027f3          	csrr	a5,sstatus
ffffffffc020210e:	8b89                	andi	a5,a5,2
ffffffffc0202110:	ef91                	bnez	a5,ffffffffc020212c <page_insert+0xcc>
        pmm_manager->free_pages(base, n);
ffffffffc0202112:	0000b797          	auipc	a5,0xb
ffffffffc0202116:	3ae7b783          	ld	a5,942(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc020211a:	739c                	ld	a5,32(a5)
ffffffffc020211c:	4585                	li	a1,1
ffffffffc020211e:	854a                	mv	a0,s2
ffffffffc0202120:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc0202122:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la)); //只刷新这个虚拟地址对应的 TLB 项
ffffffffc0202126:	120a0073          	sfence.vma	s4
ffffffffc020212a:	bf85                	j	ffffffffc020209a <page_insert+0x3a>
        intr_disable();
ffffffffc020212c:	805fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202130:	0000b797          	auipc	a5,0xb
ffffffffc0202134:	3907b783          	ld	a5,912(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0202138:	739c                	ld	a5,32(a5)
ffffffffc020213a:	4585                	li	a1,1
ffffffffc020213c:	854a                	mv	a0,s2
ffffffffc020213e:	9782                	jalr	a5
        intr_enable();
ffffffffc0202140:	feafe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0202144:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la)); //只刷新这个虚拟地址对应的 TLB 项
ffffffffc0202148:	120a0073          	sfence.vma	s4
ffffffffc020214c:	b7b9                	j	ffffffffc020209a <page_insert+0x3a>
        return -E_NO_MEM;
ffffffffc020214e:	5571                	li	a0,-4
ffffffffc0202150:	b79d                	j	ffffffffc02020b6 <page_insert+0x56>
ffffffffc0202152:	b07ff0ef          	jal	ra,ffffffffc0201c58 <pa2page.part.0>

ffffffffc0202156 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc0202156:	00003797          	auipc	a5,0x3
ffffffffc020215a:	bb278793          	addi	a5,a5,-1102 # ffffffffc0204d08 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020215e:	638c                	ld	a1,0(a5)
{
ffffffffc0202160:	7159                	addi	sp,sp,-112
ffffffffc0202162:	f85a                	sd	s6,48(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202164:	00003517          	auipc	a0,0x3
ffffffffc0202168:	d0450513          	addi	a0,a0,-764 # ffffffffc0204e68 <default_pmm_manager+0x160>
    pmm_manager = &default_pmm_manager;
ffffffffc020216c:	0000bb17          	auipc	s6,0xb
ffffffffc0202170:	354b0b13          	addi	s6,s6,852 # ffffffffc020d4c0 <pmm_manager>
{
ffffffffc0202174:	f486                	sd	ra,104(sp)
ffffffffc0202176:	e8ca                	sd	s2,80(sp)
ffffffffc0202178:	e4ce                	sd	s3,72(sp)
ffffffffc020217a:	f0a2                	sd	s0,96(sp)
ffffffffc020217c:	eca6                	sd	s1,88(sp)
ffffffffc020217e:	e0d2                	sd	s4,64(sp)
ffffffffc0202180:	fc56                	sd	s5,56(sp)
ffffffffc0202182:	f45e                	sd	s7,40(sp)
ffffffffc0202184:	f062                	sd	s8,32(sp)
ffffffffc0202186:	ec66                	sd	s9,24(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0202188:	00fb3023          	sd	a5,0(s6)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020218c:	808fe0ef          	jal	ra,ffffffffc0200194 <cprintf>
    pmm_manager->init();
ffffffffc0202190:	000b3783          	ld	a5,0(s6)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0202194:	0000b997          	auipc	s3,0xb
ffffffffc0202198:	33498993          	addi	s3,s3,820 # ffffffffc020d4c8 <va_pa_offset>
    pmm_manager->init();
ffffffffc020219c:	679c                	ld	a5,8(a5)
ffffffffc020219e:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02021a0:	57f5                	li	a5,-3
ffffffffc02021a2:	07fa                	slli	a5,a5,0x1e
ffffffffc02021a4:	00f9b023          	sd	a5,0(s3)
    uint64_t mem_begin = get_memory_base();
ffffffffc02021a8:	f6efe0ef          	jal	ra,ffffffffc0200916 <get_memory_base>
ffffffffc02021ac:	892a                	mv	s2,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc02021ae:	f72fe0ef          	jal	ra,ffffffffc0200920 <get_memory_size>
    if (mem_size == 0) {
ffffffffc02021b2:	200505e3          	beqz	a0,ffffffffc0202bbc <pmm_init+0xa66>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc02021b6:	84aa                	mv	s1,a0
    cprintf("physcial memory map:\n");
ffffffffc02021b8:	00003517          	auipc	a0,0x3
ffffffffc02021bc:	ce850513          	addi	a0,a0,-792 # ffffffffc0204ea0 <default_pmm_manager+0x198>
ffffffffc02021c0:	fd5fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc02021c4:	00990433          	add	s0,s2,s1
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc02021c8:	fff40693          	addi	a3,s0,-1
ffffffffc02021cc:	864a                	mv	a2,s2
ffffffffc02021ce:	85a6                	mv	a1,s1
ffffffffc02021d0:	00003517          	auipc	a0,0x3
ffffffffc02021d4:	ce850513          	addi	a0,a0,-792 # ffffffffc0204eb8 <default_pmm_manager+0x1b0>
ffffffffc02021d8:	fbdfd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc02021dc:	c8000737          	lui	a4,0xc8000
ffffffffc02021e0:	87a2                	mv	a5,s0
ffffffffc02021e2:	54876163          	bltu	a4,s0,ffffffffc0202724 <pmm_init+0x5ce>
ffffffffc02021e6:	757d                	lui	a0,0xfffff
ffffffffc02021e8:	0000c617          	auipc	a2,0xc
ffffffffc02021ec:	30360613          	addi	a2,a2,771 # ffffffffc020e4eb <end+0xfff>
ffffffffc02021f0:	8e69                	and	a2,a2,a0
ffffffffc02021f2:	0000b497          	auipc	s1,0xb
ffffffffc02021f6:	2be48493          	addi	s1,s1,702 # ffffffffc020d4b0 <npage>
ffffffffc02021fa:	00c7d513          	srli	a0,a5,0xc
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02021fe:	0000bb97          	auipc	s7,0xb
ffffffffc0202202:	2bab8b93          	addi	s7,s7,698 # ffffffffc020d4b8 <pages>
    npage = maxpa / PGSIZE;
ffffffffc0202206:	e088                	sd	a0,0(s1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202208:	00cbb023          	sd	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc020220c:	000807b7          	lui	a5,0x80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202210:	86b2                	mv	a3,a2
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202212:	02f50863          	beq	a0,a5,ffffffffc0202242 <pmm_init+0xec>
ffffffffc0202216:	4781                	li	a5,0
ffffffffc0202218:	4585                	li	a1,1
ffffffffc020221a:	fff806b7          	lui	a3,0xfff80
        SetPageReserved(pages + i);
ffffffffc020221e:	00679513          	slli	a0,a5,0x6
ffffffffc0202222:	9532                	add	a0,a0,a2
ffffffffc0202224:	00850713          	addi	a4,a0,8 # fffffffffffff008 <end+0x3fdf1b1c>
ffffffffc0202228:	40b7302f          	amoor.d	zero,a1,(a4)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc020222c:	6088                	ld	a0,0(s1)
ffffffffc020222e:	0785                	addi	a5,a5,1
        SetPageReserved(pages + i);
ffffffffc0202230:	000bb603          	ld	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202234:	00d50733          	add	a4,a0,a3
ffffffffc0202238:	fee7e3e3          	bltu	a5,a4,ffffffffc020221e <pmm_init+0xc8>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020223c:	071a                	slli	a4,a4,0x6
ffffffffc020223e:	00e606b3          	add	a3,a2,a4
ffffffffc0202242:	c02007b7          	lui	a5,0xc0200
ffffffffc0202246:	2ef6ece3          	bltu	a3,a5,ffffffffc0202d3e <pmm_init+0xbe8>
ffffffffc020224a:	0009b583          	ld	a1,0(s3)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc020224e:	77fd                	lui	a5,0xfffff
ffffffffc0202250:	8c7d                	and	s0,s0,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202252:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end)
ffffffffc0202254:	5086eb63          	bltu	a3,s0,ffffffffc020276a <pmm_init+0x614>
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202258:	00003517          	auipc	a0,0x3
ffffffffc020225c:	c8850513          	addi	a0,a0,-888 # ffffffffc0204ee0 <default_pmm_manager+0x1d8>
ffffffffc0202260:	f35fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc0202264:	000b3783          	ld	a5,0(s6)
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0202268:	0000b917          	auipc	s2,0xb
ffffffffc020226c:	24090913          	addi	s2,s2,576 # ffffffffc020d4a8 <boot_pgdir_va>
    pmm_manager->check();
ffffffffc0202270:	7b9c                	ld	a5,48(a5)
ffffffffc0202272:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0202274:	00003517          	auipc	a0,0x3
ffffffffc0202278:	c8450513          	addi	a0,a0,-892 # ffffffffc0204ef8 <default_pmm_manager+0x1f0>
ffffffffc020227c:	f19fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0202280:	00006697          	auipc	a3,0x6
ffffffffc0202284:	d8068693          	addi	a3,a3,-640 # ffffffffc0208000 <boot_page_table_sv39>
ffffffffc0202288:	00d93023          	sd	a3,0(s2)
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc020228c:	c02007b7          	lui	a5,0xc0200
ffffffffc0202290:	28f6ebe3          	bltu	a3,a5,ffffffffc0202d26 <pmm_init+0xbd0>
ffffffffc0202294:	0009b783          	ld	a5,0(s3)
ffffffffc0202298:	8e9d                	sub	a3,a3,a5
ffffffffc020229a:	0000b797          	auipc	a5,0xb
ffffffffc020229e:	20d7b323          	sd	a3,518(a5) # ffffffffc020d4a0 <boot_pgdir_pa>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02022a2:	100027f3          	csrr	a5,sstatus
ffffffffc02022a6:	8b89                	andi	a5,a5,2
ffffffffc02022a8:	4a079763          	bnez	a5,ffffffffc0202756 <pmm_init+0x600>
        ret = pmm_manager->nr_free_pages();
ffffffffc02022ac:	000b3783          	ld	a5,0(s6)
ffffffffc02022b0:	779c                	ld	a5,40(a5)
ffffffffc02022b2:	9782                	jalr	a5
ffffffffc02022b4:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store = nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc02022b6:	6098                	ld	a4,0(s1)
ffffffffc02022b8:	c80007b7          	lui	a5,0xc8000
ffffffffc02022bc:	83b1                	srli	a5,a5,0xc
ffffffffc02022be:	66e7e363          	bltu	a5,a4,ffffffffc0202924 <pmm_init+0x7ce>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc02022c2:	00093503          	ld	a0,0(s2)
ffffffffc02022c6:	62050f63          	beqz	a0,ffffffffc0202904 <pmm_init+0x7ae>
ffffffffc02022ca:	03451793          	slli	a5,a0,0x34
ffffffffc02022ce:	62079b63          	bnez	a5,ffffffffc0202904 <pmm_init+0x7ae>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc02022d2:	4601                	li	a2,0
ffffffffc02022d4:	4581                	li	a1,0
ffffffffc02022d6:	c9bff0ef          	jal	ra,ffffffffc0201f70 <get_page>
ffffffffc02022da:	60051563          	bnez	a0,ffffffffc02028e4 <pmm_init+0x78e>
ffffffffc02022de:	100027f3          	csrr	a5,sstatus
ffffffffc02022e2:	8b89                	andi	a5,a5,2
ffffffffc02022e4:	44079e63          	bnez	a5,ffffffffc0202740 <pmm_init+0x5ea>
        page = pmm_manager->alloc_pages(n);
ffffffffc02022e8:	000b3783          	ld	a5,0(s6)
ffffffffc02022ec:	4505                	li	a0,1
ffffffffc02022ee:	6f9c                	ld	a5,24(a5)
ffffffffc02022f0:	9782                	jalr	a5
ffffffffc02022f2:	8a2a                	mv	s4,a0

    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc02022f4:	00093503          	ld	a0,0(s2)
ffffffffc02022f8:	4681                	li	a3,0
ffffffffc02022fa:	4601                	li	a2,0
ffffffffc02022fc:	85d2                	mv	a1,s4
ffffffffc02022fe:	d63ff0ef          	jal	ra,ffffffffc0202060 <page_insert>
ffffffffc0202302:	26051ae3          	bnez	a0,ffffffffc0202d76 <pmm_init+0xc20>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc0202306:	00093503          	ld	a0,0(s2)
ffffffffc020230a:	4601                	li	a2,0
ffffffffc020230c:	4581                	li	a1,0
ffffffffc020230e:	a3bff0ef          	jal	ra,ffffffffc0201d48 <get_pte>
ffffffffc0202312:	240502e3          	beqz	a0,ffffffffc0202d56 <pmm_init+0xc00>
    assert(pte2page(*ptep) == p1);
ffffffffc0202316:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V))
ffffffffc0202318:	0017f713          	andi	a4,a5,1
ffffffffc020231c:	5a070263          	beqz	a4,ffffffffc02028c0 <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc0202320:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202322:	078a                	slli	a5,a5,0x2
ffffffffc0202324:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202326:	58e7fb63          	bgeu	a5,a4,ffffffffc02028bc <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc020232a:	000bb683          	ld	a3,0(s7)
ffffffffc020232e:	fff80637          	lui	a2,0xfff80
ffffffffc0202332:	97b2                	add	a5,a5,a2
ffffffffc0202334:	079a                	slli	a5,a5,0x6
ffffffffc0202336:	97b6                	add	a5,a5,a3
ffffffffc0202338:	14fa17e3          	bne	s4,a5,ffffffffc0202c86 <pmm_init+0xb30>
    assert(page_ref(p1) == 1);
ffffffffc020233c:	000a2683          	lw	a3,0(s4) # 80000 <kern_entry-0xffffffffc0180000>
ffffffffc0202340:	4785                	li	a5,1
ffffffffc0202342:	12f692e3          	bne	a3,a5,ffffffffc0202c66 <pmm_init+0xb10>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc0202346:	00093503          	ld	a0,0(s2)
ffffffffc020234a:	77fd                	lui	a5,0xfffff
ffffffffc020234c:	6114                	ld	a3,0(a0)
ffffffffc020234e:	068a                	slli	a3,a3,0x2
ffffffffc0202350:	8efd                	and	a3,a3,a5
ffffffffc0202352:	00c6d613          	srli	a2,a3,0xc
ffffffffc0202356:	0ee67ce3          	bgeu	a2,a4,ffffffffc0202c4e <pmm_init+0xaf8>
ffffffffc020235a:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc020235e:	96e2                	add	a3,a3,s8
ffffffffc0202360:	0006ba83          	ld	s5,0(a3)
ffffffffc0202364:	0a8a                	slli	s5,s5,0x2
ffffffffc0202366:	00fafab3          	and	s5,s5,a5
ffffffffc020236a:	00cad793          	srli	a5,s5,0xc
ffffffffc020236e:	0ce7f3e3          	bgeu	a5,a4,ffffffffc0202c34 <pmm_init+0xade>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202372:	4601                	li	a2,0
ffffffffc0202374:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202376:	9ae2                	add	s5,s5,s8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202378:	9d1ff0ef          	jal	ra,ffffffffc0201d48 <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc020237c:	0aa1                	addi	s5,s5,8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc020237e:	55551363          	bne	a0,s5,ffffffffc02028c4 <pmm_init+0x76e>
ffffffffc0202382:	100027f3          	csrr	a5,sstatus
ffffffffc0202386:	8b89                	andi	a5,a5,2
ffffffffc0202388:	3a079163          	bnez	a5,ffffffffc020272a <pmm_init+0x5d4>
        page = pmm_manager->alloc_pages(n);
ffffffffc020238c:	000b3783          	ld	a5,0(s6)
ffffffffc0202390:	4505                	li	a0,1
ffffffffc0202392:	6f9c                	ld	a5,24(a5)
ffffffffc0202394:	9782                	jalr	a5
ffffffffc0202396:	8c2a                	mv	s8,a0

    p2 = alloc_page();
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0202398:	00093503          	ld	a0,0(s2)
ffffffffc020239c:	46d1                	li	a3,20
ffffffffc020239e:	6605                	lui	a2,0x1
ffffffffc02023a0:	85e2                	mv	a1,s8
ffffffffc02023a2:	cbfff0ef          	jal	ra,ffffffffc0202060 <page_insert>
ffffffffc02023a6:	060517e3          	bnez	a0,ffffffffc0202c14 <pmm_init+0xabe>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02023aa:	00093503          	ld	a0,0(s2)
ffffffffc02023ae:	4601                	li	a2,0
ffffffffc02023b0:	6585                	lui	a1,0x1
ffffffffc02023b2:	997ff0ef          	jal	ra,ffffffffc0201d48 <get_pte>
ffffffffc02023b6:	02050fe3          	beqz	a0,ffffffffc0202bf4 <pmm_init+0xa9e>
    assert(*ptep & PTE_U);
ffffffffc02023ba:	611c                	ld	a5,0(a0)
ffffffffc02023bc:	0107f713          	andi	a4,a5,16
ffffffffc02023c0:	7c070e63          	beqz	a4,ffffffffc0202b9c <pmm_init+0xa46>
    assert(*ptep & PTE_W);
ffffffffc02023c4:	8b91                	andi	a5,a5,4
ffffffffc02023c6:	7a078b63          	beqz	a5,ffffffffc0202b7c <pmm_init+0xa26>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc02023ca:	00093503          	ld	a0,0(s2)
ffffffffc02023ce:	611c                	ld	a5,0(a0)
ffffffffc02023d0:	8bc1                	andi	a5,a5,16
ffffffffc02023d2:	78078563          	beqz	a5,ffffffffc0202b5c <pmm_init+0xa06>
    assert(page_ref(p2) == 1);
ffffffffc02023d6:	000c2703          	lw	a4,0(s8) # ff0000 <kern_entry-0xffffffffbf210000>
ffffffffc02023da:	4785                	li	a5,1
ffffffffc02023dc:	76f71063          	bne	a4,a5,ffffffffc0202b3c <pmm_init+0x9e6>

    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc02023e0:	4681                	li	a3,0
ffffffffc02023e2:	6605                	lui	a2,0x1
ffffffffc02023e4:	85d2                	mv	a1,s4
ffffffffc02023e6:	c7bff0ef          	jal	ra,ffffffffc0202060 <page_insert>
ffffffffc02023ea:	72051963          	bnez	a0,ffffffffc0202b1c <pmm_init+0x9c6>
    assert(page_ref(p1) == 2);
ffffffffc02023ee:	000a2703          	lw	a4,0(s4)
ffffffffc02023f2:	4789                	li	a5,2
ffffffffc02023f4:	70f71463          	bne	a4,a5,ffffffffc0202afc <pmm_init+0x9a6>
    assert(page_ref(p2) == 0);
ffffffffc02023f8:	000c2783          	lw	a5,0(s8)
ffffffffc02023fc:	6e079063          	bnez	a5,ffffffffc0202adc <pmm_init+0x986>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202400:	00093503          	ld	a0,0(s2)
ffffffffc0202404:	4601                	li	a2,0
ffffffffc0202406:	6585                	lui	a1,0x1
ffffffffc0202408:	941ff0ef          	jal	ra,ffffffffc0201d48 <get_pte>
ffffffffc020240c:	6a050863          	beqz	a0,ffffffffc0202abc <pmm_init+0x966>
    assert(pte2page(*ptep) == p1);
ffffffffc0202410:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V))
ffffffffc0202412:	00177793          	andi	a5,a4,1
ffffffffc0202416:	4a078563          	beqz	a5,ffffffffc02028c0 <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc020241a:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc020241c:	00271793          	slli	a5,a4,0x2
ffffffffc0202420:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202422:	48d7fd63          	bgeu	a5,a3,ffffffffc02028bc <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202426:	000bb683          	ld	a3,0(s7)
ffffffffc020242a:	fff80ab7          	lui	s5,0xfff80
ffffffffc020242e:	97d6                	add	a5,a5,s5
ffffffffc0202430:	079a                	slli	a5,a5,0x6
ffffffffc0202432:	97b6                	add	a5,a5,a3
ffffffffc0202434:	66fa1463          	bne	s4,a5,ffffffffc0202a9c <pmm_init+0x946>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202438:	8b41                	andi	a4,a4,16
ffffffffc020243a:	64071163          	bnez	a4,ffffffffc0202a7c <pmm_init+0x926>

    page_remove(boot_pgdir_va, 0x0);
ffffffffc020243e:	00093503          	ld	a0,0(s2)
ffffffffc0202442:	4581                	li	a1,0
ffffffffc0202444:	b81ff0ef          	jal	ra,ffffffffc0201fc4 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0202448:	000a2c83          	lw	s9,0(s4)
ffffffffc020244c:	4785                	li	a5,1
ffffffffc020244e:	60fc9763          	bne	s9,a5,ffffffffc0202a5c <pmm_init+0x906>
    assert(page_ref(p2) == 0);
ffffffffc0202452:	000c2783          	lw	a5,0(s8)
ffffffffc0202456:	5e079363          	bnez	a5,ffffffffc0202a3c <pmm_init+0x8e6>

    page_remove(boot_pgdir_va, PGSIZE);
ffffffffc020245a:	00093503          	ld	a0,0(s2)
ffffffffc020245e:	6585                	lui	a1,0x1
ffffffffc0202460:	b65ff0ef          	jal	ra,ffffffffc0201fc4 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0202464:	000a2783          	lw	a5,0(s4)
ffffffffc0202468:	52079a63          	bnez	a5,ffffffffc020299c <pmm_init+0x846>
    assert(page_ref(p2) == 0);
ffffffffc020246c:	000c2783          	lw	a5,0(s8)
ffffffffc0202470:	50079663          	bnez	a5,ffffffffc020297c <pmm_init+0x826>

    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202474:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202478:	608c                	ld	a1,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc020247a:	000a3683          	ld	a3,0(s4)
ffffffffc020247e:	068a                	slli	a3,a3,0x2
ffffffffc0202480:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0202482:	42b6fd63          	bgeu	a3,a1,ffffffffc02028bc <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202486:	000bb503          	ld	a0,0(s7)
ffffffffc020248a:	96d6                	add	a3,a3,s5
ffffffffc020248c:	069a                	slli	a3,a3,0x6
    return page->ref;
ffffffffc020248e:	00d507b3          	add	a5,a0,a3
ffffffffc0202492:	439c                	lw	a5,0(a5)
ffffffffc0202494:	4d979463          	bne	a5,s9,ffffffffc020295c <pmm_init+0x806>
    return page - pages + nbase;
ffffffffc0202498:	8699                	srai	a3,a3,0x6
ffffffffc020249a:	00080637          	lui	a2,0x80
ffffffffc020249e:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc02024a0:	00c69713          	slli	a4,a3,0xc
ffffffffc02024a4:	8331                	srli	a4,a4,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc02024a6:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02024a8:	48b77e63          	bgeu	a4,a1,ffffffffc0202944 <pmm_init+0x7ee>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
    free_page(pde2page(pd0[0]));
ffffffffc02024ac:	0009b703          	ld	a4,0(s3)
ffffffffc02024b0:	96ba                	add	a3,a3,a4
    return pa2page(PDE_ADDR(pde));
ffffffffc02024b2:	629c                	ld	a5,0(a3)
ffffffffc02024b4:	078a                	slli	a5,a5,0x2
ffffffffc02024b6:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02024b8:	40b7f263          	bgeu	a5,a1,ffffffffc02028bc <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc02024bc:	8f91                	sub	a5,a5,a2
ffffffffc02024be:	079a                	slli	a5,a5,0x6
ffffffffc02024c0:	953e                	add	a0,a0,a5
ffffffffc02024c2:	100027f3          	csrr	a5,sstatus
ffffffffc02024c6:	8b89                	andi	a5,a5,2
ffffffffc02024c8:	30079963          	bnez	a5,ffffffffc02027da <pmm_init+0x684>
        pmm_manager->free_pages(base, n);
ffffffffc02024cc:	000b3783          	ld	a5,0(s6)
ffffffffc02024d0:	4585                	li	a1,1
ffffffffc02024d2:	739c                	ld	a5,32(a5)
ffffffffc02024d4:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc02024d6:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc02024da:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02024dc:	078a                	slli	a5,a5,0x2
ffffffffc02024de:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02024e0:	3ce7fe63          	bgeu	a5,a4,ffffffffc02028bc <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc02024e4:	000bb503          	ld	a0,0(s7)
ffffffffc02024e8:	fff80737          	lui	a4,0xfff80
ffffffffc02024ec:	97ba                	add	a5,a5,a4
ffffffffc02024ee:	079a                	slli	a5,a5,0x6
ffffffffc02024f0:	953e                	add	a0,a0,a5
ffffffffc02024f2:	100027f3          	csrr	a5,sstatus
ffffffffc02024f6:	8b89                	andi	a5,a5,2
ffffffffc02024f8:	2c079563          	bnez	a5,ffffffffc02027c2 <pmm_init+0x66c>
ffffffffc02024fc:	000b3783          	ld	a5,0(s6)
ffffffffc0202500:	4585                	li	a1,1
ffffffffc0202502:	739c                	ld	a5,32(a5)
ffffffffc0202504:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202506:	00093783          	ld	a5,0(s2)
ffffffffc020250a:	0007b023          	sd	zero,0(a5) # fffffffffffff000 <end+0x3fdf1b14>
    asm volatile("sfence.vma");
ffffffffc020250e:	12000073          	sfence.vma
ffffffffc0202512:	100027f3          	csrr	a5,sstatus
ffffffffc0202516:	8b89                	andi	a5,a5,2
ffffffffc0202518:	28079b63          	bnez	a5,ffffffffc02027ae <pmm_init+0x658>
        ret = pmm_manager->nr_free_pages();
ffffffffc020251c:	000b3783          	ld	a5,0(s6)
ffffffffc0202520:	779c                	ld	a5,40(a5)
ffffffffc0202522:	9782                	jalr	a5
ffffffffc0202524:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202526:	4b441b63          	bne	s0,s4,ffffffffc02029dc <pmm_init+0x886>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc020252a:	00003517          	auipc	a0,0x3
ffffffffc020252e:	cf650513          	addi	a0,a0,-778 # ffffffffc0205220 <default_pmm_manager+0x518>
ffffffffc0202532:	c63fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0202536:	100027f3          	csrr	a5,sstatus
ffffffffc020253a:	8b89                	andi	a5,a5,2
ffffffffc020253c:	24079f63          	bnez	a5,ffffffffc020279a <pmm_init+0x644>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202540:	000b3783          	ld	a5,0(s6)
ffffffffc0202544:	779c                	ld	a5,40(a5)
ffffffffc0202546:	9782                	jalr	a5
ffffffffc0202548:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store = nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc020254a:	6098                	ld	a4,0(s1)
ffffffffc020254c:	c0200437          	lui	s0,0xc0200
    {
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202550:	7afd                	lui	s5,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202552:	00c71793          	slli	a5,a4,0xc
ffffffffc0202556:	6a05                	lui	s4,0x1
ffffffffc0202558:	02f47c63          	bgeu	s0,a5,ffffffffc0202590 <pmm_init+0x43a>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc020255c:	00c45793          	srli	a5,s0,0xc
ffffffffc0202560:	00093503          	ld	a0,0(s2)
ffffffffc0202564:	2ee7ff63          	bgeu	a5,a4,ffffffffc0202862 <pmm_init+0x70c>
ffffffffc0202568:	0009b583          	ld	a1,0(s3)
ffffffffc020256c:	4601                	li	a2,0
ffffffffc020256e:	95a2                	add	a1,a1,s0
ffffffffc0202570:	fd8ff0ef          	jal	ra,ffffffffc0201d48 <get_pte>
ffffffffc0202574:	32050463          	beqz	a0,ffffffffc020289c <pmm_init+0x746>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202578:	611c                	ld	a5,0(a0)
ffffffffc020257a:	078a                	slli	a5,a5,0x2
ffffffffc020257c:	0157f7b3          	and	a5,a5,s5
ffffffffc0202580:	2e879e63          	bne	a5,s0,ffffffffc020287c <pmm_init+0x726>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202584:	6098                	ld	a4,0(s1)
ffffffffc0202586:	9452                	add	s0,s0,s4
ffffffffc0202588:	00c71793          	slli	a5,a4,0xc
ffffffffc020258c:	fcf468e3          	bltu	s0,a5,ffffffffc020255c <pmm_init+0x406>
    }

    assert(boot_pgdir_va[0] == 0);
ffffffffc0202590:	00093783          	ld	a5,0(s2)
ffffffffc0202594:	639c                	ld	a5,0(a5)
ffffffffc0202596:	42079363          	bnez	a5,ffffffffc02029bc <pmm_init+0x866>
ffffffffc020259a:	100027f3          	csrr	a5,sstatus
ffffffffc020259e:	8b89                	andi	a5,a5,2
ffffffffc02025a0:	24079963          	bnez	a5,ffffffffc02027f2 <pmm_init+0x69c>
        page = pmm_manager->alloc_pages(n);
ffffffffc02025a4:	000b3783          	ld	a5,0(s6)
ffffffffc02025a8:	4505                	li	a0,1
ffffffffc02025aa:	6f9c                	ld	a5,24(a5)
ffffffffc02025ac:	9782                	jalr	a5
ffffffffc02025ae:	8a2a                	mv	s4,a0

    struct Page *p;
    p = alloc_page();
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc02025b0:	00093503          	ld	a0,0(s2)
ffffffffc02025b4:	4699                	li	a3,6
ffffffffc02025b6:	10000613          	li	a2,256
ffffffffc02025ba:	85d2                	mv	a1,s4
ffffffffc02025bc:	aa5ff0ef          	jal	ra,ffffffffc0202060 <page_insert>
ffffffffc02025c0:	44051e63          	bnez	a0,ffffffffc0202a1c <pmm_init+0x8c6>
    assert(page_ref(p) == 1);
ffffffffc02025c4:	000a2703          	lw	a4,0(s4) # 1000 <kern_entry-0xffffffffc01ff000>
ffffffffc02025c8:	4785                	li	a5,1
ffffffffc02025ca:	42f71963          	bne	a4,a5,ffffffffc02029fc <pmm_init+0x8a6>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc02025ce:	00093503          	ld	a0,0(s2)
ffffffffc02025d2:	6405                	lui	s0,0x1
ffffffffc02025d4:	4699                	li	a3,6
ffffffffc02025d6:	10040613          	addi	a2,s0,256 # 1100 <kern_entry-0xffffffffc01fef00>
ffffffffc02025da:	85d2                	mv	a1,s4
ffffffffc02025dc:	a85ff0ef          	jal	ra,ffffffffc0202060 <page_insert>
ffffffffc02025e0:	72051363          	bnez	a0,ffffffffc0202d06 <pmm_init+0xbb0>
    assert(page_ref(p) == 2);
ffffffffc02025e4:	000a2703          	lw	a4,0(s4)
ffffffffc02025e8:	4789                	li	a5,2
ffffffffc02025ea:	6ef71e63          	bne	a4,a5,ffffffffc0202ce6 <pmm_init+0xb90>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc02025ee:	00003597          	auipc	a1,0x3
ffffffffc02025f2:	d7a58593          	addi	a1,a1,-646 # ffffffffc0205368 <default_pmm_manager+0x660>
ffffffffc02025f6:	10000513          	li	a0,256
ffffffffc02025fa:	023010ef          	jal	ra,ffffffffc0203e1c <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc02025fe:	10040593          	addi	a1,s0,256
ffffffffc0202602:	10000513          	li	a0,256
ffffffffc0202606:	029010ef          	jal	ra,ffffffffc0203e2e <strcmp>
ffffffffc020260a:	6a051e63          	bnez	a0,ffffffffc0202cc6 <pmm_init+0xb70>
    return page - pages + nbase;
ffffffffc020260e:	000bb683          	ld	a3,0(s7)
ffffffffc0202612:	00080737          	lui	a4,0x80
    return KADDR(page2pa(page));
ffffffffc0202616:	547d                	li	s0,-1
    return page - pages + nbase;
ffffffffc0202618:	40da06b3          	sub	a3,s4,a3
ffffffffc020261c:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc020261e:	609c                	ld	a5,0(s1)
    return page - pages + nbase;
ffffffffc0202620:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc0202622:	8031                	srli	s0,s0,0xc
ffffffffc0202624:	0086f733          	and	a4,a3,s0
    return page2ppn(page) << PGSHIFT;
ffffffffc0202628:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020262a:	30f77d63          	bgeu	a4,a5,ffffffffc0202944 <pmm_init+0x7ee>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc020262e:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202632:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202636:	96be                	add	a3,a3,a5
ffffffffc0202638:	10068023          	sb	zero,256(a3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc020263c:	7aa010ef          	jal	ra,ffffffffc0203de6 <strlen>
ffffffffc0202640:	66051363          	bnez	a0,ffffffffc0202ca6 <pmm_init+0xb50>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
ffffffffc0202644:	00093a83          	ld	s5,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202648:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc020264a:	000ab683          	ld	a3,0(s5) # fffffffffffff000 <end+0x3fdf1b14>
ffffffffc020264e:	068a                	slli	a3,a3,0x2
ffffffffc0202650:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0202652:	26f6f563          	bgeu	a3,a5,ffffffffc02028bc <pmm_init+0x766>
    return KADDR(page2pa(page));
ffffffffc0202656:	8c75                	and	s0,s0,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0202658:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020265a:	2ef47563          	bgeu	s0,a5,ffffffffc0202944 <pmm_init+0x7ee>
ffffffffc020265e:	0009b403          	ld	s0,0(s3)
ffffffffc0202662:	9436                	add	s0,s0,a3
ffffffffc0202664:	100027f3          	csrr	a5,sstatus
ffffffffc0202668:	8b89                	andi	a5,a5,2
ffffffffc020266a:	1e079163          	bnez	a5,ffffffffc020284c <pmm_init+0x6f6>
        pmm_manager->free_pages(base, n);
ffffffffc020266e:	000b3783          	ld	a5,0(s6)
ffffffffc0202672:	4585                	li	a1,1
ffffffffc0202674:	8552                	mv	a0,s4
ffffffffc0202676:	739c                	ld	a5,32(a5)
ffffffffc0202678:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc020267a:	601c                	ld	a5,0(s0)
    if (PPN(pa) >= npage)
ffffffffc020267c:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc020267e:	078a                	slli	a5,a5,0x2
ffffffffc0202680:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202682:	22e7fd63          	bgeu	a5,a4,ffffffffc02028bc <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202686:	000bb503          	ld	a0,0(s7)
ffffffffc020268a:	fff80737          	lui	a4,0xfff80
ffffffffc020268e:	97ba                	add	a5,a5,a4
ffffffffc0202690:	079a                	slli	a5,a5,0x6
ffffffffc0202692:	953e                	add	a0,a0,a5
ffffffffc0202694:	100027f3          	csrr	a5,sstatus
ffffffffc0202698:	8b89                	andi	a5,a5,2
ffffffffc020269a:	18079d63          	bnez	a5,ffffffffc0202834 <pmm_init+0x6de>
ffffffffc020269e:	000b3783          	ld	a5,0(s6)
ffffffffc02026a2:	4585                	li	a1,1
ffffffffc02026a4:	739c                	ld	a5,32(a5)
ffffffffc02026a6:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc02026a8:	000ab783          	ld	a5,0(s5)
    if (PPN(pa) >= npage)
ffffffffc02026ac:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02026ae:	078a                	slli	a5,a5,0x2
ffffffffc02026b0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02026b2:	20e7f563          	bgeu	a5,a4,ffffffffc02028bc <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc02026b6:	000bb503          	ld	a0,0(s7)
ffffffffc02026ba:	fff80737          	lui	a4,0xfff80
ffffffffc02026be:	97ba                	add	a5,a5,a4
ffffffffc02026c0:	079a                	slli	a5,a5,0x6
ffffffffc02026c2:	953e                	add	a0,a0,a5
ffffffffc02026c4:	100027f3          	csrr	a5,sstatus
ffffffffc02026c8:	8b89                	andi	a5,a5,2
ffffffffc02026ca:	14079963          	bnez	a5,ffffffffc020281c <pmm_init+0x6c6>
ffffffffc02026ce:	000b3783          	ld	a5,0(s6)
ffffffffc02026d2:	4585                	li	a1,1
ffffffffc02026d4:	739c                	ld	a5,32(a5)
ffffffffc02026d6:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc02026d8:	00093783          	ld	a5,0(s2)
ffffffffc02026dc:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma");
ffffffffc02026e0:	12000073          	sfence.vma
ffffffffc02026e4:	100027f3          	csrr	a5,sstatus
ffffffffc02026e8:	8b89                	andi	a5,a5,2
ffffffffc02026ea:	10079f63          	bnez	a5,ffffffffc0202808 <pmm_init+0x6b2>
        ret = pmm_manager->nr_free_pages();
ffffffffc02026ee:	000b3783          	ld	a5,0(s6)
ffffffffc02026f2:	779c                	ld	a5,40(a5)
ffffffffc02026f4:	9782                	jalr	a5
ffffffffc02026f6:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc02026f8:	4c8c1e63          	bne	s8,s0,ffffffffc0202bd4 <pmm_init+0xa7e>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc02026fc:	00003517          	auipc	a0,0x3
ffffffffc0202700:	ce450513          	addi	a0,a0,-796 # ffffffffc02053e0 <default_pmm_manager+0x6d8>
ffffffffc0202704:	a91fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
}
ffffffffc0202708:	7406                	ld	s0,96(sp)
ffffffffc020270a:	70a6                	ld	ra,104(sp)
ffffffffc020270c:	64e6                	ld	s1,88(sp)
ffffffffc020270e:	6946                	ld	s2,80(sp)
ffffffffc0202710:	69a6                	ld	s3,72(sp)
ffffffffc0202712:	6a06                	ld	s4,64(sp)
ffffffffc0202714:	7ae2                	ld	s5,56(sp)
ffffffffc0202716:	7b42                	ld	s6,48(sp)
ffffffffc0202718:	7ba2                	ld	s7,40(sp)
ffffffffc020271a:	7c02                	ld	s8,32(sp)
ffffffffc020271c:	6ce2                	ld	s9,24(sp)
ffffffffc020271e:	6165                	addi	sp,sp,112
    kmalloc_init();
ffffffffc0202720:	b72ff06f          	j	ffffffffc0201a92 <kmalloc_init>
    npage = maxpa / PGSIZE;
ffffffffc0202724:	c80007b7          	lui	a5,0xc8000
ffffffffc0202728:	bc7d                	j	ffffffffc02021e6 <pmm_init+0x90>
        intr_disable();
ffffffffc020272a:	a06fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc020272e:	000b3783          	ld	a5,0(s6)
ffffffffc0202732:	4505                	li	a0,1
ffffffffc0202734:	6f9c                	ld	a5,24(a5)
ffffffffc0202736:	9782                	jalr	a5
ffffffffc0202738:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc020273a:	9f0fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc020273e:	b9a9                	j	ffffffffc0202398 <pmm_init+0x242>
        intr_disable();
ffffffffc0202740:	9f0fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
ffffffffc0202744:	000b3783          	ld	a5,0(s6)
ffffffffc0202748:	4505                	li	a0,1
ffffffffc020274a:	6f9c                	ld	a5,24(a5)
ffffffffc020274c:	9782                	jalr	a5
ffffffffc020274e:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202750:	9dafe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0202754:	b645                	j	ffffffffc02022f4 <pmm_init+0x19e>
        intr_disable();
ffffffffc0202756:	9dafe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc020275a:	000b3783          	ld	a5,0(s6)
ffffffffc020275e:	779c                	ld	a5,40(a5)
ffffffffc0202760:	9782                	jalr	a5
ffffffffc0202762:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202764:	9c6fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0202768:	b6b9                	j	ffffffffc02022b6 <pmm_init+0x160>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc020276a:	6705                	lui	a4,0x1
ffffffffc020276c:	177d                	addi	a4,a4,-1
ffffffffc020276e:	96ba                	add	a3,a3,a4
ffffffffc0202770:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage)
ffffffffc0202772:	00c7d713          	srli	a4,a5,0xc
ffffffffc0202776:	14a77363          	bgeu	a4,a0,ffffffffc02028bc <pmm_init+0x766>
    pmm_manager->init_memmap(base, n);
ffffffffc020277a:	000b3683          	ld	a3,0(s6)
    return &pages[PPN(pa) - nbase];
ffffffffc020277e:	fff80537          	lui	a0,0xfff80
ffffffffc0202782:	972a                	add	a4,a4,a0
ffffffffc0202784:	6a94                	ld	a3,16(a3)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0202786:	8c1d                	sub	s0,s0,a5
ffffffffc0202788:	00671513          	slli	a0,a4,0x6
    pmm_manager->init_memmap(base, n);
ffffffffc020278c:	00c45593          	srli	a1,s0,0xc
ffffffffc0202790:	9532                	add	a0,a0,a2
ffffffffc0202792:	9682                	jalr	a3
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202794:	0009b583          	ld	a1,0(s3)
}
ffffffffc0202798:	b4c1                	j	ffffffffc0202258 <pmm_init+0x102>
        intr_disable();
ffffffffc020279a:	996fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc020279e:	000b3783          	ld	a5,0(s6)
ffffffffc02027a2:	779c                	ld	a5,40(a5)
ffffffffc02027a4:	9782                	jalr	a5
ffffffffc02027a6:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc02027a8:	982fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc02027ac:	bb79                	j	ffffffffc020254a <pmm_init+0x3f4>
        intr_disable();
ffffffffc02027ae:	982fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
ffffffffc02027b2:	000b3783          	ld	a5,0(s6)
ffffffffc02027b6:	779c                	ld	a5,40(a5)
ffffffffc02027b8:	9782                	jalr	a5
ffffffffc02027ba:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc02027bc:	96efe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc02027c0:	b39d                	j	ffffffffc0202526 <pmm_init+0x3d0>
ffffffffc02027c2:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02027c4:	96cfe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02027c8:	000b3783          	ld	a5,0(s6)
ffffffffc02027cc:	6522                	ld	a0,8(sp)
ffffffffc02027ce:	4585                	li	a1,1
ffffffffc02027d0:	739c                	ld	a5,32(a5)
ffffffffc02027d2:	9782                	jalr	a5
        intr_enable();
ffffffffc02027d4:	956fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc02027d8:	b33d                	j	ffffffffc0202506 <pmm_init+0x3b0>
ffffffffc02027da:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02027dc:	954fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
ffffffffc02027e0:	000b3783          	ld	a5,0(s6)
ffffffffc02027e4:	6522                	ld	a0,8(sp)
ffffffffc02027e6:	4585                	li	a1,1
ffffffffc02027e8:	739c                	ld	a5,32(a5)
ffffffffc02027ea:	9782                	jalr	a5
        intr_enable();
ffffffffc02027ec:	93efe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc02027f0:	b1dd                	j	ffffffffc02024d6 <pmm_init+0x380>
        intr_disable();
ffffffffc02027f2:	93efe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02027f6:	000b3783          	ld	a5,0(s6)
ffffffffc02027fa:	4505                	li	a0,1
ffffffffc02027fc:	6f9c                	ld	a5,24(a5)
ffffffffc02027fe:	9782                	jalr	a5
ffffffffc0202800:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202802:	928fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0202806:	b36d                	j	ffffffffc02025b0 <pmm_init+0x45a>
        intr_disable();
ffffffffc0202808:	928fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc020280c:	000b3783          	ld	a5,0(s6)
ffffffffc0202810:	779c                	ld	a5,40(a5)
ffffffffc0202812:	9782                	jalr	a5
ffffffffc0202814:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202816:	914fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc020281a:	bdf9                	j	ffffffffc02026f8 <pmm_init+0x5a2>
ffffffffc020281c:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc020281e:	912fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202822:	000b3783          	ld	a5,0(s6)
ffffffffc0202826:	6522                	ld	a0,8(sp)
ffffffffc0202828:	4585                	li	a1,1
ffffffffc020282a:	739c                	ld	a5,32(a5)
ffffffffc020282c:	9782                	jalr	a5
        intr_enable();
ffffffffc020282e:	8fcfe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0202832:	b55d                	j	ffffffffc02026d8 <pmm_init+0x582>
ffffffffc0202834:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202836:	8fafe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
ffffffffc020283a:	000b3783          	ld	a5,0(s6)
ffffffffc020283e:	6522                	ld	a0,8(sp)
ffffffffc0202840:	4585                	li	a1,1
ffffffffc0202842:	739c                	ld	a5,32(a5)
ffffffffc0202844:	9782                	jalr	a5
        intr_enable();
ffffffffc0202846:	8e4fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc020284a:	bdb9                	j	ffffffffc02026a8 <pmm_init+0x552>
        intr_disable();
ffffffffc020284c:	8e4fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
ffffffffc0202850:	000b3783          	ld	a5,0(s6)
ffffffffc0202854:	4585                	li	a1,1
ffffffffc0202856:	8552                	mv	a0,s4
ffffffffc0202858:	739c                	ld	a5,32(a5)
ffffffffc020285a:	9782                	jalr	a5
        intr_enable();
ffffffffc020285c:	8cefe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0202860:	bd29                	j	ffffffffc020267a <pmm_init+0x524>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202862:	86a2                	mv	a3,s0
ffffffffc0202864:	00002617          	auipc	a2,0x2
ffffffffc0202868:	4dc60613          	addi	a2,a2,1244 # ffffffffc0204d40 <default_pmm_manager+0x38>
ffffffffc020286c:	1a400593          	li	a1,420
ffffffffc0202870:	00002517          	auipc	a0,0x2
ffffffffc0202874:	5e850513          	addi	a0,a0,1512 # ffffffffc0204e58 <default_pmm_manager+0x150>
ffffffffc0202878:	be3fd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc020287c:	00003697          	auipc	a3,0x3
ffffffffc0202880:	a0468693          	addi	a3,a3,-1532 # ffffffffc0205280 <default_pmm_manager+0x578>
ffffffffc0202884:	00002617          	auipc	a2,0x2
ffffffffc0202888:	0d460613          	addi	a2,a2,212 # ffffffffc0204958 <commands+0x818>
ffffffffc020288c:	1a500593          	li	a1,421
ffffffffc0202890:	00002517          	auipc	a0,0x2
ffffffffc0202894:	5c850513          	addi	a0,a0,1480 # ffffffffc0204e58 <default_pmm_manager+0x150>
ffffffffc0202898:	bc3fd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc020289c:	00003697          	auipc	a3,0x3
ffffffffc02028a0:	9a468693          	addi	a3,a3,-1628 # ffffffffc0205240 <default_pmm_manager+0x538>
ffffffffc02028a4:	00002617          	auipc	a2,0x2
ffffffffc02028a8:	0b460613          	addi	a2,a2,180 # ffffffffc0204958 <commands+0x818>
ffffffffc02028ac:	1a400593          	li	a1,420
ffffffffc02028b0:	00002517          	auipc	a0,0x2
ffffffffc02028b4:	5a850513          	addi	a0,a0,1448 # ffffffffc0204e58 <default_pmm_manager+0x150>
ffffffffc02028b8:	ba3fd0ef          	jal	ra,ffffffffc020045a <__panic>
ffffffffc02028bc:	b9cff0ef          	jal	ra,ffffffffc0201c58 <pa2page.part.0>
ffffffffc02028c0:	bb4ff0ef          	jal	ra,ffffffffc0201c74 <pte2page.part.0>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc02028c4:	00002697          	auipc	a3,0x2
ffffffffc02028c8:	77468693          	addi	a3,a3,1908 # ffffffffc0205038 <default_pmm_manager+0x330>
ffffffffc02028cc:	00002617          	auipc	a2,0x2
ffffffffc02028d0:	08c60613          	addi	a2,a2,140 # ffffffffc0204958 <commands+0x818>
ffffffffc02028d4:	17400593          	li	a1,372
ffffffffc02028d8:	00002517          	auipc	a0,0x2
ffffffffc02028dc:	58050513          	addi	a0,a0,1408 # ffffffffc0204e58 <default_pmm_manager+0x150>
ffffffffc02028e0:	b7bfd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc02028e4:	00002697          	auipc	a3,0x2
ffffffffc02028e8:	69468693          	addi	a3,a3,1684 # ffffffffc0204f78 <default_pmm_manager+0x270>
ffffffffc02028ec:	00002617          	auipc	a2,0x2
ffffffffc02028f0:	06c60613          	addi	a2,a2,108 # ffffffffc0204958 <commands+0x818>
ffffffffc02028f4:	16700593          	li	a1,359
ffffffffc02028f8:	00002517          	auipc	a0,0x2
ffffffffc02028fc:	56050513          	addi	a0,a0,1376 # ffffffffc0204e58 <default_pmm_manager+0x150>
ffffffffc0202900:	b5bfd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0202904:	00002697          	auipc	a3,0x2
ffffffffc0202908:	63468693          	addi	a3,a3,1588 # ffffffffc0204f38 <default_pmm_manager+0x230>
ffffffffc020290c:	00002617          	auipc	a2,0x2
ffffffffc0202910:	04c60613          	addi	a2,a2,76 # ffffffffc0204958 <commands+0x818>
ffffffffc0202914:	16600593          	li	a1,358
ffffffffc0202918:	00002517          	auipc	a0,0x2
ffffffffc020291c:	54050513          	addi	a0,a0,1344 # ffffffffc0204e58 <default_pmm_manager+0x150>
ffffffffc0202920:	b3bfd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0202924:	00002697          	auipc	a3,0x2
ffffffffc0202928:	5f468693          	addi	a3,a3,1524 # ffffffffc0204f18 <default_pmm_manager+0x210>
ffffffffc020292c:	00002617          	auipc	a2,0x2
ffffffffc0202930:	02c60613          	addi	a2,a2,44 # ffffffffc0204958 <commands+0x818>
ffffffffc0202934:	16500593          	li	a1,357
ffffffffc0202938:	00002517          	auipc	a0,0x2
ffffffffc020293c:	52050513          	addi	a0,a0,1312 # ffffffffc0204e58 <default_pmm_manager+0x150>
ffffffffc0202940:	b1bfd0ef          	jal	ra,ffffffffc020045a <__panic>
    return KADDR(page2pa(page));
ffffffffc0202944:	00002617          	auipc	a2,0x2
ffffffffc0202948:	3fc60613          	addi	a2,a2,1020 # ffffffffc0204d40 <default_pmm_manager+0x38>
ffffffffc020294c:	07100593          	li	a1,113
ffffffffc0202950:	00002517          	auipc	a0,0x2
ffffffffc0202954:	41850513          	addi	a0,a0,1048 # ffffffffc0204d68 <default_pmm_manager+0x60>
ffffffffc0202958:	b03fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc020295c:	00003697          	auipc	a3,0x3
ffffffffc0202960:	86c68693          	addi	a3,a3,-1940 # ffffffffc02051c8 <default_pmm_manager+0x4c0>
ffffffffc0202964:	00002617          	auipc	a2,0x2
ffffffffc0202968:	ff460613          	addi	a2,a2,-12 # ffffffffc0204958 <commands+0x818>
ffffffffc020296c:	18d00593          	li	a1,397
ffffffffc0202970:	00002517          	auipc	a0,0x2
ffffffffc0202974:	4e850513          	addi	a0,a0,1256 # ffffffffc0204e58 <default_pmm_manager+0x150>
ffffffffc0202978:	ae3fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p2) == 0);
ffffffffc020297c:	00003697          	auipc	a3,0x3
ffffffffc0202980:	80468693          	addi	a3,a3,-2044 # ffffffffc0205180 <default_pmm_manager+0x478>
ffffffffc0202984:	00002617          	auipc	a2,0x2
ffffffffc0202988:	fd460613          	addi	a2,a2,-44 # ffffffffc0204958 <commands+0x818>
ffffffffc020298c:	18b00593          	li	a1,395
ffffffffc0202990:	00002517          	auipc	a0,0x2
ffffffffc0202994:	4c850513          	addi	a0,a0,1224 # ffffffffc0204e58 <default_pmm_manager+0x150>
ffffffffc0202998:	ac3fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p1) == 0);
ffffffffc020299c:	00003697          	auipc	a3,0x3
ffffffffc02029a0:	81468693          	addi	a3,a3,-2028 # ffffffffc02051b0 <default_pmm_manager+0x4a8>
ffffffffc02029a4:	00002617          	auipc	a2,0x2
ffffffffc02029a8:	fb460613          	addi	a2,a2,-76 # ffffffffc0204958 <commands+0x818>
ffffffffc02029ac:	18a00593          	li	a1,394
ffffffffc02029b0:	00002517          	auipc	a0,0x2
ffffffffc02029b4:	4a850513          	addi	a0,a0,1192 # ffffffffc0204e58 <default_pmm_manager+0x150>
ffffffffc02029b8:	aa3fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(boot_pgdir_va[0] == 0);
ffffffffc02029bc:	00003697          	auipc	a3,0x3
ffffffffc02029c0:	8dc68693          	addi	a3,a3,-1828 # ffffffffc0205298 <default_pmm_manager+0x590>
ffffffffc02029c4:	00002617          	auipc	a2,0x2
ffffffffc02029c8:	f9460613          	addi	a2,a2,-108 # ffffffffc0204958 <commands+0x818>
ffffffffc02029cc:	1a800593          	li	a1,424
ffffffffc02029d0:	00002517          	auipc	a0,0x2
ffffffffc02029d4:	48850513          	addi	a0,a0,1160 # ffffffffc0204e58 <default_pmm_manager+0x150>
ffffffffc02029d8:	a83fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc02029dc:	00003697          	auipc	a3,0x3
ffffffffc02029e0:	81c68693          	addi	a3,a3,-2020 # ffffffffc02051f8 <default_pmm_manager+0x4f0>
ffffffffc02029e4:	00002617          	auipc	a2,0x2
ffffffffc02029e8:	f7460613          	addi	a2,a2,-140 # ffffffffc0204958 <commands+0x818>
ffffffffc02029ec:	19500593          	li	a1,405
ffffffffc02029f0:	00002517          	auipc	a0,0x2
ffffffffc02029f4:	46850513          	addi	a0,a0,1128 # ffffffffc0204e58 <default_pmm_manager+0x150>
ffffffffc02029f8:	a63fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p) == 1);
ffffffffc02029fc:	00003697          	auipc	a3,0x3
ffffffffc0202a00:	8f468693          	addi	a3,a3,-1804 # ffffffffc02052f0 <default_pmm_manager+0x5e8>
ffffffffc0202a04:	00002617          	auipc	a2,0x2
ffffffffc0202a08:	f5460613          	addi	a2,a2,-172 # ffffffffc0204958 <commands+0x818>
ffffffffc0202a0c:	1ad00593          	li	a1,429
ffffffffc0202a10:	00002517          	auipc	a0,0x2
ffffffffc0202a14:	44850513          	addi	a0,a0,1096 # ffffffffc0204e58 <default_pmm_manager+0x150>
ffffffffc0202a18:	a43fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202a1c:	00003697          	auipc	a3,0x3
ffffffffc0202a20:	89468693          	addi	a3,a3,-1900 # ffffffffc02052b0 <default_pmm_manager+0x5a8>
ffffffffc0202a24:	00002617          	auipc	a2,0x2
ffffffffc0202a28:	f3460613          	addi	a2,a2,-204 # ffffffffc0204958 <commands+0x818>
ffffffffc0202a2c:	1ac00593          	li	a1,428
ffffffffc0202a30:	00002517          	auipc	a0,0x2
ffffffffc0202a34:	42850513          	addi	a0,a0,1064 # ffffffffc0204e58 <default_pmm_manager+0x150>
ffffffffc0202a38:	a23fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202a3c:	00002697          	auipc	a3,0x2
ffffffffc0202a40:	74468693          	addi	a3,a3,1860 # ffffffffc0205180 <default_pmm_manager+0x478>
ffffffffc0202a44:	00002617          	auipc	a2,0x2
ffffffffc0202a48:	f1460613          	addi	a2,a2,-236 # ffffffffc0204958 <commands+0x818>
ffffffffc0202a4c:	18700593          	li	a1,391
ffffffffc0202a50:	00002517          	auipc	a0,0x2
ffffffffc0202a54:	40850513          	addi	a0,a0,1032 # ffffffffc0204e58 <default_pmm_manager+0x150>
ffffffffc0202a58:	a03fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0202a5c:	00002697          	auipc	a3,0x2
ffffffffc0202a60:	5c468693          	addi	a3,a3,1476 # ffffffffc0205020 <default_pmm_manager+0x318>
ffffffffc0202a64:	00002617          	auipc	a2,0x2
ffffffffc0202a68:	ef460613          	addi	a2,a2,-268 # ffffffffc0204958 <commands+0x818>
ffffffffc0202a6c:	18600593          	li	a1,390
ffffffffc0202a70:	00002517          	auipc	a0,0x2
ffffffffc0202a74:	3e850513          	addi	a0,a0,1000 # ffffffffc0204e58 <default_pmm_manager+0x150>
ffffffffc0202a78:	9e3fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202a7c:	00002697          	auipc	a3,0x2
ffffffffc0202a80:	71c68693          	addi	a3,a3,1820 # ffffffffc0205198 <default_pmm_manager+0x490>
ffffffffc0202a84:	00002617          	auipc	a2,0x2
ffffffffc0202a88:	ed460613          	addi	a2,a2,-300 # ffffffffc0204958 <commands+0x818>
ffffffffc0202a8c:	18300593          	li	a1,387
ffffffffc0202a90:	00002517          	auipc	a0,0x2
ffffffffc0202a94:	3c850513          	addi	a0,a0,968 # ffffffffc0204e58 <default_pmm_manager+0x150>
ffffffffc0202a98:	9c3fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0202a9c:	00002697          	auipc	a3,0x2
ffffffffc0202aa0:	56c68693          	addi	a3,a3,1388 # ffffffffc0205008 <default_pmm_manager+0x300>
ffffffffc0202aa4:	00002617          	auipc	a2,0x2
ffffffffc0202aa8:	eb460613          	addi	a2,a2,-332 # ffffffffc0204958 <commands+0x818>
ffffffffc0202aac:	18200593          	li	a1,386
ffffffffc0202ab0:	00002517          	auipc	a0,0x2
ffffffffc0202ab4:	3a850513          	addi	a0,a0,936 # ffffffffc0204e58 <default_pmm_manager+0x150>
ffffffffc0202ab8:	9a3fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202abc:	00002697          	auipc	a3,0x2
ffffffffc0202ac0:	5ec68693          	addi	a3,a3,1516 # ffffffffc02050a8 <default_pmm_manager+0x3a0>
ffffffffc0202ac4:	00002617          	auipc	a2,0x2
ffffffffc0202ac8:	e9460613          	addi	a2,a2,-364 # ffffffffc0204958 <commands+0x818>
ffffffffc0202acc:	18100593          	li	a1,385
ffffffffc0202ad0:	00002517          	auipc	a0,0x2
ffffffffc0202ad4:	38850513          	addi	a0,a0,904 # ffffffffc0204e58 <default_pmm_manager+0x150>
ffffffffc0202ad8:	983fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202adc:	00002697          	auipc	a3,0x2
ffffffffc0202ae0:	6a468693          	addi	a3,a3,1700 # ffffffffc0205180 <default_pmm_manager+0x478>
ffffffffc0202ae4:	00002617          	auipc	a2,0x2
ffffffffc0202ae8:	e7460613          	addi	a2,a2,-396 # ffffffffc0204958 <commands+0x818>
ffffffffc0202aec:	18000593          	li	a1,384
ffffffffc0202af0:	00002517          	auipc	a0,0x2
ffffffffc0202af4:	36850513          	addi	a0,a0,872 # ffffffffc0204e58 <default_pmm_manager+0x150>
ffffffffc0202af8:	963fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p1) == 2);
ffffffffc0202afc:	00002697          	auipc	a3,0x2
ffffffffc0202b00:	66c68693          	addi	a3,a3,1644 # ffffffffc0205168 <default_pmm_manager+0x460>
ffffffffc0202b04:	00002617          	auipc	a2,0x2
ffffffffc0202b08:	e5460613          	addi	a2,a2,-428 # ffffffffc0204958 <commands+0x818>
ffffffffc0202b0c:	17f00593          	li	a1,383
ffffffffc0202b10:	00002517          	auipc	a0,0x2
ffffffffc0202b14:	34850513          	addi	a0,a0,840 # ffffffffc0204e58 <default_pmm_manager+0x150>
ffffffffc0202b18:	943fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0202b1c:	00002697          	auipc	a3,0x2
ffffffffc0202b20:	61c68693          	addi	a3,a3,1564 # ffffffffc0205138 <default_pmm_manager+0x430>
ffffffffc0202b24:	00002617          	auipc	a2,0x2
ffffffffc0202b28:	e3460613          	addi	a2,a2,-460 # ffffffffc0204958 <commands+0x818>
ffffffffc0202b2c:	17e00593          	li	a1,382
ffffffffc0202b30:	00002517          	auipc	a0,0x2
ffffffffc0202b34:	32850513          	addi	a0,a0,808 # ffffffffc0204e58 <default_pmm_manager+0x150>
ffffffffc0202b38:	923fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p2) == 1);
ffffffffc0202b3c:	00002697          	auipc	a3,0x2
ffffffffc0202b40:	5e468693          	addi	a3,a3,1508 # ffffffffc0205120 <default_pmm_manager+0x418>
ffffffffc0202b44:	00002617          	auipc	a2,0x2
ffffffffc0202b48:	e1460613          	addi	a2,a2,-492 # ffffffffc0204958 <commands+0x818>
ffffffffc0202b4c:	17c00593          	li	a1,380
ffffffffc0202b50:	00002517          	auipc	a0,0x2
ffffffffc0202b54:	30850513          	addi	a0,a0,776 # ffffffffc0204e58 <default_pmm_manager+0x150>
ffffffffc0202b58:	903fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc0202b5c:	00002697          	auipc	a3,0x2
ffffffffc0202b60:	5a468693          	addi	a3,a3,1444 # ffffffffc0205100 <default_pmm_manager+0x3f8>
ffffffffc0202b64:	00002617          	auipc	a2,0x2
ffffffffc0202b68:	df460613          	addi	a2,a2,-524 # ffffffffc0204958 <commands+0x818>
ffffffffc0202b6c:	17b00593          	li	a1,379
ffffffffc0202b70:	00002517          	auipc	a0,0x2
ffffffffc0202b74:	2e850513          	addi	a0,a0,744 # ffffffffc0204e58 <default_pmm_manager+0x150>
ffffffffc0202b78:	8e3fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(*ptep & PTE_W);
ffffffffc0202b7c:	00002697          	auipc	a3,0x2
ffffffffc0202b80:	57468693          	addi	a3,a3,1396 # ffffffffc02050f0 <default_pmm_manager+0x3e8>
ffffffffc0202b84:	00002617          	auipc	a2,0x2
ffffffffc0202b88:	dd460613          	addi	a2,a2,-556 # ffffffffc0204958 <commands+0x818>
ffffffffc0202b8c:	17a00593          	li	a1,378
ffffffffc0202b90:	00002517          	auipc	a0,0x2
ffffffffc0202b94:	2c850513          	addi	a0,a0,712 # ffffffffc0204e58 <default_pmm_manager+0x150>
ffffffffc0202b98:	8c3fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(*ptep & PTE_U);
ffffffffc0202b9c:	00002697          	auipc	a3,0x2
ffffffffc0202ba0:	54468693          	addi	a3,a3,1348 # ffffffffc02050e0 <default_pmm_manager+0x3d8>
ffffffffc0202ba4:	00002617          	auipc	a2,0x2
ffffffffc0202ba8:	db460613          	addi	a2,a2,-588 # ffffffffc0204958 <commands+0x818>
ffffffffc0202bac:	17900593          	li	a1,377
ffffffffc0202bb0:	00002517          	auipc	a0,0x2
ffffffffc0202bb4:	2a850513          	addi	a0,a0,680 # ffffffffc0204e58 <default_pmm_manager+0x150>
ffffffffc0202bb8:	8a3fd0ef          	jal	ra,ffffffffc020045a <__panic>
        panic("DTB memory info not available");
ffffffffc0202bbc:	00002617          	auipc	a2,0x2
ffffffffc0202bc0:	2c460613          	addi	a2,a2,708 # ffffffffc0204e80 <default_pmm_manager+0x178>
ffffffffc0202bc4:	06400593          	li	a1,100
ffffffffc0202bc8:	00002517          	auipc	a0,0x2
ffffffffc0202bcc:	29050513          	addi	a0,a0,656 # ffffffffc0204e58 <default_pmm_manager+0x150>
ffffffffc0202bd0:	88bfd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0202bd4:	00002697          	auipc	a3,0x2
ffffffffc0202bd8:	62468693          	addi	a3,a3,1572 # ffffffffc02051f8 <default_pmm_manager+0x4f0>
ffffffffc0202bdc:	00002617          	auipc	a2,0x2
ffffffffc0202be0:	d7c60613          	addi	a2,a2,-644 # ffffffffc0204958 <commands+0x818>
ffffffffc0202be4:	1bf00593          	li	a1,447
ffffffffc0202be8:	00002517          	auipc	a0,0x2
ffffffffc0202bec:	27050513          	addi	a0,a0,624 # ffffffffc0204e58 <default_pmm_manager+0x150>
ffffffffc0202bf0:	86bfd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202bf4:	00002697          	auipc	a3,0x2
ffffffffc0202bf8:	4b468693          	addi	a3,a3,1204 # ffffffffc02050a8 <default_pmm_manager+0x3a0>
ffffffffc0202bfc:	00002617          	auipc	a2,0x2
ffffffffc0202c00:	d5c60613          	addi	a2,a2,-676 # ffffffffc0204958 <commands+0x818>
ffffffffc0202c04:	17800593          	li	a1,376
ffffffffc0202c08:	00002517          	auipc	a0,0x2
ffffffffc0202c0c:	25050513          	addi	a0,a0,592 # ffffffffc0204e58 <default_pmm_manager+0x150>
ffffffffc0202c10:	84bfd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0202c14:	00002697          	auipc	a3,0x2
ffffffffc0202c18:	45468693          	addi	a3,a3,1108 # ffffffffc0205068 <default_pmm_manager+0x360>
ffffffffc0202c1c:	00002617          	auipc	a2,0x2
ffffffffc0202c20:	d3c60613          	addi	a2,a2,-708 # ffffffffc0204958 <commands+0x818>
ffffffffc0202c24:	17700593          	li	a1,375
ffffffffc0202c28:	00002517          	auipc	a0,0x2
ffffffffc0202c2c:	23050513          	addi	a0,a0,560 # ffffffffc0204e58 <default_pmm_manager+0x150>
ffffffffc0202c30:	82bfd0ef          	jal	ra,ffffffffc020045a <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202c34:	86d6                	mv	a3,s5
ffffffffc0202c36:	00002617          	auipc	a2,0x2
ffffffffc0202c3a:	10a60613          	addi	a2,a2,266 # ffffffffc0204d40 <default_pmm_manager+0x38>
ffffffffc0202c3e:	17300593          	li	a1,371
ffffffffc0202c42:	00002517          	auipc	a0,0x2
ffffffffc0202c46:	21650513          	addi	a0,a0,534 # ffffffffc0204e58 <default_pmm_manager+0x150>
ffffffffc0202c4a:	811fd0ef          	jal	ra,ffffffffc020045a <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc0202c4e:	00002617          	auipc	a2,0x2
ffffffffc0202c52:	0f260613          	addi	a2,a2,242 # ffffffffc0204d40 <default_pmm_manager+0x38>
ffffffffc0202c56:	17200593          	li	a1,370
ffffffffc0202c5a:	00002517          	auipc	a0,0x2
ffffffffc0202c5e:	1fe50513          	addi	a0,a0,510 # ffffffffc0204e58 <default_pmm_manager+0x150>
ffffffffc0202c62:	ff8fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0202c66:	00002697          	auipc	a3,0x2
ffffffffc0202c6a:	3ba68693          	addi	a3,a3,954 # ffffffffc0205020 <default_pmm_manager+0x318>
ffffffffc0202c6e:	00002617          	auipc	a2,0x2
ffffffffc0202c72:	cea60613          	addi	a2,a2,-790 # ffffffffc0204958 <commands+0x818>
ffffffffc0202c76:	17000593          	li	a1,368
ffffffffc0202c7a:	00002517          	auipc	a0,0x2
ffffffffc0202c7e:	1de50513          	addi	a0,a0,478 # ffffffffc0204e58 <default_pmm_manager+0x150>
ffffffffc0202c82:	fd8fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0202c86:	00002697          	auipc	a3,0x2
ffffffffc0202c8a:	38268693          	addi	a3,a3,898 # ffffffffc0205008 <default_pmm_manager+0x300>
ffffffffc0202c8e:	00002617          	auipc	a2,0x2
ffffffffc0202c92:	cca60613          	addi	a2,a2,-822 # ffffffffc0204958 <commands+0x818>
ffffffffc0202c96:	16f00593          	li	a1,367
ffffffffc0202c9a:	00002517          	auipc	a0,0x2
ffffffffc0202c9e:	1be50513          	addi	a0,a0,446 # ffffffffc0204e58 <default_pmm_manager+0x150>
ffffffffc0202ca2:	fb8fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202ca6:	00002697          	auipc	a3,0x2
ffffffffc0202caa:	71268693          	addi	a3,a3,1810 # ffffffffc02053b8 <default_pmm_manager+0x6b0>
ffffffffc0202cae:	00002617          	auipc	a2,0x2
ffffffffc0202cb2:	caa60613          	addi	a2,a2,-854 # ffffffffc0204958 <commands+0x818>
ffffffffc0202cb6:	1b600593          	li	a1,438
ffffffffc0202cba:	00002517          	auipc	a0,0x2
ffffffffc0202cbe:	19e50513          	addi	a0,a0,414 # ffffffffc0204e58 <default_pmm_manager+0x150>
ffffffffc0202cc2:	f98fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202cc6:	00002697          	auipc	a3,0x2
ffffffffc0202cca:	6ba68693          	addi	a3,a3,1722 # ffffffffc0205380 <default_pmm_manager+0x678>
ffffffffc0202cce:	00002617          	auipc	a2,0x2
ffffffffc0202cd2:	c8a60613          	addi	a2,a2,-886 # ffffffffc0204958 <commands+0x818>
ffffffffc0202cd6:	1b300593          	li	a1,435
ffffffffc0202cda:	00002517          	auipc	a0,0x2
ffffffffc0202cde:	17e50513          	addi	a0,a0,382 # ffffffffc0204e58 <default_pmm_manager+0x150>
ffffffffc0202ce2:	f78fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p) == 2);
ffffffffc0202ce6:	00002697          	auipc	a3,0x2
ffffffffc0202cea:	66a68693          	addi	a3,a3,1642 # ffffffffc0205350 <default_pmm_manager+0x648>
ffffffffc0202cee:	00002617          	auipc	a2,0x2
ffffffffc0202cf2:	c6a60613          	addi	a2,a2,-918 # ffffffffc0204958 <commands+0x818>
ffffffffc0202cf6:	1af00593          	li	a1,431
ffffffffc0202cfa:	00002517          	auipc	a0,0x2
ffffffffc0202cfe:	15e50513          	addi	a0,a0,350 # ffffffffc0204e58 <default_pmm_manager+0x150>
ffffffffc0202d02:	f58fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202d06:	00002697          	auipc	a3,0x2
ffffffffc0202d0a:	60268693          	addi	a3,a3,1538 # ffffffffc0205308 <default_pmm_manager+0x600>
ffffffffc0202d0e:	00002617          	auipc	a2,0x2
ffffffffc0202d12:	c4a60613          	addi	a2,a2,-950 # ffffffffc0204958 <commands+0x818>
ffffffffc0202d16:	1ae00593          	li	a1,430
ffffffffc0202d1a:	00002517          	auipc	a0,0x2
ffffffffc0202d1e:	13e50513          	addi	a0,a0,318 # ffffffffc0204e58 <default_pmm_manager+0x150>
ffffffffc0202d22:	f38fd0ef          	jal	ra,ffffffffc020045a <__panic>
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc0202d26:	00002617          	auipc	a2,0x2
ffffffffc0202d2a:	0c260613          	addi	a2,a2,194 # ffffffffc0204de8 <default_pmm_manager+0xe0>
ffffffffc0202d2e:	0cb00593          	li	a1,203
ffffffffc0202d32:	00002517          	auipc	a0,0x2
ffffffffc0202d36:	12650513          	addi	a0,a0,294 # ffffffffc0204e58 <default_pmm_manager+0x150>
ffffffffc0202d3a:	f20fd0ef          	jal	ra,ffffffffc020045a <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202d3e:	00002617          	auipc	a2,0x2
ffffffffc0202d42:	0aa60613          	addi	a2,a2,170 # ffffffffc0204de8 <default_pmm_manager+0xe0>
ffffffffc0202d46:	08000593          	li	a1,128
ffffffffc0202d4a:	00002517          	auipc	a0,0x2
ffffffffc0202d4e:	10e50513          	addi	a0,a0,270 # ffffffffc0204e58 <default_pmm_manager+0x150>
ffffffffc0202d52:	f08fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc0202d56:	00002697          	auipc	a3,0x2
ffffffffc0202d5a:	28268693          	addi	a3,a3,642 # ffffffffc0204fd8 <default_pmm_manager+0x2d0>
ffffffffc0202d5e:	00002617          	auipc	a2,0x2
ffffffffc0202d62:	bfa60613          	addi	a2,a2,-1030 # ffffffffc0204958 <commands+0x818>
ffffffffc0202d66:	16e00593          	li	a1,366
ffffffffc0202d6a:	00002517          	auipc	a0,0x2
ffffffffc0202d6e:	0ee50513          	addi	a0,a0,238 # ffffffffc0204e58 <default_pmm_manager+0x150>
ffffffffc0202d72:	ee8fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0202d76:	00002697          	auipc	a3,0x2
ffffffffc0202d7a:	23268693          	addi	a3,a3,562 # ffffffffc0204fa8 <default_pmm_manager+0x2a0>
ffffffffc0202d7e:	00002617          	auipc	a2,0x2
ffffffffc0202d82:	bda60613          	addi	a2,a2,-1062 # ffffffffc0204958 <commands+0x818>
ffffffffc0202d86:	16b00593          	li	a1,363
ffffffffc0202d8a:	00002517          	auipc	a0,0x2
ffffffffc0202d8e:	0ce50513          	addi	a0,a0,206 # ffffffffc0204e58 <default_pmm_manager+0x150>
ffffffffc0202d92:	ec8fd0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0202d96 <check_vma_overlap.part.0>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0202d96:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc0202d98:	00002697          	auipc	a3,0x2
ffffffffc0202d9c:	66868693          	addi	a3,a3,1640 # ffffffffc0205400 <default_pmm_manager+0x6f8>
ffffffffc0202da0:	00002617          	auipc	a2,0x2
ffffffffc0202da4:	bb860613          	addi	a2,a2,-1096 # ffffffffc0204958 <commands+0x818>
ffffffffc0202da8:	08800593          	li	a1,136
ffffffffc0202dac:	00002517          	auipc	a0,0x2
ffffffffc0202db0:	67450513          	addi	a0,a0,1652 # ffffffffc0205420 <default_pmm_manager+0x718>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0202db4:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc0202db6:	ea4fd0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0202dba <find_vma>:
{
ffffffffc0202dba:	86aa                	mv	a3,a0
    if (mm != NULL)
ffffffffc0202dbc:	c505                	beqz	a0,ffffffffc0202de4 <find_vma+0x2a>
        vma = mm->mmap_cache;
ffffffffc0202dbe:	6908                	ld	a0,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0202dc0:	c501                	beqz	a0,ffffffffc0202dc8 <find_vma+0xe>
ffffffffc0202dc2:	651c                	ld	a5,8(a0)
ffffffffc0202dc4:	02f5f263          	bgeu	a1,a5,ffffffffc0202de8 <find_vma+0x2e>
    return listelm->next;
ffffffffc0202dc8:	669c                	ld	a5,8(a3)
            while ((le = list_next(le)) != list)
ffffffffc0202dca:	00f68d63          	beq	a3,a5,ffffffffc0202de4 <find_vma+0x2a>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc0202dce:	fe87b703          	ld	a4,-24(a5) # ffffffffc7ffffe8 <end+0x7df2afc>
ffffffffc0202dd2:	00e5e663          	bltu	a1,a4,ffffffffc0202dde <find_vma+0x24>
ffffffffc0202dd6:	ff07b703          	ld	a4,-16(a5)
ffffffffc0202dda:	00e5ec63          	bltu	a1,a4,ffffffffc0202df2 <find_vma+0x38>
ffffffffc0202dde:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc0202de0:	fef697e3          	bne	a3,a5,ffffffffc0202dce <find_vma+0x14>
    struct vma_struct *vma = NULL;
ffffffffc0202de4:	4501                	li	a0,0
}
ffffffffc0202de6:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0202de8:	691c                	ld	a5,16(a0)
ffffffffc0202dea:	fcf5ffe3          	bgeu	a1,a5,ffffffffc0202dc8 <find_vma+0xe>
            mm->mmap_cache = vma;
ffffffffc0202dee:	ea88                	sd	a0,16(a3)
ffffffffc0202df0:	8082                	ret
                vma = le2vma(le, list_link);
ffffffffc0202df2:	fe078513          	addi	a0,a5,-32
            mm->mmap_cache = vma;
ffffffffc0202df6:	ea88                	sd	a0,16(a3)
ffffffffc0202df8:	8082                	ret

ffffffffc0202dfa <insert_vma_struct>:
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc0202dfa:	6590                	ld	a2,8(a1)
ffffffffc0202dfc:	0105b803          	ld	a6,16(a1)
{
ffffffffc0202e00:	1141                	addi	sp,sp,-16
ffffffffc0202e02:	e406                	sd	ra,8(sp)
ffffffffc0202e04:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc0202e06:	01066763          	bltu	a2,a6,ffffffffc0202e14 <insert_vma_struct+0x1a>
ffffffffc0202e0a:	a085                	j	ffffffffc0202e6a <insert_vma_struct+0x70>

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0202e0c:	fe87b703          	ld	a4,-24(a5)
ffffffffc0202e10:	04e66863          	bltu	a2,a4,ffffffffc0202e60 <insert_vma_struct+0x66>
ffffffffc0202e14:	86be                	mv	a3,a5
ffffffffc0202e16:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != list)
ffffffffc0202e18:	fef51ae3          	bne	a0,a5,ffffffffc0202e0c <insert_vma_struct+0x12>
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
ffffffffc0202e1c:	02a68463          	beq	a3,a0,ffffffffc0202e44 <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc0202e20:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc0202e24:	fe86b883          	ld	a7,-24(a3)
ffffffffc0202e28:	08e8f163          	bgeu	a7,a4,ffffffffc0202eaa <insert_vma_struct+0xb0>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0202e2c:	04e66f63          	bltu	a2,a4,ffffffffc0202e8a <insert_vma_struct+0x90>
    }
    if (le_next != list)
ffffffffc0202e30:	00f50a63          	beq	a0,a5,ffffffffc0202e44 <insert_vma_struct+0x4a>
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0202e34:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc0202e38:	05076963          	bltu	a4,a6,ffffffffc0202e8a <insert_vma_struct+0x90>
    assert(next->vm_start < next->vm_end);
ffffffffc0202e3c:	ff07b603          	ld	a2,-16(a5)
ffffffffc0202e40:	02c77363          	bgeu	a4,a2,ffffffffc0202e66 <insert_vma_struct+0x6c>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
ffffffffc0202e44:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc0202e46:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc0202e48:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc0202e4c:	e390                	sd	a2,0(a5)
ffffffffc0202e4e:	e690                	sd	a2,8(a3)
}
ffffffffc0202e50:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc0202e52:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc0202e54:	f194                	sd	a3,32(a1)
    mm->map_count++;
ffffffffc0202e56:	0017079b          	addiw	a5,a4,1
ffffffffc0202e5a:	d11c                	sw	a5,32(a0)
}
ffffffffc0202e5c:	0141                	addi	sp,sp,16
ffffffffc0202e5e:	8082                	ret
    if (le_prev != list)
ffffffffc0202e60:	fca690e3          	bne	a3,a0,ffffffffc0202e20 <insert_vma_struct+0x26>
ffffffffc0202e64:	bfd1                	j	ffffffffc0202e38 <insert_vma_struct+0x3e>
ffffffffc0202e66:	f31ff0ef          	jal	ra,ffffffffc0202d96 <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc0202e6a:	00002697          	auipc	a3,0x2
ffffffffc0202e6e:	5c668693          	addi	a3,a3,1478 # ffffffffc0205430 <default_pmm_manager+0x728>
ffffffffc0202e72:	00002617          	auipc	a2,0x2
ffffffffc0202e76:	ae660613          	addi	a2,a2,-1306 # ffffffffc0204958 <commands+0x818>
ffffffffc0202e7a:	08e00593          	li	a1,142
ffffffffc0202e7e:	00002517          	auipc	a0,0x2
ffffffffc0202e82:	5a250513          	addi	a0,a0,1442 # ffffffffc0205420 <default_pmm_manager+0x718>
ffffffffc0202e86:	dd4fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0202e8a:	00002697          	auipc	a3,0x2
ffffffffc0202e8e:	5e668693          	addi	a3,a3,1510 # ffffffffc0205470 <default_pmm_manager+0x768>
ffffffffc0202e92:	00002617          	auipc	a2,0x2
ffffffffc0202e96:	ac660613          	addi	a2,a2,-1338 # ffffffffc0204958 <commands+0x818>
ffffffffc0202e9a:	08700593          	li	a1,135
ffffffffc0202e9e:	00002517          	auipc	a0,0x2
ffffffffc0202ea2:	58250513          	addi	a0,a0,1410 # ffffffffc0205420 <default_pmm_manager+0x718>
ffffffffc0202ea6:	db4fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc0202eaa:	00002697          	auipc	a3,0x2
ffffffffc0202eae:	5a668693          	addi	a3,a3,1446 # ffffffffc0205450 <default_pmm_manager+0x748>
ffffffffc0202eb2:	00002617          	auipc	a2,0x2
ffffffffc0202eb6:	aa660613          	addi	a2,a2,-1370 # ffffffffc0204958 <commands+0x818>
ffffffffc0202eba:	08600593          	li	a1,134
ffffffffc0202ebe:	00002517          	auipc	a0,0x2
ffffffffc0202ec2:	56250513          	addi	a0,a0,1378 # ffffffffc0205420 <default_pmm_manager+0x718>
ffffffffc0202ec6:	d94fd0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0202eca <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
ffffffffc0202eca:	7139                	addi	sp,sp,-64
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0202ecc:	03000513          	li	a0,48
{
ffffffffc0202ed0:	fc06                	sd	ra,56(sp)
ffffffffc0202ed2:	f822                	sd	s0,48(sp)
ffffffffc0202ed4:	f426                	sd	s1,40(sp)
ffffffffc0202ed6:	f04a                	sd	s2,32(sp)
ffffffffc0202ed8:	ec4e                	sd	s3,24(sp)
ffffffffc0202eda:	e852                	sd	s4,16(sp)
ffffffffc0202edc:	e456                	sd	s5,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0202ede:	bd5fe0ef          	jal	ra,ffffffffc0201ab2 <kmalloc>
    if (mm != NULL)
ffffffffc0202ee2:	2e050f63          	beqz	a0,ffffffffc02031e0 <vmm_init+0x316>
ffffffffc0202ee6:	84aa                	mv	s1,a0
    elm->prev = elm->next = elm;
ffffffffc0202ee8:	e508                	sd	a0,8(a0)
ffffffffc0202eea:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0202eec:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0202ef0:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0202ef4:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0202ef8:	02053423          	sd	zero,40(a0)
ffffffffc0202efc:	03200413          	li	s0,50
ffffffffc0202f00:	a811                	j	ffffffffc0202f14 <vmm_init+0x4a>
        vma->vm_start = vm_start;
ffffffffc0202f02:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0202f04:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0202f06:	00052c23          	sw	zero,24(a0)
    assert(mm != NULL);

    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i--)
ffffffffc0202f0a:	146d                	addi	s0,s0,-5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0202f0c:	8526                	mv	a0,s1
ffffffffc0202f0e:	eedff0ef          	jal	ra,ffffffffc0202dfa <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc0202f12:	c80d                	beqz	s0,ffffffffc0202f44 <vmm_init+0x7a>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0202f14:	03000513          	li	a0,48
ffffffffc0202f18:	b9bfe0ef          	jal	ra,ffffffffc0201ab2 <kmalloc>
ffffffffc0202f1c:	85aa                	mv	a1,a0
ffffffffc0202f1e:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc0202f22:	f165                	bnez	a0,ffffffffc0202f02 <vmm_init+0x38>
        assert(vma != NULL);
ffffffffc0202f24:	00002697          	auipc	a3,0x2
ffffffffc0202f28:	6e468693          	addi	a3,a3,1764 # ffffffffc0205608 <default_pmm_manager+0x900>
ffffffffc0202f2c:	00002617          	auipc	a2,0x2
ffffffffc0202f30:	a2c60613          	addi	a2,a2,-1492 # ffffffffc0204958 <commands+0x818>
ffffffffc0202f34:	0da00593          	li	a1,218
ffffffffc0202f38:	00002517          	auipc	a0,0x2
ffffffffc0202f3c:	4e850513          	addi	a0,a0,1256 # ffffffffc0205420 <default_pmm_manager+0x718>
ffffffffc0202f40:	d1afd0ef          	jal	ra,ffffffffc020045a <__panic>
ffffffffc0202f44:	03700413          	li	s0,55
    }

    for (i = step1 + 1; i <= step2; i++)
ffffffffc0202f48:	1f900913          	li	s2,505
ffffffffc0202f4c:	a819                	j	ffffffffc0202f62 <vmm_init+0x98>
        vma->vm_start = vm_start;
ffffffffc0202f4e:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0202f50:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0202f52:	00052c23          	sw	zero,24(a0)
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0202f56:	0415                	addi	s0,s0,5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0202f58:	8526                	mv	a0,s1
ffffffffc0202f5a:	ea1ff0ef          	jal	ra,ffffffffc0202dfa <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0202f5e:	03240a63          	beq	s0,s2,ffffffffc0202f92 <vmm_init+0xc8>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0202f62:	03000513          	li	a0,48
ffffffffc0202f66:	b4dfe0ef          	jal	ra,ffffffffc0201ab2 <kmalloc>
ffffffffc0202f6a:	85aa                	mv	a1,a0
ffffffffc0202f6c:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc0202f70:	fd79                	bnez	a0,ffffffffc0202f4e <vmm_init+0x84>
        assert(vma != NULL);
ffffffffc0202f72:	00002697          	auipc	a3,0x2
ffffffffc0202f76:	69668693          	addi	a3,a3,1686 # ffffffffc0205608 <default_pmm_manager+0x900>
ffffffffc0202f7a:	00002617          	auipc	a2,0x2
ffffffffc0202f7e:	9de60613          	addi	a2,a2,-1570 # ffffffffc0204958 <commands+0x818>
ffffffffc0202f82:	0e100593          	li	a1,225
ffffffffc0202f86:	00002517          	auipc	a0,0x2
ffffffffc0202f8a:	49a50513          	addi	a0,a0,1178 # ffffffffc0205420 <default_pmm_manager+0x718>
ffffffffc0202f8e:	cccfd0ef          	jal	ra,ffffffffc020045a <__panic>
    return listelm->next;
ffffffffc0202f92:	649c                	ld	a5,8(s1)
ffffffffc0202f94:	471d                	li	a4,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
ffffffffc0202f96:	1fb00593          	li	a1,507
    {
        assert(le != &(mm->mmap_list));
ffffffffc0202f9a:	18f48363          	beq	s1,a5,ffffffffc0203120 <vmm_init+0x256>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0202f9e:	fe87b603          	ld	a2,-24(a5)
ffffffffc0202fa2:	ffe70693          	addi	a3,a4,-2 # ffe <kern_entry-0xffffffffc01ff002>
ffffffffc0202fa6:	10d61d63          	bne	a2,a3,ffffffffc02030c0 <vmm_init+0x1f6>
ffffffffc0202faa:	ff07b683          	ld	a3,-16(a5)
ffffffffc0202fae:	10e69963          	bne	a3,a4,ffffffffc02030c0 <vmm_init+0x1f6>
    for (i = 1; i <= step2; i++)
ffffffffc0202fb2:	0715                	addi	a4,a4,5
ffffffffc0202fb4:	679c                	ld	a5,8(a5)
ffffffffc0202fb6:	feb712e3          	bne	a4,a1,ffffffffc0202f9a <vmm_init+0xd0>
ffffffffc0202fba:	4a1d                	li	s4,7
ffffffffc0202fbc:	4415                	li	s0,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0202fbe:	1f900a93          	li	s5,505
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0202fc2:	85a2                	mv	a1,s0
ffffffffc0202fc4:	8526                	mv	a0,s1
ffffffffc0202fc6:	df5ff0ef          	jal	ra,ffffffffc0202dba <find_vma>
ffffffffc0202fca:	892a                	mv	s2,a0
        assert(vma1 != NULL);
ffffffffc0202fcc:	18050a63          	beqz	a0,ffffffffc0203160 <vmm_init+0x296>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc0202fd0:	00140593          	addi	a1,s0,1
ffffffffc0202fd4:	8526                	mv	a0,s1
ffffffffc0202fd6:	de5ff0ef          	jal	ra,ffffffffc0202dba <find_vma>
ffffffffc0202fda:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc0202fdc:	16050263          	beqz	a0,ffffffffc0203140 <vmm_init+0x276>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc0202fe0:	85d2                	mv	a1,s4
ffffffffc0202fe2:	8526                	mv	a0,s1
ffffffffc0202fe4:	dd7ff0ef          	jal	ra,ffffffffc0202dba <find_vma>
        assert(vma3 == NULL);
ffffffffc0202fe8:	18051c63          	bnez	a0,ffffffffc0203180 <vmm_init+0x2b6>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc0202fec:	00340593          	addi	a1,s0,3
ffffffffc0202ff0:	8526                	mv	a0,s1
ffffffffc0202ff2:	dc9ff0ef          	jal	ra,ffffffffc0202dba <find_vma>
        assert(vma4 == NULL);
ffffffffc0202ff6:	1c051563          	bnez	a0,ffffffffc02031c0 <vmm_init+0x2f6>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc0202ffa:	00440593          	addi	a1,s0,4
ffffffffc0202ffe:	8526                	mv	a0,s1
ffffffffc0203000:	dbbff0ef          	jal	ra,ffffffffc0202dba <find_vma>
        assert(vma5 == NULL);
ffffffffc0203004:	18051e63          	bnez	a0,ffffffffc02031a0 <vmm_init+0x2d6>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203008:	00893783          	ld	a5,8(s2)
ffffffffc020300c:	0c879a63          	bne	a5,s0,ffffffffc02030e0 <vmm_init+0x216>
ffffffffc0203010:	01093783          	ld	a5,16(s2)
ffffffffc0203014:	0d479663          	bne	a5,s4,ffffffffc02030e0 <vmm_init+0x216>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203018:	0089b783          	ld	a5,8(s3)
ffffffffc020301c:	0e879263          	bne	a5,s0,ffffffffc0203100 <vmm_init+0x236>
ffffffffc0203020:	0109b783          	ld	a5,16(s3)
ffffffffc0203024:	0d479e63          	bne	a5,s4,ffffffffc0203100 <vmm_init+0x236>
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203028:	0415                	addi	s0,s0,5
ffffffffc020302a:	0a15                	addi	s4,s4,5
ffffffffc020302c:	f9541be3          	bne	s0,s5,ffffffffc0202fc2 <vmm_init+0xf8>
ffffffffc0203030:	4411                	li	s0,4
    }

    for (i = 4; i >= 0; i--)
ffffffffc0203032:	597d                	li	s2,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc0203034:	85a2                	mv	a1,s0
ffffffffc0203036:	8526                	mv	a0,s1
ffffffffc0203038:	d83ff0ef          	jal	ra,ffffffffc0202dba <find_vma>
ffffffffc020303c:	0004059b          	sext.w	a1,s0
        if (vma_below_5 != NULL)
ffffffffc0203040:	c90d                	beqz	a0,ffffffffc0203072 <vmm_init+0x1a8>
        {
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc0203042:	6914                	ld	a3,16(a0)
ffffffffc0203044:	6510                	ld	a2,8(a0)
ffffffffc0203046:	00002517          	auipc	a0,0x2
ffffffffc020304a:	54a50513          	addi	a0,a0,1354 # ffffffffc0205590 <default_pmm_manager+0x888>
ffffffffc020304e:	946fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc0203052:	00002697          	auipc	a3,0x2
ffffffffc0203056:	56668693          	addi	a3,a3,1382 # ffffffffc02055b8 <default_pmm_manager+0x8b0>
ffffffffc020305a:	00002617          	auipc	a2,0x2
ffffffffc020305e:	8fe60613          	addi	a2,a2,-1794 # ffffffffc0204958 <commands+0x818>
ffffffffc0203062:	10700593          	li	a1,263
ffffffffc0203066:	00002517          	auipc	a0,0x2
ffffffffc020306a:	3ba50513          	addi	a0,a0,954 # ffffffffc0205420 <default_pmm_manager+0x718>
ffffffffc020306e:	becfd0ef          	jal	ra,ffffffffc020045a <__panic>
    for (i = 4; i >= 0; i--)
ffffffffc0203072:	147d                	addi	s0,s0,-1
ffffffffc0203074:	fd2410e3          	bne	s0,s2,ffffffffc0203034 <vmm_init+0x16a>
ffffffffc0203078:	6488                	ld	a0,8(s1)
    while ((le = list_next(list)) != list)
ffffffffc020307a:	00a48c63          	beq	s1,a0,ffffffffc0203092 <vmm_init+0x1c8>
    __list_del(listelm->prev, listelm->next);
ffffffffc020307e:	6118                	ld	a4,0(a0)
ffffffffc0203080:	651c                	ld	a5,8(a0)
        kfree(le2vma(le, list_link)); // kfree vma
ffffffffc0203082:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc0203084:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0203086:	e398                	sd	a4,0(a5)
ffffffffc0203088:	adbfe0ef          	jal	ra,ffffffffc0201b62 <kfree>
    return listelm->next;
ffffffffc020308c:	6488                	ld	a0,8(s1)
    while ((le = list_next(list)) != list)
ffffffffc020308e:	fea498e3          	bne	s1,a0,ffffffffc020307e <vmm_init+0x1b4>
    kfree(mm); // kfree mm
ffffffffc0203092:	8526                	mv	a0,s1
ffffffffc0203094:	acffe0ef          	jal	ra,ffffffffc0201b62 <kfree>
    }

    mm_destroy(mm);

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0203098:	00002517          	auipc	a0,0x2
ffffffffc020309c:	53850513          	addi	a0,a0,1336 # ffffffffc02055d0 <default_pmm_manager+0x8c8>
ffffffffc02030a0:	8f4fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
}
ffffffffc02030a4:	7442                	ld	s0,48(sp)
ffffffffc02030a6:	70e2                	ld	ra,56(sp)
ffffffffc02030a8:	74a2                	ld	s1,40(sp)
ffffffffc02030aa:	7902                	ld	s2,32(sp)
ffffffffc02030ac:	69e2                	ld	s3,24(sp)
ffffffffc02030ae:	6a42                	ld	s4,16(sp)
ffffffffc02030b0:	6aa2                	ld	s5,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc02030b2:	00002517          	auipc	a0,0x2
ffffffffc02030b6:	53e50513          	addi	a0,a0,1342 # ffffffffc02055f0 <default_pmm_manager+0x8e8>
}
ffffffffc02030ba:	6121                	addi	sp,sp,64
    cprintf("check_vmm() succeeded.\n");
ffffffffc02030bc:	8d8fd06f          	j	ffffffffc0200194 <cprintf>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc02030c0:	00002697          	auipc	a3,0x2
ffffffffc02030c4:	3e868693          	addi	a3,a3,1000 # ffffffffc02054a8 <default_pmm_manager+0x7a0>
ffffffffc02030c8:	00002617          	auipc	a2,0x2
ffffffffc02030cc:	89060613          	addi	a2,a2,-1904 # ffffffffc0204958 <commands+0x818>
ffffffffc02030d0:	0eb00593          	li	a1,235
ffffffffc02030d4:	00002517          	auipc	a0,0x2
ffffffffc02030d8:	34c50513          	addi	a0,a0,844 # ffffffffc0205420 <default_pmm_manager+0x718>
ffffffffc02030dc:	b7efd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc02030e0:	00002697          	auipc	a3,0x2
ffffffffc02030e4:	45068693          	addi	a3,a3,1104 # ffffffffc0205530 <default_pmm_manager+0x828>
ffffffffc02030e8:	00002617          	auipc	a2,0x2
ffffffffc02030ec:	87060613          	addi	a2,a2,-1936 # ffffffffc0204958 <commands+0x818>
ffffffffc02030f0:	0fc00593          	li	a1,252
ffffffffc02030f4:	00002517          	auipc	a0,0x2
ffffffffc02030f8:	32c50513          	addi	a0,a0,812 # ffffffffc0205420 <default_pmm_manager+0x718>
ffffffffc02030fc:	b5efd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203100:	00002697          	auipc	a3,0x2
ffffffffc0203104:	46068693          	addi	a3,a3,1120 # ffffffffc0205560 <default_pmm_manager+0x858>
ffffffffc0203108:	00002617          	auipc	a2,0x2
ffffffffc020310c:	85060613          	addi	a2,a2,-1968 # ffffffffc0204958 <commands+0x818>
ffffffffc0203110:	0fd00593          	li	a1,253
ffffffffc0203114:	00002517          	auipc	a0,0x2
ffffffffc0203118:	30c50513          	addi	a0,a0,780 # ffffffffc0205420 <default_pmm_manager+0x718>
ffffffffc020311c:	b3efd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc0203120:	00002697          	auipc	a3,0x2
ffffffffc0203124:	37068693          	addi	a3,a3,880 # ffffffffc0205490 <default_pmm_manager+0x788>
ffffffffc0203128:	00002617          	auipc	a2,0x2
ffffffffc020312c:	83060613          	addi	a2,a2,-2000 # ffffffffc0204958 <commands+0x818>
ffffffffc0203130:	0e900593          	li	a1,233
ffffffffc0203134:	00002517          	auipc	a0,0x2
ffffffffc0203138:	2ec50513          	addi	a0,a0,748 # ffffffffc0205420 <default_pmm_manager+0x718>
ffffffffc020313c:	b1efd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(vma2 != NULL);
ffffffffc0203140:	00002697          	auipc	a3,0x2
ffffffffc0203144:	3b068693          	addi	a3,a3,944 # ffffffffc02054f0 <default_pmm_manager+0x7e8>
ffffffffc0203148:	00002617          	auipc	a2,0x2
ffffffffc020314c:	81060613          	addi	a2,a2,-2032 # ffffffffc0204958 <commands+0x818>
ffffffffc0203150:	0f400593          	li	a1,244
ffffffffc0203154:	00002517          	auipc	a0,0x2
ffffffffc0203158:	2cc50513          	addi	a0,a0,716 # ffffffffc0205420 <default_pmm_manager+0x718>
ffffffffc020315c:	afefd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(vma1 != NULL);
ffffffffc0203160:	00002697          	auipc	a3,0x2
ffffffffc0203164:	38068693          	addi	a3,a3,896 # ffffffffc02054e0 <default_pmm_manager+0x7d8>
ffffffffc0203168:	00001617          	auipc	a2,0x1
ffffffffc020316c:	7f060613          	addi	a2,a2,2032 # ffffffffc0204958 <commands+0x818>
ffffffffc0203170:	0f200593          	li	a1,242
ffffffffc0203174:	00002517          	auipc	a0,0x2
ffffffffc0203178:	2ac50513          	addi	a0,a0,684 # ffffffffc0205420 <default_pmm_manager+0x718>
ffffffffc020317c:	adefd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(vma3 == NULL);
ffffffffc0203180:	00002697          	auipc	a3,0x2
ffffffffc0203184:	38068693          	addi	a3,a3,896 # ffffffffc0205500 <default_pmm_manager+0x7f8>
ffffffffc0203188:	00001617          	auipc	a2,0x1
ffffffffc020318c:	7d060613          	addi	a2,a2,2000 # ffffffffc0204958 <commands+0x818>
ffffffffc0203190:	0f600593          	li	a1,246
ffffffffc0203194:	00002517          	auipc	a0,0x2
ffffffffc0203198:	28c50513          	addi	a0,a0,652 # ffffffffc0205420 <default_pmm_manager+0x718>
ffffffffc020319c:	abefd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(vma5 == NULL);
ffffffffc02031a0:	00002697          	auipc	a3,0x2
ffffffffc02031a4:	38068693          	addi	a3,a3,896 # ffffffffc0205520 <default_pmm_manager+0x818>
ffffffffc02031a8:	00001617          	auipc	a2,0x1
ffffffffc02031ac:	7b060613          	addi	a2,a2,1968 # ffffffffc0204958 <commands+0x818>
ffffffffc02031b0:	0fa00593          	li	a1,250
ffffffffc02031b4:	00002517          	auipc	a0,0x2
ffffffffc02031b8:	26c50513          	addi	a0,a0,620 # ffffffffc0205420 <default_pmm_manager+0x718>
ffffffffc02031bc:	a9efd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(vma4 == NULL);
ffffffffc02031c0:	00002697          	auipc	a3,0x2
ffffffffc02031c4:	35068693          	addi	a3,a3,848 # ffffffffc0205510 <default_pmm_manager+0x808>
ffffffffc02031c8:	00001617          	auipc	a2,0x1
ffffffffc02031cc:	79060613          	addi	a2,a2,1936 # ffffffffc0204958 <commands+0x818>
ffffffffc02031d0:	0f800593          	li	a1,248
ffffffffc02031d4:	00002517          	auipc	a0,0x2
ffffffffc02031d8:	24c50513          	addi	a0,a0,588 # ffffffffc0205420 <default_pmm_manager+0x718>
ffffffffc02031dc:	a7efd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(mm != NULL);
ffffffffc02031e0:	00002697          	auipc	a3,0x2
ffffffffc02031e4:	43868693          	addi	a3,a3,1080 # ffffffffc0205618 <default_pmm_manager+0x910>
ffffffffc02031e8:	00001617          	auipc	a2,0x1
ffffffffc02031ec:	77060613          	addi	a2,a2,1904 # ffffffffc0204958 <commands+0x818>
ffffffffc02031f0:	0d200593          	li	a1,210
ffffffffc02031f4:	00002517          	auipc	a0,0x2
ffffffffc02031f8:	22c50513          	addi	a0,a0,556 # ffffffffc0205420 <default_pmm_manager+0x718>
ffffffffc02031fc:	a5efd0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0203200 <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc0203200:	8526                	mv	a0,s1
	jalr s0
ffffffffc0203202:	9402                	jalr	s0

	jal do_exit
ffffffffc0203204:	400000ef          	jal	ra,ffffffffc0203604 <do_exit>

ffffffffc0203208 <alloc_proc>:
void switch_to(struct context *from, struct context *to); //switch.S

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void)
{
ffffffffc0203208:	1141                	addi	sp,sp,-16
    // LAB4:EXERCISE2 /*解子萱 2312585 、崔颖欣 2311136 、范鼎辉 2312326*/
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc020320a:	0e800513          	li	a0,232
{
ffffffffc020320e:	e022                	sd	s0,0(sp)
ffffffffc0203210:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203212:	8a1fe0ef          	jal	ra,ffffffffc0201ab2 <kmalloc>
ffffffffc0203216:	842a                	mv	s0,a0
    if (proc != NULL)
ffffffffc0203218:	c521                	beqz	a0,ffffffffc0203260 <alloc_proc+0x58>
    {
        proc->state = PROC_UNINIT;  // 进程状态
ffffffffc020321a:	57fd                	li	a5,-1
ffffffffc020321c:	1782                	slli	a5,a5,0x20
ffffffffc020321e:	e11c                	sd	a5,0(a0)
        proc->runs = 0;  // 运行次数
        proc->kstack = 0;  // 内核栈
        proc->need_resched = 0;  // 是否需要重新调度
        proc->parent = NULL;  // 父进程
        proc->mm = NULL;  // 内存管理
        memset(&(proc->context), 0, sizeof(struct context));  // 上下文
ffffffffc0203220:	07000613          	li	a2,112
ffffffffc0203224:	4581                	li	a1,0
        proc->runs = 0;  // 运行次数
ffffffffc0203226:	00052423          	sw	zero,8(a0)
        proc->kstack = 0;  // 内核栈
ffffffffc020322a:	00053823          	sd	zero,16(a0)
        proc->need_resched = 0;  // 是否需要重新调度
ffffffffc020322e:	00052c23          	sw	zero,24(a0)
        proc->parent = NULL;  // 父进程
ffffffffc0203232:	02053023          	sd	zero,32(a0)
        proc->mm = NULL;  // 内存管理
ffffffffc0203236:	02053423          	sd	zero,40(a0)
        memset(&(proc->context), 0, sizeof(struct context));  // 上下文
ffffffffc020323a:	03050513          	addi	a0,a0,48
ffffffffc020323e:	44b000ef          	jal	ra,ffffffffc0203e88 <memset>
        proc->tf = NULL;  // 陷阱帧
        proc->pgdir = boot_pgdir_pa;  // 页表基址
ffffffffc0203242:	0000a797          	auipc	a5,0xa
ffffffffc0203246:	25e7b783          	ld	a5,606(a5) # ffffffffc020d4a0 <boot_pgdir_pa>
        proc->tf = NULL;  // 陷阱帧
ffffffffc020324a:	0a043023          	sd	zero,160(s0)
        proc->pgdir = boot_pgdir_pa;  // 页表基址
ffffffffc020324e:	f45c                	sd	a5,168(s0)
        proc->flags = 0;  // 标志位
ffffffffc0203250:	0a042823          	sw	zero,176(s0)
        memset(proc->name, 0, sizeof(proc->name));  // 进程名
ffffffffc0203254:	4641                	li	a2,16
ffffffffc0203256:	4581                	li	a1,0
ffffffffc0203258:	0b440513          	addi	a0,s0,180
ffffffffc020325c:	42d000ef          	jal	ra,ffffffffc0203e88 <memset>
    }
    return proc;
}
ffffffffc0203260:	60a2                	ld	ra,8(sp)
ffffffffc0203262:	8522                	mv	a0,s0
ffffffffc0203264:	6402                	ld	s0,0(sp)
ffffffffc0203266:	0141                	addi	sp,sp,16
ffffffffc0203268:	8082                	ret

ffffffffc020326a <forkret>:
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void)
{
    forkrets(current->tf);
ffffffffc020326a:	0000a797          	auipc	a5,0xa
ffffffffc020326e:	2667b783          	ld	a5,614(a5) # ffffffffc020d4d0 <current>
ffffffffc0203272:	73c8                	ld	a0,160(a5)
ffffffffc0203274:	b5dfd06f          	j	ffffffffc0200dd0 <forkrets>

ffffffffc0203278 <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg)
{
ffffffffc0203278:	7179                	addi	sp,sp,-48
ffffffffc020327a:	ec26                	sd	s1,24(sp)
    memset(name, 0, sizeof(name));
ffffffffc020327c:	0000a497          	auipc	s1,0xa
ffffffffc0203280:	1cc48493          	addi	s1,s1,460 # ffffffffc020d448 <name.2>
{
ffffffffc0203284:	f022                	sd	s0,32(sp)
ffffffffc0203286:	e84a                	sd	s2,16(sp)
ffffffffc0203288:	842a                	mv	s0,a0
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc020328a:	0000a917          	auipc	s2,0xa
ffffffffc020328e:	24693903          	ld	s2,582(s2) # ffffffffc020d4d0 <current>
    memset(name, 0, sizeof(name));
ffffffffc0203292:	4641                	li	a2,16
ffffffffc0203294:	4581                	li	a1,0
ffffffffc0203296:	8526                	mv	a0,s1
{
ffffffffc0203298:	f406                	sd	ra,40(sp)
ffffffffc020329a:	e44e                	sd	s3,8(sp)
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc020329c:	00492983          	lw	s3,4(s2)
    memset(name, 0, sizeof(name));
ffffffffc02032a0:	3e9000ef          	jal	ra,ffffffffc0203e88 <memset>
    return memcpy(name, proc->name, PROC_NAME_LEN);
ffffffffc02032a4:	0b490593          	addi	a1,s2,180
ffffffffc02032a8:	463d                	li	a2,15
ffffffffc02032aa:	8526                	mv	a0,s1
ffffffffc02032ac:	3ef000ef          	jal	ra,ffffffffc0203e9a <memcpy>
ffffffffc02032b0:	862a                	mv	a2,a0
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc02032b2:	85ce                	mv	a1,s3
ffffffffc02032b4:	00002517          	auipc	a0,0x2
ffffffffc02032b8:	37450513          	addi	a0,a0,884 # ffffffffc0205628 <default_pmm_manager+0x920>
ffffffffc02032bc:	ed9fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("To U: \"%s\".\n", (const char *)arg);
ffffffffc02032c0:	85a2                	mv	a1,s0
ffffffffc02032c2:	00002517          	auipc	a0,0x2
ffffffffc02032c6:	38e50513          	addi	a0,a0,910 # ffffffffc0205650 <default_pmm_manager+0x948>
ffffffffc02032ca:	ecbfc0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("To U: \"en.., Bye, Bye. :)\"\n");
ffffffffc02032ce:	00002517          	auipc	a0,0x2
ffffffffc02032d2:	39250513          	addi	a0,a0,914 # ffffffffc0205660 <default_pmm_manager+0x958>
ffffffffc02032d6:	ebffc0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return 0;
}
ffffffffc02032da:	70a2                	ld	ra,40(sp)
ffffffffc02032dc:	7402                	ld	s0,32(sp)
ffffffffc02032de:	64e2                	ld	s1,24(sp)
ffffffffc02032e0:	6942                	ld	s2,16(sp)
ffffffffc02032e2:	69a2                	ld	s3,8(sp)
ffffffffc02032e4:	4501                	li	a0,0
ffffffffc02032e6:	6145                	addi	sp,sp,48
ffffffffc02032e8:	8082                	ret

ffffffffc02032ea <proc_run>:
{
ffffffffc02032ea:	7179                	addi	sp,sp,-48
ffffffffc02032ec:	f026                	sd	s1,32(sp)
    if (proc != current)
ffffffffc02032ee:	0000a497          	auipc	s1,0xa
ffffffffc02032f2:	1e248493          	addi	s1,s1,482 # ffffffffc020d4d0 <current>
ffffffffc02032f6:	6098                	ld	a4,0(s1)
{
ffffffffc02032f8:	f406                	sd	ra,40(sp)
ffffffffc02032fa:	ec4a                	sd	s2,24(sp)
    if (proc != current)
ffffffffc02032fc:	02a70863          	beq	a4,a0,ffffffffc020332c <proc_run+0x42>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0203300:	100027f3          	csrr	a5,sstatus
ffffffffc0203304:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0203306:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0203308:	ef8d                	bnez	a5,ffffffffc0203342 <proc_run+0x58>
        lsatp(proc->pgdir); 
ffffffffc020330a:	755c                	ld	a5,168(a0)
#define barrier() __asm__ __volatile__("fence" ::: "memory")

static inline void
lsatp(unsigned int pgdir)
{
  write_csr(satp, SATP32_MODE | (pgdir >> RISCV_PGSHIFT));
ffffffffc020330c:	800006b7          	lui	a3,0x80000
        current = proc; //再把 current 指向目标 proc，这样后面 switch_to 才知道从谁切到谁：
ffffffffc0203310:	e088                	sd	a0,0(s1)
ffffffffc0203312:	00c7d79b          	srliw	a5,a5,0xc
ffffffffc0203316:	8fd5                	or	a5,a5,a3
ffffffffc0203318:	18079073          	csrw	satp,a5
        switch_to(&(prev->context), &(proc->context));  
ffffffffc020331c:	03050593          	addi	a1,a0,48
ffffffffc0203320:	03070513          	addi	a0,a4,48
ffffffffc0203324:	58e000ef          	jal	ra,ffffffffc02038b2 <switch_to>
    if (flag) {
ffffffffc0203328:	00091763          	bnez	s2,ffffffffc0203336 <proc_run+0x4c>
}
ffffffffc020332c:	70a2                	ld	ra,40(sp)
ffffffffc020332e:	7482                	ld	s1,32(sp)
ffffffffc0203330:	6962                	ld	s2,24(sp)
ffffffffc0203332:	6145                	addi	sp,sp,48
ffffffffc0203334:	8082                	ret
ffffffffc0203336:	70a2                	ld	ra,40(sp)
ffffffffc0203338:	7482                	ld	s1,32(sp)
ffffffffc020333a:	6962                	ld	s2,24(sp)
ffffffffc020333c:	6145                	addi	sp,sp,48
        intr_enable();
ffffffffc020333e:	decfd06f          	j	ffffffffc020092a <intr_enable>
ffffffffc0203342:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0203344:	decfd0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        struct proc_struct *prev = current; //然后保存老进程，切到新进程，把 current 先保存成 prev，
ffffffffc0203348:	6098                	ld	a4,0(s1)
        return 1;
ffffffffc020334a:	6522                	ld	a0,8(sp)
ffffffffc020334c:	4905                	li	s2,1
ffffffffc020334e:	bf75                	j	ffffffffc020330a <proc_run+0x20>

ffffffffc0203350 <do_fork>:
{
ffffffffc0203350:	7179                	addi	sp,sp,-48
ffffffffc0203352:	ec26                	sd	s1,24(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc0203354:	0000a497          	auipc	s1,0xa
ffffffffc0203358:	19448493          	addi	s1,s1,404 # ffffffffc020d4e8 <nr_process>
ffffffffc020335c:	4098                	lw	a4,0(s1)
{
ffffffffc020335e:	f406                	sd	ra,40(sp)
ffffffffc0203360:	f022                	sd	s0,32(sp)
ffffffffc0203362:	e84a                	sd	s2,16(sp)
ffffffffc0203364:	e44e                	sd	s3,8(sp)
ffffffffc0203366:	e052                	sd	s4,0(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc0203368:	6785                	lui	a5,0x1
ffffffffc020336a:	1ef75d63          	bge	a4,a5,ffffffffc0203564 <do_fork+0x214>
ffffffffc020336e:	892e                	mv	s2,a1
ffffffffc0203370:	89b2                	mv	s3,a2
    if ((proc = alloc_proc()) == NULL) //分配进程结构体
ffffffffc0203372:	e97ff0ef          	jal	ra,ffffffffc0203208 <alloc_proc>
ffffffffc0203376:	842a                	mv	s0,a0
ffffffffc0203378:	1e050d63          	beqz	a0,ffffffffc0203572 <do_fork+0x222>
    proc->parent = current;  // 记录父进程指针
ffffffffc020337c:	0000aa17          	auipc	s4,0xa
ffffffffc0203380:	154a0a13          	addi	s4,s4,340 # ffffffffc020d4d0 <current>
ffffffffc0203384:	000a3783          	ld	a5,0(s4)
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0203388:	4509                	li	a0,2
    proc->parent = current;  // 记录父进程指针
ffffffffc020338a:	f01c                	sd	a5,32(s0)
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc020338c:	905fe0ef          	jal	ra,ffffffffc0201c90 <alloc_pages>
    if (page != NULL)
ffffffffc0203390:	14050063          	beqz	a0,ffffffffc02034d0 <do_fork+0x180>
    return page - pages + nbase;
ffffffffc0203394:	0000a697          	auipc	a3,0xa
ffffffffc0203398:	1246b683          	ld	a3,292(a3) # ffffffffc020d4b8 <pages>
ffffffffc020339c:	40d506b3          	sub	a3,a0,a3
ffffffffc02033a0:	8699                	srai	a3,a3,0x6
ffffffffc02033a2:	00002517          	auipc	a0,0x2
ffffffffc02033a6:	6be53503          	ld	a0,1726(a0) # ffffffffc0205a60 <nbase>
ffffffffc02033aa:	96aa                	add	a3,a3,a0
    return KADDR(page2pa(page));
ffffffffc02033ac:	00c69793          	slli	a5,a3,0xc
ffffffffc02033b0:	83b1                	srli	a5,a5,0xc
ffffffffc02033b2:	0000a717          	auipc	a4,0xa
ffffffffc02033b6:	0fe73703          	ld	a4,254(a4) # ffffffffc020d4b0 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc02033ba:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02033bc:	1ce7f063          	bgeu	a5,a4,ffffffffc020357c <do_fork+0x22c>
    assert(current->mm == NULL);
ffffffffc02033c0:	000a3783          	ld	a5,0(s4)
ffffffffc02033c4:	0000a717          	auipc	a4,0xa
ffffffffc02033c8:	10473703          	ld	a4,260(a4) # ffffffffc020d4c8 <va_pa_offset>
ffffffffc02033cc:	96ba                	add	a3,a3,a4
ffffffffc02033ce:	779c                	ld	a5,40(a5)
        proc->kstack = (uintptr_t)page2kva(page); // pmm.h 定义 page2kva 为将物理页转换为内核虚拟地址
ffffffffc02033d0:	e814                	sd	a3,16(s0)
    assert(current->mm == NULL);
ffffffffc02033d2:	1c079163          	bnez	a5,ffffffffc0203594 <do_fork+0x244>
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE - sizeof(struct trapframe)); //栈顶减去 trapframe 大小就是放 trapframe 的位置
ffffffffc02033d6:	6789                	lui	a5,0x2
ffffffffc02033d8:	ee078793          	addi	a5,a5,-288 # 1ee0 <kern_entry-0xffffffffc01fe120>
ffffffffc02033dc:	96be                	add	a3,a3,a5
    *(proc->tf) = *tf; //复制父进程的tf寄存器快照给子进程
ffffffffc02033de:	864e                	mv	a2,s3
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE - sizeof(struct trapframe)); //栈顶减去 trapframe 大小就是放 trapframe 的位置
ffffffffc02033e0:	f054                	sd	a3,160(s0)
    *(proc->tf) = *tf; //复制父进程的tf寄存器快照给子进程
ffffffffc02033e2:	87b6                	mv	a5,a3
ffffffffc02033e4:	12098893          	addi	a7,s3,288
ffffffffc02033e8:	00063803          	ld	a6,0(a2)
ffffffffc02033ec:	6608                	ld	a0,8(a2)
ffffffffc02033ee:	6a0c                	ld	a1,16(a2)
ffffffffc02033f0:	6e18                	ld	a4,24(a2)
ffffffffc02033f2:	0107b023          	sd	a6,0(a5)
ffffffffc02033f6:	e788                	sd	a0,8(a5)
ffffffffc02033f8:	eb8c                	sd	a1,16(a5)
ffffffffc02033fa:	ef98                	sd	a4,24(a5)
ffffffffc02033fc:	02060613          	addi	a2,a2,32
ffffffffc0203400:	02078793          	addi	a5,a5,32
ffffffffc0203404:	ff1612e3          	bne	a2,a7,ffffffffc02033e8 <do_fork+0x98>
    proc->tf->gpr.a0 = 0;
ffffffffc0203408:	0406b823          	sd	zero,80(a3)
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp; //设置用户态的 sp
ffffffffc020340c:	14090563          	beqz	s2,ffffffffc0203556 <do_fork+0x206>
    if (++last_pid >= MAX_PID)
ffffffffc0203410:	00006817          	auipc	a6,0x6
ffffffffc0203414:	c1880813          	addi	a6,a6,-1000 # ffffffffc0209028 <last_pid.1>
ffffffffc0203418:	00082783          	lw	a5,0(a6)
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp; //设置用户态的 sp
ffffffffc020341c:	0126b823          	sd	s2,16(a3)
    proc->context.ra = (uintptr_t)forkret; //子进程在第一次被调度时，会跳转到 forkret()
ffffffffc0203420:	00000717          	auipc	a4,0x0
ffffffffc0203424:	e4a70713          	addi	a4,a4,-438 # ffffffffc020326a <forkret>
    if (++last_pid >= MAX_PID)
ffffffffc0203428:	0017851b          	addiw	a0,a5,1
    proc->context.ra = (uintptr_t)forkret; //子进程在第一次被调度时，会跳转到 forkret()
ffffffffc020342c:	f818                	sd	a4,48(s0)
    proc->context.sp = (uintptr_t)(proc->tf); //切换到子进程时，它的内核栈起点是 trapframe 的位置
ffffffffc020342e:	fc14                	sd	a3,56(s0)
    if (++last_pid >= MAX_PID)
ffffffffc0203430:	00a82023          	sw	a0,0(a6)
ffffffffc0203434:	6789                	lui	a5,0x2
ffffffffc0203436:	0af55963          	bge	a0,a5,ffffffffc02034e8 <do_fork+0x198>
    if (last_pid >= next_safe)
ffffffffc020343a:	00006317          	auipc	t1,0x6
ffffffffc020343e:	bf230313          	addi	t1,t1,-1038 # ffffffffc020902c <next_safe.0>
ffffffffc0203442:	00032783          	lw	a5,0(t1)
ffffffffc0203446:	0000a917          	auipc	s2,0xa
ffffffffc020344a:	01290913          	addi	s2,s2,18 # ffffffffc020d458 <proc_list>
ffffffffc020344e:	0af55563          	bge	a0,a5,ffffffffc02034f8 <do_fork+0x1a8>
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc0203452:	45a9                	li	a1,10
    proc->pid = get_pid();  // 获取唯一pid
ffffffffc0203454:	c048                	sw	a0,4(s0)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc0203456:	2501                	sext.w	a0,a0
ffffffffc0203458:	58a000ef          	jal	ra,ffffffffc02039e2 <hash32>
ffffffffc020345c:	02051793          	slli	a5,a0,0x20
ffffffffc0203460:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0203464:	00006797          	auipc	a5,0x6
ffffffffc0203468:	fe478793          	addi	a5,a5,-28 # ffffffffc0209448 <hash_list>
ffffffffc020346c:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc020346e:	6518                	ld	a4,8(a0)
ffffffffc0203470:	0d840793          	addi	a5,s0,216
ffffffffc0203474:	00893683          	ld	a3,8(s2)
    prev->next = next->prev = elm;
ffffffffc0203478:	e31c                	sd	a5,0(a4)
ffffffffc020347a:	e51c                	sd	a5,8(a0)
    nr_process++;  // 全局进程计数加一
ffffffffc020347c:	409c                	lw	a5,0(s1)
    elm->next = next;
ffffffffc020347e:	f078                	sd	a4,224(s0)
    elm->prev = prev;
ffffffffc0203480:	ec68                	sd	a0,216(s0)
    list_add(&proc_list, &(proc->list_link));  // 挂入进程链表
ffffffffc0203482:	0c840713          	addi	a4,s0,200
    prev->next = next->prev = elm;
ffffffffc0203486:	e298                	sd	a4,0(a3)
    nr_process++;  // 全局进程计数加一
ffffffffc0203488:	2785                	addiw	a5,a5,1
    elm->next = next;
ffffffffc020348a:	e874                	sd	a3,208(s0)
    elm->prev = prev;
ffffffffc020348c:	0d243423          	sd	s2,200(s0)
    wakeup_proc(proc);  // 置为可运行
ffffffffc0203490:	8522                	mv	a0,s0
    prev->next = next->prev = elm;
ffffffffc0203492:	00e93423          	sd	a4,8(s2)
    nr_process++;  // 全局进程计数加一
ffffffffc0203496:	c09c                	sw	a5,0(s1)
    wakeup_proc(proc);  // 置为可运行
ffffffffc0203498:	484000ef          	jal	ra,ffffffffc020391c <wakeup_proc>
            proc->name, (proc->parent != NULL) ? proc->parent->pid : -1);
ffffffffc020349c:	701c                	ld	a5,32(s0)
    cprintf("[proc] %s pid=%d name=\"%s\" parent=%d\n", tag, proc->pid,
ffffffffc020349e:	4050                	lw	a2,4(s0)
            proc->name, (proc->parent != NULL) ? proc->parent->pid : -1);
ffffffffc02034a0:	0b440693          	addi	a3,s0,180
    cprintf("[proc] %s pid=%d name=\"%s\" parent=%d\n", tag, proc->pid,
ffffffffc02034a4:	577d                	li	a4,-1
ffffffffc02034a6:	c391                	beqz	a5,ffffffffc02034aa <do_fork+0x15a>
ffffffffc02034a8:	43d8                	lw	a4,4(a5)
ffffffffc02034aa:	00002597          	auipc	a1,0x2
ffffffffc02034ae:	20658593          	addi	a1,a1,518 # ffffffffc02056b0 <default_pmm_manager+0x9a8>
ffffffffc02034b2:	00002517          	auipc	a0,0x2
ffffffffc02034b6:	20650513          	addi	a0,a0,518 # ffffffffc02056b8 <default_pmm_manager+0x9b0>
ffffffffc02034ba:	cdbfc0ef          	jal	ra,ffffffffc0200194 <cprintf>
    ret = proc->pid;    // 返回子进程pid
ffffffffc02034be:	4048                	lw	a0,4(s0)
}
ffffffffc02034c0:	70a2                	ld	ra,40(sp)
ffffffffc02034c2:	7402                	ld	s0,32(sp)
ffffffffc02034c4:	64e2                	ld	s1,24(sp)
ffffffffc02034c6:	6942                	ld	s2,16(sp)
ffffffffc02034c8:	69a2                	ld	s3,8(sp)
ffffffffc02034ca:	6a02                	ld	s4,0(sp)
ffffffffc02034cc:	6145                	addi	sp,sp,48
ffffffffc02034ce:	8082                	ret
    kfree(proc);
ffffffffc02034d0:	8522                	mv	a0,s0
ffffffffc02034d2:	e90fe0ef          	jal	ra,ffffffffc0201b62 <kfree>
    return -E_NO_MEM;
ffffffffc02034d6:	5571                	li	a0,-4
}
ffffffffc02034d8:	70a2                	ld	ra,40(sp)
ffffffffc02034da:	7402                	ld	s0,32(sp)
ffffffffc02034dc:	64e2                	ld	s1,24(sp)
ffffffffc02034de:	6942                	ld	s2,16(sp)
ffffffffc02034e0:	69a2                	ld	s3,8(sp)
ffffffffc02034e2:	6a02                	ld	s4,0(sp)
ffffffffc02034e4:	6145                	addi	sp,sp,48
ffffffffc02034e6:	8082                	ret
        last_pid = 1;  // 超界后回绕到 1
ffffffffc02034e8:	4785                	li	a5,1
ffffffffc02034ea:	00f82023          	sw	a5,0(a6)
        goto inside;
ffffffffc02034ee:	4505                	li	a0,1
ffffffffc02034f0:	00006317          	auipc	t1,0x6
ffffffffc02034f4:	b3c30313          	addi	t1,t1,-1220 # ffffffffc020902c <next_safe.0>
    return listelm->next;
ffffffffc02034f8:	0000a917          	auipc	s2,0xa
ffffffffc02034fc:	f6090913          	addi	s2,s2,-160 # ffffffffc020d458 <proc_list>
ffffffffc0203500:	00893e03          	ld	t3,8(s2)
        next_safe = MAX_PID;  // 重新扫描前先将安全上界设为最大值
ffffffffc0203504:	6789                	lui	a5,0x2
ffffffffc0203506:	00f32023          	sw	a5,0(t1)
ffffffffc020350a:	86aa                	mv	a3,a0
ffffffffc020350c:	4581                	li	a1,0
        while ((le = list_next(le)) != list)
ffffffffc020350e:	6e89                	lui	t4,0x2
ffffffffc0203510:	052e0c63          	beq	t3,s2,ffffffffc0203568 <do_fork+0x218>
ffffffffc0203514:	88ae                	mv	a7,a1
ffffffffc0203516:	87f2                	mv	a5,t3
ffffffffc0203518:	6609                	lui	a2,0x2
ffffffffc020351a:	a811                	j	ffffffffc020352e <do_fork+0x1de>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc020351c:	00e6d663          	bge	a3,a4,ffffffffc0203528 <do_fork+0x1d8>
ffffffffc0203520:	00c75463          	bge	a4,a2,ffffffffc0203528 <do_fork+0x1d8>
ffffffffc0203524:	863a                	mv	a2,a4
ffffffffc0203526:	4885                	li	a7,1
ffffffffc0203528:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc020352a:	01278d63          	beq	a5,s2,ffffffffc0203544 <do_fork+0x1f4>
            if (proc->pid == last_pid)
ffffffffc020352e:	f3c7a703          	lw	a4,-196(a5) # 1f3c <kern_entry-0xffffffffc01fe0c4>
ffffffffc0203532:	fed715e3          	bne	a4,a3,ffffffffc020351c <do_fork+0x1cc>
                if (++last_pid >= next_safe)
ffffffffc0203536:	2685                	addiw	a3,a3,1
ffffffffc0203538:	02c6d163          	bge	a3,a2,ffffffffc020355a <do_fork+0x20a>
ffffffffc020353c:	679c                	ld	a5,8(a5)
ffffffffc020353e:	4585                	li	a1,1
        while ((le = list_next(le)) != list)
ffffffffc0203540:	ff2797e3          	bne	a5,s2,ffffffffc020352e <do_fork+0x1de>
ffffffffc0203544:	c581                	beqz	a1,ffffffffc020354c <do_fork+0x1fc>
ffffffffc0203546:	00d82023          	sw	a3,0(a6)
ffffffffc020354a:	8536                	mv	a0,a3
ffffffffc020354c:	f00883e3          	beqz	a7,ffffffffc0203452 <do_fork+0x102>
ffffffffc0203550:	00c32023          	sw	a2,0(t1)
ffffffffc0203554:	bdfd                	j	ffffffffc0203452 <do_fork+0x102>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp; //设置用户态的 sp
ffffffffc0203556:	8936                	mv	s2,a3
ffffffffc0203558:	bd65                	j	ffffffffc0203410 <do_fork+0xc0>
                    if (last_pid >= MAX_PID)
ffffffffc020355a:	01d6c363          	blt	a3,t4,ffffffffc0203560 <do_fork+0x210>
                        last_pid = 1;  // 再次超界则回绕
ffffffffc020355e:	4685                	li	a3,1
                    goto repeat;
ffffffffc0203560:	4585                	li	a1,1
ffffffffc0203562:	b77d                	j	ffffffffc0203510 <do_fork+0x1c0>
    int ret = -E_NO_FREE_PROC; //默认返回值
ffffffffc0203564:	556d                	li	a0,-5
ffffffffc0203566:	bf8d                	j	ffffffffc02034d8 <do_fork+0x188>
ffffffffc0203568:	c599                	beqz	a1,ffffffffc0203576 <do_fork+0x226>
ffffffffc020356a:	00d82023          	sw	a3,0(a6)
    return last_pid;  // 返回最终可用的唯一 PID
ffffffffc020356e:	8536                	mv	a0,a3
ffffffffc0203570:	b5cd                	j	ffffffffc0203452 <do_fork+0x102>
    ret = -E_NO_MEM;
ffffffffc0203572:	5571                	li	a0,-4
    return ret;
ffffffffc0203574:	b795                	j	ffffffffc02034d8 <do_fork+0x188>
    return last_pid;  // 返回最终可用的唯一 PID
ffffffffc0203576:	00082503          	lw	a0,0(a6)
ffffffffc020357a:	bde1                	j	ffffffffc0203452 <do_fork+0x102>
ffffffffc020357c:	00001617          	auipc	a2,0x1
ffffffffc0203580:	7c460613          	addi	a2,a2,1988 # ffffffffc0204d40 <default_pmm_manager+0x38>
ffffffffc0203584:	07100593          	li	a1,113
ffffffffc0203588:	00001517          	auipc	a0,0x1
ffffffffc020358c:	7e050513          	addi	a0,a0,2016 # ffffffffc0204d68 <default_pmm_manager+0x60>
ffffffffc0203590:	ecbfc0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(current->mm == NULL);
ffffffffc0203594:	00002697          	auipc	a3,0x2
ffffffffc0203598:	0ec68693          	addi	a3,a3,236 # ffffffffc0205680 <default_pmm_manager+0x978>
ffffffffc020359c:	00001617          	auipc	a2,0x1
ffffffffc02035a0:	3bc60613          	addi	a2,a2,956 # ffffffffc0204958 <commands+0x818>
ffffffffc02035a4:	11500593          	li	a1,277
ffffffffc02035a8:	00002517          	auipc	a0,0x2
ffffffffc02035ac:	0f050513          	addi	a0,a0,240 # ffffffffc0205698 <default_pmm_manager+0x990>
ffffffffc02035b0:	eabfc0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc02035b4 <kernel_thread>:
{
ffffffffc02035b4:	7129                	addi	sp,sp,-320
ffffffffc02035b6:	fa22                	sd	s0,304(sp)
ffffffffc02035b8:	f626                	sd	s1,296(sp)
ffffffffc02035ba:	f24a                	sd	s2,288(sp)
ffffffffc02035bc:	84ae                	mv	s1,a1
ffffffffc02035be:	892a                	mv	s2,a0
ffffffffc02035c0:	8432                	mv	s0,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc02035c2:	4581                	li	a1,0
ffffffffc02035c4:	12000613          	li	a2,288
ffffffffc02035c8:	850a                	mv	a0,sp
{
ffffffffc02035ca:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc02035cc:	0bd000ef          	jal	ra,ffffffffc0203e88 <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc02035d0:	e0ca                	sd	s2,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc02035d2:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;  // 设置为在 S 态返回，并初始化中断相关标志位
ffffffffc02035d4:	100027f3          	csrr	a5,sstatus
ffffffffc02035d8:	edd7f793          	andi	a5,a5,-291
ffffffffc02035dc:	1207e793          	ori	a5,a5,288
ffffffffc02035e0:	e23e                	sd	a5,256(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);  // 调用 do_fork，以 tf 为模板创建新线程/进程（共享地址空间）
ffffffffc02035e2:	860a                	mv	a2,sp
ffffffffc02035e4:	10046513          	ori	a0,s0,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc02035e8:	00000797          	auipc	a5,0x0
ffffffffc02035ec:	c1878793          	addi	a5,a5,-1000 # ffffffffc0203200 <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);  // 调用 do_fork，以 tf 为模板创建新线程/进程（共享地址空间）
ffffffffc02035f0:	4581                	li	a1,0
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc02035f2:	e63e                	sd	a5,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);  // 调用 do_fork，以 tf 为模板创建新线程/进程（共享地址空间）
ffffffffc02035f4:	d5dff0ef          	jal	ra,ffffffffc0203350 <do_fork>
}
ffffffffc02035f8:	70f2                	ld	ra,312(sp)
ffffffffc02035fa:	7452                	ld	s0,304(sp)
ffffffffc02035fc:	74b2                	ld	s1,296(sp)
ffffffffc02035fe:	7912                	ld	s2,288(sp)
ffffffffc0203600:	6131                	addi	sp,sp,320
ffffffffc0203602:	8082                	ret

ffffffffc0203604 <do_exit>:
{
ffffffffc0203604:	1141                	addi	sp,sp,-16
    panic("process exit!!.\n");
ffffffffc0203606:	00002617          	auipc	a2,0x2
ffffffffc020360a:	0da60613          	addi	a2,a2,218 # ffffffffc02056e0 <default_pmm_manager+0x9d8>
ffffffffc020360e:	17f00593          	li	a1,383
ffffffffc0203612:	00002517          	auipc	a0,0x2
ffffffffc0203616:	08650513          	addi	a0,a0,134 # ffffffffc0205698 <default_pmm_manager+0x990>
{
ffffffffc020361a:	e406                	sd	ra,8(sp)
    panic("process exit!!.\n");
ffffffffc020361c:	e3ffc0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0203620 <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and
//           - create the second kernel thread init_main
void proc_init(void)
{
ffffffffc0203620:	7179                	addi	sp,sp,-48
ffffffffc0203622:	ec26                	sd	s1,24(sp)
    elm->prev = elm->next = elm;
ffffffffc0203624:	0000a797          	auipc	a5,0xa
ffffffffc0203628:	e3478793          	addi	a5,a5,-460 # ffffffffc020d458 <proc_list>
ffffffffc020362c:	f406                	sd	ra,40(sp)
ffffffffc020362e:	f022                	sd	s0,32(sp)
ffffffffc0203630:	e84a                	sd	s2,16(sp)
ffffffffc0203632:	e44e                	sd	s3,8(sp)
ffffffffc0203634:	00006497          	auipc	s1,0x6
ffffffffc0203638:	e1448493          	addi	s1,s1,-492 # ffffffffc0209448 <hash_list>
ffffffffc020363c:	e79c                	sd	a5,8(a5)
ffffffffc020363e:	e39c                	sd	a5,0(a5)
    int i;

    // list_init:proc_list.prev = proc_list.next = &proc_list
    list_init(&proc_list);  // 初始化进程链表
    for (i = 0; i < HASH_LIST_SIZE; i++)
ffffffffc0203640:	0000a717          	auipc	a4,0xa
ffffffffc0203644:	e0870713          	addi	a4,a4,-504 # ffffffffc020d448 <name.2>
ffffffffc0203648:	87a6                	mv	a5,s1
ffffffffc020364a:	e79c                	sd	a5,8(a5)
ffffffffc020364c:	e39c                	sd	a5,0(a5)
ffffffffc020364e:	07c1                	addi	a5,a5,16
ffffffffc0203650:	fef71de3          	bne	a4,a5,ffffffffc020364a <proc_init+0x2a>
    {
        list_init(hash_list + i);  // 初始化哈希表，find_proc里有用，快速查找
    }

    if ((idleproc = alloc_proc()) == NULL)  // 这里调用我们写的alloc_proc，分配PCB
ffffffffc0203654:	bb5ff0ef          	jal	ra,ffffffffc0203208 <alloc_proc>
ffffffffc0203658:	0000a917          	auipc	s2,0xa
ffffffffc020365c:	e8090913          	addi	s2,s2,-384 # ffffffffc020d4d8 <idleproc>
ffffffffc0203660:	00a93023          	sd	a0,0(s2)
ffffffffc0203664:	1c050163          	beqz	a0,ffffffffc0203826 <proc_init+0x206>
        panic("cannot alloc idleproc.\n");
    }

    // check the proc structure
    // 做检查用的，确定是全0
    int *context_mem = (int *)kmalloc(sizeof(struct context));  //创建一个context结构体，进程上下文，定义见proc.h
ffffffffc0203668:	07000513          	li	a0,112
ffffffffc020366c:	c46fe0ef          	jal	ra,ffffffffc0201ab2 <kmalloc>
    memset(context_mem, 0, sizeof(struct context));
ffffffffc0203670:	07000613          	li	a2,112
ffffffffc0203674:	4581                	li	a1,0
    int *context_mem = (int *)kmalloc(sizeof(struct context));  //创建一个context结构体，进程上下文，定义见proc.h
ffffffffc0203676:	842a                	mv	s0,a0
    memset(context_mem, 0, sizeof(struct context));
ffffffffc0203678:	011000ef          	jal	ra,ffffffffc0203e88 <memset>
    int context_init_flag = memcmp(&(idleproc->context), context_mem, sizeof(struct context));
ffffffffc020367c:	00093503          	ld	a0,0(s2)
ffffffffc0203680:	85a2                	mv	a1,s0
ffffffffc0203682:	07000613          	li	a2,112
ffffffffc0203686:	03050513          	addi	a0,a0,48
ffffffffc020368a:	029000ef          	jal	ra,ffffffffc0203eb2 <memcmp>
ffffffffc020368e:	89aa                	mv	s3,a0

    int *proc_name_mem = (int *)kmalloc(PROC_NAME_LEN);
ffffffffc0203690:	453d                	li	a0,15
ffffffffc0203692:	c20fe0ef          	jal	ra,ffffffffc0201ab2 <kmalloc>
    memset(proc_name_mem, 0, PROC_NAME_LEN);
ffffffffc0203696:	463d                	li	a2,15
ffffffffc0203698:	4581                	li	a1,0
    int *proc_name_mem = (int *)kmalloc(PROC_NAME_LEN);
ffffffffc020369a:	842a                	mv	s0,a0
    memset(proc_name_mem, 0, PROC_NAME_LEN);
ffffffffc020369c:	7ec000ef          	jal	ra,ffffffffc0203e88 <memset>
    int proc_name_flag = memcmp(&(idleproc->name), proc_name_mem, PROC_NAME_LEN);
ffffffffc02036a0:	00093503          	ld	a0,0(s2)
ffffffffc02036a4:	463d                	li	a2,15
ffffffffc02036a6:	85a2                	mv	a1,s0
ffffffffc02036a8:	0b450513          	addi	a0,a0,180
ffffffffc02036ac:	007000ef          	jal	ra,ffffffffc0203eb2 <memcmp>

    if (idleproc->pgdir == boot_pgdir_pa && idleproc->tf == NULL && !context_init_flag && idleproc->state == PROC_UNINIT && idleproc->pid == -1 && idleproc->runs == 0 && idleproc->kstack == 0 && idleproc->need_resched == 0 && idleproc->parent == NULL && idleproc->mm == NULL && idleproc->flags == 0 && !proc_name_flag)
ffffffffc02036b0:	00093783          	ld	a5,0(s2)
ffffffffc02036b4:	0000a717          	auipc	a4,0xa
ffffffffc02036b8:	dec73703          	ld	a4,-532(a4) # ffffffffc020d4a0 <boot_pgdir_pa>
ffffffffc02036bc:	77d4                	ld	a3,168(a5)
ffffffffc02036be:	10e68763          	beq	a3,a4,ffffffffc02037cc <proc_init+0x1ac>
    {
        cprintf("alloc_proc() correct!\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc02036c2:	4709                	li	a4,2
ffffffffc02036c4:	e398                	sd	a4,0(a5)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc02036c6:	00003717          	auipc	a4,0x3
ffffffffc02036ca:	93a70713          	addi	a4,a4,-1734 # ffffffffc0206000 <bootstack>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02036ce:	0b478413          	addi	s0,a5,180
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc02036d2:	eb98                	sd	a4,16(a5)
    idleproc->need_resched = 1;
ffffffffc02036d4:	4705                	li	a4,1
ffffffffc02036d6:	cf98                	sw	a4,24(a5)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02036d8:	4641                	li	a2,16
ffffffffc02036da:	4581                	li	a1,0
ffffffffc02036dc:	8522                	mv	a0,s0
ffffffffc02036de:	7aa000ef          	jal	ra,ffffffffc0203e88 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc02036e2:	463d                	li	a2,15
ffffffffc02036e4:	00002597          	auipc	a1,0x2
ffffffffc02036e8:	04458593          	addi	a1,a1,68 # ffffffffc0205728 <default_pmm_manager+0xa20>
ffffffffc02036ec:	8522                	mv	a0,s0
ffffffffc02036ee:	7ac000ef          	jal	ra,ffffffffc0203e9a <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process++;
    log_proc_created("proc_init", idleproc);  //日志日志
ffffffffc02036f2:	00093783          	ld	a5,0(s2)
    nr_process++;
ffffffffc02036f6:	0000a697          	auipc	a3,0xa
ffffffffc02036fa:	df268693          	addi	a3,a3,-526 # ffffffffc020d4e8 <nr_process>
ffffffffc02036fe:	4298                	lw	a4,0(a3)
            proc->name, (proc->parent != NULL) ? proc->parent->pid : -1);
ffffffffc0203700:	738c                	ld	a1,32(a5)
    cprintf("[proc] %s pid=%d name=\"%s\" parent=%d\n", tag, proc->pid,
ffffffffc0203702:	43d0                	lw	a2,4(a5)
    nr_process++;
ffffffffc0203704:	2705                	addiw	a4,a4,1
ffffffffc0203706:	c298                	sw	a4,0(a3)
            proc->name, (proc->parent != NULL) ? proc->parent->pid : -1);
ffffffffc0203708:	0b478693          	addi	a3,a5,180
    cprintf("[proc] %s pid=%d name=\"%s\" parent=%d\n", tag, proc->pid,
ffffffffc020370c:	577d                	li	a4,-1
ffffffffc020370e:	c191                	beqz	a1,ffffffffc0203712 <proc_init+0xf2>
ffffffffc0203710:	41d8                	lw	a4,4(a1)
ffffffffc0203712:	00002597          	auipc	a1,0x2
ffffffffc0203716:	01e58593          	addi	a1,a1,30 # ffffffffc0205730 <default_pmm_manager+0xa28>
ffffffffc020371a:	00002517          	auipc	a0,0x2
ffffffffc020371e:	f9e50513          	addi	a0,a0,-98 # ffffffffc02056b8 <default_pmm_manager+0x9b0>
ffffffffc0203722:	a73fc0ef          	jal	ra,ffffffffc0200194 <cprintf>

    current = idleproc;
ffffffffc0203726:	00093783          	ld	a5,0(s2)

    int pid = kernel_thread(init_main, "Hello world!!", 0);  // 以context为参数，创建init_main线程（或者说进程，似乎这概念没分的那么清晰）
ffffffffc020372a:	4601                	li	a2,0
ffffffffc020372c:	00002597          	auipc	a1,0x2
ffffffffc0203730:	01458593          	addi	a1,a1,20 # ffffffffc0205740 <default_pmm_manager+0xa38>
ffffffffc0203734:	00000517          	auipc	a0,0x0
ffffffffc0203738:	b4450513          	addi	a0,a0,-1212 # ffffffffc0203278 <init_main>
    current = idleproc;
ffffffffc020373c:	0000a717          	auipc	a4,0xa
ffffffffc0203740:	d8f73a23          	sd	a5,-620(a4) # ffffffffc020d4d0 <current>
    int pid = kernel_thread(init_main, "Hello world!!", 0);  // 以context为参数，创建init_main线程（或者说进程，似乎这概念没分的那么清晰）
ffffffffc0203744:	e71ff0ef          	jal	ra,ffffffffc02035b4 <kernel_thread>
ffffffffc0203748:	842a                	mv	s0,a0
    if (pid <= 0)
ffffffffc020374a:	0ea05a63          	blez	a0,ffffffffc020383e <proc_init+0x21e>
    if (0 < pid && pid < MAX_PID)
ffffffffc020374e:	6789                	lui	a5,0x2
ffffffffc0203750:	fff5071b          	addiw	a4,a0,-1
ffffffffc0203754:	17f9                	addi	a5,a5,-2
ffffffffc0203756:	2501                	sext.w	a0,a0
ffffffffc0203758:	02e7e363          	bltu	a5,a4,ffffffffc020377e <proc_init+0x15e>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc020375c:	45a9                	li	a1,10
ffffffffc020375e:	284000ef          	jal	ra,ffffffffc02039e2 <hash32>
ffffffffc0203762:	02051793          	slli	a5,a0,0x20
ffffffffc0203766:	01c7d693          	srli	a3,a5,0x1c
ffffffffc020376a:	96a6                	add	a3,a3,s1
ffffffffc020376c:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list)
ffffffffc020376e:	a029                	j	ffffffffc0203778 <proc_init+0x158>
            if (proc->pid == pid)
ffffffffc0203770:	f2c7a703          	lw	a4,-212(a5) # 1f2c <kern_entry-0xffffffffc01fe0d4>
ffffffffc0203774:	0a870663          	beq	a4,s0,ffffffffc0203820 <proc_init+0x200>
    return listelm->next;
ffffffffc0203778:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc020377a:	fef69be3          	bne	a3,a5,ffffffffc0203770 <proc_init+0x150>
    return NULL;
ffffffffc020377e:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0203780:	0b478493          	addi	s1,a5,180
ffffffffc0203784:	4641                	li	a2,16
ffffffffc0203786:	4581                	li	a1,0
    {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc0203788:	0000a417          	auipc	s0,0xa
ffffffffc020378c:	d5840413          	addi	s0,s0,-680 # ffffffffc020d4e0 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0203790:	8526                	mv	a0,s1
    initproc = find_proc(pid);
ffffffffc0203792:	e01c                	sd	a5,0(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0203794:	6f4000ef          	jal	ra,ffffffffc0203e88 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0203798:	463d                	li	a2,15
ffffffffc020379a:	00002597          	auipc	a1,0x2
ffffffffc020379e:	fd658593          	addi	a1,a1,-42 # ffffffffc0205770 <default_pmm_manager+0xa68>
ffffffffc02037a2:	8526                	mv	a0,s1
ffffffffc02037a4:	6f6000ef          	jal	ra,ffffffffc0203e9a <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc02037a8:	00093783          	ld	a5,0(s2)
ffffffffc02037ac:	c7e9                	beqz	a5,ffffffffc0203876 <proc_init+0x256>
ffffffffc02037ae:	43dc                	lw	a5,4(a5)
ffffffffc02037b0:	e3f9                	bnez	a5,ffffffffc0203876 <proc_init+0x256>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc02037b2:	601c                	ld	a5,0(s0)
ffffffffc02037b4:	c3cd                	beqz	a5,ffffffffc0203856 <proc_init+0x236>
ffffffffc02037b6:	43d8                	lw	a4,4(a5)
ffffffffc02037b8:	4785                	li	a5,1
ffffffffc02037ba:	08f71e63          	bne	a4,a5,ffffffffc0203856 <proc_init+0x236>
}
ffffffffc02037be:	70a2                	ld	ra,40(sp)
ffffffffc02037c0:	7402                	ld	s0,32(sp)
ffffffffc02037c2:	64e2                	ld	s1,24(sp)
ffffffffc02037c4:	6942                	ld	s2,16(sp)
ffffffffc02037c6:	69a2                	ld	s3,8(sp)
ffffffffc02037c8:	6145                	addi	sp,sp,48
ffffffffc02037ca:	8082                	ret
    if (idleproc->pgdir == boot_pgdir_pa && idleproc->tf == NULL && !context_init_flag && idleproc->state == PROC_UNINIT && idleproc->pid == -1 && idleproc->runs == 0 && idleproc->kstack == 0 && idleproc->need_resched == 0 && idleproc->parent == NULL && idleproc->mm == NULL && idleproc->flags == 0 && !proc_name_flag)
ffffffffc02037cc:	73d8                	ld	a4,160(a5)
ffffffffc02037ce:	ee071ae3          	bnez	a4,ffffffffc02036c2 <proc_init+0xa2>
ffffffffc02037d2:	ee0998e3          	bnez	s3,ffffffffc02036c2 <proc_init+0xa2>
ffffffffc02037d6:	6394                	ld	a3,0(a5)
ffffffffc02037d8:	577d                	li	a4,-1
ffffffffc02037da:	1702                	slli	a4,a4,0x20
ffffffffc02037dc:	eee693e3          	bne	a3,a4,ffffffffc02036c2 <proc_init+0xa2>
ffffffffc02037e0:	4798                	lw	a4,8(a5)
ffffffffc02037e2:	ee0710e3          	bnez	a4,ffffffffc02036c2 <proc_init+0xa2>
ffffffffc02037e6:	6b98                	ld	a4,16(a5)
ffffffffc02037e8:	ec071de3          	bnez	a4,ffffffffc02036c2 <proc_init+0xa2>
ffffffffc02037ec:	4f98                	lw	a4,24(a5)
ffffffffc02037ee:	2701                	sext.w	a4,a4
ffffffffc02037f0:	ec0719e3          	bnez	a4,ffffffffc02036c2 <proc_init+0xa2>
ffffffffc02037f4:	7398                	ld	a4,32(a5)
ffffffffc02037f6:	ec0716e3          	bnez	a4,ffffffffc02036c2 <proc_init+0xa2>
ffffffffc02037fa:	7798                	ld	a4,40(a5)
ffffffffc02037fc:	ec0713e3          	bnez	a4,ffffffffc02036c2 <proc_init+0xa2>
ffffffffc0203800:	0b07a703          	lw	a4,176(a5)
ffffffffc0203804:	8d59                	or	a0,a0,a4
ffffffffc0203806:	0005071b          	sext.w	a4,a0
ffffffffc020380a:	ea071ce3          	bnez	a4,ffffffffc02036c2 <proc_init+0xa2>
        cprintf("alloc_proc() correct!\n");
ffffffffc020380e:	00002517          	auipc	a0,0x2
ffffffffc0203812:	f0250513          	addi	a0,a0,-254 # ffffffffc0205710 <default_pmm_manager+0xa08>
ffffffffc0203816:	97ffc0ef          	jal	ra,ffffffffc0200194 <cprintf>
    idleproc->pid = 0;
ffffffffc020381a:	00093783          	ld	a5,0(s2)
ffffffffc020381e:	b555                	j	ffffffffc02036c2 <proc_init+0xa2>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0203820:	f2878793          	addi	a5,a5,-216
ffffffffc0203824:	bfb1                	j	ffffffffc0203780 <proc_init+0x160>
        panic("cannot alloc idleproc.\n");
ffffffffc0203826:	00002617          	auipc	a2,0x2
ffffffffc020382a:	ed260613          	addi	a2,a2,-302 # ffffffffc02056f8 <default_pmm_manager+0x9f0>
ffffffffc020382e:	19b00593          	li	a1,411
ffffffffc0203832:	00002517          	auipc	a0,0x2
ffffffffc0203836:	e6650513          	addi	a0,a0,-410 # ffffffffc0205698 <default_pmm_manager+0x990>
ffffffffc020383a:	c21fc0ef          	jal	ra,ffffffffc020045a <__panic>
        panic("create init_main failed.\n");
ffffffffc020383e:	00002617          	auipc	a2,0x2
ffffffffc0203842:	f1260613          	addi	a2,a2,-238 # ffffffffc0205750 <default_pmm_manager+0xa48>
ffffffffc0203846:	1ba00593          	li	a1,442
ffffffffc020384a:	00002517          	auipc	a0,0x2
ffffffffc020384e:	e4e50513          	addi	a0,a0,-434 # ffffffffc0205698 <default_pmm_manager+0x990>
ffffffffc0203852:	c09fc0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0203856:	00002697          	auipc	a3,0x2
ffffffffc020385a:	f4a68693          	addi	a3,a3,-182 # ffffffffc02057a0 <default_pmm_manager+0xa98>
ffffffffc020385e:	00001617          	auipc	a2,0x1
ffffffffc0203862:	0fa60613          	addi	a2,a2,250 # ffffffffc0204958 <commands+0x818>
ffffffffc0203866:	1c100593          	li	a1,449
ffffffffc020386a:	00002517          	auipc	a0,0x2
ffffffffc020386e:	e2e50513          	addi	a0,a0,-466 # ffffffffc0205698 <default_pmm_manager+0x990>
ffffffffc0203872:	be9fc0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0203876:	00002697          	auipc	a3,0x2
ffffffffc020387a:	f0268693          	addi	a3,a3,-254 # ffffffffc0205778 <default_pmm_manager+0xa70>
ffffffffc020387e:	00001617          	auipc	a2,0x1
ffffffffc0203882:	0da60613          	addi	a2,a2,218 # ffffffffc0204958 <commands+0x818>
ffffffffc0203886:	1c000593          	li	a1,448
ffffffffc020388a:	00002517          	auipc	a0,0x2
ffffffffc020388e:	e0e50513          	addi	a0,a0,-498 # ffffffffc0205698 <default_pmm_manager+0x990>
ffffffffc0203892:	bc9fc0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0203896 <cpu_idle>:

// 死循环，不断轮转找到可执行状态的进程
// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void cpu_idle(void)
{
ffffffffc0203896:	1141                	addi	sp,sp,-16
ffffffffc0203898:	e022                	sd	s0,0(sp)
ffffffffc020389a:	e406                	sd	ra,8(sp)
ffffffffc020389c:	0000a417          	auipc	s0,0xa
ffffffffc02038a0:	c3440413          	addi	s0,s0,-972 # ffffffffc020d4d0 <current>
    while (1)
    {
        if (current->need_resched)
ffffffffc02038a4:	6018                	ld	a4,0(s0)
ffffffffc02038a6:	4f1c                	lw	a5,24(a4)
ffffffffc02038a8:	2781                	sext.w	a5,a5
ffffffffc02038aa:	dff5                	beqz	a5,ffffffffc02038a6 <cpu_idle+0x10>
        {
            schedule(); //../schedule/sched.c
ffffffffc02038ac:	0a2000ef          	jal	ra,ffffffffc020394e <schedule>
ffffffffc02038b0:	bfd5                	j	ffffffffc02038a4 <cpu_idle+0xe>

ffffffffc02038b2 <switch_to>:
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # a0 = from ;a1 = to 
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc02038b2:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc02038b6:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc02038ba:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc02038bc:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc02038be:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc02038c2:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc02038c6:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc02038ca:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc02038ce:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc02038d2:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc02038d6:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc02038da:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc02038de:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc02038e2:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc02038e6:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc02038ea:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc02038ee:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc02038f0:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc02038f2:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc02038f6:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc02038fa:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc02038fe:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc0203902:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc0203906:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc020390a:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc020390e:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc0203912:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc0203916:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc020391a:	8082                	ret

ffffffffc020391c <wakeup_proc>:
#include <assert.h>

void
wakeup_proc(struct proc_struct *proc) {
    // 唤醒进程：确保进程不是僵尸状态且不是可运行状态
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
ffffffffc020391c:	411c                	lw	a5,0(a0)
ffffffffc020391e:	4705                	li	a4,1
ffffffffc0203920:	37f9                	addiw	a5,a5,-2
ffffffffc0203922:	00f77563          	bgeu	a4,a5,ffffffffc020392c <wakeup_proc+0x10>
    // 将进程状态设置为可运行
    proc->state = PROC_RUNNABLE;
ffffffffc0203926:	4789                	li	a5,2
ffffffffc0203928:	c11c                	sw	a5,0(a0)
ffffffffc020392a:	8082                	ret
wakeup_proc(struct proc_struct *proc) {
ffffffffc020392c:	1141                	addi	sp,sp,-16
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
ffffffffc020392e:	00002697          	auipc	a3,0x2
ffffffffc0203932:	e9a68693          	addi	a3,a3,-358 # ffffffffc02057c8 <default_pmm_manager+0xac0>
ffffffffc0203936:	00001617          	auipc	a2,0x1
ffffffffc020393a:	02260613          	addi	a2,a2,34 # ffffffffc0204958 <commands+0x818>
ffffffffc020393e:	45a9                	li	a1,10
ffffffffc0203940:	00002517          	auipc	a0,0x2
ffffffffc0203944:	ec850513          	addi	a0,a0,-312 # ffffffffc0205808 <default_pmm_manager+0xb00>
wakeup_proc(struct proc_struct *proc) {
ffffffffc0203948:	e406                	sd	ra,8(sp)
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
ffffffffc020394a:	b11fc0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc020394e <schedule>:
}

void
schedule(void) {
ffffffffc020394e:	1141                	addi	sp,sp,-16
ffffffffc0203950:	e406                	sd	ra,8(sp)
ffffffffc0203952:	e022                	sd	s0,0(sp)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0203954:	100027f3          	csrr	a5,sstatus
ffffffffc0203958:	8b89                	andi	a5,a5,2
ffffffffc020395a:	4401                	li	s0,0
ffffffffc020395c:	efbd                	bnez	a5,ffffffffc02039da <schedule+0x8c>
    
    // 保存当前中断状态并禁用中断，确保调度过程原子性
    local_intr_save(intr_flag);  
    {
        // 步骤1: 重置当前进程的重新调度标志
        current->need_resched = 0;
ffffffffc020395e:	0000a897          	auipc	a7,0xa
ffffffffc0203962:	b728b883          	ld	a7,-1166(a7) # ffffffffc020d4d0 <current>
ffffffffc0203966:	0008ac23          	sw	zero,24(a7)
        
        // 步骤2: 确定遍历起始点
        // 如果当前进程是空闲进程，从链表头开始；否则从当前进程位置开始
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc020396a:	0000a517          	auipc	a0,0xa
ffffffffc020396e:	b6e53503          	ld	a0,-1170(a0) # ffffffffc020d4d8 <idleproc>
ffffffffc0203972:	04a88e63          	beq	a7,a0,ffffffffc02039ce <schedule+0x80>
ffffffffc0203976:	0c888693          	addi	a3,a7,200
ffffffffc020397a:	0000a617          	auipc	a2,0xa
ffffffffc020397e:	ade60613          	addi	a2,a2,-1314 # ffffffffc020d458 <proc_list>
        le = last;
ffffffffc0203982:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL;   // 下一个要调度的进程
ffffffffc0203984:	4581                	li	a1,0
            // 获取链表中的下一个进程
            if ((le = list_next(le)) != &proc_list) {
                // 将链表节点转换为进程结构体
                next = le2proc(le, list_link);
                // 如果找到可运行进程，跳出循环
                if (next->state == PROC_RUNNABLE) {
ffffffffc0203986:	4809                	li	a6,2
ffffffffc0203988:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list) {
ffffffffc020398a:	00c78863          	beq	a5,a2,ffffffffc020399a <schedule+0x4c>
                if (next->state == PROC_RUNNABLE) {
ffffffffc020398e:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link);
ffffffffc0203992:	f3878593          	addi	a1,a5,-200
                if (next->state == PROC_RUNNABLE) {
ffffffffc0203996:	03070163          	beq	a4,a6,ffffffffc02039b8 <schedule+0x6a>
                    break;
                }
            }
        } while (le != last);  // 循环直到回到起始点
ffffffffc020399a:	fef697e3          	bne	a3,a5,ffffffffc0203988 <schedule+0x3a>
        
        // 步骤4: 后备选择 - 如果没有找到可运行进程，选择空闲进程
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc020399e:	ed89                	bnez	a1,ffffffffc02039b8 <schedule+0x6a>
            next = idleproc;
        }
        
        // 步骤5: 增加选中进程的运行次数统计
        next->runs ++;
ffffffffc02039a0:	451c                	lw	a5,8(a0)
ffffffffc02039a2:	2785                	addiw	a5,a5,1
ffffffffc02039a4:	c51c                	sw	a5,8(a0)
        
        // 步骤6: 如果选中的进程不是当前进程，执行进程切换
        if (next != current) {
ffffffffc02039a6:	00a88463          	beq	a7,a0,ffffffffc02039ae <schedule+0x60>
            proc_run(next);
ffffffffc02039aa:	941ff0ef          	jal	ra,ffffffffc02032ea <proc_run>
    if (flag) {
ffffffffc02039ae:	e819                	bnez	s0,ffffffffc02039c4 <schedule+0x76>
        }
    }
    // 恢复之前的中断状态
    local_intr_restore(intr_flag);
}
ffffffffc02039b0:	60a2                	ld	ra,8(sp)
ffffffffc02039b2:	6402                	ld	s0,0(sp)
ffffffffc02039b4:	0141                	addi	sp,sp,16
ffffffffc02039b6:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc02039b8:	4198                	lw	a4,0(a1)
ffffffffc02039ba:	4789                	li	a5,2
ffffffffc02039bc:	fef712e3          	bne	a4,a5,ffffffffc02039a0 <schedule+0x52>
ffffffffc02039c0:	852e                	mv	a0,a1
ffffffffc02039c2:	bff9                	j	ffffffffc02039a0 <schedule+0x52>
}
ffffffffc02039c4:	6402                	ld	s0,0(sp)
ffffffffc02039c6:	60a2                	ld	ra,8(sp)
ffffffffc02039c8:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc02039ca:	f61fc06f          	j	ffffffffc020092a <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc02039ce:	0000a617          	auipc	a2,0xa
ffffffffc02039d2:	a8a60613          	addi	a2,a2,-1398 # ffffffffc020d458 <proc_list>
ffffffffc02039d6:	86b2                	mv	a3,a2
ffffffffc02039d8:	b76d                	j	ffffffffc0203982 <schedule+0x34>
        intr_disable();
ffffffffc02039da:	f57fc0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        return 1;
ffffffffc02039de:	4405                	li	s0,1
ffffffffc02039e0:	bfbd                	j	ffffffffc020395e <schedule+0x10>

ffffffffc02039e2 <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc02039e2:	9e3707b7          	lui	a5,0x9e370
ffffffffc02039e6:	2785                	addiw	a5,a5,1
ffffffffc02039e8:	02a7853b          	mulw	a0,a5,a0
    return (hash >> (32 - bits));
ffffffffc02039ec:	02000793          	li	a5,32
ffffffffc02039f0:	9f8d                	subw	a5,a5,a1
}
ffffffffc02039f2:	00f5553b          	srlw	a0,a0,a5
ffffffffc02039f6:	8082                	ret

ffffffffc02039f8 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc02039f8:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02039fc:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc02039fe:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203a02:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0203a04:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203a08:	f022                	sd	s0,32(sp)
ffffffffc0203a0a:	ec26                	sd	s1,24(sp)
ffffffffc0203a0c:	e84a                	sd	s2,16(sp)
ffffffffc0203a0e:	f406                	sd	ra,40(sp)
ffffffffc0203a10:	e44e                	sd	s3,8(sp)
ffffffffc0203a12:	84aa                	mv	s1,a0
ffffffffc0203a14:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0203a16:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0203a1a:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0203a1c:	03067e63          	bgeu	a2,a6,ffffffffc0203a58 <printnum+0x60>
ffffffffc0203a20:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0203a22:	00805763          	blez	s0,ffffffffc0203a30 <printnum+0x38>
ffffffffc0203a26:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0203a28:	85ca                	mv	a1,s2
ffffffffc0203a2a:	854e                	mv	a0,s3
ffffffffc0203a2c:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0203a2e:	fc65                	bnez	s0,ffffffffc0203a26 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203a30:	1a02                	slli	s4,s4,0x20
ffffffffc0203a32:	00002797          	auipc	a5,0x2
ffffffffc0203a36:	dee78793          	addi	a5,a5,-530 # ffffffffc0205820 <default_pmm_manager+0xb18>
ffffffffc0203a3a:	020a5a13          	srli	s4,s4,0x20
ffffffffc0203a3e:	9a3e                	add	s4,s4,a5
}
ffffffffc0203a40:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203a42:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0203a46:	70a2                	ld	ra,40(sp)
ffffffffc0203a48:	69a2                	ld	s3,8(sp)
ffffffffc0203a4a:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203a4c:	85ca                	mv	a1,s2
ffffffffc0203a4e:	87a6                	mv	a5,s1
}
ffffffffc0203a50:	6942                	ld	s2,16(sp)
ffffffffc0203a52:	64e2                	ld	s1,24(sp)
ffffffffc0203a54:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203a56:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0203a58:	03065633          	divu	a2,a2,a6
ffffffffc0203a5c:	8722                	mv	a4,s0
ffffffffc0203a5e:	f9bff0ef          	jal	ra,ffffffffc02039f8 <printnum>
ffffffffc0203a62:	b7f9                	j	ffffffffc0203a30 <printnum+0x38>

ffffffffc0203a64 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0203a64:	7119                	addi	sp,sp,-128
ffffffffc0203a66:	f4a6                	sd	s1,104(sp)
ffffffffc0203a68:	f0ca                	sd	s2,96(sp)
ffffffffc0203a6a:	ecce                	sd	s3,88(sp)
ffffffffc0203a6c:	e8d2                	sd	s4,80(sp)
ffffffffc0203a6e:	e4d6                	sd	s5,72(sp)
ffffffffc0203a70:	e0da                	sd	s6,64(sp)
ffffffffc0203a72:	fc5e                	sd	s7,56(sp)
ffffffffc0203a74:	f06a                	sd	s10,32(sp)
ffffffffc0203a76:	fc86                	sd	ra,120(sp)
ffffffffc0203a78:	f8a2                	sd	s0,112(sp)
ffffffffc0203a7a:	f862                	sd	s8,48(sp)
ffffffffc0203a7c:	f466                	sd	s9,40(sp)
ffffffffc0203a7e:	ec6e                	sd	s11,24(sp)
ffffffffc0203a80:	892a                	mv	s2,a0
ffffffffc0203a82:	84ae                	mv	s1,a1
ffffffffc0203a84:	8d32                	mv	s10,a2
ffffffffc0203a86:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203a88:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0203a8c:	5b7d                	li	s6,-1
ffffffffc0203a8e:	00002a97          	auipc	s5,0x2
ffffffffc0203a92:	dbea8a93          	addi	s5,s5,-578 # ffffffffc020584c <default_pmm_manager+0xb44>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0203a96:	00002b97          	auipc	s7,0x2
ffffffffc0203a9a:	f92b8b93          	addi	s7,s7,-110 # ffffffffc0205a28 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203a9e:	000d4503          	lbu	a0,0(s10)
ffffffffc0203aa2:	001d0413          	addi	s0,s10,1
ffffffffc0203aa6:	01350a63          	beq	a0,s3,ffffffffc0203aba <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0203aaa:	c121                	beqz	a0,ffffffffc0203aea <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0203aac:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203aae:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0203ab0:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203ab2:	fff44503          	lbu	a0,-1(s0)
ffffffffc0203ab6:	ff351ae3          	bne	a0,s3,ffffffffc0203aaa <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203aba:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0203abe:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0203ac2:	4c81                	li	s9,0
ffffffffc0203ac4:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0203ac6:	5c7d                	li	s8,-1
ffffffffc0203ac8:	5dfd                	li	s11,-1
ffffffffc0203aca:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0203ace:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203ad0:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0203ad4:	0ff5f593          	zext.b	a1,a1
ffffffffc0203ad8:	00140d13          	addi	s10,s0,1
ffffffffc0203adc:	04b56263          	bltu	a0,a1,ffffffffc0203b20 <vprintfmt+0xbc>
ffffffffc0203ae0:	058a                	slli	a1,a1,0x2
ffffffffc0203ae2:	95d6                	add	a1,a1,s5
ffffffffc0203ae4:	4194                	lw	a3,0(a1)
ffffffffc0203ae6:	96d6                	add	a3,a3,s5
ffffffffc0203ae8:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0203aea:	70e6                	ld	ra,120(sp)
ffffffffc0203aec:	7446                	ld	s0,112(sp)
ffffffffc0203aee:	74a6                	ld	s1,104(sp)
ffffffffc0203af0:	7906                	ld	s2,96(sp)
ffffffffc0203af2:	69e6                	ld	s3,88(sp)
ffffffffc0203af4:	6a46                	ld	s4,80(sp)
ffffffffc0203af6:	6aa6                	ld	s5,72(sp)
ffffffffc0203af8:	6b06                	ld	s6,64(sp)
ffffffffc0203afa:	7be2                	ld	s7,56(sp)
ffffffffc0203afc:	7c42                	ld	s8,48(sp)
ffffffffc0203afe:	7ca2                	ld	s9,40(sp)
ffffffffc0203b00:	7d02                	ld	s10,32(sp)
ffffffffc0203b02:	6de2                	ld	s11,24(sp)
ffffffffc0203b04:	6109                	addi	sp,sp,128
ffffffffc0203b06:	8082                	ret
            padc = '0';
ffffffffc0203b08:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0203b0a:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203b0e:	846a                	mv	s0,s10
ffffffffc0203b10:	00140d13          	addi	s10,s0,1
ffffffffc0203b14:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0203b18:	0ff5f593          	zext.b	a1,a1
ffffffffc0203b1c:	fcb572e3          	bgeu	a0,a1,ffffffffc0203ae0 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0203b20:	85a6                	mv	a1,s1
ffffffffc0203b22:	02500513          	li	a0,37
ffffffffc0203b26:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0203b28:	fff44783          	lbu	a5,-1(s0)
ffffffffc0203b2c:	8d22                	mv	s10,s0
ffffffffc0203b2e:	f73788e3          	beq	a5,s3,ffffffffc0203a9e <vprintfmt+0x3a>
ffffffffc0203b32:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0203b36:	1d7d                	addi	s10,s10,-1
ffffffffc0203b38:	ff379de3          	bne	a5,s3,ffffffffc0203b32 <vprintfmt+0xce>
ffffffffc0203b3c:	b78d                	j	ffffffffc0203a9e <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0203b3e:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0203b42:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203b46:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0203b48:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0203b4c:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0203b50:	02d86463          	bltu	a6,a3,ffffffffc0203b78 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0203b54:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0203b58:	002c169b          	slliw	a3,s8,0x2
ffffffffc0203b5c:	0186873b          	addw	a4,a3,s8
ffffffffc0203b60:	0017171b          	slliw	a4,a4,0x1
ffffffffc0203b64:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0203b66:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0203b6a:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0203b6c:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0203b70:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0203b74:	fed870e3          	bgeu	a6,a3,ffffffffc0203b54 <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0203b78:	f40ddce3          	bgez	s11,ffffffffc0203ad0 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0203b7c:	8de2                	mv	s11,s8
ffffffffc0203b7e:	5c7d                	li	s8,-1
ffffffffc0203b80:	bf81                	j	ffffffffc0203ad0 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0203b82:	fffdc693          	not	a3,s11
ffffffffc0203b86:	96fd                	srai	a3,a3,0x3f
ffffffffc0203b88:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203b8c:	00144603          	lbu	a2,1(s0)
ffffffffc0203b90:	2d81                	sext.w	s11,s11
ffffffffc0203b92:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0203b94:	bf35                	j	ffffffffc0203ad0 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0203b96:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203b9a:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0203b9e:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203ba0:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0203ba2:	bfd9                	j	ffffffffc0203b78 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0203ba4:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0203ba6:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0203baa:	01174463          	blt	a4,a7,ffffffffc0203bb2 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0203bae:	1a088e63          	beqz	a7,ffffffffc0203d6a <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0203bb2:	000a3603          	ld	a2,0(s4)
ffffffffc0203bb6:	46c1                	li	a3,16
ffffffffc0203bb8:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0203bba:	2781                	sext.w	a5,a5
ffffffffc0203bbc:	876e                	mv	a4,s11
ffffffffc0203bbe:	85a6                	mv	a1,s1
ffffffffc0203bc0:	854a                	mv	a0,s2
ffffffffc0203bc2:	e37ff0ef          	jal	ra,ffffffffc02039f8 <printnum>
            break;
ffffffffc0203bc6:	bde1                	j	ffffffffc0203a9e <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0203bc8:	000a2503          	lw	a0,0(s4)
ffffffffc0203bcc:	85a6                	mv	a1,s1
ffffffffc0203bce:	0a21                	addi	s4,s4,8
ffffffffc0203bd0:	9902                	jalr	s2
            break;
ffffffffc0203bd2:	b5f1                	j	ffffffffc0203a9e <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0203bd4:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0203bd6:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0203bda:	01174463          	blt	a4,a7,ffffffffc0203be2 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0203bde:	18088163          	beqz	a7,ffffffffc0203d60 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0203be2:	000a3603          	ld	a2,0(s4)
ffffffffc0203be6:	46a9                	li	a3,10
ffffffffc0203be8:	8a2e                	mv	s4,a1
ffffffffc0203bea:	bfc1                	j	ffffffffc0203bba <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203bec:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0203bf0:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203bf2:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0203bf4:	bdf1                	j	ffffffffc0203ad0 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0203bf6:	85a6                	mv	a1,s1
ffffffffc0203bf8:	02500513          	li	a0,37
ffffffffc0203bfc:	9902                	jalr	s2
            break;
ffffffffc0203bfe:	b545                	j	ffffffffc0203a9e <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203c00:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0203c04:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203c06:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0203c08:	b5e1                	j	ffffffffc0203ad0 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0203c0a:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0203c0c:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0203c10:	01174463          	blt	a4,a7,ffffffffc0203c18 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0203c14:	14088163          	beqz	a7,ffffffffc0203d56 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0203c18:	000a3603          	ld	a2,0(s4)
ffffffffc0203c1c:	46a1                	li	a3,8
ffffffffc0203c1e:	8a2e                	mv	s4,a1
ffffffffc0203c20:	bf69                	j	ffffffffc0203bba <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0203c22:	03000513          	li	a0,48
ffffffffc0203c26:	85a6                	mv	a1,s1
ffffffffc0203c28:	e03e                	sd	a5,0(sp)
ffffffffc0203c2a:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0203c2c:	85a6                	mv	a1,s1
ffffffffc0203c2e:	07800513          	li	a0,120
ffffffffc0203c32:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0203c34:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0203c36:	6782                	ld	a5,0(sp)
ffffffffc0203c38:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0203c3a:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0203c3e:	bfb5                	j	ffffffffc0203bba <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0203c40:	000a3403          	ld	s0,0(s4)
ffffffffc0203c44:	008a0713          	addi	a4,s4,8
ffffffffc0203c48:	e03a                	sd	a4,0(sp)
ffffffffc0203c4a:	14040263          	beqz	s0,ffffffffc0203d8e <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0203c4e:	0fb05763          	blez	s11,ffffffffc0203d3c <vprintfmt+0x2d8>
ffffffffc0203c52:	02d00693          	li	a3,45
ffffffffc0203c56:	0cd79163          	bne	a5,a3,ffffffffc0203d18 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203c5a:	00044783          	lbu	a5,0(s0)
ffffffffc0203c5e:	0007851b          	sext.w	a0,a5
ffffffffc0203c62:	cf85                	beqz	a5,ffffffffc0203c9a <vprintfmt+0x236>
ffffffffc0203c64:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203c68:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203c6c:	000c4563          	bltz	s8,ffffffffc0203c76 <vprintfmt+0x212>
ffffffffc0203c70:	3c7d                	addiw	s8,s8,-1
ffffffffc0203c72:	036c0263          	beq	s8,s6,ffffffffc0203c96 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0203c76:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203c78:	0e0c8e63          	beqz	s9,ffffffffc0203d74 <vprintfmt+0x310>
ffffffffc0203c7c:	3781                	addiw	a5,a5,-32
ffffffffc0203c7e:	0ef47b63          	bgeu	s0,a5,ffffffffc0203d74 <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0203c82:	03f00513          	li	a0,63
ffffffffc0203c86:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203c88:	000a4783          	lbu	a5,0(s4)
ffffffffc0203c8c:	3dfd                	addiw	s11,s11,-1
ffffffffc0203c8e:	0a05                	addi	s4,s4,1
ffffffffc0203c90:	0007851b          	sext.w	a0,a5
ffffffffc0203c94:	ffe1                	bnez	a5,ffffffffc0203c6c <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0203c96:	01b05963          	blez	s11,ffffffffc0203ca8 <vprintfmt+0x244>
ffffffffc0203c9a:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0203c9c:	85a6                	mv	a1,s1
ffffffffc0203c9e:	02000513          	li	a0,32
ffffffffc0203ca2:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0203ca4:	fe0d9be3          	bnez	s11,ffffffffc0203c9a <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0203ca8:	6a02                	ld	s4,0(sp)
ffffffffc0203caa:	bbd5                	j	ffffffffc0203a9e <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0203cac:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0203cae:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0203cb2:	01174463          	blt	a4,a7,ffffffffc0203cba <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0203cb6:	08088d63          	beqz	a7,ffffffffc0203d50 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0203cba:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0203cbe:	0a044d63          	bltz	s0,ffffffffc0203d78 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0203cc2:	8622                	mv	a2,s0
ffffffffc0203cc4:	8a66                	mv	s4,s9
ffffffffc0203cc6:	46a9                	li	a3,10
ffffffffc0203cc8:	bdcd                	j	ffffffffc0203bba <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0203cca:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0203cce:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0203cd0:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0203cd2:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0203cd6:	8fb5                	xor	a5,a5,a3
ffffffffc0203cd8:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0203cdc:	02d74163          	blt	a4,a3,ffffffffc0203cfe <vprintfmt+0x29a>
ffffffffc0203ce0:	00369793          	slli	a5,a3,0x3
ffffffffc0203ce4:	97de                	add	a5,a5,s7
ffffffffc0203ce6:	639c                	ld	a5,0(a5)
ffffffffc0203ce8:	cb99                	beqz	a5,ffffffffc0203cfe <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0203cea:	86be                	mv	a3,a5
ffffffffc0203cec:	00000617          	auipc	a2,0x0
ffffffffc0203cf0:	21460613          	addi	a2,a2,532 # ffffffffc0203f00 <etext+0x2a>
ffffffffc0203cf4:	85a6                	mv	a1,s1
ffffffffc0203cf6:	854a                	mv	a0,s2
ffffffffc0203cf8:	0ce000ef          	jal	ra,ffffffffc0203dc6 <printfmt>
ffffffffc0203cfc:	b34d                	j	ffffffffc0203a9e <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0203cfe:	00002617          	auipc	a2,0x2
ffffffffc0203d02:	b4260613          	addi	a2,a2,-1214 # ffffffffc0205840 <default_pmm_manager+0xb38>
ffffffffc0203d06:	85a6                	mv	a1,s1
ffffffffc0203d08:	854a                	mv	a0,s2
ffffffffc0203d0a:	0bc000ef          	jal	ra,ffffffffc0203dc6 <printfmt>
ffffffffc0203d0e:	bb41                	j	ffffffffc0203a9e <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0203d10:	00002417          	auipc	s0,0x2
ffffffffc0203d14:	b2840413          	addi	s0,s0,-1240 # ffffffffc0205838 <default_pmm_manager+0xb30>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203d18:	85e2                	mv	a1,s8
ffffffffc0203d1a:	8522                	mv	a0,s0
ffffffffc0203d1c:	e43e                	sd	a5,8(sp)
ffffffffc0203d1e:	0e2000ef          	jal	ra,ffffffffc0203e00 <strnlen>
ffffffffc0203d22:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0203d26:	01b05b63          	blez	s11,ffffffffc0203d3c <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0203d2a:	67a2                	ld	a5,8(sp)
ffffffffc0203d2c:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203d30:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0203d32:	85a6                	mv	a1,s1
ffffffffc0203d34:	8552                	mv	a0,s4
ffffffffc0203d36:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203d38:	fe0d9ce3          	bnez	s11,ffffffffc0203d30 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203d3c:	00044783          	lbu	a5,0(s0)
ffffffffc0203d40:	00140a13          	addi	s4,s0,1
ffffffffc0203d44:	0007851b          	sext.w	a0,a5
ffffffffc0203d48:	d3a5                	beqz	a5,ffffffffc0203ca8 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203d4a:	05e00413          	li	s0,94
ffffffffc0203d4e:	bf39                	j	ffffffffc0203c6c <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0203d50:	000a2403          	lw	s0,0(s4)
ffffffffc0203d54:	b7ad                	j	ffffffffc0203cbe <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0203d56:	000a6603          	lwu	a2,0(s4)
ffffffffc0203d5a:	46a1                	li	a3,8
ffffffffc0203d5c:	8a2e                	mv	s4,a1
ffffffffc0203d5e:	bdb1                	j	ffffffffc0203bba <vprintfmt+0x156>
ffffffffc0203d60:	000a6603          	lwu	a2,0(s4)
ffffffffc0203d64:	46a9                	li	a3,10
ffffffffc0203d66:	8a2e                	mv	s4,a1
ffffffffc0203d68:	bd89                	j	ffffffffc0203bba <vprintfmt+0x156>
ffffffffc0203d6a:	000a6603          	lwu	a2,0(s4)
ffffffffc0203d6e:	46c1                	li	a3,16
ffffffffc0203d70:	8a2e                	mv	s4,a1
ffffffffc0203d72:	b5a1                	j	ffffffffc0203bba <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0203d74:	9902                	jalr	s2
ffffffffc0203d76:	bf09                	j	ffffffffc0203c88 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0203d78:	85a6                	mv	a1,s1
ffffffffc0203d7a:	02d00513          	li	a0,45
ffffffffc0203d7e:	e03e                	sd	a5,0(sp)
ffffffffc0203d80:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0203d82:	6782                	ld	a5,0(sp)
ffffffffc0203d84:	8a66                	mv	s4,s9
ffffffffc0203d86:	40800633          	neg	a2,s0
ffffffffc0203d8a:	46a9                	li	a3,10
ffffffffc0203d8c:	b53d                	j	ffffffffc0203bba <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0203d8e:	03b05163          	blez	s11,ffffffffc0203db0 <vprintfmt+0x34c>
ffffffffc0203d92:	02d00693          	li	a3,45
ffffffffc0203d96:	f6d79de3          	bne	a5,a3,ffffffffc0203d10 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0203d9a:	00002417          	auipc	s0,0x2
ffffffffc0203d9e:	a9e40413          	addi	s0,s0,-1378 # ffffffffc0205838 <default_pmm_manager+0xb30>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203da2:	02800793          	li	a5,40
ffffffffc0203da6:	02800513          	li	a0,40
ffffffffc0203daa:	00140a13          	addi	s4,s0,1
ffffffffc0203dae:	bd6d                	j	ffffffffc0203c68 <vprintfmt+0x204>
ffffffffc0203db0:	00002a17          	auipc	s4,0x2
ffffffffc0203db4:	a89a0a13          	addi	s4,s4,-1399 # ffffffffc0205839 <default_pmm_manager+0xb31>
ffffffffc0203db8:	02800513          	li	a0,40
ffffffffc0203dbc:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203dc0:	05e00413          	li	s0,94
ffffffffc0203dc4:	b565                	j	ffffffffc0203c6c <vprintfmt+0x208>

ffffffffc0203dc6 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0203dc6:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0203dc8:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0203dcc:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0203dce:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0203dd0:	ec06                	sd	ra,24(sp)
ffffffffc0203dd2:	f83a                	sd	a4,48(sp)
ffffffffc0203dd4:	fc3e                	sd	a5,56(sp)
ffffffffc0203dd6:	e0c2                	sd	a6,64(sp)
ffffffffc0203dd8:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0203dda:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0203ddc:	c89ff0ef          	jal	ra,ffffffffc0203a64 <vprintfmt>
}
ffffffffc0203de0:	60e2                	ld	ra,24(sp)
ffffffffc0203de2:	6161                	addi	sp,sp,80
ffffffffc0203de4:	8082                	ret

ffffffffc0203de6 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0203de6:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0203dea:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0203dec:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0203dee:	cb81                	beqz	a5,ffffffffc0203dfe <strlen+0x18>
        cnt ++;
ffffffffc0203df0:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0203df2:	00a707b3          	add	a5,a4,a0
ffffffffc0203df6:	0007c783          	lbu	a5,0(a5)
ffffffffc0203dfa:	fbfd                	bnez	a5,ffffffffc0203df0 <strlen+0xa>
ffffffffc0203dfc:	8082                	ret
    }
    return cnt;
}
ffffffffc0203dfe:	8082                	ret

ffffffffc0203e00 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0203e00:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0203e02:	e589                	bnez	a1,ffffffffc0203e0c <strnlen+0xc>
ffffffffc0203e04:	a811                	j	ffffffffc0203e18 <strnlen+0x18>
        cnt ++;
ffffffffc0203e06:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0203e08:	00f58863          	beq	a1,a5,ffffffffc0203e18 <strnlen+0x18>
ffffffffc0203e0c:	00f50733          	add	a4,a0,a5
ffffffffc0203e10:	00074703          	lbu	a4,0(a4)
ffffffffc0203e14:	fb6d                	bnez	a4,ffffffffc0203e06 <strnlen+0x6>
ffffffffc0203e16:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0203e18:	852e                	mv	a0,a1
ffffffffc0203e1a:	8082                	ret

ffffffffc0203e1c <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc0203e1c:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc0203e1e:	0005c703          	lbu	a4,0(a1)
ffffffffc0203e22:	0785                	addi	a5,a5,1
ffffffffc0203e24:	0585                	addi	a1,a1,1
ffffffffc0203e26:	fee78fa3          	sb	a4,-1(a5)
ffffffffc0203e2a:	fb75                	bnez	a4,ffffffffc0203e1e <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc0203e2c:	8082                	ret

ffffffffc0203e2e <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0203e2e:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203e32:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0203e36:	cb89                	beqz	a5,ffffffffc0203e48 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0203e38:	0505                	addi	a0,a0,1
ffffffffc0203e3a:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0203e3c:	fee789e3          	beq	a5,a4,ffffffffc0203e2e <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203e40:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0203e44:	9d19                	subw	a0,a0,a4
ffffffffc0203e46:	8082                	ret
ffffffffc0203e48:	4501                	li	a0,0
ffffffffc0203e4a:	bfed                	j	ffffffffc0203e44 <strcmp+0x16>

ffffffffc0203e4c <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0203e4c:	c20d                	beqz	a2,ffffffffc0203e6e <strncmp+0x22>
ffffffffc0203e4e:	962e                	add	a2,a2,a1
ffffffffc0203e50:	a031                	j	ffffffffc0203e5c <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0203e52:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0203e54:	00e79a63          	bne	a5,a4,ffffffffc0203e68 <strncmp+0x1c>
ffffffffc0203e58:	00b60b63          	beq	a2,a1,ffffffffc0203e6e <strncmp+0x22>
ffffffffc0203e5c:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0203e60:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0203e62:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0203e66:	f7f5                	bnez	a5,ffffffffc0203e52 <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203e68:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0203e6c:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203e6e:	4501                	li	a0,0
ffffffffc0203e70:	8082                	ret

ffffffffc0203e72 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0203e72:	00054783          	lbu	a5,0(a0)
ffffffffc0203e76:	c799                	beqz	a5,ffffffffc0203e84 <strchr+0x12>
        if (*s == c) {
ffffffffc0203e78:	00f58763          	beq	a1,a5,ffffffffc0203e86 <strchr+0x14>
    while (*s != '\0') {
ffffffffc0203e7c:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0203e80:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0203e82:	fbfd                	bnez	a5,ffffffffc0203e78 <strchr+0x6>
    }
    return NULL;
ffffffffc0203e84:	4501                	li	a0,0
}
ffffffffc0203e86:	8082                	ret

ffffffffc0203e88 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0203e88:	ca01                	beqz	a2,ffffffffc0203e98 <memset+0x10>
ffffffffc0203e8a:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0203e8c:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0203e8e:	0785                	addi	a5,a5,1
ffffffffc0203e90:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0203e94:	fec79de3          	bne	a5,a2,ffffffffc0203e8e <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0203e98:	8082                	ret

ffffffffc0203e9a <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc0203e9a:	ca19                	beqz	a2,ffffffffc0203eb0 <memcpy+0x16>
ffffffffc0203e9c:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc0203e9e:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc0203ea0:	0005c703          	lbu	a4,0(a1)
ffffffffc0203ea4:	0585                	addi	a1,a1,1
ffffffffc0203ea6:	0785                	addi	a5,a5,1
ffffffffc0203ea8:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc0203eac:	fec59ae3          	bne	a1,a2,ffffffffc0203ea0 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc0203eb0:	8082                	ret

ffffffffc0203eb2 <memcmp>:
 * */
int
memcmp(const void *v1, const void *v2, size_t n) {
    const char *s1 = (const char *)v1;
    const char *s2 = (const char *)v2;
    while (n -- > 0) {
ffffffffc0203eb2:	c205                	beqz	a2,ffffffffc0203ed2 <memcmp+0x20>
ffffffffc0203eb4:	962e                	add	a2,a2,a1
ffffffffc0203eb6:	a019                	j	ffffffffc0203ebc <memcmp+0xa>
ffffffffc0203eb8:	00c58d63          	beq	a1,a2,ffffffffc0203ed2 <memcmp+0x20>
        if (*s1 != *s2) {
ffffffffc0203ebc:	00054783          	lbu	a5,0(a0)
ffffffffc0203ec0:	0005c703          	lbu	a4,0(a1)
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
        }
        s1 ++, s2 ++;
ffffffffc0203ec4:	0505                	addi	a0,a0,1
ffffffffc0203ec6:	0585                	addi	a1,a1,1
        if (*s1 != *s2) {
ffffffffc0203ec8:	fee788e3          	beq	a5,a4,ffffffffc0203eb8 <memcmp+0x6>
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203ecc:	40e7853b          	subw	a0,a5,a4
ffffffffc0203ed0:	8082                	ret
    }
    return 0;
ffffffffc0203ed2:	4501                	li	a0,0
}
ffffffffc0203ed4:	8082                	ret
