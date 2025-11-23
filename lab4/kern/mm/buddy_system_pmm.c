#include <pmm.h>
#include <list.h>
#include <string.h>
#include <buddy_system_pmm.h>
#include <stdio.h>

/* Buddy System算法把系统中的可用存储空间划分为存储块(Block)来进行管理, 每个存储块的大小必须是2的n次幂(Pow(2, n)), 即1, 2, 4, 8, 16, 32, 64, 128...
   当有内存分配请求时，算法会找到能满足请求的最小的2的幂次大小的块。如果找到的块比请求的大，就将其分裂成两个相等的"伙伴"块，
   直到得到合适大小的块。当释放内存时，算法会检查其"伙伴"块是否也是空闲的，如果是，就将它们合并成一个更大的块。
   这种设计能够有效减少外部碎片，提高内存利用率。
   
   本实现参考了wuwenbin的buddy system极简实现，但根据ucore的pmm框架进行了适配和重构。
*/

// LAB2 CHALLENGE 1: /*解子萱 2312585 、崔颖欣 2311136 、范鼎辉 2312326*/
// 需要重写以下函数: default_init, default_init_memmap, default_alloc_pages, default_free_pages.
/*
 * Buddy System算法详细说明:
 * (1) 数据结构: 使用完全二叉树来管理内存块，每个节点记录其对应内存块的最大可用大小
 *     树的叶子节点对应最小的内存单元，根节点对应整个内存区域
 * (2) buddy_init: 初始化buddy system的数据结构
 * (3) buddy_init_memmap: 根据给定的内存区域初始化buddy system
 *     需要计算合适的树大小，并初始化所有节点的值
 * (4) buddy_alloc_pages: 分配指定数量的页面
 *     从根节点开始，递归查找合适大小的空闲块
 *     找到后标记为已分配，并更新父节点的信息
 * (5) buddy_free_pages: 释放指定的页面
 *     找到对应的节点，标记为空闲
 *     检查伙伴节点是否也空闲，如果是则合并
 */

// Buddy system的核心数据结构
// 借鉴了wuwenbin实现中的二叉树思想，但适配了ucore的Page结构
struct buddy_system {
    unsigned size;          // 管理的总页面数，必须是2的幂
    unsigned *longest;      // 二叉树数组，记录每个节点对应的最大可用块大小
    struct Page *base;      // 内存区域的起始页面
};

static struct buddy_system buddy;  // 全局buddy system实例

// 一些有用的宏定义，借鉴自wuwenbin的实现
#define LEFT_LEAF(index) ((index) * 2 + 1)        // 计算左子节点索引
#define RIGHT_LEAF(index) ((index) * 2 + 2)       // 计算右子节点索引
#define PARENT(index) (((index) + 1) / 2 - 1)     // 计算父节点索引
#define IS_POWER_OF_2(x) (!((x) & ((x) - 1)))     // 判断是否为2的幂
#define MAX(a, b) ((a) > (b) ? (a) : (b))        // 取最大值宏

static void
buddy_init(void) {
    // 初始化buddy system，这里暂时不分配内存
    // 实际的初始化在buddy_init_memmap中进行
    buddy.size = 0;         // 初始大小为0
    buddy.longest = NULL;   // 二叉树数组指针为空
    buddy.base = NULL;      // 内存基地址为空
}

