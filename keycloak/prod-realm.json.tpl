{
  "realm": "${REALM}",
  "enabled": true,
  "sslRequired": "external",
  "registrationAllowed": true,
  "registrationEmailAsUsername": false,
  "loginWithEmailAllowed": true,
  "duplicateEmailsAllowed": false,
  "rememberMe": false,
  "verifyEmail": false,
  "resetPasswordAllowed": false,
  "editUsernameAllowed": false,
  "bruteForceProtected": true,
  "permanentLockout": false,
  "roles": {
    "realm": [
      {
        "name": "admin"
      }
    ]
  },
  "requiredCredentials": ["password"],
  "scopeMappings": [
    {
      "clientScope": "roles",
      "roles": ["admin"]
    }
  ],
  "clients": [
    {
      "clientId": "${CLIENT_ID}",
      "enabled": true,
      "clientAuthenticatorType": "client-secret",
      "secret": "${SECRET}",
      "redirectUris": [
        "${REDIRECT_URI}"
      ],
      "webOrigins": ["${WEB_ORIGIN}"],
      "bearerOnly": false,
      "directAccessGrantsEnabled": false,
      "standardFlowEnabled": true,
      "implicitFlowEnabled": false,
      "serviceAccountsEnabled": false,
      "consentRequired": false,
      "publicClient": false,
      "protocol": "openid-connect",
      "fullScopeAllowed": true,
      "defaultClientScopes": ["roles", "profile", "email"],
      "protocolMappers": [
        {
          "name": "subject",
          "protocol": "openid-connect",
          "protocolMapper": "oidc-usermodel-property-mapper",
          "consentRequired": false,
          "config": {
            "user.attribute": "id",
            "claim.name": "sub",
            "jsonType.label": "String",
            "id.token.claim": "true",
            "access.token.claim": "true",
            "userinfo.token.claim": "true"
          }
        },
        {
          "name": "realm roles",
          "protocol": "openid-connect",
          "protocolMapper": "oidc-usermodel-realm-role-mapper",
          "consentRequired": false,
          "config": {
            "multivalued": "true",
            "claim.name": "realm_access.roles",
            "jsonType.label": "String",
            "id.token.claim": "true",
            "access.token.claim": "true",
            "userinfo.token.claim": "true"
          }
        }
      ]
    }
  ],
  "accessTokenLifespan": 1800,
  "offlineSessionIdleTimeout": 7200,
  "offlineSessionMaxLifespan": 14400,
  "refreshTokenMaxReuse": 0
}
