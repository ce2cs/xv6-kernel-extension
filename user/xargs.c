// xargs - build and execute command lines from standard input
#include "kernel/types.h"
#include "kernel/stat.h"
#include "kernel/param.h"
#include "user/user.h"
#define DEBUG 0

int readline(int fd, char* buf, int buf_size) {
    int i = 0;
    char c;
    while (read(fd, &c, 1)) {
        if (i < buf_size) {
            if (c != '\n') {
                buf[i] = c;
            } else if (i < buf_size) {
                buf[i] = 0;
                break;
            }
        } else {
            return buf_size + 1;
        }
        ++i;
    }
    return i;
}

int split(char* s, char delimiter, char *splitted[], int splitted_cap) {
    int i;
    char curr[512];
    int curr_i = 0;
    int count = 0;
    for (i = 0; i < strlen(s); ++i) {
        if (i >= MAX_ARG_BYTES) {
            fprintf(2, "splitted string shard's length exceeds capacity!\n");
            exit(1);
        }
        if (s[i] == delimiter) {
            curr[curr_i] = 0;
            if (count >= splitted_cap) {
                fprintf(2, "splitted section's length exceeds capacity!\n");
                exit(1);
            }
            strcpy(splitted[count], curr);
            curr_i = 0;
            ++count;
        } else {
            curr[curr_i] = s[i];
            ++curr_i;
            if (curr_i == strlen(s)) {
                if (count >= splitted_cap) {
                    fprintf(2, "splitted section's length exceeds capacity!\n");
                    exit(1);
                }
                strcpy(splitted[count], curr);
                curr_i = 0;
                ++count;
            }
        }
    }
    return count;
}

int xargs(char *command, char *args[], int fd, int arg_size) {
    char line[512];
    int read_bytes;
    int pid = 0;
    char* argv[MAXARG];
    int i;
    int res;
    int splitted_count;

    for (i = 0; i < MAXARG; ++i) {
        if (i < arg_size) {
            argv[i] = args[i];
        } else {
            char arg[MAX_ARG_BYTES];
            argv[i] = arg;
        }
    }

    while ((read_bytes = readline(fd, line, MAX_LINE_LEN)) > 0) {
        pid = fork();
        if (pid == 0) {
            splitted_count = split(line, ' ', argv + arg_size, MAXARG - arg_size);
            argv[arg_size + splitted_count] = 0;
            if (DEBUG) {
                for (i = 0; i < MAXARG; ++i) {
                    printf("argv[%d]: %s ", i, argv[i]);
                }
                printf("\n");
            }
            exec(command, argv);
            printf("exec failed!");
        } else {
            wait(&res);
            if (res == 1) {
                fprintf(2, "child process failed\n");
                exit(1);
            }
        }
    }
    return 0;
}

int main(int argc, char *argv[]) {
    if (argc <= 1) {
        printf("usage: xargs [command] [args...]\n");
    }

    xargs(argv[1], argv + 1, 0, argc - 1);
    exit(0);
}