#####################################################################
#
# CSC258H Winter 2021 Assembly Final Project
# University of Toronto, St. George
#
# Student: Jinyang Zhao, Student Number: 1005869375
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8
# - Unit height in pixels: 8
# - Display width in pixels: 256
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
#
#
# Which approved additional features have been implemented?
# (See the project handout for the list of additional features)
# 1. break into multiple parts when centipede got shoot.
# 2. Mushroom gone after been shoot three tmes, and each life match with one different color.
# 3. Count number of lives (default 3), once it get shooted, it sink for three times.
# 4. After each round, we will randomly generate couple more mushrooms, otherwise mushroom will become less and less
# 5. pop up messages when we lose one life or dead.
#
# ... (add more if necessary)
#
# Any additional information that the TA needs to know:
# - (write here, if any)
#  $s1 store the location of BB, just in the last row (0 to 4 * 31), 
#                           so we have to add 31 * 32 * 4 to acacess correct offset
#  $s3 always store the status of centipede!! 0 means dead! #1 means still alive
#  $s4 store the life of BB, initioal 3 lives!
#  $s5 store the location of Flea.

#####################################################################

# Demo for painting
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8
# - Unit height in pixels: 8
# - Display width in pixels: 256
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
#
.data
	displayAddress: .word 0x10008000
	BackgroundColour: .word 0x000000
	Mush_threelife_clr: .word 0xff0000
	Mush_twolife_clr: .word 0xff726f
	Mush_onelife_clr: .word 0xf08080
	BBColour: .word 0x0070ff
	BulletColour: .word 0xffffff
	Head_clr: .word 0x90ee90 # Dark Green
	Body_clr: .word 0xF5FFFA # Light Green
	number_of_marshrooms: .word 16 # 16 marshrooms
	mushrooms: .space 4096 # This is a list of all marshroom location and their life.
	Bullets: .space 128 # 32 * 4 store fack address / offset
	Cent_info: .space 40 # 1 head, 0 body, -1 dead.
	Cent_loc: .space 40 # fack location / offset
	Cent_dir: .space 40 # 1 left, 2 right, 3 down and left, 4 down and right, 0 error.
	len_of_cent: .word 10
	byeColor: .word 0x37659E
	hit_by_cent_war_msg: .asciiz "You have been hit by a centipede, lose one life.\n"
	hit_by_flea: .asciiz "You have been hit by a flea, please click the button to restart the game.\n"
	bye_msg: .asciiz "You have lost all your life, click the button to restart the game.\n"
	Flea_clr: .word 0xFFEFD5
	#Flea: .space 4 # There is only one flea can have in the screen.
	
	screenHeight: .word 32
	screenWidth: .word 128
	
	
############################################################################################
.globl main
.text
main:


# Draw background
draw_backgrund:
	lw $t0, displayAddress		# Location of current pixel data
	addi $t5, $t0, 4096		# Location of last pixel data. Hard-coded below.
					# 32x32 = 1024 pixels x 4 bytes = 4096.
	lw $t3, BackgroundColour		# Colour of the background
	
draw_bg_loop:
	sw $t3, 0($t0)				# Store the colour
	addi $t0, $t0, 4			# Next pixel
	blt $t0, $t5, draw_bg_loop	
					# Finish drawing all pixels					


# initBB
init_BB:
	addi $s1, $zero, 64 # 128 * 31 + 64
	jal Draw_BB

init_Marshrooms:
	addi $t5, $zero, 4096
init_Marshrooms_loop:
	sw $zero, mushrooms($t5)
	addi $t5, $t5, -4
	bgt $t5, $zero, init_Marshrooms_loop

generate_Marshrooms:
	lw $t6, number_of_marshrooms
	lw $t3, Mush_threelife_clr
	addi $t4, $zero, 3 			# $t4 = 3
	jal Marshroom_generate_loop
	jal print_marshrooms

