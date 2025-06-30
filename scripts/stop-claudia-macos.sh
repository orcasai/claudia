#!/usr/bin/env bash

# Claudia macOS Stop-Skript
# Beendet alle laufenden Claudia-Prozesse sauber

set -e

# Farben für bessere Ausgabe
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funktion für farbige Ausgaben
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[ERFOLG]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNUNG]${NC} $1"
}

print_error() {
    echo -e "${RED}[FEHLER]${NC} $1"
}

# Hauptfunktion
main() {
    print_status "🛑 Stoppe alle Claudia-Prozesse..."
    
    # Zuerst prüfen ob PID-Datei existiert
    if [[ -f ".runtime/claudia.pid" ]]; then
        local saved_pid=$(cat .runtime/claudia.pid 2>/dev/null)
        if [[ -n "$saved_pid" ]] && kill -0 "$saved_pid" 2>/dev/null; then
            print_status "Beende Claudia-Prozess (PID: $saved_pid)..."
            kill -TERM "$saved_pid" 2>/dev/null || true
            sleep 2
            # Falls noch läuft, force kill
            if kill -0 "$saved_pid" 2>/dev/null; then
                kill -KILL "$saved_pid" 2>/dev/null || true
            fi
            print_success "Claudia-Prozess beendet"
        fi
        rm -f .runtime/claudia.pid
    fi
    
    # Finde und beende Tauri Dev-Server
    local tauri_pids=$(pgrep -f "tauri dev" 2>/dev/null || true)
    if [[ -n "$tauri_pids" ]]; then
        print_status "Beende Tauri Development Server..."
        echo "$tauri_pids" | xargs kill -TERM 2>/dev/null || true
        sleep 2
        # Falls noch läuft, force kill
        echo "$tauri_pids" | xargs kill -KILL 2>/dev/null || true
        print_success "Tauri Development Server beendet"
    fi
    
    # Finde und beende Bun-Prozesse
    local bun_pids=$(pgrep -f "bun.*tauri" 2>/dev/null || true)
    if [[ -n "$bun_pids" ]]; then
        print_status "Beende Bun-Prozesse..."
        echo "$bun_pids" | xargs kill -TERM 2>/dev/null || true
        sleep 1
        echo "$bun_pids" | xargs kill -KILL 2>/dev/null || true
        print_success "Bun-Prozesse beendet"
    fi
    
    # Finde und beende Claudia-App-Prozesse
    local claudia_pids=$(pgrep -f "claudia" 2>/dev/null || true)
    if [[ -n "$claudia_pids" ]]; then
        print_status "Beende Claudia-App..."
        echo "$claudia_pids" | xargs kill -TERM 2>/dev/null || true
        sleep 1
        echo "$claudia_pids" | xargs kill -KILL 2>/dev/null || true
        print_success "Claudia-App beendet"
    fi
    
    # Finde und beende Node/Vite-Prozesse (Frontend Dev Server)
    local node_pids=$(pgrep -f "vite.*dev" 2>/dev/null || true)
    if [[ -n "$node_pids" ]]; then
        print_status "Beende Frontend Development Server..."
        echo "$node_pids" | xargs kill -TERM 2>/dev/null || true
        sleep 1
        echo "$node_pids" | xargs kill -KILL 2>/dev/null || true
        print_success "Frontend Development Server beendet"
    fi
    
    # Prüfe ob noch Prozesse laufen
    sleep 2
    local remaining=$(pgrep -f "(tauri|claudia|bun.*tauri)" 2>/dev/null || true)
    if [[ -z "$remaining" ]]; then
        print_success "✅ Alle Claudia-Prozesse erfolgreich beendet!"
        print_status ""
        print_status "Um Claudia wieder zu starten:"
        print_status "  /Users/robin/Code/claudia/scripts/start-claudia-macos.sh"
    else
        print_warning "⚠️  Einige Prozesse laufen möglicherweise noch:"
        echo "$remaining" | while read pid; do
            ps -p "$pid" -o pid,comm,args 2>/dev/null || true
        done
        print_status ""
        print_status "Falls nötig, beende sie manuell mit:"
        print_status "  kill -9 <PID>"
    fi
}

# Skript starten
main "$@"