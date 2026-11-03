-- 残愠 · 废除副将版存档（不挂载任何武将，留作 abolishedversion）
-- 效果：锁定技，当你死亡时，你令所有伤害来源和野心家角色选择一项：
-- 1.与你势力相同的角色依次对其造成一点伤害；2.废除副将。
local H = require "packages.fengsui.hegemony_util"

local canyun = fk.CreateSkill {
  name = "fengsui_heg__canyun_abolishedversion",
  tags = { Skill.Compulsory },
}

local function damageSources(room, dead)
  local sources = {}
  for _, e in ipairs(room.logic:getEventsOfScope(GameEvent.Damage, 9999, function() return true end, Player.HistoryGame)) do
    local damage = e.data
    if e.exec_ret == true and damage and damage.to == dead and damage.from and damage.from:isAlive() then
      table.insertIfNeed(sources, damage.from)
    end
  end
  return sources
end

canyun:addEffect(fk.Death, {
  global = true,
  can_trigger = function(self, _, target, player)
    if target ~= player or not player:hasSkill(canyun.name, false, true) then return false end
    local room = player.room
    return #damageSources(room, player) > 0 or
      table.find(room.alive_players, function(p) return H.getKingdom(p) == "wild" end) ~= nil
  end,
  on_use = function(self, _, target, player)
    local room = player.room
    local kingdom = H.getKingdom(player)
    local affected = damageSources(room, player)
    for _, p in ipairs(room:getAlivePlayers()) do
      if H.getKingdom(p) == "wild" then table.insertIfNeed(affected, p) end
    end
    for _, p in ipairs(affected) do
      local choices = { "fengsui_heg__canyun_abolishedversion_damage" }
      if H.hasGeneral(p, true) then table.insert(choices, "fengsui_heg__canyun_abolishedversion_remove") end
      local choice = room:askToChoice(p, {
        choices = choices,
        skill_name = canyun.name,
        prompt = "#fengsui_heg__canyun_abolishedversion-choice",
      })
      if choice == "fengsui_heg__canyun_abolishedversion_remove" then
        H.removeGeneral(p, true, canyun.name)
        -- @! 图章标记用于客户端 Photo 换 abolished 士兵图（picMarks 同步）。
        -- 必须放在 removeGeneral 之后：先换将、后落印，客户端最后一次收到的状态
        -- 才是「士兵 + 印章」，否则换将的地板刷新会把先前发出的印章标记盖掉。
        room:setPlayerMark(p, "@!fengsui_abolish_deputy", 1)
        room:setPlayerMark(p, "fengsui_heg__abolish_deputy_state", 1)
      else
        for _, ally in ipairs(room:getAlivePlayers()) do
          -- 残愠在死亡结算完成前触发，死亡角色本身仍属于场上角色；
          -- 选项一因此也包括伤害来源/野心家自己。
          if H.getKingdom(ally) == kingdom then
            room:damage { from = ally, to = p, damage = 1, skillName = canyun.name }
          end
        end
      end
    end
  end,
})

-- 废除副将后的通用限制：副将已经由士兵替代，之后任何变更副将的请求都被拦截。
canyun:addEffect(H.GeneralTransforming, {
  global = true,
  can_trigger = function(self, _, target, _, data)
    return target and data and not data.isMain and
      (target:getMark("fengsui_heg__abolish_deputy_state") > 0 or
        target:getMark("@fengsui_heg__canyun_abolishedversion_nochange") > 0 or
        target:getMark("@fengsui_heg__xunyun_nochange") > 0)
  end,
  on_use = function() return true end,
})

Fk:loadTranslationTable {
  ["#fengsui_heg__canyun_abolishedversion-choice"] = "残愠：请选择一项",
  ["fengsui_heg__canyun_abolishedversion_damage"] = "令与你势力相同的角色依次对你造成一点伤害",
  ["fengsui_heg__canyun_abolishedversion_remove"] = "废除副将",
  ["@fengsui_heg__abolish_deputy"] = "废除副将",
  ["@fengsui_heg__canyun_abolishedversion_nochange"] = "废除副将",
}

return canyun
