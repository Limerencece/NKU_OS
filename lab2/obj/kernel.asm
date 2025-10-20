
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
kern_entry:
    # a0: hartid（当前硬件线程/内核编号）
    # a1: dtb physical address（设备树的物理地址，由上电/引导传入）
    # 保存hartid和dtb地址到全局变量，供C代码使用
    # 下面四句初始化的，与物理内存管理机制关系不大
    la t0, boot_hartid      # 取boot_hartid符号的当前地址（虚拟地址）
ffffffffc0200000:	00007297          	auipc	t0,0x7
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)            # 将hartid保存到内存
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0207000 <boot_hartid>
    la t0, boot_dtb         # 取boot_dtb符号的当前地址（虚拟地址）
ffffffffc020000c:	00007297          	auipc	t0,0x7
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0207008 <boot_dtb>
    sd a1, 0(t0)            # 将dtb物理地址保存到内存
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址（boot_page_table_sv39在链接时位于内核镜像中）
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02062b7          	lui	t0,0xc0206
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
ffffffffc020003c:	c0206137          	lui	sp,0xc0206

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
ffffffffc0200050:	fec50513          	addi	a0,a0,-20 # ffffffffc0202038 <etext+0x4>
void print_kerninfo(void) {
ffffffffc0200054:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200056:	0f6000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", (uintptr_t)kern_init); // 内核入口虚拟地址
ffffffffc020005a:	00000597          	auipc	a1,0x0
ffffffffc020005e:	07e58593          	addi	a1,a1,126 # ffffffffc02000d8 <kern_init>
ffffffffc0200062:	00002517          	auipc	a0,0x2
ffffffffc0200066:	ff650513          	addi	a0,a0,-10 # ffffffffc0202058 <etext+0x24>
ffffffffc020006a:	0e2000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);                 // 文本段结束虚拟地址
ffffffffc020006e:	00002597          	auipc	a1,0x2
ffffffffc0200072:	fc658593          	addi	a1,a1,-58 # ffffffffc0202034 <etext>
ffffffffc0200076:	00002517          	auipc	a0,0x2
ffffffffc020007a:	00250513          	addi	a0,a0,2 # ffffffffc0202078 <etext+0x44>
ffffffffc020007e:	0ce000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);                 // 数据段结束虚拟地址
ffffffffc0200082:	00007597          	auipc	a1,0x7
ffffffffc0200086:	f9658593          	addi	a1,a1,-106 # ffffffffc0207018 <buddy>
ffffffffc020008a:	00002517          	auipc	a0,0x2
ffffffffc020008e:	00e50513          	addi	a0,a0,14 # ffffffffc0202098 <etext+0x64>
ffffffffc0200092:	0ba000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);                   // BSS段结束虚拟地址
ffffffffc0200096:	0000b597          	auipc	a1,0xb
ffffffffc020009a:	1a258593          	addi	a1,a1,418 # ffffffffc020b238 <end>
ffffffffc020009e:	00002517          	auipc	a0,0x2
ffffffffc02000a2:	01a50513          	addi	a0,a0,26 # ffffffffc02020b8 <etext+0x84>
ffffffffc02000a6:	0a6000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - (char*)kern_init + 1023) / 1024); // 内核镜像占用大小（入口到end）
ffffffffc02000aa:	0000b597          	auipc	a1,0xb
ffffffffc02000ae:	58d58593          	addi	a1,a1,1421 # ffffffffc020b637 <end+0x3ff>
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
ffffffffc02000d0:	00c50513          	addi	a0,a0,12 # ffffffffc02020d8 <etext+0xa4>
}
ffffffffc02000d4:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000d6:	a89d                	j	ffffffffc020014c <cprintf>

ffffffffc02000d8 <kern_init>:

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata); // 清零BSS段，保证未初始化全局/静态变量为0
ffffffffc02000d8:	00007517          	auipc	a0,0x7
ffffffffc02000dc:	f4050513          	addi	a0,a0,-192 # ffffffffc0207018 <buddy>
ffffffffc02000e0:	0000b617          	auipc	a2,0xb
ffffffffc02000e4:	15860613          	addi	a2,a2,344 # ffffffffc020b238 <end>
int kern_init(void) {
ffffffffc02000e8:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata); // 清零BSS段，保证未初始化全局/静态变量为0
ffffffffc02000ea:	8e09                	sub	a2,a2,a0
ffffffffc02000ec:	4581                	li	a1,0
int kern_init(void) {
ffffffffc02000ee:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata); // 清零BSS段，保证未初始化全局/静态变量为0
ffffffffc02000f0:	733010ef          	jal	ra,ffffffffc0202022 <memset>
    dtb_init();                    // 解析设备树，探测可用物理内存及硬件拓扑
ffffffffc02000f4:	12c000ef          	jal	ra,ffffffffc0200220 <dtb_init>
    cons_init();                   // 初始化控制台子系统，后续可用cprintf/cputs输出
ffffffffc02000f8:	11e000ef          	jal	ra,ffffffffc0200216 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0"; // 启动提示信息
    //cprintf("%s\n\n", message);
    cputs(message);               // 简单字符串输出（不带格式化）
ffffffffc02000fc:	00002517          	auipc	a0,0x2
ffffffffc0200100:	00c50513          	addi	a0,a0,12 # ffffffffc0202108 <etext+0xd4>
ffffffffc0200104:	07e000ef          	jal	ra,ffffffffc0200182 <cputs>

    print_kerninfo();             // 打印内核入口/段边界等信息，便于调试与核验
ffffffffc0200108:	f43ff0ef          	jal	ra,ffffffffc020004a <print_kerninfo>

    // grade_backtrace();
    pmm_init();                   // 物理内存管理初始化：分页大小、页框状态、空闲链表等
ffffffffc020010c:	112010ef          	jal	ra,ffffffffc020121e <pmm_init>

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
ffffffffc0200140:	2cd010ef          	jal	ra,ffffffffc0201c0c <vprintfmt>
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
ffffffffc020014e:	02810313          	addi	t1,sp,40 # ffffffffc0206028 <boot_page_table_sv39+0x28>
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
ffffffffc0200176:	297010ef          	jal	ra,ffffffffc0201c0c <vprintfmt>
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
ffffffffc02001c2:	0000b317          	auipc	t1,0xb
ffffffffc02001c6:	02e30313          	addi	t1,t1,46 # ffffffffc020b1f0 <is_panic>
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
ffffffffc02001f6:	f3650513          	addi	a0,a0,-202 # ffffffffc0202128 <etext+0xf4>
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
ffffffffc020020c:	ef850513          	addi	a0,a0,-264 # ffffffffc0202100 <etext+0xcc>
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
ffffffffc020021c:	5730106f          	j	ffffffffc0201f8e <sbi_console_putchar>

ffffffffc0200220 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;   // 内存基地址
static uint64_t memory_size = 0;   // 内存大小

void dtb_init(void) {
ffffffffc0200220:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc0200222:	00002517          	auipc	a0,0x2
ffffffffc0200226:	f2650513          	addi	a0,a0,-218 # ffffffffc0202148 <etext+0x114>
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
ffffffffc0200248:	00007597          	auipc	a1,0x7
ffffffffc020024c:	db85b583          	ld	a1,-584(a1) # ffffffffc0207000 <boot_hartid>
ffffffffc0200250:	00002517          	auipc	a0,0x2
ffffffffc0200254:	f0850513          	addi	a0,a0,-248 # ffffffffc0202158 <etext+0x124>
ffffffffc0200258:	ef5ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);  // 打印DTB地址
ffffffffc020025c:	00007417          	auipc	s0,0x7
ffffffffc0200260:	dac40413          	addi	s0,s0,-596 # ffffffffc0207008 <boot_dtb>
ffffffffc0200264:	600c                	ld	a1,0(s0)
ffffffffc0200266:	00002517          	auipc	a0,0x2
ffffffffc020026a:	f0250513          	addi	a0,a0,-254 # ffffffffc0202168 <etext+0x134>
ffffffffc020026e:	edfff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200272:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");  // DTB地址为空错误
ffffffffc0200276:	00002517          	auipc	a0,0x2
ffffffffc020027a:	f0a50513          	addi	a0,a0,-246 # ffffffffc0202180 <etext+0x14c>
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
ffffffffc02002be:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed4cb5>
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
ffffffffc0200334:	ea090913          	addi	s2,s2,-352 # ffffffffc02021d0 <etext+0x19c>
ffffffffc0200338:	49bd                	li	s3,15
        switch (token) {
ffffffffc020033a:	4d91                	li	s11,4
ffffffffc020033c:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020033e:	00002497          	auipc	s1,0x2
ffffffffc0200342:	e8a48493          	addi	s1,s1,-374 # ffffffffc02021c8 <etext+0x194>
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
ffffffffc0200396:	eb650513          	addi	a0,a0,-330 # ffffffffc0202248 <etext+0x214>
ffffffffc020039a:	db3ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    }
    cprintf("DTB init completed\n");  // DTB初始化完成
ffffffffc020039e:	00002517          	auipc	a0,0x2
ffffffffc02003a2:	ee250513          	addi	a0,a0,-286 # ffffffffc0202280 <etext+0x24c>
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
ffffffffc02003e2:	dc250513          	addi	a0,a0,-574 # ffffffffc02021a0 <etext+0x16c>
}
ffffffffc02003e6:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);  // 魔数验证失败
ffffffffc02003e8:	b395                	j	ffffffffc020014c <cprintf>
                int name_len = strlen(name);
ffffffffc02003ea:	8556                	mv	a0,s5
ffffffffc02003ec:	3bd010ef          	jal	ra,ffffffffc0201fa8 <strlen>
ffffffffc02003f0:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003f2:	4619                	li	a2,6
ffffffffc02003f4:	85a6                	mv	a1,s1
ffffffffc02003f6:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc02003f8:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003fa:	403010ef          	jal	ra,ffffffffc0201ffc <strncmp>
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
ffffffffc0200490:	34f010ef          	jal	ra,ffffffffc0201fde <strcmp>
ffffffffc0200494:	66a2                	ld	a3,8(sp)
ffffffffc0200496:	f94d                	bnez	a0,ffffffffc0200448 <dtb_init+0x228>
ffffffffc0200498:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200448 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);  // 内存基地址
ffffffffc020049c:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);  // 内存大小
ffffffffc02004a0:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc02004a4:	00002517          	auipc	a0,0x2
ffffffffc02004a8:	d3450513          	addi	a0,a0,-716 # ffffffffc02021d8 <etext+0x1a4>
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
ffffffffc0200576:	c8650513          	addi	a0,a0,-890 # ffffffffc02021f8 <etext+0x1c4>
ffffffffc020057a:	bd3ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));  // 内存大小
ffffffffc020057e:	014b5613          	srli	a2,s6,0x14
ffffffffc0200582:	85da                	mv	a1,s6
ffffffffc0200584:	00002517          	auipc	a0,0x2
ffffffffc0200588:	c8c50513          	addi	a0,a0,-884 # ffffffffc0202210 <etext+0x1dc>
ffffffffc020058c:	bc1ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);  // 内存结束地址
ffffffffc0200590:	008b05b3          	add	a1,s6,s0
ffffffffc0200594:	15fd                	addi	a1,a1,-1
ffffffffc0200596:	00002517          	auipc	a0,0x2
ffffffffc020059a:	c9a50513          	addi	a0,a0,-870 # ffffffffc0202230 <etext+0x1fc>
ffffffffc020059e:	bafff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("DTB init completed\n");  // DTB初始化完成
ffffffffc02005a2:	00002517          	auipc	a0,0x2
ffffffffc02005a6:	cde50513          	addi	a0,a0,-802 # ffffffffc0202280 <etext+0x24c>
        memory_base = mem_base;  // 设置全局内存基地址
ffffffffc02005aa:	0000b797          	auipc	a5,0xb
ffffffffc02005ae:	c487b723          	sd	s0,-946(a5) # ffffffffc020b1f8 <memory_base>
        memory_size = mem_size;  // 设置全局内存大小
ffffffffc02005b2:	0000b797          	auipc	a5,0xb
ffffffffc02005b6:	c567b723          	sd	s6,-946(a5) # ffffffffc020b200 <memory_size>
    cprintf("DTB init completed\n");  // DTB初始化完成
ffffffffc02005ba:	b3f5                	j	ffffffffc02003a6 <dtb_init+0x186>

ffffffffc02005bc <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;  // 获取内存基地址
}
ffffffffc02005bc:	0000b517          	auipc	a0,0xb
ffffffffc02005c0:	c3c53503          	ld	a0,-964(a0) # ffffffffc020b1f8 <memory_base>
ffffffffc02005c4:	8082                	ret

ffffffffc02005c6 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;  // 获取内存大小
ffffffffc02005c6:	0000b517          	auipc	a0,0xb
ffffffffc02005ca:	c3a53503          	ld	a0,-966(a0) # ffffffffc020b200 <memory_size>
ffffffffc02005ce:	8082                	ret

ffffffffc02005d0 <buddy_init>:

static void
buddy_init(void) {
    // 初始化buddy system，这里暂时不分配内存
    // 实际的初始化在buddy_init_memmap中进行
    buddy.size = 0;         // 初始大小为0
ffffffffc02005d0:	00007797          	auipc	a5,0x7
ffffffffc02005d4:	a4878793          	addi	a5,a5,-1464 # ffffffffc0207018 <buddy>
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
ffffffffc02005e6:	00007797          	auipc	a5,0x7
ffffffffc02005ea:	a3a7b783          	ld	a5,-1478(a5) # ffffffffc0207020 <buddy+0x8>
ffffffffc02005ee:	c781                	beqz	a5,ffffffffc02005f6 <buddy_nr_free_pages+0x10>
        return 0;               // 返回0
    return buddy.longest[0];    // 返回根节点的可用大小
ffffffffc02005f0:	0007e503          	lwu	a0,0(a5)
ffffffffc02005f4:	8082                	ret
        return 0;               // 返回0
ffffffffc02005f6:	4501                	li	a0,0
}
ffffffffc02005f8:	8082                	ret

