#NoTrayIcon
SetTitleMatchMode, 2

; === CONFIGURATION ===
global DayStartHour := 8       ; Grayscale OFF during this period
global NightStartHour := 17    ; Grayscale ON after this hour

global logFile := A_ScriptDir . "\log.txt"

; === LOGGING FUNCTION ===
Log(msg) {
    global logFile
    FormatTime, timestamp,, yyyy-MM-dd HH:mm:ss
    FileAppend, %timestamp% - %msg%`n, %logFile%, UTF-8
}

; === MAIN EXECUTION ===
try {
    ; Spacer between runs
    FileAppend, `n, %logFile%, UTF-8
    Log("Running as user: " . A_UserName)

    Log("Starting grayscale toggle check.")
    Log("Configured DayStartHour: " . DayStartHour)
    Log("Configured NightStartHour: " . NightStartHour)

    RegRead, active, HKEY_CURRENT_USER\Software\Microsoft\ColorFiltering, Active
    FormatTime, hour,, H

    Log("Current hour: " . hour)
    Log("ColorFiltering Active state: " . active)

    colorActive := (active = 1)
    currentHour := hour + 0  ; ensure numeric

    ; Determine if action is needed
    if ((currentHour >= DayStartHour && currentHour < NightStartHour) && colorActive)
    {
        Log("Condition met: Grayscale is ON during daytime hours. Toggling OFF.")
        SetKeyDelay, 50, 50
        Send, ^#c
        Sleep, 500
        RegRead, postActive, HKEY_CURRENT_USER\Software\Microsoft\ColorFiltering, Active
        Log("Post-toggle ColorFiltering Active state: " . postActive)
        if (postActive = 0)
            Log("Toggle SUCCESSFUL: Grayscale disabled.")
        else
            Log("Toggle FAILED: Grayscale still enabled. Run with highest privileges.")
    }
    else if (((currentHour >= NightStartHour) || (currentHour < DayStartHour)) && !colorActive)
    {
        Log("Condition met: Grayscale is OFF during night hours. Toggling ON.")
        SetKeyDelay, 50, 50
        Send, ^#c
        Sleep, 500
        RegRead, postActive, HKEY_CURRENT_USER\Software\Microsoft\ColorFiltering, Active
        Log("Post-toggle ColorFiltering Active state: " . postActive)
        if (postActive = 1)
            Log("Toggle SUCCESSFUL: Grayscale enabled.")
        else
            Log("Toggle FAILED: Grayscale still disabled. Run with highest privileges.")
    }
    else if ((currentHour >= DayStartHour && currentHour < NightStartHour) && !colorActive)
    {
        Log("Condition not met: Grayscale is OFF during daytime hours. No action needed.")
    }
    else if (((currentHour >= NightStartHour || currentHour < DayStartHour) && colorActive))
    {
        Log("Condition not met: Grayscale is already ON during night hours. No action needed.")
    }
    else
    {
        Log("Unhandled state: hour=" . currentHour . ", grayscale=" . colorActive)
    }

} catch e {
    Log("ERROR: " . e.Message)
    MsgBox, 48, Grayscale Error, Failed to execute toggle.
}

ExitApp
