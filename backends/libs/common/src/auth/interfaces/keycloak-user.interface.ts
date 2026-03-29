import type { KeycloakRole } from '../enums/keycloak-role.enum';

export interface KeycloakUser {
  email: string;
  family_name: string;
  given_name: string;
  name: string;
  preferred_username: string;
  realm_access?: {
    roles?: KeycloakRole[];
  };
  sub: string;
}
