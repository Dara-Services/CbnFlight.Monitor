terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4"
    }
  }
}

provider "cloudflare" {
  # read token from $CLOUDFLARE_API_TOKEN
}

variable "CLOUDFLARE_ACCOUNT_ID" {
  # read account id from $TF_VAR_CLOUDFLARE_ACCOUNT_ID
  type = string
}

variable "enable_do_migration" {
  # read from $TF_VAR_enable_do_migration
  type    = bool
  default = false
}

resource "cloudflare_d1_database" "uptimeflare_d1" {
  account_id = var.CLOUDFLARE_ACCOUNT_ID
  name       = "uptimeflare_d1-cbnflight"
}

resource "cloudflare_worker_script" "uptimeflare_worker" {
  account_id         = var.CLOUDFLARE_ACCOUNT_ID
  name               = "uptimeflare_worker-cbnflight"
  content            = file("worker/dist/index.js")
  module             = true
  compatibility_date = "2023-11-08"

  d1_database_binding {
    name        = "UPTIMEFLARE_STATE"
    database_id = cloudflare_d1_database.uptimeflare_d1.id
  }

  # This is a migration resource that is used to migrate from old namespace to new namespace
  # After migration is done, you can remove this block (and the variable)
  dynamic "durable_object_namespace_binding" {
    for_each = var.enable_do_migration ? [1] : []
    content {
      name       = "UPTIMEFLARE_OLD_REMOTE_CHECKER"
      namespace_id = var.enable_do_migration ? "OLD_NAMESPACE_ID" : ""
    }
  }
}

resource "cloudflare_worker_cron_trigger" "uptimeflare_worker_cron" {
  account_id  = var.CLOUDFLARE_ACCOUNT_ID
  script_name = cloudflare_worker_script.uptimeflare_worker.name
  schedules = [
    "* * * * *", # every 1 minute
  ]
}

resource "cloudflare_pages_project" "uptimeflare" {
  account_id        = var.CLOUDFLARE_ACCOUNT_ID
  name              = "uptimeflare-cbnflight"
  production_branch = "main"

  deployment_configs {
    production {
      d1_databases = {
        UPTIMEFLARE_STATE = cloudflare_d1_database.uptimeflare_d1.id
      }
      compatibility_date  = "2023-11-08"
      compatibility_flags = ["nodejs_compat"]
    }
  }
}
