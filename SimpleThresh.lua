local AUTOUPDATES = false
local SCRIPTSTATUS = false
local ScriptName = "SimpleThresh"
local Author = "iCreative"
local version = 1.44
if myHero.charName ~= "Thresh" then return end

local priorityTable = {
    p5 = {"Alistar", "Amumu", "Blitzcrank", "Braum", "ChoGath", "DrMundo", "Garen", "Gnar", "Hecarim", "JarvanIV", "Leona", "Lulu", "Malphite", "Nasus", "Nautilus", "Nunu", "Olaf", "Rammus", "Renekton", "Sejuani", "Shen", "Shyvana", "Singed", "Sion", "Skarner", "TahmKench", "Taric", "Thresh", "Volibear", "Warwick", "MonkeyKing", "Yorick", "Zac"},
    p4 = {"Aatrox", "Darius", "Elise", "Evelynn", "Galio", "Gangplank", "Gragas", "Irelia", "Jax","LeeSin", "Maokai", "Morgana", "Nocturne", "Pantheon", "Poppy", "Rengar", "Rumble", "Ryze", "Swain","Trundle", "Tryndamere", "Udyr", "Urgot", "Vi", "XinZhao", "RekSai"},
    p3 = {"Akali", "Diana", "Fiddlesticks", "Fiora", "Fizz", "Heimerdinger", "Janna", "Jayce", "Kassadin","Kayle", "KhaZix", "Lissandra", "Mordekaiser", "Nami", "Nidalee", "Riven", "Shaco", "Sona", "Soraka", "Vladimir", "Yasuo", "Zilean", "Zyra"},
    p2 = {"Ahri", "Anivia", "Annie",  "Brand",  "Cassiopeia", "Ekko", "Karma", "Karthus", "Katarina", "Kennen", "LeBlanc",  "Lux", "Malzahar", "MasterYi", "Orianna", "Syndra", "Talon",  "TwistedFate", "Veigar", "VelKoz", "Viktor", "Xerath", "Zed", "Ziggs" },
    p1 = {"Ashe", "Caitlyn", "Corki", "Draven", "Ezreal", "Graves", "Jinx", "Kalista", "KogMaw", "Lucian", "MissFortune", "Quinn", "Sivir", "Teemo", "Tristana", "Twitch", "Varus", "Vayne"},
}

local Q, W, E, R, Ignite = nil, nil, nil, nil, nil
local TS, Menu = nil, nil

function CheckUpdate()
    if AUTOUPDATES then
        local ToUpdate = {}
        ToUpdate.LocalVersion = version
        ToUpdate.VersionPath = "raw.githubusercontent.com/LegendBot/iCreative/master/version/SimpleThresh.version"
        ToUpdate.ScriptPath = "raw.githubusercontent.com/LegendBot/iCreative/master/SimpleThresh.lua"
        ToUpdate.SavePath = SCRIPT_PATH.._ENV.FILE_NAME
        ToUpdate.CallbackUpdate = function(NewVersion,OldVersion) PrintMessage(ScriptName, "Updated to "..NewVersion..". Please reload with 2x F9.") end
        ToUpdate.CallbackNoUpdate = function(OldVersion) PrintMessage(ScriptName, "No Updates Found.") end
        ToUpdate.CallbackNewVersion = function(NewVersion) PrintMessage(ScriptName, "New Version found ("..NewVersion.."). Please wait...") end
        ToUpdate.CallbackError = function(NewVersion) PrintMessage(ScriptName, "Error while downloading.") end
        _ScriptUpdate(ToUpdate)
    end
end

function Collides(vec)
    return IsWall(D3DXVECTOR3(vec.x, vec.y, vec.z))
end

