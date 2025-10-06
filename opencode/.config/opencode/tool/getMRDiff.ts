import { tool } from "@opencode-ai/plugin"
import { execSync } from "child_process"

export default tool({
  description: "Generate MR diff summary optimized for AI analysis. Retrieves MR metadata, changed files, and raw diff. If no MR number provided, automatically detects from current branch.",
  args: {
    mrNumber: tool.schema.string().optional().describe("Optional: MR number to fetch. If not provided, uses MR from current branch."),
  },
  async execute(args) {
    try {
      const command = args.mrNumber ? `getMRDiff ${args.mrNumber}` : 'getMRDiff'
      const result = execSync(command, { 
        encoding: 'utf-8',
        maxBuffer: 10 * 1024 * 1024
      })
      return result
    } catch (error: unknown) {
      return `Error running getMRDiff: ${(error as Error).message}`
    }
  },
})
