# AskMyGPT 💬

<a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License: MIT"></a> <!-- Замените, если лицензия другая -->
<a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.x-blue.svg" alt="Flutter Version"></a> <!-- Укажите вашу версию Flutter -->
<!-- Добавьте другие бейджи, если нужно (например, статус сборки) -->

**_Сайт-визитка_**  -  **https://zelt-dev.github.io/AskMyGPT/**

**Кроссплатформенное чат-приложение для взаимодействия с AI-моделями.**

**Разработано в рамках курса "Технологии программирования"**
**Международный университет МИТСО, Кафедра информационных технологий**
**Разработчик:** ИП Озеров Виктор Андреевич
**Заказчик (учебный проект):** EPAM Systems
**Год:** 2025

---

## 🚀 О проекте

**AskMyGPT** — это современное чат-приложение, созданное на фреймворке **Flutter**, позволяющее пользователям вести диалоги с различными моделями искусственного интеллекта (AI). Приложение поддерживает управление несколькими чат-сессиями, выбор AI-модели, настройку системных промптов (шаблонов) и безопасное хранение API-ключей.

Проект разработан в соответствии с Техническим Заданием, оформленным по ГОСТ 34.602-89.

---



## 👥 Команда проекта и роли (Группа 2323)

| Участник         | Роль                     | Основные задачи                                                                                                                                                              |
| :--------------- | :----------------------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Соловей С.С.** | Руководитель             | Наставничество и контроль проекта.                                                                                                                                           |
| **Озеров В.А.**  | Ведущий разработчик      | Программирование (модули `Message`, `ChatSession`, `SharedPreferences`), Интеграция API DeepSeek (streaming, ошибки), Архитектура и оптимизация.                              |
| **Кушнеров В.Н.**| UX/UI Дизайнер           | Проектирование интерфейса (макеты Figma, прототипы), Визуальный стиль (цвета, шрифты, иконки), Адаптивный дизайн.                                                              |
| **Лавринович М.В.** | Дизайнер анимаций       | Реализация анимаций ("раздумья" ИИ, переходы, клавиатура), Анимации смены тем, Визуализация состояний элементов (нажатие, наведение).                                       |
| **Герасименок Д.В.** | UX Консультант         | Анализ юзабилити (тестирование интерфейса, навигация), Рекомендации по оптимизации UI/UX (расположение элементов, упрощение форм).                                           |
| **Леонтьев Д.В.**| Тестировщик              | Функциональное тестирование (юнит-тесты, API), Ручное тестирование (соответствие макетам, стабильность), Документация багов (баг-репорты).                                   |



---


## ✨ Основные возможности

*   **Кроссплатформенность:** Работает на Android, iOS, Web и Desktop благодаря Flutter.
*   **Мульти-чатовость:**
    *   Создание, хранение и удаление неограниченного числа чатов.
    *   Группировка чатов в боковом меню по дате ("Сегодня", "Вчера", "Предыдущие 7 дней").
    *   Пакетное удаление выбранных чатов.
*   **Поддержка AI Моделей:**
    *   Выбор между различными AI-моделями (DeepSeek, ChatGPT, Grok, Mistral - с полной реализацией для DeepSeek).
    *   **DeepSeek Integration:**
        *   ✅ **Потоковая генерация (Streaming):** Ответы отображаются по мере их поступления (эффект печати).
        *   ✅ **Отображение "Раздумий" (Reasoning):** Уникальная возможность видеть "мысли" модели перед основным ответом.
        *   ✅ **Отмена запроса:** Возможность прервать генерацию ответа.
*   **Управление Сообщениями:**
    *   Копирование текста сообщений (пользователя и AI).
    *   Перезапрос ответа у AI для конкретного сообщения.
    *   Переключение между альтернативными вариантами ответа (если AI их предоставил).
*   **Управление Шаблонами (Системные Промпты):**
    *   Создание, редактирование и удаление пользовательских шаблонов (например, "Помощник по коду").
    *   Применение шаблона к новому чату для задания контекста AI.
