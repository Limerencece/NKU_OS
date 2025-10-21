
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
kern_entry:
    # a0: hartid（当前硬件线程/内核编号）
    # a1: dtb physical address（设备树的物理地址，由上电/引导传入）
    # 保存hartid和dtb地址到全局变量，供C代码使用
    # 下面四句初始化的，与物理内存管理机制关系不大
    la t0, boot_hartid      # 取boot_hartid符号的当前地址（虚拟地址）
ffffffffc0200000:	00008297          	auipc	t0,0x8
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)            # 将hartid保存到内存
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0208000 <boot_hartid>
    la t0, boot_dtb         # 取boot_dtb符号的当前地址（虚拟地址）
ffffffffc020000c:	00008297          	auipc	t0,0x8
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0208008 <boot_dtb>
    sd a1, 0(t0)            # 将dtb物理地址保存到内存
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址（boot_page_table_sv39在链接时位于内核镜像中）
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02072b7          	lui	t0,0xc0207
    # t1 := 0xffffffff40000000 即虚实映射偏移量（高地址直映到物理低地址的偏移）
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc020001c:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200020:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    # t0 减去虚实映射偏移量 => 转换为boot_page_table_sv39的物理地址
    sub     t0, t0, t1
ffffffffc0200022:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    # 将物理地址右移12位 => 得到页表基址的物理页号（PPN），符合satp格式
    srli    t0, t0, 12
ffffffffc0200026:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置satp的MODE字段为Sv39（RISC-V 39位虚拟地址模式）
    li      t1, 8 << 60
ffffffffc020002a:	fff0031b          	addiw	t1,zero,-1
ffffffffc020002e:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    # 合并MODE与PPN，形成satp寄存器期望的值
    or      t0, t0, t1
ffffffffc0200030:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    # 写satp => 安装预设的三级页表，并切换到Sv39虚拟内存模式
    csrw    satp, t0
ffffffffc0200034:	18029073          	csrw	satp,t0
    # 刷新TLB，确保新的页表映射立即生效
    sfence.vma
ffffffffc0200038:	12000073          	sfence.vma
    #nop # 可能映射的位置有些bug。。插入一个nop
    # SATP告诉CPU页表在哪？虚拟地址怎么转换成物理地址？使用哪种页表模式？
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    # 设置栈指针sp到内核栈顶（虚拟地址），以支持后续C调用约定
    lui sp, %hi(bootstacktop)
ffffffffc020003c:	c0207137          	lui	sp,0xc0207

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	0d828293          	addi	t0,t0,216 # ffffffffc02000d8 <kern_init>
    jr t0                      # 无条件跳转到内核初始化函数
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <print_kerninfo>:
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * print_kerninfo - 打印内核的关键信息，包括入口地址、文本/数据段边界、
 * BSS结束地址以及内核映像占用的内存大小。
 * */
void print_kerninfo(void) {
ffffffffc020004a:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[]; // 链接器导出：文本段末、数据段末、BSS段末
    cprintf("Special kernel symbols:\n");
ffffffffc020004c:	00002517          	auipc	a0,0x2
ffffffffc0200050:	5a450513          	addi	a0,a0,1444 # ffffffffc02025f0 <etext+0x4>
void print_kerninfo(void) {
ffffffffc0200054:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200056:	0f6000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", (uintptr_t)kern_init); // 内核入口虚拟地址
ffffffffc020005a:	00000597          	auipc	a1,0x0
ffffffffc020005e:	07e58593          	addi	a1,a1,126 # ffffffffc02000d8 <kern_init>
ffffffffc0200062:	00002517          	auipc	a0,0x2
ffffffffc0200066:	5ae50513          	addi	a0,a0,1454 # ffffffffc0202610 <etext+0x24>
ffffffffc020006a:	0e2000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);                 // 文本段结束虚拟地址
ffffffffc020006e:	00002597          	auipc	a1,0x2
ffffffffc0200072:	57e58593          	addi	a1,a1,1406 # ffffffffc02025ec <etext>
ffffffffc0200076:	00002517          	auipc	a0,0x2
ffffffffc020007a:	5ba50513          	addi	a0,a0,1466 # ffffffffc0202630 <etext+0x44>
ffffffffc020007e:	0ce000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);                 // 数据段结束虚拟地址
ffffffffc0200082:	00008597          	auipc	a1,0x8
ffffffffc0200086:	f9658593          	addi	a1,a1,-106 # ffffffffc0208018 <buddy>
ffffffffc020008a:	00002517          	auipc	a0,0x2
ffffffffc020008e:	5c650513          	addi	a0,a0,1478 # ffffffffc0202650 <etext+0x64>
ffffffffc0200092:	0ba000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);                   // BSS段结束虚拟地址
ffffffffc0200096:	0000c597          	auipc	a1,0xc
ffffffffc020009a:	1a258593          	addi	a1,a1,418 # ffffffffc020c238 <end>
ffffffffc020009e:	00002517          	auipc	a0,0x2
ffffffffc02000a2:	5d250513          	addi	a0,a0,1490 # ffffffffc0202670 <etext+0x84>
ffffffffc02000a6:	0a6000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - (char*)kern_init + 1023) / 1024); // 内核镜像占用大小（入口到end）
ffffffffc02000aa:	0000c597          	auipc	a1,0xc
ffffffffc02000ae:	58d58593          	addi	a1,a1,1421 # ffffffffc020c637 <end+0x3ff>
ffffffffc02000b2:	00000797          	auipc	a5,0x0
ffffffffc02000b6:	02678793          	addi	a5,a5,38 # ffffffffc02000d8 <kern_init>
ffffffffc02000ba:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000be:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02000c2:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000c4:	3ff5f593          	andi	a1,a1,1023
ffffffffc02000c8:	95be                	add	a1,a1,a5
ffffffffc02000ca:	85a9                	srai	a1,a1,0xa
ffffffffc02000cc:	00002517          	auipc	a0,0x2
ffffffffc02000d0:	5c450513          	addi	a0,a0,1476 # ffffffffc0202690 <etext+0xa4>
}
ffffffffc02000d4:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000d6:	a89d                	j	ffffffffc020014c <cprintf>

ffffffffc02000d8 <kern_init>:

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata); // 清零BSS段，保证未初始化全局/静态变量为0
ffffffffc02000d8:	00008517          	auipc	a0,0x8
ffffffffc02000dc:	f4050513          	addi	a0,a0,-192 # ffffffffc0208018 <buddy>
ffffffffc02000e0:	0000c617          	auipc	a2,0xc
ffffffffc02000e4:	15860613          	addi	a2,a2,344 # ffffffffc020c238 <end>
int kern_init(void) {
ffffffffc02000e8:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata); // 清零BSS段，保证未初始化全局/静态变量为0
ffffffffc02000ea:	8e09                	sub	a2,a2,a0
ffffffffc02000ec:	4581                	li	a1,0
int kern_init(void) {
ffffffffc02000ee:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata); // 清零BSS段，保证未初始化全局/静态变量为0
ffffffffc02000f0:	4ea020ef          	jal	ra,ffffffffc02025da <memset>
    dtb_init();                    // 解析设备树，探测可用物理内存及硬件拓扑
ffffffffc02000f4:	12c000ef          	jal	ra,ffffffffc0200220 <dtb_init>
    cons_init();                   // 初始化控制台子系统，后续可用cprintf/cputs输出
ffffffffc02000f8:	11e000ef          	jal	ra,ffffffffc0200216 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0"; // 启动提示信息
    //cprintf("%s\n\n", message);
    cputs(message);               // 简单字符串输出（不带格式化）
ffffffffc02000fc:	00002517          	auipc	a0,0x2
ffffffffc0200100:	5c450513          	addi	a0,a0,1476 # ffffffffc02026c0 <etext+0xd4>
ffffffffc0200104:	07e000ef          	jal	ra,ffffffffc0200182 <cputs>

    print_kerninfo();             // 打印内核入口/段边界等信息，便于调试与核验
ffffffffc0200108:	f43ff0ef          	jal	ra,ffffffffc020004a <print_kerninfo>

    // grade_backtrace();
    pmm_init();                   // 物理内存管理初始化：分页大小、页框状态、空闲链表等
ffffffffc020010c:	316010ef          	jal	ra,ffffffffc0201422 <pmm_init>

    /* do nothing */
    while (1)
ffffffffc0200110:	a001                	j	ffffffffc0200110 <kern_init+0x38>

ffffffffc0200112 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200112:	1141                	addi	sp,sp,-16
ffffffffc0200114:	e022                	sd	s0,0(sp)
ffffffffc0200116:	e406                	sd	ra,8(sp)
ffffffffc0200118:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc020011a:	0fe000ef          	jal	ra,ffffffffc0200218 <cons_putc>
    (*cnt) ++;
ffffffffc020011e:	401c                	lw	a5,0(s0)
}
ffffffffc0200120:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc0200122:	2785                	addiw	a5,a5,1
ffffffffc0200124:	c01c                	sw	a5,0(s0)
}
ffffffffc0200126:	6402                	ld	s0,0(sp)
ffffffffc0200128:	0141                	addi	sp,sp,16
ffffffffc020012a:	8082                	ret

ffffffffc020012c <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc020012c:	1101                	addi	sp,sp,-32
ffffffffc020012e:	862a                	mv	a2,a0
ffffffffc0200130:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200132:	00000517          	auipc	a0,0x0
ffffffffc0200136:	fe050513          	addi	a0,a0,-32 # ffffffffc0200112 <cputch>
ffffffffc020013a:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc020013c:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc020013e:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200140:	084020ef          	jal	ra,ffffffffc02021c4 <vprintfmt>
    return cnt;
}
ffffffffc0200144:	60e2                	ld	ra,24(sp)
ffffffffc0200146:	4532                	lw	a0,12(sp)
ffffffffc0200148:	6105                	addi	sp,sp,32
ffffffffc020014a:	8082                	ret

ffffffffc020014c <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc020014c:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc020014e:	02810313          	addi	t1,sp,40 # ffffffffc0207028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc0200152:	8e2a                	mv	t3,a0
ffffffffc0200154:	f42e                	sd	a1,40(sp)
ffffffffc0200156:	f832                	sd	a2,48(sp)
ffffffffc0200158:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020015a:	00000517          	auipc	a0,0x0
ffffffffc020015e:	fb850513          	addi	a0,a0,-72 # ffffffffc0200112 <cputch>
ffffffffc0200162:	004c                	addi	a1,sp,4
ffffffffc0200164:	869a                	mv	a3,t1
ffffffffc0200166:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc0200168:	ec06                	sd	ra,24(sp)
ffffffffc020016a:	e0ba                	sd	a4,64(sp)
ffffffffc020016c:	e4be                	sd	a5,72(sp)
ffffffffc020016e:	e8c2                	sd	a6,80(sp)
ffffffffc0200170:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc0200172:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc0200174:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200176:	04e020ef          	jal	ra,ffffffffc02021c4 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc020017a:	60e2                	ld	ra,24(sp)
ffffffffc020017c:	4512                	lw	a0,4(sp)
ffffffffc020017e:	6125                	addi	sp,sp,96
ffffffffc0200180:	8082                	ret

ffffffffc0200182 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc0200182:	1101                	addi	sp,sp,-32
ffffffffc0200184:	e822                	sd	s0,16(sp)
ffffffffc0200186:	ec06                	sd	ra,24(sp)
ffffffffc0200188:	e426                	sd	s1,8(sp)
ffffffffc020018a:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc020018c:	00054503          	lbu	a0,0(a0)
ffffffffc0200190:	c51d                	beqz	a0,ffffffffc02001be <cputs+0x3c>
ffffffffc0200192:	0405                	addi	s0,s0,1
ffffffffc0200194:	4485                	li	s1,1
ffffffffc0200196:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc0200198:	080000ef          	jal	ra,ffffffffc0200218 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc020019c:	00044503          	lbu	a0,0(s0)
ffffffffc02001a0:	008487bb          	addw	a5,s1,s0
ffffffffc02001a4:	0405                	addi	s0,s0,1
ffffffffc02001a6:	f96d                	bnez	a0,ffffffffc0200198 <cputs+0x16>
    (*cnt) ++;
ffffffffc02001a8:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc02001ac:	4529                	li	a0,10
ffffffffc02001ae:	06a000ef          	jal	ra,ffffffffc0200218 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001b2:	60e2                	ld	ra,24(sp)
ffffffffc02001b4:	8522                	mv	a0,s0
ffffffffc02001b6:	6442                	ld	s0,16(sp)
ffffffffc02001b8:	64a2                	ld	s1,8(sp)
ffffffffc02001ba:	6105                	addi	sp,sp,32
ffffffffc02001bc:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc02001be:	4405                	li	s0,1
ffffffffc02001c0:	b7f5                	j	ffffffffc02001ac <cputs+0x2a>

ffffffffc02001c2 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02001c2:	0000c317          	auipc	t1,0xc
ffffffffc02001c6:	02e30313          	addi	t1,t1,46 # ffffffffc020c1f0 <is_panic>
ffffffffc02001ca:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02001ce:	715d                	addi	sp,sp,-80
ffffffffc02001d0:	ec06                	sd	ra,24(sp)
ffffffffc02001d2:	e822                	sd	s0,16(sp)
ffffffffc02001d4:	f436                	sd	a3,40(sp)
ffffffffc02001d6:	f83a                	sd	a4,48(sp)
ffffffffc02001d8:	fc3e                	sd	a5,56(sp)
ffffffffc02001da:	e0c2                	sd	a6,64(sp)
ffffffffc02001dc:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02001de:	000e0363          	beqz	t3,ffffffffc02001e4 <__panic+0x22>
    vcprintf(fmt, ap);
    cprintf("\n");
    va_end(ap);

panic_dead:
    while (1) {
ffffffffc02001e2:	a001                	j	ffffffffc02001e2 <__panic+0x20>
    is_panic = 1;
ffffffffc02001e4:	4785                	li	a5,1
ffffffffc02001e6:	00f32023          	sw	a5,0(t1)
    va_start(ap, fmt);
ffffffffc02001ea:	8432                	mv	s0,a2
ffffffffc02001ec:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001ee:	862e                	mv	a2,a1
ffffffffc02001f0:	85aa                	mv	a1,a0
ffffffffc02001f2:	00002517          	auipc	a0,0x2
ffffffffc02001f6:	4ee50513          	addi	a0,a0,1262 # ffffffffc02026e0 <etext+0xf4>
    va_start(ap, fmt);
ffffffffc02001fa:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001fc:	f51ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200200:	65a2                	ld	a1,8(sp)
ffffffffc0200202:	8522                	mv	a0,s0
ffffffffc0200204:	f29ff0ef          	jal	ra,ffffffffc020012c <vcprintf>
    cprintf("\n");
ffffffffc0200208:	00002517          	auipc	a0,0x2
ffffffffc020020c:	4b050513          	addi	a0,a0,1200 # ffffffffc02026b8 <etext+0xcc>
ffffffffc0200210:	f3dff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200214:	b7f9                	j	ffffffffc02001e2 <__panic+0x20>

ffffffffc0200216 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200216:	8082                	ret

ffffffffc0200218 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200218:	0ff57513          	zext.b	a0,a0
ffffffffc020021c:	32a0206f          	j	ffffffffc0202546 <sbi_console_putchar>

ffffffffc0200220 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;   // 内存基地址
static uint64_t memory_size = 0;   // 内存大小

void dtb_init(void) {
ffffffffc0200220:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc0200222:	00002517          	auipc	a0,0x2
ffffffffc0200226:	4de50513          	addi	a0,a0,1246 # ffffffffc0202700 <etext+0x114>
void dtb_init(void) {
ffffffffc020022a:	fc86                	sd	ra,120(sp)
ffffffffc020022c:	f8a2                	sd	s0,112(sp)
ffffffffc020022e:	e8d2                	sd	s4,80(sp)
ffffffffc0200230:	f4a6                	sd	s1,104(sp)
ffffffffc0200232:	f0ca                	sd	s2,96(sp)
ffffffffc0200234:	ecce                	sd	s3,88(sp)
ffffffffc0200236:	e4d6                	sd	s5,72(sp)
ffffffffc0200238:	e0da                	sd	s6,64(sp)
ffffffffc020023a:	fc5e                	sd	s7,56(sp)
ffffffffc020023c:	f862                	sd	s8,48(sp)
ffffffffc020023e:	f466                	sd	s9,40(sp)
ffffffffc0200240:	f06a                	sd	s10,32(sp)
ffffffffc0200242:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc0200244:	f09ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);      // 打印硬件线程ID
ffffffffc0200248:	00008597          	auipc	a1,0x8
ffffffffc020024c:	db85b583          	ld	a1,-584(a1) # ffffffffc0208000 <boot_hartid>
ffffffffc0200250:	00002517          	auipc	a0,0x2
ffffffffc0200254:	4c050513          	addi	a0,a0,1216 # ffffffffc0202710 <etext+0x124>
ffffffffc0200258:	ef5ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);  // 打印DTB地址
ffffffffc020025c:	00008417          	auipc	s0,0x8
ffffffffc0200260:	dac40413          	addi	s0,s0,-596 # ffffffffc0208008 <boot_dtb>
ffffffffc0200264:	600c                	ld	a1,0(s0)
ffffffffc0200266:	00002517          	auipc	a0,0x2
ffffffffc020026a:	4ba50513          	addi	a0,a0,1210 # ffffffffc0202720 <etext+0x134>
ffffffffc020026e:	edfff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200272:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");  // DTB地址为空错误
ffffffffc0200276:	00002517          	auipc	a0,0x2
ffffffffc020027a:	4c250513          	addi	a0,a0,1218 # ffffffffc0202738 <etext+0x14c>
    if (boot_dtb == 0) {
ffffffffc020027e:	120a0463          	beqz	s4,ffffffffc02003a6 <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;  // 物理地址转虚拟地址
ffffffffc0200282:	57f5                	li	a5,-3
ffffffffc0200284:	07fa                	slli	a5,a5,0x1e
ffffffffc0200286:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;  // DTB头部
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);  // 读取魔数
ffffffffc020028a:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020028c:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);  // 大端转小端
ffffffffc0200290:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200292:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200296:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);  // 大端转小端
ffffffffc020029a:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020029e:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);  // 大端转小端
ffffffffc02002a2:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002a6:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);  // 大端转小端
ffffffffc02002a8:	8ec9                	or	a3,a3,a0
ffffffffc02002aa:	0087979b          	slliw	a5,a5,0x8
ffffffffc02002ae:	1b7d                	addi	s6,s6,-1
ffffffffc02002b0:	0167f7b3          	and	a5,a5,s6
ffffffffc02002b4:	8dd5                	or	a1,a1,a3
ffffffffc02002b6:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc02002b8:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);  // 大端转小端
ffffffffc02002bc:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc02002be:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed3cb5>
ffffffffc02002c2:	10f59163          	bne	a1,a5,ffffffffc02003c4 <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc02002c6:	471c                	lw	a5,8(a4)
ffffffffc02002c8:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;  // 是否在memory节点中
ffffffffc02002ca:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002cc:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02002d0:	0086d51b          	srliw	a0,a3,0x8
ffffffffc02002d4:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);  // 大端转小端
ffffffffc02002d8:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002dc:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);  // 大端转小端
ffffffffc02002e0:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002e4:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);  // 大端转小端
ffffffffc02002e8:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002ec:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);  // 大端转小端
ffffffffc02002f0:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002f4:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);  // 大端转小端
ffffffffc02002f6:	01146433          	or	s0,s0,a7
ffffffffc02002fa:	0086969b          	slliw	a3,a3,0x8
ffffffffc02002fe:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200302:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);  // 大端转小端
ffffffffc0200304:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200308:	8c49                	or	s0,s0,a0
ffffffffc020030a:	0166f6b3          	and	a3,a3,s6
ffffffffc020030e:	00ca6a33          	or	s4,s4,a2
ffffffffc0200312:	0167f7b3          	and	a5,a5,s6
ffffffffc0200316:	8c55                	or	s0,s0,a3
ffffffffc0200318:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);  // 字符串基地址
ffffffffc020031c:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);  // 结构体指针
ffffffffc020031e:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);  // 字符串基地址
ffffffffc0200320:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);  // 结构体指针
ffffffffc0200322:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);  // 字符串基地址
ffffffffc0200326:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);  // 结构体指针
ffffffffc0200328:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020032a:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc020032e:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200330:	00002917          	auipc	s2,0x2
ffffffffc0200334:	45890913          	addi	s2,s2,1112 # ffffffffc0202788 <etext+0x19c>
ffffffffc0200338:	49bd                	li	s3,15
        switch (token) {
ffffffffc020033a:	4d91                	li	s11,4
ffffffffc020033c:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020033e:	00002497          	auipc	s1,0x2
ffffffffc0200342:	44248493          	addi	s1,s1,1090 # ffffffffc0202780 <etext+0x194>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);  // 读取token
ffffffffc0200346:	000a2703          	lw	a4,0(s4)
ffffffffc020034a:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020034e:	0087569b          	srliw	a3,a4,0x8
ffffffffc0200352:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);  // 大端转小端
ffffffffc0200356:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020035a:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);  // 大端转小端
ffffffffc020035e:	0107571b          	srliw	a4,a4,0x10
ffffffffc0200362:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200364:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);  // 大端转小端
ffffffffc0200368:	0087171b          	slliw	a4,a4,0x8
ffffffffc020036c:	8fd5                	or	a5,a5,a3
ffffffffc020036e:	00eb7733          	and	a4,s6,a4
ffffffffc0200372:	8fd9                	or	a5,a5,a4
ffffffffc0200374:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc0200376:	09778c63          	beq	a5,s7,ffffffffc020040e <dtb_init+0x1ee>
ffffffffc020037a:	00fbea63          	bltu	s7,a5,ffffffffc020038e <dtb_init+0x16e>
ffffffffc020037e:	07a78663          	beq	a5,s10,ffffffffc02003ea <dtb_init+0x1ca>
ffffffffc0200382:	4709                	li	a4,2
ffffffffc0200384:	00e79763          	bne	a5,a4,ffffffffc0200392 <dtb_init+0x172>
ffffffffc0200388:	4c81                	li	s9,0
ffffffffc020038a:	8a56                	mv	s4,s5
ffffffffc020038c:	bf6d                	j	ffffffffc0200346 <dtb_init+0x126>
ffffffffc020038e:	ffb78ee3          	beq	a5,s11,ffffffffc020038a <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);  // 内存结束地址
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;  // 设置全局内存基地址
        memory_size = mem_size;  // 设置全局内存大小
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");  // 提取内存信息失败
ffffffffc0200392:	00002517          	auipc	a0,0x2
ffffffffc0200396:	46e50513          	addi	a0,a0,1134 # ffffffffc0202800 <etext+0x214>
ffffffffc020039a:	db3ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    }
    cprintf("DTB init completed\n");  // DTB初始化完成
ffffffffc020039e:	00002517          	auipc	a0,0x2
ffffffffc02003a2:	49a50513          	addi	a0,a0,1178 # ffffffffc0202838 <etext+0x24c>
}
ffffffffc02003a6:	7446                	ld	s0,112(sp)
ffffffffc02003a8:	70e6                	ld	ra,120(sp)
ffffffffc02003aa:	74a6                	ld	s1,104(sp)
ffffffffc02003ac:	7906                	ld	s2,96(sp)
ffffffffc02003ae:	69e6                	ld	s3,88(sp)
ffffffffc02003b0:	6a46                	ld	s4,80(sp)
ffffffffc02003b2:	6aa6                	ld	s5,72(sp)
ffffffffc02003b4:	6b06                	ld	s6,64(sp)
ffffffffc02003b6:	7be2                	ld	s7,56(sp)
ffffffffc02003b8:	7c42                	ld	s8,48(sp)
ffffffffc02003ba:	7ca2                	ld	s9,40(sp)
ffffffffc02003bc:	7d02                	ld	s10,32(sp)
ffffffffc02003be:	6de2                	ld	s11,24(sp)
ffffffffc02003c0:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");  // DTB初始化完成
ffffffffc02003c2:	b369                	j	ffffffffc020014c <cprintf>
}
ffffffffc02003c4:	7446                	ld	s0,112(sp)
ffffffffc02003c6:	70e6                	ld	ra,120(sp)
ffffffffc02003c8:	74a6                	ld	s1,104(sp)
ffffffffc02003ca:	7906                	ld	s2,96(sp)
ffffffffc02003cc:	69e6                	ld	s3,88(sp)
ffffffffc02003ce:	6a46                	ld	s4,80(sp)
ffffffffc02003d0:	6aa6                	ld	s5,72(sp)
ffffffffc02003d2:	6b06                	ld	s6,64(sp)
ffffffffc02003d4:	7be2                	ld	s7,56(sp)
ffffffffc02003d6:	7c42                	ld	s8,48(sp)
ffffffffc02003d8:	7ca2                	ld	s9,40(sp)
ffffffffc02003da:	7d02                	ld	s10,32(sp)
ffffffffc02003dc:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);  // 魔数验证失败
ffffffffc02003de:	00002517          	auipc	a0,0x2
ffffffffc02003e2:	37a50513          	addi	a0,a0,890 # ffffffffc0202758 <etext+0x16c>
}
ffffffffc02003e6:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);  // 魔数验证失败
ffffffffc02003e8:	b395                	j	ffffffffc020014c <cprintf>
                int name_len = strlen(name);
ffffffffc02003ea:	8556                	mv	a0,s5
ffffffffc02003ec:	174020ef          	jal	ra,ffffffffc0202560 <strlen>
ffffffffc02003f0:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003f2:	4619                	li	a2,6
ffffffffc02003f4:	85a6                	mv	a1,s1
ffffffffc02003f6:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc02003f8:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003fa:	1ba020ef          	jal	ra,ffffffffc02025b4 <strncmp>
ffffffffc02003fe:	e111                	bnez	a0,ffffffffc0200402 <dtb_init+0x1e2>
                    in_memory_node = 1;  // 标记进入memory节点
ffffffffc0200400:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc0200402:	0a91                	addi	s5,s5,4
ffffffffc0200404:	9ad2                	add	s5,s5,s4
ffffffffc0200406:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc020040a:	8a56                	mv	s4,s5
ffffffffc020040c:	bf2d                	j	ffffffffc0200346 <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);      // 属性长度
ffffffffc020040e:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);  // 属性名偏移
ffffffffc0200412:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200416:	0087d71b          	srliw	a4,a5,0x8
ffffffffc020041a:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);  // 大端转小端
ffffffffc020041e:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200422:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);  // 大端转小端
ffffffffc0200426:	0107d79b          	srliw	a5,a5,0x10
ffffffffc020042a:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020042e:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);  // 大端转小端
ffffffffc0200432:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200436:	00eaeab3          	or	s5,s5,a4
ffffffffc020043a:	00fb77b3          	and	a5,s6,a5
ffffffffc020043e:	00faeab3          	or	s5,s5,a5
ffffffffc0200442:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200444:	000c9c63          	bnez	s9,ffffffffc020045c <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc0200448:	1a82                	slli	s5,s5,0x20
ffffffffc020044a:	00368793          	addi	a5,a3,3
ffffffffc020044e:	020ada93          	srli	s5,s5,0x20
ffffffffc0200452:	9abe                	add	s5,s5,a5
ffffffffc0200454:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200458:	8a56                	mv	s4,s5
ffffffffc020045a:	b5f5                	j	ffffffffc0200346 <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);  // 属性名偏移
ffffffffc020045c:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200460:	85ca                	mv	a1,s2
ffffffffc0200462:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200464:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);  // 大端转小端
ffffffffc0200468:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020046c:	0187971b          	slliw	a4,a5,0x18
ffffffffc0200470:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);  // 大端转小端
ffffffffc0200474:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200478:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020047a:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);  // 大端转小端
ffffffffc020047e:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200482:	8d59                	or	a0,a0,a4
ffffffffc0200484:	00fb77b3          	and	a5,s6,a5
ffffffffc0200488:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;  // 属性名
ffffffffc020048a:	1502                	slli	a0,a0,0x20
ffffffffc020048c:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020048e:	9522                	add	a0,a0,s0
ffffffffc0200490:	106020ef          	jal	ra,ffffffffc0202596 <strcmp>
ffffffffc0200494:	66a2                	ld	a3,8(sp)
ffffffffc0200496:	f94d                	bnez	a0,ffffffffc0200448 <dtb_init+0x228>
ffffffffc0200498:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200448 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);  // 内存基地址
ffffffffc020049c:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);  // 内存大小
ffffffffc02004a0:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc02004a4:	00002517          	auipc	a0,0x2
ffffffffc02004a8:	2ec50513          	addi	a0,a0,748 # ffffffffc0202790 <etext+0x1a4>
           fdt32_to_cpu(x >> 32);  // 大端转小端（64位）
ffffffffc02004ac:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004b0:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);  // 大端转小端（64位）
ffffffffc02004b4:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);  // 大端转小端
ffffffffc02004b8:	0187de1b          	srliw	t3,a5,0x18
ffffffffc02004bc:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004c0:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);  // 大端转小端
ffffffffc02004c4:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004c8:	0187d693          	srli	a3,a5,0x18
ffffffffc02004cc:	01861f1b          	slliw	t5,a2,0x18
ffffffffc02004d0:	0087579b          	srliw	a5,a4,0x8
ffffffffc02004d4:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);  // 大端转小端
ffffffffc02004d8:	0106561b          	srliw	a2,a2,0x10
ffffffffc02004dc:	010f6f33          	or	t5,t5,a6
ffffffffc02004e0:	0187529b          	srliw	t0,a4,0x18
ffffffffc02004e4:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004e8:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);  // 大端转小端
ffffffffc02004ec:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004f0:	0186f6b3          	and	a3,a3,s8
ffffffffc02004f4:	01859e1b          	slliw	t3,a1,0x18
ffffffffc02004f8:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);  // 大端转小端
ffffffffc02004fc:	0107581b          	srliw	a6,a4,0x10
ffffffffc0200500:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200504:	8361                	srli	a4,a4,0x18
ffffffffc0200506:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);  // 大端转小端
ffffffffc020050a:	0105d59b          	srliw	a1,a1,0x10
ffffffffc020050e:	01e6e6b3          	or	a3,a3,t5
ffffffffc0200512:	00cb7633          	and	a2,s6,a2
ffffffffc0200516:	0088181b          	slliw	a6,a6,0x8
ffffffffc020051a:	0085959b          	slliw	a1,a1,0x8
ffffffffc020051e:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200522:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);  // 大端转小端
ffffffffc0200526:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020052a:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);  // 大端转小端
ffffffffc020052e:	0088989b          	slliw	a7,a7,0x8
ffffffffc0200532:	011b78b3          	and	a7,s6,a7
ffffffffc0200536:	005eeeb3          	or	t4,t4,t0
ffffffffc020053a:	00c6e733          	or	a4,a3,a2
ffffffffc020053e:	006c6c33          	or	s8,s8,t1
ffffffffc0200542:	010b76b3          	and	a3,s6,a6
ffffffffc0200546:	00bb7b33          	and	s6,s6,a1
ffffffffc020054a:	01d7e7b3          	or	a5,a5,t4
ffffffffc020054e:	016c6b33          	or	s6,s8,s6
ffffffffc0200552:	01146433          	or	s0,s0,a7
ffffffffc0200556:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);  // 大端转小端（64位）
ffffffffc0200558:	1702                	slli	a4,a4,0x20
ffffffffc020055a:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020055c:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);  // 大端转小端（64位）
ffffffffc020055e:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200560:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);  // 大端转小端（64位）
ffffffffc0200562:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200566:	0167eb33          	or	s6,a5,s6
ffffffffc020056a:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc020056c:	be1ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);        // 内存基地址
ffffffffc0200570:	85a2                	mv	a1,s0
ffffffffc0200572:	00002517          	auipc	a0,0x2
ffffffffc0200576:	23e50513          	addi	a0,a0,574 # ffffffffc02027b0 <etext+0x1c4>
ffffffffc020057a:	bd3ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));  // 内存大小
ffffffffc020057e:	014b5613          	srli	a2,s6,0x14
ffffffffc0200582:	85da                	mv	a1,s6
ffffffffc0200584:	00002517          	auipc	a0,0x2
ffffffffc0200588:	24450513          	addi	a0,a0,580 # ffffffffc02027c8 <etext+0x1dc>
ffffffffc020058c:	bc1ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);  // 内存结束地址
ffffffffc0200590:	008b05b3          	add	a1,s6,s0
ffffffffc0200594:	15fd                	addi	a1,a1,-1
ffffffffc0200596:	00002517          	auipc	a0,0x2
ffffffffc020059a:	25250513          	addi	a0,a0,594 # ffffffffc02027e8 <etext+0x1fc>
ffffffffc020059e:	bafff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("DTB init completed\n");  // DTB初始化完成
ffffffffc02005a2:	00002517          	auipc	a0,0x2
ffffffffc02005a6:	29650513          	addi	a0,a0,662 # ffffffffc0202838 <etext+0x24c>
        memory_base = mem_base;  // 设置全局内存基地址
ffffffffc02005aa:	0000c797          	auipc	a5,0xc
ffffffffc02005ae:	c487b723          	sd	s0,-946(a5) # ffffffffc020c1f8 <memory_base>
        memory_size = mem_size;  // 设置全局内存大小
ffffffffc02005b2:	0000c797          	auipc	a5,0xc
ffffffffc02005b6:	c567b723          	sd	s6,-946(a5) # ffffffffc020c200 <memory_size>
    cprintf("DTB init completed\n");  // DTB初始化完成
ffffffffc02005ba:	b3f5                	j	ffffffffc02003a6 <dtb_init+0x186>

ffffffffc02005bc <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;  // 获取内存基地址
}
ffffffffc02005bc:	0000c517          	auipc	a0,0xc
ffffffffc02005c0:	c3c53503          	ld	a0,-964(a0) # ffffffffc020c1f8 <memory_base>
ffffffffc02005c4:	8082                	ret

ffffffffc02005c6 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;  // 获取内存大小
ffffffffc02005c6:	0000c517          	auipc	a0,0xc
ffffffffc02005ca:	c3a53503          	ld	a0,-966(a0) # ffffffffc020c200 <memory_size>
ffffffffc02005ce:	8082                	ret

ffffffffc02005d0 <buddy_init>:

static void
buddy_init(void) {
    // 初始化buddy system，这里暂时不分配内存
    // 实际的初始化在buddy_init_memmap中进行
    buddy.size = 0;         // 初始大小为0
ffffffffc02005d0:	00008797          	auipc	a5,0x8
ffffffffc02005d4:	a4878793          	addi	a5,a5,-1464 # ffffffffc0208018 <buddy>
ffffffffc02005d8:	0007a023          	sw	zero,0(a5)
    buddy.longest = NULL;   // 二叉树数组指针为空
ffffffffc02005dc:	0007b423          	sd	zero,8(a5)
    buddy.base = NULL;      // 内存基地址为空
ffffffffc02005e0:	0007b823          	sd	zero,16(a5)
}
ffffffffc02005e4:	8082                	ret

ffffffffc02005e6 <buddy_nr_free_pages>:

static size_t
buddy_nr_free_pages(void) {
    // 返回当前可用的页面数
    // 这里我们返回根节点的最大可用块大小
    if (buddy.longest == NULL)  // 如果未初始化
ffffffffc02005e6:	00008797          	auipc	a5,0x8
ffffffffc02005ea:	a3a7b783          	ld	a5,-1478(a5) # ffffffffc0208020 <buddy+0x8>
ffffffffc02005ee:	c781                	beqz	a5,ffffffffc02005f6 <buddy_nr_free_pages+0x10>
        return 0;               // 返回0
    return buddy.longest[0];    // 返回根节点的可用大小
ffffffffc02005f0:	0007e503          	lwu	a0,0(a5)
ffffffffc02005f4:	8082                	ret
        return 0;               // 返回0
ffffffffc02005f6:	4501                	li	a0,0
}
ffffffffc02005f8:	8082                	ret

ffffffffc02005fa <show_page_info>:
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02005fa:	0000c717          	auipc	a4,0xc
ffffffffc02005fe:	c1673703          	ld	a4,-1002(a4) # ffffffffc020c210 <pages>
ffffffffc0200602:	40e50733          	sub	a4,a0,a4
// Buddy system专用的测试函数、

