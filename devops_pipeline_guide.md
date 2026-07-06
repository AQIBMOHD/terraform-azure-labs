# Azure DevOps to Azure Integration & Pipeline Configuration Guide

This guide provides a comprehensive breakdown of how to connect the Azure Portal with Azure DevOps, configure automated pipelines, and manage advanced Infrastructure-as-Code (IaC) architectures using Terraform.

---

## 1. Connecting Azure Portal to Azure DevOps (The Service Connection)

### What is a Service Connection?
A **Service Connection** is a secure authentication bridge that allows Azure DevOps to communicate with your Azure Cloud subscription. 
Instead of logging in with a human username and password, Azure DevOps uses a **Service Principal** (an automated identity in Microsoft Entra ID) to authenticate.

### Setup Flow: Workload Identity Federation (Automatic)
The modern industry standard for this bridge is **Workload Identity Federation**. It provides password-less, secure access without needing to manage or rotate secret keys.

1. **Navigate to Settings:** Open your Azure DevOps project and click **Project settings** (gear icon ⚙️) in the bottom-left corner.
2. **Open Service Connections:** Click **Service connections** under the *Pipelines* menu section.
3. **New Connection:** Click **Create service connection** and select **Azure Resource Manager**.
4. **Choose Authentication Method:** Select **Workload identity federation (automatic)**.
5. **Set Scope:** Select **Subscription** and choose your active subscription from the dropdown. Keep the *Resource Group* field set to **All resource groups** so the pipeline can manage resources across the entire subscription.
6. **Name the Bridge:** Give it a name (e.g., `azure-sp-connection`). This exact name will be used in your pipeline YAML file.
7. **Grant Access:** Check the box **Grant access permission to all pipelines** to prevent permission errors.
8. **Save:** Click **Save**. Azure DevOps will automatically log into your subscription, create the Service Principal, and configure the federation.

---

## 2. Configuring the Pipeline inside Azure DevOps

Once the bridge is active, you must configure Azure DevOps to read your code from GitHub and run the pipeline.

### Step 1: Connect your Git Repository
1. Go to the left menu and click **Pipelines** (rocket ship icon 🚀).
2. Click **Create Pipeline** (or *New Pipeline*).
3. **Where is your code?** Select **GitHub**.
4. **Authorization:** Authenticate your GitHub account. Select your repository (e.g., `AQIBMOHD/terraform-azure-labs`).
5. **App Installation:** GitHub will ask you to install the *Azure Pipelines* app. Select **Only select repositories**, choose your repo, and click **Approve & Install**.

### Step 2: Set the YAML Configuration
1. **Configure your pipeline:** Select **Existing Azure Pipelines YAML file**.
2. **Select Path:** Choose the branch (`main`) and the path to your pipeline file (`/azure-pipelines.yml`).
3. Click **Continue** and then **Run**.

