import { tool } from "@opencode-ai/plugin"
import { execSync } from "child_process"

export default tool({
  description: "Fetch comprehensive Jira ticket details including summary, description, acceptance criteria, notes, and subtasks. Auto-extracts ticket ID from git branch name if not provided.",
  args: {
    ticketId: tool.schema.string().optional().describe("Jira ticket ID (e.g., ME-123). If omitted, will auto-extract from current git branch name."),
  },
  async execute(args) {
    try {
      const ticketArg = args.ticketId ? args.ticketId : ''
      const result = execSync(`getJiraTicket ${ticketArg}`, { encoding: 'utf-8' })
      return result
    } catch (error: unknown) {
      return `Error running getJiraTicket: ${(error as Error).message}`
    }
  },
})
