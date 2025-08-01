; === AUTO GRAYSCALE CONFIGURATION GUI EXTENDED ===

; Helper Function - Get list of USB drives with label
GetUSBList() {
    list := ""
    DriveGet, drives, List
    Loop, Parse, drives
    {
        drive := A_LoopField . ":\"
        DriveGet, type, Type, %drive%
        if (type = "Removable") {
            DriveGet, label, Label, %drive%
            shownLabel := (label != "") ? label : "Unnamed USB Drive"
            displayName := A_LoopField . ": (" . shownLabel . ")"
            list .= displayName . "|"
        }
    }
    return RTrim(list, "|")
}

;Helper function for display labels
HourFromDisplay(display) {
    if (display = "12 AM")
        return 0
    else if InStr(display, "AM")
        return SubStr(display, 1, InStr(display, " ") - 1)
    else if (display = "12 PM")
        return 12
    else
        return SubStr(display, 1, InStr(display, " ") - 1) + 12
}

; === LOAD CONFIGURATION VALUES FROM FILE ===
IniRead, DayStartHour, config.ini, Schedule, DayStartHour, 7
IniRead, NightStartHour, config.ini, Schedule, NightStartHour, 17
IniRead, LockStartHour, config.ini, Schedule, LockStartHour, 22
IniRead, LockEndHour, config.ini, Schedule, LockEndHour, 6
IniRead, LoopTimeMS, config.ini, Schedule, LoopTime, 60000
IniRead, OverrideEnabled, config.ini, Override, Enabled, 1
IniRead, OverrideSerial, config.ini, Override, Serial, 12345678
IniRead, BlockTaskManager, config.ini, TamperPrevention, BlockTaskManager, 0
IniRead, BlockTaskScheduler, config.ini, TamperPrevention, BlockTaskScheduler, 0
IniRead, BlockCmd, config.ini, TamperPrevention, BlockCmd, 0
IniRead, BlockPowerShell, config.ini, TamperPrevention, BlockPowerShell, 0
IniRead, BlockScriptFolderWindows, config.ini, TamperPrevention, BlockScriptFolderWindows, 0
IniRead, MuteDuringGrayscale, config.ini, Audio, MuteDuringGrayscale, 0

LoopTime := Round(LoopTimeMS / 60000)

HourList(selected) {
    list := ""
    firstSet := false
    Loop, 24 {
        val := A_Index - 1
        display := (val = 0) ? "12 AM"
                : (val < 12) ? val . " AM"
                : (val = 12) ? "12 PM"
                : (val - 12) . " PM"
        
        if (val = selected && val != 0 && !firstSet) {
            list .= display . "||"
            firstSet := true
        } else if (val = selected && val = 0 && !firstSet) {
            list .= display . "||"
            firstSet := true
        } else {
            list .= display . "|"
        }
    }
    return RTrim(list, "|")
}


; === CREATE THE CONFIGURATION EDITOR WINDOW ===
Gui, Add, Text,, === Grayscale Settings ===
Gui, Add, Text,, Day Start Hour:
Gui, Add, DropDownList, vDayStartHour w100, % HourList(DayStartHour)

Gui, Add, Text,, Night Start Hour:
Gui, Add, DropDownList, vNightStartHour w100, % HourList(NightStartHour)

Gui, Add, Checkbox, vMuteDuringGrayscale Checked%MuteDuringGrayscale%, Mute During Grayscale

Gui, Add, Text,, Grayscale Toggle Loop Time (minutes):
Gui, Add, Edit, vLoopTime w100, %LoopTime%

Gui, Add, Text,, === Lockdown Settings ===
Gui, Add, Text,, Lock Start Hour:
Gui, Add, DropDownList, vLockStartHour w100, % HourList(LockStartHour)

Gui, Add, Text,, Lock End Hour:
Gui, Add, DropDownList, vLockEndHour w100, % HourList(LockEndHour)



; === Override Settings ===
Gui, Add, Text,, === Override Settings ===
Gui, Add, Checkbox, vOverrideEnabled Checked%OverrideEnabled%, Enable Override USB
Gui, Add, Text,, Select USB Drive for Override:

usbList := "Use Saved USB Drive||" . GetUSBList()
Gui, Add, DropDownList, vusbDriveList w200, %usbList%

;Logging function
logFile := A_ScriptDir . "\log.txt"
maxLogSize := 5 * 1024 * 1024  ; 5 MB max log size