init_Bullets:
	addi $t4, $zero, 128
	addi $t5, $zero, 0
	addi $t6, $zero, -1
	init_Bullets_loop:
		sw $t6, Bullets($t5)
		addi $t5, $t5, 4
		blt $t5, $t4, init_Bullets_loop
init_centipede:
	addi $s3, $zero, 0 # s3 always store the status of centipede!!
				# 0 means dead! #1 means still alive
	addi $s4, $zero, 3 # BB havs 3 lifes in total!
	
init_flea:
	addi $s7, $zero, 5000
	
############################################################################################
# Game Loop main part:
game_loop_main: 
Need_new_cent_check:
	bgt $s3, $zero, check_any_imput # If s3 = 1, still alive
Create_new_centipede:
	addi $s3, $zero, 1 # now we have centpede
	lw $t4, len_of_cent
	sll $t4, $t4, 2
	addi $t5, $zero, 0
	subi $t6, $t4, 4  # T6 is the fack address
	addi $t8, $zero, 2 # t8 = 2 move right initially!
	CNC_loop:
	sw $t6, Cent_loc($t5)
	sw $t8, Cent_dir($t5)	
	sw $zero, Cent_info($t5)
	addi $t5, $t5, 4
	subi $t6, $t6, 4
	blt $t5, $t4, CNC_loop
	sw $s3, Cent_info($zero) # store the index of head
				# just use s3 here and the meaning is info[0] = 1
	
	
# Check whether the centipede fully died or not, 
# If yes, recreat and (redraw -> put it at the end) new centipede.
# 
check_any_imput:
	lw $t8, 0xffff0000
 	beq $t8, 1, keyboard_input
 	j keyboard_input_done
 	
keyboard_input:
	lw $t2, 0xffff0004
	beq $t2, 0x6A, keyboard_left # If `j`, move left
	beq $t2, 0x6B, keyboard_right# If `k`, move right
	beq $t2, 0x73, keyboard_restart # If `r`, restart the game from end screen
	beq $t2, 0x78, keyboard_shoot # If 'x', shoot!!
    	beq $t2, 0x63, Exit # If `c`, terminate the program gracefully
	j keyboard_input_done		# Otherwise, ignore...
	
keyboard_left:
	beq $s1, $zero, keyboard_input_done
	jal Clean_BB
	addi $s1, $s1, -4
	jal Draw_BB
	j keyboard_input_done 
	
keyboard_right:
	lw $t5, screenWidth				# Load in screenWidth
	addi $t5, $t5, -4
	beq $s1, $t5, keyboard_input_done
	jal Clean_BB
	addi $s1, $s1, 4
	jal Draw_BB
	j keyboard_input_done 
	
keyboard_shoot:
	#Gonna do somthing here
	addi $t5, $zero, 0 # Index in Bullet
	kb_shoot_loop:
		lw $t6, Bullets($t5) # Address in Bullet
		blt $t6, $zero, add_new_bullet # if $t6 < 0
		addi $t5, $t5, 4
		j kb_shoot_loop
	add_new_bullet:
		addi $t7, $s1, 3968 # Real address
		sw $t7, Bullets($t5)
	j keyboard_input_done 
	
keyboard_restart:
	j main

keyboard_input_done: # do nothing
	
