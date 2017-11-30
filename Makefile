DIR_RISCV			:= $(shell pwd)
DIR_WORKING			:= $(DIR_RISCV)/working
DIR_INSTALL			:= $(DIR_RISCV)/install

TOOLCHAIN			?= $(DIR_INSTALL)/riscv-gnu-toolchain
PATH				:= $(TOOLCHAIN)/bin:$(PATH)

REPO_RISCV			?= https://github.com/riscv
REPO_TOOLS			?= $(REPO_RISCV)/riscv-tools
REPO_QEMU			?= $(REPO_RISCV)/riscv-qemu

BUSYBOX_VERSION		:= 1.26.2
BUSYBOX_TARBALL		:= /pub/backup/busybox-$(BUSYBOX_VERSION).tar.bz2

LINUX_VERSION		:= 4.6.2
DIR_LINUX			:= $(DIR_WORKING)/riscv-linux
LINUX_TARBALL		:= /pub/backup/linux-$(LINUX_VERSION).tar.xz
LINUX_REPO			:= /pub/git/riscv-linux.git

DIR_TOOLS			?= $(DIR_WORKING)/riscv-tools
DIR_TOOLCHAIN		?= $(DIR_TOOLS)/riscv-gnu-toolchain
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
FESVR_BUILDLOG		:= $(LOG_PATH)/fesvr-build.log
ISA_SIM_BUILDLOG	:= $(LOG_PATH)/isa-sim-build.log

all:
	@echo ""
	@echo "Enjoy riscv!"
	@echo ""
	@echo "make highfive"
	@echo "     or: make clean"
	@echo "     or: make qemu-new"
	@echo "     or: make qemu-make"
	@echo ""

highfive:
	@make clean

clean:
	@rm -fr $(DIR_WORKING) $(DIR_INSTALL)

tools-new:
	@echo "rm old repo..."
	@rm -rf $(DIR_WORKING)/riscv-tools
	@echo "clone new repo"
	@cd $(DIR_WORKING);												\
		git clone $(REPO_TOOLS)
	@echo "create qemu branch"
	@cd $(DIR_WORKING)/riscv-tools;									\
		git branch qemu 745e74afb56ecba090669615d4ac9c9b9b96c653
	@cd $(DIR_WORKING)/riscv-tools;									\
		git checkout qemu
	@echo "update submodule"
	@cd $(DIR_WORKING)/riscv-tools;									\
		git submodule update --init --recursive

toolchain-make:
	@if [ -f $(DIR_INSTALL)/riscv-gnu-toolchain ]; then 			\
		rm -rf $(DIR_INSTALL)/riscv-gnu-toolchain					\
	;fi
	@if [ -f $(DIR_TOOLCHAIN)/Makefile ]; then						\
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
	@echo "CONFIG_CROSS_COMPILER_PREFIX=\"$(DIR_INSTALL)/riscv-gnu-toolchain/bin/riscv64-unknown-linux-gnu-\"" \
		>> $(DIR_WORKING)/busybox/.config
	@echo "CONFIG_SYSROOT=\"$(DIR_INSTALL)/riscv-gnu-toolchain/sysroot\""	\
		>> $(DIR_WORKING)/busybox/.config
	@yes "" | make -C $(DIR_WORKING)/busybox oldconfig	\
		> $(BUSYBOX_BUILDLOG) 2>&1
	@make -C $(DIR_WORKING)/busybox -j4			\
		>> $(BUSYBOX_BUILDLOG) 2>&1
	@make -C $(DIR_WORKING)/busybox install			\
		>> $(BUSYBOX_BUILDLOG) 2>&1

