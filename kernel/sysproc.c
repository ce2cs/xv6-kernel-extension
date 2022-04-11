#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "date.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
  int n;
  if(argint(0, &n) < 0)
    return -1;
  exit(n);
  return 0;  // not reached
}

uint64
sys_getpid(void)
{
  return myproc()->pid;
}

uint64
sys_fork(void)
{
  return fork();
}

uint64
sys_wait(void)
{
  uint64 p;
  if(argaddr(0, &p) < 0)
    return -1;
  return wait(p);
}

uint64
sys_sbrk(void)
{
  int addr;
  int n;

  if(argint(0, &n) < 0)
    return -1;
  addr = myproc()->sz;
  if(growproc(n) < 0)
    return -1;
  return addr;
}

uint64
sys_sleep(void)
{
  int n;
  uint ticks0;

  backtrace();
  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
  return 0;
}

uint64
sys_kill(void)
{
  int pid;

  if(argint(0, &pid) < 0)
    return -1;
  return kill(pid);
}

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
  uint xticks;

  acquire(&tickslock);
  xticks = ticks;
  release(&tickslock);
  return xticks;
}

uint64 sys_sigreturn(void) {
    struct proc *p = myproc();
    if (p->alarm_status == ALARM_DISABLE) {
      return 0;
      // panic("sigreturn: alarm not enabled");
    }
    memmove(p->trapframe, p->saved_trapframe, sizeof(struct trapframe));
    // p->alarm_interval = 0;
    // p->alarm_handler = 0;
    p->alarm_status = ALARM_ENABLE;
    // p->ticks = 0;
    return 0;
}

uint64 sys_sigalarm(void) {
    struct proc *p = myproc();
    uint64 handler_addr;
    int alarm_interval;

    argint(0, &(alarm_interval));
    argaddr(1, &handler_addr);

    if (alarm_interval == 0 && handler_addr == 0) {
      if (p->alarm_status == ALARM_DISABLE) {
        return 1;
      } 
      p->alarm_interval = 0;
      p->alarm_handler = 0;
      p->alarm_status = ALARM_DISABLE;
      p->ticks = 0;
      if (p->saved_trapframe) {
        kfree(p->saved_trapframe);
        p->saved_trapframe = 0;
      }
    } else if (p->alarm_status == ALARM_ENABLE || p->alarm_status == ALARM_EXECUTING) {
      return 0;
    } else {
      p->alarm_interval = alarm_interval;
      p->alarm_handler = (void (*) (void)) handler_addr;
      p->alarm_status = ALARM_ENABLE;
      p->ticks = 0;
      p->saved_trapframe = kalloc();
      if (p->saved_trapframe == 0) {
        panic("sigalarm: kalloc failed");
      }
    }
    return 1;
}

