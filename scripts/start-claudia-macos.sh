#!/usr/bin/env bash

# Claudia macOS Installationsskript
# Installiert automatisch alle benötigten Abhängigkeiten für Claudia

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

# Funktion zum Überprüfen ob Befehl existiert
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Funktion zum Überprüfen der macOS Version
check_macos_version() {
    local version=$(sw_vers -productVersion)
    local major_version=$(echo $version | cut -d. -f1)
    local minor_version=$(echo $version | cut -d. -f2)
    
    # Überprüfe ob macOS 11+ (Big Sur oder neuer)
    if [[ $major_version -ge 11 ]] || [[ $major_version -eq 10 && $minor_version -ge 15 ]]; then
        print_success "macOS Version $version ist kompatibel"
        return 0
    else
        print_error "macOS Version $version ist nicht unterstützt. Mindestens macOS 11 (Big Sur) erforderlich."
        return 1
    fi
}

# Homebrew installieren falls nicht vorhanden
install_homebrew() {
    if command_exists brew; then
        print_success "Homebrew ist bereits installiert"
        # Homebrew aktualisieren
        print_status "Aktualisiere Homebrew..."
        brew update
    else
        print_status "Installiere Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Homebrew zum PATH hinzufügen
        if [[ -f "/opt/homebrew/bin/brew" ]]; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [[ -f "/usr/local/bin/brew" ]]; then
            echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
            eval "$(/usr/local/bin/brew shellenv)"
        fi
        
        print_success "Homebrew installiert"
    fi
}

# Xcode Command Line Tools installieren
install_xcode_tools() {
    if xcode-select -p >/dev/null 2>&1; then
        print_success "Xcode Command Line Tools sind bereits installiert"
    else
        print_status "Installiere Xcode Command Line Tools..."
        xcode-select --install
        
        # Warten bis Installation abgeschlossen ist
        print_warning "Bitte warte bis die Xcode Command Line Tools Installation abgeschlossen ist..."
        read -p "Drücke Enter wenn die Installation abgeschlossen ist..."
        
        if xcode-select -p >/dev/null 2>&1; then
            print_success "Xcode Command Line Tools installiert"
        else
            print_error "Xcode Command Line Tools Installation fehlgeschlagen"
            exit 1
        fi
    fi
}

# Git installieren/überprüfen
install_git() {
    if command_exists git; then
        local version=$(git --version | cut -d' ' -f3)
        print_success "Git ist bereits installiert (Version: $version)"
    else
        print_status "Installiere Git über Homebrew..."
        brew install git
        print_success "Git installiert"
    fi
}

# Rust installieren
install_rust() {
    if command_exists cargo && command_exists rustc; then
        local version=$(rustc --version | cut -d' ' -f2)
        print_success "Rust ist bereits installiert (Version: $version)"
        
        # Überprüfe Rust Version (minimum 1.70.0)
        local major=$(echo $version | cut -d. -f1)
        local minor=$(echo $version | cut -d. -f2)
        
        if [[ $major -gt 1 ]] || [[ $major -eq 1 && $minor -ge 70 ]]; then
            print_success "Rust Version ist kompatibel"
        else
            print_warning "Rust Version ist zu alt (minimum 1.70.0). Aktualisiere Rust..."
            rustup update
        fi
    else
        print_status "Installiere Rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        
        # Rust zum PATH hinzufügen
        source ~/.cargo/env
        
        if command_exists cargo && command_exists rustc; then
            local version=$(rustc --version | cut -d' ' -f2)
            print_success "Rust installiert (Version: $version)"
        else
            print_error "Rust Installation fehlgeschlagen"
            exit 1
        fi
    fi
}

# Bun installieren
install_bun() {
    if command_exists bun; then
        local version=$(bun --version)
        print_success "Bun ist bereits installiert (Version: $version)"
        
        # Bun aktualisieren
        print_status "Aktualisiere Bun..."
        bun upgrade
    else
        print_status "Installiere Bun..."
        curl -fsSL https://bun.sh/install | bash
        
        # Bun zum PATH hinzufügen
        if [[ -f "$HOME/.bun/bin/bun" ]]; then
            export PATH="$HOME/.bun/bin:$PATH"
            echo 'export PATH="$HOME/.bun/bin:$PATH"' >> ~/.zprofile
        fi
        
        if command_exists bun; then
            local version=$(bun --version)
            print_success "Bun installiert (Version: $version)"
        else
            print_error "Bun Installation fehlgeschlagen"
            exit 1
        fi
    fi
}

