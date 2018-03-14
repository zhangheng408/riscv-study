#ifndef KVM_TOOLS_KERNEL_H
#define KVM_TOOLS_KERNEL_H

#define KERNEL_ALIGN		(1UL << (12 + 9))
/**
 * Code's offset in ELF file is PAGE_SIZE
 * We will load kernel in 0x80200000
 */
#define KERNEL_DRAM_OFFSET		(KERNEL_ALIGN - (1UL << 12))

#define DTB_ROM_OFFSET			(8*4)
#define DTB_DRAM_OFFSET			(0xc00000)

void* load_file(void* buffer, char *file_name, size_t max_size);
void* load_kernel(char *kernel_file_name);
void* load_dtb(char *dtb_file_name);

#endif
