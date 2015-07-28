local AUTOUPDATES = false
local SCRIPTSTATUS = false
local ScriptName = "SimpleCassiopeia"
local Author = "iCreative"
local version = 1.22

if myHero.charName ~= "Cassiopeia" then return end

local Q, W, E, R, Ignite = nil, nil, nil, nil, nil
local TS, Menu = nil, nil
local PoisonedObjects = {}

function CheckUpdate()
    if AUTOUPDATES then
        local ToUpdate = {}
        ToUpdate.LocalVersion = version
        ToUpdate.VersionPath = "raw.githubusercontent.com/LegendBot/iCreative/master/version/SimpleCassiopeia.version"
        ToUpdate.ScriptPath = "raw.githubusercontent.com/LegendBot/iCreative/master/SimpleCassiopeia.lua"
        ToUpdate.SavePath = SCRIPT_PATH.._ENV.FILE_NAME
        ToUpdate.CallbackUpdate = function(NewVersion,OldVersion) PrintMessage(ScriptName, "Updated to "..NewVersion..". Please reload with 2x F9.") end
        ToUpdate.CallbackNoUpdate = function(OldVersion) PrintMessage(ScriptName, "No Updates Found.") end
        ToUpdate.CallbackNewVersion = function(NewVersion) PrintMessage(ScriptName, "New Version found ("..NewVersion.."). Please wait...") end
        ToUpdate.CallbackError = function(NewVersion) PrintMessage(ScriptName, "Error while downloading.") end
        _ScriptUpdate(ToUpdate)
    end
end

