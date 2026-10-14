// =============================================================================
//  Demo de IA gobernada — Plataforma compartida (Banca + Salud)
//  Despliega UNA sola plataforma de AI Gateway que hospeda AMBAS demos:
//    - AI Foundry (Azure OpenAI): gpt-4o + text-embedding-3-small
//    - Azure API Management (AI Gateway): APIs banca/salud, productos con cuota
//      por unidad de negocio, autenticación keyless (Managed Identity),
//      caché semántica (Azure Managed Redis + RediSearch) y trazas de FinOps.
//    - Azure Container Apps: 2 apps web (Aria / Iris).
//    - Application Insights + Log Analytics (observabilidad / FinOps).
//    - Azure Container Registry (imágenes de las apps).
//
//  Alcance: resource group.  Compila a azuredeploy.json (botón Deploy to Azure).
// =============================================================================

targetScope = 'resourceGroup'

// ------------------------------ Parámetros ----------------------------------
@description('Región de Azure para todos los recursos.')
param location string = resourceGroup().location

@description('Prefijo corto para nombrar los recursos.')
@minLength(2)
@maxLength(10)
param namePrefix string = 'aigov'

@description('Sufijo único (por defecto derivado del grupo de recursos).')
param resourceSuffix string = substring(uniqueString(resourceGroup().id), 0, 5)

@description('Email del publicador de API Management (requerido por APIM).')
param apimPublisherEmail string = 'admin@contoso.com'

@description('Nombre del publicador de API Management.')
param apimPublisherName string = 'Contoso AI Platform'

@description('Nombre del despliegue del modelo de chat.')
param chatDeploymentName string = 'gpt-4o'

@description('Versión del modelo gpt-4o.')
param chatModelVersion string = '2024-11-20'

@description('Capacidad (miles de TPM) del modelo de chat.')
param chatCapacity int = 20

@description('Nombre del despliegue del modelo de embeddings (caché semántica).')
param embeddingDeploymentName string = 'text-embedding-3-small'

@description('Capacidad (miles de TPM) del modelo de embeddings.')
param embeddingCapacity int = 50

@description('Desplegar Azure Managed Redis para la caché semántica (tiene costo mientras esté activo).')
param deploySemanticCache bool = true

@description('Imagen de contenedor para la app de Banca. Por defecto un placeholder público que se reemplaza al construir la imagen real.')
param bancaImage string = 'mcr.microsoft.com/k8se/quickstart:latest'

@description('Imagen de contenedor para la app de Salud.')
param saludImage string = 'mcr.microsoft.com/k8se/quickstart:latest'

@description('Imagen de contenedor para la app de Logística (ALMEX).')
param almexImage string = 'mcr.microsoft.com/k8se/quickstart:latest'

@description('Imagen de contenedor para la app de Manufactura (Bocar).')
param bocarImage string = 'mcr.microsoft.com/k8se/quickstart:latest'

@description('Construir automáticamente las imágenes de las apps desde el repo público y actualizarlas (botón one-click).')
param buildAppImages bool = true

@description('URL .git del repositorio público con el código de las apps (para az acr build).')
param repoGitUrl string = 'https://github.com/gracielars999/azure-ai-governance-demos.git'

@description('Rama del repositorio para construir las imágenes.')
param repoBranch string = 'main'

@description('Marca de tiempo para forzar la re-ejecución del script de construcción (no modificar).')
param deploymentTimestamp string = utcNow()

// ------------------------------ Variables -----------------------------------
var suffix = toLower(resourceSuffix)
var lawName = '${namePrefix}-law-${suffix}'
var appInsightsName = '${namePrefix}-appi-${suffix}'
var acrName = toLower('${namePrefix}acr${suffix}')
var aiName = '${namePrefix}-aif-${suffix}'
var redisName = '${namePrefix}-amr-${suffix}'
var apimName = '${namePrefix}-apim-${suffix}'
var acaEnvName = '${namePrefix}-cae-${suffix}'
var bancaAppName = 'ca-banca-web'
var saludAppName = 'ca-salud-web'
var almexAppName = 'ca-almex-web'
var bocarAppName = 'ca-bocar-web'
var uamiName = '${namePrefix}-deploy-${suffix}'

