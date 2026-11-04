#define LEDS (*(volatile unsigned int *)0x0)

void _start(void) {
    int a = 2;
    int b = 3;
    asm("" : "+r"(a));      // não gera instrução, só esconde o valor
    asm("" : "+r"(b));
    LEDS = a + b;
    asm volatile("nop");
}
