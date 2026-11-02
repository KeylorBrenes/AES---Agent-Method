# RFC-001 — AES 1.1.0: propuesta de refinamiento

**Estado:** Aceptada e incorporada en AES 1.1.0
**Base:** AES Core 1.0.0
**Tipo de cambio:** MINOR (reglas nuevas compatibles; endurece controles existentes sin romper la estructura)
**Fecha:** 2026-11-02

---

## 0. Diagnóstico de AES 1.0.0

AES 1.0.0 acierta en lo esencial: separación de roles, protección de pruebas de aceptación, DoR/DoD, evidencia antes que afirmaciones y planificación progresiva. Al contrastarlo con las fuentes (Willison, Beck, TDAD, Böckeler, Anthropic Skills, documentación de hooks de Claude Code y permisos de OpenCode) aparecen siete huecos concretos:

| # | Hueco | Consecuencia práctica |
|---|---|---|
| 1 | Dice «proteger técnicamente», pero no define **qué cuenta** como control técnico ni en qué capa. | Se configura un permiso en OpenCode y se cree que basta; el agente escribe el archivo con `bash` y lo esquiva. |
| 2 | No exige demostrar que la prueba de aceptación **falla antes** de implementar. | Pruebas tautológicas o que no ejercitan el comportamiento pasan en verde desde el día uno. |
| 3 | No resuelve **contra qué interfaz** escribe QA las pruebas antes de que exista el código. | QA adivina nombres internos; el programador acaba «acomodando» o se generan conflictos. |
| 4 | Toda la suite de aceptación es visible para el programador. | Riesgo de implementación ajustada a la prueba (hardcoding) sin cumplir la regla general. |
| 5 | El alcance se controla por instrucción, no por **medición del diff**. | La sobreingeniería y los archivos ajenos se detectan tarde o nunca. |
| 6 | Un único ciclo para todo tamaño de cambio. | Riesgo de la queja clásica a SDD: un bug pequeño termina con historias y criterios de más. |
| 7 | No hay **bucle de aprendizaje** del harness (registro de fallos del agente → reglas/hooks/skills). | Los mismos errores se repiten entre historias. |

Además faltan dos mecanismos operativos: un **circuit breaker** para cuando el agente entra en bucles de corrección, y una regla de **commits estructurales vs. conductuales** que haga barata la revisión.

---

## 1. Posicionamiento: AES no es SDD rígido

Böckeler (Thoughtworks) distingue tres niveles de SDD: *spec-first*, *spec-anchored* y *spec-as-source*. En su análisis, Kiro convirtió un bug pequeño en cuatro historias con dieciséis criterios, y Spec Kit le resultó demasiado pesado para una funcionalidad mediana en un código existente.

AES se declara explícitamente:

- **Spec-anchored:** la especificación vive junto a la historia y se mantiene mientras la historia exista.
- **Test-as-executable-spec:** la especificación que realmente manda es la **suite de aceptación protegida**. El Markdown explica la intención; las pruebas la hacen exigible.
- **Proporcional:** el tamaño del proceso depende del *track* del cambio (sección 7), no es igual para todo.

> **Regla nueva (00 §2, principio 13):** Cuando una especificación en prosa y una prueba de aceptación aprobada discrepan, la discrepancia es un defecto de especificación que se resuelve por control de cambios. Ningún agente decide unilateralmente cuál de las dos «gana».

---

## 2. Modelo de controles en capas (nuevo 06 §9)

### Problema
Un permiso de harness no es lo mismo que un control que el agente no puede desactivar. Ejemplo real: en OpenCode, `edit` cubre las herramientas `edit`, `write` y `patch`, pero un `bash` permisivo puede escribir el mismo archivo con `sed` o `cat >`.

### Regla
Un control solo se considera **técnico** (en el sentido del principio 8) si el agente **no puede desactivarlo ni esquivarlo desde dentro de su propio entorno de ejecución**. AES define tres capas; los controles fundamentales DEBEN existir al menos en la capa L3.

