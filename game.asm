##################################################################### 
#
# CSCB58 Winter 2021 Assembly Final Project
# University of Toronto, Scarborough
#
# Student: Shengsong Xu, 1005788970, Xushengs
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8 (update this as needed)
# - Unit height in pixels: 8 (update this as needed)
# - Display width in pixels: 256 (update this as needed)
# - Display height in pixels: 256 (update this as needed)
# - Base Address for Display: 0x10008000 ($gp) 
#
# Which milestones have been reached in this submission?
# (See the assignment handout for descriptions of the milestones)
# - Milestone 4 (choose the one the applies)
#
# Which approved features have been implemented for milestone 4?
# (See the assignment handout for the list of additional features)
# 1. Increase in difficulty as game progresses. Difficulty can be achieved by making things faster, adding more obstacles
# 2. Smooth graphics: prevent flicker by carefully erasing and/or redrawing only the parts to the frame buffer that have changed
# 3. Player can use special skill that can slow down time, three times per game.
# 4. Improved control system: only need to press movement key once, then ship will continually move towards that direction, 
# press keys other than p, w, a, s, d, e to stop the ship 
#
# Link to video demonstration for final submission:
# - https://www.youtube.com/watch?v=7sUfFJ8aa7g
#
# Are you OK with us sharing the video with people outside course staff?
# - yes
#
# Any additional information that the TA needs to know:
# - I have built a scoring system and can show the score on the game-over screen once finished the function: ShowScore.
# I did not have time to finish the score feature for this assignment. But you can see the pseudocode I wrote for future coding. 
# #####################################################################


.eqv Width 		32
.eqv Height		32
.eqv Dis_add	0x10008000
.eqv KBD_Base		0xffff0000
.eqv InitPos		1936
.eqv LastP		4092		
# Color lists
.eqv Black		0x00000000
.eqv Red		0x00E74C3C
.eqv LRed		0x00EC7063
.eqv DGrey		0x00515A5A
.eqv LGrey		0x00839192
.eqv Blue		0x005DADE2
.eqv Purple		0x00A569BD  
# a, w, d, s, p
.eqv A			0x61
.eqv D			0x64
.eqv S			0x73
.eqv W			0x77
.eqv P			0x70
.eqv E 			0x65
# Game setiing
.eqv healthV		59
.eqv Tinterval		40
.eqv Slow		100
.eqv SlowT		50
.eqv First		1824	
.eqv Second		1840
.eqv Third 		1856
.eqv Fourth		1872

.data 
	CurrPos:	.word	0		# CurrPos = (y*Width + x)*4, Current position of the ship
						# Index (0, 0) <= (x, y) <= (31, 31): (y*Width + x)*4
						# x = (index/4)%Width	ie: Remainder
						# y = (index/4)/Width	ie: Integer Devision
	ObstPos:	.word	-1:10	        # Position of obstacles
	ObstSpeed:	.word   0: 10	        # Speed of obstacles, slow if <= 4; o/w fast
	Health:		.word	50		# Max Health of the ship
	Instruction:	.word 	0		# A = -4, W = -128, S = 128, D = 4
	TimeCount:	.word	0		# increase by after one every iteration
	Level:		.word 	5		# from easy to hard: 5 -> 20
	ObstAmount:	.word   3		# current number of obstacles 
	IfHit:		.word   0		# if the obstacles hit the ship
	SlowMotion:	.word   3		# number of slow motion skill left
	SlowMotionT:	.word   50		# slow motion time
	IfSlowMotion:	.word   0		# if in slow motion

.globl main	
.text

