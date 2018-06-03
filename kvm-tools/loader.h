#ifndef KVM_TOOLS_LOADER_H
#define KVM_TOOLS_LOADER_H

#include <string.h>

#define DTB_ROM_OFFSET			(0x1000)
#define DTB_DRAM_OFFSET			(0x10000000)

void* load_file(void* buffer, char *file_name, size_t max_size);
void* load_dtb(char *dtb_file_name);

#endif
