#ifndef KVM_TOOLS_KERNEL_H
#define KVM_TOOLS_KERNEL_H

#define KERNEL_ALIGN		(1UL << (12 + 9))
/**
 * Code's offset in ELF file is PAGE_SIZE
 * We will load kernel in 0x80200000
 */
#define KERNEL_DRAM_OFFSET		(0)

void* load_kernel(char *kernel_file_name);

#endif
