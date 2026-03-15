#!/usr/bin/env bash

if [ -z "${MACOS_DOCK}" ]; then
  echo "MACOS_DOCK is not set, skipping..."
  exit 0
fi

set -eufo pipefail

if ! command -v dockutil >/dev/null; then
  echo "error: dockutil not installed, re-run after installing"
  exit 1
fi

DOCK_ITEMS_FILE="${DOCK_ITEMS_FILE:-$HOME/.config/dockutil/items.csv}"
DOCK_ITEMS_PREFIX="${DOCK_ITEMS_FILE%.csv}"
# Opt-in full reset; default to targeted removals only.
DOCKUTIL_RESET_ALL="${DOCKUTIL_RESET_ALL:-false}"

if [[ ! -f "${DOCK_ITEMS_FILE}" ]]; then
  echo "error: dock items file not found at ${DOCK_ITEMS_FILE}"
  exit 1
fi

echo "dockutil found, reading Dock..."
dockutil --list || true
echo ""

expand_path() {
  local value="${1:-}"
  value="${value/#\~/${HOME}}"
  value="${value//\$HOME/${HOME}}"
  printf '%s' "${value}"
}

trim() {
  local value="${1:-}"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "${value}"
}

declare -A DESIRED PATHS TYPES VIEWS DISPLAYS SORTS PRESENT RECENT
declare -A CURRENT_POS
declare -a ORDER_APPS=()
declare -a ORDER_OTHERS=()
declare -a DOCK_ITEM_FILES=("${DOCK_ITEMS_FILE}")
DOCK_CHANGED=false
apps_position=0
others_position=0

shopt -s nullglob
for extra_file in \
  "${DOCK_ITEMS_PREFIX}.extra.csv" \
  "${DOCK_ITEMS_PREFIX}.extra."*.csv \
  "${DOCK_ITEMS_PREFIX}.local.csv" \
  "${DOCK_ITEMS_PREFIX}.local."*.csv; do
  [[ -f "${extra_file}" ]] || continue
  DOCK_ITEM_FILES+=("${extra_file}")
done
shopt -u nullglob

read_items_file() {
  local items_file="${1}"

  echo "Loading dock items from ${items_file}"

  while IFS=',' read -r section label path type view display sort; do
    section="$(trim "${section}")"
    label="$(trim "${label}")"
    path="$(trim "${path}")"
    type="$(trim "${type:-app}")"
    view="$(trim "${view}")"
    display="$(trim "${display}")"
    sort="$(trim "${sort}")"

    [[ -z "${section}" ]] && continue
    [[ "${section}" == section ]] && continue
    [[ "${section:0:1}" == "#" ]] && continue

    case "${section}" in
      apps) ORDER_APPS+=("${label}") ;;
      others) ORDER_OTHERS+=("${label}") ;;
      *) echo "warning: unsupported section '${section}' in ${items_file}, skipping" >&2; continue ;;
    esac

    key="${section}:${label}"
    DESIRED["${key}"]=1
    PATHS["${key}"]="${path}"
    TYPES["${key}"]="${type}"
    VIEWS["${key}"]="${view}"
    DISPLAYS["${key}"]="${display}"
    SORTS["${key}"]="${sort}"
  done < "${items_file}"
}

for items_file in "${DOCK_ITEM_FILES[@]}"; do
  read_items_file "${items_file}"
done

if [[ "${DOCKUTIL_RESET_ALL}" == "true" || "${DOCKUTIL_RESET_ALL}" == "1" ]]; then
  echo "Resetting Dock persistent sections before syncing..."
  DOCK_CHANGED=true
  dockutil --remove all --section apps --no-restart || true
  dockutil --remove all --section others --no-restart || true
else
  echo "Using targeted removals; set DOCKUTIL_RESET_ALL=true to force a clean slate."
fi

while IFS=$'\t' read -r item path section plist; do
  item="$(trim "${item}")"
  section="$(trim "${section}")"
  [[ -z "${item}" || -z "${section}" ]] && continue

  case "${section}" in
    apps | persistentApps)
      section_key="apps"
      ((++apps_position))
      ;;
    others | persistentOthers)
      section_key="others"
      ((++others_position))
      ;;
    recent | recentApps) RECENT["${item}"]=1; continue ;;
    *) continue ;;
  esac

  key="${section_key}:${item}"
  PRESENT["${key}"]="${path}"
  case "${section_key}" in
    apps) CURRENT_POS["${key}"]="${apps_position}" ;;
    others) CURRENT_POS["${key}"]="${others_position}" ;;
  esac

  if [[ -z "${DESIRED[${key}]+x}" ]]; then
    # avoid removing Dock anchors
    if [[ "${item}" == "Finder" || "${item}" == "Trash" ]]; then
      continue
    fi

    expanded_path="$(expand_path "${path}")"
    echo "Removing '${item}' from ${section_key}"
    DOCK_CHANGED=true
    dockutil --remove "${item}" --no-restart \
      || dockutil --remove "${expanded_path}" --no-restart \
      || true
  fi
