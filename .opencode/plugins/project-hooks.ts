import type { Plugin } from "@opencode-ai/plugin"

const DESTRUCTIVE_COMMAND =
  /(rm\s+-rf\s+[/~]|DROP\s+TABLE|DROP\s+DATABASE|git\s+push\s+.*(-f|--force)\s+.*(main|master|production)|chmod\s+777)/i

const isRubyFile = (path?: string) => path?.endsWith(".rb")
const isErbFile = (path?: string) => path?.endsWith(".erb")

/**
 * Port of `.claude/settings.json` hooks for opencode:
 *
 * - SessionStart      -> log project status on session.created
 * - PreToolUse Bash   -> block destructive commands
 * - PostToolUse Edit/Write -> auto-format Ruby/ERB with RuboCop/ERB lint
 * - Stop              -> desktop notification when a session goes idle
 */
export const ProjectHooks: Plugin = async ({ $, client }) => {
  return {
    event: async ({ event }) => {
      if (event.type === "session.created") {
        try {
          const branch = (await $`git branch --show-current`.text().catch(() => "N/A")).trim()
          const ruby = (await $`ruby -v`.text().catch(() => "N/A")).trim().split(" ")[1] || "N/A"
          await client.app.log({
            body: {
              service: "project-hooks",
              level: "info",
              message: `Session started on branch ${branch} | Ruby ${ruby}`,
            },
          })
        } catch {
          // best-effort; never break the session for a status line
        }
      }

      if (event.type === "session.idle") {
        await $`notify-send "opencode" "Response complete" 2>/dev/null || osascript -e 'display notification "Response complete" with title "opencode"' 2>/dev/null`
          .quiet()
          .nothrow()
      }
    },

    "tool.execute.before": async (input, output) => {
      if (input.tool === "bash") {
        const command = output.args?.command ?? ""
        if (DESTRUCTIVE_COMMAND.test(command)) {
          throw new Error(
            "Blocked: This command is potentially destructive. Please confirm with the user before proceeding.",
          )
        }
      }
    },

    "tool.execute.after": async (input, output) => {
      if (input.tool !== "edit" && input.tool !== "write") return
      const filePath = output.args?.filePath ?? output.args?.path
      if (!filePath) return

      if (isRubyFile(filePath)) {
        await $`bundle exec rubocop -a ${filePath}`.quiet().nothrow()
      } else if (isErbFile(filePath)) {
        await $`bundle exec erblint --autocorrect ${filePath}`.quiet().nothrow()
      }
    },
  }
}
