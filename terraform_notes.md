# Terraform Learning Journey & Project Documentation

Welcome to the documentation of your Terraform project! This document outlines what we have built, the step-by-step refactoring journey we undertook, and a consolidated summary of the advanced concepts and questions you asked during this journey.

---

## 1. Project Overview: What We Built

We started with a monolithic Azure configuration to deploy a standard secure network and compute infrastructure:
* **Resource Group:** The logical container for all Azure resources.
* **Virtual Network (VNet) & Subnets:** A private network with `frontend-snet` and `backend-snet` subnets.
* **Security (NSG):** Network Security Groups protecting the frontend and backend with rules for HTTP, HTTPS, and SSH.
* **Compute Layer:** A Linux Virtual Machine, Network Interface (NIC), and Public IP.

---

## 2. Refactoring Journey: How We Done It

We refactored this codebase from a **monolithic** structure (everything in root `main.tf`) to a **modular** structure. Here is how we did it:

### Step 1: Modularizing the Resource Group
* **Action:** Created the `modules/resource-group/` directory.
* **Structure:** Separated the code into three files:
  - `main.tf`: Declares the resource group.
  - `variables.tf`: Defines inputs (`resource_group_name`, `location`).
  - `outputs.tf`: Exports the resource group `name` and `location`.
* **Wiring:** Replaced the direct resource block in the root `main.tf` with `module "resourcegroup"` and updated all downstream resources to point to `module.resourcegroup.name` and `module.resourcegroup.location`.

### Step 2: Modularizing the Network Layer
* **Action:** Created the `modules/network/` directory.
* **Structure:**
  - `main.tf`: Declares the VNet and the two subnets (`frontend` and `backend`).
  - `variables.tf`: Defines inputs for names, regions, and address space.
  - `outputs.tf`: Exports the VNet name, VNet ID, `frontend_subnet_id`, and `backend_subnet_id`.
* **Wiring:** Replaced the VNet and subnet resources in root `main.tf` with `module "network"`. All subnet associations and NIC configurations in root were updated to read `module.network.frontend_subnet_id` or `backend_subnet_id`.

### Step 3: State Migration using `moved` Blocks (Zero Downtime)
* **Problem:** Moving resources to modules changes their resource address (e.g. `azurerm_subnet.frontend` became `module.network.azurerm_subnet.frontend`). By default, Terraform treats this as a destruction of the old resource and creation of a new one, causing massive downtime.
* **Solution:** We added `moved` blocks to the root `main.tf` for VNet, frontend subnet, and backend subnet.
* **Result:** Running `terraform apply` completed with **0 resources added, 0 changed, 0 destroyed**. The state was migrated safely!

### Step 4: Modularizing the Security Layer
* **Action:** Created the `modules/security/` directory.
* **Structure:**
  - `main.tf`: Declares NSGs (frontend & backend), security rules, and subnet associations.
  - `variables.tf`: Defines inputs for region, resource group, and subnet IDs.
  - `outputs.tf`: Exports NSG IDs.
* **Wiring:** Replaced the NSG resources in root with `module "security"`. Added corresponding `moved` blocks in root `main.tf` to migrate the state of NSGs and rules with **0 destroyed**.

### Step 5: Modularizing the Compute Layer
* **Action:** Created the `modules/compute/` directory.
* **Structure:**
  - `main.tf`: Declares Public IP, NIC, and Linux VM.
  - `variables.tf`: Defines inputs for region, resource group, and subnet IDs.
  - `outputs.tf`: Exports the VM name and public IP.
* **Wiring:** Replaced VM resources in root with `module "compute"` and added corresponding outputs to the root `outputs.tf`. Updated name attributes to ensure DNS RFC 1123 compliance (no underscores in hostnames).

### Step 6: Implementing Remote State and Cloud State Locking
* **Action:** Created an Azure Storage Account (`aqibtfstate2000`) and a Blob Container (`tfstate`) manually via the Azure Portal (prerequisite baseline resources).
* **Wiring:** Configured the `backend "azurerm" { ... }` block inside `provider.tf`.
* **Migration:** Ran `terraform init` and answered `yes` to migrate the state file from the local MacBook disk to the Azure cloud container. State locking is now handled natively via Azure Blob Leasing.

### Step 7: CI/CD Pipeline Automation (Azure DevOps Pipelines)
* **Action:** Created a Service Connection (`azure-sp-connection`) in Azure DevOps using Service Principal credentials to authorize access to Azure.
* **Code:** Wrote `azure-pipelines.yml` at the root of the repository.
* **Execution:** Ran the pipeline in Azure DevOps. It installed Terraform, initialized, planned, and applied changes automatically with 100% success (all green!).

### Step 8: Dynamic Naming Convention using Terraform Locals (Unified Prefix)
* **Action:** Added a `locals` block in root `main.tf` defining `resource_prefix = "lab01-dev"`.
* **Flow:** Passed `naming_prefix = local.resource_prefix` into the Network, Security, and Compute child modules.
* **Result:** Dynamically prepended `${var.naming_prefix}-` to all VMs, subnets, NSGs, NICs, and PIPs across the entire project in a single centralized configuration change.

---

## 3. Conceptual Q&A Digest: Your Questions Explained

Here is a summary of the conceptual questions you asked, explained with real-world context:

### Q1: What is the modular approach in Terraform and why do we need it?
* **Concept:** Breaking down a large configuration into smaller, self-contained directories (child modules) that are called by a root module.
* **Why We Need It:**
  1. **Reusability (DRY):** Write code once and reuse it across multiple environments (Dev, Test, Prod).
  2. **Logical Isolation:** Keeps your codebase readable instead of having a single 1000-line `main.tf` file.
  3. **Encapsulation:** Hides internal complex code. The parent module only passes inputs and receives outputs.