Log(msg) {
    global logFile, maxLogSize
    FileGetSize, logSize, %logFile%
    if (logSize >= maxLogSize)
        FileDelete, %logFile%
    FormatTime, timestamp,, yyyy-MM-dd HH:mm:ss
    FileAppend, %timestamp% - %msg%`n, %logFile%, UTF-8
}

; === Tamper Prevention ===
Gui, Add, Text,, === Tamper Prevention Blocking ===
Gui, Add, Checkbox, vBlockTaskManager Checked%BlockTaskManager%, Task Manager
Gui, Add, Checkbox, vBlockTaskScheduler Checked%BlockTaskScheduler%, Task Scheduler
Gui, Add, Checkbox, vBlockCmd Checked%BlockCmd%, CMD
Gui, Add, Checkbox, vBlockPowerShell Checked%BlockPowerShell%, PowerShell
Gui, Add, Checkbox, vBlockScriptFolderWindows Checked%BlockScriptFolderWindows%, Script Folder

Gui, Add, Button, Default Center gSaveConfig, Save Config
Gui, Show,, Edit HesychiaHex Config
return

; === SAVE BUTTON HANDLER ===

SaveConfig:
Gui, Submit

Gui, Default
GuiControl, Focus, SaveConfig

;CONVERTS DISPLAY TIME TO NUMERAL
DayStartHour := HourFromDisplay(DayStartHour)
NightStartHour := HourFromDisplay(NightStartHour)
LockStartHour := HourFromDisplay(LockStartHour)
LockEndHour := HourFromDisplay(LockEndHour)

; Validate inputs
if !(LoopTime is number) || LoopTime < 0.1 || LoopTime > 1440 {
    MsgBox, 48, Invalid Input, Loop Time must be a number between 0.1 and 1440 minutes.
    return
}


if (LoopTime < 0 || LoopTime > 1440) {
    MsgBox, 48, Invalid Input, Loop Time must be between 1 and 1440 minutes.
    return
}

LoopTimeMS := Round(LoopTime * 60000)

; Determine serial from selected drive (optional)
if (OverrideEnabled && usbDriveList != "Use Saved USB Drive") {
    RegExMatch(usbDriveList, "([A-Z]:)", driveLetter)
    if (driveLetter != "") {
        DriveGet, selectedSerial, Serial, %driveLetter%\
        if (selectedSerial != "")
            OverrideSerial := selectedSerial
    }
}

; Write config.ini
IniWrite, %DayStartHour%, config.ini, Schedule, DayStartHour
IniWrite, %NightStartHour%, config.ini, Schedule, NightStartHour
IniWrite, %LockStartHour%, config.ini, Schedule, LockStartHour
IniWrite, %LockEndHour%, config.ini, Schedule, LockEndHour
IniWrite, %LoopTimeMS%, config.ini, Schedule, LoopTime
IniWrite, %OverrideEnabled%, config.ini, Override, Enabled
IniWrite, %OverrideSerial%, config.ini, Override, Serial
IniWrite, %BlockTaskManager%, config.ini, TamperPrevention, BlockTaskManager
IniWrite, %BlockTaskScheduler%, config.ini, TamperPrevention, BlockTaskScheduler
IniWrite, %BlockCmd%, config.ini, TamperPrevention, BlockCmd
IniWrite, %BlockPowerShell%, config.ini, TamperPrevention, BlockPowerShell
IniWrite, %BlockScriptFolderWindows%, config.ini, TamperPrevention, BlockScriptFolderWindows
IniWrite, %MuteDuringGrayscale%, config.ini, Audio, MuteDuringGrayscale

; === PROMPT USER TO LOCK WORKSTATION OR NOT ===
MsgBox, 33, Apply Changes?, Settings saved successfully.`n`nClick OK to lock your workstation now so Task Scheduler can apply changes after unlock.`n`nClick Cancel to apply changes later manually.
IfMsgBox OK
{
    Log("User chose to lock workstation after config save.")
    DllCall("LockWorkStation")
}
else
{
    Log("User chose not to lock workstation. Informed about manual restart requirement.")
    MsgBox, 64, Manual Relaunch Required, Changes will not go into effect until you manually restart HesychiaHex.ahk.
}
ExitApp

; === GUI CLOSE HANDLER ===
GuiClose:
ExitApp