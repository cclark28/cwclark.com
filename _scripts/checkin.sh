#!/bin/bash
# Daily check-in: asks where you are, fetches weather, saves to content/
# Run manually or triggered daily at 9am via LaunchAgent

REPO_ROOT="$(git -C "$(dirname "$0")" rev-parse --show-toplevel 2>/dev/null || echo "$HOME/cwclark.com")"
LOCATION_FILE="$REPO_ROOT/content/location/current.json"
UPDATES_FILE="$REPO_ROOT/content/updates/index.json"
TODAY=$(date +%Y-%m-%d)
NOW=$(date +%H:%M)

# Check if already checked in today
if [ -f "$LOCATION_FILE" ]; then
  LAST=$(python3 -c "import json,sys; d=json.load(open('$LOCATION_FILE')); print((d.get('updated') or '')[:10])" 2>/dev/null)
  if [ "$LAST" = "$TODAY" ]; then
    osascript -e 'display notification "Already checked in today." with title "cwclark.com"' 2>/dev/null
    exit 0
  fi
  LAST_CITY=$(python3 -c "import json; d=json.load(open('$LOCATION_FILE')); print(d.get('city','Indianapolis'))" 2>/dev/null || echo "Indianapolis")
else
  LAST_CITY="Indianapolis"
fi

# ── Dialog 1: Where are you? ──────────────────────────────────────────────────
CITY=$(osascript <<EOF
tell application "System Events"
  activate
  set result to display dialog "Good morning, Charlie. Where are you today?" \
    default answer "$LAST_CITY" \
    with title "cwclark.com Check-in" \
    buttons {"Skip", "Check In"} \
    default button "Check In"
  if button returned of result is "Skip" then return ""
  return text returned of result
end tell
EOF
)

if [ -z "$CITY" ]; then
  exit 0
fi

# ── Fetch weather from wttr.in (no API key needed) ────────────────────────────
CITY_URL=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$CITY'))")
WEATHER_JSON=$(curl -sf "https://wttr.in/${CITY_URL}?format=j1" 2>/dev/null)

if [ -z "$WEATHER_JSON" ]; then
  osascript -e "display dialog \"Could not fetch weather for '$CITY'. Check your connection.\" buttons {\"OK\"} default button \"OK\" with title \"cwclark.com Check-in\""
  exit 1
fi

# Parse weather data
read -r TEMP_F TEMP_C CONDITION WIND_MPH WIND_DIR HUMIDITY COUNTRY REGION EMOJI <<< $(python3 -c "
import json, sys

data = json.loads('''$WEATHER_JSON''')
cur  = data['current_condition'][0]
area = data['nearest_area'][0]

temp_f    = cur['temp_F']
temp_c    = cur['temp_C']
condition = cur['weatherDesc'][0]['value']
wind_mph  = cur['windspeedMiles']
wind_dir  = cur['winddir16Point']
humidity  = cur['humidity']
country   = area['country'][0]['value']
region    = area['region'][0]['value'] if area.get('region') else ''

# Pick emoji based on weather code
code = int(cur['weatherCode'])
if code == 113:   emoji = '☀️'
elif code == 116: emoji = '⛅'
elif code == 119: emoji = '☁️'
elif code in [143,248,260]: emoji = '🌫️'
elif code in [176,293,296,299,302,305,308]: emoji = '🌧️'
elif code in [179,323,326,329,332,335,338]: emoji = '❄️'
elif code in [200,386,389]: emoji = '⛈️'
else:             emoji = '🌤️'

print(temp_f, temp_c, condition.replace(' ', '_'), wind_mph, wind_dir, humidity, country.replace(' ', '_'), region.replace(' ', '_'), emoji)
")

CONDITION_CLEAN="${CONDITION//_/ }"
COUNTRY_CLEAN="${COUNTRY//_/ }"
REGION_CLEAN="${REGION//_/ }"

# ── Dialog 2: Show weather summary ────────────────────────────────────────────
RESPONSE=$(osascript <<EOF
tell application "System Events"
  activate
  set result to display dialog "📍 $CITY, $REGION_CLEAN  $COUNTRY_CLEAN
$EMOJI  $CONDITION_CLEAN
🌡  ${TEMP_F}°F  /  ${TEMP_C}°C
💨  Wind ${WIND_MPH} mph ${WIND_DIR}
💧  Humidity ${HUMIDITY}%
🕐  $NOW  ·  $TODAY" \
    with title "cwclark.com — Today" \
    buttons {"Update Location", "Done"} \
    default button "Done"
  return button returned of result
end tell
EOF
)

# If they want to update location, re-run the script
if [ "$RESPONSE" = "Update Location" ]; then
  exec "$0"
  exit 0
fi

# ── Save to content/location/current.json ─────────────────────────────────────
python3 -c "
import json
data = {
  'city': '$CITY',
  'region': '$REGION_CLEAN',
  'country': '$COUNTRY_CLEAN',
  'temp_f': $TEMP_F,
  'temp_c': $TEMP_C,
  'condition': '$CONDITION_CLEAN',
  'wind_mph': $WIND_MPH,
  'wind_dir': '$WIND_DIR',
  'humidity': $HUMIDITY,
  'emoji': '$EMOJI',
  'updated': '${TODAY}T${NOW}:00'
}
with open('$LOCATION_FILE', 'w') as f:
  json.dump(data, f, indent=2)
print('location saved')
"

# ── Prepend to content/updates/index.json ─────────────────────────────────────
python3 -c "
import json

entry = {
  'id': '$TODAY',
  'date': '$TODAY',
  'time': '$NOW',
  'city': '$CITY',
  'region': '$REGION_CLEAN',
  'country': '$COUNTRY_CLEAN',
  'condition': '$CONDITION_CLEAN',
  'temp_f': $TEMP_F,
  'emoji': '$EMOJI'
}

try:
  with open('$UPDATES_FILE') as f:
    feed = json.load(f)
except:
  feed = []

# Avoid duplicate entries for same day
feed = [e for e in feed if e.get('id') != '$TODAY']
feed.insert(0, entry)

with open('$UPDATES_FILE', 'w') as f:
  json.dump(feed, f, indent=2)
print('updates feed saved')
"

# ── Done notification ──────────────────────────────────────────────────────────
osascript -e "display notification \"Checked in from $CITY $EMOJI\" with title \"cwclark.com\""
echo ""
echo "  ✓ Checked in: $CITY $EMOJI  $CONDITION_CLEAN  ${TEMP_F}°F"
echo "  ✓ Saved to content/location/current.json"
echo "  ✓ Added to content/updates/index.json"
echo ""
echo "  Run ./_scripts/save.sh to push updates to cwclark.com"
echo ""
