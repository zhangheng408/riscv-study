#include <elf.h>
#include <stdio.h>

#include "kernel.h"
#include "loader.h"
#include "memory.h"
#include "type.h"

extern align_addr *dram_base;

void* load_kernel(char *kernel_file_name){
	char* kernel = NULL;

	kernel = (char*)load_file(NULL, kernel_file_name, DRAM_SIZE - KERNEL_DRAM_OFFSET);

    Elf64_Ehdr* ehdr = (Elf64_Ehdr*)kernel;
    if (ehdr->e_ident[0] != ELFMAG0
            || ehdr->e_ident[1] != ELFMAG1
            || ehdr->e_ident[2] != ELFMAG2
            || ehdr->e_ident[3] != ELFMAG3
            || ehdr->e_ident[EI_CLASS] != ELFCLASS64
            || ehdr->e_ident[EI_DATA] != ELFDATA2LSB
            || ehdr->e_ident[EI_OSABI] != ELFOSABI_NONE
            || ehdr->e_type != ET_EXEC
            || ehdr->e_version != EV_CURRENT
            || ehdr->e_machine != EM_RISCV) {
        printf("%s is not legal riscv64 elf file\n", kernel_file_name);
        return NULL;
    }

    for (int i = 0; i < ehdr->e_phnum; ++i) {
        Elf64_Phdr* phdr = (Elf64_Phdr*)(kernel + ehdr->e_phoff + i * ehdr->e_phentsize);
        if (phdr->p_type == PT_LOAD) {
            memcpy(dram_base->aligned_addr + phdr->p_paddr + KERNEL_DRAM_OFFSET, kernel + phdr->p_offset, phdr->p_filesz);
        }
        printf("phdr %d: type %lx, paddr %lx, offset %lx, size %lx\n",
                i, phdr->p_type, phdr->p_paddr, phdr->p_offset, phdr->p_filesz);
    }
    return kernel;
}
