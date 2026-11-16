# Cost-aware working rules

## Model routing (pick the cheapest model that can do the job well)
- Lookups, file search, reading/summarizing a few files -> `quick-search` agent (Haiku).
- Small mechanical edits (rename, typo, config value, formatting) -> `simple-edit` agent (Haiku), or do it directly if it is 1-2 edits.
- Normal implementation from a clear plan, tests, bug fixes with a known cause -> do it in the main session (Sonnet under opusplan) or the `implementer` agent (Sonnet).
- Architecture, hard debugging, security review -> plan mode (Opus under opusplan) or the `deep-reviewer` agent (Opus). Use sparingly.
- Don't spawn a subagent for something a couple of direct tool calls can do: each subagent starts with a fresh context.

## Keep context small
- Read only the parts of files you need; prefer Grep/Glob over reading whole directories.
- Keep answers concise; don't repeat file contents back.
- When the user switches to an unrelated task or project, remind them to run `/clear` first (or `/compact` if they want to keep a short summary).