var cognitiveServicesUserRoleId = 'a97b65f3-24c7-4388-baec-2e87135dc908'
var acrPullRoleId = '7f951dda-4ed3-4680-a7ca-43fe172d538d'
var contributorRoleId = 'b24988ac-6180-42a0-ab88-20f7382dd24c'

var aoaiBaseUrl = '${aiServices.properties.endpoint}openai'
var embeddingsBackendUrl = '${aiServices.properties.endpoint}openai/deployments/${embeddingDeploymentName}/embeddings'

// ============================ Observabilidad ================================
resource law 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: lawName
  location: location
  properties: {
    sku: { name: 'PerGB2018' }
    retentionInDays: 30
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: law.id
  }
}

// ============================ Registro (ACR) ================================
resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: acrName
  location: location
  sku: { name: 'Basic' }
  properties: {
    adminUserEnabled: false
  }
}

// ==================== Azure AI Foundry (Azure OpenAI) =======================
resource aiServices 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: aiName
  location: location
  kind: 'AIServices'
  sku: { name: 'S0' }
  identity: { type: 'SystemAssigned' }
  properties: {
    customSubDomainName: aiName
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: false
  }
}

resource chatDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
  parent: aiServices
  name: chatDeploymentName
  sku: { name: 'GlobalStandard', capacity: chatCapacity }
  properties: {
    model: { format: 'OpenAI', name: 'gpt-4o', version: chatModelVersion }
  }
}

resource embeddingDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
  parent: aiServices
  name: embeddingDeploymentName
  dependsOn: [ chatDeployment ]
  sku: { name: 'Standard', capacity: embeddingCapacity }
  properties: {
    model: { format: 'OpenAI', name: 'text-embedding-3-small', version: '1' }
  }
}

// ============== Azure Managed Redis (caché semántica, RediSearch) ===========
resource redis 'Microsoft.Cache/redisEnterprise@2024-10-01' = if (deploySemanticCache) {
  name: redisName
  location: location
  sku: { name: 'Balanced_B0' }
}

resource redisDb 'Microsoft.Cache/redisEnterprise/databases@2024-10-01' = if (deploySemanticCache) {
  parent: redis
  name: 'default'
  properties: {
    clientProtocol: 'Encrypted'
    port: 10000
    clusteringPolicy: 'EnterpriseCluster'
    evictionPolicy: 'NoEviction'
    modules: [ { name: 'RediSearch' } ]
  }
}

// =========================== AI Gateway (APIM) ==============================
resource apim 'Microsoft.ApiManagement/service@2024-05-01' = {
  name: apimName
  location: location
  sku: { name: 'Developer', capacity: 1 }
  identity: { type: 'SystemAssigned' }
  properties: {
    publisherEmail: apimPublisherEmail
    publisherName: apimPublisherName
  }
}

// APIM autenticado a Foundry con Managed Identity (keyless): rol Cognitive Services User
resource apimAoaiRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aiServices.id, apim.id, cognitiveServicesUserRoleId)
  scope: aiServices
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', cognitiveServicesUserRoleId)
    principalId: apim.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Logger + diagnóstico → Application Insights (verbosity information para las trazas de FinOps)
resource apimLogger 'Microsoft.ApiManagement/service/loggers@2024-05-01' = {
  parent: apim
  name: 'appinsights-logger'
  properties: {
    loggerType: 'applicationInsights'
    resourceId: appInsights.id
    credentials: {
      instrumentationKey: appInsights.properties.InstrumentationKey
    }
  }
}

resource apimDiagnostic 'Microsoft.ApiManagement/service/diagnostics@2024-05-01' = {
  parent: apim
  name: 'applicationinsights'
  properties: {
    loggerId: apimLogger.id
    alwaysLog: 'allErrors'
    sampling: { samplingType: 'fixed', percentage: 100 }
    verbosity: 'information'
    httpCorrelationProtocol: 'W3C'
  }
}

