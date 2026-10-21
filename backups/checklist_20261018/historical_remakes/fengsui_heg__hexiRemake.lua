local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local hexi = fk.CreateSkill{
  name = "fengsui_heg__hexiRemake",
}

hexi:addEffect(fk.AfterCardsMove, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    -- 摸牌阶段外获得牌
    local obtained = table.find(data, function(move)
      return move.to == player and move.toArea == Card.PlayerHand
    end)
    return player:hasSkill(hexi.name) and obtained and player.phase ~= Player.Draw
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local equips = player:getCardIds("e")
    if #equips == 0 then return false end

    local cid = U.chooseCardsFromList(room, player, equips, 1, 1,
      "#fengsui_heg__hexiRemake-move", hexi.name, true)
    if #cid > 0 then
       local tos = room:askToChoosePlayers(player, {
          targets = table.filter(room.alive_players, function(p)
            return p ~= player and H.getGeneralsRevealedNum(p) > 0 and player:canMoveCardInBoardTo(p, cid[1])
          end),
          min_num = 1, max_num = 1,
          cancelable = true,
          prompt = "#fengsui_heg__hexiRemake-choose",
          skill_name = hexi.name,
       })
       if #tos > 0 then
          event:setCostData(self, { card = cid[1], to = tos[1] })
          return true
       end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).to
    local c = Fk:getCardById(event:getCostData(self).card)

    -- 置入装备区
    room:moveCardTo(c, Card.PlayerEquip, to, fk.ReasonJustMove, hexi.name, nil, false, player)

    if to:isAlive() then
       local choices = {}
       if not H.allGeneralsRevealed(to) then
          table.insert(choices, "fengsui_heg__hexiRemake_reveal_draw")
       else
          table.insert(choices, "fengsui_heg__hexiRemake_hide_damage")
       end
       if #choices == 0 then return end

       local choice = room:askToChoice(to, {
          choices = choices,
          prompt = "#fengsui_heg__hexiRemake-choice",
          skill_name = hexi.name,
       })

       if choice == "fengsui_heg__hexiRemake_reveal_draw" then
          U.revealOneGeneral(to)
          to:drawCards(2, hexi.name)
       else
          H.doHideGeneral(room, to, to, hexi.name)
          if room.current and room.current:isAlive() then
             room:damage{ from = to, to = room.current, damage = 1, skillName = hexi.name }
          end
       end
    end
  end,
})

return hexi
