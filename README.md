# Mako

Mako turns real life into a lightweight RPG entirely through SMS / Plow Chat.
It is a small Plow Hermes variant: the persona and one state skill live in this
repository, while the official Plow runtime, chat plugin, persistent Hermes
home, and Agent Index reporter remain the infrastructure layer.

## Current identity

- Display name: Mako
- Initial Agent Index ID: `mako`
- Runtime: Hermes / Plow
- License for agent-specific files: MIT

The identity is only published after registration with the official Agent Index
client. The current intended public name is Mako; the final one-line blurb is
chosen at registration time.

## SMS-first behavior

The first message is useful without onboarding. Mako creates short, realistic
quick quests, side quests and boss fights for boredom, exams, social
situations, and everyday challenges, then tracks XP, level, Social, Knowledge,
Fitness, Courage, Chaos, completions, streaks, achievements and lightweight
preferences. The state is stored in
`/var/lib/hermes/memories/mako-state.md` inside the named `mako-home` volume.
An optional daily quest is opt-in through SMS and uses the official Hermes cron
tool. The Mako logo can be sent in the same Plow Chat thread when requested.
Pets are intentionally deferred and are not part of the runtime image. There
is no dashboard, frontend, web chat, separate database, or custom scheduler.
Latch/browser/calendar tools are used only when a real requested quest
benefits from them, and the result is always returned over SMS.

## Local build and run

The official `plow-agents` CLI writes a mode-600 `plow-credentials` file for
this agent. It is ignored by both Git and Docker. Use a separate Plow line and
credential for Mako; never reuse Vela's credential.

```sh
plow-agents mint <mako-line-uid> --credential-file ./plow-credentials
docker compose up --build -d
docker compose logs -f agent
```

The named `mako-home` volume persists Hermes state and
`/var/lib/hermes/.agent-index.json`, which preserves this install's Agent Index
identity across container recreation. Do not use a fresh anonymous volume for a
recreated install.

## Agent Index registration and checks

The image fetches exactly the pinned client in `vendor/client.pin` and verifies
its SHA-256 during the image build. From this directory, use the persistent-
volume registration path:

```sh
docker compose run --rm --no-deps --build --user 10000:10000 \
  --entrypoint /bin/sh agent -c \
  '/opt/hermes/.venv/bin/python3 /opt/plow/agent-index-client.py --self-check && \
   /opt/hermes/.venv/bin/python3 /opt/plow/agent-index-client.py --register \
     --agent mako --name "Mako" \
     --blurb "Mako turns your real life into an RPG, entirely through text messages." \
     --repo "https://github.com/santleme/mako" --runtime "Hermes / Plow" && \
   /opt/hermes/.venv/bin/python3 /opt/plow/agent-index-client.py status'
docker compose up --build -d
docker compose exec -T agent /opt/hermes/.venv/bin/python3 \
  /opt/plow/agent-index-client.py --agent mako --dry-run
```

The `--user 10000:10000` registration is important: it makes the persistent
Agent Index state readable and writable by the s6 reporter, while the normal
container still starts as the base image's root `/init` process.

The runtime reporter is the official s6 longrun under
`image/s6-overlay/s6-rc.d/agent-index`. It registers only when the client says
the persistent install state is absent, gives the Plow bearer only to that
registration exchange, and reports every five minutes without the bearer.

## Mako + Vela

Mako is the RPG owner. Vela is a separate Plow Hermes repository and line that
is currently only a social presence in the shared Plow group. Vela does not
own Mako's state, quests, XP, or cron jobs. The group roster is the only
integration contract; there is no custom RPC or shared volume.

## Later evolution

Add product-specific skills under this repository only when the product is
chosen. Keep the base image, Agent Index client pin, persistent Hermes home,
and reporter wiring intact.

## Licensing

New Mako files are MIT licensed. The Plow Hermes base image and the downloaded
Agent Index client remain under their upstream licenses; see NOTICE.
