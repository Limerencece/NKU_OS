/* 在 SLUB 算法中，分配器在页级分配（由 buddy system 管理）之上，
   再实现对象级分配（由 SLUB 管理），形成两层架构的高效内存分配。
   第一层：调用 buddy system 的 alloc_pages()/free_pages() 进行页级分配；
   第二层：在每页中按固定对象大小划分为若干对象，进行快速小对象分配和回收。
   
   参考 Linux 的 SLUB 设计思想（mm/slub.c），在 uCore 框架内实现一个简化版，
   支持常见对象大小（32B、64B、128B、256B、512B、1024B、2048B、4096B）。
   
   在 alloc_pages(n) 中：当 n==1 且 size<=PGSIZE 时走对象级分配；当 n>1 或 size>PGSIZE 时退回页级分配。
   简化的点：仅实现固定大小对象缓存（kmem_cache），每个缓存管理若干 slab（单页或多页），并维护空闲对象的链表。
*/

// LAB2 CHALLENGE 2: /*解子萱 2312585 、崔颖欣 2311136 、范鼎辉 2312326*/
#include <pmm.h>
#include <list.h>
#include <string.h>
#include <slub_pmm.h>
#include <buddy_system_pmm.h>
#include <stdio.h>

// 简化版的SLUB 的核心数据结构：cache（每种对象大小一个）、slab（从 buddy 系统拿来的页），以及对象空闲链。

typedef struct slub_slab {
    struct Page *page;         // 这个 slab 对应的起始页
    list_entry_t link;         // 链接到 cache 的 slab 列表
    list_entry_t free_list;    // slab 内部的空闲对象链表
    unsigned int inuse;        // 当前已分配对象数
    unsigned int objsize;      // 对象大小（字节）
    unsigned int capacity;     // 这个 slab 可以容纳的对象总数
} slub_slab_t;

typedef struct kmem_cache {
    const char *name;          // 方便调试的名字
    unsigned int objsize;      // 对象大小
    list_entry_t slabs_partial; // 还有空位的 slab 列表
    list_entry_t slabs_full;    // 已满的 slab 列表
    unsigned int slab_pages;    // 每个 slab 占用的页数（简化为1）
} kmem_cache_t;

// 我们支持的对象大小集合 一个对应一个 cache
static const unsigned int slub_sizes[] = {32, 64, 128, 256, 512, 1024, 2048, 4096};
#define SLUB_SIZE_CLASS_COUNT (sizeof(slub_sizes)/sizeof(slub_sizes[0]))

// 为每种大小建立一个 cache
static kmem_cache_t caches[SLUB_SIZE_CLASS_COUNT];

// 计算每页能放几个对象 没考虑元数据占的空间！不要这块了
static inline unsigned calc_capacity(unsigned objsize) {
    if (objsize == 0) return 0;
    return PGSIZE / objsize; //对象数
}

// 把对象指针挂到 list_entry_t：用对象地址作为 list_entry_t 存储
typedef struct obj_node {
    list_entry_t link; // 链表节点在对象头，裸内存当节点用）
} obj_node_t;

// 初始化一个 slab，来自 buddy 系统分配的一页
static slub_slab_t *slab_create(kmem_cache_t *cache) {
    struct Page *page = buddy_system_pmm_manager.alloc_pages(cache->slab_pages);
    if (page == NULL) return NULL;

    // 为 slab 元数据使用这页的起始地址的一小块空间（不再另开页）
    void *page_va = (void *)(page2pa(page) + va_pa_offset); //用 page2pa + va_pa_offset = kva 拿到这块页的内核虚拟地址
    memset(page_va, 0, PGSIZE * cache->slab_pages); //清零整页内容。

    slub_slab_t *slab = (slub_slab_t *)page_va; 
    slab->page = page;            //把 slub_slab_t 元数据直接放在 slab 页的开头(真实 Linux SLUB 把元数据放其它地方)
    list_init(&slab->link);
    list_init(&slab->free_list);
    slab->inuse = 0;
    slab->objsize = cache->objsize;
    unsigned total = PGSIZE * cache->slab_pages;
    unsigned usable = total - sizeof(slub_slab_t);
    slab->capacity = usable / cache->objsize;       //刚刚写错的函数在这重写了一边，考虑元数据占的空间，向下整除

    // 切分对象，从 slab 元数据之后开始，每个对象紧跟在之前的对象后面
    // 真实 SLUB 会把元数据放在 per-slab 外部或者在对象末尾等      //这里sizeof(slub_slab_t)是上面的元数据结构体的大小52字节
                                                            // 编译器会在末尾自动填充 padding，把 52 向上对齐到 56 或 64
    unsigned char *obj_base = (unsigned char *)page_va + sizeof(slub_slab_t);

    for (unsigned i = 0; i < slab->capacity; i++) {
        obj_node_t *node = (obj_node_t *)(obj_base + i * cache->objsize);
        list_add(&slab->free_list, &node->link);
    }

    return slab;
}

