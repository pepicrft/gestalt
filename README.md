# Gestalt

A self-hostable AI partner that communicates via Telegram. Run it on any host where Erlang can run - a Raspberry Pi, a Hetzner server, a spare laptop, or your main machine. Chat with it like a knowledgeable friend who can execute code, manage files, and help with software development.

Running Gestalt on your local network gives you access to interfaces scoped to that network, like IoT devices, home automation systems, or internal services that aren't exposed to the internet.

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

### Building for Production

1. Clone the repository on your target host:
   ```bash
   git clone https://github.com/pepicrft/gestalt.git
   cd gestalt
   ```

2. Install dependencies with Mise and build the release:
   ```bash
   mise install
   mix deps.get --only prod
   MIX_ENV=prod mix release
   ```

   The release will be created at `_build/prod/rel/gestalt`.

3. Configure the app to run as a daemon (see platform-specific instructions below).

### Running as a Daemon

The examples below assume you cloned the repository to `/opt/gestalt`. The release binary requires Erlang, so we use `mise exec -C <project-dir>` to ensure the correct runtime version (as pinned in the project) is available.

#### Linux (systemd)

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
ExecStart=/usr/bin/mise exec -C /opt/gestalt -- /opt/gestalt/_build/prod/rel/gestalt/bin/gestalt start
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

Then enable and start the service:
```bash
sudo systemctl enable gestalt
sudo systemctl start gestalt
```

#### macOS (launchd)

Create `~/Library/LaunchAgents/com.gestalt.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.gestalt</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/mise</string>
        <string>exec</string>
        <string>-C</string>
        <string>/opt/gestalt</string>
        <string>--</string>
        <string>/opt/gestalt/_build/prod/rel/gestalt/bin/gestalt</string>
        <string>start</string>
    </array>
    <key>WorkingDirectory</key>
    <string>/opt/gestalt</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PHX_SERVER</key>
        <string>true</string>
        <key>DATABASE_PATH</key>
        <string>/var/lib/gestalt/gestalt.db</string>
        <key>SECRET_KEY_BASE</key>
        <string>your-secret-key</string>
        <key>TELEGRAM_BOT_TOKEN</key>
        <string>your-token</string>
        <key>TELEGRAM_ALLOWED_USERS</key>
        <string>123456789</string>
        <key>GESTALT_CODING_AGENT</key>
        <string>claude_code</string>
        <key>ANTHROPIC_API_KEY</key>
        <string>your-key</string>
    </dict>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/var/log/gestalt/stdout.log</string>
    <key>StandardErrorPath</key>
    <string>/var/log/gestalt/stderr.log</string>
</dict>
</plist>
```

Then load the service:
```bash
launchctl load ~/Library/LaunchAgents/com.gestalt.plist
```

#### Windows (NSSM)

Use [NSSM (Non-Sucking Service Manager)](https://nssm.cc/) to run Gestalt as a Windows service:

1. Download and install NSSM
2. Open an elevated command prompt and run:
   ```cmd
   nssm install Gestalt C:\Users\YourUser\.local\bin\mise.exe exec -C C:\gestalt -- C:\gestalt\_build\prod\rel\gestalt\bin\gestalt.bat start
   nssm set Gestalt AppDirectory C:\gestalt
   nssm set Gestalt AppEnvironmentExtra PHX_SERVER=true DATABASE_PATH=C:\gestalt\gestalt.db SECRET_KEY_BASE=your-secret-key TELEGRAM_BOT_TOKEN=your-token TELEGRAM_ALLOWED_USERS=123456789 GESTALT_CODING_AGENT=claude_code ANTHROPIC_API_KEY=your-key
   nssm start Gestalt
   ```

## License

See [LICENSE.md](LICENSE.md)
