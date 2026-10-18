---
title: Demo del Vistazo MD
autor: David
---

# Vistazo MD

Una vista rápida **propia** para *macOS*, con `código en línea`, ~~tachado~~ y [enlaces](https://github.com).

## Listas

- Elemento uno
- Elemento dos
  - Anidado
1. Primero
2. Segundo

### Tareas

- [x] Crear la extensión de Quick Look
- [ ] Añadir diagramas Mermaid

## Tabla

| Formato | Soportado | Notas |
|:--------|:---------:|------:|
| Tablas  | ✅ | GFM |
| Código  | ✅ | highlight.js |

## Código

```swift
struct Saludo {
    let nombre: String
    func decir() -> String { "Hola, \(nombre)!" }
}
```

```python
def fib(n):
    return n if n < 2 else fib(n - 1) + fib(n - 2)
```

> Una cita, con **énfasis** dentro.

---

<details><summary>HTML incrustado</summary>Contenido plegable.</details>

<script>document.body.innerHTML = "esto no debería ejecutarse"</script>