// 辅助函数：显示被分配页面的详细地址信息
static void show_page_info(struct Page *page, size_t n, const char *desc) {
    // 计算页面在pages数组中的索引
    size_t page_index = page - buddy.base;  // 页面索引 = 页面地址 - 基址
ffffffffc0200606:	00004897          	auipc	a7,0x4
ffffffffc020060a:	ada8b883          	ld	a7,-1318(a7) # ffffffffc02040e0 <error_string+0x38>
ffffffffc020060e:	00008797          	auipc	a5,0x8
ffffffffc0200612:	a1a7b783          	ld	a5,-1510(a5) # ffffffffc0208028 <buddy+0x10>
ffffffffc0200616:	870d                	srai	a4,a4,0x3
ffffffffc0200618:	8d1d                	sub	a0,a0,a5
ffffffffc020061a:	03170733          	mul	a4,a4,a7
ffffffffc020061e:	850d                	srai	a0,a0,0x3
    // 使用系统提供的page2pa函数计算物理地址
    uintptr_t phys_addr = page2pa(page);  // 调用系统函数获取物理地址
    
    cprintf("  %s: 页面索引[%d-%d], 物理地址[0x%08x-0x%08x], 大小%dKB\n", 
            desc, page_index, page_index + n - 1,  // 页面索引范围
            phys_addr, phys_addr + n * PGSIZE - 1,  // 物理地址范围
ffffffffc0200620:	00c59813          	slli	a6,a1,0xc
static void show_page_info(struct Page *page, size_t n, const char *desc) {
ffffffffc0200624:	86ae                	mv	a3,a1
ffffffffc0200626:	85b2                	mv	a1,a2
    cprintf("  %s: 页面索引[%d-%d], 物理地址[0x%08x-0x%08x], 大小%dKB\n", 
ffffffffc0200628:	fff80793          	addi	a5,a6,-1
ffffffffc020062c:	16fd                	addi	a3,a3,-1
ffffffffc020062e:	00a85813          	srli	a6,a6,0xa
    size_t page_index = page - buddy.base;  // 页面索引 = 页面地址 - 基址
ffffffffc0200632:	03150633          	mul	a2,a0,a7
ffffffffc0200636:	00004517          	auipc	a0,0x4
ffffffffc020063a:	ab253503          	ld	a0,-1358(a0) # ffffffffc02040e8 <nbase>
ffffffffc020063e:	972a                	add	a4,a4,a0

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc0200640:	0732                	slli	a4,a4,0xc
    cprintf("  %s: 页面索引[%d-%d], 物理地址[0x%08x-0x%08x], 大小%dKB\n", 
ffffffffc0200642:	97ba                	add	a5,a5,a4
ffffffffc0200644:	00002517          	auipc	a0,0x2
ffffffffc0200648:	20c50513          	addi	a0,a0,524 # ffffffffc0202850 <etext+0x264>
ffffffffc020064c:	96b2                	add	a3,a3,a2
ffffffffc020064e:	bcfd                	j	ffffffffc020014c <cprintf>

ffffffffc0200650 <buddy_free_pages>:
buddy_free_pages(struct Page *base, size_t n) {
ffffffffc0200650:	1141                	addi	sp,sp,-16
ffffffffc0200652:	e406                	sd	ra,8(sp)
    assert(n > 0);          // 确保释放页面数大于0
ffffffffc0200654:	10058d63          	beqz	a1,ffffffffc020076e <buddy_free_pages+0x11e>
    assert(base >= buddy.base && base < buddy.base + buddy.size);  // 检查页面有效性
ffffffffc0200658:	00008617          	auipc	a2,0x8
ffffffffc020065c:	9c060613          	addi	a2,a2,-1600 # ffffffffc0208018 <buddy>
ffffffffc0200660:	6a1c                	ld	a5,16(a2)
ffffffffc0200662:	0ef56663          	bltu	a0,a5,ffffffffc020074e <buddy_free_pages+0xfe>
ffffffffc0200666:	4218                	lw	a4,0(a2)
ffffffffc0200668:	02071813          	slli	a6,a4,0x20
ffffffffc020066c:	02085813          	srli	a6,a6,0x20
ffffffffc0200670:	00281693          	slli	a3,a6,0x2
ffffffffc0200674:	96c2                	add	a3,a3,a6
ffffffffc0200676:	068e                	slli	a3,a3,0x3
ffffffffc0200678:	96be                	add	a3,a3,a5
ffffffffc020067a:	0cd57a63          	bgeu	a0,a3,ffffffffc020074e <buddy_free_pages+0xfe>
    unsigned offset = base - buddy.base;  // 计算页面在数组中的偏移
ffffffffc020067e:	40f507b3          	sub	a5,a0,a5
ffffffffc0200682:	878d                	srai	a5,a5,0x3
ffffffffc0200684:	00004697          	auipc	a3,0x4
ffffffffc0200688:	a5c6b683          	ld	a3,-1444(a3) # ffffffffc02040e0 <error_string+0x38>
ffffffffc020068c:	02d786b3          	mul	a3,a5,a3
    unsigned index = offset + buddy.size - 1;  // 计算叶子节点索引
ffffffffc0200690:	fff7079b          	addiw	a5,a4,-1
    for (; buddy.longest[index]; index = PARENT(index)) {  // 向上查找直到找到已分配的节点
ffffffffc0200694:	00863883          	ld	a7,8(a2)
    unsigned index = offset + buddy.size - 1;  // 计算叶子节点索引
ffffffffc0200698:	9fb5                	addw	a5,a5,a3
    for (; buddy.longest[index]; index = PARENT(index)) {  // 向上查找直到找到已分配的节点
ffffffffc020069a:	02079693          	slli	a3,a5,0x20
ffffffffc020069e:	01e6d713          	srli	a4,a3,0x1e
ffffffffc02006a2:	9746                	add	a4,a4,a7
ffffffffc02006a4:	4314                	lw	a3,0(a4)
ffffffffc02006a6:	c2cd                	beqz	a3,ffffffffc0200748 <buddy_free_pages+0xf8>
        node_size *= 2;     // 节点大小加倍
ffffffffc02006a8:	4689                	li	a3,2
        if (index == 0)     // 如果到达根节点
ffffffffc02006aa:	e789                	bnez	a5,ffffffffc02006b4 <buddy_free_pages+0x64>
ffffffffc02006ac:	a849                	j	ffffffffc020073e <buddy_free_pages+0xee>
        node_size *= 2;     // 节点大小加倍
ffffffffc02006ae:	0016969b          	slliw	a3,a3,0x1
        if (index == 0)     // 如果到达根节点
ffffffffc02006b2:	c7d1                	beqz	a5,ffffffffc020073e <buddy_free_pages+0xee>
    for (; buddy.longest[index]; index = PARENT(index)) {  // 向上查找直到找到已分配的节点
ffffffffc02006b4:	2785                	addiw	a5,a5,1
ffffffffc02006b6:	0017d79b          	srliw	a5,a5,0x1
ffffffffc02006ba:	37fd                	addiw	a5,a5,-1
ffffffffc02006bc:	02079613          	slli	a2,a5,0x20
ffffffffc02006c0:	01e65713          	srli	a4,a2,0x1e
ffffffffc02006c4:	9746                	add	a4,a4,a7
ffffffffc02006c6:	4310                	lw	a2,0(a4)
ffffffffc02006c8:	f27d                	bnez	a2,ffffffffc02006ae <buddy_free_pages+0x5e>
    buddy.longest[index] = node_size;  // 设置节点大小为原始大小
ffffffffc02006ca:	c314                	sw	a3,0(a4)
    while (index) {         // 从当前节点向上直到根节点
ffffffffc02006cc:	cbb1                	beqz	a5,ffffffffc0200720 <buddy_free_pages+0xd0>
        index = PARENT(index);          // 移动到父节点
ffffffffc02006ce:	2785                	addiw	a5,a5,1
ffffffffc02006d0:	0017d81b          	srliw	a6,a5,0x1
ffffffffc02006d4:	387d                	addiw	a6,a6,-1
        unsigned right_longest = buddy.longest[RIGHT_LEAF(index)]; // 右子节点大小
ffffffffc02006d6:	ffe7f713          	andi	a4,a5,-2
        unsigned left_longest = buddy.longest[LEFT_LEAF(index)];   // 左子节点大小
ffffffffc02006da:	0018161b          	slliw	a2,a6,0x1
ffffffffc02006de:	2605                	addiw	a2,a2,1
        unsigned right_longest = buddy.longest[RIGHT_LEAF(index)]; // 右子节点大小
ffffffffc02006e0:	1702                	slli	a4,a4,0x20
        unsigned left_longest = buddy.longest[LEFT_LEAF(index)];   // 左子节点大小
ffffffffc02006e2:	02061793          	slli	a5,a2,0x20
        unsigned right_longest = buddy.longest[RIGHT_LEAF(index)]; // 右子节点大小
ffffffffc02006e6:	9301                	srli	a4,a4,0x20
        unsigned left_longest = buddy.longest[LEFT_LEAF(index)];   // 左子节点大小
ffffffffc02006e8:	01e7d613          	srli	a2,a5,0x1e
        unsigned right_longest = buddy.longest[RIGHT_LEAF(index)]; // 右子节点大小
ffffffffc02006ec:	070a                	slli	a4,a4,0x2
ffffffffc02006ee:	9746                	add	a4,a4,a7
        unsigned left_longest = buddy.longest[LEFT_LEAF(index)];   // 左子节点大小
ffffffffc02006f0:	9646                	add	a2,a2,a7
        unsigned right_longest = buddy.longest[RIGHT_LEAF(index)]; // 右子节点大小
ffffffffc02006f2:	00072303          	lw	t1,0(a4)
        unsigned left_longest = buddy.longest[LEFT_LEAF(index)];   // 左子节点大小
ffffffffc02006f6:	4210                	lw	a2,0(a2)
            buddy.longest[index] = node_size;           // 合并为父节点大小
ffffffffc02006f8:	02081793          	slli	a5,a6,0x20
ffffffffc02006fc:	01e7d713          	srli	a4,a5,0x1e
        node_size *= 2;                 // 节点大小加倍
ffffffffc0200700:	0016969b          	slliw	a3,a3,0x1
        if (left_longest + right_longest == node_size)  // 如果子节点大小之和等于父节点大小
ffffffffc0200704:	00660ebb          	addw	t4,a2,t1
        index = PARENT(index);          // 移动到父节点
ffffffffc0200708:	0008079b          	sext.w	a5,a6
            buddy.longest[index] = node_size;           // 合并为父节点大小
ffffffffc020070c:	9746                	add	a4,a4,a7
        if (left_longest + right_longest == node_size)  // 如果子节点大小之和等于父节点大小
ffffffffc020070e:	02de8b63          	beq	t4,a3,ffffffffc0200744 <buddy_free_pages+0xf4>
            buddy.longest[index] = MAX(left_longest, right_longest);  // 否则取最大值
ffffffffc0200712:	8832                	mv	a6,a2
ffffffffc0200714:	00667363          	bgeu	a2,t1,ffffffffc020071a <buddy_free_pages+0xca>
ffffffffc0200718:	881a                	mv	a6,t1
ffffffffc020071a:	01072023          	sw	a6,0(a4)
    while (index) {         // 从当前节点向上直到根节点
ffffffffc020071e:	fbc5                	bnez	a5,ffffffffc02006ce <buddy_free_pages+0x7e>
    for (; p != base + n; p++) {  // 遍历所有要释放的页面
ffffffffc0200720:	00259793          	slli	a5,a1,0x2
ffffffffc0200724:	97ae                	add	a5,a5,a1
ffffffffc0200726:	078e                	slli	a5,a5,0x3
ffffffffc0200728:	97aa                	add	a5,a5,a0
ffffffffc020072a:	00a78a63          	beq	a5,a0,ffffffffc020073e <buddy_free_pages+0xee>
        p->flags = 0;       // 清空页面标志
ffffffffc020072e:	00053423          	sd	zero,8(a0)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200732:	00052023          	sw	zero,0(a0)
    for (; p != base + n; p++) {  // 遍历所有要释放的页面
ffffffffc0200736:	02850513          	addi	a0,a0,40
ffffffffc020073a:	fea79ae3          	bne	a5,a0,ffffffffc020072e <buddy_free_pages+0xde>
}
ffffffffc020073e:	60a2                	ld	ra,8(sp)
ffffffffc0200740:	0141                	addi	sp,sp,16
ffffffffc0200742:	8082                	ret
            buddy.longest[index] = node_size;           // 合并为父节点大小
ffffffffc0200744:	c314                	sw	a3,0(a4)
ffffffffc0200746:	b759                	j	ffffffffc02006cc <buddy_free_pages+0x7c>
    unsigned node_size = 1;  // 初始节点大小为1
ffffffffc0200748:	4685                	li	a3,1
    buddy.longest[index] = node_size;  // 设置节点大小为原始大小
ffffffffc020074a:	c314                	sw	a3,0(a4)
ffffffffc020074c:	b741                	j	ffffffffc02006cc <buddy_free_pages+0x7c>
    assert(base >= buddy.base && base < buddy.base + buddy.size);  // 检查页面有效性
ffffffffc020074e:	00002697          	auipc	a3,0x2
ffffffffc0200752:	18a68693          	addi	a3,a3,394 # ffffffffc02028d8 <etext+0x2ec>
ffffffffc0200756:	00002617          	auipc	a2,0x2
ffffffffc020075a:	14a60613          	addi	a2,a2,330 # ffffffffc02028a0 <etext+0x2b4>
ffffffffc020075e:	0a200593          	li	a1,162
ffffffffc0200762:	00002517          	auipc	a0,0x2
ffffffffc0200766:	15650513          	addi	a0,a0,342 # ffffffffc02028b8 <etext+0x2cc>
ffffffffc020076a:	a59ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(n > 0);          // 确保释放页面数大于0
ffffffffc020076e:	00002697          	auipc	a3,0x2
ffffffffc0200772:	12a68693          	addi	a3,a3,298 # ffffffffc0202898 <etext+0x2ac>
ffffffffc0200776:	00002617          	auipc	a2,0x2
ffffffffc020077a:	12a60613          	addi	a2,a2,298 # ffffffffc02028a0 <etext+0x2b4>
ffffffffc020077e:	0a100593          	li	a1,161
ffffffffc0200782:	00002517          	auipc	a0,0x2
ffffffffc0200786:	13650513          	addi	a0,a0,310 # ffffffffc02028b8 <etext+0x2cc>
ffffffffc020078a:	a39ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc020078e <buddy_alloc_pages>:
    assert(n > 0);          // 确保请求页面数大于0
ffffffffc020078e:	c56d                	beqz	a0,ffffffffc0200878 <buddy_alloc_pages+0xea>
    if (buddy.longest == NULL || n > buddy.size) {  // 检查参数有效性
ffffffffc0200790:	00008817          	auipc	a6,0x8
ffffffffc0200794:	88880813          	addi	a6,a6,-1912 # ffffffffc0208018 <buddy>
ffffffffc0200798:	86aa                	mv	a3,a0
ffffffffc020079a:	00883503          	ld	a0,8(a6)
ffffffffc020079e:	c961                	beqz	a0,ffffffffc020086e <buddy_alloc_pages+0xe0>
ffffffffc02007a0:	00082883          	lw	a7,0(a6)
ffffffffc02007a4:	02089793          	slli	a5,a7,0x20
ffffffffc02007a8:	9381                	srli	a5,a5,0x20
ffffffffc02007aa:	0cd7e163          	bltu	a5,a3,ffffffffc020086c <buddy_alloc_pages+0xde>
    while (size < n) size <<= 1;  // 循环左移直到找到不小于n的2的幂
ffffffffc02007ae:	4785                	li	a5,1
    unsigned size = 1;      // 初始大小为1
ffffffffc02007b0:	4705                	li	a4,1
    while (size < n) size <<= 1;  // 循环左移直到找到不小于n的2的幂
ffffffffc02007b2:	00f68963          	beq	a3,a5,ffffffffc02007c4 <buddy_alloc_pages+0x36>
ffffffffc02007b6:	0017171b          	slliw	a4,a4,0x1
ffffffffc02007ba:	02071793          	slli	a5,a4,0x20
ffffffffc02007be:	9381                	srli	a5,a5,0x20
ffffffffc02007c0:	fed7ebe3          	bltu	a5,a3,ffffffffc02007b6 <buddy_alloc_pages+0x28>
    if (buddy.longest[index] < size)  // 如果根节点可用大小不足
ffffffffc02007c4:	411c                	lw	a5,0(a0)
ffffffffc02007c6:	0ae7e363          	bltu	a5,a4,ffffffffc020086c <buddy_alloc_pages+0xde>
    for (node_size = buddy.size; node_size != size; node_size /= 2) {  // 从最大节点大小开始
ffffffffc02007ca:	0ae88363          	beq	a7,a4,ffffffffc0200870 <buddy_alloc_pages+0xe2>
ffffffffc02007ce:	8646                	mv	a2,a7
    unsigned index = 0;     // 从根节点开始（索引0）
ffffffffc02007d0:	4781                	li	a5,0
        if (buddy.longest[LEFT_LEAF(index)] >= size)  // 如果左子节点足够大
ffffffffc02007d2:	0017959b          	slliw	a1,a5,0x1
ffffffffc02007d6:	0015879b          	addiw	a5,a1,1
ffffffffc02007da:	02079313          	slli	t1,a5,0x20
ffffffffc02007de:	01e35693          	srli	a3,t1,0x1e
ffffffffc02007e2:	96aa                	add	a3,a3,a0
ffffffffc02007e4:	4294                	lw	a3,0(a3)
ffffffffc02007e6:	00e6f463          	bgeu	a3,a4,ffffffffc02007ee <buddy_alloc_pages+0x60>
            index = RIGHT_LEAF(index);                // 否则选择右子节点
ffffffffc02007ea:	0025879b          	addiw	a5,a1,2
    for (node_size = buddy.size; node_size != size; node_size /= 2) {  // 从最大节点大小开始
ffffffffc02007ee:	0016561b          	srliw	a2,a2,0x1
ffffffffc02007f2:	fee610e3          	bne	a2,a4,ffffffffc02007d2 <buddy_alloc_pages+0x44>
    unsigned offset = (index + 1) * node_size - buddy.size;  // 计算页面在数组中的偏移
ffffffffc02007f6:	0017871b          	addiw	a4,a5,1
ffffffffc02007fa:	02c7063b          	mulw	a2,a4,a2
    buddy.longest[index] = 0;  // 设置节点大小为0表示已分配
ffffffffc02007fe:	02079593          	slli	a1,a5,0x20
ffffffffc0200802:	01e5d693          	srli	a3,a1,0x1e
ffffffffc0200806:	96aa                	add	a3,a3,a0
ffffffffc0200808:	0006a023          	sw	zero,0(a3)
    unsigned offset = (index + 1) * node_size - buddy.size;  // 计算页面在数组中的偏移
ffffffffc020080c:	4116063b          	subw	a2,a2,a7
    return buddy.base + offset;  // 返回页面指针
ffffffffc0200810:	1602                	slli	a2,a2,0x20
ffffffffc0200812:	9201                	srli	a2,a2,0x20
ffffffffc0200814:	00261693          	slli	a3,a2,0x2
ffffffffc0200818:	9636                	add	a2,a2,a3
ffffffffc020081a:	060e                	slli	a2,a2,0x3
    while (index) {         // 从当前节点向上直到根节点
ffffffffc020081c:	e781                	bnez	a5,ffffffffc0200824 <buddy_alloc_pages+0x96>
ffffffffc020081e:	a099                	j	ffffffffc0200864 <buddy_alloc_pages+0xd6>
ffffffffc0200820:	0017871b          	addiw	a4,a5,1
        index = PARENT(index);                          // 移动到父节点
ffffffffc0200824:	0017579b          	srliw	a5,a4,0x1
ffffffffc0200828:	37fd                	addiw	a5,a5,-1
        buddy.longest[index] = MAX(buddy.longest[LEFT_LEAF(index)],  // 左子节点大小
ffffffffc020082a:	0017969b          	slliw	a3,a5,0x1
ffffffffc020082e:	9b79                	andi	a4,a4,-2
ffffffffc0200830:	2685                	addiw	a3,a3,1
ffffffffc0200832:	1702                	slli	a4,a4,0x20
ffffffffc0200834:	02069593          	slli	a1,a3,0x20
ffffffffc0200838:	9301                	srli	a4,a4,0x20
ffffffffc020083a:	01e5d693          	srli	a3,a1,0x1e
ffffffffc020083e:	070a                	slli	a4,a4,0x2
ffffffffc0200840:	972a                	add	a4,a4,a0
ffffffffc0200842:	96aa                	add	a3,a3,a0
ffffffffc0200844:	430c                	lw	a1,0(a4)
ffffffffc0200846:	4294                	lw	a3,0(a3)
ffffffffc0200848:	02079893          	slli	a7,a5,0x20
ffffffffc020084c:	01e8d713          	srli	a4,a7,0x1e
ffffffffc0200850:	0006831b          	sext.w	t1,a3
ffffffffc0200854:	0005889b          	sext.w	a7,a1
ffffffffc0200858:	972a                	add	a4,a4,a0
ffffffffc020085a:	01137363          	bgeu	t1,a7,ffffffffc0200860 <buddy_alloc_pages+0xd2>
ffffffffc020085e:	86ae                	mv	a3,a1
ffffffffc0200860:	c314                	sw	a3,0(a4)
    while (index) {         // 从当前节点向上直到根节点
ffffffffc0200862:	ffdd                	bnez	a5,ffffffffc0200820 <buddy_alloc_pages+0x92>
    return buddy.base + offset;  // 返回页面指针
ffffffffc0200864:	01083503          	ld	a0,16(a6)
ffffffffc0200868:	9532                	add	a0,a0,a2
ffffffffc020086a:	8082                	ret
        return NULL;        // 如果未初始化或请求过大，返回NULL
ffffffffc020086c:	4501                	li	a0,0
}
ffffffffc020086e:	8082                	ret
    buddy.longest[index] = 0;  // 设置节点大小为0表示已分配
ffffffffc0200870:	00052023          	sw	zero,0(a0)
ffffffffc0200874:	4601                	li	a2,0
ffffffffc0200876:	b7fd                	j	ffffffffc0200864 <buddy_alloc_pages+0xd6>
buddy_alloc_pages(size_t n) {
ffffffffc0200878:	1141                	addi	sp,sp,-16
    assert(n > 0);          // 确保请求页面数大于0
ffffffffc020087a:	00002697          	auipc	a3,0x2
ffffffffc020087e:	01e68693          	addi	a3,a3,30 # ffffffffc0202898 <etext+0x2ac>
ffffffffc0200882:	00002617          	auipc	a2,0x2
ffffffffc0200886:	01e60613          	addi	a2,a2,30 # ffffffffc02028a0 <etext+0x2b4>
ffffffffc020088a:	07500593          	li	a1,117
ffffffffc020088e:	00002517          	auipc	a0,0x2
ffffffffc0200892:	02a50513          	addi	a0,a0,42 # ffffffffc02028b8 <etext+0x2cc>
buddy_alloc_pages(size_t n) {
ffffffffc0200896:	e406                	sd	ra,8(sp)
    assert(n > 0);          // 确保请求页面数大于0
ffffffffc0200898:	92bff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc020089c <buddy_check>:
            n * PGSIZE / 1024);  // 大小（KB）
}

static void
buddy_check(void) {
ffffffffc020089c:	7149                	addi	sp,sp,-368
    assert((p0 = alloc_page()) != NULL);  // 分配第1个页面
ffffffffc020089e:	4505                	li	a0,1
buddy_check(void) {
ffffffffc02008a0:	f686                	sd	ra,360(sp)
ffffffffc02008a2:	f2a2                	sd	s0,352(sp)
ffffffffc02008a4:	eea6                	sd	s1,344(sp)
ffffffffc02008a6:	eaca                	sd	s2,336(sp)
ffffffffc02008a8:	e6ce                	sd	s3,328(sp)
ffffffffc02008aa:	e2d2                	sd	s4,320(sp)
ffffffffc02008ac:	fe56                	sd	s5,312(sp)
ffffffffc02008ae:	fa5a                	sd	s6,304(sp)
ffffffffc02008b0:	f65e                	sd	s7,296(sp)
ffffffffc02008b2:	f262                	sd	s8,288(sp)
ffffffffc02008b4:	ee66                	sd	s9,280(sp)
ffffffffc02008b6:	ea6a                	sd	s10,272(sp)
ffffffffc02008b8:	e66e                	sd	s11,264(sp)
    assert((p0 = alloc_page()) != NULL);  // 分配第1个页面
ffffffffc02008ba:	351000ef          	jal	ra,ffffffffc020140a <alloc_pages>
ffffffffc02008be:	12050ce3          	beqz	a0,ffffffffc02011f6 <buddy_check+0x95a>
ffffffffc02008c2:	892a                	mv	s2,a0
    assert((p1 = alloc_page()) != NULL);  // 分配第2个页面
ffffffffc02008c4:	4505                	li	a0,1
ffffffffc02008c6:	345000ef          	jal	ra,ffffffffc020140a <alloc_pages>
ffffffffc02008ca:	84aa                	mv	s1,a0
ffffffffc02008cc:	100505e3          	beqz	a0,ffffffffc02011d6 <buddy_check+0x93a>
    assert((p2 = alloc_page()) != NULL);  // 分配第3个页面
ffffffffc02008d0:	4505                	li	a0,1
ffffffffc02008d2:	339000ef          	jal	ra,ffffffffc020140a <alloc_pages>
ffffffffc02008d6:	842a                	mv	s0,a0
ffffffffc02008d8:	0c050fe3          	beqz	a0,ffffffffc02011b6 <buddy_check+0x91a>
    assert(p0 != p1 && p0 != p2 && p1 != p2);  // 确保页面地址不同
ffffffffc02008dc:	78990d63          	beq	s2,s1,ffffffffc0201076 <buddy_check+0x7da>
ffffffffc02008e0:	78a90b63          	beq	s2,a0,ffffffffc0201076 <buddy_check+0x7da>
ffffffffc02008e4:	78a48963          	beq	s1,a0,ffffffffc0201076 <buddy_check+0x7da>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);  // 引用计数为0
ffffffffc02008e8:	00092783          	lw	a5,0(s2)
ffffffffc02008ec:	76079563          	bnez	a5,ffffffffc0201056 <buddy_check+0x7ba>
ffffffffc02008f0:	409c                	lw	a5,0(s1)
ffffffffc02008f2:	76079263          	bnez	a5,ffffffffc0201056 <buddy_check+0x7ba>
static inline int page_ref(struct Page *page) { return page->ref; }
ffffffffc02008f6:	00052983          	lw	s3,0(a0)
ffffffffc02008fa:	74099e63          	bnez	s3,ffffffffc0201056 <buddy_check+0x7ba>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02008fe:	0000c797          	auipc	a5,0xc
ffffffffc0200902:	9127b783          	ld	a5,-1774(a5) # ffffffffc020c210 <pages>
ffffffffc0200906:	40f90733          	sub	a4,s2,a5
ffffffffc020090a:	870d                	srai	a4,a4,0x3
ffffffffc020090c:	00003597          	auipc	a1,0x3
ffffffffc0200910:	7d45b583          	ld	a1,2004(a1) # ffffffffc02040e0 <error_string+0x38>
ffffffffc0200914:	02b70733          	mul	a4,a4,a1
ffffffffc0200918:	00003617          	auipc	a2,0x3
ffffffffc020091c:	7d063603          	ld	a2,2000(a2) # ffffffffc02040e8 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);  // 页面地址在有效范围内
ffffffffc0200920:	0000c697          	auipc	a3,0xc
ffffffffc0200924:	8e86b683          	ld	a3,-1816(a3) # ffffffffc020c208 <npage>
ffffffffc0200928:	06b2                	slli	a3,a3,0xc
ffffffffc020092a:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc020092c:	0732                	slli	a4,a4,0xc
ffffffffc020092e:	06d774e3          	bgeu	a4,a3,ffffffffc0201196 <buddy_check+0x8fa>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200932:	40f48733          	sub	a4,s1,a5
ffffffffc0200936:	870d                	srai	a4,a4,0x3
ffffffffc0200938:	02b70733          	mul	a4,a4,a1
ffffffffc020093c:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc020093e:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);  // 页面地址在有效范围内
ffffffffc0200940:	02d77be3          	bgeu	a4,a3,ffffffffc0201176 <buddy_check+0x8da>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200944:	40f507b3          	sub	a5,a0,a5
ffffffffc0200948:	878d                	srai	a5,a5,0x3
ffffffffc020094a:	02b787b3          	mul	a5,a5,a1
ffffffffc020094e:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200950:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);  // 页面地址在有效范围内
ffffffffc0200952:	00d7f2e3          	bgeu	a5,a3,ffffffffc0201156 <buddy_check+0x8ba>
    free_page(p0);          // 释放第1个页面
ffffffffc0200956:	4585                	li	a1,1
ffffffffc0200958:	854a                	mv	a0,s2
ffffffffc020095a:	2bd000ef          	jal	ra,ffffffffc0201416 <free_pages>
    free_page(p1);          // 释放第2个页面
ffffffffc020095e:	4585                	li	a1,1
ffffffffc0200960:	8526                	mv	a0,s1
ffffffffc0200962:	2b5000ef          	jal	ra,ffffffffc0201416 <free_pages>
    free_page(p2);          // 释放第3个页面
ffffffffc0200966:	4585                	li	a1,1
ffffffffc0200968:	8522                	mv	a0,s0
ffffffffc020096a:	2ad000ef          	jal	ra,ffffffffc0201416 <free_pages>
// - 测试8：功能正确性验证 - 验证分配的页面地址是否在合理范围内，分配的页面地址是否唯一，确保没有地址冲突。
// - 测试9：最终内存泄漏检查 - 比较测试前后的可用页面数，确保没有内存泄漏发生。
    // 先进行基础测试
    basic_check();          // 运行基础测试
    
    cprintf("\n--- 开始buddy system专项测试 ---\n");  // 输出测试开始信息
ffffffffc020096e:	00002517          	auipc	a0,0x2
ffffffffc0200972:	0ca50513          	addi	a0,a0,202 # ffffffffc0202a38 <etext+0x44c>
    if (buddy.longest == NULL)  // 如果未初始化
ffffffffc0200976:	00007a17          	auipc	s4,0x7
ffffffffc020097a:	6a2a0a13          	addi	s4,s4,1698 # ffffffffc0208018 <buddy>
    cprintf("\n--- 开始buddy system专项测试 ---\n");  // 输出测试开始信息
ffffffffc020097e:	fceff0ef          	jal	ra,ffffffffc020014c <cprintf>
    if (buddy.longest == NULL)  // 如果未初始化
ffffffffc0200982:	008a3783          	ld	a5,8(s4)
ffffffffc0200986:	68078f63          	beqz	a5,ffffffffc0201024 <buddy_check+0x788>
    return buddy.longest[0];    // 返回根节点的可用大小
ffffffffc020098a:	0007ea83          	lwu	s5,0(a5)
    
    // 记录初始状态
    size_t initial_free = buddy_nr_free_pages();  // 获取初始可用页面数
    cprintf("初始可用页面数: %d\n", initial_free);  // 输出初始状态
ffffffffc020098e:	85d6                	mv	a1,s5
ffffffffc0200990:	00002517          	auipc	a0,0x2
ffffffffc0200994:	0d850513          	addi	a0,a0,216 # ffffffffc0202a68 <etext+0x47c>
ffffffffc0200998:	fb4ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    // 测试1: 基本的2的幂次分配和释放
    cprintf("\n--- 测试1: 基本的2的幂次分配和释放 ---\n");
ffffffffc020099c:	00002517          	auipc	a0,0x2
ffffffffc02009a0:	0ec50513          	addi	a0,a0,236 # ffffffffc0202a88 <etext+0x49c>
ffffffffc02009a4:	fa8ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    struct Page *p1, *p2, *p4, *p8;  // 测试页面指针
    
    p1 = alloc_pages(1);   // 分配1页
ffffffffc02009a8:	4505                	li	a0,1
ffffffffc02009aa:	261000ef          	jal	ra,ffffffffc020140a <alloc_pages>
ffffffffc02009ae:	842a                	mv	s0,a0
    assert(p1 != NULL);    // 确保分配成功
ffffffffc02009b0:	060503e3          	beqz	a0,ffffffffc0201216 <buddy_check+0x97a>
    cprintf("✓ 分配1页成功\n");  // 输出成功信息
ffffffffc02009b4:	00002517          	auipc	a0,0x2
ffffffffc02009b8:	11c50513          	addi	a0,a0,284 # ffffffffc0202ad0 <etext+0x4e4>
ffffffffc02009bc:	f90ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    show_page_info(p1, 1, "1页块");  // 显示1页块详细信息
ffffffffc02009c0:	00002617          	auipc	a2,0x2
ffffffffc02009c4:	12860613          	addi	a2,a2,296 # ffffffffc0202ae8 <etext+0x4fc>
ffffffffc02009c8:	4585                	li	a1,1
ffffffffc02009ca:	8522                	mv	a0,s0
ffffffffc02009cc:	c2fff0ef          	jal	ra,ffffffffc02005fa <show_page_info>
    
    p2 = alloc_pages(2);   // 分配2页
ffffffffc02009d0:	4509                	li	a0,2
ffffffffc02009d2:	239000ef          	jal	ra,ffffffffc020140a <alloc_pages>
ffffffffc02009d6:	84aa                	mv	s1,a0
    assert(p2 != NULL);    // 确保分配成功
ffffffffc02009d8:	74050f63          	beqz	a0,ffffffffc0201136 <buddy_check+0x89a>
    cprintf("✓ 分配2页成功\n");  // 输出成功信息
ffffffffc02009dc:	00002517          	auipc	a0,0x2
ffffffffc02009e0:	12450513          	addi	a0,a0,292 # ffffffffc0202b00 <etext+0x514>
ffffffffc02009e4:	f68ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    show_page_info(p2, 2, "2页块");  // 显示2页块详细信息
ffffffffc02009e8:	00002617          	auipc	a2,0x2
ffffffffc02009ec:	13060613          	addi	a2,a2,304 # ffffffffc0202b18 <etext+0x52c>
ffffffffc02009f0:	4589                	li	a1,2
ffffffffc02009f2:	8526                	mv	a0,s1
ffffffffc02009f4:	c07ff0ef          	jal	ra,ffffffffc02005fa <show_page_info>
    
    p4 = alloc_pages(4);   // 分配4页
ffffffffc02009f8:	4511                	li	a0,4
ffffffffc02009fa:	211000ef          	jal	ra,ffffffffc020140a <alloc_pages>
ffffffffc02009fe:	8b2a                	mv	s6,a0
    assert(p4 != NULL);    // 确保分配成功
ffffffffc0200a00:	70050b63          	beqz	a0,ffffffffc0201116 <buddy_check+0x87a>
    cprintf("✓ 分配4页成功\n");  // 输出成功信息
ffffffffc0200a04:	00002517          	auipc	a0,0x2
ffffffffc0200a08:	12c50513          	addi	a0,a0,300 # ffffffffc0202b30 <etext+0x544>
ffffffffc0200a0c:	f40ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    show_page_info(p4, 4, "4页块");  // 显示4页块详细信息
ffffffffc0200a10:	00002617          	auipc	a2,0x2
ffffffffc0200a14:	13860613          	addi	a2,a2,312 # ffffffffc0202b48 <etext+0x55c>
ffffffffc0200a18:	4591                	li	a1,4
ffffffffc0200a1a:	855a                	mv	a0,s6
ffffffffc0200a1c:	bdfff0ef          	jal	ra,ffffffffc02005fa <show_page_info>
    
    p8 = alloc_pages(8);   // 分配8页
ffffffffc0200a20:	4521                	li	a0,8
ffffffffc0200a22:	1e9000ef          	jal	ra,ffffffffc020140a <alloc_pages>
ffffffffc0200a26:	892a                	mv	s2,a0
    assert(p8 != NULL);    // 确保分配成功
ffffffffc0200a28:	000507e3          	beqz	a0,ffffffffc0201236 <buddy_check+0x99a>
    cprintf("✓ 分配8页成功\n");  // 输出成功信息
ffffffffc0200a2c:	00002517          	auipc	a0,0x2
ffffffffc0200a30:	13450513          	addi	a0,a0,308 # ffffffffc0202b60 <etext+0x574>
ffffffffc0200a34:	f18ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    show_page_info(p8, 8, "8页块");  // 显示8页块详细信息
ffffffffc0200a38:	00002617          	auipc	a2,0x2
ffffffffc0200a3c:	14060613          	addi	a2,a2,320 # ffffffffc0202b78 <etext+0x58c>
ffffffffc0200a40:	45a1                	li	a1,8
ffffffffc0200a42:	854a                	mv	a0,s2
ffffffffc0200a44:	bb7ff0ef          	jal	ra,ffffffffc02005fa <show_page_info>
    if (buddy.longest == NULL)  // 如果未初始化
ffffffffc0200a48:	008a3783          	ld	a5,8(s4)
ffffffffc0200a4c:	5c078f63          	beqz	a5,ffffffffc020102a <buddy_check+0x78e>
    return buddy.longest[0];    // 返回根节点的可用大小
ffffffffc0200a50:	0007e583          	lwu	a1,0(a5)

    // 检查分配后的可用内存
    size_t after_alloc = buddy_nr_free_pages();  // 获取分配后可用页面数
    cprintf("分配后可用页面数: %d\n", after_alloc);  // 输出分配后状态
ffffffffc0200a54:	00002517          	auipc	a0,0x2
ffffffffc0200a58:	12c50513          	addi	a0,a0,300 # ffffffffc0202b80 <etext+0x594>
ffffffffc0200a5c:	ef0ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    // 释放内存
    free_pages(p1, 1);     // 释放1页
ffffffffc0200a60:	4585                	li	a1,1
ffffffffc0200a62:	8522                	mv	a0,s0
ffffffffc0200a64:	1b3000ef          	jal	ra,ffffffffc0201416 <free_pages>
    cprintf("✓ 释放1页成功\n");  // 输出成功信息
ffffffffc0200a68:	00002517          	auipc	a0,0x2
ffffffffc0200a6c:	13850513          	addi	a0,a0,312 # ffffffffc0202ba0 <etext+0x5b4>
ffffffffc0200a70:	edcff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    free_pages(p2, 2);     // 释放2页
ffffffffc0200a74:	4589                	li	a1,2
ffffffffc0200a76:	8526                	mv	a0,s1
ffffffffc0200a78:	19f000ef          	jal	ra,ffffffffc0201416 <free_pages>
    cprintf("✓ 释放2页成功\n");  // 输出成功信息
ffffffffc0200a7c:	00002517          	auipc	a0,0x2
ffffffffc0200a80:	13c50513          	addi	a0,a0,316 # ffffffffc0202bb8 <etext+0x5cc>
ffffffffc0200a84:	ec8ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    free_pages(p4, 4);     // 释放4页
ffffffffc0200a88:	4591                	li	a1,4
ffffffffc0200a8a:	855a                	mv	a0,s6
ffffffffc0200a8c:	18b000ef          	jal	ra,ffffffffc0201416 <free_pages>
    cprintf("✓ 释放4页成功\n");  // 输出成功信息
ffffffffc0200a90:	00002517          	auipc	a0,0x2
ffffffffc0200a94:	14050513          	addi	a0,a0,320 # ffffffffc0202bd0 <etext+0x5e4>
ffffffffc0200a98:	eb4ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    free_pages(p8, 8);     // 释放8页
ffffffffc0200a9c:	45a1                	li	a1,8
ffffffffc0200a9e:	854a                	mv	a0,s2
ffffffffc0200aa0:	177000ef          	jal	ra,ffffffffc0201416 <free_pages>
    cprintf("✓ 释放8页成功\n");  // 输出成功信息
ffffffffc0200aa4:	00002517          	auipc	a0,0x2
ffffffffc0200aa8:	14450513          	addi	a0,a0,324 # ffffffffc0202be8 <etext+0x5fc>
ffffffffc0200aac:	ea0ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    // 测试2: 非2的幂次分配（向上取整）
    cprintf("\n--- 测试2: 非2的幂次分配（向上取整） ---\n");
ffffffffc0200ab0:	00002517          	auipc	a0,0x2
ffffffffc0200ab4:	15050513          	addi	a0,a0,336 # ffffffffc0202c00 <etext+0x614>
ffffffffc0200ab8:	e94ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    struct Page *p3, *p5, *p6, *p7;  // 测试页面指针
    
    p3 = alloc_pages(3);   // 请求3页，应该分配4页
ffffffffc0200abc:	450d                	li	a0,3
ffffffffc0200abe:	14d000ef          	jal	ra,ffffffffc020140a <alloc_pages>
ffffffffc0200ac2:	8b2a                	mv	s6,a0
    assert(p3 != NULL);     // 确保分配成功
ffffffffc0200ac4:	62050963          	beqz	a0,ffffffffc02010f6 <buddy_check+0x85a>
    cprintf("✓ 请求3页分配成功（实际分配4页）\n");  // 输出成功信息
ffffffffc0200ac8:	00002517          	auipc	a0,0x2
ffffffffc0200acc:	18850513          	addi	a0,a0,392 # ffffffffc0202c50 <etext+0x664>
ffffffffc0200ad0:	e7cff0ef          	jal	ra,ffffffffc020014c <cprintf>
    show_page_info(p3, 4, "请求3页实际分配4页");  // 显示实际分配的4页详细信息
ffffffffc0200ad4:	00002617          	auipc	a2,0x2
ffffffffc0200ad8:	1b460613          	addi	a2,a2,436 # ffffffffc0202c88 <etext+0x69c>
ffffffffc0200adc:	4591                	li	a1,4
ffffffffc0200ade:	855a                	mv	a0,s6
ffffffffc0200ae0:	b1bff0ef          	jal	ra,ffffffffc02005fa <show_page_info>
    
    p5 = alloc_pages(5);   // 请求5页，应该分配8页
ffffffffc0200ae4:	4515                	li	a0,5
ffffffffc0200ae6:	125000ef          	jal	ra,ffffffffc020140a <alloc_pages>
ffffffffc0200aea:	892a                	mv	s2,a0
    assert(p5 != NULL);     // 确保分配成功
ffffffffc0200aec:	5e050563          	beqz	a0,ffffffffc02010d6 <buddy_check+0x83a>
    cprintf("✓ 请求5页分配成功（实际分配8页）\n");  // 输出成功信息
ffffffffc0200af0:	00002517          	auipc	a0,0x2
ffffffffc0200af4:	1c850513          	addi	a0,a0,456 # ffffffffc0202cb8 <etext+0x6cc>
ffffffffc0200af8:	e54ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    show_page_info(p5, 8, "请求5页实际分配8页");  // 显示实际分配的8页详细信息
ffffffffc0200afc:	00002617          	auipc	a2,0x2
ffffffffc0200b00:	1f460613          	addi	a2,a2,500 # ffffffffc0202cf0 <etext+0x704>
ffffffffc0200b04:	45a1                	li	a1,8
ffffffffc0200b06:	854a                	mv	a0,s2
ffffffffc0200b08:	af3ff0ef          	jal	ra,ffffffffc02005fa <show_page_info>
    
    p6 = alloc_pages(6);   // 请求6页，应该分配8页
ffffffffc0200b0c:	4519                	li	a0,6
ffffffffc0200b0e:	0fd000ef          	jal	ra,ffffffffc020140a <alloc_pages>
ffffffffc0200b12:	84aa                	mv	s1,a0
    assert(p6 != NULL);     // 确保分配成功
ffffffffc0200b14:	5a050163          	beqz	a0,ffffffffc02010b6 <buddy_check+0x81a>
    cprintf("✓ 请求6页分配成功（实际分配8页）\n");  // 输出成功信息
ffffffffc0200b18:	00002517          	auipc	a0,0x2
ffffffffc0200b1c:	20850513          	addi	a0,a0,520 # ffffffffc0202d20 <etext+0x734>
ffffffffc0200b20:	e2cff0ef          	jal	ra,ffffffffc020014c <cprintf>
    show_page_info(p6, 8, "请求6页实际分配8页");  // 显示实际分配的8页详细信息
ffffffffc0200b24:	00002617          	auipc	a2,0x2
ffffffffc0200b28:	23460613          	addi	a2,a2,564 # ffffffffc0202d58 <etext+0x76c>
ffffffffc0200b2c:	45a1                	li	a1,8
ffffffffc0200b2e:	8526                	mv	a0,s1
ffffffffc0200b30:	acbff0ef          	jal	ra,ffffffffc02005fa <show_page_info>
    
    p7 = alloc_pages(7);   // 请求7页，应该分配8页
ffffffffc0200b34:	451d                	li	a0,7
ffffffffc0200b36:	0d5000ef          	jal	ra,ffffffffc020140a <alloc_pages>
ffffffffc0200b3a:	842a                	mv	s0,a0
    assert(p7 != NULL);     // 确保分配成功
ffffffffc0200b3c:	54050d63          	beqz	a0,ffffffffc0201096 <buddy_check+0x7fa>
    cprintf("✓ 请求7页分配成功（实际分配8页）\n");  // 输出成功信息
ffffffffc0200b40:	00002517          	auipc	a0,0x2
ffffffffc0200b44:	24850513          	addi	a0,a0,584 # ffffffffc0202d88 <etext+0x79c>
ffffffffc0200b48:	e04ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    show_page_info(p7, 8, "请求7页实际分配8页");  // 显示实际分配的8页详细信息
ffffffffc0200b4c:	00002617          	auipc	a2,0x2
ffffffffc0200b50:	27460613          	addi	a2,a2,628 # ffffffffc0202dc0 <etext+0x7d4>
ffffffffc0200b54:	45a1                	li	a1,8
ffffffffc0200b56:	8522                	mv	a0,s0
ffffffffc0200b58:	aa3ff0ef          	jal	ra,ffffffffc02005fa <show_page_info>
    
    // 释放非2的幂次分配的内存
    free_pages(p3, 3);     // 释放3页
ffffffffc0200b5c:	458d                	li	a1,3
ffffffffc0200b5e:	855a                	mv	a0,s6
ffffffffc0200b60:	0b7000ef          	jal	ra,ffffffffc0201416 <free_pages>
    cprintf("✓ 释放3页成功\n");  // 输出成功信息
ffffffffc0200b64:	00002517          	auipc	a0,0x2
ffffffffc0200b68:	27c50513          	addi	a0,a0,636 # ffffffffc0202de0 <etext+0x7f4>
ffffffffc0200b6c:	de0ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    free_pages(p5, 5);     // 释放5页
ffffffffc0200b70:	4595                	li	a1,5
ffffffffc0200b72:	854a                	mv	a0,s2
ffffffffc0200b74:	0a3000ef          	jal	ra,ffffffffc0201416 <free_pages>
    cprintf("✓ 释放5页成功\n");  // 输出成功信息
ffffffffc0200b78:	00002517          	auipc	a0,0x2
ffffffffc0200b7c:	28050513          	addi	a0,a0,640 # ffffffffc0202df8 <etext+0x80c>
ffffffffc0200b80:	dccff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    free_pages(p6, 6);     // 释放6页
ffffffffc0200b84:	4599                	li	a1,6
ffffffffc0200b86:	8526                	mv	a0,s1
ffffffffc0200b88:	08f000ef          	jal	ra,ffffffffc0201416 <free_pages>
    cprintf("✓ 释放6页成功\n");  // 输出成功信息
ffffffffc0200b8c:	00002517          	auipc	a0,0x2
ffffffffc0200b90:	28450513          	addi	a0,a0,644 # ffffffffc0202e10 <etext+0x824>
ffffffffc0200b94:	db8ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    free_pages(p7, 7);     // 释放7页
ffffffffc0200b98:	459d                	li	a1,7
ffffffffc0200b9a:	8522                	mv	a0,s0
ffffffffc0200b9c:	07b000ef          	jal	ra,ffffffffc0201416 <free_pages>
    cprintf("✓ 释放7页成功\n");  // 输出成功信息
ffffffffc0200ba0:	00002517          	auipc	a0,0x2
ffffffffc0200ba4:	28850513          	addi	a0,a0,648 # ffffffffc0202e28 <etext+0x83c>
ffffffffc0200ba8:	da4ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    // 测试3: 伙伴合并机制
    cprintf("\n--- 测试3: 伙伴合并机制测试 ---\n");
ffffffffc0200bac:	00002517          	auipc	a0,0x2
ffffffffc0200bb0:	29450513          	addi	a0,a0,660 # ffffffffc0202e40 <etext+0x854>
ffffffffc0200bb4:	d98ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    struct Page *buddy_test[4];  // 测试页面数组
    
    // 分配4个连续的1页块
    cprintf("分配4个1页块，观察buddy system的分配策略：\n");
ffffffffc0200bb8:	00002517          	auipc	a0,0x2
ffffffffc0200bbc:	2b850513          	addi	a0,a0,696 # ffffffffc0202e70 <etext+0x884>
ffffffffc0200bc0:	890a                	mv	s2,sp
ffffffffc0200bc2:	d8aff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200bc6:	8b4a                	mv	s6,s2
    for (int i = 0; i < 4; i++) {  // 循环分配4次
ffffffffc0200bc8:	4481                	li	s1,0
        buddy_test[i] = alloc_pages(1);  // 每次分配1页
        if (buddy_test[i] != NULL) {  // 如果分配成功
            cprintf("✓ 分配第%d个1页块成功\n", i+1);  // 输出成功信息
ffffffffc0200bca:	00002c97          	auipc	s9,0x2
ffffffffc0200bce:	2e6c8c93          	addi	s9,s9,742 # ffffffffc0202eb0 <etext+0x8c4>
            show_page_info(buddy_test[i], 1, "1页块");  // 显示每个1页块的详细信息
ffffffffc0200bd2:	00002c17          	auipc	s8,0x2
ffffffffc0200bd6:	f16c0c13          	addi	s8,s8,-234 # ffffffffc0202ae8 <etext+0x4fc>
    for (int i = 0; i < 4; i++) {  // 循环分配4次
ffffffffc0200bda:	4b91                	li	s7,4
        buddy_test[i] = alloc_pages(1);  // 每次分配1页
ffffffffc0200bdc:	4505                	li	a0,1
ffffffffc0200bde:	02d000ef          	jal	ra,ffffffffc020140a <alloc_pages>
ffffffffc0200be2:	00ab3023          	sd	a0,0(s6) # 10000 <kern_entry-0xffffffffc01f0000>
ffffffffc0200be6:	842a                	mv	s0,a0
            cprintf("✓ 分配第%d个1页块成功\n", i+1);  // 输出成功信息
ffffffffc0200be8:	2485                	addiw	s1,s1,1
        if (buddy_test[i] != NULL) {  // 如果分配成功
ffffffffc0200bea:	c911                	beqz	a0,ffffffffc0200bfe <buddy_check+0x362>
            cprintf("✓ 分配第%d个1页块成功\n", i+1);  // 输出成功信息
ffffffffc0200bec:	85a6                	mv	a1,s1
ffffffffc0200bee:	8566                	mv	a0,s9
ffffffffc0200bf0:	d5cff0ef          	jal	ra,ffffffffc020014c <cprintf>
            show_page_info(buddy_test[i], 1, "1页块");  // 显示每个1页块的详细信息
ffffffffc0200bf4:	8662                	mv	a2,s8
ffffffffc0200bf6:	4585                	li	a1,1
ffffffffc0200bf8:	8522                	mv	a0,s0
ffffffffc0200bfa:	a01ff0ef          	jal	ra,ffffffffc02005fa <show_page_info>
    for (int i = 0; i < 4; i++) {  // 循环分配4次
ffffffffc0200bfe:	0b21                	addi	s6,s6,8
ffffffffc0200c00:	fd749ee3          	bne	s1,s7,ffffffffc0200bdc <buddy_check+0x340>
    if (buddy.longest == NULL)  // 如果未初始化
ffffffffc0200c04:	008a3783          	ld	a5,8(s4)
ffffffffc0200c08:	42078363          	beqz	a5,ffffffffc020102e <buddy_check+0x792>
    return buddy.longest[0];    // 返回根节点的可用大小
ffffffffc0200c0c:	0007e583          	lwu	a1,0(a5)
        }
    }
    
    size_t before_merge = buddy_nr_free_pages();  // 获取合并前可用页面数
    cprintf("合并前可用页面数: %d\n", before_merge);  // 输出合并前状态
ffffffffc0200c10:	00002517          	auipc	a0,0x2
ffffffffc0200c14:	2c850513          	addi	a0,a0,712 # ffffffffc0202ed8 <etext+0x8ec>
ffffffffc0200c18:	d34ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    // 释放这些块，测试合并效果
    cprintf("释放这些1页块，观察buddy system的合并过程：\n");
ffffffffc0200c1c:	00002517          	auipc	a0,0x2
ffffffffc0200c20:	2dc50513          	addi	a0,a0,732 # ffffffffc0202ef8 <etext+0x90c>
ffffffffc0200c24:	d28ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    for (int i = 0; i < 4; i++) {  // 循环释放4次
ffffffffc0200c28:	4401                	li	s0,0
        if (buddy_test[i] != NULL) {  // 如果页面有效
            free_pages(buddy_test[i], 1);  // 释放1页
            cprintf("✓ 释放第%d个1页块\n", i+1);  // 输出成功信息
ffffffffc0200c2a:	00002b97          	auipc	s7,0x2
ffffffffc0200c2e:	30eb8b93          	addi	s7,s7,782 # ffffffffc0202f38 <etext+0x94c>
            cprintf("  当前可用页面数: %d\n", buddy_nr_free_pages());  // 显示释放后的可用页面数
ffffffffc0200c32:	00002b17          	auipc	s6,0x2
ffffffffc0200c36:	326b0b13          	addi	s6,s6,806 # ffffffffc0202f58 <etext+0x96c>
    for (int i = 0; i < 4; i++) {  // 循环释放4次
ffffffffc0200c3a:	4491                	li	s1,4
        if (buddy_test[i] != NULL) {  // 如果页面有效
ffffffffc0200c3c:	00093503          	ld	a0,0(s2)
            cprintf("✓ 释放第%d个1页块\n", i+1);  // 输出成功信息
ffffffffc0200c40:	2405                	addiw	s0,s0,1
        if (buddy_test[i] != NULL) {  // 如果页面有效
ffffffffc0200c42:	c10d                	beqz	a0,ffffffffc0200c64 <buddy_check+0x3c8>
            free_pages(buddy_test[i], 1);  // 释放1页
ffffffffc0200c44:	4585                	li	a1,1
ffffffffc0200c46:	7d0000ef          	jal	ra,ffffffffc0201416 <free_pages>
            cprintf("✓ 释放第%d个1页块\n", i+1);  // 输出成功信息
ffffffffc0200c4a:	85a2                	mv	a1,s0
ffffffffc0200c4c:	855e                	mv	a0,s7
ffffffffc0200c4e:	cfeff0ef          	jal	ra,ffffffffc020014c <cprintf>
    if (buddy.longest == NULL)  // 如果未初始化
ffffffffc0200c52:	008a3783          	ld	a5,8(s4)
ffffffffc0200c56:	38078963          	beqz	a5,ffffffffc0200fe8 <buddy_check+0x74c>
    return buddy.longest[0];    // 返回根节点的可用大小
ffffffffc0200c5a:	0007e583          	lwu	a1,0(a5)
            cprintf("  当前可用页面数: %d\n", buddy_nr_free_pages());  // 显示释放后的可用页面数
ffffffffc0200c5e:	855a                	mv	a0,s6
ffffffffc0200c60:	cecff0ef          	jal	ra,ffffffffc020014c <cprintf>
    for (int i = 0; i < 4; i++) {  // 循环释放4次
ffffffffc0200c64:	0921                	addi	s2,s2,8
ffffffffc0200c66:	fc941be3          	bne	s0,s1,ffffffffc0200c3c <buddy_check+0x3a0>
    if (buddy.longest == NULL)  // 如果未初始化
ffffffffc0200c6a:	008a3783          	ld	a5,8(s4)
ffffffffc0200c6e:	3c078263          	beqz	a5,ffffffffc0201032 <buddy_check+0x796>
    return buddy.longest[0];    // 返回根节点的可用大小
ffffffffc0200c72:	0007e583          	lwu	a1,0(a5)
        }
    }
    
    size_t after_merge = buddy_nr_free_pages();  // 获取合并后可用页面数
    cprintf("合并后可用页面数: %d\n", after_merge);  // 输出合并后状态
ffffffffc0200c76:	00002517          	auipc	a0,0x2
ffffffffc0200c7a:	30250513          	addi	a0,a0,770 # ffffffffc0202f78 <etext+0x98c>
ffffffffc0200c7e:	cceff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    // 验证合并效果：尝试分配一个大块
    cprintf("验证合并效果：尝试分配4页大块\n");
ffffffffc0200c82:	00002517          	auipc	a0,0x2
ffffffffc0200c86:	31650513          	addi	a0,a0,790 # ffffffffc0202f98 <etext+0x9ac>
ffffffffc0200c8a:	cc2ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    struct Page *merged_block = alloc_pages(4);  // 尝试分配4页
ffffffffc0200c8e:	4511                	li	a0,4
ffffffffc0200c90:	77a000ef          	jal	ra,ffffffffc020140a <alloc_pages>
ffffffffc0200c94:	842a                	mv	s0,a0
    if (merged_block != NULL) {  // 如果分配成功
ffffffffc0200c96:	38050063          	beqz	a0,ffffffffc0201016 <buddy_check+0x77a>
        cprintf("✓ 合并后成功分配4页大块\n");  // 输出成功信息
ffffffffc0200c9a:	00002517          	auipc	a0,0x2
ffffffffc0200c9e:	32e50513          	addi	a0,a0,814 # ffffffffc0202fc8 <etext+0x9dc>
ffffffffc0200ca2:	caaff0ef          	jal	ra,ffffffffc020014c <cprintf>
        show_page_info(merged_block, 4, "合并后的4页块");  // 显示合并后的大块信息
ffffffffc0200ca6:	00002617          	auipc	a2,0x2
ffffffffc0200caa:	34a60613          	addi	a2,a2,842 # ffffffffc0202ff0 <etext+0xa04>
ffffffffc0200cae:	8522                	mv	a0,s0
ffffffffc0200cb0:	4591                	li	a1,4
ffffffffc0200cb2:	949ff0ef          	jal	ra,ffffffffc02005fa <show_page_info>
        free_pages(merged_block, 4);  // 释放4页大块
ffffffffc0200cb6:	8522                	mv	a0,s0
ffffffffc0200cb8:	4591                	li	a1,4
ffffffffc0200cba:	75c000ef          	jal	ra,ffffffffc0201416 <free_pages>
        cprintf("✓ 释放4页大块\n");  // 输出成功信息
ffffffffc0200cbe:	00002517          	auipc	a0,0x2
ffffffffc0200cc2:	34a50513          	addi	a0,a0,842 # ffffffffc0203008 <etext+0xa1c>
ffffffffc0200cc6:	c86ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    } else {
        cprintf("✗ 合并后无法分配4页大块\n");  // 输出失败信息
    }
    
    // 测试4: 连续分配和释放
    cprintf("\n--- 测试4: 连续分配和释放压力测试 ---\n");
ffffffffc0200cca:	00002517          	auipc	a0,0x2
ffffffffc0200cce:	37e50513          	addi	a0,a0,894 # ffffffffc0203048 <etext+0xa5c>
ffffffffc0200cd2:	0100                	addi	s0,sp,128
ffffffffc0200cd4:	c78ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    struct Page *stress_test[16];  // 压力测试页面数组
    int success_count = 0;         // 成功计数
    
    // 连续分配多个1页块
    for (int i = 0; i < 16; i++) {  // 循环分配16次
ffffffffc0200cd8:	10010913          	addi	s2,sp,256
    cprintf("\n--- 测试4: 连续分配和释放压力测试 ---\n");
ffffffffc0200cdc:	84a2                	mv	s1,s0
    int success_count = 0;         // 成功计数
ffffffffc0200cde:	4b01                	li	s6,0
        stress_test[i] = alloc_pages(1);  // 每次分配1页
ffffffffc0200ce0:	4505                	li	a0,1
ffffffffc0200ce2:	728000ef          	jal	ra,ffffffffc020140a <alloc_pages>
ffffffffc0200ce6:	e088                	sd	a0,0(s1)
        if (stress_test[i] != NULL) {  // 如果分配成功
ffffffffc0200ce8:	c111                	beqz	a0,ffffffffc0200cec <buddy_check+0x450>
            success_count++;           // 成功计数加1
ffffffffc0200cea:	2b05                	addiw	s6,s6,1
    for (int i = 0; i < 16; i++) {  // 循环分配16次
ffffffffc0200cec:	04a1                	addi	s1,s1,8
ffffffffc0200cee:	ff2499e3          	bne	s1,s2,ffffffffc0200ce0 <buddy_check+0x444>
        }
    }
    cprintf("✓ 成功分配%d个1页块\n", success_count);  // 输出成功信息
ffffffffc0200cf2:	85da                	mv	a1,s6
ffffffffc0200cf4:	00002517          	auipc	a0,0x2
ffffffffc0200cf8:	38c50513          	addi	a0,a0,908 # ffffffffc0203080 <etext+0xa94>
ffffffffc0200cfc:	c50ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    // 释放所有成功分配的块
    for (int i = 0; i < 16; i++) {  // 循环释放16次
        if (stress_test[i] != NULL) {  // 如果页面有效
ffffffffc0200d00:	6008                	ld	a0,0(s0)
ffffffffc0200d02:	c501                	beqz	a0,ffffffffc0200d0a <buddy_check+0x46e>
            free_pages(stress_test[i], 1);  // 释放1页
ffffffffc0200d04:	4585                	li	a1,1
ffffffffc0200d06:	710000ef          	jal	ra,ffffffffc0201416 <free_pages>
    for (int i = 0; i < 16; i++) {  // 循环释放16次
ffffffffc0200d0a:	0421                	addi	s0,s0,8
ffffffffc0200d0c:	fe891ae3          	bne	s2,s0,ffffffffc0200d00 <buddy_check+0x464>
        }
    }
    cprintf("✓ 释放所有分配的块\n");  // 输出成功信息
ffffffffc0200d10:	00002517          	auipc	a0,0x2
ffffffffc0200d14:	39050513          	addi	a0,a0,912 # ffffffffc02030a0 <etext+0xab4>
ffffffffc0200d18:	c34ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    // 测试5: 大块分配测试
    cprintf("\n--- 测试5: 大块分配测试 ---\n");
ffffffffc0200d1c:	00002517          	auipc	a0,0x2
ffffffffc0200d20:	3a450513          	addi	a0,a0,932 # ffffffffc02030c0 <etext+0xad4>
ffffffffc0200d24:	c28ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    struct Page *large_blocks[4];  // 大块测试页面数组
    int large_success = 0;         // 大块成功计数
    
    // 尝试分配多个大块
    cprintf("尝试分配多个16页大块，观察buddy system对大内存的处理：\n");
ffffffffc0200d28:	00002517          	auipc	a0,0x2
ffffffffc0200d2c:	3c050513          	addi	a0,a0,960 # ffffffffc02030e8 <etext+0xafc>
ffffffffc0200d30:	1004                	addi	s1,sp,32
ffffffffc0200d32:	c1aff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200d36:	8926                	mv	s2,s1
    for (int i = 0; i < 4; i++) {  // 循环分配4次
ffffffffc0200d38:	4d81                	li	s11,0
    int large_success = 0;         // 大块成功计数
ffffffffc0200d3a:	4b01                	li	s6,0
        if (large_blocks[i] != NULL) {  // 如果分配成功
            large_success++;            // 成功计数加1
            cprintf("✓ 成功分配第%d个16页大块\n", i+1);  // 输出成功信息
            show_page_info(large_blocks[i], 16, "16页大块");  // 显示16页大块详细信息
        } else {
            cprintf("! 分配第%d个16页大块失败\n", i+1);  // 输出失败信息
ffffffffc0200d3c:	00002d17          	auipc	s10,0x2
ffffffffc0200d40:	434d0d13          	addi	s10,s10,1076 # ffffffffc0203170 <etext+0xb84>
            cprintf("✓ 成功分配第%d个16页大块\n", i+1);  // 输出成功信息
ffffffffc0200d44:	00002c97          	auipc	s9,0x2
ffffffffc0200d48:	3f4c8c93          	addi	s9,s9,1012 # ffffffffc0203138 <etext+0xb4c>
            show_page_info(large_blocks[i], 16, "16页大块");  // 显示16页大块详细信息
ffffffffc0200d4c:	00002c17          	auipc	s8,0x2
ffffffffc0200d50:	414c0c13          	addi	s8,s8,1044 # ffffffffc0203160 <etext+0xb74>
    for (int i = 0; i < 4; i++) {  // 循环分配4次
ffffffffc0200d54:	4b91                	li	s7,4
        large_blocks[i] = alloc_pages(16);  // 每次分配16页
ffffffffc0200d56:	4541                	li	a0,16
ffffffffc0200d58:	6b2000ef          	jal	ra,ffffffffc020140a <alloc_pages>
            cprintf("✓ 成功分配第%d个16页大块\n", i+1);  // 输出成功信息
ffffffffc0200d5c:	2d85                	addiw	s11,s11,1
        large_blocks[i] = alloc_pages(16);  // 每次分配16页
ffffffffc0200d5e:	00a93023          	sd	a0,0(s2)
ffffffffc0200d62:	842a                	mv	s0,a0
            cprintf("✓ 成功分配第%d个16页大块\n", i+1);  // 输出成功信息
ffffffffc0200d64:	85ee                	mv	a1,s11
        if (large_blocks[i] != NULL) {  // 如果分配成功
ffffffffc0200d66:	26050663          	beqz	a0,ffffffffc0200fd2 <buddy_check+0x736>
            cprintf("✓ 成功分配第%d个16页大块\n", i+1);  // 输出成功信息
ffffffffc0200d6a:	8566                	mv	a0,s9
ffffffffc0200d6c:	be0ff0ef          	jal	ra,ffffffffc020014c <cprintf>
            show_page_info(large_blocks[i], 16, "16页大块");  // 显示16页大块详细信息
ffffffffc0200d70:	8662                	mv	a2,s8
ffffffffc0200d72:	45c1                	li	a1,16
ffffffffc0200d74:	8522                	mv	a0,s0
            large_success++;            // 成功计数加1
ffffffffc0200d76:	2b05                	addiw	s6,s6,1
            show_page_info(large_blocks[i], 16, "16页大块");  // 显示16页大块详细信息
ffffffffc0200d78:	883ff0ef          	jal	ra,ffffffffc02005fa <show_page_info>
    for (int i = 0; i < 4; i++) {  // 循环分配4次
ffffffffc0200d7c:	0921                	addi	s2,s2,8
ffffffffc0200d7e:	fd7d9ce3          	bne	s11,s7,ffffffffc0200d56 <buddy_check+0x4ba>
        }
    }
    
    cprintf("成功分配%d个16页大块，总计%dKB\n", large_success, large_success * 16 * 4);
ffffffffc0200d82:	006b161b          	slliw	a2,s6,0x6
ffffffffc0200d86:	85da                	mv	a1,s6
ffffffffc0200d88:	00002517          	auipc	a0,0x2
ffffffffc0200d8c:	41050513          	addi	a0,a0,1040 # ffffffffc0203198 <etext+0xbac>
ffffffffc0200d90:	bbcff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    // 释放大块
    cprintf("释放所有大块：\n");
ffffffffc0200d94:	00002517          	auipc	a0,0x2
ffffffffc0200d98:	43450513          	addi	a0,a0,1076 # ffffffffc02031c8 <etext+0xbdc>
ffffffffc0200d9c:	bb0ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    for (int i = 0; i < 4; i++) {  // 循环释放4次
ffffffffc0200da0:	4401                	li	s0,0
        if (large_blocks[i] != NULL) {  // 如果页面有效
            free_pages(large_blocks[i], 16);  // 释放16页
            cprintf("✓ 释放第%d个16页大块\n", i+1);  // 输出成功信息
ffffffffc0200da2:	00002b17          	auipc	s6,0x2
ffffffffc0200da6:	43eb0b13          	addi	s6,s6,1086 # ffffffffc02031e0 <etext+0xbf4>
    for (int i = 0; i < 4; i++) {  // 循环释放4次
ffffffffc0200daa:	4911                	li	s2,4
        if (large_blocks[i] != NULL) {  // 如果页面有效
ffffffffc0200dac:	6088                	ld	a0,0(s1)
            cprintf("✓ 释放第%d个16页大块\n", i+1);  // 输出成功信息
ffffffffc0200dae:	2405                	addiw	s0,s0,1
        if (large_blocks[i] != NULL) {  // 如果页面有效
ffffffffc0200db0:	c901                	beqz	a0,ffffffffc0200dc0 <buddy_check+0x524>
            free_pages(large_blocks[i], 16);  // 释放16页
ffffffffc0200db2:	45c1                	li	a1,16
ffffffffc0200db4:	662000ef          	jal	ra,ffffffffc0201416 <free_pages>
            cprintf("✓ 释放第%d个16页大块\n", i+1);  // 输出成功信息
ffffffffc0200db8:	85a2                	mv	a1,s0
ffffffffc0200dba:	855a                	mv	a0,s6
ffffffffc0200dbc:	b90ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    for (int i = 0; i < 4; i++) {  // 循环释放4次
ffffffffc0200dc0:	04a1                	addi	s1,s1,8
ffffffffc0200dc2:	ff2415e3          	bne	s0,s2,ffffffffc0200dac <buddy_check+0x510>
        }
    }
    
    // 测试6: 边界情况测试
    cprintf("\n--- 测试6: 边界情况测试 ---\n");
ffffffffc0200dc6:	00002517          	auipc	a0,0x2
ffffffffc0200dca:	43a50513          	addi	a0,a0,1082 # ffffffffc0203200 <etext+0xc14>
ffffffffc0200dce:	b7eff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    // 测试分配大块内存
    cprintf("测试极限分配：尝试分配1024页（4MB）\n");
ffffffffc0200dd2:	00002517          	auipc	a0,0x2
ffffffffc0200dd6:	45650513          	addi	a0,a0,1110 # ffffffffc0203228 <etext+0xc3c>
ffffffffc0200dda:	b72ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    struct Page *huge_block = alloc_pages(1024);  // 尝试分配1024页
ffffffffc0200dde:	40000513          	li	a0,1024
ffffffffc0200de2:	628000ef          	jal	ra,ffffffffc020140a <alloc_pages>
ffffffffc0200de6:	842a                	mv	s0,a0
    if (huge_block != NULL) {  // 如果分配成功
ffffffffc0200de8:	22050063          	beqz	a0,ffffffffc0201008 <buddy_check+0x76c>
        cprintf("✓ 分配1024页成功\n");  // 输出成功信息
ffffffffc0200dec:	00002517          	auipc	a0,0x2
ffffffffc0200df0:	47450513          	addi	a0,a0,1140 # ffffffffc0203260 <etext+0xc74>
ffffffffc0200df4:	b58ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        show_page_info(huge_block, 1024, "1024页超大块");  // 显示1024页详细信息
ffffffffc0200df8:	00002617          	auipc	a2,0x2
ffffffffc0200dfc:	48860613          	addi	a2,a2,1160 # ffffffffc0203280 <etext+0xc94>
ffffffffc0200e00:	8522                	mv	a0,s0
ffffffffc0200e02:	40000593          	li	a1,1024
ffffffffc0200e06:	ff4ff0ef          	jal	ra,ffffffffc02005fa <show_page_info>
        free_pages(huge_block, 1024);   // 释放1024页
ffffffffc0200e0a:	8522                	mv	a0,s0
ffffffffc0200e0c:	40000593          	li	a1,1024
ffffffffc0200e10:	606000ef          	jal	ra,ffffffffc0201416 <free_pages>
        cprintf("✓ 释放1024页成功\n");  // 输出成功信息
ffffffffc0200e14:	00002517          	auipc	a0,0x2
ffffffffc0200e18:	48450513          	addi	a0,a0,1156 # ffffffffc0203298 <etext+0xcac>
ffffffffc0200e1c:	b30ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    } else {
        cprintf("! 分配1024页失败（可能超出buddy system最大支持范围）\n");  // 输出失败信息
    }
    
    // 测试分配最大可能的块
    cprintf("测试分配512页（2MB）\n");
ffffffffc0200e20:	00002517          	auipc	a0,0x2
ffffffffc0200e24:	4e050513          	addi	a0,a0,1248 # ffffffffc0203300 <etext+0xd14>
ffffffffc0200e28:	b24ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    struct Page *max_block = alloc_pages(512);  // 尝试分配512页
ffffffffc0200e2c:	20000513          	li	a0,512
ffffffffc0200e30:	5da000ef          	jal	ra,ffffffffc020140a <alloc_pages>
ffffffffc0200e34:	842a                	mv	s0,a0
    if (max_block != NULL) {  // 如果分配成功
ffffffffc0200e36:	1c050263          	beqz	a0,ffffffffc0200ffa <buddy_check+0x75e>
        cprintf("✓ 分配512页成功\n");  // 输出成功信息
ffffffffc0200e3a:	00002517          	auipc	a0,0x2
ffffffffc0200e3e:	4e650513          	addi	a0,a0,1254 # ffffffffc0203320 <etext+0xd34>
ffffffffc0200e42:	b0aff0ef          	jal	ra,ffffffffc020014c <cprintf>
        show_page_info(max_block, 512, "512页大块");  // 显示512页详细信息
ffffffffc0200e46:	00002617          	auipc	a2,0x2
ffffffffc0200e4a:	4f260613          	addi	a2,a2,1266 # ffffffffc0203338 <etext+0xd4c>
ffffffffc0200e4e:	8522                	mv	a0,s0
ffffffffc0200e50:	20000593          	li	a1,512
ffffffffc0200e54:	fa6ff0ef          	jal	ra,ffffffffc02005fa <show_page_info>
        free_pages(max_block, 512);   // 释放512页
ffffffffc0200e58:	8522                	mv	a0,s0
ffffffffc0200e5a:	20000593          	li	a1,512
ffffffffc0200e5e:	5b8000ef          	jal	ra,ffffffffc0201416 <free_pages>
        cprintf("✓ 释放512页成功\n");  // 输出成功信息
ffffffffc0200e62:	00002517          	auipc	a0,0x2
ffffffffc0200e66:	4e650513          	addi	a0,a0,1254 # ffffffffc0203348 <etext+0xd5c>
ffffffffc0200e6a:	ae2ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    } else {
        cprintf("! 分配512页失败\n");  // 输出失败信息
    }
    
    // 测试7: 碎片整理效果测试
    cprintf("\n--- 测试7: 碎片整理效果测试 ---\n");
ffffffffc0200e6e:	00002517          	auipc	a0,0x2
ffffffffc0200e72:	50a50513          	addi	a0,a0,1290 # ffffffffc0203378 <etext+0xd8c>
ffffffffc0200e76:	0084                	addi	s1,sp,64
ffffffffc0200e78:	ad4ff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200e7c:	8426                	mv	s0,s1
    
    // 分配8个2页块
    for (int i = 0; i < 8; i++) {  // 循环分配8次
        frag_test[i] = alloc_pages(2);  // 每次分配2页
        if (frag_test[i] != NULL) {  // 如果分配成功
            cprintf("✓ 分配第%d个2页块\n", i+1);  // 输出成功信息
ffffffffc0200e7e:	00002b17          	auipc	s6,0x2
ffffffffc0200e82:	52ab0b13          	addi	s6,s6,1322 # ffffffffc02033a8 <etext+0xdbc>
    for (int i = 0; i < 8; i++) {  // 循环分配8次
ffffffffc0200e86:	4921                	li	s2,8
        frag_test[i] = alloc_pages(2);  // 每次分配2页
ffffffffc0200e88:	4509                	li	a0,2
ffffffffc0200e8a:	580000ef          	jal	ra,ffffffffc020140a <alloc_pages>
ffffffffc0200e8e:	e008                	sd	a0,0(s0)
            cprintf("✓ 分配第%d个2页块\n", i+1);  // 输出成功信息
ffffffffc0200e90:	2985                	addiw	s3,s3,1
        if (frag_test[i] != NULL) {  // 如果分配成功
ffffffffc0200e92:	c509                	beqz	a0,ffffffffc0200e9c <buddy_check+0x600>
            cprintf("✓ 分配第%d个2页块\n", i+1);  // 输出成功信息
ffffffffc0200e94:	85ce                	mv	a1,s3
ffffffffc0200e96:	855a                	mv	a0,s6
ffffffffc0200e98:	ab4ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    for (int i = 0; i < 8; i++) {  // 循环分配8次
ffffffffc0200e9c:	0421                	addi	s0,s0,8
ffffffffc0200e9e:	ff2995e3          	bne	s3,s2,ffffffffc0200e88 <buddy_check+0x5ec>
ffffffffc0200ea2:	04810913          	addi	s2,sp,72
ffffffffc0200ea6:	4409                	li	s0,2
    
    // 释放奇数位置的块，制造碎片
    for (int i = 1; i < 8; i += 2) {  // 释放奇数索引的块
        if (frag_test[i] != NULL) {  // 如果页面有效
            free_pages(frag_test[i], 2);  // 释放2页
            cprintf("✓ 释放第%d个2页块（制造碎片）\n", i+1);  // 输出成功信息
ffffffffc0200ea8:	00002b17          	auipc	s6,0x2
ffffffffc0200eac:	520b0b13          	addi	s6,s6,1312 # ffffffffc02033c8 <etext+0xddc>
    for (int i = 1; i < 8; i += 2) {  // 释放奇数索引的块
ffffffffc0200eb0:	49a9                	li	s3,10
        if (frag_test[i] != NULL) {  // 如果页面有效
ffffffffc0200eb2:	00093503          	ld	a0,0(s2)
ffffffffc0200eb6:	c901                	beqz	a0,ffffffffc0200ec6 <buddy_check+0x62a>
            free_pages(frag_test[i], 2);  // 释放2页
ffffffffc0200eb8:	4589                	li	a1,2
ffffffffc0200eba:	55c000ef          	jal	ra,ffffffffc0201416 <free_pages>
            cprintf("✓ 释放第%d个2页块（制造碎片）\n", i+1);  // 输出成功信息
ffffffffc0200ebe:	85a2                	mv	a1,s0
ffffffffc0200ec0:	855a                	mv	a0,s6
ffffffffc0200ec2:	a8aff0ef          	jal	ra,ffffffffc020014c <cprintf>
    for (int i = 1; i < 8; i += 2) {  // 释放奇数索引的块
ffffffffc0200ec6:	2409                	addiw	s0,s0,2
ffffffffc0200ec8:	0941                	addi	s2,s2,16
ffffffffc0200eca:	ff3414e3          	bne	s0,s3,ffffffffc0200eb2 <buddy_check+0x616>
        }
    }
    
    // 尝试分配大块，测试碎片整理
    struct Page *defrag_test = alloc_pages(8);  // 尝试分配8页
ffffffffc0200ece:	4521                	li	a0,8
ffffffffc0200ed0:	53a000ef          	jal	ra,ffffffffc020140a <alloc_pages>
ffffffffc0200ed4:	842a                	mv	s0,a0
    if (defrag_test != NULL) {  // 如果分配成功
ffffffffc0200ed6:	10050b63          	beqz	a0,ffffffffc0200fec <buddy_check+0x750>
        cprintf("✓ 碎片化后仍能分配8页大块\n");  // 输出成功信息
ffffffffc0200eda:	00002517          	auipc	a0,0x2
ffffffffc0200ede:	51e50513          	addi	a0,a0,1310 # ffffffffc02033f8 <etext+0xe0c>
ffffffffc0200ee2:	a6aff0ef          	jal	ra,ffffffffc020014c <cprintf>
        free_pages(defrag_test, 8);             // 释放8页
ffffffffc0200ee6:	45a1                	li	a1,8
ffffffffc0200ee8:	8522                	mv	a0,s0
ffffffffc0200eea:	52c000ef          	jal	ra,ffffffffc0201416 <free_pages>
ffffffffc0200eee:	04048413          	addi	s0,s1,64
        cprintf("! 碎片化后无法分配8页大块\n");  // 输出失败信息
    }
    
    // 清理剩余的偶数位置块
    for (int i = 0; i < 8; i += 2) {  // 释放偶数索引的块
        if (frag_test[i] != NULL) {  // 如果页面有效
ffffffffc0200ef2:	6088                	ld	a0,0(s1)
ffffffffc0200ef4:	c501                	beqz	a0,ffffffffc0200efc <buddy_check+0x660>
            free_pages(frag_test[i], 2);  // 释放2页
ffffffffc0200ef6:	4589                	li	a1,2
ffffffffc0200ef8:	51e000ef          	jal	ra,ffffffffc0201416 <free_pages>
    for (int i = 0; i < 8; i += 2) {  // 释放偶数索引的块
ffffffffc0200efc:	04c1                	addi	s1,s1,16
ffffffffc0200efe:	fe941ae3          	bne	s0,s1,ffffffffc0200ef2 <buddy_check+0x656>
        }
    }
    
    // 最终内存泄漏检查
    cprintf("\n--- 最终检查 ---\n");
ffffffffc0200f02:	00002517          	auipc	a0,0x2
ffffffffc0200f06:	54650513          	addi	a0,a0,1350 # ffffffffc0203448 <etext+0xe5c>
ffffffffc0200f0a:	a42ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    if (buddy.longest == NULL)  // 如果未初始化
ffffffffc0200f0e:	008a3783          	ld	a5,8(s4)
ffffffffc0200f12:	12078263          	beqz	a5,ffffffffc0201036 <buddy_check+0x79a>
    return buddy.longest[0];    // 返回根节点的可用大小
ffffffffc0200f16:	0007e403          	lwu	s0,0(a5)
    size_t final_free = buddy_nr_free_pages();  // 获取最终可用页面数
    cprintf("最终可用页面数: %d\n", final_free);  // 输出最终状态
ffffffffc0200f1a:	85a2                	mv	a1,s0
ffffffffc0200f1c:	00002517          	auipc	a0,0x2
ffffffffc0200f20:	54450513          	addi	a0,a0,1348 # ffffffffc0203460 <etext+0xe74>
ffffffffc0200f24:	a28ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    if (final_free >= initial_free) {  // 如果没有内存泄漏
ffffffffc0200f28:	0b547963          	bgeu	s0,s5,ffffffffc0200fda <buddy_check+0x73e>
        cprintf("✓ 内存泄漏检查通过\n");  // 输出通过信息
    } else {
        cprintf("✗ 警告：可能存在内存泄漏（初始:%d, 最终:%d）\n",  // 输出警告信息
ffffffffc0200f2c:	8622                	mv	a2,s0
ffffffffc0200f2e:	85d6                	mv	a1,s5
ffffffffc0200f30:	00002517          	auipc	a0,0x2
ffffffffc0200f34:	57050513          	addi	a0,a0,1392 # ffffffffc02034a0 <etext+0xeb4>
ffffffffc0200f38:	a14ff0ef          	jal	ra,ffffffffc020014c <cprintf>
                initial_free, final_free);
    }
    
    // 测试8: 功能正确性验证
    cprintf("\n--- 测试8: 功能正确性验证 ---\n");
ffffffffc0200f3c:	00002517          	auipc	a0,0x2
ffffffffc0200f40:	5ac50513          	addi	a0,a0,1452 # ffffffffc02034e8 <etext+0xefc>
ffffffffc0200f44:	a08ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    // 验证分配的页面地址是否合理
    struct Page *verify_p1 = alloc_pages(1);  // 分配验证页面1
ffffffffc0200f48:	4505                	li	a0,1
ffffffffc0200f4a:	4c0000ef          	jal	ra,ffffffffc020140a <alloc_pages>
ffffffffc0200f4e:	842a                	mv	s0,a0
    struct Page *verify_p2 = alloc_pages(1);  // 分配验证页面2
ffffffffc0200f50:	4505                	li	a0,1
ffffffffc0200f52:	4b8000ef          	jal	ra,ffffffffc020140a <alloc_pages>
ffffffffc0200f56:	84aa                	mv	s1,a0
    
    if (verify_p1 != NULL && verify_p2 != NULL) {  // 如果分配成功
ffffffffc0200f58:	c829                	beqz	s0,ffffffffc0200faa <buddy_check+0x70e>
ffffffffc0200f5a:	c921                	beqz	a0,ffffffffc0200faa <buddy_check+0x70e>
        // 检查页面地址是否在合理范围内
        if (verify_p1 >= buddy.base && verify_p1 < buddy.base + buddy.size &&
ffffffffc0200f5c:	010a3703          	ld	a4,16(s4)
ffffffffc0200f60:	00e46f63          	bltu	s0,a4,ffffffffc0200f7e <buddy_check+0x6e2>
ffffffffc0200f64:	000a6683          	lwu	a3,0(s4)
ffffffffc0200f68:	00269793          	slli	a5,a3,0x2
ffffffffc0200f6c:	97b6                	add	a5,a5,a3
ffffffffc0200f6e:	078e                	slli	a5,a5,0x3
ffffffffc0200f70:	97ba                	add	a5,a5,a4
ffffffffc0200f72:	00f47663          	bgeu	s0,a5,ffffffffc0200f7e <buddy_check+0x6e2>
ffffffffc0200f76:	00e56463          	bltu	a0,a4,ffffffffc0200f7e <buddy_check+0x6e2>
            verify_p2 >= buddy.base && verify_p2 < buddy.base + buddy.size) {
ffffffffc0200f7a:	0cf56763          	bltu	a0,a5,ffffffffc0201048 <buddy_check+0x7ac>
            cprintf("✓ 分配的页面地址在合理范围内\n");  // 输出成功信息
        } else {
            cprintf("✗ 分配的页面地址超出范围\n");  // 输出失败信息
ffffffffc0200f7e:	00002517          	auipc	a0,0x2
ffffffffc0200f82:	5ca50513          	addi	a0,a0,1482 # ffffffffc0203548 <etext+0xf5c>
ffffffffc0200f86:	9c6ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        }
        
        // 检查页面是否不同
        if (verify_p1 != verify_p2) {  // 如果页面地址不同
ffffffffc0200f8a:	0a940863          	beq	s0,s1,ffffffffc020103a <buddy_check+0x79e>
            cprintf("✓ 分配的页面地址不同\n");  // 输出成功信息
ffffffffc0200f8e:	00002517          	auipc	a0,0x2
ffffffffc0200f92:	5e250513          	addi	a0,a0,1506 # ffffffffc0203570 <etext+0xf84>
ffffffffc0200f96:	9b6ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        } else {
            cprintf("✗ 分配了相同的页面地址\n");  // 输出失败信息
        }
        
        free_pages(verify_p1, 1);  // 释放验证页面1
ffffffffc0200f9a:	4585                	li	a1,1
ffffffffc0200f9c:	8522                	mv	a0,s0
ffffffffc0200f9e:	478000ef          	jal	ra,ffffffffc0201416 <free_pages>
        free_pages(verify_p2, 1);  // 释放验证页面2
ffffffffc0200fa2:	4585                	li	a1,1
ffffffffc0200fa4:	8526                	mv	a0,s1
ffffffffc0200fa6:	470000ef          	jal	ra,ffffffffc0201416 <free_pages>
    }
    
    cprintf("\n--- buddy_check() 所有测试完成! ---\n");  // 输出测试完成信息
}
ffffffffc0200faa:	7416                	ld	s0,352(sp)
ffffffffc0200fac:	70b6                	ld	ra,360(sp)
ffffffffc0200fae:	64f6                	ld	s1,344(sp)
ffffffffc0200fb0:	6956                	ld	s2,336(sp)
ffffffffc0200fb2:	69b6                	ld	s3,328(sp)
ffffffffc0200fb4:	6a16                	ld	s4,320(sp)
ffffffffc0200fb6:	7af2                	ld	s5,312(sp)
ffffffffc0200fb8:	7b52                	ld	s6,304(sp)
ffffffffc0200fba:	7bb2                	ld	s7,296(sp)
ffffffffc0200fbc:	7c12                	ld	s8,288(sp)
ffffffffc0200fbe:	6cf2                	ld	s9,280(sp)
ffffffffc0200fc0:	6d52                	ld	s10,272(sp)
ffffffffc0200fc2:	6db2                	ld	s11,264(sp)
    cprintf("\n--- buddy_check() 所有测试完成! ---\n");  // 输出测试完成信息
ffffffffc0200fc4:	00002517          	auipc	a0,0x2
ffffffffc0200fc8:	5fc50513          	addi	a0,a0,1532 # ffffffffc02035c0 <etext+0xfd4>
}
ffffffffc0200fcc:	6175                	addi	sp,sp,368
    cprintf("\n--- buddy_check() 所有测试完成! ---\n");  // 输出测试完成信息
ffffffffc0200fce:	97eff06f          	j	ffffffffc020014c <cprintf>
            cprintf("! 分配第%d个16页大块失败\n", i+1);  // 输出失败信息
ffffffffc0200fd2:	856a                	mv	a0,s10
ffffffffc0200fd4:	978ff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200fd8:	b355                	j	ffffffffc0200d7c <buddy_check+0x4e0>
        cprintf("✓ 内存泄漏检查通过\n");  // 输出通过信息
ffffffffc0200fda:	00002517          	auipc	a0,0x2
ffffffffc0200fde:	4a650513          	addi	a0,a0,1190 # ffffffffc0203480 <etext+0xe94>
ffffffffc0200fe2:	96aff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200fe6:	bf99                	j	ffffffffc0200f3c <buddy_check+0x6a0>
        return 0;               // 返回0
ffffffffc0200fe8:	4581                	li	a1,0
ffffffffc0200fea:	b995                	j	ffffffffc0200c5e <buddy_check+0x3c2>
        cprintf("! 碎片化后无法分配8页大块\n");  // 输出失败信息
ffffffffc0200fec:	00002517          	auipc	a0,0x2
ffffffffc0200ff0:	43450513          	addi	a0,a0,1076 # ffffffffc0203420 <etext+0xe34>
ffffffffc0200ff4:	958ff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200ff8:	bddd                	j	ffffffffc0200eee <buddy_check+0x652>
        cprintf("! 分配512页失败\n");  // 输出失败信息
ffffffffc0200ffa:	00002517          	auipc	a0,0x2
ffffffffc0200ffe:	36650513          	addi	a0,a0,870 # ffffffffc0203360 <etext+0xd74>
ffffffffc0201002:	94aff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0201006:	b5a5                	j	ffffffffc0200e6e <buddy_check+0x5d2>
        cprintf("! 分配1024页失败（可能超出buddy system最大支持范围）\n");  // 输出失败信息
ffffffffc0201008:	00002517          	auipc	a0,0x2
ffffffffc020100c:	2b050513          	addi	a0,a0,688 # ffffffffc02032b8 <etext+0xccc>
ffffffffc0201010:	93cff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0201014:	b531                	j	ffffffffc0200e20 <buddy_check+0x584>
        cprintf("✗ 合并后无法分配4页大块\n");  // 输出失败信息
ffffffffc0201016:	00002517          	auipc	a0,0x2
ffffffffc020101a:	00a50513          	addi	a0,a0,10 # ffffffffc0203020 <etext+0xa34>
ffffffffc020101e:	92eff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0201022:	b165                	j	ffffffffc0200cca <buddy_check+0x42e>
        return 0;               // 返回0
ffffffffc0201024:	4a81                	li	s5,0
ffffffffc0201026:	969ff06f          	j	ffffffffc020098e <buddy_check+0xf2>
ffffffffc020102a:	4581                	li	a1,0
ffffffffc020102c:	b425                	j	ffffffffc0200a54 <buddy_check+0x1b8>
ffffffffc020102e:	4581                	li	a1,0
ffffffffc0201030:	b6c5                	j	ffffffffc0200c10 <buddy_check+0x374>
ffffffffc0201032:	4581                	li	a1,0
ffffffffc0201034:	b189                	j	ffffffffc0200c76 <buddy_check+0x3da>
ffffffffc0201036:	4401                	li	s0,0
ffffffffc0201038:	b5cd                	j	ffffffffc0200f1a <buddy_check+0x67e>
            cprintf("✗ 分配了相同的页面地址\n");  // 输出失败信息
ffffffffc020103a:	00002517          	auipc	a0,0x2
ffffffffc020103e:	55e50513          	addi	a0,a0,1374 # ffffffffc0203598 <etext+0xfac>
ffffffffc0201042:	90aff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0201046:	bf91                	j	ffffffffc0200f9a <buddy_check+0x6fe>
            cprintf("✓ 分配的页面地址在合理范围内\n");  // 输出成功信息
ffffffffc0201048:	00002517          	auipc	a0,0x2
ffffffffc020104c:	4d050513          	addi	a0,a0,1232 # ffffffffc0203518 <etext+0xf2c>
ffffffffc0201050:	8fcff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0201054:	bf1d                	j	ffffffffc0200f8a <buddy_check+0x6ee>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);  // 引用计数为0
ffffffffc0201056:	00002697          	auipc	a3,0x2
ffffffffc020105a:	94268693          	addi	a3,a3,-1726 # ffffffffc0202998 <etext+0x3ac>
ffffffffc020105e:	00002617          	auipc	a2,0x2
ffffffffc0201062:	84260613          	addi	a2,a2,-1982 # ffffffffc02028a0 <etext+0x2b4>
ffffffffc0201066:	0df00593          	li	a1,223
ffffffffc020106a:	00002517          	auipc	a0,0x2
ffffffffc020106e:	84e50513          	addi	a0,a0,-1970 # ffffffffc02028b8 <etext+0x2cc>
ffffffffc0201072:	950ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);  // 确保页面地址不同
ffffffffc0201076:	00002697          	auipc	a3,0x2
ffffffffc020107a:	8fa68693          	addi	a3,a3,-1798 # ffffffffc0202970 <etext+0x384>
ffffffffc020107e:	00002617          	auipc	a2,0x2
ffffffffc0201082:	82260613          	addi	a2,a2,-2014 # ffffffffc02028a0 <etext+0x2b4>
ffffffffc0201086:	0de00593          	li	a1,222
ffffffffc020108a:	00002517          	auipc	a0,0x2
ffffffffc020108e:	82e50513          	addi	a0,a0,-2002 # ffffffffc02028b8 <etext+0x2cc>
ffffffffc0201092:	930ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p7 != NULL);     // 确保分配成功
ffffffffc0201096:	00002697          	auipc	a3,0x2
ffffffffc020109a:	ce268693          	addi	a3,a3,-798 # ffffffffc0202d78 <etext+0x78c>
ffffffffc020109e:	00002617          	auipc	a2,0x2
ffffffffc02010a2:	80260613          	addi	a2,a2,-2046 # ffffffffc02028a0 <etext+0x2b4>
ffffffffc02010a6:	14a00593          	li	a1,330
ffffffffc02010aa:	00002517          	auipc	a0,0x2
ffffffffc02010ae:	80e50513          	addi	a0,a0,-2034 # ffffffffc02028b8 <etext+0x2cc>
ffffffffc02010b2:	910ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p6 != NULL);     // 确保分配成功
ffffffffc02010b6:	00002697          	auipc	a3,0x2
ffffffffc02010ba:	c5a68693          	addi	a3,a3,-934 # ffffffffc0202d10 <etext+0x724>
ffffffffc02010be:	00001617          	auipc	a2,0x1
ffffffffc02010c2:	7e260613          	addi	a2,a2,2018 # ffffffffc02028a0 <etext+0x2b4>
ffffffffc02010c6:	14500593          	li	a1,325
ffffffffc02010ca:	00001517          	auipc	a0,0x1
ffffffffc02010ce:	7ee50513          	addi	a0,a0,2030 # ffffffffc02028b8 <etext+0x2cc>
ffffffffc02010d2:	8f0ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p5 != NULL);     // 确保分配成功
ffffffffc02010d6:	00002697          	auipc	a3,0x2
ffffffffc02010da:	bd268693          	addi	a3,a3,-1070 # ffffffffc0202ca8 <etext+0x6bc>
ffffffffc02010de:	00001617          	auipc	a2,0x1
ffffffffc02010e2:	7c260613          	addi	a2,a2,1986 # ffffffffc02028a0 <etext+0x2b4>
ffffffffc02010e6:	14000593          	li	a1,320
ffffffffc02010ea:	00001517          	auipc	a0,0x1
ffffffffc02010ee:	7ce50513          	addi	a0,a0,1998 # ffffffffc02028b8 <etext+0x2cc>
ffffffffc02010f2:	8d0ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p3 != NULL);     // 确保分配成功
ffffffffc02010f6:	00002697          	auipc	a3,0x2
ffffffffc02010fa:	b4a68693          	addi	a3,a3,-1206 # ffffffffc0202c40 <etext+0x654>
ffffffffc02010fe:	00001617          	auipc	a2,0x1
ffffffffc0201102:	7a260613          	addi	a2,a2,1954 # ffffffffc02028a0 <etext+0x2b4>
ffffffffc0201106:	13b00593          	li	a1,315
ffffffffc020110a:	00001517          	auipc	a0,0x1
ffffffffc020110e:	7ae50513          	addi	a0,a0,1966 # ffffffffc02028b8 <etext+0x2cc>
ffffffffc0201112:	8b0ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p4 != NULL);    // 确保分配成功
ffffffffc0201116:	00002697          	auipc	a3,0x2
ffffffffc020111a:	a0a68693          	addi	a3,a3,-1526 # ffffffffc0202b20 <etext+0x534>
ffffffffc020111e:	00001617          	auipc	a2,0x1
ffffffffc0201122:	78260613          	addi	a2,a2,1922 # ffffffffc02028a0 <etext+0x2b4>
ffffffffc0201126:	11c00593          	li	a1,284
ffffffffc020112a:	00001517          	auipc	a0,0x1
ffffffffc020112e:	78e50513          	addi	a0,a0,1934 # ffffffffc02028b8 <etext+0x2cc>
ffffffffc0201132:	890ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p2 != NULL);    // 确保分配成功
ffffffffc0201136:	00002697          	auipc	a3,0x2
ffffffffc020113a:	9ba68693          	addi	a3,a3,-1606 # ffffffffc0202af0 <etext+0x504>
ffffffffc020113e:	00001617          	auipc	a2,0x1
ffffffffc0201142:	76260613          	addi	a2,a2,1890 # ffffffffc02028a0 <etext+0x2b4>
ffffffffc0201146:	11700593          	li	a1,279
ffffffffc020114a:	00001517          	auipc	a0,0x1
ffffffffc020114e:	76e50513          	addi	a0,a0,1902 # ffffffffc02028b8 <etext+0x2cc>
ffffffffc0201152:	870ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);  // 页面地址在有效范围内
ffffffffc0201156:	00002697          	auipc	a3,0x2
ffffffffc020115a:	8c268693          	addi	a3,a3,-1854 # ffffffffc0202a18 <etext+0x42c>
ffffffffc020115e:	00001617          	auipc	a2,0x1
ffffffffc0201162:	74260613          	addi	a2,a2,1858 # ffffffffc02028a0 <etext+0x2b4>
ffffffffc0201166:	0e300593          	li	a1,227
ffffffffc020116a:	00001517          	auipc	a0,0x1
ffffffffc020116e:	74e50513          	addi	a0,a0,1870 # ffffffffc02028b8 <etext+0x2cc>
ffffffffc0201172:	850ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);  // 页面地址在有效范围内
ffffffffc0201176:	00002697          	auipc	a3,0x2
ffffffffc020117a:	88268693          	addi	a3,a3,-1918 # ffffffffc02029f8 <etext+0x40c>
ffffffffc020117e:	00001617          	auipc	a2,0x1
ffffffffc0201182:	72260613          	addi	a2,a2,1826 # ffffffffc02028a0 <etext+0x2b4>
ffffffffc0201186:	0e200593          	li	a1,226
ffffffffc020118a:	00001517          	auipc	a0,0x1
ffffffffc020118e:	72e50513          	addi	a0,a0,1838 # ffffffffc02028b8 <etext+0x2cc>
ffffffffc0201192:	830ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);  // 页面地址在有效范围内
ffffffffc0201196:	00002697          	auipc	a3,0x2
ffffffffc020119a:	84268693          	addi	a3,a3,-1982 # ffffffffc02029d8 <etext+0x3ec>
ffffffffc020119e:	00001617          	auipc	a2,0x1
ffffffffc02011a2:	70260613          	addi	a2,a2,1794 # ffffffffc02028a0 <etext+0x2b4>
ffffffffc02011a6:	0e100593          	li	a1,225
ffffffffc02011aa:	00001517          	auipc	a0,0x1
ffffffffc02011ae:	70e50513          	addi	a0,a0,1806 # ffffffffc02028b8 <etext+0x2cc>
ffffffffc02011b2:	810ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p2 = alloc_page()) != NULL);  // 分配第3个页面
ffffffffc02011b6:	00001697          	auipc	a3,0x1
ffffffffc02011ba:	79a68693          	addi	a3,a3,1946 # ffffffffc0202950 <etext+0x364>
ffffffffc02011be:	00001617          	auipc	a2,0x1
ffffffffc02011c2:	6e260613          	addi	a2,a2,1762 # ffffffffc02028a0 <etext+0x2b4>
ffffffffc02011c6:	0dc00593          	li	a1,220
ffffffffc02011ca:	00001517          	auipc	a0,0x1
ffffffffc02011ce:	6ee50513          	addi	a0,a0,1774 # ffffffffc02028b8 <etext+0x2cc>
ffffffffc02011d2:	ff1fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p1 = alloc_page()) != NULL);  // 分配第2个页面
ffffffffc02011d6:	00001697          	auipc	a3,0x1
ffffffffc02011da:	75a68693          	addi	a3,a3,1882 # ffffffffc0202930 <etext+0x344>
ffffffffc02011de:	00001617          	auipc	a2,0x1
ffffffffc02011e2:	6c260613          	addi	a2,a2,1730 # ffffffffc02028a0 <etext+0x2b4>
ffffffffc02011e6:	0db00593          	li	a1,219
ffffffffc02011ea:	00001517          	auipc	a0,0x1
ffffffffc02011ee:	6ce50513          	addi	a0,a0,1742 # ffffffffc02028b8 <etext+0x2cc>
ffffffffc02011f2:	fd1fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p0 = alloc_page()) != NULL);  // 分配第1个页面
ffffffffc02011f6:	00001697          	auipc	a3,0x1
ffffffffc02011fa:	71a68693          	addi	a3,a3,1818 # ffffffffc0202910 <etext+0x324>
ffffffffc02011fe:	00001617          	auipc	a2,0x1
ffffffffc0201202:	6a260613          	addi	a2,a2,1698 # ffffffffc02028a0 <etext+0x2b4>
ffffffffc0201206:	0da00593          	li	a1,218
ffffffffc020120a:	00001517          	auipc	a0,0x1
ffffffffc020120e:	6ae50513          	addi	a0,a0,1710 # ffffffffc02028b8 <etext+0x2cc>
ffffffffc0201212:	fb1fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p1 != NULL);    // 确保分配成功
ffffffffc0201216:	00002697          	auipc	a3,0x2
ffffffffc020121a:	8aa68693          	addi	a3,a3,-1878 # ffffffffc0202ac0 <etext+0x4d4>
ffffffffc020121e:	00001617          	auipc	a2,0x1
ffffffffc0201222:	68260613          	addi	a2,a2,1666 # ffffffffc02028a0 <etext+0x2b4>
ffffffffc0201226:	11200593          	li	a1,274
ffffffffc020122a:	00001517          	auipc	a0,0x1
ffffffffc020122e:	68e50513          	addi	a0,a0,1678 # ffffffffc02028b8 <etext+0x2cc>
ffffffffc0201232:	f91fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p8 != NULL);    // 确保分配成功
ffffffffc0201236:	00002697          	auipc	a3,0x2
ffffffffc020123a:	91a68693          	addi	a3,a3,-1766 # ffffffffc0202b50 <etext+0x564>
ffffffffc020123e:	00001617          	auipc	a2,0x1
ffffffffc0201242:	66260613          	addi	a2,a2,1634 # ffffffffc02028a0 <etext+0x2b4>
ffffffffc0201246:	12100593          	li	a1,289
ffffffffc020124a:	00001517          	auipc	a0,0x1
ffffffffc020124e:	66e50513          	addi	a0,a0,1646 # ffffffffc02028b8 <etext+0x2cc>
ffffffffc0201252:	f71fe0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0201256 <buddy_init_memmap>:
buddy_init_memmap(struct Page *base, size_t n) {
ffffffffc0201256:	7179                	addi	sp,sp,-48
ffffffffc0201258:	f406                	sd	ra,40(sp)
ffffffffc020125a:	f022                	sd	s0,32(sp)
ffffffffc020125c:	ec26                	sd	s1,24(sp)
ffffffffc020125e:	e84a                	sd	s2,16(sp)
ffffffffc0201260:	e44e                	sd	s3,8(sp)
    assert(n > 0);          // 确保页面数大于0
ffffffffc0201262:	18058463          	beqz	a1,ffffffffc02013ea <buddy_init_memmap+0x194>
    while (size < n) size <<= 1;  // 循环左移直到找到不小于n的2的幂
ffffffffc0201266:	4705                	li	a4,1
ffffffffc0201268:	84ae                	mv	s1,a1
ffffffffc020126a:	842a                	mv	s0,a0
    unsigned size = 1;      // 初始大小为1
ffffffffc020126c:	4785                	li	a5,1
    while (size < n) size <<= 1;  // 循环左移直到找到不小于n的2的幂
ffffffffc020126e:	12e58563          	beq	a1,a4,ffffffffc0201398 <buddy_init_memmap+0x142>
ffffffffc0201272:	0017979b          	slliw	a5,a5,0x1
ffffffffc0201276:	02079713          	slli	a4,a5,0x20
ffffffffc020127a:	9301                	srli	a4,a4,0x20
ffffffffc020127c:	fe976be3          	bltu	a4,s1,ffffffffc0201272 <buddy_init_memmap+0x1c>
    if (size > 2048) {      // 如果超过2048页
ffffffffc0201280:	6705                	lui	a4,0x1
ffffffffc0201282:	80070713          	addi	a4,a4,-2048 # 800 <kern_entry-0xffffffffc01ff800>
ffffffffc0201286:	0007891b          	sext.w	s2,a5
ffffffffc020128a:	10f76463          	bltu	a4,a5,ffffffffc0201392 <buddy_init_memmap+0x13c>
    buddy.size = size;      // 设置buddy system的大小
ffffffffc020128e:	00007997          	auipc	s3,0x7
ffffffffc0201292:	d8a98993          	addi	s3,s3,-630 # ffffffffc0208018 <buddy>
    buddy.longest = tree;   // 设置二叉树数组指针
ffffffffc0201296:	00007517          	auipc	a0,0x7
ffffffffc020129a:	d9a50513          	addi	a0,a0,-614 # ffffffffc0208030 <tree.0>
    memset(tree, 0, sizeof(tree));  // 将数组所有元素初始化为0
ffffffffc020129e:	6611                	lui	a2,0x4
ffffffffc02012a0:	4581                	li	a1,0
    buddy.size = size;      // 设置buddy system的大小
ffffffffc02012a2:	0129a023          	sw	s2,0(s3)
    buddy.base = base;      // 设置内存基地址
ffffffffc02012a6:	0089b823          	sd	s0,16(s3)
    buddy.longest = tree;   // 设置二叉树数组指针
ffffffffc02012aa:	00a9b423          	sd	a0,8(s3)
    memset(tree, 0, sizeof(tree));  // 将数组所有元素初始化为0
ffffffffc02012ae:	32c010ef          	jal	ra,ffffffffc02025da <memset>
    unsigned node_size = size * 2;  // 初始节点大小为2倍总页面数
ffffffffc02012b2:	0019161b          	slliw	a2,s2,0x1
    for (int i = 0; i < 2 * size - 1; ++i) {  // 遍历所有节点
ffffffffc02012b6:	fff6059b          	addiw	a1,a2,-1
        buddy.longest[i] = node_size; // 设置节点的最大可用大小
ffffffffc02012ba:	0089b503          	ld	a0,8(s3)
ffffffffc02012be:	4781                	li	a5,0
ffffffffc02012c0:	86aa                	mv	a3,a0
        if (IS_POWER_OF_2(i + 1))   // 如果i+1是2的幂（即到达新的一层）
ffffffffc02012c2:	873e                	mv	a4,a5
ffffffffc02012c4:	2785                	addiw	a5,a5,1
ffffffffc02012c6:	8f7d                	and	a4,a4,a5
ffffffffc02012c8:	e319                	bnez	a4,ffffffffc02012ce <buddy_init_memmap+0x78>
            node_size /= 2;          // 节点大小减半
ffffffffc02012ca:	0016561b          	srliw	a2,a2,0x1
        buddy.longest[i] = node_size; // 设置节点的最大可用大小
ffffffffc02012ce:	c290                	sw	a2,0(a3)
    for (int i = 0; i < 2 * size - 1; ++i) {  // 遍历所有节点
ffffffffc02012d0:	0691                	addi	a3,a3,4
ffffffffc02012d2:	feb7e8e3          	bltu	a5,a1,ffffffffc02012c2 <buddy_init_memmap+0x6c>
    for (; p != base + n; p++) {  // 遍历所有实际页面
ffffffffc02012d6:	00249713          	slli	a4,s1,0x2
ffffffffc02012da:	9726                	add	a4,a4,s1
ffffffffc02012dc:	070e                	slli	a4,a4,0x3
ffffffffc02012de:	9722                	add	a4,a4,s0
        assert(PageReserved(p));  // 确保页面是保留状态
ffffffffc02012e0:	641c                	ld	a5,8(s0)
ffffffffc02012e2:	8b85                	andi	a5,a5,1
ffffffffc02012e4:	c3fd                	beqz	a5,ffffffffc02013ca <buddy_init_memmap+0x174>
        p->flags = p->property = 0;  // 清空页面标志和属性
ffffffffc02012e6:	00042823          	sw	zero,16(s0)
ffffffffc02012ea:	00043423          	sd	zero,8(s0)
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc02012ee:	00042023          	sw	zero,0(s0)
    for (; p != base + n; p++) {  // 遍历所有实际页面
ffffffffc02012f2:	02840413          	addi	s0,s0,40
ffffffffc02012f6:	fee415e3          	bne	s0,a4,ffffffffc02012e0 <buddy_init_memmap+0x8a>
    if (n < size) {         // 如果实际页面数小于调整后的2的幂
ffffffffc02012fa:	02091793          	slli	a5,s2,0x20
ffffffffc02012fe:	9381                	srli	a5,a5,0x20
ffffffffc0201300:	08f4f263          	bgeu	s1,a5,ffffffffc0201384 <buddy_init_memmap+0x12e>
        for (int i = size - 2; i >= 0; i--) {  // 从倒数第二层向上遍历
ffffffffc0201304:	ffe9059b          	addiw	a1,s2,-2
        for (unsigned i = n; i < size; i++) {  // 遍历超出范围的页面
ffffffffc0201308:	2481                	sext.w	s1,s1
        for (int i = size - 2; i >= 0; i--) {  // 从倒数第二层向上遍历
ffffffffc020130a:	87ae                	mv	a5,a1
        for (unsigned i = n; i < size; i++) {  // 遍历超出范围的页面
ffffffffc020130c:	0b24fc63          	bgeu	s1,s2,ffffffffc02013c4 <buddy_init_memmap+0x16e>
ffffffffc0201310:	fff4871b          	addiw	a4,s1,-1
ffffffffc0201314:	fff4c693          	not	a3,s1
ffffffffc0201318:	0127073b          	addw	a4,a4,s2
ffffffffc020131c:	012686bb          	addw	a3,a3,s2
ffffffffc0201320:	1702                	slli	a4,a4,0x20
ffffffffc0201322:	1682                	slli	a3,a3,0x20
ffffffffc0201324:	9301                	srli	a4,a4,0x20
ffffffffc0201326:	9281                	srli	a3,a3,0x20
ffffffffc0201328:	96ba                	add	a3,a3,a4
ffffffffc020132a:	00269613          	slli	a2,a3,0x2
ffffffffc020132e:	070a                	slli	a4,a4,0x2
ffffffffc0201330:	00450693          	addi	a3,a0,4
ffffffffc0201334:	972a                	add	a4,a4,a0
ffffffffc0201336:	96b2                	add	a3,a3,a2
            buddy.longest[index] = 0;         // 标记为不可用（大小为0）
ffffffffc0201338:	00072023          	sw	zero,0(a4)
        for (unsigned i = n; i < size; i++) {  // 遍历超出范围的页面
ffffffffc020133c:	0711                	addi	a4,a4,4
ffffffffc020133e:	fed71de3          	bne	a4,a3,ffffffffc0201338 <buddy_init_memmap+0xe2>
ffffffffc0201342:	0017979b          	slliw	a5,a5,0x1
ffffffffc0201346:	2785                	addiw	a5,a5,1
ffffffffc0201348:	078a                	slli	a5,a5,0x2
ffffffffc020134a:	00259693          	slli	a3,a1,0x2
ffffffffc020134e:	40b008b3          	neg	a7,a1
ffffffffc0201352:	397d                	addiw	s2,s2,-1
ffffffffc0201354:	97aa                	add	a5,a5,a0
ffffffffc0201356:	96aa                	add	a3,a3,a0
ffffffffc0201358:	088e                	slli	a7,a7,0x3
ffffffffc020135a:	090e                	slli	s2,s2,0x3
        for (int i = size - 2; i >= 0; i--) {  // 从倒数第二层向上遍历
ffffffffc020135c:	537d                	li	t1,-1
            unsigned right = buddy.longest[RIGHT_LEAF(i)]; // 右子节点大小
ffffffffc020135e:	01178733          	add	a4,a5,a7
ffffffffc0201362:	974a                	add	a4,a4,s2
            buddy.longest[i] = MAX(left, right);           // 父节点大小为子节点最大值
ffffffffc0201364:	4390                	lw	a2,0(a5)
ffffffffc0201366:	ffc72703          	lw	a4,-4(a4)
ffffffffc020136a:	0006051b          	sext.w	a0,a2
ffffffffc020136e:	0007081b          	sext.w	a6,a4
ffffffffc0201372:	00a87363          	bgeu	a6,a0,ffffffffc0201378 <buddy_init_memmap+0x122>
ffffffffc0201376:	8732                	mv	a4,a2
ffffffffc0201378:	c298                	sw	a4,0(a3)
        for (int i = size - 2; i >= 0; i--) {  // 从倒数第二层向上遍历
ffffffffc020137a:	35fd                	addiw	a1,a1,-1
ffffffffc020137c:	17e1                	addi	a5,a5,-8
ffffffffc020137e:	16f1                	addi	a3,a3,-4
ffffffffc0201380:	fc659fe3          	bne	a1,t1,ffffffffc020135e <buddy_init_memmap+0x108>
}
ffffffffc0201384:	70a2                	ld	ra,40(sp)
ffffffffc0201386:	7402                	ld	s0,32(sp)
ffffffffc0201388:	64e2                	ld	s1,24(sp)
ffffffffc020138a:	6942                	ld	s2,16(sp)
ffffffffc020138c:	69a2                	ld	s3,8(sp)
ffffffffc020138e:	6145                	addi	sp,sp,48
ffffffffc0201390:	8082                	ret
ffffffffc0201392:	0007091b          	sext.w	s2,a4
ffffffffc0201396:	bde5                	j	ffffffffc020128e <buddy_init_memmap+0x38>
    buddy.size = size;      // 设置buddy system的大小
ffffffffc0201398:	00007997          	auipc	s3,0x7
ffffffffc020139c:	c8098993          	addi	s3,s3,-896 # ffffffffc0208018 <buddy>
    buddy.longest = tree;   // 设置二叉树数组指针
ffffffffc02013a0:	00007517          	auipc	a0,0x7
ffffffffc02013a4:	c9050513          	addi	a0,a0,-880 # ffffffffc0208030 <tree.0>
    memset(tree, 0, sizeof(tree));  // 将数组所有元素初始化为0
ffffffffc02013a8:	6611                	lui	a2,0x4
ffffffffc02013aa:	4581                	li	a1,0
    buddy.size = size;      // 设置buddy system的大小
ffffffffc02013ac:	0099a023          	sw	s1,0(s3)
    buddy.base = base;      // 设置内存基地址
ffffffffc02013b0:	0089b823          	sd	s0,16(s3)
    buddy.longest = tree;   // 设置二叉树数组指针
ffffffffc02013b4:	00a9b423          	sd	a0,8(s3)
    memset(tree, 0, sizeof(tree));  // 将数组所有元素初始化为0
ffffffffc02013b8:	222010ef          	jal	ra,ffffffffc02025da <memset>
ffffffffc02013bc:	4905                	li	s2,1
    for (int i = 0; i < 2 * size - 1; ++i) {  // 遍历所有节点
ffffffffc02013be:	4585                	li	a1,1
    unsigned node_size = size * 2;  // 初始节点大小为2倍总页面数
ffffffffc02013c0:	4609                	li	a2,2
ffffffffc02013c2:	bde5                	j	ffffffffc02012ba <buddy_init_memmap+0x64>
        for (int i = size - 2; i >= 0; i--) {  // 从倒数第二层向上遍历
ffffffffc02013c4:	fc05c0e3          	bltz	a1,ffffffffc0201384 <buddy_init_memmap+0x12e>
ffffffffc02013c8:	bfad                	j	ffffffffc0201342 <buddy_init_memmap+0xec>
        assert(PageReserved(p));  // 确保页面是保留状态
ffffffffc02013ca:	00002697          	auipc	a3,0x2
ffffffffc02013ce:	22668693          	addi	a3,a3,550 # ffffffffc02035f0 <etext+0x1004>
ffffffffc02013d2:	00001617          	auipc	a2,0x1
ffffffffc02013d6:	4ce60613          	addi	a2,a2,1230 # ffffffffc02028a0 <etext+0x2b4>
ffffffffc02013da:	05d00593          	li	a1,93
ffffffffc02013de:	00001517          	auipc	a0,0x1
ffffffffc02013e2:	4da50513          	addi	a0,a0,1242 # ffffffffc02028b8 <etext+0x2cc>
ffffffffc02013e6:	dddfe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(n > 0);          // 确保页面数大于0
ffffffffc02013ea:	00001697          	auipc	a3,0x1
ffffffffc02013ee:	4ae68693          	addi	a3,a3,1198 # ffffffffc0202898 <etext+0x2ac>
ffffffffc02013f2:	00001617          	auipc	a2,0x1
ffffffffc02013f6:	4ae60613          	addi	a2,a2,1198 # ffffffffc02028a0 <etext+0x2b4>
ffffffffc02013fa:	03c00593          	li	a1,60
ffffffffc02013fe:	00001517          	auipc	a0,0x1
ffffffffc0201402:	4ba50513          	addi	a0,a0,1210 # ffffffffc02028b8 <etext+0x2cc>
ffffffffc0201406:	dbdfe0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc020140a <alloc_pages>:
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
    return pmm_manager->alloc_pages(n);  // 分配n个连续页
ffffffffc020140a:	0000b797          	auipc	a5,0xb
ffffffffc020140e:	e0e7b783          	ld	a5,-498(a5) # ffffffffc020c218 <pmm_manager>
ffffffffc0201412:	6f9c                	ld	a5,24(a5)
ffffffffc0201414:	8782                	jr	a5

ffffffffc0201416 <free_pages>:
}

// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    pmm_manager->free_pages(base, n);  // 释放n个连续页
ffffffffc0201416:	0000b797          	auipc	a5,0xb
ffffffffc020141a:	e027b783          	ld	a5,-510(a5) # ffffffffc020c218 <pmm_manager>
ffffffffc020141e:	739c                	ld	a5,32(a5)
ffffffffc0201420:	8782                	jr	a5

ffffffffc0201422 <pmm_init>:
    pmm_manager = &slub_pmm_manager;
ffffffffc0201422:	00003797          	auipc	a5,0x3
ffffffffc0201426:	a1e78793          	addi	a5,a5,-1506 # ffffffffc0203e40 <slub_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);  // 打印内存管理器名称
ffffffffc020142a:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);  // 初始化空闲内存映射
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc020142c:	7179                	addi	sp,sp,-48
ffffffffc020142e:	f022                	sd	s0,32(sp)
    cprintf("memory management: %s\n", pmm_manager->name);  // 打印内存管理器名称
ffffffffc0201430:	00002517          	auipc	a0,0x2
ffffffffc0201434:	22850513          	addi	a0,a0,552 # ffffffffc0203658 <buddy_system_pmm_manager+0x38>
    pmm_manager = &slub_pmm_manager;
ffffffffc0201438:	0000b417          	auipc	s0,0xb
ffffffffc020143c:	de040413          	addi	s0,s0,-544 # ffffffffc020c218 <pmm_manager>
void pmm_init(void) {
ffffffffc0201440:	f406                	sd	ra,40(sp)
ffffffffc0201442:	ec26                	sd	s1,24(sp)
ffffffffc0201444:	e44e                	sd	s3,8(sp)
ffffffffc0201446:	e84a                	sd	s2,16(sp)
ffffffffc0201448:	e052                	sd	s4,0(sp)
    pmm_manager = &slub_pmm_manager;
ffffffffc020144a:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);  // 打印内存管理器名称
ffffffffc020144c:	d01fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    pmm_manager->init();  // 初始化内存管理器
ffffffffc0201450:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;  // 设置虚拟地址到物理地址的偏移
ffffffffc0201452:	0000b497          	auipc	s1,0xb
ffffffffc0201456:	dde48493          	addi	s1,s1,-546 # ffffffffc020c230 <va_pa_offset>
    pmm_manager->init();  // 初始化内存管理器
ffffffffc020145a:	679c                	ld	a5,8(a5)
ffffffffc020145c:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;  // 设置虚拟地址到物理地址的偏移
ffffffffc020145e:	57f5                	li	a5,-3
ffffffffc0201460:	07fa                	slli	a5,a5,0x1e
ffffffffc0201462:	e09c                	sd	a5,0(s1)
    uint64_t mem_begin = get_memory_base();  // 获取内存起始地址（物理）
ffffffffc0201464:	958ff0ef          	jal	ra,ffffffffc02005bc <get_memory_base>
ffffffffc0201468:	89aa                	mv	s3,a0
    uint64_t mem_size  = get_memory_size();  // 获取内存大小（字节）
ffffffffc020146a:	95cff0ef          	jal	ra,ffffffffc02005c6 <get_memory_size>
    if (mem_size == 0) {
ffffffffc020146e:	14050d63          	beqz	a0,ffffffffc02015c8 <pmm_init+0x1a6>
    uint64_t mem_end   = mem_begin + mem_size;  // 计算内存结束地址
ffffffffc0201472:	892a                	mv	s2,a0
    cprintf("physcial memory map:\n");
ffffffffc0201474:	00002517          	auipc	a0,0x2
ffffffffc0201478:	22c50513          	addi	a0,a0,556 # ffffffffc02036a0 <buddy_system_pmm_manager+0x80>
ffffffffc020147c:	cd1fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;  // 计算内存结束地址
ffffffffc0201480:	01298a33          	add	s4,s3,s2
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc0201484:	864e                	mv	a2,s3
ffffffffc0201486:	fffa0693          	addi	a3,s4,-1
ffffffffc020148a:	85ca                	mv	a1,s2
ffffffffc020148c:	00002517          	auipc	a0,0x2
ffffffffc0201490:	22c50513          	addi	a0,a0,556 # ffffffffc02036b8 <buddy_system_pmm_manager+0x98>
ffffffffc0201494:	cb9fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    npage = maxpa / PGSIZE;  // 计算总页数
ffffffffc0201498:	c80007b7          	lui	a5,0xc8000
ffffffffc020149c:	8652                	mv	a2,s4
ffffffffc020149e:	0d47e463          	bltu	a5,s4,ffffffffc0201566 <pmm_init+0x144>
ffffffffc02014a2:	0000c797          	auipc	a5,0xc
ffffffffc02014a6:	d9578793          	addi	a5,a5,-619 # ffffffffc020d237 <end+0xfff>
ffffffffc02014aa:	757d                	lui	a0,0xfffff
ffffffffc02014ac:	8d7d                	and	a0,a0,a5
ffffffffc02014ae:	8231                	srli	a2,a2,0xc
ffffffffc02014b0:	0000b797          	auipc	a5,0xb
ffffffffc02014b4:	d4c7bc23          	sd	a2,-680(a5) # ffffffffc020c208 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);  // 页结构数组起始地址（页对齐）
ffffffffc02014b8:	0000b797          	auipc	a5,0xb
ffffffffc02014bc:	d4a7bc23          	sd	a0,-680(a5) # ffffffffc020c210 <pages>
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02014c0:	000807b7          	lui	a5,0x80
ffffffffc02014c4:	002005b7          	lui	a1,0x200
ffffffffc02014c8:	02f60563          	beq	a2,a5,ffffffffc02014f2 <pmm_init+0xd0>
ffffffffc02014cc:	00261593          	slli	a1,a2,0x2
ffffffffc02014d0:	00c586b3          	add	a3,a1,a2
ffffffffc02014d4:	fec007b7          	lui	a5,0xfec00
ffffffffc02014d8:	97aa                	add	a5,a5,a0
ffffffffc02014da:	068e                	slli	a3,a3,0x3
ffffffffc02014dc:	96be                	add	a3,a3,a5
ffffffffc02014de:	87aa                	mv	a5,a0
        SetPageReserved(pages + i);  // 标记所有页为保留状态
ffffffffc02014e0:	6798                	ld	a4,8(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02014e2:	02878793          	addi	a5,a5,40 # fffffffffec00028 <end+0x3e9f3df0>
        SetPageReserved(pages + i);  // 标记所有页为保留状态
ffffffffc02014e6:	00176713          	ori	a4,a4,1
ffffffffc02014ea:	fee7b023          	sd	a4,-32(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02014ee:	fef699e3          	bne	a3,a5,ffffffffc02014e0 <pmm_init+0xbe>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));  // 空闲内存起始地址
ffffffffc02014f2:	95b2                	add	a1,a1,a2
ffffffffc02014f4:	fec006b7          	lui	a3,0xfec00
ffffffffc02014f8:	96aa                	add	a3,a3,a0
ffffffffc02014fa:	058e                	slli	a1,a1,0x3
ffffffffc02014fc:	96ae                	add	a3,a3,a1
ffffffffc02014fe:	c02007b7          	lui	a5,0xc0200
ffffffffc0201502:	0af6e763          	bltu	a3,a5,ffffffffc02015b0 <pmm_init+0x18e>
ffffffffc0201506:	6098                	ld	a4,0(s1)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);  // 内存结束地址（页对齐）
ffffffffc0201508:	77fd                	lui	a5,0xfffff
ffffffffc020150a:	00fa75b3          	and	a1,s4,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));  // 空闲内存起始地址
ffffffffc020150e:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc0201510:	04b6ee63          	bltu	a3,a1,ffffffffc020156c <pmm_init+0x14a>
    satp_physical = PADDR(satp_virtual);          // 计算页表物理地址
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);  // 打印页表地址
}

static void check_alloc_page(void) {
    pmm_manager->check();  // 调用内存管理器的检查函数
ffffffffc0201514:	601c                	ld	a5,0(s0)
ffffffffc0201516:	7b9c                	ld	a5,48(a5)
ffffffffc0201518:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");  // 检查成功
ffffffffc020151a:	00002517          	auipc	a0,0x2
ffffffffc020151e:	22650513          	addi	a0,a0,550 # ffffffffc0203740 <buddy_system_pmm_manager+0x120>
ffffffffc0201522:	c2bfe0ef          	jal	ra,ffffffffc020014c <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;  // 设置页表虚拟地址
ffffffffc0201526:	00006597          	auipc	a1,0x6
ffffffffc020152a:	ada58593          	addi	a1,a1,-1318 # ffffffffc0207000 <boot_page_table_sv39>
ffffffffc020152e:	0000b797          	auipc	a5,0xb
ffffffffc0201532:	ceb7bd23          	sd	a1,-774(a5) # ffffffffc020c228 <satp_virtual>
    satp_physical = PADDR(satp_virtual);          // 计算页表物理地址
ffffffffc0201536:	c02007b7          	lui	a5,0xc0200
ffffffffc020153a:	0af5e363          	bltu	a1,a5,ffffffffc02015e0 <pmm_init+0x1be>
ffffffffc020153e:	6090                	ld	a2,0(s1)
}
ffffffffc0201540:	7402                	ld	s0,32(sp)
ffffffffc0201542:	70a2                	ld	ra,40(sp)
ffffffffc0201544:	64e2                	ld	s1,24(sp)
ffffffffc0201546:	6942                	ld	s2,16(sp)
ffffffffc0201548:	69a2                	ld	s3,8(sp)
ffffffffc020154a:	6a02                	ld	s4,0(sp)
    satp_physical = PADDR(satp_virtual);          // 计算页表物理地址
ffffffffc020154c:	40c58633          	sub	a2,a1,a2
ffffffffc0201550:	0000b797          	auipc	a5,0xb
ffffffffc0201554:	ccc7b823          	sd	a2,-816(a5) # ffffffffc020c220 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);  // 打印页表地址
ffffffffc0201558:	00002517          	auipc	a0,0x2
ffffffffc020155c:	20850513          	addi	a0,a0,520 # ffffffffc0203760 <buddy_system_pmm_manager+0x140>
}
ffffffffc0201560:	6145                	addi	sp,sp,48
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);  // 打印页表地址
ffffffffc0201562:	bebfe06f          	j	ffffffffc020014c <cprintf>
    npage = maxpa / PGSIZE;  // 计算总页数
ffffffffc0201566:	c8000637          	lui	a2,0xc8000
ffffffffc020156a:	bf25                	j	ffffffffc02014a2 <pmm_init+0x80>
    mem_begin = ROUNDUP(freemem, PGSIZE);  // 空闲内存起始地址（页对齐）
ffffffffc020156c:	6705                	lui	a4,0x1
ffffffffc020156e:	177d                	addi	a4,a4,-1
ffffffffc0201570:	96ba                	add	a3,a3,a4
ffffffffc0201572:	8efd                	and	a3,a3,a5
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0201574:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201578:	02c7f063          	bgeu	a5,a2,ffffffffc0201598 <pmm_init+0x176>
    pmm_manager->init_memmap(base, n);  // 初始化内存映射，构建空闲页结构
ffffffffc020157c:	6010                	ld	a2,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc020157e:	fff80737          	lui	a4,0xfff80
ffffffffc0201582:	973e                	add	a4,a4,a5
ffffffffc0201584:	00271793          	slli	a5,a4,0x2
ffffffffc0201588:	97ba                	add	a5,a5,a4
ffffffffc020158a:	6a18                	ld	a4,16(a2)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);  // 初始化空闲内存映射
ffffffffc020158c:	8d95                	sub	a1,a1,a3
ffffffffc020158e:	078e                	slli	a5,a5,0x3
    pmm_manager->init_memmap(base, n);  // 初始化内存映射，构建空闲页结构
ffffffffc0201590:	81b1                	srli	a1,a1,0xc
ffffffffc0201592:	953e                	add	a0,a0,a5
ffffffffc0201594:	9702                	jalr	a4
}
ffffffffc0201596:	bfbd                	j	ffffffffc0201514 <pmm_init+0xf2>
        panic("pa2page called with invalid pa");
ffffffffc0201598:	00002617          	auipc	a2,0x2
ffffffffc020159c:	17860613          	addi	a2,a2,376 # ffffffffc0203710 <buddy_system_pmm_manager+0xf0>
ffffffffc02015a0:	07100593          	li	a1,113
ffffffffc02015a4:	00002517          	auipc	a0,0x2
ffffffffc02015a8:	18c50513          	addi	a0,a0,396 # ffffffffc0203730 <buddy_system_pmm_manager+0x110>
ffffffffc02015ac:	c17fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));  // 空闲内存起始地址
ffffffffc02015b0:	00002617          	auipc	a2,0x2
ffffffffc02015b4:	13860613          	addi	a2,a2,312 # ffffffffc02036e8 <buddy_system_pmm_manager+0xc8>
ffffffffc02015b8:	06f00593          	li	a1,111
ffffffffc02015bc:	00002517          	auipc	a0,0x2
ffffffffc02015c0:	0d450513          	addi	a0,a0,212 # ffffffffc0203690 <buddy_system_pmm_manager+0x70>
ffffffffc02015c4:	bfffe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        panic("DTB memory info not available");  // 内存信息不可用
ffffffffc02015c8:	00002617          	auipc	a2,0x2
ffffffffc02015cc:	0a860613          	addi	a2,a2,168 # ffffffffc0203670 <buddy_system_pmm_manager+0x50>
ffffffffc02015d0:	04e00593          	li	a1,78
ffffffffc02015d4:	00002517          	auipc	a0,0x2
ffffffffc02015d8:	0bc50513          	addi	a0,a0,188 # ffffffffc0203690 <buddy_system_pmm_manager+0x70>
ffffffffc02015dc:	be7fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    satp_physical = PADDR(satp_virtual);          // 计算页表物理地址
ffffffffc02015e0:	86ae                	mv	a3,a1
ffffffffc02015e2:	00002617          	auipc	a2,0x2
ffffffffc02015e6:	10660613          	addi	a2,a2,262 # ffffffffc02036e8 <buddy_system_pmm_manager+0xc8>
ffffffffc02015ea:	08d00593          	li	a1,141
ffffffffc02015ee:	00002517          	auipc	a0,0x2
ffffffffc02015f2:	0a250513          	addi	a0,a0,162 # ffffffffc0203690 <buddy_system_pmm_manager+0x70>
ffffffffc02015f6:	bcdfe0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc02015fa <slub_init>:
    return NULL; // 超过 4096B 的对象不适用 SLUB（交给页级）
}

// 初始化所有 size 的 cache
static void slub_init_caches(void) {
    for (unsigned i = 0; i < SLUB_SIZE_CLASS_COUNT; i++) {
ffffffffc02015fa:	0000b797          	auipc	a5,0xb
ffffffffc02015fe:	a4678793          	addi	a5,a5,-1466 # ffffffffc020c040 <caches+0x10>
ffffffffc0201602:	00003617          	auipc	a2,0x3
ffffffffc0201606:	87660613          	addi	a2,a2,-1930 # ffffffffc0203e78 <slub_sizes>
ffffffffc020160a:	0000b817          	auipc	a6,0xb
ffffffffc020160e:	bf680813          	addi	a6,a6,-1034 # ffffffffc020c200 <memory_size>
    }
}

// 以下实现 pmm_manager 风格一致的接口，以便在 pmm.c 中切换到 SLUB

static void slub_init(void) {
ffffffffc0201612:	02000693          	li	a3,32
ffffffffc0201616:	00002517          	auipc	a0,0x2
ffffffffc020161a:	18a50513          	addi	a0,a0,394 # ffffffffc02037a0 <buddy_system_pmm_manager+0x180>
ffffffffc020161e:	a011                	j	ffffffffc0201622 <slub_init+0x28>
        caches[i].objsize = slub_sizes[i];
ffffffffc0201620:	4214                	lw	a3,0(a2)
        caches[i].slab_pages = (slub_sizes[i] == 2048) ? 2 : 1; // 2048B 使用双页 slab
ffffffffc0201622:	8006871b          	addiw	a4,a3,-2048
ffffffffc0201626:	00173713          	seqz	a4,a4
ffffffffc020162a:	01078593          	addi	a1,a5,16
ffffffffc020162e:	0705                	addi	a4,a4,1
        caches[i].objsize = slub_sizes[i];
ffffffffc0201630:	fed7ac23          	sw	a3,-8(a5)
        caches[i].name = "slub";
ffffffffc0201634:	fea7b823          	sd	a0,-16(a5)
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;  // 初始化节点，指向自己形成空链表
ffffffffc0201638:	e79c                	sd	a5,8(a5)
ffffffffc020163a:	e39c                	sd	a5,0(a5)
ffffffffc020163c:	ef8c                	sd	a1,24(a5)
ffffffffc020163e:	eb8c                	sd	a1,16(a5)
        caches[i].slab_pages = (slub_sizes[i] == 2048) ? 2 : 1; // 2048B 使用双页 slab
ffffffffc0201640:	d398                	sw	a4,32(a5)
    for (unsigned i = 0; i < SLUB_SIZE_CLASS_COUNT; i++) {
ffffffffc0201642:	03878793          	addi	a5,a5,56
ffffffffc0201646:	0611                	addi	a2,a2,4
ffffffffc0201648:	fd079ce3          	bne	a5,a6,ffffffffc0201620 <slub_init+0x26>
    // 初始化 SLUB 自己的数据结构
    slub_init_caches();
}
ffffffffc020164c:	8082                	ret

ffffffffc020164e <slub_init_memmap>:

static void slub_init_memmap(struct Page *base, size_t n) {
    // 交给 buddy 的 init_memmap，保证页级空间建立
    buddy_system_pmm_manager.init_memmap(base, n);
ffffffffc020164e:	00002797          	auipc	a5,0x2
ffffffffc0201652:	fe27b783          	ld	a5,-30(a5) # ffffffffc0203630 <buddy_system_pmm_manager+0x10>
ffffffffc0201656:	8782                	jr	a5

ffffffffc0201658 <slub_alloc_pages>:
// 分配 n 页：为了和 pmm 接口兼容，这里保留页级语义；
// 若用户通过对象接口分配（例如 alloc_pages(1) 但想要对象大小），我们提供一个“对象模式”的入口：
// 在测试和文档里会说明，调用 slub_alloc(size) 来拿对象；pmm 的 alloc_pages 仍表示页。
static struct Page *slub_alloc_pages(size_t n) {
    // 直接委托给 buddy 系统，保持页级分配行为
    return buddy_system_pmm_manager.alloc_pages(n);
ffffffffc0201658:	00002797          	auipc	a5,0x2
ffffffffc020165c:	fe07b783          	ld	a5,-32(a5) # ffffffffc0203638 <buddy_system_pmm_manager+0x18>
ffffffffc0201660:	8782                	jr	a5

ffffffffc0201662 <slub_free_pages>:
}

static void slub_free_pages(struct Page *base, size_t n) {
    // 直接委托给 buddy 系统，保持页级释放行为
    buddy_system_pmm_manager.free_pages(base, n);
ffffffffc0201662:	00002797          	auipc	a5,0x2
ffffffffc0201666:	fde7b783          	ld	a5,-34(a5) # ffffffffc0203640 <buddy_system_pmm_manager+0x20>
ffffffffc020166a:	8782                	jr	a5

ffffffffc020166c <slub_nr_free_pages>:
}

static size_t slub_nr_free_pages(void) {
    // 返回 buddy 的统计（页级）
    return buddy_system_pmm_manager.nr_free_pages();
ffffffffc020166c:	00002797          	auipc	a5,0x2
ffffffffc0201670:	fdc7b783          	ld	a5,-36(a5) # ffffffffc0203648 <buddy_system_pmm_manager+0x28>
ffffffffc0201674:	8782                	jr	a5

ffffffffc0201676 <slub_free>:
    for (unsigned i = 0; i < SLUB_SIZE_CLASS_COUNT; i++) {
ffffffffc0201676:	00003697          	auipc	a3,0x3
ffffffffc020167a:	80268693          	addi	a3,a3,-2046 # ffffffffc0203e78 <slub_sizes>
        list_add(&cache->slabs_partial, &slab->link);
    }
    // 当 slab 变为空，可以考虑回收页
}

static void slub_free(void *obj, size_t size) {
ffffffffc020167e:	02000793          	li	a5,32
    for (unsigned i = 0; i < SLUB_SIZE_CLASS_COUNT; i++) {
ffffffffc0201682:	4701                	li	a4,0
ffffffffc0201684:	4621                	li	a2,8
ffffffffc0201686:	a011                	j	ffffffffc020168a <slub_free+0x14>
        if (size <= slub_sizes[i]) return &caches[i];
ffffffffc0201688:	429c                	lw	a5,0(a3)
ffffffffc020168a:	1782                	slli	a5,a5,0x20
ffffffffc020168c:	9381                	srli	a5,a5,0x20
ffffffffc020168e:	00b7f763          	bgeu	a5,a1,ffffffffc020169c <slub_free+0x26>
    for (unsigned i = 0; i < SLUB_SIZE_CLASS_COUNT; i++) {
ffffffffc0201692:	2705                	addiw	a4,a4,1
ffffffffc0201694:	0691                	addi	a3,a3,4
ffffffffc0201696:	fec719e3          	bne	a4,a2,ffffffffc0201688 <slub_free+0x12>
            //cprintf("[SLUB][free] after list_add(partial)\n");
        }
    }

    //cprintf("[SLUB][free] exit\n");
}
ffffffffc020169a:	8082                	ret
    uintptr_t slab_base_pa = ROUNDDOWN(obj_pa, PGSIZE * cache->slab_pages);
ffffffffc020169c:	1702                	slli	a4,a4,0x20
ffffffffc020169e:	9301                	srli	a4,a4,0x20
ffffffffc02016a0:	00371693          	slli	a3,a4,0x3
ffffffffc02016a4:	8e99                	sub	a3,a3,a4
ffffffffc02016a6:	0000b597          	auipc	a1,0xb
ffffffffc02016aa:	98a58593          	addi	a1,a1,-1654 # ffffffffc020c030 <caches>
ffffffffc02016ae:	068e                	slli	a3,a3,0x3
ffffffffc02016b0:	96ae                	add	a3,a3,a1
ffffffffc02016b2:	5a90                	lw	a2,48(a3)
    uintptr_t obj_pa = (uintptr_t)obj - va_pa_offset;
ffffffffc02016b4:	0000b797          	auipc	a5,0xb
ffffffffc02016b8:	b7c7b783          	ld	a5,-1156(a5) # ffffffffc020c230 <va_pa_offset>
ffffffffc02016bc:	40f507b3          	sub	a5,a0,a5
    uintptr_t slab_base_pa = ROUNDDOWN(obj_pa, PGSIZE * cache->slab_pages);
ffffffffc02016c0:	00c6161b          	slliw	a2,a2,0xc
ffffffffc02016c4:	1602                	slli	a2,a2,0x20
ffffffffc02016c6:	9201                	srli	a2,a2,0x20
ffffffffc02016c8:	02c7f7b3          	remu	a5,a5,a2
    slub_slab_t *slab = (slub_slab_t *)(slab_base_pa + va_pa_offset);
ffffffffc02016cc:	40f507b3          	sub	a5,a0,a5
    if (slab->capacity == 0 || slab->objsize != cache->objsize) {
ffffffffc02016d0:	5b90                	lw	a2,48(a5)
ffffffffc02016d2:	c235                	beqz	a2,ffffffffc0201736 <slub_free+0xc0>
ffffffffc02016d4:	02c7a803          	lw	a6,44(a5)
ffffffffc02016d8:	4694                	lw	a3,8(a3)
ffffffffc02016da:	fcd810e3          	bne	a6,a3,ffffffffc020169a <slub_free+0x24>
 * Insert the new element @elm *after* the element @listelm which
 * is already in the list.
 * */
static inline void
list_add_after(list_entry_t *listelm, list_entry_t *elm) {
    __list_add(elm, listelm, listelm->next);  // 在指定节点后添加新节点
ffffffffc02016de:	0207b883          	ld	a7,32(a5)
    if (slab->inuse > 0) slab->inuse--;
ffffffffc02016e2:	0287a803          	lw	a6,40(a5)
    list_add(&slab->free_list, &node->link);
ffffffffc02016e6:	01878693          	addi	a3,a5,24
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;  // 在prev和next之间插入新节点elm
ffffffffc02016ea:	00a8b023          	sd	a0,0(a7)
ffffffffc02016ee:	f388                	sd	a0,32(a5)
    elm->next = next;               // 设置新节点的后继
ffffffffc02016f0:	01153423          	sd	a7,8(a0)
    elm->prev = prev;               // 设置新节点的前驱
ffffffffc02016f4:	e114                	sd	a3,0(a0)
    if (slab->inuse > 0) slab->inuse--;
ffffffffc02016f6:	04080163          	beqz	a6,ffffffffc0201738 <slub_free+0xc2>
ffffffffc02016fa:	fff8069b          	addiw	a3,a6,-1
ffffffffc02016fe:	d794                	sw	a3,40(a5)
    if (slab->inuse + 1 == slab->capacity) {
ffffffffc0201700:	f9061de3          	bne	a2,a6,ffffffffc020169a <slub_free+0x24>
        if (slab->link.prev == NULL || slab->link.next == NULL) {
ffffffffc0201704:	6790                	ld	a2,8(a5)
ffffffffc0201706:	da51                	beqz	a2,ffffffffc020169a <slub_free+0x24>
ffffffffc0201708:	6b88                	ld	a0,16(a5)
ffffffffc020170a:	d941                	beqz	a0,ffffffffc020169a <slub_free+0x24>
ffffffffc020170c:	00371693          	slli	a3,a4,0x3
ffffffffc0201710:	40e68733          	sub	a4,a3,a4
ffffffffc0201714:	070e                	slli	a4,a4,0x3
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;  // 前驱节点指向后继节点
ffffffffc0201716:	e608                	sd	a0,8(a2)
        if (size <= slub_sizes[i]) return &caches[i];
ffffffffc0201718:	00e58833          	add	a6,a1,a4
    __list_add(elm, listelm, listelm->next);  // 在指定节点后添加新节点
ffffffffc020171c:	01883683          	ld	a3,24(a6)
    next->prev = prev;  // 后继节点指向前驱节点
ffffffffc0201720:	e110                	sd	a2,0(a0)
            list_add(&cache->slabs_partial, &slab->link);
ffffffffc0201722:	00878613          	addi	a2,a5,8
    prev->next = next->prev = elm;  // 在prev和next之间插入新节点elm
ffffffffc0201726:	e290                	sd	a2,0(a3)
ffffffffc0201728:	0741                	addi	a4,a4,16
ffffffffc020172a:	00c83c23          	sd	a2,24(a6)
ffffffffc020172e:	95ba                	add	a1,a1,a4
    elm->next = next;               // 设置新节点的后继
ffffffffc0201730:	eb94                	sd	a3,16(a5)
    elm->prev = prev;               // 设置新节点的前驱
ffffffffc0201732:	e78c                	sd	a1,8(a5)
}
ffffffffc0201734:	8082                	ret
ffffffffc0201736:	8082                	ret
ffffffffc0201738:	4805                	li	a6,1
ffffffffc020173a:	b7d9                	j	ffffffffc0201700 <slub_free+0x8a>

ffffffffc020173c <slub_alloc>:
static void *slub_alloc(size_t size) {
ffffffffc020173c:	7139                	addi	sp,sp,-64
ffffffffc020173e:	fc06                	sd	ra,56(sp)
ffffffffc0201740:	f822                	sd	s0,48(sp)
ffffffffc0201742:	f426                	sd	s1,40(sp)
ffffffffc0201744:	f04a                	sd	s2,32(sp)
ffffffffc0201746:	ec4e                	sd	s3,24(sp)
ffffffffc0201748:	e852                	sd	s4,16(sp)
ffffffffc020174a:	e456                	sd	s5,8(sp)
ffffffffc020174c:	e05a                	sd	s6,0(sp)
ffffffffc020174e:	00002697          	auipc	a3,0x2
ffffffffc0201752:	72a68693          	addi	a3,a3,1834 # ffffffffc0203e78 <slub_sizes>
ffffffffc0201756:	02000793          	li	a5,32
    for (unsigned i = 0; i < SLUB_SIZE_CLASS_COUNT; i++) {
ffffffffc020175a:	4701                	li	a4,0
ffffffffc020175c:	4621                	li	a2,8
ffffffffc020175e:	a011                	j	ffffffffc0201762 <slub_alloc+0x26>
        if (size <= slub_sizes[i]) return &caches[i];
ffffffffc0201760:	429c                	lw	a5,0(a3)
ffffffffc0201762:	1782                	slli	a5,a5,0x20
ffffffffc0201764:	9381                	srli	a5,a5,0x20
ffffffffc0201766:	06a7f163          	bgeu	a5,a0,ffffffffc02017c8 <slub_alloc+0x8c>
    for (unsigned i = 0; i < SLUB_SIZE_CLASS_COUNT; i++) {
ffffffffc020176a:	2705                	addiw	a4,a4,1
ffffffffc020176c:	0691                	addi	a3,a3,4
ffffffffc020176e:	fec719e3          	bne	a4,a2,ffffffffc0201760 <slub_alloc+0x24>
        struct Page *pg = buddy_system_pmm_manager.alloc_pages((size + PGSIZE - 1)/PGSIZE);
ffffffffc0201772:	6785                	lui	a5,0x1
ffffffffc0201774:	17fd                	addi	a5,a5,-1
ffffffffc0201776:	953e                	add	a0,a0,a5
ffffffffc0201778:	8131                	srli	a0,a0,0xc
ffffffffc020177a:	00002797          	auipc	a5,0x2
ffffffffc020177e:	ebe7b783          	ld	a5,-322(a5) # ffffffffc0203638 <buddy_system_pmm_manager+0x18>
ffffffffc0201782:	9782                	jalr	a5
        if (!pg) return NULL;
ffffffffc0201784:	c955                	beqz	a0,ffffffffc0201838 <slub_alloc+0xfc>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201786:	0000b797          	auipc	a5,0xb
ffffffffc020178a:	a8a7b783          	ld	a5,-1398(a5) # ffffffffc020c210 <pages>
ffffffffc020178e:	8d1d                	sub	a0,a0,a5
ffffffffc0201790:	850d                	srai	a0,a0,0x3
ffffffffc0201792:	00003797          	auipc	a5,0x3
ffffffffc0201796:	94e7b783          	ld	a5,-1714(a5) # ffffffffc02040e0 <error_string+0x38>
ffffffffc020179a:	02f50533          	mul	a0,a0,a5
ffffffffc020179e:	00003797          	auipc	a5,0x3
ffffffffc02017a2:	94a7b783          	ld	a5,-1718(a5) # ffffffffc02040e8 <nbase>
ffffffffc02017a6:	953e                	add	a0,a0,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc02017a8:	0532                	slli	a0,a0,0xc
        return (void *)(page2pa(pg) + va_pa_offset);
ffffffffc02017aa:	0000b797          	auipc	a5,0xb
ffffffffc02017ae:	a867b783          	ld	a5,-1402(a5) # ffffffffc020c230 <va_pa_offset>
ffffffffc02017b2:	953e                	add	a0,a0,a5
}
ffffffffc02017b4:	70e2                	ld	ra,56(sp)
ffffffffc02017b6:	7442                	ld	s0,48(sp)
ffffffffc02017b8:	74a2                	ld	s1,40(sp)
ffffffffc02017ba:	7902                	ld	s2,32(sp)
ffffffffc02017bc:	69e2                	ld	s3,24(sp)
ffffffffc02017be:	6a42                	ld	s4,16(sp)
ffffffffc02017c0:	6aa2                	ld	s5,8(sp)
ffffffffc02017c2:	6b02                	ld	s6,0(sp)
ffffffffc02017c4:	6121                	addi	sp,sp,64
ffffffffc02017c6:	8082                	ret
    if (cache == NULL || cache->objsize == PGSIZE) {
ffffffffc02017c8:	1702                	slli	a4,a4,0x20
ffffffffc02017ca:	9301                	srli	a4,a4,0x20
ffffffffc02017cc:	00371413          	slli	s0,a4,0x3
ffffffffc02017d0:	8c19                	sub	s0,s0,a4
ffffffffc02017d2:	0000b917          	auipc	s2,0xb
ffffffffc02017d6:	85e90913          	addi	s2,s2,-1954 # ffffffffc020c030 <caches>
ffffffffc02017da:	040e                	slli	s0,s0,0x3
ffffffffc02017dc:	008909b3          	add	s3,s2,s0
ffffffffc02017e0:	0089a683          	lw	a3,8(s3)
ffffffffc02017e4:	6785                	lui	a5,0x1
ffffffffc02017e6:	f8f686e3          	beq	a3,a5,ffffffffc0201772 <slub_alloc+0x36>
    list_entry_t *le = &cache->slabs_partial;
ffffffffc02017ea:	01040793          	addi	a5,s0,16
ffffffffc02017ee:	97ca                	add	a5,a5,s2
ffffffffc02017f0:	84be                	mv	s1,a5
    return listelm->next;  // 获取下一个节点
ffffffffc02017f2:	6484                	ld	s1,8(s1)
    if (list_empty(&slab->free_list)) return NULL;
ffffffffc02017f4:	01048693          	addi	a3,s1,16
    while ((le = list_next(le)) != &cache->slabs_partial) {
ffffffffc02017f8:	04978263          	beq	a5,s1,ffffffffc020183c <slub_alloc+0x100>
    return list->next == list;  // 检查链表是否为空（指向自己）
ffffffffc02017fc:	6c88                	ld	a0,24(s1)
    if (list_empty(&slab->free_list)) return NULL;
ffffffffc02017fe:	fed50ae3          	beq	a0,a3,ffffffffc02017f2 <slub_alloc+0xb6>
    __list_del(listelm->prev, listelm->next);  // 从链表中删除节点
ffffffffc0201802:	6518                	ld	a4,8(a0)
ffffffffc0201804:	6114                	ld	a3,0(a0)
    slab->inuse++;
ffffffffc0201806:	509c                	lw	a5,32(s1)
            if (slab->inuse == slab->capacity) {
ffffffffc0201808:	5490                	lw	a2,40(s1)
    prev->next = next;  // 前驱节点指向后继节点
ffffffffc020180a:	e698                	sd	a4,8(a3)
    slab->inuse++;
ffffffffc020180c:	2785                	addiw	a5,a5,1
    next->prev = prev;  // 后继节点指向前驱节点
ffffffffc020180e:	e314                	sd	a3,0(a4)
ffffffffc0201810:	d09c                	sw	a5,32(s1)
ffffffffc0201812:	0007871b          	sext.w	a4,a5
            if (slab->inuse == slab->capacity) {
ffffffffc0201816:	f8e61fe3          	bne	a2,a4,ffffffffc02017b4 <slub_alloc+0x78>
    __list_del(listelm->prev, listelm->next);  // 从链表中删除节点
ffffffffc020181a:	6090                	ld	a2,0(s1)
ffffffffc020181c:	6494                	ld	a3,8(s1)
                list_add(&cache->slabs_full, &slab->link);
ffffffffc020181e:	02040793          	addi	a5,s0,32
ffffffffc0201822:	97ca                	add	a5,a5,s2
    prev->next = next;  // 前驱节点指向后继节点
ffffffffc0201824:	e614                	sd	a3,8(a2)
    __list_add(elm, listelm, listelm->next);  // 在指定节点后添加新节点
ffffffffc0201826:	0289b703          	ld	a4,40(s3)
    next->prev = prev;  // 后继节点指向前驱节点
ffffffffc020182a:	e290                	sd	a2,0(a3)
    prev->next = next->prev = elm;  // 在prev和next之间插入新节点elm
ffffffffc020182c:	e304                	sd	s1,0(a4)
ffffffffc020182e:	0299b423          	sd	s1,40(s3)
    elm->next = next;               // 设置新节点的后继
ffffffffc0201832:	e498                	sd	a4,8(s1)
    elm->prev = prev;               // 设置新节点的前驱
ffffffffc0201834:	e09c                	sd	a5,0(s1)
}
ffffffffc0201836:	bfbd                	j	ffffffffc02017b4 <slub_alloc+0x78>
        if (!pg) return NULL;
ffffffffc0201838:	4501                	li	a0,0
ffffffffc020183a:	bfad                	j	ffffffffc02017b4 <slub_alloc+0x78>
    struct Page *page = buddy_system_pmm_manager.alloc_pages(cache->slab_pages);
ffffffffc020183c:	00371a93          	slli	s5,a4,0x3
ffffffffc0201840:	40ea8733          	sub	a4,s5,a4
ffffffffc0201844:	00371a93          	slli	s5,a4,0x3
ffffffffc0201848:	9aca                	add	s5,s5,s2
ffffffffc020184a:	030ae503          	lwu	a0,48(s5)
ffffffffc020184e:	00002797          	auipc	a5,0x2
ffffffffc0201852:	dea7b783          	ld	a5,-534(a5) # ffffffffc0203638 <buddy_system_pmm_manager+0x18>
ffffffffc0201856:	9782                	jalr	a5
ffffffffc0201858:	8b2a                	mv	s6,a0
    if (page == NULL) return NULL;
ffffffffc020185a:	dd79                	beqz	a0,ffffffffc0201838 <slub_alloc+0xfc>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020185c:	0000b797          	auipc	a5,0xb
ffffffffc0201860:	9b47b783          	ld	a5,-1612(a5) # ffffffffc020c210 <pages>
ffffffffc0201864:	40f507b3          	sub	a5,a0,a5
ffffffffc0201868:	00003717          	auipc	a4,0x3
ffffffffc020186c:	87873703          	ld	a4,-1928(a4) # ffffffffc02040e0 <error_string+0x38>
ffffffffc0201870:	878d                	srai	a5,a5,0x3
ffffffffc0201872:	02e787b3          	mul	a5,a5,a4
    memset(page_va, 0, PGSIZE * cache->slab_pages); //清零整页内容。
ffffffffc0201876:	030aa603          	lw	a2,48(s5)
ffffffffc020187a:	00003a17          	auipc	s4,0x3
ffffffffc020187e:	86ea3a03          	ld	s4,-1938(s4) # ffffffffc02040e8 <nbase>
ffffffffc0201882:	4581                	li	a1,0
ffffffffc0201884:	00c6161b          	slliw	a2,a2,0xc
ffffffffc0201888:	1602                	slli	a2,a2,0x20
ffffffffc020188a:	9201                	srli	a2,a2,0x20
ffffffffc020188c:	9a3e                	add	s4,s4,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc020188e:	0a32                	slli	s4,s4,0xc
    void *page_va = (void *)(page2pa(page) + va_pa_offset); //用 page2pa + va_pa_offset = kva 拿到这块页的内核虚拟地址
ffffffffc0201890:	0000b797          	auipc	a5,0xb
ffffffffc0201894:	9a07b783          	ld	a5,-1632(a5) # ffffffffc020c230 <va_pa_offset>
ffffffffc0201898:	9a3e                	add	s4,s4,a5
    memset(page_va, 0, PGSIZE * cache->slab_pages); //清零整页内容。
ffffffffc020189a:	8552                	mv	a0,s4
ffffffffc020189c:	53f000ef          	jal	ra,ffffffffc02025da <memset>
    list_init(&slab->link);
ffffffffc02018a0:	008a0313          	addi	t1,s4,8
    list_init(&slab->free_list);
ffffffffc02018a4:	018a0593          	addi	a1,s4,24
    elm->prev = elm->next = elm;  // 初始化节点，指向自己形成空链表
ffffffffc02018a8:	006a3823          	sd	t1,16(s4)
ffffffffc02018ac:	006a3423          	sd	t1,8(s4)
ffffffffc02018b0:	02ba3023          	sd	a1,32(s4)
ffffffffc02018b4:	00ba3c23          	sd	a1,24(s4)
    unsigned total = PGSIZE * cache->slab_pages;
ffffffffc02018b8:	030aa783          	lw	a5,48(s5)
    slab->objsize = cache->objsize;
ffffffffc02018bc:	008aa883          	lw	a7,8(s5)
    slab->page = page;            //把 slub_slab_t 元数据直接放在 slab 页的开头(真实 Linux SLUB 把元数据放其它地方)
ffffffffc02018c0:	016a3023          	sd	s6,0(s4)
    unsigned total = PGSIZE * cache->slab_pages;
ffffffffc02018c4:	00c7979b          	slliw	a5,a5,0xc
    unsigned usable = total - sizeof(slub_slab_t);
ffffffffc02018c8:	fc87879b          	addiw	a5,a5,-56
    slab->capacity = usable / cache->objsize;       //刚刚写错的函数在这重写了一边，考虑元数据占的空间，向下整除
ffffffffc02018cc:	0317d83b          	divuw	a6,a5,a7
    slab->inuse = 0;
ffffffffc02018d0:	020a2423          	sw	zero,40(s4)
    slab->objsize = cache->objsize;
ffffffffc02018d4:	031a2623          	sw	a7,44(s4)
    slab->capacity = usable / cache->objsize;       //刚刚写错的函数在这重写了一边，考虑元数据占的空间，向下整除
ffffffffc02018d8:	030a2823          	sw	a6,48(s4)
    for (unsigned i = 0; i < slab->capacity; i++) {
ffffffffc02018dc:	0317e863          	bltu	a5,a7,ffffffffc020190c <slub_alloc+0x1d0>
ffffffffc02018e0:	862e                	mv	a2,a1
ffffffffc02018e2:	4681                	li	a3,0
ffffffffc02018e4:	4701                	li	a4,0
ffffffffc02018e6:	a019                	j	ffffffffc02018ec <slub_alloc+0x1b0>
    __list_add(elm, listelm, listelm->next);  // 在指定节点后添加新节点
ffffffffc02018e8:	020a3603          	ld	a2,32(s4)
        obj_node_t *node = (obj_node_t *)(obj_base + i * cache->objsize);
ffffffffc02018ec:	02069793          	slli	a5,a3,0x20
ffffffffc02018f0:	9381                	srli	a5,a5,0x20
ffffffffc02018f2:	03878793          	addi	a5,a5,56
ffffffffc02018f6:	97d2                	add	a5,a5,s4
    prev->next = next->prev = elm;  // 在prev和next之间插入新节点elm
ffffffffc02018f8:	e21c                	sd	a5,0(a2)
ffffffffc02018fa:	02fa3023          	sd	a5,32(s4)
    elm->next = next;               // 设置新节点的后继
ffffffffc02018fe:	e790                	sd	a2,8(a5)
    elm->prev = prev;               // 设置新节点的前驱
ffffffffc0201900:	e38c                	sd	a1,0(a5)
    for (unsigned i = 0; i < slab->capacity; i++) {
ffffffffc0201902:	2705                	addiw	a4,a4,1
ffffffffc0201904:	00d886bb          	addw	a3,a7,a3
ffffffffc0201908:	ff0760e3          	bltu	a4,a6,ffffffffc02018e8 <slub_alloc+0x1ac>
    __list_add(elm, listelm, listelm->next);  // 在指定节点后添加新节点
ffffffffc020190c:	0189b783          	ld	a5,24(s3)
    prev->next = next->prev = elm;  // 在prev和next之间插入新节点elm
ffffffffc0201910:	0067b023          	sd	t1,0(a5)
ffffffffc0201914:	0069bc23          	sd	t1,24(s3)
    return list->next == list;  // 检查链表是否为空（指向自己）
ffffffffc0201918:	020a3503          	ld	a0,32(s4)
    elm->next = next;               // 设置新节点的后继
ffffffffc020191c:	00fa3823          	sd	a5,16(s4)
    elm->prev = prev;               // 设置新节点的前驱
ffffffffc0201920:	009a3423          	sd	s1,8(s4)
    if (list_empty(&slab->free_list)) return NULL;
ffffffffc0201924:	f0b50ae3          	beq	a0,a1,ffffffffc0201838 <slub_alloc+0xfc>
    __list_del(listelm->prev, listelm->next);  // 从链表中删除节点
ffffffffc0201928:	6114                	ld	a3,0(a0)
ffffffffc020192a:	6518                	ld	a4,8(a0)
    slab->inuse++;
ffffffffc020192c:	4785                	li	a5,1
    prev->next = next;  // 前驱节点指向后继节点
ffffffffc020192e:	e698                	sd	a4,8(a3)
    next->prev = prev;  // 后继节点指向前驱节点
ffffffffc0201930:	e314                	sd	a3,0(a4)
ffffffffc0201932:	02fa2423          	sw	a5,40(s4)
    if (slab->inuse == slab->capacity) {
ffffffffc0201936:	e6f81fe3          	bne	a6,a5,ffffffffc02017b4 <slub_alloc+0x78>
    __list_del(listelm->prev, listelm->next);  // 从链表中删除节点
ffffffffc020193a:	008a3603          	ld	a2,8(s4)
ffffffffc020193e:	010a3683          	ld	a3,16(s4)
        list_add(&cache->slabs_full, &slab->link);
ffffffffc0201942:	02040413          	addi	s0,s0,32
ffffffffc0201946:	008907b3          	add	a5,s2,s0
    prev->next = next;  // 前驱节点指向后继节点
ffffffffc020194a:	e614                	sd	a3,8(a2)
    __list_add(elm, listelm, listelm->next);  // 在指定节点后添加新节点
ffffffffc020194c:	0289b703          	ld	a4,40(s3)
    next->prev = prev;  // 后继节点指向前驱节点
ffffffffc0201950:	e290                	sd	a2,0(a3)
    prev->next = next->prev = elm;  // 在prev和next之间插入新节点elm
ffffffffc0201952:	00673023          	sd	t1,0(a4)
ffffffffc0201956:	0269b423          	sd	t1,40(s3)
    elm->next = next;               // 设置新节点的后继
ffffffffc020195a:	00ea3823          	sd	a4,16(s4)
    elm->prev = prev;               // 设置新节点的前驱
ffffffffc020195e:	00fa3423          	sd	a5,8(s4)
}
ffffffffc0201962:	bd89                	j	ffffffffc02017b4 <slub_alloc+0x78>

ffffffffc0201964 <slub_check>:
    slub_free_pages(big, 2);

    cprintf("slub_check() completed.\n");
}

static void slub_check(void) {
ffffffffc0201964:	7151                	addi	sp,sp,-240
ffffffffc0201966:	f1a2                	sd	s0,224(sp)
ffffffffc0201968:	e1d2                	sd	s4,192(sp)
ffffffffc020196a:	1980                	addi	s0,sp,240
ffffffffc020196c:	f586                	sd	ra,232(sp)
ffffffffc020196e:	eda6                	sd	s1,216(sp)
ffffffffc0201970:	e9ca                	sd	s2,208(sp)
ffffffffc0201972:	e5ce                	sd	s3,200(sp)
ffffffffc0201974:	fd56                	sd	s5,184(sp)
ffffffffc0201976:	f95a                	sd	s6,176(sp)
ffffffffc0201978:	f55e                	sd	s7,168(sp)
ffffffffc020197a:	f162                	sd	s8,160(sp)
ffffffffc020197c:	ed66                	sd	s9,152(sp)
ffffffffc020197e:	e96a                	sd	s10,144(sp)
ffffffffc0201980:	e56e                	sd	s11,136(sp)
    cprintf("[SLUB] === slub_check() begin ===\n");
ffffffffc0201982:	00002517          	auipc	a0,0x2
ffffffffc0201986:	e2650513          	addi	a0,a0,-474 # ffffffffc02037a8 <buddy_system_pmm_manager+0x188>
ffffffffc020198a:	fc2fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    assert((p0 = buddy_system_pmm_manager.alloc_pages(1)) != NULL);
ffffffffc020198e:	00002a17          	auipc	s4,0x2
ffffffffc0201992:	c92a0a13          	addi	s4,s4,-878 # ffffffffc0203620 <buddy_system_pmm_manager>
ffffffffc0201996:	018a3783          	ld	a5,24(s4)
ffffffffc020199a:	4505                	li	a0,1
ffffffffc020199c:	f0f43c23          	sd	a5,-232(s0)
ffffffffc02019a0:	9782                	jalr	a5
ffffffffc02019a2:	70050f63          	beqz	a0,ffffffffc02020c0 <slub_check+0x75c>
    assert((p1 = buddy_system_pmm_manager.alloc_pages(1)) != NULL);
ffffffffc02019a6:	f1843783          	ld	a5,-232(s0)
ffffffffc02019aa:	89aa                	mv	s3,a0
ffffffffc02019ac:	4505                	li	a0,1
ffffffffc02019ae:	9782                	jalr	a5
ffffffffc02019b0:	892a                	mv	s2,a0
ffffffffc02019b2:	6e050763          	beqz	a0,ffffffffc02020a0 <slub_check+0x73c>
    assert((p2 = buddy_system_pmm_manager.alloc_pages(1)) != NULL);
ffffffffc02019b6:	f1843783          	ld	a5,-232(s0)
ffffffffc02019ba:	4505                	li	a0,1
ffffffffc02019bc:	9782                	jalr	a5
ffffffffc02019be:	84aa                	mv	s1,a0
ffffffffc02019c0:	76050c63          	beqz	a0,ffffffffc0202138 <slub_check+0x7d4>
    buddy_system_pmm_manager.free_pages(p0, 1);
ffffffffc02019c4:	020a3783          	ld	a5,32(s4)
ffffffffc02019c8:	854e                	mv	a0,s3
ffffffffc02019ca:	4585                	li	a1,1
ffffffffc02019cc:	f2f43823          	sd	a5,-208(s0)
ffffffffc02019d0:	89be                	mv	s3,a5
ffffffffc02019d2:	9782                	jalr	a5
    buddy_system_pmm_manager.free_pages(p1, 1);
ffffffffc02019d4:	4585                	li	a1,1
ffffffffc02019d6:	854a                	mv	a0,s2
ffffffffc02019d8:	9982                	jalr	s3
    buddy_system_pmm_manager.free_pages(p2, 1);
ffffffffc02019da:	4585                	li	a1,1
ffffffffc02019dc:	8526                	mv	a0,s1
ffffffffc02019de:	9982                	jalr	s3

    basic_check();
    cprintf("[SLUB] basic_check() passed.\n");
ffffffffc02019e0:	00002517          	auipc	a0,0x2
ffffffffc02019e4:	eb050513          	addi	a0,a0,-336 # ffffffffc0203890 <buddy_system_pmm_manager+0x270>
ffffffffc02019e8:	f64fe0ef          	jal	ra,ffffffffc020014c <cprintf>

    size_t sizes[] = {32,64,128,256,512,1024,2048,4096};
ffffffffc02019ec:	00002797          	auipc	a5,0x2
ffffffffc02019f0:	41478793          	addi	a5,a5,1044 # ffffffffc0203e00 <buddy_system_pmm_manager+0x7e0>
ffffffffc02019f4:	0007b883          	ld	a7,0(a5)
ffffffffc02019f8:	0087b803          	ld	a6,8(a5)
ffffffffc02019fc:	6b88                	ld	a0,16(a5)
ffffffffc02019fe:	6f8c                	ld	a1,24(a5)
ffffffffc0201a00:	7390                	ld	a2,32(a5)
ffffffffc0201a02:	7794                	ld	a3,40(a5)
ffffffffc0201a04:	7b98                	ld	a4,48(a5)
ffffffffc0201a06:	7f9c                	ld	a5,56(a5)
ffffffffc0201a08:	f5143823          	sd	a7,-176(s0)
ffffffffc0201a0c:	f5043c23          	sd	a6,-168(s0)
ffffffffc0201a10:	f8f43423          	sd	a5,-120(s0)
    for (int si = 0; si < (int)(sizeof(sizes)/sizeof(sizes[0])); si++) {
ffffffffc0201a14:	f5040793          	addi	a5,s0,-176
    size_t sizes[] = {32,64,128,256,512,1024,2048,4096};
ffffffffc0201a18:	f6a43023          	sd	a0,-160(s0)
ffffffffc0201a1c:	f6b43423          	sd	a1,-152(s0)
ffffffffc0201a20:	f6c43823          	sd	a2,-144(s0)
ffffffffc0201a24:	f6d43c23          	sd	a3,-136(s0)
ffffffffc0201a28:	f8e43023          	sd	a4,-128(s0)
ffffffffc0201a2c:	f4f43423          	sd	a5,-184(s0)
    for (unsigned i = 0; i < SLUB_SIZE_CLASS_COUNT; i++) {
ffffffffc0201a30:	4b21                	li	s6,8
        kmem_cache_t *cache = slub_select_cache(sizes[si]);
        assert(cache != NULL);
        cprintf("[SLUB] size=%u selected cache: objsize=%u, slab_pages=%u\n",
ffffffffc0201a32:	0000ac17          	auipc	s8,0xa
ffffffffc0201a36:	5fec0c13          	addi	s8,s8,1534 # ffffffffc020c030 <caches>
        cprintf("[SLUB] new cache test for size=%u begin\n", (unsigned)sizes[si]);

        // 新建一个 slab：分配到第一个对象时，partial 应为 1
        void *first = slub_alloc(sizes[si]);
        assert(first != NULL);
        cprintf("[SLUB] first alloc: va=%lx pa=%lx page_pa=%lx | partial=%d full=%d\n",
ffffffffc0201a3a:	0000ac97          	auipc	s9,0xa
ffffffffc0201a3e:	7f6c8c93          	addi	s9,s9,2038 # ffffffffc020c230 <va_pa_offset>
        kmem_cache_t *cache = slub_select_cache(sizes[si]);
ffffffffc0201a42:	f4843783          	ld	a5,-184(s0)
ffffffffc0201a46:	00002717          	auipc	a4,0x2
ffffffffc0201a4a:	43270713          	addi	a4,a4,1074 # ffffffffc0203e78 <slub_sizes>
    for (unsigned i = 0; i < SLUB_SIZE_CLASS_COUNT; i++) {
ffffffffc0201a4e:	4481                	li	s1,0
        kmem_cache_t *cache = slub_select_cache(sizes[si]);
ffffffffc0201a50:	0007b903          	ld	s2,0(a5)
ffffffffc0201a54:	02000793          	li	a5,32
ffffffffc0201a58:	a011                	j	ffffffffc0201a5c <slub_check+0xf8>
        if (size <= slub_sizes[i]) return &caches[i];
ffffffffc0201a5a:	431c                	lw	a5,0(a4)
ffffffffc0201a5c:	1782                	slli	a5,a5,0x20
ffffffffc0201a5e:	9381                	srli	a5,a5,0x20
ffffffffc0201a60:	0327f663          	bgeu	a5,s2,ffffffffc0201a8c <slub_check+0x128>
    for (unsigned i = 0; i < SLUB_SIZE_CLASS_COUNT; i++) {
ffffffffc0201a64:	2485                	addiw	s1,s1,1
ffffffffc0201a66:	0711                	addi	a4,a4,4
ffffffffc0201a68:	ff6499e3          	bne	s1,s6,ffffffffc0201a5a <slub_check+0xf6>
        assert(cache != NULL);
ffffffffc0201a6c:	00002697          	auipc	a3,0x2
ffffffffc0201a70:	36c68693          	addi	a3,a3,876 # ffffffffc0203dd8 <buddy_system_pmm_manager+0x7b8>
ffffffffc0201a74:	00001617          	auipc	a2,0x1
ffffffffc0201a78:	e2c60613          	addi	a2,a2,-468 # ffffffffc02028a0 <etext+0x2b4>
ffffffffc0201a7c:	16d00593          	li	a1,365
ffffffffc0201a80:	00002517          	auipc	a0,0x2
ffffffffc0201a84:	d8850513          	addi	a0,a0,-632 # ffffffffc0203808 <buddy_system_pmm_manager+0x1e8>
ffffffffc0201a88:	f3afe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        cprintf("[SLUB] size=%u selected cache: objsize=%u, slab_pages=%u\n",
ffffffffc0201a8c:	1482                	slli	s1,s1,0x20
ffffffffc0201a8e:	9081                	srli	s1,s1,0x20
ffffffffc0201a90:	00349a13          	slli	s4,s1,0x3
ffffffffc0201a94:	409a0a33          	sub	s4,s4,s1
ffffffffc0201a98:	0a0e                	slli	s4,s4,0x3
ffffffffc0201a9a:	014c09b3          	add	s3,s8,s4
ffffffffc0201a9e:	0309a683          	lw	a3,48(s3)
ffffffffc0201aa2:	0089a603          	lw	a2,8(s3)
ffffffffc0201aa6:	0009079b          	sext.w	a5,s2
ffffffffc0201aaa:	85be                	mv	a1,a5
ffffffffc0201aac:	00002517          	auipc	a0,0x2
ffffffffc0201ab0:	e0450513          	addi	a0,a0,-508 # ffffffffc02038b0 <buddy_system_pmm_manager+0x290>
ffffffffc0201ab4:	f2f43c23          	sd	a5,-200(s0)
ffffffffc0201ab8:	e94fe0ef          	jal	ra,ffffffffc020014c <cprintf>
        if (cache->objsize == PGSIZE) {
ffffffffc0201abc:	0089a703          	lw	a4,8(s3)
ffffffffc0201ac0:	6785                	lui	a5,0x1
ffffffffc0201ac2:	24f71863          	bne	a4,a5,ffffffffc0201d12 <slub_check+0x3ae>
            cprintf("[SLUB] 4096B special case test begin\n");
ffffffffc0201ac6:	00002517          	auipc	a0,0x2
ffffffffc0201aca:	e2a50513          	addi	a0,a0,-470 # ffffffffc02038f0 <buddy_system_pmm_manager+0x2d0>
ffffffffc0201ace:	e7efe0ef          	jal	ra,ffffffffc020014c <cprintf>
            void *ptr = slub_alloc(sizes[si]);
ffffffffc0201ad2:	854a                	mv	a0,s2
ffffffffc0201ad4:	c69ff0ef          	jal	ra,ffffffffc020173c <slub_alloc>
ffffffffc0201ad8:	85aa                	mv	a1,a0
            assert(ptr != NULL);
ffffffffc0201ada:	5a050363          	beqz	a0,ffffffffc0202080 <slub_check+0x71c>
            uintptr_t page_pa = ROUNDDOWN((uintptr_t)ptr - va_pa_offset, PGSIZE);
ffffffffc0201ade:	000cb603          	ld	a2,0(s9)
    if (PPN(pa) >= npage) {
ffffffffc0201ae2:	0000a797          	auipc	a5,0xa
ffffffffc0201ae6:	72678793          	addi	a5,a5,1830 # ffffffffc020c208 <npage>
ffffffffc0201aea:	6398                	ld	a4,0(a5)
ffffffffc0201aec:	40c50633          	sub	a2,a0,a2
ffffffffc0201af0:	77fd                	lui	a5,0xfffff
ffffffffc0201af2:	00f676b3          	and	a3,a2,a5
ffffffffc0201af6:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201afa:	62e7f363          	bgeu	a5,a4,ffffffffc0202120 <slub_check+0x7bc>
    return &pages[PPN(pa) - nbase];
ffffffffc0201afe:	00002717          	auipc	a4,0x2
ffffffffc0201b02:	5ea73703          	ld	a4,1514(a4) # ffffffffc02040e8 <nbase>
ffffffffc0201b06:	40e78733          	sub	a4,a5,a4
ffffffffc0201b0a:	00271793          	slli	a5,a4,0x2
ffffffffc0201b0e:	97ba                	add	a5,a5,a4
ffffffffc0201b10:	078e                	slli	a5,a5,0x3
ffffffffc0201b12:	0000a497          	auipc	s1,0xa
ffffffffc0201b16:	6fe4b483          	ld	s1,1790(s1) # ffffffffc020c210 <pages>
            cprintf("[SLUB] 4096B alloc: va=%lx pa=%lx page_pa=%lx\n",
ffffffffc0201b1a:	00002517          	auipc	a0,0x2
ffffffffc0201b1e:	e0e50513          	addi	a0,a0,-498 # ffffffffc0203928 <buddy_system_pmm_manager+0x308>
ffffffffc0201b22:	94be                	add	s1,s1,a5
ffffffffc0201b24:	e28fe0ef          	jal	ra,ffffffffc020014c <cprintf>
            buddy_system_pmm_manager.free_pages(pg, 1);
ffffffffc0201b28:	f3043783          	ld	a5,-208(s0)
ffffffffc0201b2c:	8526                	mv	a0,s1
ffffffffc0201b2e:	4585                	li	a1,1
ffffffffc0201b30:	9782                	jalr	a5
            cprintf("[SLUB] 4096B free done\n");
ffffffffc0201b32:	00002517          	auipc	a0,0x2
ffffffffc0201b36:	e2650513          	addi	a0,a0,-474 # ffffffffc0203958 <buddy_system_pmm_manager+0x338>
ffffffffc0201b3a:	e12fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    for (int si = 0; si < (int)(sizeof(sizes)/sizeof(sizes[0])); si++) {
ffffffffc0201b3e:	f4843783          	ld	a5,-184(s0)
ffffffffc0201b42:	f9040713          	addi	a4,s0,-112
ffffffffc0201b46:	07a1                	addi	a5,a5,8
ffffffffc0201b48:	f4f43423          	sd	a5,-184(s0)
ffffffffc0201b4c:	eef71be3          	bne	a4,a5,ffffffffc0201a42 <slub_check+0xde>
        assert(pc >= 1);
        cprintf("[SLUB] size=%u test done.\n", (unsigned)sizes[si]);
    }

    // 大量 64B 对象分配与释放，验证复用
    cprintf("[SLUB] bulk alloc/free reuse test (size=64B)\n");
ffffffffc0201b50:	00002517          	auipc	a0,0x2
ffffffffc0201b54:	0a850513          	addi	a0,a0,168 # ffffffffc0203bf8 <buddy_system_pmm_manager+0x5d8>
ffffffffc0201b58:	df4fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    const int N = 1024;
    void *arr[N];
ffffffffc0201b5c:	77f9                	lui	a5,0xffffe
ffffffffc0201b5e:	913e                	add	sp,sp,a5
ffffffffc0201b60:	890a                	mv	s2,sp
    for (int i = 0; i < N; i++) {
ffffffffc0201b62:	84ca                	mv	s1,s2
    void *arr[N];
ffffffffc0201b64:	8d4a                	mv	s10,s2
    for (int i = 0; i < N; i++) {
ffffffffc0201b66:	4b81                	li	s7,0
        arr[i] = slub_alloc(64);
        assert(arr[i] != NULL);
        if (i < 5) {
ffffffffc0201b68:	4991                	li	s3,4
    for (int i = 0; i < N; i++) {
ffffffffc0201b6a:	40000a13          	li	s4,1024
            uintptr_t pa = (uintptr_t)arr[i] - va_pa_offset;
            cprintf("[SLUB] arr[%d]: va=%lx pa=%lx page_pa=%lx\n",
                    i, (uintptr_t)arr[i], pa, ROUNDDOWN(pa, PGSIZE));
ffffffffc0201b6e:	7b7d                	lui	s6,0xfffff
            cprintf("[SLUB] arr[%d]: va=%lx pa=%lx page_pa=%lx\n",
ffffffffc0201b70:	00002a97          	auipc	s5,0x2
ffffffffc0201b74:	0c8a8a93          	addi	s5,s5,200 # ffffffffc0203c38 <buddy_system_pmm_manager+0x618>
ffffffffc0201b78:	a019                	j	ffffffffc0201b7e <slub_check+0x21a>
ffffffffc0201b7a:	0d21                	addi	s10,s10,8
    for (int i = 0; i < N; i++) {
ffffffffc0201b7c:	8bee                	mv	s7,s11
        arr[i] = slub_alloc(64);
ffffffffc0201b7e:	04000513          	li	a0,64
ffffffffc0201b82:	bbbff0ef          	jal	ra,ffffffffc020173c <slub_alloc>
ffffffffc0201b86:	00ad3023          	sd	a0,0(s10)
        assert(arr[i] != NULL);
ffffffffc0201b8a:	48050b63          	beqz	a0,ffffffffc0202020 <slub_check+0x6bc>
    for (int i = 0; i < N; i++) {
ffffffffc0201b8e:	001b8d9b          	addiw	s11,s7,1
        if (i < 5) {
ffffffffc0201b92:	3f79f563          	bgeu	s3,s7,ffffffffc0201f7c <slub_check+0x618>
    for (int i = 0; i < N; i++) {
ffffffffc0201b96:	ff4d92e3          	bne	s11,s4,ffffffffc0201b7a <slub_check+0x216>
    return listelm->next;  // 获取下一个节点
ffffffffc0201b9a:	050c3783          	ld	a5,80(s8)
    while ((le = list_next(le)) != head) cnt++;
ffffffffc0201b9e:	0000aa17          	auipc	s4,0xa
ffffffffc0201ba2:	4daa0a13          	addi	s4,s4,1242 # ffffffffc020c078 <caches+0x48>
    int cnt = 0;
ffffffffc0201ba6:	4581                	li	a1,0
    while ((le = list_next(le)) != head) cnt++;
ffffffffc0201ba8:	01478663          	beq	a5,s4,ffffffffc0201bb4 <slub_check+0x250>
ffffffffc0201bac:	679c                	ld	a5,8(a5)
ffffffffc0201bae:	2585                	addiw	a1,a1,1
ffffffffc0201bb0:	ff479ee3          	bne	a5,s4,ffffffffc0201bac <slub_check+0x248>
ffffffffc0201bb4:	060c3783          	ld	a5,96(s8)
ffffffffc0201bb8:	0000a997          	auipc	s3,0xa
ffffffffc0201bbc:	4d098993          	addi	s3,s3,1232 # ffffffffc020c088 <caches+0x58>
    int cnt = 0;
ffffffffc0201bc0:	4601                	li	a2,0
    while ((le = list_next(le)) != head) cnt++;
ffffffffc0201bc2:	01378663          	beq	a5,s3,ffffffffc0201bce <slub_check+0x26a>
ffffffffc0201bc6:	679c                	ld	a5,8(a5)
ffffffffc0201bc8:	2605                	addiw	a2,a2,1
ffffffffc0201bca:	ff379ee3          	bne	a5,s3,ffffffffc0201bc6 <slub_check+0x262>
        }
    }

    kmem_cache_t *cache64 = slub_select_cache(64);
    if (cache64)
        cprintf("[SLUB] after alloc: partial=%d full=%d\n",
ffffffffc0201bce:	00002517          	auipc	a0,0x2
ffffffffc0201bd2:	09a50513          	addi	a0,a0,154 # ffffffffc0203c68 <buddy_system_pmm_manager+0x648>
ffffffffc0201bd6:	d76fe0ef          	jal	ra,ffffffffc020014c <cprintf>
                list_count(&cache64->slabs_partial),
                list_count(&cache64->slabs_full));

    for (int i = 0; i < N; i += 2)
ffffffffc0201bda:	6789                	lui	a5,0x2
ffffffffc0201bdc:	993e                	add	s2,s2,a5
        slub_free(arr[i], 64);
ffffffffc0201bde:	6088                	ld	a0,0(s1)
ffffffffc0201be0:	04000593          	li	a1,64
    for (int i = 0; i < N; i += 2)
ffffffffc0201be4:	04c1                	addi	s1,s1,16
        slub_free(arr[i], 64);
ffffffffc0201be6:	a91ff0ef          	jal	ra,ffffffffc0201676 <slub_free>
    for (int i = 0; i < N; i += 2)
ffffffffc0201bea:	ff249ae3          	bne	s1,s2,ffffffffc0201bde <slub_check+0x27a>
ffffffffc0201bee:	050c3783          	ld	a5,80(s8)
    int cnt = 0;
ffffffffc0201bf2:	4581                	li	a1,0
    while ((le = list_next(le)) != head) cnt++;
ffffffffc0201bf4:	01478663          	beq	a5,s4,ffffffffc0201c00 <slub_check+0x29c>
ffffffffc0201bf8:	679c                	ld	a5,8(a5)
ffffffffc0201bfa:	2585                	addiw	a1,a1,1
ffffffffc0201bfc:	ff479ee3          	bne	a5,s4,ffffffffc0201bf8 <slub_check+0x294>
ffffffffc0201c00:	060c3783          	ld	a5,96(s8)
    int cnt = 0;
ffffffffc0201c04:	4601                	li	a2,0
    while ((le = list_next(le)) != head) cnt++;
ffffffffc0201c06:	01378663          	beq	a5,s3,ffffffffc0201c12 <slub_check+0x2ae>
ffffffffc0201c0a:	679c                	ld	a5,8(a5)
ffffffffc0201c0c:	2605                	addiw	a2,a2,1
ffffffffc0201c0e:	ff379ee3          	bne	a5,s3,ffffffffc0201c0a <slub_check+0x2a6>

    if (cache64)
        cprintf("[SLUB] after free half: partial=%d full=%d\n",
ffffffffc0201c12:	00002517          	auipc	a0,0x2
ffffffffc0201c16:	07e50513          	addi	a0,a0,126 # ffffffffc0203c90 <buddy_system_pmm_manager+0x670>
ffffffffc0201c1a:	d32fe0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0201c1e:	4b81                	li	s7,0
                list_count(&cache64->slabs_full));

    for (int i = 0; i < N / 2; i++) {
        void *o = slub_alloc(64);
        assert(o != NULL);
        if (i < 3) {
ffffffffc0201c20:	4489                	li	s1,2
    for (int i = 0; i < N / 2; i++) {
ffffffffc0201c22:	20000913          	li	s2,512
            uintptr_t pa = (uintptr_t)o - va_pa_offset;
            cprintf("[SLUB] reuse[%d]: va=%lx pa=%lx page_pa=%lx\n",
                    i, (uintptr_t)o, pa, ROUNDDOWN(pa, PGSIZE));
ffffffffc0201c26:	7b7d                	lui	s6,0xfffff
            cprintf("[SLUB] reuse[%d]: va=%lx pa=%lx page_pa=%lx\n",
ffffffffc0201c28:	00002a97          	auipc	s5,0x2
ffffffffc0201c2c:	0a8a8a93          	addi	s5,s5,168 # ffffffffc0203cd0 <buddy_system_pmm_manager+0x6b0>
        void *o = slub_alloc(64);
ffffffffc0201c30:	04000513          	li	a0,64
ffffffffc0201c34:	b09ff0ef          	jal	ra,ffffffffc020173c <slub_alloc>
        assert(o != NULL);
ffffffffc0201c38:	3c050463          	beqz	a0,ffffffffc0202000 <slub_check+0x69c>
    for (int i = 0; i < N / 2; i++) {
ffffffffc0201c3c:	001b8d1b          	addiw	s10,s7,1
        if (i < 3) {
ffffffffc0201c40:	3374f163          	bgeu	s1,s7,ffffffffc0201f62 <slub_check+0x5fe>
    for (int i = 0; i < N / 2; i++) {
ffffffffc0201c44:	012d0463          	beq	s10,s2,ffffffffc0201c4c <slub_check+0x2e8>
ffffffffc0201c48:	8bea                	mv	s7,s10
ffffffffc0201c4a:	b7dd                	j	ffffffffc0201c30 <slub_check+0x2cc>
ffffffffc0201c4c:	050c3783          	ld	a5,80(s8)
    int cnt = 0;
ffffffffc0201c50:	4581                	li	a1,0
    while ((le = list_next(le)) != head) cnt++;
ffffffffc0201c52:	01478663          	beq	a5,s4,ffffffffc0201c5e <slub_check+0x2fa>
ffffffffc0201c56:	679c                	ld	a5,8(a5)
ffffffffc0201c58:	2585                	addiw	a1,a1,1
ffffffffc0201c5a:	ff479ee3          	bne	a5,s4,ffffffffc0201c56 <slub_check+0x2f2>
ffffffffc0201c5e:	060c3783          	ld	a5,96(s8)
    int cnt = 0;
ffffffffc0201c62:	4601                	li	a2,0
    while ((le = list_next(le)) != head) cnt++;
ffffffffc0201c64:	01378663          	beq	a5,s3,ffffffffc0201c70 <slub_check+0x30c>
ffffffffc0201c68:	679c                	ld	a5,8(a5)
ffffffffc0201c6a:	2605                	addiw	a2,a2,1
ffffffffc0201c6c:	ff379ee3          	bne	a5,s3,ffffffffc0201c68 <slub_check+0x304>
        }
    }

    if (cache64)
        cprintf("[SLUB] after reuse: partial=%d full=%d\n",
ffffffffc0201c70:	00002517          	auipc	a0,0x2
ffffffffc0201c74:	09050513          	addi	a0,a0,144 # ffffffffc0203d00 <buddy_system_pmm_manager+0x6e0>
ffffffffc0201c78:	cd4fe0ef          	jal	ra,ffffffffc020014c <cprintf>
                list_count(&cache64->slabs_partial),
                list_count(&cache64->slabs_full));

    // 大对象回退测试：>4096 的请求退回页级
    cprintf("[SLUB] big pages (2-page) fallback test begin\n");
ffffffffc0201c7c:	00002517          	auipc	a0,0x2
ffffffffc0201c80:	0ac50513          	addi	a0,a0,172 # ffffffffc0203d28 <buddy_system_pmm_manager+0x708>
ffffffffc0201c84:	cc8fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    return buddy_system_pmm_manager.alloc_pages(n);
ffffffffc0201c88:	f1843783          	ld	a5,-232(s0)
ffffffffc0201c8c:	4509                	li	a0,2
ffffffffc0201c8e:	9782                	jalr	a5
ffffffffc0201c90:	84aa                	mv	s1,a0
    struct Page *big = slub_alloc_pages(2);
    assert(big != NULL);
ffffffffc0201c92:	46050763          	beqz	a0,ffffffffc0202100 <slub_check+0x79c>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201c96:	0000a617          	auipc	a2,0xa
ffffffffc0201c9a:	57a63603          	ld	a2,1402(a2) # ffffffffc020c210 <pages>
ffffffffc0201c9e:	40c50633          	sub	a2,a0,a2
ffffffffc0201ca2:	00002797          	auipc	a5,0x2
ffffffffc0201ca6:	43e7b783          	ld	a5,1086(a5) # ffffffffc02040e0 <error_string+0x38>
ffffffffc0201caa:	860d                	srai	a2,a2,0x3
ffffffffc0201cac:	02f60633          	mul	a2,a2,a5
    uintptr_t big_pa = page2pa(big);
    uintptr_t big_va = big_pa + va_pa_offset;
ffffffffc0201cb0:	000cb583          	ld	a1,0(s9)
ffffffffc0201cb4:	00002797          	auipc	a5,0x2
ffffffffc0201cb8:	4347b783          	ld	a5,1076(a5) # ffffffffc02040e8 <nbase>
    cprintf("[SLUB] big pages alloc: va=%lx pa=%lx\n", big_va, big_pa);
ffffffffc0201cbc:	00002517          	auipc	a0,0x2
ffffffffc0201cc0:	0ac50513          	addi	a0,a0,172 # ffffffffc0203d68 <buddy_system_pmm_manager+0x748>
ffffffffc0201cc4:	963e                	add	a2,a2,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0201cc6:	0632                	slli	a2,a2,0xc
ffffffffc0201cc8:	95b2                	add	a1,a1,a2
ffffffffc0201cca:	c82fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    buddy_system_pmm_manager.free_pages(base, n);
ffffffffc0201cce:	f3043783          	ld	a5,-208(s0)
ffffffffc0201cd2:	4589                	li	a1,2
ffffffffc0201cd4:	8526                	mv	a0,s1
ffffffffc0201cd6:	9782                	jalr	a5
    slub_free_pages(big, 2);
    cprintf("[SLUB] big pages free done\n");
ffffffffc0201cd8:	00002517          	auipc	a0,0x2
ffffffffc0201cdc:	0b850513          	addi	a0,a0,184 # ffffffffc0203d90 <buddy_system_pmm_manager+0x770>
ffffffffc0201ce0:	c6cfe0ef          	jal	ra,ffffffffc020014c <cprintf>

    cprintf("[SLUB] === slub_check() completed ===\n");
ffffffffc0201ce4:	00002517          	auipc	a0,0x2
ffffffffc0201ce8:	0cc50513          	addi	a0,a0,204 # ffffffffc0203db0 <buddy_system_pmm_manager+0x790>
ffffffffc0201cec:	c60fe0ef          	jal	ra,ffffffffc020014c <cprintf>
}
ffffffffc0201cf0:	f1040113          	addi	sp,s0,-240
ffffffffc0201cf4:	70ae                	ld	ra,232(sp)
ffffffffc0201cf6:	740e                	ld	s0,224(sp)
ffffffffc0201cf8:	64ee                	ld	s1,216(sp)
ffffffffc0201cfa:	694e                	ld	s2,208(sp)
ffffffffc0201cfc:	69ae                	ld	s3,200(sp)
ffffffffc0201cfe:	6a0e                	ld	s4,192(sp)
ffffffffc0201d00:	7aea                	ld	s5,184(sp)
ffffffffc0201d02:	7b4a                	ld	s6,176(sp)
ffffffffc0201d04:	7baa                	ld	s7,168(sp)
ffffffffc0201d06:	7c0a                	ld	s8,160(sp)
ffffffffc0201d08:	6cea                	ld	s9,152(sp)
ffffffffc0201d0a:	6d4a                	ld	s10,144(sp)
ffffffffc0201d0c:	6daa                	ld	s11,136(sp)
ffffffffc0201d0e:	616d                	addi	sp,sp,240
ffffffffc0201d10:	8082                	ret
        cprintf("[SLUB] new cache test for size=%u begin\n", (unsigned)sizes[si]);
ffffffffc0201d12:	f3843583          	ld	a1,-200(s0)
ffffffffc0201d16:	00002517          	auipc	a0,0x2
ffffffffc0201d1a:	c5a50513          	addi	a0,a0,-934 # ffffffffc0203970 <buddy_system_pmm_manager+0x350>
ffffffffc0201d1e:	c2efe0ef          	jal	ra,ffffffffc020014c <cprintf>
        void *first = slub_alloc(sizes[si]);
ffffffffc0201d22:	854a                	mv	a0,s2
ffffffffc0201d24:	a19ff0ef          	jal	ra,ffffffffc020173c <slub_alloc>
ffffffffc0201d28:	f4a43023          	sd	a0,-192(s0)
        assert(first != NULL);
ffffffffc0201d2c:	3a050a63          	beqz	a0,ffffffffc02020e0 <slub_check+0x77c>
        cprintf("[SLUB] first alloc: va=%lx pa=%lx page_pa=%lx | partial=%d full=%d\n",
ffffffffc0201d30:	f4043703          	ld	a4,-192(s0)
ffffffffc0201d34:	000cb603          	ld	a2,0(s9)
ffffffffc0201d38:	0189b783          	ld	a5,24(s3)
ffffffffc0201d3c:	010a0993          	addi	s3,s4,16
ffffffffc0201d40:	40c70633          	sub	a2,a4,a2
ffffffffc0201d44:	99e2                	add	s3,s3,s8
                ROUNDDOWN((uintptr_t)first - va_pa_offset, PGSIZE),
ffffffffc0201d46:	777d                	lui	a4,0xfffff
ffffffffc0201d48:	00e676b3          	and	a3,a2,a4
    int cnt = 0;
ffffffffc0201d4c:	4701                	li	a4,0
    while ((le = list_next(le)) != head) cnt++;
ffffffffc0201d4e:	00f98663          	beq	s3,a5,ffffffffc0201d5a <slub_check+0x3f6>
ffffffffc0201d52:	679c                	ld	a5,8(a5)
ffffffffc0201d54:	2705                	addiw	a4,a4,1
ffffffffc0201d56:	fef99ee3          	bne	s3,a5,ffffffffc0201d52 <slub_check+0x3ee>
ffffffffc0201d5a:	00349793          	slli	a5,s1,0x3
ffffffffc0201d5e:	8f85                	sub	a5,a5,s1
ffffffffc0201d60:	078e                	slli	a5,a5,0x3
ffffffffc0201d62:	97e2                	add	a5,a5,s8
ffffffffc0201d64:	778c                	ld	a1,40(a5)
        cprintf("[SLUB] first alloc: va=%lx pa=%lx page_pa=%lx | partial=%d full=%d\n",
ffffffffc0201d66:	020a0e13          	addi	t3,s4,32
ffffffffc0201d6a:	01cc0db3          	add	s11,s8,t3
    int cnt = 0;
ffffffffc0201d6e:	4781                	li	a5,0
    while ((le = list_next(le)) != head) cnt++;
ffffffffc0201d70:	00bd8663          	beq	s11,a1,ffffffffc0201d7c <slub_check+0x418>
ffffffffc0201d74:	658c                	ld	a1,8(a1)
ffffffffc0201d76:	2785                	addiw	a5,a5,1
ffffffffc0201d78:	febd9ee3          	bne	s11,a1,ffffffffc0201d74 <slub_check+0x410>
        cprintf("[SLUB] first alloc: va=%lx pa=%lx page_pa=%lx | partial=%d full=%d\n",
ffffffffc0201d7c:	f4043583          	ld	a1,-192(s0)
ffffffffc0201d80:	00002517          	auipc	a0,0x2
ffffffffc0201d84:	c3050513          	addi	a0,a0,-976 # ffffffffc02039b0 <buddy_system_pmm_manager+0x390>
ffffffffc0201d88:	bc4fe0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0201d8c:	00349793          	slli	a5,s1,0x3
ffffffffc0201d90:	8f85                	sub	a5,a5,s1
ffffffffc0201d92:	078e                	slli	a5,a5,0x3
ffffffffc0201d94:	97e2                	add	a5,a5,s8
ffffffffc0201d96:	0187bd03          	ld	s10,24(a5)
    while ((le = list_next(le)) != head) cnt++;
ffffffffc0201d9a:	25a98363          	beq	s3,s10,ffffffffc0201fe0 <slub_check+0x67c>
ffffffffc0201d9e:	008d3d03          	ld	s10,8(s10)
ffffffffc0201da2:	ffa99ee3          	bne	s3,s10,ffffffffc0201d9e <slub_check+0x43a>
        unsigned cap = ((PGSIZE * cache->slab_pages) - sizeof(slub_slab_t)) / cache->objsize;
ffffffffc0201da6:	00349b93          	slli	s7,s1,0x3
ffffffffc0201daa:	409b8bb3          	sub	s7,s7,s1
ffffffffc0201dae:	0b8e                	slli	s7,s7,0x3
ffffffffc0201db0:	017c07b3          	add	a5,s8,s7
ffffffffc0201db4:	0307a983          	lw	s3,48(a5)
ffffffffc0201db8:	f2f43423          	sd	a5,-216(s0)
ffffffffc0201dbc:	0087e783          	lwu	a5,8(a5)
ffffffffc0201dc0:	00c9999b          	slliw	s3,s3,0xc
ffffffffc0201dc4:	1982                	slli	s3,s3,0x20
ffffffffc0201dc6:	0209d993          	srli	s3,s3,0x20
ffffffffc0201dca:	fc898993          	addi	s3,s3,-56
ffffffffc0201dce:	02f9d9b3          	divu	s3,s3,a5
        cprintf("[SLUB] capacity per slab = %u objects\n", cap);
ffffffffc0201dd2:	00002517          	auipc	a0,0x2
ffffffffc0201dd6:	c4e50513          	addi	a0,a0,-946 # ffffffffc0203a20 <buddy_system_pmm_manager+0x400>
        for (unsigned i = 1; i < cap; i++) {
ffffffffc0201dda:	4b85                	li	s7,1
        unsigned cap = ((PGSIZE * cache->slab_pages) - sizeof(slub_slab_t)) / cache->objsize;
ffffffffc0201ddc:	2981                	sext.w	s3,s3
        cprintf("[SLUB] capacity per slab = %u objects\n", cap);
ffffffffc0201dde:	85ce                	mv	a1,s3
ffffffffc0201de0:	b6cfe0ef          	jal	ra,ffffffffc020014c <cprintf>
            if (i == cap / 2 || i == cap - 1) {
ffffffffc0201de4:	0019da1b          	srliw	s4,s3,0x1
ffffffffc0201de8:	fff98a9b          	addiw	s5,s3,-1
        for (unsigned i = 1; i < cap; i++) {
ffffffffc0201dec:	073bfe63          	bgeu	s7,s3,ffffffffc0201e68 <slub_check+0x504>
ffffffffc0201df0:	f2943023          	sd	s1,-224(s0)
ffffffffc0201df4:	84ea                	mv	s1,s10
ffffffffc0201df6:	8d5e                	mv	s10,s7
ffffffffc0201df8:	f2843b83          	ld	s7,-216(s0)
ffffffffc0201dfc:	a031                	j	ffffffffc0201e08 <slub_check+0x4a4>
            if (i == cap / 2 || i == cap - 1) {
ffffffffc0201dfe:	01aa8c63          	beq	s5,s10,ffffffffc0201e16 <slub_check+0x4b2>
        for (unsigned i = 1; i < cap; i++) {
ffffffffc0201e02:	2d05                	addiw	s10,s10,1
ffffffffc0201e04:	05a98f63          	beq	s3,s10,ffffffffc0201e62 <slub_check+0x4fe>
            void *obj = slub_alloc(sizes[si]);
ffffffffc0201e08:	854a                	mv	a0,s2
ffffffffc0201e0a:	933ff0ef          	jal	ra,ffffffffc020173c <slub_alloc>
            assert(obj != NULL);
ffffffffc0201e0e:	22050963          	beqz	a0,ffffffffc0202040 <slub_check+0x6dc>
            if (i == cap / 2 || i == cap - 1) {
ffffffffc0201e12:	ffaa16e3          	bne	s4,s10,ffffffffc0201dfe <slub_check+0x49a>
                uintptr_t pa = (uintptr_t)obj - va_pa_offset;
ffffffffc0201e16:	000cb683          	ld	a3,0(s9)
ffffffffc0201e1a:	0084b803          	ld	a6,8(s1)
                uintptr_t page_pa = ROUNDDOWN(pa, PGSIZE);
ffffffffc0201e1e:	77fd                	lui	a5,0xfffff
                uintptr_t pa = (uintptr_t)obj - va_pa_offset;
ffffffffc0201e20:	40d506b3          	sub	a3,a0,a3
                uintptr_t page_pa = ROUNDDOWN(pa, PGSIZE);
ffffffffc0201e24:	00f6f733          	and	a4,a3,a5
    int cnt = 0;
ffffffffc0201e28:	4781                	li	a5,0
    while ((le = list_next(le)) != head) cnt++;
ffffffffc0201e2a:	00980763          	beq	a6,s1,ffffffffc0201e38 <slub_check+0x4d4>
ffffffffc0201e2e:	00883803          	ld	a6,8(a6)
ffffffffc0201e32:	2785                	addiw	a5,a5,1
ffffffffc0201e34:	ff049de3          	bne	s1,a6,ffffffffc0201e2e <slub_check+0x4ca>
ffffffffc0201e38:	028bb883          	ld	a7,40(s7)
    int cnt = 0;
ffffffffc0201e3c:	4801                	li	a6,0
    while ((le = list_next(le)) != head) cnt++;
ffffffffc0201e3e:	011d8763          	beq	s11,a7,ffffffffc0201e4c <slub_check+0x4e8>
ffffffffc0201e42:	0088b883          	ld	a7,8(a7)
ffffffffc0201e46:	2805                	addiw	a6,a6,1
ffffffffc0201e48:	ff1d9de3          	bne	s11,a7,ffffffffc0201e42 <slub_check+0x4de>
                cprintf("[SLUB] alloc i=%u: va=%lx pa=%lx page_pa=%lx | partial=%d full=%d\n",
ffffffffc0201e4c:	862a                	mv	a2,a0
ffffffffc0201e4e:	85ea                	mv	a1,s10
ffffffffc0201e50:	00002517          	auipc	a0,0x2
ffffffffc0201e54:	c0850513          	addi	a0,a0,-1016 # ffffffffc0203a58 <buddy_system_pmm_manager+0x438>
        for (unsigned i = 1; i < cap; i++) {
ffffffffc0201e58:	2d05                	addiw	s10,s10,1
                cprintf("[SLUB] alloc i=%u: va=%lx pa=%lx page_pa=%lx | partial=%d full=%d\n",
ffffffffc0201e5a:	af2fe0ef          	jal	ra,ffffffffc020014c <cprintf>
        for (unsigned i = 1; i < cap; i++) {
ffffffffc0201e5e:	fba995e3          	bne	s3,s10,ffffffffc0201e08 <slub_check+0x4a4>
ffffffffc0201e62:	8d26                	mv	s10,s1
ffffffffc0201e64:	f2043483          	ld	s1,-224(s0)
ffffffffc0201e68:	008d3783          	ld	a5,8(s10)
    int cnt = 0;
ffffffffc0201e6c:	4581                	li	a1,0
    while ((le = list_next(le)) != head) cnt++;
ffffffffc0201e6e:	00fd0663          	beq	s10,a5,ffffffffc0201e7a <slub_check+0x516>
ffffffffc0201e72:	679c                	ld	a5,8(a5)
ffffffffc0201e74:	2585                	addiw	a1,a1,1
ffffffffc0201e76:	fefd1ee3          	bne	s10,a5,ffffffffc0201e72 <slub_check+0x50e>
ffffffffc0201e7a:	00349793          	slli	a5,s1,0x3
ffffffffc0201e7e:	8f85                	sub	a5,a5,s1
ffffffffc0201e80:	078e                	slli	a5,a5,0x3
ffffffffc0201e82:	97e2                	add	a5,a5,s8
ffffffffc0201e84:	779c                	ld	a5,40(a5)
    int cnt = 0;
ffffffffc0201e86:	4601                	li	a2,0
    while ((le = list_next(le)) != head) cnt++;
ffffffffc0201e88:	00fd8663          	beq	s11,a5,ffffffffc0201e94 <slub_check+0x530>
ffffffffc0201e8c:	679c                	ld	a5,8(a5)
ffffffffc0201e8e:	2605                	addiw	a2,a2,1
ffffffffc0201e90:	fefd9ee3          	bne	s11,a5,ffffffffc0201e8c <slub_check+0x528>
        cprintf("[SLUB] after fill: partial=%d full=%d\n",
ffffffffc0201e94:	00002517          	auipc	a0,0x2
ffffffffc0201e98:	c0c50513          	addi	a0,a0,-1012 # ffffffffc0203aa0 <buddy_system_pmm_manager+0x480>
ffffffffc0201e9c:	ab0fe0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0201ea0:	00349793          	slli	a5,s1,0x3
ffffffffc0201ea4:	8f85                	sub	a5,a5,s1
ffffffffc0201ea6:	078e                	slli	a5,a5,0x3
ffffffffc0201ea8:	97e2                	add	a5,a5,s8
ffffffffc0201eaa:	7784                	ld	s1,40(a5)
    while ((le = list_next(le)) != head) cnt++;
ffffffffc0201eac:	109d8a63          	beq	s11,s1,ffffffffc0201fc0 <slub_check+0x65c>
ffffffffc0201eb0:	6484                	ld	s1,8(s1)
ffffffffc0201eb2:	fe9d9fe3          	bne	s11,s1,ffffffffc0201eb0 <slub_check+0x54c>
        void *extra = slub_alloc(sizes[si]);
ffffffffc0201eb6:	854a                	mv	a0,s2
ffffffffc0201eb8:	885ff0ef          	jal	ra,ffffffffc020173c <slub_alloc>
ffffffffc0201ebc:	85aa                	mv	a1,a0
        if (extra != NULL) {
ffffffffc0201ebe:	c905                	beqz	a0,ffffffffc0201eee <slub_check+0x58a>
            uintptr_t pa_first = ROUNDDOWN((uintptr_t)first - va_pa_offset, PGSIZE);
ffffffffc0201ec0:	000cb983          	ld	s3,0(s9)
ffffffffc0201ec4:	f4043783          	ld	a5,-192(s0)
            cprintf("[SLUB] extra alloc: va=%lx pa=%lx page_pa=%lx | first_page_pa=%lx\n",
ffffffffc0201ec8:	00002517          	auipc	a0,0x2
ffffffffc0201ecc:	c2850513          	addi	a0,a0,-984 # ffffffffc0203af0 <buddy_system_pmm_manager+0x4d0>
            uintptr_t pa_extra = ROUNDDOWN((uintptr_t)extra - va_pa_offset, PGSIZE);
ffffffffc0201ed0:	41358633          	sub	a2,a1,s3
            uintptr_t pa_first = ROUNDDOWN((uintptr_t)first - va_pa_offset, PGSIZE);
ffffffffc0201ed4:	413789b3          	sub	s3,a5,s3
ffffffffc0201ed8:	77fd                	lui	a5,0xfffff
ffffffffc0201eda:	00f9f9b3          	and	s3,s3,a5
            uintptr_t pa_extra = ROUNDDOWN((uintptr_t)extra - va_pa_offset, PGSIZE);
ffffffffc0201ede:	00f67a33          	and	s4,a2,a5
            cprintf("[SLUB] extra alloc: va=%lx pa=%lx page_pa=%lx | first_page_pa=%lx\n",
ffffffffc0201ee2:	874e                	mv	a4,s3
ffffffffc0201ee4:	86d2                	mv	a3,s4
ffffffffc0201ee6:	a66fe0ef          	jal	ra,ffffffffc020014c <cprintf>
            assert(pa_first != pa_extra);
ffffffffc0201eea:	17498b63          	beq	s3,s4,ffffffffc0202060 <slub_check+0x6fc>
        slub_free(first, sizes[si]);
ffffffffc0201eee:	f4043503          	ld	a0,-192(s0)
ffffffffc0201ef2:	85ca                	mv	a1,s2
ffffffffc0201ef4:	f82ff0ef          	jal	ra,ffffffffc0201676 <slub_free>
ffffffffc0201ef8:	008d3783          	ld	a5,8(s10)
    int cnt = 0;
ffffffffc0201efc:	4581                	li	a1,0
    while ((le = list_next(le)) != head) cnt++;
ffffffffc0201efe:	00fd0663          	beq	s10,a5,ffffffffc0201f0a <slub_check+0x5a6>
ffffffffc0201f02:	679c                	ld	a5,8(a5)
ffffffffc0201f04:	2585                	addiw	a1,a1,1
ffffffffc0201f06:	fefd1ee3          	bne	s10,a5,ffffffffc0201f02 <slub_check+0x59e>
ffffffffc0201f0a:	649c                	ld	a5,8(s1)
    int cnt = 0;
ffffffffc0201f0c:	4601                	li	a2,0
    while ((le = list_next(le)) != head) cnt++;
ffffffffc0201f0e:	00978663          	beq	a5,s1,ffffffffc0201f1a <slub_check+0x5b6>
ffffffffc0201f12:	679c                	ld	a5,8(a5)
ffffffffc0201f14:	2605                	addiw	a2,a2,1
ffffffffc0201f16:	fef49ee3          	bne	s1,a5,ffffffffc0201f12 <slub_check+0x5ae>
        cprintf("[SLUB] after free first: partial=%d full=%d\n",
ffffffffc0201f1a:	00002517          	auipc	a0,0x2
ffffffffc0201f1e:	c3650513          	addi	a0,a0,-970 # ffffffffc0203b50 <buddy_system_pmm_manager+0x530>
ffffffffc0201f22:	a2afe0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("[SLUB] before count(partial) after free\n");
ffffffffc0201f26:	00002517          	auipc	a0,0x2
ffffffffc0201f2a:	c5a50513          	addi	a0,a0,-934 # ffffffffc0203b80 <buddy_system_pmm_manager+0x560>
ffffffffc0201f2e:	a1efe0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0201f32:	008d3783          	ld	a5,8(s10)
    int cnt = 0;
ffffffffc0201f36:	4581                	li	a1,0
    while ((le = list_next(le)) != head) cnt++;
ffffffffc0201f38:	04fd0e63          	beq	s10,a5,ffffffffc0201f94 <slub_check+0x630>
ffffffffc0201f3c:	679c                	ld	a5,8(a5)
ffffffffc0201f3e:	2585                	addiw	a1,a1,1
ffffffffc0201f40:	fefd1ee3          	bne	s10,a5,ffffffffc0201f3c <slub_check+0x5d8>
        cprintf("[SLUB] partial count=%d\n", pc);
ffffffffc0201f44:	00002517          	auipc	a0,0x2
ffffffffc0201f48:	c6c50513          	addi	a0,a0,-916 # ffffffffc0203bb0 <buddy_system_pmm_manager+0x590>
ffffffffc0201f4c:	a00fe0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("[SLUB] size=%u test done.\n", (unsigned)sizes[si]);
ffffffffc0201f50:	f3843583          	ld	a1,-200(s0)
ffffffffc0201f54:	00002517          	auipc	a0,0x2
ffffffffc0201f58:	c8450513          	addi	a0,a0,-892 # ffffffffc0203bd8 <buddy_system_pmm_manager+0x5b8>
ffffffffc0201f5c:	9f0fe0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0201f60:	bef9                	j	ffffffffc0201b3e <slub_check+0x1da>
            uintptr_t pa = (uintptr_t)o - va_pa_offset;
ffffffffc0201f62:	000cb683          	ld	a3,0(s9)
            cprintf("[SLUB] reuse[%d]: va=%lx pa=%lx page_pa=%lx\n",
ffffffffc0201f66:	862a                	mv	a2,a0
ffffffffc0201f68:	85de                	mv	a1,s7
            uintptr_t pa = (uintptr_t)o - va_pa_offset;
ffffffffc0201f6a:	40d506b3          	sub	a3,a0,a3
            cprintf("[SLUB] reuse[%d]: va=%lx pa=%lx page_pa=%lx\n",
ffffffffc0201f6e:	0166f733          	and	a4,a3,s6
ffffffffc0201f72:	8556                	mv	a0,s5
ffffffffc0201f74:	9d8fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    for (int i = 0; i < N / 2; i++) {
ffffffffc0201f78:	8bea                	mv	s7,s10
ffffffffc0201f7a:	b95d                	j	ffffffffc0201c30 <slub_check+0x2cc>
            uintptr_t pa = (uintptr_t)arr[i] - va_pa_offset;
ffffffffc0201f7c:	000cb683          	ld	a3,0(s9)
            cprintf("[SLUB] arr[%d]: va=%lx pa=%lx page_pa=%lx\n",
ffffffffc0201f80:	862a                	mv	a2,a0
ffffffffc0201f82:	85de                	mv	a1,s7
            uintptr_t pa = (uintptr_t)arr[i] - va_pa_offset;
ffffffffc0201f84:	40d506b3          	sub	a3,a0,a3
            cprintf("[SLUB] arr[%d]: va=%lx pa=%lx page_pa=%lx\n",
ffffffffc0201f88:	0166f733          	and	a4,a3,s6
ffffffffc0201f8c:	8556                	mv	a0,s5
ffffffffc0201f8e:	9befe0ef          	jal	ra,ffffffffc020014c <cprintf>
    for (int i = 0; i < N; i++) {
ffffffffc0201f92:	b6e5                	j	ffffffffc0201b7a <slub_check+0x216>
        cprintf("[SLUB] partial count=%d\n", pc);
ffffffffc0201f94:	00002517          	auipc	a0,0x2
ffffffffc0201f98:	c1c50513          	addi	a0,a0,-996 # ffffffffc0203bb0 <buddy_system_pmm_manager+0x590>
ffffffffc0201f9c:	9b0fe0ef          	jal	ra,ffffffffc020014c <cprintf>
        assert(pc >= 1);
ffffffffc0201fa0:	00002697          	auipc	a3,0x2
ffffffffc0201fa4:	c3068693          	addi	a3,a3,-976 # ffffffffc0203bd0 <buddy_system_pmm_manager+0x5b0>
ffffffffc0201fa8:	00001617          	auipc	a2,0x1
ffffffffc0201fac:	8f860613          	addi	a2,a2,-1800 # ffffffffc02028a0 <etext+0x2b4>
ffffffffc0201fb0:	1b600593          	li	a1,438
ffffffffc0201fb4:	00002517          	auipc	a0,0x2
ffffffffc0201fb8:	85450513          	addi	a0,a0,-1964 # ffffffffc0203808 <buddy_system_pmm_manager+0x1e8>
ffffffffc0201fbc:	a06fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(list_count(&cache->slabs_full) >= 1);
ffffffffc0201fc0:	00002697          	auipc	a3,0x2
ffffffffc0201fc4:	b0868693          	addi	a3,a3,-1272 # ffffffffc0203ac8 <buddy_system_pmm_manager+0x4a8>
ffffffffc0201fc8:	00001617          	auipc	a2,0x1
ffffffffc0201fcc:	8d860613          	addi	a2,a2,-1832 # ffffffffc02028a0 <etext+0x2b4>
ffffffffc0201fd0:	19f00593          	li	a1,415
ffffffffc0201fd4:	00002517          	auipc	a0,0x2
ffffffffc0201fd8:	83450513          	addi	a0,a0,-1996 # ffffffffc0203808 <buddy_system_pmm_manager+0x1e8>
ffffffffc0201fdc:	9e6fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(list_count(&cache->slabs_partial) >= 1);
ffffffffc0201fe0:	00002697          	auipc	a3,0x2
ffffffffc0201fe4:	a1868693          	addi	a3,a3,-1512 # ffffffffc02039f8 <buddy_system_pmm_manager+0x3d8>
ffffffffc0201fe8:	00001617          	auipc	a2,0x1
ffffffffc0201fec:	8b860613          	addi	a2,a2,-1864 # ffffffffc02028a0 <etext+0x2b4>
ffffffffc0201ff0:	18a00593          	li	a1,394
ffffffffc0201ff4:	00002517          	auipc	a0,0x2
ffffffffc0201ff8:	81450513          	addi	a0,a0,-2028 # ffffffffc0203808 <buddy_system_pmm_manager+0x1e8>
ffffffffc0201ffc:	9c6fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(o != NULL);
ffffffffc0202000:	00002697          	auipc	a3,0x2
ffffffffc0202004:	cc068693          	addi	a3,a3,-832 # ffffffffc0203cc0 <buddy_system_pmm_manager+0x6a0>
ffffffffc0202008:	00001617          	auipc	a2,0x1
ffffffffc020200c:	89860613          	addi	a2,a2,-1896 # ffffffffc02028a0 <etext+0x2b4>
ffffffffc0202010:	1d800593          	li	a1,472
ffffffffc0202014:	00001517          	auipc	a0,0x1
ffffffffc0202018:	7f450513          	addi	a0,a0,2036 # ffffffffc0203808 <buddy_system_pmm_manager+0x1e8>
ffffffffc020201c:	9a6fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(arr[i] != NULL);
ffffffffc0202020:	00002697          	auipc	a3,0x2
ffffffffc0202024:	c0868693          	addi	a3,a3,-1016 # ffffffffc0203c28 <buddy_system_pmm_manager+0x608>
ffffffffc0202028:	00001617          	auipc	a2,0x1
ffffffffc020202c:	87860613          	addi	a2,a2,-1928 # ffffffffc02028a0 <etext+0x2b4>
ffffffffc0202030:	1c000593          	li	a1,448
ffffffffc0202034:	00001517          	auipc	a0,0x1
ffffffffc0202038:	7d450513          	addi	a0,a0,2004 # ffffffffc0203808 <buddy_system_pmm_manager+0x1e8>
ffffffffc020203c:	986fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(obj != NULL);
ffffffffc0202040:	00002697          	auipc	a3,0x2
ffffffffc0202044:	a0868693          	addi	a3,a3,-1528 # ffffffffc0203a48 <buddy_system_pmm_manager+0x428>
ffffffffc0202048:	00001617          	auipc	a2,0x1
ffffffffc020204c:	85860613          	addi	a2,a2,-1960 # ffffffffc02028a0 <etext+0x2b4>
ffffffffc0202050:	19200593          	li	a1,402
ffffffffc0202054:	00001517          	auipc	a0,0x1
ffffffffc0202058:	7b450513          	addi	a0,a0,1972 # ffffffffc0203808 <buddy_system_pmm_manager+0x1e8>
ffffffffc020205c:	966fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(pa_first != pa_extra);
ffffffffc0202060:	00002697          	auipc	a3,0x2
ffffffffc0202064:	ad868693          	addi	a3,a3,-1320 # ffffffffc0203b38 <buddy_system_pmm_manager+0x518>
ffffffffc0202068:	00001617          	auipc	a2,0x1
ffffffffc020206c:	83860613          	addi	a2,a2,-1992 # ffffffffc02028a0 <etext+0x2b4>
ffffffffc0202070:	1aa00593          	li	a1,426
ffffffffc0202074:	00001517          	auipc	a0,0x1
ffffffffc0202078:	79450513          	addi	a0,a0,1940 # ffffffffc0203808 <buddy_system_pmm_manager+0x1e8>
ffffffffc020207c:	946fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(ptr != NULL);
ffffffffc0202080:	00002697          	auipc	a3,0x2
ffffffffc0202084:	89868693          	addi	a3,a3,-1896 # ffffffffc0203918 <buddy_system_pmm_manager+0x2f8>
ffffffffc0202088:	00001617          	auipc	a2,0x1
ffffffffc020208c:	81860613          	addi	a2,a2,-2024 # ffffffffc02028a0 <etext+0x2b4>
ffffffffc0202090:	17500593          	li	a1,373
ffffffffc0202094:	00001517          	auipc	a0,0x1
ffffffffc0202098:	77450513          	addi	a0,a0,1908 # ffffffffc0203808 <buddy_system_pmm_manager+0x1e8>
ffffffffc020209c:	926fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p1 = buddy_system_pmm_manager.alloc_pages(1)) != NULL);
ffffffffc02020a0:	00001697          	auipc	a3,0x1
ffffffffc02020a4:	78068693          	addi	a3,a3,1920 # ffffffffc0203820 <buddy_system_pmm_manager+0x200>
ffffffffc02020a8:	00000617          	auipc	a2,0x0
ffffffffc02020ac:	7f860613          	addi	a2,a2,2040 # ffffffffc02028a0 <etext+0x2b4>
ffffffffc02020b0:	10f00593          	li	a1,271
ffffffffc02020b4:	00001517          	auipc	a0,0x1
ffffffffc02020b8:	75450513          	addi	a0,a0,1876 # ffffffffc0203808 <buddy_system_pmm_manager+0x1e8>
ffffffffc02020bc:	906fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p0 = buddy_system_pmm_manager.alloc_pages(1)) != NULL);
ffffffffc02020c0:	00001697          	auipc	a3,0x1
ffffffffc02020c4:	71068693          	addi	a3,a3,1808 # ffffffffc02037d0 <buddy_system_pmm_manager+0x1b0>
ffffffffc02020c8:	00000617          	auipc	a2,0x0
ffffffffc02020cc:	7d860613          	addi	a2,a2,2008 # ffffffffc02028a0 <etext+0x2b4>
ffffffffc02020d0:	10e00593          	li	a1,270
ffffffffc02020d4:	00001517          	auipc	a0,0x1
ffffffffc02020d8:	73450513          	addi	a0,a0,1844 # ffffffffc0203808 <buddy_system_pmm_manager+0x1e8>
ffffffffc02020dc:	8e6fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(first != NULL);
ffffffffc02020e0:	00002697          	auipc	a3,0x2
ffffffffc02020e4:	8c068693          	addi	a3,a3,-1856 # ffffffffc02039a0 <buddy_system_pmm_manager+0x380>
ffffffffc02020e8:	00000617          	auipc	a2,0x0
ffffffffc02020ec:	7b860613          	addi	a2,a2,1976 # ffffffffc02028a0 <etext+0x2b4>
ffffffffc02020f0:	18300593          	li	a1,387
ffffffffc02020f4:	00001517          	auipc	a0,0x1
ffffffffc02020f8:	71450513          	addi	a0,a0,1812 # ffffffffc0203808 <buddy_system_pmm_manager+0x1e8>
ffffffffc02020fc:	8c6fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(big != NULL);
ffffffffc0202100:	00002697          	auipc	a3,0x2
ffffffffc0202104:	c5868693          	addi	a3,a3,-936 # ffffffffc0203d58 <buddy_system_pmm_manager+0x738>
ffffffffc0202108:	00000617          	auipc	a2,0x0
ffffffffc020210c:	79860613          	addi	a2,a2,1944 # ffffffffc02028a0 <etext+0x2b4>
ffffffffc0202110:	1e800593          	li	a1,488
ffffffffc0202114:	00001517          	auipc	a0,0x1
ffffffffc0202118:	6f450513          	addi	a0,a0,1780 # ffffffffc0203808 <buddy_system_pmm_manager+0x1e8>
ffffffffc020211c:	8a6fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0202120:	00001617          	auipc	a2,0x1
ffffffffc0202124:	5f060613          	addi	a2,a2,1520 # ffffffffc0203710 <buddy_system_pmm_manager+0xf0>
ffffffffc0202128:	07100593          	li	a1,113
ffffffffc020212c:	00001517          	auipc	a0,0x1
ffffffffc0202130:	60450513          	addi	a0,a0,1540 # ffffffffc0203730 <buddy_system_pmm_manager+0x110>
ffffffffc0202134:	88efe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p2 = buddy_system_pmm_manager.alloc_pages(1)) != NULL);
ffffffffc0202138:	00001697          	auipc	a3,0x1
ffffffffc020213c:	72068693          	addi	a3,a3,1824 # ffffffffc0203858 <buddy_system_pmm_manager+0x238>
ffffffffc0202140:	00000617          	auipc	a2,0x0
ffffffffc0202144:	76060613          	addi	a2,a2,1888 # ffffffffc02028a0 <etext+0x2b4>
ffffffffc0202148:	11000593          	li	a1,272
ffffffffc020214c:	00001517          	auipc	a0,0x1
ffffffffc0202150:	6bc50513          	addi	a0,a0,1724 # ffffffffc0203808 <buddy_system_pmm_manager+0x1e8>
ffffffffc0202154:	86efe0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0202158 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0202158:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020215c:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc020215e:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0202162:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0202164:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0202168:	f022                	sd	s0,32(sp)
ffffffffc020216a:	ec26                	sd	s1,24(sp)
ffffffffc020216c:	e84a                	sd	s2,16(sp)
ffffffffc020216e:	f406                	sd	ra,40(sp)
ffffffffc0202170:	e44e                	sd	s3,8(sp)
ffffffffc0202172:	84aa                	mv	s1,a0
ffffffffc0202174:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0202176:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc020217a:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc020217c:	03067e63          	bgeu	a2,a6,ffffffffc02021b8 <printnum+0x60>
ffffffffc0202180:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0202182:	00805763          	blez	s0,ffffffffc0202190 <printnum+0x38>
ffffffffc0202186:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0202188:	85ca                	mv	a1,s2
ffffffffc020218a:	854e                	mv	a0,s3
ffffffffc020218c:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc020218e:	fc65                	bnez	s0,ffffffffc0202186 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0202190:	1a02                	slli	s4,s4,0x20
ffffffffc0202192:	00002797          	auipc	a5,0x2
ffffffffc0202196:	d0678793          	addi	a5,a5,-762 # ffffffffc0203e98 <slub_sizes+0x20>
ffffffffc020219a:	020a5a13          	srli	s4,s4,0x20
ffffffffc020219e:	9a3e                	add	s4,s4,a5
}
ffffffffc02021a0:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02021a2:	000a4503          	lbu	a0,0(s4)
}
ffffffffc02021a6:	70a2                	ld	ra,40(sp)
ffffffffc02021a8:	69a2                	ld	s3,8(sp)
ffffffffc02021aa:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02021ac:	85ca                	mv	a1,s2
ffffffffc02021ae:	87a6                	mv	a5,s1
}
ffffffffc02021b0:	6942                	ld	s2,16(sp)
ffffffffc02021b2:	64e2                	ld	s1,24(sp)
ffffffffc02021b4:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02021b6:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc02021b8:	03065633          	divu	a2,a2,a6
ffffffffc02021bc:	8722                	mv	a4,s0
ffffffffc02021be:	f9bff0ef          	jal	ra,ffffffffc0202158 <printnum>
ffffffffc02021c2:	b7f9                	j	ffffffffc0202190 <printnum+0x38>

ffffffffc02021c4 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc02021c4:	7119                	addi	sp,sp,-128
ffffffffc02021c6:	f4a6                	sd	s1,104(sp)
ffffffffc02021c8:	f0ca                	sd	s2,96(sp)
ffffffffc02021ca:	ecce                	sd	s3,88(sp)
ffffffffc02021cc:	e8d2                	sd	s4,80(sp)
ffffffffc02021ce:	e4d6                	sd	s5,72(sp)
ffffffffc02021d0:	e0da                	sd	s6,64(sp)
ffffffffc02021d2:	fc5e                	sd	s7,56(sp)
ffffffffc02021d4:	f06a                	sd	s10,32(sp)
ffffffffc02021d6:	fc86                	sd	ra,120(sp)
ffffffffc02021d8:	f8a2                	sd	s0,112(sp)
ffffffffc02021da:	f862                	sd	s8,48(sp)
ffffffffc02021dc:	f466                	sd	s9,40(sp)
ffffffffc02021de:	ec6e                	sd	s11,24(sp)
ffffffffc02021e0:	892a                	mv	s2,a0
ffffffffc02021e2:	84ae                	mv	s1,a1
ffffffffc02021e4:	8d32                	mv	s10,a2
ffffffffc02021e6:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02021e8:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc02021ec:	5b7d                	li	s6,-1
ffffffffc02021ee:	00002a97          	auipc	s5,0x2
ffffffffc02021f2:	cdea8a93          	addi	s5,s5,-802 # ffffffffc0203ecc <slub_sizes+0x54>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02021f6:	00002b97          	auipc	s7,0x2
ffffffffc02021fa:	eb2b8b93          	addi	s7,s7,-334 # ffffffffc02040a8 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02021fe:	000d4503          	lbu	a0,0(s10)
ffffffffc0202202:	001d0413          	addi	s0,s10,1
ffffffffc0202206:	01350a63          	beq	a0,s3,ffffffffc020221a <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc020220a:	c121                	beqz	a0,ffffffffc020224a <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc020220c:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020220e:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0202210:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0202212:	fff44503          	lbu	a0,-1(s0)
ffffffffc0202216:	ff351ae3          	bne	a0,s3,ffffffffc020220a <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020221a:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc020221e:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0202222:	4c81                	li	s9,0
ffffffffc0202224:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0202226:	5c7d                	li	s8,-1
ffffffffc0202228:	5dfd                	li	s11,-1
ffffffffc020222a:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc020222e:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0202230:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0202234:	0ff5f593          	zext.b	a1,a1
ffffffffc0202238:	00140d13          	addi	s10,s0,1
ffffffffc020223c:	04b56263          	bltu	a0,a1,ffffffffc0202280 <vprintfmt+0xbc>
ffffffffc0202240:	058a                	slli	a1,a1,0x2
ffffffffc0202242:	95d6                	add	a1,a1,s5
ffffffffc0202244:	4194                	lw	a3,0(a1)
ffffffffc0202246:	96d6                	add	a3,a3,s5
ffffffffc0202248:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc020224a:	70e6                	ld	ra,120(sp)
ffffffffc020224c:	7446                	ld	s0,112(sp)
ffffffffc020224e:	74a6                	ld	s1,104(sp)
ffffffffc0202250:	7906                	ld	s2,96(sp)
ffffffffc0202252:	69e6                	ld	s3,88(sp)
ffffffffc0202254:	6a46                	ld	s4,80(sp)
ffffffffc0202256:	6aa6                	ld	s5,72(sp)
ffffffffc0202258:	6b06                	ld	s6,64(sp)
ffffffffc020225a:	7be2                	ld	s7,56(sp)
ffffffffc020225c:	7c42                	ld	s8,48(sp)
ffffffffc020225e:	7ca2                	ld	s9,40(sp)
ffffffffc0202260:	7d02                	ld	s10,32(sp)
ffffffffc0202262:	6de2                	ld	s11,24(sp)
ffffffffc0202264:	6109                	addi	sp,sp,128
ffffffffc0202266:	8082                	ret
            padc = '0';
ffffffffc0202268:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc020226a:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020226e:	846a                	mv	s0,s10
ffffffffc0202270:	00140d13          	addi	s10,s0,1
ffffffffc0202274:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0202278:	0ff5f593          	zext.b	a1,a1
ffffffffc020227c:	fcb572e3          	bgeu	a0,a1,ffffffffc0202240 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0202280:	85a6                	mv	a1,s1
ffffffffc0202282:	02500513          	li	a0,37
ffffffffc0202286:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0202288:	fff44783          	lbu	a5,-1(s0)
ffffffffc020228c:	8d22                	mv	s10,s0
ffffffffc020228e:	f73788e3          	beq	a5,s3,ffffffffc02021fe <vprintfmt+0x3a>
ffffffffc0202292:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0202296:	1d7d                	addi	s10,s10,-1
ffffffffc0202298:	ff379de3          	bne	a5,s3,ffffffffc0202292 <vprintfmt+0xce>
ffffffffc020229c:	b78d                	j	ffffffffc02021fe <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc020229e:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc02022a2:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02022a6:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc02022a8:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc02022ac:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc02022b0:	02d86463          	bltu	a6,a3,ffffffffc02022d8 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc02022b4:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc02022b8:	002c169b          	slliw	a3,s8,0x2
ffffffffc02022bc:	0186873b          	addw	a4,a3,s8
ffffffffc02022c0:	0017171b          	slliw	a4,a4,0x1
ffffffffc02022c4:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc02022c6:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc02022ca:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc02022cc:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc02022d0:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc02022d4:	fed870e3          	bgeu	a6,a3,ffffffffc02022b4 <vprintfmt+0xf0>
            if (width < 0)
ffffffffc02022d8:	f40ddce3          	bgez	s11,ffffffffc0202230 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc02022dc:	8de2                	mv	s11,s8
ffffffffc02022de:	5c7d                	li	s8,-1
ffffffffc02022e0:	bf81                	j	ffffffffc0202230 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc02022e2:	fffdc693          	not	a3,s11
ffffffffc02022e6:	96fd                	srai	a3,a3,0x3f
ffffffffc02022e8:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02022ec:	00144603          	lbu	a2,1(s0)
ffffffffc02022f0:	2d81                	sext.w	s11,s11
ffffffffc02022f2:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02022f4:	bf35                	j	ffffffffc0202230 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc02022f6:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02022fa:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc02022fe:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0202300:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0202302:	bfd9                	j	ffffffffc02022d8 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0202304:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0202306:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020230a:	01174463          	blt	a4,a7,ffffffffc0202312 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc020230e:	1a088e63          	beqz	a7,ffffffffc02024ca <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0202312:	000a3603          	ld	a2,0(s4)
ffffffffc0202316:	46c1                	li	a3,16
ffffffffc0202318:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc020231a:	2781                	sext.w	a5,a5
ffffffffc020231c:	876e                	mv	a4,s11
ffffffffc020231e:	85a6                	mv	a1,s1
ffffffffc0202320:	854a                	mv	a0,s2
ffffffffc0202322:	e37ff0ef          	jal	ra,ffffffffc0202158 <printnum>
            break;
ffffffffc0202326:	bde1                	j	ffffffffc02021fe <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0202328:	000a2503          	lw	a0,0(s4)
ffffffffc020232c:	85a6                	mv	a1,s1
ffffffffc020232e:	0a21                	addi	s4,s4,8
ffffffffc0202330:	9902                	jalr	s2
            break;
ffffffffc0202332:	b5f1                	j	ffffffffc02021fe <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0202334:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0202336:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020233a:	01174463          	blt	a4,a7,ffffffffc0202342 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc020233e:	18088163          	beqz	a7,ffffffffc02024c0 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0202342:	000a3603          	ld	a2,0(s4)
ffffffffc0202346:	46a9                	li	a3,10
ffffffffc0202348:	8a2e                	mv	s4,a1
ffffffffc020234a:	bfc1                	j	ffffffffc020231a <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020234c:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0202350:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0202352:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0202354:	bdf1                	j	ffffffffc0202230 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0202356:	85a6                	mv	a1,s1
ffffffffc0202358:	02500513          	li	a0,37
ffffffffc020235c:	9902                	jalr	s2
            break;
ffffffffc020235e:	b545                	j	ffffffffc02021fe <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0202360:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0202364:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0202366:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0202368:	b5e1                	j	ffffffffc0202230 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc020236a:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020236c:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0202370:	01174463          	blt	a4,a7,ffffffffc0202378 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0202374:	14088163          	beqz	a7,ffffffffc02024b6 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0202378:	000a3603          	ld	a2,0(s4)
ffffffffc020237c:	46a1                	li	a3,8
ffffffffc020237e:	8a2e                	mv	s4,a1
ffffffffc0202380:	bf69                	j	ffffffffc020231a <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0202382:	03000513          	li	a0,48
ffffffffc0202386:	85a6                	mv	a1,s1
ffffffffc0202388:	e03e                	sd	a5,0(sp)
ffffffffc020238a:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc020238c:	85a6                	mv	a1,s1
ffffffffc020238e:	07800513          	li	a0,120
ffffffffc0202392:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0202394:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0202396:	6782                	ld	a5,0(sp)
ffffffffc0202398:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc020239a:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc020239e:	bfb5                	j	ffffffffc020231a <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02023a0:	000a3403          	ld	s0,0(s4)
ffffffffc02023a4:	008a0713          	addi	a4,s4,8
ffffffffc02023a8:	e03a                	sd	a4,0(sp)
ffffffffc02023aa:	14040263          	beqz	s0,ffffffffc02024ee <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc02023ae:	0fb05763          	blez	s11,ffffffffc020249c <vprintfmt+0x2d8>
ffffffffc02023b2:	02d00693          	li	a3,45
ffffffffc02023b6:	0cd79163          	bne	a5,a3,ffffffffc0202478 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02023ba:	00044783          	lbu	a5,0(s0)
ffffffffc02023be:	0007851b          	sext.w	a0,a5
ffffffffc02023c2:	cf85                	beqz	a5,ffffffffc02023fa <vprintfmt+0x236>
ffffffffc02023c4:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02023c8:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02023cc:	000c4563          	bltz	s8,ffffffffc02023d6 <vprintfmt+0x212>
ffffffffc02023d0:	3c7d                	addiw	s8,s8,-1
ffffffffc02023d2:	036c0263          	beq	s8,s6,ffffffffc02023f6 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc02023d6:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02023d8:	0e0c8e63          	beqz	s9,ffffffffc02024d4 <vprintfmt+0x310>
ffffffffc02023dc:	3781                	addiw	a5,a5,-32
ffffffffc02023de:	0ef47b63          	bgeu	s0,a5,ffffffffc02024d4 <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc02023e2:	03f00513          	li	a0,63
ffffffffc02023e6:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02023e8:	000a4783          	lbu	a5,0(s4)
ffffffffc02023ec:	3dfd                	addiw	s11,s11,-1
ffffffffc02023ee:	0a05                	addi	s4,s4,1
ffffffffc02023f0:	0007851b          	sext.w	a0,a5
ffffffffc02023f4:	ffe1                	bnez	a5,ffffffffc02023cc <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc02023f6:	01b05963          	blez	s11,ffffffffc0202408 <vprintfmt+0x244>
ffffffffc02023fa:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc02023fc:	85a6                	mv	a1,s1
ffffffffc02023fe:	02000513          	li	a0,32
ffffffffc0202402:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0202404:	fe0d9be3          	bnez	s11,ffffffffc02023fa <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0202408:	6a02                	ld	s4,0(sp)
ffffffffc020240a:	bbd5                	j	ffffffffc02021fe <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc020240c:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020240e:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0202412:	01174463          	blt	a4,a7,ffffffffc020241a <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0202416:	08088d63          	beqz	a7,ffffffffc02024b0 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc020241a:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc020241e:	0a044d63          	bltz	s0,ffffffffc02024d8 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0202422:	8622                	mv	a2,s0
ffffffffc0202424:	8a66                	mv	s4,s9
ffffffffc0202426:	46a9                	li	a3,10
ffffffffc0202428:	bdcd                	j	ffffffffc020231a <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc020242a:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020242e:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0202430:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0202432:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0202436:	8fb5                	xor	a5,a5,a3
ffffffffc0202438:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020243c:	02d74163          	blt	a4,a3,ffffffffc020245e <vprintfmt+0x29a>
ffffffffc0202440:	00369793          	slli	a5,a3,0x3
ffffffffc0202444:	97de                	add	a5,a5,s7
ffffffffc0202446:	639c                	ld	a5,0(a5)
ffffffffc0202448:	cb99                	beqz	a5,ffffffffc020245e <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc020244a:	86be                	mv	a3,a5
ffffffffc020244c:	00002617          	auipc	a2,0x2
ffffffffc0202450:	a7c60613          	addi	a2,a2,-1412 # ffffffffc0203ec8 <slub_sizes+0x50>
ffffffffc0202454:	85a6                	mv	a1,s1
ffffffffc0202456:	854a                	mv	a0,s2
ffffffffc0202458:	0ce000ef          	jal	ra,ffffffffc0202526 <printfmt>
ffffffffc020245c:	b34d                	j	ffffffffc02021fe <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc020245e:	00002617          	auipc	a2,0x2
ffffffffc0202462:	a5a60613          	addi	a2,a2,-1446 # ffffffffc0203eb8 <slub_sizes+0x40>
ffffffffc0202466:	85a6                	mv	a1,s1
ffffffffc0202468:	854a                	mv	a0,s2
ffffffffc020246a:	0bc000ef          	jal	ra,ffffffffc0202526 <printfmt>
ffffffffc020246e:	bb41                	j	ffffffffc02021fe <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0202470:	00002417          	auipc	s0,0x2
ffffffffc0202474:	a4040413          	addi	s0,s0,-1472 # ffffffffc0203eb0 <slub_sizes+0x38>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0202478:	85e2                	mv	a1,s8
ffffffffc020247a:	8522                	mv	a0,s0
ffffffffc020247c:	e43e                	sd	a5,8(sp)
ffffffffc020247e:	0fc000ef          	jal	ra,ffffffffc020257a <strnlen>
ffffffffc0202482:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0202486:	01b05b63          	blez	s11,ffffffffc020249c <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc020248a:	67a2                	ld	a5,8(sp)
ffffffffc020248c:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0202490:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0202492:	85a6                	mv	a1,s1
ffffffffc0202494:	8552                	mv	a0,s4
ffffffffc0202496:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0202498:	fe0d9ce3          	bnez	s11,ffffffffc0202490 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020249c:	00044783          	lbu	a5,0(s0)
ffffffffc02024a0:	00140a13          	addi	s4,s0,1
ffffffffc02024a4:	0007851b          	sext.w	a0,a5
ffffffffc02024a8:	d3a5                	beqz	a5,ffffffffc0202408 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02024aa:	05e00413          	li	s0,94
ffffffffc02024ae:	bf39                	j	ffffffffc02023cc <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc02024b0:	000a2403          	lw	s0,0(s4)
ffffffffc02024b4:	b7ad                	j	ffffffffc020241e <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc02024b6:	000a6603          	lwu	a2,0(s4)
ffffffffc02024ba:	46a1                	li	a3,8
ffffffffc02024bc:	8a2e                	mv	s4,a1
ffffffffc02024be:	bdb1                	j	ffffffffc020231a <vprintfmt+0x156>
ffffffffc02024c0:	000a6603          	lwu	a2,0(s4)
ffffffffc02024c4:	46a9                	li	a3,10
ffffffffc02024c6:	8a2e                	mv	s4,a1
ffffffffc02024c8:	bd89                	j	ffffffffc020231a <vprintfmt+0x156>
ffffffffc02024ca:	000a6603          	lwu	a2,0(s4)
ffffffffc02024ce:	46c1                	li	a3,16
ffffffffc02024d0:	8a2e                	mv	s4,a1
ffffffffc02024d2:	b5a1                	j	ffffffffc020231a <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc02024d4:	9902                	jalr	s2
ffffffffc02024d6:	bf09                	j	ffffffffc02023e8 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc02024d8:	85a6                	mv	a1,s1
ffffffffc02024da:	02d00513          	li	a0,45
ffffffffc02024de:	e03e                	sd	a5,0(sp)
ffffffffc02024e0:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc02024e2:	6782                	ld	a5,0(sp)
ffffffffc02024e4:	8a66                	mv	s4,s9
ffffffffc02024e6:	40800633          	neg	a2,s0
ffffffffc02024ea:	46a9                	li	a3,10
ffffffffc02024ec:	b53d                	j	ffffffffc020231a <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc02024ee:	03b05163          	blez	s11,ffffffffc0202510 <vprintfmt+0x34c>
ffffffffc02024f2:	02d00693          	li	a3,45
ffffffffc02024f6:	f6d79de3          	bne	a5,a3,ffffffffc0202470 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc02024fa:	00002417          	auipc	s0,0x2
ffffffffc02024fe:	9b640413          	addi	s0,s0,-1610 # ffffffffc0203eb0 <slub_sizes+0x38>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0202502:	02800793          	li	a5,40
ffffffffc0202506:	02800513          	li	a0,40
ffffffffc020250a:	00140a13          	addi	s4,s0,1
ffffffffc020250e:	bd6d                	j	ffffffffc02023c8 <vprintfmt+0x204>
ffffffffc0202510:	00002a17          	auipc	s4,0x2
ffffffffc0202514:	9a1a0a13          	addi	s4,s4,-1631 # ffffffffc0203eb1 <slub_sizes+0x39>
ffffffffc0202518:	02800513          	li	a0,40
ffffffffc020251c:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0202520:	05e00413          	li	s0,94
ffffffffc0202524:	b565                	j	ffffffffc02023cc <vprintfmt+0x208>

ffffffffc0202526 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0202526:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0202528:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020252c:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc020252e:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0202530:	ec06                	sd	ra,24(sp)
ffffffffc0202532:	f83a                	sd	a4,48(sp)
ffffffffc0202534:	fc3e                	sd	a5,56(sp)
ffffffffc0202536:	e0c2                	sd	a6,64(sp)
ffffffffc0202538:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc020253a:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc020253c:	c89ff0ef          	jal	ra,ffffffffc02021c4 <vprintfmt>
}
ffffffffc0202540:	60e2                	ld	ra,24(sp)
ffffffffc0202542:	6161                	addi	sp,sp,80
ffffffffc0202544:	8082                	ret

ffffffffc0202546 <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc0202546:	4781                	li	a5,0
ffffffffc0202548:	00006717          	auipc	a4,0x6
ffffffffc020254c:	ac873703          	ld	a4,-1336(a4) # ffffffffc0208010 <SBI_CONSOLE_PUTCHAR>
ffffffffc0202550:	88ba                	mv	a7,a4
ffffffffc0202552:	852a                	mv	a0,a0
ffffffffc0202554:	85be                	mv	a1,a5
ffffffffc0202556:	863e                	mv	a2,a5
ffffffffc0202558:	00000073          	ecall
ffffffffc020255c:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc020255e:	8082                	ret

ffffffffc0202560 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0202560:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0202564:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0202566:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0202568:	cb81                	beqz	a5,ffffffffc0202578 <strlen+0x18>
        cnt ++;
ffffffffc020256a:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc020256c:	00a707b3          	add	a5,a4,a0
ffffffffc0202570:	0007c783          	lbu	a5,0(a5)
ffffffffc0202574:	fbfd                	bnez	a5,ffffffffc020256a <strlen+0xa>
ffffffffc0202576:	8082                	ret
    }
    return cnt;
}
ffffffffc0202578:	8082                	ret

ffffffffc020257a <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc020257a:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc020257c:	e589                	bnez	a1,ffffffffc0202586 <strnlen+0xc>
ffffffffc020257e:	a811                	j	ffffffffc0202592 <strnlen+0x18>
        cnt ++;
ffffffffc0202580:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0202582:	00f58863          	beq	a1,a5,ffffffffc0202592 <strnlen+0x18>
ffffffffc0202586:	00f50733          	add	a4,a0,a5
ffffffffc020258a:	00074703          	lbu	a4,0(a4)
ffffffffc020258e:	fb6d                	bnez	a4,ffffffffc0202580 <strnlen+0x6>
ffffffffc0202590:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0202592:	852e                	mv	a0,a1
ffffffffc0202594:	8082                	ret

ffffffffc0202596 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0202596:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020259a:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020259e:	cb89                	beqz	a5,ffffffffc02025b0 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc02025a0:	0505                	addi	a0,a0,1
ffffffffc02025a2:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02025a4:	fee789e3          	beq	a5,a4,ffffffffc0202596 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02025a8:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc02025ac:	9d19                	subw	a0,a0,a4
ffffffffc02025ae:	8082                	ret
ffffffffc02025b0:	4501                	li	a0,0
ffffffffc02025b2:	bfed                	j	ffffffffc02025ac <strcmp+0x16>

ffffffffc02025b4 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02025b4:	c20d                	beqz	a2,ffffffffc02025d6 <strncmp+0x22>
ffffffffc02025b6:	962e                	add	a2,a2,a1
ffffffffc02025b8:	a031                	j	ffffffffc02025c4 <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc02025ba:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02025bc:	00e79a63          	bne	a5,a4,ffffffffc02025d0 <strncmp+0x1c>
ffffffffc02025c0:	00b60b63          	beq	a2,a1,ffffffffc02025d6 <strncmp+0x22>
ffffffffc02025c4:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc02025c8:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02025ca:	fff5c703          	lbu	a4,-1(a1)
ffffffffc02025ce:	f7f5                	bnez	a5,ffffffffc02025ba <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02025d0:	40e7853b          	subw	a0,a5,a4
}
ffffffffc02025d4:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02025d6:	4501                	li	a0,0
ffffffffc02025d8:	8082                	ret

ffffffffc02025da <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc02025da:	ca01                	beqz	a2,ffffffffc02025ea <memset+0x10>
ffffffffc02025dc:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc02025de:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc02025e0:	0785                	addi	a5,a5,1
ffffffffc02025e2:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc02025e6:	fec79de3          	bne	a5,a2,ffffffffc02025e0 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc02025ea:	8082                	ret