static void
buddy_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);          // 确保页面数大于0
    
    // 将页面数调整为2的幂，这是buddy system的基本要求
    unsigned size = 1;      // 初始大小为1
    while (size < n) size <<= 1;  // 循环左移直到找到不小于n的2的幂
    
    // 限制最大支持的页面数，避免数组越界
    if (size > 2048) {      // 如果超过2048页
        size = 2048;        // 限制为最大2048页
    }
    
    buddy.size = size;      // 设置buddy system的大小
    buddy.base = base;      // 设置内存基地址
    
    // 分配二叉树数组，大小为2*size-1（完全二叉树的节点数）
    // 这里我们使用静态数组来避免动态分配的复杂性
    static unsigned tree[4096]; // 支持最大2048页 (2*2048-1=4095)
    buddy.longest = tree;   // 设置二叉树数组指针
    
    // 清零数组
    memset(tree, 0, sizeof(tree));  // 将数组所有元素初始化为0
    
    // 初始化二叉树，参考wuwenbin的实现思路
    unsigned node_size = size * 2;  // 初始节点大小为2倍总页面数
    for (int i = 0; i < 2 * size - 1; ++i) {  // 遍历所有节点
        if (IS_POWER_OF_2(i + 1))   // 如果i+1是2的幂（即到达新的一层）
            node_size /= 2;          // 节点大小减半
        buddy.longest[i] = node_size; // 设置节点的最大可用大小
    }
    
    // 初始化所有页面
    struct Page *p = base;  // 指向内存起始位置
    for (; p != base + n; p++) {  // 遍历所有实际页面
        assert(PageReserved(p));  // 确保页面是保留状态
        p->flags = p->property = 0;  // 清空页面标志和属性
        set_page_ref(p, 0);        // 设置页面引用计数为0
    }
    
    // 如果实际页面数小于2的幂，需要标记多余的部分为不可用
    if (n < size) {         // 如果实际页面数小于调整后的2的幂
        // 标记超出实际内存范围的叶子节点为不可用
        for (unsigned i = n; i < size; i++) {  // 遍历超出范围的页面
            unsigned index = i + size - 1;    // 计算对应的叶子节点索引
            buddy.longest[index] = 0;         // 标记为不可用（大小为0）
        }
        
        // 从叶子节点向上更新父节点
        for (int i = size - 2; i >= 0; i--) {  // 从倒数第二层向上遍历
            unsigned left = buddy.longest[LEFT_LEAF(i)];   // 左子节点大小
            unsigned right = buddy.longest[RIGHT_LEAF(i)]; // 右子节点大小
            buddy.longest[i] = MAX(left, right);           // 父节点大小为子节点最大值
        }
    }
}

static struct Page *
buddy_alloc_pages(size_t n) {
    assert(n > 0);          // 确保请求页面数大于0
    
    if (buddy.longest == NULL || n > buddy.size) {  // 检查参数有效性
        return NULL;        // 如果未初始化或请求过大，返回NULL
    }
    
    // 将请求大小调整为2的幂
    unsigned size = 1;      // 初始大小为1
    while (size < n) size <<= 1;  // 循环左移直到找到不小于n的2的幂
    
    // 从根节点开始查找，参考wuwenbin的分配算法
    unsigned index = 0;     // 从根节点开始（索引0）
    unsigned node_size;     // 当前节点大小
    
    if (buddy.longest[index] < size)  // 如果根节点可用大小不足
        return NULL;        // 分配失败，返回NULL
    
    // 向下查找合适的节点
    for (node_size = buddy.size; node_size != size; node_size /= 2) {  // 从最大节点大小开始
        if (buddy.longest[LEFT_LEAF(index)] >= size)  // 如果左子节点足够大
            index = LEFT_LEAF(index);                 // 选择左子节点
        else
            index = RIGHT_LEAF(index);                // 否则选择右子节点
    }
    
    // 标记该节点为已分配
    buddy.longest[index] = 0;  // 设置节点大小为0表示已分配
    
    // 计算页面偏移量
    unsigned offset = (index + 1) * node_size - buddy.size;  // 计算页面在数组中的偏移
    
    // 向上更新父节点信息
    while (index) {         // 从当前节点向上直到根节点
        index = PARENT(index);                          // 移动到父节点
        buddy.longest[index] = MAX(buddy.longest[LEFT_LEAF(index)],  // 左子节点大小
                                 buddy.longest[RIGHT_LEAF(index)]); // 右子节点大小
    }
    
    // 返回分配的页面
    return buddy.base + offset;  // 返回页面指针
}

