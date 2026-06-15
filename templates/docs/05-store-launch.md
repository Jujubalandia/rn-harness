# 05 — Store Launch Checklist

> Fase: D14-D17 | Skill: `store-metadata-reviewer` (subagente antes de submeter)

---

## Assets Necessários (criar em D13)

| Asset | App Store | Play Store |
|-------|----------|-----------|
| Ícone | 1024x1024 PNG (sem alpha) | 512x512 PNG |
| Feature graphic | — | 1024x500 PNG |
| Screenshots phone | 6.9" (1320x2868) obrigatório | 16:9 ou 9:16 |
| Screenshots tablet | iPad Pro 12.9" (opcional mas recomendado) | 7" tablet (opcional) |
| Preview video | Opcional (MP4, 15-30s) | Opcional |

**Quantidade de screenshots:** mínimo 3, ideal 5-8. Mostrar o fluxo principal.

Ferramenta: `react-native-view-shot` + Figma/Canva para moldura de device.

---

## Metadata

### App Store (limites rígidos)

| Campo | Limite | Dica |
|-------|--------|------|
| Nome | 30 chars | Inclua 1-2 keywords |
| Subtítulo | 30 chars | Diferencial em 1 linha |
| Descrição | 4000 chars | Primeiras 3 linhas são o que aparece sem "Ver mais" |
| Keywords | 100 chars total | Separar por vírgula, sem espaço |
| URL de suporte | obrigatório | GitHub Pages ou link simples |
| Privacy policy | obrigatório | Pode ser hosted no GitHub |

### Google Play (limites diferentes)

| Campo | Limite | Dica |
|-------|--------|------|
| Título | 50 chars | Mais flexível que App Store |
| Descrição curta | 80 chars | Aparece nos resultados de busca |
| Descrição completa | 4000 chars | Pode usar emojis com moderação |
| Tags | 5 tags | Escolher categoria + subcategoria |

---

## Privacy Policy (obrigatório em ambas)

Gerar em: `app-privacy-policy-generator.firebaseapp.com` (grátis)

Hospedar em: GitHub Pages ou `{{APP_DOMAIN}}/privacy`

Incluir:
- Dados coletados (email, nome, uso)
- Como são usados
- Terceiros (Supabase, Google Analytics se usar)
- Contato para deleção de conta

---

## Checklist Pré-Submissão

### Google Play (AAB)

```bash
eas build --platform android --profile production
# Aguardar build → download .aab
# Upload no Google Play Console → Internal testing → Production
```

- [ ] App assinado com keystore de produção (NÃO debug keystore)
- [ ] `versionCode` incrementado
- [ ] `targetSdkVersion` ≥ 34 (requisito 2024+)
- [ ] Declaração de anúncios (se usar AdMob)
- [ ] Data safety form preenchida
- [ ] Age rating questionnaire respondido
- [ ] Content rating preenchido

### App Store (IPA via EAS)

```bash
eas build --platform ios --profile production
eas submit --platform ios  # ou upload manual via Transporter
```

- [ ] Bundle ID correto (com.{{COMPANY}}.{{APP_SLUG}})
- [ ] `CFBundleVersion` incrementado
- [ ] Provisioning profiles válidos (Distribution, não Development)
- [ ] Export compliance (se usar criptografia → `ITSAppUsesNonExemptEncryption = NO` para a maioria)
- [ ] Age rating questionnaire respondido
- [ ] App Review Information: conta de teste criada e credenciais preenchidas no App Store Connect
- [ ] Notes para o revisor: explicar qualquer fluxo não-óbvio

---

## Erros comuns de rejeição

| Motivo | Solução |
|--------|---------|
| App Store: "funcionalidade limitada" | Garantir que guest mode funciona ou remover paywall na 1ª tela |
| App Store: missing privacy manifest | Adicionar `PrivacyInfo.xcprivacy` no Expo config |
| Play: targetSdkVersion desatualizado | `compileSdkVersion 34` no `build.gradle` |
| Play: conteúdo gerado por usuário | Adicionar botão de report + política de moderação |
| Ambas: crash na review | Garantir que conta de teste funciona com os dados de review |

---

## Após aprovação

- [ ] Registrar versão + data + número de build no `DECISIONS.md`
- [ ] Ativar lançamento gradual (10% → 50% → 100%) no Play Store
- [ ] App Store: lançamento manual ou automático após aprovação
- [ ] Iniciar fase D18-D20 (marketing)