| Capa | Dónde vive | Qué hace | ¿Lo puede esquivar el agente? |
|---|---|---|---|
| **L1 — Harness** | `opencode.json`, permisos de Claude Code | Niega edición de rutas protegidas, limita comandos. | Parcialmente (bash, config editable). Es **fricción**, no garantía. |
| **L2 — Hooks** | `PreToolUse` / `Stop` en Claude Code; plugins en OpenCode | Bloquea escrituras a rutas protegidas; impide terminar sin pruebas. | Solo si puede editar la configuración de hooks (que debe estar protegida en L1 y L3). |
| **L3 — Fuera del agente** | CI desde ref confiable, protección de rama, CODEOWNERS, montaje de solo lectura, repositorio separado | Ejecuta la suite protegida **desde la rama principal**, verifica integridad y alcance del diff. | **No.** Es el único control que cuenta como gate. |

Reglas operativas:

- **MUST:** La CI ejecuta las pruebas de aceptación obtenidas desde la rama protegida (o verifica su hash contra un manifiesto firmado en ella), nunca desde la rama del agente.
- **MUST:** La configuración del harness, hooks, CI y `AGENTS.md` está en rutas que el programador no puede editar (L1) y cuya modificación hace fallar la CI (L3).
- **SHOULD:** El programador trabaja en un worktree o contenedor donde `tests/acceptance/` está montado como solo lectura o no existe (ver holdout, §4).
- **MUST NOT:** Presentar L1 o L2 como suficientes para un control fundamental.

---

## 3. Pruebas de aceptación: RED confirmado e interfaz acordada (05 §2 ampliado)

### 3.1 Contrato de interfaz antes de las pruebas

QA no puede escribir pruebas útiles sin saber por dónde entrar al sistema. AES fija el orden:

1. **Criterios de aceptación** aprobados (humano).
2. **Contrato de interfaz** (arquitecto/orquestador): el punto de entrada observable que usarán las pruebas. Por defecto, la **frontera externa** del sistema:
   - HTTP/API: método, ruta, payload, códigos de respuesta.
   - CLI: comando, argumentos, salida y código de salida.
   - UI: flujo y selectores estables (`data-testid`) acordados.
   - Librería: firmas públicas mínimas.
3. **Pruebas de aceptación** escritas por QA contra ese contrato.

> **Regla:** Las pruebas de aceptación DEBEN ejercitar comportamiento a través del contrato de interfaz, no detalles internos. Si el programador necesita cambiar el contrato, la tarea pasa a `BLOCKED` y se resuelve por control de cambios; no adapta las pruebas.

Si la interfaz aún no puede definirse (incertidumbre real), se hace primero un **Spike** cuyo resultado es precisamente el contrato.

### 3.2 RED confirmado

Willison lo resume en su capítulo *Red/green TDD*: una prueba que ya pasa antes del cambio no está verificando el código nuevo; el paso rojo demuestra que la prueba puede detectar la funcionalidad ausente.

> **Regla (MUST):** Antes de liberar una historia a implementación, QA ejecuta la suite de aceptación contra la rama base y registra que **cada prueba nueva falla por la razón esperada** (por ejemplo, «404 en `/notifications`», no «error de importación» ni «timeout»). Una prueba nueva que pasa en verde contra la base se considera defectuosa hasta que se justifique.

Este registro (`acceptance-baseline.md` o artefacto de CI) es parte de la DoR de la historia.

### 3.3 Visibles y holdout

> **Regla (SHOULD, MUST para riesgo High/Critical):** La suite de aceptación se divide en:
>
> - **Visibles** (`tests/acceptance/`): el programador puede leerlas y ejecutarlas; le dan el bucle de retroalimentación.
> - **Holdout** (repositorio, rama o directorio no montado en el entorno del programador): variantes de los mismos criterios con datos y casos distintos. Solo las ejecuta la CI y el verificador.

Cuando una prueba holdout falla, el programador recibe **el ID del criterio y el comportamiento observado**, no el código de la prueba. Objetivo: detectar implementaciones ajustadas a los datos visibles (hardcoding) sin bloquear el feedback.

Proporción orientativa: 20–30 % de los escenarios en holdout. El perfil del proyecto la ajusta.

---

## 4. Contexto estructural, no instrucciones genéricas (04 §4 y AGENTS.md)

### Evidencia
TDAD (Alonso, Yovine y Braberman; tesis de maestría en la Universidad ORT Uruguay, arXiv:2603.17973) midió que añadir instrucciones genéricas de TDD a la guía del agente subió la tasa de regresiones de 6,08 % a 9,94 % (+63 %). Darle en cambio un **mapa de qué pruebas afecta cada archivo** la bajó a 1,82 %.

