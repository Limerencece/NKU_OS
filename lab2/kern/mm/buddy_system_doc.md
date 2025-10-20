# buddy system设计文档

## 1  算法简介
Buddy System 是一种将可用内存划分为大小为 2 的幂次的块来进行管理的分配算法。我们在分配时总是选择能够覆盖请求的最小幂次块，若块比请求大则递归地分裂为“伙伴”块，直到得到合适大小；在释放时与其伙伴检测并尽量合并成更大的块，以减少外部碎片。这套机制用一棵完全二叉树来表达每个节点对应内存区域的最大可用块大小，根节点覆盖整个区域，叶节点对应最小单位页。
**本实现参考了wuwenbin的buddy system极简实现，但根据ucore的pmm框架进行了适配和重构，并在一些边界处理和接口兼容方面进行了优化，使其能够无缝集成到ucore操作系统的物理内存管理体系中。在实现顺序上，我们先定义数据结构和树索引宏，然后实现初始化，再完成分配/释放逻辑，最后提供查询与校验。**

## 2  核心数据结构
我们用一个结构体来描述 Buddy System 的核心状态：总页数（2 的幂次）、树数组（每个节点最大可用块大小）、物理页基址。**它借鉴了wuwenbin实现中的二叉树思想，但适配了ucore的Page结构。**

```c
struct buddy_system {
    unsigned size;          // 管理的总页面数，必须是2的幂
    unsigned *longest;      // 二叉树数组，记录每个节点对应的最大可用块大小
    struct Page *base;      // 内存区域的起始页面
};
```

这里的 `size` 是逻辑管理规模（向上取整到 2 的幂），`longest` 是长度为 `2*size-1` 的完全二叉树数组，`base` 指向 ucore 的 `Page` 数组的起始位置。树的叶子对应最小页，父节点记录左右子树的最大可用块，以便快速定位分配位置。

## 3  关键宏定义
**为了简化代码实现，我们借鉴了wuwenbin实现中的一些关键宏定义**，用简单宏来表达树的结构关系与常用判断，便于实现算法时保持代码直观清晰。

```c
#define LEFT_LEAF(index) ((index) * 2 + 1)
#define RIGHT_LEAF(index) ((index) * 2 + 2)
#define PARENT(index) (((index) + 1) / 2 - 1)
#define IS_POWER_OF_2(x) (!((x) & ((x) - 1)))
#define MAX(a, b) ((a) > (b) ? (a) : (b))
```

`LEFT_LEAF/RIGHT_LEAF/PARENT` 表示在完全二叉树上的索引关系，不需要额外指针；`IS_POWER_OF_2` 用位运算判断幂次；`MAX` 是父节点汇聚左右子状态时的取值规则。

## 4  pmm_manager结构体
我们在 .c 文件末尾将 buddy System 的各个操作函数以 `pmm_manager` 结构体的方式对外暴露。正如实验课中宫老师所讲，**操作系统设计者用了较为“tricky”的方式，让 C 也能实现类似 C++ 类实例化的效果**：每种新的物理内存分配算法在 .h 中都声明一个 `pmm_manager`，在 .c 末尾都实例化一个对象，像是在实例化一个“类”的对象一样。这使得替换不同算法只需切换这个实例，接口统一、扩展方便。
```c
const struct pmm_manager buddy_system_pmm_manager = {
    .name = "buddy_system_pmm_manager",
    .init = buddy_init,
    .init_memmap = buddy_init_memmap,
    .alloc_pages = buddy_alloc_pages,
    .free_pages = buddy_free_pages,
    .nr_free_pages = buddy_nr_free_pages,
    .check = buddy_check,
};
```

## 5  核心函数
接下来，我们展示每个函数关键算法对应的代码片段。**需要说明的是，由于本部分代码量较大，为节省篇幅，不再给出完整代码实现。完整代码及详细注释可参见项目的 GitHub 仓库。**

### 5.1  buddy_init：初始化状态占位
`buddy_init` 函数负责初始化Buddy System的数据结构。这个函数的设计思路是先进行简单的初始化，实际的详细初始化工作放在 `buddy_init_memmap` 中进行：

```c
static void
buddy_init(void) {
    buddy.size = 0;
    buddy.longest = NULL;
    buddy.base = NULL;
}
```

### 5.2  buddy_init_memmap：构建树、标记可用叶子、处理非幂次规模
这个函数是整个Buddy System的初始化核心，它根据给定的内存区域初始化Buddy System。我们需要先计算合适的树大小，并初始化所有节点的值。关键算法部分包括：

```c
// size向上取整到2的幂，并限制最大size防止数组越界
unsigned size = 1; while (size < n) size <<= 1;
if (size > 2048) size = 2048;

static unsigned tree[4096];           // 2*2048-1 = 4095
buddy.longest = tree; buddy.size = size; buddy.base = base;
memset(tree, 0, sizeof(tree));

unsigned node_size = size * 2;
for (int i = 0; i < 2 * size - 1; ++i) {
    if (IS_POWER_OF_2(i + 1)) node_size /= 2;
    buddy.longest[i] = node_size;
}

// 屏蔽超出实际页面数的叶子，并自底向上更新父节点
if (n < size) {
    for (unsigned i = n; i < size; i++) {
        unsigned index = i + size - 1;
        buddy.longest[index] = 0;
    }
    for (int i = size - 2; i >= 0; i--) {
        unsigned left = buddy.longest[LEFT_LEAF(i)];
        unsigned right = buddy.longest[RIGHT_LEAF(i)];
        buddy.longest[i] = MAX(left, right);
    }
}
```

