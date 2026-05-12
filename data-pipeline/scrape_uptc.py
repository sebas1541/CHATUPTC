#!/usr/bin/env python3
"""
Scraper de micrositios UPTC. Lee `program_urls.yaml`, baja cada página,
extrae campos relevantes (SNIES, créditos, duración, perfil, materias) con
BeautifulSoup y los mergea sobre `Sources/UPTCBotKit/Resources/programas_uptc.json`.

Programas sin URL configurada en el YAML se omiten (sus campos en el JSON
se mantienen intactos).

Uso:
    pip install requests beautifulsoup4 pyyaml
    python3 scrape_uptc.py [--dry-run]

Salida:
    - Si --dry-run: imprime lo que cambiaría sin escribir
    - Si no: actualiza programas_uptc.json in-place y deja backup .json.bak
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

try:
    import requests
    import yaml
    from bs4 import BeautifulSoup
except ImportError as e:
    print(f"Falta dependencia: {e}\n\nInstala con:\n  pip3 install requests beautifulsoup4 pyyaml")
    sys.exit(1)

# Paths relativos al script
SCRIPT_DIR = Path(__file__).resolve().parent
URLS_YAML = SCRIPT_DIR / "program_urls.yaml"
JSON_PATH = SCRIPT_DIR.parent / "Sources" / "UPTCBotKit" / "Resources" / "programas_uptc.json"

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "
                  "(KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36"
}


def fetch(url: str) -> str | None:
    """Descarga HTML. Retorna None si falla."""
    try:
        r = requests.get(url, headers=HEADERS, timeout=20)
        r.raise_for_status()
        return r.text
    except Exception as e:
        print(f"  ✗ Error fetching {url}: {e}")
        return None


def extract_text_block(soup: BeautifulSoup, keywords: list[str], max_chars: int = 800) -> str | None:
    """Busca un bloque de texto cuyo header/título contenga alguno de los keywords."""
    for kw in keywords:
        # Buscar en h1-h6, strong, span con texto que matchee
        for tag in soup.find_all(["h1", "h2", "h3", "h4", "h5", "h6", "strong", "span", "p"]):
            text = tag.get_text(strip=True).lower()
            if kw.lower() in text and len(text) < 60:
                # Próximo sibling con contenido sustancial
                nxt = tag.find_next_sibling()
                if nxt:
                    content = nxt.get_text(separator=" ", strip=True)
                    if len(content) > 30:
                        return content[:max_chars].strip()
                # O el siguiente bloque de texto en el documento
                following = tag.find_all_next(text=True, limit=20)
                joined = " ".join(t.strip() for t in following if t.strip())
                if len(joined) > 50:
                    return joined[:max_chars].strip()
    return None


def extract_snies(soup: BeautifulSoup) -> str | None:
    """SNIES code (números de 3-6 dígitos cerca de 'SNIES' o 'Código')."""
    text = soup.get_text()
    m = re.search(r"SNIES[:\s]*(\d{3,6})", text, re.IGNORECASE)
    if m:
        return m.group(1)
    m = re.search(r"C[oó]digo\s+SNIES[:\s]*(\d{3,6})", text, re.IGNORECASE)
    if m:
        return m.group(1)
    return None


def extract_creditos(soup: BeautifulSoup) -> str | None:
    """Número de créditos académicos."""
    text = soup.get_text()
    m = re.search(r"(\d{2,3})\s*cr[eé]ditos?\s*(acad[eé]micos?)?", text, re.IGNORECASE)
    if m:
        return m.group(1)
    return None


def extract_duracion(soup: BeautifulSoup) -> str | None:
    """Duración en semestres."""
    text = soup.get_text()
    m = re.search(r"(\d{1,2})\s*semestres?", text, re.IGNORECASE)
    if m:
        return f"{m.group(1)} semestres"
    return None


def extract_materias(soup: BeautifulSoup, max_count: int = 30) -> list[str]:
    """Extrae lista de materias buscando tablas o listas con encabezado 'plan de estudios'
    o 'asignaturas'."""
    materias = []
    seen = set()
    # Buscar tablas que mencionen 'asignatura' en encabezados
    for table in soup.find_all("table"):
        header_text = table.get_text()[:200].lower()
        if "asignatura" in header_text or "materia" in header_text:
            for row in table.find_all("tr"):
                cells = [c.get_text(strip=True) for c in row.find_all(["td", "th"])]
                if not cells or len(cells) < 2:
                    continue
                # La 1ra o 2da celda suele ser el nombre de la asignatura
                for c in cells:
                    if 3 < len(c) < 80 and not c.isdigit() and not re.match(r"^\d+\s*$", c):
                        if c.lower() not in seen and "asignatura" not in c.lower():
                            seen.add(c.lower())
                            materias.append(c)
                            break
                if len(materias) >= max_count:
                    return materias
    return materias


def scrape_program(name: str, url: str) -> dict:
    """Scrapea un programa y retorna un dict con los campos extraídos.
    Solo incluye keys con valor no vacío."""
    html = fetch(url)
    if not html:
        return {}

    soup = BeautifulSoup(html, "html.parser")
    data = {}

    if snies := extract_snies(soup):
        data["snies"] = snies
    if creditos := extract_creditos(soup):
        data["creditos"] = creditos
    if duracion := extract_duracion(soup):
        data["duracion"] = duracion

    perfil = extract_text_block(soup, ["perfil profesional", "perfil del egresado"])
    if perfil:
        data["perfil_profesional"] = perfil

    ocup = extract_text_block(soup, ["perfil ocupacional", "campos de acción"])
    if ocup:
        data["perfil_ocupacional"] = ocup

    materias = extract_materias(soup)
    if materias:
        data["materias_clave"] = materias

    return data


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true",
                        help="No escribir el JSON, solo imprimir cambios")
    args = parser.parse_args()

    # Cargar URLs
    if not URLS_YAML.exists():
        print(f"No existe {URLS_YAML}")
        sys.exit(1)
    with URLS_YAML.open() as f:
        url_map = yaml.safe_load(f).get("programs", [])

    # Cargar JSON actual
    if not JSON_PATH.exists():
        print(f"No existe {JSON_PATH}")
        sys.exit(1)
    with JSON_PATH.open() as f:
        programs = json.load(f)
    by_name = {p["programa"]: p for p in programs}

    # Scrapear
    stats = {"updated": 0, "skipped_no_url": 0, "skipped_failed": 0}
    for entry in url_map:
        name = entry["nombre"]
        url = entry.get("url")
        if not url:
            stats["skipped_no_url"] += 1
            continue
        if name not in by_name:
            print(f"  ⚠ {name} no está en JSON (saltando)")
            continue
        print(f"→ {name}")
        scraped = scrape_program(name, url)
        if not scraped:
            stats["skipped_failed"] += 1
            print(f"  ✗ sin datos extraídos")
            continue
        # Merge: solo sobreescribir campos vacíos en el JSON actual
        target = by_name[name]
        changes = []
        for k, v in scraped.items():
            current = target.get(k, "")
            if not current or (isinstance(current, list) and not current):
                target[k] = v
                changes.append(k)
        if changes:
            stats["updated"] += 1
            print(f"  ✓ campos actualizados: {', '.join(changes)}")
        else:
            print(f"  ⊝ todos los campos ya tenían valor")

    # Resumen
    print(f"\n=== Resumen ===")
    print(f"Actualizados:        {stats['updated']}")
    print(f"Sin URL (skipped):   {stats['skipped_no_url']}")
    print(f"Fallaron al scrapear: {stats['skipped_failed']}")

    # Escribir
    if args.dry_run:
        print("\n(dry-run: nada se escribió)")
        return
    if stats["updated"] > 0:
        backup = JSON_PATH.with_suffix(".json.bak")
        backup.write_bytes(JSON_PATH.read_bytes())
        with JSON_PATH.open("w") as f:
            json.dump(programs, f, ensure_ascii=False, indent=2)
        print(f"\n✓ {JSON_PATH} actualizado (backup en {backup.name})")
    else:
        print("\n(nada que escribir)")


if __name__ == "__main__":
    main()
