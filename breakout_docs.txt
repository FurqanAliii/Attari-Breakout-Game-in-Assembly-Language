# Breakout Clone - Complete Documentation

## 1. Game Overview

**Breakout Clone** is a classic arcade game implemented in x86 Assembly (NASM) for DOS.

### Features:
- 32 colored bricks arranged in 5 rows
- Paddle control via arrow keys
- Ball physics with collision detection
- Scoring system (2 points per brick destroyed)
- Three lives system
- Real-time score display
- Victory and Game Over conditions

---

## 2. Flowchart of Game Logic

```
START
  │
  ├─► Display Rules/Instructions
  │   Wait for ENTER to start or ESC to exit
  │
  ├─► Initialize Game (printagain)
  │   ├─ Clear screen (Mode 13h - 320x200, 256 colors)
  │   ├─ Draw 32 bricks (8 columns × 5 rows)
  │   ├─ Draw paddle at bottom center
  │   ├─ Reset score to 0
  │   └─ Set lives to 3
  │
  ├─► Start New Round (startgame)
  │   ├─ Position ball at center (160, 100)
  │   ├─ Set initial ball velocity (ballSpeedx=0, ballSpeedy=2)
  │   └─ Wait for SPACE key
  │
  ├─► MAIN GAME LOOP (game)
  │   │
  │   ├─► DELETE OLD BALL POSITION
  │   │   └─ Call delball (draws black pixels)
  │   │
  │   ├─► UPDATE BALL POSITION
  │   │   └─ Call addtoball (add velocity to position)
  │   │
  │   ├─► DRAW NEW BALL
  │   │   └─ Call ball (draw 5×5 white pixels)
  │   │
  │   ├─► CHECK COLLISIONS (checkhit)
  │   │   ├─ Upper wall hit? → Reflect Y velocity
  │   │   ├─ Left/Right wall hit? → Reflect X velocity
  │   │   └─ Paddle hit?
  │   │       ├─ Yes → Reflect Y, adjust X based on hit position
  │   │       └─ No (missed) → Set gameoverbol=1
  │   │
  │   ├─► CHECK BRICK COLLISIONS (brickhit)
  │   │   ├─ Scan pixel color at ball position
  │   │   ├─ If brick color detected:
  │   │   │   ├─ Destroy brick (draw black)
  │   │   │   ├─ Reflect ball velocity
  │   │   │   ├─ Increment destroyedbricks counter
  │   │   │   ├─ Calculate score: destroyedbricks × 2
  │   │   │   └─ Play beep sound
  │   │   └─ Call finalcheck (verify destroyed bricks)
  │   │
  │   ├─► UPDATE SCORE DISPLAY
  │   │   └─ Call realtimescore (bottom-right corner)
  │   │
  │   ├─► CHECK USER INPUT (keycheck/timeiskey)
  │   │   ├─ Left Arrow (4Bh) → Move paddle left
  │   │   ├─ Right Arrow (4Dh) → Move paddle right
  │   │   ├─ ESC (01h) → Pause game
  │   │   └─ SPACE (39h) → Reset game
  │   │
  │   ├─► CHECK VICTORY CONDITION (vichecker)
  │   │   ├─ Scan all brick positions for non-black pixels
  │   │   ├─ If all black → Set gamewinbol=1
  │   │   └─ Else → Continue
  │   │
  │   ├─► CHECK GAME STATUS
  │   │   ├─ gameoverbol=1? → Jump to gameover routine
  │   │   ├─ gamewinbol=1? → Jump to victory routine
  │   │   └─ Else → Loop back to game
  │   │
  │   └─► LOOP BACK TO GAME
  │
  ├─► GAME OVER ROUTINE (gameover)
  │   ├─ Check remaining lives
  │   ├─ If lives > 0:
  │   │   ├─ Display "lifes left: X"
  │   │   ├─ Decrement life counter
  │   │   └─ Jump to startgame (new round)
  │   └─ If lives = 0:
  │       ├─ Switch to text mode
  │       ├─ Display "GAME END" message
  │       ├─ Display final score
  │       ├─ Wait for key press
  │       └─ Exit or restart
  │
  ├─► VICTORY ROUTINE (victory)
  │   ├─ Switch to text mode
  │   ├─ Display "VICTORY" message
  │   ├─ Display final score
  │   ├─ Wait for key press
  │   └─ Restart or exit
  │
  └─► EXIT
      ├─ Switch to text mode 2
      └─ Terminate program (INT 21h, AH=4Ch)
```

