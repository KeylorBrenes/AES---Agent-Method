# 09 — Mejora continua del harness

## 1. Objetivo

Convertir los fallos observados de los agentes en controles permanentes, de modo que el mismo error no dependa de que alguien lo recuerde ni de que se repita una instrucción en cada sesión.

Anthropic recomienda construir skills **después** de evaluar: ejecutar el agente en tareas representativas, observar dónde falla y cerrar esas brechas de forma incremental. Simon Willison describe el mismo principio como el «paso compuesto»: cada proyecto termina con una retrospectiva que mejora las instrucciones de las ejecuciones siguientes. AES formaliza ambos.

## 2. Registro de fallos de agentes

Cada proyecto MUST mantener `docs/agent-failure-log.md` (plantilla en `templates/agent-failure-log.md`).

Se registra un fallo cuando un agente:

- implementa funcionalidad no pedida o sale de su superficie de cambio;
- intenta debilitar, omitir o modificar pruebas;
- afirma resultados que no ejecutó;
- entra en bucles de corrección o activa el circuit breaker (04 §9);
- inventa APIs, estructuras o requisitos;
- introduce complejidad, dependencias o abstracciones injustificadas;
- comete un error de convención del proyecto que se repite.

Cada entrada describe síntoma, cómo se detectó, causa probable y el control que se añadió. No se registran juicios sobre el modelo, sino hechos observables.

## 3. Retrospectiva compuesta

Al cerrar cada historia T2/T3 y cada lote de estabilización, y al menos una vez por cada grupo de trabajo T0/T1, el orquestador MUST:

1. revisar las entradas nuevas del registro;
2. identificar patrones (un fallo repetido dos veces es un patrón);
3. proponer **un control por patrón**, eligiendo el más duro que sea razonable, en este orden:
   1. prueba o chequeo en CI (L3);
   2. hook (L2);
   3. permiso del harness (L1);
   4. skill con un procedimiento específico;
   5. una línea en `AGENTS.md`/`CLAUDE.md`;
4. presentar la propuesta al responsable humano, que la aprueba o la rechaza (06 §8);
5. tras aplicarla, registrar en qué tarea posterior se verificó que el fallo no se repite.

Una línea en las instrucciones persistentes es el control más débil: el agente puede ignorarla o perderla al compactar contexto. Se usa cuando no hay forma razonable de automatizar la detección.

La retrospectiva es breve: patrones, un control por patrón y decisiones abiertas. El detalle ya está en el registro de hallazgos y en el de fallos; copiarlo a la retrospectiva duplica el costo de redacción del orquestador.

## 4. Evaluación de cambios al harness

Los cambios a instrucciones persistentes, skills, hooks o permisos SHOULD comprobarse con al menos una tarea representativa antes de darse por buenos. Una instrucción que no cambia el comportamiento observado se elimina: ocupa contexto sin aportar.

## 5. Higiene de las instrucciones persistentes

- Revisar periódicamente `AGENTS.md`/`CLAUDE.md` y eliminar entradas que ya cubre un control más duro.
- Mantener el archivo breve; si crece, mover procedimientos a skills y dejar solo el puntero.
- No acumular reglas contradictorias: una entrada nueva que contradice otra la sustituye explícitamente.

## 6. Evidencia del proceso y métricas

Además del registro de fallos, cada proyecto SHOULD mantener un **registro de hallazgos del proceso** (`docs/harness-findings.md`, plantilla en `templates/harness-findings.md`): fricciones, confirmaciones de que un control funcionó, huecos de control y costos. Es la materia prima de las retrospectivas y de las propuestas de cambio a AES.

Por cada elemento cerrado (historia, enabler, lote) se registra una fila de métricas:

| Elemento | Inicio | Fin | Modelo real por rol | Ciclos FAIL | Intervenciones humanas | Bloqueos de controles | Costo | Tiempo |
|---|---|---|---|---|---|---|---|---|

- **Modelo real por rol:** el que ejecutó, no el que declara el perfil (06 §11).
- **Intervenciones humanas:** cada vez que el humano decidió, aprobó, corrigió o desbloqueó algo.
- **Bloqueos de controles:** de hooks, permisos y clasificadores del harness, por separado. Un control que nunca bloquea puede estar funcionando o no estar probado; un control que bloquea mucho puede estar mal calibrado.
- **Costo:** el que reporta el harness. Si solo el humano puede consultarlo, el orquestador se lo pide al cerrar.

## 7. Notas durante el ciclo

- Los hallazgos, fallos y decisiones se anotan **en el momento**, con la hora real que da un comando, no con una hora escrita por el agente. En el sandbox de AES, el orquestador escribió horas estimadas, algunas por delante del reloj.
- Las notas en curso viven fuera del control de versiones (por ejemplo, `.aes/`) y se consolidan en los registros versionados en el cierre del elemento. Así no se cuelan en los PR de tareas, donde el guardián las rechazaría por estar fuera de la superficie.
- La creación y el vaciado de las notas los hace un script, no un rol: si un rol no puede escribir en esa carpeta, la consolidación no debe depender de que pueda.
