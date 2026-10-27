pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// Player de musica atual. Prefere o Spotify; senao usa o primeiro player MPRIS aberto.
Singleton {
    id: root

    readonly property var player: {
        const ps = Mpris.players.values;
        return ps.find(p => (p.identity ?? "").toLowerCase().includes("spotify")) ?? ps[0] ?? null;
    }
    readonly property bool hasTrack: player !== null && (player.trackTitle ?? "") !== ""
    readonly property bool playing: player !== null && player.isPlaying
    readonly property string title: hasTrack ? player.trackTitle : "Nada tocando"
    readonly property string artist: hasTrack ? (player.trackArtist || player.identity) : "Abra o Spotify"
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

    // A posicao do MPRIS nao atualiza sozinha
    Timer {
        interval: 1000
        repeat: true
        running: root.playing
        onTriggered: root.player.positionChanged()
    }
}
