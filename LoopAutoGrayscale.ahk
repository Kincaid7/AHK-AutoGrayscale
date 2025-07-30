#NoTrayIcon
SetTitleMatchMode, 2

; === CONFIGURATION ===
global DayStartHour := 8       ; Grayscale OFF during this period
global NightStartHour := 17    ; Grayscale ON after this hour
global LoopTime := 1 * 60000 ; Minutes between loops
global logFile := A_ScriptDir . "\loop_log.txt"
global maxLogSize := 5 * 1024 * 1024  ; 5 MB in bytes

; === LOGGING FUNCTION ===
Log(msg) {
    global logFile, maxLogSize
    FileGetSize, logSize, %logFile%
    if (logSize >= maxLogSize) {
        FileDelete, %logFile%
    }
    FormatTime, timestamp,, yyyy-MM-dd HH:mm:ss
    FileAppend, %timestamp% - %msg%`n, %logFile%, UTF-8
}

; === MAIN SETUP ===
FileAppend, `n, %logFile%, UTF-8
Log("Running as user: " . A_UserName)
Log("Grayscale monitor started.")
Log("Configured DayStartHour: " . DayStartHour)
Log("Configured NightStartHour: " . NightStartHour)

; Run immediately
ToggleGrayscale()

; Run every X minutes
SetTimer, ToggleGrayscale, %LoopTime%

; === Keep the script running ===
#Persistent
return

; === GRAYSCALE TOGGLE LOGIC ===
ToggleGrayscale() {
    try {
        RegRead, active, HKEY_CURRENT_USER\Software\Microsoft\ColorFiltering, Active
        FormatTime, hour,, H
        Log("Check at hour " . hour . " - Grayscale Active: " . active)

        colorActive := (active = 1)
        currentHour := hour + 0  ; ensure numeric

        if ((currentHour >= DayStartHour && currentHour < NightStartHour) && colorActive) {
            Log("Daytime: Grayscale is ON. Toggling OFF.")
            SetKeyDelay, 50, 50
            Send, ^#c
            Sleep, 500
            RegRead, postActive, HKEY_CURRENT_USER\Software\Microsoft\ColorFiltering, Active
            Log("Result: " . (postActive = 0 ? "SUCCESS" : "FAILED") . " - Grayscale OFF")
        }
        else if (((currentHour >= NightStartHour) || (currentHour < DayStartHour)) && !colorActive) {
            Log("Nighttime: Grayscale is OFF. Toggling ON.")
            SetKeyDelay, 50, 50
            Send, ^#c
            Sleep, 500
            RegRead, postActive, HKEY_CURRENT_USER\Software\Microsoft\ColorFiltering, Active
            Log("Result: " . (postActive = 1 ? "SUCCESS" : "FAILED") . " - Grayscale ON")
        }
        else {
            Log("No toggle needed. Current state matches time logic.")
        }
    } catch e {
        Log("ERROR: " . e.Message)
        MsgBox, 48, Grayscale Error, Failed to execute toggle.
    }
}
