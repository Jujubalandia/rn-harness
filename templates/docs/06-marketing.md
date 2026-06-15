# 06 — Marketing Launch

> Fase: D17-D20 | Skills: `marketing-copywriter`, `viral-content-strategist`

---

## Calendário D-7 a D+14

| Dia | Ação | Plataforma | Status |
|-----|------|-----------|--------|
| D-7 | Teaser "em breve" + waitlist | Instagram + Twitter | [ ] |
| D-5 | Behind the scenes (dev diary) | TikTok / Reels | [ ] |
| D-3 | Screenshots + feature highlight | Instagram carousel | [ ] |
| D-1 | "Amanhã" countdown | Todos os canais | [ ] |
| **D0** | **LAUNCH POST** | Reddit + PH + todos | [ ] |
| D+1 | Responder comentários + DMs | Reddit + Twitter | [ ] |
| D+3 | "Primeiros X usuários" update | Instagram Stories | [ ] |
| D+7 | Métricas D+7 (transparência gera confiança) | Twitter / LinkedIn | [ ] |
| D+14 | Feature destaque / use case real | Todos os canais | [ ] |

---

## Por Plataforma

### Reddit

**Regra:** contribuir antes de promover. Nunca primeiro post = spam do app.

- Postar em 2-3 subreddits relevantes (`r/{{CATEGORIA}}`, `r/{{NICHO}}`)
- Título: "I built [X] to solve [problema que os usuários do subreddit têm]"
- Primeiro parágrafo: o problema, não o app
- Link para app no final ou nos comentários se perguntarem
- Responder TODOS os comentários nas primeiras 24h

Usar `marketing-copywriter` para adaptar o post para cada subreddit.

### Product Hunt

- Criar listing em `producthunt.com` (free)
- Lançar terça ou quarta (mais tráfego)
- Prepare: tagline 60 chars, descrição, GIF do app em ação
- Pedir upvotes apenas para pessoas que realmente usaram o app

### Instagram / TikTok

Formatos que funcionam para apps:
1. Screen recording do fluxo principal (30s)
2. "Antes e depois" do problema que o app resolve
3. Bastidores do desenvolvimento (gera conexão)
4. Tutorial rápido de uma feature

### Twitter/X

- Thread de lançamento: problema → solução → como usar → link
- Engajar em conversas sobre o problema (não sobre o app)

---

## Landing Page (mínima, mas necessária)

Estrutura em 1 página:

```
[HERO]
  Headline: {{DIFERENCIAL_UMA_LINHA}}
  Sub: {{PROBLEMA_QUE_RESOLVE}}
  CTA: [Baixar na App Store] [Baixar no Google Play]
  Screenshot/GIF do app

[FEATURES] (3 máximo)
  Feature 1 + ícone + 1 linha de descrição
  Feature 2 + ícone + 1 linha de descrição
  Feature 3 + ícone + 1 linha de descrição

[SOCIAL PROOF]
  "X usuários em X dias" (quando tiver)
  Screenshots de reviews/tweets positivos

[CTA FINAL]
  [Baixar grátis]
  Link de privacidade
```

**Hosting gratuito:** GitHub Pages, Vercel, ou Netlify.
**Builder rápido:** Carrd ($9/ano) se não quiser codar.

---

## Copy Templates

> Preencher com `marketing-copywriter` subagente para cada plataforma.

### Template Reddit (PT-BR)

```
Título: Construí um app para [PROBLEMA] — grátis, sem cadastro obrigatório

[PARÁGRAFO 1: o problema, na linguagem do subreddit]

[PARÁGRAFO 2: como o app resolve, foco no benefício não na feature]

[LINK PARA APP - Play Store e App Store]

Feedback bem-vindo — especialmente sobre [ASPECTO ESPECÍFICO].
```

### Template Product Hunt tagline

```
{{APP_NAME}} — {{DIFERENCIAL}} para {{PUBLICO}}
```
Max 60 chars. Sem ponto final. Sem "o melhor".

---

## Métricas D+7 (registrar no DECISIONS.md)

| Métrica | Alvo | Real |
|---------|------|------|
| Downloads totais | {{META}} | |
| Retention D1 | > 30% | |
| Retention D7 | > 15% | |
| Rating médio | > 4.0 | |
| Reviews | > 5 | |
| Shares (se rastreável) | | |

Se D+7 abaixo do alvo → analisar funnel antes de investir mais em marketing.