---

## 3. Interrupt Usage

### **BIOS Interrupts (INT 10h - Video Services)**

| Function | AH Value | Purpose | Usage in Code |
|----------|----------|---------|---------------|
| **Set Video Mode** | 00h | Switch between text/graphics modes | `mov ax, 13h; int 10h` (320×200, 256 colors) |
| **Set Cursor Position** | 02h | Position text cursor | Used in score display routines |
| **Write Pixel** | 0Ch | Draw individual pixels | Ball, paddle, brick rendering |
| **Read Pixel** | 0Dh | Get pixel color | Collision detection with bricks |
| **Teletype Output** | 0Eh | Print characters in text mode | Score digits display |

**Example - Drawing a Pixel:**
```asm
mov ah, 0ch    ; Write pixel function
mov al, 10     ; Color (white)
mov bh, 0      ; Page 0
mov cx, 160    ; X coordinate
mov dx, 100    ; Y coordinate
int 10h        ; Execute
```

---

### **DOS Interrupts (INT 21h - DOS Services)**

| Function | AH Value | Purpose | Usage in Code |
|----------|----------|---------|---------------|
| **Print String** | 09h | Display '$' terminated strings | Messages (rules, game over, victory) |
| **Buffered Keyboard Input** | 0Ch | Clear buffer and wait for input | Main menu and pause screens |
| **Terminate Program** | 4Ch | Exit to DOS | Program termination |

**Example - Printing Message:**
```asm
mov dx, rules_msg  ; Pointer to string
mov ah, 09h        ; Print string function
int 21h            ; Execute
```

---

### **Keyboard/Timer Hardware Ports**

| Port | Purpose | Usage |
|------|---------|-------|
| **60h** | Keyboard data | Read scan codes for arrow keys |
| **64h** | Keyboard status | Check if key is pressed |
| **61h** | PC Speaker control | Enable/disable beep sounds |
| **42h-43h** | Timer chip | Control beep frequency |

**Example - Reading Keyboard:**
```asm
in al, 64h         ; Read keyboard status
cmp al, 10b        ; Check if key available
je waitforkey
in al, 60h         ; Read scan code
cmp al, 0x4b       ; Check for Left Arrow
je left            ; Move paddle left
```

---

## 4. Scoring System Explanation

### **Score Calculation:**
- **Points per brick:** 2 points
- **Total bricks:** 32 (8 columns × 5 rows)
- **Maximum possible score:** 64 points
- **Score formula:** `score = destroyedbricks × 2`

### **Scoring Variables:**
```asm
destroyedbricks: dw 0    ; Counter for destroyed bricks
final_score_accumulator: dw 0  ; Stores calculated score (destroyedbricks × 2)
```

### **Scoring Process:**

1. **Brick Destruction Detection (brickhit routine):**
   - Ball position is checked against brick colors
   - If brick color detected → Destroy brick

2. **Score Update (finalcheck routine):**
   ```asm
   inc word [destroyedbricks]     ; Increment brick counter
   mov ax, [destroyedbricks]       ; Load count
   mov bl, 2                       ; Each brick = 2 points
   mul bl                          ; AX = destroyedbricks × 2
   mov [final_score_accumulator], ax  ; Save calculated score
   ```

