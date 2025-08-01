; === HesychiaHex SCRIPT WITH CONFIG FILE AND OVERRIDE SUPPORT ===

#NoTrayIcon              ; Prevents tray icon from appearing
#SingleInstance Force    ; Ensures only one instance is running
#Persistent              ; Keeps script alive

SetTitleMatchMode, 2	; Global substring matching in window titles

WinSetTitle, A,, HesychiaHexScript

SetWorkingDir, %A_ScriptDir%	; Sets working directory so it can find the config file

IfNotExist, config.ini
{
    MsgBox, 16, Config Error, config.ini not found in script folder.`nScript will now exit.
    ExitApp
}


; === CONFIGURATION LOADING ===
; Pull values from config.ini instead of hardcoding
IniRead, DayStartHour, config.ini, Schedule, DayStartHour, 7
IniRead, NightStartHour, config.ini, Schedule, NightStartHour, 17
IniRead, LockStartHour, config.ini, Schedule, LockStartHour, 22
IniRead, LockEndHour, config.ini, Schedule, LockEndHour, 6
IniRead, LoopTime, config.ini, Schedule, LoopTime, 6000
IniRead, MuteDuringGrayscale, config.ini, Schedule, MuteDuringGrayscale, 1

; === TAMPER PREVENTION SETTINGS ===
IniRead, BlockTaskManager,       config.ini, TamperPrevention, BlockTaskManager, 0
IniRead, BlockTaskScheduler,     config.ini, TamperPrevention, BlockTaskScheduler, 0
IniRead, BlockCmd,               config.ini, TamperPrevention, BlockCmd, 0
IniRead, BlockPowerShell,        config.ini, TamperPrevention, BlockPowerShell, 0
IniRead, BlockScriptFolderWindows, config.ini, TamperPrevention, BlockScriptFolderWindows, 0
IniRead, BlockSettings, config.ini, TamperPrevention, BlockSettings, 0

; Override config (USB serial match)
IniRead, OverrideEnabled, config.ini, Override, Enabled, 1
IniRead, OverrideSerial, config.ini, Override, Serial, 00000000

logFile := A_ScriptDir . "\log.txt"
maxLogSize := 5 * 1024 * 1024  ; 5 MB max log size

; === FUNCTION: LOGGING UTILITY ===
Log(msg) {
    global logFile, maxLogSize
    FileGetSize, logSize, %logFile%
    if (logSize >= maxLogSize) {
        FileDelete, %logFile%
    }
    FormatTime, timestamp,, yyyy-MM-dd HH:mm:ss
    FileAppend, %timestamp% - %msg%`n, %logFile%, UTF-8
}

