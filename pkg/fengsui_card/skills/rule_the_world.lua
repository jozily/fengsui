local rule_the_world = fk.CreateSkill {
  name = "rule_the_world_skill",
}

Fk:loadTranslationTable {
  ["rule_the_world_skill"] = "号令天下",
  ["#rule_the_world_skill"] = "号令天下：选择一名体力值不是全场最少的一名其他角色，其他角色选择对其使用一张【杀】或弃置其一张牌。",

  ["heg_rule_the_world"] = "号令天下",
  [":heg_rule_the_world"] = "锦囊牌<br /><b>时机</b>：出牌阶段<br /><b>目标</b>：体力值不是全场最少的一名其他角色<br /><b>效果</b>：所有除其之外的角色可以选择一项：1.弃置一张手牌，视为" ..
  "对其使用一张【杀】；2.弃置其一张牌。<br />魏：魏势力角色选择1时无需弃置牌，选择2时可以获得弃置的牌。<br />",

  ["hltx_useslash"] = "弃置一张手牌，视为对 %src 使用一张【杀】",
  ["hltx_discard"] = "弃置 %src 的一张牌",
  ["#haolingtianxia-discard1"] = "号令天下：弃置一张手牌，视为对 %src 使用一张【杀】",
  ["#haolingtianxia-discard2"] = "号令天下：弃置 %src 的一张牌",
}

rule_the_world:addEffect("cardskill", {
  prompt = "#rule_the_world_skill",
  target_num = 1,
  mod_target_filter = function(self, player, to_select, selected, card)
    if #selected == 0 then
      local n = 5
      for _, p in ipairs(Fk:currentRoom().alive_players) do
        if p.hp <= n then
          n = p.hp
        end
      end
      return to_select.hp ~= n and to_select ~= player
    end
  end,
  target_filter = Util.CardTargetFilter,
  can_use = function(self, player, card)
    return not player:isProhibited(player, card)
  end,
  on_effect = function(self, room, effect)
    local target = effect.to
    local player = effect.from
    if not target.dead then
      local choices = { "hltx_useslash:"..target.id, "hltx_discard:"..target.id, "Cancel" }
      local targets = table.filter(room:getOtherPlayers(target, true), function(p)
        return not p.dead
      end)
      room:sortByAction(targets)
      for _, p in ipairs(targets) do
        if not p.dead and not target.dead then
          local choice = room:askToChoice(p, { choices = choices, skill_name = rule_the_world.name })
          if choice == "hltx_useslash:" .. target.id then
            if not p:isKongcheng() and (player.kingdom ~= "wei" or p.kingdom ~= "wei") then --若为魏国使用的，则不需要丢牌
              room:askToDiscard(p, {
                min_num = 1,
                max_num = 1,
                include_equip = false,
                skill_name = rule_the_world.name,
                prompt = "#haolingtianxia-discard1:"..target.id,
                cancelable = false,
              })
            end
            room:useVirtualCard("slash", nil, p, target, rule_the_world.name, false)
          end
          if choice == "hltx_discard:"..target.id then
            if not target:isKongcheng() then
              local cid = room:askToChooseCard(p, {
                target = target,
                flag = "he",
                skill_name = rule_the_world.name,
                prompt = "#haolingtianxia-discard2:"..target.id,
              })
              room:throwCard({ cid }, rule_the_world.name, target, p)
              if player.kingdom == "wei" and p.kingdom == "wei" and not p.dead then --如果是魏国使用者,可以获得牌
                room:obtainCard(p, cid, true, fk.ReasonPrey)
              end
            end
          end
        end
      end
    end
  end,
})

return rule_the_world