**Matices que AES registra:** se probó con Qwen3-Coder 30B (modelo abierto, no de frontera) sobre 100 tareas de SWE-bench Verified, y la herramienta solo soporta Python. La conclusión transferible no es la cifra, es el principio: *dar información estructural concreta, no procedimientos genéricos.*

### Reglas

- **MUST NOT:** Poner en `AGENTS.md` / `CLAUDE.md` instrucciones de proceso genéricas («usa TDD», «escribe buen código», «ejecuta las pruebas relevantes»).
- **MUST:** Cada tarea incluye **comandos exactos** de validación y la **lista de pruebas de regresión afectadas** (test map) cuando se pueda generar o deducir.
- **MUST:** Primer paso de cada sesión del programador: ejecutar la suite y registrar el **baseline** (pruebas que ya fallaban antes de tocar nada). Así no «arregla» ni se culpa de fallos preexistentes. (Willison: *First run the tests*.)
- **SHOULD:** `AGENTS.md` se mantiene corto: comandos, rutas prohibidas, convenciones que un linter no detecta y fallos observados. Se empieza tarde y crece **una entrada por error real** (ver §9).

---

## 5. Superficie de cambio medida (04 §2 y 05 §5 ampliados)

### Regla
Cada tarea declara su **superficie de cambio**: globs de archivos que puede modificar. La CI (L3) compara el diff contra esa lista.

- Archivos fuera de la superficie → `FAIL` automático, salvo aprobación explícita registrada.
- Lockfiles / manifiestos de dependencias modificados sin aprobación → `FAIL`.
- **SHOULD:** El perfil fija un **presupuesto de diff** orientativo por tarea (p. ej. 300–400 líneas cambiadas). Superarlo no es fallo automático, pero obliga al verificador a justificar por qué no se dividió.

### Detector de trampas (automatizado en CI)

Sobre las líneas **añadidas** del diff, la CI busca y reporta:

| Señal | Ejemplos |
|---|---|
| Pruebas omitidas | `.skip(`, `xit(`, `xdescribe(`, `@Disabled`, `@Ignore`, `#[ignore]`, `pytest.mark.skip`, `[Fact(Skip=` |
| Silenciar analizadores | `eslint-disable`, `@ts-ignore`, `@ts-expect-error`, `# type: ignore`, `#pragma warning disable`, `noqa` |
| Errores tragados | `catch {}` / `catch (e) {}` vacíos, `except: pass` |
| Pruebas borradas | archivos de prueba eliminados o reducción del número de aserciones |
| Cobertura | caída respecto al baseline en archivos tocados |

Las coincidencias no siempre son trampa, pero **siempre** requieren justificación en el reporte de la tarea y revisión del verificador.

### Señales de desvío (checklist del verificador, de Kent Beck)

Beck vigila tres señales para intervenir: bucles innecesarios o el agente atascado repitiendo intentos, funcionalidad no pedida (aunque sea un «siguiente paso razonable») y cualquier indicio de trampa como desactivar o borrar pruebas. AES las incorpora literalmente al contrato del verificador.

---

## 6. Commits estructurales vs. conductuales (04 §7 nuevo)

Tomado de *Tidy First* (Beck):

- **MUST:** Cada commit es **estructural** (refactor sin cambio de comportamiento; todas las pruebas verdes antes y después) **o conductual** (cambia comportamiento). Nunca ambos.
- Prefijo obligatorio: `struct:` / `feat:` / `fix:` / `test:` (el perfil puede mapearlo a Conventional Commits).
- Un refactor estructural fuera de la superficie de la tarea es fuera de alcance, aunque sea «bueno».

Efecto: el verificador y tú pueden revisar los commits `struct:` solo comprobando que las pruebas siguen verdes, y concentrar la lectura en los conductuales.

---

## 7. Tracks proporcionales (02 §8 nuevo)

