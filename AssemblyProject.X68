*-----------------------------------------------------------
* Title      : Zork - assembly project
* Written by : Robin Meyler
* Date       : Jan - April
* Description: Text based game with the zork theme
*-----------------------------------------------------------
   org $500

*-------------------------------------------------------
*Choose to be Evil Wizard or New Romancers
*-------------------------------------------------------

*-------------------------------------------------------
*Validation values to be used, modify as needed
*Add additional validation values as required
*-------------------------------------------------------
exit        EQU 0      used to exit assembly program
min_feed    EQU 100    min feed requirement
min_horses  EQU 1      min number of horses
max_horses  EQU 9      max number of horses
min_soldier EQU 6      min soldiers
min_charge  EQU 1      min rate of fuel use based of speed (oats for horses)
max_charge  EQU 5      max rate e.g. Flank       
hit_point   EQU 5      points accumilated on castle (objective) strike
miss_point  EQU 8      points deducted for ordinace miss

mine_loc    EQU 100    example for a hit


*Start of Game
start:
    move.b  #100,$4000 put score/health in memory location $4000
    lea     $5300,A3   assign address A3 to that memory location
    Move.l #0, $5000    // Gold
    Move.l #0, $4500    // Feed
    Move.l #0, $4100    // Horses
    Move.l #0, $4200    // Hands
    Move.l #0, $4300    // Soliders
    Move.l #6, $5100    // Days going down
    Move.l #0, $5200    // Days going up

    
    Move.l #0, $8000    // Input


    bsr     welcome    branch to the welcome subroutine
    bsr     game       branch to the game subroutine
*Game loop
    org     $3000      the rest of the program is to be located from 3000 onwards

*-------------------------------------------------------
*-------------------Game Subroutine---------------------
*-------------------------------------------------------
game:
    bsr     gameloop   branch to gameloop subroutine
    rts                return from game: subroutine
          
end:
    simhalt

*-------------------------------------------------------
*-------------------Welcome Subroutine------------------
*-------------------------------------------------------
welcome:
    bsr     endl            branch to endl subroutine
    lea     welcome_msg,A1  assign message to address register A1
    move.b  #14,D0          move literal 14 to DO
    trap    #15             trap and interpret value in D0
    bsr     endl            branch to endl subroutine
    lea     prolog,A1
    move.b  #14,D0          move literal 14 to DO
    trap    #15  
    bsr     endl 
    bsr     get_up
    bsr     endl 
    lea    shopAttend,A1     // display string in A1 with CR 
    move.b  #13,D0        
    trap    #15  
    
    bsr     endl 
   
    bsr     neutral_zone

    rts                     return from welcome: subroutine

get_up:       
    lea     outOfBedMsg,A1
    move.b  #13,D0         
    trap    #15   
    move.b  #4, D0
    trap    #15
    CMP     #2, D1
    BEQ     squire_hassle
    bsr clear_screen

    lea     headDownstairs,A1
    move.b  #13,D0          
    trap    #15 
     bsr     endl 

    lea     talkToKing,A1
    move.b  #13,D0         
    trap    #15   
    move.b  #4, D0
    trap    #15
    bsr clear_screen
     bsr     endl 

    lea     kingsSpeech,A1
    move.b  #13,D0             
    trap    #15 
    move.L  #500, $5000         // Gold is in $5000  
     bsr     endl 

    lea     respondToKing,A1
    move.b  #13,D0         
    trap    #15   
    move.b  #4, D0
    trap    #15
    bsr clear_screen

    lea     travelToShop,A1
    move.b  #13,D0          
    trap    #15   

    rts                     return from welcome: subroutine
squire_hassle:
    lea     hassleOfSquire,A1
    move.b  #14,D0          move literal 14 to DO
    trap    #15

    jmp    get_up

