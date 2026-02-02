# Azure Authentication Demo for GitHub Actions

This repository demonstrates two methods of authenticating GitHub Actions to Azure:

1. **Service Principal + Client Secret** (legacy approach)
2. **Service Principal + OIDC / Federated Credentials** (recommended)

## Prerequisites

### Azure Setup

1. Create an App Registration in Entra ID
2. Create a Service Principal
3. Assign RBAC role (e.g., Contributor) to a resource group

### For Variant A (Client Secret)

Add these secrets to your GitHub repository:
- `AZURE_CLIENT_ID` - Application (client) ID
- `AZURE_CLIENT_SECRET` - Client secret value
- `AZURE_TENANT_ID` - Directory (tenant) ID
- `AZURE_SUBSCRIPTION_ID` - Subscription ID

### For Variant B (OIDC)

1. Add Federated Credential to your App Registration:
   - Issuer: `https://token.actions.githubusercontent.com`
   - Subject: `repo:YOUR_ORG/YOUR_REPO:ref:refs/heads/main`
   - Audience: `api://AzureADTokenExchange`

2. Add these secrets to your GitHub repository:
   - `AZURE_CLIENT_ID` - Application (client) ID
   - `AZURE_TENANT_ID` - Directory (tenant) ID
   - `AZURE_SUBSCRIPTION_ID` - Subscription ID

Note: No client secret needed for OIDC!

## Workflows

| Workflow | File | Trigger | Auth Method |
|----------|------|---------|-------------|
| Azure Login (Secret) | `azure-login-secret.yml` | Manual | Client ID + Secret |
| Azure Login (OIDC) | `azure-login-oidc.yml` | Manual | Federated Credentials |

## Usage

Go to Actions tab and manually trigger the workflow you want to test.
