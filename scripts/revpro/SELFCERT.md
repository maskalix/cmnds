# Self-Signed Certificate Generation and Deployment Guide

This guide explains how to create self-signed certificates for your HTTPS sites on your domain (e.g., `domain.tld` and `*.domain.tld`) and how to deploy these certificates across your network so that they are trusted by all computers.

## Prerequisites

- Access to a Linux server with OpenSSL installed.
- Root or sudo access to create directories and write files to `/etc/letsencrypt/live/`.
- Basic knowledge of command-line usage.

## Using the Self-Cert Script

### Step 1: Download the Script

1. **Clone the Repository or Download the Script**:

   Ensure you have the `selfcert.sh` script on your server. You can download it from your GitHub repository or copy the script content from an appropriate source.

### Step 2: Make the Script Executable

Run the following command to make the script executable:

```bash
chmod +x selfcert.sh
```
Step 3: Generate Certificates
A. Generating a CA Certificate
To generate a self-signed CA certificate, use the command:

```bash
./selfcert.sh -d domain.tld -d *.domain.tld --CA --years 10
-d: Specifies the domain names for which the certificate is valid. You can add multiple -d flags for additional domains or subdomains.
--CA: Indicates that you want to create a Certificate Authority (CA) certificate.
--years: Specifies the validity period for the certificate in years.
```
B. Generating Server Certificates
To generate a server certificate, run the following command:

```bash
./selfcert.sh -d domain.tld -d *.domain.tld --years 3
--years: Defines the validity period for the server certificate in years.
```
Step 4: Verify Certificate Generation
After running the script, check the /etc/letsencrypt/live/domain.tld/ directory for the generated files:

privkey.pem: The private key.
fullchain.pem: The self-signed certificate (or CA certificate).
Trusting the Certificate Across Your Network
Step 1: Copy the CA Certificate to All Machines
Locate the CA Certificate:

If you generated a CA certificate, it will be located in /etc/letsencrypt/live/domain.tld/fullchain.pem.

Copy the Certificate to Each Client Machine:

You can use scp, rsync, or a USB drive to copy the fullchain.pem file to each machine in your network. For example, using scp:

```bash
scp /etc/letsencrypt/live/domain.tld/fullchain.pem USER@CLIENT_IP:/path/to/destination
```
Replace USER with the actual username and CLIENT_IP with the IP address of the client machine.

Step 2: Install the CA Certificate on Client Machines
1. For Windows:
    - Open the Run dialog (Win + R) and type mmc to open the Microsoft Management Console.
    - Click on File > Add/Remove Snap-in.
    - Choose Certificates and click Add.
    - Select My user account or Computer account (depending on how you want to trust the certificate).
    - Navigate to Certificates (Local Computer) > Trusted Root Certification Authorities > Certificates.
    - Right-click on Certificates, select All Tasks > Import.
    - Follow the wizard to import the fullchain.pem file.
2. For macOS:
    - Open Keychain Access (search in Spotlight).
    - Drag and drop the fullchain.pem file into the System keychain or use File > Import Items.
    - Find the certificate in the keychain, right-click, and select Get Info.
    - Expand the Trust section and set When using this certificate to Always Trust.
3. For Linux:
    - Copy the fullchain.pem to /usr/local/share/ca-certificates/:

    ```bash
    sudo cp fullchain.pem /usr/local/share/ca-certificates/domain.tld.crt
    ```
    - Update the CA certificates:

    ```bash
    sudo update-ca-certificates
    ```
Step 3: Test Your Configuration
- Open a Web Browser on a client machine and navigate to https://domain.tld.
- Ensure that the site loads without certificate warnings.


## Conclusion
You have successfully created self-signed certificates and configured them to be trusted across your network. Follow the steps above to generate and deploy certificates for your specific domains, ensuring secure communication.

For more information, refer to the script documentation at GitHub Repository.
