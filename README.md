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
preferences. It can show the owner's progression, run an explicit opt-in
co-op scoreboard for a companion, and inspect a texted photo as evidence before
the owner confirms a quest clear. The state is stored in
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

For a fresh checkout, the official one-command local path is equivalent:

```sh
plow-agents deploy --local --line <mako-line-uid>
docker compose ps
docker compose logs -f agent
```

`deploy --local` mints the line-scoped credential and starts this Compose
project. Use `mint` plus `docker compose up` when the credential already exists
or when you want to inspect each step separately.

The named `mako-home` volume persists Hermes state and
`/var/lib/hermes/.agent-index.json`, which preserves this install's Agent Index
identity across container recreation. Do not use a fresh anonymous volume for a
recreated install.

## Agent Index registration and checks

The Agent Index client and reporter come with the Plow base image; this repo
ships no copy. From this directory, use the persistent-
volume registration path:

```sh
docker compose run --rm --no-deps --build --user 10000:10000 \
  --entrypoint /bin/sh agent -c \
  '/opt/hermes/.venv/bin/python3 /opt/plow/agent-index-client.py --self-check && \
   /opt/hermes/.venv/bin/python3 /opt/plow/agent-index-client.py --register \
     --agent mako --name "Mako" \
     --blurb "Mako turns real life into an RPG through SMS: quick quests, persistent XP, co-op progress, and optional photo proof." \
     --repo "https://github.com/santleme/mako" --runtime "Hermes / Plow" \
     --install-url "https://github.com/santleme/mako#agent-index-install-flow" && \
   /opt/hermes/.venv/bin/python3 /opt/plow/agent-index-client.py status'
docker compose up --build -d
docker compose exec -T agent /opt/hermes/.venv/bin/python3 \
  /opt/plow/agent-index-client.py --agent mako --dry-run
```

### Cloud image and one-click deployment

The repository publishes a linux/amd64 image to GHCR on every push to `main`
through `.github/workflows/publish-image.yml`. After the first successful run,
make the `ghcr.io/santleme/mako` package public so Plow can pull it
anonymously. The workflow's immutable commit tag can then be resolved to a
digest and requested with the official CLI:

```sh
plow-agents image build ghcr.io/santleme/mako:<tag>
plow-agents image push ghcr.io/santleme/mako:<tag>
plow-agents deploy ghcr.io/santleme/mako@sha256:<digest> --line <free-line-uid>
plow-agents agents
```

Wait for `running` before texting the deployed line. The Agent Index's hosted
“Text this agent” button is separate: the Index maintainers must enable the
agent's `deployable_at` flag after reviewing the public image and repository.

### Agent Index install flow and verification

The current Mako record is community-listed, not cloud-deployable: the Agent
Index has not enabled its hosted `deployable_at` flag for this agent. Its
one-command local path is still available to anyone with Docker and a Plow
line. The shortest supported path is:

```sh
git clone https://github.com/santleme/mako.git
cd mako
export PATH="$PWD/../plow-agents/bin:$PATH"
plow-agents mint <mako-line-uid> --credential-file ./plow-credentials
docker compose up --build -d
docker compose logs -f agent
```

Look for `plow-init: configured ... as cht_...` before sending the first SMS.
Verify the local runtime with `docker compose ps`, then verify the Agent Index
registration:

```sh
docker compose exec -T agent /opt/hermes/.venv/bin/python3 \
  /opt/plow/agent-index-client.py status
```

The command must exit `0`. The public record is
`https://aiworthusing.com/agent-index/mako`; the displayed name, blurb and
repository should match the registration above. A hosted “Text this agent”
button only appears after the Index maintainers enable the agent's deployable
flag; that cannot be turned on by a repository commit.

The `--user 10000:10000` registration is important: it makes the persistent
Agent Index state readable and writable by the s6 reporter, while the normal
container still starts as the base image's root `/init` process.

The runtime reporter is the base image's own `agent-index` s6 longrun. It registers only when the client says
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