neutral_zone:
   
   lea whatToBuyQuestion, A1
   move.b  #13,D0         
   trap    #15   
   move.b  #4, D0
   trap    #15
   CMP     #1, D1
   BEQ     soldiers
   CMP     #2, D1
   BEQ     horses
   CMP     #3, D1
   BEQ     feed
   CMP     #4, D1
   BEQ     hands
   CMP     #5, D1
   BNE     neutral_zone
    
    move.L  $5000, D1
    lea     yourGold,A1
    move.b  #13, D0
    trap    #15

    move.b  #3,D0        //Gold  
    trap    #15   
    bsr     endl

    move.L  $4500, D1
    lea     yourFeed,A1
    move.b  #13, D0
    trap    #15
    move.b  #3,D0        //Feed  
    trap    #15   
     
    bsr     endl
        
    move.L  $4100, D1
    lea     yourHorseCount,A1
    move.b  #13, D0
    trap    #15    
    move.b  #3,D0        //Horse     
    trap    #15   
     
    bsr     endl

    move.L  $4300, D1
    lea     yourSoliderCount,A1
    move.b  #13, D0
    trap    #15

    move.b  #3,D0        //Soldier    
    trap    #15   
    bsr     endl
        
    move.L  $4200, D1
    lea     yourHandCount,A1
    move.b  #13, D0
    trap    #15

  
    move.b  #3,D0        //Hands    
    trap    #15   
    bsr     endl
    move.b  #4, D0
    trap    #15


   rts         

*-------------------------------------------------------
*---------Gameplay Input Values Subroutine--------------
*-------------------------------------------------------    
input:
    bsr     feed            branch to feed input subroutine
    bsr     horses          branch to ship input subroutine
    bsr     soldiers        branch to soldiers input subroutine
    rts

*-------------------------------------------------------
*----------------Gameloop (main loop)-------------------
*------------------------------------------------------- 
gameloop:
    bsr     update          branch to update game subroutine 
    move.l $5100, D3
    move.l #1000, D4
    CMP     D4, D3
    BLT     gameloop        branch to gameplay subroutine
    
    bsr     clear_screen    clears the screen
    bsr     replay          branch to replay game subroutine
    bsr     clear_screen    clears the screen
    rts                     return from gameloop: subroutine

*-------------------------------------------------------
*---------------Update Mission Progress-----------------
*  Move to battle location, engage enemy, fire and take
*  fire, complete mission and return to base
*------------------------------------------------------- 
update:
    bsr     endl            print a CR and LF
    bsr     decorate        decorate with dots using a loop
    move.l $5100, D3
    move.l #1, D4
    Sub  D4, D3             // Lowering of days
    move.l D3, $5100
    
    move.l $5200, D5
    move.l #1, D7
    Add  D7, D5             // raising of days
    move.l D5, $5200

    move.l D3, D1
    lea     day,A1
    move.b  #14, D0
    trap    #15 
    move.b  #3,D0        //Display number in D1     
    trap    #15   
     bsr     endl
    move.L  $4500, D2
    move.L  #50,  D3        // Feed reduction
    Move.L  $4100, D4
    MULU    D4, D3
    SUB     D3, D2  
    move.L  D2, $4500  
    move.L  $4500, D1
    lea     yourFeed,A1
    move.b  #13, D0
    trap    #15
    move.b  #3,D0        //Display number in D1     
    trap    #15  
 
    bsr     endl

    move.l $5200, D3
    CMP  #1, D3
    BEQ  tavernMSG
    

    move.b  #4,D0        //read number to D1       
    trap    #15   

    bsr     endl
    

    
    bsr     decorate
    rts
    
tavernMSG:   
    lea     tavern_msg,A1
    move.b  #13,D0         
    trap    #15   
    move.b  #4, D0
    trap    #15
    CMP     #2, D1
    BEQ     tavern 
    rts
    
tavern:
    bsr clear_screen
    move.l $5100, D3
    move.l #1, D4
    Add  D4, D3             // Rising of days
    move.l D3, $5100
    
    lea     in_tavern,A1
    move.b  #13,D0         
    trap    #15   
    move.b  #4, D0
    trap    #15
    
    CMP  #1, D1
    BEQ  regulars
    CMP  #2, D1
    BEQ  loosesoldiers
    CMP  #3, D1
    BEQ  bar

    rts
    
regulars:
    lea     regulars_msg,A1
    move.b  #13,D0         
    trap    #15  
    move.l $5100, D3
    move.l #2, D4
    Sub  D4, D3             // Lowering of days
    move.l D3, $5100
    move.l D3, D1
     
       rts
