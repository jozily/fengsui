local U = require "packages.fengsui.pkg.fengsui_shiyi.fengsui_sweeping.sweeping_util"

local sweeping = fk.CreateSkill { name = "fengsui_limited_heg__sweeping", tags = { Skill.Limited } }

Fk:loadTranslationTable {
  ["fengsui_limited_heg__sweeping"] = "扫荡",
  [":fengsui_limited_heg__sweeping"] = "限定技，出牌阶段，若你的势力仅剩你一名角色，你可以变为野心家（若你已为野心家，则改为摸两张牌），然后发动一次“谋离间”，再可以对其中一位受到伤害的角色拉拢人心。",
  ["#fengsui_limited_heg__sweeping-lijian"] = "扫荡：请发动一次“谋离间”",
  ["#fengsui_limited_heg__sweeping-recruit"] = "扫荡：你可以选择一名受到“谋离间”伤害的角色拉拢人心",
}

sweeping:addEffect("active", {
  anim_type = "offensive",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(sweeping.name, Player.HistoryGame) == 0 and U.sameKingdomCount(player) == 1
  end,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local actual = player:getMark("__heg_general")
    if player.kingdom == "wild" then
      player:drawCards(2, sweeping.name)
    else
      U.becomeWild(player, actual)
    end
    local damaged = U.useMouLijian(player, sweeping.name)
    if player.dead or #damaged == 0 then return end
    local tos = room:askToChoosePlayers(player, {
      targets = damaged, min_num = 1, max_num = 1, cancelable = true,
      skill_name = sweeping.name, prompt = "#fengsui_limited_heg__sweeping-recruit",
    })
    if #tos > 0 then U.askOneToBuildCountry(player, tos[1], sweeping.name) end
  end,
})

sweeping:addEffect(fk.Damaged, {
  can_refresh = function(self, event, target, player, data)
    return player:getMark("fengsui_limited_heg__sweeping_resolving") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addTableMarkIfNeed(player, "fengsui_limited_heg__sweeping_damaged", target.id)
  end,
})

return sweeping
