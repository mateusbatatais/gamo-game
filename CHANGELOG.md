# Changelog — Cartridge Crusade

Todo o conteúdo notável vai aqui, em ordem cronológica reversa.

---

## [0.5.0] — 2026-05-15 — Polish, i18n, Spirits autorais, Rebind

Sessão de polish: arte por personagem, traducao, controles configuráveis, mais sinergias.

### Adicionado
- **Sprites autorais por Spirit**: Slate (12×10 chunky portable com tela LCD), Disc (10×10 circular CD-style), Handheld (8×12 slim vertical). `SpiritDef.sprite_frames` aponta pra ASCII art específica.
- **Sistema i18n** ([i18n.gd](gamo-game/scripts/autoload/i18n.gd)) — dicionário in-memory com PT-BR e EN. ~60 chaves cobrindo menus, hub, options, game over, HUD e level-up.
- **Seletor de idioma** na tela de Opções com troca em tempo real.
- **Rebind de controles** na tela de Opções — clica no botão da action, pressiona a tecla, novo binding persiste em `user://settings.cfg`. Funciona pra todas as 5 actions (move_up/down/left/right + dash).
- **2 novas sinergias**:
  - **Sonic Boom** (Stereo Sound + Power Glove) — 4 projéteis paralelos com piercing e dano alto
  - **Vortex Field** (Mode 7 Spin + Pixel Aura) — 5+ orbitais cyan + pulsos radiais em espiral
- `Settings.set_keybind/set_locale` + serialização InputEvent → Dictionary pra persistência

### Modificado
- `SpiritDef` ganha campo `sprite_frames` (Array). Player usa pra renderizar.
- `Hub` agora exibe a arte correta de cada Spirit nos cards (não mais reuso de PIXEL_IDLE).
- `Options` reorganizado em 2 colunas: esquerda audio/video/a11y/idioma; direita controles.
- `MainMenu`, `Hub`, `Options`, `GameOver`, `HUD`, `LevelUpModal`: literais substituídos por `I18n.t()` / `I18n.tf()`.
- Reward de boss em GameOver agora pega o nome do cartucho dinamicamente do CartridgeRegistry.

### Notas técnicas
- I18n carrega antes de Settings na ordem de autoload — Settings.apply_all() chama I18n.set_locale com o valor persistido.
- Trocar idioma recarrega a scene Options pra refletir os textos novos. (Outras cenas exigem voltar e reentrar — limitação aceitável pra escopo de v0.5.)
- Rebind preserva outros bindings da mesma action (ex: gamepad fica intacto quando você re-mapeia o teclado).

### Pendente
- Daltonismo modes (3 tipos: protan/deuteran/tritan)
- Tradução das descrições de cartuchos/spirits/eras (apenas UI principal foi traduzida)
- Daily seed run, modificadores de challenge
- Atualizar textos das cenas em tempo real quando idioma muda (sem reload)

---

## [0.4.0] — 2026-05-15 — Era 16-bit

Sistema de Eras, nova era jogável, novo boss, mais conteúdo.

### Adicionado
- **EraRegistry** autoload com sistema completo de Eras (definições, paletas, pool de inimigos, boss)
- **GameState.selected_era_id** + **bosses_defeated** + `register_boss_defeat()`
- **Era 16-bit jogável** — desbloqueada após vencer Corruption v1.0:
  - Paleta de fundo azul/roxo profundo + estrelas piscantes parallax-style
  - Gradient vertical no background (era 8-bit fica chapado)
- **Seleção de Era no Hub** — botões compactos no topo, com tooltip de desbloqueio
- **4 inimigos 16-bit**:
  - **HueShift** — cicla por 5 cores (cyan/magenta/yellow/orange/green) a cada 0.4s
  - **Compression** — bloco JPG que teleporta a cada 2.5s para perto do player
  - **Sprite Limit** — divide em cópias menores (até 2 gerações) ao tomar dano (40% chance)
  - **Bit Flip** — alterna estados ON/OFF a cada 1.5s; invulnerável no OFF mas anda 1.6× mais rápido
