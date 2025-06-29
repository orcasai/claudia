# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Claudia is a desktop application built with Tauri 2 that provides a GUI for Claude Code. It combines a React TypeScript frontend with a Rust backend to manage Claude Code sessions, custom AI agents, and provide advanced security features.

## Key Commands

### Development
- `bun run dev` - Run frontend development server with hot reload
- `bun run tauri dev` - Run full application in development mode
- `bunx tsc --noEmit` - Type check TypeScript code

### Building
- `bun run tauri build` - Build production application with installers
- `bun run tauri build --debug` - Debug build (faster compilation)
- `bun run tauri build --target universal-apple-darwin` - Universal macOS binary

### Testing
- `cd src-tauri && cargo test` - Run all Rust backend tests
- `cd src-tauri && cargo test --test <test_name>` - Run specific test file
- `cd src-tauri && cargo test -- --nocapture` - Show println! output during tests

### Code Quality
- `cd src-tauri && cargo fmt` - Format Rust code
- `cd src-tauri && cargo clippy` - Run Rust linter

## Architecture

### Frontend Structure
The React frontend in `/src` uses:
- **Component Architecture**: 70+ React components in `/src/components/`
- **State Management**: React Context API for global state
- **Routing**: React Router for navigation
- **API Communication**: Tauri's IPC system via `@tauri-apps/api`
- **Styling**: Tailwind CSS v4 with shadcn/ui components

### Backend Structure
The Rust backend in `/src-tauri` implements:
- **Command Handlers**: `/src-tauri/src/commands/` - Tauri commands for frontend-backend communication
- **Process Management**: `/src-tauri/src/process/` - Manages Claude Code subprocess lifecycle
- **Sandbox System**: `/src-tauri/src/sandbox/` - Platform-specific sandboxing (seccomp/Seatbelt)
- **Checkpoint System**: `/src-tauri/src/checkpoint/` - Timeline and session versioning
- **Database**: SQLite via rusqlite for persistent storage

### Key Architectural Patterns

1. **Tauri IPC Communication**:
   - Frontend invokes commands via `invoke()` from `@tauri-apps/api/core`
   - Backend handlers in `/src-tauri/src/commands/` process requests
   - All IPC uses type-safe interfaces defined in both TypeScript and Rust

2. **Process Registry**:
   - Central registry manages all Claude Code subprocesses
   - Handles process lifecycle, output streaming, and cleanup
   - Located in `/src-tauri/src/process/registry.rs`

3. **Security Sandboxing**:
   - Platform-specific implementations in `/src-tauri/src/sandbox/`
   - Profile-based permission system with reusable security profiles
   - Violation tracking and audit logging

4. **Agent System**:
   - Agents defined with custom prompts, models, and sandbox profiles
   - Execution tracked in database with full history
   - Agent definitions stored as JSON in database

## Important Implementation Details

### Frontend-Backend Communication
- All Tauri commands return `Result<T, String>` for consistent error handling
- Use `#[tauri::command]` attribute for exposing Rust functions to frontend
- Frontend uses try-catch blocks around `invoke()` calls

### Database Schema
The SQLite database stores:
- Agent definitions and execution history
- Sandbox profiles and violations
- MCP server configurations
- Usage analytics data

### Testing Strategy
- Unit tests for individual Rust modules
- Integration tests for sandbox functionality
- Platform-specific test handling with `#[cfg(target_os = ...)]`
- Tests use temporary directories and cleanup after execution

### Build Considerations
- Frontend assets are embedded in the final binary
- Platform-specific dependencies handled in `tauri.conf.json`
- Code splitting configured in `vite.config.ts` for optimal bundle size
- Universal binaries supported for macOS (Intel + Apple Silicon)