// Caché externa (Azure Managed Redis) para la caché semántica del gateway
resource apimCache 'Microsoft.ApiManagement/service/caches@2024-05-01' = if (deploySemanticCache) {
  parent: apim
  name: location
  properties: {
    connectionString: '${redis.properties.hostName}:10000,password=${redisDb.listKeys().primaryKey},ssl=True,abortConnect=False'
    useFromLocation: location
    description: 'Azure Managed Redis - caché semántica del AI Gateway'
  }
}

// Backends: chat (aoai) y embeddings (para la caché semántica)
resource backendAoai 'Microsoft.ApiManagement/service/backends@2024-05-01' = {
  parent: apim
  name: 'aoai-backend'
  properties: {
    protocol: 'http'
    url: aoaiBaseUrl
  }
}

resource backendEmbeddings 'Microsoft.ApiManagement/service/backends@2024-05-01' = {
  parent: apim
  name: 'embeddings-backend'
  properties: {
    protocol: 'http'
    url: embeddingsBackendUrl
  }
}

// ---- API Banca --------------------------------------------------------------
resource apiBanca 'Microsoft.ApiManagement/service/apis@2024-05-01' = {
  parent: apim
  name: 'banca'
  properties: {
    displayName: 'Banca AI Gateway'
    path: 'banca'
    protocols: [ 'https' ]
    subscriptionRequired: true
    serviceUrl: aoaiBaseUrl
    subscriptionKeyParameterNames: {
      header: 'Ocp-Apim-Subscription-Key'
      query: 'subscription-key'
    }
  }
}

resource opBanca 'Microsoft.ApiManagement/service/apis/operations@2024-05-01' = {
  parent: apiBanca
  name: 'chat-completions'
  properties: {
    displayName: 'Chat Completions'
    method: 'POST'
    urlTemplate: '/deployments/{deployment-id}/chat/completions'
    templateParameters: [
      { name: 'deployment-id', required: true, type: 'string' }
    ]
  }
}

resource apiBancaPolicy 'Microsoft.ApiManagement/service/apis/policies@2024-05-01' = {
  parent: apiBanca
  name: 'policy'
  dependsOn: [ backendAoai, backendEmbeddings, apimCache ]
  properties: {
    format: 'rawxml'
    value: loadTextContent('../banca-ai-demo/infra/apim-policy-core.xml')
  }
}

// ---- API Salud --------------------------------------------------------------
resource apiSalud 'Microsoft.ApiManagement/service/apis@2024-05-01' = {
  parent: apim
  name: 'salud'
  properties: {
    displayName: 'Salud AI Gateway'
    path: 'salud'
    protocols: [ 'https' ]
    subscriptionRequired: true
    serviceUrl: aoaiBaseUrl
    subscriptionKeyParameterNames: {
      header: 'Ocp-Apim-Subscription-Key'
      query: 'subscription-key'
    }
  }
}

resource opSalud 'Microsoft.ApiManagement/service/apis/operations@2024-05-01' = {
  parent: apiSalud
  name: 'chat-completions'
  properties: {
    displayName: 'Chat Completions'
    method: 'POST'
    urlTemplate: '/deployments/{deployment-id}/chat/completions'
    templateParameters: [
      { name: 'deployment-id', required: true, type: 'string' }
    ]
  }
}

resource apiSaludPolicy 'Microsoft.ApiManagement/service/apis/policies@2024-05-01' = {
  parent: apiSalud
  name: 'policy'
  dependsOn: [ backendAoai, backendEmbeddings, apimCache ]
  properties: {
    format: 'rawxml'
    value: loadTextContent('../salud-ai-demo/infra/apim-policy-core.xml')
  }
}

// ---- API Almex (Logística y Transporte) ------------------------------------
resource apiAlmex 'Microsoft.ApiManagement/service/apis@2024-05-01' = {
  parent: apim
  name: 'almex'
  properties: {
    displayName: 'Almex AI Gateway'
    path: 'almex'
    protocols: [ 'https' ]
    subscriptionRequired: true
    serviceUrl: aoaiBaseUrl
    subscriptionKeyParameterNames: {
      header: 'Ocp-Apim-Subscription-Key'
      query: 'subscription-key'
    }
  }
}

