#define _XOPEN_SOURCE 600

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <signal.h>
#include <sys/wait.h>
#include <sys/select.h>
#include <pty.h>

#define READ_BUF  4096
#define PROMPT_TIMEOUT_US 120000  /* 120 ms quiet = command done */

static volatile sig_atomic_t child_exited = 0;
static pid_t child_pid = -1;

static void sigchld_handler(int sig)
{
    (void)sig;
    child_exited = 1;
}

/*
 * pty_run_command - write cmd to master fd, drain output until the shell
 * goes quiet for PROMPT_TIMEOUT_US microseconds, return bytes read.
 *
 * Returns: number of bytes placed in out_buf, or -1 on error.
 *
 * Observation from experiment: shells buffer output unpredictably.
 * A quiet period is the only portable "command done" signal without
 * parsing the prompt string (which varies per shell/config).
 */
ssize_t pty_run_command(int master_fd, const char *cmd,
                        char *out_buf, size_t out_sz)
{
    /* send command */
    size_t cmd_len = strlen(cmd);
    if (write(master_fd, cmd, cmd_len) != (ssize_t)cmd_len) {
        perror("write cmd");
        return -1;
    }
    /* append newline if missing */
    if (cmd[cmd_len - 1] != '\n') {
        if (write(master_fd, "\n", 1) != 1) {
            perror("write newline");
            return -1;
        }
    }

    /* drain output */
    ssize_t total = 0;
    fd_set rfds;
    struct timeval tv;

    while (!child_exited) {
        FD_ZERO(&rfds);
        FD_SET(master_fd, &rfds);
        tv.tv_sec  = 0;
        tv.tv_usec = PROMPT_TIMEOUT_US;

        int r = select(master_fd + 1, &rfds, NULL, NULL, &tv);
        if (r < 0) {
            if (errno == EINTR) continue;
            perror("select");
            return -1;
        }
        if (r == 0) break;  /* quiet period — command done */

        ssize_t n = read(master_fd, out_buf + total,
                         out_sz - (size_t)total - 1);
        if (n <= 0) break;
        total += n;
        if ((size_t)total >= out_sz - 1) break;
    }

    out_buf[total] = '\0';
    return total;
}

int main(void)
{
    struct sigaction sa;
    memset(&sa, 0, sizeof(sa));
    sa.sa_handler = sigchld_handler;
    sigaction(SIGCHLD, &sa, NULL);

    int master_fd;
    child_pid = forkpty(&master_fd, NULL, NULL, NULL);

    if (child_pid < 0) {
        perror("forkpty");
        return 1;
    }

    if (child_pid == 0) {
        /* child: become a shell */
        setenv("PS1", "$ ", 1);   /* predictable prompt */
        execl("/bin/sh", "sh", NULL);
        perror("execl");
        _exit(1);
    }

    /* parent: give shell a moment to emit its initial prompt */
    {
        char discard[READ_BUF];
        fd_set rfds;
        struct timeval tv = { .tv_sec = 0, .tv_usec = PROMPT_TIMEOUT_US };
        FD_ZERO(&rfds);
        FD_SET(master_fd, &rfds);
        if (select(master_fd + 1, &rfds, NULL, NULL, &tv) > 0)
            read(master_fd, discard, sizeof(discard));
    }

    /* --- experiment sequence --- */
    static const char *commands[] = {
        "echo 'PTY harness alive'",
        "ls /",
        "uname -a",
        "echo exit_code=$?",
        "exit",
        NULL
    };

    char buf[READ_BUF];

    for (int i = 0; commands[i]; i++) {
        printf("\n[cmd] %s\n", commands[i]);
        ssize_t n = pty_run_command(master_fd, commands[i], buf, sizeof(buf));
        if (n < 0) break;
        /* strip echoed command (first line) from output */
        char *newline = strchr(buf, '\n');
        const char *output = newline ? newline + 1 : buf;
        printf("[out] %s", output);
        if (child_exited) break;
    }

    waitpid(child_pid, NULL, 0);
    close(master_fd);
    printf("\n[done]\n");
    return 0;
}