function OnLoad()
    if not RequireSimpleLib() then return end
    DelayAction(function() CheckUpdate() end, 5)
    DelayAction(function() _arrangePriorities() end, 12)
    TS = TargetSelector(TARGET_LESS_CAST_PRIORITY, 850, DAMAGE_MAGIC)
    Menu = scriptConfig(ScriptName.." by "..Author, ScriptName.."13072015")

    Q = _Spell({Slot = _Q, DamageName = "Q", Range = 850, Width = 75, Delay = 0.25, Speed = math.huge, Collision = false, Aoe = true, Type = SPELL_TYPE.CIRCULAR}):AddDraw()
    W = _Spell({Slot = _W, DamageName = "W", Range = 850, Width = 90, Delay = 0.25, Speed = 2500, Collision = false, Aoe = true, Type = SPELL_TYPE.CIRCULAR}):AddDraw()
    E = _Spell({Slot = _E, DamageName = "E", Range = 700, Delay = 0.125, Speed = 1900, Type = SPELL_TYPE.TARGETTED}):AddDraw()
    R = _Spell({Slot = _R, DamageName = "R", Range = 825, Delay = 0.50, Width = 80, Speed = math.huge, Collision = false, Aoe = true, Type = SPELL_TYPE.CONE}):AddDraw()
    Ignite = _Spell({Slot = FindSummonerSlot("summonerdot"), DamageName = "IGNITE", Range = 600, Type = SPELL_TYPE.TARGETTED})

    Menu:addSubMenu(myHero.charName.." - Target Selector Settings", "TS")
        Menu.TS:addTS(TS)
        _Circle({Menu = Menu.TS, Name = "Draw", Text = "Draw circle on Target", Source = function() return TS.target end, Range = 120, Condition = function() return ValidTarget(TS.target, TS.range) end, Color = {255, 255, 0, 0}, Width = 4})
        _Circle({Menu = Menu.TS, Name = "Range", Text = "Draw circle for Range", Range = function() return TS.range end, Color = {255, 255, 0, 0}, Enable = false})

    Menu:addSubMenu(myHero.charName.." - Combo Settings", "Combo")
        Menu.Combo:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
        Menu.Combo:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
        Menu.Combo:addParam("useE", "Use E", SCRIPT_PARAM_LIST, 2, { "Never", "On Poisoned", "Always"})
        Menu.Combo:addParam("useR2", "Use R If Enemies >=", SCRIPT_PARAM_SLICE, math.min(#GetEnemyHeroes(), 3), 0, 5, 0)

    Menu:addSubMenu(myHero.charName.." - Harass Settings", "Harass")
        Menu.Harass:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
        Menu.Harass:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
        Menu.Harass:addParam("useE", "Use E", SCRIPT_PARAM_LIST, 2, { "Never", "On Poisoned", "Always"})
        Menu.Harass:addParam("Mana", "Min. Mana Percent: ", SCRIPT_PARAM_SLICE, 30, 0, 100, 0)

    Menu:addSubMenu(myHero.charName.." - LaneClear Settings", "LaneClear")
        Menu.LaneClear:addParam("useQ", "Use Q If Hit >= ", SCRIPT_PARAM_SLICE, 2, 0, 10)
        Menu.LaneClear:addParam("useW", "Use W If Hit >= ", SCRIPT_PARAM_SLICE, 2, 0, 10)
        Menu.LaneClear:addParam("useE", "Use E", SCRIPT_PARAM_LIST, 2, { "Never", "On Poisoned", "Always"})
        Menu.LaneClear:addParam("LastHit", "Use E only for LastHit", SCRIPT_PARAM_ONOFF, true)
        Menu.LaneClear:addParam("Mana", "Min. Mana Percent: ", SCRIPT_PARAM_SLICE, 50, 0, 100, 0)

    Menu:addSubMenu(myHero.charName.." - JungleClear Settings", "JungleClear")
        Menu.JungleClear:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
        Menu.JungleClear:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
        Menu.JungleClear:addParam("useE", "Use E", SCRIPT_PARAM_ONOFF, true)

    Menu:addSubMenu(myHero.charName.." - LastHit Settings", "LastHit")
        Menu.LastHit:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, false)
        Menu.LastHit:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, false)
        Menu.LastHit:addParam("useE", "Use E", SCRIPT_PARAM_LIST, 3, { "Never", "On Poisoned", "Always"})
        Menu.LastHit:addParam("Mana", "Min. Mana Percent:", SCRIPT_PARAM_SLICE, 50, 0, 100, 0)

    Menu:addSubMenu(myHero.charName.." - KillSteal Settings", "KillSteal")
        Menu.KillSteal:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
        Menu.KillSteal:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
        Menu.KillSteal:addParam("useE", "Use E", SCRIPT_PARAM_ONOFF, true)
        Menu.KillSteal:addParam("useR", "Use R", SCRIPT_PARAM_ONOFF, false)
        Menu.KillSteal:addParam("useIgnite", "Use Ignite", SCRIPT_PARAM_ONOFF, true)

    Menu:addSubMenu(myHero.charName.." - Auto Settings", "Auto")
        Menu.Auto:addSubMenu("Use R To Interrupt", "UseR")
            _Interrupter(Menu.Auto.UseR):CheckChannelingSpells():AddCallback(function(target) R:Cast(target) end)

    Menu:addSubMenu(myHero.charName.." - Keys Settings", "Keys")
        OrbwalkManager:LoadCommonKeys(Menu.Keys)
        OrbwalkManager:AddKey({Name = "AssistedUltimate", Text = "Assisted Ultimate (Near Mouse)", Key = string.byte("T"), Mode = ORBWALK_MODE.COMBO})
        Menu.Keys:addParam("HarassToggle", "Harass (Toggle)", SCRIPT_PARAM_ONKEYTOGGLE, false, string.byte("K"))
        Menu.Keys:addParam("LastHitToggle", "LastHit E (Toggle)", SCRIPT_PARAM_ONKEYTOGGLE, false, string.byte("L"))

        Menu.Keys:permaShow("LastHitToggle")
        Menu.Keys:permaShow("HarassToggle")

        Menu.Keys.AssistedUltimate = false
        Menu.Keys.HarassToggle = false
        Menu.Keys.LastHitToggle = false
