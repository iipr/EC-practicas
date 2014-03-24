.global start

.global _ISR_STARTADDRESS

.global DoUndef
.global DoSWI
.global DoDabort

.global screen

.extern main
.extern ISR_Undef
.extern ISR_SWI
.extern ISR_FIQ
.extern ISR_Pabort
.extern ISR_Dabort 
.extern DoDetecta

.equ 	_ISR_STARTADDRESS,	0xc7fff00		/* GCS6:64M DRAM/SDRAM 	*/
.equ    UserStack,   _ISR_STARTADDRESS-0xf00         /* c7ff000 */
.equ    SVCStack,    _ISR_STARTADDRESS-0xf00+256     /* c7ff100 */
.equ    UndefStack,  _ISR_STARTADDRESS-0xf00+256*2   /* c7ff200 */
.equ    AbortStack,  _ISR_STARTADDRESS-0xf00+256*3   /* c7ff300 */
.equ    IRQStack,    _ISR_STARTADDRESS-0xf00+256*4   /* c7ff400 */
.equ    FIQStack,    _ISR_STARTADDRESS-0xf00+256*5   /* c7ff500 */

.equ    HandleReset,    _ISR_STARTADDRESS
.equ    HandleUndef,    _ISR_STARTADDRESS+4
.equ    HandleSWI,      _ISR_STARTADDRESS+4*2
.equ    HandlePabort,   _ISR_STARTADDRESS+4*3
.equ    HandleDabort,   _ISR_STARTADDRESS+4*4
.equ    HandleReserved, _ISR_STARTADDRESS+4*5
.equ    HandleIRQ,      _ISR_STARTADDRESS+4*6
.equ    HandleFIQ,      _ISR_STARTADDRESS+4*7

/* Simbolos para facilitar la codificaci�n
de los modos de ejecuci�n */
.equ 	USERMODE,	0x10
.equ 	FIQMODE,	0x11
.equ 	IRQMODE,	0x12
.equ 	SVCMODE,	0x13
.equ 	ABORTMODE,	0x17
.equ 	UNDEFMODE,	0x1b
.equ 	MODEMASK,	0x1f

.equ 	NOINT,		0xc0   /* M�scara para deshabilitar interrupciones */
.equ    IRQ_MODE,	0x40   /* deshabilitar interrupciones en modo IRQ  */
.equ    FIQ_MODE,	0x80   /* deshabilitar interrupciones en modo FIQ  */

.equ I_ISPR, 0x1e00020
.equ EXTINTPND, 0x1d20054

.equ BOTONS, 0x00200000 /* Valor de I_ISPR cuando se activa la excepci�n IRQ*/

.text

start:
    /* Si comenzamos con un reset
     el procesador esta en modo supervisor */
    bic	r0,r0,#MODEMASK
    orr	r1,r0,#SVCMODE
    msr	cpsr_cxsf,r1 	    /* SVCMode */
    /* Si comenzamos con un reset el procesador esta en modo supervisor */
    /* Si comenzamos con un reset
     el procesador esta en modo supervisor.
     Tras InitStacks DEBEMOS seguir en modo supervisor*/
    bl InitStacks
	
    /* Seguimos en modo supervisor, configuramos
       las direcciones de las rutinas de tratamiento
       de excepciones */
    bl InitISR

	@ habilitamos excepciones
	mrs r0,cpsr
	bic r0,#NOINT
	msr cpsr_cxsf,r0

    /* Pasamos a MODO USUARIO, inicializamos su pila
      y ponemos a cero el frame pointer*/
    mrs	r0,cpsr
   	bic	r0,r0,#MODEMASK
    orr	r1,r0,#USERMODE
    msr	cpsr_cxsf,r1 	    /* SVCMode */
    ldr sp,=UserStack
    mov fp,#0

    /* Saltamos a Main */
    bl main
	b .