# We have deal with all inputs!
############################################################################################
update_centipe:
move_to_new_location:
	lw $t4, len_of_cent
	sll $t4, $t4, 2  # t4 = len(centipede) * 4
	sub $t4, $t4, 4
	addi $t5, $zero, 0 # t5 = 0
	lw $t3, BackgroundColour
	MTNL_loop:
	lw $t6, Cent_info($t5) # t6 contains info 1 or 0 / head or body
	blt $t6, $zero, end_of_MTNL_loop # If t6 < 0, next!
	lw $t7, Cent_loc($t5) # t7 contains fack location
	lw $t8, Cent_dir($t5) # t8 contains direction
	
	beq $t5, $t4, Quick_clean_up_for_tail
	addi $t5, $t5, 4
	lw $t9, Cent_info($t5)
	subi $t5, $t5, 4
	beq $t9, -1, Quick_clean_up_for_tail
	j not_tail
	
	Quick_clean_up_for_tail:
	lw $t0, displayAddress
	add $t0, $t0, $t7
	sw $t3, 0($t0)
	
	not_tail:
	beq $t8, 1, Move_left
	beq $t8, 2, Move_right
	bge $t8, 3, Move_down # if t8 >= 3, move down!
	Move_left:
		subi $t7, $t7, 4
		j done_movement
	Move_right:
		addi $t7, $t7, 4
		j done_movement
	Move_down:
		addi $t7, $t7, 128
		j done_movement
	done_movement:
		sw $t7, Cent_loc($t5) # update new location based on direction.
	IF_overlap_with_mushroom_cannot_avoid:
		sw $zero, mushrooms($t7)
	end_of_MTNL_loop:
	addi $t5, $t5, 4
	ble $t5, $t4, MTNL_loop

update_direction:
	lw $t4, len_of_cent
	sll $t4, $t4, 2  # t4 = len(centipede) * 4
	addi $t5, $zero, 0 # t5 = 0
	UD_loop:
	lw $t6, Cent_info($t5) # t6 contains info 1 or 0 / head or body
	blt $t6, $zero, end_of_dir_change # If t6 < 0, next!
	lw $t7, Cent_loc($t5) # t7 contains fack address (the address is already updated!)
	lw $t8, Cent_dir($t5) # t8 contains direction
	beq $t6, 1, head_dir_update
	beq $t6, $zero, body_dir_update
	head_dir_update:
		move $t2, $t8 # t2 = t8 mack a copy of direction, we will use it!
		If_hit_with_BB:
		subi $t7, $t7, 3968
		beq $t7, $s1, GOT_A_HIT_with_BB
		addi $t7, $t7, 3968
		next_direction:
			beq $t8, 1, dir_left
			beq $t8, 2, dir_right
			beq $t8, 3, dir_down_left
			beq $t8, 4, dir_down_right
			dir_left:
				hit_left_check:
				subi $t7, $t7, 4 # go left one step
				lw $t9, mushrooms($t7)
				addi $t7, $t7, 4 # add it back
				bgt $t9, $zero, got_reg_left_hit # there is a mushroom!!!
				beq $t7, 3968, got_spe_left_hit
				addi $t3, $zero, 128 # prepare for divition
				div $t7, $t3 
				mfhi $t7 # t7 contains the remainder
				beq $t7, $zero, got_reg_left_hit
				no_left_hit: # do nothing
					j end_of_dir_change
				got_reg_left_hit:
					addi $t8, $zero, 4 # change from left to down-right
					sw $t8, Cent_dir($t5)
					j end_of_dir_change
				got_spe_left_hit:
					addi $t8, $zero, 2 # change from left to right
					sw $t8, Cent_dir($t5)
					j end_of_dir_change
			dir_right:
				hit_right_check:
				addi $t7, $t7, 4 # go right one step
				lw $t9, mushrooms($t7)
				subi $t7, $t7, 4 # sub it back
				bgt $t9, $zero, got_reg_right_hit # there is a mushroom!!!
				beq $t7, 4092, got_spe_right_hit
				
				addi $t3, $zero, 128 # prepare for divition
				div $t7, $t3 
				mfhi $t7 # t7 contains the remainder
				beq $t7, 124, got_reg_right_hit			
				
				no_right_hit: # do nothing
					j end_of_dir_change
				got_reg_right_hit:
					addi $t8, $zero, 3 # change from right to down-left
					sw $t8, Cent_dir($t5)
					j end_of_dir_change
				got_spe_right_hit:
					addi $t8, $zero, 1 # change from right to left
					sw $t8, Cent_dir($t5)
					j end_of_dir_change
			dir_down_left:
				addi $t8, $zero, 1 # change to left
				sw $t8, Cent_dir($t5)
				j end_of_dir_change	
			dir_down_right:
				addi $t8, $zero, 2 # change to right
				sw $t8, Cent_dir($t5)
				j end_of_dir_change	
	body_dir_update:
		sw $t2, Cent_dir($t5) # store the direction of previous one
		move $t2, $t8 # update our direction so next one can use
	end_of_dir_change:
		addi $t5, $t5, 4
		blt $t5, $t4, UD_loop
		