loosesoldiers:
    lea     other_soldiers_msg,A1
    move.b  #13,D0         
    trap    #15 
    move.L  #4, $8000  
    move.L  $8000, D3
    move.L  $5000, D4       // The gold
  
    Move.L  $4300, D6
    
    CMP     #20, D4            // Too much check
    BGT too_much_tavern
    
   rts
too_much_tavern
    SUB     #20, D4           // Subtracting gold
    move.L  D4, $5000
    
    Add      #4, D6
    Move.L   D6, $4300       // soldier storage
    move.L  D6, D1
    lea     yourSoliderCount,A1
    move.b  #13, D0
    trap    #15

    move.b  #3,D0        //Display number in D1     
    trap    #15   
     
    bsr     endl

    rts


bar:
    lea     bar_msg,A1
    move.b  #13,D0         
    trap    #15   
     move.l $5100, D3
    move.l #1, D4
    Add  D4, D3             // Rising of days
    move.l D3, $5100
     move.l D3, D1
      rts



*-------------------------------------------------------
*---------------Draw Mission Updates--------------------
* Draw the game progress information, status regarding
* mission
*------------------------------------------------------- 
draw:
    bsr     endl
    bsr     decorate
   
    move.b  #14,D0
    trap    #15
    bsr     decorate
    rts
*-------------------------------------------------------
*-----------------------Horse feed-----------------------
* Input the feed load for each horse. Feed costs money
* For an advanced mark you need to manage this resource
*------------------------------------------------------- 
feed:
    bsr     endl
    bsr     decorate
    lea     feed_msg,A1
      
    move.b  #13, D0
    trap    #15
    move.b  #4, D0
    trap    #15
    move.L  D1, $8000       // Gold shop entered
    
    move.L  $8000, D3
    move.L  $5000, D4       // The gold
    move.L  #100,  D5
    
    CMP   D3, D4            // Too much check
    BLT too_much_feed
    
    Move.L   $4500, D6
    MULU     D3, D5
    Add      D5, D6
    Move.L   D6, $4500       // Feed storage
    
    SUB     D3, D4           // Subtracting gold
    move.L  D4, $5000
    
    
    move.L  D6, D1
    lea     yourFeed,A1
    move.b  #13, D0
    trap    #15

    move.b  #3,D0        //Display number in D1     
    trap    #15   
     
    bsr     endl
    
    move.L  D4, D1
    lea     yourGold,A1
    move.b  #13, D0
    trap    #15

    move.b  #3,D0        //Display number in D1     
    trap    #15   
    bsr     endl
    bsr     endl
    
    bsr     decorate
    jmp     neutral_zone
    
too_much_feed:
    lea      msg2, A1
    move.b  #13, D0
    trap    #15 
    
    

*-------------------------------------------------------
*--------------------Horses Inventory---------------------
* Number of horses to be allocated to a mission 
*------------------------------------------------------- 
horses:
    bsr     endl
    bsr     decorate
    lea     horses_msg,A1
    move.b  #13, D0
    trap    #15
    move.b  #4, D0
    trap    #15
    move.L  D1, $8000       // Gold shop entered
    
    move.L  $8000, D3
    move.L  $5000, D4       // The gold
    move.L  #10,   D5
    Move.L  $4100, D6
    
    
    MULU    D5, D3
    CMP     D3, D4            // Too much check
    BLT too_much_horse

    SUB     D3, D4           // Subtracting gold
    move.L  D4, $5000
    
    DIVU     D5, D3
    Add      D3, D6
    Move.L   D6, $4100       // Horse storage

    
    move.L  D6, D1
    lea     yourHorseCount,A1
    move.b  #13, D0
    trap    #15

    move.b  #3,D0        //Display number in D1     
    trap    #15   
     
    bsr     endl
    
    move.L  D4, D1
    lea     yourGold,A1
    move.b  #13, D0
    trap    #15

    move.b  #3,D0        //Display number in D1     
    trap    #15   
    bsr     endl
    bsr     endl
    
    bsr     decorate
    jmp     neutral_zone


    bsr     decorate
    rts
    
too_much_horse:
    lea      msg2, A1
    move.b  #13, D0
    trap    #15 
    jmp      horses
    
   