function OnLoad()
    if not RequireSimpleLib() then return end
    DelayAction(function() CheckUpdate() end, 5)
    TS = TargetSelector(TARGET_LESS_CAST_PRIORITY, 1150, DAMAGE_PHYSICAL)
    Menu = scriptConfig(ScriptName.." by "..Author, ScriptName.."12072015")

    Q = _Spell({Slot = _Q, Range = 1040, Delay = 0.5, Speed = 1900, Width = 65, Collision = true, Type = SPELL_TYPE.LINEAR}):AddDraw():AddTypeFunction(function() if IsQ1() then return SPELL_TYPE.LINEAR else return SPELL_TYPE.SELF end end):AddTrackTime("threshqinternal"):AddTrackObject("missile"):AddRangeFunction(function() if IsQ1() then return 1040 else return 1200 end end)
    W = _Spell({Slot = _W, Range = 950, Delay = 0.25, Width = 300, Speed = 1800, Type = SPELL_TYPE.CIRCULAR, IsForEnemies = false}):AddDraw()
    E = _Spell({Slot = _E, Range = 500, Delay = 0, Speed = 2000, Width = 110, Aoe = true, Type = SPELL_TYPE.LINEAR}):AddDraw():SetAccuracy(40)
    R = _Spell({Slot = _R, Range = 450, Delay = 0, Type = SPELL_TYPE.SELF}):AddDraw()
    Ignite = _Spell({Slot = FindSummonerSlot("summonerdot"), DamageName = "IGNITE", Range = 600, Type = SPELL_TYPE.TARGETTED})
    Q.Arrive = 0
    Menu:addSubMenu(myHero.charName.." - Target Selector Settings", "TS")
        Menu.TS:addTS(TS)
        _Circle({Menu = Menu.TS, Name = "Draw", Text = "Draw circle on Target", Source = function() return TS.target end, Range = 120, Condition = function() return ValidTarget(TS.target, TS.range) end, Color = {255, 255, 0, 0}, Width = 4})
        _Circle({Menu = Menu.TS, Name = "Range", Text = "Draw circle for Range", Range = function() return TS.range end, Color = {255, 255, 0, 0}, Enable = false})

    Menu:addSubMenu(myHero.charName.." - Combo Settings", "Combo")
        Menu.Combo:addParam("Q1", "Use Q1", SCRIPT_PARAM_LIST, 2, {"Never", "Only On Target", "On Any Enemy"})
        Menu.Combo:addParam("Q2", "Use Q2", SCRIPT_PARAM_LIST, 2, {"Never", "Only On Target", "If Hooked Is Near Target"})
        Menu.Combo:addParam("W", "Use W", SCRIPT_PARAM_LIST, 2, {"Never", "Only If Target Got Hooked", "Always"})
        Menu.Combo:addParam("W2", "Use W On Ally If HP % <=", SCRIPT_PARAM_SLICE, 20, 0, 100)
        Menu.Combo:addParam("E", "E Mode", SCRIPT_PARAM_LIST, 2, {"Never", "Pull", "Push", "Based on %"})
        Menu.Combo:addParam("E2", "Use E", SCRIPT_PARAM_LIST, 2, {"Never", "Only On Target", "On Any Enemy"})
        Menu.Combo:addParam("R1", "Use R If HP % <=", SCRIPT_PARAM_SLICE, 15, 0, 100)
        Menu.Combo:addParam("R2", "Use R If Enemies >=", SCRIPT_PARAM_SLICE, 3, 0, 5, 0)

    Menu:addSubMenu(myHero.charName.." - Harass Settings", "Harass")
        Menu.Harass:addParam("Q1", "Use Q1", SCRIPT_PARAM_LIST, 2, {"Never", "Only On Target", "On Any Enemy"})
        Menu.Harass:addParam("Q2", "Use Q2", SCRIPT_PARAM_LIST, 2, {"Never", "Only On Target", "If Hooked Is Near Target"})
        Menu.Harass:addParam("W", "Use W", SCRIPT_PARAM_LIST, 2, {"Never", "Only If Target Got Hooked", "Always"})
        Menu.Harass:addParam("W2", "Use W On Ally If HP % <=", SCRIPT_PARAM_SLICE, 40, 0, 100)
        Menu.Harass:addParam("E", "E Mode", SCRIPT_PARAM_LIST, 4, {"Never", "Pull", "Push", "Based on %"})
        Menu.Harass:addParam("Mana", "Min. Mana Percent: ", SCRIPT_PARAM_SLICE, 30, 0, 100, 0)

    Menu:addSubMenu(myHero.charName.." - LaneClear Settings", "LaneClear")
        Menu.LaneClear:addParam("Q", "Use Q", SCRIPT_PARAM_ONOFF, false)
        Menu.LaneClear:addParam("E", "Use E", SCRIPT_PARAM_ONOFF, false)
        Menu.LaneClear:addParam("Mana", "Min. Mana Percent: ", SCRIPT_PARAM_SLICE, 50, 0, 100, 0)

    Menu:addSubMenu(myHero.charName.." - JungleClear Settings", "JungleClear")
        Menu.JungleClear:addParam("Q", "Use Q", SCRIPT_PARAM_ONOFF, true)
        Menu.JungleClear:addParam("E", "Use E", SCRIPT_PARAM_ONOFF, true)

    Menu:addSubMenu(myHero.charName.." - LastHit Settings", "LastHit")
        Menu.LastHit:addParam("Q", "Use Q", SCRIPT_PARAM_LIST, 1, {"Never", "Smart", "Always"})
        Menu.LastHit:addParam("E", "Use E", SCRIPT_PARAM_LIST, 1, {"Never", "Smart", "Always"})
        Menu.LastHit:addParam("Mana", "Min. Mana Percent:", SCRIPT_PARAM_SLICE, 50, 0, 100, 0)

    Menu:addSubMenu(myHero.charName.." - KillSteal Settings", "KillSteal")
        Menu.KillSteal:addParam("Q", "Use Q", SCRIPT_PARAM_ONOFF, false)
        Menu.KillSteal:addParam("E", "Use E", SCRIPT_PARAM_ONOFF, false)
        Menu.KillSteal:addParam("R", "Use R", SCRIPT_PARAM_ONOFF, false)
        Menu.KillSteal:addParam("Ignite", "Use Ignite", SCRIPT_PARAM_ONOFF, true)

    Menu:addSubMenu(myHero.charName.." - Auto Settings", "Auto")
        Menu.Auto:addSubMenu("Use E To Interrupt", "E")
            _Interrupter(Menu.Auto.E):CheckChannelingSpells():CheckGapcloserSpells():AddCallback(function(target) Push(target) end)
        Menu.Auto:addSubMenu("Use Q To Interrupt", "Q")
            _Interrupter(Menu.Auto.Q):CheckChannelingSpells():AddCallback(function(target) CastQ1(target) end)
        Menu.Auto:addParam("QTurret", "Use Q In Turret", SCRIPT_PARAM_ONOFF, true)
        Menu.Auto:addParam("ETurret", "Use E In Turret", SCRIPT_PARAM_ONOFF, true)
        Menu.Auto:addParam("WAlly", "Use W Ally If Enemies >=", SCRIPT_PARAM_SLICE, 3, 0, 5)
     Menu:addSubMenu(myHero.charName.." - Drawing Settings", "Draw")
        _Circle({Menu = Menu.Draw, Name = "AssistedW", Text = "Assisted W Circle", Source = function() return mousePos end, Range = 450, Condition = function() return Menu.Keys.AssistedW end, Color = {255, 0, 0, 255}, Width = 2})

    Menu:addSubMenu(myHero.charName.." - Keys Settings", "Keys")
        OrbwalkManager:LoadCommonKeys(Menu.Keys)
        Menu.Keys:addParam("AssistedW", "Assisted W", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("T"))
        Menu.Keys:addParam("PushE", "Push E", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("S"))

    AddApplyBuffCallback(
        function(source, unit, buff)
            if unit and source and buff and buff.name and source.isMe and buff.name:lower() == "threshq" and os.clock() - Q.LastCastTime < 1.5 then
                Q.target = unit
                Q.Arrive = os.clock()
            end
        end
    )
    AddRemoveBuffCallback(
        function(unit, buff)
            if unit and buff and buff.name and buff.name:lower() == "threshq" and Q.target ~= nil and Q.target.networkID == unit.networkID then
                Q.target = nil
            end
        end
    )