update_bullets:
	jal Update_and_Clean_Bullets
	
check_any_hits:
hit_with_mushrooms:
	addi $t4, $zero, 128
	addi $t5, $zero, 0 # Index in Bullet
	HWM_loop:
		lw $t6, Bullets($t5) # t6 store fack address
		blt $t6, $zero, no_hit_with_mush
		lw $t7, mushrooms($t6) #t7 store the life of marshroom at t6 location
		bgt $t7, $zero, got_a_hit_with_mush
		beq $t7, $zero, no_hit_with_mush 
	got_a_hit_with_mush:
		addi $t8, $zero, -1
		sw $t8, Bullets($t5) # Bullets gone!
		addi $t7, $t7, -1 # Marshroom life -1
		sw $t7, mushrooms($t6) # store the correct life in Marshrooms
		jal update_mushroom # we have to change the color for marshroom
	no_hit_with_mush:
	addi $t5, $t5, 4
	blt $t5, $t4, HWM_loop
	
hit_with_centipede:
	addi $t1, $zero, 128
	addi $t2, $zero, 0 # Index in Bullet
	HWC_loop:
		lw $t3, Bullets($t2) # t3 store fack address
		blt $t3, $zero, next_bullet # Bullets doesn't exist
		lw $t4, len_of_cent
		sll $t4, $t4, 2  # t7 = len(centipede) * 4
		subi $t4, $t4, 4
		addi $t5, $zero, 0 # t5 = 0
		Centipede_loop:
			lw $t6, Cent_info($t5) # head, body or NotExist
			blt $t6, $zero, next_centipede_check
			lw $t6, Cent_loc($t5) # t6 is fack address
			bne $t3, $t6, next_centipede_check
			# If program can reach here, means we got a hit!!!
			got_a_hit_with_cent:
			# deal with bullet part
			addi $t7, $zero, -1
			sw $t7, Bullets($t2)
			#deal with mushroom part
			addi $t7, $zero, 3
			sw $t7, mushrooms($t6)
			jal update_mushroom
			# deal with centipede part
			addi $t7, $zero, -1
			sw $t7, Cent_info($t5) # this part of cetipede dead
			
			beq $t5, $t4, next_centipede_check # if this is already last one
			addi $t8, $t5, 4 # next index of centipede
			lw $t7, Cent_info($t8) 
			
			blt $t7, $zero, next_centipede_check # if next one is -1, we don't care.
			addi $t7, $zero, 1 # t7 = 1
			sw $t7, Cent_info($t8) # Let next index of centipede become head!!
			
			body_to_head_change_direction:
			lw $t9, Cent_dir($t8)
			addi $s6, $zero, 1
			beq $t9, $s6, left_to_down_then_right
			addi $s6, $zero, 2
			beq $t9, $s6, right_to_down_then_left
			left_to_down_then_right:
				addi $s6, $zero, 4
				sw $s6, Cent_dir($t8) 
				j next_bullet
			right_to_down_then_left:
				addi $s6, $zero, 3
				sw $s6, Cent_dir($t8) 
				j next_bullet
				
		next_centipede_check:
		addi $t5, $t5, 4
		ble $t5, $t4, Centipede_loop
	next_bullet:
	addi $t2, $t2, 4
	blt $t2, $t1, HWC_loop	
		
Centipede_fully_dead_check:
	lw $t4, len_of_cent
	sll $t4, $t4, 2  # t4 = len(centipede) * 4
	addi $t5, $zero, 0 # t5 = 0
	CFDC_loop:
		lw $t6, Cent_info($t5)
		bge $t6, $zero, done_cent_dead_check
	end_of_CFDC_loop:
	addi $t5, $t5, 4 # t5 += 4
	blt $t5, $t4, CFDC_loop
	# If we can reach this line, means centipede_fully_dead
	addi $s3, $zero, 0 # Let s3 = 0, show centipede dead!!!
