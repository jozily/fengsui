local H = require "packages.fengsui.hegemony_util"
local Util = require "packages.fengsui.pkg.fengsui_hebi.util"
local zhanjue = fk.CreateSkill { name = "fengsui_heg__zhanjue" }
local ZNAME = "fengsui_heg__zhanjue"
zhanjue:addEffect("active", { card_num = 0, target_num = 1,
    can_use = function(self, p) return p:hasShownSkill(self.name) and p:getHandcardNum() > 0 and p:usedSkillTimes(self.name, Player.HistoryPhase) == 0 end,
    card_filter = Util.FalseFunc,
    target_filter = function(self, p, to, selected) return #selected == 0 and to ~= p and not H.compareKingdomWith(p, to) end,
  on_use = function(self, room, effect)
    local handcards = effect.from:getCardIds("h")
    local target = effect.tos[1]
    room:useVirtualCard("duel", handcards, effect.from, target, self.name, true)
  end })


-- 战绝流程中，决斗双方可将装备区所有牌作为杀响应。
zhanjue:addEffect(fk.AskForCardResponse, {
  global = true,
  can_trigger = function(self, _, target, player, data)
    local e = data and data.eventData
    return target == player and data.pattern and
      string.find(data.pattern, "slash") and e and e.card and (e.card.name == "duel" or e.card.trueName == "duel") and
      ((e.card.skillName == ZNAME) or (e.card.skillNames and table.contains(e.card.skillNames, ZNAME))) and #player:getCardIds("e") > 0
  end,
  on_cost = function(self, event, target, player)
    if player.room:askToSkillInvoke(player, { skill_name = self.name, prompt = "#fengsui_heg__zhanjue-response" }) then return true end
  end,
  on_use = function(self, _, target, player, data)
    local room = player.room
    local ids = player:getCardIds("e")
    if #ids == 0 then return end
    local slash = Fk:cloneCard("slash")
    slash:addSubcards(ids)
    slash.skillName = self.name
    data.result = { from = player, card = slash }
  end,
})

return zhanjue
