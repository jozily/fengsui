local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"
local duanyuan = fk.CreateSkill {
  name = "fengsui_heg__duanyuan",
  tags = { Skill.Limited },
}

duanyuan:addEffect(fk.TurnStart, {
  global = true,
  can_trigger = function(self, _, target, player)
    return target and player:hasShownSkill(self.name) and
      player:getMark("fengsui_heg__duanyuan_used") == 0
  end,
  on_use = function(self, _, _, player)
    local room = player.room
    room:setPlayerMark(player, "fengsui_heg__duanyuan_used", 1)
    for _, p in ipairs(room.alive_players) do
      if p == player or H.compareKingdomWith(p, player) or p.kingdom == "unknown" then
        local choice = room:askToChoice(p, {
          choices = { "fengsui_heg__duanyuan_reveal", "fengsui_heg__duanyuan_recast" },
          skill_name = self.name,
          prompt = "#fengsui_heg__duanyuan-choice",
        })
        if choice == "fengsui_heg__duanyuan_reveal" then
          if p.general == "anjiang" then
            p:revealGeneral(false)
          elseif p.deputyGeneral == "anjiang" then
            p:revealGeneral(true)
          end
          room:addPlayerMark(p, "fengsui_heg__duanyuan_damage-turn", 1)
        else
          local ids, types, available = {}, {}, p:getCardIds("he")
          local distinct = {}
          for _, id in ipairs(available) do
            distinct[Fk:getCardById(id).type] = true
          end
          local distinctCount = 0
          for _ in pairs(distinct) do distinctCount = distinctCount + 1 end
          if distinctCount < 3 then
            ids = available
          else
            for _ = 1, 3 do
              local candidates = table.filter(available, function(id)
                return not table.contains(types, Fk:getCardById(id).type)
              end)
              local selected = U.chooseCardsFromList(room, p, candidates, 1, 1,
                "#fengsui_heg__duanyuan-recast", self.name, false)
              local cid = selected[1]
              if not cid then break end
              table.insert(ids, cid)
              table.insert(types, Fk:getCardById(cid).type)
              table.removeOne(available, cid)
            end
          end
          if #ids > 0 then room:recastCard(ids, p, self.name) end
        end
      end
    end
  end,
})

duanyuan:addEffect(fk.DamageCaused, {
  global = true,
  can_trigger = function(self, _, target, player, data)
    return target and data and data.from == target and
      target:getMark("fengsui_heg__duanyuan_damage-turn") > 0
  end,
  on_use = function(self, _, target, player, data)
    data.damage = (data.damage or 1) + 1
    target.room:setPlayerMark(target, "fengsui_heg__duanyuan_damage-turn", 0)
  end,
})

return duanyuan
