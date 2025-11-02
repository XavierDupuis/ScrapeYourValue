# ScrapeYourValue
Monitors endpoints reponses from various websites and sends notifications when values change.

## Deployment

1. Download
   ```bash
    mkdir config
    wget -O config/config.yml https://raw.githubusercontent.com/XavierDupuis/ScrapeYourValue/refs/heads/main/config.yml.template
    wget -O .env https://raw.githubusercontent.com/XavierDupuis/ScrapeYourValue/refs/heads/main/.env.template
    wget -O docker-compose.yml https://raw.githubusercontent.com/XavierDupuis/ScrapeYourValue/refs/heads/main/docker-compose.yml
   ```

1. Edit the configuration files:
   - Set up your targets in `config/config.yml`
   - Configure the CRON schedule in `.env`

1. Start the service:
   ```bash
   docker compose up -d
   ```

## Development

For development, use:
```bash
docker-compose -f dev.docker-compose.yml up --build
```

## License


See [LICENSE](LICENSE) file for details.