done < <(dockutil --list)

add_item() {
  local section="${1}"
  local label="${2}"
  local key="${section}:${label}"
  local type="${TYPES[${key}]:-app}"
  local raw_path="${PATHS[${key}]:-}"
  local view="${VIEWS[${key}]:-}"
  local display="${DISPLAYS[${key}]:-}"
  local sort="${SORTS[${key}]:-}"

  # Finder and Trash are special Dock anchors that may not appear in --list.
  # Avoid trying to add them; they are always present already.
  if [[ "${label}" == "Finder" || "${label}" == "Trash" ]]; then
    return 0
  fi

  if [[ -z "${PRESENT[${key}]+x}" && -n "${RECENT[${label}]+x}" ]]; then
    # item is only in recent apps; proceed to add to persistent.
    :
  elif dockutil --find "${label}" >/dev/null 2>&1; then
    PRESENT["${key}"]="found"
    return 0
  fi

  [[ -n "${PRESENT[${key}]+x}" ]] && return 0

  local target
  target="$(expand_path "${raw_path}")"

  if [[ "${type}" != "spacer" && -z "${target}" ]]; then
    echo "Skipping '${label}' (no path provided)"
    return 0
  fi

  if [[ "${type}" != "spacer" && "${type}" != "url" && -n "${target}" && ! -e "${target}" ]]; then
    echo "Skipping '${label}' (${target}) not found on disk"
    return 0
  fi

  local cmd=()
  case "${type}" in
    spacer)
      cmd=(dockutil --add '' --type spacer --section "${section}" --no-restart)
      ;;
    folder)
      cmd=(dockutil --add "${target}" --section "${section}" --label "${label}" --no-restart)
      [[ -n "${view}" ]] && cmd+=(--view "${view}")
      [[ -n "${display}" ]] && cmd+=(--display "${display}")
      [[ -n "${sort}" ]] && cmd+=(--sort "${sort}")
      ;;
    url)
      cmd=(dockutil --add "${target}" --section "${section}" --label "${label}" --no-restart)
      ;;
    *)
      cmd=(dockutil --add "${target}" --section "${section}" --label "${label}" --no-restart)
      ;;
  esac

  echo "Adding '${label}' to ${section}"
  DOCK_CHANGED=true
  "${cmd[@]}"
  PRESENT["${key}"]="${target}"
}

for label in "${ORDER_APPS[@]}"; do
  add_item "apps" "${label}"
done

for label in "${ORDER_OTHERS[@]}"; do
  add_item "others" "${label}"
done

reorder_section() {
  local section="${1}"
  shift
  local labels=("$@")
  local position=1

  for label in "${labels[@]}"; do
    local key="${section}:${label}"
    [[ -z "${PRESENT[${key}]+x}" ]] && continue
    [[ "${label}" == "Finder" || "${label}" == "Trash" ]] && { ((position++)); continue; }

    if [[ "${DOCK_CHANGED}" == "false" && "${CURRENT_POS[${key}]:-}" == "${position}" ]]; then
      ((position++))
      continue
    fi

    DOCK_CHANGED=true
    dockutil --move "${label}" --section "${section}" --position "${position}" --no-restart || true
    ((position++))
  done
}

reorder_section "apps" "${ORDER_APPS[@]}"
reorder_section "others" "${ORDER_OTHERS[@]}"

current_show_recents="$(defaults read com.apple.dock show-recents 2>/dev/null || printf '0')"
if [[ "${current_show_recents}" != "1" && "${current_show_recents}" != "true" ]]; then
  defaults write com.apple.dock show-recents -bool true
  DOCK_CHANGED=true
fi

if [[ "${DOCK_CHANGED}" != "true" ]]; then
  echo "Dock is already up to date."
  exit 0
fi

echo "Restarting Dock to commit batch..."

killall Dock || true

echo "Dock is updated."
