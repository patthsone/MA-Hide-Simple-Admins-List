# MA Hide + Simple Admins List

Комплект плагинов для SourceMod (CS:GO / CS:S), позволяющий администраторам скрываться из общего списка игроков и из меню `sm_admins`, а также вести рейтинг администраторов (лайки/дизлайки) и оставлять контактную информацию.

![Total Downloads](https://img.shields.io/github/downloads/patthsone/MA-Hide-Simple-Admins-List/total?style=flat&label=Total%20Downloads&labelColor=rgba(0%2C%2070%2C%20114%2C%201)&color=rgba(255%2C%20255%2C%20255%2C%201)) 
![Latest Release](https://img.shields.io/github/v/release/patthsone/MA-Hide-Simple-Admins-List?style=flat&label=Latest%20Release&labelColor=rgba(0%2C%2070%2C%20114%2C%201)&color=rgba(255%2C%20255%2C%20255%2C%201)) 

[Discord сервер](https://discord.gg/VmJzFBD6wf)

## Возможности

### MA Hide
- Скрывает администратора с табло, радара и из списка `sm_admins` (при интеграции).
- Автоматически переводит скрытого игрока в спектаторов и убирает его модель.
- Не отображает скрытого администратора в меню `sm_admins` (благодаря нативной интеграции).
- Команда `sm_hide` — включить/выключить скрытие.

### Simple Admins List
- Вывод списка всех онлайн‑администраторов в удобном меню (`sm_admins`).
- Поддержка MySQL/SQLite для хранения:
  - Контакта администратора (например, Steam, Discord).
  - Количества лайков и дизлайков.
  - Информации о том, кто и как голосовал.
- Голосование за администраторов (лайк/дизлайк).
- Отправка личных сообщений администратору через команду в чате.
- Отображение времени окончания срока администратора (Material Admin).
- Отображение групп и иммунитета (опционально).

## Интеграция
Плагин `MA Hide` предоставляет нативную функцию `MA_IsClientHidden(client)`, которую `Simple Admins List` использует для фильтрации скрытых администраторов. Таким образом, если администратор включил `sm_hide`, он **не появится** в списке `sm_admins`.

## Скачивание

Готовые скомпилированные плагины (`.smx`) и файл `ma_hide.inc` доступны в разделе [Releases](https://github.com/patthsone/MA-Hide-Simple-Admins-List/releases).

Или скачайте исходники и скомпилируйте самостоятельно (см. раздел «Сборка из исходников»).

## Установка

1. Убедитесь, что у вас установлены SourceMod 1.10+ и MetaMod.
2. Скомпилируйте оба плагина:
   - Поместите `ma_hide.inc` в папку `addons/sourcemod/scripting/include/`.
   - Скомпилируйте `ma_hide.sp` → `ma_hide.smx`.
   - Скомпилируйте `simple_admins_list.sp` → `simple_admins_list.smx`.
3. Загрузите `.smx` файлы в папку `addons/sourcemod/plugins/`.
4. **Важно:** Плагин `ma_hide.smx` должен загружаться **ПЕРЕД** `simple_admins_list.smx`. SourceMod загружает плагины в алфавитном порядке, если не указано иное. Переименуйте файлы или используйте `sm plugins load` вручную.
5. Настройте базу данных (см. раздел «Настройка базы данных»).
6. Перезапустите сервер или загрузите плагины через `sm plugins load`.

## Настройка базы данных

Создайте в `addons/sourcemod/configs/databases.cfg` секцию `"admins"`:

```cfg
"admins"
{
    "driver"            "mysql"          // или "sqlite"
    "host"              "localhost"
    "database"          "admin_db"
    "user"              "root"
    "pass"              ""
    // для SQLite закомментируйте host/user/pass
}
```

Если секция не найдена, плагин автоматически использует SQLite с базой admins_info.

Конфигурация

Плагины создают файлы конфигурации в cfg/sourcemod/:

plugin.admins.cfg — для Simple Admins List

ma_hide.cfg — для MA Hide (если добавлены переменные, по умолчанию нет)

ConVars Simple Admins List
Переменная	Значение по умолчанию	Описание
sm_admins_flag	a	Флаг, необходимый администратору для отображения в списке
sm_admins_immunity	1	Показывать уровень иммунитета в информации
sm_admins_group	1	Показывать группы администратора
sm_admins_timetype	%x	Формат времени окончания срока (strftime)
sm_admins_contactlen	20	Максимальная длина контакта
sm_admins_messagelen	50	Максимальная длина личного сообщения
Команды
MA Hide
sm_hide — включить/выключить скрытие. Доступно только администраторам с флагом (по умолчанию a). При включении игрок переходит в спектаторы и становится невидимым для других.

Simple Admins List
sm_admins — открыть меню списка администраторов.

Внутри меню:

Просмотр информации об администраторе (имя, иммунитет, срок истечения, группы).

Установить/изменить свой контакт.

Поставить лайк/дизлайк.

Отправить личное сообщение.

Чат‑команды (при запросе)
Введите cancel для отмены операции.

При установке контакта просто напишите текст в чат.

При отправке сообщения — текст будет доставлен выбранному администратору.

Требования
SourceMod 1.10 или новее.

Material Admin (для получения срока истечения администратора).

AS_Colors.inc (включена в поставку, но убедитесь, что она есть в include/).

Права на создание таблиц в базе данных (автоматически).

Сборка из исходников
Установите SourceMod и компилятор spcomp.exe (или spcomp для Linux).

Положите ma_hide.inc в addons/sourcemod/scripting/include/.

Поместите AS_Colors.inc в ту же папку.

Запустите компиляцию:

bash
spcomp ma_hide.sp
spcomp simple_admins_list.sp
Установите полученные .smx файлы на сервер.

Устранение неполадок
Ошибка "MA_IsClientHidden" is not defined
Убедитесь, что ma_hide.inc находится в папке include и плагин ma_hide скомпилирован первым. Если библиотека ma_hide не загружена, натива недоступна — перезагрузите ma_hide перед вторым плагином.

Скрытый администратор всё ещё виден в sm_admins
Проверьте, что оба плагина загружены. Используйте sm plugins list. Если simple_admins_list загрузился раньше ma_hide, выполните sm plugins reload simple_admins_list. При постоянной проблеме добавьте зависимость в simple_admins_list.sp:

sourcepawn
public void OnAllPluginsLoaded()
{
    if (!LibraryExists("ma_hide"))
        LogError("MA Hide не загружен! Интеграция недоступна.");
}
База данных не создаётся
Проверьте права на запись для SQLite (папка data/) или параметры подключения MySQL. Ошибки логируются в logs/error_*.log.

Лицензия
Проект распространяется под лицензией MIT. Вы вольны модифицировать и распространять код.

Авторы
MA Hide — PattHs
Simple Admins List — SN(Kaneki)
Интеграция и доработка — PattHs
