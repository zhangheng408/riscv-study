#include <stdio.h>
#include <stdlib.h>
#include <linux/kvm.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdarg.h>

#include "kernel.h"
#include "kvm.h"
#include "loader.h"
#include "memory.h"

int kvm_fd = -1;
int vm_fd = -1;
int vcpu_fd = -1;

align_addr *rom_base = NULL;
align_addr *dram_base = NULL;

int main(int argc, char **argv){
    int ret;

    if(argc < 3){
        printf("please input kernel file and dtb file\n");
        exit(-1);
    }
    printf("main: %p\n", main);

    ret = create_vm();
    if(ret < 0){
        return -2;
    }
    printf("kvm 0x%x, vm 0x%x, vcpu 0x%x\n", kvm_fd, vm_fd, vcpu_fd);

	ret = setup_memory();
    if(ret < 0){
		goto free_vm;
    }

    if(NULL == load_kernel(argv[1])){
        printf("cannot load kernel file\n");
		goto free_mem;
    }

    if(NULL == load_dtb(argv[2])){
        printf("cannot load dtb file\n");
		goto free_mem;
    }

	ret = kvm_vcpu_run();
	if(ret < 0){
		goto free_mem;
	}

free_mem:
	free_align_addr(rom_base);
	free_align_addr(dram_base);
free_vm:
    if(vcpu_fd >= 0){
        close(vcpu_fd);
    }
    if(vm_fd >= 0){
        close(vm_fd);
    }
    if(kvm_fd >= 0){
        close(kvm_fd);
    }
    return 0;
}
