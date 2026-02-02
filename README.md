# DevOps Training - Module 1: Connecting GitHub to Azure

## Prerequisites

- [Git](https://git-scm.com/downloads) installed
- [GitHub CLI (gh)](https://cli.github.com/) installed
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) installed
- GitHub account
- Azure subscription

---

## GitHub CLI Authentication

### Option 1: Interactive Login (Browser)

```bash
gh auth login
# Select: GitHub.com
# Select: HTTPS
# Select: Login with a web browser
# Copy the code and paste it in the browser
```

### Option 2: Login with Personal Access Token (PAT)

```bash
# Create PAT at: https://github.com/settings/tokens
# Required scopes: repo, read:org, workflow

# Login with token (interactive)
gh auth login
# Select: GitHub.com
# Select: HTTPS
# Select: Paste an authentication token
# Paste your PAT

# Or login with token from file
gh auth login --with-token < token.txt

# Or login with token from environment variable
echo "ghp_your_token_here" | gh auth login --with-token
```

### Verify Login

```bash
gh auth status
```

---

## Creating and Cloning a Repository

### Create a New Repository

```bash
# Create repo on GitHub and clone locally
gh repo create my-project --public --clone

# Or create from existing local folder
cd my-project
git init
gh repo create my-project --public --source=. --push
```

### Clone an Existing Repository

```bash
# Clone via GitHub CLI
gh repo clone owner/repo-name

# Or clone via Git
git clone https://github.com/owner/repo-name.git
```

---

## Git Workflow (Feature Branch → PR → Approval → Merge)

**Important:** Never push directly to `main`/`master`. Always use feature branches and pull requests.

1. Create a feature branch from `master`
2. Make changes and commit
3. Push feature branch to remote
4. Create a Pull Request
5. Code review and approval
6. Merge Pull Request
7. Update local master

---

## Outline

### 1.1 Introduction
- Why we need to connect GitHub to Azure
- Overview of authentication options
- Security aspects (secrets vs. OIDC)

### 1.2 Variant A: Service Principal + Secret

**Theory:**
- What is a Service Principal
- App Registration vs. Service Principal
- Role-Based Access Control (RBAC)

**Practical demo:**
1. Create App Registration in Azure AD
2. Generate client secret
3. Assign RBAC role (e.g., Contributor on RG)
4. Store credentials in GitHub Secrets:
   - `AZURE_CLIENT_ID`
   - `AZURE_CLIENT_SECRET`
   - `AZURE_TENANT_ID`
   - `AZURE_SUBSCRIPTION_ID`
5. Use `azure/login@v2` action

**Disadvantages:**
- Secret has expiration
- Secret is a sensitive credential

---

### 1.3 Variant B: Service Principal + OIDC (Workload Identity Federation)

**Theory:**
- What is OIDC and why it's more secure
- Federated credentials - how they work
- No secrets in GitHub

**Practical demo:**
1. Create App Registration
2. Configure Federated Credential:
   - Issuer: `https://token.actions.githubusercontent.com`
   - Subject: `repo:org/repo:ref:refs/heads/main`
3. Assign RBAC role
4. GitHub workflow with `permissions: id-token: write`
5. Login without secrets

---

### 1.4 Variant C: User Assigned Managed Identity (UAMI)

**Theory:**
- What is Managed Identity
- System vs. User Assigned
- When to use UAMI (self-hosted runners)

**Practical demo:**
1. Create UAMI in Azure
2. Assign RBAC role
3. Configure Federated Credential on UAMI
4. Assign UAMI to VM (self-hosted runner)
5. GitHub workflow without explicit credentials

**Advantages:**
- No secrets
- No expiration
- Centralized identity management

---

### 1.5 Comparison and Best Practices

| Aspect | SP + Secret | SP + OIDC | UAMI |
|--------|-------------|-----------|------|
| Secrets in GH | Yes | No | No |
| Expiration | Yes | No | No |
| Self-hosted only | No | No | Yes |
| Complexity | Low | Medium | Medium |

**Recommendations:**
- GitHub-hosted runners → SP + OIDC
- Self-hosted runners → UAMI
- Legacy/quick tests → SP + Secret

---

## Azure CLI Setup

### Create App Registration and Service Principal

```bash
# Login to Azure
az login

# Create App Registration
az ad app create --display-name "github-actions-demo"

# Save the appId from output
APP_ID=$(az ad app list --display-name "github-actions-demo" --query "[0].appId" -o tsv)

# Create Service Principal
az ad sp create --id $APP_ID

# Get Service Principal Object ID (needed for role assignment)
SP_OBJECT_ID=$(az ad sp show --id $APP_ID --query "id" -o tsv)

echo "Application (Client) ID: $APP_ID"
echo "Service Principal Object ID: $SP_OBJECT_ID"
```

### Create Client Secret (for Variant A)

```bash
# Create client secret (valid for 1 year)
az ad app credential reset \
  --id $APP_ID \
  --append \
  --years 1

# Save the "password" from output - this is your AZURE_CLIENT_SECRET
```

### Assign RBAC Role

```bash
# Get your subscription ID
SUBSCRIPTION_ID=$(az account show --query "id" -o tsv)

# Assign Contributor role on a resource group
az role assignment create \
  --assignee $APP_ID \
  --role "Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/YOUR_RESOURCE_GROUP"

# Or assign on entire subscription (less secure)
az role assignment create \
  --assignee $APP_ID \
  --role "Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID"
```

### Create Federated Credential (for Variant B - OIDC)

```bash
# For a specific branch (e.g., main)
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "github-main-branch",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:YOUR_ORG/YOUR_REPO:ref:refs/heads/main",
    "audiences": ["api://AzureADTokenExchange"],
    "description": "GitHub Actions - main branch"
  }'

# For pull requests
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "github-pull-requests",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:YOUR_ORG/YOUR_REPO:pull_request",
    "audiences": ["api://AzureADTokenExchange"],
    "description": "GitHub Actions - pull requests"
  }'

# For a specific environment (e.g., production)
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "github-production-env",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:YOUR_ORG/YOUR_REPO:environment:production",
    "audiences": ["api://AzureADTokenExchange"],
    "description": "GitHub Actions - production environment"
  }'
```

### Get Required Values for GitHub Secrets

```bash
# Display all values you need for GitHub secrets
echo "=== GitHub Secrets ==="
echo "AZURE_CLIENT_ID: $APP_ID"
echo "AZURE_TENANT_ID: $(az account show --query 'tenantId' -o tsv)"
echo "AZURE_SUBSCRIPTION_ID: $(az account show --query 'id' -o tsv)"
echo ""
echo "For Variant A only:"
echo "AZURE_CLIENT_SECRET: <from 'az ad app credential reset' output>"
```

---

## Demo Workflows

This repo contains two demo workflow files:

| Workflow | File | Auth Method |
|----------|------|-------------|
| Azure Login (Secret) | `.github/workflows/azure-login-secret.yml` | Client ID + Secret |
| Azure Login (OIDC) | `.github/workflows/azure-login-oidc.yml` | Federated Credentials |

---

## Configuration

### For Variant A (Client Secret)

Add these secrets to your GitHub repository (Settings → Secrets and variables → Actions):
- `AZURE_CLIENT_ID` - Application (client) ID
- `AZURE_CLIENT_SECRET` - Client secret value
- `AZURE_TENANT_ID` - Directory (tenant) ID
- `AZURE_SUBSCRIPTION_ID` - Subscription ID

### For Variant B (OIDC)

1. Create Federated Credential (see CLI commands above)
2. Add these secrets to your GitHub repository:
   - `AZURE_CLIENT_ID` - Application (client) ID
   - `AZURE_TENANT_ID` - Directory (tenant) ID
   - `AZURE_SUBSCRIPTION_ID` - Subscription ID

**Note:** No client secret needed for OIDC!

---

## Running the Workflows

1. Go to the **Actions** tab
2. Select the workflow you want to test
3. Click **Run workflow**
