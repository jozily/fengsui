-- 【震朝】旧版存档技能，不挂载任何武将，只留作版本回溯。
-- 对应改动前的描述：每回合限一次，当有一名角色的判定牌生效前或有一张牌被
-- 展示后，你可以用牌堆底的一张牌替代之，然后你获得原牌并可以将一张牌置入
-- 牌堆底。与现版的差别：每回合共用一次（现版是两时机每轮各一次）、原牌
-- 必定获得（现版可选）、置入牌堆底可取消（现版为必须）。
-- official_overrides.lua 的 guardArchiveSkills 会对名字含 Remake 的技能统一
-- 补 hasSkill 门控，因此本技能不会误触发到没有它的玩家身上。
local zhenchao = fk.CreateSkill { name = "fengsui_heg__zhenchaoRemake" }

local function available(self, player)
  return player:hasSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 and
    #player.room.draw_pile > 0
end

local function putBottom(self, player)
  local room = player.room
  if player.dead or player:isNude() then return end
  local cards = room:askToCards(player, {
    min_num = 1, max_num = 1, include_equip = true, cancelable = true,
    skill_name = self.name, prompt = "#fengsui_heg__zhenchaoRemake-bottom",
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
    return target and data and data.card and available(self, player)
  end,
  on_cost = function(self, _, _, player)
    return player.room:askToSkillInvoke(player, {
      skill_name = self.name, prompt = "#fengsui_heg__zhenchaoRemake",
    })
  end,
  on_use = function(self, _, _, player, data)
    local room = player.room
    local id = room.draw_pile[#room.draw_pile]
    if not id then return end
    room:changeJudge {
      card = Fk:getCardById(id), player = player, data = data,
      skillName = self.name, exchange = true,
    }
    putBottom(self, player)
  end,
})

zhenchao:addEffect(fk.CardShown, {
  can_trigger = function(self, _, target, player, data)
    return target and available(self, player) and data and
      data.cardIds and #data.cardIds == 1
  end,
  on_cost = function(self, _, _, player)
    return player.room:askToSkillInvoke(player, {
      skill_name = self.name, prompt = "#fengsui_heg__zhenchaoRemake",
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
    -- 先将底牌交到原牌所在区域，再取得原牌；后续展示事件读取替代牌。
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
    room:obtainCard(player, original, true, fk.ReasonPrey, player, self.name)
    putBottom(self, player)
  end,
})

return zhenchao
