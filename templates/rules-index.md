Правила лежат в `@RULES_ROOT@`. OpenCode не выбирает их по glob: перед изменением файлов прочитай только те, что подходят к задаче, и считай прочитанное обязательным. Весь каталог заранее не читай.

### BSL и клиент-сервер

Когда: правка или ревью модулей BSL (*.bsl, *.os), асинхронный код, транзакции.

- `@RULES_ROOT@/bsl/1c-bsl-runtime-specifics.md` — Ошибки выполнения BSL, которые не видит статический анализ; ЗУП 3.x (`**/*.bsl`, `**/*.os`)
- `@RULES_ROOT@/bsl/1c-coding-standards.md` — Стандарты кода BSL: именование, запросы, коллекции (`**/*.bsl`, `**/*.os`)
- `@RULES_ROOT@/bsl/1c-transactions-and-locks.md` — Транзакции и управляемые блокировки: шаблон, порядок захвата (`**/*.bsl`, `**/*.os`)
- `@RULES_ROOT@/bsl/1c77-specifics.md` — Особенности 1С 7.7: коллекции, правка модулей скриптом, обмен и миграция (`**/*.1s`, `**/*.ert`, `**/*.frm`, `**/1Cv7.MD`)
- `@RULES_ROOT@/bsl/async-methods-1c.md` — Асинхронные методы 1С: Асинх/Ждать/Обещание (8.3.18+) (`**/*.bsl`, `**/*.os`)
- `@RULES_ROOT@/bsl/refactoring.md` — Правила рефакторинга кода 1С (`**/*.bsl`, `**/*.os`)
- `@RULES_ROOT@/bsl/text-formatting.md` — Запрещенные символы в генерируемом тексте: длинное тире, буква ё, кавычки-елочки (по задаче, без маски файлов)

### Запросы

Когда: текст запроса, прямой запрос в отчете, язык запросов.

- `@RULES_ROOT@/queries/1c-query-specifics.md` — Особенности запросов: совместимость типов, соединения, регистр бухгалтерии (`**/*.bsl`, `**/*.os`, `**/*.dcs`)
- `@RULES_ROOT@/queries/1c-report-direct-query.md` — Прямой запрос в отчётах 1С (СКД) без схемы компоновки (`**/*.bsl`, `**/*.os`)

### Производительность и антипаттерны

Когда: производительность, запрос в цикле, обход коллекций, оптимизация запроса.

- `@RULES_ROOT@/performance/anti_patterns.md` — Критические антипаттерны 1С: запрос в цикле, реквизиты через точку (`**/*.bsl`, `**/*.os`)
- `@RULES_ROOT@/performance/query-optimization-tips.md` — Оптимизация запросов 1С: ВЫРАЗИТЬ, ВТ, индексы (`**/*.bsl`, `**/*.os`)

### Метаданные, XML и EDT

Когда: XML-выгрузка, MDO, EDT, UUID, внешние источники, v8unpack.

- `@RULES_ROOT@/metadata/1c-mdo-integrity.md` — Целостность MDO-файлов: UUID, ссылки (`**/*.mdo`)
- `@RULES_ROOT@/metadata/edt-bsl-write-safety.md` — Безопасная запись BSL-модулей через EDT MCP (режимы write_module_source) (`**/*.bsl`)
- `@RULES_ROOT@/metadata/edt-known-errors.md` — Известные ошибки EDT: запись метаданных, деплой, реструктуризация, хранилище (`**/*.mdo`, `**/*.form`, `**/*.dcs`, `**/*.schedule`, `**/DT-INF/**`)
- `@RULES_ROOT@/metadata/edt-source-format.md` — Формат исходников 1С и один владелец развертывания на прогон (`**/*.mdo`, `**/*.form`, `**/Configuration.xml`)
- `@RULES_ROOT@/metadata/edt-thick-client-monopoly.md` — Монопольная сессия EDT и пакетный Конфигуратор, сборка .cf/.cfe из ИБ (`**/*.mdo`, `**/DT-INF/**`, `**/*.cf`, `**/*.cfe`, `**/*.epf`, `**/*.erf`, `**/*.cmd`, `**/*.bat`, `**/*.ps1`)
- `@RULES_ROOT@/metadata/edt-zip-export-pitfalls.md` — Ограничения инкрементального экспорта конфигурации из EDT в ИБ (`**/*.mdo`)
- `@RULES_ROOT@/metadata/external-data-source-mdo.md` — Внешние источники данных (ВИД) в формате EDT (`**/*.mdo`, `**/ExternalDataSources/**`)
- `@RULES_ROOT@/metadata/v8unpack-source-structure.md` — Структура исходников v8unpack (`**/*.obj.bsl`, `**/*.mgr.bsl`, `**/*.elem.json`)

### Управляемые и обычные формы

Когда: управляемые и обычные формы, Form.xml, Form.form, модуль формы.

- `@RULES_ROOT@/forms/1c-form-reserved-names.md` — Зарезервированные имена свойств в модулях форм 1С (`**/*.bsl`)
- `@RULES_ROOT@/forms/1c-managed-forms-specifics.md` — Особенности управляемых форм: доработка в расширении, динамический список, элементы (`**/*.form`, `**/Forms/**`)
- `@RULES_ROOT@/forms/1c-ordinary-forms.md` — Обычные формы: отличия от управляемых, порядок операций с видимостью (`**/Forms/**/*.bsl`, `**/Ext/Form.xml`)
- `@RULES_ROOT@/forms/edt-form-xml-requirements.md` — Требования EDT к XML-формам (Form.form): extInfo, дефолты полей (`**/Form.form`, `**/Forms/**`)
- `@RULES_ROOT@/forms/form_module_rules.md` — Клиент-серверное разделение в модулях форм (`**/*.bsl`)
- `@RULES_ROOT@/forms/forms_events.md` — Привязка обработчиков событий в Form.xml (`**/Form.xml`, `**/*.bsl`)
- `@RULES_ROOT@/forms/forms_generation.md` — Генерация и модификация форм 1С через 1c-forms-mcp (`**/Forms/**/*.xml`, `**/Forms/**`)