// 从 slab 分配一个对象
static void *slab_alloc_obj(slub_slab_t *slab) {
    if (list_empty(&slab->free_list)) return NULL;
    list_entry_t *le = list_next(&slab->free_list);
    list_del(le);
    slab->inuse++;
    // le 的地址即对象地址
    return (void *)le;
}

// 释放对象回到 slab
static void slab_free_obj(slub_slab_t *slab, void *obj) {
    obj_node_t *node = (obj_node_t *)obj;
    list_add(&slab->free_list, &node->link);
    if (slab->inuse > 0) slab->inuse--;
}

// 根据 size 选择合适的 cache（向上取最近的 size class）
static kmem_cache_t *slub_select_cache(size_t size) {
    for (unsigned i = 0; i < SLUB_SIZE_CLASS_COUNT; i++) {
        if (size <= slub_sizes[i]) return &caches[i];
    }
    return NULL; // 超过 4096B 的对象不适用 SLUB（交给页级）
}

// 初始化所有 size 的 cache
static void slub_init_caches(void) {
    for (unsigned i = 0; i < SLUB_SIZE_CLASS_COUNT; i++) {
        caches[i].name = "slub";
        caches[i].objsize = slub_sizes[i];
        list_init(&caches[i].slabs_partial);
        list_init(&caches[i].slabs_full);
        caches[i].slab_pages = (slub_sizes[i] == 2048) ? 2 : 1; // 2048B 使用双页 slab
    }
}

// 以下实现 pmm_manager 风格一致的接口，以便在 pmm.c 中切换到 SLUB

static void slub_init(void) {
    // 初始化 SLUB 自己的数据结构
    slub_init_caches();
}

static void slub_init_memmap(struct Page *base, size_t n) {
    // 交给 buddy 的 init_memmap，保证页级空间建立
    buddy_system_pmm_manager.init_memmap(base, n);
}

// 分配 n 页：为了和 pmm 接口兼容，这里保留页级语义；
// 若用户通过对象接口分配（例如 alloc_pages(1) 但想要对象大小），我们提供一个“对象模式”的入口：
// 在测试和文档里会说明，调用 slub_alloc(size) 来拿对象；pmm 的 alloc_pages 仍表示页。
static struct Page *slub_alloc_pages(size_t n) {
    // 直接委托给 buddy 系统，保持页级分配行为
    return buddy_system_pmm_manager.alloc_pages(n);
}

static void slub_free_pages(struct Page *base, size_t n) {
    // 直接委托给 buddy 系统，保持页级释放行为
    buddy_system_pmm_manager.free_pages(base, n);
}

static size_t slub_nr_free_pages(void) {
    // 返回 buddy 的统计（页级）
    return buddy_system_pmm_manager.nr_free_pages();
}

