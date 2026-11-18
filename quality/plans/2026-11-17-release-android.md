# Preparação de release Android — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:executing-plans` or `superpowers:subagent-driven-development` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Preparar o app Android para gerar um artefato de release com identificador definitivo e assinatura controlada com segurança.

**Architecture:** Resolver decisões de identidade e propriedade da chave antes de alterar configuração. Guardar segredos fora do Git e fazer o build de release falhar claramente quando a assinatura não estiver configurada; manter o build de debug independente.

**Tech Stack:** Flutter/Dart, Gradle Kotlin DSL em `frontend/android/app/build.gradle.kts`, Android SDK/Build Tools instalados.

**Spec:** `quality/backlog.md` e TODOs atuais em `frontend/android/app/build.gradle.kts`.

## Global Constraints

- O `applicationId` atual é `com.example.game_match` e `namespace` também é provisório; não escolher identificador final sem confirmação do proprietário do app.
- O build release atual assina com a chave debug; não distribuir esse artefato como release.
- Nunca commitar keystore, senhas, tokens ou propriedades locais secretas.
- Não publicar nem distribuir artefatos como parte deste plano.
- Manter builds de debug funcionando sem exigir credenciais de release.

## Review Focus

- `applicationId` e `namespace` precisam refletir decisão explícita e ser consistentes antes de distribuição.
- Ausência de credenciais de assinatura deve falhar de forma clara no release, sem fallback silencioso para assinatura debug.
- Segredos e keystore não podem aparecer no diff, logs ou artefatos versionados.
- Configuração de release não deve quebrar `flutter run`/build debug.
- O artefato final deve ter assinatura verificável e versão coerente com `pubspec.yaml`.

---

### Task 1: Resolver identidade e propriedade da assinatura

**Files:**
- Inspect: `frontend/android/app/build.gradle.kts`
- Inspect: `frontend/pubspec.yaml`
- Modify: `quality/backlog.md` and this plan only after decisions are confirmed

- [ ] **Step 1: Confirmar identificador Android definitivo e se também deve atualizar o namespace.**
- [ ] **Step 2: Confirmar proprietário da chave de release e onde será armazenada/fornecida; não solicitar nem registrar segredo no repositório.**
- [ ] **Step 3: Confirmar formato de distribuição pretendido (APK, AAB ou ambos) antes de implementar configuração de build.**

### Task 2: Configurar assinatura segura de release

**Files:**
- Modify: `frontend/android/app/build.gradle.kts`
- Modify if necessary: `frontend/android/.gitignore` ou `.gitignore` raiz
- Document: instruções locais de build Android

- [ ] **Step 1: Adicionar leitura de parâmetros de assinatura a partir de fonte local não versionada ou variáveis de ambiente definidas pelo ambiente de build.**
- [ ] **Step 2: Configurar `signingConfig` de release com esses parâmetros; remover fallback para chave debug no release.**
- [ ] **Step 3: Fazer release falhar com mensagem acionável se valores obrigatórios estiverem ausentes, preservando build debug sem esses valores.**
- [ ] **Step 4: Verificar `git status` e regras de ignore para assegurar que keystore e arquivos secretos não são rastreados.**

### Task 3: Validar artefato sem publicar

**Files:**
- Verify: `frontend/android/app/build.gradle.kts`
- Verify: `frontend/pubspec.yaml`
- Update: documentação de build Android

- [ ] **Step 1: Executar build debug e confirmar que não depende de segredo de release.**
- [ ] **Step 2: Com credenciais fornecidas pelo responsável fora do repositório, executar o build de release acordado (`flutter build appbundle --release` e/ou `flutter build apk --release`).**
- [ ] **Step 3: Verificar que o artefato foi assinado com o certificado esperado usando ferramentas Android instaladas.**
- [ ] **Step 4: Não publicar o artefato; registrar apenas comandos, localização local e resultado sem expor segredos.**

### Task 4: Atualizar estado e revisar

**Files:**
- Modify: `quality/backlog.md`
- Modify if needed: `quality/test-inventory.md`

- [ ] **Step 1: Marcar decisões e configuração concluídas, preservando no backlog qualquer decisão ainda pendente.**
- [ ] **Step 2: Revisar diff para segredos e executar verificações Android acordadas.**
- [ ] **Step 3: Solicitar revisão do Code Reviewer antes de considerar a preparação concluída.**
