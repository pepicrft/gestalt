# Gestalt

A self-hostable AI partner that communicates via Telegram. Run it on a Raspberry Pi, a Hetzner VPS, or your local machine, and chat with it like a knowledgeable friend who can execute code, manage files, and help with software development.

## Features

- **Telegram Interface**: Chat with your AI partner from anywhere via Telegram
- **Persistent Memory**: Conversations are stored in SQLite - it remembers context from days/weeks ago
- **Parallel Tasks**: Ask it to do multiple things at once - each task runs as an independent process
- **Coding Agents**: Uses Claude Code or Codex to help with complex programming tasks
- **MCP Servers**: Connect to Model Context Protocol servers for extended capabilities (GitHub, filesystem, etc.)
- **Runtime Management**: Uses Mise to install required runtimes (Node.js, Python, etc.)

## Architecture

```
You (Telegram) --> Gestalt (Phoenix/Elixir) --> Tasks (GenServers)
                         |                           |
                         v                           v
                      SQLite              Claude Code / Codex
                         |                           |
                         v                           v
                   MCP Servers <------ Config ------+
```

## Requirements

- Elixir 1.15+
- Erlang/OTP 26+
- SQLite 3
- Mise (for runtime management)
- A Telegram Bot Token (from [@BotFather](https://t.me/BotFather))

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/pepicrft/gestalt.git
   cd gestalt
   ```

2. Install dependencies:
   ```bash
   mix deps.get
   ```

3. Set up the database:
   ```bash
   mix ecto.setup
   ```

4. Configure environment variables (see Configuration below)

5. Start the server:
   ```bash
   mix phx.server
   ```

## Configuration

### Required Environment Variables

```bash
# Telegram Bot Token from @BotFather
export TELEGRAM_BOT_TOKEN="your-bot-token"

# Your Telegram user ID (get it from @userinfobot)
export TELEGRAM_ALLOWED_USERS="123456789"

# Which coding agent to use: "claude_code" or "codex"
export GESTALT_CODING_AGENT="claude_code"

# API key for your chosen coding agent
export ANTHROPIC_API_KEY="sk-ant-..."  # For Claude Code
# or
export OPENAI_API_KEY="sk-..."          # For Codex
```

### Production Environment

```bash
# Database path
export DATABASE_PATH="/var/lib/gestalt/gestalt.db"

# Secret key for Phoenix (generate with: mix phx.gen.secret)
export SECRET_KEY_BASE="your-secret-key"

# Start the server
export PHX_SERVER=true
```

## Usage

Once running, start a conversation with your Telegram bot:

```
You: Hey, can you check if there are any security issues in my blog repo?

Gestalt: I'll run a security audit on ~/src/blog. Working on it...

Gestalt: Found 2 dependencies with known vulnerabilities:
         - lodash@4.17.15 (high severity)
         - minimist@1.2.5 (moderate severity)

         Would you like me to update them?
```

### Task Management

Ask about running tasks:
```
You: What are you working on?
Gestalt: Currently running 2 tasks:
         1. Security audit on ~/src/blog (in progress)
         2. Updating deps in ~/src/api (completed)
```

Cancel tasks:
```
You: Cancel the security audit
Gestalt: Stopped the security audit task.
```

### MCP Server Management

Add MCP servers at runtime:
```
You: Add the GitHub MCP server
Gestalt: I'll set up the GitHub MCP server. Please provide a GitHub token.
You: ghp_xxxxx
Gestalt: GitHub MCP server configured and running.
```

## Development

### Running Tests

```bash
mix test
```

### Running the Full CI Suite

```bash
mix ci
```

This runs:
- Compilation with warnings as errors
- Format check
- Credo static analysis
- Tests

### Code Style

- Run `mix format` before committing
- All code must pass `mix credo --strict`
- No compiler warnings allowed

## Deployment

### Raspberry Pi

1. Install Erlang and Elixir via Mise:
   ```bash
   mise install erlang@26
   mise install elixir@1.15
   ```

2. Build a release:
   ```bash
   MIX_ENV=prod mix release
   ```

3. Copy the release to your Pi and run:
   ```bash
   PHX_SERVER=true ./bin/gestalt start
   ```

### Systemd Service

Create `/etc/systemd/system/gestalt.service`:

```ini
[Unit]
Description=Gestalt AI Partner
After=network.target

[Service]
Type=simple
User=gestalt
WorkingDirectory=/opt/gestalt
Environment=PHX_SERVER=true
Environment=DATABASE_PATH=/var/lib/gestalt/gestalt.db
Environment=SECRET_KEY_BASE=your-secret-key
Environment=TELEGRAM_BOT_TOKEN=your-token
Environment=TELEGRAM_ALLOWED_USERS=123456789
Environment=GESTALT_CODING_AGENT=claude_code
Environment=ANTHROPIC_API_KEY=your-key
ExecStart=/opt/gestalt/bin/gestalt start
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

## License

See [LICENSE.md](LICENSE.md)