end

function OnTick()
    if Menu == nil then return end
    TS:update()

    if Menu.KillSteal.Q or Menu.KillSteal.E or Menu.KillSteal.R or Menu.KillSteal.Ignite then
        for i, enemy in ipairs(GetEnemyHeroes()) do
            if IsValidTarget(enemy, TS.range) and enemy.health > 0 and enemy.health/enemy.maxHealth <= 0.35 then
                if Menu.KillSteal.Q and Q:Damage(enemy) >= enemy.health and not enemy.dead then CastQ1(enemy) end
                if Menu.KillSteal.E and E:Damage(enemy) >= enemy.health and not enemy.dead then Pull(enemy) end
                if Menu.KillSteal.R and R:Damage(enemy) >= enemy.health and not enemy.dead then R:Cast(enemy) end
                if Menu.KillSteal.Ignite and Ignite:IsReady() and Ignite:Damage(enemy) >= enemy.health then Ignite:Cast(enemy) end
            end
        end
    end
    if (Menu.Auto.QTurret and Q:IsReady()) or (Menu.Auto.ETurret and E:IsReady()) then
        for name, turret in pairs(GetTurrets()) do
            if turret ~= nil and GetDistanceSqr(myHero, turret) < math.pow(turret.range, 2) then
                if turret.team == myHero.team then
                    for i, enemy in ipairs(GetEnemyHeroes()) do
                        if Menu.Auto.ETurret and E:IsReady() and E:ValidTarget(enemy) and GetDistanceSqr(enemy, turret) < math.pow(turret.range * 1.3, 2) then
                            Pull(enemy)
                        end
                        if Menu.Auto.QTurret and Q:IsReady() and Q:ValidTarget(enemy) and GetDistanceSqr(enemy, turret) < math.pow(turret.range * 1.3, 2) then
                            CastQ1(enemy)
                        end
                    end
                end
            end
        end
    end
    if Menu.Auto.WAlly > 0 and W:IsReady() then
        for i, champion in ipairs(GetAllyHeroes()) do
            if champion and W:ValidTarget(champion) then
                if #ObjectsInArea(GetEnemyHeroes(), 450, champion) >= Menu.Auto.WAlly then
                    W:Cast(champion)
                end
            end
        end
    end
    if Menu.Keys.AssistedW then
        if OrbwalkManager:CanMove() then
            myHero:MoveTo(mousePos.x, mousePos.z)
        end
        if W:IsReady() then
            local best = nil
            for i, champion in ipairs(GetAllyHeroes()) do
                if champion and not champion.dead and GetDistanceSqr(mousePos, champion) <= math.pow(450, 2) then
                    if best == nil then
                        best = champion
                    elseif GetDistanceSqr(mousePos, best) > GetDistanceSqr(mousePos, champion) then
                        best = champion
                    end
                end
            end
            if best ~= nil then
                CastW(best)
            end
        end
    end

    if Menu.Keys.PushE then
        if OrbwalkManager:CanMove() then
            myHero:MoveTo(mousePos.x, mousePos.z)
        end
        for i, enemy in ipairs(GetEnemyHeroes()) do
            Push(enemy)
        end
    end
    if OrbwalkManager:IsCombo() then
        Combo()
    elseif OrbwalkManager:IsHarass() then
        Harass()
    elseif OrbwalkManager:IsClear() then
        Clear()
    elseif OrbwalkManager:IsLastHit() then
        LastHit()
    end
