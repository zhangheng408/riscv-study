DIR_RISCV64		:=$(wildcard ~/riscv64)
DIR_WORKING 	:=$(DIR_RISCV64)/working
QEMU_GITREPO	:=$(DIR_RISCV64)/pub/git/riscv-qemu
BUSYBOX_TARBALL :=$(DIR_RISCV64)/pub/src/busybox-1.25.1.tar.bz2
LINUX_TARBALL	:=$(DIR_RISCV64)/pub/src/linux-4.6.2.tar.gz
RISCV_LINUX_GIT	:=$(DIR_RISCV64)/pub/git/riscv-linux.git
RISCV_PK_GIT	:=$(DIR_RISCV64)/pub/git/riscv-pk.git
RISCV_TOOL_GIT	:=$(DIR_RISCV64)/pub/git/riscv-gnu-toolchain.git
RISCV_STRACE_GIT:=$(DIR_RISCV64)/pub/git/strace.git
all:
	@make highfive
highfive:
	@make clean
	@test -d $(DIR_WORKING) || mkdir -p $(DIR_WORKING)
	@make busybox
	@make strace-make
	@make qemu-new
	@make qemu-make
	@make linux-new
	@make linux-make
	@make bbl-make

set-path:
	@export RISCV=$(DIR_RISCV64)/riscv
	@export PATH=$(PATH):$(RISCV)/bin
clean:
	@rm -rf $(DIR_WORKING)

busybox:
	@echo "Removing old busybox ..."
	@rm -fr $(DIR_WORKING)/busybox*
	@cd $(DIR_WORKING);	\
		tar xfj $(BUSYBOX_TARBALL)
	@echo "Configuring busybox ..."
	@cp $(DIR_RISCV64)/pub/config/initramfs_busybox_config $(DIR_WORKING)/busybox-1.25.1/.config
	@yes "" | make -C $(DIR_WORKING)/busybox-1.25.1 oldconfig
	@make -C $(DIR_WORKING)/busybox-1.25.1 -j4 

qemu-new:
	@test -d $(DIR_WORKING)/qemu-riscv64 || mkdir -p $(DIR_WORKING)/qemu-riscv64
	@echo "Removing old qemu repo..."
	@rm -rf $(DIR_WORKING)/riscv-qemu
	@cd $(DIR_WORKING);git clone $(QEMU_GITREPO)
	
qemu-make:
	@echo "Configuring qemu ..."
	@cd $(DIR_WORKING)/riscv-qemu; ./configure \
		--target-list=riscv64-softmmu \
		--prefix=$(DIR_WORKING)/qemu-riscv64
	@echo "Make qemu and install ..."
	@make -C $(DIR_WORKING)/riscv-qemu
	@make -C $(DIR_WORKING)/riscv-qemu install

linux-new:
	@echo "Getting linux 4.6.2 src ..."
	@cd $(DIR_WORKING);tar -xzf $(LINUX_TARBALL)
	@rm -rf $(DIR_WORKING)/riscv-linux
	@cd $(DIR_WORKING);git clone $(RISCV_LINUX_GIT)
	@cd $(DIR_WORKING)/riscv-linux;git checkout priv-1.9
	@cp -r $(DIR_WORKING)/riscv-linux/arch $(DIR_WORKING)/linux-4.6.2
	@cd $(DIR_WORKING)/linux-4.6.2;mkdir tmp
	@cd $(DIR_WORKING)/linux-4.6.2/tmp;mkdir bin etc
	@cp $(DIR_WORKING)/busybox-1.25.1/busybox $(DIR_WORKING)/linux-4.6.2/tmp/bin/busybox
	@cp $(DIR_RISCV64)/pub/src/hello $(DIR_WORKING)/linux-4.6.2/tmp/bin/hello
	@cp $(DIR_WORKING)/strace/strace $(DIR_WORKING)/linux-4.6.2/tmp/bin/strace
	@cp $(DIR_RISCV64)/pub/src/inittab $(DIR_WORKING)/linux-4.6.2/tmp/etc/inittab
	@cp $(DIR_RISCV64)/pub/config/riscv_linux_config $(DIR_WORKING)/linux-4.6.2/.config
	@cp $(DIR_RISCV64)/pub/src/initramfs.txt $(DIR_WORKING)/linux-4.6.2/arch/riscv/initramfs.txt

linux-make:
	@cd $(DIR_WORKING)/linux-4.6.2;make -j4 ARCH=riscv vmlinux

bbl-make:
	@rm -rf $(DIR_WORKING)/riscv-pk
	@cd $(DIR_WORKING);git clone $(RISCV_PK_GIT)
	@cd $(DIR_WORKING)/riscv-pk;git checkout f73dee6f2cc37cafc4b6949dac9ac2d71cf84d10
	@cd $(DIR_WORKING)/riscv-pk;mkdir build
	@cd $(DIR_WORKING)/riscv-pk/build;../configure --prefix=$(RISCV) \
		--host=riscv64-unknown-linux-gnu \
		--with-payload=$(DIR_WORKING)/linux-4.6.2/vmlinux
	@make -C $(DIR_WORKING)/riscv-pk/build

toolchain:
	@rm -rf $(DIR_WORKING)/riscv-gnu-toolchain
	@cd $(DIR_WORKING);git clone $(RISCV_TOOL_GIT)
	@cd $(DIR_WORKING)/riscv-gnu-toolchain;git checkout 7e4859465ef8b38fb8369971c1449270ae7a19a1
	@cd $(DIR_WORKING)/riscv-gnu-toolchain;./configure --prefix=$(DIR_WORKING)/riscv
	@cd $(DIR_WORKING)/riscv-gnu-toolchain;make linux

strace-make:
	@rm -rf $(DIR_WORKING)/strace
	@cd $(DIR_WORKING);git clone $(RISCV_STRACE_GIT)
	@cd $(DIR_WORKING)/strace;git checkout 4b69c4736cb9b44e0bd7bef16f7f8602b5d2f113
	@cd $(DIR_WORKING)/strace;patch -p1 < $(DIR_RISCV64)/pub/patch/riscv.patch
	@cd $(DIR_WORKING)/strace;./bootstrap
	@cd $(DIR_WORKING)/strace;./configure \
		--host=riscv64-unknown-linux-gnu \
		--prefix=$(RISCV)
	@make CFLAGS+="-static" -C $(DIR_WORKING)/strace 

