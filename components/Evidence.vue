<script setup lang="ts">
// Иллюстрация-«улика» из дела: фото под скрепкой с биркой.
// Пока картинки нет (src не найден), показывается заглушка с описанием сцены —
// промпты для генерации лежат в public/images/PROMPTS.md под тем же именем файла.
import { computed, ref } from 'vue'

const props = withDefaults(defineProps<{
  src: string
  tag: string
  scene: string
  tilt?: number
}>(), { tilt: -2 })

const failed = ref(false)
const url = computed(() => {
  const base = import.meta.env.BASE_URL || '/'
  return `${base.replace(/\/$/, '')}/${props.src.replace(/^\//, '')}`
})
</script>

<template>
  <figure class="evidence" :style="{ '--tilt': `${tilt}deg` }">
    <span class="evidence__clip" aria-hidden="true" />
    <img v-if="!failed" :src="url" :alt="scene" class="evidence__img" @error="failed = true">
    <div v-else class="evidence__stub">
      <span class="evidence__stub-title">фото улики в работе</span>
      <span class="evidence__stub-scene">{{ scene }}</span>
    </div>
    <figcaption class="evidence__tag">{{ tag }}</figcaption>
  </figure>
</template>

<style scoped>
.evidence {
  position: relative;
  margin: 0;
  padding: 0.75rem 0.75rem 2.75rem;
  background: #f4efe2;
  box-shadow: 0 0.75rem 1.75rem rgb(0 0 0 / 0.45);
  transform: rotate(var(--tilt));
  width: 100%;
  aspect-ratio: 4 / 3.6;
}

.evidence__clip {
  position: absolute;
  top: -0.9rem;
  left: 50%;
  width: 1.25rem;
  height: 2.6rem;
  border: 0.22rem solid #9aa0a8;
  border-radius: 0.7rem;
  transform: translateX(-50%) rotate(8deg);
}

.evidence__img,
.evidence__stub {
  width: 100%;
  height: 100%;
  object-fit: cover;
  filter: sepia(0.25) contrast(1.05);
}

.evidence__stub {
  display: flex;
  flex-direction: column;
  justify-content: center;
  gap: 0.5rem;
  padding: 1rem;
  background:
    repeating-linear-gradient(-45deg, rgb(0 0 0 / 0.05) 0 0.75rem, transparent 0.75rem 1.5rem),
    #d9d2bf;
  color: #3a3226;
  text-align: center;
}

.evidence__stub-title {
  font: 600 1rem/1.3 var(--mc-font-mono);
  text-transform: uppercase;
  letter-spacing: 0.08em;
}

.evidence__stub-scene {
  font: 400 1rem/1.35 var(--mc-font-text);
}

.evidence__tag {
  position: absolute;
  left: 0.75rem;
  right: 0.75rem;
  bottom: 0.55rem;
  color: #2a2419;
  font: 500 1rem/1.4 var(--mc-font-mono);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
</style>
