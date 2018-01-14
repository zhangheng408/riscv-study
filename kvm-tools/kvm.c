#include <stdio.h>
#include <stdlib.h>
#include <linux/kvm.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdarg.h>

#include "kvm.h"

int kvm_ioctl(int fd, int type, ...){
    int ret;
    void *arg;
    va_list ap;

    va_start(ap, type);
    arg = va_arg(ap, void *);
    va_end(ap);

    return ioctl(fd, type, arg);
}

extern int kvm_fd;
extern int vm_fd;
extern int vcpu_fd;

int create_vm(void){
    int ret;

    kvm_fd = open("/dev/kvm", O_RDWR);
    if(kvm_fd < 0){
        printf("cannot open kvm\n");
        return -1;
    }

    // 获取KVM API版本号
    ret = kvm_ioctl(kvm_fd, KVM_GET_API_VERSION, 0);
    if(ret < 0){
        printf("get kvm version fail\n");
        return -1;
    }
    printf("kvm api version: %d\n", ret);

    // 此处最后一个参数为type，riscv忽略该值
    ret = kvm_ioctl(kvm_fd, KVM_CREATE_VM, 0);
    printf("kvm create vm: %d\n", ret);
    if(ret < 0){
        printf("create vm fail\n");
        return -3;
    }
    vm_fd = ret;

    // 最后一个参数是vcpu id，riscv应该会忽略，只支持单核
    ret = kvm_ioctl(vm_fd, KVM_CREATE_VCPU, 0);
    printf("kvm create vcpu: %d\n", ret);
    if(ret < 0){
        printf("create vcpu fail\n");
        return -4;
    }
    vcpu_fd = ret;

    return 0;
}

int kvm_vcpu_run(void){
	int ret = -1;

    ret = kvm_ioctl(vcpu_fd, KVM_RUN, 0);
    printf("kvm run vcpu: %d\n", ret);
	return ret;
}
