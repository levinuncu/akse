{
  "realm": "${REALM}",
  "enabled": true,
  "sslRequired": "none",
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
      "defaultClientScopes": ["roles", "profile", "email"]
    }
  ],
  "accessTokenLifespan": 300,
  "offlineSessionIdleTimeout": 900,
  "offlineSessionMaxLifespan": 3600,
  "refreshTokenMaxReuse": 0
}
