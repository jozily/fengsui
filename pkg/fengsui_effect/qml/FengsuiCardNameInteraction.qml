// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import Qt5Compat.GraphicalEffects
import Fk
import Fk.Components.Common
import LunarLtk

Item {
  id: root

  property string skill: ""
  property var choices: []
  property var allChoices: []
  property string defaultChoice: ""
  property string answer: defaultChoice

  property string currentUIPackage: {
    const ui = (Config.enabledUIPackages && Config.enabledUIPackages["lunarltk"])
      ? Config.enabledUIPackages["lunarltk"]
      : "default";
    if (ui !== "default" && ui !== "lunarltk-qsgs-ui") return "default";
    return ui;
  }
  property bool qsgsStyleAvailable: Fs.exists(
    Cpp.path + "/packages/lunarltk-qsgs-ui/image/selfArea/interaction.png"
  )
  property bool useQsgsStyle: currentUIPackage === "lunarltk-qsgs-ui" && qsgsStyleAvailable

  width: useQsgsStyle ? qsgsButton.width : defaultButton.width
  height: useQsgsStyle ? qsgsButton.height : defaultButton.height

  onAnswerChanged: {
    if (answer)
      Lua.updateRequestUI("Interaction", "1", "update", answer);
  }

  function clicked() {
    if (choices.length === 0) return;

    const component = Qt.createComponent(
      Cpp.path + "/packages/fengsui/pkg/fengsui_effect/qml/FengsuiCardNameBox.qml"
    );
    const scene = Ltk.roomScene;
    scene.showPopup(component, {
      choices,
      allChoices,
      prompt: skill,
      result: answer,
    });

    const box = scene.popupItem;
    box.accepted.connect(() => {
      if (box.result)
        answer = box.result;
      box.finished();
    });
  }

  MetroButton {
    id: defaultButton
    visible: !root.useQsgsStyle
    text: root.answer ? Ltk.processPrompt(root.answer) : qsTr("\u8bf7\u9009\u62e9")
    onClicked: root.clicked()
  }

  Item {
    id: qsgsButton
    visible: root.useQsgsStyle
    width: Math.max(buttonText.implicitWidth + 50, 83)
    height: 30

    BorderImage {
      anchors.fill: parent
      border.left: 27
      border.right: 27
      source: Cpp.path + "/packages/lunarltk-qsgs-ui/image/selfArea/interaction.png"
    }

    Glow {
      anchors.fill: buttonText
      source: buttonText
      color: "#000000"
      spread: 0.9
      radius: 1.5
    }

    Text {
      id: buttonText
      anchors.centerIn: parent
      text: root.answer ? Ltk.processPrompt(root.answer) : qsTr("\u8bf7\u9009\u62e9")
      color: "white"
      font.family: "SimSun"
      font.pixelSize: 14
    }

    TapHandler {
      gesturePolicy: TapHandler.WithinBounds
      onTapped: root.clicked()
    }
  }
}
