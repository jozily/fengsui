import QtQuick

Item {
  id: root
  anchors.fill: parent
  property string imageRoot: "../image/Effect/bankingdoms/"
  property int targetFrame: 3

  Rectangle {
    anchors.fill: parent
    color: "black"
    opacity: 0.55
  }

  Image {
    id: kingdom
    anchors.centerIn: parent
    scale: 1.2
    source: imageRoot + "kingdoms" + frame + ".png"
    property int frame: 0
  }

  Image {
    id: lock
    anchors.centerIn: parent
    scale: 0.8
    z: 1
    opacity: 0
    source: imageRoot + "jiasuo" + frame + ".png"
    property int frame: 0
  }

  SequentialAnimation {
    running: true
    PropertyAnimation {
      target: kingdom
      property: "frame"
      from: 0
      to: 5
      duration: 700
      loops: 3
    }
    PropertyAnimation {
      target: kingdom
      property: "frame"
      from: 0
      to: root.targetFrame
      duration: 500
    }
    ScriptAction { script: lock.opacity = 1 }
    PropertyAnimation {
      target: lock
      property: "frame"
      from: 0
      to: 60
      duration: 2100
    }
    PropertyAnimation {
      target: root
      property: "opacity"
      to: 0
      duration: 80
    }
    ScriptAction { script: roomScene.bigAnim.source = "" }
  }
}
