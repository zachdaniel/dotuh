-- Hammerspoon script for global speech-to-text in Dotuh chat
-- Place this in ~/.hammerspoon/init.lua or load it from there

local function sendTextToBrowser(text)
    -- AppleScript to find browser window with Dotuh and insert text
    local script = string.format([[
        tell application "System Events"
            set frontmostApp to name of first application process whose frontmost is true
            set chatAppFound to false
            
            -- Try to find a browser window with "Dotuh" or "Chat" in the title
            repeat with appName in {"Google Chrome", "Safari", "Firefox", "Arc"}
                try
                    tell application appName
                        set windowCount to count of windows
                        repeat with i from 1 to windowCount
                            set windowTitle to title of window i
                            if windowTitle contains "Dotuh" or windowTitle contains "Chat" then
                                set index of window i to 1
                                activate
                                set chatAppFound to true
                                exit repeat
                            end if
                        end repeat
                    end tell
                    if chatAppFound then exit repeat
                end try
            end repeat
            
            if chatAppFound then
                -- Focus on text input and type the text
                delay 0.2
                key code 48 using {cmd down} -- Cmd+Tab to ensure focus
                delay 0.1
                keystroke "%s"
            else
                display notification "Dotuh chat window not found" with title "Speech Input"
            end if
        end tell
    ]], text:gsub('"', '\\"'))
    
    hs.osascript.applescript(script)
end

local function startSpeechRecognition()
    -- Use macOS built-in speech recognition
    local task = hs.task.new("/usr/bin/osascript", function(exitCode, stdOut, stdErr)
        if exitCode == 0 and stdOut and stdOut:len() > 0 then
            local recognizedText = stdOut:gsub("%s+$", "") -- trim whitespace
            if recognizedText:len() > 0 then
                sendTextToBrowser(recognizedText)
                hs.notify.new({
                    title = "Speech Recognition",
                    informativeText = "Text sent to Dotuh: " .. recognizedText
                }):send()
            end
        else
            hs.notify.new({
                title = "Speech Recognition",
                informativeText = "Failed to recognize speech"
            }):send()
        end
    end, {
        "-e",
        [[
        tell application "SpeechRecognitionServer"
            set recognition to recognize speech from microphone
            return recognition
        end tell
        ]]
    })
    
    -- Show notification that we're listening
    hs.notify.new({
        title = "Speech Recognition",
        informativeText = "Listening... Speak now!"
    }):send()
    
    task:start()
end

-- Bind global hotkey (Cmd+Shift+Option+M for global scope)
hs.hotkey.bind({"cmd", "shift", "alt"}, "M", function()
    startSpeechRecognition()
end)

-- Alternative: Use macOS dictation directly
local function triggerDictation()
    -- AppleScript to trigger dictation and send to Dotuh
    local script = [[
        tell application "System Events"
            -- Find and activate Dotuh browser window
            set frontmostApp to name of first application process whose frontmost is true
            set chatAppFound to false
            
            repeat with appName in {"Google Chrome", "Safari", "Firefox", "Arc"}
                try
                    tell application appName
                        set windowCount to count of windows
                        repeat with i from 1 to windowCount
                            set windowTitle to title of window i
                            if windowTitle contains "Dotuh" or windowTitle contains "Chat" then
                                set index of window i to 1
                                activate
                                set chatAppFound to true
                                exit repeat
                            end if
                        end repeat
                    end tell
                    if chatAppFound then exit repeat
                end try
            end repeat
            
            if chatAppFound then
                delay 0.3
                -- Try to click on the text input (you may need to adjust coordinates)
                -- Or use Tab to navigate to input field
                key code 48 -- Tab key
                delay 0.1
                -- Trigger dictation (if enabled in System Preferences)
                key code 0x6A using {fn down} -- Fn+Fn (default dictation shortcut)
            else
                display notification "Dotuh chat window not found" with title "Dictation"
            end if
        end tell
    ]]
    
    hs.osascript.applescript(script)
end

-- Alternative binding for dictation
hs.hotkey.bind({"cmd", "shift", "alt"}, "D", function()
    triggerDictation()
end)

hs.notify.new({
    title = "Dotuh Speech Setup",
    informativeText = "Global shortcuts ready!\nCmd+Shift+Alt+M: Speech recognition\nCmd+Shift+Alt+D: Dictation"
}):send()