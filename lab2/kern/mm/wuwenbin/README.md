看一下源码实现吧，首先是伙伴分配器的数据结构：

**struct** buddy2 {

  unsigned size;

  unsigned longest[1];

};

这里的成员size表明管理内存的总单元数目（测试用例中是32），成员longest就是二叉树的节点标记，表明所对应的内存块的空闲单位，**在下文中会分析这是整个算法中最精妙的设计。**此处数组大小为1表明这是可以向后扩展的（注：在GCC环境下你可以写成longest[0]，不占用空间，这里是出于可移植性考虑），我们在分配器初始化的buddy2_new可以看到这种用法。



**struct** buddy2* buddy2_new( **int** size ) {

  **struct** buddy2* self;

  unsigned node_size;

  **int** i;

  **if** (size < 1 || !IS_POWER_OF_2(size))

​    **return** **NULL**;

  self = (**struct** buddy2*)ALLOC( 2 * size * sizeof(unsigned));

  self->size = size;

  node_size = size * 2;

  **for** (i = 0; i < 2 * size - 1; ++i) {

​    **if** (IS_POWER_OF_2(i+1))

​      node_size /= 2;

​    self->longest[i] = node_size;

  }

  **return** self;

}

整个分配器的大小就是满二叉树节点数目，即所需管理内存单元数目的2倍。一个节点对应4个字节，longest记录了节点所对应的的内存块大小。



内存分配的alloc中，入参是分配器指针和需要分配的大小，返回值是内存块索引。alloc函数首先将size调整到2的幂大小，并检查是否超过最大限度。然后进行适配搜索，深度优先遍历，当找到对应节点后，**将其longest标记为0，即分离适配的块出来，**并转换为内存块索引offset返回，依据二叉树排列序号，比如内存总体大小32，我们找到节点下标[8]，内存块对应大小是4，则offset = (8+1)*4-32 = 4，那么分配内存块就从索引4开始往后4个单位。

**int** buddy2_alloc(**struct** buddy2* self, **int** size) {

  unsigned index = 0;

  unsigned node_size;

  unsigned offset = 0;

  **if** (self==**NULL**)

​    **return** -1;

  **if** (size <= 0)

​    size = 1;

  **else** **if** (!IS_POWER_OF_2(size))

​    size = fixsize(size);

  **if** (self->longest[index] < size)

​    **return** -1;

  **for**(node_size = self->size; node_size != size; node_size /= 2 ) {

​    **if** (self->longest[LEFT_LEAF(index)] >= size)

​      index = LEFT_LEAF(index);

​    **else**

​      index = RIGHT_LEAF(index);

  }

  self->longest[index] = 0;

  offset = (index + 1) * node_size - self->size;

  **while** (index) {

​    index = PARENT(index);

​    self->longest[index] =

​      MAX(self->longest[LEFT_LEAF(index)], self->longest[RIGHT_LEAF(index)]);

  }

  **return** offset;

}

在函数返回之前需要回溯，因为小块内存被占用，大块就不能分配了，比如下标[8]标记为0分离出来，那么其父节点下标[0]、[1]、[3]也需要相应大小的分离。**将它们的longest进行折扣计算，取左右子树较大值，**下标[3]取4，下标[1]取8，下标[0]取16，表明其对应的最大空闲值。



在内存释放的free接口，我们只要传入之前分配的内存地址索引，并确保它是有效值。之后就跟alloc做反向回溯，从最后的节点开始一直往上找到longest为0的节点，即当初分配块所适配的大小和位置。**我们将longest恢复到原来满状态的值。继续向上回溯，检查是否存在合并的块，依据就是左右子树longest的值相加是否等于原空闲块满状态的大小，如果能够合并，就将父节点longest标记为相加的和**（多么简单！）。

**void** buddy2_free(**struct** buddy2* self, **int** offset) {

  unsigned node_size, index = 0;

  unsigned left_longest, right_longest;

  assert(self && offset >= 0 && offset < size);

  node_size = 1;

  index = offset + self->size - 1;

  **for** (; self->longest[index] ; index = PARENT(index)) {

​    node_size *= 2;

​    **if** (index == 0)

​      **return**;

  }

  self->longest[index] = node_size;

  **while** (index) {

​    index = PARENT(index);

​    node_size *= 2;

​    left_longest = self->longest[LEFT_LEAF(index)];

​    right_longest = self->longest[RIGHT_LEAF(index)];

​    **if** (left_longest + right_longest == node_size)

​      self->longest[index] = node_size;

​    **else**

​      self->longest[index] = MAX(left_longest, right_longest);

  }

}

上面两个成对alloc/free接口的时间复杂度都是O(logN)，保证了程序运行性能。然而这段程序设计的独特之处就在于**使用加权来标记内存空闲状态，而不是一般的有限状态机，实际上longest既可以表示权重又可以表示状态，状态机就毫无必要了，所谓“少即是多”嘛！**反观cloudwu的实现，将节点标记为UNUSED/USED/SPLIT/FULL四个状态机，反而会带来额外的条件判断和管理实现，而且还不如数值那样精确。从逻辑流程上看，wuwenbin的实现简洁明了如同教科书一般，特别是左右子树的走向，内存块的分离合并，块索引到节点下标的转换都是一步到位，不像cloudwu充斥了大量二叉树的深度和长度的间接计算，让代码变得晦涩难读，这些都是longest的功劳。**一个“极简”的设计往往在于你想不到的突破常规思维的地方。**



这份代码唯一的缺陷就是longest的大小是4字节，内存消耗大。但[cloudwu的博客](http://blog.codingnow.com/2011/12/buddy_memory_allocation.html)上有人提议用logN来保存值，这样就能实现uint8_t大小了，**看，又是一个“极简”的设计！**

说实话，很难在网上找到比这更简约更优雅的buddy system实现了——至少在Google上如此。