# Initialize the state of the game
# $s0 - $s2 <- tempVar
Initialize:
	jal ClearScreen
	
	# build ship at InitPos
	li $s0, InitPos
	# Update the CurrPos
	la $s1, CurrPos
	sw $s0, 0($s1)
	# push InitPos to the stack
	addi $sp, $sp, -4
	sw $s0, 0($sp)
	# call BuildShip
	jal BuildShip
	
	# initialize health to healthV
	la $s0, Health
	li $s1, healthV
	sw $s1, 0($s0)
	# show Health bar
	li $s0, Dis_add
	li $s3, Red
	sw $s3, 0($s0)
	sw $s3, 4($s0)
	sw $s3, 8($s0)
	sw $s3, 12($s0)
	sw $s3, 16($s0)
	
	# initialize time to 0
	la $s0, TimeCount
	li $s1, 0
	sw $s1, 0($s0)
	
	# initialize Level to 5
	la $s0, Level
	li $s1, 5
	sw $s1, 0($s0)
	
	# initialize ObstAmount to 3
	la $s0, ObstAmount
	li $s1, 2
	sw $s1, 0($s0)
	
	# initialize IfHit to 0
	la $s0, IfHit
	li $s1, 0
	sw $s1, 0($s0)
	
	# initialize SlowMotion to 3
	la $s0, SlowMotion
	li $s1, 3
	sw $s1, 0($s0)
	# show SlowMotion
	li $s0, Dis_add
	li $s3, Purple
	sw $s3, 124($s0)
	sw $s3, 116($s0)
	sw $s3, 108($s0)
	
	# initialize SlowMotionT to SlowT
	la $s0, SlowMotionT
	li $s1, SlowT
	sw $s1, 0($s0)
	
	# initialize IfSlowMotion to 0
	la $s0, IfSlowMotion
	li $s1, 0
	sw $s1, 0($s0)
	
	# build obstacles
	li $t1, 0
	la $t2, ObstAmount
	lw $t2, 0($t2)
	ObstLoop:
		# push i to the stack
		addi $sp, $sp, -4
		sw $t1, 0($sp)
		jal BuildObst
		beq $t1, $t2, WaitStart
		addi $t1, $t1, 1
		j ObstLoop

WaitStart:
	# Press P to start the game
	li $t0, KBD_Base
	lw $t1, 0($t0)
	beq $t1, 1, Start
	
Start:
	lw $t1, 4($t0)		# get the input
	beq $t1, S, main
	j WaitStart

# $t0 <- kBD_Base
# $t1 <- contents of KBD_Base
# $t2 <- Instruction
# $t3 <- x or y
# $t4 <- CurrPos
# $s0 - $s3 <- tempVar

main:
# remove the hit affect
	li $t0, Dis_add
	la $t1, CurrPos
	lw $t1, 0($t1)
	add $t1, $t1, $t0	# $t1 = Dis_add + CurrPos
	li $s0, Black
	sw $s0, -128($t1)
	sw $s0, 128($t1)
	sw $s0, 4($t1)
	sw $s0, -4($t1)
# Redraw ship at CurrPos
	jal BuildShip
# show Health
	jal ShowHealth
# Check for keyboard input and update ship location.
	# wait for input
	li $t0, KBD_Base
	lw $t1, 0($t0)
	beq $t1, 1, KBD_happened
        # j ObstLocation
	
KBD_happened:
	lw $t1, 4($t0)		# get the input
	la $t4, CurrPos		# $t4 = CurrPos
	lw $t4, 0($t4)
	li $s0, 32		# $s0 = 32
	beq $t1, A, input_A
	beq $t1, W, input_W
	beq $t1, S, input_S
	beq $t1, D, input_D
	beq $t1, E, input_E
	beq $t1, P, Initialize	#restart the game
	j ObstLocation
	
	# Move the ship and check if move is valid
	
	input_A:
	# check if move right is valid by calculate x = (CurrPos/4)%32
	srl $t4, $t4, 2		# divide CurrPos by 4
	divu $t4, $s0		# divide (CurrPos/4) by 32
	mfhi $t3		# $t3 = x
	beq $t3, 1, ObstLocation	
	la $t2, Instruction	#valid move, move ship
	li $s0, -4
	sw $s0, 0($t2)
	jal MoveShip
	j ObstLocation
	
	input_W:
	srl $t4, $t4, 2		# divide CurrPos by 4
	divu $t4, $s0		# divide (CurrPos/4) by 32
	mflo $t3		# $t3 = y
	beq $t3, 2, ObstLocation	
	la $t2, Instruction	#valid move, move ship
	li $s0, -128
	sw $s0, 0($t2)
	jal MoveShip
	j ObstLocation
	
	input_S:
	srl $t4, $t4, 2		# divide CurrPos by 4
	divu $t4, $s0		# divide (CurrPos/4) by 32
	mflo $t3		# $t3 = y
	beq $t3, 30, ObstLocation
	la $t2, Instruction	#valid move, move ship
	li $s0, 128
	sw $s0, 0($t2)
	jal MoveShip
	j ObstLocation
	
	input_D:
	srl $t4, $t4, 2		# divide CurrPos by 4
	divu $t4, $s0		# divide (CurrPos/4) by 32
	mfhi $t3		# $t3 = x
	beq $t3, 30, ObstLocation	
	la $t2, Instruction	#valid move, move ship
	li $s0, 4
	sw $s0, 0($t2)
	jal MoveShip
	j ObstLocation
	
	input_E:
	# slow motion
	# check if SlowMotion > 0
	la $s0, SlowMotion
	lw $s1, 0($s0)
	beqz $s1, ObstLocation
	# check if currently in IfSlowMotion
	la $s2, IfSlowMotion
	lw $s3, 0($s2)
	beq $s3, 1, ObstLocation
	# Update IfSlowMotion and SlowMotion
	addi $s1, $s1, -1
	sw $s1, 0($s0)
	li $s3, 1
	sw $s3, 0($s2)
	li $s3, Dis_add
	li $s4, Black
	# show SlowTime bar
	sll $s1, $s1, 3
	add $s3, $s3, $s1
	sw $s4, 108($s3)
	
