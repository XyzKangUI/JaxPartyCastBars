JaxPartyCastBars = LibStub("AceAddon-3.0"):NewAddon("JaxPartyCastBars", "AceEvent-3.0", "AceHook-3.0","AceConsole-3.0")
local defaults = {
    profile = {
        offsetY = 0,
        offsetX = 210,
        scale = .7,
        color = 1, 1, 1,
        attachPointBar = "CENTER",
        attachPointFrame = "CENTER",
        icon = false,
    }
}
local throttle = .1
local lastUpdate = 0

function JaxPartyCastBars:OnInitialize()
    JaxPartyCastBars.db = LibStub("AceDB-3.0"):New("jpcbDB", defaults, true)
    self:SetupOptions()
end

local JPC = CreateFrame("Frame","JPC",UIParent)
local GetNumPartyMembers = GetNumGroupMembers
local usingRaidFrames = tonumber(GetCVar("useCompactPartyFrames"))
local spellBars = {}
local InArena = function() return (select(2,IsInInstance()) == "arena") end

hooksecurefunc("CompactRaidFrameContainer_SetFlowSortFunction", function(_,_)
    JPC:UpdateBars()
end)

function JPC:UpdateBars()
    local raidFramesOn = tonumber(GetCVar("useCompactPartyFrames"))
    for k,sp in ipairs(spellBars) do
        sp:SetScale(JaxPartyCastBars.db.profile.scale)
        if (GetNumPartyMembers() > k)  then
            sp:ClearAllPoints()
            if (raidFramesOn == 1) or (UnitInRaid("player") and not InArena()) then
                for g =1,GetNumPartyMembers(),1 do
                    local raidFrame = nil
                    if CompactRaidFrameManager_GetSetting("KeepGroupsTogether") then
                        if UnitInRaid("player") then
                            raidFrame = _G["CompactRaidGroup1Member"..g]
                        else
                            raidFrame = _G["CompactPartyFrameMember"..g]
                        end
                    else
                        raidFrame = _G["CompactRaidFrame"..g]
                    end
                    if raidFrame and (raidFrame.unitExists and UnitIsUnit(raidFrame.unit,"party"..k)) then
                        sp:SetParent(raidFrame)
                        sp:SetPoint(JaxPartyCastBars.db.profile.attachPointFrame, raidFrame, JaxPartyCastBars.db.profile.attachPointBar, JaxPartyCastBars.db.profile.offsetX, JaxPartyCastBars.db.profile.offsetY)
                    end
                end
            else
                local partyFrame = _G["PartyMemberFrame"..k]
                if partyFrame and UnitIsUnit(partyFrame.unit,"party"..k) then
                    sp:SetParent(partyFrame)
                    sp:SetPoint(JaxPartyCastBars.db.profile.attachPointFrame, partyFrame, JaxPartyCastBars.db.profile.attachPointBar, JaxPartyCastBars.db.profile.offsetX, JaxPartyCastBars.db.profile.offsetY)
                end
            end
        end
    end
end

function JPC:GROUP_ROSTER_UPDATE()
    JPC:UpdateBars()
end

local function JPC_OnUpdate(self, elapsed)
    lastUpdate = lastUpdate + elapsed

    if lastUpdate >= throttle then
        if usingRaidFrames ~= tonumber(GetCVar("useCompactPartyFrames")) then
            usingRaidFrames = tonumber(GetCVar("useCompactPartyFrames"))
            self:UpdateBars()
        end
        lastUpdate = 0
    end
end

local function JPC_OnLoad(self)
    local c = JaxPartyCastBars.db.profile.color
    JPC.locked = true
    self:RegisterEvent("GROUP_ROSTER_UPDATE")
    self:SetScript("OnEvent",function(self,event,...) if self[event] then self[event](self,...) end end)
    for i=1,5 do
        local spellbar = CreateFrame("StatusBar", "raid"..i.."SpellBar", UIParent, "SmallCastingBarFrameTemplate");
        spellbar:SetScale(JaxPartyCastBars.db.profile.scale)
        CastingBarFrame_SetUnit(spellbar, "party"..i, true, true);
        spellBars[i] = spellbar
        if JaxPartyCastBars.db.profile.icon then
            spellbar.Icon:SetAlpha(0)
        end
        spellbar.Border:SetVertexColor(c, c, c)
    end
    JPC:UpdateBars()
    self:SetScript("OnUpdate",JPC_OnUpdate)
end

function JPC_Unlock()
    local lock = not JPC.locked
    JPC.locked = not JPC.locked
    for i=1,5 do
        if lock then
            spellBars[i]:SetAlpha(0)
        else
            spellBars[i]:Show()
            spellBars[i]:SetAlpha(1)
            if not JaxPartyCastBars.db.profile.icon then
                spellBars[i].Icon:SetTexture(GetSpellTexture(116));
            end
        end
    end
end

function JPC:UpdateBorderColor()
    local c = JaxPartyCastBars.db.profile.color
    for _, bar in ipairs(spellBars) do
        bar.Border:SetVertexColor(c, c, c)
    end
end

JPC:RegisterEvent("VARIABLES_LOADED")
JPC:SetScript("OnEvent",JPC_OnLoad)
SLASH_JaxPartyCastbars1 = "/jpcb"
SLASH_JaxPartyCastbars2 = "/jaxpartycastbars"
SlashCmdList.JaxPartyCastbars = function(msg)
end