### Step 3: Crucial Pre-requisite (Marketplace Extension)
If you run the pipeline for the first time in a new organization, it will fail with: `A task is missing: TerraformTaskV4`.
* **The Fix:** Go to the [Visual Studio Marketplace](https://marketplace.visualstudio.com/items?itemName=ms-devlabs.custom-terraform-tasks) and install the **Terraform Extension by Microsoft DevLabs** to your organization (e.g., `abismohammad313`). This teaches Azure DevOps how to interpret Terraform tasks.

---

## 3. Pipeline Configuration File (`azure-pipelines.yml`) Breakdown

Here is what each section of your pipeline code does:

```yaml
trigger:
- main # 1. TRIGGER: Runs the pipeline automatically on every 'git push' to the main branch.

pool:
  vmImage: 'ubuntu-latest' # 2. AGENT: Runs the steps on a temporary Linux VM hosted in the cloud.

variables:
  azureServiceConnection: 'azure-sp-connection' # Matches your Service Connection name
  resourceGroup: 'rg-terraform-state'
  storageAccount: 'aqibtfstate2000'
  container: 'tfstate'
  tfstateKey: 'dev.terraform.tfstate'

steps:
# 3. INSTALLER: Downloads and installs the Terraform CLI on the Ubuntu agent.
- task: TerraformInstaller@1
  displayName: 'Install Terraform'
  inputs:
    terraformVersion: 'latest'

# 4. INIT: Connects to Azure using the Service Connection and initializes the remote state backend.
- task: TerraformTaskV4@4
  displayName: 'Terraform Init'
  inputs:
    provider: 'azurerm'
    command: 'init'
    backendServiceArm: '$(azureServiceConnection)'
    backendAzureRmResourceGroupName: '$(resourceGroup)'
    backendAzureRmStorageAccountName: '$(storageAccount)'
    backendAzureRmContainerName: '$(container)'
    backendAzureRmKey: '$(tfstateKey)'

# 5. PLAN: Computes the changes required to sync Azure with your HCL code.
- task: TerraformTaskV4@4
  displayName: 'Terraform Plan'
  inputs:
    provider: 'azurerm'
    command: 'plan'
    environmentServiceNameAzureRM: '$(azureServiceConnection)'
    commandOptions: '-var-file="dev.tfvars"'

# 6. APPLY: Automatically executes the plan on Azure. Uses -auto-approve because it runs non-interactively.
- task: TerraformTaskV4@4
  displayName: 'Terraform Apply'
  inputs:
    provider: 'azurerm'
    command: 'apply'
    environmentServiceNameAzureRM: '$(azureServiceConnection)'
    commandOptions: '-var-file="dev.tfvars" -auto-approve'
```

---

## 4. Advanced Concepts Built on Top of the Pipeline

After setting up the basic pipeline, we implemented two advanced production-grade patterns:

### A. Dynamic Naming Conventions (Terraform Locals)
Instead of hardcoding names (like `"frontend-vm"`) inside child modules, we created a single `locals` block at the root level:
```hcl
locals {
  resource_prefix = "lab01-dev"
}
```
* **The Flow:** We passed `local.resource_prefix` into the child modules as a variable (`naming_prefix`) and used string interpolation to name the resources: `name = "${var.naming_prefix}-frontend-vm"`.
* **Use Case:** Changing the prefix in one place (`locals`) updates the names of all resources (VMs, NSGs, Subnets, NICs) dynamically.

### B. Secure SSH Access (HTTP Data Source)
To avoid opening port 22 (SSH) to the entire internet (`"*"`), we used a `data` block to fetch the public IP of your MacBook dynamically during execution:
```hcl
data "http" "my_public_ip" {
  url = "https://api.ipify.org"
}
```
* **The Flow:** We mapped the fetched body response to the security rules: `source_address_prefix = "${data.http.my_public_ip.response_body}/32"`.
* **Use Case:** It automatically updates the firewall rules to allow ONLY your current public IP address to access the VM, resolving dynamic IP lease issues.

---

## 5. Critical State Operations & Validation Rules

### State Untracking (`terraform state rm`)
If a resource (like a VNet) is already deployed, and you want to stop managing it via resource code (for example, converting it to a shared `data` source), you **cannot** just delete it from the code. If you do, Terraform will try to delete it from Azure.
* **The Solution:** Run `terraform state rm <resource_address>`. This tells Terraform to delete the resource from its memory diary (state file) but leave it untouched on Azure. Afterward, you can safely write a `data` block to reference it as an existing resource.

### Destructive vs. Non-Destructive Changes
* **Non-Destructive (In-Place Update):** Modifying tags or firewall security rules can be applied to existing running resources without recreation.
* **Destructive (Replacement):** Modifying the `name` attribute of virtual machines, subnets, or security groups cannot be done in-place on Azure. Terraform will output **`destroy and then create replacement`** (recreation plan) because Azure APIs require recreating the physical resource to apply the name change.

---
