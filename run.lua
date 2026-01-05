local GITHUB_USER = "FanyaOff"
local GITHUB_REPO = "HyhryaFactoryBaza"
local BRANCH = "main"
local SCRIPT_NAME = "main.lua"

local GITHUB_URL = "https://raw.githubusercontent.com/" .. GITHUB_USER .. "/" .. GITHUB_REPO .. "/" .. BRANCH .. "/" .. SCRIPT_NAME

local function log(msg)
    print("[AutoUpdate] " .. os.date("%H:%M:%S") .. " - " .. msg)
end

local function downloadScript()
    log("Downloading " .. SCRIPT_NAME .. " from GitHub...")
    log("URL: " .. GITHUB_URL)

    local response = http.get(GITHUB_URL)
    if not response then
        log("ERROR: Failed to connect to GitHub")
        return false
    end
    
    local content = response.readAll()
    response.close()
    
    if not content or content == "" then
        log("ERROR: Received empty content")
        return false
    end
    
    local file = fs.open(SCRIPT_NAME, "w")
    if not file then
        log("ERROR: Failed to create file")
        return false
    end
    
    file.write(content)
    file.close()
    
    log("SUCCESS: Downloaded " .. SCRIPT_NAME)
    return true
end

local function runScript()
    if fs.exists(SCRIPT_NAME) then
        log("Running " .. SCRIPT_NAME)
        shell.run("lua " .. SCRIPT_NAME)
    else
        log("ERROR: " .. SCRIPT_NAME .. " not found")
        return false
    end
    return true
end

local function main()
    log("GitHub: " .. GITHUB_USER .. "/" .. GITHUB_REPO .. " (branch: " .. BRANCH .. ")")
    
    local downloaded = downloadScript()
    
    local ran = runScript()
    
    if downloaded and ran then
        log("Script updated and executed successfully")
        log("Restarting to apply updates...")
        os.reboot()
    elseif ran then
        log("Script executed (no update available)")
    else
        log("ERROR: Failed to execute script")
    end
end

main()