end

function Combo()
    local target = TS.target
    if IsValidTarget(target) then
        if Menu.Combo.E > 1 then
            if Menu.Combo.E == 2 then
                if Menu.Combo.E2 == 2 then
                    Pull(target)
                elseif Menu.Combo.E2 == 3 then
                    for i, enemy in ipairs(GetEnemyHeroes()) do
                        Pull(enemy)
                    end
                end
            elseif Menu.Combo.E == 3 then
                if Menu.Combo.E2 == 2 then
                    Push(target)
                elseif Menu.Combo.E2 == 3 then
                    for i, enemy in ipairs(GetEnemyHeroes()) do
                        Push(enemy)
                    end
                end
            elseif Menu.Combo.E == 4 then
                local allies = PercentageTeam(GetAllyHeroes(), 1300)
                local enemies = PercentageTeam(GetEnemyHeroes(), 1300)
                if allies >= enemies then
                    if Menu.Combo.E2 == 2 then
                        Push(target)
                    elseif Menu.Combo.E2 == 3 then
                        for i, enemy in ipairs(GetEnemyHeroes()) do
                            Push(enemy)
                        end
                    end
                else
                    if Menu.Combo.E2 == 2 then
                        Push(target)
                    elseif Menu.Combo.E2 == 3 then
                        for i, enemy in ipairs(GetEnemyHeroes()) do
                            Push(enemy)
                        end
                    end
                end
            end
        end
        if Menu.Combo.W > 1 then
            if Menu.Combo.W == 2 then
                if IsValidTarget(Q.target) and Q.target.networkID == target.networkID then
                    CastW(BestAlly(1300, target))
                end
            elseif Menu.Combo.W == 3 then
                CastW(BestAlly(1300, target))
            end
        end
        if Menu.Combo.W2 > 0 and Menu.Combo.W2 < 100 and W:IsReady() then
            local best = nil
            for idx, champion in ipairs(GetAllyHeroes()) do
                if champion.valid and champion.health > 0 and not champion.dead and champion.health/champion.maxHealth * 100 <= Menu.Combo.W2 then
                    if best == nil then
                        best = champion
                    elseif (champion.health/champion.maxHealth * 100)/PriorityChampion(champion) < (best.health/best.maxHealth * 100)/PriorityChampion(best) then
                        best = champion
                    end
                end
            end
            if best ~= nil then
                CastW(best)
            end
        end
        if Menu.Combo.Q1 > 1 then
            if Menu.Combo.Q1 == 2 then
                CastQ1(target)
            elseif Menu.Combo.Q1 == 3 then
                for i, enemy in ipairs(GetEnemyHeroes()) do
                    CastQ1(enemy)
                end
            end
        end
        if Menu.Combo.Q2 > 1 then
            if Menu.Combo.Q2 == 2 then
                if IsValidTarget(Q.target) and Q.target.networkID == target.networkID then
                    CastQ2(target)
                end
            elseif Menu.Combo.Q2 == 3 then
                if IsValidTarget(Q.target) and GetDistanceSqr(Q.target, target) <= math.pow(350, 2) then
                    CastQ2(target)
                end
            end
        end
        if Menu.Combo.R1 > 0 and Menu.Combo.R1 < 100 and myHero.health/myHero.maxHealth * 100 <= Menu.Combo.R1 then
            for i, enemy in ipairs(GetEnemyHeroes()) do
                R:Cast(enemy)
            end
        end
        if Menu.Combo.R2 > 0 then
            if R:IsReady() and #R:ObjectsInArea(GetEnemyHeroes()) >= Menu.Combo.R2 then
                for i, enemy in ipairs(GetEnemyHeroes()) do
                    R:Cast(enemy)
                end
            end
        end
    end
