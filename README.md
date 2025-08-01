# HesychiaHex — PC Discipline & Grayscale-Lock Suite

## 📜 Overview
HesychiaHex is an **AutoHotkey v1** toolkit that

* Toggles **Windows Color-Filter → Grayscale** **ON** at night and **OFF** during the day.  
* Optionally **locks** the workstation during a configurable “lock window.”  
* Contains modular anti-tampering tools by blocking Task Manager, Task Scheduler, CMD, PowerShell, the script’s own folder, and Windows Settings when grayscale is active (unless a configurable bypass USB is inserted).  
* Can **mute system volume** during grayscale hours.  
* Stores all settings in `config.ini` and logs events to `log.txt` (auto-pruned at 5 MB).

Use Task Scheduler so it restarts at logon / unlock. Great for late-night deterrence, parental control, study focus, or digital asceticism.

---

## ⚙️ Requirements
1. **Enable Windows color-filter hotkey**  
   * `Win + R` → `ms-settings:easeofaccess-colorfilter`  
   * Turn on **Shortcut key**.  
   * Choose **Grayscale** (or any filter you prefer).  

2. **AutoHotkey v1.1 (ANSI or Unicode)**  
   * *Do not* use v2.  
   * Download: <https://www.autohotkey.com/download/ahk-install.exe>

---

## 🛠 Configuration

Two key files:

| File | Purpose |
|------|---------|
| **`HesychiaHex.ahk`** | main enforcement script |
| **`HesychiaHex_ConfigEditor.ahk`** | GUI editor that writes `config.ini` |

Run the **config-editor** after download and whenever you want to reconfigure the parameters of the script. These settings are saved into `config.ini`. 

💡 **NOTE:** To set up a USB bypass key for disabling anti-tampering and lockout features:

1. Plug in your USB drive **before** opening the configuration editor.
2. In the dropdown menu, select the USB drive you want to use.
3. When you click **Save**, the script records that drive’s serial number to the config file.

From then on, plugging in that USB acts as a **physical override key**:
- Tamper protection and lockouts will be disabled.
- Grayscale and audio muting (if enabled) will still apply.
- You can relaunch the config editor freely to adjust your settings at any time.


```ini
[Schedule]
DayStartHour   = 6     ; grayscale OFF from 06:00
NightStartHour = 22    ; grayscale ON after 22:00
LockStartHour  = 23    ; workstation locks at 23:00
LockEndHour    = 4     ; unlock window ends at 04:00
LoopTime       = 6000  ; ms between loops (6000 ms = 0.1 min)

[Override]
Enabled = 1
Serial  = 12345678    ; USB serial that bypasses locks / blocks

[TamperPrevention]
BlockTaskManager          = 1
BlockTaskScheduler        = 1
BlockCmd                  = 1
BlockPowerShell           = 1
BlockScriptFolderWindows  = 1
BlockSettings             = 1

[Audio]
MuteDuringGrayscale = 1
```
* `LoopTime` is stored in **milliseconds**; the GUI shows exact decimal **minutes** (e.g. `0.1`).
---

## 🕒 Task Scheduler Setup

### Step 1 — Create Task
**General tab**  
- **Name**: `HesychiaHex`  
- **Run only when user is logged on**  
- **Run with highest privileges**

### Step 2 — Triggers
- **At logon**  
- **At workstation unlock**  
  - *(Ensure both are enabled)*

### Step 3 — Action
- **Start a program** →  
  - **Program**: `C:\Program Files\AutoHotkey\AutoHotkey.exe`  
  - **Add arguments**: `"C:\Path\To\HesychiaHex.ahk"`

### Step 4 — Settings
- **Conditions tab** → *uncheck everything*  
- **Settings tab** →  
  - “If the task is already running” → **Stop the existing instance**

---

## 📓 Logging
A file called `log.txt` (in the same folder) records every toggle, lock, or tamper event.  
If it exceeds **5 MB**, it is automatically purged and reset.

---

## 📴 Usage Tips
- **Emergency**: Boot into **Safe Mode**, then edit `config.ini` using the config-editor
- Manual grayscale toggle: **Ctrl + Win + C**  
  *(The script will re-toggle on next loop.)*
- If a tamper block triggers incorrectly, plug in your **override USB** or update `config.ini` using the config-editor

---

## 🙏 Name Meaning
**Hesychia** (ἡσυχία) = Stillness / Disciplined Quiet  
**Hex** = The “spell” enforcing it  
Stay focused. Tame the machine.