done_cent_dead_check: # do nothing

Flea_part:
	blt $s5, 4096, move_and_creat_mush     # If this is true, we have currently a flea on screen, we just need to move it!
  	# reach this line if we don't have flea on screem
  	li $v0, 42          # Service 42, random int bounded
  	li $a0, 0           # Select random generator 0
  	li $a1, 199          # 0.5% chance to generate flea    
  	syscall             # Generate random int (returns in $a0)
  	beq $a0, $zero, Flea_is_coming # only 0.5% chance 
  	j end_of_flea
  	Flea_is_coming:
  		li $v0, 42          # Service 42, random int bounded
  		li $a0, 0           # Select random generator 0
  		li $a1, 31          # vertical column 0 to 31    
  		syscall             # Generate random int (returns in $a0)
  		sll $a0, $a0, 2     # times 4 to get fack valid address
  		move $s5, $a0

move_and_creat_mush:
	move $t6, $s5 # t6 store thre origianl offset 
	addi $s5, $s5, 128 # s5 is the new one
	lw $t3, Flea_clr
	lw $t0, displayAddress
	add $t0, $t0, $s5
	sw $t3, 0($t0)
	remove_previous_index:
		lw $t7, mushrooms($t6)
		bgt $t7, $zero, previous_has_mushroom
	previous_no_mushroom:
		lw $t3, BackgroundColour
		lw $t0, displayAddress
		add $t0, $t0, $t6
		sw $t3, 0($t0)
		j create_mushroom
	previous_has_mushroom:
		jal update_mushroom
	create_mushroom:
		bge $s5, 3584, flea_hits_with_BB
		li $v0, 42          # Service 42, random int bounded
  		li $a0, 0           # Select random generator 0
  		li $a1, 9          # 10% change to generate mushrooms.    
  		syscall             # Generate random int (returns in $a0)
  		beq $a0, $zero, create_new_mush
  		j end_of_flea
	 create_new_mush:
	 	addi $t7, $zero, 3
	 	sw $t7, mushrooms($s5)

flea_hits_with_BB:
	addi $t4, $s1, 3968
	beq $s5, $t4, hit_by_flea_bye
end_of_flea: # do nothing
display_all:
	jal Draw_Centipe
#	jal Draw_Marshrooms
	jal Draw_Bullets
	jal Draw_BB

############################################################################################
# We are mostly Done!!!	
Sleep:
	li $v0, 32
	li $a0, 30
	syscall
	
Fianlly:
	j game_loop_main
	
Exit:
	li $v0, 10 # terminate the program gracefully
	syscall

############################################################################################
# Below are all helper functions!!!
# These two are for BB location!

Draw_BB:
	lw $t3, BBColour
	lw $t0, displayAddress
	addi $t0, $t0, 3968 # 128 * 31 Which is last row
	add $t0, $t0, $s1 # $a0 should contain the pixel in last row.
	sw $t3, 0($t0)
	jr $ra
  

Clean_BB:
	lw $t3, BackgroundColour
	lw $t0, displayAddress
	addi $t0, $t0, 3968 # 128 * 31 Which is last row
	add $t0, $t0, $s1 # $a0 should contain the pixel in last row
	sw $t3, 0($t0) 
	jr $ra
	
# These four functions are for Bullets location!

Draw_Bullets:
	addi $t4, $zero, 128
	addi $t5, $zero, 0
	lw $t6, BulletColour
	Draw_Bullets_loop:
		lw $t7, Bullets($t5)
		blt $t7, $zero, End_of_DBL # IF there is an valid adress:
		lw $t0, displayAddress
		add $t0, $t0, $t7
		sw $t6, 0($t0)
	End_of_DBL: # It is negative, so empty
		addi $t5, $t5, 4
		blt $t5, $t4, Draw_Bullets_loop
	jr $ra


