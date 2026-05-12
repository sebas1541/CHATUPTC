# UPTCBot

Asistente local sobre programas de pregrado de la **Universidad Pedagógica
y Tecnológica de Colombia (UPTC)**, sede central Tunja.

Corre **100% local** en Apple Silicon usando una versión **fine-tuneada**
de **Gemma 4 E4B-it** con QLoRA sobre un dataset propio de Q&A
institucional UPTC, más una capa de **RAG** sobre el catálogo
estructurado de los 32 programas presenciales.

Sin internet, sin nube, sin que tus consultas salgan del Mac.

<p align="center">
  <img src="Sources/UPTCBotApp/Resources/logouptc.png" width="160" alt="UPTCBot logo">
</p>

---

## Stack

| Capa | Tecnología |
|---|---|
| Modelo base | **Gemma 4 E4B-it** (Effective 4 Billion, instruction-tuned) — Google, Hugging Face |
| Fine-tuning | **Unsloth / Unsloth Studio** (UI sin código) — método **QLoRA** 4-bit |
| Infraestructura de entrenamiento | **RunPod** con GPU **A40** (48 GB VRAM) |
| Entorno | **JupyterLab** + Unsloth Studio en terminal |
| Dataset | Q&A propio de UPTC (`dataset/`) — formato inspirado en Bitext Customer Support |
| Publicación del modelo | **Hugging Face Hub** (subida pendiente, se hará al cerrar el entrenamiento) |
| Inferencia local | **MLX Swift** (Apple Silicon, GPU + Neural Engine) |
| RAG en runtime | Catálogo de 32 programas + 22 docs de análisis inyectados como contexto |
| UI | **SwiftUI** + macOS 26 (Liquid Glass) |
| Persistencia de chats | `~/Documents/UPTCBot/conversations.json` |

## Cómo se entrenó

```
                ┌──────────────────────┐
                │   Gemma 4 E4B-it     │
                │   (base de Google)   │
                └──────────┬───────────┘
                           │
                           ▼
              ┌──────────────────────────┐
              │  dataset/train.jsonl     │
              │  dataset/validation.jsonl│
              │  (50 + 10 ejemplos Q&A)  │
              └──────────┬───────────────┘
                         │
                         ▼
        ┌────────────────────────────────────┐
        │  RunPod A40 (48 GB VRAM)           │
        │  └── JupyterLab terminal           │
        │      └── Unsloth Studio (UI)       │
        │          └── QLoRA 4-bit           │
        │              · 3 epochs            │
        │              · lr 2e-4             │
        │              · rank 16             │
        └────────────────┬───────────────────┘
                         │
                         ▼
            ┌──────────────────────────────┐
            │  Modelo merged + adapter     │
            │  → Hugging Face Hub          │
            │  (sebas1541/uptcbot-gemma4)  │
            └──────────────┬───────────────┘
                           │
                           ▼
              ┌────────────────────────┐
              │  Local: convertido a   │
              │  MLX 4-bit en `Model/` │
              └────────────────────────┘
```

El dataset (`dataset/`) cubre 16 tipos de intent y 5 categorías. Comportamientos
clave entrenados: no inventar datos sensibles (SNIES, créditos, costos),
asistente no oficial que redirige a uptc.edu.co cuando corresponde, y
respuestas estructuradas y concisas en español.

Más detalle en [`dataset/README.md`](dataset/README.md).

---

## Cómo correrlo en tu Mac

### Requisitos

- Mac con Apple Silicon (M1+)
- macOS 14 Sonoma o superior
- Xcode 16+ con Metal Toolchain
- ~4 GB libres en disco para los pesos del modelo

### Setup (primera vez)

```bash
cd ~/Projects/inteligencia
bash scripts/download_model.sh                       # descarga ~3.6 GB del modelo
xcodebuild -downloadComponent MetalToolchain         # Metal toolchain de Xcode 26
```

> **Por qué `xcodebuild` y no `swift build`:** el SwiftPM CLI no compila
> los shaders Metal que MLX necesita en runtime. Los scripts del proyecto
> usan `xcodebuild` directamente, transparente para ti.

### Correr la app

```bash
bash scripts/run_app.sh
```

Abre la ventana de SwiftUI con sidebar de conversaciones persistentes,
chat estilo ChatGPT, soporte de imágenes vía drag & drop, y todo el modelo
corriendo en local.

### Correr el CLI (debug)

```bash
bash scripts/run_cli.sh
```

Prompt interactivo en terminal. Útil para debugging.

---

## Estructura del repo

