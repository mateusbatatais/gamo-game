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

## Filosofia técnica
- **Sem assets autorais externos**: sprites em ASCII art + paleta convertidos em ImageTexture em runtime. SFX gerados sfxr-style em código.
- **Tipagem forte** em GDScript (`func foo(x: int) -> bool:`).
- **Sem `any`/Variant** quando há alternativa.
- **Comentários em português, código em inglês** (mesmo padrão do monorepo Gamo).
- **Entidades em código puro**: `Player`, `Enemy`, `Projectile`, `XpGem` não têm `.tscn` próprio — toda hierarquia em `_ready()`. Top-level scenes (menu, arena, game_over) têm `.tscn` mínimo apontando pro script.