*-------------------------------------------------------
*-----------------------Soldiers----------------------
* Number of soldiers
*-------------------------------------------------------   
soldiers:
    bsr     endl
    bsr     decorate
    lea     soldier_msg,A1
    move.b  #13, D0
    trap    #15
    move.b  #4, D0
    trap    #15
    move.L  D1, $8000       // number shop entered
    
    move.L  $8000, D3
    move.L  $5000, D4       // The gold
    move.L  #20,   D5
    Move.L  $4300, D6
    
    
    MULU    D5, D3
    CMP     D3, D4            // Too much check
    BLT too_much_soldier

    SUB     D3, D4           // Subtracting gold
    move.L  D4, $5000
    
    DIVU     D5, D3
    Add      D3, D6
    Move.L   D6, $4300       // soldier storage

    
    move.L  D6, D1
    lea     yourSoliderCount,A1
    move.b  #13, D0
    trap    #15

    move.b  #3,D0        //Display number in D1     
    trap    #15   
     
    bsr     endl
    
    move.L  D4, D1
    lea     yourGold,A1
    move.b  #13, D0
    trap    #15

    move.b  #3,D0        //Display number in D1     
    trap    #15   
    bsr     endl
    bsr     endl
    
    bsr     decorate
    jmp     neutral_zone


    bsr     decorate
    rts
    
too_much_soldier:
    lea      msg2, A1
    move.b  #13, D0
    trap    #15 
    jmp     soldiers



hands:
    bsr     endl
    bsr     decorate
    lea     hand_msg,A1
    move.b  #13, D0
    trap    #15
    move.b  #4, D0
    trap    #15
    move.L  D1, $8000       // number shop entered
    
    move.L  $8000, D3
    move.L  $5000, D4       // The gold
    Move.L  $4200, D6
    
    
    CMP     D3, D4            // Too much check
    BLT too_much_hand

    SUB     D3, D4           // Subtracting gold
    move.L  D4, $5000
    
    Add      D3, D6
    Move.L   D6, $4300       // soldier storage

    
    move.L  D6, D1
    lea     yourHandCount,A1
    move.b  #13, D0
    trap    #15

    move.b  #3,D0        //Display number in D1     
    trap    #15   
     
    bsr     endl
    
    move.L  D4, D1
    lea     yourGold,A1
    move.b  #13, D0
    trap    #15

    move.b  #3,D0        //Display number in D1     
    trap    #15   
    bsr     endl
    bsr     endl
    
    bsr     decorate
    jmp     neutral_zone


    bsr     decorate
    rts
    
too_much_hand:
    lea      msg2, A1
    move.b  #13, D0
    trap    #15 
    jmp     hands

*-------------------------------------------------------
*---Game Play (Mission Progress, Battle Maneuvers)------
*------------------------------------------------------- 
gameplay:
    bsr     endl
    bsr     decorate

   
    move.b  #14,D0
    trap    #15
     move.b  #2,D0
    trap    #15


  bsr     decorate
    bsr     collision
    rts

*-------------------------------------------------------
*-----------------Heads Up Display (Score)--------------
* Retrieves the score from memory location
*-------------------------------------------------------   
hud:

    bsr     endl
    bsr     decorate
       move.b  #14,D0
    trap    #15
      move.b  #2,D0
    trap    #15


    move.b  (A3),D1     retrieve the value A3 point to and move to D1
    move.b  #3,D0       move literal 3 to D0
    trap    #15         intrepret value in D0, which 3 which displays D1
    bsr     decorate
    rts

*-------------------------------------------------------
*-----------------------Taking Fire---------------------
* This could be used for collision detection, if 
*-------------------------------------------------------
collision:
    move.b  #mine_loc,D1
    cmp     #100,D1 is( x == 100)?
	bne     collision_miss if x is equal to 100, then hit
collision_hit:
    *hit
       move    #14,D0
    trap    #15
    rts
    
collision_miss:
    *miss
    move    #14,D0
    trap    #15
    rts
*-------------------------------------------------------
*--------------------------Loop-------------------------
*-------------------------------------------------------
loop:
    move.b  #5, D3 loop counter D3=5
next:

    move.b  #14,D0
    trap    #15
	sub     #1,D3   decrement loop counter
    bne     next    repeat until D0=0

