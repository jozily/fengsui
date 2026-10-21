local H = require "packages.fengsui.hegemony_util"

local lianxi = fk.CreateSkill{
  name = "fengsui_heg__lianxi",
}

lianxi:addEffect(fk.GeneralHidden, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target and player:hasSkill(lianxi.name) and target:isAlive() and
      H.compareKingdomWith(target, player) and data ~= "fengsui_heg__zhangbai"
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askToSkillInvoke(player, { skill_name = lianxi.name, prompt = "#fengsui_heg__lianxi-invoke::" .. target.id }) then
       return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room

    -- 1. 弃置其一个区域所有牌
    local choices = {}
    if not target:isKongcheng() then table.insert(choices, "lianxi_hand") end
    if #target:getCardIds("e") > 0 then table.insert(choices, "lianxi_equip") end
    if #target:getCardIds("j") > 0 then table.insert(choices, "lianxi_judge") end

    if #choices > 0 then
      local choice = room:askToChoice(player, { choices = choices, skill_name = lianxi.name })
      local cards = {}
      if choice == "lianxi_hand" then cards = target:getCardIds("h")
      elseif choice == "lianxi_equip" then cards = target:getCardIds("e")
      elseif choice == "lianxi_judge" then cards = target:getCardIds("j") end
      room:throwCard(cards, lianxi.name, target, player)
    end

    -- 2. 对当前回合角色造成1点伤害
    local current = room.current
    if current and current:isAlive() and target:isAlive() then
      room:damage{
        from = target,
        to = current,
        damage = 1,
        skillName = lianxi.name,
      }
    end

    -- 3. 与一名同势力副将易位
    local tos = table.filter(room.alive_players, function(p) return p ~= player and H.compareKingdomWith(p, player) end)
    if #tos > 0 then
      local to_swap = room:askToChoosePlayers(player, {
        targets = tos,
        min_num = 1,
        max_num = 1,
        skill_name = lianxi.name,
        prompt = "#fengsui_heg__lianxi-swap"
      })
      if #to_swap > 0 then
         H.swapDeputy(room, player, to_swap[1])
      end
    end
  end,
})

Fk:loadTranslationTable{
 ["#fengsui_heg__lianxi-invoke"] = "连徙：令 %dest 弃置一个区域所有牌并对当前角色造成1点伤害，然后你与队友副将易位",
  ["#fengsui_heg__lianxi-swap"] = "连徙：请选择一名同势力角色进行副将易位",
  ["lianxi_hand"] = "手牌区",
  ["lianxi_equip"] = "装备区",
  ["lianxi_judge"] = "判定区",
}

return lianxi
