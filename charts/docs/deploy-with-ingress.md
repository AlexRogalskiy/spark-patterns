# Deploy with ingress

The `spark-patterns` Helm chart can be used to deploy and configure the `spark-patterns` application for use with an ingress controller.

> **Note:**
>
> The `spark-patterns` Helm chart does **not** deploy an [Ingress Controller](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/) and does **not** deploy the [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/) definition.
>
> The chart aims to support deployment to as many platforms and providers as possible, so the choice of Ingress Controller and configuration of Ingress resource is left to the person deploying.

## Prerequisites

- [Helm 3](https://v3.helm.sh/)

If you are using the [VS Code Remote Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) based development
environment, all of the prerequisites will be available in the terminal.

## Install ingress controller

Install an [Ingress Controller](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/) that is available for your platform or provider.
Here is an example that uses the [Nginx Ingress Controller](https://kubernetes.github.io/ingress-nginx/deploy/) on a cloud provider:

```bash
$ helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

$ helm install nginx-ingress ingress-nginx/ingress-nginx \
    --create-namespace --namespace ingress \
    --set controller.replicaCount=2
```

## Use webapp with ingress

### Deploy webapp instances

Install two `spark-patterns` instances that will be available via 2 different paths on the ingress.

The `spark-patterns` instance will display the default "Hello world!" message, and the `custom-spark-patterns` instance will display a "This is my custom
message!" message.

```bash
$ helm install --create-namespace --namespace webapp spark-patterns . \
  --set ingress.configured=true --set ingress.pathPrefix=hello-world \
  --set service.type=ClusterIP

$ helm install --create-namespace --namespace webapp custom-spark-patterns . \
  --set ingress.configured=true --set ingress.pathPrefix=custom-message \
  --set service.type=ClusterIP \
  --set message="This is my custom message!"
```

### Deploy ingress definition

The `spark-patterns` Helm chart has a `ingress.rewritePath` configuration parameter that is `true` by default. When used together with
the `ingress.configured=true` configuration parameter, there is an assumption that the ingress being used supports path rewrites. See
the [Deploy using Helm](charts2/docs/deploy-using-helm.md) guidance for more details.

So from our example, a request to `/spark-patterns` should be rewritten to `/` before being passed to the `spark-patterns` app instance.

Create a file named `webapp-ingress.yaml` with the content below. This ingress definition will be serviced by the nginx ingress controller due to
the `kubernetes.io/ingress.class: nginx` annotation. It will also leverage the path rewrite capabilities of nginx via
the `nginx.ingress.kubernetes.io/rewrite-target: /$2` annotation.

```yaml
# webapp-ingress.yaml
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: webapp-ingress
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/rewrite-target: /$2
spec:
  rules:
    - http:
        paths:
          - backend:
              serviceName: webapp-spark-patterns
              servicePort: 8000
            path: /hello-world(/|$)(.*)
          - backend:
              serviceName: webapp-custom-spark-patterns
              servicePort: 8000
            path: /custom-message(/|$)(.*)
```

Deploy the contents of the `webapp-ingress.yaml` into the same namespace as the two `spark-patterns` apps.

```bash
$ kubectl apply -n webapp -f webapp-ingress.yaml
```

### Browse

You can browse to each of the `spark-patterns` apps via the $INGRESS_CONTROLLER_IPADDRESS and each of the configured paths. So for our example at:

- `$INGRESS_CONTROLLER_IPADDRESS/hello-world` - the `spark-patterns` instance with the default "Hello world!" message
- `$INGRESS_CONTROLLER_IPADDRESS/custom-spark-patterns` - the `custom-spark-patterns` instance with the "This is my custom message!" message

## Alternatives

You can deploy the `spark-patterns` app via the Helm chart with the `ingress.rewritePath=false` configuration parameter if you are deploying with an ingress
controller that does not support path rewrites.

In this case, the `spark-patterns` apps will serve dynamic content and static assets from the path defined by the `ingress.pathPrefix` configuration parameter.
