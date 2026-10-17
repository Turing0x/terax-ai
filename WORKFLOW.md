# Flujo de trabajo local

## Repos y remotes

- Checkout principal: `~/LocalProjects/terax-ai` (rama `local/mine`: upstream + cambios propios de Turing0x).
  - `origin` -> `https://github.com/crynta/terax-ai.git` (upstream, solo lectura para nosotros).
  - `fork` -> `https://github.com/Turing0x/terax-ai.git` (nuestro fork).
- El checkout principal tiene cambios propios sin commitear en `package.json` y `pnpm-lock.yaml`
  (subidas de versión: `ai` v7, `@ai-sdk/*`, `@babel/core` 8, pnpm 12...). **No van en ningún PR.**
  Por eso cada PR se trabaja en un worktree aparte.

## Worktrees

| Ruta | Rama | Uso |
| --- | --- | --- |
| `~/LocalProjects/terax-ai` | `local/mine` | Uso diario, cambios locales de Turing0x |
| `~/LocalProjects/terax-ai-contrib` | `contrib-notes` (huérfana) | Estas notas. Push a `fork` |
| `~/LocalProjects/terax-ai-docs` | `docs/sync-architecture-docs` | PR #1358 |
| `~/LocalProjects/terax-ai-write-guard` | `security/ai-write-guard-user-paths` | PR #1360 |

Fuera de git: `~/LocalProjects/terax-private/` (hallazgos de seguridad privados y borradores de informe). Nunca copiar su contenido a esta rama ni a PRs.

Un solo agente por worktree a la vez.

## Nuevo PR

```bash
cd ~/LocalProjects/terax-ai
git fetch origin
git worktree add -b <prefijo>/<nombre> ../terax-ai-<nombre> origin/main
cd ../terax-ai-<nombre>
pnpm install            # si hay que ejecutar checks de frontend
# ...cambios + checks (RULES.md)...
git push -u fork <prefijo>/<nombre>
gh pr create -R crynta/terax-ai --base main --head Turing0x:<prefijo>/<nombre> \
  --title "<type>(<scope>): ..." --body-file <fichero>
```

Tras el merge o cierre: `git worktree remove ../terax-ai-<nombre>` y borrar la rama del fork.

## Actualizar una rama de PR con upstream

```bash
cd ../terax-ai-<nombre>
git fetch origin && git rebase origin/main
git push --force-with-lease fork <rama>
```

## Notas (esta rama)

```bash
cd ~/LocalProjects/terax-ai-contrib
# editar STATUS.md y demás
git add -A && git commit -m "notes: ..." && git push fork contrib-notes
```

## Seguimiento de PRs

```bash
gh pr view <n> -R crynta/terax-ai --comments
gh pr checks <n> -R crynta/terax-ai
```