| Track | Cuándo | Artefactos mínimos | Gate humano |
|---|---|---|---|
| **T0 — Trivial** | Typo, texto, configuración no funcional, bump de dependencia de parche sin cambios de API | Tarea + CI verde | Ninguno previo; lectura rápida del diff |
| **T1 — Bug** | Comportamiento existente incorrecto | Prueba de reproducción **protegida** que falla (RED) + tarea | Aprobar que la prueba describe el comportamiento correcto |
| **T2 — Historia** | Comportamiento nuevo de alcance conocido | Historia, criterios, contrato de interfaz (si aplica), suite de aceptación con RED, tareas | Aprobar criterios; aceptación funcional |
| **T3 — Alto riesgo** | Auth, datos sensibles, pagos, migraciones, cambio arquitectónico, contrato público | Todo T2 + ADR + holdout obligatorio + spike si hay incertidumbre | Criterios, ADR, **revisión humana del código** de las áreas de riesgo, aceptación |

Reglas:

- El orquestador propone el track; tú puedes cambiarlo.
- **Subir** de track durante el trabajo es automático cuando aparece riesgo. **Bajar** requiere justificación registrada.
- En T1 el bug **siempre** se reproduce con una prueba que falla antes del arreglo. Cuando la prueba manual agéntica encuentra un bug (§8), se convierte en T1.

---

## 8. Verificación: evidencia ejecutada y prueba manual agéntica (06 §4 ampliado)

### Evidencia por ejecución, no por narración
Willison recomienda que los agentes documenten sus pruebas con una herramienta que **ejecuta el comando y registra la salida real** (Showboat), porque eso desincentiva fingir resultados.

- **MUST:** La evidencia válida es salida capturada por la CI o por una herramienta que ejecute y registre el comando. Un resumen escrito por el agente es contexto, no evidencia.
- **MUST:** El verificador vuelve a ejecutar las validaciones; no confía en las del programador.

### Prueba manual agéntica
Pasar todas las pruebas no garantiza que el programa arranque o que un elemento de la interfaz sea visible.

- **SHOULD (MUST en T2/T3 con interfaz de usuario):** El verificador arranca la aplicación y ejercita los flujos de los criterios: `curl` contra la API, Playwright para la interfaz (con capturas), ejecución real de la CLI.
- Las capturas y salidas se adjuntan al reporte de verificación.
- Un defecto encontrado así se registra como T1 y se arregla con RED/GREEN, para que quede como prueba permanente.

---

## 9. Circuit breaker e higiene de contexto (04 §6 ampliado)

- **MUST:** Una sesión nueva por tarea. No se reutiliza el contexto de una tarea anterior.
- **MUST:** Si una misma tarea acumula **3 ciclos `FAIL`** (verificador o CI), se detiene. No hay cuarto intento automático. El orquestador clasifica la causa:
  - tarea mal especificada o demasiado grande → volver a refinamiento;
  - prueba de aceptación incorrecta → control de cambios con QA;
  - problema de diseño → arquitecto / spike;
  - limitación del modelo → reasignar o escalar a ti.
- **SHOULD:** Si el agente repite el mismo enfoque fallido dos veces seguidas, se reinicia el contexto con un resumen escrito de lo aprendido en vez de compactar. (Compactar conserva los supuestos erróneos.)

---

## 10. Bucle de mejora del harness (nuevo standard/09)

Anthropic recomienda construir skills **después** de evaluar: ejecutar el agente en tareas representativas, ver dónde falla y cerrar esas brechas de forma incremental. Willison describe el mismo principio como el «paso compuesto»: cada proyecto termina con una retrospectiva que mejora las instrucciones de las siguientes ejecuciones.

### Regla
- **MUST:** Mantener `docs/agent-failure-log.md`. Cada fallo relevante de un agente se registra.
- **MUST:** Al cerrar cada historia T2/T3, el orquestador revisa el log y propone **un control** por patrón recurrente, preferentemente en este orden de dureza:
  1. prueba o chequeo en CI (L3);
  2. hook (L2);
  3. permiso del harness (L1);
  4. skill con procedimiento específico;
  5. una línea en `AGENTS.md`.
- Los cambios a `AGENTS.md`, hooks, skills y CI siguen requiriendo tu aprobación (06 §8).

### Plantilla de entrada

```markdown
## FL-007 — 2026-11-02
- Agente / modelo: programador / OpenCode + [modelo]
- Tarea: TASK-014 (US-005)
- Síntoma: añadió paginación no pedida al listado de notificaciones
- Detectado por: verificador (checklist «funcionalidad no pedida»)
- Causa probable: la tarea no tenía «Fuera de alcance» explícito
- Control añadido: plantilla de tarea exige «Fuera de alcance» no vacío en T2/T3 (DoR)
- Verificado en: TASK-019 (sin recurrencia)
```

