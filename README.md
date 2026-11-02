# Agentic Engineering Standard (AES)

**Versión:** 1.0.0  
**Estado:** Estándar inicial  
**Idioma normativo:** Español  
**Propósito:** establecer un proceso de ingeniería consistente para desarrollar y mantener software con agentes de IA, sin depender de un proveedor, modelo, harness o stack específico.

## Qué es AES

AES es un estándar de trabajo para proyectos de software asistidos por agentes. Define cómo descubrir y planificar el producto, mantener la arquitectura, organizar el backlog, especificar historias, dividir tareas, probar, verificar, aprobar y registrar cambios.

AES no es un generador automático de requisitos ni una metodología de cascada. La planificación es progresiva: se define con mayor detalle el trabajo próximo y se conserva una visión suficiente del producto y de su arquitectura.

## Principios de uso

1. Leer `standard/00-governance-and-principles.md` antes de iniciar un proyecto.
2. Declarar la versión de AES y completar un perfil en `profiles/` para cada proyecto.
3. Adaptar las herramientas al proyecto; no cambiar los controles fundamentales sin una excepción documentada.
4. Usar las plantillas como punto de partida. No rellenar campos irrelevantes por formalidad.
5. Mantener la trazabilidad: objetivo → Epic → Historia de Usuario → criterios de aceptación → tareas → pruebas → evidencia → aceptación.
6. Trabajar en incrementos pequeños y verificables. No planificar en detalle trabajo lejano que aún depende de aprendizaje.

## Estructura

- `standard/`: reglas normativas de AES Core.
- `templates/`: plantillas reutilizables para artefactos del proyecto.
- `agent-contracts/`: responsabilidades, permisos y límites de cada rol.
- `profiles/`: configuración específica del proyecto y su stack.

## Palabras normativas

- **MUST / DEBE:** requisito obligatorio.
- **MUST NOT / NO DEBE:** prohibición.
- **SHOULD / DEBERÍA:** regla esperada; una excepción requiere razón registrada.
- **SHOULD NOT / NO DEBERÍA:** práctica que se evita salvo justificación.
- **MAY / PUEDE:** opción permitida.

Estas palabras describen la fuerza de la regla, no una herramienta particular.

## Inicio rápido

1. Copiar AES al repositorio o referenciar una versión fija.
2. Completar `profiles/project-profile.md` a partir de `profiles/project-profile.template.md`.
3. Documentar visión y contexto con `templates/project-brief.md`.
4. Describir la arquitectura conocida y registrar decisiones importantes con ADR.
5. Crear un backlog inicial de Epics. Refinar solo las Historias de Usuario próximas.
6. Para cada Historia de Usuario, aprobar criterios de aceptación antes de implementar.
7. Diseñar pruebas protegidas, dividir la historia en tareas pequeñas y ejecutar el ciclo.
8. No cerrar la historia hasta cumplir la Definition of Done y registrar la aceptación correspondiente.

## Versionado

AES utiliza versionado semántico:

- **MAJOR:** incompatibilidad en reglas fundamentales o estructura normativa.
- **MINOR:** nuevas reglas o capacidades compatibles.
- **PATCH:** aclaraciones, correcciones y mejoras que no cambian el significado normativo.

Cada proyecto declara la versión de AES que adopta. Una actualización no se aplica silenciosamente: se revisa y se registra en el proyecto.

## Alcance de la versión 1.0.0

AES 1.0.0 establece el ciclo de ingeniería, planificación por backlog, estimación relativa con Fibonacci, diseño de tareas pequeñas, ATDD/TDD, gobierno de agentes, permisos, verificación y aceptación. No prescribe lenguajes, frameworks, proveedores de modelos, herramientas de seguimiento ni una arquitectura de software universal.
