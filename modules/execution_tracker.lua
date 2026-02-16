-- ========================================
-- VELAWARE EXECUTION TRACKER
-- Murder vs Sheriff Duels ONLY
-- ========================================
local FirebaseSystem = {}

-- ========================================
-- GAME WHITELIST
-- ========================================
local ALLOWED_GAMES = {
    [12355337193] = true, -- Murder vs Sheriff Duels
}

-- Check if we're in the right game
print("[Velaware] Current PlaceId:", game.PlaceId)
if not ALLOWED_GAMES[game.PlaceId] then
    warn("[Velaware] Not in Murder vs Sheriff Duels - tracking disabled")
    return {
        Initialize = function() end,
        TrackExecution = function() end
    }
end
print("[Velaware] Game verified - MVSD detected")

-- ========================================
-- CONFIGURATION
-- ========================================
FirebaseSystem.Config = {
    Enabled = true,
    DatabaseURL = "https://velaware-default-rtdb.firebaseio.com/",
    WebhookURL = "https://discord.com/api/webhooks/1472734715986579590/3sRnVA7XNPwZqZK7jtnpLGNyh2iHqNrKa0dZaVVx9dEL74DB4TeY0FGdm6-4yXdy739Z",
    SendWebhook = true,
}

FirebaseSystem.State = {
    SessionID = game:GetService("HttpService"):GenerateGUID(false),
    UserExecutions = 0,
    GlobalExecutions = 0,
}

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================
local function GetHWID()
    -- Try multiple HWID methods
    if gethwid then
        return gethwid()
    elseif syn and syn.request then
        return game:GetService("RbxAnalyticsService"):GetClientId()
    else
        -- Fallback: Generate persistent ID based on executor + user
        local HttpService = game:GetService("HttpService")
        local Players = game:GetService("Players")
        local fallback = HttpService:GenerateGUID(false) .. "_" .. Players.LocalPlayer.UserId
        return fallback
    end
end

local function GetExecutorName()
    local executors = {
        ["Synapse X"] = syn,
        ["Script-Ware"] = SCRIPT_WARE_VERSION,
        ["KRNL"] = KRNL_LOADED,
        ["Fluxus"] = fluxus,
        ["Arceus X"] = arceus,
        ["Delta"] = is_delta,
        ["Oxygen U"] = is_oxygen,
        ["Trigon"] = trigon,
        ["Solara"] = SOLARA_LOADED,
        ["Wave"] = WAVE_LOADED,
    }
    
    for name, check in pairs(executors) do
        if check then return name end
    end
    
    return identifyexecutor and identifyexecutor() or "Unknown"
end

local function GetRequestFunc()
    return http_request or request or (syn and syn.request) or (http and http.request)
end

local function GetAccountAge()
    local player = game.Players.LocalPlayer
    return player.AccountAge
end

local function IsPremium()
    local player = game.Players.LocalPlayer
    local success, isPremium = pcall(function()
        return player.MembershipType == Enum.MembershipType.Premium
    end)
    return success and isPremium or false
end

-- ========================================
-- FIREBASE OPERATIONS
-- ========================================
function FirebaseSystem.LogExecution(executionData)
    task.spawn(function()
        pcall(function()
            local reqFunc = GetRequestFunc()
            if not reqFunc then return end
            
            reqFunc({
                Url = FirebaseSystem.Config.DatabaseURL .. "velaware_mvsd/executions.json",
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = game:GetService("HttpService"):JSONEncode(executionData)
            })
        end)
    end)
end

function FirebaseSystem.UpdateUserStats(userId, executionData)
    task.spawn(function()
        pcall(function()
            local reqFunc = GetRequestFunc()
            if not reqFunc then return end
            
            local userStats = {
                username = executionData.username,
                displayName = executionData.displayName,
                hwid = executionData.hwid,
                lastSeen = executionData.timestamp,
                lastExecutor = executionData.executor,
                lastDevice = executionData.device,
                accountAge = executionData.accountAge,
                isPremium = executionData.isPremium,
                totalExecutions = FirebaseSystem.State.UserExecutions,
            }
            
            reqFunc({
                Url = FirebaseSystem.Config.DatabaseURL .. "velaware_mvsd/users/" .. userId .. ".json",
                Method = "PUT",
                Headers = {["Content-Type"] = "application/json"},
                Body = game:GetService("HttpService"):JSONEncode(userStats)
            })
        end)
    end)
