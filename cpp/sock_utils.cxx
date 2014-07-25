
// Copyright (c) 2013-2014 Quanta Research Cambridge, Inc.

// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <semaphore.h>
#include <pthread.h>

#include "portal.h"
#include "sock_utils.h"

#define SOCKET_NAME                 "socket_for_bluesim"
#define MAGIC_PORTAL_FOR_SENDING_FD                 666

static pthread_mutex_t socket_mutex;
static sem_t dma_waiting;
static int global_sockfd = -1;

void connect_to_bsim(void)
{
  int connect_attempts = 0;

  if (global_sockfd != -1)
    return;
  if ((global_sockfd = socket(AF_UNIX, SOCK_STREAM, 0)) == -1) {
    fprintf(stderr, "%s (%s) socket error %s\n",__FUNCTION__, SOCKET_NAME, strerror(errno));
    exit(1);
  }

  //fprintf(stderr, "%s (%s) trying to connect...\n",__FUNCTION__, SOCKET_NAME);
  struct sockaddr_un local;
  local.sun_family = AF_UNIX;
  strcpy(local.sun_path, SOCKET_NAME);
  while (connect(global_sockfd, (struct sockaddr *)&local, strlen(local.sun_path) + sizeof(local.sun_family)) == -1) {
    if(connect_attempts++ > 16){
      fprintf(stderr,"%s (%s) connect error %s\n",__FUNCTION__, SOCKET_NAME, strerror(errno));
      exit(1);
    }
    //fprintf(stderr, "%s (%s) retrying connection\n",__FUNCTION__, SOCKET_NAME);
    sleep(1);
  }
  fprintf(stderr, "%s (%s) connected\n",__FUNCTION__, SOCKET_NAME);
  pthread_mutex_init(&socket_mutex, NULL);
  sem_init(&dma_waiting, 0, 0);
}

void bsim_wait_for_connect(int* psockfd)
{
  int listening_socket;

  if ((listening_socket = socket(AF_UNIX, SOCK_STREAM, 0)) == -1) {
    fprintf(stderr, "%s: socket error %s",__FUNCTION__, strerror(errno));
    exit(1);
  }

  struct sockaddr_un local;
  local.sun_family = AF_UNIX;
  strcpy(local.sun_path, SOCKET_NAME);
  unlink(local.sun_path);
  int len = strlen(local.sun_path) + sizeof(local.sun_family);
  if (bind(listening_socket, (struct sockaddr *)&local, len) == -1) {
    fprintf(stderr, "%s[%d]: bind error %s\n",__FUNCTION__, listening_socket, strerror(errno));
    exit(1);
  }

  if (listen(listening_socket, 5) == -1) {
    fprintf(stderr, "%s[%d]: listen error %s\n",__FUNCTION__, listening_socket, strerror(errno));
    exit(1);
  }
  
  //fprintf(stderr, "%s[%d]: waiting for a connection...\n",__FUNCTION__, listening_socket);
  if ((*psockfd = accept(listening_socket, NULL, NULL)) == -1) {
    fprintf(stderr, "%s[%d]: accept error %s\n",__FUNCTION__, listening_socket, strerror(errno));
    exit(1);
  }
  remove(SOCKET_NAME);  // we are connected now, so we can remove named socket
}

/* Thanks to keithp.com for readable examples how to do this! */

#define COMMON_SOCK_FD \
    struct msghdr   msg; \
    struct iovec    iov; \
    union { \
        struct cmsghdr  cmsghdr; \
        char        control[CMSG_SPACE(sizeof (int))]; \
    } cmsgu; \
    struct cmsghdr  *cmsg; \
    \
    iov.iov_base = buf; \
    iov.iov_len = sizeof(buf); \
    msg.msg_name = NULL; \
    msg.msg_namelen = 0; \
    msg.msg_iov = &iov; \
    msg.msg_iovlen = 1; \
    msg.msg_control = cmsgu.control; \
    msg.msg_controllen = sizeof(cmsgu.control);

ssize_t sock_fd_write(int fd)
{
    char buf[] = "1";
    COMMON_SOCK_FD;
    cmsg = CMSG_FIRSTHDR(&msg);
    cmsg->cmsg_len = CMSG_LEN(sizeof (int));
    cmsg->cmsg_level = SOL_SOCKET;
    cmsg->cmsg_type = SCM_RIGHTS;
    *((int *) CMSG_DATA(cmsg)) = fd;
  struct memrequest foo = {MAGIC_PORTAL_FOR_SENDING_FD};

  pthread_mutex_lock(&socket_mutex);
  if (send(global_sockfd, &foo, sizeof(foo), 0) == -1) {
    fprintf(stderr, "%s: send error sending fd\n",__FUNCTION__);
    //exit(1);
  }
  int rv = sendmsg(global_sockfd, &msg, 0);
  pthread_mutex_unlock(&socket_mutex);
  return rv;
}

static ssize_t
sock_fd_read(int sock, int *fd)
{
    ssize_t     size;
    char buf[16];

    COMMON_SOCK_FD;
    *fd = -1;
    size = recvmsg (sock, &msg, 0);
    cmsg = CMSG_FIRSTHDR(&msg);
    if (size > 0 && cmsg && cmsg->cmsg_len == CMSG_LEN(sizeof(int))) {
        if (cmsg->cmsg_level != SOL_SOCKET || cmsg->cmsg_type != SCM_RIGHTS) {
            fprintf(stderr, "%s: invalid message\n", __FUNCTION__);
            exit(1);
        }
        *fd = *((int *) CMSG_DATA(cmsg));
    }
    return size;
}

/* functions called by READL() and WRITEL() macros in application software */
unsigned int read_portal_bsim(volatile unsigned int *addr, int id)
{
  struct memrequest foo = {id, 0,addr,0};
  struct memresponse rv;

  pthread_mutex_lock(&socket_mutex);
  if (send(global_sockfd, &foo, sizeof(foo), 0) == -1) {
    fprintf(stderr, "%s (fpga%d) send error, errno=%s\n",__FUNCTION__, id, strerror(errno));
    exit(1);
  }
  if(recv(global_sockfd, &rv, sizeof(rv), 0) == -1){
    fprintf(stderr, "%s (fpga%d) recv error\n",__FUNCTION__, id);
    exit(1);	  
  }
  pthread_mutex_unlock(&socket_mutex);
  return rv.data;
}

void write_portal_bsim(volatile unsigned int *addr, unsigned int v, int id)
{
  struct memrequest foo = {id, 1,addr,v};

  pthread_mutex_lock(&socket_mutex);
  if (send(global_sockfd, &foo, sizeof(foo), 0) == -1) {
    fprintf(stderr, "%s (fpga%d) send error\n",__FUNCTION__, id);
    exit(1);
  }
  pthread_mutex_unlock(&socket_mutex);
}

void init_pareff()
{
}

static int dma_fd = -1;
int pareff_fd(int *fd)
{
  sem_wait(&dma_waiting);
  *fd = dma_fd;
  dma_fd = -1;
}

int bsim_ctrl_recv(int sockfd, struct memrequest *data)
{
  int rc = recv(sockfd, data, sizeof(*data), MSG_DONTWAIT);
  if (rc == sizeof(*data) && data->portal == MAGIC_PORTAL_FOR_SENDING_FD) {
    sock_fd_read(sockfd, &dma_fd);
    sem_post(&dma_waiting);
    rc = -1;
  }
  return rc;
}

int bsim_ctrl_send(int sockfd, struct memresponse *data)
{
  return send(sockfd, data, sizeof(*data), 0);
}
