-- 群雄割据 1/3 判定的 ServerPlayer.revealGeneral 兜底包装。
-- 必须在 ServerPlayer 全局存在之后加载（由 lua/server/scheduler.lua 在
-- ServerPlayer 赋值后 pcall require 本文件）；包加载阶段 ServerPlayer 尚为 nil。
-- 判定本体在 _fengsui_neutral_rule.lua 导出的 neutralRule.warlordsJudge。
-- 游戏内 io.open 为只读沙箱，调试日志走 Qt 日志（写入 freekill.server.log）。
local function dbgLog(...)
  fk.qWarning("[fengsui-patch] " .. table.concat({ ... }, " "))
end

if not ServerPlayer then
  dbgLog("ServerPlayer is nil, patch aborted")
  return
end
if ServerPlayer.__fengsui_warlords_patched then
  dbgLog("already patched, skip")
  return
end

local ok, neutralRule = pcall(require,
  "packages.fengsui.pkg.fengsui_liwu.skills._fengsui_neutral_rule")
if not ok or type(neutralRule) ~= "table" or not neutralRule.warlordsJudge then
  dbgLog("require neutral_rule failed:", tostring(ok), type(neutralRule))
  return
end

local originalRevealGeneral = ServerPlayer.revealGeneral
ServerPlayer.revealGeneral = function(self, isDeputy, no_trigger)
  dbgLog("revealGeneral enter, player=", self and self.id or "?",
    "deputy=", tostring(isDeputy), "no_trigger=", tostring(no_trigger),
    "general=", tostring(self and self.general),
    "deputyGeneral=", tostring(self and self.deputyGeneral))
  originalRevealGeneral(self, isDeputy, no_trigger)
  local okJudge, err = pcall(neutralRule.warlordsJudge, self)
  dbgLog("warlordsJudge done, ok=", tostring(okJudge), err or "")
end
ServerPlayer.__fengsui_warlords_patched = true
dbgLog("patch installed on ServerPlayer.revealGeneral")
