# SLUB 内存分配器（简化版）设计说明

## 目标与背景
- 在页级分配（buddy system）之上提供对象级分配，提升小对象分配效率。
- **保持与现有 `pmm_manager` 接口风格一致，方便在 `pmm.c` 中切换管理器。**
- 支持常见对象大小：`32B, 64B, 128B, 256B, 512B, 1024B, 2048B, 4096B`。
- **详情见实验报告第二个challenge部分！！**

## 两层架构
- 第一层（页级）：复用 buddy system 的 `alloc_pages/free_pages` 完成页块管理。
- 第二层（对象级）：在页内划分固定大小对象，维护空闲对象链表，实现快速分配与释放。

## 关键数据结构
- `kmem_cache`：每种对象大小一个缓存，维护两个 slab 列表：
  - `slabs_partial`：尚有空闲对象的 slab 列表；
  - `slabs_full`：已满 slab 列表。
- `slub_slab`：一个 slab 对应一页（教学简化），包含：
  - `page`：该 slab 的起始页；
  - `free_list`：对象空闲链表；
  - `inuse`：已分配对象数量；
  - `objsize`、`capacity`：对象大小与可容纳总数。

## 对象划分与空闲链
- 每个 slab 是一页，页头存放 `slub_slab` 元数据；剩余空间按对象大小整齐切分。
- 每个对象的开头保存一个 `list_entry_t` 作为空闲链节点（简化实现）。
- 分配时从 `free_list` 取一个节点；释放时将节点重新插回链表。

## 缓存选择策略
- 请求大小向上匹配到最近的 size-class（如 `70B -> 128B`）。
- 超过 `4096B` 的请求不走 SLUB，直接回退到页级分配。

## 交互边界
- `slub_pmm_manager.alloc_pages/free_pages/nr_free_pages` 委托给 buddy，保持与其他 pmm 的接口一致。
- 对象接口：在实现文件中提供 `slub_alloc(size)` / `slub_free(ptr, size)`，用于测试。

## 简化与取舍
- 没有做 slab 回收（空 slab 保留在 partial 列以便后续复用）。
- 不做对象头记录 cache 索引（释放时由调用者传入 size）；
  - 若需要严格校验，通常在对象头写入 cache 信息
- 每个 slab 仅用一页（Linux SLUB 实际可多页并包含更复杂的 cpu/partial 管理）。

## 正确性测试要点
- 基础页级检查：复用 buddy 的分配/释放基础测试。
- size-class 覆盖：每个大小都能分配对象；满页后转入 `slabs_full`；继续分配触发新 slab。
- 列表状态：释放后 `slabs_partial` 至少有一个节点；再分配能复用释放对象。
- 压力测试：大量小对象的分配/释放，验证复用与稳定性。
- 页级回退：大对象（>4096B）使用页级分配，分配后能释放。

## 与 Linux SLUB 的关系
- 借鉴其“缓存+slab+对象”的核心思想与两个层次的设计。
- 实现细节简化，不涉及 cpu 本地缓存、partial 对象集、对象校验、红黑树等。

## 使用方式
- 在 `pmm.c` 中将 `pmm_manager = &slub_pmm_manager;`，其余逻辑保持不变。
- 对象测试调用 `slub_alloc(size)` / `slub_free(ptr, size)`。
- 页级分配仍可通过 `alloc_pages/free_pages` 进行，兼容其他模块。

## 潜在改进
- 在对象头记录 cache 索引，避免释放时需要传 size。
- slab 空页回收策略，减少内存占用峰值。
- 支持多页 slab，提高大对象的空间局部性与管理灵活性。
- 增加校验与防御性编程，提高健壮性（如越界检查、双重释放发现）。
