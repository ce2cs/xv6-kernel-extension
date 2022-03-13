//
// Created by Boyang Gao on 2/22/22.
//
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user.h"



int main(int argc, char* argv[]) {
    char* error_msg;
    int sleep_seconds;
    if (argc <= 1) {
        error_msg = "error: you need to input an integer parameter";
        write(1, error_msg, strlen(error_msg));
    }

    char* parameter = argv[1];

    if (!is_number(parameter)) {
        error_msg = "error: you must input an integer";
        write(1, error_msg, strlen(error_msg));
    }
    sleep_seconds = atoi(parameter);
    sleep(sleep_seconds);
    exit(0);
}