resource opAlmex 'Microsoft.ApiManagement/service/apis/operations@2024-05-01' = {
  parent: apiAlmex
  name: 'chat-completions'
  properties: {
    displayName: 'Chat Completions'
    method: 'POST'
    urlTemplate: '/deployments/{deployment-id}/chat/completions'
    templateParameters: [
      { name: 'deployment-id', required: true, type: 'string' }
    ]
  }
}

resource apiAlmexPolicy 'Microsoft.ApiManagement/service/apis/policies@2024-05-01' = {
  parent: apiAlmex
  name: 'policy'
  dependsOn: [ backendAoai, backendEmbeddings, apimCache ]
  properties: {
    format: 'rawxml'
    value: loadTextContent('../almex-ai-demo/infra/apim-policy-core.xml')
  }
}

// ---- API Bocar (Manufactura Automotriz) ------------------------------------
resource apiBocar 'Microsoft.ApiManagement/service/apis@2024-05-01' = {
  parent: apim
  name: 'bocar'
  properties: {
    displayName: 'Bocar AI Gateway'
    path: 'bocar'
    protocols: [ 'https' ]
    subscriptionRequired: true
    serviceUrl: aoaiBaseUrl
    subscriptionKeyParameterNames: {
      header: 'Ocp-Apim-Subscription-Key'
      query: 'subscription-key'
    }
  }
}

resource opBocar 'Microsoft.ApiManagement/service/apis/operations@2024-05-01' = {
  parent: apiBocar
  name: 'chat-completions'
  properties: {
    displayName: 'Chat Completions'
    method: 'POST'
    urlTemplate: '/deployments/{deployment-id}/chat/completions'
    templateParameters: [
      { name: 'deployment-id', required: true, type: 'string' }
    ]
  }
}

resource apiBocarPolicy 'Microsoft.ApiManagement/service/apis/policies@2024-05-01' = {
  parent: apiBocar
  name: 'policy'
  dependsOn: [ backendAoai, backendEmbeddings, apimCache ]
  properties: {
    format: 'rawxml'
    value: loadTextContent('../bocar-ai-demo/infra/apim-policy-core.xml')
  }
}

// ---- Productos (gobernanza por unidad de negocio) --------------------------
// (producto, apiId, policyFile) -> se genera producto + link + política + suscripción
var products = [
  { id: 'banca-retail',       display: 'Banca Retail',       api: 'banca', policy: loadTextContent('../banca-ai-demo/infra/apim-policy-product-retail.xml') }
  { id: 'banca-empresas',     display: 'Banca Empresas',     api: 'banca', policy: loadTextContent('../banca-ai-demo/infra/apim-policy-product-empresas.xml') }
  { id: 'salud-primaria',     display: 'Salud Atención Primaria', api: 'salud', policy: loadTextContent('../salud-ai-demo/infra/apim-policy-product-primaria.xml') }
  { id: 'salud-especialidad', display: 'Salud Especialidad', api: 'salud', policy: loadTextContent('../salud-ai-demo/infra/apim-policy-product-especialidad.xml') }
  { id: 'almex-clientes',     display: 'Almex Clientes (Autoservicio)', api: 'almex', policy: loadTextContent('../almex-ai-demo/infra/apim-policy-product-clientes.xml') }
  { id: 'almex-corporativo',  display: 'Almex Cuentas Corporativas', api: 'almex', policy: loadTextContent('../almex-ai-demo/infra/apim-policy-product-corporativo.xml') }
  { id: 'bocar-produccion',    display: 'Bocar Producción y Calidad', api: 'bocar', policy: loadTextContent('../bocar-ai-demo/infra/apim-policy-product-produccion.xml') }
  { id: 'bocar-mantenimiento', display: 'Bocar Mantenimiento Predictivo', api: 'bocar', policy: loadTextContent('../bocar-ai-demo/infra/apim-policy-product-mantenimiento.xml') }
  { id: 'bocar-cotizaciones',  display: 'Bocar Ingeniería y Cotizaciones', api: 'bocar', policy: loadTextContent('../bocar-ai-demo/infra/apim-policy-product-cotizaciones.xml') }
]