*   **Пользовательский Интерфейс:**
    *   Чистый, интуитивно понятный дизайн.
    *   Поддержка **Темной** и **Светлой** тем с мгновенным переключением.
    *   Плавные анимации (появление сообщений, "мышление" AI).
    *   Автоматическая прокрутка вниз и кнопка "Вниз" при необходимости.
    *   Базовое форматирование Markdown в ответах AI (заголовки, списки, `**жирный**`, `*курсив*`, \`inline code\`).
    *   Отображение блоков кода с подсветкой языка.
*   **Локальное Хранилище:**
    *   Сохранение всех чатов, сообщений, шаблонов и API-ключей на устройстве с использованием `shared_preferences`.
*   **Настройки:**
    *   Выделенный экран для безопасного ввода и хранения API-ключей.

---

## 📸 Скриншоты (Примеры)



| Светлая тема | Темная тема |
|---|---|
| <img src="https://i.ibb.co/gbDr1nmy/image-17.png" alt="Chat Screen Light"> | <img src="https://i.ibb.co/W42RBvQ8/image-16.png" alt="Chat Screen Dark"> |
| *Экран чата (Светлая тема)* | *Экран чата (Темная тема)* |
| <img src="https://i.ibb.co/rKFFPJtF/image-4.png" alt="Drawer Light"> | <img src="https://i.ibb.co/s9Jp9Chc/image-3.png" alt="Drawer Dark"> |
| *Боковое меню (Светлая тема)* | *Боковое меню (Темная тема)* |
| <img src="https://i.ibb.co/YBc23P8X/image-14.png" alt="Templates Screen"> | <img src="https://i.ibb.co/6crxb4xS/image-5.png" alt="API Settings Screen"> |
| *Экран управления шаблонами* | *Экран настроек API* |

---

## 🛠 Технологический стек

*   **Язык:** Dart
*   **Фреймворк:** Flutter
*   **HTTP Клиент:** `package:http` (с поддержкой Streaming/SSE)
*   **Локальное Хранилище:** `package:shared_preferences`
*   **Управление Состоянием:** `StatefulWidget` / `setState`, `ValueNotifier`
*   **Асинхронность:** `Future`, `Stream`, `async/await`

---

## 🏗 Архитектура (Обзор)

Приложение следует стандартной архитектуре Flutter-приложений, разделяя UI (экраны, виджеты), логику (управление состоянием, взаимодействие с API) и модели данных (ChatSession, Message, TemplateModel).

Взаимодействие с внешними AI API происходит через HTTPS запросы, с использованием потоковой передачи данных (streaming) для моделей, которые это поддерживают (например, DeepSeek). Локальное хранилище (`SharedPreferences`) используется для персистентности данных пользователя.

### Диаграммы



*   **Схема взаимодействия:**
    <img src="https://i.ibb.co/67HcW1mm/FLUTTER-APP.png" alt="Схема взаимодействия">
*   **Диаграмма пакетов:**
    <img src="https://i.ibb.co/gFhNQJwb/firefox-og-Vea-ROc-Ek.png" alt="Диаграмма пакетов">
*   **Диаграмма компонентов:**
    <img src="https://i.ibb.co/931f1RRS/4.png" alt="Диаграмма компонентов">
*   **Диаграмма развертывания:**
    <img src="https://i.ibb.co/WvDQHBHJ/firefox-Br-CJRW75-Uq.png" alt="Диаграмма развертывания">

---

## 📖 Использование

1.  **Создайте новый чат:** Нажмите иконку `➕` на главном экране в правом верхнем углу.
2.  **(Опционально) Выберите шаблон:** Нажмите кнопку "Шаблоны" внизу и выберите системный промпт для нового чата.
3.  **(Опционально) Выберите модель AI:** Нажмите на название текущей модели (например, "DeepSeek") и выберите другую из списка.
4.  **Начните диалог:** Введите ваше сообщение в поле ввода и нажмите иконку отправки (`➤` или `send`).
5.  **Взаимодействуйте с ответом:**
    *   Нажмите иконку `📄`  для копирования текста ответа.
    *   Нажмите иконку `🔄`  для перезапроса ответа.
    *   Если доступны альтернативы, используйте кнопки `< X / Y >` для переключения.
    *   Для DeepSeek: Нажмите на разделитель над ответом, чтобы развернуть/свернуть блок "раздумий".
6.  **Управляйте чатами:** Откройте боковое меню (свайп справа или иконка меню) для переключения между чатами или их удаления (долгое нажатие для выбора).

---

## 📚 Документация

Проектная и техническая документация разработана с учетом требований стандартов, указанных в Техническом Задании. Основные документы включают Техническое Задание, Техническую документацию, Пользовательскую документацию и Документацию по тестированию.
