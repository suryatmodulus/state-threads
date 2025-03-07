/* SPDX-License-Identifier: MIT */
/* Copyright (c) 2021 Winlin */

/* If user disable the ASM, such as avoiding bugs in ASM, donot compile it. */
#if !defined(MD_ST_NO_ASM)

#if defined(__amd64__) || defined(__x86_64__)

    /****************************************************************/

    /*
     * Internal __jmp_buf layout
     */
    #define JB_RBX  0
    #define JB_RBP  1
    #define JB_R12  2                   /* The first six integer or pointer arguments are passed in registers RDI, RSI, RDX, RCX, R8, R9. */
    #define JB_R13  3                   /* If the callee wishes to use registers RBX, RSP, RBP, and R12–R15, it must restore their original values before returning control to the caller. */
    #define JB_R14  4                   /* @see https://en.wikipedia.org/wiki/X86_calling_conventions */
    #define JB_R15  5                   /* @see https://www.cnblogs.com/Five100Miles/p/8458561.html */
    #define JB_RSP  6
    #define JB_PC   7

    .file "md_darwin.S"
    .text

    /* _st_md_cxt_save(__jmp_buf env) */ /* The env is rdi, https://en.wikipedia.org/wiki/X86_calling_conventions */
    .globl __st_md_cxt_save
        .align 16
    __st_md_cxt_save:
        /*
         * Save registers.
         */
        movq %rbx, (JB_RBX*8)(%rdi)     /* Save rbx to env[0], *(int64_t*)(rdi+0)=rbx */
        movq %rbp, (JB_RBP*8)(%rdi)     /* Save rbp to env[1], *(int64_t*)(rdi+1)=rbp */
        movq %r12, (JB_R12*8)(%rdi)     /* Save r12 to env[2], *(int64_t*)(rdi+2)=r12 */
        movq %r13, (JB_R13*8)(%rdi)     /* Save r13 to env[3], *(int64_t*)(rdi+3)=r13 */
        movq %r14, (JB_R14*8)(%rdi)     /* Save r14 to env[4], *(int64_t*)(rdi+4)=r14 */
        movq %r15, (JB_R15*8)(%rdi)     /* Save r15 to env[5], *(int64_t*)(rdi+5)=r15 */
        /* Save SP */
        leaq 8(%rsp), %r8              /* Save *(int64_t*)(rsp+8) to r8, https://github.com/ossrs/state-threads/issues/11#issuecomment-888709759 */
        movq %r8, (JB_RSP*8)(%rdi)     /* Save r8(rsp) to env[6], *(int64_t*)(rdi+6)=r8 */
        /* Save PC we are returning to */
        movq (%rsp), %r9               /* Save PC(parent function address) %(rsp) to r9 */
        movq %r9, (JB_PC*8)(%rdi)      /* Save r9(PC) to env[7], *(int64_t*)(rdi+7)=r9 */
        xorq %rax, %rax                 /* Reset rax to 0 */
        ret


    /****************************************************************/

    /* _st_md_cxt_restore(__jmp_buf env, int val) */ /* The env is rdi, val is esi/rsi, https://en.wikipedia.org/wiki/X86_calling_conventions */
    .globl __st_md_cxt_restore
        .align 16
    __st_md_cxt_restore:
        /*
         * Restore registers.
         */
        movq (JB_RBX*8)(%rdi), %rbx     /* Load rbx from env[0] */
        movq (JB_RBP*8)(%rdi), %rbp     /* Load rbp from env[1] */
        movq (JB_R12*8)(%rdi), %r12     /* Load r12 from env[2] */
        movq (JB_R13*8)(%rdi), %r13     /* Load r13 from env[3] */
        movq (JB_R14*8)(%rdi), %r14     /* Load r14 from env[4] */
        movq (JB_R15*8)(%rdi), %r15     /* Load r15 from env[5] */
        /* Set return value */          /* The esi is param1 val, the eax is return value */
        test %esi, %esi                 /*      if (!val) {         */
        mov $01, %eax                   /*          val=1;          */
        cmove %eax, %esi                /*      }                   */
        mov %esi, %eax                  /*      return val;         */
        /* Restore PC and RSP */
        movq (JB_PC*8)(%rdi), %r8      /* Load r8(PC) from env[7] */
        movq (JB_RSP*8)(%rdi), %rsp     /* Load rsp from env[6] */
        /* Jump to saved PC */
        jmpq *%r8                      /* Jump to r8(PC) */

    /****************************************************************/

#endif

#endif
