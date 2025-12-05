# 懒人 AI 开发环境（Lanren AI）

懒人 AI 是一个面向 **非开发者 / Windows 零基础用户** 的脚本集合，目标是：

- 帮你在本机一次性装好一批「AI 开发工具」，  
- 但并不是让你自己去写代码，  
- 而是让你可以用 **Claude Code、Codex 等「编码智能体」来帮你完成日常工作**，尤其是：  
  - 各种文档的整理、转换、润色、总结；  
  - 表格 / CSV 数据的简单处理；  
  - 批量生成或修改文本、脚本、配置文件等。

整个项目帮你自动安装并准备好：

- 基础命令行工具（Git、jq、yq 等）
- 开发环境（Python / Node.js 及相关包管理器）
- AI 编码助手：**Claude Code CLI** 和 **OpenAI Codex CLI**
- 一些基于 MCP 的扩展工具（如 Context7、Tavily、MarkItDown）

你不需要会编程，也不需要会用 git 或命令行，只要按照下面的步骤一点点双击脚本，即可把电脑变成「可以随时召唤 AI 编码助手帮忙处理文档与日常任务」的工作台。

---

## 一、如何从 GitHub 下载本项目（不会用 git 也没关系）

1. 打开浏览器，访问本仓库的 GitHub 页面：  
   `https://github.com/igamenovoer/lanren-ai`
2. 在页面右上方、文件列表上方，找到一个绿色的按钮：**Code**，点击它。  
3. 在弹出的菜单里，点击：**Download ZIP**。  
   - 浏览器会开始下载一个压缩包，例如：`lanren-ai-main.zip`。
4. 下载完成后：  
   - 可以在浏览器下载栏中点击「在文件夹中显示」，  
   - 或者打开资源管理器，在「下载」文件夹里找到这个 `.zip` 文件。
5. 右键这个 `lanren-ai-main.zip` 文件，选择：**全部提取...（Extract All）**。  
6. 在弹出的对话框中，选择一个你想放项目的目录，比如：  
   - 可以放在 `D:` 盘的某个文件夹里，也可以放在桌面或文档里，**位置完全由你决定**。  
   - 记住你选择的这个文件夹路径，后面会用到。  
7. 解压完成后，会出现一个包含 `components`、`scripts` 等子目录的文件夹，例如：  
   - `C:\Users\你的用户名\Desktop\lanren-ai-main`  
   - 或者你自己指定的位置下的 `lanren-ai` 之类的名字。  

> 为了方便说明，下面会把你解压出来的这个文件夹统一称为：**「项目目录」**。  
> 只要你看到的文件夹里有 `components`、`scripts` 等子目录，就可以把它当成「项目目录」来看待。

---

## 二、安装方式总览：一键安装 vs 手动安装

你有两种安装方式：

