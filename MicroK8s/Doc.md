# MicroK8s Documentation

## Introduction to MicroK8s

MicroK8s is a lightweight, single-package Kubernetes distribution developed by Canonical, designed for developers and small-scale production environments. It provides a simple, fast, and secure way to run Kubernetes clusters locally or on edge devices. MicroK8s is ideal for:

- **Developers** working on Kubernetes-based applications.
- **DevOps teams** testing CI/CD pipelines.
- **Learning Kubernetes** in a low-resource environment.

Key features include:
- **Zero-ops**: Installs with a single command.
- **Minimal footprint**: Runs on low-resource systems.
- **Add-ons**: Includes DNS, dashboard, storage, and more.
- **Cross-platform**: Supports Linux, Windows, and macOS.

This guide provides clear, step-by-step instructions to install MicroK8s on Linux, Windows, and macOS, with updated macOS instructions based on the official documentation.

---

## Installation Instructions

Below are the installation steps for each supported operating system. Follow the instructions specific to your OS.

### Prerequisites (All Operating Systems)
- At least 4GB of RAM and 20GB of free disk space.
- Administrative or superuser privileges.
- Internet connection for downloading packages.
- A terminal or command-line interface.

---

### 1. Installing MicroK8s on Linux

MicroK8s is natively supported on Linux via Snap, a universal package manager.

#### Supported Distributions
- Ubuntu, Debian, Fedora, CentOS, or any Linux distribution with Snap support.

#### Steps
1. **Install Snap (if not already installed)**:
   - On Ubuntu, Snap is pre-installed.
   - For other distributions, install Snap:
     ```bash
     sudo dnf install snapd  # Fedora
     sudo yum install snapd  # CentOS
     sudo apt update && sudo apt install snapd  # Debian
     ```
   - Enable Snap and create a symbolic link:
     ```bash
     sudo ln -s /var/lib/snapd/snap /snap
     sudo systemctl enable --now snapd.socket
     ```

2. **Install MicroK8s**:
   - Run the following command to install the latest stable version:
     ```bash
     sudo snap install microk8s --classic
     ```

3. **Verify Installation**:
   - Check the MicroK8s status:
     ```bash
     microk8s status --wait-ready
     ```
   - If MicroK8s is running, you’ll see a status message indicating it’s active.

4. **Add User to MicroK8s Group** (optional, for non-root access):
   - To run MicroK8s commands without `sudo`:
     ```bash
     sudo usermod -a -G microk8s $USER
     sudo chown -f -R $USER ~/.kube
     newgrp microk8s
     ```

5. **Test MicroK8s**:
   - Enable the Kubernetes dashboard:
     ```bash
     microk8s enable dashboard
     ```
   - Access the dashboard:
     ```bash
     microk8s dashboard-proxy
     ```
   - Open the provided URL in a browser to view the Kubernetes dashboard.

#### Troubleshooting
- If Snap fails, ensure `snapd` is running: `sudo systemctl start snapd`.
- Check Snap channels for updates: `sudo snap refresh`.

---

### 2. Installing MicroK8s on Windows

MicroK8s on Windows is installed using a dedicated Windows installer, as outlined in the official documentation.

#### Prerequisites
- Windows 10 or 11 (Pro, Enterprise, or Education editions).
- Virtualization enabled in BIOS/UEFI (e.g., Intel VT-x or AMD-V).
- At least 8GB RAM recommended.

