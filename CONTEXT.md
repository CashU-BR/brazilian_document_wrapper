# CONTEXT.md

Domain reference for CPF and CNPJ, the two Brazilian taxpayer identifiers this gem
wraps. This is background knowledge that doesn't change with each PR — for *why* this
gem is built the way it is, see `docs/adr/`; for how to *use* the gem, see `README.md`.

## CPF — Cadastro de Pessoas Físicas

Identifies an individual (a natural person). Always 11 digits, always numeric — the
reform described below does not touch CPF.

```
XXX.XXX.XXX-VV
└─ 9 root digits ─┘└2 verify digits┘
```

The two verify digits are computed with a mod-11 checksum over the preceding digits
(weights `10..2` for the first, `11..2` for the second, applied left to right). Digit
sequences where all 11 digits are identical (`000.000.000-00`, `111.111.111-11`, ...)
are rejected even when they happen to satisfy the checksum arithmetically — the
Receita Federal never issues those.

## CNPJ — Cadastro Nacional da Pessoa Jurídica

Identifies a legal entity (a company or branch thereof). Always 14 characters.

```
XX.XXX.XXX/OOOO-VV
└── root (8) ──┘└ord(4)┘└DV(2)┘
```

- **Root (positions 1-8):** identifies the entity itself (what most people mean by "the
  CNPJ" informally, e.g. all branches of the same company share a root).
- **Order (positions 9-12):** identifies the establishment — `0001` is always the
  headquarters (*matriz*); `0002`, `0003`, ... are branches (*filiais*) of the same
  root.
- **Verify digits (positions 13-14):** always numeric, computed with a mod-11 checksum
  over the preceding 12 characters (see algorithm below).

### The alphanumeric CNPJ reform (IN RFB 2.229/2024)

Since **01/07/2026** the Receita Federal issues CNPJs where the root and order
(positions 1-12) may contain uppercase letters `A-Z` in addition to digits, on a
gradual rollout (large companies first, full cutover by 01/01/2027). The verify digits
(positions 13-14) always remain purely numeric. Existing numeric CNPJs stay valid and
immutable forever — **the two formats coexist indefinitely**, this is not a transition
period to design around as temporary.

From **06/07/2026**, electronic fiscal document environments (NF-e) also accept
alphanumeric CNPJ (NT Conjunta 2025.001), so the new format can arrive through any
integration that touches a Brazilian company's tax ID — not just direct user input.

A numeric CNPJ is simply the special case of the alphanumeric format where the root
happens to contain no letters — there is one validation/checksum algorithm, not two.

### Verify digit algorithm (mod 11, shared by CPF and CNPJ)

1. **Character → value:** each of the first 12 characters becomes `codepoint(char) -
   48`. `'0'..'9'` → `0..9` (identical to the legacy numeric-only calculation);
   `'A'..'Z'` → `17..42`.
2. **Weights:** cycle `2..9` from the *rightmost* character outward, wrapping back to 2
   after 9 (`weight = 2 + (i % 8)`, `i` = position counted from the right, 0-based).
   This single formula reproduces the legacy numeric CNPJ weight tables
   (`5 4 3 2 9 8 7 6 5 4 3 2` / `6 5 4 3 2 9 8 7 6 5 4 3 2`) as a special case — no
   separate code path needed for numeric vs. alphanumeric.
3. **DV1:** sum `value × weight` over all 12 characters; `remainder = sum % 11`. If
   `remainder < 2`, `DV1 = 0`; otherwise `DV1 = 11 - remainder`.
4. **DV2:** append `DV1` (13 characters now) and repeat steps 1-3.

CPF uses the same `remainder < 2 → 0, else 11 - remainder` rule, but with fixed
(non-cycling) weights `10..2` / `11..2`, since its root is short enough to never need
to wrap around.

### Key invariants

- Letters are **never** part of the mask — the display mask is punctuation only
  (`.`, `-`, `/`). A stray character outside `0-9A-Z` (accents, symbols, lowercase
  before normalization) must fail validation, not be silently stripped like a mask
  character would be. `gsub(/\D/, "")` — a common "clean this string" idiom — silently
  deletes the letters of an alphanumeric CNPJ; that's the sharpest edge of this reform
  for any codebase touching CNPJ.
- Letters are normalized to uppercase on input; lowercase is accepted but not
  canonical.
- All-identical-character sequences (`00.000.000/0000-00`, `AA.AAA.AAA/AAAA-AA`) are
  rejected outright, mirroring the CPF rule above.
- A branch's CNPJ (`branch(order_code)`) always shares its root with the headquarters
  (`order = '0001'`) — only the order changes, and the verify digits are recalculated
  for the new 12-character string.

## References

- Instrução Normativa RFB nº 2.229/2024 (institui o CNPJ alfanumérico).
- [Manual de Cálculo do DV do CNPJ Alfanumérico (SERPRO/RFB)](https://www.gov.br/receitafederal/pt-br/centrais-de-conteudo/publicacoes/documentos-tecnicos/cnpj)
- [Página oficial do projeto CNPJ Alfanumérico](https://www.gov.br/receitafederal/pt-br/acesso-a-informacao/acoes-e-programas/programas-e-atividades/cnpj-alfanumerico)
- NT Conjunta nº 2025.001 (documentos fiscais eletrônicos).
