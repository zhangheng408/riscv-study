#ifndef KVM_TOOLS_MEMORY_H
#define KVM_TOOLS_MEMORY_H

#define ALIGN_SIZE		(0x1000)

#define ROM_BASE		0x1000 /*not from 0, from reset vector*/
#define ROM_SIZE		(0x1000 + 0x10000) /*reset vector + fdt*/

#define EXT_IO_BASE		0x40000000

#define DRAM_BASE		0x80000000
#define DRAM_SIZE		0x1000000 /*16M*/

int setup_memory(void);

#endif