end

function Harass()
    local target = TS.target
    if IsValidTarget(target) then
        if Menu.Harass.E > 1 then
            if Menu.Harass.E == 2 then
                Pull(target)
            elseif Menu.Harass.E == 3 then
                Push(target)
            elseif Menu.Harass.E == 4 then
                local allies = PercentageTeam(GetAllyHeroes(), 1100)
                local enemies = PercentageTeam(GetEnemyHeroes(), 1100)
                if allies >= enemies then
                    Pull(target)
                else
                    Push(target)
                end
            end
        end
        if Menu.Harass.W > 1 then
            if Menu.Harass.W == 2 then
                if IsValidTarget(Q.target) and Q.target.networkID == target.networkID then
                    CastW(BestAlly(1300, target))
                end
            elseif Menu.Harass.W == 3 then
                CastW(BestAlly(1300, target))
            end
        end
        if Menu.Harass.W2 > 0 and Menu.Harass.W2 < 100 and W:IsReady() then
            local best = nil
            for idx, champion in ipairs(GetAllyHeroes()) do
                if champion.valid and champion.health > 0 and not champion.dead and champion.health/champion.maxHealth * 100 <= Menu.Harass.W2 then
                    if best == nil then
                        best = champion
                    elseif (champion.health/champion.maxHealth * 100)/PriorityChampion(champion) < (best.health/best.maxHealth * 100)/PriorityChampion(best) then
                        best = champion
                    end
                end
            end
            if best ~= nil then
                CastW(best)
            end
        end
        if Menu.Harass.Q1 > 1 then
            if Menu.Harass.Q1 == 2 then
                CastQ1(target)
            elseif Menu.Harass.Q1 == 3 then
                for i, enemy in ipairs(GetEnemyHeroes()) do
                    CastQ1(enemy)
                end
            end
        end
        if Menu.Harass.Q2 > 1 then
            if Menu.Harass.Q2 == 2 then
                if IsValidTarget(Q.target) and Q.target.networkID == target.networkID then
                    CastQ2(target)
                end
            elseif Menu.Harass.Q2 == 3 then
                if IsValidTarget(Q.target) and GetDistanceSqr(Q.target, target) <= math.pow(350, 2) then
                    CastQ2(target)
                end
            end
        end
    end
