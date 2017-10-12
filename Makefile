DIR_RISCV		?= $(wildcard ~/riscv)
DIR_WORKING		?= $(DIR_RISCV)/working
DIR_INSTALL		?= $(DIR_RISCV)/install


REPO_RISCV		?= https://github.com/riscv
REPO_GNU		?= $(REPO_RISCV)/riscv-gnu-toolchain
REPO_QEMU		?= $(REPO_RISCV)/riscv-qemu

LOG_PATH		?= $(DIR_WORKING)/logs
QEMU_BUILDLOG	?= $(LOG_PATH)/qemu-build.log

all:
	@echo ""
	@echo "Enjoy riscv!"
	@echo ""
	@echo "make highfive"
	@echo "     or: make clean"
	@echo ""

highfive:
	@make clean

clean:
	@rm -fr $(DIR_WORKING) $(DIR_INSTALL)

toolchain-new:
	@echo "rm old repo..."
	@rm -rf $(DIR_WORKING)/riscv-gnu-toolchain 
	@echo "clone new repo"
	@cd $(DIR_WORKING);								\
		 git clone --recursive $(REPO_GNU);			\
		 cd -
	@echo ""

toolchain-make:
	@echo "do configure..."
	@cd $(DIR_WORKING);								\
		./configure 								\
		--prefix=$(DIR_INSTALL)/riscv-gnu-toolchain	\
		--enable-multilib

busybox:
	@echo "Remove old busybox ..."
	@test -d $(DIR_WORKING) || mkdir -p $(DIR_WORKING)
	@rm -fr $(DIR_WORKING)/busybox*
	@cd $(DIR_WORKING);					\
		tar xfj $(BUSYBOX_TARBALL);			\
		ln -sf busybox-1.21.1 busybox
	@echo "Configure and make busybox ..."
	@cp $(BUSYBOX_CONFIG) $(DIR_WORKING)/busybox/.config
	@yes "" | make -C $(DIR_WORKING)/busybox oldconfig	\
		>> $(BUSYBOX_BUILDLOG) 2>&1
	@make -C $(DIR_WORKING)/busybox -j4			\
		>> $(BUSYBOX_BUILDLOG) 2>&1
	@make -C $(DIR_WORKING)/busybox install			\
		>> $(BUSYBOX_BUILDLOG) 2>&1

linux-new:
	@echo "Remove old linux repo ..."
	@test -d $(DIR_WORKING) || mkdir -p $(DIR_WORKING)
	@rm -fr $(DIR_WORKING)/linux
	@echo "Clone and checkout RISCV branch"
	@cd $(DIR_WORKING);					\
		git clone $(LINUX_GITREPO) -- linux
	@cd $(DIR_WORKING)/linux;				\
		git checkout -b RISCV $(LINUX_VERSION)
	@cd $(DIR_WORKING)/linux;				\
		cp -a $(LINUX_307)/arch/* arch ;		\
		cp -a $(LINUX_307)/Documentation/DocBook/* Documentation/DocBook ;	\
		git add . ;					\
		git commit -asm "RISCV: Add arch/RISCV support" ; \
		git am $(LINUX_307)/patches-fixup/*

linux-make:
	@echo "Make mrproper ..."
	@make -C $(DIR_WORKING)/linux ARCH=$(LINUX_ARCH)	\
		mrproper >> $(LINUX_BUILDLOG) 2>&1
	@echo "Make $(LINUX_DEFCONFIG) ..."
	@make -C $(DIR_WORKING)/linux ARCH=$(LINUX_ARCH)	\
		$(LINUX_DEFCONFIG) >> $(LINUX_BUILDLOG) 2>&1
	@echo "Making (in several minutes) ..."
	@make -C $(DIR_WORKING)/linux ARCH=$(LINUX_ARCH) -j4	\
		>> $(LINUX_BUILDLOG) 2>&1
	@echo "Softlinking necessary files ..."
	@ln -sf $(DIR_WORKING)/linux/arch/RISCV/boot/zImage $(DIR_WORKING)
	@ln -sf $(DIR_WORKING)/linux/System.map $(DIR_WORKING)
	@echo "Generating disassembly file for vmlinux ..."
	@$(OBJDUMP) -D $(DIR_WORKING)/linux/vmlinux		\
		> $(DIR_WORKING)/vmlinux.disasm

qemu-new:
	@test -d $(DIR_WORKING) ||						\
		mkdir -p $(DIR_WORKING)
	@echo "Remove old qemu repo ..."
	@rm -fr $(DIR_WORKING)/riscv-qemu
	@echo "Clone new qemu repo ..."
	@cd $(DIR_WORKING); 							\
		git clone $(REPO_QEMU);						\
		cd -
	@echo "update submodule pixman"
	@cd $(DIR_WORKING)/riscv-qemu;					\
    	git submodule update --init pixman;			\
		cd -

qemu-make:
	@test -d $(LOG_PATH) ||							\
		mkdir -p $(LOG_PATH)
	@echo "Configure qemu ..."
	@cd $(DIR_WORKING)/riscv-qemu; ./configure						\
		--target-list=riscv64-softmmu,riscv64-linux-user			\
		--prefix=$(DIR_INSTALL)/riscv-qemu							\
		> $(QEMU_BUILDLOG) 2>&1;									\
		cd -
	@echo "Make qemu and make install ..."
	@make -C $(DIR_WORKING)/riscv-qemu -j4 >> $(QEMU_BUILDLOG) 2>&1
	@make -C $(DIR_WORKING)/riscv-qemu install >> $(QEMU_BUILDLOG) 2>&1

qemu-run:
	@echo "Remove old log file"
	@rm -fr $(QEMU_TRACELOG)
	@echo "Running QEMU in this tty ..."
	@$(DIR_WORKING)/qemu-RISCV/bin/qemu-system-RISCV\
		-curses						\
		--cpu=RISCV						\
		-M puv4						\
		-m 512						\
		-smp $(QEMU_SMP)				\
		-icount 0					\
		-kernel $(DIR_WORKING)/zImage			\
		-append "root=/dev/ram"				\
		2> $(QEMU_TRACELOG)

