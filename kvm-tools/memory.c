#include <linux/kvm.h>

#include <stdio.h>
#include <stdlib.h>

#include "memory.h"
#include "kvm.h"
#include "type.h"

align_addr *align_malloc(u64 size, u64 align){
	align_addr *addr = NULL;

    addr = malloc(sizeof(align_addr));
    if(addr == NULL){
        return NULL;
    }

    addr->raw_addr = NULL;
	addr->raw_addr = malloc(size + align);
	if(addr->raw_addr == NULL){
        free(addr);
		printf("%s: alloc 0x%x + 0x%x fail\n", __func__, size, align);
		return NULL;
	}

    addr->align = align;
    addr->size = size;
    addr->aligned_addr = (void *)(((u64)addr->raw_addr + align) & ~(align - 1));
	printf("alloc mem %p/%p with %llx/%llx\n",
			addr->raw_addr, addr->aligned_addr, addr->size, align);
	return addr;
}

void free_align_addr(align_addr* addr){
    free(addr->raw_addr);
    free(addr);
}

extern int vm_fd;

static int memory_add_subregion(u64 base, u64 size, u32 slot_id, u32 flags,
		align_addr **user_base){
	align_addr *ptr = NULL;
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
	kvm_mem.userspace_addr = (u64)ptr->aligned_addr;
	ret = kvm_ioctl(vm_fd, KVM_SET_USER_MEMORY_REGION, (void *)&kvm_mem);
	printf("%s: set user mem 0x%llx/%p, ret %d\n", __func__, base, ptr->aligned_addr, ret);
	if(ret < 0){
		free_align_addr(ptr);
		return -2;
	}

	*user_base = ptr;

	return 0;
}

extern align_addr* rom_base;
extern align_addr* dram_base;

int setup_memory(void){
	int ret = -1;

	ret = memory_add_subregion(ROM_BASE, ROM_SIZE, 0, KVM_MEM_READONLY, &rom_base);
	if(ret < 0){
		printf("add rom fail\n");
		return -1;
	}
	ret = memory_add_subregion(DRAM_BASE, DRAM_SIZE, 1, 0, &dram_base);
	if(ret < 0){
		printf("add dram fail\n");
		return -2;
	}
	return 0;
}