### Расширения

Когда: расширение CFE, перехватчики, заимствование.

- `@RULES_ROOT@/extensions/1c-extension-patterns.md` — Паттерны расширений CFE: перехватчики, маркеры (`**/*.bsl`, `**/*.os`)
- `@RULES_ROOT@/extensions/1c-extension-specifics.md` — Особенности расширений: перехваты, заимствование, XML-выгрузка внешних обработок (`**/*.bsl`, `**/*.mdo`, `**/*.xml`)

### БСП и типовые

Когда: БСП, типовая конфигурация на поддержке, профили групп доступа, фоновые задания.

- `@RULES_ROOT@/bsp/bsl-ssl.md` — Переиспользование БСП, разметка правок типовых модулей, устаревшие объекты (`**/*.bsl`, `**/*.os`)
- `@RULES_ROOT@/bsp/bsp-profile-rights-api.md` — Программная работа с профилями групп доступа БСП: ссылки на ИдентификаторыОбъектовМетаданных (`**/*.bsl`, `**/*.os`)
- `@RULES_ROOT@/bsp/routine_assignment_ext_processor.md` — Фоновые задания из внешней обработки через БСП (`**/*.bsl`, `**/*.os`)

### СКД

Когда: схема компоновки данных.

- `@RULES_ROOT@/skd/1c-skd-specifics.md` — Особенности СКД: отборы во временных таблицах, схема .dcs, оформление, вывод (`**/*.dcs`, `**/Reports/**/*.bsl`, `**/ExternalReports/**`)
- `@RULES_ROOT@/skd/1c-skd-two-pass-preprocessing.md` — Двухпроходный СКД: предобработка детальных записей до свертки (`**/Reports/**/*.bsl`, `**/*.dcs`)

### Права, роли и безопасность

Когда: роли, RLS, git, секреты, пароль в журнале Конфигуратора.

- `@RULES_ROOT@/security/1c-role-rights.md` — Права ролей 1С: права на объекты, RLS, наследование (`**/Rights.xml`, `**/Roles/**`, `**/*.mdo`)
- `@RULES_ROOT@/security/git-safety-rules.md` — Безопасная работа с git: деструктивные команды, секреты, политика EOL для 1С (по задаче, без маски файлов)

### Обмены

Когда: обмен, EnterpriseData, XDTO, HTTP-сервисы обмена.

- `@RULES_ROOT@/exchange/1c-exchange-specifics.md` — Особенности обменов: EnterpriseData, НСИ по HTTP, CPMDataExchange (`**/XDTOPackages/**`, `**/*.xdto`, `**/ExchangePlans/**`, `**/HTTPServices/**`, `**/WebServices/**`)

### Процесс агента, ревью и git

Когда: план работы агента, ревью, проверка результата, выбор модели, MCP, Windows-кириллица.

- `@RULES_ROOT@/workflow/1c-cyrillic-windows.md` — Кириллица в путях и аргументах на Windows: симптомы, кодировки, отказы (`**/*.ps1`, `**/*.py`, `**/*.cmd`, `**/*.bat`, `**/*.mjs`)
- `@RULES_ROOT@/workflow/agent-verification-patterns.md` — Паттерны проверки результата работы агента (reconciliation loop) (по задаче, без маски файлов)
- `@RULES_ROOT@/workflow/agent-working-memory.md` — Рабочая память агента: файлы плана, передача сессии, журнал инцидентов (по задаче, без маски файлов)
- `@RULES_ROOT@/workflow/code-exploration-guide.md` — Методология исследования кодовой базы 1С (по задаче, без маски файлов)
- `@RULES_ROOT@/workflow/code-review-checklist.md` — Чеклист ревью BSL-кода (`**/*.bsl`, `**/*.os`)
- `@RULES_ROOT@/workflow/designer-batch-verdict.md` — Вердикт пакетного запуска платформы: четыре сигнала вместо кода возврата (`**/scripts/*.ps1`, `**/scripts/*.py`, `**/*.cmd`, `**/*.bat`)
- `@RULES_ROOT@/workflow/file-edit-efficiency.md` — Выбор инструмента чтения и правки файлов по стоимости токенов (по задаче, без маски файлов)
- `@RULES_ROOT@/workflow/integrations.md` — Python-first подход к HTTP-интеграциям 1С (прототип Python, перенос на BSL) (по задаче, без маски файлов)
- `@RULES_ROOT@/workflow/mcp-tool-priority.md` — Маршрутизатор MCP-серверов: какой сервер брать под задачу, обязательные проверки (по задаче, без маски файлов)
- `@RULES_ROOT@/workflow/model-selection.md` — Стратегия выбора моделей: Opus/Sonnet/Haiku по типу задачи (по задаче, без маски файлов)
- `@RULES_ROOT@/workflow/sdd-workflow.md` — Specification-Driven Development: 9-фазный workflow разработки (по задаче, без маски файлов)
- `@RULES_ROOT@/workflow/skill-design.md` — Проектирование навыков: способы вызова, лестница информации, критерии завершения (по задаче, без маски файлов)
- `@RULES_ROOT@/workflow/testing-patterns.md` — Паттерны тестирования 1С: YaXUnit, Vanessa (`**/*.bsl`, `**/*.os`)
