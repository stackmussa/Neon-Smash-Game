FINAL — Assembly Project

Overview
- Collection of 8086/8088 assembly source files and supporting assets.
- Likely a MS-DOS-era game or utilities (see file names).

Key files
- BONUS.ASM, GAME.ASM, MENU.ASM — game logic and levels
- HISCORE.ASM, SCORES.ASM, HISCORE.TXT — high score handling
- EDIT.COM — possible editor or utility binary
- Other .ASM files implement input, level select, and menus
- A_i243022_i243131_i243126_i243006_iteration3/Code/ — additional code folder

Build / Run (general)
- Use the assembler and linker appropriate for your target (MASM, TASM, NASM, etc.).
- Example (MASM/TASM style):
  1. Assemble: `tasm GAME.ASM`
  2. Link: `tlink GAME.OBJ`
  3. Run the produced COM/EXE under DOS or an emulator (DOSBox)

Notes
- This README is a minimal overview. If you want, I can add build scripts, a more detailed file map, or DOSBox configuration.
