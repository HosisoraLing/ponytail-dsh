# ponytail-dsh

[Ponytail](https://github.com/DietrichGebert/ponytail) 的 **DeepSeek Harness（DSH）适配层**：在上游 instruction-tier 移植的基础上，把「档位不持久」这个缺口补掉。

ponytail 是一套「懒惰高级工程师」提示词：用最少的新代码完整解决问题，每次回复末尾交代跳过了什么、有什么风险。上游对 DSH 只做到指令层（AGENTS.md + 六个 skill），档位 `lite/full/ultra/off` 不跨会话。本适配层用 DSH 自己的机制把它补成插件级体验。

## 比上游 DSH 移植多了什么

| 能力 | 上游 instruction-tier | ponytail-dsh |
|---|---|---|
| 六个 skill（`/ponytail-review` 等） | ✅ | ✅ 装进 `$DSH_HOME/skills` |
| 常驻规则集 | ✅ `AGENTS.md` | ✅ 标记块写入 `$DSH_HOME/AGENTS.md` |
| 档位跨会话持久 | ❌ | ✅ `$DSH_HOME/.ponytail-active`，与上游 hooks 的 flag 文件同一格式 |
| 默认档位来源 | — | `PONYTAIL_DEFAULT_MODE` → `config.json` 的 `defaultMode` → `full`，与上游优先级一致 |
| 卸载还原 | 手动删文件 | ✅ 整块移除标记块，你自己写的 `AGENTS.md` 内容原样保留 |
| subagent 注入 | ❌ | 不需要：fork 子代理继承会话，独立子代理同样加载 `~/.dsh/AGENTS.md` |

## 安装

Windows（PowerShell，`powershell` 或 `pwsh` 均可）：

```powershell
powershell -File install.ps1
```

macOS / Linux：

```bash
bash install.sh
```

卸载：

```powershell
powershell -File install.ps1 -Uninstall
```

```bash
bash install.sh --uninstall
```

默认装进 `$DSH_HOME`（未设置时是 `~/.dsh`）。想装到共享目录 `~/.agents` 的话，把 `AGENTS.md` 与 `skills/` 照 [DSH 根目录表](#工作原理对应-dsh-内部) 放过去即可。

## 用法

- `/ponytail [lite|full|ultra|off]` —— 切档位并写入 flag 文件；不带参数报告当前档位。也可以说「切到 ultra 档」「stop ponytail」「normal mode」。
- `/ponytail-review [target]` —— 审一次变更（bug、安全、真实负载、缺测试的危险代码、慢路径、可删的代码）
- `/ponytail-audit [target]` —— 审整个仓库，产出排序报告，不改任何文件
- `/ponytail-debt` —— 把 `shortcut:` 注释汇成欠账清单
- `/ponytail-gain` —— 展示基准测得的收益（代码量、成本、速度）
- `/ponytail-help` —— 速查卡

## 工作原理（对应 DSH 内部）

- **常驻规则**：`dsh-agent-instructions` 把 `$DSH_HOME/AGENTS.md` → `~/.agents/AGENTS.md` → 项目 `AGENTS.md`/`CLAUDE.md` 链作为基线注入每个会话的首个请求（默认预算 65536 字节）。ponytail 规则集约 2.7 KB，装在链首。
- **skill 发现**：`dsh-skill-filesystem` 扫描一层深度 `<root>/<name>/SKILL.md`，frontmatter 要求 kebab-case 的 `name` 与 `description`。根目录优先级：`<projectRoot>/.dsh/skills`（100）、`<projectRoot>/.agents/skills`（200）、`customSkillDirs`（300）、`<dshHome>/skills`（400）、`<agentsHome>/skills`（500）。目录被监视，增删 skill 无需重启（已打开的会话要重连或新开会话才会刷新目录）。
- **档位持久化**：DSH 没有生命周期 hook，所以档位由 AGENTS.md 里的约定驱动——agent 在编码任务开始时读 `$DSH_HOME/.ponytail-active`，切换档位时写入。flag 文件格式与上游 `hooks/ponytail-runtime.js` 的 `.ponytail-active` 完全一致（一个档位词），因此与其他 agent 的 ponytail 安装互通。

## 不做的事（YAGNI）

- 不做 statusline 徽标与 cost band：DSH 没有对应机制。
- 不做 subagent hook 注入：DSH 子代理天然读到同一套指令，fork 子代理直接继承会话。
- 不改 DSH 本体、不写 DSH 配置文件。

## 文件清单

| 文件 | 说明 |
|---|---|
| `AGENTS.md` | 常驻规则：上游 `AGENTS.md` 全文 + DSH 档位约定，整段包在 `ponytail-dsh` 标记块里 |
| `skills/ponytail/SKILL.md` | 上游懒惰模式 skill，末尾追加 DSH 档位持久化段 |
| `skills/ponytail-{review,audit,debt,gain,help}/SKILL.md` | 与上游逐字节一致 |
| `install.ps1` / `install.sh` | 安装与卸载，幂等，卸载可还原 |
| `LICENSE` | 本适配层，MIT |
| `LICENSE.upstream` | 上游 ponytail 的 MIT 许可（skills 与其规则文本的版权方） |

## English summary

A thin DeepSeek Harness adapter for [ponytail](https://github.com/DietrichGebert/ponytail). It installs the six upstream skills into `$DSH_HOME/skills`, injects the compact ruleset through the managed block in `$DSH_HOME/AGENTS.md`, and — the part upstream's instruction-tier port lacks — persists the `lite/full/ultra/off` level across sessions in `$DSH_HOME/.ponytail-active`, the same flag-file format upstream's lifecycle hooks use. `install.ps1 -Uninstall` / `install.sh --uninstall` removes exactly what was installed and restores your own `AGENTS.md` content. No statusline band, no hook injection: DSH subagents already load the same user-global instructions.

## 致谢与许可

基于 [DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail)（MIT）。`skills/` 下的六个 `SKILL.md` 与 `AGENTS.md` 规则文本来自上游，其版权声明见 `LICENSE.upstream`；本适配层其余部分以 MIT 发布，见 `LICENSE`。
