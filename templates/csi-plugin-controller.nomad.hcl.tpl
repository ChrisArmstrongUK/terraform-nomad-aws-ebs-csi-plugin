job "${job_name}" {
  region = "${region}"
  datacenters = [
%{ for dc in datacenters ~}
    "${dc}",
%{ endfor ~}
  ]
  type = "system"

  group "csi_plugin_controller" {
    task "csi_driver" {
      driver = "docker"

      config {
        image = "${plugin_image}:${plugin_image_version}"

        args = [
          "--endpoint=unix://csi/csi.sock",
          "--logtostderr",
          "--v=5",
        ]
      }

      csi_plugin {
        id = "${plugin_id}"
        type = "controller"
        mount_dir = "${plugin_csi_mount_dir}"
      }

      resources {
        cpu = ${plugin_cpu}
        memory = ${plugin_memory}
      }
    }
  }
}