end

function OnTick()
    if Menu == nil then return end
    TS:update()
    if OrbwalkManager:IsCombo() and OrbwalkManager:InRange(TS.target) and (E:IsReady() or E:GetSpellData().currentCd < 1) and IsPoisoned(TS.target) then
        OrbwalkManager:DisableAttacks()
    else
        OrbwalkManager:EnableAttacks()
    end
    KillSteal()
    if OrbwalkManager:IsCombo() then
        Combo()
    elseif OrbwalkManager:IsHarass() then
        Harass()
    elseif OrbwalkManager:IsClear() then
        Clear()
    elseif OrbwalkManager:IsLastHit() then
        LastHit()
    end
    if Menu.Keys.AssistedUltimate then
        local BestEnemy = nil
        for idx, enemy in ipairs(GetEnemyHeroes()) do
            if R:ValidTarget(enemy) then
                if BestEnemy == nil then BestEnemy = enemy
                elseif GetDistanceSqr(mousePos, BestEnemy) > GetDistanceSqr(mousePos, enemy) then BestEnemy = enemy end
            end
        end
        if R:ValidTarget(BestEnemy) then
            R:Cast(BestEnemy)
        end
    end
    if Menu.Keys.LastHitToggle and not OrbwalkManager:IsCombo() then
        local minion = E:LastHit({ Mode = LASTHIT_MODE.ALWAYS, UseCast = false})
        if ValidTarget(minion) then
            if Menu.LastHit.useE == 2 then
                if IsPoisoned(minion) then
                    E:Cast(minion)
                end
            elseif Menu.LastHit.useE == 3 then
                E:Cast(minion)
            end
        end
    end
    if Menu.Keys.HarassToggle then Harass() end

end

function IsPoisoned(target)
    if ValidTarget(target) then
        if #PoisonedObjects > 0 then
            for i = #PoisonedObjects, 1, -1 do
                local obj = PoisonedObjects[i]
                if obj and obj.valid and obj.name then
                    if GetDistanceSqr(Vector(target.x, 0, target.z), Vector(obj.x, 0, obj.z)) < Prediction.VP:GetHitBox(target) * Prediction.VP:GetHitBox(target) then
                        return true
                    end
                else
                    table.remove(PoisonedObjects, i)
                    break
                end
            end
        end
        for i = 1, objManager.maxObjects do
            local obj = objManager:GetObject(i)
            if obj and obj.valid and obj.name and obj.name:lower() == "global_poison.troy" and GetDistanceSqr(Vector(target.x, 0, target.z), Vector(obj.x, 0, obj.z)) < Prediction.VP:GetHitBox(target) * Prediction.VP:GetHitBox(target) then
                table.insert(PoisonedObjects, obj)
                return true
            end
        end
    end
    return false
end

function KillSteal()
    for idx, enemy in ipairs(GetEnemyHeroes()) do
        if ValidTarget(enemy, TS.range) and enemy.health > 0 and enemy.health/enemy.maxHealth <= 0.35 then
            if Menu.KillSteal.useQ and Q:Damage(enemy) >= enemy.health and not enemy.dead then Q:Cast(enemy) end
            if Menu.KillSteal.useW and W:Damage(enemy) >= enemy.health and not enemy.dead then W:Cast(enemy) end
            if Menu.KillSteal.useE and E:Damage(enemy) >= enemy.health and not enemy.dead then E:Cast(enemy) end
            if Menu.KillSteal.useR and R:Damage(enemy) >= enemy.health and not enemy.dead then R:Cast(enemy) end
            if Menu.KillSteal.useIgnite and Ignite:IsReady() and Ignite:Damage(enemy) >= enemy.health and not enemy.dead then Ignite:Cast(enemy) end
        end
    end
end

