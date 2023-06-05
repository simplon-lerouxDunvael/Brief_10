<div style='text-align: justify;'>

<div id='top'/>

# Integrating DevSecOps testing tools to Azure DevOps Pipeline

## Summary

###### [00 - Daily Scrum](#Scrum)

###### [01 -  Doc reading](#Doc)

###### [02 - Creation of a resource group and deployment of Voting-App](#RG)

###### [03 - Creating the pipeline](#Pipeline)

###### [04 - Choosing the security tests checking tools](#Choice)

###### [05 - Installation of Trivy](#Trivy)

###### [06 - Installation of OWASP Zap](#Owasp)

###### [07 - Using Trivy and OWASP Zap with Azure DevOps Pipelines](#T&OwtADP)

###### [08 - Prompting administrator to continue or not the pipeline after a failure status from tests](#Admin)

###### [09 - Definition of the different tools](#Definition)

&nbsp;&nbsp;&nbsp;[a) SonarQube](#Sonar)  
&nbsp;&nbsp;&nbsp;[b) OWASP Dependency-Check](#OWASP1)  
&nbsp;&nbsp;&nbsp;[c) Clair](#Clair)  
&nbsp;&nbsp;&nbsp;[d) Trivy](#Trivy)  
&nbsp;&nbsp;&nbsp;[e) Grype](#Grype)  
&nbsp;&nbsp;&nbsp;[f) OWASP Zap](#OWASP2)  

###### [10 - Installation of Prometheus and Grafana](#PromGraf)

###### [11 - ](#)

###### [12 - ](#)

###### [13 - ](#)

###### [ - Usefull Commands](#UsefullCommands)

<div id='Scrum'/>  

### **Scrum quotidien**

Scrum Master = Me, myself and I
Daily personnal reactions with reports and designations of first tasks for the day.

Frequent meeting with other coworkers to study solutions to encountered problems together.

[scrums](https://github.com/simplon-lerouxDunvael/Brief_7/blob/main/Plans_et_demarches/Scrum.md)

[&#8679;](#top)

<div id='Docs'/>  

#### **doc reading**

Researches and reading of documentations to determine the needed prerequisites, functionnalities and softwares to complete the different tasks of Brief 10.

[&#8679;](#top)  

<div id='RG'/>  

### **Creation of a resource group and deployment of Voting-App**

I created a resource group and deployed the Voting App via the file script .sh (created beforehand).

Nginx was properly installed on both namespaces. I updated the DNS records IP addresses with the ones displaying thanks to my script.

Then i downloaded the kubeconfig file to update it in my GitHub repository.

```Bash
download kubeconfig.yaml
```

The TLS was properly installed and functional and I could connect in https to the azure voting app (QUA and PROD).

My infrastructure is now deployed and functional. Therefore I can now start to install Prometheus and Grafana.

*I am keeping the pipelines parts and security checking tools as well as it could be usefull in he future.*

[&#8679;](#top)

<div id='Pipeline'/>  

### **Creating the pipeline**

First I went to Azure DevOps, created a [project](https://dev.azure.com/dlerouxext/b10duna) and on Pipelines.

Then, I had to configure my organization and project's [visibility](https://learn.microsoft.com/en-us/azure/devops/organizations/projects/make-project-public?view=azure-devops). I went to the settings and turned on the visibility to private.

*Since the last update of Kubernetes, the connection to Azure can't be made with the service connections.  
Therefore, I used the kubeconfig file created from my script to recover the connections informations I need.*

```Bash
az aks get-credentials --resource-group $rgname --name $aksname -f kubeconfig.yaml
```

Then I downloaded it and placed it directly in my Git repository (downloading it from azure terminal does not push it into Git) :

```Bash
download kubeconfig.yaml
```

Once downloaded, I just had to put the code into the Kubernetes service connection (choosing autoConfig params) to be able to use my pipeline and Kubernetes services. I also added a Docker connection so my pipeline could access my Docker registry and Voting app image.

Then I created a new GitHub repository and copy/pasteed all the files from the previous repository from brief 9 : azVotingApp_b9duna and named it azVotingApp_b10duna.

Finally i used the pipeline that was created during brief 9.

The pipeline is constructed in a specific order :

* First I declared the variables that would be used several times
* Then I created a job to Build and Push the Docker Image into my Docker repository previously created
* Once the docker image was created, I deployed it (in a canary way) to the qua namespace and checked that the voting app responded well with a curl (deployment.yaml)
* Then as it worked, I deployed it (also in a canary way) to the prod namespace and checked that the voting app responded well with a curl too (deployment-canary.yaml)
* Then I used a bash script to check the replicas created (2 for prod, 1 for qua). This way, I knew that in the namespace prod, there were one voting app with the old version and one with the new version. The cluster IP would manage the users between the pods.
* Then I promoted the new version to all the pods in the prod namespace (deployment.yaml)
* As the checks were successful, I deleted the canary deployment from the prod namespace (deployment-canary.yaml)

[&#8679;](#top)

<div id='Choice'/>  

### **Choosing the security tests checking tools**

Based on the tools and environment, I decided to integrate Trivy for container image security scanning and OWASP ZAP for dynamic application security testing.

* Trivy is a lightweight and easy-to-use tool for scanning container images for vulnerabilities. It can be easily integrated into a Docker-based CI/CD pipeline, especially on Azure DevOps as it's available on the Marketplace for free as a container for the VM that will scan the image directly. Additionally, Trivy is compatible with various container image registries and can detect vulnerabilities in both the OS packages and application dependencies.

* OWASP ZAP is a comprehensive tool for testing web applications for security vulnerabilities, and it can be integrated into most CI/CD pipelines. It offers a flexible and customizable testing framework and can detect a wide range of security vulnerabilities, including injection flaws, cross-site scripting, and broken authentication.

By integrating Trivy and OWASP ZAP into my CI/CD pipeline, I can ensure that my container images and web applications are secure and protected against common security threats.

[&#8679;](#top)

<div id='Trivy'/>  

### **Installation of Trivy**

First, I went to [Trivy Github](https://github.com/aquasecurity/trivy-azure-pipelines-task) and downloaded Trivy on the [Azure DevOps Market](https://marketplace.visualstudio.com/items?itemName=AquaSecurityOfficial.trivy-official) (by clicking on *Get it for Free*) to link it to my Azure DevOps account. Once it was installed I could use Trivy tasks on my pipeline.

![trivy_download](https://user-images.githubusercontent.com/108001918/234309975-4560cc33-49a0-432d-aa18-49e16d0198c1.png)

[&#8679;](#top)

<div id='Owasp'/>  

### **Installation of OWASP Zap**

First, I downloaded OWASP Zap on the [Azure DevOps Market](https://marketplace.visualstudio.com/items?itemName=CSE-DevOps.zap-scanner) (by clicking on *Get it for Free*) to link it to my Azure DevOps account. Once it was installed I could use OWASP Zap tasks on my pipeline.

![owaspzap_download](https://user-images.githubusercontent.com/108001918/234544420-87d0869f-1168-45f2-8f72-d974195dc9ff.png)

[&#8679;](#top)

<div id='T&OwtADP'/>  

### **Using Trivy and OWASP Zap with Azure DevOps Pipelines**

**Trivy :**

In order to ask Trivy to scan my Docker image, I created a trivy task and completed the configuration needed.
Then in order to extract the output and gets the metrics, I created a repository at the root of my GitHub repo to store the reports and then extract the temporary output of Trivy before it is destroyed. As a professionnal Aqua account is needed to get the output for Trivy, extracting the temporary output before it is send to Aqua is the only way to get the metrics.

After creating the repository Reports, I created a README.md file so that the output would be directed and pushed into the directory (without any file in it not push is made).

For the needs of the demonstration, and because Trivy detects about 80+K lines of issues with a severity "high" or higher, and because the docker image used for the webapp cannot be changed, the information will be acknowledged but ignored.

**OWASP Zap :**

In order to ask OWASP Zap to test my Azure Voting App, I created a owaspzap task and completed the configuration needed.

I run the OWASP Zap scanner against the app (after it has been deployed to qua) and publish the OWASP Zap report as a build artifact.

OWASP ZAP Scan supposedly has an option to define the output but all of them failed. It appears that it is a common issue according to the reviews of OWASP ZAP Scan, it is a current bug that may or may not be fixed in the future.

![owasp_nofile](https://user-images.githubusercontent.com/108001918/234587089-15960667-c46c-4ba4-a9ad-b2ce30793780.png)

For the needs of the demonstration, and because OWASP ZAP Scan still detects vulnerabilities, and because the docker image used for the webapp cannot be changed, the information will be acknowledged but ignored.

![owasp_nofile2](https://user-images.githubusercontent.com/108001918/234592211-e6c28936-da10-425a-9224-8a0da0501831.png)

Here is the link to the reviews of OWASP Zap and the comments about the bug : <https://marketplace.visualstudio.com/items?itemName=CSE-DevOps.zap-scanner&ssr=false#review-details>.

[&#8679;](#top)

<div id='Admin'/>  

### **Prompting administrator to continue or not the pipeline after a failure status from tests**

In order to prompt administrator to continue or not the pipeline after a failure status from tests it is necessary to use a manual validation task. All the information on how to configure and implement it in Azure DevOps Pipelines come from :

* <https://learn.microsoft.com/en-us/azure/devops/pipelines/tasks/reference/manual-validation-v0?view=azure-pipelines>

* <https://stackoverflow.com/questions/56176773/how-to-add-a-manual-intervention-step-in-azure-pipelines-yaml>

Once implemented, the administrator can click on `Review` during the pipeline process and choose wheither to continue or stop the pipeline.

![admin1](https://user-images.githubusercontent.com/108001918/234603075-df816da8-2f27-49a2-acba-401f290b5e5e.png)

![admin2](https://user-images.githubusercontent.com/108001918/234603082-32af3b1a-cd67-4ebd-b937-4363356a41f2.png)

Then the pipeline can run until it is stopped or completes all tasks.

*NB : Because of quotas issues with Let's Encrypt, if the server chosen is <https://acme-staging-v02.api.letsencrypt.org/directory> the curl task in the pipeline can't verify the certificate.  
However with the other server <https://acme-v02.api.letsencrypt.org/directory> it works perfectly.*

[&#8679;](#top)

<div id='PromGraf'/>  

### **Installation of Prometheus and Grafana**

In order to install Prometheus and Grafana, I followed this [tutorial](https://shailender-choudhary.medium.com/monitor-azure-kubernetes-service-aks-with-prometheus-and-grafana-8e2fe64d1314).

I used Helm and the following commands :

```bash

```

[&#8679;](#top)

--------

<div id='Definition'/>  

### **Definition of the different tools**

[&#8679;](#top)

<div id='Sonar'/> 

#### a) SonarQube :  a Static Application Security Testing (SAST) solution

*Definition :* SonarQube is a comprehensive platform that can analyze over 27 programming languages and checks for potential security vulnerabilities, bugs, and code smells. It offers static and dynamic security testing features, as well as code compliance and quality checks. The platform also provides a complete view of project health, including an overview of vulnerabilities.

*Advantages :* SonarQube is a complete solution for code quality and security analysis. It provides detailed reports and metrics to measure code quality and security. SonarQube integrates well with popular CI/CD platforms, including GitLab CI/CD and Azure DevOps.

*Inconvenients :* SonarQube can sometimes produce false positives and its installation and configuration process can be long and tedious. Its free version may have limitations in terms of functionality and support.SonarQube's analysis can be resource-intensive and may require a powerful server to run effectively.

[&#8679;](#top)

<div id='OWASP1'/> 

#### b) OWASP Dependency-Check : a Software Composition Analysis (SCA) solution

*Definition :* OWASP Dependency-Check is an open-source project dependency security testing solution. It can detect vulnerabilities in third-party libraries. It scans both the direct and transitive dependencies of the project and compares them against a database of known vulnerabilities. It supports multiple programming languages, including Java, .NET, and Python.

*Advantages :* For testing vulnerabilities in third-party libraries, OWASP Dependency-Check is a solid choice. It is easy to use, install adn customize to fit a project's specific needs. It provides a comprehensive database of known vulnerabilities and is regularly updated. It also supports multiple programming languages and can be easily integrated into most CI/CD pipelines.

*Inconvenients :* It can produce a large number of false positives and can only detect known vulnerabilities, requiring manual review and investigation. Dependency-Check may add additional time to the build process, especially for large projects with many dependencies.

[&#8679;](#top)

<div id='Clair'/> 

#### c) [Clair](https://github.com/quay/clair) : a Container Image Security solution

*Definition :* Clair is an open-source container security testing tool. It can analyze and detect known vulnerabilities in container images, OS packages and application dependencies. It works by comparing the layers of a container image against a database of known vulnerabilities. Clair can be used with various container image registries, including Docker and Quay.

*Advantages :* Clair is easy to install and use. Clair is simple and easy to use for containers as it can be integrated with a variety of container image registries and works with various operating systems. It offers detailed reports and can detect vulnerabilities in both the OS packages and application dependencies. Clair has a flexible architecture, allowing users to choose from various database and API options.

*Inconvenients :* Clair cannot detect unknown vulnerabilities, does not scan running containers cannot detect vulnerabilities introduced after the container has been built. It can be resource-intensive and may require a powerful server to run effectively, especially for large container images. Clair may produce false positives or negatives and requires manual review and investigation.

[&#8679;](#top)

<div id='Trivy'/> 

#### d) [Trivy](https://github.com/aquasecurity/trivy) : a Container Image Security solution

*Definition :* Trivy is an open-source container security testing tool. It can detect and identify known and unknown vulnerabilities in container images, both OS packages and application dependencies by comparing the layers of a container image against a database of known vulnerabilities. Trivy can be used with various container image registries, including Docker and Kubernetes.

*Advantages :* Trivy is a powerful tool that supports multiple types of containers and can detect unknown vulnerabilities. It also has a comprehensive vulnerability database and is regularly updated with the latest CVEs. Trivy has a simple and easy-to-use command-line interface, and it can be integrated into most CI/CD pipelines.

*Inconvenients :* The runtime of Trivy can be long on large container images, therefore it can be resource-intensive and may require a powerful server to run effectively. Trivy only performs static analysis and cannot detect vulnerabilities introduced after the container has been built and deployed. Manual review and investigation my be required as Trivy can produce false positives or negatives.

[&#8679;](#top)

<div id='Grype'/> 

#### e) [Grype](https://github.com/anchore/grype) : a Software Composition Analysis (SCA) solution

*Definition :* Grype is an open-source container security testing tool (similar to Trivy) that scan images and packages for vulnerabilities. It identifies vulnerabilities in both OS packages and application dependencies by comparing the packages and dependencies against a database of known vulnerabilities. Grype can be used with various container image registries, including Docker and Kubernetes.

*Advantages :* It can detect known and unknown vulnerabilities in container images thanks to a comprehensive vulnerability database regularly updated with the latest CVEs. It can detect vulnerabilities in both the OS packages and application dependencies and supports multiple types of containers. Grype is highly configurable and can be easily integrated into most CI/CD pipelines.

*Inconvenients :* It does not support all of Docker's features, such as platform manifests and only performs static analysis. It cannot detect vulnerabilities introduced after the container has been built and deployed. It can be resource-intensive and may require a powerful server to run effectively, especially for large container images. 
As Grype can produce false positives or negatives, manual review and investigation can be required. There may be compatibility issues with older versions of Python.

[&#8679;](#top)

<div id='OWASP2'/> 

#### f) OWASP Zap : a Dynamic Application Security Testing (DAST) solution

*Definition :* OWASP Zap (Zed Attack Proxy) is an open-source security testing tool for web applications and checks for security vulnerabilities. ZAP can be used for a wide range of security testing, including automated scanning, manual testing, and penetration testing and works by simulating attacks on the web application and analyzing the responses to identify vulnerabilities.

*Advantages :* For web application security testing, OWASP Zap is a popular option. It offers a wide range of security testing features and can detect a wide range of security vulnerabilities, including injection flaws, cross-site scripting, and broken authentication. It offers a flexible and customizable testing framework, allowing users to create and run custom tests. ZAP provides a comprehensive report of the vulnerabilities detected, including recommendations for remediation. Fianlly it is easy to install and use.

*Inconvenients :* It can produce a large number of false positives which requires manual review and investigation. It may be resource-intensive and may require a powerful server to run effectively, especially for large and complex web applications. As ZAP may generate a large number of alerts it requires skilled security professionals to interpret and act on the results an therefore can be difficult to configure and use for inexperienced users. 

[&#8679;](#top)

----------

**Trivy :**

Trivy can be added to the pipeline by using a Docker container that has Trivy installed. Here are the steps to integrate Trivy :

* Add a new stage to the pipeline and call it "Security Scan".
* Add a new job to the "Security Scan" stage and name it "Trivy Scan".
* Specify the Docker image that contains Trivy by adding a Docker task to the "Trivy Scan" job.
* Configure the Docker task to run Trivy and scan your Docker image.

Here is an example YAML code for the "Security Scan" stage that runs Trivy :

```yaml
# Security Trivy
- stage: [stage name]
  dependsOn: Build
  jobs:
  - job: [job name]
    displayName: '[job display name]'
    pool:
      vmImage: '[vm image to run the scan - ubuntu-latest recommended by Az DevOps]'
    steps:
    - task: trivy@1
      inputs:
        version: 'latest'
        debug: [boolean]
        loginDockerConfig: [boolean]
        image: '[image to scan]'
        severities: '[CRITICAL,HIGH,MEDIUM,LOW,UNKNOWN]'
        ignoreUnfixed: [boolean]

```

```yaml
# Security Trivy
- stage: TrivyScanSec
  dependsOn: Build
  jobs:
  - job: TrivyScan
    displayName: 'Run Trivy Scan'
    pool:
      vmImage: 'ubuntu-latest'
    steps:
    - task: trivy@1
      inputs:
        version: 'latest'
        debug: true
        loginDockerConfig: true
        image: 'dunvael/custom-voting-app'
        severities: 'CRITICAL,HIGH,MEDIUM'
        ignoreUnfixed: true
      displayName: 'Run Trivy scan and save report'
      # Save the Trivy report to a file in the $(Build.ArtifactStagingDirectory) directory
      # so that it can be uploaded as an artifact in the next step.
      # Check out the GitHub repository using a Personal Access Token (PAT) as a secure way to authenticate.
      # The token should have the "repo" scope.
    - checkout: self
      persistCredentials: true
      displayName: 'Checkout GitHub repository'
      condition: always()
        # Copy the Trivy report from the artifact staging directory to the local directory of the checked-out repository
        # so that it can be committed and pushed to the remote repository.
    - task: CmdLine@2
      inputs:
        script: |
          mkdir reports
          cp /tmp/trivy-results-0.*.json reports/trivy-report.json
          git add reports/trivy-report.json
          git config --global user.email "simplon.example@gmail.com"
          git config --global user.name "Simplon-example"
          git commit -m "Add Trivy report"
          git push origin HEAD:main
      displayName: 'Push Trivy report to GitHub'
      condition: always()
```

**OWASP Zap :**

OWASP Zap can be added to the pipeline by using an extension that has OWASP Zap installed. Here are the steps to integrate OWASP Zap :

* Add a new stage to the pipeline and call it "Security Scan".
* Add a new job to the "Security Scan" stage and name it "OWASP Zap Scan".
* Configure the OWASP Zap task to scan your application (via its URL).

Here is an example YAML code for the "Security Scan" stage that runs OWASP Zap:

```yaml
# OWASP ZAP Scan
- stage: OwaspZapScanSec
  dependsOn: DeployQUA
  jobs:
    - job: ZapScan
      displayName: 'Run OWASP Zap security scan'
      continueOnError: true
      pool:
        vmImage: 'ubuntu-latest'
      steps:
      - task: owaspzap@1
        inputs:
          aggressivemode: true
          scantype: 'targetedScan'
          url: 'https://example-URL.toscan'
          port: '80, 443'
        displayName: 'Run OWASP Zap scan and save report'
        # Check out the GitHub repository using a Personal Access Token (PAT) as a secure way to authenticate.
      - checkout: self
        persistCredentials: true
        displayName: 'Checkout GitHub repository'
        condition: always()
          # Copy the OWASP Zap report from the artifact staging directory to the local directory of the checked-out repository so that it can be committed and pushed to the remote repository.
      - task: CmdLine@2
        inputs:
          script: |
            mkdir reports
            file=$(find . -name report.json)
            cp "$file" reports/zap-report.json
            git add reports/zap-report.json
            git config --global user.email "simplon.example@gmail.com"
            git config --global user.name "Simplon-example"
            git commit -m "Add OWASP Zap test results"
            git push origin HEAD:main
        displayName: 'Push OWASP Zap report to GitHub'
        condition: always()
```

[&#8679;](#top)

<div id='UsefullCommands'/>  

### **USEFULL COMMANDS**

### **To clone and pull a GitHub repository**

```bash
git clone [GitHubRepositoryURL]
```

```bash
git pull
```

[&#8679;](#top)

### **To create an alias for a command on azure CLi**

alias [WhatWeWant]="[WhatIsChanged]"  

*Example :*  

```bash
alias k="kubectl"
```

[&#8679;](#top)

### **To deploy resources with yaml file**

kubectl apply -f [name-of-the-yaml-file]

*Example :*  

```bash
kubectl apply -f azure-vote.yaml
```

[&#8679;](#top)

### **To check resources**

```bash
kubectl get nodes
kubectl get pods
kubectl get services
kubectl get deployments
kubectl get events
kubectl get secrets
kubectl get logs
```

*To keep verifying the resources add --watch at the end of the command :*

*Example :*

```bash
kubectl get services --watch
```

*To check the resources according to their namespace, add --namespace after the command and the namespace's name :*

*Example :*

```bash
kubectl get services --namespace [namespace's-name]
```

[&#8679;](#top)

### **To describe resources**

```bash
kubectl describe nodes
kubectl describe pods
kubectl describe services # or svc
kubectl describe deployment # or deploy
kubectl describe events
kubectl describe secrets
kubectl describe logs
```

*To specify which resource needs to be described just put the resource ID at the end of the command.*

*Example :*

```bash
kubectl describe svc redis-service
```

*To access to all the logs from all containers :*

```bash
kubectl logs podname --all-containers
```

*To access to the logs from a specific container :*

```bash
kubectl logs podname -c [container's-name]
```

*To list all events from a specific pod :*

```bash
kubectl get events --field-selector [involvedObject].name=[podsname]
```

[&#8679;](#top)

### **To delete resources**

```bash
kubectl delete deploy --all
kubectl delete svc --all
kubectl delete pvc --all
kubectl delete pv --all
az group delete --name [resourceGroupName] --yes --no-wait
```

[&#8679;](#top)

### **To check TLS certificate in request order**

```bash
kubectl get certificate
kubectl get certificaterequest
kubectl get order
kubectl get challenge
```

[&#8679;](#top)

### **To describe TLS certificate in request order**

```bash
kubectl describe certificate
kubectl describe certificaterequest
kubectl describe order
kubectl describe challenge
```

[&#8679;](#top)

### **Get the IP address to point the DNS to nginx in the two namespaces**

```bash
kubectl get svc --all-namespaces
```

[&#8679;](#top)

</div>
