DIR_RISCV			:= $(shell pwd)
DIR_WORKING			:= $(DIR_RISCV)/working
DIR_INSTALL			:= $(DIR_RISCV)/install
DIR_PATCH			:= $(DIR_RISCV)/patch

TOOLCHAIN			?= $(DIR_INSTALL)/riscv-gnu-toolchain
PATH				:= $(TOOLCHAIN)/bin:$(PATH)
CROSS_PREFIX		:= riscv64-unknown-linux-gnu-
DIR_SYSROOT			:= $(TOOLCHAIN)/sysroot

REPO_RISCV			?= https://github.com/riscv
REPO_TOOLS			?= $(REPO_RISCV)/riscv-tools
REPO_QEMU			?= $(REPO_RISCV)/riscv-qemu
REPO_LINUX			?= $(REPO_RISCV)/riscv-linux

QEMU_BASE			:= 2ab9055
LINUX_BASE			:= 50c4c4e
TOOLS_BASE			:= ccf7c12
BINUTILS_BASE		:= d0176cb
PK_BASE				:= 2dcae92

BUSYBOX_VERSION		:= 1.26.2
BUSYBOX_TARBALL		:= /pub/backup/busybox-$(BUSYBOX_VERSION).tar.bz2

DIR_LINUX			?= $(DIR_WORKING)/riscv-linux
DIR_TOOLS			?= $(DIR_WORKING)/riscv-tools
DIR_TOOLCHAIN		?= $(DIR_TOOLS)/riscv-gnu-toolchain
DIR_BINUTILS		?= $(DIR_TOOLCHAIN)/riscv-binutils-gdb
DIR_QEMU			?= $(DIR_TOOLCHAIN)/riscv-qemu
DIR_PK				?= $(DIR_TOOLS)/riscv-pk
DIR_FESVR			?= $(DIR_TOOLS)/riscv-fesvr
DIR_ISA_SIM			?= $(DIR_TOOLS)/riscv-isa-sim

LOG_PATH			:= $(DIR_RISCV)/logs
QEMU_BUILDLOG		:= $(LOG_PATH)/qemu-build.log
TOOLCHAIN_BUILDLOG	:= $(LOG_PATH)/toolchain-build.log
BUSYBOX_BUILDLOG	:= $(LOG_PATH)/busybox-build.log
LINUX_BUILDLOG		:= $(LOG_PATH)/linux-build.log
PK_BUILDLOG			:= $(LOG_PATH)/pk-build.log

DIR_DTS				:= $(DIR_RISCV)/dts

QEMU_MACHINE		?= spike_v1.10

all:
	@echo ""
	@echo "Enjoy riscv!"
	@echo ""

highfive:
	@make clean
	@make tools-new
	@make tools-update
	@make toolchain-make
	@make linux-update
	@make linux-headers-install
	@make linux-new
	@make linux-make
	@make pk-make
	@make qemu-update
	@make qemu-make
	@make qemu-run

clean:
	@rm -fr $(DIR_WORKING) $(DIR_INSTALL)

tools-new:
	@test -d $(DIR_WORKING) || mkdir -p $(DIR_WORKING)
	@echo "rm old repo..."
	@rm -rf $(DIR_WORKING)/riscv-tools
	@echo "clone new repo"
	@cd $(DIR_WORKING);												\
		git clone --recursive $(REPO_TOOLS)

