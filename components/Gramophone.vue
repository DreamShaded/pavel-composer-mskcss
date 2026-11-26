<script setup lang="ts">
// Патефон-проигрыватель для музыкальных фрагментов.
//
// Сценарий (эффекты из каталога awesome-ai-motion):
//   1. shared-element move — патефон из правого нижнего угла едет в центр и растёт (0.7s, power3.out);
//      одновременно spotlight-затемнение краёв (0.65s);
//   2. drop — на диск опускается пластинка (0.5s, power3.out), затем spin-loop (линейно, 1.8s/оборот);
//   3. iris-mask — видео раскрывается кругом из центра пластинки (1.35s, power2.inOut).
// На выходе всё в обратном порядке: iris закрывается, пластинка поднимается, патефон уезжает в угол.
//
// Управление — кликами Slidev. Трек i играет, когда $clicks === at + i; клик после последнего трека
// возвращает патефон в угол. В frontmatter слайда нужно `clicks: at + tracks.length`.
//
// Предзагрузка: у каждого трека свой <video preload="auto">. src им выдаётся, когда до слайда
// остаётся один шаг (открыт предыдущий слайд) или когда открыт сам слайд, — к клику клип уже в буфере.
import { computed, onBeforeUnmount, ref, useId, watch } from 'vue'
import { onSlideEnter, onSlideLeave, useSlideContext } from '@slidev/client'

interface Track {
  src: string
  label: string
  tone?: string
}

const props = withDefaults(defineProps<{
  tracks: Track[]
  at?: number
}>(), { at: 1 })

const { $clicks, $renderContext, $nav, $page } = useSlideContext()

// Патефонов в колоде несколько, а id градиентов в SVG глобальны на документ — делаем уникальными.
const uid = useId()
const brassId = `gramo-brass-${uid}`
const woodId = `gramo-wood-${uid}`

// Анимируем и играем звук только в живом показе; в презентере — тот же сценарий без звука,
// в превью/обзоре/экспорте — статичный патефон в углу.
const isLive = computed(() => !$nav.value.isPrintMode && ($renderContext.value === 'slide' || $renderContext.value === 'presenter'))
const isMuted = computed(() => $renderContext.value !== 'slide')

const root = ref<HTMLElement>()
const deck = ref<HTMLElement>()
const record = ref<HTMLElement>()
const screen = ref<HTMLElement>()
const veil = ref<HTMLElement>()
const videos = ref<HTMLVideoElement[]>([])

// Грузим клипы заранее: с предыдущего слайда или с этого. Один раз включив, не выключаем —
// уже скачанное пригодится при возврате на слайд.
const PRELOAD_AHEAD = 1
const armed = ref(false)
watch(
  () => isLive.value && $nav.value.currentSlideNo >= $page.value - PRELOAD_AHEAD && $nav.value.currentSlideNo <= $page.value,
  (near) => { if (near) armed.value = true },
  { immediate: true },
)

const current = ref(-1) // какой трек сейчас на патефоне
const spinning = ref(false)
let inCenter = false
let generation = 0
let queue: Promise<void> = Promise.resolve()

const EASE_OUT = 'cubic-bezier(0.215, 0.61, 0.355, 1)' // power3.out
const EASE_IN_OUT = 'cubic-bezier(0.455, 0.03, 0.515, 0.955)' // power2.inOut
const CORNER = 'translate(26.4rem, 3.25rem) scale(0.3)'
const CENTER = 'translate(0, 0) scale(1)'
const IRIS_CLOSED = 'circle(0px at 50% 128%)'
const IRIS_OPEN = 'circle(34rem at 50% 128%)'

const reduceMotion = typeof matchMedia === 'function' && matchMedia('(prefers-reduced-motion: reduce)').matches
const speed = reduceMotion ? 0.01 : 1

const target = computed(() => {
  const i = $clicks.value - props.at
  return i >= 0 && i < props.tracks.length ? i : -1
})
const track = computed(() => (current.value >= 0 ? props.tracks[current.value] : undefined))