3. **Real-time Display (realtimescore):**
   - Converts score to 3 ASCII digits (e.g., 064)
   - Displays at bottom-right corner (Row 24, Column 60)
   - Updates after every brick destruction

4. **Final Score Display:**
   - Shown on Victory/Game Over screens
   - Uses `ShowFinalscore` routine
   - Displays format: "score: XXX"

### **Score Display Format:**
```
score: 000  (Game start)
score: 018  (9 bricks destroyed)
score: 064  (All 32 bricks destroyed - VICTORY!)
```

---

## 5. Gameplay Mechanics

### **Controls:**
| Key | Action |
|-----|--------|
| **← (Left Arrow)** | Move paddle left (4 pixels) |
| **→ (Right Arrow)** | Move paddle right (4 pixels) |
| **ESC** | Pause/Resume game |
| **SPACE** | Reset game (during play) |
| **ENTER** | Start game (main menu) |

### **Ball Physics:**
- **Initial velocity:** X=0, Y=2 (moves straight down)
- **Speed variables:**
  - `ballSpeedx`: Horizontal velocity (-6 to +6)
  - `ballSpeedy`: Vertical velocity (-8 to +8)
- **Collision response:**
  - Wall hits → Negate appropriate velocity
  - Paddle hits → Velocity changes based on hit location:
    - **Left edge:** X=-6, Y=-2 (sharp left)
    - **Left-center:** X=-2, Y=-4
    - **Center:** X=0, Y=-8 (straight up)
    - **Right-center:** X=+2, Y=-4
    - **Right edge:** X=+6, Y=-2 (sharp right)

### **Lives System:**
- Start with **3 lives**
- Lose a life when ball passes paddle (Y > 187)
- Display updates: "lifes left: 3" → "2" → "1"
- **Game Over** when lives reach 0

### **Victory Condition:**
- Destroy all 32 bricks
- Triggered by `vichecker` routine (scans all brick positions)
- Maximum score achieved: **64 points**

---

## 6. Memory Map

### **Important Variables:**
```
ballx, bally         - Ball center position (0-319, 0-199)
ballSpeedx, ballSpeedy - Ball velocity components
padminx, padmaxx     - Paddle boundaries
pady                 - Paddle Y position (185)
lifecounter          - Remaining lives (3, 2, 1, 0)
destroyedbricks      - Count of destroyed bricks (0-32)
final_score_accumulator - Calculated score (0-64)
gameoverbol          - Game over flag
gamewinbol           - Victory flag
```

---

## 7. Compilation Instructions

### **Requirements:**
- NASM assembler
- DOSBox emulator

### **Compile:**
```bash
nasm -f bin breakout.asm -o breakout.com
```

### **Run in DOSBox:**
```
mount c: /path/to/folder
c:
breakout.com
```

---

## 8. Code Structure Summary

| Section | Lines | Purpose |
|---------|-------|---------|
| **Data Section** | 1-120 | Variable declarations, strings, messages |
| **Ball Rendering** | 122-170 | Draw/erase 5×5 ball |
| **Brick System** | 172-290 | Draw 32 bricks, collision detection |
| **Paddle Control** | 292-450 | Left/right movement, keyboard input |
| **Collision Logic** | 452-680 | Wall/paddle/brick hit detection |
| **Scoring System** | 682-820 | Score calculation and display |
| **Main Game Loop** | 822-1020 | Core game logic |
| **Victory/Game Over** | 1022-1150 | End-game screens |

---

## 9. Technical Highlights

1. **Pixel-Perfect Collision:** Uses INT 10h, AH=0Dh to read exact pixel colors
2. **Sound Effects:** PC speaker control via ports 61h, 42h, 43h
3. **Real-time Score:** Updates after every brick destruction
4. **Efficient Rendering:** Only redraws changed screen areas
5. **Smooth Controls:** Paddle moves 4 pixels per keypress with paint correction

---

**End of Documentation**
