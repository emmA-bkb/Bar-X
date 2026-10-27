pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// Current music player. Prefers Spotify; otherwise uses the first open MPRIS player.
Singleton {
    id: root

    readonly property var player: {
        const ps = Mpris.players.values;
        return ps.find(p => (p.identity ?? "").toLowerCase().includes("spotify")) ?? ps[0] ?? null;
    }
    readonly property bool hasTrack: player !== null && (player.trackTitle ?? "") !== ""
    readonly property bool playing: player !== null && player.isPlaying
    readonly property string title: hasTrack ? player.trackTitle : "Nothing playing"
    readonly property string artist: hasTrack ? (player.trackArtist || player.identity) : "Open Spotify"
    readonly property string art: hasTrack ? (player.trackArtUrl ?? "") : ""
    readonly property real progress: player && player.length > 0 ? Math.min(1, player.position / player.length) : 0

    function toggle() {
        if (player && player.canTogglePlaying)
            player.togglePlaying();
    }
    function next() {
        if (player && player.canGoNext)
            player.next();
    }
    function previous() {
        if (player && player.canGoPrevious)
            player.previous();
    }

    // The MPRIS position doesn't update by itself
    Timer {
        interval: 1000
        repeat: true
        running: root.playing
        onTriggered: root.player.positionChanged()
    }
}
