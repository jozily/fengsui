local kuanqu = fk.CreateSkill {
  name = "fengsui_heg__kuanqu",
}

kuanqu:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player)
    return target == player and player.phase == Player.Play and player:hasSkill(self.name)
  end,
  on_cost = function(self, event, target, player)
    return player.room:askToSkillInvoke(player, {
      skill_name = self.name,
      prompt = "#fengsui_heg__kuanqu-invoke",
    })
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local wounded = table.filter(room.alive_players, function(p) return p.hp < p.maxHp end)
    local healthy = table.filter(room.alive_players, function(p) return p.hp >= p.maxHp end)
    if #wounded > 0 then
      room:useVirtualCard("god_salvation", nil, player, wounded, self.name, true)
    end
    if #healthy > 0 then
      room:useVirtualCard("amazing_grace", nil, player, healthy, self.name, true)
    end

    local hand_num = player:getHandcardNum()
    for _, p in ipairs(table.simpleClone(room.alive_players)) do
      if p:isAlive() and p ~= player and p.hp > player.hp then
        room:damage { from = player, to = p, damage = 1, skillName = self.name }
      end
    end
    for _, p in ipairs(room.alive_players) do
      if p:isAlive() and p ~= player and p:getHandcardNum() > hand_num and not p:isKongcheng() then
        local id = room:askToChooseCard(player, {
          target = p,
          flag = "h",
          skill_name = self.name,
          prompt = "#fengsui_heg__kuanqu-take::" .. p.id,
        })
        if id then room:obtainCard(player, id, true, fk.ReasonPrey, player, self.name) end
      end
    end
  end,
})

Fk:loadTranslationTable {
  ["#fengsui_heg__kuanqu-invoke"] = "款曲：是否视为使用桃园结义和五谷丰登？",
  ["#fengsui_heg__kuanqu-take"] = "款曲：获得 %dest 的一张手牌",
}

return kuanqu
