# DUO MESH Art Key — состояние на 2026-06-07

## 1. Что построено

Art Key — это цифровой сертификат подлинности для произведений искусства. Каждый сертификат содержит криптографически верифицируемую цепочку владения (provenance) с подписями Ed25519. Верификация работает офлайн: проверяющему не нужен доступ к серверу DUO MESH — только открытые ключи REGISTRY и PLATFORM.

### 1.1. Архитектура доверия (трёхуровневая)

```
Уровень 0 — REGISTRY (trust anchor)
  Глобальный ключ Ed25519, задаётся через env-переменные.
  Подписывает attestation — связку {artistId, artistPublicKey, artworkId}.
  Поддерживает ротацию (multi-key через kid).
  Формат: PEM/base64, Node crypto.

Уровень 1 — ARTIST
  Персональный ключ Ed25519 на каждого художника.
  Генерируется при онбординге. Приватный ключ шифрован в KeyStore (AES-256-GCM).
  Подписывает genesis-запись цепочки владения.
  Формат: hex raw, Web Crypto.

Уровень 2 — PLATFORM
  Ключ платформы DUO MESH. Создаётся при первом запуске.
  Совместно подписывает genesis (co-signature).
  Формат: hex raw, Web Crypto.
```

### 1.2. Структура сертификата (ArtKey)

| Поле | Назначение |
|---|---|
| `keyCode` | Публичный идентификатор: `DUO-2026-XXXXXXXX` |
| `ownerKey` | Код владельца: `X0000-0000` |
| `integrityHash` | SHA-256 контента artwork (файлы постера/модели) |
| `certificateHash` | SHA-256 метаданных сертификата |
| `platformSignature` | Ed25519-подпись платформы на genesis-payload |
| `issuedAt` | Дата выпуска сертификата |
| `timestampToken` | RFC 3161 timestamp (опционально) |

### 1.3. Цепочка владения (ProvenanceRecord)

Каждая запись в цепочке:

| Поле | Назначение |
|---|---|
| `sequence` | Порядковый номер (0 = genesis) |
| `transferType` | CREATION / PRIMARY_SALE / SECONDARY_SALE / GIFT / INHERITANCE / TRANSFER |
| `recordHash` | SHA-256 канонического JSON записи |
| `prevRecordHash` | Хеш предыдущей записи (образует hash chain) |
| `signature` | Ed25519-подпись на recordHash |
| `signerRole` | ARTIST / PLATFORM / REGISTRY |
| `signingKeyId` | ID ключа подписанта в таблице SigningKey |
| `registryKeyId` | kid REGISTRY-ключа (для multi-key резолва) |
| `occurredAt` | Временная метка события (задаётся приложением, **не** БД) |

## 2. Модель безопасности: ключевые инварианты

### 2.1. Каноническая реконструкция хеша
Функция `payloadFromRecord()` — **единственный** builder, который и mint, и verify используют для построения payload из строки БД. Исключает рассинхрон «подписали одну форму — проверили другую».

### 2.2. Хеш-колонка occurredAt
Выделенная колонка `occurred_at` **без `@default(now())`** — всегда задаётся приложением явно. `created_at` остаётся метаданными БД и в хеше НЕ участвует. Предотвращает рассинхрон app-Date vs db-now().

### 2.3. Доверенный резолв ключа (не из записи)
Verify **никогда** не доверяет `signerPublicKey` из проверяемой записи. Для ARTIST/PLATFORM ключ резолвится из таблицы SigningKey по `signingKeyId`. Для REGISTRY — multi-key резолв по `registryKeyId` с fallback на env-ключ.

### 2.4. Artist-binding авторизация
Для ARTIST-подписанных записей: `keyInfo.ownerId === artwork.artistId`. Атакующий с валидным ключом другого художника не может подписать genesis чужой работы.

### 2.5. Anti-transplant защита
RegistryAttestation привязана к конкретному `artworkId`. Attestation artworkId сверяется с artworkId цепочки. Нельзя перенести аттестацию на другую работу.

### 2.6. Fail-closed
Любое исключение в криптографических операциях (битый PEM, невалидный формат ключа) → `verified = false` с логированием.