ffffffffc02005fa <buddy_free_pages>:
buddy_free_pages(struct Page *base, size_t n) {
ffffffffc02005fa:	1141                	addi	sp,sp,-16
ffffffffc02005fc:	e406                	sd	ra,8(sp)
    assert(n > 0);          // 确保释放页面数大于0
ffffffffc02005fe:	10058d63          	beqz	a1,ffffffffc0200718 <buddy_free_pages+0x11e>
    assert(base >= buddy.base && base < buddy.base + buddy.size);  // 检查页面有效性
ffffffffc0200602:	00007617          	auipc	a2,0x7
ffffffffc0200606:	a1660613          	addi	a2,a2,-1514 # ffffffffc0207018 <buddy>
ffffffffc020060a:	6a1c                	ld	a5,16(a2)
ffffffffc020060c:	0ef56663          	bltu	a0,a5,ffffffffc02006f8 <buddy_free_pages+0xfe>
ffffffffc0200610:	4218                	lw	a4,0(a2)
ffffffffc0200612:	02071813          	slli	a6,a4,0x20
ffffffffc0200616:	02085813          	srli	a6,a6,0x20
ffffffffc020061a:	00281693          	slli	a3,a6,0x2
ffffffffc020061e:	96c2                	add	a3,a3,a6
ffffffffc0200620:	068e                	slli	a3,a3,0x3
ffffffffc0200622:	96be                	add	a3,a3,a5
ffffffffc0200624:	0cd57a63          	bgeu	a0,a3,ffffffffc02006f8 <buddy_free_pages+0xfe>
    unsigned offset = base - buddy.base;  // 计算页面在数组中的偏移
ffffffffc0200628:	40f507b3          	sub	a5,a0,a5
ffffffffc020062c:	878d                	srai	a5,a5,0x3
ffffffffc020062e:	00003697          	auipc	a3,0x3
ffffffffc0200632:	cf26b683          	ld	a3,-782(a3) # ffffffffc0203320 <error_string+0x38>
ffffffffc0200636:	02d786b3          	mul	a3,a5,a3
    unsigned index = offset + buddy.size - 1;  // 计算叶子节点索引
ffffffffc020063a:	fff7079b          	addiw	a5,a4,-1
    for (; buddy.longest[index]; index = PARENT(index)) {  // 向上查找直到找到已分配的节点
ffffffffc020063e:	00863883          	ld	a7,8(a2)
    unsigned index = offset + buddy.size - 1;  // 计算叶子节点索引
ffffffffc0200642:	9fb5                	addw	a5,a5,a3
    for (; buddy.longest[index]; index = PARENT(index)) {  // 向上查找直到找到已分配的节点
ffffffffc0200644:	02079693          	slli	a3,a5,0x20
ffffffffc0200648:	01e6d713          	srli	a4,a3,0x1e
ffffffffc020064c:	9746                	add	a4,a4,a7
ffffffffc020064e:	4314                	lw	a3,0(a4)
ffffffffc0200650:	c2cd                	beqz	a3,ffffffffc02006f2 <buddy_free_pages+0xf8>
        node_size *= 2;     // 节点大小加倍
ffffffffc0200652:	4689                	li	a3,2
        if (index == 0)     // 如果到达根节点
ffffffffc0200654:	e789                	bnez	a5,ffffffffc020065e <buddy_free_pages+0x64>
ffffffffc0200656:	a849                	j	ffffffffc02006e8 <buddy_free_pages+0xee>
        node_size *= 2;     // 节点大小加倍
ffffffffc0200658:	0016969b          	slliw	a3,a3,0x1
        if (index == 0)     // 如果到达根节点
ffffffffc020065c:	c7d1                	beqz	a5,ffffffffc02006e8 <buddy_free_pages+0xee>
    for (; buddy.longest[index]; index = PARENT(index)) {  // 向上查找直到找到已分配的节点
ffffffffc020065e:	2785                	addiw	a5,a5,1
ffffffffc0200660:	0017d79b          	srliw	a5,a5,0x1
ffffffffc0200664:	37fd                	addiw	a5,a5,-1
ffffffffc0200666:	02079613          	slli	a2,a5,0x20
ffffffffc020066a:	01e65713          	srli	a4,a2,0x1e
ffffffffc020066e:	9746                	add	a4,a4,a7
ffffffffc0200670:	4310                	lw	a2,0(a4)
ffffffffc0200672:	f27d                	bnez	a2,ffffffffc0200658 <buddy_free_pages+0x5e>
    buddy.longest[index] = node_size;  // 设置节点大小为原始大小
ffffffffc0200674:	c314                	sw	a3,0(a4)
    while (index) {         // 从当前节点向上直到根节点
ffffffffc0200676:	cbb1                	beqz	a5,ffffffffc02006ca <buddy_free_pages+0xd0>
        index = PARENT(index);          // 移动到父节点
ffffffffc0200678:	2785                	addiw	a5,a5,1
ffffffffc020067a:	0017d81b          	srliw	a6,a5,0x1
ffffffffc020067e:	387d                	addiw	a6,a6,-1
        unsigned right_longest = buddy.longest[RIGHT_LEAF(index)]; // 右子节点大小
ffffffffc0200680:	ffe7f713          	andi	a4,a5,-2
        unsigned left_longest = buddy.longest[LEFT_LEAF(index)];   // 左子节点大小
ffffffffc0200684:	0018161b          	slliw	a2,a6,0x1
ffffffffc0200688:	2605                	addiw	a2,a2,1
        unsigned right_longest = buddy.longest[RIGHT_LEAF(index)]; // 右子节点大小
ffffffffc020068a:	1702                	slli	a4,a4,0x20
        unsigned left_longest = buddy.longest[LEFT_LEAF(index)];   // 左子节点大小
ffffffffc020068c:	02061793          	slli	a5,a2,0x20
        unsigned right_longest = buddy.longest[RIGHT_LEAF(index)]; // 右子节点大小
ffffffffc0200690:	9301                	srli	a4,a4,0x20
        unsigned left_longest = buddy.longest[LEFT_LEAF(index)];   // 左子节点大小
ffffffffc0200692:	01e7d613          	srli	a2,a5,0x1e
        unsigned right_longest = buddy.longest[RIGHT_LEAF(index)]; // 右子节点大小
ffffffffc0200696:	070a                	slli	a4,a4,0x2
ffffffffc0200698:	9746                	add	a4,a4,a7
        unsigned left_longest = buddy.longest[LEFT_LEAF(index)];   // 左子节点大小
ffffffffc020069a:	9646                	add	a2,a2,a7
        unsigned right_longest = buddy.longest[RIGHT_LEAF(index)]; // 右子节点大小
ffffffffc020069c:	00072303          	lw	t1,0(a4)
        unsigned left_longest = buddy.longest[LEFT_LEAF(index)];   // 左子节点大小
ffffffffc02006a0:	4210                	lw	a2,0(a2)
            buddy.longest[index] = node_size;           // 合并为父节点大小
ffffffffc02006a2:	02081793          	slli	a5,a6,0x20
ffffffffc02006a6:	01e7d713          	srli	a4,a5,0x1e
        node_size *= 2;                 // 节点大小加倍
ffffffffc02006aa:	0016969b          	slliw	a3,a3,0x1
        if (left_longest + right_longest == node_size)  // 如果子节点大小之和等于父节点大小
ffffffffc02006ae:	00660ebb          	addw	t4,a2,t1
        index = PARENT(index);          // 移动到父节点
ffffffffc02006b2:	0008079b          	sext.w	a5,a6
            buddy.longest[index] = node_size;           // 合并为父节点大小
ffffffffc02006b6:	9746                	add	a4,a4,a7
        if (left_longest + right_longest == node_size)  // 如果子节点大小之和等于父节点大小
ffffffffc02006b8:	02de8b63          	beq	t4,a3,ffffffffc02006ee <buddy_free_pages+0xf4>
            buddy.longest[index] = MAX(left_longest, right_longest);  // 否则取最大值
ffffffffc02006bc:	8832                	mv	a6,a2
ffffffffc02006be:	00667363          	bgeu	a2,t1,ffffffffc02006c4 <buddy_free_pages+0xca>
ffffffffc02006c2:	881a                	mv	a6,t1
ffffffffc02006c4:	01072023          	sw	a6,0(a4)
    while (index) {         // 从当前节点向上直到根节点
ffffffffc02006c8:	fbc5                	bnez	a5,ffffffffc0200678 <buddy_free_pages+0x7e>
    for (; p != base + n; p++) {  // 遍历所有要释放的页面
ffffffffc02006ca:	00259793          	slli	a5,a1,0x2
ffffffffc02006ce:	97ae                	add	a5,a5,a1
ffffffffc02006d0:	078e                	slli	a5,a5,0x3
ffffffffc02006d2:	97aa                	add	a5,a5,a0
ffffffffc02006d4:	00a78a63          	beq	a5,a0,ffffffffc02006e8 <buddy_free_pages+0xee>
        p->flags = 0;       // 清空页面标志
ffffffffc02006d8:	00053423          	sd	zero,8(a0)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc02006dc:	00052023          	sw	zero,0(a0)
    for (; p != base + n; p++) {  // 遍历所有要释放的页面
ffffffffc02006e0:	02850513          	addi	a0,a0,40
ffffffffc02006e4:	fea79ae3          	bne	a5,a0,ffffffffc02006d8 <buddy_free_pages+0xde>
}
ffffffffc02006e8:	60a2                	ld	ra,8(sp)
ffffffffc02006ea:	0141                	addi	sp,sp,16
ffffffffc02006ec:	8082                	ret
            buddy.longest[index] = node_size;           // 合并为父节点大小
ffffffffc02006ee:	c314                	sw	a3,0(a4)
ffffffffc02006f0:	b759                	j	ffffffffc0200676 <buddy_free_pages+0x7c>
    unsigned node_size = 1;  // 初始节点大小为1
ffffffffc02006f2:	4685                	li	a3,1
    buddy.longest[index] = node_size;  // 设置节点大小为原始大小
ffffffffc02006f4:	c314                	sw	a3,0(a4)
ffffffffc02006f6:	b741                	j	ffffffffc0200676 <buddy_free_pages+0x7c>
    assert(base >= buddy.base && base < buddy.base + buddy.size);  // 检查页面有效性
ffffffffc02006f8:	00002697          	auipc	a3,0x2
ffffffffc02006fc:	be068693          	addi	a3,a3,-1056 # ffffffffc02022d8 <etext+0x2a4>
ffffffffc0200700:	00002617          	auipc	a2,0x2
ffffffffc0200704:	ba060613          	addi	a2,a2,-1120 # ffffffffc02022a0 <etext+0x26c>
ffffffffc0200708:	0ac00593          	li	a1,172
ffffffffc020070c:	00002517          	auipc	a0,0x2
ffffffffc0200710:	bac50513          	addi	a0,a0,-1108 # ffffffffc02022b8 <etext+0x284>
ffffffffc0200714:	aafff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(n > 0);          // 确保释放页面数大于0
ffffffffc0200718:	00002697          	auipc	a3,0x2
ffffffffc020071c:	b8068693          	addi	a3,a3,-1152 # ffffffffc0202298 <etext+0x264>
ffffffffc0200720:	00002617          	auipc	a2,0x2
ffffffffc0200724:	b8060613          	addi	a2,a2,-1152 # ffffffffc02022a0 <etext+0x26c>
ffffffffc0200728:	0ab00593          	li	a1,171
ffffffffc020072c:	00002517          	auipc	a0,0x2
ffffffffc0200730:	b8c50513          	addi	a0,a0,-1140 # ffffffffc02022b8 <etext+0x284>
ffffffffc0200734:	a8fff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200738 <buddy_alloc_pages>:
    assert(n > 0);          // 确保请求页面数大于0
ffffffffc0200738:	c56d                	beqz	a0,ffffffffc0200822 <buddy_alloc_pages+0xea>
    if (buddy.longest == NULL || n > buddy.size) {  // 检查参数有效性
ffffffffc020073a:	00007817          	auipc	a6,0x7
ffffffffc020073e:	8de80813          	addi	a6,a6,-1826 # ffffffffc0207018 <buddy>
ffffffffc0200742:	86aa                	mv	a3,a0
ffffffffc0200744:	00883503          	ld	a0,8(a6)
ffffffffc0200748:	c961                	beqz	a0,ffffffffc0200818 <buddy_alloc_pages+0xe0>
ffffffffc020074a:	00082883          	lw	a7,0(a6)
ffffffffc020074e:	02089793          	slli	a5,a7,0x20
ffffffffc0200752:	9381                	srli	a5,a5,0x20
ffffffffc0200754:	0cd7e163          	bltu	a5,a3,ffffffffc0200816 <buddy_alloc_pages+0xde>
    while (size < n) size <<= 1;  // 循环左移直到找到不小于n的2的幂
ffffffffc0200758:	4785                	li	a5,1
    unsigned size = 1;      // 初始大小为1
ffffffffc020075a:	4705                	li	a4,1
    while (size < n) size <<= 1;  // 循环左移直到找到不小于n的2的幂
ffffffffc020075c:	00f68963          	beq	a3,a5,ffffffffc020076e <buddy_alloc_pages+0x36>
ffffffffc0200760:	0017171b          	slliw	a4,a4,0x1
ffffffffc0200764:	02071793          	slli	a5,a4,0x20
ffffffffc0200768:	9381                	srli	a5,a5,0x20
ffffffffc020076a:	fed7ebe3          	bltu	a5,a3,ffffffffc0200760 <buddy_alloc_pages+0x28>
    if (buddy.longest[index] < size)  // 如果根节点可用大小不足
ffffffffc020076e:	411c                	lw	a5,0(a0)
ffffffffc0200770:	0ae7e363          	bltu	a5,a4,ffffffffc0200816 <buddy_alloc_pages+0xde>
    for (node_size = buddy.size; node_size != size; node_size /= 2) {  // 从最大节点大小开始
ffffffffc0200774:	0ae88363          	beq	a7,a4,ffffffffc020081a <buddy_alloc_pages+0xe2>
ffffffffc0200778:	8646                	mv	a2,a7
    unsigned index = 0;     // 从根节点开始（索引0）
ffffffffc020077a:	4781                	li	a5,0
        if (buddy.longest[LEFT_LEAF(index)] >= size)  // 如果左子节点足够大
ffffffffc020077c:	0017959b          	slliw	a1,a5,0x1
ffffffffc0200780:	0015879b          	addiw	a5,a1,1
ffffffffc0200784:	02079313          	slli	t1,a5,0x20
ffffffffc0200788:	01e35693          	srli	a3,t1,0x1e
ffffffffc020078c:	96aa                	add	a3,a3,a0
ffffffffc020078e:	4294                	lw	a3,0(a3)
ffffffffc0200790:	00e6f463          	bgeu	a3,a4,ffffffffc0200798 <buddy_alloc_pages+0x60>
            index = RIGHT_LEAF(index);                // 否则选择右子节点
ffffffffc0200794:	0025879b          	addiw	a5,a1,2
    for (node_size = buddy.size; node_size != size; node_size /= 2) {  // 从最大节点大小开始
ffffffffc0200798:	0016561b          	srliw	a2,a2,0x1
ffffffffc020079c:	fee610e3          	bne	a2,a4,ffffffffc020077c <buddy_alloc_pages+0x44>
    unsigned offset = (index + 1) * node_size - buddy.size;  // 计算页面在数组中的偏移
ffffffffc02007a0:	0017871b          	addiw	a4,a5,1
ffffffffc02007a4:	02c7063b          	mulw	a2,a4,a2
    buddy.longest[index] = 0;  // 设置节点大小为0表示已分配
ffffffffc02007a8:	02079593          	slli	a1,a5,0x20
ffffffffc02007ac:	01e5d693          	srli	a3,a1,0x1e
ffffffffc02007b0:	96aa                	add	a3,a3,a0
ffffffffc02007b2:	0006a023          	sw	zero,0(a3)
    unsigned offset = (index + 1) * node_size - buddy.size;  // 计算页面在数组中的偏移
ffffffffc02007b6:	4116063b          	subw	a2,a2,a7
    return buddy.base + offset;  // 返回页面指针
ffffffffc02007ba:	1602                	slli	a2,a2,0x20
ffffffffc02007bc:	9201                	srli	a2,a2,0x20
ffffffffc02007be:	00261693          	slli	a3,a2,0x2
ffffffffc02007c2:	9636                	add	a2,a2,a3
ffffffffc02007c4:	060e                	slli	a2,a2,0x3
    while (index) {         // 从当前节点向上直到根节点
ffffffffc02007c6:	e781                	bnez	a5,ffffffffc02007ce <buddy_alloc_pages+0x96>
ffffffffc02007c8:	a099                	j	ffffffffc020080e <buddy_alloc_pages+0xd6>
ffffffffc02007ca:	0017871b          	addiw	a4,a5,1
        index = PARENT(index);                          // 移动到父节点
ffffffffc02007ce:	0017579b          	srliw	a5,a4,0x1
ffffffffc02007d2:	37fd                	addiw	a5,a5,-1
        buddy.longest[index] = MAX(buddy.longest[LEFT_LEAF(index)],  // 左子节点大小
ffffffffc02007d4:	0017969b          	slliw	a3,a5,0x1
ffffffffc02007d8:	9b79                	andi	a4,a4,-2
ffffffffc02007da:	2685                	addiw	a3,a3,1
ffffffffc02007dc:	1702                	slli	a4,a4,0x20
ffffffffc02007de:	02069593          	slli	a1,a3,0x20
ffffffffc02007e2:	9301                	srli	a4,a4,0x20
ffffffffc02007e4:	01e5d693          	srli	a3,a1,0x1e
ffffffffc02007e8:	070a                	slli	a4,a4,0x2
ffffffffc02007ea:	972a                	add	a4,a4,a0
ffffffffc02007ec:	96aa                	add	a3,a3,a0
ffffffffc02007ee:	430c                	lw	a1,0(a4)
ffffffffc02007f0:	4294                	lw	a3,0(a3)
ffffffffc02007f2:	02079893          	slli	a7,a5,0x20
ffffffffc02007f6:	01e8d713          	srli	a4,a7,0x1e
ffffffffc02007fa:	0006831b          	sext.w	t1,a3
ffffffffc02007fe:	0005889b          	sext.w	a7,a1
ffffffffc0200802:	972a                	add	a4,a4,a0
ffffffffc0200804:	01137363          	bgeu	t1,a7,ffffffffc020080a <buddy_alloc_pages+0xd2>
ffffffffc0200808:	86ae                	mv	a3,a1
ffffffffc020080a:	c314                	sw	a3,0(a4)
    while (index) {         // 从当前节点向上直到根节点
ffffffffc020080c:	ffdd                	bnez	a5,ffffffffc02007ca <buddy_alloc_pages+0x92>
    return buddy.base + offset;  // 返回页面指针
ffffffffc020080e:	01083503          	ld	a0,16(a6)
ffffffffc0200812:	9532                	add	a0,a0,a2
ffffffffc0200814:	8082                	ret
        return NULL;        // 如果未初始化或请求过大，返回NULL
ffffffffc0200816:	4501                	li	a0,0
}
ffffffffc0200818:	8082                	ret
    buddy.longest[index] = 0;  // 设置节点大小为0表示已分配
ffffffffc020081a:	00052023          	sw	zero,0(a0)
ffffffffc020081e:	4601                	li	a2,0
ffffffffc0200820:	b7fd                	j	ffffffffc020080e <buddy_alloc_pages+0xd6>
buddy_alloc_pages(size_t n) {
ffffffffc0200822:	1141                	addi	sp,sp,-16
    assert(n > 0);          // 确保请求页面数大于0
ffffffffc0200824:	00002697          	auipc	a3,0x2
ffffffffc0200828:	a7468693          	addi	a3,a3,-1420 # ffffffffc0202298 <etext+0x264>
ffffffffc020082c:	00002617          	auipc	a2,0x2
ffffffffc0200830:	a7460613          	addi	a2,a2,-1420 # ffffffffc02022a0 <etext+0x26c>
ffffffffc0200834:	07f00593          	li	a1,127
ffffffffc0200838:	00002517          	auipc	a0,0x2
ffffffffc020083c:	a8050513          	addi	a0,a0,-1408 # ffffffffc02022b8 <etext+0x284>
buddy_alloc_pages(size_t n) {
ffffffffc0200840:	e406                	sd	ra,8(sp)
    assert(n > 0);          // 确保请求页面数大于0
ffffffffc0200842:	981ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200846 <buddy_check>:
    free_page(p2);          // 释放第3个页面
}

// Buddy system专用的测试函数
static void
buddy_check(void) {
ffffffffc0200846:	714d                	addi	sp,sp,-336
    assert((p0 = alloc_page()) != NULL);  // 分配第1个页面
ffffffffc0200848:	4505                	li	a0,1
buddy_check(void) {
ffffffffc020084a:	e686                	sd	ra,328(sp)
ffffffffc020084c:	e2a2                	sd	s0,320(sp)
ffffffffc020084e:	fe26                	sd	s1,312(sp)
ffffffffc0200850:	fa4a                	sd	s2,304(sp)
ffffffffc0200852:	f64e                	sd	s3,296(sp)
ffffffffc0200854:	f252                	sd	s4,288(sp)
ffffffffc0200856:	ee56                	sd	s5,280(sp)
ffffffffc0200858:	ea5a                	sd	s6,272(sp)
ffffffffc020085a:	e65e                	sd	s7,264(sp)
ffffffffc020085c:	e262                	sd	s8,256(sp)
    assert((p0 = alloc_page()) != NULL);  // 分配第1个页面
ffffffffc020085e:	1a9000ef          	jal	ra,ffffffffc0201206 <alloc_pages>
ffffffffc0200862:	78050863          	beqz	a0,ffffffffc0200ff2 <buddy_check+0x7ac>
ffffffffc0200866:	892a                	mv	s2,a0
    assert((p1 = alloc_page()) != NULL);  // 分配第2个页面
ffffffffc0200868:	4505                	li	a0,1
ffffffffc020086a:	19d000ef          	jal	ra,ffffffffc0201206 <alloc_pages>
ffffffffc020086e:	84aa                	mv	s1,a0
ffffffffc0200870:	76050163          	beqz	a0,ffffffffc0200fd2 <buddy_check+0x78c>
    assert((p2 = alloc_page()) != NULL);  // 分配第3个页面
ffffffffc0200874:	4505                	li	a0,1
ffffffffc0200876:	191000ef          	jal	ra,ffffffffc0201206 <alloc_pages>
ffffffffc020087a:	842a                	mv	s0,a0
ffffffffc020087c:	72050b63          	beqz	a0,ffffffffc0200fb2 <buddy_check+0x76c>
    assert(p0 != p1 && p0 != p2 && p1 != p2);  // 确保页面地址不同
ffffffffc0200880:	5e990963          	beq	s2,s1,ffffffffc0200e72 <buddy_check+0x62c>
ffffffffc0200884:	5ea90763          	beq	s2,a0,ffffffffc0200e72 <buddy_check+0x62c>
ffffffffc0200888:	5ea48563          	beq	s1,a0,ffffffffc0200e72 <buddy_check+0x62c>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);  // 引用计数为0
ffffffffc020088c:	00092783          	lw	a5,0(s2)
ffffffffc0200890:	5c079163          	bnez	a5,ffffffffc0200e52 <buddy_check+0x60c>
ffffffffc0200894:	409c                	lw	a5,0(s1)
ffffffffc0200896:	5a079e63          	bnez	a5,ffffffffc0200e52 <buddy_check+0x60c>
static inline int page_ref(struct Page *page) { return page->ref; }
ffffffffc020089a:	00052983          	lw	s3,0(a0)
ffffffffc020089e:	5a099a63          	bnez	s3,ffffffffc0200e52 <buddy_check+0x60c>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02008a2:	0000b797          	auipc	a5,0xb
ffffffffc02008a6:	96e7b783          	ld	a5,-1682(a5) # ffffffffc020b210 <pages>
ffffffffc02008aa:	40f90733          	sub	a4,s2,a5
ffffffffc02008ae:	870d                	srai	a4,a4,0x3
ffffffffc02008b0:	00003597          	auipc	a1,0x3
ffffffffc02008b4:	a705b583          	ld	a1,-1424(a1) # ffffffffc0203320 <error_string+0x38>
ffffffffc02008b8:	02b70733          	mul	a4,a4,a1
ffffffffc02008bc:	00003617          	auipc	a2,0x3
ffffffffc02008c0:	a6c63603          	ld	a2,-1428(a2) # ffffffffc0203328 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);  // 页面地址在有效范围内
ffffffffc02008c4:	0000b697          	auipc	a3,0xb
ffffffffc02008c8:	9446b683          	ld	a3,-1724(a3) # ffffffffc020b208 <npage>
ffffffffc02008cc:	06b2                	slli	a3,a3,0xc
ffffffffc02008ce:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc02008d0:	0732                	slli	a4,a4,0xc
ffffffffc02008d2:	6cd77063          	bgeu	a4,a3,ffffffffc0200f92 <buddy_check+0x74c>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02008d6:	40f48733          	sub	a4,s1,a5
ffffffffc02008da:	870d                	srai	a4,a4,0x3
ffffffffc02008dc:	02b70733          	mul	a4,a4,a1
ffffffffc02008e0:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc02008e2:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);  // 页面地址在有效范围内
ffffffffc02008e4:	68d77763          	bgeu	a4,a3,ffffffffc0200f72 <buddy_check+0x72c>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02008e8:	40f507b3          	sub	a5,a0,a5
ffffffffc02008ec:	878d                	srai	a5,a5,0x3
ffffffffc02008ee:	02b787b3          	mul	a5,a5,a1
ffffffffc02008f2:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc02008f4:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);  // 页面地址在有效范围内
ffffffffc02008f6:	64d7fe63          	bgeu	a5,a3,ffffffffc0200f52 <buddy_check+0x70c>
    free_page(p0);          // 释放第1个页面
ffffffffc02008fa:	4585                	li	a1,1
ffffffffc02008fc:	854a                	mv	a0,s2
ffffffffc02008fe:	115000ef          	jal	ra,ffffffffc0201212 <free_pages>
    free_page(p1);          // 释放第2个页面
ffffffffc0200902:	4585                	li	a1,1
ffffffffc0200904:	8526                	mv	a0,s1
ffffffffc0200906:	10d000ef          	jal	ra,ffffffffc0201212 <free_pages>
    free_page(p2);          // 释放第3个页面
ffffffffc020090a:	4585                	li	a1,1
ffffffffc020090c:	8522                	mv	a0,s0
ffffffffc020090e:	105000ef          	jal	ra,ffffffffc0201212 <free_pages>
    // 先进行基础测试
    basic_check();          // 运行基础测试
    
    cprintf("\n--- 开始buddy system专项测试 ---\n");  // 输出测试开始信息
ffffffffc0200912:	00002517          	auipc	a0,0x2
ffffffffc0200916:	b2650513          	addi	a0,a0,-1242 # ffffffffc0202438 <etext+0x404>
    if (buddy.longest == NULL)  // 如果未初始化
ffffffffc020091a:	00006a17          	auipc	s4,0x6
ffffffffc020091e:	6fea0a13          	addi	s4,s4,1790 # ffffffffc0207018 <buddy>
    cprintf("\n--- 开始buddy system专项测试 ---\n");  // 输出测试开始信息
ffffffffc0200922:	82bff0ef          	jal	ra,ffffffffc020014c <cprintf>
    if (buddy.longest == NULL)  // 如果未初始化
ffffffffc0200926:	008a3783          	ld	a5,8(s4)
ffffffffc020092a:	4e078c63          	beqz	a5,ffffffffc0200e22 <buddy_check+0x5dc>
    return buddy.longest[0];    // 返回根节点的可用大小
ffffffffc020092e:	0007ea83          	lwu	s5,0(a5)
    
    // 记录初始状态
    size_t initial_free = buddy_nr_free_pages();  // 获取初始可用页面数
    cprintf("初始可用页面数: %d\n", initial_free);  // 输出初始状态
ffffffffc0200932:	85d6                	mv	a1,s5
ffffffffc0200934:	00002517          	auipc	a0,0x2
ffffffffc0200938:	b3450513          	addi	a0,a0,-1228 # ffffffffc0202468 <etext+0x434>
ffffffffc020093c:	811ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    // 测试1: 基本的2的幂次分配和释放
    cprintf("\n--- 测试1: 基本的2的幂次分配和释放 ---\n");
ffffffffc0200940:	00002517          	auipc	a0,0x2
ffffffffc0200944:	b4850513          	addi	a0,a0,-1208 # ffffffffc0202488 <etext+0x454>
ffffffffc0200948:	805ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    struct Page *p1, *p2, *p4, *p8;  // 测试页面指针
    
    p1 = alloc_pages(1);   // 分配1页
ffffffffc020094c:	4505                	li	a0,1
ffffffffc020094e:	0b9000ef          	jal	ra,ffffffffc0201206 <alloc_pages>
ffffffffc0200952:	84aa                	mv	s1,a0
    assert(p1 != NULL);    // 确保分配成功
ffffffffc0200954:	6a050f63          	beqz	a0,ffffffffc0201012 <buddy_check+0x7cc>
    cprintf("✓ 分配1页成功\n");  // 输出成功信息
ffffffffc0200958:	00002517          	auipc	a0,0x2
ffffffffc020095c:	b7850513          	addi	a0,a0,-1160 # ffffffffc02024d0 <etext+0x49c>
ffffffffc0200960:	fecff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    p2 = alloc_pages(2);   // 分配2页
ffffffffc0200964:	4509                	li	a0,2
ffffffffc0200966:	0a1000ef          	jal	ra,ffffffffc0201206 <alloc_pages>
ffffffffc020096a:	842a                	mv	s0,a0
    assert(p2 != NULL);    // 确保分配成功
ffffffffc020096c:	5c050363          	beqz	a0,ffffffffc0200f32 <buddy_check+0x6ec>
    cprintf("✓ 分配2页成功\n");  // 输出成功信息
ffffffffc0200970:	00002517          	auipc	a0,0x2
ffffffffc0200974:	b8850513          	addi	a0,a0,-1144 # ffffffffc02024f8 <etext+0x4c4>
ffffffffc0200978:	fd4ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    p4 = alloc_pages(4);   // 分配4页
ffffffffc020097c:	4511                	li	a0,4
ffffffffc020097e:	089000ef          	jal	ra,ffffffffc0201206 <alloc_pages>
ffffffffc0200982:	8b2a                	mv	s6,a0
    assert(p4 != NULL);    // 确保分配成功
ffffffffc0200984:	58050763          	beqz	a0,ffffffffc0200f12 <buddy_check+0x6cc>
    cprintf("✓ 分配4页成功\n");  // 输出成功信息
ffffffffc0200988:	00002517          	auipc	a0,0x2
ffffffffc020098c:	b9850513          	addi	a0,a0,-1128 # ffffffffc0202520 <etext+0x4ec>
ffffffffc0200990:	fbcff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    p8 = alloc_pages(8);   // 分配8页
ffffffffc0200994:	4521                	li	a0,8
ffffffffc0200996:	071000ef          	jal	ra,ffffffffc0201206 <alloc_pages>
ffffffffc020099a:	892a                	mv	s2,a0
    assert(p8 != NULL);    // 确保分配成功
ffffffffc020099c:	68050b63          	beqz	a0,ffffffffc0201032 <buddy_check+0x7ec>
    cprintf("✓ 分配8页成功\n");  // 输出成功信息
ffffffffc02009a0:	00002517          	auipc	a0,0x2
ffffffffc02009a4:	ba850513          	addi	a0,a0,-1112 # ffffffffc0202548 <etext+0x514>
ffffffffc02009a8:	fa4ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    if (buddy.longest == NULL)  // 如果未初始化
ffffffffc02009ac:	008a3783          	ld	a5,8(s4)
ffffffffc02009b0:	46078b63          	beqz	a5,ffffffffc0200e26 <buddy_check+0x5e0>
    return buddy.longest[0];    // 返回根节点的可用大小
ffffffffc02009b4:	0007e583          	lwu	a1,0(a5)

    // 检查分配后的可用内存
    size_t after_alloc = buddy_nr_free_pages();  // 获取分配后可用页面数
    cprintf("分配后可用页面数: %d\n", after_alloc);  // 输出分配后状态
ffffffffc02009b8:	00002517          	auipc	a0,0x2
ffffffffc02009bc:	ba850513          	addi	a0,a0,-1112 # ffffffffc0202560 <etext+0x52c>
ffffffffc02009c0:	f8cff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    // 释放内存
    free_pages(p1, 1);     // 释放1页
ffffffffc02009c4:	4585                	li	a1,1
ffffffffc02009c6:	8526                	mv	a0,s1
ffffffffc02009c8:	04b000ef          	jal	ra,ffffffffc0201212 <free_pages>
    cprintf("✓ 释放1页成功\n");  // 输出成功信息
ffffffffc02009cc:	00002517          	auipc	a0,0x2
ffffffffc02009d0:	bb450513          	addi	a0,a0,-1100 # ffffffffc0202580 <etext+0x54c>
ffffffffc02009d4:	f78ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    free_pages(p2, 2);     // 释放2页
ffffffffc02009d8:	4589                	li	a1,2
ffffffffc02009da:	8522                	mv	a0,s0
ffffffffc02009dc:	037000ef          	jal	ra,ffffffffc0201212 <free_pages>
    cprintf("✓ 释放2页成功\n");  // 输出成功信息
ffffffffc02009e0:	00002517          	auipc	a0,0x2
ffffffffc02009e4:	bb850513          	addi	a0,a0,-1096 # ffffffffc0202598 <etext+0x564>
ffffffffc02009e8:	f64ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    free_pages(p4, 4);     // 释放4页
ffffffffc02009ec:	4591                	li	a1,4
ffffffffc02009ee:	855a                	mv	a0,s6
ffffffffc02009f0:	023000ef          	jal	ra,ffffffffc0201212 <free_pages>
    cprintf("✓ 释放4页成功\n");  // 输出成功信息
ffffffffc02009f4:	00002517          	auipc	a0,0x2
ffffffffc02009f8:	bbc50513          	addi	a0,a0,-1092 # ffffffffc02025b0 <etext+0x57c>
ffffffffc02009fc:	f50ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    free_pages(p8, 8);     // 释放8页
ffffffffc0200a00:	45a1                	li	a1,8
ffffffffc0200a02:	854a                	mv	a0,s2
ffffffffc0200a04:	00f000ef          	jal	ra,ffffffffc0201212 <free_pages>
    cprintf("✓ 释放8页成功\n");  // 输出成功信息
ffffffffc0200a08:	00002517          	auipc	a0,0x2
ffffffffc0200a0c:	bc050513          	addi	a0,a0,-1088 # ffffffffc02025c8 <etext+0x594>
ffffffffc0200a10:	f3cff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    // 测试2: 非2的幂次分配（向上取整）
    cprintf("\n--- 测试2: 非2的幂次分配（向上取整） ---\n");
ffffffffc0200a14:	00002517          	auipc	a0,0x2
ffffffffc0200a18:	bcc50513          	addi	a0,a0,-1076 # ffffffffc02025e0 <etext+0x5ac>
ffffffffc0200a1c:	f30ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    struct Page *p3, *p5, *p6, *p7;  // 测试页面指针
    
    p3 = alloc_pages(3);   // 请求3页，应该分配4页
ffffffffc0200a20:	450d                	li	a0,3
ffffffffc0200a22:	7e4000ef          	jal	ra,ffffffffc0201206 <alloc_pages>
ffffffffc0200a26:	8b2a                	mv	s6,a0
    assert(p3 != NULL);     // 确保分配成功
ffffffffc0200a28:	4c050563          	beqz	a0,ffffffffc0200ef2 <buddy_check+0x6ac>
    cprintf("✓ 请求3页分配成功（实际分配4页）\n");  // 输出成功信息
ffffffffc0200a2c:	00002517          	auipc	a0,0x2
ffffffffc0200a30:	c0450513          	addi	a0,a0,-1020 # ffffffffc0202630 <etext+0x5fc>
ffffffffc0200a34:	f18ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    p5 = alloc_pages(5);   // 请求5页，应该分配8页
ffffffffc0200a38:	4515                	li	a0,5
ffffffffc0200a3a:	7cc000ef          	jal	ra,ffffffffc0201206 <alloc_pages>
ffffffffc0200a3e:	892a                	mv	s2,a0
    assert(p5 != NULL);     // 确保分配成功
ffffffffc0200a40:	48050963          	beqz	a0,ffffffffc0200ed2 <buddy_check+0x68c>
    cprintf("✓ 请求5页分配成功（实际分配8页）\n");  // 输出成功信息
ffffffffc0200a44:	00002517          	auipc	a0,0x2
ffffffffc0200a48:	c3450513          	addi	a0,a0,-972 # ffffffffc0202678 <etext+0x644>
ffffffffc0200a4c:	f00ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    p6 = alloc_pages(6);   // 请求6页，应该分配8页
ffffffffc0200a50:	4519                	li	a0,6
ffffffffc0200a52:	7b4000ef          	jal	ra,ffffffffc0201206 <alloc_pages>
ffffffffc0200a56:	84aa                	mv	s1,a0
    assert(p6 != NULL);     // 确保分配成功
ffffffffc0200a58:	44050d63          	beqz	a0,ffffffffc0200eb2 <buddy_check+0x66c>
    cprintf("✓ 请求6页分配成功（实际分配8页）\n");  // 输出成功信息
ffffffffc0200a5c:	00002517          	auipc	a0,0x2
ffffffffc0200a60:	c6450513          	addi	a0,a0,-924 # ffffffffc02026c0 <etext+0x68c>
ffffffffc0200a64:	ee8ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    p7 = alloc_pages(7);   // 请求7页，应该分配8页
ffffffffc0200a68:	451d                	li	a0,7
ffffffffc0200a6a:	79c000ef          	jal	ra,ffffffffc0201206 <alloc_pages>
ffffffffc0200a6e:	842a                	mv	s0,a0
    assert(p7 != NULL);     // 确保分配成功
ffffffffc0200a70:	42050163          	beqz	a0,ffffffffc0200e92 <buddy_check+0x64c>
    cprintf("✓ 请求7页分配成功（实际分配8页）\n");  // 输出成功信息
ffffffffc0200a74:	00002517          	auipc	a0,0x2
ffffffffc0200a78:	c9450513          	addi	a0,a0,-876 # ffffffffc0202708 <etext+0x6d4>
ffffffffc0200a7c:	ed0ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    // 释放非2的幂次分配的内存
    free_pages(p3, 3);     // 释放3页
ffffffffc0200a80:	458d                	li	a1,3
ffffffffc0200a82:	855a                	mv	a0,s6
ffffffffc0200a84:	78e000ef          	jal	ra,ffffffffc0201212 <free_pages>
    cprintf("✓ 释放3页成功\n");  // 输出成功信息
ffffffffc0200a88:	00002517          	auipc	a0,0x2
ffffffffc0200a8c:	cb850513          	addi	a0,a0,-840 # ffffffffc0202740 <etext+0x70c>
ffffffffc0200a90:	ebcff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    free_pages(p5, 5);     // 释放5页
ffffffffc0200a94:	4595                	li	a1,5
ffffffffc0200a96:	854a                	mv	a0,s2
ffffffffc0200a98:	77a000ef          	jal	ra,ffffffffc0201212 <free_pages>
    cprintf("✓ 释放5页成功\n");  // 输出成功信息
ffffffffc0200a9c:	00002517          	auipc	a0,0x2
ffffffffc0200aa0:	cbc50513          	addi	a0,a0,-836 # ffffffffc0202758 <etext+0x724>
ffffffffc0200aa4:	ea8ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    free_pages(p6, 6);     // 释放6页
ffffffffc0200aa8:	4599                	li	a1,6
ffffffffc0200aaa:	8526                	mv	a0,s1
ffffffffc0200aac:	766000ef          	jal	ra,ffffffffc0201212 <free_pages>
    cprintf("✓ 释放6页成功\n");  // 输出成功信息
ffffffffc0200ab0:	00002517          	auipc	a0,0x2
ffffffffc0200ab4:	cc050513          	addi	a0,a0,-832 # ffffffffc0202770 <etext+0x73c>
ffffffffc0200ab8:	e94ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    free_pages(p7, 7);     // 释放7页
ffffffffc0200abc:	459d                	li	a1,7
ffffffffc0200abe:	8522                	mv	a0,s0
ffffffffc0200ac0:	752000ef          	jal	ra,ffffffffc0201212 <free_pages>
    cprintf("✓ 释放7页成功\n");  // 输出成功信息
ffffffffc0200ac4:	00002517          	auipc	a0,0x2
ffffffffc0200ac8:	cc450513          	addi	a0,a0,-828 # ffffffffc0202788 <etext+0x754>
ffffffffc0200acc:	e80ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    // 测试3: 伙伴合并机制
    cprintf("\n--- 测试3: 伙伴合并机制测试 ---\n");
ffffffffc0200ad0:	00002517          	auipc	a0,0x2
ffffffffc0200ad4:	cd050513          	addi	a0,a0,-816 # ffffffffc02027a0 <etext+0x76c>
ffffffffc0200ad8:	848a                	mv	s1,sp
ffffffffc0200ada:	e72ff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200ade:	8926                	mv	s2,s1
    struct Page *buddy_test[4];  // 测试页面数组
    
    // 分配4个连续的1页块
    for (int i = 0; i < 4; i++) {  // 循环分配4次
ffffffffc0200ae0:	4401                	li	s0,0
        buddy_test[i] = alloc_pages(1);  // 每次分配1页
        if (buddy_test[i] != NULL) {  // 如果分配成功
            cprintf("✓ 分配第%d个1页块成功\n", i+1);  // 输出成功信息
ffffffffc0200ae2:	00002b97          	auipc	s7,0x2
ffffffffc0200ae6:	ceeb8b93          	addi	s7,s7,-786 # ffffffffc02027d0 <etext+0x79c>
    for (int i = 0; i < 4; i++) {  // 循环分配4次
ffffffffc0200aea:	4b11                	li	s6,4
        buddy_test[i] = alloc_pages(1);  // 每次分配1页
ffffffffc0200aec:	4505                	li	a0,1
ffffffffc0200aee:	718000ef          	jal	ra,ffffffffc0201206 <alloc_pages>
ffffffffc0200af2:	00a93023          	sd	a0,0(s2)
            cprintf("✓ 分配第%d个1页块成功\n", i+1);  // 输出成功信息
ffffffffc0200af6:	2405                	addiw	s0,s0,1
        if (buddy_test[i] != NULL) {  // 如果分配成功
ffffffffc0200af8:	c509                	beqz	a0,ffffffffc0200b02 <buddy_check+0x2bc>
            cprintf("✓ 分配第%d个1页块成功\n", i+1);  // 输出成功信息
ffffffffc0200afa:	85a2                	mv	a1,s0
ffffffffc0200afc:	855e                	mv	a0,s7
ffffffffc0200afe:	e4eff0ef          	jal	ra,ffffffffc020014c <cprintf>
    for (int i = 0; i < 4; i++) {  // 循环分配4次
ffffffffc0200b02:	0921                	addi	s2,s2,8
ffffffffc0200b04:	ff6414e3          	bne	s0,s6,ffffffffc0200aec <buddy_check+0x2a6>
    if (buddy.longest == NULL)  // 如果未初始化
ffffffffc0200b08:	008a3783          	ld	a5,8(s4)
ffffffffc0200b0c:	32078363          	beqz	a5,ffffffffc0200e32 <buddy_check+0x5ec>
    return buddy.longest[0];    // 返回根节点的可用大小
ffffffffc0200b10:	0007e583          	lwu	a1,0(a5)
        }
    }
    
    size_t before_merge = buddy_nr_free_pages();  // 获取合并前可用页面数
    cprintf("合并前可用页面数: %d\n", before_merge);  // 输出合并前状态
ffffffffc0200b14:	00002517          	auipc	a0,0x2
ffffffffc0200b18:	ce450513          	addi	a0,a0,-796 # ffffffffc02027f8 <etext+0x7c4>
ffffffffc0200b1c:	e30ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    // 释放这些块，测试合并效果
    for (int i = 0; i < 4; i++) {  // 循环释放4次
ffffffffc0200b20:	4401                	li	s0,0
        if (buddy_test[i] != NULL) {  // 如果页面有效
            free_pages(buddy_test[i], 1);  // 释放1页
            cprintf("✓ 释放第%d个1页块\n", i+1);  // 输出成功信息
ffffffffc0200b22:	00002b17          	auipc	s6,0x2
ffffffffc0200b26:	cf6b0b13          	addi	s6,s6,-778 # ffffffffc0202818 <etext+0x7e4>
    for (int i = 0; i < 4; i++) {  // 循环释放4次
ffffffffc0200b2a:	4911                	li	s2,4
        if (buddy_test[i] != NULL) {  // 如果页面有效
ffffffffc0200b2c:	6088                	ld	a0,0(s1)
            cprintf("✓ 释放第%d个1页块\n", i+1);  // 输出成功信息
ffffffffc0200b2e:	2405                	addiw	s0,s0,1
        if (buddy_test[i] != NULL) {  // 如果页面有效
ffffffffc0200b30:	c901                	beqz	a0,ffffffffc0200b40 <buddy_check+0x2fa>
            free_pages(buddy_test[i], 1);  // 释放1页
ffffffffc0200b32:	4585                	li	a1,1
ffffffffc0200b34:	6de000ef          	jal	ra,ffffffffc0201212 <free_pages>
            cprintf("✓ 释放第%d个1页块\n", i+1);  // 输出成功信息
ffffffffc0200b38:	85a2                	mv	a1,s0
ffffffffc0200b3a:	855a                	mv	a0,s6
ffffffffc0200b3c:	e10ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    for (int i = 0; i < 4; i++) {  // 循环释放4次
ffffffffc0200b40:	04a1                	addi	s1,s1,8
ffffffffc0200b42:	ff2415e3          	bne	s0,s2,ffffffffc0200b2c <buddy_check+0x2e6>
    if (buddy.longest == NULL)  // 如果未初始化
ffffffffc0200b46:	008a3783          	ld	a5,8(s4)
ffffffffc0200b4a:	2e078063          	beqz	a5,ffffffffc0200e2a <buddy_check+0x5e4>
    return buddy.longest[0];    // 返回根节点的可用大小
ffffffffc0200b4e:	0007e583          	lwu	a1,0(a5)
        }
    }
    
    size_t after_merge = buddy_nr_free_pages();  // 获取合并后可用页面数
    cprintf("合并后可用页面数: %d\n", after_merge);  // 输出合并后状态
ffffffffc0200b52:	00002517          	auipc	a0,0x2
ffffffffc0200b56:	ce650513          	addi	a0,a0,-794 # ffffffffc0202838 <etext+0x804>
ffffffffc0200b5a:	df2ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    // 测试4: 连续分配和释放
    cprintf("\n--- 测试4: 连续分配和释放压力测试 ---\n");
ffffffffc0200b5e:	00002517          	auipc	a0,0x2
ffffffffc0200b62:	cfa50513          	addi	a0,a0,-774 # ffffffffc0202858 <etext+0x824>
ffffffffc0200b66:	0100                	addi	s0,sp,128
ffffffffc0200b68:	de4ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    struct Page *stress_test[16];  // 压力测试页面数组
    int success_count = 0;         // 成功计数
    
    // 连续分配多个1页块
    for (int i = 0; i < 16; i++) {  // 循环分配16次
ffffffffc0200b6c:	10010913          	addi	s2,sp,256
    cprintf("\n--- 测试4: 连续分配和释放压力测试 ---\n");
ffffffffc0200b70:	84a2                	mv	s1,s0
    int success_count = 0;         // 成功计数
ffffffffc0200b72:	4b01                	li	s6,0
        stress_test[i] = alloc_pages(1);  // 每次分配1页
ffffffffc0200b74:	4505                	li	a0,1
ffffffffc0200b76:	690000ef          	jal	ra,ffffffffc0201206 <alloc_pages>
ffffffffc0200b7a:	e088                	sd	a0,0(s1)
        if (stress_test[i] != NULL) {  // 如果分配成功
ffffffffc0200b7c:	c111                	beqz	a0,ffffffffc0200b80 <buddy_check+0x33a>
            success_count++;           // 成功计数加1
ffffffffc0200b7e:	2b05                	addiw	s6,s6,1
    for (int i = 0; i < 16; i++) {  // 循环分配16次
ffffffffc0200b80:	04a1                	addi	s1,s1,8
ffffffffc0200b82:	fe9919e3          	bne	s2,s1,ffffffffc0200b74 <buddy_check+0x32e>
        }
    }
    cprintf("✓ 成功分配%d个1页块\n", success_count);  // 输出成功信息
ffffffffc0200b86:	85da                	mv	a1,s6
ffffffffc0200b88:	00002517          	auipc	a0,0x2
ffffffffc0200b8c:	d0850513          	addi	a0,a0,-760 # ffffffffc0202890 <etext+0x85c>
ffffffffc0200b90:	dbcff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    // 释放所有成功分配的块
    for (int i = 0; i < 16; i++) {  // 循环释放16次
        if (stress_test[i] != NULL) {  // 如果页面有效
ffffffffc0200b94:	6008                	ld	a0,0(s0)
ffffffffc0200b96:	c501                	beqz	a0,ffffffffc0200b9e <buddy_check+0x358>
            free_pages(stress_test[i], 1);  // 释放1页
ffffffffc0200b98:	4585                	li	a1,1
ffffffffc0200b9a:	678000ef          	jal	ra,ffffffffc0201212 <free_pages>
    for (int i = 0; i < 16; i++) {  // 循环释放16次
ffffffffc0200b9e:	0421                	addi	s0,s0,8
ffffffffc0200ba0:	fe891ae3          	bne	s2,s0,ffffffffc0200b94 <buddy_check+0x34e>
        }
    }
    cprintf("✓ 释放所有分配的块\n");  // 输出成功信息
ffffffffc0200ba4:	00002517          	auipc	a0,0x2
ffffffffc0200ba8:	d0c50513          	addi	a0,a0,-756 # ffffffffc02028b0 <etext+0x87c>
ffffffffc0200bac:	da0ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    // 测试5: 大块分配测试
    cprintf("\n--- 测试5: 大块分配测试 ---\n");
ffffffffc0200bb0:	00002517          	auipc	a0,0x2
ffffffffc0200bb4:	d2050513          	addi	a0,a0,-736 # ffffffffc02028d0 <etext+0x89c>
ffffffffc0200bb8:	1004                	addi	s1,sp,32
ffffffffc0200bba:	d92ff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200bbe:	8926                	mv	s2,s1
    struct Page *large_blocks[4];  // 大块测试页面数组
    int large_success = 0;         // 大块成功计数
    
    // 尝试分配多个大块
    for (int i = 0; i < 4; i++) {  // 循环分配4次
ffffffffc0200bc0:	4401                	li	s0,0
        large_blocks[i] = alloc_pages(16);  // 每次分配16页
        if (large_blocks[i] != NULL) {  // 如果分配成功
            large_success++;            // 成功计数加1
            cprintf("✓ 成功分配第%d个16页大块\n", i+1);  // 输出成功信息
        } else {
            cprintf("! 分配第%d个16页大块失败\n", i+1);  // 输出失败信息
ffffffffc0200bc2:	00002c17          	auipc	s8,0x2
ffffffffc0200bc6:	d5ec0c13          	addi	s8,s8,-674 # ffffffffc0202920 <etext+0x8ec>
            cprintf("✓ 成功分配第%d个16页大块\n", i+1);  // 输出成功信息
ffffffffc0200bca:	00002b97          	auipc	s7,0x2
ffffffffc0200bce:	d2eb8b93          	addi	s7,s7,-722 # ffffffffc02028f8 <etext+0x8c4>
    for (int i = 0; i < 4; i++) {  // 循环分配4次
ffffffffc0200bd2:	4b11                	li	s6,4
        large_blocks[i] = alloc_pages(16);  // 每次分配16页
ffffffffc0200bd4:	4541                	li	a0,16
ffffffffc0200bd6:	630000ef          	jal	ra,ffffffffc0201206 <alloc_pages>
            cprintf("✓ 成功分配第%d个16页大块\n", i+1);  // 输出成功信息
ffffffffc0200bda:	2405                	addiw	s0,s0,1
        large_blocks[i] = alloc_pages(16);  // 每次分配16页
ffffffffc0200bdc:	00a93023          	sd	a0,0(s2)
            cprintf("✓ 成功分配第%d个16页大块\n", i+1);  // 输出成功信息
ffffffffc0200be0:	85a2                	mv	a1,s0
        if (large_blocks[i] != NULL) {  // 如果分配成功
ffffffffc0200be2:	20050063          	beqz	a0,ffffffffc0200de2 <buddy_check+0x59c>
            cprintf("✓ 成功分配第%d个16页大块\n", i+1);  // 输出成功信息
ffffffffc0200be6:	855e                	mv	a0,s7
ffffffffc0200be8:	d64ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    for (int i = 0; i < 4; i++) {  // 循环分配4次
ffffffffc0200bec:	0921                	addi	s2,s2,8
ffffffffc0200bee:	ff6413e3          	bne	s0,s6,ffffffffc0200bd4 <buddy_check+0x38e>
        }
    }
    
    // 释放大块
    for (int i = 0; i < 4; i++) {  // 循环释放4次
ffffffffc0200bf2:	4401                	li	s0,0
        if (large_blocks[i] != NULL) {  // 如果页面有效
            free_pages(large_blocks[i], 16);  // 释放16页
            cprintf("✓ 释放第%d个16页大块\n", i+1);  // 输出成功信息
ffffffffc0200bf4:	00002b17          	auipc	s6,0x2
ffffffffc0200bf8:	d54b0b13          	addi	s6,s6,-684 # ffffffffc0202948 <etext+0x914>
    for (int i = 0; i < 4; i++) {  // 循环释放4次
ffffffffc0200bfc:	4911                	li	s2,4
        if (large_blocks[i] != NULL) {  // 如果页面有效
ffffffffc0200bfe:	6088                	ld	a0,0(s1)
            cprintf("✓ 释放第%d个16页大块\n", i+1);  // 输出成功信息
ffffffffc0200c00:	2405                	addiw	s0,s0,1
        if (large_blocks[i] != NULL) {  // 如果页面有效
ffffffffc0200c02:	c901                	beqz	a0,ffffffffc0200c12 <buddy_check+0x3cc>
            free_pages(large_blocks[i], 16);  // 释放16页
ffffffffc0200c04:	45c1                	li	a1,16
ffffffffc0200c06:	60c000ef          	jal	ra,ffffffffc0201212 <free_pages>
            cprintf("✓ 释放第%d个16页大块\n", i+1);  // 输出成功信息
ffffffffc0200c0a:	85a2                	mv	a1,s0
ffffffffc0200c0c:	855a                	mv	a0,s6
ffffffffc0200c0e:	d3eff0ef          	jal	ra,ffffffffc020014c <cprintf>
    for (int i = 0; i < 4; i++) {  // 循环释放4次
ffffffffc0200c12:	04a1                	addi	s1,s1,8
ffffffffc0200c14:	ff2415e3          	bne	s0,s2,ffffffffc0200bfe <buddy_check+0x3b8>
        }
    }
    
    // 测试6: 边界情况测试
    cprintf("\n--- 测试6: 边界情况测试 ---\n");
ffffffffc0200c18:	00002517          	auipc	a0,0x2
ffffffffc0200c1c:	d5050513          	addi	a0,a0,-688 # ffffffffc0202968 <etext+0x934>
ffffffffc0200c20:	d2cff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    // 测试分配大块内存
    struct Page *huge_block = alloc_pages(1024);  // 尝试分配1024页
ffffffffc0200c24:	40000513          	li	a0,1024
ffffffffc0200c28:	5de000ef          	jal	ra,ffffffffc0201206 <alloc_pages>
ffffffffc0200c2c:	842a                	mv	s0,a0
    if (huge_block != NULL) {  // 如果分配成功
ffffffffc0200c2e:	1e050363          	beqz	a0,ffffffffc0200e14 <buddy_check+0x5ce>
        cprintf("✓ 分配1024页成功\n");  // 输出成功信息
ffffffffc0200c32:	00002517          	auipc	a0,0x2
ffffffffc0200c36:	d5e50513          	addi	a0,a0,-674 # ffffffffc0202990 <etext+0x95c>
ffffffffc0200c3a:	d12ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        free_pages(huge_block, 1024);   // 释放1024页
ffffffffc0200c3e:	8522                	mv	a0,s0
ffffffffc0200c40:	40000593          	li	a1,1024
ffffffffc0200c44:	5ce000ef          	jal	ra,ffffffffc0201212 <free_pages>
        cprintf("✓ 释放1024页成功\n");  // 输出成功信息
ffffffffc0200c48:	00002517          	auipc	a0,0x2
ffffffffc0200c4c:	d6850513          	addi	a0,a0,-664 # ffffffffc02029b0 <etext+0x97c>
ffffffffc0200c50:	cfcff0ef          	jal	ra,ffffffffc020014c <cprintf>
    } else {
        cprintf("! 分配1024页失败\n");  // 输出失败信息
    }
    
    // 测试分配最大可能的块
    struct Page *max_block = alloc_pages(512);  // 尝试分配512页
ffffffffc0200c54:	20000513          	li	a0,512
ffffffffc0200c58:	5ae000ef          	jal	ra,ffffffffc0201206 <alloc_pages>
ffffffffc0200c5c:	842a                	mv	s0,a0
    if (max_block != NULL) {  // 如果分配成功
ffffffffc0200c5e:	1a050463          	beqz	a0,ffffffffc0200e06 <buddy_check+0x5c0>
        cprintf("✓ 分配512页成功\n");  // 输出成功信息
ffffffffc0200c62:	00002517          	auipc	a0,0x2
ffffffffc0200c66:	d8650513          	addi	a0,a0,-634 # ffffffffc02029e8 <etext+0x9b4>
ffffffffc0200c6a:	ce2ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        free_pages(max_block, 512);   // 释放512页
ffffffffc0200c6e:	8522                	mv	a0,s0
ffffffffc0200c70:	20000593          	li	a1,512
ffffffffc0200c74:	59e000ef          	jal	ra,ffffffffc0201212 <free_pages>
        cprintf("✓ 释放512页成功\n");  // 输出成功信息
ffffffffc0200c78:	00002517          	auipc	a0,0x2
ffffffffc0200c7c:	d8850513          	addi	a0,a0,-632 # ffffffffc0202a00 <etext+0x9cc>
ffffffffc0200c80:	cccff0ef          	jal	ra,ffffffffc020014c <cprintf>
    } else {
        cprintf("! 分配512页失败\n");  // 输出失败信息
    }
    
    // 测试7: 碎片整理效果测试
    cprintf("\n--- 测试7: 碎片整理效果测试 ---\n");
ffffffffc0200c84:	00002517          	auipc	a0,0x2
ffffffffc0200c88:	dac50513          	addi	a0,a0,-596 # ffffffffc0202a30 <etext+0x9fc>
ffffffffc0200c8c:	0084                	addi	s1,sp,64
ffffffffc0200c8e:	cbeff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200c92:	8426                	mv	s0,s1
    
    // 分配8个2页块
    for (int i = 0; i < 8; i++) {  // 循环分配8次
        frag_test[i] = alloc_pages(2);  // 每次分配2页
        if (frag_test[i] != NULL) {  // 如果分配成功
            cprintf("✓ 分配第%d个2页块\n", i+1);  // 输出成功信息
ffffffffc0200c94:	00002b17          	auipc	s6,0x2
ffffffffc0200c98:	dccb0b13          	addi	s6,s6,-564 # ffffffffc0202a60 <etext+0xa2c>
    for (int i = 0; i < 8; i++) {  // 循环分配8次
ffffffffc0200c9c:	4921                	li	s2,8
        frag_test[i] = alloc_pages(2);  // 每次分配2页
ffffffffc0200c9e:	4509                	li	a0,2
ffffffffc0200ca0:	566000ef          	jal	ra,ffffffffc0201206 <alloc_pages>
ffffffffc0200ca4:	e008                	sd	a0,0(s0)
            cprintf("✓ 分配第%d个2页块\n", i+1);  // 输出成功信息
ffffffffc0200ca6:	2985                	addiw	s3,s3,1
        if (frag_test[i] != NULL) {  // 如果分配成功
ffffffffc0200ca8:	c509                	beqz	a0,ffffffffc0200cb2 <buddy_check+0x46c>
            cprintf("✓ 分配第%d个2页块\n", i+1);  // 输出成功信息
ffffffffc0200caa:	85ce                	mv	a1,s3
ffffffffc0200cac:	855a                	mv	a0,s6
ffffffffc0200cae:	c9eff0ef          	jal	ra,ffffffffc020014c <cprintf>
    for (int i = 0; i < 8; i++) {  // 循环分配8次
ffffffffc0200cb2:	0421                	addi	s0,s0,8
ffffffffc0200cb4:	ff2995e3          	bne	s3,s2,ffffffffc0200c9e <buddy_check+0x458>
ffffffffc0200cb8:	04810913          	addi	s2,sp,72
ffffffffc0200cbc:	4409                	li	s0,2
    
    // 释放奇数位置的块，制造碎片
    for (int i = 1; i < 8; i += 2) {  // 释放奇数索引的块
        if (frag_test[i] != NULL) {  // 如果页面有效
            free_pages(frag_test[i], 2);  // 释放2页
            cprintf("✓ 释放第%d个2页块（制造碎片）\n", i+1);  // 输出成功信息
ffffffffc0200cbe:	00002b17          	auipc	s6,0x2
ffffffffc0200cc2:	dc2b0b13          	addi	s6,s6,-574 # ffffffffc0202a80 <etext+0xa4c>
    for (int i = 1; i < 8; i += 2) {  // 释放奇数索引的块
ffffffffc0200cc6:	49a9                	li	s3,10
        if (frag_test[i] != NULL) {  // 如果页面有效
ffffffffc0200cc8:	00093503          	ld	a0,0(s2)
ffffffffc0200ccc:	c901                	beqz	a0,ffffffffc0200cdc <buddy_check+0x496>
            free_pages(frag_test[i], 2);  // 释放2页
ffffffffc0200cce:	4589                	li	a1,2
ffffffffc0200cd0:	542000ef          	jal	ra,ffffffffc0201212 <free_pages>
            cprintf("✓ 释放第%d个2页块（制造碎片）\n", i+1);  // 输出成功信息
ffffffffc0200cd4:	85a2                	mv	a1,s0
ffffffffc0200cd6:	855a                	mv	a0,s6
ffffffffc0200cd8:	c74ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    for (int i = 1; i < 8; i += 2) {  // 释放奇数索引的块
ffffffffc0200cdc:	2409                	addiw	s0,s0,2
ffffffffc0200cde:	0941                	addi	s2,s2,16
ffffffffc0200ce0:	ff3414e3          	bne	s0,s3,ffffffffc0200cc8 <buddy_check+0x482>
        }
    }
    
    // 尝试分配大块，测试碎片整理
    struct Page *defrag_test = alloc_pages(8);  // 尝试分配8页
ffffffffc0200ce4:	4521                	li	a0,8
ffffffffc0200ce6:	520000ef          	jal	ra,ffffffffc0201206 <alloc_pages>
ffffffffc0200cea:	842a                	mv	s0,a0
    if (defrag_test != NULL) {  // 如果分配成功
ffffffffc0200cec:	10050663          	beqz	a0,ffffffffc0200df8 <buddy_check+0x5b2>
        cprintf("✓ 碎片化后仍能分配8页大块\n");  // 输出成功信息
ffffffffc0200cf0:	00002517          	auipc	a0,0x2
ffffffffc0200cf4:	dc050513          	addi	a0,a0,-576 # ffffffffc0202ab0 <etext+0xa7c>
ffffffffc0200cf8:	c54ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        free_pages(defrag_test, 8);             // 释放8页
ffffffffc0200cfc:	45a1                	li	a1,8
ffffffffc0200cfe:	8522                	mv	a0,s0
ffffffffc0200d00:	512000ef          	jal	ra,ffffffffc0201212 <free_pages>
ffffffffc0200d04:	04048413          	addi	s0,s1,64
        cprintf("! 碎片化后无法分配8页大块\n");  // 输出失败信息
    }
    
    // 清理剩余的偶数位置块
    for (int i = 0; i < 8; i += 2) {  // 释放偶数索引的块
        if (frag_test[i] != NULL) {  // 如果页面有效
ffffffffc0200d08:	6088                	ld	a0,0(s1)
ffffffffc0200d0a:	c501                	beqz	a0,ffffffffc0200d12 <buddy_check+0x4cc>
            free_pages(frag_test[i], 2);  // 释放2页
ffffffffc0200d0c:	4589                	li	a1,2
ffffffffc0200d0e:	504000ef          	jal	ra,ffffffffc0201212 <free_pages>
    for (int i = 0; i < 8; i += 2) {  // 释放偶数索引的块
ffffffffc0200d12:	04c1                	addi	s1,s1,16
ffffffffc0200d14:	fe941ae3          	bne	s0,s1,ffffffffc0200d08 <buddy_check+0x4c2>
        }
    }
    
    // 最终内存泄漏检查
    cprintf("\n--- 最终检查 ---\n");
ffffffffc0200d18:	00002517          	auipc	a0,0x2
ffffffffc0200d1c:	de850513          	addi	a0,a0,-536 # ffffffffc0202b00 <etext+0xacc>
ffffffffc0200d20:	c2cff0ef          	jal	ra,ffffffffc020014c <cprintf>
    if (buddy.longest == NULL)  // 如果未初始化
ffffffffc0200d24:	008a3783          	ld	a5,8(s4)
ffffffffc0200d28:	10078363          	beqz	a5,ffffffffc0200e2e <buddy_check+0x5e8>
    return buddy.longest[0];    // 返回根节点的可用大小
ffffffffc0200d2c:	0007e403          	lwu	s0,0(a5)
    size_t final_free = buddy_nr_free_pages();  // 获取最终可用页面数
    cprintf("最终可用页面数: %d\n", final_free);  // 输出最终状态
ffffffffc0200d30:	85a2                	mv	a1,s0
ffffffffc0200d32:	00002517          	auipc	a0,0x2
ffffffffc0200d36:	de650513          	addi	a0,a0,-538 # ffffffffc0202b18 <etext+0xae4>
ffffffffc0200d3a:	c12ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    if (final_free >= initial_free) {  // 如果没有内存泄漏
ffffffffc0200d3e:	0b547663          	bgeu	s0,s5,ffffffffc0200dea <buddy_check+0x5a4>
        cprintf("✓ 内存泄漏检查通过\n");  // 输出通过信息
    } else {
        cprintf("✗ 警告：可能存在内存泄漏（初始:%d, 最终:%d）\n",  // 输出警告信息
ffffffffc0200d42:	8622                	mv	a2,s0
ffffffffc0200d44:	85d6                	mv	a1,s5
ffffffffc0200d46:	00002517          	auipc	a0,0x2
ffffffffc0200d4a:	e1250513          	addi	a0,a0,-494 # ffffffffc0202b58 <etext+0xb24>
ffffffffc0200d4e:	bfeff0ef          	jal	ra,ffffffffc020014c <cprintf>
                initial_free, final_free);
    }
    
    // 测试8: 功能正确性验证
    cprintf("\n--- 测试8: 功能正确性验证 ---\n");
ffffffffc0200d52:	00002517          	auipc	a0,0x2
ffffffffc0200d56:	e4e50513          	addi	a0,a0,-434 # ffffffffc0202ba0 <etext+0xb6c>
ffffffffc0200d5a:	bf2ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    // 验证分配的页面地址是否合理
    struct Page *verify_p1 = alloc_pages(1);  // 分配验证页面1
ffffffffc0200d5e:	4505                	li	a0,1
ffffffffc0200d60:	4a6000ef          	jal	ra,ffffffffc0201206 <alloc_pages>
ffffffffc0200d64:	842a                	mv	s0,a0
    struct Page *verify_p2 = alloc_pages(1);  // 分配验证页面2
ffffffffc0200d66:	4505                	li	a0,1
ffffffffc0200d68:	49e000ef          	jal	ra,ffffffffc0201206 <alloc_pages>
ffffffffc0200d6c:	84aa                	mv	s1,a0
    
    if (verify_p1 != NULL && verify_p2 != NULL) {  // 如果分配成功
ffffffffc0200d6e:	c829                	beqz	s0,ffffffffc0200dc0 <buddy_check+0x57a>
ffffffffc0200d70:	c921                	beqz	a0,ffffffffc0200dc0 <buddy_check+0x57a>
        // 检查页面地址是否在合理范围内
        if (verify_p1 >= buddy.base && verify_p1 < buddy.base + buddy.size &&
ffffffffc0200d72:	010a3703          	ld	a4,16(s4)
ffffffffc0200d76:	00e46f63          	bltu	s0,a4,ffffffffc0200d94 <buddy_check+0x54e>
ffffffffc0200d7a:	000a6683          	lwu	a3,0(s4)
ffffffffc0200d7e:	00269793          	slli	a5,a3,0x2
ffffffffc0200d82:	97b6                	add	a5,a5,a3
ffffffffc0200d84:	078e                	slli	a5,a5,0x3
ffffffffc0200d86:	97ba                	add	a5,a5,a4
ffffffffc0200d88:	00f47663          	bgeu	s0,a5,ffffffffc0200d94 <buddy_check+0x54e>
ffffffffc0200d8c:	00e56463          	bltu	a0,a4,ffffffffc0200d94 <buddy_check+0x54e>
            verify_p2 >= buddy.base && verify_p2 < buddy.base + buddy.size) {
ffffffffc0200d90:	0af56a63          	bltu	a0,a5,ffffffffc0200e44 <buddy_check+0x5fe>
            cprintf("✓ 分配的页面地址在合理范围内\n");  // 输出成功信息
        } else {
            cprintf("✗ 分配的页面地址超出范围\n");  // 输出失败信息
ffffffffc0200d94:	00002517          	auipc	a0,0x2
ffffffffc0200d98:	e6c50513          	addi	a0,a0,-404 # ffffffffc0202c00 <etext+0xbcc>
ffffffffc0200d9c:	bb0ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        }
        
        // 检查页面是否不同
        if (verify_p1 != verify_p2) {  // 如果页面地址不同
ffffffffc0200da0:	08940b63          	beq	s0,s1,ffffffffc0200e36 <buddy_check+0x5f0>
            cprintf("✓ 分配的页面地址不同\n");  // 输出成功信息
ffffffffc0200da4:	00002517          	auipc	a0,0x2
ffffffffc0200da8:	e8450513          	addi	a0,a0,-380 # ffffffffc0202c28 <etext+0xbf4>
ffffffffc0200dac:	ba0ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        } else {
            cprintf("✗ 分配了相同的页面地址\n");  // 输出失败信息
        }
        
        free_pages(verify_p1, 1);  // 释放验证页面1
ffffffffc0200db0:	4585                	li	a1,1
ffffffffc0200db2:	8522                	mv	a0,s0
ffffffffc0200db4:	45e000ef          	jal	ra,ffffffffc0201212 <free_pages>
        free_pages(verify_p2, 1);  // 释放验证页面2
ffffffffc0200db8:	4585                	li	a1,1
ffffffffc0200dba:	8526                	mv	a0,s1
ffffffffc0200dbc:	456000ef          	jal	ra,ffffffffc0201212 <free_pages>
    }
    
    cprintf("\n--- buddy_check() 所有测试完成! ---\n");  // 输出测试完成信息
}
ffffffffc0200dc0:	6416                	ld	s0,320(sp)
ffffffffc0200dc2:	60b6                	ld	ra,328(sp)
ffffffffc0200dc4:	74f2                	ld	s1,312(sp)
ffffffffc0200dc6:	7952                	ld	s2,304(sp)
ffffffffc0200dc8:	79b2                	ld	s3,296(sp)
ffffffffc0200dca:	7a12                	ld	s4,288(sp)
ffffffffc0200dcc:	6af2                	ld	s5,280(sp)
ffffffffc0200dce:	6b52                	ld	s6,272(sp)
ffffffffc0200dd0:	6bb2                	ld	s7,264(sp)
ffffffffc0200dd2:	6c12                	ld	s8,256(sp)
    cprintf("\n--- buddy_check() 所有测试完成! ---\n");  // 输出测试完成信息
ffffffffc0200dd4:	00002517          	auipc	a0,0x2
ffffffffc0200dd8:	ea450513          	addi	a0,a0,-348 # ffffffffc0202c78 <etext+0xc44>
}
ffffffffc0200ddc:	6171                	addi	sp,sp,336
    cprintf("\n--- buddy_check() 所有测试完成! ---\n");  // 输出测试完成信息
ffffffffc0200dde:	b6eff06f          	j	ffffffffc020014c <cprintf>
            cprintf("! 分配第%d个16页大块失败\n", i+1);  // 输出失败信息
ffffffffc0200de2:	8562                	mv	a0,s8
ffffffffc0200de4:	b68ff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200de8:	b511                	j	ffffffffc0200bec <buddy_check+0x3a6>
        cprintf("✓ 内存泄漏检查通过\n");  // 输出通过信息
ffffffffc0200dea:	00002517          	auipc	a0,0x2
ffffffffc0200dee:	d4e50513          	addi	a0,a0,-690 # ffffffffc0202b38 <etext+0xb04>
ffffffffc0200df2:	b5aff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200df6:	bfb1                	j	ffffffffc0200d52 <buddy_check+0x50c>
        cprintf("! 碎片化后无法分配8页大块\n");  // 输出失败信息
ffffffffc0200df8:	00002517          	auipc	a0,0x2
ffffffffc0200dfc:	ce050513          	addi	a0,a0,-800 # ffffffffc0202ad8 <etext+0xaa4>
ffffffffc0200e00:	b4cff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200e04:	b701                	j	ffffffffc0200d04 <buddy_check+0x4be>
        cprintf("! 分配512页失败\n");  // 输出失败信息
ffffffffc0200e06:	00002517          	auipc	a0,0x2
ffffffffc0200e0a:	c1250513          	addi	a0,a0,-1006 # ffffffffc0202a18 <etext+0x9e4>
ffffffffc0200e0e:	b3eff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200e12:	bd8d                	j	ffffffffc0200c84 <buddy_check+0x43e>
        cprintf("! 分配1024页失败\n");  // 输出失败信息
ffffffffc0200e14:	00002517          	auipc	a0,0x2
ffffffffc0200e18:	bbc50513          	addi	a0,a0,-1092 # ffffffffc02029d0 <etext+0x99c>
ffffffffc0200e1c:	b30ff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200e20:	bd15                	j	ffffffffc0200c54 <buddy_check+0x40e>
        return 0;               // 返回0
ffffffffc0200e22:	4a81                	li	s5,0
ffffffffc0200e24:	b639                	j	ffffffffc0200932 <buddy_check+0xec>
ffffffffc0200e26:	4581                	li	a1,0
ffffffffc0200e28:	be41                	j	ffffffffc02009b8 <buddy_check+0x172>
ffffffffc0200e2a:	4581                	li	a1,0
ffffffffc0200e2c:	b31d                	j	ffffffffc0200b52 <buddy_check+0x30c>
ffffffffc0200e2e:	4401                	li	s0,0
ffffffffc0200e30:	b701                	j	ffffffffc0200d30 <buddy_check+0x4ea>
ffffffffc0200e32:	4581                	li	a1,0
ffffffffc0200e34:	b1c5                	j	ffffffffc0200b14 <buddy_check+0x2ce>
            cprintf("✗ 分配了相同的页面地址\n");  // 输出失败信息
ffffffffc0200e36:	00002517          	auipc	a0,0x2
ffffffffc0200e3a:	e1a50513          	addi	a0,a0,-486 # ffffffffc0202c50 <etext+0xc1c>
ffffffffc0200e3e:	b0eff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200e42:	b7bd                	j	ffffffffc0200db0 <buddy_check+0x56a>
            cprintf("✓ 分配的页面地址在合理范围内\n");  // 输出成功信息
ffffffffc0200e44:	00002517          	auipc	a0,0x2
ffffffffc0200e48:	d8c50513          	addi	a0,a0,-628 # ffffffffc0202bd0 <etext+0xb9c>
ffffffffc0200e4c:	b00ff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200e50:	bf81                	j	ffffffffc0200da0 <buddy_check+0x55a>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);  // 引用计数为0
ffffffffc0200e52:	00001697          	auipc	a3,0x1
ffffffffc0200e56:	54668693          	addi	a3,a3,1350 # ffffffffc0202398 <etext+0x364>
ffffffffc0200e5a:	00001617          	auipc	a2,0x1
ffffffffc0200e5e:	44660613          	addi	a2,a2,1094 # ffffffffc02022a0 <etext+0x26c>
ffffffffc0200e62:	0e900593          	li	a1,233
ffffffffc0200e66:	00001517          	auipc	a0,0x1
ffffffffc0200e6a:	45250513          	addi	a0,a0,1106 # ffffffffc02022b8 <etext+0x284>
ffffffffc0200e6e:	b54ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);  // 确保页面地址不同
ffffffffc0200e72:	00001697          	auipc	a3,0x1
ffffffffc0200e76:	4fe68693          	addi	a3,a3,1278 # ffffffffc0202370 <etext+0x33c>
ffffffffc0200e7a:	00001617          	auipc	a2,0x1
ffffffffc0200e7e:	42660613          	addi	a2,a2,1062 # ffffffffc02022a0 <etext+0x26c>
ffffffffc0200e82:	0e800593          	li	a1,232
ffffffffc0200e86:	00001517          	auipc	a0,0x1
ffffffffc0200e8a:	43250513          	addi	a0,a0,1074 # ffffffffc02022b8 <etext+0x284>
ffffffffc0200e8e:	b34ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p7 != NULL);     // 确保分配成功
ffffffffc0200e92:	00002697          	auipc	a3,0x2
ffffffffc0200e96:	86668693          	addi	a3,a3,-1946 # ffffffffc02026f8 <etext+0x6c4>
ffffffffc0200e9a:	00001617          	auipc	a2,0x1
ffffffffc0200e9e:	40660613          	addi	a2,a2,1030 # ffffffffc02022a0 <etext+0x26c>
ffffffffc0200ea2:	13600593          	li	a1,310
ffffffffc0200ea6:	00001517          	auipc	a0,0x1
ffffffffc0200eaa:	41250513          	addi	a0,a0,1042 # ffffffffc02022b8 <etext+0x284>
ffffffffc0200eae:	b14ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p6 != NULL);     // 确保分配成功
ffffffffc0200eb2:	00001697          	auipc	a3,0x1
ffffffffc0200eb6:	7fe68693          	addi	a3,a3,2046 # ffffffffc02026b0 <etext+0x67c>
ffffffffc0200eba:	00001617          	auipc	a2,0x1
ffffffffc0200ebe:	3e660613          	addi	a2,a2,998 # ffffffffc02022a0 <etext+0x26c>
ffffffffc0200ec2:	13200593          	li	a1,306
ffffffffc0200ec6:	00001517          	auipc	a0,0x1
ffffffffc0200eca:	3f250513          	addi	a0,a0,1010 # ffffffffc02022b8 <etext+0x284>
ffffffffc0200ece:	af4ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p5 != NULL);     // 确保分配成功
ffffffffc0200ed2:	00001697          	auipc	a3,0x1
ffffffffc0200ed6:	79668693          	addi	a3,a3,1942 # ffffffffc0202668 <etext+0x634>
ffffffffc0200eda:	00001617          	auipc	a2,0x1
ffffffffc0200ede:	3c660613          	addi	a2,a2,966 # ffffffffc02022a0 <etext+0x26c>
ffffffffc0200ee2:	12e00593          	li	a1,302
ffffffffc0200ee6:	00001517          	auipc	a0,0x1
ffffffffc0200eea:	3d250513          	addi	a0,a0,978 # ffffffffc02022b8 <etext+0x284>
ffffffffc0200eee:	ad4ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p3 != NULL);     // 确保分配成功
ffffffffc0200ef2:	00001697          	auipc	a3,0x1
ffffffffc0200ef6:	72e68693          	addi	a3,a3,1838 # ffffffffc0202620 <etext+0x5ec>
ffffffffc0200efa:	00001617          	auipc	a2,0x1
ffffffffc0200efe:	3a660613          	addi	a2,a2,934 # ffffffffc02022a0 <etext+0x26c>
ffffffffc0200f02:	12a00593          	li	a1,298
ffffffffc0200f06:	00001517          	auipc	a0,0x1
ffffffffc0200f0a:	3b250513          	addi	a0,a0,946 # ffffffffc02022b8 <etext+0x284>
ffffffffc0200f0e:	ab4ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p4 != NULL);    // 确保分配成功
ffffffffc0200f12:	00001697          	auipc	a3,0x1
ffffffffc0200f16:	5fe68693          	addi	a3,a3,1534 # ffffffffc0202510 <etext+0x4dc>
ffffffffc0200f1a:	00001617          	auipc	a2,0x1
ffffffffc0200f1e:	38660613          	addi	a2,a2,902 # ffffffffc02022a0 <etext+0x26c>
ffffffffc0200f22:	10d00593          	li	a1,269
ffffffffc0200f26:	00001517          	auipc	a0,0x1
ffffffffc0200f2a:	39250513          	addi	a0,a0,914 # ffffffffc02022b8 <etext+0x284>
ffffffffc0200f2e:	a94ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p2 != NULL);    // 确保分配成功
ffffffffc0200f32:	00001697          	auipc	a3,0x1
ffffffffc0200f36:	5b668693          	addi	a3,a3,1462 # ffffffffc02024e8 <etext+0x4b4>
ffffffffc0200f3a:	00001617          	auipc	a2,0x1
ffffffffc0200f3e:	36660613          	addi	a2,a2,870 # ffffffffc02022a0 <etext+0x26c>
ffffffffc0200f42:	10900593          	li	a1,265
ffffffffc0200f46:	00001517          	auipc	a0,0x1
ffffffffc0200f4a:	37250513          	addi	a0,a0,882 # ffffffffc02022b8 <etext+0x284>
ffffffffc0200f4e:	a74ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);  // 页面地址在有效范围内
ffffffffc0200f52:	00001697          	auipc	a3,0x1
ffffffffc0200f56:	4c668693          	addi	a3,a3,1222 # ffffffffc0202418 <etext+0x3e4>
ffffffffc0200f5a:	00001617          	auipc	a2,0x1
ffffffffc0200f5e:	34660613          	addi	a2,a2,838 # ffffffffc02022a0 <etext+0x26c>
ffffffffc0200f62:	0ed00593          	li	a1,237
ffffffffc0200f66:	00001517          	auipc	a0,0x1
ffffffffc0200f6a:	35250513          	addi	a0,a0,850 # ffffffffc02022b8 <etext+0x284>
ffffffffc0200f6e:	a54ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);  // 页面地址在有效范围内
ffffffffc0200f72:	00001697          	auipc	a3,0x1
ffffffffc0200f76:	48668693          	addi	a3,a3,1158 # ffffffffc02023f8 <etext+0x3c4>
ffffffffc0200f7a:	00001617          	auipc	a2,0x1
ffffffffc0200f7e:	32660613          	addi	a2,a2,806 # ffffffffc02022a0 <etext+0x26c>
ffffffffc0200f82:	0ec00593          	li	a1,236
ffffffffc0200f86:	00001517          	auipc	a0,0x1
ffffffffc0200f8a:	33250513          	addi	a0,a0,818 # ffffffffc02022b8 <etext+0x284>
ffffffffc0200f8e:	a34ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);  // 页面地址在有效范围内
ffffffffc0200f92:	00001697          	auipc	a3,0x1
ffffffffc0200f96:	44668693          	addi	a3,a3,1094 # ffffffffc02023d8 <etext+0x3a4>
ffffffffc0200f9a:	00001617          	auipc	a2,0x1
ffffffffc0200f9e:	30660613          	addi	a2,a2,774 # ffffffffc02022a0 <etext+0x26c>
ffffffffc0200fa2:	0eb00593          	li	a1,235
ffffffffc0200fa6:	00001517          	auipc	a0,0x1
ffffffffc0200faa:	31250513          	addi	a0,a0,786 # ffffffffc02022b8 <etext+0x284>
ffffffffc0200fae:	a14ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p2 = alloc_page()) != NULL);  // 分配第3个页面
ffffffffc0200fb2:	00001697          	auipc	a3,0x1
ffffffffc0200fb6:	39e68693          	addi	a3,a3,926 # ffffffffc0202350 <etext+0x31c>
ffffffffc0200fba:	00001617          	auipc	a2,0x1
ffffffffc0200fbe:	2e660613          	addi	a2,a2,742 # ffffffffc02022a0 <etext+0x26c>
ffffffffc0200fc2:	0e600593          	li	a1,230
ffffffffc0200fc6:	00001517          	auipc	a0,0x1
ffffffffc0200fca:	2f250513          	addi	a0,a0,754 # ffffffffc02022b8 <etext+0x284>
ffffffffc0200fce:	9f4ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p1 = alloc_page()) != NULL);  // 分配第2个页面
ffffffffc0200fd2:	00001697          	auipc	a3,0x1
ffffffffc0200fd6:	35e68693          	addi	a3,a3,862 # ffffffffc0202330 <etext+0x2fc>
ffffffffc0200fda:	00001617          	auipc	a2,0x1
ffffffffc0200fde:	2c660613          	addi	a2,a2,710 # ffffffffc02022a0 <etext+0x26c>
ffffffffc0200fe2:	0e500593          	li	a1,229
ffffffffc0200fe6:	00001517          	auipc	a0,0x1
ffffffffc0200fea:	2d250513          	addi	a0,a0,722 # ffffffffc02022b8 <etext+0x284>
ffffffffc0200fee:	9d4ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p0 = alloc_page()) != NULL);  // 分配第1个页面
ffffffffc0200ff2:	00001697          	auipc	a3,0x1
ffffffffc0200ff6:	31e68693          	addi	a3,a3,798 # ffffffffc0202310 <etext+0x2dc>
ffffffffc0200ffa:	00001617          	auipc	a2,0x1
ffffffffc0200ffe:	2a660613          	addi	a2,a2,678 # ffffffffc02022a0 <etext+0x26c>
ffffffffc0201002:	0e400593          	li	a1,228
ffffffffc0201006:	00001517          	auipc	a0,0x1
ffffffffc020100a:	2b250513          	addi	a0,a0,690 # ffffffffc02022b8 <etext+0x284>
ffffffffc020100e:	9b4ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p1 != NULL);    // 确保分配成功
ffffffffc0201012:	00001697          	auipc	a3,0x1
ffffffffc0201016:	4ae68693          	addi	a3,a3,1198 # ffffffffc02024c0 <etext+0x48c>
ffffffffc020101a:	00001617          	auipc	a2,0x1
ffffffffc020101e:	28660613          	addi	a2,a2,646 # ffffffffc02022a0 <etext+0x26c>
ffffffffc0201022:	10500593          	li	a1,261
ffffffffc0201026:	00001517          	auipc	a0,0x1
ffffffffc020102a:	29250513          	addi	a0,a0,658 # ffffffffc02022b8 <etext+0x284>
ffffffffc020102e:	994ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p8 != NULL);    // 确保分配成功
ffffffffc0201032:	00001697          	auipc	a3,0x1
ffffffffc0201036:	50668693          	addi	a3,a3,1286 # ffffffffc0202538 <etext+0x504>
ffffffffc020103a:	00001617          	auipc	a2,0x1
ffffffffc020103e:	26660613          	addi	a2,a2,614 # ffffffffc02022a0 <etext+0x26c>
ffffffffc0201042:	11100593          	li	a1,273
ffffffffc0201046:	00001517          	auipc	a0,0x1
ffffffffc020104a:	27250513          	addi	a0,a0,626 # ffffffffc02022b8 <etext+0x284>
ffffffffc020104e:	974ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0201052 <buddy_init_memmap>:
buddy_init_memmap(struct Page *base, size_t n) {
ffffffffc0201052:	7179                	addi	sp,sp,-48
ffffffffc0201054:	f406                	sd	ra,40(sp)
ffffffffc0201056:	f022                	sd	s0,32(sp)
ffffffffc0201058:	ec26                	sd	s1,24(sp)
ffffffffc020105a:	e84a                	sd	s2,16(sp)
ffffffffc020105c:	e44e                	sd	s3,8(sp)
    assert(n > 0);          // 确保页面数大于0
ffffffffc020105e:	18058463          	beqz	a1,ffffffffc02011e6 <buddy_init_memmap+0x194>
    while (size < n) size <<= 1;  // 循环左移直到找到不小于n的2的幂
ffffffffc0201062:	4705                	li	a4,1
ffffffffc0201064:	84ae                	mv	s1,a1
ffffffffc0201066:	842a                	mv	s0,a0
    unsigned size = 1;      // 初始大小为1
ffffffffc0201068:	4785                	li	a5,1
    while (size < n) size <<= 1;  // 循环左移直到找到不小于n的2的幂
ffffffffc020106a:	12e58563          	beq	a1,a4,ffffffffc0201194 <buddy_init_memmap+0x142>
ffffffffc020106e:	0017979b          	slliw	a5,a5,0x1
ffffffffc0201072:	02079713          	slli	a4,a5,0x20
ffffffffc0201076:	9301                	srli	a4,a4,0x20
ffffffffc0201078:	fe976be3          	bltu	a4,s1,ffffffffc020106e <buddy_init_memmap+0x1c>
    if (size > 2048) {      // 如果超过2048页
ffffffffc020107c:	6705                	lui	a4,0x1
ffffffffc020107e:	80070713          	addi	a4,a4,-2048 # 800 <kern_entry-0xffffffffc01ff800>
ffffffffc0201082:	0007891b          	sext.w	s2,a5
ffffffffc0201086:	10f76463          	bltu	a4,a5,ffffffffc020118e <buddy_init_memmap+0x13c>
    buddy.size = size;      // 设置buddy system的大小
ffffffffc020108a:	00006997          	auipc	s3,0x6
ffffffffc020108e:	f8e98993          	addi	s3,s3,-114 # ffffffffc0207018 <buddy>
    buddy.longest = tree;   // 设置二叉树数组指针
ffffffffc0201092:	00006517          	auipc	a0,0x6
ffffffffc0201096:	f9e50513          	addi	a0,a0,-98 # ffffffffc0207030 <tree.0>
    memset(tree, 0, sizeof(tree));  // 将数组所有元素初始化为0
ffffffffc020109a:	6611                	lui	a2,0x4
ffffffffc020109c:	4581                	li	a1,0
    buddy.size = size;      // 设置buddy system的大小
ffffffffc020109e:	0129a023          	sw	s2,0(s3)
    buddy.base = base;      // 设置内存基地址
ffffffffc02010a2:	0089b823          	sd	s0,16(s3)
    buddy.longest = tree;   // 设置二叉树数组指针
ffffffffc02010a6:	00a9b423          	sd	a0,8(s3)
    memset(tree, 0, sizeof(tree));  // 将数组所有元素初始化为0
ffffffffc02010aa:	779000ef          	jal	ra,ffffffffc0202022 <memset>
    unsigned node_size = size * 2;  // 初始节点大小为2倍总页面数
ffffffffc02010ae:	0019161b          	slliw	a2,s2,0x1
    for (int i = 0; i < 2 * size - 1; ++i) {  // 遍历所有节点
ffffffffc02010b2:	fff6059b          	addiw	a1,a2,-1
        buddy.longest[i] = node_size; // 设置节点的最大可用大小
ffffffffc02010b6:	0089b503          	ld	a0,8(s3)
ffffffffc02010ba:	4781                	li	a5,0
ffffffffc02010bc:	86aa                	mv	a3,a0
        if (IS_POWER_OF_2(i + 1))   // 如果i+1是2的幂（即到达新的一层）
ffffffffc02010be:	873e                	mv	a4,a5
ffffffffc02010c0:	2785                	addiw	a5,a5,1
ffffffffc02010c2:	8f7d                	and	a4,a4,a5
ffffffffc02010c4:	e319                	bnez	a4,ffffffffc02010ca <buddy_init_memmap+0x78>
            node_size /= 2;          // 节点大小减半
ffffffffc02010c6:	0016561b          	srliw	a2,a2,0x1
        buddy.longest[i] = node_size; // 设置节点的最大可用大小
ffffffffc02010ca:	c290                	sw	a2,0(a3)
    for (int i = 0; i < 2 * size - 1; ++i) {  // 遍历所有节点
ffffffffc02010cc:	0691                	addi	a3,a3,4
ffffffffc02010ce:	feb7e8e3          	bltu	a5,a1,ffffffffc02010be <buddy_init_memmap+0x6c>
    for (; p != base + n; p++) {  // 遍历所有实际页面
ffffffffc02010d2:	00249713          	slli	a4,s1,0x2
ffffffffc02010d6:	9726                	add	a4,a4,s1
ffffffffc02010d8:	070e                	slli	a4,a4,0x3
ffffffffc02010da:	9722                	add	a4,a4,s0
        assert(PageReserved(p));  // 确保页面是保留状态
ffffffffc02010dc:	641c                	ld	a5,8(s0)
ffffffffc02010de:	8b85                	andi	a5,a5,1
ffffffffc02010e0:	c3fd                	beqz	a5,ffffffffc02011c6 <buddy_init_memmap+0x174>
        p->flags = p->property = 0;  // 清空页面标志和属性
ffffffffc02010e2:	00042823          	sw	zero,16(s0)
ffffffffc02010e6:	00043423          	sd	zero,8(s0)
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc02010ea:	00042023          	sw	zero,0(s0)
    for (; p != base + n; p++) {  // 遍历所有实际页面
ffffffffc02010ee:	02840413          	addi	s0,s0,40
ffffffffc02010f2:	fee415e3          	bne	s0,a4,ffffffffc02010dc <buddy_init_memmap+0x8a>
    if (n < size) {         // 如果实际页面数小于调整后的2的幂
ffffffffc02010f6:	02091793          	slli	a5,s2,0x20
ffffffffc02010fa:	9381                	srli	a5,a5,0x20
ffffffffc02010fc:	08f4f263          	bgeu	s1,a5,ffffffffc0201180 <buddy_init_memmap+0x12e>
        for (int i = size - 2; i >= 0; i--) {  // 从倒数第二层向上遍历
ffffffffc0201100:	ffe9059b          	addiw	a1,s2,-2
        for (unsigned i = n; i < size; i++) {  // 遍历超出范围的页面
ffffffffc0201104:	2481                	sext.w	s1,s1
        for (int i = size - 2; i >= 0; i--) {  // 从倒数第二层向上遍历
ffffffffc0201106:	87ae                	mv	a5,a1
        for (unsigned i = n; i < size; i++) {  // 遍历超出范围的页面
ffffffffc0201108:	0b24fc63          	bgeu	s1,s2,ffffffffc02011c0 <buddy_init_memmap+0x16e>
ffffffffc020110c:	fff4871b          	addiw	a4,s1,-1
ffffffffc0201110:	fff4c693          	not	a3,s1
ffffffffc0201114:	0127073b          	addw	a4,a4,s2
ffffffffc0201118:	012686bb          	addw	a3,a3,s2
ffffffffc020111c:	1702                	slli	a4,a4,0x20
ffffffffc020111e:	1682                	slli	a3,a3,0x20
ffffffffc0201120:	9301                	srli	a4,a4,0x20
ffffffffc0201122:	9281                	srli	a3,a3,0x20
ffffffffc0201124:	96ba                	add	a3,a3,a4
ffffffffc0201126:	00269613          	slli	a2,a3,0x2
ffffffffc020112a:	070a                	slli	a4,a4,0x2
ffffffffc020112c:	00450693          	addi	a3,a0,4
ffffffffc0201130:	972a                	add	a4,a4,a0
ffffffffc0201132:	96b2                	add	a3,a3,a2
            buddy.longest[index] = 0;         // 标记为不可用（大小为0）
ffffffffc0201134:	00072023          	sw	zero,0(a4)
        for (unsigned i = n; i < size; i++) {  // 遍历超出范围的页面
ffffffffc0201138:	0711                	addi	a4,a4,4
ffffffffc020113a:	fed71de3          	bne	a4,a3,ffffffffc0201134 <buddy_init_memmap+0xe2>
ffffffffc020113e:	0017979b          	slliw	a5,a5,0x1
ffffffffc0201142:	2785                	addiw	a5,a5,1
ffffffffc0201144:	078a                	slli	a5,a5,0x2
ffffffffc0201146:	00259693          	slli	a3,a1,0x2
ffffffffc020114a:	40b008b3          	neg	a7,a1
ffffffffc020114e:	397d                	addiw	s2,s2,-1
ffffffffc0201150:	97aa                	add	a5,a5,a0
ffffffffc0201152:	96aa                	add	a3,a3,a0
ffffffffc0201154:	088e                	slli	a7,a7,0x3
ffffffffc0201156:	090e                	slli	s2,s2,0x3
        for (int i = size - 2; i >= 0; i--) {  // 从倒数第二层向上遍历
ffffffffc0201158:	537d                	li	t1,-1
            unsigned right = buddy.longest[RIGHT_LEAF(i)]; // 右子节点大小
ffffffffc020115a:	01178733          	add	a4,a5,a7
ffffffffc020115e:	974a                	add	a4,a4,s2
            buddy.longest[i] = MAX(left, right);           // 父节点大小为子节点最大值
ffffffffc0201160:	4390                	lw	a2,0(a5)
ffffffffc0201162:	ffc72703          	lw	a4,-4(a4)
ffffffffc0201166:	0006051b          	sext.w	a0,a2
ffffffffc020116a:	0007081b          	sext.w	a6,a4
ffffffffc020116e:	00a87363          	bgeu	a6,a0,ffffffffc0201174 <buddy_init_memmap+0x122>
ffffffffc0201172:	8732                	mv	a4,a2
ffffffffc0201174:	c298                	sw	a4,0(a3)
        for (int i = size - 2; i >= 0; i--) {  // 从倒数第二层向上遍历
ffffffffc0201176:	35fd                	addiw	a1,a1,-1
ffffffffc0201178:	17e1                	addi	a5,a5,-8
ffffffffc020117a:	16f1                	addi	a3,a3,-4
ffffffffc020117c:	fc659fe3          	bne	a1,t1,ffffffffc020115a <buddy_init_memmap+0x108>
}
ffffffffc0201180:	70a2                	ld	ra,40(sp)
ffffffffc0201182:	7402                	ld	s0,32(sp)
ffffffffc0201184:	64e2                	ld	s1,24(sp)
ffffffffc0201186:	6942                	ld	s2,16(sp)
ffffffffc0201188:	69a2                	ld	s3,8(sp)
ffffffffc020118a:	6145                	addi	sp,sp,48
ffffffffc020118c:	8082                	ret
ffffffffc020118e:	0007091b          	sext.w	s2,a4
ffffffffc0201192:	bde5                	j	ffffffffc020108a <buddy_init_memmap+0x38>
    buddy.size = size;      // 设置buddy system的大小
ffffffffc0201194:	00006997          	auipc	s3,0x6
ffffffffc0201198:	e8498993          	addi	s3,s3,-380 # ffffffffc0207018 <buddy>
    buddy.longest = tree;   // 设置二叉树数组指针
ffffffffc020119c:	00006517          	auipc	a0,0x6
ffffffffc02011a0:	e9450513          	addi	a0,a0,-364 # ffffffffc0207030 <tree.0>
    memset(tree, 0, sizeof(tree));  // 将数组所有元素初始化为0
ffffffffc02011a4:	6611                	lui	a2,0x4
ffffffffc02011a6:	4581                	li	a1,0
    buddy.size = size;      // 设置buddy system的大小
ffffffffc02011a8:	0099a023          	sw	s1,0(s3)
    buddy.base = base;      // 设置内存基地址
ffffffffc02011ac:	0089b823          	sd	s0,16(s3)
    buddy.longest = tree;   // 设置二叉树数组指针
ffffffffc02011b0:	00a9b423          	sd	a0,8(s3)
    memset(tree, 0, sizeof(tree));  // 将数组所有元素初始化为0
ffffffffc02011b4:	66f000ef          	jal	ra,ffffffffc0202022 <memset>
ffffffffc02011b8:	4905                	li	s2,1
    for (int i = 0; i < 2 * size - 1; ++i) {  // 遍历所有节点
ffffffffc02011ba:	4585                	li	a1,1
    unsigned node_size = size * 2;  // 初始节点大小为2倍总页面数
ffffffffc02011bc:	4609                	li	a2,2
ffffffffc02011be:	bde5                	j	ffffffffc02010b6 <buddy_init_memmap+0x64>
        for (int i = size - 2; i >= 0; i--) {  // 从倒数第二层向上遍历
ffffffffc02011c0:	fc05c0e3          	bltz	a1,ffffffffc0201180 <buddy_init_memmap+0x12e>
ffffffffc02011c4:	bfad                	j	ffffffffc020113e <buddy_init_memmap+0xec>
        assert(PageReserved(p));  // 确保页面是保留状态
ffffffffc02011c6:	00002697          	auipc	a3,0x2
ffffffffc02011ca:	ae268693          	addi	a3,a3,-1310 # ffffffffc0202ca8 <etext+0xc74>
ffffffffc02011ce:	00001617          	auipc	a2,0x1
ffffffffc02011d2:	0d260613          	addi	a2,a2,210 # ffffffffc02022a0 <etext+0x26c>
ffffffffc02011d6:	06700593          	li	a1,103
ffffffffc02011da:	00001517          	auipc	a0,0x1
ffffffffc02011de:	0de50513          	addi	a0,a0,222 # ffffffffc02022b8 <etext+0x284>
ffffffffc02011e2:	fe1fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(n > 0);          // 确保页面数大于0
ffffffffc02011e6:	00001697          	auipc	a3,0x1
ffffffffc02011ea:	0b268693          	addi	a3,a3,178 # ffffffffc0202298 <etext+0x264>
ffffffffc02011ee:	00001617          	auipc	a2,0x1
ffffffffc02011f2:	0b260613          	addi	a2,a2,178 # ffffffffc02022a0 <etext+0x26c>
ffffffffc02011f6:	04600593          	li	a1,70
ffffffffc02011fa:	00001517          	auipc	a0,0x1
ffffffffc02011fe:	0be50513          	addi	a0,a0,190 # ffffffffc02022b8 <etext+0x284>
ffffffffc0201202:	fc1fe0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0201206 <alloc_pages>:
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
    return pmm_manager->alloc_pages(n);  // 分配n个连续页
ffffffffc0201206:	0000a797          	auipc	a5,0xa
ffffffffc020120a:	0127b783          	ld	a5,18(a5) # ffffffffc020b218 <pmm_manager>
ffffffffc020120e:	6f9c                	ld	a5,24(a5)
ffffffffc0201210:	8782                	jr	a5

ffffffffc0201212 <free_pages>:
}

// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    pmm_manager->free_pages(base, n);  // 释放n个连续页
ffffffffc0201212:	0000a797          	auipc	a5,0xa
ffffffffc0201216:	0067b783          	ld	a5,6(a5) # ffffffffc020b218 <pmm_manager>
ffffffffc020121a:	739c                	ld	a5,32(a5)
ffffffffc020121c:	8782                	jr	a5

ffffffffc020121e <pmm_init>:
    pmm_manager = &slub_pmm_manager;  // 使用SLUB内存管理器
ffffffffc020121e:	00002797          	auipc	a5,0x2
ffffffffc0201222:	e6278793          	addi	a5,a5,-414 # ffffffffc0203080 <slub_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);  // 打印内存管理器名称
ffffffffc0201226:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);  // 初始化空闲内存映射
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc0201228:	7179                	addi	sp,sp,-48
ffffffffc020122a:	f022                	sd	s0,32(sp)
    cprintf("memory management: %s\n", pmm_manager->name);  // 打印内存管理器名称
ffffffffc020122c:	00002517          	auipc	a0,0x2
ffffffffc0201230:	ae450513          	addi	a0,a0,-1308 # ffffffffc0202d10 <buddy_system_pmm_manager+0x38>
    pmm_manager = &slub_pmm_manager;  // 使用SLUB内存管理器
ffffffffc0201234:	0000a417          	auipc	s0,0xa
ffffffffc0201238:	fe440413          	addi	s0,s0,-28 # ffffffffc020b218 <pmm_manager>
void pmm_init(void) {
ffffffffc020123c:	f406                	sd	ra,40(sp)
ffffffffc020123e:	ec26                	sd	s1,24(sp)
ffffffffc0201240:	e44e                	sd	s3,8(sp)
ffffffffc0201242:	e84a                	sd	s2,16(sp)
ffffffffc0201244:	e052                	sd	s4,0(sp)
    pmm_manager = &slub_pmm_manager;  // 使用SLUB内存管理器
ffffffffc0201246:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);  // 打印内存管理器名称
ffffffffc0201248:	f05fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    pmm_manager->init();  // 初始化内存管理器
ffffffffc020124c:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;  // 设置虚拟地址到物理地址的偏移
ffffffffc020124e:	0000a497          	auipc	s1,0xa
ffffffffc0201252:	fe248493          	addi	s1,s1,-30 # ffffffffc020b230 <va_pa_offset>
    pmm_manager->init();  // 初始化内存管理器
ffffffffc0201256:	679c                	ld	a5,8(a5)
ffffffffc0201258:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;  // 设置虚拟地址到物理地址的偏移
ffffffffc020125a:	57f5                	li	a5,-3
ffffffffc020125c:	07fa                	slli	a5,a5,0x1e
ffffffffc020125e:	e09c                	sd	a5,0(s1)
    uint64_t mem_begin = get_memory_base();  // 获取内存起始地址
ffffffffc0201260:	b5cff0ef          	jal	ra,ffffffffc02005bc <get_memory_base>
ffffffffc0201264:	89aa                	mv	s3,a0
    uint64_t mem_size  = get_memory_size();   // 获取内存大小
ffffffffc0201266:	b60ff0ef          	jal	ra,ffffffffc02005c6 <get_memory_size>
    if (mem_size == 0) {
ffffffffc020126a:	14050d63          	beqz	a0,ffffffffc02013c4 <pmm_init+0x1a6>
    uint64_t mem_end   = mem_begin + mem_size;  // 计算内存结束地址
ffffffffc020126e:	892a                	mv	s2,a0
    cprintf("physcial memory map:\n");
ffffffffc0201270:	00002517          	auipc	a0,0x2
ffffffffc0201274:	ae850513          	addi	a0,a0,-1304 # ffffffffc0202d58 <buddy_system_pmm_manager+0x80>
ffffffffc0201278:	ed5fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;  // 计算内存结束地址
ffffffffc020127c:	01298a33          	add	s4,s3,s2
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc0201280:	864e                	mv	a2,s3
ffffffffc0201282:	fffa0693          	addi	a3,s4,-1
ffffffffc0201286:	85ca                	mv	a1,s2
ffffffffc0201288:	00002517          	auipc	a0,0x2
ffffffffc020128c:	ae850513          	addi	a0,a0,-1304 # ffffffffc0202d70 <buddy_system_pmm_manager+0x98>
ffffffffc0201290:	ebdfe0ef          	jal	ra,ffffffffc020014c <cprintf>
    npage = maxpa / PGSIZE;  // 计算总页数
ffffffffc0201294:	c80007b7          	lui	a5,0xc8000
ffffffffc0201298:	8652                	mv	a2,s4
ffffffffc020129a:	0d47e463          	bltu	a5,s4,ffffffffc0201362 <pmm_init+0x144>
ffffffffc020129e:	0000b797          	auipc	a5,0xb
ffffffffc02012a2:	f9978793          	addi	a5,a5,-103 # ffffffffc020c237 <end+0xfff>
ffffffffc02012a6:	757d                	lui	a0,0xfffff
ffffffffc02012a8:	8d7d                	and	a0,a0,a5
ffffffffc02012aa:	8231                	srli	a2,a2,0xc
ffffffffc02012ac:	0000a797          	auipc	a5,0xa
ffffffffc02012b0:	f4c7be23          	sd	a2,-164(a5) # ffffffffc020b208 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);  // 页结构数组起始地址（页对齐）
ffffffffc02012b4:	0000a797          	auipc	a5,0xa
ffffffffc02012b8:	f4a7be23          	sd	a0,-164(a5) # ffffffffc020b210 <pages>
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02012bc:	000807b7          	lui	a5,0x80
ffffffffc02012c0:	002005b7          	lui	a1,0x200
ffffffffc02012c4:	02f60563          	beq	a2,a5,ffffffffc02012ee <pmm_init+0xd0>
ffffffffc02012c8:	00261593          	slli	a1,a2,0x2
ffffffffc02012cc:	00c586b3          	add	a3,a1,a2
ffffffffc02012d0:	fec007b7          	lui	a5,0xfec00
ffffffffc02012d4:	97aa                	add	a5,a5,a0
ffffffffc02012d6:	068e                	slli	a3,a3,0x3
ffffffffc02012d8:	96be                	add	a3,a3,a5
ffffffffc02012da:	87aa                	mv	a5,a0
        SetPageReserved(pages + i);  // 标记所有页为保留状态
ffffffffc02012dc:	6798                	ld	a4,8(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02012de:	02878793          	addi	a5,a5,40 # fffffffffec00028 <end+0x3e9f4df0>
        SetPageReserved(pages + i);  // 标记所有页为保留状态
ffffffffc02012e2:	00176713          	ori	a4,a4,1
ffffffffc02012e6:	fee7b023          	sd	a4,-32(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02012ea:	fef699e3          	bne	a3,a5,ffffffffc02012dc <pmm_init+0xbe>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));  // 空闲内存起始地址
ffffffffc02012ee:	95b2                	add	a1,a1,a2
ffffffffc02012f0:	fec006b7          	lui	a3,0xfec00
ffffffffc02012f4:	96aa                	add	a3,a3,a0
ffffffffc02012f6:	058e                	slli	a1,a1,0x3
ffffffffc02012f8:	96ae                	add	a3,a3,a1
ffffffffc02012fa:	c02007b7          	lui	a5,0xc0200
ffffffffc02012fe:	0af6e763          	bltu	a3,a5,ffffffffc02013ac <pmm_init+0x18e>
ffffffffc0201302:	6098                	ld	a4,0(s1)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);   // 内存结束地址（页对齐）
ffffffffc0201304:	77fd                	lui	a5,0xfffff
ffffffffc0201306:	00fa75b3          	and	a1,s4,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));  // 空闲内存起始地址
ffffffffc020130a:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc020130c:	04b6ee63          	bltu	a3,a1,ffffffffc0201368 <pmm_init+0x14a>
    satp_physical = PADDR(satp_virtual);          // 计算页表物理地址
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);  // 打印页表地址
}

static void check_alloc_page(void) {
    pmm_manager->check();  // 调用内存管理器的检查函数
ffffffffc0201310:	601c                	ld	a5,0(s0)
ffffffffc0201312:	7b9c                	ld	a5,48(a5)
ffffffffc0201314:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");  // 检查成功
ffffffffc0201316:	00002517          	auipc	a0,0x2
ffffffffc020131a:	ae250513          	addi	a0,a0,-1310 # ffffffffc0202df8 <buddy_system_pmm_manager+0x120>
ffffffffc020131e:	e2ffe0ef          	jal	ra,ffffffffc020014c <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;  // 设置页表虚拟地址
ffffffffc0201322:	00005597          	auipc	a1,0x5
ffffffffc0201326:	cde58593          	addi	a1,a1,-802 # ffffffffc0206000 <boot_page_table_sv39>
ffffffffc020132a:	0000a797          	auipc	a5,0xa
ffffffffc020132e:	eeb7bf23          	sd	a1,-258(a5) # ffffffffc020b228 <satp_virtual>
    satp_physical = PADDR(satp_virtual);          // 计算页表物理地址
ffffffffc0201332:	c02007b7          	lui	a5,0xc0200
ffffffffc0201336:	0af5e363          	bltu	a1,a5,ffffffffc02013dc <pmm_init+0x1be>
ffffffffc020133a:	6090                	ld	a2,0(s1)
}
ffffffffc020133c:	7402                	ld	s0,32(sp)
ffffffffc020133e:	70a2                	ld	ra,40(sp)
ffffffffc0201340:	64e2                	ld	s1,24(sp)
ffffffffc0201342:	6942                	ld	s2,16(sp)
ffffffffc0201344:	69a2                	ld	s3,8(sp)
ffffffffc0201346:	6a02                	ld	s4,0(sp)
    satp_physical = PADDR(satp_virtual);          // 计算页表物理地址
ffffffffc0201348:	40c58633          	sub	a2,a1,a2
ffffffffc020134c:	0000a797          	auipc	a5,0xa
ffffffffc0201350:	ecc7ba23          	sd	a2,-300(a5) # ffffffffc020b220 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);  // 打印页表地址
ffffffffc0201354:	00002517          	auipc	a0,0x2
ffffffffc0201358:	ac450513          	addi	a0,a0,-1340 # ffffffffc0202e18 <buddy_system_pmm_manager+0x140>
}
ffffffffc020135c:	6145                	addi	sp,sp,48
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);  // 打印页表地址
ffffffffc020135e:	deffe06f          	j	ffffffffc020014c <cprintf>
    npage = maxpa / PGSIZE;  // 计算总页数
ffffffffc0201362:	c8000637          	lui	a2,0xc8000
ffffffffc0201366:	bf25                	j	ffffffffc020129e <pmm_init+0x80>
    mem_begin = ROUNDUP(freemem, PGSIZE);  // 空闲内存起始地址（页对齐）
ffffffffc0201368:	6705                	lui	a4,0x1
ffffffffc020136a:	177d                	addi	a4,a4,-1
ffffffffc020136c:	96ba                	add	a3,a3,a4
ffffffffc020136e:	8efd                	and	a3,a3,a5
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0201370:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201374:	02c7f063          	bgeu	a5,a2,ffffffffc0201394 <pmm_init+0x176>
    pmm_manager->init_memmap(base, n);  // 初始化内存映射，构建空闲页结构
ffffffffc0201378:	6010                	ld	a2,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc020137a:	fff80737          	lui	a4,0xfff80
ffffffffc020137e:	973e                	add	a4,a4,a5
ffffffffc0201380:	00271793          	slli	a5,a4,0x2
ffffffffc0201384:	97ba                	add	a5,a5,a4
ffffffffc0201386:	6a18                	ld	a4,16(a2)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);  // 初始化空闲内存映射
ffffffffc0201388:	8d95                	sub	a1,a1,a3
ffffffffc020138a:	078e                	slli	a5,a5,0x3
    pmm_manager->init_memmap(base, n);  // 初始化内存映射，构建空闲页结构
ffffffffc020138c:	81b1                	srli	a1,a1,0xc
ffffffffc020138e:	953e                	add	a0,a0,a5
ffffffffc0201390:	9702                	jalr	a4
}
ffffffffc0201392:	bfbd                	j	ffffffffc0201310 <pmm_init+0xf2>
        panic("pa2page called with invalid pa");
ffffffffc0201394:	00002617          	auipc	a2,0x2
ffffffffc0201398:	a3460613          	addi	a2,a2,-1484 # ffffffffc0202dc8 <buddy_system_pmm_manager+0xf0>
ffffffffc020139c:	07100593          	li	a1,113
ffffffffc02013a0:	00002517          	auipc	a0,0x2
ffffffffc02013a4:	a4850513          	addi	a0,a0,-1464 # ffffffffc0202de8 <buddy_system_pmm_manager+0x110>
ffffffffc02013a8:	e1bfe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));  // 空闲内存起始地址
ffffffffc02013ac:	00002617          	auipc	a2,0x2
ffffffffc02013b0:	9f460613          	addi	a2,a2,-1548 # ffffffffc0202da0 <buddy_system_pmm_manager+0xc8>
ffffffffc02013b4:	06300593          	li	a1,99
ffffffffc02013b8:	00002517          	auipc	a0,0x2
ffffffffc02013bc:	99050513          	addi	a0,a0,-1648 # ffffffffc0202d48 <buddy_system_pmm_manager+0x70>
ffffffffc02013c0:	e03fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        panic("DTB memory info not available");  // 内存信息不可用
ffffffffc02013c4:	00002617          	auipc	a2,0x2
ffffffffc02013c8:	96460613          	addi	a2,a2,-1692 # ffffffffc0202d28 <buddy_system_pmm_manager+0x50>
ffffffffc02013cc:	04b00593          	li	a1,75
ffffffffc02013d0:	00002517          	auipc	a0,0x2
ffffffffc02013d4:	97850513          	addi	a0,a0,-1672 # ffffffffc0202d48 <buddy_system_pmm_manager+0x70>
ffffffffc02013d8:	debfe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    satp_physical = PADDR(satp_virtual);          // 计算页表物理地址
ffffffffc02013dc:	86ae                	mv	a3,a1
ffffffffc02013de:	00002617          	auipc	a2,0x2
ffffffffc02013e2:	9c260613          	addi	a2,a2,-1598 # ffffffffc0202da0 <buddy_system_pmm_manager+0xc8>
ffffffffc02013e6:	07e00593          	li	a1,126
ffffffffc02013ea:	00002517          	auipc	a0,0x2
ffffffffc02013ee:	95e50513          	addi	a0,a0,-1698 # ffffffffc0202d48 <buddy_system_pmm_manager+0x70>
ffffffffc02013f2:	dd1fe0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc02013f6 <slub_init>:
    return NULL; // 超过 4096B 的对象不适用 SLUB（交给页级）
}

// 初始化所有 size 的 cache
static void slub_init_caches(void) {
    for (unsigned i = 0; i < SLUB_SIZE_CLASS_COUNT; i++) {
ffffffffc02013f6:	0000a797          	auipc	a5,0xa
ffffffffc02013fa:	c4a78793          	addi	a5,a5,-950 # ffffffffc020b040 <caches+0x10>
ffffffffc02013fe:	00002617          	auipc	a2,0x2
ffffffffc0201402:	cba60613          	addi	a2,a2,-838 # ffffffffc02030b8 <slub_sizes>
ffffffffc0201406:	0000a817          	auipc	a6,0xa
ffffffffc020140a:	dfa80813          	addi	a6,a6,-518 # ffffffffc020b200 <memory_size>
    }
}

// 以下实现 pmm_manager 风格一致的接口，以便在 pmm.c 中切换到 SLUB

static void slub_init(void) {
ffffffffc020140e:	02000693          	li	a3,32
ffffffffc0201412:	00002517          	auipc	a0,0x2
ffffffffc0201416:	a4650513          	addi	a0,a0,-1466 # ffffffffc0202e58 <buddy_system_pmm_manager+0x180>
ffffffffc020141a:	a011                	j	ffffffffc020141e <slub_init+0x28>
        caches[i].objsize = slub_sizes[i];
ffffffffc020141c:	4214                	lw	a3,0(a2)
        caches[i].slab_pages = (slub_sizes[i] == 2048) ? 2 : 1; // 2048B 使用双页 slab
ffffffffc020141e:	8006871b          	addiw	a4,a3,-2048
ffffffffc0201422:	00173713          	seqz	a4,a4
ffffffffc0201426:	01078593          	addi	a1,a5,16
ffffffffc020142a:	0705                	addi	a4,a4,1
        caches[i].objsize = slub_sizes[i];
ffffffffc020142c:	fed7ac23          	sw	a3,-8(a5)
        caches[i].name = "slub";
ffffffffc0201430:	fea7b823          	sd	a0,-16(a5)
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;  // 初始化节点，指向自己形成空链表
ffffffffc0201434:	e79c                	sd	a5,8(a5)
ffffffffc0201436:	e39c                	sd	a5,0(a5)
ffffffffc0201438:	ef8c                	sd	a1,24(a5)
ffffffffc020143a:	eb8c                	sd	a1,16(a5)
        caches[i].slab_pages = (slub_sizes[i] == 2048) ? 2 : 1; // 2048B 使用双页 slab
ffffffffc020143c:	d398                	sw	a4,32(a5)
    for (unsigned i = 0; i < SLUB_SIZE_CLASS_COUNT; i++) {
ffffffffc020143e:	03878793          	addi	a5,a5,56
ffffffffc0201442:	0611                	addi	a2,a2,4
ffffffffc0201444:	fd079ce3          	bne	a5,a6,ffffffffc020141c <slub_init+0x26>
    // 初始化 SLUB 自己的数据结构
    slub_init_caches();
}
ffffffffc0201448:	8082                	ret

ffffffffc020144a <slub_init_memmap>:

static void slub_init_memmap(struct Page *base, size_t n) {
    // 交给 buddy 的 init_memmap，保证页级空间建立
    buddy_system_pmm_manager.init_memmap(base, n);
ffffffffc020144a:	00002797          	auipc	a5,0x2
ffffffffc020144e:	89e7b783          	ld	a5,-1890(a5) # ffffffffc0202ce8 <buddy_system_pmm_manager+0x10>
ffffffffc0201452:	8782                	jr	a5

ffffffffc0201454 <slub_alloc_pages>:
// 分配 n 页：为了和 pmm 接口兼容，这里保留页级语义；
// 若用户通过对象接口分配（例如 alloc_pages(1) 但想要对象大小），我们提供一个“对象模式”的入口：
// 在测试和文档里会说明，调用 slub_alloc(size) 来拿对象；pmm 的 alloc_pages 仍表示页。
static struct Page *slub_alloc_pages(size_t n) {
    // 直接委托给 buddy 系统，保持页级分配行为
    return buddy_system_pmm_manager.alloc_pages(n);
ffffffffc0201454:	00002797          	auipc	a5,0x2
ffffffffc0201458:	89c7b783          	ld	a5,-1892(a5) # ffffffffc0202cf0 <buddy_system_pmm_manager+0x18>
ffffffffc020145c:	8782                	jr	a5

ffffffffc020145e <slub_free_pages>:
}

static void slub_free_pages(struct Page *base, size_t n) {
    // 直接委托给 buddy 系统，保持页级释放行为
    buddy_system_pmm_manager.free_pages(base, n);
ffffffffc020145e:	00002797          	auipc	a5,0x2
ffffffffc0201462:	89a7b783          	ld	a5,-1894(a5) # ffffffffc0202cf8 <buddy_system_pmm_manager+0x20>
ffffffffc0201466:	8782                	jr	a5

ffffffffc0201468 <slub_nr_free_pages>:
}

static size_t slub_nr_free_pages(void) {
    // 返回 buddy 的统计（页级）
    return buddy_system_pmm_manager.nr_free_pages();
ffffffffc0201468:	00002797          	auipc	a5,0x2
ffffffffc020146c:	8987b783          	ld	a5,-1896(a5) # ffffffffc0202d00 <buddy_system_pmm_manager+0x28>
ffffffffc0201470:	8782                	jr	a5

ffffffffc0201472 <slub_free>:
    for (unsigned i = 0; i < SLUB_SIZE_CLASS_COUNT; i++) {
ffffffffc0201472:	00002697          	auipc	a3,0x2
ffffffffc0201476:	c4668693          	addi	a3,a3,-954 # ffffffffc02030b8 <slub_sizes>
        list_add(&cache->slabs_full, &slab->link);
    }
    return obj;
}

static void slub_free(void *obj, size_t size) {
ffffffffc020147a:	02000793          	li	a5,32
    for (unsigned i = 0; i < SLUB_SIZE_CLASS_COUNT; i++) {
ffffffffc020147e:	4701                	li	a4,0
ffffffffc0201480:	4621                	li	a2,8
ffffffffc0201482:	a011                	j	ffffffffc0201486 <slub_free+0x14>
        if (size <= slub_sizes[i]) return &caches[i];
ffffffffc0201484:	429c                	lw	a5,0(a3)
ffffffffc0201486:	1782                	slli	a5,a5,0x20
ffffffffc0201488:	9381                	srli	a5,a5,0x20
ffffffffc020148a:	00b7f763          	bgeu	a5,a1,ffffffffc0201498 <slub_free+0x26>
    for (unsigned i = 0; i < SLUB_SIZE_CLASS_COUNT; i++) {
ffffffffc020148e:	2705                	addiw	a4,a4,1
ffffffffc0201490:	0691                	addi	a3,a3,4
ffffffffc0201492:	fec719e3          	bne	a4,a2,ffffffffc0201484 <slub_free+0x12>
        // 原来是满的，刚释放后不满
        list_del(&slab->link);
        list_add(&cache->slabs_partial, &slab->link);
    }
    // 当 slab 变为空，可以考虑回收页
}
ffffffffc0201496:	8082                	ret
    uintptr_t slab_base_pa = ROUNDDOWN(obj_pa, PGSIZE * cache->slab_pages);
ffffffffc0201498:	1702                	slli	a4,a4,0x20
ffffffffc020149a:	9301                	srli	a4,a4,0x20
ffffffffc020149c:	00371793          	slli	a5,a4,0x3
ffffffffc02014a0:	8f99                	sub	a5,a5,a4
ffffffffc02014a2:	0000a617          	auipc	a2,0xa
ffffffffc02014a6:	b8e60613          	addi	a2,a2,-1138 # ffffffffc020b030 <caches>
ffffffffc02014aa:	078e                	slli	a5,a5,0x3
ffffffffc02014ac:	97b2                	add	a5,a5,a2
ffffffffc02014ae:	5b94                	lw	a3,48(a5)
    uintptr_t obj_pa = (uintptr_t)obj - va_pa_offset;
ffffffffc02014b0:	0000a797          	auipc	a5,0xa
ffffffffc02014b4:	d807b783          	ld	a5,-640(a5) # ffffffffc020b230 <va_pa_offset>
ffffffffc02014b8:	40f507b3          	sub	a5,a0,a5
    uintptr_t slab_base_pa = ROUNDDOWN(obj_pa, PGSIZE * cache->slab_pages);
ffffffffc02014bc:	00c6969b          	slliw	a3,a3,0xc
ffffffffc02014c0:	1682                	slli	a3,a3,0x20
ffffffffc02014c2:	9281                	srli	a3,a3,0x20
ffffffffc02014c4:	02d7f7b3          	remu	a5,a5,a3
    slub_slab_t *slab = (slub_slab_t *)(slab_base_pa + va_pa_offset);
ffffffffc02014c8:	40f507b3          	sub	a5,a0,a5
 * Insert the new element @elm *after* the element @listelm which
 * is already in the list.
 * */
static inline void
list_add_after(list_entry_t *listelm, list_entry_t *elm) {
    __list_add(elm, listelm, listelm->next);  // 在指定节点后添加新节点
ffffffffc02014cc:	738c                	ld	a1,32(a5)
    if (slab->inuse > 0) slab->inuse--;
ffffffffc02014ce:	5794                	lw	a3,40(a5)
    list_add(&slab->free_list, &node->link);
ffffffffc02014d0:	01878813          	addi	a6,a5,24
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;  // 在prev和next之间插入新节点elm
ffffffffc02014d4:	e188                	sd	a0,0(a1)
ffffffffc02014d6:	f388                	sd	a0,32(a5)
    elm->next = next;               // 设置新节点的后继
ffffffffc02014d8:	e50c                	sd	a1,8(a0)
    elm->prev = prev;               // 设置新节点的前驱
ffffffffc02014da:	01053023          	sd	a6,0(a0)
    if (slab->inuse > 0) slab->inuse--;
ffffffffc02014de:	ee8d                	bnez	a3,ffffffffc0201518 <slub_free+0xa6>
ffffffffc02014e0:	4685                	li	a3,1
    if (slab->inuse + 1 == slab->capacity) {
ffffffffc02014e2:	5b8c                	lw	a1,48(a5)
ffffffffc02014e4:	fad599e3          	bne	a1,a3,ffffffffc0201496 <slub_free+0x24>
    __list_del(listelm->prev, listelm->next);  // 从链表中删除节点
ffffffffc02014e8:	6b88                	ld	a0,16(a5)
ffffffffc02014ea:	0087b803          	ld	a6,8(a5)
ffffffffc02014ee:	00371693          	slli	a3,a4,0x3
ffffffffc02014f2:	40e68733          	sub	a4,a3,a4
ffffffffc02014f6:	070e                	slli	a4,a4,0x3
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;  // 前驱节点指向后继节点
ffffffffc02014f8:	00a83423          	sd	a0,8(a6)
        if (size <= slub_sizes[i]) return &caches[i];
ffffffffc02014fc:	00e605b3          	add	a1,a2,a4
    __list_add(elm, listelm, listelm->next);  // 在指定节点后添加新节点
ffffffffc0201500:	6d94                	ld	a3,24(a1)
    next->prev = prev;  // 后继节点指向前驱节点
ffffffffc0201502:	01053023          	sd	a6,0(a0)
        list_add(&cache->slabs_partial, &slab->link);
ffffffffc0201506:	00878513          	addi	a0,a5,8
    prev->next = next->prev = elm;  // 在prev和next之间插入新节点elm
ffffffffc020150a:	e288                	sd	a0,0(a3)
ffffffffc020150c:	0741                	addi	a4,a4,16
ffffffffc020150e:	ed88                	sd	a0,24(a1)
ffffffffc0201510:	963a                	add	a2,a2,a4
    elm->next = next;               // 设置新节点的后继
ffffffffc0201512:	eb94                	sd	a3,16(a5)
    elm->prev = prev;               // 设置新节点的前驱
ffffffffc0201514:	e790                	sd	a2,8(a5)
}
ffffffffc0201516:	8082                	ret
    if (slab->inuse > 0) slab->inuse--;
ffffffffc0201518:	fff6859b          	addiw	a1,a3,-1
ffffffffc020151c:	d78c                	sw	a1,40(a5)
ffffffffc020151e:	b7d1                	j	ffffffffc02014e2 <slub_free+0x70>

ffffffffc0201520 <slub_alloc>:
static void *slub_alloc(size_t size) {
ffffffffc0201520:	7139                	addi	sp,sp,-64
ffffffffc0201522:	fc06                	sd	ra,56(sp)
ffffffffc0201524:	f822                	sd	s0,48(sp)
ffffffffc0201526:	f426                	sd	s1,40(sp)
ffffffffc0201528:	f04a                	sd	s2,32(sp)
ffffffffc020152a:	ec4e                	sd	s3,24(sp)
ffffffffc020152c:	e852                	sd	s4,16(sp)
ffffffffc020152e:	e456                	sd	s5,8(sp)
ffffffffc0201530:	e05a                	sd	s6,0(sp)
ffffffffc0201532:	00002697          	auipc	a3,0x2
ffffffffc0201536:	b8668693          	addi	a3,a3,-1146 # ffffffffc02030b8 <slub_sizes>
ffffffffc020153a:	02000793          	li	a5,32
    for (unsigned i = 0; i < SLUB_SIZE_CLASS_COUNT; i++) {
ffffffffc020153e:	4701                	li	a4,0
ffffffffc0201540:	4621                	li	a2,8
ffffffffc0201542:	a011                	j	ffffffffc0201546 <slub_alloc+0x26>
        if (size <= slub_sizes[i]) return &caches[i];
ffffffffc0201544:	429c                	lw	a5,0(a3)
ffffffffc0201546:	1782                	slli	a5,a5,0x20
ffffffffc0201548:	9381                	srli	a5,a5,0x20
ffffffffc020154a:	06a7f163          	bgeu	a5,a0,ffffffffc02015ac <slub_alloc+0x8c>
    for (unsigned i = 0; i < SLUB_SIZE_CLASS_COUNT; i++) {
ffffffffc020154e:	2705                	addiw	a4,a4,1
ffffffffc0201550:	0691                	addi	a3,a3,4
ffffffffc0201552:	fec719e3          	bne	a4,a2,ffffffffc0201544 <slub_alloc+0x24>
        struct Page *pg = buddy_system_pmm_manager.alloc_pages((size + PGSIZE - 1)/PGSIZE);
ffffffffc0201556:	6785                	lui	a5,0x1
ffffffffc0201558:	17fd                	addi	a5,a5,-1
ffffffffc020155a:	953e                	add	a0,a0,a5
ffffffffc020155c:	8131                	srli	a0,a0,0xc
ffffffffc020155e:	00001797          	auipc	a5,0x1
ffffffffc0201562:	7927b783          	ld	a5,1938(a5) # ffffffffc0202cf0 <buddy_system_pmm_manager+0x18>
ffffffffc0201566:	9782                	jalr	a5
        if (!pg) return NULL;
ffffffffc0201568:	c955                	beqz	a0,ffffffffc020161c <slub_alloc+0xfc>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020156a:	0000a797          	auipc	a5,0xa
ffffffffc020156e:	ca67b783          	ld	a5,-858(a5) # ffffffffc020b210 <pages>
ffffffffc0201572:	8d1d                	sub	a0,a0,a5
ffffffffc0201574:	850d                	srai	a0,a0,0x3
ffffffffc0201576:	00002797          	auipc	a5,0x2
ffffffffc020157a:	daa7b783          	ld	a5,-598(a5) # ffffffffc0203320 <error_string+0x38>
ffffffffc020157e:	02f50533          	mul	a0,a0,a5
ffffffffc0201582:	00002797          	auipc	a5,0x2
ffffffffc0201586:	da67b783          	ld	a5,-602(a5) # ffffffffc0203328 <nbase>
ffffffffc020158a:	953e                	add	a0,a0,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc020158c:	0532                	slli	a0,a0,0xc
        return (void *)(page2pa(pg) + va_pa_offset);
ffffffffc020158e:	0000a797          	auipc	a5,0xa
ffffffffc0201592:	ca27b783          	ld	a5,-862(a5) # ffffffffc020b230 <va_pa_offset>
ffffffffc0201596:	953e                	add	a0,a0,a5
}
ffffffffc0201598:	70e2                	ld	ra,56(sp)
ffffffffc020159a:	7442                	ld	s0,48(sp)
ffffffffc020159c:	74a2                	ld	s1,40(sp)
ffffffffc020159e:	7902                	ld	s2,32(sp)
ffffffffc02015a0:	69e2                	ld	s3,24(sp)
ffffffffc02015a2:	6a42                	ld	s4,16(sp)
ffffffffc02015a4:	6aa2                	ld	s5,8(sp)
ffffffffc02015a6:	6b02                	ld	s6,0(sp)
ffffffffc02015a8:	6121                	addi	sp,sp,64
ffffffffc02015aa:	8082                	ret
    if (cache == NULL || cache->objsize == PGSIZE) {
ffffffffc02015ac:	1702                	slli	a4,a4,0x20
ffffffffc02015ae:	9301                	srli	a4,a4,0x20
ffffffffc02015b0:	00371413          	slli	s0,a4,0x3
ffffffffc02015b4:	8c19                	sub	s0,s0,a4
ffffffffc02015b6:	0000a917          	auipc	s2,0xa
ffffffffc02015ba:	a7a90913          	addi	s2,s2,-1414 # ffffffffc020b030 <caches>
ffffffffc02015be:	040e                	slli	s0,s0,0x3
ffffffffc02015c0:	008909b3          	add	s3,s2,s0
ffffffffc02015c4:	0089a683          	lw	a3,8(s3)
ffffffffc02015c8:	6785                	lui	a5,0x1
ffffffffc02015ca:	f8f686e3          	beq	a3,a5,ffffffffc0201556 <slub_alloc+0x36>
    list_entry_t *le = &cache->slabs_partial;
ffffffffc02015ce:	01040793          	addi	a5,s0,16
ffffffffc02015d2:	97ca                	add	a5,a5,s2
ffffffffc02015d4:	84be                	mv	s1,a5
    return listelm->next;  // 获取下一个节点
ffffffffc02015d6:	6484                	ld	s1,8(s1)
    if (list_empty(&slab->free_list)) return NULL;
ffffffffc02015d8:	01048693          	addi	a3,s1,16
    while ((le = list_next(le)) != &cache->slabs_partial) {
ffffffffc02015dc:	04978263          	beq	a5,s1,ffffffffc0201620 <slub_alloc+0x100>
    return list->next == list;  // 检查链表是否为空（指向自己）
ffffffffc02015e0:	6c88                	ld	a0,24(s1)
    if (list_empty(&slab->free_list)) return NULL;
ffffffffc02015e2:	fed50ae3          	beq	a0,a3,ffffffffc02015d6 <slub_alloc+0xb6>
    __list_del(listelm->prev, listelm->next);  // 从链表中删除节点
ffffffffc02015e6:	6518                	ld	a4,8(a0)
ffffffffc02015e8:	6114                	ld	a3,0(a0)
    slab->inuse++;
ffffffffc02015ea:	509c                	lw	a5,32(s1)
            if (slab->inuse == slab->capacity) {
ffffffffc02015ec:	5490                	lw	a2,40(s1)
    prev->next = next;  // 前驱节点指向后继节点
ffffffffc02015ee:	e698                	sd	a4,8(a3)
    slab->inuse++;
ffffffffc02015f0:	2785                	addiw	a5,a5,1
    next->prev = prev;  // 后继节点指向前驱节点
ffffffffc02015f2:	e314                	sd	a3,0(a4)
ffffffffc02015f4:	d09c                	sw	a5,32(s1)
ffffffffc02015f6:	0007871b          	sext.w	a4,a5
            if (slab->inuse == slab->capacity) {
ffffffffc02015fa:	f8e61fe3          	bne	a2,a4,ffffffffc0201598 <slub_alloc+0x78>
    __list_del(listelm->prev, listelm->next);  // 从链表中删除节点
ffffffffc02015fe:	6090                	ld	a2,0(s1)
ffffffffc0201600:	6494                	ld	a3,8(s1)
                list_add(&cache->slabs_full, &slab->link);
ffffffffc0201602:	02040793          	addi	a5,s0,32
ffffffffc0201606:	97ca                	add	a5,a5,s2
    prev->next = next;  // 前驱节点指向后继节点
ffffffffc0201608:	e614                	sd	a3,8(a2)
    __list_add(elm, listelm, listelm->next);  // 在指定节点后添加新节点
ffffffffc020160a:	0289b703          	ld	a4,40(s3)
    next->prev = prev;  // 后继节点指向前驱节点
ffffffffc020160e:	e290                	sd	a2,0(a3)
    prev->next = next->prev = elm;  // 在prev和next之间插入新节点elm
ffffffffc0201610:	e304                	sd	s1,0(a4)
ffffffffc0201612:	0299b423          	sd	s1,40(s3)
    elm->next = next;               // 设置新节点的后继
ffffffffc0201616:	e498                	sd	a4,8(s1)
    elm->prev = prev;               // 设置新节点的前驱
ffffffffc0201618:	e09c                	sd	a5,0(s1)
}
ffffffffc020161a:	bfbd                	j	ffffffffc0201598 <slub_alloc+0x78>
        if (!pg) return NULL;
ffffffffc020161c:	4501                	li	a0,0
ffffffffc020161e:	bfad                	j	ffffffffc0201598 <slub_alloc+0x78>
    struct Page *page = buddy_system_pmm_manager.alloc_pages(cache->slab_pages);
ffffffffc0201620:	00371a93          	slli	s5,a4,0x3
ffffffffc0201624:	40ea8733          	sub	a4,s5,a4
ffffffffc0201628:	00371a93          	slli	s5,a4,0x3
ffffffffc020162c:	9aca                	add	s5,s5,s2
ffffffffc020162e:	030ae503          	lwu	a0,48(s5)
ffffffffc0201632:	00001797          	auipc	a5,0x1
ffffffffc0201636:	6be7b783          	ld	a5,1726(a5) # ffffffffc0202cf0 <buddy_system_pmm_manager+0x18>
ffffffffc020163a:	9782                	jalr	a5
ffffffffc020163c:	8b2a                	mv	s6,a0
    if (page == NULL) return NULL;
ffffffffc020163e:	dd79                	beqz	a0,ffffffffc020161c <slub_alloc+0xfc>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201640:	0000a797          	auipc	a5,0xa
ffffffffc0201644:	bd07b783          	ld	a5,-1072(a5) # ffffffffc020b210 <pages>
ffffffffc0201648:	40f507b3          	sub	a5,a0,a5
ffffffffc020164c:	00002717          	auipc	a4,0x2
ffffffffc0201650:	cd473703          	ld	a4,-812(a4) # ffffffffc0203320 <error_string+0x38>
ffffffffc0201654:	878d                	srai	a5,a5,0x3
ffffffffc0201656:	02e787b3          	mul	a5,a5,a4
    memset(page_va, 0, PGSIZE * cache->slab_pages); //清零整页内容。
ffffffffc020165a:	030aa603          	lw	a2,48(s5)
ffffffffc020165e:	00002a17          	auipc	s4,0x2
ffffffffc0201662:	ccaa3a03          	ld	s4,-822(s4) # ffffffffc0203328 <nbase>
ffffffffc0201666:	4581                	li	a1,0
ffffffffc0201668:	00c6161b          	slliw	a2,a2,0xc
ffffffffc020166c:	1602                	slli	a2,a2,0x20
ffffffffc020166e:	9201                	srli	a2,a2,0x20
ffffffffc0201670:	9a3e                	add	s4,s4,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0201672:	0a32                	slli	s4,s4,0xc
    void *page_va = (void *)(page2pa(page) + va_pa_offset); //用 page2pa + va_pa_offset = kva 拿到这块页的内核虚拟地址
ffffffffc0201674:	0000a797          	auipc	a5,0xa
ffffffffc0201678:	bbc7b783          	ld	a5,-1092(a5) # ffffffffc020b230 <va_pa_offset>
ffffffffc020167c:	9a3e                	add	s4,s4,a5
    memset(page_va, 0, PGSIZE * cache->slab_pages); //清零整页内容。
ffffffffc020167e:	8552                	mv	a0,s4
ffffffffc0201680:	1a3000ef          	jal	ra,ffffffffc0202022 <memset>
    list_init(&slab->link);
ffffffffc0201684:	008a0313          	addi	t1,s4,8
    list_init(&slab->free_list);
ffffffffc0201688:	018a0593          	addi	a1,s4,24
    elm->prev = elm->next = elm;  // 初始化节点，指向自己形成空链表
ffffffffc020168c:	006a3823          	sd	t1,16(s4)
ffffffffc0201690:	006a3423          	sd	t1,8(s4)
ffffffffc0201694:	02ba3023          	sd	a1,32(s4)
ffffffffc0201698:	00ba3c23          	sd	a1,24(s4)
    unsigned total = PGSIZE * cache->slab_pages;
ffffffffc020169c:	030aa783          	lw	a5,48(s5)
    slab->objsize = cache->objsize;
ffffffffc02016a0:	008aa883          	lw	a7,8(s5)
    slab->page = page;            //把 slub_slab_t 元数据直接放在 slab 页的开头(真实 Linux SLUB 把元数据放其它地方)
ffffffffc02016a4:	016a3023          	sd	s6,0(s4)
    unsigned total = PGSIZE * cache->slab_pages;
ffffffffc02016a8:	00c7979b          	slliw	a5,a5,0xc
    unsigned usable = total - sizeof(slub_slab_t);
ffffffffc02016ac:	fc87879b          	addiw	a5,a5,-56
    slab->capacity = usable / cache->objsize;       //刚刚写错的函数在这重写了一边，考虑元数据占的空间，向下整除
ffffffffc02016b0:	0317d83b          	divuw	a6,a5,a7
    slab->inuse = 0;
ffffffffc02016b4:	020a2423          	sw	zero,40(s4)
    slab->objsize = cache->objsize;
ffffffffc02016b8:	031a2623          	sw	a7,44(s4)
    slab->capacity = usable / cache->objsize;       //刚刚写错的函数在这重写了一边，考虑元数据占的空间，向下整除
ffffffffc02016bc:	030a2823          	sw	a6,48(s4)
    for (unsigned i = 0; i < slab->capacity; i++) {
ffffffffc02016c0:	0317e863          	bltu	a5,a7,ffffffffc02016f0 <slub_alloc+0x1d0>
ffffffffc02016c4:	862e                	mv	a2,a1
ffffffffc02016c6:	4681                	li	a3,0
ffffffffc02016c8:	4701                	li	a4,0
ffffffffc02016ca:	a019                	j	ffffffffc02016d0 <slub_alloc+0x1b0>
    __list_add(elm, listelm, listelm->next);  // 在指定节点后添加新节点
ffffffffc02016cc:	020a3603          	ld	a2,32(s4)
        obj_node_t *node = (obj_node_t *)(obj_base + i * cache->objsize);
ffffffffc02016d0:	02069793          	slli	a5,a3,0x20
ffffffffc02016d4:	9381                	srli	a5,a5,0x20
ffffffffc02016d6:	03878793          	addi	a5,a5,56
ffffffffc02016da:	97d2                	add	a5,a5,s4
    prev->next = next->prev = elm;  // 在prev和next之间插入新节点elm
ffffffffc02016dc:	e21c                	sd	a5,0(a2)
ffffffffc02016de:	02fa3023          	sd	a5,32(s4)
    elm->next = next;               // 设置新节点的后继
ffffffffc02016e2:	e790                	sd	a2,8(a5)
    elm->prev = prev;               // 设置新节点的前驱
ffffffffc02016e4:	e38c                	sd	a1,0(a5)
    for (unsigned i = 0; i < slab->capacity; i++) {
ffffffffc02016e6:	2705                	addiw	a4,a4,1
ffffffffc02016e8:	00d886bb          	addw	a3,a7,a3
ffffffffc02016ec:	ff0760e3          	bltu	a4,a6,ffffffffc02016cc <slub_alloc+0x1ac>
    __list_add(elm, listelm, listelm->next);  // 在指定节点后添加新节点
ffffffffc02016f0:	0189b783          	ld	a5,24(s3)
    prev->next = next->prev = elm;  // 在prev和next之间插入新节点elm
ffffffffc02016f4:	0067b023          	sd	t1,0(a5)
ffffffffc02016f8:	0069bc23          	sd	t1,24(s3)
    return list->next == list;  // 检查链表是否为空（指向自己）
ffffffffc02016fc:	020a3503          	ld	a0,32(s4)
    elm->next = next;               // 设置新节点的后继
ffffffffc0201700:	00fa3823          	sd	a5,16(s4)
    elm->prev = prev;               // 设置新节点的前驱
ffffffffc0201704:	009a3423          	sd	s1,8(s4)
    if (list_empty(&slab->free_list)) return NULL;
ffffffffc0201708:	f0b50ae3          	beq	a0,a1,ffffffffc020161c <slub_alloc+0xfc>
    __list_del(listelm->prev, listelm->next);  // 从链表中删除节点
ffffffffc020170c:	6114                	ld	a3,0(a0)
ffffffffc020170e:	6518                	ld	a4,8(a0)
    slab->inuse++;
ffffffffc0201710:	4785                	li	a5,1
    prev->next = next;  // 前驱节点指向后继节点
ffffffffc0201712:	e698                	sd	a4,8(a3)
    next->prev = prev;  // 后继节点指向前驱节点
ffffffffc0201714:	e314                	sd	a3,0(a4)
ffffffffc0201716:	02fa2423          	sw	a5,40(s4)
    if (slab->inuse == slab->capacity) {
ffffffffc020171a:	e6f81fe3          	bne	a6,a5,ffffffffc0201598 <slub_alloc+0x78>
    __list_del(listelm->prev, listelm->next);  // 从链表中删除节点
ffffffffc020171e:	008a3603          	ld	a2,8(s4)
ffffffffc0201722:	010a3683          	ld	a3,16(s4)
        list_add(&cache->slabs_full, &slab->link);
ffffffffc0201726:	02040413          	addi	s0,s0,32
ffffffffc020172a:	008907b3          	add	a5,s2,s0
    prev->next = next;  // 前驱节点指向后继节点
ffffffffc020172e:	e614                	sd	a3,8(a2)
    __list_add(elm, listelm, listelm->next);  // 在指定节点后添加新节点
ffffffffc0201730:	0289b703          	ld	a4,40(s3)
    next->prev = prev;  // 后继节点指向前驱节点
ffffffffc0201734:	e290                	sd	a2,0(a3)
    prev->next = next->prev = elm;  // 在prev和next之间插入新节点elm
ffffffffc0201736:	00673023          	sd	t1,0(a4)
ffffffffc020173a:	0269b423          	sd	t1,40(s3)
    elm->next = next;               // 设置新节点的后继
ffffffffc020173e:	00ea3823          	sd	a4,16(s4)
    elm->prev = prev;               // 设置新节点的前驱
ffffffffc0201742:	00fa3423          	sd	a5,8(s4)
}
ffffffffc0201746:	bd89                	j	ffffffffc0201598 <slub_alloc+0x78>

ffffffffc0201748 <slub_check>:
    list_entry_t *le = head;
    while ((le = list_next(le)) != head) cnt++;
    return cnt;
}

static void slub_check(void) {
ffffffffc0201748:	7131                	addi	sp,sp,-192
ffffffffc020174a:	f922                	sd	s0,176(sp)
ffffffffc020174c:	e952                	sd	s4,144(sp)
ffffffffc020174e:	0180                	addi	s0,sp,192
ffffffffc0201750:	fd06                	sd	ra,184(sp)
ffffffffc0201752:	f526                	sd	s1,168(sp)
ffffffffc0201754:	f14a                	sd	s2,160(sp)
ffffffffc0201756:	ed4e                	sd	s3,152(sp)
ffffffffc0201758:	e556                	sd	s5,136(sp)
ffffffffc020175a:	e15a                	sd	s6,128(sp)
ffffffffc020175c:	fcde                	sd	s7,120(sp)
ffffffffc020175e:	f8e2                	sd	s8,112(sp)
ffffffffc0201760:	f4e6                	sd	s9,104(sp)
ffffffffc0201762:	f0ea                	sd	s10,96(sp)
ffffffffc0201764:	ecee                	sd	s11,88(sp)
    assert((p0 = buddy_system_pmm_manager.alloc_pages(1)) != NULL);
ffffffffc0201766:	00001a17          	auipc	s4,0x1
ffffffffc020176a:	572a0a13          	addi	s4,s4,1394 # ffffffffc0202cd8 <buddy_system_pmm_manager>
ffffffffc020176e:	018a3783          	ld	a5,24(s4)
ffffffffc0201772:	4505                	li	a0,1
ffffffffc0201774:	f4f43023          	sd	a5,-192(s0)
ffffffffc0201778:	9782                	jalr	a5
ffffffffc020177a:	3a050363          	beqz	a0,ffffffffc0201b20 <slub_check+0x3d8>
    assert((p1 = buddy_system_pmm_manager.alloc_pages(1)) != NULL);
ffffffffc020177e:	f4043783          	ld	a5,-192(s0)
ffffffffc0201782:	89aa                	mv	s3,a0
ffffffffc0201784:	4505                	li	a0,1
ffffffffc0201786:	9782                	jalr	a5
ffffffffc0201788:	892a                	mv	s2,a0
ffffffffc020178a:	32050f63          	beqz	a0,ffffffffc0201ac8 <slub_check+0x380>
    assert((p2 = buddy_system_pmm_manager.alloc_pages(1)) != NULL);
ffffffffc020178e:	f4043783          	ld	a5,-192(s0)
ffffffffc0201792:	4505                	li	a0,1
ffffffffc0201794:	9782                	jalr	a5
ffffffffc0201796:	84aa                	mv	s1,a0
ffffffffc0201798:	3c050463          	beqz	a0,ffffffffc0201b60 <slub_check+0x418>
    buddy_system_pmm_manager.free_pages(p0, 1);
ffffffffc020179c:	020a3783          	ld	a5,32(s4)
ffffffffc02017a0:	854e                	mv	a0,s3
ffffffffc02017a2:	4585                	li	a1,1
ffffffffc02017a4:	f4f43423          	sd	a5,-184(s0)
ffffffffc02017a8:	89be                	mv	s3,a5
ffffffffc02017aa:	9782                	jalr	a5
    buddy_system_pmm_manager.free_pages(p1, 1);
ffffffffc02017ac:	4585                	li	a1,1
ffffffffc02017ae:	854a                	mv	a0,s2
ffffffffc02017b0:	9982                	jalr	s3
    buddy_system_pmm_manager.free_pages(p2, 1);
ffffffffc02017b2:	4585                	li	a1,1
ffffffffc02017b4:	8526                	mv	a0,s1
ffffffffc02017b6:	9982                	jalr	s3
    basic_check();

    // 对象分配测试：覆盖所有 size class，并验证 partial/full 列表移动与跨页扩容
    size_t sizes[] = {32,64,128,256,512,1024,2048,4096};
ffffffffc02017b8:	00002797          	auipc	a5,0x2
ffffffffc02017bc:	88878793          	addi	a5,a5,-1912 # ffffffffc0203040 <buddy_system_pmm_manager+0x368>
ffffffffc02017c0:	0007b883          	ld	a7,0(a5)
ffffffffc02017c4:	0087b803          	ld	a6,8(a5)
ffffffffc02017c8:	6b88                	ld	a0,16(a5)
ffffffffc02017ca:	6f8c                	ld	a1,24(a5)
ffffffffc02017cc:	7390                	ld	a2,32(a5)
ffffffffc02017ce:	7794                	ld	a3,40(a5)
ffffffffc02017d0:	7b98                	ld	a4,48(a5)
ffffffffc02017d2:	7f9c                	ld	a5,56(a5)
ffffffffc02017d4:	f5143823          	sd	a7,-176(s0)
ffffffffc02017d8:	f5043c23          	sd	a6,-168(s0)
ffffffffc02017dc:	f6a43023          	sd	a0,-160(s0)
ffffffffc02017e0:	f6b43423          	sd	a1,-152(s0)
ffffffffc02017e4:	f6c43823          	sd	a2,-144(s0)
ffffffffc02017e8:	f6d43c23          	sd	a3,-136(s0)
ffffffffc02017ec:	f8e43023          	sd	a4,-128(s0)
ffffffffc02017f0:	f8f43423          	sd	a5,-120(s0)
    for (int si = 0; si < (int)(sizeof(sizes)/sizeof(sizes[0])); si++) {
ffffffffc02017f4:	f5040b13          	addi	s6,s0,-176
    for (unsigned i = 0; i < SLUB_SIZE_CLASS_COUNT; i++) {
ffffffffc02017f8:	4aa1                	li	s5,8
        kmem_cache_t *cache = slub_select_cache(sizes[si]);
        assert(cache != NULL);

        // 4096B 特例：对象等于一页，走页级路径验证回退逻辑
        if (cache->objsize == PGSIZE) {
ffffffffc02017fa:	0000ab97          	auipc	s7,0xa
ffffffffc02017fe:	836b8b93          	addi	s7,s7,-1994 # ffffffffc020b030 <caches>
        assert(list_count(&cache->slabs_full) >= 1);

        // 继续分配一个对象，触发第二个 slab 的创建
        void *extra = slub_alloc(sizes[si]);
        if (extra != NULL) {
            uintptr_t pa_first = ROUNDDOWN((uintptr_t)first - va_pa_offset, PGSIZE);
ffffffffc0201802:	0000ac97          	auipc	s9,0xa
ffffffffc0201806:	a2ec8c93          	addi	s9,s9,-1490 # ffffffffc020b230 <va_pa_offset>
        kmem_cache_t *cache = slub_select_cache(sizes[si]);
ffffffffc020180a:	000b3d03          	ld	s10,0(s6)
    for (unsigned i = 0; i < SLUB_SIZE_CLASS_COUNT; i++) {
ffffffffc020180e:	00002717          	auipc	a4,0x2
ffffffffc0201812:	8aa70713          	addi	a4,a4,-1878 # ffffffffc02030b8 <slub_sizes>
        kmem_cache_t *cache = slub_select_cache(sizes[si]);
ffffffffc0201816:	02000793          	li	a5,32
    for (unsigned i = 0; i < SLUB_SIZE_CLASS_COUNT; i++) {
ffffffffc020181a:	4481                	li	s1,0
ffffffffc020181c:	a011                	j	ffffffffc0201820 <slub_check+0xd8>
        if (size <= slub_sizes[i]) return &caches[i];
ffffffffc020181e:	431c                	lw	a5,0(a4)
ffffffffc0201820:	1782                	slli	a5,a5,0x20
ffffffffc0201822:	9381                	srli	a5,a5,0x20
ffffffffc0201824:	03a7f663          	bgeu	a5,s10,ffffffffc0201850 <slub_check+0x108>
    for (unsigned i = 0; i < SLUB_SIZE_CLASS_COUNT; i++) {
ffffffffc0201828:	2485                	addiw	s1,s1,1
ffffffffc020182a:	0711                	addi	a4,a4,4
ffffffffc020182c:	ff5499e3          	bne	s1,s5,ffffffffc020181e <slub_check+0xd6>
        assert(cache != NULL);
ffffffffc0201830:	00001697          	auipc	a3,0x1
ffffffffc0201834:	7e868693          	addi	a3,a3,2024 # ffffffffc0203018 <buddy_system_pmm_manager+0x340>
ffffffffc0201838:	00001617          	auipc	a2,0x1
ffffffffc020183c:	a6860613          	addi	a2,a2,-1432 # ffffffffc02022a0 <etext+0x26c>
ffffffffc0201840:	0f500593          	li	a1,245
ffffffffc0201844:	00001517          	auipc	a0,0x1
ffffffffc0201848:	65450513          	addi	a0,a0,1620 # ffffffffc0202e98 <buddy_system_pmm_manager+0x1c0>
ffffffffc020184c:	977fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        if (cache->objsize == PGSIZE) {
ffffffffc0201850:	1482                	slli	s1,s1,0x20
ffffffffc0201852:	9081                	srli	s1,s1,0x20
ffffffffc0201854:	00349a13          	slli	s4,s1,0x3
ffffffffc0201858:	409a0a33          	sub	s4,s4,s1
ffffffffc020185c:	0a0e                	slli	s4,s4,0x3
ffffffffc020185e:	014b8933          	add	s2,s7,s4
ffffffffc0201862:	00892703          	lw	a4,8(s2)
ffffffffc0201866:	6785                	lui	a5,0x1
ffffffffc0201868:	0ef71063          	bne	a4,a5,ffffffffc0201948 <slub_check+0x200>
            void *ptr = slub_alloc(sizes[si]);
ffffffffc020186c:	856a                	mv	a0,s10
ffffffffc020186e:	cb3ff0ef          	jal	ra,ffffffffc0201520 <slub_alloc>
            assert(ptr != NULL);
ffffffffc0201872:	28050763          	beqz	a0,ffffffffc0201b00 <slub_check+0x3b8>
            uintptr_t page_pa = ROUNDDOWN((uintptr_t)ptr - va_pa_offset, PGSIZE);
ffffffffc0201876:	000cb783          	ld	a5,0(s9)
    if (PPN(pa) >= npage) {
ffffffffc020187a:	0000a717          	auipc	a4,0xa
ffffffffc020187e:	98e70713          	addi	a4,a4,-1650 # ffffffffc020b208 <npage>
ffffffffc0201882:	6318                	ld	a4,0(a4)
ffffffffc0201884:	40f507b3          	sub	a5,a0,a5
ffffffffc0201888:	83b1                	srli	a5,a5,0xc
ffffffffc020188a:	24e7ff63          	bgeu	a5,a4,ffffffffc0201ae8 <slub_check+0x3a0>
    return &pages[PPN(pa) - nbase];
ffffffffc020188e:	00002717          	auipc	a4,0x2
ffffffffc0201892:	a9a70713          	addi	a4,a4,-1382 # ffffffffc0203328 <nbase>
ffffffffc0201896:	6318                	ld	a4,0(a4)
ffffffffc0201898:	0000a697          	auipc	a3,0xa
ffffffffc020189c:	97868693          	addi	a3,a3,-1672 # ffffffffc020b210 <pages>
ffffffffc02018a0:	6288                	ld	a0,0(a3)
ffffffffc02018a2:	8f99                	sub	a5,a5,a4
ffffffffc02018a4:	00279713          	slli	a4,a5,0x2
ffffffffc02018a8:	97ba                	add	a5,a5,a4
ffffffffc02018aa:	078e                	slli	a5,a5,0x3
            buddy_system_pmm_manager.free_pages(pg, 1);
ffffffffc02018ac:	953e                	add	a0,a0,a5
ffffffffc02018ae:	f4843783          	ld	a5,-184(s0)
ffffffffc02018b2:	4585                	li	a1,1
ffffffffc02018b4:	9782                	jalr	a5
    for (int si = 0; si < (int)(sizeof(sizes)/sizeof(sizes[0])); si++) {
ffffffffc02018b6:	0b21                	addi	s6,s6,8
ffffffffc02018b8:	f9040793          	addi	a5,s0,-112
ffffffffc02018bc:	f4fb17e3          	bne	s6,a5,ffffffffc020180a <slub_check+0xc2>
        assert(list_count(&cache->slabs_partial) >= 1);
    }

    // 大量 64B 对象分配与释放，验证复用
    const int N = 1024;
    void *arr[N];
ffffffffc02018c0:	77f9                	lui	a5,0xffffe
ffffffffc02018c2:	913e                	add	sp,sp,a5
ffffffffc02018c4:	848a                	mv	s1,sp
    for (int i = 0; i < N; i++) {
ffffffffc02018c6:	6989                	lui	s3,0x2
ffffffffc02018c8:	99a6                	add	s3,s3,s1
    void *arr[N];
ffffffffc02018ca:	8926                	mv	s2,s1
        arr[i] = slub_alloc(64);
ffffffffc02018cc:	04000513          	li	a0,64
ffffffffc02018d0:	c51ff0ef          	jal	ra,ffffffffc0201520 <slub_alloc>
ffffffffc02018d4:	00a93023          	sd	a0,0(s2)
        assert(arr[i] != NULL);
ffffffffc02018d8:	18050863          	beqz	a0,ffffffffc0201a68 <slub_check+0x320>
    for (int i = 0; i < N; i++) {
ffffffffc02018dc:	0921                	addi	s2,s2,8
ffffffffc02018de:	ff2997e3          	bne	s3,s2,ffffffffc02018cc <slub_check+0x184>
    }
    for (int i = 0; i < N; i += 2) {
        slub_free(arr[i], 64);
ffffffffc02018e2:	6088                	ld	a0,0(s1)
ffffffffc02018e4:	04000593          	li	a1,64
    for (int i = 0; i < N; i += 2) {
ffffffffc02018e8:	04c1                	addi	s1,s1,16
        slub_free(arr[i], 64);
ffffffffc02018ea:	b89ff0ef          	jal	ra,ffffffffc0201472 <slub_free>
    for (int i = 0; i < N; i += 2) {
ffffffffc02018ee:	fe999ae3          	bne	s3,s1,ffffffffc02018e2 <slub_check+0x19a>
ffffffffc02018f2:	20000493          	li	s1,512
    }
    for (int i = 0; i < N/2; i++) {
        void *o = slub_alloc(64);
ffffffffc02018f6:	04000513          	li	a0,64
ffffffffc02018fa:	c27ff0ef          	jal	ra,ffffffffc0201520 <slub_alloc>
        assert(o != NULL);
ffffffffc02018fe:	14050563          	beqz	a0,ffffffffc0201a48 <slub_check+0x300>
    for (int i = 0; i < N/2; i++) {
ffffffffc0201902:	34fd                	addiw	s1,s1,-1
ffffffffc0201904:	f8ed                	bnez	s1,ffffffffc02018f6 <slub_check+0x1ae>
    return buddy_system_pmm_manager.alloc_pages(n);
ffffffffc0201906:	f4043783          	ld	a5,-192(s0)
ffffffffc020190a:	4509                	li	a0,2
ffffffffc020190c:	9782                	jalr	a5
    }

    // 大对象回退测试：>4096 的请求退回页级
    struct Page *big = slub_alloc_pages(2); // 2 页作为大对象块
    assert(big != NULL);
ffffffffc020190e:	18050d63          	beqz	a0,ffffffffc0201aa8 <slub_check+0x360>
    buddy_system_pmm_manager.free_pages(base, n);
ffffffffc0201912:	f4843783          	ld	a5,-184(s0)
ffffffffc0201916:	4589                	li	a1,2
ffffffffc0201918:	9782                	jalr	a5
    slub_free_pages(big, 2);

    cprintf("slub_check() completed.\n");
ffffffffc020191a:	00001517          	auipc	a0,0x1
ffffffffc020191e:	6de50513          	addi	a0,a0,1758 # ffffffffc0202ff8 <buddy_system_pmm_manager+0x320>
ffffffffc0201922:	82bfe0ef          	jal	ra,ffffffffc020014c <cprintf>
}
ffffffffc0201926:	f4040113          	addi	sp,s0,-192
ffffffffc020192a:	70ea                	ld	ra,184(sp)
ffffffffc020192c:	744a                	ld	s0,176(sp)
ffffffffc020192e:	74aa                	ld	s1,168(sp)
ffffffffc0201930:	790a                	ld	s2,160(sp)
ffffffffc0201932:	69ea                	ld	s3,152(sp)
ffffffffc0201934:	6a4a                	ld	s4,144(sp)
ffffffffc0201936:	6aaa                	ld	s5,136(sp)
ffffffffc0201938:	6b0a                	ld	s6,128(sp)
ffffffffc020193a:	7be6                	ld	s7,120(sp)
ffffffffc020193c:	7c46                	ld	s8,112(sp)
ffffffffc020193e:	7ca6                	ld	s9,104(sp)
ffffffffc0201940:	7d06                	ld	s10,96(sp)
ffffffffc0201942:	6de6                	ld	s11,88(sp)
ffffffffc0201944:	6129                	addi	sp,sp,192
ffffffffc0201946:	8082                	ret
        void *first = slub_alloc(sizes[si]);
ffffffffc0201948:	856a                	mv	a0,s10
ffffffffc020194a:	bd7ff0ef          	jal	ra,ffffffffc0201520 <slub_alloc>
ffffffffc020194e:	8c2a                	mv	s8,a0
        assert(first != NULL);
ffffffffc0201950:	22050863          	beqz	a0,ffffffffc0201b80 <slub_check+0x438>
    return listelm->next;  // 获取下一个节点
ffffffffc0201954:	01893983          	ld	s3,24(s2)
        assert(list_count(&cache->slabs_partial) >= 1);
ffffffffc0201958:	010a0793          	addi	a5,s4,16
ffffffffc020195c:	97de                	add	a5,a5,s7
    while ((le = list_next(le)) != head) cnt++;
ffffffffc020195e:	0d378563          	beq	a5,s3,ffffffffc0201a28 <slub_check+0x2e0>
ffffffffc0201962:	0089b983          	ld	s3,8(s3) # 2008 <kern_entry-0xffffffffc01fdff8>
ffffffffc0201966:	ff379ee3          	bne	a5,s3,ffffffffc0201962 <slub_check+0x21a>
        unsigned cap = ((PGSIZE * cache->slab_pages) - sizeof(slub_slab_t)) / cache->objsize;
ffffffffc020196a:	00349793          	slli	a5,s1,0x3
ffffffffc020196e:	8f85                	sub	a5,a5,s1
ffffffffc0201970:	078e                	slli	a5,a5,0x3
ffffffffc0201972:	97de                	add	a5,a5,s7
ffffffffc0201974:	0307a903          	lw	s2,48(a5) # ffffffffffffe030 <end+0x3fdf2df8>
ffffffffc0201978:	0087e703          	lwu	a4,8(a5)
        for (unsigned i = 1; i < cap; i++) {
ffffffffc020197c:	4d85                	li	s11,1
        unsigned cap = ((PGSIZE * cache->slab_pages) - sizeof(slub_slab_t)) / cache->objsize;
ffffffffc020197e:	00c9191b          	slliw	s2,s2,0xc
ffffffffc0201982:	1902                	slli	s2,s2,0x20
ffffffffc0201984:	02095913          	srli	s2,s2,0x20
ffffffffc0201988:	fc890913          	addi	s2,s2,-56
ffffffffc020198c:	02e95933          	divu	s2,s2,a4
ffffffffc0201990:	2901                	sext.w	s2,s2
        for (unsigned i = 1; i < cap; i++) {
ffffffffc0201992:	012dfa63          	bgeu	s11,s2,ffffffffc02019a6 <slub_check+0x25e>
            assert(slub_alloc(sizes[si]) != NULL);
ffffffffc0201996:	856a                	mv	a0,s10
ffffffffc0201998:	b89ff0ef          	jal	ra,ffffffffc0201520 <slub_alloc>
ffffffffc020199c:	0e050663          	beqz	a0,ffffffffc0201a88 <slub_check+0x340>
        for (unsigned i = 1; i < cap; i++) {
ffffffffc02019a0:	2d85                	addiw	s11,s11,1
ffffffffc02019a2:	ffb91ae3          	bne	s2,s11,ffffffffc0201996 <slub_check+0x24e>
ffffffffc02019a6:	00349793          	slli	a5,s1,0x3
ffffffffc02019aa:	8f85                	sub	a5,a5,s1
ffffffffc02019ac:	078e                	slli	a5,a5,0x3
ffffffffc02019ae:	97de                	add	a5,a5,s7
    while ((le = list_next(le)) != head) cnt++;
ffffffffc02019b0:	779c                	ld	a5,40(a5)
        assert(list_count(&cache->slabs_full) >= 1);
ffffffffc02019b2:	020a0a13          	addi	s4,s4,32
ffffffffc02019b6:	9a5e                	add	s4,s4,s7
    while ((le = list_next(le)) != head) cnt++;
ffffffffc02019b8:	05478863          	beq	a5,s4,ffffffffc0201a08 <slub_check+0x2c0>
        void *extra = slub_alloc(sizes[si]);
ffffffffc02019bc:	856a                	mv	a0,s10
ffffffffc02019be:	b63ff0ef          	jal	ra,ffffffffc0201520 <slub_alloc>
        if (extra != NULL) {
ffffffffc02019c2:	c919                	beqz	a0,ffffffffc02019d8 <slub_check+0x290>
            uintptr_t pa_first = ROUNDDOWN((uintptr_t)first - va_pa_offset, PGSIZE);
ffffffffc02019c4:	000cb683          	ld	a3,0(s9)
ffffffffc02019c8:	777d                	lui	a4,0xfffff
ffffffffc02019ca:	40dc07b3          	sub	a5,s8,a3
            uintptr_t pa_extra = ROUNDDOWN((uintptr_t)extra - va_pa_offset, PGSIZE);
ffffffffc02019ce:	8d15                	sub	a0,a0,a3
            uintptr_t pa_first = ROUNDDOWN((uintptr_t)first - va_pa_offset, PGSIZE);
ffffffffc02019d0:	8ff9                	and	a5,a5,a4
            uintptr_t pa_extra = ROUNDDOWN((uintptr_t)extra - va_pa_offset, PGSIZE);
ffffffffc02019d2:	8d79                	and	a0,a0,a4
            assert(pa_first != pa_extra);
ffffffffc02019d4:	16a78663          	beq	a5,a0,ffffffffc0201b40 <slub_check+0x3f8>
        slub_free(first, sizes[si]);
ffffffffc02019d8:	85ea                	mv	a1,s10
ffffffffc02019da:	8562                	mv	a0,s8
ffffffffc02019dc:	a97ff0ef          	jal	ra,ffffffffc0201472 <slub_free>
    while ((le = list_next(le)) != head) cnt++;
ffffffffc02019e0:	0089b783          	ld	a5,8(s3)
ffffffffc02019e4:	ed3799e3          	bne	a5,s3,ffffffffc02018b6 <slub_check+0x16e>
        assert(list_count(&cache->slabs_partial) >= 1);
ffffffffc02019e8:	00001697          	auipc	a3,0x1
ffffffffc02019ec:	55868693          	addi	a3,a3,1368 # ffffffffc0202f40 <buddy_system_pmm_manager+0x268>
ffffffffc02019f0:	00001617          	auipc	a2,0x1
ffffffffc02019f4:	8b060613          	addi	a2,a2,-1872 # ffffffffc02022a0 <etext+0x26c>
ffffffffc02019f8:	11b00593          	li	a1,283
ffffffffc02019fc:	00001517          	auipc	a0,0x1
ffffffffc0201a00:	49c50513          	addi	a0,a0,1180 # ffffffffc0202e98 <buddy_system_pmm_manager+0x1c0>
ffffffffc0201a04:	fbefe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(list_count(&cache->slabs_full) >= 1);
ffffffffc0201a08:	00001697          	auipc	a3,0x1
ffffffffc0201a0c:	58068693          	addi	a3,a3,1408 # ffffffffc0202f88 <buddy_system_pmm_manager+0x2b0>
ffffffffc0201a10:	00001617          	auipc	a2,0x1
ffffffffc0201a14:	89060613          	addi	a2,a2,-1904 # ffffffffc02022a0 <etext+0x26c>
ffffffffc0201a18:	10e00593          	li	a1,270
ffffffffc0201a1c:	00001517          	auipc	a0,0x1
ffffffffc0201a20:	47c50513          	addi	a0,a0,1148 # ffffffffc0202e98 <buddy_system_pmm_manager+0x1c0>
ffffffffc0201a24:	f9efe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(list_count(&cache->slabs_partial) >= 1);
ffffffffc0201a28:	00001697          	auipc	a3,0x1
ffffffffc0201a2c:	51868693          	addi	a3,a3,1304 # ffffffffc0202f40 <buddy_system_pmm_manager+0x268>
ffffffffc0201a30:	00001617          	auipc	a2,0x1
ffffffffc0201a34:	87060613          	addi	a2,a2,-1936 # ffffffffc02022a0 <etext+0x26c>
ffffffffc0201a38:	10400593          	li	a1,260
ffffffffc0201a3c:	00001517          	auipc	a0,0x1
ffffffffc0201a40:	45c50513          	addi	a0,a0,1116 # ffffffffc0202e98 <buddy_system_pmm_manager+0x1c0>
ffffffffc0201a44:	f7efe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(o != NULL);
ffffffffc0201a48:	00001697          	auipc	a3,0x1
ffffffffc0201a4c:	59068693          	addi	a3,a3,1424 # ffffffffc0202fd8 <buddy_system_pmm_manager+0x300>
ffffffffc0201a50:	00001617          	auipc	a2,0x1
ffffffffc0201a54:	85060613          	addi	a2,a2,-1968 # ffffffffc02022a0 <etext+0x26c>
ffffffffc0201a58:	12a00593          	li	a1,298
ffffffffc0201a5c:	00001517          	auipc	a0,0x1
ffffffffc0201a60:	43c50513          	addi	a0,a0,1084 # ffffffffc0202e98 <buddy_system_pmm_manager+0x1c0>
ffffffffc0201a64:	f5efe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(arr[i] != NULL);
ffffffffc0201a68:	00001697          	auipc	a3,0x1
ffffffffc0201a6c:	56068693          	addi	a3,a3,1376 # ffffffffc0202fc8 <buddy_system_pmm_manager+0x2f0>
ffffffffc0201a70:	00001617          	auipc	a2,0x1
ffffffffc0201a74:	83060613          	addi	a2,a2,-2000 # ffffffffc02022a0 <etext+0x26c>
ffffffffc0201a78:	12300593          	li	a1,291
ffffffffc0201a7c:	00001517          	auipc	a0,0x1
ffffffffc0201a80:	41c50513          	addi	a0,a0,1052 # ffffffffc0202e98 <buddy_system_pmm_manager+0x1c0>
ffffffffc0201a84:	f3efe0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(slub_alloc(sizes[si]) != NULL);
ffffffffc0201a88:	00001697          	auipc	a3,0x1
ffffffffc0201a8c:	4e068693          	addi	a3,a3,1248 # ffffffffc0202f68 <buddy_system_pmm_manager+0x290>
ffffffffc0201a90:	00001617          	auipc	a2,0x1
ffffffffc0201a94:	81060613          	addi	a2,a2,-2032 # ffffffffc02022a0 <etext+0x26c>
ffffffffc0201a98:	10b00593          	li	a1,267
ffffffffc0201a9c:	00001517          	auipc	a0,0x1
ffffffffc0201aa0:	3fc50513          	addi	a0,a0,1020 # ffffffffc0202e98 <buddy_system_pmm_manager+0x1c0>
ffffffffc0201aa4:	f1efe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(big != NULL);
ffffffffc0201aa8:	00001697          	auipc	a3,0x1
ffffffffc0201aac:	54068693          	addi	a3,a3,1344 # ffffffffc0202fe8 <buddy_system_pmm_manager+0x310>
ffffffffc0201ab0:	00000617          	auipc	a2,0x0
ffffffffc0201ab4:	7f060613          	addi	a2,a2,2032 # ffffffffc02022a0 <etext+0x26c>
ffffffffc0201ab8:	12f00593          	li	a1,303
ffffffffc0201abc:	00001517          	auipc	a0,0x1
ffffffffc0201ac0:	3dc50513          	addi	a0,a0,988 # ffffffffc0202e98 <buddy_system_pmm_manager+0x1c0>
ffffffffc0201ac4:	efefe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p1 = buddy_system_pmm_manager.alloc_pages(1)) != NULL);
ffffffffc0201ac8:	00001697          	auipc	a3,0x1
ffffffffc0201acc:	3e868693          	addi	a3,a3,1000 # ffffffffc0202eb0 <buddy_system_pmm_manager+0x1d8>
ffffffffc0201ad0:	00000617          	auipc	a2,0x0
ffffffffc0201ad4:	7d060613          	addi	a2,a2,2000 # ffffffffc02022a0 <etext+0x26c>
ffffffffc0201ad8:	0e000593          	li	a1,224
ffffffffc0201adc:	00001517          	auipc	a0,0x1
ffffffffc0201ae0:	3bc50513          	addi	a0,a0,956 # ffffffffc0202e98 <buddy_system_pmm_manager+0x1c0>
ffffffffc0201ae4:	edefe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0201ae8:	00001617          	auipc	a2,0x1
ffffffffc0201aec:	2e060613          	addi	a2,a2,736 # ffffffffc0202dc8 <buddy_system_pmm_manager+0xf0>
ffffffffc0201af0:	07100593          	li	a1,113
ffffffffc0201af4:	00001517          	auipc	a0,0x1
ffffffffc0201af8:	2f450513          	addi	a0,a0,756 # ffffffffc0202de8 <buddy_system_pmm_manager+0x110>
ffffffffc0201afc:	ec6fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(ptr != NULL);
ffffffffc0201b00:	00001697          	auipc	a3,0x1
ffffffffc0201b04:	42068693          	addi	a3,a3,1056 # ffffffffc0202f20 <buddy_system_pmm_manager+0x248>
ffffffffc0201b08:	00000617          	auipc	a2,0x0
ffffffffc0201b0c:	79860613          	addi	a2,a2,1944 # ffffffffc02022a0 <etext+0x26c>
ffffffffc0201b10:	0fa00593          	li	a1,250
ffffffffc0201b14:	00001517          	auipc	a0,0x1
ffffffffc0201b18:	38450513          	addi	a0,a0,900 # ffffffffc0202e98 <buddy_system_pmm_manager+0x1c0>
ffffffffc0201b1c:	ea6fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p0 = buddy_system_pmm_manager.alloc_pages(1)) != NULL);
ffffffffc0201b20:	00001697          	auipc	a3,0x1
ffffffffc0201b24:	34068693          	addi	a3,a3,832 # ffffffffc0202e60 <buddy_system_pmm_manager+0x188>
ffffffffc0201b28:	00000617          	auipc	a2,0x0
ffffffffc0201b2c:	77860613          	addi	a2,a2,1912 # ffffffffc02022a0 <etext+0x26c>
ffffffffc0201b30:	0df00593          	li	a1,223
ffffffffc0201b34:	00001517          	auipc	a0,0x1
ffffffffc0201b38:	36450513          	addi	a0,a0,868 # ffffffffc0202e98 <buddy_system_pmm_manager+0x1c0>
ffffffffc0201b3c:	e86fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(pa_first != pa_extra);
ffffffffc0201b40:	00001697          	auipc	a3,0x1
ffffffffc0201b44:	47068693          	addi	a3,a3,1136 # ffffffffc0202fb0 <buddy_system_pmm_manager+0x2d8>
ffffffffc0201b48:	00000617          	auipc	a2,0x0
ffffffffc0201b4c:	75860613          	addi	a2,a2,1880 # ffffffffc02022a0 <etext+0x26c>
ffffffffc0201b50:	11600593          	li	a1,278
ffffffffc0201b54:	00001517          	auipc	a0,0x1
ffffffffc0201b58:	34450513          	addi	a0,a0,836 # ffffffffc0202e98 <buddy_system_pmm_manager+0x1c0>
ffffffffc0201b5c:	e66fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p2 = buddy_system_pmm_manager.alloc_pages(1)) != NULL);
ffffffffc0201b60:	00001697          	auipc	a3,0x1
ffffffffc0201b64:	38868693          	addi	a3,a3,904 # ffffffffc0202ee8 <buddy_system_pmm_manager+0x210>
ffffffffc0201b68:	00000617          	auipc	a2,0x0
ffffffffc0201b6c:	73860613          	addi	a2,a2,1848 # ffffffffc02022a0 <etext+0x26c>
ffffffffc0201b70:	0e100593          	li	a1,225
ffffffffc0201b74:	00001517          	auipc	a0,0x1
ffffffffc0201b78:	32450513          	addi	a0,a0,804 # ffffffffc0202e98 <buddy_system_pmm_manager+0x1c0>
ffffffffc0201b7c:	e46fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(first != NULL);
ffffffffc0201b80:	00001697          	auipc	a3,0x1
ffffffffc0201b84:	3b068693          	addi	a3,a3,944 # ffffffffc0202f30 <buddy_system_pmm_manager+0x258>
ffffffffc0201b88:	00000617          	auipc	a2,0x0
ffffffffc0201b8c:	71860613          	addi	a2,a2,1816 # ffffffffc02022a0 <etext+0x26c>
ffffffffc0201b90:	10300593          	li	a1,259
ffffffffc0201b94:	00001517          	auipc	a0,0x1
ffffffffc0201b98:	30450513          	addi	a0,a0,772 # ffffffffc0202e98 <buddy_system_pmm_manager+0x1c0>
ffffffffc0201b9c:	e26fe0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0201ba0 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0201ba0:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201ba4:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0201ba6:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201baa:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0201bac:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201bb0:	f022                	sd	s0,32(sp)
ffffffffc0201bb2:	ec26                	sd	s1,24(sp)
ffffffffc0201bb4:	e84a                	sd	s2,16(sp)
ffffffffc0201bb6:	f406                	sd	ra,40(sp)
ffffffffc0201bb8:	e44e                	sd	s3,8(sp)
ffffffffc0201bba:	84aa                	mv	s1,a0
ffffffffc0201bbc:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0201bbe:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0201bc2:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0201bc4:	03067e63          	bgeu	a2,a6,ffffffffc0201c00 <printnum+0x60>
ffffffffc0201bc8:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0201bca:	00805763          	blez	s0,ffffffffc0201bd8 <printnum+0x38>
ffffffffc0201bce:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0201bd0:	85ca                	mv	a1,s2
ffffffffc0201bd2:	854e                	mv	a0,s3
ffffffffc0201bd4:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0201bd6:	fc65                	bnez	s0,ffffffffc0201bce <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201bd8:	1a02                	slli	s4,s4,0x20
ffffffffc0201bda:	00001797          	auipc	a5,0x1
ffffffffc0201bde:	4fe78793          	addi	a5,a5,1278 # ffffffffc02030d8 <slub_sizes+0x20>
ffffffffc0201be2:	020a5a13          	srli	s4,s4,0x20
ffffffffc0201be6:	9a3e                	add	s4,s4,a5
}
ffffffffc0201be8:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201bea:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0201bee:	70a2                	ld	ra,40(sp)
ffffffffc0201bf0:	69a2                	ld	s3,8(sp)
ffffffffc0201bf2:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201bf4:	85ca                	mv	a1,s2
ffffffffc0201bf6:	87a6                	mv	a5,s1
}
ffffffffc0201bf8:	6942                	ld	s2,16(sp)
ffffffffc0201bfa:	64e2                	ld	s1,24(sp)
ffffffffc0201bfc:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201bfe:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0201c00:	03065633          	divu	a2,a2,a6
ffffffffc0201c04:	8722                	mv	a4,s0
ffffffffc0201c06:	f9bff0ef          	jal	ra,ffffffffc0201ba0 <printnum>
ffffffffc0201c0a:	b7f9                	j	ffffffffc0201bd8 <printnum+0x38>

ffffffffc0201c0c <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0201c0c:	7119                	addi	sp,sp,-128
ffffffffc0201c0e:	f4a6                	sd	s1,104(sp)
ffffffffc0201c10:	f0ca                	sd	s2,96(sp)
ffffffffc0201c12:	ecce                	sd	s3,88(sp)
ffffffffc0201c14:	e8d2                	sd	s4,80(sp)
ffffffffc0201c16:	e4d6                	sd	s5,72(sp)
ffffffffc0201c18:	e0da                	sd	s6,64(sp)
ffffffffc0201c1a:	fc5e                	sd	s7,56(sp)
ffffffffc0201c1c:	f06a                	sd	s10,32(sp)
ffffffffc0201c1e:	fc86                	sd	ra,120(sp)
ffffffffc0201c20:	f8a2                	sd	s0,112(sp)
ffffffffc0201c22:	f862                	sd	s8,48(sp)
ffffffffc0201c24:	f466                	sd	s9,40(sp)
ffffffffc0201c26:	ec6e                	sd	s11,24(sp)
ffffffffc0201c28:	892a                	mv	s2,a0
ffffffffc0201c2a:	84ae                	mv	s1,a1
ffffffffc0201c2c:	8d32                	mv	s10,a2
ffffffffc0201c2e:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201c30:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0201c34:	5b7d                	li	s6,-1
ffffffffc0201c36:	00001a97          	auipc	s5,0x1
ffffffffc0201c3a:	4d6a8a93          	addi	s5,s5,1238 # ffffffffc020310c <slub_sizes+0x54>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201c3e:	00001b97          	auipc	s7,0x1
ffffffffc0201c42:	6aab8b93          	addi	s7,s7,1706 # ffffffffc02032e8 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201c46:	000d4503          	lbu	a0,0(s10)
ffffffffc0201c4a:	001d0413          	addi	s0,s10,1
ffffffffc0201c4e:	01350a63          	beq	a0,s3,ffffffffc0201c62 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0201c52:	c121                	beqz	a0,ffffffffc0201c92 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0201c54:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201c56:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0201c58:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201c5a:	fff44503          	lbu	a0,-1(s0)
ffffffffc0201c5e:	ff351ae3          	bne	a0,s3,ffffffffc0201c52 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201c62:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0201c66:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0201c6a:	4c81                	li	s9,0
ffffffffc0201c6c:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0201c6e:	5c7d                	li	s8,-1
ffffffffc0201c70:	5dfd                	li	s11,-1
ffffffffc0201c72:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0201c76:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201c78:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201c7c:	0ff5f593          	zext.b	a1,a1
ffffffffc0201c80:	00140d13          	addi	s10,s0,1
ffffffffc0201c84:	04b56263          	bltu	a0,a1,ffffffffc0201cc8 <vprintfmt+0xbc>
ffffffffc0201c88:	058a                	slli	a1,a1,0x2
ffffffffc0201c8a:	95d6                	add	a1,a1,s5
ffffffffc0201c8c:	4194                	lw	a3,0(a1)
ffffffffc0201c8e:	96d6                	add	a3,a3,s5
ffffffffc0201c90:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0201c92:	70e6                	ld	ra,120(sp)
ffffffffc0201c94:	7446                	ld	s0,112(sp)
ffffffffc0201c96:	74a6                	ld	s1,104(sp)
ffffffffc0201c98:	7906                	ld	s2,96(sp)
ffffffffc0201c9a:	69e6                	ld	s3,88(sp)
ffffffffc0201c9c:	6a46                	ld	s4,80(sp)
ffffffffc0201c9e:	6aa6                	ld	s5,72(sp)
ffffffffc0201ca0:	6b06                	ld	s6,64(sp)
ffffffffc0201ca2:	7be2                	ld	s7,56(sp)
ffffffffc0201ca4:	7c42                	ld	s8,48(sp)
ffffffffc0201ca6:	7ca2                	ld	s9,40(sp)
ffffffffc0201ca8:	7d02                	ld	s10,32(sp)
ffffffffc0201caa:	6de2                	ld	s11,24(sp)
ffffffffc0201cac:	6109                	addi	sp,sp,128
ffffffffc0201cae:	8082                	ret
            padc = '0';
ffffffffc0201cb0:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0201cb2:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201cb6:	846a                	mv	s0,s10
ffffffffc0201cb8:	00140d13          	addi	s10,s0,1
ffffffffc0201cbc:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201cc0:	0ff5f593          	zext.b	a1,a1
ffffffffc0201cc4:	fcb572e3          	bgeu	a0,a1,ffffffffc0201c88 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0201cc8:	85a6                	mv	a1,s1
ffffffffc0201cca:	02500513          	li	a0,37
ffffffffc0201cce:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201cd0:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201cd4:	8d22                	mv	s10,s0
ffffffffc0201cd6:	f73788e3          	beq	a5,s3,ffffffffc0201c46 <vprintfmt+0x3a>
ffffffffc0201cda:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0201cde:	1d7d                	addi	s10,s10,-1
ffffffffc0201ce0:	ff379de3          	bne	a5,s3,ffffffffc0201cda <vprintfmt+0xce>
ffffffffc0201ce4:	b78d                	j	ffffffffc0201c46 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0201ce6:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0201cea:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201cee:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0201cf0:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0201cf4:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201cf8:	02d86463          	bltu	a6,a3,ffffffffc0201d20 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0201cfc:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0201d00:	002c169b          	slliw	a3,s8,0x2
ffffffffc0201d04:	0186873b          	addw	a4,a3,s8
ffffffffc0201d08:	0017171b          	slliw	a4,a4,0x1
ffffffffc0201d0c:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0201d0e:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0201d12:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0201d14:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0201d18:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201d1c:	fed870e3          	bgeu	a6,a3,ffffffffc0201cfc <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0201d20:	f40ddce3          	bgez	s11,ffffffffc0201c78 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0201d24:	8de2                	mv	s11,s8
ffffffffc0201d26:	5c7d                	li	s8,-1
ffffffffc0201d28:	bf81                	j	ffffffffc0201c78 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0201d2a:	fffdc693          	not	a3,s11
ffffffffc0201d2e:	96fd                	srai	a3,a3,0x3f
ffffffffc0201d30:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201d34:	00144603          	lbu	a2,1(s0)
ffffffffc0201d38:	2d81                	sext.w	s11,s11
ffffffffc0201d3a:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201d3c:	bf35                	j	ffffffffc0201c78 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0201d3e:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201d42:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0201d46:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201d48:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0201d4a:	bfd9                	j	ffffffffc0201d20 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0201d4c:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201d4e:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201d52:	01174463          	blt	a4,a7,ffffffffc0201d5a <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0201d56:	1a088e63          	beqz	a7,ffffffffc0201f12 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0201d5a:	000a3603          	ld	a2,0(s4)
ffffffffc0201d5e:	46c1                	li	a3,16
ffffffffc0201d60:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201d62:	2781                	sext.w	a5,a5
ffffffffc0201d64:	876e                	mv	a4,s11
ffffffffc0201d66:	85a6                	mv	a1,s1
ffffffffc0201d68:	854a                	mv	a0,s2
ffffffffc0201d6a:	e37ff0ef          	jal	ra,ffffffffc0201ba0 <printnum>
            break;
ffffffffc0201d6e:	bde1                	j	ffffffffc0201c46 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0201d70:	000a2503          	lw	a0,0(s4)
ffffffffc0201d74:	85a6                	mv	a1,s1
ffffffffc0201d76:	0a21                	addi	s4,s4,8
ffffffffc0201d78:	9902                	jalr	s2
            break;
ffffffffc0201d7a:	b5f1                	j	ffffffffc0201c46 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201d7c:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201d7e:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201d82:	01174463          	blt	a4,a7,ffffffffc0201d8a <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0201d86:	18088163          	beqz	a7,ffffffffc0201f08 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0201d8a:	000a3603          	ld	a2,0(s4)
ffffffffc0201d8e:	46a9                	li	a3,10
ffffffffc0201d90:	8a2e                	mv	s4,a1
ffffffffc0201d92:	bfc1                	j	ffffffffc0201d62 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201d94:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0201d98:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201d9a:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201d9c:	bdf1                	j	ffffffffc0201c78 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0201d9e:	85a6                	mv	a1,s1
ffffffffc0201da0:	02500513          	li	a0,37
ffffffffc0201da4:	9902                	jalr	s2
            break;
ffffffffc0201da6:	b545                	j	ffffffffc0201c46 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201da8:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0201dac:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201dae:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201db0:	b5e1                	j	ffffffffc0201c78 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0201db2:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201db4:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201db8:	01174463          	blt	a4,a7,ffffffffc0201dc0 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0201dbc:	14088163          	beqz	a7,ffffffffc0201efe <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0201dc0:	000a3603          	ld	a2,0(s4)
ffffffffc0201dc4:	46a1                	li	a3,8
ffffffffc0201dc6:	8a2e                	mv	s4,a1
ffffffffc0201dc8:	bf69                	j	ffffffffc0201d62 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0201dca:	03000513          	li	a0,48
ffffffffc0201dce:	85a6                	mv	a1,s1
ffffffffc0201dd0:	e03e                	sd	a5,0(sp)
ffffffffc0201dd2:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0201dd4:	85a6                	mv	a1,s1
ffffffffc0201dd6:	07800513          	li	a0,120
ffffffffc0201dda:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201ddc:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0201dde:	6782                	ld	a5,0(sp)
ffffffffc0201de0:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201de2:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0201de6:	bfb5                	j	ffffffffc0201d62 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201de8:	000a3403          	ld	s0,0(s4)
ffffffffc0201dec:	008a0713          	addi	a4,s4,8
ffffffffc0201df0:	e03a                	sd	a4,0(sp)
ffffffffc0201df2:	14040263          	beqz	s0,ffffffffc0201f36 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0201df6:	0fb05763          	blez	s11,ffffffffc0201ee4 <vprintfmt+0x2d8>
ffffffffc0201dfa:	02d00693          	li	a3,45
ffffffffc0201dfe:	0cd79163          	bne	a5,a3,ffffffffc0201ec0 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201e02:	00044783          	lbu	a5,0(s0)
ffffffffc0201e06:	0007851b          	sext.w	a0,a5
ffffffffc0201e0a:	cf85                	beqz	a5,ffffffffc0201e42 <vprintfmt+0x236>
ffffffffc0201e0c:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201e10:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201e14:	000c4563          	bltz	s8,ffffffffc0201e1e <vprintfmt+0x212>
ffffffffc0201e18:	3c7d                	addiw	s8,s8,-1
ffffffffc0201e1a:	036c0263          	beq	s8,s6,ffffffffc0201e3e <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0201e1e:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201e20:	0e0c8e63          	beqz	s9,ffffffffc0201f1c <vprintfmt+0x310>
ffffffffc0201e24:	3781                	addiw	a5,a5,-32
ffffffffc0201e26:	0ef47b63          	bgeu	s0,a5,ffffffffc0201f1c <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0201e2a:	03f00513          	li	a0,63
ffffffffc0201e2e:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201e30:	000a4783          	lbu	a5,0(s4)
ffffffffc0201e34:	3dfd                	addiw	s11,s11,-1
ffffffffc0201e36:	0a05                	addi	s4,s4,1
ffffffffc0201e38:	0007851b          	sext.w	a0,a5
ffffffffc0201e3c:	ffe1                	bnez	a5,ffffffffc0201e14 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0201e3e:	01b05963          	blez	s11,ffffffffc0201e50 <vprintfmt+0x244>
ffffffffc0201e42:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0201e44:	85a6                	mv	a1,s1
ffffffffc0201e46:	02000513          	li	a0,32
ffffffffc0201e4a:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201e4c:	fe0d9be3          	bnez	s11,ffffffffc0201e42 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201e50:	6a02                	ld	s4,0(sp)
ffffffffc0201e52:	bbd5                	j	ffffffffc0201c46 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201e54:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201e56:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0201e5a:	01174463          	blt	a4,a7,ffffffffc0201e62 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0201e5e:	08088d63          	beqz	a7,ffffffffc0201ef8 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0201e62:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0201e66:	0a044d63          	bltz	s0,ffffffffc0201f20 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0201e6a:	8622                	mv	a2,s0
ffffffffc0201e6c:	8a66                	mv	s4,s9
ffffffffc0201e6e:	46a9                	li	a3,10
ffffffffc0201e70:	bdcd                	j	ffffffffc0201d62 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0201e72:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201e76:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0201e78:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0201e7a:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0201e7e:	8fb5                	xor	a5,a5,a3
ffffffffc0201e80:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201e84:	02d74163          	blt	a4,a3,ffffffffc0201ea6 <vprintfmt+0x29a>
ffffffffc0201e88:	00369793          	slli	a5,a3,0x3
ffffffffc0201e8c:	97de                	add	a5,a5,s7
ffffffffc0201e8e:	639c                	ld	a5,0(a5)
ffffffffc0201e90:	cb99                	beqz	a5,ffffffffc0201ea6 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201e92:	86be                	mv	a3,a5
ffffffffc0201e94:	00001617          	auipc	a2,0x1
ffffffffc0201e98:	27460613          	addi	a2,a2,628 # ffffffffc0203108 <slub_sizes+0x50>
ffffffffc0201e9c:	85a6                	mv	a1,s1
ffffffffc0201e9e:	854a                	mv	a0,s2
ffffffffc0201ea0:	0ce000ef          	jal	ra,ffffffffc0201f6e <printfmt>
ffffffffc0201ea4:	b34d                	j	ffffffffc0201c46 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201ea6:	00001617          	auipc	a2,0x1
ffffffffc0201eaa:	25260613          	addi	a2,a2,594 # ffffffffc02030f8 <slub_sizes+0x40>
ffffffffc0201eae:	85a6                	mv	a1,s1
ffffffffc0201eb0:	854a                	mv	a0,s2
ffffffffc0201eb2:	0bc000ef          	jal	ra,ffffffffc0201f6e <printfmt>
ffffffffc0201eb6:	bb41                	j	ffffffffc0201c46 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0201eb8:	00001417          	auipc	s0,0x1
ffffffffc0201ebc:	23840413          	addi	s0,s0,568 # ffffffffc02030f0 <slub_sizes+0x38>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201ec0:	85e2                	mv	a1,s8
ffffffffc0201ec2:	8522                	mv	a0,s0
ffffffffc0201ec4:	e43e                	sd	a5,8(sp)
ffffffffc0201ec6:	0fc000ef          	jal	ra,ffffffffc0201fc2 <strnlen>
ffffffffc0201eca:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0201ece:	01b05b63          	blez	s11,ffffffffc0201ee4 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0201ed2:	67a2                	ld	a5,8(sp)
ffffffffc0201ed4:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201ed8:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0201eda:	85a6                	mv	a1,s1
ffffffffc0201edc:	8552                	mv	a0,s4
ffffffffc0201ede:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201ee0:	fe0d9ce3          	bnez	s11,ffffffffc0201ed8 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201ee4:	00044783          	lbu	a5,0(s0)
ffffffffc0201ee8:	00140a13          	addi	s4,s0,1
ffffffffc0201eec:	0007851b          	sext.w	a0,a5
ffffffffc0201ef0:	d3a5                	beqz	a5,ffffffffc0201e50 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201ef2:	05e00413          	li	s0,94
ffffffffc0201ef6:	bf39                	j	ffffffffc0201e14 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0201ef8:	000a2403          	lw	s0,0(s4)
ffffffffc0201efc:	b7ad                	j	ffffffffc0201e66 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0201efe:	000a6603          	lwu	a2,0(s4)
ffffffffc0201f02:	46a1                	li	a3,8
ffffffffc0201f04:	8a2e                	mv	s4,a1
ffffffffc0201f06:	bdb1                	j	ffffffffc0201d62 <vprintfmt+0x156>
ffffffffc0201f08:	000a6603          	lwu	a2,0(s4)
ffffffffc0201f0c:	46a9                	li	a3,10
ffffffffc0201f0e:	8a2e                	mv	s4,a1
ffffffffc0201f10:	bd89                	j	ffffffffc0201d62 <vprintfmt+0x156>
ffffffffc0201f12:	000a6603          	lwu	a2,0(s4)
ffffffffc0201f16:	46c1                	li	a3,16
ffffffffc0201f18:	8a2e                	mv	s4,a1
ffffffffc0201f1a:	b5a1                	j	ffffffffc0201d62 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0201f1c:	9902                	jalr	s2
ffffffffc0201f1e:	bf09                	j	ffffffffc0201e30 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0201f20:	85a6                	mv	a1,s1
ffffffffc0201f22:	02d00513          	li	a0,45
ffffffffc0201f26:	e03e                	sd	a5,0(sp)
ffffffffc0201f28:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0201f2a:	6782                	ld	a5,0(sp)
ffffffffc0201f2c:	8a66                	mv	s4,s9
ffffffffc0201f2e:	40800633          	neg	a2,s0
ffffffffc0201f32:	46a9                	li	a3,10
ffffffffc0201f34:	b53d                	j	ffffffffc0201d62 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0201f36:	03b05163          	blez	s11,ffffffffc0201f58 <vprintfmt+0x34c>
ffffffffc0201f3a:	02d00693          	li	a3,45
ffffffffc0201f3e:	f6d79de3          	bne	a5,a3,ffffffffc0201eb8 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0201f42:	00001417          	auipc	s0,0x1
ffffffffc0201f46:	1ae40413          	addi	s0,s0,430 # ffffffffc02030f0 <slub_sizes+0x38>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201f4a:	02800793          	li	a5,40
ffffffffc0201f4e:	02800513          	li	a0,40
ffffffffc0201f52:	00140a13          	addi	s4,s0,1
ffffffffc0201f56:	bd6d                	j	ffffffffc0201e10 <vprintfmt+0x204>
ffffffffc0201f58:	00001a17          	auipc	s4,0x1
ffffffffc0201f5c:	199a0a13          	addi	s4,s4,409 # ffffffffc02030f1 <slub_sizes+0x39>
ffffffffc0201f60:	02800513          	li	a0,40
ffffffffc0201f64:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201f68:	05e00413          	li	s0,94
ffffffffc0201f6c:	b565                	j	ffffffffc0201e14 <vprintfmt+0x208>

ffffffffc0201f6e <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201f6e:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201f70:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201f74:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201f76:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201f78:	ec06                	sd	ra,24(sp)
ffffffffc0201f7a:	f83a                	sd	a4,48(sp)
ffffffffc0201f7c:	fc3e                	sd	a5,56(sp)
ffffffffc0201f7e:	e0c2                	sd	a6,64(sp)
ffffffffc0201f80:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201f82:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201f84:	c89ff0ef          	jal	ra,ffffffffc0201c0c <vprintfmt>
}
ffffffffc0201f88:	60e2                	ld	ra,24(sp)
ffffffffc0201f8a:	6161                	addi	sp,sp,80
ffffffffc0201f8c:	8082                	ret

ffffffffc0201f8e <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc0201f8e:	4781                	li	a5,0
ffffffffc0201f90:	00005717          	auipc	a4,0x5
ffffffffc0201f94:	08073703          	ld	a4,128(a4) # ffffffffc0207010 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201f98:	88ba                	mv	a7,a4
ffffffffc0201f9a:	852a                	mv	a0,a0
ffffffffc0201f9c:	85be                	mv	a1,a5
ffffffffc0201f9e:	863e                	mv	a2,a5
ffffffffc0201fa0:	00000073          	ecall
ffffffffc0201fa4:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0201fa6:	8082                	ret

ffffffffc0201fa8 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0201fa8:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0201fac:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0201fae:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0201fb0:	cb81                	beqz	a5,ffffffffc0201fc0 <strlen+0x18>
        cnt ++;
ffffffffc0201fb2:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0201fb4:	00a707b3          	add	a5,a4,a0
ffffffffc0201fb8:	0007c783          	lbu	a5,0(a5)
ffffffffc0201fbc:	fbfd                	bnez	a5,ffffffffc0201fb2 <strlen+0xa>
ffffffffc0201fbe:	8082                	ret
    }
    return cnt;
}
ffffffffc0201fc0:	8082                	ret

ffffffffc0201fc2 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0201fc2:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201fc4:	e589                	bnez	a1,ffffffffc0201fce <strnlen+0xc>
ffffffffc0201fc6:	a811                	j	ffffffffc0201fda <strnlen+0x18>
        cnt ++;
ffffffffc0201fc8:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201fca:	00f58863          	beq	a1,a5,ffffffffc0201fda <strnlen+0x18>
ffffffffc0201fce:	00f50733          	add	a4,a0,a5
ffffffffc0201fd2:	00074703          	lbu	a4,0(a4)
ffffffffc0201fd6:	fb6d                	bnez	a4,ffffffffc0201fc8 <strnlen+0x6>
ffffffffc0201fd8:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0201fda:	852e                	mv	a0,a1
ffffffffc0201fdc:	8082                	ret

ffffffffc0201fde <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201fde:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201fe2:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201fe6:	cb89                	beqz	a5,ffffffffc0201ff8 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0201fe8:	0505                	addi	a0,a0,1
ffffffffc0201fea:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201fec:	fee789e3          	beq	a5,a4,ffffffffc0201fde <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201ff0:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201ff4:	9d19                	subw	a0,a0,a4
ffffffffc0201ff6:	8082                	ret
ffffffffc0201ff8:	4501                	li	a0,0
ffffffffc0201ffa:	bfed                	j	ffffffffc0201ff4 <strcmp+0x16>

ffffffffc0201ffc <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201ffc:	c20d                	beqz	a2,ffffffffc020201e <strncmp+0x22>
ffffffffc0201ffe:	962e                	add	a2,a2,a1
ffffffffc0202000:	a031                	j	ffffffffc020200c <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0202002:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0202004:	00e79a63          	bne	a5,a4,ffffffffc0202018 <strncmp+0x1c>
ffffffffc0202008:	00b60b63          	beq	a2,a1,ffffffffc020201e <strncmp+0x22>
ffffffffc020200c:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0202010:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0202012:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0202016:	f7f5                	bnez	a5,ffffffffc0202002 <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0202018:	40e7853b          	subw	a0,a5,a4
}
ffffffffc020201c:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020201e:	4501                	li	a0,0
ffffffffc0202020:	8082                	ret

ffffffffc0202022 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0202022:	ca01                	beqz	a2,ffffffffc0202032 <memset+0x10>
ffffffffc0202024:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0202026:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0202028:	0785                	addi	a5,a5,1
ffffffffc020202a:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc020202e:	fec79de3          	bne	a5,a2,ffffffffc0202028 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0202032:	8082                	ret
