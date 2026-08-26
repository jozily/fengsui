local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local gaofanResponse = fk.CreateSkill{
  name = "fengsui_heg__gaofan_response&",
}

local function responseCardName()
  if not Fk.currentResponsePattern then return end
  local pattern = Exppattern:Parse(Fk.currentResponsePattern)
  return table.find(Fk:getAllCardNames("bt"), function(name)
    return pattern:match(Fk:cloneCard(name))
  end)
end

local function swapMain(room, first, second)
  if not U.swapGenerals(room, first) or not U.swapGenerals(room, second) then return false end
  H.swapDeputy(room, first, second)
  U.swapGenerals(room, first)
  U.swapGenerals(room, second)
  return true
end

gaofanResponse:addEffect("viewas", {
  prompt = "#fengsui_heg__gaofan-response",
  card_filter = Util.FalseFunc,
  view_as = function(self, player, cards)
    if #cards > 0 then return end
    local name = responseCardName()
    if not name then return end
    local card = Fk:cloneCard(name)
    card.skillName = "fengsui_heg__gaofan"
    card:setMark("fengsui_heg__gaofan_owner", player:getMark("fengsui_heg__gaofan_owner"))
    card:setMark("fengsui_heg__gaofan_source", player:getMark("fengsui_heg__gaofan_source"))
    card:setMark("fengsui_heg__gaofan_counterpart", player:getMark("fengsui_heg__gaofan_counterpart"))
    return card
  end,
  before_use = function(self, player, use)
    local room = player.room
    local owner = room:getPlayerById(use.card:getMark("fengsui_heg__gaofan_owner"))
    local counterpart = room:getPlayerById(use.card:getMark("fengsui_heg__gaofan_counterpart"))
    if not owner or owner.dead or not counterpart or counterpart.dead then return end
    local main = Fk.generals[H.getActualGeneral(owner, false)]
    local is_deputy = not (main and table.contains(main:getSkillNameList(), "fengsui_heg__gaofan"))
    if is_deputy then
      H.swapDeputy(room, owner, counterpart)
    else
      swapMain(room, owner, counterpart)
    end
    room:notifySkillInvoked(owner, "fengsui_heg__gaofan", "control")
    owner:broadcastSkillInvoke("fengsui_heg__gaofan")
  end,
  after_use = function(self, player, use)
    local room = player.room
    local source = room:getPlayerById(use.card:getMark("fengsui_heg__gaofan_source"))
    if not source or source.dead then return end
    local choices = {}
    if H.hasGeneral(source, true) then
      table.insert(choices, "fengsui_heg__gaofan_transform")
    end
    if player:isAlive() then
      table.insert(choices, "fengsui_heg__gaofan_damage")
    end
    if #choices == 0 then return end
    local choice = #choices == 1 and choices[1] or room:askToChoice(source, {
      choices = choices,
      skill_name = "fengsui_heg__gaofan",
      prompt = "#fengsui_heg__gaofan-choice::" .. player.id,
    })
    if choice == "fengsui_heg__gaofan_transform" then
      if H.transformGeneral(room, source, false, false, 1, "fengsui_heg__gaofan") then return end
    end
    if player:isAlive() then
      room:damage{
        from = source,
        to = player,
        damage = 1,
        skillName = "fengsui_heg__gaofan",
      }
    end
  end,
  enabled_at_play = Util.FalseFunc,
  enabled_at_response = function(self, player)
    return player:getMark("fengsui_heg__gaofan_owner") ~= 0 and responseCardName() ~= nil
  end,
})

return gaofanResponse
