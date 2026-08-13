local skill = fk.CreateSkill {
  name = "heg_zhaoshu_other&",
}

local H = require "packages.fengsui.hegemony_util"

Fk:loadTranslationTable {
  ["heg_zhaoshu_other&"] = "诏书",
  [":heg_zhaoshu_other&"] = "出牌阶段限一次，你可以将一张（若你为小势力角色，则改为两张）手牌置于【诏书】上。",

  ["#heg_zhaoshu_other&"] = "诏书：你可以将一张（若你为小势力角色，则改为两张）手牌置于【诏书】上",
}

skill:addEffect("active", {
  prompt = "#heg_zhaoshu_other&",
  anim_type = "support",
  min_card_num = 1,
  max_card_num = 2,
  can_use = function(self, player)
    return player:usedSkillTimes(skill.name, Player.HistoryPhase) == 0 and
    table.find(Fk:currentRoom().alive_players, function(p)
      return p:hasSkill("zhaoshu_yuan") and H.compareKingdomWith(p, player)
    end)
  end,
  card_filter = function(self, player, to_select, selected)
    if H.isBigKingdomPlayer(player) then
      return #selected == 0 and table.contains(player:getHandlyIds(true), to_select)
    elseif H.isSmallKingdomPlayer(player) then  --小势力角色
      return #selected <= 1 and table.contains(player:getHandlyIds(true), to_select)
    else                                        --既不是大势力也不是小势力
      return #selected == 0 and table.contains(player:getHandlyIds(true), to_select)
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local tos = table.find(room.alive_players, function(p)
      return p:hasSkill("zhaoshu_yuan") and H.compareKingdomWith(p, player)
    end)
    if tos and tos:hasSkill("zhaoshu_yuan") then
      tos:addToPile("@[zhaoshu]", effect.cards, true, skill.name)
    end
  end,
})

return skill
