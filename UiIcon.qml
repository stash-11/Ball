import QtQuick
Image {
    id: root
    property string name: "music"
    property color tint: "#edf0ed"
    width: 22; height: 22
    sourceSize.width: width * 2; sourceSize.height: height * 2
    readonly property var paths: ({
        music: '<path d="M9 18V5l12-2v13M9 9l12-2"/><ellipse cx="6" cy="18" rx="3" ry="3"/><ellipse cx="18" cy="16" rx="3" ry="3"/>',
        youtube: '<rect x="2" y="5" width="20" height="14" rx="5"/><path d="m10 9 5 3-5 3z"/>',
        play: '<path d="m8 5 11 7-11 7z"/>',
        pause: '<path d="M8 5v14M16 5v14"/>',
        previous: '<path d="M5 5v14m14-14L8 12l11 7z"/>',
        next: '<path d="M19 5v14M5 5l11 7-11 7z"/>',
        download: '<path d="M12 3v12m-5-5 5 5 5-5M4 16v5h16v-5"/>',
        folder: '<path d="M3 7V5h7l2 3h9v12H3z"/>',
        drop: '<path d="M12 3v11m-4-4 4 4 4-4M5 17h14v4H5z"/>',
        chevron: '<path d="m7 10 5 5 5-5"/>'
    })
    source: "data:image/svg+xml;utf8," + encodeURIComponent('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="' + tint + '" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">' + (paths[name] || paths.music) + '</svg>')
}
