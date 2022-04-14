// Physical memory allocator, for user processes,
// kernel stacks, page-table pages,
// and pipe buffers. Allocates whole 4096-byte pages.

#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "riscv.h"
#include "defs.h"
#define PA2REF(pa) (((uint64)pa - KERNBASE) / PGSIZE)

void freerange(void *pa_start, void *pa_end);

extern char end[]; // first address after kernel.
                   // defined by kernel.ld.

struct run {
  struct run *next;
};

struct {
  struct spinlock lock;
  struct run *freelist;
} kmem;

// LAB 6 with reference count to pa
int page_ref_count[(PHYSTOP - KERNBASE) / PGSIZE];

void increase_ref_count(void *pa) {
  if ((uint64) pa < KERNBASE || (uint64) pa >= PHYSTOP)
    panic("increase_ref_count: invalid pa");
  int index = PA2REF(pa);
  acquire(&kmem.lock);
  if (page_ref_count[index] <= 0)
    panic("increase_ref_count: ref_count <= 0");
  page_ref_count[index]++;
  release(&kmem.lock);
}

void
kinit()
{
  int i = 0;
  initlock(&kmem.lock, "kmem");
  for (i = 0; i < PA2REF(PHYSTOP); i++) {
    page_ref_count[i] = 1;
  }
  freerange(end, (void*)PHYSTOP);
}

void
freerange(void *pa_start, void *pa_end)
{
  char *p;
  p = (char*)PGROUNDUP((uint64)pa_start);
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    kfree(p);
}

// Free the page of physical memory pointed at by v,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    panic("kfree");

  // Lab 6: if ref count is not 0, decrease it
  uint64 ref_i = PA2REF(pa);
  acquire(&kmem.lock);
  if (page_ref_count[ref_i] > 0) {
    page_ref_count[ref_i]--;
    if (page_ref_count[ref_i] > 0) {
      release(&kmem.lock);
      return;
    }
  } else {
    panic("kfree: page_ref_count is 0");
  }
  release(&kmem.lock);

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);

  r = (struct run*)pa;

  acquire(&kmem.lock);
  r->next = kmem.freelist;
  kmem.freelist = r;
  release(&kmem.lock);
}

// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
  struct run *r;

  acquire(&kmem.lock);
  r = kmem.freelist;
  if(r)
    kmem.freelist = r->next;
  release(&kmem.lock);

  if(r) {
    // Lab 6: increase ref count
    page_ref_count[PA2REF(r)]++;
    memset((char*)r, 5, PGSIZE); // fill with junk
  }
  return (void*)r;
}
