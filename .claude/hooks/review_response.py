#!/usr/bin/env python3
"""
Stop / PreToolUse(Edit) hook: CLAUDE.md の原則に照らしてレビューする。
違反が見つかった場合は non-zero で終了し、Claude に再考を促す。
"""

import json
import sys
import subprocess
import os


CLAUDE_MD_PATH = os.path.join(
    os.path.dirname(__file__), '..', '..', 'CLAUDE.md'
)

STOP_REVIEW_PROMPT = """あなたは Claude Code の回答品質レビュアーです。
以下の「行動原則」に照らして、「レビュー対象の回答」を評価してください。

## 行動原則（CLAUDE.md より）

{claude_md}

## レビュー対象の回答

{response}

## 評価タスク

上記の行動原則のうち、特に以下の観点で違反がないか確認してください：

1. **唯々諾々の禁止**: 自分の考えを述べずにユーザーの意見に即座に同意していないか
2. **修正前の方針合意**: 変更理由・内容の合意なく修正に走っていないか。「何が問題か」の認識が合う前に修正内容の検討を始めていないか
3. **議論の収束を待つ**: 議論が収束していないのに次のアクションを促していないか
4. **合意の粒度**: 総論だけで各論の合意なく進もうとしていないか

違反がなければ「OK」とだけ出力してください。
違反がある場合は、どの原則に違反しているか・どう修正すべきかを日本語で簡潔に出力してください。「OK」という文字列を含めないでください。
"""

EDIT_REVIEW_PROMPT = """あなたは Claude Code の編集品質レビュアーです。
以下の「行動原則」と「直近の会話履歴」に照らして、「実行しようとしている編集」が適切かを評価してください。

## 行動原則（CLAUDE.md より）

{claude_md}

## 直近の会話履歴（最新20件）

{recent_messages}

## 実行しようとしている編集

ファイル: {file_path}

## 評価タスク

以下の順序で確認してください：

1. **ファイル言及後の合意**: 会話の中で Claude が「{file_path}」または該当ファイルのファイル名を明示した後に、ユーザーが肯定的に応答しているか
   - ファイル名の言及より前に出た「ok」「良いね」などはそのファイルへの合意とみなさない
   - Claude がファイル名を言及した後、ユーザーが肯定した流れがあれば合意あり
2. **合意の粒度**: ファイルへの言及後の合意が「方向性」だけでなく「具体的な内容・文章」への合意になっているか

少しでも疑わしければ違反として報告してください。

違反がなければ「OK」とだけ出力してください。
違反がある場合は、どの原則に違反しているか・どう修正すべきかを日本語で簡潔に出力してください。「OK」という文字列を含めないでください。
"""


def claude_announced_file(transcript_path: str, file_path: str, n: int = 20) -> bool:
    """直近 n 件の会話で Claude がそのファイル名を言及しているか確認する。"""
    try:
        with open(transcript_path, encoding='utf-8') as f:
            transcript = json.load(f)
    except Exception:
        return True  # 読み取れない場合は通過させる

    messages = transcript.get('messages', [])
    recent = messages[-n:] if len(messages) >= n else messages
    basename = os.path.basename(file_path)

    for msg in recent:
        if msg.get('role') != 'assistant':
            continue
        content = msg.get('content', '')
        if isinstance(content, list):
            parts = [
                c.get('text', '')
                for c in content
                if isinstance(c, dict) and c.get('type') == 'text'
            ]
            content = '\n'.join(parts)
        if file_path in content or (basename and basename in content):
            return True

    return False


def get_last_assistant_text(transcript_path: str) -> str | None:
    try:
        with open(transcript_path, encoding='utf-8') as f:
            transcript = json.load(f)
    except Exception:
        return None

    messages = transcript.get('messages', [])
    for msg in reversed(messages):
        if msg.get('role') == 'assistant':
            content = msg.get('content', '')
            if isinstance(content, str):
                return content
            if isinstance(content, list):
                parts = [
                    c.get('text', '')
                    for c in content
                    if isinstance(c, dict) and c.get('type') == 'text'
                ]
                text = '\n'.join(parts).strip()
                if text:
                    return text
    return None


