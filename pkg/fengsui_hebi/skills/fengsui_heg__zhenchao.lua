-- 每轮各限一次，当有一名角色的判定牌生效前或有一张牌被展示后，
-- 你可以用牌堆底的一张牌替代之，然后你可以获得原牌并将一张牌置入牌堆底。
local zhenchao = fk.CreateSkill { name = "fengsui_heg__zhenchao" }

-- 「每轮各限一次」的两个分支就是描述里的两个时机：判定牌生效前、
-- 一张牌被展示后。标记必须以 -round 结尾，引擎才会每轮自动清除；
-- 两个分支各用一枚，互不占用次数（参照 fengsui_heg__fuzhu_xs）。
local function usedMark(self, kind)
  return self.name .. "-" .. kind .. "-round"
end

local function available(self, player, kind)
  return player:hasSkill(self.name) and
    player:getMark(usedMark(self, kind)) == 0 and
    #player.room.draw_pile > 0
end

-- 后续效果整体可选：发动后询问是否「获得原牌并将一张牌置入牌堆底」。
-- 选择执行时先获得原牌、再选牌置底，因此玩家此时必有牌可用。
local function askGain(self, player)
  return player.room:askToSkillInvoke(player, {
    skill_name = self.name, prompt = "#fengsui_heg__zhenchao-gain",
  })
end

local function putBottom(self, player)
  local room = player.room
  if player.dead or player:isNude() then return end
  local cards = room:askToCards(player, {
    min_num = 1, max_num = 1, include_equip = true, cancelable = false,
    skill_name = self.name, prompt = "#fengsui_heg__zhenchao-bottom",
  })
  if #cards > 0 then
    room:moveCards {
      ids = cards, from = player, toArea = Card.DrawPile,
      drawPilePosition = -1, moveReason = fk.ReasonPut,
      skillName = self.name, moveVisible = true,
    }
  end
end

zhenchao:addEffect(fk.AskForRetrial, {
  can_trigger = function(self, _, target, player, data)
    return target and data and data.card and available(self, player, "judge")
  end,
  on_cost = function(self, _, _, player)
    return player.room:askToSkillInvoke(player, {
      skill_name = self.name, prompt = "#fengsui_heg__zhenchao",
    })
  end,
  on_use = function(self, _, _, player, data)
    local room = player.room
    local id = room.draw_pile[#room.draw_pile]
    if not id then return end
    room:setPlayerMark(player, usedMark(self, "judge"), 1)
    -- 必须先问：changeJudge 的 exchange 决定原判定牌进手牌还是弃牌堆。
    local gain = askGain(self, player)
    room:changeJudge {
      card = Fk:getCardById(id), player = player, data = data,
      skillName = self.name, exchange = gain,
    }
    if gain then putBottom(self, player) end
  end,
})

zhenchao:addEffect(fk.CardShown, {
  can_trigger = function(self, _, target, player, data)
    return target and available(self, player, "shown") and data and
      data.cardIds and #data.cardIds == 1
  end,
  on_cost = function(self, _, _, player)
    return player.room:askToSkillInvoke(player, {
      skill_name = self.name, prompt = "#fengsui_heg__zhenchao",
    })
  end,
  on_use = function(self, _, target, player, data)
    local room = player.room
    local original = data.cardIds[1]
    local area = room:getCardArea(original)
    -- CardShown 的 from 在不同展示路径中并不总是填写；优先使用实际
    -- 持有者，避免把牌堆底的牌移动到 nil 角色而导致区域状态损坏。
    local source = data.from or room:getCardOwner(original) or target
    local id = room.draw_pile[#room.draw_pile]
    if not id then return end
    room:setPlayerMark(player, usedMark(self, "shown"), 1)
    local gain = askGain(self, player)
    -- 先将底牌交到原牌所在区域，再处理原牌；后续展示事件读取替代牌。
    -- 判定区和处理区没有玩家归属，不能强行填写 to。
    local move = {
      ids = {id}, toArea = area, moveReason = fk.ReasonJustMove,
      skillName = self.name, moveVisible = true,
    }
    if source and (area == Card.PlayerHand or area == Card.PlayerEquip or
        area == Card.PlayerJudge or area == Card.PlayerSpecial) then
      move.to = source
    end
    room:moveCards(move)
    data.cardIds = {id}
    if data.card then data.card = Fk:getCardById(id) end
    if gain then
      room:obtainCard(player, original, true, fk.ReasonPrey, player, self.name)
      putBottom(self, player)
    else
      -- 未获得原牌时也必须让它离开原区域：底牌已被放进原牌所在区域，
      -- 两张牌同时留在该区域会平白多出一张牌，故移入弃牌堆。
      room:moveCards {
        ids = { original }, from = room:getCardOwner(original),
        toArea = Card.DiscardPile, moveReason = fk.ReasonPut,
        skillName = self.name, moveVisible = true,
      }
    end
  end,
})

return zhenchao