end

function Clear()
    if myHero.mana / myHero.maxMana * 100 >= Menu.LaneClear.Mana then
        if Menu.LaneClear.Q then Q:LastHit({Mode = Menu.LastHit.Q}) Q:LaneClear() end
        if Menu.LaneClear.E then E:LastHit({Mode = Menu.LastHit.E}) E:LaneClear() end
    end
    if Menu.JungleClear.Q then Q:JungleClear() end
    if Menu.JungleClear.E then E:JungleClear() end
end

function LastHit()
    if myHero.mana / myHero.maxMana * 100 >= Menu.LastHit.Mana then
        Q:LastHit({Mode = Menu.LastHit.Q})
        E:LastHit({Mode = Menu.LastHit.E})
    end
end

function IsQ1()
    return Q:GetSpellData().name:lower() == "threshq"
end


function CastQ(target)
    if IsQ1() then CastQ1(target) else CastQ2(target) end
end

function CastQ1(target)
    if Q:IsReady() and Q:ValidTarget(target) and IsQ1() then
        Q:Cast(target)
    end
end

function CastQ2(target)
    if Q:IsReady() and IsValidTarget(target) and not IsQ1() and IsValidTarget(Q.target) and os.clock() - Q.Arrive >= 1.15 then
        CastSpell(Q.Slot)
    end
end

function CastW(champion)
    if W:IsReady() and champion and champion.valid and not champion.dead and GetDistanceSqr(myHero, champion) < math.pow(1300, 2) then
        local CastPosition, WillHit = W:GetPrediction(champion)
        local Position = Vector(myHero) + Vector(Vector(CastPosition) - Vector(myHero)):normalized() * math.min(GetDistance(myHero, CastPosition), W.Range)
        if not Collides(Position) then
            W:CastToVector(Position)
        end
    end
end

function Push(target)
    if E:IsReady() and E:ValidTarget(target) then
        local CastPosition, WillHit = E:GetPrediction(target)
        if CastPosition and WillHit then
            local BestPos = nil
            if BestPos == nil then
                BestPos = Vector(myHero)
            end
            local Position = Vector(myHero) + Vector(Vector(CastPosition) - Vector(BestPos)):normalized() * E.Range
            E:CastToVector(Position)
        end
    end
end

