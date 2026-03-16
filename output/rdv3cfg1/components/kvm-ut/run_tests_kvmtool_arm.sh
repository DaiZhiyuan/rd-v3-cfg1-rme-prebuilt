#!/bin/bash

LKVM_DEFAULT_ARGS='--nodefaults --network mode=none --loglevel=warning'
NCPUS=$(nproc)

function run_selftest_setup {
	echo -e '\n   === selftest-setup ===\n'
	$LKVM run -k $TESTDIR/selftest.flat -c 2 -m 256 $IRQCHIP_ARG $ARCH_ARG \
		-p 'setup smp=2 mem=256' $LKVM_DEFAULT_ARGS
}

function run_vectors_kernel {
	echo -e '\n   === selftest-vectors-kernel ===\n'
	$LKVM run -k $TESTDIR/selftest.flat -c 1 -m 64 $IRQCHIP_ARG $ARCH_ARG \
		-p 'vectors-kernel' $LKVM_DEFAULT_ARGS
}

function run_vectors_user {
	echo -e '\n   === selftest-vectors-user ===\n'
	$LKVM run -k $TESTDIR/selftest.flat -c 1 -m 64 $IRQCHIP_ARG $ARCH_ARG \
		-p 'vectors-user' $LKVM_DEFAULT_ARGS
}

function run_selftest_smp {
	echo -e '\n   === selftest-smp ===\n'
	$LKVM run -k $TESTDIR/selftest.flat -c $NCPUS -m 64 $IRQCHIP_ARG $ARCH_ARG \
		-p "smp" $LKVM_DEFAULT_ARGS
}

function run_pmu_cycle_counter {
	echo -e '\n   === pmu-cycle-counter ===\n'
	$LKVM run -k $TESTDIR/pmu.flat -c 1 -m 64 $IRQCHIP_ARG $ARCH_ARG \
		--pmu -p 'cycle-counter 0' $LKVM_DEFAULT_ARGS
}

function run_pmu_test {
	local testname="$1"
	echo -e "\n   === $testname ===\n"
	$LKVM run -k $TESTDIR/pmu.flat -c 1 -m 64 $IRQCHIP_ARG \
		--pmu -p "$testname" $LKVM_DEFAULT_ARGS
}

function run_gicv2_ipi {
	local ncpus=$NCPUS
	if [[ $ncpus -gt 8 ]]; then
		ncpus=8
	fi

	echo -e "\n   === gicv2-ipi ===\n"
	$LKVM run -k $TESTDIR/gic.flat -c $ncpus -m 64 $ARCH_ARG --irqchip=gicv2 \
		-p 'ipi' $LKVM_DEFAULT_ARGS
}

function run_gicv3_ipi {
	echo -e "\n   === gicv3-ipi ===\n"
	$LKVM run -k $TESTDIR/gic.flat -c $NCPUS -m 64 $ARCH_ARG --irqchip=gicv3 \
		-p 'ipi' $LKVM_DEFAULT_ARGS
}

function run_gicv2_active {
	local ncpus=$NCPUS
	if [[ $ncpus -gt 8 ]]; then
		ncpus=8
	fi

	echo -e "\n   === gicv2-active ===\n"
	$LKVM run -k $TESTDIR/gic.flat -c $ncpus -m 64 $ARCH_ARG --irqchip=gicv2 \
		-p 'active' $LKVM_DEFAULT_ARGS
}

function run_gicv3_active {
	echo -e "\n   === gicv3-active ===\n"
	$LKVM run -k $TESTDIR/gic.flat -c $NCPUS -m 64 $ARCH_ARG --irqchip=gicv3 \
		-p 'active' $LKVM_DEFAULT_ARGS
}

function run_gicv2_mmio {
	echo -e '\n   === gicv2-mmio ===\n'
	$LKVM run -k $TESTDIR/gic.flat -c $NCPUS -m 64 $ARCH_ARG --irqchip gicv2 \
		-p 'mmio' $LKVM_DEFAULT_ARGS
}

function run_gicv2_mmio_up {
	echo -e '\n   === gicv2-mmio-up ===\n'
	$LKVM run -f $TESTDIR/gic.flat -c 1 -m 64 $ARCH_ARG --irqchip gicv2 \
		-p 'mmio' $LKVM_DEFAULT_ARGS
}

