output "next_step_setup" {
  description = "Port forwarding for faster deployment, you can also wait for the service to be ready and use the https endpoint in 5-authentication-setup keycloak terraform provider"
  value       = "Access Keycloak via port-forward: kubectl port-forward svc/keycloak-keycloakx-http -n identity 8081:80"
}

output "keycloak_endpoint" {
  description = "Endpoint"
  value = "Access Keycloak at https://${var.keycloak_endpoint}"
}