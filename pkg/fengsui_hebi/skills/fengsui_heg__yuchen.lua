local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"
local Util = require "packages.utility.utility"

local yuchen = fk.CreateSkill{
  name = "fengsui_heg__yuchen",
}

local function settleNewCombination(room, player)
  local main_name = H.getActualGeneral(player, false)
  local deputy_name = H.getActualGeneral(player, true)
  local main = Fk.generals[main_name]
  local deputy = Fk.generals[deputy_name]
  if not main or not deputy then return end

  local mainHp = main.maxHp + (main.mainMaxHpAdjustedValue or 0)
  local deputyHp = deputy.maxHp + (deputy.deputyMaxHpAdjustedValue or 0)
  if mainHp == deputyHp and player:getMark("@!!yinyangfish") == 0 then
    H.addHegMark(player, "yinyangfish")
    room:addTableMarkIfNeed(player, "@fengsui_heg__yuchen-turn", "毓尘：" .. Fk:translate("@!!yinyangfish"))
  end
  if (main:isCompanionWith(deputy) or deputy:isCompanionWith(main)) and
    player:getMark("@!!companion") == 0 then
    H.addHegMark(player, "companion")
    room:addTableMarkIfNeed(player, "@fengsui_heg__yuchen-turn", "毓尘：" .. Fk:translate("@!!companion"))
  end
end

yuchen:addEffect("active", {
  anim_type = "support",
  prompt = "#fengsui_heg__yuchen-invoke",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:hasShownSkill(yuchen.name) and
      player:usedSkillTimes(yuchen.name, Player.HistoryPhase) == 0 and
      H.getGeneralsRevealedNum(player) > 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    if #selected > 0 or to_select == player or not H.compareKingdomWith(to_select, player) then
      return false
    end
    return H.hasGeneral(player, true) and H.hasGeneral(to_select, true)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    H.swapDeputy(room, player, target)

    settleNewCombination(room, player)
    if target:isAlive() then settleNewCombination(room, target) end
  end,
})

Fk:loadTranslationTable{
  ["fengsui_heg__yuchen"] = "毓尘",
  [":fengsui_heg__yuchen"] = "出牌阶段限一次，你可与其他同势力角色副将<a href='heg__yiwei'>易位</a>，若在两个新的组合中：主副将体力值均相等且对应角色没有阴阳鱼标记的角色获得一枚阴阳鱼标记；两张武将牌构成珠联璧合且对应角色没有珠联璧合标记的角色获得一枚珠联璧合标记。",
  ["#fengsui_heg__yuchen-invoke"] = "毓尘：选择一名其他同势力角色，与其副将易位",
  ["@fengsui_heg__yuchen-turn"] = "毓尘：",
}
return yuchen
