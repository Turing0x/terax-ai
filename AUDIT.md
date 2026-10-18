# Auditoría

Base: upstream `main` (v0.9.0, `1a68067`).

## Orden acordado (2026-10-17)

### Fase A: seguridad (acotada)

Modelo de amenaza (de `SECURITY.md`): entrada no confiable = salida de terminal, contenido de ficheros/repos, resultados de herramientas IA (prompt injection), web preview, updater. Fuera: atacante local.

| # | Superficie | Pregunta | Estado |
| --- | --- | --- | --- |
| A1 | Herramientas IA | ¿Prompt injection ejecuta sin aprobación? ¿Bypass path guard / deny-list? | Revisada. Hardening abajo; resto en privado |
| A2 | Comandos IPC Tauri | ¿Validan rutas contra `WorkspaceRegistry`? ¿Capabilities mínimas? | Pendiente |
| A3 | OSC 52/8/7 | Portapapeles sin permiso, enlaces peligrosos, cwd falso | Pendiente |
| A4 | Red y preview | Proxy, CSP, orígenes alcanzables | Pendiente |
| A5 | Credenciales | Fugas en logs, errores, contexto IA | Pendiente |
| A6 | Control plane CLI | Permisos de socket, autenticación | Pendiente |
| A7 | Updater | Firma, https | Pendiente |

Método: revisar PRs abiertos del área, leer código, hipótesis concretas, PoC en build local. Sin PoC no hay hallazgo.

Clasificación:
- Explotable: email privado a security@terax.app. Se registra SOLO en `../terax-private/SECURITY-FINDINGS.md` (fuera de git) hasta fix publicado. Esta rama es pública.
- Hardening sin impacto explotable: PR `security/<área>`, aquí como A-n.
- Falso positivo: descartado con motivo.

### Fase B: funcional (uso diario)

1. Arranque y sesión 2. Terminal 3. Tabs y splits 4. Atajos y paleta 5. Ajustes 6. Explorador y editor 7. Git 8. IA

Por área: checklist de comportamiento esperado (referencia iTerm/Warp/VS Code), prueba manual de Turing0x, lectura de código buscando casos límite. Hallazgos F-n: bug (PR directo) | UX (issue antes) | feature (issue antes).

## Formato de hallazgo

```
### A-<n> / F-<n>: <título corto>
- Área / severidad: <seguridad|corrección|rendimiento|UX|docs|tests> / <alta|media|baja>
- Ubicación: `ruta:línea`
- Problema: qué falla y en qué escenario concreto
- Propuesta: cambio mínimo + test que fija el invariante
- Estado: abierto | PR #<n> | descartado (motivo)
```

## Observaciones previas

- `bash_kill` sin aprobación: solo procesos de `bash_background` ya aprobados. Intencionado. Documentado en #1358.
- Traducciones `docs/readme/*` mencionan xterm.js (11 idiomas). Esperar #1307.

## PRs abiertos relevantes para A1

#1255 (deny aprobaciones pendientes), #876 (YOLO toggle), #1062/#1060/#1181 (tests IA), #973 (security hardening, grande).

## Hallazgos

### A-1: write guard no cubre ficheros de persistencia de usuario
- Área / severidad: seguridad (hardening) / media
- Ubicación: `src/modules/ai/lib/security.ts:106-125`
- Problema: prefijos anclados a raíz. `~/Library/LaunchAgents`, `~/Library/LaunchDaemons`, `~/.zshrc`, `~/.bashrc`, `~/.gitconfig`, `/Applications` pasan `checkWritable`. Sigue haciendo falta aprobación.
- Propuesta: cubrir variantes de usuario; test en `security.test.ts`.
- Estado: PR #1360

### A-2: open_preview acepta cualquier puerto loopback sin aprobación
- Área / severidad: seguridad (hardening) / baja
- Ubicación: `src/modules/ai/tools/terminal.ts:63-93`
- Propuesta: aprobación si el puerto no es de un `bash_background` activo.
- Estado: abierto