Update_and_Clean_Bullets: 
	addi $t4, $zero, 128
	addi $t5, $zero, 0 # Index in Bullet
	lw $t3, BackgroundColour
	UCB_loop:
		lw $t6, Bullets($t5) # t6 is fack address in Bullets
		blt $t6, $zero, next_bullect # if $t6 < 0
		lw $t0, displayAddress
		add $t0, $t0, $t6
		sw $t3, 0($t0)  # clean the bullet on screen
		subi $t6, $t6, 128 # Update the bullet location in array (prepare for next round)
		sw $t6, Bullets($t5)
	next_bullect:
	addi $t5, $t5, 4
	blt $t5, $t4, UCB_loop
	jr $ra	
	
# These one is using for generate marshrooms!
Marshroom_generate_loop:
	move $s0, $ra
	jal get_random_number		        # Get random number (0-799) in $a0
	move $ra, $s0
	ble $a0, 40, Marshroom_generate_loop # If the number is less than 40, do it again
	lw $t7, mushrooms($a0)                 # If we already have a mushroom there, do it again
	bgt $t7, $zero, Marshroom_generate_loop # Repeat
	
	sw $t4, mushrooms($a0) 		# Store marshhom[index] = 3
	
	addi $t6, $t6, -1
	bgt  $t6, $zero, Marshroom_generate_loop
	jr $ra	


get_random_number:
  	li $v0, 42          # Service 42, random int bounded
  	li $a0, 6           # Select random generator 0
  	li $a1, 864          # 27 rows * 32 width = 800    
  	syscall             # Generate random int (returns in $a0)
  	sll $a0, $a0, 2
  	jr $ra

update_mushroom: #Index is put in $t6, #life num is is $t7, no return value
	addi $t8, $zero, 0
	beq $t7, $t8, zero_life
	addi $t8, $zero, 1
	beq $t7, $t8, one_life
	addi $t8, $zero, 2
	beq $t7, $t8, two_life
	addi $t8, $zero, 3
	beq $t7, $t8, three_life
	zero_life:
		lw $t3, BackgroundColour
		j done_clr_select
	one_life:
		lw $t3, Mush_onelife_clr
		j done_clr_select
	two_life:
		lw $t3, Mush_twolife_clr
		j done_clr_select
	three_life: # Or even more with bugs...
		lw $t3, Mush_threelife_clr
	done_clr_select:
	lw $t0, displayAddress
	add $t0, $t0, $t6
	sw $t3, 0($t0)
	jr $ra
		

	
	
	
# index_to_address:  # Index put in a2, return address is in v0
# is_sth_in_some_list: # Take a1, a2 as input, return v0 (1 is true, 0 is false) Use t8, t9 here

print_marshrooms: 
	lw $t7, Mush_threelife_clr
	addi $t9, $zero, 4096 #Begin/Destination Address!

	move $s0, $ra
	jal print_marshroom_loop
	move $ra, $s0	
	
	jr $ra
	
print_marshroom_loop:
	lw $t6, mushrooms($t9)
	bgt $t6, $zero, yes_marsh_print
	beq $t6, $zero, no_marsh
	yes_marsh_print:	
		lw $t0, displayAddress
		add $t0, $t0, $t9 # Address in display with destination
		sw $t7, 0($t0)
	no_marsh:
	subi $t9, $t9, 4
	bge $t9, $zero, print_marshroom_loop
	jr $ra
	
Draw_Centipe:
	lw $t4, len_of_cent
	sll $t4, $t4, 2
	addi $t5, $zero, 0
	DC_loop:
	lw $t6, Cent_info($t5) # t6 contains info 1 or 0 / head or body
	blt $t6, $zero, end_of_DC_loop # If t6 < 0, next!
	lw $t7, Cent_loc($t5) # t7 contains fack location
	beq $t6, $zero, this_is_body # If t6 == 0, this is body
	this_is_head:
		lw $t3, Head_clr
		j done_clr_choose
	this_is_body:
		lw $t3, Body_clr
	done_clr_choose:
		lw $t0, displayAddress
		add $t0, $t0, $t7
		sw $t3, 0($t0)	
	end_of_DC_loop:
	addi $t5, $t5, 4
	blt $t5, $t4, DC_loop
	jr $ra
	
