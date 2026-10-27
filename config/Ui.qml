pragma Singleton
import QtQuick
import Quickshell

// Estado da interface compartilhado entre as paginas.
Singleton {
    property int page: 0

    // Posicoes da barra; cada uma tem os seus estilos (variacoes)
    readonly property var barPositions: [
        {
            "id": "top",
            "name": "Em cima",
            "description": "Barra no topo da tela",
            "preview": "floating"
        },
        {
            "id": "bottom",
            "name": "Embaixo",
            "description": "Doca pequena e centralizada",
            "preview": "bottom"
        },
        {
            "id": "side",
            "name": "Lateral",
            "description": "Barra vertical do lado esquerdo",
            "preview": "side"
        }
    ]

    // Estilos de barra. id e o que fica salvo no preset ("bar").
    readonly property var barStyles: [
        {
            "id": "floating",
            "position": "top",
            "name": "Flutuante",
            "fullName": "Flutuante",
            "description": "Barra inteira com cantos arredondados e margem da borda"
        },
        {
            "id": "island",
            "position": "top",
            "name": "Ilhas",
            "fullName": "Ilhas",
            "description": "Módulos separados em pílulas: esquerda, centro e direita"
        },
        {
            "id": "minimal",
            "position": "top",
            "name": "Minimalista",
            "fullName": "Minimalista",
            "description": "Barra fina colada na borda, só o essencial"
        },
        {
            "id": "tonal",
            "position": "top",
            "name": "Tonal",
            "fullName": "Tonal",
            "description": "Ilhas tingidas com a cor do tema e área ativa em florzinha"
        },
        {
            "id": "bottom",
            "position": "bottom",
            "name": "Doca",
            "fullName": "Doca",
            "description": "Pequena e centralizada na parte de baixo da tela"
        },
        {
            "id": "bottom-tonal",
            "position": "bottom",
            "name": "Doca tonal",
            "fullName": "Doca tonal",
            "description": "A doca tingida com a cor do tema e área ativa em florzinha"
        },
        {
            "id": "side",
            "position": "side",
            "name": "Inteira",
            "fullName": "Lateral",
            "description": "Uma barra só, de cima a baixo, com cantos arredondados"
        },
        {
            "id": "side-island",
            "position": "side",
            "name": "Ilhas",
            "fullName": "Lateral em ilhas",
            "description": "Três pílulas separadas: em cima, no meio e embaixo"
        },
        {
            "id": "side-minimal",
            "position": "side",
            "name": "Minimalista",
            "fullName": "Lateral minimalista",
            "description": "Fina e colada na borda, só workspaces, relógio e bandeja"
        },
        {
            "id": "side-tonal",
            "position": "side",
            "name": "Tonal",
            "fullName": "Lateral tonal",
            "description": "Ilhas tingidas com a cor do tema e área ativa em florzinha"
        }
    ]

    function barStyle(id) {
        return barStyles.find(b => b.id === id) ?? null;
    }

    // Tamanho da tela real: as posicoes dos widgets sao relativas a ela
    readonly property var screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    readonly property real screenWidth: screen ? screen.width : 1920
    readonly property real screenHeight: screen ? screen.height : 1080

    // Tipos de widget. w/h = tamanho em pixels na tela real.
    readonly property var widgetTypes: [
        {
            "id": "clock",
            "name": "Relógio",
            "description": "Hora grande e data",
            "icon": Icons.clock,
            "w": 340,
            "h": 170
        },
        {
            "id": "calendar",
            "name": "Calendário",
            "description": "Mês atual com o dia de hoje",
            "icon": Icons.calendar,
            "w": 330,
            "h": 330
        },
        {
            "id": "media",
            "name": "Música",
            "description": "Spotify e outros players (MPRIS)",
            "icon": Icons.music,
            "w": 460,
            "h": 160
        },
        {
            "id": "weather",
            "name": "Clima",
            "description": "Temperatura e condição do tempo",
            "icon": Icons.cloud,
            "w": 380,
            "h": 160
        },
        {
            "id": "system",
            "name": "Sistema",
            "description": "Uso de CPU, RAM e disco",
            "icon": Icons.chip,
            "w": 420,
            "h": 140
        },
        {
            "id": "mediaFlower",
            "name": "Música · Flor",
            "description": "Capa redonda e play em florzinha",
            "icon": Icons.music,
            "w": 440,
            "h": 150
        },
        {
            "id": "clockStacked",
            "name": "Relógio grande",
            "description": "Hora e minuto empilhados, sem fundo",
            "icon": Icons.clock,
            "w": 250,
            "h": 300,
            "bg": 0
        },
        {
            "id": "statTiles",
            "name": "Sistema · Blocos",
            "description": "CPU, RAM e disco em blocos separados",
            "icon": Icons.memory,
            "w": 420,
            "h": 140
        },
        {
            "id": "weekStrip",
            "name": "Semana",
            "description": "Calendário só da semana atual",
            "icon": Icons.calendar,
            "w": 360,
            "h": 130
        },
        {
            "id": "profile",
            "name": "Perfil",
            "description": "Sua foto, tempo ligado e atalhos",
            "icon": Icons.person2,
            "w": 330,
            "h": 190
        },
        {
            "id": "weatherFlower",
            "name": "Clima · Flor",
            "description": "Temperatura com ícone em florzinha",
            "icon": Icons.cloud,
            "w": 360,
            "h": 130
        }
    ]

    // Fundo padrao de um tipo de widget (alguns, como o relogio grande, nao tem fundo)
    function defaultBg(type) {
        const t = widgetType(type);
        return t && t.bg !== undefined ? t.bg : 0.89;
    }

    function widgetType(id) {
        return widgetTypes.find(t => t.id === id) ?? null;
    }

    readonly property var accents: ["#7fd1c4", "#8ec5ff", "#a7b0ff", "#c9a7ff", "#f4a7c0", "#ffb38a", "#f6d58b", "#a8e6a1"]

    signal toast(string message)

    // Pedido aberto do seletor de cor: { title, color, callback } (ou null)
    property var colorRequest: null

    // Abre o seletor de cor livre; callback(hex) e chamado ao confirmar
    function pickColor(title, initial, callback) {
        colorRequest = {
            "title": title,
            "color": initial,
            "callback": callback
        };
    }

    function notify(message) {
        toast(message);
    }

    function barName(id) {
        const s = barStyle(id);
        return s ? s.fullName : id;
    }
}