### 2.7. Двухфазный INSERT+UPDATE
Минт трансфера: фаза 1 — INSERT с заглушкой `recordHash: ''`, фаза 2 — `payloadFromRecord(inserted)` → hash → sign → UPDATE. Хеш всегда вычисляется из сохранённой строки, а не из параметров до INSERT.

## 3. Что починено (хронология багов)

### 3.1. Mesh Poem — рассинхрон хеша (P0, исправлен)
**Симптом**: сертификат `DUO-2026-86AA8502`, seq=1 — `verified: false`.
**Причина**: минт вычислял хеш с `new Date().toISOString()` (28 мс до INSERT), а `@default(now())` в БД проставил другой `createdAt`. Verify реконструировал из `createdAt` → другой хеш.
**Фикс**: (а) конкретная запись перехеширована и переподписана PLATFORM-ключом; (б) mint теперь явно проставляет временную метку до INSERT.

### 3.2. Структурный фикс: occurredAt (P0, сделано)
**Проблема**: `@default(now())` на `createdAt` — бомба замедленного действия для любого будущего трансфера.
**Решение**: выделенная колонка `occurredAt` без `@default`. 53 строки забэкфилены: `occurred_at = created_at`. `payloadFromRecord` читает `occurredAt`, не `createdAt`.

### 3.3. Дедупликация payload-билдера (P0, сделано)
**Проблема**: backfill-скрипт имел свою копию `buildPayload()`. Verify имел inline-построение payload.
**Решение**: единственная функция `payloadFromRecord()` в `signing.service.ts`. И backfill, и mint, и verify используют её.

### 3.4. Удаление мёртвого кода (сделано)
Файлы `provenance-signing.ts` и `provenance.ts` удалены. Ноль вызовов, приглашение к багам.

### 3.5. Flaky-тест и round-trip (сделано)
**Проблема**: tamper-тест создавал два разных `new Date()` для payload и mock record → недетерминированный хеш в ~30% запусков.
**Фикс**: единый `Date` объект в моке + round-trip тест через реальную БД. Round-trip сразу поймал пропущенный `recordHash` в фазе 1 INSERT (required поле, моки пропускали).

## 4. Текущий статус продакшена

| Показатель | Значение |
|---|---|
| Всего ProvenanceRecord | 53 |
| Подписано REGISTRY | 53/53 |
| Platform co-signature на ArtKey | 39/39 |
| Hash check (verify) | 53/53 match |
| API verify endpoint | 39/39 verified |
| Backfill-скрипт | 0 неподписанных записей |

## 5. Тестовое покрытие

| Файл | Кол-во | Что покрывает |
|---|---|---|
| `art-key.service.tamper.test.ts` | 12 | Полный tamper-матрикс: подмена байта, key substitution, unauthorized artist, fail-closed, platform co-sig forgery, attestation checks |
| `provenance-transfer.roundtrip.test.ts` | 2 | INSERT → reload → verify через реальную БД. Ловит рассинхрон occurredAt и пропущенные required-поля |
| `crypto/tamper.test.ts` | 10+ | Офлайн-верификатор: data tamper, re-chain, reorder, deletion, signature flip, attestation attacks |

Все тесты используют **настоящую крипту** (Ed25519 через Node crypto / Web Crypto), не моки.

## 6. Что готово для маркетологов

### Можно передавать прямо сейчас:
- **Верификация через веб**: страница `/verify/DUO-2026-XXXXXXXX` показывает полную цепочку владения, статус подлинности, историю переходов
- **PDF-сертификат**: endpoint `/:keyCode/certificate.pdf` — скачиваемый сертификат подлинности с QR-кодом
- **Офлайн-верификация**: endpoint `/:keyCode/export` — самодостаточный бандл для проверки без доступа к серверу
- **Публичный transparency log**: append-only аудит-лог всех событий

### Честные гарантии, которые можно писать в маркетинге:
1. «Подлинность контента доказана криптографически» — integrityHash от файлов
2. «Цепочка владения защищена от подделки» — Ed25519 + hash chain
3. «Сертификат можно проверить самостоятельно» — офлайн-верификатор с открытым кодом
4. «Никто не может подделать сертификат художника» — artist-binding + key resolution

