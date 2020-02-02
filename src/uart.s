.option norvc
.data

.equ UART_ADDR, 0x10000000
.equ UART_DATA_REGISTER, 0x00
.equ UART_INTERRUPT_ENABLE_REGISTER, 0x01
.equ UART_INTERRUPT_ID_AND_FIFO_CTRL_REGISTER, 0x02
.equ UART_LINE_CTRL_REGISTER, 0x03
.equ UART_MODEM_CTRL_REGISTER, 0x04
.equ UART_LINE_STATUS, 0x05

.text
.global _start
    _start:
        csrw mie, zero
        csrr t3, mhartid
        la t0, trap
        csrw mtvec, t0

        mv sp, zero
        mv t0, zero
        mv t1, zero
        la t1, stack

        lw t0, 0(t1)
        slli t0, t0, 32
        srli t0, t0, 32
        lw sp, 4(t1)
        slli sp, sp, 32
        or sp, sp, t0

        jal setup_uart
        la a0, msg
        li a1, 13
        jal print_message
        
        jal hcf
    hcf:
        wfi
        j hcf

    setup_uart:
        li t0, UART_ADDR

        li t1, 0x00
        sb t1, UART_INTERRUPT_ENABLE_REGISTER(t0)

        li t1, 0x80
        sb t1, UART_INTERRUPT_ID_AND_FIFO_CTRL_REGISTER(t0)

        li t1, 0x03
        sb t1, UART_DATA_REGISTER(t0)

        li t1, 0x00
        sb t1, UART_INTERRUPT_ENABLE_REGISTER(t0)

        li t1, 0x03
        sb t1, UART_LINE_CTRL_REGISTER(t0)

        li t1, 0xC7
        sb t1, UART_INTERRUPT_ID_AND_FIFO_CTRL_REGISTER(t0)

        li t1, 0x0B
        sb t1, UART_MODEM_CTRL_REGISTER(t0)
        
        ret

    # Parameters:
    #   message_address -> a0
    #   message_length -> a1
    #
    # Returns:
    #   None
    print_message:
        addi sp, sp, -24
        sd s0, 0(sp)
        sd s1, 8(sp)
        sd ra, 16(sp)

        mv s0, zero
        mv s1, zero
        
        write_loop:
            mv t5, a0
            wait_for_data:
                jal is_data_empty
                beq a0, zero, wait_for_data
            mv a0, t5
            lb s0, 0(a0)
            li t5, UART_ADDR
            sb s0, UART_DATA_REGISTER(t5)
            addi a0, a0, 1
            addi s1, s1, 1
            blt s1, a1, write_loop
            
        ld s0, 0(sp)
        ld s1, 8(sp)
        ld ra, 16(sp)
        addi sp, sp, 24
        ret

    # Parameters:
    #   None
    #
    # Returns:
    #   a0 -> 1 if the data register can be written to
    #   a0 -> 0 if the data register is not ready for writing
    is_data_empty:
        # Load line status register value
        li t0, UART_ADDR
        lb t1, UART_LINE_STATUS(t0)

        # a0 = (t1 & (1 << 6)) >> 6
        li t2, 1 << 6
        and t1, t1, t2
        srli a0, t1, 6

        ret

    # Parameters:
    #   None
    #
    # Returns:
    #   a0 -> 1 if the data register can be written to
    #   a0 -> 0 if the data register is not ready for writing
    is_data_waiting:
        # Load line status register value
        li t0, UART_ADDR
        lb t1, UART_LINE_STATUS(t0)

        # Set a0 to t1 & t2
        li t2, 1
        and a0, t1, t2

        ret

    trap:
        la a0, hcf
        mret

.section .rodata
    msg:    .string "Hello, world!"
    .equ MSG_LEN, 13
    stack:  .dword __stack
