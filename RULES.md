# Reglas del mantenedor

Resumen de `CONTRIBUTING.md` y `TERAX.md`. Incumplirlas suele acabar en PR cerrado sin revisión.

## Antes de empezar

- Features, cambios de UX, refactors, perf y cambios de arquitectura: **discutir antes** (issue o Discord "Crynta OS"). Sin eso, el PR se cierra.
- Bugs claros, docs y typos: PR directo, sin issue.
- Revisar `ROADMAP.md` (planned / out of scope) y PRs abiertos del área.
- Fuera de alcance: debugger/profiler, notebooks, UIs de package managers, navegador completo, telemetría, marketplaces de extensiones.

## Al escribir

- Un PR = un cambio lógico. Nada de reformatear o limpiar ficheros ajenos al objetivo.
- Lógica nueva en funciones puras (functional core); comandos Tauri y componentes React finos.
- Sin comentarios salvo el "por qué" en 1-2 líneas. Sin em-dash. Sin emojis. Inglés americano en strings de UI.
- Imports siempre `@/...` en frontend. Solo pnpm.
- Rendimiento: nada de dependencias >50 KB gzip (cliente) o >5 MB (Rust) sin justificar; respetar startup graph, compositing budget y animaciones con `steps()`.
- Seguridad: validar en cada frontera (IPC, fs, red, herramientas de IA). Nunca saltarse la deny-list ni el `WorkspaceRegistry`.
- Paridad de plataformas: macOS / Linux / Windows / WSL. Rutas con `.split(/[\\/]/)`; Enter es `\r`.

## Seguridad (`SECURITY.md`)

- Vulnerabilidades: email privado a security@terax.app, nunca issue o PR público. Incluir impacto, reproducción, versión, OS y arquitectura.
- Hardening sin impacto explotable: PR público con prefijo `security/` y título `security(<scope>): ...`. El texto del PR no debe insinuar vulnerabilidades pendientes.
- Fuera de alcance: atacante local con shell, bugs de dependencias upstream, versiones < 0.5.

## Tests obligatorios

Cambios en spawn de shell/terminal, autorización de workspace, capa git, mutación de fs,
superficie IPC o de herramientas de IA, o lógica pura de amplio alcance (cwd, árbol de splits,
parsing OSC, command guard) **necesitan un test** que fije el invariante, incluido el caso deny.

## Checklist antes del PR

```bash
pnpm lint && pnpm check-types && pnpm test
cd src-tauri && cargo fmt && cargo clippy --all-targets --locked -- -D warnings && cargo nextest run --locked
```

- [ ] Rama con prefijo: `feat/`, `fix/`, `chore/`, `docs/`, `perf/`, `security/` (kebab-case), nunca desde `main` del fork.
- [ ] Título Conventional Commits con scope (`fix(terminal): ...`). Se convierte en el squash commit.
- [ ] Plantilla de PR rellena: What / Why / How / Testing, con pasos manuales concretos.
- [ ] Capturas o GIF si hay UI.
- [ ] Ningún cambio de `package.json` / `pnpm-lock.yaml` de Turing0x incluido.
