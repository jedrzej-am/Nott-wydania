#!/bin/bash
#
# Instalacja Nott jedną komendą — bez kodu źródłowego i bez konta deweloperskiego.
#
#   curl -fsSL https://raw.githubusercontent.com/jedrzej-am/Nott-wydania/main/instaluj.sh | bash
#
# Co robi:
#   1. Znajduje najnowsze wydanie w publicznym repo wydań (bez tokenu).
#   2. Pobiera paczkę ZIP (ditto — zachowuje podpis i atrybuty aplikacji).
#   3. Instaluje do /Applications i zdejmuje kwarantannę pobierania,
#      żeby macOS nie kazał szukać zgody w Ustawieniach (podpis jest ad-hoc).
#   4. Uruchamia aplikację. Kolejne aktualizacje Nott pobiera już sam.

set -euo pipefail

REPO="jedrzej-am/Nott-wydania"

echo "Szukam najnowszego wydania Nott…"
JSON="$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest")"
WERSJA="$(printf '%s' "$JSON" | grep -o '"tag_name": *"[^"]*"' | head -1 | cut -d'"' -f4)"
URL="$(printf '%s' "$JSON" | grep -o '"browser_download_url": *"[^"]*\.zip"' | head -1 | cut -d'"' -f4)"

if [[ -z "$URL" ]]; then
    echo "Nie znalazłem paczki ZIP w najnowszym wydaniu — sprawdź https://github.com/$REPO/releases" >&2
    exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "Pobieram Nott $WERSJA…"
curl -fL --progress-bar -o "$TMP/Nott.zip" "$URL"
ditto -x -k "$TMP/Nott.zip" "$TMP"

if [[ ! -d "$TMP/Nott.app" ]]; then
    echo "Paczka nie zawiera Nott.app" >&2
    exit 1
fi

# Działająca aplikacja nie może być podmieniona pod spodem — prosimy ją o zamknięcie.
if pgrep -x Nott >/dev/null 2>&1; then
    echo "Zamykam działającą kopię Nott…"
    osascript -e 'tell application "Nott" to quit' >/dev/null 2>&1 || true
    sleep 2
fi

echo "Instaluję do /Applications…"
rm -rf /Applications/Nott.app
ditto "$TMP/Nott.app" /Applications/Nott.app

# Kwarantanna pobierania: bez konta deweloperskiego macOS blokowałby pierwsze
# uruchomienie („Otwórz mimo to" w Ustawieniach). Skoro instalację uruchomiono
# świadomie tą komendą, zdejmujemy ją od razu.
xattr -dr com.apple.quarantine /Applications/Nott.app 2>/dev/null || true

open /Applications/Nott.app
echo
echo "Gotowe — Nott $WERSJA jest w /Applications."
echo "Kolejne aktualizacje aplikacja pobiera już sama (menu Nott → Sprawdź aktualizacje…)."