resource apimProducts 'Microsoft.ApiManagement/service/products@2024-05-01' = [for p in products: {
  parent: apim
  name: p.id
  properties: {
    displayName: p.display
    description: 'Producto de gobernanza para ${p.display}'
    subscriptionRequired: true
    approvalRequired: false
    state: 'published'
  }
}]

resource apimProductApis 'Microsoft.ApiManagement/service/products/apis@2024-05-01' = [for (p, i) in products: {
  name: '${apimName}/${p.id}/${p.api}'
  dependsOn: [ apimProducts[i], apiBanca, apiSalud, apiAlmex, apiBocar ]
}]

resource apimProductPolicies 'Microsoft.ApiManagement/service/products/policies@2024-05-01' = [for (p, i) in products: {
  name: '${apimName}/${p.id}/policy'
  dependsOn: [ apimProducts[i] ]
  properties: {
    format: 'rawxml'
    value: p.policy
  }
}]

resource apimSubscriptions 'Microsoft.ApiManagement/service/subscriptions@2024-05-01' = [for (p, i) in products: {
  name: '${apimName}/${p.id}'
  dependsOn: [ apimProducts[i] ]
  properties: {
    displayName: p.display
    scope: '${apim.id}/products/${p.id}'
    state: 'active'
  }
}]

// =========================== Container Apps =================================
resource acaEnv 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: acaEnvName
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: law.properties.customerId
        sharedKey: law.listKeys().primarySharedKey
      }
    }
  }
}

var gatewayUrl = 'https://${apimName}.azure-api.net'

resource bancaApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: bancaAppName
  location: location
  identity: { type: 'SystemAssigned' }
  tags: { 'azd-service-name': 'banca' }
  properties: {
    managedEnvironmentId: acaEnv.id
    configuration: {
      ingress: { external: true, targetPort: 8000, transport: 'auto' }
      registries: [ { server: acr.properties.loginServer, identity: 'system' } ]
      secrets: [
        { name: 'subkey-retail', value: apimSubscriptions[0].listSecrets().primaryKey }
        { name: 'subkey-empresas', value: apimSubscriptions[1].listSecrets().primaryKey }
      ]
    }
    template: {
      containers: [
        {
          name: 'web'
          image: bancaImage
          resources: { cpu: json('0.5'), memory: '1Gi' }
          env: [
            { name: 'APIM_GATEWAY_URL', value: gatewayUrl }
            { name: 'APIM_API_PATH', value: 'banca' }
            { name: 'MODEL_DEPLOYMENT', value: chatDeploymentName }
            { name: 'SUBKEY_RETAIL', secretRef: 'subkey-retail' }
            { name: 'SUBKEY_EMPRESAS', secretRef: 'subkey-empresas' }
          ]
        }
      ]
      scale: { minReplicas: 1, maxReplicas: 2 }
    }
  }
}

resource saludApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: saludAppName
  location: location
  identity: { type: 'SystemAssigned' }
  tags: { 'azd-service-name': 'salud' }
  properties: {
    managedEnvironmentId: acaEnv.id
    configuration: {
      ingress: { external: true, targetPort: 8000, transport: 'auto' }
      registries: [ { server: acr.properties.loginServer, identity: 'system' } ]
      secrets: [
        { name: 'subkey-primaria', value: apimSubscriptions[2].listSecrets().primaryKey }
        { name: 'subkey-especialidad', value: apimSubscriptions[3].listSecrets().primaryKey }
      ]
    }
    template: {
      containers: [
        {
          name: 'web'
          image: saludImage
          resources: { cpu: json('0.5'), memory: '1Gi' }
          env: [
            { name: 'APIM_GATEWAY_URL', value: gatewayUrl }
            { name: 'APIM_API_PATH', value: 'salud' }
            { name: 'MODEL_DEPLOYMENT', value: chatDeploymentName }
            { name: 'SEND_HISTORY', value: '0' }
            { name: 'SUBKEY_PRIMARIA', secretRef: 'subkey-primaria' }
            { name: 'SUBKEY_ESPECIALIDAD', secretRef: 'subkey-especialidad' }
          ]
        }
      ]
      scale: { minReplicas: 1, maxReplicas: 2 }
    }
  }
}

