# 🗺️ Roadmap — Cartridge Crusade

> Plano de versões do MVP até o launch. Datas omitidas de propósito — projeto é por diversão, sem prazo.

---

## v0.1 — Vertical Slice (MVP jogável) ✅ implementado
**Meta**: provar que o loop funciona. Uma run completa, do menu ao game-over.

- [x] Setup do projeto Godot 4.3
- [x] Sistema de input (teclado + gamepad)
- [x] Spirit "Pixel" jogável (movimento + auto-attack)
- [x] Arena 8-bit (placeholder visual com grid + scanlines)
- [x] 3 tipos de inimigo: Artifact, Tear, Null Sprite
- [x] Sistema de XP + level up + 3-card choice
- [x] 5 cartuchos jogáveis (Star Blaster, Spread, Aura, Glove, Save State)
- [x] HUD básico: HP, XP, timer, cartuchos equipados
- [x] Main menu
- [x] Game over screen
- [x] Save/load persistente (ConfigFile)
- [ ] Build Windows testada em hardware real

**Definição de pronto**: alguém pega o jogo do zero, joga uma run de 5 min, e diz "isso é divertido".

**Como testar**: abra `project.godot` no Godot 4.3 e pressione F5. Veja [README.md](./README.md#como-rodar).

---

## v0.2 — Polish do Loop ✅ implementado (parcial)
- [x] +5 inimigos (Bleed+Stain, ASCII Swarm, Echo, Checksum, Memory Leak)
- [x] Boss Era 8-bit: **Corruption v1.0** com 3 padrões de ataque e 3 fases
- [x] Save/load real (já estava em v0.1 via ConfigFile)
- [x] Coleção persistente entre runs (já estava em v0.1)
- [x] Cartucho lendário "Reset Button" como drop do boss
- [x] Tela de vitória diferenciada
- [x] HUD do boss (HP bar + warning)
- [ ] Hub mínimo "A Estante" → adiada pra v0.3
- [ ] Shader CRT toggle → adiada pra v0.4 (junto com opções)

---

## v0.3 — Profundidade + Estrutura ✅ implementado
- [x] **3 sinergias evolutivas** (Mega Blaster, Chaos Field, Iron Save)
- [x] **4 Spirits jogáveis** (Pixel + Slate + Disc + Handheld) com desbloqueios progressivos
- [x] Hub "A Estante" — cena de meta-progressão visual
- [x] Tela de Opções (audio, video, acessibilidade)
- [x] **Shader CRT** (scanlines, vignette, aberração cromática, curvatura) com toggle
- [x] Settings persistido em `user://settings.cfg`
- [ ] Spirit "Slate" com arte autoral (atualmente usa PIXEL_IDLE com paleta diferente) → v0.4
- [ ] Era 16-bit (movido pra v0.4)


## v0.4 — Era 16-bit ✅ implementado (parcial)
- [x] Nova arena com identidade 16-bit (paleta azul/roxa + gradient + estrelas piscantes)
- [x] **4 inimigos novos** (HueShift, Compression, Sprite Limit, Bit Flip)
- [x] Boss "Fragmentation" com 4 fases (split em 4 fragments na fase final)
- [x] **3 novos cartuchos** (Stereo Sound, Mode 7 Spin, Region Free)
- [x] Sistema de Eras (EraRegistry + seleção no Hub)
- [ ] +4 inimigos pra completar os 8 promised (Echo Variant, DMA Bus, Audio Wave, Z-Order Glitch) → v0.5
- [ ] ASCII art autoral por Spirit → v0.5
- [ ] Mais sinergias envolvendo cartuchos 16-bit → v0.5

---

## v0.5 — Acessibilidade Avançada + Polish ✅ implementado (parcial)
- [x] Menu de opções básico (v0.3)
- [x] Screen shake toggle, photosensitivity toggle (v0.3)
- [x] **Rebind de controles** (clica no botão da action, pressiona tecla, persiste)
- [x] **i18n (PT-BR + EN)** com seletor em runtime
- [x] **ASCII art autoral pra cada Spirit** (Slate, Disc, Handheld com sprites próprios)
- [x] 2 sinergias novas envolvendo 16-bit (Sonic Boom, Vortex Field)
- [ ] Daltonismo modes (protan/deuteran/tritan) → v0.6
- [ ] Tradução de descrições (cartuchos/spirits/eras) → v0.6

---

## v0.5 — Era 32-bit CD
- [ ] Arena Era CD (dithering, FMV fundo)
- [ ] 8 inimigos novos
- [ ] Boss "Bad Sector"
- [ ] +10 cartuchos
- [ ] Spirit "Disc"

---

## v0.6 — Meta-progressão profunda
- [ ] Achievements (Steamworks integração)
- [ ] Estatísticas por Spirit
- [ ] Modificadores de run (challenge runs)
- [ ] Daily seed run

---

## v0.7 — Era 64-bit
- [ ] Arena Era 64-bit (pseudo-3D, fog)
- [ ] 8 inimigos novos
- [ ] Boss "Polygon Hell"
- [ ] +10 cartuchos
- [ ] Spirit "Module"

---

## v0.8 — Audio Pass
- [ ] Curadoria final de música CC0 (10+ faixas)
- [ ] SFX procedurais polidos por contexto
- [ ] Sistema de música dinâmica (intensidade)
- [ ] Mixer com canais separados

---

## v0.9 — Era Final
- [ ] Era "Moderno Corrompido"
- [ ] Boss final "The Glitch"
- [ ] Spirit "Handheld"
- [ ] Cinematic ending (texto + portrait)
- [ ] Créditos

---

## v0.10 — Beta Aberto
- [ ] Itch.io demo público
- [ ] Coleta de feedback estruturado
- [ ] Bug fixing pass
- [ ] Performance pass (testar em hardware fraco)

---

## v1.0 — Launch Steam
- [ ] Steam Direct submission ($100)
- [ ] Steam page (capsule art, screenshots, trailer)
- [ ] Trailer de gameplay (gravado por nós)
- [ ] Press kit
- [ ] Conexão sutil com Gamo (QR code, link nas opções)
- [ ] Build Windows + macOS + Linux

---

## Pós-launch (v1.x)
- New Game+ / Heroic difficulty
- Modo cooperativo local (split-screen)
- Eventos sazonais
- Mods/workshop?
- Integração API Gamo (achievements remotos)

---

*Cada versão termina com: tag git + build pra teste local + nota de release em `CHANGELOG.md`.*