InitStacks:
    /* C�digo de la primera parte */
	/*TAREA 1a*/
	/*El alumno/a debe realizar la inicializacion de los punteros de pila (registros SP) de los modos 
	UndefMode,  AbortMode , IRQMode , FIQMode  y  SVCMode */
	
	//Comenzamos leyendo el registro de estado
	mrs	r0,cpsr

	//Inicializamos la pila del modo Undef
	bic	r0,r0, #MODEMASK
	orr	r1,r0, #UNDEFMODE
	msr	cpsr_cxsf, r1
	ldr	sp, =UndefStack

    //Inicializamos la pila del modo Abort
	bic	r0,r0, #MODEMASK
	orr	r1,r0, #ABORTMODE
	msr	cpsr_cxsf, r1
	ldr	sp, =AbortStack

   // Inicializamos la pila del modo IRQ
	bic	r0,r0, #MODEMASK
	orr	r1,r0, #IRQMODE
	msr	cpsr_cxsf, r1
	ldr	sp, =IRQStack

   // Inicializamos la pila del modo FIQ
	bic	r0,r0, #MODEMASK
	orr	r1,r0, #FIQMODE
	msr	cpsr_cxsf, r1
	ldr	sp, =FIQStack

   // Inicializamos la pila del modo SVC
   bic	    r0,r0, #MODEMASK
   orr	    r1,r0, #SVCMODE
   msr	    cpsr_cxsf, r1
   ldr	    sp, =SVCStack
    
	/*Fin TAREA 1a*/
    mov pc, lr


//  Debemos comprobar la fuente de la interrupcion.
// Para ello habra que mirar en (INTOND o I_ISPR)??? y EXTINTPND
ISR_IRQ:
	/*TAREA 2 definir la rutina ISR_IRQ*/
	/*El alumno/a debe implementar esta rutina, que comprobara si se ha pulsado un boton, y si saltar� en caso afirmativo a la funcion DoDetecta*/
	/*Ayuda: No olvideis que esta rutina debe cargar en PC la direccion de retorno al terminar*/
	/*Ayuda: Los registros I_ISPR y EXTINTPND nos proporcionan informacion de las interrupciones pendientes de atender*/

	/*Debe preservar los registros arquitect�nicos r0-r12*/

	/* pr�logo */
	push {r0, r1, lr} @ Basta con apilar los registros modificados
		@ INCLUYENDO r0-r3 si se modifican


	/* cuerpo de la rutina */

	/*Comprobamos qu� interrupci�n hab�a habido*/
	ldr r0,=I_ISPR
	ldr r0,[r0]
	/*Cargamos el valor de I_ISPR cuando se pulsa un bot�n y es prioritario*/
	ldr r1, =BOTONS
	/* Comparamos el valor cuando se pulsa el boton con el valor actual de I_ISPR */
	cmp r0,r1
	bne epilogo
	bl DoDetecta
	/* ep�logo */

epilogo:
	pop {r0, r1, lr} @ restauramos contexto y retornamos
	subs pc,lr,#4 @ La constante a restar depende de la excepci�n


	/*Fin TAREA 2*/

InitISR:
    /* C�digo de la primera parte */
	/*TAREA 1b*/
	/*El alumno/a debe definir la tabla de direcciones de rutinas*/
	/*Ayuda: las entradas de la tabla son HandleUndef,HandleDabort, HandlePabort, HandleIRQ, HandleSWI, y HandleFIQ*/
	
	ldr r0,=ISR_Undef
	ldr r1,=HandleUndef
	str r0,[r1]

	ldr r0,=ISR_Dabort
	ldr r1,=HandleDabort
	str r0,[r1]

	ldr r0,=ISR_Pabort
	ldr r1,=HandlePabort
	str r0,[r1]

	ldr r0,=ISR_IRQ
	ldr r1,=HandleIRQ
	str r0,[r1]

	ldr r0,=ISR_SWI
	ldr r1,=HandleSWI
	str r0,[r1]

	ldr r0,=ISR_FIQ
	ldr r1,=HandleFIQ
	str r0,[r1]



	/*fin TAREA 1b*/
	mov pc,lr



DoSWI:
	swi #0
	mov pc,lr

DoUndef:
	.word 0xE6000010
	mov pc,lr

DoDabort:
	ldr r0,=0x0a333333
	str r0,[r0]
	mov pc,lr


screen:
	.space 1024

.end
