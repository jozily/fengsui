local juben = fk.CreateSkill { name = "fengsui_toaru__heg__juben" }

local used_mark = "fengsui_toaru__heg__juben-round"
local max_use_per_round = 2

Fk:loadTranslationTable{
  ["fengsui_toaru__heg__juben"] = "剧本",
  [":fengsui_toaru__heg__juben"] = "每轮限两次，当一名角色使用基本牌或普通锦囊牌指定目标后，若此牌的目标数为1，你可以展示牌堆顶的一张牌，"..
    "然后选择将此牌的目标改为或增加一名合法目标（按展示牌的点数向前或向后递推座次），最后你获得展示牌。",
  ["#fengsui_toaru__heg__juben-invoke"] = "剧本：是否展示牌堆顶一张牌，改动 %dest 使用的牌的目标？",
  ["#fengsui_toaru__heg__juben-choose"] = "剧本：牌堆顶为 %arg 点，选择如何改动目标",
  ["fengsui_toaru__heg__juben_change_fwd"] = "改为 %dest（向前递推）",
  ["fengsui_toaru__heg__juben_change_back"] = "改为 %dest（向后递推）",
  ["fengsui_toaru__heg__juben_add_fwd"] = "增加 %dest（向前递推）",
  ["fengsui_toaru__heg__juben_add_back"] = "增加 %dest（向后递推）",
}

local function cardAllowed(card)
  return card ~= nil and (card.type == Card.TypeBasic or card:isCommonTrick())
end

-- 递推座次：向前即沿下家方向数，向后即沿上家方向数，按存活角色绕圈计数。
local function seatTarget(origin, num, forward)
  if num <= 0 then return nil end
  local count = #origin.room.alive_players
  if count <= 1 then return nil end
  local step = num % count
  if step == 0 then return nil end
  if forward then return origin:getNextAlive(false, step) end
  return origin:getLastAlive(false, step)
end

local function canBeTarget(use, p)
  if not p or not p:isAlive() then return false end
  if table.contains(use.tos, p) then return false end
  -- canUseTo 内部还会调用 canUse，连带检查「本阶段还能否再使用这张牌」。
  -- 杀在 TargetSpecified 时次数已经记上，普通角色每阶段只能用一张，
  -- 于是所有候选目标都被判非法，剧本对大多数杀都不触发；只有装备连弩、
  -- 有无限杀技能、或回合外响应打出的杀才有剩余次数，表现成「有些角色的
  -- 杀触发不了」。剧本只关心「此人能否成为该牌的目标」，故同时绕过
  -- 次数与距离两项限制（两者都是 UseExtraData 的标准字段）。
  return use.from:canUseTo(use.card, p, {
    bypass_distances = true,
    bypass_times = true,
  })
end

-- 展示牌点数决定递推步数，两个方向各给「改为」「增加」两种改法。
local function buildOptions(use, num)
  local options = {}
  local origin = use.tos[1]
  if not origin then return options end
  for _, forward in ipairs({ true, false }) do
    local cand = seatTarget(origin, num, forward)
    if canBeTarget(use, cand) then
      local suffix = forward and "fwd" or "back"
      table.insert(options, { key = "fengsui_toaru__heg__juben_change_" .. suffix, target = cand, change = true })
      table.insert(options, { key = "fengsui_toaru__heg__juben_add_" .. suffix, target = cand, change = false })
    end
  end
  return options
end

juben:addEffect(fk.TargetSpecified, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(juben.name) then return false end
    if player:getMark(used_mark) >= max_use_per_round then return false end
    if not data or not data.use or not data.from or data.cancelled then return false end
    if not cardAllowed(data.card) then return false end
    if #data.use.tos ~= 1 then return false end
    -- 点数要展示牌堆顶才知道，这里先只确认场上还有能当目标的人。
    return table.find(player.room.alive_players, function(p)
      return canBeTarget(data.use, p)
    end) ~= nil
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = juben.name,
      prompt = "#fengsui_toaru__heg__juben-invoke::" .. data.from.id,
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local use = data.use
    local origin = use.tos[1]
    local top = room:getNCards(1)[1]
    if not top or not origin then return end
    local number = Fk:getCardById(top).number or 0
    room:showCards({ top })
    -- 展示牌堆顶即视为发动一次，无论后续是否找到可改动的目标。
    room:addPlayerMark(player, used_mark, 1)
    local options = buildOptions(use, number)
    if #options == 0 then
      -- 旧写法在这里直接 return，展示的牌既没给玩家也没退回牌堆，会凭空消失。
      room:obtainCard(player, top, false, fk.ReasonPrey, player, juben.name)
      return
    end
    local choices = table.map(options, function(o) return o.key .. "::" .. o.target.id end)
    local chosen = room:askToChoice(player, {
      choices = choices,
      skill_name = juben.name,
      prompt = "剧本：牌堆顶为 " .. number .. " 点，选择如何改动目标",
    })
    local picked
    for i, choice in ipairs(choices) do
      if choice == chosen then picked = options[i] break end
    end
    if picked then
      if picked.change then data:cancelTarget(origin) end
      data:addTarget(picked.target)
    end
    room:obtainCard(player, top, false, fk.ReasonPrey, player, juben.name)
  end,
})

return juben
