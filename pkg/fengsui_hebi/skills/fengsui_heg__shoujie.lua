local H = require "packages.fengsui.hegemony_util"

local shoujie = fk.CreateSkill{
  name = "fengsui_heg__shoujie",
}

shoujie:addEffect(fk.TargetConfirming, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    -- 后半段：自己成为同势力角色牌的目标
    if target == player and player:hasSkill(shoujie.name) and H.compareKingdomWith(data.from, player) then
       return #player:getCardIds("h") > #data.from:getCardIds("h") or
         #player:getCardIds("e") > #data.from:getCardIds("e") or
         #player:getCardIds("j") > #data.from:getCardIds("j")
    end
    return false
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askToSkillInvoke(player, { skill_name = shoujie.name, prompt = "#fengsui_heg__shoujie-cancel::"..data.from.id }) then
       return true
    end
  end,
  on_use = function(self, event, target, player, data)
    data:cancelTarget(player)
  end,
})

shoujie:addEffect(fk.TargetConfirmed, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    local used = ((data.extra_data or {}).fengsui_heg__shoujie_used or {})[player.id]
    return player:hasSkill(shoujie.name) and not used and
      H.compareKingdomWith(target, player) and data.card.type == Card.TypeTrick and
      #data.use.tos > 1 and #player:getCardIds("he") > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = { "Cancel" }
    if not player:isKongcheng() then table.insert(choices, 1, "shoujie_hand") end
    if #player:getCardIds("e") > 0 then table.insert(choices, 1, "shoujie_equip") end
    local choice = room:askToChoice(player, {
       choices = choices,
       prompt = "#fengsui_heg__shoujie-protect",
       skill_name = shoujie.name,
    })
    if choice ~= "Cancel" then
       event:setCostData(self, { choice = choice })
       return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice

    data.extra_data = data.extra_data or {}
    data.extra_data.fengsui_heg__shoujie_used = data.extra_data.fengsui_heg__shoujie_used or {}
    data.extra_data.fengsui_heg__shoujie_used[player.id] = true

    local cards = {}
    if choice == "shoujie_hand" then cards = player:getCardIds("h")
    elseif choice == "shoujie_equip" then cards = player:getCardIds("e") end

    local c_len = #cards
    room:throwCard(cards, shoujie.name, player, player)

    if c_len > 0 then
       local target_mates = data:getAllTargets()
       local tos = room:askToChoosePlayers(player, {
          targets = target_mates,
          min_num = 1,
          max_num = math.min(c_len, #target_mates),
          prompt = "#fengsui_heg__shoujie-cancel-tos",
          skill_name = shoujie.name,
          cancelable = false,
       })

       for _, p in ipairs(tos) do
          data:cancelTarget(p)
       end
    end
  end,
})

Fk:loadTranslationTable{
  ["fengsui_heg__shoujie"] = "守节",
  [":fengsui_heg__shoujie"] = "与你势力相同的角色成为多目标锦囊牌的目标后，你可以弃置手牌区或装备区的所有牌，取消其中至多等量名角色的目标。当你成为同势力角色牌的目标后，若你任意一个区域的牌大于其，取消之。",
  ["#fengsui_heg__shoujie-cancel"] = "守节：你的某区域牌多于 %dest，是否取消该牌的目标？",
  ["#fengsui_heg__shoujie-protect"] = "守节：是否弃置所有手牌或装备区牌，取消此锦囊牌的若干目标？",
  ["shoujie_hand"] = "弃置所有手牌",
  ["shoujie_equip"] = "弃置所有装备区牌",
  ["#fengsui_heg__shoujie-cancel-tos"] = "守节：请选择要从此锦囊中取消的目标",
}

return shoujie