这部分代码体现了Buddy System的核心设计思想：将内存划分为2的幂次大小的块，并使用完全二叉树来管理这些内存块。

### 5.3  buddy_alloc_pages：向下查找合适节点、标记分配、向上汇总
分配指定数量的页面是这个算法的核心功能。我们从根节点开始，递归查找合适大小的空闲块，找到后标记为已分配，并更新父节点的信息。关键算法代码：

```c
// 请求大小向上取整为2的幂
unsigned size = 1; while (size < n) size <<= 1;

// 从根向下选择能容纳size的子树
unsigned index = 0, node_size;
if (buddy.longest[index] < size) return NULL;
for (node_size = buddy.size; node_size != size; node_size /= 2) {
    if (buddy.longest[LEFT_LEAF(index)] >= size) index = LEFT_LEAF(index);
    else index = RIGHT_LEAF(index);
}

// 标记叶子已分配并计算页偏移
buddy.longest[index] = 0;
unsigned offset = (index + 1) * node_size - buddy.size;

// 向上更新父节点的最大可用块大小
while (index) {
    index = PARENT(index);
    buddy.longest[index] = MAX(buddy.longest[LEFT_LEAF(index)],
                               buddy.longest[RIGHT_LEAF(index)]);
}
```

这个算法展示了Buddy System的高效性，通过二叉树结构快速定位到合适的内存块。

### 5.4  buddy_free_pages：定位节点、标记空闲、伙伴合并
释放指定的页面时，我们需要找到对应的节点，标记为空闲，然后检查伙伴节点是否也空闲，如果是则合并。关键算法：

```c
// 根据页偏移定位叶子索引
unsigned offset = base - buddy.base;
unsigned node_size = 1, index = offset + buddy.size - 1;

// 向上查找“值为0的节点”，找到真实已分配块的叶子
for (; buddy.longest[index]; index = PARENT(index)) {
    node_size *= 2;
    if (index == 0) return; // 防御
}

// 标记空闲并尝试与伙伴合并
buddy.longest[index] = node_size;
while (index) {
    index = PARENT(index); node_size *= 2;
    unsigned L = buddy.longest[LEFT_LEAF(index)];
    unsigned R = buddy.longest[RIGHT_LEAF(index)];
    buddy.longest[index] = (L + R == node_size) ? node_size : MAX(L, R);
}
```

### 5.5  buddy_nr_free_pages：查询当前最大可分配块
这个函数返回当前可用的页面数，实现非常简单：

```c
static size_t
buddy_nr_free_pages(void) {
    if (buddy.longest == NULL) return 0;
    return buddy.longest[0];
}
```

## 6  测试用例
测试部分包含两个函数：`basic_check` 和 `buddy_check`。`basic_check` 我们直接复用了 `default_pmm.c` 的实现，而`buddy_check` 则是我们重点设计的专项测试（借助了大模型）。

### 6.1  basic_check
`basic_check` 函数直接复用了 `default_pmm.c` 中的实现，这是为了确保Buddy System能够通过ucore框架的基础测试。这个测试函数主要验证了基本的页面分配和释放功能，包括：
- 分配单个页面并验证分配成功
- 验证分配的页面地址在合理范围内
- 验证页面引用计数正确
- 测试页面释放功能
- 验证内存泄漏检查

​    这个基础测试确保了Buddy System与ucore框架的兼容性，为我们后续的专项测试打下了坚实的基础。

### 6.2  buddy_check函数
`buddy_check` 函数是我们专门为Buddy System设计的综合性测试函数，包含了200多行代码，全面测试了Buddy System的各种功能和边界情况。测试内容主要包括：
- **测试1：基本的2的幂次分配和释放** - 验证Buddy System能够正确分配和释放1、2、4、8页等2的幂次大小的内存块。
- **测试2：非2的幂次分配（向上取整）** - 测试请求3、5、6、7页时，系统能够正确向上取整到4、8、8、8页进行分配。
- **测试3：伙伴合并机制测试** - 验证当连续分配多个小内存块并释放时，系统能够正确合并伙伴块形成更大的空闲块。
- **测试4：连续分配和释放压力测试** - 通过连续分配和释放16个1页块，测试系统在压力情况下的稳定性和性能。
- **测试5：大块分配测试** - 测试分配16页大块的能力，验证系统对大内存请求的处理。
- **测试6：边界情况测试** - 包括测试分配1024页和512页等边界情况，验证系统对极端内存请求的处理。
- **测试7：碎片整理效果测试** - 通过有策略地分配和释放内存块，制造碎片化场景，然后测试系统是否仍能分配大块内存。
- **测试8：功能正确性验证** - 验证分配的页面地址是否在合理范围内，分配的页面地址是否唯一，确保没有地址冲突。
- **测试9：最终内存泄漏检查** - 比较测试前后的可用页面数，确保没有内存泄漏发生。

​    这些测试用例覆盖全面，输出带有明确的“成功/失败/警告”提示，基本上把 Buddy System 核心行为和边界都跑了一遍，且在 QEMU 下全部通过，确保了算法的正确性和健壮性。最终测试结果展示如下：
![buddy_system_res](./buddy_system_res.jpg)    **由于本部分代码量较大，为节省篇幅，在此不再给出代码实现。**

## 7  总结
总体上，这份设计以“先有数据结构与树宏，才能有初始化；先有初始化，才能保障分配/释放逻辑正确”为主线，算法核心参考了 wuwenbin 的极简实现，但我们在 ucore 的接口规范、边界安全（数组越界与非幂次规模）、测试充分性等方面做了落地适配。接口层通过 `pmm_manager` 的“类实例化”式结构统一暴露，既达到了替换简单、扩展友好的目标，也与课程框架保持一致。