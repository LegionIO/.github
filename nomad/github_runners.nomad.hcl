# LegionIO Self-Hosted GitHub Actions Runner Pool
#
# Deploys 6 ephemeral runners registered to the LegionIO org.
# Each runner picks up one job, then exits and Nomad restarts it fresh.
#
# Prerequisites:
#   1. Create a fine-grained PAT with Self-hosted runners (R/W) org permission
#   2. Store it as a Nomad variable:
#      nomad var put nomad/jobs/github-runners github_token="ghp_..."
#
# Routing:
#   All LegionIO repos use shared reusable workflows in .github.
#   To route jobs to these runners, update the shared workflows:
#
#     runs-on: ubuntu-latest
#   becomes:
#     runs-on: ${{ inputs.runner || 'ubuntu-latest' }}
#
#   Then add an input to each shared workflow:
#     inputs:
#       runner:
#         description: 'Runner label'
#         default: 'legion'       # <- flip to 'ubuntu-latest' to disable self-hosted
#         type: string
#
#   Since every repo calls these shared workflows via `uses:`, this single
#   change propagates to all repos. No individual repo updates needed.
#
#   Fallback: set the default back to 'ubuntu-latest' and jobs go to
#   GitHub-hosted runners. Or remove the runners from the org.

variable "runner_count" {
  description = "Number of parallel runner instances"
  type        = number
  default     = 6
}

variable "runner_image" {
  description = "Docker image for the GitHub Actions runner"
  type        = string
  default     = "myoung34/github-runner:latest"
}

variable "runner_cpu" {
  description = "CPU allocation per runner (MHz)"
  type        = number
  default     = 2000
}

variable "runner_memory" {
  description = "Memory allocation per runner (MB)"
  type        = number
  default     = 4096
}

job "github-runners" {
  datacenters = ["*"]
  type        = "service"

  meta {
    managed_by = "LegionIO/.github"
    purpose    = "self-hosted GitHub Actions runners"
  }

  group "runners" {
    count = var.runner_count

    update {
      max_parallel     = 2
      min_healthy_time = "30s"
      healthy_deadline = "5m"
      auto_revert      = true
    }

    restart {
      attempts = 5
      interval = "30m"
      delay    = "15s"
      mode     = "delay"
    }

    reschedule {
      delay          = "30s"
      delay_function = "exponential"
      max_delay      = "10m"
      unlimited      = true
    }

    network {
      mode = "host"
    }

    task "runner" {
      driver = "docker"

      template {
        data        = <<-EOT
{{ with nomadVar "nomad/jobs/github-runners" }}
ACCESS_TOKEN={{ .github_token }}
{{ end }}
EOT
        destination = "secrets/env.env"
        env         = true
      }

      config {
        image = var.runner_image
      }

      env {
        # Org-level registration
        RUNNER_SCOPE  = "org"
        ORG_NAME      = "LegionIO"

        # Runner identification
        RUNNER_NAME_PREFIX = "legion-nomad"
        RUNNER_WORKDIR     = "/tmp/runner"

        # Labels for job routing
        LABELS = "self-hosted,linux,x64,legion"

        # Ephemeral: pick up one job, then exit (Nomad restarts a fresh instance)
        EPHEMERAL = "true"

        # Disable automatic updates (managed by Nomad image deploys)
        DISABLE_AUTO_UPDATE = "true"
      }

      resources {
        cpu    = var.runner_cpu
        memory = var.runner_memory
      }

      # Docker socket for container-based actions
      volume_mount {
        volume      = "docker"
        destination = "/var/run/docker.sock"
        read_only   = false
      }
    }

    volume "docker" {
      type   = "host"
      source = "docker"
    }

    # Optional: preempt lower priority jobs if cluster is constrained
    # priority = 60
  }
}
