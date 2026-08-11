local H = require "packages.fengsui.hegemony_util"

local xuanbei = fk.CreateSkill{
  name = "fengsui_heg__xuanbei",
}

local function isCompanion(player)
  local main = Fk.generals[H.getActualGeneral(player, false)]
  local deputy = Fk.generals[H.getActualGeneral(player, true)]
  return main and deputy and main:isCompanionWith(deputy)
end

local function timesNum(player)
  local room = player.room or Fk:currentRoom()
  if not room then return 0 end
  local kingdoms, shown = {}, 0
  for _, p in ipairs(room.alive_players) do
    local kingdom = H.getKingdom(p)
    if kingdom ~= "unknown" then table.insertIfNeed(kingdoms, kingdom) end
    if H.compareKingdomWith(p, player) then shown = shown + H.getGeneralsRevealedNum(p) end
  end
  return math.min(shown, #kingdoms)
end

xuanbei:addEffect("active", {
  anim_type = "support",
  card_num = 0,
  target_num = 1,
  prompt = "#fengsui_heg__xuanbei",
  can_use = function(self, player)
    return player:usedSkillTimes(xuanbei.name, Player.HistoryPhase) == 0 and timesNum(player) > 0
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and H.compareKingdomWith(player, to_select)
  end,
  on_use = function(self, room, effect)
    local player, to = effect.from, effect.tos[1]
    local formed = isCompanion(to)
    local times = timesNum(player)
    for _ = 1, times do
      if to.dead then break end
      H.transformGeneral(room, to, false, false, 1, xuanbei.name)
      formed = formed or isCompanion(to)
    end
    if formed then
      room:handleAddLoseSkills(player, "-" .. xuanbei.name)
      if player:isAlive() then H.addHegMark(player, "companion", 1) end
      if to:isAlive() then H.addHegMark(to, "companion", 1) end
    end
  end,
})

return xuanbei
