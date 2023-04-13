# Run ORAS CSI driver in kind

Create the kind cluster with the a local registry using the following script 

```shell 
❯ hack/kind-with-registry.sh
Creating cluster "oras" ...
 ✓ Ensuring node image (kindest/node:v1.25.3) 🖼
 ✓ Preparing nodes 📦
 ✓ Writing configuration 📜
 ✓ Starting control-plane 🕹🕹️
 ✓ Installing CNI 🔌
 ✓ Installing StorageClass 💾
Set kubectl context to "kind-oras"
You can now use your cluster with:

kubectl cluster-info --context kind-oras

Thanks for using kind! 😊
configmap/local-registry-hosting created
```

## Update oras-csi deployment

To deploy the oras-csi driver update `csi-oras.yaml`
 - https://github.com/converged-computing/oras-csi/blob/8f5d240fd94a1f9fd9006122d0eea4f9583f310c/deploy/kubernetes/csi-oras.yaml#L160

From 
  
```yaml
          image: ghcr.io/converged-computing/oras-csi-plugin:latest
```

to 

```yaml
          image: localhost:5001/oras-csi-plugin:latest
```

## Deploying the driver

Make dev will use the kind cluster as the context and build and push to your local registry at `localhost:5001` 

```
make dev DOCKER_REGISTRY=localhost:5001
``` 

You can validate if your images are in the registry 

```shell
$ oras repo tags localhost:5001/oras-csi-plugin
latest
0.1.0-dev
```

Also validate if your pods are running 

```shell
❯ kubectl logs --follow $(kubectl get pods -l 'app=csi-oras-node' --all-namespaces -o jsonpath='{.items[*].metadata.name}') -n kube-system
Defaulted container "driver-registrar" out of: driver-registrar, csi-oras-plugin
I0412 23:45:13.384094       1 main.go:110] Version: v1.1.0-0-g80a94421
I0412 23:45:13.384148       1 main.go:120] Attempting to open a gRPC connection with: "/csi/csi.sock"
I0412 23:45:13.384164       1 connection.go:151] Connecting to unix:///csi/csi.sock
I0412 23:45:18.646061       1 main.go:127] Calling CSI driver to discover driver name
I0412 23:45:18.646194       1 connection.go:180] GRPC call: /csi.v1.Identity/GetPluginInfo
I0412 23:45:18.646237       1 connection.go:181] GRPC request: {}
I0412 23:45:18.648333       1 connection.go:183] GRPC response: {"name":"csi.oras.land","vendor_version":"0.1.0"}
I0412 23:45:18.648762       1 connection.go:184] GRPC error: <nil>
I0412 23:45:18.648769       1 main.go:137] CSI driver name: "csi.oras.land"
I0412 23:45:18.648810       1 node_register.go:54] Starting Registration Server at: /registration/csi.oras.land-reg.sock
I0412 23:45:18.648991       1 node_register.go:61] Registration Server started at: /registration/csi.oras.land-reg.sock
I0412 23:45:19.360555       1 main.go:77] Received GetInfo call: &InfoRequest{}
I0412 23:45:19.378305       1 main.go:87] Received NotifyRegistrationStatus call: &RegistrationStatus{PluginRegistered:true,Error:,}
```


## Pushing your images 

Images in the local kind registry can be reference using the `kind-registry:5000` as the registry host. 

```shell
❯ oras copy ghcr.io/singularityhub/github-ci:latest localhost:5001/github-ci:latest
Copying acb1ec674e68 container.sif
Copied  acb1ec674e68 container.sif
Copied [registry] ghcr.io/singularityhub/github-ci:latest => [registry] localhost:5001/github-ci:latest
Digest: sha256:5d6742ff0b10c1196202765dafb43275259bcbdbd3868c19ba1d19476c088867 
```

- Deploy the sample pod and mount the artifact from local registr y

```shell
kubectl apply -f hack/pod.yaml
```