function Pull(target)
    if E:IsReady() and E:ValidTarget(target) then
        local CastPosition, WillHit = E:GetPrediction(target)
        if CastPosition and WillHit then
            local BestPos = nil
            
            if BestPos == nil then
                for name, turret in pairs(GetTurrets()) do
                    if turret ~= nil and GetDistanceSqr(myHero, turret) < math.pow(turret.range * 1.3, 2) then
                        if turret.team == myHero.team then
                            BestPos = Vector(turret)
                        end
                    end
                end
            end
            if BestPos == nil then
                local best = nil
                for idx, champion in ipairs(GetAllyHeroes()) do
                    if champion.valid and champion.health > 0 and not champion.dead then
                        if GetDistanceSqr(target, champion) <= math.pow(1000, 2) then
                            if best == nil then
                                best = champion
                            elseif GetDistanceSqr(target, best) > GetDistanceSqr(target, champion) then
                                best = champion
                            end
                        end
                    end
                end
                if best ~= nil then
                    BestPos = Vector(best)
                end
            end
            if BestPos ~= nil then
                local allies = PercentageTeam(GetAllyHeroes(), 1100)
                local enemies = PercentageTeam(GetEnemyHeroes(), 1100)
                local pointSegment, pointLine, isOnSegment = VectorPointProjectionOnLineSegment(CastPosition, BestPos, myHero)
                if isOnSegment and GetDistanceSqr(myHero, pointSegment) < math.pow(E.Width, 2) and allies >= enemies then
                    local Position1 = Vector(BestPos) + Vector(Vector(BestPos) - Vector(CastPosition)):normalized():perpendicular() * (E.Width - GetDistance(myHero, pointSegment))
                    local Position2 = Vector(BestPos) + Vector(Vector(BestPos) - Vector(CastPosition)):normalized():perpendicular2() * (E.Width - GetDistance(myHero, pointSegment))
                    if GetDistanceSqr(myHero, Position1) < GetDistanceSqr(myHero, Position2) and GetDistanceSqr(myHero, Position1) < GetDistanceSqr(target, Position1) then
                        E:CastToVector(Position1)
                    elseif GetDistanceSqr(myHero, Position1) > GetDistanceSqr(myHero, Position2) and GetDistanceSqr(myHero, Position2) < GetDistanceSqr(target, Position2) then
                        E:CastToVector(Position2)
                    end
                end
            end
            local Position = Vector(myHero) + Vector(Vector(myHero) - Vector(CastPosition)):normalized() * E.Range
            E:CastToVector(Position)
        end
    end
end

function OnProcessSpell(unit, spell)
    if unit and spell and spell.name then
        if spell.name:lower():find("lanternwally") and not IsQ1() and IsValidTarget(Q.target) and Q:IsReady() then
            CastSpell(Q.Slot)
        end
    end
end

function ObjectsInArea(objects, range, position)
    local objects2 = {}
    for i, object in ipairs(objects) do
        if ValidTarget(object) then
            if GetDistanceSqr(position, object) <= range * range then
                table.insert(objects2, object)
            end
        end
    end
    return objects2
end

function PriorityChampion(champion)
    if priorityTable.p1[champion.charName] ~= nil then
        return 1
    elseif priorityTable.p2[champion.charName] ~= nil then
        return 2
    elseif priorityTable.p3[champion.charName] ~= nil then
        return 3
    elseif priorityTable.p4[champion.charName] ~= nil then
        return 4
    elseif priorityTable.p5[champion.charName] ~= nil then
        return 5
    end
    return 5
end

function PercentageTeam(team, range)
    local percentage = team == GetAllyHeroes() and myHero.health/myHero.maxHealth * 100 or 0
    for i, champion in ipairs(team) do
        if champion and champion.valid and champion.health > 0 and not champion.dead then
            if GetDistanceSqr(myHero, champion) <= math.pow(range, 2) then
                percentage = percentage + champion.health/champion.maxHealth * 100
            end
        end
    end
    return percentage
end

function BestAlly(range, target)
    local best = nil
    for idx, champion in ipairs(GetAllyHeroes()) do
        if champion.valid and champion.health > 0 and not champion.dead then
            if GetDistanceSqr(myHero, champion) <= math.pow(range, 2) and GetDistanceSqr(champion, target) > math.pow((champion.range + champion.boundingRadius), 2) and GetDistanceSqr(myHero, target) < GetDistanceSqr(champion, target) then
                if best == nil then
                    best = champion
                elseif (champion.health/champion.maxHealth * 100)/PriorityChampion(champion) < (best.health/best.maxHealth * 100)/PriorityChampion(best) then
                    best = champion
                end
            end
        end
    end
    return best
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

if SCRIPTSTATUS then
    assert(load(Base64Decode("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"), nil, "bt", _ENV))() ScriptStatus("QDGFIHKJLJE") 
end
