#!/usr/bin/env bash
# Нарезка клипов из исходников ./videos в ./public/clips (H.264 ≤720p, AAC, faststart).
# Идемпотентно: существующий клип пропускается; FORCE=1 пересобирает всё.
# Таймкоды — из Plan.md; где Павел их не дал, взято начало трека (помечено «assumed»).
set -euo pipefail
cd "$(dirname "$0")/.."
SRC=videos
OUT=public/clips
mkdir -p "$OUT"

# slug | файл-источник | старт (сек) | длительность (сек, 0 = до конца)
CLIPS=(
  "pifpaf|Пиф-паф - ой-ой-ой. Легендарный мультфильм-пародия (1980).mp4|695|40"
  "crab-canon|Bach's Crab Canon.mp4|0|0"
  "crab-rave|Noisestorm - Crab Rave [Monstercat Release].mp4|0|30"            # assumed
  "beriozka|Ансамбль Березка Во поле березка стояла Девичий хоровод Beriozka Ensemble Russian Folk Dance Superb.mp4|0|60"  # assumed
  "berlioz-dies-irae|Berlioz： Symphonie fantastique – V. (Dream of a Witches’ Sabbath) – London Philharmonic Orchestra.mp4|167|60"
  "tango|Танго из фильма 'Запах женщины'. Аль Пачино и Габриэль Анвар.mp4|102|60"
  "mozart-rondo|Mozart - Rondo in C major K 373 for violin and orchestra (1781) [Grumiaux].mp4|204|60"
  "glebov-adagio|Глебов Адажио.mp4|0|60"                                       # assumed
  "kashcheevna|Клавдия Кудряшова ｜ Ария Кащеевны.mp4|264|60"
  "prokofiev-march|Сергей Прокофьев. Марш из оперы 'Любовь к трем апельсинам'. Дирижер Геннадий Рождественский (1984).mp4|0|0"
  "imperial-march|John Williams & Vienna Philharmonic – Williams： Imperial March (from “Star Wars”).mp4|0|60"  # assumed
  "trepak|П.И.Чайковский. Балет 'Щелкунчик'. Часть дивертисмента - Русский танец 'Трепак'.mp4|0|0"
  "home-alone|Home Alone Soundtrack-02 Holiday Flight.mp4|0|0"
)

for row in "${CLIPS[@]}"; do
  IFS='|' read -r slug file start dur <<<"${row%%#*}"
  dur="${dur// /}"
  src="$SRC/$file"; dst="$OUT/$slug.mp4"
  [[ -f "$src" ]] || { echo "missing source: $src" >&2; exit 1; }
  if [[ -f "$dst" && "${FORCE:-0}" != 1 ]]; then echo "skip $slug"; continue; fi
  durargs=(); [[ "$dur" != 0 ]] && durargs=(-t "$dur")
  echo "cut $slug (start=${start}s dur=${dur}s)"
  ffmpeg -hide_banner -loglevel error -y -ss "$start" -i "$src" "${durargs[@]}" \
    -vf "scale='min(1280,iw)':'min(720,ih)':force_original_aspect_ratio=decrease,scale=trunc(iw/2)*2:trunc(ih/2)*2" \
    -c:v libx264 -preset medium -crf 26 -pix_fmt yuv420p \
    -af "afade=t=in:d=0.8" -c:a aac -b:a 128k -movflags +faststart "$dst.tmp.mp4"
  mv "$dst.tmp.mp4" "$dst"
done
du -sh "$OUT"
