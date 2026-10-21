local H = require "packages.fengsui.hegemony_util"

local weihou = fk.CreateSkill{
  name = "fengsui_heg__weihou",
}

local function retrialCards(player)
  return table.filter(player:getCardIds("e"), function(id)
    return not player:prohibitResponse(Fk:getCardById(id))
  end)
end

weihou:addEffect(fk.AskForRetrial, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(weihou.name) and H.compareKingdomWith(target, player) and
      H.allGeneralsRevealed(player) and #retrialCards(player) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local ids = retrialCards(player)
    local cards = player.room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      pattern = tostring(Exppattern{ id = ids }),
      skill_name = weihou.name,
      prompt = "#fengsui_heg__weihou-invoke::" .. target.id,
      cancelable = true,
    })
    if #cards > 0 then
      local choice = player.room:askToChoice(player, {
        choices = {"fengsui_heg__weihou_main", "fengsui_heg__weihou_deputy"},
        skill_name = weihou.name,
        prompt = "#fengsui_heg__weihou-hide",
      })
      event:setCostData(self, {
        cards = cards,
        hide_deputy = choice == "fengsui_heg__weihou_deputy",
      })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cost = event:getCostData(self)
    local new_card = Fk:getCardById(cost.cards[1])
    player:hideGeneral(cost.hide_deputy)
    room:changeJudge{
      card = new_card,
      player = player,
      data = data,
      skillName = weihou.name,
      response = true,
    }
  end,
})

Fk:loadTranslationTable{
  ["#fengsui_heg__weihou-hide"] = "维后：选择暗置一张武将牌",
  ["fengsui_heg__weihou_main"] = "暗置主将",
  ["fengsui_heg__weihou_deputy"] = "暗置副将",
}

return weihou