# Claude Code CLI installieren
install_claude_cli() {
    # Check multiple possible locations for claude
    local claude_found=false
    local claude_path=""
    
    # Check if claude exists as command (handles PATH)
    if command_exists claude; then
        claude_found=true
        claude_path="claude"
    # Check common installation path
    elif [[ -x "$HOME/.claude/local/claude" ]]; then
        claude_found=true
        claude_path="$HOME/.claude/local/claude"
    fi
    
    if [[ "$claude_found" == true ]]; then
        local version=$($claude_path --version 2>/dev/null || echo "unbekannt")
        print_success "Claude Code CLI ist bereits installiert (Version: $version)"
    else
        print_warning "Claude Code CLI ist nicht installiert!"
        print_status "Claude Code CLI muss manuell von https://claude.ai/code heruntergeladen werden"
        print_status "Folge diesen Schritten:"
        print_status "1. Gehe zu https://claude.ai/code"
        print_status "2. Lade die macOS Version herunter"
        print_status "3. Installiere die Anwendung"
        print_status "4. Stelle sicher, dass 'claude' im Terminal verfügbar ist"
        
        read -p "Drücke Enter wenn Claude Code CLI installiert ist..."
        
        # Re-check after user confirmation
        if command_exists claude || [[ -x "$HOME/.claude/local/claude" ]]; then
            local version=$(claude --version 2>/dev/null || $HOME/.claude/local/claude --version 2>/dev/null || echo "unbekannt")
            print_success "Claude Code CLI gefunden (Version: $version)"
        else
            print_error "Claude Code CLI ist immer noch nicht verfügbar. Bitte installiere es manuell."
            print_status "Du kannst das Skript später erneut ausführen."
            exit 1
        fi
    fi
}

# pkg-config installieren (optional aber empfohlen)
install_pkg_config() {
    if command_exists pkg-config; then
        print_success "pkg-config ist bereits installiert"
    else
        print_status "Installiere pkg-config..."
        brew install pkg-config
        print_success "pkg-config installiert"
    fi
}

# Hauptfunktion
main() {
    print_status "Claudia macOS Installation gestartet..."
    print_status "Überprüfe System..."
    
    # System überprüfen
    if ! check_macos_version; then
        exit 1
    fi
    
    # Installationen
    install_homebrew
    install_xcode_tools
    install_git
    install_rust
    install_bun
    install_pkg_config
    install_claude_cli
    
    print_success "Alle Abhängigkeiten sind installiert!"
    
    # Frontend Dependencies installieren
    print_status "Installiere Frontend-Dependencies..."
    if command -v bun >/dev/null 2>&1; then
        if bun install; then
            print_success "Frontend-Dependencies installiert"
        else
            print_error "Fehler beim Installieren der Frontend-Dependencies"
            print_status "Du kannst es später manuell mit 'bun install' versuchen"
            return 1
        fi
    else
        print_warning "Bun ist nicht verfügbar. Starte das Terminal neu und führe 'bun install' aus."
        return 1
    fi
    
    # Parameter prüfen für Production Build
    if [[ "$1" == "--prod" ]]; then
        print_status "🏗️  Starte Production Build..."
        print_status "Das kann einige Minuten dauern..."
        if bun run tauri build; then
            print_success "Production Build erfolgreich erstellt!"
            print_status ""
            print_status "🎉 Claudia ist bereit für die Verteilung!"
            print_status "Die App-Dateien findest du in: src-tauri/target/release/bundle/"
        else
            print_error "Production Build fehlgeschlagen"
            return 1
        fi
    else
        print_status "🚀 Starte Claudia Entwicklungsserver..."
        print_status ""
        
        # Runtime-Verzeichnis erstellen falls nicht vorhanden
        mkdir -p .runtime
        
        # Log-Datei initial erstellen falls sie noch nicht existiert (wichtig für nohup)
        [[ ! -f .runtime/claudia.log ]] && touch .runtime/claudia.log
        
        # Server im Hintergrund starten (anhängen statt überschreiben)
        nohup bun run tauri dev >> .runtime/claudia.log 2>&1 &
        CLAUDIA_PID=$!
        echo $CLAUDIA_PID > .runtime/claudia.pid
        
        # Kurz warten um sicherzustellen dass der Prozess läuft
        sleep 2
        
        if kill -0 $CLAUDIA_PID 2>/dev/null; then
            print_success "✅ Claudia läuft im Hintergrund (PID: $CLAUDIA_PID)"
            print_status ""
            print_status "📋 WICHTIGE INFO:"
            print_status "• Claudia öffnet sich automatisch als Desktop-App"
            print_status "• Hot-Reload: Änderungen werden automatisch übernommen"
            print_status "• Logs anzeigen: tail -f .runtime/claudia.log"
            print_status ""
            print_status "🔧 ZUM BEENDEN:"
            print_status "• /Users/robin/Code/claudia/scripts/stop-claudia-macos.sh"
            print_status "• Oder schließe das Claudia-Fenster direkt"
            print_status ""
            print_success "Terminal ist wieder frei - du kannst es schließen oder weiterarbeiten"
        else
            print_error "Fehler beim Starten von Claudia"
            print_status "Überprüfe .runtime/claudia.log für Details"
            exit 1
        fi
    fi
}

# Skript starten
main "$@"