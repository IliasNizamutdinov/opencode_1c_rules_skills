---
description: Запустить Яндекс Браузер с портом удаленной отладки Chrome DevTools
---

Запусти Яндекс Браузер с удаленной отладкой (Chrome DevTools Protocol) для отладки веб-клиента 1С.
Команда рассчитана на Windows. На Linux и macOS браузер и флаги будут другими: не подставляй пути Яндекс Браузера наугад, спроси путь к исполняемому файлу.

`$ARGUMENTS` может содержать порт. Если порта нет, используй 9222.

1. Закрой процессы Яндекс Браузера:

```bat
taskkill /F /IM browser.exe
```

2. Подожди 3 секунды и запусти браузер:

```bat
"%LOCALAPPDATA%\Yandex\YandexBrowser\Application\browser.exe" --remote-debugging-port=9222
```

3. Подожди 10 секунд и проверь CDP:

```bash
curl -s http://localhost:9222/json/version
```

4. Если ответа нет, повтори проверку еще два раза с паузой 5 секунд.
5. Если CDP ответил, выведи статус и WebSocket URL. Напомни добавить MCP Chrome DevTools в `opencode.json` (`mcp.servers`), если его еще нет. Не записывай конфигурацию молча: покажи фрагмент и дождись согласия.
