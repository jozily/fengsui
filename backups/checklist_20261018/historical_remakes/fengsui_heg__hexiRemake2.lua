local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local hexi = fk.CreateSkill{
  name = "fengsui_heg__hexi",
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
    local equips = table.filter(player:getCardIds("he"), function(id)
      return Fk:getCardById(id).type == Card.TypeEquip
    end)
    if #equips == 0 then return false end

    local cid = U.chooseCardsFromList(room, player, equips, 1, 1,
      "#fengsui_heg__hexi-move", hexi.name, true)
    if #cid > 0 then
       local tos = room:askToChoosePlayers(player, {
          targets = table.filter(room.alive_players, function(p)
            return player:canMoveCardInBoardTo(p, cid[1])
          end),
          min_num = 1, max_num = 1,
          cancelable = true,
          prompt = "#fengsui_heg__hexi-choose",
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
       if H.getGeneralsRevealedNum(to) < 2 then table.insert(choices, "fengsui_heg__hexi_reveal_damage") end
       if H.allGeneralsRevealed(to) then table.insert(choices, "fengsui_heg__hexi_hide_draw") end
       if #choices == 0 then return end

       local choice = room:askToChoice(to, {
          choices = choices,
          prompt = "#fengsui_heg__hexi-choice",
          skill_name = hexi.name,
       })

       if choice == "fengsui_heg__hexi_reveal_damage" then
          U.revealOneGeneral(to)
          if room.current and room.current:isAlive() then
             room:damage{ from = to, to = room.current, damage = 1, skillName = hexi.name }
          end
       else
          local hidden_place = H.doHideGeneral(room, to, player, hexi.name)
          to:drawCards(2, hexi.name)
          local mark = to:getTableMark(MarkEnum.RevealProhibited .. "-turn")
          table.insertIfNeed(mark, hidden_place and "d" or "m")
          room:setPlayerMark(to, MarkEnum.RevealProhibited .. "-turn", mark)
       end
    end
  end,
})

Fk:loadTranslationTable{
  ["fengsui_heg__hexi_reveal_damage"] = "明置一张武将牌并对当前回合角色造成1点伤害",
  ["fengsui_heg__hexi_hide_draw"] = "暗置一张武将牌并摸两张牌（本回合不能明置）",
}

return hexi
