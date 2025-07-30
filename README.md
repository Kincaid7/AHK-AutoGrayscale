**README — Grayscale Toggle Auto Enforcement Script**

📜 **Overview**

This AHK script, when leveraged with Task Scheduler, automatically toggles Windows grayscale mode ON at night and OFF during the day, based on your defined hours. It is designed to discourage late-night PC usage by keeping grayscale on unless it's your configured daytime hours.

It runs silently, appending logs to a file for troubleshooting and purging the log if it exceeds 5MB.

⚙️ **Requirements**

**Enable Color Filter Hotkey**

To check your Color Filter Settings

Ctrl+R to open the Run Tool

Input: ms-settings:easeofaccess-colorfilter to open the setting page

Then ensure the shortcut key is enabled

_You should also enable the color filter and select Grayscale, or whatever Filter you want applied when toggled. You can turn it off right after._

**AutoHotkey Version: v1.1+**

This script was written for AutoHotkey v1.1 (ANSI or Unicode). Do not use AutoHotkey v2—it is not compatible.

Download AutoHotkey v1.1 here:
https://www.autohotkey.com/download/ahk-install.exe

🛠 **Configuration**

Open the script in any text editor. The configurable section is at the top:

global DayStartHour := 8       ; Grayscale OFF during this period

global NightStartHour := 17    ; Grayscale ON after this hour

global LoopTime := 1 * 60000 ; Minutes between loops

DayStartHour: The hour (24h format) when grayscale should turn off.

NightStartHour: The hour (24h format) when grayscale should turn on.

LoopTime: The amount of minutes you want before looping


Example:

8 means 8:00 AM

17 means 5:00 PM

The log file is stored in the same folder as the script and is automatically reset if it exceeds 5MB.

🕒 **How to Set Up the Script with Task Scheduler**

To ensure the script runs automatically every 5 minutes only when you're logged in, follow these steps:

✅ **Step 1: Create a Task**

Open Task Scheduler

Click “Create Task”

On the General tab:

Name: Anything (Grayscale Toggle)

Check: Run only when user is logged on

Check: Run with highest privileges

Configure for: Windows 10/11

🔁 **Step 2: Add a Trigger**

Go to the Triggers tab → Click New...

Begin the task: At Logon

Click New Again...

Begin the task: At Workstation Unlock

_Ensure enabled is checked_

⚙️ **Step 3: Add an Action**

Go to the Actions tab → Click New...

Action: Start a program

Program/script:
Browse to your installed AutoHotkey.exe
(e.g., C:\Program Files\AutoHotkey\AutoHotkey.exe)

Add arguments (replace with your script path):
"C:\Path\To\AutoGrayscale.ahk"

Click OK

🧹 **Step 4: Additionaol Task Options**

If you tested with “basic tasks,” go back and delete them to avoid conflicts.

Under the Conditions Tab, uncheck all boxes, including Start the task only if the computer is on AC power if using a laptop

Under settings, ensure that If the task is already running behavior is set to "Stop the existing instance"


📓 **Logging**

A file named log.txt will be created in the same folder.

Every script run appends a timestamped entry.

If the file exceeds 5MB, it is deleted automatically and started fresh.

📴 **Usage Tip**

You can still toggle grayscale manually via Ctrl + Win + C (Windows hotkey).
However, this script will re-toggle according to your Task Scheduler settings to keep you accountable.

If you encounter permission issues, try running the script or Task Scheduler as Administrator.