- **Boss "Fragmentation"** (Era 16-bit, HP 1200):
  - 4 fases (Whole/Cracked/Shattered/Final) — Final = invulnerável, divide em 4 Fragments
  - 3 padrões de ataque: **Frag Burst** (12 projéteis circulares), **Crossfire** (4 cardeais com piercing), **Phase Dash** (teleport + lunge)
  - `FragmentationFragment` — entidade filha, 80 HP cada, persegue player; todos devem morrer pra boss morrer de verdade
- **3 novos cartuchos 16-bit**:
  - **Stereo Sound** (Raro) — 2 projéteis paralelos com offset lateral
  - **Mode 7 Spin** (Especial) — projéteis em espiral 360° ao redor do player
  - **Region Free** (Lendário, drop do Fragmentation) — projéteis que aceleram em voo + piercing
- **AcceleratingProjectile** — estende Projectile, override de `_physics_process` que rampa speed do inicial ao alvo

### Modificado
- `EnemySpawner` agora lê pool de inimigos da Era selecionada (não mais hardcoded). Spawn entries usam string IDs.
- `ArenaBackground` parametrizado por Era (paleta + decorações).
- HUD pega nome do boss dinamicamente da Era em vez de hardcoded "CORRUPTION v1.0".
- Arena spawna o boss certo (CorruptionV1 ou Fragmentation) baseado em `era.boss_class_name`.
- Reward de boss agora é por era: 8-bit = Reset Button, 16-bit = Region Free.

### Pendente
- ASCII art autoral por Spirit (atualmente todos reusam PIXEL_IDLE)
- Mais sinergias evolutivas envolvendo cartuchos 16-bit
- v0.5: rebind de controles, i18n (PT-BR + EN), daltonismo

---

## [0.3.0] — 2026-05-15 — Sinergias, Spirits, Hub, Opções

Profundidade no loop e estrutura pra v0.4 (Era 16-bit).

### Adicionado
- **Sinergias evolutivas** — 3 evoluções de cartuchos:
  - **Mega Blaster** (Star Blaster maxado + Power Glove) — laser piercing forte e rápido
  - **Chaos Field** (Pixel Aura maxado + Spread Cart) — orbitais que disparam pulsos radiais a cada 1.6s
  - **Iron Save** (Save State maxado + Power Glove) — 2+ revives + buff de +60% dano permanente após primeiro revive
- **CartridgeRegistry.available_evolutions()** — detecta combos prontos; aparecem com prioridade no level-up
- **Player.unequip_cartridge()** — consume ingredientes na evolução, reverte efeitos passivos via `on_unequip()`
- **4 Spirits jogáveis**:
  - **Pixel** (default) — HP 100, vel 150, balanceado, Star Blaster inicial
  - **Slate** (desbloq: 3 min de run) — HP 160, vel 110, paleta cinza/azul, Pixel Aura inicial (tank)
  - **Disc** (desbloq: 5 cartuchos coletados) — HP 75, vel 165, paleta prata/cyan, Spread Cart inicial
  - **Handheld** (desbloq: derrotar boss) — HP 60, vel 210, paleta vermelho/amarelo, dash 2s (speedster)
- **SpiritRegistry** autoload + `Player.apply_spirit(def)` aplica stats/paleta/cartucho inicial
- **Hub "A Estante"** — cena nova de meta-progressão:
  - Grid 2×2 de Spirits com cards mostrando sprite, nome, descrição e condição de desbloqueio
  - Painel de coleção de cartuchos (todos os 9 + evoluções, grayed se não coletado)
  - Stats persistentes (best time, kills, runs)
  - Botões JOGAR / MENU
- **Settings autoload** — persiste em `user://settings.cfg`:
  - Master volume, SFX volume
  - Fullscreen toggle
  - Shader CRT toggle
  - Screen shake toggle
  - Modo fotossensível
