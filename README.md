# SoftUGS
UGS preamp software

## Building

### Requirements

- **avra** — AVR assembler compatible with Atmel/AVR Studio syntax
  - macOS: `brew install avra`
  - Debian/Ubuntu: `apt install avra`
  - Arch: `pacman -S avra`

- **avrdude** (optional, for programming the MCU)
  - macOS: `brew install avrdude`
  - Debian/Ubuntu: `apt install avrdude`

### Compile

```sh
make                            # builds default target (ATMEGA64_OPTREX)
make TARGET=ATMEGA64_VFD        # builds a specific variant
make clean                      # removes build artifacts
```

Output files are placed in `build/`:
- `SoftUGS-<TARGET>.hex` — flash memory image
- `SoftUGS-<TARGET>.eep` — EEPROM data

### Available targets

| Target | MCU | Display | Notes |
|--------|-----|---------|-------|
| `FLAT` | ATmega64 | Optrex LCD | No bypass |
| `ATMEGA64_OPTREX` | ATmega64 | Optrex LCD | With bypass |
| `ATMEGA64_CRYSTALFONTZ` | ATmega64 | CrystalFontz LCD | With bypass |
| `ATMEGA64_CRYSTALFONTZ_ALDO` | ATmega64 | CrystalFontz LCD | Aldo remote mod |
| `ATMEGA64_CRYSTALFONTZ_MFC` | ATmega64 | CrystalFontz LCD | MFC I/O mod |
| `ATMEGA128_CRYSTALFONTZ` | ATmega128 | CrystalFontz LCD | With bypass |
| `ATMEGA64_VFD` | ATmega64 | VFD Noritake | With bypass |
| `ATMEGA64_VFD_NEWHAVEN` | ATmega64 | VFD Newhaven | With bypass |
| `ATMEGA64_VFD_ALDO` | ATmega64 | VFD Noritake | Aldo remote mod |
| `ATMEGA128_VFD` | ATmega128 | VFD Noritake | With bypass |
| `ATMEGA128_VFD_NEWHAVEN` | ATmega128 | VFD Newhaven | With bypass |

### Flash the MCU

```sh
make flash                      # program flash memory
make flash-eeprom               # program EEPROM
make flash-all                  # program both
```

By default uses `usbasp` programmer. Override with:

```sh
make flash PROGRAMMER=avrisp2 PORT=/dev/ttyUSB0
```

## IR Learning Diagnostics

During RC5 remote control learning (Setup > RC5 menu > press Menu on a command), the last character on the second display line shows the current state:

| Char | Meaning |
|------|---------|
| `*` | PD1 went LOW — a signal was detected on the IR input |
| `.` | Debounce rejected — the pulse was shorter than 100µs (noise) |
| `>` | IRDetect called — signal confirmed, decoding in progress |
| `X` | Decode failed — IRDetect timed out or received garbage |
| code | Success — the received RC5 code is displayed |

A typical successful learning shows `*` then `>` then the code value. An `X` on the first attempt is normal — press the remote button again. If only dots (`.`) appear, the IR receiver is producing very short pulses. If nothing appears at all, the IR receiver may be disconnected or damaged.
