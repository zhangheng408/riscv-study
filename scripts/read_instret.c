//#include<stdio.h>

#define csr_read(csr)						\
({				            				\
	register unsigned long __v;				\
	asm volatile ("csrr %0, " #csr			\
			      : "=r" (__v) :			\
			      : "memory");	    		\
	__v;						        	\
})

void main() {
    csr_read(instret);
    //printf("instruction retired: %lx\n", csr_read(instret));
}
