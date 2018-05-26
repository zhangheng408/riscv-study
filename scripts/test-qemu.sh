#!/bin/sh

basepath=$(cd `dirname $0`; pwd)
benchs=`ls $basepath/../install/riscv-tests/share/riscv-tests/benchmarks/*.riscv`
qemu=$basepath/../install/riscv-qemu/bin/qemu-system-riscv64
for bench in $benchs; do \
    echo "$bench"; \
    $qemu -nographic -kernel $bench; \
    echo ""
done
