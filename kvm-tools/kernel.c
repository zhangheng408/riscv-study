#include <stdio.h>

#include "memory.h"
#include "kernel.h"

extern align_addr *dram_base;

void* load_kernel(char *kernel_file_name) {
    FILE *kernel_file;
    long kernel_size;
    size_t result;
	void* buffer = (void *)((char *)dram_base->aligned_addr + KERNEL_OFFSET);

    kernel_file = fopen(kernel_file_name, "rb");
    if(kernel_file == NULL){
        printf("cannot open kernel file\n");
        return NULL;
    }

    /* 获取文件大小 */
    fseek(kernel_file , 0 , SEEK_END);
    kernel_size = ftell(kernel_file);
	if(kernel_size >= DRAM_SIZE){
		printf("too large kernel %llx/%llx\n", kernel_size, DRAM_BASE);
		fclose(kernel_file);
		return NULL;
	}
    rewind(kernel_file);

    /* 将文件拷贝到dram中 */
    result = fread(buffer, 1, kernel_size, kernel_file);
    if(result != kernel_size){
        printf("load half kernel 0x%lx/0x%lx\n", result, kernel_size);
		fclose(kernel_file);
        return NULL;
    }
    printf("load kernel %s in %p[0x%lx]\n", kernel_file_name, buffer, kernel_size);

    /* 关闭文件 */
    fclose(kernel_file);
    return buffer;
}