### Seguridad de skills
Solo se instalan skills de fuentes confiables; las de terceros se auditan (archivos incluidos, scripts, dependencias, conexiones externas) antes de usarlas. Una skill nunca concede permisos (ya en 06 §6).

---

## 11. Qué revisas tú (00 §5 ampliado)

Willison establece una regla dura: no abrir pull requests con código que uno mismo no haya revisado. Tu objetivo es otro: verificar comportamiento sin leer cada línea. AES lo reconcilia moviendo tu revisión **del código a los contratos**:

> **Si no vas a leer el código, lee las pruebas.** La suite de aceptación es lo único en lo que confías ciegamente; por tanto es lo que tú SÍ apruebas.

| Momento | Qué revisas | T0 | T1 | T2 | T3 |
|---|---|---|---|---|---|
| Antes | Criterios de aceptación y exclusiones | — | ✓ | ✓ | ✓ |
| Antes | Pruebas de aceptación (al menos nombres de escenarios y aserciones clave) | — | ✓ | ✓ | ✓ |
| Antes | Contrato de interfaz / ADR | — | — | si cambia | ✓ |
| Después | Reporte de verificación + evidencias (capturas, salidas) | — | ✓ | ✓ | ✓ |
| Después | Alertas del detector de trampas y de superficie | si hay | si hay | si hay | ✓ |
| Después | Código | diff rápido | opcional | solo áreas señaladas | **áreas de riesgo, obligatorio** |
| Después | Demo / prueba funcional propia | — | — | ✓ | ✓ |

Esto es honesto con el riesgo: en T3 no hay forma responsable de saltarse la lectura del código sensible.

---

## 12. Ciclo AES 1.1 completo

```
0. Clasificar track (T0–T3)                          [orquestador → tú confirmas]
1. Refinar historia: criterios + fuera de alcance     [orquestador → tú apruebas]
2. Contrato de interfaz (si hay frontera nueva)       [arquitecto → tú si es material]
3. QA: pruebas visibles + holdout
   → ejecutar contra base → RED confirmado → commit en rama protegida
4. Tareas: superficie, comandos exactos, test map     [orquestador]
5. Programador (sesión nueva por tarea):
   baseline → RED/GREEN/REFACTOR → commits struct/feat → reporte
6. CI (L3): aceptación desde ref confiable, holdout,
   superficie, detector de trampas, lint, tipos, seguridad
7. Verificador (sesión limpia, solo lectura):
   spec + diff + CI → re-ejecución → prueba manual agéntica → PASS/FAIL/BLOCKED
   └─ 3 FAIL → circuit breaker
8. Tú: reporte + evidencias + demo (+ código en T3)  → Accepted / Rejected
9. Retro compuesta: failure log → un control nuevo por patrón
```

---

## 13. Implementación de referencia

> Configuraciones verificadas contra la documentación pública a noviembre de 2026. **Comprobar contra la versión instalada:** OpenCode v2 cambió la sintaxis de permisos (`permissions` como lista de reglas `action/resource/effect`).

### 13.1 OpenCode — agente programador (sintaxis v1)

En OpenCode la última regla que coincide gana, así que el comodín va primero.

```jsonc
// opencode.json (en ruta protegida)
{
  "$schema": "https://opencode.ai/config.json",
  "agent": {
    "programmer": {
      "permission": {
        "edit": {
          "*": "allow",
          "tests/acceptance/**": "deny",
          "specs/**": "deny",
          ".github/**": "deny",
          "ci/**": "deny",
          ".claude/**": "deny",
          "opencode.json": "deny",
          "AGENTS.md": "deny"
        },
        "bash": {
          "*": "ask",
          "npm test*": "allow",
          "npm run lint*": "allow",
          "git status": "allow",
          "git diff*": "allow",
          "git add*": "allow",
          "git commit*": "allow",
          "git push*": "deny",
          "rm *": "deny"
        },
        "webfetch": "deny"
      }
    },
    "verifier": {
      "permission": {
        "edit": "deny",
        "bash": {
          "*": "ask",
          "npm test*": "allow",
          "git diff*": "allow",
          "git log*": "allow",
          "npx playwright*": "allow"
        }
      }
    }
  }
}
```

