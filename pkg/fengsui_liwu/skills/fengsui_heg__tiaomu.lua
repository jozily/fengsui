local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_liwu.util"
local tiaomu = fk.CreateSkill {
  name = "fengsui_heg__tiaomu",
  tags = { Skill.Compulsory },
}
local target_mark = "@fengsui_heg__tiaomu"

tiaomu:addEffect(fk.TargetConfirmed, {
  can_trigger = function(self, _, target, player, data)
    return target == player and player:hasShownSkill(tiaomu.name) and data.use and data.from and
      data.use.card and data.use.card.type ~= Card.TypeEquip and
      H.allGeneralsRevealed(player) and
      player.maxHp == data.from.maxHp and
      ((U.getSkillPlace(player, tiaomu.name) and data.from.deputyGeneral ~= "anjiang") or
        (not U.getSkillPlace(player, tiaomu.name) and data.from.general ~= "anjiang")) and
      not data.from:inMyAttackRange(player)
  end,
  on_use = function(self, _, target, player, data)
    local room = player.room
    local place = U.getSkillPlace(player, tiaomu.name)
    if place == nil then return end
    player:hideGeneral(not place)
    room:drawCards(data.from, 1, tiaomu.name)
    data:setNullified(player)
    room:setPlayerMark(data.from, target_mark, 1)
  end,
})

-- 朱佩兰死亡后移除全场迢目标记
tiaomu:addEffect(fk.Death, {
  global = true,
  can_trigger = function(self, _, target, player)
    return target == player and player:hasSkill(tiaomu.name, true, true)
  end,
  on_use = function(self, _, target, player)
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      if p:getMark(target_mark) ~= 0 then
        room:setPlayerMark(p, target_mark, 0)
      end
    end
  end,
})

return tiaomu