```
.
├── README.md                              # este archivo
├── Package.swift                          # SwiftPM
├── dataset/                               # Dataset de fine-tuning
│   ├── README.md
│   ├── train.jsonl                        # 50 ejemplos
│   └── validation.jsonl                   # 10 ejemplos
├── Sources/
│   ├── UPTCBotKit/                        # Library compartida (CLI + App)
│   │   ├── Knowledge.swift                # Formatea JSON → system prompt RAG
│   │   ├── ModelService.swift             # Carga Gemma 4 vía MLXVLM
│   │   └── Resources/
│   │       ├── programas_uptc.json        # Catálogo de 32 programas
│   │       └── analysis_docs.json         # 22 docs de análisis temático
│   ├── UPTCBotApp/                        # App SwiftUI macOS
│   │   ├── UPTCBotApp.swift               # @main
│   │   ├── ContentView.swift              # NavigationSplitView
│   │   ├── SidebarView.swift              # Chats persistentes
│   │   ├── ChatDetailView.swift           # Burbujas + composer + drag&drop
│   │   ├── ChatViewModel.swift            # Streaming + KV cache
│   │   ├── ComposerView.swift             # Input con + menu para imágenes
│   │   ├── MessageView.swift              # Renderiza markdown + thumbnails
│   │   ├── ConversationStore.swift        # Persistencia JSON
│   │   ├── UPTCLogo.swift                 # Componente del logo
│   │   └── Resources/logouptc.png         # Logo del cóndor
│   └── uptcbot/                           # CLI executable
│       └── main.swift
├── scripts/
│   ├── download_model.sh
│   ├── run_app.sh
│   ├── run_cli.sh
│   ├── build_app.sh                       # Empaca UPTCBot.app
│   └── make_dmg_background.py             # Background custom del DMG
├── Model/                                 # Pesos MLX (gitignored, 3.4 GB)
├── build/                                  # AppIcon.icns + DMG assets (gitignored)
└── dist/                                   # UPTCBot.app empacada (gitignored)
```

## Distribución (DMG)

### Generar el DMG

```bash
bash scripts/build_app.sh                  # arma dist/UPTCBot.app (~3.5 GB)
# luego, con create-dmg:
create-dmg --volname "UPTCBot" \
           --volicon build/AppIcon.icns \
           --background build/dmg-background.png \
           --window-pos 200 120 --window-size 660 420 \
           --icon-size 96 \
           --icon "UPTCBot.app" 165 220 \
           --hide-extension "UPTCBot.app" \
           --app-drop-link 495 220 \
           /tmp/UPTCBot.dmg dist/
mv /tmp/UPTCBot.dmg ~/Desktop/UPTCBot.dmg
```

El DMG resultante tiene un fondo custom con flecha hacia Applications, ícono
del cóndor como volumen, y queda en ~2.6 GB comprimido.

> Nota técnica: `create-dmg` no puede escribir directo a `~/Desktop` por
> permisos sandbox de macOS — créalo en `/tmp/` y muévelo con `mv`.

### Cómo instalar UPTCBot (instrucciones para el usuario final)

1. **Abre** `UPTCBot.dmg` haciendo doble click.
2. **Arrastra** `UPTCBot.app` hacia la carpeta `Applications` en la ventana
   del DMG.
3. **Cierra** el DMG (no dejes el `.app` en el DMG montado, ejecútalo desde
   `/Applications`).

### Primera apertura — bypass de Gatekeeper

Como esta app **no está firmada con Apple Developer ID** (cuesta $99/año),
la primera vez que la abras macOS bloqueará la ejecución:

> *"UPTCBot" cannot be opened because Apple cannot check it for malicious
> software. macOS cannot verify that this app is free from malware.*
>
> [ Move to Trash ] [ Done ]

**NO pulses "Move to Trash".** Pulsa "Done" y sigue estos pasos:

1. **Abre System Settings** (icono del engranaje en el Dock o en
   `/Applications`).
2. Ve a **Privacy & Security** en la barra lateral izquierda.
3. **Baja hasta la sección "Security"** (al final, antes de "Advanced").
4. Verás un mensaje:
   > *"UPTCBot.app" was blocked from use because it is not from an identified
   > developer.*
5. Click en **"Open Anyway"** al lado derecho de ese mensaje.
6. macOS te volverá a pedir confirmación → click **"Open Anyway"** otra vez.
7. Ingresa tu **contraseña / Touch ID** si lo pide.

La app se abrirá y empezará a cargar el modelo (~10–30s la primera vez).
Después de este primer permiso, las siguientes aperturas son normales con
doble click.

#### Alternativa rápida (Terminal)

Si prefieres saltarte los menús, una sola línea desde Terminal hace lo
mismo:

```bash
xattr -dr com.apple.quarantine /Applications/UPTCBot.app
```

Esto quita el atributo de cuarentena que macOS asigna a apps descargadas, y
después puedes abrirla con doble click normal sin warnings.

---

## Próximos pasos

- [ ] Subir el modelo merged a Hugging Face (`sebas1541/uptcbot-gemma4`)
- [ ] Expandir el dataset a ~500 ejemplos para mejor robustez del fine-tune
- [ ] Reemplazar context-stuffing por retrieval real con `MLXEmbedders` cuando
      el catálogo crezca
- [ ] Firma con Developer ID + notarización para distribución sin warnings

---

## Créditos

- **Modelo base:** Google DeepMind (Gemma 4 E4B-it)
- **Pipeline de fine-tuning:** Unsloth (open source)
- **GPU:** RunPod
- **Inferencia local:** MLX (Apple) + MLX Swift (Apple ML Research)
- **Datos UPTC:** Anexo PILA 2024-1, micrositios oficiales por programa,
  documento del Ministerio de Educación Nacional

Asistente **NO oficial**. La información puede tener errores. Verifica
siempre los datos sensibles en [uptc.edu.co](https://www.uptc.edu.co).
