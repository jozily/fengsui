local s = fk.CreateSkill { name = "fengsui_heg__fuzhu_xs" }

s:addEffect(fk.CardUseFinished, {
  global = true,
  can_trigger = function(self, event, target, player, data)
    if not target or target.dead or not player:hasSkill(s.name) or
        target.kingdom ~= player.kingdom or not data.card then return false end
    if data.card.type == Card.TypeEquip then return false end
    -- 「每轮各限一次」的两个分支就是描述里 / 左右两侧：非转化牌、转化牌。
    -- 标记必须以 -round 结尾，引擎才会每轮自动清除。
    local kind = (data.card.skillName and data.card.skillName ~= "") and "converted" or "normal"
    return player:getMark(s.name .. "-" .. kind .. "-round") == 0 and not player:isKongcheng()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local kind = (data.card.skillName and data.card.skillName ~= "") and "converted" or "normal"
    room:setPlayerMark(player, s.name .. "-" .. kind .. "-round", 1)

    -- 端点由分支决定，不给玩家自选：非转化牌→置于牌堆底、亮出牌堆顶；
    -- 转化牌→置于牌堆顶、亮出牌堆底。亮出的始终是另一端。
    local putTop = (kind == "converted")
    local cards = room:askToCards(player, {
      min_num = 1, max_num = 1, include_equip = false,
      skill_name = s.name,
      prompt = putTop and "#fengsui_heg__fuzhu_xs-put-top" or "#fengsui_heg__fuzhu_xs-put-bottom",
      cancelable = false,
    })
    if #cards == 0 then return end
    room:moveCards {
      ids = cards, from = player, toArea = Card.DrawPile,
      moveReason = fk.ReasonPut, skillName = s.name,
      drawPilePosition = putTop and 1 or -1, moveVisible = true,
    }
    local shown = room:getNCards(3, putTop and "bottom" or "top")
    if #shown == 0 then return end
    room:showCards(shown, player, player)
    local types = {}
    for _, id in ipairs(shown) do
      table.insertIfNeed(types, Fk:getCardById(id):getTypeString())
    end
    local choice = room:askToChoice(player, {
      choices = types, skill_name = s.name, prompt = "#fengsui_heg__fuzhu_xs-type",
    })
    local gain = table.filter(shown, function(id)
      return Fk:getCardById(id):getTypeString() == choice
    end)
    if #gain > 0 then
      room:obtainCard(target, gain, true, fk.ReasonPrey, player, s.name)
    end
    local rest = table.filter(shown, function(id)
      return not table.contains(gain, id)
    end)
    -- getNCards 只查看、不移出牌堆：仅剩一张时它本就留在对应端，
    -- 直接跳过排序框；两张及以上才让玩家调整顺序后放回原端。
    if #rest > 1 then
      local n = #rest
      room:askToGuanxing(player, {
        cards = rest,
        top_limit = putTop and { 0, 0 } or { n, n },
        bottom_limit = putTop and { n, n } or { 0, 0 },
        area_names = { "牌堆顶", "牌堆底" },
        skill_name = s.name,
      })
    end
  end,
})

return s