function assetUrl(path: string) {
  if (/^(https?:)?\/\//.test(path)) return path
  const base = import.meta.env.BASE_URL || '/'
  return `${base.replace(/\/$/, '')}/${path.replace(/^\//, '')}`
}

async function animate(el: HTMLElement | undefined, frames: Keyframe[], duration: number, easing: string) {
  if (!el) return
  const a = el.animate(frames, { duration: duration * speed, easing, fill: 'forwards' })
  try {
    await a.finished
    a.commitStyles()
  }
  catch {
    // анимацию отменил reset() — это штатно
  }
  a.cancel()
}

function waitForPlayable(v: HTMLVideoElement, timeoutMs = 1500) {
  if (v.readyState >= 3) return Promise.resolve()
  return new Promise<void>((resolve) => {
    const done = () => {
      v.removeEventListener('canplay', done)
      clearTimeout(t)
      resolve()
    }
    const t = setTimeout(done, timeoutMs)
    v.addEventListener('canplay', done)
  })
}

async function toCenter() {
  await Promise.all([
    animate(deck.value, [{ transform: CORNER }, { transform: CENTER }], 700, EASE_OUT),
    animate(veil.value, [{ opacity: 0 }, { opacity: 1 }], 650, EASE_OUT),
  ])
  inCenter = true
}

async function toCorner() {
  await Promise.all([
    animate(deck.value, [{ transform: CENTER }, { transform: CORNER }], 700, EASE_OUT),
    animate(veil.value, [{ opacity: 1 }, { opacity: 0 }], 650, EASE_OUT),
  ])
  inCenter = false
}

async function putRecord(i: number, gen: number) {
  armed.value = true
  current.value = i
  const v = videos.value[i]
  if (v)
    v.muted = isMuted.value
  await animate(record.value, [
    { opacity: 0, transform: 'translateY(-10rem)' },
    { opacity: 1, transform: 'translateY(0)' },
  ], 500, EASE_OUT)
  if (gen !== generation) return
  spinning.value = true
  if (v) {
    await waitForPlayable(v)
    if (gen !== generation) return
    v.currentTime = 0
    v.play().catch(err => console.warn('[Gramophone] play() rejected', err))
  }
  await animate(screen.value, [{ clipPath: IRIS_CLOSED }, { clipPath: IRIS_OPEN }], 1350, EASE_IN_OUT)
}

async function liftRecord() {
  await animate(screen.value, [{ clipPath: IRIS_OPEN }, { clipPath: IRIS_CLOSED }], 800, EASE_IN_OUT)
  pauseAll()
  spinning.value = false
  await animate(record.value, [
    { opacity: 1, transform: 'translateY(0)' },
    { opacity: 0, transform: 'translateY(-10rem)' },
  ], 450, EASE_OUT)
  current.value = -1
}

async function apply(gen: number) {
  if (gen !== generation) return
  const want = target.value
  if (want === current.value) {
    if (want < 0 && inCenter) await toCorner()
    return
  }
  if (current.value >= 0) await liftRecord()
  if (gen !== generation) return
  if (want < 0) {
    if (inCenter) await toCorner()
    return
  }
  if (!inCenter) await toCenter()
  if (gen !== generation) return
  await putRecord(want, gen)
}

// Очередь: идёт один сценарий за раз; если за время анимации пришло несколько кликов,
// выполняется только последний запрос.
function request() {
  if (!isLive.value) return
  const gen = ++generation
  queue = queue.then(() => apply(gen))
}

function pauseAll() {
  for (const v of videos.value)
    v?.pause()
}

// Мгновенный сброс: ушли со слайда — тишина и патефон в углу.
function reset() {
  generation++
  for (const el of [deck.value, record.value, screen.value, veil.value])
    el?.getAnimations().forEach(a => a.cancel())
  if (deck.value) deck.value.style.transform = CORNER
  if (veil.value) veil.value.style.opacity = '0'
  if (record.value) {
    record.value.style.opacity = '0'
    record.value.style.transform = 'translateY(-10rem)'
  }
  if (screen.value) screen.value.style.clipPath = IRIS_CLOSED
  pauseAll()
  spinning.value = false
  current.value = -1
  inCenter = false
  queue = Promise.resolve()
}

watch(target, request)
watch(isMuted, (m) => { for (const v of videos.value) if (v) v.muted = m })
onSlideEnter(() => request())
onSlideLeave(() => reset())
onBeforeUnmount(reset)
</script>

<template>
  <div ref="root" class="gramo" aria-hidden="true">
    <div ref="veil" class="gramo__veil" />

    <div ref="deck" class="gramo__deck">
      <svg class="gramo__body" viewBox="0 0 240 240">
        <defs>
          <linearGradient :id="brassId" x1="0" y1="0" x2="1" y2="1">
            <stop offset="0" stop-color="#f3d27a" />
            <stop offset="0.55" stop-color="#c79a3b" />
            <stop offset="1" stop-color="#7a5418" />
          </linearGradient>
          <linearGradient :id="woodId" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0" stop-color="#8a5130" />
            <stop offset="1" stop-color="#4d2a15" />
          </linearGradient>
        </defs>
        <!-- раструб -->
        <path d="M184 150 C 182 112, 150 92, 112 74" fill="none" :stroke="`url(#${brassId})`" stroke-width="9" stroke-linecap="round" />
        <path d="M118 80 L 30 16 C 6 40, 14 92, 52 104 Z" :fill="`url(#${brassId})`" />
        <ellipse cx="40" cy="60" rx="20" ry="46" transform="rotate(-34 40 60)" fill="#3b2a12" opacity="0.55" />
        <!-- корпус -->
        <rect x="34" y="158" width="172" height="62" rx="6" :fill="`url(#${woodId})`" />
        <rect x="46" y="172" width="148" height="34" rx="3" fill="none" stroke="#c79a3b" stroke-opacity="0.6" stroke-width="2" />
        <!-- ручка завода -->
        <path d="M206 186 h 18 v -16" fill="none" stroke="#c79a3b" stroke-width="5" stroke-linecap="round" />
        <!-- диск -->
        <ellipse cx="120" cy="158" rx="84" ry="23" fill="#1d1d1f" />
        <ellipse cx="120" cy="156" rx="80" ry="21" fill="#2c2c30" />
      </svg>

      <div ref="record" class="gramo__record">
        <div class="gramo__tilt">
          <div class="gramo__disc" :class="{ 'is-spinning': spinning }">
            <span class="gramo__label" :style="{ background: track?.tone ?? 'var(--mc-red)' }" />
          </div>
        </div>
      </div>

      <svg class="gramo__arm" viewBox="0 0 240 240">
        <circle cx="190" cy="150" r="7" fill="#c79a3b" />
        <path d="M190 150 L 158 156" stroke="#d9b45a" stroke-width="5" stroke-linecap="round" />
      </svg>
    </div>

    <div ref="screen" class="gramo__screen">
      <video
        v-for="(t, i) in tracks"
        v-show="i === current"
        :key="t.src"
        :ref="(el) => { if (el) videos[i] = el as HTMLVideoElement }"
        class="gramo__video"
        :src="armed ? assetUrl(t.src) : undefined"
        playsinline
        preload="auto"
      />
      <span v-if="track" class="gramo__caption">♪ {{ track.label }}</span>
    </div>
  </div>
</template>

<style scoped>
.gramo {
  position: absolute;
  inset: 0;
  z-index: 30;
  pointer-events: none;
}

.gramo__veil {
  position: absolute;
  inset: 0;
  opacity: 0;
  background: radial-gradient(ellipse at 50% 48%, rgb(0 0 0 / 0.55) 0%, rgb(0 0 0 / 0.94) 68%);
}

/* Геометрия на канвасе 980×551: в центре патефон стоит снизу по центру, в углу —
   над номером слайда (см. CORNER в скрипте). */
.gramo__deck {
  position: absolute;
  left: 23.125rem;
  top: 18.125rem;
  width: 15rem;
  height: 15rem;
  transform: translate(26.4rem, 3.25rem) scale(0.3);
  transform-origin: 50% 50%;
  filter: drop-shadow(0 0.6rem 1rem rgb(0 0 0 / 0.45));
}

.gramo__body,
.gramo__arm {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
}

.gramo__arm {
  z-index: 2;
}

/* Пластинка: внешний слой опускается в экранных координатах, .gramo__tilt кладёт её
   в плоскость диска, .gramo__disc крутится в этой плоскости. */
.gramo__record {
  position: absolute;
  left: 2.85rem;
  top: 4.9rem;
  width: 9.3rem;
  height: 9.3rem;
  z-index: 1;
  opacity: 0;
  transform: translateY(-10rem);
}

.gramo__tilt {
  width: 100%;
  height: 100%;
  transform: rotateX(74deg);
}

.gramo__disc {
  position: relative;
  width: 100%;
  height: 100%;
  border-radius: 50%;
  background:
    repeating-radial-gradient(circle, #111 0 2px, #1c1c1c 2px 4px),
    #111;
  box-shadow: inset 0 0 0 2px #333;
  animation: gramo-spin 1.8s linear infinite;
  animation-play-state: paused;
}

.gramo__disc.is-spinning {
  animation-play-state: running;
}

.gramo__label {
  position: absolute;
  inset: 34%;
  border-radius: 50%;
  /* засечка на этикетке, чтобы вращение читалось */
  box-shadow: inset 0.9rem 0 0 -0.6rem rgb(255 255 255 / 0.85);
}

.gramo__screen {
  position: absolute;
  left: 13.25rem;
  top: 1.5rem;
  width: 36rem;
  height: 20.25rem;
  clip-path: circle(0px at 50% 128%);
}

.gramo__video {
  width: 100%;
  height: 100%;
  object-fit: contain;
  background: #000;
  border-radius: 1rem;
  /* мягкие края: картинка растворяется в затемнении */
  mask-image: radial-gradient(ellipse at 50% 50%, #000 66%, transparent 100%);
}

.gramo__caption {
  position: absolute;
  left: 50%;
  bottom: 0.75rem;
  transform: translateX(-50%);
  max-width: 90%;
  padding: 0.2rem 0.9rem;
  border-radius: 999px;
  background: rgb(0 0 0 / 0.7);
  color: #ecebe6;
  font: 500 1rem/1.4 var(--mc-font-mono);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

@keyframes gramo-spin {
  to { transform: rotate(360deg); }
}

@media (prefers-reduced-motion: reduce) {
  .gramo__disc { animation-duration: 6s; }
}
</style>