// 对象分配接口，不改变 pmm_manager 的签名，测试中直接调用
static void *slub_alloc(size_t size) {
    kmem_cache_t *cache = slub_select_cache(size);
    if (cache == NULL || cache->objsize == PGSIZE) {
        // 对象太大，直接分配整页（或多页）。这里返回页的虚拟地址。
        struct Page *pg = buddy_system_pmm_manager.alloc_pages((size + PGSIZE - 1)/PGSIZE);
        if (!pg) return NULL;
        return (void *)(page2pa(pg) + va_pa_offset);
    }

    // 尝试在 partial 列表找到空位对象
    list_entry_t *le = &cache->slabs_partial;
    while ((le = list_next(le)) != &cache->slabs_partial) {
        // 把 list 节点本身当做指向 slab 的节点，改为直接获取 slab 容器
        // 在创建 slab 时使用 slab->link 作为链入节点，因此这里需要用 to_struct
        slub_slab_t *slab = to_struct(le, slub_slab_t, link);
        void *obj = slab_alloc_obj(slab);
        if (obj != NULL) {
            // 如果分配后满了，移到 full 列表
            if (slab->inuse == slab->capacity) {
                list_del(&slab->link);
                list_add(&cache->slabs_full, &slab->link);
            }
            return obj;
        }
    }

    // 没有可用对象就新建一个 slab
    slub_slab_t *slab = slab_create(cache);
    if (slab == NULL) return NULL;
    // 新 slab 加入 partial 列表
    list_add(&cache->slabs_partial, &slab->link);
    void *obj = slab_alloc_obj(slab);
    if (obj == NULL) return NULL;
    if (slab->inuse == slab->capacity) {
        list_del(&slab->link);
        list_add(&cache->slabs_full, &slab->link);
    }
    return obj;
}

static void old_slub_free(void *obj, size_t size) {
    kmem_cache_t *cache = slub_select_cache(size);
    if (cache == NULL) {
        // 当 size>4096 或自定义大对象，调用方需使用 slub_free_pages；这里无法安全定位页
        return;
    }
    // 根据对象地址定位所属 slab
    uintptr_t obj_pa = (uintptr_t)obj - va_pa_offset;
    uintptr_t slab_base_pa = ROUNDDOWN(obj_pa, PGSIZE * cache->slab_pages);
    slub_slab_t *slab = (slub_slab_t *)(slab_base_pa + va_pa_offset);
    slab_free_obj(slab, obj);
    // 如果 slab 从 full 变成 partial，需要移动列表
    if (slab->inuse + 1 == slab->capacity) {
        // 原来是满的，刚释放后不满
        list_del(&slab->link);
        list_add(&cache->slabs_partial, &slab->link);
    }
    // 当 slab 变为空，可以考虑回收页
}

static void slub_free(void *obj, size_t size) {
    kmem_cache_t *cache = slub_select_cache(size);
    if (cache == NULL) {
        //cprintf("[SLUB][free] size=%u no cache (page path)\n", (unsigned)size);
        return;
    }

    uintptr_t obj_pa = (uintptr_t)obj - va_pa_offset;
    uintptr_t slab_base_pa = ROUNDDOWN(obj_pa, PGSIZE * cache->slab_pages);
    slub_slab_t *slab = (slub_slab_t *)(slab_base_pa + va_pa_offset);

    // ★ 修复：基本校验，防止 slab_base_pa 定位错误（多页 slab 非对齐时）
    if (slab->capacity == 0 || slab->objsize != cache->objsize) {
        //cprintf("[SLUB][free][WARN] invalid slab detected: obj_pa=%lx slab_base_pa=%lx cap=%u objsize=%u(cache=%u)\n",
        //        obj_pa, slab_base_pa, slab->capacity, slab->objsize, cache->objsize);
        return; // 防止链表破坏或死循环
    }

    //cprintf("[SLUB][free] enter: size=%u obj=%lx obj_pa=%lx slab_base_pa=%lx slab=%lx "
    //        "inuse(before)=%u cap=%u slab_pages=%u\n",
    //        (unsigned)size, (uintptr_t)obj, obj_pa, slab_base_pa, (uintptr_t)slab,
    //        slab->inuse, slab->capacity, cache->slab_pages);

    slab_free_obj(slab, obj);
    //cprintf("[SLUB][free] after slab_free_obj: inuse=%u (cap=%u)\n",
            //slab->inuse, slab->capacity);

    if (slab->inuse + 1 == slab->capacity) {
        //cprintf("[SLUB][free] will move FULL->PARTIAL: link=%lx full_head=%lx partial_head=%lx\n",
                //(uintptr_t)&slab->link, (uintptr_t)&cache->slabs_full, (uintptr_t)&cache->slabs_partial);
        //cprintf("[SLUB][free] link.prev=%lx link.next=%lx (before list_del)\n",
                //(uintptr_t)slab->link.prev, (uintptr_t)slab->link.next);

        // 在移动前再做一次基本 sanity check
        if (slab->link.prev == NULL || slab->link.next == NULL) {
            //cprintf("[SLUB][free][WARN] list link broken, skip move.\n");
        } else {
            list_del(&slab->link);
            //cprintf("[SLUB][free] after list_del, link.prev=%lx link.next=%lx, now list_add(partial)\n",
                    //(uintptr_t)slab->link.prev, (uintptr_t)slab->link.next);
            list_add(&cache->slabs_partial, &slab->link);
            //cprintf("[SLUB][free] after list_add(partial)\n");
        }
    }

    //cprintf("[SLUB][free] exit\n");
}