- **一键安装**：在项目根目录直接双击 `install-everything.bat`，脚本会按推荐顺序自动调用各组件的安装脚本，尽量一次性完成全部环境搭建。  
- **手动安装**：按照下面的「五、手动安装」章节，从第 1 步到第 8 步，进入每个 `components\...\` 目录，手动双击对应的 `.bat` 文件。

需要特别说明的是：

- 每台电脑的 **Windows 版本、已安装软件、网络环境** 都可能不同，一键安装脚本在某些机器上可能会在中途某一步失败。  
- 如果一键安装过程中出现错误提示，或者黑窗口一闪而过你没看清楚，**不要紧张**，可以改用「手动安装」方式，一步一步来。  
- 大部分安装脚本都尽量设计为 **幂等** 的，也就是多运行几次一般不会破坏已有环境。  
- 在安装过程中，脚本有时会在黑色窗口里问你类似 `Do you want to continue? (Y/N)`、`是否继续？(Y/N)` 这样的 **是 / 否** 问题：  
  - 如果你看不懂具体含义，又不确定选什么，一般可以直接输入 `y` 然后按回车，相当于选择「是 / 继续」。  
  - 极少数危险操作（例如删除大量数据）本项目的脚本不会默认去做，所以对本仓库自带的安装脚本来说，**选 Yes 通常是安全的默认选项**。  

推荐顺序：

1. **优先尝试一键安装**（简单、省心）；  
2. 如果中途出现问题，再回到 README，按「手动安装」章节一项一项地补装或重装。  

---

## 三、一键安装（推荐先尝试）

一键安装脚本位于项目根目录：

- 路径：`<项目目录>\install-everything.bat`

使用方法：

1. 打开资源管理器，进入你的「项目目录」（也就是你刚刚解压出来、里面有 `components` 子目录的那个文件夹）。  
2. 找到 `install-everything.bat`，**双击运行**。  
3. 黑色命令行窗口会弹出，脚本会依次执行这些操作：  
   - 调整当前用户的 PowerShell 脚本执行权限（调用同目录下的 `enable-ps1-permission.bat`）；  
   - 安装 / 检查：winget、PowerShell 7、VS Code；  
   - 安装常用命令行工具：jq、yq、Git；  
   - 安装开发基础工具：uv、pixi、Node.js、Bun、aria2；  
   - 安装 AI 相关组件：Claude Code CLI、Codex CLI、Context7 MCP、MarkItDown；  
   - 为后续的「跳过登录 / 使用自定义 Endpoint」预备好必要的脚本（`config-custom-api-key.bat` / `.ps1` 等），但 **不会自动修改你的 API Key 或 Codex/Claude 登录状态**；  
   - **不会自动运行 `config-*.bat` 配置脚本**（例如 Tavily MCP 配置、自定义 API Key / 代理、跳过登录等），这些属于「可选配置」，需要你在安装完后进入对应 `components\...\` 目录按需双击执行。  
4. 如果某个子步骤执行失败，窗口中会出现类似：  
   - `[WARN] Step script exited with error code: ...`  
   - 同时会显示是哪一个 `components\...\install-comp.bat`（或 `config-*.bat`）出错。  
   脚本不会在这里中断，而是继续尝试后面的安装步骤；安装结束后，你可以：  
   - 在窗口中向上滚动，找到失败步骤对应的组件路径和描述；  
   - 按照「手动安装」章节，进入对应 `components\...\` 目录，单独重新运行那个 `.bat`。  

重要提醒：

- 由于安装内容较多，且依赖网络和系统环境，一键安装 **可能在某一步失败或出错**，这是正常情况。  
  - 如果你对报错信息看不懂，或者脚本行为让你不放心，可以直接关闭窗口，改用「手动安装」一项一项来，会更容易定位问题。  
- 一键脚本本身不会做特别危险的操作，只是按顺序调用各组件目录里的 `.bat` 安装脚本；这些脚本大多数都可以安全地重复执行。  
- 其中「winget」这一步，在 **Windows 11 或较新的 Windows 10（例如 22H2 及之后版本）** 上通常已经不需要了：  
  - 如果系统已经自带 `winget`，对应的 PowerShell 脚本会自动检测并跳过，不会重复安装。  

如果一键安装执行完后仍有某些组件缺失，请按下一节的「手动安装」说明进行补装。  

---

## 四、手动安装（适合一步一步确认的用户）

如果你不想使用一键安装，或者一键安装过程中某一步失败，可以按照下面的步骤 **手动安装**。  
每一步的基本操作都类似：

> 进入对应的 `components\子目录` → 双击本目录下的 `.bat` 文件 → 等脚本跑完 → 关闭窗口。

下面的说明都按推荐顺序列出，你也可以根据自己需求跳过不需要的组件。

---

### 手动安装第 1 步：检查 / 安装 winget（Windows 包管理器）

1. 打开资源管理器，进入：「项目目录」下的 `components\winget` 目录  
2. 双击：`install-comp.bat`  
3. 等待窗口执行完毕，看到“已安装 / 已存在”之类提示后关闭窗口。

说明：

- Windows 11 和较新的 Windows 10（例如 22H2 及以后版本）通常已经自带 `winget`。  
- 即使已经安装过，脚本也会先检查系统是否有 `winget`，如果有就直接跳过，不会重复安装或破坏现有环境。  
- 如果你已经确认命令行里能运行 `winget`，这一步可以跳过，但运行一次也没有坏处。  

---

### 手动安装第 2 步：安装 PowerShell 7

1. 进入：「项目目录」下的 `components\powershell-7` 目录  
2. 双击：`install-comp.bat`  
3. 安装完成后，建议重启一次 PowerShell 或电脑。

PowerShell 7 会作为后续脚本的推荐运行环境，更稳定、功能也更完整。

---

### 手动安装第 3 步：安装 VS Code（代码编辑器）

1. 进入：「项目目录」下的 `components\vscode` 目录  
2. 双击：`install-vscode-app.bat`，安装 VS Code 软件本体。  
3. 安装完成并确认 VS Code 能正常打开后，再双击：`install-extensions.bat`，自动安装推荐插件：  
   - Python 扩展  
   - Git 扩展  
   - Markdown Preview Enhanced  
   - Rainbow CSV  
   - Excel Viewer  
   - OpenAI Codex 插件  
   - Claude Code 插件  
   - Cline 等辅助插件  

---

### 手动安装第 4 步：安装常用命令行小工具

依次进入下面三个目录，每个目录里双击一次 `install-comp.bat`：

1. `components\jq\install-comp.bat`（安装 JSON 处理工具 `jq`）  
2. `components\yq\install-comp.bat`（安装 YAML 处理工具 `yq`）  
3. `components\git\install-comp.bat`（安装 Git 版本控制）  
   - 也就是说：先进入「项目目录」，再按顺序进入对应的 `components\...\` 子目录并双击里面的 `install-comp.bat`。  

每个脚本执行完之后可以直接关闭窗口，再进行下一步。

---

### 手动安装第 5 步：安装开发基础工具（Python / Conda / Node.js 等）

依然是「进入目录 → 双击 `.bat`」的方式，推荐安装顺序如下：

1. `components\uv\install-comp.bat`  
   - 安装 Python 相关的现代包管理 / 运行工具。  
2. `components\pixi\install-comp.bat`  
   - 安装基于 Conda 的环境管理工具。  
3. `components\nodejs\install-comp.bat`  
   - 安装 Node.js 与 npm。  
4. `components\bun\install-comp.bat`  
   - 安装 Bun（快速的 JS 运行时和包管理器），后续为 Tavily MCP 配置时会用到。  
5. `components\aria2\install-comp.bat`（可选但推荐）  
   - 安装 aria2 下载工具，用于某些脚本的加速下载。  

如果中间有步骤失败，可以稍后重试；大部分脚本都可以安全地重复执行。

---

### 手动安装第 6 步：安装 Claude Code CLI，并可选配置 Tavily / 自定义 API

#### 6.1 安装 Claude Code CLI

1. 进入：「项目目录」下的 `components\claude-code-cli` 目录  
2. 双击：`install-comp.bat`  
3. 等待安装完成，窗口提示成功后关闭。  

#### 6.2 配置登录相关和自定义 API 入口

在 `components\claude-code-cli` 目录下，你可以按需双击这些配置脚本：

- `config-skip-login.bat`  
  - 作用：在 `%USERPROFILE%\.claude.json` 中写入 / 更新 `hasCompletedOnboarding = true`，让 Claude Code CLI 在本机启动时直接进入可用状态，而不会再次弹出首启登录 / Onboarding 向导。  
  - 一般来说，`install-comp.bat` 已经会做一次类似处理；如果你换机、重装 CLI 或希望「强制认定已经完成 Onboarding」，可以单独再跑一次这个脚本。  

- `config-custom-api-key.bat`  
  - 作用：  
    - 在 PowerShell 中创建一个别名命令，例如 `claude-kimi`。  
    - 以后在 PowerShell 里输入 `claude-kimi`，脚本会自动设置好自定义 Endpoint 和 API Key，并以此启动 `claude`。  
  - 如果你在寻找第三方兼容 Claude / OpenAI 的代理或网关，可以参考这个收集仓库：  
    - <https://github.com/mn-api/awesome-ai-proxy>  
    - 里面列出了很多第三方 API 提供商，你可以从中挑选一个支持 Claude / OpenAI 的服务，按照对方文档拿到「接口地址（Base URL）」和「API Key」，再填进本脚本提示即可。  
   - 如果你想使用国内厂商提供的兼容接口，也可以考虑：  
     - SiliconFlow（硅基流动）：<https://siliconflow.cn/>（提供多家模型的统一 API）  
     - Kimi 官方网站：<https://kimi.moonshot.cn/>（按官方文档申请并获取对应的 API Key）  
     具体怎么获取、使用这些平台的 Key，请以各自官网的说明为准。  

#### 6.3 为 Claude 配置 Context7 MCP（可选）

Context7 MCP 可以为 Claude 提供更强的代码理解、项目上下文检索等能力。前提是你已经按第 8 步安装了 Context7 MCP 服务器（`components\context7-mcp\install-comp.bat`）。

在 `components\claude-code-cli` 目录下双击：

- `config-context7-mcp.bat`  
  - 作用：在 Claude Code 的配置中注册 Context7 MCP 服务器（通常基于 `@upstash/context7-mcp` 或类似实现）。  
  - 脚本会调用已安装的 Context7 MCP，并写入合适的 MCP 配置，让 `claude` 可以直接调用 Context7 提供的工具。  

如果你暂时不需要更高级的上下文管理，可以先跳过这一步。

#### 6.4 为 Claude 配置 Tavily MCP（可选）

Tavily MCP 可以让 Claude 具备联网搜索等能力。使用前需要先在 Tavily 官网申请一个 API Key：

1. 打开浏览器访问：<https://app.tavily.com/home>  
2. 注册或登录 Tavily 账号。  
3. 在控制台（Dashboard）中找到 API Keys 相关页面，创建并复制一个新的 Key。  

然后在 `components\claude-code-cli` 目录下双击：

- `config-tavily-mcp.bat`  
  - 运行过程中脚本会提示你输入 Tavily API Key，把刚刚复制的那一串粘贴进去即可。  
  - 脚本会自动完成 Tavily MCP 的安装与在 Claude Code 中的注册。  

如果你暂时不需要联网搜索，可以先跳过这一步。

---

### 手动安装第 7 步：安装 OpenAI Codex CLI，并配置 Tavily / 自定义 API

#### 7.1 安装 Codex CLI

1. 进入：「项目目录」下的 `components\codex-cli` 目录  
2. 双击：`install-comp.bat`  
3. 等待脚本提示安装成功后关闭窗口。  

#### 7.2 配置 Codex 登录与自定义 OpenAI 兼容 API

在同一目录下，你可以按需双击这些脚本：

- `config-custom-api-key.bat`  
  - 作用：  
    - 在 PowerShell 中创建一个类似 `codex-openai-proxy` 的命令别名。  
    - 这个别名会自动设置 `OPENAI_BASE_URL` 和 `OPENAI_API_KEY`，然后启动 `codex`。  
    - 同时更新 Codex 的 `config.toml`，创建一个以别名为基础的 `model_provider` 条目，配置自定义 `base_url` / `env_key`，并设置 `requires_openai_auth = false`，从而跳过 Codex 的登录界面。  
  - 如果你希望使用第三方 OpenAI 兼容代理（比如国内加速或自建代理），也可以参考：  
    - <https://github.com/mn-api/awesome-ai-proxy>  
    - 在该列表中挑选一个支持 OpenAI 协议的服务，按对方文档拿到接口地址和 API Key，再在本脚本的提示中填入即可。  
   - 如果你更倾向于使用国内厂商的兼容接口，同样可以关注：  
     - SiliconFlow（硅基流动）：<https://siliconflow.cn/>  
     - Kimi 官方网站：<https://kimi.moonshot.cn/>  
     这些平台通常会提供 OpenAI 协议或相似的兼容层，获取 API Key 和调用方式都以各自官方文档为准。  

#### 7.3 为 Codex 配置 Context7 MCP（可选）

当你已经按第 8 步安装好 Context7 MCP（`components\context7-mcp\install-comp.bat`）后，可以在 Codex 中启用它：

- 双击：`components\codex-cli\config-context7-mcp.bat`  
  - 脚本会在 Codex 的 `config.toml` 中写入 `[mcp_servers.context7]`（或类似）配置，指向已安装的 Context7 MCP 服务器。  
  - 这样，在 `codex` 中就可以直接使用 Context7 作为 MCP 工具源，用于项目上下文检索等任务。  

如果你主要使用 Tavily 或不需要 Context7，暂时可以跳过这一步。

#### 7.4 为 Codex 配置 Tavily MCP（可选）

- 双击：`components\codex-cli\config-tavily-mcp.bat`  
  - 脚本会使用 Bun 安装 Tavily MCP，并在 Codex 的 `config.toml` 中写入 `[mcp_servers.tavily]` 配置，使用 `bunx tavily-mcp@latest` 启动 MCP 服务器。  
  - 同样需要 Tavily API Key，获取方式与第 6 步相同：  
    1. 打开 <https://app.tavily.com/home> 并登录。  
    2. 在 Tavily 控制台中创建并复制一个 API Key。  
    3. 运行 `config-tavily-mcp.bat` 时按提示粘贴该 Key。  

如果你只想先简单体验 Codex CLI，最少可以只运行 `install-comp.bat`，直接用官方登录流程；  
如果你想一开始就走「自定义 Endpoint + API Key + 跳过登录界面」的路线，可以在安装后再运行 `config-custom-api-key.bat`，根据提示配置一个专用别名（例如 `codex-openai-proxy`）。  

---

### 手动安装第 8 步：安装 MCP / 文本处理插件

最后，再安装两个常用扩展组件：

1. 「项目目录」下的 `components\context7-mcp\install-comp.bat`  
   - 为 Codex / 其他 MCP 客户端准备 Context7 相关的 MCP 服务器。  
2. 「项目目录」下的 `components\markitdown\install-comp.bat`  
   - 安装 MarkItDown，用于更好地处理和转换 Markdown 内容。  

到这里，一个完整的「懒人 AI 开发环境」就搭建完成了。

---

## 五、使用流程小结

1. 按「一、如何从 GitHub 下载本项目」中的说明，先下载并解压仓库到本地，并记住解压出来的「项目目录」。  
2. 选择安装方式：  
   - **方式 A：一键安装（推荐先尝试）**  
     - 在项目根目录双击 `install-everything.bat`。  
     - 如果所有步骤都顺利完成，那你可以跳过下面的手动安装章节。  
     - 如果脚本中途报错或某些步骤失败，请记住提示中出现的 `components\...\` 路径，然后参考「四、手动安装」章节，对应步骤进行人工重试。  
   - **方式 B：手动安装（更稳定、可控）**  
     - 按照「四、手动安装」中第 1 步到第 8 步的顺序，依次进入各个 `components\...\` 目录，双击对应的 `.bat` 文件。  
     - 可以按需跳过你不需要的组件（例如暂时不用 Codex / 某些 MCP），只装你想要的部分。  
3. 安装完成后：  
   - 打开 VS Code，确认推荐插件已安装。  
   - 打开 PowerShell 7 终端，尝试运行：`claude`、`codex`，以及你在 `config-custom-api-key` 中配置的别名命令。  
   - 如需联网搜索或使用 Tavily 相关功能，在运行 Tavily 配置脚本时输入 / 粘贴你的 Tavily API Key。  

---

## 六、如何在 PowerShell / VS Code 中启动 Claude 和 Codex

当你完成前面的安装与配置后，就可以在命令行或 VS Code 里启动 Claude / Codex 作为「编码助手」，帮你处理各种文档与日常任务。

- **在 PowerShell 7 中启动**（推荐）：  
  1. 在开始菜单中搜索并打开「PowerShell 7」或「PowerShell 7 (x64)」。  
  2. 在出现的黑色/蓝色窗口中直接输入：  
     - `claude`（启动 Claude Code CLI）  
     - `codex`（启动 Codex CLI）  
     - 或者你通过 `config-custom-api-key.bat` 配置过的别名，例如 `claude-kimi`、`codex-openai-proxy` 等。  

- **在 Windows PowerShell 5.x 中启动**：  
  - 如果你习惯用系统自带的「Windows PowerShell」，同样可以在窗口里输入 `claude`、`codex` 或自定义别名来启动。  
  - 建议优先使用 PowerShell 7；PowerShell 5 主要作为备用。  

- **在 VS Code 里使用集成终端**：  
  1. 打开 VS Code。  
  2. 使用快捷键 ``Ctrl + ` ``（键盘左上角 ESC 下方的反引号键）打开「终端」。  
  3. 如果终端顶部显示的不是 PowerShell 7，可以点击右上角的小下拉菜单，选择 `PowerShell 7` 或类似选项。  
  4. 在这个终端里同样可以输入 `claude`、`codex` 或自定义别名来启动。  

