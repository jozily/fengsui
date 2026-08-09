local H = require "packages.fengsui.hegemony_util"

local yudao = fk.CreateSkill{
  name = "fengsui_heg__yudao",
}

yudao:addEffect(fk.Damage, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yudao.name) and data.to and data.to:isAlive() and
      H.compareKingdomWith(player, data.to)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = yudao.name,
      prompt = "#fengsui_heg__yudao-change::" .. data.to.id,
    })
  end,
  on_use = function(self, event, target, player, data)
    H.askToHebiOrTransform(player.room, data.to, yudao.name, false)
  end,
})

yudao:addEffect(fk.Damaged, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(yudao.name) or not data.from or data.from.dead or
      not H.compareKingdomWith(player, data.from) then return false end
    return player:getMark("@!!yinyangfish") == 0 or data.from:getMark("@!!yinyangfish") == 0
  end,
  on_cost = function(self, event, target, player, data)
    local candidates = table.filter({player, data.from}, function(p)
      return p:isAlive() and p:getMark("@!!yinyangfish") == 0
    end)
    local chosen = player.room:askToChoosePlayers(player, {
      targets = candidates,
      min_num = 1,
      max_num = 1,
      skill_name = yudao.name,
      prompt = "#fengsui_heg__yudao-fish",
      cancelable = true,
    })
    if #chosen > 0 then
      event:setCostData(self, {to = chosen[1]})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    H.addHegMark(event:getCostData(self).to, "yinyangfish")
  end,
})

Fk:loadTranslationTable{
  ["#fengsui_heg__yudao-change"] = "熨道：你可以令 %dest 合璧或变更副将",
  ["#fengsui_heg__yudao-fish"] = "熨道：选择双方中一名没有阴阳鱼标记的角色获得标记",
}

return yudao