end

function FirebaseSystem.TrackHWID(hwid, executionData)
    task.spawn(function()
        pcall(function()
            local reqFunc = GetRequestFunc()
            if not reqFunc then return end
            
            -- Track unique HWIDs
            local hwidHash = game:GetService("HttpService"):GenerateGUID(false):sub(1, 8)
            local hwidData = {
                userId = executionData.userId,
                username = executionData.username,
                lastSeen = executionData.timestamp,
                executor = executionData.executor,
            }
            
            reqFunc({
                Url = FirebaseSystem.Config.DatabaseURL .. "velaware_mvsd/hwids/" .. hwidHash .. ".json",
                Method = "PUT",
                Headers = {["Content-Type"] = "application/json"},
                Body = game:GetService("HttpService"):JSONEncode(hwidData)
            })
        end)
    end)
end

function FirebaseSystem.IncrementCounters()
    local success, globalCount, userCount = pcall(function()
        local userId = tostring(game.Players.LocalPlayer.UserId)
        local reqFunc = GetRequestFunc()
        if not reqFunc then return 0, 0 end
        
        -- Global counter for MVSD only
        local globalUrl = FirebaseSystem.Config.DatabaseURL .. "velaware_mvsd/counters/global.json"
        local globalResponse = game:HttpGet(globalUrl)
        local currentGlobal = 0
        
        if globalResponse and globalResponse ~= "null" then
            currentGlobal = tonumber(game:GetService("HttpService"):JSONDecode(globalResponse)) or 0
        end
        
        local newGlobal = currentGlobal + 1
        
        reqFunc({
            Url = globalUrl,
            Method = "PUT",
            Headers = {["Content-Type"] = "application/json"},
            Body = game:GetService("HttpService"):JSONEncode(newGlobal)
        })
        
        -- User counter
        local userUrl = FirebaseSystem.Config.DatabaseURL .. "velaware_mvsd/counters/users/" .. userId .. ".json"
        local userResponse = game:HttpGet(userUrl)
        local currentUser = 0
        
        if userResponse and userResponse ~= "null" then
            currentUser = tonumber(game:GetService("HttpService"):JSONDecode(userResponse)) or 0
        end
        
        local newUser = currentUser + 1
        
        reqFunc({
            Url = userUrl,
            Method = "PUT",
            Headers = {["Content-Type"] = "application/json"},
            Body = game:GetService("HttpService"):JSONEncode(newUser)
        })
        
        return newGlobal, newUser
    end)
    
    if success then
        FirebaseSystem.State.GlobalExecutions = globalCount
        FirebaseSystem.State.UserExecutions = userCount
    end
end

