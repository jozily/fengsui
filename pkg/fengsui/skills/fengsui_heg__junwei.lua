local H = require "packages.hegemony.util"
local U = require "packages.hegemony.pkg.fengsui.util"

local junwei = fk.CreateSkill{
  name = "fengsui_heg__junwei",
}

junwei:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(junwei.name) and
      player.phase == Player.Start and table.find(player.room.alive_players, function(p)
        return not H.compareKingdomWith(p, player)
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local same_count = table.count(room.alive_players, function(p)
      return H.compareKingdomWith(p, player)
    end)
    local chosen = room:askToChoosePlayers(player, {
      targets = table.filter(room.alive_players, function(p)
        return not H.compareKingdomWith(p, player)
      end),
      min_num = 1,
      max_num = math.min(same_count, 4),
      prompt = "#fengsui_heg__junwei-targets:::" .. math.min(same_count, 4),
      skill_name = junwei.name,
      cancelable = true,
    })
    if #chosen > 0 then
      local command = H.askToStartCommand(player, { skill_name = junwei.name })
      if command then
        event:setCostData(self, { tos = chosen, command = command })
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cost = event:getCostData(self)
    local used = {}
    for _, to in ipairs(cost.tos) do
      if to:isAlive() then
        local choices = {}
        if not table.contains(used, "fengsui_heg__junwei_opt1") then
          table.insert(choices, "fengsui_heg__junwei_opt1")
        end
        if not table.contains(used, "fengsui_heg__junwei_opt2") and #to:getCardIds("hej") > 0 then
          table.insert(choices, "fengsui_heg__junwei_opt2")
        end
        if not table.contains(used, "fengsui_heg__junwei_opt3") and H.getGeneralsRevealedNum(to) > 0 then
          table.insert(choices, "fengsui_heg__junwei_opt3")
        end
        if not table.contains(used, "fengsui_heg__junwei_opt4") then
          table.insert(choices, "fengsui_heg__junwei_opt4")
        end
        if #choices == 0 then break end
        local choice = room:askToChoice(to, {
          choices = choices,
          prompt = "#fengsui_heg__junwei-choice",
          skill_name = junwei.name,
        })
        table.insert(used, choice)
        if choice == "fengsui_heg__junwei_opt1" then
          H.Command{
            tos = { to },
            from = player,
            command = cost.command,
            skillName = junwei.name,
            forced = true,
          }
          if to:isAlive() then
            local tos = room:askToChooseToMoveCardInBoard(to, {
              prompt = "#fengsui_heg__junwei-move",
              skill_name = junwei.name,
              cancelable = true,
            })
            if #tos == 2 then
              room:askToMoveCardInBoard(to, {
                target_one = tos[1],
                target_two = tos[2],
                skill_name = junwei.name,
              })
            end
          end
        elseif choice == "fengsui_heg__junwei_opt2" then
          local cards = U.chooseCardsFromList(room, to, to:getCardIds("hej"), 1, 1,
            "#fengsui_heg__junwei-discard", junwei.name, false)
          room:throwCard(cards, junwei.name, to, to)
          if to:isAlive() then to:drawCards(2, junwei.name) end
        elseif choice == "fengsui_heg__junwei_opt3" then
          H.doHideGeneral(room, to, to, junwei.name)
          room:setPlayerMark(to, "@@fengsui_heg__junwei-turn", 1)
        elseif choice == "fengsui_heg__junwei_opt4" then
          local n = to:getHandcardNum()
          if n > 0 then
            room:throwCard(to:getCardIds("h"), junwei.name, to, to)
            if to:isAlive() then to:drawCards(n, junwei.name) end
          end
        end
      end
    end
  end,
})

junwei:addEffect(fk.GeneralShown, {
  global = true,
  mute = true,
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@@fengsui_heg__junwei-turn") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    if data.m then player:hideGeneral(false) end
    if data.d then player:hideGeneral(true) end
  end,
})

return junwei
