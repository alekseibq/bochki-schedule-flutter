# Command approvals

Do not request `require_escalated` or separate confirmation for commands that
are already allowed by a `prefix_rule` in `~/.codex/rules/default.rules` when
the action is explicitly within the user's requested task.

For such commands, execute them directly: do not pass
`sandbox_permissions: "require_escalated"` or a `justification` parameter.

In particular, when the user has explicitly requested the workflow, execute
without additional confirmation: `gh issue comment`, `gh pr create`, `gh pr
edit`, `gh pr checks`, `gh pr merge`, `gh run watch`, `git add`, `git commit`,
`git push`, `git pull`, and `git checkout`.

Request confirmation only for actions outside the requested scope, destructive
operations, or commands without an allow rule.
