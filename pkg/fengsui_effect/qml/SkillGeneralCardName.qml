// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import Fk
import Fk.Components.Common

MetroButton {
  id: root
  property string skill
  property var extra_data
  property var choices : (extra_data !== undefined) ? extra_data.choices : []
  property var all_choices : (extra_data !== undefined) ? extra_data.all_choices : []
  property string default_choice : (extra_data !== undefined) ? extra_data.default_choice : ""
  property string answer: default_choice

  readonly property var roomScene: Ltk.roomScene

  text: Util.processPrompt(answer)

  onAnswerChanged: {
    if (!answer) return;
    Lua.call("UpdateRequestUI", "Interaction", "1", "update", answer);
    // Lua.call("SetInteractionDataOfSkill", skill, JSON.stringify(answer));
    // roomScene.dashboard.startPending(skill);
    if (answer == default_choice) return;
    roomScene.startCheat("ChooseHandcard");
  }

  onClicked: {
    answer = default_choice;
    // roomScene.popupBox.sourceComponent =
      // Qt.createComponent(AppPath + "/packages/fengsui/pkg/fengsui_effect/qml/ChooseGeneralsBox.qml");
    roomScene.popupBox.sourceComponent = Qt.createComponent("./ChooseGeneralsBox.qml");

    const box = roomScene.popupBox.item;
    box.cards = all_choices;
    box.available_cards = choices;
    box.prompt = skill;
    box.accepted.connect(() => {
      answer = box.result;
    });
  }

}
