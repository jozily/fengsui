local skill = fk.CreateSkill {
  name = "zhaoshu_yuan",
  attached_skill_name = "heg_zhaoshu_other&",
}

local H = require "packages.fengsui.hegemony_util"

Fk:loadTranslationTable {
  ["zhaoshu_yuan"] = "诏书",
  [":zhaoshu_yuan"] = "出牌阶段限一次，若【诏书】上有四张花色均不同的牌，你可以将【诏书】上所有的牌置入弃牌堆，然后随机获得一张势力锦囊。",

  ["zhaoshu_other&"] = "诏书",
  [":zhaoshu_other&"] = "出牌阶段限一次，你可以将一张（若你为小势力角色，则改为两张）手牌置于【诏书】上。",
  ["#zhaoshu_yuan_skill"] = "诏书：弃置【诏书】上的所有牌并随机获得一张势力锦囊",
  ["@[zhaoshu]"] = "诏书",
}

skill:addEffect("active", {
  anim_type = "offensive",
  prompt = "#zhaoshu_yuan_skill",
  card_filter = Util.FalseFunc,
  can_use = function(self, player)
    local cards = player:getPile("@[zhaoshu]")
    local suits = {}
    for _, id in ipairs(cards) do
      if Fk:getCardById(id).suit ~= Card.NoSuit and not table.contains(suits, Fk:getCardById(id).suit) and Fk:getCardById(id).name ~= "heg_zhaoshu" then
        table.insertIfNeed(suits, Fk:getCardById(id).suit)
      end
    end
    return #player:getPile("@[zhaoshu]") >= 4 and player:usedSkillTimes(skill.name, Player.HistoryPhase) == 0 and
    #suits == 4 and not player.dead
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local piles = player:getPile("@[zhaoshu]")
    for _, id in ipairs(piles) do
      local c = Fk:getCardById(id)
      if c.name == "heg_zhaoshu" then
        table.removeOne(piles, id)
        break
      end
    end
    local ruleworld = { { "heg_rule_the_world", Card.Spade, 12 } } --号令天下
    local kefu = { { "heg_conquering", Card.Diamond, 1 } }        --克复中原
    local guguo = { { "heg_consolidate_country", Card.Heart, 1 } } --固国安邦
    local wenhe = { { "heg_chaos", Card.Club, 12 } }              --文和乱武
    local taikang = { { "fengsui__taikangzhizhi", Card.Heart, 1 } } --太康之治
    local cards = { ruleworld, kefu, guguo, wenhe, taikang }
    local cardss = { "heg_rule_the_world", "heg_conquering", "heg_consolidate_country", "heg_chaos", "fengsui__taikangzhizhi" }
    if #piles > 0 then
      room:moveCardTo(piles, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, skill.name, "@[zhaoshu]", true, player)
      local i = math.random(#cards)
      local trickcard = room:prepareDeriveCards(cards[i], cardss[i])[1]
      if not player.dead and table.contains({ Card.Void, Card.DrawPile, Card.DiscardPile }, room:getCardArea(trickcard)) then
        room:setCardMark(Fk:getCardById(trickcard), MarkEnum.DestructIntoDiscard, 1)
        room:moveCardTo(trickcard, Player.Hand, player, fk.ReasonPrey, skill.name)
      end
    end
  end,
})

--给同势力增加技能
local skill_spec = {
  can_refresh = function(self, event, target, player, data)
    return target == player
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local players = room.alive_players
    local zhaoshus = table.filter(players, function(p) return p:hasSkill(skill.name) end)
    local zhaoshu_map = {}
    for _, p in ipairs(players) do
      local will_attach = false
      for _, zhaoshuyuan in ipairs(zhaoshus) do
        if (H.compareKingdomWith(zhaoshuyuan, p)) then
          will_attach = true
          break
        end
      end
      zhaoshu_map[p] = will_attach
    end
    for p, v in pairs(zhaoshu_map) do
      if v ~= p:hasSkill("heg_zhaoshu_other&") then
        room:handleAddLoseSkills(p, v and skill.attached_skill_name or "-" .. skill.attached_skill_name, nil, false, true)
      end
    end
  end,
}

skill:addEffect(fk.AfterPropertyChange, skill_spec)
skill:addEffect(fk.GeneralRevealed, skill_spec)
skill:addEffect(fk.GeneralHidden, skill_spec)
local adddAcquireEffect = function(self, player, _)
  local room = player.room
  for _, p in ipairs(room.alive_players) do
    if H.compareKingdomWith(player, p) then
      room:handleAddLoseSkills(p, skill.attached_skill_name, nil, false, true)
    end
  end
end
skill:addAcquireEffect(adddAcquireEffect)
local addLoseEffect = function(self, player, _)
  local room = player.room
  for _, p in ipairs(room.alive_players) do
    if H.compareKingdomWith(player, p) then
      room:handleAddLoseSkills(p, "-" .. skill.attached_skill_name, nil, false, true)
    end
  end
end
skill:addLoseEffect(addLoseEffect)

--诏书回流
skill:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    if player:hasSkill(skill.name, true, true) then
      for _, move in ipairs(data) do
        if move.from == player then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId).name == "heg_zhaoshu" and info.fromArea == Card.PlayerSpecial and info.fromSpecialName == "@[zhaoshu]" then
              return true
            end
          end
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local players = room.players
    player.room:setTag("hegzhaoshuRemoved", false)     --二次移除
    local zhaoshus = table.filter(players, function(p) return p:hasSkill(skill.name) end)
    local zhaoshu_map = {}
    for _, p in ipairs(players) do
      local will_attach = false
      for _, zhaoshuyuan in ipairs(zhaoshus) do
        if (H.compareKingdomWith(zhaoshuyuan, p)) then
          will_attach = true
          break
        end
      end
      zhaoshu_map[p] = will_attach
    end
    for p, v in pairs(zhaoshu_map) do
      if v ~= p:hasSkill("heg_zhaoshu_other&") then
        room:handleAddLoseSkills(p, v and skill.attached_skill_name or "-" .. skill.attached_skill_name, nil, false, true)
      end
    end
    room:handleAddLoseSkills(player, "-" .. skill.name, nil, false, true)
  end,
})

return skill
