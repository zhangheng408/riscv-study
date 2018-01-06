#include <stdio.h>
#include <stdlib.h>
#include <linux/kvm.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdarg.h>

int kvm_fd = -1;
int vm_fd = -1;
int vcpu_fd = -1;

void* load_kernel(char *kernel_file_name);

void main_loop(void);

int create_vm(void);

int kvm_ioctl(int fd, int type, ...){
    int ret;
    void *arg;
    va_list ap;

    va_start(ap, type);
    arg = va_arg(ap, void *);
    va_end(ap);

    return ioctl(fd, type, arg);
}

int main(int argc, char **argv) {
    void *kernel = NULL;
    int ret;

    if(argc < 2){
        printf("please input kernel file\n");
        exit(1);
    }
    kernel = load_kernel(argv[1]);
    if(kernel == NULL){
        printf("cannot load kernel file\n");
        exit(2);
    }

    ret = create_vm();
    if(ret < 0){
        goto free_kernel;
    }
    printf("kvm 0x%x, vm 0x%x, vcpu 0x%x\n", kvm_fd, vm_fd, vcpu_fd);

    main_loop();

    if(vcpu_fd >= 0){
        close(vcpu_fd);
    }
    if(vm_fd >= 0){
        close(vm_fd);
    }
    if(kvm_fd >= 0){
        close(kvm_fd);
    }
free_kernel:
    free(kernel);
    return 0;
}

int create_vm(void){
    int ret;

    kvm_fd = open("/dev/kvm", O_RDWR);
    if(kvm_fd == -1){
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

void* load_kernel(char *kernel_file_name) {
    FILE *kernel_file;
    long kernel_size;
    char *buffer;
    size_t result;

    kernel_file = fopen(kernel_file_name, "rb");
    if(kernel_file==NULL){
        printf("cannot open kernel file\n");
        return NULL;
    }

    /* 获取文件大小 */
    fseek(kernel_file , 0 , SEEK_END);
    kernel_size = ftell(kernel_file);
    rewind(kernel_file);

    /* 分配内存存储整个文件 */
    buffer = (char*)malloc(sizeof(char)*kernel_size);
    if(buffer == NULL){
        printf("cannot alloc mem\n");
        return NULL;
    }

    /* 将文件拷贝到buffer中 */
    result = fread(buffer, 1, kernel_size, kernel_file);
    if(result != kernel_size){
        printf("load half kernel 0x%lx/0x%lx\n", result, kernel_size);
        return NULL;
    }
    printf("load kernel %s in %p[0x%lx]\n", kernel_file_name, buffer, kernel_size);

    /* 关闭文件 */
    fclose(kernel_file);
    return buffer;
}

void main_loop(void) {
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
