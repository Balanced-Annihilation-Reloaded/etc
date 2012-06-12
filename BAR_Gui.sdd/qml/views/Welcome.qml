import Qt 4.7

MainView {
	id: welcomeView

	Rectangle {
		color: "white"
		opacity: 0.9
		width: parent.width - 10
		height: welcomeText.height + 10
		radius: 5
		DText {
			id: welcomeText
			font.pointSize: 14
			width: parent.width - 16
			wrapMode: "WordWrap"
			anchors.centerIn: parent
			text: "long intro text again"
		}
	}

	state: "Onscreen"
}
