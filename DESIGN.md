# 🎮 Cartridge Crusade — Game Design Document

> Documento vivo. Atualizado conforme decisões são tomadas. Fonte da verdade pro design do jogo.

---

## 1. Visão Geral

### 1.1 Pitch
**Cartridge Crusade** é um *bullet heaven roguelite* 2D pixel art onde o jogador é o **Spirit of a Console** — uma alma digital que vive em consoles antigos — lutando para salvar a **Coleção Eterna** de um vírus corruptor chamado **The Glitch**. O jogador atravessa as **Eras dos Videogames** (8-bit → moderno), coleta cartuchos lendários, e enfrenta hordas de inimigos glitch.

### 1.2 Tema e Tom
- Nostalgia retrô como amor à história dos games
- Glitch / corrupção digital como antagonista visual e narrativo
- Coleção como ato heroico (alinhado ao Gamo)
- Tom: aventura arcade com humor afetuoso, sem grimdark

### 1.3 Plataforma e Distribuição
- **Plataforma primária**: PC (Windows, macOS, Linux)
- **Distribuição**: Steam (gratuito), com possibilidade futura de itch.io
- **Objetivo de negócio**: divulgar a plataforma Gamo entre retrogamers, colecionadores e entusiastas

### 1.4 Público-Alvo
- Retrogamers (35-55 anos, nostalgia de NES/SNES/Mega Drive/PS1)
- Colecionadores de videogames (público-core do Gamo)
- Entusiastas de roguelite/bullet heaven (público-shoulder)
- Streamers/criadores de conteúdo retrô

### 1.5 Gênero e Referências
- **Gênero**: Bullet Heaven / Survivors-like / Roguelite
- **Referências de mecânica**: *Vampire Survivors*, *Brotato*, *Halls of Torment*, *Holocure*
- **Referências de estética**: *Undertale* (paleta limitada), *Crypt of the Necrodancer* (chiptune+pixel), *Hyper Light Drifter* (uso de cor), *Enter the Gungeon* (corruption boss)
- **Referências de meta**: *Hades* (boon synergy, hub progression)

---

## 2. Núcleo de Gameplay

### 2.1 Loop Principal (10 min)
1. Jogador escolhe um **Spirit** na Estante (hub)
2. Equipa até 3 **Cartuchos** iniciais (passivos/armas)
3. Entra em uma **Era** (fase) — sobrevive a ondas crescentes de Glitches
4. A cada level-up, escolhe entre 3 **Slots** (novos cartuchos, upgrades, sinergias)
5. Boss da Era no minuto 7
6. Vitória ou morte → retorna à Estante com cartuchos coletados (meta-progressão)

### 2.2 Pilares de Design
1. **"Run de 7-15 minutos"** — fácil de encaixar no dia, viciante
2. **"Toda morte ensina algo"** — meta-progressão garante avanço
3. **"Colecionar é a recompensa"** — espelha o Gamo
4. **"Glitch é o feio que vira lindo"** — abraçar limitações estéticas como identidade

### 2.3 Mecânica de Combate
- Movimento WASD/setas + gamepad (twin-stick não, auto-attack)
- **Auto-attack**: ataque básico dispara automaticamente no inimigo mais próximo
- **Cartuchos equipados** disparam em padrões próprios
- Sem ataque manual — foco em posicionamento e build
- Dash (1 charge, cooldown 4s) — única ação ativa

### 2.4 Sistema de Cartuchos
**Tipos**:
- **Arma** (W) — adiciona padrão de disparo (3-slot limit)
- **Passivo** (P) — modifica stats (5-slot limit)
- **Modificador** (M) — altera comportamento de cartucho-arma

**Raridade** (espelha categorias do Gamo):
| Raridade | Cor | Drop rate inicial |
|---|---|---|
| Comum | cinza | 60% |
| Raro | verde | 25% |
| Especial | azul | 12% |
| Lendário | dourado | 3% |

**Sinergias**: combinações específicas de 2-3 cartuchos desbloqueiam evolução (estilo *Vampire Survivors* evolutions).

### 2.5 Progressão de Run
- XP de inimigos → level up → escolha de 3 cartuchos
- Inimigos dropam **Tokens de Memória** (moeda da run)
- Baús aparecem após mini-bosses (a cada 2 min) com cartucho garantido
- Boss final dropa **Cartucho Lendário** da era