### Ограничения (что НЕЛЬЗЯ обещать):
1. «Блокчейн» — это не блокчейн. Это Ed25519-подписи + hash chain. Технически честнее и эффективнее.
2. «Децентрализованная верификация» — пока trust anchor один (REGISTRY), модель custodial.
3. «Невозможно отозвать без согласия художника» — админ может revoke.

## 7. Что осталось (P1/P2)

### P1 — можно жить, но желательно до маркетинга:

| Задача | Статус |
|---|---|
| Дедупликация `buildStandardPayload` в `scripts/backfill-signatures.ts` | Есть своя копия, надо импортировать `payloadFromRecord` |
| RFC 3161 timestamp: full verification | TSA-сертификат не пинится, проверка формальная |
| KeyStore: миграция с файлового на HSM/Vault | Пока JSON-файл, зашифрованный AES-256-GCM |
| Revocation: проверка в verify | Поле `revokedAt` есть, логика проверки есть |

### P2 — на будущее:

| Задача | Описание |
|---|---|
| Multi-REGISTRY trust anchor | Несколько независимых REGISTRY-ключей (разные организации) |
| Ledger-интеграция | Хеш цепочки → публичный блокчейн для внешнего аудита |
| Webhook на смену владельца | Нотификации при transfer |
| Artist key recovery | Восстановление ключа художника (сейчас: утерян = новый ключ) |

## 8. Как проверить сертификат (пользовательский путь)

1. Открыть `https://duomesh.art/verify/DUO-2026-XXXXXXXX`
2. Страница показывает:
   - Название работы, художник, год
   - Статус: «Подлинность подтверждена» / «Сертификат недействителен»
   - Цепочку владения: кто → кому, когда, тип передачи
   - Хеши и подписи (сворачиваемые для нефаховых пользователей)
3. QR-код на сертификате ведёт на ту же страницу
4. Технический пользователь может скачать export-бандл и проверить офлайн

## 9. Карта файлов

```
backend/
├── prisma/schema.prisma              # Модели: ArtKey, ProvenanceRecord, SigningKey, RegistryAttestation
├── src/
│   ├── crypto/
│   │   ├── canonical.ts              # canonicalJSON() — детерминированная сериализация
│   │   ├── hash.ts                   # sha256Hex(), compositeFileHash(), hashPayload()
│   │   ├── keys.ts                   # Генерация Ed25519 (Web Crypto)
│   │   ├── keystore.ts               # KeyStore — шифрованное хранение приватных ключей
│   │   ├── sign.ts                   # signPayload(), signDigest(), signCanonicalJson()
│   │   ├── verify.ts                 # verifyProvenanceSignature(), verifyDigest()
│   │   └── timestamp.ts              # RFC 3161 TSP-клиент
│   ├── services/
│   │   ├── signing.service.ts        # payloadFromRecord(), SigningService (управление ключами + подпись)
│   │   ├── art-key.service.ts        # ArtKeyService: mint (generate) + verify
│   │   ├── provenance-transfer.service.ts  # Создание transfer-записей (двухфазный INSERT+UPDATE)
│   │   ├── art-key.service.tamper.test.ts   # 12 tamper-тестов боевого verify
│   │   └── provenance-transfer.roundtrip.test.ts  # 2 round-trip теста через реальную БД
│   ├── routes/
│   │   └── art-keys.ts               # GET /:keyCode, PDF, export, revoke
│   └── generated/prisma/             # Сгенерированный Prisma-клиент
├── backfill-registry-signatures.ts   # Бэкфилл-скрипт REGISTRY-подписей
└── scripts/backfill-signatures.ts    # Старый бэкфилл (нуждается в дедупликации)
```

## 10. Рекомендация тимлиду

**Фаза 0 (сейчас)**: можно передавать маркетологам. Верификация работает, 39 сертификатов подтверждены, тесты зелёные. Ключевые баги починены структурно.

**Фаза 1 (до маркетинговой кампании)**: дедуплицировать `scripts/backfill-signatures.ts`, допилить timestamp-верификацию, протестировать с реальными художниками (не Daria Lys).

**Фаза 2 (перед открытием платформы)**: миграция KeyStore на HSM/Vault, multi-REGISTRY trust anchor, webhook-нотификации.

**Фаза 3 (масштабирование)**: ledger-интеграция, artist key recovery, публичный мониторинг сертификатов.
