local chaos = fk.CreateSkill {
  name = "heg_chaos_skill",
}

Fk:loadTranslationTable {
  ["heg_chaos"] = "文和乱武",
  [":heg_chaos"] = "锦囊牌<br /><b>时机</b>：出牌阶段<br /><b>目标</b>：所有角色<br /><b>效果</b>：目标角色依次展示手牌,你选择一项：1.令其弃置两张类别各不同的手牌；2.你弃置其中一张牌。" ..
  "<br />群：群势力角色执行效果后若没有手牌，则将手牌摸至体力值。",

  ["heg_chaos_skill"] = "文和乱武",
  ["#heg_chaos_skill"] = "文和乱武：对所有角色使用，目标角色依次展示手牌",

  ["chaos_discard-self"] = "令 %src 弃置两张类别各不同的手牌",
  ["chaos_discard-others"] = "你弃置其中一张牌",
  ["#whlw-discard"] = "文和乱武：弃置两张类别各不同的手牌",
}


chaos:addEffect("cardskill", {
  prompt = "#heg_chaos_skill",
  can_use = Util.GlobalCanUse,
  on_use = function(self, room, cardUseEvent)
    return Util.AoeCardOnUse(self, cardUseEvent.from, cardUseEvent, true)
  end,
  mod_target_filter = Util.TrueFunc,
  on_effect = function(self, room, effect)
    local player = effect.from
    local target = effect.to
    local cards = target:getCardIds("h")
    if not target.dead and not target:isKongcheng() then
      target:showCards(cards)
      room:showCards(cards, target)
      local choices = {}
      local allChoices = { "chaos_discard-self:"..target.id, "chaos_discard-others" }
      table.insert(choices, "chaos_discard-others")
      local types = {}
      for _, c in ipairs(cards) do
        local card = Fk:getCardById(c)
        if not table.contains(types, card.type) then
          table.insertIfNeed(types, card.type)
        end
      end
      if #types > 1 then
        table.insert(choices, "chaos_discard-self:"..target.id)
      end
      local choice = room:askToChoice(player, { choices = choices, skill_name = chaos.name, all_choices = allChoices })
      if choice:startsWith("chaos_discard-self:" .. target.id) then   --自己弃牌
        local result, dat = room:askToUseActiveSkill(target, {
          skill_name = "#heg_chaos_active",
          prompt = "#whlw-discard",
          cancelable = false,
        })
        if result and dat then
          room:throwCard(dat.cards, chaos.name, target, target)
        end
        if player.kingdom == "qun" and target.kingdom == "qun" and target:isKongcheng() then
          local num = target.hp - target:getHandcardNum()
          if num > 0 then
            target:drawCards(num, chaos.name)
          end
        end
      end
      if choice:startsWith("chaos_discard-others") then     --别人弃牌
        if target:getHandcardNum() > 0 then
          local card, _ = room:askToChooseCardsAndChoice(player, {
            cards = target:getCardIds("h"),
            choices = { "OK" },
            skill_name = chaos.name,
            min_num = 1,
            max_num = 1,
            all_cards = target:getCardIds("h"),
          })
          room:throwCard(card, chaos.name, target, player)
          if player.kingdom == "qun" and target.kingdom == "qun" and target:isKongcheng() then
            local num = target.hp - target:getHandcardNum()
            if num > 0 then
              target:drawCards(num, chaos.name)
            end
          end
        end
      end
    end
  end,
})

return chaos
