#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "spinlock.h"
#include "proc.h"
#include "sleeplock.h"
#include "fs.h"
#include "file.h"
#include "fcntl.h"


int mmaphandler(void) {

  int i;
  uint64 pfva = r_stval();
  struct proc *p = myproc();
  if (pfva >= p->sz || pfva < p->trapframe->sp) {
    return -1;
  }
  int found_vma = 0;
  struct vma *vma_p;
  for (i = 0; i < 16; i++) {
    if (p->vmas[i].occupied == 0) {
      continue;
    }
    if (pfva >= p->vmas[i].addr && pfva < p->vmas[i].addr + p->vmas[i].length) {
      found_vma = 1;
      vma_p = &p->vmas[i];
      break;
    }
  }
  if (!found_vma) {
    return -1;
  }

  pte_t *pte = kalloc();
  if (pte == 0) {
    return -1;
  }
  int perm = PTE_U;
  if (vma_p->prot & PROT_READ) {
    perm |= PTE_R;
  }
  if (vma_p->prot & PROT_WRITE) {
    perm |= PTE_W;
  }
  memset(pte, 0, PGSIZE);
  ilock(vma_p->file->ip);
  pfva = PGROUNDDOWN(pfva);
  readi(vma_p->file->ip, 0, (uint64) pte, pfva - vma_p->addr, PGSIZE);
  iunlock(vma_p->file->ip);
  if (mappages(p->pagetable, pfva, PGSIZE, (uint64) pte, perm) != 0) {
    kfree(pte);
    return -1;
  }
  vma_p->mapped_addr = pfva;
  // printf("mmaphandler: mapped %p\n", pfva);
  return 0;
}

uint64 
sys_mmap(void) {
  uint64 addr;
  int len, prot, flags, fd, off, i;
  uint64 mapped_addr = 0xffffffffffffffff;
  struct proc *p;
  struct vma *vma_p;
  if (argaddr(0, &addr) < 0 || argint(1, &len) < 0 || argint(2, &prot) < 0 || 
      argint(3, &flags) < 0 || argint(4, &fd) < 0 || argint(5, &off) < 0) {
    return -1;
  }

  p = myproc();

  if (!p->ofile[fd]->writable && (prot & PROT_WRITE) && (flags & MAP_SHARED)) {
    return -1;
  }

  addr = p->sz;

  int found_vma = 0;
  for (i = 0; i < 16; i++) {
      if (p->vmas[i].occupied) {
          continue;
      }
      found_vma = 1;
      vma_p = &p->vmas[i];
      break;
  }
  
  if (!found_vma) {
      return mapped_addr;
  }

  vma_p->occupied = 1;
  vma_p->addr = p->sz;
  vma_p->length = len;
  vma_p->prot = prot;
  vma_p->flags = flags;
  vma_p->file = p->ofile[fd];
  filedup(vma_p->file);
  p->sz += len;
  // printf("mmap: mapped %p with length %d, shared: %d\n", p->sz, len, flags & MAP_SHARED);
  return vma_p->addr;
}

uint64
sys_munmap(void) {
    uint64 addr;
    int len, i, found_vma;
    struct vma *vma;
    if (argaddr(0, &addr) < 0 || argint(1, &len) < 0) {
        return -1;
    }

    struct proc *p = myproc();

    found_vma = 0;
    for (i = 0; i < 16; i++) {
        if (!p->vmas[i].occupied){
            continue;
        }
        if (addr >= p->vmas[i].addr && addr < p->vmas[i].addr + p->vmas[i].length) {
            if (len > p->vmas[i].length) {
                return -1;
            }
            vma = &p->vmas[i];
            found_vma = 1;
            break;
        }
    }

    if (!found_vma) {
        return -1;
    }

    if (vma->flags & MAP_SHARED) {
        // printf("munmap: writing from addr %p with %d\n", addr, len);
        if (filewrite(vma->file, addr, len) < 0) {
            // printf("munmap: filewrite failed, addr %p with %d, vma_addr %p, vma_len %d\n",
                    // addr, len, vma->addr, vma->length);
            // printf("file info: ref %d, writable %d, off %d\n", vma->file->ref, vma->file->writable, vma->file->off);
            // return -1;
        }
    }
    // uint64 origin_addr = vma->addr;
    // int origin_length = vma->length;
    if (addr == vma->addr && len == vma->length) {
        vma->occupied = 0;
        fileclose(vma->file);
    }
    vma->addr += len;
    vma->length -= len;
    // printf("munmap: addr: %p, len: %d, shared: %d\n"
    // "vma_addr changed from %p to %p, vma_length changed from %d to %d \n", 
    // addr, len, vma->flags & MAP_SHARED, origin_addr, vma->addr, origin_length, vma->length);

    // if (addr + len > vma->mapped_addr) {
    //   len = vma->mapped_addr - addr;
    //   // p->sz = addr;
    // }
    uvmunmap(p->pagetable, addr, len / PGSIZE, 1);
    return 0;
}