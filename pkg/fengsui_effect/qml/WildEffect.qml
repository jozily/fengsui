import QtQuick

Item {
  id: root
  // 野心家特效.BB
  //property int sceneHeight: 720
  //property int sceneWidth: 1280
  property string img: "../image/WildEffect/"
  //素材文件夹

  anchors.fill: parent
  scale: 0.9

  Image {
    id: bg
    anchors.centerIn: parent
    //width: 1600
    //height: 900
    //fillMode: Image.PreserveAspectFit
    scale: 0.9
    source: img + "WildEffect" + curr + ".png"
    property int curr: 0
    opacity: 1
  }

  //静态
  ParallelAnimation {
    id: step1
    running: true
    // bg
    //动画
    SequentialAnimation {
          PauseAnimation { duration: 50 }
          ScriptAction { script: bg.opacity = 1; }
          PropertyAnimation {
            target: bg
            property: "curr"
            to: 68
            duration: 3800
          }
        }
    onFinished: {
      anim2.start();
    }
  }

  PropertyAnimation {
     id: anim2
     target: root
     property: "opacity"
     to: 0
     duration: 560
     onFinished: {
       roomScene.bigAnim.source = "";
     }
   }
}