; === FUNCTION: CHECK USB OVERRIDE ===
ShouldOverride() {
    global OverrideEnabled, OverrideSerial
    static lastOverrideDrive := ""

    if (!OverrideEnabled)
        return false

    DriveGet, drives, List
    Loop, Parse, drives
    {
        drive := A_LoopField . ":"
        DriveGet, type, Type, %drive%
        if (type = "Removable") {
            DriveGet, serial, Serial, %drive%\
            if (serial = OverrideSerial) {
                if (lastOverrideDrive != drive) {
                    lastOverrideDrive := drive
                    Log("Override USB detected in drive " . drive)
                    Sleep, 200
                    MsgBox, 64, HesychiaHex, HesychiaHex.ahk Override USB detected in drive %drive% `nAnti-Tamper controls and Lockdown disabled until removal.
                }
                return true
            }
        }
    }

    ; If override is no longer detected, clear cached state
    if (lastOverrideDrive != "") {
        lastOverrideDrive := ""
        Log("Override USB no longer detected.")
        MsgBox, 48, HesychiaHex, HesychiaHex.ahk Override USB has been removed.`nTamper controls and Lockdown period are enabled again.
    }

    return false
}


; === LOGGING STARTUP STATE ===
FileAppend, `n, %logFile%, UTF-8
Log("Running as user: " . A_UserName)
Log("HesychiaHex Checking Toggle")
Log("Configured Daylight Hours: " . DayStartHour . " to " . NightStartHour)
Log("Configured Lock Hours: " . LockStartHour . " to " . LockEndHour)
Log("Configured Grayscale LoopTime: " . Floor(LoopTime / 60000) . " minutes")

; === IMMEDIATE GRAYSCALE CHECK ===
ToggleGrayscale()

; === SET LOOP TIMER ===
SetTimer, ToggleGrayscale, %LoopTime%
SetTimer, HandleTampering, 1000

return

ToggleGrayscale() {
    global DayStartHour, NightStartHour, LockStartHour, LockEndHour, MuteDuringGrayscale

    try {
        RegRead, active, HKEY_CURRENT_USER\Software\Microsoft\ColorFiltering, Active
        FormatTime, hour,, H
        currentHour := hour + 0  ; ensure numeric
        colorActive := (active = 1)

        ; === DAYTIME: Grayscale should be OFF ===
        if ((currentHour >= DayStartHour && currentHour < NightStartHour) && colorActive) {
            Log("Daytime: Grayscale is ON. Toggling OFF.")
            SendGrayscaleToggle()
        }

        ; === NIGHTTIME: Grayscale should be ON ===
        else {
            if (!colorActive) {
                Log("Nighttime: Grayscale is OFF. Toggling ON.")
                SendGrayscaleToggle()
            }

            ; Ensure MUTE during nighttime
            if (MuteDuringGrayscale) {
                SoundGet, isMuted,, mute
                Log("Mute check result: [" . isMuted . "]")

                ; Normalize string to numeric
                if (isMuted = "On" || isMuted = 1 || isMuted = "1") {
                    ; Already muted, do nothing
                } else {
                    SoundSet, 1,, mute
                    Log("System muted during nighttime.")
                }
            }
        }
    } catch e {
        Log("ERROR: " . e.Message)
        MsgBox, 48, Grayscale Error, Failed to execute toggle.
    }

    ; === LOCK ENFORCEMENT ===
    FormatTime, currentHour,, H
    currentHour := currentHour + 0  ; ensure numeric

    if (!ShouldOverride() && ((LockStartHour < LockEndHour && currentHour >= LockStartHour && currentHour < LockEndHour)
     || (LockStartHour > LockEndHour && (currentHour >= LockStartHour || currentHour < LockEndHour)))) {
        Log("Lock condition met, Locking workstation.")
        DllCall("LockWorkStation")
    }
}



; === FUNCTION: SEND GRAYSCALE TOGGLE HOTKEY ===
SendGrayscaleToggle() {
    SetKeyDelay, 50, 50
    Send, ^#c
    Sleep, 500
    RegRead, postActive, HKEY_CURRENT_USER\Software\Microsoft\ColorFiltering, Active
    Log("Post-toggle filter status: " . (postActive = 1 ? "ON" : "OFF"))
}

HandleTampering() {
    global BlockTaskManager, BlockTaskScheduler, BlockCmd, BlockPowerShell, BlockScriptFolderWindows, BlockSettings, DayStartHour, NightStartHour

    FormatTime, currentHour,, H
    currentHour := currentHour + 0  ; ensure numeric

    if (ShouldOverride()) {
        return
    }

    ; === Only continue if we are outside daytime hours ===
    if ((DayStartHour < NightStartHour && (currentHour >= NightStartHour || currentHour < DayStartHour))
     || (DayStartHour > NightStartHour && (currentHour >= NightStartHour || currentHour < DayStartHour))) {

        if (BlockTaskManager && WinExist("ahk_exe Taskmgr.exe")) {
            WinClose
            MsgBox, 48, HesychiaHex, Access Denied. Viewing the Task Manager during grayscale hours without USB override is restricted. See Config File.  In case of emergency, reboot PC in safe mode and edit configuration.
            Log("Tamper attempt: Task Manager closed.")
        }

        if (BlockTaskScheduler && WinExist("Task Scheduler")) {
            WinClose
            MsgBox, 48, HesychiaHex, Access Denied. Viewing the Task Scheduler during grayscale hours without USB override is restricted. See Config File.  In case of emergency, reboot PC in safe mode and edit configuration.
            Log("Tamper attempt: Task Scheduler closed.")
        }

        if (BlockCmd && WinExist("ahk_exe cmd.exe")) {
            WinClose
            MsgBox, 48, HesychiaHex, Access Denied. Viewing the Command Prompt during grayscale hours without USB override is restricted. See Config File.  In case of emergency, reboot PC in safe mode and edit configuration.
            Log("Tamper attempt: Command Prompt closed.")
        }

        if (BlockPowerShell && WinExist("Windows PowerShell")) {
            WinClose
            MsgBox, 48, Access Denied, Viewing the Powershell during grayscale hours without USB override is restricted. See Config File.  In case of emergency, reboot PC in safe mode and edit configuration.
            Log("Tamper attempt: PowerShell closed.")
        }

	if (BlockSettings && WinExist("Settings ahk_exe ApplicationFrameHost.exe")) {
	    WinClose
	    MsgBox, 48, HesychiaHex, Access Denied.`nModern Settings app is restricted during grayscale hours.`nUse USB override or Safe Mode to bypass.
	    Log("Tamper attempt: Modern Settings window closed.")
	}
	
	if (BlockSettings && WinExist("Date and Time ahk_exe rundll32.exe")) {
	    WinClose
	    MsgBox, 48, HesychiaHex, Access Denied.`nDate and Time control panel is restricted during grayscale hours.`nUse USB override or Safe Mode to bypass.
	    Log("Tamper attempt: Date and Time panel closed.")
	}

	if (BlockSettings && WinExist("Region ahk_exe rundll32.exe")) {
	    WinClose
	    MsgBox, 48, HesychiaHex, Access Denied.`nRegion control panel is restricted during grayscale hours.`nUse USB override or Safe Mode to bypass.
	    Log("Tamper attempt: Region panel closed.")
	}


        if (BlockScriptFolderWindows) {
            for window in ComObjCreate("Shell.Application").Windows {
                try {
                    folder := window.Document.Folder.Self.Path
                    if (InStr(folder, A_ScriptDir)) {
                        WinClose, % "ahk_id " . window.HWND
                        MsgBox, 48, HesychiaHex, Access Denied. Viewing the Script Directory during grayscale hours without USB override is restricted. See Config File.  In case of emergency, reboot PC in safe mode and edit configuration.
                        Log("Tamper attempt: Explorer window showing script directory closed.")
                    }
                } catch e {
                    ; Silently skip any non-Explorer windows
                }
            }
        }

    }
}
