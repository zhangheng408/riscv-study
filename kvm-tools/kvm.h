#ifndef KVM_TOOLS_KVM_H
#define KVM_TOOLS_KVM_H

int kvm_ioctl(int fd, int type, ...);
int create_vm(void);
int kvm_vcpu_run(void);

#endif
