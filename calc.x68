	ORG	$2500
CNT	DC.B	'Continue? (y)'
	ORG	$3000
MSG	DC.B	'Enter two whole numbers seperated by an operator, assigned vars can be used:'
	ORG	$4000
VAR	DC.B	'Assign to var?'

START	ORG	$1000
	LEA	$3000,A1	set addr of banner str
	MOVEQ	#76,D1		set banner len
	MOVEQ	#0,D0		set trap for disp str
	TRAP	#15		disp banner
	MOVEA	#0,A1		reset A1
	LEA	$1000,A6	get addr of user mem
	MOVEQ	#2,D0		set trap for str in
REPEAT	TRAP	#15		get str
	MOVEA.L	#0,A0		reset A0
	SUBQ	#2,D1		offset str len
READC	MOVE.B	(A0)+,D0	get next char
	CMP.B	#$30,D0		is this a number?
	BLT	OPRND		if not, test for opr8r
	CMP.B	#$60,D0		is this a ltr?
	BGT	GETV		retreive var
	SUBI	#$30,D0		get dec equiv
GOTV	MOVE.B	D0,(A6)+	push onto mem
	DBRA	D1,READC	repeat
	JMP	(A4)		pointer to calling sub (set by sub)

OPRND	IF.B D0 <EQ> #$2D THEN	is the operator "-"
	BRA SUBFUN
	ENDI
	IF.B D0 <EQ> #$2B THEN	is the operator "+"
	BRA ADDFUN
	ENDI
	IF.B D0 <EQ> #$2A THEN	is the operator "*"
	BRA MULFUN
	ENDI
	IF.B D0 <EQ> #$2F THEN	is the operator "/"
	BRA DIVFUN
	ENDI
	RTS

ADDFUN	LEA	ADDFUN,A4	set return addr
	ADDA	#12,A4		offset (3*4) to set return
	JSR	READC		get next character
	MOVE.B	(-2,A6),D0	retrieve operand 1
	ADD.B	(-1,A6),D0	add operand 2
	BRA	DONE		for now!

SUBFUN	LEA	SUBFUN,A4	set return addr
	ADDA	#12,A4		offset (3*4) to set return 
	JSR	READC		get next character
	MOVE.B	(-2,A6),D0	retrieve operand 1
	SUB.B	(-1,A6),D0	subtract operand 2
	BRA	DONE		for now!

MULFUN	LEA	MULFUN,A4	set return addr
	ADDA	#12,A4		offset (3*4) to set return
	JSR	READC		get next character
	CLR.W	D1		cleanup...this will be handle by seperate routine
	MOVE.B	(-2,A6),D0	retrieve operand 1
	MOVE.B	(-1,A6),D1	retrieve operand 2
	MULU	D1,D0		return here and multiply
	BRA	DONE		now disp	

DIVFUN	LEA	DIVFUN,A4	set return addr
	ADDA	#12,A4		offset (3*4) to set return
	JSR	READC		get next character
	CLR.W	D1	
	MOVE.B	(-2,A6),D0	retrieve operand 1
	MOVE.B	(-1,A6),D1	retrieve operand 2
	MOVEQ	#10,D2		assume ops are < 10
	DIVU	D1,D2		
	MULU	D2,D0
	DIVU	#10,D0		GET FIRST DIGIT
	MOVE.B	D0,D1		STORE IN D1
	SWAP	D0		GET SECOND DIG
	CMP.B	#5,D0		IS SEC DIG >= 5
	BLT	RND		IF NOT, ROUND DOWN
	ADDQ	#1,D1		ROUND UP
RND	MOVE.B	D1,D0		RESTORE	
	BRA	DONE		now disp

DONE	MOVE.W	D0,D1		move for disp
	MOVEQ	#3,D0		set trap
	TRAP	#15		disp result
	MOVE.W	D1,D6		get copy of result
	MOVEQ	#3,D1		incr line cnt
	MOVEQ	#11,D0		set D0 for pos
	TRAP	#15		next disp line
	BRA	ASSV		assign result to var?

RETV	MOVEQ	#5,D1
	MOVEQ	#11,D0
	TRAP	#15
	LEA	$2500,A1	get addr continue str
	MOVEQ	#13,D1		set len
	MOVEQ	#0,D0		set trap
	TRAP	#15		continue?
	MOVEQ	#5,D0		set trap
	TRAP	#15		get resp
	CMP.B	#$79,D1		is resp y?
	BNE	QUIT
	MOVE.W	#$FF00,D1	clrscr val
	MOVEQ	#11,D0		clrscr
	TRAP	#15		clear scrn
	LEA	$0,A1

CLEAN	CLR.L	D0		begin reset DR
	CLR.L	D1		.
	CLR.L	D2		.
	CLR.L	D3		.
	CLR.L	D4		.
	CLR.L	D5		.
	CLR.L	D6		.
	CLR.L	D7		end reset DR
	MOVEA	A5,A1		begin reset addr
	MOVEA	A5,A2		.		
	MOVEA	A5,A3		.
	MOVEA	A5,A4		.
	MOVEA	A5,A6		end reset addr
	MOVEQ	#2,D0		
	BRA	REPEAT		start over

ASSV	LEA	$4000,A1	get addr of var prompt
	MOVEQ	#14,D1		get msg len
	MOVEQ	#0,D0		set trap
	TRAP	#15		disp var?
	MOVEQ	#5,D0		set trap
	TRAP	#15		get response
	ADDA	D1,A2 		incr addr offset
	MOVE.B	D6,(A2)		put value in var store
	MOVEA	A5,A2		restore addr
	BRA	RETV		go back

GETV	ADDA	D0,A2		get offset for var
	MOVE.B	(A2),D0		put the val in D0
	MOVEA	A5,A2		restore addr
	BRA	GOTV

QUIT	STOP	#$2000
	END	START
