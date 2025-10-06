# OpenCode Configuration Guidelines

## Custom Agents
Located in `.config/opencode/agent/`

## Custom Commands
Located in `.config/opencode/command/`

## File Structure
```
.config/opencode/
├── agent/                    # Custom agent definitions
│   └── conversational-planner.md
└── command/                  # Custom slash commands
    └── update-mr.md
```

## Adding New Agents/Commands
1. Create `.md` file in appropriate directory
2. Include frontmatter with `description`, `mode`, `tools`, `agent` (for commands)
3. Write agent instructions or command workflow
4. Use `$ARGUMENTS` to reference command parameters

## Notes
- Agent files use YAML frontmatter + markdown instructions
- Commands can reference available bash tools in user's `~/bin/`
- This directory is stowed to `~/.config/opencode/` via GNU Stow
