#!/bin/sh

basepath=$(cd `dirname $0`; pwd)
qemu=$basepath/../install/riscv-qemu/bin/qemu-system-riscv64

benchs=`ls $basepath/../install/riscv-tests/share/riscv-tests/benchmarks/*.riscv`
for bench in $benchs; do \
    echo "$bench"; \
    $qemu -nographic -machine spike_v1.10 -kernel $bench; \
    echo ""
done

isa_tests=`ls $basepath/../install/riscv-tests/share/riscv-tests/isa/rv64* | grep -v .dump`
for isa_test in $isa_tests; do \
    echo "$isa_test"; \
    $qemu -nographic -machine spike_v1.10 -kernel $isa_test; \
    echo ""
done
