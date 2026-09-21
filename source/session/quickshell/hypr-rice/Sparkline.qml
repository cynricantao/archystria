import QtQuick

Item {
    id: root

    property var values: []
    property color strokeColor: Theme.primary
    property color fillColor: Qt.rgba(strokeColor.r, strokeColor.g, strokeColor.b, 0.10)
    property real maximum: 100
    property real lineWidth: 1.7

    implicitHeight: 42

    onValuesChanged: graph.requestPaint()
    onWidthChanged: graph.requestPaint()
    onHeightChanged: graph.requestPaint()

    Canvas {
        id: graph
        anchors.fill: parent
        renderTarget: Canvas.FramebufferObject
        antialiasing: true

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const points = root.values || [];
            if (points.length < 2 || width <= 1 || height <= 1)
                return;
            const step = width / Math.max(1, points.length - 1);
            const y = value => height - Math.max(0, Math.min(root.maximum, Number(value) || 0)) / root.maximum * (height - 3) - 1.5;
            ctx.beginPath();
            ctx.moveTo(0, y(points[0]));
            for (let i = 1; i < points.length; i++)
                ctx.lineTo(i * step, y(points[i]));
            ctx.lineTo(width, height);
            ctx.lineTo(0, height);
            ctx.closePath();
            ctx.fillStyle = root.fillColor;
            ctx.fill();
            ctx.beginPath();
            ctx.moveTo(0, y(points[0]));
            for (let i = 1; i < points.length; i++)
                ctx.lineTo(i * step, y(points[i]));
            ctx.strokeStyle = root.strokeColor;
            ctx.lineWidth = root.lineWidth;
            ctx.lineJoin = "round";
            ctx.lineCap = "round";
            ctx.stroke();
        }
    }
}
