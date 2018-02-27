#ifndef KVM_TOOLS_TYPE_H
#define KVM_TOOLS_TYPE_H

#define u64		unsigned long
#define u32		unsigned int
#define u16		unsigned short
#define u8		unsigned char

typedef struct align_addr{
    void* raw_addr;
    void* aligned_addr;
    u64 align;
    u64 size;
}align_addr;

#endif