*-------------------------------------------------------
*------------------Screen Decoration--------------------
*-------------------------------------------------------
decorate:
    move.b  #60, D3
    bsr     endl
out:
        move.b  #14,D0
    trap    #15
	sub     #1,D3   decrement loop counter
    bne     out	    repeat until D0=0
    bsr     endl
    rts
    
clear_screen: 
    move.b  #11,D0      clear screen
    move.w  #$ff00,D1
    trap    #15
    rts
*-------------------------------------------------------
*------------------------Replay-------------------------
*-------------------------------------------------------
replay:
    bsr     endl
    lea     replay_msg,A1
    move.b  #14,D0
    trap    #15
    
    move.b  #4,D0
    trap    #15

    cmp     #exit,D1
    beq     end         if SR Z register contains 1 beq => Branch Equals
    bsr     start

endl:
    movem.l D0/A1,-(A7)
    move    #14,D0
    lea     crlf,A1
    trap    #15
    movem.l (A7)+,D0/A1
    rts
    
*-------------------------------------------------------
*-------------------Data Delarations--------------------
*-------------------------------------------------------

msg1:           dc.b    'north', 0
msg2:           dc.b    'Not enough gold for that transaction', 0
                
yourGold:        dc.b    'Current Gold:', 0
yourFeed:       dc.b    'Current Feed:', 0
yourHorseCount  dc.b    'Your Horse count:', 0
yourHandCount   dc.b    'Your horse Hand count:', 0
yourSoliderCount  dc.b   'Your Solider count', 0
day:             dc.b    $0D,$0A
                 dc.b   'Days till enemy castle:', 0

      
                
                
crlf:           dc.b    $0D,$0A,0
welcome_msg:    dc.b    '************************************************************'
                dc.b    $0D,$0A
                dc.b    'ZorkQuest: Assault on Egreth Castle'
                dc.b    $0D,$0A
                dc.b    '************************************************************'
                dc.b    $0D,$0A,0
                   
prolog:         dc.b    'Hey, hey sir, wake up! The king calls, he wants you in hall.'
                dc.b    $0D,$0A
                dc.b    'The king calls for you, wake up! there is no time, its time to prove yourself.', 0
                
outOfBedMsg:     dc.b    'Get out of Bed?'
                dc.b    $0D,$0A
                dc.b    '1: Yeah, get up'
                dc.b    $0D,$0A
                dc.b    '2: Nah, rest is vital', 0
                
talktoKing:     dc.b    'What to say to the King?'
                dc.b    $0D,$0A
                dc.b    '1: The hell do you have me up this early for?!'
                dc.b    $0D,$0A
                dc.b    '2: You called for me?', 0
                
respondToKing:  dc.b    'What to respond to the King?'
                dc.b    $0D,$0A
                dc.b    '1: You can count on me, ill return our honor!'
                dc.b    $0D,$0A
                dc.b    '2: Fine', 0
             
              

hassleOfSquire: dc.b    'This isnt the time, your father wont be happy, wake up sir!', 0
              
headDownstairs: dc.b    '>You wake fully, dress and head down stairs to the hall.', 0 

kingsSpeech:    dc.b    'King:'
                dc.b    $0D,$0A
                dc.b    'Son! What took so long, I called for you an age ago, were at war son.'
                dc.b    $0D,$0A
                dc.b    'Were going straight for their heart, their home, Egreth castle.'
                dc.b    $0D,$0A
                dc.b    'Head over to the neutral area in freerealm and purchase what you will need'
                dc.b    $0D,$0A
                dc.b    $0D,$0A
                dc.b    '*You recieve 500 gold*', 0
                
travelToShop:   dc.b    $0D,$0A
                dc.b    '*3 days later*', 0
                
                
shopAttend    
                dc.b    'Shop attendent:'
                dc.b    $0D,$0A
                dc.b    'Id expect your journey to take about 5 days'
                dc.b    $0D,$0A
                dc.b    'Horses are 10 gold and Soliders are 20 gold'
                dc.b    $0D,$0A
                dc.b    'Feed is 100 per gold, each horse will eat 50 a day'
                dc.b    $0D,$0A
                dc.b    'Horses hand are 1 gold each, each horse needs a hand'
                dc.b    $0D,$0A
                dc.b   'but 1 can look after 2 horses'
                dc.b    $0D,$0A
                dc.b   'You might need some gold down the road', 0