### 2.6 Meta-Progressão (Hub: A Estante)
- Cartuchos coletados ficam na **Coleção Permanente** (acesso visual em prateleira)
- 5 Spirits desbloqueáveis (1 inicial + 4 via coleção)
- **Save Slots** = 3
- **Achievements** vinculados a marcos de coleção (espelhando o Gamo)
- Possível integração futura: QR code de Gamo na tela de game-over

---

## 3. Conteúdo

### 3.1 Spirits (Personagens Jogáveis)

| Nome | Conceito | Stats | Mecânica única |
|---|---|---|---|
| **Pixel** | Cartucho 8-bit | HP médio, Velocidade alta | Projétil simples, alta cadência |
| **Slate** | Console portátil-grandão cinza | HP alto, Velocidade baixa | AoE no corpo a corpo |
| **Disc** | Mídia óptica era CD | HP médio, Velocidade média | Projéteis ricocheteiam paredes |
| **Module** | Console modular tipo Atari | HP baixo, Velocidade média | Slot extra de cartucho-arma |
| **Handheld** | Portátil compacto | HP baixo, Velocidade muito alta | Dash com 2 charges |

> **Importante**: nenhum design referencia IP de console real. Visuais são formas geométricas estilizadas (retângulos com botões, slots, telas).

### 3.2 Eras (Fases)

| # | Era | Identidade visual | Boss | Status MVP |
|---|---|---|---|---|
| 1 | **8-bit** | 4 cores, sprites chunky, sem scroll suave | "Corruption v1.0" | ✅ MVP |
| 2 | **16-bit** | 16+ cores, parallax, Mode 7 fake | "Fragmentation" | v0.3 |
| 3 | **32-bit CD** | Dithering, FMV corrompido fundo | "Bad Sector" | v0.5 |
| 4 | **64-bit** | Pseudo-3D, fog distance, sprites baixa-poly | "Polygon Hell" | v0.7 |
| 5 | **Moderno Corrompido** | Mistura de todas as eras + glitches máximos | "The Glitch" | v1.0 |

### 3.3 Inimigos Glitch (MVP — Era 8-bit)

| Nome | Visual | Comportamento |
|---|---|---|
| **Artifact** | Pixel verde piscando | Caminhada lenta direto no jogador |
| **Tear** | Linhas horizontais que se movem | Atravessa em linha reta |
| **Bleed** | Mancha de cor vazando | Trail de dano residual |
| **Null Sprite** | Quadrado magenta/preto | Tank, dispara projétil |
| **ASCII Swarm** | Caracteres voadores | Enxame rápido |
| **Echo** | Cópia distorcida do jogador | Mimicka movimento com delay |
| **Checksum** | Hexágono numérico girando | Orbita e dispara |
| **Memory Leak** | Bloco crescendo lentamente | Engole espaço, dano contínuo se tocar |

**Boss MVP — Corruption v1.0**: ciclo de 3 fases. Telegrafa ataques com glitch screen. Dropa **Cartucho Lendário "Reset Button"**.

### 3.4 Cartuchos MVP (5 iniciais)

| Nome | Tipo | Efeito |
|---|---|---|
| **Star Blaster** | Arma | Projétil reto, cadência média |
| **Spread Cart** | Arma | 3 projéteis em leque |
| **Pixel Aura** | Arma | Orbital damage |
| **Power Glove** | Passivo | +20% dano |
| **Save State** | Passivo | Revive 1 vez por run |

**Sinergia exemplo**: Star Blaster + Power Glove → evolui para "Mega Blaster" (laser piercing).

---

## 4. Estética e Áudio

### 4.1 Direção de Arte
- **Resolução base**: 320×180 (escalada para 1280×720 / 1920×1080)
- **Paleta por era**: limitada e icônica
- **Sprites**: gerados procedural ou desenhados em código (formas + paletas)
- **Pós-processamento**: shaders CRT, scanlines, chromatic aberration (toggle em opções)
- **UI**: estética "bootscreen retrô" — fontes pixel, bordas chunky

