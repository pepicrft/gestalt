# Gestalt Development Guidelines

## Project Overview

Gestalt is a self-hostable AI partner that communicates via Telegram. It runs on any host (Raspberry Pi, VPS, local machine) and can execute tasks, manage MCP servers, and use coding agents (Claude Code/Codex) to help with software development.

## Architecture

### Core Concepts

- **Conversation**: A persistent chat session with a user (GenServer + Ecto schema)
- **Task**: A unit of work spawned from conversation, runs in parallel (GenServer + Ecto schema)
- **MCP Server**: A long-lived process providing tools via Model Context Protocol (GenServer + Ecto schema)
- **Coding Agent**: External tool (Claude Code/Codex) invoked within tasks

### Process Hierarchy

```
Application
├── Gestalt.Repo (SQLite)
├── Gestalt.Telegram.Poller (long-polling GenServer)
├── Gestalt.Conversation.Supervisor (DynamicSupervisor)
│   └── Gestalt.Conversation.Server (one per user)
├── Gestalt.Task.Supervisor (DynamicSupervisor)
│   └── Gestalt.Task.Server (many per conversation)
└── Gestalt.MCP.Supervisor (DynamicSupervisor)
    └── Gestalt.MCP.Process (one per MCP server)
```

### Data Flow

```
Telegram → Poller → Conversation.Server → Task.Server → Agent/MCP → Result
                         ↓                     ↓
                      SQLite               SQLite
```

## Tech Stack

- **Framework**: Phoenix (without LiveView for now)
- **Database**: SQLite via Ecto + ecto_sqlite3
- **HTTP Client**: Req
- **Runtime Management**: Mise (for MCP server dependencies)
- **Coding Agents**: Claude Code CLI, Codex CLI

## Development Guidelines

### Testing Requirements

**All code must be tested.** Follow these principles:

1. **Test isolation**: Each test must have its state scoped to that test only. No global state modification.

2. **No shared state**: Tests must not depend on or modify:
   - Global application state
   - Shared database records (use sandbox)
   - Environment variables (use Application.put_env in setup, restore in on_exit)
   - File system (use tmp_dir or mock)

3. **Use Mimic for mocking**:
   ```elixir
   # In test/test_helper.exs
   Mimic.copy(Gestalt.Telegram.Client)

   # In your test
   setup :set_mimic_global  # or :set_mimic_private for async tests

   test "sends message" do
     expect(Gestalt.Telegram.Client, :send_message, fn _chat_id, _text ->
       {:ok, %{}}
     end)
     # ... test code
   end
   ```

4. **Async tests by default**: Use `async: true` unless tests share resources that can't be isolated.

5. **Database sandbox**: All tests use `Ecto.Adapters.SQL.Sandbox` for automatic transaction rollback.

### Code Style

- Follow standard Elixir formatting (`mix format`)
- No compiler warnings allowed - CI will fail
- Use typespecs for public functions
- Document modules and public functions with `@moduledoc` and `@doc`

### GenServer Guidelines

- Always implement `handle_continue/2` for initialization that might fail
- Use `via_tuple` with Registry for named processes
- Implement graceful shutdown in `terminate/2`
- Keep state serializable (for potential persistence)

### Error Handling

- Use `{:ok, result}` / `{:error, reason}` tuples
- Let processes crash on unexpected errors (supervisor will restart)
- Log errors with metadata: `Logger.error("message", task_id: id, error: reason)`

## Configuration

### Required Environment Variables

```bash
TELEGRAM_BOT_TOKEN=xxx           # Telegram bot token from @BotFather
TELEGRAM_ALLOWED_USERS=123,456   # Comma-separated Telegram user IDs
GESTALT_CODING_AGENT=claude_code # or "codex"
ANTHROPIC_API_KEY=xxx            # Required if using Claude Code
OPENAI_API_KEY=xxx               # Required if using Codex
```

### Runtime Configuration (via Telegram)

- MCP server management
- Runtime installation via Mise
- Task preferences

### MCP Server Configuration

MCP server configurations are persisted in SQLite and exported to a format compatible with coding agents (Claude Code, Codex). When a task spawns a coding agent:

1. Gestalt reads MCP server configs from the database
2. Generates the appropriate config file (e.g., `~/.claude/claude_code_config.json` for Claude Code)
3. Passes the config to the coding agent process

This ensures coding agents have access to the same MCP servers that Gestalt manages.

## File Structure

```
lib/
├── gestalt/
│   ├── application.ex
│   ├── repo.ex
│   ├── telegram/
│   │   ├── client.ex          # HTTP client for Telegram API
│   │   ├── poller.ex          # Long-polling GenServer
│   │   ├── handler.ex         # Message routing
│   │   └── message.ex         # Message parsing
│   ├── conversation/
│   │   ├── conversation.ex    # Ecto schema
│   │   ├── server.ex          # GenServer
│   │   ├── supervisor.ex      # DynamicSupervisor
│   │   └── memory.ex          # Context management
│   ├── task/
│   │   ├── task.ex            # Ecto schema
│   │   ├── server.ex          # GenServer
│   │   ├── supervisor.ex      # DynamicSupervisor
│   │   └── registry.ex        # Task tracking
│   ├── agent/
│   │   ├── runner.ex          # Agent interface
│   │   ├── claude_code.ex     # Claude Code adapter
│   │   └── codex.ex           # Codex adapter
│   ├── mcp/
│   │   ├── server.ex          # Ecto schema
│   │   ├── process.ex         # GenServer per server
│   │   ├── supervisor.ex      # DynamicSupervisor
│   │   ├── client.ex          # MCP protocol
│   │   └── registry.ex        # Server tracking
│   └── mise/
│       └── manager.ex         # Runtime management
├── gestalt_web/
│   ├── endpoint.ex
│   ├── router.ex
│   └── controllers/
│       └── health_controller.ex
└── gestalt.ex
```

## Running the Project

```bash
# Install dependencies
mix deps.get

# Setup database
mix ecto.create
mix ecto.migrate

# Run tests
mix test

# Start server
mix phx.server
# or in IEx
iex -S mix phx.server
```

## Common Commands

```bash
mix format           # Format code
mix credo            # Static analysis
mix dialyzer         # Type checking
mix test             # Run tests
mix test --cover     # Run tests with coverage
```