whatToBuyQuestion:    dc.b    'What do you want to buy?'
                      dc.b    $0D,$0A
                      dc.b    '1: Buy Soliders'
                      dc.b    $0D,$0A
                      dc.b    '2: Buy Horses'
                      dc.b    $0D,$0A
                      dc.b    '3: Buy Horse feed'
                      dc.b    $0D,$0A
                      dc.b    '4: Buy Horses hand'
                      dc.b    $0D,$0A
                      dc.b    '5: Im ready for the road', 0
             
                  
feed_msg:         dc.b    'How much gold do you want spend on feed?',0
                
horses_msg:      dc.b    'How many Horses do you want?', 0

soldier_msg:     dc.b    'How many soldiers you want?', 0

hand_msg:        dc.b    'How many horses Hands do you want?'
                dc.b    $0D,$0A
                dc.b    '1 gold for a Hand'
                dc.b    $0D,$0A
                dc.b    '1 horses hand can look after 2 horses'
                dc.b    $0D,$0A
                dc.b    'Without them, the horse will die', 0

tavern_msg      dc.b    '>You come to a fork in the road'
                dc.b    $0D,$0A
                dc.b    'Left is the way but Right has a tavern'
                dc.b    $0D,$0A
                dc.b    'Right will add a day, but might offer opportunities'
                dc.b    $0D,$0A
                dc.b    $0D,$0A
                dc.b    '1: Left'
                dc.b    $0D,$0A
                dc.b    '2: Right', 0
                
in_tavern       dc.b    '>To the right of the room theres a group of 10 soliders with no sigil'
                dc.b    $0D,$0A
                dc.b    '>To the Left of the room, about 15 regulars'
                dc.b    $0D,$0A
                dc.b    '>In front of you is the bar'
                dc.b    $0D,$0A
                dc.b    'The two groups seem at odds, your armys first move is important'
                dc.b    $0D,$0A
                dc.b    $0D,$0A
                dc.b    '1: Left, approach regulars and ask for tips for shortcuts'
                dc.b    $0D,$0A
                dc.b    '2: Right, approach the soliders, ask their price'
                dc.b    $0D,$0A
                dc.b    '3: The bar, youre, here for beer, not trouble', 0

regulars_msg:   dc.b    'You approach the regulars'
                dc.b    $0D,$0A
                dc.b    'You ask if there was a quicker way to the castle'
                dc.b    $0D,$0A
                dc.b    'They tell you of shortcut through the mountains'
                dc.b    $0D,$0A
                dc.b    'You shorthen the journey by a day instead of losing a day'
                dc.b    $0D,$0A
                dc.b    'One of the other soldiers suddenly hits a regular at the bar'
                dc.b    $0D,$0A
                dc.b    'They deem your army enemies too', 0

other_soldiers_msg:    dc.b    '>You approach the Soliders'
                dc.b    $0D,$0A
                dc.b    '>You ask if they are for hire'
                dc.b    $0D,$0A
                dc.b    '>Being your last chance to use any of money left'
                dc.b    $0D,$0A
                dc.b    '>You take 4 soliders for 5 gold each, ready to fight'
                dc.b    $0D,$0A
                dc.b    '>One of the other soldiers suddenly hits a regular at the bar'
                dc.b    $0D,$0A
                dc.b    '>Regulars deem your army enemies too', 0

    
bar_msg:         dc.b    '>You approach the bar'
                dc.b    $0D,$0A
                dc.b    '>Your army begins the throw the beer back'
                dc.b    $0D,$0A
                dc.b    '>One of you hands has gotten very ill'
                dc.b    $0D,$0A
                dc.b    '>Waiting for him to recover will lose you another day'
                dc.b    $0D,$0A
                dc.b    '>One of the other soldiers suddenly hits a regular at the bar'
                dc.b    $0D,$0A
                dc.b    '>You avoid them and leave', 0

replay_msg:     dc.b    'You have run out of feed and have lost, Enter 0 to Quit any other number to replay : ',0

health:     ds.w    1
score:      ds.w    1 reserve space for score

    end start





*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