Draw_Marshrooms:
	jr $ra

GOT_A_HIT_with_BB:
	sub $s4, $s4, 1 # BB life minus 1
	beq $s4, $zero, lose_all_life_bye
	addi $s3, $zero, 0 # Centipede Gone!
	
	BB_bulinbulin_three_times:
		lw $t0 displayAddress
		addi $t0, $t0, 3968 # To last row
		add $t0, $t0, $s1 # Become the location of BB
		
		addi $t5, $zero, 3
		addi $t6, $zero, 0
		BulinBulin_loop:
		lw $t3, BackgroundColour
		sw $t3, 0($t0)
		li $v0, 32
		li $a0, 200
		syscall
		
		lw $t3, BBColour
		sw $t3, 0($t0)
		li $v0, 32
		li $a0, 200
		syscall
		
		addi $t6, $t6, 1
		blt $t6, $t5, BulinBulin_loop
	
	repaint_centipede_become_background:
	lw $t4, len_of_cent
	sll $t4, $t4, 2
	addi $t5, $zero, 0
	lw $t3, BackgroundColour
	RCBB_loop:
	lw $t6, Cent_info($t5) # t6 contains info 1 or 0 / head or body
	blt $t6, $zero, end_of_RCBB_loop # If t6 < 0, next!
	lw $t7, Cent_loc($t5) # tt contains fack address
	lw $t0, displayAddress
	add $t0, $t0, $t7
	sw $t3, 0($t0)
	end_of_RCBB_loop:
	addi $t5, $t5, 4
	blt $t5, $t4, RCBB_loop
	
	Send_a_lose_life_message:
		li $v0, 55
		la $a0, hit_by_cent_war_msg
		li $a1, 1
		syscall
	
	
	j game_loop_main
lose_all_life_bye:
	jal bye_loop_FINISH
	Send_lose_all_life_message:
		li $v0, 55
		la $a0, bye_msg
		li $a1, 1
		syscall
  	j main
hit_by_flea_bye:
	jal bye_loop_FINISH
	Send_hit_by_flea_message:
		li $v0, 55
		la $a0, hit_by_flea
		li $a1, 1
		syscall
  	j main
bye_loop_FINISH:
	# draw b
	lw $t0, displayAddress
	addi $t0, $t0, 1576
	lw $t1, byeColor
	sw $t1, 128($t0)
	sw $t1, 256($t0)
	sw $t1, 384($t0)
	sw $t1, 388($t0)
	sw $t1, 392($t0)
	sw $t1, 520($t0)
	sw $t1, 512($t0)
	sw $t1, 640($t0)
	sw $t1, 644($t0)
	sw $t1, 648($t0)
	#draw y
	sw $t1, 400($t0)
	sw $t1, 528($t0)
	sw $t1, 656($t0)
	sw $t1, 408($t0)
	sw $t1, 536($t0)
	sw $t1, 660($t0)
	sw $t1, 664($t0)
	sw $t1, 792($t0)
	sw $t1, 920($t0)
	sw $t1, 916($t0)
	sw $t1, 912($t0)
	#draw E
	sw $t1, 672($t0)
	sw $t1, 676($t0)
	sw $t1, 680($t0)
	sw $t1, 544($t0)
	sw $t1, 416($t0)
	sw $t1, 420($t0)
	sw $t1, 424($t0)
	sw $t1, 288($t0)
	sw $t1, 160($t0)
	sw $t1, 164($t0)
	sw $t1, 168($t0)
	#draw ! 
	sw $t1, 176($t0)
	sw $t1, 304($t0)
	sw $t1, 432($t0)
	sw $t1, 688($t0)
	li $v0, 32 # sleep
	li $a0, 3000
	syscall
	jr $ra