# Update obstacle location.
# $t1 <- i
# $t2 <- ObstPos
# $t3 <- ObstPos[i]
# $s0 <- tempVar

ObstLocation:
	li $t1, 0	# i = 0
	la $t4, ObstAmount
	lw $t4, 0($t4)
	Loop1:
		# push i to the stack
		addi $sp, $sp, -4
		sw $t1, 0($sp)
		# access ObstPos[i]
		la $t2, ObstPos 
		sll $s0, $t1, 2		# $s0 = 4*i
		add $t2, $t2, $s0	# $t2 = ObstPos + 4*i
		lw $t3, 0($t2)		# $t3 = ObstPos[i]
		
		# if ObstPos[i] == -1: call BuildObst
		beq $t3, -1, Call_buildObst
		
		# else call MoveObst
		jal MoveObst
	IncreaseI:
		beq $t1, $t4, Detect_Collision
		addi $t1, $t1, 1
		j Loop1
		
		Call_buildObst:
			jal BuildObst
			j IncreaseI
	
	
# Check for various collisions (e.g., between ship and obstacles).
# $t1 <- i
# $t2 <- ObstPos
# $t3 <- ObstPos[i]
# $t4 <- ObstAmount
# $t5 <- Xs
# $t6 <- Ys
# $t7 <- Xo, Xo - Xs
# $t8 <- Ys, Yo - Ys
# $t9 <- tempVar
# $s0 <- 32
Detect_Collision:
	# set i = 0
	li $t1, 0	# i = 0
	la $t4, ObstAmount
	lw $t4, 0($t4)
	# acsess CurrPos, $t9 = CurrPos
	la $t9, CurrPos
	lw $t9, 0($t9)	
	# calculate Xs, Ys
	li $s0, 32
	srl $t5, $t9, 2		# divide CurrPos by 4
	divu $t5, $s0		# divide (CurrPos/4) by 32
	mfhi $t5		# $t5 = Xs
	mflo $t6		# $t6 = Ys
	# for each ObstPos:
	Loop2:
		# access ObstPos[i]
		la $t2, ObstPos 
		sll $s0, $t1, 2		# $s0 = 4*i
		add $t2, $t2, $s0	# $t2 = ObstPos + 4*i
		lw $t3, 0($t2)		# $t3 = ObstPos[i]
		# Calculate Xo, Yo of ObstPos[i]
		li $s0, 32
		srl $t7, $t3, 2		# divide ObstPos[i] by 4
		divu $t7, $s0		# divide (ObstPos[i]/4) by 32
		mfhi $t7		# $t7 = Xo
		mflo $t8		# $t8 = Yo
		# Calculate $t7 = Xo - Xs
		sub $t7, $t7, $t5
		# Calculate $t8 = Yo - Ys
		sub $t8, $t8, $t6
		# if $t7 > 2: j Updata_status
		bgt $t7, 3, Increase2
		# if $t7 < 0: j Update_status
		blt $t7, -1, Increase2
		# if $t8 > 1: j Updata_status
		bgt $t8, 2, Increase2
		# if $t8 < -1: j Update_status
		blt $t8, -2, Increase2
		# else: IfHit = 1
		la $s0, IfHit
		li $t9, 1
		sw $t9, 0($s0)
		# Increase i
	Increase2:
		beq $t1, $t4, Updata_status
		addi $t1, $t1, 1
		j Loop2
		
		