static void
buddy_free_pages(struct Page *base, size_t n) {
    assert(n > 0);          // 确保释放页面数大于0
    assert(base >= buddy.base && base < buddy.base + buddy.size);  // 检查页面有效性
    
    // 计算页面偏移量
    unsigned offset = base - buddy.base;  // 计算页面在数组中的偏移
    
    // 直接使用wuwenbin的释放算法，不需要考虑释放大小
    unsigned node_size = 1;  // 初始节点大小为1
    unsigned index = offset + buddy.size - 1;  // 计算叶子节点索引
    
    // 向上查找到正确的节点（找到值为0的节点）
    for (; buddy.longest[index]; index = PARENT(index)) {  // 向上查找直到找到已分配的节点
        node_size *= 2;     // 节点大小加倍
        if (index == 0)     // 如果到达根节点
            return;         // 直接返回（不应该发生）
    }
    
    // 标记该节点为空闲
    buddy.longest[index] = node_size;  // 设置节点大小为原始大小
    
    // 向上合并空闲的伙伴节点
    while (index) {         // 从当前节点向上直到根节点
        index = PARENT(index);          // 移动到父节点
        node_size *= 2;                 // 节点大小加倍
        
        unsigned left_longest = buddy.longest[LEFT_LEAF(index)];   // 左子节点大小
        unsigned right_longest = buddy.longest[RIGHT_LEAF(index)]; // 右子节点大小
        
        // 如果两个子节点都空闲且大小相等，则合并
        if (left_longest + right_longest == node_size)  // 如果子节点大小之和等于父节点大小
            buddy.longest[index] = node_size;           // 合并为父节点大小
        else
            buddy.longest[index] = MAX(left_longest, right_longest);  // 否则取最大值
    }
    
    // 重置页面状态
    struct Page *p = base;  // 指向要释放的页面
    for (; p != base + n; p++) {  // 遍历所有要释放的页面
        p->flags = 0;       // 清空页面标志
        set_page_ref(p, 0); // 设置页面引用计数为0
    }
}

static size_t
buddy_nr_free_pages(void) {
    // 返回当前可用的页面数
    // 这里我们返回根节点的最大可用块大小
    if (buddy.longest == NULL)  // 如果未初始化
        return 0;               // 返回0
    return buddy.longest[0];    // 返回根节点的可用大小
}

// 基础测试函数，复用default_pmm.c中的实现
static void
basic_check(void) {
    struct Page *p0, *p1, *p2;  // 测试页面指针
    p0 = p1 = p2 = NULL;        // 初始化为NULL
    assert((p0 = alloc_page()) != NULL);  // 分配第1个页面
    assert((p1 = alloc_page()) != NULL);  // 分配第2个页面
    assert((p2 = alloc_page()) != NULL);  // 分配第3个页面

    assert(p0 != p1 && p0 != p2 && p1 != p2);  // 确保页面地址不同
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);  // 引用计数为0

    assert(page2pa(p0) < npage * PGSIZE);  // 页面地址在有效范围内
    assert(page2pa(p1) < npage * PGSIZE);  // 页面地址在有效范围内
    assert(page2pa(p2) < npage * PGSIZE);  // 页面地址在有效范围内

    free_page(p0);          // 释放第1个页面
    free_page(p1);          // 释放第2个页面
    free_page(p2);          // 释放第3个页面
}

// Buddy system专用的测试函数、

// 辅助函数：显示被分配页面的详细地址信息
static void show_page_info(struct Page *page, size_t n, const char *desc) {
    // 计算页面在pages数组中的索引
    size_t page_index = page - buddy.base;  // 页面索引 = 页面地址 - 基址
    // 使用系统提供的page2pa函数计算物理地址
    uintptr_t phys_addr = page2pa(page);  // 调用系统函数获取物理地址
    
    cprintf("  %s: 页面索引[%d-%d], 物理地址[0x%08x-0x%08x], 大小%dKB\n", 
            desc, page_index, page_index + n - 1,  // 页面索引范围
            phys_addr, phys_addr + n * PGSIZE - 1,  // 物理地址范围
            n * PGSIZE / 1024);  // 大小（KB）
}

