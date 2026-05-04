# Makefile for SoftUGS - AVR Assembly project
# Replaces AVR Studio build for use on Linux and macOS
#
# Requirements:
#   - avra (AVR Assembler, Atmel-syntax compatible)
#     Install: brew install avra       (macOS)
#              apt install avra        (Debian/Ubuntu)
#              pacman -S avra          (Arch)
#
#   - avrdude (for programming the MCU, optional)
#     Install: brew install avrdude    (macOS)
#              apt install avrdude     (Debian/Ubuntu)
#
# Usage:
#   make                  Build the default target (ATMEGA128_CRYSTALFONTZ)
#   make TARGET=<name>    Build a specific target variant
#   make flash            Program the MCU via avrdude
#   make clean            Remove build artifacts
#
# Available TARGETs:
#   FLAT
#   ATMEGA64_OPTREX
#   ATMEGA64_CRYSTALFONTZ
#   ATMEGA64_CRYSTALFONTZ_ALDO
#   ATMEGA64_CRYSTALFONTZ_MFC
#   ATMEGA128_CRYSTALFONTZ  (default)
#   ATMEGA64_VFD
#   ATMEGA64_VFD_NEWHAVEN
#   ATMEGA64_VFD_ALDO
#   ATMEGA128_VFD
#   ATMEGA128_VFD_NEWHAVEN

# --- Configuration ---

TARGET ?= ATMEGA64_OPTREX

# Derive MCU from target name for avrdude
ifneq (,$(findstring ATMEGA128,$(TARGET)))
  MCU = atmega128
else
  MCU = atmega64
endif

# avrdude programmer configuration
PROGRAMMER ?= usbasp
PORT ?= usb

# --- Tools ---

AVRA ?= avra
AVRDUDE ?= avrdude

# --- Files ---

SRC = SoftUGS.asm
BUILD_DIR = build
OUT_HEX = $(BUILD_DIR)/SoftUGS-$(TARGET).hex
OUT_EEP = $(BUILD_DIR)/SoftUGS-$(TARGET).eep

# Preprocessed source with the correct target #define active
PREP_SRC = $(BUILD_DIR)/SoftUGS-$(TARGET).asm

# All assembly source files (for dependency tracking)
ASM_SOURCES = $(wildcard *.asm *.ASM)
INC_SOURCES = $(wildcard *.inc)

# --- Rules ---

.PHONY: all clean flash flash-eeprom help

all: $(OUT_HEX)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# Preprocess: activate the chosen target define, deactivate all others
# Pattern in source: ";#define NAME" = inactive, "#define NAME" = active
# Strategy: comment out all target defines, then uncomment the selected one
#
# Also convert Atmel Studio preprocessor syntax to avra-compatible:
#   #if defined(NAME)    -> #ifdef NAME
#   #if defined (NAME)   -> #ifdef NAME
#   #if !defined(NAME)   -> #ifndef NAME
#   #if ! defined(NAME)  -> #ifndef NAME
# And strip CRLF line endings + #pragma lines (unsupported by avra)

# Order matters: longer names first to avoid partial matches
TARGETS_RE = ATMEGA64_CRYSTALFONTZ_ALDO|ATMEGA64_CRYSTALFONTZ_MFC|ATMEGA128_VFD_NEWHAVEN|ATMEGA64_VFD_NEWHAVEN|ATMEGA128_CRYSTALFONTZ|ATMEGA64_CRYSTALFONTZ|ATMEGA64_VFD_ALDO|ATMEGA64_OPTREX|ATMEGA128_VFD|ATMEGA64_VFD|FLAT