// 基础检查与 SLUB 专属检查
static void basic_check(void) {
    // 复用 buddy 的基础页分配检查
    struct Page *p0, *p1, *p2;
    p0 = p1 = p2 = NULL;
    assert((p0 = buddy_system_pmm_manager.alloc_pages(1)) != NULL);
    assert((p1 = buddy_system_pmm_manager.alloc_pages(1)) != NULL);
    assert((p2 = buddy_system_pmm_manager.alloc_pages(1)) != NULL);
    buddy_system_pmm_manager.free_pages(p0, 1);
    buddy_system_pmm_manager.free_pages(p1, 1);
    buddy_system_pmm_manager.free_pages(p2, 1);
}

static int list_count(list_entry_t *head) {
    int cnt = 0;
    list_entry_t *le = head;
    while ((le = list_next(le)) != head) cnt++;
    return cnt;
}

static void old_slub_check(void) {
    basic_check();

    // 对象分配测试：覆盖所有 size class，并验证 partial/full 列表移动与跨页扩容
    size_t sizes[] = {32,64,128,256,512,1024,2048,4096};
    for (int si = 0; si < (int)(sizeof(sizes)/sizeof(sizes[0])); si++) {
        kmem_cache_t *cache = slub_select_cache(sizes[si]);
        assert(cache != NULL);

        // 4096B 特例：对象等于一页，走页级路径验证回退逻辑
        if (cache->objsize == PGSIZE) {
            void *ptr = slub_alloc(sizes[si]);
            assert(ptr != NULL);
            uintptr_t page_pa = ROUNDDOWN((uintptr_t)ptr - va_pa_offset, PGSIZE);
            struct Page *pg = pa2page(page_pa);
            buddy_system_pmm_manager.free_pages(pg, 1);
            continue;
        }

        // 新建一个 slab：分配到第一个对象时，partial 应为 1
        void *first = slub_alloc(sizes[si]);
        assert(first != NULL);
        assert(list_count(&cache->slabs_partial) >= 1);

        // 计算单 slab 能装的对象个数（与实现保持一致）
        unsigned cap = ((PGSIZE * cache->slab_pages) - sizeof(slub_slab_t)) / cache->objsize;

        // 再分配 cap-1 个对象，使该 slab 充满
        for (unsigned i = 1; i < cap; i++) {
            assert(slub_alloc(sizes[si]) != NULL);
        }
        // 满了之后，partial 至少减少，full 至少增加
        assert(list_count(&cache->slabs_full) >= 1);

        // 继续分配一个对象，触发第二个 slab 的创建
        void *extra = slub_alloc(sizes[si]);
        if (extra != NULL) {
            uintptr_t pa_first = ROUNDDOWN((uintptr_t)first - va_pa_offset, PGSIZE);
            uintptr_t pa_extra = ROUNDDOWN((uintptr_t)extra - va_pa_offset, PGSIZE);
            // 预期来自不同页（不同 slab）
            assert(pa_first != pa_extra);
        }

        // 释放一些对象，观察 partial 列表出现
        slub_free(first, sizes[si]);
        assert(list_count(&cache->slabs_partial) >= 1);
    }

    // 大量 64B 对象分配与释放，验证复用
    const int N = 1024;
    void *arr[N];
    for (int i = 0; i < N; i++) {
        arr[i] = slub_alloc(64);
        assert(arr[i] != NULL);
    }
    for (int i = 0; i < N; i += 2) {
        slub_free(arr[i], 64);
    }
    for (int i = 0; i < N/2; i++) {
        void *o = slub_alloc(64);
        assert(o != NULL);
    }

    // 大对象回退测试：>4096 的请求退回页级
    struct Page *big = slub_alloc_pages(2); // 2 页作为大对象块
    assert(big != NULL);
    slub_free_pages(big, 2);

    cprintf("slub_check() completed.\n");
}

