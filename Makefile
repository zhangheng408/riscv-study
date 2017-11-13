DIR_RISCV			:= $(wildcard ~/riscv)
DIR_WORKING			:= $(DIR_RISCV)/working
DIR_INSTALL			:= $(DIR_RISCV)/install

TOOLCHAIN			?= $(DIR_INSTALL)/riscv-gnu-toolchain
PATH				:= $(TOOLCHAIN)/bin:$(PATH)

REPO_RISCV			?= https://github.com/riscv
REPO_TOOLS			?= $(REPO_RISCV)/riscv-tools
REPO_QEMU			?= $(REPO_RISCV)/riscv-qemu

BUSYBOX_VERSION		:= 1.25.1
BUSYBOX_TARBALL		:= /pub/backup/busybox-$(BUSYBOX_VERSION).tar.bz2

LINUX_VERSION		:= 4.6.2
DIR_LINUX			:= $(DIR_WORKING)/linux-$(LINUX_VERSION)
LINUX_TARBALL		:= /pub/backup/linux-$(LINUX_VERSION).tar.xz
LINUX_REPO			:= /pub/git/riscv-linux.git

DIR_PK				?= $(DIR_WORKING)/riscv-tools/riscv-pk

LOG_PATH			:= $(DIR_RISCV)/logs
QEMU_BUILDLOG		:= $(LOG_PATH)/qemu-build.log
TOOLCHAIN_BUILDLOG	:= $(LOG_PATH)/toolchain-build.log
BUSYBOX_BUILDLOG	:= $(LOG_PATH)/busybox-build.log
LINUX_BUILDLOG		:= $(LOG_PATH)/linux-build.log
BBL_BUILDLOG		:= $(LOG_PATH)/bbl-build.log

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
	@rm -rf $(DIR_INSTALL)/riscv-gnu-toolchain
	@make -C $(DIR_WORKING)/riscv-tools/riscv-gnu-toolchain			\
		clean
	@test -d $(LOG_PATH) ||											\
		mkdir -p $(LOG_PATH)
	@echo "do configure..."
	@cd $(DIR_WORKING)/riscv-tools/riscv-gnu-toolchain;				\
		./configure 												\
		--prefix=$(DIR_INSTALL)/riscv-gnu-toolchain					\
		> $(TOOLCHAIN_BUILDLOG) 2>&1
	@echo "make and make install..."
	@make -C $(DIR_WORKING)/riscv-tools/riscv-gnu-toolchain			\
		linux														\
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

bbl-make:
	@echo "clean old build ..."
	@rm -rf $(DIR_INSTALL)/riscv-pk
	@rm -rf $(BBL_BUILDLOG)
	@test -d $(LOG_PATH) ||							\
		mkdir -p $(LOG_PATH)
	@echo "Make clean ..."
	@rm -rf $(DIR_PK)/build
	@echo "config..."
	@mkdir -p $(DIR_PK)/build
	@cd $(DIR_PK)/build;							\
		../configure								\
		--prefix=$(DIR_INSTALL)/riscv-pk			\
		--host=riscv64-unknown-linux-gnu			\
		--with-payload=$(DIR_LINUX)/vmlinux			\
		>> $(BBL_BUILDLOG) 2>&1
	@echo "make..."
	@make -C $(DIR_PK)/build						\
		>> $(BBL_BUILDLOG) 2>&1
	@make -C $(DIR_PK)/build install				\
		>> $(BBL_BUILDLOG) 2>&1

qemu-new:
	@test -d $(DIR_WORKING) ||						\
		mkdir -p $(DIR_WORKING)
	@echo "Remove old qemu repo ..."
	@rm -fr $(DIR_WORKING)/riscv-qemu
	@echo "Clone new qemu repo ..."
	@cd $(DIR_WORKING); 							\
		git clone $(REPO_QEMU)
	@echo "update submodule pixman"
	@cd $(DIR_WORKING)/riscv-qemu;					\
    	git submodule update --init pixman

qemu-make:
	@test -d $(LOG_PATH) ||							\
		mkdir -p $(LOG_PATH)
	@rm -rf $(DIR_INSTALL)/riscv-qemu
	@echo "Configure qemu ..."
	@cd $(DIR_WORKING)/riscv-qemu; ./configure						\
		--target-list=riscv64-softmmu,riscv64-linux-user			\
		--prefix=$(DIR_INSTALL)/riscv-qemu							\
		> $(QEMU_BUILDLOG) 2>&1
	@echo "Make qemu and make install ..."
	@make -C $(DIR_WORKING)/riscv-qemu -j4 >> $(QEMU_BUILDLOG) 2>&1
	@make -C $(DIR_WORKING)/riscv-qemu install >> $(QEMU_BUILDLOG) 2>&1

qemu-run:
	@$(DIR_INSTALL)/riscv-qemu/bin/qemu-system-riscv64				\
		-nographic													\
		-kernel $(DIR_INSTALL)/riscv-pk/riscv64-unknown-elf/bin/bbl

qemu-ucb:
	@$(DIR_INSTALL)/riscv-qemu/bin/qemu-system-riscv64				\
		-nographic													\
		-kernel $(DIR_RISCV)/ucb/bblvmlinuxinitramfs_dynamic_1.9.1
