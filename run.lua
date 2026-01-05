local GITHUB_USER = "your-username"
local GITHUB_REPO = "your-repo"
local BRANCH = "main"
local MAIN_SCRIPT = "main.lua"
local UPDATE_INTERVAL = 300

local API_BASE = "https://api.github.com/repos/" .. GITHUB_USER .. "/" .. GITHUB_REPO
local RAW_BASE = "https://raw.githubusercontent.com/" .. GITHUB_USER .. "/" .. GITHUB_REPO .. "/" .. BRANCH

local COMMIT_FILE = ".last_commit"

local function log(msg)
    print("[AutoUpdate] " .. os.date("%H:%M:%S") .. " - " .. msg)
end

local function checkInternet()
    local success, response = pcall(http.get, "https://www.google.com", nil, 5)
    if success and response then
        response.close()
        return true
    end
    return false
end

local function getLatestCommit()
    local url = API_BASE .. "/commits/" .. BRANCH
    local response = http.get(url)
    if not response then
        return nil, "Failed to connect to GitHub API"
    end
    
    local data = response.readAll()
    response.close()
    
    local json = textutils.unserializeJSON(data)
    if json and json.sha then
        return json.sha
    end
    
    return nil, "Failed to parse commit data"
end

local function getRepositoryFiles()
    local url = API_BASE .. "/contents"
    local response = http.get(url)
    if not response then
        return nil, "Failed to get repository contents"
    end
    
    local data = response.readAll()
    response.close()
    
    local files = textutils.unserializeJSON(data)
    if not files then
        return nil, "Failed to parse repository contents"
    end
    
    return files
end

local function downloadFile(filePath, localPath)
    local url = RAW_BASE .. "/" .. filePath
    local response = http.get(url)
    if not response then
        return false, "Failed to download " .. filePath
    end
    
    local content = response.readAll()
    response.close()
    
    local dir = localPath:match("(.*/)")
    if dir then
        shell.run("mkdir -p " .. dir)
    end
    
    local file = fs.open(localPath, "w")
    if file then
        file.write(content)
        file.close()
        return true
    end
    
    return false, "Failed to write " .. localPath
end

local function updateFiles()
    log("Checking for updates...")
    
    local files, err = getRepositoryFiles()
    if not files then
        log("Error: " .. err)
        return false
    end
    
    local updated = false
    for _, file in ipairs(files) do
        if file.type == "file" then
            local success, msg = downloadFile(file.path, file.name)
            if success then
                log("Updated: " .. file.name)
                updated = true
            else
                log("Failed to update " .. file.name .. ": " .. msg)
            end
        end
    end
    
    return updated
end

local function saveCommitHash(hash)
    local file = fs.open(COMMIT_FILE, "w")
    if file then
        file.write(hash)
        file.close()
        return true
    end
    return false
end

local function loadCommitHash()
    local file = fs.open(COMMIT_FILE, "r")
    if file then
        local hash = file.readAll()
        file.close()
        return hash:match("%S+")
    end
    return nil
end

local function checkForUpdates()
    if not checkInternet() then
        log("No internet connection")
        return false
    end
    
    local latestCommit, err = getLatestCommit()
    if not latestCommit then
        log("Error getting latest commit: " .. err)
        return false
    end
    
    local lastCommit = loadCommitHash()
    
    if lastCommit ~= latestCommit then
        log("New version detected!")
        local updated = updateFiles()
        if updated then
            saveCommitHash(latestCommit)
            log("Update completed successfully")
            return true
        else
            log("Update failed")
            return false
        end
    else
        log("Already up to date")
        return false
    end
end

local function runMainScript()
    if fs.exists(MAIN_SCRIPT) then
        log("Running " .. MAIN_SCRIPT)
        shell.run("lua " .. MAIN_SCRIPT)
    else
        log("Main script not found: " .. MAIN_SCRIPT)
    end
end

local function main()
    log("Starting Auto-Update System")
    log("Repository: " .. GITHUB_USER .. "/" .. GITHUB_REPO .. " (branch: " .. BRANCH .. ")")
    
    local updated = checkForUpdates()
    
    runMainScript()
    
    if updated then
        log("Restarting to apply updates...")
        os.reboot()
    end
    

end

main()