### A-3: plan mode solo por prompt; applyAll no recomprueba
- Área / severidad: seguridad (hardening) / baja
- Ubicación: `agent.ts:301-302`, `tools/shell.ts`, `planStore.applyAll`
- Propuesta: bloquear `bash_*` con plan activo; `checkWritableCanonical` en apply.
- Estado: abierto

### A-4: spawn_coding_agent no filtra control chars
- Área / severidad: seguridad (hardening) / baja
- Ubicación: `useAiLiveBridge.ts` (~120-155)
- Problema: `\x1b[201~` embebido cierra bracketed paste. `send_to_agent` sí filtra.
- Propuesta: reutilizar `hasControlChars`.
- Estado: abierto

### A-5: bash_logs / bash_kill no ligados a la sesión de chat
- Área / severidad: seguridad (hardening) / baja
- Ubicación: `src-tauri/src/.../shell/mod.rs` (~187-215)
- Propuesta: guardar sessionId dueño en `BackgroundProc`.
- Estado: abierto

### A-6: deny-list de shell es conveniencia, no frontera
- Área / severidad: seguridad (hardening) / baja
- Problema: `rm -rf /*`, `rm -r -f /`, `bash <(curl …)`, `| /bin/sh`, `| python3` pasan. El código ya dice que el usuario es el gate.
- Propuesta: ampliar patrones obvios con tests. Prioridad baja.
- Estado: abierto

