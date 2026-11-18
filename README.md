# Гиперссылки в классической музыке

Доклад Павла для Moscow CSS 32: случайность, плагиат или окно в другие миры. Slidev, тема
`slidev-theme-moscowcss` (копия лежит в репо). Сайт: https://dreamshaded.github.io/pavel-composer-mskcss/

```bash
pnpm install
pnpm dev          # внутри монорепо speech-and-reports
pnpm build:pages  # сборка как на Pages: --base, hash-роутинг, без заметок
pnpm clips        # пересобрать public/clips из исходников в ./videos (в git не хранятся)
```

Музыкальные фрагменты включает патефон (`components/Gramophone.vue`) по кликам слайда.
Иллюстрации-улики: промпты в `public/images/PROMPTS.md`.
Деплой: push в `main` → GitHub Actions → Pages (заметки спикера в публичную сборку не попадают).
