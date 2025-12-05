How to skip Codex CLI login using OPENAI_API_KEY (current Codex version caveat)

This note documents a behavioral quirk in the current Codex CLI build that affects attempts to skip the login flow by overriding the built-in `openai` model provider in `config.toml`.

## Problem: requires_openai_auth override is ignored for built-in `openai`

In this Codex version, the core config loader builds the model provider map by:

- Starting from `built_in_model_providers()` (compiled-in defaults, including `"openai"` with `requires_openai_auth = true`).
- Then merging user-defined providers from `[model_providers]` in `config.toml` using `HashMap::entry(...).or_insert(...)`.

Relevant snippet (simplified) from `codex-rs/core/src/config/mod.rs`:

```rust
let mut model_providers = built_in_model_providers();
// Merge user-defined providers into the built-in list.
for (key, provider) in cfg.model_providers.into_iter() {
    // IMPORTANT: or_insert means built-ins win, user config is ignored on conflict
    model_providers.entry(key).or_insert(provider);
}

let model_provider_id = model_provider
    .or(config_profile.model_provider)
    .or(cfg.model_provider)
    .unwrap_or_else(|| "openai".to_string());
let model_provider = model_providers
    .get(&model_provider_id)
    .ok_or_else(|| std::io::Error::new(
        std::io::ErrorKind::NotFound,
        format!("Model provider `{model_provider_id}` not found"),
    ))?
    .clone();
```

The built-in provider map is defined in `codex-rs/core/src/model_provider_info.rs`:

```rust
pub fn built_in_model_providers() -> HashMap<String, ModelProviderInfo> {
    use ModelProviderInfo as P;

    [
        (
            "openai",
            P {
                name: "OpenAI".into(),
                base_url: std::env::var("OPENAI_BASE_URL")
                    .ok()
                    .filter(|v| !v.trim().is_empty()),
                env_key: None,
                env_key_instructions: None,
                experimental_bearer_token: None,
                wire_api: WireApi::Responses,
                query_params: None,
                http_headers: Some(
                    [("version".to_string(), env!("CARGO_PKG_VERSION").to_string())]
                        .into_iter()
                        .collect(),
                ),
                env_http_headers: Some(
                    [
                        ("OpenAI-Organization".to_string(), "OPENAI_ORGANIZATION".to_string()),
                        ("OpenAI-Project".to_string(), "OPENAI_PROJECT".to_string()),
                    ]
                    .into_iter()
                    .collect(),
                ),
                request_max_retries: None,
                stream_max_retries: None,
                stream_idle_timeout_ms: None,
                requires_openai_auth: true,
            },
        ),
        // ...
    ]
    .into_iter()
    .map(|(k, v)| (k.to_string(), v))
    .collect()
}
```

Because `or_insert` never overwrites an existing key, any `[model_providers.openai]` block defined in `~/.codex/config.toml` does not replace the built-in `"openai"` provider. As a result:

- Setting `requires_openai_auth = false` under `[model_providers.openai]` in `config.toml` has no effect.
- Setting `env_key = "OPENAI_API_KEY"` for `[model_providers.openai]` is also ignored.

The TUI login logic uses the *resolved* provider’s `requires_openai_auth` flag:

```rust
fn get_login_status(config: &Config) -> LoginStatus {
    if config.model_provider.requires_openai_auth {
        // read auth.json, show login screen if missing
    } else {
        LoginStatus::NotAuthenticated
    }
}

fn should_show_login_screen(login_status: LoginStatus, config: &Config) -> bool {
    if !config.model_provider.requires_openai_auth {
        return false;
    }
    login_status == LoginStatus::NotAuthenticated
}
```

Since the effective provider for `model_provider = "openai"` still has `requires_openai_auth = true` from the built-in map, Codex continues to show the login screen even when the TOML appears to disable it.

## Workaround: use a new provider ID and point `model_provider` at it

Until the upstream merge behavior is changed to let user config override built-ins, skipping login via `config.toml` should be done by:

1. Defining a *new* provider ID (for example `openai-env` or `openai-custom`), and
2. Setting `model_provider` to that ID.

Example `~/.codex/config.toml` snippet that skips the login screen and uses `OPENAI_API_KEY` from the environment:

```toml
# Use our custom provider instead of the built-in "openai"
model_provider = "openai-env"

[model_providers.openai-env]
name = "OpenAI via env key"
base_url = "https://api.openai.com/v1"
env_key = "OPENAI_API_KEY"
env_key_instructions = "Set OPENAI_API_KEY in your environment before starting Codex."
requires_openai_auth = false
```

Then ensure `OPENAI_API_KEY` is set in the environment before launching Codex:

```powershell
$env:OPENAI_API_KEY = "sk-..."    # Windows PowerShell / PowerShell 7+
codex
```

On Unix-like shells:

```bash
export OPENAI_API_KEY="sk-..."
codex
```

With this setup:

- Codex resolves `model_provider = "openai-env"` to the user-defined provider (no conflict with the built-in `"openai"` key).
- `config.model_provider.requires_openai_auth` becomes `false`.
- The login screen is skipped, and Codex uses `OPENAI_API_KEY` directly.

## How this interacts with helper scripts (PowerShell examples)

If you are writing Windows helper scripts (for example under `components\codex-cli`) that aim to configure Codex to skip login by editing `config.toml`, be careful to:

- Avoid trying to override `[model_providers.openai]` in the current Codex version.
- Instead, create a new provider and set `model_provider` to that provider ID.

Conceptual PowerShell approach when editing `config.toml`:

```powershell
$configPath = Join-Path $codexHome "config.toml"
$config = Get-Content $configPath -Raw -ErrorAction SilentlyContinue
if ($null -eq $config) { $config = "" }

# Ensure root model_provider is set
if ($config -notmatch '(?m)^\s*model_provider\s*=') {
    $config = "model_provider = `"openai-env`"`n" + $config
} else {
    $config = [regex]::Replace(
        $config,
        '(?m)^\s*model_provider\s*=.*$',
        'model_provider = "openai-env"'
    )
}

# Ensure [model_providers] table exists and add/replace our custom provider block
if ($config -notmatch '(?m)^\[model_providers\]') {
    $config += "`n[model_providers]`n"
}

$customBlock = @'

[model_providers.openai-env]
name = "OpenAI via env key"
base_url = "https://api.openai.com/v1"
env_key = "OPENAI_API_KEY"
env_key_instructions = "Set OPENAI_API_KEY in your environment before starting Codex."
requires_openai_auth = false
'@

# For a simple implementation, append the block (or replace an existing one via regex)
$config += $customBlock + "`n"

Set-Content -Path $configPath -Value $config -Encoding UTF8
```

This pattern avoids relying on overriding the built-in `"openai"` entry and works with the current merge behavior.

## Upstream fix (for future Codex versions)

The underlying issue is in the model provider merge strategy:

- Using `.or_insert(provider)` prefers built-in providers and silently discards user overrides for the same key.
- A more intuitive behavior for configuration would be to let user config override built-ins, for example:

```rust
let mut model_providers = built_in_model_providers();
for (key, provider) in cfg.model_providers.into_iter() {
    // Overwrite built-in entry when the user provides a matching key
    model_providers.insert(key, provider);
}
```

Once an upstream fix like this is in place, the simple pattern documented in `docs/example-config.md` (using `[model_providers.openai]` with `requires_openai_auth = false` and `env_key = "OPENAI_API_KEY"`) will start working as expected, and helper scripts can be simplified accordingly.

