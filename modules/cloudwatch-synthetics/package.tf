resource "archive_file" "canary_bundle" {
  for_each = var.canaries

  type             = "zip"
  output_path      = local.archive_output_paths[each.key]
  output_file_mode = "0644"

  dynamic "source" {
    for_each = each.value.source_files
    content {
      content = (
        trimspace(source.value) != "" &&
        !startswith(source.value, "/") &&
        !endswith(source.value, "/") &&
        length(regexall("//", source.value)) == 0 &&
        !contains(split("/", source.value), ".") &&
        !contains(split("/", source.value), "..")
        ) ? (
        fileexists("${path.root}/${source.value}") ? file("${path.root}/${source.value}") : ""
      ) : ""
      filename = source.key
    }
  }

  source {
    content  = jsonencode(local.canary_configs[each.key].config)
    filename = "config.json"
  }

  lifecycle {
    precondition {
      condition = alltrue([
        for source_path in values(each.value.source_files) :
        (
          trimspace(source_path) != "" &&
          !startswith(source_path, "/") &&
          !endswith(source_path, "/") &&
          length(regexall("//", source_path)) == 0 &&
          !contains(split("/", source_path), ".") &&
          !contains(split("/", source_path), "..")
        ) ? fileexists("${path.root}/${source_path}") : false
      ])
      error_message = "Each source_files source path must refer to an existing file below the Terraform root; source symlinks are unsupported."
    }
  }
}