tools-update:
	@echo "clean binuitls git dir ..."
	@cd $(DIR_BINUTILS);											\
		git clean -qndf;											\
		git checkout -fB mprc $(BINUTILS_BASE)
	@echo "apply binutils patch ..."
	@cd $(DIR_BINUTILS);											\
		git am $(DIR_PATCH)/tools/toolchain/binuitls/*
	@echo "clean riscv-pk git dir ..."
	@cd $(DIR_PK);													\
		git clean -qndf;											\
		git checkout -fB mprc $(PK_BASE)
	@echo "apply riscv-pk patch ..."
	@cd $(DIR_PK);													\
		git am $(DIR_PATCH)/tools/pk/*

toolchain-make:
	@if [ -e $(DIR_INSTALL)/riscv-gnu-toolchain ]; then 			\
		rm -rf $(DIR_INSTALL)/riscv-gnu-toolchain					\
	;fi
	@if [ -e $(DIR_TOOLCHAIN)/Makefile ]; then						\
		make -C $(DIR_TOOLCHAIN) clean								\
	;fi
	@test -d $(LOG_PATH) ||											\
		mkdir -p $(LOG_PATH)
	@echo "do configure..."
	@cd $(DIR_TOOLCHAIN);											\
		./configure 												\
		--prefix=$(DIR_INSTALL)/riscv-gnu-toolchain					\
		> $(TOOLCHAIN_BUILDLOG) 2>&1
	@echo "make and make install..."
	@make -C $(DIR_TOOLCHAIN) linux									\
		>> $(TOOLCHAIN_BUILDLOG) 2>&1

busybox:
	@test -d $(LOG_PATH) ||											\
		mkdir -p $(LOG_PATH)
	@echo "Remove old busybox ..."
	@test -d $(DIR_WORKING) || mkdir -p $(DIR_WORKING)
	@rm -fr $(DIR_WORKING)/busybox*
	@cd $(DIR_WORKING);												\
		tar xmfj $(BUSYBOX_TARBALL);								\
		ln -sf busybox-$(BUSYBOX_VERSION) busybox
	@echo "Configure and make busybox ..."
	@echo "CONFIG_STATIC=y"											\
		> $(DIR_WORKING)/busybox/.config
	@echo "CONFIG_CROSS_COMPILER_PREFIX=\"$(CROSS_PREFIX)"" \
		>> $(DIR_WORKING)/busybox/.config
	@echo "CONFIG_SYSROOT=\"$(DIR_SYSROOT)\""	\
		>> $(DIR_WORKING)/busybox/.config
	@yes "" | make -C $(DIR_WORKING)/busybox oldconfig	\
		> $(BUSYBOX_BUILDLOG) 2>&1
	@make -C $(DIR_WORKING)/busybox -j4			\
		>> $(BUSYBOX_BUILDLOG) 2>&1
	@make -C $(DIR_WORKING)/busybox install			\
		>> $(BUSYBOX_BUILDLOG) 2>&1

linux-new:
	@test -d $(DIR_WORKING) || mkdir -p $(DIR_WORKING)
	@echo "Remove old linux repo ..."
	@rm -fr $(DIR_LINUX)
	@echo "clone new repo ..."
	@cd $(DIR_WORKING);												\
		git clone $(REPO_LINUX)
	@echo "make tags .."
	@make -C $(DIR_LINUX) tags ARCH=riscv

linux-update:
	@echo "clean git dir ..."
	@cd $(DIR_LINUX);								\
		git clean -qndf;							\
		git checkout -fB mprc $(LINUX_BASE)
	@echo "apply linux patch ..."
	@cd $(DIR_LINUX);								\
		git am $(DIR_PATCH)/linux/*
	@cd $(DIR_LINUX);								\
		git am $(DIR_PATCH)/linux/kvm/*

linux-headers-install:
	@make -C $(DIR_LINUX)							\
		headers_install								\
		ARCH=riscv									\
		INSTALL_HDR_PATH=$(DIR_SYSROOT)/usr/

linux-simple-make:
	@echo "Making (in several minutes) ..."
	@make -C $(DIR_LINUX) ARCH=riscv -j4			\
		> $(LINUX_BUILDLOG) 2>&1

linux-make:
	@test -d $(LOG_PATH) ||							\
		mkdir -p $(LOG_PATH)
	@echo "Make clean ..."
	@make -C $(DIR_LINUX) ARCH=riscv				\
		clean > $(LINUX_BUILDLOG) 2>&1
	@echo "Make guest config ..."
	@cp $(DIR_RISCV)/linux-configs/guest-config		\
		$(DIR_LINUX)/.config
	@make -C $(DIR_LINUX) ARCH=riscv				\
		olddefconfig >> $(LINUX_BUILDLOG) 2>&1
	@echo "Making (in several minutes) ..."
	@make -C $(DIR_LINUX) ARCH=riscv -j4			\
		>> $(LINUX_BUILDLOG) 2>&1
	@echo "dump guest linux"
	@riscv64-unknown-linux-gnu-objdump -D			\
		$(DIR_LINUX)/vmlinux						\
		> $(LOG_PATH)/dump.linux.guest.log
	@echo "Copy guest vmlinux to install/"
	@cp $(DIR_LINUX)/vmlinux						\
		$(DIR_INSTALL)/vmlinux-guest
	@echo "Make guest dtb ..."
	@$(DIR_LINUX)/scripts/dtc/dtc -I dts -o dtb		\
		$(DIR_DTS)/riscv-spike-10.dts				\
		-o $(DIR_INSTALL)/spike-10.dtb
	@echo "Make host config ..."
	@cp $(DIR_RISCV)/linux-configs/host-config		\
		$(DIR_LINUX)/.config
	@make -C $(DIR_LINUX) ARCH=riscv				\
		olddefconfig >> $(LINUX_BUILDLOG) 2>&1
	@echo "Making (in several minutes) ..."
	@make -C $(DIR_LINUX) ARCH=riscv -j4			\
		>> $(LINUX_BUILDLOG) 2>&1
	@echo "dump host linux"
	@riscv64-unknown-linux-gnu-objdump -D			\
		$(DIR_LINUX)/vmlinux						\
		> $(LOG_PATH)/dump.linux.host.log
	@echo "Copy host vmlinux to install/"
	@cp $(DIR_LINUX)/vmlinux						\
		$(DIR_INSTALL)/vmlinux-host

kvm-tool-make:
	@$(CROSS_PREFIX)gcc								\
		$(DIR_RISCV)/kvm-tools/*.c					\
		-static										\
		-o $(DIR_INSTALL)/kvm-tool

pk-make:
	@echo "clean old build ..."
	@rm -rf $(DIR_INSTALL)/riscv-pk
	@rm -rf $(PK_BUILDLOG)
	@test -d $(LOG_PATH) ||							\
		mkdir -p $(LOG_PATH)
	@echo "Make clean ..."
	@rm -rf $(DIR_PK)/build
	@echo "config..."
	@mkdir -p $(DIR_PK)/build
	@if [ -e $(DIR_LINUX)/vmlinux ]; then			\
		cd $(DIR_PK)/build;							\
		../configure								\
		--prefix=$(DIR_INSTALL)/riscv-pk			\
		--host=riscv64-unknown-linux-gnu			\
		--with-payload=$(DIR_LINUX)/vmlinux			\
		--enable-logo								\
		>> $(PK_BUILDLOG) 2>&1						\
	;else											\
		cd $(DIR_PK)/build;							\
		../configure								\
		--prefix=$(DIR_INSTALL)/riscv-pk			\
		--host=riscv64-unknown-linux-gnu			\
		--enable-logo								\
		>> $(PK_BUILDLOG) 2>&1						\
	;fi
	@echo "make..."
	@make -C $(DIR_PK)/build						\
		>> $(PK_BUILDLOG) 2>&1
	@make -C $(DIR_PK)/build install				\
		>> $(PK_BUILDLOG) 2>&1
	@echo "dump bbl"
	@riscv64-unknown-linux-gnu-objdump -D			\
		$(DIR_PK)/build/bbl							\
		> $(LOG_PATH)/dump.bbl.log

qemu-update:
	@echo "clean git dir ..."
	@cd $(DIR_QEMU);								\
		git clean -qndf;							\
		git checkout -fB mprc $(QEMU_BASE)
	@echo "apply qemu patch ..."
	@cd $(DIR_QEMU);								\
		git am $(DIR_PATCH)/qemu/*;					\
		git am $(DIR_PATCH)/qemu/hyper/*

qemu-make:
	@test -d $(LOG_PATH) ||							\
		mkdir -p $(LOG_PATH)
	@rm -rf $(DIR_INSTALL)/riscv-qemu
	@echo "Configure qemu ..."
	@cd $(DIR_QEMU); 												\
		./configure													\
		--target-list=riscv64-softmmu,riscv64-linux-user			\
		--prefix=$(DIR_INSTALL)/riscv-qemu							\
		> $(QEMU_BUILDLOG) 2>&1
	@echo "Make qemu and make install ..."
	@make -C $(DIR_QEMU) -j4 >> $(QEMU_BUILDLOG) 2>&1
	@make -C $(DIR_QEMU) install >> $(QEMU_BUILDLOG) 2>&1

qemu-run:
	@$(DIR_INSTALL)/riscv-qemu/bin/qemu-system-riscv64				\
		-nographic													\
		-m 1948M													\
		-machine $(QEMU_MACHINE)									\
		-kernel $(DIR_INSTALL)/riscv-pk/riscv64-unknown-elf/bin/bbl

qemu-ucb:
	@$(DIR_INSTALL)/riscv-qemu/bin/qemu-system-riscv64				\
		-nographic													\
		-kernel $(DIR_RISCV)/ucb/bblvmlinuxinitramfs_dynamic_1.9.1
