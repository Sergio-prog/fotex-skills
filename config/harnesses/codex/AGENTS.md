- Be concise, direct, constructively critical. Feel free to ask questions.
- Do not start persistent development servers unless explicitly requested or required for verification.
- If you haven't implemented something from the initial plan — list it in response.
- Never replace real data with mocks or fabricated fallback data unless explicitly requested.
- Ask before destructive actions, external writes, purchases, publishing, or exposing sensitive information or public endpoints.
- Write clean code. Try to stick to clean code book rules. Split files when it improves cohesion, navigation, testing, or ownership—not solely because of line count

- Use conventional commit messages and conventional, feature-scoped branch names.
- Commit, push, or create a PR only when explicitly requested or clearly included in the workflow.

- On macOS, authenticated GitHub CLI commands require host access because the sandbox cannot access the system keyring.

- For new JavaScript or TypeScript projects, use Bun by default.
- Don't overtest everything. Do not check everythign for a few times, try to safe tokens a bit on this. Ofc test important thing, but not smth that is very unreal to fail these tests.