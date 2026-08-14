local M = {}

local interactionPath = "packages/fengsui/pkg/fengsui_effect/qml/FengsuiCardNameInteraction.qml"

function M.create(skillName, choices, allChoices)
  if type(choices) ~= "table" or #choices == 0 then return end

  return {
    type = "custom",
    default = choices[1],
    qml = {
      url = interactionPath,
      prop = {
        skill = skillName,
        choices = choices,
        allChoices = allChoices or choices,
        defaultChoice = choices[1],
      },
    },
  }
end

return M