static void slub_check(void) {
    cprintf("[SLUB] === slub_check() begin ===\n");

    basic_check();
    cprintf("[SLUB] basic_check() passed.\n");

    size_t sizes[] = {32,64,128,256,512,1024,2048,4096};
    for (int si = 0; si < (int)(sizeof(sizes)/sizeof(sizes[0])); si++) {
        kmem_cache_t *cache = slub_select_cache(sizes[si]);
        assert(cache != NULL);
        cprintf("[SLUB] size=%u selected cache: objsize=%u, slab_pages=%u\n",
                (unsigned)sizes[si], cache->objsize, cache->slab_pages);

        // 4096B 特例：对象等于一页，走页级路径验证回退逻辑
        if (cache->objsize == PGSIZE) {
            cprintf("[SLUB] 4096B special case test begin\n");
            void *ptr = slub_alloc(sizes[si]);
            assert(ptr != NULL);
            uintptr_t page_pa = ROUNDDOWN((uintptr_t)ptr - va_pa_offset, PGSIZE);
            struct Page *pg = pa2page(page_pa);
            cprintf("[SLUB] 4096B alloc: va=%lx pa=%lx page_pa=%lx\n",
                    (uintptr_t)ptr, (uintptr_t)ptr - va_pa_offset, page_pa);
            buddy_system_pmm_manager.free_pages(pg, 1);
            cprintf("[SLUB] 4096B free done\n");
            continue;
        }

        cprintf("[SLUB] new cache test for size=%u begin\n", (unsigned)sizes[si]);

        // 新建一个 slab：分配到第一个对象时，partial 应为 1
        void *first = slub_alloc(sizes[si]);
        assert(first != NULL);
        cprintf("[SLUB] first alloc: va=%lx pa=%lx page_pa=%lx | partial=%d full=%d\n",
                (uintptr_t)first,
                (uintptr_t)first - va_pa_offset,
                ROUNDDOWN((uintptr_t)first - va_pa_offset, PGSIZE),
                list_count(&cache->slabs_partial),
                list_count(&cache->slabs_full));
        assert(list_count(&cache->slabs_partial) >= 1);

        unsigned cap = ((PGSIZE * cache->slab_pages) - sizeof(slub_slab_t)) / cache->objsize;
        cprintf("[SLUB] capacity per slab = %u objects\n", cap);

        // 再分配 cap-1 个对象，使该 slab 充满
        for (unsigned i = 1; i < cap; i++) {
            void *obj = slub_alloc(sizes[si]);
            assert(obj != NULL);
            if (i == cap / 2 || i == cap - 1) {
                uintptr_t pa = (uintptr_t)obj - va_pa_offset;
                uintptr_t page_pa = ROUNDDOWN(pa, PGSIZE);
                cprintf("[SLUB] alloc i=%u: va=%lx pa=%lx page_pa=%lx | partial=%d full=%d\n",
                        i, (uintptr_t)obj, pa, page_pa,
                        list_count(&cache->slabs_partial),
                        list_count(&cache->slabs_full));
            }
        }
        cprintf("[SLUB] after fill: partial=%d full=%d\n",
                list_count(&cache->slabs_partial),
                list_count(&cache->slabs_full));
        assert(list_count(&cache->slabs_full) >= 1);

        // 继续分配一个对象，触发第二个 slab 的创建
        void *extra = slub_alloc(sizes[si]);
        if (extra != NULL) {
            uintptr_t pa_first = ROUNDDOWN((uintptr_t)first - va_pa_offset, PGSIZE);
            uintptr_t pa_extra = ROUNDDOWN((uintptr_t)extra - va_pa_offset, PGSIZE);
            cprintf("[SLUB] extra alloc: va=%lx pa=%lx page_pa=%lx | first_page_pa=%lx\n",
                    (uintptr_t)extra,
                    (uintptr_t)extra - va_pa_offset,
                    pa_extra, pa_first);
            assert(pa_first != pa_extra);
        }

        // 释放一些对象，观察 partial 列表出现
        slub_free(first, sizes[si]);
        cprintf("[SLUB] after free first: partial=%d full=%d\n",
                list_count(&cache->slabs_partial),
                list_count(&cache->slabs_full));
        //assert(list_count(&cache->slabs_partial) >= 1);
        cprintf("[SLUB] before count(partial) after free\n");
        int pc = list_count(&cache->slabs_partial);
        cprintf("[SLUB] partial count=%d\n", pc);
        assert(pc >= 1);
        cprintf("[SLUB] size=%u test done.\n", (unsigned)sizes[si]);
    }

    // 大量 64B 对象分配与释放，验证复用
    cprintf("[SLUB] bulk alloc/free reuse test (size=64B)\n");
    const int N = 1024;
    void *arr[N];
    for (int i = 0; i < N; i++) {
        arr[i] = slub_alloc(64);
        assert(arr[i] != NULL);
        if (i < 5) {
            uintptr_t pa = (uintptr_t)arr[i] - va_pa_offset;
            cprintf("[SLUB] arr[%d]: va=%lx pa=%lx page_pa=%lx\n",
                    i, (uintptr_t)arr[i], pa, ROUNDDOWN(pa, PGSIZE));
        }
    }

    kmem_cache_t *cache64 = slub_select_cache(64);
    if (cache64)
        cprintf("[SLUB] after alloc: partial=%d full=%d\n",
                list_count(&cache64->slabs_partial),
                list_count(&cache64->slabs_full));

    for (int i = 0; i < N; i += 2)
        slub_free(arr[i], 64);

    if (cache64)
        cprintf("[SLUB] after free half: partial=%d full=%d\n",
                list_count(&cache64->slabs_partial),
                list_count(&cache64->slabs_full));

    for (int i = 0; i < N / 2; i++) {
        void *o = slub_alloc(64);
        assert(o != NULL);
        if (i < 3) {
            uintptr_t pa = (uintptr_t)o - va_pa_offset;
            cprintf("[SLUB] reuse[%d]: va=%lx pa=%lx page_pa=%lx\n",
                    i, (uintptr_t)o, pa, ROUNDDOWN(pa, PGSIZE));
        }
    }

    if (cache64)
        cprintf("[SLUB] after reuse: partial=%d full=%d\n",
                list_count(&cache64->slabs_partial),
                list_count(&cache64->slabs_full));

    // 大对象回退测试：>4096 的请求退回页级
    cprintf("[SLUB] big pages (2-page) fallback test begin\n");
    struct Page *big = slub_alloc_pages(2);
    assert(big != NULL);
    uintptr_t big_pa = page2pa(big);
    uintptr_t big_va = big_pa + va_pa_offset;
    cprintf("[SLUB] big pages alloc: va=%lx pa=%lx\n", big_va, big_pa);
    slub_free_pages(big, 2);
    cprintf("[SLUB] big pages free done\n");

    cprintf("[SLUB] === slub_check() completed ===\n");
}


const struct pmm_manager slub_pmm_manager = {
    .name = "slub_pmm_manager",
    .init = slub_init,
    .init_memmap = slub_init_memmap,
    .alloc_pages = slub_alloc_pages,
    .free_pages = slub_free_pages,
    .nr_free_pages = slub_nr_free_pages,
    .check = slub_check,
};