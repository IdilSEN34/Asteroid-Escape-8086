# Asteroid Escape (8086 Assembly)

An interactive retro arcade game developed using **Intel 8086 Assembly** language. This project was created as part of the Microprocessors course at **Marmara University**, Computer Engineering Department.

## 🎮 Game Overview
"Asteroid Escape" is a real-time survival game where the player controls a ship at the bottom of the screen to avoid falling asteroids. The game demonstrates low-level hardware interaction, memory management, and real-time data processing under limited hardware resources.

### Key Features
* **Flicker-Free Graphics:** Implemented using the `AX=0600h` BIOS scroll function to minimize screen flickering during frame updates.
* **Pseudo-Random Mechanics:** Asteroid positions and types are generated using the system clock (`INT 1Ah`) as a seed.
* **Power-up System:** Includes a blue shield item (indicated by a '+' character) that grants the player one-time protection from collisions.
* **Dynamic Difficulty:** Features different asteroid types, including fast-moving hazards signaled by '!' characters.

## 🛠️ Technical Specifications
* **Architecture:** Intel 80x86.
* **Video Mode:** Standard 80x25 Text Mode (BIOS INT 10h / `AX=0003h`) with 16-color support.
* **Input Handling:** Non-blocking keyboard I/O using `INT 16h` for smooth gameplay movement.
* **Timing:** Frame rate stabilization achieved through `INT 15h` microsecond delay functions.

## 🚀 How to Run
1. Download and install the **emu8086** emulator.
2. Open `mikroislemci_proje.asm` in the emulator.
3. Click `Emulate` and then `Run`.

## 📁 Project Structure
* `/src`: Contains the original and commented Assembly source codes.
* `/docs`: Includes the formal project report (PDF) detailing the system architecture.
* `/assets`: Screenshots and visual documentation of the game.

## 🎓 Academic Context
* **Institution:** Marmara University
* **Course:** BLM2008 - Microprocessors
* **Developer:** İdil ŞEN
