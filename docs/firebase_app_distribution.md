# Firebase App Distribution

Configuracao pronta para distribuir builds Android e iOS usando o Firebase CLI.

## Regra de ambiente

Os scripts de App Distribution agora forcam `APP_ENV=prod` por padrao.

Isso significa que toda build publicada por:

- `scripts/distribute_android.sh`
- `scripts/distribute_ios.sh`

vai apontar para a API de producao, mesmo que o projeto use `dev` por padrao no ambiente local.

Base padrao de producao:

```text
https://tmjapp-api-53m7i55c3q-rj.a.run.app/api/
```

Se voce precisar sobrescrever temporariamente a URL em uma distribuicao, pode informar:

```bash
API_BASE_URL="https://sua-url/api/" ./scripts/distribute_android.sh
```

## Pre-requisitos

- `flutter` no PATH
- `firebase-tools` no PATH
- login no Firebase CLI:

```bash
firebase login
```

- projeto Firebase configurado em `firebase.json`

## Android

O projeto agora aceita assinatura release por `android/key.properties` ou por variaveis de ambiente:

- `ANDROID_KEYSTORE_PATH`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

Exemplo de arquivo:

```properties
storePassword=change-me
keyPassword=change-me
keyAlias=upload
storeFile=/absolute/path/to/your-upload-keystore.jks
```

Template:

- `android/key.properties.example`

### Distribuir APK

```bash
cd tmjappdrive
GROUPS="android-testers" RELEASE_NOTES="Build de homologacao" ./scripts/distribute_android.sh
```

### Distribuir AAB

```bash
cd tmjappdrive
ARTIFACT_TYPE=aab GROUPS="android-testers" ./scripts/distribute_android.sh
```

## iOS

Para iOS, o build exige assinatura Apple valida no ambiente local. Se voce usa export options customizado, informe:

- `EXPORT_OPTIONS_PLIST=/absolute/path/to/ExportOptions.plist`

### Distribuir IPA

```bash
cd tmjappdrive
GROUPS="ios-testers" RELEASE_NOTES="Build de homologacao" ./scripts/distribute_ios.sh
```

## Variaveis opcionais

- `BUILD_NAME`
- `BUILD_NUMBER`
- `TESTERS`
- `GROUPS`
- `RELEASE_NOTES`
- `RELEASE_NOTES_FILE`
- `ANDROID_FIREBASE_APP_ID`
- `IOS_FIREBASE_APP_ID`
- `APP_ENV`
- `API_BASE_URL`

Os App IDs sao lidos automaticamente de `firebase.json` quando nao forem informados.

## Scripts

- `scripts/distribute_android.sh`
- `scripts/distribute_ios.sh`
