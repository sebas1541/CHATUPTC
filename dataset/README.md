# Dataset de fine-tuning — UPTCBot

Dataset propio construido para fine-tunear Gemma 4 E4B-it sobre el dominio
específico de programas de pregrado de la UPTC (sede Tunja).

## Archivos

| Archivo | Ejemplos | Propósito |
|---|---|---|
| `train.jsonl` | 50 | Entrenamiento (90%) |
| `validation.jsonl` | 10 | Validación durante el entrenamiento (10%) |

## Schema

Cada línea es un objeto JSON independiente con cuatro campos:

```jsonl
{
  "instruction": "Pregunta del usuario en español",
  "response": "Respuesta esperada del asistente",
  "intent": "etiqueta_tecnica_del_tipo_de_consulta",
  "category": "categoria_amplia"
}
```

Inspirado en el formato del dataset **Bitext Customer Support** de Hugging
Face — `instruction`/`response` son el par para el SFT, y los campos
`intent`/`category` se mantienen como metadata por si en el futuro se hace
classification head o se filtran ejemplos por tipo.

## Cobertura

### Intents (16 etiquetas)

| Intent | Descripción | # ejemplos |
|---|---|---|
| `saludo` | Inicio de conversación | 2 |
| `despedida` | Cierre | 1 |
| `agradecimiento` | "Gracias" | 1 |
| `listar_facultades` | Listado de facultades | 1 |
| `listar_ingenierias` | Programas de ingeniería | 1 |
| `listar_licenciaturas` | Las 12 licenciaturas | 1 |
| `listar_programas_facultad` | Programas de una facultad específica | 2 |
| `cantidad_programas` | Cuántos programas hay | 1 |
| `consulta_creditos` | Créditos académicos | 3 |
| `consulta_snies` | Código SNIES | 4 |
| `consulta_duracion` | Semestres | 3 |
| `consulta_facultad` | A qué facultad pertenece X | 2 |
| `consulta_materias` | Plan de estudios | 4 |
| `consulta_titulo` | Título a otorgar | 2 |
| `consulta_semestre` | Materias de un semestre | 1 |
| `consulta_practica` | Componente práctico | 1 |
| `descripcion_programa` | "¿Qué es X?" | 3 |
| `consulta_existencia` | "¿Hay carrera de X?" | 1 |
| `recomendacion_ia` | Para IA | 1 |
| `recomendacion_programacion` | Para programar | 1 |
| `recomendacion_matematicas` | Para mates | 1 |
| `recomendacion_salud` | Para salud | 1 |
| `recomendacion_docencia` | Para enseñar | 1 |
| `recomendacion_electronica` | Para hardware | 1 |
| `recomendacion_gestion` | Para negocios | 1 |
| `recomendacion_facil` | Sesgada / subjetiva | 1 |
| `recomendacion_indirecta` | No hay programa directo | 1 |
| `comparacion_programas` | Programa vs programa | 3 |
| `comparacion_matematicas` | Cuál tiene más mates | 1 |
| `comparacion_hardware` | Cuál tiene más hardware | 1 |
| `consulta_costos` | Costo, matrícula | 1 |
| `consulta_fechas` | Calendario, inscripciones | 1 |
| `consulta_admision` | Puntaje, requisitos | 2 |
| `consulta_horarios` | Horarios de clase | 1 |
| `fuera_de_tema` | Off-topic | 2 |

### Categorías (5)

- **`informacion_programa`** — datos concretos de un programa
- **`informacion_general`** — listados, conteos
- **`recomendacion`** — sugerir programa según intereses
- **`comparacion`** — comparar dos o más programas
- **`fuera_de_alcance`** — preguntas que requieren info oficial / no relevantes

## Comportamientos clave entrenados

1. **No inventar datos sensibles**: SNIES, créditos, duración solo se afirman
   cuando están verificados; si no están, decir "verifica en uptc.edu.co".
2. **Asistente no oficial**: cada respuesta sensible redirige a canales
   oficiales.
3. **Cortés y conciso**: respuestas estructuradas, español natural.
4. **No off-topic**: declinar preguntas fuera del dominio académico UPTC con
   redirección amable.
5. **Recomendaciones razonadas**: opción principal + complementarias con
   justificación breve.

## Pipeline de fine-tuning

El dataset se usó con **Unsloth Studio** sobre **Gemma 4 E4B-it** vía
**QLoRA 4-bit**. Setup:

| Componente | Valor |
|---|---|
| Modelo base | `google/gemma-4-e4b-it` |
| Método | QLoRA (Quantized Low-Rank Adaptation, 4-bit) |
| UI de entrenamiento | Unsloth Studio |
| GPU | RunPod A40 (48 GB VRAM) |
| Entorno | JupyterLab |
| Epochs | 3 |
| Learning rate | 2e-4 |
| Batch size | 4 |
| LoRA rank | 16 |
| Output | Adapter + modelo merged, subido a Hugging Face |

## Próximos pasos del dataset

- Expandir a ~500 ejemplos para mejor robustez
- Incluir ejemplos adversariales (preguntas trampa, ambiguas)
- Generar ejemplos sintéticos con back-translation
- Validar respuestas con un revisor humano del programa académico UPTC
