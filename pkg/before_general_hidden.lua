-- 「即将暗置武将牌」时机。
--
-- 引擎只提供 fk.GeneralHidden：它由 ServerPlayer:hideGeneral 在整段暗置流程
-- 走完之后才触发（写 __heg_general/__heg_deputy、换成 anjiang、剥技能、重算
-- 性别、发日志都在它之前）。技能若挂在这个时机上再把人明置回来，暗置的
-- 副作用已经全部发生过一遍，等于空转。
--
-- 这里补一个 fk.BeforeGeneralHidden：包装 ServerPlayer.hideGeneral，在原函数
-- 之前触发，data = { is_deputy = boolean, prevented = boolean }。技能在 on_use
-- 里把 data.prevented 置 true 即可取消这次暗置（本文件不主动取消任何东西，
-- 默认暗置照常发生）。
--
-- 加载分两步：
--   1. 事件类必须在包加载前注册，技能 addEffect 时会引用到它；
--   2. 方法包装必须等 ServerPlayer 全局就绪，由 lua/server/scheduler.lua
--      在赋值后 pcall 调用 installPatch。
-- 两步都做成幂等，客户端（没有 ServerPlayer）只走第一步。

local M = {}

--- 注册事件类；TriggerEvent 尚不可用时返回 nil，调用方可重试。
function M.installEvent()
  if not fk.BeforeGeneralHidden and TriggerEvent then
    fk.BeforeGeneralHidden = TriggerEvent:subclass("fk.BeforeGeneralHidden")
  end
  return fk.BeforeGeneralHidden
end

--- 包装 ServerPlayer.hideGeneral；没有 ServerPlayer 时只保证事件类存在。
function M.installPatch()
  M.installEvent()
  if not ServerPlayer or not fk.BeforeGeneralHidden then
    return false
  end
  if ServerPlayer.__fengsui_before_hidden_patched then return true end

  local original = ServerPlayer.hideGeneral
  if type(original) ~= "function" then return false end

  ServerPlayer.hideGeneral = function(self, isDeputy)
    local room = self.room
    -- 不在对局中（房间搭建、测试 mock）时没有 logic，直接走原逻辑。
    if room and room.logic and not self.dead then
      local data = { is_deputy = isDeputy, prevented = false }
      room.logic:trigger(fk.BeforeGeneralHidden, self, data)
      if data.prevented then return false end
    end
    return original(self, isDeputy)
  end

  ServerPlayer.__fengsui_before_hidden_patched = true
  return true
end

M.installEvent()

return M