function run_gicv2_mmio_3p {
	echo -e '\n   === gicv2-mmio-3p ===\n'
	$LKVM run -f $TESTDIR/gic.flat -c 3 -m 64 $ARCH_ARG --irqchip gicv2 \
		-p 'mmio' $LKVM_DEFAULT_ARGS
}

function run_its_test {
	testname="$1"
	echo -e "\n   === $testname ===\n"
	$LKVM run -f $TESTDIR/gic.flat -c 4 -m 64 --irqchip gicv3-its \
		-p $testname $LKVM_DEFAULT_ARGS
}

function run_psci {
	echo -e '\n   === psci ===\n'
	$LKVM run -f $TESTDIR/psci.flat -c $NCPUS -m 64 $ARCH_ARG $IRQCHIP_ARG $LKVM_DEFAULT_ARGS
}

function run_timer {
	echo -e '\n   === timer ===\n'
	$LKVM run -f $TESTDIR/timer.flat -c 1 -m 64 $IRQCHIP_ARG $LKVM_DEFAULT_ARGS
}

function run_micro_bench {
	echo -e '\n   === micro-bench ===\n'
	$LKVM run -f $TESTDIR/micro-bench.flat -c 2 -m 256 $IRQCHIP_ARG $LKVM_DEFAULT_ARGS
}

function run_cache {
	echo -e '\n   === cache ===\n'
	$LKVM run -f $TESTDIR/cache.flat -c 1 -m 64 $IRQCHP_ARG $LKVM_DEFAULT_ARGS
}

function run_debug_test {
	testname="$1"
	echo -e "\n   === $testname ===\n"
	$LKVM run -k $TESTDIR/debug.flat -c 1 -m 64 $IRQCHIP_ARG \
		--pmu -p "$testname" $LKVM_DEFAULT_ARGS
}

TESTDIR=arm

GIC=""
ARCH=""
while getopts "a:g:" option; do
	case "${option}" in
		a) ARCH=${OPTARG};;
		g) GIC=${OPTARG};;
		?)
			exit 1
			;;
	esac
done

IRQCHIP_ARG=""
ARCH_ARG=""

if [[ -n "$ARCH" ]]; then
	if [[ "$ARCH" != "arm64" ]] && [[ "$ARCH" != "arm" ]]; then
		echo "Invalid 'ARCH' parameter given: '$ARCH'"
		exit 1
	fi
	if [[ "$ARCH" = "arm" ]]; then
		ARCH_ARG="--aarch32"
		TESTDIR=$AARCH32_TESTDIR
	fi
fi
if [[ -n "$GIC" ]]; then
	if [[ "$GIC" != "gicv2" ]] && [[ "$GIC" != "gicv3" ]] && \
		"$GIC" != "gicv3-its" && "$GIC" != "gicv2m" ]]; then
		echo "Invalid 'GIC' parameter given: '$GIC'"
		exit 1
	fi
	IRQCHIP_ARG="--irqchip=$GIC"
fi

run_selftest_setup
run_vectors_kernel
run_vectors_user
run_selftest_smp

run_pmu_cycle_counter
if [[ "$ARCH" != "arm" ]]; then
	run_pmu_test pmu-event-introspection
	run_pmu_test pmu-event-counter-config
	run_pmu_test pmu-basic-event-count
	run_pmu_test pmu-mem-access
	run_pmu_test pmu-mem-access-reliability
	run_pmu_test pmu-sw-incr
	run_pmu_test pmu-chained-counters
	run_pmu_test pmu-chained-sw-incr
	run_pmu_test pmu-chain-promotion
	run_pmu_test pmu-overflow-interrupt
fi

run_gicv2_ipi
run_gicv2_mmio
run_gicv2_mmio_up
run_gicv2_mmio_3p
run_gicv3_ipi
run_gicv2_active
run_gicv3_active

if [[ "$ARCH" != "arm" ]]; then
	run_its_test its-introspection
	run_its_test its-trigger
	run_its_test its-migration
	run_its_test its-pending-migration
	run_its_test its-migrate-unmapped-collection
fi

run_psci

if [[ "$ARCH" != "arm" ]]; then
	run_timer
	run_micro_bench
	run_cache

	run_debug_test bp
	run_debug_test bp-migration
	run_debug_test wp
	run_debug_test wp-migration
	run_debug_test ss
	run_debug_test ss-migration
fi
