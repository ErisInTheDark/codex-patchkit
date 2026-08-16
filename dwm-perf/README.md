# shared private desktop patch ♡

one private desktop per tool call made DWM progressively monch resources. this patch gives each Codex process one shared desktop instead, so the tiny tool-call beasties stop leaving glittery window-manager footprints everywhere (╬ Ò﹏Ó)و✧

## credit first!!!!

the design and original implementation came from [codengine's attached `codex-0.144.5-shared-private-desktop.patch`](https://github.com/openai/codex/issues/33192#issuecomment-5017820258) in [OpenAI Codex issue #33192](https://github.com/openai/codex/issues/33192).

codengine tested that `0.144.5` patch across thousands of tool calls without DWM memory or CPU growth. this folder contains a compatibility rebase of their work, nyot a replacement implementation wearing a fake moustache!!!!

## ribbons added for Codex 0.147.0

- elevated-runner IPC moves from `5` to `6`, instead of the original `4` to `5`
- the newer network-proxy restricting SID field and its test stay intact
- newer `ConsoleMode`, job-object, logging, and process-spawn behavior stay intact
- legacy, ConPTY, and elevated launches all reach the same process-owned private desktop

the process-global owner is the ONE lifecycle owner. callers select the right desktop target, but nobody starts a competing cache swamp, nyaaaa (｡•̀ᴗ-)✧