Recordatorio: esto es **L1**. `bash` sigue pudiendo escribir archivos; por eso existe la §13.3.

### 13.2 Claude Code — hooks (L2)

`PreToolUse` con código de salida 2 bloquea la herramienta y devuelve el mensaje de stderr al modelo. `Stop` puede impedir que el agente termine; el campo `stop_hook_active` evita el bucle infinito.

```json
// .claude/settings.json
{
  "hooks": {
    "PreToolUse": [
      { "matcher": "Edit|Write|MultiEdit",
        "hooks": [{ "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/protect-paths.sh" }] }
    ],
    "Stop": [
      { "hooks": [{ "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/require-green.sh" }] }
    ]
  }
}
```

```bash
#!/usr/bin/env bash
# .claude/hooks/protect-paths.sh
f=$(jq -r '.tool_input.file_path // empty')
case "$f" in
  */tests/acceptance/*|*/specs/*|*/.github/*|*/ci/*|*/.claude/*|*/AGENTS.md|*/opencode.json)
    echo "AES: '$f' es ruta protegida. Requiere flujo QA/orquestador aprobado." >&2
    exit 2 ;;
esac
exit 0
```

```bash
#!/usr/bin/env bash
# .claude/hooks/require-green.sh — no terminar con pruebas rojas (una sola vez)
input=$(cat)
[ "$(echo "$input" | jq -r '.stop_hook_active')" = "true" ] && exit 0
if ! npm test --silent >/dev/null 2>&1; then
  echo "AES: hay pruebas fallando. Corrígelas o reporta BLOCKED con la causa." >&2
  exit 2
fi
exit 0
```

Nota: en una sesión de QA (que sí escribe `tests/acceptance/`) se usa otra configuración o worktree; las rutas protegidas lo son para el rol programador.

### 13.3 CI — guardián AES (L3, el único que cuenta)

Se ejecuta con el script obtenido de la rama protegida, nunca de la rama del agente.

```bash
#!/usr/bin/env bash
# ci/aes-guard.sh — invocado por un workflow que hace checkout de main para ci/
set -euo pipefail
BASE="${BASE_REF:-origin/main}"
TASK_SCOPE="${TASK_SCOPE_FILE:?ruta al .scope de la tarea}"   # globs, uno por línea
fail=0
changed=$(git diff --name-only "$BASE"...HEAD)

# 1. Rutas protegidas
if echo "$changed" | grep -qE '^(tests/acceptance/|specs/|\.github/|ci/|\.claude/|AGENTS\.md|opencode\.json)'; then
  echo "FAIL: el diff modifica rutas protegidas:"; echo "$changed" | grep -E '^(tests/acceptance/|specs/|\.github/|ci/|\.claude/|AGENTS\.md|opencode\.json)'
  fail=1
fi

# 2. Superficie de cambio declarada
while IFS= read -r file; do
  ok=0
  while IFS= read -r glob; do
    [[ -z "$glob" || "$glob" == \#* ]] && continue
    [[ "$file" == $glob ]] && { ok=1; break; }
  done < "$TASK_SCOPE"
  [[ $ok -eq 0 ]] && { echo "FAIL: fuera de superficie: $file"; fail=1; }
done <<< "$changed"

# 3. Detector de trampas (solo líneas añadidas)
added=$(git diff "$BASE"...HEAD -U0 | grep -E '^\+[^+]' || true)
if echo "$added" | grep -nE '\.skip\(|xit\(|xdescribe\(|@Disabled|@Ignore|#\[ignore\]|pytest\.mark\.skip|Skip *=|eslint-disable|@ts-ignore|@ts-expect-error|# *type: *ignore|#pragma warning disable|noqa'; then
  echo "REVIEW: marcadores de omisión/silenciado. Requieren justificación en el reporte."
  fail=1
fi

# 4. Pruebas borradas
if git diff --name-status "$BASE"...HEAD | grep -E '^D' | grep -qiE 'test|spec'; then
  echo "FAIL: se eliminaron archivos de prueba."; fail=1
fi

# 5. Ejecutar aceptación desde la versión confiable
git checkout "$BASE" -- tests/acceptance/
echo "Suite de aceptación restaurada desde $BASE"

exit $fail
```

