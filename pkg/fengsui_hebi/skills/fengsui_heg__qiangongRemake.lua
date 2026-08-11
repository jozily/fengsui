local H = require "packages.fengsui.hegemony_util"

local qiangong = fk.CreateSkill{
  name = "fengsui_heg__qiangongRemake",
}

local function commonAreas(first, second)
  local areas = {}
  if not first:isKongcheng() and not second:isKongcheng() then
    table.insert(areas, "fengsui_heg__qiangongRemake_hand")
  end
  if #first:getCardIds("e") > 0 and #second:getCardIds("e") > 0 then
    table.insert(areas, "fengsui_heg__qiangongRemake_equip")
  end
  if #first:getCardIds("j") > 0 and #second:getCardIds("j") > 0 then
    table.insert(areas, "fengsui_heg__qiangongRemake_judge")
  end
  return areas
end

qiangong:addEffect("active", {
  anim_type = "support",
  prompt = "#fengsui_heg__qiangongRemake-invoke",
  card_num = 0,
  target_num = 2,
  can_use = function(self, player)
    return player:usedSkillTimes(qiangong.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    if #selected == 0 then
      return #to_select:getCardIds("hej") > 0
    end
    return #selected == 1 and to_select ~= selected[1] and
      #commonAreas(selected[1], to_select) > 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local first, second = effect.tos[1], effect.tos[2]
    local areas = commonAreas(first, second)
    if #areas == 0 then return end
    local choice = room:askToChoice(player, {
      choices = areas,
      skill_name = qiangong.name,
      prompt = "#fengsui_heg__qiangongRemake-area",
    })
    local flags = {
      fengsui_heg__qiangongRemake_hand = "h",
      fengsui_heg__qiangongRemake_equip = "e",
      fengsui_heg__qiangongRemake_judge = "j",
    }
    local flag = flags[choice]
    local from_second = room:askToChooseCard(first, {
      target = second,
      flag = flag,
      skill_name = qiangong.name,
      prompt = "#fengsui_heg__qiangongRemake-take::" .. second.id,
    })
    room:moveCardTo(from_second, Card.PlayerHand, first, fk.ReasonPrey, qiangong.name, nil, false, first)
    if second.dead or first.dead or #first:getCardIds(flag) == 0 then return end
    local from_first = room:askToChooseCard(second, {
      target = first,
      flag = flag,
      skill_name = qiangong.name,
      prompt = "#fengsui_heg__qiangongRemake-take::" .. first.id,
    })
    room:moveCardTo(from_first, Card.PlayerHand, second, fk.ReasonPrey, qiangong.name, nil, false, second)
    local small = table.filter({first, second}, function(p)
      return p:isAlive() and H.isSmallKingdomPlayer(p)
    end)
    if #small > 0 then
      local chosen = room:askToChoosePlayers(player, {
        targets = small,
        min_num = 1,
        max_num = 1,
        skill_name = qiangong.name,
        prompt = "#fengsui_heg__qiangongRemake-draw",
        cancelable = true,
      })
      if #chosen > 0 then chosen[1]:drawCards(1, qiangong.name) end
    end
  end,
})

return qiangong
