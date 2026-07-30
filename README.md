# 🤖 Claude Code with Amazon Nova via LiteLLM Proxy

This guide explains how to run **Claude Code** using **Amazon Bedrock Nova models** through a **LiteLLM Proxy** running in Docker.

---

# Prerequisites

- Docker installed
- AWS IAM User with Bedrock access
- Claude Code installed
- VS Code (optional)

---

# 1. Create an IAM Policy

Attach the following IAM policy to the AWS user that will be used by the LiteLLM proxy.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowNovaOnly",
      "Effect": "Allow",
      "Action": [
        "bedrock:InvokeModel",
        "bedrock:InvokeModelWithResponseStream"
      ],
      "Resource": [
        "arn:aws:bedrock:*::foundation-model/amazon.nova-*"
      ]
    }
  ]
}
```

---

# 2. Configure Your Shell

Append the following to your `~/.bashrc`.

```bash
export ANTHROPIC_BASE_URL="http://127.0.0.1:4000"
export ANTHROPIC_AUTH_TOKEN="your-auth-token-as-you-wish"
export ANTHROPIC_MODEL="claude-haiku-4-5"
export CLAUDE_CODE_MAX_OUTPUT_TOKENS=9500
```

> **Note**
>
> Do **not** place the following variables in `~/.bashrc`:
>
> - `AWS_ACCESS_KEY_ID`
> - `AWS_SECRET_ACCESS_KEY`
> - `AWS_REGION`
>
> These should only be passed to the Docker container as environment variables.

Reload your shell:

```bash
source ~/.bashrc
```

---

# 3. Configure Claude Code

Create or edit:

```
~/.claude/settings.json
```

Contents:

```json
{
  "theme": "dark"
}
```

The Claude Code configuration remains intentionally minimal because the model configuration is provided through the environment variables in `~/.bashrc`.

---

# 4. Configure VS Code Extension (Optional)

Create:

```
.vscode/settings.json
```

```json
{
  "claudeCode.disableLoginPrompt": true,
  "claudeCode.useTerminal": true,
  "claudeCode.environmentVariables": [
    {
      "name": "ANTHROPIC_BASE_URL",
      "value": "http://127.0.0.1:4000"
    },
    {
      "name": "ANTHROPIC_AUTH_TOKEN",
      "value": "your-auth-token-as-you-wish"
    },
    {
      "name": "ANTHROPIC_MODEL",
      "value": "claude-haiku-4-5"
    },
    {
      "name": "CLAUDE_CODE_MAX_OUTPUT_TOKENS",
      "value": "9500"
    }
  ]
}
```

---

# Running Claude Code

## 1. Pull the LiteLLM Docker image

```bash
docker pull priyanshuvaliya18/litellm-proxy:latest 
```

---

## 2. Start the LiteLLM Proxy

Replace the placeholder AWS credentials with your IAM user's credentials.

```bash
docker run -d \
  --name litellm-proxy \
  -p 4000:4000 \
  -e AWS_ACCESS_KEY_ID=<your-nova-iam-access-key> \
  -e AWS_SECRET_ACCESS_KEY=<your-nova-iam-secret> \
  -e AWS_REGION=us-east-1 \
  -e LITELLM_MASTER_KEY=your-auth-token-as-you-wish \
  priyanshuvaliya18/litellm-proxy:latest
```

---

## 3. Verify the container is running

```bash
docker ps
```

You should see the `litellm-proxy` container running.

---

## 4. Reload your shell

```bash
source ~/.bashrc
```

---

## 5. Launch Claude Code

```bash
claude
```

---

# Using VS Code

Once `.vscode/settings.json` is in place:

1. Open your project.

```bash
code .
```

2. Use the integrated terminal exactly as you would normally.
3. Alternatively, open the **Claude Code** panel inside VS Code.

No additional configuration is required.

---

# Architecture

```
Claude Code
      │
      ▼
LiteLLM Proxy (Docker)
      │
      ▼
Amazon Bedrock
      │
      ▼
Amazon Nova Models
```

---

# Environment Variables

| Variable | Value |
|----------|-------|
| `ANTHROPIC_BASE_URL` | `http://127.0.0.1:4000` |
| `ANTHROPIC_AUTH_TOKEN` | `your-auth-token-as-you-wish` |
| `ANTHROPIC_MODEL` | `claude-haiku-4-5` |
| `CLAUDE_CODE_MAX_OUTPUT_TOKENS` | `9500` |

---

# Docker Environment Variables

These are supplied **only** when running the container.

| Variable | Description |
|----------|-------------|
| `AWS_ACCESS_KEY_ID` | IAM Access Key |
| `AWS_SECRET_ACCESS_KEY` | IAM Secret Key |
| `AWS_REGION` | AWS Region (e.g. `us-east-1`) |
| `LITELLM_MASTER_KEY` | Proxy authentication key |

---

# Quick Start

```bash
# Pull image
docker pull priyanshuvaliya18/litellm-proxy:latest 

# Run
docker run -d \
  --name litellm-proxy \
  -p 4000:4000 \
  -e AWS_ACCESS_KEY_ID=<ACCESS_KEY> \
  -e AWS_SECRET_ACCESS_KEY=<SECRET_KEY> \
  -e AWS_REGION=us-east-1 \
  -e LITELLM_MASTER_KEY=your-auth-token-as-you-wish \
  priyanshuvaliya18/litellm-proxy:latest

# Verify
docker ps

# Reload shell
source ~/.bashrc

# Start Claude Code
claude
```