# Update other game state and end of game: Health; Level; TimeCount
# $s0 <- IfHit, color
# $s1 <- tempvar
# $t0 <- Dis_add
# $t1 <- CurrPos
# $t2 <- Health
Updata_status:
	# show hit effect
	la $s0, IfHit
	lw $s0, 0($s0)
	bne $s0, 1, NotHit
	# load Dis_add
	li $t0, Dis_add
	la $t1, CurrPos
	lw $t1, 0($t1)
	add $t1, $t1, $t0	# $t1 = Dis_add + CurrPos
	# draw effect
	li $s0, Red
	sw $s0, 0($t1)
	sw $s0, -128($t1)
	sw $s0, 128($t1)
	sw $s0, 4($t1)
	sw $s0, -4($t1)
	
NotHit:
	# access IfHit
	la $s0, IfHit
	lw $s0, 0($s0)
	# access Health
	la $t2, Health
	lw $t2, 0($t2)
	# Update Health
	sub $s1, $t2, $s0	# $s1 = Health - IfHit
	# sub $s1, $t2, 0	# for testing
	la $t2, Health
	sw $s1, 0($t2)
	beqz $s1, GameOver
	# reset IfHit = 0
	la $s0, IfHit
	li $s1, 0
	sw $s1, 0($s0)
	
	# access TimeCount: don't change $s0, $s1
	la $s0, TimeCount
	lw $s1, 0($s0)
	# calculate TimeCount % 15000
	li $t0, 500
	divu $s1, $t0
	mfhi $t0
	# Check if need to Update Level and ObstAmount
	beqz $s1, Sleep
	bnez $t0, Sleep
	# check if reach the highest ObstAmount
	la $t1, Level
	lw $t3, 0($t1)
	addi $t3, $t3, 1
	sw $t3, 0($t1)	# Level ++
	# access ObstAmount
	la $t1, ObstAmount
	lw $t3, 0($t1)
	beq $t3, 7, Sleep
	addi $t3, $t3, 1
	sw $t3, 0($t1)
	
Sleep:
	# Update TimeCount
	addi $s1, $s1, 1
	sw $s1, 0($s0)
	# check IfSlowMotion
	la $t1, IfSlowMotion
	lw $t2, 0($t1)
	beq $t2, 0, NormalSleep
	# check SlowMotionT == 0
	la $t3, SlowMotionT
	lw $t4, 0($t3)
	beqz $t4, UpdateSlowMotion
	# in SlowMotion, update SlowMotionT
	addi $t4, $t4, -1
	sw $t4, 0($t3)
	# Sleep in SlowMotion
	li $v0, 32
	li $a0, Slow
	syscall
	# iterate again
	j main
UpdateSlowMotion:
	# reset SlowMotionT
	li $s2, SlowT
	sw $s2, 0($t3)
	# reset IfSlowMotion
	li $s2, 0
	sw $s2, 0($t1)
NormalSleep:
	# Sleep for Tinterval seconds.
	li $v0, 32
	li $a0, Tinterval
	syscall
	# Iterate again
	j main
	
# GameOver: show final score: TimeCount/10, 
GameOver:
	li $s0, 0	#i = 0
	li $s1, LRed
	li $s2, Dis_add
	Loop4:
		bgt $s0, LastP, SScore	#if (i > LastP): Return
		sw $s1, 0($s2)
		addi $s0, $s0, 4	#i =+ 4
		addi $s2, $s2, 4	
		j Loop4
SScore:
	# load TimeCount
	la $s0, TimeCount
	lw $s1, 0($s0)
	# TimeCount / 8
	# $v0 = TimeCount / 8
	srl $v0, $s1, 3
	# jal ShowScore	

Restart:
	li $t0, KBD_Base
	lw $t1, 0($t0)
	beq $t1, 1, Restart_happen
	# j DebugEND
	
Restart_happen:
	lw $t1, 4($t0)		# get the input
	beq $t1, P, Initialize
	j Restart
	
DebugEND:
	li $v0, 1
	la $t0, TimeCount
	lw $t0, 0($t0)
	move $a0, $t0
	syscall 
	li $v0, 10
	syscall 		
	
	
	
	
	
	
# Functions are here:	
	
