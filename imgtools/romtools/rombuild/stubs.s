@ Copyright (c) 1999-2009 Nokia Corporation and/or its subsidiary(-ies).
@ All rights reserved.
@ This component and the accompanying materials are made available
@ under the terms of the License "Eclipse Public License v1.0"
@ which accompanies this distribution, and is available
@ at the URL "http://www.eclipse.org/legal/epl-v10.html".
@
@ Initial Contributors:
@ Nokia Corporation - initial contribution.
@
@
@ Description:
@ DLL Stub routines
@ Compile with "gcc -c -Wa,-adhln stubs.s"
@
.text
	.code 32
	.globl  arm4_stub
arm4_stub:
	ldr     ip, [pc]
	ldr     pc, [ip]
	.word   0x11223344  @ address in IAT/edata

	.code 32
	.globl  armi_stub
armi_stub:
	ldr     ip, [pc, #4]
	ldr     pc, [ip]
	bx      ip
	.word   0x11223344  @ address in IAT/edata

	.code 16
	.globl  thumb_stub
thumb_stub:
	push    {r6}
	ldr     r6, [pc, #8]
	ldr     r6, [r6]
	mov     ip, r6
	pop     {r6}
	bx      ip
	.word   0x11223344	@ address in IAT/edata

	.code 16
	.globl  thumb_r3unused_stub
thumb_r3unused_stub:
	ldr     r3, [pc, #4]
	ldr     r3, [r3]
	bx      r3
	nop
	.word   0x11223344	@ address in IAT/edata


@ In-place rewrites if destination address
@ is fixed
@
	.code 32
	.globl  fast_armi_stub
fast_armi_stub:
	ldr     ip, [pc, #4]
	bx      ip
	.word   0           @ nop
	.word   0x50515253  @ destination address

	.code 16
	.globl  fast_thumb_stub
fast_thumb_stub:
	push    {r6}
	ldr     r6, [pc, #8]
	mov     ip, r6
	pop     {r6}
	bx      ip
	nop
	.word   0x50515253  @ destination address

	.code 16
	.globl  fast_thumb_r3unused_stub
fast_thumb_r3unused_stub:
	ldr     r3, [pc, #4]
	bx      r3
	nop
	nop
	.word   0x50515253  @ destination address



