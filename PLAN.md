# Plan de implementación: B6 (explorador y editor) y B7 (git)

Base: `AUDIT.md` F-1..F-14, upstream `1a68067`. Creado 2026-10-18.

Reglas para todos los PRs:
- Un hallazgo = un PR. Worktree propio desde `origin/main` (`../terax-ai-<slug>`), nunca desde `local/mine`.
- Antes de empezar: `gh pr list -R crynta/terax-ai --state open --search "<área>"` por si alguien lo ha cubierto.
- Test que fija el invariante (TERAX.md lo exige en git, fs y watcher).
- Checks: `pnpm lint`, `pnpm check-types`, `pnpm test`; Rust: `cargo clippy --all-targets --locked -- -D warnings`, `cargo nextest run --locked` (o `cargo test --locked`).
- Ruta: `implementador` por PR, `verificador` (otro modelo) antes de abrir. Push y PR con OK de Turing0x.
- Sin `biome format --write` sobre ficheros enteros.

## Orden

| Ola | PR | Hallazgo | Tipo | Tamaño | Bloqueo |
| --- | --- | --- | --- | --- | --- |
| 1 | P1 | F-4 paginación historial con merges | fix | S, Rust | ninguno |
| 1 | P2 | F-8 guardar sobre symlink | fix | S, Rust | ninguno |
| 1 | P3 | F-9 renombrar fichero con cambios sin guardar | fix | S, frontend | ninguno |
| 1 | P4 | F-5 timeout de commit | fix | XS, Rust | ninguno |
| 2 | P5 | F-1 Source Control en tiempo real | fix | L, Rust + frontend | issue con el diseño antes |
| 2 | P6 | F-2 diff obsoleto | fix | S, frontend | P5 (usa su señal) |
| 2 | P7 | F-3 historial tras commit | fix | S, frontend | P5 |
| 3 | ~~P8~~ | F-7 rutas canónicas del watcher | descartado | - | no reproducido en macOS |
| 3 | ~~P9~~ | F-6 PATH de git en macOS | descartado | - | no reproducido en macOS |
| 4 | I1, I2, I4 | F-10, F-11, F-13 | UX | - | issue antes; I3 (F-12) descartado, no reproducido |
| - | P10 | F-14 nombres no UTF-8 | fix | XS | prioridad baja |

Ola 1: fixes pequeños, sin diseño discutible. Pueden ir en paralelo (ficheros disjuntos), un worktree por PR.

## Ola 1

### P1: `fix(git): keep merged-branch commits when paging history`
- Fichero: `src-tauri/src/modules/git/operations.rs` (`log`, ~507-612); el frontend (`GitHistoryPane.tsx` `loadMore`) pasa el número de commits cargados.
- Cambio: sustituir el cursor `{sha}^` por `--skip=<n>` desde HEAD. Mantener `before_sha` solo como comprobación: si el commit en la posición `n-1` ya no es `before_sha`, HEAD se movió y el frontend recarga desde cero. Ajustar el tipo del comando (`skip: Option<u32>`) y `native.gitLog`.
- Test: repo temporal con `feat` mergeada `--no-ff`, páginas de 3; la unión de páginas es igual a `git log` completo y sin duplicados.
- Riesgo: `--skip` re-recorre los primeros n commits en cada página; con un máximo de 200 por página y paginación bajo demanda es despreciable.

### P2: `fix(fs): write through symlinks instead of replacing them`
- Fichero: `src-tauri/src/modules/fs/file.rs` (`write_atomic`, `fs_write_file`).
- Cambio: si el destino existe y es symlink, resolverlo (`canonicalize`) y escribir de forma atómica sobre el destino real (temporal en su directorio). Fichero nuevo: sin cambios. Conservar permisos del destino real.
- Test: symlink -> fichero; tras guardar, el enlace sigue siendo enlace y el destino tiene el contenido nuevo. Symlink colgante: comportamiento explícito (error o crear destino), decidir y testear.
- Comprobar: los controles de rutas protegidas de la IA validan la ruta canónica (A1 ya lo cubre con `checkWritableCanonical`); no abrir camino nuevo. Revisar con ojo de seguridad.

### P3: `fix(editor): keep unsaved edits when an open file is renamed`
- Ficheros: `src/modules/editor/lib/useDocument.ts`, posible helper puro en `editor/lib/`.
- Cambio: distinguir "misma pestaña, el fichero cambió de ruta" de "ruta nueva". En un rename, conservar buffer, `savedRef`, `dirty` y `diskMtimeRef`; no recargar. `EditorStack` ya mantiene el pane por id de tab.
- Test: helper puro que decide reload vs retarget; test del hook si el patrón existe en el repo.
- Comprobar: LSP (`didClose`/`didOpen` con la ruta nueva) y watchers (`useEditorFileSync` ya re-registra por ruta).