- **配合 VS Code 插件使用**：  
  - 如果你安装了 Claude / Codex 相关的 VS Code 插件（通过 `components\vscode\install-extensions.bat`），也可以在 VS Code 界面中：  
    - 打开命令面板（`Ctrl + Shift + P`），搜索插件提供的命令；  
    - 或在侧边栏找到对应的面板，按插件的界面引导操作。  
  - 插件和命令行可以同时存在：你可以在终端里用 `claude` / `codex` 处理某些任务，也可以在 VS Code 里直接选中文本调用插件。  

---

## 七、注意事项

- 大多数脚本都尽量设计成 **幂等** 的：多运行几次，一般不会破坏原有配置；但在修改前备份重要配置文件始终是好习惯。  
- 某些安装过程依赖外网（npm、Bun 下载、MCP 服务等），如果你在中国大陆使用，建议配置好代理或者使用镜像源。  
- 如果你对某个组件暂时不需要，可以跳过对应步骤；README 中的顺序只是一个对新手比较友好的推荐路径。  
- 如果你多次重试某个步骤仍然失败，或者错误信息看不懂，可以把问题反馈到本项目的 GitHub：  
  1. 打开浏览器访问：`https://github.com/igamenovoer/lanren-ai`  
  2. 点击页面上方的 **Issues** 选项卡，再点击右侧绿色的 **New issue** 按钮。  
  3. 在标题中简单写明「哪一步出错」（例如：`Step 6 Claude Code install failed`）。  
  4. 在内容中说明：你的 Windows 版本、你是通过一键安装还是手动安装、出错的是哪一步，以及大致的报错文字。  
  5. 在 Issue 里尽量上传两样东西：  
     - **出错时黑色命令行窗口的截图**（把整个窗口一起截进去）。  
     - **相关的日志文件**：所有组件安装与配置脚本都会把详细日志写到当前工作目录下的 `lanren-cache` 目录，例如：  
       - `<项目目录>\lanren-cache\logs\...`  
       请在 `lanren-cache\logs` 下面找到最近生成的 `.log` 文件（文件名里通常包含组件名和时间戳），把它一并作为附件上传。  
  这些信息可以帮助作者更快定位问题，给出针对性的解决方案。  

欢迎你根据自己的习惯在本地继续扩展这些脚本，打造属于你自己的「懒人 AI 开发环境」。
