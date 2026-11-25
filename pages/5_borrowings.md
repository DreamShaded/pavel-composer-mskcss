---
layout: default
kicker: "/ дело №7 · цитаты и плагиат"
clicks: 3
---

# Кто у кого стянул ноты?

<div class="case">
<Evidence src="/images/09-tango.webp" tag="на грани плагиата" scene="Двое тянут друг у друга лист с нотами" :tilt="-3" />
<div class="case__text">

<div class="pair">
<Pill tone="red" :tilt="-2">Гардель, «Por una cabeza»</Pill>
</div>
<div class="pair">
<span class="pair__arrow">←</span>
<Pill tone="sky" :tilt="2">Моцарт, рондо K.373</Pill>
</div>

</div>
</div>

<Gramophone :tracks="[
  { src: '/clips/tango.mp4', label: 'Танго из фильма «Запах женщины»', tone: 'var(--mc-red)' },
  { src: '/clips/mozart-rondo.mp4', label: 'Моцарт. Рондо до мажор K.373', tone: 'var(--mc-sky)' },
]" />

<!--
Теперь заимствования, которые стоят на самой грани.

[click] Танго «Por una cabeza» Карлоса Гарделя. Все помнят его по фильму «Запах женщины». (фрагмент с 1:42; если время поджимает — с 2:18)

[click] А теперь Моцарт, Рондо до мажор для скрипки с оркестром, K.373. (с 3:24) Слышите?

[click] Случайность или заимствование — решайте сами.
-->

---
layout: default
kicker: "/ загадка"
clicks: 2
---

# Угадайте песню

<div class="case">
<Evidence src="/images/10-riddle.webp" tag="написано задолго до песни" scene="Конверт с грифом «секретно», из него торчит нотный лист" :tilt="2" />
<div class="case__text">

Сейчас прозвучит музыка, написанная **раньше**.<br>Какую известную песню вы в ней узнаете?

<div v-click="2" class="answer">
<div class="pair">
<Pill tone="yellow" :tilt="-3">Глебов, Адажио</Pill>
<span class="pair__arrow">→</span>
<Pill tone="green" :tilt="2">«Крылатые качели»</Pill>
</div>
</div>

</div>
</div>

<Gramophone :tracks="[{ src: '/clips/glebov-adagio.mp4', label: 'Е. Глебов. Адажио', tone: 'var(--mc-yellow)' }]" />

<!--
Загадка для зала. Сейчас прозвучит музыка, которая написана за много лет до одной очень известной песни. Угадайте, какой.

[click] Слушаем. Это Евгений Глебов.

[click] Правильно: «Крылатые качели». Саму песню включать не буду, вы её и так слышите в голове.
-->
