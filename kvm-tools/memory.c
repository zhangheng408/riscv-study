#include <linux/kvm.h>

#include <stdio.h>
#include <stdlib.h>

#include "memory.h"
#include "kvm.h"
#include "type.h"

void *align_malloc(u64 size, u64 align){
	void *ptr = NULL;

	ptr = malloc(size + align);
	if(ptr == NULL){
		printf("%s: alloc 0x%x + 0x%x fail\n", __func__, size, align);
		return NULL;
	}
	return (void *)(((u64)ptr + align) & ~(align - 1));
}

extern int vm_fd;

static int memory_add_subregion(u64 base, u64 size, u32 slot_id, u32 flags,
		void **user_base){
	void *ptr = NULL;
	struct kvm_userspace_memory_region kvm_mem;
	int ret =  -1;

	ptr = align_malloc(size, ALIGN_SIZE);
	if(ptr == NULL){
		return -1;
	}

	kvm_mem.slot = slot_id;
	kvm_mem.flags = flags;
	kvm_mem.guest_phys_addr = base;
	kvm_mem.memory_size = size;
	kvm_mem.userspace_addr = (u64)ptr;
	ret = kvm_ioctl(vm_fd, KVM_SET_USER_MEMORY_REGION, (void *)&kvm_mem);
	if(ret < 0){
		printf("%s: set user mem 0x%llx/%p fail", base, ptr);
		free(ptr);
		return -2;
	}

	*user_base = ptr;

	return 0;
}

extern void* rom_base;
extern void* dram_base;

int setup_memory(void){
	int ret = -1;

	ret = memory_add_subregion(ROM_BASE, ROM_SIZE, 0, KVM_MEM_READONLY, &rom_base);
	if(ret < 0){
		printf("add rom fail\n");
		return -1;
	}
	ret = memory_add_subregion(DRAM_BASE, DRAM_SIZE, 0, 0, &dram_base);
	if(ret < 0){
		printf("add dram fail\n");
		return -2;
	}
	return 0;
}
