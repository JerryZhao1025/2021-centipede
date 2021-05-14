# centipede
This is a "Centipede" Game wrote in assembly language.

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
#
# Any additional informations:
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
