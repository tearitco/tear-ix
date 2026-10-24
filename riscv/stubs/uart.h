#ifndef UART_H
#define UART_H

#include <stdint.h>
#include "trap.h"

#define UART_RX_FIFO 128

typedef struct UART {
    uint8_t rhr[UART_RX_FIFO];
    int rh_head;
    int rh_tail;
    int rh_count;
    uint8_t ier;
    uint8_t iir;
    uint8_t lcr;
    uint8_t mcr;
    uint8_t lsr;
    uint8_t msr;
    uint8_t scr;
    uint8_t dll;
    uint8_t dlm;
    int tx_irq_pending;
    int interrupting;
} UART;

void uart_init(UART *u);
void uart_poll(UART *u);
int uart_irq_pending(UART *u);
Trap uart_load(UART *u, uint64_t addr, uint64_t bits, uint64_t *out);
Trap uart_store(UART *u, uint64_t addr, uint64_t bits, uint64_t value);
void uart_restore_term(void);

#endif
