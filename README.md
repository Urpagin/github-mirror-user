# github-mirror-user 🚀

A small **Docker Compose** setup to periodically mirror all repositories, public & private, of your GitHub account and make them available with a high-performance git frontend, [Forgejo](https://forgejo.org/).

> [!NOTE]
> This project can **only** be installed with Docker Compose. You may use Docker alone, but you'll have to manually create the commands.

## Features ✨

* Periodic mirroring of **all** repositories, public and private of a GitHub account you have access.
* Nice and lightweight git frontend.
* Optional simple Discord webhook error logging.

## Installation 🛠️

> \[!TIP]
> Please follow the instructions carefully. They may feel out of order, but the `.env` file needs to be populated with both a GitHub token **and** a Forgejo token.

1. Clone the repository 📂

```bash
git clone https://github.com/Urpagin/github-mirror-user.git
cd github-mirror-user
```  

2. Initialize the frontend 🌐

2.1 Launch the frontend

```bash
sudo docker compose up -d server
```

2.2 Create the admin account

Visit [http://127.0.0.1:64175](http://127.0.0.1:64175) (replace with your machine's IP) and follow the instructions.

2.3 Create your Forgejo token

Generate your Forgejo token (see instructions in the `.env` file) and place it in the `.env` file.

3. Populate fully the `.env` file 📄

Read and follow the instructions contained inside the `.env` file carefully.

4. Start the containers 🐳

```bash
sudo docker compose up -d
```

5. Verify & Enjoy 🎉

Wait for the cronjob to run (you can [modify the cron interval](https://crontab.guru/) by changing the startup command of the cron container in the `docker-compose.yml` file; make sure to force recreate the containers afterward).

You can check the logs of all the containers interactively using this command:
```bash
docker compose up -d --force-recreate
```

```bash
sudo docker compose logs -f
```

## Containers 📦

### Forgejo

Forgejo is similar to GitLab, Gitea, or Gogs. It's written in Go and designed to be lightweight.

> Forgejo is a self-hosted lightweight software forge. Easy to install and low maintenance—it just does the job.

* 🌍 [Website](https://forgejo.org/)
* 📥 [Source](https://codeberg.org/forgejo/forgejo)

### Alpine (cron)

We run the cron daemon in a small Alpine Linux container to periodically execute the mirroring script (`crontab_script.sh`). ⏰

## Small Behaviour Explanation

If you receive a code 55 from the Discord webhook, it means the `crontab_script.sh` script is running
and it is ran once more, almost making them overlap, if not for the lockfile logic on top of the script.

## Security 🔒

> \[!IMPORTANT]
> Ensure logs remain secure and private, as some logging includes sensitive tokens for GitHub and Forgejo!
