-- 九变篇「奇珍牌弃牌堆」：官方规则为奇珍牌进入弃牌堆时单独放置便于检索，
-- 仍属弃牌堆，洗牌时与其他牌一起混洗。因此这里不改动牌的真实区域，只用一个
-- 左上角 banner（@$ 前缀 → 可点开的牌堆）镜像展示当前弃牌堆里的奇珍牌。
local qizhenPile = fk.CreateSkill{
  name = "#fengsui_qizhen_pile",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["#fengsui_qizhen_pile"] = "奇珍牌弃牌堆",
  ["@$fengsui_qizhen_discard"] = "奇珍牌弃牌堆",
}

local BANNER = "@$fengsui_qizhen_discard"

local function isCurio(id)
  local card = Fk:getCardById(id)
  return card and card.type == Card.TypeEquip and card.package and
    card.package.name == "nine_variations"
end

local function nineOn(room)
  if not room or not room.getSettings then return false end
  local value = room:getSettings("fengsui_enable_nine_variations")
  return value == true or value == 1 or value == "1" or value == "true"
end

-- 依据房间 discard_pile 全量重算并刷新 banner，避免增量增删在洗牌/批量移动时失步。
local function refresh(room)
  if not nineOn(room) then
    room:setBanner(BANNER, nil)
    return
  end
  local ids = {}
  for _, id in ipairs(room.discard_pile) do
    if isCurio(id) then table.insert(ids, id) end
  end
  room:setBanner(BANNER, ids)
end

qizhenPile:addEffect(fk.AfterCardsMove, {
  global = true,
  mute = true,
  priority = 1.001,
  can_trigger = function(self, event, target, player, data)
    -- 只让一号位刷新，避免每个角色各触发一次导致重复 setBanner
    if player.seat ~= 1 or not nineOn(player.room) then return false end
    for _, move in ipairs(data) do
      for _, info in ipairs(move.moveInfo) do
        -- 注意：MoveInfo 只有 fromArea，没有 toArea；目标区域在 move 层（move.toArea）。
        if isCurio(info.cardId) and
          (info.fromArea == Card.DiscardPile or move.toArea == Card.DiscardPile) then
          return true
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    refresh(player.room)
  end,
})

qizhenPile:addEffect(fk.AfterDrawPileShuffle, {
  global = true,
  mute = true,
  priority = 1.001,
  can_trigger = function(self, event, target, player, data)
    return player.seat == 1 and nineOn(player.room)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    refresh(player.room)
  end,
})

return qizhenPile
