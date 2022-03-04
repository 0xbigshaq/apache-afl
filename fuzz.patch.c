/* ---------------------------------- */

#include <sched.h>
#include <linux/sched.h>
#include <arpa/inet.h>
#include <errno.h>
#include <net/if.h>
#include <net/route.h>
#include <netinet/ip6.h>
#include <netinet/tcp.h>
#include <sched.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <sys/ioctl.h>
#include <sys/resource.h>
#include <sys/socket.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

static void netIfaceUp(const char *ifacename)
{
    int sock = socket(AF_INET, SOCK_STREAM, IPPROTO_IP);
    if (sock == -1) {
        perror("socket(AF_INET, SOCK_STREAM, IPPROTO_IP)");
        exit(1);
    }

    struct ifreq ifr;
    memset(&ifr, '\0', sizeof(ifr));
    snprintf(ifr.ifr_name, IF_NAMESIZE, "%s", ifacename);

    if (ioctl(sock, SIOCGIFFLAGS, &ifr) == -1) {
        perror("ioctl(iface='lo', SIOCGIFFLAGS, IFF_UP)");
        exit(1);
    }

    ifr.ifr_flags |= (IFF_UP | IFF_RUNNING);

    if (ioctl(sock, SIOCSIFFLAGS, &ifr) == -1) {
        perror("ioctl(iface='lo', SIOCSIFFLAGS, IFF_UP)");
        exit(1);
    }

    close(sock);
}

void unsh(void)
{
    unshare(CLONE_NEWUSER | CLONE_NEWNET | CLONE_NEWNS);

    if (mount("tmpfs", "/tmp", "tmpfs", 0, "") == -1) {
        perror("tmpfs");
        exit(1);
    }
    netIfaceUp("lo");
}

static void fuzzer_thread(void)
{
    int BUFSIZE=1024*1024;
    usleep(10000);
    char buf[BUFSIZE+1];
    memset(buf, 0, BUFSIZE);
    size_t read_bytes = read(0, buf, BUFSIZE);
    buf[BUFSIZE-2] = '\r';
    buf[BUFSIZE-1] = '\n';
    buf[BUFSIZE] = '\0';

    int sockfd = socket(AF_INET, SOCK_STREAM, IPPROTO_IP);
    if (sockfd == -1) {
        perror("socket");
        exit(1);
    }

    int sz = (1024 * 1024);
    if (setsockopt(sockfd, SOL_SOCKET, SO_SNDBUF, &sz, sizeof(sz)) == -1) {
        perror("setsockopt");
        exit(1);
    }

    printf("[+] Connecting\n", buf);

    struct sockaddr_in saddr;
    saddr.sin_family = AF_INET;
    saddr.sin_port = htons(80);
    saddr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    while (connect(sockfd, &saddr, sizeof(saddr)) == -1) {
        perror("connect");
        usleep(100000);
    }

    printf("[+] Sending buf %s\n", buf);

    if (send(sockfd, buf, read_bytes, MSG_NOSIGNAL) != read_bytes) {
        perror("send() failed 1");
        exit(1);
    }

    if (shutdown(sockfd, SHUT_WR) == -1) {
        perror("shutdown");
        exit(1);
    }

    char b[1024 * 1024];
    while (recv(sockfd, b, sizeof(b), MSG_WAITALL) > 0) ;

    printf("[+] Received %s\n", b);

    close(sockfd);
    printf("[+] Done\n");
    usleep(100000);
    exit(0);
}

static void launch_fuzzy_thread(void)
{
    pthread_t t;
    pthread_attr_t attr;

    pthread_attr_init(&attr);
    pthread_attr_setstacksize(&attr, 1024 * 1024 * 8);
    pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);

    pthread_create(&t, &attr, fuzzer_thread, NULL);
}

/* ---------------------------------- */
int main(int argc, const char * const argv[])
{
    // enable fuzzing :^)
   if (getenv("NO_FUZZ") == NULL) {
        unsh();
        launch_fuzzy_thread();
        printf("[+] Launched AFL loop\n");
   }
   printf("[+] Continue with normal apache execution\n");

// ------------------------------------

