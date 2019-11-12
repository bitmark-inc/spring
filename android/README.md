# Bitmark Synergy Application

The Bitmark Synergy application for helping Social Network Users Reclaim Rights to Personal Data

## Getting Started

#### Prequisites

- Java 8
- Android 6.0 (API 23)

#### Preinstallation

Create `.properties` file for the configuration
- `sentry.properties` : uploading the Proguard mapping file to Sentry
```xml
defaults.project=bitmark-registry
defaults.org=bitmark-inc
auth.token=SentryAuthToken
```
- `key.properties` : API key configuration
```xml
api.key.bitmark=BitmarkSdkApiKey
api.key.intercom=IntercomApiKey
```
- `app/src/main/resources/sentry.properties` : Configuration for Sentry
```xml
dsn=SentryDSN
buffer.dir=sentry-events
buffer.size=100
async=true
async.queuesize=100
```
- `app/fabric.properties` : Configuration for Fabric distribution
```xml
apiSecret=FabricSecretKey
apiKey=FabricApiKey
```

Create `distribution` directory for distribution configuration
- release_note.txt : Release note for distribution
- testers.txt : list email of testers, separate by a comma

Add `release.keystore` and `release.properties` for releasing as production

#### Installing

`./gradlew clean fillSecretKey assembleInhouseDebug`

Using `-PsplitApks` to build split APKs

## Deployment
The debug build is distributed via ***Fabric Beta***

`./gradew crashlyticsUploadDistributionInhouseDebug`
