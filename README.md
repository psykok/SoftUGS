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