### Refutado en A1 (no volver a comprobar)
`..`, mayúsculas, `.SSH`, ADS, punto/espacio final, `\\?\`; symlink a ruta protegida (canonicaliza); escritura vía symlink colgante; subagentes (solo lectura); ejecución antes de aprobar; auto-approve (no existe); imagen markdown zero-click (CSP `img-src`); XSS markdown (sanitize + CSP); sentinel shell; preview no loopback.

## Fase B: áreas 6 (Explorador y editor) y 7 (Git)

Auditada 2026-10-18 sobre `1a68067`. Método: lectura de código de punta a punta en los caminos de uso diario + reproducción en repo de prueba cuando era posible. Verificación de cada hallazgo indicada como `repro` (reproducido), `código` (confirmado leyendo el código, sin ambigüedad) o `manual` (falta prueba en la app).

Síntoma reportado por Turing0x: Source Control no refleja cambios en tiempo real. Causa raíz: F-1.

### Causa raíz común

Solo existe un watcher nativo (`fs/watch.rs`) y lo usan el explorador (directorios expandidos) y los editores (ficheros abiertos). Source Control no se suscribe a nada: depende del evento `focus` de la ventana. Además el watcher ignora `.git` (`plan.rs` `SKIP_DIRS` y `EXCLUDE_UNDER_ROOT`) y no informa de ediciones in-place al explorador (`listing_changed`, intencionado).

### F-1: Source Control solo se actualiza al enfocar la ventana
- Área / severidad: corrección / alta
- Ubicación: `src/modules/source-control/useSourceControl.ts:513-590`
- Problema: `git status` corre en cambio de contexto (cd a otro repo, cambio de tab), al recibir `focus` la ventana y tras acciones del propio panel. Con Terax ya enfocado no se refresca nunca ante: `git add/commit/checkout/stash` en la terminal, guardar en el editor, escrituras de herramientas IA, agentes CLI (Claude Code, Codex) editando ficheros, crear/borrar/mover desde el explorador. Cd dentro del mismo repo reutiliza el snapshot (TTL 2 s). Las decoraciones git del explorador cuelgan del mismo snapshot y quedan igual de obsoletas.
- Propuesta: señales baratas que disparen el refresh ya existente (debounce, coalescido, solo con `live`): (a) watcher de `.git/HEAD`, `.git/index` y `refs/` en Rust (detecta toda operación git, venga de donde venga); (b) `fs:file-written` y `fs:changed` dentro del repo; (c) fin de comando OSC 133 en una terminal cuyo cwd está en el repo. Planificador puro testeado (qué señal refresca qué repo y cuándo). Coste cero cuando no hay consumidor `live`.
- Verificación: código
- Estado: abierto. Sin issue ni PR upstream que lo cubra (revisado 2026-10-18).

### F-2: pestañas de diff git muestran contenido obsoleto
- Área / severidad: corrección / media
- Ubicación: `src/modules/editor/lib/diffCache.ts`, `src/modules/editor/GitDiffPane.tsx:148-196`
- Problema: el diff de trabajo se cachea por (repo, ruta, modo). Solo se invalida al hacer stage/unstage/discard/commit desde el panel o con el botón refresh. Editar y guardar el fichero, o cambiarlo desde la terminal, deja el diff viejo; al volver a la pestaña se sirve desde caché. Con la pestaña activa no se recarga nunca.
- Propuesta: invalidar la entrada al cambiar el snapshot de status del repo (o con las mismas señales de F-1) y recargar la pestaña activa.
- Verificación: código
- Estado: abierto

### F-3: el historial git no se refresca tras un commit
- Área / severidad: corrección / media
- Ubicación: `src/modules/git-history/GitHistoryPane.tsx:363-370`
- Problema: `git log` se carga al montar o al cambiar `repoRoot`, y con el botón refresh. Un commit (panel o terminal), pull o checkout no actualiza la pestaña abierta.
- Propuesta: recargar cuando cambie HEAD (señal (a) de F-1).
- Verificación: código
- Estado: abierto

### F-4: la paginación del historial pierde commits en repos con merges
- Área / severidad: corrección / alta
- Ubicación: `src-tauri/src/modules/git/operations.rs:519-527` (cursor `{sha}^`)
- Problema: la página siguiente se pide como `git log <último>^`, que solo sigue el primer padre. Los commits alcanzables solo por el segundo padre de un merge y más antiguos que el corte desaparecen. Repro: rama `feat` (f1, f2, f3) mergeada con `--no-ff` en `main` (m1, m2, m3), páginas de 3: se ven `merge m3 m2` y `m1 root`; `f1 f2 f3` nunca aparecen. Con `PAGE_SIZE = 30` pasa en cualquier repo con ramas mergeadas.
- Propuesta: paginar con `--skip=<n>` desde el mismo punto de partida (u otra forma que respete el orden de `git log`). Test Rust con repo temporal con merge.
- Verificación: repro
- Estado: abierto

### F-5: commit desde el panel muere a los 30 s, incluidos los hooks
- Área / severidad: corrección / media
- Ubicación: `src-tauri/src/modules/git/operations.rs:442-447`, `types.rs:3`
- Problema: `git commit` usa `DEFAULT_TIMEOUT_SECS = 30`. Los hooks `pre-commit`/`commit-msg` (husky, lint-staged, tests) corren dentro de ese tiempo. Al expirar se mata git y puede quedar `.git/index.lock`, que bloquea las siguientes operaciones.
- Propuesta: timeout propio para commit (el máximo permitido, 180 s) y mensaje claro si expira.
- Verificación: código
- Estado: abierto

### F-6: git hereda el PATH mínimo de la app GUI en macOS
- Área / severidad: corrección / media
- Ubicación: `src-tauri/src/modules/git/process.rs:304-328`
- Problema: `run_git` lanza `git` con el entorno del proceso. Lanzada desde el Dock, la app tiene un PATH mínimo (el módulo LSP ya lo resuelve con `lsp/env.rs`). Los hooks que llaman a `node`/`npx`, los credential helpers en Homebrew (`gh auth git-credential`) y `gpg` para firmar fallarían desde el panel aunque funcionen en la terminal.
- Propuesta: reutilizar el entorno capturado del login shell (`lsp/env.rs`) para git.
- Verificación: manual (commit con hook husky y push con helper `gh`, abriendo Terax desde el Dock)
- Estado: abierto

### F-7: el explorador y los editores no se actualizan bajo symlinks o con mayúsculas distintas
- Área / severidad: corrección / alta
- Ubicación: `src-tauri/src/modules/fs/watch.rs:192-222` (claves canónicas), `src/modules/explorer/lib/useFileTree.ts:332-340`, `src/modules/editor/useEditorFileSync.ts:92-99`
- Problema: el watcher registra y emite rutas canónicas (`std::fs::canonicalize`, que resuelve symlinks y corrige mayúsculas en macOS). El árbol y las pestañas guardan la ruta tal como llega del cwd de la terminal (OSC 7, ruta lógica). No coinciden: `cd /tmp/x` (canónica `/private/tmp/x`), un `~/code` que es symlink, o `cd ~/projects` cuando el directorio es `Projects`. En esos casos ni el árbol ni los editores abiertos se refrescan nunca por cambios externos. Verificado: `realpath` devuelve `CaseDir` para `casedir` y `/private/tmp` para `/tmp`.
- Propuesta: que Rust recuerde la ortografía con la que cada cliente registró la ruta y emita esa (o devolver ambas). Test con directorio enlazado.
- Verificación: repro parcial (resolución de rutas), manual (refresco en la app)
- Estado: abierto

### F-8: guardar un fichero que es symlink lo sustituye por un fichero normal
- Área / severidad: corrección / alta
- Ubicación: `src-tauri/src/modules/fs/file.rs:120-129`, `145-150`
- Problema: `write_atomic` escribe un temporal y hace `rename` sobre la ruta pedida. Si esa ruta es un symlink, `rename` reemplaza el enlace, no el destino: el original queda sin cambios y el enlace se convierte en un fichero suelto. Rompe dotfiles gestionados con stow/chezmoi (`~/.zshrc` -> `dotfiles/zshrc`) y cualquier config enlazada. También pierde hardlinks.
- Propuesta: resolver el destino real antes de escribir (temporal en el directorio del destino real). Test Rust con symlink.
- Verificación: código (semántica POSIX de `rename`)
- Estado: abierto

### F-9: renombrar o mover un fichero abierto con cambios sin guardar descarta los cambios
- Área / severidad: corrección / alta
- Ubicación: `src/app/App.tsx:734-747`, `src/modules/editor/lib/useDocument.ts:141-159`
- Problema: al renombrar/mover desde el explorador se actualiza `path` de la pestaña. `useDocument` trata el cambio de ruta como fichero nuevo: pone `dirty=false` y recarga del disco. Las ediciones no guardadas se pierden sin aviso.
- Propuesta: si solo cambia la ruta del mismo fichero, conservar el buffer y el estado sucio (retarget, no reload). Test de la función pura que decide.
- Verificación: código
- Estado: abierto

### F-10: el borrado del explorador es permanente
- Área / severidad: UX / media
- Ubicación: `src-tauri/src/modules/fs/mutate.rs:225-231`, menú contextual de `FileExplorer.tsx`
- Problema: `remove_dir_all`/`remove_file`, sin papelera del sistema. La confirmación es un segundo clic en el mismo menú. VS Code, Finder y la mayoría de exploradores mueven a la papelera.
- Propuesta: mover a la papelera del SO (requiere dependencia nueva o API nativa por plataforma). Issue antes.
- Verificación: código
- Estado: abierto (issue antes)

### F-11: cambio en disco con buffer sucio pasa desapercibido hasta guardar
- Área / severidad: UX / media
- Ubicación: `src/modules/editor/lib/useDocument.ts:171-181`
- Problema: con cambios sin guardar, `reload` no hace nada y no avisa. El usuario lo descubre al guardar (toast de conflicto). Si el fichero se borra en disco tampoco hay indicación.
- Propuesta: aviso en la pestaña ("cambiado en disco" / "borrado") con Recargar / Mantener. Issue antes.
- Verificación: código
- Estado: abierto (issue antes)

### F-12: la recarga externa podría perder cursor y scroll
- Área / severidad: UX / media
- Ubicación: `src/modules/editor/EditorPane.tsx:655-658`
- Problema: al recargar, el nuevo contenido entra por la prop `value` de `@uiw/react-codemirror`, que sustituye el documento entero. Es probable que el cursor salte y se pierda la posición de scroll en cada cambio externo (formatter de terminal, git checkout, agente).
- Propuesta: aplicar el cambio externo como diff mínimo y conservar selección y scroll.
- Verificación: manual
- Estado: abierto

### F-13: atajos de teclado básicos ausentes en el explorador
- Área / severidad: UX / baja
- Ubicación: `src/modules/explorer/FileExplorer.tsx:542-626`
- Problema: solo hay flechas, Enter y pegar. Faltan Supr/Cmd+Backspace (borrar), F2 o Enter (renombrar, según plataforma), Cmd+C/Cmd+X (copiar/cortar ficheros), Inicio/Fin.
- Propuesta: añadirlos vía registro de atajos. Issue antes.
- Verificación: código
- Estado: abierto (issue antes)

### F-14: entradas con nombre no UTF-8 desaparecen del árbol
- Área / severidad: corrección / baja
- Ubicación: `src-tauri/src/modules/fs/tree.rs:169`
- Problema: `into_string().ok()?` descarta en silencio los nombres no UTF-8 (posibles en Linux).
- Propuesta: nombre con `to_string_lossy` y marcarlo como no editable. Prioridad baja.
- Verificación: código
- Estado: abierto

### F-15: un timeout de git deja vivos los procesos de los hooks
- Área / severidad: corrección / baja
- Ubicación: `src-tauri/src/modules/proc/capture.rs:133-137`, `git/process.rs` `build_git_command`
- Problema: al expirar, `capture::run` mata solo a `git`. Sin grupo de procesos (Unix) ni `ProcessJob` (Windows), los hooks (sh, node lint-staged) quedan huérfanos y pueden seguir tocando el árbol o el index.
- Propuesta: grupo de procesos + killpg en Unix y `ProcessJob` en Windows, como `lsp/session.rs`. PR aparte.
- Verificación: código (lo encontró la revisión de P4)
- Estado: abierto

### Ya cubierto por issues/PRs upstream (no duplicar)
Doble clic renombra en vez de abrir (#541, PR #621). Editor no se recarga tras discard (#988, PR #1251). Explorer y Source Control al cambiar de space (#1159, PR #1250). Scroll horizontal del árbol (#616). Zoom escala el árbol (#768, PR #786). Worktrees (#1101, #856). Ramas desde el panel (#767). Vista en árbol del panel (#1086, PR #543). Gutter git en el editor (#921). Diff lado a lado (#534, PR #926). Abrir con la app por defecto (#588, PR #620).

### Cobertura
Revisado a fondo: watcher (`fs/watch*`), árbol (`useFileTree`, `fs/tree.rs`), mutaciones (`fs/mutate.rs`), lectura/escritura (`fs/file.rs`, `useDocument`, `EditorPane`, `useEditorFileSync`), backend git (`commands`, `operations`, `process`, `parser`, `untracked`), `useSourceControl`, `useSourceControlPanel`, `useSourceControlContext`, `repositoryTarget`, decoraciones git del explorador, carga de `GitDiffPane` y `GitHistoryPane`.
Leído por encima o sin revisar: `ExplorerSearch`, drag and drop y pegado (`useExplorerDnd`, `useExplorerFileDrop`, `clipboardPaste`, `fs/copy.rs`), búsqueda e índice (`fs/search`, `grep`, `index`), autocompletado IA, LSP, formatters externos, markdown, `AiDiffPane`, render de `SourceControlPanel`. La autorización de rutas en los comandos IPC de fs y git va en A2 (seguridad), no aquí.