linux-new:
	@echo "Remove old linux repo ..."
	@test -d $(DIR_WORKING) || mkdir -p $(DIR_WORKING)
	@rm -fr $(DIR_LINUX)
	@echo "untar linux tarball ..."
	@cd $(DIR_WORKING);												\
		tar xmJf $(LINUX_TARBALL)
	@echo "add git repo ..."
	@cd $(DIR_LINUX);												\
		git init;													\
		git remote add origin $(LINUX_REPO);						\
		rm -rf .gitignore arch/.gitignore;							\
		git pull -f origin priv-1.9:master

linux-make:
	@test -d $(LOG_PATH) ||							\
		mkdir -p $(LOG_PATH)
	@echo "Make mrproper ..."
	@make -C $(DIR_LINUX) ARCH=riscv				\
		mrproper > $(LINUX_BUILDLOG) 2>&1
	@echo "Make config ..."
	@cp $(DIR_RISCV)/riscv_linux_config 			\
		$(DIR_LINUX)/.config
	@make -C $(DIR_LINUX) ARCH=riscv				\
		olddefconfig >> $(LINUX_BUILDLOG) 2>&1
	@echo "Making (in several minutes) ..."
	@make -C $(DIR_LINUX) ARCH=riscv -j4			\
		>> $(LINUX_BUILDLOG) 2>&1

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
	@if [ -f $(DIR_LINUX)/vmlinux ]; then			\
		cd $(DIR_PK)/build;							\
		../configure								\
		--prefix=$(DIR_INSTALL)/riscv-pk			\
		--host=riscv64-unknown-linux-gnu			\
		--with-payload=$(DIR_LINUX)/vmlinux			\
		>> $(PK_BUILDLOG) 2>&1						\
	;else											\
		cd $(DIR_PK)/build;							\
		../configure								\
		--prefix=$(DIR_INSTALL)/riscv-pk			\
		--host=riscv64-unknown-linux-gnu			\
		>> $(PK_BUILDLOG) 2>&1						\
	;fi
	@echo "make..."
	@make -C $(DIR_PK)/build						\
		>> $(PK_BUILDLOG) 2>&1
	@make -C $(DIR_PK)/build install				\
		>> $(PK_BUILDLOG) 2>&1

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
		-kernel $(DIR_INSTALL)/riscv-pk/riscv64-unknown-elf/bin/bbl

qemu-ucb:
	@$(DIR_INSTALL)/riscv-qemu/bin/qemu-system-riscv64				\
		-nographic													\
		-kernel $(DIR_RISCV)/ucb/bblvmlinuxinitramfs_dynamic_1.9.1

fesvr-make:
	@echo "remove old build..."
	@test -d $(LOG_PATH) ||											\
		mkdir -p $(LOG_PATH)
	@rm -rf $(DIR_INSTALL)/riscv-fesvr
	@echo "config..."
	@mkdir -p $(DIR_FESVR)/build
	@cd $(DIR_FESVR)/build;											\
		../configure --prefix=$(DIR_INSTALL)/riscv-fesvr			\
		> $(FESVR_BUILDLOG) 2>&1
	@echo "make install..."
	@make -C $(DIR_FESVR)/build install 							\
		>> $(FESVR_BUILDLOG) 2>&1

isa-sim-make:
	@echo "remove old build..."
	@test -d $(LOG_PATH) ||											\
		mkdir -p $(LOG_PATH)
	@rm -rf $(DIR_INSTALL)/riscv-isa-sim
	@echo "config..."
	@mkdir -p $(DIR_ISA_SIM)/build
	@cd $(DIR_ISA_SIM)/build;										\
		../configure --prefix=$(DIR_INSTALL)/riscv-isa-sim			\
		--with-fesvr=$(DIR_INSTALL)/riscv-fesvr						\
		> $(ISA_SIM_BUILDLOG) 2>&1
	@echo "make install..."
	@make -C $(DIR_ISA_SIM)/build 									\
		>> $(ISA_SIM_BUILDLOG) 2>&1
	@make -C $(DIR_ISA_SIM)/build install 							\
		>> $(ISA_SIM_BUILDLOG) 2>&1