- **Tela de Opções** — sliders e checkboxes pra configurar tudo acima
- **Shader CRT** (`shaders/crt.gdshader`) — scanlines + aberração cromática + vignette + curvatura sutil. Aplicado via `CrtOverlay` autoload em layer 100 sobre tudo.
- **SceneRouter** ganhou `go_to_hub()` e `go_to_options()`. Fluxo: MainMenu → Hub → Arena → GameOver → Hub/Menu

### Modificado
- MainMenu agora vai pro Hub em vez de Arena direto, e tem botão OPCOES
- Player.gd parametrizado por Spirit (max_hp, move_speed, sprite_scale_value, dash_max_cooldown, spirit_palette, starting_cartridge)
- LevelUpModal continua o mesmo — evoluções aparecem com cor dourada (LEGENDARY) e descrição própria

### Pendente
- Era 16-bit completa (nova arena, 8 inimigos, novo boss "Fragmentation") — escopo pra v0.4 dedicada
- Daily seed, rebind de controles, screen shake usage — v0.4

---

## [0.2.0] — 2026-05-15 — Polish do Loop + Boss

Run agora tem objetivo: derrotar o boss da Era 8-bit aos 5:00.

### Adicionado
- **5 novos inimigos Glitch**:
  - `Bleed` — blob roxo que deixa rastro de dano residual (`Stain`)
  - `ASCII Swarm` — enxame de glyphs amarelos com movimento ondulado, spawna em grupos de 3-5
  - `Echo` — réplica que mimica posição do player com delay de 1.5s (via novo autoload `PlayerTrail`)
  - `Checksum` — turret hexagonal que mantém distância e dispara projétil (novo `EnemyProjectile`)
  - `Memory Leak` — bloco corrompido que cresce com o tempo, libera 3 ASCII Swarm ao morrer
- **Unlock progressivo** de tipos no spawner: cada inimigo entra no pool conforme tempo (0s, 30s, 75s, 90s, 150s, 180s, 210s, 240s).
- **Boss Era 8-bit: Corruption v1.0**:
  - Spawna às 5:00 com aviso visual aos 4:50 ("WARNING — CORRUPTION INCOMING")
  - HP 800, sprite 18×20 com scale 3× (~54×60 px na tela)
  - 3 fases de comportamento baseadas em HP%: Opening / Midgame / Final
  - 3 padrões de ataque: **Bullet Ring** (12 projéteis em círculo), **Charge** (telegraph + dash), **Minion Spawn** (4 Artifacts)
  - Drop de morte: 8 gemas de XP + auto-equip do cartucho lendário Reset Button + vitória
- **Cartucho lendário Reset Button** — revive com 100% HP (vs Save State que revive com 50%)
- **HUD do boss** — barra de HP no topo central + nome + tela de WARNING piscante
- **Tela de Vitória** — `game_over.tscn` agora diferencia "VITORIA" (verde, "CORRUPTION PURGED") de "GAME OVER" (rosa, "THE GLITCH PREVAILS"), exibe + Reset Button (Lendário) na tela
- **Persistência de cartucho coletado**: Reset Button entra em `GameState.collected_cartridges` após primeira vitória

### Modificado
- Player teve `revives_remaining` separado em **`save_state_revives`** e **`reset_button_revives`** pra suportar dois tipos de revive
- `EventBus` ganhou sinais `boss_warning`, `boss_spawned`, `boss_damaged`, `boss_defeated`
- `EnemySpawner` reescrito com `SpawnEntry` (tipo + unlock_time + weight) e `enabled` flag (boss pausa o spawner)
- `GameState.last_run_victory` agora persiste o resultado da última run pra tela de game_over

### Notas técnicas
- `PlayerTrail` autoload grava posição do player a cada 0.1s (até 5s de histórico). Echo enemy lê de lá.
- `EnemyProjectile` separado de `Projectile` pra evitar acoplamento — projétil inimigo usa `area_entered` no hurtbox do player (layer 4), enquanto projétil do player usa `body_entered` em corpos inimigos (layer 8).
- `Stain` (rastro do Bleed) estende `Enemy` com HP infinito e move_speed=0 — abusa do sistema de detecção existente sem código novo no Player.