#Function: void ClearScreen(), Empty the Entire Screen
ClearScreen:
	li $s0, 0	#i = 0
	li $s1, Black
	li $s2, Dis_add
	Loop:
		bgt $s0, LastP, Return	#if (i > LastP): Return
		sw $s1, 0($s2)
		addi $s0, $s0, 4	#i =+ 4
		addi $s2, $s2, 4	
		j Loop
	Return:
		jr $ra
	
#Function: void BuildShip()	
# $s0 <- CurrPos (make sure is valid) ie: 1 <= x <= 20, 1 <= y <= 30
# $s1 <- dis_add
# $s2 <- color
BuildShip:
	# get CurrPos
	la $s0, CurrPos
	lw $s0, 0($s0)
	# build the ship
	li $s1, Dis_add
	add $s1, $s1, $s0
	# pick red
	li $s2, Purple
	sw $s2, 0($s1)
	li $s2, Blue
	sw $s2, -124($s1)
	sw $s2, -132($s1)
	sw $s2, 132($s1)
	sw $s2, 124($s1)
	jr $ra
	
	
# function: void MoveShip() fetch Instruction and CurrPos, Make Sure move is valid
# $s0 <- tempVar
# $s1 <- Instruction
# $s2 <- CurrPos
# $s3 <- dis_add
MoveShip:
	# get Instruction from .data
	la $s0, Instruction
	lw $s1, 0($s0)
	# get CurrPos from .data
	la $s0, CurrPos		
	lw $s2, 0($s0)
	# erase the ship at CurrPos
	li $s3, Dis_add
	add $s3, $s3, $s2	# $s3 = CurrPos
	li $s0, Black
	sw $s0, 0($s3)
	sw $s0, -124($s3)
	sw $s0, -132($s3)
	sw $s0, 132($s3)
	sw $s0, 124($s3)
	# update the CurrPos
	add $s2, $s2, $s1
	la $s0, CurrPos
	sw $s2, 0($s0)
	# build the ship by Instrcution
	add $s3, $s3, $s1
	li $s0, Purple
	sw $s0, 0($s3)
	li $s0, Blue
	sw $s0, -124($s3)
	sw $s0, -132($s3)
	sw $s0, 132($s3)
	sw $s0, 124($s3)
	jr $ra
	
# Function: void BuildObst(int i): Generate and build obstcle at ObstPos[i]
# $s0 <- ObstPos
# $s1 <- color
# $s2 <- Diss_add
# $s3 <- Random Number
# $s4 <- ObstSpeed
# $s5 <- i
BuildObst:
	# pop i from stack
	lw $s5, 0($sp)
	addi $sp, $sp, 4
	sll $s5, $s5, 2		# i = i*4
	
	# load ObstPos and Dis_add
	la $s0, ObstPos
	li $s2, Dis_add
	la $s4, ObstSpeed
	
	# generate random speed
	li $v0, 42
	li $a0, 0
	
	la $a1, Level
	lw $a1, 0($a1)	# $a1 = Level
	syscall 
	# store speed in ObstSpeed
	move $s3, $a0
	add $s4, $s4, $s5	# ObstSpeed + i*4
	sw $s3, 0($s4)		# ObstSpeed[i] = Random Speed
	
	# generate random index
	li $v0, 42
	li $a0, 0
	li $a1, 29
	syscall 
	# store speed in ObstPos
	move $s3, $a0
	addi $s3, $s3, 2
	sll $s3, $s3, 5
	addi $s3, $s3, 31
	sll $s3, $s3, 2
	add $s0, $s0, $s5	# ObstPos + i*4
	sw $s3, 0($s0)		# ObstPos[i] = Random index
	
	# build obstcles at ObstPos[i]
	add $s2, $s2, $s3
	li $s1, LGrey
	sw $s1, -8($s2)
	sw $s1, 124($s2)
	li $s1, DGrey
	sw $s1, -4($s2)
	sw $s1, -132($s2)
	sw $s1, 0($s2)
	# return
	jr $ra
	
