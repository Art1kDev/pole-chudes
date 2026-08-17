# POLE CHUDES (1992–1993) — reverse-engineered source code

**Reverse-engineered reconstruction of the original DOS game «Поле чудес» by Vadim Bashurov (Arzamas-16, 1992–1993).**

The source code was recovered by reverse engineering the original `POLE.EXE`. The reconstruction preserves the original program structure, procedures, variables, algorithms and formulas, and is written in **Turbo Pascal 7.0** for MS-DOS.

The original program was written for DOS. This reconstruction works in DOS or in an emulator. It uses VGA mode `10h` (640×350×16), direct access to video memory at `$A000`, and does **not** use Crt, Graph or BGI units.

---

## Legal notice

This repository contains a reverse-engineered reconstruction of the original 1992–1993 DOS game «Поле чудес».

- **Original game**: © 1992–1993 Vadim Bashurov, Arzamas-16, USSR/Russia
- **Turbo Pascal runtime library**: © Borland International

I publish this reconstruction strictly for historical, educational and archival purposes.

This project is not affiliated with or endorsed by the copyright holders of the television game show «Поле чудес» or any related rights holders.

If you represent the rights holders and want me to take this repository down, open an issue or contact me.

---

## Requirements

The game runs **only under MS-DOS** (or a DOS emulator such as DOSBox). This is not a port to a modern operating system.

The reconstructed code retains direct interaction with IBM PC hardware:

- VGA mode `$10` (640×350×16);
- direct access to video memory at `$A000`;
- BIOS `INT 10h` services;
- keyboard via BIOS `INT 16h`;
- mouse support via `INT 33h`;
- PC speaker sound via ports `$42` / `$61`;
- the data files `POLE.LIB`, `POLE.FNT`, `POLE.OVL` and `POLE.PIC` placed next to the executable.

## Building and running

### DOSBox + Turbo Pascal 7

Install DOSBox (or DOSBox-X / DOSBox Staging) and Turbo Pascal 7.0, then compile the reconstructed source. Place `POLE.LIB`, `POLE.FNT`, `POLE.OVL` and `POLE.PIC` in the same directory as the resulting `EXE`.
