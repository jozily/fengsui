local H = require "packages.fengsui.hegemony_util"

local xunyun = fk.CreateSkill{
  name = "fengsui_heg__xunyunRemake",
  tags = { Skill.Compulsory },
}

xunyun:addEffect(fk.EnterDying, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xunyun.name) and player:usedSkillTimes(xunyun.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local from = data.damage and data.damage.from
    if from and not from.dead then
      local choices = {}
      if from.deputyGeneral ~= "anjiang" then table.insert(choices, 1, "xunyun_removeDeputy") end
      if H.allGeneralsRevealed(from) then table.insert(choices, "xunyun_hideAll") end
      if #choices > 0 then
        local choice = room:askToChoice(from, {
          choices = choices,
          skill_name = xunyun.name,
          prompt = "#fengsui_heg__xunyunRemake-choice::" .. player.id,
        })

        if choice == "xunyun_removeDeputy" then
          H.removeGeneral(from, true)
        else
          from:hideGeneral(false)
          from:hideGeneral(true)
          local mark = from:getTableMark(MarkEnum.RevealProhibited .. "-round")
          table.insertIfNeed(mark, "m")
          table.insertIfNeed(mark, "d")
          room:setPlayerMark(from, MarkEnum.RevealProhibited .. "-round", mark)
        end
      end
    end
    -- 记录脱离濒死时需要的参数
    local count = 0
    if from then
      for _, p in ipairs(room.alive_players) do
        if H.compareKingdomWith(p, from) then
           if p.general == "anjiang" then count = count + 1 end
           if p.deputyGeneral == "anjiang" then count = count + 1 end
        end
      end
    end
    room:setPlayerMark(player, "fengsui_heg__xunyunRemake_draw_count", count)
  end,
})

xunyun:addEffect(fk.AfterDying, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:isAlive() and player:getMark("fengsui_heg__xunyunRemake_draw_count") > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local count = player:getMark("fengsui_heg__xunyunRemake_draw_count")
    room:setPlayerMark(player, "fengsui_heg__xunyunRemake_draw_count", 0)

    local targets = table.filter(room.alive_players, function(p) return H.compareKingdomWith(p, player) end)
    if #targets > 0 and count > 0 then
      local to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = targets,
        skill_name = xunyun.name,
        prompt = "#fengsui_heg__xunyunRemake-draw:::" .. (count * 2)
      })
      if #to > 0 then
        to[1]:drawCards(count * 2, xunyun.name)
      end
    end
  end,
})

Fk:loadTranslationTable{
  ["fengsui_heg__xunyunRemake"] = "勋殒",
  [":fengsui_heg__xunyunRemake"] = "锁定技，当你首次进入濒死状态时，你令伤害来源选择一项：1.移除副将；2.若其武将牌均明置，暗置所有武将牌且本轮无法明置；然后若你脱离濒死，你令一名同势力角色摸X张牌（X为伤害来源势力暗置武将牌数的两倍）。",
  ["xunyun_removeDeputy"] = "移除副将",
  ["xunyun_hideAll"] = "若武将牌均明置，暗置所有武将牌，本轮无法明置",
  ["#fengsui_heg__xunyunRemake-choice"] = "勋殒：你导致 %dest 濒死，请选择承受代价",
  ["#fengsui_heg__xunyunRemake-draw"] = "勋殒：你脱离濒死，选一名同势力角色摸 %arg 张牌",
}

return xunyun