# Function: void MoveObst(int i): Move obstcles
# $s0 <- ObstPos
# $s1 <- 32
# $s3 <- ObstPos[i]
# $s4 <- ObstSpeed[i]
# $s5 <- i
# $s6 <- x of ObstPos[i]
MoveObst:
	# pop i from stack
	lw $s5, 0($sp)
	addi $sp, $sp, 4
	sll $s5, $s5, 2		# i = i*4
	
	# load ObstPos and ObstSpeed
	la $s0, ObstPos
	la $s4, ObstSpeed
	
	# access ObstPos[i] and ObstSpeed[i]
	add $s0, $s0, $s5	# $s3 = ObstPos + i*4
	lw $s3, 0($s0)		# $s3 = ObstPos[i]
	add $s4, $s4, $s5	# $s4 = ObstSpeed + i*4
	lw $s4, 0($s4)		# $s4 = ObstSpeed[i]
	
	# Calculate x of ObstPos[i]: x = (ObstPos[i] / 4) % 32
	li $s1, 32
	srl $s6, $s3, 2		# divide ObstPos[i] by 4
	divu $s6, $s1		# divide (ObstPos[i]/4) by 32
	mfhi $s6		# $s6 = x
	
	# Check for four different move cases
	# case1: x == 2; ObstPos[i] =- 4*Speed[i]
	beq $s6, 2, Move_Case1
	# case2: x == 1; ObstPos[i] =- 4*Speed[i] or -1
	beq $s6, 1, Move_Case2
	# case3: x == 0; ObstPos[i] = -1
	beq $s6, 0, Move_Case3
	# case4: x > 3; ObstPos[i] =- 4*Speed[i]
	bgt $s6, 2, Move_Case4
	
	Move_Case1:
		# push old $ra
		addi $sp, $sp, -4
		sw $ra, 0($sp)
		# $a2 = ObstPos[i] = $s3
		move $a2, $s3
		# call MoveObst1 with mode = 0 for erase
		li $a0, 0
		jal MoveObst1
		# ObstPos[i] = ObstPos[i] - 4
		addi $s3, $s3, -4
		sw $s3, 0($s0)		
		move $a2, $s3
		# call MoveObst2 with mode = 1 for build
		li $a0, 1
		jal MoveObst2
		# pop old $ra
		lw $ra, 0($sp)
		addi $sp, $sp, 4
		# jump to return1
		j return1
	Move_Case2:
		# push old $ra
		addi $sp, $sp, -4
		sw $ra, 0($sp)
		# $a2 = ObstPos[i] = $s3
		move $a2, $s3
		# call MoveObst2 with mode = 0 for erase
		li $a0, 0
		jal MoveObst2
		# if speed > 4: 
		bgt $s4, 4, MoveFast2
		# else: speed <= 4:
		# ObstPos[i] = ObstPos[i] - 4
		addi $s3, $s3, -4
		sw $s3, 0($s0)	
		move $a2, $s3
		# call MoveObst3 with mode = 1 for build
		li $a0, 1
		jal MoveObst3
		# pop old $ra
		lw $ra, 0($sp)
		addi $sp, $sp, 4
		# jump to return1
		j return1
		MoveFast2:
			# ObstPos[i] = -1
			li $s3, -1
			sw $s3, 0($s0)
			# pop old $ra
			lw $ra, 0($sp)
			addi $sp, $sp, 4
			# jump to return1
			j return1
	Move_Case3:
		# push old $ra
		addi $sp, $sp, -4
		sw $ra, 0($sp)
		# $a2 = ObstPos[i] = $s3
		move $a2, $s3
		# call MoveObst3 with mode = 0 for erase
		li $a0, 0
		jal MoveObst3
		# ObstPos[i] = -1
		li $s3, -1
		sw $s3, 0($s0)
		# pop old $ra
		lw $ra, 0($sp)
		addi $sp, $sp, 4
		# jump to return1
		j return1
	Move_Case4:
		# push old $ra
		addi $sp, $sp, -4
		sw $ra, 0($sp)
		# $a2 = ObstPos[i] = $s3
		move $a2, $s3
		# call MoveObst1 with mode = 0 for erase
		li $a0, 0
		jal MoveObst1
		# if speed > 4: 
		bgt $s4, 4, MoveFast4
		# else: speed <= 4:
		# ObstPos[i] = ObstPos[i] - 4
		addi $s3, $s3, -4
		sw $s3, 0($s0)
		move $a2, $s3
		# call MoveObst1 with mode = 1 for build
		li $a0, 1
		jal MoveObst1
		# pop old $ra
		lw $ra, 0($sp)
		addi $sp, $sp, 4
		# jump to return1
		j return1
		MoveFast4:
			# ObstPos[i] = ObstPos[i] - 8
			addi $s3, $s3, -8
			sw $s3, 0($s0)	
			move $a2, $s3
			
			li $a0, 1
			# if $s1 = x == 3: Move to shape2
			beq $s6, 3, EdgeCase
			# call MoveObst1 with mode = 1 for build
			jal MoveObst1
			j Popra
			EdgeCase:
				jal MoveObst2
			Popra:
			# pop old $ra
			lw $ra, 0($sp)
			addi $sp, $sp, 4
			# jump to return1
			j return1
	
	return1:
		jr $ra