resource almexApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: almexAppName
  location: location
  identity: { type: 'SystemAssigned' }
  tags: { 'azd-service-name': 'almex' }
  properties: {
    managedEnvironmentId: acaEnv.id
    configuration: {
      ingress: { external: true, targetPort: 8000, transport: 'auto' }
      registries: [ { server: acr.properties.loginServer, identity: 'system' } ]
      secrets: [
        { name: 'subkey-clientes', value: apimSubscriptions[4].listSecrets().primaryKey }
        { name: 'subkey-corporativo', value: apimSubscriptions[5].listSecrets().primaryKey }
      ]
    }
    template: {
      containers: [
        {
          name: 'web'
          image: almexImage
          resources: { cpu: json('0.5'), memory: '1Gi' }
          env: [
            { name: 'APIM_GATEWAY_URL', value: gatewayUrl }
            { name: 'APIM_API_PATH', value: 'almex' }
            { name: 'MODEL_DEPLOYMENT', value: chatDeploymentName }
            { name: 'SEND_HISTORY', value: '0' }
            { name: 'SUBKEY_CLIENTES', secretRef: 'subkey-clientes' }
            { name: 'SUBKEY_CORPORATIVO', secretRef: 'subkey-corporativo' }
          ]
        }
      ]
      scale: { minReplicas: 1, maxReplicas: 2 }
    }
  }
}

resource bocarApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: bocarAppName
  location: location
  identity: { type: 'SystemAssigned' }
  tags: { 'azd-service-name': 'bocar' }
  properties: {
    managedEnvironmentId: acaEnv.id
    configuration: {
      ingress: { external: true, targetPort: 8000, transport: 'auto' }
      registries: [ { server: acr.properties.loginServer, identity: 'system' } ]
      secrets: [
        { name: 'subkey-produccion', value: apimSubscriptions[6].listSecrets().primaryKey }
        { name: 'subkey-mantenimiento', value: apimSubscriptions[7].listSecrets().primaryKey }
        { name: 'subkey-cotizaciones', value: apimSubscriptions[8].listSecrets().primaryKey }
      ]
    }
    template: {
      containers: [
        {
          name: 'web'
          image: bocarImage
          resources: { cpu: json('0.5'), memory: '1Gi' }
          env: [
            { name: 'APIM_GATEWAY_URL', value: gatewayUrl }
            { name: 'APIM_API_PATH', value: 'bocar' }
            { name: 'MODEL_DEPLOYMENT', value: chatDeploymentName }
            { name: 'SEND_HISTORY', value: '0' }
            { name: 'SUBKEY_PRODUCCION', secretRef: 'subkey-produccion' }
            { name: 'SUBKEY_MANTENIMIENTO', secretRef: 'subkey-mantenimiento' }
            { name: 'SUBKEY_COTIZACIONES', secretRef: 'subkey-cotizaciones' }
          ]
        }
      ]
      scale: { minReplicas: 1, maxReplicas: 2 }
    }
  }
}

// ACR pull (keyless) para las Container Apps
resource bancaAcrPull 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, bancaApp.id, acrPullRoleId)
  scope: acr
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', acrPullRoleId)
    principalId: bancaApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource saludAcrPull 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, saludApp.id, acrPullRoleId)
  scope: acr
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', acrPullRoleId)
    principalId: saludApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource almexAcrPull 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, almexApp.id, acrPullRoleId)
  scope: acr
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', acrPullRoleId)
    principalId: almexApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource bocarAcrPull 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, bocarApp.id, acrPullRoleId)
  scope: acr
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', acrPullRoleId)
    principalId: bocarApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// ============ One-click: construir imágenes reales y actualizar apps =========
