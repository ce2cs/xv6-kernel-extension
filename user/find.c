//
// Created by Boyang Gao on 3/4/22.
//

#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/fs.h"

void get_file_name(char* path, char* buf) {
    char *p;
    for(p=path+strlen(path); p >= path && *p != '/'; p--);
    p++;
    strcpy(buf, p);
}

int find(char* path, char* target) {
    int fd;
    struct dirent de;
    struct stat st;
    char buf[512];
    char *p;
    if ((fd = open(path, 0)) < 0) {
        fprintf(2, "find: cannot open %s\n", path);
    }

    if (fstat(fd, &st) < 0) {
        fprintf(2, "find: cannot stat %s \n", path);
        close(fd);
        return 0;
    }

    if (st.type == T_FILE) {
        char file_name[DIRSIZ];
        get_file_name(path, file_name);
        if (strcmp(file_name, target) == 0) {
            printf("%s\n", path);
        }
    }

    if (st.type == T_DIR) {
        if(strlen(path) + 1 + DIRSIZ + 1 > sizeof buf){
            fprintf(2, "ls: path too long\n");
        }
        strcpy(buf, path);
        p = buf + strlen(buf);
        *p = '/';
        p++;
        while(read(fd, &de, sizeof(de)) == sizeof(de)){
            if(de.inum == 0) continue;
            if (strcmp(de.name, ".") == 0 || strcmp(de.name, "..") == 0) continue;
            memmove(p, de.name, DIRSIZ);
            find(buf, target);
        }
    }
    close(fd);
    return 0;
}

int main(int argc, char *argv[]) {
    if (argc != 3) {
        fprintf(2, "find: missing argument, usage: find [dir] [file]\n");
    }

    char* path = argv[1];
    char* target = argv[2];
    find(path, target);
    exit(0);
}