# Function: MoveObst1(int mode)
# $a0 <- mode: 0: erase 1: build
# $s2 <- Dis_add
# $a1 <- color, tempVar
# $a2 <- ObstPos[i]
MoveObst1:
	# load Dis_add, calculate Dis_add + ObstPos[i]
	li $s2, Dis_add
	add $s2, $s2, $a2
	
	# if mode == 0: erase the obstacle at ObstPos[i]
	beqz $a0, Erase1
	# else: build the obstacle at ObstPos[i]
	li $a1, LGrey
	sw $a1, -8($s2)
	sw $a1, 124($s2)
	li $a1, DGrey
	sw $a1, -4($s2)
	sw $a1, -132($s2)
	sw $a1, 0($s2)
	j ReturnShip1
	
	Erase1:
		li $a1, Black
		sw $a1, -8($s2)
		sw $a1, 124($s2)
		sw $a1, -4($s2)
		sw $a1, -132($s2)
		sw $a1, 0($s2)
	
	ReturnShip1:
		jr $ra
		
# Function: MoveObst2(int mode)
# $a0 <- mode: 0: erase 1: build
# $s2 <- Dis_add
# $a1 <- color, tempVar
# $a2 <- ObstPos[i]
MoveObst2:
	# load Dis_add, calculate Dis_add + ObstPos[i]
	li $s2, Dis_add
	add $s2, $s2, $a2
	
	# if mode == 0: erase the obstacle at ObstPos[i]
	beqz $a0, Erase2
	# else: build the obstacle at ObstPos[i]
	li $a1, LGrey
	sw $a1, 124($s2)
	li $a1, DGrey
	sw $a1, -4($s2)
	sw $a1, -132($s2)
	sw $a1, 0($s2)
	j ReturnShip2
	
	Erase2:
		li $a1, Black
		sw $a1, 124($s2)
		sw $a1, -4($s2)
		sw $a1, -132($s2)
		sw $a1, 0($s2)
	
	ReturnShip2:
		jr $ra

# Function: MoveObst3(int mode)
# $a0 <- mode: 0: erase 1: build
# $s2 <- Dis_add
# $a1 <- color, tempVar
# $a2 <- ObstPos[i]
MoveObst3:
	# load Dis_add, calculate Dis_add + ObstPos[i]
	li $s2, Dis_add
	add $s2, $s2, $a2
	
	# if mode == 0: erase the obstacle at ObstPos[i]
	beqz $a0, Erase3
	# else: build the obstacle at ObstPos[i]
	li $a1, DGrey
	sw $a1, 0($s2)
	j ReturnShip3
	
	Erase3:
		li $a1, Black
		sw $a1, 0($s2)
	
	ReturnShip3:
		jr $ra
		
# Function: ShowHealth()
# $a0 <- Dis_add
# $a1 <- i
# $a2 <- Health
# $a3 <- Color
ShowHealth:
	# load Dis_add
	li $a0, Dis_add
	addi $a0, $a0, 16
	# load Health
	la $a2, Health
	lw $a2, 0($a2)
	li $a1, 10
	divu $a2, $a1	# $a1 = Health / 10
	mflo $a2
	li $a1, 5
	sub $a1, $a1, $a2 # i = 5 - Health
	Loop3:
		beqz $a1, return3
		li $a3, LRed
		sw $a3, 0($a0)
		# i++
		addi $a0, $a0, -4
		addi $a1, $a1, -1
		j Loop3
	return3:
		jr $ra
		
# Function: ShowScore(int score)
# $v0 <- score
# $v1 <- digit
# $v2 <- tempVar
ShowScore:
	# first digit = score / 1000
	# second digit = score - 1000 * first digit / 100
	# third digit = score - 100 * second digit / 10
	# fourth digit = score - 10 * third digit / 1
	
