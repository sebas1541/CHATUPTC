# data-pipeline

Scripts para enriquecer `programas_uptc.json` con datos oficiales del sitio
de la UPTC. Solo se ejecuta cuando quieras actualizar la base de conocimiento;
no es parte del runtime de la app.

## Limitación: UPTC no es scrapeable directamente

El sitio `uptc.edu.co` carga los listados de programas via JavaScript desde un
endpoint interno (`excv2/arcv2`) que no es accesible programáticamente. El
sitemap.xml está vacío y las facultades no enumeran sus programas en HTML
estático.

Por eso `program_urls.yaml` lleva las URLs hardcodeadas. Solo conocemos:
- `Ingeniería de Sistemas y Computación` (verificada)

Para las otras 31, las URLs están como `null`. Si quieres llenar más:

1. Abre `https://uptc.edu.co` en el navegador
2. Navega a Académico → Facultades → la facultad correspondiente
3. Encuentra el programa y copia la URL de su micrositio (termina en
   `/index.html`)
4. Pégala en `program_urls.yaml` reemplazando el `null`
5. Re-corre el scraper

## Setup

```bash
cd data-pipeline
pip3 install requests beautifulsoup4 pyyaml
```

## Uso

```bash
# Ver qué cambiaría sin escribir
python3 scrape_uptc.py --dry-run

# Aplicar (deja backup .json.bak)
python3 scrape_uptc.py
```

## Qué intenta extraer

- **SNIES**: regex sobre el texto completo de la página buscando "SNIES: 1234"
- **Créditos académicos**: regex "175 créditos"
- **Duración**: regex "10 semestres"
- **Perfil profesional**: bloque de texto después de un header que contenga
  "perfil profesional" o "perfil del egresado"
- **Perfil ocupacional**: similar para "perfil ocupacional" / "campos de acción"
- **Materias clave**: filas de tablas que aparezcan después de headers que
  mencionen "asignaturas" o "plan de estudios"

## Merge semantics

El scraper **NO sobreescribe** campos que ya tienen valor en
`programas_uptc.json`. Solo llena campos vacíos. Si quieres re-escribir un
campo, bórralo manualmente del JSON primero y vuelve a correr el scraper.

## Estructura

```
data-pipeline/
├── README.md             # este archivo
├── program_urls.yaml     # URLs por programa
└── scrape_uptc.py        # scraper principal
```
