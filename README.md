## Kubefed playground

### Set up kubefed clusters using kind

To create kubefed clusters using `kind` run:

```bash
./setup.sh
```

This will create 4 kind clusters (`cluster1-4`), deploy `kubefed` (via `helm`), and join all clusters to the host cluster (`cluster1`), ready to be used.

### Connecting to the clusters

After creating the clusters, there will be a single merged `kubeconfig` file called `kubefed-kubeconfig.yml`, with the current context set to the host cluster. To use this to connect to any of the other clusters, first run:

```bash
export KUBECONFIG=kubefed-kubeconfig.yml
```

And then specify the relevant context in your `kubectl` commands, e.g.:

```bash
kubectl get pods --context cluster2-admin@cluster2
```

### Cleanup

To delete all clusters run:

```bash
./cleanup.sh
```
