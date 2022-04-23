// Physical memory allocator, for user processes,
// kernel stacks, page-table pages,
// and pipe buffers. Allocates whole 4096-byte pages.

#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "riscv.h"
#include "defs.h"

void freerange(void *pa_start, void *pa_end);

extern char end[]; // first address after kernel.
                   // defined by kernel.ld.

struct run {
  struct run *next;
};

struct {
  struct spinlock lock[NCPU];
  struct run *freelist[NCPU];
} kmem;

void
kinit()
{
  int i;
  for (i = 0; i < NCPU; i++) {
    kmem.freelist[i] = 0;
    initlock(&kmem.lock[i], "kmem");
  }
  freerange(end, (void*)PHYSTOP);
}

void
kfree_init(void *pa, int hartid)
{
struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);

  r = (struct run*)pa;

  acquire(&kmem.lock[hartid]);
  r->next = kmem.freelist[hartid];
  kmem.freelist[hartid] = r;
  release(&kmem.lock[hartid]);
}

void
freerange(void *pa_start, void *pa_end)
{
  int i = 0;
  char *p;
  p = (char*)PGROUNDUP((uint64)pa_start);
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE) {
    kfree_init(p, i % NCPU);
    ++i;
  }
}



// Free the page of physical memory pointed at by v,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
  struct run *r;
  int hartid;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);

  r = (struct run*)pa;

  // acquire(&kmem.lock);
  // r->next = kmem.freelist;
  // kmem.freelist = r;
  // release(&kmem.lock);

  push_off();
  hartid = cpuid();
  acquire(&kmem.lock[hartid]);
  r->next = kmem.freelist[hartid];
  kmem.freelist[hartid] = r;
  release(&kmem.lock[hartid]);
  pop_off();
}

// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
  // struct run *r;

  // acquire(&kmem.lock);
  // r = kmem.freelist;
  // if(r)
  //   kmem.freelist = r->next;
  // release(&kmem.lock);

  // if(r)
  //   memset((char*)r, 5, PGSIZE); // fill with junk
  // return (void*)r;

    // struct run *r;

  int i;
  push_off();
  struct run *r;
  int hartid = cpuid();
  acquire(&kmem.lock[hartid]);
  r = kmem.freelist[hartid];
  if(r) {
    kmem.freelist[hartid] = r->next;
    release(&kmem.lock[hartid]);
    memset((char*)r, 5, PGSIZE); // fill with junk
  } else {
    release(&kmem.lock[hartid]);
    for (i = 0; i < NCPU; i++) {
      if (i == hartid)
        continue;
      acquire(&kmem.lock[i]);
      r = kmem.freelist[i];
      if (r) {
        kmem.freelist[i] = r->next;
        release(&kmem.lock[i]);
        memset((char*)r, 5, PGSIZE); // fill with junk
        break;
      }
      release(&kmem.lock[i]);
    }
  }
  pop_off();
  return (void*)r;
}
