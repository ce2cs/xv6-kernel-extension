//
// Created by Boyang Gao on 2/22/22.
//
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

void primes(const int *left_pipe) {
    close(left_pipe[1]);
    int right_pipe[2];
    int n;
    int prime;
    int pid;

    if (read(left_pipe[0], &n,  4) == 0) {
        // printf("finish: close left pipe %d\n", left_pipe[0]);
        close(left_pipe[0]);
        exit(0);
    }

    pipe(right_pipe);
    // printf("create right_pipe %d, %d\n", right_pipe[0], right_pipe[1]);
    prime = n;
    printf("prime %d\n", prime);
    pid = fork();
    if (pid == 0) {
        primes(right_pipe);
    } else {
        close(right_pipe[0]);
        while (read(left_pipe[0], &n, 4)) {
            // printf("pid %d: read %d from left pipe %d\n", pid, n, left_pipe[0]);
            if (n % prime == 0) {
                continue;
            }
            // printf("pid %d: write %d to right pipe %d\n", pid, n, right_pipe[1]);
            write(right_pipe[1], &n, 4);
        }
        // printf("pid %d: close read left pipe %d\n", pid, left_pipe[0]);
        close(left_pipe[0]);
        // printf("pid %d: close write right pipe %d\n", pid, right_pipe[1]);
        close(right_pipe[1]);
        wait((int *) 0);
    }
    // printf("pid %d: exit\n", pid);    // // printf("pid %d: waiting child process\n", pid);
    exit(0);
}

int main() {
    int i;
    int p[2];
    int pid;

    pipe(p);
    pid = fork();
    if (pid == 0) {
        primes(p);
    } else {
        close(p[0]);
        for (i = 2; i < 36; ++i) {
            // printf("pid %d: write %d to right pipe %d\n", pid, i, p[1]);
            write(p[1], &i, 4);
        }
        // printf("pid %d: close write right pipe %d\n", pid, p[1]);
        close(p[1]);
        // printf("pid %d: waiting child process\n", pid);
        wait((int *) 0);
    }
    // printf("pid %d: exit\n", pid);
    exit(0);
}

