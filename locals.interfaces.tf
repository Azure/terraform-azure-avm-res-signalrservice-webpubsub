locals {
  interface_private_endpoints = {
    for key, endpoint in var.private_endpoints : key => merge(endpoint, {
      name                            = coalesce(endpoint.name, "${var.name}-pe-${substr(uuidv5("url", key), 0, 8)}")
      network_interface_name          = coalesce(endpoint.network_interface_name, "${var.name}-nic-${substr(uuidv5("url", key), 0, 8)}")
      private_service_connection_name = coalesce(endpoint.private_service_connection_name, "${var.name}-psc-${substr(uuidv5("url", key), 0, 8)}")
      subresource_name                = coalesce(endpoint.subresource_name, "webpubsub")
      lock                            = endpoint.lock == null ? var.lock : (endpoint.lock.kind == "None" ? null : endpoint.lock)
      ip_configurations = {
        for configuration_key, configuration in endpoint.ip_configurations : configuration_key => merge(configuration, {
          member_name = coalesce(configuration.member_name, "webpubsub")
        })
      }
      role_assignments = {
        for assignment_key, assignment in endpoint.role_assignments : assignment_key => merge(assignment, {
          principal_type = assignment.principal_type != null ? assignment.principal_type : (assignment.skip_service_principal_aad_check ? "ServicePrincipal" : null)
        })
      }
    })
  }
}