### Pendente pra v0.3
- Hub "A Estante" (cena de meta-progressão visual)
- Shader CRT toggle
- 2ª era (16-bit)

---

## [0.1.0] — 2026-05-15 — Vertical Slice (MVP)

Primeira versão jogável: do menu ao game-over com uma run completa.

### Adicionado
- **Engine + projeto**: Godot 4.3, viewport 320×180 com upscale para 1280×720, renderer GL Compatibility.
- **Autoloads**: `EventBus`, `GameState`, `ArenaBounds`, `Sprites`, `CartridgeRegistry`, `XpSystem`, `SceneRouter`, `Audio`.
- **Geração procedural de sprites**: utilitário `PixelArt` que converte ASCII art + paleta em `ImageTexture`. **Nenhum asset externo** — todos os visuais são gerados em código.
- **Áudio procedural**: SFX sfxr-style gerados em runtime via `AudioStreamWAV` (shoot, hit, enemy_die, player_hurt, level_up, pickup, dash).
- **Player "Pixel"** (Spirit cartucho 8-bit):
  - Movimento WASD/setas/gamepad com `Input.get_vector`
  - Dash (Space/gamepad-A, cooldown 4s, invul durante 0.15s)
  - HP 100, invul 0.5s pós-dano, flicker visual
  - Auto-aim no inimigo mais próximo
  - Slot de cartuchos
- **3 inimigos Glitch**:
  - `Artifact` — pixel verde, perseguição lenta direta
  - `Tear` — linha horizontal, movimento horizontal-dominante
  - `NullSprite` — quadrado missing-texture, tank
- **Projétil**: Area2D com piercing e bounce opcionais
- **XP Gem**: gema com atração magnética dentro do raio de pickup
- **EnemySpawner**: waves crescentes nos cantos da arena, peso de tipo escala com tempo
- **XP System**: curva 5 * 1.35^(level-1), pausas o jogo no level-up
- **5 cartuchos**:
  - `Star Blaster` (W, Comum) — projétil reto
  - `Spread Cart` (W, Raro) — 3-7 projéteis em leque (escala com level)
  - `Pixel Aura` (W, Especial) — 2-6 orbitais (escala com level)
  - `Power Glove` (P, Comum) — +25% dano por level
  - `Save State` (P, Lendário) — +1 revive por level
- **LevelUpModal**: pausa, mostra 3 cartas com raridade colorida, suporta mouse, gamepad e teclas 1/2/3
- **HUD**: HP bar, timer, level, kills, XP bar full-width, slots de cartucho
- **MainMenu**: tela título com botões + stats persistentes
- **GameOver**: tela com stats da run + REJOGAR/MENU
- **Arena**: fundo procedural com grid + scanlines, condição de vitória aos 7 min
- **Persistência**: `user://save.cfg` (ConfigFile) com cartuchos coletados, kills totais, best time

### Notas técnicas
- Entities (`Player`, `Enemy`, `Projectile`, `XpGem`) são instanciados via `ClassName.new()` sem `.tscn` próprio — toda hierarquia montada em `_ready()`.
- Apenas top-level scenes têm `.tscn` (`main_menu`, `arena`, `game_over`).
- Contato player-vs-inimigo é polled por frame (não `body_entered`) pra dano contínuo enquanto stacked.
- Cartridges são `Node`s filhos de `Player.cartridge_root` — modular, fácil de adicionar novos.

### Limitações conhecidas
- Sem boss ainda (vitória = sobreviver 7min) — chega na v0.2
- Hub "Estante" inexistente — chega na v0.2
- Fonte default do Godot em font_size pequeno fica meio borrada — fonte pixel CC0 entra na v0.4
- Sem música — playlist CC0 entra na v0.8
- Sem options menu (volume, fullscreen, rebind) — v0.4
