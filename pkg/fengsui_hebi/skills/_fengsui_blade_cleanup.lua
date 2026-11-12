-- 青龙偃月刀（sa__blade）禁亮标记的兜底清理，只在 fengsui 包内注册。
--
-- 官方 blade.lua 把清理挂在装备技能自身的 fk.CardUseFinished refresh：
-- 若【杀】结算途中青龙刀被拆或替换，技能先被卸掉，这条 refresh 不再执行，
-- 目标身上的 @@sa__blade 与 MarkEnum.RevealProhibited 里的 "m"/"d"
-- 就会永久残留，导致该角色再也不能明置武将牌。
--
-- 这里用一条不依赖任何武将/装备的全局 late_refresh 兜底：官方 refresh
-- 正常执行过就把 @@sa__blade 减到 0，本技能直接跳过；没执行过则按
-- extra_data 里记的次数补清。建安写在同一个无后缀 mark 里的那一项
-- 由 fengsui_jianan_reveal 记录，清完补回，避免两处效果互相误伤。

local bladeCleanup = fk.CreateSkill {
  name = "#fengsui_blade_cleanup",
  mute = true,
  no_indicate = true,
}

bladeCleanup:addEffect(fk.CardUseFinished, {
  global = true,
  late_refresh = true,
  can_refresh = function(self, event, target, player, data)
    return data and data.extra_data and
      data.extra_data.sa__bladeRevealProhibited ~= nil
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local extra = data.extra_data
    local record = extra.sa__bladeRevealProhibited
    -- 一次使用结算只处理一次；全局 refresh 会对每名角色各调用一遍。
    extra.sa__bladeRevealProhibited = nil
    -- 官方 refresh 里误写成 data.sa__bladeRevealProhibited = nil，一并清掉。
    data.sa__bladeRevealProhibited = nil

    for key, num in pairs(record) do
      local p = room:getPlayerById(tonumber(key))
      if p then
        local left = p:getMark("@@sa__blade")
        if left > 0 then
          local n = math.min(tonumber(num) or 0, left)
          local rec = p:getTableMark(MarkEnum.RevealProhibited)
          for _ = 1, n do
            table.removeOne(rec, "m")
            table.removeOne(rec, "d")
          end
          local flag = p:getMark("fengsui_jianan_reveal")
          if type(flag) == "string" and (flag == "m" or flag == "d")
              and not table.contains(rec, flag) then
            table.insert(rec, flag)
          end
          room:setPlayerMark(p, MarkEnum.RevealProhibited, #rec == 0 and 0 or rec)
          room:setPlayerMark(p, "@@sa__blade", math.max(0, left - n))
        end
      end
    end
  end,
})

return bladeCleanup
