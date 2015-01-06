# groowin-test-box

Packer configuration for creating base box for integration tests of **Groowin** - a Groovy-based DSL for working with remote WinRM servers.

## Overview

The main goal of the packer configuration is to provide depending [groowin](https://github.com/aestasit/groowin) and [groovy-winrm-client](https://github.com/aestasit/groovy-winrm-client) projects with test environment for integration tests and more precisely test WinRM via HTTPS.
The main requirement set to the packer box implementation is to make the installation of the system as simple as possible with as little additional steps as possible.

Final configuration allows to create VirtualBox base box with the completely configured working WinRM via HTTP and HTTPS.
All integration tests written for the **groowin** and **groovy-winrm-client** refers to the same test server IP 192.168.25.25.
The system expanded by **Vagrantfile** has the same IP address.


## Usage groowin-test-box

As it is mentioned before the configuration if for providing test environment for **groowin** and **groovy-winrm-client** projects.
The configuration allows to prepare and expand the virtual machine by the only on IP address 192.168.25.25.
For more information how to configure the system by another IP address please refer to the [Implementation details]() chapter.

To expand and to use the virutal machine it is necessary to make the following steps:

1. execute the command `packer build windows_2008_r2_puppet.json`
2. when execution of the previous step is finished and a base box is created, add the box to Vagrant executing the command like `vagrant box add --name aestasit/2008r2 windows_2008_r2_virtualbox.box`
3. start virtual machine by Vagranfile stored together with the configuration files by executing `vagrant up`
4. add self-signed certificate on the local machine(`./scripts/vagrant-2008R2.pfx`) with the password Vagrant-2008r2. Copy the `vagrant-2008R2.pfx` file to host system and double click on it. Enter password and select 'Trusted Root Certification Authorities' as certificate storage.
5. test WinRM via HTTPS executing the command `winrs -r:https://192.168.25.25:5986 -u:vagrant -p:vagrant hostname` The response has to be Vagrant-2008r2

## Implementation details

The current packer configuration is based on the [joefitzgerald/packer-windows](https://github.com/joefitzgerald/packer-windows) project.
The configuration creates a base Windows Server 2008 R2 box.

To make the process of the box creation simple all changes were put to `./answer_files/2008_r2/Autounattend.xml` file.

The following changes were applied to the configuration:

- Port 5986 is open. Line [181-186] of `./answer_files/2008_r2/Autounattend.xml`
- Preliminarily created self-signed certificate `./scripts/vagrant-2008R2.pfx` is added to the configured system. Line [240-244] of `./answer_files/2008_r2/Autounattend.xml`. The password for the certificate is `Vagrant-2008r2`
- WinRM configured to listen by HTTPS. Line [245-249] of `./answer_files/2008_r2/Autounattend.xml`


### Changing IP address of a virtual machine

To change the IP of the virtual machine to another one and have WinRM working by HTTPS the first step has to remain and the last two steps has to be omitted in `./answer_files/2008_r2/Autounattend.xml` and done manually.
We need to recreate a base box (in comparison with the default configuration).

Assume that box is created and virtual machine started. Assume that you logged in to the guest system as administrator or you can run applications with the rights of Administrator.

We need to complete the following steps:

* To create the self-signed certificate use the following command:

        makecert -r -pe -n "CN=192.168.10.128" -b 01/01/2015 -e 01/01/2022 -eku 1.3.6.1.5.5.7.3.1 -sky exchange vagrant-2008R2.cer -sv vagrant-2008R2.pvk

    During the execution you will be asked to define password for the private key.

* After certificate together with private key are created we need to create certificate containing private key:

        pvk2pfx -pvk vagrant-2008R2.pvk -spc vagrant-2008R2.cer -pfx vagrant-2008R2.pfx -pi __YOUR_PASSWORD_HERE__`

    vagrant-2008R2.pfx file will be created as a result of the command execution. pvk2pfx.exe is a part of WindowsSDK so you may need to install it additionally.

* Execute the following command to install the certificate to Trusted Root Certification Authorities and Personal folder.

        certutil -f -p __YOUR_PASSWORD_HERE__ -importpfx __path__to__vagrant-2008r2.pfx

* To create an HTTPS listener save the following code to addHttpsListener.ps1 file and execute the command `powershell -File addHttpsListener.ps1`

        $Thumbprint = (Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object {$_.Subject -match "192.168.10.128"}).Thumbprint;
        winrm create winrm/config/Listener?Address=*+Transport=HTTPS '@{Hostname="192.168.10.128";CertificateThumbprint="'$Thumbprint'"}'



## Links

1. [Configure WinRM to Use HTTPS](http://pubs.vmware.com/orchestrator-plugins/index.jsp?topic=%2Fcom.vmware.using.powershell.plugin.doc_10%2FGUID-2F7DA33F-E427-4B22-8946-03793C05A097.html)