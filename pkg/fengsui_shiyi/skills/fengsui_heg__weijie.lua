local H = require "packages.fengsui.hegemony_util"

local weijie = fk.CreateSkill{name = "fengsui_heg__weijie"}

Fk:loadTranslationTable{
  ["fengsui_heg__weijie"] = "诿解",
  [":fengsui_heg__weijie"] = "每回合限一次，当一名同势力角色需要打出基本牌时，你可以弃置当前回合角色的一张牌，若此牌与其需要打出的牌类别相同，其视为打出之。",
  ["#fengsui_heg__weijie-invoke"] = "诿解：弃置当前回合角色的一张牌，若为基本牌，视为 %dest 打出所需牌",
  ["$fengsui_heg__weijie1"] = "败战之罪在你，休要多言！",
  ["$fengsui_heg__weijie2"] = "纵汝舌灿莲花，亦难逃死罪。",
}

local function matchingBasics(pattern)
  local result = {}
  for _, name in ipairs(Fk:getAllCardNames("b")) do
    local card = Fk:cloneCard(name)
    if Exppattern:Parse(pattern):match(card) then table.insertIfNeed(result, name) end
  end
  return result
end

weijie:addEffect(fk.AskForCardResponse, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    local current = player.room.current
    return target and target:isAlive() and player:hasSkill(weijie.name) and
      H.compareKingdomWith(player, target) and
      player:usedSkillTimes(weijie.name, Player.HistoryTurn) == 0 and
      current and current:isAlive() and not current:isNude() and #matchingBasics(data.pattern) > 0
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = weijie.name,
      prompt = "#fengsui_heg__weijie-invoke::" .. target.id,
    }) then
      event:setCostData(self, { tos = { target } })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room, current = player.room, player.room.current
    local id = room:askToChooseCard(player, { target = current, flag = "he", skill_name = weijie.name })
    local sameType = Fk:getCardById(id).type == Card.TypeBasic
    room:throwCard(id, weijie.name, current, player)
    if not sameType then return end
    local names = matchingBasics(data.pattern)
    local name = #names == 1 and names[1] or room:askToChoice(player, {
      choices = names, skill_name = weijie.name,
    })
    local card = Fk:cloneCard(name)
    card.skillName = weijie.name
    data.result = { from = target, card = card }
  end,
})

return weijie
