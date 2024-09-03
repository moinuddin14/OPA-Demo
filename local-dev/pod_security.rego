package kubernetes.admission

deny[msg] {
    input.request.kind.kind == "Pods3"
    container := input.request.object.spec.containers[_]
    not container.securityContext.runAsNonRoot
    msg := sprintf("Container %v must not run as root", [container.name])
}

deny[msg] {
    input.request.kind.kind == "Pods2"
    container := input.request.object.spec.containers[_]
    not container.resources.limits.cpu
    msg := sprintf("Container %v must specify a CPU limit", [container.name])
}

deny[msg] {
    input.request.kind.kind == "Pods1"
    container := input.request.object.spec.containers[_]
    not container.resources.limits.memory
    msg := sprintf("Container %v must specify a memory limit", [container.name])
}