def get_recent_messages(transcript_path: str, n: int = 5) -> str:
    try:
        with open(transcript_path, encoding='utf-8') as f:
            transcript = json.load(f)
    except Exception:
        return ''

    messages = transcript.get('messages', [])
    recent = messages[-n:] if len(messages) >= n else messages
    lines = []
    for msg in recent:
        role = msg.get('role', '')
        content = msg.get('content', '')
        if isinstance(content, list):
            parts = [
                c.get('text', '')
                for c in content
                if isinstance(c, dict) and c.get('type') == 'text'
            ]
            content = '\n'.join(parts)
        if content:
            lines.append(f"[{role}]: {str(content)[:500]}")
    return '\n\n'.join(lines)


def call_claude(prompt: str, model: str = 'claude-sonnet-4-6') -> str:
    try:
        result = subprocess.run(
            ['claude', '-p', prompt, '--model', model],
            capture_output=True,
            text=True,
            timeout=60,
        )
        return result.stdout.strip()
    except Exception:
        return 'OK'


def handle_stop(data: dict) -> None:
    if data.get('stop_hook_active'):
        sys.exit(0)

    transcript_path = data.get('transcript_path')
    if not transcript_path:
        sys.exit(0)

    last_response = get_last_assistant_text(transcript_path)
    if not last_response or len(last_response.strip()) < 50:
        sys.exit(0)

    try:
        with open(CLAUDE_MD_PATH, encoding='utf-8') as f:
            claude_md = f.read()
    except Exception:
        sys.exit(0)

    prompt = STOP_REVIEW_PROMPT.format(
        claude_md=claude_md,
        response=last_response[:3000],
    )
    review_output = call_claude(prompt)

    if not review_output or review_output.upper().startswith('OK'):
        sys.exit(0)

    print(
        f"[CLAUDE.md レビュー] 以下の原則違反が検出されました。回答を見直してください:\n\n{review_output}",
        file=sys.stderr,
    )
    sys.exit(1)


def handle_edit(data: dict) -> None:
    transcript_path = data.get('transcript_path')
    if not transcript_path:
        sys.exit(0)

    tool_input = data.get('tool_input', {})
    file_path = tool_input.get('file_path', '（不明）')

    # 機械的な事前チェック: Claude がそのファイルを会話中に言及したか
    if not claude_announced_file(transcript_path, file_path):
        print(
            f"[編集予告なし] '{os.path.basename(file_path)}' への編集予告が直近の会話に見つかりません。\n"
            f"編集前にファイル名を明示してユーザーと合意してください。",
            file=sys.stderr,
        )
        sys.exit(1)

    recent_messages = get_recent_messages(transcript_path, n=20)
    if not recent_messages:
        sys.exit(0)

    try:
        with open(CLAUDE_MD_PATH, encoding='utf-8') as f:
            claude_md = f.read()
    except Exception:
        sys.exit(0)

    prompt = EDIT_REVIEW_PROMPT.format(
        claude_md=claude_md,
        recent_messages=recent_messages,
        file_path=file_path,
    )
    review_output = call_claude(prompt)

    if not review_output or review_output.upper().startswith('OK'):
        sys.exit(0)

    print(
        f"[CLAUDE.md レビュー / Edit] 以下の原則違反が検出されました。編集前に確認してください:\n\n{review_output}",
        file=sys.stderr,
    )
    sys.exit(1)


def main():
    try:
        data = json.load(sys.stdin)
    except Exception:
        sys.exit(0)

    tool_name = data.get('tool_name', '')

    if tool_name == 'Edit':
        handle_edit(data)
    else:
        handle_stop(data)


if __name__ == '__main__':
    main()
