![Terraform Validate](https://github.com/KristophUK/terraform-nomad-aws-ebs-csi-plugin/workflows/Terraform%20Validate/badge.svg?branch=master)

# Terraform Module - AWS EBS CSI Plugin

AWS EBS is a block storage service provided by AWS. This module deploys the AWS EBS CSI Plugin into Nomad to allow Nomad jobs to use AWS EBS volumes as persistant storage for stateful workloads.

## Links

- [Nomad Storage Plugins - CSI Plugins](https://www.nomadproject.io/docs/internals/plugins/csi#csi-plugins)
- [AWS EBS - Product Page](https://aws.amazon.com/ebs/)
- [AWS EBS CSI Driver - GitHub Repository](https://github.com/kubernetes-sigs/aws-ebs-csi-driver)
- [AWS EBS CSI Driver - AWS Documentation](https://docs.aws.amazon.com/eks/latest/userguide/ebs-csi.html)

## Note before use

The CSI itself can be found on the [AWS EBS CSI Driver GitHub Page](https://github.com/kubernetes-sigs/aws-ebs-csi-driver). It's a good place to look for documentation, features and issues. Most of the documentation on the GitHub page at the moment assumes you're using Kubernetes but the CSI itself should be cross compatible with any container orchestrator that supports CSI. (Which includes Nomad).

## Deploying the plugin to Nomad

### Privileged Containers

The nomad agents and docker daemon must be configured to allow privileged containers. Make sure you understand what this means before proceeding and check the docker image being run as part of this job.

nomad config snippet...
```HCL
client {
    enabled = true
    options {
        "docker.privileged.enabled" = "true"
    }
}
```

### Deployment the CSI Plugin

See provision instructions on the [Terraform Registry page](https://registry.terraform.io/modules/KristophUK/aws-ebs-csi-plugin/nomad/)

## Registering an EBS Volume

Once the plugin has deployed successfully you can register an EBS Volume. Create a volume config file such as the one below.
---
ebs-volume.hcl
```HCL
id = "ebs0"
name = "ebs0"
type = "csi"
plugin_id = "aws-ebs"
external_id = [EBSVolumeId]
access_mode = "single-node-writer"
attachment_mode = "file-system"
```
---
Then register the volume...
```shell
nomad volume register ebs-volume.hcl
```
---
You can also register the volume using Terraform and the Nomad Provider. See the module examples.

## Using the volume

Once the volume has been registered it can be used in a jobspec. For this example, assume a volume has already been registered with the id `jenkins_ebs`. You could then run this job and setup Jenkins, maybe creating a job or two. If you then purge and re-create the jenkins job, you should see all the config changes and jobs you created have persisted.

```HCL
job "jenkins" {
  datacenters = ["dc1"]
  type        = "service"

  group "jenkins" {
    count = 1

    volume "jenkins_home" {
      type      = "csi"
      read_only = false
      source    = "jenkins_ebs"
    }

    task "jenkins" {
      driver = "docker"

      volume_mount {
        volume      = "jenkins_home"
        destination = "/var/jenkins_home"
        read_only   = false
      }

      config {
        image = "jenkins/jenkins:latest"

        port_map {
          http = 8080
          jnlp = 50000
        }
      }

      resources {
        cpu    = 500
        memory = 512
        network {
          port "http" {}
          port "jnlp" {}
        }
      }

      service {
        name = "jenkins"
        port = "http"

        check {
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}
```