# The main source also gets target selection preprocessing
$(PREP_SRC): $(SRC) $(ASM_SOURCES) $(INC_SOURCES) | $(BUILD_DIR)
	@echo "Preprocessing for target: $(TARGET)"
	@for f in $(filter-out $(SRC),$(ASM_SOURCES)) $(INC_SOURCES); do \
		LC_ALL=C sed -E \
		    -e 's/\r$$//' \
		    -e 's/^[[:space:]]*#if[[:space:]]*![[:space:]]*defined[[:space:]]*\(([^)]*)\)/#ifndef \1/' \
		    -e 's/^[[:space:]]*#if[[:space:]]+defined[[:space:]]*\(([^)]*)\)/#ifdef \1/' \
		    -e '/^[[:space:]]*#pragma/d' \
		    -e 's/^([A-Za-z_][A-Za-z0-9_]*)[[:space:]]+:/\1:/' \
		    -e '/^\.device[[:space:]]+ATmega64$$/d' \
		    "$$f" > $(BUILD_DIR)/"$$f"; \
	done
	LC_ALL=C sed -E \
	    -e 's/\r$$//' \
	    -e 's/^[[:space:]]*#if[[:space:]]*![[:space:]]*defined[[:space:]]*\(([^)]*)\)/#ifndef \1/' \
	    -e 's/^[[:space:]]*#if[[:space:]]+defined[[:space:]]*\(([^)]*)\)/#ifdef \1/' \
	    -e '/^[[:space:]]*#pragma/d' \
	    -e 's/^([A-Za-z_][A-Za-z0-9_]*)[[:space:]]+:/\1:/' \
	    -e 's/^#define[[:space:]]*($(TARGETS_RE))/;#define \1/' \
	    -e 's/^;#define[[:space:]]*$(TARGET)[[:space:]]/#define $(TARGET) /' \
	    -e 's/^;#define[[:space:]]*$(TARGET)$$/#define $(TARGET)/' \
	    $(SRC) > $@

# Assemble (avra produces Intel HEX output directly)
$(OUT_HEX): $(PREP_SRC)
	@echo "Assembling: $(TARGET) (MCU=$(MCU))"
	cd $(BUILD_DIR) && $(AVRA) $(notdir $(PREP_SRC)) -o $(notdir $(OUT_HEX)) -e $(notdir $(OUT_EEP)) -l /dev/null
	@echo "Build complete: $(OUT_HEX)"

# Flash program memory
flash: $(OUT_HEX)
	$(AVRDUDE) -p $(MCU) -c $(PROGRAMMER) -P $(PORT) -U flash:w:$(OUT_HEX):i

# Flash EEPROM
flash-eeprom: $(OUT_HEX)
	$(AVRDUDE) -p $(MCU) -c $(PROGRAMMER) -P $(PORT) -U eeprom:w:$(OUT_EEP):i

# Flash both
flash-all: flash flash-eeprom

clean:
	rm -rf $(BUILD_DIR)

help:
	@echo "SoftUGS Build System"
	@echo "===================="
	@echo ""
	@echo "Targets:"
	@echo "  make                          Build default ($(TARGET))"
	@echo "  make TARGET=ATMEGA64_VFD      Build specific variant"
	@echo "  make flash                    Program flash memory"
	@echo "  make flash-eeprom             Program EEPROM"
	@echo "  make flash-all                Program flash + EEPROM"
	@echo "  make clean                    Remove build artifacts"
	@echo ""
	@echo "Variables:"
	@echo "  TARGET=<name>                 Hardware variant (see top of Makefile)"
	@echo "  PROGRAMMER=<prog>             avrdude programmer (default: usbasp)"
	@echo "  PORT=<port>                   avrdude port (default: usb)"
	@echo ""
	@echo "Available targets:"
	@echo "  FLAT                          ATMega64, Optrex, no bypass"
	@echo "  ATMEGA64_OPTREX              ATMega64, Optrex, bypass"
	@echo "  ATMEGA64_CRYSTALFONTZ        ATMega64, CrystalFontz, bypass"
	@echo "  ATMEGA64_CRYSTALFONTZ_ALDO   ATMega64, CrystalFontz, bypass, Aldo mod"
	@echo "  ATMEGA64_CRYSTALFONTZ_MFC    ATMega64, CrystalFontz, bypass, MFC mod"
	@echo "  ATMEGA128_CRYSTALFONTZ       ATMega128, CrystalFontz, bypass (default)"
	@echo "  ATMEGA64_VFD                 ATMega64, VFD Noritake, bypass"
	@echo "  ATMEGA64_VFD_NEWHAVEN        ATMega64, VFD Newhaven, bypass"
	@echo "  ATMEGA64_VFD_ALDO            ATMega64, VFD Noritake, bypass, Aldo mod"
	@echo "  ATMEGA128_VFD                ATMega128, VFD Noritake, bypass"
	@echo "  ATMEGA128_VFD_NEWHAVEN       ATMega128, VFD Newhaven, bypass"
