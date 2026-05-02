# Firestore сийд (PA Style Studio)

## Задължително: правила (иначе запис на час няма да мине)

От папката `barbershop_app` (където е `firebase.json`):

```bash
firebase login
firebase use <твоят-project-id>
firebase deploy --only firestore
```

(Това качва **`firestore.rules`** и **`firestore.indexes.json`** — без индекси заявките за график може да върнат грешка в конзолата.)

---

Попълва колекциите, които приложението очаква:

| Колекция / път | Съдържание |
|----------------|------------|
| `salon/main` | Метаданни за салона (по избор) |
| `services` | Услуги: `nameBg`, `price`, `durationMinutes` |
| `barberProducts` | Фризьори като продукт: `nameBg`, `imageUrl`, `sortOrder` |
| `barberProducts/{id}/blockedSlots` | *(създава се от приложението)* Блокирани часове за този фризьор |

За заявки по записи Firestore може да поиска **композитен индекс** на колекция `appointments`: полета `barberProductId` (Ascending) + `startAt` (Ascending).

Данните са в **`seed-data.json`** — редактирай ги според салона.

## Пускане

1. Инсталирай зависимости (еднократно):

   ```bash
   cd scripts/firestore-seed
   npm install
   ```

2. **Project id** се намира автоматично от `barbershop_app/barbershop_app/lib/firebase_options.dart`.  
   Ако скриптът не го намира, задай:
   - CMD: `set FIREBASE_PROJECT_ID=pa-style-barbershop`  
   - PowerShell: `$env:FIREBASE_PROJECT_ID="pa-style-barbershop"`  
   или  
   - копирай `seed.config.example.json` → **`seed.config.json`** и поправи `projectId`.

3. Сервизен акаунт (препоръчително):
   - Firebase Console → Project settings → **Service accounts** → **Generate new private key**
   - Запази JSON като **`serviceAccountKey.json`** в `firestore-seed`  
     *(в `.gitignore` — не го качвай в git)*  

   Без този файл скриптът ползва *Application Default Credentials* — на Windows често липсва project id или права; **`serviceAccountKey.json` е най-сигурният вариант.**

4. Изпълни:

   ```bash
   npm run seed
   ```

**Алтернатива:** сложи пътя към ключа в променлива `GOOGLE_APPLICATION_CREDENTIALS` и махни локалния `serviceAccountKey.json` — скриптът ще ползва *Application Default Credentials*.

## Грешка `5 NOT_FOUND` при `npm run seed`

Почти винаги означава, че в този Firebase проект **още няма създадена Firestore база**.

В [Firebase Console](https://console.firebase.google.com) → твоят проект → **Build** → **Firestore Database** → **Create database** (Native mode, избери регион). После пак `npm run seed`.

Провери и дали `project_id` в `serviceAccountKey.json` е **същият** проект, в който ползваш приложението (`firebase_options.dart`).

## Бележки

- Снимките в сийда са от Unsplash (публични URL); смени ги с твои линкове от Firebase Storage при желание.
- Не пипа `appointments` и `profiles` — те са за реални потребители и записи.
- Повторно пускане прави **merge** върху същите document ID-та.
