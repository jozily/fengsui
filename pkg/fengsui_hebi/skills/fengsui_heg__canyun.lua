local H = require "packages.fengsui.hegemony_util"

local canyun = fk.CreateSkill{
  name = "fengsui_heg__canyun",
  tags = { Skill.Compulsory },
}

canyun:addEffect(fk.Death, {
  global = true,
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(canyun.name, false, true) then return false end
    return (data.damage and data.damage.from and data.damage.from:isAlive()) or
      table.find(player.room.alive_players, function(p) return p.kingdom == "wild" end) ~= nil
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local kingdom = H.getKingdom(player)
    local affected = {}
    if data.damage and data.damage.from and data.damage.from:isAlive() then
      table.insert(affected, data.damage.from)
    end
    for _, p in ipairs(room:getAlivePlayers()) do
      if p.kingdom == "wild" then table.insertIfNeed(affected, p) end
    end
    for _, p in ipairs(affected) do
        local choices = {"fengsui_heg__canyun_damage"}
        if H.hasGeneral(p, true) then table.insert(choices, "fengsui_heg__canyun_remove") end
        local choice = room:askToChoice(p, {
          choices = choices,
          skill_name = canyun.name,
          prompt = "#fengsui_heg__canyun-choice",
        })
        if choice == "fengsui_heg__canyun_damage" then
          room:setPlayerMark(p, "@fengsui_heg__canyun_damage", kingdom)
        else
          p:drawCards(3, canyun.name)
          if p:isAlive() and H.hasGeneral(p, true) then H.removeGeneral(p, true) end
          room:setPlayerMark(p, "@fengsui_heg__canyun_nochange", 1)
        end
    end
  end,
})

canyun:addEffect(fk.DamageCaused, {
  global = true,
  can_trigger = function(self, event, target, player, data)
    local mark = data.to and data.to:getMark("@fengsui_heg__canyun_damage") or 0
    return data.from == target and type(mark) == "string" and mark ~= "" and
      H.getKingdom(data.from) == mark
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(1)
  end,
})

canyun:addEffect(H.GeneralTransforming, {
  global = true,
  can_trigger = function(self, event, target, player, data)
    return target:getMark("@fengsui_heg__canyun_nochange") > 0 and not data.isMain
  end,
  on_use = function(self, event, target, player, data)
    return true
  end,
})

Fk:loadTranslationTable{
  ["#fengsui_heg__canyun-choice"] = "残愠：请选择一项",
  ["fengsui_heg__canyun_damage"] = "贾褒同势力角色对你造成的伤害+1",
  ["fengsui_heg__canyun_remove"] = "摸三张牌，移除副将且无法再变更",
  ["@fengsui_heg__canyun_damage"] = "残愠：伤害+1",
  ["@fengsui_heg__canyun_nochange"] = "残愠：无法变更副将",
}

return canyun
