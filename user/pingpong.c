//
// Created by Boyang Gao on 2/22/22.
//

#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int main() {
    int pid;
    int p[2];
    int fork_pid;
    char buf[4];

    pipe(p);
    fork_pid = fork();
    pid = getpid();
    if (fork_pid == 0) {
        read(p[0], buf, 4);
        write(p[1], "pong", 4);
    } else {
        write(p[1], "ping", 4);
        wait((int *) 0);
        read(p[0], buf, 4);
    }
    printf("%d: received %s\n", pid, buf);
    close(p[0]);
    close(p[1]);
    exit(0);
}