static void
buddy_check(void) {
// - 测试1：基本的2的幂次分配和释放 - 验证Buddy System能够正确分配和释放1、2、4、8页等2的幂次大小的内存块。
// - 测试2：非2的幂次分配（向上取整） - 测试请求3、5、6、7页时，系统能够正确向上取整到4、8、8、8页进行分配。
// - 测试3：伙伴合并机制测试 - 验证当连续分配多个小内存块并释放时，系统能够正确合并伙伴块形成更大的空闲块。
// - 测试4：连续分配和释放压力测试 - 通过连续分配和释放16个1页块，测试系统在压力情况下的稳定性和性能。
// - 测试5：大块分配测试 - 测试分配16页大块的能力，验证系统对大内存请求的处理。
// - 测试6：边界情况测试 - 包括测试分配1024页和512页等边界情况，验证系统对极端内存请求的处理。
// - 测试7：碎片整理效果测试 - 通过有策略地分配和释放内存块，制造碎片化场景，然后测试系统是否仍能分配大块内存。
// - 测试8：功能正确性验证 - 验证分配的页面地址是否在合理范围内，分配的页面地址是否唯一，确保没有地址冲突。
// - 测试9：最终内存泄漏检查 - 比较测试前后的可用页面数，确保没有内存泄漏发生。
    // 先进行基础测试
    basic_check();          // 运行基础测试
    
    cprintf("\n--- 开始buddy system专项测试 ---\n");  // 输出测试开始信息
    
    // 记录初始状态
    size_t initial_free = buddy_nr_free_pages();  // 获取初始可用页面数
    cprintf("初始可用页面数: %d\n", initial_free);  // 输出初始状态
    
    // 测试1: 基本的2的幂次分配和释放
    cprintf("\n--- 测试1: 基本的2的幂次分配和释放 ---\n");
    struct Page *p1, *p2, *p4, *p8;  // 测试页面指针
    
    p1 = alloc_pages(1);   // 分配1页
    assert(p1 != NULL);    // 确保分配成功
    cprintf("✓ 分配1页成功\n");  // 输出成功信息
    show_page_info(p1, 1, "1页块");  // 显示1页块详细信息
    
    p2 = alloc_pages(2);   // 分配2页
    assert(p2 != NULL);    // 确保分配成功
    cprintf("✓ 分配2页成功\n");  // 输出成功信息
    show_page_info(p2, 2, "2页块");  // 显示2页块详细信息
    
    p4 = alloc_pages(4);   // 分配4页
    assert(p4 != NULL);    // 确保分配成功
    cprintf("✓ 分配4页成功\n");  // 输出成功信息
    show_page_info(p4, 4, "4页块");  // 显示4页块详细信息
    
    p8 = alloc_pages(8);   // 分配8页
    assert(p8 != NULL);    // 确保分配成功
    cprintf("✓ 分配8页成功\n");  // 输出成功信息
    show_page_info(p8, 8, "8页块");  // 显示8页块详细信息

    // 检查分配后的可用内存
    size_t after_alloc = buddy_nr_free_pages();  // 获取分配后可用页面数
    cprintf("分配后可用页面数: %d\n", after_alloc);  // 输出分配后状态
    
    // 释放内存
    free_pages(p1, 1);     // 释放1页
    cprintf("✓ 释放1页成功\n");  // 输出成功信息
    
    free_pages(p2, 2);     // 释放2页
    cprintf("✓ 释放2页成功\n");  // 输出成功信息
    
    free_pages(p4, 4);     // 释放4页
    cprintf("✓ 释放4页成功\n");  // 输出成功信息
    
    free_pages(p8, 8);     // 释放8页
    cprintf("✓ 释放8页成功\n");  // 输出成功信息
    
    // 测试2: 非2的幂次分配（向上取整）
    cprintf("\n--- 测试2: 非2的幂次分配（向上取整） ---\n");
    struct Page *p3, *p5, *p6, *p7;  // 测试页面指针
    
    p3 = alloc_pages(3);   // 请求3页，应该分配4页
    assert(p3 != NULL);     // 确保分配成功
    cprintf("✓ 请求3页分配成功（实际分配4页）\n");  // 输出成功信息
    show_page_info(p3, 4, "请求3页实际分配4页");  // 显示实际分配的4页详细信息
    
    p5 = alloc_pages(5);   // 请求5页，应该分配8页
    assert(p5 != NULL);     // 确保分配成功
    cprintf("✓ 请求5页分配成功（实际分配8页）\n");  // 输出成功信息
    show_page_info(p5, 8, "请求5页实际分配8页");  // 显示实际分配的8页详细信息
    
    p6 = alloc_pages(6);   // 请求6页，应该分配8页
    assert(p6 != NULL);     // 确保分配成功
    cprintf("✓ 请求6页分配成功（实际分配8页）\n");  // 输出成功信息
    show_page_info(p6, 8, "请求6页实际分配8页");  // 显示实际分配的8页详细信息
    
    p7 = alloc_pages(7);   // 请求7页，应该分配8页
    assert(p7 != NULL);     // 确保分配成功
    cprintf("✓ 请求7页分配成功（实际分配8页）\n");  // 输出成功信息
    show_page_info(p7, 8, "请求7页实际分配8页");  // 显示实际分配的8页详细信息
    
    // 释放非2的幂次分配的内存
    free_pages(p3, 3);     // 释放3页
    cprintf("✓ 释放3页成功\n");  // 输出成功信息
    
    free_pages(p5, 5);     // 释放5页
    cprintf("✓ 释放5页成功\n");  // 输出成功信息
    
    free_pages(p6, 6);     // 释放6页
    cprintf("✓ 释放6页成功\n");  // 输出成功信息
    
    free_pages(p7, 7);     // 释放7页
    cprintf("✓ 释放7页成功\n");  // 输出成功信息
    
    // 测试3: 伙伴合并机制
    cprintf("\n--- 测试3: 伙伴合并机制测试 ---\n");
    struct Page *buddy_test[4];  // 测试页面数组
    
    // 分配4个连续的1页块
    cprintf("分配4个1页块，观察buddy system的分配策略：\n");
    for (int i = 0; i < 4; i++) {  // 循环分配4次
        buddy_test[i] = alloc_pages(1);  // 每次分配1页
        if (buddy_test[i] != NULL) {  // 如果分配成功
            cprintf("✓ 分配第%d个1页块成功\n", i+1);  // 输出成功信息
            show_page_info(buddy_test[i], 1, "1页块");  // 显示每个1页块的详细信息
        }
    }
    
    size_t before_merge = buddy_nr_free_pages();  // 获取合并前可用页面数
    cprintf("合并前可用页面数: %d\n", before_merge);  // 输出合并前状态
    
    // 释放这些块，测试合并效果
    cprintf("释放这些1页块，观察buddy system的合并过程：\n");
    for (int i = 0; i < 4; i++) {  // 循环释放4次
        if (buddy_test[i] != NULL) {  // 如果页面有效
            free_pages(buddy_test[i], 1);  // 释放1页
            cprintf("✓ 释放第%d个1页块\n", i+1);  // 输出成功信息
            cprintf("  当前可用页面数: %d\n", buddy_nr_free_pages());  // 显示释放后的可用页面数
        }
    }
    
    size_t after_merge = buddy_nr_free_pages();  // 获取合并后可用页面数
    cprintf("合并后可用页面数: %d\n", after_merge);  // 输出合并后状态
    
    // 验证合并效果：尝试分配一个大块
    cprintf("验证合并效果：尝试分配4页大块\n");
    struct Page *merged_block = alloc_pages(4);  // 尝试分配4页
    if (merged_block != NULL) {  // 如果分配成功
        cprintf("✓ 合并后成功分配4页大块\n");  // 输出成功信息
        show_page_info(merged_block, 4, "合并后的4页块");  // 显示合并后的大块信息
        free_pages(merged_block, 4);  // 释放4页大块
        cprintf("✓ 释放4页大块\n");  // 输出成功信息
    } else {
        cprintf("✗ 合并后无法分配4页大块\n");  // 输出失败信息
    }
    
    // 测试4: 连续分配和释放
    cprintf("\n--- 测试4: 连续分配和释放压力测试 ---\n");
    struct Page *stress_test[16];  // 压力测试页面数组
    int success_count = 0;         // 成功计数
    
    // 连续分配多个1页块
    for (int i = 0; i < 16; i++) {  // 循环分配16次
        stress_test[i] = alloc_pages(1);  // 每次分配1页
        if (stress_test[i] != NULL) {  // 如果分配成功
            success_count++;           // 成功计数加1
        }
    }
    cprintf("✓ 成功分配%d个1页块\n", success_count);  // 输出成功信息
    
    // 释放所有成功分配的块
    for (int i = 0; i < 16; i++) {  // 循环释放16次
        if (stress_test[i] != NULL) {  // 如果页面有效
            free_pages(stress_test[i], 1);  // 释放1页
        }
    }
    cprintf("✓ 释放所有分配的块\n");  // 输出成功信息
    
    // 测试5: 大块分配测试
    cprintf("\n--- 测试5: 大块分配测试 ---\n");
    struct Page *large_blocks[4];  // 大块测试页面数组
    int large_success = 0;         // 大块成功计数
    
    // 尝试分配多个大块
    cprintf("尝试分配多个16页大块，观察buddy system对大内存的处理：\n");
    for (int i = 0; i < 4; i++) {  // 循环分配4次
        large_blocks[i] = alloc_pages(16);  // 每次分配16页
        if (large_blocks[i] != NULL) {  // 如果分配成功
            large_success++;            // 成功计数加1
            cprintf("✓ 成功分配第%d个16页大块\n", i+1);  // 输出成功信息
            show_page_info(large_blocks[i], 16, "16页大块");  // 显示16页大块详细信息
        } else {
            cprintf("! 分配第%d个16页大块失败\n", i+1);  // 输出失败信息
        }
    }
    
    cprintf("成功分配%d个16页大块，总计%dKB\n", large_success, large_success * 16 * 4);
    
    // 释放大块
    cprintf("释放所有大块：\n");
    for (int i = 0; i < 4; i++) {  // 循环释放4次
        if (large_blocks[i] != NULL) {  // 如果页面有效
            free_pages(large_blocks[i], 16);  // 释放16页
            cprintf("✓ 释放第%d个16页大块\n", i+1);  // 输出成功信息
        }
    }
    
    // 测试6: 边界情况测试
    cprintf("\n--- 测试6: 边界情况测试 ---\n");
    
    // 测试分配大块内存
    cprintf("测试极限分配：尝试分配1024页（4MB）\n");
    struct Page *huge_block = alloc_pages(1024);  // 尝试分配1024页
    if (huge_block != NULL) {  // 如果分配成功
        cprintf("✓ 分配1024页成功\n");  // 输出成功信息
        show_page_info(huge_block, 1024, "1024页超大块");  // 显示1024页详细信息
        free_pages(huge_block, 1024);   // 释放1024页
        cprintf("✓ 释放1024页成功\n");  // 输出成功信息
    } else {
        cprintf("! 分配1024页失败（可能超出buddy system最大支持范围）\n");  // 输出失败信息
    }
    
    // 测试分配最大可能的块
    cprintf("测试分配512页（2MB）\n");
    struct Page *max_block = alloc_pages(512);  // 尝试分配512页
    if (max_block != NULL) {  // 如果分配成功
        cprintf("✓ 分配512页成功\n");  // 输出成功信息
        show_page_info(max_block, 512, "512页大块");  // 显示512页详细信息
        free_pages(max_block, 512);   // 释放512页
        cprintf("✓ 释放512页成功\n");  // 输出成功信息
    } else {
        cprintf("! 分配512页失败\n");  // 输出失败信息
    }
    
    // 测试7: 碎片整理效果测试
    cprintf("\n--- 测试7: 碎片整理效果测试 ---\n");
    struct Page *frag_test[8];  // 碎片测试页面数组
    
    // 分配8个2页块
    for (int i = 0; i < 8; i++) {  // 循环分配8次
        frag_test[i] = alloc_pages(2);  // 每次分配2页
        if (frag_test[i] != NULL) {  // 如果分配成功
            cprintf("✓ 分配第%d个2页块\n", i+1);  // 输出成功信息
        }
    }
    
    // 释放奇数位置的块，制造碎片
    for (int i = 1; i < 8; i += 2) {  // 释放奇数索引的块
        if (frag_test[i] != NULL) {  // 如果页面有效
            free_pages(frag_test[i], 2);  // 释放2页
            cprintf("✓ 释放第%d个2页块（制造碎片）\n", i+1);  // 输出成功信息
        }
    }
    
    // 尝试分配大块，测试碎片整理
    struct Page *defrag_test = alloc_pages(8);  // 尝试分配8页
    if (defrag_test != NULL) {  // 如果分配成功
        cprintf("✓ 碎片化后仍能分配8页大块\n");  // 输出成功信息
        free_pages(defrag_test, 8);             // 释放8页
    } else {
        cprintf("! 碎片化后无法分配8页大块\n");  // 输出失败信息
    }
    
    // 清理剩余的偶数位置块
    for (int i = 0; i < 8; i += 2) {  // 释放偶数索引的块
        if (frag_test[i] != NULL) {  // 如果页面有效
            free_pages(frag_test[i], 2);  // 释放2页
        }
    }
    
    // 最终内存泄漏检查
    cprintf("\n--- 最终检查 ---\n");
    size_t final_free = buddy_nr_free_pages();  // 获取最终可用页面数
    cprintf("最终可用页面数: %d\n", final_free);  // 输出最终状态
    
    if (final_free >= initial_free) {  // 如果没有内存泄漏
        cprintf("✓ 内存泄漏检查通过\n");  // 输出通过信息
    } else {
        cprintf("✗ 警告：可能存在内存泄漏（初始:%d, 最终:%d）\n",  // 输出警告信息
                initial_free, final_free);
    }
    
    // 测试8: 功能正确性验证
    cprintf("\n--- 测试8: 功能正确性验证 ---\n");
    
    // 验证分配的页面地址是否合理
    struct Page *verify_p1 = alloc_pages(1);  // 分配验证页面1
    struct Page *verify_p2 = alloc_pages(1);  // 分配验证页面2
    
    if (verify_p1 != NULL && verify_p2 != NULL) {  // 如果分配成功
        // 检查页面地址是否在合理范围内
        if (verify_p1 >= buddy.base && verify_p1 < buddy.base + buddy.size &&
            verify_p2 >= buddy.base && verify_p2 < buddy.base + buddy.size) {
            cprintf("✓ 分配的页面地址在合理范围内\n");  // 输出成功信息
        } else {
            cprintf("✗ 分配的页面地址超出范围\n");  // 输出失败信息
        }
        
        // 检查页面是否不同
        if (verify_p1 != verify_p2) {  // 如果页面地址不同
            cprintf("✓ 分配的页面地址不同\n");  // 输出成功信息
        } else {
            cprintf("✗ 分配了相同的页面地址\n");  // 输出失败信息
        }
        
        free_pages(verify_p1, 1);  // 释放验证页面1
        free_pages(verify_p2, 1);  // 释放验证页面2
    }
    
    cprintf("\n--- buddy_check() 所有测试完成! ---\n");  // 输出测试完成信息
}

// Buddy system的pmm_manager结构体
const struct pmm_manager buddy_system_pmm_manager = {
    .name = "buddy_system_pmm_manager",  // 管理器名称
    .init = buddy_init,                   // 初始化函数指针
    .init_memmap = buddy_init_memmap,     // 内存映射初始化函数指针
    .alloc_pages = buddy_alloc_pages,     // 页面分配函数指针
    .free_pages = buddy_free_pages,       // 页面释放函数指针
    .nr_free_pages = buddy_nr_free_pages,  // 空闲页面计数函数指针
    .check = buddy_check,                 // 检查测试函数指针
};