# MMU相关常量/宏（如PGSHIFT、页表项格式）
#include <mmu.h>         
# 内存布局、内核栈大小等（KSTACKSIZE等） 
#include <memlayout.h>    

    .section .text,"ax",%progbits      # 代码段：可执行+可读
    .globl kern_entry
kern_entry:
    # a0: hartid（当前硬件线程/内核编号）
    # a1: dtb physical address（设备树的物理地址，由上电/引导传入）
    # 保存hartid和dtb地址到全局变量，供C代码使用
    # 下面四句初始化的，与物理内存管理机制关系不大
    la t0, boot_hartid      # 取boot_hartid符号的当前地址（虚拟地址）
    sd a0, 0(t0)            # 将hartid保存到内存
    la t0, boot_dtb         # 取boot_dtb符号的当前地址（虚拟地址）
    sd a1, 0(t0)            # 将dtb物理地址保存到内存

    # t0 := 三级页表的虚拟地址（boot_page_table_sv39在链接时位于内核镜像中）
    lui     t0, %hi(boot_page_table_sv39)
    # t1 := 0xffffffff40000000 即虚实映射偏移量（高地址直映到物理低地址的偏移）
    li      t1, 0xffffffffc0000000 - 0x80000000
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    # t0 减去虚实映射偏移量 => 转换为boot_page_table_sv39的物理地址
    sub     t0, t0, t1
    # t0 >>= 12，变为三级页表的物理页号
    # 将物理地址右移12位 => 得到页表基址的物理页号（PPN），符合satp格式
    srli    t0, t0, 12

    # t1 := 8 << 60，设置satp的MODE字段为Sv39（RISC-V 39位虚拟地址模式）
    li      t1, 8 << 60
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    # 合并MODE与PPN，形成satp寄存器期望的值
    or      t0, t0, t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    # 写satp => 安装预设的三级页表，并切换到Sv39虚拟内存模式
    csrw    satp, t0
    # 刷新TLB，确保新的页表映射立即生效
    sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    # SATP告诉CPU页表在哪？虚拟地址怎么转换成物理地址？使用哪种页表模式？
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    # 设置栈指针sp到内核栈顶（虚拟地址），以支持后续C调用约定
    lui sp, %hi(bootstacktop)

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
    addi t0, t0, %lo(kern_init)
    jr t0                      # 无条件跳转到内核初始化函数

.section .data
    # 对齐到页大小（2^PGSHIFT，2^12），保证栈和页表按页边界对齐
    .align PGSHIFT
    .global bootstack
bootstack:
    .space KSTACKSIZE          # 分配内核栈空间（大小由KSTACKSIZE定义）
    .global bootstacktop
bootstacktop:                   # 标记栈顶符号，供设置sp使用

.section .data
    # 将页表放到一个页里，因此必须按12位对齐（PGSHIFT=12）
    .align PGSHIFT
    .global boot_page_table_sv39
# 分配4KiB内存给预设的三级页表（一级页表，指向巨页映射）
boot_page_table_sv39:
    # 0xffffffff_c0000000 映射到 0x80000000（1G），建立高半区直映
    # 前511个页表项均设置为0 => V=0 => 未映射（unmapped）
    .zero 8 * 511
    # 设置最后一个页表项：PPN=0x80000，权限位VRWXAD=1，表示叶子项（巨页）可读写执行
    .quad (0x80000 << 10) | 0xcf # VRWXAD

    .global boot_hartid
boot_hartid:
    .quad 0                    # 保存hartid的内存位置
    .global boot_dtb
boot_dtb:
    .quad 0                    # 保存设备树物理地址的内存位置