### Q2: What is the difference between Tracked and Untracked files in Git?
We used a **Warehouse Analogy** to understand this:
* **Untracked (Unregistered Boxes):** Files in your project directory that Git is ignoring. Git does not track changes to them. If you delete them, Git cannot restore them. They appear under "Untracked files" in `git status`.
* **Tracked (Registered Boxes):** Files that have been added (`git add`) and committed (`git commit`). Git monitors these files 24/7. Any edits are flagged as "modified", and you can restore them to past versions if deleted.

### Q3: What is the role of `.tfvars` files (and why do we have dev, test, and prod)?
* **The Concept:** Think of `variables.tf` as a blank admission form (it defines *what* inputs exist). Think of `.tfvars` as the filled-out form (it contains the actual values, like `vnet_name = "vnet-dev"`).
* **The Role of dev/test/prod.tfvars:** These files act as **Configuration Profiles**. They allow you to deploy completely different environments using the exact same code by just changing the input file.

### Q4: Why are we only running "dev" right now? Why are test and prod not active?
* **The Problem:** If we run `terraform apply -var-file="test.tfvars"` directly using a single state file, Terraform will destroy your Dev environment resources and turn them into Test resources.
* **The Solution:** In the real world, we use **State Isolation** to run them concurrently, either using Terraform Workspaces or by using different folders/keys for each environment.

### Q5: What does `outputs.tf` actually do (The Restaurant Analogy)?
* **Concept:** It is the "return statement" of a module.
* **The Restaurant Analogy:**
  - **You (Root config):** Customer sitting at the table.
  - **Kitchen (Child Module):** Where the food is cooked. You can't see inside (encapsulation).
  - **Chef's Counter (outputs.tf):** Where the chef puts the ready dish so the waiter can serve it to you.
  Without `outputs.tf`, the cooked resources remain trapped inside the module, and other configurations cannot reference them.

### Q6: Why did we output the Subnet ID, but not the Subnet IP address prefix (e.g. 10.0.1.0/24)?
* **ID vs IP:** When Azure connects a VM or NSG to a subnet, its API requires the **Subnet Resource ID**, not its IP prefix. The ID uniquely identifies the resource in Azure.
* **Inputs vs Outputs:** The Subnet IP range is an Input (a decision we make). Outputs are values generated by Azure after creation (like IDs) that we cannot predict beforehand.

### Q7: Why did the VM hostname (computer name) throw an error with underscores (`_`)?
* **Concept:** Linux hostnames must comply with standard DNS naming rules (RFC 1123).
* **The Rule:** Hostnames can only contain alphanumeric characters and hyphens (`-`). They **cannot** contain underscores (`_`). When the VM resource name is defaulted as `"frontend_vm"`, it contains an underscore, which Azure API rejects. Changing the name attribute to `"frontend-vm"` resolved it.

### Q8: What happens internally during Git commands?
* **`git add .`:** Compresses file changes into **blobs** in `.git/objects` and updates the index file (Staging Area).
* **`git commit`:** Creates a **tree** object representing the folder structure and a **commit** object containing author details, message, and a pointer to the tree. Updates the branch ref pointer.
* **`git push`:** Compares commit history between local and remote, packages missing objects into a **packfile**, and uploads it to GitHub to sync branch pointers.

### Q9: What is State Locking and how does it work locally vs in the cloud?
* **Local State Locking:** Creates a temporary lock file locally. If another process runs, it reads the lock file and fails with `Error acquiring the state lock`.
* **Cloud State Locking (Azure Blob Lease):** Terraform requests a **Blob Lease** from Azure for the state file. Azure locks the blob exclusively for that write process. Any other process trying to write is rejected by Azure.

### Q10: Why did we use `key = "dev.terraform.tfstate"` in the backend config?
* **The Concept:** The `key` represents the file name of the state file inside the Blob container.
* **Isolation:** By using different keys for different environments (e.g. `dev.terraform.tfstate`, `test.terraform.tfstate`, `prod.terraform.tfstate`), we can store the states of multiple environments in the same container securely and independently.

### Q11: What is Azure DevOps and why do we need Service Connections & Extensions?
* **Azure DevOps:** A platform to automate workflows via CI/CD pipelines.
* **Service Connection:** A secure bridge that authorizes Azure DevOps to log into Azure and manage resources on your behalf using a Service Principal.
* **Extensions:** Azure DevOps is a general-purpose tool. To recognize and execute special YAML tasks like `TerraformTaskV4`, we must install the **Terraform Extension** from the Visual Studio Marketplace to add those capabilities.

### Q12: Is the CI/CD pipeline mandatory to apply locals/HCL changes?
* **Technically No:** You can execute `terraform apply` locally from your personal computer's terminal if you have authenticated via Azure CLI (`az login`) or environment variables.
* **Professionally Yes (Enterprise Standard):** In actual companies, direct laptop deployments are blocked for security, audit, tracking, and compliance. All changes must go through a Git repository pull request and be deployed exclusively via automated pipelines.

### Q13: Why does changing name attributes trigger resource replacement (Plan: 14 to destroy)?
* **Destructive vs Non-destructive Updates:** In Azure, resources like Virtual Machines, Subnets, and Network Security Groups cannot be renamed while running. Changing their `name` attribute in HCL tells Terraform to delete (destroy) the old resource and provision a new one from scratch. Modifying tags, however, is supported in-place (non-destructive) by Azure APIs.

---
