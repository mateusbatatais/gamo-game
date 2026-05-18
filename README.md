# 🎮 Cartridge Crusade — v0 (arquivado)

> ⚠️ **Status: ARCHIVED como v0**. Este foi o primeiro experimento — bullet heaven roguelite estilo Vampire Survivors. Funcional até v0.5 mas o estilo bullet-heaven com cartuchos como personagens ficou genérico demais. Decidimos pivotar pra um sidescroll com mascote robô em **[../gamo-mascot/](../gamo-mascot/)**.
>
> Este diretório é mantido como referência arquivada — não receberá mais features. Pode ser deletado quando quiser.

---

**Status histórico**: v0.5 — bullet heaven funcional com 2 Eras, 4 Spirits, 12 cartuchos, 5 evoluções, 2 bosses.
**Design completo**: [DESIGN.md](./DESIGN.md) — GDD do projeto.
**Plano de versões**: [ROADMAP.md](./ROADMAP.md).
**Histórico**: [CHANGELOG.md](./CHANGELOG.md).

---

## Stack
- **Engine**: Godot 4.3 (GDScript)
- **Renderer**: GL Compatibility (suporta hardware antigo)
- **Target**: Windows, macOS, Linux → Steam
- **Resolução**: 320×180 nativa, scaled para qualquer monitor

## Como rodar

1. Baixe o [Godot 4.3](https://godotengine.org/download) (standard, não .NET)
2. No editor, **Import** → selecione `project.godot`
3. Pressione **F5** (ou Play). Pode pedir uma main scene → `scenes/main_menu.tscn` já está configurada
4. Controles:
   - **WASD/Setas/Stick** — mover
   - **Espaço/A (gamepad)** — dash (cooldown 4s)
   - **Mouse/Setas+Enter ou 1/2/3** — escolher cartucho no level-up

## Estrutura
```
gamo-game/
├── DESIGN.md / ROADMAP.md / CHANGELOG.md
├── project.godot       # Configuração + autoloads + input map
├── scenes/             # Top-level .tscn: main_menu, arena, game_over
├── scripts/
│   ├── autoload/       # Singletons (EventBus, GameState, Sprites, etc.)
│   ├── entities/       # Player, Enemy, Projectile, XpGem
│   │   └── enemies/    # Artifact, Tear, NullSprite
│   ├── cartridges/     # 5 cartuchos do MVP
│   ├── systems/        # EnemySpawner
│   ├── ui/             # HUD, LevelUpModal
│   ├── scenes/         # Scripts das cenas top-level
│   └── util/           # PixelArt (gerador procedural)
└── export/             # Builds (gitignored)
```

## Export Web (HTML5)

Pra jogar no navegador:

1. **Editor → Project → Export**
2. O preset **"Web"** já está configurado em `export_presets.cfg`
3. Primeiro uso: clique em **"Manage Export Templates"** e baixe os templates web (`~50MB`)
4. Botão **"Export Project"** → escolhe destino (default: `build/web/index.html`)

Resultado: 4 arquivos em `build/web/`:
- `index.html` — usa o shell custom em [web/shell.html](./web/shell.html) com loading bar pixel-art
- `index.js` + `index.wasm` — engine Godot compilado para web
- `index.pck` — assets do jogo

Pra testar local: `python -m http.server 8000` dentro de `build/web/` e abrir `http://localhost:8000`. Servir via `file://` não funciona por causa de CORS.

Pra deploy: hospedar a pasta `build/web/` em qualquer static host (GitHub Pages, Netlify, Cloudflare Pages, gamo.games). Configurar os MIME types corretos pro `.wasm` (`application/wasm`) — a maioria dos hosts já cuida disso.

**Loading bar customizado**: o shell `web/shell.html` mostra título "CARTRIDGE CRUSADE" estilizado + barra de progresso chunky enquanto o engine + .pck baixam, e desaparece com fade quando o jogo está pronto. Reporte de progresso vem do callback `onProgress` do Godot engine.

## Filosofia técnica
- **Sem assets autorais externos**: sprites em ASCII art + paleta convertidos em ImageTexture em runtime. SFX gerados sfxr-style em código.
- **Tipagem forte** em GDScript (`func foo(x: int) -> bool:`).
- **Sem `any`/Variant** quando há alternativa.
- **Comentários em português, código em inglês** (mesmo padrão do monorepo Gamo).
- **Entidades em código puro**: `Player`, `Enemy`, `Projectile`, `XpGem` não têm `.tscn` próprio — toda hierarquia em `_ready()`. Top-level scenes (menu, arena, game_over) têm `.tscn` mínimo apontando pro script.
