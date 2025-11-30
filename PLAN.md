# Gestalt Implementation Plan

## Phase 1: Foundation

### 1.1 Project Setup
- [ ] Create Phoenix application (no LiveView, no Mailer)
- [ ] Configure SQLite with ecto_sqlite3
- [ ] Add dependencies: Req, Mimic, Credo
- [ ] Setup GitHub Actions CI pipeline
- [ ] Configure test environment with Ecto sandbox

### 1.2 Telegram Integration
- [ ] Implement `Gestalt.Telegram.Client` - HTTP client for Telegram Bot API
- [ ] Implement `Gestalt.Telegram.Poller` - Long-polling GenServer
- [ ] Implement `Gestalt.Telegram.Message` - Parse incoming messages
- [ ] Implement `Gestalt.Telegram.Handler` - Route messages to conversations
- [ ] Add authorization check (TELEGRAM_ALLOWED_USERS)

### 1.3 Conversation Management
- [ ] Create `conversations` table migration
- [ ] Create `messages` table migration
- [ ] Implement `Gestalt.Conversation` schema
- [ ] Implement `Gestalt.Conversation.Message` schema
- [ ] Implement `Gestalt.Conversation.Server` GenServer
- [ ] Implement `Gestalt.Conversation.Supervisor` DynamicSupervisor
- [ ] Implement conversation recovery on application restart

**Milestone**: Can send/receive Telegram messages, conversations persist to SQLite

---

## Phase 2: Task Execution

### 2.1 Task Infrastructure
- [ ] Create `tasks` table migration
- [ ] Implement `Gestalt.Task` schema (status, type, result, conversation_id)
- [ ] Implement `Gestalt.Task.Server` GenServer
- [ ] Implement `Gestalt.Task.Supervisor` DynamicSupervisor
- [ ] Implement `Gestalt.Task.Registry` for tracking active tasks

### 2.2 Shell Execution
- [ ] Implement `Gestalt.Shell` - Safe command execution
- [ ] Add working directory support
- [ ] Add timeout handling
- [ ] Stream output capture

### 2.3 Task Interaction
- [ ] Task status queries ("what are you working on?")
- [ ] Task cancellation
- [ ] Task-to-conversation communication (questions, updates)
- [ ] Task completion notifications

**Milestone**: Can spawn parallel tasks that execute shell commands and report back

---

## Phase 3: Coding Agents

### 3.1 Agent Abstraction
- [ ] Define `Gestalt.Agent` behaviour
- [ ] Implement `Gestalt.Agent.Runner` - Agent selection and execution

### 3.2 Claude Code Integration
- [ ] Implement `Gestalt.Agent.ClaudeCode`
- [ ] CLI invocation with proper arguments
- [ ] Output parsing and streaming
- [ ] Error handling

### 3.3 Codex Integration
- [ ] Implement `Gestalt.Agent.Codex`
- [ ] CLI invocation
- [ ] Output parsing
- [ ] Error handling

### 3.4 Agent Configuration
- [ ] Pass MCP server config to agents
- [ ] Working directory management
- [ ] Environment variable injection

**Milestone**: Can ask Gestalt to write code, it delegates to Claude Code or Codex

---

## Phase 4: MCP Server Management

### 4.1 MCP Infrastructure
- [ ] Create `mcp_servers` table migration
- [ ] Implement `Gestalt.MCP.Server` schema
- [ ] Implement `Gestalt.MCP.Process` GenServer (one per MCP server)
- [ ] Implement `Gestalt.MCP.Supervisor` DynamicSupervisor
- [ ] Implement `Gestalt.MCP.Registry`

### 4.2 MCP Protocol Client
- [ ] Implement `Gestalt.MCP.Client` - JSON-RPC over stdio
- [ ] Initialize handshake
- [ ] Tool discovery (tools/list)
- [ ] Tool execution (tools/call)
- [ ] Resource access (resources/read)

### 4.3 MCP Server Lifecycle
- [ ] Add MCP server via Telegram command
- [ ] Remove MCP server
- [ ] List active MCP servers
- [ ] Restart failed MCP servers

### 4.4 Config Export for Agents
- [ ] Generate Claude Code compatible config
- [ ] Generate Codex compatible config
- [ ] Auto-update config when MCP servers change

**Milestone**: Can add MCP servers via Telegram, they're available to coding agents

---

## Phase 5: Runtime Management

### 5.1 Mise Integration
- [ ] Implement `Gestalt.Mise.Manager`
- [ ] Check if runtime is installed
- [ ] Install runtime (node, python, etc.)
- [ ] List installed runtimes

### 5.2 MCP Server Dependencies
- [ ] Detect required runtime for MCP server
- [ ] Auto-install missing runtimes
- [ ] npm/pip package installation

**Milestone**: Can install Node/Python via Mise when adding an MCP server that needs it

---

## Phase 6: Memory and Context

### 6.1 Conversation Memory
- [ ] Implement `Gestalt.Conversation.Memory`
- [ ] Context window management (truncation strategies)
- [ ] Important information extraction and persistence
- [ ] Long-term memory storage

### 6.2 Summarization
- [ ] Periodic conversation summarization
- [ ] Task result summarization
- [ ] Memory retrieval for context

**Milestone**: Gestalt remembers context from previous conversations

---

## Phase 7: Polish and Production

### 7.1 Reliability
- [ ] Graceful shutdown handling
- [ ] Process recovery after crashes
- [ ] Connection retry logic (Telegram, MCP)

### 7.2 Observability
- [ ] Structured logging
- [ ] Health check endpoint
- [ ] Basic metrics (tasks completed, uptime)

### 7.3 Deployment
- [ ] Mix release configuration
- [ ] Systemd service file
- [ ] Docker image (optional, for those who prefer it)
- [ ] Documentation for Raspberry Pi setup

**Milestone**: Production-ready, can run reliably on a Raspberry Pi

---

## Future Ideas (Not Planned)

- Web UI dashboard (Phoenix LiveView)
- Multiple conversation support (family members)
- Voice messages (speech-to-text)
- Scheduled tasks / reminders
- Integration with calendar, email
- Local LLM support via Ollama