function Combo()
    local target = TS.target
    if ValidTarget(target) then
        if Menu.Combo.useE > 1 then
            if Menu.Combo.useE == 2 then
                if IsPoisoned(target) then
                    E:Cast(target)
                end
            elseif Menu.Combo.useE == 3 then
                E:Cast(target)
            end
        end
        if Menu.Combo.useQ then
            if not IsPoisoned(target) then Q:Cast(target) end
        end
        if Menu.Combo.useW then
            if not IsPoisoned(target) then W:Cast(target) end
        end
        if Menu.Combo.useR2 > 0 then
            if R:IsReady() then
                for i, enemy in ipairs(GetEnemyHeroes()) do
                    local CastPosition, WillHit, NumberOfHits = R:GetPrediction(enemy, {TypeOfPrediction = "VPrediction"})
                    if NumberOfHits and type(NumberOfHits) == "number" and NumberOfHits >= Menu.Combo.useR2 and WillHit then
                        CastSpell(R.Slot, CastPosition.x, CastPosition.z)
                    end
                end
            end
        end
    end
end

function Harass()
    local target = TS.target
    if ValidTarget(target) then
        if Menu.Harass.useE > 1 then
            if Menu.Harass.useE == 2 then
                if IsPoisoned(target) then
                    E:Cast(target)
                end
            elseif Menu.Harass.useE == 3 then
                E:Cast(target)
            end
        end
        if Menu.Harass.useQ then
            if not IsPoisoned(target) then Q:Cast(target) end
        end
        if Menu.Harass.useW then
            if not IsPoisoned(target) then W:Cast(target) end
        end
    end
end

function Clear()
    if myHero.mana / myHero.maxMana * 100 >= Menu.LaneClear.Mana then
        if Menu.LaneClear.useE > 1 and E:IsReady() then
            local minion = E:LastHit({ Mode = LASTHIT_MODE.ALWAYS, UseCast = false})
            if ValidTarget(minion) then
                if Menu.LaneClear.useE == 2 then
                    if IsPoisoned(minion) then
                        E:Cast(minion)
                    end
                elseif Menu.LaneClear.useE == 3 then
                    E:Cast(minion)
                end
            end
            if not Menu.LaneClear.LastHit then
                local minion = E:LaneClear({ UseCast = false})
                if ValidTarget(minion) then
                    if Menu.LaneClear.useE == 2 then
                        if IsPoisoned(minion) then
                            E:Cast(minion)
                        end
                    elseif Menu.LaneClear.useE == 3 then
                        E:Cast(minion)
                    end
                end
            end
        end
        if Menu.LaneClear.useQ then
            Q:LaneClear({NumberOfHits = Menu.LaneClear.useQ})
        end
        if Menu.LaneClear.useW then
            W:LaneClear({NumberOfHits = Menu.LaneClear.useW})
        end
    end

    if Menu.JungleClear.useE then
        local minion = E:JungleClear({ UseCast = false})
        if IsPoisoned(minion) then
            E:Cast(minion)
        end
    end
    if Menu.JungleClear.useQ then
        Q:JungleClear()
    end
    if Menu.JungleClear.useW then
        W:JungleClear()
    end
end

function LastHit()
    if myHero.mana / myHero.maxMana * 100 >= Menu.LastHit.Mana then
        if Menu.LastHit.useE > 1 then
            local minion = E:LastHit({ Mode = LASTHIT_MODE.ALWAYS, UseCast = false})
            if ValidTarget(minion) then
                if Menu.LastHit.useE == 2 then
                    if IsPoisoned(minion) then
                        E:Cast(minion)
                    end
                elseif Menu.LastHit.useE == 3 then
                    E:Cast(minion)
                end
            end
        end
        if Menu.LastHit.useQ then
            Q:LastHit()
        end
        if Menu.LastHit.useW then
            W:LastHit()
        end
    end
end

