-- 新版（2026-11-13）：互换对应区域各一张牌后，只在该区域牌数严格较多
-- （两人不并列）、且该角色与发动者势力相同时，才可令其合璧；不再摸牌。
-- 改版前的「小势力角色摸牌 + 同势力合璧」版本见
-- fengsui_heg__bizunRemake2.lua。
local H = require "packages.fengsui.hegemony_util"

local bizun = fk.CreateSkill{
  name = "fengsui_heg__bizunRemake3",
}

local function commonAreas(first, second)
  local areas = {}
  if not first:isKongcheng() and not second:isKongcheng() then table.insert(areas, "bizun_hand") end
  if #first:getCardIds("e") > 0 and #second:getCardIds("e") > 0 then table.insert(areas, "bizun_equip") end
  if #first:getCardIds("j") > 0 and #second:getCardIds("j") > 0 then table.insert(areas, "bizun_judge") end
  return areas
end

bizun:addEffect("active", {
  anim_type = "support",
  prompt = "#fengsui_heg__bizunRemake3",
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
      prompt = "#fengsui_heg__bizunRemake3-area",
    })
    local flag = ({bizun_hand = "h", bizun_equip = "e", bizun_judge = "j"})[choice]
    -- 互换后双方该区域牌数变化相同（手牌区各净变 0，装备/判定区各 -1），
    -- 谁牌较多不因结算顺序改变，故在移动牌之前记录原始牌数。
    local first_num = #first:getCardIds(flag)
    local second_num = #second:getCardIds(flag)
    local from_second = room:askToChooseCard(first, {
      target = second,
      flag = flag,
      skill_name = bizun.name,
      prompt = "#fengsui_heg__bizunRemake3-take::" .. second.id,
    })
    room:moveCardTo(from_second, Card.PlayerHand, first, fk.ReasonPrey, bizun.name, nil, false, first)
    if second.dead or first.dead or #first:getCardIds(flag) == 0 then return end
    local from_first = room:askToChooseCard(second, {
      target = first,
      flag = flag,
      skill_name = bizun.name,
      prompt = "#fengsui_heg__bizunRemake3-take::" .. first.id,
    })
    room:moveCardTo(from_first, Card.PlayerHand, second, fk.ReasonPrey, bizun.name, nil, false, second)

    -- 「对应区域牌较多」须唯一：两人牌数相同则不存在这样的角色。
    local more
    if first_num > second_num then
      more = first
    elseif second_num > first_num then
      more = second
    end
    if not more or not more:isAlive() or not H.compareKingdomWith(more, player) then return end
    if room:askToSkillInvoke(player, {
      skill_name = bizun.name,
      prompt = "#fengsui_heg__bizunRemake3-change::" .. more.id,
    }) then
      H.askToHebiOrTransform(room, more, bizun.name, false)
    end
  end,
})

Fk:loadTranslationTable{
  ["#fengsui_heg__bizunRemake3"] = "迁宫：依次选择两名角色并选择二者均有牌的相同区域",
  ["#fengsui_heg__bizunRemake3-area"] = "迁宫：选择双方均有牌的区域",
  ["#fengsui_heg__bizunRemake3-take"] = "迁宫：获得 %dest 该区域的一张牌",
  ["#fengsui_heg__bizunRemake3-change"] = "迁宫：你可以令 %dest 合璧",
  ["bizun_hand"] = "手牌区",
  ["bizun_equip"] = "装备区",
  ["bizun_judge"] = "判定区",
}

return bizun
