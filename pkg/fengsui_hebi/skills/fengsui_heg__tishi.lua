local H = require "packages.fengsui.hegemony_util"
local tishi = fk.CreateSkill { name = "fengsui_heg__tishi", tags = { Skill.Compulsory } }
  tishi:addEffect(fk.HpChanged, {
    can_trigger = function(self, _, target, player, data)
      return target == player and player:hasSkill(self.name) and data and data.old ~= player.hp and (player.hp == 3 or player.hp == 2 or player.hp == 1) and player:getMark("fengsui_heg__tishi-" .. player.hp .. "-round") == 0
    end,
    on_use = function(self, _, _, player)
      local room = player.room
      local n = player.hp
      room:setPlayerMark(player, "fengsui_heg__tishi-" .. n .. "-round", 1)
      local Heg = require "packages.fengsui.hegemony_util"
      if n == 3 then Heg.addHegMark(player, "yinyangfish")
      elseif n == 2 then Heg.addHegMark(player, "vanguard")
      elseif n == 1 then
        local card = Fk:cloneCard("thunder__slash")
        local targets = table.filter(room:getOtherPlayers(player), function(p) return player:canUseTo(card, p, { bypass_times = true, bypass_distances = true }) end)
        if #targets > 0 then
          local tos = room:askToChoosePlayers(player, { targets = targets, min_num = 1, max_num = 1, cancelable = false, skill_name = self.name, prompt = "#fengsui_heg__tishi-slash" })
          if #tos > 0 then room:useVirtualCard("thunder__slash", nil, player, tos[1], self.name, true) end
        end
      end
    end,
  })
tishi:addEffect(fk.RoundStart, { global = true, on_use = function(self, _, target) for _, n in ipairs({1,2,3}) do target.room:setPlayerMark(target, "fengsui_heg__tishi-" .. n .. "-round", 0) end end })
return tishi
