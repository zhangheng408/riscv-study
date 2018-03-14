#include <stdio.h>

#include "memory.h"
#include "loader.h"

void* load_file(void* buffer, char *file_name, size_t max_size) {
    FILE *file_ptr;
    long file_size;
    size_t result;

    file_ptr = fopen(file_name, "rb");
    if(file_ptr == NULL){
        printf("cannot open file %s\n", file_name);
        return NULL;
    }

    /* 获取文件大小 */
    fseek(file_ptr , 0 , SEEK_END);
    file_size = ftell(file_ptr);
	if(file_size >= DRAM_SIZE){
		printf("too large file %llx/%llx\n", file_size, DRAM_BASE);
		fclose(file_ptr);
		return NULL;
	}
    rewind(file_ptr);

    /* 将文件拷贝到dram中 */
    result = fread(buffer, 1, file_size, file_ptr);
    if(result != file_size){
        printf("load half file 0x%lx/0x%lx\n", result, file_size);
		fclose(file_ptr);
        return NULL;
    }
    printf("load file %s in %p[0x%lx]\n", file_name, buffer, file_size);

    /* 关闭文件 */
    fclose(file_ptr);
    return buffer;
}

extern align_addr *dram_base;

void* load_kernel(char *kernel_file_name){
	void* buffer = (void *)((char *)dram_base->aligned_addr + KERNEL_DRAM_OFFSET);

	return load_file(buffer, kernel_file_name, DRAM_SIZE - KERNEL_DRAM_OFFSET);
}
void* load_dtb(char *dtb_file_name){
	void* buffer = (void *)((char *)dram_base->aligned_addr + DTB_DRAM_OFFSET);

	return load_file(buffer, dtb_file_name, 4UL << 12); /* 4K */
}
