# uptcbot

Asistente local sobre programas de pregrado de la UPTC (sede Tunja) usando
**Gemma 4 E2B** acelerado por **MLX** en Apple Silicon. La base de conocimiento
se inyecta como contexto en el prompt (RAG simple, sin fine-tuning).

El modelo se carga desde una copia local en `Model/` — no requiere internet
después del setup inicial.

## Requisitos

- Mac con Apple Silicon (M1+)
- macOS 14+
- Swift 6.1+ (incluido con Xcode 16+)
- ~4 GB libres en disco para los pesos del modelo

## Setup (primera vez)

```bash
cd ~/Projects/inteligencia
bash scripts/download_model.sh                       # ~3.6 GB desde Hugging Face
xcodebuild -downloadComponent MetalToolchain         # ~688 MB, Xcode 26+
```

> **Importante:** `swift build` / `swift run` no funcionan porque SwiftPM
> CLI **no compila shaders Metal** y MLX los necesita en runtime. Hay que
> usar `xcodebuild` (o Xcode.app). El wrapper de abajo automatiza eso.

## Correr

```bash
bash scripts/run_cli.sh
```

El script compila vía `xcodebuild`, localiza el binario en `DerivedData/` y lo
ejecuta apuntando `UPTC_MODEL_PATH` a `./Model/`.

Se abre un prompt interactivo. Ctrl+D para salir.

```
> ¿Qué facultades de la UPTC están en Tunja?
[respuesta streaming...]
>
```

## Variable de entorno opcional

Si quieres tener el modelo en otra carpeta (compartido entre proyectos, disco
externo, etc.):

```bash
UPTC_MODEL_PATH=/Volumes/Externo/gemma-4-e2b swift run -c release uptcbot
```

## Estructura

```
Package.swift
Sources/uptcbot/
  main.swift                        # CLI loop + carga modelo
  Knowledge.swift                   # Formatea JSON → contexto
  Resources/programas_uptc.json     # 32 programas UPTC Tunja
Model/                              # Pesos Gemma 4 E2B (gitignored, 3.6 GB)
scripts/download_model.sh           # Re-descarga si falta Model/
```

## Próximos pasos

- Reemplazar contexto completo por retrieval con embeddings (`MLXEmbedders`)
  cuando el corpus crezca.
- Completar campos vacíos del JSON scrapeando micrositios oficiales por programa.
- Envolver en SwiftUI para `.app` distribuible (en ese caso, el modelo iría
  dentro del bundle `.app` en vez de en `Model/`).
