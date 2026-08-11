local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local yuchen = fk.CreateSkill{
  name = "fengsui_heg__yuchen",
}

local function settleNewCombination(room, player)
  local main_name = H.getActualGeneral(player, false)
  local deputy_name = H.getActualGeneral(player, true)
  local main = Fk.generals[main_name]
  local deputy = Fk.generals[deputy_name]
  if not main or not deputy then return end

  if main.maxHp == deputy.maxHp and player:getMark("@!!yinyangfish") == 0 then
    H.addHegMark(player, "yinyangfish")
    room:addTableMarkIfNeed(player, "@fengsui_heg__yuchen-turn", "yinyangfish")
  end
  if (main:isCompanionWith(deputy) or deputy:isCompanionWith(main)) and
    player:getMark("@!!companion") == 0 then
    H.addHegMark(player, "companion")
    room:addTableMarkIfNeed(player, "@fengsui_heg__yuchen-turn", "companion")
  end
end

yuchen:addEffect("active", {
  anim_type = "support",
  prompt = "#fengsui_heg__yuchen-invoke",
  card_num = 0,
  target_num = 1,
  interaction = function(self, player)
    local choices = {}
    if H.hasGeneral(player, false) and H.hasGeneral(player, true) then
      table.insert(choices, "fengsui_heg__yuchen_main")
    end
    if H.hasGeneral(player, true) then
      table.insert(choices, "fengsui_heg__yuchen_deputy")
    end
    if #choices > 0 then
      return UI.ComboBox { choices = choices }
    end
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(yuchen.name, Player.HistoryPhase) == 0 and
      H.getGeneralsRevealedNum(player) > 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    if #selected > 0 or to_select == player or not H.compareKingdomWith(to_select, player) then
      return false
    end
    local is_deputy = self.interaction.data == "fengsui_heg__yuchen_deputy"
    return self.interaction.data ~= nil and H.hasGeneral(to_select, is_deputy) and
      (is_deputy or H.hasGeneral(to_select, true))
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local is_deputy = self.interaction.data == "fengsui_heg__yuchen_deputy"

    if is_deputy then
      H.swapDeputy(room, player, target)
    else
      -- swapDeputy完整保留易位双方的技能历史和私人牌堆；临时换位后可复用同一套逻辑交换主将。
      if not U.swapGenerals(room, player) or not U.swapGenerals(room, target) then return end
      H.swapDeputy(room, player, target)
      U.swapGenerals(room, player)
      U.swapGenerals(room, target)
    end

    settleNewCombination(room, player)
    if target:isAlive() then settleNewCombination(room, target) end
  end,
})

Fk:loadTranslationTable{
  ["fengsui_heg__yuchen"] = "毓尘",
  [":fengsui_heg__yuchen"] = "出牌阶段限一次，你可用一张武将牌与一名其他同势力角色的对应武将牌<a href='heg__yiwei'>易位</a>，在两个新的组合中：主副将体力值相等且对应角色没有阴阳鱼标记的角色获得一枚阴阳鱼标记；两张武将牌构成珠联璧合且对应角色没有珠联璧合标记的角色则获得一枚珠联璧合标记。",
  ["#fengsui_heg__yuchen-invoke"] = "毓尘：选择主将或副将，再选择一名同势力角色进行对应武将牌易位",
  ["fengsui_heg__yuchen_main"] = "主将易位",
  ["fengsui_heg__yuchen_deputy"] = "副将易位",
  ["@fengsui_heg__yuchen-turn"] = "毓尘：本回合获得标记",
}
return yuchen
