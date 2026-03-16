/* SPDX-License-Identifier: GPL-2.0 */
/*
 * Copyright (C) 2022 Arm Limited.
 * All rights reserved.
 */
#ifndef __SMC_RSI_H_
#define __SMC_RSI_H_

/*
 * This file describes the Realm Services Interface (RSI) Application Binary
 * Interface (ABI) for SMC calls made from within the Realm to the RMM and
 * serviced by the RMM.
 */

#define SMC_RSI_CALL_BASE		0xC4000190

#define RSI_ABI_VERSION_MAJOR		1
#define RSI_ABI_VERSION_MINOR		0

#define RSI_ABI_VERSION			((RSI_ABI_VERSION_MAJOR << 16) | \
					 RSI_ABI_VERSION_MINOR)

#define RSI_ABI_VERSION_GET_MAJOR(_version) ((_version) >> 16)
#define RSI_ABI_VERSION_GET_MINOR(_version) ((_version) & 0xFFFF)

#define RSI_SUCCESS			0
#define RSI_ERROR_INPUT			1
#define RSI_ERROR_STATE			2
#define RSI_INCOMPLETE			3
#define RSI_ERROR_COUNT			4

#define RSI_HASH_SHA_256		0
#define RSI_HASH_SHA_512		1


#define SMC_RSI_FID(_x)			(SMC_RSI_CALL_BASE + (_x))

/*
 * Returns whether the requested RSI version is compatible.
 * arg1: Requested interface version.
 * ret0: RSI_SUCCESS / RSI_ERROR_INPUT
 * ret1: Lower implemented interface version
 * ret2: Higher implemented interface version
 */
#define SMC_RSI_ABI_VERSION			SMC_RSI_FID(0)

/*
 * Returns RSI features.
 * arg1: Feature register index
 * ret0: Status
 * ret1: Feature register value
 */
#define SMC_RSI_FEATURES			SMC_RSI_FID(1)


/*
 * Returns a measurement
 * arg1 == Index (0..4), which measurement (RIM or REM) to read
 * ret0 == Status / error
 * ret1 == Measurement value, bytes:  0 -  7
 * ret2 == Measurement value, bytes:  7 - 15
 * ret3 == Measurement value, bytes: 16 - 23
 * ret4 == Measurement value, bytes: 24 - 31
 * ret5 == Measurement value, bytes: 32 - 39
 * ret6 == Measurement value, bytes: 40 - 47
 * ret7 == Measurement value, bytes: 48 - 55
 * ret8 == Measurement value, bytes: 56 - 63
 */
#define SMC_RSI_MEASUREMENT_READ		SMC_RSI_FID(2)

/*
 * Extend a Realm Exetendable measurement.
 * arg1  == Index (1..4), which measurement (REM) to extend
 * arg2  == Size of realm measurement in bytes, max 64 bytes
 * arg3  == Measurement value, bytes:  0 -  7
 * arg4  == Measurement value, bytes:  7 - 15
 * arg5  == Measurement value, bytes: 16 - 23
 * arg6  == Measurement value, bytes: 24 - 31
 * arg7  == Measurement value, bytes: 32 - 39
 * arg8  == Measurement value, bytes: 40 - 47
 * arg9  == Measurement value, bytes: 48 - 55
 * arg10 == Measurement value, bytes: 56 - 63
 * ret0  == Status / error
 */
#define SMC_RSI_MEASUREMENT_EXTEND		SMC_RSI_FID(3)

/*
 * Initialise the operation to retrieve an attestation token
 * arg1 == Challenge value, bytes:  0 -  7
 * arg2 == Challenge value, bytes:  7 - 15
 * arg3 == Challenge value, bytes: 16 - 23
 * arg4 == Challenge value, bytes: 24 - 31
 * arg5 == Challenge value, bytes: 32 - 39
 * arg6 == Challenge value, bytes: 40 - 47
 * arg7 == Challenge value, bytes: 48 - 55
 * arg8 == Challenge value, bytes: 56 - 63
 * ret0 == Status / error
 * ret1 == Upper bound of the token in bytes
 */
#define SMC_RSI_ATTEST_TOKEN_INIT		SMC_RSI_FID(4)

/*
 * Continue the operation to retrieve an attestation token
 * arg1 == The IPA of token buffer
 * arg2 == Offset within the from the beginning of @arg1
 * arg3 == Space available from @arg2 in the buffer.
 * ret0 == Status / error
 * ret1 == Size of completed token in bytes
 */
#define SMC_RSI_ATTEST_TOKEN_CONTINUE		SMC_RSI_FID(5)



#ifndef __ASSEMBLY__

struct rsi_realm_config {
	union {
		struct {
			/* Width of IPA in bits */
			unsigned long ipa_width;
			/* Hash algorithm */
			unsigned long algorithm;
		};
		unsigned char __reserved0[0x1000];
	};
	/* Offset 0x1000 */
};

#endif /* __ASSEMBLY__ */

/*
 * arg0 == struct rsi_realm_config addr
 */
#define SMC_RSI_REALM_CONFIG			SMC_RSI_FID(6)

/*
 * arg0 == IPA address of target region
 * arg1 == size of target region in bytes
 * arg2 == RIPAS value
 * arg3 == RipasChangeFlags
 * ret0 == Status / error
 * ret1 == Top of modified IPA range
 */
#define RSI_NO_CHANGE_DESTROYED			0
#define RSI_CHANGE_DESTROYED			1

#define SMC_RSI_IPA_STATE_SET			SMC_RSI_FID(7)

/*
 * Get the IPA state for the given IPA
 * arg0 == IPA
 * ret0 == Status/error
 * ret1 == RIPAS value.
 */
#define SMC_RSI_IPA_STATE_GET			SMC_RSI_FID(8)

#define RSI_HOST_CALL_NR_GPRS			31

#ifndef __ASSEMBLY__

struct rsi_host_call {
	unsigned int imm;
	unsigned long gprs[RSI_HOST_CALL_NR_GPRS];
};

#endif /* __ASSEMBLY__ */

/*
 * arg0 == struct rsi_host_call addr
 */
#define SMC_RSI_HOST_CALL			SMC_RSI_FID(9)

#endif /* __SMC_RSI_H_ */
