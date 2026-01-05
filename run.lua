-- Simple ComputerCraft Auto-Update Script
-- Downloads main.lua from GitHub and runs it

-- Configuration - CHANGE THESE VALUES
local GITHUB_USER = "FanyaOff"  -- Your GitHub username
local GITHUB_REPO = "HyhryaFactoryBaza"      -- Your repository name  
local BRANCH = "main"                -- Branch name
local SCRIPT_NAME = "main.lua"       -- Script to download and run

-- Build the raw GitHub URL
local GITHUB_URL = "https://raw.githubusercontent.com/" .. GITHUB_USER .. "/" .. GITHUB_REPO .. "/" .. BRANCH .. "/" .. SCRIPT_NAME

-- Function to print with timestamp
local function log(msg)
    print("[AutoUpdate] " .. os.date("%H:%M:%S") .. " - " .. msg)
end

-- Function to download the script from GitHub
local function downloadScript()
    log("Downloading " .. SCRIPT_NAME .. " from GitHub...")
    log("URL: " .. GITHUB_URL)
    
    -- Try to download the script
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
    
    -- Save the script
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

-- Function to run the downloaded script
local function runScript()
    if fs.exists(SCRIPT_NAME) then
        log("Running " .. SCRIPT_NAME)
        -- Execute the script
        shell.run("lua " .. SCRIPT_NAME)
    else
        log("ERROR: " .. SCRIPT_NAME .. " not found")
        return false
    end
    return true
end

-- Main function
local function main()
    log("Starting Auto-Update Script")
    log("GitHub: " .. GITHUB_USER .. "/" .. GITHUB_REPO .. " (branch: " .. BRANCH .. ")")
    
    -- Download the script
    local downloaded = downloadScript()
    
    -- Try to run it regardless of download success
    local ran = runScript()
    
    if downloaded and ran then
        log("Script updated and executed successfully")
    elseif ran then
        log("Script executed (no update available)")
    else
        log("ERROR: Failed to execute script")
    end
end

-- Run the main function
main()