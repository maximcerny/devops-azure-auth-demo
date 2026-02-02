# DevOps Školení - Modul 1: Propojení GitHub s Azure

## Osnova

### 1.1 Úvod
- Proč potřebujeme propojit GitHub s Azure
- Přehled možností autentizace
- Bezpečnostní aspekty (secrets vs. OIDC)

### 1.2 Varianta A: Service Principal + Secret

**Teorie:**
- Co je Service Principal
- App Registration vs. Service Principal
- Role-Based Access Control (RBAC)

**Praktická ukázka:**
1. Vytvoření App Registration v Azure AD
2. Vygenerování client secret
3. Přiřazení RBAC role (např. Contributor na RG)
4. Uložení credentials do GitHub Secrets:
   - `AZURE_CLIENT_ID`
   - `AZURE_CLIENT_SECRET`
   - `AZURE_TENANT_ID`
   - `AZURE_SUBSCRIPTION_ID`
5. Použití `azure/login@v2` action

**Nevýhody:**
- Secret má expiraci
- Secret je citlivý údaj

---

### 1.3 Varianta B: Service Principal + OIDC (Workload Identity Federation)

**Teorie:**
- Co je OIDC a proč je bezpečnější
- Federated credentials - jak fungují
- Žádné secrets v GitHubu

**Praktická ukázka:**
1. Vytvoření App Registration
2. Konfigurace Federated Credential:
   - Issuer: `https://token.actions.githubusercontent.com`
   - Subject: `repo:org/repo:ref:refs/heads/main`
3. Přiřazení RBAC role
4. GitHub workflow s `permissions: id-token: write`
5. Login bez secrets

---

### 1.4 Varianta C: User Assigned Managed Identity (UAMI)

**Teorie:**
- Co je Managed Identity
- System vs. User Assigned
- Kdy použít UAMI (self-hosted runners)

**Praktická ukázka:**
1. Vytvoření UAMI v Azure
2. Přiřazení RBAC role
3. Konfigurace Federated Credential na UAMI
4. Přiřazení UAMI k VM (self-hosted runner)
5. GitHub workflow bez explicitních credentials

**Výhody:**
- Žádné secrets
- Žádná expirace
- Centrální správa identity

---

### 1.5 Srovnání a best practices

| Aspekt | SP + Secret | SP + OIDC | UAMI |
|--------|-------------|-----------|------|
| Secrets v GH | Ano | Ne | Ne |
| Expirace | Ano | Ne | Ne |
| Self-hosted only | Ne | Ne | Ano |
| Složitost | Nízká | Střední | Střední |

**Doporučení:**
- GitHub-hosted runners → SP + OIDC
- Self-hosted runners → UAMI
- Legacy/rychlé testy → SP + Secret

---

## Demo Workflows

Toto repo obsahuje dva demo workflow soubory:

| Workflow | Soubor | Auth metoda |
|----------|--------|-------------|
| Azure Login (Secret) | `.github/workflows/azure-login-secret.yml` | Client ID + Secret |
| Azure Login (OIDC) | `.github/workflows/azure-login-oidc.yml` | Federated Credentials |

---

## Konfigurace

### Pro variantu A (Client Secret)

Přidej tyto secrets do GitHub repository:
- `AZURE_CLIENT_ID` - Application (client) ID
- `AZURE_CLIENT_SECRET` - Client secret value
- `AZURE_TENANT_ID` - Directory (tenant) ID
- `AZURE_SUBSCRIPTION_ID` - Subscription ID

### Pro variantu B (OIDC)

1. Přidej Federated Credential do App Registration:
   ```bash
   az ad app federated-credential create \
     --id <APPLICATION_ID> \
     --parameters '{
       "name": "github-main-branch",
       "issuer": "https://token.actions.githubusercontent.com",
       "subject": "repo:OWNER/REPO:ref:refs/heads/main",
       "audiences": ["api://AzureADTokenExchange"]
     }'
   ```

2. Přidej tyto secrets do GitHub repository:
   - `AZURE_CLIENT_ID` - Application (client) ID
   - `AZURE_TENANT_ID` - Directory (tenant) ID
   - `AZURE_SUBSCRIPTION_ID` - Subscription ID

**Poznámka:** Pro OIDC není potřeba client secret!

---

## Spuštění

1. Jdi do záložky **Actions**
2. Vyber workflow který chceš otestovat
3. Klikni na **Run workflow**