-- ========================================
-- DISCORD WEBHOOK
-- ========================================
function FirebaseSystem.SendWebhook(executionData)
    print("[Velaware] Attempting to send webhook...")
    task.spawn(function()
        local success, err = pcall(function()
            local reqFunc = GetRequestFunc()
            if not reqFunc then 
                warn("[Velaware] No request function available!")
                return 
            end
            
            print("[Velaware] Request function found, building embed...")
            
            local premiumBadge = executionData.isPremium and " 👑" or ""
            
            local embed = {
                ["embeds"] = {{
                    ["title"] = "🎯 Velaware Execution - MVSD",
                    ["description"] = "**Murder vs Sheriff Duels execution tracked**",
                    ["color"] = 9055743,
                    ["fields"] = {
                        {
                            ["name"] = "👤 Player" .. premiumBadge,
                            ["value"] = string.format(
                                "```\n%s (@%s)\nUserID: %s\nAge: %d days\n```",
                                executionData.displayName,
                                executionData.username,
                                executionData.userId,
                                executionData.accountAge
                            ),
                            ["inline"] = true
                        },
                        {
                            ["name"] = "🎮 Game",
                            ["value"] = "```\nMurder vs Sheriff Duels\nPlaceID: 12355337193\n```",
                            ["inline"] = true
                        },
                        {
                            ["name"] = "📱 Device",
                            ["value"] = executionData.device == "Mobile" and "📱 Mobile" or "💻 PC",
                            ["inline"] = true
                        },
                        {
                            ["name"] = "⚡ Executor",
                            ["value"] = "```" .. executionData.executor .. "```",
                            ["inline"] = true
                        },
                        {
                            ["name"] = "🔑 HWID",
                            ["value"] = "```" .. executionData.hwid:sub(1, 16) .. "...```",
                            ["inline"] = true
                        },
                        {
                            ["name"] = "🔢 Execution Count",
                            ["value"] = string.format(
                                "User: **%d** | Global: **%d**",
                                FirebaseSystem.State.UserExecutions,
                                FirebaseSystem.State.GlobalExecutions
                            ),
                            ["inline"] = false
                        }
                    },
                    ["thumbnail"] = {
                        ["url"] = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. executionData.userId .. "&width=150&height=150&format=png"
                    },
                    ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%S"),
                    ["footer"] = {
                        ["text"] = "Velaware MVSD • Execution Tracker"
                    }
                }}
            }
            
            print("[Velaware] Sending webhook request...")
            local response = reqFunc({
                Url = FirebaseSystem.Config.WebhookURL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = game:GetService("HttpService"):JSONEncode(embed)
            })
            
            if response then
                print("[Velaware] Webhook response:", response.StatusCode)
                if response.StatusCode == 204 then
                    print("[Velaware] ✅ Webhook sent successfully!")
                else
                    warn("[Velaware] ❌ Webhook failed with status:", response.StatusCode)
                    warn("[Velaware] Response body:", response.Body)
                end
            else
                warn("[Velaware] ❌ No response from webhook")
            end
        end)
        
        if not success then
            warn("[Velaware] ❌ Webhook error:", err)
        end
    end)
end

-- ========================================
-- MAIN TRACKING FUNCTION
-- ========================================
function FirebaseSystem.TrackExecution()
    if not FirebaseSystem.Config.Enabled then return end
    
    task.spawn(function()
        pcall(function()
            local player = game.Players.LocalPlayer
            local userId = tostring(player.UserId)
            local hwid = GetHWID()
            
            local executionData = {
                userId = userId,
                username = player.Name,
                displayName = player.DisplayName,
                hwid = hwid,
                gameName = "Murder vs Sheriff Duels",
                placeId = game.PlaceId,
                executor = GetExecutorName(),
                device = game:GetService("UserInputService").TouchEnabled and "Mobile" or "PC",
                accountAge = GetAccountAge(),
                isPremium = IsPremium(),
                timestamp = os.time(),
                sessionId = FirebaseSystem.State.SessionID,
            }
            
            FirebaseSystem.IncrementCounters()
            FirebaseSystem.LogExecution(executionData)
            FirebaseSystem.UpdateUserStats(userId, executionData)
            FirebaseSystem.TrackHWID(hwid, executionData)
            
            if FirebaseSystem.Config.SendWebhook then
                FirebaseSystem.SendWebhook(executionData)
            end
            
            print(string.format(
                "[Velaware] MVSD execution tracked | User: %d | Global: %d",
                FirebaseSystem.State.UserExecutions,
                FirebaseSystem.State.GlobalExecutions
            ))
        end)
    end)
end

-- ========================================
-- INITIALIZATION
-- ========================================
function FirebaseSystem.Initialize()
    print("[Velaware] Initializing MVSD execution tracker...")
    FirebaseSystem.TrackExecution()
    return FirebaseSystem
end

return FirebaseSystem
