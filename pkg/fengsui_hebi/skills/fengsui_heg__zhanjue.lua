local H = require "packages.fengsui.hegemony_util"
local Util = require "packages.fengsui.pkg.fengsui_hebi.util"
local zhanjue = fk.CreateSkill { name = "fengsui_heg__zhanjue" }
zhanjue:addEffect("active", { card_num = 0, target_num = 1,
    can_use = function(self, p) return p:getHandcardNum() > 0 and p:usedSkillTimes(self.name, Player.HistoryPhase) == 0 end,
    card_filter = Util.FalseFunc,
    target_filter = function(self, p, to, selected) return #selected == 0 and to ~= p and not H.compareKingdomWith(p, to) end,
    on_use = function(self, room, effect)
      room:askToDiscard(effect.from, { min_num = effect.from:getHandcardNum(), max_num = effect.from:getHandcardNum(), include_equip = false, skill_name = self.name })
      room:useVirtualCard("duel", nil, effect.from, effect.tos[1], self.name, true)
    end })


-- 战绝流程中，决斗双方可将装备区所有牌作为杀响应。
zhanjue:addEffect(fk.AskForCardResponse, {
  global = true,
  can_trigger = function(self, _, target, player, data)
    local e = data and data.eventData
    return target == player and player:hasSkill(self.name) and data.pattern and
      string.find(data.pattern, "slash") and e and e.card and e.card.name == "duel" and
      e.card.skillNames and table.contains(e.card.skillNames, self.name) and #player:getCardIds("e") > 0
  end,
  on_cost = function(self, event, target, player)
    if player.room:askToSkillInvoke(player, { skill_name = self.name, prompt = "#fengsui_heg__zhanjue-response" }) then return true end
  end,
  on_use = function(self, _, target, player, data)
    local room = player.room
    local ids = player:getCardIds("e")
    if #ids == 0 then return end
    room:throwCard(ids, self.name, player, player)
    local slash = Fk:cloneCard("slash")
    slash.skillName = self.name
    data.result = { from = player, card = slash }
  end,
})

return zhanjue