#### Steps
1. **Download the Installer for Windows**:
   - Visit the official MicroK8s website: [microk8s.io](https://microk8s.io).
   - Download the MicroK8s for Windows installer from the provided link. [microk8s-installer](https://microk8s.io/microk8s-installer.exe)

2. **Run the Installer**:
   - Locate the downloaded installer (e.g., `microk8s-installer.exe`).
   - Double-click to run the installer and follow the on-screen instructions.
   - Ensure you have administrative privileges to complete the installation.

3. **Open a Command Line**:
   - Open a Windows Command Prompt or PowerShell as Administrator:
     - Press `Win + S`, type `cmd` or `powershell`, right-click, and select "Run as Administrator".

4. **Check the Status While Kubernetes Starts**:
   - Verify that MicroK8s is running:
     ```cmd
     microk8s status --wait-ready
     ```
   - This command waits until all Kubernetes services are active.

5. **Turn On the Services You Want**:
   - Enable essential add-ons for your cluster:
     ```cmd
     microk8s enable dashboard
     microk8s enable dns
     microk8s enable registry
     microk8s enable istio
     ```
   - To see a list of available services:
     ```cmd
     microk8s enable --help
     ```
   - To disable a service:
     ```cmd
     microk8s disable <service-name>
     ```

6. **Start Using Kubernetes**:
   - Check the cluster status:
     ```cmd
     microk8s kubectl get all --all-namespaces
     ```
   - For frequent use, consider installing the native Windows version of `kubectl`:
     - Download `kubectl` from [kubernetes.io](https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/).
     - Add it to your system PATH for easy access.

7. **Access the Kubernetes Dashboard**:
   - Start the dashboard proxy:
     ```cmd
     microk8s dashboard-proxy
     ```
   - Open the provided URL in a browser to access the Kubernetes dashboard.

8. **Start and Stop Kubernetes to Save Battery**:
   - Kubernetes services run continuously, consuming resources. To save battery:
     - Stop MicroK8s:
       ```cmd
       microk8s stop
       ```
     - Start MicroK8s:
       ```cmd
       microk8s start
       ```

#### Troubleshooting
- If the installer fails, ensure Hyper-V is enabled: `Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All`.
- Check for updates to the installer on [microk8s.io](https://microk8s.io).
- If `kubectl` commands fail, verify the kubeconfig file is correctly set up in `%USERPROFILE%\.kube\config`.

---

### 3. Installing MicroK8s on macOS

MicroK8s on macOS can be installed directly using Homebrew, as per the official documentation, providing a simpler alternative to the Multipass-based approach.

#### Prerequisites
- macOS 10.14 (Mojave) or later.
- At least 8GB RAM recommended.
- Homebrew installed (if not, install from [brew.sh](https://brew.sh)).

#### Steps
1. **Install MicroK8s on macOS**:
   - Open a Terminal.
   - Install MicroK8s using Homebrew:
     ```bash
     brew install ubuntu/microk8s/microk8s
     ```
   - If you don’t have Homebrew, visit [brew.sh](https://brew.sh) and follow the installation instructions.

2. **Run the MicroK8s Installer**:
   - Start the MicroK8s installation:
     ```bash
     microk8s install
     ```

3. **Check the Status While Kubernetes Starts**:
   - Verify that MicroK8s is running:
     ```bash
     microk8s status --wait-ready
     ```
   - This command waits until all Kubernetes services are active.

4. **Turn On the Services You Want**:
   - Enable essential add-ons for your cluster:
     ```bash
     microk8s enable dashboard
     microk8s enable dns
     microk8s enable registry
     microk8s enable istio
     ```
   - To see a list of available services:
     ```bash
     microk8s enable --help
     ```
   - To disable a service:
     ```bash
     microk8s disable <service-name>
     ```

5. **Start Using Kubernetes**:
   - Check the cluster status:
     ```bash
     microk8s kubectl get all --all-namespaces
     ```
   - For frequent use, consider installing the native macOS version of `kubectl`:
     - Install via Homebrew:
       ```bash
       brew install kubectl
       ```
     - Learn more at [kubernetes.io](https://kubernetes.io/docs/tasks/tools/install-kubectl-macos/).

6. **Access the Kubernetes Dashboard**:
   - Start the dashboard proxy:
     ```bash
     microk8s dashboard-proxy
     ```
   - Open the provided URL in a browser to access the Kubernetes dashboard.

7. **Start and Stop Kubernetes to Save Battery**:
   - Kubernetes services run continuously, consuming resources. To save battery:
     - Stop MicroK8s:
       ```bash
       microk8s stop
       ```
     - Start MicroK8s:
       ```bash
       microk8s start
       ```

#### Alternative Installation (Using Multipass)
If the Homebrew method is not suitable, you can use Multipass to run MicroK8s in a Linux VM.

1. **Install Multipass**:
   - Install via Homebrew:
     ```bash
     brew install --cask multipass
     ```
   - Alternatively, download from [multipass.run](https://multipass.run).

2. **Launch a MicroK8s VM**:
   - Create a VM with MicroK8s:
     ```bash
     multipass launch microk8s --name microk8s-vm
     ```

3. **Access the MicroK8s VM**:
   - Connect to the VM:
     ```bash
     multipass shell microk8s-vm
     ```
   - Verify MicroK8s:
     ```bash
     microk8s status --wait-ready
     ```

4. **Set Up kubectl on macOS**:
   - Install `kubectl`:
     ```bash
     brew install kubectl
     ```
   - Copy the kubeconfig file:
     ```bash
     multipass exec microk8s-vm -- /snap/bin/microk8s config > ~/.kube/config
     ```

5. **Test MicroK8s**:
   - Run:
     ```bash
     kubectl get nodes
     ```
   - Enable and access the dashboard:
     ```bash
     multipass exec microk8s-vm -- /snap/bin/microk8s enable dashboard
     multipass exec microk8s-vm -- /snap/bin/microk8s dashboard-proxy
     ```

#### Troubleshooting
- If Homebrew installation fails, ensure Homebrew is up-to-date: `brew update`.
- If MicroK8s fails to start, check for sufficient disk space and RAM.
- For Multipass issues, restart the VM: `multipass stop microk8s-vm && multipass start microk8s-vm`.

---

## Getting Started with MicroK8s

Once installed, you can explore MicroK8s features:

- **Enable Add-ons**:
  ```bash
  microk8s enable dns storage ingress
  ```
- **Deploy a Sample Application**:
  ```bash
  kubectl create deployment nginx --image=nginx
  kubectl expose deployment nginx --port=80 --type=NodePort
  ```
- **Check Cluster Status**:
  ```bash
  kubectl get all
  ```

## Additional Resources
- [Official MicroK8s Documentation](https://microk8s.io/docs)
- [Kubernetes Tutorials](https://kubernetes.io/docs/tutorials/)
- [Homebrew Website](https://brew.sh)
- [Multipass Documentation](https://multipass.run/docs)