### P4: `fix(git): give commit hooks time to finish`
- Fichero: `src-tauri/src/modules/git/operations.rs` (`commit`), `types.rs`.
- Cambio: `COMMIT_TIMEOUT_SECS = MAX_TIMEOUT_SECS` (180). Si expira, error claro que mencione los hooks y un posible `index.lock`.
- Test: el comando usa el timeout de commit (test de la constante o del builder de argumentos, según el patrón existente).

## Ola 2

### P5: Source Control en tiempo real (F-1)
Abrir issue primero con este diseño (cambia el modelo de refresco y el mantenedor cuida mucho el rendimiento).

Señales, de más a menos importante:
1. Watcher de metadatos git (Rust). Comandos `git_watch_add/remove(repoRoot)`, con refcount. Vigila `.git/HEAD`, `.git/index`, `.git/refs/` (recursivo) y `.git/packed-refs`; resuelve `.git` fichero (worktrees y submódulos) a su `gitdir` y `commondir`. Emite `git:changed { repoRoot }` con debounce (~300 ms, ventana máx. 1 s). Ignora `index.lock`, `*.lock` y `objects/`. Reutiliza los backends de `fs/watch` (FSEvents / notify), sin hilos nuevos si es posible.
2. Escrituras propias: `fs:file-written` y mutaciones del explorador dentro del repo -> refresh.
3. Cambios del árbol de trabajo hechos por otros procesos sin tocar `.git` (editar en vim, agente CLI): `fs:changed` de directorios vigilados dentro del repo. Cobertura parcial (solo directorios expandidos / ficheros abiertos); el resto lo recoge el fin de comando.
4. Fin de comando OSC 133 (`onCommandState(false)`) en una terminal cuyo cwd está en el repo -> refresh.

Frontend: `useSourceControl` se suscribe solo con `live`; planificador puro `planLiveRefresh(signal, repoRoot, live, inflight, lastAt)` con tests (coalescer ráfagas, ignorar otros repos, no refrescar mientras hay uno en curso salvo marcarlo como pendiente). El watcher se registra al tener repo y consumidor `live`, y se libera al perderlos.

Coste: 0 sin consumidor `live`; con él, 1 stream/watch por repo y un `git status` por ráfaga.

Riesgo: el propio `git status` reescribe `.git/index` (stat cache) y realimenta la señal. `GIT_OPTIONAL_LOCKS=0` ya está puesto en `run_git` y lo evita; verificarlo con un test o una traza.

Partición posible: P5a (watcher Rust + evento, tests), P5b (suscripción frontend + planificador).

### P6: `fix(git): refresh open diff tabs when the file changes`
- `diffCache.ts`: invalidar las claves del repo cuando llega un snapshot de status nuevo con cambios en esa ruta (o con `git:changed`). `GitDiffPane`: recargar si está activo y su clave se invalidó.

### P7: `fix(git): refresh history when HEAD moves`
- `GitHistoryPane`: escuchar `git:changed` del repo y recargar la primera página conservando el scroll si el commit superior no cambió.

## Ola 3 (necesitan prueba manual antes)

### P8: rutas canónicas del watcher (F-7). DESCARTADO: no reproducido en macOS
- Prueba manual: `cd /tmp && mkdir t && cd t`, abrir el explorador, `touch x` en otra terminal; la entrada no debería aparecer.
- Cambio: `WatchSet` guarda, por clave canónica, las ortografías con que se registró (refcount por ortografía) y `fs:changed` emite esas en vez de la canónica. Ficheros: igual. Tests en `watch.rs` con directorio enlazado y con otra ortografía de mayúsculas.

### P9: PATH de git en macOS (F-6). DESCARTADO: no reproducido en macOS
- Prueba manual: abrir Terax desde el Dock y hacer commit en un repo con hook husky (`npx`), y push con credential helper `gh`.
- Cambio: mover la captura del entorno del login shell de `lsp/env.rs` a un módulo compartido (`proc/login_env.rs`), aplicarla en `build_git_command`. La captura bloquea hasta 10 s la primera vez: calentarla en segundo plano al arrancar y no bloquear `git status` (si no está lista, usar el entorno del proceso).

## Ola 4: issues de UX (sin código hasta tener respuesta)
- I1 F-10: borrar a la papelera del SO. Requiere dependencia (`trash`) o APIs nativas: pide aprobación de dependencia y justificar el tamaño del binario.
- I2 F-11: aviso "cambiado en disco" / "borrado en disco" en la pestaña con buffer sucio.
- ~~I3 F-12~~: descartado, no reproducido en macOS.
- I4 F-13: atajos del explorador (borrar, renombrar, copiar/cortar, inicio/fin).

## Pendiente de Turing0x
- ~~Prueba manual de F-6, F-7 y F-12~~: hecha 2026-10-18, no reproducidos.
- OK para abrir el issue de diseño de P5.
- Elegir: empezar ola 1 en paralelo (4 worktrees) o en serie.
