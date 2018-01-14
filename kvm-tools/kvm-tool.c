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
#include "memory.h"
#include "kernel.h"

int kvm_fd = -1;
int vm_fd = -1;
int vcpu_fd = -1;

void *rom_base = NULL;
void *dram_base = NULL;

void main_loop(void){
    char c;

    while(1){
        scanf("%c", &c);
        switch(c){
            case 'q':
            case 'Q':
                return;
            default:
                printf("unknown cmd\n");
        }
    }
}

int main(int argc, char **argv){
    int ret;

    if(argc < 2){
        printf("please input kernel file\n");
        exit(-1);
    }

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

	ret = kvm_vcpu_run();
	if(ret < 0){
		goto free_mem;
	}

    main_loop();

free_mem:
	free(rom_base);
	free(dram_base);
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
