// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import Qt5Compat.GraphicalEffects
import Fk
import Fk.Components.Common
import LunarLtk

Item {
  id: root
  property var model
  property var choices: model ? model.choices : []
  property var all_choices: model ? model.all_choices : []
  property string default_choice: model ? model.default_choice : ""
  property string answer: default_choice
  property string currentUIPackage: {
    const ui = (Config.enabledUIPackages && Config.enabledUIPackages["lunarltk"])
      ? Config.enabledUIPackages["lunarltk"]
      : "default";
    if (ui !== "default" && ui !== "lunarltk-qsgs-ui") return "default";
    return ui;
  }
  property bool sunGodAvailable: Fs.exists(
    Cpp.path + "/packages/lunarltk-qsgs-ui/image/selfArea/interaction.png"
  )
  property bool useSunGodUI: currentUIPackage === "lunarltk-qsgs-ui" && sunGodAvailable

  width: useSunGodUI ? qsgsButton.width : defaultButton.width
  height: useSunGodUI ? qsgsButton.height : defaultButton.height

  readonly property string displayText: {
    if (!answer || answer === default_choice) {
      return qsTr("\u8BF7\u9009\u62E9");
    }
    const data = Ltk.getGeneralData(answer);
    if (!data || !data.kingdom) {
      return Ltk.processPrompt(answer);
    }
    return `${Lua.tr(data.kingdom)}|${Lua.tr(answer)}`;
  }

  onAnswerChanged: {
    if (!answer) return;
    Lua.updateRequestUI("Interaction", "1", "update", answer);
  }

  function clicked() {
    if (choices.length === 0) return;
    const component = Qt.createComponent(
      Cpp.path +
      "/packages/fengsui/pkg/fengsui_effect/qml/GzygSoulBox.qml"
    );
    const scene = Ltk.roomScene;
    scene.showPopup(component, {
      cards: all_choices,
      availableCards: choices,
      result: answer,
    });
    scene.popupItem.accepted.connect(() => {
      answer = scene.popupItem.result;
      scene.popupItem.finished();
    });
  }


  MetroButton {
    id: defaultButton
    visible: !root.useSunGodUI
    text: root.displayText

    onClicked: {
      root.clicked();
    }
  }

  Item {
    id: qsgsButton
    visible: root.useSunGodUI
    width: img.width
    height: 30

    BorderImage {
      id: img
      height: qsgsButton.height
      width: Math.max(imgText.width + 50, 83)
      border.left: 27
      border.top: 0
      border.right: 27
      border.bottom: 0
      source: Cpp.path + "/packages/lunarltk-qsgs-ui/image/selfArea/interaction.png"
    }

    Glow {
      source: imgText
      anchors.fill: imgText
      color: "#000000"
      spread: 0.9
      radius: 1.5
    }

    Text {
      id: imgText
      anchors.horizontalCenter: img.horizontalCenter
      anchors.verticalCenter: img.verticalCenter
      font.family: "SimSun"
      font.pixelSize: 14
      color: "white"
      height: contentHeight
      width: contentWidth
      text: {
        const prompt = root.displayText;
        return prompt.length > 7 ? (prompt.substring(0, 7) + "...") : prompt;
      }
    }

    MouseArea {
      anchors.fill: parent
      onPressed: {
        root.clicked();
      }
    }
  }
}
