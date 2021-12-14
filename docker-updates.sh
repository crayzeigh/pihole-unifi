#!/bin/bash

email="you@domain.com"

body="Start: $(date)
Checking for new images...
$(/bin/docker-compose -f /path/to/docker-compose.yml pull --no-parallel 2>&1)

Updating changed containers...
$(/bin/docker-compose -f /path/to/docker-compose.yml up -d 2>&1)

Cleaning up...
$(/bin/docker system prune -af 2>&1)

End $(date)
"

# Only receive emails if an image changed
if [[ ${body} == *"Recreating"* ]]; then
  echo "${body}" | mail -s "Docker Updates Completed" ${email}
fi