Complementos en el repositorio: protección de rama en `main` (sin push directo, CI obligatoria), `CODEOWNERS` con tu usuario sobre `tests/acceptance/`, `specs/`, `ci/`, `.github/`, `.claude/`, `AGENTS.md`, `opencode.json`.

### 13.4 Plantilla de tarea — campos añadidos

```markdown
## Track: T2
## Superficie de cambio (globs)
src/notifications/**
src/api/routes/notifications.ts
tests/unit/notifications/**

## Fuera de alcance (obligatorio en T2/T3)
- Envío de correos, push, preferencias de notificación
- Paginación (US-007)

## Comandos de validación exactos
npm test -- tests/unit/notifications
npm run test:acceptance -- --grep "US-005"
npm run lint && npm run typecheck

## Pruebas de regresión afectadas (test map)
tests/unit/auth/session.test.ts
tests/acceptance/US-002-inbox.spec.ts

## Presupuesto de diff orientativo: ~250 líneas
```

---

## 14. Cambios por archivo

| Archivo | Cambio |
|---|---|
| `standard/00` | Principio 13 (prosa vs. pruebas); §5 tabla «Qué revisa el humano». |
| `standard/02` | §8 Tracks T0–T3. |
| `standard/04` | Superficie de cambio; comandos exactos y test map; baseline; commits struct/feat; circuit breaker; sesión nueva por tarea. |
| `standard/05` | Contrato de interfaz; RED confirmado; visibles + holdout; detector de trampas. |
| `standard/06` | §9 Modelo de controles L1/L2/L3; evidencia ejecutada; prueba manual agéntica; prohibición de instrucciones genéricas en AGENTS.md. |
| `standard/08` | DoR historia: RED confirmado, contrato de interfaz, track. DoR tarea: superficie, comandos, fuera de alcance. DoD tarea: commits separados, detector sin alertas sin justificar. |
| `standard/09` *(nuevo)* | Bucle de mejora del harness y failure log. |
| `agent-contracts/qa-test-designer` | RED confirmado, holdout, escribir contra contrato de interfaz. |
| `agent-contracts/programmer` | Baseline, commits separados, superficie, prohibición de editar config de agentes. |
| `agent-contracts/verifier` | Re-ejecución, señales de Beck, prueba manual agéntica, holdout. |
| `agent-contracts/orchestrator` | Clasificar track, circuit breaker, retro compuesta. |
| `templates/task.md` | Campos de §13.4. |
| `templates/agent-failure-log.md` *(nuevo)* | Plantilla de §10. |
| `templates/project-profile.template.md` | Capas L1/L2/L3 implementadas, proporción holdout, presupuesto de diff, mapeo de tracks. |
| `profiles/reference/` *(nuevo)* | Los archivos de §13 como implementación de referencia Claude Code + OpenCode. |

---

## 15. Fuentes

- Simon Willison — *Agentic Engineering Patterns* (capítulos *Red/green TDD*, *First run the tests*, *Agentic manual testing*, *Anti-patterns*, *AI should help us produce better code*): https://simonwillison.net/guides/agentic-engineering-patterns/
- Kent Beck — *Augmented Coding: Beyond the Vibes* (resumen): https://kentbeck.com/summaries/augmented-coding-beyond-the-vibes/
- The Pragmatic Engineer — *TDD, AI agents and coding with Kent Beck*: https://newsletter.pragmaticengineer.com/p/tdd-ai-agents-and-coding-with-kent
- Daniel Vaughan — *TDAD and the testing revolution* (sobre arXiv:2603.17973): https://codex.danielvaughan.com/premium-pdfs/04-tdad-and-the-testing-revolution.pdf
- Birgitta Böckeler — *Understanding Spec-Driven-Development: Kiro, spec-kit, and Tessl*: https://www.martinfowler.com/articles/exploring-gen-ai/sdd-3-tools.html
- Anthropic — *Equipping agents for the real world with Agent Skills*: https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills
- OpenHands — *Claude Code best practices*: https://www.openhands.dev/blog/claude-code-best-practices-agentic-coding
- Claude Code — documentación de hooks: https://docs.anthropic.com/en/docs/claude-code/hooks
- OpenCode — permisos: https://opencode.ai/docs/permissions/
