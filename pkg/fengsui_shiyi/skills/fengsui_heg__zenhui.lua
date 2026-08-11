local H = require "packages.fengsui.hegemony_util"

local zenhui = fk.CreateSkill {
  name = "fengsui_heg__zenhui",
}

Fk:loadTranslationTable{
  ["fengsui_heg__zenhui"] = "谮毁",
  [":fengsui_heg__zenhui"] = "当你使用黑色【杀】指定目标后，若你的武将牌均明置，你可以暗置另一张武将牌并令一名非此牌目标角色成为此牌的额外目标或使用者。若其势力与你不同，你交给其其明置武将牌数张牌。",
  ["#fengsui_heg__zenhui-choose"] = "谮毁：选择一名非此%arg目标的角色",
  ["#fengsui_heg__zenhui-choice"] = "谮毁：令 %dest 成为此牌的额外目标或使用者",
  ["fengsui_heg__zenhui_target"] = "成为额外目标",
  ["fengsui_heg__zenhui_user"] = "成为使用者",
  ["#fengsui_heg__zenhui-give"] = "谮毁：交给 %dest %arg 张牌",

  ["$fengsui_heg__zenhui1"] = "我的好妹妹，来世莫要生于帝王家。",
  ["$fengsui_heg__zenhui2"] = "至尊有诏，不从长公主旨，斩！",
}

local function hideOtherGeneral(player)
  local place = H.inGeneralSkills(player, zenhui.name)
  if not place then return false end
  local hideDeputy = place == "m"
  if hideDeputy then
    player.room:setPlayerMark(player, "__heg_deputy", player.deputyGeneral)
  else
    player.room:setPlayerMark(player, "__heg_general", player.general)
  end
  player:hideGeneral(hideDeputy)
  return true
end

zenhui:addEffect(fk.TargetSpecifying, {
  can_trigger = function(self, event, target, player, data)
    if data.from ~= player or not player:hasSkill(zenhui.name) or
      not H.allGeneralsRevealed(player) or not data.firstTarget or
      data.card.trueName ~= "slash" or data.card.color ~= Card.Black then
      return false
    end
    return table.find(player.room.alive_players, function(p)
      return p ~= player and not table.contains(data.use.tos, p)
    end) ~= nil
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local candidates = table.filter(room.alive_players, function(p)
      return p ~= player and not table.contains(data.use.tos, p)
    end)
    local tos = room:askToChoosePlayers(player, {
      targets = candidates,
      min_num = 1,
      max_num = 1,
      prompt = "#fengsui_heg__zenhui-choose:::" .. data.card:toLogString(),
      skill_name = zenhui.name,
      cancelable = true,
    })
    if #tos == 0 then return false end
    local to = tos[1]
    local extraTargets = data:getExtraTargets({ bypass_times = true })
    local choices = { "fengsui_heg__zenhui_user", "Cancel" }
    if table.contains(extraTargets, to) then
      table.insert(choices, 1, "fengsui_heg__zenhui_target")
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      all_choices = { "fengsui_heg__zenhui_target", "fengsui_heg__zenhui_user", "Cancel" },
      skill_name = zenhui.name,
      prompt = "#fengsui_heg__zenhui-choice::" .. to.id,
    })
    if choice == "Cancel" then return false end
    event:setCostData(self, { tos = tos, choice = choice })
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cost = event:getCostData(self)
    local to = cost.tos[1]
    if not hideOtherGeneral(player) then return end
    if cost.choice == "fengsui_heg__zenhui_target" then
      data:addTarget(to)
    else
      data.from = to
    end
    if player.dead or to.dead or H.compareKingdomWith(player, to) then return end
    local n = math.min(H.getGeneralsRevealedNum(to), #player:getCardIds("he"))
    if n == 0 then return end
    local cards = room:askToCards(player, {
      min_num = n,
      max_num = n,
      include_equip = true,
      skill_name = zenhui.name,
      prompt = "#fengsui_heg__zenhui-give::" .. to.id .. ":" .. n,
      cancelable = false,
    })
    room:moveCardTo(cards, Card.PlayerHand, to, fk.ReasonGive, zenhui.name, nil, false, player)
  end,
})

return zenhui
