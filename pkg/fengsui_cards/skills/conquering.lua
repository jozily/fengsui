local conquering = fk.CreateSkill {
  name = "heg_conquering_skill",
}

Fk:loadTranslationTable {
  ["heg_conquering"] = "克复中原",
  [":heg_conquering"] = "锦囊牌<br /><b>时机</b>：出牌阶段<br /><b>目标</b>：任意名角色<br /><b>效果</b>：目标角色依次选择一项：1.视为使用一张【杀】；" ..
  "2.摸一张牌。<br />蜀：蜀势力角色选择1时【杀】伤害+1，选择2时改为摸两张牌。<br />",

  ["heg_conquering_skill"] = "克复中原",
  ["#heg_conquering_skill"] = "克复中原：选择任意名角色使用",

  ["#kfzy-choose"] = "克复中原：选择一名角色成为【杀】的目标",
  ["kfzy_useslash"] = "视为使用一张【杀】",
  ["kfzy_drawcards"] = "摸一张牌",
}

conquering:addEffect("cardskill", {
  prompt = "#heg_conquering_skill",
  min_target_num = 1,
  mod_target_filter = function(self, to_select, selected, player)
    return to_select:isAlive()
  end,
  target_filter = Util.CardTargetFilter,
  on_effect = function(self, room, effect)
    local player = effect.from
    local target = effect.to
    local choices = {}
    local slash = Fk:cloneCard("slash")
    table.insert(choices, "kfzy_useslash")
    table.insert(choices, "kfzy_drawcards")
    local choice = room:askToChoice(target, { choices = choices, skill_name = conquering.name })
    if choice == "kfzy_drawcards" then
      if player.kingdom == "shu" and target.kingdom == "shu" then
        target:drawCards(2, conquering.name)
      else
        target:drawCards(1, conquering.name)
      end
    end
    if choice == "kfzy_useslash" then
      local max_num = slash.skill:getMaxTargetNum(target, slash)
      local targets = table.filter(room:getOtherPlayers(target, false), function(p)
        return target:inMyAttackRange(p)
      end)
      if #targets == 0 or max_num == 0 then return end
      local tos = room:askToChoosePlayers(target, {
        targets = targets,
        min_num = 1,
        max_num = max_num,
        prompt = "#kfzy-choose",
        skill_name = conquering.name,
        cancelable = true,
      })
      if #tos > 0 then
        if player.kingdom == "shu" and target.kingdom == "shu" then
          room:useCard({
            from = target,
            tos = tos,
            card = slash,
            extraUse = false,
            additionalDamage = 1,
          })
        else
          room:useCard({
            from = target,
            tos = tos,
            card = slash,
            extraUse = false,
          })
        end
      end
    end
  end,
})

return conquering