### 4.2 Identidade Glitch
- Shaders custom para corrupção visual
- Partículas de tearing, missing texture pink (#FF00FF / #000000)
- Distorção quando jogador toma dano

### 4.3 Áudio
- **Música**: trilha CC0 chiptune (a curar: juhanijunkala, ozzed, Eric Skiff)
- **SFX**: gerados via sfxr/Bfxr em código (procedural retro sounds)
- **Vozes**: nenhuma. Tudo via texto/portrait

### 4.4 Fontes
- Pixel font open-source (ex: "Press Start 2P", "VT323", ou fonte custom em código)

---

## 5. Tecnologia

### 5.1 Engine
- **Godot 4.3** (estável atual)
- **GDScript** como linguagem principal (sem C# pra simplicidade)
- **GL Compatibility** renderer (máxima compatibilidade com PCs antigos do público retrô)

### 5.2 Estrutura de Pastas
```
gamo-game/
├── project.godot
├── DESIGN.md
├── ROADMAP.md
├── README.md
├── scenes/          # .tscn (cenas Godot)
│   ├── main_menu.tscn
│   ├── hub.tscn
│   └── arena.tscn
├── scripts/         # .gd (lógica)
│   ├── spirits/
│   ├── cartridges/
│   ├── enemies/
│   └── systems/
├── autoload/        # Singletons (GameState, AudioBus, etc.)
├── shaders/         # .gdshader (CRT, glitch, etc.)
├── assets/
│   ├── sprites/     # PNGs gerados ou CC0
│   ├── audio/       # OGG (música) + WAV (SFX procedurais cacheados)
│   └── fonts/
└── export/          # builds (gitignored)
```

### 5.3 Salvamento
- `user://save_<slot>.dat` — formato Godot ConfigFile (legível, debugável)
- Salva: coleção de cartuchos, Spirits desbloqueados, achievements, settings

### 5.4 Targets de Performance
- **Mínimo**: 60 FPS em hardware com integrated graphics de 2015
- **Resolução**: nativa 320×180, scaling para qualquer monitor

---

## 6. Monetização e Distribuição

- **Preço**: gratuito (Free-to-Play sem microtransações)
- **Steam**: necessário Steam Direct ($100 USD one-time fee)
- **Sem DRM** (filosofia indie + público retrô valoriza)
- **Sem ads**

### Conexão com Gamo
- Tela de game-over: "Curte colecionar games de verdade? Conheça Gamo" + QR code (não-intrusivo, opcional)
- Achievement especial por conectar conta Gamo (futuro, pós v1.0)
- Cartuchos lendários com nomes que homenageiam clássicos (sem violar IP)

---

## 7. Riscos e Mitigações

| Risco | Probabilidade | Mitigação |
|---|---|---|
| Arte ficar amadora | Alta | Abraçar estética 8-bit minimalista como escolha |
| Performance em PCs antigos | Média | Renderer GL Compatibility + targets baixos |
| Música repetitiva (CC0) | Média | Curar 8-10 faixas, randomizar por run |
| Bugs de física em arena open | Alta | Testes automatizados + escopo restrito MVP |
| Falta de polish vs concorrentes | Alta | Focar em **um** loop bem feito antes de adicionar conteúdo |
| Processo por IP de console | Baixa-Média | Designs 100% originais, sem nomes/cores específicos |

---

## 8. Critérios de Sucesso

### MVP (v0.1)
- [ ] Jogador completa uma run de 7 min do início ao fim
- [ ] 0 crashes em 10 runs consecutivas
- [ ] Build Windows funcional em 1 clique
- [ ] Coleção persiste entre sessões

### Launch (v1.0)
- [ ] 5 Eras completas
- [ ] 5 Spirits jogáveis
- [ ] 50+ cartuchos
- [ ] 10+ sinergias evolutivas
- [ ] Trilha sonora coesa
- [ ] Steam page aprovada
- [ ] Achievements (10+)

---

## 9. Decisões em Aberto

- [ ] Nome final do jogo (Cartridge Crusade é provisório)
- [ ] Idiomas suportados no launch (PT-BR + EN garantidos; ES/JP a definir)
- [ ] Sistema de daily run / weekly seeds?
- [ ] Modo cooperativo local (split-screen)? — fora do MVP, talvez v1.x
- [ ] Integração técnica real com API Gamo (achievements remotos)?

---

*Última atualização: 2026-05-15*
