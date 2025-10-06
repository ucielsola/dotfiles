import { tool } from "@opencode-ai/plugin"
import { execSync } from "child_process"

export default tool({
  description: "Generate AI-ready diff summary between feature branch and base branch. Shows files changed, commit messages, diff stats, and code changes.",
  args: {
    baseBranch: tool.schema.string().default("master").describe("Base branch to compare against (default: master)"),
  },
  async execute(args) {
    try {
      const result = execSync(`getDiff ${args.baseBranch}`, { encoding: 'utf-8' })
      return result
    } catch (error: unknown) {
      return `Error running getDiff: ${(error as Error).message}`
    }
  },
})
