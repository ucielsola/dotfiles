import { tool } from "@opencode-ai/plugin"
import { execSync } from "child_process"

export default tool({
  description: "Update GitLab MR description and optionally the title. Finds the MR for the current git branch and updates it. Requires glab CLI and an existing open MR.",
  args: {
    summary: tool.schema.string().describe("The summary/description to set for the MR. Should be a comprehensive description of the changes."),
    title: tool.schema.string().optional().describe("Optional: The title for the MR following the pattern [type]([scope]): [TICKET-ID] [brief description]"),
  },
  async execute(args) {
    try {
      // Escape single quotes in summary for shell safety
      const escapedSummary = args.summary.replace(/'/g, "'\\''")
      
      let command = `updateMR '${escapedSummary}'`
      
      // Add title if provided
      if (args.title) {
        const escapedTitle = args.title.replace(/'/g, "'\\''")
        command += ` '${escapedTitle}'`
      }
      
      const result = execSync(command, { encoding: 'utf-8' })
      return result
    } catch (error: unknown) {
      return `Error running updateMR: ${(error as Error).message}`
    }
  },
})
