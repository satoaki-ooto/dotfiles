import { isToolCallEventType, type ExtensionAPI } from "@earendil-works/pi-coding-agent";

// PreToolUse 相当。bash ツールの `git push` が main/master を更新する場合にブロックする。
//
// permissions だけではコマンド文字列しか見えないため、main 上での `git push origin HEAD` や
// `git push origin feat:main` を取りこぼす。ここでは push 先の refspec を解決して判定する。
//
// deliberate: シェルの完全なパースはしない。whitespace で分割し、変数展開
// (`git push origin $BR`) や alias は解決しない。GitHub の branch protection と併用する前提。
// `!` でユーザーが直接打つコマンド (user_bash) は対象外。

const PROTECTED_BRANCHES = new Set(["main", "master"]);

function splitShellSegments(command: string): string[] {
	// `cd x && git push origin main` を独立したセグメントとして扱う。
	// バッククォートと `$()` の括弧も区切りにする。
	return command.split(/[\n;&|()`]/);
}

function stripQuotes(word: string): string {
	// `bash -c "git push ..."` のような引用符付きの語も検出する。
	return word.replace(/["']/g, "");
}

function isProtectedBranch(ref: string): boolean {
	const branch = ref.startsWith("refs/heads/") ? ref.slice("refs/heads/".length) : ref;
	return PROTECTED_BRANCHES.has(branch);
}

function destinationOf(refspec: string): string {
	const withoutForce = refspec.startsWith("+") ? refspec.slice(1) : refspec;
	const colon = withoutForce.lastIndexOf(":");
	// `src:dst` -> dst、`:dst` (削除) -> dst、`name` -> name
	return colon === -1 ? withoutForce : withoutForce.slice(colon + 1);
}

function checkRefspec(refspec: string, currentBranch: string | null): string | undefined {
	let destination = destinationOf(refspec);

	if (destination.includes("*")) {
		return `wildcard refspec '${refspec}' may include main/master`;
	}

	// 宛先が無い / HEAD は現在のブランチへの push。解決できなければ fail closed。
	if (destination === "" || destination === "HEAD") {
		if (currentBranch === null) {
			return `cannot determine the current branch for refspec '${refspec}'`;
		}
		destination = currentBranch;
	}

	if (isProtectedBranch(destination)) {
		return `push to '${destination}' (refspec '${refspec}')`;
	}

	return undefined;
}

function checkSegment(segment: string, currentBranch: string | null): string | undefined {
	const words = segment.split(/\s+/).filter(Boolean).map(stripQuotes);
	const positional: string[] = [];
	let seenGit = false;
	let seenPush = false;

	for (const word of words) {
		if (!seenPush) {
			if (word === "git") seenGit = true;
			if (seenGit && word === "push") seenPush = true;
			continue;
		}

		if (word === "--all" || word === "--mirror") {
			return `git push ${word}`;
		}
		if (word.startsWith("-")) continue;
		positional.push(word);
	}

	if (!seenPush) return undefined;

	// positional[0] は remote。以降が refspec で、無ければ現在のブランチ。
	if (positional.length <= 1) {
		return checkRefspec("HEAD", currentBranch);
	}

	for (const refspec of positional.slice(1)) {
		const reason = checkRefspec(refspec, currentBranch);
		if (reason) return reason;
	}

	return undefined;
}

export function findGitPushViolation(command: string, currentBranch: string | null): string | undefined {
	for (const segment of splitShellSegments(command)) {
		const reason = checkSegment(segment, currentBranch);
		if (reason) return reason;
	}
	return undefined;
}

async function resolveCurrentBranch(pi: ExtensionAPI, cwd: string): Promise<string | null> {
	try {
		const result = await pi.exec("git", ["symbolic-ref", "--short", "-q", "HEAD"], { cwd, timeout: 2000 });
		const branch = result.stdout.trim();
		return result.code === 0 && branch ? branch : null;
	} catch {
		return null;
	}
}

export default function (pi: ExtensionAPI) {
	pi.on("tool_call", async (event, ctx) => {
		if (!isToolCallEventType("bash", event)) return;

		const command = event.input.command;
		if (!command.includes("push")) return;

		const currentBranch = await resolveCurrentBranch(pi, ctx.cwd);
		const violation = findGitPushViolation(command, currentBranch);
		if (!violation) return;

		return {
			block: true,
			reason: `BLOCKED: ${violation}. git push to main/master is forbidden; push a feature branch instead.`,
		};
	});
}