function RequireSimpleLib()
    if FileExist(LIB_PATH.."SimpleLib.lua") and not FileExist(SCRIPT_PATH.."SimpleLib.lua") then
        require "SimpleLib"
        return true
    elseif FileExist(LIB_PATH.."SimpleLib.lua") and FileExist(SCRIPT_PATH.."SimpleLib.lua") then
        print("SimpleLib.lua should not be in Custom Script (Only on Common folder), delete it from there...")
        return false
    else
        local function Base64Encode2(data)
            local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
            return ((data:gsub('.', function(x)
                local r,b='',x:byte()
                for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
                return r;
            end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
                if (#x < 6) then return '' end
                local c=0
                for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
                return b:sub(c+1,c+1)
            end)..({ '', '==', '=' })[#data%3+1])
        end
        local SavePath = LIB_PATH.."SimpleLib.lua"
        local ScriptPath = '/BoL/TCPUpdater/GetScript'..(usehttps and '5' or '6')..'.php?script='..Base64Encode2("raw.githubusercontent.com/jachicao/BoL/master/SimpleLib.lua")..'&rand='..math.random(99999999)
        local GotScript = false
        local LuaSocket = nil
        local Socket = nil
        local Size = nil
        local RecvStarted = false
        local Receive, Status, Snipped = nil, nil, nil
        local Started = false
        local File = ""
        local NewFile = ""
        if not LuaSocket then
            LuaSocket = require("socket")
        else
            Socket:close()
            Socket = nil
            Size = nil
            RecvStarted = false
        end
        Socket = LuaSocket.tcp()
        if not Socket then
            print('Socket Error')
        else
            Socket:settimeout(0, 'b')
            Socket:settimeout(99999999, 't')
            Socket:connect('sx-bol.eu', 80)
            Started = false
            File = ""
        end
        AddTickCallback(function()
            if GotScript then return end
            Receive, Status, Snipped = Socket:receive(1024)
            if Status == 'timeout' and not Started then
                Started = true
                print("Downloading a library called SimpleLib. Please wait...")
                Socket:send("GET "..ScriptPath.." HTTP/1.1\r\nHost: sx-bol.eu\r\n\r\n")
            end
            if (Receive or (#Snipped > 0)) and not RecvStarted then
                RecvStarted = true
            end

            File = File .. (Receive or Snipped)
            if File:find('</si'..'ze>') then
                if not Size then
                    Size = tonumber(File:sub(File:find('<si'..'ze>') + 6, File:find('</si'..'ze>') - 1))
                end
                if File:find('<scr'..'ipt>') then
                    local _, ScriptFind = File:find('<scr'..'ipt>')
                    local ScriptEnd = File:find('</scr'..'ipt>')
                    if ScriptEnd then ScriptEnd = ScriptEnd - 1 end
                    local DownloadedSize = File:sub(ScriptFind + 1,ScriptEnd or -1):len()
                end
            end
            if File:find('</scr'..'ipt>') then
                local a,b = File:find('\r\n\r\n')
                File = File:sub(a,-1)
                NewFile = ''
                for line,content in ipairs(File:split('\n')) do
                    if content:len() > 5 then
                        NewFile = NewFile .. content
                    end
                end
                local HeaderEnd, ContentStart = NewFile:find('<sc'..'ript>')
                local ContentEnd, _ = NewFile:find('</scr'..'ipt>')
                if not ContentStart or not ContentEnd then
                else
                    local newf = NewFile:sub(ContentStart + 1,ContentEnd - 1)
                    local newf = newf:gsub('\r','')
                    if newf:len() ~= Size then
                        return
                    end
                    local newf = Base64Decode(newf)
                    if type(load(newf)) ~= 'function' then
                    else
                        local f = io.open(SavePath, "w+b")
                        f:write(newf)
                        f:close()
                        print("Required library downloaded. Please reload with 2x F9.")
                    end
                end
                GotScript = true
            end
        end)
        return false
    end
end


assert(load(Base64Decode("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"), nil, "bt", _ENV))() ScriptStatus("PCFEDGEBIBD") 
