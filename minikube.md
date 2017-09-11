# Install the Gitlab Helm Charts to Minikube for demo

Please be noted this is for demo or practice only. It's not suitable for production usage.

## Minikube Brief Introduction

Please see https://gitlab.com/charts/helm.gitlab.io/tree/master/doc/minikube.

More detailed information is available at [Minikube website](https://kubernetes.io/docs/getting-started-guides/minikube/).


## Challenges to port the demo to Minikube environment

* Local laptop usually could not have fixed IP or DNS or get firewall opened.
* Minikube only supports hostPath for Persistent Volume
* Registry needs trusted certificate to run in https mode to avoid endless troubles

## Ways to overcome above limitations
* Use local DNS services on the laptop to serve wildcard DNS
* Use standard storage class for persistent volume which comes with Minikube
* Leave registry service running https and change others to plan http
* Use [ngrok](https://ngrok.com/) to achieve [Automatic generation of Let’s Encrypt certificates on Minikube](https://developer.ibm.com/recipes/tutorials/automatic-generation-of-lets-encrypt-certificates-with-minikube/)

## Detailed instructions to setup

### Preparation
* Understand and install Minikube per documentation [here](https://gitlab.com/charts/helm.gitlab.io/tree/master/doc/minikube). 
* Config addons of Minikube
 * Enable "default-storageclass"
 
        ```
        minikube addons enable default-storageclass
        ```
        
 * Enable "kube-dns"
 
        ```
        minikube addons enable kube-dns
        ```
        
 * Disable "ingress"
 
        ```
        minikube addons disable ingress
        ```
* Install [DNSMasq](http://www.thekelleys.org.uk/dnsmasq/doc.html) for Mac or [Acrylic](http://mayakron.altervista.org/wikibase/show.php?id=AcrylicHome) for Windows
* Config DNSMasq or Acrylic to resolve only your target demo domain. See example and instructions at [another demo project](https://gitlab.com/xiaogang_gitlab/demo-vagrant#setup-instructions).
* Install [ngrok](https://ngrok.com/)
* Checkout the code in this repo to a working directory

### Demo setup
* Start the Minikube and note down its ip address

    ```
    minikube start
    ```

    ```
    minikube ip
    ```
* Update DNSmasq or Acrylic with the new ip address of the demo domain then restart the service. Below is an example for DNSmasq. In the rest of the document, "demo.io" will be used as demo domain and 192.168.99.111 as the Minikube VM ip. Please replace them with actual ip address and domain when you run your setup. 
  * Update the `/usr/local/etc/dnsmasq.conf` file with below entry
  
        ```
        address=/.demo.io/192.168.99.111
        ```
   * Restart the DNSmasq service
   
        ```
        sudo brew services restart dnsmasq
        ```
        
* Start ngrok in a different window and keep it open until the whole demo process is verified to work. Note down the dynamic hostname in the output which will be used in later steps.

    ```
    ngrok http demo.io:80
    ```
    
* Install and initialize Helm by referring instructions at [Installing GitLab on Kubernetes](https://docs.gitlab.com/ee/install/kubernetes/index.html). 
    
* Go to the working directory with the code checked out from this project and run the command to generate the yaml file.

    ```
    helm install --name gitlab --set provider=minikube,baseDomain=<your demo domain>,baseIP=$(minikube ip),legoEmail=<valid email address>,ngrokHostname=<dynamic ngrok hostname> charts/gitlab-omnibus
    ```
    
* Run additional commands per the end of screent output from above command to fix the DNS issue inside the pods. Below is a sample.

    ```shell
cat <<EOF | kubectl apply --force -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: kube-dns
  namespace: kube-system
data:
  stubDomains: |
    {
      "demo.io": ["192.168.99.1"],
      "834c0399.ngrok.io": ["192.168.99.1"]
    }
EOF
    ```
    
    Another option may be to disable the kube-dns addon of Minikube and deploy it with config via Helm chart.
 
        
* Check the progress untill all pods are up and running.
    
    ```
    kubectl get pods --all-namespaces
    ```

    You can also use Minikube dashboard to view the status. Use the command below to launch the dashboard
    
    ```
    minikube dashboard
    ```
* Check the cluster ip address for nginx service by running the command below or you can check it from dashboard

    ```
    kubectl get services --namespace nginx
    ```
* Update the DNSmasq entry with the ngrok dynamic hostname and cluster ip address to make the registry traffic inside the cluster.

    ```
    address=/<dynamic ngrok hostname>/<cluster ip address for nginx>
    ```
    Then restart the DNSmasq service again.
    ```
    sudo brew services restart dnsmasq
    ```
* Login to Minikube VM and udpate the hosts file. Note this file is not persistent across VM restart. You may have to do it again when cluster gets restarted.

    ```
    minikube ssh
    ```
    Edit the host file to have 2 extra lines like below and save it.
    ```
    sudo vi /etc/hosts
    ```
    ```
    <cluster ip address for nginx>  gitlab.<demo domain>
    <cluster ip address for nginx>  <ngrok dynamic hostname>
    ```
* Open a browser window and point it to `gitlab.<demo domain>` then go through the [Gitlab Idea to Production Demo](https://about.gitlab.com/handbook/sales/demo/). Everything should work except Promethus monitoring of the environment due to the limitation of Minikube.

## Trouble shooting

TBA