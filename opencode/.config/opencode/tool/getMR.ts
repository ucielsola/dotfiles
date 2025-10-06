import { tool } from "@opencode-ai/plugin"
import { execSync } from "child_process"

export default tool({
  description: "Get MR number from current git branch. Finds the merge request associated with the current branch using glab CLI.",
  args: {},
  async execute() {
    try {
      const result = execSync('getMR', { encoding: 'utf-8' })
      return result.trim()
    } catch (error: unknown) {
      return `Error running getMR: ${(error as Error).message}`
    }
  },
})
