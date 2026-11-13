-- 迁宫存档（2026-11-13 改版前）：选两名角色与二者均有牌的相同区域，依次互换
-- 该区域各一张牌；随后可令其中一名小势力角色摸一张牌，若其与发动者势力相同
-- 则令其合璧。
-- 现役版本见 fengsui_heg__bizun.lua，此文件未挂载到任何武将，仅作回退备份。
local H = require "packages.fengsui.hegemony_util"

local bizun = fk.CreateSkill{
  name = "fengsui_heg__bizunRemake2",
}

local function commonAreas(first, second)
  local areas = {}
  if not first:isKongcheng() and not second:isKongcheng() then table.insert(areas, "bizunRemake2_hand") end
  if #first:getCardIds("e") > 0 and #second:getCardIds("e") > 0 then table.insert(areas, "bizunRemake2_equip") end
  if #first:getCardIds("j") > 0 and #second:getCardIds("j") > 0 then table.insert(areas, "bizunRemake2_judge") end
  return areas
end

bizun:addEffect("active", {
  anim_type = "support",
  prompt = "#fengsui_heg__bizunRemake2",
  card_num = 0,
  target_num = 2,
  can_use = function(self, player)
    return player:usedSkillTimes(bizun.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    if #selected == 0 then return #to_select:getCardIds("hej") > 0 end
    return #selected == 1 and to_select ~= selected[1] and #commonAreas(selected[1], to_select) > 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local first, second = effect.tos[1], effect.tos[2]
    local areas = commonAreas(first, second)
    if #areas == 0 then return end
    local choice = room:askToChoice(player, {
      choices = areas,
      skill_name = bizun.name,
      prompt = "#fengsui_heg__bizunRemake2-area",
    })
    local flag = ({bizunRemake2_hand = "h", bizunRemake2_equip = "e", bizunRemake2_judge = "j"})[choice]
    local from_second = room:askToChooseCard(first, {
      target = second,
      flag = flag,
      skill_name = bizun.name,
      prompt = "#fengsui_heg__bizunRemake2-take::" .. second.id,
    })
    room:moveCardTo(from_second, Card.PlayerHand, first, fk.ReasonPrey, bizun.name, nil, false, first)
    if second.dead or first.dead or #first:getCardIds(flag) == 0 then return end
    local from_first = room:askToChooseCard(second, {
      target = first,
      flag = flag,
      skill_name = bizun.name,
      prompt = "#fengsui_heg__bizunRemake2-take::" .. first.id,
    })
    room:moveCardTo(from_first, Card.PlayerHand, second, fk.ReasonPrey, bizun.name, nil, false, second)

    local small = table.filter({first, second}, function(p)
      return p:isAlive() and H.isSmallKingdomPlayer(p)
    end)
    if #small == 0 then return end
    local chosen = room:askToChoosePlayers(player, {
      targets = small,
      min_num = 1,
      max_num = 1,
      skill_name = bizun.name,
      prompt = "#fengsui_heg__bizunRemake2-draw",
      cancelable = true,
    })
    if #chosen == 0 then return end
    local to = chosen[1]
    to:drawCards(1, bizun.name)
    if to:isAlive() and H.compareKingdomWith(to, player) and room:askToSkillInvoke(player, {
      skill_name = bizun.name,
      prompt = "#fengsui_heg__bizunRemake2-change::" .. to.id,
    }) then
      H.askToHebiOrTransform(room, to, bizun.name, false)
    end
  end,
})

Fk:loadTranslationTable{
  ["#fengsui_heg__bizunRemake2"] = "迁宫：依次选择两名角色并选择二者均有牌的相同区域",
  ["#fengsui_heg__bizunRemake2-area"] = "迁宫：选择双方均有牌的区域",
  ["#fengsui_heg__bizunRemake2-take"] = "迁宫：获得 %dest 该区域的一张牌",
  ["#fengsui_heg__bizunRemake2-draw"] = "迁宫：你可以令其中一名小势力角色摸一张牌",
  ["#fengsui_heg__bizunRemake2-change"] = "迁宫：你可以令 %dest 合璧",
  ["bizunRemake2_hand"] = "手牌区",
  ["bizunRemake2_equip"] = "装备区",
  ["bizunRemake2_judge"] = "判定区",
}

return bizun