resource uami 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = if (buildAppImages) {
  name: uamiName
  location: location
}

resource uamiContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (buildAppImages) {
  name: guid(resourceGroup().id, uamiName, contributorRoleId)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', contributorRoleId)
    principalId: uami.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource buildScript 'Microsoft.Resources/deploymentScripts@2023-08-01' = if (buildAppImages) {
  name: '${namePrefix}-build-${suffix}'
  location: location
  kind: 'AzureCLI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: { '${uami.id}': {} }
  }
  dependsOn: [ uamiContributor, bancaApp, saludApp, almexApp, bocarApp, bancaAcrPull, saludAcrPull, almexAcrPull, bocarAcrPull ]
  properties: {
    azCliVersion: '2.61.0'
    timeout: 'PT45M'
    retentionInterval: 'PT1H'
    cleanupPreference: 'OnSuccess'
    forceUpdateTag: deploymentTimestamp
    environmentVariables: [
      { name: 'ACR', value: acrName }
      { name: 'ACR_SERVER', value: acr.properties.loginServer }
      { name: 'RG', value: resourceGroup().name }
      { name: 'REPO', value: repoGitUrl }
      { name: 'BRANCH', value: repoBranch }
      { name: 'BANCA_APP', value: bancaAppName }
      { name: 'SALUD_APP', value: saludAppName }
      { name: 'ALMEX_APP', value: almexAppName }
      { name: 'BOCAR_APP', value: bocarAppName }
    ]
    scriptContent: '''
      set -e
      echo "Construyendo imagen de Banca..."
      az acr build --registry "$ACR" --image banca-web:latest "${REPO}#${BRANCH}:banca-ai-demo"
      echo "Construyendo imagen de Salud..."
      az acr build --registry "$ACR" --image salud-web:latest "${REPO}#${BRANCH}:salud-ai-demo"
      echo "Construyendo imagen de Almex..."
      az acr build --registry "$ACR" --image almex-web:latest "${REPO}#${BRANCH}:almex-ai-demo"
      echo "Construyendo imagen de Bocar..."
      az acr build --registry "$ACR" --image bocar-web:latest "${REPO}#${BRANCH}:bocar-ai-demo"
      echo "Actualizando Container Apps con las imágenes reales..."
      az containerapp update -g "$RG" -n "$BANCA_APP" --image "${ACR_SERVER}/banca-web:latest"
      az containerapp update -g "$RG" -n "$SALUD_APP" --image "${ACR_SERVER}/salud-web:latest"
      az containerapp update -g "$RG" -n "$ALMEX_APP" --image "${ACR_SERVER}/almex-web:latest"
      az containerapp update -g "$RG" -n "$BOCAR_APP" --image "${ACR_SERVER}/bocar-web:latest"
      echo "Listo."
    '''
  }
}

// ------------------------------ Salidas -------------------------------------
output aiGatewayUrl string = gatewayUrl
output apimName string = apimName
output appInsightsName string = appInsightsName
output acrLoginServer string = acr.properties.loginServer
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = acr.properties.loginServer
output AZURE_CONTAINER_REGISTRY_NAME string = acr.name
output bancaAppUrl string = 'https://${bancaApp.properties.configuration.ingress.fqdn}'
output saludAppUrl string = 'https://${saludApp.properties.configuration.ingress.fqdn}'
output almexAppUrl string = 'https://${almexApp.properties.configuration.ingress.fqdn}'
output bocarAppUrl string = 'https://${bocarApp.properties.configuration.ingress.fqdn}'
output foundryEndpoint string = aiServices.properties.endpoint
output resourceGroupName string = resourceGroup().name
output howToGetKeys string = 'az apim subscription show -g ${resourceGroup().name} --service-name ${apimName} --sid <banca-retail|banca-empresas|salud-primaria|salud-especialidad|almex-clientes|almex-corporativo|bocar-produccion|bocar-mantenimiento|bocar-cotizaciones> --query primaryKey -o tsv'
